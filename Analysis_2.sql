-------------------------------------------------------

-- Inventory Stock urgency report (products where stock < 10)

SELECT inv.product_id, p.product_name, inv.stock_quantity,
DENSE_RANK() OVER(ORDER BY inv.stock_quantity ASC) AS urgency_rank
FROM inventory inv
JOIN products p
ON p.product_id = inv.product_id
WHERE inv.stock_quantity < 10;

-------------------------------------------------------

-- Delivery Delays days ranked (delivered_date > expected_date)

SELECT o.customer_id , cus.customer_name ,  o.order_id, 
sp.expected_delivery_date , sp.delivered_date,
(sp.delivered_date - sp.expected_delivery_date) AS delay_days,
DENSE_RANK() OVER(ORDER BY (sp.delivered_date - sp.expected_delivery_date) DESC) AS delay_rank
FROM shipping sp 
JOIN orders o ON o.order_id = sp.order_id
JOIN customers cus ON cus.customer_id = o.customer_id
WHERE sp.delivered_date > sp.expected_delivery_date;

-------------------------------------------------------

-- Top 5 Performing Sellers

SELECT oi.seller_id, s.seller_name, 
COUNT(o.order_id) AS total_orders , SUM(oi.total_sale) AS total_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN sellers s ON s.seller_id = oi.seller_id
WHERE o.status = 'Delivered'
GROUP BY oi.seller_id , s.seller_name
ORDER BY 
total_revenue DESC LIMIT 5;

-------------------------------------------------------

-- Product Margin Rate & profit/loss rate

SELECT p.product_id, p.product_name AS name, 
p.price,p.cost,
(p.price - p.cost ) AS margin_per_unit,
(p.price - p.cost ) / NULLIF(p.price, 0) * 100 AS product_margin_rate,
SUM(oi.quantity) AS total_quantity,
SUM((p.price - p.cost ) * oi.quantity) AS P_L,
SUM((p.price - p.cost ) * oi.quantity) / SUM(oi.total_sale) AS P_L_rate,
DENSE_RANK() OVER(ORDER BY ((p.price - p.cost ) /  NULLIF(p.price, 0)) DESC) AS margin_ranked
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY product_margin_rate DESC; 

-------------------------------------------------------

-- Top 5 Customers by Orders in Each State

WITH S_C_O AS(
	SELECT cus.state, cus.customer_id, cus.customer_name, 
	COUNT(o.order_id) AS total_orders,
	DENSE_RANK() OVER(PARTITION BY cus.state ORDER BY COUNT(o.order_id) DESC ) AS ranked_cus
	FROM customers cus
	JOIN orders o ON o.customer_id = cus.customer_id
	GROUP BY cus.state, cus.customer_id, cus.customer_name
	ORDER BY cus.state , total_orders DESC)
	
SELECT *
FROM S_C_O
WHERE ranked_cus <= 5;

-------------------------------------------------------

-- Inactive Sellers (No sales in last 60 days)

WITH S_last_order AS(
	SELECT oi.seller_id, MAX(o.order_date) AS last_order
	FROM order_items oi
	JOIN orders o ON oi.order_id = o.order_id
	GROUP BY oi.seller_id)

SELECT s.seller_id, s.seller_name , s.state, slo.last_order
FROM sellers s
LEFT JOIN S_last_order slo ON s.seller_id = slo.seller_id
WHERE slo.last_order IS NULL OR slo.last_order < CURRENT_DATE - INTERVAL '60 days';

-------------------------------------------------------

-- Customer Segmentation

WITH cus_pro AS(
	SELECT cus.customer_id, cus.customer_name,
	SUM(oi.total_sale) AS total_revenue,
	COUNT(DISTINCT o.order_id) AS total_orders,
	MAX(o.order_date::date) AS last_order
	FROM customers cus
	JOIN orders o ON o.customer_id = cus.customer_id
	JOIN order_items oi ON oi.order_id = o.order_id
	WHERE o.status = 'Delivered'
	GROUP BY cus.customer_id, cus.customer_name)

SELECT *,
 CURRENT_DATE - cus_pro.last_order AS days_since_lo,
 CASE WHEN cus_pro.total_revenue > 7000 THEN 'GOLD'
     WHEN cus_pro.total_revenue > 5000 THEN 'SILVER'
	 WHEN cus_pro.total_revenue > 3000 THEN 'BRONZE'
     ELSE 'NORMAL' END AS revenue_segment,

 CASE WHEN cus_pro.total_orders > 20 THEN 'high frequency'
      WHEN cus_pro.total_orders > 10 THEN 'medium frequency'
	  ELSE 'low frequency' END AS frequency_segment
FROM cus_pro;

-------------------------------------------------------