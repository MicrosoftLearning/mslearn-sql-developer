---
lab:
    title: 'Lab 3 – Write advanced T-SQL queries'
    module: 'Write advanced T-SQL queries'
---

# Write advanced T-SQL queries

**Estimated Time: 30 minutes**

In this exercise, you practice using JSON functions to build and query JSON data from the AdventureWorksLT database. You also combine JSON output with a CTE and a window function to create a practical report.

You are a database developer for an e-commerce company. The marketing team needs product data in JSON format for a web catalog, and you need to create reports that rank products within categories.

> &#128221; These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Prerequisites

- SQL Server 2022+ or Azure SQL Database
- A query tool such as SQL Server Management Studio
- A connection with read permissions
- [AdventureWorks lightweight sample database](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure) (SQL Server or Azure SQL)

---

## Connect to AdventureWorksLT

Ensure the *AdventureWorksLT* sample database is restored and available on your SQL instance. Verify connectivity:

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    -- Verify key tables in AdventureWorksLT
    SELECT TOP (5) ProductID, Name, ListPrice 
    FROM SalesLT.Product;
    
    SELECT TOP (5) ProductCategoryID, Name 
    FROM SalesLT.ProductCategory;
    ```

    Each query should return up to five rows of sample data. If any query returns no rows or fails, confirm that the *AdventureWorksLT* database is properly restored and that you have read access.

---

## Build JSON output from product data

The marketing team needs product information in JSON format for a web catalog. Start by creating a simple JSON object from the Product table.

### Create a JSON object for each product

Use `FOR JSON PATH` to convert product rows into JSON.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    SELECT 
        ProductID,
        Name,
        Color,
        ListPrice
    FROM SalesLT.Product
    WHERE Color IS NOT NULL
    ORDER BY ListPrice DESC
    FOR JSON PATH;
    ```

    This query selects products with a color value and formats the results as a JSON array. Each row becomes a JSON object with properties matching the column names. The `FOR JSON PATH` clause handles the conversion automatically.

### Create nested JSON with product categories

Add category information as a nested object.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        p.ListPrice,
        JSON_OBJECT(
            'CategoryID': pc.ProductCategoryID,
            'CategoryName': pc.Name
        ) AS Category
    FROM SalesLT.Product AS p
    INNER JOIN SalesLT.ProductCategory AS pc
        ON p.ProductCategoryID = pc.ProductCategoryID
    ORDER BY p.ListPrice DESC
    FOR JSON PATH;
    ```

    This query uses `JSON_OBJECT` to build a nested structure. The Category property contains its own JSON object with CategoryID and CategoryName. This approach keeps related data grouped together in the output.

---

## Combine JSON with a CTE and window function

Now create a more useful report that ranks products by price within each category and outputs the result as JSON.

### Write a CTE with window function ranking

First, build the query logic using a CTE and `ROW_NUMBER()`.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    WITH RankedProducts AS (
        SELECT 
            p.ProductID,
            p.Name AS ProductName,
            pc.Name AS CategoryName,
            p.ListPrice,
            ROW_NUMBER() OVER (
                PARTITION BY pc.ProductCategoryID 
                ORDER BY p.ListPrice DESC
            ) AS PriceRank
        FROM SalesLT.Product AS p
        INNER JOIN SalesLT.ProductCategory AS pc
            ON p.ProductCategoryID = pc.ProductCategoryID
        WHERE p.ListPrice > 0
    )
    SELECT 
        ProductID,
        ProductName,
        CategoryName,
        ListPrice,
        PriceRank
    FROM RankedProducts
    WHERE PriceRank <= 3
    ORDER BY CategoryName, PriceRank;
    ```

    The CTE calculates a price rank for each product within its category. The `PARTITION BY` clause restarts the numbering for each category, and `ORDER BY ListPrice DESC` assigns rank 1 to the most expensive product. The outer query filters to show only the top 3 products per category.

### Output the ranked products as JSON

Add `FOR JSON PATH` to format the results for an API.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    WITH RankedProducts AS (
        SELECT 
            p.ProductID,
            p.Name AS ProductName,
            pc.Name AS CategoryName,
            p.ListPrice,
            ROW_NUMBER() OVER (
                PARTITION BY pc.ProductCategoryID 
                ORDER BY p.ListPrice DESC
            ) AS PriceRank
        FROM SalesLT.Product AS p
        INNER JOIN SalesLT.ProductCategory AS pc
            ON p.ProductCategoryID = pc.ProductCategoryID
        WHERE p.ListPrice > 0
    )
    SELECT 
        ProductID,
        ProductName,
        CategoryName,
        ListPrice,
        PriceRank
    FROM RankedProducts
    WHERE PriceRank <= 3
    ORDER BY CategoryName, PriceRank
    FOR JSON PATH, ROOT('TopProducts');
    ```

    Adding `ROOT('TopProducts')` wraps the entire JSON array in an object with a named property. This makes the output easier to work with in applications that expect a root element.

---

## Parse JSON data with OPENJSON

Now practice reading JSON data back into rows using `OPENJSON`.

### Parse a JSON array into rows

Suppose you receive product updates as JSON. Use `OPENJSON` to convert it to a table.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    DECLARE @ProductUpdates NVARCHAR(MAX) = N'[
        {"ProductID": 680, "NewPrice": 1250.00},
        {"ProductID": 706, "NewPrice": 1450.00},
        {"ProductID": 707, "NewPrice": 38.99}
    ]';

    SELECT 
        ProductID,
        NewPrice
    FROM OPENJSON(@ProductUpdates)
    WITH (
        ProductID INT '$.ProductID',
        NewPrice DECIMAL(10,2) '$.NewPrice'
    );
    ```

    The `WITH` clause defines the schema for the output. Each JSON property maps to a column with a specified data type. The `$.PropertyName` syntax tells SQL Server which JSON path to read for each column.

### Join parsed JSON with existing data

Combine the JSON data with the Product table to see current and new prices.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    DECLARE @ProductUpdates NVARCHAR(MAX) = N'[
        {"ProductID": 680, "NewPrice": 1250.00},
        {"ProductID": 706, "NewPrice": 1450.00},
        {"ProductID": 707, "NewPrice": 38.99}
    ]';

    SELECT 
        p.ProductID,
        p.Name,
        p.ListPrice AS CurrentPrice,
        updates.NewPrice,
        updates.NewPrice - p.ListPrice AS PriceDifference
    FROM SalesLT.Product AS p
    INNER JOIN OPENJSON(@ProductUpdates)
    WITH (
        ProductID INT '$.ProductID',
        NewPrice DECIMAL(10,2) '$.NewPrice'
    ) AS updates
        ON p.ProductID = updates.ProductID;
    ```

    This query joins the parsed JSON directly with the Product table. The `OPENJSON` function with a `WITH` clause acts like a table, so you can join it just like any other data source. The result shows each product's current price alongside the proposed new price.

---

## Cleanup

If you are not using the database or the lab files for any other purpose, you can clean up the objects you created in this lab.

1. From the lab virtual machine or your local machine if one wasn't provided, start a SQL Server Management Studio session (SSMS).
1. When SSMS opens, by default the **Connect to Server** dialog will appear. Choose the Default instance and select **Connect**. You might need to check the **Trust server certificate** checkbox.
1. In **Object Explorer**, expand the **Databases** folder.
1. Right-click on the **AdventureWorksLT** database and select **Delete**.
1. In the **Delete Object** dialog, check the **Close existing connections** checkbox.
1. Select **OK**.

---

You have successfully completed this exercise.

In this exercise, you learned how to write advanced T-SQL queries using JSON functions and window functions. You practiced generating JSON output from query results using `FOR JSON PATH`, creating nested JSON structures with `JSON_OBJECT`, combining JSON output with CTEs and window functions, and parsing JSON arrays into rows using `OPENJSON` with a schema.
