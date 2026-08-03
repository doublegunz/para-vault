## 1. Before You Begin

Complex systems have many classes that work together: sending an email involves SMTP connection, template rendering, header building, attachment encoding, and logging. Making callers coordinate all these classes creates tight coupling. **Facade** provides a simple interface to a complex subsystem. Meanwhile, **Flyweight** shares common data between many objects to reduce memory usage. Facade simplifies a complex API into a single easy-to-use class, while Flyweight optimizes memory by sharing immutable state between similar objects.

### What You'll Build

You will create a Facade for an order processing subsystem and a Flyweight for rendering many text characters with shared font data.

### What You'll Learn

- ✅ Facade: simple interface to complex subsystem
- ✅ How Laravel's Facade works (and why it is not the GoF Facade)
- ✅ Flyweight: share intrinsic (immutable) state, vary extrinsic state
- ✅ Flyweight factory for managing shared instances
- ✅ When each pattern is appropriate

### What You'll Need

- Lesson 8 completed

---

## 2. Facade

The Facade wraps a complex subsystem with a simple interface. The client calls one method on the Facade instead of coordinating multiple objects. Create the four subsystem classes and the `OrderFacade` that orchestrates them all in a single method call:

```php
<?php
namespace App\Structural\Facade;

// Complex subsystem classes
class Inventory
{
    public function check(string $productId, int $qty): bool
    {
        echo "[Inventory] Checking {$productId} x{$qty}: Available\n";
        return true;
    }
    public function reserve(string $productId, int $qty): void
    {
        echo "[Inventory] Reserved {$productId} x{$qty}\n";
    }
}

class PaymentProcessor
{
    public function charge(string $customerId, float $amount): string
    {
        echo "[Payment] Charged \${$amount} to {$customerId}\n";
        return 'txn_' . uniqid();
    }
}

class ShippingService
{
    public function createShipment(string $orderId, string $address): string
    {
        echo "[Shipping] Shipment created for {$orderId} to {$address}\n";
        return 'ship_' . uniqid();
    }
}

class NotificationService
{
    public function sendOrderConfirmation(string $email, string $orderId): void
    {
        echo "[Email] Order {$orderId} confirmation sent to {$email}\n";
    }
}

// Facade: one simple method for the entire process
class OrderFacade
{
    public function __construct(
        private Inventory $inventory,
        private PaymentProcessor $payment,
        private ShippingService $shipping,
        private NotificationService $notification,
    ) {}

    public function placeOrder(string $customerId, string $productId, int $qty, float $amount, string $address, string $email): string
    {
        // Coordinate the complex subsystem
        if (!$this->inventory->check($productId, $qty)) {
            throw new \RuntimeException('Product not available');
        }
        $this->inventory->reserve($productId, $qty);
        $txnId = $this->payment->charge($customerId, $amount);
        $shipId = $this->shipping->createShipment($txnId, $address);
        $this->notification->sendOrderConfirmation($email, $txnId);

        echo "[Order] Complete! Transaction: {$txnId}, Shipment: {$shipId}\n";
        return $txnId;
    }
}

// Client: one call instead of coordinating 4 classes
$facade = new OrderFacade(new Inventory(), new PaymentProcessor(), new ShippingService(), new NotificationService());
$facade->placeOrder('cust_1', 'prod_laptop', 1, 8500000, 'Jl. Merdeka 1, Bandung', 'budi@example.com');
```

---

## 3. Flyweight

Flyweight shares common (intrinsic) state between many objects. Each object stores only its unique (extrinsic) state. This dramatically reduces memory when you have thousands of similar objects. Create the immutable `CharacterStyle` flyweight, a `StyleFactory` that caches and reuses style instances, and a `Character` that carries its own position while sharing a style:

```php
<?php
namespace App\Structural\Flyweight;

// Flyweight: shared intrinsic state
class CharacterStyle
{
    public function __construct(
        public readonly string $fontFamily,
        public readonly int $fontSize,
        public readonly string $color,
    ) {}
}

// Flyweight factory: creates and caches shared styles
class StyleFactory
{
    private array $styles = [];

    public function getStyle(string $font, int $size, string $color): CharacterStyle
    {
        $key = "{$font}_{$size}_{$color}";
        if (!isset($this->styles[$key])) {
            $this->styles[$key] = new CharacterStyle($font, $size, $color);
            echo "[Factory] Created new style: {$key}\n";
        }
        return $this->styles[$key];
    }

    public function getStyleCount(): int { return count($this->styles); }
}

// Character: extrinsic state (position, char) + shared flyweight (style)
class Character
{
    public function __construct(
        public readonly string $char,
        public readonly int $row,
        public readonly int $col,
        public readonly CharacterStyle $style,
    ) {}

    public function render(): string
    {
        return "'{$this->char}' at ({$this->row},{$this->col}) in {$this->style->fontFamily} {$this->style->fontSize}pt {$this->style->color}";
    }
}

// Usage: 1000 characters, but only a few shared styles
$factory = new StyleFactory();
$characters = [];

$text = "Hello, World! This is a Flyweight pattern demonstration. ";
$bodyStyle = $factory->getStyle('Arial', 12, '#333333');
$headerStyle = $factory->getStyle('Arial', 24, '#000000');

foreach (str_split($text) as $i => $char) {
    $style = $i < 14 ? $headerStyle : $bodyStyle;
    $characters[] = new Character($char, 0, $i, $style);
}

echo "Characters: " . count($characters) . "\n";
echo "Unique styles: " . $factory->getStyleCount() . "\n";
// 58 characters share just 2 style objects!
```

---

## 4. Fix the Errors in Your Code

These are the three most common Facade and Flyweight mistakes in PHP codebases.

**Error 1: Facade that exposes subsystem components through getter methods.**

When the Facade provides getters that return internal subsystem objects, callers bypass the Facade and interact with subsystem classes directly. This defeats the purpose of providing a simplified interface.

```php
// Wrong: exposing the PaymentProcessor via a getter defeats the Facade
class OrderFacade
{
    public function getPaymentProcessor(): PaymentProcessor
    {
        return $this->payment;
    }
}

// Correct: keep subsystem objects private; expose only high-level operations
class OrderFacade
{
    public function placeOrder(string $customerId, string $productId, ...): string { ... }
    // No getters for internal subsystem components
}
```

The Facade should expose only high-level operations. If a caller truly needs direct access to a subsystem class, provide a specific method on the Facade rather than exposing the component itself.

**Error 2: Flyweight with mutable shared state.**

The intrinsic (shared) state of a Flyweight must be immutable. If two objects share the same Flyweight instance and one modifies a property, every object sharing that instance is affected.

```php
// Wrong: public mutable properties — any user of this style can change shared state
class CharacterStyle
{
    public string $color;
    public string $fontFamily;
    public int $fontSize;
}

// Correct: readonly properties guarantee that shared state is never modified
class CharacterStyle
{
    public function __construct(
        public readonly string $fontFamily,
        public readonly int $fontSize,
        public readonly string $color,
    ) {}
}
```

Declare all intrinsic Flyweight properties as `readonly`. This guarantees that shared state cannot be accidentally modified by any object that holds a reference to the Flyweight.

**Error 3: Flyweight factory that creates a new instance on every call.**

A factory that returns `new CharacterStyle(...)` every time provides no memory benefit. The factory must cache instances by a key built from their intrinsic properties and return the cached instance on subsequent calls.

```php
// Wrong: creates a new style object on every call — no sharing, no memory savings
public function getStyle(string $font, int $size, string $color): CharacterStyle
{
    return new CharacterStyle($font, $size, $color);
}

// Correct: build a cache key and return the existing instance on repeated calls
public function getStyle(string $font, int $size, string $color): CharacterStyle
{
    $key = "{$font}_{$size}_{$color}";
    if (!isset($this->styles[$key])) {
        $this->styles[$key] = new CharacterStyle($font, $size, $color);
    }
    return $this->styles[$key];
}
```

The cache inside the factory is what makes Flyweight effective. Build the cache key from all intrinsic property values and always check the cache before creating a new instance.

---

## 5. Exercises

**Exercise 1:** Create a `ReportFacade` that coordinates DataFetcher, DataFormatter, PdfGenerator, and EmailSender to produce and send a report in one method call.

**Exercise 2:** Create a Flyweight for map markers: each marker has a position (extrinsic) and an icon type (intrinsic/shared). An `IconFactory` shares icon objects between markers.

**Exercise 3:** Research and explain in comments how Laravel's `Cache::get()` Facade works. Is it the GoF Facade pattern?

---

## 6. Solutions

**Solution for Exercise 3:** Laravel's "Facades" are actually static proxies that resolve a service from the container. They are closer to the Proxy pattern than the GoF Facade. `Cache::get()` calls `app('cache')->get()`. The GoF Facade wraps a complex subsystem; Laravel's Facade wraps a single service with static syntax.

---

## 7. Next Up - Lesson 10

Facade provides a simple interface to a complex subsystem. Clients can still access the subsystem directly if needed, but the Facade handles the common coordinate-and-call workflow in one method. Flyweight shares immutable intrinsic state between many objects, while each object keeps its own extrinsic state. Use Facade to simplify wide API surfaces; use Flyweight when memory pressure is a concern with thousands of similar objects.

This concludes the Structural Patterns module. In Lesson 10, you will learn the Composite pattern: a way to compose objects into tree structures so that individual objects and groups of objects can be treated uniformly.