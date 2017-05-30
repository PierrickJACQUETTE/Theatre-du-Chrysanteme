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
    date TIMESTAMP NOT NULL
);

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
  date TIMESTAMP,
  idSalle SERIAL REFERENCES Salles
);

CREATE TABLE SpectaclesCres (
  idSpectacle SERIAL PRIMARY KEY REFERENCES Spectacles
);

CREATE TABLE CoutProds (
  idCoutProd SERIAL PRIMARY KEY,
  prix INTEGER NOT NULL CHECK (prix > 0),
  date TIMESTAMP,
  idSpectacle SERIAL REFERENCES SpectaclesCres
);

CREATE TABLE ContratDeVentes (
  idContratDeVente SERIAL PRIMARY KEY,
  prix INTEGER NOT NULL CHECK (prix > 0),
  date TIMESTAMP,
  idSpectacle SERIAL REFERENCES SpectaclesCres,
  idSalle SERIAL REFERENCES Salles
);

CREATE TABLE Subventions (
  action EnumActions NOT NULL,
  date TIMESTAMP,
  prix INTEGER NOT NULL CHECK (prix > 0),
  idOrganisme SERIAL REFERENCES Organismes,
  idSpectacle SERIAL REFERENCES Spectacles,
  PRIMARY KEY (idOrganisme, idSpectacle)
);

CREATE TABLE Representations (
  idRepresentation SERIAL PRIMARY KEY,
  date TIMESTAMP,
  dateVente TIMESTAMP,
  lieu VARCHAR(50) NOT NULL,
  nbPlaces Integer NOT NULL CHECK (nbPlaces > 0),
  idSpectacle SERIAL REFERENCES Spectacles
);

CREATE TABLE Tarifs (
  idTarif SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  prix INTEGER CHECK (prix >= 0),
  reduction INTEGER CHECK (reduction >= 0 AND reduction <= 100 ),
  support VARCHAR(50),
  nombre INTEGER,
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
