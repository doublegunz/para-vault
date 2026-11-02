## 1. Before You Begin

The previous lesson closed the first half of the CRUD cycle. Users can now create new journal entries. But there is no way to fix a typo, revise what was written, or remove an entry entirely. This lesson completes the other half.

Edit and delete are structurally similar to create: they both involve a controller method that displays a form, a second method that processes the submission, and a CSRF token to protect against forged requests. The key difference is that edit and delete operate on an existing entry, which means every action must verify that the entry belongs to the currently logged-in user.

By the end of this lesson, the full CRUD cycle will be complete. You will also understand the pattern Symfony uses for organizing controller actions and why updates do not require calling `persist()` again.

### What You'll Build

By the end of this lesson, users can edit existing entries and delete them. The full CRUD cycle (Create, Read, Update, Delete) will be complete for Catatku.

### What You'll Learn

- ✅ How to build an edit form pre-filled with the current entity values
- ✅ How to update an existing entity using the EntityManager
- ✅ How to delete an entity and redirect afterward
- ✅ Why update operations do not need `persist()`
- ✅ How CSRF tokens are made unique per entry to prevent token reuse

### What You'll Need

- At least one existing entry to edit and delete
- The dev login shortcut (`/dev-login`) from Lesson 8 to access the application

---

## 2. Adding Edit and Delete to the Controller

All three new methods belong in `EntryController`. Each one uses the entity value resolver to automatically fetch the entry by the ID in the URL, then verifies ownership before doing anything.

### Step 1: Add the edit() Method

The `edit()` method handles GET requests to the edit form. It loads the entry and passes it to the template so the form can be pre-filled with the current values.

```php
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
```

This method follows the same ownership check pattern you added to `show()` in Lesson 8. `createAccessDeniedException()` throws a 403 Forbidden response if the entry does not belong to the current user. The check must appear at the beginning of any method that operates on a specific entry, before any data is passed to the template.

### Step 2: Add the update() Method

The `update()` method handles POST requests from the edit form. It validates the input, updates the entity, and redirects to the entry's detail page.

```php
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
```

`'edit-entry-' . $entry->getId()` builds a unique CSRF token intention per entry. If the entry ID is 5, the intention is `'edit-entry-5'`. This prevents a token generated for editing entry 5 from being used to update entry 8. The same token intention must appear in the form template.

For the update operation, notice that only `$entityManager->flush()` is called, without a preceding `persist()`. This is because the entry is already a **tracked entity**: Doctrine loaded it from the database when the entity value resolver ran, so Doctrine is already monitoring it for changes. When you call `setTitle()` and `setContent()` on a tracked entity, Doctrine records those changes. `flush()` then generates and executes the UPDATE SQL statement automatically.

`$entry->setUpdatedAt(new \DateTimeImmutable())` records the exact moment the entry was last edited. Doctrine does not set this automatically: you are responsible for updating it before flushing.

### Step 3: Add the delete() Method

The `delete()` method handles POST requests from the delete form. It verifies the CSRF token, removes the entity, and redirects to the entries listing.

```php
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
```

`$entityManager->remove($entry)` marks the entity for deletion. Like `persist()`, this does not immediately execute SQL. `flush()` that follows sends the DELETE query to the database. After deletion, the user is redirected to the entries listing because the entry they were viewing no longer exists.

Note that the delete route only accepts POST requests (`methods: ['POST']`). This prevents a simple link or an image on another website from triggering a deletion when a logged-in user visits it. Delete actions must always be triggered by a form submission.

### Step 4: Review the Complete Controller

Add all three methods at the end of the `EntryController` class, after `store()`. They use `Request` and `EntityManagerInterface`, which are already imported from Lesson 8. The complete `src/Controller/EntryController.php` now looks like this:

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

Compare your file with this version line by line. A missing closing brace or a method placed outside the class is the most common reason for a syntax error at this point.

---

## 3. Creating the Edit Template

The edit template is almost identical to the create template. The key difference is that the form fields are pre-filled with the entry's current values, and the form submits to the `entry_update` route with the entry's ID.

### Step 1: Create edit.html.twig

Create `templates/entry/edit.html.twig`:

```html
{% extends 'base.html.twig' %}

{% block title %}Edit: {{ entry.title }} - Catatku{% endblock %}

{% block body %}
    <div class="mb-6">
        <a href="{{ path('entry_show', {id: entry.id}) }}" class="text-sm text-gray-400 hover:text-gray-700">← Back to entry</a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Edit Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="{{ path('entry_update', {id: entry.id}) }}">
            <input type="hidden" name="_csrf_token" value="{{ csrf_token('edit-entry-' ~ entry.id) }}">

            {# Title #}
            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" id="title" name="title"
                    value="{{ old.title is defined ? old.title : entry.title }}"
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
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y {{ errors.content is defined ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                >{{ old.content is defined ? old.content : entry.content }}</textarea>
                {% if errors.content is defined %}
                    <p class="text-xs text-red-500 mt-1">{{ errors.content }}</p>
                {% endif %}
            </div>

            {# Buttons #}
            <div class="flex items-center justify-between">
                <a href="{{ path('entry_show', {id: entry.id}) }}" class="text-sm text-gray-500 hover:text-gray-900">Cancel</a>
                <button type="submit" class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg hover:bg-gray-700 transition-colors">
                    Save Changes
                </button>
            </div>
        </form>
    </div>
{% endblock %}
```

`{{ csrf_token('edit-entry-' ~ entry.id) }}` generates the per-entry token. The `~` operator in Twig concatenates strings. If the entry ID is 5, this generates a token with intention `'edit-entry-5'`. The same string is constructed in the controller with `'edit-entry-' . $entry->getId()`.

`{{ old.title is defined ? old.title : entry.title }}` handles two cases. On the initial GET request, `old` is not passed from the controller, so `old.title is defined` is false and the field shows the entry's current title. After a failed POST validation, `old` is passed with the submitted value, so the field shows what the user typed instead of the original database value. This Twig ternary is equivalent to Laravel's `old('title', $entry->getTitle())` helper.

### Step 2: Add Edit and Delete Buttons to the Listing

Now that `entry_edit` and `entry_delete` exist, every card in the listing can offer both actions. Replace the contents of `templates/entry/index.html.twig` with the following:

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
                        <a href="{{ path('entry_edit', {id: entry.id}) }}" class="text-xs text-gray-500 hover:text-gray-800">Edit</a>
                        <form method="POST" action="{{ path('entry_delete', {id: entry.id}) }}" onsubmit="return confirm('Delete this entry?')" class="ml-auto">
                            <input type="hidden" name="_csrf_token" value="{{ csrf_token('delete-entry-' ~ entry.id) }}">
                            <button type="submit" class="text-xs text-red-400 hover:text-red-600">Delete</button>
                        </form>
                    </div>
                </div>
            {% endfor %}
        {% endif %}
    </div>
{% endblock %}
```

The Edit link points to `entry_edit`. Delete is not a link but a small form, because the `entry_delete` route only accepts POST requests.

`{{ csrf_token('delete-entry-' ~ entry.id) }}` generates a CSRF token unique to each entry's delete action. The `~` operator in Twig concatenates strings, so each entry gets a distinct token intention string like `'delete-entry-3'`. This prevents an attacker from reusing a delete token from one entry to delete a different entry.

`onsubmit="return confirm('Delete this entry?')"` asks the browser to show a confirmation dialog before the form is sent. If the user clicks Cancel, `confirm()` returns `false` and the form is not submitted.

### Step 3: Add Edit and Delete Buttons to the Detail Page

The detail page gets the same two actions below the article. Replace the contents of `templates/entry/show.html.twig` with the following:

```html
{% extends 'base.html.twig' %}

{% block title %}{{ entry.title }} - Catatku{% endblock %}

{% block body %}
    <div class="mb-6">
        <a href="{{ path('entry_index') }}" class="text-sm text-gray-400 hover:text-gray-700">← Back to list</a>
    </div>

    <article class="bg-white rounded-xl border border-gray-200 p-6">
        <div class="mb-6">
            <h1 class="text-2xl font-bold text-gray-900 mb-2">{{ entry.title }}</h1>
            <p class="text-sm text-gray-400">
                Written on {{ entry.createdAt|date('d F Y') }}
                {% if entry.updatedAt and entry.updatedAt != entry.createdAt %}
                    · Updated {{ entry.updatedAt|date('d F Y') }}
                {% endif %}
            </p>
        </div>
        <div class="prose prose-gray max-w-none text-gray-700 leading-relaxed whitespace-pre-line">
            {{ entry.content }}
        </div>
    </article>

    <div class="flex items-center gap-3 mt-4">
        <a href="{{ path('entry_edit', {id: entry.id}) }}" class="text-sm bg-gray-900 text-white px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">Edit Entry</a>
        <form method="POST" action="{{ path('entry_delete', {id: entry.id}) }}" onsubmit="return confirm('Delete this entry?')">
            <input type="hidden" name="_csrf_token" value="{{ csrf_token('delete-entry-' ~ entry.id) }}">
            <button type="submit" class="text-sm text-red-500 hover:text-red-700 transition-colors">Delete</button>
        </form>
    </div>
{% endblock %}
```

The delete form here uses the same `'delete-entry-' ~ entry.id` intention as the listing, so the same `delete()` method in the controller can verify tokens from both pages.

---

## 4. Test Edit and Delete

Verify all routes are registered before testing:

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
  entry_index                GET      /entries
  entry_show                 ANY      /entries/{id}
  dev_login                  ANY      /dev-login
  entry_create               ANY      /entries/create
  entry_store                POST     /entries
  entry_edit                 ANY      /entries/{id}/edit
  entry_update               POST     /entries/{id}/update
  entry_delete               POST     /entries/{id}/delete
  home                       ANY      /
 -------------------------- -------- -----------------------------------
```

You should see `entry_edit`, `entry_update`, and `entry_delete` in the list alongside the existing routes. Notice the `Method` column: `entry_update` and `entry_delete` only accept `POST`.

Then test the full flow in the browser:

1. Visit `http://localhost:8080/dev-login` if you are not logged in.
2. Click Edit on any entry, clear the title, and click "Save Changes". The form shows "The title field is required." and keeps your content.
3. Fill in a new title and save. You land on the detail page with the message "Entry updated successfully." and an "Updated" date next to "Written on".
4. Click Delete on the detail page and confirm. You are redirected to the listing with "Entry deleted successfully.", and the entry is gone.
5. Open `http://localhost:8080/entries/1/delete` directly in the address bar. Because a browser address bar sends a GET request, Symfony answers `405 Method Not Allowed` and nothing is deleted.

---

## 5. Fix the Errors in Your Code

**Error 1: Calling persist() on an already-tracked entity.**

A common misconception is that you need to call `persist()` before every `flush()`, even for updates.

```php
// Wrong: unnecessary persist() on a tracked entity
$entry->setTitle($title);
$entityManager->persist($entry);
$entityManager->flush();

// Correct: tracked entities only need flush()
$entry->setTitle($title);
$entityManager->flush();
```

When Doctrine fetches an entity from the database (which happens automatically via the entity value resolver here), that entity is already in a "managed" state. Doctrine tracks every change made to a managed entity. Calling `flush()` generates the UPDATE SQL for any changed properties. Calling `persist()` on an already-managed entity is harmless but unnecessary and misleading. Reserve `persist()` for brand-new entities that Doctrine does not yet know about.

**Error 2: Forgetting to set updatedAt before flushing.**

If you modify an entry's content without calling `setUpdatedAt()`, the detail page shows no "Updated" date even though the entry was changed.

```php
// Wrong: no updatedAt timestamp set
$entry->setTitle($title);
$entry->setContent($content);
$entityManager->flush();

// Correct: always update the timestamp when editing
$entry->setTitle($title);
$entry->setContent($content);
$entry->setUpdatedAt(new \DateTimeImmutable());
$entityManager->flush();
```

Doctrine does not automatically manage timestamp fields. `updatedAt` is just a regular column. If you want it to reflect the most recent edit time, you must set it explicitly before every save. After `flush()`, the detail page's `{% if entry.updatedAt %}` check will display the updated date.

**Error 3: Delete route accepting GET requests.**

If the delete route accepts GET requests, any HTTP link on an external page can trigger a deletion when a logged-in user clicks it.

```php
// Wrong: accepts GET, can be triggered by a link
#[Route('/entries/{id}/delete', name: 'entry_delete')]

// Correct: restrict to POST only
#[Route('/entries/{id}/delete', name: 'entry_delete', methods: ['POST'])]
```

Destructive actions (delete, and also update) must only be triggered by a POST or DELETE HTTP method, never by GET. HTML forms support GET and POST. A form with `method="POST"` is the standard way to trigger a destructive action. The CSRF token adds a second layer: even if someone crafted a POST request, they would need a valid CSRF token to pass the validation check.

---

## 6. Exercises

**Exercise 1:** Right now, if you try to edit an entry that belongs to a different user, you get a 403 error. Verify this: add a second user (Siti) to the fixtures as in Lesson 6, Exercise 2, and reload them. Temporarily change the email in `devLogin()` to `siti@example.com`, visit `/dev-login`, then navigate directly to the edit URL of one of Budi's entries. Confirm you see a 403. Explain why this protection is important, then change the email in `devLogin()` back to `budi@example.com`.

**Exercise 2:** Add a confirmation message to the delete button that includes the entry title. Instead of the generic browser `confirm('Delete this entry?')`, display a message like "Delete 'Year-end vacation plans'?" using Twig's string concatenation. Update the relevant template.

**Exercise 3:** The `update()` method currently validates that title is under 255 characters and content is not empty. Add a third rule: content must be at least 10 characters. Test it with a very short content and verify the error appears below the content field.

---

## 7. Solutions

**Solution for Exercise 1:**

This behavior is intentional and critical for user privacy. Without the ownership check in every method, a logged-in user could construct a URL like `/entries/3/edit` and modify another user's entry, even though the listing page never shows it to them. Security that only hides data at the presentation layer (in Twig templates) is insufficient. The ownership check in the controller is the authoritative guard.

**Solution for Exercise 2:**

Update the delete form's `onsubmit` attribute in `show.html.twig`. Replace the opening `<form>` tag of the delete form with this line:

```html
<form method="POST" action="{{ path('entry_delete', {id: entry.id}) }}" onsubmit="return confirm('Delete \'{{ entry.title|e('js') }}\'?')">
```

`\'` is an escaped single quote inside the JavaScript string, so the dialog shows the title wrapped in quotes, for example `Delete 'My first entry'?`.

The `|e('js')` filter escapes the title for safe inclusion in a JavaScript string context, preventing XSS if the title contains quotes or special characters. For a title like `Budi's "big" day`, the rendered attribute becomes `onsubmit="return confirm('Delete \'Budi\u0027s\u0020\u0022big\u0022\u0020day\'?')"`. Every quote and space is turned into a `\uXXXX` code that JavaScript decodes back into the original character, so the title can never close the string early.

**Solution for Exercise 3:**

Add an `elseif` branch to the content check. Replace the whole `update()` method with this version:

```php
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
    } elseif (strlen($content) < 10) {
        $errors['content'] = 'The content must be at least 10 characters.';
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
```

The validation logic in `update()` is intentionally a copy of the validation in `store()`. Both methods receive user input for the same fields and need the same rules. In a production application, you would extract this validation into a shared private method or use Symfony's Form component with Constraints to avoid duplication. For this course, keeping each method self-contained makes the logic easier to follow.

---

## Next Up - Lesson 10

In this lesson, you completed the full CRUD cycle. You built the edit form pre-filled with existing entity data, implemented updates using Doctrine's change tracking pattern (modify the entity, call `flush()`, no `persist()` needed), and handled deletions with per-entry CSRF tokens to prevent unauthorized removal.

In Lesson 10, you will replace the temporary `/dev-login` shortcut with a real login form powered by Symfony's `form_login` authenticator, add logout, and scope the entries listing to the logged-in user.