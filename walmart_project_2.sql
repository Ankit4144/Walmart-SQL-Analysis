select * from walmartsales_sql;
-- Alter the column to TIME
ALTER TABLE walmartsales_sql
MODIFY COLUMN Time TIME;

-- Update the column with only the time part
UPDATE walmartsales_sql
SET Time = TIME(Time);

-- cogs to cost
ALTER TABLE walmartsales_sql
RENAME COLUMN cogs TO cost;

update walmartsales_sql
set Date= str_to_date(Date, '%d-%m-%Y');
alter table walmartsales_sql
modify column Date date;


# Task 1: Identifying the Top Branch by Sales Growth Rate

with Total_M_Sales as
(
select Branch, Month(Date) as D_M, round(sum(Total),2) as Monthly_Sales
from walmartsales_sql
group by Branch, D_M
),
Sales_Growth as
(
select *,
lag(Monthly_Sales) over(partition by Branch order by D_M) as Previous_M_Sale
from Total_M_Sales
),
Growth_R_Cal as
(
select *,
round(((Monthly_Sales - Previous_M_Sale)/Previous_M_Sale)*100,2) as Growth_Rate
from Sales_Growth
where Previous_M_Sale is not null
)
select * from Growth_R_Cal
order by Growth_Rate desc
limit 1;


# Task 2: Finding the Most Profitable Product Line for Each Branch 
ALTER TABLE walmartsales_sql
CHANGE `Product line` `product_line` VARCHAR(100);

with Cal_Profit as 
(
select Branch, Product_line, round(sum(`gross income`),2) as Gross_Profit
from walmartsales_sql
group by Branch, product_line
),
Rank_Profitability as
(
select Branch, Product_line, Gross_Profit,
dense_rank() over(partition by Branch order by Gross_Profit desc) as Rank_P
from Cal_Profit 
)
select * from Rank_Profitability
where Rank_P = 1 
order by Rank_P 
;

select round(avg(Total),2) as Avg_spending from walmartsales_sql;


# Task 3: Analyzing Customer Segmentation Based on Spending 

with Avg_Spend as  
(
select `Customer ID`, round(Avg(Total),2) as Avg_Spending_per_cust
from walmartsales_sql group by `Customer ID`
)
select `Customer ID`,Avg_Spending_per_cust,
case 
when Avg_Spending_per_cust >= 340 then 'High Spender'
when Avg_Spending_per_cust between 300 and 340 then 'Medium Spender'
else 'Low Spender'
end as Spending_Level
from Avg_Spend
order by Avg_Spending_per_cust desc;


# Task 4: Detecting Anomalies in Sales Transactions 

with productline_avg as 
(
select `Invoice ID`, product_line, Total,
round(Avg(Total) over(partition by product_line),2) as Avg_Pline_Sale
from walmartsales_sql
)
select `Invoice ID`, product_line, Total, Avg_Pline_Sale,
case
when Total > Avg_Pline_Sale*1.5 then 'High Anomaly'
when Total < Avg_Pline_Sale*0.5 then 'Low Anomaly'
else 'No Anomaly'
end as Anomalies
from productline_avg;


# Task 5: Most Popular Payment Method by City 

	with Count_Payment as 
	(
	select City, Payment, count(Payment) as Payments_Done
	from walmartsales_sql
	group by City, Payment
	)
	select * ,
	rank() over(partition by City order by Payments_Done desc) as Rank_by_City 
	from Count_Payment;
    

# Task 6: Monthly Sales Distribution by Gender 

with Monthly_Sales as
(
select Gender, monthname(Date) as Month, month(Date) as Month_Num, round(sum(Total),2) as T_Sales
from walmartsales_sql
group by Gender, Month, Month_num
)
select Gender, Month_Num, T_Sales
from Monthly_Sales order by Month_Num;


# Task 7: Best Product Line by Customer Type

with Best_P_line as
(
select `Customer type`, product_line, round(sum(Total),2) as Total_Sales, 
round(sum(`Gross income`),2) as Total_Profit
from walmartsales_sql
group by `Customer type`, product_line
)
select *, rank() over(partition by `Customer type` order by Total_Profit desc) as Rank_Profitability
from Best_P_line;


# Task 8: Identifying Repeat Customers

with Cust_P_Count as
(
select `Customer ID`, Date, count(`Invoice ID`) as No_of_Purchase
from walmartsales_sql
group by `Customer ID`,Date
),
Repeat_cust as
(
select *,lag(Date) over(partition by `Customer ID` order by Date) as Previous_Purchase
from Cust_P_Count
),
Date_Diff as
(
select *, datediff(Date, Previous_Purchase) as Gap_in_Next_Purchase
from Repeat_cust
)
select * from Date_Diff where Gap_in_Next_Purchase <=30
order by No_of_Purchase desc;


# Task 9: Finding Top 5 Customers by Sales Volume 

With S_Vol as
(
select `Customer ID`, round(sum(Total),2) as Sales_Volume
from walmartsales_sql
group by `Customer ID`
)
select * ,
row_number() over(order by Sales_Volume desc ) as Top_5
from S_Vol
limit 5;


# Task 10: Analyzing Sales Trends by Day of the Week

select Dayname(Date) as Day_Name, round(Sum(Total),2) as T_Sales,
case
when Sum(Total)>=50000 then 'High'
when Sum(Total)>=42000 then 'Average'
else 'Low'
end as Sales_Category
from walmartsales_sql
group by Day_Name
order by T_Sales desc;