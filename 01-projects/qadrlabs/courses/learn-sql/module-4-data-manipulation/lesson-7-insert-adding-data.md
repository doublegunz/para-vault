## 1. Before You Begin

So far, we have only read data. Now it is time to write it. **INSERT** adds new rows to a table. Every form submission on every website (registration, checkout, posting a comment) translates to an INSERT statement behind the scenes. This lesson covers single-row inserts, multi-row inserts, default values, and auto-increment IDs. We will also create two new tables, `authors` and `customers`, which will be needed for the JOIN and relationship lessons later in the course.

### What You'll Build

You will add new books to the `books` table, create the `authors` and `customers` tables, and populate them with sample data. You will also understand how auto-increment IDs are generated and how to retrieve them.

### What You'll Learn

- ✅ `INSERT INTO ... VALUES` for single rows
- ✅ Inserting multiple rows in one statement
- ✅ Specifying columns vs omitting them
- ✅ `DEFAULT` values and `AUTO_INCREMENT`
- ✅ `INSERT INTO ... SELECT` (insert from a query)
- ✅ `LAST_INSERT_ID()` to get the generated ID

### What You'll Need

- The `bookstore` database with the `books` table

---

## 2. Setup

Connect to MySQL and select the bookstore database before running any statements in this lesson.

```sql
mysql -u root -p
USE bookstore;
```

Once you see `Database changed`, you are ready to write INSERT statements against the `bookstore` database.

---

## 3. Single Row INSERT

The most common form of INSERT adds one row at a time and explicitly lists the column names. This is the recommended style because it makes the statement self-documenting and resilient to future changes in the table structure.

```sql
INSERT INTO books (title, author, price, stock, category, published_year)
VALUES ('Eloquent JavaScript', 'Marijn Haverbeke', 35.00, 20, 'Programming', 2018);
```

```sql
SELECT * FROM books WHERE title = 'Eloquent JavaScript';
```

The first argument to INSERT INTO is the table name. The column list in parentheses specifies which columns you are providing values for. VALUES then provides the actual data in the same order. The `id` column is omitted because it is AUTO_INCREMENT and MySQL generates it automatically. The `created_at` column is also omitted because it has a `DEFAULT CURRENT_TIMESTAMP` that fills in automatically.

Avoid the version that omits column names entirely:

```sql
-- Not recommended: must match every column in exact table order
-- INSERT INTO books VALUES (NULL, 'Title', 'Author', 35.00, 20, 'Cat', 2020, NOW());
```

This version breaks silently if columns are added or reordered in the table later. Always list column names explicitly.

---

## 4. Multiple Row INSERT

You can insert several rows in a single INSERT statement by separating each set of values with a comma. This is significantly faster than running a separate INSERT for each row.

```sql
INSERT INTO books (title, author, price, stock, category, published_year) VALUES
('You Don''t Know JS', 'Kyle Simpson', 30.00, 25, 'Programming', 2015),
('Head First Java', 'Kathy Sierra', 42.00, 18, 'Programming', 2005),
('Learning Python', 'Mark Lutz', 55.00, 12, 'Programming', 2013);
```

```sql
SELECT title, author, price FROM books ORDER BY id DESC LIMIT 4;
```

Each row is enclosed in its own set of parentheses and separated from the next by a comma. The entire statement ends with a single semicolon. Notice `Don''t` (two single quotes inside a single-quoted string) - in SQL, you escape a single quote by doubling it. The verification query uses `ORDER BY id DESC LIMIT 4` to show the most recently inserted rows first.

---

## 5. DEFAULT and AUTO_INCREMENT

Some columns have default values defined at the table level. When you omit those columns from an INSERT, MySQL fills them in automatically.

```sql
INSERT INTO books (title, author, price, category, published_year)
VALUES ('Minimalism', 'Joshua Fields Millburn', 15.00, 'Self-Help', 2011);
```

```sql
SELECT LAST_INSERT_ID();
```

```sql
SELECT id, title, stock, created_at FROM books WHERE title = 'Minimalism';
```

In the `books` table, `stock` has `DEFAULT 0`, `created_at` has `DEFAULT CURRENT_TIMESTAMP`, and `id` is `AUTO_INCREMENT`. All three were omitted from the INSERT above. MySQL fills `stock` with `0`, `created_at` with the current timestamp, and `id` with the next available integer. `LAST_INSERT_ID()` returns the auto-generated ID from the most recent INSERT statement in your current session. This is useful when you need to immediately use the new row's ID in a follow-up INSERT (for example, creating a related record in another table).

---

## 6. Create the Authors Table

The `authors` table stores information about book authors separately from the `books` table. This is the first step toward a properly normalized database, where each piece of information is stored in exactly one place. We will link authors to books using a foreign key in Lesson 11.

```sql
CREATE TABLE authors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100),
    birth_year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

```sql
INSERT INTO authors (name, country, birth_year) VALUES
('Robert C. Martin', 'United States', 1952),
('Martin Fowler', 'United Kingdom', 1963),
('James Clear', 'United States', 1986),
('Yuval Noah Harari', 'Israel', 1976),
('Cal Newport', 'United States', 1982),
('Eric Ries', 'United States', 1978);
```

```sql
SELECT * FROM authors;
```

The `authors` table structure is intentionally simple: an auto-increment ID, a required name, and optional fields for country and birth year. The multi-row INSERT adds six authors in a single statement. These are the six authors whose names match books already in the `books` table, which we will use in Lesson 10 to set up the `author_id` link.

---

## 7. Create the Customers Table

The `customers` table will be used in Lesson 9 to create sample orders. The `email` column has a `UNIQUE` constraint, which means no two customers can share the same email address.

```sql
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    city VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

```sql
INSERT INTO customers (name, email, city) VALUES
('Andi Pratama', 'andi@example.com', 'Jakarta'),
('Budi Santoso', 'budi@example.com', 'Bandung'),
('Citra Dewi', 'citra@example.com', 'Surabaya'),
('Dewi Lestari', 'dewi@example.com', 'Jakarta'),
('Eka Wahyuni', 'eka@example.com', 'Yogyakarta');
```

```sql
SELECT * FROM customers;
```

`NOT NULL UNIQUE` on the `email` column means every customer must have an email address and that email must be unique across the entire table. If you try to insert a second row with an email that already exists, MySQL rejects the INSERT with a duplicate key error. This prevents data integrity problems like two customer accounts sharing the same login email.

---

## 8. Fix the Errors in Your Code

These three errors are the most common mistakes when writing INSERT statements.

**Error 1: Column count mismatch.**

The number of column names listed must exactly match the number of values provided.

```sql
-- Wrong: 3 columns listed but 4 values provided
INSERT INTO books (title, author, price)
VALUES ('Test Book', 'Author', 25.00, 10);

-- Correct: column count matches value count
INSERT INTO books (title, author, price, stock)
VALUES ('Test Book', 'Author', 25.00, 10);
```

MySQL returns `ERROR 1136: Column count doesn't match value count at row 1`. Count the columns, count the values, and make sure they match. Adding `stock` to the column list fixes the mismatch in this example.

**Error 2: Duplicate unique value.**

Inserting a value that already exists in a UNIQUE column causes the INSERT to fail. The existing data is not modified.

```sql
-- Wrong: andi@example.com is already in the customers table
INSERT INTO customers (name, email, city)
VALUES ('Test User', 'andi@example.com', 'Jakarta');

-- Correct: use a unique email address
INSERT INTO customers (name, email, city)
VALUES ('Test User', 'newuser@example.com', 'Jakarta');
```

The error message is `ERROR 1062: Duplicate entry 'andi@example.com' for key 'customers.email'`. The UNIQUE constraint on `email` is working as designed. Use a different email address that does not yet exist in the table.

**Error 3: NOT NULL violation.**

Inserting a row without providing a value for a NOT NULL column that has no DEFAULT causes the INSERT to fail.

```sql
-- Wrong: "author" is NOT NULL but no value is provided
INSERT INTO books (title, price, stock, category)
VALUES ('No Author', 30.00, 5, 'Test');

-- Correct: always include all required NOT NULL columns
INSERT INTO books (title, author, price, stock, category)
VALUES ('No Author', 'Unknown', 30.00, 5, 'Test');
```

`author` is defined as `NOT NULL` and has no DEFAULT value, so MySQL requires a value every time you insert a row. The error message is `ERROR 1364: Field 'author' doesn't have a default value`. Either provide a value for the column or change the column definition to allow NULL or have a DEFAULT.

---

## 9. Exercises

**Exercise 1:** Insert 3 new books into the books table in a single INSERT statement. Choose any titles, authors, and prices.

**Exercise 2:** Insert 3 new customers. Verify with `SELECT * FROM customers ORDER BY id DESC LIMIT 3;`.

**Exercise 3:** Create a table called `categories` with columns: `id` (INT AUTO_INCREMENT PRIMARY KEY), `name` (VARCHAR(100) NOT NULL UNIQUE), `description` (TEXT). Insert 5 categories that match the ones used in the books table.

---

## 10. Solutions

**Solution for Exercise 1:**

Insert three books in a single multi-row INSERT statement.

```sql
INSERT INTO books (title, author, price, stock, category, published_year) VALUES
('Cracking the Coding Interview', 'Gayle McDowell', 40.00, 15, 'Programming', 2015),
('Educated', 'Tara Westover', 18.00, 30, 'Biography', 2018),
('Dune', 'Frank Herbert', 15.00, 25, 'Fiction', 1965);
```

Each set of values is enclosed in parentheses and separated by a comma. The `id` and `created_at` columns are omitted because they fill in automatically through AUTO_INCREMENT and DEFAULT CURRENT_TIMESTAMP respectively. After inserting, run `SELECT * FROM books ORDER BY id DESC LIMIT 3;` to confirm the three new rows appear at the top of the result.

**Solution for Exercise 2:**

Insert three new customers and verify the result.

```sql
INSERT INTO customers (name, email, city) VALUES
('Fani Rahayu', 'fani@example.com', 'Medan'),
('Gilang Putra', 'gilang@example.com', 'Semarang'),
('Hana Safitri', 'hana@example.com', 'Malang');
```

The emails must be unique. Using `@example.com` addresses keeps them clearly fake and avoids conflicts with the five original customers. Running `SELECT * FROM customers ORDER BY id DESC LIMIT 3` after the INSERT returns Hana, Gilang, and Fani (in that reverse order) confirming all three rows were saved.

**Solution for Exercise 3:**

First create the `categories` table, then insert five category rows.

```sql
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

INSERT INTO categories (name, description) VALUES
('Programming', 'Books about software development and coding'),
('Computer Science', 'Academic computer science topics'),
('Business', 'Entrepreneurship, management, and strategy'),
('Self-Help', 'Personal development and productivity'),
('Biography', 'Life stories of notable people');
```

`VARCHAR(100) NOT NULL UNIQUE` on `name` ensures every category has a name and no two categories can share the same name. `TEXT` for `description` allows long descriptions without a character limit. The five category names match the categories used in the `books` table, which sets the stage for joining these tables in a future lesson.

---

## Next Up - Lesson 8

INSERT adds rows to tables. Always specify column names explicitly for clarity and resilience. Multi-row INSERT is more efficient than running separate statements for each row. AUTO_INCREMENT generates IDs automatically. DEFAULT values fill in when a column is omitted. `LAST_INSERT_ID()` returns the ID generated by the most recent INSERT. Constraints (NOT NULL, UNIQUE) are enforced on every INSERT attempt.

In Lesson 8, you will learn **UPDATE and DELETE**: how to change existing data and remove rows, including the safety practices that prevent accidental data loss.