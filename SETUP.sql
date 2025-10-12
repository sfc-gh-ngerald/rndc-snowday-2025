USE ROLE ACCOUNTADMIN;

-- Creating a Small WH for use in the RNDC Snow Day Labs
-- If needed, we can scale this up later
CREATE OR REPLACE WAREHOUSE RNDC_LAB_WH WITH WAREHOUSE_SIZE='SMALL';
USE WAREHOUSE RNDC_LAB_WH;

-- Ensuring that cross region inference is turned on. 
-- This is a requirements for Analyst
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';

-- Setup dedicated Snowflake Intelligence db
CREATE DATABASE IF NOT EXISTS snowflake_intelligence;
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;

-- Setup dedicated Agents schema to store agents
CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;

-- Providing access to create new agents in the schema
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE ACCOUNTADMIN;

-- ================================================================
-- RNDC Snowflake Hands-On Lab - Data Setup Script
-- Star Schema: Sales Fact Table with Customer and Product Dimensions
-- ================================================================

-- Create database and schema
CREATE DATABASE IF NOT EXISTS RNDC_LAB;
USE DATABASE RNDC_LAB;
CREATE SCHEMA IF NOT EXISTS TARGET;
USE SCHEMA TARGET;

-- ================================================================
-- DIMENSION TABLE: CUSTOMER
-- ================================================================
CREATE OR REPLACE TABLE Customer (
    Customer_ID INT PRIMARY KEY COMMENT 'Unique identifier for each customer account',
    Customer_Name VARCHAR(200) COMMENT 'Business name of the customer establishment',
    Account_Type VARCHAR(20) COMMENT 'Classification: On-Premise (bars/restaurants) or Off-Premise (retail stores)',
    City VARCHAR(100) COMMENT 'City where the customer business is located',
    State VARCHAR(2) COMMENT 'Two-letter state code',
    License_Status VARCHAR(20) COMMENT 'Current status of alcohol license (Active/Suspended)',
    Sales_Territory VARCHAR(50) COMMENT 'Sales territory or geographic region for the account'
) COMMENT = 'Customer dimension table containing account information for on-premise and off-premise retailers';

-- Insert sample customer data
INSERT INTO Customer (Customer_ID, Customer_Name, Account_Type, City, State, License_Status, Sales_Territory) VALUES
(1001, 'The Rusty Anchor Bar & Grill', 'On-Premise', 'Austin', 'TX', 'Active', 'Central Texas'),
(1002, 'Sunset Wine & Spirits', 'Off-Premise', 'Houston', 'TX', 'Active', 'Houston Metro'),
(1003, 'Downtown Steakhouse', 'On-Premise', 'Dallas', 'TX', 'Active', 'North Texas'),
(1004, 'Premium Liquor Mart', 'Off-Premise', 'San Antonio', 'TX', 'Active', 'South Texas'),
(1005, 'The Velvet Lounge', 'On-Premise', 'Fort Worth', 'TX', 'Active', 'North Texas'),
(1006, 'Coastal Beverage Store', 'Off-Premise', 'Corpus Christi', 'TX', 'Active', 'Coastal Region'),
(1007, 'Hill Country Grill', 'On-Premise', 'Fredericksburg', 'TX', 'Active', 'Central Texas'),
(1008, 'QuickStop Liquors', 'Off-Premise', 'Arlington', 'TX', 'Active', 'North Texas'),
(1009, 'Uptown Wine Bar', 'On-Premise', 'Dallas', 'TX', 'Active', 'North Texas'),
(1010, 'World Corner Store', 'Off-Premise', 'College Station', 'TX', 'Active', 'Central Texas'),
(1011, 'Mariachi Mexican Restaurant', 'On-Premise', 'El Paso', 'TX', 'Active', 'West Texas'),
(1012, 'Total Wine Superstore', 'Off-Premise', 'Plano', 'TX', 'Active', 'North Texas'),
(1013, 'The Jazz Kitchen', 'On-Premise', 'Austin', 'TX', 'Active', 'Central Texas'),
(1014, 'Beachside Package Store', 'Off-Premise', 'Galveston', 'TX', 'Active', 'Houston Metro'),
(1015, 'Prime Cuts Steakhouse', 'On-Premise', 'Houston', 'TX', 'Active', 'Houston Metro'),
(1016, 'Budget Beverage Outlet', 'Off-Premise', 'Lubbock', 'TX', 'Active', 'West Texas'),
(1017, 'Rooftop Bar & Lounge', 'On-Premise', 'San Antonio', 'TX', 'Active', 'South Texas'),
(1018, 'Neighborhood Liquor', 'Off-Premise', 'Waco', 'TX', 'Active', 'Central Texas'),
(1019, 'Italian Villa Restaurant', 'On-Premise', 'Irving', 'TX', 'Active', 'North Texas'),
(1020, 'Express Wine & Spirits', 'Off-Premise', 'Amarillo', 'TX', 'Active', 'Panhandle'),
(1021, 'The Sports Bar & Grill', 'On-Premise', 'Frisco', 'TX', 'Active', 'North Texas'),
(1022, 'Valley Wine Shop', 'Off-Premise', 'McAllen', 'TX', 'Active', 'Rio Grande Valley'),
(1023, 'Seafood Palace', 'On-Premise', 'Beaumont', 'TX', 'Active', 'East Texas'),
(1024, 'Discount Liquor Warehouse', 'Off-Premise', 'Killeen', 'TX', 'Active', 'Central Texas'),
(1025, 'Fusion Bistro', 'On-Premise', 'Austin', 'TX', 'Suspended', 'Central Texas');

-- ================================================================
-- DIMENSION TABLE: PRODUCT
-- ================================================================
CREATE OR REPLACE TABLE Product (
    Product_SKU VARCHAR(20) PRIMARY KEY COMMENT 'Unique stock keeping unit identifier for each product',
    Brand_Name VARCHAR(100) COMMENT 'Brand name of the wine or spirits product',
    Supplier_ID INT COMMENT 'Unique identifier for the supplier or vendor',
    Category VARCHAR(50) COMMENT 'Product category: Vodka, Whiskey, Tequila, Rum, Gin, Cabernet, Chardonnay, etc.',
    Bottle_Size_L DECIMAL(4,2) COMMENT 'Bottle size in liters (e.g., 0.75L standard, 1.0L liter)',
    Proof INT COMMENT 'Alcohol proof (twice the ABV percentage). Wine products use 0.'
) COMMENT = 'Product dimension table containing wine and spirits catalog with brand, category, and specifications';

-- Insert sample product data (wine and spirits)
INSERT INTO Product (Product_SKU, Brand_Name, Supplier_ID, Category, Bottle_Size_L, Proof) VALUES
-- Vodka
('SKU-V-001', 'Tito''s Handmade Vodka', 2001, 'Vodka', 0.75, 80),
('SKU-V-002', 'Grey Goose', 2002, 'Vodka', 0.75, 80),
('SKU-V-003', 'Ketel One', 2003, 'Vodka', 1.00, 80),
('SKU-V-004', 'Absolut', 2002, 'Vodka', 0.75, 80),
-- Whiskey
('SKU-W-001', 'Jack Daniel''s Tennessee Whiskey', 2004, 'Whiskey', 0.75, 80),
('SKU-W-002', 'Maker''s Mark Bourbon', 2005, 'Whiskey', 0.75, 90),
('SKU-W-003', 'Crown Royal', 2006, 'Whiskey', 0.75, 80),
('SKU-W-004', 'Bulleit Bourbon', 2007, 'Whiskey', 0.75, 90),
-- Tequila
('SKU-T-001', 'Patron Silver', 2008, 'Tequila', 0.75, 80),
('SKU-T-002', 'Don Julio Blanco', 2009, 'Tequila', 0.75, 80),
('SKU-T-003', 'Casamigos Reposado', 2010, 'Tequila', 0.75, 80),
('SKU-T-004', '1800 Reposado', 2008, 'Tequila', 0.75, 80),
-- Rum
('SKU-R-001', 'Bacardi Superior', 2011, 'Rum', 0.75, 80),
('SKU-R-002', 'Captain Morgan Spiced', 2012, 'Rum', 0.75, 70),
('SKU-R-003', 'Malibu Coconut Rum', 2013, 'Rum', 0.75, 42),
-- Gin
('SKU-G-001', 'Tanqueray', 2014, 'Gin', 0.75, 94),
('SKU-G-002', 'Hendrick''s', 2015, 'Gin', 0.75, 88),
('SKU-G-003', 'Bombay Sapphire', 2016, 'Gin', 0.75, 94),
-- Red Wine
('SKU-RW-001', 'Caymus Cabernet Sauvignon', 2017, 'Cabernet', 0.75, 0),
('SKU-RW-002', 'Josh Cellars Cabernet', 2018, 'Cabernet', 0.75, 0),
('SKU-RW-003', 'La Crema Pinot Noir', 2019, 'Pinot Noir', 0.75, 0),
('SKU-RW-004', 'Meiomi Pinot Noir', 2019, 'Pinot Noir', 0.75, 0),
('SKU-RW-005', 'Apothic Red Blend', 2020, 'Red Blend', 0.75, 0),
-- White Wine
('SKU-WW-001', 'Kendall-Jackson Chardonnay', 2021, 'Chardonnay', 0.75, 0),
('SKU-WW-002', 'Kim Crawford Sauvignon Blanc', 2022, 'Sauvignon Blanc', 0.75, 0),
('SKU-WW-003', 'Santa Margherita Pinot Grigio', 2023, 'Pinot Grigio', 0.75, 0),
('SKU-WW-004', 'Ruffino Pinot Grigio', 2023, 'Pinot Grigio', 0.75, 0),
-- Champagne/Sparkling
('SKU-SP-001', 'Moet & Chandon', 2024, 'Champagne', 0.75, 0),
('SKU-SP-002', 'La Marca Prosecco', 2025, 'Prosecco', 0.75, 0);

-- ================================================================
-- FACT TABLE: SALES
-- ================================================================
CREATE OR REPLACE TABLE Sales (
    Transaction_ID INT PRIMARY KEY COMMENT 'Unique identifier for each sales transaction',
    Date DATE COMMENT 'Date when the sales transaction occurred',
    Sales_Rep_ID INT COMMENT 'Unique identifier for the sales representative',
    Customer_ID INT COMMENT 'Foreign key reference to the customer account',
    Product_SKU VARCHAR(20) COMMENT 'Foreign key reference to the product sold',
    Case_Quantity INT COMMENT 'Number of cases sold (each case contains 12 bottles)',
    Bottle_Price DECIMAL(10,2) COMMENT 'Price per individual bottle before discounts',
    Total_Sale_Amount DECIMAL(12,2) COMMENT 'Total sale amount after discounts (cases × 12 × price - discount)',
    Discount_Applied DECIMAL(10,2) COMMENT 'Dollar amount of discount (10% for >5 cases, 5% for promotions)',
    Promotion_ID INT COMMENT 'Promotional campaign identifier (NULL if no promotion)',
    FOREIGN KEY (Customer_ID) REFERENCES Customer(Customer_ID),
    FOREIGN KEY (Product_SKU) REFERENCES Product(Product_SKU)
) COMMENT = 'Sales fact table containing transaction records with quantities, pricing, and discounts';

-- ================================================================
-- GENERATE SALES DATA (Using Snowflake GENERATOR)
-- Generate 100,000 transactions over the past 12 months
-- Uses seed value (42) for reproducible data generation
-- ================================================================

-- Create a temporary table to hold product pricing
CREATE OR REPLACE TEMPORARY TABLE Product_Pricing AS
SELECT 
    Product_SKU,
    Category,
    CASE 
        WHEN Category IN ('Vodka', 'Whiskey', 'Tequila', 'Gin', 'Rum') THEN 
            CASE 
                WHEN Brand_Name LIKE '%Grey Goose%' OR Brand_Name LIKE '%Patron%' OR Brand_Name LIKE '%Don Julio%' THEN 45.99
                WHEN Brand_Name LIKE '%Tito%' OR Brand_Name LIKE '%Maker%' OR Brand_Name LIKE '%Casamigos%' THEN 32.99
                WHEN Brand_Name LIKE '%Jack Daniel%' OR Brand_Name LIKE '%Crown Royal%' THEN 28.99
                WHEN Brand_Name LIKE '%Hendrick%' THEN 38.99
                ELSE 24.99
            END
        WHEN Category = 'Champagne' THEN 54.99
        WHEN Category = 'Prosecco' THEN 12.99
        WHEN Category IN ('Cabernet', 'Pinot Noir') THEN 
            CASE 
                WHEN Brand_Name LIKE '%Caymus%' THEN 89.99
                WHEN Brand_Name LIKE '%Meiomi%' OR Brand_Name LIKE '%La Crema%' THEN 22.99
                ELSE 16.99
            END
        WHEN Category IN ('Chardonnay', 'Sauvignon Blanc', 'Pinot Grigio') THEN 
            CASE 
                WHEN Brand_Name LIKE '%Santa Margherita%' THEN 24.99
                WHEN Brand_Name LIKE '%Kim Crawford%' OR Brand_Name LIKE '%Kendall%' THEN 14.99
                ELSE 11.99
            END
        WHEN Category = 'Red Blend' THEN 12.99
        ELSE 19.99
    END AS Base_Price
FROM Product;

-- Generate sales transactions
INSERT INTO Sales (
    Transaction_ID,
    Date,
    Sales_Rep_ID,
    Customer_ID,
    Product_SKU,
    Case_Quantity,
    Bottle_Price,
    Total_Sale_Amount,
    Discount_Applied,
    Promotion_ID
)
WITH Generated_Rows AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ8()) AS Transaction_ID,
        DATEADD(
            DAY, 
            UNIFORM(1, 365, RANDOM(42)), 
            DATEADD(YEAR, -1, CURRENT_DATE())
        ) AS Date,
        UNIFORM(5001, 5025, RANDOM(42)) AS Sales_Rep_ID,
        UNIFORM(1001, 1024, RANDOM(42)) AS Customer_ID,
        SEQ8() AS Seed
    FROM TABLE(GENERATOR(ROWCOUNT => 100000))
),
Product_Selection AS (
    SELECT 
        gr.*,
        p.Product_SKU,
        pp.Base_Price,
        pp.Category
    FROM Generated_Rows gr
    CROSS JOIN (
        SELECT 
            Product_SKU,
            ROW_NUMBER() OVER (ORDER BY Product_SKU) AS Product_Rank
        FROM Product
    ) p
    JOIN Product_Pricing pp ON p.Product_SKU = pp.Product_SKU
    WHERE MOD(gr.Seed, 30) = MOD(p.Product_Rank - 1, 30)
),
Sales_With_Calculations AS (
    SELECT
        Transaction_ID,
        Date,
        Sales_Rep_ID,
        Customer_ID,
        Product_SKU,
        CASE 
            WHEN Category IN ('Vodka', 'Whiskey', 'Tequila', 'Gin', 'Rum') 
                THEN UNIFORM(1, 10, RANDOM(42))
            ELSE UNIFORM(1, 15, RANDOM(42))
        END AS Case_Quantity,
        Base_Price AS Bottle_Price,
        -- Determine if promotion applies (20% chance)
        CASE 
            WHEN UNIFORM(1, 100, RANDOM(42)) <= 20 
            THEN UNIFORM(1001, 1010, RANDOM(42))
            ELSE NULL 
        END AS Promotion_ID
    FROM Product_Selection
)
SELECT 
    Transaction_ID,
    Date,
    Sales_Rep_ID,
    Customer_ID,
    Product_SKU,
    Case_Quantity,
    Bottle_Price,
    -- Calculate discount: 10% for volume (>5 cases) or 5% for promotions
    CASE 
        WHEN Case_Quantity > 5 THEN ROUND(Case_Quantity * 12 * Bottle_Price * 0.10, 2)
        WHEN Promotion_ID IS NOT NULL THEN ROUND(Case_Quantity * 12 * Bottle_Price * 0.05, 2)
        ELSE 0.00
    END AS Discount_Applied,
    -- Calculate total sale amount (Case_Quantity * 12 bottles * price - discount)
    ROUND(
        (Case_Quantity * 12 * Bottle_Price) - 
        CASE 
            WHEN Case_Quantity > 5 THEN ROUND(Case_Quantity * 12 * Bottle_Price * 0.10, 2)
            WHEN Promotion_ID IS NOT NULL THEN ROUND(Case_Quantity * 12 * Bottle_Price * 0.05, 2)
            ELSE 0.00
        END,
        2
    ) AS Total_Sale_Amount,
    Promotion_ID
FROM Sales_With_Calculations;

-- ================================================================
-- DATA VALIDATION QUERIES
-- ================================================================

-- Summary statistics
SELECT 
    'Total Sales Transactions' AS Metric,
    COUNT(*) AS Value
FROM Sales
UNION ALL
SELECT 
    'Total Customers',
    COUNT(*) 
FROM Customer
UNION ALL
SELECT 
    'Total Products',
    COUNT(*) 
FROM Product
UNION ALL
SELECT 
    'Total Revenue',
    SUM(Total_Sale_Amount)
FROM Sales
UNION ALL
SELECT 
    'Total Discounts Given',
    SUM(Discount_Applied)
FROM Sales;

-- Sales by Category
SELECT 
    p.Category,
    COUNT(s.Transaction_ID) AS Transaction_Count,
    SUM(s.Case_Quantity) AS Total_Cases_Sold,
    ROUND(SUM(s.Total_Sale_Amount), 2) AS Total_Revenue
FROM Sales s
JOIN Product p ON s.Product_SKU = p.Product_SKU
GROUP BY p.Category
ORDER BY Total_Revenue DESC;

-- Sales by Account Type
SELECT 
    c.Account_Type,
    COUNT(s.Transaction_ID) AS Transaction_Count,
    ROUND(SUM(s.Total_Sale_Amount), 2) AS Total_Revenue,
    ROUND(AVG(s.Total_Sale_Amount), 2) AS Avg_Transaction_Size
FROM Sales s
JOIN Customer c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Account_Type
ORDER BY Total_Revenue DESC;

-- Top 10 Customers by Revenue
SELECT 
    c.Customer_Name,
    c.Account_Type,
    c.City,
    COUNT(s.Transaction_ID) AS Transaction_Count,
    ROUND(SUM(s.Total_Sale_Amount), 2) AS Total_Revenue
FROM Sales s
JOIN Customer c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Name, c.Account_Type, c.City
ORDER BY Total_Revenue DESC
LIMIT 10;

-- ================================================================
-- SETUP COMPLETE
-- ================================================================
SELECT 'RNDC Lab Data Setup Complete!' AS Status;