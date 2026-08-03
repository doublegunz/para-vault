## 1. Before You Begin

Collections need to be traversed without exposing their internal structure. Should the client know if data is stored in an array, a linked list, or a database result set? No. The **Iterator** pattern provides a uniform way to traverse any collection. Meanwhile, when many objects communicate with each other, the connections become tangled. Adding a new participant means updating every other participant. The **Mediator** pattern centralizes communication through a single mediator object, reducing N-to-N dependencies to N connections.

### What You'll Build

You will create a custom collection with an Iterator for paginated database results, and a Mediator for a chat room where users communicate through the room instead of directly with each other.

### What You'll Learn

- ✅ Iterator: traverse collections with a uniform interface
- ✅ PHP's `Iterator` and `IteratorAggregate` interfaces
- ✅ Custom iterators for specialized traversal
- ✅ Mediator: centralize complex communication
- ✅ Reducing N*N connections to N connections through a mediator

### What You'll Need

- Lesson 14 completed

---

## 2. Iterator Pattern

PHP has built-in Iterator support. Implementing `IteratorAggregate` lets your custom collection work with `foreach`.

```php
<?php
namespace App\Behavioral\Iterator;

class PaginatedCollection implements \IteratorAggregate, \Countable
{
    private array $items;
    private int $perPage;

    public function __construct(array $items, int $perPage = 5)
    {
        $this->items = $items;
        $this->perPage = $perPage;
    }

    public function getIterator(): \ArrayIterator
    {
        return new \ArrayIterator($this->items);
    }

    public function count(): int { return count($this->items); }

    public function getPage(int $page): array
    {
        $offset = ($page - 1) * $this->perPage;
        return array_slice($this->items, $offset, $this->perPage);
    }

    public function getTotalPages(): int
    {
        return (int) ceil(count($this->items) / $this->perPage);
    }

    // Custom iterator: yields items page by page
    public function pages(): \Generator
    {
        for ($page = 1; $page <= $this->getTotalPages(); $page++) {
            yield $page => $this->getPage($page);
        }
    }
}

// Usage
$users = new PaginatedCollection([
    'Alice', 'Bob', 'Charlie', 'David', 'Eve',
    'Frank', 'Grace', 'Henry', 'Ivy', 'Jack',
    'Karen', 'Leo',
], perPage: 4);

// Standard iteration with foreach (IteratorAggregate)
foreach ($users as $user) { echo "{$user} "; }
echo "\n";

// Page-by-page iteration (Generator)
foreach ($users->pages() as $pageNum => $pageItems) {
    echo "Page {$pageNum}: " . implode(', ', $pageItems) . "\n";
}
echo "Total pages: {$users->getTotalPages()}\n";
```

---

## 3. Mediator Pattern

Without Mediator, N objects communicating directly create N*(N-1)/2 connections. The Mediator reduces this to N connections (each object connects only to the mediator).

```php
<?php
namespace App\Behavioral\Mediator;

// Mediator interface
interface ChatMediator
{
    public function sendMessage(string $message, User $sender): void;
    public function addUser(User $user): void;
}

// Concrete mediator
class ChatRoom implements ChatMediator
{
    private array $users = [];

    public function addUser(User $user): void
    {
        $this->users[$user->getName()] = $user;
        $user->setMediator($this);
        echo "[ChatRoom] {$user->getName()} joined.\n";
    }

    public function sendMessage(string $message, User $sender): void
    {
        foreach ($this->users as $user) {
            if ($user !== $sender) {
                $user->receive($message, $sender->getName());
            }
        }
    }
}

// Colleague
class User
{
    private ?ChatMediator $mediator = null;

    public function __construct(private string $name) {}

    public function getName(): string { return $this->name; }
    public function setMediator(ChatMediator $mediator): void { $this->mediator = $mediator; }

    public function send(string $message): void
    {
        echo "[{$this->name}] Sends: {$message}\n";
        $this->mediator->sendMessage($message, $this);
    }

    public function receive(string $message, string $from): void
    {
        echo "[{$this->name}] Received from {$from}: {$message}\n";
    }
}

// Usage
$chatRoom = new ChatRoom();
$budi = new User('Budi');
$citra = new User('Citra');
$dewi = new User('Dewi');

$chatRoom->addUser($budi);
$chatRoom->addUser($citra);
$chatRoom->addUser($dewi);

$budi->send('Hello everyone!');
$citra->send('Hi Budi!');
```

Budi does not communicate with Citra directly. All messages go through the ChatRoom mediator.

---

## 4. Fix the Errors in Your Code

These are the three most common Iterator and Mediator mistakes in PHP codebases.

**Error 1: Iterator `valid()` method always returns `true`, causing an infinite loop.**

The `valid()` method tells `foreach` whether there is a current element to process. If it never returns `false`, `foreach` will loop forever without ever stopping.

```php
// Wrong: valid() always returns true — infinite loop in foreach
class BadIterator implements \Iterator
{
    public function valid(): bool { return true; }
}

// Correct: track the current position and compare against the collection size
class GoodIterator implements \Iterator
{
    private int $position = 0;

    public function __construct(private array $items) {}

    public function current(): mixed { return $this->items[$this->position]; }
    public function key(): int { return $this->position; }
    public function next(): void { $this->position++; }
    public function rewind(): void { $this->position = 0; }
    public function valid(): bool { return isset($this->items[$this->position]); }
}
```

Always track the current position in a private property and check it against the collection size in `valid()`. Use `isset()` to handle non-sequential arrays safely.

**Error 2: Mediator broadcasts messages back to the sender.**

When a user sends a message through the mediator, that message should go to all other participants. If the sender also receives the message, every chat becomes an echo of what the user just said.

```php
// Wrong: sender receives their own message
public function sendMessage(string $message, User $sender): void
{
    foreach ($this->users as $user) {
        $user->receive($message, $sender->getName());
    }
}

// Correct: exclude the sender from the broadcast
public function sendMessage(string $message, User $sender): void
{
    foreach ($this->users as $user) {
        if ($user !== $sender) {
            $user->receive($message, $sender->getName());
        }
    }
}
```

Always add an identity check (`$user !== $sender`) inside the mediator's broadcast loop to exclude the originator of the message.

**Error 3: Colleague that communicates directly with other colleagues, bypassing the mediator.**

If a user object holds a direct reference to another user and sends messages to it directly, the mediator is bypassed. The communication is hidden from the mediator, which can no longer enforce logging, filtering, or routing rules.

```php
// Wrong: Budi holds a reference to Citra and speaks to her directly
$budi->directMessage($citra, 'Secret');

// Correct: all communication goes through the mediator
$budi->send('Hello everyone!'); // internally calls $this->mediator->sendMessage(...)
```

Colleague classes should hold only a reference to the mediator, never to other colleagues directly. All inter-colleague communication is initiated by calling a method on the mediator.

---

## 5. Exercises

**Exercise 1:** Create a `FilterIterator` that wraps a collection and only yields items matching a predicate function. Example: iterate only active users.

**Exercise 2:** Create an `AirTrafficControl` mediator for `Airplane` objects. Planes request landing/takeoff through the controller, which checks if the runway is free.

**Exercise 3:** Create a `FormMediator` that coordinates form fields: when "country" changes, it updates the "city" dropdown. When "type" changes, it shows/hides the "company" field.

---

## 6. Solutions

**Solution for Exercise 1:**

```php
class FilterIterator implements \IteratorAggregate
{
    public function __construct(private array $items, private \Closure $predicate) {}
    public function getIterator(): \Generator
    {
        foreach ($this->items as $item) {
            if (($this->predicate)($item)) yield $item;
        }
    }
}
$active = new FilterIterator($users, fn($u) => $u['status'] === 'active');
foreach ($active as $user) { echo $user['name'] . "\n"; }
```

---

## 7. Next Up - Lesson 16

Iterator provides uniform traversal for any collection without exposing its internal structure. PHP's `IteratorAggregate` and Generators make custom iterators straightforward to implement. Mediator centralizes communication between many objects, reducing N-to-N dependencies to N connections through a single hub. Use Iterator for custom collections; use Mediator when objects have complex, many-to-many communication that is difficult to trace.

In Lesson 16, you will learn Memento, Visitor, and Interpreter: the three remaining behavioral patterns that solve specialized problems in state management, class hierarchy operations, and grammar evaluation.