The previous lesson closed half of the CRUD cycle. Users can now write new entries and see them in the listing. But entries that are already saved cannot be modified if something needs fixing, and there is no way to remove them if they are no longer needed. This lesson completes the other half.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the full CRUD cycle for Catatku will be complete: create, read, update, and delete. All seven operations will have their own routes, controller methods, and views, all working with RESTful conventions and proper authorization checks.

### What You'll Learn

- How to build an edit form that pre-fills with existing data
- How `old('field', $default)` works with a second argument for edit forms
- What method spoofing is and why it is necessary (`@method('PUT')` and `@method('DELETE')`)
- How to implement the `update()` and `destroy()` controller methods
- Why every mutating operation needs an `abort(403)` ownership check
- The complete RESTful routing convention for a Laravel resource

### What You'll Need

- The `catatku` project open in VS Code with the development server running
- Logged in via `/dev-login` (the temporary route from Lesson 8)
- At least one entry already created so you have something to edit and delete

---

## Step 1: Add the Edit and Delete Routes {#step-1-add-the-edit-and-delete-routes}

Update `routes/web.php` with the complete set of routes for entries:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;

Route::get('/', function () {
    return view('home');
});

Route::get('/entries', [EntryController::class, 'index']);

Route::middleware('auth')->group(function () {
    Route::get('/entries/create', [EntryController::class, 'create']);
    Route::post('/entries', [EntryController::class, 'store']);
    Route::get('/entries/{entry}', [EntryController::class, 'show']);
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit']); // add this
    Route::put('/entries/{entry}', [EntryController::class, 'update']); // add this
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']); // add this
});

// ONLY FOR DEVELOPMENT - delete after lesson 10
Route::get('/dev-login', function () {
    auth()->loginUsingId(1);
    return redirect('/entries');
});
```

Three new routes have been added inside the `middleware('auth')` group.

`Route::get('/entries/{entry}/edit', ...)` displays the edit form pre-filled with the entry's current data. The `{entry}` parameter will be resolved by Route Model Binding, just like in the `show()` method.

`Route::put('/entries/{entry}', ...)` processes the edit form submission. Notice the HTTP method is PUT, not POST. In RESTful conventions, POST creates a new resource while PUT updates an existing one.

`Route::delete('/entries/{entry}', ...)` handles the deletion of an entry. The DELETE method signals that the resource at this URL should be removed.

---

## Step 2: Add the Controller Methods {#step-2-add-the-controller-methods}

Open `app/Http/Controllers/EntryController.php` and add the `edit()`, `update()`, and `destroy()` methods. Here is the complete controller:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Entry;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;

class EntryController extends Controller
{
    public function index()
    {
        $entries = Entry::with('user')->latest()->get();

        return view('entries.index', compact('entries'));
    }

    public function create()
    {
        return view('entries.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'title'   => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        $request->user()->entries()->create($validated);

        return redirect('/entries')
            ->with('success', 'Entry saved successfully.');
    }

    public function show(Entry $entry)
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        return view('entries.show', compact('entry'));
    }

    public function edit(Entry $entry)
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        return view('entries.edit', compact('entry'));
    }

    public function update(Request $request, Entry $entry): RedirectResponse
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        $validated = $request->validate([
            'title'   => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        $entry->update($validated);

        return redirect('/entries/' . $entry->id)
            ->with('success', 'Entry updated successfully.');
    }

    public function destroy(Entry $entry): RedirectResponse
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        $entry->delete();

        return redirect('/entries')
            ->with('success', 'Entry deleted successfully.');
    }
}
```

> **Note about `index()`:** The `index()` method currently uses `Entry::with('user')->latest()->get()`, which fetches all entries from all users. This is temporary. Once we complete the authentication system in Lesson 11 and move `/entries` inside the `middleware('auth')` group, we will update this to `auth()->user()->entries()->latest()->get()` so each user only sees their own entries.

Let us look at each new method in detail.

### The `edit()` Method {#the-edit-method}

```php
public function edit(Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    return view('entries.edit', compact('entry'));
}
```

This method is structurally identical to `show()`. It receives an `Entry` object through Route Model Binding, checks that the authenticated user owns it, and passes it to a view. The difference is purely in the view: `show` renders a read-only detail page, while `edit` renders a form pre-filled with the entry's current data.

### The `update()` Method {#the-update-method}

```php
public function update(Request $request, Entry $entry): RedirectResponse
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    $validated = $request->validate([
        'title'   => 'required|string|max:255',
        'content' => 'required|string',
    ]);

    $entry->update($validated);

    return redirect('/entries/' . $entry->id)
        ->with('success', 'Entry updated successfully.');
}
```

Compare this to the `store()` method from Lesson 8. The validation rules are identical because the same fields need the same constraints whether you are creating or updating. The key difference is in how the data is saved: `store()` uses `$request->user()->entries()->create($validated)` to create a new record, while `update()` uses `$entry->update($validated)` to modify an existing one.

`$entry->update($validated)` is a single line that updates the entry in the database with the validated data. Eloquent automatically sets the `updated_at` column to the current time. After saving, we redirect to the entry's detail page (not the listing) so the user can immediately see their changes.

### The `destroy()` Method {#the-destroy-method}

```php
public function destroy(Entry $entry): RedirectResponse
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    $entry->delete();

    return redirect('/entries')
        ->with('success', 'Entry deleted successfully.');
}
```

This is the simplest method in the controller. After the ownership check, `$entry->delete()` removes the record from the database permanently. We redirect to the entries listing because the entry no longer exists, so there is nowhere else to go.

### Why Every Method Needs `abort(403)` {#why-every-method-needs-abort-403}

You might have noticed that the ownership check appears in every method that works with a specific entry: `show()`, `edit()`, `update()`, and `destroy()`. This repetition is intentional.

Even though entries are meant to be private, a creative user could try to guess the URL of someone else's entry. If your entry is at `/entries/5`, nothing stops another user from typing `/entries/5/edit` in their browser and attempting to modify it. The `abort(403)` check ensures that any operation, whether reading, editing, or deleting, only succeeds if the entry actually belongs to the authenticated user. Everyone else gets a 403 Forbidden response.

In larger applications, this pattern is typically managed through Laravel's Policy or Gate system, which centralizes authorization logic. But the principle is exactly the same: verify ownership before allowing any action.

---

## Step 3: Create the Edit Form View {#step-3-create-the-edit-form-view}

Create the file `resources/views/entries/edit.blade.php`:

```html
<x-layout :title="'Edit: ' . $entry->title . ' — Catatku'">

    <div class="mb-6">
        <a href="/entries/{{ $entry->id }}"
           class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to entry
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Edit Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="/entries/{{ $entry->id }}">
            @csrf
            @method('PUT')

            {{-- Title --}}
            <div class="mb-5">
                <label for="title"
                       class="block text-sm font-medium text-gray-700 mb-1">
                    Title
                </label>
                <input
                    type="text"
                    id="title"
                    name="title"
                    value="{{ old('title', $entry->title) }}"
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent
                           {{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                    autofocus
                >
                @error('title')
                    <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Content --}}
            <div class="mb-6">
                <label for="content"
                       class="block text-sm font-medium text-gray-700 mb-1">
                    Content
                </label>
                <textarea
                    id="content"
                    name="content"
                    rows="12"
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                >{{ old('content', $entry->content) }}</textarea>
                @error('content')
                    <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Buttons --}}
            <div class="flex items-center justify-between">
                <a href="/entries/{{ $entry->id }}"
                   class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <button type="submit"
                    class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Save Changes
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

This form looks very similar to the create form from Lesson 8, but there are three important differences.

`@method('PUT')` appears right after `@csrf`. This tells Laravel to treat the form submission as a PUT request, even though the HTML form's `method` attribute is `POST`. We will explain why this is necessary in the reference section below.

`old('title', $entry->title)` uses a second argument. The `old()` helper accepts a default value as its second parameter. The first time the edit page loads, no "old" input exists in the session, so `old()` falls back to `$entry->title`, which is the entry's current value from the database. If the user submits the form and validation fails, `old()` returns the value they just typed (the first argument takes priority), so they do not lose their changes. This two-argument pattern is what makes the edit form work correctly in both scenarios.

`action="/entries/{{ $entry->id }}"` points the form to the specific entry's URL, not to `/entries` like the create form. Combined with `@method('PUT')`, this tells Laravel to route the submission to the `update()` method.

---

## Step 4: Verify All Routes {#step-4-verify-all-routes}

Run the following command to confirm that all routes are registered correctly:

```bash
php artisan route:list
```

Expected output:

```
$ php artisan route:list

  GET|HEAD  / ............................................... routes/web.php:6
  GET|HEAD  dev-login ...................................... routes/web.php:22
  GET|HEAD  entries .................................... EntryController@index
  POST      entries .................................... EntryController@store
  GET|HEAD  entries/create ............................ EntryController@create
  GET|HEAD  entries/{entry} ............................. EntryController@show
  PUT       entries/{entry} ........................... EntryController@update
  DELETE    entries/{entry} .......................... EntryController@destroy
  GET|HEAD  entries/{entry}/edit ........................ EntryController@edit
```

This is the complete set of RESTful routes for the entries resource. Seven routes, seven controller methods, covering every CRUD operation.

---

## Step 5: Test Edit and Delete {#step-5-test-edit-and-delete}

Make sure you are logged in (via `/dev-login`), then test the full flow:

1. Go to `http://127.0.0.1:8000/entries` and make sure you have at least one entry. If not, create one from `/entries/create`.
2. Click the **Edit** link on any entry card. The edit form should open with the title and content fields pre-filled with the entry's current data.
![access edit page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/11-access-edit-page.webp)

3. Change the title or content, then click **Save Changes**. You should be redirected to the entry's detail page with a green success message saying "Entry updated successfully." The content should reflect your changes.
![change title or content](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/12-change-title-for-edit-feature-testing.webp)

![entry updated](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/13-entry-updated.webp)

4. Go back to the entries listing and click **Delete** on any entry. A browser confirmation dialog will appear asking "Delete this entry?" Click OK. You should be redirected to the listing with a success message saying "Entry deleted successfully." and the entry should no longer appear.

![test delete](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/14-test-delete.webp)

![entry deleted](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/15-entry-deleted.webp)

5. Try testing the authorization check. We can use Tinker to add a new user, just as we did in Lesson 6.  After that, we can log in to the second account using the same method by changing the `id` value in `auth()->loginUsingId(1)` on the `/dev-login` route to 2.  Log in to our second account by going to `http://127.0.0.1:8000/entries` in our browser. After that, we can try clicking “Read” on one of the data entries for User 1's account. you should see a 403 Forbidden error. 

![error 403](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/07-error-403.webp)

---

## What is Method Spoofing? {#what-is-method-spoofing}

HTML forms only support two HTTP methods: GET and POST. This is a limitation in the HTML specification itself, not in Laravel or PHP. But RESTful routing conventions use additional methods like PUT (for updates) and DELETE (for deletions) to make the intent of each request clear.

Laravel solves this mismatch with **method spoofing**. When you include `@method('PUT')` in a form, Blade generates a hidden input field:

```html
<input type="hidden" name="_method" value="PUT">
```

The form is still sent as a POST request (because that is all HTML supports), but Laravel reads the `_method` field and treats the request as if it were a PUT request. The same mechanism works with `@method('DELETE')`.

This is why the delete form in the EntryCard component uses `method="POST"` in the HTML but includes `@method('DELETE')`:

```html
<form method="POST" action="/entries/{{ $entry->id }}">
    @csrf
    @method('DELETE')
    <button type="submit">Delete</button>
</form>
```

The browser sends it as POST, but Laravel routes it to the `destroy()` method because of the `_method` field. This pattern is not unique to Laravel. Many web frameworks use the same approach because they all face the same HTML limitation.

---

## RESTful Routing Conventions {#restful-routing-conventions}

Laravel follows RESTful conventions for naming routes and controller methods. Here is the complete table for the "entries" resource:

| Action | HTTP Method | URL | Controller Method |
|--------|-------------|-----|-------------------|
| List all | GET | `/entries` | `index()` |
| Show create form | GET | `/entries/create` | `create()` |
| Save new | POST | `/entries` | `store()` |
| Show detail | GET | `/entries/{entry}` | `show()` |
| Show edit form | GET | `/entries/{entry}/edit` | `edit()` |
| Save changes | PUT/PATCH | `/entries/{entry}` | `update()` |
| Delete | DELETE | `/entries/{entry}` | `destroy()` |

By following these conventions, anyone familiar with Laravel can immediately predict the route structure just from the controller and method names. This consistency makes codebases easier to navigate, especially when working in teams.

Notice that `create` and `store` are separate, and `edit` and `update` are separate. This reflects the two-step form pattern: the first step (GET) shows the form, and the second step (POST/PUT) processes the submission. The separation also means that if validation fails on the second step, the form (first step) can be redisplayed with errors without any confusion about which URL to redirect to.

---

## Conclusion {#conclusion}

The CRUD cycle is now complete. All seven operations that make up entry management are working with proper routes, controller methods, and views. Here are the key takeaways:

- HTML forms only support GET and POST. **Method spoofing** with `@method('PUT')` and `@method('DELETE')` lets Laravel treat POST submissions as PUT or DELETE requests to match RESTful conventions.
- `@method('PUT')` generates `<input type="hidden" name="_method" value="PUT">`. Laravel reads this field to determine the actual intended HTTP method.
- The **edit form** is structurally similar to the create form, with two differences: it includes `@method('PUT')`, and it uses `old('field', $entry->field)` to pre-fill fields with existing data.
- `old('field', $default)` with a **second argument** is essential for edit forms. On first load, it shows the current database value. After a failed validation, it shows what the user just typed.
- `$entry->update($validated)` modifies an existing record in the database. Eloquent automatically updates the `updated_at` timestamp.
- `$entry->delete()` permanently removes a record from the database. After deletion, redirect to the listing since the entry no longer exists.
- Every method that operates on a specific entry includes an **`abort(403)` ownership check** to ensure only the entry owner can read, edit, or delete it.
- **RESTful routing conventions** provide a predictable, industry-standard structure: seven routes, seven controller methods, each with a clear name and purpose.
- `php artisan route:list` displays all registered routes and is useful for verifying that your route structure is complete and correct.
- The `index()` method currently shows all entries. This will be updated in Lesson 11 to show only the authenticated user's entries once the full authentication system is in place.

In the next two lessons, we will build the real authentication system: a registration page for creating new accounts and a login page that verifies user identity before granting access. The temporary `/dev-login` route has served its purpose and will finally be removed.