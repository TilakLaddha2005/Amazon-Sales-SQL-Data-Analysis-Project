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

---
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

## Tools Used
- PostgreSQL – Data modeling and querying


## Author and Contact
Tilak Laddha  
Email: tilakladdhaofficial2005@gmail.com  


