-------------------------------------------------------

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

-------------------------------------------------------

--Top Shipping Provider

SELECT sh.shipping_id , sh.shipping_provider,
COUNT(o.order_id) AS total_orders,
SUM(oi.total_sale) AS total_revenue,
RANK() OVER(ORDER BY SUM(oi.total_sale) DESC) AS provider_ranked
FROM shipping sh
JOIN orders o ON o.order_id = sh.order_id
JOIN order_items oi ON oi.order_id = sh.order_id
WHERE o.status = 'Delivered'
GROUP BY sh.shipping_id , sh.shipping_provider
ORDER BY total_revenue DESC ;

-------------------------------------------------------

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

-------------------------------------------------------
