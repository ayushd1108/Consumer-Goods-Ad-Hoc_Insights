#Resume Project Challenge
#Provide Insights to Management in Consumer Goods Domain

#Task1

SELEct
       distinct(market) 
FROM dim_customer
WHERE customer="Atliq Exclusive" AND 
	  region="APAC";
      
#Task2

WITH unique_products_2020 AS 
               (SELECT COUNT(DISTINCT(product_code)) AS unique_products_2020
                FROM fact_gross_price
				WHERE fiscal_year=2020),
     unique_products_2021 AS 
			   (SELECT COUNT(DISTINCT(product_code)) AS unique_products_2021
                FROM fact_gross_price
                WHERE fiscal_year=2021)
SELECT *,
       ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) AS pct_increase
FROM unique_products_2020
CROSS JOIN unique_products_2021;

#Task3

SELECT segment,
       COUNT(DISTINCT(product_code)) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

#Task4

WITH products_2020 AS (
    SELECT p.segment,
           COUNT(DISTINCT g.product_code) AS product_count_20
    FROM dim_product p
    JOIN fact_gross_price g ON p.product_code = g.product_code
    WHERE g.fiscal_year = 2020
    GROUP BY p.segment
),
products_2021 AS (
    SELECT a.segment,
           COUNT(DISTINCT b.product_code) AS product_count_21
    FROM dim_product a
    JOIN fact_gross_price b ON a.product_code = b.product_code
    WHERE b.fiscal_year = 2021
    GROUP BY a.segment
)
SELECT c.segment,
       c.product_count_20,
       d.product_count_21,
       d.product_count_21 - c.product_count_20 AS difference
FROM products_2020 c
JOIN products_2021 d
ON c.segment = d.segment
ORDER BY difference DESC;

#TAsk5

SELECT p.product_code,
       p.product,
       m.manufacturing_cost
FROM dim_product p 
JOIN fact_manufacturing_cost m 
     ON p.product_code=m.product_code
WHERE m.manufacturing_cost IN ((SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost),
                              (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost))
ORDER BY m.manufacturing_cost DESC;

#Task6

SELECT c.customer_code,
       c.customer,
       p.pre_invoice_discount_pct
FROM dim_customer c
JOIN fact_pre_invoice_deductions p
ON c.customer_code=p.customer_code
WHERE p.fiscal_year=2021 AND c.market="India"
ORDER BY p.pre_invoice_discount_pct DESC
LIMIT 5;
#since we have only 1 pre_invoice_discount_for a whole year there is no need to 
#use AVG function at all since we want to calculate only for fiscal_year 2021

#Task7

WITH CTE AS (SELECT MONTHNAME(s.date) As month,
                    YEAR(s.date) AS year,
					round(SUM(g.gross_price*s.sold_quantity)/1000000,2) AS gross_sales
             FROM fact_sales_monthly s
             JOIN dim_customer c
	              ON s.customer_code=c.customer_code
             JOIN fact_gross_price g
                  ON s.product_code=g.product_code
                  AND s.fiscal_year=g.fiscal_year
		     WHERE c.customer="Atliq Exclusive"
			 GROUP BY month,year)
SELECT month,
       year,
       CONCAT(gross_sales, " M") AS gross_sales_mln
FROM CTE;

#Task8

SELECT CONCAT("Q" ,CEILING(MONTH(DATE_ADD(date, INTERVAL 4 MONTH))/3)) AS Quarters_2020,
       SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year=2020
GROUP BY Quarters_2020
ORDER BY total_sold_quantity DESC;

#Task9

WITH channel_gross_sales AS (SELECT c.channel,
								    round(SUM(g.gross_price*s.sold_quantity)/1000000,2) AS gross_sales_mln
							 FROM fact_sales_monthly s
							 JOIN dim_customer c
								  ON s.customer_code=c.customer_code
							 JOIN fact_gross_price g
								  ON s.product_code=g.product_code
								  AND s.fiscal_year=g.fiscal_year
                                  WHERE s.fiscal_year=2021
							 GROUP BY c.channel)
 SELECT *,
        CONCAT(ROUND(gross_sales_mln*100/SUM(gross_sales_mln) OVER(),2), " %") AS percentage_contribution
FROM channel_gross_sales
ORDER BY gross_sales_mln DESC;

#Task10

WITH CTE1 AS (SELECT division,
					 product_code,
					 concat(product, " | " ,variant) as product_variant,
					 SUM(sold_quantity) AS total_sold_quantity
			  FROM dim_product 
			  JOIN fact_sales_monthly 
			       USING (product_code)
			  WHERE fiscal_year=2021
              GROUP BY division,
                       product_code,
                       product_variant),
CTE2 AS (SELECT *,
	            RANK() OVER(partition by division order by total_sold_quantity DESC) AS rank_order
         FROM CTE1)
SELECT *
FROM CTE2
WHERE rank_order <=3;



