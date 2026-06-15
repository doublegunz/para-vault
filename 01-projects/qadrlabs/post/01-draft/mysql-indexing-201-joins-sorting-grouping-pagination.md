# MySQL Indexing 201: Speeding Up JOINs, ORDER BY, GROUP BY, and Pagination

In [Database Indexing 101](https://qadrlabs.com/post/database-indexing-101-when-an-index-makes-mysql-faster-and-when-it-makes-it-slower) we made single table lookups fast: we watched a `WHERE customer_id = ?` query go from a 100 millisecond full scan to a 0.04 millisecond index seek, learned the leftmost prefix rule, and saw when an index quietly slows you down. That covers the simplest shape a query can take, one table and one filter. The trouble is that almost no real page is that simple. A real page joins orders to customers, sorts them by date, groups them into a summary, and shows page 3,000 of the results.

Those four operations, join, sort, group, and paginate, are where slowness hides even after you have indexed every column in your `WHERE` clauses. A join with no index on the join column turns into a full scan for every matched row. An `ORDER BY` with no supporting index forces MySQL to sort the entire result set in a pass called `filesort`. A `GROUP BY` spills into a temporary table. And a `LIMIT 20 OFFSET 200000` reads two hundred thousand rows just to throw all but twenty away. None of these show up on a development database with a thousand rows, and all of them show up at the worst possible moment in production.

The good news is that you already have the only tool you need, which is `EXPLAIN`. In this article we extend the same demo dataset from part one, add a `customers` table, and use `EXPLAIN` and `EXPLAIN ANALYZE` to find and fix each of these four problems. By the end you will recognize `Using filesort` and `Using temporary` on sight and know exactly which index makes them disappear.

## Overview {#overview}

The approach is identical to part one: we never claim an index helps, we measure it, run the query both ways, and read the plan. We start by rebuilding the `orders` table from part one and adding a `customers` table so we have something to join against. Then we take the four expensive query shapes one at a time. For joins we watch a missing index on the join column force a full scan and then fix it. For sorting and grouping we learn to read `Using filesort` and `Using temporary` and design the composite index that removes them. For pagination we measure why deep `OFFSET` collapses and rewrite it as keyset pagination that stays fast no matter how deep the user scrolls. Everything is plain MySQL and the `mysql` command line client.

### What You'll Build

- The part one `orders` table with 500,000 rows, plus a new `customers` table with 50,000 rows to join against
- A set of `EXPLAIN` and `EXPLAIN ANALYZE` experiments that show a join, a sort, and a grouping query each running slowly, then fast after the right index
- A keyset pagination query that returns page 10,001 in the same time as page 1, next to the `OFFSET` version that does not

### What You'll Learn

- How MySQL executes a join as a nested loop, and why an index on the join column is what makes it cheap
- How to read `Using filesort` and remove it with an index that already provides the sort order
- How a composite index can satisfy a `WHERE` filter and an `ORDER BY` at the same time
- How `GROUP BY` falls back to a temporary table, and how an index turns it into an index scan
- Why `LIMIT n OFFSET m` gets slower the deeper you page, and how keyset pagination avoids it

### What You'll Need

- MySQL 8.0.18 or newer, because `EXPLAIN ANALYZE` arrived in 8.0.18 (the output below is from MySQL 8.4)
- Access to the `mysql` command line client or any SQL console
- The fundamentals from [Database Indexing 101](https://qadrlabs.com/post/database-indexing-101-when-an-index-makes-mysql-faster-and-when-it-makes-it-slower), especially how to read the `type`, `key`, `rows`, and `Extra` columns of `EXPLAIN`
- The demo dataset, which we recreate from scratch in the next section so you do not need part one's database still lying around

## Rebuilding the Demo Data {#rebuilding-the-demo-data}

To keep this article self contained we recreate the `orders` table from part one and add a `customers` table, because a join needs two tables. The `customers` table has 50,000 rows with ids from 1 to 50,000, which is exactly the range the `orders.customer_id` column was seeded against, so every order points at a real customer. We use a recursive common table expression to generate the rows in pure SQL. Save this as `setup.sql`.

```sql
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(60)  NOT NULL,
    country    VARCHAR(40)  NOT NULL,
    created_at DATETIME     NOT NULL
) ENGINE = InnoDB;

CREATE TABLE orders (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT            NOT NULL,
    status      VARCHAR(20)    NOT NULL,
    total       DECIMAL(10, 2) NOT NULL,
    created_at  DATETIME       NOT NULL
) ENGINE = InnoDB;

SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO customers (name, country, created_at)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 50000
)
SELECT
    CONCAT('Customer ', n),
    ELT(FLOOR(1 + RAND() * 5), 'Indonesia', 'Malaysia', 'Singapore', 'Thailand', 'Vietnam'),
    TIMESTAMP('2023-01-01') + INTERVAL FLOOR(RAND() * 365 * 86400) SECOND
FROM seq;

INSERT INTO orders (customer_id, status, total, created_at)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 500000
)
SELECT
    FLOOR(1 + RAND() * 50000),
    ELT(CASE WHEN RAND() < 0.80 THEN 1 WHEN RAND() < 0.95 THEN 2 ELSE 3 END,
        'completed', 'pending', 'cancelled'),
    ROUND(5 + RAND() * 995, 2),
    TIMESTAMP('2024-01-01') + INTERVAL FLOOR(RAND() * 730 * 86400) SECOND
FROM seq;
```

Both tables start with only a primary key and no secondary indexes, which is deliberate, because we want to feel each problem before we fix it. Load the file and confirm the counts.

```bash
mysql -uroot -p indexing_demo < setup.sql
```

```sql
SELECT
    (SELECT COUNT(*) FROM customers) AS customers,
    (SELECT COUNT(*) FROM orders)    AS orders;
```

```
+-----------+--------+
| customers | orders |
+-----------+--------+
|     50000 | 500000 |
+-----------+--------+
```

Fifty thousand customers and half a million orders, each order linked to a customer through `customer_id`. Now we can join them.

## How MySQL Executes a JOIN {#how-mysql-executes-a-join}

The most important thing to understand about a join is that MySQL does not have a magic "match everything" operation. It runs a nested loop: it picks one table to read first, called the driving table, and then for every row it finds there it looks up the matching rows in the other table. If that second lookup can use an index it is a quick seek; if it cannot, MySQL scans the entire second table once for every single driving row, which is catastrophic. So the index that matters for a join is the one on the column you join on. Let us prove it by joining a single customer to their orders while `orders.customer_id` has no index.

```sql
EXPLAIN SELECT c.name, o.id, o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.id = 4529;
```

```
+----+-------------+-------+------------+-------+---------------+---------+---------+-------+--------+----------+-------------+
| id | select_type | table | partitions | type  | possible_keys | key     | key_len | ref   | rows   | filtered | Extra       |
+----+-------------+-------+------------+-------+---------------+---------+---------+-------+--------+----------+-------------+
|  1 | SIMPLE      | c     | NULL       | const | PRIMARY       | PRIMARY | 4       | const |      1 |   100.00 | NULL        |
|  1 | SIMPLE      | o     | NULL       | ALL   | NULL          | NULL    | NULL    | NULL  | 498630 |    10.00 | Using where |
+----+-------------+-------+------------+-------+---------------+---------+---------+-------+--------+----------+-------------+
```

Read the rows top to bottom, because that is the join order MySQL chose. It reads `customers` first with `type = const`, which is the fastest access of all: it found the one row with `id = 4529` directly through the primary key. Then it joins to `orders` with `type = ALL`, a full scan of all 498,630 rows, because there is no index on `customer_id` to seek into. The measured cost is exactly what you would fear.

```sql
EXPLAIN ANALYZE SELECT c.name, o.id, o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.id = 4529;
```

```
-> Filter: (o.customer_id = 4529)  (cost=50288 rows=49863) (actual time=5.37..107 rows=14 loops=1)
    -> Table scan on o  (cost=50288 rows=498630) (actual time=0.146..89.9 rows=500000 loops=1)
```

MySQL read all 500,000 orders to find the 14 that belong to this customer, taking about 107 milliseconds. Now add the index on the join column and run the identical query.

```sql
CREATE INDEX idx_customer_id ON orders (customer_id);

EXPLAIN SELECT c.name, o.id, o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.id = 4529;
```

```
+----+-------------+-------+------------+-------+-----------------+-----------------+---------+-------+------+----------+-------+
| id | select_type | table | partitions | type  | possible_keys   | key             | key_len | ref   | rows | filtered | Extra |
+----+-------------+-------+------------+-------+-----------------+-----------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | c     | NULL       | const | PRIMARY         | PRIMARY         | 4       | const |    1 |   100.00 | NULL  |
|  1 | SIMPLE      | o     | NULL       | ref   | idx_customer_id | idx_customer_id | 4       | const |   14 |   100.00 | NULL  |
+----+-------------+-------+------------+-------+-----------------+-----------------+---------+-------+------+----------+-------+
```

The access to `orders` changed from `ALL` to `ref`, the estimate dropped from 498,630 rows to 14, and the `key` column shows `idx_customer_id` is now used. The join lookup is a seek instead of a scan.

```sql
EXPLAIN ANALYZE SELECT c.name, o.id, o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.id = 4529;
```

```
-> Index lookup on o using idx_customer_id (customer_id=4529)  (cost=4.9 rows=14) (actual time=0.0458..0.0482 rows=14 loops=1)
```

From 107 milliseconds down to about 0.048 milliseconds, the same speedup as part one but for a join. The rule is simple and worth memorizing: every column you join on should be indexed, and in practice that almost always means indexing your foreign keys. To see the nested loop more clearly, run a query that does not narrow to a single customer, so MySQL has to loop over many rows.

```sql
EXPLAIN ANALYZE SELECT c.country, COUNT(*)
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'cancelled'
GROUP BY c.country;
```

```
-> Table scan on <temporary>  (actual time=132..132 rows=5 loops=1)
    -> Aggregate using temporary table  (actual time=132..132 rows=5 loops=1)
        -> Nested loop inner join  (cost=67740 rows=49863) (actual time=0.193..130 rows=4918 loops=1)
            -> Filter: (o.`status` = 'cancelled')  (cost=50288 rows=49863) (actual time=0.184..122 rows=4918 loops=1)
                -> Table scan on o  (cost=50288 rows=498630) (actual time=0.162..94.1 rows=500000 loops=1)
            -> Single-row index lookup on c using PRIMARY (id=o.customer_id)  (cost=0.25 rows=1) (actual time=0.00147..0.00149 rows=1 loops=4918)
```

This time `orders` is the driving table, MySQL scans it to find the 4,918 cancelled orders, and for each one it does a `Single-row index lookup on c using PRIMARY`. The `loops=4918` on that last line is the nested loop running 4,918 times, once per cancelled order, and each loop is cheap only because `customers.id` is a primary key. Notice also the `Aggregate using temporary table` at the top, which is the `GROUP BY` paying for a temporary table; we will deal with exactly that later.

## Eliminating filesort in ORDER BY {#ordering-with-indexes}

Sorting is expensive, and the word to watch for in a plan is `filesort`. Despite the name it does not necessarily touch disk, but it does mean MySQL had to collect the rows and sort them itself rather than reading them in order. Because a B-tree index is already stored in sorted order, an index on the column you sort by lets MySQL skip the sort entirely and just read the index from one end. Watch what happens when we ask for the ten most expensive orders with no index on `total`.

```sql
EXPLAIN SELECT id, customer_id, total FROM orders ORDER BY total DESC LIMIT 10;
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+----------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra          |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+----------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 498630 |   100.00 | Using filesort |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+----------------+
```

The `Extra` column says `Using filesort`, and `type = ALL` means MySQL reads every row before it can sort. Even though we only want 10 rows, it has to consider all 500,000 to find which are the largest. The measured plan shows the cost.

```sql
EXPLAIN ANALYZE SELECT id, customer_id, total FROM orders ORDER BY total DESC LIMIT 10;
```

```
-> Limit: 10 row(s)  (cost=50288 rows=10) (actual time=154..154 rows=10 loops=1)
    -> Sort: orders.total DESC, limit input to 10 row(s) per chunk  (cost=50288 rows=498630) (actual time=154..154 rows=10 loops=1)
        -> Table scan on orders  (cost=50288 rows=498630) (actual time=0.152..86.5 rows=500000 loops=1)
```

The `Sort` node sitting on top of a full `Table scan` is the filesort, and the whole thing takes about 154 milliseconds. Now create an index on `total` and run the same query.

```sql
CREATE INDEX idx_total ON orders (total);

EXPLAIN SELECT id, customer_id, total FROM orders ORDER BY total DESC LIMIT 10;
```

```
+----+-------------+--------+------------+-------+---------------+-----------+---------+------+------+----------+---------------------+
| id | select_type | table  | partitions | type  | possible_keys | key       | key_len | ref  | rows | filtered | Extra               |
+----+-------------+--------+------------+-------+---------------+-----------+---------+------+------+----------+---------------------+
|  1 | SIMPLE      | orders | NULL       | index | NULL          | idx_total | 5       | NULL |   10 |   100.00 | Backward index scan |
+----+-------------+--------+------------+-------+---------------+-----------+---------+------+------+----------+---------------------+
```

The filesort is gone. The `Extra` now reads `Backward index scan`, because we asked for `DESC` and the index is stored ascending, so MySQL simply reads it from the high end backward. It needs only 10 rows, not 498,630.

```sql
EXPLAIN ANALYZE SELECT id, customer_id, total FROM orders ORDER BY total DESC LIMIT 10;
```

```
-> Limit: 10 row(s)  (cost=0.00854 rows=10) (actual time=0.238..0.239 rows=10 loops=1)
    -> Index scan on orders using idx_total (reverse)  (cost=0.00854 rows=10) (actual time=0.231..0.233 rows=10 loops=1)
```

From 154 milliseconds to about 0.24 milliseconds, because MySQL read 10 index entries instead of sorting half a million rows. Real queries rarely sort without filtering first, though, and that combination is where column order matters. Consider showing the newest pending orders, which filters on `status` and sorts on `created_at`.

```sql
EXPLAIN SELECT id, customer_id, created_at
FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 20;
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-----------------------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra                       |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-----------------------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 498630 |    10.00 | Using where; Using filesort |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-----------------------------+
```

This is the worst of both: a full scan to apply the filter, then a filesort to order what survives, about 137 milliseconds when measured. The fix is a single composite index whose first column is the equality filter and whose second column is the sort, so the index both finds the `pending` rows and stores them already ordered by `created_at`.

```sql
CREATE INDEX idx_status_created ON orders (status, created_at);

EXPLAIN SELECT id, customer_id, created_at
FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 20;
```

```
+----+-------------+--------+------------+------+--------------------+--------------------+---------+-------+--------+----------+---------------------+
| id | select_type | table  | partitions | type | possible_keys      | key                | key_len | ref   | rows   | filtered | Extra               |
+----+-------------+--------+------------+------+--------------------+--------------------+---------+-------+--------+----------+---------------------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_status_created | idx_status_created | 82      | const | 182582 |   100.00 | Backward index scan |
+----+-------------+--------+------------+------+--------------------+--------------------+---------+-------+--------+----------+---------------------+
```

The `filesort` disappeared and `type` became `ref`. MySQL seeks to the `pending` section of the index and reads it backward to get the newest first, which means the `WHERE` and the `ORDER BY` are both satisfied by one index. The measured difference is dramatic.

```sql
EXPLAIN ANALYZE SELECT id, customer_id, created_at
FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 20;
```

```
-> Limit: 20 row(s)  (cost=19533 rows=20) (actual time=2.99..2.99 rows=20 loops=1)
    -> Index lookup on orders using idx_status_created (status='pending') (reverse)  (cost=19533 rows=182582) (actual time=2.98..2.99 rows=20 loops=1)
```

About 3 milliseconds instead of 137. The order of columns in this index is not arbitrary: `status` comes first because it is matched with equality, and `created_at` comes second because it is the sort. Flip them and the index could no longer jump straight to the `pending` rows in date order, which is the same leftmost prefix logic from part one applied to sorting.

## Grouping with Indexes {#grouping-with-indexes}

A `GROUP BY` has to gather rows that share a value and collapse them, and by default MySQL does that by building a temporary table to hold the groups, which shows up as `Using temporary` in the plan. As with sorting, an index that already orders the rows by the grouping column lets MySQL stream through them and aggregate on the fly, with no temporary table at all. To show both sides cleanly we count orders per customer, first telling MySQL to ignore the index on `customer_id` with the `IGNORE INDEX` hint so we can see the unindexed behavior.

```sql
EXPLAIN SELECT customer_id, COUNT(*) AS orders_count
FROM orders IGNORE INDEX (idx_customer_id)
GROUP BY customer_id;
```

```
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-----------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra           |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-----------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 498630 |   100.00 | Using temporary |
+----+-------------+--------+------------+------+---------------+------+---------+------+--------+----------+-----------------+
```

There it is, `Using temporary` next to a full table scan. The measured plan shows MySQL building the temporary table to hold the 49,999 distinct customers it found.

```sql
EXPLAIN ANALYZE SELECT customer_id, COUNT(*) AS orders_count
FROM orders IGNORE INDEX (idx_customer_id)
GROUP BY customer_id;
```

```
-> Table scan on <temporary>  (actual time=213..216 rows=49999 loops=1)
    -> Aggregate using temporary table  (actual time=213..213 rows=49999 loops=1)
        -> Table scan on orders  (cost=50288 rows=498630) (actual time=1..77 rows=500000 loops=1)
```

About 216 milliseconds, with the work split between scanning the table and managing the temporary table. Now let MySQL use the index it already has on `customer_id`.

```sql
EXPLAIN SELECT customer_id, COUNT(*) AS orders_count
FROM orders
GROUP BY customer_id;
```

```
+----+-------------+--------+------------+-------+-----------------+-----------------+---------+------+--------+----------+-------------+
| id | select_type | table  | partitions | type  | possible_keys   | key             | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+--------+------------+-------+-----------------+-----------------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | index | idx_customer_id | idx_customer_id | 4       | NULL | 498630 |   100.00 | Using index |
+----+-------------+--------+------------+-------+-----------------+-----------------+---------+------+--------+----------+-------------+
```

The `Using temporary` is replaced by `Using index`, and `type` is now `index`, meaning MySQL walks the index in order. Because the index is sorted by `customer_id`, all rows for one customer sit together, so MySQL can count one customer, emit the result, and move on without ever holding a temporary table.

```sql
EXPLAIN ANALYZE SELECT customer_id, COUNT(*) AS orders_count
FROM orders
GROUP BY customer_id;
```

```
-> Group aggregate: count(0)  (cost=100151 rows=50261) (actual time=8.65..134 rows=49999 loops=1)
    -> Covering index scan on orders using idx_customer_id  (cost=50288 rows=498630) (actual time=8.64..113 rows=500000 loops=1)
```

About 134 milliseconds instead of 216, and the structure is different: a `Group aggregate` streaming directly off a `Covering index scan`, with no temporary table in sight. The grouping query still reads every index entry because it counts every order, so it is not as dramatic a win as a selective lookup, but removing the temporary table is real, and it gets more valuable as the grouped result grows. The same principle that removed `filesort` removes `Using temporary`: give MySQL the rows already in the order it needs.

## Pagination: OFFSET vs Keyset {#pagination-offset-vs-keyset}

Pagination is where a query that looks harmless turns into a time bomb. The natural way to fetch page N is `LIMIT 20 OFFSET (N-1)*20`, and it works fine for the first few pages. The problem is that `OFFSET` does not skip rows for free; MySQL still has to produce every row up to the offset and then discard them. Page 1 is instant.

```sql
EXPLAIN ANALYZE SELECT id, customer_id, total
FROM orders
ORDER BY id
LIMIT 20 OFFSET 0;
```

```
-> Limit: 20 row(s)  (cost=0.0171 rows=20) (actual time=0.0129..0.0153 rows=20 loops=1)
    -> Index scan on orders using PRIMARY  (cost=0.0171 rows=20) (actual time=0.0124..0.0141 rows=20 loops=1)
```

About 0.015 milliseconds, because MySQL reads 20 rows off the primary key and stops. Now jump to page 10,001 by setting the offset to 200,000.

```sql
EXPLAIN SELECT id, customer_id, total
FROM orders
ORDER BY id
LIMIT 20 OFFSET 200000;
```

```
+----+-------------+--------+------------+-------+---------------+---------+---------+------+--------+----------+-------+
| id | select_type | table  | partitions | type  | possible_keys | key     | key_len | ref  | rows   | filtered | Extra |
+----+-------------+--------+------------+-------+---------------+---------+---------+------+--------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | index | NULL          | PRIMARY | 8       | NULL | 200020 |   100.00 | NULL  |
+----+-------------+--------+------------+-------+---------------+---------+---------+------+--------+----------+-------+
```

The `rows` estimate is 200,020, not 20. MySQL plans to read everything up to and including the page we want. The measured plan confirms the waste.

```sql
EXPLAIN ANALYZE SELECT id, customer_id, total
FROM orders
ORDER BY id
LIMIT 20 OFFSET 200000;
```

```
-> Limit/Offset: 20/200000 row(s)  (cost=8194 rows=20) (actual time=38.4..38.4 rows=20 loops=1)
    -> Index scan on orders using PRIMARY  (cost=8194 rows=200020) (actual time=0.15..33.7 rows=200020 loops=1)
```

The inner node actually read 200,020 rows to return 20, taking about 38 milliseconds, and that number climbs linearly the deeper a user pages. The fix is keyset pagination, also called seek pagination. Instead of telling MySQL how many rows to skip, you tell it where the last page ended and ask for the next batch directly. Since the previous page ended at `id = 200000`, the next page is simply the rows with a greater id.

```sql
EXPLAIN SELECT id, customer_id, total
FROM orders
WHERE id > 200000
ORDER BY id
LIMIT 20;
```

```
+----+-------------+--------+------------+-------+---------------+---------+---------+------+--------+----------+-------------+
| id | select_type | table  | partitions | type  | possible_keys | key     | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+--------+------------+-------+---------------+---------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | range | PRIMARY       | PRIMARY | 8       | NULL | 249315 |   100.00 | Using where |
+----+-------------+--------+------------+-------+---------------+---------+---------+------+--------+----------+-------------+
```

The access is now a `range` scan on the primary key. The `rows` estimate of 249,315 is just the optimizer's guess at how many rows match `id > 200000`; the important part is what actually happens when the `LIMIT` stops it early.

```sql
EXPLAIN ANALYZE SELECT id, customer_id, total
FROM orders
WHERE id > 200000
ORDER BY id
LIMIT 20;
```

```
-> Limit: 20 row(s)  (cost=49944 rows=20) (actual time=0.238..0.243 rows=20 loops=1)
    -> Filter: (orders.id > 200000)  (cost=49944 rows=249315) (actual time=0.238..0.242 rows=20 loops=1)
        -> Index range scan on orders using PRIMARY over (200000 < id)  (cost=49944 rows=249315) (actual time=0.236..0.239 rows=20 loops=1)
```

The actual rows read is 20, and the time is about 0.24 milliseconds, the same as page 1, because the index jumps straight to `id = 200000` and reads forward 20 rows. Deep `OFFSET` took 38 milliseconds for the identical page; keyset pagination took a fraction of a millisecond and, crucially, will not get slower at page 50,000. The trade is that keyset pagination needs a unique, ordered column to seek on, usually the primary key or a composite of the sort column plus a tiebreaker, and you cannot jump to an arbitrary page number, only forward and backward from where you are. For infinite scroll and "next page" links that is exactly the access pattern anyway, which is why keyset pagination is the right default for any list that can grow large.

## Conclusion {#conclusion}

The skill from part one, deciding with `EXPLAIN` instead of guessing, is the same skill that fixes the four query shapes that dominate real applications. A join is a nested loop that lives or dies on the index on its join column, a sort and a group are both about giving MySQL the rows in the order it needs so it can skip `filesort` and `Using temporary`, and pagination is about not reading rows you are going to throw away. Read the plan, find the expensive node, and give it the index that removes it. Here are the ideas worth keeping.

- **Index every column you join on.** A join is a nested loop, and without an index on the join column MySQL scans the whole second table for every driving row, so in practice index your foreign keys.
- **`Using filesort` means MySQL sorted the rows itself.** An index on the `ORDER BY` column lets it read rows already sorted, even backward for `DESC`, and skip the sort entirely.
- **A composite index can serve `WHERE` and `ORDER BY` together.** Put the equality filter column first and the sort column second, so one index both finds and orders the rows.
- **`Using temporary` means `GROUP BY` built a temporary table.** An index on the grouping column lets MySQL stream and aggregate in order with no temporary table.
- **Deep `OFFSET` reads everything it skips.** `LIMIT 20 OFFSET 200000` produces 200,020 rows to return 20, and the cost grows with the page number.
- **Keyset pagination stays constant.** Seeking with `WHERE id > :last_seen ORDER BY id LIMIT n` reads only the rows you return, at the price of forward and backward movement instead of random page jumps.
