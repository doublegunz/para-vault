## 1. Before You Begin

### Introduction

Unlike the PHP Fundamental course where you created separate folders for each lesson, this course builds a single project from start to finish. Every lesson adds to the same codebase. This lesson sets up that project with a professional folder structure, Composer for dependency management, and PSR-4 autoloading.

By setting up the project yourself, you will understand what frameworks generate for you and why each piece exists.

### What You'll Build

You will create a PHP project called Catatku with a clean folder structure, Composer autoloading, and PHP's built-in development server. By the end, you will have a "Hello, Catatku!" page running in the browser.

### What You'll Learn

- ✅ How to initialize a project with `composer init` and configure PSR-4 autoloading
- ✅ How to organize a PHP project with `public/`, `src/`, `templates/`, and `config/` directories
- ✅ Why the `public/` directory is the only folder exposed to the web
- ✅ How to use PHP's built-in development server
- ✅ How Composer autoloading eliminates manual `require` statements

### What You'll Need

- Laragon installed and running
- PHP 8.3 available (check with `php -v` in terminal)
- Composer installed (check with `composer --version`)
- VS Code installed

---

## 2. Setup: Create the Project

In this section you will create the project folder, initialize Composer, and build the directory structure. These three steps are done once at the start of every new PHP project. Follow each step in order because each one depends on the previous.

### Step 1: Create the Project Folder

Open the Laragon terminal (click **Terminal** in Laragon) and run:

```bash
mkdir C:\laragon\www\catatku
cd C:\laragon\www\catatku
```

`mkdir` (make directory) creates a new folder named `catatku` inside the Laragon web directory. `cd` (change directory) then moves into that folder. After this, every command you run in the terminal is executed from inside the `catatku` folder.

### Step 2: Initialize Composer

Run the following command:

```bash
composer init
```

`composer init` launches an interactive wizard that asks a few questions (project name, description, license, etc.) to create the `composer.json` file. For most questions you can press Enter to accept the default value.

When prompted, you can accept defaults for most fields. After `composer init` finishes, open the file `composer.json` in VS Code.

Open `composer.json` and replace its content with:

```json
{
    "name": "catatku/app",
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    }
}
```

- **`name`** is the package identity in `vendor/package` format. The value `catatku/app` means a project named `app` owned by `catatku`.
- **`autoload.psr-4`** configures PSR-4 autoloading. The entry `"App\\": "src/"` tells Composer that every class with a namespace starting with `App\` can be found in the `src/` folder. For example, the class `App\Models\Entry` will be resolved automatically to `src/Models/Entry.php`.

Save the file (**Ctrl+S**).

Then run in the terminal:

```bash
composer dump-autoload
```

`composer dump-autoload` regenerates the autoloader file in the `vendor/` folder. Run this command every time you modify `composer.json` manually. After this, Composer applies the updated rule: every class in the `App\` namespace lives in the `src/` folder. For example, `App\Models\Entry` will be loaded from `src/Models/Entry.php`.

### Step 3: Create the Directory Structure

Run these commands in the terminal:

```bash
mkdir config public src templates
```

A single `mkdir` command can create multiple folders at once by separating the names with spaces. These four folders form the base structure of the Catatku application and will be used throughout the entire course.

Your project now looks like this:

```
catatku/
├── config/              ← Configuration files (database credentials, etc.)
├── public/              ← Web root (only folder accessible from browser)
├── src/                 ← PHP classes (models, controllers, repositories)
├── templates/           ← HTML template files
├── composer.json
└── vendor/              ← Composer dependencies (auto-generated)
```

### Step 4: Open in VS Code

Open VS Code. Select **File** then **Open Folder**, navigate to `C:\laragon\www\catatku`, and click **Select Folder**.

---

## 3. Create the Entry Point

Every request to the application enters through a single file: `public/index.php`. This is called the **front controller** pattern, which we will build fully in Lesson 8. For now, this file only verifies that the project is running correctly.

### Step 1: Create the File

In the VS Code Explorer panel, right-click on the `public` folder, select **New File**, type `index.php`, and press Enter.

### Step 2: Write the Code

Open `public/index.php` and type the following code:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

echo '<h1>Hello, Catatku!</h1>';
echo '<p>Your PHP OOP project is ready.</p>';
echo '<p>Server time: ' . date('H:i:s') . '</p>';
```

`require_once __DIR__ . '/../vendor/autoload.php'` loads the Composer autoloader. This line must be at the very top of every entry point file so PHP can locate classes automatically without writing manual `require` statements. `__DIR__` holds the absolute path of the folder where this file lives (`public/`), so `/../vendor/autoload.php` always resolves to the correct location regardless of where the server is started.

The three `echo` lines display simple HTML to confirm the server is running. `date('H:i:s')` returns the current server time in hour:minute:second format. Refresh the browser and you will see the time update.

### Step 3: Save the File

Press **Ctrl+S**.

### Step 4: Run the Development Server

Open a terminal in VS Code (**Ctrl+`**) or use the Laragon terminal. Make sure you are in the `catatku` folder, then run:

```bash
php -S localhost:8080 -t public
```

`php -S localhost:8080` starts PHP's built-in web server, making it accessible at `http://localhost:8080`. The `-t public` flag (short for *target*) tells PHP to use the `public/` folder as the document root, so `public/index.php` is the file executed when a browser requests `/`. Without this flag, PHP uses the current working directory as the root, which could expose files outside of `public/`.

### Step 5: Open in the Browser

Open a browser and navigate to:

```
http://localhost:8080
```

You should see:

```
Hello, Catatku!
Your PHP OOP project is ready.
Server time: 14:30:05
```

> **Keep the terminal running.** The server stays active as long as the terminal is open. Open a new terminal tab for other commands. To stop the server, press **Ctrl+C** in the terminal.

---

## 4. Understanding the Folder Structure {#understanding-the-folder-structure}

Each directory has a clear purpose.

**`public/`** is the web root. Only `index.php` lives here. Every HTTP request enters through this single file. This is the "front controller" pattern that we will build in Lesson 8.

**`src/`** is where all PHP classes live. Controllers, models, repositories, and other application code go here, organized by namespace.

**`config/`** stores configuration files like database credentials. These are PHP files that return arrays, keeping sensitive data separate from application logic.

**`templates/`** holds HTML template files. Separating templates from PHP classes keeps presentation logic out of your business code.

**`vendor/`** is managed entirely by Composer. Never edit files in this directory.

This structure mirrors what every modern PHP framework uses. Laravel has `app/`, `public/`, `config/`, and `resources/views/`. Symfony has `src/`, `public/`, `config/`, and `templates/`. The names differ slightly, but the concept is identical.

**Security note:** Only the `public/` folder is accessible from the browser. All other directories (`src/`, `config/`, `templates/`) are above the web root and cannot be accessed directly. Database credentials in `config/` are safe.

---

## 5. How PSR-4 Autoloading Works {#how-psr-4-autoloading-works}

The `require_once __DIR__ . '/../vendor/autoload.php'` line in `index.php` loads Composer's autoloader. From that point, whenever you use a class like `App\Models\Entry`, PHP automatically finds and loads the file without you writing a `require` statement.

The mapping rule defined in `composer.json` is:

```
Namespace App\        →  Directory src/
App\Models\Entry      →  src/Models/Entry.php
App\Controllers\Home  →  src/Controllers/Home.php
App\Database          →  src/Database.php
```

The class name must match the file name exactly (case-sensitive). The namespace path must match the directory path. This is the PSR-4 autoloading standard used by every modern PHP project.

---

## 6. Fix the Errors in Your Code

Look at the following code and find the mistakes:

```php
<?php
// File: public/index.php

// Error 1: Wrong path to autoloader
require_once 'vendor/autoload.php';

// Error 2: Class file in wrong location
// File is saved at: src/entry.php
// Class declared as: namespace App\Models; class Entry { }

// Error 3: Using the class without the namespace
$entry = new Entry();
```

**Error 1 — Relative path to autoloader.** The path `'vendor/autoload.php'` is relative to the server's working directory, which may not be the project root. Always use `__DIR__ . '/../vendor/autoload.php'` from `public/index.php` for a reliable absolute path.

**Error 2 — File in wrong location.** If the class is `App\Models\Entry`, PSR-4 autoloading expects it at `src/Models/Entry.php` (not `src/entry.php`). The directory must match the namespace (`Models`), and the filename must match the class name exactly (`Entry.php`, not `entry.php`).

**Error 3 — Missing `use` statement.** After autoloading, you must either use the full qualified name `new \App\Models\Entry()` or add a `use` statement at the top: `use App\Models\Entry;` then `new Entry()`.

---

## 7. Exercises

**Exercise 1:** Create a file `public/info.php` that loads the Composer autoloader and displays the PHP version (`phpversion()`), the current date, and the project's document root (`$_SERVER['DOCUMENT_ROOT']`). Run it at `http://localhost:8080/info.php`.

**Exercise 2:** Without running the code, determine the correct file path for each of these classes based on the PSR-4 mapping `"App\\": "src/"`:
- `App\Controllers\EntryController`
- `App\Models\User`
- `App\Helpers\Formatter`

**Exercise 3:** Create a file `src/Greeting.php` with a class `App\Greeting` that has one public method `sayHello(string $name): string` which returns "Hello, [name]! Welcome to Catatku." Then update `public/index.php` to create a `Greeting` object and display the result. Run it at `http://localhost:8080`.

---

## 8. Solutions

**Solution for Exercise 1:**

Open the `public` folder and create `info.php`:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

echo '<h2>Server Information</h2>';
echo '<p>PHP Version: ' . phpversion() . '</p>';
echo '<p>Date: ' . date('l, F j, Y') . '</p>';
echo '<p>Document Root: ' . htmlspecialchars($_SERVER['DOCUMENT_ROOT']) . '</p>';
```

`phpversion()` returns a string with the currently running PHP version, for example `8.3.0`. `date('l, F j, Y')` formats the current date: `l` outputs the full day name, `F` the full month name, `j` the day without a leading zero, and `Y` the four-digit year, producing output like `Friday, April 18, 2025`. `$_SERVER['DOCUMENT_ROOT']` is a PHP superglobal holding the absolute path to the `public/` folder on the server.

Save the file. Run at: `http://localhost:8080/info.php`

**Solution for Exercise 2:**

- `App\Controllers\EntryController` maps to `src/Controllers/EntryController.php`
- `App\Models\User` maps to `src/Models/User.php`
- `App\Helpers\Formatter` maps to `src/Helpers/Formatter.php`

**Solution for Exercise 3:**

Create `src/Greeting.php`:

```php
<?php

namespace App;

class Greeting
{
    public function sayHello(string $name): string
    {
        return "Hello, " . htmlspecialchars($name) . "! Welcome to Catatku.";
    }
}
```

`namespace App` declares that this class belongs to the `App` namespace, so the autoloader can locate it at `src/Greeting.php`. `class Greeting` defines a new class, a concept covered in depth in Lesson 3. `public function sayHello(string $name): string` is a public method that accepts a `string` parameter and returns a `string`. `htmlspecialchars()` converts characters like `<` and `>` into safe HTML equivalents, preventing potential XSS attacks.

Save the file.

Update `public/index.php`:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Greeting;

$greeting = new Greeting();
echo '<h1>' . $greeting->sayHello('Budi') . '</h1>';
echo '<p>' . $greeting->sayHello('Citra') . '</p>';
```

`use App\Greeting` tells PHP which class to use. Without it, you would have to write `new App\Greeting()` every time. `new Greeting()` creates one *object* (instance) of the `Greeting` class and stores it in `$greeting`. Notice that `sayHello()` is called twice with different arguments. This demonstrates a core OOP idea: one class can produce many objects and be called repeatedly with different data.

Save the file. Run at: `http://localhost:8080`

---

## 9. Conclusion

You now have a properly structured PHP project with Composer autoloading. The key points: Composer's PSR-4 autoloading maps namespaces to directories (`App\` maps to `src/`), so you never need to write `require` statements for your classes. The `public/` directory is the only folder exposed to the browser, everything else is protected. And `php -S localhost:8080 -t public` starts the development server.

This folder structure and autoloading setup is identical to what every modern PHP framework uses.

---

## Next Up — Lesson 3: Classes and Objects

In the next lesson you will:

1. Create your first PHP class
2. Understand the difference between a **class** (the blueprint) and an **object** (an instance)
3. Model a journal entry using OOP

The project you set up in this lesson will be used right away. Your first class will be saved in the `src/` folder and loaded automatically by the autoloader.