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
-- SUPPORT CASES TABLE
-- ================================================================
CREATE OR REPLACE TABLE Support_Cases (
    Support_Case_ID INT PRIMARY KEY COMMENT 'Unique identifier for each support case',
    Transaction_ID INT COMMENT 'Foreign key reference to the sales transaction',
    Case_Date DATE COMMENT 'Date when the support case was opened',
    Case_Type VARCHAR(50) COMMENT 'Type of issue: Damaged Product, Delivery Issue, Wrong Product, Quality Complaint, Billing Issue, etc.',
    Priority VARCHAR(20) COMMENT 'Priority level: Low, Medium, High, Critical',
    Status VARCHAR(20) COMMENT 'Current status: Open, In Progress, Resolved, Closed',
    Resolution_Time_Days INT COMMENT 'Number of days taken to resolve the case (NULL if not yet resolved)',
    Customer_Satisfaction_Score INT COMMENT 'Customer satisfaction rating 1-5 after resolution (NULL if not yet resolved)',
    Description VARCHAR(500) COMMENT 'Brief description of the customer issue',
    FOREIGN KEY (Transaction_ID) REFERENCES Sales(Transaction_ID)
) COMMENT = 'Support cases table containing customer complaints and issues related to sales transactions';

-- Generate 100 support cases mapped to random transactions
INSERT INTO Support_Cases (
    Support_Case_ID,
    Transaction_ID,
    Case_Date,
    Case_Type,
    Priority,
    Status,
    Resolution_Time_Days,
    Customer_Satisfaction_Score,
    Description
)
WITH Case_Types AS (
    SELECT 'Damaged Product' AS Case_Type, 1 AS Type_ID
    UNION ALL SELECT 'Delivery Issue', 2
    UNION ALL SELECT 'Wrong Product', 3
    UNION ALL SELECT 'Quality Complaint', 4
    UNION ALL SELECT 'Billing Issue', 5
    UNION ALL SELECT 'Missing Items', 6
    UNION ALL SELECT 'Late Delivery', 7
    UNION ALL SELECT 'Temperature Issue', 8
),
Priorities AS (
    SELECT 'Low' AS Priority, 1 AS Priority_ID
    UNION ALL SELECT 'Medium', 2
    UNION ALL SELECT 'High', 3
    UNION ALL SELECT 'Critical', 4
),
Statuses AS (
    SELECT 'Resolved' AS Status, 1 AS Status_ID, 85 AS Probability
    UNION ALL SELECT 'Closed', 2, 10
    UNION ALL SELECT 'In Progress', 3, 3
    UNION ALL SELECT 'Open', 4, 2
),
Random_Transactions AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY Transaction_ID) AS Support_Case_ID,
        Transaction_ID,
        Date AS Transaction_Date
    FROM Sales
    ORDER BY RANDOM(42)
    LIMIT 100
),
Cases_With_Resolution AS (
    SELECT
        Support_Case_ID,
        Transaction_ID,
        DATEADD(DAY, UNIFORM(1, 30, RANDOM(42)), Transaction_Date) AS Case_Date,
        CASE UNIFORM(1, 8, RANDOM(42))
            WHEN 1 THEN 'Damaged Product'
            WHEN 2 THEN 'Delivery Issue'
            WHEN 3 THEN 'Wrong Product'
            WHEN 4 THEN 'Quality Complaint'
            WHEN 5 THEN 'Billing Issue'
            WHEN 6 THEN 'Missing Items'
            WHEN 7 THEN 'Late Delivery'
            ELSE 'Temperature Issue'
        END AS Case_Type,
        CASE UNIFORM(1, 100, RANDOM(42))
            WHEN 1 THEN 'Critical'
            WHEN 2 THEN 'Critical'
            WHEN 3 THEN 'Critical'
            ELSE CASE UNIFORM(1, 4, RANDOM(42))
                WHEN 1 THEN 'Low'
                WHEN 2 THEN 'Medium'
                WHEN 3 THEN 'High'
                ELSE 'Medium'
            END
        END AS Priority,
        CASE UNIFORM(1, 100, RANDOM(42))
            WHEN 1 THEN 'Open'
            WHEN 2 THEN 'Open'
            WHEN 3 THEN 'In Progress'
            WHEN 4 THEN 'In Progress'
            WHEN 5 THEN 'In Progress'
            WHEN 6 THEN 'Closed'
            WHEN 7 THEN 'Closed'
            ELSE 'Resolved'
        END AS Status
    FROM Random_Transactions
)
SELECT
    Support_Case_ID,
    Transaction_ID,
    Case_Date,
    Case_Type,
    Priority,
    Status,
    -- Resolution time only for resolved/closed cases
    CASE 
        WHEN Status IN ('Resolved', 'Closed') THEN UNIFORM(1, 45, RANDOM(42))
        ELSE NULL
    END AS Resolution_Time_Days,
    -- Customer satisfaction only for resolved/closed cases
    CASE 
        WHEN Status IN ('Resolved', 'Closed') THEN 
            CASE 
                WHEN Priority = 'Critical' THEN UNIFORM(2, 4, RANDOM(42))
                WHEN Priority = 'High' THEN UNIFORM(3, 5, RANDOM(42))
                ELSE UNIFORM(3, 5, RANDOM(42))
            END
        ELSE NULL
    END AS Customer_Satisfaction_Score,
    -- Generate realistic unique descriptions based on case type with variations
    CASE Case_Type
        WHEN 'Damaged Product' THEN 
            CASE MOD(Support_Case_ID, 12)
                WHEN 0 THEN 'Received shipment with 3 broken bottles of Cabernet. Glass shards in box, product leaking. Need credit and replacement ASAP.'
                WHEN 1 THEN '2 cases arrived with damaged bottles. Labels torn off, liquid seeping through cardboard. Cannot sell these to customers.'
                WHEN 2 THEN 'Driver dropped pallet during unload. 5 bottles shattered, rest of order appears intact but checking for cracks.'
                WHEN 3 THEN 'Box was crushed in transit. 4 bottles of vodka completely destroyed. Packaging inadequate for weight.'
                WHEN 4 THEN 'Entire case of wine bottles have cracked necks. Looks like freezing damage during transport.'
                WHEN 5 THEN 'Bottles arrived with damaged foil caps and cork issues. Customer refuses to accept this product.'
                WHEN 6 THEN 'Found broken glass when opening delivery. At least 6 bottles destroyed, product all over warehouse floor.'
                WHEN 7 THEN 'Premium whiskey bottles have chipped glass on shoulders. Cannot display these, significant loss.'
                WHEN 8 THEN 'Several bottles leaking from caps. Cork damage evident. Need replacement for tonight''s event.'
                WHEN 9 THEN 'Case of Prosecco arrived with broken bottles. Shipment not properly secured during delivery.'
                WHEN 10 THEN 'Champagne bottles have damaged labels from moisture. Product integrity OK but can''t sell at full price.'
                ELSE 'Multiple damaged bottles in shipment. Poor packaging or rough handling suspected.'
            END
        WHEN 'Delivery Issue' THEN
            CASE MOD(Support_Case_ID, 10)
                WHEN 0 THEN 'Delivery scheduled for 10am, arrived at 4:30pm. Had customers waiting. Lost sales due to delay.'
                WHEN 1 THEN 'Driver never showed up for scheduled delivery. No call, no update. This is the second time this month.'
                WHEN 2 THEN 'Truck broke down, delivery rescheduled to next day. Big problem - we have wedding event tonight!'
                WHEN 3 THEN 'Wrong location - driver delivered to our other location across town. Caused major inventory issues.'
                WHEN 4 THEN 'Delivery arrived at closed restaurant (Sunday). Driver didn''t call ahead. Product sat outside for hours.'
                WHEN 5 THEN 'Scheduled AM delivery came at 7pm. Staff already left. Had to pay overtime to receive shipment.'
                WHEN 6 THEN 'No one notified us of delivery time change. Shipment arrived when we were closed for private event.'
                WHEN 7 THEN 'Driver refused to bring product into cooler. Left pallets in 95 degree heat for 20 minutes.'
                WHEN 8 THEN 'Delivery came 2 days late. Already had to cancel orders with our customers. Very disappointed.'
                ELSE 'Missed delivery window completely. Restaurant was out of several key products during dinner rush.'
            END
        WHEN 'Wrong Product' THEN
            CASE MOD(Support_Case_ID, 10)
                WHEN 0 THEN 'Ordered Grey Goose, received Absolut instead. Customer specifically requested premium brand for event.'
                WHEN 1 THEN 'Received Cabernet when we ordered Pinot Noir. Wrong SKU on entire pallet. Need exchange immediately.'
                WHEN 2 THEN 'Got 1L bottles instead of 750ml as ordered. Pricing is all wrong now, shelf space is an issue.'
                WHEN 3 THEN 'Ordered Jack Daniels, received Jim Beam. Invoice shows correct product but delivery is wrong.'
                WHEN 4 THEN 'Wrong tequila brand delivered. Ordered Don Julio, received 1800. Customer loyalty program affected.'
                WHEN 5 THEN 'Received cases of Chardonnay instead of Sauvignon Blanc. Wedding event is tomorrow, please help!'
                WHEN 6 THEN 'Bourbon mix-up. Got Makers Mark but order clearly states Bulleit. Have customers asking for it.'
                WHEN 7 THEN 'Received wrong vintage of wine. Ordered 2022, received 2020. Menu already printed with specific year.'
                WHEN 8 THEN 'Completely wrong rum - ordered spiced, got coconut. Can''t use this for our signature cocktails.'
                ELSE 'Wrong product entirely. Ordered vodka cases, received gin. Major issue for our bar program.'
            END
        WHEN 'Quality Complaint' THEN
            CASE MOD(Support_Case_ID, 10)
                WHEN 0 THEN 'Wine has visible sediment and off color. Multiple bottles from same batch. Customers complaining.'
                WHEN 1 THEN 'Whiskey tastes off - chemical flavor. Several customers sent drinks back. Need to pull entire batch.'
                WHEN 2 THEN 'Cork taint in Cabernet. Musty smell, undrinkable. At least 4 bottles confirmed from this case.'
                WHEN 3 THEN 'Tequila bottles have particles floating in liquid. Quality control issue. Cannot serve this.'
                WHEN 4 THEN 'Vodka has cloudy appearance. Multiple bottles affected. Concerned about contamination.'
                WHEN 5 THEN 'Wine oxidized - brown tinge, flat taste. Either storage or cork issue. Lost $300 in returned drinks.'
                WHEN 6 THEN 'Rum has strange sediment at bottom. Never seen this before with this brand. Product defect?'
                WHEN 7 THEN 'Prosecco is flat - barely any carbonation. Entire case seems affected. Ruined brunch service.'
                WHEN 8 THEN 'Label says 80 proof but tastes watered down. Multiple bartenders noticed. Authenticity concern.'
                ELSE 'Off taste in multiple bottles. Customers refusing drinks. Quality issue with this batch.'
            END
        WHEN 'Billing Issue' THEN
            CASE MOD(Support_Case_ID, 10)
                WHEN 0 THEN 'Invoice shows $2,847 but quote was $2,450. Promotion discount not applied. Need correction.'
                WHEN 1 THEN 'Charged for 10 cases but only received 8. Count verified by two staff members. Credit needed.'
                WHEN 2 THEN 'Wrong pricing on invoice. Bottle price shows $45.99 but our contract rate is $38.50.'
                WHEN 3 THEN 'Double charged on credit card. Same invoice billed twice. Please refund one charge immediately.'
                WHEN 4 THEN 'Volume discount not reflected on bill. Ordered 12 cases, should qualify for 10% off.'
                WHEN 5 THEN 'Promotional pricing from sales rep not honored. Invoice $380 higher than quoted price.'
                WHEN 6 THEN 'Invoice includes items we did not order. Extra $650 in charges for unknown products.'
                WHEN 7 THEN 'Tax calculated incorrectly. Our license qualifies for different rate. Overcharged by $127.'
                WHEN 8 THEN 'Payment terms wrong on invoice. Net 30 agreed but invoice shows due immediately.'
                ELSE 'Billing error - charged premium pricing but received standard product. Need price adjustment.'
            END
        WHEN 'Missing Items' THEN
            CASE MOD(Support_Case_ID, 10)
                WHEN 0 THEN 'Ordered 5 cases of Merlot, only received 3. Invoice shows 5, need 2 cases delivered ASAP.'
                WHEN 1 THEN 'Packing slip shows 8 cases but truck only had 6. Driver confirmed short shipment.'
                WHEN 2 THEN 'Missing entire case of vodka from order. Charged for it but not in delivery.'
                WHEN 3 THEN 'Order incomplete - missing 2 cases of whiskey. This is for weekend inventory, urgent.'
                WHEN 4 THEN 'Received partial shipment. 4 cases short. No explanation from driver or dispatch.'
                WHEN 5 THEN 'Missing case of Champagne from order. Special order for anniversary party this weekend.'
                WHEN 6 THEN 'Invoice vs delivery mismatch. Short 3 cases of beer. Need delivery today if possible.'
                WHEN 7 THEN 'Ordered mixed case but only got 8 bottles instead of 12. Charged for full case.'
                WHEN 8 THEN 'Missing promotional items that were supposed to come with order. Glassware and POS materials.'
                ELSE 'Short delivery - missing 2 cases from order. Inventory counts don''t match invoice.'
            END
        WHEN 'Late Delivery' THEN
            CASE MOD(Support_Case_ID, 10)
                WHEN 0 THEN 'Delivery 3 days late. Had to emergency order from competitor. Already committed to customers.'
                WHEN 1 THEN 'Shipment was supposed to arrive Thursday for weekend. Now Monday - missed entire weekend sales.'
                WHEN 2 THEN 'Critical late delivery. Wedding reception in 4 hours, still no champagne order. Bride is furious.'
                WHEN 3 THEN 'Delivery missed by 2 days. Had to comp drinks to customers, lost revenue on featured items.'
                WHEN 4 THEN 'Late by full week. Special order for corporate event already happened. Cannot use this product now.'
                WHEN 5 THEN 'Shipment delayed, no communication from company. Found out after calling multiple times.'
                WHEN 6 THEN 'Promised delivery Friday AM for weekend inventory. Showed up Monday afternoon. Unacceptable.'
                WHEN 7 THEN '4 days late on seasonal product. Lost opportunity to sell during holiday weekend rush.'
                WHEN 8 THEN 'Time-sensitive order for tasting event. Arrived 2 days late, event already over. Need refund.'
                ELSE 'Late delivery caused us to run out of key products. Customers went elsewhere. Lost business.'
            END
        WHEN 'Temperature Issue' THEN
            CASE MOD(Support_Case_ID, 8)
                WHEN 0 THEN 'Wine delivered warm in 85 degree weather. No refrigeration in truck. Cork pushed out on 3 bottles.'
                WHEN 1 THEN 'Temperature-sensitive products left in hot truck for 2+ hours. Wine may be cooked. Requesting credit.'
                WHEN 2 THEN 'Product frozen during transport. Several bottles show ice crystals. Wine quality compromised.'
                WHEN 3 THEN 'Delivery truck was not climate controlled. Heat damage visible on wine labels and corks.'
                WHEN 4 THEN 'Found bottles hot to touch upon delivery. Summer heat exposure. Concerned about quality.'
                WHEN 5 THEN 'Chardonnay delivered at room temp instead of chilled. Had event starting in 2 hours, had to scramble.'
                WHEN 6 THEN 'Cases left outside in sun by driver. Bottles were 90+ degrees. Cannot serve this wine.'
                ELSE 'Temperature abuse evident. Corks dried out, bottles show heat damage. Product not saleable.'
            END
        ELSE 'General customer complaint requiring investigation and resolution.'
    END AS Description
FROM Cases_With_Resolution;

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
FROM Sales
UNION ALL
SELECT 
    'Total Support Cases',
    COUNT(*)
FROM Support_Cases;

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

-- Support Cases by Type and Status
SELECT 
    sc.Case_Type,
    sc.Status,
    COUNT(sc.Support_Case_ID) AS Case_Count,
    ROUND(AVG(sc.Resolution_Time_Days), 1) AS Avg_Resolution_Days,
    ROUND(AVG(sc.Customer_Satisfaction_Score), 2) AS Avg_Satisfaction_Score
FROM Support_Cases sc
GROUP BY sc.Case_Type, sc.Status
ORDER BY Case_Count DESC;

-- ================================================================
-- SETUP COMPLETE
-- ================================================================
SELECT 'RNDC Lab Data Setup Complete!' AS Status;