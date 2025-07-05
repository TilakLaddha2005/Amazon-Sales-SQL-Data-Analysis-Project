-------------------------------------------------------

--  Gross Profit by Month Analysis

WITH month_data AS(
	SELECT TO_CHAR(o.order_date , 'YYYY-Month') AS months,
	SUM(oi.total_sale) AS total_revenue ,
	COUNT(o.order_id) AS total_orders ,
	SUM((pr.price - pr.cost ) * oi.quantity) AS gross_profit
	FROM order_items oi
	JOIN orders o ON o.order_id = oi.order_id
	JOIN products pr ON pr.product_id = oi.product_id
	WHERE o.status = 'Delivered'
	GROUP BY months ),

profit_data AS(
	SELECT *,
	md.gross_profit / NULLIF(md.total_revenue,0) * 100 AS profit_margin_rate,
	LAG(md.gross_profit) OVER(ORDER BY months) AS prev_month_profit
	FROM month_data md)

SELECT *,
CASE WHEN prev_month_profit IS NULL THEN 0
ELSE (pd.gross_profit - pd.prev_month_profit ) * 100 / NULLIF(prev_month_profit, 0) END AS profit_change_rate
FROM profit_data pd
ORDER BY months;

-------------------------------------------------------

-- Return Rate by Category

WITH total_orders_count AS(
	SELECT c.category_id, c.category_name,
	COUNT(o.order_id) AS total_orders,
	COUNT(CASE WHEN o.status = 'Returned' THEN o.order_id END) AS total_retured
	FROM categories c
	JOIN products p ON p.category_id = c.category_id
	JOIN order_items oi ON oi.product_id = p.product_id
	JOIN orders o ON o.order_id = oi.order_id
	GROUP BY  c.category_id, c.category_name)

SELECT *,
((toc.total_retured * 100) / NULLIF(toc.total_orders, 0)) AS return_rate ,
DENSE_RANK() OVER(ORDER BY ((toc.total_retured * 100) / NULLIF(toc.total_orders, 0)) DESC) AS return_rate_ranked
FROM total_orders_count toc
ORDER BY return_rate DESC;

-------------------------------------------------------

-- Customer Churn / Active Rate

WITH cus_lo AS(
	SELECT cus.customer_id , cus.customer_name,
	MAX(o.order_date) AS last_order_date
	FROM customers cus
	JOIN orders o ON o.customer_id = cus.customer_id
	JOIN order_items oi ON oi.order_id = o.order_id
	WHERE o.status = 'Delivered'
	GROUP BY cus.customer_id , cus.customer_name),
	
	a_c_data AS(
	SELECT clo.*,
	CURRENT_DATE - clo.last_order_date AS days_since_last_orders,
	CASE WHEN CURRENT_DATE - clo.last_order_date > 90 THEN 'churned'
	ELSE 'active' END AS status
	FROM cus_lo clo)

SELECT 
COUNT(*) AS total_customers,
COUNT(*) FILTER (WHERE a_c_data.status = 'churned') AS churned_cus,
COUNT(*) FILTER (WHERE a_c_data.status = 'active') AS active_cus,
COUNT(*) FILTER (WHERE a_c_data.status = 'churned')  * 100/ COUNT(*) AS churned_rate
FROM a_c_data;

-------------------------------------------------------

-- Revenue Loss due to Cancellations

WITH rev_data AS (
	SELECT 
	o.order_id,
	o.status,
	SUM(oi.total_sale) AS revenue
	FROM orders o
	JOIN order_items oi ON oi.order_id = o.order_id
	GROUP BY o.order_id)

SELECT 
COUNT(*) AS total_orders,
COUNT(*) FILTER (WHERE rd.status = 'Cancelled') AS order_cancelled,
COUNT(*) / COUNT(*) FILTER (WHERE rd.status = 'Cancelled') AS cancellation_rate,
SUM(rd.revenue) AS total_revenue,
SUM(rd.revenue) FILTER (WHERE rd.status = 'Cancelled' ) AS revenue_lost,
SUM(rd.revenue) FILTER (WHERE rd.status = 'Cancelled' ) * 100 / SUM(rd.revenue) AS revenue_lost_pct
FROM rev_data rd;

-------------------------------------------------------

-- Time to Deliver vs Revenue Impact

WITH del_data AS(
	SELECT 
	o.order_id,
	o.order_date AS ord_date,
	sh.delivered_date AS del_date,
	sh.expected_delivery_date AS exp_del_date,
	sh.delivered_date - o.order_date AS actual_del_days,
	sh.expected_delivery_date - o.order_date AS expected_days,
	sh.delivered_date - sh.expected_delivery_date  AS delay_days,
	SUM(oi.total_sale) AS revenue
	FROM shipping sh
	JOIN orders o ON o.order_id = sh.order_id
	JOIN order_items oi ON oi.order_id = o.order_id
	WHERE o.status = 'Delivered'
	GROUP BY o.order_id , ord_date , del_date , exp_del_date)

SELECT 
COUNT(*) AS total_orders,
AVG(dd.actual_del_days) AS avg_del_days,
AVG(dd.delay_days) AS avg_delay_days,
SUM(dd.revenue) AS total_revenue,
SUM(dd.revenue) FILTER (WHERE dd.delay_days > 2) AS delay_del_rev,
SUM(dd.revenue) FILTER (WHERE dd.delay_days > 2) * 100 / SUM(dd.revenue) AS delay_del_rev_pct
FROM del_data dd;

-------------------------------------------------------

-- Order Fulfillment Rate (OFR)

SELECT 
COUNT(*) AS total_orders,
COUNT(*) FILTER (WHERE o.status = 'Delivered') AS orders_fullfilled,
COUNT(*) FILTER (WHERE o.status IN ('Delivered','Shipped','Pending')) AS total_fulfillable_orders,
COUNT(*) FILTER (WHERE o.status = 'Delivered') * 100 / 
COUNT(*) FILTER (WHERE o.status IN ('Delivered','Shipped','Pending')) AS fullfillment_pct
FROM orders o;

-------------------------------------------------------
