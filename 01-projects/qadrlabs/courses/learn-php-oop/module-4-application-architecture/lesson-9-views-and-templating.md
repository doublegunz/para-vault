## 1. Before You Begin

### Introduction

Every page in our application currently duplicates the full HTML structure: doctype, head, navigation, and body. When we add more pages, changing the navigation means editing every single template. This lesson builds a simple **template system** with a shared layout that solves this.

### What You'll Build

You will create a `View` class that renders templates with a shared layout, flash messages, and data passing. This is the same concept behind Blade (Laravel), Twig (Symfony), and CodeIgniter's view system.

### What You'll Learn

- ✅ How to build a template rendering class with PHP's output buffering
- ✅ How to implement a shared layout that wraps all page content
- ✅ How to pass data from controllers to templates safely
- ✅ How to implement flash messages using sessions
- ✅ How `extract()` and `ob_start()`/`ob_get_clean()` work

### What You'll Need

- The Router and controllers from Lesson 8
- The development server running

---

## 2. Create the View Class

In this section you will build a custom template engine. It will isolate the messy `require` logic, manage variables, and handle session-based flash messages for user feedback.

### Step 1: Create the File

Right-click on the `src` folder, select **New File**, type `View.php`, and press Enter.

### Step 2: Write the Code

Open `src/View.php` and type the following code:

```php
<?php

namespace App;

class View
{
    public static function render(string $template, array $data = [], ?string $layout = 'layouts/main'): void
    {
        extract($data);

        ob_start();
        require __DIR__ . '/../templates/' . $template . '.php';
        $content = ob_get_clean();

        if ($layout) {
            require __DIR__ . '/../templates/' . $layout . '.php';
        } else {
            echo $content;
        }
    }

    public static function setFlash(string $key, string $message): void
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        $_SESSION['flash'][$key] = $message;
    }

    public static function getFlash(string $key): ?string
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        $message = $_SESSION['flash'][$key] ?? null;
        unset($_SESSION['flash'][$key]);
        return $message;
    }
}
```

`ob_start()` begins output buffering. Everything echoed between `ob_start()` and `ob_get_clean()` is captured into a string (`$content`) instead of being sent to the browser. The layout template decides where to place that content.

`extract($data)` converts an associative array into variables. If `$data` is `['entries' => [...]]`, it creates an `$entries` variable in the template scope.

Flash messages are stored in the session and cleared after being read once, exactly like `session('success')` in Laravel or `addFlash()` in Symfony.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 3. Create the Layout

This section creates the master layout file that provides the `<html>`, `<head>`, `<style>`, and navigation for every page.

### Step 1: Create the Folder

In `templates/`, create a subfolder called `layouts`.

### Step 2: Create the File

Right-click on `templates/layouts`, select **New File**, type `main.php`.

### Step 3: Write the Code

Open `templates/layouts/main.php` and type the following code:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?= $title ?? 'Catatku' ?></title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 700px; margin: 0 auto; padding: 20px; background: #fafafa; }
        nav { background: #fff; border: 1px solid #ddd; padding: 10px 15px; margin-bottom: 20px; border-radius: 6px; display: flex; justify-content: space-between; align-items: center; }
        nav a { text-decoration: none; color: #0077cc; margin-right: 12px; }
        nav .brand { font-weight: bold; font-size: 1.1em; color: #333; }
        .flash-success { background: #d1e7dd; border: 1px solid #a3cfbb; color: #0f5132; padding: 10px 15px; border-radius: 6px; margin-bottom: 15px; }
        .flash-error { background: #f8d7da; border: 1px solid #f5c2c7; color: #842029; padding: 10px 15px; border-radius: 6px; margin-bottom: 15px; }
        .btn { display: inline-block; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; text-decoration: none; font-size: 0.9em; }
        .btn-primary { background: #0077cc; color: #fff; }
        .btn-danger { background: #dc3545; color: #fff; }
        .btn-sm { padding: 4px 10px; font-size: 0.8em; }
    </style>
</head>
<body>

    <nav>
        <div>
            <a href="/entries" class="brand">Catatku</a>
            <a href="/entries">Entries</a>
        </div>
        <div>
            <?php if (isset($_SESSION['user_id'])): ?>
                <span style="color:#666;font-size:0.85em;"><?= htmlspecialchars($_SESSION['user_name'] ?? '') ?></span>
                <a href="/logout" style="margin-left:10px;">Logout</a>
            <?php else: ?>
                <a href="/login">Log In</a>
                <a href="/register">Register</a>
            <?php endif; ?>
        </div>
    </nav>

    <?php $success = \App\View::getFlash('success'); ?>
    <?php if ($success): ?>
        <div class="flash-success"><?= htmlspecialchars($success) ?></div>
    <?php endif; ?>

    <?php $error = \App\View::getFlash('error'); ?>
    <?php if ($error): ?>
        <div class="flash-error"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <?= $content ?>

</body>
</html>
```

`<?= $content ?>` is where the child template's output gets inserted. This is equivalent to `{{ $slot }}` in Blade, `{% block body %}` in Twig, or `renderSection('content')` in CodeIgniter. Note that the layout also checks for flash messages and renders them automatically for any page using the layout.

### Step 4: Save the File

Press **Ctrl+S**.

---

## 4. Update the Templates

Now each template only contains its unique content. The layout wraps it automatically.

### Step 1: Reorganize Template Folders

Rename `templates/entries/` to `templates/entry/` (singular, matching the entity name). Create the folder if needed.

### Step 2: Update entries/index.php

Open `templates/entry/index.php` and replace the entire content with:

```php
<?php $title = 'My Entries - Catatku'; ?>

<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px;">
    <h2>My Entries</h2>
    <a href="/entries/create" class="btn btn-primary">+ Write New Entry</a>
</div>

<?php if (empty($entries)): ?>
    <p style="color:#999; text-align:center; padding:30px;">No entries yet. Start writing your first entry!</p>
<?php else: ?>
    <?php foreach ($entries as $entry): ?>
        <div style="background:#fff; border:1px solid #ddd; padding:15px; margin-bottom:10px; border-radius:6px;">
            <h3 style="margin:0 0 5px;">
                <a href="/entries/<?= $entry->getId() ?>" style="text-decoration:none;color:#333;"><?= htmlspecialchars($entry->getTitle()) ?></a>
            </h3>
            <p style="color:#666; font-size:0.9em;"><?= htmlspecialchars($entry->getExcerpt(120)) ?></p>
            <small style="color:#999;"><?= htmlspecialchars($entry->getCreatedAt()) ?></small>
        </div>
    <?php endforeach; ?>
<?php endif; ?>
```

This template defines its own `$title` variable, which the main layout will pick up. The `$entries` array is passed in by the controller and extracted by the View class before this file is required.

Save the file.

### Step 3: Update entry/show.php

Open `templates/entry/show.php` and replace with:

```php
<?php $title = htmlspecialchars($entry->getTitle()) . ' - Catatku'; ?>

<p><a href="/entries">&larr; Back to list</a></p>

<article style="background:#fff; border:1px solid #ddd; padding:20px; border-radius:6px;">
    <h1><?= htmlspecialchars($entry->getTitle()) ?></h1>
    <small style="color:#999;">
        <?= htmlspecialchars($entry->getCreatedAt()) ?>
        <?php if ($entry->isEdited()): ?>
            | Edited: <?= htmlspecialchars($entry->getUpdatedAt()) ?>
        <?php endif; ?>
    </small>
    <div style="white-space:pre-line; margin-top:15px; line-height:1.6;">
        <?= htmlspecialchars($entry->getContent()) ?>
    </div>
</article>
```

The `$entry` object provides all the data needed here. The parent layout will wrap this content in the site navigation, applying all CSS globally.

Save the file.

### Step 4: Update home.php

Open `templates/home.php` and replace with:

```php
<?php $title = 'Catatku - Your Personal Journal'; ?>

<h1>Welcome to Catatku</h1>
<p>Your personal journal application built with PHP OOP.</p>
<p><a href="/entries" class="btn btn-primary">View Entries</a></p>
```

Since this template has no dynamic data requirements from the database, it simply defines the title and writes the HTML content.

Save the file.

---

## 5. Update Controllers to Use View

In this section you will refactor the controllers to use the new `View::render()` method instead of calling `require` directly.

### Step 1: Update EntryController

Open `src/Controllers/EntryController.php` and replace the entire content with:

```php
<?php

namespace App\Controllers;

use App\View;
use App\Repositories\EntryRepository;

class EntryController
{
    private EntryRepository $entryRepo;

    public function __construct()
    {
        $this->entryRepo = new EntryRepository();
    }

    public function index(): void
    {
        $entries = $this->entryRepo->findAll();
        View::render('entry/index', ['entries' => $entries]);
    }

    public function show(int $id): void
    {
        $entry = $this->entryRepo->findById($id);
        if (!$entry) {
            http_response_code(404);
            echo '<h1>Entry not found</h1>';
            return;
        }
        View::render('entry/show', ['entry' => $entry]);
    }
}
```

Instead of managing the `require` calls and absolute paths themselves, the methods now just pass the template name string (e.g., `'entry/index'`) and an array of data.

Save the file.

### Step 2: Update HomeController

Open `src/Controllers/HomeController.php` and replace with:

```php
<?php

namespace App\Controllers;

use App\View;

class HomeController
{
    public function index(): void
    {
        View::render('home');
    }
}
```

The `HomeController` doesn't need to pass any data, so it skips the second argument entirely.

Save the file.

---

## 6. Start Sessions in the Front Controller

Since flash messages rely on PHP native sessions, the session must be started early in the application lifecycle before any output is sent to the browser.

### Step 1: Update public/index.php

Open `public/index.php` and add `session_start()` after the autoloader:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

session_start();

use App\Router;
use App\Controllers\HomeController;
use App\Controllers\EntryController;

$router = new Router();

$router->get('/', [HomeController::class, 'index']);
$router->get('/entries', [EntryController::class, 'index']);
$router->get('/entries/{id}', [EntryController::class, 'show']);

$router->dispatch(
    $_SERVER['REQUEST_METHOD'],
    $_SERVER['REQUEST_URI']
);
```

Calling `session_start()` at the top of the front controller ensures the session array `$_SESSION` is available globally across all controllers and views for the duration of the request.

### Step 2: Save and Run

Save the file (**Ctrl+S**). Run `composer dump-autoload`. Open:

```
http://localhost:8080/entries
```

You should see entries displayed inside the shared layout with navigation.

---

## 7. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
// Error 1: render() called with wrong template path
View::render('entries/index', ['entries' => $entries]);
// But template is at templates/entry/index.php (singular!)

// Error 2: extract() with name collision
View::render('entry/index', ['content' => $entries]);
// $content is already used by the layout for the page output!

// Error 3: Flash message read before session_start()
$msg = View::getFlash('success');
// If session_start() was not called first, $_SESSION is empty
```

**Error 1: Wrong template path.** The template is at `templates/entry/index.php`, so the first argument must be `'entry/index'` not `'entries/index'`.

**Error 2: Variable name collision.** The layout uses `$content` for the rendered page. If you pass `['content' => ...]` in data, `extract()` overwrites it. Use a different key name like `['entries' => ...]`.

**Error 3: Session not started.** The View class checks `session_status()` internally, but it is best to ensure `session_start()` is called in the front controller before any flash operations.

---

## 8. Exercises

**Exercise 1:** Create a second layout `templates/layouts/blank.php` that renders content without navigation. Use it for a 404 page: create `templates/errors/404.php` and render it in the Router's 404 handler with `View::render('errors/404', [], 'layouts/blank')`.

**Exercise 2:** Add an `error` flash message type. Test it by setting `View::setFlash('error', 'Something went wrong')` in a controller method and verifying the red message appears in the layout.

**Exercise 3:** Create a helper function `e(string $value): string` at the top of the layout that wraps `htmlspecialchars()`. Replace all `htmlspecialchars()` calls in the templates with the shorter `e()`. This is the same pattern as Laravel's `e()` helper.

---

## 9. Solutions

**Solution for Exercise 1:**

Create `templates/layouts/blank.php`:

```php
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title><?= $title ?? 'Catatku' ?></title></head>
<body style="font-family:Arial,sans-serif;max-width:700px;margin:50px auto;text-align:center;">
    <?= $content ?>
</body>
</html>
```

The blank layout still echoes `$content` but drops the navigation bar and uses simplified styling.

Create `templates/errors/404.php`:

```php
<?php $title = '404 - Not Found'; ?>
<h1>404 - Page Not Found</h1>
<p>The page you are looking for does not exist.</p>
<p><a href="/entries">Go to entries</a></p>
```

This template defines the custom title and content specifically for the 404 page.

In `src/Router.php`, update the 404 handler:

```php
http_response_code(404);
\App\View::render('errors/404', [], 'layouts/blank');
```

The third argument specifies the layout. Because `'layouts/blank'` is passed, the View class skips the default `layouts/main` layout and wraps the 404 content in the blank layout instead.

**Solution for Exercise 2:**

The layout already has the flash-error block. Test in a controller:

```php
View::setFlash('error', 'Something went wrong');
header('Location: /entries');
exit;
```

Because `header('Location: ...')` issues a redirect, the current request ends, and a new one starts. The flash message survives this redirect because it's stored in the `$_SESSION`.

**Solution for Exercise 3:**

At the top of `templates/layouts/main.php`, add:

```php
<?php
function e(string $value): string { return htmlspecialchars($value, ENT_QUOTES, 'UTF-8'); }
?>
```

The `ENT_QUOTES` flag ensures both single and double quotes are encoded. The `UTF-8` flag sets the encoding explicitly.

Then replace `htmlspecialchars($entry->getTitle())` with `e($entry->getTitle())` throughout templates.

---

## 10. Conclusion

The View class renders templates with a shared layout using output buffering. `extract()` converts data arrays into template variables. The layout provides the HTML skeleton and flash messages; child templates supply only their unique content. This is the same mechanism used by every PHP framework's template engine.

---

## Next Up - Lesson 10: Form Handling and CSRF Validation

In the next lesson you will:

1. Build the entry creation form with proper validation
2. Implement CSRF protection to secure form submissions
3. Use the session flash messages built in this lesson to notify users of success or validation errors