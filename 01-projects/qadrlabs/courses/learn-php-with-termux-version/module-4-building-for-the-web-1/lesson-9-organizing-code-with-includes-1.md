## 1. Before You Begin

As your PHP projects grow, you will notice the same code appearing in multiple files: the database connection, the HTML header, the navigation bar, the footer. Copying and pasting this code everywhere creates a maintenance problem. If you change the navigation, you have to update every single file manually and you will inevitably miss one.

PHP solves this with **include** and **require** statements. They let you write a piece of code once in a separate file, then pull it into any other file that needs it. This is the foundation of every organized PHP project and every PHP framework.

### What You'll Build

You will reorganize a multi-page project by extracting shared parts (header, footer, and configuration) into separate files and including them wherever needed. The result is a small site where changing a navigation link in one place updates every page automatically.

### What You'll Learn

- ✅ The difference between `include`, `require`, `include_once`, and `require_once`
- ✅ How to create shared layout files (header, footer)
- ✅ How to separate configuration from logic
- ✅ How to organize a project folder structure
- ✅ How to use `__DIR__` for reliable file paths

### What You'll Need

- Termux open with Apache running (`apachectl`)
- Lessons 1 through 8 completed

---

## 2. Setup

Before writing any code, create the lesson folder and two subfolders to organize files by role. This structure reflects how real PHP projects separate shared code from page-specific code.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-09
cd lesson-09
```

Now create the two subfolders for this lesson:

```bash
mkdir includes pages
```

After running these commands, the folder structure looks like this:

```
learn-php/
└── lesson-09/
    ├── includes/     ← shared PHP files (header, footer, config)
    ├── pages/        ← individual page files
    └── (main files such as index.php)
```

The `includes` folder holds files that are not pages themselves, only pieces that other pages pull in. The `pages` folder holds secondary pages like About and Contact. Root-level files like `index.php` are entry points that the browser accesses directly.

---

## 3. require vs include

The four include-related statements all load an external PHP file into the current file, but they differ in what happens when the file is missing and whether they prevent duplicate loading. Understanding the difference is important because choosing the wrong one can hide critical errors.

### Step 1: Create the Demo File

Make sure you are in the `lesson-09` folder, then open a new file:

```bash
micro demo-require.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "<h2>require vs include Demo</h2>";

// require: stops the entire script with a fatal error if the file is not found
require __DIR__ . '/includes/greeting.php';

echo "<p>This line runs after the require.</p>";

// include: shows a warning but continues running if the file is not found
include __DIR__ . '/includes/does-not-exist.php';
echo "<p>This line STILL runs after the failed include.</p>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: Create the Included File

Navigate into the `includes` folder and create the greeting file:

```bash
micro includes/greeting.php
```

Type the following code:

```php
<?php
echo "<p>Hello from <strong>greeting.php</strong>! I was loaded via require.</p>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 4: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-09/demo-require.php
```

You will see the greeting from `greeting.php`, then a PHP warning about the non-existent file, and then the last `echo` still executes because `include` was used instead of `require`.

`require` and `include` both insert the contents of another PHP file into the current one at the exact point where the statement appears. The difference is in the error behavior: `require` triggers a fatal error and halts the script if the file is not found, while `include` only triggers a warning and lets the script continue. `require_once` and `include_once` work identically to their counterparts but keep an internal record of which files have been loaded and skip any file that has already been included. Use `require_once` for files that define functions or classes, because loading those files twice would cause a "Cannot redeclare" fatal error. `__DIR__` is a PHP magic constant that expands to the absolute path of the directory containing the current file. Using it makes paths reliable regardless of which directory PHP's working directory happens to be when the script runs.

In practice, the recommendation is straightforward: use `require_once` for any file that is critical to the page (configuration, database connections, function libraries), and use `include` only for purely optional content like sidebar widgets that the page can survive without.

---

## 4. Create Shared Layout Files

The most common use of includes in PHP is extracting the HTML header and footer into their own files. Every page on a site starts with the same `<!DOCTYPE html>`, `<head>`, and opening `<nav>`, and ends with the same closing `</body>` and `</html>`. Putting these in shared files means the entire site's layout is controlled from two places.

### Step 1: Create the Header File

Navigate into the `includes` folder and create the header file:

```bash
micro includes/header.php
```

Type the following code into the editor:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?= $page_title ?? 'Catatku' ?></title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 700px; margin: 0 auto; padding: 20px; }
        nav { background: #f0f0f0; padding: 10px 15px; margin-bottom: 20px; border-radius: 4px; }
        nav a { margin-right: 15px; text-decoration: none; color: #0077cc; }
        nav a:hover { text-decoration: underline; }
        footer { margin-top: 30px; padding-top: 15px; border-top: 1px solid #ddd; color: #999; font-size: 0.85em; }
    </style>
</head>
<body>
    <nav>
        <a href="index.php">Home</a>
        <a href="pages/about.php">About</a>
        <a href="pages/contact.php">Contact</a>
    </nav>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit. Notice that this file does not close `<body>` or `<html>` - those tags live in the footer file.

### Step 2: Create the Footer File

In the `includes` folder, create the footer file:

```bash
micro includes/footer.php
```

Type the following code:

```php
    <footer>
        <p>Catatku &copy; <?= date('Y') ?>. Built with PHP.</p>
    </footer>
</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit. This file contains only the closing tags that `header.php` left open, forming the second half of the HTML document.

### Step 3: Create the Home Page

Make sure you are in the `lesson-09` folder, then create `index.php`:

```bash
micro index.php
```

Type the following code:

```php
<?php
$page_title = "Home - Catatku";
require_once __DIR__ . '/includes/header.php';
?>

    <h1>Welcome to Catatku</h1>
    <p>This is the home page. The header and footer are loaded from separate files.</p>
    <p>Today is <?= date("l, F j, Y") ?></p>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 4: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-09/index.php
```

You will see a complete page with a navigation bar, content area, and footer, yet `index.php` itself contains almost no HTML. All the structure comes from the two included files.

`$page_title` is set before the `require_once` for the header. This is intentional: included files share the same variable scope as the file that includes them. When PHP loads `header.php`, it can read `$page_title` because both files are part of the same running script. The `$page_title ?? 'Catatku'` in the header uses the null-coalescing operator to fall back to a default title if the page did not define one. This makes the header file safe to include even in pages that forget to set `$page_title`.

---

## 5. Create More Pages

With the shared layout files in place, creating a new page requires only a few lines. You set the title, include the header, write the page content, and include the footer. All the navigation and styling come along automatically.

### Step 1: Create the About Page

Navigate into the `pages` folder and create the about file:

```bash
micro pages/about.php
```

Type the following code:

```php
<?php
$page_title = "About - Catatku";
require_once __DIR__ . '/../includes/header.php';
?>

    <h1>About Catatku</h1>
    <p>Catatku is a simple journal application built with PHP.</p>
    <p>This page demonstrates how includes work across different folders.</p>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 2: Create the Contact Page

In the `pages` folder, create the contact file:

```bash
micro pages/contact.php
```

Type the following code:

```php
<?php
$page_title = "Contact - Catatku";
require_once __DIR__ . '/../includes/header.php';
?>

    <h1>Contact Us</h1>
    <p>Email: hello@catatku.example.com</p>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the home page and use the navigation links to visit each page:

```
http://localhost:8080/learn-php/lesson-09/index.php
```

Every page shares the same header and footer, but each has its own title and content. If you need to add a new navigation link, you change `includes/header.php` once and all three pages reflect the update immediately.

The path `__DIR__ . '/../includes/header.php'` requires attention. `__DIR__` inside `pages/about.php` resolves to the absolute path of the `pages` folder. The `..` segment means "go up one level," which moves from `pages/` to `lesson-09/`. From there, `/includes/header.php` descends into the shared files folder. This navigation up-then-down is the standard pattern for any file that needs to reach a sibling directory.

---

## 6. Separating Configuration

In any real application, settings like the application name, database credentials, and utility functions appear in many places. Defining them in one configuration file and requiring that file wherever they are needed means you only have one place to update when something changes.

### Step 1: Create the Config File

In the `includes` folder, create the configuration file:

```bash
micro includes/config.php
```

Type the following code into the editor:

```php
<?php
// Application configuration
$app_name    = "Catatku";
$app_version = "1.0";

// In a real project, database credentials would go here:
// $db_host = "127.0.0.1";
// $db_name = "db_catatku";
// $db_user = "root";
// $db_pass = "";

// Helper function available to all pages that include this file
function formatDate($date_string) {
    return date("F j, Y", strtotime($date_string));
}
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 2: Update the Home Page to Use Config

Open `index.php` in the editor:

```bash
micro index.php
```

Replace its contents with the following:

```php
<?php
require_once __DIR__ . '/includes/config.php';
$page_title = "Home - " . $app_name;
require_once __DIR__ . '/includes/header.php';
?>

    <h1>Welcome to <?= htmlspecialchars($app_name) ?></h1>
    <p>Version: <?= htmlspecialchars($app_version) ?></p>
    <p>Today is <?= formatDate('now') ?></p>
    <p>The header, footer, and config are all separate files.</p>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-09/index.php
```

The page now reads its title and version from `config.php`, and the date is formatted by the `formatDate` function also defined there. Because `config.php` is loaded with `require_once`, the function is defined exactly once no matter how many pages include the file. Functions defined in an included file become available in the including file just as if they had been defined there directly.

---

## 7. Fix the Errors in Your Code

This section covers three mistakes that are common when developers first start using includes. Each one either hides a critical failure, produces an unreliable path, or causes a fatal "cannot redeclare" error.

**Error 1: Using `include` for a file that the rest of the script depends on.**

If a database connection file is missing and you use `include` to load it, PHP only shows a warning and continues. The very next line tries to use the database connection object, which was never created, and fails with a confusing error message that points at the query line, not at the missing file.

```php
// Wrong
include 'database.php';
$pdo->query("SELECT * FROM users");

// Correct
require 'database.php';
$pdo->query("SELECT * FROM users");
```

`require` halts the script immediately with a clear "Failed to open stream" fatal error if the file is not found. This is precisely what you want: a missing database file should stop the script loudly, not silently continue into a broken state.

---

**Error 2: Using a relative path without `__DIR__`.**

A relative path like `'includes/header.php'` is resolved from PHP's current working directory, which is determined by how Apache runs the script and can change depending on whether the script is called directly or included from another file. This means the same path works from one location but silently breaks from another.

```php
// Wrong
require 'includes/header.php';

// Correct
require __DIR__ . '/includes/header.php';
```

`__DIR__` always expands to the absolute path of the directory that contains the current file, regardless of where PHP's working directory happens to be. Using it makes every file path predictable and portable across different server environments.

---

**Error 3: Loading a file that defines functions more than once.**

If a file defines a function and you load it twice using plain `require`, PHP throws a fatal "Cannot redeclare function" error on the second load.

```php
// Wrong
require 'config.php';
require 'config.php';

// Correct
require_once 'config.php';
require_once 'config.php'; // second call is silently skipped
```

`require_once` keeps track of every file it has already loaded. If the same path is passed again, it skips the load entirely rather than re-executing the file. This is the safe default for any file that defines functions, classes, or constants.

---

## 8. Exercises

Complete the following exercises in the `lesson-09` folder. Remember that navigation paths may need the `../` prefix depending on whether the file is in the root of `lesson-09` or inside a subfolder.

**Exercise 1:** Create a file called `includes/sidebar.php` that displays a list of three links inside a styled `<div>`. Then create `exercise-1.php` in the root of `lesson-09` that includes the header, includes the sidebar, adds a heading and a short paragraph, and then includes the footer.

**Exercise 2:** Create `includes/functions.php` containing two functions: `greet($name)` that returns the string `"Hello, [name]!"` and `formatPrice($number)` that returns `"Rp"` followed by the number formatted with thousands separators. Then create `exercise-2.php` that loads the functions file with `require_once` and displays results from calling both functions with different arguments.

**Exercise 3:** Create `pages/dashboard.php` that uses the shared header and footer, loads `config.php`, displays the app name and version, shows the current date using `formatDate()`, and includes an HTML table with three sample journal entry titles and their dates.

---

## 9. Solutions

**Solution for Exercise 1:**

First, create `includes/sidebar.php`:

```php
<div style="background: #f9f9f9; padding: 10px 15px; border-radius: 4px; margin-bottom: 15px;">
    <strong>Quick Links</strong>
    <ul>
        <li><a href="index.php">Home</a></li>
        <li><a href="pages/about.php">About</a></li>
        <li><a href="pages/contact.php">Contact</a></li>
    </ul>
</div>
```

Then create `exercise-1.php`:

```php
<?php
$page_title = "Exercise 1";
require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
?>

    <h1>Page with Sidebar</h1>
    <p>The sidebar above is loaded from a separate file.</p>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
```

Open `http://localhost:8080/learn-php/lesson-09/exercise-1.php` in the browser. The page renders with the standard navigation from `header.php`, then the sidebar from `sidebar.php`, and then the page content. Notice that `sidebar.php` contains only HTML, not a full PHP file structure. Included files can contain any mix of PHP and HTML - they do not need to be complete standalone documents.

---

**Solution for Exercise 2:**

First, create `includes/functions.php`:

```php
<?php
function greet($name) {
    return "Hello, " . htmlspecialchars($name) . "!";
}

function formatPrice($number) {
    return "Rp" . number_format($number, 0, ",", ".");
}
?>
```

Then create `exercise-2.php`:

```php
<?php
require_once __DIR__ . '/includes/functions.php';

echo greet("Budi") . "<br>";
echo greet("Citra") . "<br>";
echo "Laptop: " . formatPrice(8500000) . "<br>";
echo "Mouse: " . formatPrice(150000) . "<br>";
?>
```

Open `http://localhost:8080/learn-php/lesson-09/exercise-2.php`. After `require_once` loads the functions file, both `greet()` and `formatPrice()` are available as if they were defined directly in `exercise-2.php`. If you call `require_once` a second time with the same path in the same request, PHP recognizes it has already been loaded and skips the file, preventing "Cannot redeclare function" errors when the functions file is included from multiple pages.

---

**Solution for Exercise 3:**

Create `pages/dashboard.php`:

```php
<?php
require_once __DIR__ . '/../includes/config.php';
$page_title = "Dashboard - " . $app_name;
require_once __DIR__ . '/../includes/header.php';
?>

    <h1>Dashboard</h1>
    <p>Welcome to <?= htmlspecialchars($app_name) ?> v<?= htmlspecialchars($app_version) ?></p>
    <p>Today: <?= formatDate('now') ?></p>

    <h3>Recent Entries</h3>
    <table border="1" cellpadding="8" cellspacing="0">
        <tr><th>No</th><th>Title</th><th>Date</th></tr>
        <tr><td>1</td><td>My first journal entry</td><td><?= formatDate('2025-01-10') ?></td></tr>
        <tr><td>2</td><td>Learning PHP includes</td><td><?= formatDate('2025-01-15') ?></td></tr>
        <tr><td>3</td><td>Weekend plans</td><td><?= formatDate('2025-01-20') ?></td></tr>
    </table>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
```

Open `http://localhost:8080/learn-php/lesson-09/pages/dashboard.php`. The `__DIR__` inside `pages/dashboard.php` resolves to the `pages` folder. The `/../` prefix navigates up one level to `lesson-09`, from which `/includes/config.php` is reachable. Because `config.php` is loaded first, both `$app_name` and `formatDate()` are available when `header.php` and the page content are processed. The date strings passed to `formatDate()` go through `strtotime()`, which converts them into Unix timestamps that `date()` then formats as "Month day, Year".

---

## Next Up - Lesson 10

Organizing code with includes is a simple technique with a large impact on maintainability. Write shared pieces once in separate files, pull them in with `require_once`, and change them in one place to update every page at once. Use `require_once` for anything critical or that defines functions. Use `__DIR__` for all file paths. Remember that included files share the same variable scope as the file that includes them, so variables set before an include are readable inside the included file.

In Lesson 10, you will enter the world of databases. You will connect PHP to MySQL using PDO, create a table for journal entries, and run your first SQL queries. This is where your application begins storing data that persists across page visits.