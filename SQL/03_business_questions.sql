--CONTROLLO TABELLA
SELECT
    COUNT(*) AS total_rows
FROM ebay_perfume_clean;
--Vediamo le prime righe della tabella pulita 
SELECT *
FROM ebay_perfume_clean
LIMIT 20;
/*CAPSTONE PROJECT — EBAY PERFUME DATASET
            DOMANDE BUSINESS
   1. Quale categoria vende di più: profumi uomo o donna?
   2. Quali brand hanno il maggior numero di vendite?
   3. Quali sono i brand migliori in ogni categoria?
   4. Quali tipi di profumo vendono di più?
   5. I prodotti economici vendono più dei prodotti costosi?
   6. Quali sono i prodotti più venduti?
   7. Quali prodotti generano la revenue stimata più alta?
   8. Quali brand generano la revenue stimata più alta?
   9. Quale categoria genera più revenue stimata?
   10. Quali paesi hanno il maggior numero di prodotti/venditori?
   11. I paesi con più prodotti hanno anche performance di vendita migliori?
   12. Quali brand hanno il prezzo medio più alto?
   13. I brand premium hanno anche buone performance di vendita?
   14. Quali prodotti economici hanno vendite elevate?
   15. Quali prodotti premium hanno vendite elevate?
   16. Quali prodotti hanno molto stock ma poche vendite?
   17. Quali prodotti hanno poco stock ma molte vendite?
   18. Quali combinazioni brand + tipo prodotto performano meglio?
   19. Quali prodotti hanno il miglior rapporto vendite/prezzo?
   20. KPI summary finale del dataset pulito.
*/
--BUSINESS QUESTION 1:
--I profumi uomo o donna vendono di più?(category divide men / women
-- COUNT(*) conta quanti prodotti ci sono
-- SUM(sold) calcola vendite totali
-- AVG(sold) calcola vendite medie per prodotto
-- AVG(price) calcola prezzo medio)
SELECT
    category,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(sold)::numeric, 2) AS avg_sold_per_product,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM ebay_perfume_clean
GROUP BY category
ORDER BY total_sold DESC;
--Nonostante il numero di prodotti sia quasi identico tra profumi uomo e donna,
--le fragranze maschili registrano vendite significativamente più alte (761 vs 489 unità vendute).
--Inoltre, i profumi da uomo hanno anche un prezzo medio superiore (€46 contro €39), 
--suggerendo una domanda e un posizionamento premium più forti nel segmento maschile

-- BUSINESS QUESTION 2:
--Quali brand hanno venduto più unità?(raggruppiamo per brand,sommiamo sold,escludiamo brand NULL)
SELECT
    brand,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(sold)::numeric, 2) AS avg_sold_per_product,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM ebay_perfume_clean
WHERE brand IS NOT NULL
GROUP BY brand
ORDER BY total_sold DESC
LIMIT 50;
-- Vediamo due leader delle vendite : Calvin Klein(145,67) e Versace (128,07) , terzo posto Davidoff(60,28)

--BUSINESS QUESTION 3:
--Quali sono i migliori brand separati per categoria men/women?
--(Prima calcoliamo vendite per category + brand.
--Poi usiamo ROW_NUMBER per creare una classifica separata dentro ogni category)
WITH brand_sales AS (
    SELECT
        category,
        brand,
        COUNT(*) AS number_of_products,
        SUM(sold) AS total_sold,
        ROUND(AVG(price)::numeric, 2) AS avg_price
    FROM ebay_perfume_clean
    WHERE brand IS NOT NULL
    GROUP BY category, brand
),
ranked_brands AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY total_sold DESC
        ) AS brand_rank
    FROM brand_sales
)
SELECT
    category,
    brand_rank,
    brand,
    number_of_products,
    total_sold,
    avg_price
FROM ranked_brands
WHERE brand_rank <= 10
ORDER BY category, brand_rank;
--Per Uomini rimangono tre leader brands: Calvin Klein , Versace, Davidoff
-- Per Donne vediamo Calvin Klein, Versace ed Elizabeth Taylor

--BUSINESS QUESTION 4:
--Quale tipo di prodotto vende di più?
--(Raggruppiamo per type e confrontiamo vendite)

SELECT
    type,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(sold)::numeric, 2) AS avg_sold_per_product,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM ebay_perfume_clean
WHERE type IS NOT NULL
GROUP BY type
ORDER BY total_sold DESC;
--Eau de Toilette è il tipo di prodotto più popolare 

--BUSINESS QUESTION 5:
--La fascia di prezzo influenza le vendite?
--Creiamo fasce prezzo direttamente nella query:
-- Low price: sotto 30
-- Medium price: 30–80
-- High price: sopra 80
---Poi confrontiamo:
-- numero prodotti
-- vendite totali
-- vendite medie per prodotto
SELECT
    CASE
        WHEN price < 30 THEN 'Low price'
        WHEN price BETWEEN 30 AND 80 THEN 'Medium price'
        ELSE 'High price'
    END AS price_segment,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(sold)::numeric, 2) AS avg_sold_per_product,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM ebay_perfume_clean
WHERE price IS NOT NULL
GROUP BY
    CASE
        WHEN price < 30 THEN 'Low price'
        WHEN price BETWEEN 30 AND 80 THEN 'Medium price'
        ELSE 'High price'
    END
ORDER BY avg_sold_per_product DESC;
--Si osserva che i prodotti con prezzi più bassi tendono ad avere volumi di vendita più elevati.

--BUSINESS QUESTION 6:
--Quali singoli prodotti hanno venduto più unità?
--Ordiniamo tutti i prodotti per sold decrescente
SELECT
    category,
    brand,
    title,
    type,
    price,
    sold,
    country
FROM ebay_perfume_clean
ORDER BY sold DESC
LIMIT 20;
-- Tra gli uomini abbiamo :Ck One by Calvin Klein Cologne Perfume Unisex 3.4 oz New In Box
--Tra le donne abbiamo : Escape by Calvin Klein EDP Perfume for Women 3.4 oz New In Box

--BUSINESS QUESTION 7:
--Quali prodotti generano più valore economico stimato?
--Non abbiamo revenue reale.
--La stimiamo con: estimated_revenue = price * sold
--(Questa è una stima, non fatturato ufficiale)
SELECT
    category,
    brand,
    title,
    type,
    price,
    sold,
    ROUND((price * sold)::numeric, 2) AS estimated_revenue
FROM ebay_perfume_clean
WHERE price IS NOT NULL
  AND sold IS NOT NULL
ORDER BY estimated_revenue DESC
LIMIT 20;
--Tra gli uomini vediamo brand Azzaro (Chrome by Azzaro 6.7 / 6.8 oz EDT Cologne for Men New In Box)
--Tra le Donne vediamo brand Calvin Klein (Escape by Calvin Klein EDP Perfume for Women 3.4 oz New In Box)

--BUSINESS QUESTION 8:
--Quali brand generano più revenue stimata?
--(Per ogni brand: sommiamo vendite, calcoliamo revenue stimata, calcoliamo prezzo medio)
SELECT
    brand,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(SUM(price * sold)::numeric, 2) AS estimated_revenue
FROM ebay_perfume_clean
WHERE brand IS NOT NULL
  AND price IS NOT NULL
  AND sold IS NOT NULL
GROUP BY brand
ORDER BY estimated_revenue DESC
LIMIT 20;
--Più revenue stimata genera Versace, Calvin Klein e Davidoff

--BUSINESS QUESTION 9:
--Quale categoria genera più revenue stimata?
--Confrontiamo men vs women usando: price * sold
SELECT
    category,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(SUM(price * sold)::numeric, 2) AS estimated_revenue
FROM ebay_perfume_clean
WHERE price IS NOT NULL
  AND sold IS NOT NULL
GROUP BY category
ORDER BY estimated_revenue DESC;
--Men :25 802,60 estimated revenue
--Women :13 886,55 estimated revenue

--BUSINESS QUESTION 10:
--Da quali paesi arrivano più prodotti/venditori?
--Raggruppiamo per country
SELECT
    country,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM ebay_perfume_clean
WHERE country IS NOT NULL
GROUP BY country
ORDER BY number_of_products DESC;
--più prodotti arrivano da United States e Hong Kong

--BUSINESS QUESTION 11:
--I paesi con tanti prodotti hanno anche buone vendite medie?
--Non guardiamo solo total_sold. Guardiamo anche avg_sold_per_product
--HAVING COUNT(*) >= 5: Evita conclusioni su paesi con pochissimi prodotti.
SELECT
    country,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(sold)::numeric, 2) AS avg_sold_per_product,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM ebay_perfume_clean
WHERE country IS NOT NULL
GROUP BY country
HAVING COUNT(*) >= 5
ORDER BY avg_sold_per_product DESC;
--gli USA hanno tantissimi prodotti ma anche performance medie molto alte.
-- Canada ha buone performance medie, ma pochi prodotti.
--Hong Kong ha i prezzi medi più alti, ma vendite medie inferiori rispetto agli USA.
--Taiwan ha i prezzi molto alti, ma volumi medi più bassi.Potrebbe indicare:
--prodotti premium,nicchia,domanda più limitata.

--BUSINESS QUESTION 12:
--Quali brand sembrano più premium?
--Calcoliamo prezzo medio per brand.
--HAVING COUNT(*) >= 3:Consideriamo solo brand con almeno 3 prodotti,così il risultato è più affidabile
SELECT
    brand,
    COUNT(*) AS number_of_products,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM ebay_perfume_clean
WHERE brand IS NOT NULL
  AND price IS NOT NULL
GROUP BY brand
HAVING COUNT(*) >= 3
ORDER BY avg_price DESC
LIMIT 20;
--Tra i 3 brand premium vediamo : As Picture Show, Roja, Michael Kors

--BUSINESS QUESTION 13:
--I brand con prezzo medio alto hanno anche buone vendite?
--Confrontiamo: avg_price, total_sold, avg_sold_per_product
SELECT
    brand,
    COUNT(*) AS number_of_products,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    SUM(sold) AS total_sold,
    ROUND(AVG(sold)::numeric, 2) AS avg_sold_per_product,
    ROUND(SUM(price * sold)::numeric, 2) AS estimated_revenue
FROM ebay_perfume_clean
WHERE brand IS NOT NULL
  AND price IS NOT NULL
  AND sold IS NOT NULL
GROUP BY brand
HAVING COUNT(*) >= 3
ORDER BY avg_price DESC
LIMIT 30;

--Creed ha forte domanda nonostante il prezzo elevato
--Michael Kors ha il prezzo alto, performance vendita molto forti,un brand molto popolare.
--Penhaligon's ha il prezzo premium e le vendite molto basse

--BUSINESS QUESTION 14:
--Quali prodotti costano poco ma vendono tanto?
--Filtriamo prodotti sotto 30.Poi ordiniamo per sold.
SELECT
    category,
    brand,
    title,
    type,
    price,
    sold
FROM ebay_perfume_clean
WHERE price < 30
ORDER BY sold DESC
LIMIT 20;
--Calvin Klein (Ck One by Calvin Klein Cologne Perfume Unisex 3.4 oz New In Box)

--BUSINESS QUESTION 15
--Quali prodotti premium vendono tanto?
--Filtriamo prodotti con prezzo >= 80.Poi ordiniamo per sold.
SELECT
    category,
    brand,
    title,
    type,
    price,
    sold
FROM ebay_perfume_clean
WHERE price >= 80
ORDER BY sold DESC
LIMIT 20;
--Prada (Prada Luna Rossa by Prada 3.4 oz EDT Cologne for Men New In Box)
--Yves Saint Laurent(Y by Yves Saint Laurent YSL 3.3 / 3.4 oz EDP Cologne for Men New In Box)
--Lancome(Poeme by Lancome 3.4 oz./ 100 ml. L'eau de Parfum Spray for Women in Sealed Box)

--BUSINESS QUESTION 16:
--Quali prodotti potrebbero essere slow movers?
--Slow mover = tanto stock disponibile ma poche vendite.
--Criterio scelto:
--available >= 10
--sold <= 5
SELECT
    category,
    brand,
    title,
    type,
    price,
    available,
    sold,
    available_status
FROM ebay_perfume_clean
WHERE available >= 10
  AND sold <= 5
ORDER BY available DESC, sold ASC
LIMIT 30;
--Elizabeth Arden(Elizabeth Arden White Tea Fragrance Collection Set for Women - 3Pc Mini Gift Set)/price 19.45
--Ulric De Varens(Varens For Men Cafe Vanille Eau De Toilette for MEN - Gourmand, Elegant, Bold)/price 22

--BUSINESS QUESTION 17:
--Quali prodotti sembrano avere alta domanda e poco stock?
--Possibile prodotto da rifornire:
-- available tra 1 e 5
-- sold >= 100
SELECT
    category,
    brand,
    title,
    type,
    price,
    available,
    sold,
    available_status
FROM ebay_perfume_clean
WHERE available BETWEEN 1 AND 5
  AND sold >= 100
ORDER BY sold DESC
LIMIT 30;
--Tommy Hilfiger(TOMMY BOY EST 1985 by Tommy Hilfiger Cologne edt men 3.4 / 3.3 oz NEW in BOX)
--Paul Sebastian(PS by Paul Sebastian Cologne for Men 8 / 8.0 oz Brand New In Box)
--Assorted(Men's Cologne Sample Spray Vials - Choose Scent Combined Shipping)

--BUSINESS QUESTION 18:
--Quali combinazioni brand + tipo prodotto sono più forti?
--Non guardiamo solo brand.Non guardiamo solo type.Guardiamo la combinazione brand + type
SELECT
    brand,
    type,
    COUNT(*) AS number_of_products,
    SUM(sold) AS total_sold,
    ROUND(AVG(sold)::numeric, 2) AS avg_sold_per_product,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(SUM(price * sold)::numeric, 2) AS estimated_revenue
FROM ebay_perfume_clean
WHERE brand IS NOT NULL
  AND type IS NOT NULL
  AND price IS NOT NULL
  AND sold IS NOT NULL
GROUP BY brand, type
HAVING COUNT(*) >= 2
ORDER BY total_sold DESC
LIMIT 30;
--Eau de Toilette (Versace, Davidoff, Calvin Klein) 

--BUSINESS QUESTION 19:
--Quali prodotti vendono tanto rispetto al loro prezzo?
--Creiamo una metrica: sales_per_price = sold / price
--Più è alta, più il prodotto ha tante vendite rispetto al prezzo.
--NULLIF(price, 0):Evita errore se price fosse 0.
SELECT
    category,
    brand,
    title,
    type,
    price,
    sold,
    ROUND((sold / NULLIF(price, 0))::numeric, 2) AS sales_per_price
FROM ebay_perfume_clean
WHERE price IS NOT NULL
  AND sold IS NOT NULL
  AND price > 0
ORDER BY sales_per_price DESC
LIMIT 20;
--2nd To None(6 For $19.95 MEN(M) WOMEN(W) & UNISEX(U) Body Oil Fragrances 10 ml Roll On Pure)
--Assorted(Women Designer Perfume Vials Samples Choose Scents, Combined Shipping & Discount)
--Calvin Klein(Ck One by Calvin Klein Cologne Perfume Unisex 3.4 oz New In Box)

--BUSINESS QUESTION 20:
--KPI SUMMARY
--una vista generale del dataset pulito.
--Metriche:
--- prodotti totali : 1990
--- brand unici : 368
--- tipi prodotto :9
--- paesi venditori :13
--- unità vendute :1 250 751
--- prezzo medio : 43,19
--- revenue stimata : 39 689 155,22

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT brand) AS total_brands,
    COUNT(DISTINCT type) AS total_product_types,
    COUNT(DISTINCT country) AS total_countries,
    SUM(sold) AS total_units_sold,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(SUM(price * sold)::numeric, 2) AS estimated_revenue
FROM ebay_perfume_clean
WHERE price IS NOT NULL
  AND sold IS NOT NULL;












