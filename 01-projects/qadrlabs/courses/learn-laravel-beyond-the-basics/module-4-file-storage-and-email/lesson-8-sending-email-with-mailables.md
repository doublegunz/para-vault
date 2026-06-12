## 1. Before You Begin

Catatku can become more engaging by notifying users about activity. A welcome email when they register sets a positive first impression. A notification when someone comments on their entry encourages engagement. Laravel's Mailable classes encapsulate email logic cleanly: the subject, recipients, template, and data are all organized in a single class, making emails easy to write, test, and maintain.

This lesson teaches you to create Mailable classes, design email templates with Blade's Markdown components, configure a mail driver for testing, and send emails from controllers. You will build a welcome email and a comment notification email for Catatku. By the end, you will be able to trigger emails from your controllers and preview them in the browser as you develop.

### What You'll Build

You will create a `WelcomeEmail` Mailable sent when a user registers, and a `NewCommentEmail` Mailable sent when someone comments on a user's entry.

### What You'll Learn

- ✅ Configuring the mail driver for development
- ✅ Creating Mailable classes with `make:mail`
- ✅ Blade Markdown email templates
- ✅ Sending mail: `Mail::to($user)->send()`
- ✅ Queueable emails for background sending
- ✅ Previewing emails in the browser

### What You'll Need

- Lesson 7 completed

---

## 2. Configure Mail Driver

During development, you do not want to send real emails. The `log` driver writes emails to `storage/logs/laravel.log` so you can inspect them without an SMTP server, which is perfect for iterating on templates and debugging.

### Step 1: Update .env

Open the `.env` file and set the mail configuration.

```env
MAIL_MAILER=log
MAIL_FROM_ADDRESS=noreply@catatku.test
MAIL_FROM_NAME="Catatku"
```

Each of these variables matters. `MAIL_MAILER=log` tells Laravel to use the log driver, so every "sent" email appears as a text block in `storage/logs/laravel.log` instead of going to a real mail server. `MAIL_FROM_ADDRESS` and `MAIL_FROM_NAME` set the default sender for emails, so every Mailable does not need to specify a sender explicitly. For production, you would switch `MAIL_MAILER` to `smtp` with a real mail service like Mailgun, Postmark, or Amazon SES, but the log driver is ideal during development.

---

## 3. Create the Welcome Email

The welcome email is sent immediately after a user registers. It greets the user by name and provides a call-to-action button to write their first entry.

### Step 1: Generate the Mailable

Run the following command to create both the Mailable class and its email template in one step.

```bash
php artisan make:mail WelcomeEmail --markdown=emails.welcome
```

This creates two files at once. The first is `app/Mail/WelcomeEmail.php`, which is the Mailable class that defines the email's subject, recipients, and template. The second is `resources/views/emails/welcome.blade.php`, which is the actual email content using Laravel's Markdown mail components. The `--markdown=emails.welcome` flag tells Artisan to set up the template file at that path.

### Step 2: Define the Mailable Class

Open `app/Mail/WelcomeEmail.php` and replace its content with the following.

```php
<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class WelcomeEmail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public User $user) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Welcome to Catatku!');
    }

    public function content(): Content
    {
        return new Content(markdown: 'emails.welcome');
    }
}
```

Let us walk through this Mailable class in detail. The class extends `Mailable`, which provides all the core email functionality. The `use Queueable, SerializesModels;` mixes in two traits: `Queueable` allows the email to be dispatched to a background queue (covered in Lesson 13), and `SerializesModels` correctly handles Eloquent models when the email is serialized for queuing.

The constructor uses PHP 8 constructor property promotion: `public User $user` declares a public property and assigns it from the parameter in a single line. Public properties on a Mailable are automatically available in the Blade template, which is why we use `public` rather than `private` or `protected`. The `envelope()` method returns an `Envelope` object that defines metadata like the subject line. The `content()` method returns a `Content` object pointing to the markdown template at `resources/views/emails/welcome.blade.php`.

### Step 3: Write the Email Template

Open `resources/views/emails/welcome.blade.php` and replace its content with the following.

```
<x-mail::message>
# Welcome to Catatku, {{ $user->name }}!

Thank you for joining Catatku. Your personal journal is ready.

Start capturing your thoughts, memories, and ideas. Every entry is private and only visible to you.

<x-mail::button :url="route('entries.create')">
Write Your First Entry
</x-mail::button>

Happy journaling!<br>
{{ config('app.name') }}
</x-mail::message>
```

Breaking down this template: the outer `<x-mail::message>` component provides the standard email layout with header, content area, and footer, and styles it for good rendering across email clients. The `#` character starts a Markdown heading that becomes a styled `<h1>`. The `$user` variable is available because it is a public property on the Mailable. The `<x-mail::button>` component renders a large, styled call-to-action button; its `:url` prop takes a route URL. The `config('app.name')` helper reads your app name from configuration. Standard Markdown formatting also works inside the template: `**bold**` and `*italic*` are supported.

### Step 4: Send the Email on Registration

Open `app/Http/Controllers/AuthController.php` and update the `register` method. Add the `WelcomeEmail` and `Mail` imports to the top of the file alongside the existing `use` statements, then add the email dispatch after the `Auth::login()` call as shown below.

```php
<?php
// ... others lines of code
use App\Mail\WelcomeEmail;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    // ... other methods

    public function register(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        Auth::login($user);

        Mail::to($user)->send(new WelcomeEmail($user));

        return redirect()->route('entries.index')
            ->with('success', 'Welcome to Catatku, ' . $user->name . '!');
    }

    // ... other methods
}
```

Reading through this method: the two new `use` statements import the Mailable class and the Mail facade. The rest of the method — validation, user creation, and login — stays exactly as it was. The single new line, `Mail::to($user)->send(new WelcomeEmail($user))`, goes directly after `Auth::login($user)` so the welcome email fires only after the user account exists and the session is established. The `to()` method accepts a User model (Laravel reads the `email` property automatically), a string email address, or an array of recipients. The `send()` method delivers the email synchronously, meaning the request waits for the email to complete before redirecting. For better performance, use `queue()` instead (covered in Lesson 13), but `send()` is safe during development when using the log driver because it completes almost instantly.

---

## 4. Create the Comment Notification Email

The comment notification email alerts an entry author when someone posts a comment on their entry. It includes the commenter's name, the comment content, and a link directly to the entry.

### Step 1: Generate the Mailable

Run the following command to create the second Mailable and its template.

```bash
php artisan make:mail NewCommentEmail --markdown=emails.new-comment
```

This follows the same pattern as before, creating both the class file and the template file simultaneously.

### Step 2: Define the Mailable

Open `app/Mail/NewCommentEmail.php` and replace its content with the following.

```php
<?php

namespace App\Mail;

use App\Models\Comment;
use App\Models\Entry;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class NewCommentEmail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public Comment $comment,
        public Entry $entry,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: "New comment on \"{$this->entry->title}\"",
        );
    }

    public function content(): Content
    {
        return new Content(markdown: 'emails.new-comment');
    }
}
```

This Mailable follows the same pattern as `WelcomeEmail` but takes two public properties: the comment itself and the entry it was posted on. The constructor uses promoted properties for both. The envelope's `subject` uses a double-quoted string interpolating the entry title via `$this->entry->title`, so the email subject becomes something like "New comment on \"My Vacation\"". This helps recipients identify the entry without even opening the email.

### Step 3: Write the Template

Open `resources/views/emails/new-comment.blade.php` and add the following template content.

```
<x-mail::message>
# New Comment on "{{ $entry->title }}"

**{{ $comment->user->name }}** commented on your journal entry:

<x-mail::panel>
{{ $comment->body }}
</x-mail::panel>

<x-mail::button :url="route('entries.show', $entry)">
View Entry
</x-mail::button>

Thanks,<br>
{{ config('app.name') }}
</x-mail::message>
```

The template uses two mail components you have not seen yet. `<x-mail::panel>` renders a highlighted box that visually distinguishes the comment text from the surrounding message content, making it easy for the recipient to identify what was said. `<x-mail::button>` links to the entry detail page so the recipient can click straight to the comment thread. The Markdown `**bold**` emphasizes the commenter's name. All variables (`$entry`, `$comment`) come from the Mailable's public properties.

### Step 4: Send on Comment Creation

Open `app/Http/Controllers/CommentController.php` and update the `store` method to send the notification after creating the comment. Add the `NewCommentEmail` and `Mail` imports to the top of the file alongside the existing `use` statements.

```php
<?php
// ... others lines of code
use App\Mail\NewCommentEmail;
use Illuminate\Support\Facades\Mail;

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

        if ($entry->user_id !== $request->user()->id) {
            Mail::to($entry->user)->send(new NewCommentEmail($comment, $entry));
        }

        return back()->with('success', 'Comment posted!');
    }
}
```

The key addition is the `if ($entry->user_id !== $request->user()->id)` check. This prevents sending a notification when users comment on their own entries, which would produce unnecessary email traffic and feel spammy to the user. If the commenter is a different person from the entry author, `Mail::to($entry->user)` reads the entry author's email from the user model and sends the notification. The `$entry->user` relationship must be loaded; if you have not eager loaded it, Eloquent will run a query automatically (which is acceptable here since this runs once per comment).

---

## 5. Run and Test

Let us verify both emails work correctly by previewing them in the browser and checking the log output.

### Step 1: Preview Emails in the Browser

The fastest way to test email appearance is to preview them directly in the browser without sending anything. Add a temporary preview route at the bottom of `routes/web.php`, outside any middleware group.

```php
Route::get('/mail-preview/welcome', function () {
    return new \App\Mail\WelcomeEmail(\App\Models\User::first());
});
```

Visit `http://localhost:8000/mail-preview/welcome`. You should see the fully rendered welcome email with styling, the user's name, and the button. This preview technique works because Mailable classes implement the `Renderable` interface. When the router sees a Mailable returned from a route closure, it automatically calls `render()` on it and sends the HTML as the HTTP response. Remove this preview route before deploying to production.

### Step 2: Test Email Sending

Register a new user through the registration form. Then check the log file for the email output.

```bash
tail -50 storage/logs/laravel.log
```

The `tail -50` command outputs the last 50 lines of the log file. You should see the email content logged, including the subject line, recipient address, and HTML body. If you see "Welcome to Catatku!" in the output, the email was dispatched successfully through the log driver.

### Step 3: Test Comment Notification

Log in as User A and create an entry. Log out and log in as User B. Post a comment on User A's entry. Check the log file again. You should see a "New comment on..." email addressed to User A's email address, confirming the notification was dispatched.

### Step 4: Verify Self-Comment Suppression

Log in as User A and post a comment on one of your own entries. Check the log file immediately after. No new email entry should appear because the `if ($entry->user_id !== $request->user()->id)` condition prevents the dispatch when the commenter and the entry author are the same person.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when working with Mailable classes and email templates in Laravel.

**Error 1: Mailable property declared as private, making it inaccessible in the template.**

This error occurs when you declare a property on the Mailable as `private` or `protected`. Only `public` properties are automatically passed to Blade templates. Accessing a non-public property in the template produces an "Undefined variable" error.

```php
// Wrong: private property is invisible to the Blade template
class WelcomeEmail extends Mailable
{
    private User $user;

    public function __construct(User $user)
    {
        $this->user = $user;
    }
}

// Correct: public property is automatically available in the template
class WelcomeEmail extends Mailable
{
    public function __construct(public User $user) {}
}
```

With the wrong version, the template receives `$user` as null or throws "Undefined variable $user" because Laravel only passes public properties. The correct version uses PHP 8 constructor property promotion to declare `$user` as public in a single line, making it available to the template automatically without any additional `with()` calls.

---

**Error 2: Sending emails in a loop with `send()`, blocking the web request.**

This error occurs when you need to email many users at once and call `Mail::to($user)->send(...)` inside a foreach loop. Each `send()` call makes a synchronous connection to the mail server. Ten recipients means ten round trips, and the web request does not return until all ten complete.

```php
// Wrong: each send() blocks the request until the email is delivered
foreach ($subscribers as $user) {
    Mail::to($user)->send(new Newsletter($user));
}

// Correct: queue() dispatches each email to a background worker
foreach ($subscribers as $user) {
    Mail::to($user)->queue(new Newsletter($user));
}
```

The wrong version calls `send()` in a loop. For 100 subscribers and a mail server that takes 200ms per email, the request takes 20 seconds. Users see a timeout or an extremely slow page. The correct version calls `queue()`, which adds each email to the queue and returns immediately. Background workers process the queue independently, and the web request completes in milliseconds. Lesson 13 covers setting up queues in full detail.

---

**Error 3: No valid mail driver configured, causing connection errors.**

This error occurs when `MAIL_MAILER` is not set in `.env` or is set to `smtp` without valid SMTP credentials. Laravel attempts to connect to the configured mail server and fails with a connection or authentication error.

```env
# Wrong: MAIL_MAILER=smtp without valid credentials causes connection failure
MAIL_MAILER=smtp
MAIL_HOST=smtp.example.com
MAIL_USERNAME=
MAIL_PASSWORD=

# Correct: use log driver during development, no external server needed
MAIL_MAILER=log
MAIL_FROM_ADDRESS=noreply@catatku.test
MAIL_FROM_NAME="Catatku"
```

Without a valid mail driver, every `Mail::to(...)->send(...)` call throws a `TransportException` or "Connection refused" error that breaks the user's request. Setting `MAIL_MAILER=log` in `.env` switches to the built-in log driver, which requires no external configuration. Every "sent" email is written to `storage/logs/laravel.log` as text, making it easy to inspect without any mail infrastructure.

---

## 7. Exercises

These exercises reinforce the email development workflow from this lesson. Exercise 1 and 2 extend the templates you already built. Exercise 3 connects Catatku to a real email inbox so you can test HTML rendering in an actual mail client environment.

**Exercise 1:** Create a mail preview route for `NewCommentEmail`. You will need to fetch a comment and its entry to pass to the constructor: `new NewCommentEmail(Comment::first(), Entry::first())`.

**Exercise 2:** Add a "View your entries" link to the welcome email footer using the `<x-mail::subcopy>` component.

**Exercise 3:** Switch the mail driver to Mailtrap (mailtrap.io). Sign up for a free account, get the SMTP credentials, and configure `.env`. Send a test email and view it in the Mailtrap inbox with full HTML rendering.

---

## 8. Solutions

Each solution below is self-contained. Exercises 1 and 2 require only small additions to existing files. Exercise 3 requires a Mailtrap account, but the sign-up is free and takes under two minutes.

**Solution for Exercise 1:**

Add the preview route to `routes/web.php` alongside the welcome preview route.

```php
Route::get('/mail-preview/comment', function () {
    $comment = \App\Models\Comment::with('user')->first();
    $entry = $comment->entry;
    return new \App\Mail\NewCommentEmail($comment, $entry);
});
```

The `with('user')` eager loads the comment author so the `$comment->user->name` reference in the template does not trigger a lazy query at render time. `$comment->entry` accesses the entry through the `belongsTo` relationship you defined in Lesson 1. Visiting `http://localhost:8000/mail-preview/comment` renders the full email HTML in the browser, including the panel with the comment body and the button linking to the entry. Remove both preview routes before deploying to production, because they expose email content to any visitor without authentication.

---

**Solution for Exercise 2:**

Open `resources/views/emails/welcome.blade.php` and add the `<x-mail::subcopy>` block at the bottom, just before the closing `</x-mail::message>` tag.

```
<x-mail::message>
# Welcome to Catatku, {{ $user->name }}!

Thank you for joining Catatku. Your personal journal is ready.

<x-mail::button :url="route('entries.create')">
Write Your First Entry
</x-mail::button>

Happy journaling!<br>
{{ config('app.name') }}

<x-mail::subcopy>
You can view all your journal entries here:
[{{ route('entries.index') }}]({{ route('entries.index') }})
</x-mail::subcopy>
</x-mail::message>
```

The `<x-mail::subcopy>` component renders small gray text at the bottom of the email, typically used for legal notices, unsubscribe links, or secondary navigation. The Markdown link syntax `[text](url)` renders as a hyperlink inside the subtext area. This is useful for giving users a plain-text fallback when the styled button does not render correctly in their email client.

---

**Solution for Exercise 3:**

Sign up for a free account at mailtrap.io. After logging in, navigate to "Email Testing" and open your default inbox. Click the gear icon for "SMTP Settings" to see your credentials. Open your Catatku `.env` file and replace the existing mail configuration with the following, substituting your actual Mailtrap username and password.

```env
MAIL_MAILER=smtp
MAIL_HOST=sandbox.smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=your_mailtrap_username
MAIL_PASSWORD=your_mailtrap_password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@catatku.test
MAIL_FROM_NAME="Catatku"
```

`MAIL_MAILER=smtp` switches Laravel from the log driver to a real SMTP connection. `sandbox.smtp.mailtrap.io` is Mailtrap's sandbox host, which accepts emails on port 2525 and routes them to your inbox rather than to real recipients. `MAIL_ENCRYPTION=tls` enables transport security for the SMTP connection. After saving `.env`, clear the configuration cache so Laravel picks up the new values.

```bash
php artisan config:clear
```

`php artisan config:clear` removes the cached configuration so the next request reads the updated `.env` values. Without this step, Laravel may continue using the old `log` driver from a previous cache. Register a new user through the Catatku form and then open your Mailtrap inbox. The welcome email should appear within seconds, fully rendered with your subject line, layout, button, and formatted content exactly as it will look to real users.

---

## Next Up - Lesson 9

In this lesson you built two complete email workflows for Catatku. You configured the `log` mail driver for development so all outgoing emails are captured in the log file for inspection without needing an SMTP server. You created the `WelcomeEmail` and `NewCommentEmail` Mailable classes, each with a Blade Markdown template that uses the `<x-mail::message>`, `<x-mail::button>`, and `<x-mail::panel>` components. You learned to preview emails in the browser by returning a Mailable from a route closure, and you added a self-comment guard to avoid spamming users with notifications about their own activity.

In Lesson 9, you will learn how to build a REST API for Catatku: designing JSON endpoints that follow REST conventions, returning proper HTTP status codes, and testing your API with curl.