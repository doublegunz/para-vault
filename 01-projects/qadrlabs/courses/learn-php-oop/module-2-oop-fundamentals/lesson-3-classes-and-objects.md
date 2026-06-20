## 1. Before You Begin

### Introduction

In the previous lesson, we set up a clean project structure with Composer autoloading. But so far, we have not written a single class. Everything has been procedural PHP. This lesson introduces the most fundamental concept in OOP: the **class**.

In procedural PHP, you represented a journal entry as an associative array: `$entry = ['title' => '...', 'content' => '...']`. This works, but nothing prevents you from misspelling a key, there is no way to attach behavior to the data, and there is no guarantee about what keys exist or what types they contain. A class solves all of these problems.

### What You'll Build

You will create the `Entry` class that represents a journal entry, then create multiple `Entry` objects and display their data.

### What You'll Learn

- ✅ What a class is and how it differs from procedural code
- ✅ How to define properties (data) and methods (behavior) on a class
- ✅ How to create objects using the `new` keyword
- ✅ The difference between a class (the blueprint) and an object (an instance)
- ✅ How `$this` refers to the current object inside a method

### What You'll Need

- The Catatku project from Lesson 2 with Composer autoloading
- The development server running (`php -S localhost:8080 -t public`)

---

## 2. Setup

In the VS Code Explorer, right-click on the `src` folder and create a new folder called `Models`.

Your project structure now includes:
```
catatku/
├── src/
│   └── Models/     ← newly created
├── public/
│   └── index.php
└── ...
```

---

## 3. Create the Entry Class

In this section you will create the first PHP file that contains a complete class with properties and methods. The `Entry` class represents a single journal entry with an explicitly defined data structure.

### Step 1: Create the File

Right-click on the `src/Models` folder, select **New File**, type `Entry.php`, and press Enter.

### Step 2: Write the Code

Open `src/Models/Entry.php` and type the following code:

```php
<?php

namespace App\Models;

class Entry
{
    public int $id;
    public string $title;
    public string $content;
    public int $userId;
    public string $createdAt;
    public ?string $updatedAt;

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

`namespace App\Models;` declares that this class belongs to the `App\Models` namespace. Thanks to PSR-4 autoloading, Composer knows to find this file at `src/Models/Entry.php`.

`class Entry` defines a new class. A class is a blueprint that describes what data an entry has (properties) and what it can do (methods).

**Properties** like `public int $id` and `public string $title` define the data that every Entry object will hold. The type declarations (`int`, `string`, `?string`) tell PHP what kind of value each property expects. The `?` prefix on `?string` means the value can be `null`.

**Methods** like `getExcerpt()` and `isEdited()` define behavior. Inside a method, `$this` refers to the current object. So `$this->content` accesses the `content` property of whichever object the method is called on.

---

## 4. Use the Entry Class

Now that the `Entry` class exists, it is time to use it in `public/index.php`. This section shows how to create objects from the class, assign values to each property, and call the methods we defined.

### Step 1: Open the File

Open `public/index.php`.

### Step 2: Replace the Code

Replace the entire content of `public/index.php` with:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Models\Entry;

// Create an Entry object
$entry = new Entry();
$entry->id = 1;
$entry->title = 'My first entry';
$entry->content = 'This is the content of my first journal entry. It has quite a lot of text to demonstrate the excerpt feature that we built into the class.';
$entry->userId = 1;
$entry->createdAt = '2026-02-20 10:00:00';
$entry->updatedAt = null;

// Access properties and call methods
echo '<h1>' . htmlspecialchars($entry->title) . '</h1>';
echo '<p>' . htmlspecialchars($entry->getExcerpt(50)) . '</p>';
echo '<p>Edited: ' . ($entry->isEdited() ? 'Yes' : 'No') . '</p>';

echo '<hr>';

// Create a second Entry, each object is independent
$entry2 = new Entry();
$entry2->id = 2;
$entry2->title = 'Learning PHP OOP';
$entry2->content = 'Classes and objects are the foundation of OOP.';
$entry2->userId = 1;
$entry2->createdAt = '2026-02-19 10:00:00';
$entry2->updatedAt = '2026-02-19 15:30:00';

echo '<h1>' . htmlspecialchars($entry2->title) . '</h1>';
echo '<p>' . htmlspecialchars($entry2->getExcerpt(50)) . '</p>';
echo '<p>Edited: ' . ($entry2->isEdited() ? 'Yes' : 'No') . '</p>';
```

### Step 3: Save the File

Press **Ctrl+S**.

### Step 4: Run in the Browser

Make sure the development server is running (`php -S localhost:8080 -t public`). Open:

```
http://localhost:8080
```

You will see two entries displayed. The first shows "Edited: No" because `updatedAt` is null. The second shows "Edited: Yes" because `updatedAt` differs from `createdAt`.

### Code Breakdown

`use App\Models\Entry;` imports the class so you can write `new Entry()` instead of `new \App\Models\Entry()`.

`$entry = new Entry();` creates a new **object** from the Entry class. `$entry` and `$entry2` are two different objects, each holding different data, but both created from the same blueprint.

`$entry->title` accesses a property using the arrow operator `->`. `$entry->getExcerpt(50)` calls a method on the object.

---

## 5. Classes vs Objects {#classes-vs-objects}

This is the most important distinction in OOP.

A **class** is the blueprint. It defines what properties and methods exist, but it holds no actual data. The `Entry` class says "every entry has a title, content, and a method called `getExcerpt`."

An **object** is an instance created from a class. It holds actual data. When you write `$entry = new Entry()`, you create an object. You can create as many objects as you need from the same class, each with different data.

Think of it like a cookie cutter and cookies. The class is the cookie cutter (the shape). The objects are the cookies (the actual things with different decorations). One cutter, many cookies.

---

## 6. Fix the Errors in Your Code

Look at the following code and find the mistakes:

```php
<?php
// File: public/index.php
require_once __DIR__ . '/../vendor/autoload.php';

// Error 1: Missing use statement
$entry = new Entry();

// Error 2: Wrong property name
$entry->judul = 'My Entry';

// Error 3: Calling a method that does not exist
echo $entry->getSummary();
```

**Error 1 — Missing `use` statement.** Without `use App\Models\Entry;`, PHP does not know which `Entry` class you mean. Add the `use` statement after the `require_once` line.

**Error 2 — Property `judul` does not exist.** The class defines `$title`, not `$judul`. Unlike associative arrays where you can add any key, a class only allows properties that are defined in the class. This is one of the advantages of OOP: misspelled property names cause errors instead of silently creating wrong data.

**Error 3 — Method `getSummary()` does not exist.** The class has `getExcerpt()`, not `getSummary()`. PHP will throw a fatal error for calling a non-existent method.

---

## 7. Exercises

**Exercise 1:** Create a `User` class at `src/Models/User.php` with namespace `App\Models`. Give it public properties: `int $id`, `string $name`, `string $email`, `string $createdAt`. Add a method `getInitials(): string` that returns the first letter of each word in the name (e.g. "Budi Santoso" returns "BS"). Test it in `public/index.php`.

**Exercise 2:** Add a method `getWordCount(): int` to the `Entry` class that returns the number of words in the `$content` property using `str_word_count()`. Update `public/index.php` to display the word count for each entry.

**Exercise 3:** Create a file `public/test-objects.php` that creates 3 `Entry` objects with different data, stores them in an array, and displays all of them in an HTML table with columns: Title, Excerpt (50 chars), Word Count, Edited.

---

## 8. Solutions

**Solution for Exercise 1:**

Create `src/Models/User.php`:

```php
<?php

namespace App\Models;

class User
{
    public int $id;
    public string $name;
    public string $email;
    public string $createdAt;

    public function getInitials(): string
    {
        $words = explode(' ', $this->name);
        $initials = '';
        foreach ($words as $word) {
            $initials .= strtoupper(mb_substr($word, 0, 1));
        }
        return $initials;
    }
}
```

`explode(' ', $this->name)` splits the name by spaces into an array of words. The `foreach` loop iterates over each word, extracts the first character with `mb_substr($word, 0, 1)`, then converts it to uppercase with `strtoupper()`. The `mb_` prefix ensures correct handling of multi-byte Unicode characters.

Save the file. Test in `public/index.php` by adding:

```php
use App\Models\User;

$user = new User();
$user->id = 1;
$user->name = 'Budi Santoso';
$user->email = 'budi@example.com';
$user->createdAt = '2026-01-15 08:00:00';

echo '<p>User: ' . htmlspecialchars($user->name) . ' (' . $user->getInitials() . ')</p>';
```

The pattern is identical to how the `Entry` object was used: create an object, assign each property, then call the method you need. The call to `$user->getInitials()` is placed directly inside `echo`, so the result is printed immediately without storing it in a temporary variable.

Run at: `http://localhost:8080`

**Solution for Exercise 2:**

Add this method to `src/Models/Entry.php` inside the class:

```php
    public function getWordCount(): int
    {
        return str_word_count($this->content);
    }
```

`str_word_count($this->content)` is a built-in PHP function that counts the number of words in a string and returns an integer. Using `$this->content` inside the method means each `Entry` object counts the words in its own content independently.

Save the file. Use it in `public/index.php`:

```php
echo '<p>Words: ' . $entry->getWordCount() . '</p>';
```

**Solution for Exercise 3:**

Create `public/test-objects.php`:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Models\Entry;

$entries = [];

$e1 = new Entry();
$e1->id = 1;
$e1->title = 'First Entry';
$e1->content = 'This is my first journal entry about learning PHP OOP concepts.';
$e1->userId = 1;
$e1->createdAt = '2026-02-20 10:00:00';
$e1->updatedAt = null;
$entries[] = $e1;

$e2 = new Entry();
$e2->id = 2;
$e2->title = 'Learning Classes';
$e2->content = 'Classes are blueprints. Objects are instances. This is the most fundamental concept.';
$e2->userId = 1;
$e2->createdAt = '2026-02-21 09:00:00';
$e2->updatedAt = '2026-02-21 14:00:00';
$entries[] = $e2;

$e3 = new Entry();
$e3->id = 3;
$e3->title = 'Weekend Coding';
$e3->content = 'Spent the weekend building Catatku with PHP OOP. Progress feels great.';
$e3->userId = 1;
$e3->createdAt = '2026-02-22 15:00:00';
$e3->updatedAt = null;
$entries[] = $e3;

echo '<h2>Entry List</h2>';
echo '<table border="1" cellpadding="8" cellspacing="0">';
echo '<tr><th>Title</th><th>Excerpt</th><th>Words</th><th>Edited</th></tr>';
foreach ($entries as $entry) {
    echo '<tr>';
    echo '<td>' . htmlspecialchars($entry->title) . '</td>';
    echo '<td>' . htmlspecialchars($entry->getExcerpt(50)) . '</td>';
    echo '<td>' . $entry->getWordCount() . '</td>';
    echo '<td>' . ($entry->isEdited() ? 'Yes' : 'No') . '</td>';
    echo '</tr>';
}
echo '</table>';
```

This script creates three `Entry` objects and stores them in the `$entries` array. The `foreach` block iterates over each element and renders one HTML table row per object. All three objects share the same class but hold their own data independently.

Save the file. Run at: `http://localhost:8080/test-objects.php`

---

## 9. Conclusion

You have created your first PHP class and learned the most fundamental OOP concept. A class is a blueprint that defines properties and methods. An object is an instance created from a class using `new`. Each object holds its own data. The `->` arrow operator accesses properties and methods, and `$this` inside a method refers to the current object.

Right now, properties are `public` and can be set to anything from anywhere. There is nothing stopping someone from creating an Entry without a title, or changing the ID after creation.

---

## Next Up - Lesson 4: Constructors and Encapsulation

In the next lesson you will:

1. Use `__construct()` so objects are always created in a valid state
2. Learn the visibility modifiers `public`, `private`, and `protected`
3. Understand encapsulation and why it protects the integrity of an object's data

The `Entry` class you built in this lesson will be refactored to apply all of these concepts.