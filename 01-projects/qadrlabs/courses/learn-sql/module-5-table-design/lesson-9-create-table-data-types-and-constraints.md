## 1. Before You Begin

So far, we have used tables that were already created. Now it is time to design your own. `CREATE TABLE` defines the table name, column names, data types, and constraints. Choosing the right data type prevents invalid data from being stored. Constraints enforce rules automatically at the database level, which is more reliable than trying to enforce them in application code. Good table design is the foundation of a healthy database.

### What You'll Build

You will create the `orders` table for the bookstore database, learning each data type and constraint along the way. You will also insert sample order rows to prepare for the JOIN lessons.

### What You'll Learn

- ✅ `CREATE TABLE` syntax
- ✅ Numeric types: INT, BIGINT, DECIMAL, FLOAT
- ✅ String types: VARCHAR, CHAR, TEXT, ENUM
- ✅ Date types: DATE, DATETIME, TIMESTAMP
- ✅ Constraints: NOT NULL, UNIQUE, DEFAULT, CHECK, PRIMARY KEY
- ✅ AUTO_INCREMENT for primary keys
- ✅ `DROP TABLE` to delete a table

### What You'll Need

- The `bookstore` database

---

## 2. Setup

Connect to MySQL and select the bookstore database before running any statements in this lesson.

```sql
mysql -u root -p
USE bookstore;
```

Once you see `Database changed`, you are ready to create tables in the `bookstore` database.

---

## 3. Data Types

Every column in a table must have a data type. The data type tells MySQL what kind of values the column can hold, how much storage to allocate, and what operations can be performed on it. Choosing the correct data type for each column is one of the most important decisions in table design.

### Numeric Types

Use numeric types for counts, IDs, money, and any value you need to perform arithmetic on.

| Type | Size | Range | Use Case |
|------|------|-------|----------|
| `INT` | 4 bytes | -2.1B to 2.1B | IDs, counts, years |
| `BIGINT` | 8 bytes | Very large | Large IDs, timestamps |
| `DECIMAL(p,s)` | Variable | Exact | Money (DECIMAL(10,2)) |
| `FLOAT` | 4 bytes | Approximate | Scientific calculations |
| `BOOLEAN` | 1 byte | 0 or 1 | True/false flags |

**Always use DECIMAL for money.** FLOAT uses binary floating-point arithmetic which introduces rounding errors. For example, `0.1 + 0.2` in a FLOAT column may not equal exactly `0.3`. `DECIMAL(10,2)` stores up to 99,999,999.99 with complete precision, making it the safe choice for any monetary value.

### String Types

Use string types for text data such as names, titles, descriptions, and status labels.

| Type | Max Length | Use Case |
|------|-----------|----------|
| `VARCHAR(n)` | Up to n chars | Names, emails, titles |
| `CHAR(n)` | Exactly n chars | Fixed-length codes (ISO country codes) |
| `TEXT` | 65,535 chars | Long content, descriptions |
| `ENUM('a','b','c')` | One of the values | Status fields with a fixed set of options |

**Use VARCHAR for most strings.** VARCHAR stores only as many bytes as the actual content requires, making it more storage-efficient than CHAR for variable-length text. Use TEXT for content that may be longer than 255 characters, like product descriptions or comments. Use ENUM when a column should only ever hold one of a predefined set of values.

### Date and Time Types

Use date and time types for anything time-related. Do not store dates as plain VARCHAR; date-specific types enable date arithmetic and proper sorting.

| Type | Format | Use Case |
|------|--------|----------|
| `DATE` | YYYY-MM-DD | Birth dates, due dates, order dates |
| `DATETIME` | YYYY-MM-DD HH:MM:SS | Event timestamps without timezone |
| `TIMESTAMP` | Auto-converts to UTC | Created/updated times, tracks timezone |

TIMESTAMP automatically converts values to UTC when storing and back to the server's local time when retrieving. This makes TIMESTAMP the better choice for `created_at` and `updated_at` columns that need to remain consistent across servers in different timezones.

---

## 4. Create the Orders Table

The `orders` table connects customers to books and records the details of each purchase. It uses several different data types and constraints to reflect real business rules.

```sql
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    book_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    total_price DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') NOT NULL DEFAULT 'pending',
    order_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

```sql
DESCRIBE orders;
```

`id INT AUTO_INCREMENT PRIMARY KEY` creates an auto-generated unique identifier for each order. `customer_id` and `book_id` are INT columns that will later be connected to the `customers` and `books` tables via foreign keys - they are NOT NULL because every order must belong to a customer and reference a book. `quantity INT NOT NULL DEFAULT 1` means "how many copies were ordered" and defaults to 1 if not specified. `DECIMAL(10,2)` stores the total price exactly. `ENUM` restricts `status` to five valid values and defaults to `'pending'`. `notes TEXT` is nullable because notes are optional. `ON UPDATE CURRENT_TIMESTAMP` on `updated_at` automatically sets the timestamp to the current time whenever the row is modified.

### Constraint Breakdown

Each constraint in the `orders` table serves a specific purpose that prevents invalid data from entering the database.

`PRIMARY KEY` uniquely identifies each row. Only one primary key per table is allowed, and it cannot be NULL. `NOT NULL` prevents a column from being left empty. `DEFAULT` provides a fallback value when the column is omitted from an INSERT. `ENUM` restricts the column to a predefined set of valid values; any other value causes an error. `ON UPDATE CURRENT_TIMESTAMP` is a special MySQL feature that automatically updates the timestamp column whenever any other column in the row is modified.

---

## 5. More Constraint Examples

To see all constraints working, this section creates a practice `products` table that demonstrates UNIQUE and CHECK constraints before cleaning it up.

```sql
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    price DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    weight_kg DECIMAL(5,2),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (price > 0),
    CHECK (stock >= 0)
);
```

```sql
INSERT INTO products (name, sku, price, stock) VALUES ('Widget', 'WDG-001', 10.00, 50);
```

```sql
DROP TABLE products;
```

`UNIQUE` on `sku` means no two products can have the same stock-keeping unit code. Unlike PRIMARY KEY, a UNIQUE column can contain NULL (multiple rows can have NULL in a UNIQUE column). `CHECK (price > 0)` is a constraint that MySQL evaluates on every INSERT and UPDATE - if the condition is false, the operation is rejected. `CHECK (stock >= 0)` prevents negative stock values entirely. The `DROP TABLE products` at the end removes the practice table; we do not need it for the rest of the course.

---

## 6. Insert Sample Orders

With the `orders` table created, we can add sample data to use in lessons 11 and 12 when joining tables together.

```sql
INSERT INTO orders (customer_id, book_id, quantity, total_price, status, order_date) VALUES
(1, 1, 2, 90.00, 'delivered', '2026-01-15'),
(1, 3, 1, 55.00, 'delivered', '2026-02-10'),
(2, 2, 1, 50.00, 'shipped', '2026-03-05'),
(2, 5, 1, 80.00, 'processing', '2026-03-20'),
(3, 4, 3, 180.00, 'delivered', '2026-01-28'),
(3, 1, 1, 45.00, 'delivered', '2026-02-14'),
(4, 6, 2, 150.00, 'pending', '2026-04-01'),
(4, 9, 1, 20.00, 'shipped', '2026-03-25'),
(5, 10, 1, 18.00, 'delivered', '2026-02-28'),
(5, 11, 2, 44.00, 'processing', '2026-03-30'),
(1, 7, 1, 70.00, 'pending', '2026-04-05'),
(3, 12, 1, 25.00, 'shipped', '2026-03-18');
```

```sql
SELECT * FROM orders;
```

The `customer_id` values (1-5) reference the five customers from the `customers` table. The `book_id` values reference books in the `books` table. The `status` values match exactly the options defined in the ENUM constraint. Notice that `notes` and `created_at` are omitted because `notes` defaults to NULL and `created_at` defaults to the current timestamp. Running `SELECT * FROM orders` confirms all 12 rows were inserted.

---

## 7. DROP TABLE

DROP TABLE permanently removes the table and all its data from the database. This operation cannot be undone.

```sql
-- DROP TABLE tablename;
-- DROP TABLE IF EXISTS tablename;
```

`DROP TABLE` returns an error if the table does not exist. Adding `IF EXISTS` suppresses that error and makes the command safe to run in scripts that might be executed multiple times. You will use `DROP TABLE IF EXISTS` frequently in the exercises throughout this course.

---

## 8. Fix the Errors in Your Code

These three errors are the most common mistakes when creating tables.

**Error 1: Defining two PRIMARY KEYs.**

Each table can have exactly one primary key. Using PRIMARY KEY on more than one column causes an error.

```sql
-- Wrong: two PRIMARY KEY declarations
CREATE TABLE test (
    id INT PRIMARY KEY,
    code VARCHAR(10) PRIMARY KEY
);

-- Correct: use UNIQUE for the second column
CREATE TABLE test (
    id INT PRIMARY KEY,
    code VARCHAR(10) UNIQUE
);
```

MySQL returns `ERROR 1068: Multiple primary key defined`. A table can only have one primary key, which identifies each row uniquely. If another column also needs to have unique values, use `UNIQUE` instead of `PRIMARY KEY`.

**Error 2: VARCHAR without a length.**

VARCHAR requires a maximum length in parentheses. Without it, MySQL returns a syntax error.

```sql
-- Wrong: no length specified
CREATE TABLE test (
    name VARCHAR
);

-- Correct: always specify a length
CREATE TABLE test (
    name VARCHAR(255)
);
```

`VARCHAR(255)` is the most common choice for general-purpose text columns because 255 is the maximum length for an index on this type. For longer text, use TEXT. For shorter fixed-length strings (like a 2-character country code), use `CHAR(2)`.

**Error 3: Inserting an invalid ENUM value.**

ENUM columns only accept values that were listed when the column was defined. Any other value causes the INSERT to fail.

```sql
-- Wrong: 'completed' is not in the ENUM list
INSERT INTO orders (customer_id, book_id, quantity, total_price, status, order_date)
VALUES (1, 1, 1, 45.00, 'completed', '2026-04-01');

-- Correct: use a valid ENUM value
INSERT INTO orders (customer_id, book_id, quantity, total_price, status, order_date)
VALUES (1, 1, 1, 45.00, 'delivered', '2026-04-01');
```

The error message is `ERROR 1265: Data truncated for column 'status'`. The valid values for `status` are: `'pending'`, `'processing'`, `'shipped'`, `'delivered'`, and `'cancelled'`. Any variation in spelling or any value not in this list will be rejected.

---

## 9. Exercises

**Exercise 1:** Create a `reviews` table with: id (INT AUTO_INCREMENT PK), book_id (INT NOT NULL), customer_id (INT NOT NULL), rating (INT NOT NULL, CHECK 1-5), comment (TEXT), created_at (TIMESTAMP DEFAULT CURRENT_TIMESTAMP). Insert 3 sample reviews.

**Exercise 2:** Create an `employees` table with: id, name (NOT NULL), email (NOT NULL UNIQUE), department (ENUM: 'sales', 'engineering', 'marketing', 'hr'), salary (DECIMAL(10,2), CHECK > 0), hire_date (DATE NOT NULL). Insert 3 employees.

**Exercise 3:** Run `DESCRIBE orders;` and `DESCRIBE books;`. Compare the data types used. Note which columns use NOT NULL, DEFAULT, and UNIQUE.

---

## 10. Solutions

**Solution for Exercise 1:**

Create the `reviews` table with a CHECK constraint on `rating`, then insert three sample rows.

```sql
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    customer_id INT NOT NULL,
    rating INT NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (rating BETWEEN 1 AND 5)
);

INSERT INTO reviews (book_id, customer_id, rating, comment) VALUES
(1, 1, 5, 'Excellent book on clean coding practices.'),
(2, 2, 4, 'Very practical and well-written.'),
(5, 3, 5, 'The definitive algorithms textbook.');
```

`CHECK (rating BETWEEN 1 AND 5)` means any INSERT or UPDATE that tries to set `rating` to 0, 6, or any value outside the 1-5 range will be rejected by MySQL. The three inserted reviews reference books with IDs 1, 2, and 5 and customers with IDs 1, 2, and 3, all of which exist in the database.

**Solution for Exercise 2:**

Create the `employees` table with an ENUM for department and a CHECK on salary.

```sql
CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department ENUM('sales', 'engineering', 'marketing', 'hr'),
    salary DECIMAL(10,2),
    hire_date DATE NOT NULL,
    CHECK (salary > 0)
);

INSERT INTO employees (name, email, department, salary, hire_date) VALUES
('Andi', 'andi@company.com', 'engineering', 15000000, '2024-01-15'),
('Budi', 'budi@company.com', 'sales', 12000000, '2024-03-01'),
('Citra', 'citra@company.com', 'marketing', 13000000, '2024-06-10');
```

`department ENUM(...)` without `NOT NULL` means the column can also be NULL, which is useful if an employee has not yet been assigned to a department. `CHECK (salary > 0)` prevents zero or negative salaries. The salary values are stored as full integers in Indonesian Rupiah (IDR).

**Solution for Exercise 3:**

Run DESCRIBE on both tables and observe the structure.

```sql
DESCRIBE orders;
DESCRIBE books;
```

`DESCRIBE` returns one row per column showing: the column name, the data type, whether NULL is allowed, the key type (PRI for primary key, UNI for unique), the default value, and extra attributes like `auto_increment`. Comparing the two tables, `orders` uses `DECIMAL(10,2)`, `ENUM`, `DATE`, and `TIMESTAMP`, while `books` uses `INT`, `VARCHAR`, `DECIMAL`, and `TIMESTAMP`. Both tables have an `id` column as PRIMARY KEY with AUTO_INCREMENT, and `created_at` as TIMESTAMP with a DEFAULT.

---

## Next Up - Lesson 10

CREATE TABLE defines structure with column names, data types, and constraints. Use INT for whole numbers, DECIMAL for money, VARCHAR for text, TEXT for long content, and DATE or TIMESTAMP for dates. Constraints enforce data integrity: NOT NULL requires a value, UNIQUE prevents duplicates, DEFAULT provides fallback values, CHECK validates against a condition, and PRIMARY KEY uniquely identifies each row. DROP TABLE removes a table permanently.

In Lesson 10, you will learn **ALTER TABLE**: how to modify existing tables by adding, dropping, and renaming columns, and you will get an introduction to database normalization.