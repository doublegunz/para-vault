## 1. Before You Begin

The previous lessons brought us far. The entity is connected to the database, the repository fetches real data, and entries appear in the browser. But the views still feel raw: no consistent navigation bar, and every new page would require duplicating the same HTML head section. This lesson fixes both problems.

Most web applications have a consistent shell: a navigation bar, a footer, and a content area that changes per page. Duplicating this HTML in every template is fragile. Change one thing (like a page title or a nav link) and you have to update every file.

Twig solves this with **template inheritance**. You define a single base layout once. Every other template extends it and fills in only the parts that change. This lesson introduces that pattern, applies it to the entries listing, and adds a new entry detail page that uses route parameters to fetch a specific entry from the database.

### What You'll Build

By the end of this lesson, Catatku will have two polished pages that share the same base layout: the entries listing and an entry detail page. Both pages use real database data and include proper navigation.

### What You'll Learn

- ✅ How to create a reusable base layout using Twig's `extends` and `block` tags
- ✅ How to update existing templates to inherit from the base layout
- ✅ How to build a detail page using route parameters
- ✅ How Symfony automatically converts route parameters to entities with the entity value resolver

### What You'll Need

- The controller connected to the database and seed data from Lesson 6
- Three seed entries loaded via `php bin/console doctrine:fixtures:load`

---

## 2. Creating the Base Layout

A base layout is a Twig template that defines the overall page structure. Child templates inherit from it and fill in named "blocks" with their own content.

### Step 1: Replace base.html.twig

The `webapp` package already created a starter `templates/base.html.twig` when you installed it in Lesson 2. Replace its entire contents with the following:

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

`{% block title %}Catatku{% endblock %}` defines a named block with a default value. Any child template can override this block to set a custom page title. If a child template does not override it, the default "Catatku" is used.

`{% block body %}{% endblock %}` is the main content placeholder. Every child template fills this block with its own page-specific content.

`{{ path('entry_index') }}` generates a URL from a route name. This is the correct way to generate links in Symfony. If you later change the `/entries` path to `/journal`, only the `#[Route]` attribute needs updating. All `path()` calls throughout the application will automatically produce the new URL.

`{% for message in app.flashes('success') %}` displays one-time flash messages. Flash messages are stored in the session and automatically cleared after being displayed once. When a user creates, edits, or deletes an entry, a success message is stored with `$this->addFlash()` in the controller and displayed here on the next page load.

The empty `<div>` on the right side of the navigation bar is reserved for the Log In, Register, and Logout links. Those routes do not exist yet, and `path()` throws an error for a route name that does not exist, so you will add the Log In and Logout links in Lesson 10 together with the login system, and the Register link in Lesson 11.

The starter file you replaced also loaded `importmap('app')`, which pulls in Symfony's JavaScript (including Turbo, a library that turns links and form submissions into background requests). Catatku does not need it, so the new layout only loads Tailwind. This keeps every form in the course behaving like a plain HTML form.

---

## 3. Updating the Entries Listing

With the base layout in place, update the entries listing template to inherit from it instead of duplicating the HTML structure.

### Step 1: Replace the Entry Index Template

Replace all content in `templates/entry/index.html.twig`:

```html
{% extends 'base.html.twig' %}

{% block title %}My Entries - Catatku{% endblock %}

{% block body %}
    <div class="mb-6">
        <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
    </div>

    <div class="space-y-4">
        {% if entries is empty %}
            <div class="text-center py-16">
                <p class="text-5xl mb-4">📓</p>
                <p class="font-medium text-gray-600">No entries yet</p>
                <p class="text-sm text-gray-400 mt-1">Start writing your first entry!</p>
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

`{% extends 'base.html.twig' %}` must be the very first tag in a child template. It tells Twig which parent layout to use. The child template only defines the blocks it wants to override. Everything else comes from the parent.

`{{ path('entry_show', {id: entry.id}) }}` generates a URL with a route parameter. The second argument is an object literal in Twig that maps parameter names to values. Symfony's router uses this to build the correct URL, such as `/entries/3`.

Each card has a "Read" link for now. The "Write New Entry" button arrives in Lesson 8, and the Edit and Delete buttons in Lesson 9, at the same moment their routes are created.

---

## 4. Building the Entry Detail Page

The detail page displays a single entry in full. It introduces two new Symfony concepts: route parameters and the entity value resolver.

### Step 1: Add the show() Method to EntryController

Open `src/Controller/EntryController.php`, import the `Entry` class, and add a `show()` method. The complete file now looks like this:

```php
<?php

namespace App\Controller;

use App\Entity\Entry;
use App\Repository\EntryRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

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
        return $this->render('entry/show.html.twig', [
            'entry' => $entry,
        ]);
    }
}
```

`{id}` in the route path is a route parameter. When someone visits `/entries/3`, Symfony extracts `3` as the value of `{id}`.

`requirements: ['id' => '\d+']` restricts the parameter to numeric values only. Without this, the route would match any string in that position, including `/entries/create`, which would conflict with the create route.

`Entry $entry` in the method signature triggers the **entity value resolver** (older tutorials call this feature ParamConverter). Symfony sees a route parameter named `{id}` and a method argument typed `Entry`. It automatically runs `$entryRepository->find($id)` and injects the result. If no entry exists with that ID, Symfony automatically returns a 404 response. You do not need to write the lookup yourself.

Right now anyone can open any entry, because there is no way to log in yet. In Lesson 8, once you can log in, you will add an ownership check to this method so that a user can only read their own entries.

### Step 2: Create the Detail Template

Create the file `templates/entry/show.html.twig`. The Edit and Delete buttons will be added below the article in Lesson 9.

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

{% endblock %}
```

`{% if entry.updatedAt and entry.updatedAt != entry.createdAt %}` conditionally shows the updated date. Because `updatedAt` is nullable (it is `NULL` until the entry is edited), this check prevents displaying a null date for new entries. The second condition `entry.updatedAt != entry.createdAt` prevents showing "Updated" if the edit happened on the same second as creation.

### Step 3: View the Result

Open `http://localhost:8080/entries` and click "Read" on any entry to see the full detail page. Both pages now share the same layout, navigation, and flash message area.

You can also check the routes from the terminal. The detail route shows its `{id}` parameter in the path:

```bash
php bin/console debug:router entry_show
```

Output:

```text
+--------------+---------------------------------------------------------+
| Property     | Value                                                   |
+--------------+---------------------------------------------------------+
| Route Name   | entry_show                                              |
| Path         | /entries/{id}                                           |
| Path Regex   | {^/entries/(?P<id>\d+)$}sDu                             |
| Host         | ANY                                                     |
| Host Regex   |                                                         |
| Scheme       | ANY                                                     |
| Method       | ANY                                                     |
| Requirements | id: \d+                                                 |
| Class        | Symfony\Component\Routing\Route                         |
| Defaults     | _controller: App\Controller\EntryController::show()     |
| Options      | compiler_class: Symfony\Component\Routing\RouteCompiler |
|              | utf8: true                                              |
+--------------+---------------------------------------------------------+
```

The `Requirements` row confirms that `{id}` only accepts digits, and the `Defaults` row shows the controller method that handles the route.


---

## 5. How Twig Template Inheritance Works

Template inheritance uses three concepts working together. Understanding each one separately makes the pattern much clearer.

`{% extends 'base.html.twig' %}` declares the parent template. This tag must appear as the very first thing in the child template file.

`{% block name %}...{% endblock %}` in the parent defines a named placeholder. The child template uses the exact same tag to fill that placeholder with its own content. The name must match exactly.

`{{ parent() }}` inside a child block includes the parent block's content, allowing you to add to it rather than replace it entirely. For example, a child template can add extra CSS to the `<head>` by calling `{{ parent() }}` first, then adding its own styles.

---

## 6. Fix the Errors in Your Code

**Error 1: Writing content outside a block in a child template.**

A child template may only contain blocks. Any HTML outside a `{% block %}` tag has nowhere to go, because the layout comes from the parent.

```twig
{# Wrong: the paragraph sits outside any block #}
<p>Entry detail</p>
{% extends 'base.html.twig' %}

{# Correct: everything visible lives inside a block #}
{% extends 'base.html.twig' %}

{% block body %}
    <p>Entry detail</p>
{% endblock %}
```

With the wrong version, opening the detail page shows Symfony's error page with this message:

```text
A template that extends another one cannot include content outside Twig blocks. Did you forget to put the content inside a {% block %} tag in "entry/show.html.twig" at line 1?
```

Twig comments (`{# ... #}`) and blank lines before `{% extends %}` are allowed, because they produce no output. Keeping `{% extends %}` as the first line is still a good habit, so anyone reading the file sees immediately which layout it uses.

**Error 2: Route parameter does not match requirements.**

When the route requires `\d+` (digits only) and a non-numeric string is passed, Symfony returns a 404 instead of calling the controller.

```php
// Wrong: allows any string, conflicts with /entries/create
#[Route('/entries/{id}', name: 'entry_show')]

// Correct: restricts to numeric IDs only
#[Route('/entries/{id}', name: 'entry_show', requirements: ['id' => '\d+'])]
```

Without the `requirements` constraint, Symfony would match `/entries/create` against the `entry_show` route, inject it as `{id}`, and pass the string `"create"` to the entity value resolver, which would fail to find an entry with that ID. The `\d+` regex ensures only numeric values match, leaving `/entries/create` free for the create route.

**Error 3: Using a route name that does not exist yet.**

`path()` needs a route that already exists. Linking to a route that will only be created in a later lesson breaks the whole page, not just the link.

```twig
{# Wrong: entry_create is only created in Lesson 8 #}
<a href="{{ path('entry_create') }}">+ Write New Entry</a>

{# Correct: link only to routes that exist, such as entry_show #}
<a href="{{ path('entry_show', {id: entry.id}) }}">Read</a>
```

With the wrong version, `/entries` returns a 500 error. The error message starts like this, followed by the template name and line number:

```text
An exception has been thrown during the rendering of a template ("Unable to generate a URL for the named route "entry_create" as such route does not exist.")
```

Run `php bin/console debug:router` whenever you are unsure whether a route name exists. That is why the buttons for creating, editing, and deleting entries are added in the lessons that create their routes.

---

## 7. Exercises

**Exercise 1:** Visit `http://localhost:8080/entries/999` where `999` is an ID that does not exist. What HTTP status code does Symfony return? Why?

**Exercise 2:** In `show.html.twig`, add a small section below the article that displays the word count of the entry's content. Use Twig's `|length` filter on the words (hint: split the content on spaces first). The output should read something like "Words: 42".

**Exercise 3:** Currently the "Back to list" link in `show.html.twig` always goes to the entries listing. Add a second back link at the bottom of the page (after the article) that also links back to the listing.

---

## 8. Solutions

**Solution for Exercise 1:**

Symfony returns a **404 Not Found** response. This is because the entity value resolver runs `$entryRepository->find(999)`, which returns `null`. When no entity is found for a type-hinted argument, the resolver throws a 404 Not Found exception. You do not need to write any `if ($entry === null)` checks in the controller. This behavior is one of the primary benefits of the entity value resolver: the controller method only runs if the entity actually exists.

**Solution for Exercise 2:**

Add a paragraph right after the closing `</article>` tag. The complete `templates/entry/show.html.twig` looks like this:

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

    <p class="text-xs text-gray-400 mt-3">
        Words: {{ entry.content|split(' ')|length }}
    </p>

{% endblock %}
```

`entry.content|split(' ')` splits the content string into an array of words using a space as the delimiter. `|length` then counts the number of elements in that array. Chaining filters in Twig is done by placing each filter after a `|` character. The result is an approximate word count (it counts whitespace-separated tokens, so punctuation attached to words is counted as part of the word).

**Solution for Exercise 3:**

Add a second link right after the closing `</article>` tag. The complete `templates/entry/show.html.twig` looks like this:

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

    <div class="mt-6 border-t border-gray-100 pt-4">
        <a href="{{ path('entry_index') }}" class="text-sm text-gray-400 hover:text-gray-700">← Back to all entries</a>
    </div>

{% endblock %}
```

`{{ path('entry_index') }}` generates the URL for the entries listing by route name. Using `path()` instead of hardcoding `/entries` ensures this link continues to work correctly even if the entries path is ever changed.

---

## Next Up - Lesson 8

In this lesson, you built a reusable base layout using Twig template inheritance, updated the entries listing to inherit from it, and added the entry detail page with route parameters and the entity value resolver.

In Lesson 8, you will build the create entry form with CSRF protection and manual validation. You will add a temporary login shortcut so you can test protected pages, give the detail page its ownership check, and let logged-in users write new journal entries from inside the application, and you will learn how the EntityManager saves new data to the database.