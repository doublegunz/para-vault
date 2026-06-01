---
title: "Getting Started with PHP Enums: A Practical Guide for Beginners"
slug: "getting-started-with-php-enums-a-practical-guide-for-beginners"
category: "php"
date: "2026-04-12"
status: "published"
---

You are building an order management system, and you need to track the status of each order. So you start with something simple: a plain string. An order can be `"pending"`, `"processing"`, `"shipped"`, or `"delivered"`. It works, until it does not.

A teammate writes `"Pending"` instead of `"pending"`. Another writes `"ship"` instead of `"shipped"`. Your IDE cannot warn you, your code cannot catch it until runtime, and suddenly a bug slips into production over a typo. The deeper the project grows, the more these magic strings scatter across controllers, views, and database queries. Tracking them all down becomes a maintenance nightmare.

PHP 8.1 introduced native **Enums** to solve exactly this problem. An enum lets you define a fixed set of named values that are type-safe, autocomplete-friendly, and centralized in one place. No more magic strings, no more silent bugs from typos. In this guide, you will build a small order status system from scratch using pure PHP, so you can feel exactly how enums make your code cleaner and safer.

---

## Overview {#overview}

Before diving into code, here is a quick picture of what you will accomplish in this guide.

**What You'll Build**

A simple PHP order status system that uses enums to represent and manage order states, complete with helper methods and a demonstration script you can run directly in your browser.

**What You'll Learn**

- What PHP enums are and why they exist
- The difference between Pure Enums and Backed Enums
- How to add methods inside an enum class
- How to use an enum as a type hint in another class
- How to use built-in enum utilities like `cases()`, `from()`, and `tryFrom()`

**What You'll Need**

- PHP 8.1 or higher installed on your machine
- A terminal or command prompt
- Any text editor or IDE (VS Code, PhpStorm, etc.)

---

## Understanding PHP Enum {#understanding-php-enum}

An enum, short for enumeration, is a special type that represents a collection of named constants. Think of it as a way to say: "this variable can only ever be one of these specific values, and nothing else."

Before enums existed in PHP, developers typically used class constants or plain strings to represent fixed sets of values. The problem is that PHP had no built-in way to enforce those values at the type level. You could accidentally pass any string to a function expecting a status, and PHP would happily accept it.

With enums, PHP knows exactly which values are valid. If you try to use a value outside the defined cases, PHP throws an error immediately, before the bug can cause damage deeper in your application.

### Pure Enum vs Backed Enum

PHP 8.1 offers two flavors of enums, and understanding the difference is important before writing any code.

A **Pure Enum** defines named cases with no underlying value attached. Each case is simply a label. Use a pure enum when the value itself does not need to be stored anywhere, for example when you only need to compare states in memory.

A **Backed Enum** attaches a scalar value, either a `string` or an `int`, to each case. This is the type you will use most often in real applications, because it lets you save the enum value to a database, read it from a form input, or pass it through an API. In this guide, you will start with a pure enum to understand the concept, then convert it to a backed enum as the project grows.

---

## Hands-on: Build a Simple Order Status System {#hands-on}

The goal is to build a small, self-contained PHP project with three files: the enum definition, an `Order` class that uses it, and an `index.php` that ties everything together and displays output in the browser.

### Step 1: Create the Project Structure

Open your terminal and create a new project folder. All files in this tutorial will live inside it.

```bash
mkdir php-enum-demo
cd php-enum-demo
```

You should now be inside the `php-enum-demo` folder. This is where all your files will go.

### Step 2: Create the Enum File

Create a new file called `OrderStatus.php` inside the project folder. This file will hold your enum definition.

```php
<?php

// We define an enum using the `enum` keyword, just like you would use `class`.
// For now, this is a Pure Enum — no backing type is declared yet.
enum OrderStatus
{
    case PENDING;
    case PROCESSING;
    case SHIPPED;
    case DELIVERED;
    case CANCELLED;
}
```

Each `case` inside the enum is a named constant. Notice that unlike class constants, you do not assign a value here. In a pure enum, `OrderStatus::PENDING` is not a string or an integer — it is an instance of `OrderStatus` itself.

Save the file as `OrderStatus.php`.

### Step 3: Use the Pure Enum

Create a new file called `index.php`. You will use this file to test your enum and run the demo.

```php
<?php

require_once 'OrderStatus.php';

// Assigning an enum case to a variable.
// $status is now an instance of OrderStatus, not a string.
$status = OrderStatus::PENDING;

// You can compare enum cases directly using ===
if ($status === OrderStatus::PENDING) {
    echo "The order is pending." . PHP_EOL;
}

// The `match` expression works beautifully with enums,
// because enum cases are singletons — each case is exactly one object.
$message = match ($status) {
    OrderStatus::PENDING    => "Waiting for confirmation.",
    OrderStatus::PROCESSING => "Your order is being prepared.",
    OrderStatus::SHIPPED    => "Your order is on its way.",
    OrderStatus::DELIVERED  => "Your order has been delivered.",
    OrderStatus::CANCELLED  => "Your order was cancelled.",
};

echo $message . PHP_EOL;
```

The `match` expression is the natural partner of enums. Because PHP guarantees only the defined cases exist, `match` can be exhaustive — you can handle every possible state without worrying about unexpected values slipping through.

Save `index.php`, then run index.php in the terminal to test it

```bash
php index.php 
```

The terminal will display the following output:

```
The order is pending.
Waiting for confirmation.
```

Great, the pure enum works. Now it is time to make it more practical.

### Step 4: Convert to a Backed Enum

In a real application, you need to save the order status to a database or read it from a request payload. A pure enum cannot do this on its own because its cases have no underlying scalar value. This is where a **Backed Enum** comes in.

Open `OrderStatus.php` and update it to add a backing type. You add the type right after the enum name with a colon, and then assign a string value to each case.

```php
<?php

// Adding `: string` makes this a Backed Enum.
// Each case is now mapped to a specific string value.
enum OrderStatus: string
{
    case PENDING    = 'pending';
    case PROCESSING = 'processing';
    case SHIPPED    = 'shipped';
    case DELIVERED  = 'delivered';
    case CANCELLED  = 'cancelled';
}
```

The string value on the right (e.g., `'pending'`) is what you would store in a database column. The case name on the left (e.g., `PENDING`) is what you use in your PHP code. This separation is powerful: your code stays readable while your stored data stays clean and predictable.

Now update `index.php` to demonstrate working with backed enum values:

```php
<?php

require_once 'OrderStatus.php';

$status = OrderStatus::SHIPPED;

// Access the underlying string value with ->value
echo "Status value: " . $status->value . PHP_EOL; // shipped

// Convert a string (e.g., from a database) back to an enum using from()
// from() throws a ValueError if the string does not match any case
$fromDb = OrderStatus::from('processing');
echo "From DB: " . $fromDb->name . PHP_EOL; // PROCESSING

// Use tryFrom() when the value might not be valid — it returns null instead of throwing
$unknown = OrderStatus::tryFrom('refunded');
echo "Unknown status: " . ($unknown === null ? "not found" : $unknown->value) . PHP_EOL;
```

Save the file again, then run the script in the terminal using the following command:

```
php index.php
```
Output:
```
Status value: shipped
From DB: PROCESSING
Unknown status: not found
```

Notice the difference between `from()` and `tryFrom()`. Use `from()` when you are certain the value is valid, such as when reading from your own controlled database. Use `tryFrom()` when the value comes from user input or an external source, where an invalid value is possible.

### Step 5: Add Helper Methods to the Enum

One of the most powerful features of PHP enums is that they can contain methods, just like a class. This lets you keep all the logic related to a specific case in one place, instead of scattering `if` statements across your controllers.

Open `OrderStatus.php` and add two methods: `label()` for a human-readable display name, and `color()` for a UI badge color.

```php
<?php

enum OrderStatus: string
{
    case PENDING    = 'pending';
    case PROCESSING = 'processing';
    case SHIPPED    = 'shipped';
    case DELIVERED  = 'delivered';
    case CANCELLED  = 'cancelled';

    // label() returns a human-friendly display name for each status.
    // Using match($this) lets each case describe its own label.
    public function label(): string
    {
        return match ($this) {
            self::PENDING    => 'Pending',
            self::PROCESSING => 'Processing',
            self::SHIPPED    => 'Shipped',
            self::DELIVERED  => 'Delivered',
            self::CANCELLED  => 'Cancelled',
        };
    }

    // color() returns a CSS class or color string useful for UI badges.
    // All the display logic lives here, not in your view or controller.
    public function color(): string
    {
        return match ($this) {
            self::PENDING    => 'gray',
            self::PROCESSING => 'blue',
            self::SHIPPED    => 'yellow',
            self::DELIVERED  => 'green',
            self::CANCELLED  => 'red',
        };
    }
}
```

By putting `label()` and `color()` directly inside the enum, you follow a key software design principle: the enum knows everything about itself. Your controller does not need to know that `"shipped"` maps to the color `"yellow"`. It just calls `$status->color()` and gets the answer.

### Step 6: Create the Order Class

Now create a new file called `Order.php`. This class represents a simple order that holds an `OrderStatus` enum as one of its properties.

```php
<?php

require_once 'OrderStatus.php';

class Order
{
    // Using the enum as a type hint means PHP will reject any value
    // that is not a valid OrderStatus instance. This is type safety in action.
    public function __construct(
        public int $id,
        public string $customerName,
        public OrderStatus $status = OrderStatus::PENDING
    ) {}

    // A simple method to update the status.
    // Because $newStatus is type-hinted as OrderStatus,
    // you can only pass a valid enum case here.
    public function updateStatus(OrderStatus $newStatus): void
    {
        $this->status = $newStatus;
    }

    // Display a formatted summary of the order.
    public function summary(): string
    {
        return sprintf(
            "Order #%d for %s | Status: %s (%s) | Color: %s",
            $this->id,
            $this->customerName,
            $this->status->label(),
            $this->status->value,
            $this->status->color()
        );
    }
}
```

Notice how `OrderStatus` is used as the type hint for both the constructor parameter and the `updateStatus()` method. PHP will now enforce at the language level that only a valid `OrderStatus` case can be assigned to these parameters.

Save `Order.php`.

### Step 7: Wire Everything Together

Now update `index.php` to use the `Order` class and demonstrate the full flow, including listing all available statuses using `cases()`.

```php
<?php

require_once 'OrderStatus.php';
require_once 'Order.php';

// Create a new order — status defaults to PENDING
$order = new Order(id: 1, customerName: 'Alice');
echo $order->summary() . PHP_EOL;

// Update the status to SHIPPED
$order->updateStatus(OrderStatus::SHIPPED);
echo $order->summary() . PHP_EOL;

// cases() returns an array of all defined enum cases.
// This is useful for generating dropdowns or lists in a UI.
echo PHP_EOL . "All available statuses:" . PHP_EOL;
foreach (OrderStatus::cases() as $case) {
    echo "- [{$case->color()}] {$case->label()} (value: {$case->value})" . PHP_EOL;
}
```

Save the file again, then run the script in the terminal using the following command.

```
php index.php
```

```
Order #1 for Alice | Status: Pending (pending) | Color: gray
Order #1 for Alice | Status: Shipped (shipped) | Color: yellow

All available statuses:
- [gray] Pending (value: pending)
- [blue] Processing (value: processing)
- [yellow] Shipped (value: shipped)
- [green] Delivered (value: delivered)
- [red] Cancelled (value: cancelled)
```

Your enum-powered order system is fully working. Every status is centralized, type-safe, and carries its own display logic.

---

## How PHP Enum Works Under the Hood {#how-enum-works}

Now that you have seen enums in action, it is worth understanding a few important things about how they actually behave in PHP. This knowledge will help you avoid confusion and use enums more confidently.

### Enum Cases Are Objects, Not Scalars

In a pure enum, each case is a singleton object — there is exactly one instance of `OrderStatus::PENDING` in the entire application. This is why you can safely compare cases with `===`. When you write `$status === OrderStatus::PENDING`, PHP is comparing object identity, and because each case is a singleton, this comparison always works correctly.

In a backed enum, the case is still an object, but it carries a `->value` property that holds the underlying scalar. The `->name` property, available on both pure and backed enums, gives you the case name as a string (e.g., `"PENDING"`).

### The Three Key Utilities: `cases()`, `from()`, and `tryFrom()`

PHP provides three built-in tools for working with enums programmatically.

`cases()` is a static method available on every enum. It returns an array of all defined cases, which is perfect for generating a list of options in a UI or iterating over all valid values.

`from()` is available on backed enums. It takes a scalar value and returns the matching enum case. If the value does not match any case, it throws a `ValueError`. Use this when you trust the source of the data.

`tryFrom()` is the safe version of `from()`. Instead of throwing an error, it returns `null` when no matching case is found. Use this when processing user input or data from external sources where an invalid value is possible.

### Enums Can Implement Interfaces

PHP enums can implement interfaces, which opens up powerful design patterns. For example, you could define a `HasLabel` interface that requires a `label()` method, then implement it on multiple enums across your project. This ensures consistency when you have several enums that all need display-friendly labels. The enum syntax for implementing an interface is identical to a class: `enum OrderStatus: string implements HasLabel`.

### When to Use Pure vs Backed

Use a **pure enum** when the values only need to exist in memory and never need to be serialized or stored. Use a **backed enum** whenever you need to persist the value, read it from a database, accept it from a form or API, or pass it as a URL parameter. In most real-world PHP applications, backed enums with a `string` type are the most common choice.

---

## What About Laravel? {#enum-in-laravel}

Everything you have learned in this guide applies directly to Laravel with almost no changes. Laravel 9 and above has first-class support for PHP native enums, and several framework features are built specifically to work with them.

In a Laravel application, you can register an enum in a model's `$casts` array so that Eloquent automatically converts the database string into an enum object when you retrieve a record, and converts it back when you save. Laravel also ships with a built-in `Enum` validation rule, so you can validate incoming request data against a specific enum class in a single line. For API development, you can expose enum values with their labels and colors through API Resources, giving your frontend everything it needs without hardcoding any mappings on the client side.

A future article on qadrlabs will walk through the full Laravel implementation, covering migrations, model casting, form validation, Blade views, and API responses.

---

## Conclusion {#conclusion}

Throughout this guide, you went from an unreliable magic string to a clean, type-safe enum-powered system. You built a pure enum, converted it to a backed enum, added helper methods, used it as a type hint in a class, and explored the built-in utilities that PHP provides. That is a solid foundation for using enums confidently in any PHP project.

**Key Takeaways**

- PHP 8.1 enums replace magic strings and constants with a type-safe, centralized definition of valid values.
- Pure enums have no underlying scalar value; backed enums map each case to a `string` or `int`, making them suitable for database storage and serialization.
- Enum cases are singleton objects — you can safely compare them with `===` and use them directly in `match` expressions.
- Methods like `label()` and `color()` belong inside the enum class, not scattered across controllers or views, keeping your codebase clean and consistent.
- `cases()` gives you all defined cases as an array, `from()` converts a scalar to an enum (or throws on failure), and `tryFrom()` does the same but returns `null` instead of throwing.
- Using an enum as a type hint in a class or method means PHP enforces valid values at the language level, catching bugs before they reach production.

**What's Next**

Now that you understand how PHP enums work at the core level, here are a few directions to explore next.

- **PHP Interfaces with Enums** — since enums can implement interfaces, learning how PHP interfaces work will help you design more flexible and consistent enum-based systems across a larger codebase.
- [**PHP Enums in Laravel**](https://qadrlabs.com/post/refactoring-magic-strings-to-php-enums-in-laravel-13) — the upcoming qadrlabs article will cover how to integrate enums into a full Laravel application, including Eloquent casting, form validation with the `Enum` rule, Blade dropdowns, and API Resources.
- **PHP Official Documentation** — the [PHP 8.1 Enums reference](https://www.php.net/manual/en/language.enumerations.php) is thorough and well-written, and is the authoritative source for edge cases and advanced features like enum constants and interface implementations.