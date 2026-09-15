--Creating The Tables

-- 1. product_category_name_translation
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- 2. customers
CREATE TABLE customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- 3. sellers
CREATE TABLE sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- 4. products
CREATE TABLE products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght NUMERIC,
    product_description_lenght NUMERIC,
    product_photos_qty NUMERIC,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

-- 5. geolocation
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat NUMERIC,
    geolocation_lng NUMERIC,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2)
);

-- 6. orders
CREATE TABLE orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- 7. order_items
CREATE TABLE order_items (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(32) NOT NULL,
    seller_id VARCHAR(32) NOT NULL,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- 8. order_payments
CREATE TABLE order_payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- 9. order_reviews
CREATE TABLE order_reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32) NOT NULL,
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);

CREATE OR REPLACE PROCEDURE load_olist_data()
LANGUAGE plpgsql
AS $$
BEGIN

    -- 1. product_category_name_translation
    RAISE NOTICE '>> Truncating Table: product_category_name_translation';
    TRUNCATE TABLE product_category_name_translation CASCADE;
    RAISE NOTICE '>> Inserting Data Into: product_category_name_translation';
    EXECUTE format($f$
        COPY product_category_name_translation
        FROM %L WITH (FORMAT csv, HEADER true, DELIMITER ',')
    $f$, 'C:/Users/KIIT0001/Desktop/Olist/product_category_name_translation.csv');

    -- 2. customers
    RAISE NOTICE '>> Truncating Table: customers';
    TRUNCATE TABLE customers CASCADE;
    RAISE NOTICE '>> Inserting Data Into: customers';
    EXECUTE format($f$
        COPY customers
        FROM %L WITH (FORMAT csv, HEADER true, DELIMITER ',')
    $f$, 'C:/Users/KIIT0001/Desktop/Olist/olist_customers_dataset.csv');

    -- 3. sellers
    RAISE NOTICE '>> Truncating Table: sellers';
    TRUNCATE TABLE sellers CASCADE;
    RAISE NOTICE '>> Inserting Data Into: sellers';
    EXECUTE format($f$
        COPY sellers
        FROM %L WITH (FORMAT csv, HEADER true, DELIMITER ',')
    $f$, 'C:/Users/KIIT0001/Desktop/Olist/olist_sellers_dataset.csv');

    -- 4. products
    RAISE NOTICE '>> Truncating Table: products';
    TRUNCATE TABLE products CASCADE;
    RAISE NOTICE '>> Inserting Data Into: products';
    EXECUTE format($f$
        COPY products
        FROM %L WITH (FORMAT csv, HEADER true, DELIMITER ',')
    $f$, 'C:/Users/KIIT0001/Desktop/Olist/olist_products_dataset.csv');

    -- 5. geolocation
    RAISE NOTICE '>> Truncating Table: geolocation';
    TRUNCATE TABLE geolocation CASCADE;
    RAISE NOTICE '>> Inserting Data Into: geolocation';
    EXECUTE format($f$
        COPY geolocation
        FROM %L WITH (FORMAT csv, HEADER true, DELIMITER ',')
    $f$, 'C:/Users/KIIT0001/Desktop/Olist/olist_geolocation_dataset.csv');

    -- 6. orders
    RAISE NOTICE '>> Truncating Table: orders';
    TRUNCATE TABLE orders CASCADE;
    RAISE NOTICE '>> Inserting Data Into: orders';
    EXECUTE format($f$
        COPY orders
        FROM %L WITH (FORMAT csv, HEADER true, DELIMITER ',')
    $f$, 'C:/Users/KIIT0001/Desktop/Olist/olist_orders_dataset.csv');

    -- 7. order_items
    RAISE NOTICE '>> Truncating Table: order_items';
    TRUNCATE TABLE order_items CASCADE;
    RAISE NOTICE '>> Inserting Data Into: order_items';
    EXECUTE format($f$
        COPY order_items
        FROM %L WITH (FORMAT csv, HEADER true, DELIMITER ',')
    $f$, 'C:/Users/KIIT0001/Desktop/Olist/olist_order_items_dataset.csv');

    -- 8. order_payments
    RAISE NOTICE '>> Truncating Table: order_payments';
    TRUNCATE TABLE order_payments CASCADE;
    RAISE NOTICE '>> Inserting Data Into: order_payments';
    EXECUTE format($f$
        COPY order_payments
        FROM %L WITH (FORMAT csv, HEADER true, DELIMITER ',')
    $f$, 'C:/Users/KIIT0001/Desktop/Olist/olist_order_payments_dataset.csv');

    -- 9. order_reviews
    RAISE NOTICE '>> Truncating Table: order_reviews';
    TRUNCATE TABLE order_reviews CASCADE;
    RAISE NOTICE '>> Inserting Data Into: order_reviews';
    EXECUTE format($f$
        COPY order_reviews
        FROM %L WITH (FORMAT csv, HEADER true, DELIMITER ',')
    $f$, 'C:/Users/KIIT0001/Desktop/Olist/olist_order_reviews_dataset.csv');

    RAISE NOTICE '>> Olist data load complete.';

END;
$$;


--Call The Stored Procedure
CALL load_olist_data();

--Read data from all the tables

SELECT * FROM product_category_name_translation LIMIT 10;

SELECT * FROM customers LIMIT 10;

SELECT * FROM sellers LIMIT 10;

SELECT * FROM products LIMIT 10;

SELECT * FROM geolocation LIMIT 10;

SELECT * FROM orders LIMIT 10;

SELECT * FROM order_items LIMIT 10;

SELECT * FROM order_payments LIMIT 10;

SELECT * FROM order_reviews LIMIT 10;






