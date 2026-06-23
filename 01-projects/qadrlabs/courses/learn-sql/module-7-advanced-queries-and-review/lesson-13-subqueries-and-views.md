## 1. Before You Begin

A **subquery** is a query nested inside another query. It lets you answer complex questions like "Which books cost more than the average?", "Which customers have placed the most orders?", or "Which books have never been ordered?" A **view** is a saved query that behaves like a virtual table. Once created, you query it with simple SELECT statements without rewriting the underlying JOIN or aggregation logic every time. Subqueries and views are the advanced tools that complete your SQL toolkit.

### What You'll Build

You will write subqueries in WHERE, FROM, and SELECT clauses, then create views for common bookstore reports that can be reused throughout the application.

### What You'll Learn

- ✅ Subqueries in WHERE (scalar and list)
- ✅ Subqueries in FROM (derived tables)
- ✅ Subqueries in SELECT (correlated)
- ✅ `EXISTS` for existence checks
- ✅ `CREATE VIEW` for reusable queries
- ✅ When to use subqueries vs JOINs

### What You'll Need

- The `bookstore` database with all tables and data from previous lessons

---

## 2. Setup

Connect to MySQL and select the bookstore database before running any queries in this lesson.

```sql
mysql -u root -p
USE bookstore;
```

Once you see `Database changed`, you are ready to write subqueries and create views in the `bookstore` database.

---

## 3. Subqueries in WHERE

A subquery in a WHERE clause filters the outer query's rows based on a value or set of values calculated from another query. This is useful when the filter condition involves data from a different part of the database.

```sql
SELECT title, price
FROM books
WHERE price > (SELECT AVG(price) FROM books);
```

```sql
SELECT title, author
FROM books
WHERE author = (
    SELECT author
    FROM books
    GROUP BY author
    ORDER BY COUNT(*) DESC
    LIMIT 1
);
```

```sql
SELECT name, email
FROM customers
WHERE id IN (SELECT DISTINCT customer_id FROM orders);
```

```sql
SELECT name, email
FROM customers
WHERE id NOT IN (SELECT DISTINCT customer_id FROM orders);
```

```sql
SELECT title
FROM books
WHERE id IN (
    SELECT book_id
    FROM orders
    GROUP BY book_id
    HAVING COUNT(*) > 2
);
```

The first query uses a scalar subquery: `(SELECT AVG(price) FROM books)` returns a single number, and the outer WHERE compares each book's price against it. The second finds the author with the most books using GROUP BY and LIMIT 1 inside the subquery. The third uses `IN` to match any customer whose ID appears in the orders table, filtering for customers who have ordered at least once. The fourth uses `NOT IN` to do the opposite, finding customers who have never ordered. The fifth uses a GROUP BY inside the subquery to find book IDs that appear more than twice in orders, then shows those books' titles.

---

## 4. Subqueries in FROM (Derived Tables)

A subquery in the FROM clause creates a temporary result set called a **derived table**. You can then query it like any other table. This is useful when you need to perform an aggregation and then aggregate again on top of it.

```sql
SELECT AVG(order_count) AS avg_orders_per_customer
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) AS customer_orders;
```

```sql
SELECT c.name, co.total_spent
FROM (
    SELECT customer_id, SUM(total_price) AS total_spent
    FROM orders
    GROUP BY customer_id
) AS co
INNER JOIN customers c ON co.customer_id = c.id
ORDER BY co.total_spent DESC;
```

The first query cannot be written in a single GROUP BY because you are grouping, then averaging the group counts. The inner query calculates how many orders each customer has placed. The outer query then averages those per-customer counts. A derived table in FROM must have an alias (like `AS customer_orders` or `AS co`). Without an alias, MySQL returns a syntax error. The second query joins the derived table `co` to the `customers` table to add the customer's name to the spending totals.

---

## 5. Subqueries in SELECT (Correlated)

A subquery in the SELECT clause runs once for every row returned by the outer query. These are called **correlated subqueries** because they reference columns from the outer query inside the subquery.

```sql
SELECT
    title,
    price,
    (SELECT COUNT(*) FROM orders o WHERE o.book_id = b.id) AS order_count
FROM books b
ORDER BY order_count DESC;
```

```sql
SELECT
    name,
    email,
    (SELECT COALESCE(SUM(total_price), 0) FROM orders o WHERE o.customer_id = c.id) AS total_spent
FROM customers c
ORDER BY total_spent DESC;
```

In the first query, `b.id` references the outer `books` row. For each book, the subquery counts how many orders reference that book's ID. The result is a column that shows the number of times each book has been ordered. `COALESCE(SUM(total_price), 0)` in the second query handles customers with no orders: if `SUM` returns NULL (because there are no matching rows), `COALESCE` substitutes 0. Correlated subqueries are convenient but can be slow on large tables because they execute once per row. An equivalent JOIN with GROUP BY is usually faster.

---

## 6. EXISTS

EXISTS is an alternative to IN that checks whether a subquery returns at least one row. It stops searching as soon as it finds the first match, which can make it faster than IN for large datasets.

```sql
SELECT name, email
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.id
);
```

```sql
SELECT title
FROM books b
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.book_id = b.id
);
```

`SELECT 1` inside an EXISTS subquery is a convention: it does not matter what the subquery selects because EXISTS only cares whether any rows are returned at all. For each customer, MySQL checks whether any row in `orders` has a matching `customer_id`. If yes, EXISTS returns TRUE and the customer appears in the output. `NOT EXISTS` does the inverse: it returns rows from the outer query where the subquery finds no matches, making it useful for finding books that have never been ordered.

---

## 7. Views

A view is a stored query saved under a name in the database. Querying a view runs the underlying SQL automatically, without you having to write it again. Views simplify complex queries for everyday use.

```sql
CREATE VIEW v_book_catalog AS
SELECT
    b.id,
    b.title,
    a.name AS author,
    b.price,
    b.stock,
    b.category
FROM books b
LEFT JOIN authors a ON b.author_id = a.id;
```

```sql
SELECT * FROM v_book_catalog;
SELECT * FROM v_book_catalog WHERE category = 'Programming';
SELECT * FROM v_book_catalog WHERE price > 50 ORDER BY price DESC;
```

```sql
CREATE VIEW v_order_summary AS
SELECT
    o.id AS order_id,
    c.name AS customer,
    c.city,
    b.title AS book,
    o.quantity,
    o.total_price,
    o.status,
    o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
INNER JOIN books b ON o.book_id = b.id;
```

```sql
SELECT * FROM v_order_summary ORDER BY order_date DESC;
SELECT customer, SUM(total_price) AS spent FROM v_order_summary GROUP BY customer;
```

```sql
CREATE VIEW v_customer_spending AS
SELECT
    c.id AS customer_id,
    c.name,
    c.email,
    c.city,
    COUNT(o.id) AS total_orders,
    COALESCE(SUM(o.total_price), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.email, c.city;
```

```sql
SELECT * FROM v_customer_spending ORDER BY total_spent DESC;
```

```sql
SHOW FULL TABLES WHERE Table_type = 'VIEW';
```

`CREATE VIEW v_book_catalog AS` followed by a SELECT statement saves that SELECT as a named view. From then on, `SELECT * FROM v_book_catalog` behaves exactly like running the underlying JOIN query directly. Views do not store data themselves; they store the query definition and run it fresh each time. This means any changes to the underlying tables are immediately reflected in the view. You can filter, sort, and aggregate on top of views just like real tables. `SHOW FULL TABLES WHERE Table_type = 'VIEW'` lists all views in the current database. `DROP VIEW v_book_catalog` removes a view without affecting the underlying tables.

---

## 8. Subqueries vs JOINs

Both approaches can often solve the same problem. Understanding when to use each makes your queries more readable and performant.

| Approach | Best For |
|----------|----------|
| Subquery in WHERE | Filtering by aggregate values (above average, in a list) |
| Subquery in FROM | Creating intermediate summaries to query further |
| Correlated subquery | Per-row calculations that reference the outer query |
| JOIN | Combining columns from related tables into one result |
| VIEW | Reusing complex queries without rewriting them |

Many subqueries can be rewritten as JOINs and vice versa. JOINs are generally faster because MySQL can optimize them more effectively. Use subqueries when they make the logic clearer or when a JOIN would be harder to read. Use views to give frequently used queries a stable name that the rest of the team can rely on.

---

## 9. Fix the Errors in Your Code

These three errors are the most common structural mistakes when writing subqueries and creating views.

**Error 1: Subquery returns multiple rows where only one is expected.**

Comparison operators like `>`, `=`, and `<` expect a single value. If the subquery returns more than one row, MySQL returns an error.

```sql
-- Wrong: subquery returns multiple prices (all Programming books)
SELECT title FROM books
WHERE price > (SELECT price FROM books WHERE category = 'Programming');

-- Correct option A: use IN to compare against a list
SELECT title FROM books
WHERE price > ALL (SELECT price FROM books WHERE category = 'Programming');

-- Correct option B: use an aggregate to get a single value
SELECT title FROM books
WHERE price > (SELECT MAX(price) FROM books WHERE category = 'Programming');
```

`ERROR 1242: Subquery returns more than 1 row` means the inner query returned multiple rows when the operator needed exactly one. Use `IN` or `NOT IN` for list comparisons, or `ANY`, `ALL`, `MAX()`, `MIN()`, or `LIMIT 1` to reduce the subquery to a single value.

**Error 2: Derived table in FROM without an alias.**

Every subquery used in the FROM clause must be given an alias. Without an alias, MySQL cannot refer to the derived table's columns.

```sql
-- Wrong: no alias on the derived table
SELECT * FROM (SELECT customer_id, COUNT(*) FROM orders GROUP BY customer_id);

-- Correct: always add AS alias_name after the closing parenthesis
SELECT * FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) AS customer_orders;
```

MySQL returns `ERROR 1248: Every derived table must have its own alias`. Adding `AS customer_orders` immediately after the closing parenthesis of the subquery fixes the error. Choose a descriptive alias that reflects what the derived table represents.

**Error 3: ORDER BY inside a VIEW definition.**

ORDER BY in a view definition is not guaranteed to be preserved when you query the view. MySQL may ignore it or the behavior depends on the version.

```sql
-- Wrong: ORDER BY inside the view - not reliably preserved
CREATE VIEW v_test AS SELECT * FROM books ORDER BY price DESC;

-- Correct: define the view without ORDER BY, then sort when querying
CREATE VIEW v_test AS SELECT * FROM books;
SELECT * FROM v_test ORDER BY price DESC;
```

A view is a query definition, not a sorted result set. Any ORDER BY you need should be applied when you SELECT from the view, not inside the CREATE VIEW statement. This also makes views more flexible, since different queries can sort the same view in different ways.

---

## 10. Exercises

**Exercise 1:** Write a query that finds all books priced above the average price of their own category. Use a correlated subquery. Display the title, category, price, and the category average.

**Exercise 2:** Create a view called `v_category_stats` that shows each category with its book count, average price, total stock, and total inventory value. Query the view to find the most valuable category.

**Exercise 3:** Write a query using EXISTS to find authors who have at least one book in the bookstore. Display the author's name and country.

---

## 11. Solutions

**Solution for Exercise 1:**

Use a correlated subquery both in the SELECT list (to display the average) and in the WHERE clause (to filter).

```sql
SELECT
    b.title,
    b.category,
    b.price,
    (SELECT AVG(b2.price) FROM books b2 WHERE b2.category = b.category) AS category_avg
FROM books b
WHERE b.price > (SELECT AVG(b2.price) FROM books b2 WHERE b2.category = b.category);
```

For each book `b`, the correlated subquery `(SELECT AVG(b2.price) FROM books b2 WHERE b2.category = b.category)` calculates the average price of all books in the same category. The WHERE condition then keeps only books where the book's own price exceeds that category average. The same subquery appears twice: once in SELECT to display the average alongside the price, and once in WHERE to filter. In production, a derived table in FROM would calculate the average once per category and perform better.

**Solution for Exercise 2:**

Create the view with GROUP BY aggregates, then query it with ORDER BY.

```sql
CREATE VIEW v_category_stats AS
SELECT
    category,
    COUNT(*) AS book_count,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(stock) AS total_stock,
    SUM(price * stock) AS inventory_value
FROM books
GROUP BY category;

SELECT * FROM v_category_stats ORDER BY inventory_value DESC;
```

`CREATE VIEW v_category_stats AS` saves the GROUP BY query. From that point on, anyone with access to the database can run `SELECT * FROM v_category_stats` to get a category summary without writing the aggregation themselves. The ORDER BY in the second query sorts the categories by total inventory value, so the most valuable category appears first.

**Solution for Exercise 3:**

Use EXISTS with a correlated subquery that checks whether any book references the author's ID.

```sql
SELECT a.name, a.country
FROM authors a
WHERE EXISTS (SELECT 1 FROM books b WHERE b.author_id = a.id);
```

For each author in `authors`, the EXISTS subquery checks `books` for any row where `book_id = a.id`. If at least one such row exists, EXISTS returns TRUE and the author is included in the output. `SELECT 1` inside EXISTS is a convention: the subquery only needs to return any row, and EXISTS does not use the selected values. This query effectively filters out authors in the `authors` table who have no books linked to them.

---

## Next Up - Lesson 14

Subqueries are queries nested inside other queries. They can appear in WHERE (for filtering), FROM (as derived tables that must have an alias), and SELECT (as correlated per-row calculations). EXISTS checks whether a subquery returns any rows at all. Views are saved query definitions that behave like virtual tables, simplifying complex joins and aggregations into reusable names. JOINs are generally faster than equivalent correlated subqueries.

In Lesson 14, you will review everything you have learned and see how SQL connects to PHP, Python, Java, ORMs, and data analysis tools, plus get a roadmap for where to go next.