In the previous lesson, we set up a complete development environment and got a CodeIgniter project running in the browser. But what you saw was CodeIgniter's default welcome page, not something we built. This lesson changes that. For the first time, we will create pages that actually belong to Catatku: a home page and an entries listing page that you can open in the browser and see real content rendered from data.

## Overview {#overview}

### What You'll Build

By the end of this lesson, you will be able to open your browser, go to `http://localhost:8080/entries`, and see a journal entries listing page with several entries displayed neatly. The data shown will come from an array we write ourselves, not from a database yet, but the layout and flow already reflect how a real application works.

### What You'll Learn

- What a route is and how it connects a URL to the code that runs
- How to define routes in `app/Config/Routes.php`
- How to create PHP views and organize them in folders
- How to pass data from routes to views
- Basic PHP template syntax for displaying variables and loops

### What You'll Need

- The `catatku` project open in VS Code
- The development server running with `php spark serve`
- Nothing new to install

---

## Step 1: Explore the Default Route File {#step-1-explore-the-default-route-file}

Open `app/Config/Routes.php` in VS Code. You will find a default route near the bottom of the file:

```php
$routes->get('/', 'Home::index');
```

Read this line as: "When there is a GET request to the URL `/`, call the `index` method on the `Home` controller."

Unlike some frameworks where routes use closures (anonymous functions), CodeIgniter routes always point to controller methods using the `Controller::method` string syntax. The `Home` controller already exists at `app/Controllers/Home.php`, and its `index()` method loads the default welcome page. The ‘welcome_message’ parameter in the `view()` function refers to the view file `app/Views/welcome_message.php`.

A **view** is a file that turns data into HTML that gets sent to the browser. CodeIgniter uses plain PHP files for views, which means you write standard PHP mixed with HTML. There is no special template language to learn.

---

## Step 2: Create the Home Page {#step-2-create-the-home-page}

Let us create a proper home page for Catatku. First, update `app/Controllers/Home.php`:

```php
<?php

namespace App\Controllers;

class Home extends BaseController
{
    public function index()
    {
        return view('home');
    }
}
```

Now create the view file at `app/Views/home.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Catatku - Simple Journal App</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50 text-gray-900 font-sans antialiased selection:bg-blue-100">
    <div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-blue-50 to-white">
        <div class="max-w-2xl w-full text-center px-6 py-12">
            <h1 class="text-5xl font-extrabold tracking-tight text-blue-600 mb-6 drop-shadow-sm">Catatku</h1>
            <p class="text-xl text-gray-600 mb-10 leading-relaxed">
                A simple journal app to accompany your day. Start capturing what matters, easily and quickly.
            </p>
            
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
                <?php if (session()->get('user_id')): ?>
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        My Entries
                    </a>
                <?php else: ?>
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        Log In
                    </a>
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-gray-200 text-lg font-medium rounded-xl text-blue-700 bg-white hover:bg-gray-50 shadow-sm flex-1 sm:flex-none transition-all duration-200 hover:border-gray-300">
                        Register
                    </a>
                <?php endif; ?>
            </div>
        </div>
    </div>
</body>
</html>
```

Save the file.
If the development server isn't running yet, run the following command:
```
php spark serve
```

Then open `http://localhost:8080` in your browser. You should see the Catatku home page.

![view catatku home page](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/01-app-homepage.webp)

Notice the `session()->get('user_id')` check in the template. This is a conditional that checks whether a user is logged in by looking for a `user_id` value in the session. Since we have not built authentication yet, the browser will always show the "Log In" and "Register" buttons. The `href` attributes are empty for now. We will wire them up in Lesson 11.

---

## Step 3: Add the Entries Route {#step-3-add-the-entries-route}

CodeIgniter routes can use closures for quick prototyping. Open `app/Config/Routes.php` and add a route for the entries listing. Find the existing route section and add below it:

```php
$routes->get('/', 'Home::index');

$routes->get('/entries', static function () {
    $entries = [
        [
            'id'         => 1,
            'title'      => 'Year-end vacation plans',
            'content'    => 'It has been a while since the last vacation. Maybe Yogyakarta or Lombok. Need to research the budget and best timing.',
            'created_at' => '20 February 2026',
        ],
        [
            'id'         => 2,
            'title'      => 'First day learning CodeIgniter',
            'content'    => 'Started learning CodeIgniter today. Turns out it is not as hard as I expected. Routing and views are quite intuitive.',
            'created_at' => '19 February 2026',
        ],
        [
            'id'         => 3,
            'title'      => 'This month\'s resolutions',
            'content'    => 'Want to be more consistent writing entries every day. At least one paragraph before bed.',
            'created_at' => '18 February 2026',
        ],
    ];

    return view('entries/index', ['entries' => $entries]);
});
```

The second argument to `view()` is an associative array of data to pass to the view. The key `'entries'` becomes a `$entries` variable inside the view file. This is how data travels from a route to a view in CodeIgniter.

The view name `'entries/index'` tells CodeIgniter to look for a file at `app/Views/entries/index.php`. The slash maps directly to folder structure.

---

## Step 4: Create the Entries View {#step-4-create-the-entries-view}

Create a new folder called `entries` inside `app/Views/`, then create a file called `index.php` inside it:

```
app/
└── Views/
    ├── home.php
    └── entries/
        └── index.php   ← create this file
```

Add the following content to `app/Views/entries/index.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Entries — Catatku</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50">

    <nav class="bg-white border-b border-gray-200 px-6 py-4">
        <h1 class="text-xl font-bold text-gray-900">Catatku 📓</h1>
    </nav>

    <div class="max-w-2xl mx-auto mt-8 px-4">

        <div class="flex items-center justify-between mb-6">
            <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
            <a href="/entries/create"
               class="bg-gray-900 text-white text-sm px-4 py-2 rounded-lg hover:bg-gray-700">
                + Write New Entry
            </a>
        </div>

        <?php foreach ($entries as $entry): ?>
            <div class="bg-white rounded-xl border border-gray-200 p-5 mb-4">
                <h3 class="font-semibold text-gray-900 mb-1">
                    <?= esc($entry['title']) ?>
                </h3>
                <p class="text-sm text-gray-500 mb-3">
                    <?= esc($entry['created_at']) ?>
                </p>
                <p class="text-sm text-gray-700 line-clamp-2">
                    <?= esc($entry['content']) ?>
                </p>
            </div>
        <?php endforeach; ?>

    </div>

</body>
</html>
```

Let us walk through the key syntax used in this template.

`<?= esc($entry['title']) ?>` displays the value of a variable with automatic escaping. The `esc()` function is CodeIgniter's helper that runs the output through `htmlspecialchars`, protecting your application from XSS (Cross-Site Scripting) attacks. Always use `esc()` when displaying user-facing data.

`<?php foreach ($entries as $entry): ?> ... <?php endforeach; ?>` is a standard PHP loop using the alternative syntax with colons. This syntax is preferred in templates because it is easier to read when mixed with HTML compared to curly braces.

---

## Step 5: View the Result {#step-5-view-the-result}

Make sure the development server is running, then open `http://localhost:8080/entries` in your browser.

![view entries listing page](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/02-view-entries-page.webp)

You should see the entries listing page with three journal entries. The data comes from the array we defined in the route.

---

## What is a Route? {#what-is-a-route}

A route is a mapping between a URL and the code that should run when that URL is requested. In CodeIgniter, all web routes are defined in `app/Config/Routes.php`.

Think of a route like a receptionist in an office building. When a visitor arrives and says "I need to go to the archives room," the receptionist directs them to the correct floor and room. Routes work the same way: when the browser requests a specific URL, the route directs the request to the right piece of code.

The basic pattern in CodeIgniter looks like this:

```php
$routes->get('/url', 'Controller::method');
```

`$routes->get` means this route responds to HTTP GET requests. The first argument is the URL path. The second argument is a string that tells CodeIgniter which controller and method to call.

---

## Data Flow: Route to View {#data-flow-route-to-view}

Understanding how data moves through your application is essential:

```
app/Config/Routes.php (or Controller)
    $entries = [...];
    return view('entries/index', ['entries' => $entries]);
            │
            ▼
app/Views/entries/index.php
    <?php foreach ($entries as $entry): ?>
        <?= esc($entry['title']) ?>
    <?php endforeach; ?>
```

The data is created in the route (or controller), passed to the view as an associative array, and displayed using PHP. This pattern will stay exactly the same throughout the course. Only the data source changes.

---

## Conclusion {#conclusion}

This lesson brought Catatku from a blank project to something you can see in the browser. Here are the key takeaways:

- A **route** maps a URL to code. All web routes live in `app/Config/Routes.php`.
- `$routes->get('/path', 'Controller::method')` defines a route that responds to GET requests.
- A **view** is a PHP template file in `app/Views/`. Views use the `.php` extension.
- Data is passed to views as an associative array: `view('name', ['key' => $value])`. Keys become variables inside the view.
- `esc($variable)` displays a value with automatic XSS protection. Always use this instead of raw `echo`.
- `<?php foreach ... endforeach; ?>` loops over arrays to render repeated HTML blocks.
- The **data flow pattern** (route/controller prepares data, passes it to a view, PHP renders it) stays the same throughout the entire course.

In the next lesson, we will learn about the **MVC pattern** and why CodeIgniter organizes code the way it does. Right now, all our logic lives in `Routes.php`, and that will start feeling uncomfortable as the application grows.