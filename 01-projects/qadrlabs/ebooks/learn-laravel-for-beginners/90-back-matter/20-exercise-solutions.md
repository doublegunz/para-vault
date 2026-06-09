# Exercise Solutions

This section contains solutions to the exercises at the end of each chapter. Try each exercise on your own first. Struggling with a problem for a few minutes, even getting it wrong, teaches you far more than reading the answer straight away. When you are ready, compare your approach with the one here. There is often more than one correct answer; these are reference solutions, not the only way.

## Chapter 1 {#chapter-1}

These are reflection questions, so the "solutions" are model answers rather than code.

1. Ownership-based authorization means a user can only act on the data that belongs to them, not on other people's data. Email is a perfect everyday example: you can read and delete the messages in your own inbox, but not anyone else's.
2. The seven capabilities are routing, the MVC pattern, database migrations, the Eloquent ORM, full CRUD, authentication, and ownership-based authorization. Which two feel least familiar is personal; revisit your note at the end and see how they feel then.
3. A single end-to-end project shows how the pieces connect, which is exactly the part isolated tutorials leave out.

## Chapter 2 {#chapter-2}

1. `php artisan --version` prints the installed version, for example `Laravel Framework 13.x.x`. The exact patch number varies over time.
2. Start the server on a custom port with a flag:

```bash
php artisan serve --port=8080
```

The app then loads at `http://127.0.0.1:8080`.

3. A fresh Laravel 13 project registers a small number of framework routes before you write any (such as the storage route and the `up` health-check route). Run `php artisan route:list` and count the lines; `php artisan route:list --except-vendor` shows that you have written none of your own yet.

## Chapter 3 {#chapter-3}

1. Add the route and view:

```php
// routes/web.php
Route::get('/about', function () {
    return view('about');
});
```

```html
<!-- resources/views/about.blade.php -->
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>About - Catatku</title></head>
<body>
    <h1>About Catatku</h1>
    <p>Catatku is a simple, private journal app built while learning Laravel.</p>
</body>
</html>
```

2. Add a fourth array element with `id`, `title`, `content`, and `created_at` keys; it appears automatically because `@foreach` renders every item.
3. Show the count above the list:

```html
<p>You have {{ count($entries) }} entries.</p>
```

## Chapter 4 {#chapter-4}

1. Generate and wire the controller:

```bash
php artisan make:controller PageController
```

```php
// app/Http/Controllers/PageController.php
public function about()
{
    return view('about');
}
```

```php
// routes/web.php
use App\Http\Controllers\PageController;

Route::get('/about', [PageController::class, 'about']);
```

2. `php artisan route:list` now shows `/about` handled by `PageController@about` instead of a closure.
3. The view did not change because it only ever received a finished `$entries` value and rendered it. Moving where that value is prepared (closure to controller) does not change what the view is handed, so its output is identical.

## Chapter 5 {#chapter-5}

1. Add the column inside `Schema::create('entries', ...)`:

```php
$table->string('mood')->nullable();
```

Then `php artisan migrate:rollback` followed by `php artisan migrate`, and verify in Tinker with `Schema::getColumnListing('entries')`.

2. The command to undo the most recent migration is:

```bash
php artisan migrate:rollback
```

3. Add a nullable timestamp column and re-run the migration:

```php
$table->timestamp('published_at')->nullable();
```

## Chapter 6 {#chapter-6}

1. Fetch the latest entry and print its owner's name:

```php
\App\Models\Entry::with('user')->latest()->first()->user->name;
```

2. Add `'mood'` to the model's fillable list, then in Tinker:

```php
$user = \App\Models\User::find(1);
$user->entries()->create([
    'title'   => 'A good day',
    'content' => 'Felt productive today.',
    'mood'    => 'happy',
]);
```

(This assumes you kept the `mood` column from the Chapter 5 exercise.)

3. Count a user's entries:

```php
\App\Models\User::find(1)->entries()->count();
```

## Chapter 7 {#chapter-7}

1. Add a footer just before `</body>` in `layout.blade.php`:

```html
<footer class="max-w-2xl mx-auto px-4 py-8 text-center text-xs text-gray-400">
    Catatku - your personal journal
</footer>
```

2. Create the component and use it:

```html
<!-- resources/views/components/empty-state.blade.php -->
<div class="text-center py-16">
    <p class="font-medium text-gray-600">No entries yet</p>
    <a href="/entries/create" class="text-sm text-blue-600 hover:underline">Write now</a>
</div>
```

```html
<!-- in the listing view -->
@empty
    <x-empty-state />
@endforelse
```

3. Estimate reading time on the detail page:

```html
<p class="text-xs text-gray-400">
    {{ max(1, ceil(str_word_count($entry->content) / 200)) }} min read
</p>
```

## Chapter 8 {#chapter-8}

1. Add the rule in the controller:

```php
'title' => 'required|string|min:3|max:255',
```

2. Show a word count hint below the textarea:

```html
<p class="text-xs text-gray-400 mt-1">
    {{ str_word_count(old('content')) }} words
</p>
```

3. Use the array form of rules with a custom message:

```php
$validated = $request->validate([
    'title'   => 'required|string|max:255',
    'content' => 'required|string',
], [
    'title.required' => 'Please give your entry a title.',
]);
```

## Chapter 9 {#chapter-9}

1. Change the redirect target in `update()`:

```php
return redirect('/entries')
    ->with('success', 'Entry updated successfully.');
```

2. Show the edited note conditionally on the detail page:

```html
@if ($entry->updated_at->ne($entry->created_at))
    <span class="text-xs text-gray-400">Edited {{ $entry->updated_at->diffForHumans() }}</span>
@endif
```

3. From the RESTful table: "show edit form" is GET `/entries/{entry}/edit` handled by `edit()`; "save changes" is PUT (or PATCH) `/entries/{entry}` handled by `update()`.

## Chapter 10 {#chapter-10}

1. Add the rule:

```php
'name' => 'required|string|min:2|max:255',
```

2. Add helper text under the password input:

```html
<p class="text-xs text-gray-400 mt-1">Use at least 8 characters.</p>
```

3. Change the redirect in `register()`:

```php
return redirect('/entries/create')
    ->with('success', 'Welcome to Catatku, ' . $user->name . '! Write your first entry.');
```

## Chapter 11 {#chapter-11}

1. Add a checkbox named `remember` to the login form, then read it in the controller:

```php
$remember = $request->boolean('remember');

if (Auth::attempt($credentials, $remember)) {
    $request->session()->regenerate();
    return redirect('/entries')->with('success', 'Welcome back!');
}
```

2. Add a flash message in `logout()`:

```php
return redirect('/login')->with('success', 'You have been logged out.');
```

The layout's existing `@if (session('success'))` block displays it on the login page.

3. Show the entry count in the navigation, inside the `@auth` block of the layout:

```html
<span class="text-sm text-gray-500">
    {{ auth()->user()->name }} ({{ auth()->user()->entries()->count() }})
</span>
```
