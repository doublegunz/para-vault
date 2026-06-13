## 1. Before You Begin

When a user posts a comment in Catatku, several things should happen: save the comment, send an email to the entry author, maybe update a "recent activity" cache, maybe log it for analytics. Cramming all of this into the controller mixes unrelated responsibilities and makes the controller harder to read and test. Events let you announce that something happened, and listeners let other parts of the system react to it independently. This separation keeps each piece of code focused on a single responsibility.

Laravel's event system implements the observer pattern. Your code dispatches events at meaningful moments (like "a comment was posted"), and listeners handle the side effects. Listeners are independent: adding a new listener does not require changing the code that dispatches the event. This makes it easy to add features like notifications, analytics, and caching without touching the core logic. By the end of this lesson, Catatku will use events instead of direct side-effect calls, making the codebase more modular and easier to extend.

### What You'll Build

You will create a `CommentPosted` event, refactor the CommentController to dispatch it, and create multiple listeners: one for email notifications, one for logging, and one for updating a last-activity timestamp.

### What You'll Learn

- ✅ Creating events with `make:event`
- ✅ Creating listeners with `make:listener`
- ✅ Registering events and listeners
- ✅ Dispatching events
- ✅ Queueable listeners
- ✅ Model observers (another event pattern)

### What You'll Need

- Lesson 13 completed with queues working

---

## 2. Why Events?

Without events, the controller calls every side effect directly. The following example shows a store method that handles comment creation along with all its side effects.

```php
public function store(Request $request, Entry $entry)
{
    $comment = $entry->comments()->create([...]);

    if ($entry->user_id !== $request->user()->id) {
        Mail::to($entry->user)->send(new NewCommentEmail($comment, $entry));
    }
    Log::info("Comment posted", ['comment_id' => $comment->id]);
    Cache::forget("user.{$entry->user_id}.activity");

    return back();
}
```

Every time you add a new side effect, you modify the controller. The method grows, mixing concerns that have nothing to do with the core action of creating a comment. Testing becomes harder because one test file has to know about every side effect. Any future change (adding Slack notification, removing the cache line) requires modifying a controller that should only be responsible for form handling and HTTP responses.

With events, the controller becomes dramatically simpler.

```php
public function store(Request $request, Entry $entry)
{
    $comment = $entry->comments()->create([...]);
    CommentPosted::dispatch($comment);
    return back();
}
```

The controller dispatches one event and returns. Listeners registered elsewhere handle every side effect. Adding a new behavior like posting to a Slack channel means creating a new listener file, not modifying the controller. This is the Open/Closed Principle in action: classes are open for extension (add listeners) but closed for modification (the controller stays unchanged).

---

## 3. Create the Event

An event class is a plain PHP object that carries data about what happened. It has no behavior of its own — its job is to hold enough information for listeners to act on. In this section you will generate the `CommentPosted` event and define the data it carries.

### Step 1: Generate the Event Class

Run the following command to create the event class.

```bash
php artisan make:event CommentPosted
```

This creates `app/Events/CommentPosted.php` with a skeleton structure. An event class is essentially a data container: it holds the information that listeners need to react appropriately.

### Step 2: Define the Event

Open `app/Events/CommentPosted.php` and replace its content with the following.

```php
<?php

namespace App\Events;

use App\Models\Comment;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CommentPosted
{
    use Dispatchable, SerializesModels;

    public function __construct(public Comment $comment) {}
}
```

Let us look at every part of this class carefully. The namespace `App\Events` matches the directory. The two traits add important functionality. `Dispatchable` provides the static `dispatch()` method so you can call `CommentPosted::dispatch($comment)` from anywhere in the application. Behind the scenes, `dispatch()` creates a new instance of the event and sends it through Laravel's event dispatcher to all registered listeners. `SerializesModels` handles serialization correctly when any listener is queued: it stores Eloquent models by their primary key rather than as a full in-memory object, and reloads them from the database when the listener runs. This prevents stale model data when there is a delay between dispatch and execution. The constructor uses constructor property promotion (`public Comment $comment`) to declare and assign the property in a single line. The event carries the comment so every listener has the context it needs to decide whether and how to react.

---

## 4. Create Listeners

Each listener is responsible for exactly one side effect. In this section you will create three listeners for the `CommentPosted` event: one that sends the notification email, one that logs the activity, and one that updates the entry's last-activity timestamp. Each is a separate class so they can be tested, modified, and removed independently.

### Step 1: Create the Email Notification Listener

Run the following command to generate the listener, pre-wired to handle the `CommentPosted` event.

```bash
php artisan make:listener SendCommentNotification --event=CommentPosted
```

This creates `app/Listeners/SendCommentNotification.php` with a skeleton `handle()` method already typed for the `CommentPosted` event. Open the file and replace its content with the following.

```php
<?php

namespace App\Listeners;

use App\Events\CommentPosted;
use App\Mail\NewCommentEmail;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Mail;

class SendCommentNotification implements ShouldQueue
{
    public function handle(CommentPosted $event): void
    {
        $comment = $event->comment;
        $entry = $comment->entry;

        if ($comment->user_id === $entry->user_id) {
            return;
        }

        Mail::to($entry->user)->send(new NewCommentEmail($comment, $entry));
    }
}
```

Reading through this listener in detail: the class implements `ShouldQueue`, which means this listener runs on the queue when the event is dispatched. The user who posted the comment does not wait for the email to send; the listener is deferred to a background worker. The `handle()` method receives the `CommentPosted` event as a parameter (Laravel injects it automatically based on the type hint). Inside, we extract the comment and entry from the event for readability. The `if ($comment->user_id === $entry->user_id)` check returns early when the commenter is also the entry author, preventing self-notification. Then we send the email. Notice how this listener focuses on exactly one responsibility: decide whether to send the notification, then send it. It does not log, update timestamps, or do anything else, which keeps it independently testable.

### Step 2: Create the Logging Listener

Generate the logging listener with the following command.

```bash
php artisan make:listener LogCommentActivity --event=CommentPosted
```

Open `app/Listeners/LogCommentActivity.php` and replace its content with the following.

```php
<?php

namespace App\Listeners;

use App\Events\CommentPosted;
use Illuminate\Support\Facades\Log;

class LogCommentActivity
{
    public function handle(CommentPosted $event): void
    {
        Log::info('Comment posted', [
            'comment_id' => $event->comment->id,
            'entry_id' => $event->comment->entry_id,
            'user_id' => $event->comment->user_id,
        ]);
    }
}
```

This listener is simpler than the previous one. It writes a structured log entry with the relevant IDs for debugging and analytics. Notice that it does not implement `ShouldQueue`: logging is fast (just a file write), so there is no benefit to deferring it. Synchronous listeners run immediately in the same request cycle, while queued listeners run later in the background worker. You choose per listener based on whether the work is slow enough to warrant deferring.

### Step 3: Create the Activity Update Listener

Generate the activity update listener.

```bash
php artisan make:listener UpdateEntryLastActivity --event=CommentPosted
```

Open `app/Listeners/UpdateEntryLastActivity.php` and replace its content with the following.

```php
<?php

namespace App\Listeners;

use App\Events\CommentPosted;

class UpdateEntryLastActivity
{
    public function handle(CommentPosted $event): void
    {
        $event->comment->entry->touch();
    }
}
```

The `touch()` method updates the `updated_at` timestamp on the entry without modifying any other column. This effectively marks the entry as recently active. If you order entries by `updated_at` on the index page, entries with recent comments will appear higher in the list. Encapsulating this in its own listener means the comment controller has no knowledge of this behavior. If you later want to use a dedicated `last_activity_at` column instead, you change only this listener file.

---

## 5. Register and Dispatch the Event

With the event and listeners created, the remaining steps are to register the listeners so Laravel knows which events they handle, and to update the controller to dispatch the event in place of its previous direct side-effect calls.

### Step 1: Laravel Auto-Discovery

Laravel 11+ automatically discovers listeners when their `handle()` method type-hints the event class. All three listeners we created type-hint `CommentPosted $event`, so no manual registration in an `EventServiceProvider` is needed. The auto-discovery system scans the `app/Listeners` directory and wires listeners to events based on the `handle()` parameter type. This simplifies setup considerably compared to older versions of Laravel.

### Step 2: Dispatch from the Controller

Open `app/Http/Controllers/CommentController.php` and update the `store` method to dispatch the event.

```php
<?php
// ... others lines of code

use App\Events\CommentPosted;

class CommentController extends Controller
{
    public function store(Request $request, Entry $entry)
    {
        $validated = $request->validate([
            'body' => 'required|string|min:2|max:1000',
        ]);

        $comment = $entry->comments()->create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        CommentPosted::dispatch($comment);

        return back()->with('success', 'Comment posted!');
    }
}
```

The controller is now smaller and focused on its core job: validate input, create the comment, announce the event, and redirect. The `CommentPosted::dispatch($comment)` line fires the event, and Laravel notifies every registered listener in the correct order. The three listeners all run: `LogCommentActivity` runs synchronously in the request, `SendCommentNotification` is queued for the background worker, and `UpdateEntryLastActivity` runs synchronously as well. Crucially, the controller has no idea how many listeners exist or what they do. This is the heart of event-driven architecture.

---

## 6. Model Observers

Another event pattern in Laravel is the model observer. Observers listen to model lifecycle events: `creating`, `created`, `updating`, `updated`, `deleting`, `deleted`. Instead of dispatching events manually, Laravel fires them automatically when models change. This is useful for logic that should always run when a model is modified, regardless of how it was modified (controller, Tinker, queue job, anything).

### Step 1: Create an Entry Observer

Generate the observer class for the Entry model.

```bash
php artisan make:observer EntryObserver --model=Entry
```

Open `app/Observers/EntryObserver.php` and implement two lifecycle methods.

```php
<?php

namespace App\Observers;

use App\Models\Entry;
use Illuminate\Support\Facades\Log;

class EntryObserver
{
    public function created(Entry $entry): void
    {
        Log::info('New entry created', [
            'entry_id' => $entry->id,
            'user_id'  => $entry->user_id,
            'title'    => $entry->title,
        ]);
    }

    public function deleted(Entry $entry): void
    {
        if ($entry->cover_image) {
            \Storage::disk('public')->delete($entry->cover_image);
        }
    }
}
```

Let us look at each method. The `created` method runs after the entry is successfully saved to the database (the past-tense name indicates the event fires after the INSERT statement completes). This is the right moment for side effects that need the new record's `id` to be set, such as logging or notifying other systems. The `Log::info()` call writes a structured entry to `storage/logs/laravel.log` with the new entry's `id`, author, and title, giving you a permanent audit trail of every entry ever created — without changing the `Entry` model or adding a column to the database.

The `deleted` method runs after the entry is removed from the database (the past-tense name indicates the event fires after the DELETE statement). We use this to clean up the cover image file from disk. This is a powerful pattern: no matter how an entry gets deleted (from a controller, from Tinker, from a queue job, from a seeder), the cover image cleanup always runs because the observer is attached to the model itself, not to any specific caller.

### Step 2: Register the Observer

Open `app/Providers/AppServiceProvider.php` and register the observer in the `boot()` method.

```php
<?php
// ... others lines of code

use App\Models\Entry;
use App\Observers\EntryObserver;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Entry::observe(EntryObserver::class);
        // ... other code
    }
}
```

The `Entry::observe(EntryObserver::class)` call registers all the methods in `EntryObserver` as callbacks for the corresponding model lifecycle events. Now every create or delete of an Entry anywhere in the application triggers the observer methods automatically.

---

## 7. Run and Test

Let us verify each listener and observer works correctly.

### Step 1: Start the Queue Worker

Run the following command in a separate terminal to start the queue worker.

```bash
php artisan queue:work
```

The `SendCommentNotification` listener is queued, so the worker needs to be running to process it.

### Step 2: Post a Comment

In the browser, post a comment on another user's entry. Verify the following four outcomes:

- The HTTP request completes quickly and returns the success message
- The worker terminal shows the `SendCommentNotification` listener being processed
- `storage/logs/laravel.log` contains the log entry from `LogCommentActivity`
- The entry's `updated_at` reflects the new timestamp (check in Tinker with `Entry::find($id)->updated_at`)

Each of these is the result of one listener doing its single job, all triggered from one `CommentPosted::dispatch($comment)` call.

### Step 3: Test the Observer

Open Tinker to test the observer.

```bash
php artisan tinker
```

Create a new entry and confirm the observer fires.

```php
$user = \App\Models\User::first();
$entry = $user->entries()->create([
    'title'   => 'My Vacation Photos',
    'content' => 'A great trip.',
]);
```

After this runs, open `storage/logs/laravel.log` and look for the log entry written by the `created` observer method. You should see a line containing `"New entry created"` with the entry's `id`, `user_id`, and `title`. Now delete the entry and confirm the `deleted` observer fires.

```php
$entry->delete();
```

The `deleted` method runs. If the entry had a `cover_image` path stored, the file would be deleted from the public disk automatically. Type `exit` to leave Tinker.

---

## 8. Fix the Errors in Your Code

These are the most common mistakes when working with events, listeners, and observers in Laravel.

**Error 1: Event dispatched but nothing happens because the listener's type hint does not match.**

This error occurs when auto-discovery relies on the `handle()` method's type hint to wire the listener to the event. If the event class was renamed, or the import namespace is wrong, the type hint does not match and the listener is never registered.

```php
// Wrong: listener type-hints an old or wrong event class name
use App\Events\CommentCreated; // The actual event is CommentPosted

class SendCommentNotification
{
    public function handle(CommentCreated $event): void { ... }
}

// Correct: listener type-hints the exact event class that is dispatched
use App\Events\CommentPosted;

class SendCommentNotification
{
    public function handle(CommentPosted $event): void { ... }
}
```

The wrong version type-hints `CommentCreated`, which does not exist or is not what you dispatch. Laravel's auto-discovery scanner looks for listeners whose `handle()` parameter type matches the dispatched event class. A mismatch means the listener is completely invisible to the system. The fix is to ensure the type-hinted class is the exact class you dispatch with `CommentPosted::dispatch(...)`.

---

**Error 2: A synchronous listener throws an exception, crashing the HTTP request.**

This error occurs when a listener runs synchronously (does not implement `ShouldQueue`) and throws an unhandled exception. Because synchronous listeners run inside the HTTP request lifecycle, their exceptions propagate up to the user as a 500 error.

```php
// Wrong: synchronous listener throws an exception during the user's request
class NotifySlack
{
    public function handle(CommentPosted $event): void
    {
        // If the Slack API is down, this throws and the user sees a 500 error
        Http::post('https://hooks.slack.com/...', [...]);
    }
}

// Correct: implement ShouldQueue so exceptions go to failed_jobs, not to the user
class NotifySlack implements ShouldQueue
{
    public function handle(CommentPosted $event): void
    {
        Http::post('https://hooks.slack.com/...', [...]);
    }
}
```

The wrong version is a synchronous listener that calls an external API. If that API is unavailable, the exception bubbles up through the event dispatcher into the controller and back to the user as a 500 page. The correct version implements `ShouldQueue`, so the listener runs on the queue worker. If the Slack API is down, the job fails and goes to `failed_jobs`, where it can be retried once the API recovers, without ever showing an error to the original user.

---

**Error 3: Model observers do not fire when using mass update on a query builder.**

This error occurs when you call `update()` or `delete()` on a query builder (not on an individual model instance). Query-builder methods bypass the model lifecycle entirely for performance, which means no observer methods fire.

```php
// Wrong: mass update on the query builder bypasses model events
Entry::where('draft', true)->update(['published' => true]);
// The "updating" and "updated" observer methods DO NOT fire

// Correct: iterate and update each model instance to trigger observer events
Entry::where('draft', true)->get()->each(function ($entry) {
    $entry->update(['published' => true]);
});
```

The wrong version runs a single SQL `UPDATE` statement that modifies all matching rows without instantiating any Eloquent model objects. Since no model objects exist, no lifecycle events fire. The correct version fetches the models with `get()`, then iterates them with `each()`, calling `update()` on each individual model instance. This triggers the `updating` and `updated` observer methods for every entry. The trade-off is that this runs one query per entry instead of one bulk query, so use this only when the observer logic justifiably needs to run.

---

## 9. Exercises

Practice the event and observer patterns independently using the patterns from this lesson before checking the solutions.

**Exercise 1:** Create an `EntryCreated` event dispatched when a new entry is saved. Create a listener that sends a "Your entry was published" confirmation email to the author.

**Exercise 2:** Add an `updating` method to `EntryObserver` that logs the old and new title when the title changes. Use `$entry->isDirty('title')` and `$entry->getOriginal('title')` to detect and read the old value.

**Exercise 3:** Create a `UserRegistered` event and a `SendWelcomeEmail` listener. Dispatch the event from the registration controller to replace the direct `Mail::to($user)->send(...)` call with an event-driven version.

---

## 10. Solutions

Compare your implementations with the ones below. Pay attention to which listeners implement `ShouldQueue` and why.

**Solution for Exercise 1:**

Generate the event and listener with the following commands.

```bash
php artisan make:event EntryCreated --no-interaction
php artisan make:listener SendEntryPublishedEmail --event=EntryCreated --no-interaction
```

Open `app/Events/EntryCreated.php` and replace its content with the following.

```php
<?php

namespace App\Events;

use App\Models\Entry;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class EntryCreated
{
    use Dispatchable, SerializesModels;

    public function __construct(public Entry $entry) {}
}
```

Open `app/Listeners/SendEntryPublishedEmail.php` and replace its content with the following.

```php
<?php

namespace App\Listeners;

use App\Events\EntryCreated;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Mail;

class SendEntryPublishedEmail implements ShouldQueue
{
    public function handle(EntryCreated $event): void
    {
        Mail::to($event->entry->user)->send(
            new \App\Mail\WelcomeEmail($event->entry->user)
        );
    }
}
```

Open `app/Http/Controllers/EntryController.php` and dispatch the event in the `store()` method after creating the entry.

```php
<?php
// ... others lines of code

use App\Events\EntryCreated;

class EntryController extends Controller
{
    // ... other methods

    public function store(Request $request): RedirectResponse
    {
        // ... other code
        $entry = auth()->user()->entries()->create($data);
        $entry->tags()->sync($validated['tags'] ?? []);
        EntryCreated::dispatch($entry);

        return redirect()->route('entries.index');
    }

    // ... other methods
}
```

The listener implements `ShouldQueue` because email delivery is a network operation that should not block the HTTP request. The event carries the full `Entry` model with `SerializesModels`, so `$event->entry->user` is reloaded fresh from the database when the queued listener runs, giving you the current author record rather than a stale in-memory copy.

---

**Solution for Exercise 2:**

Add the following method to `app/Observers/EntryObserver.php`.

```php
<?php
// ... others lines of code

class EntryObserver
{
    // ... other methods

    public function updating(Entry $entry): void
    {
        if ($entry->isDirty('title')) {
            \Log::info('Entry title changed', [
                'entry_id' => $entry->id,
                'old' => $entry->getOriginal('title'),
                'new' => $entry->title,
            ]);
        }
    }

    // ... other methods
}
```

The `isDirty('title')` method returns `true` only when the title attribute was changed since the model was loaded from the database. This prevents logging when an edit saves other fields (like content or tags) without touching the title. `getOriginal('title')` returns the title as it was when the model was fetched from the database, before any in-memory mutations. `$entry->title` is the new value that is about to be persisted. Both values are logged together in a structured array so you can trace every title change in `storage/logs/laravel.log` without querying the database.

---

**Solution for Exercise 3:**

Generate the event and listener with the following commands.

```bash
php artisan make:event UserRegistered --no-interaction
php artisan make:listener SendWelcomeEmail --event=UserRegistered --no-interaction
```

Open `app/Events/UserRegistered.php` and replace its content with the following.

```php
<?php

namespace App\Events;

use App\Models\User;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UserRegistered
{
    use Dispatchable, SerializesModels;

    public function __construct(public User $user) {}
}
```

Open `app/Listeners/SendWelcomeEmail.php` and replace its content with the following.

```php
<?php

namespace App\Listeners;

use App\Events\UserRegistered;
use App\Mail\WelcomeEmail;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Mail;

class SendWelcomeEmail implements ShouldQueue
{
    public function handle(UserRegistered $event): void
    {
        Mail::to($event->user)->send(new WelcomeEmail($event->user));
    }
}
```

Open `app/Http/Controllers/AuthController.php` and update the `register()` method to dispatch the event in place of the direct `Mail::to(...)` call.

```php
<?php
// ... others lines of code

use App\Events\UserRegistered;

class AuthController extends Controller
{
    // ... other methods

    public function register(Request $request): RedirectResponse
    {
        // ... other code
        Auth::login($user);
        UserRegistered::dispatch($user);

        return redirect()->route('entries.index');
    }

    // ... other methods
}
```

The `Mail::to(...)` call is removed from the controller entirely. The controller now has no knowledge of the welcome email or any other registration side effect. Adding a future side effect (like creating a default entry or notifying an admin) requires only a new listener, not a controller change. The `ShouldQueue` on the listener means the welcome email is deferred to the background worker, keeping the registration redirect fast.

---

## Next Up - Lesson 15

In this lesson you decoupled Catatku's comment side effects using Laravel's event system. You created the `CommentPosted` event as a simple data container carrying the comment model, refactored `CommentController@store` to dispatch it with a single `CommentPosted::dispatch($comment)` call, and implemented three independent listeners: `SendCommentNotification` (queued, sends email to entry author), `LogCommentActivity` (synchronous, writes structured log), and `UpdateEntryLastActivity` (synchronous, touches entry timestamp). You also built the `EntryObserver` to automatically log new entries in the `created` hook and clean up cover images in the `deleted` hook, registered in `AppServiceProvider`, so these behaviors run for every entry modification regardless of source.

In Lesson 15, you will learn Blade components: packaging reusable UI into named `<x-component>` tags with props, slots, and attribute pass-through, so design changes require editing one file instead of hunting through every view.