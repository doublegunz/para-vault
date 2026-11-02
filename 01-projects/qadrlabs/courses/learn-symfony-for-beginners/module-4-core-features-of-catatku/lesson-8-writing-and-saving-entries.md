## 1. Before You Begin

The previous lesson produced structured pages with a shared layout. But every entry was created through fixtures, a development shortcut that has nothing to do with the real user experience. There is no way for someone to write a new entry from inside the application. This lesson closes that gap.

Building a create form in Symfony involves three moving parts: a controller method that displays the empty form, a second controller method that handles the submitted data, and a Twig template that renders the form and its validation errors.

This lesson also introduces the security firewall. Before a user can save a journal entry, Symfony needs to know who that user is. You will configure a basic `access_control` rule to protect the create route, and add a temporary developer login shortcut so you can test the feature before building the real login form in Lesson 10.

### What You'll Build

By the end of this lesson, a logged-in user can open the create form, write a journal entry with a title and body, submit the form, and see the new entry appear at the top of the entries listing.

### What You'll Learn

- ✅ How to build a form with CSRF protection using manual HTML (not Symfony's Form component)
- ✅ How to validate input in the controller with field-level error messages
- ✅ How to persist a new entity using EntityManagerInterface
- ✅ How `$this->addFlash()` creates one-time session-based success messages
- ✅ How to configure a basic security firewall with access control rules
- ✅ How to protect the detail page so only the entry owner can read it

### What You'll Need

- The layout and views from Lesson 7
- The seed user (`budi@example.com`) created via fixtures in Lesson 6

---

## 2. Configuring Basic Security

Before building the create form, you need to protect the route so only authenticated users can access it. The security firewall is configured in a YAML file.

### Step 1: Update security.yaml

Open `config/packages/security.yaml` and replace its content with the following:

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

    access_control:
        - { path: ^/entries/create, roles: ROLE_USER }
        - { path: ^/entries/\d+, roles: ROLE_USER }
```

`providers` tells Symfony which entity to use for user lookup. The `property: email` line means that when Symfony looks up a user by identifier, it searches by email address.

`access_control` is a list of path patterns and their required roles. `ROLE_USER` is the default role assigned to every authenticated user in Symfony. Any unauthenticated visitor who tries to access a protected path now sees Symfony's error page with the message "Full authentication is required to access this resource." and the status `401 Unauthorized`. Try it by opening `http://localhost:8080/entries/create` in your browser. The page does not exist yet, but the firewall rejects the request before Symfony even looks for the route. In Lesson 10, you will configure a proper redirect to the login page.

### Step 2: Add a Temporary Dev Login Route

To test the create form before the real login system is built, add a temporary developer login route to `EntryController`. This shortcut programmatically logs in the seed user so you can access protected pages.

Now that there is a logged-in user, you can also finish the detail page from Lesson 7: add an ownership check to `show()` so a user can only read their own entries. The complete `src/Controller/EntryController.php` now looks like this:

```php
<?php

namespace App\Controller;

use App\Entity\Entry;
use App\Repository\EntryRepository;
use App\Repository\UserRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Authenticator\Token\PostAuthenticationToken;

class EntryController extends AbstractController
{
    #[Route('/entries', name: 'entry_index')]
    public function index(EntryRepository $entryRepository): Response
    {
        $entries = $entryRepository->findBy([], ['createdAt' => 'DESC']);

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

    #[Route('/dev-login', name: 'dev_login')]
    public function devLogin(UserRepository $userRepository, Request $request): Response
    {
        $user = $userRepository->findOneBy(['email' => 'budi@example.com']);

        $token = new PostAuthenticationToken(
            $user,
            'main',
            $user->getRoles()
        );
        $this->container->get('security.token_storage')->setToken($token);
        $request->getSession()->set('_security_main', serialize($token));

        return $this->redirectToRoute('entry_index');
    }
}
```

This method finds the seed user, creates a security token for that user on the `main` firewall, and stores it in the session. After visiting `/dev-login`, Symfony treats subsequent requests as if you are logged in as Budi. This route must be removed before the lesson on real authentication. Never leave development-only login shortcuts in a production application.

You may wonder why the method builds the token by hand instead of calling Symfony's `Security::login()` helper. That helper logs a user in through one of the firewall's authenticators, and the `main` firewall has none yet. Calling it now fails with `No authenticators found for firewall "main".` The real authenticator, `form_login`, arrives in Lesson 10.

`$entry->getUser() !== $this->getUser()` in `show()` compares the entry's owner against the currently logged-in user. If they are different, `createAccessDeniedException()` throws a 403 Forbidden response. This check prevents one user from reading another user's entries by guessing the URL.

Visit `http://localhost:8080/dev-login`. You are redirected to the entries listing, and from now on you can open the detail page of any of Budi's entries.

---

## 3. Building the Create Form

With route protection in place, you can now build the form itself. The create flow uses two controller methods: one to display the empty form, and one to process the submitted data.

### Step 1: Add the create() and store() Methods

Add two methods to `EntryController`: `create()` handles GET requests and renders the empty form, and `store()` handles POST requests, validates the form input, and saves the new entry. You also need three new imports and one small change to the `index()` route. The complete `src/Controller/EntryController.php` now looks like this:

```php
<?php

namespace App\Controller;

use App\Entity\Entry;
use App\Repository\EntryRepository;
use App\Repository\UserRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Authenticator\Token\PostAuthenticationToken;

class EntryController extends AbstractController
{
    #[Route('/entries', name: 'entry_index', methods: ['GET'])]
    public function index(EntryRepository $entryRepository): Response
    {
        $entries = $entryRepository->findBy([], ['createdAt' => 'DESC']);

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

    #[Route('/dev-login', name: 'dev_login')]
    public function devLogin(UserRepository $userRepository, Request $request): Response
    {
        $user = $userRepository->findOneBy(['email' => 'budi@example.com']);

        $token = new PostAuthenticationToken(
            $user,
            'main',
            $user->getRoles()
        );
        $this->container->get('security.token_storage')->setToken($token);
        $request->getSession()->set('_security_main', serialize($token));

        return $this->redirectToRoute('entry_index');
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
}
```

The `create()` method does nothing except render the template. It has no data to fetch and no logic to run. In Symfony, separating the display action from the save action keeps each method focused on a single responsibility.

Look closely at the `index()` route: it now has `methods: ['GET']`. This matters because `store()` uses the same path, `/entries`, for POST requests. Symfony checks routes in the order they are defined, and a route without `methods` accepts every HTTP method. Without `methods: ['GET']`, the form's POST request would be caught by `index()`, which simply shows the listing again, and `store()` would never run.

`$request->request->get('title', '')` reads a POST field named `title`. The second argument is the default value if the field is missing. `trim()` removes leading and trailing whitespace so that a title containing only spaces is treated as empty.

`$this->isCsrfTokenValid('create-entry', ...)` verifies the CSRF token submitted with the form. The first argument is the intention string, which must match exactly what was used to generate the token in the template. If the token is invalid or missing, an attacker is likely forging the request.

`EntityManagerInterface $entityManager` is injected by Symfony. `persist($entry)` registers the new entity with Doctrine. `flush()` executes the INSERT SQL statement. Without `flush()`, the entry is never written to the database.

`$this->getUser()` returns the currently authenticated User object. Passing it to `setUser()` creates the foreign key relationship between the entry and its owner.

`$this->addFlash('success', '...')` stores a message in the session. The base layout's `{% for message in app.flashes('success') %}` loop picks it up and displays it on the next page load, then clears it automatically.

If validation fails, the template is re-rendered with `$errors` and `$old` passed in. The `$old` array allows the form to repopulate the fields with what the user typed, so they do not have to start over.

---

## 4. Creating the Form Template

The template renders the form with CSRF protection and displays validation errors when present.

### Step 1: Create create.html.twig

Create `templates/entry/create.html.twig`:

```html
{% extends 'base.html.twig' %}

{% block title %}Write Entry - Catatku{% endblock %}

{% block body %}
    <div class="mb-6">
        <a href="{{ path('entry_index') }}" class="text-sm text-gray-400 hover:text-gray-700">← Back to list</a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Write New Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="{{ path('entry_store') }}">
            <input type="hidden" name="_csrf_token" value="{{ csrf_token('create-entry') }}">

            {# Title #}
            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" id="title" name="title"
                    value="{{ old.title|default('') }}"
                    placeholder="Entry title..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent {{ errors.title is defined ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                    autofocus>
                {% if errors.title is defined %}
                    <p class="text-xs text-red-500 mt-1">{{ errors.title }}</p>
                {% endif %}
            </div>

            {# Content #}
            <div class="mb-6">
                <label for="content" class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea id="content" name="content" rows="12"
                    placeholder="Write your entry here..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y {{ errors.content is defined ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                >{{ old.content|default('') }}</textarea>
                {% if errors.content is defined %}
                    <p class="text-xs text-red-500 mt-1">{{ errors.content }}</p>
                {% endif %}
            </div>

            {# Buttons #}
            <div class="flex items-center justify-between">
                <a href="{{ path('entry_index') }}" class="text-sm text-gray-500 hover:text-gray-900">Cancel</a>
                <button type="submit" class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg hover:bg-gray-700 transition-colors">
                    Save Entry
                </button>
            </div>
        </form>
    </div>
{% endblock %}
```

`{{ csrf_token('create-entry') }}` generates a CSRF token with the intention string `'create-entry'`. This value is submitted with the form and verified by `isCsrfTokenValid('create-entry', ...)` in the controller. The intention string acts as a namespace: a token generated with `'create-entry'` cannot be used to pass validation for `'delete-entry'`.

`{{ old.title|default('') }}` displays the previously submitted title value after a failed validation, or an empty string on the first load. The `|default('')` filter prevents a Twig "undefined variable" error when `old` is not passed from the controller (which is the case on the initial GET request).

`{{ errors.title is defined ? 'border-red-400 bg-red-50' : 'border-gray-300' }}` conditionally applies error styling to the input field. When the `errors` variable has a `title` key, the field gets a red border. Otherwise it uses the normal gray border. This inline ternary is Twig's equivalent of a CSS class toggle.

### Step 2: Add the Write Button to the Listing

Now that the `entry_create` route exists, the listing can link to it. Replace the contents of `templates/entry/index.html.twig` with the following:

```html
{% extends 'base.html.twig' %}

{% block title %}My Entries - Catatku{% endblock %}

{% block body %}
    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
        <a href="{{ path('entry_create') }}" class="bg-gray-900 text-white text-sm px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">
            + Write New Entry
        </a>
    </div>

    <div class="space-y-4">
        {% if entries is empty %}
            <div class="text-center py-16">
                <p class="text-5xl mb-4">📓</p>
                <p class="font-medium text-gray-600">No entries yet</p>
                <p class="text-sm text-gray-400 mt-1">Start writing your first entry!</p>
                <a href="{{ path('entry_create') }}" class="inline-block mt-4 text-sm text-blue-600 hover:underline">Write now →</a>
            </div>
        {% else %}
            {% for entry in entries %}
                <div class="bg-white rounded-xl border border-gray-200 p-5 hover:border-gray-300 transition-colors">
                    <div class="flex items-start justify-between gap-3 mb-3">
                        <a href="{{ path('entry_show', {id: entry.id}) }}" class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
                            {{ entry.title }}
                        </a>
                        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">{{ entry.createdAt|date('d M Y') }}</span>
                    </div>
                    <p class="text-sm text-gray-500 line-clamp-2 mb-4">{{ entry.content }}</p>
                    <div class="flex items-center gap-3 pt-3 border-t border-gray-100">
                        <a href="{{ path('entry_show', {id: entry.id}) }}" class="text-xs text-blue-600 hover:text-blue-800">Read</a>
                    </div>
                </div>
            {% endfor %}
        {% endif %}
    </div>
{% endblock %}
```

There are two new links, both generated with `{{ path('entry_create') }}`: a "+ Write New Entry" button next to the heading, and a "Write now" link inside the empty state message, which appears when the user has no entries yet.

---

## 5. Testing the Create Flow

With the controller methods and template in place, you can test the full create flow.

### Step 1: Log In and Test

Follow these steps to verify everything works:

1. Visit `http://localhost:8080/dev-login` to authenticate as the seed user.
2. Click "+ Write New Entry" on the listing, or go to `http://localhost:8080/entries/create`.
3. Submit the form with empty fields to see the validation error messages appear in the form.
4. Fill in a title and body, then click "Save Entry". You should be redirected to the entries listing with a green success banner that says "Entry saved successfully." and your new entry at the top.
5. Submit the form again after changing the hidden `_csrf_token` value with your browser's developer tools. Symfony rejects the request with the message "Invalid CSRF token." and the status `403 Forbidden`.

---

## 6. Fix the Errors in Your Code

**Error 1: CSRF token validation fails immediately.**

This error appears when the intention string in the controller does not match the one used in the template.

```php
// Wrong: controller checks 'entry-create', but template generates 'create-entry'
if (!$this->isCsrfTokenValid('entry-create', $request->request->get('_csrf_token'))) {

// Correct: both must use the same intention string
if (!$this->isCsrfTokenValid('create-entry', $request->request->get('_csrf_token'))) {
```

After this change in the controller, verify the template line:

```twig
<input type="hidden" name="_csrf_token" value="{{ csrf_token('create-entry') }}">
```

The string passed to `csrf_token()` in Twig and to `isCsrfTokenValid()` in PHP must be identical. A mismatch always produces an Invalid CSRF token error, even when the user submits the form legitimately.

**Error 2: Old input not preserved after validation failure.**

When validation fails and the template is re-rendered, the user should see their previous input. If the `old` variable is not passed, the form resets to empty.

```php
// Wrong: re-renders without old input
if (!empty($errors)) {
    return $this->render('entry/create.html.twig', [
        'errors' => $errors,
    ]);
}

// Correct: pass both errors and old input
if (!empty($errors)) {
    return $this->render('entry/create.html.twig', [
        'errors' => $errors,
        'old'    => ['title' => $title, 'content' => $content],
    ]);
}
```

The `old` array holds the user's submitted values so the template can repopulate the form fields. Without it, the user must retype everything after a validation error. Requiring the user to retype a long journal entry because of a missing title is a very poor experience.

**Error 3: The form submits, but nothing is saved.**

If the listing route has no `methods` option, it also answers POST requests to `/entries`. Because `index()` is defined before `store()`, Symfony picks it first, and the submitted form just shows the listing again without saving or validating anything.

```php
// Wrong: entry_index accepts any HTTP method, including POST
#[Route('/entries', name: 'entry_index')]

// Correct: entry_index only answers GET, so POST reaches entry_store
#[Route('/entries', name: 'entry_index', methods: ['GET'])]
```

Run `php bin/console debug:router` to check. The `Method` column must show `GET` for `entry_index` and `POST` for `entry_store`. Whenever two routes share a path, give each one an explicit `methods` option.

---

## 7. Exercises

**Exercise 1:** Add a third validation rule to the `store()` method: the content must be at least 10 characters long. Add an appropriate error message and verify it appears when you submit a very short body.

**Exercise 2:** Right now, the 255-character limit on the title is only checked on the server side. Add `maxlength="255"` as an HTML attribute to the title input in `create.html.twig`. Explain why both client-side and server-side validation are still necessary.

**Exercise 3:** After a successful save, the user is redirected to the entries listing. Modify the `store()` method so the user is redirected to the detail page of the entry they just created, instead of the listing.

---

## 8. Solutions

**Solution for Exercise 1:**

Add an `elseif` branch to the content check. Replace the whole `store()` method in `EntryController` with this version:

```php
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
    } elseif (strlen($content) < 10) {
        $errors['content'] = 'The content must be at least 10 characters.';
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
```

`strlen($content)` returns the number of bytes in the string. For ASCII text, this equals the number of characters. The `elseif` structure ensures that the "too short" error only appears when the content is not empty. If the field is empty, the "required" message takes priority.

**Solution for Exercise 2:**

Replace the `<input>` element for the title in `create.html.twig` with this version:

```html
<input type="text" id="title" name="title"
    value="{{ old.title|default('') }}"
    placeholder="Entry title..."
    maxlength="255"
    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent {{ errors.title is defined ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
    autofocus>
```

The only new line is `maxlength="255"`. The browser now stops accepting characters once the title reaches 255.

Client-side validation (the `maxlength` attribute) prevents most users from accidentally submitting a title that is too long, which improves the user experience. However, it does not prevent a determined attacker from bypassing the HTML by sending a raw HTTP request with a crafted payload. Server-side validation in the controller is essential because it is the only validation the server controls. Both layers are necessary for a secure and user-friendly application.

**Solution for Exercise 3:**

Change the redirect at the end of `store()`. The complete method looks like this:

```php
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

    return $this->redirectToRoute('entry_show', ['id' => $entry->getId()]);
}
```

After `flush()`, Doctrine has written the entry to the database and the `id` property has been populated with the auto-generated primary key. `$entry->getId()` returns that ID, which you pass as a route parameter to `redirectToRoute()`. The user is taken directly to the detail page of the entry they just saved.

---

## Next Up - Lesson 9

In this lesson, you configured basic route protection with Symfony's security firewall, added a temporary login shortcut and an ownership check for the detail page, built a create form with CSRF protection and field-level validation, and saved new entries to the database using the EntityManager. You also learned how flash messages provide feedback to the user after a form submission.

In Lesson 9, you will complete the full CRUD cycle by adding edit and delete functionality. Users will be able to modify existing entries and remove them, with proper ownership checks and CSRF protection on every destructive action.