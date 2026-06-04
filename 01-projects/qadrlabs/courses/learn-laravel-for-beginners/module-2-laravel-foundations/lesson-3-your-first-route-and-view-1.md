In the previous lesson, we set up a complete development environment and got a Laravel project running in the browser. But what you saw was Laravel's default welcome page, not something we built. This lesson changes that. For the first time, we will create pages that actually belong to Catatku: a home page and an entries listing page that you can open in the browser and see real content rendered from data.

## Overview {#overview}

### What You'll Build

By the end of this lesson, you will be able to open your browser, go to `http://127.0.0.1:8000/entries`, and see a journal entries listing page with several entries displayed neatly. The data shown will come from an array we write ourselves, not from a database yet, but the layout and flow already reflect how a real application works. You will also create a custom home page for Catatku to replace Laravel's default welcome page.

### What You'll Learn

- What a route is and how it connects a URL to the code that runs
- How to define routes in `routes/web.php`
- How to create Blade views and organize them in folders
- Basic Blade syntax: `{{ }}` for displaying variables, `@foreach` for loops, and `{{-- --}}` for comments
- How data flows from a route to a view using `compact()`

### What You'll Need

- The `catatku` project open in VS Code
- The development server running with `php artisan serve`
- Nothing new to install. Everything you need is already inside the Laravel project we created in Lesson 2

---

## Step 1: Explore the Default Route File {#step-1-explore-the-default-route-file}

Open `routes/web.php` in VS Code. You will find one route that Laravel created for you:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});
```

Read this line as: "When there is a GET request to the URL `/`, run this function, which returns a view file called `welcome.blade.php`."

There are two important concepts here. First, `Route::get('/', ...)` tells Laravel to listen for GET requests at the root URL. GET is the HTTP method your browser uses when you type a URL and press Enter. Second, `return view('welcome')` tells Laravel to find a file called `welcome.blade.php` inside `resources/views/` and send its HTML content back to the browser.

This is the route responsible for the Laravel welcome page you saw in the previous lesson when you opened `http://127.0.0.1:8000`.

A **view** is a file that turns data into HTML that gets sent to the browser. Laravel uses **Blade** as its template engine. Blade files are regular HTML enhanced with a cleaner, safer PHP syntax that makes working with dynamic data much more pleasant.

---

## Step 2: Create the Home Page {#step-2-create-the-home-page}

Instead of showing Laravel's default welcome page, let us create a proper home page for Catatku. First, update the route in `routes/web.php` to point to a new view:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('home');
});
```

The only change here is replacing `'welcome'` with `'home'`. This tells Laravel to look for `home.blade.php` instead of `welcome.blade.php` when someone visits the root URL.

Now create the view file. Make a new file at `resources/views/home.blade.php` and add the following content:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Catatku - Simple Journal App</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-900 font-sans antialiased selection:bg-blue-100">
    <div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-blue-50 to-white">
        <div class="max-w-2xl w-full text-center px-6 py-12">
            <h1 class="text-5xl font-extrabold tracking-tight text-blue-600 mb-6 drop-shadow-sm">Catatku</h1>
            <p class="text-xl text-gray-600 mb-10 leading-relaxed">
                A simple journal app to accompany your day. Start capturing what matters, easily and quickly.
            </p>
            
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
                @auth
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        My Entries
                    </a>
                @else
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        Log In
                    </a>
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-gray-200 text-lg font-medium rounded-xl text-blue-700 bg-white hover:bg-gray-50 shadow-sm flex-1 sm:flex-none transition-all duration-200 hover:border-gray-300">
                        Register
                    </a>
                @endauth
            </div>
        </div>
    </div>
</body>
</html>
```

Save the file.
As a reminder, if the development server isn't running yet, run the following command first `php artisan serve`, then open `http://127.0.0.1:8000` in your browser. 

Instead of the default Laravel page, you should now see the Catatku home page with the app title, a description, and navigation buttons.

![catatku homepage](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/02-catatku-landing-page.webp)

Notice the `@auth` and `@else` directives in the template. These are Blade conditionals that check whether a user is logged in. Since we have not built authentication yet, the browser will show the "Log In" and "Register" buttons (the `@else` block). The `href` attributes are empty for now. We will wire them up in Lesson 11 when the authentication system is complete.

---

## Step 3: Add the Entries Route {#step-3-add-the-entries-route}

Now let us create the route for the journal entries listing page. We will use dummy data for now so we can focus on understanding how routes and views work before touching the database.

Open `routes/web.php` and add a new route below the existing one:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('home');
});

Route::get('/entries', function () {
    $entries = [
        [
            'id'         => 1,
            'title'      => 'Year-end vacation plans',
            'content'    => 'It has been a while since the last vacation. Maybe Yogyakarta or Lombok. Need to research the budget and best timing.',
            'created_at' => '20 February 2026',
        ],
        [
            'id'         => 2,
            'title'      => 'First day learning Laravel',
            'content'    => 'Started learning Laravel today. Turns out it is not as hard as I expected. Routing and views are quite intuitive.',
            'created_at' => '19 February 2026',
        ],
        [
            'id'         => 3,
            'title'      => 'This month\'s resolutions',
            'content'    => 'Want to be more consistent writing entries every day. At least one paragraph before bed.',
            'created_at' => '18 February 2026',
        ],
    ];

    return view('entries.index', compact('entries'));
});
```

This new route listens for GET requests to `/entries`. Inside the closure, we create an `$entries` array containing three fake journal entries. Each entry has an `id`, `title`, `content`, and `created_at` field, mimicking the structure we will eventually use with real database records.

The `return view('entries.index', compact('entries'))` line does two things. The first argument `'entries.index'` tells Laravel to look for a view file at `resources/views/entries/index.blade.php`. The dot notation maps directly to folder structure. The second argument `compact('entries')` is a PHP shorthand for `['entries' => $entries]`. It takes the variable `$entries` and makes it available inside the view under the same name. This is how data travels from a route to a view.

---

## Step 4: Create the Entries View {#step-4-create-the-entries-view}

Create a new folder called `entries` inside `resources/views/`, then create a file called `index.blade.php` inside it:

```
resources/
└── views/
    ├── home.blade.php
    └── entries/
        └── index.blade.php   ← create this file
```

Add the following content to `resources/views/entries/index.blade.php`:

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

        {{-- Entry list --}}
        @foreach ($entries as $entry)
            <div class="bg-white rounded-xl border border-gray-200 p-5 mb-4">
                <h3 class="font-semibold text-gray-900 mb-1">
                    {{ $entry['title'] }}
                </h3>
                <p class="text-sm text-gray-500 mb-3">
                    {{ $entry['created_at'] }}
                </p>
                <p class="text-sm text-gray-700 line-clamp-2">
                    {{ $entry['content'] }}
                </p>
            </div>
        @endforeach

    </div>

</body>
</html>
```

Let us walk through the Blade syntax used in this template.

`{{ $entry['title'] }}` displays the value of a variable. The double curly braces are not just for display. Laravel automatically runs the output through `htmlspecialchars`, which protects your application from XSS (Cross-Site Scripting) attacks. You should always use `{{ }}` instead of raw PHP `echo` when displaying user-facing data.

`@foreach ($entries as $entry) ... @endforeach` is a loop that iterates over each item in the `$entries` array. For every entry, Blade renders the HTML block inside the loop once, with `$entry` containing the current item's data. This is how we display a list of items without duplicating HTML manually.

`{{-- Entry list --}}` is a Blade comment. Unlike HTML comments (`<!-- -->`), Blade comments are completely stripped from the output. They never appear in the HTML that gets sent to the browser, which means they are invisible to anyone viewing your page source.

---

## Step 5: View the Result {#step-5-view-the-result}

Make sure the development server is still running (we started it earlier with `php artisan serve`), then open your browser and go to `http://127.0.0.1:8000/entries`.

![View entries page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/03-catatku-entries-page.webp)

You should see the entries listing page with three journal entries displayed neatly, each showing a title, a date, and a content snippet. The data comes from the array we defined in the route. The "+ Write New Entry" button does not work yet because we have not created that route, but the page itself is fully functional.

Try visiting `http://127.0.0.1:8000` as well to confirm the home page is still working. You now have two working routes in your application: `/` for the home page and `/entries` for the entries listing.

---

## What is a Route? {#what-is-a-route}

Now that you have seen routes in action, let us step back and understand the concept more clearly.

When you type `http://127.0.0.1:8000/entries` in your browser, something needs to decide what page to show. That something is a **route**.

A route is a mapping between a URL and the code that should run when that URL is requested. In Laravel, all web routes are defined in the `routes/web.php` file.

Think of a route like a receptionist in an office building. When a visitor arrives and says "I need to go to the archives room," the receptionist directs them to the correct floor and room. Routes work the same way: when the browser requests a specific URL, the route directs the request to the right piece of code.

The basic pattern looks like this:

```php
Route::get('/url', function () {
    // Code that runs when this URL is visited
    return view('template-name');
});
```

`Route::get` means this route responds to HTTP GET requests (the kind your browser makes when you type a URL). The first argument is the URL path. The second argument is a closure (an anonymous function) that contains the code to execute. Whatever this function returns is what gets sent back to the browser.

---

## Data Flow: Route to View {#data-flow-route-to-view}

Understanding how data moves through your application is essential. Here is the pattern we used in this lesson:

```
routes/web.php
    $entries = [...];
    return view('entries.index', compact('entries'));
            │
            ▼
resources/views/entries/index.blade.php
    @foreach ($entries as $entry)
        {{ $entry['title'] }}
    @endforeach
```

The data is created in the route, passed to the view through `compact()`, and displayed using Blade syntax. This pattern will stay exactly the same throughout the rest of the course. The only thing that will change is where the data comes from. Right now it is a hardcoded array. In a few lessons, `$entries` will come from the database through Eloquent. But the flow from route to view remains identical.

This is one of the most important things to understand early: **the mechanism for passing data to views does not change based on the data source.** Whether the data comes from an array, an API, or a database query, the view always receives it the same way and renders it the same way.

---

## Conclusion {#conclusion}

This lesson brought Catatku from a blank project to something you can see and interact with in the browser. Here are the key takeaways:

- A **route** maps a URL to the code that should run when that URL is requested. All web routes live in `routes/web.php`.
- `Route::get('/path', function () { ... })` defines a route that responds to GET requests at the given path.
- A **view** is a Blade template file that turns data into HTML. Views live in `resources/views/` and use the `.blade.php` extension.
- Laravel uses **dot notation** to map view names to folder paths: `'entries.index'` maps to `resources/views/entries/index.blade.php`.
- `compact('entries')` is a shorthand for `['entries' => $entries]` and is the standard way to pass data from a route to a view.
- `{{ $variable }}` displays a value with automatic XSS protection. Always use this instead of raw PHP `echo`.
- `@foreach` loops over collections to render repeated HTML blocks without code duplication.
- `{{-- comment --}}` creates comments that are stripped from the HTML output entirely.
- The **data flow pattern** (route prepares data, passes it to a view, Blade renders it) stays the same throughout the entire course. Only the data source changes.

In the next lesson, we will learn about the **MVC pattern** and why Laravel organizes code the way it does. Right now, all our logic and data live together in `routes/web.php`, and that will start feeling uncomfortable as the application grows. Controllers solve this problem, and understanding why they exist will make everything we build afterward feel much more natural.