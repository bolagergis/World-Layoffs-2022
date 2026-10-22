===============================================================================
SQL PROJECT: WORLD LAYOFFS 2022 — DATA CLEANING
===============================================================================

Dataset source:
https://www.kaggle.com/datasets/swaptr/layoffs-2022

/*
===============================================================================
1. CREATE A STAGING TABLE AND IMPORT THE DATA
===============================================================================

-- Create a staging table for data cleaning
SELECT *
FROM dbo.layoffs;


CREATE TABLE dbo.layoffs_staging
(
    company NVARCHAR(255),
    location NVARCHAR(255),
    industry NVARCHAR(255),
    total_laid_off NVARCHAR(50),
    percentage_laid_off NVARCHAR(50),
    [date] NVARCHAR(50),
    stage NVARCHAR(100),
    country NVARCHAR(255),
    funds_raised_millions NVARCHAR(50)
);

-- Import the CSV file into the staging table.
-- The file must be available at this path inside the SQL Server container.
BULK INSERT dbo.layoffs_staging
FROM '/tmp/layoffs.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

-- Preview the imported data
SELECT TOP 10 *
FROM dbo.layoffs_staging;

-- Inspect all imported records
SELECT *
FROM dbo.layoffs_staging;


/*
===============================================================================
2. IDENTIFY AND REMOVE DUPLICATE RECORDS
===============================================================================

WITH duplicates_cte AS
(
    SELECT *,
           ROW_NUMBER() OVER
           (
               PARTITION BY
                   company,
                   location,
                   industry,
                   total_laid_off,
                   percentage_laid_off,
                   [date],
                   stage,
                   country,
                   funds_raised_millions
               ORDER BY company
           ) AS row_num
    FROM dbo.layoffs_staging
)
DELETE FROM duplicates_cte
WHERE row_num > 1;


/*
===============================================================================
3. STANDARDIZE DATA AND CORRECT INCONSISTENT VALUES
===============================================================================

-- Review distinct company names
SELECT DISTINCT company
FROM dbo.layoffs_staging;

-- Identify unnecessary spaces in company names und remove them
SELECT company,
       TRIM(company) AS company_trim
FROM dbo.layoffs_staging;

UPDATE dbo.layoffs_staging
SET company = TRIM(company);

-- Review distinct industry values
SELECT DISTINCT industry
FROM dbo.layoffs_staging
ORDER BY 1;

-- Identify inconsistent cryptocurrency industry values
SELECT *
FROM dbo.layoffs_staging
WHERE industry LIKE '%crypto%';

-- Standardize industry names beginning with 'crypto' and Verify the changes
UPDATE dbo.layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%';

SELECT DISTINCT industry
FROM dbo.layoffs_staging
ORDER BY 1;

-- Review distinct locations
SELECT DISTINCT location
FROM dbo.layoffs_staging
ORDER BY 1;

-- Review distinct countries
SELECT DISTINCT country
FROM dbo.layoffs_staging
ORDER BY 1;

-- Inspect country values beginning with 'United States'
SELECT *
FROM dbo.layoffs_staging
WHERE country LIKE 'united states%';

-- Standardize country values beginning with 'United States'
UPDATE dbo.layoffs_staging
SET country = 'United States'
WHERE country LIKE 'united states%';

-- Verify the standardized country value
SELECT country
FROM dbo.layoffs_staging
WHERE country LIKE 'united states%'
GROUP BY country;


/*
===============================================================================
4. CHECK AND CONVERT DATE VALUES
===============================================================================
TRY_CONVERT attempts to interpret the text as a date using style 101
*/

-- Test whether the text values can be converted to dates
SELECT [date],
       TRY_CONVERT(date, [date], 101) AS date_format
FROM dbo.layoffs_staging;

-- Update the date values using SQL Server date conversion
UPDATE dbo.layoffs_staging
SET [date] = TRY_CONVERT(date, [date], 101);


/*
===============================================================================
5. IDENTIFY AND HANDLE MISSING VALUES
===============================================================================
The CSV may contain the literal text 'NULL' rather than actual SQL NULL values.

-- Find records with an actual SQL NULL in total_laid_off
SELECT company,
       location,
       industry,
       total_laid_off,
       percentage_laid_off,
       [date],
       stage,
       country,
       funds_raised_millions
FROM dbo.layoffs_staging
WHERE total_laid_off IS NULL;

-- Find records with an actual SQL NULL in industry
SELECT *
FROM dbo.layoffs_staging
WHERE industry IS NULL;

-- Find records with missing or empty industry values
SELECT *
FROM dbo.layoffs_staging
WHERE industry IS NULL
   OR industry = '';

-- Inspect records where total_laid_off contains the text 'NULL'
SELECT company,
       location,
       industry,
       total_laid_off,
       percentage_laid_off,
       [date],
       stage,
       country,
       funds_raised_millions
FROM dbo.layoffs_staging
WHERE total_laid_off = 'NULL';

-- Convert the text 'NULL' into an actual SQL NULL
UPDATE dbo.layoffs_staging
SET total_laid_off = NULL
WHERE total_laid_off = 'NULL';

UPDATE dbo.layoffs_staging
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 'NULL';

UPDATE dbo.layoffs_staging
SET industry = NULL
WHERE industry = 'NULL';

-- Inspect the updated data
SELECT *
FROM dbo.layoffs_staging;


/*
===============================================================================
6. FILL MISSING INDUSTRY VALUES
===============================================================================
Airbnb is assigned the industry Travel based on the dataset's classification.
*/

-- Fill the missing industry value
UPDATE dbo.layoffs_staging
SET industry = 'Travel'
WHERE industry IS NULL
  AND company = 'Airbnb';

-- Fill missing industry values using matching company records
UPDATE t1
SET t1.industry = t2.industry
FROM dbo.layoffs_staging AS t1
JOIN dbo.layoffs_staging AS t2
    ON t1.company = t2.company
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


/*
===============================================================================
7. REMOVE RECORDS WITH INSUFFICIENT LAYOFF INFORMATION
===============================================================================

-- Review records with both layoff measures missing
SELECT *
FROM dbo.layoffs_staging
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Remove records with both layoff measures missing
DELETE FROM dbo.layoffs_staging
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
