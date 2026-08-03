## 1. Before You Begin

When an object changes state, other objects often need to react: when a user registers, send a welcome email, create a default profile, and log the event. Hardcoding these reactions in the user creation code violates SRP and makes it impossible to add new reactions without modifying the original class. The **Observer** pattern defines a one-to-many dependency: when the subject changes, all observers are notified automatically. Observer is the foundation of event systems in every PHP framework — Laravel's event/listener system, Symfony's event dispatcher, and JavaScript's `addEventListener` are all implementations of this pattern.

### What You'll Build

You will create an event system for user registration that notifies multiple listeners (email, logging, analytics) without coupling.

### What You'll Learn

- ✅ Observer: subject, observer, notify mechanism
- ✅ PHP's built-in `SplSubject` and `SplObserver` interfaces
- ✅ Custom event dispatcher implementation
- ✅ Decoupling with Observer
- ✅ Observer in Laravel: events, listeners, model observers

### What You'll Need

- Lesson 11 completed

---

## 2. Implementation

The Subject maintains a list of observers and notifies them when its state changes. Create an `EventDispatcher` as the subject, an `EventListener` interface as the observer contract, and four concrete listeners that react to user registration events:

```php
<?php
namespace App\Behavioral\Observer;

// Observer interface
interface EventListener
{
    public function handle(string $event, array $data): void;
}

// Subject: event dispatcher
class EventDispatcher
{
    private array $listeners = [];

    public function subscribe(string $event, EventListener $listener): void
    {
        $this->listeners[$event][] = $listener;
    }

    public function dispatch(string $event, array $data = []): void
    {
        echo "--- Dispatching: {$event} ---\n";
        foreach ($this->listeners[$event] ?? [] as $listener) {
            $listener->handle($event, $data);
        }
    }
}

// Concrete observers
class SendWelcomeEmail implements EventListener
{
    public function handle(string $event, array $data): void
    {
        echo "[Email] Welcome email sent to {$data['email']}\n";
    }
}

class CreateDefaultProfile implements EventListener
{
    public function handle(string $event, array $data): void
    {
        echo "[Profile] Default profile created for {$data['name']}\n";
    }
}

class LogActivity implements EventListener
{
    public function handle(string $event, array $data): void
    {
        echo "[Log] Event '{$event}' for user {$data['id']}\n";
    }
}

class UpdateAnalytics implements EventListener
{
    public function handle(string $event, array $data): void
    {
        echo "[Analytics] New user registered. Total users updated.\n";
    }
}

// Usage
$dispatcher = new EventDispatcher();
$dispatcher->subscribe('user.registered', new SendWelcomeEmail());
$dispatcher->subscribe('user.registered', new CreateDefaultProfile());
$dispatcher->subscribe('user.registered', new LogActivity());
$dispatcher->subscribe('user.registered', new UpdateAnalytics());
$dispatcher->subscribe('user.deleted', new LogActivity());

// Register a user: all listeners fire automatically
$dispatcher->dispatch('user.registered', ['id' => 1, 'name' => 'Budi', 'email' => 'budi@example.com']);

// Delete a user: only LogActivity fires
$dispatcher->dispatch('user.deleted', ['id' => 1]);
```

Adding new behavior (e.g., send a Slack notification on registration) requires creating one new class and one `subscribe()` call. Zero changes to existing code.

---

## 3. PHP's Built-in SplObserver

PHP provides `SplSubject` and `SplObserver` interfaces, but they are rarely used in practice because they are limited. Custom implementations (like above) are more flexible.

---

## 4. Fix the Errors in Your Code

These are the three most common Observer pattern mistakes in PHP codebases.

**Error 1: Subject dispatches events before the object is fully constructed.**

If the subject dispatches an event inside its constructor, observers may receive an event about an object that is only partially initialized. Observers that read properties from the subject will see incomplete or default values.

```php
// Wrong: dispatch fires before the User object is fully set up
class User
{
    public string $name = '';
    public string $email = '';

    public function __construct(private EventDispatcher $dispatcher)
    {
        $this->dispatcher->dispatch('user.created');
    }
}

// Correct: dispatch after the object is fully initialized
class UserService
{
    public function createUser(array $data): User
    {
        $user = new User($data['name'], $data['email']);
        $this->dispatcher->dispatch('user.created', $data);
        return $user;
    }
}
```

Dispatch events from service classes or factory methods, not from constructors. The object should be fully constructed and valid before any observer reacts to it.

**Error 2: Observer that modifies the event data passed by reference.**

In PHP, arrays are passed by value, so modifying an array in one observer does not affect other observers. However, if event data is passed as an object, observers can mutate shared state and corrupt data for subsequent observers.

```php
// Wrong: modifying an object in one observer affects all subsequent observers
class BadObserver implements EventListener
{
    public function handle(string $event, object $data): void
    {
        $data->name = 'Changed'; // mutates the shared object!
    }
}

// Correct: treat event data as read-only; use arrays (value-copied) for safety
class GoodObserver implements EventListener
{
    public function handle(string $event, array $data): void
    {
        echo "Processing: {$data['name']}\n";
    }
}
```

Pass event data as arrays (copied by value) or as immutable value objects. Never allow observers to modify shared event data that subsequent observers will also read.

**Error 3: Observer that dispatches an event it also listens to, causing an infinite loop.**

If an observer dispatches a new event inside its handler, and that same observer is also subscribed to that new event, the dispatcher will call the observer again, creating an infinite recursion.

```php
// Wrong: AuditObserver dispatches 'audit.logged' and also listens to it
class AuditObserver implements EventListener
{
    public function __construct(private EventDispatcher $dispatcher) {}

    public function handle(string $event, array $data): void
    {
        $this->dispatcher->dispatch('audit.logged', $data);
        // If AuditObserver is subscribed to 'audit.logged', this loops forever
    }
}

// Correct: use a dedicated non-recursive event name, or guard against re-entry
class AuditObserver implements EventListener
{
    private bool $handling = false;

    public function handle(string $event, array $data): void
    {
        if ($this->handling) return;
        $this->handling = true;
        // ... handle event ...
        $this->handling = false;
    }
}
```

Be careful when observers dispatch events. Ensure that any newly dispatched event uses a different name from the one that triggered the observer, or add a guard flag to prevent re-entrant calls.

---

## 5. Exercises

**Exercise 1:** Add an `unsubscribe()` method to EventDispatcher. Demonstrate subscribing, dispatching, unsubscribing, and dispatching again to show the listener no longer fires.

**Exercise 2:** Create a stock price observer: `StockPrice` is the subject. `InvestorAlert`, `DashboardUpdater`, and `TradingBot` are observers that react when the price changes.

**Exercise 3:** Create a typed event system: instead of string event names, use event classes (`UserRegisteredEvent`, `OrderPlacedEvent`). Each event carries its own data as properties.

---

## 6. Solutions

**Solution for Exercise 3:**

```php
class UserRegisteredEvent { public function __construct(public readonly int $userId, public readonly string $email) {} }

interface TypedListener { public function handle(object $event): void; }

class TypedDispatcher
{
    private array $listeners = [];
    public function subscribe(string $eventClass, TypedListener $listener): void { $this->listeners[$eventClass][] = $listener; }
    public function dispatch(object $event): void
    {
        foreach ($this->listeners[$event::class] ?? [] as $listener) { $listener->handle($event); }
    }
}
```

---

## 7. Next Up - Lesson 13

Observer defines a one-to-many dependency where all registered observers are notified automatically when the subject changes. It decouples the subject from its reactions: new observers can be added without modifying the subject class. Dispatch events from service classes, not constructors. Pass event data as arrays to prevent observers from mutating shared state. Laravel events/listeners and Symfony's event dispatcher are Observer implementations.

In Lesson 13, you will learn Template Method and Command: Template Method defines an algorithm skeleton with customizable steps, and Command encapsulates actions as objects that can be queued, logged, or undone.