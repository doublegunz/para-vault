# Send Email in the Background with Laravel Queues

Sending an email during a web request looks harmless. A visitor submits a form, your controller connects to an SMTP server, and the response appears after the message has been accepted. The problem becomes obvious when the mail server is slow. The visitor waits for work that does not need to finish before the page can respond.

That delay also makes the request more fragile. A temporary SMTP timeout can turn an otherwise valid form submission into an error page, and every additional email makes the response slower.

Laravel queues solve this by storing the email as a background job. The controller can respond immediately, while a separate queue worker sends the message. In this tutorial, you will build that complete flow with a queued Mailable, a database queue, a log mailer, form validation, and Pest tests.

## Overview {#overview}

We will build a small welcome-email form. Submitting the form validates the recipient, places a Mailable on a dedicated `emails` queue, and redirects immediately with a confirmation message. A queue worker processes the message afterward. We will use Laravel's log mailer first, so you can complete the tutorial without an SMTP account or real credentials.

### What You'll Build

- A form that accepts a recipient name and email address
- A Form Request that validates the submitted data
- A queued `WelcomeMail` Mailable
- A database-backed queue named `emails`
- A worker that sends the email through Laravel's log mailer
- Six Pest tests for the form, validation, queue, recipient, and email content

### What You'll Learn

- How a queued email removes SMTP work from an HTTP request
- How to configure Laravel's database queue and log mailer
- How to make a Mailable implement `ShouldQueue`
- Why a separate custom Job is unnecessary for a simple queued email
- How to run a worker for one named queue
- How to test queued Mailables without sending real email
- How retries and failed jobs help when mail delivery encounters an error

### What You'll Need

- PHP 8.3 or newer
- Composer and the Laravel installer
- Basic familiarity with routes, controllers, Blade, and Artisan
- A terminal and a code editor
- No SMTP account for the main tutorial

## Step 1: Create and Configure the Project {#step-1-create-and-configure-the-project}

Create a fresh Laravel project with SQLite and Pest, then enter the new directory.

```bash
laravel new queued-welcome-mail --no-interaction --database=sqlite --pest --no-boost
cd queued-welcome-mail
```

The `--database=sqlite` option creates an SQLite database for the application. The `--pest` option installs Pest, while `--no-boost` keeps this small tutorial focused on Laravel's built-in mail and queue features.

Check the installed framework version.

```bash
php artisan --version
```

The project used to validate this tutorial returned:

```text
Laravel Framework 13.22.0
```

Open `.env` and confirm these values:

```dotenv
DB_CONNECTION=sqlite

QUEUE_CONNECTION=database

MAIL_MAILER=log
MAIL_SCHEME=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"
```

The database queue stores pending jobs in the `jobs` table. The log mailer writes the complete message to `storage/logs/laravel.log` instead of contacting an SMTP server.

A fresh Laravel 13 project already contains a migration that creates `jobs`, `job_batches`, and `failed_jobs`. The installer also runs the initial migrations, so you do not need the older `php artisan queue:table` setup used by older Laravel tutorials.

Save `.env`, then confirm that the database is up to date.

```bash
php artisan migrate
```

The validated project returned:

```text
 INFO Nothing to migrate.
```

If Laravel runs migrations instead, that is also valid. It means the database tables had not been created yet.

## Step 2: Build the Welcome Email Form {#step-2-build-the-welcome-email-form}

The form needs a controller for displaying the page and a Form Request for validating its input. Generate both classes.

```bash
php artisan make:request SendWelcomeEmailRequest
php artisan make:controller WelcomeEmailController
```

Artisan creates the two files:

```text
 INFO Request [app/Http/Requests/SendWelcomeEmailRequest.php] created successfully.

 INFO Controller [app/Http/Controllers/WelcomeEmailController.php] created successfully.
```

Open `app/Http/Requests/SendWelcomeEmailRequest.php` and replace it with:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SendWelcomeEmailRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'max:255'],
        ];
    }
}
```

Returning `true` from `authorize()` allows anyone who can reach this public demo form to submit it. The validation rules require a short name and a syntactically valid email address. In a real application, protect the form with authentication, authorization, rate limiting, or another control appropriate for the feature.

Save the request file. Next, open `app/Http/Controllers/WelcomeEmailController.php` and add the action that displays the form:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class WelcomeEmailController extends Controller
{
    public function create(): View
    {
        return view('welcome-email');
    }
}
```

The `create()` action has one responsibility: return the Blade view containing the form. Save the controller.

Create `resources/views/welcome-email.blade.php` with the following standalone page:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Send a Welcome Email</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-2">Send a Welcome Email</h1>
        <p class="text-gray-600 mb-6">
            Submit the form and Laravel will process the email in the background.
        </p>

        @if (session('status'))
            <div class="mb-6 rounded-md bg-green-100 px-4 py-3 text-green-800">
                {{ session('status') }}
            </div>
        @endif

        <form action="{{ route('emails.store') }}" method="POST" class="space-y-5">
            @csrf

            <div>
                <label for="name" class="block text-sm font-medium mb-1">Name</label>
                <input id="name" name="name" type="text" value="{{ old('name') }}"
                    class="w-full rounded-md border border-gray-300 px-3 py-2">
                @error('name')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <div>
                <label for="email" class="block text-sm font-medium mb-1">Email</label>
                <input id="email" name="email" type="email" value="{{ old('email') }}"
                    class="w-full rounded-md border border-gray-300 px-3 py-2">
                @error('email')
                    <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <button type="submit"
                class="rounded-md bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700">
                Queue Welcome Email
            </button>
        </form>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Queued Email at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The form posts to the named route we will register next. The `@csrf` directive adds Laravel's CSRF token, `old()` restores submitted values after validation fails, and `@error` displays each validation message.

Save the view. Open `routes/web.php` and replace its contents with both routes:

```php
<?php

use App\Http\Controllers\WelcomeEmailController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/welcome-email', [WelcomeEmailController::class, 'create'])
    ->name('emails.create');
Route::post('/welcome-email', [WelcomeEmailController::class, 'store'])
    ->name('emails.store');
```

The original `/` route keeps Laravel's starter page available. The new GET route displays the email form, while the POST route reserves the form target that the controller will implement in Step 4. Do not submit the form yet because `store()` does not exist until that step.

Save the route file and confirm both routes are registered:

```bash
php artisan route:list --path=welcome-email
```

The validated project returned:

```text
 GET|HEAD welcome-email .. emails.create › WelcomeEmailController@create
 POST welcome-email .. emails.store › WelcomeEmailController@store

 Showing [2] routes
```

Start the development server.

```bash
php artisan serve
```

Open `http://127.0.0.1:8000/welcome-email`. You should see the welcome-email form with fields for a name and email address.

## Step 3: Create the Queued Mailable {#step-3-create-the-queued-mailable}

A Mailable describes an email's subject, content, and attachments. Generate one for the welcome message.

```bash
php artisan make:mail WelcomeMail
```

Artisan confirms the generated class:

```text
 INFO Mailable [app/Mail/WelcomeMail.php] created successfully.
```

Open `app/Mail/WelcomeMail.php` and replace it with:

```php
<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class WelcomeMail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public function __construct(public string $name)
    {
        $this->onQueue('emails');
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Welcome to Qadrlabs',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.welcome',
        );
    }

    /**
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}
```

The important part is `implements ShouldQueue`. It tells Laravel that this Mailable belongs on a queue. The `Queueable` trait provides queue configuration methods, so the constructor can assign every instance to the named `emails` queue.

The public `$name` property is serialized with the queued message and becomes available to the Blade view. `envelope()` defines the subject, while `content()` selects the view.

Save the Mailable. Create `resources/views/emails/welcome.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Qadrlabs</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-4">Hello {{ $name }}</h1>

        <p class="mb-4">
            Thanks for trying queued email with Laravel.
        </p>

        <p>
            This message was processed by a queue worker instead of delaying the original
            web request.
        </p>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Queued Email at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

This template uses the serialized `$name` value to personalize the email. Save the file, then check the Mailable for syntax errors.

```bash
php -l app/Mail/WelcomeMail.php
```

PHP should report:

```text
No syntax errors detected in app/Mail/WelcomeMail.php
```

## Step 4: Queue the Email from the Controller {#step-4-queue-the-email-from-the-controller}

The Mailable is ready, so the controller can now validate a submission and queue it. Open `app/Http/Controllers/WelcomeEmailController.php`. Its current version only contains `create()`:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class WelcomeEmailController extends Controller
{
    public function create(): View
    {
        return view('welcome-email');
    }
}
```

Replace it with the complete controller:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\SendWelcomeEmailRequest;
use App\Mail\WelcomeMail;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Mail;
use Illuminate\View\View;

class WelcomeEmailController extends Controller
{
    public function create(): View
    {
        return view('welcome-email');
    }

    public function store(SendWelcomeEmailRequest $request): RedirectResponse
    {
        $validated = $request->validated();

        Mail::to($validated['email'])->queue(
            new WelcomeMail($validated['name'])
        );

        return to_route('emails.create')
            ->with('status', 'Your welcome email has been queued.');
    }
}
```

The `store()` action receives only validated input. `Mail::to()` sets the recipient, and `queue()` stores the Mailable for a worker instead of opening the SMTP connection during the request. The redirect carries a flash message back to the form.

This use case does not need a separate `SendWelcomeEmailJob`. The queued Mailable already represents one background task. Add a custom Job later only if the background operation must coordinate additional work beyond delivering this message.

Save the controller and check its syntax:

```bash
php -l app/Http/Controllers/WelcomeEmailController.php
```

PHP should report:

```text
No syntax errors detected in app/Http/Controllers/WelcomeEmailController.php
```

The routes from Step 2 now point to two implemented controller actions, so the complete HTTP flow is connected.

## Step 5: Try It Out {#step-5-try-it-out}

You need two terminal windows because the web server and queue worker are separate long-running processes.

In the first terminal, start Laravel's development server if it is not already running:

```bash
php artisan serve
```

In the second terminal, start a worker that only consumes the `emails` queue:

```bash
php artisan queue:work --queue=emails --tries=3 --backoff=5
```

The worker waits for queued mail. `--tries=3` allows a failing message to be attempted three times, and `--backoff=5` waits five seconds before another attempt.

Open `http://127.0.0.1:8000/welcome-email`, enter a name and email address, then submit the form. The browser should return immediately and display:

```text
Your welcome email has been queued.
```

Watch the worker terminal. The validated run produced:

```text
2026-07-26 01:46:14 App\Mail\WelcomeMail .. RUNNING
2026-07-26 01:46:14 App\Mail\WelcomeMail .. 19.32ms DONE
```

Your timestamp and duration will differ. `RUNNING` means the worker reserved the queued Mailable, and `DONE` means the log mailer accepted and wrote the message successfully.

Open `storage/logs/laravel.log`. The test submission produced this message header and content:

```text
[2026-07-26 01:46:14] local.DEBUG: From: Laravel <hello@example.com>
To: ada@example.com
Subject: Welcome to Qadrlabs
MIME-Version: 1.0
Date: Sun, 26 Jul 2026 01:46:14 +0000
```

Farther down in the same log entry, the rendered HTML includes:

```html
<h1 class="text-2xl font-bold mb-4">Hello Ada Lovelace</h1>

<p class="mb-4">
    Thanks for trying queued email with Laravel.
</p>
```

This confirms that the worker processed the correct recipient, subject, and personalized content without contacting a real mail server.

## Step 6: Test the Queued Email Flow {#step-6-test-the-queued-email-flow}

Manual testing proves the flow works, but an automated test suite protects it from future changes. Laravel's mail fake intercepts outgoing messages, so the tests can inspect the queued Mailable without writing to the log or contacting SMTP.

Generate a Pest feature test:

```bash
php artisan make:test --pest QueuedWelcomeEmailTest
```

Artisan creates the test file:

```text
 INFO Test [tests/Feature/QueuedWelcomeEmailTest.php] created successfully.
```

Open `tests/Feature/QueuedWelcomeEmailTest.php` and replace it with:

```php
<?php

use App\Mail\WelcomeMail;
use Illuminate\Support\Facades\Mail;

it('displays the welcome email form', function () {
    $this->get(route('emails.create'))
        ->assertOk()
        ->assertSee('Send a Welcome Email');
});

it('requires a name and email address', function () {
    $this->post(route('emails.store'), [])
        ->assertSessionHasErrors(['name', 'email']);
});

it('requires a valid email address', function () {
    $this->post(route('emails.store'), [
        'name' => 'Ada Lovelace',
        'email' => 'not-an-email',
    ])->assertSessionHasErrors(['email']);
});

it('queues one welcome email after a valid submission', function () {
    Mail::fake();

    $this->post(route('emails.store'), [
        'name' => 'Ada Lovelace',
        'email' => 'ada@example.com',
    ])->assertRedirectToRoute('emails.create')
        ->assertSessionHas('status', 'Your welcome email has been queued.');

    Mail::assertQueuedCount(1);
});

it('queues the welcome email for the submitted recipient on the emails queue', function () {
    Mail::fake();

    $this->post(route('emails.store'), [
        'name' => 'Ada Lovelace',
        'email' => 'ada@example.com',
    ]);

    Mail::assertQueued(WelcomeMail::class, function (WelcomeMail $mail) {
        return $mail->hasTo('ada@example.com')
            && $mail->queue === 'emails'
            && $mail->name === 'Ada Lovelace';
    });
});

it('renders the expected welcome email content', function () {
    $mail = new WelcomeMail('Ada Lovelace');

    $mail->assertHasSubject('Welcome to Qadrlabs');
    $mail->assertSeeInHtml('Hello Ada Lovelace');
    $mail->assertSeeInHtml('Thanks for trying queued email with Laravel.');
});
```

The first three tests cover the form and its validation. The fourth test verifies that a successful request queues exactly one message and returns the expected confirmation. The fifth inspects the queued Mailable's recipient, queue name, and serialized name. The last test renders the Mailable and checks its subject and HTML.

Save the test and run only this file:

```bash
php artisan test tests/Feature/QueuedWelcomeEmailTest.php
```

The validated suite returned:

```
php artisan test tests/Feature/QueuedWelcomeEmailTest.php 

   PASS  Tests\Feature\QueuedWelcomeEmailTest
  ✓ it displays the welcome email form                                   0.12s  
  ✓ it requires a name and email address                                 0.02s  
  ✓ it requires a valid email address                                    0.03s  
  ✓ it queues one welcome email after a valid submission                 0.02s  
  ✓ it queues the welcome email for the submitted recipient on the emai… 0.02s  
  ✓ it renders the expected welcome email content                        0.02s  

  Tests:    6 passed (15 assertions)
  Duration: 0.32s
```

The duration will vary. The important result is six passing tests with no failures.

## How Queued Mail Works {#how-queued-mail-works}

The feature contains four parts that run at different times:

1. The browser sends a POST request to `WelcomeEmailController::store()`.
2. Laravel validates the request and serializes `WelcomeMail` into the `jobs` table.
3. The controller redirects before SMTP or another mail transport does any work.
4. The queue worker reserves the job, renders the Mailable, sends it through the configured mailer, and deletes the completed row.

The queue connection and mailer solve separate problems. `QUEUE_CONNECTION=database` decides where background work waits. `MAIL_MAILER=log` decides how the worker delivers the message after it starts processing that work.

Implementing `ShouldQueue` on the Mailable makes its background behavior explicit. Even if another part of the application later calls `send()` with this Mailable, Laravel still queues it because the class implements that contract.

Named queues provide basic workload separation. This tutorial sends mail to `emails`, so `queue:work --queue=emails` does not consume unrelated jobs. In production, that lets you give email delivery its own worker count, retry policy, and monitoring.

## Retries and Failed Jobs {#retries-and-failed-jobs}

Email delivery can fail because of a temporary network issue, provider throttling, or invalid credentials. The worker command used in this tutorial gives each job up to three attempts:

```bash
php artisan queue:work --queue=emails --tries=3 --backoff=5
```

If every attempt throws an exception, Laravel stores the job in `failed_jobs`. List those records with:

```bash
php artisan queue:failed
```

When there are no failures, Laravel reports:

```text
 INFO No failed jobs found.
```

After correcting the underlying problem, retry one failed job by its ID:

```bash
php artisan queue:retry 5
```

Retry every failed job only when you have confirmed that replaying all of them is safe:

```bash
php artisan queue:retry all
```

Queue workers are long-running processes. They keep the application code loaded in memory, so restart them gracefully during deployment:

```bash
php artisan queue:restart
```

In production, keep workers alive with a process monitor such as Supervisor or the worker management provided by your hosting platform. Configure the worker timeout to be shorter than the queue connection's `retry_after` value. That prevents the same frozen job from being processed twice.

## Use a Real SMTP Server {#use-a-real-smtp-server}

The log mailer is ideal for learning and local verification. When you are ready to deliver a real message, replace the mail settings in `.env` with credentials from your SMTP provider:

```dotenv
MAIL_MAILER=smtp
MAIL_SCHEME=smtp
MAIL_HOST=smtp.example.com
MAIL_PORT=587
MAIL_USERNAME=your-smtp-username
MAIL_PASSWORD=your-smtp-password
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"
```

Use the exact scheme, host, port, and authentication values supplied by your provider. `smtp` on port 587 is a common STARTTLS configuration. If your provider requires implicit TLS on port 465, it may specify the `smtps` scheme instead. Keep real credentials out of source control.

After changing `.env`, clear cached configuration:

```bash
php artisan config:clear
```

Restart the queue workers so their long-running processes load the new mail configuration:

```bash
php artisan queue:restart
php artisan queue:work --queue=emails --tries=3 --backoff=5
```

Submit the form again and check the recipient inbox or your provider's delivery dashboard. The controller, Mailable, routes, and tests do not need to change because Laravel's mailer abstraction keeps transport configuration outside the application code.

## Where to Go Next {#where-to-go-next}

This tutorial deliberately handles one independent welcome email. Real applications often introduce additional queue concerns as their workflows grow.

If an email depends on database records created inside a transaction, read [Laravel afterCommit: Don't Send the Confirmation Email Before the Transaction Commits](https://qadrlabs.com/post/laravel-aftercommit-dont-send-the-confirmation-email-before-the-transaction-commits). It explains how to prevent a worker from processing data before the transaction commits.

If you need to send a large campaign, read [Queue Rate Limiting and Batching in Laravel](https://qadrlabs.com/post/queue-rate-limiting-and-batching-in-laravel-send-thousands-of-bulk-emails-without-getting-banned-by-your-smtp-provider). It covers provider limits, per-recipient jobs, batch progress, failures, and cancellation.

These advanced patterns solve different problems. Keep a single transactional email as a queued Mailable until your application has a concrete reason to add orchestration, transaction awareness, rate limiting, or batching.

## Conclusion {#conclusion}

Moving email delivery to a queue improves response time and separates a fragile external operation from the user's request. Laravel's queued Mailables make that separation possible without adding a custom Job for a simple message.

- **Queued Mailables keep requests responsive.** The controller stores background work and redirects without waiting for the mail transport.
- **`ShouldQueue` makes intent explicit.** The Mailable declares that Laravel should process it through the queue.
- **Named queues separate workloads.** The `emails` queue can have dedicated workers and retry settings.
- **The log mailer removes setup friction.** You can verify recipients, subjects, and rendered HTML before adding SMTP credentials.
- **Pest tests protect the complete flow.** The suite covers the form, validation, queued message, recipient, queue name, and email content.
- **Retries need operational support.** Inspect failed jobs, retry them only after fixing the cause, and keep production workers supervised.
