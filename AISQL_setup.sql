-- ================================================================
-- AISQL DoorDash Demo - Setup Script
-- ================================================================
-- This script sets up the environment for the AISQL_DOORDASH_DEMO.ipynb notebook
-- by creating tables and loading data from the RNDC_LAB.TARGET.DOORDASH_IMAGES stage
-- ================================================================

-- ================================================================
-- 1. Environment Setup
-- ================================================================
USE ROLE ACCOUNTADMIN;
USE DATABASE RNDC_LAB;
USE SCHEMA RNDC_LAB.TARGET;

-- ================================================================
-- 2. Create CSV File Format
-- ================================================================
CREATE OR REPLACE FILE FORMAT RNDC_LAB.TARGET.CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = FALSE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
    NULL_IF = ('NULL', 'null', '');

-- ================================================================
-- 3. Create and Load DOORDASH_100 Table
-- ================================================================

-- Create DOORDASH_100 table based on CSV structure
    CREATE OR REPLACE TABLE RNDC_LAB.TARGET.DOORDASH_100 (
    REVIEW_ID INT,
    RESTAURANT_ID INT,
    CUSTOMER_ID INT,
    RATING FLOAT,
    REVIEW_DATE TIMESTAMP,
    ORDER_TYPE VARCHAR(50),
    REVIEW_TEXT TEXT,
    RESTAURANT_NAME VARCHAR(500),
    RESTAURANT_CUISINE_TYPE VARCHAR(100),
    PRICE_RANGE VARCHAR(10),
    RESTAURANT_LOCATION_AREA VARCHAR(100),
    RESTAURANT_LOCATION_NEIGHBORHOOD VARCHAR(100),
    RESTAURANT_LOCATION_REGION VARCHAR(50),
    RESTAURANT_OPENING_HOURS VARCHAR(50),
    RESTAURANT_HAS_DELIVERY BOOLEAN,
    RESTAURANT_HAS_TAKEOUT BOOLEAN,
    RESTAURANT_DATE_ADDED DATE,
    CUSTOMER_NAME VARCHAR(200),
    CUSTOMER_EMAIL VARCHAR(200),
    CUSTOMER_JOIN_DATE DATE,
    CUSTOMER_PREFERRED_CUISINE VARCHAR(100),
    CUSTOMER_CITY VARCHAR(100),
    CUSTOMER_STATE VARCHAR(10),
    IS_CUSTOMER_FREQUENT BOOLEAN
) COMMENT = 'DoorDash restaurant reviews with customer and restaurant metadata for AISQL demos';

-- Load data from the stage
COPY INTO RNDC_LAB.TARGET.DOORDASH_100
FROM @RNDC_LAB.TARGET.DOORDASH_IMAGES/v_doordash_100.csv
FILE_FORMAT = (FORMAT_NAME = 'RNDC_LAB.TARGET.CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- Verify data load
SELECT COUNT(*) AS total_reviews FROM RNDC_LAB.TARGET.DOORDASH_100;

-- ================================================================
-- 4. Create and Populate IMG_TBL Table
-- ================================================================

-- Create IMG_TBL table for food images
CREATE OR REPLACE TABLE RNDC_LAB.TARGET.IMG_TBL (
    IMG_FILE FILE,
    RELATIVE_PATH VARCHAR(16777216),
    SIZE NUMBER(38,0),
    LAST_MODIFIED TIMESTAMP_TZ(3),
    MD5 VARCHAR(16777216),
    ETAG VARCHAR(16777216),
    FILE_URL VARCHAR(16777216)
) COMMENT = 'Food images from stage with metadata for AISQL vision demos';

-- Populate IMG_TBL from stage directory
-- Use DIRECTORY() to get metadata and construct FILE references
INSERT INTO RNDC_LAB.TARGET.IMG_TBL (
    IMG_FILE,
    RELATIVE_PATH,
    SIZE,
    LAST_MODIFIED,
    MD5,
    ETAG,
    FILE_URL
)
SELECT
    TO_FILE('@RNDC_LAB.TARGET.DOORDASH_IMAGES/' || RELATIVE_PATH) AS IMG_FILE,
    RELATIVE_PATH,
    SIZE,
    LAST_MODIFIED,
    MD5,
    ETAG,
    BUILD_STAGE_FILE_URL(@RNDC_LAB.TARGET.DOORDASH_IMAGES, RELATIVE_PATH) AS FILE_URL
FROM DIRECTORY(@RNDC_LAB.TARGET.DOORDASH_IMAGES)
WHERE RELATIVE_PATH LIKE '%.jpg';

-- Verify image load
SELECT COUNT(*) AS total_images FROM RNDC_LAB.TARGET.IMG_TBL;

-- ================================================================
-- Setup Complete
-- ================================================================
-- The following tables are now ready for use in AISQL_DOORDASH_DEMO.ipynb:
--   - RNDC_LAB.TARGET.DOORDASH_100 (restaurant reviews)
--   - RNDC_LAB.TARGET.IMG_TBL (food images)
-- ================================================================

-- Display sample data
SELECT 'DOORDASH_100 Sample' AS dataset;
SELECT * FROM RNDC_LAB.TARGET.DOORDASH_100 LIMIT 5;

SELECT 'IMG_TBL Sample' AS dataset;
SELECT RELATIVE_PATH, SIZE, LAST_MODIFIED FROM RNDC_LAB.TARGET.IMG_TBL LIMIT 5;

