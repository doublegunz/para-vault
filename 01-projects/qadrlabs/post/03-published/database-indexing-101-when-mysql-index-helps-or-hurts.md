# Database Indexing 101: When an Index Makes MySQL Faster and When It Makes It Slower

A query that felt instant on your laptop can crawl in production, and the reason is almost always the same. On your machine the table had a few hundred rows, so MySQL read all of them in a blink no matter how you wrote the query. In production that same table has five million rows, and the database is now reading every single one of them to answer a question that should touch a handful. The page that used to load in 20 milliseconds now takes four seconds, the database CPU sits pinned at 100 percent, and your slow query log fills up faster than you can read it.

The usual reaction is to panic and add an index to every column in the WHERE clause, then a few more for good measure. Sometimes that fixes it. Often it does not, because an index on a low selectivity column is ignored, an index in the wrong column order never gets used, and every index you add quietly taxes every INSERT and UPDATE the table will ever receive. You end up with a table that is slow to write and still slow to read, and now you also have ten indexes nobody can explain.

The fix is not more indexes, it is understanding what an index actually is and reading what MySQL tells you it is doing. In this article we build a MySQL table with half a million rows, then use `EXPLAIN` and `EXPLAIN ANALYZE` to watch exactly when an index turns a full table scan into an instant lookup, and when that same index does nothing but slow your writes down. By the end you will be able to look at a query and predict whether an index will help before you ever create it.

## Overview {#overview}

The whole article is built around one idea: an index is a sorted copy of one or more columns that lets MySQL find rows without reading the whole table, and that copy is not free. We make the trade real by running every example against a seeded table and reading the actual execution plan, so you never have to take a claim on faith. We start with how a B-tree index is laid out, prove the speedup with a real before and after, walk through composite indexes and covering indexes, then spend the back half of the article on the cases where an index is pure overhead. Everything here is plain MySQL and the `mysql` command line client, so it applies whether your application is written in PHP, Python, Go, or anything else.

### What You'll Build

- A MySQL `orders` table seeded with 500,000 rows so that execution plans behave the way they do in production
- A set of `EXPLAIN` and `EXPLAIN ANALYZE` experiments that compare a full table scan against an index seek on the same query
- A small write benchmark that measures how much five extra indexes cost on a bulk insert
- A collection of queries that look reasonable but defeat their own index, so you can recognize the pattern in your own code

### What You'll Learn

- How a B-tree index is structured and why a lookup goes from reading every row to reading a few
- How to read the important columns of `EXPLAIN` (`type`, `key`, `rows`, `Extra`) and the tree output of `EXPLAIN ANALYZE`
- How composite indexes work and why the leftmost prefix rule decides which queries they help
- What a covering index is and how `Using index` tells you a query never touched the table
- Why selectivity, not just having an index, decides whether the optimizer uses it
- The concrete costs of an index: slower writes, more storage, and redundant work
- How to test an index change safely in production with an invisible index

### What You'll Need

- MySQL 8.0.18 or newer, because `EXPLAIN ANALYZE` was introduced in 8.0.18 (the output below is from MySQL 8.4)
- Access to the `mysql` command line client or any SQL console connected to that server
- Basic SQL comfort with `SELECT`, `WHERE`, `ORDER BY`, and `CREATE TABLE`
- No application framework is required; this is pure MySQL

## How a B-Tree Index Actually Works {#how-a-btree-index-works}

Before touching any commands, it helps to picture what an index is, because almost every rule later in the article falls out of this one structure. When you create a normal MySQL index you are creating a B-tree, which is a balanced tree that keeps the indexed values in sorted order. Searching a sorted tree is the same idea as looking up a word in a dictionary: you do not read every page, you jump to roughly the right place and narrow down. That is why an indexed lookup scales with the logarithm of the row count instead of the row count itself. Doubling the table adds at most one extra level to the tree, not twice the work.

There is a second detail specific to InnoDB, the default storage engine, that explains a lot of later behavior. InnoDB stores the table itself as a B-tree keyed on the primary key, which is called the clustered index. The rows are physically ordered by primary key and live in the leaves of that tree. Every other index you create is a secondary index, and its leaves do not store the full row; they store the indexed columns plus the primary key value. So when a secondary index finds a match, it often has to take that primary key and do a second lookup into the clustered index to fetch the rest of the row. That second hop is cheap for a few rows and expensive for millions, which is the seed of nearly every "the index made it slower" story you are about to see.

## Setting Up a Demo Table {#setting-up-a-demo-table}

To make execution plans behave realistically we need real volume, because the optimizer makes different choices on a thousand rows than it does on a million. We create an `orders` table and seed it with 500,000 rows using a recursive common table expression, which generates a sequence of numbers in pure SQL with no external script. Save the following as `setup.sql`.

```sql
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT            NOT NULL,
    status      VARCHAR(20)    NOT NULL,
    total       DECIMAL(10, 2) NOT NULL,
    created_at  DATETIME       NOT NULL
) ENGINE = InnoDB;

SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO orders (customer_id, status, total, created_at)
WITH RECURSIVE seq (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 500000
)
SELECT
    FLOOR(1 + RAND() * 50000) AS customer_id,
    ELT(
        CASE
            WHEN RAND() < 0.80 THEN 1
            WHEN RAND() < 0.95 THEN 2
            ELSE 3
        END,
        'completed', 'pending', 'cancelled'
    ) AS status,
    ROUND(5 + RAND() * 995, 2) AS total,
    TIMESTAMP('2024-01-01') + INTERVAL FLOOR(RAND() * 730 * 86400) SECOND AS created_at
FROM seq;
```

The table has a primary key on `id` but deliberately no other indexes yet, because we want to feel the pain of a full scan before we fix it. The `cte_max_recursion_depth` setting is raised because the recursive CTE defaults to a 1000 row limit, which is far too small here. The `status` column is filled with a realistic skew using `ELT` and `RAND`: roughly 80 percent `completed`, 15 percent `pending`, and 5 percent `cancelled`. That skew matters later, because an index is only as useful as the column is selective. Load the file with the client.

```bash
mysql -uroot -p indexing_demo < setup.sql
```

With the data loaded, confirm the row count and the status distribution so the numbers in the execution plans make sense.

```sql
SELECT COUNT(*) AS total_rows FROM orders;

SELECT status, COUNT(*) AS rows_count
FROM orders
GROUP BY status
ORDER BY rows_count DESC;
```

```
+------------+
| total_rows |
+------------+
|     500000 |
+------------+

+-----------+------------+
| status    | rows_count |
+-----------+------------+
| completed |     400184 |
| pending   |      94870 |
| cancelled |       4946 |
+-----------+------------+
```

Five hundred thousand rows, with `completed` dominating exactly as designed. This is now a table where the optimizer's decisions are meaningful, so we can start measuring.

## Full Table Scan vs Index Seek {#full-scan-vs-index-seek}

The clearest way to understand an index is to watch a query run without one, then add the index and run the identical query again. We look for a single customer's orders, which should be a tiny fraction of the table. Start by asking MySQL how it plans to run the query with `EXPLAIN`, which describes the plan without executing it.

```sql
EXPLAIN SELECT id, customer_id, total FROM orders WHERE customer_id = 4529;
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 499207 |    10.00 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
```

The two columns that tell the whole story are `type` and `rows`. A `type` of `ALL` means a full table scan, the worst access method, where MySQL reads every row and checks the `WHERE` clause on each one. The `rows` estimate of 499207 confirms it expects to examine the entire table. The `key` column is `NULL`, meaning no index is used, because none exists on `customer_id`. To see the real cost rather than an estimate, run `EXPLAIN ANALYZE`, which actually executes the query and reports measured timings.

```sql
EXPLAIN ANALYZE SELECT id, customer_id, total FROM orders WHERE customer_id = 4529;
```

```
-> Filter: (orders.customer_id = 4529)  (cost=50346 rows=49921) (actual time=0.164..99.5 rows=9 loops=1)
    -> Table scan on orders  (cost=50346 rows=499207) (actual time=0.158..83.1 rows=500000 loops=1)
```

Read the tree from the inside out. The inner node, `Table scan on orders`, shows `actual ... rows=500000`, meaning MySQL physically read all half a million rows. The outer `Filter` then threw almost all of them away and kept `rows=9`. The `actual time` of the whole operation ends at about 99.5 milliseconds. We read 500,000 rows to return 9. Now create an index on `customer_id` and run the exact same query.

```sql
CREATE INDEX idx_customer_id ON orders (customer_id);

EXPLAIN SELECT id, customer_id, total FROM orders WHERE customer_id = 4529;
```

```
+----+-------------+--------+------------+------+-----------------+-----------------+---------+-------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys   | key             | key_len | ref   | rows | filtered | Extra |
+----+-------------+--------+------------+------+-----------------+-----------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_customer_id | idx_customer_id | 4       | const |    9 |   100.00 | NULL  |
+----+-------------+--------+------------+------+-----------------+-----------------+---------+-------+------+----------+-------+
```

The `type` is now `ref`, an index lookup, the `key` column shows MySQL chose `idx_customer_id`, and the `rows` estimate dropped from 499207 to 9. The optimizer now knows it can jump straight to the matching entries instead of scanning. The measured version confirms it.

```sql
EXPLAIN ANALYZE SELECT id, customer_id, total FROM orders WHERE customer_id = 4529;
```

```
-> Index lookup on orders using idx_customer_id (customer_id=4529)  (cost=3.15 rows=9) (actual time=0.0372..0.039 rows=9 loops=1)
```

The full scan finished in about 99.5 milliseconds; the index lookup finished in about 0.039 milliseconds. That is the entire promise of an index in one comparison: the same query, the same result, roughly 2,500 times faster because MySQL stopped reading rows it did not need. This is when an index helps, and it helps the most exactly when your query selects a small slice of a large table.

## Composite Indexes and the Leftmost Prefix Rule {#composite-indexes-and-leftmost-prefix}

Real queries rarely filter on a single column, so MySQL lets you index several columns together in what is called a composite index. The catch, and it is the single most misunderstood thing about indexes, is that the order of columns in the index decides which queries can use it. This is the leftmost prefix rule, and getting it wrong is why people create an index and then watch the optimizer ignore it. Drop the single column index and create a composite one on three columns.

```sql
DROP INDEX idx_customer_id ON orders;
CREATE INDEX idx_cust_status_date ON orders (customer_id, status, created_at);
```

Think of this index as a phone book sorted first by `customer_id`, then by `status`, then by `created_at`. You can use it efficiently as long as you start filtering from the left. A query that filters on `customer_id` alone uses it, a query on `customer_id` and `status` uses it, and a query on all three uses it. The moment you skip the leftmost column, the sorted order is useless to you. Watch the plan for a query on just the first column.

```sql
EXPLAIN SELECT * FROM orders WHERE customer_id = 4529;
```

```
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys        | key                  | key_len | ref   | rows | filtered | Extra |
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_cust_status_date | idx_cust_status_date | 4       | const |    9 |   100.00 | NULL  |
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
```

The index is used, and the `key_len` of 4 tells you only the first column (a 4 byte `INT`) participated. Add the second column and the plan uses more of the index.

```sql
EXPLAIN SELECT * FROM orders WHERE customer_id = 4529 AND status = 'completed';
```

```
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys        | key                  | key_len | ref         | rows | filtered | Extra |
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_cust_status_date | idx_cust_status_date | 86      | const,const |    9 |   100.00 | NULL  |
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------------+------+----------+-------+
```

The `key_len` grew to 86 and `ref` now shows `const,const`, meaning both leading columns are used by the index. Now break the rule by filtering on `status` alone, skipping the leftmost `customer_id`.

```sql
EXPLAIN SELECT * FROM orders WHERE status = 'pending';
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 499207 |    10.00 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
```

Back to a full scan. The index sorts by `customer_id` first, so the `status` values are scattered all over the tree, and there is no way to jump to all the `pending` rows without reading everything. The same thing happens if you filter on `status` and `created_at` together but still skip `customer_id`.

```sql
EXPLAIN SELECT * FROM orders WHERE status = 'pending' AND created_at >= '2025-01-01';
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 499207 |     3.33 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
```

Still a full scan, because the index can only be entered from its leftmost column. The practical rule for ordering composite index columns is to put columns used with equality (`=`) first and columns used with a range (`>`, `<`, `BETWEEN`, `>=`) last, because once the index hits a range it cannot use any column after it for seeking. Design the column order around the queries you actually run, not around the order the columns happen to appear in the table.

## Covering Indexes: Answering From the Index Alone {#covering-indexes}

Recall that a secondary index leaf stores the indexed columns plus the primary key, and that fetching any other column means a second hop into the clustered index. That hop is avoidable. If every column a query needs already lives in the index, MySQL can answer the query from the index alone and never touch the table. This is called a covering index, and it is one of the highest leverage optimizations available, especially for pagination and reporting queries that run constantly. Our composite index covers `customer_id`, `status`, and `created_at`, so a query that selects only those columns is fully covered.

```sql
EXPLAIN SELECT customer_id, status, created_at FROM orders WHERE customer_id = 4529;
```

```
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys        | key                  | key_len | ref   | rows | filtered | Extra       |
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_cust_status_date | idx_cust_status_date | 4       | const |    9 |   100.00 | Using index |
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------------+
```

The `Extra` column now says `Using index`, which is the signal that the query was answered entirely from the index with no table access. The measured plan names it explicitly.

```sql
EXPLAIN ANALYZE SELECT customer_id, status, created_at FROM orders WHERE customer_id = 4529;
```

```
-> Covering index lookup on orders using idx_cust_status_date (customer_id=4529)  (cost=2 rows=9) (actual time=0.0095..0.0118 rows=9 loops=1)
```

It reports a `Covering index lookup` finishing in about 0.0118 milliseconds. Now add one column that is not in the index, `total`, and the covering optimization disappears.

```sql
EXPLAIN SELECT customer_id, total FROM orders WHERE customer_id = 4529;
```

```
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys        | key                  | key_len | ref   | rows | filtered | Extra |
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_cust_status_date | idx_cust_status_date | 4       | const |    9 |   100.00 | NULL  |
+----+-------------+--------+------------+------+----------------------+----------------------+---------+-------+------+----------+-------+
```

The `Extra` column is empty now, because `total` forces MySQL to take the primary key from each index entry and look up the full row in the clustered index. The measured difference is real.

```sql
EXPLAIN ANALYZE SELECT customer_id, total FROM orders WHERE customer_id = 4529;
```

```
-> Index lookup on orders using idx_cust_status_date (customer_id=4529)  (cost=3.15 rows=9) (actual time=0.0313..0.0329 rows=9 loops=1)
```

A plain `Index lookup` at about 0.0329 milliseconds, roughly three times slower than the covering version, and that gap widens as the number of matched rows grows because each extra row is another random hop into the clustered index. The lesson is that selecting only the columns you need, instead of reaching for `SELECT *`, can let an existing index cover the query for free.

## When an Index Slows You Down {#when-an-index-slows-you-down}

So far every index has earned its keep, which is the part of the story people remember. The other half is that an index is a second sorted data structure the database must keep perfectly in sync with the table, and that synchronization is not free. Every example in this section is a case where the index either costs more than it saves or is silently ignored while still charging you on every write. These are the patterns that turn a well meaning "let me add an index" into a regression.

### Write Amplification

An index speeds up reads by precomputing order, and that order has to be maintained on every write. Insert a row and MySQL must insert an entry into every index on the table; update an indexed column and it must move the entry to its new sorted position. To measure this, we create two tables with identical columns, one with no secondary indexes and one with five, then insert the same 500,000 rows into each.

```sql
CREATE TABLE bench_no_index (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    status      VARCHAR(20) NOT NULL,
    total       DECIMAL(10,2) NOT NULL,
    created_at  DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE bench_many_index (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    status      VARCHAR(20) NOT NULL,
    total       DECIMAL(10,2) NOT NULL,
    created_at  DATETIME NOT NULL,
    INDEX idx_customer (customer_id),
    INDEX idx_status (status),
    INDEX idx_total (total),
    INDEX idx_created (created_at),
    INDEX idx_cust_status (customer_id, status)
) ENGINE=InnoDB;
```

Now time a bulk insert into each table, pulling the rows straight from our seeded `orders` table so both inserts move identical data.

```sql
INSERT INTO bench_no_index (customer_id, status, total, created_at)
SELECT customer_id, status, total, created_at FROM orders;
```

```
real	0m2.101s
```

```sql
INSERT INTO bench_many_index (customer_id, status, total, created_at)
SELECT customer_id, status, total, created_at FROM orders;
```

```
real	0m8.682s
```

The same 500,000 rows took 2.1 seconds with no secondary indexes and 8.7 seconds with five, more than four times slower, because each insert now maintains six B-trees instead of one. On a write heavy table this is the difference between keeping up with traffic and falling behind. The storage cost is just as concrete; check how much space the data and the indexes each consume.

```sql
SELECT table_name,
       ROUND(data_length / 1024 / 1024, 1)  AS data_mb,
       ROUND(index_length / 1024 / 1024, 1) AS index_mb
FROM information_schema.tables
WHERE table_schema = 'indexing_demo'
  AND table_name IN ('bench_no_index', 'bench_many_index');
```

```
+------------------+---------+----------+
| TABLE_NAME       | data_mb | index_mb |
+------------------+---------+----------+
| bench_many_index |    26.6 |     82.8 |
| bench_no_index   |    26.6 |      0.0 |
+------------------+---------+----------+
```

The five indexes take 82.8 MB, more than three times the size of the data itself. Every index you add is real disk, real memory in the buffer pool, and real time on every write, so each one needs to pay for itself in reads.

### Low Cardinality and Poor Selectivity

An index helps when it lets MySQL skip most of the table, and it can only do that when the value you filter on is rare. Cardinality is the number of distinct values in a column, and selectivity is the fraction of rows a given value matches. Our `status` column has only three values, so it has low cardinality, and `completed` matches 80 percent of the table. Create an index on `status` and ask for the common value.

```sql
CREATE INDEX idx_status_only ON orders (status);

EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'completed';
```

```
-> Index lookup on orders using idx_status_only (status='completed')  (cost=27694 rows=249356) (actual time=1.56..593 rows=400184 loops=1)
```

Here is the surprise: MySQL used the index and the query took about 593 milliseconds. Now force it to ignore the index and scan the table instead, using the `IGNORE INDEX` hint.

```sql
EXPLAIN ANALYZE SELECT * FROM orders IGNORE INDEX (idx_status_only) WHERE status = 'completed';
```

```
-> Filter: (orders.`status` = 'completed')  (cost=50296 rows=249356) (actual time=0.184..157 rows=400184 loops=1)
    -> Table scan on orders  (cost=50296 rows=498712) (actual time=0.183..105 rows=500000 loops=1)
```

The full scan took about 157 milliseconds, almost four times faster than using the index. This is the heart of why blindly indexing hurts. To return 400,000 rows through the index, MySQL walks the index and then makes a separate random jump into the clustered index for each match, and hundreds of thousands of random hops are far more expensive than one sequential pass over the table. An index on a low selectivity column does not just fail to help, it actively makes the common case slower while still charging you on every write. Indexes pay off on columns where the values you search for are selective, like a user ID or an email, not a status flag with three values.

### Functions and Expressions on the Column

An index stores the column's values, not the result of a function applied to them, so the moment you wrap an indexed column in a function the index becomes unusable. Create an index on `created_at` and filter by calling `DATE()` on it.

```sql
CREATE INDEX idx_created ON orders (created_at);

EXPLAIN SELECT * FROM orders WHERE DATE(created_at) = '2025-06-15';
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 496857 |   100.00 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
```

A full scan, because MySQL would have to compute `DATE(created_at)` for every row to know whether it matches, which means reading every row. The fix is to rewrite the condition so the bare column is compared against a range, which is called making the predicate sargable.

```sql
EXPLAIN SELECT * FROM orders WHERE created_at >= '2025-06-15' AND created_at < '2025-06-16';
```

```
+----+-------------+--------+------------+-------+---------------+-------------+---------+------+------+----------+-----------------------+
| id | select_type | table  | partitions | type  | possible_keys | key         | key_len | ref  | rows | filtered | Extra                 |
+----+-------------+--------+------------+-------+---------------+-------------+---------+------+------+----------+-----------------------+
|  1 | SIMPLE      | orders | NULL       | range | idx_created   | idx_created | 5       | NULL |  709 |   100.00 | Using index condition |
+----+-------------+--------+------------+-------+---------------+-------------+---------+------+------+----------+-----------------------+
```

Same logical question, but now the `type` is `range`, the index is used, and the estimate drops from 496857 rows to 709. Both queries find every order on a single day; only the second one can use the index, because it asks about the column itself rather than a function of it. If you genuinely need to query a transformation of a column, MySQL 8 supports functional indexes, but the simplest win is almost always to keep the column bare on one side of the comparison.

### Leading Wildcard LIKE

A B-tree is sorted left to right, exactly like a dictionary, so it can find everything starting with a prefix but not everything ending with a suffix. A `LIKE` pattern that is anchored on the left can use the index; one that starts with a wildcard cannot. Add an indexed text column to demonstrate it.

```sql
ALTER TABLE orders ADD COLUMN reference VARCHAR(20) NOT NULL DEFAULT '';
UPDATE orders SET reference = CAST(customer_id AS CHAR);
CREATE INDEX idx_reference ON orders (reference);

EXPLAIN SELECT * FROM orders WHERE reference LIKE '45%';
```

```
+----+-------------+--------+------------+-------+---------------+---------------+---------+------+-------+----------+-----------------------+
| id | select_type | table  | partitions | type  | possible_keys | key           | key_len | ref  | rows  | filtered | Extra                 |
+----+-------------+--------+------------+-------+---------------+---------------+---------+------+-------+----------+-----------------------+
|  1 | SIMPLE      | orders | NULL       | range | idx_reference | idx_reference | 82      | NULL | 20376 |   100.00 | Using index condition |
+----+-------------+--------+------------+-------+---------------+---------------+---------+------+-------+----------+-----------------------+
```

The prefix pattern `'45%'` uses the index as a range scan, because MySQL can jump to the values starting with `45` and read forward. Move the wildcard to the front and the index is dead.

```sql
EXPLAIN SELECT * FROM orders WHERE reference LIKE '%45';
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 496857 |    11.11 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
```

Back to a full scan, because there is no sorted position for "ends with 45". This is why "search anywhere in the text" features built on `LIKE '%term%'` do not scale, and why full text search or a dedicated search engine exists for that job.

### Implicit Type Conversion

The same defeat happens, far more sneakily, when the type of your value does not match the type of the column. Our `reference` column is a `VARCHAR`, but it holds digits, so it is tempting to compare it against a number. When you do, MySQL has to convert the column to a number for every row, which, just like a function call, makes the index unusable.

```sql
EXPLAIN SELECT * FROM orders WHERE reference = 4529;
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | idx_reference | NULL | NULL    | NULL | 496857 |    10.00 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
```

Notice that `possible_keys` lists `idx_reference`, so MySQL knows the index exists, but `key` is `NULL` and the type is `ALL`. The number `4529` forced a conversion that the index cannot satisfy. Quote the value so it matches the column type and the index comes back to life.

```sql
EXPLAIN SELECT * FROM orders WHERE reference = '4529';
```

```
+----+-------------+--------+------------+------+---------------+---------------+---------+-------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys | key           | key_len | ref   | rows | filtered | Extra |
+----+-------------+--------+------------+------+---------------+---------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_reference | idx_reference | 82      | const |    9 |   100.00 | NULL  |
+----+-------------+--------+------------+------+---------------+---------------+---------+-------+------+----------+-------+
```

A clean `ref` lookup with 9 estimated rows. This bug is easy to introduce from application code that binds an integer where the column is a string, and it is invisible until you read the plan and notice the index you built is quietly being skipped.

### Redundant and Overlapping Indexes

Because a composite index can be used by any leftmost prefix of its columns, a separate index on just the first column is usually pure waste. We already have `idx_cust_status_date` on `(customer_id, status, created_at)`, which fully serves any query on `customer_id` alone. Add a standalone index on `customer_id` anyway, the kind of thing that accumulates over years of well meaning changes.

```sql
CREATE INDEX idx_customer ON orders (customer_id);
```

MySQL ships a `sys` schema view that finds exactly this kind of duplication, so you do not have to spot it by eye.

```sql
SELECT table_name, redundant_index_name, redundant_index_columns,
       dominant_index_name, dominant_index_columns
FROM sys.schema_redundant_indexes
WHERE table_name = 'orders'\G
```

```
*************************** 1. row ***************************
             table_name: orders
   redundant_index_name: idx_customer
redundant_index_columns: customer_id
    dominant_index_name: idx_cust_status_date
 dominant_index_columns: customer_id,status,created_at
```

The view names `idx_customer` as redundant and points to the composite index that already covers it. A redundant index gives you nothing on reads, since the dominant index already handles those queries, while still costing you on every write and every byte of storage. Auditing `sys.schema_redundant_indexes` on a mature database is one of the fastest ways to reclaim write performance with zero risk to reads.

### Tiny Tables

The last case is the one people forget: on a very small table an index barely matters, because MySQL can read the whole thing in a single page fetch. A lookup table of a few rows is read in one I/O whether you scan it or seek into an index, so the index adds maintenance cost and storage for no measurable gain. Create a three row status lookup table with an index on its code.

```sql
CREATE TABLE order_statuses (
    id    INT PRIMARY KEY,
    code  VARCHAR(20) NOT NULL,
    label VARCHAR(50) NOT NULL,
    INDEX idx_code (code)
) ENGINE=InnoDB;

INSERT INTO order_statuses VALUES
    (1, 'completed', 'Completed'),
    (2, 'pending',   'Pending'),
    (3, 'cancelled', 'Cancelled');

EXPLAIN SELECT * FROM order_statuses WHERE code = 'pending';
```

```
+----+-------------+----------------+------------+------+---------------+----------+---------+-------+------+----------+-------+
| id | select_type | table          | partitions | type | possible_keys | key      | key_len | ref   | rows | filtered | Extra |
+----+-------------+----------------+------------+------+---------------+----------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | order_statuses | NULL       | ref  | idx_code      | idx_code | 82      | const |    1 |   100.00 | NULL  |
+----+-------------+----------------+------------+------+---------------+----------+---------+-------+------+----------+-------+
```

MySQL will happily use the index here, but with only three rows the difference against a scan is unmeasurable; both touch a single data page. The point is not that the index breaks anything, it is that it earns nothing while still being maintained on every write. Save your indexes for tables large enough that skipping rows is a real win, and do not reflexively index every small lookup table.

## Testing Index Changes Safely with Invisible Indexes {#invisible-indexes}

Everything above leads to an uncomfortable question in production: you suspect an index is unused or harmful, but dropping it is risky, because if you are wrong a critical query falls off a cliff and rebuilding a large index takes time. MySQL 8 solves this with invisible indexes. An invisible index is still fully maintained on every write, so it stays current, but the optimizer pretends it does not exist when planning queries. You get to simulate dropping it without actually dropping it. Confirm the query currently uses `idx_reference`, then make it invisible.

```sql
EXPLAIN SELECT * FROM orders WHERE reference = '4529';
```

```
+----+-------------+--------+------------+------+---------------+---------------+---------+-------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys | key           | key_len | ref   | rows | filtered | Extra |
+----+-------------+--------+------------+------+---------------+---------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_reference | idx_reference | 82      | const |    9 |   100.00 | NULL  |
+----+-------------+--------+------------+------+---------------+---------------+---------+-------+------+----------+-------+
```

```sql
ALTER TABLE orders ALTER INDEX idx_reference INVISIBLE;

EXPLAIN SELECT * FROM orders WHERE reference = '4529';
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 496857 |     0.00 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-------------+
```

The plan immediately falls back to a full scan, exactly as it would if the index were dropped, but the index is still on disk and still being kept up to date. You can now watch your application and slow query log for a while; if nothing degrades, the index is genuinely safe to drop. If something does degrade, you can make it visible again instantly with no rebuild. You can also test the other direction by switching invisible indexes on for just your own session, which lets you measure a candidate index without exposing it to the whole server.

```sql
SET SESSION optimizer_switch = 'use_invisible_indexes=on';

EXPLAIN SELECT * FROM orders WHERE reference = '4529';
```

```
+----+-------------+--------+------------+------+---------------+---------------+---------+-------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys | key           | key_len | ref   | rows | filtered | Extra |
+----+-------------+--------+------------+------+---------------+---------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_reference | idx_reference | 82      | const |    9 |   100.00 | NULL  |
+----+-------------+--------+------------+------+---------------+---------------+---------+-------+------+----------+-------+
```

With the session switch on, the optimizer uses the invisible index again, just for you, so you can confirm the plan before flipping it back to visible for everyone.

```sql
ALTER TABLE orders ALTER INDEX idx_reference VISIBLE;
```

Invisible indexes turn index changes from a leap of faith into a measured, reversible experiment, which is exactly the discipline this whole article argues for: decide with `EXPLAIN`, not with a hunch.

## Conclusion {#conclusion}

An index is a sorted copy of your data that trades write cost and storage for read speed, and the entire craft is knowing when that trade is worth it. The wins are dramatic when a query selects a small slice of a large table, and the losses are just as real when the column is not selective, the predicate cannot use the sort order, or the index simply duplicates another. The one habit that ties it all together is to stop guessing and read the plan, because MySQL tells you exactly what it is doing if you ask. Here are the ideas worth keeping.

- **An index is a sorted structure, not free magic.** It lets MySQL skip rows by keeping values in B-tree order, and that order must be maintained on every insert, update, and delete.
- **Measure with `EXPLAIN` and `EXPLAIN ANALYZE`.** The `type`, `key`, and `rows` columns and the measured tree output tell you whether an index is used and what it actually costs, before and after a change.
- **Composite indexes follow the leftmost prefix rule.** An index on `(a, b, c)` serves queries on `a`, `a, b`, or `a, b, c`, but never `b` or `c` alone, so order the columns around your real queries with equality first and ranges last.
- **Covering indexes answer from the index alone.** When every selected column lives in the index you get `Using index` and skip the trip to the table, which is why selecting only the columns you need pays off.
- **Selectivity decides everything.** An index on a low cardinality column like a status flag is often slower than a scan and still taxes every write, so reserve indexes for columns where the values you search are rare.
- **Many ordinary patterns silently kill an index.** Functions on the column, leading wildcard `LIKE`, and implicit type conversions all force a full scan even when a perfect index exists, and only the plan reveals it.
- **Every index has a price.** More indexes mean slower writes and more storage, redundant indexes give nothing back, and `sys.schema_redundant_indexes` will find the duplicates for you.
- **Test changes with invisible indexes.** Make an index invisible to simulate dropping it without the risk, and flip it back instantly if a query regresses, so index decisions become reversible experiments instead of gambles.
