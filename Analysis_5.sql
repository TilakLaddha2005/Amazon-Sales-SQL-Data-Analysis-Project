-------------------------------------------------------

-- Daily Revenue Volatility

WITH rev_day AS (
	SELECT 
	o.order_date::DATE AS date,
	SUM(oi.total_sale) AS revenue_per_day
	FROM orders o
	JOIN order_items oi ON oi.order_id = o.order_id
	WHERE o.status = 'Delivered'
	GROUP BY o.order_date::DATE)

SELECT 
AVG(rd.revenue_per_day) AS avg_day_revenue,
STDDEV(rd.revenue_per_day) AS daily_volatility,
MAX(rd.revenue_per_day) AS max_day_revenue,
MIN(rd.revenue_per_day) AS min_day_revenue
FROM rev_day rd;

-------------------------------------------------------

-- Inventory Turnover Ratio

WITH pro_data AS (
	SELECT 
	p.product_id,
	p.product_name ,
	SUM(oi.quantity) AS product_sold
	FROM products p
	JOIN order_items oi ON p.product_id = oi.product_id
	JOIN orders o ON o.order_id = oi.order_id
	WHERE o.status = 'Delivered'
	GROUP BY p.product_id , p.product_name )

SELECT pd.*,
inv.stock_quantity AS quantity_avaiable,
ROUND(pd.product_sold::decimal / NULLIF(inv.stock_quantity,0),2) AS Inventory_Turnover_Ratio
FROM pro_data pd
JOIN inventory inv ON inv.product_id = pd.product_id
ORDER BY inventory_turnover_ratio DESC;

-------------------------------------------------------

-- Repeat Purchase Rate

WITH cus_ord AS (
	SELECT 
	o.customer_id,
	COUNT(DISTINCT order_id) AS total_orders
	FROM orders o
	WHERE o.status = 'Delivered'
	GROUP BY o.customer_id)

SELECT 
COUNT(co.customer_id) AS total_customer,
COUNT(*) FILTER (WHERE co.total_orders > 7) AS total_repeat_cus,
COUNT(*) FILTER (WHERE co.total_orders > 7) * 100 / COUNT(co.customer_id) AS repeat_cus_rate
FROM cus_ord co;

-------------------------------------------------------

-- RFM (Recency-Frequency-Monetary) Score

WITH rfm_base AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.item_price * oi.quantity) AS monetary_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name
),

rfm_scores AS (
    SELECT *,
        CURRENT_DATE - last_order_date AS recency_days,
        NTILE(5) OVER (ORDER BY CURRENT_DATE - last_order_date DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_value DESC) AS m_score
    FROM rfm_base
),

rfm_segmented AS (
    SELECT *,
        CONCAT(r_score, f_score, m_score) AS rfm_score,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Platinum'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Gold'
            WHEN r_score = 3 AND f_score = 2 AND m_score = 2 THEN 'Silver'
            WHEN r_score = 2 OR f_score = 2 OR m_score = 2 THEN 'Bronze'
            ELSE 'Churn Risk'
        END AS rfm_segment
    FROM rfm_scores
)

SELECT 
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary_value AS monetary_value,
    r_score, f_score, m_score,
    rfm_score,
    rfm_segment
FROM rfm_segmented
ORDER BY rfm_segment, rfm_score DESC;

-------------------------------------------------------

-- Cash Flow Trend Analysis

SELECT 
TO_CHAR(o.order_date,'YYYY-Month') AS month,
SUM(p.amount_paid) AS daily_cash_flow,
COUNT(o.order_id) AS total_daily_orders
FROM orders o
JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_status = 'Success' AND o.status = 'Delivered'
GROUP BY month
ORDER BY month;

-------------------------------------------------------

-- Payment Method Popularity

WITH total_rev_per_order AS(
	SELECT o.order_id, SUM(oi.total_sale) AS total_rev
	FROM order_items oi
	JOIN orders o ON o.order_id = oi.order_id
	WHERE o.status = 'Delivered'
	GROUP BY o.order_id)

SELECT py.payment_method, COUNT(py.order_id),SUM(trpo.total_rev) AS total_rev_
FROM payments py
JOIN  total_rev_per_order trpo ON py.order_id = trpo.order_id
GROUP BY py.payment_method
ORDER BY total_rev_ DESC;

-------------------------------------------------------





