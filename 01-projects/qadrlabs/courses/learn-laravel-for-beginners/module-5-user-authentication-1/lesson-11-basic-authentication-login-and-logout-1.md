The previous lesson completed the registration flow. Users can create an account and get logged in automatically. But there is one scenario we have not handled yet: a user who already has an account, closes the browser, and comes back the next day. They need a way to log back in. And users who are done need a way to log out safely. This lesson builds both, and it is the final lesson that touches the authentication system.

## Overview {#overview}

### What You'll Build

By the end of this lesson, there will be no gaps left in the authentication flow. Guests are directed to the login page, logged-in users cannot access the registration or login pages again, and the entire flow from signing up to logging out works without any development shortcuts. We will also update the home page with real navigation links, make the entries listing fully private, and update the controller to show only the current user's entries.

### What You'll Learn

- How `Auth::attempt()` verifies credentials against the database
- Why session regeneration after login protects against session fixation attacks
- Why login error messages should be intentionally vague
- How the three-step logout process works and why each step matters
- How to use `->name('login')` to give a route a name that Laravel's auth middleware depends on
- How `back()->withErrors()->onlyInput()` sends error messages back to the form while preserving only safe input
- How to update the home page to link to real authentication routes
- Why the controller query changes from `Entry::with('user')` to `auth()->user()->entries()` once authentication is in place

### What You'll Need

- The `catatku` project open in VS Code with the development server running
- The `AuthController` with registration methods from Lesson 10
- At least one registered user account for testing login

---

## Step 1: Add Login and Logout Methods to AuthController {#step-1-add-login-and-logout-methods-to-authcontroller}

Open `app/Http/Controllers/AuthController.php` and add the login and logout methods below the existing registration methods:

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
    // --- Registration (from Lesson 10) ---

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

    // --- Login ---

    public function showLogin()
    {
        return view('auth.login');
    }

    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        if (Auth::attempt($credentials)) {
            $request->session()->regenerate();

            return redirect('/entries')
                ->with('success', 'Welcome back!');
        }

        return back()->withErrors([
            'email' => 'The email or password you entered is incorrect.',
        ])->onlyInput('email');
    }

    // --- Logout ---

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/login');
    }
}
```

Let us walk through each new method in detail.

### The `login()` Method {#the-login-method}

The login method has three distinct phases: validate the input format, attempt authentication, and handle failure.

```php
$credentials = $request->validate([
    'email'    => 'required|email',
    'password' => 'required|string',
]);
```

This first step validates that the email and password fields are present and have the correct format. Notice that we do not use `unique` or `min:8` here. These rules were for registration. During login, we only care that the fields are not empty and that the email looks like an email. The actual credential verification happens in the next step.

```php
if (Auth::attempt($credentials)) {
    $request->session()->regenerate();

    return redirect('/entries')
        ->with('success', 'Welcome back!');
}
```

`Auth::attempt($credentials)` does two things in a single call: it searches for a user with the given email, then verifies the password against the stored hash using `Hash::check()`. If both succeed, it creates a session for the user and returns `true`. If either fails (email not found or password mismatch), it returns `false`. You do not need to write any of this lookup or verification logic yourself.

`$request->session()->regenerate()` generates a new session ID immediately after a successful login. This protects against **session fixation attacks**, where an attacker obtains a session ID before the victim logs in and then uses that same ID to hijack the authenticated session. By regenerating the ID after login, any previously obtained session ID becomes useless.

```php
return back()->withErrors([
    'email' => 'The email or password you entered is incorrect.',
])->onlyInput('email');
```

If `Auth::attempt()` returns `false`, we redirect the user back to the login form with an error message. Three things happen in this chain:

`back()` redirects to the previous page (the login form).

`withErrors(['email' => '...'])` attaches an error message to the `email` field. The message deliberately says "The email or password you entered is incorrect" without specifying which one was wrong. This vagueness is intentional. If the error said "email not found," an attacker could use the login form to discover which email addresses are registered in the system. Keeping the message generic prevents this information leak.

`onlyInput('email')` preserves only the email field value in the session. The password is intentionally excluded. Sending passwords back to the browser, even in a form field, is a security risk. The user will need to retype their password, but their email address will still be filled in.

### The `logout()` Method {#the-logout-method}

```php
public function logout(Request $request): RedirectResponse
{
    Auth::logout();

    $request->session()->invalidate();
    $request->session()->regenerateToken();

    return redirect('/login');
}
```

Logout involves three steps, and each one serves a different purpose:

`Auth::logout()` removes the user's identity from the current session. After this call, `auth()->user()` returns `null`.

`$request->session()->invalidate()` destroys the entire session data on the server. This ensures that no leftover data from the authenticated session can be reused.

`$request->session()->regenerateToken()` creates a new CSRF token. The old token was tied to the previous session, and if someone captured it, they could potentially use it to forge requests. Generating a new token after logout eliminates that risk.

These three steps together ensure a clean, secure logout with no session remnants that could be exploited.

---

## Step 2: Update the Routes {#step-2-update-the-routes}

Update `routes/web.php` with the final, complete route configuration:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;
use App\Http\Controllers\AuthController;

Route::get('/', function () {
    return view('home');
});

// Routes for guests (only accessible before login)
Route::middleware('guest')->group(function () {
    Route::get('/register', [AuthController::class, 'showRegister']);
    Route::post('/register', [AuthController::class, 'register']);
		
	// Add a login route
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login']);
});

// All routes that require login
Route::middleware('auth')->group(function () {

	// Add a route for logging out
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/entries', [EntryController::class, 'index']); // Move  /entries route into the `middleware(‘auth’)` group
    Route::get('/entries/create', [EntryController::class, 'create']);
    Route::post('/entries', [EntryController::class, 'store']);
    Route::get('/entries/{entry}', [EntryController::class, 'show']);
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

There are two important changes from the previous lesson's route file.

**`/entries` has moved inside the `middleware('auth')` group.** In earlier lessons, the entries listing was public so we could develop and test without a working authentication system. Now that registration and login are fully working, entries are completely private. Any guest who tries to access `/entries` will be automatically redirected to the login page. This matches the core promise of Catatku: all journal entries are personal and private.

Before:
```php
Route::get('/entries', [EntryController::class, 'index']);

Route::middleware('auth')->group(function () {
    
    // ... other routes

});
```
After:
```php
Route::middleware('auth')->group(function () {
    
    Route::get('/entries', [EntryController::class, 'index']);
     // ... other routes

});
```

**`->name('login')` gives the login route a name.** This is not just for convenience. Laravel's built-in `auth` middleware looks for a route named `login` when it needs to redirect unauthenticated users. Without this name, guests who try to access protected routes would get an error instead of being smoothly redirected to the login page. The `->name()` method is how you assign names to routes in Laravel.

The `logout` route uses POST, not GET. This is a security best practice. If logout were a GET request, a malicious website could include an image tag like `<img src="http://catatku.test/logout">` that would log users out without their knowledge. Making it POST and requiring a `@csrf` token prevents this.

---

## Step 3: Update the EntryController {#step-3-update-the-entrycontroller}

Now that `/entries` is inside the `middleware('auth')` group, the user is always authenticated when the `index()` method runs. This means we can and should update the query to show only the current user's entries instead of showing everyone's entries.

Open `app/Http/Controllers/EntryController.php` and update the `index()` method:

```php
public function index()
{
    $entries = auth()->user()->entries()->latest()->get();

    return view('entries.index', compact('entries'));
}
```

The rest of the controller stays the same. Here is why this change matters:

```php
// Before (Lessons 6-9): fetched ALL entries from ALL users
$entries = Entry::with('user')->latest()->get();

// Now (Lesson 11): fetches only the current user's entries
$entries = auth()->user()->entries()->latest()->get();
```

In Lessons 6 through 9, we used `Entry::with('user')->latest()->get()` because the `/entries` route was public and the authentication system did not exist yet. Calling `auth()->user()` on an unauthenticated visitor would crash the application. Using `Entry::with('user')` was a practical choice that let us develop and test CRUD features without being blocked by authentication.

Now that `/entries` lives inside `middleware('auth')`, Laravel guarantees that `auth()->user()` always returns a valid `User` object. It is safe to call `auth()->user()->entries()`, and more importantly, it is the *correct* thing to do. Catatku is a private journal application. Each user should only see their own entries, not everyone else's.

`auth()->user()->entries()->latest()->get()` works through the `hasMany` relationship we defined in Lesson 6. It automatically adds a `WHERE user_id = ?` clause to the SQL query, scoping the results to the authenticated user. You never need to manually filter by `user_id` in the query. The relationship handles it for you.

Notice that `with('user')` is no longer needed either. Since we are querying through the user's relationship, we already know who the user is. There is no need to eager load it.

---

## Step 4: Create the Login View {#step-4-create-the-login-view}

Create the file `resources/views/auth/login.blade.php`:

```html
<x-layout title="Log In — Catatku">

    <div class="max-w-sm mx-auto">

        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Log in to Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">
                Continue writing your journal
            </p>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <form method="POST" action="/login">
                @csrf

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
                        autofocus
                    >
                    @error('email')
                        <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Password --}}
                <div class="mb-6">
                    <label for="password"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Password
                    </label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        placeholder="Your password"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm
                               focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent"
                    >
                </div>

                <button type="submit"
                    class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium
                           hover:bg-gray-700 transition-colors">
                    Log In
                </button>

            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Don't have an account?
            <a href="/register" class="text-gray-900 font-medium hover:underline">
                Register now
            </a>
        </p>

    </div>

</x-layout>
```

The login form is simpler than the registration form because it only needs two fields: email and password. Notice that the password field does not use `old()`. As we discussed in Lesson 10, password values should never be sent back to the browser, even after a failed login attempt.

The `@error('email')` block will display the generic error message we defined in the controller ("The email or password you entered is incorrect.") when authentication fails. Because we attached the error to the `email` key using `withErrors(['email' => '...'])`, it appears below the email field, but the message itself covers both fields.

---

## Step 5: Update the Home Page {#step-5-update-the-home-page}

The home page buttons have been empty placeholders since Lesson 3. Now that authentication is in place, we can wire them up. Update `resources/views/home.blade.php`:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Catatku - Simple Journal App</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-900 font-sans antialiased selection:bg-blue-100">
    <div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-blue-50 to-white">
        <div class="max-w-2xl w-full text-center px-6 py-12">
            <h1 class="text-5xl font-extrabold tracking-tight text-blue-600 mb-6 drop-shadow-sm">Catatku</h1>
            <p class="text-xl text-gray-600 mb-10 leading-relaxed">
                A simple journal app to accompany your day. Start capturing what matters, easily and quickly.
            </p>
            
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
                @auth
                    <a href="{{ url('/entries') }}" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        My Entries
                    </a>
                @else
                    <a href="{{ url('/login') }}" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        Log In
                    </a>
                    <a href="{{ url('/register') }}" class="inline-flex items-center justify-center px-8 py-3.5 border border-gray-200 text-lg font-medium rounded-xl text-blue-700 bg-white hover:bg-gray-50 shadow-sm flex-1 sm:flex-none transition-all duration-200 hover:border-gray-300">
                        Register
                    </a>
                @endauth
            </div>
        </div>
    </div>
</body>
</html>
```

In this step, we add links to the “My Entries,” “Login,” and “Register” pages. The `href=""` placeholders are now replaced with real URLs using the `{{ url('/path') }}` helper. The `@auth` block shows a "My Entries" button for logged-in users, while the `@else` block shows "Log In" and "Register" buttons for guests.

---

## Step 6: Test the Complete Authentication Flow {#step-6-test-the-complete-authentication-flow}

Make sure the development server is running, then test these scenarios to verify everything works correctly:

**Scenario 1: New user registration**

1. Open `http://127.0.0.1:8000` and click "Register" to go to the registration page.
2. Fill in the form and click "Create Account." You should be logged in and redirected to the entries listing with a welcome message.
3. Create some entries, read them, edit, and delete. Everything should work.
4. Click "Logout" in the navigation bar. You should be redirected to the login page.

**Scenario 2: Returning user login**

1. Open the login page and enter the email and password you registered with. Click "Log In."
2. You should be redirected to the entries listing with a "Welcome back!" message.
3. The entries you created earlier should still be there.

**Scenario 3: Wrong credentials**

1. On the login page, enter a valid email but the wrong password. Click "Log In."
2. You should see the error message "The email or password you entered is incorrect." The email field should still be filled in, but the password field should be empty.

**Scenario 4: Guest tries to access entries directly**

1. Make sure you are logged out.
2. Try accessing `http://127.0.0.1:8000/entries` directly in the URL bar.
3. You should be automatically redirected to `/login`.

**Scenario 5: Logged-in user tries to access registration or login**

1. Make sure you are logged in.
2. Try accessing `http://127.0.0.1:8000/register` or `http://127.0.0.1:8000/login`.
3. You should be redirected away automatically because the `guest` middleware prevents authenticated users from accessing these pages.

**Scenario 6: Multi-user privacy**

1. Register a second user account with a different email.
2. Create entries with this new account.
3. Log out, then log in with the first account.
4. The entries listing should only show entries belonging to the first account. The second user's entries should not appear at all.

---

## How Login Works Behind the Scenes {#how-login-works-behind-the-scenes}

When a user fills in the login form and clicks "Log In," here is the complete sequence of events:

```
1. Browser sends POST /login
   { email: "budi@example.com", password: "secret123" }
         │
         ▼
2. Auth::attempt() finds the user by email
   then verifies the password with Hash::check()
         │
         ├── No match → redirect back with error message
         │
         └── Match → create session
                      Session ID stored on the server
                      Session ID sent to the browser as a cookie
         │
         ▼
3. Redirect to entries listing
   Every subsequent request carries the cookie,
   so Laravel knows which user is active
```

The session-based approach means the server remembers who you are across multiple requests. The browser stores a session cookie (a small piece of data containing the session ID), and sends it automatically with every request. Laravel reads that cookie, looks up the session on the server, and retrieves the authenticated user. This is why you stay logged in when navigating between pages and why closing the browser (which clears the cookie) requires you to log in again.

---

## The Complete Application Flow {#the-complete-application-flow}

With authentication fully implemented, here is the complete picture of how Catatku works:

```
Guest opens Catatku
    │
    ├── Home page → click "Register" → registration form → logged in automatically
    ├── Home page → click "Log In" → login form → logged in after verification
    └── Tries to access /entries → redirected to /login

Logged-in user
    │
    ├── View own entries listing (only their entries, not anyone else's)
    ├── Read entry detail
    ├── Write new entry
    ├── Edit existing entry
    ├── Delete entry
    └── Logout → redirected to login page

Security
    ├── Guest cannot access /entries → redirect to login
    ├── User A cannot see User B's entries in the listing
    ├── User A cannot read User B's entry → 403
    ├── User A cannot edit User B's entry → 403
    └── User A cannot delete User B's entry → 403
```

Every feature promised in Lesson 1 is now working. Users can register, log in, write entries, read them, update them, delete them, and log out. All with proper security and well-structured code.

---

## Conclusion {#conclusion}

The authentication system for Catatku is now complete. Here are the key takeaways:

- `Auth::attempt($credentials)` handles both user lookup and password verification in a single call. It returns `true` on success and `false` on failure.
- **Session regeneration** (`$request->session()->regenerate()`) after login prevents session fixation attacks by replacing the session ID so any previously captured ID becomes invalid.
- Login error messages should be **intentionally vague** ("The email or password you entered is incorrect") to prevent attackers from discovering which email addresses are registered in your system.
- `back()->withErrors([...])->onlyInput('email')` redirects to the form with error messages while preserving only the email value. Passwords are never sent back to the browser.
- The **three-step logout** is essential: `Auth::logout()` removes the user identity, `session()->invalidate()` destroys all session data, and `session()->regenerateToken()` creates a new CSRF token.
- Logout must use a **POST route** (not GET) to prevent cross-site logout attacks where a malicious site could log out your users without their knowledge.
- `->name('login')` on the login route is required because Laravel's `auth` middleware looks for a route with this name when redirecting unauthenticated users.
- `/entries` is now inside the `middleware('auth')` group, making the entries listing fully private. Guests are redirected to the login page.
- The `index()` method now uses **`auth()->user()->entries()->latest()->get()`** instead of `Entry::with('user')->latest()->get()`. In Lessons 6 through 9, we used `Entry::with('user')` because auth did not exist yet and calling `auth()->user()` would crash. Now that the route requires authentication, we can safely scope the query to the current user, ensuring each user only sees their own entries.
- The `guest` middleware prevents logged-in users from accessing registration and login pages, since they have no reason to see those forms.
- The `{{ url('/path') }}` helper generates full URLs in Blade templates, which we used to wire up the home page navigation buttons.

In the final lesson, we will not add any new features. Instead, we will step back and look at the entire journey: what we built, what patterns emerged repeatedly, and where you can go from here to continue growing as a Laravel developer.