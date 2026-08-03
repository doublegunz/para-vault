## 1. Before You Begin

Sometimes you need to add behavior to an object without modifying its class. **Decorator** wraps an object and adds behavior while maintaining the same interface. **Proxy** wraps an object to control access to it. Both patterns use composition and implement the same interface as the wrapped object. The difference is intent: Decorator adds features, Proxy controls access. Decorator adds responsibilities to objects dynamically, making it ideal for composable middleware-style pipelines. Proxy controls access with strategies such as caching, lazy loading, and access control.

### What You'll Build

You will create a middleware-like decorator chain for HTTP requests, and a caching proxy for expensive database queries.

### What You'll Learn

- ✅ Decorator: add behavior dynamically without modifying the class
- ✅ Stacking multiple decorators
- ✅ Proxy: control access (lazy loading, caching, logging, access control)
- ✅ Decorator vs Proxy vs Adapter (same structure, different intent)
- ✅ Decorator in Laravel: middleware

### What You'll Need

- Lesson 7 completed

---

## 2. Decorator Pattern

The Decorator wraps an object, implements the same interface, and adds behavior before or after delegating to the wrapped object. Create the `Logger` interface, a concrete `ConsoleLogger`, a base `LoggerDecorator`, and three concrete decorators that add timestamps, severity levels, and JSON formatting:

```php
<?php
namespace App\Structural\Decorator;

interface Logger
{
    public function log(string $message): void;
}

class ConsoleLogger implements Logger
{
    public function log(string $message): void
    {
        echo $message . "\n";
    }
}

// Decorator base
abstract class LoggerDecorator implements Logger
{
    public function __construct(protected Logger $logger) {}
}

// Adds timestamp
class TimestampDecorator extends LoggerDecorator
{
    public function log(string $message): void
    {
        $this->logger->log("[" . date('Y-m-d H:i:s') . "] " . $message);
    }
}

// Adds severity level
class LevelDecorator extends LoggerDecorator
{
    public function __construct(Logger $logger, private string $level = 'INFO')
    {
        parent::__construct($logger);
    }

    public function log(string $message): void
    {
        $this->logger->log("[{$this->level}] " . $message);
    }
}

// Adds JSON formatting
class JsonDecorator extends LoggerDecorator
{
    public function log(string $message): void
    {
        $this->logger->log(json_encode(['message' => $message]));
    }
}

// Stack decorators: each wraps the previous one
$logger = new ConsoleLogger();
$logger = new TimestampDecorator($logger);
$logger = new LevelDecorator($logger, 'WARNING');

$logger->log('Disk space is running low');
// Output: [WARNING] [2026-04-10 14:30:00] Disk space is running low
```

Decorators can be stacked in any order. Each one adds one concern. This follows SRP and OCP.

---

## 3. Proxy Pattern

The Proxy has the same interface as the real object but controls access to it. Common types: caching proxy, lazy-loading proxy, access control proxy, logging proxy.

```php
<?php
namespace App\Structural\Proxy;

interface UserRepository
{
    public function findAll(): array;
    public function findById(int $id): ?array;
}

class DatabaseUserRepository implements UserRepository
{
    public function findAll(): array
    {
        echo "[DB] Expensive query: SELECT * FROM users\n";
        return [
            ['id' => 1, 'name' => 'Budi'],
            ['id' => 2, 'name' => 'Citra'],
        ];
    }

    public function findById(int $id): ?array
    {
        echo "[DB] Expensive query: SELECT * FROM users WHERE id = {$id}\n";
        return ['id' => $id, 'name' => 'User ' . $id];
    }
}

// Caching proxy
class CachingUserRepository implements UserRepository
{
    private array $cache = [];

    public function __construct(private UserRepository $repo) {}

    public function findAll(): array
    {
        if (!isset($this->cache['all'])) {
            $this->cache['all'] = $this->repo->findAll();
        } else {
            echo "[Cache] Hit for findAll\n";
        }
        return $this->cache['all'];
    }

    public function findById(int $id): ?array
    {
        $key = "user_{$id}";
        if (!isset($this->cache[$key])) {
            $this->cache[$key] = $this->repo->findById($id);
        } else {
            echo "[Cache] Hit for user {$id}\n";
        }
        return $this->cache[$key];
    }
}

// Usage
$repo = new CachingUserRepository(new DatabaseUserRepository());
$repo->findAll();       // DB query
$repo->findAll();       // Cache hit!
$repo->findById(1);     // DB query
$repo->findById(1);     // Cache hit!
```

---

## 4. Decorator vs Proxy vs Adapter

All three wrap objects, but with different intents.

| Pattern | Intent | Modifies interface? |
|---------|--------|-------------------|
| Decorator | Add behavior | No (same interface) |
| Proxy | Control access | No (same interface) |
| Adapter | Convert interface | Yes (different interface) |

---

## 5. Fix the Errors in Your Code

These are the three most common Decorator and Proxy mistakes in PHP codebases.

**Error 1: Decorator does not implement the component interface.**

The decorator must implement the same interface as the wrapped component. Without this declaration, code that type-hints the interface will reject the decorator, and all type-safety guarantees are lost.

```php
// Wrong: class declaration is missing "implements Logger"
class TimestampDecorator
{
    public function __construct(protected Logger $logger) {}
    public function log(string $message): void
    {
        $this->logger->log('[' . date('H:i:s') . '] ' . $message);
    }
}

// Correct: explicitly declare the interface
class TimestampDecorator implements Logger
{
    public function __construct(protected Logger $logger) {}
    public function log(string $message): void
    {
        $this->logger->log('[' . date('H:i:s') . '] ' . $message);
    }
}
```

Every decorator must declare `implements InterfaceName`. Without it, the decorator cannot be passed to any function that type-hints the interface.

**Error 2: Proxy that returns from the cache without checking if it is populated.**

A caching proxy must delegate to the real object when the cache is empty. Accessing an undefined cache key returns `null` or throws a PHP notice, causing the application to behave incorrectly on the first call.

```php
// Wrong: returns cache entry directly — undefined key on first call
class CachingRepo implements UserRepository
{
    private array $cache = [];
    public function findAll(): array
    {
        return $this->cache['all'];
    }
}

// Correct: check the cache, then delegate to the real object on a miss
class CachingRepo implements UserRepository
{
    private array $cache = [];
    public function __construct(private UserRepository $repo) {}
    public function findAll(): array
    {
        if (!isset($this->cache['all'])) {
            $this->cache['all'] = $this->repo->findAll();
        }
        return $this->cache['all'];
    }
}
```

Always use `isset()` (or a `null` check) before reading from the cache. On a miss, call the real object and store the result before returning.

**Error 3: Decorator method calls itself instead of delegating to the wrapped component.**

Inside a decorator, calling `$this->log(...)` invokes the decorator's own method recursively, causing infinite recursion and a stack overflow. The delegate call must go through the wrapped component property.

```php
// Wrong: $this->log() calls itself — infinite recursion
class BadDecorator extends LoggerDecorator
{
    public function log(string $message): void
    {
        $this->log($message);
    }
}

// Correct: delegate to $this->logger — the wrapped component
class GoodDecorator extends LoggerDecorator
{
    public function log(string $message): void
    {
        $this->logger->log('[PREFIX] ' . $message);
    }
}
```

Always call `$this->wrappedComponent->method(...)` inside the decorator, not `$this->method(...)`. The decorator adds behavior before or after the delegate call, but it must always delegate.

---

## 6. Exercises

**Exercise 1:** Create a `EncryptionDecorator` for the Logger that encrypts (base64_encode) the message before passing it to the inner logger.

**Exercise 2:** Create an `AccessControlProxy` for `UserRepository` that checks if the current user has "admin" role before allowing `findAll()`. Non-admins get an exception.

**Exercise 3:** Create a middleware-like decorator chain for an HTTP handler: `LoggingMiddleware -> AuthMiddleware -> RateLimitMiddleware -> Handler`. Each decorator wraps the next.

---

## 7. Solutions

**Solution for Exercise 2:**

```php
class AccessControlProxy implements UserRepository
{
    public function __construct(private UserRepository $repo, private string $role) {}
    public function findAll(): array
    {
        if ($this->role !== 'admin') throw new \RuntimeException('Access denied');
        return $this->repo->findAll();
    }
    public function findById(int $id): ?array { return $this->repo->findById($id); }
}
```

---

## 8. Next Up - Lesson 9

Decorator adds behavior by wrapping objects in composable layers. Stack multiple decorators in any order for composable features. Proxy controls access with caching, lazy loading, or access control. Both patterns implement the same interface as the wrapped object. Laravel's middleware is a Decorator chain; ORM lazy-loading uses Proxy.

In Lesson 9, you will learn Facade and Flyweight: Facade provides a simplified interface to a complex subsystem, while Flyweight shares memory between thousands of similar objects.