## 1. Before You Begin

When your code creates objects directly with `new`, it becomes tightly coupled to specific classes. If you later need a different implementation (a different payment gateway, a different notification channel), you must modify every place that creates the object. **Factory patterns** solve this by encapsulating object creation: the calling code asks for an object through an interface, and the factory decides which concrete class to instantiate. This lesson covers two related patterns: Factory Method, which delegates object creation to subclasses, and Abstract Factory, which creates families of related objects. Both follow the Open/Closed Principle — adding new product types requires zero changes to existing code.

### What You'll Build

You will build a notification system (Factory Method) and a cross-platform UI component factory (Abstract Factory).

### What You'll Learn

- ✅ Factory Method: delegate object creation to subclasses
- ✅ Abstract Factory: create families of related objects
- ✅ The difference between the two patterns
- ✅ When to use Factory Method vs Abstract Factory
- ✅ Static factory methods (Simple Factory)
- ✅ Factory patterns in Laravel

### What You'll Need

- Lesson 3 completed

---

## 2. Factory Method

The Factory Method defines an interface for creating objects, but lets subclasses decide which class to instantiate. The superclass works with the product through an interface; the specific product type is determined by the subclass.

### The Problem

You are building a notification system. Today you only send emails. Tomorrow you need SMS and push notifications. Without a factory, every caller creates `new EmailNotification()` directly, and adding SMS requires modifying every caller.

### The Implementation

Create the product interface, concrete products, an abstract creator, and concrete creators. Each creator subclass overrides the factory method to return the appropriate notification type:

```php
<?php
namespace App\Creational\FactoryMethod;

// Product interface
interface Notification
{
    public function send(string $to, string $message): void;
}

// Concrete products
class EmailNotification implements Notification
{
    public function send(string $to, string $message): void
    {
        echo "[Email] To: {$to} | Message: {$message}\n";
    }
}

class SmsNotification implements Notification
{
    public function send(string $to, string $message): void
    {
        echo "[SMS] To: {$to} | Message: {$message}\n";
    }
}

class PushNotification implements Notification
{
    public function send(string $to, string $message): void
    {
        echo "[Push] To: {$to} | Message: {$message}\n";
    }
}

// Creator (abstract): declares the factory method
abstract class NotificationCreator
{
    // Factory method: subclasses decide which Notification to create
    abstract protected function createNotification(): Notification;

    // Business logic that uses the product
    public function notify(string $to, string $message): void
    {
        $notification = $this->createNotification();
        $notification->send($to, $message);
    }
}

// Concrete creators
class EmailNotificationCreator extends NotificationCreator
{
    protected function createNotification(): Notification { return new EmailNotification(); }
}

class SmsNotificationCreator extends NotificationCreator
{
    protected function createNotification(): Notification { return new SmsNotification(); }
}

class PushNotificationCreator extends NotificationCreator
{
    protected function createNotification(): Notification { return new PushNotification(); }
}
```

Usage:

```php
function sendAlert(NotificationCreator $creator, string $to, string $msg): void
{
    $creator->notify($to, $msg);
}

sendAlert(new EmailNotificationCreator(), 'admin@example.com', 'Server is down!');
sendAlert(new SmsNotificationCreator(), '+62812345', 'Server is down!');
sendAlert(new PushNotificationCreator(), 'device-token-123', 'Server is down!');
```

Adding a new notification type (e.g., WhatsApp) requires creating two classes: `WhatsAppNotification` and `WhatsAppNotificationCreator`. Zero changes to existing code. OCP satisfied.

---

## 3. Simple Factory (Static Factory Method)

A simpler variant: a static method that decides which class to create based on a parameter. This is not the GoF Factory Method but is extremely common in PHP.

```php
class NotificationFactory
{
    public static function create(string $channel): Notification
    {
        return match ($channel) {
            'email' => new EmailNotification(),
            'sms'   => new SmsNotification(),
            'push'  => new PushNotification(),
            default => throw new \InvalidArgumentException("Unknown channel: {$channel}"),
        };
    }
}

$notification = NotificationFactory::create('email');
$notification->send('user@example.com', 'Hello!');
```

---

## 4. Abstract Factory

The Abstract Factory creates families of related objects without specifying their concrete classes. Each factory implementation produces a complete set of related products.

### The Problem

You are building a UI toolkit that supports different themes: Light and Dark. Each theme has its own Button, Input, and Card styles. You need a way to create a complete set of themed components.

```php
<?php
namespace App\Creational\AbstractFactory;

// Abstract products
interface Button { public function render(): string; }
interface Input { public function render(): string; }
interface Card { public function render(): string; }

// Light theme products
class LightButton implements Button { public function render(): string { return '<button class="btn-light">Click</button>'; } }
class LightInput implements Input { public function render(): string { return '<input class="input-light" />'; } }
class LightCard implements Card { public function render(): string { return '<div class="card-light">Content</div>'; } }

// Dark theme products
class DarkButton implements Button { public function render(): string { return '<button class="btn-dark">Click</button>'; } }
class DarkInput implements Input { public function render(): string { return '<input class="input-dark" />'; } }
class DarkCard implements Card { public function render(): string { return '<div class="card-dark">Content</div>'; } }

// Abstract factory
interface UIFactory
{
    public function createButton(): Button;
    public function createInput(): Input;
    public function createCard(): Card;
}

// Concrete factories
class LightThemeFactory implements UIFactory
{
    public function createButton(): Button { return new LightButton(); }
    public function createInput(): Input { return new LightInput(); }
    public function createCard(): Card { return new LightCard(); }
}

class DarkThemeFactory implements UIFactory
{
    public function createButton(): Button { return new DarkButton(); }
    public function createInput(): Input { return new DarkInput(); }
    public function createCard(): Card { return new DarkCard(); }
}

// Client code: works with any factory
function renderForm(UIFactory $factory): void
{
    echo $factory->createCard()->render() . "\n";
    echo $factory->createInput()->render() . "\n";
    echo $factory->createButton()->render() . "\n";
}

renderForm(new LightThemeFactory());
renderForm(new DarkThemeFactory());
```

---

## 5. Factory Method vs Abstract Factory

Both patterns create objects through interfaces, but they serve different purposes.

| Aspect | Factory Method | Abstract Factory |
|--------|---------------|-----------------|
| Creates | One product type | Family of related products |
| Mechanism | Subclass overrides a method | Factory object creates products |
| Use case | "I need a notification" | "I need a complete themed UI" |
| Adding products | New creator subclass | New factory + product classes |

Use Factory Method when you need one product type. Use Abstract Factory when you need a consistent family of related products.

---

## 6. Fix the Errors in Your Code

These are the three most common factory pattern mistakes in PHP codebases.

**Error 1: Factory method returns a concrete type instead of the interface.**

When the return type is a concrete class, the caller becomes coupled to that class. The entire purpose of the factory is to return the abstraction so the caller never depends on concrete types.

```php
// Wrong: return type is a concrete class, not the interface
class NotificationFactory
{
    public static function create(): EmailNotification { ... }
}

// Correct: return type is the interface
class NotificationFactory
{
    public static function create(): Notification { ... }
}
```

Always type the return value as the interface (`Notification`), not the concrete class (`EmailNotification`).

**Error 2: Modifying the factory for every new type (violates OCP).**

A simple `if/elseif` or `match` inside the factory means adding a new type requires editing the factory class. This violates the Open/Closed Principle because the factory is not closed for modification.

```php
// Wrong: every new type requires editing this method
public static function create(string $type): Notification
{
    if ($type === 'email') return new EmailNotification();
    if ($type === 'sms') return new SmsNotification();
    // Adding WhatsApp requires modifying this class!
}

// Correct: use the Factory Method pattern with subclasses,
// or a registry that allows new types to be added externally
public static function register(string $channel, string $class): void
{
    static::$registry[$channel] = $class;
}
```

Use subclasses (Factory Method) or a registry (Section 3) so new types can be added without touching existing factory code.

**Error 3: Abstract Factory creating unrelated products.**

An Abstract Factory must produce a coherent family of related objects. If the factory mixes unrelated concerns, it creates hidden coupling between things that should be independent.

```php
// Wrong: UIFactory creates a database connection — unrelated to UI
interface UIFactory
{
    public function createButton(): Button;
    public function createDatabase(): Database;
}

// Correct: the factory creates only UI-related products
interface UIFactory
{
    public function createButton(): Button;
    public function createInput(): Input;
    public function createCard(): Card;
}
```

Keep each Abstract Factory focused on one family of related objects. If you need both UI and database objects, create two separate factories.

---

## 7. Exercises

**Exercise 1:** Create a `LoggerFactory` with a static `create(string $type)` method that returns `FileLogger`, `DatabaseLogger`, or `ConsoleLogger`, all implementing a `LoggerInterface`.

**Exercise 2:** Create an Abstract Factory for document export: `PdfExporter`, `CsvExporter`, `XlsxExporter`. Each factory creates `Header`, `Body`, and `Footer` objects styled for its format.

**Exercise 3:** Refactor the `NotificationFactory` to use a registry (associative array) instead of match/if-else, so new types can be registered at runtime.

---

## 8. Solutions

**Solution for Exercise 3:**

```php
class NotificationFactory
{
    private static array $registry = [];

    public static function register(string $channel, string $class): void
    {
        static::$registry[$channel] = $class;
    }

    public static function create(string $channel): Notification
    {
        if (!isset(static::$registry[$channel])) {
            throw new \InvalidArgumentException("Unknown: {$channel}");
        }
        return new (static::$registry[$channel])();
    }
}

NotificationFactory::register('email', EmailNotification::class);
NotificationFactory::register('sms', SmsNotification::class);
$n = NotificationFactory::create('email');
```

---

## 9. Next Up - Lesson 5

Factory Method delegates object creation to subclasses through an overridable method. Abstract Factory creates families of related objects through a factory interface. The Simple Factory (static method) is the most common variant in PHP. All factory patterns decouple the client from concrete classes, following OCP and DIP. Laravel's service container uses factory patterns internally to resolve dependencies.

In Lesson 5, you will learn the Builder pattern: a way to construct complex objects step by step using a fluent interface, avoiding the unreadable constructor with many parameters.