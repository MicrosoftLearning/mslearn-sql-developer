---
lab:
    title: 'Lab 6 - Optimize query performance'
    module: 'Optimize database performance'
---

# Optimize query performance

**Estimated Time: 45 minutes**

In this exercise, you investigate slow queries in Azure SQL Database using execution plans, dynamic management views (DMVs), and Query Store. You build a realistic workload and identify a missing index through the execution plan. You then simulate a parameter sniffing regression with a stored procedure and skewed data. You use the Top Resource Consuming Queries view in SSMS to detect the regression and force a better plan. You also apply a Query Store hint and diagnose a blocking scenario between two writers.

You're a database administrator for Adventure Works. After a recent deployment, the customer service team reports that order lookups are slower than before. You use execution plans to find the root cause, Query Store to confirm the regression and fix it, and DMVs to investigate a blocking issue reported by the warehouse team.

> &#128221; These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Prerequisites

- An [Azure subscription](https://azure.microsoft.com/free)
- SQL Server Management Studio (SSMS) for the Query Store GUI sections
- Basic familiarity with Azure SQL Database and T-SQL

---

## Provision an Azure SQL Database

First, create an Azure SQL Database with sample data.

> &#128221; Skip this section if you already have an AdventureWorksLT Azure SQL Database provisioned.

1. Sign in to the [Azure portal](https://portal.azure.com).
1. Navigate to the **Azure SQL** page, and then select **+ Create**.
1. Select **SQL databases**, **Single database**, and then select the **Create** button.
1. Fill in the required information on the **Create SQL Database** page:

    | Setting | Value |
    | --- | --- |
    | **Subscription** | Select your Azure subscription. |
    | **Resource group** | Select or create a resource group. |
    | **Database name** | *AdventureWorksLT* |
    | **Server** | Select **Create new** and create a new server with a unique name. You should use **Use Microsoft Entra-only authentication** for more secure access, or **Use both SQL and Microsoft Entra authentication**/**SQL authentication** with an admin sign in and password, but note that *Microsoft Entra-only authentication* is recommended. |
    | **Workload environment** | *Development* |
    | **Backup storage redundancy** | *Locally-redundant backup storage* |

1. Select **Next: Networking** and configure the following settings:

    | Setting | Value |
    | --- | --- |
    | **Connectivity method** | *Public endpoint* |
    | **Allow Azure services and resources to access this server** | *Yes* |
    | **Add current client IP address** | *Yes* |

1. Select **Next: Security**, then select **Next: Additional settings**.
1. On the **Additional settings** page, set **Use existing data** to *Sample* to create the AdventureWorksLT sample database.
1. Select **Review + create**, review the settings, and then select **Create**.
1. Wait for the deployment to complete, then navigate to the new Azure SQL Database resource.

---

## Create the test workload

The AdventureWorksLT sample database has product and customer data, but its tables are small. You need a larger table to produce meaningful execution plans and query statistics. In this section, you create an `OrderHistory` table with 80,000 rows that simulates a year of order data.

1. Connect to your Azure SQL Database using SSMS.
1. Run the following script to create and populate the `OrderHistory` table:

    ```sql
    DROP TABLE IF EXISTS dbo.OrderHistory;

    CREATE TABLE dbo.OrderHistory (
        OrderID INT IDENTITY(1,1) PRIMARY KEY,
        CustomerID INT NOT NULL,
        ProductID INT NOT NULL,
        OrderDate DATETIME NOT NULL,
        Quantity INT NOT NULL,
        UnitPrice DECIMAL(10,2) NOT NULL,
        TotalAmount AS (Quantity * UnitPrice) PERSISTED,
        Status NVARCHAR(20) NOT NULL
    );

    -- Insert 80,000 rows referencing real AdventureWorksLT customers and products
    INSERT INTO dbo.OrderHistory (CustomerID, ProductID, OrderDate, Quantity, UnitPrice, Status)
    SELECT TOP 80000
        c.CustomerID,
        p.ProductID,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
        ABS(CHECKSUM(NEWID())) % 10 + 1,
        p.ListPrice,
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN N'Pending'
            WHEN 1 THEN N'Processing'
            WHEN 2 THEN N'Shipped'
            ELSE N'Delivered'
        END
    FROM SalesLT.Customer AS c
    CROSS JOIN SalesLT.Product AS p
    ORDER BY NEWID();
    ```

    > &#128221; This script creates realistic order data by combining actual customers and products from the AdventureWorksLT sample database. The `TotalAmount` column is a computed column, which means the engine calculates it automatically from `Quantity * UnitPrice`.

1. Verify the table was created and populated:

    ```sql
    SELECT COUNT(*) AS TotalOrders FROM dbo.OrderHistory;
    GO
    ```

    > &#128221; You should see **80,000** rows.

---

## Enable and configure Query Store

Query Store captures query text, execution plans, and runtime statistics directly inside the database. Enable it with recommended settings before you start running queries, so it captures everything from this point forward.

1. Run the following script to enable Query Store and clear any previous data:

    ```sql
    ALTER DATABASE CURRENT SET QUERY_STORE = ON (
        OPERATION_MODE = READ_WRITE,
        QUERY_CAPTURE_MODE = AUTO,
        WAIT_STATS_CAPTURE_MODE = ON
    );
    GO

    -- Clear any prior data so only this exercise's queries appear
    ALTER DATABASE CURRENT SET QUERY_STORE CLEAR;
    GO
    ```

    > &#128221; Clearing the Query Store ensures you see only the queries from this exercise, which makes the regression easier to spot later. This sh

1. Verify that Query Store is active:

    ```sql
    SELECT actual_state_desc, desired_state_desc,
        current_storage_size_mb, max_storage_size_mb
    FROM sys.database_query_store_options;
    ```

    > &#128221; The `actual_state_desc` should show `READ_WRITE`. If it shows `READ_ONLY`, Query Store has run out of space. Increase the maximum storage size with `ALTER DATABASE CURRENT SET QUERY_STORE (MAX_STORAGE_SIZE_MB = 200);`.

---

## Analyze execution plans and add a missing index

Execution plans show you the exact operators, data access methods, and cost estimates the optimizer chose for a query. In this section, you run a query that performs poorly, read the plan to understand why, and fix it with a covering index.

1. In SSMS, select **Include Actual Execution Plan** (Ctrl+M) to enable plan capture.

1. Run the following query that the customer service team uses to look up recent orders for a customer:

    ```sql
    SET STATISTICS IO ON;

    SELECT
        oh.OrderID,
        oh.OrderDate,
        p.Name AS ProductName,
        oh.Quantity,
        oh.UnitPrice,
        oh.TotalAmount,
        oh.Status
    FROM dbo.OrderHistory AS oh
    INNER JOIN SalesLT.Product AS p
        ON oh.ProductID = p.ProductID
    WHERE oh.CustomerID = 29485
        AND oh.OrderDate >= DATEADD(MONTH, -3, GETDATE())
    ORDER BY oh.OrderDate DESC;

    SET STATISTICS IO OFF;
    ```

1. Select the **Execution Plan** tab and examine the plan. Look for the following:

    - **Clustered Index Scan** on `OrderHistory`. The engine reads every row because there's no index on `CustomerID` or `OrderDate`.
    - **Estimated vs Actual Number of Rows** on the scan operator. Hover over the scan operator and compare these values. A large difference indicates stale statistics.
    - **Missing index suggestion** in green text at the top of the plan, this message means the optimizer thinks an index could help this query.

1. Right-click anywhere on the execution plan and select **Missing Index Details...**. SSMS opens a new query window with a scripted `CREATE INDEX` statement similar to the following:

    ```sql
    /*
    Missing Index Details from SQLQuery123.sql - <yourservername>.database.windows.net.AdventureWorksLT (<username>) (51)
    The Query Processor estimates that implementing the following index could improve the query cost by 95.0604%.
    */

    /*
    USE [AdventureWorksLT]
    GO
    CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
    ON [dbo].[OrderHistory] ([CustomerID],[OrderDate])
    INCLUDE ([ProductID],[Quantity],[UnitPrice],[TotalAmount],[Status])
    GO
    */
    ```

    > &#128221; The optimizer tells you exactly which columns it wants as key columns and which as included columns. Notice it includes `TotalAmount` in the INCLUDE list even though it's a persisted computed column. The percentage estimate tells you how much the optimizer expects the query cost to decrease if you add this index.

1. Switch to the **Messages** tab and note the `logical reads` value for `OrderHistory`. This value is the number of 8-KB pages the engine read to execute the query.

1. Create the covering index. Rather than using the exact suggestion from the plan, add a `DESC` sort on `OrderDate` so the engine reads the most recent orders first without an extra sort:

    ```sql
    CREATE NONCLUSTERED INDEX IX_OrderHistory_CustomerDate
    ON dbo.OrderHistory (CustomerID, OrderDate DESC)
    INCLUDE (ProductID, Quantity, UnitPrice, Status);
    ```

    > &#128221; This index uses a compound key on `CustomerID` and `OrderDate DESC`. The engine can seek directly to the customer's rows, and the `DESC` order means it reads the most recent orders first without an extra sort. The included columns prevent Key Lookups back to the clustered index, making this a **covering index**.

1. Run the same query again. In the execution plan, you should now see an **Index Seek** on `IX_OrderHistory_CustomerDate` instead of a Clustered Index Scan. In the **Messages** tab, compare the new `logical reads` value to the previous one.

    > &#128221; The reduction in logical reads should be dramatic. Fewer reads mean less I/O, lower CPU usage, and faster response times for the customer service team.

---

## Use DMVs to find the most expensive queries

Execution plans examine one query at a time. DMVs give you a broader view across all queries in the database, which helps you find the most expensive ones before diving into individual plans.

1. Run the following query to find the top five queries by average CPU time:

    ```sql
    SELECT TOP 5
        qs.total_worker_time / qs.execution_count AS avg_cpu_time_us,
        qs.execution_count,
        qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
        SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
            ((CASE qs.statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE qs.statement_end_offset
            END - qs.statement_start_offset) / 2) + 1) AS query_text
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
    ORDER BY avg_cpu_time_us DESC;
    ```

    > &#128221; The results show aggregate performance statistics for cached query plans. Look for queries with high `avg_logical_reads`. A query with high logical reads relative to the number of rows it returns is a strong candidate for index tuning.

1. The existing `IX_OrderHistory_CustomerDate` index covers queries that filter by `CustomerID`, but the warehouse team also runs a report that filters by `Status` and joins to the `Product` table. Run this query a few times so the optimizer registers the missing index:

    ```sql
    SELECT
        p.Name AS ProductName,
        p.ProductNumber,
        oh.OrderDate,
        oh.Quantity,
        oh.TotalAmount
    FROM dbo.OrderHistory AS oh
    INNER JOIN SalesLT.Product AS p
        ON oh.ProductID = p.ProductID
    WHERE oh.Status = N'Pending'
        AND oh.OrderDate >= DATEADD(MONTH, -1, GETDATE())
    ORDER BY oh.TotalAmount DESC;
    GO 5
    ```

    > &#128221; This query needs an index on `Status` and `OrderDate`, which is different from the existing index on `CustomerID` and `OrderDate`. Running it multiple times ensures the optimizer accumulates enough statistics for the missing index DMVs.

1. Now query the missing index DMVs to see what the optimizer recommends across the entire workload:

    ```sql
    SELECT TOP 10
        mid.statement AS table_name,
        mid.equality_columns,
        mid.inequality_columns,
        mid.included_columns,
        ROUND(migs.avg_total_user_cost * migs.avg_user_impact *
            (migs.user_seeks + migs.user_scans), 2) AS improvement_measure
    FROM sys.dm_db_missing_index_groups AS mig
    INNER JOIN sys.dm_db_missing_index_group_stats AS migs
        ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details AS mid
        ON mig.index_handle = mid.index_handle
    ORDER BY improvement_measure DESC;
    ```

    > &#128221; You should see a recommendation with `Status` as an equality column and `OrderDate` as an inequality column. The `improvement_measure` combines the average query cost, the estimated improvement percentage, and how often the query runs. Higher values mean greater benefit. These are recommendations, not directives. Always test a new index on both read and write performance before adding it to production.

---

## Simulate and detect a plan regression with Query Store

Parameter sniffing is a common cause of plan regressions. The optimizer compiles a plan based on the first parameter value it sees and caches that plan. All future calls reuse the cached plan, even when a different plan would perform better. In this section, you cause a parameter sniffing regression using a stored procedure, detect it with the Query Store GUI, and force the better plan.

### Set up the regression scenario

1. Clear Query Store and reconfigure it so every stored procedure call is recorded:

    ```sql
    ALTER DATABASE CURRENT SET QUERY_STORE CLEAR;
    GO

    ALTER DATABASE CURRENT SET QUERY_STORE (
        QUERY_CAPTURE_MODE = ALL
    );
    GO
    ```

    > &#128221; `QUERY_CAPTURE_MODE = ALL` ensures every execution is recorded, including short stored procedure calls that the default `AUTO` mode might skip. In production, you would typically keep the default `AUTO` capture mode to focus on more expensive queries.

1. Replace the covering index with a noncovering one. Without INCLUDE columns, the optimizer must decide between an index seek with key lookups (fast for few rows) and a full table scan (cheaper when there are many key lookups). This decision is what makes parameter sniffing possible:

    ```sql
    DROP INDEX IF EXISTS IX_OrderHistory_CustomerDate ON dbo.OrderHistory;
    ```

    > &#128221; Dropping the index ensures that the new non-covering index can be created without conflicts.

    ```sql
    CREATE NONCLUSTERED INDEX IX_OrderHistory_CustomerDate
    ON dbo.OrderHistory (CustomerID, OrderDate DESC);
    ```

    > &#128221; The covering index from the earlier section always used an index seek regardless of how many rows matched. By removing the INCLUDE columns, the optimizer now has to weigh the cost of key lookups, which makes it sensitive to the estimated number of rows.

1. Add skewed data so one customer has far more orders than others. This skewed data creates the conditions for parameter sniffing by giving the optimizer a reason to choose different plans for different customers:

    ```sql
    INSERT INTO dbo.OrderHistory (CustomerID, ProductID, OrderDate, Quantity, UnitPrice, Status)
    SELECT TOP 50000
        1,
        p.ProductID,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
        ABS(CHECKSUM(NEWID())) % 10 + 1,
        p.ListPrice,
        N'Pending'
    FROM SalesLT.Product AS p
    CROSS JOIN SalesLT.Product AS p2
    ORDER BY NEWID();
    ```

    > &#128221; CustomerID 1 now has over 50,000 rows, while most other customers have fewer than 100. This extreme skew is what makes the optimizer choose different access methods for different parameter values.

1. Update statistics so the optimizer knows about the new data distribution:

    ```sql
    UPDATE STATISTICS dbo.OrderHistory;
    ```

1. Create a stored procedure that wraps the customer order query. Stored procedures cache their execution plans, which is what makes parameter sniffing happen:

    ```sql
    CREATE OR ALTER PROCEDURE dbo.GetCustomerOrders
        @CustomerID INT
    AS
    BEGIN
        SELECT
            oh.OrderID,
            oh.OrderDate,
            p.Name AS ProductName,
            oh.Quantity,
            oh.UnitPrice,
            oh.TotalAmount,
            oh.Status
        FROM dbo.OrderHistory AS oh
        INNER JOIN SalesLT.Product AS p
            ON oh.ProductID = p.ProductID
        WHERE oh.CustomerID = @CustomerID
        ORDER BY oh.OrderDate DESC;
    END;
    ```

### Cause the regression

1. Clear the procedure cache and compile the **fast plan** by running the procedure with **CustomerID 29485** (fewer than 100 rows). The optimizer compiles a plan with an **Index Seek**:

    ```sql
    ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
    GO

    EXEC dbo.GetCustomerOrders @CustomerID = 29485;
    GO 10
    ```

1. Now clear the cache and compile the **slow plan** by calling with **CustomerID 1** (50,000+ rows). The optimizer compiles a **Clustered Index Scan** because scanning the whole table is cheaper than performing 50,000 key lookups:

    ```sql
    ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
    GO

    EXEC dbo.GetCustomerOrders @CustomerID = 1;
    ```

1. Run the procedure with **CustomerID 29485** again. The optimizer **reuses the cached scan plan** even though the seek plan was faster for this customer:

    ```sql
    EXEC dbo.GetCustomerOrders @CustomerID = 29485;
    GO 10
    ```

    > &#128221; This is the regression. The plan compiled for 50,000 rows is being reused for a customer with fewer than 100 rows. The Clustered Index Scan reads every row in the table when it only needs a handful. In production, this often shows up as a query that was "fast yesterday and slow today" after a plan cache recycle.

1. Flush Query Store data to disk so the GUI can display the results immediately:

    ```sql
    EXEC sp_query_store_flush_db;
    ```

### Use the Query Store GUI to find and fix the regression

1. In SSMS Object Explorer, expand your database node.
1. Expand the **Query Store** folder.
1. Select **Top Resource Consuming Queries**.

    > &#128221; This view shows the queries that consume the most resources, sorted by the metric you choose. It's the most common starting point for performance tuning because it immediately tells you which queries to investigate first.

1. If not already set, use the dropdowns at the top to set the metric to **Duration (ms)**, the statistic to **Total**, and the time range to **Last hour**. The time interval is found by selecting the *Configure* button.
1. Select the tallest bar in the left pane. This script should be the `GetCustomerOrders` query. The right pane shows a **Plan summary** chart where each circle represents a different execution plan.
1. Observe that there are two plans with very different durations. Select the circle with the **higher duration** (the scan plan). The plan details appear at the bottom. Notice the **Clustered Index Scan** operator.
1. Select the circle with the **lower duration** (the seek plan). Notice the **Index Seek** operator.
1. With the faster plan selected, select the **Force Plan** button in the toolbar. A confirmation dialog appears. Select **Yes**.

    > &#128221; Plan forcing tells the optimizer to always use the seek plan for this query, regardless of which parameter value is passed. The index still exists, so the forced plan executes successfully. This is a quick fix that doesn't require modifying application code or the stored procedure.

1. Now navigate to **Queries With Forced Plans** under the Query Store folder. Verify that your query appears in the list with the forced plan.

### Verify plan forcing with T-SQL

1. Confirm the forced plan:

    ```sql
    SELECT
        q.query_id,
        p.plan_id,
        p.is_forced_plan,
        p.force_failure_count,
        qt.query_sql_text
    FROM sys.query_store_plan AS p
    INNER JOIN sys.query_store_query AS q
        ON p.query_id = q.query_id
    INNER JOIN sys.query_store_query_text AS qt
        ON q.query_text_id = qt.query_text_id
    WHERE p.is_forced_plan = 1;
    ```

    > &#128221; The `is_forced_plan` column should show **1**. The `force_failure_count` should be **0** because the index the plan depends on still exists. If this value were nonzero, it would mean the forced plan can't execute and the optimizer is falling back to a different plan.

1. Test the forced plan by running the procedure again. The optimizer uses the forced seek plan regardless of the parameter value:

    ```sql
    EXEC dbo.GetCustomerOrders @CustomerID = 29485;
    ```

1. To confirm the seek plan is used there as well, now let's run the procedure with the other parameter value:

    ```sql
    EXEC dbo.GetCustomerOrders @CustomerID = 1;
    ```

    > &#128221; Even though CustomerID 1 has 50,000+ rows, the optimizer still uses the seek plan because it's forced. This may lead to slower performance for that customer, but it prevents the regression for all other customers. In production, you would typically use this as a temporary mitigation while you work on a more permanent fix, such as rewriting the query or adding an index.

1. Review the execution plan for both parameter values. For @CustomerID = 29485, you might see a warning on the SELECT operator about too much memory allocated. For @CustomerID = 1, you might see a temporary spill to disk on the Sort operator.


1. Restore the covering index and clean up the stored procedure for the remaining exercises:

    ```sql
    DROP PROCEDURE IF EXISTS dbo.GetCustomerOrders;

    DROP INDEX IX_OrderHistory_CustomerDate ON dbo.OrderHistory;

    CREATE NONCLUSTERED INDEX IX_OrderHistory_CustomerDate
    ON dbo.OrderHistory (CustomerID, OrderDate DESC)
    INCLUDE (ProductID, Quantity, UnitPrice, Status);
    ```

---

## Apply a Query Store hint

Sometimes you need to shape query execution without modifying application code. Query Store hints let you attach a hint to a specific query through Query Store. In this section, you run a heavy aggregation query that goes parallel, then apply a `MAXDOP 1` hint to force it to a single thread.

1. In SSMS, select **Include Actual Execution Plan** (Ctrl+M) if it isn't already enabled, and run the following query. This query groups orders by customer, product, category, and status, then applies multiple window functions with different partitions. Each partition requires a separate sort, which drives up the query cost:

    ```sql
    SELECT
        oh.CustomerID,
        p.Name AS ProductName,
        pc.Name AS CategoryName,
        oh.Status,
        COUNT(*) AS OrderCount,
        SUM(oh.TotalAmount) AS TotalRevenue,
        AVG(oh.TotalAmount) AS AvgOrderValue,
        STDEV(oh.TotalAmount) AS StdDevOrderValue,
        RANK() OVER (PARTITION BY oh.Status
            ORDER BY SUM(oh.TotalAmount) DESC) AS StatusRevenueRank,
        PERCENT_RANK() OVER (PARTITION BY pc.Name
            ORDER BY AVG(oh.TotalAmount)) AS CategoryPctRank,
        SUM(COUNT(*)) OVER (PARTITION BY oh.Status) AS StatusTotalOrders
    FROM dbo.OrderHistory AS oh
    INNER JOIN SalesLT.Product AS p
        ON oh.ProductID = p.ProductID
    INNER JOIN SalesLT.ProductCategory AS pc
        ON p.ProductCategoryID = pc.ProductCategoryID
    GROUP BY oh.CustomerID, p.Name, pc.Name, oh.Status
    ORDER BY TotalRevenue DESC;
    ```

1. Select the **Execution Plan** tab. Look for parallelism arrows (small yellow arrows) on operators like Hash Match, Sort, or Clustered Index Scan. These arrows indicate the optimizer chose a parallel plan. You should also see a **Gather Streams** operator that combines results from multiple threads.

    > &#128221; This query is expensive because grouping by `CustomerID, ProductName, CategoryName, Status` produces thousands of groups, and the three window functions use different `PARTITION BY` columns. Each distinct partition requires a separate sort pass over the results. The optimizer chooses a parallel plan because the estimated cost exceeds the cost threshold for parallelism (default 5).

1. Find the `query_id` for this query in Query Store:

    ```sql
    SELECT q.query_id, qt.query_sql_text
    FROM sys.query_store_query_text AS qt
    INNER JOIN sys.query_store_query AS q
        ON qt.query_text_id = q.query_text_id
    WHERE qt.query_sql_text LIKE '%RevenueRank%PARTITION%'
        AND qt.query_sql_text NOT LIKE '%query_store%';
    ```

    > &#128221; Note the `query_id` value. You use it in the next steps to apply and clear the hint.

1. Apply a `MAXDOP 1` hint to force the query to run on a single thread:

    ```sql
    EXEC sp_query_store_set_hints
        @query_id = <query_id>,
        @query_hints = N'OPTION (MAXDOP 1)';
    ```

    > &#128221; Replace `<query_id>` with the actual value from the previous step. The `MAXDOP 1` hint forces the query to run on a single thread. This is useful for queries where parallelism overhead is greater than the benefit, or when you want to reduce CPU consumption on a shared server.

1. Run the aggregation query again and check the execution plan. The parallelism arrows should be gone. All operators run on a single thread, and the Gather Streams operator no longer appears.

    > &#128221; Compare the execution times. For this query, the parallel plan is likely faster because the aggregation and window function benefit from multiple threads. The single-threaded plan uses less CPU overall but takes longer wall-clock time. This tradeoff is exactly what `MAXDOP` controls.

1. Remove the hint when you're done testing:

    ```sql
    EXEC sp_query_store_clear_hints @query_id = <query_id>;
    ```

    > &#128221; Query Store hints override statement-level hints and plan guides. They give you full control over query behavior without touching application code. In production, use them carefully and document which queries have hints applied.

---

## Identify and resolve blocking

In Azure SQL Database, Read Committed Snapshot Isolation (RCSI) is enabled by default, so read operations don't block writes. However, two write operations that target the same row still block each other. In this section, you simulate a blocking scenario the warehouse team reported and use DMVs to diagnose it.

1. Open **three separate query windows** in SSMS, all connected to the same database. Label them mentally as Window 1, Window 2, and Window 3.

1. In **Window 1**, start a transaction that updates an order's status but doesn't commit. This query simulates a warehouse application that crashed mid-transaction:

    ```sql
    BEGIN TRANSACTION;
    UPDATE dbo.OrderHistory SET Status = N'Cancelled' WHERE OrderID = 1;
    -- Simulating an application that stopped without committing
    ```

1. In **Window 2**, try to update the same row. This query simulates another warehouse worker processing the same order:

    ```sql
    UPDATE dbo.OrderHistory SET Status = N'Shipped' WHERE OrderID = 1;
    ```

    > &#128221; This query hangs. It is blocked because Window 1 holds an exclusive lock on the row and hasn't committed.

1. In **Window 3**, identify the blocking chain and investigate what the head blocker is doing:

    ```sql
    -- Find blocked sessions
    SELECT
        r.session_id AS blocked_session,
        r.blocking_session_id AS head_blocker,
        r.wait_type,
        r.wait_time AS wait_time_ms,
        r.wait_resource,
        t.text AS blocked_query
    FROM sys.dm_exec_requests AS r
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
    WHERE r.blocking_session_id <> 0;
    ```

    > &#128221; The `wait_type` should be `LCK_M_X` (waiting for an exclusive lock). The `wait_resource` identifies the exact row. The `head_blocker` column shows you which session to investigate.

1. Continuing in **Window 3**, investigate what the head blocker session is doing:

    ```sql
    -- Investigate the head blocker
    SELECT
        s.session_id,
        s.status,
        s.login_time,
        s.program_name,
        s.host_name,
        t.text AS last_query,
        c.connect_time,
        s.last_request_start_time,
        s.last_request_end_time
    FROM sys.dm_exec_sessions AS s
    LEFT JOIN sys.dm_exec_connections AS c
        ON s.session_id = c.session_id
    CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) AS t
    WHERE s.session_id = <blocking_session_id>;
    ```

    > &#128221; Replace `<blocking_session_id>` with the value from the previous result. Notice the `status` column shows `sleeping`, which means the session executed a statement but is now idle with an open transaction. This is one of the most common blocking patterns: a sleeping session with an uncommitted transaction.

1. In **Window 1**, resolve the block by rolling back the transaction:

    ```sql
    ROLLBACK TRANSACTION;
    ```

1. Switch to **Window 2** and confirm the update completed.

    > &#128221; In production, keep transactions short by executing only the minimum required statements and committing immediately. Use `TRY...CATCH` blocks in your T-SQL and roll back in the `CATCH` block so that a runtime error doesn't leave a transaction open. Consider using `SET XACT_ABORT ON` in stored procedures that begin transactions, so that any runtime error automatically rolls back the open transaction. If an orphaned session is blocking others, you can terminate it with `KILL <session_id>;`.

---

## Cleanup

Drop the test table and stored procedure you created during this exercise:

```sql
DROP PROCEDURE IF EXISTS dbo.GetCustomerOrders;
DROP TABLE IF EXISTS dbo.OrderHistory;
```

Unforce any forced plans and clear Query Store hints to leave the database in a clean state:

```sql
-- Unforce all plans
DECLARE @qid INT, @pid INT;

SELECT TOP 1 @qid = q.query_id, @pid = p.plan_id
FROM sys.query_store_plan AS p
INNER JOIN sys.query_store_query AS q ON p.query_id = q.query_id
WHERE p.is_forced_plan = 1;

WHILE @@ROWCOUNT > 0
BEGIN
    EXEC sp_query_store_unforce_plan @query_id = @qid, @plan_id = @pid;

    SELECT TOP 1 @qid = q.query_id, @pid = p.plan_id
    FROM sys.query_store_plan AS p
    INNER JOIN sys.query_store_query AS q ON p.query_id = q.query_id
    WHERE p.is_forced_plan = 1;
END
```

> &#128221; This Azure SQL Database resource could be used for other labs in the course. If you're done with all labs, you can either delete the database or delete the entire resource group if you created it for this lab and it only contains this database. Deleting the resource group is a good way to ensure you don't leave any resources running that could incur costs.

---

You successfully completed this exercise.

In this exercise, you investigated query performance issues in Azure SQL Database. You analyzed execution plans to identify a missing index and created a covering index that dramatically reduced logical reads. You used DMVs to find the most expensive queries and missing index recommendations across the workload. You simulated a parameter sniffing regression using a stored procedure with skewed data, then used the Top Resource Consuming Queries view in SSMS to detect the regression and force the better plan. You applied a Query Store hint to control parallelism without changing application code. Finally, you diagnosed a writer-writer blocking scenario using DMVs to identify the head blocker, investigated the sleeping session, and resolved it.
