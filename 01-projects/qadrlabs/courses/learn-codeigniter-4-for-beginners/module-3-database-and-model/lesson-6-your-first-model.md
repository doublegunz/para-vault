In the previous lesson, we created the `entries` table in the database. But a table sitting in the database does not mean much if we do not know how to talk to it from our PHP code. This lesson answers that question using **CodeIgniter Models**.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the controller will no longer use a hardcoded array. Instead, it will query the database using the EntryModel. You will also have seed data to see real entries in the browser.

### What You'll Learn

- What CodeIgniter Models are and how they simplify database interaction
- How to configure a model with `$allowedFields` for mass assignment protection
- How to update the controller to fetch real data
- How to update the view to work with model result objects
- How to insert seed data using CodeIgniter's built-in Seeder

### What You'll Need

- The `entries` table created in the database from Lesson 5

---

## Step 1: Create the EntryModel {#step-1-create-the-entrymodel}

```bash
php spark make:model EntryModel
```

Open `app/Models/EntryModel.php` and configure it:

```php
<?php

namespace App\Models;

use CodeIgniter\Model;

class EntryModel extends Model
{
    protected $table            = 'entries';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'object';
    protected $allowedFields    = ['user_id', 'title', 'content'];
    protected $useTimestamps    = true;
    protected $createdField     = 'created_at';
    protected $updatedField     = 'updated_at';
}
```

Let us understand each property:

`$table = 'entries'` tells the model which database table to use. Unlike some frameworks, CodeIgniter requires you to specify this explicitly.

`$returnType = 'object'` means query results are returned as objects, so you access properties with `$entry->title` instead of `$entry['title']`.

`$allowedFields = ['user_id', 'title', 'content']` is the mass assignment protection. Only these columns can be set through `insert()` or `update()` calls. This prevents malicious users from injecting unexpected fields.

`$useTimestamps = true` tells the model to automatically fill `created_at` and `updated_at` columns when records are created or modified.

---

## Step 2: Create the UserModel {#step-2-create-the-usermodel}

We will also need a UserModel for authentication later:

```bash
php spark make:model UserModel
```

Configure `app/Models/UserModel.php`:

```php
<?php

namespace App\Models;

use CodeIgniter\Model;

class UserModel extends Model
{
    protected $table            = 'users';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'object';
    protected $allowedFields    = ['name', 'email', 'password'];
    protected $useTimestamps    = true;
}
```

---

## Step 3: Update the Controller {#step-3-update-the-controller}

Open `app/Controllers/EntryController.php` and replace the hardcoded array:

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
}
```

`model(EntryModel::class)` loads the model using CodeIgniter's service locator. `orderBy('created_at', 'DESC')` sorts results newest first. `findAll()` retrieves all records as a collection of objects.

We are fetching all entries from all users for now. Once we build authentication in Lesson 11, we will update this to filter by the authenticated user.

---

## Step 4: Update the View {#step-4-update-the-view}

The data is now objects, not arrays. Update `app/Views/entries/index.php`:

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

        <?php if (empty($entries)): ?>
            <div class="text-center py-16 text-gray-400">
                <p class="text-5xl mb-4">📓</p>
                <p class="font-medium text-gray-500">No entries yet</p>
                <p class="text-sm mt-1">Start writing your first entry!</p>
            </div>
        <?php else: ?>
            <?php foreach ($entries as $entry): ?>
                <div class="bg-white rounded-xl border border-gray-200 p-5 mb-4">
                    <h3 class="font-semibold text-gray-900 mb-1">
                        <?= esc($entry->title) ?>
                    </h3>
                    <p class="text-xs text-gray-400 mb-3">
                        <?= date('d F Y', strtotime($entry->created_at)) ?>
                    </p>
                    <p class="text-sm text-gray-600 line-clamp-2">
                        <?= esc($entry->content) ?>
                    </p>
                </div>
            <?php endforeach; ?>
        <?php endif; ?>

    </div>

</body>
</html>
```

Key changes: `$entry->title` uses arrow notation for objects. `date('d F Y', strtotime($entry->created_at))` formats the timestamp. `if (empty($entries))` handles the empty state.

---

## Step 5: Insert Seed Data {#step-5-insert-seed-data}

The database is currently empty, so visiting `/entries` will show the "No entries yet" empty state. Let us insert some test data using CodeIgniter's built-in Seeder system.

First, generate a seeder file:

```bash
php spark make:seeder TestDataSeeder
```

Open the generated file at `app/Database/Seeds/TestDataSeeder.php` and update it:

```php
<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;
use App\Models\UserModel;
use App\Models\EntryModel;

class TestDataSeeder extends Seeder
{
    public function run()
    {
        // Create a test user
        $userModel = model(UserModel::class);
        $userModel->insert([
            'name'     => 'Budi',
            'email'    => 'budi@example.com',
            'password' => password_hash('password123', PASSWORD_DEFAULT),
        ]);

        $userId = $userModel->getInsertID();

        // Create test entries
        $entryModel = model(EntryModel::class);

        $entryModel->insert([
            'user_id' => $userId,
            'title'   => 'My first entry',
            'content' => 'This is my very first journal entry. Feels great to get started!',
        ]);

        $entryModel->insert([
            'user_id' => $userId,
            'title'   => 'Learning CodeIgniter',
            'content' => 'Today I learned about CodeIgniter models. Interacting with the database is clean and straightforward.',
        ]);

        $entryModel->insert([
            'user_id' => $userId,
            'title'   => 'Weekend plans',
            'content' => 'Planning to finish the CodeIgniter course this weekend and maybe start a side project.',
        ]);
    }
}
```

Now run the seeder:

```bash
php spark db:seed TestDataSeeder
```

Output:

```
Seeded: TestDataSeeder
```

The seeder creates one user (Budi) and three journal entries. This is the proper CodeIgniter way to insert test data. Seeders are reusable, shareable with your team, and can be run anytime you need to reset your test data.

If you ever need to start fresh, you can roll back all migrations and re-run them along with the seeder:

```bash
php spark migrate:rollback
php spark migrate
php spark db:seed TestDataSeeder
```

---

## Step 6: View the Result {#step-6-view-the-result}

Open `http://localhost:8080/entries`. You should see the three entries from the database.

![view entries from database](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/03-view-entries-from-database.webp)

---

## What is Mass Assignment Protection? {#what-is-mass-assignment-protection}

`$allowedFields` lists which columns can be set through `insert()` or `update()`. If a malicious user tries to inject an extra field like `is_admin=1`, the model silently ignores it. Only the columns listed in `$allowedFields` are accepted.

This is why we include `user_id` in `$allowedFields` for EntryModel but will always set it from the server-side session, never from user input.

---

## Conclusion {#conclusion}

Here are the key takeaways:

- CodeIgniter **Models** map to database tables and provide methods like `findAll()`, `find()`, `insert()`, `update()`, and `delete()`.
- `$allowedFields` prevents mass assignment attacks by listing which columns can be filled.
- `$useTimestamps = true` automatically manages `created_at` and `updated_at` columns.
- `$returnType = 'object'` means results use arrow notation (`$entry->title`).
- `model(ModelClass::class)` loads a model using CodeIgniter's service locator.
- `orderBy('created_at', 'DESC')->findAll()` fetches all records sorted newest first.
- `esc()` escapes output for XSS protection. `date()` with `strtotime()` formats timestamps.
- **Seeders** (`php spark make:seeder`, `php spark db:seed`) are the proper way to insert test data in CodeIgniter. They are reusable and can be shared with your team.

In the next lesson, we will build a reusable **view layout** and the entry detail page.