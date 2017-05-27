/***************	FONCTION 	****************/

CREATE OR REPLACE FUNCTION privateCheckPeriode(periode VARCHAR(15)) RETURNS BOOLEAN AS $$
    BEGIN
        IF periode IS NULL OR periode = 'microseconds' OR periode = 'millennium'
             OR periode = 'minute' OR periode = 'second' OR periode = 'quarter'
             OR periode = 'hour' OR periode = 'day' OR periode = 'week' OR periode = 'year'
             OR periode = 'decade' OR periode = 'month' OR periode = 'century'  THEN
             return true;
        ELSE
            return false;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION testCond(idRepr INTEGER, idTar INTEGER, nomDF VARCHAR(50))
RETURNS INTEGER AS $$
    DECLARE
        prixMin int;
        nbBillet int :=0;
        nbBilletName int :=0;
        dateCourante TIMESTAMP;
        dateV TIMESTAMP;
        ligne record;
        cond boolean := false;
    BEGIN
        SELECT date INTO dateCourante FROM DateCourante;
        SELECT dateVente INTO dateV FROM Representations WHERE idRepresentation=idRepr;
        SELECT count(*) INTO nbBillet FROM Tickets WHERE idRepresentation=idRepr;
        SELECT count(*) INTO nbBilletName FROM Tickets WHERE idRepresentation=idRepr AND Tickets.nom = nomDF;
        SELECT prix INTO prixMin FROM Tarifs WHERE idRepresentation=idRepr AND nom='Normal';
        FOR ligne IN
            SELECT * FROM Tarifs WHERE idRepresentation=idRepr AND (nom!='Normal' OR nom!='Reduit')
        LOOP
            IF ligne.nom = 'P1' AND ligne.support = 'day' AND dateV + (ligne.nombre * interval '1 day')< DateCourante THEN
                cond := true;
            ELSIF ligne.nom = 'P2' AND ligne.support = 'billet' AND ligne.nombre < nbBillet THEN
                cond :=true;
            ELSIF ligne.nom = 'P3' AND ligne.support = 'billet' AND ligne.nombre >= nbBilletName THEN
                cond :=true;
            END IF;
            IF cond = true AND ligne.prix < prixMin THEN
                prixMin = ligne.prix;
                idTar = ligne.idTarif;
            END IF;
            cond := false;
        END LOOP;
        return idTar;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION achete(nomFamille VARCHAR(50), nombre int,
representation int) RETURNS void AS $$
    DECLARE
        idRes int :=0;
    BEGIN
        IF nombre < 1 THEN
            RAISE EXCEPTION 'Le nombre de tickets doit etre positif';
        ELSE
            SELECT idReference INTO idRes FROM Tickets WHERE nom=nomFamille
            AND idRepresentation=representation;
        END IF;
        IF idRes IS NULL THEN
            WITH rows AS (
            INSERT INTO Tickets (nom, idRepresentation, idTarif) VALUES
                (nomFamille, representation , (SELECT idTarif
                FROM Tarifs WHERE idRepresentation=representation AND nom='Normal'))
                RETURNING idTicket)
            INSERT INTO Vendus (idTicket) SELECT idTicket FROM rows;
            SELECT idReference INTO idRes FROM Tickets WHERE nom=nomFamille
                AND idRepresentation=representation;
        ELSE
            RAISE NOTICE 'Modification de lachat deja existant';
            WITH rows AS (
            INSERT INTO Tickets (nom, idRepresentation, idReference, idTarif) VALUES
                (nomFamille, representation , idRes, (SELECT idTarif
                FROM Tarifs WHERE idRepresentation=representation AND nom='Normal'))
                RETURNING idTicket)
            INSERT INTO Vendus (idTicket) SELECT idTicket FROM rows;
        END IF;
        RAISE NOTICE '1 billet ajoute';
        FOR i in 2..nombre
        LOOP
            WITH rows AS (
            INSERT INTO Tickets (nom, idRepresentation, idReference, idTarif) VALUES
                (nomFamille, representation , idRes, (SELECT idTarif
                FROM Tarifs WHERE idRepresentation=representation AND nom='Normal'))
                RETURNING idTicket)
            INSERT INTO Vendus (idTicket) SELECT idTicket FROM rows;
            RAISE NOTICE '% billets ajoutes', i;
        END LOOP;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION reserve(nomFamille VARCHAR(50), nombre int,
representation int) RETURNS void AS $$
    DECLARE
        idRes int :=0;
    BEGIN
        IF nombre < 1 THEN
            RAISE EXCEPTION 'Le nombre de tickets doit etre positif';
        ELSE
            SELECT idReference INTO idRes FROM Tickets WHERE nom=nomFamille
            AND idRepresentation=representation;
        END IF;
        IF idRes IS NULL THEN
            WITH rows AS (
            INSERT INTO Tickets (nom, idRepresentation, idTarif) VALUES
                (nomFamille, representation , (SELECT idTarif
                FROM Tarifs WHERE idRepresentation=representation AND nom='Normal'))
                RETURNING idTicket)
            INSERT INTO Reservations (idTicket) SELECT idTicket FROM rows;
            SELECT idReference INTO idRes FROM Tickets WHERE nom=nomFamille
                AND idRepresentation=representation;
        ELSE
            RAISE NOTICE 'Modification de la reservation existante';
            WITH rows AS (
            INSERT INTO Tickets (nom, idRepresentation, idReference, idTarif) VALUES
                (nomFamille, representation , idRes, (SELECT idTarif
                FROM Tarifs WHERE idRepresentation=representation AND nom='Normal'))
                RETURNING idTicket)
            INSERT INTO Reservations (idTicket) SELECT idTicket FROM rows;
        END IF;
        RAISE NOTICE '1 billet ajoute';
        FOR i in 2..nombre
        LOOP
            WITH rows AS (
            INSERT INTO Tickets (nom, idRepresentation, idReference, idTarif) VALUES
                (nomFamille, representation , idRes, (SELECT idTarif
                FROM Tarifs WHERE idRepresentation=representation AND nom='Normal'))
                RETURNING idTicket)
            INSERT INTO Reservations (idTicket) SELECT idTicket FROM rows;
            RAISE NOTICE '% billets ajoutes', i;
        END LOOP;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION acheteUneReservation(nomFamille VARCHAR(50),
idReservation int) RETURNS void AS $$
    DECLARE
        nb int :=0;
        ligne record;
    BEGIN
        FOR ligne IN
            SELECT dateLimite, Tickets.idTicket FROM Tickets JOIN Reservations
                ON Tickets.idTicket = Reservations.idTicket WHERE nom=nomFamille
                AND idReference=idReservation
        LOOP
            IF ligne.dateLimite < (SELECT date FROM DateCourante) THEN
                DELETE FROM Reservations WHERE idTicket=ligne.idTicket;
                DELETE FROM Tickets WHERE idTicket=ligne.idTicket;
                RAISE EXCEPTION 'La date limite est depasse !';
            ELSE
                DELETE FROM Reservations WHERE idTicket=ligne.idTicket;
                INSERT INTO Vendus (idTicket) VALUES (ligne.idTicket);
                RAISE NOTICE '% billet(s) achete(s)', nb+1;
            END IF;
            nb:=nb+1;
        END LOOP;
        IF nb = 0 THEN
            RAISE EXCEPTION 'Le ticket est inconnu !';
            return;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION refreshReservation() RETURNS void AS $$
    DECLARE
        ligne record;
    BEGIN
        FOR ligne IN
            SELECT dateLimite, nom, Tickets.idTicket FROM Tickets JOIN Reservations
                ON Tickets.idTicket = Reservations.idTicket
        LOOP
            IF ligne.dateLimite < (SELECT date FROM DateCourante) THEN
                DELETE FROM Reservations WHERE idTicket=ligne.idTicket;
                DELETE FROM Tickets WHERE idTicket=ligne.idTicket;
                RAISE EXCEPTION 'La date limite est depasse !';
            END IF;
        END LOOP;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION depenses(nomSpec VARCHAR(50)) RETURNS INT AS $$
    DECLARE
        idSpec int :=0;
        spectacleAchetes int :=0;
        coutProds int :=0;
    BEGIN
        SELECT idSpectacle INTO idSpec FROM Spectacles WHERE nom=nomSpec;
        SELECT coalesce(sum(prix),0) INTO spectacleAchetes FROM SpectaclesAchetes
            WHERE(idSpectacle = idSpec OR idSpec IS NULL) ;
        SELECT coalesce(sum(prix),0) INTO coutProds FROM CoutProds JOIN
            SpectaclesCres ON CoutProds.idSpectacle = SpectaclesCres.idSpectacle
            WHERE (SpectaclesCres.idSpectacle = idSpec OR idSpec IS NULL);
        return spectacleAchetes+coutProds;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION depenses(nomSpec VARCHAR(50), periode VARCHAR(15))
RETURNS TABLE (depenses numeric(10), date TIMESTAMP) AS $$
    DECLARE
        idSpec int :=0;
    BEGIN
        IF privateCheckPeriode(periode) = FALSE THEN
            RAISE EXCEPTION 'La periode indique nest pas valide!';
        END IF;
        SELECT idSpectacle INTO idSpec FROM Spectacles WHERE nom=nomSpec;
        return query SELECT coalesce(sum(sub.P),0),
            date_trunc(periode, sub.d) AS e FROM (
                SELECT coalesce(sum(prix),0) AS P,
                    date_trunc(periode, SpectaclesAchetes.date) AS d FROM
                    SpectaclesAchetes WHERE (idSpectacle = idSpec OR idSpec IS NULL)
                    GROUP By d
                union all
                SELECT coalesce(sum(prix),0) AS P, date_trunc(periode, CoutProds.date) AS d
                    FROM CoutProds JOIN SpectaclesCres ON
                    CoutProds.idSpectacle = SpectaclesCres.idSpectacle
                    WHERE (SpectaclesCres.idSpectacle = idSpec OR idSpec IS NULL)
                    GROUP By d
        ) AS sub GROUP BY e ORDER BY e asc;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recettes(nomSpec VARCHAR(50)) RETURNS INT AS $$
    DECLARE
        idSpec int :=0;
        subvention int :=0;
        ticketsVendus int :=0;
        spectacleVendus int :=0;
    BEGIN
        SELECT idSpectacle INTO idSpec FROM Spectacles WHERE nom=nomSpec;
        SELECT coalesce(sum(prix),0) INTO subvention FROM Subventions
            WHERE (idSpectacle = idSpec OR idSpec IS NULL);
        SELECT coalesce(sum(prix),0) INTO ticketsVendus FROM Tickets
            JOIN Tarifs ON tickets.idTarif = Tarifs.idTarif JOIN Vendus ON
            Vendus.idTicket = Tickets.idTicket JOIN Representations ON
            Tickets.idRepresentation = Representations.idRepresentation WHERE
            (idSpectacle = idSpec OR idSpec IS NULL);
        SELECT coalesce(sum(prix),0) INTO spectacleVendus FROM ContratDeVentes JOIN
            SpectaclesCres ON ContratDeVentes.idSpectacle = SpectaclesCres.idSpectacle
            WHERE (SpectaclesCres.idSpectacle = idSpec OR idSpec IS NULL);
        return subvention + ticketsVendus + spectacleVendus;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recettes(nomSpec VARCHAR(50), periode VARCHAR(15))
RETURNS TABLE (recettes numeric(10), date TIMESTAMP) AS $$
    DECLARE
        idSpec int :=0;
    BEGIN
        IF privateCheckPeriode(periode) = FALSE THEN
            RAISE EXCEPTION 'La periode indique nest pas valide!';
            END IF;
        SELECT idSpectacle INTO idSpec FROM Spectacles WHERE nom=nomSpec;
        return query SELECT coalesce(sum(sub.P),0), date_trunc(periode, sub.d)
            AS e FROM (
                SELECT coalesce(sum(prix),0) AS P, date_trunc(periode, Subventions.date) AS d
                    FROM Subventions WHERE (idSpectacle = idSpec OR idSpec IS NULL)
                    GROUP BY d
                union all
                SELECT coalesce(sum(prix),0) AS P, date_trunc(periode, Representations.date) AS d
                    FROM Tickets JOIN Tarifs ON tickets.idTarif = Tarifs.idTarif
                    JOIN Vendus ON Vendus.idTicket = Tickets.idTicket JOIN
                    Representations ON Tickets.idRepresentation =
                    Representations.idRepresentation
                    WHERE (idSpectacle = idSpec OR idSpec IS NULL) GROUP BY d
                union all
                SELECT coalesce(sum(prix),0) AS P, date_trunc(periode, ContratDeVentes.date) AS d
                    FROM ContratDeVentes JOIN SpectaclesCres ON
                    ContratDeVentes.idSpectacle = SpectaclesCres.idSpectacle
                    WHERE (SpectaclesCres.idSpectacle = idSpec OR idSpec IS NULL)
                    GROUP BY d
        )AS sub GROUP BY e ORDER BY e asc;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION benefices(nameSpec VARCHAR(50)) RETURNS TABLE
(nomSpectacles VARCHAR(50), depenses int, recettes int, benefices int ) AS $$
    DECLARE
        ligne record;
        i int :=0;
        totalRecettes int :=0;
        totalDepenses int :=0;
    BEGIN
        FOR ligne IN
            SELECT nom FROM Spectacles WHERE (nom=nameSpec OR nameSpec IS NULL)
        LOOP
            nomSpectacles = ligne.nom;
            depenses =  depenses(ligne.nom);
            recettes = recettes(ligne.nom);
            benefices = recettes - depenses;
            totalRecettes = totalRecettes + recettes;
            totalDepenses = totalDepenses + depenses;
            i = i + 1;
            return next;
        END LOOP;
        IF i > 1 THEN
            nomSpectacles = 'Total';
            depenses = totalDepenses;
            recettes = totalRecettes;
            benefices = totalRecettes - totalDepenses;
            return next;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION benefices(nomSpec VARCHAR(50), periode VARCHAR(15))
RETURNS TABLE (date TIMESTAMP, recettes numeric(10), depenses numeric(10),
benefices numeric(10)) AS $$
    BEGIN
        return query
        SELECT sub.d AS e, coalesce(sum(sub.P),0), coalesce(sum(sub.V),0),
        coalesce(sum(sub.P),0)-coalesce(sum(sub.V),0) FROM(
            SELECT recettes.date AS d, coalesce(sum(recettes.recettes),0) AS P, NULL AS V
                FROM recettes(nomSpec, periode) GROUP BY d
            union all
            SELECT depenses.date AS d, NULL AS P, coalesce(sum(depenses.depenses),0) AS V
                FROM depenses(nomSpec, periode) GROUP BY d
        ) AS sub GROUP BY e ORDER BY e asc;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION billetNB(nomSpec VARCHAR(50)) RETURNS TABLE
(date TIMESTAMP, billetVendus numeric(10), recetteV numeric(10), billetsReserves
numeric(10), recetteR numeric(10), nbTotal numeric(10), recetteTotal numeric(10))
AS $$
    BEGIN
        DROP TABLE IF EXISTS OneSpectacle;
        CREATE TABLE OneSpectacle AS SELECT Representations.date,idTicket, prix, Tarifs.nom
            FROM Spectacles NATURAL JOIN Representations JOIN Tickets ON
            Tickets.idRepresentation = Representations.idRepresentation JOIN
            Tarifs ON Tarifs.idTarif = Tickets.idTarif
            WHERE Spectacles.nom = nomSpec;
        return query
        SELECT sub.date AS e, coalesce(sum(sub.BV),0), coalesce(sum(sub.PV),0),
        coalesce(sum(sub.BR),0), coalesce(sum(sub.PR),0), coalesce(sum(sub.BV),0)+
        coalesce(sum(sub.BR),0), coalesce(sum(sub.PV),0)+coalesce(sum(sub.PR),0)
        FROM (
            SELECT OneSpectacle.date, coalesce(count(*),0) AS BV, coalesce(sum(prix),0)
                AS PV, NULL AS BR, NULL AS PR FROM OneSpectacle JOIN Vendus ON
                Vendus.idTicket = OneSpectacle.idTicket GROUP BY OneSpectacle.date
            union all
            SELECT OneSpectacle.date, NULL AS BV, NULL AS PV, coalesce(count(*),0)
                AS BR, coalesce(sum(prix),0) AS PR FROM OneSpectacle JOIN
                Reservations ON Reservations.idTicket = OneSpectacle.idTicket
                GROUP BY OneSpectacle.date
        ) AS sub GROUP BY e ORDER BY e asc;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION billetTarif(nomSpec VARCHAR(50)) RETURNS TABLE
(date TIMESTAMP, Tarifs VARCHAR(20), prix int, billetVendus numeric(10),
billetsReserves numeric(10)) AS $$
    BEGIN
        DROP TABLE IF EXISTS OneSpectacle;
        CREATE TABLE OneSpectacle AS SELECT Representations.date, idTicket,
            Tarifs.prix, Tarifs.nom
            FROM Spectacles NATURAL JOIN Representations JOIN Tickets ON
            Tickets.idRepresentation = Representations.idRepresentation JOIN
            Tarifs ON Tarifs.idTarif = Tickets.idTarif
            WHERE Spectacles.nom = nomSpec;
        return query
        SELECT sub.date AS e, sub.nom, sub.prix, coalesce(sum(sub.BV),0),
        coalesce(sum(sub.BR),0) FROM(
            SELECT OneSpectacle.date, nom, OneSpectacle.prix, coalesce(count(*),0) AS BV, NULL AS BR FROM
                OneSpectacle JOIN Vendus ON Vendus.idTicket = OneSpectacle.idTicket
                GROUP BY nom, OneSpectacle.date, OneSpectacle.prix
            union all
            SELECT OneSpectacle.date, nom, OneSpectacle.prix, NULL AS BV, coalesce(count(*),0) AS BR FROM
                OneSpectacle JOIN Reservations ON Reservations.idTicket =
                OneSpectacle.idTicket GROUP BY nom, OneSpectacle.date, OneSpectacle.prix
        ) AS sub GROUP BY sub.date, sub.prix, sub.nom
        ORDER BY sub.date asc, sub.nom asc;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tournee(nomSpec VARCHAR(50)) RETURNS TABLE
(piece VARCHAR(50), salle VARCHAR(50), ville VARCHAR(50), departement VARCHAR(50),
pays VARCHAR(50)) AS $$
    BEGIN
        return query
        SELECT Spectacles.nom, Salles.nom, Salles.ville, Salles.departement,
            Salles.pays FROM Spectacles
            JOIN SpectaclesCres ON Spectacles.idSpectacle = SpectaclesCres.idSpectacle
            JOIN ContratDeVentes ON SpectaclesCres.idSpectacle = ContratDeVentes.idSpectacle
            JOIN Salles ON Salles.idSalle = ContratDeVentes.idSalle
            WHERE (Spectacles.nom=nomSpec OR nomSpec IS NULL);
    END;
$$ LANGUAGE plpgsql;
/**************	END FONCTION	****************/

/**********	FONCTION FOR TRIGGER	************/

CREATE OR REPLACE FUNCTION tarifs() RETURNS TRIGGER AS $$
    DECLARE
        price int :=0;
    BEGIN
        IF new.prix IS NULL THEN
            new.prix = 0;
        END IF;
        IF new.nom = 'P1' OR new.nom = 'P2' OR new.nom = 'P3' THEN
            SELECT prix INTO price FROM Tarifs WHERE nom = 'Normal' AND idRepresentation=new.idRepresentation;
            IF price IS NULL THEN
                RAISE EXCEPTION 'merci de rentrer un tarif normal pour cette representation';
            END IF;
            new.prix = price - (price*new.reduction/100);
        END IF;
        return new;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tickets() RETURNS TRIGGER AS $$
    DECLARE
        nbPlace int :=0;
        nbPlaceEnCours int :=0;
        nbTickets int :=0;
        nomTarifs VARCHAR(50);
    BEGIN
        PERFORM refreshReservation();
        SELECT nbPlaces INTO nbPlace FROM Representations WHERE idRepresentation=new.idRepresentation;
        SELECT count(*) INTO nbPlaceEnCours FROM Tickets WHERE idRepresentation=new.idRepresentation;
        SELECT count(*) INTO nbTickets FROM Tickets WHERE idRepresentation=new.idRepresentation
            AND nom=new.nom AND idReference!=new.idReference;
        SELECT nom INTO nomTarifs FROM Tarifs WHERE idRepresentation=new.idRepresentation
            AND idTarif=new.idTarif;
        IF nbPlace < nbPlaceEnCours+1 THEN
            RAISE EXCEPTION 'toutes les places sont occupees pour cette representation !';
        ELSIF nbTickets > 0 THEN
            RAISE EXCEPTION 'une reservation a deja eu lieu pour cette representation !';
        ELSIF nomTarifs IS NULL THEN
            RAISE EXCEPTION 'pas de tarifs';
        ELSIF nomTarifs ='Normal' THEN
            new.idTarif = testCond(new.idRepresentation, new.idTarif, new.nom);
        END IF;
        return new;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ticketsReserves() RETURNS TRIGGER AS $$
    DECLARE
        nb int := 0;
        nbVendus int :=0;
        dateRepresentation TIMESTAMP := (SELECT date FROM DateCourante);
    BEGIN
        SELECT count(*) INTO nb FROM Tickets WHERE idTicket=new.idTicket;
        SELECT count(*) INTO nbVendus FROM Vendus WHERE idTicket=new.idTicket;
        SELECT date INTO dateRepresentation FROM Representations WHERE
                idRepresentation = (SELECT idRepresentation FROM Tickets
                    WHERE idTicket=new.idTicket);
        IF new.dateLimite IS NULL THEN
            SELECT date INTO new.dateLimite FROM DateCourante;
            new.dateLimite = new.dateLimite + interval '72 hours';
        END IF;
        IF nb <= 0 THEN
            RAISE EXCEPTION 'Le ticket est inconnu !';
        ELSIF nbVendus >= 1 THEN
            RAISE EXCEPTION 'Le ticket existe deja comme un ticket achete !';
        ELSIF dateRepresentation < new.dateLimite THEN
            IF dateRepresentation < (SELECT date FROM DateCourante) THEN
                RAISE EXCEPTION 'Reservation impossible : la date de la representation est passée';
            ELSE /*dateLimite est reduit < 72hours */
                new.dateLimite = dateRepresentation;
            END IF;
        END IF;
        PERFORM refreshReservation();
        return new;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ticketsVendus() RETURNS TRIGGER AS $$
    DECLARE
        nb int := 0;
        nbReserve int :=0;
        dateRepresentation TIMESTAMP := (SELECT date FROM DateCourante);
    BEGIN
        SELECT count(*) INTO nb FROM Tickets WHERE idTicket=new.idTicket;
        SELECT count(*) INTO nbReserve FROM Reservations WHERE idTicket=new.idTicket;
        SELECT date INTO dateRepresentation FROM Representations WHERE
                idRepresentation = (SELECT idRepresentation FROM Tickets
                    WHERE idTicket=new.idTicket);
        IF nb <= 0 THEN
            RAISE EXCEPTION 'Le ticket est inconnu !';
        ELSIF nbReserve >= 1 THEN
            RAISE EXCEPTION 'Le ticket existe deja comme un ticket reserve !';
        ELSIF dateRepresentation < (SELECT date FROM DateCourante) THEN
            RAISE EXCEPTION 'Achat impossible : la date de la representation est passée';
        END IF;
        PERFORM refreshReservation();
        return new;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION spectaclesCres() RETURNS TRIGGER AS $$
    DECLARE
        nb int := 0;
        nbAchete int :=0;
    BEGIN
        SELECT count(*) INTO nb FROM Spectacles WHERE idSpectacle=new.idSpectacle;
        SELECT count(*) INTO nbAchete FROM SpectaclesAchetes WHERE idSpectacle=new.idSpectacle;
        IF nb <= 0 THEN
            RAISE EXCEPTION 'Le spectacle est inconnu !';
        ELSIF nbAchete >= 1 THEN
            RAISE EXCEPTION 'Le spectacle existe deja comme un spectacle achete !';
        ELSE
            return new;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION spectaclesAchetes() RETURNS TRIGGER AS $$
    DECLARE
        nb int := 0;
        nbCres int :=0;
        idChrysanteme int :=0;
    BEGIN
        SELECT count(*) INTO nb FROM Spectacles WHERE idSpectacle=new.idSpectacle;
        SELECT count(*) INTO nbCres FROM SpectaclesCres WHERE idSpectacle=new.idSpectacle;
        SELECT idSalle INTO idChrysanteme FROM Salles WHERE nom='Theatre du Chrysanteme';
        IF nb <= 0 THEN
            RAISE EXCEPTION 'Le spectacle est inconnu !';
        ELSIF nbCres >= 1 THEN
            RAISE EXCEPTION 'Le spectacle existe deja comme un spectacle cres !';
        ELSIF new.idSalle = idChrysanteme THEN
            RAISE EXCEPTION 'on ne peut pas acheter a nous meme !';
        ELSE
            IF new.date IS NULL THEN
                SELECT date INTO new.date FROM DateCourante;
            END IF;
            return new;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION coutProds() RETURNS TRIGGER AS $$
    BEGIN
        IF new.date IS NULL THEN
            SELECT date INTO new.date FROM DateCourante;
        END IF;
        return new;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION subvention() RETURNS TRIGGER AS $$
    BEGIN
        IF new.date IS NULL THEN
            SELECT date INTO new.date FROM DateCourante;
        END IF;
        return new;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION contratDeVentes() RETURNS TRIGGER AS $$
    DECLARE
        idChrysanteme int :=0;
    BEGIN
        SELECT idSalle INTO idChrysanteme FROM Salles WHERE nom='Theatre du Chrysanteme';
        IF new.idSalle = idChrysanteme THEN
            RAISE EXCEPTION 'on ne peut pas vendre a nous meme !';
        ELSIF new.date IS NULL THEN
            SELECT date INTO new.date FROM DateCourante;
        END IF;
        return new;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION nbPlacesInfCapacite() RETURNS TRIGGER AS $$
    DECLARE
        capacite int := 0;
    BEGIN
        SELECT Salles.capacite INTO capacite FROM Salles WHERE nom = 'Theatre du Chrysanteme';
        IF capacite < new.nbPlaces THEN
            RAISE EXCEPTION 'le nombre de place souhaite est trop important';
        ELSIF new.date IS NULL THEN
            SELECT date INTO new.date FROM DateCourante;
        END IF;
        IF new.dateVente IS NULL THEN
            SELECT date INTO new.dateVente FROM DateCourante;
        END IF;
        return new;
    END;
$$ LANGUAGE plpgsql;

/******	    END FONCTION FOR TRIGGER	********/

/***************	TRIGGER		****************/
DROP TRIGGER IF EXISTS insertTarifs ON Tarifs;
DROP TRIGGER IF EXISTS insertTickets ON Tickets;
DROP TRIGGER IF EXISTS insertTicketsReserves ON Reservations;
DROP TRIGGER IF EXISTS insertTicketsAchetes ON Vendus;
DROP TRIGGER IF EXISTS insertSpectaclesCres ON SpectaclesCres;
DROP TRIGGER IF EXISTS insertSpectaclesAchetes ON SpectaclesAchetes;
DROP TRIGGER IF EXISTS insertCoutProds ON CoutProds;
DROP TRIGGER IF EXISTS insertSubventions ON Subventions;
DROP TRIGGER IF EXISTS insertContratDeVentes ON ContratDeVentes;
DROP TRIGGER IF EXISTS representationsNbPlaces ON Representations;

CREATE TRIGGER insertTarifs BEFORE INSERT OR UPDATE
ON Tarifs FOR EACH ROW EXECUTE PROCEDURE tarifs();

CREATE TRIGGER insertTickets BEFORE INSERT OR UPDATE
ON Tickets FOR EACH ROW EXECUTE PROCEDURE tickets();

CREATE TRIGGER insertTicketsReserves BEFORE INSERT OR UPDATE
ON Reservations FOR EACH ROW EXECUTE PROCEDURE ticketsReserves();

CREATE TRIGGER insertTicketsAchetes BEFORE INSERT OR UPDATE
ON Vendus FOR EACH ROW EXECUTE PROCEDURE ticketsVendus();

CREATE TRIGGER insertSpectaclesCres BEFORE INSERT OR UPDATE
ON SpectaclesCres FOR EACH ROW EXECUTE PROCEDURE spectaclesCres();

CREATE TRIGGER insertSpectaclesAchetes BEFORE INSERT OR UPDATE
ON SpectaclesAchetes FOR EACH ROW EXECUTE PROCEDURE spectaclesAchetes();

CREATE TRIGGER insertCoutProds BEFORE INSERT OR UPDATE
ON CoutProds FOR EACH ROW EXECUTE PROCEDURE coutProds();

CREATE TRIGGER insertSubventions BEFORE INSERT OR UPDATE
ON Subventions FOR EACH ROW EXECUTE PROCEDURE subvention();

CREATE TRIGGER insertContratDeVentes BEFORE INSERT OR UPDATE
ON ContratDeVentes FOR EACH ROW EXECUTE PROCEDURE contratDeVentes();

CREATE TRIGGER representationsNbPlaces BEFORE INSERT OR UPDATE OF nbPlaces
ON Representations FOR EACH ROW EXECUTE PROCEDURE nbPlacesInfCapacite();

/************** END TRIGGER		****************/
