## 1. Before You Begin

Over the last several lessons, you built a full CRUD system using a temporary `/dev-login` shortcut. That shortcut was always a placeholder: it can only log in Budi, and anyone who knows the URL can use it. This lesson replaces it with a real login form, adds logout, and finalizes the security configuration.

Symfony's `form_login` authenticator is a built-in component that handles the entire login flow. When you configure it in `security.yaml`, Symfony intercepts form submissions to the login route, looks up the user by their identifier (email in this case), verifies the password hash, creates a session token, and handles redirection, all without you writing any of that logic.

This lesson also updates the entries controller to scope queries to the currently authenticated user, making journal entries truly private. Creating new accounts is covered in Lesson 11, so for now you will log in with the seed user from Lesson 6.

### What You'll Build

By the end of this lesson, guests are redirected to the login form when they try to access protected pages, Budi can log in with his email and password, entries are scoped to each user's account, and users can log out safely from any page. The `/dev-login` shortcut is gone.

### What You'll Learn

- ✅ How to configure Symfony's `form_login` authenticator in `security.yaml`
- ✅ How to create a login controller and template
- ✅ How Symfony's firewall intercepts the logout route automatically
- ✅ How to update the controller to show only the current user's entries
- ✅ How to add authentication-aware links to the layout and the home page

### What You'll Need

- The `catatku` project with all CRUD features from Lessons 7 to 9 working
- The seed user from Lesson 6: email `budi@example.com`, password `password123`
- The `security.yaml` from Lesson 8

---

## 2. Configuring the Security Firewall

The security firewall is the single most important piece of configuration in a Symfony authentication system. This lesson updates it with the configuration that the rest of the course builds on.

### Step 1: Update security.yaml

Replace the contents of `config/packages/security.yaml` with the following:

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
        - { path: ^/login, roles: PUBLIC_ACCESS }
        - { path: ^/entries, roles: ROLE_USER }
        - { path: ^/$, roles: PUBLIC_ACCESS }
```

`form_login` tells Symfony to use its built-in form login authenticator. `login_path` is the route that displays the login form. `check_path` is the route where the login form submits its data. Both point to `app_login` here, meaning the same route both displays and processes the form. `default_target_path` is where the user goes after a successful login. `enable_csrf: true` adds CSRF protection to the login form automatically without any extra code.

`logout` configures the logout behavior. `path` is the route name that triggers logout. When a request hits `app_logout`, Symfony's firewall intercepts it, destroys the session, and redirects the user to the `target` route.

`access_control` is now the definitive list of which paths require authentication. `/entries` and all of its sub-paths, including `/entries/create` and `/entries/5/edit`, require `ROLE_USER` (any authenticated user). The home page and the login page are `PUBLIC_ACCESS`, meaning no authentication is required.

The `app_login` and `app_logout` routes do not exist yet, so do not open the application in the browser until you finish the next section.

---

## 3. Creating the AuthController

Login and logout belong in a dedicated controller. This keeps authentication logic separate from the journal features, and in Lesson 11 the same controller will also handle registration.

### Step 1: Create AuthController.php

Create the file `src/Controller/AuthController.php`:

```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
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
}
```

`AuthenticationUtils` is a Symfony service designed specifically for login pages. `getLastAuthenticationError()` retrieves the error from the most recent failed login attempt, stored temporarily in the session. `getLastUsername()` retrieves the email address the user entered on the last failed attempt, so you can pre-fill the email field without asking them to retype it.

The `if ($this->getUser())` guard at the top redirects already-authenticated users away from the login page. This pattern is sometimes called a "guest-only" guard.

The `login()` method only handles displaying the form. The actual credential verification is done entirely by the firewall. When the form is submitted, Symfony's `form_login` authenticator intercepts the POST request to `check_path` before it ever reaches this controller method. The controller only runs when displaying the form (GET) or when there is an error to show.

The `logout()` method exists only to define the route name `app_logout` that the firewall configuration references. Symfony intercepts every request to `/logout` before any controller code executes. It destroys the session token and redirects the user to the `target` route specified in `security.yaml`. If you try to add logic here, it will never run.

### Step 2: Verify the Routes

Check that both new routes are registered:

```bash
php bin/console debug:router
```

Output:

```text
 -------------------------- -------- -----------------------------------
  Name                       Method   Path
 -------------------------- -------- -----------------------------------
  _preview_error             ANY      /_error/{code}.{_format}
  _wdt_stylesheet            ANY      /_wdt/styles
  _wdt                       ANY      /_wdt/{token}
  _profiler_home             ANY      /_profiler/
  _profiler_search           ANY      /_profiler/search
  _profiler_search_bar       ANY      /_profiler/search_bar
  _profiler_phpinfo          ANY      /_profiler/phpinfo
  _profiler_xdebug           ANY      /_profiler/xdebug
  _profiler_font             ANY      /_profiler/font/{fontName}.woff2
  _profiler_search_results   ANY      /_profiler/{token}/search/results
  _profiler_open_file        ANY      /_profiler/open
  _profiler                  ANY      /_profiler/{token}
  _profiler_router           ANY      /_profiler/{token}/router
  _profiler_exception        ANY      /_profiler/{token}/exception
  _profiler_exception_css    ANY      /_profiler/{token}/exception.css
  app_login                  ANY      /login
  app_logout                 ANY      /logout
  entry_index                GET      /entries
  entry_show                 ANY      /entries/{id}
  entry_create               ANY      /entries/create
  entry_store                POST     /entries
  entry_edit                 ANY      /entries/{id}/edit
  entry_update               POST     /entries/{id}/update
  entry_delete               POST     /entries/{id}/delete
  home                       ANY      /
 -------------------------- -------- -----------------------------------
```

`app_login` and `app_logout` now appear at the top of the application routes.

---

## 4. Creating the Login Template

The login template requires specific field names. Symfony's `form_login` authenticator reads `_username` for the identifier and `_password` for the password. These names are fixed by the authenticator and cannot be changed without additional configuration.

### Step 1: Create login.html.twig

Create `templates/auth/login.html.twig`. The `auth/` subdirectory keeps authentication templates separate from the entry templates.

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

    </div>
{% endblock %}
```

The email field uses `name="_username"` even though the field label says "Email". This is required by Symfony's `form_login` authenticator, which looks for a field named `_username` for the identifier. Similarly, the password field uses `name="_password"`. The CSRF token must use the intention string `'authenticate'`, which is the default expected by `enable_csrf: true`.

If you view the page source in the browser, the hidden CSRF field shows `value="csrf-token"` instead of a long random string. That is expected. Symfony 8 protects the `authenticate` and `logout` intentions with stateless CSRF protection, configured in `config/packages/csrf.yaml`: instead of comparing the token with a value stored in the session, Symfony checks that the request really comes from your own site using the `Origin` header that every modern browser sends with a form submission.

The error message is deliberately vague: "The email or password you entered is incorrect." A more specific message like "No account found with this email" or "Wrong password" would allow an attacker to enumerate valid email addresses by observing which message appears. The vague message reveals nothing about whether the email exists.

`{{ last_username }}` pre-fills the email input with the address the user typed on a failed login. This improves usability: the user only needs to correct the password without retyping the email.

---

## 5. Updating the EntryController

Now that real login works, the temporary shortcut can go, and the entries listing can show only the logged-in user's entries.

### Step 1: Remove devLogin and Scope the Listing

Delete the entire `devLogin()` method from `src/Controller/EntryController.php`, together with the two imports that only it used (`UserRepository` and `PostAuthenticationToken`). Then update `index()` to filter by the current user. The complete file now looks like this:

```php
<?php

namespace App\Controller;

use App\Entity\Entry;
use App\Repository\EntryRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class EntryController extends AbstractController
{
    #[Route('/entries', name: 'entry_index', methods: ['GET'])]
    public function index(EntryRepository $entryRepository): Response
    {
        $entries = $entryRepository->findBy(
            ['user' => $this->getUser()],
            ['createdAt' => 'DESC']
        );

        return $this->render('entry/index.html.twig', [
            'entries' => $entries,
        ]);
    }

    #[Route('/entries/{id}', name: 'entry_show', requirements: ['id' => '\d+'])]
    public function show(Entry $entry): Response
    {
        if ($entry->getUser() !== $this->getUser()) {
            throw $this->createAccessDeniedException();
        }

        return $this->render('entry/show.html.twig', [
            'entry' => $entry,
        ]);
    }

    #[Route('/entries/create', name: 'entry_create')]
    public function create(): Response
    {
        return $this->render('entry/create.html.twig');
    }

    #[Route('/entries', name: 'entry_store', methods: ['POST'])]
    public function store(Request $request, EntityManagerInterface $entityManager): Response
    {
        $title = trim($request->request->get('title', ''));
        $content = trim($request->request->get('content', ''));

        $errors = [];
        if (empty($title)) {
            $errors['title'] = 'The title field is required.';
        } elseif (strlen($title) > 255) {
            $errors['title'] = 'The title must not exceed 255 characters.';
        }
        if (empty($content)) {
            $errors['content'] = 'The content field is required.';
        }

        if (!$this->isCsrfTokenValid('create-entry', $request->request->get('_csrf_token'))) {
            throw $this->createAccessDeniedException('Invalid CSRF token.');
        }

        if (!empty($errors)) {
            return $this->render('entry/create.html.twig', [
                'errors' => $errors,
                'old'    => ['title' => $title, 'content' => $content],
            ]);
        }

        $entry = new Entry();
        $entry->setTitle($title);
        $entry->setContent($content);
        $entry->setUser($this->getUser());

        $entityManager->persist($entry);
        $entityManager->flush();

        $this->addFlash('success', 'Entry saved successfully.');

        return $this->redirectToRoute('entry_index');
    }

    #[Route('/entries/{id}/edit', name: 'entry_edit', requirements: ['id' => '\d+'])]
    public function edit(Entry $entry): Response
    {
        if ($entry->getUser() !== $this->getUser()) {
            throw $this->createAccessDeniedException();
        }

        return $this->render('entry/edit.html.twig', [
            'entry' => $entry,
        ]);
    }

    #[Route('/entries/{id}/update', name: 'entry_update', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function update(Request $request, Entry $entry, EntityManagerInterface $entityManager): Response
    {
        if ($entry->getUser() !== $this->getUser()) {
            throw $this->createAccessDeniedException();
        }

        if (!$this->isCsrfTokenValid('edit-entry-' . $entry->getId(), $request->request->get('_csrf_token'))) {
            throw $this->createAccessDeniedException('Invalid CSRF token.');
        }

        $title = trim($request->request->get('title', ''));
        $content = trim($request->request->get('content', ''));

        $errors = [];
        if (empty($title)) {
            $errors['title'] = 'The title field is required.';
        } elseif (strlen($title) > 255) {
            $errors['title'] = 'The title must not exceed 255 characters.';
        }
        if (empty($content)) {
            $errors['content'] = 'The content field is required.';
        }

        if (!empty($errors)) {
            return $this->render('entry/edit.html.twig', [
                'entry'  => $entry,
                'errors' => $errors,
                'old'    => ['title' => $title, 'content' => $content],
            ]);
        }

        $entry->setTitle($title);
        $entry->setContent($content);
        $entry->setUpdatedAt(new \DateTimeImmutable());

        $entityManager->flush();

        $this->addFlash('success', 'Entry updated successfully.');

        return $this->redirectToRoute('entry_show', ['id' => $entry->getId()]);
    }

    #[Route('/entries/{id}/delete', name: 'entry_delete', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function delete(Request $request, Entry $entry, EntityManagerInterface $entityManager): Response
    {
        if ($entry->getUser() !== $this->getUser()) {
            throw $this->createAccessDeniedException();
        }

        if (!$this->isCsrfTokenValid('delete-entry-' . $entry->getId(), $request->request->get('_csrf_token'))) {
            throw $this->createAccessDeniedException('Invalid CSRF token.');
        }

        $entityManager->remove($entry);
        $entityManager->flush();

        $this->addFlash('success', 'Entry deleted successfully.');

        return $this->redirectToRoute('entry_index');
    }
}
```

Development shortcuts must never be left in code that could be deployed to a real server. Visiting `/dev-login` now returns a 404 Not Found page.

The `access_control` rule in `security.yaml` guarantees that only authenticated users can reach `/entries`. This means `$this->getUser()` will always return a valid `User` object here, never `null`. Passing `['user' => $this->getUser()]` as the criteria to `findBy()` adds a `WHERE user_id = ?` clause to the SQL query, so only the current user's entries are returned.

Previously, `findBy([], ...)` returned all entries from all users. Now each user sees only their own journal. This is what makes Catatku a private journal rather than a public feed.

---

## 6. Adding Authentication Links

The layout and the home page still have no way to log in or out. Now that `app_login` and `app_logout` exist, both templates can link to them.

### Step 1: Update base.html.twig

Replace the contents of `templates/base.html.twig` with the following:

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

The right side of the navigation bar, which was empty since Lesson 7, now changes with the login state. `{% if app.user %}` is true for a logged-in user, who sees their name (`app.user.name` calls `getName()` on the `User` entity) and a Logout button. A guest sees a "Log In" link instead. The Register link joins them in Lesson 11.

Logout is a small form that sends a POST request to `app_logout`, rather than a plain link, so that a link or an image on another website cannot log your users out.

### Step 2: Update home.html.twig

The home page was created in Lesson 3 with empty `href` attributes. Replace the contents of `templates/home.html.twig`:

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
                {% endif %}
            </div>
        </div>
    </div>
</body>
</html>
```

`{% if app.user %}` checks whether the visitor is authenticated. Authenticated users see a "My Entries" button that links to `entry_index`. Unauthenticated visitors see a "Log In" button. `app` is Twig's global Symfony application variable, which provides access to the current user, session, and request without any extra setup.

---

## 7. Testing the Complete Authentication Flow

With all pieces in place, test every authentication scenario to verify the system works end to end.

### Step 1: Run Through All Scenarios

Test each of the following:

1. Visit `http://localhost:8080/entries` without being logged in. You should be redirected to `/login`.
2. Submit the login form with `budi@example.com` and a wrong password. Verify the vague error message appears and the email field keeps `budi@example.com`.
3. Submit the login form with `budi@example.com` and `password123`. Verify you land on the entries listing and see "Budi" in the navigation bar.
4. Verify that Budi's entries are listed and that create, edit, and delete still work.
5. Visit `http://localhost:8080/login` while logged in. You are sent straight back to the entries listing.
6. Click "Logout" in the navigation. Verify you are redirected to the login page and can no longer access the entries listing.

---

## 8. Fix the Errors in Your Code

**Error 1: Login form uses wrong field names.**

Symfony's `form_login` authenticator reads fixed field names. Using incorrect names means the authenticator receives empty values and always fails.

```html
<!-- Wrong: authenticator does not look for 'email' or 'pass' -->
<input name="email" ...>
<input name="pass" ...>

<!-- Correct: authenticator reads '_username' and '_password' -->
<input name="_username" ...>
<input name="_password" ...>
```

Symfony's `form_login` reads `_username` for the identifier and `_password` for the password by default. If you want to change them, you can configure `username_parameter` and `password_parameter` under `form_login` in `security.yaml`, but the defaults work for this course.

**Error 2: CSRF token for login uses the wrong intention.**

The `enable_csrf: true` option in `security.yaml` expects the CSRF token field to use the intention string `'authenticate'`. Using a different string means CSRF validation fails on every login attempt.

```twig
{# Wrong: wrong intention string for form_login CSRF #}
<input type="hidden" name="_csrf_token" value="{{ csrf_token('login') }}">

{# Correct: must match Symfony's expected intention #}
<input type="hidden" name="_csrf_token" value="{{ csrf_token('authenticate') }}">
```

When `enable_csrf: true` is set under `form_login`, Symfony validates the token using the intention `'authenticate'`. If the token in the form was generated with a different intention, validation fails and the login is rejected as a CSRF attack attempt.

**Error 3: access_control order matters.**

Symfony evaluates `access_control` rules in order and stops at the first match. If a broad public rule appears before `^/entries`, the entries rule is never reached.

```yaml
# Wrong: ^/ matches every URL, so /entries becomes public
access_control:
    - { path: ^/, roles: PUBLIC_ACCESS }
    - { path: ^/entries, roles: ROLE_USER }

# Correct: specific rules first, and ^/$ matches only the home page
access_control:
    - { path: ^/login, roles: PUBLIC_ACCESS }
    - { path: ^/entries, roles: ROLE_USER }
    - { path: ^/$, roles: PUBLIC_ACCESS }
```

The `^/$` pattern matches only the root URL exactly, so it does not conflict with `^/entries`. But `^/` without the `$` matches every URL, including `/entries`, and because it comes first, the permissive rule wins. Always place the most specific rules at the top.

---

## 9. Exercises

**Exercise 1:** After logging out, visit `http://localhost:8080/entries` directly. Describe what happens and trace exactly which part of `security.yaml` causes it.

**Exercise 2:** The login error message currently reads "The email or password you entered is incorrect." Improve the visual presentation by adding a warning icon emoji before the text. No PHP changes are needed, only a template update.

**Exercise 3:** Open HeidiSQL and look at the `user` table. Find the row for `budi@example.com`. Verify the password column contains a hashed value (starting with `$2y$` for bcrypt). Explain why storing this hash instead of the original password is important.

---

## 10. Solutions

**Solution for Exercise 1:**

Visiting `/entries` without being logged in triggers the `access_control` rule `{ path: ^/entries, roles: ROLE_USER }`. Because the visitor does not have `ROLE_USER`, Symfony asks the firewall what to do. The `main` firewall has `form_login` configured with `login_path: app_login`, so Symfony automatically redirects the visitor to `/login` rather than showing an error page. This is the correct production behavior: guests are guided to log in rather than receiving a generic error.

**Solution for Exercise 2:**

Replace the `{% if error %}` block in `templates/auth/login.html.twig` with this version:

```html
{% if error %}
    <div class="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg">
        ⚠️ The email or password you entered is incorrect.
    </div>
{% endif %}
```

The warning emoji is a Unicode character and can be placed directly in the template without any special handling.

**Solution for Exercise 3:**

The password column in the `user` table contains a value that starts with `$2y$13$`. This is a bcrypt hash: `2y` names the algorithm and `13` is the cost, which controls how slow the hashing is. Bcrypt is a one-way hashing function: given the hash, there is no mathematical way to recover the original password. If your database is ever compromised (through a SQL injection, a server breach, or a leaked backup), an attacker who obtains the hashed values cannot use them to log in, because the original passwords are not stored anywhere. Verifying a login requires running the bcrypt algorithm on the submitted password and comparing the result to the stored hash, not comparing strings directly.

---

## Next Up - Lesson 11

In this lesson, you replaced the `/dev-login` shortcut with Symfony's `form_login` authenticator, which handles credential verification, session creation, and redirect logic based on the `security.yaml` configuration. The login template uses `_username` and `_password` field names, the CSRF token uses the `'authenticate'` intention, and logout is handled entirely by the firewall. The entries controller now scopes queries to the authenticated user, making journal entries truly private.

There is still one gap: only Budi, created by the fixtures, can log in. In Lesson 11, you will build user registration so anyone can create an account, hash their password, and be logged in automatically right after signing up.
