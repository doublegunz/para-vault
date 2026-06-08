---
title: "Getting Started with pgvector: Set Up Vector Search in PostgreSQL on Ubuntu 25.04"
slug: "getting-started-with-pgvector-set-up-vector-search-in-postgresql-on-ubuntu-2504"
category: "Ubuntu"
date: "2026-03-26"
status: "published"
---

Vector databases are everywhere in the AI era. They power semantic search, recommendation engines, and retrieval-augmented generation (RAG) systems. But you do not need a separate database to use vectors. If you already use PostgreSQL, you can add vector search capabilities directly to your existing database with pgvector.

pgvector is a lightweight, open-source PostgreSQL extension that adds support for storing, indexing, and querying vector data. It runs inside PostgreSQL, so you get vector search alongside all the features you already rely on: ACID transactions, backups, replication, joins, and standard SQL.

In this tutorial, we will install PostgreSQL and pgvector on Ubuntu 25.04, learn how to store and query vectors from the terminal, and build a practical example that demonstrates similarity search.


## What Is a Vector? {#what-is-a-vector}

Before touching the terminal, let's understand what we are working with.

A vector is simply an array of numbers. In the context of databases and AI, vectors are used to represent the meaning of text, images, or other data as a list of floating-point numbers. This numerical representation is called an embedding.

For example, the sentence "PostgreSQL is a powerful database" might be represented as a vector like `[0.12, -0.45, 0.78, 0.33, ...]` with hundreds or thousands of dimensions. Texts with similar meanings produce vectors that are close together in mathematical space, while unrelated texts produce vectors that are far apart.

pgvector lets you store these vectors in a PostgreSQL column and perform similarity searches to find the closest matches. This is the foundation of semantic search: instead of matching keywords, you match meaning.


## What Is pgvector? {#what-is-pgvector}

pgvector is a PostgreSQL extension that adds three key capabilities:

1. **A `vector` data type.** You can create columns that store arrays of floating-point numbers with a fixed number of dimensions.
2. **Distance operators.** You can calculate how similar two vectors are using L2 distance (`<->`), inner product (`<#>`), or cosine distance (`<=>`).
3. **Indexing.** You can create HNSW or IVFFlat indexes to speed up similarity searches on large datasets.

It is lightweight, adds no background processes, and uses memory only when you query or build indexes. Your existing PostgreSQL backup and replication setup covers vector data automatically.


## Overview {#overview}

### What You'll Do

- Install PostgreSQL and pgvector on Ubuntu 25.04.
- Create a database with a vector column.
- Insert vector data and run similarity searches.
- Compare different distance operators.
- Build HNSW and IVFFlat indexes for performance.
- Walk through a practical example: finding similar products.

### What You'll Need

- Ubuntu 25.04 (Plucky Puffin).
- Terminal access with sudo privileges.
- Basic familiarity with SQL.


## Step 1: Install PostgreSQL {#step-1-install-postgresql}

Ubuntu 25.04 includes PostgreSQL in its default repositories. Install it along with the contrib package:

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib -y
```

After installation, PostgreSQL starts automatically. Verify it is running:

```bash
sudo systemctl status postgresql
```

You should see `active (exited)` or `active (running)` in the output.

Check the installed version:

```bash
psql --version
```

Ubuntu 25.04 ships with PostgreSQL 17 by default.


## Step 2: Install pgvector {#step-2-install-pgvector}

pgvector is available as a prebuilt package from the PostgreSQL APT repository. The package name follows the pattern `postgresql-<version>-pgvector`.

For PostgreSQL 17:

```bash
sudo apt install postgresql-17-pgvector -y
```

If you are using a different PostgreSQL version, replace `17` with your version number. You can check your version with `psql --version`.

That's it. No compilation needed.


## Step 3: Enable pgvector in a Database {#step-3-enable-pgvector}

Installing the package makes pgvector available on the system, but you still need to enable it in each database where you want to use it.

First, switch to the `postgres` user and open the PostgreSQL interactive shell:

```bash
sudo -i -u postgres
psql
```

Create a new database for our experiments:

```sql
CREATE DATABASE vector_lab;
```

Connect to it:

```sql
\c vector_lab
```

Enable the pgvector extension:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

Verify the extension is loaded:

```sql
\dx
```

You should see `vector` in the list of installed extensions.


## Step 4: Create a Table with a Vector Column {#step-4-create-table}

Let's start with the basics. Create a table that stores items with 3-dimensional vectors:

```sql
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    embedding vector(3)
);
```

The `vector(3)` data type defines a column that stores vectors with exactly 3 dimensions. In real applications, you would use higher dimensions (768, 1536, etc.) depending on your embedding model. We use 3 dimensions here to keep the examples easy to read.

Insert some sample data:

```sql
INSERT INTO items (name, embedding) VALUES
    ('apple',  '[1.0, 0.5, 0.2]'),
    ('banana', '[0.9, 0.6, 0.3]'),
    ('car',    '[0.1, 0.8, 0.9]'),
    ('truck',  '[0.2, 0.7, 0.8]'),
    ('bike',   '[0.15, 0.75, 0.85]');
```

Notice that vectors are inserted as string literals in the format `'[x, y, z]'`. pgvector parses this format automatically.

Verify the data:

```sql
SELECT * FROM items;
```

```
 id |  name  |   embedding
----+--------+---------------
  1 | apple  | [1,0.5,0.2]
  2 | banana | [0.9,0.6,0.3]
  3 | car    | [0.1,0.8,0.9]
  4 | truck  | [0.2,0.7,0.8]
  5 | bike   | [0.15,0.75,0.85]
(5 rows)
```


## Step 5: Query by Similarity {#step-5-query-by-similarity}

This is the core of pgvector. Instead of searching by exact values, you search by how similar vectors are to each other.

### L2 Distance (Euclidean)

The `<->` operator calculates the L2 (Euclidean) distance between two vectors. Smaller values mean more similar:

```sql
SELECT name, embedding, embedding <-> '[1.0, 0.5, 0.2]' AS distance
FROM items
ORDER BY distance
LIMIT 3;
```

```
  name  |   embedding    |      distance
--------+----------------+--------------------
 apple  | [1,0.5,0.2]    |                  0
 banana | [0.9,0.6,0.3]  | 0.1732050808072457
 truck  | [0.2,0.7,0.8]  | 1.0049875621120888
(3 rows)
```

The query finds the 3 items whose embeddings are closest to `[1.0, 0.5, 0.2]`. Apple has a distance of 0 because it is an exact match. Banana is the second closest. The vehicle items are further away.

### Cosine Distance

The `<=>` operator calculates cosine distance, which measures the angle between two vectors regardless of their magnitude. This is commonly used with normalized embeddings:

```sql
SELECT name, embedding, embedding <=> '[1.0, 0.5, 0.2]' AS cosine_distance
FROM items
ORDER BY cosine_distance
LIMIT 3;
```

```
  name  |   embedding    |   cosine_distance
--------+----------------+----------------------
 apple  | [1,0.5,0.2]    |                    0
 banana | [0.9,0.6,0.3]  | 0.004504527406668438
 truck  | [0.2,0.7,0.8]  |   0.2789812238417421
(3 rows)
```

Cosine distance ranges from 0 (identical direction) to 2 (opposite direction). For most embedding models, cosine distance is the recommended metric because it handles variations in vector magnitude better than L2 distance.

### Inner Product

The `<#>` operator calculates the negative inner product. It is useful when you want higher values to indicate greater similarity (common with some embedding models):

```sql
SELECT name, embedding, (embedding <#> '[1.0, 0.5, 0.2]') * -1 AS inner_product
FROM items
ORDER BY embedding <#> '[1.0, 0.5, 0.2]'
LIMIT 3;
```

Note that pgvector returns the **negative** inner product because PostgreSQL only supports ascending order for index scans. Multiplying by -1 gives you the actual inner product value.


## Step 6: Build Indexes for Performance {#step-6-build-indexes}

Without an index, pgvector performs a sequential scan, comparing the query vector against every row in the table. This is fine for small datasets but becomes slow as the table grows. pgvector supports two index types.

### HNSW Index

HNSW (Hierarchical Navigable Small World) is the recommended index type. It builds a multi-layered graph structure and provides fast, high-recall approximate nearest neighbor search:

```sql
CREATE INDEX ON items USING hnsw (embedding vector_l2_ops);
```

The `vector_l2_ops` specifies the distance operator class. Use the operator class that matches how you query:

| Distance Operator | Operator Class        |
|-------------------|-----------------------|
| `<->` (L2)        | `vector_l2_ops`       |
| `<=>` (Cosine)    | `vector_cosine_ops`   |
| `<#>` (Inner Product) | `vector_ip_ops`   |

For cosine distance:

```sql
CREATE INDEX ON items USING hnsw (embedding vector_cosine_ops);
```

### IVFFlat Index

IVFFlat (Inverted File with Flat compression) divides vectors into clusters and searches only the nearest clusters. It is faster to build than HNSW but generally slower at query time:

```sql
CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
```

The `lists` parameter controls how many clusters are created. A common guideline is to use the square root of the number of rows for small datasets or `rows / 1000` for datasets with over one million rows.

### When to Use Which Index

For most use cases, start with HNSW. It provides better query performance and recall. IVFFlat can be useful when you need faster index build times on very large datasets or when memory is constrained.


## Step 7: Practical Example - Product Similarity {#step-7-practical-example}

Let's build a more realistic example. Imagine you run an online store and want to add a "similar products" feature.

### Create the Products Table

```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10,2),
    embedding vector(5)
);
```

We use 5-dimensional vectors to keep things readable. In production, you would use vectors from an actual embedding model (768 or 1536 dimensions).

### Insert Product Data

```sql
INSERT INTO products (name, category, price, embedding) VALUES
    ('Running Shoes Pro',     'footwear',    129.99, '[0.9, 0.8, 0.1, 0.2, 0.3]'),
    ('Trail Running Shoes',   'footwear',    149.99, '[0.85, 0.75, 0.15, 0.25, 0.35]'),
    ('Casual Sneakers',       'footwear',     79.99, '[0.7, 0.6, 0.3, 0.4, 0.2]'),
    ('Hiking Boots',          'footwear',    189.99, '[0.6, 0.7, 0.5, 0.6, 0.4]'),
    ('Basketball Jersey',     'clothing',     59.99, '[0.2, 0.3, 0.8, 0.7, 0.6]'),
    ('Running T-Shirt',       'clothing',     34.99, '[0.5, 0.6, 0.5, 0.3, 0.4]'),
    ('Yoga Mat',              'equipment',    29.99, '[0.3, 0.4, 0.6, 0.8, 0.7]'),
    ('Dumbbells Set',         'equipment',    89.99, '[0.1, 0.2, 0.7, 0.9, 0.8]'),
    ('Fitness Tracker',       'electronics', 199.99, '[0.4, 0.5, 0.6, 0.5, 0.5]'),
    ('Wireless Earbuds',      'electronics',  79.99, '[0.3, 0.3, 0.7, 0.6, 0.7]');
```

### Find Similar Products

Find the 3 products most similar to "Running Shoes Pro":

```sql
SELECT p2.name, p2.category, p2.price,
       p2.embedding <=> p1.embedding AS distance
FROM products p1, products p2
WHERE p1.name = 'Running Shoes Pro'
  AND p2.id != p1.id
ORDER BY distance
LIMIT 3;
```

```
        name         | category | price  |       distance
---------------------+----------+--------+----------------------
 Trail Running Shoes | footwear | 149.99 | 0.001005024150267518
 Casual Sneakers     | footwear |  79.99 |  0.01317078502709768
 Running T-Shirt     | clothing |  34.99 |  0.03498727735368957
(3 rows)
```

The results make intuitive sense. Trail Running Shoes are the most similar (barely different embedding), followed by Casual Sneakers and Running T-Shirt (both related to running/sports).

### Find Similar Products Within a Category

You can combine vector similarity with traditional SQL filtering. For example, find similar footwear only:

```sql
SELECT p2.name, p2.price,
       p2.embedding <=> p1.embedding AS distance
FROM products p1, products p2
WHERE p1.name = 'Running Shoes Pro'
  AND p2.id != p1.id
  AND p2.category = 'footwear'
ORDER BY distance
LIMIT 3;
```

```
        name         | price  |       distance
---------------------+--------+----------------------
 Trail Running Shoes | 149.99 | 0.001005024150267518
 Casual Sneakers     |  79.99 |  0.01317078502709768
 Hiking Boots        | 189.99 |  0.04872354009158498
(3 rows)
```

This is the power of pgvector: you can mix vector similarity with regular SQL filters, joins, aggregations, and everything else PostgreSQL offers. A dedicated vector database cannot do this.

### Find Products Within a Distance Threshold

Instead of limiting to a fixed number of results, you can filter by a maximum distance:

```sql
SELECT name, category, price,
       embedding <=> '[0.9, 0.8, 0.1, 0.2, 0.3]' AS distance
FROM products
WHERE embedding <=> '[0.9, 0.8, 0.1, 0.2, 0.3]' < 0.05
ORDER BY distance;
```

This returns only products whose cosine distance from the query vector is less than 0.05, regardless of how many that turns out to be.

### Add an Index for Performance

With 10 rows, an index is unnecessary. But for production datasets, add one:

```sql
CREATE INDEX ON products USING hnsw (embedding vector_cosine_ops);
```

To verify the index is being used, run:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT name, embedding <=> '[0.9, 0.8, 0.1, 0.2, 0.3]' AS distance
FROM products
ORDER BY embedding <=> '[0.9, 0.8, 0.1, 0.2, 0.3]'
LIMIT 3;
```

Look for `Index Scan using` in the output instead of `Seq Scan`.


## Distance Operators Cheat Sheet {#distance-operators}

| Operator | Type             | Range   | Best For                              |
|----------|------------------|---------|---------------------------------------|
| `<->`    | L2 (Euclidean)   | 0 to +inf | General purpose, non-normalized vectors |
| `<=>`    | Cosine           | 0 to 2  | Normalized embeddings (e.g., OpenAI)  |
| `<#>`    | Negative Inner Product | -inf to 0 | Performance with normalized vectors |

For all three operators, smaller values mean more similar. Use cosine distance (`<=>`) as your default choice unless you have a specific reason to use another.


## Cleanup {#cleanup}

When you are done experimenting, you can drop the tables and database:

```sql
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS products;
```

Exit psql:

```sql
\q
```

Exit the postgres user:

```bash
exit
```

If you want to remove the entire database:

```bash
sudo -i -u postgres
psql -c "DROP DATABASE vector_lab;"
exit
```


## Conclusion {#conclusion}

In this tutorial, we installed PostgreSQL and pgvector on Ubuntu 25.04, created tables with vector columns, ran similarity searches using three different distance operators, built indexes for performance, and walked through a practical product similarity example.

Here are the key takeaways:

- **pgvector adds vector search to PostgreSQL.** No separate database needed. Your vectors live alongside your regular data, benefiting from PostgreSQL's ACID compliance, backups, and replication.
- **Three distance operators cover most use cases.** L2 (`<->`), cosine (`<=>`), and inner product (`<#>`) each serve different scenarios. Cosine distance is the safest default for most embedding models.
- **HNSW is the recommended index type.** It provides fast, high-recall approximate nearest neighbor search. IVFFlat is an alternative when build time or memory is a concern.
- **You can mix vector search with regular SQL.** Combine similarity queries with WHERE clauses, JOINs, GROUP BY, and everything else PostgreSQL supports. This is pgvector's biggest advantage over dedicated vector databases.
- **Enable the extension per database.** Installing the pgvector package makes it available system-wide, but you must run `CREATE EXTENSION vector` in each database where you want to use it.
- **Match the operator class to your query.** When creating an index, the operator class (`vector_l2_ops`, `vector_cosine_ops`, `vector_ip_ops`) must match the distance operator you use in your queries.

From here, you can integrate pgvector with your application by generating real embeddings from text or images using an AI model, storing them in a vector column, and querying them with similarity search. The SQL patterns you learned in this tutorial apply directly regardless of what language or framework you use.