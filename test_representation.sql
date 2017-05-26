/*Theatre du Chrysanteme salle : 100*/

/*Insert ok car 90 < 100*/
INSERT INTO Representations(date, lieu, nbPlaces, idSpectacle) VALUES
    (TIMESTAMP '2017-06-10 22:20:51', 'Paris', 90,
    (   SELECT idSpectacle FROM Spectacles WHERE nom='Notre-Dame-de-Paris'));

/*Error car 101 > 100*/
INSERT INTO Representations(date, lieu, nbPlaces, idSpectacle) VALUES
    (TIMESTAMP '2017-06-11 22:20:51', 'Paris', 101,
        (SELECT idSpectacle FROM Spectacles WHERE nom='Notre-Dame-de-Paris'));
