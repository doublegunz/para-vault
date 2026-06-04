In the previous lesson, we created a working entries listing page. But if you look at `routes/web.php` right now, something feels off: a file that should only contain a URL map is instead packed with logic, preparing data, defining arrays, and deciding what gets displayed. For a single route, that is still tolerable. But Catatku will eventually have many routes, and if they all follow the same pattern, `routes/web.php` will become a very uncomfortable place to work in.

This lesson solves that problem. And more than just moving code to a different file, you will understand *why* this separation is the right way to think about organizing your application.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the `/entries` page will display exactly the same result in the browser: three dummy entries, just like before. The difference will not be visible to the user, but the code structure behind it will be significantly better. Logic will live in a controller, presentation will stay in the view, and the route file will contain nothing but a clean map.

### What You'll Learn

- What the MVC (Model-View-Controller) architectural pattern is and why it exists
- The specific responsibility of each part: Model, View, and Controller
- How to generate a controller using the `php artisan make:controller` command
- How to move logic from a route closure into a controller method
- How to update routes to point to controller methods instead of closures
- How to verify registered routes using `php artisan route:list`

### What You'll Need

- The `catatku` project open in VS Code
- The development server running with `php artisan serve`
- The `/entries` route and `entries/index.blade.php` view from Lesson 3

---

## Step 1: Identify the Problem {#step-1-identify-the-problem}

Let us look at what we built in the previous lesson. Open `routes/web.php` and examine the `/entries` route:

```php
Route::get('/entries', function () {
    $entries = [
        ['title' => 'Year-end vacation plans...', ...],
        ...
    ];
    return view('entries.index', compact('entries'));
});
```

For one route, this still looks reasonable. But think ahead: Catatku will eventually need routes to display the entries list, show a single entry's detail, show a form to create a new entry, save that entry, show an edit form, save the changes, and delete an entry. If all of that logic gets piled into `routes/web.php`, the file will become extremely long and painful to maintain.

This is the problem that the **MVC** pattern solves.

---

## Step 2: Create the EntryController {#step-2-create-the-entrycontroller}

Laravel provides an Artisan command to generate controllers. Run the following in your terminal:

```bash
php artisan make:controller EntryController
```

Output:

```
INFO  Controller [app/Http/Controllers/EntryController.php] created successfully.
```

Open the newly created file at `app/Http/Controllers/EntryController.php`. You will see an empty class:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class EntryController extends Controller
{
    //
}
```

This is a standard Laravel controller. It lives in the `App\Http\Controllers` namespace and extends the base `Controller` class. Right now it has no methods, so it does not do anything yet. Let us change that.

Add an `index()` method that handles the entries listing page. This is the same logic we previously had inside the route closure, now living in its proper home:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class EntryController extends Controller
{
    public function index()
    {
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
    }
}

```

The `index()` method is a public function, which means Laravel can call it from the outside when a route points to it. The method name `index` is a convention in Laravel for the action that lists all resources. You will see this naming pattern throughout the course: `index` for listing, `show` for a single item, `create` for the form, `store` for saving, and so on.

Notice that the code inside `index()` is identical to what we had in the route closure. We have not changed any logic. We simply moved it to a more appropriate location.

---

## Step 3: Update the Route {#step-3-update-the-route}

Now update `routes/web.php` so the `/entries` route points to the controller instead of the anonymous function:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController; // add this line

Route::get('/', function () {
    return view('home');
});

Route::get('/entries', [EntryController::class, 'index']); // modify `/entries` route
```

Two things changed here. First, we added a `use` statement at the top to import `EntryController`. Without this import, Laravel would not know which class we are referring to.

Second, the `/entries` route now uses `[EntryController::class, 'index']` instead of a closure. Read this as: "When there is a GET request to `/entries`, call the `index` method on `EntryController`." The `::class` syntax gives Laravel the full class name as a string, so it can find and instantiate the controller automatically.

Look at how clean `routes/web.php` is now. It contains only URL mappings with no business logic at all. Each route says *what URL* maps to *which controller method*, and that is it. As we add more routes in future lessons, this file will remain readable because every route will be a single, concise line.

---

## Step 4: Verify the Result {#step-4-verify-the-result}

First, let us check that Laravel recognizes our routes correctly. Run the following command:

```bash
php artisan route:list
```

Output:

```
php artisan route:list

  GET|HEAD  / ............................................... routes/web.php:6
  GET|HEAD  entries .................................... EntryController@index
  GET|HEAD  storage/{path} storage.local › vendor/laravel/framework/src/Illum…
  PUT       storage/{path} storage.local.upload › vendor/laravel/framework/sr…
  GET|HEAD  up vendor/laravel/framework/src/Illuminate/Foundation/Configurati…

                                                            Showing [5] routes
```

The second line confirms that GET requests to `/entries` are handled by the `index` method of `EntryController`. The `route:list` command is a useful debugging tool. Whenever you add or modify routes, you can run it to verify that Laravel registered them correctly.

Now open your browser and go to `http://127.0.0.1:8000/entries`. The page should look exactly the same as before: three journal entries with titles, dates, and content snippets. The user sees no difference, but under the hood, the code is organized properly.
![entries page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/03-catatku-entries-page.webp)

---

## What is MVC? {#what-is-mvc}

Now that you have experienced the refactoring firsthand, let us understand the pattern behind it.

MVC stands for **Model - View - Controller**. It is an architectural pattern that separates an application into three parts, each with a distinct responsibility:

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Model     │    │    View     │    │ Controller  │
│              │    │             │    │             │
│ Talks to the │    │ Displays    │    │ Receives    │
│ database     │    │ data to the │    │ requests &  │
│              │    │ user as HTML│    │ coordinates │
│              │    │             │    │ the flow    │
└──────────────┘    └─────────────┘    └─────────────┘
```

**Model** is responsible for data. It communicates with the database to retrieve, store, update, and delete records. We have not created a model yet, but we will in Lesson 5.

**View** is responsible for presentation. It takes data provided by the controller and renders it as HTML. Our `entries/index.blade.php` file is a view.

**Controller** is responsible for application flow. It receives incoming requests, asks the model for data (or prepares it), and passes that data to the appropriate view. Our `EntryController` is a controller.

### The Restaurant Kitchen Analogy {#the-restaurant-kitchen-analogy}

Think of it like a restaurant:

**Model** is the kitchen. This is where raw ingredients (data) are stored, prepared, and processed.

**View** is the plate and the table. This is how the food is presented to the guest.

**Controller** is the waiter. The waiter takes the order from the guest, fetches the food from the kitchen, and serves it at the table.

The waiter does not cook. The kitchen does not interact with guests. Each part has one clear role, and the system works because everyone stays in their lane. The same principle applies to MVC: controllers do not write HTML, views do not query the database, and models do not decide which page to show.

---

## The Complete MVC Flow {#the-complete-mvc-flow}

With the changes we made in this lesson, here is how a request flows through the application:

```
Browser: GET /entries
              │
              ▼
        routes/web.php
        Route::get('/entries', [EntryController::class, 'index'])
              │
              ▼
        EntryController@index()
        $entries = [...];              ← will come from a Model later
        return view('entries.index', compact('entries'))
              │
              ▼
        resources/views/entries/index.blade.php
        @foreach ($entries as $entry) ...
              │
              ▼
        HTML sent to the browser
```

The browser sends a request. The route directs it to the controller. The controller prepares the data and passes it to the view. The view renders HTML and sends it back to the browser. Every web request in Laravel follows this same pattern.

Right now, the `$entries` data is a hardcoded array inside the controller. In the next lesson, that array will be replaced by a database query through an Eloquent model. But the rest of the flow, from controller to view to browser, will remain exactly the same.

---

## Conclusion {#conclusion}

This lesson made a change that is invisible to the user but transformative for the developer. Here are the key takeaways:

- **MVC** (Model-View-Controller) is an architectural pattern that separates your application into three parts: data (Model), presentation (View), and flow control (Controller).
- Each part has **one responsibility**: Models talk to the database, Views render HTML, and Controllers coordinate between them.
- `php artisan make:controller EntryController` generates a new controller file at `app/Http/Controllers/EntryController.php`.
- Controller methods like `index()` contain the logic that was previously inside route closures. The method name `index` is a Laravel convention for listing resources.
- Routes point to controllers using the syntax `[ControllerClass::class, 'methodName']`, keeping `routes/web.php` clean and focused on URL mapping only.
- `php artisan route:list` displays all registered routes and is useful for verifying that routes are wired up correctly.
- The **request flow** is: Browser sends a request, the route directs it to a controller, the controller prepares data and sends it to a view, the view renders HTML back to the browser.
- The refactoring we did produces the **exact same output** in the browser. The benefit is entirely in code organization, readability, and maintainability.

In the next lesson, we will replace the hardcoded array with real data. We will create a database table using a **migration** and meet **Eloquent**, Laravel's ORM that makes communicating with the database feel far more natural than you might expect.