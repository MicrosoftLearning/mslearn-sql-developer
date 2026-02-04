---
lab:
    title: 'Lab 5 – Implement security and compliance with SQL'
    module: 'Implement security and compliance with SQL'
---

# Implement security and compliance with SQL

**Estimated Time: 30 minutes**

In this exercise, you implement security features to protect sensitive data in a SQL database. You configure Dynamic Data Masking to hide sensitive information from unauthorized users and implement Row-Level Security to filter data based on user identity.

You are a database developer who needs to protect employee and customer data while ensuring authorized users can still access the information they need.

> &#128221; These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Prerequisites

- An [Azure subscription](https://azure.microsoft.com/free)
- Visual Studio Code with the SQL Server (mssql) extension, or SQL Server Management Studio
- Basic familiarity with Azure SQL Database and T-SQL

---

## Provision an Azure SQL Database

First, create an Azure SQL Database for the security exercises.

1. Sign in to the [Azure portal](https://portal.azure.com).
1. Navigate to the **Azure SQL** page, and then select **+ Create**.
1. Select **SQL databases**, **Single database**, and then select the **Create** button.
1. Fill in the required information on the **Create SQL Database** page:

    | Setting | Value |
    | --- | --- |
    | **Subscription** | Select your Azure subscription. |
    | **Resource group** | Select or create a resource group. |
    | **Database name** | *SecurityLabDB* |
    | **Server** | Select **Create new** and create a new server with a unique name, using **SQL authentication** with an admin login and password. |
    | **Workload environment** | *Development* |
    | **Backup storage redundancy** | *Locally-redundant backup storage* |

1. Select **Next: Networking** and configure the following settings:

    | Setting | Value |
    | --- | --- |
    | **Connectivity method** | *Public endpoint* |
    | **Allow Azure services and resources to access this server** | *Yes* |
    | **Add current client IP address** | *Yes* |

1. Select **Review + create**, review the settings, and then select **Create**.
1. Wait for the deployment to complete, then navigate to the new Azure SQL Database resource.

---

## Create sample tables

Connect to the database and create sample tables with sensitive data.

1. Open Visual Studio Code and connect to your Azure SQL Database using the SQL Server extension.
1. Open a new query window and run the following script to create the sample tables:

    ```sql
    -- Create tables for the exercise
    CREATE TABLE dbo.Employees (
        EmployeeID int PRIMARY KEY IDENTITY(1,1),
        FirstName nvarchar(50) NOT NULL,
        LastName nvarchar(50) NOT NULL,
        Email nvarchar(100) NOT NULL,
        SSN char(11) NOT NULL,
        Salary decimal(18,2) NOT NULL,
        Department nvarchar(50) NOT NULL
    );

    CREATE TABLE dbo.Customers (
        CustomerID int PRIMARY KEY IDENTITY(1,1),
        CompanyName nvarchar(100) NOT NULL,
        ContactName nvarchar(100) NOT NULL,
        Phone nvarchar(20) NOT NULL,
        CreditCardNumber nvarchar(19) NOT NULL,
        SalesRegion nvarchar(20) NOT NULL
    );

    -- Insert sample data
    INSERT INTO dbo.Employees (FirstName, LastName, Email, SSN, Salary, Department)
    VALUES 
        ('Sarah', 'Chen', 'sarah.chen@contoso.com', '123-45-6789', 95000.00, 'Engineering'),
        ('Marcus', 'Johnson', 'marcus.johnson@contoso.com', '234-56-7890', 75000.00, 'Engineering'),
        ('Emily', 'Williams', 'emily.williams@contoso.com', '345-67-8901', 82000.00, 'Sales'),
        ('David', 'Brown', 'david.brown@contoso.com', '456-78-9012', 68000.00, 'Sales'),
        ('Lisa', 'Garcia', 'lisa.garcia@contoso.com', '567-89-0123', 71000.00, 'HR');

    INSERT INTO dbo.Customers (CompanyName, ContactName, Phone, CreditCardNumber, SalesRegion)
    VALUES
        ('Northwind Traders', 'John Smith', '206-555-0100', '4111-1111-1111-1111', 'West'),
        ('Adventure Works', 'Jane Doe', '425-555-0150', '5500-0000-0000-0004', 'East'),
        ('Fabrikam Inc', 'Bob Wilson', '503-555-0175', '3400-0000-0000-009', 'West'),
        ('Contoso Ltd', 'Alice Brown', '360-555-0125', '6011-0000-0000-0004', 'East');
    ```

---

## Implement Dynamic Data Masking

Dynamic Data Masking hides sensitive data from non-privileged users by masking it in query results.

1. Add masks to the `Employees` table to protect sensitive columns:

    ```sql
    -- Mask SSN to show only last 4 digits
    ALTER TABLE dbo.Employees
    ALTER COLUMN SSN ADD MASKED WITH (FUNCTION = 'partial(0, "XXX-XX-", 4)');

    -- Mask Salary with a random value
    ALTER TABLE dbo.Employees
    ALTER COLUMN Salary ADD MASKED WITH (FUNCTION = 'random(50000, 150000)');

    -- Mask Email to show first character and domain
    ALTER TABLE dbo.Employees
    ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
    ```

1. Add masks to the `Customers` table:

    ```sql
    -- Mask credit card to show only last 4 digits
    ALTER TABLE dbo.Customers
    ALTER COLUMN CreditCardNumber ADD MASKED WITH (FUNCTION = 'partial(0, "XXXX-XXXX-XXXX-", 4)');

    -- Mask phone number to show only last 4 digits
    ALTER TABLE dbo.Customers
    ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = 'partial(0, "XXX-XXX-", 4)');
    ```

1. Create a test user without UNMASK permission and verify masking works:

    ```sql
    -- Create a user without UNMASK permission
    CREATE USER MaskedViewer WITHOUT LOGIN;
    GRANT SELECT ON dbo.Employees TO MaskedViewer;
    GRANT SELECT ON dbo.Customers TO MaskedViewer;

    -- Query as the masked user (data appears masked)
    EXECUTE AS USER = 'MaskedViewer';
    SELECT FirstName, LastName, Email, SSN, Salary FROM dbo.Employees;
    SELECT CompanyName, ContactName, Phone, CreditCardNumber FROM dbo.Customers;
    REVERT;

    -- Query as admin (data appears unmasked)
    SELECT FirstName, LastName, Email, SSN, Salary FROM dbo.Employees;
    ```

    Notice that when running as `MaskedViewer`, the SSN shows as `XXX-XX-6789`, the email shows as `sXXX@XXXX.com`, and salary shows a random value. As an admin, you see the actual data.

---

## Implement Row-Level Security

Row-Level Security (RLS) enables you to control access to rows in a database table based on the characteristics of the user executing a query.

1. Create users representing sales representatives for different regions:

    ```sql
    -- Create users for different sales regions
    CREATE USER WestSalesRep WITHOUT LOGIN;
    CREATE USER EastSalesRep WITHOUT LOGIN;

    -- Grant SELECT permission on Customers table
    GRANT SELECT ON dbo.Customers TO WestSalesRep;
    GRANT SELECT ON dbo.Customers TO EastSalesRep;
    ```

1. Create a security schema and predicate function that filters rows based on the user's region:

    ```sql
    -- Create a schema for security objects
    CREATE SCHEMA Security;
    GO

    -- Create a function that determines which rows a user can see
    CREATE FUNCTION Security.fn_RegionFilter(@SalesRegion nvarchar(20))
    RETURNS TABLE
    WITH SCHEMABINDING
    AS
    RETURN SELECT 1 AS AccessGranted
        WHERE @SalesRegion = 
            CASE USER_NAME()
                WHEN 'WestSalesRep' THEN 'West'
                WHEN 'EastSalesRep' THEN 'East'
                ELSE @SalesRegion -- Admins see all regions
            END
           OR IS_MEMBER('db_owner') = 1;
    GO
    ```

1. Create a security policy that applies the filter function to the Customers table:

    ```sql
    -- Create security policy
    CREATE SECURITY POLICY CustomerRegionPolicy
    ADD FILTER PREDICATE Security.fn_RegionFilter(SalesRegion)
        ON dbo.Customers
    WITH (STATE = ON);
    ```

1. Test the Row-Level Security by querying as different users:

    ```sql
    -- Test as WestSalesRep (should see only West region customers)
    EXECUTE AS USER = 'WestSalesRep';
    SELECT * FROM dbo.Customers;
    REVERT;

    -- Test as EastSalesRep (should see only East region customers)
    EXECUTE AS USER = 'EastSalesRep';
    SELECT * FROM dbo.Customers;
    REVERT;

    -- Test as admin (should see all customers)
    SELECT * FROM dbo.Customers;
    ```

    The `WestSalesRep` user sees only Northwind Traders and Fabrikam Inc (West region), while `EastSalesRep` sees Adventure Works and Contoso Ltd (East region). The admin account sees all four customers.

---

## Cleanup

If you're not using the Azure SQL Database for any other purpose, you can clean up the resources you created.

1. Run the following script to remove the security objects and sample data:

    ```sql
    -- Remove security policy and function
    DROP SECURITY POLICY IF EXISTS CustomerRegionPolicy;
    DROP FUNCTION IF EXISTS Security.fn_RegionFilter;
    DROP SCHEMA IF EXISTS Security;

    -- Remove test users
    DROP USER IF EXISTS MaskedViewer;
    DROP USER IF EXISTS WestSalesRep;
    DROP USER IF EXISTS EastSalesRep;

    -- Drop tables
    DROP TABLE IF EXISTS dbo.Customers;
    DROP TABLE IF EXISTS dbo.Employees;
    ```

1. In the Azure portal, navigate to your resource group.
1. Select **Delete resource group** and confirm deletion by typing the resource group name.
1. Select **Delete** to remove all resources created in this lab.

---

You have successfully completed this exercise.

In this exercise, you learned how to implement security and compliance features in SQL databases. You practiced provisioning an Azure SQL Database, implementing Dynamic Data Masking to protect sensitive columns, and configuring Row-Level Security to filter data based on user identity. These features provide defense in depth, protecting your data at multiple layers.
