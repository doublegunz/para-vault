## 1. Before You Begin

So far, every query returns individual rows. But often you need summaries: "How many books are there?", "What is the average price?", "What is the total inventory value?" **Aggregate functions** calculate a single value from multiple rows. **GROUP BY** lets you calculate aggregates for each group of rows separately, which is how you answer questions like "How many books does each category have?" or "What is the average price per category?".

### What You'll Build

You will write queries to summarize book data: counts, totals, averages, and grouped statistics by category.

### What You'll Learn

- ✅ `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`
- ✅ `GROUP BY` for grouped summaries
- ✅ `HAVING` for filtering groups (WHERE for groups)
- ✅ Combining GROUP BY with ORDER BY and LIMIT
- ✅ `COUNT(*)` vs `COUNT(column)` vs `COUNT(DISTINCT column)`

### What You'll Need

- The `bookstore` database with the `books` table

---

## 2. Setup

Connect to MySQL and select the bookstore database before running any queries in this lesson.

```sql
mysql -u root -p
USE bookstore;
```

Once you see `Database changed`, you are ready to run aggregate queries against the `books` table.

---

## 3. Aggregate Functions (Without GROUP BY)

When used without GROUP BY, aggregate functions treat the entire table as a single group and return exactly one row of results. This is useful for answering "how many total" or "what is the overall average" types of questions.

```sql
SELECT COUNT(*) AS total_books FROM books;
```

```sql
SELECT SUM(price * stock) AS total_inventory_value FROM books;
```

```sql
SELECT AVG(price) AS average_price FROM books;
```

```sql
SELECT
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive
FROM books;
```

```sql
SELECT
    COUNT(*) AS total_books,
    SUM(stock) AS total_stock,
    AVG(price) AS avg_price,
    MIN(published_year) AS oldest_year,
    MAX(published_year) AS newest_year
FROM books;
```

```sql
SELECT COUNT(*) AS programming_books
FROM books
WHERE category = 'Programming';
```

```sql
SELECT
    COUNT(*) AS all_rows,
    COUNT(category) AS rows_with_category
FROM books;
```

```sql
SELECT COUNT(DISTINCT category) AS unique_categories FROM books;
```

`COUNT(*)` counts all rows including those with NULL values. `COUNT(column)` counts only rows where that column is not NULL, so it can return a smaller number than `COUNT(*)` if the column has nulls. `COUNT(DISTINCT column)` counts how many unique non-NULL values the column has. `SUM()` adds all values. `AVG()` divides the sum by the count of non-NULL values. `MIN()` and `MAX()` find the smallest and largest values. You can combine multiple aggregate functions in a single SELECT clause, as shown in the fifth query above.

---

## 4. GROUP BY

GROUP BY divides rows into groups based on a column's value, then applies aggregate functions to each group separately. This is where aggregate functions become truly powerful.

```sql
SELECT category, COUNT(*) AS book_count
FROM books
GROUP BY category;
```

```sql
SELECT category, AVG(price) AS avg_price
FROM books
GROUP BY category
ORDER BY avg_price DESC;
```

```sql
SELECT category, SUM(stock) AS total_stock
FROM books
GROUP BY category
ORDER BY total_stock DESC;
```

```sql
SELECT
    FLOOR(published_year / 10) * 10 AS decade,
    COUNT(*) AS book_count
FROM books
WHERE published_year > 0
GROUP BY decade
ORDER BY decade;
```

```sql
SELECT
    category,
    COUNT(*) AS books,
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive,
    AVG(price) AS avg_price
FROM books
GROUP BY category
ORDER BY avg_price DESC;
```

GROUP BY combines all rows that share the same value in the grouped column. Each unique category becomes one row in the result. Every column in SELECT that is not inside an aggregate function must appear in the GROUP BY clause. If you list `category, title` in SELECT but only `GROUP BY category`, MySQL does not know which title to show for each group (since one category has many titles), causing an error or unpredictable results. The last query shows how to run multiple aggregates per group in a single pass.

---

## 5. HAVING (Filtering Groups)

WHERE filters individual rows before grouping. HAVING filters entire groups after aggregation. Use HAVING when your condition involves an aggregate function.

```sql
SELECT category, COUNT(*) AS book_count
FROM books
GROUP BY category
HAVING book_count > 2;
```

```sql
SELECT category, AVG(price) AS avg_price
FROM books
GROUP BY category
HAVING avg_price > 40
ORDER BY avg_price DESC;
```

```sql
SELECT category, COUNT(*) AS book_count, AVG(price) AS avg_price
FROM books
WHERE published_year > 2000
GROUP BY category
HAVING book_count >= 2
ORDER BY avg_price DESC;
```

`HAVING book_count > 2` keeps only groups (categories) that have more than 2 books. You cannot write this as a WHERE condition because `book_count` does not exist until after GROUP BY runs. The third query shows WHERE and HAVING working together: `WHERE published_year > 2000` filters rows first, then GROUP BY groups the remaining rows, then `HAVING book_count >= 2` filters the groups. This sequence is important to understand: WHERE, then GROUP BY, then HAVING.

---

## 6. Complete Example

This section brings all the pieces together in a single query that generates a category report with multiple aggregates and both a HAVING filter and an ORDER BY.

```sql
SELECT
    category,
    COUNT(*) AS books,
    SUM(stock) AS total_stock,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(price * stock) AS inventory_value
FROM books
GROUP BY category
HAVING books >= 2
ORDER BY inventory_value DESC;
```

`ROUND(value, 2)` rounds a number to 2 decimal places, which keeps the average price tidy. `HAVING books >= 2` excludes any category that has only one book (since a single book is not a meaningful group for a category report). The result is sorted by total inventory value descending, so the most valuable category appears first. This pattern - GROUP BY with multiple aggregates, a HAVING filter, and an ORDER BY - is one of the most common patterns in reporting queries.

---

## 7. Fix the Errors in Your Code

These three errors are specific to GROUP BY and HAVING queries and are very commonly encountered by beginners.

**Error 1: Non-aggregated column in SELECT without GROUP BY.**

When using GROUP BY, every column in SELECT must either be in the GROUP BY clause or wrapped in an aggregate function.

```sql
-- Wrong: "title" is not in GROUP BY and not aggregated
SELECT category, title, COUNT(*) FROM books GROUP BY category;

-- Correct option A: remove title from SELECT
SELECT category, COUNT(*) FROM books GROUP BY category;

-- Correct option B: add title to GROUP BY
SELECT category, title, COUNT(*) FROM books GROUP BY category, title;
```

The wrong version asks MySQL to show a `title` for each category group, but each category has multiple titles. MySQL cannot pick one without being told which to use. Adding `title` to GROUP BY means each unique `(category, title)` pair becomes a separate group.

**Error 2: Using WHERE instead of HAVING for aggregate conditions.**

WHERE is evaluated before aggregation, so aggregate aliases like `cnt` do not exist at that point.

```sql
-- Wrong: "cnt" alias does not exist during WHERE evaluation
SELECT category, COUNT(*) AS cnt
FROM books
WHERE cnt > 2
GROUP BY category;

-- Correct: use HAVING for post-aggregation filters
SELECT category, COUNT(*) AS cnt
FROM books
GROUP BY category
HAVING cnt > 2;
```

MySQL evaluates WHERE before GROUP BY, so it has no knowledge of aggregate results like `cnt` at that stage. HAVING runs after GROUP BY and can reference both aggregate results and aliases.

**Error 3: Forgetting GROUP BY when selecting a non-aggregated column with an aggregate.**

Without GROUP BY, MySQL aggregates the entire table into one row. Any non-aggregated column included in that query produces an unpredictable value.

```sql
-- Wrong: "category" has no GROUP BY, so MySQL picks an arbitrary value
SELECT category, AVG(price) FROM books;

-- Correct: tell MySQL which groups to calculate averages for
SELECT category, AVG(price) FROM books GROUP BY category;
```

Without GROUP BY, the entire `books` table is treated as one group. MySQL returns a single row with the overall average price and an arbitrary category value, which is almost certainly not what you intended. Adding `GROUP BY category` creates one result row per category.

---

## 8. Exercises

**Exercise 1:** Write a query that shows the total number of books and total inventory value for each category. Sort by inventory value descending.

**Exercise 2:** Write a query that finds authors who have more than 1 book in the table. Display the author name and book count. (Hint: GROUP BY author HAVING COUNT(*) > 1.)

**Exercise 3:** Write a query that shows the average price and total stock for books published after 2010, grouped by category, but only for categories with an average price above $20. Sort by average price descending.

---

## 9. Solutions

**Solution for Exercise 1:**

Group by category and compute both COUNT and the inventory value SUM, then order results by the largest inventory value first.

```sql
SELECT
    category,
    COUNT(*) AS total_books,
    SUM(price * stock) AS inventory_value
FROM books
GROUP BY category
ORDER BY inventory_value DESC;
```

`COUNT(*)` counts all books in each category group, while `SUM(price * stock)` adds up the inventory value for every book in that category. The result gives you both the depth (how many titles) and the worth (total dollar value) of each category's inventory.

**Solution for Exercise 2:**

Group by author and use HAVING to keep only those with more than one book.

```sql
SELECT author, COUNT(*) AS book_count
FROM books
GROUP BY author
HAVING book_count > 1;
```

With the current 15-book dataset, most authors have only one book, so this query likely returns a small or empty set. If you added more books by "Robert C. Martin" or "Martin Fowler" in earlier exercises, those authors will appear here. `HAVING book_count > 1` runs after GROUP BY, making it the correct place for this aggregate condition.

**Solution for Exercise 3:**

Apply the year filter with WHERE before grouping, then apply the average price filter with HAVING after grouping.

```sql
SELECT
    category,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(stock) AS total_stock
FROM books
WHERE published_year > 2010
GROUP BY category
HAVING avg_price > 20
ORDER BY avg_price DESC;
```

`WHERE published_year > 2010` eliminates rows from before 2011 before any grouping happens. GROUP BY then groups the remaining rows by category. `HAVING avg_price > 20` removes any category whose average price (calculated only from post-2010 books) is $20 or less. The final ORDER BY sorts the remaining categories by descending average price.

---

## Next Up - Lesson 7

Aggregate functions (COUNT, SUM, AVG, MIN, MAX) summarize multiple rows into a single value. GROUP BY creates groups so each group gets its own aggregate calculation. HAVING filters groups after aggregation, while WHERE filters individual rows before aggregation. Every non-aggregated column in SELECT must appear in GROUP BY.

In Lesson 7, you will learn **INSERT**: how to add new rows to tables, covering single-row inserts, multi-row inserts, default values, and auto-increment IDs.