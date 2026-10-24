use dannys_diner

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INT,
  "product_name" VARCHAR(5),
  "price" INT
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  SELECT * FROM members
  SELECT * FROM sales
  SELECT * FROM menu

  /*Problem Statement
Danny wants to use the data to answer a few simple questions about his customers,
especially about their visiting patterns, how much money they’ve spent and also which menu 
items are their favourite. Having this deeper connection with his customers will help him 
deliver a better and more personalised experience for his loyal customers.He plans on using 
these insights to help him decide whether he should expand the existing customer loyalty 
program - additionally he needs help to generate some basic datasets so his team can easily
inspect the data without needing to use SQL.Danny has provided you with a sample of his 
overall customer data due to privacy issues - but he hopes that these examples are enough 
for you to write fully functioning SQL queries to help him answer his questions!*/

--Case Study Questions

--What is the total amount each customer spent at the restaurant?
select customer_id,sum(price) as prices from sales
	join menu on sales.product_id = menu.product_id
	group by customer_id

--How many days has each customer visited the restaurant?
select customer_id, count(order_date) as days_visited from sales
group by customer_id
--What was the first item from the menu purchased by each customer?
select  customer_Id, order_date,product_name from sales
join menu on sales.product_id = menu.product_id
where order_date = (select min(order_date) as first_order from sales)


--What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name,count( sales.product_id) as purchase_frequency from sales
join menu on sales.product_id = menu.product_id
group by product_name
order by purchase_frequency desc

--Which item was the most popular for each customer?
select customer_id, product_name,count( sales.product_id) as purchase_frequency from sales
join menu on sales.product_id = menu.product_id
where sales.product_id = (select max( sales.product_id) from sales)
group by customer_id,product_name

--Which item was purchased first by the customer after they became a member?
select  join_date,sales.customer_id,order_date,sales.product_id from sales
join members on sales.customer_id= members.customer_id
where order_date > join_date  
and order_date = (select min(order_date) from sales as first_order 
where first_order.customer_id = sales.customer_id 
and order_date > join_date )

--Which item was purchased just before the customer became a member?
select  join_date,sales.customer_id,order_date,sales.product_id from sales
join members on sales.customer_id= members.customer_id
where order_date < join_date  
and order_date = (select max(order_date) from sales as first_order 
where first_order.customer_id = sales.customer_id 
and order_date < join_date )
--What is the total items and amount spent for each member before they became a member?
select sales.customer_id,sum(price) as amount_spent, count(sales.product_id) as total_items from sales
join menu on sales.product_id = menu.product_id
join members on sales.customer_id = members.customer_id
where order_date < join_date
group by sales.customer_id

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id, sum(case when product_name = 'sushi' then price * 10 * 2 else price * 10
end) as points from sales
join menu on sales.product_id = menu.product_id
group by customer_id

/*In the first week after a customer joins the program (including their join date) they 
earn 2x points on all items, not just sushi - how many points do customer A and B have 
at the end of January?*/
select sales.customer_id, sum(case when order_date >= join_date and 
order_date <= dateadd(day,6,join_date) then price *10*20
when product_name = 'sushi' then price * 10 * 2 else price * 10
end) as points from sales
join menu on sales.product_id = menu.product_id
left join members on sales.customer_id = members.customer_id
where order_date <= '2021-01-31'
group by sales.customer_id

--order history table
select sales.customer_id, sales.order_date,menu.product_name, menu.price,
case when order_date >= members.join_date then 'Y' ELSE 'N' end as member
into member_order_history
from sales
join menu on sales.product_id = menu.product_id
left join members on sales.customer_id = members.customer_id

select * from member_order_history

--Ranking
select customer_id,order_date,product_name,price,member,
case when member = 'Y' then dense_rank() over(partition by customer_id,member
order by order_date asc) else null end as ranking
from member_order_history
order by customer_id, order_date asc