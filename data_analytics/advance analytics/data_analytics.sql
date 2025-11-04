use DataWarehouse;
-- Advance analytics--
-- change over time

-- change over year(a high level overview insights that help with strategic decision making)
select 
datepart(year, order_date) as order_year,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by datepart(year, order_date)
order by datepart(year, order_date);

-- change over month: (discover the seasonality of data)
select 
format(order_date, 'MMMM') as order_month,
-- datename(month, order_date) as 
--MONTH(order_date) as order_month,
--datepart(year, order_date) as order_year,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by format(order_date, 'MMMM')--MONTH(order_date)
order by order_month;

-- year month both:
select 
year(order_date) as order_year,
MONTH(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by year(order_date),
MONTH(order_date) 
order by order_month;

select 
format(order_date, 'yyyy-MMM') as order_date,
--DATETRUNC(month, order_date)
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by format(order_date, 'yyyy-MMM')
order by order_date;

---------------------------------------
-- cumulative analysis--
-- calculate the total sales per month
-- & the running total and moving average of sales over time.
with data_agg as (
select 
DATETRUNC(month, order_date) as order_date,
sum(sales_amount) as total_sales,
avg(price) as avg_price
from gold.fact_sales
where order_date is not null
group by DATETRUNC(month, order_date)
)
select order_date, 
total_sales, 
avg_price,
sum(total_sales) over(partition by order_date order by order_date) as running_total_sales,
avg(avg_price) over(partition by order_date order by order_date) as moving_average_price
from data_agg;

-- same thing for year:
with data_agg as (
select 
DATETRUNC(YEAR, order_date) as order_date,
sum(sales_amount) as total_sales,
avg(price) as avg_price
from gold.fact_sales
where order_date is not null
group by DATETRUNC(YEAR, order_date)
)
select order_date, 
total_sales, 
avg_price,
sum(total_sales) over(partition by order_date order by order_date) as running_total_sales,
avg(avg_price) over(partition by order_date order by order_date) as moving_average_price
from data_agg;


-- Performace Analysis--
-- analyze the yearly performance of products by comparing their sales
-- to both the average sales performace of the product and the previous year's sales

with yearly_product_sales as (
select year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales 
from gold.fact_sales as f
left join gold.dim_products as p
on f.product_key = p.product_key
where order_date is not null
group by year(f.order_date),p.product_name)
select order_year,
product_name,
current_sales,
avg(current_sales) over(partition by product_name) avg_sales,
current_sales - avg(current_sales) over(partition by product_name) as diff_avg,
case
	when current_sales - avg(current_sales) over(partition by product_name) > 0 
	then 'Above Average'
	when current_sales - avg(current_sales) over(partition by product_name) <0
	then 'Below Average'
	else 'Average'
end as avg_change,
-- year over Year Analysis:
lag(current_sales) over(partition by product_name order by order_year) as py_sales,
current_sales - lag(current_sales) over(partition by product_name order by order_year) as diff_py,
case
	when current_sales - lag(current_sales) over(partition by product_name order by order_year) > 0 
	then 'Increase'
	when current_sales - lag(current_sales) over(partition by product_name order by order_year) < 0
	then 'Decrease'
	else 'No change'
end as py_change
from yearly_product_sales;

-- Part to whole analysis------
-- which category contributes the most to overall sales?

with category_sales as (
select 
p.category,
sum(f.sales_amount) total_sales
from gold.fact_sales as f
left join gold.dim_products as p
on p.product_key = f.product_key
group by p.category)
select category,
total_sales,
sum(total_sales) over() overall_sales,
concat(round((cast(total_sales as float)/ sum(total_sales) over()) * 100,2),'%') as percentage_of_total
from category_sales
order by total_sales desc; -- bike cat contribute the most

-- Data segmentation-----
-- segment products into cost ranges and count how many products fall into each segment

with product_segments as (
select product_key, 
product_name,
cost,
case
	when cost < 100 then 'Below 100'
	when cost between 100 and 500 then '100 - 500'
	when cost between 500 and 1000 then '500 - 1000'
	else 'Above 1000'
end as cost_range
from gold.dim_products)
select cost_range,
count(product_key) as total_products
from product_segments
group by cost_range
order by total_products desc;

/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/
with customer_spending as (
select 
c.customer_key,
sum(f.sales_amount) total_spending,
min(f.order_date) as first_order,
max(order_date) as last_order,
datediff(month , min(order_date), max(order_date)) as lifespan
from gold.fact_sales as f
left join gold.dim_customers as c
on f.customer_key = c.customer_key
group by  c.customer_key)
, data_segments as (
select customer_key,
total_spending,
lifespan,
case
	when lifespan >= 12 and total_spending > 5000 then 'VIP'
	when lifespan >= 12 and total_spending <= 5000 then 'Regular'
	else 'New'
end as customer_segments
from customer_spending)
select 
customer_segments,
count(customer_key) as total_customer
from data_segments
group by customer_segments
order by total_customer desc;

-- Reproting:

-- Customer Report:

-- Create Report: gold.report_customers
-- =============================================================================
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

WITH base_query AS(
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)

, customer_aggregation AS (
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
	 WHEN age < 20 THEN 'Under 20'
	 WHEN age between 20 and 29 THEN '20-29'
	 WHEN age between 30 and 39 THEN '30-39'
	 WHEN age between 40 and 49 THEN '40-49'
	 ELSE '50 and above'
END AS age_group,
CASE 
    WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
    WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
    ELSE 'New'
END AS customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_products
lifespan,
-- Compuate average order value (AVO)
CASE WHEN total_sales = 0 THEN 0
	 ELSE total_sales / total_orders
END AS avg_order_value,
-- Compuate average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
     ELSE total_sales / lifespan
END AS avg_monthly_spend
FROM customer_aggregation;
select * from gold.report_customers;


------------------------------------------------------------------------------------------------------
-- Product reprort:
-----------------------------------------------------------
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
    SELECT
	    f.order_number,
        f.order_date,
		f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  -- only consider valid sales dates
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan
	END AS avg_monthly_revenue

FROM product_aggregations;
select * from gold.report_products;