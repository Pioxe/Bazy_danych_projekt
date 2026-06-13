--usuwanie
DROP TABLE sprzedaz CASCADE CONSTRAINTS;
DROP TABLE produkty CASCADE CONSTRAINTS;
DROP TABLE czas CASCADE CONSTRAINTS;
DROP TABLE klient CASCADE CONSTRAINTS;
DROP SEQUENCE seq_produkty;
DROP SEQUENCE seq_klient;
DROP SEQUENCE seq_sprzedaz;


-- SELECT COUNT(*) FROM TEMP;
-- DESC TEMP;


-- TABELA WYMIARU: produkty
CREATE TABLE produkty (
id_produktu     NUMBER(10) PRIMARY KEY,
kod_produktu    VARCHAR2(30) NOT NULL,
linia_produktu  VARCHAR2(50) NOT NULL,
msrp            NUMBER(10,2)
);

-- TABELA WYMIARU: czas
CREATE TABLE czas (
id_czasu         NUMBER(10) PRIMARY KEY, 
data_sprzedazy   DATE NOT NULL,          
dzien_tyg_numer  NUMBER(2) NOT NULL,
czy_weekend      VARCHAR2(3) CHECK (czy_weekend IN ('TAK', 'NIE')) NOT NULL,
dzien_tyg_nazwa  VARCHAR2(20) NOT NULL,
miesiac_nazwa    VARCHAR2(20) NOT NULL,
miesiac_numer    NUMBER(2) NOT NULL,
kwartal_numer    NUMBER(1) NOT NULL,
rok              NUMBER(4) NOT NULL
);

-- TABELA WYMIARU: klient
CREATE TABLE klient (
id_klienta          NUMBER(10) PRIMARY KEY,
customer_name       VARCHAR2(100) NOT NULL,
contact_first_name  VARCHAR2(50),
contact_last_name   VARCHAR2(50),
phone               VARCHAR2(30),
address_line_1      VARCHAR2(150),
address_line_2      VARCHAR2(150),
city                VARCHAR2(50),
state               VARCHAR2(50),
postal_code         VARCHAR2(30),
country             VARCHAR2(50),
territory           VARCHAR2(20)
);

-- TABELA FAKTÓW: sprzedaz
CREATE TABLE sprzedaz (
id_sprzedazy      NUMBER(10) PRIMARY KEY,
id_produktu       NUMBER(10) REFERENCES produkty(id_produktu) NOT NULL, 
id_czasu          NUMBER(10)  REFERENCES czas(id_czasu) NOT NULL,       
id_klienta        NUMBER(10) REFERENCES klient(id_klienta) NOT NULL,   
order_number      NUMBER(10) NOT NULL,
order_line_number NUMBER(3)  NOT NULL,
status            VARCHAR2(20),
deal_size         VARCHAR2(20),
quantity_ordered  NUMBER(6)  NOT NULL,
price_each        NUMBER(10,2) NOT NULL,
sales             NUMBER(12,2) NOT NULL
);
commit;


--- MERGE DLA PRODUKTOW
--generator
CREATE SEQUENCE seq_produkty
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

-- MERGE (z DISTINCT)
MERGE INTO produkty t
USING (
    SELECT DISTINCT productcode, productline, msrp 
    FROM temp
) s
ON (t.kod_produktu = s.productcode)

WHEN MATCHED THEN
    UPDATE SET 
        t.linia_produktu = s.productline,
        t.msrp           = s.msrp

WHEN NOT MATCHED THEN
    INSERT (id_produktu, kod_produktu, linia_produktu, msrp)
    VALUES (seq_produkty.NEXTVAL, s.productcode, s.productline, s.msrp);


--SPAWDZENIE ILE CZY TYLE SAMO
-- SELECT COUNT(DISTINCT productcode) FROM temp;
-- SELECT COUNT(*) FROM produkty;
--109




---SELECT * FROM temp order by orderdate;



-- MERGE INTO czas t
-- USING (
--     
-- ) s
-- ON (t.id_czasu = TO_NUMBER(TO_CHAR(s.czysta_data, 'YYYYMMDD')))
-- WHEN NOT MATCHED THEN
--     INSERT (id_czasu, data_sprzedazy, dzien_tyg_numer, czy_weekend, dzien_tyg_nazwa, miesiac_nazwa, miesiac_numer, kwartal_numer, rok)
--     VALUES (
--         TO_NUMBER(),
--         s.czysta_data,
--         TO_NUMBER(),

--     );

-- SELECT column_name, data_type, data_precision, data_scale 
-- FROM user_tab_columns 
-- WHERE table_name = 'czas';
-- SELECT 
--     MAX(TO_NUMBER(TO_CHAR(TRUNC(TO_DATE(orderdate, 'MM/DD/YYYY HH24:MI')), 'YYYYMMDD'))) AS max_id_czasu,
--     MAX(TO_NUMBER(TO_CHAR(TRUNC(TO
--     MAX(TO_NUMBER(TO_CHAR(TRUNC(TO_DATE) AS max_kwartal_num,
--     MAX(TO_NUMBER(TO_CHAR(TRUNC(TO_DATE(o 'YYYY'))) AS max_rok
-- FROM temp;





-- MERGE DLA CZASU
--numer dnia tygodnia do 2 cyfr


MERGE INTO czas t
USING (
    SELECT DISTINCT TRUNC(TO_DATE(orderdate, 'MM/DD/YYYY HH24:MI')) AS czysta_data 
    FROM temp 
) s
ON (t.id_czasu = TO_NUMBER(TO_CHAR(s.czysta_data, 'YYYYMMDD')))
WHEN NOT MATCHED THEN
    INSERT (id_czasu, data_sprzedazy, dzien_tyg_numer, czy_weekend, dzien_tyg_nazwa, miesiac_nazwa, miesiac_numer, kwartal_numer, rok)
    VALUES (
        TO_NUMBER(TO_CHAR(s.czysta_data, 'YYYYMMDD')),
        s.czysta_data,
        TO_NUMBER(TO_CHAR(s.czysta_data, 'ID')),
        CASE WHEN TO_CHAR(s.czysta_data, 'ID') IN ('6', '7') THEN 'TAK' ELSE 'NIE' END,
        TO_CHAR(s.czysta_data, 'Day'),
        TO_CHAR(s.czysta_data, 'Month'),
        TO_NUMBER(TO_CHAR(s.czysta_data, 'MM')),
        TO_NUMBER(TO_CHAR(s.czysta_data, 'Q')),
        TO_NUMBER(TO_CHAR(s.czysta_data, 'YYYY'))
    );

COMMIT;


--- poprawnosc
-- SELECT COUNT(*) FROM czas;
-- SELECT COUNT(DISTINCT TRUNC(TO_DATE(orderdate, 'MM/DD/YYYY HH24:MI'))) AS wszystkie_unikalne_dni
-- FROM temp;
--252




---merge dal klienta

CREATE SEQUENCE seq_klient
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;



MERGE INTO klient k
USING (
    SELECT DISTINCT
        customername, contactfirstname, contactlastname, phone, addressline1, addressline2, city, state, postalcode, country, territory
    FROM temp
    WHERE customername IS NOT NULL
) s
ON (k.customer_name = s.customername) 
-- czy klient już istnieje
WHEN NOT MATCHED THEN
    INSERT (
        id_klienta, customer_name, contact_first_name, contact_last_name, phone, address_line_1, address_line_2, city, state, postal_code, country, territory
    )
    VALUES (seq_klient.NEXTVAL, s.customername, s.contactfirstname, s.contactlastname, s.phone, s.addressline1, s.addressline2, s.city, s.state, s.postalcode, s.country, s.territory);


---spr
-- SELECT COUNT(DISTINCT customername)
-- FROM temp;
-- SELECT COUNT(*)
-- FROM klient;

--92
COMMIT;
-- sprzedarz merge
CREATE SEQUENCE seq_sprzedaz
START WITH 1
INCREMENT BY 1;



MERGE INTO sprzedaz s
USING (
        SELECT
        p.id_produktu, c.id_czasu, k.id_klienta, t.ordernumber, t.orderlinenumber, t.status, t.dealsize, t.quantityordered, t.priceeach, t.sales
    FROM temp t
    JOIN produkty p
        ON p.kod_produktu = t.productcode
    JOIN klient k
        ON k.customer_name = t.customername
    JOIN czas c
        ON c.data_sprzedazy = TO_DATE(t.orderdate, 'MM/DD/YYYY HH24:MI')
) src
ON (
    s.order_number = src.ordernumber
    AND s.order_line_number = src.orderlinenumber
)
WHEN NOT MATCHED THEN
    INSERT (
        id_sprzedazy, id_produktu, id_czasu, id_klienta, order_number, order_line_number, status, deal_size, quantity_ordered, price_each, sales)
    VALUES (
        seq_sprzedaz.NEXTVAL, src.id_produktu, src.id_czasu, src.id_klienta, src.ordernumber, src.orderlinenumber, src.status, src.dealsize, src.quantityordered, src.priceeach, src.sales );



--spr
-- SELECT COUNT(*)
-- FROM sprzedaz;

--2823

commit;
--spr wszystkiego
-- SELECT COUNT(*) FROM temp;
-- SELECT COUNT(*) FROM sprzedaz;
-- SELECT 
--     TO_NUMBER(ordernumber),
--     TO_NUMBER(orderlinenumber),
--     productcode,
--     customername,
--     TO_DATE(orderdate, 'MM/DD/YYYY HH24:MI')
-- FROM temp
-- MINUS
-- SELECT 
--     s.order_number,
--     s.order_line_number,
--     p.kod_produktu,
--     k.customer_name,
--     c.data_sprzedazy
-- FROM sprzedaz s
-- JOIN produkty p ON p.id_produktu = s.id_produktu
-- JOIN klient k ON k.id_klienta = s.id_klienta
-- JOIN czas c ON c.id_czasu = s.id_czasu; 
