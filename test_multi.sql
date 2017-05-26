/*ContratDeVentes*/
/*Error On ne peux pas vendre a nous meme*/
INSERT INTO ContratDeVentes (prix, idSpectacle,idSalle) VALUES
    (3000, (SELECT SpectaclesCres.idSpectacle FROM
        SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
        Spectacles.idSpectacle WHERE Spectacles.nom='Cyrano de Bergerac'),
        (SELECT idSalle from Salles WHERE nom='Theatre du Chrysanteme'));

/*La date est celle du jour par defaut*/
INSERT INTO ContratDeVentes (prix, idSpectacle,idSalle) VALUES
        (3500, (SELECT SpectaclesCres.idSpectacle FROM
            SpectaclesCres JOIN Spectacles ON SpectaclesCres.idSpectacle =
            Spectacles.idSpectacle WHERE Spectacles.nom='Cyrano de Bergerac'),
            (SELECT idSalle from Salles WHERE nom='Theatre Imperial'));

/*Subventions*/
/*La date est celle du jour par defaut*/
INSERT INTO Subventions (action, prix, idOrganisme, idSpectacle) VALUES
    ('creation', 600, (SELECT idOrganisme FROM Organismes WHERE nom='Ministere de la Culture')
    , (SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles
        ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE
        Spectacles.nom='Cyrano de Bergerac'));

/*Error prix <= 0*/
INSERT INTO Subventions (action, prix, idOrganisme, idSpectacle) VALUES
    ('creation', 0, (SELECT idOrganisme FROM Organismes WHERE nom='Ministere de la Culture')
    , (SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles
    ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE
    Spectacles.nom='Cyrano de Bergerac'));

/*CoutProds*/
/*La date est celle du jour par defaut*/
INSERT INTO CoutProds(prix, idSpectacle) VALUES
    (300, (SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles
        ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE
        Spectacles.nom='Notre-Dame-de-Paris'));

/*Error prix <= 0*/
INSERT INTO CoutProds(prix, idSpectacle) VALUES
    (-1, (SELECT SpectaclesCres.idSpectacle FROM SpectaclesCres JOIN Spectacles
        ON SpectaclesCres.idSpectacle = Spectacles.idSpectacle WHERE
        Spectacles.nom='Notre-Dame-de-Paris'));
