DROP TABLE IF EXISTS Theatre.Organisme ;
DROP TABLE IF EXISTS Theatre.Subvention ;
DROP TABLE IF EXISTS Theatre.Spectacle ;
DROP TABLE IF EXISTS Theatre.Representation ;
DROP TABLE IF EXISTS Theatre.TicketsAchete ;
DROP TABLE IF EXISTS Theatre.TicketReserve ;
DROP TABLE IF EXISTS Theatre.CoutProd ;
DROP TABLE IF EXISTS Theatre.PieceAchetees ;
DROP TABLE IF EXISTS Theatre.PieceCrees ;
DROP TABLE IF EXISTS Theatre.ContratVente ;
DROP TABLE IF EXISTS Theatre.Salles ;

DROP SCHEMA IF EXISTS Theatre ;

CREATE SCHEMA Theatre;
CREATE TABLE Theatre.Organisme (
  id SERIAL PRIMARY KEY,
  nom VARCHAR NOT NULL UNIQUE,
  ville VARCHAR NOT NULL,
  departement VARCHAR NOT NULL,
  pays VARCHAR NOT NULL
);

CREATE TABLE Theatre.Spectacle (
  id SERIAL PRIMARY KEY,
  nom VARCHAR NOT NULL UNIQUE,
  tarifNormal INTEGER CHECK (tarifNormal > 0),
  tarifReduit INTEGER CHECK (tarifReduit > 0)
);

CREATE TABLE Theatre.Subvention (
  id SERIAL PRIMARY KEY,
  Action VARCHAR NOT NULL,
  date DATE DEFAULT CURRENT_DATE,
  prix INTEGER CHECK (prix > 0),
  idOrdanisme REFERENCES Theatre.Organisme,
  idSpectacle REFERENCES Theatre.Spectacle
);

CREATE TABLE Theatre.Representation (
  id SERIAL PRIMARY KEY,
  date DATE NOT NULL,
  lieu VARCHAR NOT NULL,
  reduction INTEGER CHECK (reduction >= 0),
  condition VARCHAR,
  nbPlaces Integer NOT NULL CHECK (nbPlaces > 0),
  idSpectacle REFERENCES Theatre.Spectacle
);

CREATE TABLE Theatre.TicketsAchete (
  id SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  idRepresentation REFERENCES Theatre.Representation
);

CREATE TABLE Theatre.TicketReserve (
  id SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  status VARCHAR,
  idRepresentation REFERENCES Theatre.Representation
);

CREATE TABLE Theatre.PieceCrees (
  id SERIAL PRIMARY KEY,
  nom VARCHAR UNIQUE NOT NULL,
  date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE Theatre.CoutProd (
  id SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  date DATE DEFAULT CURRENT_DATE,
  idPieceCrees REFERENCES Theatre.PieceCrees
);

CREATE TABLE Theatre.Salles (
  id SERIAL PRIMARY KEY,
  capacite INTEGER CHECK (capacite > 0),
  nom VARCHAR NOT NULL,
  ville VARCHAR NOT NULL,
  departement VARCHAR NOT NULL,
  pays VARCHAR NOT NULL
);

CREATE TABLE Theatre.PieceAchetees (
  id SERIAL PRIMARY KEY,
  prix INTEGER CHECK (prix > 0),
  date DATE DEFAULT CURRENT_DATE,
  idPieceCrees REFERENCES Theatre.PieceCrees
);

CREATE TABLE Theatre.PieceCrees (
  id SERIAL PRIMARY KEY,
  nom VARCHAR UNIQUE NOT NULL,
  prix INTEGER CHECK (prix > 0),
  date DATE DEFAULT CURRENT_DATE,
  idSalle REFERENCES Theatre.Salles
);


GRANT USAGE ON SCHEMA Theatre to PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA  Theatre to PUBLIC;
