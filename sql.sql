/*Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset*/
/*1.Data type of all columns in the "customers" table*/
SELECT column_name,data_type FROM `target_dataset.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'customers'
/*2.Get the time range between which the orders were placed:*/
select min(order_purchase_timestamp) as start_date,max(order_purchase_timestamp) as end_date,date_diff(
max(order_purchase_timestamp),min(order_purchase_timestamp),day) as time_span from`target.orders`
/*3.Count the Cities & States of customers who ordered during the given period:*/
select count(distinct customer_city) as cities,count(distinct customer_state) as states
from `target.customers` c join `target.orders` o on c.customer_id=o.customer_id
/*4.growing trend in the no. of orders placed over the past years*/
select extract(year from order_purchase_timestamp) as year, count(order_id) as num_order
from `target.orders`
group by extract(year from order_purchase_timestamp)order by num_order
/*5.monthly seasonality in terms of the no. of orders being placed?*/
select format_timestamp('%Y-%m',order_purchase_timestamp) as
year_month,count(order_id) as num_order
from `target.orders`
group by year_month
order by year_month
/*6.During what time of the day, do the Brazilian customers mostly place their orders:
(Dawn, Morning, Afternoon or Night)
o 0-6 hrs : Dawn
o 7-12 hrs : Mornings
o 13-18 hrs : Afternoon
o 19-23 hrs : Night*/
SELECT
CASE
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6
THEN 'Dawn'
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12
THEN 'Morning'
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18
THEN 'Afternoon'
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 19 AND 23
THEN 'Night'
END AS time_of_day,
COUNT(order_id) AS num_orders
FROM
`target.orders`
GROUP BY
CASE
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6
THEN 'Dawn'
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12
THEN 'Morning'
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18
THEN 'Afternoon'
WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 19 AND 23
THEN 'Night'
END
ORDER BY
num_orders DESC
/*7.Evolution of E-commerce orders in the Brazil region:
month on month no. of orders placed in each state.*/
select extract(year from o.order_purchase_timestamp) as order_year,extract(month from
o.order_purchase_timestamp) as order_month
,count(o.order_id) as num_order,c.customer_state from `target.orders` o join
`target.customers` c
on o.customer_id=c.customer_id
group by extract(year from order_purchase_timestamp),extract(month from
order_purchase_timestamp),customer_state
order by order_year, order_month,customer_state
/*8.customers distributed across all the states*/
select customer_state,count(customer_id) as cus_dist from `target.customers`
group by customer_state
order by cus_dist
/*9.Get the % increase in the cost of orders from year 2017 to 2018 (include months
between Jan to Aug only).
You can use the "payment_value" column in the payments table to get the cost of
orders.*/
WITH orders_2017 AS (
SELECT SUM(payment_value) AS total_cost_2017
FROM `target.payments`
WHERE order_id IN (
SELECT order_id
FROM `target.orders`
WHERE order_purchase_timestamp BETWEEN '2017-01-01' AND '2017-08-31')),
orders_2018 AS (
SELECT SUM(payment_value) AS total_cost_2018
FROM `target.payments`
WHERE order_id IN (
SELECT order_id
FROM `target.orders`
WHERE order_purchase_timestamp BETWEEN '2018-01-01' AND '2018-08-31'
))SELECT ROUND ((orders_2018.total_cost_2018 - orders_2017.total_cost_2017) /
orders_2017.total_cost_2017 * 100,2) AS percentage_increase
FROM orders_2017, orders_2018
/*10.Total & Average value of order price for each state*/
select c.customer_state,round(sum(ot.price),2) as price,round(avg(ot.price),2) as average
from `target.customers` c join `target.orders` o
on c.customer_id=o.customer_id
join `target.order_items` ot on o.order_id= ot.order_id
group by c.customer_state
/*11.Total & Average value of order freight for each state*/
select c.customer_state,round(sum(ot.freight_value),2) as
price,round(avg(ot.freight_value),2) as average from `target.customers` c join `target.orders`
o on c.customer_id=o.customer_id
join `target.order_items` ot on o.order_id= ot.order_id
group by c.customer_state
/*12.Find the no. of days taken to deliver each order from the order’s purchase date as
delivery time.
Also, calculate the difference (in days) between the estimated & actual delivery date of
an order.*/
select order_id,date_diff(order_delivered_customer_date,order_purchase_timestamp,day) as
time_to_deliver
,date_diff(order_delivered_customer_date,order_estimated_delivery_date,day) as
diff_estimated_delivery from `target.orders`
group by order_id,time_to_deliver,diff_estimated_delivery
/*13.Find out the top 5 states with the highest & lowest average freight value*/
QUERY FOR HIGHEST:
select customer_state,highest_avg,avg_fv from
(select customer_state,round(avg(freight_value),4) as avg_fv,dense_rank()over(order by
avg(freight_value)desc) as highest_avg from `target.order_items` ot join `target.orders`o on
ot.order_id=o.order_id join `target.customers` c on o.customer_id=c.customer_id
group by customer_state)t
where highest_avg<=5
order by highest_avg
QUERY FOR LOWEST:
select customer_state,lowest_avg,avg_fv from
(select customer_state,round(avg(freight_value),4) as avg_fv,dense_rank()over(order by
avg(freight_value)) as lowest_avg from `target.order_items` ot join `target.orders`o on
ot.order_id=o.order_id join `target.customers` c on o.customer_id=c.customer_id
group by customer_state)t
where lowest_avg<=5
order by lowest_avg
/*14.Find out the top 5 states where the order delivery is really fast as compared to the
estimated date of delivery.
You can use the difference between the averages of actual & estimated delivery date to
figure out how fast the delivery was for each state.*/
select customer_state,delivery_time,fast_del from
(select customer_state,avg(date_diff(
order_estimated_delivery_date,order_delivered_customer_date,day)) as
delivery_time,row_number()over(order by avg(date_diff(
order_estimated_delivery_date,order_delivered_customer_date,day))) as fast_del from
`target.customers` c join `target.orders` o on c.customer_id=o.customer_id
group by customer_state)t
where fast_del<=5
order by fast_del
/*15.month on month no. of orders placed using different payment types*/
select extract(year from order_purchase_timestamp) as year, extract(month from
order_purchase_timestamp) as month,payment_type,count(o.order_id) as num_order from
`target.orders` o join `target.payments` p on o.order_id=p.order_id
group by extract(year from order_purchase_timestamp),extract(month from
order_purchase_timestamp),payment_type
order by year,month
/*16.no. of orders placed on the basis of the payment installments that have
been paid.*/
select payment_installments,count(order_id) as num_order from `target.payments`
group by payment_installments
order by payment_installments
