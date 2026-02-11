---
lab:
    title: 'Lab 10 – Implement intelligent search with full-text, vector, and hybrid queries'
    module: 'Design and implement models and embeddings with SQL'
---

# Implement intelligent search with full-text, vector, and hybrid queries

**Estimated Time: 45 minutes**

In this exercise, you implement different search approaches in Azure SQL Database. You create full-text indexes, run vector searches using stored embeddings, and combine both techniques with hybrid search using Reciprocal Rank Fusion (RRF). You then compare how each search approach handles the same query and observe the differences in results.

You're a database developer for Adventure Works. Your team wants to improve product search so customers can find relevant items whether they search by exact keywords or describe what they need in natural language. You implement full-text search for keyword matching, vector search for semantic similarity, and hybrid search to combine both approaches.

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

The AdventureWorksLT sample database contains product information but no customer reviews. In this step, you download and run a script that creates a **ProductReview** table with 140 realistic reviews across many product categories. These reviews provide rich text data to search through using full-text, vector, and hybrid search.

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

    > &#128221; `CREATE VECTOR INDEX` creates a DiskANN-based approximate nearest neighbor (ANN) index, which is fundamentally different from a regular nonclustered index. DiskANN builds a graph structure that navigates through vectors to find close matches efficiently. The `ALLOW_STALE_VECTOR_INDEX` setting keeps the table writable. Without it, the table becomes read-only when a vector index exists.

---

## Create a full-text index

Full-text search requires a full-text index on the text columns you want to search. In this section, you create a full-text catalog and index on the `ReviewTitle` and `ReviewText` columns of the `ProductReview` table.

1. Create a full-text catalog and a full-text index:

    ```sql
    -- Create a full-text catalog
    CREATE FULLTEXT CATALOG ProductReviewCatalog AS DEFAULT;
    GO

    -- Create a full-text index on ReviewTitle and ReviewText
    CREATE FULLTEXT INDEX ON dbo.ProductReview
    (
        ReviewTitle LANGUAGE 1033,
        ReviewText LANGUAGE 1033
    )
    KEY INDEX PK_ProductReview
    ON ProductReviewCatalog
    WITH (CHANGE_TRACKING AUTO);
    GO
    ```

    > &#128221; The `KEY INDEX` must reference the unique index on the table's primary key. `LANGUAGE 1033` specifies English, which enables inflectional matching (for example, "ride" matching "riding"). `CHANGE_TRACKING AUTO` keeps the index updated as data changes.

1. Verify the full-text index was created and is populated:

    ```sql
    -- Check full-text index status
    SELECT 
        OBJECTPROPERTY(OBJECT_ID('dbo.ProductReview'), 'TableFullTextPopulateStatus') AS PopulateStatus,
        OBJECTPROPERTY(OBJECT_ID('dbo.ProductReview'), 'TableHasActiveFulltextIndex') AS HasActiveIndex;
    GO
    ```

    > &#128221; A `PopulateStatus` of **0** means the full-text index is fully populated and ready for queries. A value of **1** means population is still in progress. `HasActiveIndex` should be **1**.

---

## Search with full-text predicates

Full-text search uses predicates like `CONTAINS` and `FREETEXT` to query the full-text index. `CONTAINS` looks for exact words or phrases. `FREETEXT` matches word forms and inflections automatically.

1. Use `CONTAINS` to search for reviews mentioning a specific word:

    ```sql
    -- Find reviews that contain the word "puncture"
    SELECT 
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        p.Name AS ProductName
    FROM dbo.ProductReview r
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    WHERE CONTAINS(r.ReviewText, 'puncture');
    GO
    ```

    > &#128221; `CONTAINS` searches the full-text index for the exact word "puncture." It returns only reviews where that specific word appears.

1. Use `FREETEXT` to search for a phrase. `FREETEXT` automatically expands search terms to include inflectional forms:

    ```sql
    -- Find reviews about gloves and warmth
    SELECT TOP 10
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        p.Name AS ProductName
    FROM dbo.ProductReview r
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    WHERE FREETEXT(r.ReviewText, 'warm gloves for cold winter commuting');
    GO
    ```

    > &#128221; `FREETEXT` handles inflections, so "warm" can match "warmth" or "warming," and "commuting" can match "commute" or "commuter." It also drops stopwords like "for" and "the." Compare this to `CONTAINS`, which would require you to specify each word form explicitly. Use `TOP` with `FREETEXT` since broad phrases can match many rows.

    `FREETEXT` is more flexible, but it might return less relevant results if the search phrase is too broad. `CONTAINS` gives you more control but requires more precise queries.

1. Use `CONTAINSTABLE` to get ranked results with relevance scores:

    ```sql
    -- Search with ranking scores
    SELECT TOP 10
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        p.Name AS ProductName,
        ft.[RANK] AS FullTextRank
    FROM dbo.ProductReview r
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    INNER JOIN CONTAINSTABLE(dbo.ProductReview, (ReviewTitle, ReviewText), 
        'FORMSOF(INFLECTIONAL, mountain) AND FORMSOF(INFLECTIONAL, trail)') AS ft
        ON r.ReviewID = ft.[KEY]
    ORDER BY ft.[RANK] DESC;
    GO
    ```

    > &#128221; `CONTAINSTABLE` returns a table with a `KEY` column (matching the primary key) and a `RANK` column indicating how well each row matches. `FORMSOF(INFLECTIONAL, mountain)` matches "mountain," "mountains," and other inflected forms. The `AND` operator requires both terms to appear.

1. Use a prefix search to find reviews where words start with specific characters:

    ```sql
    -- Find reviews with words starting with "comfort"
    SELECT 
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        p.Name AS ProductName
    FROM dbo.ProductReview r
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    WHERE CONTAINS(r.ReviewText, '"comfort*"');
    GO
    ```

    > &#128221; The prefix search `"comfort*"` matches "comfort," "comfortable," "comfortably," and any other word beginning with "comfort." This is useful when you want to capture variations of a root word without listing every form.

---

## Search with vector similarity

Vector search finds reviews based on the semantic meaning of text, not just keyword matches. A question about "keeping drinks cold on a ride" can find reviews about water bottles even if those exact words don't appear.

1. Use `VECTOR_DISTANCE` for exact nearest neighbor search. This option calculates the cosine distance between the query embedding and every review:

    ```sql
    -- Exact vector search using VECTOR_DISTANCE
    DECLARE @searchText NVARCHAR(1000) = 'comfortable seat for long distance touring';
    DECLARE @searchVector VECTOR(1536);

    SELECT @searchVector = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL my_embedding_model);

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

    > &#128221; `VECTOR_DISTANCE` calculates the cosine distance between two vectors. Lower values mean higher similarity. This function scans every row in the table, which works well for smaller datasets. Notice that the results include reviews about touring bikes and saddle comfort even if they do not contain the exact words "comfortable seat."

1. Use `VECTOR_SEARCH` with the DiskANN index for approximate nearest neighbor (ANN) search. This index is optimized for large datasets and provides faster results:

    ```sql
    -- Approximate vector search using VECTOR_SEARCH with DiskANN index
    DECLARE @searchText NVARCHAR(1000) = 'something to keep me visible when riding at night';
    DECLARE @searchVector VECTOR(1536);

    SELECT @searchVector = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL my_embedding_model);

    SELECT
        p.Name AS ProductName,
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        pc.Name AS Category,
        vs.distance AS Distance
    FROM VECTOR_SEARCH(
        TABLE = dbo.ProductReview AS r,
        COLUMN = ReviewVector,
        SIMILAR_TO = @searchVector,
        METRIC = 'cosine',
        TOP_N = 5
    ) AS vs
    INNER JOIN SalesLT.Product p 
        ON r.ProductID = p.ProductID
    INNER JOIN SalesLT.ProductCategory pc 
        ON p.ProductCategoryID = pc.ProductCategoryID
    ORDER BY vs.distance;
    GO
    ```

    > &#128221; `VECTOR_SEARCH` uses the DiskANN index to find approximate nearest neighbors without scanning every row. The query describes a concept ("visible when riding at night") rather than specific keywords. Vector search finds reviews about lights, reflective gear, and visibility even when those words do not appear in the search text.

1. Check vector metadata using `VECTORPROPERTY`:

    ```sql
    -- Inspect vector metadata
    SELECT TOP 1
        VECTORPROPERTY(ReviewVector, 'Dimensions') AS VectorDimensions,
        VECTORPROPERTY(ReviewVector, 'BaseType') AS VectorBaseType
    FROM dbo.ProductReview
    WHERE ReviewVector IS NOT NULL;
    GO
    ```

    > &#128221; `VECTORPROPERTY` returns metadata about a vector column. This is useful for validating that your vectors have the expected number of dimensions and confirming the data type.

---

## Combine full-text and vector search with hybrid search

Full-text search excels at finding exact keywords but misses documents that express the same idea differently. Vector search captures semantic meaning but might miss important terms the user specified. Hybrid search runs both approaches and merges the results using Reciprocal Rank Fusion (RRF).

RRF combines ranked results from different sources by using rank positions instead of raw scores. The formula `1/(k + rank)` converts ranks into scores, where `k` is a smoothing constant (typically 60). Items appearing in both result sets get higher combined scores, pushing the most broadly relevant results to the top.

1. Run the following hybrid search query that combines full-text and vector search using RRF:

    ```sql
    DECLARE @searchText NVARCHAR(1000) = 'durable tires that resist punctures on rough terrain';
    DECLARE @searchVector VECTOR(1536);
    DECLARE @topN INT = 50;
    DECLARE @rrfK INT = 60;

    -- Generate embedding for the search phrase
    SELECT @searchVector = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL my_embedding_model);

    -- Run hybrid search with RRF
    WITH keyword_search AS (
        SELECT TOP(@topN)
            r.ReviewID,
            RANK() OVER (ORDER BY ft.[RANK] DESC) AS keyword_rank
        FROM dbo.ProductReview r
        INNER JOIN FREETEXTTABLE(dbo.ProductReview, (ReviewTitle, ReviewText), @searchText) AS ft
            ON r.ReviewID = ft.[KEY]
    ),
    vector_search AS (
        SELECT TOP(@topN)
            ReviewID,
            RANK() OVER (ORDER BY distance) AS vector_rank
        FROM (
            SELECT 
                r.ReviewID,
                vs.distance
            FROM VECTOR_SEARCH(
                TABLE = dbo.ProductReview AS r,
                COLUMN = ReviewVector,
                SIMILAR_TO = @searchVector,
                METRIC = 'cosine',
                TOP_N = 50
            ) AS vs
        ) AS similar_reviews
    ),
    combined AS (
        SELECT
            COALESCE(ks.ReviewID, vs.ReviewID) AS ReviewID,
            ks.keyword_rank,
            vs.vector_rank,
            COALESCE(1.0 / (@rrfK + ks.keyword_rank), 0.0) +
            COALESCE(1.0 / (@rrfK + vs.vector_rank), 0.0) AS rrf_score
        FROM keyword_search ks
        FULL OUTER JOIN vector_search vs ON ks.ReviewID = vs.ReviewID
    )
    SELECT TOP 10
        p.Name AS ProductName,
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        c.keyword_rank,
        c.vector_rank,
        c.rrf_score
    FROM combined c
    INNER JOIN dbo.ProductReview r ON c.ReviewID = r.ReviewID
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    ORDER BY c.rrf_score DESC;
    GO
    ```

    > &#128221; This query runs full-text and vector search in parallel using CTEs. The `keyword_search` CTE uses `FREETEXTTABLE` to rank reviews by BM25 relevance. The `vector_search` CTE uses `VECTOR_SEARCH` to rank reviews by embedding similarity. The `combined` CTE joins both result sets with a `FULL OUTER JOIN` and calculates the RRF score. Reviews that appear in both lists get higher combined scores. The final `SELECT` returns the top 10 results ordered by RRF score, showing which reviews performed well across both search methods.

1. Examine the output columns. Rows where both `keyword_rank` and `vector_rank` have values were found by both search methods and tend to have the highest RRF scores. Rows with a `NULL` in one rank column were found by only one method.

---

## Compare the three search approaches

To understand the strengths of each approach, run the same question through all three search methods and compare the results.

1. Run a full-text search for a comfortable family bike:

    ```sql
    -- Full-text search only
    SELECT TOP 5
        p.Name AS ProductName,
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        ft.[RANK] AS FullTextRank
    FROM dbo.ProductReview r
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    INNER JOIN FREETEXTTABLE(dbo.ProductReview, (ReviewTitle, ReviewText), 
        'comfortable bike for long weekend rides with the family') AS ft
        ON r.ReviewID = ft.[KEY]
    ORDER BY ft.[RANK] DESC;
    GO
    ```

1. Run a vector search with the same question:

    ```sql
    -- Vector search only
    DECLARE @searchText NVARCHAR(1000) = 'comfortable bike for long weekend rides with the family';
    DECLARE @searchVector VECTOR(1536);

    SELECT @searchVector = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL my_embedding_model);

    SELECT
        p.Name AS ProductName,
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        vs.distance AS Distance
    FROM VECTOR_SEARCH(
        TABLE = dbo.ProductReview AS r,
        COLUMN = ReviewVector,
        SIMILAR_TO = @searchVector,
        METRIC = 'cosine',
        TOP_N = 5
    ) AS vs
    INNER JOIN SalesLT.Product p 
        ON r.ProductID = p.ProductID
    ORDER BY vs.distance;
    GO
    ```

1. Run the hybrid search with the same question:

    ```sql
    -- Hybrid search with RRF
    DECLARE @searchText NVARCHAR(1000) = 'comfortable bike for long weekend rides with the family';
    DECLARE @searchVector VECTOR(1536);
    DECLARE @topN INT = 50;
    DECLARE @rrfK INT = 60;

    SELECT @searchVector = AI_GENERATE_EMBEDDINGS(@searchText USE MODEL my_embedding_model);

    WITH keyword_search AS (
        SELECT TOP(@topN)
            r.ReviewID,
            RANK() OVER (ORDER BY ft.[RANK] DESC) AS keyword_rank
        FROM dbo.ProductReview r
        INNER JOIN FREETEXTTABLE(dbo.ProductReview, (ReviewTitle, ReviewText), @searchText) AS ft
            ON r.ReviewID = ft.[KEY]
    ),
    vector_search AS (
        SELECT TOP(@topN)
            ReviewID,
            RANK() OVER (ORDER BY distance) AS vector_rank
        FROM (
            SELECT 
                r.ReviewID,
                vs.distance
            FROM VECTOR_SEARCH(
                TABLE = dbo.ProductReview AS r,
                COLUMN = ReviewVector,
                SIMILAR_TO = @searchVector,
                METRIC = 'cosine',
                TOP_N = 50
            ) AS vs
        ) AS similar_reviews
    ),
    combined AS (
        SELECT
            COALESCE(ks.ReviewID, vs.ReviewID) AS ReviewID,
            ks.keyword_rank,
            vs.vector_rank,
            COALESCE(1.0 / (@rrfK + ks.keyword_rank), 0.0) +
            COALESCE(1.0 / (@rrfK + vs.vector_rank), 0.0) AS rrf_score
        FROM keyword_search ks
        FULL OUTER JOIN vector_search vs ON ks.ReviewID = vs.ReviewID
    )
    SELECT TOP 5
        p.Name AS ProductName,
        r.ReviewTitle,
        r.ReviewText,
        r.Rating,
        c.keyword_rank,
        c.vector_rank,
        c.rrf_score
    FROM combined c
    INNER JOIN dbo.ProductReview r ON c.ReviewID = r.ReviewID
    INNER JOIN SalesLT.Product p ON r.ProductID = p.ProductID
    ORDER BY c.rrf_score DESC;
    GO
    ```

    > &#128221; Compare the three result sets side by side. Full-text search returns reviews containing words like "comfortable," "weekend," and "family." Vector search returns reviews about recreational bikes, relaxed geometry, and leisure riding that might use different wording. Hybrid search combines both, giving higher scores to reviews that appear in both result sets. This comparison illustrates when each approach works best: full-text for exact keyword matches, vector for semantic similarity, and hybrid when you want the best of both.

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

In this exercise, you implemented and compared three search approaches in Azure SQL Database: full-text search using a full-text index with keyword predicates and inflectional patterns, vector search using exact and approximate nearest neighbor queries with a DiskANN index, and hybrid search combining both methods with Reciprocal Rank Fusion to merge keyword and semantic results. You compared all three approaches on the same query to understand the strengths of each.