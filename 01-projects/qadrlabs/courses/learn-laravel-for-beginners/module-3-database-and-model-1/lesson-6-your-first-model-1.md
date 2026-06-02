In the previous lesson, we created the `entries` table in the database. But a table sitting in the database does not mean much if we do not know how to talk to it from our PHP code. This lesson answers that question, and the answer is called **Eloquent**.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the controller will no longer use a hardcoded array. Instead, it will query the database directly using Eloquent. The view will be updated to work with Eloquent objects, and it will gracefully handle the case when no entries exist yet. You will also have a fully configured `Entry` model with mass assignment protection, a defined relationship to the `User` model, and some seed data to see real entries in the browser.

### What You'll Learn

- What Eloquent ORM is and why it makes database interaction significantly cleaner than raw SQL
- How to configure the `Entry` model using Laravel 13's `#[Fillable]` attribute
- What mass assignment protection is and why it matters for security
- How to define relationships between models (`belongsTo` and `hasMany`)
- How to update the controller to fetch real data from the database
- How to update the view to work with Eloquent objects instead of arrays
- The difference between `@foreach` and `@forelse` in Blade
- How to insert seed data using Artisan Tinker for testing

### What You'll Need

- The `catatku` project open in VS Code with the development server running
- The `entries` table created in the database from Lesson 5
- You can verify by opening HeidiSQL from Laragon and checking that the `entries` table exists in `db_catatku`

---

## Step 1: Understand the Entry Model {#step-1-understand-the-entry-model}

In the previous lesson, Artisan created the file `app/Models/Entry.php` when we ran `php artisan make:model Entry -m`. Open that file:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Entry extends Model
{
    //
}
```

This is an empty Eloquent model. Even in this state, it already knows quite a lot. Because the class is named `Entry`, Eloquent automatically maps it to the `entries` table in the database. Because it extends `Model`, it inherits all of Eloquent's query methods, timestamp handling, and relationship capabilities. But we need to add a few things to make it truly useful.

---

## Step 2: Configure the Entry Model {#step-2-configure-the-entry-model}

Update `app/Models/Entry.php` with mass assignment protection and a relationship:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

There are two important additions here. Let us look at each one.

### The `#[Fillable]` Attribute {#the-fillable-attribute}

The `#[Fillable(['title', 'content'])]` line at the top of the class uses a PHP attribute to declare which columns are allowed to be filled through mass assignment. Laravel 13 introduces this approach as the modern way to define fillable fields. If you have seen older Laravel tutorials, they use `protected $fillable = [...]` as a property inside the class. The `#[Fillable]` attribute achieves the same result with a cleaner, more declarative syntax.

If you look at the default `User` model in `app/Models/User.php`, you will notice that Laravel 13 already uses this same pattern:

```php
#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    // ...
}
```

This is the standard approach in Laravel 13. Attributes keep model configuration visible at a glance, right at the top of the class, instead of buried among properties and methods.

### The `belongsTo` Relationship {#the-belongsto-relationship}

The `user()` method defines that every entry belongs to one user. This corresponds to the `user_id` foreign key column we added to the `entries` table in Lesson 5. When you call `$entry->user`, Eloquent automatically runs a query to fetch the related `User` record. We will use this relationship later when we build the store functionality, where entries will be created through the authenticated user's relationship.

---

## Step 3: Add the Reverse Relationship to User {#step-3-add-the-reverse-relationship-to-user}

Relationships work in both directions. We defined that an entry belongs to a user, but we also need to tell the `User` model that a user can have many entries.

Open `app/Models/User.php` and add the `entries()` method:

```php
use Illuminate\Database\Eloquent\Relations\HasMany;

// Inside the User class, add this method:
public function entries(): HasMany
{
    return $this->hasMany(Entry::class);
}
```

So, the complete code for the User model class is as follows:
```php
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\Relations\HasMany; // add this lines of code


#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // add this lines of code
    public function entries(): HasMany
    {
        return $this->hasMany(Entry::class);
    }
}

```

With both sides of the relationship defined, you can navigate in either direction:

From an entry to its owner: `$entry->user->name`

From a user to all their entries: `$user->entries()->get()`

This bidirectional relationship will become essential in later lessons. When we build the store functionality, we will create entries through the user relationship: `$request->user()->entries()->create($validated)`. This automatically sets the `user_id` column without us having to specify it manually, which is both convenient and secure.

---

## Step 4: Update the Controller {#step-4-update-the-controller}

Now let us replace the hardcoded array in `EntryController` with a real database query. Open `app/Http/Controllers/EntryController.php` and update the `index()` method.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Entry; // add this line of code
use Illuminate\Http\Request;

class EntryController extends Controller
{
    public function index()
    {
        $entries = Entry::with('user')->latest()->get();

        return view('entries.index', compact('entries'));
    }
}
```

Let us break down the query `Entry::with('user')->latest()->get()`:

`Entry::` starts a query on the `entries` table through the Eloquent model.

`with('user')` tells Eloquent to eager load the related `User` record for each entry. Without this, accessing `$entry->user` in the view would trigger a separate database query for every single entry (known as the "N+1 problem"). With `with('user')`, Eloquent fetches all related users in a single additional query, regardless of how many entries there are.

`latest()` orders the results by `created_at` in descending order (newest first). It is a shortcut for `orderBy('created_at', 'desc')`.

`get()` executes the query and returns the results as an Eloquent Collection.

Notice that we are fetching all entries from the database, not just entries belonging to a specific user. This is intentional for now. The authentication system does not exist yet, so calling `auth()->user()` would crash the application. Once we build authentication in Lesson 11, we will update this query to `auth()->user()->entries()->latest()->get()` so each user only sees their own entries.

---

## Step 5: Update the View {#step-5-update-the-view}

The data the view receives is now a collection of Eloquent objects, not an array. The syntax for accessing properties changes from bracket notation (`$entry['title']`) to arrow notation (`$entry->title`).

Update `resources/views/entries/index.blade.php`:

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

        @forelse ($entries as $entry)
            <div class="bg-white rounded-xl border border-gray-200 p-5 mb-4">
                <h3 class="font-semibold text-gray-900 mb-1">
                    {{ $entry->title }}
                </h3>
                <p class="text-xs text-gray-400 mb-3">
                    {{ $entry->created_at->format('d F Y') }}
                </p>
                <p class="text-sm text-gray-600 line-clamp-2">
                    {{ $entry->content }}
                </p>
            </div>
        @empty
            <div class="text-center py-16 text-gray-400">
                <p class="text-5xl mb-4">📓</p>
                <p class="font-medium text-gray-500">No entries yet</p>
                <p class="text-sm mt-1">Start writing your first entry!</p>
            </div>
        @endforelse

    </div>

</body>
</html>
```

There are three important changes from the previous version:

`$entry->title` instead of `$entry['title']`. Eloquent models are objects, so you access their properties with the arrow operator `->` instead of array brackets `[]`. This is a fundamental difference you will see throughout the rest of the course.

`$entry->created_at->format('d F Y')`. Laravel automatically converts timestamp columns into Carbon objects. Carbon is a powerful date/time library that comes bundled with Laravel. The `format('d F Y')` method produces output like "20 February 2026". You can change the format string to display dates in any format you need.

`@forelse ... @empty ... @endforelse` replaces the `@foreach` we used before. The `@forelse` directive works exactly like `@foreach`, but it includes an `@empty` block that renders when the collection has no items. This is much cleaner than manually checking the array length before deciding what to display.

---

## Step 6: Insert Seed Data with Tinker {#step-6-insert-seed-data-with-tinker}

The database is currently empty, so visiting `/entries` will show the "No entries yet" empty state. Let us insert some test data using Artisan Tinker so we can see entries displayed in the browser.

Open a new terminal (keep the development server running) and start Tinker:

```bash
php artisan tinker
```

First, create a temporary user. We need one because every entry requires a `user_id`:

```php
$user = \App\Models\User::create([
    'name'     => 'Budi',
    'email'    => 'budi@example.com',
    'password' => bcrypt('password123'),
]);
```

Now create a few entries through the user's relationship:

```php
$user->entries()->create(['title' => 'My first entry', 'content' => 'This is my very first journal entry. Feels great to get started!']);

$user->entries()->create(['title' => 'Learning Laravel', 'content' => 'Today I learned about Eloquent ORM. Turns out interacting with the database can be this clean and expressive.']);

$user->entries()->create(['title' => 'Weekend plans', 'content' => 'Planning to finish the Laravel course this weekend and maybe start building a side project.']);
```

Output:
```
$ php artisan tinker
Psy Shell v0.12.22 (PHP 8.4.5 — cli) by Justin Hileman
New PHP manual is available (latest: 3.0.2). Update with `doc --update-manual`

> $user = \App\Models\User::create([
.     'name'     => 'Budi',
.     'email'    => 'budi@example.com',
.     'password' => bcrypt('password123'),
. ]);

= App\Models\User {#7909
    name: "Budi",
    email: "budi@example.com",
    #password: "\$2y\$12\$ho.DIN6DCiHFqKwiEzb8GuFdTkFEdDKhyL6x8E4MqjL0Zrf7/Tncu",
    updated_at: "2026-03-29 08:12:19",
    created_at: "2026-03-29 08:12:19",
    id: 1,
  }

> $user->entries()->create(['title' => 'My first entry', 'content' => 'This is my very first journal entry. Feels great to get started!']);

= App\Models\Entry {#8652
    title: "My first entry",
    content: "This is my very first journal entry. Feels great to get started!",
    user_id: 1,
    updated_at: "2026-03-29 08:12:29",
    created_at: "2026-03-29 08:12:29",
    id: 1,
  }

> $user->entries()->create(['title' => 'Learning Laravel', 'content' => 'Today I learned about Eloquent ORM. Turns out interacting with the database can be this clean and expressive.']);

= App\Models\Entry {#7407
    title: "Learning Laravel",
    content: "Today I learned about Eloquent ORM. Turns out interacting with the database can be this clean and expressive.",
    user_id: 1,
    updated_at: "2026-03-29 08:12:38",
    created_at: "2026-03-29 08:12:38",
    id: 2,
  }

> $user->entries()->create(['title' => 'Weekend plans', 'content' => 'Planning to finish the Laravel course this weekend and maybe start building a side project.']);

= App\Models\Entry {#7350
    title: "Weekend plans",
    content: "Planning to finish the Laravel course this weekend and maybe start building a side project.",
    user_id: 1,
    updated_at: "2026-03-29 08:12:43",
    created_at: "2026-03-29 08:12:43",
    id: 3,
  }


```

![insert data via tinker](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/04-insert-dummy-data-via-tinker.webp)

Type `exit` to leave Tinker.

Notice how we used `$user->entries()->create([...])` to insert entries. This is the same relationship-based approach we will use in the controller later. The `user_id` column is set automatically because we are creating through the user's `entries()` relationship.

---

## Step 7: View the Result {#step-7-view-the-result}

Open `http://127.0.0.1:8000/entries` in your browser. You should now see the three entries we just created, displayed with their titles, dates, and content snippets. The data comes from the database, not from a hardcoded array.

![fetch data from database](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/05-fetch-data-from-database.webp)

This confirms that the model is properly connected to the database, the Eloquent query is working, and the view correctly renders Eloquent objects.

---

## What is Eloquent ORM? {#what-is-eloquent-orm}

Now that you have used Eloquent in practice, let us understand what it is at a conceptual level.

ORM stands for Object-Relational Mapping. It is a technique that lets you interact with database tables using PHP objects instead of writing raw SQL. Each table in the database gets a corresponding model class in PHP. Each row in the table becomes an instance of that class. And each column becomes a property on that object.

Without Eloquent, fetching entries from the database requires code like this:

```php
$pdo = new PDO('mysql:host=127.0.0.1;dbname=db_catatku', 'root', '');
$stmt = $pdo->prepare('SELECT * FROM entries ORDER BY created_at DESC');
$stmt->execute();
$entries = $stmt->fetchAll(PDO::FETCH_ASSOC);
```

With Eloquent, the same operation becomes:

```php
$entries = Entry::latest()->get();
```

The difference is dramatic. The Eloquent version is shorter, more expressive, and easier to read. It is also safer because Eloquent handles parameter binding and SQL injection prevention automatically. You do not need to worry about escaping values or preparing statements manually.

---

## What is Mass Assignment Protection? {#what-is-mass-assignment-protection}

The `#[Fillable(['title', 'content'])]` attribute is a security feature that deserves a deeper explanation.

Mass assignment is when you pass an array of data directly to a method like `Entry::create()` or `$entry->update()`. This is convenient because you can create a record in a single line:

```php
Entry::create(['title' => 'My Entry', 'content' => 'Hello world']);
```

But it becomes dangerous when the data comes from user input. Imagine a form with fields for `title` and `content`. A malicious user could add an extra `user_id=5` field to the request, attempting to forge ownership of the entry. If you wrote this in your controller:

```php
Entry::create($request->all()); // Dangerous!
```

The `user_id` from the manipulated request would be saved to the database. The attacker just claimed ownership of someone else's entry.

The `#[Fillable]` attribute prevents this. By declaring only `['title', 'content']` as fillable, any attempt to mass-assign `user_id` or any other column is silently ignored. The `user_id` is not in the fillable list, so it cannot be set through mass assignment.

How do we set `user_id` then? We do it explicitly through the relationship. In a later lesson when we build the store functionality, the code will look like this:

```php
$request->user()->entries()->create($validated);
```

This creates the entry through the authenticated user's `entries()` relationship, which automatically sets `user_id` to the current user's ID. The value comes from the server-side session, not from user input, making it impossible to forge.

---

## Conclusion {#conclusion}

This lesson transformed the `Entry` model from an empty file into a fully functional, secure model connected to the database. Here are the key takeaways:

- **Eloquent ORM** maps database tables to PHP classes, rows to objects, and columns to properties. It lets you interact with the database using expressive PHP code instead of raw SQL.
- Laravel 13 uses the **`#[Fillable]`** attribute to declare which columns can be mass-assigned. This replaces the older `protected $fillable` property with a cleaner, more declarative syntax.
- **Mass assignment protection** prevents malicious users from setting columns they should not have access to (like `user_id`). Only columns listed in `#[Fillable]` can be filled through `create()` or `update()`.
- The **`belongsTo`** relationship on `Entry` says "every entry belongs to one user." The **`hasMany`** relationship on `User` says "every user can have many entries."
- `Entry::with('user')->latest()->get()` fetches all entries with their related users in an efficient query, ordered newest first. This query will be updated to scope by user once authentication is built.
- **Eager loading** with `with('user')` prevents the N+1 query problem by fetching all related records in a single additional query.
- Eloquent objects use **arrow notation** (`$entry->title`) instead of array bracket notation (`$entry['title']`).
- Laravel automatically converts timestamp columns to **Carbon** objects, giving you powerful date formatting methods like `->format('d F Y')`.
- **`@forelse`** is like `@foreach` but includes an `@empty` block for gracefully handling empty collections.
- **Artisan Tinker** lets you interact with your models and database directly from the command line. It is invaluable for testing and inserting seed data during development.

In the next lesson, we will clean up the views using **Blade components**, Laravel's way of breaking HTML templates into reusable pieces. Navigation bars, page layouts, and structural elements will only need to be written once and can be shared across every page. This is the first step toward making Catatku look and feel like a real application.