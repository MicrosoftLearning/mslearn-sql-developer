---
lab:
    title: 'Lab 11 – Implement RAG solutions'
    module: 'Design and implement RAG with SQL'
---

# Implement RAG solutions

**Estimated Time: 45 minutes**

In this exercise, you implement a complete Retrieval Augmented Generation (RAG) solution using Azure SQL Database. You create a product review table, add a vector column to store embeddings, generate embeddings for customer reviews, use vector search to retrieve relevant reviews, format them as JSON context, construct an augmented prompt, call an Azure OpenAI endpoint, and extract the response.

You're a database developer for Adventure Works. Your team wants to build an AI-powered product assistant that answers customer questions using real customer reviews. Instead of fine-tuning a model, you use RAG to ground the model's responses in your database. You use vector search to find the most relevant reviews for each question.

> &#128221; These exercises ask you to copy and paste T-SQL code. Please verify that the code has been copied correctly, before executing the code.

## Prerequisites

- An [Azure subscription](https://azure.microsoft.com/free) with approval for [Azure OpenAI access](/legal/cognitive-services/openai/limited-access)
- Visual Studio Code with the SQL Server (mssql) extension, or SQL Server Management Studio
- Basic familiarity with Azure SQL Database and T-SQL

---

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

1. Leave **Want to use SQL elastic pool** set to **No**.
1. For **Workload environment**, select **Development**. This presets the compute to **General Purpose serverless** with auto-pause enabled, which is the most cost-friendly paid option.
1. Under **Compute + storage**, select **Configure database**. Change the service tier to **Hyperscale** and the compute tier to **Serverless**. Select **Apply** to confirm.
1. Under **Backup storage redundancy**, select **Locally-redundant backup storage**.
1. Select **Next: Networking**.
1. On the **Networking** tab, for **Connectivity method**, select **Public endpoint**.
1. Under **Firewall rules**, set **Allow Azure services and resources to access this server** to **Yes** and **Add current client IP address** to **Yes**.
1. Select **Next: Security**, then select **Next: Additional settings**.
1. On the **Additional settings** tab, under **Data source**, set **Use existing data** to *Sample* to create the AdventureWorksLT sample database. Select **OK** when prompted to confirm.
1. Select **Review + create**, review the settings, and then select **Create**.
1. Wait for the deployment to complete, then navigate to the new Azure SQL Database resource.

---

## Deploy an Azure OpenAI model

Next, deploy an Azure OpenAI resource with a chat model and an embedding model.

> &#128221; Skip this section if you already have an Azure OpenAI resource with **gpt-4.1-mini** and **text-embedding-3-small** models deployed.

1. In the Azure portal, search for **Azure OpenAI** and select **Create**.
1. Select **Foundry (Recommended)** from the pull-down menu.
1. Fill in the required information:

    | Setting | Value |
    | --- | --- |
    | **Subscription** | Select your Azure subscription. |
    | **Resource group** | Use the same resource group as your SQL Database. |
    | **Name** | Enter a unique name (for example, *adventureworks-openai*). |
    | **Region** | Choose a region where Azure OpenAI is available. |
    | **Default project name** | *proj-sqlailab* |

1. Select **Review + create**, then select **Create**.
1. Wait for the deployment to complete, then select **Go to resource**.
1. On the Azure OpenAI resource overview page, note the **Endpoint** value (for example, `https://adventureworks-openai.cognitiveservices.azure.com/`). You need the endpoint name (the part before `.cognitiveservices.azure.com`) later.
1. Select **Go to Foundry portal** to open the [Microsoft Foundry](https://ai.azure.com) portal.

    > &#128161; You will deploy two models: **gpt-4.1-mini** (for chat completions) and **text-embedding-3-small** (for embeddings). The following steps guide you through deploying both models.

1. In the Microsoft Foundry portal, select **Model catalog** in the left menu.
1. Search for and select **gpt-4.1-mini**.
1. Select **Use this model** to deploy the model.
1. Set the **Deployment name** to **gpt-4.1-mini** and select **Deploy**.
1. On the deployment details page, note the **Target URI**. The Target URI looks like `https://<your-endpoint>.cognitiveservices.azure.com/openai/deployments/gpt-4.1-mini/chat/completions?api-version=...`. You need the `api-version` value later.
1. Now deploy the embedding model. Select **Model catalog** in the left menu to return to the catalog. If the catalog only shows your existing deployment, select **Model catalog** again to access the full catalog.
1. Search for and select **text-embedding-3-small**.
1. Select **Use this model** to deploy the embedding model.
1. Set the **Deployment name** to **text-embedding-3-small** and select **Deploy**.
1. On the deployment details page, note the **Target URI** for this model as well. It looks like `https://<your-endpoint>.cognitiveservices.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=...`.
1. In the left menu, select **Models + endpoints** under **My assets** to verify both deployments appear.

---

## Configure managed identity access

Since Azure SQL Database uses a system-assigned managed identity to authenticate with Azure OpenAI, you need to enable the identity on your SQL Server and grant it access to the Azure OpenAI resource. This approach is more secure than API keys and doesn't require storing secrets.

> &#128221; Skip this section if your SQL Server already has a system-assigned managed identity enabled and it has been granted the **Cognitive Services OpenAI User** role on your Azure OpenAI resource.

1. In the Azure portal, navigate to your **SQL server** (the logical server, not the database).
1. In the left menu, select **Security** > **Identity**.
1. Under **System assigned managed identity**, set **Status** to **On** and select **Save**.
1. Now navigate to your **Azure OpenAI** resource (for example, *adventureworks-openai*).
1. In the left menu, select **Access control (IAM)**.
1. Select **+ Add** and then select **Add role assignment**.
1. On the **Role** tab, search for and select **Cognitive Services OpenAI User**, then select **Next**.
1. On the **Members** tab, select **Managed identity**, then select **+ Select members**.
1. In the **Select managed identities** pane, set **Managed identity** to **SQL server**, select your SQL server from the list, and then select **Select**.
1. Select **Review + assign** twice to complete the role assignment.

    > &#128221; The role assignment may take up to 5 minutes to take effect. You can proceed with the next steps while waiting.

---

## Create the ProductReview table

The AdventureWorksLT sample database contains product information but no customer reviews. In this step, you download and run a script that creates a **ProductReview** table with 140 realistic reviews across many product categories. These reviews give the RAG solution rich, varied content to search through.

1. Connect to your Azure SQL Database using Visual Studio Code or SQL Server Management Studio.
1. Download the review script from [**product-reviews-insert.sql**](https://raw.githubusercontent.com/MicrosoftLearning/mslearn-sql-developer/main/Allfiles/product-reviews-insert.sql) and save it locally.
1. Open the downloaded file and run the entire script against your **AdventureWorksLT** database.
1. Verify the table was created and populated by running:

    ```sql
    SELECT COUNT(*) AS TotalReviews FROM dbo.ProductReview;
    GO
    ```

    > &#128221; You should see **140** rows. The reviews cover bikes, tires, lights, helmets, gloves, maintenance tools, and more, with ratings ranging from 1 to 5 stars.

---

## Create a database scoped credential and an external model for embeddings

Set up the credential and model reference needed to call Azure OpenAI from T-SQL. You create a single credential using the system-assigned managed identity of your Azure SQL Server. This credential is used by both `CREATE EXTERNAL MODEL` (for embeddings) and `sp_invoke_external_rest_endpoint` (for chat completions), and eliminates the need for API keys.

> &#128221; Skip this section if you already have a database scoped credential and an external embedding model configured for your Azure OpenAI endpoint.

1. to create a database scoped credential using managed identity, open a new query window and run the following script. Replace `<your-openai-endpoint>` with the endpoint name from your Azure OpenAI resource (for example, if your endpoint is `https://adventureworks-openai.cognitiveservices.azure.com/`, use *adventureworks-openai*).

    ```sql
    -- Create a database master key if one doesn't exist
    IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
        CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<your strong password here>';
    GO

    -- Create a credential using Managed Identity
    CREATE DATABASE SCOPED CREDENTIAL [https://<your-openai-endpoint>.cognitiveservices.azure.com]
    WITH IDENTITY = 'Managed Identity', SECRET = '{"resourceid":"https://cognitiveservices.azure.com"}';
    GO
    ```

    > &#128221; Replace `<your strong password here>` with a strong password. Replace `<your-openai-endpoint>` with the endpoint name from your Azure OpenAI resource (for example, *adventureworks-openai*). The `IDENTITY = 'Managed Identity'` tells Azure SQL Database to authenticate using its system-assigned managed identity. The `resourceid` in the SECRET specifies the Azure OpenAI audience. No API key is needed.

1. Now create an external model reference for the embedding model. This reference allows you to use `AI_GENERATE_EMBEDDINGS` directly in T-SQL. Replace `<your-openai-endpoint>` with your endpoint name.

    ```sql
    -- Create an external model reference for embeddings
    CREATE EXTERNAL MODEL my_embedding_model
    WITH (
        LOCATION = 'https://<your-openai-endpoint>.cognitiveservices.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=<your-api-version>',
        API_FORMAT = 'Azure OpenAI',
        MODEL_TYPE = EMBEDDINGS,
        MODEL = 'text-embedding-3-small',
        CREDENTIAL = [https://<your-openai-endpoint>.cognitiveservices.azure.com]
    );
    GO
    ```

    > &#128221; Replace `<your-openai-endpoint>` with the same endpoint name you used in the credential, and `<your-api-version>` with the API version from your text-embedding-3-small **Target URI**. You can also copy the entire `LOCATION` value directly from the Target URI. The `MODEL` option is required and must match the model name.

---

## Add a vector column and generate embeddings

In this section, you add a vector column to the ProductReview table, generate embeddings for review text, and create a vector index for efficient similarity search.

> &#128221; Skip this section if your `dbo.ProductReview` table already has a `ReviewVector` column with generated embeddings.

1. First, add a vector column to the `dbo.ProductReview` table to store review embeddings:

    ```sql
    -- Add a vector column to store review text embeddings
    ALTER TABLE dbo.ProductReview
    ADD ReviewVector VECTOR(1536);
    GO
    ```

    > &#128221; The `VECTOR(1536)` data type stores a 1536-dimensional vector, which matches the output of the *text-embedding-3-small* model.

1. Generate embeddings for each review by combining the product name, review title, and review text. The script processes reviews in batches of 30 with a short delay between batches to avoid API rate limits:

    ```sql
    -- Generate embeddings in batches to avoid API rate limits
    DECLARE @batchSize INT = 30;
    DECLARE @rowsUpdated INT = 1;
    DECLARE @retryCount INT;
    DECLARE @maxRetries INT = 3;

    WHILE @rowsUpdated > 0
    BEGIN
        SET @retryCount = 0;

        RETRY:
        BEGIN TRY
            UPDATE TOP (@batchSize) r
            SET r.ReviewVector = AI_GENERATE_EMBEDDINGS(
                p.Name + ' - ' + r.ReviewTitle + ': ' + r.ReviewText
                USE MODEL my_embedding_model)
            FROM dbo.ProductReview r
            INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
            WHERE r.ReviewVector IS NULL;

            SET @rowsUpdated = @@ROWCOUNT;

            -- Brief pause between batches to respect API rate limits
            IF @rowsUpdated > 0
                WAITFOR DELAY '00:00:02';
        END TRY
        BEGIN CATCH
            SET @retryCount += 1;
            IF @retryCount <= @maxRetries
            BEGIN
                PRINT 'Rate limited. Retrying in 5 seconds... (Attempt ' 
                    + CAST(@retryCount AS NVARCHAR(10)) + ' of ' 
                    + CAST(@maxRetries AS NVARCHAR(10)) + ')';
                WAITFOR DELAY '00:00:05';
                GOTO RETRY;
            END
            ELSE
                THROW;
        END CATCH
    END
    GO
    ```

    > &#128221; This step may take a couple of minutes. The script processes 30 reviews per batch with a 2-second pause between batches. If the API returns a rate-limit error, it retries up to three times with a 5-second wait. The product name, review title, and review text are embedded together so that vector search can match on both the product being reviewed and the customer's experience.

1. Verify that the embeddings were generated:

    ```sql
    -- Check how many reviews have embeddings
    SELECT 
        COUNT(*) AS TotalReviews,
        COUNT(ReviewVector) AS ReviewsWithEmbeddings
    FROM dbo.ProductReview;
    GO
    ```

1. Enable preview features and create a vector index on the column for efficient approximate nearest neighbor (ANN) search:

    ```sql
    -- Enable preview features required for vector indexes
    ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
    GO

    -- Allow the table to remain writable after vector index creation
    ALTER DATABASE SCOPED CONFIGURATION SET ALLOW_STALE_VECTOR_INDEX = ON;
    GO

    -- Create a DiskANN vector index for fast approximate nearest neighbor search
    CREATE VECTOR INDEX IX_Review_ReviewVector
    ON dbo.ProductReview(ReviewVector)
    WITH (METRIC = 'cosine', TYPE = 'DISKANN');
    GO
    ```

    > &#128221; `CREATE VECTOR INDEX` creates a DiskANN-based approximate nearest neighbor (ANN) index, which is fundamentally different from a regular nonclustered index. DiskANN builds a graph structure that navigates through vectors to find close matches efficiently. The `ALLOW_STALE_VECTOR_INDEX` setting keeps the table writable. Without it, the table becomes read-only when a vector index exists. For large tables, the ANN index dramatically speeds up similarity search by avoiding a full scan of every row.

---

## Retrieve data using vector search and format it as JSON context

In this section, you practice the **retrieval** step of RAG. Instead of using a hardcoded `WHERE` clause, you convert the user's question into an embedding and use `VECTOR_SEARCH` to find the most relevant reviews. Then you format the results as JSON.

1. Run the following query to use the `VECTOR_SEARCH` function for approximate nearest neighbor search. This function uses the DiskANN vector index for fast retrieval:

    ```sql
    -- Convert a question to an embedding and find the closest matching reviews
    DECLARE @userQuestion NVARCHAR(1000) = 'What mountain bike can handle really technical rocky trails?';
    DECLARE @questionVector VECTOR(1536);

    -- Generate embedding for the question
    SELECT @questionVector = AI_GENERATE_EMBEDDINGS(@userQuestion USE MODEL my_embedding_model);

    -- Find the top 5 most relevant reviews using ANN vector search
    SELECT
        p.Name AS ProductName,
        p.ListPrice,
        pc.Name AS Category,
        r.Rating,
        r.ReviewTitle,
        r.ReviewText,
        vs.distance AS Distance
    FROM VECTOR_SEARCH(
        TABLE = dbo.ProductReview AS r,
        COLUMN = ReviewVector,
        SIMILAR_TO = @questionVector,
        METRIC = 'cosine',
        TOP_N = 5
    ) AS vs
    INNER JOIN SalesLT.Product p 
        ON r.ProductID = p.ProductID
    INNER JOIN SalesLT.ProductCategory pc 
        ON p.ProductCategoryID = pc.ProductCategoryID
    FOR JSON PATH;
    GO
    ```

    > &#128221; `VECTOR_SEARCH` performs an approximate nearest neighbor (ANN) search using the DiskANN vector index. Unlike `VECTOR_DISTANCE` with `ORDER BY` (which scans every row), `VECTOR_SEARCH` navigates the graph index to find the closest matches efficiently. The `distance` column is automatically included in the results. Lower distance values mean higher relevance. Notice how each review is unique. Unlike product descriptions where multiple sizes of the same bike share the same text, each review describes a distinct customer experience.

---

## Build an augmented prompt with database context

Now you combine retrieved data with a system message and user question to build the **augmented** prompt. This prompt is the "A" in RAG.

1. Run the following script to build a complete RAG prompt in T-SQL. This script uses vector search to retrieve relevant reviews, then builds the augmented prompt:

    ```sql
    DECLARE @userQuestion NVARCHAR(1000) = 'What is the best bike for commuting to work in rainy weather?';
    DECLARE @questionVector VECTOR(1536);
    DECLARE @context NVARCHAR(MAX);
    DECLARE @payload NVARCHAR(MAX);

    -- Step 1: Convert the question to an embedding
    SELECT @questionVector = AI_GENERATE_EMBEDDINGS(@userQuestion USE MODEL my_embedding_model);

    -- Step 2: Retrieve relevant reviews using ANN vector search
    SET @context = (
        SELECT
            p.Name AS ProductName,
            p.ListPrice,
            pc.Name AS Category,
            r.Rating,
            r.ReviewTitle,
            r.ReviewText
        FROM VECTOR_SEARCH(
            TABLE = dbo.ProductReview AS r,
            COLUMN = ReviewVector,
            SIMILAR_TO = @questionVector,
            METRIC = 'cosine',
            TOP_N = 5
        ) AS vs
        INNER JOIN SalesLT.Product p 
            ON r.ProductID = p.ProductID
        INNER JOIN SalesLT.ProductCategory pc 
            ON p.ProductCategoryID = pc.ProductCategoryID
        FOR JSON PATH
    );

    -- Step 3: Build augmented prompt using JSON_OBJECT and JSON_ARRAY
    SET @payload = JSON_OBJECT(
        'messages': JSON_ARRAY(
            JSON_OBJECT(
                'role': 'system', 
                'content': 'You are an Adventure Works product assistant. Answer questions using only the provided product reviews and data. Mention specific customer experiences from the reviews when relevant. Be concise and helpful. If the data does not contain enough information, say so.'
            ),
            JSON_OBJECT(
                'role': 'user', 
                'content': 'Product reviews: ' + ISNULL(@context, '[]') + CHAR(10) + CHAR(10) + 'Customer question: ' + @userQuestion
            )
        ),
        'max_tokens': CAST(500 AS INT),
        'temperature': 0.5
    );

    -- Display the constructed payload
    SELECT @payload AS AugmentedPrompt;
    GO
    ```

    > &#128221; Review the output JSON. The `VECTOR_SEARCH` function finds the most semantically relevant customer reviews using the DiskANN vector index. Each review is unique, containing a real customer's experience, rating, and opinion, which gives the model richer context than product descriptions alone. The system message instructs the model to reference specific customer experiences in its answers.

---

## Call the Azure OpenAI endpoint and generate a response

This step is the "G" in RAG, the generation step. You send the augmented prompt to Azure OpenAI and extract the answer.

1. Run the following script to complete the full RAG pipeline. Replace `<your-openai-endpoint>` with your endpoint name and `<your-api-version>` with the API version from your gpt-4.1-mini Target URI.

    ```sql
    DECLARE @userQuestion NVARCHAR(1000) = 'Which tires last the longest and resist punctures?';
    DECLARE @questionVector VECTOR(1536);
    DECLARE @context NVARCHAR(MAX);
    DECLARE @payload NVARCHAR(MAX);
    DECLARE @response NVARCHAR(MAX);
    DECLARE @returnValue INT;

    -- Step 1: Convert the question to an embedding
    SELECT @questionVector = AI_GENERATE_EMBEDDINGS(@userQuestion USE MODEL my_embedding_model);

    -- Step 2: Retrieve relevant reviews using ANN vector search
    SET @context = (
        SELECT
            p.Name AS ProductName,
            p.ListPrice,
            pc.Name AS Category,
            r.Rating,
            r.ReviewTitle,
            r.ReviewText
        FROM VECTOR_SEARCH(
            TABLE = dbo.ProductReview AS r,
            COLUMN = ReviewVector,
            SIMILAR_TO = @questionVector,
            METRIC = 'cosine',
            TOP_N = 5
        ) AS vs
        INNER JOIN SalesLT.Product p 
            ON r.ProductID = p.ProductID
        INNER JOIN SalesLT.ProductCategory pc 
            ON p.ProductCategoryID = pc.ProductCategoryID
        FOR JSON PATH
    );

    -- Step 3: Build augmented prompt
    SET @payload = JSON_OBJECT(
        'messages': JSON_ARRAY(
            JSON_OBJECT(
                'role': 'system', 
                'content': 'You are an Adventure Works product assistant. Answer questions using only the provided product reviews and data. Mention specific customer experiences from the reviews when relevant. Be concise and helpful. If the data does not contain enough information, say so.'
            ),
            JSON_OBJECT(
                'role': 'user', 
                'content': 'Product reviews: ' + ISNULL(@context, '[]') + CHAR(10) + CHAR(10) + 'Customer question: ' + @userQuestion
            )
        ),
        'max_tokens': CAST(500 AS INT),
        'temperature': 0.5
    );

    -- Step 4: Call Azure OpenAI
    EXECUTE @returnValue = sp_invoke_external_rest_endpoint
        @url = N'https://<your-openai-endpoint>.cognitiveservices.azure.com/openai/deployments/gpt-4.1-mini/chat/completions?api-version=<your-api-version>',
        @method = 'POST',
        @payload = @payload,
        @credential = [https://<your-openai-endpoint>.cognitiveservices.azure.com],
        @response = @response OUTPUT;

    -- Step 5: Extract and display the answer
    IF @returnValue = 0
    BEGIN
        DECLARE @answer NVARCHAR(MAX);
        SET @answer = JSON_VALUE(@response, '$.result.choices[0].message.content');
        SELECT @answer AS AssistantResponse;
    END
    ELSE
    BEGIN
        SELECT 
            @returnValue AS HttpStatus,
            JSON_VALUE(@response, '$.response.status.http.description') AS ErrorDescription;
    END
    GO
    ```

    > &#128221; Replace `<your-openai-endpoint>` with the same endpoint name used in your credential, and `<your-api-version>` with the API version from your gpt-4.1-mini **Target URI**. The URL uses the `cognitiveservices.azure.com` domain, matching the credential and your Foundry portal Target URI.

---

## Create a RAG stored procedure

Now put it all together in a reusable stored procedure that your application can call.

1. Run the following script to create the stored procedure. Replace `<your-openai-endpoint>` with your endpoint name and `<your-api-version>` with the API version from your gpt-4.1-mini Target URI.

    ```sql
    CREATE OR ALTER PROCEDURE dbo.AskProductQuestion
        @Question NVARCHAR(1000),
        @Answer NVARCHAR(MAX) OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @questionVector VECTOR(1536);
        DECLARE @context NVARCHAR(MAX);
        DECLARE @payload NVARCHAR(MAX);
        DECLARE @response NVARCHAR(MAX);
        DECLARE @returnValue INT;

        -- Step 1: Convert the question to an embedding
        SELECT @questionVector = AI_GENERATE_EMBEDDINGS(@Question USE MODEL my_embedding_model);

        -- Step 2: Retrieve relevant reviews using ANN vector search
        SET @context = (
            SELECT
                p.Name AS ProductName,
                p.ListPrice,
                pc.Name AS Category,
                r.Rating,
                r.ReviewTitle,
                r.ReviewText
            FROM VECTOR_SEARCH(
                TABLE = dbo.ProductReview AS r,
                COLUMN = ReviewVector,
                SIMILAR_TO = @questionVector,
                METRIC = 'cosine',
                TOP_N = 5
            ) AS vs
            INNER JOIN SalesLT.Product p 
                ON r.ProductID = p.ProductID
            INNER JOIN SalesLT.ProductCategory pc 
                ON p.ProductCategoryID = pc.ProductCategoryID
            FOR JSON PATH
        );

        -- Check if context was retrieved
        IF @context IS NULL
        BEGIN
            SET @Answer = 'No reviews found matching your query. Please try a different question.';
            RETURN;
        END

        -- Step 3: Build the augmented prompt
        SET @payload = JSON_OBJECT(
            'messages': JSON_ARRAY(
                JSON_OBJECT(
                    'role': 'system', 
                    'content': 'You are an Adventure Works product assistant. Follow these rules:
    1. Answer only using the provided product reviews and data
    2. Reference specific customer experiences from the reviews when relevant
    3. Include star ratings to help the customer assess product quality
    4. Keep responses under 150 words
    5. Suggest related products when relevant'
                ),
                JSON_OBJECT(
                    'role': 'user', 
                    'content': 'Product reviews: ' + @context + CHAR(10) + CHAR(10) + 'Customer question: ' + @Question
                )
            ),
            'max_tokens': CAST(500 AS INT),
            'temperature': 0.5
        );

        -- Step 4: Call the model
        EXECUTE @returnValue = sp_invoke_external_rest_endpoint
            @url = N'https://<your-openai-endpoint>.cognitiveservices.azure.com/openai/deployments/gpt-4.1-mini/chat/completions?api-version=<your-api-version>',
            @method = 'POST',
            @payload = @payload,
            @credential = [https://<your-openai-endpoint>.cognitiveservices.azure.com],
            @response = @response OUTPUT;

        -- Step 5: Extract the answer or handle errors
        IF @returnValue = 0
            SET @Answer = JSON_VALUE(@response, '$.result.choices[0].message.content');
        ELSE IF @returnValue = 429
            SET @Answer = 'The service is currently busy. Please try again in a moment.';
        ELSE IF @returnValue IN (401, 403)
            SET @Answer = 'Authentication failed. Please check the credential configuration.';
        ELSE
            SET @Answer = 'Unable to process your question at this time. HTTP status: ' + CAST(@returnValue AS NVARCHAR(10));
    END;
    GO
    ```

    > &#128221; Replace `<your-openai-endpoint>` with the same endpoint name used in your credential, and `<your-api-version>` with the API version from your gpt-4.1-mini **Target URI**.

1. Test the stored procedure with a question about night riding safety:

    ```sql
    DECLARE @response NVARCHAR(MAX);

    EXEC dbo.AskProductQuestion
        @Question = 'I ride before sunrise and after dark. What lights actually work well?',
        @Answer = @response OUTPUT;

    SELECT @response AS AssistantResponse;
    GO
    ```

1. Try a question about bike maintenance:

    ```sql
    DECLARE @response NVARCHAR(MAX);

    EXEC dbo.AskProductQuestion
        @Question = 'How do I keep my bike maintained between shop visits?',
        @Answer = @response OUTPUT;

    SELECT @response AS AssistantResponse;
    GO
    ```

1. Test with a question about common complaints:

    ```sql
    DECLARE @response NVARCHAR(MAX);

    EXEC dbo.AskProductQuestion
        @Question = 'What are the most common problems or complaints people have with their bikes?',
        @Answer = @response OUTPUT;

    SELECT @response AS AssistantResponse;
    GO
    ```

    > &#128221; Each call follows the same RAG pattern: convert the question to an embedding, use `VECTOR_SEARCH` with the DiskANN index to retrieve the most relevant reviews from the database, augment the prompt with that data, and generate a grounded response. The model's answers should reference specific customer experiences from the reviews. Notice how vector search finds relevant reviews based on semantic meaning. For example, a question about "problems" retrieves low-rated reviews mentioning specific issues.

Try your own questions as well! The more you test with different queries, the better you understand how the RAG pipeline works and how the model uses the retrieved context to generate answers.

---

## Cleanup

If you aren't using the Azure SQL Database or the Azure OpenAI resources for any other purpose, you can clean up the resources you created in this exercise.

> &#128221; These resources are used on labs 9, 10, and 11.

If you provisioned a new resource group for this lab, you can simply delete the entire resource group to remove all resources at once. If you used an existing resource group, delete the Azure SQL Database and Azure OpenAI resource individually.

1. In the Azure portal, navigate to your resource group.
1. Select **Delete resource group** and confirm deletion by typing the resource group name.
1. Select **Delete** to remove all resources created in this lab.

---

You successfully completed this exercise.

In this exercise, you implemented a complete Retrieval-Augmented Generation (RAG) solution using Azure SQL Database and Azure OpenAI. You generated embeddings and created a vector index for fast retrieval, searched for semantically relevant reviews, formatted the results as context for a language model, built augmented prompts with grounding instructions, called the Azure OpenAI endpoint from T-SQL, and packaged the entire RAG pipeline into a reusable stored procedure with error handling.
