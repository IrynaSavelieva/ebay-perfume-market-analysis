-- 1.Prima visualizzazione del dataset maschile
--Voglio confrontare la struttura del dataset maschile con quella del dataset femminile.
--Cosa scopro:Se le due tabelle hanno colonne simili e se infuturo potranno essere unite.
SELECT * 
FROM ebay_womens_perfume
LIMIT 20;

SELECT *
FROM ebay_mens_perfume
LIMIT 20;
-- 2. Conteggio righe nel dataset femminile e maschile
-- Prima di ogni analisi devo sapere quanti record ho.
-- Cosa scopro:La dimensione del dataset femminile e mascile.
SELECT COUNT(*) AS total_womens_rows
FROM ebay_womens_perfume; --1000 righe

SELECT COUNT(*) AS total_mens_rows
FROM ebay_mens_perfume;--1000 righe

-- 3. Controllo dei valori mancanti nel dataset 
-- Perché:I valori mancanti possono influenzare qualsiasi analisi futura:
-- prezzo medio, vendite, brand più forti e confronto tra prodotti.
-- Cosa scopro: Quali colonne hanno più problemi di qualità.
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN brand IS NULL OR brand = '' THEN 1 ELSE 0 END) AS missing_brand,--1
    SUM(CASE WHEN title IS NULL OR title = '' THEN 1 ELSE 0 END) AS missing_title,--0
    SUM(CASE WHEN type IS NULL OR type = '' THEN 1 ELSE 0 END) AS missing_type,--2
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,--0
    SUM(CASE WHEN available IS NULL THEN 1 ELSE 0 END) AS missing_available,--131
    SUM(CASE WHEN sold IS NULL THEN 1 ELSE 0 END) AS missing_sold,--16
    SUM(CASE WHEN "itemLocation" IS NULL OR "itemLocation" = '' THEN 1 ELSE 0 END) AS missing_location --0
FROM ebay_womens_perfume; -- colonna "itemLocation" è creata con maiuscole, diventa case-sensitive, serve mettere le virgolette 

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN brand IS NULL OR brand = '' THEN 1 ELSE 0 END) AS missing_brand, --1
    SUM(CASE WHEN title IS NULL OR title = '' THEN 1 ELSE 0 END) AS missing_title,--0
    SUM(CASE WHEN type IS NULL OR type = '' THEN 1 ELSE 0 END) AS missing_type,--2
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,--0
    SUM(CASE WHEN available IS NULL THEN 1 ELSE 0 END) AS missing_available,--111
    SUM(CASE WHEN sold IS NULL THEN 1 ELSE 0 END) AS missing_sold,--6
    SUM(CASE WHEN "itemLocation" IS NULL OR "itemLocation" = '' THEN 1 ELSE 0 END) AS missing_location--0
FROM ebay_mens_perfume;
-- 4. Esplorazione dei brand nel dataset 
-- Perché:Il brand può essere uno dei fattori principali legati alle vendite.
-- Cosa scopro:Quali brand appaiono più spesso e se ci sono valori sporchi,scritti male o non standardizzati.
SELECT
    brand,
    COUNT(*) AS number_of_products
FROM ebay_womens_perfume
GROUP BY brand
ORDER BY number_of_products DESC
LIMIT 30; --Donne: Lancome appaia 37 volte, Prada, Clinique, Unbranded appaiano 11 volte 

SELECT
    brand,
    COUNT(*) AS number_of_products
FROM ebay_mens_perfume
GROUP BY brand
ORDER BY number_of_products DESC
LIMIT 30; --Uomini: Armani appaia 60 volte, Givenchy, Gucci, SECERTMU, HERMÈS, Rasasi, Parfums de Marly appaiano 9 volte 

--5.Esplorazione delle categorie di prodotto 
-- Perché:La colonna type può indicare differenze importanti tra prodotti,
-- ad esempio Eau de Parfum, Eau de Toilette, Cologne, ecc.
-- Cosa scopro:Quali tipi di prodotto sono più presenti nel dataset femminile.
---- Se il mercato maschile ha una distribuzione diversa dei tipi di prodotto.
SELECT
    type,
    COUNT(*) AS number_of_products
FROM ebay_womens_perfume
GROUP BY type
ORDER BY number_of_products DESC;--ABBIAMO 72 righe: riga 17 cologne, riga 19 vuota, riga 20 SKIN_MOISTURIZER, riga 22 Perfume, Eau de Parfum, riga 24 BEAUTY,
--riga 25 ASST, riga 28 Parfum, Lotion, Gloss and Blush, riga 29 Eau de Parfum, Eau De Parfume, riga 31 FRAGRANCE BODY MIST, riga 32 3Pc, 
-- riga 36 1 , riga 40 Eau De Parfum 2 Pcs Set, riga 41 EDT, riga 42 /, riga 44 SOLID PERFUME STICK, riga 47 EDP,riga 49 deodorant,riga 50 Eau de Parfum, Spray,
-- riga 51 Does Not Apply, riga 53 ~ BODY FIRM ADVANCED BODY REPAIR TREATMENT ~, riga 57 EDP and Parfum, riga 59 Eau de Parfum/Perfume, riga 70 Does not apply
SELECT 
    type,
    COUNT(*) AS number_of_products
FROM ebay_mens_perfume
GROUP BY type
ORDER BY number_of_products DESC; --abbiamo 65 righe in colona type: riga 13 PARFUM,riga 15 /, riga 17 EDT,riga 18 Does not apply, riga 19 vuota, 
--riga 23 LE PARFUM, riga 25 DIOR HOMME COLOGNE, riga 29 EDC, 
--riga 45 N/A, riga 52 ~ THE ONE EAU DE PARFUM SPRAY ~, riga 55 edt, riga 56 Y , riga 62 Eau de Parfum/ Eau de Toilette

-- 6. Statistiche base sui prezzi:-- Valori molto alti o molto bassi possono indicare outlier.
--il dataset maschile ha prezzi medi più alti, , data set feminile ha il prezzo min piu basso e max piu alto rispetto dataset maschile 
SELECT
    MIN(price) AS min_price,--1,99
    MAX(price) AS max_price,--299,99
    AVG(price) AS avg_price --39.89298014044762
FROM ebay_womens_perfume
WHERE price IS NOT NULL;

SELECT
    MIN(price) AS min_price,--3
    MAX(price) AS max_price,--259,09
    AVG(price) AS avg_price --46.48120019102097
FROM ebay_mens_perfume
WHERE price IS NOT NULL;

-- 7. Prodotti femminili con prezzo più alto
-- Cosa scopro:Se i prodotti più costosi sono reali, premium,oppure possibili errori nei dati.
--NON VEDO OUTLIERS
SELECT
    brand,
    title,
    type,
    price,
    sold,
    available,
    "itemLocation"
FROM ebay_womens_perfume
WHERE price IS NOT NULL
ORDER BY price DESC
LIMIT 20;

SELECT
    brand,
    title,
    type,
    price,
    sold,
    available,
    "itemLocation"
FROM ebay_mens_perfume
WHERE price IS NOT NULL
ORDER BY price DESC
LIMIT 20;
-- 8. Prodotti con più vendite
-- La colonna sold mostra la performance commerciale del prodotto.
-- Cosa scopro:Quali prodotti hanno venduto di più e quali caratteristiche hanno:brand, prezzo, tipo e location.
SELECT
    brand, -- Calvin Klein
    title,--Escape by Calvin Klein EDP Perfume for Women 3.4 oz New In Box
    type,--Eau de Parfum
    price,--26.66
    sold,--17854
    available,--NULL
    "itemLocation"--Hackensack, New Jersey, United States
FROM ebay_womens_perfume
WHERE sold IS NOT NULL
ORDER BY sold DESC
LIMIT 20;

SELECT
    brand,--Calvin Klein
    title,--Ck One by Calvin Klein Cologne Perfume Unisex 3.4 oz New In Box
    type,-- vuoto
    price,--23.89
    sold,--54052
    available,--NULL
    "itemLocation"--Hackensack, New Jersey, United States
FROM ebay_mens_perfume
WHERE sold IS NOT NULL
ORDER BY sold DESC
LIMIT 20;

-- 9. Prezzo medio e vendite medie per tipo di prodotto 
-- Perché:Voglio capire se alcune categorie hanno prezzi o vendite più alte.
-- Cosa scopro:Quali tipi di prodotto performano meglio nel mercato
SELECT
    type,
    COUNT(*) AS number_of_products,--Eau de Parfume
    AVG(price) AS avg_price,--25.84000015258789
    AVG(sold) AS avg_sold --10605.5000000000000000
FROM ebay_womens_perfume
WHERE type IS NOT NULL
GROUP BY type
ORDER BY avg_sold DESC;

SELECT
    type,
    COUNT(*) AS number_of_products,--Fragrance Oil, 29.989999771118164, NULL
    AVG(price) AS avg_price,
    AVG(sold) AS avg_sold
FROM ebay_mens_perfume
WHERE type IS NOT NULL
GROUP BY type
ORDER BY avg_sold DESC;

--10.Brand con migliore performance totale(quali brand generano più vendite complessive)
SELECT
    brand, -- Donne: Calvin Klein
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    AVG(price) AS avg_price
FROM ebay_womens_perfume
WHERE brand IS NOT NULL
GROUP BY brand
ORDER BY total_sold DESC
LIMIT 20;

SELECT
    brand,--Calvin Klein
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    AVG(price) AS avg_price
FROM ebay_mens_perfume
WHERE brand IS NOT NULL
GROUP BY brand
ORDER BY total_sold DESC
LIMIT 20;
ORDER BY total_sold DESC
LIMIT 20;

-- 11. Controllo della disponibilità :la disponibilità può aiutare a capire stock, domanda e prodotti popolari.
SELECT
    brand,
    title,
    available AS quantita_disponibile
FROM ebay_womens_perfume
WHERE available IS NOT NULL
  AND available > 0
ORDER BY available DESC;

SELECT
    brand,
    title,
    available AS quantita_disponibile
FROM ebay_mens_perfume
WHERE available IS NOT NULL
  AND available > 0
ORDER BY available DESC;

-- 12. Esplorazione della colonna availableText
-- Questa colonna può contenere testo misto, per esempio informazioni su disponibilità e vendite nella stessa frase
SELECT
    "availableText",
    COUNT(*) AS number_of_rows
FROM ebay_womens_perfume
GROUP BY "availableText"
ORDER BY number_of_rows DESC
LIMIT 30;

SELECT
    "availableText",
    COUNT(*) AS number_of_rows
FROM ebay_mens_perfume
GROUP BY "availableText"
ORDER BY number_of_rows DESC
LIMIT 30;

-- 13. Esplorazione delle location 
-- La location del venditore può influenzare fiducia, spedizione e vendite.
--scopro differenze geografiche e possibili inconsistenze nei dati
SELECT
    "itemLocation", --riga 17 TX, United States, riga 26 California or Hong Kong, Hong Kong, riga 27 CA, China, riga 28 HongKong, Hong Kong.
    COUNT(*) AS number_of_products
FROM ebay_womens_perfume
GROUP BY "itemLocation"
ORDER BY number_of_products DESC
LIMIT 30;

SELECT
    "itemLocation",--riga 19 New York,United States, Hong Kong
    COUNT(*) AS number_of_products
FROM ebay_mens_perfume
GROUP BY "itemLocation"
ORDER BY number_of_products DESC
LIMIT 30;

-- 14. Creazione temporanea di una tabella combinata uomo + donna
-- Per confrontare i due mercati, è utile unire i dataset e aggiungere una colonna category.
-- Cosi posso fare analisi comparative senza perdere l’origine del dato.
WITH all_perfumes AS (
    SELECT
        'women' AS category,
        brand,
        title,
        type,
        price,
        "priceWithCurrency",
        available,
        "availableText",
        sold,
        "lastUpdated",
        "itemLocation"
    FROM ebay_womens_perfume

    UNION ALL

    SELECT
        'men' AS category,
        brand,
        title,
        type,
        price,
        "priceWithCurrency",
        available,
        "availableText",
        sold,
        "lastUpdated",
        "itemLocation"
    FROM ebay_mens_perfume
)
SELECT *
FROM all_perfumes
LIMIT 20;

-- 15. Confronto generale uomo vs donna
-- il mercato femminile e quello maschile hanno comportamenti diversi?
--scopro:numero prodotti, prezzo medio, vendite medie e vendite totali per categoria.
--Risposta: il segmento maschile presenta un prezzo medio più elevato e un volume di vendite significativamente maggiore rispetto a quello femminile
WITH all_perfumes AS (
    SELECT
        'women' AS category,
        brand,
        title,
        type,
        price,
        available,
        sold,
        "itemLocation"
    FROM ebay_womens_perfume

    UNION ALL

    SELECT
        'men' AS category,
        brand,
        title,
        type,
        price,
        available,
        sold,
        "itemLocation"
    FROM ebay_mens_perfume
)
SELECT
    category,
    COUNT(*) AS number_of_products,
    AVG(price) AS avg_price,
    AVG(sold) AS avg_sold,
    SUM(sold) AS total_sold
FROM all_perfumes
GROUP BY category;

-- 16. Top brand complessivi unendo uomo e donna ( prima di fare pulizia dei dati e sistemare)
--Serve per:capire il dataset, vedere problemi (duplicati, nomi strani)
-- Voglio identificare i brand più forti nell’intero dataset.
--Vediamo nel dataset, i brand più venduti sono Calvin Klein, Versace e Davidoff.Davidoff ha pochi prodotti ma tante vendite
WITH all_perfumes AS (
    SELECT
        'women' AS category,
        brand,
        price,
        sold
    FROM ebay_womens_perfume

    UNION ALL

    SELECT
        'men' AS category,
        brand,
        price,
        sold
    FROM ebay_mens_perfume
)
SELECT
    brand,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    AVG(price) AS avg_price
FROM all_perfumes
WHERE brand IS NOT NULL
GROUP BY brand
ORDER BY total_sold DESC
LIMIT 100;

-- 17. Controllo finale: righe con dati fondamentali mancanti
-- Per l’analisi futura, brand, price e sold sono colonne importanti.
--scopro quante righe potrebbero essere problematiche per l’analisi
--missing brands 1( donna e uomo) , donna 16 missing sold, uomo 6 missing sold 
WITH all_perfumes AS (
    SELECT
        'women' AS category,
        brand,
        title,
        type,
        price,
        available,
        sold,
        "itemLocation"
    FROM ebay_womens_perfume

    UNION ALL

    SELECT
        'men' AS category,
        brand,
        title,
        type,
        price,
        available,
        sold,
        "itemLocation"
    FROM ebay_mens_perfume
)
SELECT
    category,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN brand IS NULL OR brand = '' THEN 1 ELSE 0 END) AS missing_brand,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,
    SUM(CASE WHEN sold IS NULL THEN 1 ELSE 0 END) AS missing_sold
FROM all_perfumes
GROUP BY category;
--In questo file ho eseguito una prima esplorazione di due dataset di profumi eBay:
--uno relativo ai profumi da donna e uno ai profumi da uomo.
--L’obiettivo di questa fase non era ancora la pulizia dei dati, ma comprendere
--la struttura, la qualità e il potenziale analitico dei dataset.
--Ho verificato il numero di righe, analizzato un’anteprima dei dati, identificato
--valori mancanti ed esplorato vari aspetti come brand, tipologie di prodotto, prezzi,
--vendite, disponibilità e localizzazione dei venditori.
--Ho inoltre creato viste temporanee combinate per confrontare i prodotti da uomo e da donna
--e iniziare a individuare possibili domande di business, ad esempio quali brand, tipologie
--di prodotto o fasce di prezzo possano essere associati a migliori performance di vendita.
--Questa fase esplorativa mi ha aiutato a comprendere i principali problemi di qualità dei dati
--e a decidere quali elementi dovranno essere puliti o trasformati nella fase successiva del progetto.


