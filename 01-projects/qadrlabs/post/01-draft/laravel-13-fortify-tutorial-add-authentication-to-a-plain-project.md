# Laravel 13 Fortify Tutorial: Add Authentication to a Plain Laravel Project

You spin up the React, Vue, or Livewire starter kit and everything is already there: a login page, a registration form, password resets, even two-factor authentication. Then you open a plain project you created with `composer create-project laravel/laravel`, and there is nothing. No login route, no auth scaffolding, just the welcome page. If you peek inside those starter kits to see how they pull it off, you keep running into the same package name: Laravel Fortify. So the natural question becomes, "what exactly is Fortify doing, and can I wire it into a project I already have?"

The reason this feels confusing is that Fortify has no visible frontend of its own. It does not ship a single Blade file, so opening its source does not show you a login page to copy. It is a backend only authentication service. That is precisely why the starter kits lean on it: Fortify owns the routes, controllers, validation, and security, while each starter kit supplies its own React, Vue, or Blade views on top. Once you understand that split, adding Fortify to a bare project stops being mysterious.

In this tutorial we take a fresh `composer create-project` application with zero authentication and wire Fortify into it by hand. You will install the package, enable the features you want, bind your own Blade views to Fortify's routes, and end up with working registration, login, logout, and password reset, plus two-factor authentication enabled and ready. If you have used the scaffolding-based approach before, it helps to compare this with our [Laravel Breeze tutorial](https://qadrlabs.com/post/install-laravel-breeze-di-laravel-12) and the [Sanctum API authentication tutorial](https://qadrlabs.com/post/rest-api-authentication-with-laravel-sanctum); Fortify sits in a different spot from both, and we will map out where at the end.

## Overview {#overview}

Fortify is a "headless" authentication backend. That single idea drives every decision in this tutorial, so it is worth stating plainly before we touch the terminal. Headless means Fortify registers all the authentication routes and handles all the logic, but it never decides what your pages look like. You hand it a view, it handles the POST. By the end you will have a small but complete authentication flow that you fully control, running on top of a project that started with nothing.

### What You'll Build
- A plain Laravel application with Fortify-powered **registration, login, and logout**.
- A **password reset** flow that emails a reset link (captured in the log during development).
- A protected `/dashboard` route that only authenticated users can reach.
- **Two-factor authentication** enabled and ready on the User model, with its routes explained.

### What You'll Learn
- What "headless authentication" actually means and why the starter kits use Fortify.
- How to install Fortify into an existing project that was created with `composer create-project`.
- How to turn features on and off in `config/fortify.php`.
- How to bind your own Blade views to Fortify's routes using the `Fortify` facade.
- How to protect routes and where two-factor authentication plugs in.

### What You'll Need
- **PHP 8.3 or newer** and Composer installed locally.
- A terminal and a code editor.
- Basic familiarity with Laravel routing and Blade templates.
- No prior authentication package. We start from a clean slate, so you do not need Breeze, Jetstream, or a starter kit installed.

## Step 1: Create the Plain Laravel Project {#step-1-create-the-plain-laravel-project}

Fortify integrates into any Laravel application, so the starting point is deliberately boring: a brand-new project with no authentication at all. This is the same skeleton you would get on any existing `composer create-project` app, which means if you already have such a project you can skip the create step and follow along inside it. Create the project and move into it.

```bash
composer create-project laravel/laravel fortify-demo
cd fortify-demo
```

The installer sets up a SQLite database by default and runs the initial migrations for you, so the `users` table already exists. That is all the base we need. There is no login page here yet, which is exactly the situation we are solving.

Because we will write automated tests at the end, add Pest now. A fresh Laravel project ships with PHPUnit, and Pest is a thin, expressive layer on top of it that reads more like plain English. Pull in Pest and its Laravel plugin as development dependencies.

```bash
composer require pestphp/pest pestphp/pest-plugin-laravel --dev --with-all-dependencies
```

The `--with-all-dependencies` flag lets Composer update any shared packages Pest needs so the versions line up cleanly. Once it finishes, initialize Pest so it creates its `tests/Pest.php` configuration file.

```bash
./vendor/bin/pest --init
```

With that in place, confirm the base project is healthy by running the test suite that ships with a fresh install.

```bash
php artisan test
```

You should see the two example tests pass, which tells you the application boots and the database connection works.

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response

  Tests:    2 passed (2 assertions)
  Duration: 0.16s
```

## Step 2: Install Laravel Fortify {#step-2-install-laravel-fortify}

Now we bring in the package that does all the heavy lifting. Fortify is a first-party Laravel package, so installation is a single Composer command followed by an Artisan installer that publishes everything you will edit later.

```bash
composer require laravel/fortify
```

After the package is installed, run Fortify's install command. This is the step that turns an opaque dependency into files you can actually see and modify.

```bash
php artisan fortify:install
```

The command prints a short confirmation.

```
   INFO  Fortify scaffolding installed successfully.
```

That one command did several things, and it is worth knowing each of them because they are the pieces you will touch throughout the rest of the tutorial. First, it published a `config/fortify.php` configuration file where you enable and disable features. Second, it created an `app/Providers/FortifyServiceProvider.php` and registered it for you. Third, it generated a folder of action classes that contain the actual business logic for creating and updating users. You can list them to confirm.

```bash
ls app/Actions/Fortify/
```

```
CreateNewUser.php
PasswordValidationRules.php
ResetUserPassword.php
UpdateUserPassword.php
UpdateUserProfileInformation.php
```

These action classes are the reason Fortify feels so flexible. Instead of hiding the "create a user" logic deep inside the package, Fortify puts it right in your application where you can edit validation rules or add fields. The install command also registered the new provider in `bootstrap/providers.php`, which is how Laravel 13 loads service providers.

```php
<?php

return [
    App\Providers\AppServiceProvider::class,
    App\Providers\FortifyServiceProvider::class,
];
```

Finally, Fortify published a couple of database migrations, including one that adds two-factor authentication columns to the `users` table. Run the migrations to apply them.

```bash
php artisan migrate
```

```
   INFO  Running migrations.

  2026_08_03_021929_add_two_factor_columns_to_users_table ........ 9.29ms DONE
  2026_08_03_021930_create_passkeys_table ....................... 16.86ms DONE
```

The `add_two_factor_columns_to_users_table` migration is the important one for us; it adds the `two_factor_secret` and `two_factor_recovery_codes` columns that two-factor authentication relies on. Fortify also ships a `passkeys` migration for WebAuthn support, which we are not covering here, but running it now does no harm.

## Step 3: Enable the Features You Need {#step-3-enable-the-features-you-need}

Open `config/fortify.php` and you will find that Fortify treats every capability as an opt-in feature. This is the control panel for the whole package. Rather than forcing every application to expose registration or two-factor authentication, Fortify lets you list exactly the features you want in the `features` array, and it only registers routes for the ones present.

Look at the `features` array near the bottom of the file. A fresh install enables a sensible default set. For this tutorial we want registration, password resets, profile and password updates, and two-factor authentication. We are leaving passkeys out to keep the focus on classic authentication, so comment that entry out.

```php
'features' => [
    Features::registration(),
    Features::resetPasswords(),
    // Features::emailVerification(),
    Features::updateProfileInformation(),
    Features::updatePasswords(),
    Features::twoFactorAuthentication([
        'confirm' => true,
        'confirmPassword' => true,
        // 'window' => 0,
    ]),
    // Features::passkeys([
    //     'confirmPassword' => true,
    // ]),
],
```

Each entry maps directly to a set of routes. `Features::registration()` gives you the `GET /register` and `POST /register` routes, `Features::resetPasswords()` gives you the forgot-password and reset-password routes, and `Features::twoFactorAuthentication()` wires up the two-factor endpoints. Remove an entry and those routes simply stop existing, which is a clean way to lock down an application that should not allow self-registration, for example.

While you are in this file, set the `home` path to the page users should land on after they log in. By default it points at `/home`, but we will build a dashboard instead, so point it there.

```php
'home' => '/dashboard',
```

A few other keys near the top are worth knowing even though the defaults are fine for us. The `guard` key (`web`) tells Fortify which authentication guard to use, `username` (`email`) sets which field acts as the login identifier, and `middleware` (`['web']`) controls the middleware applied to Fortify's routes. Leave them as they are.

## Step 4: Bind the Authentication Views {#step-4-bind-the-authentication-views}

This is the step where the headless idea becomes concrete. Fortify has registered a `GET /login` route, but it does not know what your login page looks like, so out of the box that route returns nothing useful. Your job is to tell Fortify which view to render for each of these pages. You do that in the `boot` method of `FortifyServiceProvider` using the `Fortify` facade.

Open `app/Providers/FortifyServiceProvider.php` and add the view bindings just below the existing action registrations. You also need to import the `Request` class, since the reset-password view needs the incoming request to read the reset token.

```php
use Illuminate\Http\Request;
use Laravel\Fortify\Fortify;

// ... inside the boot() method, after the existing Fortify::...Using() calls:

Fortify::loginView(fn () => view('auth.login'));
Fortify::registerView(fn () => view('auth.register'));
Fortify::requestPasswordResetLinkView(fn () => view('auth.forgot-password'));
Fortify::resetPasswordView(fn (Request $request) => view('auth.reset-password', ['request' => $request]));
```

Each of these methods binds a view to the matching GET route. `Fortify::loginView()` decides what renders at `GET /login`, `Fortify::registerView()` handles `GET /register`, and so on. Notice that we only ever supply the view for the GET request. The POST side, the part that validates credentials, creates the session, hashes the password, and sends the reset email, is owned entirely by Fortify. This is the division of labor that makes Fortify frontend-agnostic: a React starter kit would return an Inertia page here instead of a Blade view, but the backend logic stays identical.

Because we enabled two-factor authentication with confirmation, the User model also needs Fortify's trait so it can generate and store secrets. Open `app/Models/User.php` and add the `TwoFactorAuthenticatable` trait.

```php
use Laravel\Fortify\TwoFactorAuthenticatable;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, TwoFactorAuthenticatable;

    // ...
}
```

The `TwoFactorAuthenticatable` trait adds the methods Fortify uses behind the scenes to enable two-factor authentication, generate recovery codes, and validate one-time passwords against the stored secret. Without it, the two-factor columns would just sit empty.

## Step 5: Build the Blade Views and Dashboard {#step-5-build-the-blade-views-and-dashboard}

Now we supply the actual pages. Each view is a standalone HTML document styled with Tailwind from the CDN, and each form posts to the route name Fortify already registered. The key detail to keep in mind is that you never write a controller or a route for these forms. Fortify's routes already exist; your form just needs to point its `action` at the right URL and include a CSRF token.

Create the login page at `resources/views/auth/login.blade.php`. The form posts to `/login`, which Fortify handles.

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Log In</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-6">Log In</h1>

        @if (session('status'))
            <div class="mb-4 rounded bg-green-100 text-green-800 px-4 py-3 text-sm">
                {{ session('status') }}
            </div>
        @endif

        @if ($errors->any())
            <div class="mb-4 rounded bg-red-100 text-red-800 px-4 py-3 text-sm">
                {{ $errors->first() }}
            </div>
        @endif

        <form method="POST" action="/login" class="space-y-4">
            @csrf

            <div>
                <label for="email" class="block text-sm font-medium mb-1">Email</label>
                <input id="email" name="email" type="email" value="{{ old('email') }}" required autofocus
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <div>
                <label for="password" class="block text-sm font-medium mb-1">Password</label>
                <input id="password" name="password" type="password" required
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <div class="flex items-center justify-between">
                <label class="flex items-center text-sm">
                    <input type="checkbox" name="remember" class="mr-2">
                    Remember me
                </label>
                <a href="/forgot-password" class="text-sm text-blue-600 hover:underline">Forgot password?</a>
            </div>

            <button type="submit"
                class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 transition">Log In</button>
        </form>

        <p class="mt-4 text-sm text-center">
            Need an account?
            <a href="/register" class="text-blue-600 hover:underline">Register</a>
        </p>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Laravel Fortify at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

Two Blade details are doing real work here. The `@csrf` directive outputs the hidden CSRF token that Laravel requires on every POST; without it Fortify would reject the request. The `$errors` bag and `session('status')` block let Fortify communicate back to you: failed logins land in `$errors`, and messages such as "a reset link has been sent" arrive in the status session key. Fortify populates both for you.

Next create the registration page at `resources/views/auth/register.blade.php`. It posts to `/register` and includes a password confirmation field, which Fortify validates by default.

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-6">Create an Account</h1>

        @if ($errors->any())
            <div class="mb-4 rounded bg-red-100 text-red-800 px-4 py-3 text-sm">
                <ul class="list-disc list-inside">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="/register" class="space-y-4">
            @csrf

            <div>
                <label for="name" class="block text-sm font-medium mb-1">Name</label>
                <input id="name" name="name" type="text" value="{{ old('name') }}" required autofocus
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <div>
                <label for="email" class="block text-sm font-medium mb-1">Email</label>
                <input id="email" name="email" type="email" value="{{ old('email') }}" required
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <div>
                <label for="password" class="block text-sm font-medium mb-1">Password</label>
                <input id="password" name="password" type="password" required
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <div>
                <label for="password_confirmation" class="block text-sm font-medium mb-1">Confirm Password</label>
                <input id="password_confirmation" name="password_confirmation" type="password" required
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <button type="submit"
                class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 transition">Register</button>
        </form>

        <p class="mt-4 text-sm text-center">
            Already registered?
            <a href="/login" class="text-blue-600 hover:underline">Log in</a>
        </p>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Laravel Fortify at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The field names matter here. Fortify's `CreateNewUser` action expects `name`, `email`, `password`, and `password_confirmation`, so as long as your inputs use those names, registration works with no extra wiring. If you wanted to add a field like a username, this is where you would add the input, and `app/Actions/Fortify/CreateNewUser.php` is where you would add its validation rule.

Now create the two password-reset views. The first, `resources/views/auth/forgot-password.blade.php`, is where a user requests a reset link. It posts to `/forgot-password`.

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Forgot Password</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-2">Forgot Your Password?</h1>
        <p class="text-sm text-gray-600 mb-6">
            Enter your email and we will send you a password reset link.
        </p>

        @if (session('status'))
            <div class="mb-4 rounded bg-green-100 text-green-800 px-4 py-3 text-sm">
                {{ session('status') }}
            </div>
        @endif

        @if ($errors->any())
            <div class="mb-4 rounded bg-red-100 text-red-800 px-4 py-3 text-sm">
                {{ $errors->first() }}
            </div>
        @endif

        <form method="POST" action="/forgot-password" class="space-y-4">
            @csrf

            <div>
                <label for="email" class="block text-sm font-medium mb-1">Email</label>
                <input id="email" name="email" type="email" value="{{ old('email') }}" required autofocus
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <button type="submit"
                class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 transition">Email Password Reset Link</button>
        </form>

        <p class="mt-4 text-sm text-center">
            <a href="/login" class="text-blue-600 hover:underline">Back to log in</a>
        </p>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Laravel Fortify at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The second, `resources/views/auth/reset-password.blade.php`, is the page the user reaches from the emailed link. It posts to `/reset-password` and carries a hidden `token` field. This is why we passed `$request` into this view in Step 4: the token and email arrive as part of the request, and the form has to send them back so Fortify can verify the reset is legitimate.

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-6">Reset Password</h1>

        @if ($errors->any())
            <div class="mb-4 rounded bg-red-100 text-red-800 px-4 py-3 text-sm">
                {{ $errors->first() }}
            </div>
        @endif

        <form method="POST" action="/reset-password" class="space-y-4">
            @csrf

            <input type="hidden" name="token" value="{{ $request->route('token') }}">

            <div>
                <label for="email" class="block text-sm font-medium mb-1">Email</label>
                <input id="email" name="email" type="email" value="{{ old('email', $request->email) }}" required autofocus
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <div>
                <label for="password" class="block text-sm font-medium mb-1">New Password</label>
                <input id="password" name="password" type="password" required
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <div>
                <label for="password_confirmation" class="block text-sm font-medium mb-1">Confirm New Password</label>
                <input id="password_confirmation" name="password_confirmation" type="password" required
                    class="w-full rounded border border-gray-300 px-3 py-2 focus:outline-none focus:ring focus:border-blue-400">
            </div>

            <button type="submit"
                class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 transition">Reset Password</button>
        </form>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Laravel Fortify at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The last piece is the destination. Fortify sends authenticated users to the `home` path we set to `/dashboard`, but that route does not exist yet, so add it. Open `routes/web.php` and register a dashboard route protected by the `auth` middleware.

```php
Route::view('/dashboard', 'dashboard')
    ->middleware('auth')
    ->name('dashboard');
```

The `auth` middleware is what makes this route private; any guest who tries to open it is redirected to `/login`. Notice we did not add a logout route. Fortify already registered `POST /logout` for us, so the dashboard view only needs a small form that posts to it. Create `resources/views/dashboard.blade.php`.

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex items-center justify-between mb-6">
            <h1 class="text-2xl font-bold">Dashboard</h1>

            <form method="POST" action="/logout">
                @csrf
                <button type="submit"
                    class="bg-gray-800 text-white px-4 py-2 rounded hover:bg-gray-900 transition">Log Out</button>
            </form>
        </div>

        <p class="text-gray-700">
            Welcome back, <span class="font-semibold">{{ auth()->user()->name }}</span>.
            You are signed in through Laravel Fortify.
        </p>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Laravel Fortify at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

## Step 6: Enable Two-Factor Authentication {#step-6-enable-two-factor-authentication}

Two-factor authentication is the feature that made you curious about Fortify in the first place, because it is the thing the starter kits show off. The good news is that you have already enabled it. Adding `Features::twoFactorAuthentication()` in Step 3, running the migration in Step 2, and adding the `TwoFactorAuthenticatable` trait in Step 4 together mean two-factor is live and ready. To prove it, list the routes Fortify registered for it.

```bash
php artisan route:list --path=two-factor
```

```
  GET|HEAD   two-factor-challenge .................... two-factor.login › Laravel\Fortify › TwoFactorAuthenticatedSessionController@create
  POST       two-factor-challenge ............... two-factor.login.store › Laravel\Fortify › TwoFactorAuthenticatedSessionController@store
  POST       user/confirmed-two-factor-authentication two-factor.confirm › Laravel\Fortify › ConfirmedTwoFactorAuthenticationController@s…
  POST       user/two-factor-authentication ................ two-factor.enable › Laravel\Fortify › TwoFactorAuthenticationController@store
  DELETE     user/two-factor-authentication ............. two-factor.disable › Laravel\Fortify › TwoFactorAuthenticationController@destroy
  GET|HEAD   user/two-factor-qr-code ............................... two-factor.qr-code › Laravel\Fortify › TwoFactorQrCodeController@show
  GET|HEAD   user/two-factor-recovery-codes ................... two-factor.recovery-codes › Laravel\Fortify › RecoveryCodeController@index
  POST       user/two-factor-recovery-codes ........ two-factor.regenerate-recovery-codes › Laravel\Fortify › RecoveryCodeController@store
  GET|HEAD   user/two-factor-secret-key ...................... two-factor.secret-key › Laravel\Fortify › TwoFactorSecretKeyController@show
```

Each of these endpoints has a clear job, and reading them top to bottom tells the whole two-factor story. A logged-in user sends a `POST` to `user/two-factor-authentication` to switch it on, which generates a secret. They then fetch `user/two-factor-qr-code` to display a QR code their authenticator app can scan, and `user/two-factor-recovery-codes` to see one-time backup codes. Because we set `'confirm' => true`, they must post a valid code to `user/confirmed-two-factor-authentication` before it fully activates. From then on, logging in with a correct password redirects to `two-factor-challenge` instead of the dashboard, where the user enters their app's six-digit code. A `DELETE` to `user/two-factor-authentication` turns it back off.

Building the QR-code and recovery-code interface is a tutorial of its own, so we are stopping at "enabled and explained" here. The important takeaway is that Fortify already gives you every endpoint; wiring a real two-factor UI is a matter of calling these routes from a settings page, which is exactly what the starter kits do. We will cover that build in a dedicated follow-up.

## Step 7: Try It Out {#step-7-try-it-out}

With everything wired up, start the development server and walk through the flow like a real user.

```bash
php artisan serve
```

```
   INFO  Server running on [http://127.0.0.1:8000].

  Press Ctrl+C to stop the server
```

Open `http://127.0.0.1:8000/register` in your browser and create an account. Fill in a name, an email, and a password with its confirmation, then submit. Fortify's `POST /register` route validates the input, creates the user, logs them in, and redirects to the dashboard. Here is that exact round trip captured against the running server, showing the `302` redirect straight to `/dashboard`.

```
### Registering a new user via POST /register
HTTP status: 302
Redirects to: http://127.0.0.1:8899/dashboard

### Visiting the protected /dashboard as the logged-in user
Welcome back, Budi Santoso
```

The new user is now in the database. You can confirm it with Tinker, which shows the record Fortify's `CreateNewUser` action inserted.

```
### Users now in the database
Array
(
    [id] => 1
    [name] => Budi Santoso
    [email] => budi@example.com
```

Now try the password reset. From the login page click "Forgot password?", enter the email you registered with, and submit. Fortify generates a signed reset link and sends it through your configured mailer. A fresh Laravel project uses the `log` mail driver by default, so instead of a real email the message is written to `storage/logs/laravel.log`. Open that file and you will find the reset link waiting.

```
### The reset email written to storage/logs/laravel.log
Subject: Reset your password
Reset Password: http://127.0.0.1:8899/reset-password/9922542d0567aa8aab8593d5fee83ffc0d0a1052c6c827812996881ecb049f2d?email=budi%40example.com
```

Paste that URL into your browser and it opens the reset-password view we built, with the token and email already filled in. Set a new password, submit, and Fortify updates the record and redirects you to the login page with a success status. Finally, log in with the new password and click "Log Out" on the dashboard to confirm the full cycle works.

## Step 8: Write Tests {#step-8-write-tests}

Clicking through the browser proves the flow works today, but tests prove it keeps working tomorrow. Because Fortify exposes ordinary routes, testing it is no different from testing any Laravel endpoint. Create a test file at `tests/Feature/FortifyAuthTest.php` that exercises the whole surface: rendering the pages, registering, logging in with good and bad credentials, logging out, protecting the dashboard, requesting a reset link, and confirming the two-factor columns exist.

```php
<?php

use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Schema;

uses(RefreshDatabase::class);

test('the login screen can be rendered', function () {
    $this->get('/login')->assertOk()->assertSee('Log In');
});

test('the registration screen can be rendered', function () {
    $this->get('/register')->assertOk()->assertSee('Create an Account');
});

test('a new user can register', function () {
    $response = $this->post('/register', [
        'name' => 'Aisyah',
        'email' => 'aisyah@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    $response->assertRedirect('/dashboard');
    $this->assertAuthenticated();
    $this->assertDatabaseHas('users', ['email' => 'aisyah@example.com']);
});

test('a user can log in with valid credentials', function () {
    $user = User::factory()->create([
        'password' => Hash::make('password123'),
    ]);

    $response = $this->post('/login', [
        'email' => $user->email,
        'password' => 'password123',
    ]);

    $response->assertRedirect('/dashboard');
    $this->assertAuthenticatedAs($user);
});

test('a user cannot log in with an invalid password', function () {
    $user = User::factory()->create([
        'password' => Hash::make('password123'),
    ]);

    $this->post('/login', [
        'email' => $user->email,
        'password' => 'wrong-password',
    ])->assertSessionHasErrors('email');

    $this->assertGuest();
});

test('an authenticated user can log out', function () {
    $user = User::factory()->create();

    $this->actingAs($user)->post('/logout')->assertRedirect('/');

    $this->assertGuest();
});

test('a guest is redirected away from the dashboard', function () {
    $this->get('/dashboard')->assertRedirect('/login');
});

test('a password reset link can be requested', function () {
    Notification::fake();

    $user = User::factory()->create();

    $this->post('/forgot-password', ['email' => $user->email]);

    Notification::assertSentTo($user, ResetPassword::class);
});

test('the users table has the two factor columns', function () {
    expect(Schema::hasColumn('users', 'two_factor_secret'))->toBeTrue();
    expect(Schema::hasColumn('users', 'two_factor_recovery_codes'))->toBeTrue();
});
```

A few of these tests lean on Laravel testing helpers that make Fortify easy to verify. `assertAuthenticated` and `assertGuest` check the session state after a request, so a passing "invalid password" test confirms a failed login really does leave the user logged out. `Notification::fake()` intercepts the reset email so the test can assert the `ResetPassword` notification was queued without sending anything. Run the whole suite.

```bash
php artisan test
```

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.12s

   PASS  Tests\Feature\FortifyAuthTest
  ✓ the login screen can be rendered                                     0.10s
  ✓ the registration screen can be rendered                              0.02s
  ✓ a new user can register                                              0.04s
  ✓ a user can log in with valid credentials                            0.04s
  ✓ a user cannot log in with an invalid password                       0.03s
  ✓ an authenticated user can log out                                   0.03s
  ✓ a guest is redirected away from the dashboard                       0.02s
  ✓ a password reset link can be requested                              0.24s
  ✓ the users table has the two factor columns                          0.10s

  Tests:    11 passed (26 assertions)
  Duration: 0.81s
```

All eleven tests pass, which means registration, login, logout, route protection, password resets, and the two-factor schema all behave correctly on a project that had zero authentication a few steps ago.

## How Fortify Works Under the Hood {#how-fortify-works-under-the-hood}

Now that the flow is working, it is worth stepping back to see why the pieces fit together the way they do, because the design is what makes Fortify reusable across such different frontends. The whole package rests on a strict separation between routing and rendering.

When Fortify boots, it reads the `features` array from `config/fortify.php` and registers a fixed set of routes and controllers for each enabled feature. Those controllers contain all the security-sensitive logic: throttling login attempts, hashing passwords, regenerating the session on login to prevent fixation, verifying signed reset tokens, and validating one-time passwords. You never wrote any of that, and you should not have to, because getting it wrong is how applications get breached.

What Fortify deliberately does not decide is presentation. For every GET route that shows a page, Fortify calls back to a view you registered with the `Fortify` facade, which is why Step 4 existed. And for every action that changes data, such as creating a user or resetting a password, Fortify delegates to the action classes in `app/Actions/Fortify`. That is where your application-specific rules live, so adding a field to registration means editing `CreateNewUser.php`, not forking the package. After a successful action, Fortify returns a response object such as `LoginResponse` or `RegisterResponse`, and because those are bound in the container you can override where users get redirected without touching a controller. This is exactly how a starter kit swaps in Inertia or an API response while keeping the same secure backend.

## Fortify vs Breeze vs Sanctum {#fortify-vs-breeze-vs-sanctum}

Laravel offers several authentication packages, and it is easy to assume they compete when they actually solve different problems. Knowing which one to reach for saves you from bolting the wrong tool onto a project. Here is how the three most common choices relate.

- **Laravel Breeze** is scaffolding you own. It generates real routes, controllers, and Blade or Inertia views directly into your application, and then it steps out of the way. It is perfect when you want a simple, editable starting point and do not mind that the generated code is now your responsibility to maintain. See our [Laravel Breeze tutorial](https://qadrlabs.com) for that approach.
- **Laravel Fortify** is a headless backend, which is what we built here. It keeps the authentication logic inside the package and lets you supply any frontend, whether Blade, React, Vue, or Livewire. This is why the official starter kits are built on it, and why it is the right choice when you want first-party security without owning the boilerplate.
- **Laravel Sanctum** is not a login-page package at all. It issues API tokens and manages SPA session authentication, so you reach for it when a mobile app or a separate JavaScript frontend needs to authenticate against your API. Our [Sanctum API authentication tutorial](https://qadrlabs.com) covers that use case.

In practice these are often combined rather than chosen between. A single application might use Fortify for its web login and Sanctum for its API, because one guards browser sessions and the other guards token requests.

## Conclusion {#conclusion}

Laravel Fortify turns the mystery of "how do the starter kits do authentication" into a handful of explicit, controllable steps. You installed a headless backend, enabled exactly the features you wanted, pointed its routes at your own Blade views, and ended with registration, login, logout, password resets, and two-factor authentication running on a project that began with nothing but a welcome page. Here are the ideas worth carrying forward.

- **Fortify is headless by design.** It owns the routes, controllers, and security logic but never the views, which is why the same package powers Blade, React, Vue, and Livewire starter kits alike.
- **Features are opt-in through config.** The `features` array in `config/fortify.php` is the single switchboard; a feature that is not listed has no routes, which makes locking down registration or two-factor a one-line change.
- **You bind views, Fortify handles POSTs.** Registering `Fortify::loginView()` and its siblings supplies only the GET pages, while credential checking, hashing, and session handling stay inside the package where they belong.
- **Action classes are your extension point.** The files in `app/Actions/Fortify` hold the create-and-update logic in your own codebase, so customizing validation or adding fields never means editing the vendor directory.
- **Two-factor comes almost for free.** Enabling the feature, running the migration, and adding the `TwoFactorAuthenticatable` trait registers a full set of two-factor endpoints, leaving only the user interface for you to build on top.
