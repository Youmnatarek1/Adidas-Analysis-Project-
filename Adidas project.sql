--read data
select *
from dbo.[Adidas_Sales_ANSI]; 
---------------------------------------Explore data-------------------------------------------------------
--Data contains 52 city
SELECT DISTINCT City
FROM dbo.[Adidas_Sales_ANSI];
--Data contains 5 Regions
SELECT DISTINCT Region
FROM dbo.[Adidas_Sales_ANSI];
--Data contains 50 States 
SELECT DISTINCT State
FROM dbo.[Adidas_Sales_ANSI];
--Data contains 3 Sales methods(Online, outlet and In-store) 
SELECT DISTINCT [Sales Method]
FROM dbo.[Adidas_Sales_ANSI];
--1)Total sales
ALTER TABLE dbo.[Adidas_Sales_ANSI]
ADD 
    Total_Sales AS ([Units Sold]*[Price Per Unit]);

--change dtype of unit sold & price per unit
ALTER TABLE Adidas_Sales_ANSI
ALTER COLUMN [Units Sold] FLOAT;

ALTER TABLE Adidas_Sales_ANSI
ALTER COLUMN [Price per Unit] FLOAT;

ALTER TABLE Adidas_Sales_ANSI
ALTER COLUMN [Operating Margin] FLOAT;
--------------------------------------[1]Sales Performance Insights--------------------------------------------------------  
--1)Top 10 Products of highest sales
Select top 10 product, SUM(Total_Sales) AS Total_Sales
From dbo.[Adidas_Sales_ANSI]
GROUP BY product
Order by Total_Sales DESC;

--2)Highest Sales Performance Region 
Select top 1 Region , SUM(Total_Sales) AS Total_Sales
FROM dbo.[Adidas_Sales_ANSI]
GROUP BY Region
Order By Total_Sales DESC;

--3)Lowest Sales Performance Region
Select top 1 Region , SUM(Total_Sales) AS Total_Sales
FROM dbo.[Adidas_Sales_ANSI]
GROUP BY Region
Order By Total_Sales ASC;

--4)Monthly Sales trend over Time
SELECT MONTH([Invoice Date]) AS Month,SUM(Total_Sales) AS Total_Sales
FROM dbo.[Adidas_Sales_ANSI]
GROUP BY MONTH([Invoice Date])
ORDER BY Month;

--5)Year that acheives the peak sales 
Select YEAR([Invoice Date]) AS Year, SUM(Total_Sales) AS Total_Sales
FROM dbo.[Adidas_Sales_ANSI]
Group By YEAR([Invoice Date])
Order By Total_Sales DESC;

--6)Month that acheives the peak sales 
Select Month([Invoice Date]) AS Month, SUM(Total_Sales) AS Total_Sales
From dbo.[Adidas_Sales_ANSI]
Group By Month([Invoice Date])
Order By Total_Sales DESC;

--Merge month & year together
SELECT 
    YEAR([Invoice Date]) AS Year,
    DATENAME(MONTH, [Invoice Date]) AS Month,
    SUM(Total_Sales) AS Total_Sales
FROM dbo.[Adidas_Sales_ANSI]
GROUP BY 
    YEAR([Invoice Date]),
    DATENAME(MONTH, [Invoice Date]);

--7)% of total sales that each region contributes
SELECT 
    Region, SUM(Total_Sales) AS Total_Sales,
    PERCENT_RANK() OVER (ORDER BY SUM(Total_Sales) DESC) AS Percentage_of_region_contribution
FROM dbo.[Adidas_Sales_ANSI]
GROUP BY Region;

---
SELECT 
    Region,
    SUM(Total_Sales) AS Region_Sales,
    SUM(Total_Sales) * 100.0 /
    SUM(SUM(Total_Sales)) OVER () AS Sales_Percentage
FROM dbo.[Adidas_Sales_ANSI]
GROUP BY Region;
--------------------------------------[2]Profitability Insights--------------------------------------------------------  
--1)products generate the highest operating profit
SELECT PRODUCT , SUM ([Total_Sales]*[Operating Margin]) AS Operating_Profit
FROM dbo.[Adidas_Sales_ANSI]
Group By PRODUCT
Order By Operating_Profit DESC;

--2)Region that has the best Operating Margin
SELECT TOP 1 Region,  AVG([Operating Margin]) AS Average_Margin
FROM dbo.[Adidas_Sales_ANSI]
GROUP BY Region
Order By Average_Margin DESC;

--3)High Sales always associated with high Profit
SELECT Product, SUM([Total_Sales]) AS [Total_Sales]
,SUM ([Total_Sales]*[Operating Margin]) AS Operating_Profit
FROM dbo.[Adidas_Sales_ANSI]
Group By Product

--4)products have high revenue but low profitability?
SELECT Product, SUM([Price per Unit]*[Units Sold]) AS Total_Revenue
,SUM ([Total_Sales]*[Operating Margin]) AS Operating_Profit,
(SUM([Total_Sales]*[Operating Margin]) / SUM([Total_Sales])) * 100 AS Profit_Margin
FROM [Adidas_Sales_ANSI]
Group By Product
Order By Total_Revenue DESC,Profit_Margin ASC;

--5)Which retailers contribute most to total profit?
Select Retailer, SUM([Total_Sales]*[Operating Margin]) AS Total_Profit
From [Adidas_Sales_ANSI]
Group By Retailer
Order By Total_Profit DESC;

----------------------------------------[3]Product & Customer Behavior------------------------------------------------
--1) Which product category sells the most units >> Men's Street Footwear
Select Product, SUM([Units Sold]) AS Total_Units_Sold
From [Adidas_Sales_ANSI]
Group By Product
Order By Total_Units_Sold  DESC;

--2)Sales Method generates the highest revenue >> Online
Select [Sales Method], SUM([Price per Unit]*[Units Sold]) AS Total_Revenue
From [Adidas_Sales_ANSI]
Group By [Sales Method]
Order By Total_Revenue DESC;

--3)Which products perform best in each region

SELECT *
FROM (
    SELECT Region,Product,SUM(Total_Sales) AS Total_Revenue,
        RANK() OVER(PARTITION BY Region ORDER BY SUM(Total_Sales) DESC) AS Rank_in_region
    FROM Adidas_Sales_ANSI
    GROUP BY Region, Product
) t
WHERE Rank_in_region = 1;
--4)Are some products dependent on specific regions
Select PRODUCT, Region, SUM([Units Sold]) AS Total_Unit_Sold, SUM(Total_Sales) AS Total_Revenue
From [Adidas_Sales_ANSI]
Group By Product,Region
Order By Total_Revenue, Total_Unit_Sold DESC;

-----------------------------------------------------[4]Time Based Analysis---------------------------------------------------------
--1)How do sales vary by quarter
Select DATEPART(QUARTER, [Invoice Date]) AS Quarter, SUM(Total_Sales) AS Total_Sales
From [Adidas_Sales_ANSI]
Group By DATEPART(QUARTER, [Invoice Date]) 
Order By Total_Sales DESC;

--2) What is the growth rate month over month >> In 2021 :Jan has 598% (Huge growth) ,while June 2020: down -49.91% (huge drop)
WITH MonthlyRevenue AS (
    SELECT YEAR([Invoice Date]) AS Year, MONTH([Invoice Date]) AS Month, SUM([Total_Sales]) AS Revenue
    FROM dbo.[Adidas_Sales_ANSI]
    GROUP BY YEAR([Invoice Date]), MONTH([Invoice Date])
)
SELECT 
    Year,Month,Revenue,
    LAG(Revenue) OVER (ORDER BY Year, Month) AS Previous_Month_Revenue,
    (Revenue - LAG(Revenue) OVER (ORDER BY Year, Month)) * 100.0 / LAG(Revenue) OVER (ORDER BY Year, Month) AS MoM_Growth_Percent
FROM MonthlyRevenue
ORDER BY Year, Month;

--3)Which season shows the highest demand
SELECT 
    CASE 
        WHEN MONTH([Invoice Date]) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH([Invoice Date]) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH([Invoice Date]) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH([Invoice Date]) IN (9, 10, 11) THEN 'Fall'
    END AS Season, SUM([Total_Sales]) AS Total_Revenue
FROM dbo.[Adidas_Sales_ANSI]
GROUP BY 
    CASE 
        WHEN MONTH([Invoice Date]) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH([Invoice Date]) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH([Invoice Date]) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH([Invoice Date]) IN (9, 10, 11) THEN 'Fall'
    END
ORDER BY Total_Revenue DESC;

-------------------------------------------------[5]Retailer Performance------------------------------------------------------------
--1)Which retailer has the highest average sales per transaction	>> Walmart 
Select Retailer, AVG([Total_Sales]) AS AVG_Total_Sales
From [Adidas_Sales_ANSI]
Group By Retailer
Order By AVG_Total_Sales DESC;

--2)Which retailer sells the widest variety of products >> There is no variety bet retailers
Select Retailer, COUNT(DISTINCT PRODUCT) AS Product_Variety, SUM([Total_Sales]) AS Total_Sales
From [Adidas_Sales_ANSI]
Group By Retailer
Order By Product_Variety,Total_Sales DESC;

--3)Which retailer underperforms compared to others in the same region
SELECT Retailer, Region, SUM([Total_Sales]) AS Total_Sales,
    RANK() OVER (PARTITION BY Region ORDER BY SUM([Total_Sales]) ASC) AS RankInRegion
FROM [Adidas_Sales_ANSI]
GROUP BY Retailer, Region
ORDER BY Region ASC, RankInRegion ASC;