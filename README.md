Olist E-Commerce Analytics | SQL Data Analysis Project
📌 About This Project

This project is an end-to-end SQL data analysis project based on the Brazilian e-commerce platform Olist.

The goal was not just to write SQL queries, but to work through a complete analytics workflow—from loading raw CSV files into SQL Server and checking data quality to answering business questions using advanced SQL techniques.

Throughout the project, I used Microsoft SQL Server Management Studio (SSMS) and T-SQL to analyze sales, customers, products, sellers, payments, deliveries, and customer retention.

The project also includes advanced analysis using CTEs, Window Functions, RFM Segmentation, Customer Retention Analysis, and Cohort Analysis.

🎯 Business Questions Explored

Some of the main questions I tried to answer were:

How is the business performing in terms of sales and orders?
Which product categories generate the most revenue?
Which sellers contribute the most to the marketplace?
Are customers coming back to make repeat purchases?
Which payment methods do customers prefer?
How does delivery performance affect customer satisfaction?
How well are customers retained over time?
🛠️ Tools Used
Microsoft SQL Server
SQL Server Management Studio (SSMS)
T-SQL
Git & GitHub
📂 Dataset

This project uses the Brazilian E-Commerce Public Dataset by Olist, which contains information about approximately 100,000 orders placed between 2016 and 2018.

The dataset includes information about customers, orders, products, sellers, payments, reviews, and delivery details.

Dataset Tables
Table	Description
Customers	Customer identification and location information
Orders	Order status and order lifecycle timestamps
Order Items	Product, seller, price, and freight information
Order Payments	Payment type, installments, and payment value
Order Reviews	Customer review scores and feedback
Products	Product characteristics and categories
Sellers	Seller location information
Geolocation	Brazilian geographic location data
Category Translation	Portuguese to English product category mapping
🗂️ Project Structure
Olist-Ecommerce-Analytics/
│
├── README.md
├── assets/
├── data/
│   ├── raw/
│   └── processed/
│
├── docs/
├── power-bi/
├── python/
│
└── sql/
    ├── 01_database/
    ├── 02_data_loading/
    ├── 03_data_quality/
    ├── 04_business_analysis/
    ├── 05_advanced_analytics/
    └── 06_views/

The project is organized in the same order as the actual analytics workflow—from database creation to final business insights.

🏗️ Project Workflow
Raw CSV Files
      ↓
SQL Server Database
      ↓
Data Loading
      ↓
Data Quality Checks
      ↓
Business Analysis
      ↓
Advanced SQL Analytics
      ↓
Business Insights
🔍 Data Quality Checks

Before starting the analysis, I performed several checks to better understand the quality and structure of the data.

The validation process included:

Row count verification
Duplicate record checks
NULL value analysis
Primary and foreign key relationship checks
Validation Summary

The core tables were successfully loaded into SQL Server. No duplicate records were found based on the expected unique identifiers, and the relationship checks did not identify any broken relationships.

This step was important because analytical results are only meaningful when the underlying data is properly understood and validated.

📊 Analysis Performed
1. Sales Analysis

The sales analysis focused on understanding overall business performance.

I analyzed:

Total revenue
Freight revenue
Monthly sales trends
Order performance
Revenue growth patterns
Key Result

The delivered orders generated approximately R$15.42M in total value, with an average order value of approximately R$159.83.

2. Customer Analysis

This analysis focused on customer purchasing behavior and repeat purchases.

I explored:

Customer distribution
One-time vs repeat customers
Customer purchasing patterns
Customer segmentation
Key Insight

Approximately 97% of customers made only one purchase. This indicates that improving customer retention and encouraging repeat purchases could be a major opportunity for the business.

3. Product & Category Analysis

For product analysis, I looked at:

Top-performing product categories
Revenue by category
Product demand
Customer satisfaction across categories
Top Categories by Revenue

Some of the highest-performing categories were:

Health & Beauty
Watches & Gifts
Bed, Bath & Table
Sports & Leisure
Computers & Accessories

These categories represent important areas for inventory planning, marketing, and business growth.

4. Seller Analysis

The seller analysis focused on understanding the contribution of individual sellers to the marketplace.

The analysis included:

Seller sales performance
Revenue contribution
Order volume

This can help identify high-performing sellers and highlight areas where seller performance can be improved.

5. Payment Analysis

I analyzed customer payment preferences and installment behavior.

The analysis included:

Payment methods
Payment value
Number of installments
Average payment value
Key Insight

Credit cards accounted for approximately 78% of total payment value, making them the most important payment method in the dataset.

6. Delivery & Customer Satisfaction Analysis

Delivery performance is an important part of the customer experience, so I compared delivery timing with customer review scores.

The analysis included:

On-time vs late deliveries
Delivery performance
Customer review scores
Key Insight

Late deliveries had an average review score of approximately 2.57, compared with 4.29 for on-time deliveries.

This shows a clear relationship between delivery performance and customer satisfaction. Improving logistics and reducing late deliveries could have a direct positive impact on customer experience.

🚀 Advanced SQL Analytics
CTEs (Common Table Expressions)

CTEs were used to break complex queries into smaller and more readable steps. They were particularly useful when performing multi-stage analysis.

Window Functions

Window functions were used for analytical calculations such as:

Ranking
Running totals
Comparing current and previous months using LAG()
Performing calculations while keeping row-level detail
Monthly Growth Analysis

Month-over-month revenue growth was analyzed to identify periods of business growth and decline.

This helped show how sales performance changed over time instead of looking only at overall totals.

RFM Customer Segmentation

Customers were analyzed using the RFM framework:

Recency – How recently a customer made a purchase
Frequency – How often a customer purchased
Monetary Value – How much a customer spent

This type of segmentation can help businesses identify different customer groups and develop more targeted retention strategies.

Customer Retention Analysis

Customer activity was analyzed to understand the difference between:

One-time customers
Repeat customers
Active customers
Inactive customers

The results showed that repeat purchasing was relatively low, reinforcing the importance of customer retention strategies.

Cohort Analysis

Customers were grouped according to their first purchase month, and their activity was tracked over subsequent months.

The cohort analysis showed how customer retention changes over time and provides a better understanding of long-term customer behavior.

💡 Key Business Insights

After completing the analysis, these were some of the most important findings:

👥 Customer Retention Is a Major Opportunity

Only around 3% of customers made repeat purchases. This suggests that the business has a strong opportunity to improve customer retention through loyalty programs, personalized offers, and post-purchase engagement.

🚚 Delivery Performance Strongly Affects Customer Satisfaction

Customers who received their orders late gave significantly lower review scores than customers who received orders on time.

Improving delivery performance could therefore improve both customer satisfaction and the overall marketplace experience.

📦 Revenue Is Concentrated in Key Categories

Categories such as Health & Beauty, Watches & Gifts, and Bed, Bath & Table were among the strongest contributors to revenue.

These categories may deserve additional attention in marketing and inventory planning.

💳 Credit Cards Are the Preferred Payment Method

Credit cards accounted for approximately 78% of payment value, making the credit card experience particularly important for customers.

📍 São Paulo Is the Largest Market

São Paulo (SP) generated the highest revenue and order volume among the states in the dataset.

This makes SP an important market while also highlighting the potential to identify growth opportunities in other regions.

📈 Business Recommendations

Based on the analysis, the following actions could be considered:

Improve Customer Retention

Introduce loyalty programs, personalized recommendations, and post-purchase engagement to encourage customers to return.

Improve Delivery Performance

Monitor late deliveries and identify sellers or logistics partners with poor delivery performance. More accurate delivery estimates could also help manage customer expectations.

Focus on High-Performing Categories

Prioritize inventory availability and marketing efforts for categories that consistently generate strong revenue.

Leverage Customer Payment Preferences

Continue optimizing the credit card payment experience while exploring ways to improve adoption and convenience of other payment methods.

Strengthen Regional Strategy

Maintain focus on strong markets such as São Paulo while identifying regions with potential for future growth.

▶️ How to Run This Project
1. Download the Dataset

Download the Olist dataset and place the CSV files inside:

data/raw/
2. Open SQL Server Management Studio

Open Microsoft SQL Server Management Studio (SSMS) and connect to your SQL Server instance.

3. Run the SQL Files

Execute the scripts in the following order:

1. sql/01_database/
2. sql/02_data_loading/
3. sql/03_data_quality/
4. sql/04_business_analysis/
5. sql/05_advanced_analytics/
6. sql/06_views/

Note: Update the file paths in the bulk insert script according to the location of the CSV files on your local machine.

🧠 Skills Demonstrated

Through this project, I practiced and applied:

SQL Database Design
Data Import and Loading
Data Quality Validation
Joins and Aggregations
CTEs
Window Functions
Views
Customer Segmentation
RFM Analysis
Customer Retention Analysis
Cohort Analysis
Business Analysis
Data-Driven Recommendations
👤 Author

Subhadeep Panda

Aspiring Data Analyst | SQL | Python | Power BI

GitHub: Subhadeep-dataScience

🎯 Final Note

This project was built as part of my journey toward becoming a Data Analyst. My focus was to go beyond basic SQL queries and understand how SQL can be used to solve real business problems—from validating raw data to finding insights that can support business decisions.