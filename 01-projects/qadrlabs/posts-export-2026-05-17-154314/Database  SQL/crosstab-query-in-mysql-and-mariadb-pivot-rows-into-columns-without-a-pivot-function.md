---
title: "Crosstab Query in MySQL and MariaDB: Pivot Rows into Columns Without a PIVOT Function"
slug: "crosstab-query-in-mysql-and-mariadb-pivot-rows-into-columns-without-a-pivot-function"
category: "Database & SQL"
date: "2026-04-24"
status: "published"
---

Every developer eventually faces this moment: the data is in the database, the logic is correct, but the report looks wrong. The business team wants a spreadsheet-style summary where products are rows and months are columns, yet what your `SELECT` returns is a long vertical list of individual transactions. You know the answer is somewhere in a pivot table, but MySQL gives you nothing but a blank stare when you type `PIVOT`.

That frustration is real, and it compounds quickly. Unlike SQL Server or Oracle, MySQL and MariaDB have no native `PIVOT` keyword. So developers either hand the raw data off to a spreadsheet, write fragile post-processing code in PHP or Python, or give up and produce a report that nobody finds readable. None of those options scale well.

The good news is that MySQL and MariaDB are fully capable of producing pivot output. You just need to understand two techniques: a static approach using conditional aggregation with `CASE WHEN`, and a dynamic approach that generates the query automatically using `GROUP_CONCAT` and prepared statements. This article walks through both, from schema setup to real output, so you finish with a technique you can apply immediately to your own data.

## Overview {#overview}

This article is a conceptual and practical guide to writing crosstab queries (also called pivot queries) in MySQL and MariaDB. It does not rely on any ORM, framework, or external library. Everything runs in plain SQL.

### What You'll Build

- A sample `sales` database with realistic transaction data spanning multiple products and months.
- A **static pivot query** that transforms monthly revenue rows into side-by-side columns using `CASE WHEN` and `SUM`.
- A **dynamic pivot query** that auto-generates column definitions from the data itself using `GROUP_CONCAT` and a prepared statement, so adding new months or products requires no changes to the query.

### What You'll Learn

- Why conditional aggregation is the foundation of pivot queries in MySQL and MariaDB.
- How to embed a `CASE WHEN` expression inside an aggregate function to create virtual columns.
- How `GROUP_CONCAT` can build SQL fragments dynamically, turning a list of distinct values into a full query string.
- How to use `PREPARE`, `EXECUTE`, and `DEALLOCATE PREPARE` to run dynamically constructed SQL safely.
- The trade-offs between static and dynamic pivots, including a note on `GROUP_CONCAT`'s default length limit.

### What You'll Need

- MySQL 8.0+ or MariaDB 10.4+. Both behave identically for everything covered in this article.
- Access to a MySQL or MariaDB client. The MySQL CLI works perfectly. GUI clients like DBeaver, TablePlus, or phpMyAdmin work just as well.
- Familiarity with basic SQL: `SELECT`, `GROUP BY`, `JOIN`, and aggregate functions like `SUM` and `COUNT`.

## Setting Up the Sample Data {#setting-up-sample-data}

Before writing any pivot logic, you need a dataset worth pivoting. The goal here is a schema that is simple enough to understand at a glance but realistic enough that the pivot output feels meaningful. A product sales table fits that requirement well. Each row records a single product's revenue for a given month, and the pivot will turn those months into columns so you can compare products side by side.

Open your MySQL or MariaDB client and run the following statements.

```sql
-- Create a dedicated database so the sample data stays isolated
CREATE DATABASE IF NOT EXISTS pivot_demo;
USE pivot_demo;

-- The sales table is intentionally simple: one row per product per month.
-- In a real system this might be an aggregated view of individual orders,
-- but keeping the schema flat here lets us focus entirely on the pivot logic.
CREATE TABLE IF NOT EXISTS sales (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    product     VARCHAR(50)    NOT NULL,
    month       VARCHAR(10)    NOT NULL,  -- stored as 'Jan', 'Feb', etc. for readability
    month_order TINYINT        NOT NULL,  -- numeric order so we can sort correctly
    revenue     DECIMAL(10, 2) NOT NULL
);

-- Insert twelve months of data across three products.
-- Notice that not every product has every month. Mouse is missing April,
-- and Keyboard is missing February. This gap is intentional because pivot
-- queries must handle missing intersections gracefully.
INSERT INTO sales (product, month, month_order, revenue) VALUES
    ('Laptop',   'Jan', 1, 15000.00),
    ('Laptop',   'Feb', 2, 18500.00),
    ('Laptop',   'Mar', 3, 17200.00),
    ('Laptop',   'Apr', 4, 21000.00),
    ('Mouse',    'Jan', 1,  3200.00),
    ('Mouse',    'Feb', 2,  2800.00),
    ('Mouse',    'Mar', 3,  3500.00),
    ('Keyboard', 'Jan', 1,  5100.00),
    ('Keyboard', 'Mar', 3,  4800.00),
    ('Keyboard', 'Apr', 4,  6200.00);
```

Save and run this block. To confirm the data loaded correctly, run a plain `SELECT` first. You want to see ten rows, each representing one product-month combination.

```sql
SELECT product, month, revenue
FROM sales
ORDER BY product, month_order;
```

The output should look like this:

```
+-----------+-------+---------+
| product   | month | revenue |
+-----------+-------+---------+
| Keyboard  | Jan   | 5100.00 |
| Keyboard  | Mar   | 4800.00 |
| Keyboard  | Apr   | 6200.00 |
| Laptop    | Jan   | 15000.00|
| Laptop    | Feb   | 18500.00|
| Laptop    | Mar   | 17200.00|
| Laptop    | Apr   | 21000.00|
| Mouse     | Jan   | 3200.00 |
| Mouse     | Feb   | 2800.00 |
| Mouse     | Mar   | 3500.00 |
+-----------+-------+---------+
10 rows in set (0.00 sec)
```

This vertical format is what you start with. By the end of this article, it will be a side-by-side table where Jan, Feb, Mar, and Apr each have their own column.

## Static Pivot: CASE WHEN with Aggregate Functions {#static-pivot}

The static pivot is the right tool when you know your column values in advance and they do not change often. If you are building a monthly sales report for a fixed fiscal year, you know there will always be twelve months. Writing a query with twelve explicit columns is verbose but completely predictable, easy to read, and straightforward to debug.

The core idea is elegant once you see it. Instead of letting the database summarize all revenue in a single column, you create one column per month and force each column to only "see" the revenue for its specific month. You achieve this by placing a `CASE WHEN` expression inside an aggregate function.

### How Conditional Aggregation Works

Think of it this way. A regular `SUM(revenue)` adds up every value it finds in the `revenue` column for a given group. A conditional `SUM(CASE WHEN month = 'Jan' THEN revenue ELSE 0 END)` still adds up every value it encounters, but anything that is not January contributes `0` to the total. The result is a sum that only counts January revenue, yet it appears as a proper column in your result set.

This is what makes it so powerful: aggregate functions in MySQL and MariaDB accept expressions, not just column names. A `CASE WHEN` block is an expression. Therefore, you can embed it inside `SUM`, `COUNT`, `AVG`, `MIN`, or `MAX` and the database will evaluate it row by row before aggregating.

Here is the simplest possible example to make this concrete before building the full query:

```sql
-- This query produces a single "virtual column" for January only.
-- The CASE WHEN acts as a filter inside the SUM: rows where month is
-- not 'Jan' contribute 0 rather than being excluded entirely.
-- GROUP BY product ensures we get one row per product.
SELECT
    product,
    SUM(CASE WHEN month = 'Jan' THEN revenue ELSE 0 END) AS jan
FROM sales
GROUP BY product;
```

Output:

```
+-----------+----------+
| product   | jan      |
+-----------+----------+
| Keyboard  |  5100.00 |
| Laptop    | 15000.00 |
| Mouse     |  3200.00 |
+-----------+----------+
3 rows in set (0.00 sec)
```

The mechanics are now visible. The `CASE WHEN` block inside `SUM` returns the actual revenue value for January rows and returns `0` for everything else. When `SUM` aggregates those values per product, the zeros simply do not add anything. The `AS jan` alias then gives the column a human-readable name.

### Building the Full Static Pivot

Extending this to all four months is a matter of repeating the pattern once per column. Each repetition targets one month and gives it a descriptive alias.

```sql
-- The full static pivot query.
-- Each SUM(CASE WHEN ...) block creates one month column.
-- The ELSE 0 ensures that missing months (like Mouse in April) show 0
-- rather than NULL. If you prefer NULL to signal "no data", replace 0 with NULL.
-- The ORDER BY uses MIN(month_order) to sort products by their earliest month.
SELECT
    product,
    SUM(CASE WHEN month = 'Jan' THEN revenue ELSE 0 END) AS jan,
    SUM(CASE WHEN month = 'Feb' THEN revenue ELSE 0 END) AS feb,
    SUM(CASE WHEN month = 'Mar' THEN revenue ELSE 0 END) AS mar,
    SUM(CASE WHEN month = 'Apr' THEN revenue ELSE 0 END) AS apr,
    SUM(revenue) AS total  -- A grand total column is easy to add here
FROM sales
GROUP BY product
ORDER BY product;
```

Run this query. The output transforms the ten-row vertical list into a clean three-row pivot table:

```
+-----------+----------+----------+----------+----------+----------+
| product   | jan      | feb      | mar      | apr      | total    |
+-----------+----------+----------+----------+----------+----------+
| Keyboard  |  5100.00 |     0.00 |  4800.00 |  6200.00 | 16100.00 |
| Laptop    | 15000.00 | 18500.00 | 17200.00 | 21000.00 | 71700.00 |
| Mouse     |  3200.00 |  2800.00 |  3500.00 |     0.00 |  9500.00 |
+-----------+----------+----------+----------+----------+----------+
3 rows in set (0.00 sec)
```

Notice how the missing intersections resolve cleanly. Keyboard had no February data, so it shows `0.00`. Mouse had no April data, so that cell also shows `0.00`. The `total` column correctly sums only the months that actually had revenue, since `SUM` adds the actual values and zeros contribute nothing.

You can swap `SUM` for any other aggregate function without changing the structure. If your underlying table contains individual order rows rather than pre-aggregated monthly totals, `COUNT(CASE WHEN month = 'Jan' THEN id END)` would give you order counts per month, and `AVG(CASE WHEN month = 'Jan' THEN revenue ELSE NULL END)` would give you average order value. The pattern is the same; only the function changes.

## Dynamic Pivot: GROUP_CONCAT and Prepared Statements {#dynamic-pivot}

The static approach has one significant limitation. Every time a new month, product category, or dimension value appears in your data, you must manually edit the query to add a new `CASE WHEN` block. For a monthly report covering a fixed calendar year this is manageable. For any report where column values are not known in advance, it becomes a maintenance problem.

The dynamic pivot solves this by writing the query for you. Instead of hardcoding `'Jan'`, `'Feb'`, `'Mar'`, and so on, the query reads the distinct values directly from the table, assembles a SQL string containing the appropriate `CASE WHEN` blocks, and then executes that string. Adding a new month to the data is enough; the query adapts on its own.

### Building the Dynamic SQL String

The key function is `GROUP_CONCAT`. Normally you use it to collapse multiple rows into a comma-separated string, for example concatenating product names into a single cell. Here you use it to concatenate SQL fragments: one `SUM(CASE WHEN ...)` expression per distinct month.

Start by understanding what `GROUP_CONCAT` will produce. Run this intermediary query first to see the raw output before any execution happens:

```sql
-- This SELECT builds the SQL fragment that will become the column list.
-- The subquery (distinct_months) handles deduplication first by selecting
-- only DISTINCT month and month_order pairs. Once the rows are already unique,
-- the outer GROUP_CONCAT can ORDER BY month_order as a plain column reference
-- without needing any nested aggregate function, which MariaDB does not allow.
SELECT
    GROUP_CONCAT(
        CONCAT(
            'SUM(CASE WHEN month = ''', month, ''' THEN revenue ELSE 0 END) AS `', month, '`'
        )
        ORDER BY month_order
    ) AS column_expressions
FROM (
    SELECT DISTINCT month, month_order FROM sales
) AS distinct_months;
```

The output of this query is a single string, not a result table. It is the raw material for your final query:

```
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| column_expressions                                                                                                                                                                                                               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| SUM(CASE WHEN month = 'Jan' THEN revenue ELSE 0 END) AS `Jan`,SUM(CASE WHEN month = 'Feb' THEN revenue ELSE 0 END) AS `Feb`,SUM(CASE WHEN month = 'Mar' THEN revenue ELSE 0 END) AS `Mar`,SUM(CASE WHEN month = 'Apr' THEN revenue ELSE 0 END) AS `Apr` |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

That string is exactly what you would have typed by hand in the static version. The difference is that it was generated from the actual data. If May data appears in the table next month, `GROUP_CONCAT` will automatically include a `SUM(CASE WHEN month = 'May' ...)` fragment the next time this runs.

### Executing the Dynamic Pivot

Now that you understand the intermediate output, you can build the full dynamic pivot. The technique uses a session variable (`@sql`) to hold the generated string, then passes it to `PREPARE` and `EXECUTE`.

First, initialize the session variable to `NULL`. This ensures you start with a clean slate, since `GROUP_CONCAT` writing `INTO` a variable that already holds a value can produce unexpected concatenation.

```sql
SET @sql = NULL;
```

Next, generate the column expressions and store them in `@sql`. The inner subquery selects `DISTINCT month` and `month_order` pairs first, so by the time `GROUP_CONCAT` sees the rows they are already deduplicated. This is what allows `ORDER BY month_order` to work as a plain column reference without any nested aggregate function.

```sql
SELECT
    GROUP_CONCAT(
        CONCAT(
            'SUM(CASE WHEN month = ''', month, ''' THEN revenue ELSE 0 END) AS `', month, '`'
        )
        ORDER BY month_order
    )
INTO @sql
FROM (
    SELECT DISTINCT month, month_order FROM sales
) AS distinct_months;
```

Now wrap the generated column list inside a complete `SELECT` statement. `CONCAT` prepends `SELECT product,` and appends the `FROM`, `GROUP BY`, and `ORDER BY` clauses, producing a fully valid SQL string.

```sql
SET @sql = CONCAT(
    'SELECT product, ',
    @sql,
    ', SUM(revenue) AS total FROM sales GROUP BY product ORDER BY product'
);
```

Before executing, inspect the assembled string. This step is optional but invaluable during development: if the final query misbehaves, reading `@sql` tells you exactly what was generated.

```sql
SELECT @sql;
```

Finally, execute the string using a prepared statement. `PREPARE` parses and validates the query, `EXECUTE` runs it and returns the result set, and `DEALLOCATE PREPARE` frees the statement handle from memory.

```sql
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
```

The `SELECT @sql` line in the middle is optional but worth keeping during development. It lets you read the assembled query before running it, which makes debugging much easier if something is off with the string concatenation.

The final output is identical to the static pivot:

```
+-----------+----------+----------+----------+----------+----------+
| product   | Jan      | Feb      | Mar      | Apr      | total    |
+-----------+----------+----------+----------+----------+----------+
| Keyboard  |  5100.00 |     0.00 |  4800.00 |  6200.00 | 16100.00 |
| Laptop    | 15000.00 | 18500.00 | 17200.00 | 21000.00 | 71700.00 |
| Mouse     |  3200.00 |  2800.00 |  3500.00 |     0.00 |  9500.00 |
+-----------+----------+----------+----------+----------+----------+
3 rows in set (0.00 sec)
```

The visual result is the same, but the mechanism is fundamentally different. The dynamic version discovered those four months by querying the table. The static version required you to know them beforehand.

## Try It Out: Seeing the Dynamic Advantage {#try-it-out}

The real proof of the dynamic approach is what happens when data changes. Insert a new month of data and see how each technique responds.

### Scenario A: Adding May Data to the Static Pivot

Add May data for all three products:

```sql
INSERT INTO sales (product, month, month_order, revenue) VALUES
    ('Laptop',   'May', 5, 23500.00),
    ('Mouse',    'May', 5,  4100.00),
    ('Keyboard', 'May', 5,  7300.00);
```

Now run the static pivot query again (the one with four explicit `CASE WHEN` blocks). The output will look like this:

```
+-----------+----------+----------+----------+----------+----------+
| product   | jan      | feb      | mar      | apr      | total    |
+-----------+----------+----------+----------+----------+----------+
| Keyboard  |  5100.00 |     0.00 |  4800.00 |  6200.00 | 23400.00 |
| Laptop    | 15000.00 | 18500.00 | 17200.00 | 21000.00 | 95200.00 |
| Mouse     |  3200.00 |  2800.00 |  3500.00 |     0.00 | 13600.00 |
+-----------+----------+----------+----------+----------+----------+
3 rows in set (0.00 sec)
```

Notice that May has disappeared entirely. The query does not know May exists because you never wrote a `CASE WHEN month = 'May'` block. Meanwhile, the `total` column has quietly absorbed May's revenue into its sum, so the totals no longer match the column-by-column numbers. This is a silent data discrepancy, the worst kind.

To fix it, you would have to open the query, add a fifth `CASE WHEN` block for May, and redeploy.

### Scenario B: Adding May Data to the Dynamic Pivot

Run the exact same dynamic pivot block from the previous section without changing a single character. The `GROUP_CONCAT` query now finds five distinct months in the table and generates five `CASE WHEN` fragments automatically:

```
+-----------+----------+----------+----------+----------+----------+----------+
| product   | Jan      | Feb      | Mar      | Apr      | May      | total    |
+-----------+----------+----------+----------+----------+----------+----------+
| Keyboard  |  5100.00 |     0.00 |  4800.00 |  6200.00 |  7300.00 | 23400.00 |
| Laptop    | 15000.00 | 18500.00 | 17200.00 | 21000.00 | 23500.00 | 95200.00 |
| Mouse     |  3200.00 |  2800.00 |  3500.00 |     0.00 |  4100.00 | 13600.00 |
+-----------+----------+----------+----------+----------+----------+----------+
3 rows in set (0.00 sec)
```

May appears as a new column with no changes to the query. The `total` column and the individual month columns are now consistent. This is the core advantage of the dynamic approach.

## Understanding How Conditional Aggregation Works {#understanding-conditional-aggregation}

Now that you have seen both techniques produce real output, it is worth stepping back to understand the mechanics more precisely. This understanding will help you adapt the pattern to different scenarios beyond monthly revenue pivots.

### Why CASE WHEN Belongs Inside Aggregate Functions

SQL's aggregate functions (`SUM`, `COUNT`, `AVG`, `MIN`, `MAX`) accept any expression that resolves to a value, not just bare column names. A `CASE WHEN` block is an expression that resolves to a value based on a condition. The database evaluates the `CASE WHEN` expression for every row in the group before applying the aggregate. This means:

- `SUM(CASE WHEN month = 'Jan' THEN revenue ELSE 0 END)` evaluates to `revenue` for January rows and `0` for all others, then sums the results. The sum equals January's total revenue.
- `COUNT(CASE WHEN month = 'Jan' THEN id ELSE NULL END)` evaluates to `id` for January rows and `NULL` for all others. Since `COUNT` ignores `NULL` values, the result is a count of only January rows.

This distinction between `ELSE 0` and `ELSE NULL` matters more than it might appear. Using `ELSE 0` with `SUM` is safe and produces a tidy `0.00` for missing months. Using `ELSE NULL` with `SUM` is also safe, since `SUM` ignores `NULL`. However, using `ELSE 0` with `AVG` produces wrong results: the zero values are treated as valid data points and drag the average down. For `AVG` pivot columns, always use `ELSE NULL`.

```sql
-- Correct: AVG ignores NULL, so missing months do not distort the average.
AVG(CASE WHEN month = 'Jan' THEN revenue ELSE NULL END) AS jan_avg

-- Incorrect: 0 is a valid value for AVG. Missing months pull the average down.
AVG(CASE WHEN month = 'Jan' THEN revenue ELSE 0 END) AS jan_avg
```

### The GROUP_CONCAT Length Limit

`GROUP_CONCAT` has a default maximum output length of 1024 characters. For small pivot tables with a handful of columns this is never an issue. For tables with many distinct pivot values, the generated SQL string can exceed this limit and get silently truncated, producing a broken query that fails with a cryptic error.

You can raise the limit for the current session before running the dynamic pivot:

```sql
-- Raise the GROUP_CONCAT output limit to 1 MB for this session.
-- This setting resets when the session ends, so it does not affect
-- other connections or persist after you disconnect.
SET SESSION group_concat_max_len = 1048576;

-- Then run the dynamic pivot as normal.
SET @sql = NULL;
SELECT GROUP_CONCAT(...) INTO @sql FROM sales;
-- ...and so on
```

For most reporting scenarios, 1 MB is more than sufficient. If you are pivoting on a column with hundreds of distinct values, you may want to reconsider the design: very wide tables become difficult to read and can hint at a schema that would benefit from a different reporting approach.

## Static Pivot vs Dynamic Pivot {#static-vs-dynamic}

Having built and tested both approaches, you are in a good position to choose the right one for each situation. Here is how the trade-offs break down.

The **static pivot** is the better choice when the pivot dimension is fixed and well-known (months of a calendar year, days of a week, a fixed set of categories), when the query will be read and maintained by other developers who benefit from explicit column definitions, and when you want the query to be embeddable in an ORM raw query or a Laravel query builder call without any procedural logic.

The **dynamic pivot** is the better choice when the pivot values are determined by data and can change over time, when you want the report to be self-maintaining, and when the query runs in a stored procedure, a cron job, or a reporting script where programmatic SQL execution is acceptable.

One important caution about dynamic pivots: because the query string is assembled from values in the database, you must ensure those values are not user-controlled. In the example above, the `month` column is populated by your own application logic. If it were populated directly from user input without sanitization, a malicious value could inject arbitrary SQL into the `@sql` string. This is an SQL injection risk specific to dynamic SQL patterns. The standard mitigation is to always source pivot dimension values from controlled, validated data in your own tables.

There is also a practical ergonomic difference. Static pivot queries are easy to copy, paste, and run anywhere. Dynamic pivots require a multi-statement execution block, which some tools and client libraries handle differently. Some MySQL GUIs require you to enable multi-statement mode or run the block as a script rather than a single query. Keep this in mind when choosing where and how the query will be executed.

## Conclusion {#conclusion}

MySQL and MariaDB have no `PIVOT` keyword, but the combination of conditional aggregation and dynamic SQL covers every use case that a native `PIVOT` function would address. Here are the key ideas to carry forward:

- **Conditional aggregation is the foundation.** Embedding a `CASE WHEN` expression inside `SUM`, `COUNT`, `AVG`, or any other aggregate function creates a virtual column that only aggregates rows matching a specific condition. This single technique is the heart of every pivot query in MySQL and MariaDB.
- **`ELSE 0` and `ELSE NULL` are not interchangeable.** Use `ELSE 0` with `SUM` and `COUNT` when you want missing intersections to appear as zero. Use `ELSE NULL` with `AVG`, `MIN`, and `MAX` to avoid distorting results with phantom zero values.
- **Static pivot queries are explicit and portable.** When your pivot dimensions are fixed and well-known, write them out explicitly with one `CASE WHEN` block per column. The query is self-documenting, easy to debug, and runs as a single statement in any client.
- **Dynamic pivots use `GROUP_CONCAT` to write SQL for you.** By concatenating distinct dimension values into a string of `CASE WHEN` expressions, then executing that string with a prepared statement, the query adapts automatically when new values appear in the data. You never need to edit the query to add a new month, category, or dimension value.
- **Raise `group_concat_max_len` for wide pivots.** The default 1024-character limit on `GROUP_CONCAT` output can truncate the generated SQL when there are many distinct pivot values. Setting `SET SESSION group_concat_max_len = 1048576` before running the dynamic pivot prevents silent truncation errors.
- **Dynamic SQL and user input do not mix safely.** Always ensure the column values used to build the dynamic SQL string come from trusted, application-controlled data. If users can influence those values, validate and sanitize them rigorously before letting them near a `GROUP_CONCAT` expression.