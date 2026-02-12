---
lab:
    title: 'Lab 7 - Implement CI/CD with SQL Database Projects'
    module: 'Implement CI/CD by using SQL Database Projects'
---

# Implement CI/CD with SQL Database Projects

**Estimated Time: 45 minutes**

In this lab, you create a SQL database project, build it locally, push it to a GitHub repository, and configure a GitHub Actions pipeline that automatically builds and deploys schema changes to Azure SQL Database.

You're a database administrator for Adventure Works. The team has been applying database changes by running scripts manually against production. After a recent deployment broke a table because someone ran the scripts out of order, your manager asks you to set up an automated pipeline. You use a SQL database project as the source of truth for the schema and GitHub Actions to build and deploy changes.

> &#128221; These exercises ask you to copy and paste T-SQL code and YAML content. Please verify that the code has been copied correctly before executing or committing.

## Prerequisites

Before starting this exercise, make sure you have the following accounts and tools set up:

- An [Azure subscription](https://azure.microsoft.com/free).
- A [GitHub account](https://github.com/join).
- [Git](https://git-scm.com/downloads) installed on your machine.
- [GitHub CLI (gh)](https://cli.github.com/) installed on your machine.
- [Visual Studio Code](https://code.visualstudio.com/download) with the [MSSQL extension](https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql) installed (the MSSQL extension includes SQL Database Projects support).
- [.NET SDK 8.0](https://dotnet.microsoft.com/download/dotnet/8.0) or later.

## Provision an Azure SQL Database

First, create an Azure SQL Database with sample data.

> &#128221; Skip this section if you already have an AdventureWorksLT Azure SQL Database provisioned.

1. Go to the [Azure SQL hub](https://aka.ms/azuresqlhub) and sign in with your Azure account if prompted. In the **Azure SQL Database** pane, select **Show options**, and then select **Create SQL Database**.

    > &#128161; If you see a **Free offer** banner on this page, you can apply it to use Azure SQL Database at no cost. The [free offer](https://learn.microsoft.com/azure/azure-sql/database/free-offer) provides 100,000 vCore seconds of serverless compute and 32 GB of storage per month. If you apply the free offer, skip steps 3 to 6.

1. On the **Basics** tab of the **Create SQL Database** page, fill in the required information:

    | Setting | Value |
    | --- | --- |
    | **Subscription** | Select your Azure subscription. |
    | **Resource group** | Select or create a resource group. |
    | **Database name** | *AdventureWorksLT* |
    | **Server** | Select **Create new** and create a new server with a unique name. Select your **Location**. You should use **Use Microsoft Entra-only authentication** for more secure access, or **Use both SQL and Microsoft Entra authentication**/**SQL authentication** with an admin sign in and password, but note that *Microsoft Entra-only authentication* is recommended. Select **OK**. |

    > &#128221; If you already have a test server you can use, select it instead of creating a new one.

1. Leave **Want to use SQL elastic pool** set to **No**.
1. For **Workload environment**, select **Development**. This presets the compute to **General Purpose serverless** with auto-pause enabled, which is the most cost-friendly paid option.
1. Under **Compute + storage**, select **Configure database**. Change the service tier to **Hyperscale** and the compute tier to **Serverless**. Select **Apply** to confirm.
1. Under **Backup storage redundancy**, select **Locally-redundant backup storage**.
1. Select **Next: Networking**.
1. On the **Networking** tab, for **Connectivity method**, select **Public endpoint**.

    > &#128221; If you selected an existing server instead of creating a new one, the **Connectivity method** option may not appear because it is already configured on the server.

1. Under **Firewall rules**, set **Allow Azure services and resources to access this server** to **Yes** and **Add current client IP address** to **Yes**.
1. Select **Next: Security**, then select **Next: Additional settings**.
1. On the **Additional settings** tab, under **Data source**, set **Use existing data** to *Sample* to create the AdventureWorksLT sample database. Select **OK** when prompted to confirm.
1. Select **Review + create**, review the settings, and then select **Create**.
1. Wait for the deployment to complete, then navigate to the new Azure SQL Database resource.

## Configure your development environment

Set up Git, authenticate with GitHub, and install the SQL project templates.

1. Open a terminal in Visual Studio Code (**Terminal** > **New Terminal**) and verify the required tools are installed by running the following commands:

    ```bash
    git --version
    gh --version
    dotnet --version
    ```

    <blockquote>
    <div markdown="1">

    &#128221; If any of these commands aren't recognized, install the missing tool before continuing:

    - **Git**: Download and install from [https://git-scm.com/downloads](https://git-scm.com/downloads).
    - **GitHub CLI**: Download and install from [https://cli.github.com](https://cli.github.com).
    - **.NET SDK 8.0+**: Download and install from [https://dotnet.microsoft.com/download/dotnet/8.0](https://dotnet.microsoft.com/download/dotnet/8.0).

    </div>
    </blockquote>

    <blockquote>
    <div markdown="1">

    &#128161; After installing, **fully close and reopen Visual Studio Code** (not just the terminal) so it picks up the updated system PATH. If a command still isn't recognized in the Visual Studio Code terminal, run the following command to manually refresh the PATH in your current PowerShell session:

    `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")`

    </div>
    </blockquote>

1. Configure your Git identity:

    > &#128221; Skip this step if you already configured your Git identity in a previous exercise. You can verify by running `git config --global user.name` and `git config --global user.email` in the terminal. If both return values, move to the step 3.

    ```bash
    git config --global user.name "Your Name"
    git config --global user.email "your-email@example.com"
    ```

1. Authenticate with GitHub using the GitHub CLI:

    ```bash
    gh auth login
    ```

    When prompted, select **GitHub.com**, choose **HTTPS** as the protocol, and authenticate through the browser.

1. Install the SQL database project templates:

    ```bash
    dotnet new install Microsoft.Build.Sql.Templates
    ```

    > &#128221; This package adds the `sqlproj` template to your .NET CLI. You only need to install it once per machine.

## Create a SQL database project

Create a new SQL database project and add two database objects: a table and a stored procedure.

1. Create a project folder and initialize the SQL project (if needed, navigate to the directory where you want to create the project before running these commands):

    ```bash
    mkdir AdventureWorksDB
    cd AdventureWorksDB
    ```

1. Initialize the SQL database project with Azure SQL Database as the target platform:

    ```bash
    dotnet new sqlproj -tp SqlAzureV12
    ```

    > &#128221; The `-tp SqlAzureV12` flag sets the target platform to Azure SQL Database. Without it, the project defaults to the latest SQL Server version, and the `.dacpac` won't deploy to Azure SQL Database. This creates a file named `AdventureWorksDB.sqlproj` in the current directory. The file references the Microsoft.Build.Sql SDK, which enables `dotnet build` to compile your T-SQL into a `.dacpac`.

1. Create a **Tables** folder to store table definitions:

    ```bash
    mkdir Tables
    ```

1. In Visual Studio Code, open the **AdventureWorksDB** folder (**File** > **Open Folder**). In the **Explorer** pane, right-click the **Tables** folder and select **New File**. Name the file `InventoryLog.sql`, add the following content and save the file:

    ```sql
    CREATE TABLE [dbo].[InventoryLog] (
        [LogID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [ProductID] INT NOT NULL,
        [ChangeDate] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [QuantityChange] INT NOT NULL,
        [ChangeType] NVARCHAR(20) NOT NULL
    );
    ```

1. Create a **StoredProcedures** folder to store procedure definitions:

    ```bash
    mkdir StoredProcedures
    ```

1. In the **Explorer** pane, right-click the **StoredProcedures** folder and select **New File**. Name the file `uspLogInventoryChange.sql`, add the following content and save the file:

    ```sql
    CREATE PROCEDURE [dbo].[uspLogInventoryChange]
        @ProductID INT,
        @QuantityChange INT,
        @ChangeType NVARCHAR(20)
    AS
    BEGIN
        INSERT INTO [dbo].[InventoryLog] (ProductID, QuantityChange, ChangeType)
        VALUES (@ProductID, @QuantityChange, @ChangeType);
    END;
    ```

    > &#128221; The SDK-style SQL project uses default globbing, which means any `.sql` file in the project directory or subdirectories is included in the build automatically. You don't need to list each file in the `.sqlproj`.

## Build the project locally

Build the project to verify the T-SQL compiles and the `.dacpac` is produced.

1. From the `AdventureWorksDB` directory, run:

    ```bash
    dotnet build
    ```

1. Confirm the build output includes a line ending with `AdventureWorksDB -> ...bin/Debug/AdventureWorksDB.dacpac`.

    > &#128221; The `.dacpac` is the deployable artifact. It contains the schema definition for every object in the project. SqlPackage (or the `azure/sql-action`) compares this `.dacpac` to the target database and generates the ALTER/CREATE statements needed to bring the database in sync.

1. If the build fails, check the terminal output for errors. Common issues include missing semicolons, mismatched brackets, or incorrect column references.

## Initialize Git and create a GitHub repository

Set up version control and push the project to GitHub. Make sure your terminal is still in the **AdventureWorksDB** folder (the same directory that contains `AdventureWorksDB.sqlproj`).

1. Initialize a Git repository in the project folder:

    ```bash
    git init -b main
    ```

1. In Visual Studio Code's **Explorer** pane, select the **New File** *icon* at the top of the file list. Name the file `.gitignore` and add the following content to exclude build output and save the file:

    ```text
    bin/
    obj/
    ```

1. In the terminal, create the GitHub repository and link it to your local project:

    ```bash
    gh repo create AdventureWorksDB --private --source=. --remote=origin
    ```

    > &#128221; This command creates a private repository named `AdventureWorksDB` on your GitHub account (for example, `https://github.com/YourGitHubUser/AdventureWorksDB`) and adds it as a remote named `origin`. It doesn't push any files yet.

## Configure the GitHub secrets for deployment

The pipeline needs credentials to deploy to Azure SQL Database. The steps differ depending on your server's authentication mode.

### Option A: SQL authentication (default)

If your server supports SQL authentication, you only need a connection string secret.

1. In the Azure portal, navigate to your **SQL database** resource.
1. In the left menu, select **Connection strings** under **Settings**.
1. On the **ADO.NET (SQL authentication)** tab, copy the connection string. It looks similar to:

    ```text
    Server=tcp:yourserver.database.windows.net,1433;Initial Catalog=AdventureWorksLT;Persist Security Info=False;User ID=youradmin;Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
    ```

1. In the copied string, replace `{your_password}` with the actual password you set when creating the server.
1. In the terminal, add the connection string as a GitHub secret:

    ```bash
    gh secret set SQL_CONNECTION_STRING
    ```

    When prompted, paste the full connection string (with the real password) and press **Enter**.

    > &#128221; GitHub encrypts the secret value. It's never visible in logs or to anyone viewing the repository. The workflow accesses it through `{% raw %}${{ secrets.SQL_CONNECTION_STRING }}{% endraw %}`.

1. Skip ahead to the **Create the GitHub Actions workflow** section and use **Option A** for the workflow YAML.

### Option B: Microsoft Entra-only authentication (Entra-only alternative)

If your server uses Microsoft Entra-only authentication, you need to register an app in Microsoft Entra ID, configure federated credentials for GitHub Actions, and store multiple secrets.

1. In the Azure portal, navigate to **Microsoft Entra ID** > **Manage** > **App registrations** > **New registration**.
1. Set **Name** to `sqldeploysp`, leave all other settings at their defaults, and select **Register**.
1. On the app registration's **Overview** page, note the **Application (client) ID** and **Directory (tenant) ID**. You need these values later.
1. Select **Manage** > **Certificates & secrets** > **Federated credentials** > **Add credential**.
1. Select **GitHub Actions deploying Azure resources** and fill in the following:

    | Setting | Value |
    | --- | --- |
    | **Organization** | *Your GitHub username* |
    | **Repository** | *AdventureWorksDB* |
    | **Entity type** | *Branch* |
    | **GitHub branch name** | *main* |
    | **Name** | *github-actions-deploy* |

1. Select **Add**.

1. Navigate to the **Resource group** that contains your SQL server and select **Access control (IAM)** > **Add** > **Add role assignment**.
1. On the **Role** tab, search for `SQL Server Contributor`, select it, then select **Next**.

    > &#128221; The **SQL Server Contributor** role follows the principle of least privilege. It grants permission to manage SQL servers and firewall rules without giving broad access to all resources in the resource group. The `azure/sql-action` needs this role to create and remove temporary firewall rules during deployment. The actual database access is handled separately by the SQL-level `db_owner` grant you configure in the next step.

1. On the **Members** tab, select **User, group, or service principal**, then select **Select members**. Search for `sqldeploysp`, select it, and then select **Review + assign** and **Review + assign** again to finish.

1. Get your subscription ID. Navigate to your **SQL server** resource and copy the **Subscription ID** from the **Overview** page.

1. Grant the service principal access to your SQL database. Navigate to your **SQL database** resource and select **Query editor (preview)** or **SQL Server Management Studio (SSMS)**. Sign in and run:

    ```sql
    CREATE USER [sqldeploysp] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_owner ADD MEMBER [sqldeploysp];
    ```

1. In the terminal, add the GitHub secrets:

    ```bash
    gh secret set AZURE_CLIENT_ID
    gh secret set AZURE_TENANT_ID
    gh secret set AZURE_SUBSCRIPTION_ID
    gh secret set SQL_CONNECTION_STRING
    ```

    When prompted for each secret, paste the corresponding value:
    - `AZURE_CLIENT_ID`: The **Application (client) ID** from step 3.
    - `AZURE_TENANT_ID`: The **Directory (tenant) ID** from step 3.
    - `AZURE_SUBSCRIPTION_ID`: The **Subscription ID** from step 11.
    - `SQL_CONNECTION_STRING`: Use the following format (replace `yourserver` with your server name):

    ```text
    Server=tcp:yourserver.database.windows.net,1433;Initial Catalog=AdventureWorksLT;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=Active Directory Default;
    ```

    > &#128221; The `Active Directory Default` authentication method allows the `azure/sql-action` to use the service principal identity established by the `azure/login` step. No password is needed in the connection string.

## Create the GitHub Actions workflow

Create a workflow file that builds the SQL project and deploys the `.dacpac` to Azure SQL Database on every push to `main`.

1. In the terminal, create the folder structure for the workflow file:

    ```bash
    mkdir -p .github/workflows
    ```

    > &#128221; If the `.github` folder is a hidden directory, to see it in VS Code's Explorer pane, select **File** > **Preferences** > **Settings**, search for `files.exclude`, and remove or disable the `**/.github` pattern if it's listed.

1. In the **Explorer** pane, right-click the **workflows** folder (under.github**) and select **New File**. Name the file `build-deploy.yml`.

1. Add the workflow content based on your authentication method and save the file:

    ### Option A: SQL authentication workflow

    ```yaml
    name: Build and Deploy SQL Database Project

    on:
      push:
        branches:
          - main

    jobs:
      build-and-deploy:
        runs-on: ubuntu-latest

        steps:
          - name: Checkout repository
            uses: actions/checkout@v4

          - name: Setup .NET SDK
            uses: actions/setup-dotnet@v4
            with:
              dotnet-version: '8.x'

          - name: Build SQL project
            run: dotnet build AdventureWorksDB.sqlproj

          - name: Install SqlPackage
            run: dotnet tool install -g microsoft.sqlpackage

          - name: Deploy to Azure SQL Database
            uses: azure/sql-action@v2.3
            with:
              connection-string: {% raw %}${{ secrets.SQL_CONNECTION_STRING }}{% endraw %}
              path: ./bin/Debug/AdventureWorksDB.dacpac
              action: publish
    ```

    ### Option B: Microsoft Entra-only authentication workflow

    ```yaml
    name: Build and Deploy SQL Database Project

    on:
      push:
        branches:
          - main

    permissions:
      id-token: write
      contents: read

    jobs:
      build-and-deploy:
        runs-on: ubuntu-latest

        steps:
          - name: Checkout repository
            uses: actions/checkout@v4

          - name: Setup .NET SDK
            uses: actions/setup-dotnet@v4
            with:
              dotnet-version: '8.x'

          - name: Build SQL project
            run: dotnet build AdventureWorksDB.sqlproj

          - name: Install SqlPackage
            run: dotnet tool install -g microsoft.sqlpackage

          - name: Azure Login
            uses: azure/login@v2
            with:
              client-id: {% raw %}${{ secrets.AZURE_CLIENT_ID }}{% endraw %}
              tenant-id: {% raw %}${{ secrets.AZURE_TENANT_ID }}{% endraw %}
              subscription-id: {% raw %}${{ secrets.AZURE_SUBSCRIPTION_ID }}{% endraw %}

          - name: Deploy to Azure SQL Database
            uses: azure/sql-action@v2.3
            with:
              connection-string: {% raw %}${{ secrets.SQL_CONNECTION_STRING }}{% endraw %}
              path: ./bin/Debug/AdventureWorksDB.dacpac
              action: publish
    ```

    > &#128221; Both workflows build the SQL project into a `.dacpac` and use the `azure/sql-action` to deploy it. The difference is that Option B adds an `azure/login` step with OIDC federated credentials, which lets the `azure/sql-action` authenticate using Microsoft Entra. The `permissions` block grants the workflow a token to authenticate with Azure. The `publish` action generates ALTER and CREATE statements as needed, so you never write deployment scripts by hand.

## Push and verify the first deployment

Push the project to GitHub, watch the pipeline run, and verify the table was created in Azure SQL Database.

1. Stage, commit, and push all files:

    ```bash
    git add -A
    git commit -m "Initial SQL project with InventoryLog table and CI/CD pipeline"
    git push -u origin main
    ```

1. Open the GitHub repository in a browser:

    ```bash
    gh browse
    ```

1. Select the **Actions** tab. You should see a workflow run in progress or recently completed. Select it to view the build and deploy steps.

1. If the workflow completed with a green checkmark, the deployment succeeded. If it failed, select the failed step to read the error message.

    > &#128221; Common failures at this stage include an incorrect connection string (check the secret value), a firewall rule that wasn't saved (go back to the server's Networking page), or a mistyped file path in the workflow YAML.

1. Verify the table was created in Azure SQL Database. In the Azure portal, navigate to your SQL database and select **Query editor (preview)** or use **SQL Server Management Studio (SSMS)**.
1. Sign in with the SQL admin credentials you set during provisioning.
1. Run the following query:

    ```sql
    SELECT TABLE_SCHEMA, TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'InventoryLog';
    ```

    > &#128221; You should see one row showing `dbo.InventoryLog`. This table didn't exist before. The pipeline created it by deploying your `.dacpac`.

1. Verify the stored procedure was also created:

    ```sql
    SELECT ROUTINE_SCHEMA, ROUTINE_NAME
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'uspLogInventoryChange';
    ```

## Push a schema change

Test the full cycle by modifying the table, pushing the change, and verifying the pipeline updates the database.

1. In Visual Studio Code, open `Tables/InventoryLog.sql` and add a `Notes` column before the closing parenthesis:

    ```sql
    CREATE TABLE [dbo].[InventoryLog] (
        [LogID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [ProductID] INT NOT NULL,
        [ChangeDate] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [QuantityChange] INT NOT NULL,
        [ChangeType] NVARCHAR(20) NOT NULL,
        [Notes] NVARCHAR(200) NULL
    );
    ```

    > &#128221; Notice that you're editing the CREATE TABLE statement, not writing an ALTER TABLE script. The SQL project is declarative. You define what the table should look like. When the pipeline deploys this updated `.dacpac`, the `azure/sql-action` compares it to the existing table and generates an `ALTER TABLE ADD` statement automatically.

1. Build locally to make sure the change compiles:

    ```bash
    dotnet build
    ```

1. Commit and push the change:

    ```bash
    git add -A
    git commit -m "Add Notes column to InventoryLog table"
    git push
    ```

1. In the browser, select the **Actions** tab on your GitHub repository and watch the new workflow run.

1. After the workflow completes, go back to the **Query editor** in the Azure portal or use **SQL Server Management Studio (SSMS)** and run:

    ```sql
    SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'InventoryLog'
    ORDER BY ORDINAL_POSITION;
    ```

    > &#128221; You should see the `Notes` column listed with data type `nvarchar` and `IS_NULLABLE` set to `YES`. The pipeline detected the difference between the `.dacpac` and the live database, generated the ALTER TABLE statement, and applied it, all from a one-line change in your SQL file.

## Cleanup

To avoid incurring costs, remove the resources you created during this exercise.

1. Delete the GitHub repository:

    ```bash
    gh repo delete AdventureWorksDB --yes
    ```

    > &#128221; If you get a **403** error saying *Must have admin rights to Repository*, your GitHub CLI token doesn't include the `delete_repo` scope. Run `gh auth refresh -h github.com -s delete_repo` to add it, then retry the delete command.

1. In the Azure portal, navigate to the **SQL server** resource and select **Networking**. Under **Firewall rules**, delete the `AllowGitHubRunners` rule and select **Save**.

> &#128221; If you're done with all exercises in this course, you can delete the Azure SQL Database or the entire resource group to stop all charges. If other exercises in the course use the same database, keep it and only remove the firewall rule.

If you don't need the database anymore, you can delete it:

1. In the Azure portal, navigate to your **SQL database** resource.
1. Select **Delete** from the top menu, type the database name to confirm, and select **Delete**.


You successfully completed this exercise.

## Key takeaways

In this exercise, you created a SQL database project with a table and stored procedure, built the `.dacpac` locally, and pushed the project to GitHub. You configured a GitHub Actions workflow that builds the project and deploys it to Azure SQL Database using the `azure/sql-action`. You then pushed a schema change (adding a column to the table) and verified that the pipeline detected the difference and applied the ALTER TABLE automatically. This exercise demonstrated the core CI/CD workflow for database projects: edit the declarative schema, push to source control, and let the pipeline handle the build and deployment.
