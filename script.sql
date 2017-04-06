------------------------------------------------------------
--        Script Postgre 
------------------------------------------------------------



------------------------------------------------------------
-- Table: Pieces
------------------------------------------------------------
CREATE TABLE public.Pieces(
	numPiece                 SERIAL NOT NULL ,
	titre                    VARCHAR (25) NOT NULL ,
	auteur                   VARCHAR (25) NOT NULL ,
	numContratAccueil        INT  NOT NULL ,
	numRepresentationExterne INT  NOT NULL ,
	numRepresentationLocale  INT  NOT NULL ,
	CONSTRAINT prk_constraint_Pieces PRIMARY KEY (numPiece)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: PiecesMisEnScenes
------------------------------------------------------------
CREATE TABLE public.PiecesMisEnScenes(
	prixMiseEnScene INT  NOT NULL ,
	dateMisEnScene  TIMESTAMP  NOT NULL ,
	numPiece        INT  NOT NULL ,
	CONSTRAINT prk_constraint_PiecesMisEnScenes PRIMARY KEY (numPiece)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: PiecesExternes
------------------------------------------------------------
CREATE TABLE public.PiecesExternes(
	numPiece INT  NOT NULL ,
	CONSTRAINT prk_constraint_PiecesExternes PRIMARY KEY (numPiece)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: Organismes
------------------------------------------------------------
CREATE TABLE public.Organismes(
	numOrganisme         SERIAL NOT NULL ,
	nomOrganisme         VARCHAR (25) NOT NULL ,
	villeOrganisme       VARCHAR (25) NOT NULL ,
	departementOrganisme VARCHAR (25) NOT NULL ,
	paysOrganisme        VARCHAR (25) NOT NULL ,
	CONSTRAINT prk_constraint_Organismes PRIMARY KEY (numOrganisme)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: ContratsAccueils
------------------------------------------------------------
CREATE TABLE public.ContratsAccueils(
	numContratAccueil  SERIAL NOT NULL ,
	prixAchat          INT  NOT NULL ,
	dateContratAccueil TIMESTAMP  NOT NULL ,
	numPiece           INT  NOT NULL ,
	CONSTRAINT prk_constraint_ContratsAccueils PRIMARY KEY (numContratAccueil)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: Structures
------------------------------------------------------------
CREATE TABLE public.Structures(
	numStructure             SERIAL NOT NULL ,
	nomStructure             VARCHAR (25) NOT NULL ,
	villeStructure           VARCHAR (25) NOT NULL ,
	departementStructure     VARCHAR (2) NOT NULL ,
	paysStructure            VARCHAR (25) NOT NULL ,
	numRepresentationExterne INT  NOT NULL ,
	numContratAccueil        INT  NOT NULL ,
	CONSTRAINT prk_constraint_Structures PRIMARY KEY (numStructure)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: RepresentationsExternes
------------------------------------------------------------
CREATE TABLE public.RepresentationsExternes(
	numRepresentationExterne  SERIAL NOT NULL ,
	dateRepresentationExterne TIMESTAMP  NOT NULL ,
	prixVente                 INT  NOT NULL ,
	dateVente                 TIMESTAMP  NOT NULL ,
	CONSTRAINT prk_constraint_RepresentationsExternes PRIMARY KEY (numRepresentationExterne)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: Tarifs
------------------------------------------------------------
CREATE TABLE public.Tarifs(
	numTarif  SERIAL NOT NULL ,
	libelle   VARCHAR (25) NOT NULL ,
	prixTarif INT  NOT NULL ,
	reduction INT  NOT NULL ,
	numBillet INT  NOT NULL ,
	CONSTRAINT prk_constraint_Tarifs PRIMARY KEY (numTarif)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: RepresentationsLocales
------------------------------------------------------------
CREATE TABLE public.RepresentationsLocales(
	numRepresentationLocale  SERIAL NOT NULL ,
	dateRepresentationLocale TIMESTAMP  NOT NULL ,
	dateOuvertureVente       TIMESTAMP  NOT NULL ,
	prixVenteBilletRef       INT  NOT NULL ,
	nbPlaceMax               INT  NOT NULL ,
	numTarif                 INT   ,
	numBillet                INT  NOT NULL ,
	CONSTRAINT prk_constraint_RepresentationsLocales PRIMARY KEY (numRepresentationLocale)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: Billets
------------------------------------------------------------
CREATE TABLE public.Billets(
	numBillet     SERIAL NOT NULL ,
	numSpectateur INT  NOT NULL ,
	CONSTRAINT prk_constraint_Billets PRIMARY KEY (numBillet)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: Spectateurs
------------------------------------------------------------
CREATE TABLE public.Spectateurs(
	numSpectateur         SERIAL NOT NULL ,
	nomSpectateur         VARCHAR (25) NOT NULL ,
	prenom                VARCHAR (25) NOT NULL ,
	villeSpectateur       VARCHAR (25) NOT NULL ,
	departementSpectateur INT  NOT NULL ,
	paysSpectateur        VARCHAR (25) NOT NULL ,
	numBillet             INT  NOT NULL ,
	CONSTRAINT prk_constraint_Spectateurs PRIMARY KEY (numSpectateur)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: BilletsAchetes
------------------------------------------------------------
CREATE TABLE public.BilletsAchetes(
	dateBilletAchete TIMESTAMP  NOT NULL ,
	numBillet        INT  NOT NULL ,
	CONSTRAINT prk_constraint_BilletsAchetes PRIMARY KEY (numBillet)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: BilletsReserves
------------------------------------------------------------
CREATE TABLE public.BilletsReserves(
	dateBilletReserve TIMESTAMP  NOT NULL ,
	numBillet         INT  NOT NULL ,
	CONSTRAINT prk_constraint_BilletsReserves PRIMARY KEY (numBillet)
)WITHOUT OIDS;


------------------------------------------------------------
-- Table: subvention
------------------------------------------------------------
CREATE TABLE public.subvention(
	montant        INT  NOT NULL ,
	dateSubvention TIMESTAMP  NOT NULL ,
	numPiece       INT  NOT NULL ,
	numOrganisme   INT  NOT NULL ,
	CONSTRAINT prk_constraint_subvention PRIMARY KEY (numPiece,numOrganisme)
)WITHOUT OIDS;



ALTER TABLE public.Pieces ADD CONSTRAINT FK_Pieces_numContratAccueil FOREIGN KEY (numContratAccueil) REFERENCES public.ContratsAccueils(numContratAccueil);
ALTER TABLE public.Pieces ADD CONSTRAINT FK_Pieces_numRepresentationExterne FOREIGN KEY (numRepresentationExterne) REFERENCES public.RepresentationsExternes(numRepresentationExterne);
ALTER TABLE public.Pieces ADD CONSTRAINT FK_Pieces_numRepresentationLocale FOREIGN KEY (numRepresentationLocale) REFERENCES public.RepresentationsLocales(numRepresentationLocale);
ALTER TABLE public.PiecesMisEnScenes ADD CONSTRAINT FK_PiecesMisEnScenes_numPiece FOREIGN KEY (numPiece) REFERENCES public.Pieces(numPiece);
ALTER TABLE public.PiecesExternes ADD CONSTRAINT FK_PiecesExternes_numPiece FOREIGN KEY (numPiece) REFERENCES public.Pieces(numPiece);
ALTER TABLE public.ContratsAccueils ADD CONSTRAINT FK_ContratsAccueils_numPiece FOREIGN KEY (numPiece) REFERENCES public.Pieces(numPiece);
ALTER TABLE public.Structures ADD CONSTRAINT FK_Structures_numRepresentationExterne FOREIGN KEY (numRepresentationExterne) REFERENCES public.RepresentationsExternes(numRepresentationExterne);
ALTER TABLE public.Structures ADD CONSTRAINT FK_Structures_numContratAccueil FOREIGN KEY (numContratAccueil) REFERENCES public.ContratsAccueils(numContratAccueil);
ALTER TABLE public.Tarifs ADD CONSTRAINT FK_Tarifs_numBillet FOREIGN KEY (numBillet) REFERENCES public.Billets(numBillet);
ALTER TABLE public.RepresentationsLocales ADD CONSTRAINT FK_RepresentationsLocales_numTarif FOREIGN KEY (numTarif) REFERENCES public.Tarifs(numTarif);
ALTER TABLE public.RepresentationsLocales ADD CONSTRAINT FK_RepresentationsLocales_numBillet FOREIGN KEY (numBillet) REFERENCES public.Billets(numBillet);
ALTER TABLE public.Billets ADD CONSTRAINT FK_Billets_numSpectateur FOREIGN KEY (numSpectateur) REFERENCES public.Spectateurs(numSpectateur);
ALTER TABLE public.Spectateurs ADD CONSTRAINT FK_Spectateurs_numBillet FOREIGN KEY (numBillet) REFERENCES public.Billets(numBillet);
ALTER TABLE public.BilletsAchetes ADD CONSTRAINT FK_BilletsAchetes_numBillet FOREIGN KEY (numBillet) REFERENCES public.Billets(numBillet);
ALTER TABLE public.BilletsReserves ADD CONSTRAINT FK_BilletsReserves_numBillet FOREIGN KEY (numBillet) REFERENCES public.Billets(numBillet);
ALTER TABLE public.subvention ADD CONSTRAINT FK_subvention_numPiece FOREIGN KEY (numPiece) REFERENCES public.Pieces(numPiece);
ALTER TABLE public.subvention ADD CONSTRAINT FK_subvention_numOrganisme FOREIGN KEY (numOrganisme) REFERENCES public.Organismes(numOrganisme);
