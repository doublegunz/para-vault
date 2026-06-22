## 1. Before You Begin

As your PHP projects grow, a problem emerges: the same code appears in multiple files. The navigation bar, the CSS styles, the database connection, the site footer — all of these appear on every page, but you have been copying them manually. When the design changes, you must update every single file. This is the classic maintenance nightmare, and PHP's include and require statements solve it cleanly.

### Introduction

Includes let you write a piece of code once in a separate file, then pull it into any page that needs it. This is the foundation of every organized PHP project. Before frameworks and templating engines, this simple file-splitting technique was (and still is) how PHP developers build maintainable multi-page sites. By the end of this lesson, any change to the shared header or footer will update every page automatically.

### What You'll Build

You will reorganize a multi-page project by extracting the shared HTML header, footer, and configuration into separate files, then including them from each page.

### What You'll Learn

- ✅ The difference between `include`, `require`, `include_once`, and `require_once`
- ✅ Creating shared layout files (header.php, footer.php)
- ✅ Separating configuration and functions from page logic
- ✅ Using `__DIR__` for reliable file paths regardless of where a file is called from

### What You'll Need

- Laragon running
- VS Code open in the `learn-php` folder
- Lessons 1 through 8 completed

---

## 2. Setup

Create `lesson-09` inside `learn-php`. Inside `lesson-09`, create two subfolders: `includes` and `pages`. The `includes` folder holds reusable files, and `pages` holds individual page files.

---

## 3. require vs include

All four statements (`include`, `require`, `include_once`, `require_once`) pull another PHP file into the current file as if you had typed its contents there. The difference is what happens when the file is missing.

### Step 1: Create the Included File

Inside the `includes` folder, create `greeting.php` and add:

```php
<?php
echo "<p>Hello from <strong>greeting.php</strong>! Loaded via require.</p>";
?>
```

Save the file.

### Step 2: Create the Demo File

In `lesson-09`, create `demo-require.php`.

```php
<?php
// require: loads the file. If the file is NOT found, PHP throws a FATAL error
// and stops completely. Use for files that are critical to the page.
require __DIR__ . '/includes/greeting.php';

echo "<p>This line runs after the require.</p>";

// include: loads the file. If the file is NOT found, PHP only shows a WARNING
// and continues running. Use for optional content (like ad widgets).
include __DIR__ . '/includes/does-not-exist.php';
echo "<p>This line STILL runs after the failed include.</p>";

// require_once and include_once: same as above, but guarantee the file
// is loaded only ONE time even if the statement appears multiple times.
// This prevents "Cannot redeclare function" errors when files define functions.
?>
```

Save the file.

### Step 3: Run in the Browser

```
http://localhost/learn-php/lesson-09/demo-require.php
```

You will see the greeting from `greeting.php`, then a warning about the missing file, and then the last line still executes. The `__DIR__` constant is the full path to the directory containing the current file. Using it as a prefix guarantees that PHP finds the correct file regardless of which directory the web server considers "current." Always use `__DIR__` for includes rather than relative paths like `'includes/greeting.php'`, which can break in unexpected ways when files call other files.

---

## 4. Create Shared Layout Files

### Step 1: Create header.php

In the `includes` folder, create `header.php` and add:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?= $page_title ?? 'Catatku' ?></title>
    <style>
        body  { font-family: Arial, sans-serif; max-width: 700px; margin: 0 auto; padding: 20px; }
        nav   { background: #f0f0f0; padding: 10px 15px; margin-bottom: 20px; border-radius: 4px; }
        nav a { margin-right: 15px; text-decoration: none; color: #0077cc; }
        footer{ margin-top: 30px; padding-top: 15px; border-top: 1px solid #ddd; color: #999; font-size: 0.85em; }
    </style>
</head>
<body>
    <nav>
        <a href="/learn-php/lesson-09/index.php">Home</a>
        <a href="/learn-php/lesson-09/pages/about.php">About</a>
        <a href="/learn-php/lesson-09/pages/contact.php">Contact</a>
    </nav>
```

Save the file. Notice this file does not close the `<body>` tag — the footer file will do that.

### Step 2: Create footer.php

In the `includes` folder, create `footer.php` and add:

```php
    <footer>
        <p>Catatku &copy; <?= date('Y') ?> — Built with PHP</p>
    </footer>
</body>
</html>
```

Save the file.

### Step 3: Create the Home Page

In the `lesson-09` folder, create `index.php` and add:

```php
<?php
// Set the page title BEFORE requiring the header
// The header uses $page_title, so it must exist before header.php loads
$page_title = "Home — Catatku";
require_once __DIR__ . '/includes/header.php';
?>

    <h1>Welcome to Catatku</h1>
    <p>The header and footer are loaded from separate files.</p>
    <p>Today is <?= date("l, F j, Y") ?></p>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
```

Save the file and visit `http://localhost/learn-php/lesson-09/index.php`. You should see a complete page with navigation and footer coming from the include files.

The `$page_title` variable must be set before the `require_once` for the header because included files share the same variable scope as the file that includes them. When `header.php` is loaded, it can access `$page_title` as if it were defined right in that file. The `??` operator provides a fallback if a page forgets to set the title.

---

## 5. Create More Pages

In `pages/about.php`, create:

```php
<?php
$page_title = "About — Catatku";
require_once __DIR__ . '/../includes/header.php';
?>
    <h1>About Catatku</h1>
    <p>A simple journal built with PHP.</p>
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
```

The `/../` in the path means "go up one directory level." Since `about.php` lives inside `pages/`, it needs to go up to `lesson-09/` before going down into `includes/`. Save it and visit via the navigation link on the home page. All pages share the same header and footer — change `header.php` once and every page updates.

Now create `pages/contact.php` so the Contact link in the shared navigation also points to a real page:

```php
<?php
$page_title = "Contact - Catatku";
require_once __DIR__ . '/../includes/header.php';
?>
    <h1>Contact</h1>
    <p>You can reach the Catatku team at hello@example.com.</p>
<?php require_once __DIR__ . '/../includes/footer.php'; ?>
```

Save the file and visit `http://localhost/learn-php/lesson-09/pages/contact.php`. You should see the same shared navigation and footer around the contact page content. This confirms that every link in the navigation now points to a page that exists.

---

## 6. Separating Configuration

Create `includes/config.php` and add:

```php
<?php
$app_name    = "Catatku";
$app_version = "1.0";

// Helper functions available to every page that includes this config
function formatDate($date_string) {
    return date("F j, Y", strtotime($date_string));
}
?>
```

Save the file. Now update `index.php` to use it:

```php
<?php
require_once __DIR__ . '/includes/config.php';
$page_title = "Home — $app_name";
require_once __DIR__ . '/includes/header.php';
?>
    <h1>Welcome to <?= htmlspecialchars($app_name) ?></h1>
    <p>Version: <?= htmlspecialchars($app_version) ?></p>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
```

The config pattern keeps all application-wide settings in one place. In Lesson 10, the database connection will live in this same file, making it available to every page with a single `require_once`.

---

## 7. Fix the Errors in Your Code

Three common mistakes with includes: using `include` instead of `require` for a critical database connection file (if it fails, the page silently breaks rather than stopping), using relative paths like `require 'includes/header.php'` without `__DIR__` (works until another file calls the file from a different directory), and using `require` instead of `require_once` for a file that defines functions (the second load throws "Cannot redeclare function"). The fixes respectively: use `require` for critical files, prefix all paths with `__DIR__ . '/'`, and use `require_once` for any file that defines classes or functions.

---

## 8. Exercises

**Exercise 1:** Create `exercise-1.php`. Build `includes/sidebar.php` with a list of links. Include it between the header and page content. **Exercise 2:** Create `includes/functions.php` with two helper functions: `greet($name)` returning "Hello, [name]!" and `formatPrice($number)` returning "Rp" + formatted number. Require it in `exercise-2.php` and call both functions. **Exercise 3:** Create `pages/dashboard.php` using the shared header/footer and config. Display the app name, current date using `formatDate('now')`, and a small table of three sample entry titles.

---

## 9. Solutions

**Solution for Exercise 2:**

Create `includes/functions.php`:
```php
<?php
function greet($name) { return "Hello, " . htmlspecialchars($name) . "!"; }
function formatPrice($number) { return "Rp" . number_format($number, 0, ",", "."); }
?>
```

Create `exercise-2.php`:
```php
<?php
require_once __DIR__ . '/includes/functions.php';
echo greet("Budi") . "<br>";
echo "Laptop: " . formatPrice(8500000) . "<br>";
?>
```

---

## 10. Understanding Includes

Includes implement the **single source of truth** principle: each piece of information or behavior exists in exactly one place. When you need the same functionality in multiple places, you include the single file that defines it rather than copying code. This is one of the most broadly applicable principles in software engineering, and PHP's include system is the simplest possible implementation of it.

The distinction between `include` and `require` maps to a practical judgment: how catastrophic is it if this file is missing? For a database connection, the answer is "completely catastrophic" — no page can work without it, so `require` is correct. For an optional ad widget in the sidebar, the answer is "the page still works" — so `include` is appropriate. The `_once` variants (both `include_once` and `require_once`) add the additional guarantee of loading each file only once per request, which is essential for files that define functions or classes.

---

## 11. Conclusion

Includes extract repeated code into one place, making sites maintainable at scale. `require_once` is the standard choice for critical files that define functions or configurations. Always use `__DIR__ . '/'` for reliable paths. Set variables before including files that depend on them. This pattern is the predecessor to the template and component systems in every PHP framework.

**In Lesson 10**, you will connect PHP to MySQL using PDO and start building the database backend for Catatku.
