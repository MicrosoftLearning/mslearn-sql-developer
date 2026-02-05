---
lab:
    title: 'Lab 4 – Implement SQL solutions by using AI-assisted tools'
    module: 'Implement SQL solutions by using AI-assisted tools'
---

# Implement SQL solutions by using AI-assisted tools

**Estimated Time: 45 minutes**

In this exercise, you practice using AI-assisted development tools to design and implement SQL solutions. You configure GitHub Copilot in Visual Studio Code, create custom instruction files for consistent T-SQL code generation, and use Copilot to generate database objects.

You are a database developer who wants to accelerate your development workflow using AI-assisted tools. Your team has adopted GitHub Copilot to help write T-SQL code following consistent standards and best practices.

> &#128221; These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Prerequisites

- An [Azure subscription](https://azure.microsoft.com/free)
- A [GitHub account with Copilot access](https://github.com/features/copilot)
- Visual Studio Code installed on your computer
- Basic familiarity with Azure SQL Database and T-SQL

---

## Provision an Azure SQL Database

First, you need to create an Azure SQL Database to use with GitHub Copilot.

1. Sign in to the [Azure portal](https://portal.azure.com).
1. Navigate to the **Azure SQL** page, and then select **+ Create**.
1. Select **SQL databases**, **Single database**, and then select the **Create** button.
1. Fill in the required information on the **Create SQL Database** page:

    | Setting | Value |
    | --- | --- |
    | **Subscription** | Select your Azure subscription. |
    | **Resource group** | Select or create a resource group. |
    | **Database name** | *AdventureWorksLT* |
    | **Server** | Select **Create new** and create a new server with a unique name, using **SQL authentication** with an admin login and password. |
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

## Set up Visual Studio Code with GitHub Copilot

Next, configure Visual Studio Code with the required extensions for AI-assisted SQL development.

1. Open **Visual Studio Code** on your computer.
1. Select the **Extensions** icon in the Activity Bar (or press **Ctrl+Shift+X**).
1. Search for and install the following extensions:
    - **GitHub Copilot** (by GitHub)
    - **GitHub Copilot Chat** (by GitHub)
    - **SQL Server (mssql)** (by Microsoft)
1. After installation, select the **Accounts** icon in the Activity Bar.
1. Select **Sign in to use GitHub Copilot** and sign in with your GitHub account that has Copilot access.
1. Verify the Copilot icon appears in the status bar, indicating Copilot is active.

---

## Connect to the Azure SQL Database

Now, connect Visual Studio Code to your Azure SQL Database.

1. In Visual Studio Code, select the **SQL Server** icon in the Activity Bar.
1. Select **Add Connection** and enter the following connection details:

    | Setting | Value |
    | --- | --- |
    | **Server name** | *Your Azure SQL server name (for example, yourserver.database.windows.net)* |
    | **Database name** | *AdventureWorksLT* |
    | **Authentication type** | *SQL Login* |
    | **User name** | *Your SQL admin username* |
    | **Password** | *Your SQL admin password* |
    | **Trust server certificate** | *True* |

1. Select **Connect** and verify the connection appears in the **Connections** pane.
1. Expand your connection to view the database objects (Tables, Views, Stored Procedures).

---

## Create a custom instruction file for Copilot

Custom instruction files guide Copilot to generate code that follows your team's standards. Create an instruction file for T-SQL development.

1. In Visual Studio Code, open the folder where you want to store your database project (or create a new folder).
1. Create a new folder named `.github` in the root of your project.
1. Create a new file named `copilot-instructions.md` inside the `.github` folder.
1. Add the following content to the instruction file:

    ```markdown
    # T-SQL Development Guidelines for Copilot

    ## Naming Conventions
    - Tables: PascalCase, singular form (Customer, Product, SalesOrder)
    - Columns: PascalCase (FirstName, OrderDate, UnitPrice)
    - Stored procedures: usp_ActionEntity (usp_GetCustomerOrders, usp_InsertProduct)
    - Views: vw_EntityDescription (vw_ActiveCustomers, vw_ProductInventory)
    - Indexes: IX_TableName_ColumnName

    ## T-SQL Style Guidelines
    - Always use explicit column lists in SELECT statements (avoid SELECT *)
    - Include schema prefix for all objects (SalesLT.Product, SalesLT.Customer)
    - Use ANSI JOIN syntax (INNER JOIN, LEFT JOIN) instead of comma-separated tables
    - Include SET NOCOUNT ON at the beginning of stored procedures
    - Use TRY...CATCH blocks for error handling in stored procedures

    ## Security Requirements
    - Use parameterized queries, never concatenate user input
    - Never include actual credentials or connection strings in code
    - Use least-privilege principles for GRANT statements

    ## Comments
    - Include a header comment with procedure name, purpose, and author
    - Add inline comments for complex logic
    ```

1. Save the file. Copilot will now consider these guidelines when generating T-SQL code.

---

## Use Copilot to generate a stored procedure

Now use GitHub Copilot to generate a stored procedure following your custom guidelines.

1. In Visual Studio Code, create a new file named `usp_GetCustomerOrderSummary.sql`.
1. Open the **Copilot Chat** panel by pressing **Ctrl+Alt+I** (or selecting the Copilot Chat icon).
1. Make sure the **Mode** is set to **Ask** in the bottom-left of the Copilot Chat panel.
1. In the chat, type the following prompt:

    ```text
    Create a stored procedure named usp_GetCustomerOrderSummary that retrieves customer order information from the AdventureWorksLT database. The procedure should:
    - Accept a @CustomerID parameter (optional, if NULL return all customers)
    - Return customer name, total number of orders, total order amount, and last order date
    - Join SalesLT.Customer, SalesLT.SalesOrderHeader, and SalesLT.SalesOrderDetail tables
    - Include error handling with TRY...CATCH
    - Follow the T-SQL guidelines in the instruction file
    ```

1. Review the generated code. Notice how Copilot follows your naming conventions and style guidelines.
1. If needed, ask Copilot to refine the code:

    ```text
    Add a comment header and ensure the procedure uses SET NOCOUNT ON
    ```

1. Copy the final stored procedure code to your SQL file.

---

## Use Copilot to generate a view

Use Copilot to create a view that supports your application needs.

1. Create a new file named `vw_ProductSalesAnalysis.sql`.
1. In the Copilot Chat panel, enter the following prompt:

    ```text
    Create a view named vw_ProductSalesAnalysis that shows:
    - Product name and category
    - Total quantity sold
    - Total revenue
    - Average sale price
    - Number of orders containing this product
    
    Use the SalesLT schema tables and follow the T-SQL guidelines.
    ```

1. Review the generated code and verify it follows your naming conventions and style guidelines.
1. Copy the code to your SQL file.

---

## Use Copilot to explain existing code

Copilot can also help you understand existing database code.

1. In the **SQL Server** connection pane, expand **Views** under your database.
1. Right-click on `SalesLT.vGetAllCategories` and select **Script as Create**.
1. Select the entire view code in the editor.
1. Open Copilot Chat and type:

    ```text
    Explain what this view does and how the recursive CTE works
    ```

1. Review the explanation. Copilot analyzes the code and provides a clear description of its functionality.

---

## Use Copilot for query optimization suggestions

Ask Copilot to help optimize a query.

1. Create a new file named `query_optimization.sql`.
1. Type or paste the following query:

    ```sql
    SELECT *
    FROM SalesLT.SalesOrderHeader h, SalesLT.SalesOrderDetail d, SalesLT.Product p
    WHERE h.SalesOrderID = d.SalesOrderID
    AND d.ProductID = p.ProductID
    AND h.OrderDate > '2008-01-01'
    ```

1. Select the query and open Copilot Chat.
1. Type the following prompt:

    ```text
    Review this query and suggest optimizations following best practices. Explain each improvement.
    ```

1. Review Copilot's suggestions, which should include:
    - Converting to explicit ANSI JOIN syntax
    - Replacing SELECT * with specific column names
    - Adding schema prefixes
    - Potentially adding indexes

---

## Cleanup

If you are not using the Azure SQL Database or the lab files for any other purpose, you can clean up the resources you created in this exercise.

1. In the Azure portal, navigate to your resource group.
1. Select **Delete resource group** and confirm deletion by typing the resource group name.
1. Select **Delete** to remove all resources created in this lab.
1. In Visual Studio Code, you can sign out of GitHub Copilot if needed by selecting the **Accounts** icon and choosing **Sign Out**.

---

You have successfully completed this exercise.

In this exercise, you learned how to use AI-assisted tools to design and implement SQL solutions. You practiced provisioning an Azure SQL Database, configuring GitHub Copilot in Visual Studio Code, creating custom instruction files to guide code generation, using Copilot to generate stored procedures and views, explaining existing database code, and getting query optimization suggestions.
