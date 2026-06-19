## 1. Before You Begin

By default, CI3 URLs follow the pattern `controller/method/parameter`. But you can customize this with routes: map `/` to a specific controller, create friendly URLs, or restrict HTTP methods. Routes are defined in `application/config/routes.php`.

### What You'll Build

You will configure the default controller, add custom routes for the blog, and understand URL segment mapping.

### What You'll Learn

- ✅ Default CI3 URL structure: `controller/method/params`
- ✅ Configuring the default controller in `routes.php`
- ✅ Custom routes with wildcards: `(:num)`, `(:any)`
- ✅ Redirecting the home page to posts
- ✅ Reserved routes: `default_controller`, `404_override`

### What You'll Need

- Lesson 3 completed

---

## 2. Configure Routes

Let's configure custom routes to map friendly URLs to our controllers.

### Step 1: Open routes.php

Open `application/config/routes.php` in VS Code. This file is where you define every custom URL mapping for the application. By default, it only contains the `default_controller` and a few reserved keys.

### Step 2: Add Routes

Replace the existing content with the following route definitions for our blog.

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

// Default controller (home page)
$route['default_controller'] = 'posts';

// Custom routes for blog
$route['posts']              = 'posts/index';
$route['posts/create']       = 'posts/create';
$route['posts/(:num)']       = 'posts/show/$1';
$route['posts/edit/(:num)']  = 'posts/edit/$1';
$route['posts/delete/(:num)'] = 'posts/delete/$1';

// Reserved
$route['404_override'] = '';
$route['translate_uri_dashes'] = FALSE;
```

Here is what each line does:

- `$route['default_controller'] = 'posts'` tells CI3 which controller to load when the user visits the root URL (`/`). Without this, visiting `http://localhost/ci3-blog/` would return a 404 error.
- `$route['posts'] = 'posts/index'` maps the URL `/posts` to the `index()` method of the `Posts` controller.
- `$route['posts/create'] = 'posts/create'` maps the URL `/posts/create` to the `create()` method. **Important:** this specific route must be defined before any wildcard route that could match it, otherwise the wildcard will intercept the request first.
- `$route['posts/(:num)'] = 'posts/show/$1'` maps any URL like `/posts/5` to the `show()` method, passing `5` as the `$id` parameter. `(:num)` is a wildcard that matches only numeric segments. `$1` refers to the value matched by the first wildcard.
- `$route['posts/edit/(:num)']` and `$route['posts/delete/(:num)']` follow the same pattern and will be used in Lessons 9 and 10.
- `$route['404_override'] = ''` means CI3 will use its own default 404 page. You can set this to a controller/method to create a custom 404 page.
- `$route['translate_uri_dashes'] = FALSE` keeps URL dashes as-is. If set to TRUE, CI3 would convert dashes in URL segments to underscores when looking for controllers and methods.

### Step 3: Save and Test

Press **Ctrl+S** to save the routes file. Then open your browser and test the following:

Visit `http://localhost/ci3-blog/` - should show the posts listing (default controller).

Visit `http://localhost/ci3-blog/posts/1` - should show post detail (`(:num)` routes the number to the show method).

---

## 3. URL Segments Explained

CodeIgniter translates segments of a URL directly into controllers, methods, and parameters.

```text
http://localhost/ci3-blog/posts/show/1
                          ^      ^    ^
                          |      |    |
                     controller method parameter
                     (segment 1) (segment 2) (segment 3)
```

Each slash-separated part of the URL after the base URL corresponds to a specific role in CI3's dispatch system. The first segment always maps to a controller class, the second to a method within that class, and the third onward to arguments passed to that method.

In the controller, you can also access segments programmatically. For the URL above, `$this->uri->segment(1)` returns `'posts'`, `$this->uri->segment(2)` returns `'show'`, and `$this->uri->segment(3)` returns `'1'`. This is useful when you need to access URL parameters in a situation where they are not automatically passed as method arguments.

---

## 4. Route Wildcards

You can use wildcards in routes to match dynamic segments like IDs or slugs.

| Wildcard | Matches | Example |
|----------|---------|---------|
| `(:num)` | Numbers only | `posts/(:num)` matches `/posts/5` |
| `(:any)` | Any characters | `posts/(:any)` matches `/posts/hello` |
| `(:segment)` | Any segment | Same as `(:any)` but single segment |

`$1` in the route target references the first wildcard match. If you have two wildcards in a route, `$2` references the second match. For example, `$route['posts/(:num)/comments/(:num)'] = 'comments/show/$1/$2'` would pass both numeric segments to the method.

---

## 5. Fix the Errors in Your Code

Here are common routing issues and how to troubleshoot them.

**Error 1: Route order.**
CI3 checks routes top to bottom. Specific routes (`posts/create`) must be placed before wildcard routes (`posts/(:any)`).

```php
// Wrong: wildcard catches everything before 'create'
$route['posts/(:any)'] = 'posts/show/$1';
$route['posts/create'] = 'posts/create';

// Correct:
$route['posts/create'] = 'posts/create';
$route['posts/(:any)'] = 'posts/show/$1';
```

When CI3 evaluates a URL like `/posts/create`, it goes through the `routes.php` file from top to bottom and uses the first route that matches. If `posts/(:any)` comes first, it will match `/posts/create` before CI3 even gets to the explicit `'posts/create'` rule. Always put your specific, literal routes above your wildcard routes.

**Error 2: No default controller.**
Without a default controller, the root URL will return a 404 error. Ensure it's set in your routes file.

```php
$route['default_controller'] = 'posts';
```

This setting is mandatory if you want `http://localhost/ci3-blog/` to work. CI3 does not have a built-in fallback.

**Error 3: URI dashes mismatch.**
When `translate_uri_dashes` is TRUE, dashes in URLs are converted to underscores for controller and method names. Keep it FALSE unless you explicitly need this behavior.

---

## 6. Exercises

Practice creating different types of routes with these tasks.

**Exercise 1:** Add a route that maps `/about` to `pages/about` and `/contact` to `pages/contact`.

**Exercise 2:** Add a route `$route['blog'] = 'posts/index';` so that `/blog` also shows the posts listing.

**Exercise 3:** Test visiting `/posts/create` and `/posts/5`. Verify the correct controller method is called for each.

---

## 7. Solutions

Here are the correct routing configurations for the exercises.

**Solution for Exercise 1:**

```php
$route['about'] = 'pages/about';
$route['contact'] = 'pages/contact';
```

These are literal routes with no wildcards. When the user visits `/about`, CI3 loads the `About` method on the `Pages` controller. These must be placed above any wildcard routes to avoid conflicts.

**Solution for Exercise 2:**

```php
$route['blog'] = 'posts/index';
```

This creates an alias. Both `/posts` and `/blog` now load the exact same controller method (`Posts::index()`). This is useful when you want to support multiple URL patterns for the same content.

**Solution for Exercise 3:** `/posts/create` calls `Posts::create()`, `/posts/5` calls `Posts::show(5)` via the `(:num)` route.

---

## Next Up - Lesson 5

CI3 URLs follow `controller/method/parameter`. Custom routes in `routes.php` override this. `(:num)` matches numbers, `(:any)` matches anything. Specific routes must come before wildcard routes. `default_controller` sets the home page.

In Lesson 5, you will configure the database connection for MySQL.