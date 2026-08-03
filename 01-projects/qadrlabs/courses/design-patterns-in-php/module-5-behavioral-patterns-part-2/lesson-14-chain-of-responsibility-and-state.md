## 1. Before You Begin

Some requests need to pass through multiple handlers: middleware checks authentication, then authorization, then rate limiting, then finally processes the request. **Chain of Responsibility** passes a request along a chain of handlers, each deciding whether to process it or pass it on. Meanwhile, some objects change behavior based on their internal state: an order behaves differently when it is "pending" versus "shipped" versus "delivered." The **State** pattern encapsulates state-specific behavior into separate classes, eliminating large `if/else` blocks that check the current state.

### What You'll Build

You will create a middleware pipeline (Chain of Responsibility) and an order status system (State).

### What You'll Learn

- ✅ Chain of Responsibility: pass requests through a handler chain
- ✅ Each handler decides to process or pass on
- ✅ State: change behavior when internal state changes
- ✅ State transitions and state-specific behavior
- ✅ CoR in Laravel: middleware. State in order/workflow systems.

### What You'll Need

- Lesson 13 completed

---

## 2. Chain of Responsibility

Each handler in the chain either handles the request or passes it to the next handler. Build the abstract `Middleware` base class and three concrete middleware handlers (authentication, rate limiting, and logging) that form a chained pipeline:

```php
<?php
namespace App\Behavioral\ChainOfResponsibility;

abstract class Middleware
{
    private ?Middleware $next = null;

    public function setNext(Middleware $next): Middleware
    {
        $this->next = $next;
        return $next;
    }

    public function handle(array $request): array
    {
        if ($this->next) {
            return $this->next->handle($request);
        }
        return $request;
    }
}

class AuthenticationMiddleware extends Middleware
{
    public function handle(array $request): array
    {
        if (empty($request['token'])) {
            echo "[Auth] REJECTED: No token\n";
            return ['error' => 'Unauthorized'];
        }
        echo "[Auth] Token valid\n";
        $request['user'] = 'Budi';
        return parent::handle($request);
    }
}

class RateLimitMiddleware extends Middleware
{
    private int $requests = 0;

    public function handle(array $request): array
    {
        $this->requests++;
        if ($this->requests > 5) {
            echo "[RateLimit] REJECTED: Too many requests\n";
            return ['error' => 'Rate limited'];
        }
        echo "[RateLimit] OK ({$this->requests}/5)\n";
        return parent::handle($request);
    }
}

class LoggingMiddleware extends Middleware
{
    public function handle(array $request): array
    {
        echo "[Log] Request from: " . ($request['user'] ?? 'anonymous') . "\n";
        return parent::handle($request);
    }
}

// Build the chain
$auth = new AuthenticationMiddleware();
$rateLimit = new RateLimitMiddleware();
$logging = new LoggingMiddleware();

$auth->setNext($rateLimit)->setNext($logging);

// Process requests
$auth->handle(['token' => 'valid_token', 'path' => '/api/users']);
$auth->handle([]);  // No token: rejected at authentication
```

---

## 3. State Pattern

Each state is a separate class that handles state-specific behavior. The context delegates to the current state object. Create the `OrderState` interface and five concrete state classes that define valid transitions, then an `Order` context that delegates all state-related behavior to the current state object:

```php
<?php
namespace App\Behavioral\State;

interface OrderState
{
    public function next(Order $order): void;
    public function cancel(Order $order): void;
    public function getStatus(): string;
}

class PendingState implements OrderState
{
    public function next(Order $order): void { echo "Order confirmed. Moving to Processing.\n"; $order->setState(new ProcessingState()); }
    public function cancel(Order $order): void { echo "Order cancelled.\n"; $order->setState(new CancelledState()); }
    public function getStatus(): string { return 'Pending'; }
}

class ProcessingState implements OrderState
{
    public function next(Order $order): void { echo "Order shipped.\n"; $order->setState(new ShippedState()); }
    public function cancel(Order $order): void { echo "Cannot cancel: already processing.\n"; }
    public function getStatus(): string { return 'Processing'; }
}

class ShippedState implements OrderState
{
    public function next(Order $order): void { echo "Order delivered.\n"; $order->setState(new DeliveredState()); }
    public function cancel(Order $order): void { echo "Cannot cancel: already shipped.\n"; }
    public function getStatus(): string { return 'Shipped'; }
}

class DeliveredState implements OrderState
{
    public function next(Order $order): void { echo "Order already delivered.\n"; }
    public function cancel(Order $order): void { echo "Cannot cancel: already delivered.\n"; }
    public function getStatus(): string { return 'Delivered'; }
}

class CancelledState implements OrderState
{
    public function next(Order $order): void { echo "Cannot proceed: order cancelled.\n"; }
    public function cancel(Order $order): void { echo "Already cancelled.\n"; }
    public function getStatus(): string { return 'Cancelled'; }
}

class Order
{
    private OrderState $state;

    public function __construct() { $this->state = new PendingState(); }
    public function setState(OrderState $state): void { $this->state = $state; }
    public function next(): void { $this->state->next($this); }
    public function cancel(): void { $this->state->cancel($this); }
    public function getStatus(): string { return $this->state->getStatus(); }
}

// Usage
$order = new Order();
echo "Status: {$order->getStatus()}\n";  // Pending
$order->next();                           // Confirmed -> Processing
echo "Status: {$order->getStatus()}\n";  // Processing
$order->cancel();                         // Cannot cancel
$order->next();                           // Shipped
$order->next();                           // Delivered
```

---

## 4. Fix the Errors in Your Code

These are the three most common Chain of Responsibility and State mistakes in PHP codebases.

**Error 1: Handler that does not delegate to the next handler in the chain.**

If a handler processes the request but does not call `parent::handle()` (or `$this->next->handle()`), the chain stops at that handler. Subsequent handlers never receive the request.

```php
// Wrong: processes the request but never calls the next handler
class BadMiddleware extends Middleware
{
    public function handle(array $request): array
    {
        echo "Processing...\n";
        return $request;
    }
}

// Correct: always delegate to parent::handle() to continue the chain
class GoodMiddleware extends Middleware
{
    public function handle(array $request): array
    {
        echo "Processing...\n";
        return parent::handle($request);
    }
}
```

Every handler must call `parent::handle($request)` (or the equivalent `$next($request)`) unless it intentionally short-circuits the chain. Short-circuiting is valid (e.g., rejecting an unauthenticated request), but forgetting to delegate is a bug.

**Error 2: State transition method sets the wrong target state.**

State transitions define the business logic of a workflow. Setting the wrong target state (e.g., going backward from Processing to Pending) creates inconsistent data and can allow operations that should be forbidden.

```php
// Wrong: ProcessingState.next() transitions backward to Pending
class ProcessingState implements OrderState
{
    public function next(Order $order): void
    {
        $order->setState(new PendingState());
    }
}

// Correct: transition forward to the next logical state
class ProcessingState implements OrderState
{
    public function next(Order $order): void
    {
        echo "Order shipped.\n";
        $order->setState(new ShippedState());
    }
}
```

Map out all valid state transitions before coding. Each `next()` and `cancel()` method should enforce the correct direction according to the business workflow.

**Error 3: Terminal state that allows further transitions.**

A terminal state (Delivered, Cancelled) should not allow transitions to any other state. Allowing a delivered order to transition to Pending creates invalid data that violates the business rules.

```php
// Wrong: Delivered state allows transitioning back to Pending
class DeliveredState implements OrderState
{
    public function next(Order $order): void
    {
        $order->setState(new PendingState());
    }
}

// Correct: terminal state logs or throws but does not transition
class DeliveredState implements OrderState
{
    public function next(Order $order): void
    {
        echo "Order is already delivered. No further transitions allowed.\n";
    }

    public function cancel(Order $order): void
    {
        echo "Cannot cancel a delivered order.\n";
    }
}
```

Terminal states should never call `setState()`. They should log the invalid attempt, return an error, or throw an exception to signal that the operation is not permitted.

---

## 5. Exercises

**Exercise 1:** Add a `ValidationMiddleware` to the chain that checks if the request has a `path` key. Insert it between authentication and rate limiting.

**Exercise 2:** Add a `ReturnedState` to the order system. Delivered orders can be returned within a time limit.

**Exercise 3:** Create a State pattern for a document workflow: Draft -> Review -> Approved -> Published. Each state has allowed and disallowed transitions.

---

## 6. Solutions

**Solution for Exercise 1:**

```php
class ValidationMiddleware extends Middleware
{
    public function handle(array $request): array
    {
        if (empty($request['path'])) { echo "[Validate] REJECTED: No path\n"; return ['error' => 'Bad request']; }
        echo "[Validate] Path OK: {$request['path']}\n";
        return parent::handle($request);
    }
}
$auth->setNext($validation)->setNext($rateLimit)->setNext($logging);
```

---

## 7. Next Up - Lesson 15

Chain of Responsibility passes requests through a pipeline of handlers, each deciding to process or delegate. Always call `parent::handle()` to continue the chain unless intentionally short-circuiting. State encapsulates state-specific behavior into separate classes, eliminating large conditional blocks. State transitions happen by replacing the state object. Both patterns replace complex conditional logic with clear, polymorphic class hierarchies.

In Lesson 15, you will learn Iterator and Mediator: Iterator provides uniform access to any collection, and Mediator centralizes complex many-to-many communication through a single hub object.