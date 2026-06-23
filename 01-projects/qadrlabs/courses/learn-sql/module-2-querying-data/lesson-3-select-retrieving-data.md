## 1. Before You Begin

SELECT is the most-used SQL statement. It retrieves data from one or more tables. Every report, every search result, every data display in every application starts with a SELECT query. In Lesson 2 you created the `books` table with 15 rows of sample data. In this lesson, you will use that data to learn how to choose which columns to retrieve, rename columns with aliases, perform calculations, and use basic string functions.

### What You'll Build

You will write queries to retrieve book data in different ways: specific columns, calculated prices, formatted output, and renamed columns.

### What You'll Learn

- ✅ `SELECT *` to retrieve all columns
- ✅ `SELECT column1, column2` to retrieve specific columns
- ✅ Column aliases with `AS`
- ✅ Arithmetic in SELECT: `price * 1.1`
- ✅ String functions: `UPPER()`, `LOWER()`, `CONCAT()`, `LENGTH()`
- ✅ `NULL` values and how they behave

### What You'll Need

- MySQL running with the `bookstore` database from Lesson 2
- The `books` table with 15 rows of sample data

---

## 2. Setup

Connect to MySQL and select the database before running any query. You must do this at the start of every session.

```bash
mysql -u root -p
```

```sql
USE bookstore;
```

Once you see `Database changed`, you are ready to run queries against the `bookstore` database.

---

## 3. Selecting All Columns

The simplest SELECT query retrieves every column from a table. The asterisk (`*`) is a shorthand that tells MySQL to include all columns.

```sql
SELECT * FROM books;
```

The `*` means "all columns." This returns every column and every row in the `books` table. You should see all 15 books with all 8 columns displayed.

> **Tip:** `SELECT *` is convenient for exploration but avoid it in production code. Always specify the columns you need. Selecting unused columns wastes bandwidth and makes the query harder to maintain.

---

## 4. Selecting Specific Columns

More often than not, you only need a subset of columns. Listing the columns you want makes your intent clear and reduces the amount of data transferred from the database.

```sql
SELECT title, price FROM books;
```

```sql
SELECT title, author, published_year FROM books;
```

Both queries return all 15 rows, but only the columns you listed. The column order in the output matches the order you specified in the query, not the order they appear in the table.

---

## 5. Column Aliases

Column aliases let you rename columns in the query output without changing the table. This is useful when a column name is technical or unclear, or when you want a friendlier label for a report.

```sql
SELECT
    title AS book_title,
    author AS written_by,
    price AS price_usd
FROM books;
```

```sql
SELECT
    title AS "Book Title",
    price AS "Price (USD)"
FROM books;
```

`AS` renames the column only in the result set. The underlying table is not affected. When an alias contains spaces or special characters, wrap it in double quotes. Aliases are commonly used in combination with calculated columns, which we cover next.

---

## 6. Arithmetic in SELECT

SQL allows you to use arithmetic operators directly in a SELECT statement. This lets you compute new values on the fly without modifying any data in the table.

```sql
SELECT
    title,
    price,
    price * 0.11 AS tax,
    price * 1.11 AS price_with_tax
FROM books;
```

```sql
SELECT
    title,
    price,
    stock,
    price * stock AS inventory_value
FROM books;
```

```sql
SELECT
    title,
    published_year,
    2026 - published_year AS age_years
FROM books;
```

SQL supports `+`, `-`, `*`, `/`, and `%` (modulo) in SELECT. The arithmetic is evaluated for every row, so `price * stock` gives you the inventory value for each individual book without any extra code.

---

## 7. String Functions

MySQL includes built-in string functions that transform text values during a query. These are useful for formatting output, standardizing case, and combining values.

```sql
SELECT
    UPPER(title) AS title_upper,
    LOWER(author) AS author_lower
FROM books;
```

```sql
SELECT
    CONCAT(title, ' by ', author) AS full_description
FROM books;
```

```sql
SELECT
    title,
    LENGTH(title) AS title_length
FROM books;
```

```sql
SELECT
    title,
    SUBSTRING(title, 1, 20) AS short_title
FROM books;
```

```sql
SELECT
    title,
    REPLACE(title, 'The ', '') AS without_the
FROM books;
```

`UPPER()` and `LOWER()` change the letter case of a string. `CONCAT()` joins multiple strings together into one - notice how we added ` by ` as a literal string between the title and the author. `LENGTH()` returns the number of characters. `SUBSTRING(string, start, length)` extracts a portion of a string starting at position `start` (1-indexed) and taking `length` characters. `REPLACE()` replaces every occurrence of the search string with the replacement.

---

## 8. Working with NULL

NULL is a special value in SQL that means "no value" or "unknown." In the `books` table, `category` and `published_year` are nullable, which means they can be NULL if no value was provided at insert time.

```sql
SELECT 10 + NULL;
SELECT NULL = NULL;
```

```sql
SELECT
    title,
    IFNULL(category, 'Uncategorized') AS category
FROM books;
```

```sql
SELECT COALESCE(NULL, NULL, 'default');
```

`10 + NULL` returns NULL, not 10, because any arithmetic involving NULL is undefined. `NULL = NULL` also returns NULL (not true), which is why you cannot use `=` to check for NULL. `IFNULL(value, fallback)` returns the fallback if the value is NULL. `COALESCE()` accepts any number of arguments and returns the first non-NULL value it finds - useful when you have several possible fallback columns.

---

## 9. Fix the Errors in Your Code

This section covers three mistakes that are very common when writing your first SELECT queries.

**Error 1: Misspelled column name.**

SQL is strict about column names. If the name does not match exactly, MySQL returns an error rather than guessing.

```sql
-- Wrong: typo in column name
SELECT titel, price FROM books;

-- Correct: exact column name
SELECT title, price FROM books;
```

The error message is `ERROR 1054: Unknown column 'titel' in 'field list'`. When you see this, run `DESCRIBE books;` to see the exact column names and correct your typo.

**Error 2: Missing comma between column names.**

Without a comma, MySQL interprets the second name as an alias for the first column, not as a separate column.

```sql
-- Wrong: missing comma makes "price" an alias for "title"
SELECT title price FROM books;

-- Correct: columns separated by commas
SELECT title, price FROM books;
```

This is a silent bug: the query runs without an error but returns only one column instead of two. Always double-check your column list for missing commas when the output does not look right.

**Error 3: Using `=` to check for NULL.**

NULL cannot be compared with `=`. The comparison always returns NULL (not true and not false), so no rows match.

```sql
-- Wrong: = cannot find NULL values
SELECT * FROM books WHERE category = NULL;

-- Correct: use IS NULL
SELECT * FROM books WHERE category IS NULL;
```

`WHERE category = NULL` returns an empty result even if NULL values exist. The correct syntax is `IS NULL` (or `IS NOT NULL` to find rows that do have a value). We cover WHERE in detail in Lesson 4.

---

## 10. Exercises

**Exercise 1:** Write a query that displays each book's title, author, and a column called `discounted_price` that shows the price with a 20% discount (price * 0.8).

**Exercise 2:** Write a query that displays each book's title and a column called `summary` that concatenates the title, " (", the published year, ")". Example output: "Clean Code (2008)".

**Exercise 3:** Write a query that shows the title, the length of the title, and the title in all uppercase. Sort mentally: which book has the longest title?

---

## 11. Solutions

**Solution for Exercise 1:**

Use `price * 0.8` to calculate the 20% discounted price and give it an alias so the column has a meaningful label.

```sql
SELECT
    title,
    author,
    price * 0.8 AS discounted_price
FROM books;
```

`price * 0.8` multiplies each book's original price by 0.8, which removes 20% from the value. The `AS discounted_price` alias gives the calculated column a readable name in the output. This approach does not change any data in the table; it only affects what is displayed.

**Solution for Exercise 2:**

Use `CONCAT()` to join the title, a literal opening parenthesis with a space, the published year, and a closing parenthesis.

```sql
SELECT
    title,
    CONCAT(title, ' (', published_year, ')') AS summary
FROM books;
```

`CONCAT()` accepts any number of arguments and joins them all into one string. Passing `published_year` (an INT column) works correctly because MySQL automatically converts the integer to a string when it is used inside `CONCAT()`.

**Solution for Exercise 3:**

Use `LENGTH()` and `UPPER()` together in the same query to see both the length and the uppercase version.

```sql
SELECT
    title,
    LENGTH(title) AS title_length,
    UPPER(title) AS title_upper
FROM books;
```

Scanning the `title_length` column, "Introduction to Algorithms" has the longest title at 26 characters. `LENGTH()` counts every character including spaces, while `UPPER()` converts all lowercase letters to uppercase without changing spaces or punctuation.

---

## Next Up - Lesson 4

SELECT retrieves data from tables. `SELECT *` gets all columns; listing specific columns is preferred. `AS` creates column aliases. Arithmetic operators (+, -, *, /) work in SELECT and are calculated per row. String functions like `UPPER()`, `LOWER()`, `CONCAT()`, `LENGTH()`, and `SUBSTRING()` transform text. `NULL` represents unknown values and requires `IS NULL` for comparison.

In Lesson 4, you will learn **WHERE**: filtering rows so that your queries return only the specific data you need instead of the entire table.