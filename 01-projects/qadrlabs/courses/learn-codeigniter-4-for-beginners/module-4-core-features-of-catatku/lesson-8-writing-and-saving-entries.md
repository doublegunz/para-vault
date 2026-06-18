The previous lesson produced visible, structured pages. But every entry was created through a Seeder. There is no way for a user to write a new entry from inside the application. This lesson closes that gap.

## Overview {#overview}

### What You'll Build

By the end of this lesson, a logged-in user will be able to open a form, write a journal entry, and see it appear in the listing immediately.

### What You'll Learn

- The two-step form flow: GET to display, POST to process
- How to validate input using CodeIgniter's validation library
- How `csrf_field()` protects forms from CSRF attacks
- How `old()` restores input after validation failures
- How to save data securely with the user's ID from the session
- How to create an Auth Filter to protect routes

### What You'll Need

- The layout, partial, and views from Lesson 7
- The test user created in Lesson 6

---

## Step 1: Create the Auth Filter {#step-1-create-the-auth-filter}

Before building the form, we need a way to protect routes. CodeIgniter uses **Filters** (similar to middleware). Create `app/Filters/AuthFilter.php`:

```php
<?php

namespace App\Filters;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Filters\FilterInterface;

class AuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        if (!session()->get('user_id')) {
            return redirect()->to('/login');
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        //
    }
}
```

Register it in `app/Config/Filters.php`. Find the `$aliases` array and add:

```php
public array $aliases = [
    // ... existing aliases
    'auth'  => \App\Filters\AuthFilter::class,
];
```

### Enable CSRF Protection {#enable-csrf-protection}

Our forms already include `csrf_field()` (you added it in Lesson 7, and the create form below uses it too). But generating the token is only half the job. By default, CodeIgniter does **not** validate that token, so it provides no real protection yet. We need to turn on the `csrf` filter.

Still inside `app/Config/Filters.php`, find the `$globals` array. The `csrf` filter is there but commented out. Uncomment it so it runs before every request:

```php
public array $globals = [
    'before' => [
        // 'honeypot',
        'csrf',
        // 'invalidchars',
    ],
    'after' => [
        // 'honeypot',
        // 'secureheaders',
    ],
];
```

With this enabled, CodeIgniter checks the CSRF token on every request that changes data (POST, PUT, PATCH, DELETE). If the token is missing or wrong, the request is rejected (in `development` you will see a 403 error page). Read-only requests like GET are not affected, so links and pages such as `/dev-login` keep working.

A few details worth knowing (configured in `app/Config/Security.php`):

- The token field is named `csrf_test_name`, which is exactly what `csrf_field()` renders.
- `$regenerate = true` means a fresh token is issued on every request, which is more secure. The browser handles this automatically because each page reload prints a new token.

From now on, every form in Catatku is genuinely protected against CSRF, not just decorated with a hidden field.

---

## Step 2: Add the Routes {#step-2-add-the-routes}

Open `app/Config/Routes.php`:

```php
$routes->get('/', 'Home::index');
$routes->get('/entries', 'EntryController::index');
$routes->get('/entries/(:num)', 'EntryController::show/$1');
```

Next, we define some new routes for storing new data and for testing.
```php
$routes->get('/', 'Home::index');
$routes->get('/entries', 'EntryController::index');

$routes->group('', ['filter' => 'auth'], static function ($routes) {
    $routes->get('/entries/create', 'EntryController::create');
    $routes->post('/entries', 'EntryController::store');
    $routes->get('/entries/(:num)', 'EntryController::show/$1');
});

// ONLY FOR DEVELOPMENT - delete after lesson 10
$routes->get('/dev-login', static function () {
    session()->set(['user_id' => 1, 'user_name' => 'Budi']);
    return redirect()->to('/entries');
});
```

`['filter' => 'auth']` applies the AuthFilter to all routes in the group. In addition to implementing the filter, we also added a new route: `/dev-login` route. The `/dev-login` route sets session data for testing. We will remove it in Lesson 10.

---

## Step 3: Add Controller Methods {#step-3-add-controller-methods}

Update `app/Controllers/EntryController.php` by adding two new methods: `create()` and `store()`.

```php
<?php

namespace App\Controllers;

use App\Models\EntryModel;

class EntryController extends BaseController
{
    public function index()
    {
        $entryModel = model(EntryModel::class);
        $entries = $entryModel->orderBy('created_at', 'DESC')->findAll();

        return view('entries/index', ['entries' => $entries]);
    }

    public function create()
    {
        return view('entries/create');
    }

    public function store()
    {
        $rules = [
            'title'   => 'required|max_length[255]',
            'content' => 'required',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $entryModel = model(EntryModel::class);
        $entryModel->insert([
            'user_id' => session()->get('user_id'),
            'title'   => $this->request->getPost('title'),
            'content' => $this->request->getPost('content'),
        ]);

        return redirect()->to('/entries')->with('success', 'Entry saved successfully.');
    }

    public function show($id)
    {
        $entryModel = model(EntryModel::class);
        $entry = $entryModel->find($id);

        if (!$entry) {
            throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound();
        }

        if ( (int) $entry->user_id !== (int) session()->get('user_id')) {
            return $this->response->setStatusCode(403, 'Forbidden');
        }

        return view('entries/show', ['entry' => $entry]);
    }
}
```

`$this->validate($rules)` checks the input. If it fails, `redirect()->back()->withInput()` sends the user back with their input preserved. `with('errors', ...)` flashes the error messages to the session.

`session()->get('user_id')` retrieves the authenticated user's ID from the session. This is always set server-side, never from form input.

---

## Step 4: Create the Form View {#step-4-create-the-form-view}

Create `app/Views/entries/create.php`:

```php
<?= $this->extend('layouts/main') ?>

<?= $this->section('title') ?>Write Entry — Catatku<?= $this->endSection() ?>

<?= $this->section('content') ?>

    <div class="mb-6">
        <a href="/entries" class="text-sm text-gray-400 hover:text-gray-700">← Back to list</a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Write New Entry</h2>

    <?php $errors = session()->getFlashdata('errors') ?? []; ?>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="/entries">
            <?= csrf_field() ?>

            <!-- Title -->
            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" id="title" name="title"
                    value="<?= old('title') ?>"
                    placeholder="Entry title..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent <?= isset($errors['title']) ? 'border-red-400 bg-red-50' : 'border-gray-300' ?>"
                    autofocus>
                <?php if (isset($errors['title'])): ?>
                    <p class="text-xs text-red-500 mt-1"><?= esc($errors['title']) ?></p>
                <?php endif; ?>
            </div>

            <!-- Content -->
            <div class="mb-6">
                <label for="content" class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea id="content" name="content" rows="12"
                    placeholder="Write your entry here..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y <?= isset($errors['content']) ? 'border-red-400 bg-red-50' : 'border-gray-300' ?>"
                ><?= old('content') ?></textarea>
                <?php if (isset($errors['content'])): ?>
                    <p class="text-xs text-red-500 mt-1"><?= esc($errors['content']) ?></p>
                <?php endif; ?>
            </div>

            <!-- Buttons -->
            <div class="flex items-center justify-between">
                <a href="/entries" class="text-sm text-gray-500 hover:text-gray-900">Cancel</a>
                <button type="submit" class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg hover:bg-gray-700 transition-colors">
                    Save Entry
                </button>
            </div>
        </form>
    </div>

<?= $this->endSection() ?>
```

`csrf_field()` generates a hidden CSRF token, and because we enabled the `csrf` filter in Step 1, that token is now actually validated on the server when the form is submitted, not just printed into the HTML. `old('title')` retrieves the previously submitted value after a validation failure. The error display pattern checks `$errors['field']` from the flashed session data.

---

## Step 5: Test the Create Flow {#step-5-test-the-create-flow}

1. Visit `http://localhost:8080/dev-login` to log in as Budi.
![login with dev-login route](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/05-login-with-dev-login-route.webp)

2. Go to `http://localhost:8080/entries/create`.
![view create new entry form](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/06-view-create-new-entry-form.webp)

3. Submit with empty fields to see validation errors.
![test form validation](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/07-test-form-validation.webp)

4. Fill in valid data and click "Save Entry" to see it in the listing.

![fill in valid data](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/08-test-fill-form-and-save-new-entry.webp)

![new entries saved](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/09-new-entry-saved.webp)

---

## Conclusion {#conclusion}

Here are the key takeaways:

- **Filters** are CodeIgniter's equivalent of middleware. The `AuthFilter` checks for a session `user_id` and redirects to login if missing.
- `$routes->group('', ['filter' => 'auth'], ...)` applies a filter to all routes in the group.
- `$this->validate($rules)` checks input against rules like `required` and `max_length[255]`.
- `redirect()->back()->withInput()` preserves form input after validation failure.
- `csrf_field()` generates a CSRF token, but real protection only kicks in once you enable the `csrf` filter in `app/Config/Filters.php` (`$globals['before']`). With it on, CodeIgniter rejects any POST that lacks a valid token.
- `old('field')` retrieves preserved input from the session.
- `session()->get('user_id')` provides the authenticated user's ID for secure data insertion.

In the next lesson, we will complete CRUD with edit and delete operations.