## 1. Before You Begin

### Introduction

As our project grows, we will have many classes: Entry, User, EntryRepository, Database, Router, and more. Without a system for organizing them, we would need a `require` statement for every single file, and class name collisions would become inevitable. This lesson introduces **namespaces** and confirms how **PSR-4 autoloading** eliminates both problems.

### What You'll Build

You will create the `User` model class and a `Database` placeholder class, organize them with namespaces, and verify that Composer's autoloader finds everything automatically.

### What You'll Learn

- ✅ What namespaces are and why they prevent name collisions
- ✅ How PSR-4 autoloading maps namespaces to directories
- ✅ The `use` statement for importing classes
- ✅ How to structure classes across multiple directories
- ✅ Why you never need `require` or `include` for your own classes again

### What You'll Need

- The Catatku project with the Entry class from Lesson 4
- The development server running

---

## 2. Understand the Problem

Without namespaces, every class name must be unique across your entire project and all libraries. Imagine you have a `User` class and a library you installed also has a `User` class. PHP would not know which one you mean.

**Namespaces** add a prefix path to class names. `App\Models\User` and `Vendor\Auth\User` can coexist because they have different fully qualified names.

Without autoloading, you would need a `require` line for every class file. With PSR-4, the single `require_once __DIR__ . '/../vendor/autoload.php'` handles everything.

---

## 3. Create the User Class

In this section you will create the `User` model that represents a registered account in the application. This class follows the same encapsulation pattern introduced in Lesson 4.

### Step 1: Create the File

In the VS Code Explorer, right-click on the `src/Models` folder, select **New File**, type `User.php`, and press Enter.

### Step 2: Write the Code

Open `src/Models/User.php` and type the following code:

```php
<?php

namespace App\Models;

class User
{
    private int $id;
    private string $name;
    private string $email;
    private string $password;
    private string $createdAt;

    public function __construct(
        int $id,
        string $name,
        string $email,
        string $password,
        string $createdAt
    ) {
        $this->id = $id;
        $this->name = $name;
        $this->email = $email;
        $this->password = $password;
        $this->createdAt = $createdAt;
    }

    public function getId(): int { return $this->id; }
    public function getName(): string { return $this->name; }
    public function getEmail(): string { return $this->email; }
    public function getPassword(): string { return $this->password; }
    public function getCreatedAt(): string { return $this->createdAt; }
}
```

The `namespace App\Models;` declaration gives this class the fully qualified name `App\Models\User`. Thanks to PSR-4 autoloading, Composer knows to locate it at `src/Models/User.php`.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 4. Create the Database Placeholder

In this section you will create a `Database` class that lives in the root `App` namespace. This placeholder confirms that a class does not have to be in a subdirectory, and it will be replaced with a real PDO connection in Lesson 6.

### Step 1: Create the File

Right-click on the `src` folder (not `src/Models`), select **New File**, type `Database.php`, and press Enter.

### Step 2: Write the Code

Open `src/Database.php` and type the following code:

```php
<?php

namespace App;

class Database
{
    // We will fill this with a real PDO connection in Lesson 6
    public function getConnection(): string
    {
        return 'Database connection placeholder';
    }
}
```

This class uses namespace `App` instead of `App\Models`, so it lives directly in `src/` rather than a subdirectory. The autoloader resolves `App\Database` to `src/Database.php`.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 5. Verify Autoloading

This section brings all three classes together in `public/index.php` to confirm that Composer's autoloader resolves each one correctly without any manual `require` calls.

### Step 1: Regenerate the Autoloader

Open the terminal and run:

```bash
composer dump-autoload
```

### Step 2: Update the Entry Point

Open `public/index.php` and replace its content with:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Models\Entry;
use App\Models\User;
use App\Database;

$entry = new Entry(
    id: 1,
    title: 'Namespaces work!',
    content: 'All classes are loaded automatically by Composer.',
    userId: 1,
    createdAt: '2026-02-20 10:00:00'
);

$user = new User(
    id: 1,
    name: 'Budi',
    email: 'budi@example.com',
    password: 'hashed_password_here',
    createdAt: '2026-02-20 10:00:00'
);

$db = new Database();

echo '<h1>' . htmlspecialchars($entry->getTitle()) . '</h1>';
echo '<p>Author: ' . htmlspecialchars($user->getName()) . '</p>';
echo '<p>' . $db->getConnection() . '</p>';
```

Three classes from three different namespaces (`App\Models\Entry`, `App\Models\User`, `App\Database`) are all instantiated without any explicit `require` for them. The `use` statements at the top provide the fully qualified names, and the autoloader resolves each one to the correct file path automatically.

### Step 3: Save and Run

Save the file (**Ctrl+S**). Open:

```
http://localhost:8080
```

All three classes load correctly without any `require` statements for them. The current project structure:

```
src/
├── Database.php           ← App\Database
└── Models/
    ├── Entry.php          ← App\Models\Entry
    └── User.php           ← App\Models\User
```

---

## 6. How PSR-4 Autoloading Works

When PHP encounters `new Entry()`, it asks the autoloader: "Where is this class?" The autoloader follows these steps:

1. Look at the `use` statement: the full name is `App\Models\Entry`
2. Match the prefix `App\` to the directory `src/`
3. Convert the remaining namespace `Models\Entry` to a path: `Models/Entry.php`
4. Load the file `src/Models/Entry.php`

This happens automatically. You only need the one `require_once` for Composer's autoloader, and all your classes are available.

---

## 7. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
require_once __DIR__ . '/../vendor/autoload.php';

// Error 1: Wrong namespace in class file
// File: src/Models/User.php contains: namespace App;
// But the file is in src/Models/ which should be App\Models

// Error 2: Using class without use statement
$user = new User(1, 'Budi', 'budi@example.com', 'pass', '2026-01-01');

// Error 3: Class file in wrong directory
// File: src/Controllers/Database.php
// But namespace is: App\Database (should be at src/Database.php)
```

**Error 1 — Namespace does not match directory.** If the file is at `src/Models/User.php`, the namespace must be `App\Models`, not `App`. The namespace path must mirror the directory path.

**Error 2 — Missing `use` statement.** Without `use App\Models\User;`, PHP looks for a `User` class in the global namespace and fails. Always add the `use` statement.

**Error 3 — File in wrong directory for its namespace.** If the namespace is `App\Database`, the file must be at `src/Database.php`. If you put it in `src/Controllers/Database.php`, the autoloader will not find it because the path does not match the namespace.

---

## 8. Exercises

**Exercise 1:** Create a class `App\Helpers\TextHelper` at `src/Helpers/TextHelper.php` with a static method `excerpt(string $text, int $length = 100): string` that returns a truncated text. Test it in `public/index.php`. Remember to create the `Helpers` folder first and run `composer dump-autoload`.

**Exercise 2:** Without running the code, write down the expected file path for each class: `App\Controllers\EntryController`, `App\Repositories\EntryRepository`, `App\Models\Category`.

**Exercise 3:** Create a file `public/test-autoload.php` that uses all classes created so far (`Entry`, `User`, `Database`). Display each one's class name using `get_class($object)` to verify they are loaded with the correct fully qualified name.

---

## 9. Solutions

**Solution for Exercise 1:**

Create folder `src/Helpers/`, then create `src/Helpers/TextHelper.php`:

```php
<?php

namespace App\Helpers;

class TextHelper
{
    public static function excerpt(string $text, int $length = 100): string
    {
        if (mb_strlen($text) <= $length) {
            return $text;
        }
        return mb_substr($text, 0, $length) . '...';
    }
}
```

`public static function excerpt()` uses the `static` modifier, meaning it can be called directly on the class without creating an object: `TextHelper::excerpt(...)`. The `::` operator is used for static method calls. `mb_strlen()` counts characters for multi-byte strings, and `mb_substr()` extracts the truncated portion without splitting a multi-byte character in half.

Save the file. Run `composer dump-autoload`. Test in `public/index.php`:

```php
use App\Helpers\TextHelper;

$long = 'This is a very long text that should be truncated by the TextHelper class.';
echo '<p>' . TextHelper::excerpt($long, 30) . '</p>';
```

`TextHelper::excerpt($long, 30)` calls the static method with a 30-character limit. Static methods belong to the class itself rather than to any instance, which is why no `new` keyword is needed before calling it.

Run at: `http://localhost:8080`

**Solution for Exercise 2:**

- `App\Controllers\EntryController` maps to `src/Controllers/EntryController.php`
- `App\Repositories\EntryRepository` maps to `src/Repositories/EntryRepository.php`
- `App\Models\Category` maps to `src/Models/Category.php`

**Solution for Exercise 3:**

Create `public/test-autoload.php`:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Models\Entry;
use App\Models\User;
use App\Database;

$entry = new Entry(1, 'Test', 'Content', 1, '2026-01-01');
$user  = new User(1, 'Budi', 'budi@example.com', 'pass', '2026-01-01');
$db    = new Database();

echo '<h2>Autoloading Verification</h2>';
echo '<p>Entry class: ' . get_class($entry) . '</p>';   // App\Models\Entry
echo '<p>User class: ' . get_class($user) . '</p>';     // App\Models\User
echo '<p>Database class: ' . get_class($db) . '</p>';   // App\Database
```

`get_class($object)` returns the fully qualified class name of an object as a string, including its namespace. The output confirms that PSR-4 autoloading resolved every class name to the correct file: `App\Models\Entry`, `App\Models\User`, and `App\Database`.

Save the file. Run at: `http://localhost:8080/test-autoload.php`

---

## 10. Conclusion

Namespaces prevent class name collisions. PSR-4 autoloading maps namespace prefixes to directories. The `use` statement imports classes by their fully qualified name. You only need one `require` statement in your entire project: the one that loads Composer's autoloader. This system is identical to what every modern PHP framework uses.

---

## Next Up - Lesson 6: Connecting to MySQL with PDO

In the next lesson you will:

1. Replace the `Database` placeholder with a real PDO connection to MySQL
2. Wrap all connection logic in a proper `Database` class
3. Query the database and map result rows to `Entry` objects