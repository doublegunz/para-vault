## 1. Before You Begin

Sometimes creating an object from scratch is expensive: it requires loading data from a database, parsing a file, or performing complex calculations. If you already have a similar object, it would be faster to **clone** it and modify only the differences. The **Prototype** pattern creates new objects by copying an existing object (the prototype). This lesson covers the Prototype pattern using PHP's built-in `clone` keyword and the `__clone()` magic method for controlling deep copy behavior.

### What You'll Build

You will create a document template system and a game entity spawner that use cloning instead of construction.

### What You'll Learn

- ✅ The Prototype pattern: intent and structure
- ✅ PHP's `clone` keyword and shallow vs deep copy
- ✅ The `__clone()` magic method for deep cloning
- ✅ Prototype registry for managing prototypes
- ✅ When to use Prototype vs Factory

### What You'll Need

- Lesson 5 completed

---

## 2. The Problem

You have a document template with complex formatting, styles, and metadata. Creating each document from scratch (loading styles, setting defaults) takes time. It is faster to clone the template and change only what differs (title, content).

---

## 3. Implementation

Create a `Document` class with a `__clone()` method that handles deep copy behavior. The `DocumentRegistry` acts as a prototype registry — it stores named templates and produces clones on demand:

```php
<?php
namespace App\Creational\Prototype;

class Document
{
    private array $styles;
    private array $metadata;

    public function __construct(
        private string $title,
        private string $content,
        array $styles = [],
        array $metadata = [],
    ) {
        $this->styles = $styles ?: ['font' => 'Arial', 'size' => 12, 'color' => '#333'];
        $this->metadata = $metadata ?: ['author' => 'System', 'version' => '1.0'];
    }

    // Deep clone: ensure nested arrays/objects are independent copies
    public function __clone(): void
    {
        // Arrays are copied by value in PHP, so this is already safe.
        // For objects: $this->relatedObject = clone $this->relatedObject;
        $this->metadata['created_at'] = date('Y-m-d H:i:s');
    }

    public function setTitle(string $title): void { $this->title = $title; }
    public function setContent(string $content): void { $this->content = $content; }

    public function __toString(): string
    {
        return sprintf(
            "[%s] %s\nContent: %s\nFont: %s %dpt\nAuthor: %s",
            $this->metadata['created_at'] ?? 'N/A', $this->title, $this->content,
            $this->styles['font'], $this->styles['size'], $this->metadata['author']
        );
    }
}

// Prototype registry
class DocumentRegistry
{
    private array $prototypes = [];

    public function register(string $name, Document $prototype): void
    {
        $this->prototypes[$name] = $prototype;
    }

    public function create(string $name): Document
    {
        if (!isset($this->prototypes[$name])) {
            throw new \RuntimeException("Unknown template: {$name}");
        }
        return clone $this->prototypes[$name];
    }
}
```

Usage:

```php
// Register templates
$registry = new DocumentRegistry();
$registry->register('report', new Document('Report Template', 'Enter report content here.'));
$registry->register('memo', new Document('Memo Template', 'Enter memo content.', ['font' => 'Courier', 'size' => 10, 'color' => '#000']));

// Create documents from templates (clone, not construct)
$report1 = $registry->create('report');
$report1->setTitle('Q1 Financial Report');
$report1->setContent('Revenue increased by 15% in Q1 2026.');

$report2 = $registry->create('report');
$report2->setTitle('Q2 Financial Report');
$report2->setContent('Revenue stabilized in Q2 2026.');

echo $report1 . "\n\n" . $report2;
```

---

## 4. Shallow vs Deep Copy

PHP's `clone` creates a **shallow copy**: primitive properties are copied by value, but object properties are copied by reference (both the original and clone point to the same nested object).

```php
class Page
{
    public function __construct(public string $title, public Author $author) {}

    // Without __clone: $clone->author === $original->author (same object!)
    public function __clone(): void
    {
        $this->author = clone $this->author;  // Deep copy
    }
}
```

Always implement `__clone()` when your object contains other objects.

---

## 5. Fix the Errors in Your Code

These are the three most common Prototype pattern mistakes in PHP codebases.

**Error 1: Forgetting to deep clone nested objects.**

PHP's `clone` creates a shallow copy: primitive properties are copied by value, but object properties are copied by reference. Without `__clone()`, both the original and the clone share the same nested object, so modifying one affects the other.

```php
// Wrong: Order and Customer are cloned, but $customer inside is still shared
class Order
{
    public function __construct(public array $items, public Customer $customer) {}
}
$clone = clone $order;
$clone->customer->name = 'Changed'; // also changes $order->customer->name!

// Correct: deep clone nested objects in __clone()
class Order
{
    public function __construct(public array $items, public Customer $customer) {}
    public function __clone(): void
    {
        $this->customer = clone $this->customer;
    }
}
```

Always implement `__clone()` when your object contains other objects. Clone each nested object property individually.

**Error 2: Cloning immutable objects unnecessarily.**

If an object is immutable (all properties are `readonly`), cloning it and modifying properties is impossible. Cloning immutable objects wastes memory without any benefit.

```php
// Wrong: cloning a readonly object just to read it
class Config
{
    public function __construct(public readonly string $name) {}
}
$clone = clone $config; // identical copy, waste of memory

// Correct: just share the reference — immutable objects are safe to share
$sharedConfig = $config;
```

Clone only mutable objects. For immutable objects, sharing the reference is safe and more efficient.

**Error 3: Prototype and Singleton are incompatible.**

Singleton uses a private constructor to prevent external instantiation. But Prototype requires cloning, and `clone` calls `__clone()` on an already-constructed instance — the two patterns conflict fundamentally.

```php
// Wrong: trying to clone a Singleton
class Singleton
{
    private static ?Singleton $instance = null;
    private function __construct() {}
    public static function getInstance(): static { return static::$instance ??= new static(); }
}
$copy = clone Singleton::getInstance(); // creates a second instance!
// If __clone is public (default), this breaks the Singleton guarantee.

// Correct: add private __clone() to every Singleton class
private function __clone(): void {}
```

Never apply Prototype to a Singleton. If an object must be both unique and cloneable, reconsider the design — the two constraints are mutually exclusive.

---

## 6. Exercises

**Exercise 1:** Create a `GameEntity` class with name, health, position (object), and inventory (array). Implement `__clone()` for deep copy. Clone a "warrior template" and customize each clone.

**Exercise 2:** Create a `StyleSheet` prototype with font, colors, and margins. Register "minimal" and "corporate" templates. Create documents using each.

**Exercise 3:** Compare performance: time creating 1000 objects with `new` vs `clone`. Use `microtime(true)` to measure.

---

## 7. Solutions

**Solution for Exercise 1:**

```php
class Position { public function __construct(public float $x, public float $y) {} }
class GameEntity
{
    public function __construct(public string $name, public int $health, public Position $pos, public array $inventory = []) {}
    public function __clone(): void { $this->pos = clone $this->pos; }
}
$template = new GameEntity('Warrior', 100, new Position(0, 0), ['sword', 'shield']);
$w1 = clone $template; $w1->name = 'Warrior A'; $w1->pos->x = 10;
$w2 = clone $template; $w2->name = 'Warrior B'; $w2->pos->x = 20;
```

---

## 8. Next Up - Lesson 7

Prototype creates objects by cloning an existing instance. PHP's `clone` keyword performs a shallow copy — implement `__clone()` to deep clone any nested objects. A Prototype Registry manages named templates and returns clones on demand. Use Prototype when object construction is expensive and a similar object already exists. Prototype is incompatible with Singleton.

This concludes the Creational Patterns module. In Lesson 7, you will begin Structural Patterns with Adapter and Bridge: two patterns that manage interface differences between classes.