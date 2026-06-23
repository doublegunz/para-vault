## 1. Before You Begin

SELECT retrieves data and WHERE filters it, but the results still come back in an unpredictable order and may contain duplicate values. **ORDER BY** sorts results by one or more columns. **LIMIT** restricts how many rows are returned. **DISTINCT** removes duplicate values from the output. These three clauses turn raw query results into useful, organized output - the kind you would display in a top-ten list, a paginated table, or a dropdown of available options.

### What You'll Build

You will write queries for top-N lists, paginated results, and unique value lists from the `books` table.

### What You'll Learn

- ✅ `ORDER BY column ASC|DESC` for sorting
- ✅ Sorting by multiple columns
- ✅ `LIMIT n` to restrict output
- ✅ `LIMIT n OFFSET m` for pagination
- ✅ `DISTINCT` to remove duplicate values
- ✅ Combining ORDER BY, LIMIT, and WHERE

### What You'll Need

- The `bookstore` database with the `books` table

---

## 2. Setup

Connect to MySQL and select the bookstore database before running any queries.

```sql
mysql -u root -p
USE bookstore;
```

Once you see `Database changed`, you are ready to write queries that use ORDER BY, LIMIT, and DISTINCT.

---

## 3. ORDER BY

Without ORDER BY, MySQL returns rows in an unspecified order that can change between queries. ORDER BY lets you specify exactly how results should be sorted.

```sql
SELECT title, price FROM books ORDER BY price ASC;
```

```sql
SELECT title, price FROM books ORDER BY price DESC;
```

```sql
SELECT title, category, price
FROM books
ORDER BY category ASC, price DESC;
```

```sql
SELECT title, published_year FROM books ORDER BY published_year DESC;
```

```sql
SELECT title, price * stock AS inventory_value
FROM books
ORDER BY inventory_value DESC;
```

`ASC` (ascending) sorts from lowest to highest and is the default when you omit the direction. `DESC` (descending) sorts from highest to lowest. When you sort by multiple columns, the second column breaks ties in the first. In the third example, books are first sorted alphabetically by category, and within each category, they are sorted by price from most to least expensive. The last example shows that you can ORDER BY a calculated column alias - this works because ORDER BY is evaluated after SELECT.

---

## 4. LIMIT

Large tables can have millions of rows. LIMIT prevents you from accidentally fetching more data than you need, which is important for both performance and usability.

```sql
SELECT title, price FROM books ORDER BY price DESC LIMIT 5;
```

```sql
SELECT title, published_year FROM books ORDER BY published_year DESC LIMIT 3;
```

```sql
SELECT title, price FROM books ORDER BY price ASC LIMIT 1;
```

```sql
SELECT title, price FROM books ORDER BY title LIMIT 5 OFFSET 0;
```

```sql
SELECT title, price FROM books ORDER BY title LIMIT 5 OFFSET 5;
```

```sql
SELECT title, price FROM books ORDER BY title LIMIT 5 OFFSET 10;
```

`LIMIT n` returns at most n rows. Without ORDER BY, the rows chosen are unpredictable, so always pair LIMIT with ORDER BY. `OFFSET m` skips the first m rows before returning results. Combined, `LIMIT 5 OFFSET 5` skips 5 rows and returns the next 5 - this is exactly how pagination works in web applications. Page 1 uses `OFFSET 0`, page 2 uses `OFFSET 5`, page 3 uses `OFFSET 10`, and so on.

---

## 5. DISTINCT

When a column contains repeated values, SELECT returns every row including duplicates. DISTINCT filters out rows where the specified columns are identical to a row already in the result.

```sql
SELECT DISTINCT category FROM books;
```

```sql
SELECT DISTINCT author FROM books;
```

```sql
SELECT COUNT(DISTINCT category) AS unique_categories FROM books;
```

```sql
SELECT DISTINCT category, published_year FROM books ORDER BY category;
```

`SELECT DISTINCT category FROM books` returns each category name only once, regardless of how many books belong to that category. This is useful for populating a filter dropdown or a list of available options. When applied to multiple columns like in the last example, DISTINCT removes rows where ALL listed columns are identical to a previous row. `COUNT(DISTINCT column)` counts how many unique values exist, which is different from `COUNT(*)` that counts all rows.

---

## 6. Combining Everything

In practice, these three clauses work together. The SQL clause order is fixed: SELECT, FROM, WHERE, ORDER BY, LIMIT.

```sql
SELECT title, price
FROM books
WHERE category = 'Programming'
ORDER BY price ASC
LIMIT 3;
```

```sql
SELECT DISTINCT category
FROM books
WHERE published_year > 2010
ORDER BY category;
```

```sql
SELECT title, price, stock, price * stock AS value
FROM books
WHERE stock > 10
ORDER BY value DESC
LIMIT 5;
```

The first query finds the three cheapest Programming books by filtering with WHERE, sorting with ORDER BY, and then taking the top 3 with LIMIT. The second finds every category that has at least one book published after 2010, without repeating category names. The third finds the five books with the highest inventory value among those with more than 10 items in stock.

**Query execution order matters:** MySQL processes clauses in this internal sequence: FROM, WHERE, SELECT, DISTINCT, ORDER BY, LIMIT. This is why you cannot use a column alias defined in SELECT inside a WHERE clause - WHERE is evaluated before SELECT runs. However, you can use an alias in ORDER BY because ORDER BY executes after SELECT.

---

## 7. Fix the Errors in Your Code

These three errors are among the most common structural mistakes when first using ORDER BY, LIMIT, and DISTINCT.

**Error 1: ORDER BY placed after LIMIT.**

SQL clauses must appear in a specific order. LIMIT always comes last.

```sql
-- Wrong: LIMIT before ORDER BY
SELECT title FROM books LIMIT 5 ORDER BY price;

-- Correct: ORDER BY before LIMIT
SELECT title FROM books ORDER BY price LIMIT 5;
```

MySQL will return a syntax error if you put LIMIT before ORDER BY. The correct fixed order for a complete query is: SELECT, FROM, WHERE, ORDER BY, LIMIT.

**Error 2: Using a column alias in WHERE.**

WHERE is processed before SELECT, so aliases defined in SELECT do not yet exist when WHERE runs.

```sql
-- Wrong: alias "value" does not exist during WHERE evaluation
SELECT title, price * stock AS value FROM books WHERE value > 1000;

-- Correct: repeat the expression in WHERE
SELECT title, price * stock AS value FROM books WHERE price * stock > 1000;
```

The alias `value` is only available in ORDER BY and HAVING, not in WHERE. The fix is to write out the full expression `price * stock > 1000` directly in the WHERE clause.

**Error 3: DISTINCT in the wrong position.**

DISTINCT must come immediately after SELECT, before any column names.

```sql
-- Wrong: DISTINCT after a column name
SELECT title, DISTINCT category FROM books;

-- Correct: DISTINCT immediately after SELECT
SELECT DISTINCT category FROM books;
```

`SELECT title, DISTINCT category` is a syntax error. DISTINCT applies to the entire row result (all listed columns), not to an individual column. If you need to count distinct values within a specific column, use `COUNT(DISTINCT column)` instead.

---

## 8. Exercises

**Exercise 1:** Write a query to find the 5 books with the highest inventory value (price * stock). Display title, price, stock, and inventory value. Sort by inventory value descending.

**Exercise 2:** Write a query to display books on "page 2" of a paginated list (5 books per page), sorted alphabetically by title. Show title and author.

**Exercise 3:** Write a query that shows all unique combinations of category and published_year for books published after 2010. Sort by category, then by year.

---

## 9. Solutions

**Solution for Exercise 1:**

Calculate the inventory value as a computed column, then sort by it descending and take only the top 5.

```sql
SELECT title, price, stock, price * stock AS inventory_value
FROM books
ORDER BY inventory_value DESC
LIMIT 5;
```

`price * stock AS inventory_value` creates the computed column. Using the alias `inventory_value` in ORDER BY works because ORDER BY is evaluated after SELECT. `LIMIT 5` then takes only the first 5 rows from the sorted result, which are the 5 books with the highest total inventory worth.

**Solution for Exercise 2:**

Page 2 of a 5-per-page list means skipping the first 5 rows (page 1) and returning the next 5.

```sql
SELECT title, author
FROM books
ORDER BY title ASC
LIMIT 5 OFFSET 5;
```

`ORDER BY title ASC` ensures the alphabetical ordering is consistent across pages. `LIMIT 5 OFFSET 5` skips the first 5 books (which would be page 1) and returns books 6 through 10. If you had 15 books sorted alphabetically, page 1 would be rows 1-5, page 2 rows 6-10, and page 3 rows 11-15.

**Solution for Exercise 3:**

Use DISTINCT with two columns and a WHERE condition to filter before removing duplicates.

```sql
SELECT DISTINCT category, published_year
FROM books
WHERE published_year > 2010
ORDER BY category, published_year;
```

`DISTINCT category, published_year` removes rows where both the category and the year are identical to a previous row. For example, if two Self-Help books were published in 2018, only one `(Self-Help, 2018)` row appears in the output. The ORDER BY clause then sorts the unique combinations first by category alphabetically, then by year within each category.

---

## Next Up - Lesson 6

ORDER BY sorts results (ASC ascending, DESC descending). LIMIT restricts the number of rows returned. LIMIT with OFFSET enables pagination. DISTINCT removes duplicate rows from the result. The correct clause order is: SELECT, FROM, WHERE, ORDER BY, LIMIT. Column aliases defined in SELECT are available in ORDER BY but not in WHERE.

In Lesson 6, you will learn **aggregate functions and GROUP BY**: how to summarize data with COUNT, SUM, AVG, MIN, and MAX, and how to calculate those summaries separately for each group of rows.