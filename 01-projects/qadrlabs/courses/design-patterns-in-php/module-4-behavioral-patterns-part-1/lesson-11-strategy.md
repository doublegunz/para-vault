## 1. Before You Begin

When a class needs to perform an operation that can be done in multiple ways (sorting, payment processing, discount calculation), hardcoding the algorithm with `if/else` violates the Open/Closed Principle. Adding a new algorithm means modifying existing code. The **Strategy** pattern extracts each algorithm into a separate class, making them interchangeable at runtime. Strategy is one of the most widely used behavioral patterns: it defines a family of algorithms, encapsulates each one in a class, and makes them interchangeable so the client can select the appropriate one at runtime.

### What You'll Build

You will create a payment processing system where the payment method (credit card, bank transfer, e-wallet) is selected at runtime via the Strategy pattern.

### What You'll Learn

- ✅ Strategy: interchangeable algorithms behind a common interface
- ✅ Context class that delegates to the strategy
- ✅ Selecting strategies at runtime
- ✅ Strategy vs if/else: why Strategy is better
- ✅ Strategy in Laravel: filesystem drivers, cache drivers, mail drivers

### What You'll Need

- Lesson 10 completed

---

## 2. The Problem

A payment system supports multiple methods. The if/else approach violates OCP:

```php
// BAD: adding PayPal requires modifying this method
class PaymentService
{
    public function pay(string $method, float $amount): void
    {
        if ($method === 'credit_card') { /* ... */ }
        elseif ($method === 'bank_transfer') { /* ... */ }
        elseif ($method === 'ewallet') { /* ... */ }
        // Every new method = modify this class
    }
}
```

---

## 3. The Solution

Each payment method becomes a Strategy class implementing a common interface. The service delegates to whichever strategy is provided.

```php
<?php
namespace App\Behavioral\Strategy;

// Strategy interface
interface PaymentStrategy
{
    public function pay(float $amount): bool;
    public function getName(): string;
}

// Concrete strategies
class CreditCardPayment implements PaymentStrategy
{
    public function __construct(private string $cardNumber, private string $expiry) {}

    public function pay(float $amount): bool
    {
        echo "[CreditCard] Charging {$amount} to card ending " . substr($this->cardNumber, -4) . "\n";
        return true;
    }

    public function getName(): string { return 'Credit Card'; }
}

class BankTransferPayment implements PaymentStrategy
{
    public function __construct(private string $bankCode, private string $accountNumber) {}

    public function pay(float $amount): bool
    {
        echo "[BankTransfer] Transferring {$amount} to {$this->bankCode}-{$this->accountNumber}\n";
        return true;
    }

    public function getName(): string { return 'Bank Transfer'; }
}

class EWalletPayment implements PaymentStrategy
{
    public function __construct(private string $walletId) {}

    public function pay(float $amount): bool
    {
        echo "[E-Wallet] Debiting {$amount} from wallet {$this->walletId}\n";
        return true;
    }

    public function getName(): string { return 'E-Wallet'; }
}

// Context: uses whichever strategy is injected
class PaymentService
{
    public function __construct(private PaymentStrategy $strategy) {}

    public function setStrategy(PaymentStrategy $strategy): void
    {
        $this->strategy = $strategy;
    }

    public function processPayment(float $amount): void
    {
        echo "Processing payment via {$this->strategy->getName()}...\n";
        $success = $this->strategy->pay($amount);
        echo $success ? "Payment successful!\n" : "Payment failed!\n";
    }
}

// Usage: select strategy at runtime
$service = new PaymentService(new CreditCardPayment('4111111111111234', '12/26'));
$service->processPayment(150000);

$service->setStrategy(new EWalletPayment('wallet_budi_123'));
$service->processPayment(50000);
```

Adding PayPal requires one new class. Zero changes to `PaymentService`.

---

## 4. Discount Calculation Example

Strategy is perfect for business rules that vary:

```php
interface DiscountStrategy
{
    public function calculate(float $total): float;
}

class NoDiscount implements DiscountStrategy
{
    public function calculate(float $total): float { return 0; }
}

class PercentageDiscount implements DiscountStrategy
{
    public function __construct(private float $percent) {}
    public function calculate(float $total): float { return $total * ($this->percent / 100); }
}

class FixedDiscount implements DiscountStrategy
{
    public function __construct(private float $amount) {}
    public function calculate(float $total): float { return min($this->amount, $total); }
}

class BuyOneGetOneFree implements DiscountStrategy
{
    public function calculate(float $total): float { return $total * 0.5; }
}

class Order
{
    public function __construct(private float $total, private DiscountStrategy $discount) {}
    public function getFinalPrice(): float { return $this->total - $this->discount->calculate($this->total); }
}
```

---

## 5. Fix the Errors in Your Code

These are the three most common Strategy pattern mistakes in PHP codebases.

**Error 1: Strategy that accumulates state across multiple uses.**

Strategies should ideally be stateless. If a strategy stores state (such as a transaction counter) that accumulates across calls, reusing the same instance causes one payment's data to bleed into the next.

```php
// Wrong: $transactionCount accumulates if the strategy is reused
class CreditCardPayment implements PaymentStrategy
{
    private int $transactionCount = 0;

    public function pay(float $amount): bool
    {
        $this->transactionCount++;
        return true;
    }
}

// Correct: keep strategies stateless, or create a new instance per use
class CreditCardPayment implements PaymentStrategy
{
    public function __construct(private string $cardNumber, private string $expiry) {}

    public function pay(float $amount): bool
    {
        echo "[CreditCard] Charging {$amount}\n";
        return true;
    }
}
```

Keep strategies stateless when possible. If state is required, create a new strategy instance for each use rather than sharing one instance across multiple operations.

**Error 2: Context class typed to a concrete strategy instead of the interface.**

When the context stores the strategy as a concrete class, the entire purpose of the pattern is defeated: the context is now coupled to one implementation and cannot accept other strategies.

```php
// Wrong: typed to a concrete class — only CreditCardPayment is accepted
class PaymentService
{
    private CreditCardPayment $strategy;
}

// Correct: typed to the interface — any PaymentStrategy implementation is accepted
class PaymentService
{
    private PaymentStrategy $strategy;

    public function __construct(PaymentStrategy $strategy)
    {
        $this->strategy = $strategy;
    }
}
```

Always type the context's strategy property to the interface, not to a concrete class. This is the core of the pattern: the context works with any implementation that satisfies the contract.

**Error 3: Passing `null` as the strategy.**

If null is passed where a strategy is expected, any method call on the strategy inside the context will throw a fatal error. Either enforce the strategy in the constructor or provide a Null Object strategy that does nothing.

```php
// Wrong: null is accepted — processPayment() will throw a fatal error
$service = new PaymentService(null);
$service->processPayment(100);

// Correct: enforce the strategy via constructor type-hint
class PaymentService
{
    public function __construct(private PaymentStrategy $strategy) {}
}
// PHP will throw a TypeError if null is passed

// Alternative: provide a Null Object strategy
class NoPayment implements PaymentStrategy
{
    public function pay(float $amount): bool { return false; }
    public function getName(): string { return 'None'; }
}
```

Use PHP's type system to prevent null from being passed. If "no strategy" is a valid state, implement a Null Object strategy that returns safe default values rather than allowing null.

---

## 6. Exercises

**Exercise 1:** Create a sorting strategy system: `BubbleSort`, `QuickSort`, `MergeSort` implementing `SortStrategy`. A `Sorter` context accepts any strategy. Demonstrate switching strategies.

**Exercise 2:** Create a shipping cost strategy: `FlatRateShipping`, `WeightBasedShipping`, `FreeShipping`. The `Order` class uses the strategy to calculate shipping.

**Exercise 3:** Create a validation strategy: `EmailValidator`, `PhoneValidator`, `UrlValidator` implementing `ValidatorStrategy`. A `FormField` context validates its value using the injected strategy.

---

## 7. Solutions

**Solution for Exercise 1:**

```php
interface SortStrategy { public function sort(array &$data): void; }
class BubbleSort implements SortStrategy
{
    public function sort(array &$data): void { sort($data); echo "Sorted with BubbleSort\n"; }
}
class QuickSort implements SortStrategy
{
    public function sort(array &$data): void { sort($data); echo "Sorted with QuickSort\n"; }
}
class Sorter
{
    public function __construct(private SortStrategy $strategy) {}
    public function setStrategy(SortStrategy $s): void { $this->strategy = $s; }
    public function sort(array &$data): void { $this->strategy->sort($data); }
}
```

---

## 8. Next Up - Lesson 12

Strategy encapsulates interchangeable algorithms behind a common interface. The context delegates to whichever strategy is injected. New strategies can be added without modifying existing code, satisfying OCP. Always type the context's strategy property to the interface, and keep strategies stateless when possible. Laravel uses Strategy for filesystem, cache, mail, and queue drivers.

In Lesson 12, you will learn the Observer pattern: a way to define a one-to-many dependency so that when one object changes state, all registered observers are notified automatically.