---
lab:
    title: 'Lab 9 – Generate and update embeddings in Azure SQL Database'
    module: 'Design and implement models and embeddings with SQL'
---

# Generate and update embeddings in Azure SQL Database

**Estimated Time: 30 minutes**

In this exercise, you create an external model reference, generate embeddings from text stored in Azure SQL Database using the `AI_GENERATE_EMBEDDINGS` function, and verify the results. You also explore how embeddings need to be maintained when source data changes. Finally, you perform a basic vector search to confirm that the embeddings capture semantic meaning.

You're a database developer for Adventure Works. Your team is adding AI-powered search capabilities to the product catalog. The first step is to generate and store vector embeddings for customer reviews so they're compared by semantic similarity later. You also need to understand how embeddings stay in sync when review data changes.

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

The AdventureWorksLT sample database contains product information but no customer reviews. In this step, you download and run a script that creates a **ProductReview** table with 140 realistic reviews across many product categories. These reviews provide the text data that you generate embeddings for in this exercise.

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

1. To create a database scoped credential using managed identity, open a new query window and run the following script. Replace `<your-openai-endpoint>` with the endpoint name from your Azure OpenAI resource (for example, if your endpoint is `https://adventureworks-openai.cognitiveservices.azure.com/`, use *adventureworks-openai*).

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

In this section, you add a vector column to the ProductReview table and generate embeddings for the review text. The embedding model converts each review's text into a 1536-dimensional vector that captures its semantic meaning.

1. To store review embeddings, add a vector column to the `dbo.ProductReview` table:

    ```sql
    -- Add a vector column to store review text embeddings
    ALTER TABLE dbo.ProductReview
    ADD ReviewVector VECTOR(1536);
    GO
    ```

    > &#128221; The `VECTOR(1536)` data type stores a 1536-dimensional vector, which matches the output of the *text-embedding-3-small* model. Each element is stored as a single-precision (4-byte) float, so a 1536-dimension vector uses about 6 KB per row.

1. Test embedding generation on a single review first. This test confirms the external model and credential are working:

    ```sql
    -- Test embedding generation on a single review
    SELECT TOP 1
        r.ReviewID,
        r.ReviewTitle,
        AI_GENERATE_EMBEDDINGS(
            r.ReviewTitle + ': ' + r.ReviewText
            USE MODEL my_embedding_model
        ) AS TestEmbedding
    FROM dbo.ProductReview r;
    GO
    ```

    > &#128221; You should see a long array of floating-point numbers. This confirms that your credential, external model, and Azure OpenAI deployment are all configured correctly. If you get an error, check that the managed identity role assignment has taken effect (it can take up to 5 minutes).

1. Now generate embeddings for all reviews in batches. The script combines the product name, review title, and review text to create richer embeddings, and processes 30 reviews per batch with retry logic for rate limits:

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

---

## Verify and inspect the generated embeddings

After generating embeddings, verify that all reviews have vectors and inspect the vector properties.

1. Check how many reviews have embeddings:

    ```sql
    -- Verify embedding counts
    SELECT 
        COUNT(*) AS TotalReviews,
        COUNT(ReviewVector) AS ReviewsWithEmbeddings,
        COUNT(*) - COUNT(ReviewVector) AS ReviewsMissingEmbeddings
    FROM dbo.ProductReview;
    GO
    ```

    > &#128221; All 140 reviews should have embeddings. If any are missing, run the batch embedding script again as it only processes rows where `ReviewVector IS NULL`.

1. Inspect the vector dimensions and data type using `VECTORPROPERTY`:

    ```sql
    -- Check vector metadata
    SELECT TOP 1
        r.ReviewID,
        r.ReviewTitle,
        VECTORPROPERTY(r.ReviewVector, 'Dimensions') AS VectorDimensions,
        VECTORPROPERTY(r.ReviewVector, 'BaseType') AS VectorBaseType,
        DATALENGTH(r.ReviewVector) AS VectorSizeBytes
    FROM dbo.ProductReview r
    WHERE r.ReviewVector IS NOT NULL;
    GO
    ```

    > &#128221; `VECTORPROPERTY` returns metadata about a vector. You should see 1536 dimensions, a `float` base type, and approximately 6,148 bytes per vector. This function is useful for validating that vectors have the expected structure, especially when troubleshooting dimension mismatch errors.

1. View a sample of actual vector values for a review:

    ```sql
    -- View a sample embedding
    SELECT TOP 1
        r.ReviewID,
        r.ReviewTitle,
        LEFT(CAST(r.ReviewVector AS NVARCHAR(MAX)), 200) AS EmbeddingPreview
    FROM dbo.ProductReview r
    WHERE r.ReviewVector IS NOT NULL;
    GO
    ```

    > &#128221; The embedding is a JSON array of floating-point numbers. The full vector has 1536 elements, so this query shows only the first 200 characters. Each number represents a dimension of meaning that the embedding model learned during training.

---

## Validate embeddings with a basic vector search

To confirm that the embeddings capture semantic meaning, run a basic vector similarity search using `VECTOR_DISTANCE`. This function calculates the cosine distance between two vectors, where smaller values indicate greater similarity.

1. Search for reviews similar to a natural language question:

    ```sql
    -- Find reviews semantically similar to a question
    DECLARE @searchText NVARCHAR(1000) = 'Which tires last the longest and resist punctures?';
    DECLARE @searchVector VECTOR(1536);

    -- Generate an embedding for the search text
    SELECT @searchVector = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL my_embedding_model);

    -- Find the 5 closest reviews by cosine distance
    SELECT TOP 5
        p.Name AS ProductName,
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        VECTOR_DISTANCE('cosine', @searchVector, r.ReviewVector) AS Distance
    FROM dbo.ProductReview r
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    ORDER BY Distance;
    GO
    ```

    > &#128221; The results should show tire-related reviews discussing puncture resistance and durability, even though the search text and review text use different wording. This confirms that the embeddings capture semantic meaning. `VECTOR_DISTANCE` with cosine metric returns values between 0 (identical) and 2 (opposite). Lower values mean the review is more relevant to the question.

1. Compare the semantic search to a simple keyword search:

    ```sql
    -- Keyword search for comparison
    SELECT TOP 5
        p.Name AS ProductName,
        r.ReviewTitle,
        r.ReviewText,
        r.Rating
    FROM dbo.ProductReview r
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    WHERE r.ReviewText LIKE '%puncture%';
    GO
    ```

    > &#128221; The `LIKE` search only finds reviews containing the exact word "puncture." The vector search found reviews about tire durability and longevity that describe the same concept using different words. This difference illustrates why embeddings are valuable for search.

---

## Explore embedding maintenance

Embeddings are a snapshot of the source text at the time they were generated. When the source text changes, the embedding becomes stale and no longer reflects the current content. In this section, you observe this problem and practice regenerating embeddings.

1. Pick a review and note its current embedding distance from a known query:

    ```sql
    -- Check distance of a specific review before update
    DECLARE @searchVector VECTOR(1536);
    SELECT @searchVector = AI_GENERATE_EMBEDDINGS('warm winter cycling gloves' USE MODEL my_embedding_model);

    SELECT
        r.ReviewID,
        r.ReviewTitle,
        r.ReviewText,
        VECTOR_DISTANCE('cosine', @searchVector, r.ReviewVector) AS DistanceBefore
    FROM dbo.ProductReview r
    WHERE r.ReviewID = 124;
    GO
    ```

    > &#128221; Review 124 is about warm winter gloves. Note the distance value. The embedding currently reflects this content, so the distance should be small.

1. Now update the review text to something different. The embedding is now stale since it still reflects the original text:

    ```sql
    -- Change the review text without updating the embedding
    UPDATE dbo.ProductReview
    SET ReviewText = 'These tires are the most puncture-resistant tires I have ever used. Over 3000 miles with zero flats on rough gravel roads.',
        ReviewTitle = N'Indestructible tires'
    WHERE ReviewID = 124;
    GO
    ```

1. Check the distance again. The embedding still reflects the old glove review, but the text is now about tires:

    ```sql
    -- Check distance after text change (embedding is stale)
    DECLARE @searchVector VECTOR(1536);
    SELECT @searchVector = AI_GENERATE_EMBEDDINGS('warm winter cycling gloves' USE MODEL my_embedding_model);

    SELECT
        r.ReviewID,
        r.ReviewTitle,
        r.ReviewText,
        VECTOR_DISTANCE('cosine', @searchVector, r.ReviewVector) AS DistanceAfterTextChange
    FROM dbo.ProductReview r
    WHERE r.ReviewID = 124;
    GO
    ```

    > &#128221; The distance is still small because the embedding has not been updated. The vector still represents "warm winter gloves" even though the text now describes puncture-resistant tires. A vector search for gloves would incorrectly return this tire review. This is why embedding maintenance is important.

1. Regenerate the embedding for the updated review:

    ```sql
    -- Regenerate the embedding to match the updated text
    UPDATE r
    SET r.ReviewVector = AI_GENERATE_EMBEDDINGS(
        p.Name + ' - ' + r.ReviewTitle + ': ' + r.ReviewText
        USE MODEL my_embedding_model)
    FROM dbo.ProductReview r
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    WHERE r.ReviewID = 124;
    GO
    ```

1. Verify the distance now reflects the updated content:

    ```sql
    -- Check distance after embedding regeneration
    DECLARE @searchVector VECTOR(1536);
    SELECT @searchVector = AI_GENERATE_EMBEDDINGS('warm winter cycling gloves' USE MODEL my_embedding_model);

    SELECT
        r.ReviewID,
        r.ReviewTitle,
        r.ReviewText,
        VECTOR_DISTANCE('cosine', @searchVector, r.ReviewVector) AS DistanceAfterRegeneration
    FROM dbo.ProductReview r
    WHERE r.ReviewID = 124;
    GO
    ```

    > &#128221; The distance should now be much larger because the embedding reflects the tire content, not the glove content. The vector and the text are back in sync. In production, you would automate this regeneration using triggers, Change Tracking, Change Data Capture, or an external process like Azure Functions. The right approach depends on how often your data changes and how quickly embeddings need to reflect those changes.

1. Restore the original review so the data is consistent for later labs:

    ```sql
    -- Restore the original review text and regenerate the embedding
    UPDATE dbo.ProductReview
    SET ReviewTitle = N'Warm hands well below freezing',
        ReviewText = N'Rode through an entire winter with the Full-Finger Gloves and never had cold fingers even at minus 5 degrees with wind chill. The fleece lining is cozy without being bulky and I can still operate my brake levers precisely. Essential cold weather gear.'
    WHERE ReviewID = 124;
    GO

    -- Regenerate the embedding for the restored text
    UPDATE r
    SET r.ReviewVector = AI_GENERATE_EMBEDDINGS(
        p.Name + ' - ' + r.ReviewTitle + ': ' + r.ReviewText
        USE MODEL my_embedding_model)
    FROM dbo.ProductReview r
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    WHERE r.ReviewID = 124;
    GO
    ```

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

In this exercise, you learned how to store and generate vector embeddings in Azure SQL Database. You added a vector column and generated embeddings individually and in batches with retry logic. You inspected vector metadata such as dimensions and storage size. You validated embeddings with a similarity search and compared the results to a traditional keyword search. Finally, you observed how embeddings become stale when source text changes and how to regenerate them to restore consistency.
