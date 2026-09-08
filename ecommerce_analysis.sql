USE Ecommerce_Analytics;

SELECT COUNT(*) AS Total_Rows
FROM dbo.online_retail_sales;

SELECT TOP 10 *
FROM dbo.online_retail_sales;

-- Check missing values
SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END) AS Missing_InvoiceNo,
    SUM(CASE WHEN StockCode IS NULL THEN 1 ELSE 0 END) AS Missing_StockCode,
    SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END) AS Missing_Description,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Missing_Quantity,
    SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS Missing_InvoiceDate,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS Missing_UnitPrice,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Missing_CustomerID,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS Missing_Country
FROM dbo.online_retail_sales;

-- Check for exact duplicate transactions

SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    Is_Cancelled,
    Sales_Amount,
    COUNT(*) AS Duplicate_Count
FROM dbo.online_retail_sales
GROUP BY
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    Is_Cancelled,
    Sales_Amount
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;

SELECT
    Is_Cancelled,
    COUNT(*) AS Total_Rows,
    SUM(Sales_Amount) AS Total_Sales
FROM dbo.online_retail_sales
GROUP BY Is_Cancelled
ORDER BY Is_Cancelled;

SELECT
    Is_Cancelled,
    COUNT(*) AS Total_Rows,
    SUM(Sales_Amount) AS Total_Sales
FROM dbo.online_retail_sales
GROUP BY Is_Cancelled
ORDER BY Is_Cancelled;

SELECT
    MIN(InvoiceDate) AS Min_Date,
    MAX(InvoiceDate) AS Max_Date,
    MIN(Quantity) AS Min_Quantity,
    MAX(Quantity) AS Max_Quantity,
    MIN(UnitPrice) AS Min_UnitPrice,
    MAX(UnitPrice) AS Max_UnitPrice
FROM dbo.online_retail_sales;

-- Check extreme quantities
SELECT TOP 20
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    Sales_Amount
FROM dbo.online_retail_sales
ORDER BY Quantity DESC;

-- Check zero-price transactions
SELECT
    COUNT(*) AS Zero_Price_Rows,
    SUM(Quantity) AS Zero_Price_Quantity
FROM dbo.online_retail_sales
WHERE UnitPrice = 0;

SELECT *
FROM dbo.online_retail_sales
WHERE Quantity = 80995;

SELECT *
FROM dbo.online_retail_sales
WHERE UnitPrice = 0;

--SELECT *
--FROM dbo.online_retail_sales
--WHERE UnitPrice > 0;

-- Check cancelled transactions
SELECT
    Is_Cancelled,
    COUNT(*) AS Total_Rows,
    SUM(Quantity) AS Total_Quantity,
    SUM(Sales_Amount) AS Total_Sales
FROM dbo.online_retail_sales
GROUP BY Is_Cancelled
ORDER BY Is_Cancelled;

SELECT
    COUNT(DISTINCT CustomerID) AS Unique_Customers,
    COUNT(*) AS Total_Transactions
FROM dbo.online_retail_sales
WHERE CustomerID IS NOT NULL;

SELECT
    Country,
    COUNT(*) AS Total_Transactions,
    COUNT(DISTINCT CustomerID) AS Unique_Customers,
    SUM(Sales_Amount) AS Total_Sales
FROM dbo.online_retail_sales
GROUP BY Country
ORDER BY Total_Sales DESC;

SELECT
    YEAR(InvoiceDate) AS Year,
    MONTH(InvoiceDate) AS Month,
    COUNT(*) AS Total_Transactions,
    SUM(Sales_Amount) AS Total_Sales
FROM dbo.online_retail_sales
WHERE Is_Cancelled = 0
GROUP BY
    YEAR(InvoiceDate),
    MONTH(InvoiceDate)
ORDER BY
    Year,
    Month;

-- Top 10 products by quantity sold

SELECT TOP 10
    StockCode,
    Description,
    SUM(Quantity) AS Total_Quantity,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    SUM(Sales_Amount) AS Total_Sales
FROM dbo.online_retail_sales
WHERE Is_Cancelled = 0
  AND UnitPrice > 0
GROUP BY
    StockCode,
    Description
ORDER BY
    Total_Quantity DESC;

-- Top 10 Customers by Revenue

SELECT TOP 10
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    SUM(Quantity) AS Total_Quantity,
    SUM(Sales_Amount) AS Total_Sales
FROM dbo.online_retail_sales
WHERE Is_Cancelled = 0
  AND UnitPrice > 0
  AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY Total_Sales DESC;

-- Average Order Value (AOV)

SELECT
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Sales_Amount) / COUNT(DISTINCT InvoiceNo) AS Average_Order_Value
FROM dbo.online_retail_sales
WHERE Is_Cancelled = 0
  AND UnitPrice > 0;

-- Repeat Customers vs One-Time Customers

WITH CustomerOrders AS
(
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS Total_Orders
    FROM dbo.online_retail_sales
    WHERE Is_Cancelled = 0
      AND UnitPrice > 0
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT
    CASE
        WHEN Total_Orders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS Customer_Type,
    COUNT(*) AS Number_of_Customers
FROM CustomerOrders
GROUP BY
    CASE
        WHEN Total_Orders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END
ORDER BY Number_of_Customers DESC;

-- RFM Analysis

SELECT
    CustomerID,

    -- Recency: Last purchase date
    MAX(InvoiceDate) AS Last_Purchase_Date,

    -- Frequency: Number of unique orders
    COUNT(DISTINCT InvoiceNo) AS Frequency,

    -- Monetary: Total amount spent
    SUM(Sales_Amount) AS Monetary_Value

FROM dbo.online_retail_sales
WHERE Is_Cancelled = 0
    AND UnitPrice > 0
    AND CustomerID IS NOT NULL

GROUP BY CustomerID

ORDER BY Monetary_Value DESC;

-- RFM Scoring

WITH RFM AS
(
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS Last_Purchase_Date,
        COUNT(DISTINCT InvoiceNo) AS Frequency,
        SUM(Sales_Amount) AS Monetary_Value
    FROM dbo.online_retail_sales
    WHERE Is_Cancelled = 0
        AND UnitPrice > 0
        AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),

ReferenceDate AS
(
    SELECT MAX(InvoiceDate) AS Max_Date
    FROM dbo.online_retail_sales
    WHERE Is_Cancelled = 0
        AND UnitPrice > 0
)

SELECT
    CustomerID,

    DATEDIFF(DAY, Last_Purchase_Date, Max_Date) AS Recency,

    Frequency,
    Monetary_Value,

    -- Recency Score
    NTILE(5) OVER (
        ORDER BY DATEDIFF(DAY, Last_Purchase_Date, Max_Date) DESC
    ) AS R_Score,

    -- Frequency Score
    NTILE(5) OVER (
        ORDER BY Frequency
    ) AS F_Score,

    -- Monetary Score
    NTILE(5) OVER (
        ORDER BY Monetary_Value
    ) AS M_Score

FROM RFM
CROSS JOIN ReferenceDate;

-- Final RFM Customer Segmentation

WITH RFM AS
(
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS Last_Purchase_Date,
        COUNT(DISTINCT InvoiceNo) AS Frequency,
        SUM(Sales_Amount) AS Monetary_Value
    FROM dbo.online_retail_sales
    WHERE Is_Cancelled = 0
        AND UnitPrice > 0
        AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),

ReferenceDate AS
(
    SELECT MAX(InvoiceDate) AS Max_Date
    FROM dbo.online_retail_sales
    WHERE Is_Cancelled = 0
        AND UnitPrice > 0
),

RFM_Scored AS
(
    SELECT
        CustomerID,

        DATEDIFF(DAY, Last_Purchase_Date, Max_Date) AS Recency,

        Frequency,
        Monetary_Value,

        NTILE(5) OVER (
            ORDER BY DATEDIFF(DAY, Last_Purchase_Date, Max_Date) DESC
        ) AS R_Score,

        NTILE(5) OVER (
            ORDER BY Frequency
        ) AS F_Score,

        NTILE(5) OVER (
            ORDER BY Monetary_Value
        ) AS M_Score

    FROM RFM
    CROSS JOIN ReferenceDate
)

SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary_Value,
    R_Score,
    F_Score,
    M_Score,

    CONCAT(R_Score, F_Score, M_Score) AS RFM_Score,

    CASE
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4
            THEN 'Champions'

        WHEN R_Score >= 3 AND F_Score >= 4
            THEN 'Loyal Customers'

        WHEN R_Score >= 4 AND F_Score BETWEEN 2 AND 3
            THEN 'Potential Loyalists'

        WHEN R_Score <= 2 AND F_Score >= 4
            THEN 'At Risk'

        WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score >= 3
            THEN 'Need Attention'

        WHEN R_Score = 1 AND F_Score = 1
            THEN 'Lost Customers'

        ELSE 'Others'
    END AS Customer_Segment

FROM RFM_Scored
ORDER BY Monetary_Value DESC;

-- Final RFM Segment Summary

WITH RFM AS
(
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS Last_Purchase_Date,
        COUNT(DISTINCT InvoiceNo) AS Frequency,
        SUM(Sales_Amount) AS Monetary_Value
    FROM dbo.online_retail_sales
    WHERE Is_Cancelled = 0
        AND UnitPrice > 0
        AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),

ReferenceDate AS
(
    SELECT MAX(InvoiceDate) AS Max_Date
    FROM dbo.online_retail_sales
    WHERE Is_Cancelled = 0
        AND UnitPrice > 0
),

RFM_Scored AS
(
    SELECT
        CustomerID,
        DATEDIFF(DAY, Last_Purchase_Date, Max_Date) AS Recency,
        Frequency,
        Monetary_Value,

        NTILE(5) OVER (
            ORDER BY DATEDIFF(DAY, Last_Purchase_Date, Max_Date) DESC
        ) AS R_Score,

        NTILE(5) OVER (
            ORDER BY Frequency
        ) AS F_Score,

        NTILE(5) OVER (
            ORDER BY Monetary_Value
        ) AS M_Score

    FROM RFM
    CROSS JOIN ReferenceDate
),

Segmented AS
(
    SELECT
        CustomerID,
        Frequency,
        Monetary_Value,
        R_Score,
        F_Score,
        M_Score,

        CASE
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4
                THEN 'Champions'

            WHEN R_Score >= 3 AND F_Score >= 4
                THEN 'Loyal Customers'

            WHEN R_Score >= 4 AND F_Score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'

            WHEN R_Score <= 2 AND F_Score >= 4
                THEN 'At Risk'

            WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score >= 3
                THEN 'Need Attention'

            WHEN R_Score = 1 AND F_Score = 1
                THEN 'Lost Customers'

            ELSE 'Others'
        END AS Customer_Segment

    FROM RFM_Scored
)

SELECT
    Customer_Segment,
    COUNT(*) AS Number_of_Customers,
    SUM(Frequency) AS Total_Orders,
    SUM(Monetary_Value) AS Total_Revenue,
    AVG(Monetary_Value) AS Average_Customer_Value
FROM Segmented
GROUP BY Customer_Segment
ORDER BY Total_Revenue DESC;
