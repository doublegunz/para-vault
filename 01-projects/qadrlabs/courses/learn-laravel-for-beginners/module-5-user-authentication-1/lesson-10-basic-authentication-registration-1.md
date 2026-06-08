Over the last several lessons, we have built a lot on top of the assumption that the user is already logged in, thanks to the `/dev-login` route we created as a temporary shortcut. That was enough to develop the CRUD features without being held up by an authentication system that did not exist yet. But that shortcut cannot stay forever, and this lesson is where we replace it with the real thing.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the `/dev-login` route can be deleted permanently. Users will be able to register with a real account, get logged in automatically after registration, and the entire flow we have built since Lesson 7 can finally be tested the proper way.

### What You'll Learn

- What authentication is and why Catatku needs it
- How to create a dedicated `AuthController` for handling registration
- How to validate registration input with rules like `unique`, `confirmed`, and `min`
- Why passwords must be hashed before storage and how `Hash::make()` works
- How `Auth::login()` creates a session for the newly registered user
- How `middleware('guest')` restricts pages to unauthenticated visitors only
- How the `password_confirmation` field works with the `confirmed` validation rule

### What You'll Need

- The `catatku` project open in VS Code with the development server running
- All changes from previous lessons saved and working
- The temporary `/dev-login` route still in place (we will remove it at the end of this lesson)

---

## Step 1: Create the AuthController {#step-1-create-the-authcontroller}

Authentication logic does not belong in `EntryController`. Entries and user accounts are separate concerns, so they get separate controllers. Run the following command to generate a new controller:

```bash
php artisan make:controller AuthController
```
Output:
```
$ php artisan make:controller AuthController

   INFO  Controller [app/Http/Controllers/AuthController.php] created successfully.
```

Open `app/Http/Controllers/AuthController.php` and add the registration methods:

```php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function showRegister()
    {
        return view('auth.register');
    }

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

        return redirect('/entries')
            ->with('success', 'Welcome to Catatku, ' . $user->name . '!');
    }
}
```

The controller has two methods that follow the same two-step form pattern we used for creating entries: one GET method to show the form and one POST method to process the submission. Let us walk through the `register()` method step by step.

### Validation Rules {#validation-rules}

```php
$validated = $request->validate([
    'name'     => 'required|string|max:255',
    'email'    => 'required|email|unique:users,email',
    'password' => 'required|string|min:8|confirmed',
]);
```

Most of these rules are familiar from previous lessons. The new ones are:

`email` ensures the value has a valid email format (contains an `@` symbol and a domain name).

`unique:users,email` checks the database to verify that this email is not already used by another user. The format is `unique:table_name,column_name`. If someone tries to register with an email that already exists, validation fails with a clear error message.

`min:8` requires the password to be at least 8 characters long. Short passwords are easy to guess or brute-force, so enforcing a minimum length is a basic security measure.

`confirmed` is a special rule that requires a matching confirmation field. When you add `confirmed` to the `password` field, Laravel automatically looks for a field named `password_confirmation` in the form data. If the two values do not match, validation fails. This prevents users from accidentally mistyping their password during registration, which would lock them out of their own account.

### Password Hashing {#password-hashing}

```php
'password' => Hash::make($validated['password']),
```

Passwords must **never** be stored as plain text. If the database is ever compromised, every user's password would be immediately exposed. `Hash::make()` transforms the password into a hash that cannot be reversed:

```
Input:   "secret123"
Output:  "$2y$12$LkIKjbPXRGkpVBz..."
```

Every time you hash the same password, the result is different because `Hash::make()` adds a random salt. But Laravel can still verify a password against its hash using `Hash::check('secret123', $hashedValue)`. This one-way nature is the core of password security: you can verify without ever storing or revealing the original.

### Automatic Login {#automatic-login}

```php
Auth::login($user);
```

After the user is successfully created, we log them in immediately without requiring them to visit the login page and enter their credentials again. This creates a better user experience. The `Auth::login()` method creates a session for the user, and from this point on, `auth()->user()` will return this user object in all subsequent requests.

---

## Step 2: Add the Registration Routes {#step-2-add-the-registration-routes}

Update `routes/web.php` with the registration routes and remove the `/dev-login` shortcut:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;
use App\Http\Controllers\AuthController; // [ ... Add this line of code ... ]

Route::get('/', function () {
    return view('home');
});

// Add a route for the registration feature
Route::middleware('guest')->group(function () {
    Route::get('/register', [AuthController::class, 'showRegister']);
    Route::post('/register', [AuthController::class, 'register']);
});

Route::get('/entries', [EntryController::class, 'index']);

Route::middleware('auth')->group(function () {
    Route::get('/entries/create', [EntryController::class, 'create']);
    Route::post('/entries', [EntryController::class, 'store']);
    Route::get('/entries/{entry}', [EntryController::class, 'show']);
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

Notice that the `/dev-login` route is gone. We no longer need it.

The registration routes are wrapped in `middleware('guest')`. This middleware is the opposite of `middleware('auth')`: it only allows unauthenticated visitors. If a user who is already logged in tries to access `/register`, they will be redirected to the home page automatically. There is no reason for a logged-in user to see the registration form.

We now have two middleware groups in the route file. The `guest` group contains pages that only non-authenticated visitors should see (registration, and soon, login). The `auth` group contains pages that require authentication (everything that creates, modifies, or deletes entries). And some routes, like `/entries` (the listing) and `/` (the home page), sit outside both groups because they are accessible to everyone.

---

## Step 3: Verify the User Model {#step-3-verify-the-user-model}

Before testing registration, let us make sure the `User` model is configured to accept the fields we are sending. Open `app/Models/User.php`. In Laravel 13, the default User model already uses the `#[Fillable]` attribute:

```php
#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    // ...
}
```

The `#[Fillable]` attribute lists `name`, `email`, and `password` as mass-assignable fields. This matches exactly what our `register()` method passes to `User::create()`. The `#[Hidden]` attribute ensures that `password` and `remember_token` are excluded when the model is serialized to JSON, preventing sensitive data from accidentally leaking in API responses.

If your User model still uses the older `protected $fillable` syntax, both approaches work. But the `#[Fillable]` attribute is the standard in Laravel 13, as we discussed in Lesson 6.

---

## Step 4: Create the Registration View {#step-4-create-the-registration-view}

Create the folder `resources/views/auth/` and the file `resources/views/auth/register.blade.php`:

```html
<x-layout title="Register — Catatku">

    <div class="max-w-sm mx-auto">

        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Join Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">
                Your personal journal space
            </p>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <form method="POST" action="/register">
                @csrf

                {{-- Name --}}
                <div class="mb-4">
                    <label for="name"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Name
                    </label>
                    <input
                        type="text"
                        id="name"
                        name="name"
                        value="{{ old('name') }}"
                        placeholder="Your full name"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                               focus:ring-2 focus:ring-gray-900 focus:border-transparent
                               {{ $errors->has('name') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                        autofocus
                    >
                    @error('name')
                        <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Email --}}
                <div class="mb-4">
                    <label for="email"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Email
                    </label>
                    <input
                        type="email"
                        id="email"
                        name="email"
                        value="{{ old('email') }}"
                        placeholder="name@email.com"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                               focus:ring-2 focus:ring-gray-900 focus:border-transparent
                               {{ $errors->has('email') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                    >
                    @error('email')
                        <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Password --}}
                <div class="mb-4">
                    <label for="password"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Password
                    </label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        placeholder="At least 8 characters"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                               focus:ring-2 focus:ring-gray-900 focus:border-transparent
                               {{ $errors->has('password') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                    >
                    @error('password')
                        <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Confirm Password --}}
                <div class="mb-6">
                    <label for="password_confirmation"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Confirm Password
                    </label>
                    <input
                        type="password"
                        id="password_confirmation"
                        name="password_confirmation"
                        placeholder="Re-enter your password"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm
                               focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent"
                    >
                </div>

                <button type="submit"
                    class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium
                           hover:bg-gray-700 transition-colors">
                    Create Account
                </button>

            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Already have an account?
            <a href="/login" class="text-gray-900 font-medium hover:underline">
                Log in here
            </a>
        </p>

    </div>

</x-layout>
```

This form follows the same patterns we have been using: `@csrf` for CSRF protection, `old()` for preserving input after validation failures, `@error` for displaying field-specific error messages, and conditional CSS classes for visual error indicators.

There are two things worth noting about the password fields. First, the `password` input does not use `old()`. This is intentional. For security reasons, you should never send password values back to the browser, even after a validation failure. The user will need to retype their password, which is a small inconvenience but an important security practice.

Second, the `password_confirmation` field has the exact name `password_confirmation`. This naming convention is required by the `confirmed` validation rule. When Laravel sees `confirmed` on the `password` field, it looks for a companion field named `{fieldname}_confirmation`. If you named it anything else, the validation would not work.

---

## Step 5: Test the Registration Flow {#step-5-test-the-registration-flow}
In this step, we will test the registration feature. If we have already logged in, we can use a different browser to test this registration feature.

Make sure the development server is running, then test the following scenarios:

1. Go to `http://127.0.0.1:8000/register`. You should see the registration form with fields for name, email, password, and password confirmation.
![access register page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/16-access-register-page.webp)

2. Try submitting the form with all fields empty. You should be redirected back to the form with red-bordered inputs and error messages below each required field.
![validation test -- all empty](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/17-register-validation-test-all-empty.webp)

3. Fill in the name and email, but enter a password shorter than 8 characters. The password field should show an error about the minimum length.

![validation test - password field shorter](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/18-register-validation-password-field.webp)

4. Enter a valid password in the password field but type something different in the confirmation field. You should see an error saying the password confirmation does not match.
![validation test - password not match](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/19-register-validation-password-not-match.webp)

5. Fill in all fields correctly with valid data and click "Create Account." You should be redirected to the entries listing with a welcome message like "Welcome to Catatku, New user!"
![new user registered](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/20-user-registered.webp)

6. Try visiting `/register` again while still logged in. You should be redirected away from the registration page because the `guest` middleware prevents authenticated users from accessing it.

7. Try registering with the same email you just used. You should see an error on the email field saying it has already been taken.
![validation test - email taken](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/21-register-validation-email-taken.webp)

---

## What is Authentication? {#what-is-authentication}

Authentication is the process of proving identity, verifying that someone is who they claim to be. In Catatku, authentication involves three operations:

**Registration** is when a user signs up with a name, email, and password. The data is validated, the password is hashed, the account is saved to the database, and the user is logged in automatically.

**Login** is when an existing user provides their email and password. The system verifies the credentials against what is stored in the database. If they match, a session is created.

**Logout** is when the session is destroyed. The user returns to being an unauthenticated visitor.

Without authentication, we would have no way to know who wrote which entry, and all the privacy features we have built would not function correctly. The `user_id` column in the `entries` table, the `abort(403)` checks in the controller, and the `@auth` directive in the layout all depend on knowing who the current user is.

In this lesson, we built the registration piece. Login and logout will be completed in the next lesson.

---

## Conclusion {#conclusion}

The registration system is now fully working. Here are the key takeaways:

- **Authentication** is the process of verifying user identity. Registration, login, and logout are the three core operations.
- The `AuthController` handles authentication logic separately from entry management, keeping concerns properly separated.
- `unique:users,email` checks the database to ensure no two users share the same email address.
- The `confirmed` validation rule requires a companion field named `{field}_confirmation` with a matching value. This prevents password typos during registration.
- `Hash::make()` converts a plain text password into a bcrypt hash that cannot be reversed. **Never store passwords as plain text.** If the database is compromised, hashed passwords protect your users because the original values cannot be recovered.
- `Auth::login($user)` creates a session for the user, logging them in immediately after registration so they do not need to enter their credentials a second time.
- `middleware('guest')` restricts routes to unauthenticated visitors only. Logged-in users are redirected away automatically. This is the counterpart to `middleware('auth')`.
- Password fields should **never** use `old()` to preserve values after validation failures. Sending passwords back to the browser, even in a form field, is a security risk.
- The `/dev-login` route is no longer needed and has been removed. From this point forward, all authentication goes through the real system.
- The default `User` model in Laravel 13 uses `#[Fillable(['name', 'email', 'password'])]` and `#[Hidden(['password', 'remember_token'])]` attributes, matching the modern attribute-based approach we use for the `Entry` model.

In the next lesson, we will complete the authentication system with login and logout functionality. After that, Catatku will stand entirely on its own foundation, with no shortcuts or workarounds remaining.