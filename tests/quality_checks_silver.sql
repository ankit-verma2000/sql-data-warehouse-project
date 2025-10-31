/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    cst_id,
    COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    cst_key 
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- Data Standardization & Consistency
SELECT DISTINCT 
    cst_marital_status 
FROM silver.crm_cust_info;

-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    prd_id,
    COUNT(*) 
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    prd_nm 
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLs or Negative Values in Cost
-- Expectation: No Results
SELECT 
    prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & Consistency
SELECT DISTINCT 
    prd_line 
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders (Start Date > End Date)
-- Expectation: No Results
SELECT 
    * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================
-- Check for Invalid Dates
-- Expectation: No Invalid Dates
SELECT 
    NULLIF(sls_due_dt, 0) AS sls_due_dt 
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
    OR LEN(sls_due_dt) != 8 
    OR sls_due_dt > 20500101 
    OR sls_due_dt < 19000101;

-- Check for Invalid Date Orders (Order Date > Shipping/Due Dates)
-- Expectation: No Results
SELECT 
    * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results
SELECT DISTINCT 
    sls_sales,
    sls_quantity,
    sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================
-- Identify Out-of-Range Dates
-- Expectation: Birthdates between 1924-01-01 and Today
SELECT DISTINCT 
    bdate 
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' 
   OR bdate > GETDATE();

-- Data Standardization & Consistency
SELECT DISTINCT 
    gen 
FROM silver.erp_cust_az12;

-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================
-- Data Standardization & Consistency
SELECT DISTINCT 
    cntry 
FROM silver.erp_loc_a101
ORDER BY cntry;

-- ====================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ====================================================================
-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    * 
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT 
    maintenance 
FROM silver.erp_px_cat_g1v2;



-----------------------------------
-- Proper end to end: data qualtiy checks
----------------------------------------------------------------
----------------------------------------------------------------
-- Checks for null or duplicates in a primary key:

select * from bronze.crm_cust_info;
-- Check for duplicates:
select cst_id, count(*) as no_duplicates
from bronze.crm_cust_info
group by cst_id
having count(*) >1;

select * from (select *, 
row_number() over(partition by cst_id order by cst_create_date desc)  as flag_last
from bronze.crm_cust_info
where cst_id is not null) as t
where flag_last =1


-- Quality check;
--- check for unwanted spaces in the string value:
select cst_id, cst_key,
trim(cst_firstname) as cst_firstname, 
Trim(cst_lastname) as cst_lastname,
case when upper(trim(cst_marital_status)) = 'S' Then 'Single' 
	when upper(trim(cst_marital_status)) = 'M' then 'Married' 
	else 'n/a' 
end cst_marital_status,
case when upper(trim(cst_gndr)) = 'F' Then 'Female' 
	when upper(trim(cst_gndr)) = 'M' then 'Male' 
	else 'n/a' 
end cst_gndr,
cst_create_date
from (select *, 
row_number() over(partition by cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info
where cst_id is not null) as t
where flag_last =1;

-------------------------
select * from bronze.crm_prd_info;

-- Check for duplicates:
select prd_id, count(*) as no_duplicates
from bronze.crm_prd_info
group by prd_id
having count(*) >1

-- check for negative or  null values in crm prd info
select prd_cost
from bronze.crm_prd_info
where prd_cost < 0 or prd_cost is null

-- data std and consistency:
select distinct prd_line
from bronze.crm_prd_info;

select distinct prd_line
from silver.crm_prd_info;
--use DataWarehouse
-- check for invalid date orders:

-- check for extraa spaces:
select *
from bronze.crm_sales_details
where sls_ord_num != trim(sls_ord_num)

-- check for invalid dates: -- check for all the dates in the sales_details table: 

select nullif(sls_ship_dt, 0) as sls_ship_dt
from bronze.crm_sales_details
where sls_ship_dt <=0
or len(sls_ship_dt) != 8
or sls_ship_dt> 20500101
or sls_ship_dt < 19000101

-- check for invaid date s orders:
select * from bronze.crm_sales_details
where sls_order_dt < sls_order_dt or sls_due_dt < sls_order_dt;

-- check for data consistency: 
-- sales = qunaitity *price and value != 0 or null or negative:
select sls_sales , sls_quantity ,sls_price,
case 
	when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
	else sls_sales
end as sls_sales,

from bronze.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <=0 or sls_quantity <=0 or sls_price <=0
order by sls_sales , sls_quantity ,sls_price
-----------------
select distinct
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,
 case
	when sls_sales is null or sls_sales <=0 or sls_sales != sls_quantity * abs(sls_price)
	then sls_quantity * abs(sls_price)
	else sls_sales
 end as sls_sales,
 case
	when sls_price is null or sls_price <=0 
	then sls_sales / nullif(sls_quantity, 0)
	else sls_price
 end as sls_price
from bronze.crm_sales_details
where sls_sales ! = sls_quantity * sls_price

--------------------------------
-- bronze erp_cust_az12 ---
select distinct
bdate from bronze.erp_cust_az12
where bdate > getdate() or bdate < '1924-01-01' -- not possible to survive that long and invalid date is written

-- data std and consistency:
select distinct gen,
case when upper(trim(gen)) in ('F', 'FEMALE') THEN 'Female' 
when upper(trim(gen)) in ('M', 'MALE') THEN 'Male'
else 'n/a'
end as gen
from bronze.erp_cust_az12

------------------------------------
--- bronze.erp_loc_a101
--- handle missing and null values:

select 
distinct cntry,
case when trim(cntry) = 'DE' then 'Germany'
when trim(cntry) in ('US', 'USA') then 'United States'
when trim(cntry) = '' or cntry is null then 'n/a'
else trim(cntry) 
end as cntry
from bronze.erp_loc_a101;

--------------------------------erp_px_cat_g1v2
-- check for unwanted spaces:

select *
from bronze.erp_px_cat_g1v2
where cat != trim(cat) or subcat != trim(subcat) or maintenance != trim(maintenance)

-- data std and consistency:
select distinct cat
from bronze.erp_px_cat_g1v2; 
select distinct subcat
from bronze.erp_px_cat_g1v2;
select distinct maintenance
from bronze.erp_px_cat_g1v2;

