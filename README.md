# Amazon Sales SQL Data Analysis Project

## Project Overview
This project showcases advanced SQL data analysis on a mock Amazon-style sales dataset consisting of 9 interrelated tables. The dataset mimics real-world eCommerce data involving products, customers, sellers, orders, shipping, payments, and inventory. 

## Dataset Structure (9 CSVs)
| Table Name     | Description                                      | Rows     |
|----------------|--------------------------------------------------|----------|
| categories     | Product categories (e.g., Electronics, Books)     | 8        |
| products       | 800+ product SKUs with category and price         | 800      |
| sellers        | Seller businesses and their Indian state          | 200      |
| customers      | Customers with Indian states and cities           | 1000     |
| orders         | Orders made by customers                         | 21,000   |
| order_items    | Products sold in each order                      | ~42,000  |
| shipping       | Shipping provider and delivery info               | 21,000   |
| payments       | Payment method and transaction status             | 21,000   |
| inventory      | Available product stock levels                    | 800      |


![ERD diagram](/ERD%20diagram.png)

## SQL Challenges Solved
This project answers 25+ business-critical questions using advanced SQL. Topics include:

### Sales Performance
- Top selling product
- Monthly sales trends
- Revenue by category/state/shipping provider
- Most returned products
- Top products with decreasing revenue ratio
- Daily Revenue Volatility
- Payment Method Popularity
- Time to Deliver vs Revenue Impact
- Order Fulfillment Rate (OFR)

### Customer Analytics
- Average order value
- Customer Churn / Active Rate
- Customers with no purchases
- Top 5 customers by state
- Customers Segmentation
- RFM segmentation
- Repeat Purchase Rate

### Shipping and Inventory
- Inventory stock alerts
- Shipping delays
- Inventory turnover ratio

### Finance Insights
- Revenue loss due to returns/cancellations
- Profit margin by product and seller
- Cash flow trends
- Gross Profit by Month Analysis
- Return rate by category

### Seller Insights
- Top performing sellers
- Inactive sellers in last 60 days
- Cross-sell opportunities

### Sales Performance
- Top selling product

```sql
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
```
- Monthly sales trends

```sql
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
```

- Revenue by category/state/shipping provider
```sql
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
```

```sql
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
```
- Most returned products
```sql
-- Most Returned Products

SELECT p.product_name,
COUNT(o.order_id) as total_orders_ret
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'Returned'
GROUP BY p.product_name
ORDER BY total_orders_ret DESC;
```
- Top products with decreasing revenue ratio
```sql
-- Top Products with Decreasing Revenue Ratio
WITH mon_rev AS(
	SELECT p.product_id, p.product_name,
	TO_CHAR(o.order_date , 'YYYY-MM') AS months,
	SUM(oi.total_sale) AS montly_revenue
	FROM products p
	JOIN order_items oi ON oi.product_id = p.product_id
	JOIN orders o ON o.order_id = oi.order_id
	WHERE o.status = 'Delivered'
	GROUP BY p.product_id, p.product_name , months),
	
mon_trends AS(
	SELECT mr.product_id, mr.product_name,
	MAX(mr.montly_revenue) AS max_mon_rev,
	MIN(mr.montly_revenue) AS min_mon_rev
	FROM mon_rev mr
	GROUP BY mr.product_id, mr.product_name)

SELECT mt.product_id, mt.product_name,
mt.max_mon_rev, mt.min_mon_rev,
CASE WHEN mt.max_mon_rev = 0 THEN 0 
     ELSE mt.min_mon_rev / mt.max_mon_rev
	 END AS revenue_ratio
FROM mon_trends mt
WHERE mt.max_mon_rev > 0 
ORDER BY revenue_ratio ASC ;
```
**- Daily Revenue Volatility**
```sql
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
```

- Payment Method Popularity
```sql
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
```
**- Time to Deliver vs Revenue Impact**
```sql
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
```
**- Order Fulfillment Rate (OFR)**
```sql
-- Order Fulfillment Rate (OFR)

SELECT 
COUNT(*) AS total_orders,
COUNT(*) FILTER (WHERE o.status = 'Delivered') AS orders_fullfilled,
COUNT(*) FILTER (WHERE o.status IN ('Delivered','Shipped','Pending')) AS total_fulfillable_orders,
COUNT(*) FILTER (WHERE o.status = 'Delivered') * 100 / 
COUNT(*) FILTER (WHERE o.status IN ('Delivered','Shipped','Pending')) AS fullfillment_pct
FROM orders o;
```
### Customer Analytics
**- Average order value**

```sql
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
```
**- Customer Churn / Active Rate**
```sql
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
```
- Customers with no purchases
```sql
-- Total Customers with No Purchases

SELECT
COUNT(*) 
FROM customers c
LEFT JOIN orders o
ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;
```
- Top 5 customers by state
```sql
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
```
**- Customers Segmentation**
```sql
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
```
**- RFM segmentation**
```sql
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
```
**- Repeat Purchase Rate**
```sql
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
```

### Shipping and Inventory
- Inventory stock alerts
```sql

-- Inventory Stock urgency report (products where stock < 10)

SELECT inv.product_id, p.product_name, inv.stock_quantity,
DENSE_RANK() OVER(ORDER BY inv.stock_quantity ASC) AS urgency_rank
FROM inventory inv
JOIN products p
ON p.product_id = inv.product_id
WHERE inv.stock_quantity < 10;
```
- Shipping delays

```sql
-- Delivery Delays days ranked (delivered_date > expected_date)

SELECT o.customer_id , cus.customer_name ,  o.order_id, 
sp.expected_delivery_date , sp.delivered_date,
(sp.delivered_date - sp.expected_delivery_date) AS delay_days,
DENSE_RANK() OVER(ORDER BY (sp.delivered_date - sp.expected_delivery_date) DESC) AS delay_rank
FROM shipping sp 
JOIN orders o ON o.order_id = sp.order_id
JOIN customers cus ON cus.customer_id = o.customer_id
WHERE sp.delivered_date > sp.expected_delivery_date;
```
- Inventory turnover ratio
```sql
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
```

### Finance Insights

- Revenue loss due to returns/cancellations

```sql
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

```
- Profit margin by product and seller
```sql

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
```
- Cash flow trends

```sql
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
```
**- Gross Profit by Month Analysis**
```sql
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
```
-Return Rate by Category
```sql
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
```

### Seller Insights
- Top performing sellers
```sql
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
```
- Inactive sellers in last 60 days
```sql
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
```

**- Cross-sell opportunities**
```sql
-- Cross-Sell Opportunities

SELECT
p1.product_id AS main_product_id,
p1.product_name AS main_product,
p2.product_id AS cross_product_id,
p2.product_name AS cross_product,
COUNT(*) AS times_broght_together
FROM order_items oi1
JOIN order_items oi2 ON oi2.order_id = oi1.order_id AND oi2.product_id <> oi1.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY main_product_id, main_product,
cross_product_id, cross_product
HAVING COUNT(*) >=3
ORDER BY times_broght_together DESC;
```

## Tools Used
- PostgreSQL – Data modeling and querying


## Author and Contact
Tilak Laddha  
Email: tilakladdhaofficial2005@gmail.com  


