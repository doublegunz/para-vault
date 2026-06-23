## 1. Before You Begin

Tables evolve. Requirements change. You need to add a column, rename one, change a data type, or drop a column that is no longer needed. **ALTER TABLE** modifies existing tables without losing the data already stored in them. This lesson also introduces normalization: the practice of organizing tables to reduce redundancy and store each piece of information in exactly one place.

### What You'll Build

You will modify the existing bookstore tables by adding, renaming, and dropping columns. You will also add an `author_id` column to the `books` table and populate it, preparing the database for the foreign key relationship in Lesson 11.

### What You'll Learn

- ✅ `ALTER TABLE ... ADD COLUMN`
- ✅ `ALTER TABLE ... DROP COLUMN`
- ✅ `ALTER TABLE ... MODIFY COLUMN` (change type/constraints)
- ✅ `ALTER TABLE ... RENAME COLUMN`
- ✅ `ALTER TABLE ... RENAME TO` (rename the table)
- ✅ Introduction to normalization (reducing redundancy)

### What You'll Need

- The `bookstore` database with books, authors, customers, and orders tables

---

## 2. Setup

Connect to MySQL and select the bookstore database before running any statements in this lesson.

```sql
mysql -u root -p
USE bookstore;
```

Once you see `Database changed`, you are ready to run ALTER TABLE statements against the `bookstore` database.

---

## 3. Adding Columns

Adding a column with ALTER TABLE inserts the new column into the existing table structure without touching any existing rows or their data.

```sql
ALTER TABLE books ADD COLUMN isbn VARCHAR(20) AFTER title;
```

```sql
ALTER TABLE customers ADD COLUMN phone VARCHAR(20) AFTER email;
```

```sql
ALTER TABLE authors
    ADD COLUMN bio TEXT AFTER country,
    ADD COLUMN website VARCHAR(255) AFTER bio;
```

```sql
DESCRIBE books;
DESCRIBE customers;
DESCRIBE authors;
```

`AFTER column_name` controls where the new column appears in the table structure. Without `AFTER`, MySQL adds the column at the very end of the column list. A single ALTER TABLE statement can add multiple columns at once by chaining `ADD COLUMN` clauses with commas, as shown in the authors example. The `DESCRIBE` commands confirm the new columns appear in the expected positions.

---

## 4. Modifying Columns

MODIFY COLUMN lets you change a column's data type, length, constraints, or default value. The column name itself stays the same.

```sql
ALTER TABLE books MODIFY COLUMN isbn VARCHAR(30);
```

```sql
ALTER TABLE customers MODIFY COLUMN phone VARCHAR(20) DEFAULT '';
```

```sql
ALTER TABLE authors MODIFY COLUMN bio TEXT;
```

```sql
DESCRIBE books;
```

The first statement extends the `isbn` column from `VARCHAR(20)` to `VARCHAR(30)` without losing any data already stored. The second adds a default value of an empty string to the `phone` column. The third changes the `bio` column explicitly to TEXT (it was already TEXT, so this is a no-op). Always run `DESCRIBE` after modifying columns to verify the change took effect as expected.

---

## 5. Renaming and Dropping Columns

Renaming gives a column a new name without changing its data or type. Dropping removes the column and all its data permanently.

```sql
ALTER TABLE books RENAME COLUMN published_year TO pub_year;
```

```sql
ALTER TABLE books RENAME COLUMN pub_year TO published_year;
```

```sql
ALTER TABLE books DROP COLUMN isbn;
```

```sql
DESCRIBE books;
```

`RENAME COLUMN` is available in MySQL 8.0 and later. In older MySQL versions, you would use `CHANGE COLUMN old_name new_name type` instead. The two RENAME statements above demonstrate renaming and then renaming back. `DROP COLUMN` removes the column and every value stored in it across all rows. This is irreversible without a backup. The final `DESCRIBE books` confirms `isbn` is gone and `published_year` is back to its original name.

---

## 6. Introduction to Normalization

The current `books` table stores the author name as a plain string in the `author` column. If "Robert C. Martin" wrote three books, his name is stored three times. If we need to correct his name, we must find and update every row that contains it. This repetition is called **redundancy**, and it leads to inconsistent data when updates are missed.

**Normalization** solves this by storing each fact in exactly one place and using a reference (an ID) to connect related tables.

```
BEFORE (redundant):
books table: title, author_name, price
  "Clean Code", "Robert C. Martin", 45.00
  "Clean Architecture", "Robert C. Martin", 40.00

AFTER (normalized):
authors table: id, name
  1, "Robert C. Martin"

books table: title, author_id, price
  "Clean Code", 1, 45.00
  "Clean Architecture", 1, 40.00
```

Now the author name is stored once in `authors`. Both books reference author ID 1 instead of repeating the name. To correct a spelling mistake in the author's name, you update one row in `authors` and both books immediately reflect the change. This is the foundation for foreign keys (Lesson 11) and JOINs (Lesson 12).

---

## 7. Add author_id to Books

We will now add the `author_id` column to the `books` table and populate it by matching author names between the two tables. This is the practical step that connects the books and authors data before we formalize the relationship with a foreign key.

```sql
ALTER TABLE books ADD COLUMN author_id INT AFTER author;
```

```sql
UPDATE books SET author_id = 1 WHERE author = 'Robert C. Martin';
UPDATE books SET author_id = 2 WHERE author = 'Martin Fowler';
UPDATE books SET author_id = 3 WHERE author = 'James Clear';
UPDATE books SET author_id = 4 WHERE author = 'Yuval Noah Harari';
UPDATE books SET author_id = 5 WHERE author = 'Cal Newport';
UPDATE books SET author_id = 6 WHERE author = 'Eric Ries';
```

```sql
SELECT id, title, author, author_id FROM books;
```

`ALTER TABLE books ADD COLUMN author_id INT AFTER author` adds a nullable INT column next to the existing `author` column. It starts as NULL for all rows. The six UPDATE statements populate `author_id` for books whose authors appear in the `authors` table. Books by authors not in the `authors` table (like "Gang of Four" or "Sun Tzu") will remain NULL in `author_id`. In Lesson 11, we will add a FOREIGN KEY constraint that formalizes the link between `books.author_id` and `authors.id`.

---

## 8. Fix the Errors in Your Code

These three errors are the most common mistakes when using ALTER TABLE.

**Error 1: Adding a NOT NULL column without a DEFAULT to a table that already has data.**

When you add a NOT NULL column, MySQL must assign a value to every existing row. If there is no DEFAULT, MySQL does not know what value to use and returns an error.

```sql
-- Wrong: existing rows have no value for "rating" and no default is provided
ALTER TABLE books ADD COLUMN rating INT NOT NULL;

-- Correct: provide a default so existing rows get a value automatically
ALTER TABLE books ADD COLUMN rating INT NOT NULL DEFAULT 0;
```

The error message is `ERROR 1364: Field 'rating' doesn't have a default value` (on strict MySQL configurations). Adding `DEFAULT 0` tells MySQL to fill in `0` for all existing rows, satisfying the NOT NULL constraint without requiring you to update each row manually.

**Error 2: Dropping a column that does not exist.**

If the column was already dropped in a previous session, trying to drop it again causes an error.

```sql
-- Wrong: isbn was already dropped in this lesson
ALTER TABLE books DROP COLUMN isbn;

-- Correct: check with DESCRIBE first
DESCRIBE books;
-- If isbn appears in the output, then run:
ALTER TABLE books DROP COLUMN isbn;
```

The error message is `ERROR 1091: Can't DROP 'isbn'; check that column/key exists`. Running `DESCRIBE books` before the DROP lets you confirm the column still exists. Alternatively, use `ALTER TABLE books DROP COLUMN IF EXISTS isbn` in MySQL 8.0 or later.

**Error 3: Trying to change the primary key type after the table has data.**

Changing the data type of a column that is a PRIMARY KEY or referenced by foreign keys requires special handling and can break existing relationships.

```sql
-- Wrong: modifying a PRIMARY KEY column type is risky
ALTER TABLE books MODIFY COLUMN id VARCHAR(10);

-- Correct: plan the primary key type before creating the table
-- Do not change primary key types on tables with data or relationships
```

The safest approach is to decide on your primary key type (INT, BIGINT, UUID) at CREATE TABLE time and never change it. If you must change it on an existing table, you need to drop all foreign keys that reference it, make the change, and recreate the foreign keys. Plan your schema carefully from the start to avoid this situation.

---

## 9. Exercises

**Exercise 1:** Add a `discount_percent` column (DECIMAL(5,2), DEFAULT 0) to the books table. Update 3 books to have a 10% discount. Query books with their discounted price.

**Exercise 2:** Add a `is_active` column (BOOLEAN, DEFAULT TRUE) to the customers table. Set 2 customers to inactive (FALSE). Query only active customers.

**Exercise 3:** Drop the `employees` table (from Lesson 9 exercises, if it exists). Use `DROP TABLE IF EXISTS`.

---

## 10. Solutions

**Solution for Exercise 1:**

Add the column, update three rows, then query the result.

```sql
ALTER TABLE books ADD COLUMN discount_percent DECIMAL(5,2) DEFAULT 0;
UPDATE books SET discount_percent = 10 WHERE id IN (1, 2, 3);
SELECT title, price, discount_percent,
       price * (1 - discount_percent/100) AS discounted_price
FROM books WHERE discount_percent > 0;
```

`ALTER TABLE books ADD COLUMN discount_percent DECIMAL(5,2) DEFAULT 0` adds the column and immediately gives all 20+ existing rows a value of `0`. The UPDATE changes the discount for the first three books only. The final SELECT calculates the discounted price with `price * (1 - discount_percent/100)`: for a 10% discount, this becomes `price * 0.9`. Only books where `discount_percent > 0` appear in the output.

**Solution for Exercise 2:**

Add the column and then deactivate two customers.

```sql
ALTER TABLE customers ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
UPDATE customers SET is_active = FALSE WHERE id IN (4, 5);
SELECT name, email FROM customers WHERE is_active = TRUE;
```

BOOLEAN stores values as 0 (FALSE) or 1 (TRUE). `DEFAULT TRUE` means all existing customers start as active. The UPDATE marks customers 4 and 5 (Dewi Lestari and Eka Wahyuni) as inactive. The final SELECT returns only the three customers where `is_active = TRUE` (or `is_active = 1`), effectively filtering out the deactivated accounts.

**Solution for Exercise 3:**

Use `DROP TABLE IF EXISTS` to safely remove the table without risking an error.

```sql
DROP TABLE IF EXISTS employees;
```

`IF EXISTS` prevents MySQL from returning an error if the `employees` table was never created or was already dropped. This pattern is common in database migration scripts that may be run multiple times. If the table exists, it is removed along with all its data. If it does not exist, the statement completes silently.

---

## Next Up - Lesson 11

ALTER TABLE modifies existing tables: ADD COLUMN inserts a new column, DROP COLUMN removes it permanently, MODIFY COLUMN changes its type or constraints, and RENAME COLUMN gives it a new name. Adding NOT NULL columns to tables with existing data requires a DEFAULT value. Normalization reduces redundancy by storing each fact once and using ID references to connect tables. The `author_id` column we added to `books` prepares the database for foreign keys and JOINs.

In Lesson 11, you will learn about **foreign keys and relationships**: how to formally connect tables together and enforce referential integrity at the database level.