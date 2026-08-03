## 1. Before You Begin

Some objects require many parameters to construct: an email with recipients, CC, BCC, subject, body, attachments, headers. A constructor with ten parameters is unreadable. Optional parameters make it worse. The **Builder** pattern lets you construct complex objects step by step, calling only the methods you need. The Builder separates the construction of a complex object from its representation: instead of a massive constructor, you chain method calls that set individual properties, then call `build()` to get the final object.

### What You'll Build

You will create an Email builder and a Query builder that construct complex objects through a fluent interface.

### What You'll Learn

- ✅ The Builder pattern: intent, structure, implementation
- ✅ Fluent interface (method chaining)
- ✅ Director class (optional orchestrator)
- ✅ Builder vs constructor: when to choose Builder
- ✅ Builder in Laravel: Query Builder, Mail Builder

### What You'll Need

- Lesson 4 completed

---

## 2. The Problem

Consider constructing an email. The constructor approach becomes unwieldy fast:

```php
// Unreadable: what does each parameter mean?
$email = new Email('john@example.com', 'jane@example.com', null, null,
    'Meeting', 'Let us meet tomorrow', 'text/html', true, null, ['file.pdf']);
```

With Builder, the same construction is clear and flexible:

```php
$email = Email::builder()
    ->from('john@example.com')
    ->to('jane@example.com')
    ->subject('Meeting')
    ->body('Let us meet tomorrow')
    ->attach('file.pdf')
    ->build();
```

---

## 3. Implementation

The Builder stores construction state and returns itself from each method (enabling chaining). The `build()` method creates the final object.

```php
<?php
namespace App\Creational\Builder;

// The product
class Email
{
    public function __construct(
        public readonly string $from,
        public readonly string $to,
        public readonly string $subject,
        public readonly string $body,
        public readonly array $cc = [],
        public readonly array $bcc = [],
        public readonly array $attachments = [],
        public readonly string $contentType = 'text/plain',
    ) {}

    public function __toString(): string
    {
        $parts = ["From: {$this->from}", "To: {$this->to}", "Subject: {$this->subject}"];
        if ($this->cc) $parts[] = "CC: " . implode(', ', $this->cc);
        if ($this->bcc) $parts[] = "BCC: " . implode(', ', $this->bcc);
        if ($this->attachments) $parts[] = "Attachments: " . implode(', ', $this->attachments);
        $parts[] = "Type: {$this->contentType}";
        $parts[] = "---\n{$this->body}";
        return implode("\n", $parts);
    }

    public static function builder(): EmailBuilder
    {
        return new EmailBuilder();
    }
}

// The builder
class EmailBuilder
{
    private string $from = '';
    private string $to = '';
    private string $subject = '';
    private string $body = '';
    private array $cc = [];
    private array $bcc = [];
    private array $attachments = [];
    private string $contentType = 'text/plain';

    public function from(string $from): static { $this->from = $from; return $this; }
    public function to(string $to): static { $this->to = $to; return $this; }
    public function subject(string $subject): static { $this->subject = $subject; return $this; }
    public function body(string $body): static { $this->body = $body; return $this; }
    public function cc(string ...$addresses): static { $this->cc = $addresses; return $this; }
    public function bcc(string ...$addresses): static { $this->bcc = $addresses; return $this; }
    public function attach(string ...$files): static { $this->attachments = array_merge($this->attachments, $files); return $this; }
    public function html(): static { $this->contentType = 'text/html'; return $this; }

    public function build(): Email
    {
        if (empty($this->from) || empty($this->to) || empty($this->subject)) {
            throw new \RuntimeException('From, to, and subject are required.');
        }
        return new Email($this->from, $this->to, $this->subject, $this->body, $this->cc, $this->bcc, $this->attachments, $this->contentType);
    }
}
```

Usage:

```php
$email = Email::builder()
    ->from('john@example.com')
    ->to('jane@example.com')
    ->cc('boss@example.com', 'team@example.com')
    ->subject('Weekly Report')
    ->body('<h1>Report</h1><p>All systems operational.</p>')
    ->html()
    ->attach('report.pdf', 'data.xlsx')
    ->build();

echo $email;
```

---

## 4. Query Builder Example

Laravel's Query Builder is one of the most famous Builder pattern implementations. Here is a simplified version:

```php
<?php
namespace App\Creational\Builder;

class QueryBuilder
{
    private string $table = '';
    private array $columns = ['*'];
    private array $wheres = [];
    private ?string $orderBy = null;
    private ?int $limit = null;

    public function table(string $table): static { $this->table = $table; return $this; }
    public function select(string ...$columns): static { $this->columns = $columns; return $this; }
    public function where(string $column, string $operator, mixed $value): static { $this->wheres[] = "{$column} {$operator} '{$value}'"; return $this; }
    public function orderBy(string $column, string $direction = 'ASC'): static { $this->orderBy = "{$column} {$direction}"; return $this; }
    public function limit(int $limit): static { $this->limit = $limit; return $this; }

    public function toSQL(): string
    {
        $sql = "SELECT " . implode(', ', $this->columns) . " FROM {$this->table}";
        if ($this->wheres) $sql .= " WHERE " . implode(' AND ', $this->wheres);
        if ($this->orderBy) $sql .= " ORDER BY {$this->orderBy}";
        if ($this->limit) $sql .= " LIMIT {$this->limit}";
        return $sql;
    }
}

// Usage
$sql = (new QueryBuilder())
    ->table('users')
    ->select('name', 'email')
    ->where('status', '=', 'active')
    ->where('age', '>', '18')
    ->orderBy('name')
    ->limit(10)
    ->toSQL();

echo $sql;
// SELECT name, email FROM users WHERE status = 'active' AND age > '18' ORDER BY name ASC LIMIT 10
```

---

## 5. Fix the Errors in Your Code

These are the three most common Builder pattern mistakes in PHP codebases.

**Error 1: Builder methods not returning `$this`.**

The entire fluent interface depends on each method returning the builder instance. If any method returns `void`, the chain breaks and the caller cannot continue without storing intermediate variables.

```php
// Wrong: method returns void, breaking the chain
public function from(string $from): void
{
    $this->from = $from;
}
// $builder->from('a')->to('b') fails — cannot chain on void

// Correct: every setter returns the builder instance
public function from(string $from): static
{
    $this->from = $from;
    return $this;
}
```

Every setter method in the builder must return `$this` (or `static` for subclass compatibility) to enable method chaining.

**Error 2: No validation in `build()`.**

A builder without validation in `build()` can silently create incomplete objects. An email with no recipient or subject will pass through the builder and fail later in an unexpected place.

```php
// Wrong: build() creates the object without checking required fields
public function build(): Email
{
    return new Email($this->from, $this->to, $this->subject, $this->body);
}

// Correct: validate required fields before creating the product
public function build(): Email
{
    if (empty($this->from) || empty($this->to) || empty($this->subject)) {
        throw new \RuntimeException('From, to, and subject are required.');
    }
    return new Email($this->from, $this->to, $this->subject, $this->body);
}
```

Always validate that all required fields are set before calling the product constructor inside `build()`.

**Error 3: Mutable product defeats the purpose of the Builder.**

If the product object can be modified after `build()` returns it, there is no guarantee that the caller receives it in the validated state the builder produced. Callers can bypass the builder's rules entirely.

```php
// Wrong: Email has public setters, so the builder's validation can be bypassed
class Email
{
    public string $from = '';
    public string $to = '';
}
$email = Email::builder()->from('a')->to('b')->build();
$email->from = ''; // validation bypassed!

// Correct: use readonly properties so the product is immutable after construction
class Email
{
    public function __construct(
        public readonly string $from,
        public readonly string $to,
    ) {}
}
```

Declare product properties as `readonly` so that once `build()` returns a validated object, its state cannot be changed.

---

## 6. Exercises

**Exercise 1:** Create an `HttpRequestBuilder` that builds HTTP request objects with method, URL, headers (array), body, and timeout. Include validation: method and URL are required.

**Exercise 2:** Create a `ReportBuilder` with title, author, sections (each with title and content), and format (PDF/HTML). The builder should allow adding multiple sections with `addSection()`.

**Exercise 3:** Create a Director class that uses the EmailBuilder to create preset email templates: `createWelcomeEmail(string $to)` and `createPasswordResetEmail(string $to, string $token)`.

---

## 7. Solutions

**Solution for Exercise 3:**

```php
class EmailDirector
{
    public function createWelcomeEmail(string $to): Email
    {
        return Email::builder()->from('noreply@app.com')->to($to)->subject('Welcome!')->body('Welcome to our platform.')->build();
    }
    public function createPasswordResetEmail(string $to, string $token): Email
    {
        return Email::builder()->from('noreply@app.com')->to($to)->subject('Reset Password')->body("Reset link: https://app.com/reset/{$token}")->build();
    }
}
```

---

## 8. Next Up - Lesson 6

Builder constructs complex objects step by step through a fluent interface. Each setter method returns `$this` for chaining. The `build()` method validates and creates the final product, which should be immutable with `readonly` properties. A Director class can encapsulate common construction sequences. Laravel's Query Builder and Mail builder are real-world examples of this pattern.

In Lesson 6, you will learn the Prototype pattern: a way to create new objects by cloning an existing instance instead of constructing from scratch, which is useful when object creation is expensive.