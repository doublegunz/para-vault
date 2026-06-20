## 1. Before You Begin

### Introduction

In the previous lessons, we built classes that hold data in memory. But real applications need data that persists between requests. This lesson connects our project to MySQL using PDO, PHP's standard database interface, wrapped in a proper `Database` class.

### What You'll Build

You will build a `Database` class that manages the MySQL connection, create a configuration file for credentials, and create the `users` and `entries` tables.

### What You'll Learn

- ✅ How to create a reusable Database class with the Singleton pattern
- ✅ How to use configuration files for database credentials
- ✅ How to create tables programmatically with a schema script
- ✅ Why prepared statements prevent SQL injection
- ✅ PDO options: error mode, fetch mode, and emulated prepares

### What You'll Need

- Laragon running (both Apache AND MySQL must be green)
- The Catatku project from Lesson 5
- HeidiSQL (included with Laragon) for database management

---

## 2. Create the Database

This section creates the MySQL database that Catatku will use. You only need to do this once, and the database persists across development sessions.

### Step 1: Open HeidiSQL

In Laragon, click the **Database** button to open HeidiSQL. Connect with hostname `127.0.0.1`, user `root`, empty password.

### Step 2: Create the Database

In the HeidiSQL query tab, type and execute (press F9):

```sql
CREATE DATABASE IF NOT EXISTS db_catatku
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
```

`IF NOT EXISTS` makes this statement safe to run multiple times without throwing an error. `utf8mb4` is the full Unicode character set that supports emoji and all non-ASCII characters. `utf8mb4_unicode_ci` is the collation rule that handles multilingual text comparisons correctly.

Refresh the left panel. The `db_catatku` database should appear.

---

## 3. Create the Configuration File

Database credentials should never be hardcoded inside a class. This section creates a dedicated configuration file that the `Database` class will load at runtime.

### Step 1: Create the File

In VS Code, right-click on the `config` folder, select **New File**, type `database.php`, and press Enter.

### Step 2: Write the Code

Open `config/database.php` and type the following code:

```php
<?php

return [
    'host'     => '127.0.0.1',
    'port'     => '3306',
    'database' => 'db_catatku',
    'username' => 'root',
    'password' => '',
    'charset'  => 'utf8mb4',
];
```

This file returns a plain PHP array with the database credentials. Any script that does `require 'config/database.php'` receives the array directly as the return value. Keeping credentials in a config file rather than hardcoded inside the class mirrors the `.env` approach that frameworks use, and makes credentials easy to change without touching the Database class itself.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 4. Build the Database Class

This section replaces the `Database` placeholder from Lesson 5 with a real implementation that establishes a PDO connection using the Singleton pattern, ensuring only one connection is created per request.

### Step 1: Open the File

Open `src/Database.php` in VS Code.

### Step 2: Replace the Code

Replace the entire content with:

```php
<?php

namespace App;

use PDO;
use PDOException;

class Database
{
    private static ?PDO $connection = null;

    public static function getConnection(): PDO
    {
        if (self::$connection === null) {
            $config = require __DIR__ . '/../config/database.php';

            $dsn = sprintf(
                'mysql:host=%s;port=%s;dbname=%s;charset=%s',
                $config['host'],
                $config['port'],
                $config['database'],
                $config['charset']
            );

            try {
                self::$connection = new PDO($dsn, $config['username'], $config['password'], [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_OBJ,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                ]);
            } catch (PDOException $e) {
                die('Database connection failed: ' . $e->getMessage());
            }
        }

        return self::$connection;
    }
}
```

### Step 3: Save the File

Press **Ctrl+S**.

### Code Breakdown

`private static ?PDO $connection = null;` keeps a single connection instance. The `static` keyword means the property belongs to the class itself, not to individual objects. This is the **Singleton pattern**: only one connection is created and reused everywhere.

`self::$connection` accesses the static property. `self::` refers to the current class, like `$this->` refers to the current object.

`PDO::FETCH_OBJ` returns query results as objects (not associative arrays). This fits our OOP approach better. `PDO::ERRMODE_EXCEPTION` makes PDO throw exceptions instead of failing silently.

---

## 5. Create the Tables

Rather than creating tables manually in HeidiSQL each time, this section writes a PHP script that creates both tables programmatically. This script is repeatable and can be committed to version control.

### Step 1: Create the File

Right-click on the `config` folder, select **New File**, type `schema.php`, and press Enter.

### Step 2: Write the Code

Open `config/schema.php` and type the following code:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Database;

$pdo = Database::getConnection();

$pdo->exec("
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
");

$pdo->exec("
    CREATE TABLE IF NOT EXISTS entries (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
");

echo "Tables created successfully.\n";
```

`Database::getConnection()` returns the shared PDO instance. `$pdo->exec()` executes a SQL statement where no result rows are expected. `CREATE TABLE IF NOT EXISTS` makes the script safe to run multiple times. The `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE` constraint enforces referential integrity: deleting a user automatically removes all their journal entries.

### Step 3: Save the File

Press **Ctrl+S**.

### Step 4: Run in the Terminal

Open a new terminal and run:

```bash
cd C:\laragon\www\catatku
php config/schema.php
```

You should see: `Tables created successfully.`

Verify in HeidiSQL: click on `db_catatku`, you should see the `users` and `entries` tables.

---

## 6. Test the Connection

This section updates `public/index.php` to verify that the `Database` class connects to MySQL and that both tables are visible.

### Step 1: Open the File

Open `public/index.php`.

### Step 2: Replace the Code

Replace the entire content with:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Database;

$pdo = Database::getConnection();

echo '<h1>Catatku</h1>';
echo '<p>Database connected successfully!</p>';

$stmt = $pdo->query("SHOW TABLES");
$tables = $stmt->fetchAll();
echo '<p>Tables found: ' . count($tables) . '</p>';
echo '<ul>';
foreach ($tables as $table) {
    $name = array_values((array) $table)[0];
    echo '<li>' . htmlspecialchars($name) . '</li>';
}
echo '</ul>';
```

`Database::getConnection()` is called as a static method and returns the single shared PDO instance. `$pdo->query()` executes the SQL and returns a `PDOStatement`. `fetchAll()` retrieves all rows at once as an array of objects. `array_values((array) $table)[0]` converts each result object to an array and picks the first value, which holds the table name string.

### Step 3: Save and Run

Save the file (**Ctrl+S**). Open:

```
http://localhost:8080
```

You should see "Database connected successfully!" with 2 tables listed.

---

## 7. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
use App\Database;

// Error 1: Creating a Database object instead of using static method
$db = new Database();
$pdo = $db->getConnection();

// Error 2: Concatenating user input into a query
$id = $_GET['id'];
$stmt = $pdo->query("SELECT * FROM entries WHERE id = $id");

// Error 3: Config file returns nothing
// config/database.php contains:
// $host = '127.0.0.1'; $database = 'db_catatku';
```

**Error 1: Wrong usage.** `getConnection()` is a `static` method, called on the class itself: `Database::getConnection()`, not on an object.

**Error 2: SQL injection.** Never concatenate `$_GET` data into queries. Use prepared statements: `$stmt = $pdo->prepare("SELECT * FROM entries WHERE id = :id"); $stmt->execute(['id' => $id]);`.

**Error 3: Config file must `return` an array.** Using plain variables means the Database class cannot read them. The file must end with `return ['host' => '127.0.0.1', ...];`.

---

## 8. Exercises

**Exercise 1:** Add a method `public static function isConnected(): bool` to the Database class that returns `true` if a connection exists, `false` otherwise. Test it in `public/index.php` before and after calling `getConnection()`.

**Exercise 2:** Create a seed script `config/seed.php` that inserts one test user (`password_hash()`) and two test entries into the database. Run it with `php config/seed.php`.

**Exercise 3:** Create `public/test-db.php` that connects to the database, counts the number of users and entries using `SELECT COUNT(*)`, and displays the results. Use prepared statements for all queries.

---

## 9. Solutions

**Solution for Exercise 1:**

Add to `src/Database.php` inside the class:

```php
    public static function isConnected(): bool
    {
        return self::$connection !== null;
    }
```

`self::$connection !== null` checks whether the static property has been assigned a PDO object. Before `getConnection()` is called for the first time, the property holds its initial value of `null`, so this returns `false`. After the connection is established, it returns `true`.

Test in `public/index.php`:

```php
echo '<p>Connected before: ' . (Database::isConnected() ? 'Yes' : 'No') . '</p>';
$pdo = Database::getConnection();
echo '<p>Connected after: ' . (Database::isConnected() ? 'Yes' : 'No') . '</p>';
```

Calling `isConnected()` before `getConnection()` returns `No` because `$connection` is still `null`. After `getConnection()` runs, the static property holds the PDO object, so the second call returns `Yes`. The ternary operator `? 'Yes' : 'No'` converts the boolean return value to a readable string.

**Solution for Exercise 2:**

Create `config/seed.php`:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Database;

$pdo = Database::getConnection();

$stmt = $pdo->prepare("INSERT INTO users (name, email, password) VALUES (:name, :email, :password)");
$stmt->execute([
    'name'     => 'Budi Santoso',
    'email'    => 'budi@example.com',
    'password' => password_hash('password123', PASSWORD_DEFAULT),
]);
$userId = $pdo->lastInsertId();
echo "User created with ID: $userId\n";

$stmt = $pdo->prepare("INSERT INTO entries (user_id, title, content) VALUES (:uid, :title, :content)");
$stmt->execute(['uid' => $userId, 'title' => 'My first entry', 'content' => 'Learning PHP OOP is exciting!']);
$stmt->execute(['uid' => $userId, 'title' => 'Day two', 'content' => 'Today I learned about the Database class.']);
echo "2 entries created.\n";
```

`$pdo->prepare()` creates a prepared statement with named placeholders like `:name`. `execute()` binds the actual values and runs the query safely, eliminating any risk of SQL injection. `lastInsertId()` returns the auto-incremented primary key of the last inserted row, used here as the `user_id` for both entries. `password_hash()` hashes the password with bcrypt before it is stored.

Run: `php config/seed.php`

**Solution for Exercise 3:**

Create `public/test-db.php`:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Database;

$pdo = Database::getConnection();

$users   = $pdo->query("SELECT COUNT(*) as total FROM users")->fetch();
$entries = $pdo->query("SELECT COUNT(*) as total FROM entries")->fetch();

echo '<h2>Database Statistics</h2>';
echo '<p>Users: ' . $users->total . '</p>';
echo '<p>Entries: ' . $entries->total . '</p>';
```

`->query()` is chained directly with `->fetch()` to execute the query and retrieve the single result row in one line. Because `PDO::FETCH_OBJ` was set as a default option in the `Database` class, `fetch()` returns a `stdClass` object, so the `total` column is read as `$users->total` rather than as an array key.

Run at: `http://localhost:8080/test-db.php`

---

## 10. Conclusion

PDO is PHP's standard database interface. The Database class uses the Singleton pattern to maintain a single connection. Configuration files keep credentials separate from code. Prepared statements prevent SQL injection by separating query structure from data. Always use them.

---

## Next Up - Lesson 7: The Repository Pattern

In the next lesson you will:

1. Build an `EntryRepository` class that centralizes all SQL queries for journal entries
2. Replace scattered `$pdo->query()` calls with clean, named method calls
3. Understand why separating database logic from business logic makes the application easier to maintain and test