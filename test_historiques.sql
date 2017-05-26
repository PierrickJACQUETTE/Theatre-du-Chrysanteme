/*function benefices mais aussi fonction recettes et depenses uniquement*/

/*benefices (recettes et depenses) du theatre*/
SELECT * FROM benefices(NULL, NULL);

/*benefices (recettes et depenses) par jour, par month, year ...*/
SELECT * FROM benefices(NULL, 'day');

/*benefices (recettes et depenses) par jour, par month, year ... pour un spectacle*/
SELECT * FROM benefices('Le Cid', 'day');

/*benefices (recettes et depenses) par spectacle*/
SELECT * FROM benefices(NULL);

/*benefices (recettes et depenses) pour un spectacle*/
SELECT * FROM benefices('Le Cid');

/*Billet par tarif en fonction d'un spectacle et par representation avec prix*/
SELECT * FROM billetTarif('Notre-Dame-de-Paris');

/*Nombre de Billet par representation avec cout*/
SELECT * FROM billetNB('Notre-Dame-de-Paris');
