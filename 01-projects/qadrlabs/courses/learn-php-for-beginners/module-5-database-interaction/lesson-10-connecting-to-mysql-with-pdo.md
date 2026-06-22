## 1. Before You Begin

Every PHP program you have written so far forgets everything the moment the browser closes. Variables, form data, and all computation exist only for the duration of one request. Databases change this fundamentally: data written to MySQL persists until you explicitly delete it and can be retrieved, searched, and modified at any time. This lesson is the turning point from scripts that "think" to applications that truly "remember."

### Introduction

MySQL is one of the most widely used relational databases in the world, and PHP Data Objects (PDO) is PHP's standard, secure interface for communicating with it. This lesson creates the Catatku database, connects PHP to it, and introduces prepared statements — the mandatory technique for writing queries that involve user-supplied data. Every lesson from here on builds on this foundation.

### What You'll Build

You will create the `db_catatku` database with `users` and `entries` tables, write a shared `config.php` file that establishes the PDO connection, test the connection from a PHP page, and insert your first rows of data.

### What You'll Learn

- ✅ What a relational database is and why it is the right tool for persistent data
- ✅ How to create a database and tables in MySQL using HeidiSQL
- ✅ How to connect PHP to MySQL with PDO
- ✅ Why prepared statements are mandatory and how they work
- ✅ How to insert data safely using PDO

### What You'll Need

- Laragon running with both Apache AND MySQL green
- VS Code open in the `learn-php` folder
- Lessons 1 through 9 completed

---

## 2. Setup

Create a new subfolder called `lesson-10` inside `learn-php`.

---

## 3. Creating the Database and Tables

Before writing any PHP, you need to create the database structure. HeidiSQL (bundled with Laragon) gives you a graphical interface for running SQL commands.

### Step 1: Open HeidiSQL

In Laragon, click the **Database** button to open HeidiSQL. If prompted for connection details, use hostname `127.0.0.1`, user `root`, an empty password, and port `3306`.

### Step 2: Create the Database

In HeidiSQL, open a new query tab and execute the following SQL:

```sql
CREATE DATABASE IF NOT EXISTS db_catatku
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
```

This creates a database named `db_catatku`. The `CHARACTER SET utf8mb4` setting allows the database to store any Unicode character, including emoji and characters from every language. After running, right-click the left panel and select Refresh to see `db_catatku` appear.

### Step 3: Create the Tables

Click `db_catatku` in the left panel to select it, then run:

```sql
USE db_catatku;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

Save the file.

Let us read through each column definition carefully. In the `users` table, `id INT AUTO_INCREMENT PRIMARY KEY` creates a column that starts at 1 and counts up automatically for each new row, serving as a guaranteed unique identifier for every user. `name VARCHAR(255) NOT NULL` creates a text column with a maximum of 255 characters; the `NOT NULL` constraint means a row without a name cannot be inserted. `email VARCHAR(255) NOT NULL UNIQUE` adds the additional constraint that no two rows can share the same email address. `password VARCHAR(255) NOT NULL` stores the hashed password — never the plain text. `created_at DATETIME DEFAULT CURRENT_TIMESTAMP` automatically records when the row was inserted.

In the `entries` table, `user_id INT NOT NULL` is the foreign key column that links each entry to its author. The `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` constraint enforces referential integrity: `user_id` must match a real `id` in the `users` table, and `ON DELETE CASCADE` means that when a user is deleted, all their entries are automatically deleted too.

---

## 4. The PDO Connection: config.php

Rather than putting connection code in every page, you will create a shared `config.php` at the root of `learn-php` that any lesson can include.

### Step 1: Create the File

In the `learn-php` folder (the root, not inside any lesson folder), create a new file called `config.php`.

### Step 2: Write the Code

Open `config.php` and type the following code:

```php
<?php
// Database credentials — in a real project these would come from environment variables
$db_host = "127.0.0.1";
$db_name = "db_catatku";
$db_user = "root";
$db_pass = "";

try {
    $pdo = new PDO(
        "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
        $db_user,
        $db_pass,
        [
            // ERRMODE_EXCEPTION: throw an exception on any database error
            // so problems are visible immediately rather than silently failing
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,

            // FETCH_ASSOC: return rows as associative arrays ($row['title'])
            // rather than indexed arrays ($row[0]) — much more readable
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,

            // Disable emulated prepares to use real prepared statements
            // This maximizes security against SQL injection
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );
} catch (PDOException $e) {
    // If connection fails, stop immediately with a clear error message
    // In production, you would log the error rather than displaying it
    die("Database connection failed: " . $e->getMessage());
}
?>
```

### Step 3: Save the File

Press **Ctrl+S**.

Each option in the PDO configuration array serves a specific purpose. `PDO::ERRMODE_EXCEPTION` means any database error (bad SQL, connection problem, constraint violation) throws a PHP exception rather than just setting an error flag you might forget to check. This makes problems impossible to miss during development. `PDO::FETCH_ASSOC` changes how `fetch()` and `fetchAll()` return data: instead of both numbered indexes (`$row[0]`) and named keys (`$row['title']`) for every column, you get only the named keys, which reduces confusion and makes code clearer. `PDO::ATTR_EMULATE_PREPARES => false` forces PHP to use MySQL's native prepared statement mechanism rather than simulating it in PHP — the native version is more secure and efficient. The `try/catch` block catches any `PDOException` that occurs during connection and stops execution with an informative message, because nothing useful can happen if the database is unreachable.

---

## 5. Prepared Statements: The Security Fundamental

This is the single most important security concept in database programming, and it deserves a dedicated explanation before you write any queries.

Consider this dangerous pattern:

```php
// NEVER DO THIS
$id = $_GET['id'];
$pdo->query("SELECT * FROM entries WHERE id = $id");
// If a user visits: page.php?id=1 OR 1=1
// The query becomes: SELECT * FROM entries WHERE id = 1 OR 1=1
// This returns EVERY row in the table! (SQL Injection)
```

A malicious user can type SQL commands into the URL that become part of your query. This is called **SQL Injection**, and it has compromised databases at companies worldwide.

The fix is prepared statements, which separate the SQL command from the data:

```php
// ALWAYS do this when including user data
$stmt = $pdo->prepare("SELECT * FROM entries WHERE id = :id");
$stmt->execute(['id' => $_GET['id']]);
```

In a prepared statement, the database receives the SQL command first (with `:id` as a placeholder) and separately receives the actual values to fill those placeholders. The database treats the value purely as data — it can never interpret it as SQL syntax. Whatever the user types in the URL, it gets treated as a literal value, not as part of the query structure. The rule is absolute: every query that uses data from any external source (user input, URL parameters, cookies, API responses) must use prepared statements.

---

## 6. Test the Connection

### Step 1: Create the File

In `lesson-10`, create `test-connection.php`.

### Step 2: Write the Code

```php
<?php
require_once __DIR__ . '/../config.php';

echo "<h2>Database Connection Test</h2>";
echo "<p>Connected to <strong>db_catatku</strong> successfully!</p>";

// Query to list all tables in the current database
$stmt   = $pdo->query("SHOW TABLES");
$tables = $stmt->fetchAll();

echo "<p>Tables found: " . count($tables) . "</p><ul>";
foreach ($tables as $table) {
    // Each row has one column; array_values()[0] gets it regardless of column name
    echo "<li>" . array_values($table)[0] . "</li>";
}
echo "</ul>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-10/test-connection.php
```

You should see "Connected to db_catatku successfully!" followed by a list showing `entries` and `users`. If you see an error message instead, check that MySQL is running (green in Laragon) and that the database name in `config.php` matches exactly.

---

## 7. Insert Your First Data

### Step 1: Create the File

In `lesson-10`, create `seed-data.php`.

### Step 2: Write the Code

```php
<?php
require_once __DIR__ . '/../config.php';

// Insert a sample user using a prepared statement
$stmt = $pdo->prepare(
    "INSERT INTO users (name, email, password) VALUES (:name, :email, :password)"
);
$stmt->execute([
    'name'     => 'Budi Santoso',
    'email'    => 'budi@example.com',
    'password' => password_hash('password123', PASSWORD_DEFAULT),
]);

// lastInsertId() returns the auto-generated id of the most recently inserted row
$user_id = $pdo->lastInsertId();
echo "User added with ID: $user_id <br>";

// Insert three sample entries for that user
$entries = [
    ['My first entry',  'This is my very first journal entry!'],
    ['Learning PHP',    'Today I learned about PDO and databases.'],
    ['Weekend plans',   'I want to finish the PHP course this weekend.'],
];

$stmt = $pdo->prepare(
    "INSERT INTO entries (user_id, title, content) VALUES (:user_id, :title, :content)"
);

foreach ($entries as $entry) {
    $stmt->execute([
        'user_id' => $user_id,
        'title'   => $entry[0],
        'content' => $entry[1],
    ]);
    echo "Entry added: {$entry[0]} <br>";
}

echo "<br><strong>All sample data inserted!</strong>";
echo "<br><em>Do not run this file more than once — email must be unique.</em>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-10/seed-data.php
```

Two things in this code deserve special attention. `password_hash('password123', PASSWORD_DEFAULT)` converts the plain password into a secure hash using bcrypt — a one-way function that cannot be reversed. This hashed string (which looks like `$2y$10$...`) is what gets stored in the database, never the original text. If the database is ever stolen, the attacker only gets hashes, not passwords. The `PASSWORD_DEFAULT` constant uses whatever PHP considers the best algorithm at the time of compilation, so hashes automatically upgrade as PHP improves its recommendations. `$pdo->lastInsertId()` retrieves the `AUTO_INCREMENT` ID that MySQL assigned to the just-inserted user row, which you then use as the `user_id` for the entries — linking each journal entry to its author.

---

## 8. Fix the Errors in Your Code

```php
<?php
require_once __DIR__ . '/../config.php';

// Mistake 1: Direct string interpolation — SQL injection vulnerability
$name = $_GET['name'];
$pdo->query("SELECT * FROM users WHERE name = '$name'");

// Mistake 2: Password stored as plain text
$stmt = $pdo->prepare("INSERT INTO users (name, email, password) VALUES (:n, :e, :p)");
$stmt->execute(['n' => 'Siti', 'e' => 'siti@example.com', 'p' => 'secret123']);

// Mistake 3: prepare() result not captured
$pdo->prepare("SELECT * FROM entries WHERE user_id = :id");
$stmt->execute(['id' => 1]);
?>
```

Mistake 1 puts `$_GET['name']` directly inside the SQL string, opening an SQL injection hole. Use a prepared statement: `$stmt = $pdo->prepare("... WHERE name = :name"); $stmt->execute(['name' => $_GET['name']]);`. Mistake 2 stores the password as plain text `'secret123'`. Always hash: `password_hash('secret123', PASSWORD_DEFAULT)`. Mistake 3 calls `prepare()` but discards the returned statement object — it returns a `PDOStatement` that you must store in a variable like `$stmt = $pdo->prepare(...)`, otherwise the `$stmt->execute()` call on the next line either refers to an old statement or produces a "call to member function on null" error.

---

## 9. Exercises

**Exercise 1:** Create `exercise-1.php` in `lesson-10`. Display the count of rows in both the `users` and `entries` tables using `SELECT COUNT(*) AS total FROM table_name`. **Exercise 2:** Insert a new user with your own chosen name, a unique email, and a hashed password. Display the new user's ID. **Exercise 3:** Insert two new entries for `user_id = 1` using a prepared statement in a `foreach` loop.

---

## 10. Understanding Databases and PDO

A relational database organizes data into tables (like spreadsheets), where each row is one record and each column is one attribute of that record. Relationships between tables are expressed through foreign keys: the `user_id` column in `entries` references the `id` column in `users`, creating a link between the two tables. This structure is how virtually all business applications store their data.

PDO is PHP's database-agnostic layer: the same PHP code works with MySQL, PostgreSQL, SQLite, and other databases with only the connection string changed. This abstraction is valuable because it keeps your PHP code from depending on MySQL-specific syntax, making migrations to different databases feasible.

Prepared statements protect against SQL injection by treating user data as data, never as SQL code. This is fundamentally different from string concatenation or interpolation, where there is no way to prevent a clever string from containing SQL syntax. If you take away only one security lesson from this entire course, let it be this: use prepared statements for every query that involves external data.

Password hashing is non-negotiable in any real application. Plain-text passwords in databases are a catastrophic liability: if the database is ever exposed, every user's password is immediately readable. With bcrypt hashing (what `PASSWORD_DEFAULT` uses), an attacker who steals the hash still faces years of computation to crack a single strong password.

---

## 11. Conclusion

MySQL stores data permanently. PDO provides a clean, secure PHP interface for communicating with it. Every query that uses external data must use prepared statements — there are no exceptions. Passwords must be hashed with `password_hash()`. The `config.php` file centralizes the connection and makes it available to every page with a single `require_once`.

**In Lesson 11**, you will query the database and render the results as HTML pages — the listing and detail views for Catatku's journal entries.