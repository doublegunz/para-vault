## 1. Before You Begin

### Introduction

Over the last several lessons, we relied on a `/dev-login` shortcut that sets session values manually. This lesson replaces it with a real authentication system: registration, login, logout, and route protection. All built with PHP OOP.

### What You'll Build

A complete authentication system: registration with password hashing, login with credential verification, logout with session destruction, and route protection that redirects guests to the login page.

### What You'll Learn

- ✅ How `password_hash()` and `password_verify()` work
- ✅ How to build an `AuthController` for registration and login
- ✅ How to protect routes with a middleware-like pattern in the router
- ✅ How to scope entries to the authenticated user
- ✅ Why login error messages should be intentionally vague

### What You'll Need

- The complete CRUD from Lessons 10-11
- The development server running

---

## 2. Create the AuthController

This section creates the controller responsible for handling user registration, login forms, and session management.

### Step 1: Create the File

Right-click on `src/Controllers`, select **New File**, type `AuthController.php`.

### Step 2: Write the Code

Open `src/Controllers/AuthController.php` and type the following code:

```php
<?php

namespace App\Controllers;

use App\View;
use App\Helpers;
use App\Repositories\UserRepository;

class AuthController
{
    private UserRepository $userRepo;

    public function __construct()
    {
        $this->userRepo = new UserRepository();
    }

    public function showRegister(): void
    {
        View::render('auth/register');
    }

    public function register(): void
    {
        if (!Helpers::verifyCsrfToken($_POST['csrf_token'] ?? '')) {
            http_response_code(403);
            echo 'Invalid CSRF token.';
            return;
        }

        $name     = trim($_POST['name'] ?? '');
        $email    = trim($_POST['email'] ?? '');
        $password = $_POST['password'] ?? '';
        $errors   = [];

        if (empty($name)) { $errors['name'] = 'Name is required.'; }
        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors['email'] = 'A valid email is required.';
        }
        if (strlen($password) < 8) {
            $errors['password'] = 'Password must be at least 8 characters.';
        }

        if (empty($errors['email']) && $this->userRepo->findByEmail($email)) {
            $errors['email'] = 'This email is already registered.';
        }

        if (!empty($errors)) {
            Helpers::setOld(['name' => $name, 'email' => $email]);
            View::render('auth/register', ['errors' => $errors]);
            Helpers::clearOld();
            return;
        }

        $userId = $this->userRepo->create([
            'name'     => $name,
            'email'    => $email,
            'password' => password_hash($password, PASSWORD_DEFAULT),
        ]);

        $_SESSION['user_id']   = $userId;
        $_SESSION['user_name'] = $name;
        session_regenerate_id(true);

        View::setFlash('success', 'Account created! Welcome, ' . $name . '!');
        header('Location: /entries');
        exit;
    }

    public function showLogin(): void
    {
        View::render('auth/login');
    }

    public function login(): void
    {
        if (!Helpers::verifyCsrfToken($_POST['csrf_token'] ?? '')) {
            http_response_code(403);
            echo 'Invalid CSRF token.';
            return;
        }

        $email    = trim($_POST['email'] ?? '');
        $password = $_POST['password'] ?? '';

        $user = $this->userRepo->findByEmail($email);

        if ($user && password_verify($password, $user->getPassword())) {
            $_SESSION['user_id']   = $user->getId();
            $_SESSION['user_name'] = $user->getName();
            session_regenerate_id(true);

            View::setFlash('success', 'Welcome back, ' . $user->getName() . '!');
            header('Location: /entries');
            exit;
        }

        // Intentionally vague error message
        Helpers::setOld(['email' => $email]);
        View::render('auth/login', ['error' => 'The email or password you entered is incorrect.']);
        Helpers::clearOld();
    }

    public function logout(): void
    {
        $_SESSION = [];
        session_destroy();
        header('Location: /login');
        exit;
    }
}
```

The `register` method handles creating new accounts and explicitly encrypts the password with `password_hash()`. The `login` method verifies those credentials using `password_verify()`. On successful login or registration, the session variable `user_id` is set, and crucially, `session_regenerate_id(true)` is called to deter session fixation attacks.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 3. Add Route Protection to the Router

To protect routes globally without adding manual permission checks to every single controller method, this section implements a middleware-like pattern in the Router class.

### Step 1: Open the File

Open `src/Router.php`.

### Step 2: Update the Route Methods

Replace the `get()` and `post()` methods to accept an options array:

```php
    public function get(string $path, array $action, array $options = []): void
    {
        $this->routes['GET'][$path] = ['action' => $action, 'options' => $options];
    }

    public function post(string $path, array $action, array $options = []): void
    {
        $this->routes['POST'][$path] = ['action' => $action, 'options' => $options];
    }
```

### Step 3: Update the dispatch() Method

Update `dispatch()` to check auth before calling the action:

```php
    public function dispatch(string $method, string $uri): void
    {
        $path = parse_url($uri, PHP_URL_PATH);

        if (isset($this->routes[$method][$path])) {
            $route = $this->routes[$method][$path];
            if ($this->checkAuth($route['options'])) {
                $this->callAction($route['action']);
            }
            return;
        }

        foreach ($this->routes[$method] ?? [] as $routePath => $route) {
            $pattern = preg_replace('#\{(\w+)\}#', '(\d+)', $routePath);
            if (preg_match('#^' . $pattern . '$#', $path, $matches)) {
                array_shift($matches);
                if ($this->checkAuth($route['options'])) {
                    $this->callAction($route['action'], $matches);
                }
                return;
            }
        }

        http_response_code(404);
        \App\View::render('errors/404', [], 'layouts/main');
    }

    private function checkAuth(array $options): bool
    {
        if (!empty($options['auth']) && !isset($_SESSION['user_id'])) {
            header('Location: /login');
            exit;
        }
        if (!empty($options['guest']) && isset($_SESSION['user_id'])) {
            header('Location: /entries');
            exit;
        }
        return true;
    }
```

The `dispatch` method now checks an options array containing `auth` or `guest` keys before calling the target controller. `checkAuth` verifies the session status and redirects users automatically. This provides a centralized and robust way to secure the application.

### Step 4: Create the 404 Template

The updated `dispatch()` now renders a `errors/404` view instead of echoing plain HTML, so that file must exist. If you already created it in Lesson 9 Exercise 1, you can skip this step.

Create the folder `templates/errors/`, then create `templates/errors/404.php`:

```php
<?php $title = '404 - Not Found'; ?>
<h1>404 - Page Not Found</h1>
<p>The page you are looking for does not exist.</p>
<p><a href="/entries">Go to entries</a></p>
```

This template only provides a title and the page content. The layout wraps it, so it works with `layouts/main` (used here) just as well as `layouts/blank`.

### Step 5: Save the Files

Press **Ctrl+S**.

---

## 4. Update the Routes

This section applies the new router protection flags to the existing routes, defining exactly who can access what.

### Step 1: Open the File

Open `public/index.php`.

### Step 2: Replace the Routes

Replace all route definitions with:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

session_start();

use App\Router;
use App\Controllers\HomeController;
use App\Controllers\EntryController;
use App\Controllers\AuthController;

$router = new Router();

// Public routes
$router->get('/', [HomeController::class, 'index']);

// Auth routes (guest only)
$router->get('/register', [AuthController::class, 'showRegister'], ['guest' => true]);
$router->post('/register', [AuthController::class, 'register'], ['guest' => true]);
$router->get('/login', [AuthController::class, 'showLogin'], ['guest' => true]);
$router->post('/login', [AuthController::class, 'login'], ['guest' => true]);
$router->get('/logout', [AuthController::class, 'logout'], ['auth' => true]);

// Protected routes (auth required)
$router->get('/entries', [EntryController::class, 'index'], ['auth' => true]);
$router->get('/entries/create', [EntryController::class, 'create'], ['auth' => true]);
$router->post('/entries', [EntryController::class, 'store'], ['auth' => true]);
$router->get('/entries/{id}', [EntryController::class, 'show'], ['auth' => true]);
$router->get('/entries/{id}/edit', [EntryController::class, 'edit'], ['auth' => true]);
$router->post('/entries/{id}/update', [EntryController::class, 'update'], ['auth' => true]);
$router->post('/entries/{id}/delete', [EntryController::class, 'destroy'], ['auth' => true]);

$router->dispatch($_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI']);
```

Notice that registration and login have `['guest' => true]`, ensuring logged-in users cannot access them. Similarly, all entry management routes have `['auth' => true]`, effectively locking out unauthenticated visitors.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 5. Update EntryController to Scope by User

Now that users are authenticated, the application should only display entries that belong to the logged-in user rather than all entries in the entire system.

### Step 1: Open the File

Open `src/Controllers/EntryController.php`.

### Step 2: Update the index() Method

Change `findAll()` to `findByUserId()`:

```php
    public function index(): void
    {
        $entries = $this->entryRepo->findByUserId((int) $_SESSION['user_id']);
        View::render('entry/index', ['entries' => $entries]);
    }
```

Changing `findAll()` to `findByUserId()` ensures data privacy so users manage their own journal exclusively.

### Step 3: Save the File

Press **Ctrl+S**. Now each user only sees their own entries.

---

## 6. Create the Auth Templates

This section creates the HTML forms for the registration and login pages.

### Step 1: Create the Folder

In `templates/`, create a subfolder called `auth`.

### Step 2: Create register.php

Create `templates/auth/register.php`:

```php
<?php $title = 'Register - Catatku'; ?>

<h2>Create an Account</h2>

<form method="POST" action="/register" style="max-width:400px;">
    <?= \App\Helpers::csrfField() ?>

    <div style="margin-bottom:12px;">
        <label><strong>Name:</strong></label><br>
        <input type="text" name="name" value="<?= \App\Helpers::old('name') ?>"
               style="width:100%;padding:8px;border:1px solid <?= isset($errors['name']) ? 'red' : '#ccc' ?>;border-radius:4px;">
        <?php if (isset($errors['name'])): ?>
            <p style="color:red;font-size:0.85em;"><?= htmlspecialchars($errors['name']) ?></p>
        <?php endif; ?>
    </div>

    <div style="margin-bottom:12px;">
        <label><strong>Email:</strong></label><br>
        <input type="email" name="email" value="<?= \App\Helpers::old('email') ?>"
               style="width:100%;padding:8px;border:1px solid <?= isset($errors['email']) ? 'red' : '#ccc' ?>;border-radius:4px;">
        <?php if (isset($errors['email'])): ?>
            <p style="color:red;font-size:0.85em;"><?= htmlspecialchars($errors['email']) ?></p>
        <?php endif; ?>
    </div>

    <div style="margin-bottom:12px;">
        <label><strong>Password:</strong></label><br>
        <input type="password" name="password"
               style="width:100%;padding:8px;border:1px solid <?= isset($errors['password']) ? 'red' : '#ccc' ?>;border-radius:4px;">
        <?php if (isset($errors['password'])): ?>
            <p style="color:red;font-size:0.85em;"><?= htmlspecialchars($errors['password']) ?></p>
        <?php endif; ?>
    </div>

    <button type="submit" class="btn btn-primary" style="width:100%;">Register</button>
</form>

<p style="margin-top:15px;">Already have an account? <a href="/login">Log in here</a></p>
```

The registration template uses the same pattern as the other forms: displaying old input data conditionally, catching validation errors beside the fields, and providing a CSRF token to secure the form.

Save the file.

### Step 3: Create login.php

Create `templates/auth/login.php`:

```php
<?php $title = 'Login - Catatku'; ?>

<h2>Log in to Catatku</h2>

<?php if (isset($error)): ?>
    <p style="color:red;border:1px solid red;padding:10px;border-radius:4px;max-width:400px;">
        <?= htmlspecialchars($error) ?>
    </p>
<?php endif; ?>

<form method="POST" action="/login" style="max-width:400px;">
    <?= \App\Helpers::csrfField() ?>

    <div style="margin-bottom:12px;">
        <label><strong>Email:</strong></label><br>
        <input type="email" name="email" value="<?= \App\Helpers::old('email') ?>"
               style="width:100%;padding:8px;border:1px solid #ccc;border-radius:4px;">
    </div>

    <div style="margin-bottom:12px;">
        <label><strong>Password:</strong></label><br>
        <input type="password" name="password"
               style="width:100%;padding:8px;border:1px solid #ccc;border-radius:4px;">
    </div>

    <button type="submit" class="btn btn-primary" style="width:100%;">Log In</button>
</form>

<p style="margin-top:15px;">Don't have an account? <a href="/register">Register here</a></p>
```

The login form captures credentials. Unlike the registration form which highlights specific field errors (e.g. "Email is too short"), the login form exclusively uses a single, intentionally vague overall error message to prevent attackers from discovering which emails are registered.

Save the file.

---

## 7. Test the Complete Flow

It's time to verify the authentication subsystem works flawlessly exactly as designed.

1. Stop the server and restart: `php -S localhost:8080 -t public`
2. Visit `http://localhost:8080/entries` - should redirect to `/login`
3. Click "Register here" and create a new account
4. After registration, you should be auto-logged-in and see your entries
5. Click "Logout" in the navigation
6. Try logging in with wrong credentials - should see vague error message
7. Log in with correct credentials - should see entries

---

## 8. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
// Error 1: Storing plain-text password
$userRepo->create([
    'password' => $_POST['password'],  // NEVER!
]);

// Error 2: Specific login error message
if (!$user) {
    $error = 'Email not found.';    // Tells attacker which emails exist
} elseif (!password_verify($password, $user->getPassword())) {
    $error = 'Wrong password.';     // Confirms email exists
}

// Error 3: No session_regenerate_id after login
$_SESSION['user_id'] = $user->getId();
// Session fixation attack possible!
```

**Error 1: Plain-text password.** Always use `password_hash($password, PASSWORD_DEFAULT)` before storing. If the database is breached, hashed passwords cannot be reversed.

**Error 2: Specific error messages.** Separate messages tell attackers which emails are registered. Always use one vague message: "The email or password you entered is incorrect."

**Error 3: No session regeneration.** Without `session_regenerate_id(true)` after login, the old session ID (which might have been captured by an attacker) remains valid. Always regenerate after login.

---

## 9. Exercises

**Exercise 1:** Add a "Change Password" feature. Create a route `GET /profile/password` and `POST /profile/password` that shows a form with "Current Password", "New Password", and "Confirm New Password" fields. Verify the current password before updating.

**Exercise 2:** Remove the `dev-login` route from `public/index.php` now that real authentication is in place.

**Exercise 3:** Add a user count display on the home page: "X users have joined Catatku." Create a `countAll()` method on `UserRepository` and display the result on the home template.

---

## 10. Solutions

**Solution for Exercise 1:**

Add routes to `public/index.php`:

```php
$router->get('/profile/password', [AuthController::class, 'showChangePassword'], ['auth' => true]);
$router->post('/profile/password', [AuthController::class, 'changePassword'], ['auth' => true]);
```

Add to `AuthController`:

```php
    public function showChangePassword(): void
    {
        View::render('auth/change-password');
    }

    public function changePassword(): void
    {
        if (!Helpers::verifyCsrfToken($_POST['csrf_token'] ?? '')) { http_response_code(403); return; }

        $current = $_POST['current_password'] ?? '';
        $new     = $_POST['new_password'] ?? '';
        $confirm = $_POST['confirm_password'] ?? '';
        $errors  = [];

        $user = $this->userRepo->findById((int) $_SESSION['user_id']);
        if (!password_verify($current, $user->getPassword())) {
            $errors['current'] = 'Current password is incorrect.';
        }
        if (strlen($new) < 8) { $errors['new'] = 'New password must be at least 8 characters.'; }
        if ($new !== $confirm) { $errors['confirm'] = 'Passwords do not match.'; }

        if (!empty($errors)) {
            View::render('auth/change-password', ['errors' => $errors]);
            return;
        }

        // Add an updatePassword() method to UserRepository
        View::setFlash('success', 'Password changed successfully!');
        header('Location: /entries');
        exit;
    }
```

Updating a user's password always requires verifying their current password to ensure the session wasn't hijacked and the user is deliberately making the change. The new password is then hashed identically to registration.

**Solution for Exercise 2:**

Remove the `$router->get('/dev-login', ...)` line and the `devLogin()` method from `HomeController`.

**Solution for Exercise 3:**

Add to `UserRepository`:

```php
    public function countAll(): int
    {
        return (int) $this->pdo->query("SELECT COUNT(*) as total FROM users")->fetch()->total;
    }
```

A simple raw query neatly fetches the scalar count value directly via the PDO object.

Update `HomeController`:

```php
    public function index(): void
    {
        $userRepo = new \App\Repositories\UserRepository();
        View::render('home', ['userCount' => $userRepo->countAll()]);
    }
```

In `templates/home.php` add: `<p><?= $userCount ?> users have joined Catatku.</p>`

---

---

## Next Up - Lesson 13: Inheritance and Interfaces

In the next lesson you will:

1. Refactor repetitive code using Abstract Classes and Inheritance
2. Build Interfaces to define strict contracts for repositories
3. Build a BaseRepository to eliminate repetitive CRUD SQL across your application