1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.
SELECT market 
FROM dim_customer
WHERE customer = "Atliq Exclusive"
AND region = "APAC"
GROUP BY market;

2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg

WITH unique_product_cte AS (
SELECT (SELECT COUNT(DISTINCT product_code)
		FROM fact_sales_monthly
		WHERE fiscal_year = "2020") unique_product_2020
	  ,(SELECT COUNT(DISTINCT product_code)
		FROM fact_sales_monthly
		WHERE fiscal_year = "2021") unique_product_2021
)
SELECT unique_product_2020
	  ,unique_product_2021
      , ROUND((unique_product_2021-unique_product_2020)*100/unique_product_2020,1) percentage_chg
FROM unique_product_cte





3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count

SELECT segment
	  ,COUNT(DISTINCT product_code) product_count
FROM dim_product
GROUP BY segment 
ORDER BY product_count DESC;

4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference

WITH product_count_2020_cte AS (
SELECT p.segment
	  ,COUNT(DISTINCT m.product_code) product_count_2020
FROM fact_sales_monthly m
LEFT JOIN dim_product p
ON m.product_code = p.product_code
WHERE m.fiscal_year = "2020"
GROUP BY segment 
),
product_count_2021_cte AS (
SELECT p.segment
	  ,COUNT(DISTINCT m.product_code) product_count_2021
FROM fact_sales_monthly m
LEFT JOIN dim_product p
ON m.product_code = p.product_code
WHERE m.fiscal_year = "2021"
GROUP BY segment 
)
SELECT c20.segment
	  ,c20.product_count_2020
	  ,c21.product_count_2021
      ,MAX(ABS(c21.product_count_2021-c20.product_count_2020)) difference
FROM product_count_2020_cte c20 
INNER JOIN product_count_2021_cte c21
ON c20.segment = c21.segment

5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost

SELECT m.product_code
	  ,p.product
      ,MAX(m.manufacturing_cost) manufacturing_cost
FROM dim_product p
INNER JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code
UNION ALL
SELECT m.product_code
	  ,p.product
      ,MIN(m.manufacturing_cost) manufacturing_cost
FROM dim_product p
INNER JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code



6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage

SELECT d.customer_code
	  ,c.customer
      ,AVG(d.pre_invoice_discount_pct) average_discount_percentage
FROM dim_customer c
INNER JOIN fact_pre_invoice_deductions d
ON c.customer_code = d.customer_code
WHERE d.fiscal_year = "2021"
AND c.market = "India"
GROUP BY d.customer_code, c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5

7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount

SELECT MONTHNAME(s.date) month
	  ,YEAR(s.date) year
      ,SUM(s.sold_quantity*p.gross_price) gross_sales_amount
FROM fact_sales_monthly s
LEFT JOIN fact_gross_price p
ON s.product_code = p.product_code
LEFT JOIN dim_customer c
ON s.customer_code = c.customer_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY month, year
ORDER BY  year, MONTH(date)


8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity

SELECT QUARTER(date) quarter
      ,SUM(sold_quantity) total_sold_quantity
FROM fact_sales_monthly 
WHERE fiscal_year = "2020"
GROUP BY quarter
ORDER BY  total_sold_quantity DESC
LIMIT 1


9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage


WITH sales_cte AS(
SELECT c.channel channel
	  ,SUM(s.sold_quantity*p.gross_price)  gross_sales_mln
      ,RANK() OVER(ORDER BY SUM(s.sold_quantity*p.gross_price) DESC) rnk
FROM fact_sales_monthly s
LEFT JOIN fact_gross_price p
ON s.product_code = p.product_code
LEFT JOIN dim_customer c
ON s.customer_code = c.customer_code
WHERE s.fiscal_year = "2021"
GROUP BY c.channel
) 
SELECT channel
	  ,gross_sales_mln
      ,ROUND(gross_sales_mln*100/(SELECT SUM(gross_sales_mln) FROM sales_cte),1) percentage
FROM sales_cte
WHERE rnk = 1
GROUP BY gross_sales_mln

10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order

WITH rank_cte AS (
SELECT p.division
      ,p.product_code
      ,p.product
      ,SUM(s.sold_quantity) total_sold_quantity
      ,ROW_NUMBER() OVER (PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) rank_order
FROM fact_sales_monthly s
LEFT JOIN dim_product p
ON s.product_code = p.product_code
WHERE s.fiscal_year = "2021"
GROUP BY p.division, p.product_code, p.product
)
SELECT division
	  ,product_code
      ,product
      ,total_sold_quantity
      ,rank_order
FROM rank_cte
WHERE rank_order <= 3;




SELECT * FROM dim_customer;
SELECT * FROM dim_product;
SELECT * FROM fact_gross_price;
SELECT * FROM fact_manufacturing_cost;
SELECT * FROM fact_pre_invoice_deductions;
SELECT * FROM fact_sales_monthly;


