DROP TABLE IF EXISTS Theatre.ContratDeVentes ;
DROP TABLE IF EXISTS Theatre.CoutProds ;
DROP TABLE IF EXISTS Theatre.Tickets ;
DROP TABLE IF EXISTS Theatre.Representations ;
DROP TABLE IF EXISTS Theatre.Subventions ;
DROP TABLE IF EXISTS Theatre.SpectaclesCres ;
DROP TABLE IF EXISTS Theatre.SpectaclesAchetes ;
DROP TABLE IF EXISTS Theatre.Spectacles ;
DROP TABLE IF EXISTS Theatre.Salles ;
DROP TABLE IF EXISTS Theatre.Organismes ;

DROP SCHEMA IF EXISTS Theatre ;

CREATE TYPE EnumActions AS ENUM ('creation', 'accueil');
CREATE TYPE EnumStatus AS ENUM ('reserve', 'achete');

CREATE SCHEMA Theatre;

CREATE TABLE Theatre.Organismes (
  idOrganisme SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL UNIQUE,
  ville VARCHAR(50) NOT NULL,
  departement VARCHAR(50) NOT NULL,
  pays VARCHAR(50) NOT NULL
);

CREATE TABLE Theatre.Salles (
  idSalle SERIAL PRIMARY KEY,
  capacite INTEGER CHECK (capacite > 0),
  nom VARCHAR(50) NOT NULL,
  ville VARCHAR(50) NOT NULL,
  departement VARCHAR(50) NOT NULL,
  pays VARCHAR(50) NOT NULL
);

CREATE TABLE Theatre.Spectacles (
  idSpectacle SERIAL PRIMARY KEY,
  nom VARCHAR(50) UNIQUE NOT NULL,
  tarifNormal INTEGER CHECK (tarifNormal > 0),
  tarifReduit INTEGER CHECK (tarifReduit > 0)
);

CREATE TABLE Theatre.SpectaclesAchetes (
  idSpectacle SERIAL PRIMARY KEY REFERENCES Theatre.Spectacles,
  prix INTEGER CHECK (prix > 0),
  date DATE DEFAULT CURRENT_DATE,
  idSalle SERIAL REFERENCES Theatre.Salles
);

CREATE TABLE Theatre.SpectaclesCres (
  idSpectacle SERIAL PRIMARY KEY REFERENCES Theatre.Spectacles
);


CREATE TABLE Theatre.Subventions (
  id SERIAL PRIMARY KEY,
  action EnumActions NOT NULL,
  date DATE DEFAULT CURRENT_DATE,
  prix INTEGER CHECK (prix > 0),
  idOrganisme SERIAL REFERENCES Theatre.Organismes,
  idSpectacle SERIAL REFERENCES Theatre.Spectacles
);

CREATE TABLE Theatre.Representations (
  idRepresentation SERIAL PRIMARY KEY,
  date DATE NOT NULL,
  lieu VARCHAR(50) NOT NULL,
  reduction INTEGER CHECK (reduction >= 0),
  condition VARCHAR(50),
  nbPlaces Integer NOT NULL CHECK (nbPlaces > 0),
  idSpectacle SERIAL REFERENCES Theatre.Spectacles
);

CREATE TABLE Theatre.Tickets (
  idTicket SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  status EnumStatus,
  idRepresentation SERIAL REFERENCES Theatre.Representations
);

CREATE TABLE Theatre.CoutProds (
  idCoutProd SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  date DATE DEFAULT CURRENT_DATE,
  idSpectacle SERIAL REFERENCES Theatre.SpectaclesCres
);

CREATE TABLE Theatre.ContratDeVentes (
  idContratDeVente SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  date DATE DEFAULT CURRENT_DATE,
  idSpectacle SERIAL REFERENCES Theatre.SpectaclesCres,
  idSalle SERIAL REFERENCES Theatre.Salles
);
