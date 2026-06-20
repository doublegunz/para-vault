## 1. Before You Begin

### Introduction

In the previous lesson, we created the Entry class and manually set each property after creating the object. That works, but it has a problem: nothing stops you from creating an Entry without a title, or from changing the ID after creation. This lesson introduces two concepts that fix both issues: **constructors** and **encapsulation**.

### What You'll Build

You will refactor the Entry class to use a constructor for guaranteed initialization and private properties with getters and setters for controlled access.

### What You'll Learn

- ✅ How `__construct()` ensures objects are created in a valid state
- ✅ Visibility modifiers: `public`, `private`, and `protected`
- ✅ Why encapsulation matters: controlling how data is accessed and modified
- ✅ Getters and setters for controlled property access
- ✅ PHP 8's constructor promotion shorthand

### What You'll Need

- The Catatku project from Lesson 3 with the `Entry` class
- The development server running (`php -S localhost:8080 -t public`)

---

## 2. Add a Constructor and Private Properties

In this section you will refactor the Entry class by adding a constructor that requires all essential data at creation time and changing all properties from `public` to `private`.

### Step 1: Open the File

Open `src/Models/Entry.php` in VS Code.

### Step 2: Replace the Code

Replace the entire content of `src/Models/Entry.php` with:

```php
<?php

namespace App\Models;

class Entry
{
    private int $id;
    private string $title;
    private string $content;
    private int $userId;
    private string $createdAt;
    private ?string $updatedAt;

    public function __construct(
        int $id,
        string $title,
        string $content,
        int $userId,
        string $createdAt,
        ?string $updatedAt = null
    ) {
        $this->id = $id;
        $this->title = $title;
        $this->content = $content;
        $this->userId = $userId;
        $this->createdAt = $createdAt;
        $this->updatedAt = $updatedAt;
    }

    // Getters: read-only access to private properties
    public function getId(): int { return $this->id; }
    public function getTitle(): string { return $this->title; }
    public function getContent(): string { return $this->content; }
    public function getUserId(): int { return $this->userId; }
    public function getCreatedAt(): string { return $this->createdAt; }
    public function getUpdatedAt(): ?string { return $this->updatedAt; }

    // Setters: only for properties that SHOULD be changeable
    public function setTitle(string $title): void { $this->title = $title; }
    public function setContent(string $content): void { $this->content = $content; }
    public function setUpdatedAt(?string $updatedAt): void { $this->updatedAt = $updatedAt; }

    // Note: no setId(), no setUserId(), no setCreatedAt()
    // These values should never change after creation

    public function getExcerpt(int $length = 100): string
    {
        if (mb_strlen($this->content) <= $length) {
            return $this->content;
        }

        return mb_substr($this->content, 0, $length) . '...';
    }

    public function isEdited(): bool
    {
        return $this->updatedAt !== null && $this->updatedAt !== $this->createdAt;
    }
}
```

### Step 3: Save the File

Press **Ctrl+S**.

### Code Breakdown

`__construct()` is a special method that runs automatically when you create an object with `new`. It guarantees that every Entry object starts with all required data.

Properties changed from `public` to `private`. This is **encapsulation**: only the class itself can directly access its data. The outside world must use getter methods (for reading) and setter methods (for writing).

Properties that should never change after creation (`id`, `userId`, `createdAt`) have getters but **no setters**. The ID is set once in the constructor and can never be changed from outside.

Properties that should be changeable (`title`, `content`, `updatedAt`) have both getters and setters. Setters give you a place to add validation later if needed.

> **Heads up:** Standalone scripts from earlier lessons that set properties directly (for example `public/test-objects.php` from Lesson 3, which used `$entry->id = 1;`) will now error. The properties are `private` and the constructor requires arguments, so the old public-property API no longer works. That is expected after this refactor. You can safely delete those throwaway test files.

---

## 3. Use the Refactored Class

With the refactored Entry class ready, this section updates `public/index.php` to use the new constructor syntax and getter methods instead of direct property access.

### Step 1: Open the File

Open `public/index.php`.

### Step 2: Replace the Code

Replace the entire content with:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Models\Entry;

// Now creating an Entry requires all essential data upfront
$entry = new Entry(
    id: 1,
    title: 'My first entry',
    content: 'This is the content of my first journal entry. It demonstrates constructors and encapsulation in PHP OOP.',
    userId: 1,
    createdAt: '2026-02-20 10:00:00'
);

echo '<h1>' . htmlspecialchars($entry->getTitle()) . '</h1>';
echo '<p>' . htmlspecialchars($entry->getExcerpt(50)) . '</p>';
echo '<p>ID: ' . $entry->getId() . '</p>';
echo '<p>Edited: ' . ($entry->isEdited() ? 'Yes' : 'No') . '</p>';

// Change title using the setter
$entry->setTitle('Updated title');
echo '<p>New title: ' . htmlspecialchars($entry->getTitle()) . '</p>';

// These would cause errors:
// $entry->id = 999;     // Error! $id is private
// $entry->title;        // Error! $title is private, use getTitle()
// new Entry();          // Error! Constructor requires arguments
```

`new Entry(id: 1, title: '...', ...)` uses PHP 8 **named arguments**, which allow passing values by parameter name in any order. This makes the constructor call self-documenting. `$entry->getTitle()` reads the private property through the getter. The three commented lines at the bottom are intentionally invalid, serving as a reminder of what encapsulation prevents.

### Step 3: Save and Run

Save the file (**Ctrl+S**). Open:

```
http://localhost:8080
```

---

## 4. Understanding Visibility

**`public`** means anyone can read and write. This is wide open.

**`private`** means only the class itself can access the property. The outside world must use methods.

**`protected`** means the class and its children (subclasses) can access it. We will use this in Lesson 13.

Why does this matter? With `public` properties, anyone could write `$entry->id = 999` and change the ID. With `private` properties and no setter for `id`, the ID is set once in the constructor and can never be changed.

---

## 5. Constructor Promotion (PHP 8)

PHP 8 introduced **constructor promotion**, a shorthand that declares and assigns properties in one line:

```php
public function __construct(
    private int $id,
    private string $title,
    private string $content,
    private int $userId,
    private string $createdAt,
    private ?string $updatedAt = null,
) {}
```

This does exactly the same thing as the longer version. We use the longer form in this course for clarity, but you will see constructor promotion frequently in framework code.

---

## 6. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
use App\Models\Entry;

// Error 1: Creating object without required arguments
$entry = new Entry();
$entry->title = 'My Entry';

// Error 2: Accessing private property directly
echo $entry->content;

// Error 3: Trying to set an immutable property
$entry = new Entry(1, 'Title', 'Content', 1, '2026-01-01');
$entry->setId(999);
```

**Error 1 — Constructor requires arguments.** You cannot create an empty Entry anymore. The constructor enforces that all required data is provided: `new Entry(id: 1, title: 'My Entry', content: '...', userId: 1, createdAt: '...')`.

**Error 2 — Direct access to private property.** `$entry->content` does not work because `content` is `private`. Use the getter: `$entry->getContent()`.

**Error 3 — No `setId()` method exists.** The ID is immutable by design. There is no setter for it, so once set in the constructor, it cannot be changed.

---

## 7. Exercises

**Exercise 1:** Add a validation rule inside the `setTitle()` method: if the title is empty or longer than 255 characters, throw an `\InvalidArgumentException` with a descriptive message. Test it in `public/index.php` by wrapping the call in a `try/catch` block.

**Exercise 2:** Create a method `toArray(): array` on the Entry class that returns all properties as an associative array (like `['id' => 1, 'title' => '...', ...]`). Test it in `public/index.php` using `print_r()`.

**Exercise 3:** Refactor the `User` class from Exercise 1 of Lesson 3 to use a constructor with private properties, getters, and no setters for `id` and `email`. Add a setter only for `name`. Test the refactored class in `public/index.php`.

---

## 8. Solutions

**Solution for Exercise 1:**

In `src/Models/Entry.php`, replace `setTitle`:

```php
    public function setTitle(string $title): void
    {
        if (empty(trim($title))) {
            throw new \InvalidArgumentException('Title cannot be empty.');
        }
        if (strlen($title) > 255) {
            throw new \InvalidArgumentException('Title must be 255 characters or less.');
        }
        $this->title = $title;
    }
```

`empty(trim($title))` trims whitespace from both ends first, then checks if the result is empty. This catches inputs that consist only of spaces. `strlen($title) > 255` validates the maximum length. Throwing `\InvalidArgumentException` is the PHP standard convention for signaling that a method received an invalid argument.

Test in `public/index.php`:

```php
try {
    $entry->setTitle('');
} catch (\InvalidArgumentException $e) {
    echo '<p style="color:red">Error: ' . $e->getMessage() . '</p>';
}
```

The `try` block calls `setTitle('')` with an empty string. When the setter throws `\InvalidArgumentException`, execution jumps to the `catch` block and `$e->getMessage()` retrieves the message that was passed to the exception's constructor.

Run at: `http://localhost:8080`

**Solution for Exercise 2:**

Add to `src/Models/Entry.php`:

```php
    public function toArray(): array
    {
        return [
            'id'         => $this->id,
            'title'      => $this->title,
            'content'    => $this->content,
            'userId'     => $this->userId,
            'createdAt'  => $this->createdAt,
            'updatedAt'  => $this->updatedAt,
        ];
    }
```

`toArray()` returns an associative array where each key is a property name and each value is that property's current value. Using `$this->propertyName` inside a method is valid even for private properties because the method is defined within the same class.

Test in `public/index.php`:

```php
echo '<pre>';
print_r($entry->toArray());
echo '</pre>';
```

`print_r()` outputs a human-readable representation of an array. Wrapping it between `<pre>` tags preserves whitespace and indentation, making the nested array structure much easier to read in the browser.

**Solution for Exercise 3:**

Replace `src/Models/User.php`:

```php
<?php

namespace App\Models;

class User
{
    private int $id;
    private string $name;
    private string $email;
    private string $createdAt;

    public function __construct(int $id, string $name, string $email, string $createdAt)
    {
        $this->id = $id;
        $this->name = $name;
        $this->email = $email;
        $this->createdAt = $createdAt;
    }

    public function getId(): int { return $this->id; }
    public function getName(): string { return $this->name; }
    public function getEmail(): string { return $this->email; }
    public function getCreatedAt(): string { return $this->createdAt; }

    public function setName(string $name): void { $this->name = $name; }
}
```

The constructor assigns all four properties at once, ensuring every User object is fully initialized from the start. Notice that `setId()`, `setEmail()`, and `setCreatedAt()` are deliberately absent: these values should never change after creation. Only `setName()` is provided because a user's display name could legitimately be updated.

Run at: `http://localhost:8080`

---

## 9. Conclusion

Constructors ensure every object starts in a valid state. Encapsulation (private properties with getters/setters) controls how data is accessed and modified. Properties that should never change have getters but no setters. This is not unnecessary bureaucracy; it prevents entire categories of bugs.

---

## Next Up - Lesson 5: Namespaces and Autoloading

In the next lesson you will:

1. Organize the growing codebase with PHP namespaces
2. Verify that Composer's PSR-4 autoloader finds all your classes automatically
3. Remove every manual `require` statement from the project