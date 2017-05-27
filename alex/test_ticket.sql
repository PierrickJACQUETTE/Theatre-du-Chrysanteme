/* Les billets reserves et achetes se comporte identiquement*/

/*Error nombre de tickets < 1*/
SELECT * FROM reserve('test1', 0, 1);
/*Ajoute une reservation pour pierre*/
SELECT * FROM reserve('Paul', 1, 1);
/*Modifie une reservation pour pierre*/
SELECT * FROM reserve('Paul', 1, 1);
/*Possibilite de reserver plusieurs billets en meme temps*/
SELECT * FROM reserve('Paul', 3, 1);

SELECT * FROM tickets WHERE nom ='Paul';

/*Ajoute une reservatin pour pierre => error car deja reservation*/
INSERT INTO Tickets (nom, idRepresentation, idTarif) VALUES
    ('Pierre', (SELECT idRepresentation FROM Representations
    WHERE date='2017-06-29 22:00:00' and lieu='Paris'), (SELECT idTarif
    FROM Tarifs JOIN Representations ON Representations.idRepresentation=
    Tarifs.idRepresentation AND nom='Normal' AND date='2017-06-29 22:00:00'
    AND lieu='Paris'));

/*Ajoute une reservation pour completer la salle*/
INSERT INTO Tickets (nom, idRepresentation, idTarif) VALUES
    ('Ferdinand', (SELECT idRepresentation FROM Representations
    WHERE date='2017-06-29 22:00:00' and lieu='Paris'), (SELECT idTarif
    FROM Tarifs JOIN Representations ON Representations.idRepresentation=
    Tarifs.idRepresentation AND nom='Normal' AND date='2017-06-29 22:00:00'
    AND lieu='Paris'));

/*Error toutes les places sont occupees =>trigger*/
SELECT * FROM reserve('test2', 1, 5);

/*Error date depassee*/
SELECT * FROM reserve('test2', 1, 6);

/*Fonctionne si date < 2017-05-10 22:20:51 sinon error*/
SELECT * FROM acheteUneReservation('Paul',6);
