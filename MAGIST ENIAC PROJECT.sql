#basic exploration magist dataset

# 1-How many orders are there in the dataset? The orders table contains a row for each order, so it should be easy to find out! 99441"
SELECT COUNT(*)
FROM orders;

#2-Are orders actually delivered?Look at columns in the orders table: one of them is called order_status. Most orders seem to be delivered, but some aren’t. Find out how many orders are delivered and how many are cancelled, unavailable or in any other status by selecting a count and aggregating by this column."
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status;

#3-Is Magist having user growth? 
SELECT YEAR(order_purchase_timestamp) AS year_,COUNT(customer_id) AS n_customer
FROM orders
WHERE YEAR(order_purchase_timestamp) IN('2018','2017')
GROUP BY year_ 
ORDER BY year_ ;

#4-How many products are there in the products table?
SELECT COUNT(DISTINCT product_id) as "total products"
FROM products;

#5-Which are the categories with most products? find name english 
SELECT COUNT(DISTINCT product_id),product_category_name
FROM products
GROUP BY product_category_name
ORDER BY COUNT(product_id) DESC
LIMIT 10;

#6-How many of those products were present in actual transactions?
SELECT count(DISTINCT product_id) AS n_products
FROM
	order_items;

#7-What’s the price for the most expensive and cheapest products? 
SELECT 
    products.product_category_name,
    max(price) as max_price,
    min(price) as min_price,
    product_category_name_english
FROM 
    order_items
INNER join products on products.product_id = order_items.product_id
INNER JOIN product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name

group by product_category_name
order by max_price desc, min_price desc;

#8-What are the highest and lowest payment values?
SELECT order_payments.payment_value, products.product_id, products.product_category_name, product_category_name_translation.product_category_name_english
FROM order_payments
INNER JOIN order_items
ON order_payments.order_id = order_items.order_id
INNER JOIN products
ON order_items.product_id = products.product_id
INNER JOIN product_category_name_translation
ON products.product_category_name = product_category_name_translation.product_category_name
ORDER BY payment_value DESC; 




/*Business Questions

in relation to the products:

How many different products are being sold?
What are the most popular categories?
How popular are tech products compared to other categories?
What’s the average price of the products being sold?
Are expensive tech products popular?
What’s the average monthly revenue of Magist’s sellers?

-----
In relation to the sellers:

How many sellers are there?
What’s the average revenue of the sellers?
What’s the average revenue of sellers that sell tech products?
In relation to the delivery time:

What’s the average time between the order being placed and the product being delivered?
How many orders are delivered on time vs orders delivered with a delay?
Is there any pattern for delayed orders, e.g. big products being delayed more often?
*/

use magist;

#In relation to the products
#1-What categories of tech products does Magist have?
SELECT COUNT(*) 
FROM (
	SELECT 
		product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm, 
		COUNT(*) AS num_duplicates
	FROM products
	GROUP BY 
		product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm
	HAVING COUNT(product_id) = 1
	ORDER BY COUNT(*) DESC
) prod;

#2-How many products of these tech categories have been sold? 
SELECT products.product_category_name,product_category_name_translation.product_category_name_english,COUNT(order_items.order_id),
CASE
 WHEN product_category_name_translation.product_category_name_english IN ('food','food_drink','drinks') THEN 'Food&Drink'
 WHEN product_category_name_translation.product_category_name_english IN ('auto') THEN 'Automotive'
 WHEN product_category_name_translation.product_category_name_english IN ('art','arts_and_craftmanship','party_supplies','christmas_supplies') THEN 'Art&Craft'
 WHEN product_category_name_translation.product_category_name_english IN ('electronics','computers_accessories','pc_gamer','computers','consoles_games','telephony','watches_gifts') THEN 'Tech'
 WHEN product_category_name_translation.product_category_name_english IN ('sports_leisure','fashion_bags_accessories','fashion_shoes','fashion_sport','fashio_female_clothing','fashion_male_clothing','fashion_childrens_clothes','fashion_underwear_beach','luggage_accessories') THEN 'Fashion'
 WHEN product_category_name_translation.product_category_name_english IN ('bed_bath_table','home_confort','home_comfort_2','air_conditioning','home_appliances','home_appliances_2','small_appliances','garden_tools','flowers','la_cuisine','furniture_mattress_and_upholstery','office_furniture','furniture_bedroom','furniture_living_room','small_appliances_home_oven_and_coffee','portable_kitchen_food_processors','housewares','kitchen_dining_laundry_garden_furniture','furniture_decor') THEN 'Home&Living'
 WHEN product_category_name_translation.product_category_name_english IN ('home_construction','construction_tools_construction','costruction_tools_tools','construction_tools_lights','costruction_tools_garden','construction_tools_safety') THEN 'Construction'
 WHEN product_category_name_translation.product_category_name_english IN ('books_imported','books_general_interest','books_technical') THEN 'Book'
 WHEN product_category_name_translation.product_category_name_english IN ('baby','health_beauty','toys','diapers_and_hygiene','perfumery') THEN 'Beauty&Baby'
 WHEN product_category_name_translation.product_category_name_english IN ('agro_industry_and_commerce','industry_commerce_and_business') THEN 'Industry'
  WHEN product_category_name_translation.product_category_name_english IN ('audio','cds_dvds_musicals','cine_photo','dvds_blu_ray','musical_instruments','music','tablets_printing_image') THEN 'Audio&Photo'
 WHEN product_category_name_translation.product_category_name_english IN ('cool_stuff','market_place','others','stationery','pet_shop','security_and_services','fixed_telephony','signaling_and_security') THEN 'Other'
 END AS  'Categories'
FROM product_category_name_translation 
INNER JOIN products ON product_category_name_translation.product_category_name = products.product_category_name
JOIN order_items ON order_items.product_id = products.product_id
JOIN orders ON orders.order_id = order_items.order_id
GROUP BY Categories;


#3-What’s the average price of the products being sold?
SELECT AVG(a.prod_price) 
FROM (
	SELECT product_id, AVG(price) as prod_price
	FROM order_items
	GROUP BY product_id
) a;

#4-Are expensive tech products popular?
SELECT p.product_category_name, pt.product_category_name_english as 'ENGLISH',
    MAX(oi.price) AS 'Most Expensive',
    CASE 
    WHEN COUNT(DISTINCT p.product_id) >= 1000 THEN "HOT" 
    WHEN COUNT(DISTINCT p.product_id) >= 750  THEN "ON HIGH DEMAND"
    WHEN COUNT(DISTINCT p.product_id) >= 500  THEN "AVERAGE DEMAND"
    WHEN COUNT(DISTINCT p.product_id) >= 250  THEN "LOW DEMAND"
    WHEN COUNT(DISTINCT p.product_id) <  250  THEN "NOT INTERESTING"
    END AS Popularity
FROM products p
JOIN product_category_name_translation pt ON p.product_category_name = pt.product_category_name
JOIN order_items oi ON p.product_id = oi.product_id
    WHERE pt.product_category_name_english IN ('electronics','computers_accessories','pc_gamer','computers','consoles_games','telephony','watches_gifts')
GROUP BY p.product_category_name
ORDER BY MAX(oi.price) DESC;


#In relation to the sellers:

#1-How many sellers are there?
SELECT COUNT(seller_id)
FROM sellers;

#2-What’s the average monthly revenue of Magist’s sellers?
SELECT ROUND(AVG(revenue)) AS avg_revenue FROM(
	SELECT 
		s.seller_id, 
		ROUND(SUM(oi.price)) AS revenue 
	FROM sellers s
		LEFT JOIN order_items oi
		ON s.seller_id = oi.seller_id
	GROUP BY s.seller_id
	ORDER BY revenue DESC
	) a;

#3-What’s the average revenue of sellers that sell tech products?
SELECT ROUND(AVG(mix.seller_monthly_income),2) AS 'Average monthly income', ROUND(MAX(mix.seller_monthly_income),2) AS 'Maximum monthly income', ROUND(MIN(mix.seller_monthly_income),2) AS 'Minimum monthly income', mix.monthyear,
FROM (
SELECT s.seller_id, SUM(price) AS seller_monthly_income, date_format(o.order_purchase_timestamp, '%M %Y') AS monthyear
FROM sellers s
 JOIN order_items oi ON s.seller_id = oi.seller_id
 JOIN orders o ON oi.order_id = o.order_id
 JOIN products p ON oi.product_id = p.product_id
 JOIN product_category_name_translation pt ON p.product_category_name = pt.product_category_name
WHERE pt.product_category_name IN ('electronics','computers_accessories','pc_gamer','computers','consoles_games','watches_gifts')
GROUP BY s.seller_id, date_format(order_purchase_timestamp, '%M %Y')
ORDER BY year(order_purchase_timestamp),month(order_purchase_timestamp)) AS mix
GROUP BY mix.monthyear;  

#In relation to the delivery time:

#1-What’s the average time between the order being placed and the product being delivered?
SELECT AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp))
FROM orders

#2-How many orders are delivered on time vs orders delivered with a delay?
WITH main AS ( 
	SELECT * FROM orders
	WHERE order_delivered_customer_date AND order_estimated_delivery_date IS NOT NULL
    ),
    d1 AS (
	SELECT order_delivered_customer_date - order_estimated_delivery_date AS delay FROM main
    ), 
    d2 AS (
	SELECT 
		CASE WHEN delay > 0 THEN 1 ELSE 0 END AS pos_del,
		CASE WHEN delay <=0 THEN 1 ELSE 0 END AS neg_del FROM d1
	GROUP BY delay
    )
SELECT SUM(pos_del) AS delay, SUM(neg_del) AS on_time FROM d2;

#3-Is there any pattern for delayed orders, e.g. big products being delayed more often?
with main as ( 
	SELECT * FROM orders
	WHERE order_delivered_customer_date AND order_estimated_delivery_date IS NOT NULL
    ),
    d1 as (
	SELECT *, (order_delivered_customer_date - order_estimated_delivery_date)/1000/60/60/24 AS delay FROM main
    )
		SELECT 
			CASE 
				WHEN delay > 101 THEN "> 100 day Delay"
				WHEN delay > 3 AND delay < 8 THEN "3-7 day delay"
                WHEN delay > 1.5 THEN "1.5 - 3 days delay"
				ELSE "< 1.5 day delay"
			END AS "delay_range", 
            AVG(product_weight_g) AS weight_avg,
            MAX(product_weight_g) AS max_weight,
            MIN(product_weight_g) AS min_weight,
            SUM(product_weight_g) AS sum_weight,
            COUNT(*) AS product_count FROM d1 a
    INNER JOIN order_items b
    ON a.order_id = b.order_id
    INNER JOIN products c
    ON b.product_id = c.product_id
    WHERE delay > 0
    GROUP BY delay_range
    ORDER BY weight_avg DESC;