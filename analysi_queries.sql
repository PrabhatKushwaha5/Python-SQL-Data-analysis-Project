USE MyLocalDB;
SELECT * FROM data_orders;



-- select top 10 highest revenue generating prducts

select product_id,sum(sale_price) as sales
from data_orders
group by product_id
order by sales desc
limit 10;

-- select top 5 highest selling products in each region

with cte as (
select region,product_id,sum(sale_price) as sales
from data_orders
group by region,product_id)
select * from (
select *
, row_number() over (partition by region order by sales desc) as rn
from cte) A
where rn<=5;


-- fina month over month growth comparison for 2022 and 2023 salaes

WITH monthly_sales AS (
    SELECT 
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        SUM(sale_price) AS sales   -- ✅ corrected
    FROM data_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)

SELECT 
    month,
    SUM(CASE WHEN year = 2022 THEN sales END) AS sales_2022,
    SUM(CASE WHEN year = 2023 THEN sales END) AS sales_2023,
    
    ROUND(
        (SUM(CASE WHEN year = 2023 THEN sales END) -
         SUM(CASE WHEN year = 2022 THEN sales END)) /
         NULLIF(SUM(CASE WHEN year = 2022 THEN sales END), 0) * 100, 2
    ) AS yoy_growth_percent

FROM monthly_sales
GROUP BY month
ORDER BY month;



-- for each catogry which month had highest sales
WITH monthly_sales AS (
    SELECT 
        category,
        MONTH(order_date) AS month,
        SUM(sale_price) AS sales
    FROM data_orders
    GROUP BY category, MONTH(order_date)
),

ranked_sales AS (
    SELECT 
        category,
        month,
        sales,
        RANK() OVER (
            PARTITION BY category 
            ORDER BY sales DESC
        ) AS rnk
    FROM monthly_sales
)

SELECT 
    category,
    month,
    sales
FROM ranked_sales
WHERE rnk = 1
ORDER BY category;


-- which sub category had highest growth by profit in 2023 compare to 2022

WITH yearly_profit AS (
    SELECT 
        sub_category,
        YEAR(order_date) AS year,
        SUM(profit) AS total_profit
    FROM data_orders
    GROUP BY sub_category, YEAR(order_date)
),

profit_compare AS (
    SELECT 
        sub_category,
        SUM(CASE WHEN year = 2022 THEN total_profit END) AS profit_2022,
        SUM(CASE WHEN year = 2023 THEN total_profit END) AS profit_2023
    FROM yearly_profit
    GROUP BY sub_category
),

growth_calc AS (
    SELECT 
        sub_category,
        profit_2022,
        profit_2023,
        ROUND(
            (profit_2023 - profit_2022) / profit_2022 * 100, 2
        ) AS growth_percent
    FROM profit_compare
)

SELECT *
FROM growth_calc
ORDER BY growth_percent DESC
LIMIT 1;