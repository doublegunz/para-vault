Over the last several lessons, we have built a lot on top of the `/dev-login` shortcut. This lesson replaces it with the real thing, starting with registration.

## Overview {#overview}

### What You'll Build

By the end of this lesson, users can register with a real account, get logged in automatically, and the `/dev-login` route can be deleted permanently.

### What You'll Learn

- How to create an `AuthController` for handling registration
- How to validate registration input with rules like `is_unique` and `matches`
- Why passwords must be hashed with `password_hash()` before storage
- How CodeIgniter's Session library creates authenticated sessions
- How to create a `GuestFilter` to restrict pages to unauthenticated visitors

### What You'll Need

- The `catatku` project with all CRUD features working
- The `/dev-login` route still in place

---

## Step 1: Create the GuestFilter {#step-1-create-the-guestfilter}

Create `app/Filters/GuestFilter.php`:

```php
<?php

namespace App\Filters;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Filters\FilterInterface;

class GuestFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        if (session()->get('user_id')) {
            return redirect()->to('/entries');
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        //
    }
}
```

Register it in `app/Config/Filters.php`:

```php
public array $aliases = [
    // ... existing
    'auth'  => \App\Filters\AuthFilter::class,
    'guest' => \App\Filters\GuestFilter::class,
];
```

The `GuestFilter` is the opposite of `AuthFilter`: it only allows unauthenticated visitors.

---

## Step 2: Create the AuthController {#step-2-create-the-authcontroller}

```bash
php spark make:controller AuthController
```

Update `app/Controllers/AuthController.php`:

```php
<?php

namespace App\Controllers;

use App\Models\UserModel;

class AuthController extends BaseController
{
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
}
```

### Validation Rules {#validation-rules}

`valid_email` checks for a valid email format. `is_unique[users.email]` checks the database to ensure the email is not already taken. `min_length[8]` requires at least 8 characters. `matches[password]` ensures `password_confirmation` matches `password`.

### Password Hashing {#password-hashing}

`password_hash($password, PASSWORD_DEFAULT)` is PHP's built-in function that creates a bcrypt hash. Unlike storing plain text, a hash cannot be reversed. `PASSWORD_DEFAULT` automatically uses the strongest available algorithm.

### Session-Based Login {#session-based-login}

`session()->set([...])` stores the user's ID and name in the session. From this point on, `session()->get('user_id')` returns their ID on every subsequent request.

---

## Step 3: Add the Routes {#step-3-add-the-routes}

Next, we’ll define a route for registration using the guest filter we created in the previous step. We’ll also remove the `dev-login` route. Open and edit `app/Config/Routes.php` .

```php
$routes->get('/', 'Home::index');

$routes->group('', ['filter' => 'guest'], static function ($routes) {
    $routes->get('/register', 'AuthController::showRegister');
    $routes->post('/register', 'AuthController::register');
});

$routes->get('/entries', 'EntryController::index');

$routes->group('', ['filter' => 'auth'], static function ($routes) {
    $routes->get('/entries/create', 'EntryController::create');
    $routes->post('/entries', 'EntryController::store');
    $routes->get('/entries/(:num)', 'EntryController::show/$1');
    $routes->get('/entries/(:num)/edit', 'EntryController::edit/$1');
    $routes->post('/entries/(:num)/update', 'EntryController::update/$1');
    $routes->post('/entries/(:num)/delete', 'EntryController::destroy/$1');
});
```

---

## Step 4: Create the Registration View {#step-4-create-the-registration-view}

Create `app/Views/auth/register.php`:

```php
<?= $this->extend('layouts/main') ?>

<?= $this->section('title') ?>Register — Catatku<?= $this->endSection() ?>

<?= $this->section('content') ?>

    <?php $errors = session()->getFlashdata('errors') ?? []; ?>

    <div class="max-w-sm mx-auto">
        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Join Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">Your personal journal space</p>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <form method="POST" action="/register">
                <?= csrf_field() ?>

                <div class="mb-4">
                    <label for="name" class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                    <input type="text" id="name" name="name" value="<?= old('name') ?>" placeholder="Your full name"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 <?= isset($errors['name']) ? 'border-red-400 bg-red-50' : 'border-gray-300' ?>" autofocus>
                    <?php if (isset($errors['name'])): ?>
                        <p class="text-xs text-red-500 mt-1"><?= esc($errors['name']) ?></p>
                    <?php endif; ?>
                </div>

                <div class="mb-4">
                    <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                    <input type="email" id="email" name="email" value="<?= old('email') ?>" placeholder="name@email.com"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 <?= isset($errors['email']) ? 'border-red-400 bg-red-50' : 'border-gray-300' ?>">
                    <?php if (isset($errors['email'])): ?>
                        <p class="text-xs text-red-500 mt-1"><?= esc($errors['email']) ?></p>
                    <?php endif; ?>
                </div>

                <div class="mb-4">
                    <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                    <input type="password" id="password" name="password" placeholder="At least 8 characters"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 <?= isset($errors['password']) ? 'border-red-400 bg-red-50' : 'border-gray-300' ?>">
                    <?php if (isset($errors['password'])): ?>
                        <p class="text-xs text-red-500 mt-1"><?= esc($errors['password']) ?></p>
                    <?php endif; ?>
                </div>

                <div class="mb-6">
                    <label for="password_confirmation" class="block text-sm font-medium text-gray-700 mb-1">Confirm Password</label>
                    <input type="password" id="password_confirmation" name="password_confirmation" placeholder="Re-enter your password"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900">
                </div>

                <button type="submit" class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium hover:bg-gray-700 transition-colors">
                    Create Account
                </button>
            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Already have an account? <a href="/login" class="text-gray-900 font-medium hover:underline">Log in here</a>
        </p>
    </div>

<?= $this->endSection() ?>
```

---

## Step 5: Test Registration {#step-5-test-registration}
If you haven't logged out of your account via the `dev-login` route from the previous lesson, you can test this registration feature using a different browser. 

In a different browser, open the URL `http://localhost:8080/register`.
![view register page](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/16-view-register-page.webp)

Next, we can test the form validation by leaving the field blank and then clicking the “Create Account” button.
![test form validation](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/17-test-validation.webp)

We can also test the form validation by entering a password that is shorter than required.
![test form validation 2](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/18-test-validation.webp)

Register with valid data. You should be redirected to the entries listing with a welcome message.
![user registered](https://cdn.jsdelivr.net/gh/gungunpriatna/learn-codeigniter-4-course-assets@main/19-user-registered.webp)

---

## Conclusion {#conclusion}

- The `AuthController` handles registration separately from entry management.
- `is_unique[users.email]` prevents duplicate email addresses. `matches[password]` ensures password confirmation matches.
- `password_hash()` is PHP's built-in bcrypt hashing function. **Never store plain text passwords.**
- `session()->set([...])` stores user data in the session for authentication.
- The `GuestFilter` prevents logged-in users from accessing registration/login pages.
- Password fields should never use `old()` to preserve values after failures.

In the next lesson, we will complete authentication with login, logout, and the final route configuration.