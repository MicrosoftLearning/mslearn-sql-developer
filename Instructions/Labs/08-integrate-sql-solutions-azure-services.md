---
lab:
    title: 'Lab 8 – Integrate SQL solutions with Azure services'
    module: 'Integrate SQL solutions with Azure services'
    description: This exercise will help you create a Data API Builder configuration for a product catalog database and deploy it to Azure with REST and GraphQL endpoints.
    level: 300
    duration: 30 minutes
    islab: true
    primarytopics:
        - Azure SQL Database
        - Data API Builder
        - REST
        - GraphQL
---

# Integrate SQL solutions with Azure services

**Estimated Time: 30 minutes**

In this exercise, you create a Data API Builder configuration for a product catalog database and deploy it to Azure. You configure entities for tables and views, set up REST and GraphQL endpoints, and verify the API works correctly.

You are a database developer who needs to expose product catalog data through modern APIs. Your team's frontend developers require both REST endpoints for simple operations and GraphQL for flexible queries with relationships.

> &#128221; These exercises ask you to copy and paste configuration code. Please verify that the code has been copied correctly before proceeding to the next step.

## Prerequisites

- An [Azure subscription](https://azure.microsoft.com/free)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and signed in to your subscription
- A code editor such as [Visual Studio Code](https://code.visualstudio.com/download) and the [SQL Server (mssql) extension](https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql) installed
- Access to an Azure SQL Database or SQL Server instance
- Dotnet SDK 8.0 or later installed.

---

## Set up the sample database

Before configuring Data API Builder, you need a database with tables and sample data.

1. Connect to your SQL Server or Azure SQL Database using SQL Server Management Studio (SSMS) or Visual Studio Code with the SQL Server (mssql) extension. For your database, select **master** if not already selected.

1. Create a new database for this exercise:

    ```sql
    CREATE DATABASE ProductCatalog;
    GO
    ```

    If you created the database in a SQL Server (not Azure SQL Database), switch to the new database:

    ```sql
    USE ProductCatalog;
    GO
    ```

    If you created the database in Azure SQL Database, select the new database from the database dropdown in SSMS or Visual Studio Code, or open a **New Query** window and set the context to the new database.

1. Create the tables for the product catalog:

    ```sql
    -- Create Categories table
    CREATE TABLE dbo.Categories (
        CategoryID INT IDENTITY(1,1) PRIMARY KEY,
        CategoryName NVARCHAR(50) NOT NULL,
        Description NVARCHAR(200)
    );
    
    -- Create Products table
    CREATE TABLE dbo.Products (
        ProductID INT IDENTITY(1,1) PRIMARY KEY,
        ProductName NVARCHAR(100) NOT NULL,
        CategoryID INT NOT NULL,
        UnitPrice DECIMAL(10,2) NOT NULL,
        UnitsInStock INT NOT NULL DEFAULT 0,
        Discontinued BIT NOT NULL DEFAULT 0,
        CONSTRAINT FK_Products_Categories 
            FOREIGN KEY (CategoryID) REFERENCES dbo.Categories(CategoryID)
    );
    GO
    
    -- Create a view combining product and category information
    CREATE VIEW dbo.ProductCatalogView AS
    SELECT 
        p.ProductID,
        p.ProductName,
        c.CategoryName,
        p.UnitPrice,
        p.UnitsInStock,
        CASE 
            WHEN p.UnitsInStock = 0 THEN 'Out of Stock'
            WHEN p.UnitsInStock < 10 THEN 'Low Stock'
            ELSE 'Available'
        END AS StockStatus
    FROM dbo.Products p
    INNER JOIN dbo.Categories c ON p.CategoryID = c.CategoryID
    WHERE p.Discontinued = 0;
    GO
    ```

1. Insert sample data:

    ```sql
    -- Insert categories
    INSERT INTO dbo.Categories (CategoryName, Description) VALUES
    ('Electronics', 'Electronic devices and accessories'),
    ('Clothing', 'Apparel and fashion items'),
    ('Home & Garden', 'Products for home improvement');
    
    -- Insert products
    INSERT INTO dbo.Products (ProductName, CategoryID, UnitPrice, UnitsInStock) VALUES
    ('Wireless Headphones', 1, 79.99, 50),
    ('USB-C Cable', 1, 12.99, 200),
    ('Laptop Stand', 1, 45.00, 5),
    ('Cotton T-Shirt', 2, 24.99, 100),
    ('Running Shoes', 2, 89.99, 0),
    ('Garden Hose', 3, 34.99, 25);
    GO
    ```

    You now have a database with categories, products, and a view that joins them.

---

## Install Data API Builder CLI

The DAB CLI helps you create and manage configuration files.

1. Open a terminal or command prompt.

1. Install the Data API Builder CLI using .NET:

    ```bash
    dotnet tool install --global Microsoft.DataApiBuilder
    ```

1. Verify the installation:

    ```bash
    dab --version
    ```

    You should see the version number displayed, confirming the CLI is installed.

---

## Create the initial configuration

Use the DAB CLI to create a baseline configuration file.

1. Create a new directory for your project:

    ```bash
    mkdir product-catalog-api
    cd product-catalog-api
    ```

1. Initialize a new configuration file:

    ```bash
    dab init --database-type mssql --connection-string "@env('DATABASE_CONNECTION_STRING')" --host-mode development
    ```

    This command creates a `dab-config.json` file with basic settings. The `@env()` syntax means DAB reads the connection string from an environment variable at runtime.

1. Open `dab-config.json` in your editor. You should see a structure similar to:

    ```json
    {
      "$schema": "https://github.com/Azure/data-api-builder/releases/latest/download/dab.draft.schema.json",
      "data-source": {
        "database-type": "mssql",
        "connection-string": "@env('DATABASE_CONNECTION_STRING')"
      },
      "runtime": {
        "rest": { "enabled": true, "path": "/api" },
        "graphql": { "enabled": true, "path": "/graphql" },
        "host": { "mode": "development" }
      },
      "entities": {}
    }
    ```

    > &#128161; The `dab-config.json` file defines the Data API Builder configuration, including the data source, runtime settings, and entities that will be exposed through the API. Your current settings might differ to the previous example depending on your environment and the database you are connecting to. Your settings will at least include the @env('DATABASE_CONNECTION_STRING') variable, the /api and /graphql paths in the `runtime` section, your mode set to development, and an empty `entities` object.

---

## Add entities for tables

On the terminal or in a command prompt, add the Categories and Products tables as API entities.

1. Use the CLI to add the Categories entity:

    ```bash
    dab add Category --source dbo.Categories --permissions "anonymous:read"
    ```

1. Add Product entity with anonymous read

    ```bash
    dab add Product --source dbo.Products --permissions "anonymous:read"
    ```

1. Add authenticated full CRUD

    ```bash
    dab update Product --permissions "authenticated:*"
    ```

1. Open `dab-config.json` to see the generated entities (your file might look slightly different depending on your environment):

    ```json
    "entities": {
      "Category": {
        "source": { "object": "dbo.Categories", "type": "table" },
        "permissions": [
          { "role": "anonymous", "actions": ["read"] }
        ]
      },
      "Product": {
        "source": { "object": "dbo.Products", "type": "table" },
        "permissions": [
          { "role": "anonymous", "actions": ["read"] },
          { "role": "authenticated", "actions": ["*"] }
        ]
      }
    }
    ```

---

## Configure field mappings and relationships

Enhance the Product entity with field mappings and a relationship to Category.

1. Edit `dab-config.json` to add field mappings to the Product entity. Replace the Product entity section with:

    ```json
    "Product": {
      "source": { "object": "dbo.Products", "type": "table" },
      "mappings": {
        "ProductID": "id",
        "ProductName": "name",
        "UnitPrice": "price",
        "UnitsInStock": "stockQuantity",
        "Discontinued": "isDiscontinued"
      },
      "relationships": {
        "category": {
          "cardinality": "one",
          "target.entity": "Category",
          "source.fields": ["CategoryID"],
          "target.fields": ["CategoryID"]
        }
      },
      "permissions": [
        { "role": "anonymous", "actions": ["read"] },
        { "role": "authenticated", "actions": ["*"] }
      ]
    }
    ```

    The `mappings` section renames database columns to more API-friendly names. The `relationships` section enables GraphQL clients to navigate from a product to its category.

1. Add the reverse relationship to the Category entity, replacing the existing Category entity section in `dab-config.json` with the following:

    ```json
    "Category": {
      "source": { "object": "dbo.Categories", "type": "table" },
      "relationships": {
        "products": {
          "cardinality": "many",
          "target.entity": "Product",
          "source.fields": ["CategoryID"],
          "target.fields": ["CategoryID"]
        }
      },
      "permissions": [
        { "role": "anonymous", "actions": ["read"] }
      ]
    }
    ```

1. Save the changes to `dab-config.json`.

---

## Add the view as a read-only entity

Expose the ProductCatalogView for clients who need combined product and category information.

1. Add the view entity using the CLI:

    ```bash
    dab add ProductCatalog --source dbo.ProductCatalogView --source.type view --source.key-fields "ProductID" --permissions "anonymous:read"
    ```

1. Verify the entity was added correctly in `dab-config.json`:

    ```json
    "ProductCatalog": {
      "source": {
        "object": "dbo.ProductCatalogView",
        "type": "view",
        "key-fields": ["ProductID"]
      },
      "graphql": { "operation": "query" },
      "permissions": [
        { "role": "anonymous", "actions": ["read"] }
      ]
    }
    ```

    The `key-fields` property is required for views because DAB can't detect primary keys automatically.

---

## Test locally

Run Data API Builder locally to verify your configuration. The `dab start` command launches a local web server using the .NET runtime and connects to your database using the connection string you provide.

1. Open a **PowerShell** or **Bash** terminal. The remaining commands in this section must be run in PowerShell or Bash (not CMD). If you are currently in a CMD prompt, type `pwsh` and press Enter to switch to PowerShell (notice the prompt changes to `PS`).

1. Set the database connection string as an environment variable. Use **one** of the two options below depending on how your SQL server was configured for authentication.

    > &#128221; When you (or your admin) created the Azure SQL server, you chose an authentication method based on your organization's security policies. That same choice determines the connection string you use here. If you are unsure which method was configured, check the Azure portal: navigate to your SQL server > **Settings** > **Microsoft Entra ID**. If an Entra admin is set and the **Support only Microsoft Entra authentication for this server** checkbox is checked, use Option A.

    **Option A: Microsoft Entra authentication** (no username/password needed; uses your signed-in Azure identity)

    | Shell | Command |
    | --- | --- |
    | **PowerShell** | `$env:DATABASE_CONNECTION_STRING="Server=your-server.database.windows.net;Database=ProductCatalog;Authentication=Active Directory Default;TrustServerCertificate=true"` |
    | **Bash** | `export DATABASE_CONNECTION_STRING="Server=your-server.database.windows.net;Database=ProductCatalog;Authentication=Active Directory Default;TrustServerCertificate=true"` |

    **Option B: SQL authentication** (use the admin login and password from server creation)

    | Shell | Command |
    | --- | --- |
    | **PowerShell** | `$env:DATABASE_CONNECTION_STRING="Server=your-server.database.windows.net;Database=ProductCatalog;User Id=your-user;Password=your-password;TrustServerCertificate=true"` |
    | **Bash** | `export DATABASE_CONNECTION_STRING="Server=your-server.database.windows.net;Database=ProductCatalog;User Id=your-user;Password=your-password;TrustServerCertificate=true"` |

    > &#128161; Replace `your-server` with your actual server name. For Option B, also replace `your-user` and `your-password` with the admin credentials you set during server creation.

1. Start Data API Builder:

    ```bash
    dab start
    ```

1. Open a browser and navigate to `http://localhost:5000/api/Product` to test the REST endpoint.

    You should see a JSON response with product data using the mapped field names (id, name, price, stockQuantity).

    > &#128221; **If you used Option A (Microsoft Entra)** and get an error about `DefaultAzureCredential failed to retrieve a token`, your Azure CLI session may have expired. Run `az login --scope https://database.windows.net//.default` in your terminal to re-authenticate, then run `dab start` again.

1. Navigate to `http://localhost:5000/graphql` to access the GraphQL playground.

1. Select **Create Document** to open a new query tab. Paste the following GraphQL query and press **Ctrl+Alt+Enter** (or select the **Run** button) to execute it:

    ```graphql
    query {
      products {
        items {
          id
          name
          price
          category {
            CategoryName
          }
        }
      }
    }
    ```

    The response includes product information with the related category name, demonstrating the configured relationship.

1. Go back to the terminal and press `Ctrl+C` to stop Data API Builder.

---

## Cleanup

If you're not using the database for any other purpose, you can clean up the resources you created.

1. Run the following script to remove the database objects:

    ```sql
    USE master;
    GO
    DROP DATABASE IF EXISTS ProductCatalog;
    GO
    ```

1. Delete the project directory:

    ```bash
    cd ..
    rm -rf product-catalog-api
    ```

---

You have successfully completed this exercise.

In this exercise, you learned how to create a Data API Builder configuration from scratch. You practiced creating entities for tables and views, configuring field mappings and relationships, and testing APIs locally. These skills enable you to rapidly expose SQL databases through modern REST and GraphQL APIs.
