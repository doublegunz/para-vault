## 1. Before You Begin

Real-world applications integrate many libraries and services, each with its own interface. Your code expects one interface, but the third-party library provides a different one. **Adapter** makes incompatible interfaces work together. **Bridge** separates an abstraction from its implementation so both can vary independently. Both patterns deal with interface mismatch, but at different levels. Adapter wraps an existing class with a new interface; Bridge separates what an object does from how it does it.

### What You'll Build

You will create an Adapter that wraps different payment gateways into a unified interface, and a Bridge that separates notification delivery (email, SMS) from notification urgency (regular, urgent).

### What You'll Learn

- ✅ Adapter: wrap an incompatible interface
- ✅ Class adapter vs object adapter
- ✅ Bridge: decouple abstraction from implementation
- ✅ When to use Adapter vs Bridge
- ✅ Real-world examples: payment gateways, logging, file systems

### What You'll Need

- Lesson 6 completed

---

## 2. Adapter Pattern

The Adapter makes an existing class work with an interface it was not designed for. It wraps the "adaptee" and translates method calls.

### The Problem

Your application uses a `PaymentGateway` interface. A third-party library (Stripe SDK) has different method names. You cannot modify the library code.

```php
<?php
namespace App\Structural\Adapter;

// Your application's interface
interface PaymentGateway
{
    public function charge(float $amount, string $currency): bool;
    public function refund(string $transactionId, float $amount): bool;
}

// Third-party library (cannot modify)
class StripeSDK
{
    public function createCharge(int $amountInCents, string $currency): array
    {
        echo "[Stripe] Charged {$amountInCents} cents {$currency}\n";
        return ['id' => 'txn_' . uniqid(), 'status' => 'succeeded'];
    }
    public function createRefund(string $chargeId, int $amountInCents): array
    {
        echo "[Stripe] Refunded {$amountInCents} cents for {$chargeId}\n";
        return ['status' => 'succeeded'];
    }
}

// Adapter: makes StripeSDK work with PaymentGateway interface
class StripeAdapter implements PaymentGateway
{
    public function __construct(private StripeSDK $stripe) {}

    public function charge(float $amount, string $currency): bool
    {
        $result = $this->stripe->createCharge((int)($amount * 100), $currency);
        return $result['status'] === 'succeeded';
    }

    public function refund(string $transactionId, float $amount): bool
    {
        $result = $this->stripe->createRefund($transactionId, (int)($amount * 100));
        return $result['status'] === 'succeeded';
    }
}

// Client code works with the interface
function processPayment(PaymentGateway $gateway): void
{
    $gateway->charge(99.99, 'USD');
    $gateway->refund('txn_123', 25.00);
}

processPayment(new StripeAdapter(new StripeSDK()));
```

---

## 3. Bridge Pattern

Bridge separates an abstraction (what it does) from its implementation (how it does it). Both can vary independently without affecting each other.

```php
<?php
namespace App\Structural\Bridge;

// Implementation interface (how messages are delivered)
interface MessageSender
{
    public function send(string $to, string $content): void;
}

class EmailSender implements MessageSender
{
    public function send(string $to, string $content): void { echo "[Email -> {$to}] {$content}\n"; }
}

class SmsSender implements MessageSender
{
    public function send(string $to, string $content): void { echo "[SMS -> {$to}] {$content}\n"; }
}

// Abstraction (what kind of notification)
abstract class Notification
{
    public function __construct(protected MessageSender $sender) {}
    abstract public function notify(string $to, string $message): void;
}

class RegularNotification extends Notification
{
    public function notify(string $to, string $message): void
    {
        $this->sender->send($to, "[INFO] {$message}");
    }
}

class UrgentNotification extends Notification
{
    public function notify(string $to, string $message): void
    {
        $this->sender->send($to, "[URGENT!] {$message}");
        $this->sender->send($to, "[REMINDER] {$message}");  // Sends twice
    }
}

// Usage: any notification type x any delivery method
$regularEmail = new RegularNotification(new EmailSender());
$urgentSms = new UrgentNotification(new SmsSender());
$regularEmail->notify('admin@example.com', 'Server backup completed');
$urgentSms->notify('+62812345', 'Server is down!');
```

The Bridge enables `N notification types x M delivery methods` without creating `N*M` classes.

---

## 4. Adapter vs Bridge

Both manage interfaces, but at different stages and for different purposes.

| Aspect | Adapter | Bridge |
|--------|---------|--------|
| Purpose | Make existing interface compatible | Separate abstraction from implementation |
| When | After design (retrofitting) | During design (planning ahead) |
| Wraps | Third-party class | Implementation hierarchy |
| Direction | Existing -> expected interface | Two independent hierarchies |

---

## 5. Fix the Errors in Your Code

These are the three most common Adapter and Bridge mistakes in PHP codebases.

**Error 1: Adapter that extends the adaptee instead of wrapping it.**

Extending the adaptee (class adapter) couples the adapter to its internal details. If the adaptee changes, the adapter breaks. Composition is safer and avoids exposing unwanted inherited methods.

```php
// Wrong: inheriting from StripeSDK couples the adapter to its internals
class StripeAdapter extends StripeSDK
{
    public function charge(float $amount, string $currency): bool { ... }
}

// Correct: wrap the adaptee via constructor injection (object adapter)
class StripeAdapter implements PaymentGateway
{
    public function __construct(private StripeSDK $stripe) {}
    public function charge(float $amount, string $currency): bool { ... }
    public function refund(string $transactionId, float $amount): bool { ... }
}
```

Use composition (inject the adaptee in the constructor) instead of class inheritance. This keeps the adapter decoupled from the adaptee's implementation details.

**Error 2: Using Bridge when only one dimension of variation exists.**

Bridge is designed for cases where both the abstraction AND the implementation vary independently. If only one side varies, the pattern adds unnecessary class hierarchy.

```php
// Wrong: adding Bridge when there is only one notification type
// Only the sender varies (Email, SMS) — Strategy is sufficient here.
abstract class Notification
{
    public function __construct(protected MessageSender $sender) {}
    abstract public function notify(string $to, string $message): void;
}

// Correct: use Bridge when BOTH hierarchies have multiple implementations
// RegularNotification + UrgentNotification (abstraction side)
// AND EmailSender + SmsSender (implementation side)
```

Apply Bridge only when you have multiple independent dimensions of variation. For a single varying dimension, Strategy or simple polymorphism is enough.

**Error 3: Adapter that does not fully implement the target interface.**

If the adapter leaves any interface method unimplemented, PHP will throw a fatal error when the adapter is instantiated. Every method declared in the interface must have a concrete implementation.

```php
// Wrong: refund() is missing — PHP will throw a fatal error on instantiation
class StripeAdapter implements PaymentGateway
{
    public function charge(float $amount, string $currency): bool { ... }
}

// Correct: implement every method declared in the interface
class StripeAdapter implements PaymentGateway
{
    public function charge(float $amount, string $currency): bool { ... }
    public function refund(string $transactionId, float $amount): bool { ... }
}
```

Always check the target interface and verify the adapter covers every method. Use your IDE's "implement missing methods" feature to catch omissions before runtime.

---

## 6. Exercises

**Exercise 1:** Create an `XmlToJsonAdapter` that wraps a legacy XML API class and makes it return JSON. The XML class has `fetchXml(): string`. The adapter implements `DataProvider::fetchData(): array`.

**Exercise 2:** Create a Bridge for shapes and renderers. Shapes: Circle, Square. Renderers: SvgRenderer, CanvasRenderer. Each shape delegates its drawing to the renderer.

**Exercise 3:** Create a `LoggerAdapter` that wraps PHP's `error_log()` function into a `LoggerInterface` with `info()`, `warning()`, `error()` methods.

---

## 7. Solutions

**Solution for Exercise 1:**

```php
interface DataProvider { public function fetchData(): array; }
class LegacyXmlApi { public function fetchXml(): string { return '<item><name>Test</name></item>'; } }
class XmlToJsonAdapter implements DataProvider
{
    public function __construct(private LegacyXmlApi $api) {}
    public function fetchData(): array
    {
        $xml = simplexml_load_string($this->api->fetchXml());
        return json_decode(json_encode($xml), true);
    }
}
```

---

## 8. Next Up - Lesson 8

Adapter wraps an incompatible interface to match the expected one. Use it when integrating third-party libraries that you cannot modify. Bridge separates abstraction from implementation, allowing both hierarchies to vary independently. Use it when you have two independent dimensions of variation. Both patterns favor composition over inheritance.

In Lesson 8, you will learn Decorator and Proxy: two patterns that wrap objects with the same interface — Decorator to add behavior, and Proxy to control access.