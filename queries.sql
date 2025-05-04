select * from customers;
select * from city;
select * from products;
select * from sales;

-- T1: Coffee consumers count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select 
	city_name,
    (population * 0.25)/1000000 as coffee_consumers, -- to read it easily with millions, we use /1000000 
    city_rank 
from city
order by 2 desc;

-- T2: Total Revenue from coffe sales
-- What is the total revenue generated from coffee sales across all cities in the last quaryer of 2023?

select 
	ci.city_name,
	sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on c.city_id = ci.city_id
where 
	extract(year from s.sale_date)=2023
    and
    extract(quarter from s.sale_date)=4

group by 1 
order by 2 desc;

-- Task3: sales count for each product--  
-- how many units of each coffee products are sold?
select 
	p.product_name,
    count(s.sale_id) as total_orders
from products as p
left join sales as s
on p.product_id = s.product_id
group by 1
order by 2 desc;

-- Task-4: average sales amount per city
-- what is the average sales amount per customer in each city
select 
	ci.city_name,
  --   sum(s.total) as total_revenue,
--     count(distinct(c.customer_id)) as total_count,
	sum(s.total)/count(distinct(c.customer_id), 2) as avg_sales
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on c.city_id = ci.city_id
group by 1
order by 2 desc;

-- Task-5: coffee consumers vs unique coffee consumers
-- only 25% population will consume
with city_table as (
select 
	city_name,
    Round((population*0.25)/1000000, 2) as coffee_consumers
from city
),
customers_table as
(select
	ci.city_name,
    count(distinct c.customer_id) as unique_customers_count
from sales as s
join customers as c
on c.customer_id = s.customer_id
join city as ci
on c.city_id = ci.city_id 
group by 1
)
select
	ct.city_name,
    ct.coffee_consumers,
    cu.unique_customers_count
from city_table as ct
join customers_table as cu
on cu.city_name = ct.city_name

order by 2 desc;

-- Task-6: Top selling products by city
-- what are the top 3 selling products in each city based on sales volume?
 select *
 from 
(select 
	ci.city_name,
    p.product_name,
    count(sale_id) as total_orders,
    dense_rank() over(partition by ci.city_name order by count(sale_id) desc) as ranks
from sales as s
join products as p
on s.product_id = p.product_id
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id=c.city_id
group by 1,2
) as table1
where ranks<=3;
-- order by 1,3 desc

-- Task-7: Customer segmentation by city 
--  How many unique customers are there in each city who have purchased coffee products?

select
	ci.city_name,
    count(distinct(c.customer_id)) as unique_customers
from city as ci
left join customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1;

-- Task-8: Average sales vs Rent
-- Find each city and their average sales per customer and avg rent per customer
with 
city_table 
as 
	(select 
		ci.city_name,
        sum(s.total) as total_revenue,
        count(distinct s.customer_id) as total_customers,
		round(sum(s.total)/count(distinct(s.customer_id)),2) as avg_sales   
		
	from sales as s
	join customers as c
	on s.customer_id = c.customer_id
	join city as ci
	on c.city_id = ci.city_id
	group by 1
	order by 2 desc
),
city_rent
as
-- City and total rent/total customers
(select 
	city_name,
    estimated_rent
from city)
select
	cr.city_name,
    cr.estimated_rent,
    ct.total_customers,
    ct.avg_sales,
    round((cr.estimated_rent/ct.total_customers),2) as avg_rent
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 4 desc;

-- Task-9:  Monthly sales growth
-- sales growth rate: calculate the %growth(or decline) in sales over different time periods(monthly)
with
monthly_sales as
(select 
	ci.city_name,
    extract(month from sale_date) as month,
    extract(year from sale_date) as year,
    sum(s.total) as total_sale
	-- lag(total_sale, 1) over(partition by city_name order by year, month) as last_month_sale

from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on c.city_id = ci.city_id
group by 1,2,3
order by 1,3,2
),
growth_ratio
as
(select 
	city_name,
    month,
    year,
    total_sale as current_month_sale,
    lag(total_sale, 1) over(partition by city_name order by year, month) as last_month_sale
from monthly_sales)
select
	city_name,
	month,
    year,
    current_month_sale,
    round((((current_month_sale-last_month_sale)/(last_month_sale)) * 100),2) as growth_ratio
from growth_ratio;

-- Task-10: market potential analysis
-- identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumers

with city_table
as
 (select
	ci.city_name,
    sum(s.total) as total_revenue,
    count(distinct s.customer_id) as total_customers,
    round(sum(s.total)/count(distinct s.customer_id)) as avg_sales_per_customer
 from sales as s
 join customers as c
 on s.customer_id = c.customer_id
 join city as ci
 on ci.city_id = c.city_id
 group by 1
 order by 2 desc
 ),
city_rent as
(select
	city_name,
    estimated_rent as total_rent,
    (population * 0.25)/1000000 as estimated_coffee_consumers_in_millions
from city)
select
	cr.city_name,
    ct.total_revenue,
    cr.total_rent,
    ct.total_customers,
    cr.estimated_coffee_consumers_in_millions,
    ct.avg_sales_per_customer,
    round(cr.total_rent/ct.total_customers, 2) as avg_rent_per_customer
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 2 desc;

-- Recommendations of the cities
-- 1. Pune
-- 	highest total revenue, avg rent is low and avg sales per customer is high

-- 2. Delhi
-- 	highest estimated coffee consumers, highest total customers, avg rent per customer is 330 only

-- 3. Jaipur
-- 	highest total customers, avg rent is less, avg sales is also better




    









