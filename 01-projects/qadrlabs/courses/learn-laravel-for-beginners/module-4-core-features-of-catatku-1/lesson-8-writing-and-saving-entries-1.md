The previous lesson produced something you can actually see and interact with: an entries listing page and a detail page, both working with a clean shared layout. But if you look closely, every entry displayed was created manually through Tinker. There is no way for a user to write a new entry from inside the application itself.

This lesson closes that gap.

## Overview {#overview}

### What You'll Build

By the end of this lesson, a logged-in user will be able to open a form, write a journal entry, and see it appear in the entries list immediately. One complete flow, from an empty form to a saved database record, will work for the first time.

### What You'll Learn

- How Laravel handles the two-step form flow: a GET route to display the form and a POST route to process the submission
- How to validate user input using `$request->validate()` with rules like `required`, `string`, and `max`
- What happens when validation fails: automatic redirect, error messages, and preserved input
- How `@csrf` protects your forms from cross-site request forgery attacks
- How `old()` restores previously entered values when the user is sent back to the form
- How to save data securely through an Eloquent relationship so `user_id` cannot be forged
- How to group routes with `middleware('auth')` to require authentication

### What You'll Need

- The `catatku` project open in VS Code with the development server running
- The layout component, EntryCard component, and entry views from Lesson 7
- The test user created via Tinker in Lesson 6

---

## Step 1: Add the Routes {#step-1-add-the-routes}

We need three new routes: one to display the create form (GET) and one to process the form submission (POST), and one for user authentication used for testing

Update `routes/web.php`:

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
});

// ONLY FOR DEVELOPMENT - delete after lesson 10
Route::get('/dev-login', function () {
    auth()->loginUsingId(1);
    return redirect('/entries');
});
```

There are several things to notice here.

The `/entries` route stays outside the `middleware('auth')` group, so anyone can view the entries listing without logging in. The create, store, and show routes are inside the group, meaning only authenticated users can access them. If an unauthenticated visitor tries to access any route inside the group, Laravel automatically redirects them to the login page.

`Route::get('/entries/create', ...)` displays the form. `Route::post('/entries', ...)` processes the form submission. This two-route pattern is standard in Laravel: GET to show, POST to process. You will see it repeated for every form in the application.

> **Route order matters!** The `/entries/create` route must be declared **before** `/entries/{entry}`. If you reverse them, Laravel will think the word "create" in the URL is an entry ID and try to find an Entry with ID "create" in the database, which will fail with a 404.

The `/dev-login` route at the bottom is a temporary shortcut for testing. It logs in the user with ID 1 (the "Budi" user we created via Tinker in Lesson 6) and redirects to the entries listing. We will remove this route in Lesson 10 when we build proper authentication.

---

## Step 2: Add Controller Methods {#step-2-add-controller-methods}

Open `app/Http/Controllers/EntryController.php` and add the `create()` and `store()` methods:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Entry;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse; // add this line of code

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
}
```

The `create()` method is straightforward: it simply returns the form view. No data preparation is needed because we are creating something new, not displaying existing data.

The `store()` method does the real work. Let us walk through it step by step.

`$request->validate([...])` checks the incoming data against the specified rules. If any rule fails, Laravel automatically redirects the user back to the form, carrying the error messages and the previously entered values. If all rules pass, the method returns an array containing only the validated data.

The validation rules are separated by pipe characters (`|`). For the `title` field: `required` means it cannot be empty, `string` means it must be text, and `max:255` limits it to 255 characters (matching the VARCHAR column size in the database). For the `content` field: `required` and `string` ensure it is present and is text, with no length limit since the database column is TEXT type.

`$request->user()->entries()->create($validated)` saves the new entry to the database. This single line does three important things. `$request->user()` gets the currently authenticated user from the session. `->entries()` accesses the `hasMany` relationship we defined in Lesson 6, which means the `user_id` column is automatically set to the current user's ID. `->create($validated)` inserts a new record using only the validated data.

This approach is secure because `user_id` never comes from the form input. It is always derived from the server-side session. Even if someone tried to inject a fake `user_id` into the form submission, the `#[Fillable]` attribute on the Entry model would ignore it (since only `title` and `content` are fillable), and the relationship would overwrite it with the correct value anyway.

`return redirect('/entries')->with('success', '...')` sends the user back to the entries listing page and stores a flash message in the session. Remember the `@if (session('success'))` block in our layout component from Lesson 7? This is where that flash message comes from. The message is shown once and then automatically cleared from the session.

---

## Step 3: Create the Form View {#step-3-create-the-form-view}

Create the file `resources/views/entries/create.blade.php`:

```html
<x-layout title="Write Entry — Catatku">

    <div class="mb-6">
        <a href="/entries" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to list
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Write New Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="/entries">
            @csrf

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
                    value="{{ old('title') }}"
                    placeholder="Entry title..."
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
                    placeholder="Write your entry here..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                >{{ old('content') }}</textarea>
                @error('content')
                    <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Buttons --}}
            <div class="flex items-center justify-between">
                <a href="/entries"
                   class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <button type="submit"
                    class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Save Entry
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

There are several mechanisms working together in this form. Let us examine each one.

### The `@csrf` Directive {#the-csrf-directive}

Every POST form in Laravel must include `@csrf`. This directive generates a hidden input field containing a unique token tied to the user's session:

```html
<!-- What @csrf renders -->
<input type="hidden" name="_token" value="xYz123...">
```

This token proves that the form was submitted from a page in your own application, not from a malicious external site trying to forge requests on behalf of your users. This type of attack is called Cross-Site Request Forgery (CSRF). Without the `@csrf` token, Laravel rejects all POST requests with a 419 error.

### The `old()` Helper {#the-old-helper}

When validation fails, Laravel automatically redirects the user back to the form. But without `old()`, all the text they typed would be gone, forcing them to start over. That is a terrible user experience.

`old('title')` retrieves the previously submitted value for the `title` field from the session. Laravel stores these values automatically when validation fails, and `old()` fetches them back. For `<input>` elements, you place `old()` in the `value` attribute:

```html
<input value="{{ old('title') }}">
```

For `<textarea>` elements, you place `old()` between the opening and closing tags. Note that there is no whitespace between the tags and the Blade expression, because any whitespace would appear as content in the textarea:

```html
<textarea>{{ old('content') }}</textarea>
```

### Error Display {#error-display}

The `@error('title') ... @enderror` block renders only when validation for that specific field fails. Inside the block, `$message` contains the error message generated by Laravel (for example, "The title field is required.").

The conditional CSS class `{{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}` changes the input border to red and adds a light red background when there is a validation error for that field. When there is no error, it uses the normal gray border. This gives users an immediate visual cue about which fields need attention.

---

## Step 4: Test the Create Flow {#step-4-test-the-create-flow}

With the test user already created in Lesson 6 and the temporary `/dev-login` route in place, let us test the full flow.

First, log in by visiting `http://127.0.0.1:8000/dev-login`. This will authenticate you as the user with ID 1 (Budi) and redirect you to the entries listing.

Now go to `http://127.0.0.1:8000/entries/create`. You should see the form with a title input, a content textarea, and a "Save Entry" button.
![write new entry](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/08-write-new-entry.webp)

Try submitting the form with empty fields. You should be redirected back to the form with red-bordered inputs and error messages below each field. This is Laravel's validation at work.

Now fill in a title and content, then click "Save Entry". You should be redirected to the entries listing, where a green success message says "Entry saved successfully." and your new entry appears in the list.
![new entry saved](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/09-new-entry-saved.webp)

Click on the entry title or the "Read" link to visit the detail page and confirm that the content was saved correctly.
![visit detail page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/10-visit-entry-detail-page.webp)

---

## The Form Flow in Laravel {#the-form-flow-in-laravel}

Now that you have seen the entire flow in action, let us map out what happens behind the scenes when a user submits a form:

```
1. Browser sends POST /entries
   { _token: "abc...", title: "My entry", content: "Entry body..." }
         │
         ▼
2. routes/web.php directs to EntryController@store
         │
         ▼
3. Controller validates the data
   Is title present? Is content present?
         │
         ├── Failed  → redirect back to form with errors + old input
         └── Passed  → save to database → redirect to listing with success message
```

This flow is the same for every form in Laravel. The specifics change (different fields, different validation rules, different redirect targets), but the pattern stays identical: validate first, reject or save, then redirect. You will see this exact pattern again when we build the edit form in the next lesson.

---

## Understanding Middleware Groups {#understanding-middleware-groups}

In the route file, we wrapped several routes inside `Route::middleware('auth')->group(function () { ... })`. This means every route inside the group requires an authenticated user. If someone who is not logged in tries to access any of these routes, Laravel automatically redirects them to the login page.

The `/entries` listing route is intentionally left outside the group so that anyone can browse entries without logging in. But creating, viewing details, and all future operations that modify data will require authentication.

This separation is a common pattern in web applications: public read access with protected write access. The entries listing is the storefront window that anyone can look through. The operations that change data require you to walk through the door and identify yourself first.

---

## Conclusion {#conclusion}

A complete flow is now working: the user opens a form, fills in a title and content, submits it, and the entry gets saved to the database. Here are the key takeaways:

- Laravel forms follow a **two-route pattern**: GET to display the form, POST to process the submission. The form's `action` attribute points to the POST route, and the `method` attribute is set to `POST`.
- `$request->validate([...])` checks input against rules. If validation **fails**, Laravel automatically redirects back with error messages and old input. If it **passes**, you get a clean array of validated data.
- Common validation rules include `required` (must be present), `string` (must be text), and `max:255` (maximum character length).
- **`@csrf`** generates a hidden token that proves the form was submitted from your application, protecting against cross-site request forgery attacks. Every POST form must include it.
- **`old('field')`** retrieves the previously entered value after a validation failure, so users do not lose their work. Place it in the `value` attribute for inputs and between tags for textareas.
- **`@error('field') ... @enderror`** renders error messages for specific fields. The `$message` variable inside contains the validation error text.
- `$request->user()->entries()->create($validated)` saves data through the Eloquent relationship, automatically setting `user_id` from the session. This is secure because `user_id` never comes from user input.
- `redirect('/path')->with('success', '...')` sends the user to a new page with a one-time flash message stored in the session.
- **`Route::middleware('auth')->group(...)`** requires authentication for all routes inside the group. Unauthenticated visitors are redirected to the login page automatically.
- **Route order matters.** Static segments like `/entries/create` must be declared before dynamic segments like `/entries/{entry}`, or Laravel will try to match "create" as an entry ID.

In the next lesson, we will implement the remaining two CRUD operations: editing existing entries and deleting them. You will learn why browsers only understand GET and POST, and how Laravel uses `@method('PUT')` and `@method('DELETE')` to work around that limitation.