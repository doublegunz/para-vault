## 1. Before You Begin

Foreign keys connect tables. **JOIN** queries combine data from connected tables into a single result set. Instead of querying books in one query and then authors in a separate query and manually matching them in application code, a JOIN query returns book titles alongside author names in one operation. This is the most powerful feature of relational databases and one of the most important SQL skills you will use throughout your career.

### What You'll Build

You will write JOIN queries that combine books with authors, orders with customers, and multi-table reports that aggregate data across three or four tables at once.

### What You'll Learn

- ✅ `INNER JOIN`: rows that match in both tables
- ✅ `LEFT JOIN`: all rows from the left table, matched or not
- ✅ `RIGHT JOIN`: all rows from the right table
- ✅ Joining more than two tables
- ✅ Table aliases for shorter queries
- ✅ Combining JOIN with WHERE, ORDER BY, GROUP BY

### What You'll Need

- The `bookstore` database with foreign keys from Lesson 11

---

## 2. Setup

Connect to MySQL and select the bookstore database before running any queries in this lesson.

```sql
mysql -u root -p
USE bookstore;
```

Once you see `Database changed`, you are ready to write JOIN queries against the bookstore tables.

---

## 3. INNER JOIN

INNER JOIN returns only the rows that have a matching value in both tables. Rows from either table that have no match are excluded from the result.

```sql
SELECT
    b.title,
    a.name AS author_name,
    a.country
FROM books b
INNER JOIN authors a ON b.author_id = a.id;
```

`b` and `a` are **table aliases**: short names assigned after the table name that make the query easier to read and type. `ON b.author_id = a.id` is the join condition: it tells MySQL how the two tables relate, matching each book's `author_id` with the corresponding author's `id`. Only books that have a non-NULL `author_id` matching a row in `authors` appear in the result. Books where `author_id` is NULL are excluded.

```sql
SELECT
    o.id AS order_id,
    c.name AS customer_name,
    o.total_price,
    o.status,
    o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
ORDER BY o.order_date DESC;
```

```sql
SELECT
    o.id AS order_id,
    c.name AS customer,
    b.title AS book,
    o.quantity,
    o.total_price,
    o.status
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
INNER JOIN books b ON o.book_id = b.id
ORDER BY o.order_date DESC;
```

The second query joins two tables. The third joins three: `orders` is the starting table, `customers` is joined by `customer_id`, and `books` is joined by `book_id`. Each additional INNER JOIN adds another table to the result. You can chain as many JOINs as needed; just ensure each has its own ON condition.

---

## 4. LEFT JOIN

LEFT JOIN returns all rows from the left table, even when there is no matching row in the right table. Where there is no match, the right-side columns appear as NULL in the result.

```sql
SELECT
    b.title,
    b.author,
    a.name AS author_from_table,
    a.country
FROM books b
LEFT JOIN authors a ON b.author_id = a.id;
```

```sql
SELECT b.title, b.author
FROM books b
LEFT JOIN authors a ON b.author_id = a.id
WHERE a.id IS NULL;
```

```sql
SELECT
    c.name,
    c.email,
    COUNT(o.id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.email
ORDER BY order_count DESC;
```

The first query returns every book in the `books` table. For books that have a matching `author_id` in the `authors` table, the author's name and country appear. For books without a match (where `author_id` is NULL or references a non-existent author), `author_from_table` and `country` appear as NULL. The second query uses this behavior deliberately: by filtering `WHERE a.id IS NULL`, it finds books that are not linked to any row in the `authors` table. The third query counts orders per customer, and because it uses LEFT JOIN, customers with zero orders still appear in the result with `order_count = 0`.

---

## 5. RIGHT JOIN

RIGHT JOIN is the mirror of LEFT JOIN: it returns all rows from the right table, whether or not they have a match in the left table. Unmatched left-side columns appear as NULL.

```sql
SELECT
    a.name AS author,
    b.title
FROM books b
RIGHT JOIN authors a ON b.author_id = a.id;
```

```sql
SELECT
    a.name AS author,
    b.title
FROM authors a
LEFT JOIN books b ON a.id = b.author_id;
```

Both queries produce the same result: all authors, with their books listed next to them. Authors who have no books in the `books` table appear with NULL in the `title` column. Most developers prefer to rewrite RIGHT JOINs as LEFT JOINs by swapping the table order (as shown in the second query) because having the "main" table on the left reads more naturally and is easier to maintain.

---

## 6. Practical: Multi-Table Reports

Real reporting queries combine JOINs with GROUP BY, ORDER BY, and LIMIT to answer business questions. These examples demonstrate the patterns you will use most often.

```sql
SELECT
    c.name AS customer,
    COUNT(o.id) AS total_orders,
    SUM(o.total_price) AS total_spent
FROM customers c
INNER JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name
ORDER BY total_spent DESC;
```

```sql
SELECT
    b.title,
    COUNT(o.id) AS times_ordered,
    SUM(o.quantity) AS total_sold,
    SUM(o.total_price) AS revenue
FROM books b
INNER JOIN orders o ON b.id = o.book_id
GROUP BY b.id, b.title
ORDER BY revenue DESC
LIMIT 5;
```

```sql
SELECT b.title, b.price
FROM books b
LEFT JOIN orders o ON b.id = o.book_id
WHERE o.id IS NULL
ORDER BY b.title;
```

```sql
SELECT
    o.id AS order_id,
    c.name AS customer,
    c.city,
    b.title AS book,
    a.name AS author,
    o.quantity,
    o.total_price,
    o.status,
    o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
INNER JOIN books b ON o.book_id = b.id
LEFT JOIN authors a ON b.author_id = a.id
ORDER BY o.order_date DESC;
```

The first query joins `customers` and `orders` to calculate each customer's total spending. `GROUP BY c.id, c.name` groups all orders by customer. The second finds the top 5 most ordered books by revenue. The third uses LEFT JOIN with `WHERE o.id IS NULL` to find books that have never been ordered - this "anti-join" pattern is one of the most useful LEFT JOIN techniques. The fourth is a four-table JOIN that produces a full order report. Notice it uses LEFT JOIN for authors because some books may not have a linked author, and we still want those books to appear in the report.

---

## 7. Fix the Errors in Your Code

These three errors are the most common structural mistakes when writing JOIN queries.

**Error 1: Missing the ON clause.**

Without ON, MySQL performs a Cartesian product: every row from the first table is paired with every row from the second table. With 15 books and 6 authors, this produces 90 rows of meaningless combinations.

```sql
-- Wrong: no ON clause creates a Cartesian product
SELECT b.title, a.name
FROM books b
INNER JOIN authors a;

-- Correct: always specify the join condition
SELECT b.title, a.name
FROM books b
INNER JOIN authors a ON b.author_id = a.id;
```

The Cartesian product result looks like data but is entirely wrong because each book is matched to every author rather than its actual author. Always include `ON table1.column = table2.column` immediately after each JOIN.

**Error 2: Ambiguous column name.**

When two joined tables have a column with the same name (like `id`, which exists in both `books` and `authors`), MySQL does not know which table you mean.

```sql
-- Wrong: "id" exists in both tables; MySQL cannot determine which one
SELECT id, title, name
FROM books
INNER JOIN authors ON books.author_id = authors.id;

-- Correct: prefix every ambiguous column with its table name or alias
SELECT books.id, books.title, authors.name
FROM books
INNER JOIN authors ON books.author_id = authors.id;
```

The error message is `ERROR 1052: Column 'id' in field list is ambiguous`. The fix is to prefix ambiguous columns with the table name (or alias). As queries grow to three or four tables, it is good practice to prefix all column references with aliases to make the query unambiguous and easier to read.

**Error 3: Using INNER JOIN when the requirement needs LEFT JOIN.**

INNER JOIN silently drops rows that have no match. If your requirement is "all customers including those without orders," INNER JOIN will exclude the zero-order customers without any error.

```sql
-- Wrong: customers with no orders are silently excluded
SELECT c.name, COUNT(o.id)
FROM customers c
INNER JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name;

-- Correct: LEFT JOIN keeps all customers, COUNT(o.id) returns 0 for no-order customers
SELECT c.name, COUNT(o.id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name;
```

`COUNT(o.id)` rather than `COUNT(*)` is important here. When a customer has no orders, `o.id` is NULL for that row. `COUNT(o.id)` counts non-NULL values, so it returns 0 for customers with no orders. `COUNT(*)` would count the NULL row and incorrectly return 1.

---

## 8. Exercises

**Exercise 1:** Write a query that shows all books with their author name and country. Include books without a matching author. Sort by author name.

**Exercise 2:** Write a query that shows total revenue per customer city. Join `orders` with `customers`, GROUP BY city, and display city, order count, and total revenue. Sort by revenue descending.

**Exercise 3:** Write a query that lists customers who have never placed an order. Use LEFT JOIN with a WHERE IS NULL condition.

---

## 9. Solutions

**Solution for Exercise 1:**

Use LEFT JOIN so books without a linked author still appear in the results.

```sql
SELECT b.title, b.price, a.name AS author, a.country
FROM books b
LEFT JOIN authors a ON b.author_id = a.id
ORDER BY a.name;
```

Books that have `author_id = NULL` or whose `author_id` does not match any row in `authors` will appear with NULL in the `a.name` and `a.country` columns. `ORDER BY a.name` sorts matched authors alphabetically while placing NULL-author books at the top (MySQL sorts NULL values before non-NULL in ascending order by default).

**Solution for Exercise 2:**

Join `orders` to `customers` and group by the customer's city to produce city-level revenue totals.

```sql
SELECT
    c.city,
    COUNT(o.id) AS total_orders,
    SUM(o.total_price) AS total_revenue
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
GROUP BY c.city
ORDER BY total_revenue DESC;
```

`GROUP BY c.city` collapses all orders from customers in the same city into one result row. `COUNT(o.id)` counts the number of orders per city. `SUM(o.total_price)` adds up the total revenue from all those orders. INNER JOIN is appropriate here because we only care about cities that actually have orders.

**Solution for Exercise 3:**

Use LEFT JOIN to include all customers and filter for the ones where no order was found.

```sql
SELECT c.name, c.email
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
WHERE o.id IS NULL;
```

`LEFT JOIN orders o` includes every customer regardless of whether they have an order. For customers with no orders, `o.id` is NULL in the joined result. `WHERE o.id IS NULL` keeps only those rows, producing a list of customers who have placed zero orders. If you deleted customer 5 in Lesson 11, that customer no longer appears here. Any other customer with no orders in the `orders` table will show up.

---

## Next Up - Lesson 13

INNER JOIN returns only rows that match in both tables. LEFT JOIN returns all rows from the left table plus matches from the right. RIGHT JOIN is the mirror of LEFT JOIN. Always specify an ON condition to avoid Cartesian products. Prefix ambiguous column names with table aliases. Combine JOIN with WHERE, GROUP BY, ORDER BY, and LIMIT to build powerful multi-table reports.

In Lesson 13, you will learn **subqueries and views**: how to write queries inside other queries, and how to create reusable named query definitions with CREATE VIEW.