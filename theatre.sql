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

DROP TYPE IF EXISTS EnumActions ;

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
  capacite INTEGER CHECK (capacite > 0),
  nom VARCHAR(50) NOT NULL,
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
  prix INTEGER CHECK (prix > 0),
  date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  idSalle SERIAL REFERENCES Salles
);

CREATE TABLE SpectaclesCres (
  idSpectacle SERIAL PRIMARY KEY REFERENCES Spectacles
);

CREATE TABLE CoutProds (
  idCoutProd SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  idSpectacle SERIAL REFERENCES SpectaclesCres
);

CREATE TABLE ContratDeVentes (
  idContratDeVente SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  idSpectacle SERIAL REFERENCES SpectaclesCres,
  idSalle SERIAL REFERENCES Salles
);

CREATE TABLE Subventions (
  action EnumActions NOT NULL,
  date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  prix INTEGER CHECK (prix > 0),
  idOrganisme SERIAL REFERENCES Organismes,
  idSpectacle SERIAL REFERENCES Spectacles,
  PRIMARY KEY (idOrganisme, idSpectacle)
);

CREATE TABLE Representations (
  idRepresentation SERIAL PRIMARY KEY,
  date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  lieu VARCHAR(50) NOT NULL,
  nbPlaces Integer NOT NULL CHECK (nbPlaces > 0),
  idSpectacle SERIAL REFERENCES Spectacles
);

CREATE TABLE Tarifs (
  idTarif SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  prix INTEGER CHECK (prix > 0),
  idRepresentation SERIAL REFERENCES Representations
);

CREATE TABLE Tickets (
  idTicket SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  idRepresentation SERIAL REFERENCES Representations,
  idTarif SERIAL REFERENCES Tarifs
);

CREATE TABLE Reservations (
  idTicket SERIAL PRIMARY KEY REFERENCES Tickets,
  dateLimite TIMESTAMP DEFAULT CURRENT_TIMESTAMP + interval '72 hours'
);

CREATE TABLE Vendus (
  idTicket SERIAL PRIMARY KEY REFERENCES Tickets
);

/***************	FONCTION 	****************/

CREATE OR REPLACE FUNCTION acheteUneReservation(nom VARCHAR(50)) RETURNS void AS $$
    DECLARE
        nb int :=0;
        id int :=0;
    BEGIN
        SELECT count(*) INTO nb FROM Reservations WHERE nom=nom;
        IF nb <= 0 THEN
            RAISE NOTICE 'Le ticket est inconnu !';
            return;
        END IF;
        IF (SELECT dateLimite FROM Reservations WHERE nom=nom) < CURRENT_TIMESTAMP THEN
            DELETE FROM Reservations WHERE nom=nom;
            RAISE NOTICE 'La date limite est depasse !';
            return;
        ELSE
            SELECT idTicket INTO id FROM Reservations WHERE nom=nom;
            DELETE FROM Reservations WHERE nom=nom;
            INSERT INTO Vendus (idTicket) VALUES (id);
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION depenses() RETURNS INT AS $$
    BEGIN
        return (SELECT coalesce(sum(prix),0) FROM SpectaclesAchetes)+(SELECT coalesce(sum(prix),0) FROM CoutProds);
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recettes() RETURNS INT AS $$
    DECLARE
        subvention int :=0;
        ticketsVendus int :=0;
        pieceVendus int :=0;
    BEGIN
        SELECT coalesce(sum(prix),0) INTO subvention FROM Subventions;
        SELECT coalesce(sum(prix),0) INTO ticketsVendus FROM Tickets
        INNER JOIN Tarifs ON tickets.idTarif = Tarifs.idTarif JOIN Vendus ON
        Vendus.idTicket = Tickets.idTicket;
        SELECT coalesce(sum(prix),0) INTO pieceVendus FROM ContratDeVentes;
        return subvention + ticketsVendus + pieceVendus;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION benefices() RETURNS INT AS $$
    BEGIN
        return recettes()-depenses();
    END;
$$ LANGUAGE plpgsql;

/**************	END FONCTION	****************/

/**********	FONCTION FOR TRIGGER	************/

CREATE OR REPLACE FUNCTION ticketsReserves() RETURNS TRIGGER AS $$
    DECLARE
        nb int := 0;
        nbVendus int :=0;
        dateRepresentation TIMESTAMP :=CURRENT_TIMESTAMP;
    BEGIN
        SELECT count(*) INTO nb FROM Tickets WHERE idTicket=new.idTicket;
        SELECT count(*) INTO nbVendus FROM Vendus WHERE idTicket=new.idTicket;
        SELECT date INTO dateRepresentation FROM Representations WHERE
                idRepresentation = (SELECT idRepresentation FROM Tickets
                    WHERE idTicket=new.idTicket);
        IF nb <= 0 THEN
            RAISE NOTICE 'Le ticket est inconnu !';
            return null;
        ELSIF nbVendus >= 1 THEN
            RAISE NOTICE 'Le ticket existe deja comme un ticket achete !';
            return null;
        ELSIF dateRepresentation < new.dateLimite THEN
            IF dateRepresentation < CURRENT_TIMESTAMP THEN
                RAISE NOTICE 'Reservation impossible : la date de la representation est passée';
                return null;
            ELSE /*dateLimite est reduit <72hours */
                new.dateLimite = dateRepresentation;
                return new;
            END IF;
        ELSE
            return new;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ticketsVendus() RETURNS TRIGGER AS $$
    DECLARE
        nb int := 0;
        nbReserve int :=0;
        dateRepresentation TIMESTAMP :=CURRENT_TIMESTAMP;
    BEGIN
        SELECT count(*) INTO nb FROM Tickets WHERE idTicket=new.idTicket;
        SELECT count(*) INTO nbReserve FROM Reservations WHERE idTicket=new.idTicket;
        SELECT date INTO dateRepresentation FROM Representations WHERE
                idRepresentation = (SELECT idRepresentation FROM Tickets
                    WHERE idTicket=new.idTicket);
        IF nb <= 0 THEN
            RAISE NOTICE 'Le ticket est inconnu !';
            return null;
        ELSIF nbReserve >= 1 THEN
            RAISE NOTICE 'Le ticket existe deja comme un ticket reserve !';
            return null;
        ELSIF dateRepresentation < CURRENT_TIMESTAMP THEN
                RAISE NOTICE 'Achat impossible : la date de la representation est passée';
                return null;
        ELSE
            return new;
        END IF;
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
            RAISE NOTICE 'Le spectacle est inconnu !';
            return null;
        ELSIF nbAchete >= 1 THEN
            RAISE NOTICE 'Le spectacle existe deja comme un spectacle achete !';
            return null;
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
            RAISE NOTICE 'Le spectacle est inconnu !';
            return null;
        ELSIF nbCres >= 1 THEN
            RAISE NOTICE 'Le spectacle existe deja comme un spectacle cres !';
            return null;
        ELSE
            return new;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION contratDeVentes() RETURNS TRIGGER AS $$
    DECLARE
        idChrysanteme int :=0;
    BEGIN
        SELECT idSalle INTO idChrysanteme FROM Salles WHERE nom='Threatre du Chrysanteme';
        IF new.idSalle = idChrysanteme THEN
            RAISE NOTICE 'on ne peut pas vendre a nous meme !';
            return null;
        END IF;
        return new;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION nbPlacesInfCapacite() RETURNS TRIGGER AS $$
    DECLARE
        capacite int := 0;
    BEGIN
        SELECT Salles.capacite INTO capacite FROM Salles WHERE nom = 'Chrysanteme';
        IF capacite < new.nbPlaces THEN
            RAISE NOTICE 'le nombre de place souhaite est trop important';
            return null;
        ELSE
            return new;
        END IF;
    END;
$$ LANGUAGE plpgsql;

/******	    END FONCTION FOR TRIGGER	********/

/***************	TRIGGER		****************/

CREATE TRIGGER insertTicketsReserves BEFORE INSERT
ON Reservations FOR EACH ROW EXECUTE PROCEDURE ticketsReserves();

CREATE TRIGGER insertTicketsAchetes BEFORE INSERT
ON Vendus FOR EACH ROW EXECUTE PROCEDURE ticketsVendus();

CREATE TRIGGER insertSpectaclesCres BEFORE INSERT OR UPDATE
ON SpectaclesCres FOR EACH ROW EXECUTE PROCEDURE spectaclesCres();

CREATE TRIGGER insertSpectaclesAchetes BEFORE INSERT OR UPDATE
ON SpectaclesAchetes FOR EACH ROW EXECUTE PROCEDURE spectaclesAchetes();

CREATE TRIGGER insertContratDeVentes BEFORE INSERT OR UPDATE
ON ContratDeVentes FOR EACH ROW EXECUTE PROCEDURE contratDeVentes();

CREATE TRIGGER representationsNbPlaces BEFORE INSERT OR UPDATE OF nbPlaces
ON Representations FOR EACH ROW EXECUTE PROCEDURE nbPlacesInfCapacite();

/************** END TRIGGER		****************/

/***************	INSERT 	****************/

INSERT INTO Salles (capacite, nom, ville, departement, pays) VALUES
    (100, 'Threatre du Chrysanteme', 'Paris', 'Paris', 'France'),
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
    ((SELECT idSpectacle from Spectacles WHERE nom='Le Cid'), 2000, '2017-05-09 12:13:51', (SELECT idSalle FROM Salles WHERE nom='Theatre Antoine')),
    ((SELECT idSpectacle from Spectacles WHERE nom='Rhinoceros'), 6000, '2017-05-09 12:13:51', (SELECT idSalle FROM Salles WHERE nom='Theatre Imperial'));

INSERT INTO ContratDeVentes (prix,date,idSpectacle,idSalle) VALUES
    (3000, '2017-05-10 14:15:19', (SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE Spectacles.nom='Cyrano de Bergerac'), (SELECT idSalle from Salles WHERE nom='Theatre Imperial'));

INSERT INTO Subventions (action,date,prix, idOrganisme, idSpectacle) VALUES
    ('accueil', '2017-05-08 21:14:26', 200, (SELECT idOrganisme FROM Organismes WHERE nom='Ministere de la Culture'), (SELECT SpectaclesAchetes.idSpectacle FROM SpectaclesAchetes JOIN Spectacles ON SpectaclesAchetes.idSpectacle = Spectacles.idSpectacle WHERE Spectacles.nom='Le Cid')),
    ('creation', '2017-05-07 20:41:59', 600, (SELECT idOrganisme FROM Organismes WHERE nom='Centre nationnal du theatre'),(SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE Spectacles.nom='Notre-Dame-de-Paris'));

INSERT INTO CoutProds(prix, date, idSpectacle) VALUES
    (150, '2017-05-08 21:14:26', (SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE Spectacles.nom='Notre-Dame-de-Paris')),
    (100, '2017-05-09 18:16:18', (SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE Spectacles.nom='Notre-Dame-de-Paris')),
    (50, '2017-05-10 05:09:19', (SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE Spectacles.nom='Cyrano de Bergerac'));

INSERT INTO Representations( date, lieu, nbPlaces, idSpectacle) VALUES
    (TIMESTAMP '2017-05-10 22:20:51', 'Paris', 100,
        (SELECT idSpectacle FROM Spectacles WHERE nom='Notre-Dame-de-Paris'));

INSERT INTO Tarifs (nom, prix ,idRepresentation) VALUES
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
    ((SELECT idTicket FROM Tickets WHERE nom='Dupond')),
    ((SELECT idTicket FROM Tickets WHERE nom='Alphonse'));

INSERT INTO Vendus(idTicket) VALUES
    ((SELECT idTicket FROM Tickets WHERE nom='Bertrand')),
    ((SELECT idTicket FROM Tickets WHERE nom='Pierre'));
/**************	END INSERT 	****************/
