---
lab:
    title: 'Lab 2 – Implement programmability objects in SQL Server'
    module: 'Implement programmability objects in SQL Server'
---

# Implement programmability objects in SQL Server

**Estimated Time: 45 minutes**

In this exercise you will create and use core SQL Server programmability objects to centralize logic and improve maintainability:

- Create a view to simplify complex queries
- Write a stored procedure to encapsulate a business operation
- Implement a scalar function for reusable calculations
- Build an inline table-valued function (`TVF`) for parameterized result sets
- Add a trigger to automatically respond to data changes

> &#128221; These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Prerequisites

- SQL Server 2019+ or Azure SQL Database
- A query tool such as SQL Server Management Studio
- A connection with `CREATE` permissions
- [AdventureWorks lightweight sample database](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure) (SQL Server or Azure SQL)

---

## Connect to AdventureWorksLT

Ensure the *AdventureWorksLT* sample database is restored and available on your SQL instance. Verify connectivity and some key tables:

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to execute this query.

    ```sql
    -- Verify key tables in AdventureWorksLT
    SELECT TOP (5) CustomerID, FirstName, LastName 
    FROM SalesLT.Customer;
    
    SELECT TOP (5) SalesOrderID, OrderDate, CustomerID 
    FROM SalesLT.SalesOrderHeader;
    
    SELECT TOP (5) ProductID, Name, ListPrice 
    FROM SalesLT.Product;
    ```

    Each query should return up to five rows of sample data. The first result set displays customer names, the second shows recent orders with dates and customer references, and the third lists products with their prices. If any query returns no rows or fails, confirm that the *AdventureWorksLT* database is properly restored and that you have read access.

---

## Create a view to simplify queries

Create a view that combines customers and their orders in AdventureWorksLT (*SalesLT* schema). This hides `JOIN` complexity from application code.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to create the view.

    ```sql
    CREATE OR ALTER VIEW SalesLT.vCustomerOrders AS
    SELECT 
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        h.SalesOrderID,
        h.OrderDate
    FROM SalesLT.Customer c
    INNER JOIN SalesLT.SalesOrderHeader h ON c.CustomerID = h.CustomerID;
    ```

1. Validate the view. Execute the following query.

    ```sql
    SELECT TOP (5) * 
    FROM SalesLT.vCustomerOrders 
    ORDER BY OrderDate DESC;
    ```

    The query returns up to five rows showing the most recent orders. Each row includes a `CustomerID`, the customer's full name, the `SalesOrderID`, and the `OrderDate`, demonstrating how the view simplifies access to joined customer and order data.

---

## Create a stored procedure to process an order

Encapsulate a business operation that adds an order line item to an existing order in AdventureWorksLT and updates the header subtotal.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to create the stored procedure.

    ```sql
    CREATE OR ALTER PROCEDURE dbo.AddOrderLineItem
    	@SalesOrderID INT,
    	@ProductID    INT,
    	@Quantity     INT
    AS
    BEGIN
    	SET NOCOUNT ON;
    	BEGIN TRANSACTION;
    
    	-- Use Product ListPrice as UnitPrice
    	DECLARE @UnitPrice DECIMAL(18,2);
    	SELECT @UnitPrice = CAST(ListPrice AS DECIMAL(18,2))
    	FROM SalesLT.Product
    	WHERE ProductID = @ProductID;
    
    	IF @UnitPrice IS NULL
    	BEGIN
    		ROLLBACK TRANSACTION;
    		THROW 50010, 'Invalid ProductID specified.', 1;
    	END
    
    	-- Ensure SalesOrderID exists
    	IF NOT EXISTS (SELECT 1 FROM SalesLT.SalesOrderHeader WHERE SalesOrderID = @SalesOrderID)
    	BEGIN
    		ROLLBACK TRANSACTION;
    		THROW 50011, 'Invalid SalesOrderID specified.', 1;
    	END
    
    	-- Insert line item (no discount)
    	INSERT INTO SalesLT.SalesOrderDetail (SalesOrderID, OrderQty, ProductID, UnitPrice, UnitPriceDiscount)
    	VALUES (@SalesOrderID, @Quantity, @ProductID, @UnitPrice, 0);
    
    	-- Update header subtotal based on current line totals
    	UPDATE h
    	SET SubTotal = d.SumLineTotal,
    		ModifiedDate = SYSUTCDATETIME()
    	FROM SalesLT.SalesOrderHeader h
    	INNER JOIN (
    		SELECT SalesOrderID, SUM(LineTotal) AS SumLineTotal
    		FROM SalesLT.SalesOrderDetail
    		WHERE SalesOrderID = @SalesOrderID
    		GROUP BY SalesOrderID
    	) d ON d.SalesOrderID = h.SalesOrderID;
    
    	COMMIT TRANSACTION;
    END;
    ```

    This stored procedure performs a transactional insert of a new line item. It first validates that the product and order exist—rolling back and throwing an error if either is invalid. After inserting the detail row with the product's list price, it recalculates the order's subtotal from all line items and updates the header. Wrapping everything in a transaction ensures the operation is atomic: either all changes succeed or none are applied.

1. Execute the following T-SQL code to test the stored procedure.

    ```sql
    -- Add a line item to an existing order (choose a valid SalesOrderID)
    DECLARE @SalesOrderID INT = (SELECT TOP 1 SalesOrderID 
                                FROM SalesLT.SalesOrderHeader 
                                ORDER BY SalesOrderID DESC);
    EXEC dbo.AddOrderLineItem @SalesOrderID = @SalesOrderID,         
                                @ProductID = 680, 
                                @Quantity = 1; -- adjust ProductID as needed
    
    SELECT TOP (5) * 
    FROM SalesLT.SalesOrderDetail 
    WHERE SalesOrderID = @SalesOrderID 
    ORDER BY SalesOrderDetailID DESC;

    SELECT SalesOrderID, SubTotal, TaxAmt, Freight, TotalDue 
    FROM SalesLT.SalesOrderHeader 
    WHERE SalesOrderID = @SalesOrderID;
    ```

---

## Create a scalar function for reusable calculations

Create a scalar function that returns the total value of an order using AdventureWorksLT line totals.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to create the function.

    ```sql
        CREATE OR ALTER FUNCTION dbo.fnOrderTotal (@OrderID INT)
        RETURNS DECIMAL(18,2)
        AS
        BEGIN
        	DECLARE @Total DECIMAL(18,2);
        	SELECT @Total = SUM(LineTotal)
        	FROM SalesLT.SalesOrderDetail
        	WHERE SalesOrderID = @OrderID;
        	RETURN ISNULL(@Total, 0.00);
        END;
    ```

1. Execute the following T-SQL code to use the function:

    ```sql
    SELECT d.SalesOrderID, dbo.fnOrderTotal(d.SalesOrderID) AS OrderTotal
    FROM SalesLT.SalesOrderDetail d
    GROUP BY d.SalesOrderID
    ORDER BY d.SalesOrderID DESC;
    ```

---

## Create an inline table-valued function (TVF)

Build a `TVF` to return orders for a given customer from AdventureWorksLT. `TVF`s are handy in `SELECT` and `JOIN` clauses.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to create the TVF.

    ```sql
    CREATE OR ALTER FUNCTION dbo.GetCustomerOrders (@CustomerID INT)
    RETURNS TABLE
    AS
    RETURN
    (
    	SELECT 
    		h.SalesOrderID,
    		h.OrderDate
    		FROM SalesLT.SalesOrderHeader h
    		WHERE h.CustomerID = @CustomerID
    );
    ```

1. Execute the following T-SQL code to query the function.

    ```sql
    SELECT * 
    FROM dbo.GetCustomerOrders(1)
    ORDER BY OrderDate DESC;
    ```

1. Execute the following T-SQL code to join the function to customers:

    ```sql
    SELECT CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName, o.SalesOrderID, o.OrderDate
    FROM SalesLT.Customer c
    INNER JOIN dbo.GetCustomerOrders(c.CustomerID) o ON 1 = 1
    WHERE c.CustomerID = 1;
    ```

---

## Create a trigger to log changes

Add a trigger that logs updates to order totals when *SalesLT* order details change. Triggers help enforce rules or capture audit trails automatically.

1. Copy and paste the following T-SQL code into a new query window. Select **Execute** to create the audit table and trigger.

    ```sql
    -- Audit table
    IF OBJECT_ID('dbo.OrderAudit') IS NULL
    BEGIN
        CREATE TABLE dbo.OrderAudit (
            AuditID     INT IDENTITY(1,1) PRIMARY KEY,
            OrderID     INT NOT NULL,
            OldTotal    DECIMAL(18,2) NULL,
            NewTotal    DECIMAL(18,2) NULL,
            ChangedAt   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
        );
    END
    GO

    -- Trigger on order details updates
    CREATE OR ALTER TRIGGER SalesLT.trg_LogOrderTotalChange
    ON SalesLT.SalesOrderDetail
    AFTER INSERT, UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;
        ;WITH A AS (
            SELECT SalesOrderID FROM inserted
            UNION
            SELECT SalesOrderID FROM deleted
        )
        INSERT INTO dbo.OrderAudit (OrderID, OldTotal, NewTotal)
        SELECT 
            a.SalesOrderID,
            d.Total,
            i.Total
        FROM (
            SELECT SalesOrderID, SUM(OrderQty * UnitPrice) AS Total
            FROM SalesLT.SalesOrderDetail
            GROUP BY SalesOrderID
        ) i
        INNER JOIN (
            SELECT SalesOrderID, SUM(OrderQty * UnitPrice) AS Total
            FROM SalesLT.SalesOrderDetail
            GROUP BY SalesOrderID
        ) d ON i.SalesOrderID = d.SalesOrderID
        INNER JOIN A a ON a.SalesOrderID = i.SalesOrderID;
    END;
    ```

1. Execute the following T-SQL code to test the trigger:

    ```sql
    -- Update an order detail to change the total
    UPDATE d
    SET OrderQty = OrderQty + 1
    FROM SalesLT.SalesOrderDetail d
    WHERE d.SalesOrderID = (SELECT TOP 1 SalesOrderID FROM SalesLT.SalesOrderHeader ORDER BY SalesOrderID DESC);
    
    SELECT TOP (5) * 
    FROM dbo.OrderAudit 
    ORDER BY AuditID DESC;
    ```

    The `SELECT` statement returns recent rows from the audit table. Each row shows the `OrderID` that was affected, the previous total (`OldTotal`), the new total (`NewTotal`) after the quantity change, and a timestamp. This confirms the trigger automatically logged the modification.

---

## Cleanup

If you are not using the database or the lab files for any other purpose, you can clean up the objects you created in this lab.

1. From the lab virtual machine or your local machine if one wasn't provided, start a SQL Server Management Studio session (SSMS).
1. When SSMS opens, by default the **Connect to Server** dialog will appear. Choose the Default instance and select **Connect**. You might need to check the **Trust server certificate** checkbox.
1. In **Object Explorer**, expand the **Databases** folder.
1. Right-click on the **AdventureWorksLT** database and select **Delete**.
1. In the **Delete Object** dialog, check the **Close existing connections** checkbox.
1. Select **OK**.

## Next steps

1. Consider adding indexes to improve performance of `JOIN` operations and filter predicates.
1. Extend the stored procedure to handle multiple line items per order.
1. Add permissions to expose the view safely to end users.

---

You have successfully completed this exercise.

In this exercise, you learned how to implement core SQL Server programmability objects, including views to simplify complex queries, stored procedures to encapsulate transactional business logic, scalar functions for reusable calculations, inline table-valued functions for parameterized result sets, and triggers to automatically capture audit trails when data changes.
