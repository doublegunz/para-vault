The previous lessons brought us far. The model is connected to the database and the controller fetches real data. But the views still feel raw: no consistent navigation, and every new page would require duplicating the HTML structure. This lesson fixes that.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the application will have two fully working pages: an entries listing and an entry detail page, both sharing the same layout.

### What You'll Learn

- How to create a reusable layout using CodeIgniter's view layout system (`extend`, `section`, `renderSection`)
- How to extract repeated UI into view partials
- How to build an entry detail page with URL segment parameters
- How to protect a page so only the entry owner can access it

### What You'll Need

- The controller connected to the database and seed data from Lesson 6

---

## Step 1: Create the Main Layout {#step-1-create-the-main-layout}

CodeIgniter has a built-in view layout system. Create `app/Views/layouts/main.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $this->renderSection('title') ?></title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50 min-h-screen">

    <!-- Navigation -->
    <nav class="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div class="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
            <a href="/entries" class="text-xl font-bold text-gray-900 hover:text-gray-700">
                Catatku 📓
            </a>
            <div class="flex items-center gap-4">
                <?php if (session()->get('user_id')): ?>
                    <span class="text-sm text-gray-500"><?= esc(session()->get('user_name')) ?></span>
                    <form method="POST" action="/logout">
                        <?= csrf_field() ?>
                        <button type="submit" class="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                            Logout
                        </button>
                    </form>
                <?php else: ?>
                    <a href="/login" class="text-sm text-gray-600 hover:text-gray-900">Log In</a>
                    <a href="/register" class="text-sm bg-gray-900 text-white px-3 py-1.5 rounded-lg hover:bg-gray-700 transition-colors">
                        Register
                    </a>
                <?php endif; ?>
            </div>
        </div>
    </nav>

    <!-- Page content -->
    <main class="max-w-2xl mx-auto px-4 py-8">
        <?php if (session()->getFlashdata('success')): ?>
            <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-800 text-sm rounded-xl">
                <?= esc(session()->getFlashdata('success')) ?>
            </div>
        <?php endif; ?>

        <?= $this->renderSection('content') ?>
    </main>

</body>
</html>
```

`$this->renderSection('title')` and `$this->renderSection('content')` are placeholders that child views fill with their own content. `session()->getFlashdata('success')` displays one-time flash messages.

---

## Step 2: Create the Entry Card Partial {#step-2-create-the-entry-card-partial}

Create `app/Views/partials/entry_card.php`:

```html
<div class="bg-white rounded-xl border border-gray-200 p-5 hover:border-gray-300 transition-colors">
    <div class="flex items-start justify-between gap-3 mb-3">
        <a href="/entries/<?= esc($entry->id) ?>" class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
            <?= esc($entry->title) ?>
        </a>
        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">
            <?= date('d M Y', strtotime($entry->created_at)) ?>
        </span>
    </div>
    <p class="text-sm text-gray-500 line-clamp-2 mb-4"><?= esc($entry->content) ?></p>
    <div class="flex items-center gap-3 pt-3 border-t border-gray-100">
        <a href="/entries/<?= esc($entry->id) ?>" class="text-xs text-blue-600 hover:text-blue-800">Read</a>
        <a href="/entries/<?= esc($entry->id) ?>/edit" class="text-xs text-gray-500 hover:text-gray-800">Edit</a>
        <form method="POST" action="/entries/<?= esc($entry->id) ?>/delete" onsubmit="return confirm('Delete this entry?')" class="ml-auto">
            <?= csrf_field() ?>
            <button type="submit" class="text-xs text-red-400 hover:text-red-600">Delete</button>
        </form>
    </div>
</div>
```

In CodeIgniter, view partials are regular PHP files loaded with `view()`. Unlike Blade components, they share the parent view's scope when included, but we will pass data explicitly for clarity.

---

## Step 3: Update the Entries Listing View {#step-3-update-the-entries-listing-view}

Replace `app/Views/entries/index.php`:

```php
<?= $this->extend('layouts/main') ?>

<?= $this->section('title') ?>My Entries — Catatku<?= $this->endSection() ?>

<?= $this->section('content') ?>

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
        <a href="/entries/create" class="bg-gray-900 text-white text-sm px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">
            + Write New Entry
        </a>
    </div>

    <div class="space-y-4">
        <?php if (empty($entries)): ?>
            <div class="text-center py-16">
                <p class="text-5xl mb-4">📓</p>
                <p class="font-medium text-gray-600">No entries yet</p>
                <p class="text-sm text-gray-400 mt-1">Start writing your first entry!</p>
                <a href="/entries/create" class="inline-block mt-4 text-sm text-blue-600 hover:underline">Write now →</a>
            </div>
        <?php else: ?>
            <?php foreach ($entries as $entry): ?>
                <?= view('partials/entry_card', ['entry' => $entry]) ?>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>

<?= $this->endSection() ?>
```

`$this->extend('layouts/main')` tells CodeIgniter to wrap this view inside the layout. `$this->section('content')` defines what goes into the layout's `renderSection('content')` placeholder. `view('partials/entry_card', ['entry' => $entry])` loads the partial and passes the entry data to it.

---

## Step 4: Add the Entry Detail Page {#step-4-add-the-entry-detail-page}

Add the `show()` method to `EntryController`:

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

Unlike some frameworks that have automatic model binding, CodeIgniter passes URL segments as method parameters. `$entryModel->find($id)` looks up the record. If not found, we throw a 404. If the user does not own the entry, we return a 403.

> **Note:** Since the authentication system is not built yet, unauthenticated visitors who access an entry detail URL will see a 403 error (because `session()->get('user_id')` returns `null`). In Lesson 8, we will add a Filter that redirects guests to the login page instead.

Add the route in `app/Config/Routes.php`:

```php
$routes->get('/', 'Home::index');
$routes->get('/entries', 'EntryController::index');
$routes->get('/entries/(:num)', 'EntryController::show/$1');
```

`(:num)` is a route placeholder that only matches numeric values. The `$1` passes the matched value as the first parameter to the `show()` method.

Create `app/Views/entries/show.php`:

```php
<?= $this->extend('layouts/main') ?>

<?= $this->section('title') ?><?= esc($entry->title) ?> — Catatku<?= $this->endSection() ?>

<?= $this->section('content') ?>

    <div class="mb-6">
        <a href="/entries" class="text-sm text-gray-400 hover:text-gray-700">← Back to list</a>
    </div>

    <article class="bg-white rounded-xl border border-gray-200 p-6">
        <div class="mb-6">
            <h1 class="text-2xl font-bold text-gray-900 mb-2"><?= esc($entry->title) ?></h1>
            <p class="text-sm text-gray-400">
                Written on <?= date('d F Y', strtotime($entry->created_at)) ?>
                <?php if ($entry->updated_at !== $entry->created_at): ?>
                    · Updated <?= date('d F Y', strtotime($entry->updated_at)) ?>
                <?php endif; ?>
            </p>
        </div>
        <div class="prose prose-gray max-w-none text-gray-700 leading-relaxed whitespace-pre-line">
            <?= esc($entry->content) ?>
        </div>
    </article>

    <div class="flex items-center gap-3 mt-4">
        <a href="/entries/<?= esc($entry->id) ?>/edit" class="text-sm bg-gray-900 text-white px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">Edit Entry</a>
        <form method="POST" action="/entries/<?= esc($entry->id) ?>/delete" onsubmit="return confirm('Delete this entry?')">
            <?= csrf_field() ?>
            <button type="submit" class="text-sm text-red-500 hover:text-red-700 transition-colors">Delete</button>
        </form>
    </div>

<?= $this->endSection() ?>
```

---

## Step 5: View the Result {#step-5-view-the-result}

Open `http://localhost:8080/entries`. 

![View entries list page with new layout](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/04-view-entries-page-with-new-layout.webp)

Click "Read" on any entry card to visit the detail page, but Since we haven't logged in yet, clicking it won't display the entry details page.  

---

## How CodeIgniter's Layout System Works {#how-codeigniters-layout-system-works}

CodeIgniter's layout system uses three methods:

`$this->extend('layouts/main')` declares which layout file to use as the wrapper. This must be the first line in a child view.

`$this->section('name')` starts a named content block. Everything between `section()` and `endSection()` gets captured.

`$this->renderSection('name')` in the layout file outputs the captured content from the child view at that exact position.

This is functionally equivalent to Blade's `@extends`/`@section`/`@yield` or Twig's `extends`/`block` systems. The child view defines blocks of content, and the layout decides where to place them.

---

## Conclusion {#conclusion}

Here are the key takeaways:

- CodeIgniter's **layout system** (`extend`, `section`, `renderSection`) lets you define a wrapper template once and reuse it across all pages.
- **View partials** are regular PHP files loaded with `view('path', $data)` to extract repeated UI elements.
- `$routes->get('/entries/(:num)', 'Controller::method/$1')` defines a route with a numeric parameter.
- `$model->find($id)` retrieves a single record by primary key. Check for `null` to handle 404 cases.
- Ownership checks (`$entry->user_id !== session user_id`) prevent unauthorized access. This will improve with Filters in the next lesson.
- `session()->getFlashdata('success')` displays one-time messages stored in the session.
- `csrf_field()` generates a hidden CSRF token field for forms. The token is rendered now, but CodeIgniter does not validate it yet. We will turn on real CSRF protection in Lesson 8 by enabling the `csrf` filter.

In the next lesson, we will build the form for creating new entries with validation and secure saving.