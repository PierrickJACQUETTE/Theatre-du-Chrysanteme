TRUNCATE TABLE ContratDeVentes RESTART IDENTITY;
TRUNCATE TABLE CoutProds RESTART IDENTITY;
TRUNCATE TABLE Reservations RESTART IDENTITY;
TRUNCATE TABLE Vendus RESTART IDENTITY;
TRUNCATE TABLE Tickets RESTART IDENTITY CASCADE;
TRUNCATE TABLE Tarifs RESTART IDENTITY CASCADE;
TRUNCATE TABLE Representations RESTART IDENTITY CASCADE;
TRUNCATE TABLE Subventions RESTART IDENTITY;
TRUNCATE TABLE SpectaclesCres RESTART IDENTITY CASCADE;
TRUNCATE TABLE SpectaclesAchetes RESTART IDENTITY;
TRUNCATE TABLE Spectacles RESTART IDENTITY CASCADE;
TRUNCATE TABLE Salles RESTART IDENTITY CASCADE;
TRUNCATE TABLE Organismes RESTART IDENTITY CASCADE;

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
        (SELECT idSalle from Salles WHERE nom='Theatre Imperial')),
    (2500, '2017-05-11 19:18:16', (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Cyrano de Bergerac'),
        (SELECT idSalle from Salles WHERE nom='Café de la gare')),
    (2600, '2017-05-12 09:23:13', (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Cyrano de Bergerac'),
        (SELECT idSalle from Salles WHERE nom='Theatre Antoine')),
    (2700, '2017-05-13 10:25:10', (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Notre-Dame-de-Paris'),
        (SELECT idSalle from Salles WHERE nom='Theatre Imperial')),
    (3100, '2017-05-14 16:28:59', (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Notre-Dame-de-Paris'),
        (SELECT idSalle from Salles WHERE nom='Theatre Antoine')),
    (3200, '2017-05-15 20:30:05', (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Notre-Dame-de-Paris'),
        (SELECT idSalle from Salles WHERE nom='Café de la gare'));

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

INSERT INTO Representations(date, lieu, nbPlaces, reduction, reducNombre, support, temps, idSpectacle) VALUES
    (TIMESTAMP '2017-05-10 22:20:51', 'Paris', 100, NULL, NULL, NULL, NULL,
        (SELECT idSpectacle FROM Spectacles WHERE nom='Notre-Dame-de-Paris')),
    (TIMESTAMP '2017-06-02 21:00:00', 'Paris', 80, 10, 5, 'billet', 'first',
        (SELECT idSpectacle FROM Spectacles WHERE nom='Le Cid')),
    (TIMESTAMP '2017-05-28 21:00:00', 'Paris', 100, 15, 1, 'day' , 'first',
        (SELECT idSpectacle FROM Spectacles WHERE nom='Cyrano de Bergerac')),
    (TIMESTAMP '2017-06-01 22:00:00', 'Paris', 70, 20, 5, 'day', 'last',
        (SELECT idSpectacle FROM Spectacles WHERE nom='Hamlet')),
    (TIMESTAMP '2017-06-29 22:00:00', 'Paris', 2, NULL, NULL, NULL, NULL,
        (SELECT idSpectacle FROM Spectacles WHERE nom='Hamlet'));

INSERT INTO Tarifs (nom, prix, idRepresentation) VALUES
    ('Normal', 16, (SELECT idRepresentation FROM Representations JOIN Spectacles
        ON Representations.idSpectacle = Spectacles.idSpectacle WHERE
        nom='Notre-Dame-de-Paris' AND date='2017-05-10 22:20:51')),
    ('Reduit', 14, (SELECT idRepresentation FROM Representations JOIN Spectacles
        ON Representations.idSpectacle = Spectacles.idSpectacle WHERE
        nom='Notre-Dame-de-Paris' AND date='2017-05-10 22:20:51')),
    ('Normal', 18, (SELECT idRepresentation FROM Representations JOIN Spectacles
        ON Representations.idSpectacle = Spectacles.idSpectacle WHERE
        nom='Le Cid')),
    ('Normal', 20, (SELECT idRepresentation FROM Representations JOIN Spectacles
        ON Representations.idSpectacle = Spectacles.idSpectacle WHERE
        nom='Cyrano de Bergerac')),
    ('Normal', 25, (SELECT idRepresentation FROM Representations JOIN Spectacles
        ON Representations.idSpectacle = Spectacles.idSpectacle WHERE
        nom='Hamlet' AND date='2017-06-01 22:00:00')),
    ('Normal', 25, (SELECT idRepresentation FROM Representations JOIN Spectacles
        ON Representations.idSpectacle = Spectacles.idSpectacle WHERE
        nom='Hamlet' AND date='2017-06-29 22:00:00')),
    ('Normal', 16, (SELECT idRepresentation FROM Representations JOIN Spectacles
        ON Representations.idSpectacle = Spectacles.idSpectacle WHERE
        nom='Notre-Dame-de-Paris' AND date='2017-05-08 22:00:00'));

INSERT INTO Tickets (nom, idRepresentation, idTarif) VALUES
    ('Dupond', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-10 22:20:51' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs JOIN Representations ON Representations.idRepresentation=
        Tarifs.idRepresentation AND nom='Normal' AND date='2017-05-10 22:20:51'
        AND lieu='Paris')),
    ('Alphonse', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-10 22:20:51' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs JOIN Representations ON Representations.idRepresentation=
        Tarifs.idRepresentation AND nom='Normal' AND date='2017-05-10 22:20:51'
        AND lieu='Paris')),
    ('Bertrand', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-10 22:20:51' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs JOIN Representations ON Representations.idRepresentation=
        Tarifs.idRepresentation AND nom='Normal' AND date='2017-05-10 22:20:51'
        AND lieu='Paris')),
    ('Pierre', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-10 22:20:51' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs JOIN Representations ON Representations.idRepresentation=
        Tarifs.idRepresentation AND nom='Reduit' AND date='2017-05-10 22:20:51'
        AND lieu='Paris')),
    ('Alphonse2', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-08 22:00:00' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs JOIN Representations ON Representations.idRepresentation=
        Tarifs.idRepresentation AND nom='Normal' AND date='2017-05-10 22:20:51'
        AND lieu='Paris')),
    ('Bertrand2', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-08 22:00:00' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs JOIN Representations ON Representations.idRepresentation=
        Tarifs.idRepresentation AND nom='Normal' AND date='2017-05-10 22:20:51'
        AND lieu='Paris')),
    ('Pierre2', (SELECT idRepresentation FROM Representations
        WHERE date='2017-05-08 22:00:00' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs JOIN Representations ON Representations.idRepresentation=
        Tarifs.idRepresentation AND nom='Reduit' AND date='2017-05-10 22:20:51'
        AND lieu='Paris')),
    ('Pierre', (SELECT idRepresentation FROM Representations
        WHERE date='2017-06-29 22:00:00' and lieu='Paris'), (SELECT idTarif
        FROM Tarifs JOIN Representations ON Representations.idRepresentation=
        Tarifs.idRepresentation AND nom='Normal' AND date='2017-06-29 22:00:00'
        AND lieu='Paris'));

INSERT INTO Reservations (idTicket) VALUES
    ((SELECT idTicket FROM Tickets WHERE nom='Dupond' AND idReference=1)),
    ((SELECT idTicket FROM Tickets WHERE nom='Alphonse' AND idReference=2));

INSERT INTO Vendus(idTicket) VALUES
    ((SELECT idTicket FROM Tickets WHERE nom='Pierre' AND idReference=8)),
    ((SELECT idTicket FROM Tickets WHERE nom='Bertrand' AND idReference=3)),
    ((SELECT idTicket FROM Tickets WHERE nom='Pierre' AND idReference=4)),
    ((SELECT idTicket FROM Tickets WHERE nom='Bertrand2' AND idReference=6)),
    ((SELECT idTicket FROM Tickets WHERE nom='Pierre2' AND idReference=7)),
    ((SELECT idTicket FROM Tickets WHERE nom='Alphonse2' AND idReference=5));
/**************	END INSERT 	****************/
