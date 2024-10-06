/*-----------------------------------------------------------------------------------------------------------------------------------

                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
use orders;
show tables;

-- 1. WRITE A QUERY TO DISPLAY CUSTOMER FULL NAME WITH THEIR TITLE (MR/MS), BOTH FIRST NAME AND LAST NAME ARE IN UPPER CASE WITH 
-- CUSTOMER EMAIL ID, CUSTOMER CREATIONDATE AND DISPLAY CUSTOMER’S CATEGORY AFTER APPLYING BELOW CATEGORIZATION RULES:
	-- i.IF CUSTOMER CREATION DATE YEAR <2005 THEN CATEGORY A
    -- ii.IF CUSTOMER CREATION DATE YEAR >=2005 AND <2011 THEN CATEGORY B
    -- iii.IF CUSTOMER CREATION DATE YEAR>= 2011 THEN CATEGORY C
    
    -- HINT: USE CASE STATEMENT, NO PERMANENT CHANGE IN TABLE REQUIRED. [NOTE: TABLES TO BE USED -ONLINE_CUSTOMER TABLE]

select concat(case CUSTOMER_GENDER 
when 'M' then 'Mr.' 
when 'F' then 'Ms.' 
end ,' ',upper(CUSTOMER_FNAME),' ' ,upper(CUSTOMER_LNAME) ) as Customer_full_name,CUSTOMER_EMAIL,CUSTOMER_CREATION_DATE, 
case 
when year(CUSTOMER_CREATION_DATE)<2005 then 'A' 
when 2005<=year(CUSTOMER_CREATION_DATE) and year(CUSTOMER_CREATION_DATE)<2011 then 'B' else 'C' 
end as Customers_Category from online_customer;

-- 2. WRITE A QUERY TO DISPLAY THE FOLLOWING INFORMATION FOR THE PRODUCTS, WHICH HAVE NOT BEEN SOLD:  PRODUCT_ID, PRODUCT_DESC, 
-- PRODUCT_QUANTITY_AVAIL, PRODUCT_PRICE,INVENTORY VALUES(PRODUCT_QUANTITY_AVAIL*PRODUCT_PRICE), NEW_PRICE AFTER APPLYING DISCOUNT 
-- AS PER BELOW CRITERIA. SORT THE OUTPUT WITH RESPECT TO DECREASING VALUE OF INVENTORY_VALUE.
	-- i.IF PRODUCT PRICE > 20,000 THEN APPLY 20% DISCOUNT
    -- ii.IF PRODUCT PRICE > 10,000 THEN APPLY 15% DISCOUNT
    -- iii.IF PRODUCT PRICE =< 10,000 THEN APPLY 10% DISCOUNT
    
    -- HINT: USE CASE STATEMENT, NO PERMANENT CHANGE IN TABLE REQUIRED. [NOTE: TABLES TO BE USED -PRODUCT, ORDER_ITEMS TABLE] 
    
select product_id, product_desc, product_quantity_avail, product_price, (product_quantity_avail*product_price) as inventory_values,
case
when product_price > 20000 then(product_price*20)/100
when product_price > 10000 then(product_price*15)/100
when product_price <= 10000 then(product_price*10)/100
end as New_price
from product
order by inventory_values desc;

-- 3. WRITE A QUERY TO DISPLAY PRODUCT_CLASS_CODE, PRODUCT_CLASS_DESCRIPTION, COUNT OF PRODUCT TYPE IN EACH PRODUCT CLASS, 
-- INVENTORY VALUE (P.PRODUCT_QUANTITY_AVAIL*P.PRODUCT_PRICE). INFORMATION SHOULD BE DISPLAYED FOR ONLY THOSE PRODUCT_CLASS_CODE 
-- WHICH HAVE MORE THAN 1,00,000 INVENTORY VALUE. SORT THE OUTPUT WITH RESPECT TO DECREASING VALUE OF INVENTORY_VALUE.
	-- [NOTE: TABLES TO BE USED -PRODUCT, PRODUCT_CLASS]
    
select PC.product_class_code,PC.product_class_desc, 
count(P.product_desc) AS PRODUCT_TYPE_COUNT,
sum(P.product_quantity_avail * P.product_price) AS INVENTORY_VALUE
from product_class PC
join product P ON PC.product_class_code = P.product_class_code
group by PC.PRODUCT_CLASS_CODE, PC.PRODUCT_CLASS_DESC
having sum(P.product_quantity_avail * P.product_price) > 100000
order by inventory_value desc;
    
-- 4. WRITE A QUERY TO DISPLAY CUSTOMER_ID, FULL NAME, CUSTOMER_EMAIL, CUSTOMER_PHONE AND COUNTRY OF CUSTOMERS WHO HAVE CANCELLED 
-- ALL THE ORDERS PLACED BY THEM(USE SUB-QUERY)
	-- [NOTE: TABLES TO BE USED - ONLINE_CUSTOMER, ADDRESSS, ORDER_HEADER]

select o.customer_id,concat(upper(o.customer_fname),' ',upper(o.customer_lname))
Full_Name,o.customer_email, o.customer_phone,a.country
from online_customer o
inner join address a
using (Address_id)
inner join order_header
using (customer_id)
where Order_status= 'Cancelled';
   
-- 5. WRITE A QUERY TO DISPLAY SHIPPER NAME, CITY TO WHICH IT IS CATERING, NUMBER OF CUSTOMER CATERED BY THE SHIPPER IN THE CITY AND 
-- NUMBER OF CONSIGNMENTS DELIVERED TO THAT CITY FOR SHIPPER DHL(9 ROWS)
	-- [NOTE: TABLES TO BE USED -SHIPPER, ONLINE_CUSTOMER, ADDRESSS, ORDER_HEADER]

select S.shipper_name,a.city, 
count(OH.customer_id) as customers_ount,
count(OH.order_id) as number_of_consignments
from shipper S
inner join order_header OH on S.shipper_id = OH.shipper_id
inner join online_customer OC on OH.customer_id = OC.customer_id
inner join address A on OC.address_id = A.address_id
where   order_status='shipped' and S.shipper_name='DHL'
group by S.shipper_name, A.city;      

-- 6. WRITE A QUERY TO DISPLAY CUSTOMER ID, CUSTOMER FULL NAME, TOTAL QUANTITY AND TOTAL VALUE (QUANTITY*PRICE) SHIPPED WHERE MODE 
-- OF PAYMENT IS CASH AND CUSTOMER LAST NAME STARTS WITH 'G'
	-- [NOTE: TABLES TO BE USED -ONLINE_CUSTOMER, ORDER_ITEMS, PRODUCT, ORDER_HEADER]

select oc.customer_id,concat(oc.customer_fname,' ',oc.customer_lname) as
Full_Name,count(o.product_quantity) as total_quantity,
sum(o.product_quantity * p.product_price) as total_value
from online_customer oc
inner join order_header oh
using (customer_id)
inner join order_items o
using(order_id)
inner join product p
using (product_id)
where order_status = 'Shipped' and payment_mode='Cash' and customer_lname like 'G%'
group by customer_id;

    
-- 7. WRITE A QUERY TO DISPLAY ORDER_ID AND VOLUME OF BIGGEST ORDER (IN TERMS OF VOLUME) THAT CAN FIT IN CARTON ID 10  
	-- [NOTE: TABLES TO BE USED -CARTON, ORDER_ITEMS, PRODUCT]

select O.order_id , max(P.len*P.width*P.height) as volume,
max(product_quantity) as total_qty
from order_items O
inner join product P on O.product_id = P.product_id
where O.order_id IN(
					select order_id from carton where carton_id=10
                    )
group by O.order_id
order by volume desc
limit 1;

-- 8. WRITE A QUERY TO DISPLAY PRODUCT_ID, PRODUCT_DESC, PRODUCT_QUANTITY_AVAIL, QUANTITY SOLD, AND SHOW INVENTORY STATUS OF 
-- PRODUCTS AS BELOW AS PER BELOW CONDITION:
	-- A.FOR ELECTRONICS AND COMPUTER CATEGORIES, 
		-- i.IF SALES TILL DATE IS ZERO THEN SHOW 'NO SALES IN PAST, GIVE DISCOUNT TO REDUCE INVENTORY',
        -- ii.IF INVENTORY QUANTITY IS LESS THAN 10% OF QUANTITY SOLD, SHOW 'LOW INVENTORY, NEED TO ADD INVENTORY', 
        -- iii.IF INVENTORY QUANTITY IS LESS THAN 50% OF QUANTITY SOLD, SHOW 'MEDIUM INVENTORY, NEED TO ADD SOME INVENTORY', 
        -- iv.IF INVENTORY QUANTITY IS MORE OR EQUAL TO 50% OF QUANTITY SOLD, SHOW 'SUFFICIENT INVENTORY'
	-- B.FOR MOBILES AND WATCHES CATEGORIES, 
		-- i.IF SALES TILL DATE IS ZERO THEN SHOW 'NO SALES IN PAST, GIVE DISCOUNT TO REDUCE INVENTORY', 
        -- ii.IF INVENTORY QUANTITY IS LESS THAN 20% OF QUANTITY SOLD, SHOW 'LOW INVENTORY, NEED TO ADD INVENTORY',  
        -- iii.IF INVENTORY QUANTITY IS LESS THAN 60% OF QUANTITY SOLD, SHOW 'MEDIUM INVENTORY, NEED TO ADD SOME INVENTORY', 
        -- iv.IF INVENTORY QUANTITY IS MORE OR EQUAL TO 60% OF QUANTITY SOLD, SHOW 'SUFFICIENT INVENTORY'
	-- C.REST OF THE CATEGORIES, 
		-- i.IF SALES TILL DATE IS ZERO THEN SHOW 'NO SALES IN PAST, GIVE DISCOUNT TO REDUCE INVENTORY', 
        -- ii.IF INVENTORY QUANTITY IS LESS THAN 30% OF QUANTITY SOLD, SHOW 'LOW INVENTORY, NEED TO ADD INVENTORY',  
        -- iii.IF INVENTORY QUANTITY IS LESS THAN 70% OF QUANTITY SOLD, SHOW 'MEDIUM INVENTORY, NEED TO ADD SOME INVENTORY', 
        -- iv. IF INVENTORY QUANTITY IS MORE OR EQUAL TO 70% OF QUANTITY SOLD, SHOW 'SUFFICIENT INVENTORY'
        
			-- [NOTE: TABLES TO BE USED -PRODUCT, PRODUCT_CLASS, ORDER_ITEMS] (USE SUB-QUERY)

SELECT P.product_id, P.product_desc, P.product_quantity_avail, SUM(OI.product_quantity) AS QUANTITY_SOLD,
CASE
	WHEN PC.product_class_desc IN ('Electronics', 'Computer') THEN
		CASE
			WHEN SUM(OI.product_quantity) = 0 THEN 'NO SALES IN PAST, GIVE DISCOUNT TO REDUCE INVENTORY'
			WHEN P.product_quantity_avail < 0.1 * SUM(OI.product_quantity) THEN 'LOW INVENTORY, NEED TO ADD INVENTORY'
			WHEN P.product_quantity_avail < 0.5 * SUM(OI.product_quantity) THEN 'MEDIUM INVENTORY, NEED TO ADD SOME INVENTORY'
			ELSE 'SUFFICIENT INVENTORY'
		END
	WHEN PC.product_class_desc IN ('Mobiles', 'Watches') THEN
		CASE
			WHEN SUM(OI.product_quantity) = 0 THEN 'NO SALES IN PAST, GIVE DISCOUNT TO REDUCE INVENTORY'
			WHEN P.product_quantity_avail < 0.2 * SUM(OI.product_quantity) THEN 'LOW INVENTORY, NEED TO ADD INVENTORY'
			WHEN P.product_quantity_avail < 0.6 * SUM(OI.product_quantity) THEN 'MEDIUM INVENTORY, NEED TO ADD SOME INVENTORY'
			ELSE 'SUFFICIENT INVENTORY'
		END
	ELSE
		CASE
			WHEN SUM(OI.product_quantity) = 0 THEN 'NO SALES IN PAST, GIVE DISCOUNT TO REDUCE INVENTORY'
			WHEN P.product_quantity_avail < 0.3 * SUM(OI.product_quantity) THEN 'LOW INVENTORY, NEED TO ADD INVENTORY'
			WHEN P.product_quantity_avail < 0.7 * SUM(OI.product_quantity) THEN 'MEDIUM INVENTORY, NEED TO ADD SOME INVENTORY'
			ELSE 'SUFFICIENT INVENTORY'
		END
END AS INVENTORY_STATUS
FROM product P
JOIN product_class PC ON P.product_class_code = PC.product_class_code
LEFT JOIN order_items OI ON P.product_id = OI.product_id
GROUP BY P.product_id, P.product_desc, P.product_quantity_avail, PC.product_class_desc;
    
-- 9. WRITE A QUERY TO DISPLAY PRODUCT_ID, PRODUCT_DESC AND TOTAL QUANTITY OF PRODUCTS WHICH ARE SOLD TOGETHER WITH PRODUCT ID 201 
-- AND ARE NOT SHIPPED TO CITY BANGALORE AND NEW DELHI. DISPLAY THE OUTPUT IN DESCENDING ORDER WITH RESPECT TO TOT_QTY.(USE SUB-QUERY)
	-- [NOTE: TABLES TO BE USED -ORDER_ITEMS,PRODUCT,ORDER_HEADER, ONLINE_CUSTOMER, ADDRESS]
    
Select O.product_id,P.product_desc,
SUM(O.product_quantity) AS tot_qty
from order_items O
inner join order_header OH on O.order_id = OH.order_id
inner join product P on O.product_id = P.product_id
where O.order_id IN(
               select distinct O2.order_id from order_items O2 where O2.product_id =201
               )
and OH.customer_id IN(
              select OC.customer_id 
              from online_customer OC 
              join address A1 on OC.address_id = A1.address_id
              where A1.CITY NOT IN ('Bangalore', 'New Delhi')
              )
group by O.product_id,P.product_desc
order by tot_qty desc; 

-- 10. WRITE A QUERY TO DISPLAY THE ORDER_ID,CUSTOMER_ID AND CUSTOMER FULLNAME AND TOTAL QUANTITY OF PRODUCTS SHIPPED FOR ORDER IDS 
-- WHICH ARE EVEN AND SHIPPED TO ADDRESS WHERE PINCODE IS NOT STARTING WITH "5" 
	-- [NOTE: TABLES TO BE USED - ONLINE_CUSTOMER,ORDER_HEADER, ORDER_ITEMS, ADDRESS]

select o.order_id,oc.customer_id,concat(oc.customer_fname,' ',customer_lname) as
full_name,sum(o.product_quantity) as Total_quantity
from order_items o
inner join order_header oh
using (order_id)
inner join online_customer oc
using (customer_id)
inner join address a
using (address_id)
where order_id%2=0 and pincode not like '5%'
group by order_id;
