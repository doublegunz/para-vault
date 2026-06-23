## 1. Before You Begin

INSERT adds data. UPDATE changes existing data. DELETE removes data. These are the remaining DML (Data Manipulation Language) operations that complete the CRUD cycle: Create (INSERT), Read (SELECT), Update (UPDATE), Delete (DELETE). Both UPDATE and DELETE use WHERE to target specific rows. **Forgetting WHERE is the most dangerous mistake in SQL - it affects every row in the table.** This lesson teaches these operations along with the safety habits that prevent accidental data loss.

### What You'll Build

You will update book prices, modify customer information, and delete rows from the `books` table using safe practices.

### What You'll Learn

- ✅ `UPDATE ... SET ... WHERE` to change data
- ✅ Updating multiple columns at once
- ✅ `DELETE FROM ... WHERE` to remove rows
- ✅ The danger of UPDATE/DELETE without WHERE
- ✅ Safe practices: SELECT before UPDATE/DELETE
- ✅ `TRUNCATE TABLE` to delete all rows

### What You'll Need

- The `bookstore` database with books, authors, and customers tables

---

## 2. Setup

Connect to MySQL and select the bookstore database before running any statements in this lesson.

```sql
mysql -u root -p
USE bookstore;
```

Once you see `Database changed`, you are ready to run UPDATE and DELETE statements against the `bookstore` database.

---

## 3. UPDATE

UPDATE changes the values of one or more columns in rows that match the WHERE condition. The SET clause lists what to change and what to change it to.

```sql
UPDATE books SET price = 48.00 WHERE id = 1;
```

```sql
SELECT id, title, price FROM books WHERE id = 1;
```

```sql
UPDATE books SET price = 52.00, stock = 30 WHERE id = 2;
```

```sql
UPDATE books SET price = price * 1.10 WHERE category = 'Programming';
```

```sql
UPDATE books SET stock = stock + 5 WHERE category = 'Self-Help';
```

```sql
SELECT title, price, stock FROM books WHERE category = 'Programming';
```

The first UPDATE changes the price of the single book with `id = 1`. Filtering by primary key ensures exactly one row is updated. The third example updates two columns simultaneously by separating them with a comma in the SET clause. The fourth example uses a calculation: `price = price * 1.10` reads the current price, multiplies it by 1.10, and writes the result back. Any arithmetic expression is valid in SET. The fifth example increments stock by 5 for every Self-Help book, which is more efficient than updating each book individually.

### The Golden Rule

Always SELECT before UPDATE. Run the WHERE clause as a SELECT first to see exactly which rows will be affected before you commit to the change.

```sql
SELECT id, title, price FROM books WHERE category = 'Business';
```

```sql
UPDATE books SET price = price * 0.9 WHERE category = 'Business';
```

The SELECT in the first step shows you every row that the subsequent UPDATE will change. If the results look wrong, you can correct the WHERE condition before any data is modified. This habit costs almost nothing and prevents expensive mistakes.

---

## 4. DELETE

DELETE removes rows from a table permanently. Like UPDATE, it requires a WHERE clause to target specific rows.

```sql
DELETE FROM books WHERE id = 15;
```

```sql
SELECT * FROM books WHERE id = 15;
```

```sql
DELETE FROM books WHERE published_year < 0;
```

```sql
SELECT COUNT(*) FROM books;
```

The first DELETE removes the book with `id = 15`. After running the verification SELECT, you will see an empty result because the row no longer exists. The second DELETE removes all books where `published_year` is negative (which includes "The Art of War" with `published_year = -500`). Always run a COUNT or SELECT after a DELETE to confirm the correct number of rows were removed.

### Safety: Always SELECT First

Just as with UPDATE, run the WHERE condition as a SELECT before deleting anything.

```sql
SELECT id, title FROM books WHERE stock = 0;
```

```sql
DELETE FROM books WHERE stock = 0;
```

The SELECT shows you the exact rows that will be deleted. If the list looks correct, run the DELETE. If not, refine your WHERE condition. Deleted rows cannot be recovered without a database backup, so this two-step approach is essential.

---

## 5. Dangerous Mistakes

This section shows the most dangerous forms of UPDATE and DELETE so you can recognize and avoid them. The commented-out statements are intentionally not complete queries - they are shown as warnings only.

```sql
-- This would set every book's price to $0:
-- UPDATE books SET price = 0;

-- This would delete every row in the table:
-- DELETE FROM books;

-- TRUNCATE removes all rows and resets AUTO_INCREMENT to 1:
-- TRUNCATE TABLE books;
```

`UPDATE books SET price = 0` without a WHERE clause changes every single row in the `books` table. `DELETE FROM books` without WHERE removes every row. Both of these are valid SQL that MySQL will execute without warning. `TRUNCATE TABLE` is even faster than DELETE for clearing a table because it does not scan rows individually, but it also cannot be filtered with WHERE. All three are irreversible without a backup.

> **Best practice:** In production systems, wrap destructive operations in transactions. `START TRANSACTION;` begins a block, `ROLLBACK;` undoes everything in the block, and `COMMIT;` makes the changes permanent. Transactions are covered in advanced SQL topics beyond this course.

---

## 6. Fix the Errors in Your Code

These three errors are the most common mistakes with UPDATE and DELETE statements.

**Error 1: UPDATE without WHERE.**

Without WHERE, every row in the table is updated. There is no undo in standard MySQL without transactions.

```sql
-- Wrong: all books get category 'Unknown'
UPDATE books SET category = 'Unknown';

-- Correct: target specific rows with WHERE
UPDATE books SET category = 'Unknown' WHERE id = 99;
```

MySQL executes the wrong version without an error or warning. Every row in `books` will have its category overwritten with `'Unknown'`. Always include a WHERE clause and verify it with a SELECT first.

**Error 2: Incomplete SET clause.**

The SET clause requires a complete `column = value` assignment. Omitting the `= value` part causes a syntax error.

```sql
-- Wrong: missing = and the new value
UPDATE books SET title WHERE id = 1;

-- Correct: provide the full assignment
UPDATE books SET title = 'New Title' WHERE id = 1;
```

MySQL returns `ERROR 1064: You have an error in your SQL syntax`. The SET clause must always have the form `column = expression`. Without the `=` and the value, MySQL cannot determine what to write into the column.

**Error 3: Overly broad DELETE condition.**

A WHERE condition that matches most of the table can delete far more rows than intended.

```sql
-- Wrong: this would delete almost all books in the table
SELECT id, title FROM books WHERE price > 10;
DELETE FROM books WHERE price > 10;

-- Correct: always SELECT first to confirm scope, then narrow the condition if needed
SELECT id, title FROM books WHERE price > 70 AND category = 'Computer Science';
DELETE FROM books WHERE price > 70 AND category = 'Computer Science';
```

In the current dataset, `price > 10` matches nearly every book. Running the SELECT first reveals how many rows the DELETE would remove. If the count is higher than expected, add additional conditions to narrow the scope before executing the DELETE.

---

## 7. Exercises

**Exercise 1:** Increase the stock of all "Computer Science" books by 10. Use UPDATE with WHERE. Verify with a SELECT.

**Exercise 2:** Update the email of customer "Budi Santoso" to "budi.santoso@example.com". First SELECT to find the row, then UPDATE.

**Exercise 3:** Delete all books from the "Fiction" category (if any exist from previous exercise solutions). First SELECT to check, then DELETE. Verify with a count.

---

## 8. Solutions

**Solution for Exercise 1:**

First check which rows will be affected, then run the UPDATE, then verify the change.

```sql
SELECT title, stock FROM books WHERE category = 'Computer Science';
UPDATE books SET stock = stock + 10 WHERE category = 'Computer Science';
SELECT title, stock FROM books WHERE category = 'Computer Science';
```

`stock = stock + 10` reads the current stock value for each matching row and adds 10 to it. The first and third SELECT statements show the stock values before and after the update, confirming the change was applied correctly. All three Computer Science books ("Introduction to Algorithms", "Database System Concepts", "Artificial Intelligence") should show their stock increased by exactly 10.

**Solution for Exercise 2:**

Select the customer first to confirm the row exists, then update the email.

```sql
SELECT * FROM customers WHERE name = 'Budi Santoso';
UPDATE customers SET email = 'budi.santoso@example.com' WHERE name = 'Budi Santoso';
SELECT * FROM customers WHERE name = 'Budi Santoso';
```

Filtering by `name` works in this case because Budi Santoso is the only customer with that name. In production, filtering by `id` is safer because names are not guaranteed to be unique. The third SELECT confirms the email column now shows `budi.santoso@example.com`.

**Solution for Exercise 3:**

Check for Fiction books first, then delete them, then confirm with a count.

```sql
SELECT id, title FROM books WHERE category = 'Fiction';
DELETE FROM books WHERE category = 'Fiction';
SELECT COUNT(*) FROM books;
```

If you inserted "Dune" as a Fiction book during the Lesson 7 exercises, the first SELECT will show it. The DELETE then removes all Fiction books. The final `COUNT(*)` confirms the total row count has decreased by the number of rows deleted. If no Fiction books exist, the SELECT returns an empty set and the DELETE removes zero rows without an error.

---

## Next Up - Lesson 9

UPDATE changes existing rows using SET and WHERE. DELETE removes rows matching a WHERE condition. Both are dangerous without WHERE, as they affect every row in the table. Always SELECT first to preview which rows will be affected before running UPDATE or DELETE. TRUNCATE removes all rows and resets the auto-increment counter.

In Lesson 9, you will learn **CREATE TABLE**: how to design your own tables from scratch by choosing the right data types and adding constraints to enforce data integrity.