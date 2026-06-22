## 1. Before You Begin

In the previous lessons, you worked with HTML forms and organized code with includes. But so far, all data disappears the moment a script finishes running. Text files can save data, but imagine searching for one specific record among thousands of lines, or ensuring that two users do not write to the same file at the same time. Text files are not designed for those problems.

This is where **databases** come in. A database is a system designed specifically to store, retrieve, and manage large amounts of data efficiently and safely. **MySQL** (running as MariaDB in Termux) is one of the most popular databases in the world, and PHP communicates with it through **PDO** (PHP Data Objects).

This lesson is a turning point: from programs that forget everything when the browser is closed, to programs that store data permanently and can search, modify, or delete it at any time.

### What You'll Build

You will create a database called `db_catatku`, create the `users` and `entries` tables, connect PHP to MySQL using PDO, and insert your first data into the database.

### What You'll Learn

- ✅ What a relational database is and why it is needed
- ✅ How to create a database and tables in MySQL using the MariaDB terminal
- ✅ How to connect PHP to MySQL with PDO
- ✅ What prepared statements are and why they are mandatory
- ✅ How to insert data into the database from PHP

### What You'll Need

- Termux open with Apache running (`apachectl`) and MariaDB running (`mariadbd-safe -u root &`)
- Lessons 1 through 9 completed

---

## 2. Setup

Create a dedicated folder for this lesson inside your project directory.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-10
cd lesson-10
```

Files in this lesson will also reference a shared `config.php` that you will place one level up in the `learn-php` root folder. This shared configuration file will be reused by Lessons 11 through 13 as well.

---

## 3. Creating the Database and Tables

Before PHP can store anything, the database and its tables must exist. You create them using SQL commands typed directly into the MariaDB terminal in Termux.

### Step 1: Open the MariaDB Terminal

Open a Termux session and log in to MariaDB:

```bash
mysql -u root -p
```

Enter your password (`1234`) when prompted. You will see the MariaDB prompt, which means you are now inside the database engine and can type SQL commands.

### Step 2: Create the Database

Type the following SQL command and press Enter:

```sql
CREATE DATABASE IF NOT EXISTS db_catatku
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
```

`CREATE DATABASE IF NOT EXISTS` creates the database only if it does not already exist, so running the command twice will not cause an error. `utf8mb4` is the correct character encoding for Indonesian text and emoji, supporting the full Unicode range. `utf8mb4_unicode_ci` is the collation, which controls how text is sorted and compared.

### Step 3: Create the Tables

Type the following commands and press Enter after each block:

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

After running these commands, type `SHOW TABLES;` to verify. You should see both `users` and `entries` listed.

`USE db_catatku` switches the active database to `db_catatku`. `id INT AUTO_INCREMENT PRIMARY KEY` creates a column that automatically assigns a unique integer to each new row, starting from 1. This becomes the row's permanent identity. `VARCHAR(255) NOT NULL` defines a text column with a maximum of 255 characters that cannot be left empty. `UNIQUE` on the email column means no two rows can share the same email address. `TEXT` stores longer strings without a length limit, suitable for journal entry content. The `FOREIGN KEY` on `entries.user_id` creates a link to `users.id`: each entry must belong to a valid user, and `ON DELETE CASCADE` means that if a user is deleted, all their entries are automatically deleted as well.

---

## 4. Connecting PHP to MySQL with PDO

PDO (PHP Data Objects) is PHP's built-in database abstraction layer. It provides a consistent API for talking to different database systems, handles connection errors gracefully, and is the foundation of prepared statements. The connection is typically stored in a shared `config.php` file that every page requiring database access will load.

### Step 1: Create the Configuration File

Navigate to the `learn-php` root folder and create the shared config file there, not inside `lesson-10`, so all future lessons can reuse it:

```bash
cd ~/storage/shared/htdocs/learn-php
micro config.php
```

Type the following code into the editor:

```php
<?php
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
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );
} catch (PDOException $e) {
    die("Database connection failed: " . $e->getMessage());
}
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

`new PDO(...)` creates the connection object. The first argument is the DSN (Data Source Name), a connection string that specifies the database type (`mysql:`), the host address, the database name, and the character set. `PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION` tells PDO to throw a `PDOException` whenever a database operation fails, rather than silently returning `false`. This makes errors visible and debuggable. `PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC` makes every query result return rows as associative arrays, so you access values as `$row['title']` rather than `$row[0]`. `PDO::ATTR_EMULATE_PREPARES => false` disables PDO's emulation layer and uses the database's own prepared statement engine, which provides the strongest protection against SQL injection. The `try/catch` block intercepts `PDOException` if the connection fails and calls `die()` with a readable message, stopping the script before it attempts to run queries against a non-existent connection.

### Step 2: Test the Connection

Go back into the `lesson-10` folder and create the test file:

```bash
cd ~/storage/shared/htdocs/learn-php/lesson-10
micro test-connection.php
```

Type the following code:

```php
<?php
require_once __DIR__ . '/../config.php';

echo "<h2>Database Connection Test</h2>";
echo "<p>Connection to <strong>db_catatku</strong> successful!</p>";

$stmt   = $pdo->query("SHOW TABLES");
$tables = $stmt->fetchAll();

echo "<p>Number of tables: " . count($tables) . "</p>";
echo "<ul>";
foreach ($tables as $table) {
    $table_name = array_values($table)[0];
    echo "<li>$table_name</li>";
}
echo "</ul>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

Open the following URL in the browser:

```
http://localhost:8080/learn-php/lesson-10/test-connection.php
```

If the connection succeeds you will see the heading, the success message, and a list showing `entries` and `users`. If you see an error, check that MariaDB is running in Termux and that the credentials in `config.php` are correct. `$pdo->query()` runs a SQL statement that does not need parameters and returns a statement object. `fetchAll()` retrieves all result rows at once as an array. `array_values($table)[0]` extracts the first value from each row (the table name) regardless of what key the column is stored under.

---

## 5. Prepared Statements: The Safe Way to Interact with a Database

Prepared statements are the single most important security practice in database programming. Every query that includes user-supplied data must use a prepared statement. Understanding why requires seeing what happens without one.

When user input is embedded directly into a SQL string, a malicious user can craft input that changes the meaning of the query. For example, if `$id` comes from a URL parameter and contains `1 OR 1=1`, the resulting query returns every row in the table, not just the requested one. This is called SQL injection. Prepared statements prevent it by sending the SQL template and the data separately: the database processes the template first, then slots the data into the reserved positions. Whatever the data contains, it can never alter the SQL structure.

```php
// Wrong: user data embedded directly in the SQL string
$id  = $_GET['id'];
$pdo->query("SELECT * FROM entries WHERE id = $id");

// Correct: SQL template and data are sent separately
$stmt = $pdo->prepare("SELECT * FROM entries WHERE id = :id");
$stmt->execute(['id' => $_GET['id']]);
```

In the correct version, `:id` is a named placeholder in the SQL template. `prepare()` sends that template to the database, which compiles it. `execute()` then sends the actual data value, which the database treats as a literal string or number, never as additional SQL. The rule is simple: every time a query includes any value that originated outside your PHP code (from a form, URL, cookie, or file), use a prepared statement. There are no exceptions to this rule.

---

## 6. Inserting Your First Data

With the database connection working, now insert actual data. The seeder script below creates one user and three journal entries, demonstrating both how `password_hash` works and how to reuse a single prepared statement in a loop.

### Step 1: Create the Seeder File

Make sure you are in the `lesson-10` folder and create the file:

```bash
micro seed-data.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
require_once __DIR__ . '/../config.php';

$stmt = $pdo->prepare("INSERT INTO users (name, email, password) VALUES (:name, :email, :password)");
$stmt->execute([
    'name'     => 'Budi Santoso',
    'email'    => 'budi@example.com',
    'password' => password_hash('password123', PASSWORD_DEFAULT),
]);

$user_id = $pdo->lastInsertId();
echo "User added successfully with ID: $user_id <br>";

$entries = [
    ['My first entry',    'This is my very first journal entry. It feels great to get started!'],
    ['Learning PHP',      'Today I learned about PDO and databases. It is not as hard as I expected.'],
    ['Weekend plans',     'I want to finish the PHP course this weekend and start learning a framework.'],
];

$stmt = $pdo->prepare("INSERT INTO entries (user_id, title, content) VALUES (:user_id, :title, :content)");

foreach ($entries as $entry) {
    $stmt->execute([
        'user_id' => $user_id,
        'title'   => $entry[0],
        'content' => $entry[1],
    ]);
    echo "Entry added: {$entry[0]} <br>";
}

echo "<br><strong>All sample data has been inserted!</strong>";
echo "<br><em>Note: do not run this file more than once, because the email must be unique.</em>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-10/seed-data.php
```

You will see confirmation lines for the user and all three entries. If you see a duplicate key error, it means the seeder has already run once - that is expected, because the `email` column has a `UNIQUE` constraint.

`password_hash('password123', PASSWORD_DEFAULT)` converts the plain password into a long hashed string that cannot be reversed. `PASSWORD_DEFAULT` uses bcrypt, the current recommended algorithm. The hash includes a random salt, so two calls with the same password produce different hashes. Never store plain-text passwords in a database. `$pdo->lastInsertId()` returns the auto-incremented `id` that MySQL assigned to the last inserted row. The code uses this ID when inserting entries so that each entry is correctly linked to the newly created user. Preparing the `INSERT INTO entries` statement once outside the loop and calling `execute()` with different data on each iteration is both efficient and safe: the database compiles the query template only once, and the loop provides the data without re-parsing the SQL each time.

---

## 7. Fix the Errors in Your Code

This section covers three mistakes that are very common when developers first work with PDO. Two of them introduce serious security vulnerabilities, and one produces a subtle runtime error.

**Error 1: Embedding user input directly into a SQL query.**

Constructing a SQL string by concatenating or interpolating user data allows a malicious user to inject arbitrary SQL commands. This is SQL injection and can expose or destroy the entire database.

```php
// Wrong
$name = $_GET['name'];
$pdo->query("SELECT * FROM users WHERE name = '$name'");

// Correct
$stmt = $pdo->prepare("SELECT * FROM users WHERE name = :name");
$stmt->execute(['name' => $_GET['name']]);
```

If a user passes `name=' OR '1'='1` through the URL, the wrong version produces the query `WHERE name = '' OR '1'='1'`, which matches every row in the table. The correct version passes the value as data, so the database always interprets it as a literal string to match, never as part of the SQL logic.

---

**Error 2: Storing a password in plain text.**

Inserting a raw password string into the database means that anyone who can read the database (through a breach, a backup file, or unauthorized access) immediately knows every user's password.

```php
// Wrong
$stmt->execute([
    'name'     => 'Siti',
    'email'    => 'siti@example.com',
    'password' => 'secret123',
]);

// Correct
$stmt->execute([
    'name'     => 'Siti',
    'email'    => 'siti@example.com',
    'password' => password_hash('secret123', PASSWORD_DEFAULT),
]);
```

`password_hash()` creates a one-way hash: given the hash, you cannot recover the original password. To verify a login, use `password_verify($input, $stored_hash)`, which compares without ever decoding the hash. This is the mandatory approach for any application that handles user accounts.

---

**Error 3: Not saving the result of `prepare()` to a variable.**

`$pdo->prepare()` returns a `PDOStatement` object. If you do not capture it in a variable, the object is lost and the subsequent `execute()` call operates on whatever value `$stmt` happened to hold before - which may be `null` or a statement from a previous operation.

```php
// Wrong
$pdo->prepare("SELECT * FROM entries WHERE user_id = :id");
$stmt->execute(['id' => 1]);

// Correct
$stmt = $pdo->prepare("SELECT * FROM entries WHERE user_id = :id");
$stmt->execute(['id' => 1]);
```

Without `$stmt =`, the first line creates and immediately discards the prepared statement object. The second line then calls `execute()` on whatever `$stmt` was from before, which either does nothing or executes the wrong query. Always assign the result of `prepare()` to a variable before calling `execute()` on it.

---

## 8. Exercises

Complete the following exercises in the `lesson-10` folder. Each file should begin with `require_once __DIR__ . '/../config.php';` to load the database connection.

**Exercise 1:** Create `exercise-1.php`. Connect to the database and display the number of rows in each table. Use the query `SELECT COUNT(*) AS total FROM table_name` for each table and display the results on the page.

**Exercise 2:** Create `exercise-2.php`. Insert a new user into the `users` table with a name, email, and hashed password. After the insert, display the message: "User added successfully with ID: (id)".

**Exercise 3:** Create `exercise-3.php`. Insert two new entries into the `entries` table for the user with `user_id = 1`. Define the entries as an array and use a prepared statement inside a `foreach` loop to insert them.

---

## 9. Solutions

**Solution for Exercise 1:**

```php
<?php
require_once __DIR__ . '/../config.php';

echo "<h2>Database Statistics</h2>";

$stmt   = $pdo->query("SELECT COUNT(*) AS total FROM users");
$result = $stmt->fetch();
echo "Number of users: {$result['total']} <br>";

$stmt   = $pdo->query("SELECT COUNT(*) AS total FROM entries");
$result = $stmt->fetch();
echo "Number of entries: {$result['total']} <br>";
?>
```

`$pdo->query()` is appropriate here because neither query uses any user-supplied input, so there is no injection risk. `SELECT COUNT(*) AS total` asks the database to count all rows and alias the result column as `total`. `fetch()` retrieves a single row as an associative array, so `$result['total']` gives the count. Running this after the seeder should show 1 user and 3 entries.

---

**Solution for Exercise 2:**

```php
<?php
require_once __DIR__ . '/../config.php';

$stmt = $pdo->prepare("INSERT INTO users (name, email, password) VALUES (:name, :email, :password)");
$stmt->execute([
    'name'     => 'Siti Rahayu',
    'email'    => 'siti@example.com',
    'password' => password_hash('password456', PASSWORD_DEFAULT),
]);

$id = $pdo->lastInsertId();
echo "User added successfully with ID: $id";
?>
```

The prepared statement separates the SQL template from the data values, making it safe to insert any string as a name or email without risk of SQL injection. `password_hash('password456', PASSWORD_DEFAULT)` produces a different hash string each time it is called, even for the same input password, because bcrypt generates a random salt internally. `lastInsertId()` returns the `id` that the database auto-assigned to the newly inserted row.

---

**Solution for Exercise 3:**

```php
<?php
require_once __DIR__ . '/../config.php';

$new_entries = [
    ['A productive day',   'I managed to finish two lessons today in one sitting.'],
    ['Late night thoughts', 'It is raining hard tonight. Perfect for reading.'],
];

$stmt = $pdo->prepare("INSERT INTO entries (user_id, title, content) VALUES (:user_id, :title, :content)");

foreach ($new_entries as $entry) {
    $stmt->execute([
        'user_id' => 1,
        'title'   => $entry[0],
        'content' => $entry[1],
    ]);
    echo "Entry added: {$entry[0]} <br>";
}
?>
```

The prepared statement is created once before the loop with `prepare()`, and `execute()` is called multiple times inside the loop with different data each time. This is more efficient than calling `prepare()` inside the loop, because the database only compiles the SQL template once. Each `execute()` call sends the data separately and inserts one row. After this script runs, the `entries` table will have two additional rows linked to the user with `id = 1`.

---

## Next Up - Lesson 11

This lesson is a major step: PHP can now store data in MySQL permanently. PDO is the correct tool for this because it handles connection errors clearly, returns results as associative arrays, and is the foundation of prepared statements. Prepared statements are not optional - they are the only safe way to include any external value in a SQL query. Passwords must always be stored as hashes using `password_hash()` and verified with `password_verify()`.

In Lesson 11, you will learn how to read data from the database and display it as a web page. You will fetch all journal entries from the `entries` table and render them as a formatted list - the first page of the Catatku application that is driven entirely by real database data.