## 1. Before You Begin

Some resources should exist only once in an application: the database connection, the configuration manager, the logger. Creating multiple instances wastes memory and can cause conflicts (two database connections competing, inconsistent config values). The **Singleton** pattern ensures a class has exactly one instance and provides a global access point to it. Singleton is the simplest and most controversial creational pattern: simple because the implementation is straightforward, and controversial because it introduces global state, which makes testing harder. This lesson teaches the pattern, its proper use cases, and its drawbacks.

### What You'll Build

You will create a database connection manager and a configuration manager using the Singleton pattern.

### What You'll Learn

- ✅ The Singleton pattern: intent, structure, implementation
- ✅ Private constructor, static instance, static accessor
- ✅ Preventing cloning and unserialization
- ✅ When Singleton is appropriate
- ✅ Why Singleton is often overused (testing, coupling)
- ✅ Singleton in Laravel: service container shared bindings

### What You'll Need

- Lesson 2 completed with SOLID understanding

---

## 2. The Problem

Imagine a database connection class. Every time you call `new Database()`, a new connection is opened. In a web request that runs 20 queries across 10 different classes, you could end up with 10 separate connections. This wastes resources and makes transaction management impossible.

You need a way to ensure only one instance exists and every part of the application uses that same instance.

---

## 3. The Solution

The Singleton pattern has three key elements: a private constructor (prevents external instantiation), a static property holding the single instance, and a static method that returns the instance (creating it on first call).

Create `src/Creational/Singleton/Database.php`:

```php
<?php

namespace App\Creational\Singleton;

class Database
{
    private static ?Database $instance = null;

    // Private constructor: cannot be called from outside
    private function __construct(
        private readonly string $host,
        private readonly string $name,
    ) {
        echo "Database connection created to {$this->host}/{$this->name}\n";
    }

    // Static accessor: returns the single instance
    public static function getInstance(): static
    {
        if (static::$instance === null) {
            static::$instance = new static('localhost', 'app_db');
        }
        return static::$instance;
    }

    // Prevent cloning
    private function __clone(): void {}

    // Prevent unserialization
    public function __wakeup(): void
    {
        throw new \RuntimeException('Cannot unserialize a singleton.');
    }

    public function query(string $sql): array
    {
        echo "Executing: {$sql}\n";
        return [];
    }

    public function getConnectionInfo(): string
    {
        return "{$this->host}/{$this->name}";
    }
}
```

Create `src/Creational/Singleton/Demo.php`:

```php
<?php

require_once __DIR__ . '/../../vendor/autoload.php';

use App\Creational\Singleton\Database;

// First call: creates the instance
$db1 = Database::getInstance();
$db1->query("SELECT * FROM users");

// Second call: returns the SAME instance (no "connection created" message)
$db2 = Database::getInstance();
$db2->query("SELECT * FROM orders");

// Proof: same instance
echo "Same instance? " . ($db1 === $db2 ? 'Yes' : 'No') . "\n";

// This fails: private constructor
// $db3 = new Database('localhost', 'test');  // Fatal error!
```

Run: `php run.php Creational/Singleton`

Output:

```
Database connection created to localhost/app_db
Executing: SELECT * FROM users
Executing: SELECT * FROM orders
Same instance? Yes
```

---

## 4. Configuration Manager Example

A second practical example: application configuration loaded once from a file.

```php
<?php

namespace App\Creational\Singleton;

class Config
{
    private static ?Config $instance = null;
    private array $settings = [];

    private function __construct(string $filePath)
    {
        $this->settings = require $filePath;
    }

    public static function getInstance(string $filePath = ''): static
    {
        if (static::$instance === null) {
            if (empty($filePath)) {
                throw new \RuntimeException('Config file path required on first call.');
            }
            static::$instance = new static($filePath);
        }
        return static::$instance;
    }

    public function get(string $key, mixed $default = null): mixed
    {
        return $this->settings[$key] ?? $default;
    }

    private function __clone(): void {}
}
```

---

## 5. When to Use and When to Avoid

**Use Singleton when:**
- A single shared resource (database connection, file handle, config) must exist
- Creating multiple instances would cause bugs or waste resources
- The instance must be accessible across the application

**Avoid Singleton when:**
- You are using it as a "global variable" disguise
- Testing requires different instances (Singleton is hard to mock)
- Dependency injection is available (prefer DI over Singleton)

**The modern alternative:** Use a dependency injection container (like Laravel's service container) with `singleton` binding. It provides the same single-instance guarantee without the global state drawbacks:

```php
// Laravel: container-managed singleton (preferred)
$this->app->singleton(Database::class, fn() => new Database('localhost', 'app_db'));
```

---

## 6. Fix the Errors in Your Code

These three mistakes are the most common Singleton implementation errors in PHP.

**Error 1: Public constructor allows multiple instances.**

If the constructor is public, any code can call `new Logger()` and get a separate instance, breaking the guarantee the pattern is designed to enforce.

```php
// Wrong: public constructor allows external instantiation
class Logger
{
    private static ?Logger $instance = null;
    public function __construct() {}
}

// Correct: private constructor prevents external instantiation
class Logger
{
    private static ?Logger $instance = null;
    private function __construct() {}

    public static function getInstance(): static
    {
        return static::$instance ??= new static();
    }
}
```

Make the constructor `private`. Only the static `getInstance()` method should be able to call it.

**Error 2: Cloning the singleton creates a second instance.**

PHP's `clone` keyword creates a copy of any object. Without blocking it explicitly, a caller can write `$copy = clone Database::getInstance()` and instantly have two instances.

```php
// Wrong: __clone is not defined, so cloning is allowed
class Database
{
    private static ?Database $instance = null;
    private function __construct() {}
    public static function getInstance(): static { ... }
}

// Correct: declare __clone as private to prevent copying
class Database
{
    private static ?Database $instance = null;
    private function __construct() {}
    private function __clone(): void {}
    public static function getInstance(): static { ... }
}
```

Always add `private function __clone(): void {}` to every Singleton class to block the `clone` keyword.

**Error 3: Static property not declared as nullable.**

If you declare `private static Database $instance` without a default value, PHP raises an error on the first call because the property is uninitialized and has no value to return.

```php
// Wrong: non-nullable typed property with no default value
class Database
{
    private static Database $instance;
}

// Correct: nullable type with null as the initial value
class Database
{
    private static ?Database $instance = null;
}
```

The `?Database` nullable type and `= null` initial value are both required. The null check in `getInstance()` then creates the instance on the first call and returns the stored instance on every subsequent call.

---

## 7. Exercises

**Exercise 1:** Create a `Logger` singleton that writes messages to an array. Add `log(string $message)` and `getLogs(): array` methods. Demonstrate that two calls to `getInstance()` share the same log history.

**Exercise 2:** Create a `Registry` singleton that stores key-value pairs. Add `set(string $key, mixed $value)` and `get(string $key)` methods. Store and retrieve values from different parts of the code.

**Exercise 3:** Explain in comments why Singleton makes unit testing harder. Write a test scenario where you need a fresh Database instance but Singleton prevents it.

---

## 8. Solutions

**Solution for Exercise 1:**

```php
class Logger
{
    private static ?Logger $instance = null;
    private array $logs = [];
    private function __construct() {}
    public static function getInstance(): static
    {
        return static::$instance ??= new static();
    }
    public function log(string $message): void { $this->logs[] = date('H:i:s') . " $message"; }
    public function getLogs(): array { return $this->logs; }
    private function __clone(): void {}
}

$logger1 = Logger::getInstance();
$logger1->log('User logged in');
$logger2 = Logger::getInstance();
$logger2->log('Order created');
echo count($logger1->getLogs());  // 2 (same instance!)
```

**Solution for Exercise 3:** In unit tests, you want fresh state for each test. Singleton carries state between tests. Solution: add a `resetInstance()` method (only for testing) or use dependency injection instead.

---

## 9. Next Up - Lesson 4

Singleton ensures exactly one instance of a class exists by combining a private constructor, a static property, and a static accessor. Always block cloning with a private `__clone()` method and prevent unserialization with `__wakeup()`. Use Singleton for genuinely shared resources such as database connections and configuration managers, and prefer a dependency injection container when one is available because it provides the same single-instance guarantee without introducing global state.

In Lesson 4, you will learn the Factory Method and Abstract Factory patterns: two ways to create objects without specifying their exact classes, keeping your code open for new types without modifying existing code.