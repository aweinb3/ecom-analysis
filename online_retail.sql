
------------ SETTING UP DATA -------------

copy retail_sales(transactions_id,sale_date,sale_time,customer_id,gender,age,category,quantity,price_per_unit,cogs,total_sale)
from '/Library/PostgreSQL/17/data/Retail_Sales.csv'
delimiter ','
csv header:

select * from retail_sales
order by customer_id;

-- removing null values
select * from retail_sales where
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR 
    gender IS NULL OR age IS NULL OR category IS NULL OR 
    quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL;

delete from retail_sales where
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR 
    gender IS NULL OR age IS NULL OR category IS NULL OR 
    quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL;

-- updating data types
alter table retail_sales
alter column price_per_unit set data type numeric(10,0),
alter column cogs set data type numeric(10,1),
alter column total_sale set data type numeric(10,0);

-- adding revenue column
alter table retail_sales
add column revenue numeric(10,1);
update retail_sales
set revenue = total_sale - (cogs * quantity);

-- checking date range and customer count
select min(sale_date), max(sale_date) from retail_sales; -- sales span 1/1/2022 - 12/31/2023
select count(*) count, count(distinct customer_id) distinct from retail_sales;




------------ SALES PERFORMANCE -------------

-- sales info by month
SELECT
    to_char (sale_date, 'YYYY-MM') as month,
    sum (quantity) as sales_count,
    round(avg(revenue)::numeric,2) as avg_rev,
    sum (revenue) as tot_rev
from retail_sales
group by month
order by month;

-- annual growth
select 
    to_char (sale_date, 'YYYY') as year,
    count (*) as orders,
    sum(quantity) as units_sold,
    sum(revenue) as tot_rev
from retail_sales
group by year;

-- sales by hour of day
SELECT
    extract (hour from sale_time) as sale_hour,
    count (*) as order_count,
    round(avg(revenue),2) as avg_revenue
from retail_sales
group by sale_hour
order by sale_hour;

-- order trends by age segment
SELECT
    CASE
        when age between 13 and 28 then 'Gen_Z'
        when age between 29 and 44 then 'Millennial'
        when age between 45 and 60 then 'Gen_X'
        else 'Boomer'
    end as age_group,
    count (*) as sales_count,
    round(avg(revenue),2) as avg_revenue,
    mode() within group (order by category) as most_popular_category
from retail_sales
group by age_group;

-- order trends by gender
select
    gender,
    count (*) as sales_count,
    round(avg(revenue),2) as avg_revenue,
    mode() within group (order by category) as most_popular_category
from retail_sales
group by gender;

-- order trends by category
select 
    category, 
    count (*) as sales_count,
    sum(revenue) revenue,
    round(avg(revenue),2) as avg_revenue,
    mode() within group (order by gender) as pop_amongst,
    count(distinct customer_id) as distinct_customers
from retail_sales
group by category
order by revenue desc;

-- min avg and max for profit, order quantity, and revenue
select min(total_sale), avg(total_sale), max(total_sale) from retail_sales;
select min(quantity), avg(quantity), max(quantity) from retail_sales;
select min(revenue), avg(revenue), max(revenue) from retail_sales;

-- # of transactions with negative revenue
select count(transactions_id) from retail_sales where revenue < 0;

-- negative transactions by category
select category, count(transactions_id) from retail_sales 
where revenue < 0
group by category
order by count desc;

-- which customer_IDs do we have a net loss from
select customer_id, sum(revenue), count(transactions_id)
from retail_sales
group by customer_id
having sum(revenue) < 0;

-- which customer_IDs do we make the most on?
SELECT
    customer_id,
    sum(revenue) as revenue,
    count(transactions_id) as orders,
    round(avg(revenue),2) as avg_revenue
from retail_sales
group by customer_id
order by revenue desc
limit 15;


------------ RFM ANALYSIS -------------

-- For each customer_id find: 
-- most recent purchase
-- number of orders made in the last 3 months
-- total revenue from the last 3 months

select 
    customer_id, 
    max(sale_date) as most_recent_purchase,
    count(case when sale_date >= '2023-09-01' then customer_id end) as orders,
    sum(case when sale_date >= '2023-09-01' then revenue end) as revenue
from retail_sales 
group by customer_id
order by most_recent_purchase desc;