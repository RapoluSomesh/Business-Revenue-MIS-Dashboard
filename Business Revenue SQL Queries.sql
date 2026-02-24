#creating database
create database generating_dataset;
USE generating_dataset;

#Create Tables
CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(50),
    region VARCHAR(20),
    signup_date DATE
);

CREATE TABLE orders (
    order_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    order_date DATE,
    product_category VARCHAR(50),
    sales DECIMAL(10,2),
    quantity INT
);

CREATE TABLE product_cost (
    product_category VARCHAR(50),
    cost_price DECIMAL(10,2)
);

SET SESSION cte_max_recursion_depth = 2000;
#Generate 200 Customers
INSERT INTO customers (customer_id, customer_name, region, signup_date)
SELECT 
    CONCAT('C', LPAD(id,3,'0')),
    CONCAT('Customer_',id),
    ELT(FLOOR(1 + RAND()*4),'South','North','East','West'),
    DATE_ADD('2023-01-01', INTERVAL FLOOR(RAND()*365) DAY)
FROM (
    WITH RECURSIVE cust_gen AS (
        SELECT 1 AS id
        UNION ALL
        SELECT id + 1 FROM cust_gen WHERE id < 200
    )
    SELECT id FROM cust_gen
) AS temp;

#Generate 1000 Orders
INSERT INTO orders (order_id, customer_id, order_date, product_category, sales, quantity)
SELECT 
    CONCAT('O', LPAD(id,4,'0')),
    CONCAT('C', LPAD(FLOOR(1 + RAND()*200),3,'0')),
    DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND()*365) DAY),
    ELT(FLOOR(1 + RAND()*4),'Electronics','Furniture','Clothing','Grocery'),
    ROUND(500 + RAND()*50000,2),
    FLOOR(1 + RAND()*5)
FROM (
    WITH RECURSIVE order_gen AS (
        SELECT 1 AS id
        UNION ALL
        SELECT id + 1 FROM order_gen WHERE id < 1000
    )
    SELECT id FROM order_gen
) AS temp;

INSERT INTO product_cost VALUES
('Electronics', 30000),
('Furniture', 12000),
('Clothing', 2000),
('Grocery', 500);

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;

# 1. Total Revenue

select 
sum(sales) as Total_Revenue 
from orders;

#2. Total Unique Customers

select 
count(distinct customer_id) as Total_Customers 
from customers;

#3. Total Orders

SELECT 
COUNT(DISTINCT order_id) AS total_orders
FROM orders;

#4. Total Profit

SELECT 
SUM(o.sales - pc.cost_price) AS total_profit
FROM orders o
JOIN product_cost pc
ON o.product_category = pc.product_category;

#5. Profit Margin %

SELECT 
(SUM(o.sales - pc.cost_price)/SUM(o.sales))*100 AS profit_margin
FROM orders o
JOIN product_cost pc
ON o.product_category = pc.product_category;

#6. Repeat Customers

SELECT 
COUNT(customer_id) AS repeat_customers
FROM (
SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) > 1
) AS repeat_data;

#7. Monthly Revenue Trend

SELECT 
DATE_FORMAT(order_date,'%Y-%m') AS month,
SUM(sales) AS monthly_revenue
FROM orders
GROUP BY month
ORDER BY month;

#8. Region-wise Revenue

SELECT 
c.region,
SUM(o.sales) AS revenue
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.region;

#9. Top 10 Customers (CLV)

SELECT 
customer_id,
SUM(sales) AS lifetime_value
FROM orders
GROUP BY customer_id
ORDER BY lifetime_value DESC
LIMIT 10;

# create view

CREATE VIEW dashboard_data AS
SELECT 
o.order_id,
o.customer_id,
c.region,
o.order_date,
DATE_FORMAT(o.order_date,'%Y-%m') AS order_month,
o.product_category,
o.sales,
pc.cost_price,
(o.sales - pc.cost_price) AS profit,
((o.sales - pc.cost_price)/o.sales)*100 AS profit_margin
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
JOIN product_cost pc
ON o.product_category = pc.product_category;
