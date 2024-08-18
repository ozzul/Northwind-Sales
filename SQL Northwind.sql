SELECT * FROM public.customers
		
SELECT * FROM public.orders

SELECT * FROM public.order_details

SELECT * FROM public.products

SELECT * FROM public.employees

SELECT * FROM public.shippers

SELECT * FROM public.suppliers

SELECT * FROM public.categories


--------GÜNÜMÜZ TARİHİ OLARAK KABUL ETMEK İÇİN SON SİPARİŞ TARİHİNİ BULALIM:
SELECT MAX(shipped_date) AS latest_shipped_date
	FROM orders;

-----------------------------------------------MÜŞTERİ ANALİZİ--------------------------------------------------------



--HANGİ ÜLKEDEN KAÇ MÜŞTERİMİZ VAR? TOPLAM KAÇ MÜŞTERİMİZ VAR?
SELECT country, COUNT(*) AS country_count 
	FROM customers 
		GROUP BY country 
			UNION ALL
SELECT 'TOTAL', COUNT(*) as country_count
	FROM customers
		ORDER BY 2 DESC

			
---CUSTOMERS VE ORDERS TABLOSUNU BİRLEŞTİREREK HANGİ MÜŞTERİ NE ZAMAN VE KAÇ SİPARİŞ VERMİŞ GÖREBİLİRİZ:
SELECT 
	c.customer_id, 
	c.company_name, 
	c.contact_name, 
	c.contact_title, 
	o.order_id, 
	o.employee_id, 
	o.order_date, 
	o.shipped_date, 
	o.ship_country,
	COALESCE(COUNT(o.order_id) OVER (PARTITION BY c.customer_id), 0) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
	ORDER BY 10 DESC
	LIMIT 150
	
----İLK 10 MÜŞTERİ TOPLAM SİPARİŞİN % KAÇINI OLUŞTURUYOR?
		
WITH top_customers AS (
    SELECT 
        c.customer_id, 
        c.company_name, 
        COUNT(o.order_id) AS order_count
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.company_name
    ORDER BY order_count DESC
    LIMIT 10
)
SELECT SUM(order_count) AS top_10_customers_orders
FROM top_customers;

WITH top_customers AS (
    SELECT 
        c.customer_id, 
        c.company_name, 
        COUNT(o.order_id) AS order_count
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.company_name
    ORDER BY order_count DESC
    LIMIT 10
),
total_orders AS (
    SELECT COUNT(*) AS total
    FROM orders
),
top_10_orders AS (
    SELECT SUM(order_count) AS top_10_total
    FROM top_customers
)
SELECT 
    (top_10_total * 100.0 / total) AS percentage_of_top_10_customers
FROM top_10_orders, total_orders;


-----------------------------------------------SİPARİŞ ANALİZİ--------------------------------------------------------

			
-----EN FAZLA GELİR SAĞLAYAN SİPARİŞLERİ, MİKTARLARINI, TUTARLARINI VE İNDİRİM ORANLARINI BULALIM.

SELECT  o.order_id,
		o.customer_id,
		o.order_date,
		od.product_id, 
		od.unit_price, 
		od.quantity,
		od.discount,
		(od.unit_price * od.quantity) AS total_income
FROM orders o
	LEFT JOIN order_details od ON o.order_id=od.order_id
	ORDER BY 8 DESC
	
SELECT  
    p.product_name,
	od.product_id,
    od.unit_price, 
    od.quantity,
    od.discount,
    (od.unit_price * od.quantity) AS original_income,  -- İndirimsiz toplam gelir
    (od.unit_price * od.quantity * od.discount) AS discount_amount,  -- İndirim tutarı
    (od.unit_price * od.quantity * (1 - od.discount)) AS discounted_income  -- İndirimli toplam gelir
FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
GROUP BY 1, 2, 3, 4, 5
ORDER BY discounted_income DESC;


	
------İNDİRİM YAPILAN ÜRÜNLERDE SATIŞLAR ARTMIŞ MIDIR?

	SELECT
    od.product_id,
    p.product_name,
    AVG(od.discount) AS avg_discount,
    SUM(od.quantity) AS total_quantity_sold,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_income
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY od.product_id, p.product_name
HAVING AVG(od.discount) IS NOT NULL
ORDER BY 5 DESC;

---ORTALAMA SİPARİŞ ULAŞTIRMA SÜRESİ NEDİR?
SELECT ROUND(AVG(o.shipped_date - o.order_date), 2) AS avg_days_to_ship
	FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id

----EN ÇOK HAFTANIN HANGİ GÜNLERİ SİPARİŞ VERİLİYOR?
SELECT 
    TO_CHAR(o.order_date, 'Day') AS day_of_week,
    COUNT(o.order_id) AS order_count
		FROM orders o
			GROUP BY TO_CHAR(o.order_date, 'Day')
			ORDER BY order_count DESC


----ÜLKELERE GÖRE AYRIMDA TOPLAM SİPARİŞ SAYISI NEDİR?
SELECT COUNT(*) as
	order_count,
	ship_country
	FROM orders
		GROUP BY ship_country
			ORDER BY 1 DESC
			
-----------------------------------------------ÜRÜN ANALİZİ-----------------------------------------------------------			

	
------TOTAL_PRICE HESAPLAYARAK CİROSU EN YÜKSEK İLK 10 ORDER'I GETİRELİM:	
SELECT order_id, product_id, unit_price, quantity,
       ROUND(unit_price * quantity) AS total_price
			FROM order_details
				ORDER BY 5 DESC 
					LIMIT 10 

-------TOTAL_QUANTITY HESAPLAYARAK EN ÇOK SATAN İLK 10 PRODUCT'I GETİRELİM:
SELECT 
	od.product_id,
	p.product_name,
	p.unit_price,
	SUM(od.quantity) AS total_quantity
		FROM order_details od
	LEFT JOIN products p ON od.product_id = p.product_id
			GROUP BY od.product_id, p.product_name, p.unit_price
				ORDER BY 4 DESC
					LIMIT 10

		
--------EN YÜKSEK FİYATLI 5 ÜRÜN?
SELECT product_id, product_name, unit_price
	FROM products
		ORDER BY unit_price DESC
			LIMIT 5;

--------EN DÜŞÜK FİYATLI 5 ÜRÜN?
SELECT product_id, product_name, unit_price
	FROM products
		ORDER BY unit_price ASC
			LIMIT 5;

---------STOK MİKTARI EN YÜKSEK ÜRÜNLER?
SELECT product_id, product_name, unit_in_stock
	FROM products
		ORDER BY unit_in_stock DESC 
			LIMIT 5;


			
----SİPARİŞLERDE YAPILAN İNDİRİM ORANLARI VE SAYISINI BULARAK İNDİRİM ORTALAMASINI HESAPLAYALIM:
SELECT od.*, p.*
	FROM order_details od
		JOIN products p ON od.product_id = p.product_id
			WHERE od.discount <> 0
				ORDER BY 5 DESC 
				
--TÜM SİPARİŞLERDEKİ ORTALAMA İNDİRİM:
SELECT AVG(disc) AS avg_discount
	FROM (
    	SELECT DISTINCT order_id, discount AS disc
    		FROM order_details )
				AS unique_discounts
--YAPILAN MAX İNDİRİM:
SELECT MAX(disc) AS max_discount
	FROM (
    	SELECT DISTINCT order_id, discount AS disc
    		FROM order_details )
				AS unique_discounts
				
-----------------------------------------------KATEGORİ ANALİZİ-----------------------------------------------------------


--KAÇ KATEGORİ VAR?
SELECT 
	category_id, 
	COUNT (*) AS category_count
	FROM products
		GROUP BY category_id
			ORDER BY 2 DESC
---ÜRÜN VE STOK BİLGİLERİ:
SELECT 
	product_name,
	product_id,
	category_id,
	unit_price,
	unit_in_stock,
	unit_on_order
	FROM products
						
----ÜRÜN KATEGORİSİNE GÖRE ORTALAMA FİYAT VE TOPLAM SATIŞ TUTARLARI:
SELECT 
	p.category_id,
	c.category_name,
    ROUND(AVG(p.unit_price):: numeric, 2) AS avg_price, 
    SUM(od.quantity) AS total_sales
		FROM products p
JOIN order_details od ON p.product_id = od.product_id
JOIN categories c ON p.category_id = c.category_id
	GROUP BY p.category_id, c.category_id, c.category_name
		ORDER BY 4 DESC
		
		
			
-----------------------------------------------ÇALIŞAN ANALİZİ-----------------------------------------------------------

--GÜNÜMÜZ TARİHİ: 06/05/1998 SON SİPARİŞ TARİHİ OLSUN.

---ÇALIŞAN SAYISI?
SELECT 'TOTAL', COUNT(*) as employee_count
	FROM employees
		ORDER BY 2 DESC
		
----ÇALIŞAN YAŞLARI VE YAŞADIĞI ŞEHİRLER?
SELECT employee_id, birth_date, first_name, last_name, city,
       EXTRACT(YEAR FROM AGE('1998-05-06',birth_date)) AS age
FROM employees;

-----ÇALIŞAN BİLGİLERİ VE YAPTIKLARI SATIŞLAR?
SELECT e.employee_id, 
       e.first_name, 
       e.last_name, 
       e.title,
	   e.birth_date,
	   e.city,
       COALESCE(SUM(od.quantity), 0) AS total_quantity,
	   EXTRACT(YEAR FROM AGE('1998-05-06', e.birth_date)) AS age
FROM employees e
		LEFT JOIN orders o ON e.employee_id = o.employee_id
					LEFT JOIN order_details od ON o.order_id = od.order_id
						GROUP BY e.employee_id, e.first_name, e.last_name, e.title, e.birth_date, e.city
							ORDER BY total_quantity DESC
							
							
							
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.title,
    e.birth_date,
    e.city,
    COALESCE(
        ROUND(SUM(od.quantity * od.unit_price)::numeric, 0), 
        0
    ) AS total_income_before_discount,  -- İndirimsiz toplam gelir
    COALESCE(
        ROUND(SUM(od.quantity * od.unit_price * od.discount)::numeric, 0), 
        0
    ) AS total_discount_amount,  -- İndirim tutarları
    COALESCE(
        ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))::numeric, 0), 
        0
    ) AS total_income_after_discount  -- İndirimli toplam gelir
FROM employees e
LEFT JOIN orders o ON e.employee_id = o.employee_id
LEFT JOIN order_details od ON o.order_id = od.order_id
GROUP BY 
    e.employee_id, 
    e.first_name, 
    e.last_name, 
    e.title, 
    e.birth_date, 
    e.city
ORDER BY total_income_after_discount DESC
					
		
------ÇALIŞANLARIN ŞİRKETİMİZE SAĞLADIKLARI TOPLAM GELİRLERİ GÖRELİM?		
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.title,
       e.birth_date,
       e.city,
       COALESCE(ROUND(SUM(od.quantity * od.unit_price)::numeric, 0), 0) AS total_income
FROM employees e
	LEFT JOIN orders o ON e.employee_id = o.employee_id
	LEFT JOIN order_details od ON o.order_id = od.order_id
		GROUP BY e.employee_id, e.first_name, e.last_name, e.title, e.birth_date, e.city
		ORDER BY total_income DESC





-----------------------------------------------TAŞIYICI ANALİZİ----------------------------------------------------			
--ÇALIŞTIĞIMIZ KAÇ NAKLİYE FİRMASI VAR?
SELECT 'TOTAL', shipper_id, COUNT (*) as count_shipper
	FROM shippers
		ORDER BY 1 DESC

---EN ÇOK HANGİ NAKLİYE FİRMASINI KULLANIYORUZ?
SELECT s.company_name,
       COUNT(o.order_id) AS total_orders
			FROM orders o
		LEFT JOIN shippers s ON o.ship_via = s.shipper_id
			GROUP BY s.company_name
				ORDER BY total_orders DESC
				
----EN ÇOK TAŞIMA MALİYETİ HANGİ ÜRÜNLERDE VE HANGİ ÜLKELERDE ÇIKMIŞTIR?
SELECT o.ship_via,
       o.order_date,
       o.order_id,
       o.customer_id,
       o.freight,
       o.ship_country,
       (o.shipped_date - o.order_date) AS days_to_ship
	   FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id
	ORDER BY 5 DESC
	
	WITH RankedOrders AS (
    SELECT  
        o.order_id,
        o.customer_id,
        o.order_date,
        o.freight,
        o.ship_country,
        od.product_id,
        od.unit_price, 
        od.quantity,
        od.discount,
        p.product_name,
        (od.unit_price * od.quantity) AS original_income,  -- İndirimsiz toplam gelir
        (od.unit_price * od.quantity * od.discount) AS discount_amount,  -- İndirim tutarı
        (od.unit_price * od.quantity * (1 - od.discount)) AS discounted_income,  -- İndirimli toplam gelir
        ROW_NUMBER() OVER (PARTITION BY o.order_id ORDER BY (od.unit_price * od.quantity * (1 - od.discount)) DESC) AS rn
    FROM orders o
    LEFT JOIN order_details od ON o.order_id = od.order_id
    JOIN products p ON od.product_id = p.product_id
)
SELECT 
    order_id,
    customer_id,
    order_date,
    freight,
    ship_country,
    product_id,
    unit_price, 
    quantity,
    discount,
    product_name,
    original_income,
    discount_amount,
    discounted_income
FROM RankedOrders
WHERE rn = 1
ORDER BY discounted_income DESC;