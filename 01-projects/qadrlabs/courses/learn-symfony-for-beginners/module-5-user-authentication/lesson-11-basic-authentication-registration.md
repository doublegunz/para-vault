## 1. Before You Begin

The previous lesson completed the login system. Budi can log in, his entries are private, and he can log out safely. But Budi was created by the fixtures, and nobody else can join Catatku. This lesson adds the missing piece: a registration form that lets anyone create an account.

Symfony's Security component handles authentication at the framework level. Instead of managing sessions and password verification by hand, you configure a set of rules in `security.yaml` and implement a specific interface on your User entity. Symfony does the rest. Registration builds on the same pieces: the password hasher you met in the fixtures, and the `form_login` authenticator you configured in Lesson 10.

This lesson focuses on registration: creating a new account, hashing the password, and logging the user in automatically after registration so they land directly in the application.

### What You'll Build

By the end of this lesson, new users can register with a name, email, and password. After successful registration they are logged in automatically and redirected to their own, still empty, entries listing. The login page, the navigation bar, and the home page all link to the registration form.

### What You'll Learn

- ✅ How to create a registration controller with Symfony's PasswordHasher service
- ✅ How to validate registration input including email format and password confirmation
- ✅ How to check for duplicate email addresses before saving
- ✅ How to programmatically log a user in after registration using the `Security` helper

### What You'll Need

- The `AuthController`, login template, and `security.yaml` from Lesson 10
- The seed user from Lesson 6 (`budi@example.com`) to test the duplicate email check

---

## 2. Adding Registration to the AuthController

Registration, login, and logout all belong in the same controller. This keeps authentication logic separate from application logic.

### Step 1: Add the register() Method

Open `src/Controller/AuthController.php`, add the new imports, and add a `register()` method below `logout()`. The complete file now looks like this:

```php
<?php

namespace App\Controller;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Authentication\AuthenticationUtils;

class AuthController extends AbstractController
{
    #[Route('/login', name: 'app_login')]
    public function login(AuthenticationUtils $authUtils): Response
    {
        if ($this->getUser()) {
            return $this->redirectToRoute('entry_index');
        }

        $error = $authUtils->getLastAuthenticationError();
        $lastUsername = $authUtils->getLastUsername();

        return $this->render('auth/login.html.twig', [
            'last_username' => $lastUsername,
            'error'         => $error,
        ]);
    }

    #[Route('/logout', name: 'app_logout')]
    public function logout(): void
    {
        // This method body is intentionally empty.
        // Symfony's security firewall intercepts requests to this route
        // and handles session destruction before this code ever runs.
    }

    #[Route('/register', name: 'app_register')]
    public function register(
        Request $request,
        UserPasswordHasherInterface $passwordHasher,
        EntityManagerInterface $entityManager,
        Security $security,
    ): Response {
        if ($this->getUser()) {
            return $this->redirectToRoute('entry_index');
        }

        if ($request->isMethod('POST')) {
            if (!$this->isCsrfTokenValid('register', $request->request->get('_csrf_token'))) {
                throw $this->createAccessDeniedException('Invalid CSRF token.');
            }

            $name     = trim($request->request->get('name', ''));
            $email    = trim($request->request->get('email', ''));
            $password = $request->request->get('password', '');
            $passwordConfirmation = $request->request->get('password_confirmation', '');

            $errors = [];
            if (empty($name)) {
                $errors['name'] = 'The name field is required.';
            }
            if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                $errors['email'] = 'Please enter a valid email address.';
            }
            if (empty($password) || strlen($password) < 8) {
                $errors['password'] = 'The password must be at least 8 characters.';
            }
            if ($password !== $passwordConfirmation) {
                $errors['password_confirmation'] = 'The password confirmation does not match.';
            }

            if (empty($errors['email'])) {
                $existingUser = $entityManager->getRepository(User::class)->findOneBy(['email' => $email]);
                if ($existingUser) {
                    $errors['email'] = 'This email address is already taken.';
                }
            }

            if (!empty($errors)) {
                return $this->render('auth/register.html.twig', [
                    'errors' => $errors,
                    'old'    => ['name' => $name, 'email' => $email],
                ]);
            }

            $user = new User();
            $user->setName($name);
            $user->setEmail($email);
            $user->setPassword($passwordHasher->hashPassword($user, $password));

            $entityManager->persist($user);
            $entityManager->flush();

            $security->login($user, 'form_login', 'main');

            $this->addFlash('success', 'Welcome to Catatku, ' . $user->getName() . '!');

            return $this->redirectToRoute('entry_index');
        }

        return $this->render('auth/register.html.twig');
    }
}
```

`if ($this->getUser())` at the very top of `register()` checks whether the visitor is already logged in. If so, they are redirected to the entries listing immediately. This is the same guest-only guard that `login()` uses, and it prevents logged-in users from seeing the registration form.

`UserPasswordHasherInterface $passwordHasher` is injected by Symfony. It uses the algorithm configured in `security.yaml` (the `'auto'` setting currently selects bcrypt). Calling `$passwordHasher->hashPassword($user, $password)` produces a hashed string that can safely be stored in the database. You can verify it later with the same service, but you can never reverse it to get the original password.

The uniqueness check runs only when `$errors['email']` is not already set. This prevents running a database query when the email format is obviously invalid. `$entityManager->getRepository(User::class)->findOneBy(['email' => $email])` queries the `user` table for a row with that email. If one exists, the email is already taken.

`$security->login($user, 'form_login', 'main')` logs the user in immediately after their account is created, so they do not need to fill in a separate login form after registering. `Security` is Symfony's security helper service. The second argument names the authenticator to use, `form_login` from Lesson 10, and the third names the firewall, `main`. Symfony creates the security token, stores it in the session, and treats every following request as coming from this user.

Password fields (`password` and `password_confirmation`) are intentionally not included in the `old` array passed back on validation failure. Repopulating password fields after a failed submission is a security anti-pattern because it could expose sensitive input in the browser's form history.

### Step 2: Make the Registration Page Public

`access_control` in Lesson 10 only listed `/login`, `/entries`, and the home page. Add a rule for `/register` so the intent is explicit. The complete `config/packages/security.yaml` now looks like this:

```yaml
security:
    password_hashers:
        Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface: 'auto'

    providers:
        app_user_provider:
            entity:
                class: App\Entity\User
                property: email

    firewalls:
        dev:
            pattern: ^/(_(profiler|wdt)|css|images|js)/
            security: false
        main:
            lazy: true
            provider: app_user_provider
            form_login:
                login_path: app_login
                check_path: app_login
                default_target_path: entry_index
                enable_csrf: true
            logout:
                path: app_logout
                target: app_login

    access_control:
        - { path: ^/register, roles: PUBLIC_ACCESS }
        - { path: ^/login, roles: PUBLIC_ACCESS }
        - { path: ^/entries, roles: ROLE_USER }
        - { path: ^/$, roles: PUBLIC_ACCESS }
```

The only new line is `- { path: ^/register, roles: PUBLIC_ACCESS }`. A path that matches no rule is already public, so the page would work without it, but listing every public page makes the security rules easy to review at a glance.

---

## 3. Creating the Registration Template

The registration form needs fields for name, email, password, and password confirmation. It extends the base layout and follows the same error display pattern established in Lesson 8.

### Step 1: Create register.html.twig

Create the file `templates/auth/register.html.twig` next to `login.html.twig`:

```html
{% extends 'base.html.twig' %}

{% block title %}Register - Catatku{% endblock %}

{% block body %}
    <div class="max-w-sm mx-auto">
        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Join Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">Your personal journal space</p>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <form method="POST" action="{{ path('app_register') }}">
                <input type="hidden" name="_csrf_token" value="{{ csrf_token('register') }}">

                <div class="mb-4">
                    <label for="name" class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                    <input type="text" id="name" name="name" value="{{ old.name|default('') }}" placeholder="Your full name"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 {{ errors.name is defined ? 'border-red-400 bg-red-50' : 'border-gray-300' }}" autofocus>
                    {% if errors.name is defined %}
                        <p class="text-xs text-red-500 mt-1">{{ errors.name }}</p>
                    {% endif %}
                </div>

                <div class="mb-4">
                    <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                    <input type="email" id="email" name="email" value="{{ old.email|default('') }}" placeholder="name@email.com"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 {{ errors.email is defined ? 'border-red-400 bg-red-50' : 'border-gray-300' }}">
                    {% if errors.email is defined %}
                        <p class="text-xs text-red-500 mt-1">{{ errors.email }}</p>
                    {% endif %}
                </div>

                <div class="mb-4">
                    <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                    <input type="password" id="password" name="password" placeholder="At least 8 characters"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 {{ errors.password is defined ? 'border-red-400 bg-red-50' : 'border-gray-300' }}">
                    {% if errors.password is defined %}
                        <p class="text-xs text-red-500 mt-1">{{ errors.password }}</p>
                    {% endif %}
                </div>

                <div class="mb-6">
                    <label for="password_confirmation" class="block text-sm font-medium text-gray-700 mb-1">Confirm Password</label>
                    <input type="password" id="password_confirmation" name="password_confirmation" placeholder="Re-enter your password"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900">
                    {% if errors.password_confirmation is defined %}
                        <p class="text-xs text-red-500 mt-1">{{ errors.password_confirmation }}</p>
                    {% endif %}
                </div>

                <button type="submit" class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium hover:bg-gray-700 transition-colors">
                    Create Account
                </button>
            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Already have an account? <a href="{{ path('app_login') }}" class="text-gray-900 font-medium hover:underline">Log in here</a>
        </p>
    </div>
{% endblock %}
```

The password and password confirmation fields do not have `value="{{ old.password|default('') }}"`. This is intentional: password fields must never be repopulated after a form submission. A browser's autocomplete may still prefill them, but the application must not do so.

The "Log in here" link at the bottom points to `app_login`, which has existed since Lesson 10, so users who already have an account can switch to the login form.

---

## 4. Linking to the Registration Page

A registration page is only useful if people can find it. Three templates get a link to `app_register`: the login page, the navigation bar, and the home page.

### Step 1: Update login.html.twig

Replace the contents of `templates/auth/login.html.twig`. The only change is the "Don't have an account?" paragraph below the form:

```html
{% extends 'base.html.twig' %}

{% block title %}Log In - Catatku{% endblock %}

{% block body %}
    <div class="max-w-sm mx-auto">
        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Log in to Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">Continue writing your journal</p>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <form method="POST" action="{{ path('app_login') }}">
                <input type="hidden" name="_csrf_token" value="{{ csrf_token('authenticate') }}">

                {% if error %}
                    <div class="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg">
                        The email or password you entered is incorrect.
                    </div>
                {% endif %}

                <div class="mb-4">
                    <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                    <input type="email" id="email" name="_username" value="{{ last_username }}" placeholder="name@email.com"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900" autofocus>
                </div>

                <div class="mb-6">
                    <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                    <input type="password" id="password" name="_password" placeholder="Your password"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900">
                </div>

                <button type="submit" class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium hover:bg-gray-700 transition-colors">
                    Log In
                </button>
            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Don't have an account? <a href="{{ path('app_register') }}" class="text-gray-900 font-medium hover:underline">Register now</a>
        </p>
    </div>
{% endblock %}
```

### Step 2: Update base.html.twig

Replace the contents of `templates/base.html.twig`. Guests now see a "Register" button next to "Log In":

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Catatku{% endblock %}</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50 min-h-screen">

    {# Navigation #}
    <nav class="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div class="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
            <a href="{{ path('entry_index') }}" class="text-xl font-bold text-gray-900 hover:text-gray-700">
                Catatku 📓
            </a>
            <div class="flex items-center gap-4">
                {% if app.user %}
                    <span class="text-sm text-gray-500">{{ app.user.name }}</span>
                    <form method="POST" action="{{ path('app_logout') }}">
                        <input type="hidden" name="_csrf_token" value="{{ csrf_token('logout') }}">
                        <button type="submit" class="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                            Logout
                        </button>
                    </form>
                {% else %}
                    <a href="{{ path('app_login') }}" class="text-sm text-gray-600 hover:text-gray-900">Log In</a>
                    <a href="{{ path('app_register') }}" class="text-sm bg-gray-900 text-white px-3 py-1.5 rounded-lg hover:bg-gray-700 transition-colors">
                        Register
                    </a>
                {% endif %}
            </div>
        </div>
    </nav>

    {# Page content #}
    <main class="max-w-2xl mx-auto px-4 py-8">
        {% for message in app.flashes('success') %}
            <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-800 text-sm rounded-xl">
                {{ message }}
            </div>
        {% endfor %}

        {% block body %}{% endblock %}
    </main>

</body>
</html>
```

### Step 3: Update home.html.twig

Replace the contents of `templates/home.html.twig`. Guests now see a second button, "Register", next to "Log In":

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
                {% if app.user %}
                    <a href="{{ path('entry_index') }}" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow transition-all duration-200 hover:scale-105">
                        My Entries
                    </a>
                {% else %}
                    <a href="{{ path('app_login') }}" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow transition-all duration-200 hover:scale-105">
                        Log In
                    </a>
                    <a href="{{ path('app_register') }}" class="inline-flex items-center justify-center px-8 py-3.5 border border-gray-200 text-lg font-medium rounded-xl text-blue-700 bg-white hover:bg-gray-50 shadow-sm transition-all duration-200 hover:border-gray-300">
                        Register
                    </a>
                {% endif %}
            </div>
        </div>
    </div>
</body>
</html>
```

---

## 5. Testing Registration

With the controller and templates in place, test the full registration flow. Log out first if you are still logged in as Budi.

### Step 1: Run Through the Validation Scenarios

Visit `http://localhost:8080/register` and test the following scenarios:

1. Submit with all fields empty to verify each error message appears.
2. Enter an invalid email format like `notanemail` to verify the email validation error.
3. Enter a password shorter than 8 characters to verify the password length error.
4. Enter mismatched passwords to verify the confirmation error.
5. Register with the email `budi@example.com` (the seed user's email) to verify the uniqueness error.
6. Register with completely valid data and verify you are logged in and redirected to the entries listing with a welcome message such as "Welcome to Catatku, Siti!". The listing is empty, because the new account has no entries yet.

### Step 2: Verify That Journals Stay Private

1. As the new user, write an entry.
2. Log out and log in as `budi@example.com` with `password123`. Budi's listing shows only his own entries, not the one you just wrote.
3. Log out, log in as the new user again, and open the detail page of one of Budi's entries by typing its URL (for example `/entries/1`). Symfony answers with `403 Forbidden`.

---

## 6. Fix the Errors in Your Code

**Error 1: Password stored in plain text.**

Forgetting to hash the password before saving it is a serious security vulnerability.

```php
// Wrong: plain text password stored in the database
$user->setPassword($password);

// Correct: always hash before saving
$user->setPassword($passwordHasher->hashPassword($user, $password));
```

`hashPassword($user, $password)` uses the `User` object as context (some algorithms use a per-user salt derived from user properties) and produces a hash string like `$2y$13$...`. This stored hash can be verified later using the same service, but it cannot be reversed. If the database is ever leaked, attackers cannot recover the original passwords.

**Error 2: Uniqueness check runs even when email format is invalid.**

If the email validation already failed, there is no point querying the database for a clearly invalid email.

```php
// Wrong: always queries the database, even for 'notanemail'
if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors['email'] = 'Please enter a valid email address.';
}
$existingUser = $entityManager->getRepository(User::class)->findOneBy(['email' => $email]);
if ($existingUser) {
    $errors['email'] = 'This email address is already taken.';
}

// Correct: only check uniqueness when the format is valid
if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors['email'] = 'Please enter a valid email address.';
}
if (empty($errors['email'])) {
    $existingUser = $entityManager->getRepository(User::class)->findOneBy(['email' => $email]);
    if ($existingUser) {
        $errors['email'] = 'This email address is already taken.';
    }
}
```

The `if (empty($errors['email']))` guard prevents an unnecessary database query. An email that fails the format check can never match a stored address, so the query would only waste time. Checking the format first and only querying the database if it passes is both cleaner and slightly more efficient.

**Error 3: Redirecting after registration without logging the user in.**

If you call `redirectToRoute()` immediately after saving the user without calling `$security->login()`, the user lands on the entries listing while still being treated as a guest. The `access_control` rules then redirect them to the login page.

```php
// Wrong: user is saved but not authenticated
$entityManager->persist($user);
$entityManager->flush();
return $this->redirectToRoute('entry_index');

// Correct: log the user in before redirecting
$entityManager->persist($user);
$entityManager->flush();
$security->login($user, 'form_login', 'main');
return $this->redirectToRoute('entry_index');
```

`$security->login()` creates the security token, stores it in the session, and marks the request as authenticated. Without this call, the next request (the redirect) finds no security token in the session and treats the visitor as unauthenticated. Users would need to log in manually after registering, which is a poor experience.

---

## 7. Exercises

**Exercise 1:** Add a validation rule that the name field must be at most 100 characters long. Add the corresponding error message and verify it appears when you enter a very long name.

**Exercise 2:** After a successful registration, the flash message currently says "Welcome to Catatku, Siti!". Change it to also include the registered email address in the message, like "Welcome, Siti! You are now logged in as siti@example.com."

**Exercise 3:** What happens if you visit `/register` after already being logged in? Test it in the browser and explain why Symfony behaves the way it does based on the code in the `register()` method.

---

## 8. Solutions

**Solution for Exercise 1:**

Replace the name check at the top of the validation in `register()` with this version:

```php
if (empty($name)) {
    $errors['name'] = 'The name field is required.';
} elseif (strlen($name) > 100) {
    $errors['name'] = 'The name must not exceed 100 characters.';
}
```

`strlen($name) > 100` checks the byte length of the string. For names using standard Latin characters, this equals the number of characters. The `elseif` structure ensures that the "too long" error only appears when the name is not empty.

**Solution for Exercise 2:**

Replace the `addFlash()` call in the `register()` method with this version:

```php
$this->addFlash(
    'success',
    'Welcome, ' . $user->getName() . '! You are now logged in as ' . $user->getEmail() . '.'
);
```

`$user->getName()` and `$user->getEmail()` call the getter methods generated by `make:entity` and `make:user`. At this point in the code, the user has already been saved and logged in, so both values are available. String concatenation with `.` is standard PHP.

**Solution for Exercise 3:**

When you visit `/register` while already logged in, Symfony immediately redirects you to the entries listing (`entry_index`). This happens because of the `if ($this->getUser())` check at the very beginning of the `register()` method. `$this->getUser()` returns the authenticated User object when a valid session exists, and returns `null` for unauthenticated visitors. Since the condition is true for a logged-in user, the method returns a redirect response before rendering any HTML. The registration form is never shown.

---

## Next Up - Lesson 12

In this lesson, you completed Catatku's authentication system with user registration. New users can create accounts with hashed passwords and are logged in automatically through the `Security` helper and the `form_login` authenticator. The validation covers required fields, email format, password minimum length, password confirmation matching, and duplicate email detection, and every user sees only their own journal.

In Lesson 12, the final lesson, you will step back and review the entire Catatku journey, explore topics that were intentionally left out of this course, and plan your next steps as a Symfony developer.
