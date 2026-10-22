# World Layoffs Data Cleaning with SQL Server
This project focuses on cleaning a real-world layoffs dataset using SQL Server.

The goal of this project was to practice the data cleaning process and learn how to transform raw data into a clean and reliable dataset for future analysis. The dataset contains company layoff information from different industries and countries around the world.

## Dataset Source:
https://www.kaggle.com/datasets/swaptr/layoffs-2022

## Tools
- Microsoft SQL Server — database management and data cleaning
- SQL — querying, transforming, and validating data
- Visual Studio Code — writing and executing SQL scripts
- Docker — running SQL Server locally

## My cleaning steps
I did not clean the original table directly. I first made a staging table, so if I break something, the raw data is still safe.

1. **Create the staging table and import the data**
   I created the table `layoffs_staging` and loaded the CSV file with `BULK INSERT`. At the start I used text (NVARCHAR) for all columns, so the import does not fail because of strange values.

2. **Remove duplicates**
   I used `ROW_NUMBER()` with `PARTITION BY` on all columns. A row with `row_num` bigger than 1 is a duplicate. In SQL Server I can delete these rows directly from the CTE.

3. **Standardize the data**
   - Removed extra spaces in the company names with `TRIM`
   - Changed all the different crypto spellings in the industry column to `Crypto`
   - Changed all the different United States spellings in the country column to `United States`

4. **Check and convert the dates**
   The dates were saved as text. First I tested the conversion with `TRY_CONVERT(date, [date], 101)` to see if it works, then I updated the column.

5. **Handle missing values**
   The CSV had the text `'NULL'` and not a real SQL `NULL`. I changed the text into real `NULL` values in `total_laid_off`, `percentage_laid_off` and `industry`.

6. **Fill missing industry values**
   Airbnb had no industry, so I set it to `Travel`. For other companies I used a self join to take the industry from another row of the same company.

7. **Remove rows without useful information**
   If a row has no `total_laid_off` and no `percentage_laid_off`, there is nothing to analyze. I deleted these rows.
   
## What I Learned
### MySQL vs SQL Server
1. Deleting rows is easier in SQL Server than in MySQL. I can delete directly from a CTE.
2. The date column is written differently. In MySQL it is `date`, in SQL Server it is `[date]`.
3. `STR_TO_DATE` in MySQL is `TRY_CONVERT` in SQL Server. If a value can not be converted, `TRY_CONVERT` gives NULL and not an error
