The previous lessons brought us quite far. The `Entry` model is connected to the database, the relationship to `User` is defined, and the controller can fetch real data. But if you open the application right now, what you see still feels raw: a messy HTML structure, no consistent navigation, and every new page we create in the future would force us to repeat the same boilerplate from scratch.

This lesson fixes that.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the application will have two fully working pages: an entries listing and an entry detail page. Both will share the same layout with consistent navigation, flash message support, and a clean visual structure. This is a significant visual leap compared to what we have right now.

### What You'll Learn

- How to create a reusable layout using Blade components and the `{{ $slot }}` mechanism
- How to extract repeated UI elements into standalone components like `EntryCard`
- How to use the `@props` directive to pass data into components
- How to build an entry detail page with a `show()` controller method
- What Route Model Binding is and how it automatically converts URL parameters into Eloquent objects
- How to protect a page so only the entry owner can access it using `abort(403)`
- Blade directives for conditional display: `@auth`, `@else`, `@endauth`

### What You'll Need

- The `catatku` project open in VS Code with the development server running
- The controller connected to the database and the entries listing view from previous lessons
- Seed data inserted via Tinker from Lesson 6 so you have entries to display

---

## Step 1: Create the Main Layout {#step-1-create-the-main-layout}

Right now, `entries/index.blade.php` mixes everything together: the full HTML structure, navigation, and the entries listing logic. When we create the detail page, the create form, and the login page later, all of them will need the same navigation. We would end up copying and pasting the same HTML over and over.

**Blade components** solve this problem by letting us break HTML into reusable pieces. The most important piece is the layout: a wrapper that provides the HTML skeleton, navigation, and common elements, while leaving a "hole" for each page to fill with its own content.

Create the file `resources/views/components/layout.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Catatku' }}</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50 min-h-screen">

    {{-- Navigation --}}
    <nav class="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div class="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
            <a href="/entries" class="text-xl font-bold text-gray-900 hover:text-gray-700">
                Catatku 📓
            </a>
            <div class="flex items-center gap-4">
                @auth
                    <span class="text-sm text-gray-500">{{ auth()->user()->name }}</span>
                    <form method="POST" action="/logout">
                        @csrf
                        <button type="submit"
                            class="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                            Logout
                        </button>
                    </form>
                @else
                    <a href="/login" class="text-sm text-gray-600 hover:text-gray-900">Log In</a>
                    <a href="/register"
                        class="text-sm bg-gray-900 text-white px-3 py-1.5 rounded-lg hover:bg-gray-700 transition-colors">
                        Register
                    </a>
                @endauth
            </div>
        </div>
    </nav>

    {{-- Page content --}}
    <main class="max-w-2xl mx-auto px-4 py-8">

        {{-- Flash success message --}}
        @if (session('success'))
            <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-800 text-sm rounded-xl">
                {{ session('success') }}
            </div>
        @endif

        {{ $slot }}
    </main>

</body>
</html>
```

There are several important pieces in this layout:

`{{ $title ?? 'Catatku' }}` is the page title. The `??` is PHP's null coalescing operator. If a page passes a `title` value, it gets used. Otherwise, it falls back to "Catatku". This lets each page customize its browser tab title.

`@auth ... @else ... @endauth` is a Blade directive that checks the user's login status. The `@auth` block renders when the user is logged in (showing their name and a logout button). The `@else` block renders when they are not (showing login and register links). Since we have not built authentication yet, you will always see the `@else` block for now.

`@if (session('success'))` checks for flash messages in the session. After saving, updating, or deleting an entry, we will redirect with a success message. This block displays that message at the top of the page. We will put this to use starting in the next lesson.

`{{ $slot }}` is the most important part. This is the "hole" where content from the page using this layout gets inserted. When a view wraps its content in `<x-layout>...</x-layout>`, everything between those tags becomes the value of `$slot`.

---

## Step 2: Create the EntryCard Component {#step-2-create-the-entrycard-component}

Each entry in the listing is rendered as a card with a title, date, content snippet, and action buttons. Instead of putting all that HTML directly in the listing view, we will extract it into its own component. This way, if we ever need to change how an entry card looks, we change it in one place.

Create the file `resources/views/components/entry-card.blade.php`:

```html
@props(['entry'])

<div class="bg-white rounded-xl border border-gray-200 p-5 hover:border-gray-300 transition-colors">

    {{-- Header: title and date --}}
    <div class="flex items-start justify-between gap-3 mb-3">
        <a href="/entries/{{ $entry->id }}"
           class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
            {{ $entry->title }}
        </a>
        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    {{-- Content snippet --}}
    <p class="text-sm text-gray-500 line-clamp-2 mb-4">
        {{ $entry->content }}
    </p>

    {{-- Action buttons --}}
    <div class="flex items-center gap-3 pt-3 border-t border-gray-100">
        <a href="/entries/{{ $entry->id }}"
           class="text-xs text-blue-600 hover:text-blue-800">
            Read
        </a>
        <a href="/entries/{{ $entry->id }}/edit"
           class="text-xs text-gray-500 hover:text-gray-800">
            Edit
        </a>
        <form method="POST" action="/entries/{{ $entry->id }}"
              onsubmit="return confirm('Delete this entry?')"
              class="ml-auto">
            @csrf
            @method('DELETE')
            <button type="submit" class="text-xs text-red-400 hover:text-red-600">
                Delete
            </button>
        </form>
    </div>

</div>
```

`@props(['entry'])` declares that this component requires an `entry` prop. When we use the component, we will pass the entry like this: `<x-entry-card :entry="$entry" />`. The colon before `entry` tells Blade to evaluate the value as a PHP expression rather than treating it as a plain string.

The card includes links to the detail page (`/entries/{{ $entry->id }}`), the edit page, and a delete form. The edit and delete functionality will not work yet because we have not built those routes, but the UI is already in place. The delete form uses `@method('DELETE')` because HTML forms only support GET and POST natively. This Blade directive adds a hidden field that tells Laravel to treat the form submission as a DELETE request.

---

## Step 3: Update the Entries Listing View {#step-3-update-the-entries-listing-view}

Now update `resources/views/entries/index.blade.php` to use the layout and the entry card component:

```html
<x-layout title="My Entries — Catatku">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
        <a href="/entries/create"
           class="bg-gray-900 text-white text-sm px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">
            + Write New Entry
        </a>
    </div>

    <div class="space-y-4">
        @forelse ($entries as $entry)
            <x-entry-card :entry="$entry" />
        @empty
            <div class="text-center py-16">
                <p class="text-5xl mb-4">📓</p>
                <p class="font-medium text-gray-600">No entries yet</p>
                <p class="text-sm text-gray-400 mt-1">
                    Start writing your first entry!
                </p>
                <a href="/entries/create"
                   class="inline-block mt-4 text-sm text-blue-600 hover:underline">
                    Write now →
                </a>
            </div>
        @endforelse
    </div>

</x-layout>
```

Compare this to the previous version. The entire HTML document structure, the `<head>` section, and the navigation are all gone. They now live in the layout component. This view only contains the content that is unique to the entries listing page.

`<x-layout title="My Entries — Catatku">` wraps the page content in the layout component and passes a custom title for the browser tab. Everything between `<x-layout>` and `</x-layout>` becomes the `{{ $slot }}` in the layout.

`<x-entry-card :entry="$entry" />` renders one entry card for each entry in the collection. The entire card HTML is handled by the component, keeping this view focused on the page-level structure.

---

## Step 4: Add the Entry Detail Page {#step-4-add-the-entry-detail-page}

Users need to be able to read a full entry. This requires three things: a controller method, a route, and a view.

First, add the `show()` method to `EntryController`:

```php
public function show(Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    return view('entries.show', compact('entry'));
}
```

There are two important concepts in this short method.

**Route Model Binding** is what makes the `Entry $entry` parameter work. When Laravel sees a type-hinted parameter in a controller method, it automatically looks up the corresponding database record using the value from the URL. If someone visits `/entries/5`, Laravel runs `Entry::findOrFail(5)` behind the scenes and injects the result as `$entry`. If no entry with that ID exists, Laravel automatically returns a 404 error. You do not need to write any lookup code yourself.

**`abort(403)`** stops execution and returns a "Forbidden" error. The `if` check ensures that only the entry owner can view their entry. If `$entry->user_id` does not match the currently authenticated user's ID, the request is blocked.

> **Note:** Since the authentication system is not built yet, unauthenticated visitors who access an entry detail URL directly will see a 403 error (because `auth()->id()` returns `null`, which never matches a `user_id`). This is not ideal. In Lesson 8, we will move this route inside the `middleware('auth')` group, which will redirect guests to the login page instead of showing a 403. For now, the ownership check itself is correct.

Next, add the route in `routes/web.php`. Place it after the existing `/entries` route:

```php
Route::get('/entries', [EntryController::class, 'index']);
Route::get('/entries/{entry}', [EntryController::class, 'show']);
```

The `{entry}` segment in the URL is a route parameter. It tells Laravel that this part of the URL is dynamic. When someone visits `/entries/3`, the value `3` gets passed to the `show()` method, where Route Model Binding converts it into an `Entry` object.

Finally, create the view at `resources/views/entries/show.blade.php`:

```html
<x-layout :title="$entry->title . ' — Catatku'">

    <div class="mb-6">
        <a href="/entries" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to list
        </a>
    </div>

    <article class="bg-white rounded-xl border border-gray-200 p-6">

        {{-- Header --}}
        <div class="mb-6">
            <h1 class="text-2xl font-bold text-gray-900 mb-2">
                {{ $entry->title }}
            </h1>
            <p class="text-sm text-gray-400">
                Written on {{ $entry->created_at->isoFormat('D MMMM Y') }}
                @if ($entry->updated_at->ne($entry->created_at))
                    · Updated {{ $entry->updated_at->diffForHumans() }}
                @endif
            </p>
        </div>

        {{-- Entry content --}}
        <div class="prose prose-gray max-w-none text-gray-700 leading-relaxed whitespace-pre-line">
            {{ $entry->content }}
        </div>

    </article>

    {{-- Action buttons --}}
    <div class="flex items-center gap-3 mt-4">
        <a href="/entries/{{ $entry->id }}/edit"
           class="text-sm bg-gray-900 text-white px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">
            Edit Entry
        </a>
        <form method="POST" action="/entries/{{ $entry->id }}"
              onsubmit="return confirm('Delete this entry?')">
            @csrf
            @method('DELETE')
            <button type="submit"
                class="text-sm text-red-500 hover:text-red-700 transition-colors">
                Delete
            </button>
        </form>
    </div>

</x-layout>
```

A few things worth noting in this template:

`:title="$entry->title . ' — Catatku'"` passes the page title as a PHP expression (note the colon prefix). This sets the browser tab to something like "My first entry - Catatku", which is more descriptive than a generic title.

`$entry->created_at->isoFormat('D MMMM Y')` uses Carbon's `isoFormat()` method, which produces locale-aware date output like "20 February 2026".

`$entry->updated_at->ne($entry->created_at)` checks if the entry has been edited after it was first created. The `ne()` method (short for "not equal") compares two Carbon dates. If they differ, the template shows "Updated 2 hours ago" (or however long ago the edit was). The `diffForHumans()` method produces human-readable relative time strings automatically.

`whitespace-pre-line` is a Tailwind CSS class that preserves line breaks in text. Without it, newline characters (`\n`) in the content would be ignored by HTML, and multi-paragraph entries would appear as a single block of text.

---

## Step 5: View the Result {#step-5-view-the-result}

Make sure the development server is running, then open `http://127.0.0.1:8000/entries` in your browser.

![entries page after implement layout](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/06-implement-layout.webp)

You should see the listing page with the new layout: a sticky navigation bar at the top, entry cards with action buttons, and a clean visual structure. The seed data you inserted in Lesson 6 should be displayed as entry cards. Clicking the "Read" link or the entry title on any card takes you to the detail page for that entry.
![error 403 when access entry detail  page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/07-error-403.webp)
Since we haven't logged in yet, clicking the “Read” button will result in a 403 Forbidden error.

Both pages share the same layout component, so the navigation, page width, and overall feel are consistent across the application.

---

## How Blade Components Work {#how-blade-components-work}

Now that you have built and used several Blade components, let us understand the mechanism behind them.

Any `.blade.php` file inside `resources/views/components/` automatically becomes a Blade component. The file name determines the tag name: `layout.blade.php` becomes `<x-layout>`, and `entry-card.blade.php` becomes `<x-entry-card>`. The `x-` prefix is how Blade identifies component tags.

Components receive data in two ways. **Slots** are the content placed between the opening and closing tags. Whatever you write between `<x-layout>` and `</x-layout>` becomes `{{ $slot }}` inside the component. **Props** are named attributes you pass to the component, like `:entry="$entry"` on `<x-entry-card>`. The `@props` directive at the top of a component declares which props it accepts.

The colon prefix on attributes matters. Without a colon (`title="My Page"`), the value is treated as a literal string. With a colon (`:title="$entry->title"`), the value is evaluated as a PHP expression. This is how you pass variables and dynamic values to components.

---

## How Route Model Binding Works {#how-route-model-binding-works}

Route Model Binding is one of Laravel's most convenient features. When you type-hint a controller parameter with an Eloquent model class, Laravel automatically resolves the route parameter into a model instance.

The route `Route::get('/entries/{entry}', ...)` defines a parameter called `{entry}`. The controller method `show(Entry $entry)` type-hints that parameter as an `Entry` model. Laravel connects these two: it takes the value from the URL (for example, `5`), runs `Entry::findOrFail(5)`, and passes the result to your method.

If the record does not exist, `findOrFail` throws a `ModelNotFoundException`, which Laravel converts into a 404 response automatically. You do not need to write any "record not found" logic yourself.

The parameter name in the route (`{entry}`) must match the variable name in the method signature (`$entry`) for this binding to work.

---

## Conclusion {#conclusion}

This lesson changed how we build views in a significant way. Here are the key takeaways:

- **Blade components** let you extract reusable HTML into separate files. Any file in `resources/views/components/` becomes a component automatically.
- The **layout component** (`<x-layout>`) provides the HTML skeleton, navigation, and flash message support. Every page uses it, so changes to the layout propagate everywhere instantly.
- `{{ $slot }}` is the placeholder inside a component where the caller's content gets inserted. Everything between `<x-layout>` and `</x-layout>` becomes the slot.
- `@props(['entry'])` declares required props for a component. Props are passed using attributes like `:entry="$entry"`, where the colon prefix means the value is a PHP expression.
- The **EntryCard component** (`<x-entry-card>`) encapsulates the display logic for a single entry, keeping the listing view focused on page structure.
- **Route Model Binding** (`Entry $entry`) automatically converts URL parameters into Eloquent objects. If the record is not found, Laravel returns a 404.
- `abort(403)` stops execution and returns a "Forbidden" response, providing a simple way to block unauthorized access. Currently, unauthenticated visitors see a 403 error. This will improve to a login redirect once we add the `auth` middleware in the next lesson.
- `@method('DELETE')` adds a hidden form field that tells Laravel to treat a POST submission as a DELETE request, since HTML forms only support GET and POST.
- Carbon methods like `isoFormat()`, `diffForHumans()`, and `ne()` make date display and comparison straightforward without manual formatting logic.
- The `whitespace-pre-line` CSS class preserves line breaks in text content, which is essential for displaying multi-paragraph entries correctly.

In the next lesson, we will build the form for creating new entries. You will learn how to display a form, validate user input, save data to the database, and redirect with a success message. This is where Catatku truly starts to come alive.