--FASE 1 — CREARE UNA TABELLA UNICA UOMO + DONNA
/*Abbiamo due tabelle separate:
   - ebay_mens_perfume
   - ebay_womens_perfume

   Per fare cleaning e analisi più facilmente, le uniamo in una tabella unica.
   Aggiungiamo una nuova colonna chiamata category per sapere se il prodotto
   arriva dal dataset "men" o "women".
*/
CREATE TABLE ebay_perfume_raw AS
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
FROM ebay_mens_perfume;
--Controllo:
SELECT
    category,
    COUNT(*) AS total_rows
FROM ebay_perfume_raw
GROUP BY category;
/*
FASE 2 — CREARE UNA TABELLA DI CLEANING
   Non vogliamo modificare subito la tabella originale.
   Creiamo una nuova tabella dove lavoriamo sui dati puliti.
*/
CREATE TABLE ebay_perfume_cleaning AS
SELECT
    category,
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
FROM ebay_perfume_raw;
/* Controllo veloce */
SELECT *
FROM ebay_perfume_cleaning
LIMIT 20;
--FASE 3 — PULIRE SPAZI VUOTI NELLE COLONNE TESTUALI
--Problema:Alcuni valori possono avere spazi prima o dopo il testo.
--Esempio:' Dior ' invece di 'Dior'
--Soluzione:Usiamo TRIM()
UPDATE ebay_perfume_cleaning
SET
    brand = TRIM(brand),
    title = TRIM(title),
    type = TRIM(type),
    "priceWithCurrency" = TRIM("priceWithCurrency"),
    "availableText" = TRIM("availableText"),
    "lastUpdated" = TRIM("lastUpdated"),
    "itemLocation" = TRIM("itemLocation");

--FASE 4 — TRASFORMARE STRINGHE VUOTE IN NULL
--Problema: è meglio usare NULL per indicare dati mancanti.
 UPDATE ebay_perfume_cleaning
SET
    brand = NULLIF(brand, ''),
    title = NULLIF(title, ''),
    type = NULLIF(type, ''),
    "priceWithCurrency" = NULLIF("priceWithCurrency", ''),
    "availableText" = NULLIF("availableText", ''),
    "lastUpdated" = NULLIF("lastUpdated", ''),
    "itemLocation" = NULLIF("itemLocation", '');  

--FASE 5 — CONTROLLARE VALORI MANCANTI DOPO LA PRIMA PULIZIA
--Dopo aver trasformato stringhe vuote in NULL, controlliamo meglio quali colonne hanno problemi
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN brand IS NULL THEN 1 ELSE 0 END) AS missing_brand,
SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS missing_title,
SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) AS missing_type,
SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,
SUM(CASE WHEN available IS NULL THEN 1 ELSE 0 END) AS missing_available,
SUM(CASE WHEN sold IS NULL THEN 1 ELSE 0 END) AS missing_sold,
SUM(CASE WHEN "lastUpdated" IS NULL THEN 1 ELSE 0 END) AS missing_last_updated,
SUM(CASE WHEN "itemLocation" IS NULL THEN 1 ELSE 0 END) AS missing_location
FROM ebay_perfume_cleaning;
--ABBIAMO : missing brand-2, missing title-0, missing type-4, missing price-0, 
--missing available-242, missing sold-22, missing last updated-126, missing location-0 .

--FASE 6 — CREARE COLONNA BRAND PULITA
--La colonna brand contiene valori poco utili come:
-- As Shown
-- AS SHOW
-- Unbranded
-- Does Not Apply
-- N/A
--Creiamo una nuova colonna brand_clean
ALTER TABLE ebay_perfume_cleaning
ADD COLUMN brand_clean TEXT;

--Inseriamo brand pulito 
UPDATE ebay_perfume_cleaning
SET brand_clean =
CASE
WHEN brand IS NULL THEN NULL
WHEN LOWER(brand) IN (
            'as shown',
            'as show',
            'show',
            'unbranded',
            'does not apply',
            'n/a',
            'na',
            'none',
            'unknown'
        )
        THEN NULL
ELSE INITCAP(LOWER(brand))
    END;
--Controllo brand dopo pulizia
SELECT
    brand,
    brand_clean,
    COUNT(*) AS number_of_rows
FROM ebay_perfume_cleaning
GROUP BY brand, brand_clean
ORDER BY number_of_rows DESC
LIMIT 50;

--FASE 7 — CREARE COLONNA TYPE PULITA
--type contiene molti valori simili:
-- Eau de Parfum
-- EDP
-- Eau De Parfume
-- Eau de Parfum Spray
-- EDT
-- Eau de Toilette
-- Cologne
-- Does not apply
-- /
--voglio standardizzare le categorie principali
ALTER TABLE ebay_perfume_cleaning
ADD COLUMN type_clean TEXT;

UPDATE ebay_perfume_cleaning
SET type_clean =
CASE
WHEN type IS NULL THEN NULL
WHEN LOWER(type) IN (
'/',
'n/a',
'na',
'does not apply',
'does not apply.',
'none'
)
THEN null
WHEN LOWER(type) ILIKE '%perfume oil%'
THEN 'Perfume Oil'
WHEN LOWER(type) LIKE '%eau de parfum%'
          OR LOWER(type) LIKE '%edp%'
          OR LOWER(type) ILIKE '%Eau de Perfume%'
        THEN 'Eau de Parfum'
WHEN LOWER (type) ILIKE '%Perfum%'
		OR LOWER(type)ILIKE'%Perfume%'
		OR LOWER(type)ILIKE'%Parfum%'
		THEN 'Parfum'
WHEN LOWER(type) LIKE '%eau de toilette%'
          OR LOWER(type) LIKE '%edt%'
        THEN 'Eau de Toilette'
WHEN LOWER(type) LIKE '%cologne%'
          OR LOWER(type) LIKE '%edc%'
        THEN 'Cologne'
WHEN LOWER(type) LIKE '%body mist%'
          OR LOWER(type) LIKE '%mist%'
        THEN 'Body Mist'
WHEN LOWER(type) LIKE '%lotion%'
        THEN 'Lotion'
WHEN LOWER(type) LIKE '%deodorant%'
        THEN 'Deodorant'
ELSE 'Other'
    END;
--Controllo type prima e dopo cleaning:(Perfume oil, Eau de Parfum, Parfum, 
--Eau de Toilette, Cologne, Body Mist,Lotion, Deodorant, Other)
SELECT type, type_clean,
    COUNT(*) AS number_of_rows
FROM ebay_perfume_cleaning
GROUP BY type, type_clean
ORDER BY number_of_rows DESC;

--FASE 8 — GESTIRE SOLD MANCANTE
--sold indica quante unità sono state vendute.
--alcune righe hanno sold NULL.
--Scelta di cleaning:
--Se sold è NULL, possiamo creare una nuova colonna sold_clean dove mettiamo 0.
--Perché 0? In questo caso NULL può significare che non sono state registrate vendite.

ALTER TABLE ebay_perfume_cleaning
ADD COLUMN sold_clean INTEGER;

UPDATE ebay_perfume_cleaning
SET sold_clean =
    CASE
        WHEN sold IS NULL THEN 0
        ELSE sold::INTEGER
    END;
--Controllo sold
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN sold IS NULL THEN 1 ELSE 0 END) AS original_missing_sold,
    SUM(CASE WHEN sold_clean IS NULL THEN 1 ELSE 0 END) AS missing_sold_clean,
    MIN(sold_clean) AS min_sold,
    MAX(sold_clean) AS max_sold
FROM ebay_perfume_cleaning;

--FASE 9 — GESTIRE AVAILABLE MANCANTE
--available ha tanti valori NULL

ALTER TABLE ebay_perfume_cleaning
ADD COLUMN available_clean INTEGER;

ALTER TABLE ebay_perfume_cleaning
ADD COLUMN available_status TEXT;

UPDATE ebay_perfume_cleaning
set 
available_clean =
        CASE
            WHEN available IS NULL THEN NULL
            ELSE available::INTEGER
END,
available_status =
        CASE
            WHEN available IS NULL THEN 'Unknown'
            WHEN available = 0 THEN 'Out of stock'
            WHEN available > 0 THEN 'Available'
            ELSE 'Unknown'
        END;
--Controllo disponibilità : Available- 1758, Unknown-242.
SELECT
    available_status,
    COUNT(*) AS number_of_rows
FROM ebay_perfume_cleaning
GROUP BY available_status
ORDER BY number_of_rows DESC;

--FASE 10 — CREARE COLONNA PRICE CLEAN
--price è già numerica, ma creiamo price_clean per avere una colonna finale.
--Inoltre controlliamo eventuali prezzi strani
ALTER TABLE ebay_perfume_cleaning
ADD COLUMN price_clean NUMERIC(10,2);


UPDATE ebay_perfume_cleaning
SET price_clean =
    CASE
        WHEN price IS NULL THEN NULL
        WHEN price <= 0 THEN NULL
        ELSE ROUND(price::NUMERIC, 2)
    END;
--Controllo prezzo
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN price_clean IS NULL THEN 1 ELSE 0 END) AS missing_price_clean,
    MIN(price_clean) AS min_price, --1,99
    MAX(price_clean) AS max_price, --299,99
    AVG(price_clean) AS avg_price --43,18709
FROM ebay_perfume_cleaning;

--FASE 11 — CREARE COLONNE LOCATION PULITE
--itemLocation contiene valori misti:
-- "Allen Park, Michigan, United States"
-- "New Jersey, Hong Kong"
-- "CA, China"
--facciamo una pulizia semplice:
--prendiamo l’ultima parte dopo l’ultima virgola come country_clean
ALTER TABLE ebay_perfume_cleaning
ADD COLUMN country_clean TEXT;


UPDATE ebay_perfume_cleaning
SET country_clean =
    CASE
        WHEN "itemLocation" IS NULL THEN NULL
        WHEN "itemLocation" LIKE '%,%' THEN TRIM(SPLIT_PART("itemLocation", ',', ARRAY_LENGTH(STRING_TO_ARRAY("itemLocation", ','), 1)))
        ELSE TRIM("itemLocation")
    END;
--Controllo paesi più frequenti
SELECT
    country_clean,
    COUNT(*) AS number_of_products
FROM ebay_perfume_cleaning
GROUP BY country_clean
ORDER BY number_of_products DESC
LIMIT 30;
--vediamo United States e Estados Unidos 
UPDATE ebay_perfume_cleaning
SET country_clean = 'United States'
WHERE country_clean = 'Estados Unidos';
--verifica:
SELECT
    country_clean,
    COUNT(*) AS number_of_products
FROM ebay_perfume_cleaning
GROUP BY country_clean
ORDER BY number_of_products DESC;

--FASE 12 — CREARE COLONNA LAST_UPDATED CLEAN
--lastUpdated è testo: esempio "May 24, 2024 10:03:04 PDT"
--rimuoviamo " PDT" e convertiamo in timestamp

ALTER TABLE ebay_perfume_cleaning
ADD COLUMN last_updated_clean TIMESTAMP;

SELECT "lastUpdated"
FROM ebay_perfume_cleaning
WHERE "lastUpdated" IS NOT NULL
LIMIT 20;

UPDATE ebay_perfume_cleaning
SET last_updated_clean =
CASE
    WHEN "lastUpdated" IS NULL THEN NULL
    ELSE (
        REPLACE("lastUpdated", ' PDT', '')
    )::timestamp
END;
--Controllo date
SELECT
    MIN(last_updated_clean) AS first_update,
    MAX(last_updated_clean) AS last_update,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN last_updated_clean IS NULL THEN 1 ELSE 0 END) AS missing_last_updated_clean
FROM ebay_perfume_cleaning;

--FASE 13 — CERCARE DUPLICATI
--Prima controlliamo
SELECT
    category,
    brand_clean,
    title,
    price_clean,
    COUNT(*) AS duplicate_count
FROM ebay_perfume_cleaning
GROUP BY
    category,
    brand_clean,
    title,
    price_clean
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
--FASE 14 — CREARE TABELLA FINALE PULITA SENZA DUPLICATI
--Usiamo ROW_NUMBER().
--Se troviamo duplicati, teniamo solo la prima riga.
--Criterio: duplicato = stessa category + stesso title + stesso price_clean
CREATE TABLE ebay_perfume_clean AS
WITH ranked_products AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY category, title, price_clean
            ORDER BY sold_clean DESC, last_updated_clean DESC
        ) AS row_num
    FROM ebay_perfume_cleaning
)
SELECT
    category,
    brand_clean AS brand,
    title,
    type_clean AS type,
    price_clean AS price,
    available_clean AS available,
    available_status,
    sold_clean AS sold,
    country_clean AS country,
    last_updated_clean AS last_updated
FROM ranked_products
WHERE row_num = 1;
--FASE 15 — CONTROLLO FINALE DELLA TABELLA CLEAN
SELECT *
FROM ebay_perfume_clean
LIMIT 50;
--Conteggio finale righe : men-994, women-996
SELECT
    category,
    COUNT(*) AS total_clean_rows
FROM ebay_perfume_clean
GROUP BY category;
--Controllo valori mancanti nella tabella finale
SELECT
    COUNT(*) AS total_rows, --1990
    SUM(CASE WHEN brand IS NULL THEN 1 ELSE 0 END) AS missing_brand,--107
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS missing_title,--0
    SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) AS missing_type,--13
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,--0
    SUM(CASE WHEN available IS NULL THEN 1 ELSE 0 END) AS missing_available,--240
    SUM(CASE WHEN sold IS NULL THEN 1 ELSE 0 END) AS missing_sold,--0
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS missing_country,--0
    SUM(CASE WHEN last_updated IS NULL THEN 1 ELSE 0 END) AS missing_last_updated--124
FROM ebay_perfume_clean;

--FASE 16 — QUERY DI ANALISI DOPO CLEANING
--Ora posso fare analisi più pulite
SELECT
    category,
    COUNT(*) AS number_of_products,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(sold) AS total_sold,
    ROUND(AVG(sold), 2) AS avg_sold
FROM ebay_perfume_clean
GROUP BY category;

--Top brand dopo cleaning
SELECT
    brand,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(price), 2) AS avg_price
FROM ebay_perfume_clean
WHERE brand IS NOT NULL
GROUP BY brand
ORDER BY total_sold DESC
LIMIT 20;
--Performance per tipo prodotto
SELECT
    type,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(price), 2) AS avg_price
FROM ebay_perfume_clean
WHERE type IS NOT NULL
GROUP BY type
ORDER BY total_sold DESC;


--CONTROLLARE BRAND MANCANTI
SELECT
    title,
    type,
    price
FROM ebay_perfume_clean
WHERE brand IS NULL
LIMIT 50;
--VEDIAMO CARATTERI STRANI:
SELECT title
FROM ebay_perfume_clean
WHERE title ~ '[🥇^\w\s,/-]';

UPDATE ebay_perfume_clean
SET title =
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(title, '🥇', ''),
                '🦋', ''),
            '✅', ''),
        '🌺', ''),
    '💯', '');

SELECT title
FROM ebay_perfume_clean
WHERE title ~ '[^a-zA-Z0-9[:space:].,/%&()\-]';


--ABBIAMO FATTO :
--unione dataset
--gestione NULL
--standardizzazione brand
--standardizzazione type
--pulizia testo
--parsing date
--parsing location
--gestione duplicati
--creazione tabella finale clean


























