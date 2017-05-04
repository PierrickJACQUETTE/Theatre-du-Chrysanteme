DROP TABLE IF EXISTS ContratDeVentes ;
DROP TABLE IF EXISTS CoutProds ;
DROP TABLE IF EXISTS Tickets ;
DROP TABLE IF EXISTS Representations ;
DROP TABLE IF EXISTS Subventions ;
DROP TABLE IF EXISTS SpectaclesCres ;
DROP TABLE IF EXISTS SpectaclesAchetes ;
DROP TABLE IF EXISTS Spectacles ;
DROP TABLE IF EXISTS Salles ;
DROP TABLE IF EXISTS Organismes ;

DROP TYPE IF EXISTS EnumActions ;
DROP TYPE IF EXISTS EnumStatus;

CREATE TYPE EnumActions AS ENUM ('creation', 'accueil');
CREATE TYPE EnumStatus AS ENUM ('reserve', 'achete');


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
  nom VARCHAR(50) UNIQUE NOT NULL,
  tarifNormal INTEGER CHECK (tarifNormal > 0),
  tarifReduit INTEGER CHECK (tarifReduit > 0)
);

CREATE TABLE SpectaclesAchetes (
  idSpectacle SERIAL PRIMARY KEY REFERENCES Spectacles,
  prix INTEGER CHECK (prix > 0),
  date DATE DEFAULT CURRENT_DATE,
  idSalle SERIAL REFERENCES Salles
);

CREATE TABLE SpectaclesCres (
  idSpectacle SERIAL PRIMARY KEY REFERENCES Spectacles
);

CREATE TABLE Subventions (
  id SERIAL PRIMARY KEY,
  action EnumActions NOT NULL,
  date DATE DEFAULT CURRENT_DATE,
  prix INTEGER CHECK (prix > 0),
  idOrganisme SERIAL REFERENCES Organismes,
  idSpectacle SERIAL REFERENCES Spectacles
);

CREATE TABLE Representations (
  idRepresentation SERIAL PRIMARY KEY,
  date DATE NOT NULL,
  lieu VARCHAR(50) NOT NULL,
  reduction INTEGER CHECK (reduction >= 0),
  condition VARCHAR(50),
  nbPlaces Integer NOT NULL CHECK (nbPlaces > 0),
  idSpectacle SERIAL REFERENCES Spectacles
);

CREATE TABLE Tickets (
  idTicket SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  status EnumStatus,
  idRepresentation SERIAL REFERENCES Representations
);

CREATE TABLE CoutProds (
  idCoutProd SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  date DATE DEFAULT CURRENT_DATE,
  idSpectacle SERIAL REFERENCES SpectaclesCres
);

CREATE TABLE ContratDeVentes (
  idContratDeVente SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  date DATE DEFAULT CURRENT_DATE,
  idSpectacle SERIAL REFERENCES SpectaclesCres,
  idSalle SERIAL REFERENCES Salles
);
