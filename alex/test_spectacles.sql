/*Error Spectacles inconnu*/
INSERT INTO SpectaclesCres (idSpectacle) VALUES
    ((SELECT idSpectacle FROM Spectacles WHERE nom='ExistePas'));

/*Error Spectacles achetes*/
INSERT INTO SpectaclesCres (idSpectacle) VALUES
    ((SELECT idSpectacle FROM Spectacles WHERE nom='Le Cid'));

/*Error Spectacles inconnu*/
INSERT INTO SpectaclesAchetes (idSpectacle, prix, date, idSalle) VALUES
    ((SELECT idSpectacle from Spectacles WHERE nom='ExistePas'), 2000, '2017-05-09 12:13:51',
        (SELECT idSalle FROM Salles WHERE nom='Theatre Antoine'));

/*Error Spectacles cres*/
INSERT INTO SpectaclesAchetes (idSpectacle, prix, date, idSalle) VALUES
    ((SELECT idSpectacle from Spectacles WHERE nom='Cyrano de Bergerac'), 2000, '2017-05-09 12:13:51',
        (SELECT idSalle FROM Salles WHERE nom='Theatre Antoine'));

/*Insertion reussi de deux spectacles*/
INSERT INTO Spectacles (nom) VALUES
    ('Phedre'), ('Avare');

/*Insertion reussi dun spectacle cre*/
INSERT INTO SpectaclesCres (idSpectacle) VALUES
    ((SELECT idSpectacle FROM Spectacles WHERE nom='Phedre'));

/*Insertion reussi dun spectacle achete*/
INSERT INTO SpectaclesAchetes (idSpectacle, prix, date, idSalle) VALUES
    ((SELECT idSpectacle from Spectacles WHERE nom='Avare'), 2000, '2017-05-28 12:13:51',
        (SELECT idSalle FROM Salles WHERE nom='Theatre Antoine'));
