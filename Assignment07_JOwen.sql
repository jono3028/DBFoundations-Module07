--*************************************************************************--
-- Title: Assignment07
-- Author: JOwen
-- Desc: This file demonstrates how to use Functions
-- Change Log: When,Who,What
-- 2017-01-01,RRoot,Created File
-- 2022-05-31,JOwen,Completed Assignment
--**************************************************************************--
BEGIN TRY
    USE Master;
    IF Exists(SELECT Name FROM SysDatabases WHERE Name = 'Assignment07DB_JOwen')
        BEGIN
            ALTER DATABASE [Assignment07DB_JOwen] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
            DROP DATABASE Assignment07DB_JOwen;
        END
    CREATE DATABASE Assignment07DB_JOwen;
END TRY
BEGIN CATCH
    PRINT Error_Number();
END CATCH
GO
USE Assignment07DB_JOwen;

-- Create Tables (Module 01)-- 
CREATE TABLE Categories
(
    [CategoryID]   [int] IDENTITY (1,1) NOT NULL,
    [CategoryName] [nvarchar](100)      NOT NULL
);
GO

CREATE TABLE Products
(
    [ProductID]   [int] IDENTITY (1,1) NOT NULL,
    [ProductName] [nvarchar](100)      NOT NULL,
    [CategoryID]  [int]                NULL,
    [UnitPrice]   [money]              NOT NULL
);
GO

CREATE TABLE Employees -- New Table
(
    [EmployeeID]        [int] IDENTITY (1,1) NOT NULL,
    [EmployeeFirstName] [nvarchar](100)      NOT NULL,
    [EmployeeLastName]  [nvarchar](100)      NOT NULL,
    [ManagerID]         [int]                NULL
);
GO

CREATE TABLE Inventories
(
    [InventoryID]   [int] IDENTITY (1,1) NOT NULL,
    [InventoryDate] [Date]               NOT NULL,
    [EmployeeID]    [int]                NOT NULL,
    [ProductID]     [int]                NOT NULL,
    [ReorderLevel]  INT                  NOT NULL -- New Column
    ,
    [Count]         [int]                NOT NULL
);
GO

-- Add Constraints (Module 02) -- 
BEGIN
    -- Categories
    ALTER TABLE Categories
        ADD CONSTRAINT pkCategories
            PRIMARY KEY (CategoryId);

    ALTER TABLE Categories
        ADD CONSTRAINT ukCategories
            UNIQUE (CategoryName);
END
GO

BEGIN
    -- Products
    ALTER TABLE Products
        ADD CONSTRAINT pkProducts
            PRIMARY KEY (ProductId);

    ALTER TABLE Products
        ADD CONSTRAINT ukProducts
            UNIQUE (ProductName);

    ALTER TABLE Products
        ADD CONSTRAINT fkProductsToCategories
            FOREIGN KEY (CategoryId) REFERENCES Categories (CategoryId);

    ALTER TABLE Products
        ADD CONSTRAINT ckProductUnitPriceZeroOrHigher
            CHECK (UnitPrice >= 0);
END
GO

BEGIN
    -- Employees
    ALTER TABLE Employees
        ADD CONSTRAINT pkEmployees
            PRIMARY KEY (EmployeeId);

    ALTER TABLE Employees
        ADD CONSTRAINT fkEmployeesToEmployeesManager
            FOREIGN KEY (ManagerId) REFERENCES Employees (EmployeeId);
END
GO

BEGIN
    -- Inventories
    ALTER TABLE Inventories
        ADD CONSTRAINT pkInventories
            PRIMARY KEY (InventoryId);

    ALTER TABLE Inventories
        ADD CONSTRAINT dfInventoryDate
            DEFAULT GetDate() FOR InventoryDate;

    ALTER TABLE Inventories
        ADD CONSTRAINT fkInventoriesToProducts
            FOREIGN KEY (ProductId) REFERENCES Products (ProductId);

    ALTER TABLE Inventories
        ADD CONSTRAINT ckInventoryCountZeroOrHigher
            CHECK ([Count] >= 0);

    ALTER TABLE Inventories
        ADD CONSTRAINT fkInventoriesToEmployees
            FOREIGN KEY (EmployeeId) REFERENCES Employees (EmployeeId);
END
GO

-- Adding Data (Module 04) -- 
INSERT INTO Categories
    (CategoryName)
SELECT CategoryName
FROM Northwind.dbo.Categories
ORDER BY CategoryID;
GO

INSERT INTO Products
    (ProductName, CategoryID, UnitPrice)
SELECT ProductName, CategoryID, UnitPrice
FROM Northwind.dbo.Products
ORDER BY ProductID;
GO

INSERT INTO Employees
    (EmployeeFirstName, EmployeeLastName, ManagerID)
SELECT E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID)
FROM Northwind.dbo.Employees AS E
ORDER BY E.EmployeeID;
GO

INSERT INTO Inventories
    (InventoryDate, EmployeeID, ProductID, [Count], [ReorderLevel]) -- New column added this week
SELECT '20170101' AS InventoryDate, 5 AS EmployeeID, ProductID, UnitsInStock, ReorderLevel
FROM Northwind.dbo.Products
UNION
SELECT '20170201' AS InventoryDate,
       7          AS EmployeeID,
       ProductID,
       UnitsInStock + 10,
       ReorderLevel -- Using this is to create a made up value
FROM Northwind.dbo.Products
UNION
SELECT '20170301' AS InventoryDate,
       9          AS EmployeeID,
       ProductID,
       abs(UnitsInStock - 10),
       ReorderLevel -- Using this is to create a made up value
FROM Northwind.dbo.Products
ORDER BY 1, 2
GO


-- Adding Views (Module 06) -- 
CREATE VIEW vCategories WITH SCHEMABINDING
AS
SELECT CategoryID, CategoryName
FROM dbo.Categories;
GO
CREATE VIEW vProducts WITH SCHEMABINDING
AS
SELECT ProductID, ProductName, CategoryID, UnitPrice
FROM dbo.Products;
GO
CREATE VIEW vEmployees WITH SCHEMABINDING
AS
SELECT EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID
FROM dbo.Employees;
GO
CREATE VIEW vInventories WITH SCHEMABINDING
AS
SELECT InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count]
FROM dbo.Inventories;
GO

-- Show the Current data in the Categories, Products, and Inventories Tables
SELECT *
FROM vCategories;
GO
SELECT *
FROM vProducts;
GO
SELECT *
FROM vEmployees;
GO
SELECT *
FROM vInventories;
GO

/*
 ******************************** Questions and Answers ********************************
 */
PRINT
    'NOTES------------------------------------------------------------------------------------
     1) You must use the BASIC views for each table.
     2) Remember that Inventory Counts are Randomly Generated. So, your counts may not match mine
     3) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
    ------------------------------------------------------------------------------------------'
GO
-- Question 1 (5% of pts):
-- Show a list of Product names and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the product name.

-- <Put Your Code Here> --
-- SELECT ProductName, UnitPrice FROM Products ORDER BY ProductName;

CREATE OR ALTER FUNCTION dbo.fnFormatCurrencyUSD(@value MONEY)
    RETURNS NVARCHAR(100) AS
BEGIN
    RETURN (FORMAT(@value, 'C', 'en-US'));
END
GO

SELECT ProductName, dbo.fnFormatCurrencyUSD(UnitPrice) AS UnitPrice
FROM vProducts
ORDER BY ProductName;
GO

-- Question 2 (10% of pts): 
-- Show a list of Category and Product names, and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the Category and Product.
-- <Put Your Code Here> --

SELECT CategoryName, ProductName, dbo.fnFormatCurrencyUSD(UnitPrice) AS UnitPrice
FROM vProducts P
         JOIN vCategories C ON P.CategoryID = C.CategoryID
ORDER BY C.CategoryName, P.ProductName;
GO

-- Question 3 (10% of pts): 
-- Use functions to show a list of Product names, each Inventory Date, and the Inventory Count.
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

-- <Put Your Code Here> --

-- SELECT * FROM Products
-- JOIN Inventories I ON Products.ProductID = I.ProductID
-- ORDER BY ProductName, InventoryDate;

CREATE OR ALTER FUNCTION dbo.fnFormatDateMMMMyyyy(@date DATETIME)
    RETURNS NVARCHAR(100) AS
BEGIN
    RETURN FORMAT(@date, 'MMMM, yyyy');
END
GO

SELECT ProductName, dbo.fnFormatDateMMMMyyyy(InventoryDate) AS InventoryDate, Count
FROM vProducts P
         JOIN vInventories I ON P.ProductID = I.ProductID
ORDER BY P.ProductName, MONTH(I.InventoryDate), YEAR(I.InventoryDate);
GO

-- Question 4 (10% of pts): 
-- CREATE A VIEW called vProductInventories. 
-- Shows a list of Product names, each Inventory Date, and the Inventory Count. 
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

-- <Put Your Code Here> --
-- SELECT *
-- FROM vProducts P
--          JOIN vInventories I ON P.ProductID = I.ProductID
-- ORDER BY ProductName, InventoryDate;

-- CREATE OR ALTER VIEW vProductInventories AS
-- SELECT TOP 1000 ProductName, InventoryDate, Count
-- FROM vProducts P
--          JOIN vInventories I ON P.ProductID = I.ProductID
-- ORDER BY ProductName, InventoryDate;

CREATE OR ALTER VIEW vProductInventories AS
SELECT TOP 1000 ProductName, dbo.fnFormatDateMMMMyyyy(InventoryDate) AS InventoryDate, Count
FROM vProducts P
         JOIN vInventories I ON P.ProductID = I.ProductID
ORDER BY P.ProductName, I.InventoryDate;
GO

-- Check that it works: Select * From vProductInventories;
SELECT *
FROM vProductInventories;
GO

-- Question 5 (10% of pts): 
-- CREATE A VIEW called vCategoryInventories. 
-- Shows a list of Category names, Inventory Dates, and a TOTAL Inventory Count BY CATEGORY
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

-- <Put Your Code Here> --
-- SELECT C.CategoryName, InventoryDate, I.Count FROM vInventories I
-- JOIN vProducts P ON I.ProductID = P.ProductID
-- RIGHT JOIN vCategories C ON P.CategoryID = C.CategoryID;

-- SELECT C.CategoryName, InventoryDate, SUM(I.Count) FROM vInventories I
-- JOIN vProducts P ON I.ProductID = P.ProductID
-- RIGHT JOIN vCategories C ON P.CategoryID = C.CategoryID
-- GROUP BY I.InventoryDate, C.CategoryName;

CREATE OR ALTER VIEW vCategoryInventories AS
SELECT TOP 1000 C.CategoryName,
                dbo.fnFormatDateMMMMyyyy(I.InventoryDate) AS InventoryDate,
                SUM(I.Count)                              AS InventroyCount
FROM vInventories I
         JOIN vProducts P ON I.ProductID = P.ProductID
         RIGHT JOIN vCategories C ON P.CategoryID = C.CategoryID
GROUP BY I.InventoryDate, C.CategoryName
ORDER BY C.CategoryName, I.InventoryDate;
GO
-- Check that it works: Select * From vCategoryInventories;
SELECT *
FROM vCategoryInventories;
GO

-- Question 6 (10% of pts): 
-- CREATE ANOTHER VIEW called vProductInventoriesWithPreviouMonthCounts. 
-- Show a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month Count.
-- Use functions to set any January NULL counts to zero. 
-- Order the results by the Product and Date. 
-- This new view must use your vProductInventories view.

-- <Put Your Code Here> --
-- SELECT ProductName,
--        dbo.fnFormatDateMMMMyyyy(InventoryDate),
--        Count                                                                         AS InventoryCount,
--        ISNULL(LAG(Count) OVER ( PARTITION BY ProductName ORDER BY InventoryDate), 0) AS PreviousInventoryCount
-- FROM vInventories I
--          JOIN vProducts P ON I.ProductID = P.ProductID
-- ORDER BY ProductName, InventoryDate;

CREATE OR ALTER VIEW vProductInventoriesWithPreviousMonthCounts AS
SELECT TOP 1000 P.ProductName,
                dbo.fnFormatDateMMMMyyyy(I.InventoryDate) AS InventoryDate,
                Count                                     AS InventoryCount,
                ISNULL(LAG(Count) OVER ( PARTITION BY P.ProductName ORDER BY I.InventoryDate),
                       0)                                 AS PreviousInventoryCount
FROM vInventories I
         JOIN vProducts P ON I.ProductID = P.ProductID
ORDER BY P.ProductName, I.InventoryDate;
GO

-- Check that it works: Select * From vProductInventoriesWithPreviousMonthCounts;
SELECT *
FROM vProductInventoriesWithPreviousMonthCounts;
GO

-- Question 7 (15% of pts): 
-- CREATE a VIEW called vProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- Varify that the results are ordered by the Product and Date.

-- <Put Your Code Here> --
CREATE OR ALTER FUNCTION dbo.fnCalculateKPI(@Current INT, @Previous INT)
    RETURNS INT
AS
BEGIN
    RETURN (
        CASE
            WHEN @Current > @Previous THEN 1
            WHEN @Current < @Previous THEN -1
            ELSE 0
            END
        );
END
GO

CREATE OR ALTER VIEW vProductInventoriesWithPreviousMonthCountsWithKPIs AS
SELECT TOP 1000 P.ProductName,
                dbo.fnFormatDateMMMMyyyy(I.InventoryDate) AS InventoryDate,
                Count                                     AS InventoryCount,
                ISNULL(LAG(Count) OVER ( PARTITION BY P.ProductName ORDER BY I.InventoryDate),
                       0)                                 AS PreviousInventoryCount,
                dbo.fnCalculateKPI(I.Count,
                                   ISNULL(LAG(Count) OVER ( PARTITION BY P.ProductName ORDER BY I.InventoryDate),
                                          0))             AS CountVsPreviousCountKPI
FROM vInventories I
         JOIN vProducts P ON I.ProductID = P.ProductID
ORDER BY P.ProductName, I.InventoryDate;
GO

-- Important: This new view must use your vProductInventoriesWithPreviousMonthCounts view!
-- Check that it works: Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs;
SELECT *
FROM vProductInventoriesWithPreviousMonthCountsWithKPIs;
GO

-- Question 8 (25% of pts): 
-- CREATE a User Defined Function (UDF) called fProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, the Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- The function must use the ProductInventoriesWithPreviousMonthCountsWithKPIs view.
-- Varify that the results are ordered by the Product and Date.

-- <Put Your Code Here> --
CREATE OR ALTER FUNCTION fProductInventoriesWithPreviousMonthCountsWithKPIs(@KpiValue INT)
    RETURNS TABLE
        AS
        RETURN SELECT *
               FROM vProductInventoriesWithPreviousMonthCountsWithKPIs
               WHERE CountVsPreviousCountKPI = @KpiValue;
GO

-- Check that it works:
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
GO
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
GO
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
GO

/***************************************************************************************/