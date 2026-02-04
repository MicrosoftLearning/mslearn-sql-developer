---
lab:
    title: 'Lab 1 – Design and implement database objects with SQL Server'
    module: 'Design and implement database objects with SQL Server'
---

# Design and implement database objects with SQL

**Estimated Time: 30 minutes**

In this exercise you will implement various database objects in SQL Server, including tables, constraints, temporal tables, JSON columns, and indexes. This exercise will help you understand how to create a robust and efficient database schema.

You are a database designer for an e-commerce platform. You need to create a database schema that includes standard tables with appropriate constraints, a temporal table for tracking price changes, JSON storage for product metadata, and partitioning for efficient historical data management.

> &#128221; These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Setup environment

If your lab virtual machine has been provided and pre-configured, you should find the lab files ready in the **C:\LabFiles** folder. *Take a moment to check, if the files are already there, skip this section*. However, if you're using your own machine or the lab files are missing, you'll need to clone them from *GitHub* to proceed.

> &#9888; **Important:** This exercise requires **SQL Server 2025** or later.

1. From the lab virtual machine or your local machine if one wasn't provided, start a Visual Studio Code session.

1. Open the command palette (Ctrl+Shift+P) and type **Git: Clone**. Select the **Git: Clone** option.

1. Paste the following URL into the **Repository URL** field and select **Enter**.

    ```url
    https://github.com/MicrosoftLearning/mslearn-sql-developer.git
    ```

1. Save the repository to the **C:\LabFiles** folder on the lab virtual machine or your local machine if one wasn't provided (create the folder if it does not exist).

---

## Create a new database

1. From the lab virtual machine or your local machine if one wasn't provided, start a SQL Server Management Studio session (SSMS).

1. When SSMS opens, by default the **Connect to Server** dialog will appear. Choose the Default instance and select **Connect**. You might need to check the **Trust server certificate** checkbox.

    > &#128221; Note that if you are using your own SQL Server instance, you will need to connect to it using the appropriate server instance name and credentials.

1. Select the **Databases** folder, and then **New Query**.

1. In the new query window, copy and paste the below T-SQL into it. Execute the query to create the database.

    ```sql
    CREATE DATABASE EcommerceDB;
    GO

    USE EcommerceDB;
    GO
    ```

1. Under the **Messages** tab, you should see a message indicating that the commands completed successfully.

---

## Create core tables with constraints

Create the foundational tables for the e-commerce system.

1. Select **New Query**. Copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Create Supplier table
    CREATE TABLE Supplier (
        SupplierID INT PRIMARY KEY IDENTITY(1,1),
        SupplierName NVARCHAR(100) NOT NULL UNIQUE,
        Country NVARCHAR(50) NOT NULL,
        Email NVARCHAR(100),
        Phone NVARCHAR(20),
        CreatedDate DATETIME2 DEFAULT GETUTCDATE()
    );

    -- Create Category table
    CREATE TABLE Category (
        CategoryID INT PRIMARY KEY IDENTITY(1,1),
        CategoryName NVARCHAR(100) NOT NULL UNIQUE,
        Description NVARCHAR(500)
    );

    -- Create Product table with constraints
    CREATE TABLE Product (
        ProductID INT PRIMARY KEY IDENTITY(1,1),
        ProductName NVARCHAR(100) NOT NULL,
        CategoryID INT NOT NULL,
        SupplierID INT NOT NULL,
        BasePrice DECIMAL(10,2) NOT NULL,
        StockQuantity INT NOT NULL DEFAULT 0,
        CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
        CHECK (BasePrice > 0),
        CHECK (StockQuantity >= 0),
        FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
        FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID),
    );

    -- Create indexes
    CREATE INDEX IX_Category ON Product(CategoryID);
    CREATE INDEX IX_Supplier ON Product(SupplierID);

    GO
    ```

1. Insert sample data into the tables. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Insert sample suppliers
    INSERT INTO Supplier (SupplierName, Country, Email, Phone)
    VALUES 
        ('Contoso Supplies', 'USA', 'contact@contoso.com', '555-0100'),
        ('Fabrikam Inc', 'Canada', 'sales@fabrikam.com', '555-0200');

    -- Insert sample categories
    INSERT INTO Category (CategoryName, Description)
    VALUES 
        ('Electronics', 'Electronic devices and accessories'),
        ('Clothing', 'Apparel and fashion items');

    -- Insert sample products
    INSERT INTO Product (ProductName, CategoryID, SupplierID, BasePrice, StockQuantity)
    VALUES 
        ('Wireless Mouse', 1, 1, 29.99, 100),
        ('Cotton T-Shirt', 2, 2, 19.99, 250);
    GO
    ```

---

## Create a temporal table for price history

Temporal tables automatically track changes over time. This task creates a price history table that maintains a full audit trail of price changes.

1. Select **New Query**. Copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Create Price History table with temporal versioning
    CREATE TABLE ProductPrice (
        PriceID INT PRIMARY KEY IDENTITY(1,1),
        ProductID INT NOT NULL,
        CurrentPrice DECIMAL(10,2) NOT NULL,
        EffectiveDate DATE,
        SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN,
        SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN,
        PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime),
        FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
    ) WITH (SYSTEM_VERSIONING = ON);
    GO

    -- Insert initial price data
    INSERT INTO ProductPrice (ProductID, CurrentPrice, EffectiveDate)
    VALUES (1, 99.99, '2025-01-01'), (2, 149.99, '2025-01-01');

    -- Update price (creates history entry)
    UPDATE ProductPrice SET CurrentPrice = 109.99 WHERE ProductID = 1;
    GO
    ```

1. Query the price history to see changes over time. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Query price history
    SELECT ProductID, CurrentPrice, SysStartTime, SysEndTime
    FROM ProductPrice
    FOR SYSTEM_TIME ALL
    WHERE ProductID = 1;
    ```

    > &#128221; Note that the temporal table shows both the current price and the previous price with their respective time ranges.

---

## Add JSON columns for metadata

JSON columns store flexible, variable data that differs by product type. This task adds metadata storage and creates an index on a frequently queried property.

1. Select **New Query**. Copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Add metadata column to Product (JSON type requires SQL Server 2025)
    ALTER TABLE Product ADD Metadata JSON;
    GO

    -- Add computed column for indexing
    ALTER TABLE Product ADD MetadataColor AS JSON_VALUE(Metadata, '$.color');
    GO

    -- Create index on the computed column
    CREATE NONCLUSTERED INDEX IX_Product_Metadata_Color
        ON Product (MetadataColor);
    GO

    -- Update products with metadata
    UPDATE Product SET Metadata = N'{"color":"blue","size":"large","material":"cotton"}'
    WHERE ProductID = 1;

    UPDATE Product SET Metadata = N'{"color":"red","size":"small","material":"silk"}'
    WHERE ProductID = 2;
    GO
    ```

1. Query the JSON data. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Query JSON data
    SELECT 
        ProductID,
        ProductName,
        JSON_VALUE(Metadata, '$.color') AS Color,
        JSON_VALUE(Metadata, '$.size') AS Size,
        JSON_VALUE(Metadata, '$.material') AS Material
    FROM Product
    WHERE JSON_VALUE(Metadata, '$.color') = 'blue';
    ```

---

## Create a partitioned order table

Partitioning divides large tables into smaller segments for faster queries and easier maintenance. This task creates a partitioned orders table.

1. Select **New Query**. Copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Create partition function for order dates
    -- Use RANGE RIGHT for date columns to keep same-day values together
    CREATE PARTITION FUNCTION PF_OrderDate (DATE)
        AS RANGE RIGHT FOR VALUES 
        ('2025-01-01', '2025-04-01', '2025-07-01', '2025-10-01');

    -- Create partition scheme (single filegroup recommended)
    CREATE PARTITION SCHEME PS_OrderDate
        AS PARTITION PF_OrderDate ALL TO ([PRIMARY]);

    -- Create partitioned Order table
    -- Include OrderDate in primary key for clustered index alignment
    CREATE TABLE [Order] (
        OrderID BIGINT IDENTITY(1,1),
        OrderDate DATE NOT NULL,
        CustomerName NVARCHAR(100) NOT NULL,
        TotalAmount DECIMAL(12,2) NOT NULL,
        OrderStatus NVARCHAR(20) DEFAULT 'Pending',
        CONSTRAINT PK_Order PRIMARY KEY (OrderID, OrderDate),
        CHECK (TotalAmount > 0),
        CHECK (OrderStatus IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'))
    ) ON PS_OrderDate(OrderDate);

    -- Create partitioned index
    CREATE NONCLUSTERED INDEX IX_Order_Customer
        ON [Order](CustomerName)
        ON PS_OrderDate(OrderDate);
    GO

    -- Insert sample orders
    INSERT INTO [Order] (OrderDate, CustomerName, TotalAmount, OrderStatus) VALUES
        ('2025-01-15', 'John Smith', 299.97, 'Delivered'),
        ('2025-02-20', 'Jane Doe', 149.99, 'Shipped'),
        ('2025-06-10', 'Bob Johnson', 449.95, 'Processing');
    GO
    ```

1. Query by partition. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Query by partition
    SELECT 
        $PARTITION.PF_OrderDate(OrderDate) AS PartitionNumber,
        COUNT(*) AS OrdersInPartition,
        MIN(OrderDate) AS MinDate,
        MAX(OrderDate) AS MaxDate
    FROM [Order]
    GROUP BY $PARTITION.PF_OrderDate(OrderDate);
    ```

---

## Create order details with SEQUENCE

Sequences generate unique numbers independently of any table. This task uses a sequence for order line item identifiers.

1. Select **New Query**. Copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Create SEQUENCE for order line items
    CREATE SEQUENCE OrderLineSequence
        START WITH 1
        INCREMENT BY 1;

    -- Create OrderDetail table
    CREATE TABLE OrderDetail (
        OrderLineID INT PRIMARY KEY,
        OrderID BIGINT NOT NULL,
        OrderDate DATE NOT NULL,
        ProductID INT NOT NULL,
        Quantity INT NOT NULL,
        UnitPrice DECIMAL(10,2) NOT NULL,
        LineTotal AS (Quantity * UnitPrice),
        CHECK (Quantity > 0),
        CHECK (UnitPrice > 0),
        FOREIGN KEY (OrderID, OrderDate) REFERENCES [Order](OrderID, OrderDate),
        FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
    );
    GO

    -- Insert order details using SEQUENCE
    INSERT INTO OrderDetail (OrderLineID, OrderID, OrderDate, ProductID, Quantity, UnitPrice)
    VALUES 
        (NEXT VALUE FOR OrderLineSequence, 1, '2025-01-15', 1, 2, 99.99),
        (NEXT VALUE FOR OrderLineSequence, 1, '2025-01-15', 2, 1, 149.99),
        (NEXT VALUE FOR OrderLineSequence, 2, '2025-02-20', 1, 3, 99.99);
    GO
    ```

1. Verify the data. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    SELECT * FROM OrderDetail;
    ```

---

## Verify database objects

Run verification queries to ensure all database objects were created correctly.

1. Select **New Query**. Copy and paste the following T-SQL code into the query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Verify constraints work
    -- This should fail: negative price
    INSERT INTO Product (ProductName, CategoryID, SupplierID, BasePrice, StockQuantity)
    VALUES ('Invalid', 1, 1, -50, 10);
    ```

    > &#128221; This query should fail with a CHECK constraint violation, confirming that the constraint is working correctly.

1. Verify the JSON and partitioning queries. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    USE EcommerceDB;
    GO

    -- Verify JSON queries work
    SELECT ProductName, JSON_VALUE(Metadata, '$.color') AS Color
    FROM Product
    WHERE Metadata IS NOT NULL;

    -- Verify partitioning
    SELECT $PARTITION.PF_OrderDate(OrderDate) AS Partition, COUNT(*) AS RecordCount
    FROM [Order]
    GROUP BY $PARTITION.PF_OrderDate(OrderDate);

    -- Verify temporal table
    SELECT ProductID, CurrentPrice, SysStartTime, SysEndTime
    FROM ProductPrice FOR SYSTEM_TIME ALL
    ORDER BY ProductID, SysStartTime;
    ```

---

## Cleanup

If you are not using the database or the lab files for any other purpose, you can clean up the objects you created in this lab.

1. From the lab virtual machine or your local machine if one wasn't provided, start a SQL Server Management Studio session (SSMS).
1. When SSMS opens, by default the **Connect to Server** dialog will appear. Choose the Default instance and select **Connect**. You might need to check the **Trust server certificate** checkbox.
1. In **Object Explorer**, expand the **Databases** folder.
1. Right-click on the **EcommerceDB** database and select **Delete**.
1. In the **Delete Object** dialog, check the **Close existing connections** checkbox.
1. Select **OK**.

---

You have successfully completed this lab.

In this exercise, you've learned how to design and implement various database objects in SQL Server, including tables with constraints, temporal tables for tracking changes, JSON columns for flexible metadata storage, partitioned tables for large data sets, and sequences for generating unique identifiers.
