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
  idTarifs SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  prix INTEGER CHECK (prix > 0),
  idRepresentation SERIAL REFERENCES Representations
);

CREATE TABLE Tickets (
  idTicket SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  idRepresentation SERIAL REFERENCES Representations,
  idTarifs SERIAL REFERENCES Tarifs
);

CREATE TABLE Reservations (
  idTicket SERIAL PRIMARY KEY REFERENCES Tickets,
  dateLimite TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Vendus (
  idTicket SERIAL PRIMARY KEY REFERENCES Tickets
);

/***************	FONCTION 	****************/
/**************	END FONCTION	****************/

/**********	FONCTION FOR TRIGGER	************/

CREATE OR REPLACE FUNCTION ticketsReserves() RETURNS TRIGGER AS $$
    DECLARE
        nb int := 0;
        nbVendus int :=0;
    BEGIN
        SELECT count(*) INTO nb FROM Tickets WHERE idTicket=new.idTicket;
        SELECT count(*) INTO nbVendus FROM Vendus WHERE idTicket=new.idTicket;
        IF nb <= 0 THEN
            RAISE NOTICE 'Le ticket est inconnu !';
            return null;
        ELSIF nbReserve >= 1 THEN
            RAISE NOTICE 'Le ticket existe deja comme un ticket achete !';
            return null;
        ELSE
            return new;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ticketsVendus() RETURNS TRIGGER AS $$
    DECLARE
        nb int := 0;
        nbReserve int :=0;
    BEGIN
        SELECT count(*) INTO nb FROM Tickets WHERE idTicket=new.idTicket;
        SELECT count(*) INTO nbReserve FROM Reservations WHERE idTicket=new.idTicket;
        IF nb <= 0 THEN
            RAISE NOTICE 'Le ticket est inconnu !';
            return null;
        ELSIF nbReserve >= 1 THEN
            RAISE NOTICE 'Le ticket existe deja comme un ticket reserve !';
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

CREATE TRIGGER insertTicketsReserves BEFORE INSERT OR UPDATE
ON Reservations FOR EACH ROW EXECUTE PROCEDURE ticketsReserves();

CREATE TRIGGER insertTicketsAchetes BEFORE INSERT OR UPDATE
ON Vendus FOR EACH ROW EXECUTE PROCEDURE ticketsVendus();

CREATE TRIGGER insertSpectaclesCres BEFORE INSERT OR UPDATE
ON SpectaclesCres FOR EACH ROW EXECUTE PROCEDURE spectaclesCres();

CREATE TRIGGER insertSpectaclesAchetes BEFORE INSERT OR UPDATE
ON spectaclesAchetes FOR EACH ROW EXECUTE PROCEDURE spectaclesAchetes();

CREATE TRIGGER representationsNbPlaces BEFORE INSERT OR UPDATE OF nbPlaces
ON Representations FOR EACH ROW EXECUTE PROCEDURE nbPlacesInfCapacite();

/************** END TRIGGER		****************/

/***************	INSERT 	****************/

INSERT INTO Salles (capacite, nom, ville, departement, pays) VALUES
    (100, 'Chrysanteme', 'Paris', 'Paris', 'France');

INSERT INTO Spectacles (nom) VALUES
    ('Notre-Dame-de-Paris');

INSERT INTO SpectaclesCres (idSpectacle) VALUES
    ((SELECT idSpectacle from Spectacles WHERE nom='Notre-Dame-de-Paris'));

INSERT INTO Representations( date, lieu, nbPlaces, idSpectacle) VALUES
    (TIMESTAMP '2017-05-05 22:20:51', 'Paris', 100,
        (SELECT idSpectacle from Spectacles WHERE nom='Notre-Dame-de-Paris'));

/**************	END INSERT 	****************/
