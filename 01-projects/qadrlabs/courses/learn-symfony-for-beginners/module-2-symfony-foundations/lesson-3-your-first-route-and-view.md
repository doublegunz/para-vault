## 1. Before You Begin

In the previous lesson, we set up a complete development environment and got a Symfony project running in the browser. But what you saw was Symfony's default welcome page, not something we built. This lesson changes that. By the end, you will have created real pages with real code.

Symfony's fundamental job is to receive an HTTP request from the browser and return an HTTP response. The two pieces that connect these are routes and controllers. A route tells Symfony which URL maps to which code. A controller is the PHP function that runs when that URL is visited.

This lesson introduces both concepts by building a home page and an entries listing page using dummy data. You will also write your first Twig templates, learning the basic syntax that Symfony uses to generate HTML.

### What You'll Build

By the end of this lesson, Catatku will have two working pages: a home page at `/` and an entries listing page at `/entries`, both rendered through Twig templates with data passed from a controller.

### What You'll Learn

- ✅ How to define routes using the `#[Route]` PHP attribute on controller methods
- ✅ How to create Twig templates and pass data to them from a controller
- ✅ Basic Twig syntax: `{{ }}` for output, `{% %}` for logic, `{# #}` for comments
- ✅ How data flows from a controller to a Twig template
- ✅ How to verify registered routes using `php bin/console debug:router`

### What You'll Need

- The `catatku` project open in VS Code from Lesson 2
- The development server running (`php -S localhost:8080 -t public`)

---

## 2. Creating Your First Controller

In Symfony, routes are defined directly on controller methods using PHP attributes. This approach keeps the route definition directly above the code it triggers, making it easy to trace any URL to the exact function responsible for it.

### Step 1: Create the Home Controller

Create the file `src/Controller/HomeController.php`. This controller will handle requests to the root URL of the application.

```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class HomeController extends AbstractController
{
    #[Route('/', name: 'home')]
    public function index(): Response
    {
        return $this->render('home.html.twig');
    }
}
```

`#[Route('/', name: 'home')]` is a PHP attribute that tells Symfony: when a request arrives for the URL `/`, call this method. Because no `methods` option is given, the route accepts any HTTP method, which is why `debug:router` lists it as `ANY` later in this lesson. The `name` parameter assigns a unique identifier to the route. This name is used elsewhere to generate URLs, so you can change the actual path later without breaking any references.

`$this->render('home.html.twig')` finds a Twig template inside the `templates/` directory and returns its HTML output as an HTTP response. Controllers extend `AbstractController`, which provides helper methods like `render()`, `redirectToRoute()`, and `getUser()`. Without this base class, you would need to assemble the response object manually.

### Step 2: Create the Home Template

Create the file `templates/home.html.twig`. Symfony looks for templates inside the `templates/` folder by default, so you do not need to specify the full path in the `render()` call.

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
                {% if app.user %}
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        My Entries
                    </a>
                {% else %}
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        Log In
                    </a>
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-gray-200 text-lg font-medium rounded-xl text-blue-700 bg-white hover:bg-gray-50 shadow-sm flex-1 sm:flex-none transition-all duration-200 hover:border-gray-300">
                        Register
                    </a>
                {% endif %}
            </div>
        </div>
    </div>
</body>
</html>
```

`{% if app.user %}` checks whether a user is currently logged in. `app` is a global Twig variable that Symfony provides automatically in every template. It gives access to the current session, request, and authenticated user. The `href` attributes are empty for now because the login and register routes do not exist yet. You will wire up the Log In link in Lesson 10 and the Register link in Lesson 11.

Open `http://localhost:8080` to see the home page.

---

## 3. Building the Entries Listing

With the home page working, the next step is building the entries listing page. This introduces how to pass data from a controller to a template.

### Step 1: Create the Entry Controller with Dummy Data

Create `src/Controller/EntryController.php`. Unlike the `HomeController`, this controller will pass data to its template by including an associative array as the second argument to `render()`.

```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class EntryController extends AbstractController
{
    #[Route('/entries', name: 'entry_index')]
    public function index(): Response
    {
        $entries = [
            [
                'id'         => 1,
                'title'      => 'Year-end vacation plans',
                'content'    => 'It has been a while since the last vacation. Maybe Yogyakarta or Lombok.',
                'created_at' => '20 February 2026',
            ],
            [
                'id'         => 2,
                'title'      => 'First day learning Symfony',
                'content'    => 'Started learning Symfony today. The structure is clear and everything has its place.',
                'created_at' => '19 February 2026',
            ],
            [
                'id'         => 3,
                'title'      => 'This month\'s resolutions',
                'content'    => 'Want to be more consistent writing entries every day. At least one paragraph before bed.',
                'created_at' => '18 February 2026',
            ],
        ];

        return $this->render('entry/index.html.twig', [
            'entries' => $entries,
        ]);
    }
}
```

The second argument to `render()` is an associative array of variables that will be available inside the template. The key `'entries'` becomes the variable name `entries` in Twig. You can pass as many variables as needed by adding more key-value pairs to this array.

### Step 2: Create the Entries Template

Create the file `templates/entry/index.html.twig`. Symfony allows you to organize templates into subdirectories. Placing this file in a subfolder called `entry/` keeps things organized as the project grows.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Entries - Catatku</title>
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

        {# Entry list #}
        {% for entry in entries %}
            <div class="bg-white rounded-xl border border-gray-200 p-5 mb-4">
                <h3 class="font-semibold text-gray-900 mb-1">
                    {{ entry.title }}
                </h3>
                <p class="text-sm text-gray-500 mb-3">
                    {{ entry.created_at }}
                </p>
                <p class="text-sm text-gray-700 line-clamp-2">
                    {{ entry.content }}
                </p>
            </div>
        {% endfor %}

    </div>

</body>
</html>
```

Let us walk through the Twig syntax used in this template.

`{{ entry.title }}` outputs the value of a variable. Twig automatically escapes all output to prevent XSS (cross-site scripting) attacks. This means that if a user somehow stored `<script>alert('hacked')</script>` as a title, Twig would display it as text rather than executing it as JavaScript. You use dot notation (`entry.title`) to access array keys or object properties. Twig figures out automatically which one it is.

`{% for entry in entries %} ... {% endfor %}` iterates over the `entries` array. The `{% %}` tags are for control structures: loops, conditions, and other logic. They do not produce any output themselves.

`{# Entry list #}` is a Twig comment. Unlike HTML comments, Twig comments are completely stripped from the final output and never appear in the browser's view source.

---

## 4. Verifying Routes and Viewing the Result

After creating both controllers, it is worth verifying that Symfony has registered the routes correctly before opening the browser.

### Step 1: Check Routes with the Console

Open a terminal inside your project folder and run:

```bash
php bin/console debug:router
```

Output:

```text
 -------------------------- -------- ----------------------------------- 
  Name                       Method   Path                               
 -------------------------- -------- ----------------------------------- 
  _preview_error             ANY      /_error/{code}.{_format}           
  _wdt_stylesheet            ANY      /_wdt/styles                       
  _wdt                       ANY      /_wdt/{token}                      
  _profiler_home             ANY      /_profiler/                        
  _profiler_search           ANY      /_profiler/search                  
  _profiler_search_bar       ANY      /_profiler/search_bar              
  _profiler_phpinfo          ANY      /_profiler/phpinfo                 
  _profiler_xdebug           ANY      /_profiler/xdebug                  
  _profiler_font             ANY      /_profiler/font/{fontName}.woff2   
  _profiler_search_results   ANY      /_profiler/{token}/search/results  
  _profiler_open_file        ANY      /_profiler/open                    
  _profiler                  ANY      /_profiler/{token}                 
  _profiler_router           ANY      /_profiler/{token}/router          
  _profiler_exception        ANY      /_profiler/{token}/exception       
  _profiler_exception_css    ANY      /_profiler/{token}/exception.css   
  entry_index                ANY      /entries                           
  home                       ANY      /                                  
 -------------------------- -------- ----------------------------------- 
```

This command outputs a table of every route Symfony currently knows about. The `_profiler` and `_wdt` routes belong to the Web Profiler, a debugging toolbar that the `webapp` package installs for the `dev` environment. You should see `home` pointing to `HomeController::index` and `entry_index` pointing to `EntryController::index`. If a route is missing, it usually means there is a typo in the `#[Route]` attribute or the file is in the wrong directory.

### Step 2: Open the Entries Page

Open `http://localhost:8080/entries` in your browser. You should see three journal entries rendered from the dummy data defined in the controller. You are seeing real data flow from PHP through Twig and into HTML.

---

## 5. How Routes and Data Flow Work

Having built these two pages, it is worth stepping back to understand the pattern you just used. This pattern repeats throughout the entire course.

### How a Route Works

A route maps a URL to the code that should run. In Symfony, routes are defined using `#[Route]` attributes directly on controller methods. The basic structure is:

```php
#[Route('/url', name: 'route_name', methods: ['GET'])]
public function methodName(): Response
{
    return $this->render('template.html.twig', ['key' => $value]);
}
```

The `name` parameter is especially important. Instead of hardcoding URLs in your templates and controllers, Symfony lets you reference routes by name. In a Twig template you write `{{ path('route_name') }}`, and in a controller you write `$this->redirectToRoute('route_name')`. This means changing a URL from `/entries` to `/journal` only requires updating the `#[Route]` attribute. All references to the name update automatically.

### How Data Flows from Controller to Template

The data flow follows a simple, consistent pattern:

```text
src/Controller/EntryController.php
    $entries = [...];
    return $this->render('entry/index.html.twig', ['entries' => $entries])
            │
            ▼
templates/entry/index.html.twig
    {% for entry in entries %}
        {{ entry.title }}
    {% endfor %}
```

Data is prepared in the controller, passed to the template as an associative array, and rendered using Twig syntax. This same flow repeats whether the data comes from a hardcoded array (like now) or from the database (as it will from Lesson 6 onward).

---

## 6. Fix the Errors in Your Code

**Error 1: Template not found.**

This error appears when the path passed to `render()` does not match the actual file location.

```php
// Wrong: file is at templates/entry/index.html.twig
return $this->render('index.html.twig');

// Correct: include the subdirectory
return $this->render('entry/index.html.twig');
```

Symfony looks for templates relative to the `templates/` directory. If your template is inside a subdirectory, you must include that path. Double-check the filename, extension (`.html.twig`), and folder name for typos.

**Error 2: Twig variable undefined.**

This appears when a template references a variable that was not passed from the controller.

```php
// Wrong: 'entries' key is missing from the array
return $this->render('entry/index.html.twig', []);

// Correct: include the variable in the second argument
return $this->render('entry/index.html.twig', [
    'entries' => $entries,
]);
```

Every variable used in a Twig template must be explicitly passed in the second argument to `render()`. If you reference `{{ entries }}` in Twig but the controller passes an empty array, Symfony will throw an error in `dev` mode. Check that the key in PHP matches the variable name used in the template exactly.

**Error 3: Route not responding because methods is mismatched.**

When you add `methods: ['POST']` to a route, it only responds to POST requests. Visiting the URL directly in the browser sends a GET request.

```php
// Wrong: this route only accepts POST, so the browser gets a 405 error
#[Route('/entries', name: 'entry_index', methods: ['POST'])]

// Correct: use GET for pages the user visits directly
#[Route('/entries', name: 'entry_index', methods: ['GET'])]
```

For any page the user navigates to directly, use `methods: ['GET']`. Reserve `methods: ['POST']` for routes that handle form submissions. When no `methods` is specified, the route accepts all HTTP methods.

---

## 7. Exercises

**Exercise 1:** Open `src/Controller/HomeController.php` and add a second route to the same controller that responds to `/about` and renders a simple template called `about.html.twig`. Create the template with a heading that reads "About Catatku". Verify the route appears in the output of `php bin/console debug:router`.

**Exercise 2:** In `EntryController::index()`, add a fourth dummy entry to the `$entries` array. Give it an `id` of `4`, a title of your choice, a content of your choice, and today's date as `created_at`. Reload the browser and verify the fourth entry appears.

**Exercise 3:** Inside `templates/entry/index.html.twig`, add an empty state message. Use Twig's `{% if entries is empty %}` to display the text "No entries yet. Start writing!" when the entries array is empty. Test it by temporarily setting `$entries = []` in the controller.

---

## 8. Solutions

**Solution for Exercise 1:**

Add an `about()` method to `HomeController`. The complete file now looks like this:

```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class HomeController extends AbstractController
{
    #[Route('/', name: 'home')]
    public function index(): Response
    {
        return $this->render('home.html.twig');
    }

    #[Route('/about', name: 'about')]
    public function about(): Response
    {
        return $this->render('about.html.twig');
    }
}
```

Then create `templates/about.html.twig`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>About - Catatku</title>
</head>
<body>
    <h1>About Catatku</h1>
    <p>Catatku is a personal journal application built with Symfony 8.</p>
</body>
</html>
```

`#[Route('/about', name: 'about')]` registers a new route for the `/about` URL with the name `about`. Run `php bin/console debug:router` to confirm it appears in the list alongside the `home` and `entry_index` routes.

**Solution for Exercise 2:**

Add the following array to the `$entries` variable in `EntryController::index()`:

```php
[
    'id'         => 4,
    'title'      => 'Planning a new project',
    'content'    => 'I want to start a side project this month. Still figuring out what to build.',
    'created_at' => '21 February 2026',
],
```

`$entries` is a regular PHP array. Adding a new element to it automatically makes it available in the Twig template, because the entire array is passed to `render()`. When you reload `http://localhost:8080/entries`, the fourth card appears because the `{% for entry in entries %}` loop iterates over every item in the array.

**Solution for Exercise 3:**

Update `templates/entry/index.html.twig` to wrap the entry loop with an empty state check:

```html
{% if entries is empty %}
    <div class="text-center py-16 text-gray-400">
        <p class="text-lg font-medium">No entries yet. Start writing!</p>
    </div>
{% else %}
    {% for entry in entries %}
        <div class="bg-white rounded-xl border border-gray-200 p-5 mb-4">
            <h3 class="font-semibold text-gray-900 mb-1">{{ entry.title }}</h3>
            <p class="text-sm text-gray-500 mb-3">{{ entry.created_at }}</p>
            <p class="text-sm text-gray-700 line-clamp-2">{{ entry.content }}</p>
        </div>
    {% endfor %}
{% endif %}
```

`{% if entries is empty %}` is a Twig test that returns true when the variable is an empty array or an empty collection. The `{% else %}` block runs when entries exist. Twig's `is empty` test works the same way for both arrays and Doctrine collections, so this pattern will continue to work in Lesson 6 when the entries come from the database.

---

## Next Up - Lesson 4

In this lesson, you built two pages powered by real PHP and Twig. You defined routes using `#[Route]` attributes, passed data from a controller to a template, and learned the three types of Twig tags. The data flow pattern (the controller prepares data, `render()` passes it to Twig, and Twig displays it) is the backbone of every page in Catatku.

In Lesson 4, you will formalize the MVC pattern and understand exactly how Symfony organizes code into Controllers, Entities, and Templates. The code structure you have now will make much more sense once you see the architecture behind it.