## 1. Before You Begin

In the beginner course, Catatku entries are private: each user only sees their own entries. But what happens if someone manually types `/entries/42/edit` in the browser, where entry 42 belongs to another user? Without authorization, they could see or modify someone else's diary entry. Authentication answers "who are you?" Authorization answers "what are you allowed to do?" This lesson closes that security gap.

Laravel provides two tools for authorization: Gates for simple closure-based checks (like "is this user an admin?") and Policies for model-specific rules (like "can this user edit this entry?"). Policies are the standard approach for CRUD authorization and integrate cleanly with controllers and Blade views. By the end of this lesson, Catatku will correctly reject attempts by User B to read or modify User A's entries, no matter how those attempts are made.

### What You'll Build

You will create an `EntryPolicy` that restricts viewing, editing, and deleting entries to the entry's owner. You will also add an admin bypass using `Gate::before()`.

### What You'll Learn

- ✅ Creating Policies with `make:policy`
- ✅ Policy methods: `view`, `update`, `delete`
- ✅ Using `$this->authorize()` in controllers
- ✅ Using `@can` and `@cannot` in Blade views
- ✅ Gates for simple authorization checks
- ✅ Admin bypass with `Gate::before()`

### What You'll Need

- Lesson 4 completed

---

## 2. Create an Entry Policy

A Policy groups authorization logic for a specific model. Laravel auto-discovers policies when they follow the naming convention: `EntryPolicy` for the `Entry` model. This naming convention is similar to how migrations, controllers, and factories follow predictable naming patterns to reduce configuration.

### Step 1: Generate the Policy

Run the following Artisan command to create the policy file with pre-built method signatures.

```bash
php artisan make:policy EntryPolicy --model=Entry
```

This creates `app/Policies/EntryPolicy.php` with skeleton methods for each CRUD action. The `--model=Entry` flag tells Artisan to generate method signatures that accept the Entry model as their second parameter, saving you from writing them manually.

### Step 2: Define the Authorization Rules

Open `app/Policies/EntryPolicy.php` and replace the content with the following.

```php
<?php

namespace App\Policies;

use App\Models\Entry;
use App\Models\User;

class EntryPolicy
{
    public function view(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }

    public function update(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }

    public function delete(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }
}
```

Let us walk through this Policy carefully. The `namespace App\Policies;` declaration matches the directory structure. The `use` statements import the two model classes so they can be type-hinted as parameters. The class is named `EntryPolicy` to match Laravel's auto-discovery convention: Laravel looks for `{ModelName}Policy` in the `app/Policies` directory when checking permissions for that model. Each method receives the authenticated `User` as the first parameter and the `Entry` being accessed as the second parameter, and returns `true` if the action is allowed or `false` if it should be denied.

The logic is the same for all three actions: compare the user's ID with the entry's `user_id`. If they match, the user is the owner and the action is permitted. Because Catatku is a private journal application, even viewing is restricted to the owner. In a public blog application, you might allow anyone to view but restrict editing to the author.

### Step 3: Apply in the Controller

Open `app/Http/Controllers/EntryController.php` and update the methods that access a specific entry. In Laravel 13, controllers no longer ship with an `authorize()` helper by default — use `Gate::authorize()` from the `Gate` facade instead, which behaves identically: it throws a 403 Forbidden exception if the Policy method returns `false`. Add the `Gate` import alongside the existing `use` statements. These calls also replace the manual `if ($entry->user_id !== auth()->id()) { abort(403); }` checks from the basic course.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;

class EntryController extends Controller
{
    // ... other methods

    public function show(Entry $entry)
    {
        Gate::authorize('view', $entry);

        $entry->load('comments.user', 'tags');

        return view('entries.show', compact('entry'));
    }

    public function edit(Entry $entry)
    {
        Gate::authorize('update', $entry);

        $tags = Tag::orderBy('name')->get();

        return view('entries.edit', compact('entry', 'tags'));
    }

    public function update(Request $request, Entry $entry)
    {
        Gate::authorize('update', $entry);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        $entry->update([
            'title' => $validated['title'],
            'content' => $validated['content'],
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);

        return redirect()->route('entries.index')->with('success', 'Entry updated!');
    }

    public function destroy(Entry $entry)
    {
        Gate::authorize('delete', $entry);

        $entry->delete();

        return redirect()->route('entries.index')->with('success', 'Entry deleted.');
    }

    public function restore(Entry $entry)
    {
        Gate::authorize('update', $entry);

        $entry->restore();

        return redirect()->route('entries.trash')->with('success', 'Entry restored!');
    }

    // ... other methods
}
```

Examining the pattern in each method: the very first line of each action that touches a specific entry is `Gate::authorize('ability_name', $entry)`. For `show`, we authorize `view`; for `edit`, `update`, and `restore`, we authorize `update`; for `destroy`, we authorize `delete`. The first argument is the ability name as a string, which must match a method name on the Policy. The second argument is the entry being checked.

If the Policy method returns `false`, Laravel automatically throws a 403 Forbidden HTTP exception, renders the default 403 error page, and the controller code below the `Gate::authorize()` call never runs. You do not need to write if/else logic or redirect manually. Notice that we place `Gate::authorize()` before validation and before any other work, because there is no point validating or processing data the user is not allowed to touch.

### Step 4: Use in Blade Views

Open `resources/views/components/entry-card.blade.php`. In the action buttons section, replace the existing Edit and Delete buttons with the `@can`-wrapped versions below so they are only shown to the entry owner.

```blade
{{-- Action buttons --}}
<div class="flex items-center gap-3 pt-3 border-t border-gray-100">
    <a href="/entries/{{ $entry->id }}" class="text-xs text-blue-600 hover:text-blue-800">
        Read
    </a>
    @can('update', $entry)
    <a href="{{ route('entries.edit', $entry) }}" class="text-xs text-gray-500 hover:text-gray-800">
        Edit
    </a>
    @endcan
    @can('delete', $entry)
    <form method="POST" action="{{ route('entries.destroy', $entry) }}" onsubmit="return confirm('Delete this entry?')"
        class="ml-auto">
        @csrf
        @method('DELETE')
        <button type="submit" class="text-xs text-red-400 hover:text-red-600">
            Delete
        </button>
    </form>
    @endcan
</div>
```

The `@can('update', $entry)` directive renders the enclosed HTML only if the current user is authorized according to the Policy's `update` method. The `@endcan` closes the block. This hides buttons that the user cannot use, which improves the user experience. However, hiding buttons is not enough for security on its own. A determined user could POST directly to the delete endpoint using curl without clicking any button. The real security enforcement happens in the controller's `Gate::authorize()` call. Always use both: `@can` for UX and `Gate::authorize()` for security.

After the change, the full `entry-card.blade.php` looks like this:

```blade
@props(['entry'])

<div class="bg-white rounded-xl border border-gray-200 p-5 hover:border-gray-300 transition-colors">

    {{-- Header: title and date --}}
    <div class="flex items-start justify-between gap-3 mb-3">
        <a href="/entries/{{ $entry->id }}" class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
            {{ $entry->title }}
        </a>
        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    {{-- Content snippet --}}
    <p class="text-sm text-gray-500 line-clamp-2 mb-2">
        {{ $entry->excerpt }}
    </p>
    <span style="color: #9ca3af; font-size: 0.8em;">
        {{ $entry->reading_time }} min read · {{ $entry->created_at_human }}
    </span>

    {{-- Tags --}}
    @if($entry->tags->isNotEmpty())
        <div style="margin-top: 8px; display: flex; flex-wrap: wrap; gap: 4px;">
            @foreach ($entry->tags as $tag)
                <span style="background: #dbeafe; color: #1e40af; padding: 2px 10px; border-radius: 12px; font-size: 0.75em; font-weight: 600;">
                    {{ $tag->name }}
                </span>
            @endforeach
        </div>
    @endif

    {{-- Action buttons --}}
    <div class="flex items-center gap-3 pt-3 border-t border-gray-100">
        <a href="/entries/{{ $entry->id }}" class="text-xs text-blue-600 hover:text-blue-800">
            Read
        </a>
        @can('update', $entry)
        <a href="{{ route('entries.edit', $entry) }}" class="text-xs text-gray-500 hover:text-gray-800">
            Edit
        </a>
        @endcan
        @can('delete', $entry)
        <form method="POST" action="{{ route('entries.destroy', $entry) }}" onsubmit="return confirm('Delete this entry?')"
            class="ml-auto">
            @csrf
            @method('DELETE')
            <button type="submit" class="text-xs text-red-400 hover:text-red-600">
                Delete
            </button>
        </form>
        @endcan
    </div>

</div>
```

---

## 3. Gates for Admin Bypass

Gates are simpler than Policies. They are closures defined in a service provider rather than a dedicated class. The `Gate::before()` method runs before any Policy check and can override the result, which is exactly what we need for admin users who should be able to perform any action.

### Step 1: Add Admin Bypass

Open `app/Providers/AppServiceProvider.php` and add the `Gate::before()` call inside the `boot()` method of the `AppServiceProvider` class.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;

class AppServiceProvider extends ServiceProvider
{
    // ... other methods

    public function boot(): void
    {
        Gate::before(function ($user) {
            if ($user->email === 'admin@example.com') {
                return true;
            }
        });
    }
}
```

Examining this snippet: `Gate::before()` registers a closure that runs before every Policy check across the entire application. The closure receives the authenticated user. If the user's email matches the admin value, we return `true`, which short-circuits all Policy checks and allows the action. If the condition is false, the closure returns nothing (PHP implicitly returns `null`), and Laravel then proceeds with the normal Policy check. This means the admin user can view, edit, and delete any entry without the Policy needing to know about admins. In production, you would use a database column like `is_admin` instead of checking the email, but the pattern is identical.

---

## 4. Run and Test

Let us verify that authorization works correctly from both the browser and Tinker.

### Step 1: Test as the Owner

Start the server and log in with your existing account.

```bash
php artisan serve
```

Navigate to one of your entries. You should see the Edit and Delete buttons because the Policy's `update` and `delete` methods return `true` for the owner. Click Edit to verify you can access the edit form. Click Delete to verify the entry is soft-deleted successfully.

### Step 2: Test Authorization Failure

The easiest way to test rejection is through Tinker. Create a second user and check the authorization result programmatically.

```bash
php artisan tinker
```

Run the following commands one at a time to compare how different users are evaluated against the same policy.

```php
$user2 = \App\Models\User::factory()->create([
    'email' => 'test2@example.com',
    'password' => bcrypt('password'),
]);

$entry = \App\Models\Entry::first();

$user2->can('update', $entry);

$entry->user->can('update', $entry);
```

`$user2->can('update', $entry)` evaluates the Policy's `update` method with the second user and the entry, returning `false` because the IDs do not match. `$entry->user->can('update', $entry)` does the same check for the entry's actual owner, returning `true`. The `can` method on a User model is the programmatic equivalent of the `@can` Blade directive, and you can use it anywhere you need to check permissions outside of a controller. Type `exit` to leave Tinker.

### Step 3: Test in the Browser

Log out, then log in as the second user you just created. Now manually navigate to `/entries/{id}/edit` where `{id}` is an entry belonging to the first user. You should see a 403 Forbidden error page instead of the edit form, confirming that the controller blocks unauthorized access even when the UI does not link to the page.

### Step 4: Test Admin Bypass (Optional)

Create a user with email `admin@example.com`, log in as them, and try to edit another user's entry. Because `Gate::before()` returns `true` for this email, you should be able to access the edit form. This proves the admin override works while leaving normal users appropriately restricted.

---

## 5. Fix the Errors in Your Code

These are the most common mistakes when implementing authorization with Gates and Policies in Laravel.

**Error 1: Calling `authorize()` without passing the model instance.**

This error occurs when you call `$this->authorize()` with only the ability name but forget to pass the model instance. Laravel needs the model to call the correct Policy method with the right arguments.

```php
// Wrong: no entry passed, Laravel cannot call the Policy method
$this->authorize('update');

// Correct: pass the entry so the Policy receives it as the second argument
$this->authorize('update', $entry);
```

Without the second argument, Laravel does not know which entry to check authorization against. The Policy's `update(User $user, Entry $entry)` method expects an entry, so the call fails with an error about missing arguments. The correct version passes `$entry`, giving the Policy everything it needs to compare user IDs.

---

**Error 2: Policy class named incorrectly, breaking auto-discovery.**

This error occurs when you name the Policy class something other than `{ModelName}Policy`. Laravel's auto-discovery mechanism looks for this exact pattern, so a differently named class is never found automatically.

```php
// Wrong: class named EntryAuth instead of EntryPolicy
// Laravel looks for EntryPolicy, not EntryAuth
class EntryAuth
{
    public function update(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }
}

// Correct: follows the ModelNamePolicy naming convention
class EntryPolicy
{
    public function update(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }
}
```

The wrong version uses `EntryAuth`, which Laravel cannot auto-discover. Every `authorize('update', $entry)` call falls through without hitting any policy, and the result is either always allowed or always denied depending on your configuration. The correct version uses `EntryPolicy`, which Laravel finds automatically. If you must use a custom name, register the mapping manually in `AppServiceProvider::boot()` using `Gate::policy(Entry::class, EntryAuth::class)`.

---

**Error 3: Policy method returns void instead of bool.**

This error occurs when a developer writes the policy method to call `abort(403)` directly instead of returning a boolean. Policy methods must return `bool`; if the method returns `void` or `null`, the authorization check always fails or produces unexpected behavior.

```php
// Wrong: calling abort() inside a policy method bypasses the framework's response flow
public function update(User $user, Entry $entry): void
{
    if ($user->id !== $entry->user_id) {
        abort(403);
    }
}

// Correct: return bool and let authorize() handle the 403 response
public function update(User $user, Entry $entry): bool
{
    return $user->id === $entry->user_id;
}
```

The wrong version uses `void` as the return type and calls `abort(403)` inside the policy. While this can work in some cases, it bypasses the framework's clean authorization flow: the policy is supposed to return a decision, not produce a response. The correct version returns `true` or `false`, and `$this->authorize()` in the controller is responsible for throwing the 403 exception when it receives `false`.

---

## 6. Exercises

Practice applying the authorization patterns from this lesson to parts of Catatku that are not yet protected. Each exercise extends what you built without requiring changes to the core policy logic you already wrote.

**Exercise 1:** Create a `CommentPolicy` with a `delete` method that allows only the comment author to delete their comment. Apply it in the `CommentController@destroy` method.

**Exercise 2:** Add an `is_admin` boolean column to the users table. Update the `Gate::before()` check to use this column instead of email comparison.

**Exercise 3:** Add a `viewAny` method to `EntryPolicy` that always returns `true` (everyone can view the entry list). Use `$this->authorize('viewAny', Entry::class)` in the index method (note: the second argument is the class, not an instance).

---

## 7. Solutions

Each solution below is complete and directly applicable to your Catatku project. Read the narrative after each code block to understand how the pieces connect before moving on to the next exercise.

**Solution for Exercise 1:**

Run the Artisan command to generate the policy file.

```bash
php artisan make:policy CommentPolicy --model=Comment
```

Open `app/Policies/CommentPolicy.php` and add the delete method.

```php
<?php

namespace App\Policies;

use App\Models\Comment;
use App\Models\User;

class CommentPolicy
{
    public function delete(User $user, Comment $comment): bool
    {
        return $user->id === $comment->user_id;
    }
}
```

This follows the same pattern as `EntryPolicy`: compare the authenticated user's ID with the record's `user_id`. In `app/Http/Controllers/CommentController.php`, add `Gate::authorize()` as the first line of the `destroy` method in the `CommentController` class.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;

class CommentController extends Controller
{
    // ... other methods

    public function destroy(Comment $comment)
    {
        Gate::authorize('delete', $comment);

        $comment->delete();

        return back()->with('success', 'Comment deleted.');
    }
}
```

`Gate::authorize('delete', $comment)` calls `CommentPolicy::delete()` with the current user and the comment. If the IDs do not match, Laravel throws a 403 exception before `$comment->delete()` is ever reached.

---

**Solution for Exercise 2:**

Create and run a migration to add the `is_admin` column to the users table.

```bash
php artisan make:migration add_is_admin_to_users --table=users
```

In the migration file, add the column definition.

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->boolean('is_admin')->default(false);
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('is_admin');
    });
}
```

Run the migration, then update `AppServiceProvider::boot()` to use the database column instead of email comparison.

```php
Gate::before(function ($user) {
    if ($user->is_admin) {
        return true;
    }
});
```

The `$user->is_admin` expression reads the boolean column directly from the model. This approach is more maintainable than email comparison because you can grant or revoke admin status through the database without redeploying code.

---

**Solution for Exercise 3:**

Open `app/Policies/EntryPolicy.php` and add the `viewAny` method inside the class body.

```php
public function viewAny(User $user): bool
{
    return true;
}
```

Unlike `view`, `update`, and `delete`, the `viewAny` method receives only the authenticated user and no model instance. This is because the action targets the list as a whole, not any single entry. Returning `true` unconditionally means every authenticated user may access the entry index. In `app/Http/Controllers/EntryController.php`, add `Gate::authorize()` as the first line of the `index` method in the `EntryController` class.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request)
    {
        Gate::authorize('viewAny', Entry::class);

        $query = auth()->user()->entries()->with('tags')->withCount('comments');

        if ($request->filled('search')) {
            $query->search($request->input('search'));
        }

        $entries = $query->latest()->paginate(15);

        return view('entries.index', compact('entries'));
    }

    // ... other methods
}
```

Notice that the second argument to `Gate::authorize()` is `Entry::class`, the class name as a string, rather than a model instance. Laravel uses this to locate the right policy (`EntryPolicy`) and call its `viewAny` method. Passing a class instead of an instance is required whenever the action does not involve a specific record. If you later want to restrict the listing to admin users only, you can change the return value to `return $user->is_admin;` without touching the controller.

---

## Next Up - Lesson 6

In this lesson you added a complete authorization layer to Catatku using Laravel's Policy system. You created `EntryPolicy` with `view`, `update`, and `delete` methods that each compare the authenticated user's ID with the entry's `user_id`. You applied `$this->authorize()` in every controller method that accesses a specific entry, ensuring that unauthorized requests are rejected with a 403 response regardless of how they arrive. You used the `@can` Blade directive to hide UI controls for unauthorized users, and you added a `Gate::before()` callback to give admin users a bypass across all policies.

In Lesson 6, you will learn middleware and route protection: how to create custom middleware, how to organize routes into middleware groups, and how to apply rate limiting to prevent abuse.