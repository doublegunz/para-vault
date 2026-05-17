---
title: "PHP 8.1 Readonly Properties: Building Immutable Value Objects and DTOs"
slug: "php-81-readonly-properties-building-immutable-value-objects-and-dtos"
category: "php"
date: "2026-04-13"
status: "published"
---

We have a class that holds order data. We pass it from a controller to a service, and then to a repository. Somewhere along the way, a value changes unexpectedly. The total is wrong. The customer name got overwritten. We spend an hour tracing through the call stack trying to figure out who changed what and when.

This is the hidden cost of mutable objects. In PHP, any code that holds a reference to an object can modify its properties at any time. There is no native protection, no warning, and no trail. The larger the project, the more places a value can be changed from, and the harder bugs become to reproduce and fix.

PHP 8.1 introduced `readonly` properties as a native solution to this problem. A readonly property can only be set once, and any attempt to change it afterward throws a fatal error immediately. Combined with constructor property promotion from PHP 8.0, we can build clean, immutable Data Transfer Objects and Value Objects in just a few lines of code, with no boilerplate getters or setters required.

---

## Overview {#overview}

Before writing any code, here is what this guide covers from start to finish.

**What You'll Build**

A small PHP project with three components: a simple class to understand the basics of readonly, a DTO that carries order data between layers, and a `Money` Value Object that enforces its own business rules. We will run everything directly from the terminal using the PHP CLI.

**What You'll Learn**

- What readonly properties are and what rules they enforce
- How constructor property promotion combines with readonly to eliminate boilerplate
- The difference between a DTO and a Value Object, and when to use each
- How to use the wither pattern to "update" an immutable object safely
- The difference between `readonly` properties (PHP 8.1) and `readonly class` (PHP 8.2)

**What You'll Need**

- PHP 8.1 or higher (PHP 8.2 recommended for the `readonly class` syntax)
- A terminal or command prompt
- Any text editor or IDE

---

## Understanding Readonly Properties {#understanding-readonly}

A readonly property is a class property that can only be assigned a value once. After that first assignment, the value is locked. Any subsequent attempt to modify it, whether from outside the class or from within a method inside the class, throws an `Error` immediately.

The key benefit here is not just preventing accidents. It is about making the code's intent explicit. When we see a readonly property, we know immediately that this value represents something that should not change for the lifetime of the object. We can read it, pass it around, and depend on it without fear.

There is one important caveat to understand before writing code: readonly provides **shallow immutability**. This means the property reference itself cannot be replaced, but if the property holds an object, the internals of that nested object can still be modified. We will see a concrete example of this later. For scalar types like `string`, `int`, and `float`, readonly gives full immutability as expected.

### The Rules You Need to Know

PHP enforces four rules on readonly properties that we need to understand before using them.

First, a readonly property must have a declared type. PHP needs a type to distinguish between "not yet initialized" and "set to null", and without a type this distinction would be ambiguous. If a property needs to accept any type, use `mixed` as the type declaration.

Second, a readonly property cannot have a default value set directly on the property declaration. Since the point of readonly is that the value is set exactly once, a default value would essentially make it a constant. The exception is constructor property promotion, where a default value on the parameter applies to the constructor argument, not the property itself.

Third, a readonly property cannot be `unset()` after it has been initialized. Unsetting counts as a modification, and PHP will throw an error.

Fourth, the readonly flag cannot be changed during class inheritance. A child class cannot redeclare a readonly property as non-readonly, and vice versa. This ensures immutability contracts are preserved across an inheritance chain.

---

## Hands-on: Build an Immutable Order System {#hands-on}

We will build three PHP files step by step: a simple class that demonstrates the readonly basics, a DTO for carrying order data, and a `Money` Value Object with its own validation logic. A fourth file, `index.php`, will tie everything together and display the result directly in the terminal.

### Step 1: Create the Project Structure

Open a terminal and create the project folder. All files in this tutorial will live here.

```bash
mkdir php-readonly-demo
cd php-readonly-demo
```

We should now be inside the `php-readonly-demo` folder. This is our working directory for the rest of the tutorial.

### Step 2: Create a Simple Readonly Property

Before using the shorthand syntax, it is worth seeing how readonly properties look in their most explicit form. This makes it easier to understand what the shorthand is actually doing under the hood.

Create a file called `UserProfile.php` and add the following code:

```php
<?php

class UserProfile
{
    // The readonly keyword goes between the visibility modifier and the type.
    // This property can only be assigned once, inside the class.
    public readonly string $name;
    public readonly string $email;

    public function __construct(string $name, string $email)
    {
        // This is the one and only time these properties can be written to.
        $this->name  = $name;
        $this->email = $email;
    }
}
```

In this form, the property is declared separately from the constructor. The `readonly` keyword sits between `public` and the type declaration. The assignment happens inside the constructor body as usual.

Save `UserProfile.php`. Now create `index.php` to test this class:

```php
<?php

require_once 'UserProfile.php';

$user = new UserProfile('Alice', 'alice@example.com');

// Reading a readonly property works just like any public property.
echo "Name: "  . $user->name  . PHP_EOL;
echo "Email: " . $user->email . PHP_EOL;

// Attempting to overwrite a readonly property throws a Fatal Error.
// Uncomment the line below to see the error in action:
// $user->name = 'Bob';
```

Run the script from the terminal to test:

```bash
php index.php
```

We should see:

```
Name: Alice
Email: alice@example.com
```

Now uncomment the `$user->name = 'Bob'` line, save, and run `php index.php` again. PHP will throw:

```
Fatal error: Uncaught Error: Cannot modify readonly property UserProfile::$name
```

This is exactly the protection readonly provides. The error is thrown at runtime the moment a modification is attempted, not silently ignored.

Comment that line back out before moving to the next step.

### Step 3: Refactor Using Constructor Property Promotion

Writing the property declaration and the constructor assignment separately works, but it is repetitive. PHP 8.0 introduced constructor property promotion, which lets you declare and assign a property directly in the constructor signature. Combined with `readonly`, this eliminates almost all the boilerplate.

Open `UserProfile.php` and replace its contents with the promoted version:

```php
<?php

class UserProfile
{
    // Constructor property promotion with readonly.
    // PHP automatically creates the property, declares it as readonly,
    // and assigns the constructor argument to it — all in one line.
    public function __construct(
        public readonly string $name,
        public readonly string $email,
    ) {}
}
```

This is functionally identical to the previous version. The constructor body is now empty because PHP handles the property declaration and assignment automatically. Run `php index.php` again and the output will be exactly the same as before.

This is the syntax we will use for the rest of the tutorial, because it is clean, concise, and expressive.

### Step 4: Build a DTO

A DTO, or Data Transfer Object, is an object whose sole purpose is to carry structured data from one part of your application to another. It does not contain business logic or validation rules. It is just a structured container with a known shape.

Create a file called `CreateOrderDTO.php`. This DTO will represent the data needed to create a new order.

```php
<?php

// The `readonly class` keyword (PHP 8.2) automatically applies readonly
// to every property in the class. You no longer need to write `readonly`
// on each individual property — it is implied for all of them.
readonly class CreateOrderDTO
{
    public function __construct(
        public string $customerName,
        public string $customerEmail,
        public string $shippingAddress,
        public string $status = 'pending',
    ) {}

    // A static factory method lets you build the DTO from an array,
    // which is useful when the data comes from a form submission or an API payload.
    // The DTO itself stays clean — the construction logic lives here.
    public static function fromArray(array $data): self
    {
        return new self(
            customerName:    $data['customer_name'],
            customerEmail:   $data['customer_email'],
            shippingAddress: $data['shipping_address'],
            status:          $data['status'] ?? 'pending',
        );
    }
}
```

A few things to note here. The `readonly class` syntax on line 7 is a PHP 8.2 feature. It is shorthand for writing `public readonly` on every property individually. If you are on PHP 8.1, replace `readonly class` with `class` and add `readonly` to each property in the constructor manually.

The `fromArray()` static factory method is a common pattern for DTOs. The DTO itself stays simple, while the logic for building it from different data sources can live in these named constructors.

Save `CreateOrderDTO.php`.

### Step 5: Build a Value Object

A Value Object is different from a DTO. While a DTO is just a data container with no guarantees about the validity of its contents, a Value Object enforces its own rules. When we hold an instance of a Value Object, we know the data inside it is valid, because the constructor would have thrown an exception otherwise.

Create a file called `Money.php`. This Value Object represents a monetary amount with a currency.

```php
<?php

// Money is a classic Value Object. Two Money instances with the same
// amount and currency are considered equal, regardless of whether
// they are the same object in memory.
readonly class Money
{
    public function __construct(
        public int    $amount,   // stored as the smallest unit, e.g. cents or rupiah
        public string $currency, // ISO 4217 three-letter code, e.g. 'IDR', 'USD'
    ) {
        // Value Objects validate themselves at construction time.
        // If the data does not meet the rules, the object is never created.
        if ($this->amount < 0) {
            throw new \InvalidArgumentException(
                "Amount cannot be negative. Got: {$this->amount}"
            );
        }

        if (strlen($this->currency) !== 3) {
            throw new \InvalidArgumentException(
                "Currency must be a 3-character ISO 4217 code. Got: '{$this->currency}'"
            );
        }
    }

    // The add() method demonstrates the wither pattern.
    // Because Money is immutable, we cannot modify $this->amount directly.
    // Instead, we return a brand new Money instance with the combined value.
    // The original objects remain completely unchanged.
    public function add(Money $other): self
    {
        if ($this->currency !== $other->currency) {
            throw new \LogicException(
                "Cannot add amounts with different currencies: {$this->currency} and {$other->currency}"
            );
        }

        return new self($this->amount + $other->amount, $this->currency);
    }

    // A helper method for display — the display logic lives here,
    // not scattered across views or controllers.
    public function format(): string
    {
        return number_format($this->amount, 0, ',', '.') . ' ' . $this->currency;
    }
}
```

The `add()` method is the most important part of this class. Because `Money` is readonly, you cannot write `$this->amount = $this->amount + $other->amount`. Instead, you create and return a new `Money` instance with the combined value. The original two objects are left untouched. This is the wither pattern: rather than mutating the object, you produce a new one that reflects the desired change.

Save `Money.php`.

### Step 6: Wire Everything Together

Now update `index.php` to demonstrate all three components working together, including a deliberate attempt to modify a readonly property so we can see the protection in action.

```php
<?php

require_once 'UserProfile.php';
require_once 'CreateOrderDTO.php';
require_once 'Money.php';

echo "=== UserProfile ===" . PHP_EOL;

$user = new UserProfile('Alice', 'alice@example.com');
echo "Name: "  . $user->name  . PHP_EOL;
echo "Email: " . $user->email . PHP_EOL;

echo PHP_EOL . "=== CreateOrderDTO ===" . PHP_EOL;

// Build the DTO from an array, simulating data arriving from a form or API.
$orderData = [
    'customer_name'    => 'Budi Santoso',
    'customer_email'   => 'budi@example.com',
    'shipping_address' => 'Jl. Sudirman No. 1, Jakarta',
];

$dto = CreateOrderDTO::fromArray($orderData);

echo "Customer: "  . $dto->customerName    . PHP_EOL;
echo "Email: "     . $dto->customerEmail   . PHP_EOL;
echo "Address: "   . $dto->shippingAddress . PHP_EOL;
echo "Status: "    . $dto->status          . PHP_EOL;

echo PHP_EOL . "=== Money Value Object ===" . PHP_EOL;

$price    = new Money(150000, 'IDR');
$shipping = new Money(20000, 'IDR');

// add() returns a NEW Money object. $price and $shipping are untouched.
$total = $price->add($shipping);

echo "Price:    " . $price->format()    . PHP_EOL; // 150.000 IDR
echo "Shipping: " . $shipping->format() . PHP_EOL; // 20.000 IDR
echo "Total:    " . $total->format()    . PHP_EOL; // 170.000 IDR

// Confirm the originals are unchanged after add().
echo PHP_EOL . "After add(), original price is still: " . $price->format() . PHP_EOL;

echo PHP_EOL . "=== Readonly Protection in Action ===" . PHP_EOL;

// Wrapping in try-catch so the rest of the page can still render.
try {
    // This will throw a Fatal Error because $dto->status is readonly.
    $dto->status = 'shipped';
} catch (\Error $e) {
    echo "Caught error: " . $e->getMessage() . PHP_EOL;
}

echo PHP_EOL . "=== Invalid Money (Negative Amount) ===" . PHP_EOL;

try {
    // This will throw an InvalidArgumentException from inside the constructor.
    $bad = new Money(-500, 'IDR');
} catch (\InvalidArgumentException $e) {
    echo "Caught error: " . $e->getMessage() . PHP_EOL;
}
```

Save `index.php`.

### Step 7: Run and Test

Make sure we are inside the `php-readonly-demo` folder in the terminal, then run:

```bash
php index.php
```

We should see:

```
=== UserProfile ===
Name: Alice
Email: alice@example.com

=== CreateOrderDTO ===
Customer: Budi Santoso
Email: budi@example.com
Address: Jl. Sudirman No. 1, Jakarta
Status: pending

=== Money Value Object ===
Price:    150.000 IDR
Shipping: 20.000 IDR
Total:    170.000 IDR

After add(), original price is still: 150.000 IDR

=== Readonly Protection in Action ===
Caught error: Cannot modify readonly property CreateOrderDTO::$status

=== Invalid Money (Negative Amount) ===
Caught error: Amount cannot be negative. Got: -500
```

Every section confirms a different guarantee. The DTO carries data without modification. The `Money` Value Object rejects invalid input at construction time. The wither pattern in `add()` produces a new object while leaving the originals intact. And the readonly protection kicks in immediately when a modification is attempted.

---

## DTO vs Value Object: What is the Difference? {#dto-vs-vo}

Now that we have built both, it is worth taking a moment to understand the conceptual difference between a DTO and a Value Object, because they look similar in code but serve different purposes.

A **DTO** is a structured data container. Its job is to carry data from one layer of an application to another with a known, explicit shape. A DTO says: "these fields exist, and they have these types." It does not say anything about whether the values are meaningful from a business perspective. An empty string is a valid `string`, and a DTO will accept it without complaint. DTOs live at the edges of an application, where data enters or exits, such as when receiving a form submission or returning an API response.

A **Value Object** is a representation of a domain concept. It not only defines what fields exist, but also enforces that the combination of those fields makes sense within the rules of the business. A `Money` object with a negative amount is not a valid monetary concept, so the constructor rejects it. A Value Object says: "if I exist, my data is valid." This is a guarantee a DTO does not provide. Value Objects are used inside the domain logic, wherever a concept carries meaning and rules of its own.

| | DTO | Value Object |
|---|---|---|
| Purpose | Transfer data between layers | Represent a domain concept |
| Validation | None (structure only) | Enforced in constructor |
| Business logic | None | Can have methods like `add()`, `format()` |
| Identity | Not applicable | Defined entirely by its value |
| Typical examples | `CreateOrderDTO`, `UserPayload` | `Money`, `Email`, `Coordinate` |
| Must be immutable? | Ideally yes | Always |

The practical rule: use a DTO when you need to move data around cleanly. Use a Value Object when a concept in your domain has its own validity rules or behavior.

---

## How Readonly Works Under the Hood {#how-readonly-works}

With the hands-on part complete, there are a few important mechanics worth understanding more deeply.

### Readonly is Shallow, Not Deep

Readonly prevents a property from being reassigned, but it does not freeze the object that a property points to. Consider a class with a readonly property that holds an array or an object. We cannot replace the array with a new one, but if the property holds an object, we can still call methods on that object that modify its internal state.

```php
readonly class Order
{
    public function __construct(
        public \stdClass $meta,
    ) {}
}

$order = new Order(new \stdClass());

// This throws: Cannot modify readonly property Order::$meta
// $order->meta = new \stdClass();

// But this is allowed — you are mutating the object $meta points to,
// not replacing the reference stored in $meta.
$order->meta->note = 'Handle with care';
echo $order->meta->note; // Handle with care
```

For scalar types (`string`, `int`, `float`, `bool`) this is not a concern, since scalars are always copied by value. For object and array types, keep this shallow immutability in mind.

### `readonly` Property vs `readonly class`

PHP 8.1 introduced `readonly` on individual properties. PHP 8.2 added `readonly` at the class level.

Writing `readonly class` is shorthand for marking every property in the class as readonly. It also prevents dynamic properties from being added to the object. If only some properties need to be readonly, we use PHP 8.1 style and mark them individually. If every property should be readonly, the PHP 8.2 `readonly class` syntax is cleaner and communicates intent more clearly.

### The Wither Pattern

Because you cannot modify a readonly property after initialization, updating an object means creating a new one. The wither pattern is the standard approach for this. A `with*` method takes a new value for one field, copies the rest from the current instance, and returns a fresh object.

```php
readonly class OrderData
{
    public function __construct(
        public string $orderId,
        public string $customerName,
        public string $status,
    ) {}

    // withStatus() returns a new OrderData with an updated status.
    // The original $this remains completely unchanged.
    public function withStatus(string $status): self
    {
        return new self(
            orderId:      $this->orderId,
            customerName: $this->customerName,
            status:       $status,
        );
    }
}

$original = new OrderData('ORD-001', 'Alice', 'pending');
$updated  = $original->withStatus('shipped');

echo $original->status; // pending
echo $updated->status;  // shipped
```

As a note for what is ahead: PHP 8.3 allows reinitializing readonly properties inside `__clone()`, which makes a reflection-based clone approach possible. PHP 8.5 is expected to introduce a native `clone with` syntax that will make the wither pattern even more concise at the language level.

---

## What About Laravel? {#readonly-in-laravel}

Everything covered in this guide applies directly in Laravel. The most immediate use case is using readonly DTOs in the Controller-Service pattern. A controller receives a `FormRequest`, builds an immutable DTO from the validated data using a `fromRequest()` factory method, and passes it to a service. The service can rely on the DTO's values never changing while it processes the request.

Laravel 9 and above works seamlessly with PHP 8.1 readonly properties and PHP 8.2 readonly classes. There is no additional configuration required. A future article on qadrlabs will walk through this pattern in a complete Laravel application, including integration with form requests, service classes, and API resources.

---

## Conclusion {#conclusion}

PHP used to require private properties, getters, and a significant amount of ceremony just to protect an object from unexpected mutation. PHP 8.1 changed that with readonly properties, and PHP 8.2 extended it further with readonly classes. Combined with constructor property promotion, you now have a concise, expressive, native way to build objects that mean what they say.

**Key Takeaways**

- A readonly property can only be assigned once. Any attempt to reassign it throws a fatal `Error` immediately, at runtime.
- Readonly properties must have a declared type. They cannot have a default value in the property declaration itself, but a default value on a promoted constructor parameter is allowed.
- PHP 8.2 `readonly class` applies readonly to all properties in the class automatically, and also prevents dynamic properties.
- Readonly provides shallow immutability. Scalars stored in readonly properties are fully immutable. Objects stored in readonly properties can still have their internals mutated.
- A DTO carries structured data between layers with no validity guarantees beyond type correctness. A Value Object enforces its own domain rules and guarantees that if it exists, its data is valid.
- The wither pattern is the standard way to "update" an immutable object: produce a new instance with the desired change while leaving the original untouched.
- Constructor property promotion plus `readonly` eliminates boilerplate getters entirely, since `public readonly` properties are readable from outside the class but not writable.

**What's Next**

- **PHP 8.0 Constructor Property Promotion** — if the `public function __construct(public readonly ...)` syntax felt new, the dedicated article on constructor property promotion will give you a deeper understanding of how it works on its own.
- **PHP Enums as Value Object Properties** — the previous qadrlabs article on PHP enums pairs naturally with this one. Using a `readonly` class with an enum property is a powerful combination for modeling domain state.
- **PHP Official Documentation** — the [PHP manual on readonly properties](https://www.php.net/manual/en/language.oop5.properties.php#language.oop5.properties.readonly-properties) is the authoritative reference for edge cases, including behavior in inheritance and cloning.