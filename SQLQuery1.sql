USE [Sales Store] ; 
SELECT * FROM dbo.['stores data-set$'];
SELECT * FROM dbo.['Features data set$'] ;
SELECT * FROM dbo.['sales data-set$']
;

-- How many stores in the data --
SELECT COUNT(DISTINCT dbo.['stores data-set$'].Store) AS Total_Stores
FROM dbo.['stores data-set$'] ; 
-- 45 Stores

-- Total Sales for each Store DESCENDING--
SELECT dbo.['sales data-set$'].Store,
SUM(dbo.['sales data-set$'].Weekly_Sales) AS Total_Sales
FROM dbo.['sales data-set$']
GROUP BY dbo.['sales data-set$'].Store
ORDER BY 2 DESC  ;
-- Store num 20 is the most selled store for the years 2010-2012

-- How many Departments for each Store --
SELECT  s.Store,
COUNT(Distinct s.Dept)  AS Total_dep 
FROM dbo.['sales data-set$'] s
GROUP BY s.Store
ORDER BY 1
;

-- Total Sales for each department in each Store--
SELECT s.Store,
s.Dept,
SUM(s.Weekly_Sales) AS Total_Sales 
FROM dbo.['sales data-set$'] s
GROUP BY  s.Dept,s.Store
ORDER BY 1,3 DESC;

-- The most Selled Department in each store--
SELECT Store,Dept,Total_Sales 
FROM(
SELECT s.Store,
s.Dept,
SUM(s.Weekly_Sales) AS Total_Sales ,
DENSE_RANK() OVER(PARTITION BY Store Order BY SUM(s.Weekly_Sales) DESC) AS rk
FROM dbo.['sales data-set$'] s
GROUP BY  s.Dept,s.Store
)a
WHERE rk= 1 

--Checking for not profitable departments in each Store --
SELECT Store, Dept, Total_Sales 
FROM
(
SELECT s.Store,
s.Dept,
SUM(s.Weekly_Sales) AS Total_Sales 
FROM dbo.['sales data-set$'] s
GROUP BY  s.Dept,s.Store
--ORDER BY 1,3 DESC
)a 
WHERE Total_Sales < 0 
ORDER BY 1,3,2 

--The most losing Department in each Store--
SELECT Store,Dept,Total_Sales 
FROM(
SELECT Store,Dept,Total_Sales ,
DENSE_RANK() OVER(PARTITION BY Store ORDER BY Total_Sales) AS rk
FROM(
SELECT Store, Dept, Total_Sales
FROM
(
SELECT s.Store,
s.Dept,
SUM(s.Weekly_Sales) AS Total_Sales 
FROM dbo.['sales data-set$'] s
GROUP BY  s.Dept,s.Store
--ORDER BY 1,3 DESC
)a 
WHERE Total_Sales < 0 
--ORDER BY 1,3,2 
)a
)b
WHERE rk = 1
ORDER BY 1 ;

--Checking for each week if its higher or less than  Average Weekly Sales--
SELECT Date,a.Store,Total_Sales,Average_Sales_per_week,
CASE 
WHEN Total_Sales > Average_Sales_per_week THEN 'Higher Than Average'
ELSE 'Less than Average'
END AS Different
FROM
(
SELECT dbo.['sales data-set$'].Store,
SUM(dbo.['sales data-set$'].Weekly_Sales)/143 AS Average_Sales_per_week
FROM dbo.['sales data-set$']
GROUP BY dbo.['sales data-set$'].Store
--ORDER BY 1 
)a
JOIN
(
SELECT Date, dbo.['sales data-set$'].Store,
SUM(dbo.['sales data-set$'].Weekly_Sales) AS Total_Sales
FROM dbo.['sales data-set$']
GROUP BY dbo.['sales data-set$'].Store,dbo.['sales data-set$'].Date 
--ORDER BY 2,1
)b
ON a.Store=b.Store
ORDER BY 2,1 

--Checking if in the holidays week sales were higher or lower than the average weekly sales--
SELECT a.Date,a.Store,a.Total_Sales,b.Average_Sales_per_week,
CASE WHEN a.Total_Sales > b.Average_Sales_per_week THEN 'Higher Than Average'
ELSE 'Less Than Average' 
END AS Holiday_indicator
FROM
(
SELECT Date,
dbo.['sales data-set$'].Store,
SUM(dbo.['sales data-set$'].Weekly_Sales) AS Total_Sales
FROM dbo.['sales data-set$']
WHERE Date IN (SELECT Date FROM dbo.['sales data-set$'] WHERE IsHoliday = 1)
GROUP BY dbo.['sales data-set$'].Store,Date 
--ORDER BY 2,1
) a
JOIN
(
SELECT dbo.['sales data-set$'].Store,
SUM(dbo.['sales data-set$'].Weekly_Sales) / 143 AS Average_Sales_per_week
FROM dbo.['sales data-set$']
GROUP BY dbo.['sales data-set$'].Store
)b
ON a.Store=b.Store
ORDER BY 2,1

/*
450 Total Holiday Weeks
Lets see How many holiday weeks sales were higher than the avrage week sales--
*/

SELECT COUNT(*) AS Total_higher_than_AVG_week 
FROM
(
SELECT a.Date,a.Store,a.Total_Sales,b.Average_Sales_per_week,
CASE
WHEN a.Total_Sales > b.Average_Sales_per_week THEN 'Higher Than Average'
ELSE 'Less Than Average' 
END AS Holiday_indicator
FROM
(
SELECT Date,
dbo.['sales data-set$'].Store,
SUM(dbo.['sales data-set$'].Weekly_Sales) AS Total_Sales
FROM dbo.['sales data-set$']
WHERE Date IN (SELECT Date FROM dbo.['sales data-set$'] WHERE IsHoliday = 1)
GROUP BY dbo.['sales data-set$'].Store,Date 
--ORDER BY 2,1
) a
JOIN
(
SELECT dbo.['sales data-set$'].Store,
SUM(dbo.['sales data-set$'].Weekly_Sales)/143 AS Average_Sales_per_week
FROM dbo.['sales data-set$']
GROUP BY dbo.['sales data-set$'].Store
)b
ON a.Store=b.Store
--ORDER BY 2,1 
)a
WHERE Holiday_indicator = 'Higher Than Average'
-- As we can see 54% from the holidays week were with sales that higher than the average weekly sales--


-- AVG Unemployment Rate for all the years--
SELECT  AVG(f.Unemployment) AS AVG_unemployment_rate 
FROM dbo.['Features data set$'] f

-- Insert the AVG unemployment rate in null values--
UPDATE dbo.['Features data set$'] 
SET Unemployment  = (SELECT  AVG(f.Unemployment) AS AVG_unemployment_rate 
FROM dbo.['Features data set$'] f)
WHERE Unemployment IS NULL;


-- Checking the Releation between AVG unemployment rate and total weekly sales for each year--
SELECT a.calendar_year,AVG_unemployment_rate,total_Sales 
FROM 
(
SELECT YEAR(f.Date) AS calendar_year,
AVG(f.Unemployment) AS AVG_unemployment_rate 
FROM dbo.['Features data set$'] f
WHERE YEAR(f.Date)  IN (SELECT DISTINCT YEAR(d.Date) FROM dbo.['sales data-set$'] d)
GROUP BY YEAR(f.Date) 
--ORDER BY 1 
)a
JOIN
(
SELECT YEAR(d.Date) AS calendar_year, 
SUM(d.Weekly_Sales) AS total_Sales 
FROM dbo.['sales data-set$'] d
GROUP BY YEAR(d.Date) 
)b
ON a.calendar_year = b.calendar_year 
ORDER BY 2 

/*
As we can see there is not negative releation between the two parameters. 
High unemployment rate doesnt affect necessarily on the sales.
In 2012 the AVG unemployment rate was the lowest but the sales were the lowest as well.
*/

-- Let's see if the is a releation between the AVG temperature and total weekly sales for each year--
SELECT a.calendar_year,AVG_temperature_rate,total_Sales 
FROM 
(
SELECT YEAR(f.Date) AS calendar_year,
AVG(f.Temperature) AS AVG_temperature_rate 
FROM dbo.['Features data set$'] f
WHERE YEAR(f.Date)  IN (SELECT DISTINCT YEAR(d.Date) FROM dbo.['sales data-set$'] d)
GROUP BY YEAR(f.Date) 
--ORDER BY 1 
)a
JOIN
(
SELECT YEAR(d.Date) AS calendar_year, 
SUM(d.Weekly_Sales) AS total_Sales 
FROM dbo.['sales data-set$'] d
GROUP BY YEAR(d.Date) 
)b
ON a.calendar_year = b.calendar_year 
ORDER BY 2 

/*
As we can see from this table,when the temperature is lower the sales are higher thus we can assume that there is a negative releation
between the avg temperature and the total sales.
From the table we can see that the sales are going down when the temperature is rising.
*/


SELECT * FROM dbo.['stores data-set$'];
SELECT * FROM dbo.['Features data set$'] 

-- Check the change in the AVG Fuel price over the years
SELECT YEAR(f.Date) AS calenadr_Year,
AVG(f.Fuel_Price) AS AVG_Fuel_Price
FROM dbo.['Features data set$'] f
WHERE YEAR(f.Date)  IN (SELECT DISTINCT YEAR(d.Date) FROM dbo.['sales data-set$'] d)
GROUP BY YEAR(f.Date) 

/*
We can see the price is constantly growing
*/
-- Let's the for the fuel the relation to the sales as well
SELECT a.calendar_year,AVG_Fuel_Price,total_Sales 
FROM 
(
SELECT YEAR(f.Date) AS calendar_year,
AVG(f.Fuel_Price) AS AVG_Fuel_Price 
FROM dbo.['Features data set$'] f
WHERE YEAR(f.Date)  IN (SELECT DISTINCT YEAR(d.Date) FROM dbo.['sales data-set$'] d)
GROUP BY YEAR(f.Date) 
--ORDER BY 1 
)a
JOIN
(
SELECT YEAR(d.Date) AS calendar_year, 
SUM(d.Weekly_Sales) AS total_Sales 
FROM dbo.['sales data-set$'] d
GROUP BY YEAR(d.Date) 
)b
ON a.calendar_year = b.calendar_year 
ORDER BY 2 
/*
We can see here a negative releation as well. 
When the Fuel price is rising the sales decreased.
*/