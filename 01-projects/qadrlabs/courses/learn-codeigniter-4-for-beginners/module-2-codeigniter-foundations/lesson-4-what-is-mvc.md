In the previous lesson, we created a working entries listing page. But if you look at `app/Config/Routes.php` right now, something feels off: a file that should only contain a URL map is instead packed with logic, preparing data, defining arrays, and deciding what gets displayed. This lesson solves that problem.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the `/entries` page will display exactly the same result in the browser. The difference will not be visible to the user, but the code structure will be significantly better: logic will live in a controller, presentation in a view, and the route file will contain nothing but a clean map.

### What You'll Learn

- What the MVC (Model-View-Controller) architectural pattern is and why it exists
- How to generate a controller using `php spark make:controller`
- How to move logic from a route closure into a controller method
- How to update routes to point to controller methods
- How to verify registered routes using `php spark routes`

### What You'll Need

- The `catatku` project open in VS Code with the development server running
- The `/entries` route and view from Lesson 3

---

## Step 1: Identify the Problem {#step-1-identify-the-problem}

The `/entries` route in `Routes.php` currently contains a closure with data preparation logic. For one route, this is tolerable. But Catatku will eventually need many routes, and piling all logic into `Routes.php` will make it unmanageable.

This is the problem that the **MVC** pattern solves.

---

## Step 2: Create the EntryController {#step-2-create-the-entrycontroller}

Run the following command in your terminal:

```bash
php spark make:controller EntryController
```

Output:

```
File created: APPPATH/Controllers/EntryController.php
```

Open the newly created file at `app/Controllers/EntryController.php`. You will see:

```php
<?php

namespace App\Controllers;

use App\Controllers\BaseController;
use CodeIgniter\HTTP\ResponseInterface;

class EntryController extends BaseController
{
    public function index()
    {
        //
    }
}
```

Update it with the entries listing logic:

```php
<?php

namespace App\Controllers;

use App\Controllers\BaseController;

class EntryController extends BaseController
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
    }
}
```

The `index()` method is a convention in CodeIgniter for the action that lists all resources. The code inside is identical to what we had in the route closure. We simply moved it to a more appropriate location.

---

## Step 3: Update the Route {#step-3-update-the-route}

Now update `app/Config/Routes.php` to point to the controller:

```php
$routes->get('/', 'Home::index');
$routes->get('/entries', 'EntryController::index');
```

The closure is gone. The route now says: "When there is a GET request to `/entries`, call the `index` method on `EntryController`." The file is clean and focused on URL mapping.

---

## Step 4: Verify the Result {#step-4-verify-the-result}

Check that CodeIgniter recognizes the routes:

```bash
php spark routes
```

Open `http://localhost:8080/entries`. The page should look exactly the same as before.

![view entries listing page](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/02-view-entries-page.webp)

---

## What is MVC? {#what-is-mvc}

MVC stands for **Model - View - Controller**. It separates an application into three parts:

**Model** is responsible for data. It communicates with the database to retrieve, store, update, and delete records. We have not created a model yet, but we will in Lesson 5.

**View** is responsible for presentation. It takes data provided by the controller and renders it as HTML. Our `entries/index.php` file is a view.

**Controller** is responsible for application flow. It receives incoming requests, asks the model for data (or prepares it), and passes that data to the appropriate view. Our `EntryController` is a controller.

### The Restaurant Kitchen Analogy {#the-restaurant-kitchen-analogy}

**Model** is the kitchen. This is where raw ingredients (data) are stored, prepared, and processed.

**View** is the plate and the table. This is how the food is presented to the guest.

**Controller** is the waiter. The waiter takes the order from the guest, fetches the food from the kitchen, and serves it at the table.

The waiter does not cook. The kitchen does not interact with guests. Each part has one clear role.

---

## The Complete MVC Flow {#the-complete-mvc-flow}

```
Browser: GET /entries
              │
              ▼
        app/Config/Routes.php
        $routes->get('/entries', 'EntryController::index')
              │
              ▼
        EntryController::index()
        $entries = [...];
        return view('entries/index', ['entries' => $entries])
              │
              ▼
        app/Views/entries/index.php
        <?php foreach ($entries as $entry): ?> ...
              │
              ▼
        HTML sent to the browser
```

---

## Conclusion {#conclusion}

This lesson made a change that is invisible to the user but transformative for the developer. Here are the key takeaways:

- **MVC** separates your application into three parts: data (Model), presentation (View), and flow control (Controller).
- `php spark make:controller EntryController` generates a new controller file at `app/Controllers/EntryController.php`.
- Controller methods like `index()` contain the logic previously inside route closures.
- Routes point to controllers using `'ControllerName::methodName'` string syntax.
- `php spark routes` displays all registered routes.
- The **request flow** is: Browser sends a request, the route directs it to a controller, the controller prepares data and sends it to a view, the view renders HTML.

In the next lesson, we will replace the hardcoded array with real data by creating a database table using **migrations**.