---
title: "Laravel 13: Track Every Change with Spatie Activity Log"
slug: "laravel-13-track-every-change-with-spatie-activity-log"
category: "Laravel"
date: "2026-04-04"
status: "published"
---

When multiple users can create, edit, and delete posts, you need to know who did what and when. If a post title was changed yesterday, who changed it? What was the old title? If a published post was reverted to draft, who made that decision? Without an audit trail, you are left guessing, and guessing does not hold up in a content review meeting.

Spatie's Activity Log package solves this by automatically recording every model event (created, updated, deleted) with the user who performed it, what fields changed, and the before/after values. In this tutorial, we will install Spatie Activity Log v5, add automatic logging to our Post model, build a view to display the audit trail, and write Pest tests to verify the logging behavior.


## Overview {#overview}

We will add automatic activity logging to a blog application built with Laravel 13. Every time a post is created, updated, or deleted, the change will be recorded in an `activity_log` table with the authenticated user, the affected model, a description of the event, and a JSON snapshot of the old and new field values.

### What You'll Build

- Automatic activity logging on the Post model using the `LogsActivity` trait.
- A log options configuration that tracks specific fields with before/after snapshots.
- An activity log page that shows who did what, when, and what changed.
- Pest tests that verify logging behavior for create, update, and delete events.

### What You'll Learn

- How to install and configure Spatie Activity Log v5 in Laravel 13.
- How to use the `LogsActivity` trait with `LogOptions` to track model changes.
- How to access logged data via `$activity->attribute_changes`, `$activity->causer`, and `$activity->subject`.
- How to display a before/after diff of field changes in a Blade view.
- How to enable soft-deleted model resolution in activity log subjects.
- How to write tests that assert specific activity log entries exist with correct data.

### What You'll Need

- PHP 8.3 or higher.
- Composer installed globally.
- MySQL or another supported database.
- A Laravel 13 blog project with authentication. You can follow the [CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step) and [auth tutorial](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes) to set up the base project.


## Step 1: Install Spatie Activity Log v5 {#step-1-install-package}

Install the package via Composer:

```bash
composer require spatie/laravel-activitylog
```

The package will automatically register its service provider via Laravel's auto-discovery.

Publish the migration:

```bash
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-migrations"
```

Publish the configuration file:

```bash
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-config"
```

Run the migration:

```bash
php artisan migrate
```

This creates the `activity_log` table with columns for the log name, description, subject (the model that changed), causer (the user who made the change), properties (old/new values as JSON), event type, and timestamps.


## Step 2: Configure the Package {#step-2-configure-package}

Open `config/activitylog.php`. The v5 configuration has a few settings worth reviewing:

```php
return [
    /*
     * If set to false, no activities will be saved to the database.
     */
    'enabled' => env('ACTIVITYLOG_ENABLED', true),

    /*
     * When the clean command is executed, all recording activities older than
     * the number of days specified here will be deleted.
     */
    'clean_after_days' => 365,

    /*
     * If set to true, the subject relationship on activities
     * will include soft deleted models.
     */
    'include_soft_deleted_subjects' => false,

    // ... other settings
];
```

If your Post model uses soft deletes, change `include_soft_deleted_subjects` to `true`:

```php
'include_soft_deleted_subjects' => true,
```

Without this, activity logs for deleted posts would show a null subject because the default Eloquent query excludes soft-deleted records.

Save the file.


## Step 3: Add Activity Logging to the Post Model {#step-3-add-logging-to-model}

Open `app/Models/Post.php` and add the `LogsActivity` trait with a `getActivitylogOptions()` method:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Spatie\Activitylog\Models\Concerns\LogsActivity;
use Spatie\Activitylog\Support\LogOptions;

#[Fillable(['title', 'slug', 'content', 'status', 'user_id'])]
class Post extends Model
{
    use HasFactory, LogsActivity;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['title', 'content', 'status'])
            ->logOnlyDirty()
            ->useLogName('posts')
            ->setDescriptionForEvent(fn (string $eventName) => "Post {$eventName}");
    }
}
```

**Important:** In Spatie Activity Log v5, the trait namespace is `Spatie\Activitylog\Models\Concerns\LogsActivity`. The `LogOptions` class is at `Spatie\Activitylog\Support\LogOptions`.

If your model also uses `SoftDeletes`, add it alongside `LogsActivity`:

```php
use HasFactory, LogsActivity, SoftDeletes;
```

Let's break down each `LogOptions` method:

**`logOnly(['title', 'content', 'status'])`**: Only these three fields will be tracked. Changes to `slug` or `user_id` will not appear in the activity log. This keeps the log focused on meaningful changes.

**`logOnlyDirty()`**: When a post is updated, only the fields that actually changed will be logged. If a user submits the edit form without changing the title, the title will not appear in the log entry.

**`useLogName('posts')`**: Groups all post-related activities under the "posts" log name. This makes it easy to filter activities by type when you have multiple models being logged.

**`setDescriptionForEvent(...)`**: Customizes the description text for each event. The `$eventName` parameter will be `created`, `updated`, or `deleted`. The resulting descriptions will be "Post created", "Post updated", and "Post deleted".

From this point forward, every time a post is created, updated, or deleted, Spatie will automatically insert a row into the `activity_log` table. You do not need to add any logging code to your controllers.

Save the file.


## Step 4: Build the Activity Log Controller and View {#step-4-build-activity-log-view}

### Add the Controller Method

Open `app/Http/Controllers/PostController.php` and add an `activityLog()` method. Add the `use` statement for the Activity model at the top of the file:

```php
use Spatie\Activitylog\Models\Activity;
```

Then add the method:

```php
/**
 * Display the activity log for all posts.
 */
public function activityLog()
{
    $activities = Activity::where('log_name', 'posts')
        ->with('causer')
        ->latest()
        ->paginate(20);

    return view('posts.activity-log', compact('activities'));
}
```

The query fetches all activities from the "posts" log (matching the `useLogName('posts')` we set on the model), eager loads the causer (user) relationship, and paginates the results with 20 items per page.

Save the file.

### Create the View

Create `resources/views/posts/activity-log.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Activity Log</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-7xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="bg-white p-6 md:p-8 rounded-lg shadow-md">
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-3xl font-bold text-gray-900">Activity Log</h1>
                <a href="{{ route('posts.index') }}"
                    class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back
                    to Posts</a>
            </div>

            <div class="overflow-x-auto">
                <table class="min-w-full bg-white border border-gray-200 shadow-sm rounded-lg overflow-hidden">
                    <thead class="bg-gray-50 border-b border-gray-200">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Event
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                User</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Changes
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Date</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200">
                        @forelse($activities as $activity)
                        <tr class="hover:bg-gray-50 transition duration-150">
                            <td class="px-6 py-4 text-sm font-medium text-gray-900">
                                {{ $activity->description }}
                            </td>
                            <td class="px-6 py-4 text-sm text-gray-500">
                                {{ $activity->causer?->name ?? 'System' }}
                            </td>
                            <td class="px-6 py-4 text-sm text-gray-500">
                                @php
                                $changes = $activity->attribute_changes;
                                @endphp
                                @if($changes && isset($changes['old']) && isset($changes['attributes']))
                                @foreach($changes['attributes'] as $key => $newValue)
                                @if(isset($changes['old'][$key]) && $changes['old'][$key] !== $newValue)
                                <div class="mb-1">
                                    <span class="font-medium text-gray-700">{{ $key }}:</span>
                                    <span class="text-red-500 line-through">{{ $changes['old'][$key] }}</span>
                                    <span class="mx-1">to</span>
                                    <span class="text-green-600">{{ $newValue }}</span>
                                </div>
                                @endif
                                @endforeach
                                @elseif($changes && isset($changes['old']) && !isset($changes['attributes']))
                                @foreach($changes['old'] as $key => $value)
                                <div class="mb-1">
                                    <span class="font-medium text-gray-700">{{ $key }}:</span>
                                    <span class="text-red-500 line-through">{{ $value }}</span>
                                </div>
                                @endforeach
                                @elseif($changes && isset($changes['attributes']))
                                @foreach($changes['attributes'] as $key => $value)
                                <div class="mb-1">
                                    <span class="font-medium text-gray-700">{{ $key }}:</span>
                                    <span class="text-green-600">{{ $value }}</span>
                                </div>
                                @endforeach
                                @else
                                <span class="text-gray-400">No details</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
                                {{ $activity->created_at->format('M d, Y H:i') }}
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" class="px-6 py-4 text-center text-sm text-gray-500">No activity recorded yet.</td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <div class="mt-6">
                {{ $activities->links() }}
            </div>
        </div>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
            target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>

</html>

```

The Changes column handles three cases:

- **Update events**: Both `old` and `attributes` (new values) are present. We display a before/after diff with the old value struck through in red and the new value in green. We also check that the values are actually different to avoid showing unchanged fields.
- **Create events**: Only `attributes` are present (no old values), so we display the initial values.
- **Delete events**: The `attribute_changes` may contain only `old` values or be empty, so we show "No details".

**Note:** Use `$activity->attribute_changes` to access the old/new values collection. This accessor returns a structured collection with `attributes` and `old` keys, which is the recommended way to read the change data.

Save the file.


## Step 5: Register the Route {#step-5-register-route}

Open `routes/web.php` and add the activity log route. Place it before `Route::resource()` alongside other custom routes:

```php
Route::get('/posts/activity-log', [PostController::class, 'activityLog'])->name('posts.activity-log');
```

Optionally, add a link to the activity log page in your index view:

```html
<a href="{{ route('posts.activity-log') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">
    Activity Log
</a>
```

Save the files.


## Step 6: Install Pest and Write Tests {#step-6-install-pest-and-write-tests}

If you have not installed Pest yet, replace PHPUnit:

```bash
composer remove phpunit/phpunit
composer require pestphp/pest --dev --with-all-dependencies
./vendor/bin/pest --init
```

Create the test file:

```bash
php artisan make:test ActivityLogTest --pest
```

Open `tests/Feature/ActivityLogTest.php`:

```php
<?php

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Activitylog\Models\Activity;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->user = User::factory()->create();
});

// ============================================================
// Automatic Logging Tests
// ============================================================

test('creating a post logs a created activity', function () {
    $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Logged Post',
        'content' => 'This should be logged.',
        'status' => 'publish',
    ]);

    $activity = Activity::where('log_name', 'posts')->latest()->first();

    $this->assertNotNull($activity);
    $this->assertEquals('Post created', $activity->description);
    $this->assertEquals($this->user->id, $activity->causer_id);

    $changes = $activity->attribute_changes;
    $this->assertEquals('Logged Post', $changes['attributes']['title']);
});

test('updating a post logs an updated activity with old and new values', function () {
    $post = Post::factory()->create([
        'user_id' => $this->user->id,
        'title' => 'Original Title',
    ]);

    $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => 'Updated Title',
        'content' => $post->content,
        'status' => $post->status,
    ]);

    $activity = Activity::where('log_name', 'posts')
        ->where('description', 'Post updated')
        ->latest()
        ->first();

    $this->assertNotNull($activity);

    $changes = $activity->attribute_changes;
    $this->assertEquals('Original Title', $changes['old']['title']);
    $this->assertEquals('Updated Title', $changes['attributes']['title']);
});

test('deleting a post logs a deleted activity', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $activity = Activity::where('log_name', 'posts')
        ->where('description', 'Post deleted')
        ->latest()
        ->first();

    $this->assertNotNull($activity);
    $this->assertEquals($this->user->id, $activity->causer_id);
});

test('updating a post without changing tracked fields does not create a log entry', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    // Count existing activities
    $countBefore = Activity::where('log_name', 'posts')
        ->where('description', 'Post updated')
        ->count();

    // Submit the same data (no changes to tracked fields)
    $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => $post->title,
        'content' => $post->content,
        'status' => $post->status,
    ]);

    $countAfter = Activity::where('log_name', 'posts')
        ->where('description', 'Post updated')
        ->count();

    $this->assertEquals($countBefore, $countAfter);
});

// ============================================================
// Activity Log Page Tests
// ============================================================

test('activity log page displays logged activities', function () {
    Post::factory()->create(['user_id' => $this->user->id, 'title' => 'Activity Test']);

    $response = $this->actingAs($this->user)->get(route('posts.activity-log'));

    $response->assertStatus(200);
    $response->assertSee('Post created');
});

test('activity log page shows empty state when no activities exist', function () {
    $response = $this->actingAs($this->user)->get(route('posts.activity-log'));

    $response->assertStatus(200);
    $response->assertSee('No activity recorded yet.');
});
```

The tests verify six behaviors: create events are logged with causer and attribute values, update events include old and new values, delete events are logged, no-change updates are skipped (thanks to `logOnlyDirty()`), the activity log page displays entries, and the page shows an empty state.

Save the file.


## Step 7: Run the Tests {#step-7-run-tests}

```bash
php artisan test --filter=ActivityLogTest
```

All 6 tests should pass.


## Step 8: Try It Out {#step-8-try-it-out}

Start the development server:

```bash
php artisan serve
```

1. Log in and create a new post.
2. Edit the post and change the title.
3. Delete the post.
4. Navigate to the activity log page.
5. You should see three entries: "Post created", "Post updated", and "Post deleted".
6. The "Post updated" entry should show the old title crossed out in red and the new title in green.
7. Each entry displays the username and the timestamp.


## How Spatie Activity Log v5 Stores Data {#how-activity-log-stores-data}

Each row in the `activity_log` table contains:

| Column | Description | Example |
|--------|-------------|---------|
| `log_name` | The log group name | `posts` |
| `description` | What happened | `Post updated` |
| `subject_type` | The model class | `App\Models\Post` |
| `subject_id` | The model ID | `1` |
| `causer_type` | The user model class | `App\Models\User` |
| `causer_id` | The user ID | `3` |
| `properties` | JSON with old/new values | `{"attributes": {"title": "New"}, "old": {"title": "Old"}}` |
| `event` | The event name | `updated` |
| `created_at` | When the action occurred | `2026-04-03 10:15:00` |

The `properties` column stores the raw JSON data. In your code, use `$activity->attribute_changes` to access the structured collection with `attributes` and `old` keys. This accessor is the recommended way in v5 to read the change data.


## Conclusion {#conclusion}

In this tutorial, we added automatic activity logging to our blog application using Spatie Activity Log v5. Every create, update, and delete action is now recorded with the user who performed it, the affected model, and a before/after snapshot of the changed fields.

Here are the key takeaways:

- **`LogsActivity` trait makes logging automatic.** Once added to the model, every create, update, and delete event is logged without any changes to your controllers.
- **`LogOptions` gives fine-grained control.** Use `logOnly()` to track specific fields, `logOnlyDirty()` to skip unchanged values, `useLogName()` to group logs, and `setDescriptionForEvent()` to customize descriptions.
- **Use `$activity->attribute_changes` to access change data.** This accessor returns a structured collection with `attributes` and `old` keys for easy before/after comparison.
- **The trait namespace is `Spatie\Activitylog\Models\Concerns\LogsActivity`.** Make sure to use the correct import path when adding the trait to your model.
- **Enable `include_soft_deleted_subjects` if you use soft deletes.** Without this, activity logs for deleted models will have null subjects.
- **`logOnlyDirty()` prevents noisy logs.** If a user submits a form without changing any tracked fields, no activity is recorded. This keeps the log clean and meaningful.
- **Activity logging works with any model.** While we applied it to posts, you can add the `LogsActivity` trait to any Eloquent model (users, comments, orders, etc.) with its own `LogOptions` configuration.