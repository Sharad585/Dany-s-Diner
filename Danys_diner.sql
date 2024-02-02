create database case_studies;
use case_studies;

-- Create sales table
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

-- Insert data into sales table
INSERT INTO sales
  (customer_id, order_date, product_id)
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

-- Create menu table
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

-- Insert data into menu table
INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

-- Create members table

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

-- Insert data into members table
INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  /*Q1*--What is the total amount each customer spent at the restaurant?*/

  
  select * from menu;
  select * from sales;
  select * from members;
  
  select a.customer_id,sum(b.price) as total_amount from sales a
  join menu b on a.product_id=b.product_id
  group by a.customer_id;
  
    /*How many days has each customer visited the restaurant?*/
    
select customer_id,count(distinct order_date) as total_days from sales
group by customer_id;

/*What was the first item from the menu purchased by each customer?*/
with cte as (
select customer_id,order_date,product_id,rank()over(partition by customer_id order by order_date) as rnk from sales
)
select cte.customer_id,group_concat(distinct b.product_name) as first_food from cte
join menu b on cte.product_id=b.product_id
where rnk=1
group by cte.customer_id;

/*What is the most purchased item on the menu and how many times was it purchased by all customers*/

select customer_id,count(product_id) as cnt from sales
where product_id=(
select product_id as cnt from sales
group by product_id
order by count(*) desc
limit 1) 
group by customer_id
;
/*Which item was the most popular for each customer?*/
 select * from menu;
  select * from sales;
  select * from members;
  
  select customer_id,group_concat(product_name) from (
					  select customer_id,product_id,count(product_id),dense_rank()over( partition by customer_id order by count(product_id) desc) as rnk from sales
					  group by customer_id,product_id
                      )hh
                      join menu b on hh.product_id = b.product_id
                      where rnk=1
                      group by customer_id;
                      
                      
 /*Which item was purchased first by the customer after they became a member?*/
select customer_id,order_date,product_id from (
 select a.customer_id,a.order_date,a.product_id,row_number()over(partition by customer_id order by a.order_date)as rnk  from sales a 
 join members b on a.customer_id=b.customer_id and a.order_date>=b.join_date
 )hh
 where rnk=1;
 
 /*Which item was purchased just before the customer became a member*/
 
 select customer_id,order_date,product_id from (
 select a.customer_id,a.order_date,a.product_id,row_number()over(partition by customer_id order by a.order_date desc)as rnk  from sales a 
 join members b on a.customer_id=b.customer_id and a.order_date<b.join_date
 )hh
 where rnk=1;
 
 /*What is the total items and amount spent for each member before they became a member?*/
  select a.customer_id,count(a.product_id) as total_items,sum(c.price) as amount_spent from sales a 
 join members b on a.customer_id=b.customer_id and a.order_date<b.join_date
 join menu c on a.product_id=c.product_id
 group by a.customer_id
 order by a.customer_id;
 
 /*If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?*/
 with cte as (
 select a.customer_id,a.product_id,b.product_name,price from sales a  
 join menu b on a.product_id=b.product_id
 )
 select customer_id,sum(case when product_name='sushi' then price*2*10 
				else price*10 end ) as total_points from cte
                group by customer_id;
                
 /* the first week after a customer joins the program (including their join date) they earn 2x points on all items,
 not just sushi - how many points do customer A and B have at the end of January?*/    
 
 
 with cte as (
 select a.customer_id,a.product_id,c.product_name,c.price from sales a 
 join members b on a.customer_id=b.customer_id
 join menu c on a.product_id=c.product_id
 where a.order_date  between b.join_date and (b.join_date +7) 
 ),
 cte2 as(
 select customer_id,sum(price*2*10) as total_points_after_week from cte
 group by customer_id 
 ),
  cte3 as (
 select a.customer_id,a.order_date,a.product_id,b.product_name,price from sales a  
 join menu b on a.product_id=b.product_id
 join members c on a.customer_id=c.customer_id
 where a.order_date >(c.join_date+7) and a.order_date <'2021-01-31'
 ),
 cte4 as(
 select customer_id,sum(case when product_name='sushi' then price*2*10 
				else price*10 end ) as total_points from cte3
                group by customer_id
                
                )
          select cte2.customer_id,cte2.total_points_after_week,cte4.total_points,cte2.total_points_after_week+ifnull(cte4.total_points,0) as total from cte2
          left join cte4 on cte2.customer_id=cte4.customer_id
 ;
 

