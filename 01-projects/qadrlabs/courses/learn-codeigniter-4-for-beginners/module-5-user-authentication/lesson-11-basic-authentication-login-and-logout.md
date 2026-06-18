The previous lesson completed registration. Users can create an account and get logged in automatically. But there is no way to log back in after closing the browser, and no way to log out safely. This lesson builds both.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the authentication system is complete. Guests are redirected to login, logged-in users cannot access auth pages, entries are fully private, and the controller scopes entries to the current user.

### What You'll Learn

- How to verify credentials with `password_verify()`
- Why login error messages should be intentionally vague
- How to implement a secure logout that destroys the session
- How to update the controller to show only the current user's entries
- How to wire up the home page with real navigation links

### What You'll Need

- The `AuthController` with registration from Lesson 10
- At least one registered user account

---

## Step 1: Add Login and Logout Methods {#step-1-add-login-and-logout-methods}

Update `app/Controllers/AuthController.php`:

```php
<?php

namespace App\Controllers;

use App\Models\UserModel;

class AuthController extends BaseController
{
    // --- Registration (from Lesson 10) ---

    public function showRegister()
    {
        return view('auth/register');
    }

    public function register()
    {
        $rules = [
            'name'     => 'required|max_length[255]',
            'email'    => 'required|valid_email|is_unique[users.email]',
            'password' => 'required|min_length[8]',
            'password_confirmation' => 'required|matches[password]',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $userModel = model(UserModel::class);
        $userModel->insert([
            'name'     => $this->request->getPost('name'),
            'email'    => $this->request->getPost('email'),
            'password' => password_hash($this->request->getPost('password'), PASSWORD_DEFAULT),
        ]);

        $userId = $userModel->getInsertID();
        $user = $userModel->find($userId);

        session()->set([
            'user_id'   => $user->id,
            'user_name' => $user->name,
        ]);

        return redirect()->to('/entries')->with('success', 'Welcome to Catatku, ' . $user->name . '!');
    }

    // --- Login ---

    public function showLogin()
    {
        return view('auth/login');
    }

    public function login()
    {
        $rules = [
            'email'    => 'required|valid_email',
            'password' => 'required',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $userModel = model(UserModel::class);
        $user = $userModel->where('email', $this->request->getPost('email'))->first();

        if (!$user || !password_verify($this->request->getPost('password'), $user->password)) {
            return redirect()->back()
                ->withInput()
                ->with('errors', ['email' => 'The email or password you entered is incorrect.']);
        }

        session()->regenerate();
        session()->set([
            'user_id'   => $user->id,
            'user_name' => $user->name,
        ]);

        return redirect()->to('/entries')->with('success', 'Welcome back!');
    }

    // --- Logout ---

    public function logout()
    {
        session()->destroy();

        return redirect()->to('/login');
    }
}
```

### The `login()` Method {#the-login-method}

`$userModel->where('email', ...)->first()` finds a user by email. `password_verify()` is PHP's built-in function that checks a plain text password against a bcrypt hash.

The error message "The email or password you entered is incorrect" is deliberately vague. It does not reveal whether the email exists in the system, preventing attackers from mapping registered emails.

`session()->regenerate()` creates a new session ID after login, preventing session fixation attacks. `session()->set([...])` stores the authenticated user's data.

### The `logout()` Method {#the-logout-method}

`session()->destroy()` completely destroys the session, removing all user data and the session cookie. This is a single-step approach that is clean and effective.

---

## Step 2: Update the Routes {#step-2-update-the-routes}

The final route configuration:

```php
<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */
$routes->get('/', 'Home::index');

// Routes for guests only
$routes->group('', ['filter' => 'guest'], static function ($routes) {
    $routes->get('/register', 'AuthController::showRegister');
    $routes->post('/register', 'AuthController::register');
    $routes->get('/login', 'AuthController::showLogin');
    $routes->post('/login', 'AuthController::login');
});

// All routes that require login
$routes->group('', ['filter' => 'auth'], static function ($routes) {
    $routes->post('/logout', 'AuthController::logout');

    $routes->get('/entries', 'EntryController::index');
    $routes->get('/entries/create', 'EntryController::create');
    $routes->post('/entries', 'EntryController::store');
    $routes->get('/entries/(:num)', 'EntryController::show/$1');
    $routes->get('/entries/(:num)/edit', 'EntryController::edit/$1');
    $routes->post('/entries/(:num)/update', 'EntryController::update/$1');
    $routes->post('/entries/(:num)/delete', 'EntryController::destroy/$1');
});
```

**`/entries` has moved inside the auth group.** Entries are now fully private. The `AuthFilter` redirects guests to `/login`.

**Logout uses POST** to prevent cross-site logout attacks.

---

## Step 3: Update the EntryController {#step-3-update-the-entrycontroller}

Now that `/entries` requires authentication, update the `index()` method to scope entries to the current user:

```php
public function index()
{
    $entryModel = model(EntryModel::class);
    $entries = $entryModel
        ->where('user_id', session()->get('user_id'))
        ->orderBy('created_at', 'DESC')
        ->findAll();

    return view('entries/index', ['entries' => $entries]);
}
```

Previously, `index()` fetched all entries from all users. Now `where('user_id', session()->get('user_id'))` scopes the query to only the authenticated user's entries. This is safe because the `auth` filter guarantees `session()->get('user_id')` always has a value.

---

## Step 4: Create the Login View {#step-4-create-the-login-view}

Create `app/Views/auth/login.php`:

```php
<?= $this->extend('layouts/main') ?>

<?= $this->section('title') ?>Log In — Catatku<?= $this->endSection() ?>

<?= $this->section('content') ?>

    <?php $errors = session()->getFlashdata('errors') ?? []; ?>

    <div class="max-w-sm mx-auto">
        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Log in to Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">Continue writing your journal</p>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <form method="POST" action="/login">
                <?= csrf_field() ?>

                <div class="mb-4">
                    <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                    <input type="email" id="email" name="email" value="<?= old('email') ?>" placeholder="name@email.com"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 <?= isset($errors['email']) ? 'border-red-400 bg-red-50' : 'border-gray-300' ?>" autofocus>
                    <?php if (isset($errors['email'])): ?>
                        <p class="text-xs text-red-500 mt-1"><?= esc($errors['email']) ?></p>
                    <?php endif; ?>
                </div>

                <div class="mb-6">
                    <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                    <input type="password" id="password" name="password" placeholder="Your password"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900">
                </div>

                <button type="submit" class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium hover:bg-gray-700 transition-colors">
                    Log In
                </button>
            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Don't have an account? <a href="/register" class="text-gray-900 font-medium hover:underline">Register now</a>
        </p>
    </div>

<?= $this->endSection() ?>
```

---

## Step 5: Update the Home Page {#step-5-update-the-home-page}

Update `app/Views/home.php` with real navigation links:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Catatku - Simple Journal App</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50 text-gray-900 font-sans antialiased selection:bg-blue-100">
    <div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-blue-50 to-white">
        <div class="max-w-2xl w-full text-center px-6 py-12">
            <h1 class="text-5xl font-extrabold tracking-tight text-blue-600 mb-6 drop-shadow-sm">Catatku</h1>
            <p class="text-xl text-gray-600 mb-10 leading-relaxed">
                A simple journal app to accompany your day. Start capturing what matters, easily and quickly.
            </p>
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
                <?php if (session()->get('user_id')): ?>
                    <a href="/entries" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow transition-all duration-200 hover:scale-105">
                        My Entries
                    </a>
                <?php else: ?>
                    <a href="/login" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow transition-all duration-200 hover:scale-105">
                        Log In
                    </a>
                    <a href="/register" class="inline-flex items-center justify-center px-8 py-3.5 border border-gray-200 text-lg font-medium rounded-xl text-blue-700 bg-white hover:bg-gray-50 shadow-sm transition-all duration-200 hover:border-gray-300">
                        Register
                    </a>
                <?php endif; ?>
            </div>
        </div>
    </div>
</body>
</html>
```

---

## Step 6: Test the Complete Flow {#step-6-test-the-complete-flow}

Test all scenarios: registration, login, wrong credentials, guest redirect, multi-user privacy (register two users, verify they only see their own entries), and logout.

---

## Conclusion {#conclusion}

- `password_verify()` checks a plain text password against a stored bcrypt hash.
- Login error messages should be **intentionally vague** to prevent email enumeration.
- `session()->regenerate()` prevents session fixation attacks after login.
- `session()->destroy()` completely removes the session on logout.
- `/entries` is now inside the `auth` filter group, making entries fully private.
- The `index()` method uses `where('user_id', session()->get('user_id'))` to scope entries to the current user.
- The `guest` filter prevents authenticated users from accessing registration and login pages.
- Logout uses POST to prevent cross-site logout attacks.

In the final lesson, we will review the entire journey and plan what to learn next.