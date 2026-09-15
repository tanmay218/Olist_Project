--Read data from all the tables to understabd the structure of the tables

SELECT * FROM product_category_name_translation LIMIT 10;

SELECT * FROM customers LIMIT 10;

SELECT * FROM sellers LIMIT 10;

SELECT * FROM products LIMIT 10;

SELECT * FROM geolocation LIMIT 100;

SELECT * FROM orders LIMIT 10;

SELECT * FROM order_items LIMIT 10;

SELECT * FROM order_payments LIMIT 10;

SELECT * FROM order_reviews LIMIT 10;

--Number of rows in each table

SELECT 'product_category_name_translation' AS table_name, COUNT(*) AS total FROM product_category_name_translation
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews;


--------------------------------------------------------------------

--Customers Table

-- Null checks
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS null_unique_id,
    COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS null_zip,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS null_state
FROM customers;

-- Duplicate customer_id (should be 0, it's the PK)
SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Distinct states (sanity check — should be ~27 Brazilian states)
SELECT DISTINCT customer_state FROM customers ORDER BY customer_state;

-- customer_unique_id repeats intentionally (same person, multiple orders) — check the ratio
SELECT 
	   COUNT(DISTINCT customer_id) AS distinct_customer_id,
       COUNT(DISTINCT customer_unique_id) AS distinct_unique_id
FROM customers;

--unwanted spaces check
SELECT customer_id, 'customer_id' AS col, customer_id AS value FROM customers WHERE customer_id != TRIM(customer_id)
UNION ALL
SELECT customer_id, 'customer_unique_id', customer_unique_id FROM customers WHERE customer_unique_id != TRIM(customer_unique_id)
UNION ALL
SELECT customer_id, 'customer_city', customer_city FROM customers WHERE customer_city != TRIM(customer_city)
UNION ALL
SELECT customer_id, 'customer_state', customer_state FROM customers WHERE customer_state != TRIM(customer_state);
----------------------------

--orders table

-- 1. Null checks across all columns
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_ts,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_delivered_date,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated_date
FROM orders;

-- 2. Duplicate order_id (should be 0, it's the PK)
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 3. Order status distribution
SELECT order_status, COUNT(*) AS total
FROM orders
GROUP BY order_status
ORDER BY total DESC;

-- 4. Timestamp logic errors — delivered before purchased (should be 0 rows)
SELECT *
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 5. Timestamp logic errors — approved before purchased (should be 0 rows)
SELECT *
FROM orders
WHERE order_approved_at < order_purchase_timestamp;

-- 6. Delivered but marked as a non-delivered status (mismatch check)
SELECT order_status, COUNT(*)
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_status != 'delivered'
GROUP BY order_status;

-- 7. Status = 'delivered' but missing delivery date (should be 0, but Olist has a few known exceptions)
SELECT order_id, order_status, order_delivered_customer_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 8. Whitespace check on text columns (order_id, customer_id, order_status)
SELECT order_id, 'order_id' AS col FROM orders WHERE order_id != TRIM(order_id)
UNION ALL
SELECT order_id, 'customer_id' FROM orders WHERE customer_id != TRIM(customer_id)
UNION ALL
SELECT order_id, 'order_status' FROM orders WHERE order_status != TRIM(order_status);

-- 9. Case consistency check on order_status (should all be lowercase already, but confirm)
SELECT DISTINCT order_status FROM orders ORDER BY order_status;

-- 10. Orders with no matching customer_id in customers table (orphan check — matters now that FK is dropped)
SELECT o.order_id, o.customer_id
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 11. Estimated delivery earlier than purchase date (logic sanity check)
SELECT *
FROM orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;

-- 12. Carrier date after delivered date (should never happen — courier can't deliver before receiving it... check the reverse too)
SELECT *
FROM orders
WHERE order_delivered_carrier_date > order_delivered_customer_date;	

--fix the issue 
--the columns with true must not be considered during the analysis
ALTER TABLE orders ADD COLUMN IF NOT EXISTS timestamp_anomaly_flag BOOLEAN DEFAULT FALSE;

UPDATE orders
SET timestamp_anomaly_flag = TRUE
WHERE order_delivered_carrier_date > order_delivered_customer_date;

--check the changes
SELECT COUNT(*) FROM orders WHERE timestamp_anomaly_flag = TRUE;

-------------------------------------------------------------------

--order_items cleaning

-- 1. Null checks
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS null_item_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS null_ship_limit,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS null_freight
FROM order_items;

-- 2. Duplicate PK check (order_id + order_item_id should be unique together)
SELECT order_id, order_item_id, COUNT(*)
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- 3. Price/freight sanity checks — negative or zero values
SELECT * FROM order_items WHERE price <= 0;
SELECT * FROM order_items WHERE freight_value < 0;

-- 4. Orphan check — order_id not present in orders
SELECT oi.order_id
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 5. Orphan check — product_id not present in products
SELECT DISTINCT oi.product_id
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 6. Orphan check — seller_id not present in sellers
SELECT DISTINCT oi.seller_id
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- 7. Whitespace check on ID columns
SELECT order_id, 'order_id' AS col FROM order_items WHERE order_id != TRIM(order_id)
UNION ALL
SELECT order_id, 'product_id' FROM order_items WHERE product_id != TRIM(product_id)
UNION ALL
SELECT order_id, 'seller_id' FROM order_items WHERE seller_id != TRIM(seller_id);

-- 8. Shipping limit date earlier than... nothing to compare against directly in this table,
--    but check it against the order's purchase date for logic sanity
SELECT oi.order_id, oi.shipping_limit_date, o.order_purchase_timestamp
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE oi.shipping_limit_date < o.order_purchase_timestamp;

--------------------------------------------------------------------------------

--order_payments

-- 1. Null checks
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE payment_sequential IS NULL) AS null_payment_seq,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS null_payment_type,
    COUNT(*) FILTER (WHERE payment_installments IS NULL) AS null_installments,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS null_payment_value
FROM order_payments;

-- 2. Duplicate PK check (order_id + payment_sequential should be unique together)
SELECT order_id, payment_sequential, COUNT(*)
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- 3. Payment type distribution (sanity check — expect: credit_card, boleto, voucher, debit_card, not_defined)
SELECT payment_type, COUNT(*) AS total
FROM order_payments
GROUP BY payment_type
ORDER BY total DESC;

-- 4. Payment value sanity checks — negative or zero values
SELECT * FROM order_payments WHERE payment_value <= 0;

-- 5. Installments sanity check — negative or zero (0 installments doesn't make sense)
SELECT * FROM order_payments WHERE payment_installments <= 0;

-- 6. Orphan check — order_id not present in orders
SELECT DISTINCT op.order_id
FROM order_payments op
LEFT JOIN orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 7. Whitespace check
SELECT order_id, 'order_id' AS col FROM order_payments WHERE order_id != TRIM(order_id)
UNION ALL
SELECT order_id, 'payment_type' FROM order_payments WHERE payment_type != TRIM(payment_type);

-- 8. Cross-check: total payment_value per order vs. total price+freight per order
--    (large mismatches could indicate data issues, though some variance is expected due to vouchers/discounts)
SELECT 
    o.order_id,
    SUM(DISTINCT op.payment_value) AS total_paid,
    SUM(oi.price + oi.freight_value) AS total_item_cost
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id
HAVING ABS(SUM(DISTINCT op.payment_value) - SUM(oi.price + oi.freight_value)) > 50
ORDER BY ABS(SUM(DISTINCT op.payment_value) - SUM(oi.price + oi.freight_value)) DESC
LIMIT 20;

----------------------------------------------------------------

--	order_reviews

-- 1. Null checks
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE review_id IS NULL) AS null_review_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS null_score,
    COUNT(*) FILTER (WHERE review_comment_title IS NULL) AS null_comment_title,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS null_comment_message,
    COUNT(*) FILTER (WHERE review_creation_date IS NULL) AS null_creation_date,
    COUNT(*) FILTER (WHERE review_answer_timestamp IS NULL) AS null_answer_ts
FROM order_reviews;

-- 2. Duplicate PK check (review_id + order_id should be unique together)
SELECT review_id, order_id, COUNT(*)
FROM order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

-- 3. Duplicate review_id alone (known Olist quirk — same review_id can appear across different orders)
SELECT review_id, COUNT(*)
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- 4. Review score sanity check — should only be 1 to 5
SELECT DISTINCT review_score FROM order_reviews ORDER BY review_score;

-- 5. Score distribution
SELECT review_score, COUNT(*) AS total
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 6. Orphan check — order_id not present in orders
SELECT DISTINCT r.order_id
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 7. Logic check — review answered before it was created (should be 0 rows)
SELECT *
FROM order_reviews
WHERE review_answer_timestamp < review_creation_date;

-- 8. Whitespace check
SELECT review_id, 'review_id' AS col FROM order_reviews WHERE review_id != TRIM(review_id)
UNION ALL
SELECT review_id, 'order_id' FROM order_reviews WHERE order_id != TRIM(order_id);

------------------------------------------------------------

--products table cleaning

-- 1. Null checks
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_category,
    COUNT(*) FILTER (WHERE product_name_lenght IS NULL) AS null_name_len,
    COUNT(*) FILTER (WHERE product_description_lenght IS NULL) AS null_desc_len,
    COUNT(*) FILTER (WHERE product_photos_qty IS NULL) AS null_photos_qty,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS null_weight,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS null_length,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS null_height,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS null_width
FROM products;

-- 2. Duplicate PK check
SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- 3. Zero or negative dimension/weight sanity checks (physically impossible)
SELECT * FROM products WHERE product_weight_g <= 0;
SELECT * FROM products WHERE product_length_cm <= 0;
SELECT * FROM products WHERE product_height_cm <= 0;
SELECT * FROM products WHERE product_width_cm <= 0;

-- 4. Category values not present in translation table (orphan check, no FK now)
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;

-- 5. Whitespace check
SELECT product_id, 'product_id' AS col FROM products WHERE product_id != TRIM(product_id)
UNION ALL
SELECT product_id, 'product_category_name' FROM products WHERE product_category_name != TRIM(product_category_name);

-- 6. Distinct category count sanity check (Olist has ~71-74 categories typically)
SELECT COUNT(DISTINCT product_category_name) FROM products;


---------------------------------------------------------
-- 1. Null checks
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE geolocation_zip_code_prefix IS NULL) AS null_zip,
    COUNT(*) FILTER (WHERE geolocation_lat IS NULL) AS null_lat,
    COUNT(*) FILTER (WHERE geolocation_lng IS NULL) AS null_lng,
    COUNT(*) FILTER (WHERE geolocation_city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE geolocation_state IS NULL) AS null_state
FROM geolocation;

-- 2. Full duplicate rows (since there's no PK, exact duplicates are possible and common in this file)
SELECT geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state, COUNT(*)
FROM geolocation
GROUP BY geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- 3. Distinct state count (should be ~27)
SELECT DISTINCT geolocation_state FROM geolocation ORDER BY geolocation_state;

-- 4. Lat/lng out-of-range sanity check for Brazil
--    Brazil's approximate bounding box: lat -34 to 6, lng -74 to -32
SELECT * FROM geolocation
WHERE geolocation_lat NOT BETWEEN -34 AND 6
   OR geolocation_lng NOT BETWEEN -74 AND -32;

-- 5. Whitespace check
SELECT geolocation_zip_code_prefix, 'city' AS col FROM geolocation WHERE geolocation_city != TRIM(geolocation_city)
UNION ALL
SELECT geolocation_zip_code_prefix, 'state' FROM geolocation WHERE geolocation_state != TRIM(geolocation_state);

-- 6. Case inconsistency check on city names (common issue in this file — e.g. "sao paulo" vs "SÃO PAULO")
SELECT DISTINCT geolocation_city
FROM geolocation
WHERE geolocation_city ~ '[A-Z]' AND geolocation_city ~ '[a-z]'
ORDER BY geolocation_city
LIMIT 30;

-------------------------------------------------------

--sellers table
	
-- 1. Null checks
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE seller_zip_code_prefix IS NULL) AS null_zip,
    COUNT(*) FILTER (WHERE seller_city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE seller_state IS NULL) AS null_state
FROM sellers;

-- 2. Duplicate PK check
SELECT seller_id, COUNT(*)
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- 3. Distinct state count sanity check (should be ~23, sellers are less geographically spread than customers)
SELECT DISTINCT seller_state FROM sellers ORDER BY seller_state;

-- 4. Whitespace check
SELECT seller_id, 'seller_id' AS col FROM sellers WHERE seller_id != TRIM(seller_id)
UNION ALL
SELECT seller_id, 'seller_city' FROM sellers WHERE seller_city != TRIM(seller_city)
UNION ALL
SELECT seller_id, 'seller_state' FROM sellers WHERE seller_state != TRIM(seller_state);

-- 5. Case inconsistency check on city names
SELECT DISTINCT seller_city
FROM sellers
WHERE seller_city ~ '[A-Z]' AND seller_city ~ '[a-z]'
ORDER BY seller_city;

-- 6. Orphan check — sellers with zip prefix not present in geolocation (informational, not necessarily a fix)
SELECT DISTINCT s.seller_zip_code_prefix
FROM sellers s
LEFT JOIN geolocation g ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;

--------------------------------------------------------

--product_category_name_translation

-- 1. Null checks
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_category_pt,
    COUNT(*) FILTER (WHERE product_category_name_english IS NULL) AS null_category_en
FROM product_category_name_translation;

-- 2. Duplicate PK check
SELECT product_category_name, COUNT(*)
FROM product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- 3. Duplicate English translations (multiple Portuguese names mapping to the same English name — not necessarily wrong, but worth knowing)
SELECT product_category_name_english, COUNT(*)
FROM product_category_name_translation
GROUP BY product_category_name_english
HAVING COUNT(*) > 1;

-- 4. Whitespace check
SELECT product_category_name, 'category_pt' AS col FROM product_category_name_translation WHERE product_category_name != TRIM(product_category_name)
UNION ALL
SELECT product_category_name, 'category_en' FROM product_category_name_translation WHERE product_category_name_english != TRIM(product_category_name_english);

-- 5. Categories in products that are missing from this table (reverse of the check we ran earlier)
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;






	








