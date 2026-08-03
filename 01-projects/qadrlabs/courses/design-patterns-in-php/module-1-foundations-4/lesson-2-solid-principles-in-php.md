## 1. Before You Begin

Design patterns are solutions to design problems. But how do you know if your design is good? The **SOLID principles** are five guidelines for writing flexible, maintainable object-oriented code. They are the foundation on which design patterns are built. Understanding SOLID makes every pattern feel intuitive instead of arbitrary. This lesson covers all five principles with practical PHP 8 examples. Each principle is demonstrated with a bad example that violates it and a good example that follows it.

### What You'll Build

You will refactor a monolithic order processing class into a clean, SOLID-compliant design using interfaces, dependency injection, and single-purpose classes.

### What You'll Learn

- ✅ **S**ingle Responsibility Principle (SRP)
- ✅ **O**pen/Closed Principle (OCP)
- ✅ **L**iskov Substitution Principle (LSP)
- ✅ **I**nterface Segregation Principle (ISP)
- ✅ **D**ependency Inversion Principle (DIP)
- ✅ How each principle connects to specific design patterns

### What You'll Need

- Lesson 1 completed with the project structure set up

---

## 2. Single Responsibility Principle (SRP)

A class should have only one reason to change. If a class handles both business logic and database queries, changes to the database require modifying business logic code. SRP says: split them.

```php
<?php
// BAD: One class does everything
class OrderProcessor
{
    public function calculateTotal(array $items): float
    {
        $total = 0;
        foreach ($items as $item) {
            $total += $item['price'] * $item['qty'];
        }
        return $total;
    }

    public function saveToDatabase(array $order): void
    {
        // Database logic mixed with business logic!
        $pdo = new PDO('mysql:host=localhost;dbname=shop', 'root', '');
        $stmt = $pdo->prepare("INSERT INTO orders (total) VALUES (:total)");
        $stmt->execute(['total' => $order['total']]);
    }

    public function sendEmail(string $to, string $subject): void
    {
        // Email logic mixed in too!
        mail($to, $subject, 'Your order has been placed.');
    }
}
```

```php
<?php
// GOOD: Each class has one responsibility
class OrderCalculator
{
    public function calculateTotal(array $items): float
    {
        return array_sum(array_map(
            fn($item) => $item['price'] * $item['qty'],
            $items
        ));
    }
}

class OrderRepository
{
    public function __construct(private PDO $pdo) {}

    public function save(float $total): int
    {
        $stmt = $this->pdo->prepare("INSERT INTO orders (total) VALUES (:total)");
        $stmt->execute(['total' => $total]);
        return (int) $this->pdo->lastInsertId();
    }
}

class OrderNotifier
{
    public function notify(string $to, float $total): void
    {
        // Send email notification
        echo "Email sent to {$to}: Order total \${$total}\n";
    }
}
```

**Connected patterns:** Strategy, Command, Observer all enforce SRP by separating concerns into dedicated classes.

---

## 3. Open/Closed Principle (OCP)

Classes should be open for extension but closed for modification. When you need new behavior, you should be able to add it without changing existing, tested code.

```php
<?php
// BAD: Adding a new discount type requires modifying this method
class DiscountCalculator
{
    public function calculate(string $type, float $amount): float
    {
        if ($type === 'percentage') {
            return $amount * 0.10;
        } elseif ($type === 'fixed') {
            return 50.0;
        } elseif ($type === 'seasonal') {  // New type = modify existing code!
            return $amount * 0.25;
        }
        return 0;
    }
}
```

```php
<?php
// GOOD: New discounts are added by creating new classes, not modifying existing ones
interface DiscountStrategy
{
    public function calculate(float $amount): float;
}

class PercentageDiscount implements DiscountStrategy
{
    public function __construct(private float $rate = 0.10) {}
    public function calculate(float $amount): float { return $amount * $this->rate; }
}

class FixedDiscount implements DiscountStrategy
{
    public function __construct(private float $discount = 50.0) {}
    public function calculate(float $amount): float { return $this->discount; }
}

// Adding a new discount: create a new class. Zero changes to existing code.
class SeasonalDiscount implements DiscountStrategy
{
    public function calculate(float $amount): float { return $amount * 0.25; }
}

class Order
{
    public function applyDiscount(float $total, DiscountStrategy $strategy): float
    {
        return $total - $strategy->calculate($total);
    }
}
```

**Connected patterns:** Strategy, Decorator, Factory Method, and Observer all follow OCP.

---

## 4. Liskov Substitution Principle (LSP)

Subclasses should be substitutable for their parent classes without breaking the program. If a function accepts a `Bird`, passing a `Penguin` (which cannot fly) should not cause errors.

```php
<?php
// BAD: Square violates the contract of Rectangle
class Rectangle
{
    public function __construct(protected float $width, protected float $height) {}
    public function setWidth(float $w): void { $this->width = $w; }
    public function setHeight(float $h): void { $this->height = $h; }
    public function area(): float { return $this->width * $this->height; }
}

class Square extends Rectangle
{
    public function setWidth(float $w): void { $this->width = $w; $this->height = $w; }  // Violates LSP!
    public function setHeight(float $h): void { $this->width = $h; $this->height = $h; }
}

// Surprise! setWidth on a Square also changes height. Calling code does not expect this.
```

```php
<?php
// GOOD: Use an interface instead of inheritance
interface Shape
{
    public function area(): float;
}

class Rectangle implements Shape
{
    public function __construct(private float $width, private float $height) {}
    public function area(): float { return $this->width * $this->height; }
}

class Square implements Shape
{
    public function __construct(private float $side) {}
    public function area(): float { return $this->side * $this->side; }
}
```

**Connected patterns:** Factory Method and Abstract Factory produce objects that satisfy LSP by returning interface-typed results.

---

## 5. Interface Segregation Principle (ISP)

Clients should not be forced to depend on methods they do not use. Fat interfaces should be split into smaller, focused ones.

```php
<?php
// BAD: One interface forces all implementations to handle everything
interface Worker
{
    public function work(): void;
    public function eat(): void;
    public function sleep(): void;
}

class Robot implements Worker
{
    public function work(): void { echo "Working...\n"; }
    public function eat(): void { /* Robots don't eat! Empty method. */ }
    public function sleep(): void { /* Robots don't sleep! */ }
}
```

```php
<?php
// GOOD: Split into focused interfaces
interface Workable { public function work(): void; }
interface Eatable { public function eat(): void; }
interface Sleepable { public function sleep(): void; }

class Human implements Workable, Eatable, Sleepable
{
    public function work(): void { echo "Human working\n"; }
    public function eat(): void { echo "Human eating\n"; }
    public function sleep(): void { echo "Human sleeping\n"; }
}

class Robot implements Workable
{
    public function work(): void { echo "Robot working\n"; }
    // No forced empty methods!
}
```

**Connected patterns:** Adapter, Strategy, Observer all use focused interfaces.

---

## 6. Dependency Inversion Principle (DIP)

High-level modules should not depend on low-level modules. Both should depend on abstractions (interfaces). This is the most impactful principle for design patterns.

```php
<?php
// BAD: High-level class depends on low-level class directly
class MySQLDatabase
{
    public function query(string $sql): array { return []; }
}

class UserRepository
{
    private MySQLDatabase $db;
    public function __construct() { $this->db = new MySQLDatabase(); }  // Tightly coupled!
}
```

```php
<?php
// GOOD: Both depend on an abstraction
interface DatabaseInterface
{
    public function query(string $sql): array;
}

class MySQLDatabase implements DatabaseInterface
{
    public function query(string $sql): array { return []; }
}

class PostgreSQLDatabase implements DatabaseInterface
{
    public function query(string $sql): array { return []; }
}

class UserRepository
{
    public function __construct(private DatabaseInterface $db) {}  // Depends on interface!
    public function findAll(): array { return $this->db->query("SELECT * FROM users"); }
}

// Swap database without changing UserRepository:
$repo = new UserRepository(new MySQLDatabase());
$repo = new UserRepository(new PostgreSQLDatabase());
```

**Connected patterns:** Almost every pattern uses DIP. Strategy, Factory, Observer, and Adapter all depend on interfaces.

---

## 7. Fix the Errors in Your Code

These are the three SOLID violations most commonly found in PHP codebases.

**Error 1: God class (violates SRP).**

A class with too many responsibilities has too many reasons to change. When the database schema changes, the request-handling code breaks. When the email provider changes, the logging code is affected.

```php
// Wrong: one class handles too many unrelated concerns
class Application
{
    public function handleRequest() { ... }
    public function connectDatabase() { ... }
    public function renderView() { ... }
    public function sendEmail() { ... }
    public function logError() { ... }
}

// Correct: split each responsibility into its own focused class
class Router { public function handleRequest() { ... } }
class Database { public function connect() { ... } }
class ViewRenderer { public function render() { ... } }
class Mailer { public function send() { ... } }
class Logger { public function log() { ... } }
```

Split the god class into focused, single-purpose classes. Each class should have only one reason to change.

**Error 2: Depending on a concrete class instead of an interface (violates DIP).**

When a high-level class type-hints a low-level class directly, swapping implementations requires modifying the high-level class. This is the opposite of what DIP requires.

```php
// Wrong: tightly coupled to a specific payment gateway
class PaymentService
{
    public function __construct(private StripeGateway $gateway) {}
}

// Correct: depends on an abstraction, not a concrete class
class PaymentService
{
    public function __construct(private PaymentGatewayInterface $gateway) {}
}
```

Type-hint the interface, not the concrete class. Inject the concrete implementation from outside the class. This allows swapping `StripeGateway` for `PayPalGateway` without touching `PaymentService`.

**Error 3: Fat interface forces unwanted method implementations (violates ISP).**

An interface that bundles unrelated methods forces every implementing class to stub out methods it does not need, creating empty implementations and misleading contracts.

```php
// Wrong: forces every repository to implement export and import
interface CrudRepository
{
    public function findAll(): array;
    public function findById(int $id): ?object;
    public function create(array $data): object;
    public function update(int $id, array $data): object;
    public function delete(int $id): bool;
    public function export(): string;
    public function import(string $data): void;
}

// Correct: split into focused, role-specific interfaces
interface ReadRepository
{
    public function findAll(): array;
    public function findById(int $id): ?object;
}
interface WriteRepository
{
    public function create(array $data): object;
    public function update(int $id, array $data): object;
    public function delete(int $id): bool;
}
interface ExportableRepository
{
    public function export(): string;
    public function import(string $data): void;
}
```

Implement only the interfaces your class actually needs. A read-only repository implements `ReadRepository` without being forced to implement write or export methods.

---

## 8. Exercises

**Exercise 1:** Refactor a `UserService` class that handles user creation, email notification, and logging into three separate classes following SRP.

**Exercise 2:** Create a `NotificationInterface` with a `send(string $message)` method. Implement `EmailNotification`, `SmsNotification`, and `SlackNotification`. Write a function that accepts the interface (DIP).

**Exercise 3:** Identify which SOLID principle is violated in this code: `class FileLogger extends DatabaseLogger`. (Hint: a file logger is not a database logger.)

---

## 9. Solutions

**Solution for Exercise 1:**

```php
class UserCreator { public function create(array $data): User { /* ... */ } }
class UserNotifier { public function sendWelcomeEmail(User $user): void { /* ... */ } }
class UserLogger { public function logCreation(User $user): void { /* ... */ } }
```

**Solution for Exercise 2:**

```php
interface NotificationInterface { public function send(string $message): void; }
class EmailNotification implements NotificationInterface { public function send(string $message): void { echo "Email: $message\n"; } }
class SmsNotification implements NotificationInterface { public function send(string $message): void { echo "SMS: $message\n"; } }

function notify(NotificationInterface $notifier, string $msg): void { $notifier->send($msg); }
notify(new EmailNotification(), 'Hello!');
notify(new SmsNotification(), 'Hello!');
```

**Solution for Exercise 3:** LSP is violated. `FileLogger` is not a `DatabaseLogger`. They should both implement a `LoggerInterface` instead of using inheritance.

---

## 10. Next Up - Lesson 3

SOLID principles guide good object-oriented design. SRP keeps classes focused on one responsibility. OCP allows extending behavior without modifying existing code. LSP ensures subclasses are true substitutes. ISP keeps interfaces small and focused. DIP makes high-level modules depend on abstractions, not on concrete implementations. Every design pattern in this course embodies one or more of these principles.

In Lesson 3, you will learn the first creational pattern: Singleton, which ensures a class has exactly one instance and provides a global access point to it throughout the application's lifetime.