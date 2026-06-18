The previous lesson closed half of the CRUD cycle. Users can now write new entries and see them in the listing. But entries cannot be modified or removed. This lesson completes the other half.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the full CRUD cycle will be complete: create, read, update, and delete.

### What You'll Learn

- How to build an edit form with pre-filled data
- How `old('field', $default)` works with a default value for edit forms
- How to implement update and delete operations
- RESTful-style routing conventions in CodeIgniter
- Why every mutating operation needs an ownership check

### What You'll Need

- Logged in via `/dev-login`
- At least one entry to edit and delete

---

## Step 1: Add the Routes {#step-1-add-the-routes}

Open `app/Config/Routes.php`:
```php
$routes->group('', ['filter' => 'auth'], static function ($routes) {
    $routes->get('/entries/create', 'EntryController::create');
    $routes->post('/entries', 'EntryController::store');
    $routes->get('/entries/(:num)', 'EntryController::show/$1');
});
```

Next, we define three new routes: `edit()`, `update()`, and `delete()`.
```php
$routes->group('', ['filter' => 'auth'], static function ($routes) {
    $routes->get('/entries/create', 'EntryController::create');
    $routes->post('/entries', 'EntryController::store');
    $routes->get('/entries/(:num)', 'EntryController::show/$1');
    $routes->get('/entries/(:num)/edit', 'EntryController::edit/$1'); // add this line of code
    $routes->post('/entries/(:num)/update', 'EntryController::update/$1'); // add this line of code
    $routes->post('/entries/(:num)/delete', 'EntryController::destroy/$1'); // add this line of code
});
```

As a result, the entire route looks like the following line of code:

```php
$routes->get('/', 'Home::index');
$routes->get('/entries', 'EntryController::index');

$routes->group('', ['filter' => 'auth'], static function ($routes) {
    $routes->get('/entries/create', 'EntryController::create');
    $routes->post('/entries', 'EntryController::store');
    $routes->get('/entries/(:num)', 'EntryController::show/$1');
    $routes->get('/entries/(:num)/edit', 'EntryController::edit/$1'); // add this line of code
    $routes->post('/entries/(:num)/update', 'EntryController::update/$1'); // add this line of code
    $routes->post('/entries/(:num)/delete', 'EntryController::destroy/$1'); // add this line of code
});

// ONLY FOR DEVELOPMENT - delete after lesson 10
$routes->get('/dev-login', static function () {
    session()->set(['user_id' => 1, 'user_name' => 'Budi']);
    return redirect()->to('/entries');
});
```

For update and delete, we use POST routes with descriptive URL segments (`/update` and `/delete`) rather than PUT and DELETE HTTP methods. This is simpler for beginners because HTML forms only support GET and POST natively. CodeIgniter does support method spoofing with a hidden `_method` field if you prefer RESTful conventions, but the explicit URL approach is more straightforward.

---

## Step 2: Add Controller Methods {#step-2-add-controller-methods}
Before adding a new method to the controller, we’ll try to extract the validation logic from the `show()` method so we don’t have to repeat the same lines of code in the `edit()`, `update()`, and `destroy()` methods.

Reopen `EntryController`, then locate the `show()` method.
```php
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
```

### Create a ForbiddenException for entries that are not yours {#create-a-forbiddenexception}

In Lesson 7, `show()` returned a 403 with `$this->response->setStatusCode(403, 'Forbidden')`. That works when the check lives directly inside the action. But we are about to move the check into a shared helper, and a helper cannot stop the request by returning a response. It has to `throw`.

For the "entry does not exist" case we already throw `PageNotFoundException`, which CodeIgniter turns into a 404. For the "entry exists but is not yours" case we want a **403 Forbidden** (the user is logged in, they are just not allowed to touch this entry). CodeIgniter only maps an exception to an HTTP status code when that exception implements `HTTPExceptionInterface`, and there is no built-in 403 exception. So we create a small one of our own, mirroring how `PageNotFoundException` produces a 404.

Create `app/Exceptions/ForbiddenException.php`:

```php
<?php

namespace App\Exceptions;

use CodeIgniter\Exceptions\HTTPExceptionInterface;
use RuntimeException;

class ForbiddenException extends RuntimeException implements HTTPExceptionInterface
{
    public function __construct(string $message = 'You are not allowed to access this entry.')
    {
        parent::__construct($message, 403);
    }
}
```

The `403` passed to `parent::__construct()` is the exception code, and because the class implements `HTTPExceptionInterface`, CodeIgniter uses it as the HTTP status code.

To show a clean page instead of the debug screen when this happens, add an error view at `app/Views/errors/html/error_403.php`:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>403 Forbidden</title>
    <style>
        body { height: 100%; background: #fafafa; font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; color: #777; font-weight: 300; }
        h1 { font-weight: lighter; font-size: 3rem; margin: 0; color: #222; }
        .wrap { max-width: 1024px; margin: 5rem auto; padding: 2rem; background: #fff; text-align: center; border: 1px solid #efefef; border-radius: 0.5rem; }
        p { margin-top: 1.5rem; }
    </style>
</head>
<body>
<div class="wrap">
    <h1>403</h1>
    <p>
        <?php if (ENVIRONMENT !== 'production') : ?>
            <?= nl2br(esc($message)) ?>
        <?php else : ?>
            You are not allowed to view this page.
        <?php endif; ?>
    </p>
</div>
</body>
</html>
```

CodeIgniter automatically uses `error_403.php` for any exception whose status code is 403.

Next, we'll extract the ownership check into a new method, `findOwnedEntry()`, and then modify the `show()` method.
```php
    public function show($id)
    {
        $entry = $this->findOwnedEntry($id);
        return view('entries/show', ['entry' => $entry]);
    }

    private function findOwnedEntry($id)
    {
        $entryModel = model(EntryModel::class);
        $entry = $entryModel->find($id);

        if (!$entry) {
            throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound();
        }

        if ( (int) $entry->user_id !== (int) session()->get('user_id')) {
            throw new \App\Exceptions\ForbiddenException();
        }

        return $entry;
    }
```
We extracted the ownership check into a `findOwnedEntry()` private method to avoid repeating the same code in every method. It returns the entry when everything is fine, throws a **404** (`PageNotFoundException`) when the entry does not exist, and throws a **403** (`ForbiddenException`) when the entry belongs to someone else. This keeps the same 403 behavior we wrote in Lesson 7, now in one reusable place. `$entryModel->update($id, [...])` updates the record. `$entryModel->delete($id)` removes it permanently.

Next we add `edit()`, `update()`, and `destroy()` to `EntryController`:

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
        $entry = $this->findOwnedEntry($id);
        return view('entries/show', ['entry' => $entry]);
    }

    public function edit($id)
    {
        $entry = $this->findOwnedEntry($id);
        return view('entries/edit', ['entry' => $entry]);
    }

    public function update($id)
    {
        $entry = $this->findOwnedEntry($id);

        $rules = [
            'title'   => 'required|max_length[255]',
            'content' => 'required',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $entryModel = model(EntryModel::class);
        $entryModel->update($id, [
            'title'   => $this->request->getPost('title'),
            'content' => $this->request->getPost('content'),
        ]);

        return redirect()->to('/entries/' . $id)->with('success', 'Entry updated successfully.');
    }

    public function destroy($id)
    {
        $entry = $this->findOwnedEntry($id);

        $entryModel = model(EntryModel::class);
        $entryModel->delete($id);

        return redirect()->to('/entries')->with('success', 'Entry deleted successfully.');
    }

    /**
     * Find an entry and verify ownership. Returns 404 if not found, 403 if not owned.
     */
    private function findOwnedEntry($id)
    {
        $entryModel = model(EntryModel::class);
        $entry = $entryModel->find($id);

        if (!$entry) {
            throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound();
        }

        if ( (int) $entry->user_id !== (int) session()->get('user_id')) {
            throw new \App\Exceptions\ForbiddenException();
        }

        return $entry;
    }
}
```



> **Note about `index()`:** The `index()` method currently fetches all entries from all users. This will be updated in Lesson 11 to show only the authenticated user's entries.

---

## Step 3: Create the Edit Form View {#step-3-create-the-edit-form-view}

Create `app/Views/entries/edit.php`:

```php
<?= $this->extend('layouts/main') ?>

<?= $this->section('title') ?>Edit: <?= esc($entry->title) ?> — Catatku<?= $this->endSection() ?>

<?= $this->section('content') ?>

    <div class="mb-6">
        <a href="/entries/<?= esc($entry->id) ?>" class="text-sm text-gray-400 hover:text-gray-700">← Back to entry</a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Edit Entry</h2>

    <?php $errors = session()->getFlashdata('errors') ?? []; ?>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="/entries/<?= esc($entry->id) ?>/update">
            <?= csrf_field() ?>

            <!-- Title -->
            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" id="title" name="title"
                    value="<?= old('title', $entry->title) ?>"
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
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y <?= isset($errors['content']) ? 'border-red-400 bg-red-50' : 'border-gray-300' ?>"
                ><?= old('content', $entry->content) ?></textarea>
                <?php if (isset($errors['content'])): ?>
                    <p class="text-xs text-red-500 mt-1"><?= esc($errors['content']) ?></p>
                <?php endif; ?>
            </div>

            <!-- Buttons -->
            <div class="flex items-center justify-between">
                <a href="/entries/<?= esc($entry->id) ?>" class="text-sm text-gray-500 hover:text-gray-900">Cancel</a>
                <button type="submit" class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg hover:bg-gray-700 transition-colors">
                    Save Changes
                </button>
            </div>
        </form>
    </div>

<?= $this->endSection() ?>
```

`old('title', $entry->title)` works the same as in the Laravel course: on first load it shows the database value; after a failed validation it shows what the user just typed. Also update the entry card partial (`app/Views/partials/entry_card.php`) delete form action to use `/entries/<?= esc($entry->id) ?>/delete`.

---

## Step 4: Verify and Test {#step-4-verify-and-test}
Now let’s try clicking the edit button on one of the records. Once we click it, the edit form page will open, displaying the record’s data.

![view edit form](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/10-view-edit-form.webp)


Next, let’s clear the content field to test the form validation, then click the Save Changes button.

![test form validation](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/11-test-form-validation.webp)

As you can see, the error message `The content field is required` indicates that the form validation is working properly.

Next, let’s try updating the form fields, then click the “Save Changes” button again.

![test fill data for update](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/12-test-edit-data.webp)

After clicking the button, the entry is successfully updated, and the entry details page appears with a success notification.

![data updated](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/13-entry-updated.webp)

Next, go back to the entries list page and click the delete link on one of the entries. A confirmation popup will appear before the entry is deleted.

![test delete data](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/14-test-delete-data.webp)

Click OK, and a notification will appear stating that the data has been successfully deleted.

![entry deleted](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/15-entry-deleted.webp)

---

## Conclusion {#conclusion}

The CRUD cycle is now complete. Here are the key takeaways:

- CodeIgniter supports **POST routes with descriptive URLs** (`/entries/1/update`, `/entries/1/delete`) as a beginner-friendly alternative to PUT/DELETE method spoofing.
- `old('field', $default)` with a **second argument** is essential for edit forms.
- `$model->update($id, $data)` modifies an existing record. `$model->delete($id)` removes it permanently.
- Extract repeated logic into **private helper methods** like `findOwnedEntry()` to keep controller methods clean.
- Every method that operates on a specific entry needs an **ownership check** to prevent unauthorized access. `findOwnedEntry()` centralizes it: a missing entry returns **404**, and an entry that belongs to someone else returns **403** through the custom `ForbiddenException`.
- The `index()` method will be updated in Lesson 11 to scope entries to the authenticated user.

In the next two lessons, we will build the real authentication system and remove the `/dev-login` shortcut.