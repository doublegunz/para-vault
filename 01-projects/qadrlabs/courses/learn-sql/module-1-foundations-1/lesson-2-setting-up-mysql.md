## 1. Before You Begin

To write SQL, you need a database server running on your computer and a client to connect to it. This lesson installs MySQL, teaches you how to connect via the command line, and creates the bookstore database that you will use throughout the course.

### What You'll Build

You will install MySQL, connect to it using the command-line client, create the `bookstore` database, and populate it with a `books` table containing 15 sample rows. This is the foundation every later lesson depends on.

### What You'll Learn

- ✅ How to install MySQL (via Laragon on Windows, or standalone)
- ✅ How to connect to MySQL from the command line
- ✅ How to create and select a database
- ✅ Basic MySQL commands: SHOW DATABASES, USE, SHOW TABLES
- ✅ How to exit the MySQL client

### What You'll Need

- A computer running Windows, macOS, or Linux
- An internet connection for downloading software

---

## 2. Install MySQL

MySQL must be installed and running before you can write any SQL. Choose the option that matches your operating system. Once installed, MySQL runs as a background service that listens for connections on port 3306.

### Option A: Windows (Laragon - Recommended)

If you already have Laragon installed from a previous course, MySQL is included. Click **Start All** in Laragon. MySQL is ready.

If not, download Laragon from [laragon.org](https://laragon.org/) and install it. It includes MySQL, Apache, and PHP in one package, which makes it the easiest option for Windows users who plan to write PHP later.

### Option B: Windows (Standalone)

Download MySQL Community Server from [dev.mysql.com/downloads](https://dev.mysql.com/downloads/). Run the installer, choose "Developer Default", and set a root password (or leave it empty for local development).

### Option C: macOS

Run the following commands in your terminal. `brew install mysql` downloads and installs MySQL, while `brew services start mysql` starts it as a background service that launches automatically at login.

```bash
brew install mysql
brew services start mysql
```

### Option D: Linux (Ubuntu/Debian)

Run the following commands. `apt install mysql-server` installs MySQL from the official Ubuntu package repository, and `systemctl start mysql` starts the service immediately.

```bash
sudo apt update
sudo apt install mysql-server
sudo systemctl start mysql
```

---

## 3. Connect to MySQL

With MySQL installed and running, the next step is connecting to it using the MySQL command-line client. This client lets you type SQL statements directly and see results immediately.

### Step 1: Open a Terminal

**Windows (Laragon):** Click the **Terminal** button in Laragon. Or open Command Prompt and navigate to Laragon's MySQL bin directory.

**macOS/Linux:** Open Terminal.

### Step 2: Connect

Run this command to connect as the root user. The `-u root` flag specifies the username, and `-p` tells the client to prompt you for a password.

```bash
mysql -u root -p
```

Enter your password (leave empty if none set). You should see the MySQL prompt:

```
mysql>
```

This prompt means you are now connected to the MySQL server. Every SQL statement you type here is sent to the MySQL server for execution.

### Step 3: Test with a Simple Command

Run a quick test to confirm the connection is working. `NOW()` is a MySQL function that returns the current date and time.

```sql
SELECT NOW();
```

You should see the current date and time in the output. This confirms MySQL is working correctly and ready to accept queries.

---

## 4. Create the Bookstore Database

A MySQL server can host many databases at once. Each database is an isolated container for its own tables and data. We will create a dedicated database for this course so our tables do not mix with anything else on the server.

### Step 1: Show Existing Databases

Before creating anything, take a look at what already exists on the server.

```sql
SHOW DATABASES;
```

You will see system databases like `information_schema`, `mysql`, and `performance_schema`. These are used by MySQL internally. Do not modify them.

### Step 2: Create the Database

Create the `bookstore` database with UTF-8 character support. The `CHARACTER SET utf8mb4` and `COLLATE utf8mb4_unicode_ci` settings ensure that the database correctly handles international characters, including emoji.

```sql
CREATE DATABASE bookstore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Step 3: Verify

Run `SHOW DATABASES` again to confirm the new database appears in the list.

```sql
SHOW DATABASES;
```

`bookstore` should now appear in the list alongside the system databases.

### Step 4: Select the Database

Before you can create tables or run queries, you must tell MySQL which database to use. `USE` switches the active database for all subsequent statements.

```sql
USE bookstore;
```

You will see the output `Database changed`. From now on, all SQL statements run against the `bookstore` database until you switch to another or end the session.

### Step 5: Check for Tables

Confirm the database is empty at this point.

```sql
SHOW TABLES;
```

The output will be `Empty set` because we have not created any tables yet. We will create tables in later lessons.

---

## 5. Create and Populate the Books Table

For the next few lessons (3 through 6), you will write SELECT and filtering queries that need real data to work against. We will create the `books` table now and insert 15 sample rows so these lessons have something meaningful to query.

### Step 1: Create the Table

The following statement creates the `books` table with columns for the book's ID, title, author, price, stock quantity, category, publication year, and a timestamp for when the record was created.

```sql
CREATE TABLE books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    category VARCHAR(100),
    published_year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

`AUTO_INCREMENT PRIMARY KEY` means MySQL automatically generates a unique integer ID for each row. `DECIMAL(10,2)` stores the price exactly with two decimal places, which is the correct type for money. `DEFAULT 0` means stock defaults to zero if not specified. We will explore all of these data types and constraints in detail in Lesson 9.

### Step 2: Insert Sample Data

Insert 15 books covering several categories. All of these books will appear in query results throughout lessons 3 to 8.

```sql
INSERT INTO books (title, author, price, stock, category, published_year) VALUES
('Clean Code', 'Robert C. Martin', 45.00, 25, 'Programming', 2008),
('The Pragmatic Programmer', 'David Thomas', 50.00, 18, 'Programming', 2019),
('Refactoring', 'Martin Fowler', 55.00, 12, 'Programming', 2018),
('Design Patterns', 'Gang of Four', 60.00, 8, 'Programming', 1994),
('Introduction to Algorithms', 'Thomas H. Cormen', 80.00, 15, 'Computer Science', 2009),
('Database System Concepts', 'Abraham Silberschatz', 75.00, 10, 'Computer Science', 2019),
('Artificial Intelligence', 'Stuart Russell', 70.00, 7, 'Computer Science', 2020),
('The Art of War', 'Sun Tzu', 12.00, 50, 'Philosophy', -500),
('Sapiens', 'Yuval Noah Harari', 20.00, 35, 'History', 2014),
('Atomic Habits', 'James Clear', 18.00, 40, 'Self-Help', 2018),
('Deep Work', 'Cal Newport', 22.00, 30, 'Self-Help', 2016),
('Thinking, Fast and Slow', 'Daniel Kahneman', 25.00, 20, 'Psychology', 2011),
('The Lean Startup', 'Eric Ries', 28.00, 22, 'Business', 2011),
('Zero to One', 'Peter Thiel', 24.00, 28, 'Business', 2014),
('Steve Jobs', 'Walter Isaacson', 30.00, 15, 'Biography', 2011);
```

Note that "The Art of War" has `published_year = -500` to represent approximately 500 BC. This is valid because `published_year` is stored as a plain INT with no constraint preventing negative values.

### Step 3: Verify

Confirm all 15 rows were inserted successfully.

```sql
SELECT * FROM books;
```

You should see 15 rows of book data. The `id` column will be automatically filled with values 1 through 15.

---

## 6. Essential MySQL Commands

These are the commands you will use most often while working in the MySQL client. Keep them handy for reference throughout the course.

| Command | Purpose |
|---------|---------|
| `SHOW DATABASES;` | List all databases |
| `CREATE DATABASE name;` | Create a new database |
| `DROP DATABASE name;` | Delete a database (careful!) |
| `USE name;` | Switch to a database |
| `SHOW TABLES;` | List all tables in the current database |
| `DESCRIBE tablename;` | Show table structure (columns, types) |
| `SELECT * FROM tablename;` | Show all data in a table |
| `EXIT;` or `\q` | Quit the MySQL client |

`DESCRIBE` is especially useful when you forget what columns a table has or what data types they use. You will use it frequently in upcoming lessons.

---

## 7. Fix the Errors in Your Code

This section covers the three most common errors beginners encounter when first connecting to MySQL and running their first queries.

**Error 1: Missing semicolon.**

Every SQL statement must end with a semicolon. Without it, MySQL waits for more input and nothing happens.

```sql
-- Wrong: no semicolon
SELECT NOW()

-- Correct: statement ends with ;
SELECT NOW();
```

When you press Enter after a statement without a semicolon, the prompt changes to `->` which means MySQL is waiting for more. Type `;` and press Enter to execute it, or type `\c` to cancel.

**Error 2: No database selected.**

You must run `USE bookstore;` before querying any tables. If you skip this step, MySQL does not know which database to look in.

```sql
-- Wrong: query runs without selecting a database first
SELECT * FROM books;

-- Correct: select the database first
USE bookstore;
SELECT * FROM books;
```

The error message is `ERROR 1046: No database selected`. Running `USE bookstore;` fixes it immediately.

**Error 3: Case sensitivity in table names.**

On Linux, MySQL table names are case-sensitive. On Windows, they are not. Writing `Books` instead of `books` will fail on Linux but work on Windows, which creates inconsistencies when you deploy code to a Linux server.

```sql
-- Wrong (on Linux): uppercase B
SELECT * FROM Books;

-- Correct: always use lowercase
SELECT * FROM books;
```

The safest habit is to always use lowercase for table names and database names regardless of your operating system. This eliminates an entire category of bugs when moving between environments.

---

## 8. Exercises

**Exercise 1:** Connect to MySQL, run `SHOW DATABASES;`, then `SELECT VERSION();` to check your MySQL version. Write down the version number.

**Exercise 2:** Create a second database called `testdb`. Switch to it with `USE testdb;`. Verify with `SELECT DATABASE();` (shows the current database). Then drop it with `DROP DATABASE testdb;`.

**Exercise 3:** Switch back to `bookstore`. Run `DESCRIBE books;` to see the table structure. Identify the data type of each column.

---

## 9. Solutions

**Solution for Exercise 1:**

Run both commands in sequence inside the MySQL client.

```sql
SHOW DATABASES;
SELECT VERSION();
```

`SELECT VERSION()` asks MySQL to return its own version number. The output will look something like `8.0.36` or `10.11.6-MariaDB` depending on which database engine you installed. This is a quick way to confirm which version you are running.

**Solution for Exercise 2:**

Run the following commands in order.

```sql
CREATE DATABASE testdb;
USE testdb;
SELECT DATABASE();
DROP DATABASE testdb;
SHOW DATABASES;
```

`SELECT DATABASE()` returns the name of the currently active database, which should output `testdb`. After running `DROP DATABASE testdb`, running `SHOW DATABASES` again confirms the database is gone. This exercise demonstrates the full lifecycle of a database: create, use, and delete.

**Solution for Exercise 3:**

Switch to the correct database first, then run DESCRIBE.

```sql
USE bookstore;
DESCRIBE books;
```

`DESCRIBE books` outputs one row per column, showing the column name, data type, whether it allows NULL, its key type (PRI for primary key), its default value, and any extra behavior (like `auto_increment`). The output confirms: `id` (int), `title` (varchar(255)), `author` (varchar(255)), `price` (decimal(10,2)), `stock` (int), `category` (varchar(100)), `published_year` (int), and `created_at` (timestamp).

---

## Next Up - Lesson 3

MySQL is installed and running. You connect with `mysql -u root -p`, then select your database with `USE bookstore`. The `bookstore` database now has a `books` table with 15 sample rows ready to query. Every SQL statement must end with a semicolon, and table names on Linux are case-sensitive.

In Lesson 3, you will learn **SELECT**: the most important SQL statement, used to retrieve data from tables in every application and every framework.