DROP TABLE IF EXISTS ContratDeVentes ;
DROP TABLE IF EXISTS CoutProds ;
DROP TABLE IF EXISTS Reservations;
DROP TABLE IF EXISTS Vendus;
DROP TABLE IF EXISTS Tickets ;
DROP TABLE IF EXISTS Tarifs;
DROP TABLE IF EXISTS Representations ;
DROP TABLE IF EXISTS Subventions ;
DROP TABLE IF EXISTS SpectaclesCres ;
DROP TABLE IF EXISTS SpectaclesAchetes ;
DROP TABLE IF EXISTS Spectacles ;
DROP TABLE IF EXISTS Salles ;
DROP TABLE IF EXISTS Organismes ;
DROP TABLE IF EXISTS DateCourante ;
DROP TYPE IF EXISTS EnumActions ;

CREATE TABLE DateCourante (
    date TIMESTAMP
);
INSERT INTO DateCourante VALUES ('2017-05-09 21:21:33');

CREATE TYPE EnumActions AS ENUM ('creation', 'accueil');

CREATE TABLE Organismes (
  idOrganisme SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL UNIQUE,
  ville VARCHAR(50) NOT NULL,
  departement VARCHAR(50) NOT NULL,
  pays VARCHAR(50) NOT NULL
);

CREATE TABLE Salles (
  idSalle SERIAL PRIMARY KEY,
  capacite INTEGER NOT NULL CHECK (capacite > 0),
  nom VARCHAR(50) UNIQUE NOT NULL,
  ville VARCHAR(50) NOT NULL,
  departement VARCHAR(50) NOT NULL,
  pays VARCHAR(50) NOT NULL
);

CREATE TABLE Spectacles (
  idSpectacle SERIAL PRIMARY KEY,
  nom VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE SpectaclesAchetes (
  idSpectacle SERIAL PRIMARY KEY REFERENCES Spectacles,
  prix INTEGER NOT NULL CHECK (prix > 0),
  date TIMESTAMP NOT NULL,
  idSalle SERIAL REFERENCES Salles
);

CREATE TABLE SpectaclesCres (
  idSpectacle SERIAL PRIMARY KEY REFERENCES Spectacles
);

CREATE TABLE CoutProds (
  idCoutProd SERIAL PRIMARY KEY,
  prix INTEGER NOT NULL CHECK (prix > 0),
  date TIMESTAMP NOT NULL,
  idSpectacle SERIAL REFERENCES SpectaclesCres
);

CREATE TABLE ContratDeVentes (
  idContratDeVente SERIAL PRIMARY KEY,
  prix INTEGER NOT NULL CHECK (prix > 0),
  date TIMESTAMP NOT NULL,
  idSpectacle SERIAL REFERENCES SpectaclesCres,
  idSalle SERIAL REFERENCES Salles
);

CREATE TABLE Subventions (
  action EnumActions NOT NULL,
  date TIMESTAMP NOT NULL,
  prix INTEGER NOT NULL CHECK (prix > 0),
  idOrganisme SERIAL REFERENCES Organismes,
  idSpectacle SERIAL REFERENCES Spectacles,
  PRIMARY KEY (idOrganisme, idSpectacle)
);

CREATE TABLE Representations (
  idRepresentation SERIAL PRIMARY KEY,
  date TIMESTAMP NOT NULL,
  lieu VARCHAR(50) NOT NULL,
  nbPlaces Integer NOT NULL CHECK (nbPlaces > 0),
  idSpectacle SERIAL REFERENCES Spectacles
);

CREATE TABLE Tarifs (
  idTarif SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  prix INTEGER NOT NULL CHECK (prix > 0),
  idRepresentation SERIAL REFERENCES Representations
);

CREATE TABLE Tickets (
  idTicket SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  idReference SERIAL NOT NULL,
  idRepresentation SERIAL REFERENCES Representations,
  idTarif SERIAL REFERENCES Tarifs
);

CREATE TABLE Reservations (
  idTicket SERIAL PRIMARY KEY REFERENCES Tickets,
  dateLimite TIMESTAMP
);

CREATE TABLE Vendus (
  idTicket SERIAL PRIMARY KEY REFERENCES Tickets
);

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
RETURNS TABLE (date TIMESTAMP, recettes numeric(10), depenses numeric(10), benefices numeric(10)) AS $$
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

/**************	END FONCTION	****************/

/**********	FONCTION FOR TRIGGER	************/

CREATE OR REPLACE FUNCTION tickets() RETURNS TRIGGER AS $$
    DECLARE
        nbPlace int :=0;
        nbPlaceEnCours int :=0;
        nbTickets int :=0;
    BEGIN
        SELECT nbPlaces INTO nbPlace FROM Representations WHERE idRepresentation=new.idRepresentation;
        SELECT count(*) INTO nbPlaceEnCours FROM Tickets WHERE idRepresentation=new.idRepresentation;
        SELECT count(*) INTO nbTickets FROM Tickets WHERE idRepresentation=new.idRepresentation
            AND nom=new.nom AND idReference!=new.idReference;
        IF nbPlace < nbPlaceEnCours+1 THEN
            RAISE EXCEPTION 'toutes les places sont occupees pour cette representation !';
        ELSIF nbTickets > 0 THEN
            RAISE EXCEPTION 'une reservation a deja eu lieu pour cette representation !';
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
    BEGIN
        SELECT count(*) INTO nb FROM Spectacles WHERE idSpectacle=new.idSpectacle;
        SELECT count(*) INTO nbCres FROM SpectaclesCres WHERE idSpectacle=new.idSpectacle;
        IF nb <= 0 THEN
            RAISE EXCEPTION 'Le spectacle est inconnu !';
        ELSIF nbCres >= 1 THEN
            RAISE EXCEPTION 'Le spectacle existe deja comme un spectacle cres !';
        ELSE
            IF new.date IS NULL THEN
                SELECT date INTO new.dateLimite FROM DateCourante;
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
            SELECT date INTO new.dateLimite FROM DateCourante;
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
            SELECT date INTO new.dateLimite FROM DateCourante;
        END IF;
        return new;
    END;
$$ LANGUAGE plpgsql;

/******	    END FONCTION FOR TRIGGER	********/

/***************	TRIGGER		****************/

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

/***************	INSERT 	****************/

INSERT INTO Salles (capacite, nom, ville, departement, pays) VALUES
    (100, 'Theatre du Chrysanteme', 'Paris', 'Paris', 'France'),
    (150, 'Theatre Imperial', 'Lyon', 'Rhone', 'France'),
    (200, 'Café de la gare', 'Marseille', 'Bouches du Rhone', 'France'),
    (250, 'Theatre Antoine', 'Paris', 'Paris', 'France');

INSERT INTO Organismes (nom, ville, departement, pays) VALUES
    ('Ministere de la Culture', 'Paris', 'Paris', 'France'),
    ('Centre nationnal du theatre', 'Lyon', 'Rhone', 'France'),
    ('Ville de Marseille', 'Marseille', 'Bouches du Rhone', 'France'),
    ('Comedie Francaise', 'Paris', 'Paris', 'France');

INSERT INTO Spectacles (nom) VALUES
    ('Notre-Dame-de-Paris'), ('Cyrano de Bergerac'), ('Hamlet'), ('Le Cid'),
    ('Rhinoceros');

INSERT INTO SpectaclesCres (idSpectacle) VALUES
    ((SELECT idSpectacle FROM Spectacles WHERE nom='Notre-Dame-de-Paris')),
    ((SELECT idSpectacle FROM Spectacles WHERE nom='Cyrano de Bergerac'));

INSERT INTO SpectaclesAchetes (idSpectacle, prix, date, idSalle) VALUES
    ((SELECT idSpectacle from Spectacles WHERE nom='Le Cid'), 2000, '2017-05-09 12:13:51',
        (SELECT idSalle FROM Salles WHERE nom='Theatre Antoine')),
    ((SELECT idSpectacle from Spectacles WHERE nom='Rhinoceros'), 6000, '2017-05-09 12:13:51',
        (SELECT idSalle FROM Salles WHERE nom='Theatre Imperial'));

INSERT INTO ContratDeVentes (prix,date,idSpectacle,idSalle) VALUES
    (3000, '2017-05-10 14:15:19', (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Cyrano de Bergerac'),
        (SELECT idSalle from Salles WHERE nom='Theatre Imperial'));

INSERT INTO Subventions (action, date, prix, idOrganisme, idSpectacle) VALUES
    ('accueil', '2017-05-08 21:14:26', 200, (SELECT idOrganisme FROM Organismes WHERE nom='Ministere de la Culture'), (SELECT SpectaclesAchetes.idSpectacle FROM SpectaclesAchetes JOIN Spectacles ON SpectaclesAchetes.idSpectacle = Spectacles.idSpectacle WHERE Spectacles.nom='Le Cid')),
    ('creation', '2017-05-07 20:41:59', 600, (SELECT idOrganisme FROM Organismes WHERE nom='Centre nationnal du theatre'),(SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE Spectacles.nom='Notre-Dame-de-Paris'));

INSERT INTO CoutProds(prix, date, idSpectacle) VALUES
    (150, '2017-05-08 21:14:26', (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Notre-Dame-de-Paris')),
    (100, '2017-05-09 18:16:18', (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Notre-Dame-de-Paris')),
    (50, '2017-05-10 05:09:19', (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Cyrano de Bergerac'));

INSERT INTO Representations(date, lieu, nbPlaces, idSpectacle) VALUES
    (TIMESTAMP '2017-05-10 22:20:51', 'Paris', 100,
        (SELECT idSpectacle FROM Spectacles WHERE nom='Notre-Dame-de-Paris'));

INSERT INTO Tarifs (nom, prix, idRepresentation) VALUES
    ('Normal', 16, (SELECT idRepresentation FROM Representations JOIN Spectacles
        ON Representations.idSpectacle = Spectacles.idSpectacle WHERE
        nom='Notre-Dame-de-Paris'));

INSERT INTO Tickets (nom, idRepresentation, idTarif) VALUES
    ('Dupond', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-10 22:20:51' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs WHERE idRepresentation=idRepresentation AND nom='Normal')),
    ('Alphonse', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-10 22:20:51' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs WHERE idRepresentation=idRepresentation AND nom='Normal')),
    ('Bertrand', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-10 22:20:51' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs WHERE idRepresentation=idRepresentation AND nom='Normal')),
    ('Pierre', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-10 22:20:51' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs WHERE idRepresentation=idRepresentation AND nom='Normal'));

INSERT INTO Reservations (idTicket) VALUES
    ((SELECT idTicket FROM Tickets WHERE nom='Dupond' AND idReference=1)),
    ((SELECT idTicket FROM Tickets WHERE nom='Alphonse' AND idReference=2));

INSERT INTO Vendus(idTicket) VALUES
    ((SELECT idTicket FROM Tickets WHERE nom='Bertrand' AND idReference=3)),
    ((SELECT idTicket FROM Tickets WHERE nom='Pierre' AND idReference=4));
/**************	END INSERT 	****************/
