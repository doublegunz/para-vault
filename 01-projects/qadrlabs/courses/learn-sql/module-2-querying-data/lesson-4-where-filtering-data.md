## 1. Before You Begin

SELECT retrieves data. WHERE filters it. Without WHERE, every query returns all rows in the table. With WHERE, you ask specific questions: "Which books cost more than $50?", "Which books are in the Programming category?", "Which books were published between 2010 and 2020?" WHERE is the second most important SQL keyword after SELECT, and you will use it in almost every query you write.

### What You'll Build

You will write filtered queries using comparison operators, logical operators, pattern matching, range checks, and NULL handling against the `books` table.

### What You'll Learn

- ✅ Comparison operators: `=`, `!=`, `<`, `>`, `<=`, `>=`
- ✅ Logical operators: `AND`, `OR`, `NOT`
- ✅ Range: `BETWEEN ... AND ...`
- ✅ Lists: `IN (...)`
- ✅ Pattern matching: `LIKE` with `%` and `_`
- ✅ NULL checks: `IS NULL`, `IS NOT NULL`

### What You'll Need

- The `bookstore` database with the `books` table from Lesson 2

---

## 2. Setup

Connect to MySQL and select the database before running any query in this lesson.

```bash
mysql -u root -p
```

```sql
USE bookstore;
```

Once you see `Database changed`, all queries in this lesson will run against the `books` table in the `bookstore` database.

---

## 3. Comparison Operators

The most basic form of filtering uses comparison operators to check a column's value against a specific value. MySQL evaluates the condition for every row and only returns rows where the condition is true.

```sql
SELECT title, price FROM books WHERE price = 50.00;

SELECT title, price FROM books WHERE price > 50.00;

SELECT title, price FROM books WHERE price <= 50.00;

SELECT title, category FROM books WHERE category != 'Programming';

SELECT title, published_year FROM books WHERE published_year > 2015;
```

`=` checks for an exact match. `!=` (or `<>`) checks that the value does not match. `<`, `>`, `<=`, and `>=` compare numeric and date values. String comparisons with `=` are case-insensitive in MySQL by default, so `'Programming'` and `'programming'` match the same rows.

---

## 4. Logical Operators: AND, OR, NOT

A single WHERE condition filters on one criterion. Logical operators let you combine multiple conditions into a single filter.

```sql
SELECT title, price, category
FROM books
WHERE category = 'Programming' AND price > 50.00;
```

```sql
SELECT title, category
FROM books
WHERE category = 'Business' OR category = 'Self-Help';
```

```sql
SELECT title, category
FROM books
WHERE NOT category = 'Programming';
```

```sql
SELECT title, price, category
FROM books
WHERE (category = 'Programming' OR category = 'Computer Science')
  AND price < 60.00;
```

`AND` requires both conditions to be true. A row only appears in the result if it satisfies every `AND`-connected condition. `OR` requires at least one condition to be true. `NOT` reverses the result of a condition. When combining `AND` and `OR`, use parentheses to make your intent explicit.

> **Important:** Always use parentheses when combining AND and OR. Without them, AND is evaluated before OR, which can produce unexpected results. `A OR B AND C` is evaluated as `A OR (B AND C)`, not `(A OR B) AND C`.

---

## 5. BETWEEN, IN, and LIKE

These three operators provide concise ways to express common filtering patterns that would otherwise require multiple conditions.

```sql
SELECT title, price
FROM books
WHERE price BETWEEN 20.00 AND 50.00;
```

```sql
SELECT title, published_year
FROM books
WHERE published_year BETWEEN 2010 AND 2019;
```

```sql
SELECT title, category
FROM books
WHERE category IN ('Programming', 'Computer Science', 'Business');
```

```sql
SELECT title FROM books WHERE title LIKE 'The%';
SELECT title FROM books WHERE title LIKE '%Code%';
SELECT title FROM books WHERE title LIKE '%ing';
SELECT title FROM books WHERE author LIKE 'Martin%';
SELECT title FROM books WHERE title LIKE '____';
```

`BETWEEN` is inclusive on both ends, so `price BETWEEN 20.00 AND 50.00` is exactly the same as `price >= 20.00 AND price <= 50.00`. `IN` checks whether a value matches any item in a list. It is much shorter than writing multiple `OR` conditions. `LIKE` matches a pattern instead of an exact value. The `%` wildcard matches any sequence of zero or more characters. The `_` wildcard matches exactly one character. In the last example, `'____'` (four underscores) matches any title that is exactly four characters long.

---

## 6. IS NULL and IS NOT NULL

NULL requires special operators because it represents the absence of a value. Standard comparison operators (`=`, `!=`) do not work with NULL.

```sql
SELECT title, category
FROM books
WHERE category IS NULL;
```

```sql
SELECT title, category
FROM books
WHERE category IS NOT NULL;
```

`IS NULL` returns rows where the column has no value. `IS NOT NULL` returns rows that do have a value. In the current `books` dataset all rows have a category, so the first query returns an empty set. If you inserted a book without specifying a category, it would appear here. Never use `= NULL` to check for NULL values; it always returns an empty result because NULL cannot be compared to anything, including itself.

---

## 7. Combining Everything

In real queries, you will often combine several operators together. The key is to always think about the logical order: which rows do you want to include, and which do you want to exclude?

```sql
SELECT title, author, price, category, published_year
FROM books
WHERE category IN ('Programming', 'Computer Science')
  AND published_year > 2010
  AND price < 70.00;
```

```sql
SELECT title
FROM books
WHERE title LIKE '%the%';
```

```sql
SELECT title, price, category
FROM books
WHERE price > 40.00
  AND category != 'Programming';
```

The first query combines `IN`, `>`, and `<` to find books in technical categories that were published recently and cost less than $70. The second query uses `LIKE` with `%the%` to find any title containing the word "the" anywhere. In MySQL, `LIKE` comparisons are case-insensitive by default, so this also matches "The" at the start of titles like "The Art of War". The third query uses `>` and `!=` together to find expensive books outside the Programming category.

---

## 8. Fix the Errors in Your Code

These three errors are extremely common when first writing WHERE conditions.

**Error 1: String value without quotes.**

SQL distinguishes between column names and string values using quotes. A word without quotes is treated as a column name.

```sql
-- Wrong: Programming treated as a column name
SELECT * FROM books WHERE category = Programming;

-- Correct: string values go inside single quotes
SELECT * FROM books WHERE category = 'Programming';
```

Without quotes, MySQL looks for a column named `Programming`, which does not exist. The error message is `ERROR 1054: Unknown column 'Programming'`. Always wrap string values in single quotes.

**Error 2: Using `=` instead of `LIKE` for pattern matching.**

The `=` operator performs an exact match. It does not interpret `%` as a wildcard.

```sql
-- Wrong: looking for a book literally titled "%Code%"
SELECT * FROM books WHERE title = '%Code%';

-- Correct: use LIKE for pattern matching
SELECT * FROM books WHERE title LIKE '%Code%';
```

`WHERE title = '%Code%'` returns no results because no book is literally titled `%Code%`. Switching to `LIKE` tells MySQL to treat `%` as a wildcard.

**Error 3: AND/OR precedence without parentheses.**

Without parentheses, MySQL evaluates `AND` before `OR`, which changes the meaning of your query in ways that can be hard to spot.

```sql
-- Wrong: AND is evaluated first, giving unexpected results
SELECT * FROM books
WHERE category = 'Business' OR category = 'Self-Help' AND price > 25.00;

-- Correct: use parentheses to group the OR condition first
SELECT * FROM books
WHERE (category = 'Business' OR category = 'Self-Help') AND price > 25.00;
```

The wrong version is read as: `category = 'Business'` OR `(category = 'Self-Help' AND price > 25.00)`. This returns all Business books regardless of price. The correct version with parentheses first combines the two categories, then applies the price filter to both.

---

## 9. Exercises

**Exercise 1:** Write a query that finds all books with a price between $20 and $30, published after 2010. Display the title, price, and published year.

**Exercise 2:** Write a query that finds books whose author name contains "Martin" (case-insensitive). Display the title and author.

**Exercise 3:** Write a query that finds all books that are NOT in the categories "Programming" or "Computer Science" and have more than 20 items in stock. Display title, category, and stock.

---

## 10. Solutions

**Solution for Exercise 1:**

Use `BETWEEN` for the price range and `>` for the year condition, combining them with `AND`.

```sql
SELECT title, price, published_year
FROM books
WHERE price BETWEEN 20.00 AND 30.00
  AND published_year > 2010;
```

`BETWEEN 20.00 AND 30.00` is inclusive, meaning books priced exactly $20 or exactly $30 are also included. The `AND published_year > 2010` condition further narrows the results to books published in 2011 or later.

**Solution for Exercise 2:**

Use `LIKE` with `%Martin%` to match any author name containing "Martin" anywhere in the string.

```sql
SELECT title, author
FROM books
WHERE author LIKE '%Martin%';
```

The `%` before and after `Martin` means there can be any characters before or after it. This matches "Robert C. Martin" and "Martin Fowler" from our dataset. Because MySQL LIKE is case-insensitive by default, `'%martin%'` would return the same results.

**Solution for Exercise 3:**

Use `NOT IN` to exclude the two technical categories, then add a stock condition with `AND`.

```sql
SELECT title, category, stock
FROM books
WHERE category NOT IN ('Programming', 'Computer Science')
  AND stock > 20;
```

`NOT IN ('Programming', 'Computer Science')` excludes both categories at once, which is more concise than writing `category != 'Programming' AND category != 'Computer Science'`. The result includes books from History, Self-Help, Psychology, Business, Biography, and Philosophy categories that have more than 20 copies in stock.

---

## Next Up - Lesson 5

WHERE filters rows based on conditions. Comparison operators (`=`, `!=`, `<`, `>`) compare values. `AND` requires all conditions to be true, `OR` requires at least one. `BETWEEN` checks inclusive ranges, `IN` checks membership in a list, `LIKE` matches patterns with `%` (any characters) and `_` (exactly one character). `IS NULL` checks for missing values. Always use parentheses when combining `AND` with `OR`.

In Lesson 5, you will learn **ORDER BY, LIMIT, and DISTINCT**: how to sort your results, limit how many rows are returned, and remove duplicate values from output.