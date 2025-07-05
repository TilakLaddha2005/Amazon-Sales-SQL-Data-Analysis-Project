-- Analysis Report
-------------------------------------------------------

-- Top 5 Selling Product

SELECT 
p.product_id,
p.product_name AS name,
COUNT(oi.order_id) AS total_orders,
SUM(oi.total_sale) AS total_revenue
FROM products p
JOIN order_items oi
JOIN orders o
ON o.order_id = oi.order_id
ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY
p.product_id,
p.product_name
ORDER BY
SUM(oi.total_sale) DESC LIMIT 5;

-------------------------------------------------------

-- Revenue by Category

SELECT
c.category_name,
SUM(oi.total_sale) AS total_revenue
FROM categories c
JOIN products p ON p.category_id = c.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY
c.category_name
ORDER BY
SUM(oi.total_sale) DESC ;

-------------------------------------------------------

-- Top 5 customer with highedt Average Order Value (AOV)

WITH total_rev_order AS(
	SELECT 
	oi.order_id,
	c.customer_id,
	c.customer_name,
	SUM(oi.total_sale) AS total_revenue_per_orders
	FROM customers c
	JOIN orders o
	ON o.customer_id = c.customer_id
	JOIN order_items oi
	ON oi.order_id = o.order_id
	WHERE o.status = 'Delivered'
	GROUP BY
	oi.order_id,
	c.customer_id,
	c.customer_name)

SELECT 
tro.customer_id,
tro.customer_name,
COUNT(*) AS total_orders_per_cus,
SUM(tro.total_revenue_per_orders) AS total_revenue_per_cus,
SUM(tro.total_revenue_per_orders) / COUNT(*) AS AOV
FROM total_rev_order tro
GROUP BY
tro.customer_id,
tro.customer_name
ORDER BY
AOV DESC LIMIT 5;

-------------------------------------------------------

-- Monthly Sales Trends

SELECT 
TO_CHAR(o.order_date , 'YYYY-MONTH') AS Months,
SUM(oi.total_sale)
FROM orders o
JOIN order_items oi
ON oi.order_id = o.order_id
GROUP BY
Months
ORDER BY
Months;

-------------------------------------------------------

-- Total Customers with No Purchases

SELECT
COUNT(*) 
FROM customers c
LEFT JOIN orders o
ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-------------------------------------------------------

-- Best Selling Categories by State

-- by revenue 

SELECT 
cus.state,
c.category_name,
SUM(oi.total_sale) AS total_revenue
FROM customers cus
JOIN orders o ON o.customer_id = cus.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY cus.state,c.category_name
ORDER BY cus.state, SUM(oi.total_sale) DESC;

-- by quantity

SELECT c.state, cat.category_name, SUM(oi.quantity) AS quantity_sold
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
GROUP BY c.state, cat.category_name
ORDER BY c.state, quantity_sold DESC;
-------------------------------------------------------

-- Most Returned Products

SELECT p.product_name,
COUNT(o.order_id) as total_orders_ret
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'Returned'
GROUP BY p.product_name
ORDER BY total_orders_ret DESC;

-------------------------------------------------------
