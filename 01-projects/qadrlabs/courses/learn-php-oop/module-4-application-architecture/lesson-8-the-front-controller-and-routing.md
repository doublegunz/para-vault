## 1. Before You Begin

### Introduction

Right now, `public/index.php` just dumps data. A real application needs to show different pages based on the URL: `/entries` for the listing, `/entries/1` for a detail page, `/login` for the login form. This lesson builds the routing system that makes that possible.

### What You'll Build

You will create a `Router` class, controller classes, and basic templates. Every request will enter through `public/index.php` (the front controller) and be routed to the correct controller method.

### What You'll Learn

- ✅ What the Front Controller pattern is and why every framework uses it
- ✅ How to build a simple Router class
- ✅ How to create controller classes with action methods
- ✅ How to extract URL parameters (like entry IDs) from the path
- ✅ How `$_SERVER['REQUEST_URI']` and `$_SERVER['REQUEST_METHOD']` work

### What You'll Need

- The repositories from Lesson 7 with seed data
- The development server running

---

## 2. Create the Router

In this section you will create the `Router` class that stores URL-to-controller mappings and dispatches each incoming request to the correct method.

### Step 1: Create the File

Right-click on the `src` folder, select **New File**, type `Router.php`, and press Enter.

### Step 2: Write the Code

Open `src/Router.php` and type the following code:

```php
<?php

namespace App;

class Router
{
    private array $routes = [];

    public function get(string $path, array $action): void
    {
        $this->routes['GET'][$path] = $action;
    }

    public function post(string $path, array $action): void
    {
        $this->routes['POST'][$path] = $action;
    }

    public function dispatch(string $method, string $uri): void
    {
        $path = parse_url($uri, PHP_URL_PATH);

        // Try exact match first
        if (isset($this->routes[$method][$path])) {
            $this->callAction($this->routes[$method][$path]);
            return;
        }

        // Try pattern matching (e.g., /entries/{id})
        foreach ($this->routes[$method] ?? [] as $route => $action) {
            $pattern = preg_replace('#\{(\w+)\}#', '(\d+)', $route);
            if (preg_match('#^' . $pattern . '$#', $path, $matches)) {
                array_shift($matches);
                $this->callAction($action, $matches);
                return;
            }
        }

        http_response_code(404);
        echo '<h1>404 - Page Not Found</h1>';
    }

    private function callAction(array $action, array $params = []): void
    {
        [$controllerClass, $method] = $action;
        $controller = new $controllerClass();
        call_user_func_array([$controller, $method], $params);
    }
}
```

### Step 3: Save the File

Press **Ctrl+S**.

### Code Breakdown

The Router stores routes as an array keyed by HTTP method and path. `dispatch()` matches the current request against registered routes. The `{id}` placeholder is converted to a regex that captures numeric values and passes them to the controller method.

---

## 3. Create the Controllers

Controllers receive a dispatched request and produce a response. This section creates two controllers: `HomeController` for the home page and `EntryController` for the entry listing and detail pages.

### Step 1: Create the Controllers Folder

Right-click on the `src` folder, select **New Folder**, type `Controllers`, and press Enter.

### Step 2: Create HomeController

Right-click on `src/Controllers`, select **New File**, type `HomeController.php`.

Open `src/Controllers/HomeController.php` and type:

```php
<?php

namespace App\Controllers;

class HomeController
{
    public function index(): void
    {
        require __DIR__ . '/../../templates/home.php';
    }
}
```

`require __DIR__ . '/../../templates/home.php'` loads the template in this method's scope. `__DIR__` holds the absolute path of `src/Controllers/`, so `../../` navigates two levels up to the project root before entering `templates/`. Any variables assigned before `require` are accessible inside the template file.

Save the file (**Ctrl+S**).

### Step 3: Create EntryController

Right-click on `src/Controllers`, select **New File**, type `EntryController.php`.

Open `src/Controllers/EntryController.php` and type:

```php
<?php

namespace App\Controllers;

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
        require __DIR__ . '/../../templates/entries/index.php';
    }

    public function show(int $id): void
    {
        $entry = $this->entryRepo->findById($id);
        if (!$entry) {
            http_response_code(404);
            echo '<h1>Entry not found</h1>';
            return;
        }
        require __DIR__ . '/../../templates/entries/show.php';
    }
}
```

The `index()` method calls `findAll()` and stores the result in `$entries`, which becomes available inside the template when `require` is called. The `show()` method receives the `$id` value extracted from the URL by the Router, calls `findById()`, and either renders the template or sends a 404 response if no matching entry was found.

Save the file (**Ctrl+S**).

---

## 4. Create the Templates

Controllers fetch and prepare data; templates render that data as HTML. Variables assigned in a controller method before the `require` call are available inside the corresponding template file.

### Step 1: Create Template Folders

In `templates/`, create a subfolder `entries/`.

### Step 2: Create home.php

Right-click on `templates`, select **New File**, type `home.php`.

Open `templates/home.php` and type:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Catatku</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 700px; margin: 0 auto; padding: 20px; }
        nav { background: #f0f0f0; padding: 10px 15px; margin-bottom: 20px; border-radius: 4px; }
        nav a { margin-right: 15px; text-decoration: none; color: #0077cc; font-weight: bold; }
    </style>
</head>
<body>
    <nav>
        <a href="/">Catatku</a>
        <a href="/entries">Entries</a>
    </nav>
    <h1>Welcome to Catatku</h1>
    <p>Your personal journal application built with PHP OOP.</p>
    <p><a href="/entries">View all entries</a></p>
</body>
</html>
```

The inline `<style>` block keeps styles self-contained for now. Each navigation link points to a route registered in `public/index.php`. The template is pure static HTML because `HomeController::index()` passes no variables to it.

Save the file.

### Step 3: Create entries/index.php

Right-click on `templates/entries`, select **New File**, type `index.php`.

Open `templates/entries/index.php` and type:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Entries - Catatku</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 700px; margin: 0 auto; padding: 20px; }
        nav { background: #f0f0f0; padding: 10px 15px; margin-bottom: 20px; border-radius: 4px; }
        nav a { margin-right: 15px; text-decoration: none; color: #0077cc; font-weight: bold; }
        .entry-card { border: 1px solid #ddd; padding: 15px; margin-bottom: 12px; border-radius: 6px; }
        .entry-card h3 { margin: 0 0 5px; }
        .entry-card h3 a { text-decoration: none; color: #333; }
        .entry-card small { color: #999; }
    </style>
</head>
<body>
    <nav>
        <a href="/">Catatku</a>
        <a href="/entries">Entries</a>
    </nav>
    <h1>My Entries</h1>
    <?php if (empty($entries)): ?>
        <p>No entries yet.</p>
    <?php else: ?>
        <?php foreach ($entries as $entry): ?>
            <div class="entry-card">
                <h3><a href="/entries/<?= $entry->getId() ?>"><?= htmlspecialchars($entry->getTitle()) ?></a></h3>
                <p><?= htmlspecialchars($entry->getExcerpt(100)) ?></p>
                <small><?= htmlspecialchars($entry->getCreatedAt()) ?></small>
            </div>
        <?php endforeach; ?>
    <?php endif; ?>
</body>
</html>
```

`$entries` is accessible here because `EntryController::index()` assigned it before calling `require`. The alternative `if/else/foreach ... endif` syntax is recommended for templates mixed with HTML because it is easier to scan. `<?= ... ?>` is shorthand for `<?php echo ... ?>`. `htmlspecialchars()` converts special HTML characters to entity equivalents, preventing XSS.

Save the file.

### Step 4: Create entries/show.php

Right-click on `templates/entries`, select **New File**, type `show.php`.

Open `templates/entries/show.php` and type:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?= htmlspecialchars($entry->getTitle()) ?> - Catatku</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 700px; margin: 0 auto; padding: 20px; }
        nav { background: #f0f0f0; padding: 10px 15px; margin-bottom: 20px; border-radius: 4px; }
        nav a { margin-right: 15px; text-decoration: none; color: #0077cc; font-weight: bold; }
    </style>
</head>
<body>
    <nav>
        <a href="/">Catatku</a>
        <a href="/entries">Entries</a>
    </nav>
    <p><a href="/entries">&larr; Back to list</a></p>
    <article>
        <h1><?= htmlspecialchars($entry->getTitle()) ?></h1>
        <small><?= htmlspecialchars($entry->getCreatedAt()) ?>
            <?php if ($entry->isEdited()): ?>
                | Edited: <?= htmlspecialchars($entry->getUpdatedAt()) ?>
            <?php endif; ?>
        </small>
        <div style="white-space: pre-line; margin-top: 15px;">
            <?= htmlspecialchars($entry->getContent()) ?>
        </div>
    </article>
</body>
</html>
```

`$entry` is the `Entry` object assigned in `EntryController::show()` before this template was loaded. `$entry->isEdited()` compares `updatedAt` with `createdAt` to conditionally display the edit timestamp. `white-space: pre-line` in the CSS preserves line breaks in the content without needing `nl2br()`.

Save the file.

---

## 5. Update the Front Controller

This section replaces the test code in `public/index.php` with the actual routing setup that maps each URL to a specific controller method.

### Step 1: Open the File

Open `public/index.php`.

### Step 2: Replace the Code

Replace the entire content with:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Router;
use App\Controllers\HomeController;
use App\Controllers\EntryController;

$router = new Router();

// Define routes
$router->get('/', [HomeController::class, 'index']);
$router->get('/entries', [EntryController::class, 'index']);
$router->get('/entries/{id}', [EntryController::class, 'show']);

// Dispatch the current request
$router->dispatch(
    $_SERVER['REQUEST_METHOD'],
    $_SERVER['REQUEST_URI']
);
```

`$router->get('/entries/{id}', [EntryController::class, 'show'])` registers a parameterized route. The `{id}` placeholder is converted to a regex pattern by the Router, which captures the numeric value and passes it as the first argument to `EntryController::show()`. `$_SERVER['REQUEST_METHOD']` holds the current HTTP verb and `$_SERVER['REQUEST_URI']` holds the full request path, including any query string that `parse_url()` strips inside `dispatch()`.

### Step 3: Save and Run

Save the file (**Ctrl+S**). Run `composer dump-autoload`. Restart the development server:

```bash
php -S localhost:8080 -t public
```

### Step 4: Test the Routes

Open the following URLs in the browser:

- `http://localhost:8080/` - shows the home page
- `http://localhost:8080/entries` - shows the entries listing
- `http://localhost:8080/entries/1` - shows the first entry's detail
- `http://localhost:8080/nonexistent` - shows a 404 page

---

## 6. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
// Error 1: Route path does not match URL
$router->get('/entry/{id}', [EntryController::class, 'show']);
// But the link says: <a href="/entries/1">

// Error 2: Controller method signature wrong
public function show(): void {  // Missing $id parameter!
    $entry = $this->entryRepo->findById($id);
}

// Error 3: Template path wrong
require __DIR__ . '/templates/home.php';
// But the file is at: templates/home.php (relative to project root, not src/)
```

**Error 1: Route path mismatch.** The route says `/entry/{id}` but the link says `/entries/1`. They must match exactly. Fix: `$router->get('/entries/{id}', ...)`.

**Error 2: Missing parameter.** The router extracts `{id}` from the URL and passes it to the method. The method must accept it: `public function show(int $id): void`.

**Error 3: Wrong `__DIR__` calculation.** Inside `src/Controllers/EntryController.php`, `__DIR__` is `src/Controllers/`. To reach `templates/`, you need `__DIR__ . '/../../templates/home.php'` (go up two levels).

---

## 7. Exercises

**Exercise 1:** Add a new route `GET /about` that maps to `HomeController::about()`. Create the `about()` method and `templates/about.php` template. Test at `http://localhost:8080/about`.

**Exercise 2:** Add a count to the entries listing template that shows "X entries found" at the top of the page.

**Exercise 3:** Add a route `GET /entries/{id}/json` that returns the entry data as JSON (use `header('Content-Type: application/json')` and `json_encode($entry->toArray())`). You will need the `toArray()` method from Lesson 4 Exercise 2. Test at `http://localhost:8080/entries/1/json`.

---

## 8. Solutions

**Solution for Exercise 1:**

Add to `public/index.php`:

```php
$router->get('/about', [HomeController::class, 'about']);
```

Add to `src/Controllers/HomeController.php`:

```php
    public function about(): void
    {
        require __DIR__ . '/../../templates/about.php';
    }
```

`require` loads the template in the method's scope. Since `about()` has no data to retrieve, no variables are assigned before `require`, and the template uses only static HTML.

Create `templates/about.php`:

```php
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>About - Catatku</title></head>
<body>
    <h1>About Catatku</h1>
    <p>A personal journal application built with PHP OOP.</p>
    <p><a href="/">Home</a></p>
</body>
</html>
```

**Solution for Exercise 2:**

In `templates/entries/index.php`, add after the `<h1>`:

```php
    <p><?= count($entries) ?> entries found</p>
```

**Solution for Exercise 3:**

Add to `public/index.php`:

```php
$router->get('/entries/{id}/json', [EntryController::class, 'showJson']);
```

Add to `src/Controllers/EntryController.php`:

```php
    public function showJson(int $id): void
    {
        $entry = $this->entryRepo->findById($id);
        if (!$entry) {
            http_response_code(404);
            echo json_encode(['error' => 'Not found']);
            return;
        }
        header('Content-Type: application/json');
        echo json_encode($entry->toArray());
    }
```

`header('Content-Type: application/json')` must be sent before any output. It tells the browser or API client to parse the response as JSON. `json_encode($entry->toArray())` converts the associative array of entry fields to a JSON string. The 404 branch also returns JSON to give API clients a consistent error format regardless of whether the entry exists.

Run at: `http://localhost:8080/entries/1/json`

---

## 9. Conclusion

The Front Controller pattern routes all requests through a single `public/index.php`. The Router class maps URL paths and HTTP methods to controller methods. Route parameters like `{id}` are extracted from the URL and passed to the controller. This is the same architecture that Laravel, Symfony, and CodeIgniter use.

---

## Next Up - Lesson 9: Templates and Shared Layouts

In the next lesson you will:

1. Build a shared layout template that eliminates HTML duplication across all pages
2. Implement a simple rendering system that injects page content into the layout
3. Refactor all existing templates to use the new shared layout