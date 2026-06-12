## 1. Before You Begin

Catatku's views have been styled with inline CSS for simplicity. Every `<button>` has a `style="background: #2563eb; ..."` attribute. This is fine for learning, but painful for real projects: changing the blue color requires editing every view, and the markup becomes cluttered with style rules. Tailwind CSS provides utility classes (`class="bg-blue-600 text-white"`) that keep styling concise while living in the same files as your markup. Vite is the build tool that compiles your CSS and JavaScript for production, producing optimized bundles with features like automatic reloading during development.

This lesson teaches you to set up Vite and Tailwind in Catatku, migrate from inline styles to utility classes, and configure hot reloading for instant feedback during development. Laravel 13 ships with Vite and Tailwind pre-configured in new projects, so if your project already has `vite.config.js` and `tailwind.config.js`, you mostly need to understand what is there and how to use it. By the end, your views will be cleaner, your development experience will be faster with instant reloads, and your production builds will be optimized.

### What You'll Build

You will configure Vite and Tailwind, migrate one view (the entry index) from inline styles to Tailwind classes, and set up the development workflow with `npm run dev` for hot reloading.

### What You'll Learn

- ✅ What Vite is and why we need a build tool
- ✅ Tailwind CSS utility classes
- ✅ The `@vite` Blade directive
- ✅ Running `npm run dev` and `npm run build`
- ✅ Custom Tailwind configuration
- ✅ Responsive and hover variants

### What You'll Need

- Lesson 15 completed
- Node.js 18+ installed on your machine

---

## 2. Install Vite and Tailwind

Laravel 13 ships with Vite, Tailwind CSS v4, and their integration already configured. Check your project for `package.json` and `vite.config.js`. If both exist, skip to Section 3. If either is missing, follow the two steps below.

### Step 1: Install Dependencies

First, check whether `axios` is listed in your `package.json` dependencies. Some older or default Laravel scaffolds include it, but Catatku does not use it directly. If you see it, remove it from the package list and also clear its import from `resources/js/bootstrap.js`.

Run the uninstall command to remove the package.

```bash
npm uninstall axios
```

Removing the package alone is not enough. Vite scans `resources/js/bootstrap.js` at startup and will still throw a `Failed to run dependency scan` error because that file contains an `import axios from 'axios'` line. Open `resources/js/bootstrap.js` and replace its entire content with the following.

```javascript
// No third-party imports required for Catatku.
```

The original `bootstrap.js` set axios as a global and configured the `X-Requested-With` header for AJAX requests. Catatku uses standard HTML form submissions and the Sanctum API rather than direct axios calls, so none of that setup is needed. Clearing the file prevents Vite from trying to resolve a package that no longer exists.

Then install all remaining packages.

```bash
npm install --ignore-scripts
```

This installs Vite, the `laravel-vite-plugin`, and Tailwind CSS v4 (via the `@tailwindcss/vite` plugin). Unlike Tailwind CSS v3, version 4 does not require PostCSS or a separate `tailwindcss.config.js` file. The build integration is handled entirely through the Vite plugin.

### Step 2: Confirm the CSS Entry Point

Open `resources/css/app.css`. The default content from the Laravel 13 scaffold looks like this.

```css
@import 'tailwindcss';

@source '../../vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php';
@source '../../storage/framework/views/*.php';
@source '../**/*.blade.php';
@source '../**/*.js';

@theme {
    --font-sans: 'Instrument Sans', ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji',
        'Segoe UI Symbol', 'Noto Color Emoji';
}
```

Let us walk through each section. The `@import 'tailwindcss'` line replaces the three `@tailwind base/components/utilities` directives from Tailwind v3: one import is all Tailwind v4 needs. The `@source` directives tell Tailwind exactly which file paths to scan for class names; Tailwind generates CSS only for classes it actually finds in those files, which is how it produces tiny production bundles. The Pagination vendor path ensures paginator link styles are generated even though those files live outside `resources/`. The `@theme` block defines CSS custom properties that Tailwind maps to utility classes automatically.

To add brand colors for Catatku, extend the existing `@theme` block with color tokens. Open `resources/css/app.css` and add the four `--color-brand-*` lines inside the `@theme` block.

```css
@import 'tailwindcss';

@source '../../vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php';
@source '../../storage/framework/views/*.php';
@source '../**/*.blade.php';
@source '../**/*.js';

@theme {
    --font-sans: 'Instrument Sans', ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji',
        'Segoe UI Symbol', 'Noto Color Emoji';

    --color-brand-50: #eff6ff;
    --color-brand-500: #3b82f6;
    --color-brand-600: #2563eb;
    --color-brand-700: #1d4ed8;
}
```

Each `--color-brand-*` custom property is automatically mapped to utility classes: `--color-brand-600` becomes available as `bg-brand-600`, `text-brand-600`, `border-brand-600`, and every other color utility variant. No JavaScript configuration file is needed.

### Step 3: Confirm the Vite Configuration

Open `vite.config.js` and confirm it matches the following.

```javascript
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
        tailwindcss(),
    ],
    server: {
        watch: {
            ignored: ['**/storage/framework/views/**'],
        },
    },
});
```

The two plugins work together in a specific way. The `laravel` plugin integrates Vite with Laravel's asset versioning and the `@vite()` Blade directive, and the `refresh: true` option makes the browser reload automatically when Blade files change. The `tailwindcss()` plugin from `@tailwindcss/vite` handles all Tailwind CSS processing directly inside Vite without needing PostCSS. The `server.watch.ignored` rule prevents Vite from watching Laravel's compiled view cache, which would cause unnecessary rebuilds.

---

## 3. Include Vite in Your Layout

The layout file `resources/views/components/layout.blade.php` currently loads Tailwind CSS from a CDN using a `<script>` tag. Replace that single line with the `@vite()` Blade directive so the layout uses your locally compiled assets instead.

In the `<head>` section, find and replace this line:

```
<script src="https://unpkg.com/@tailwindcss/browser@4"></script>
```

Replace it with:

```
@vite(['resources/css/app.css', 'resources/js/app.js'])
```

The `@vite([...])` directive does two different things depending on the current environment. In development mode (when `npm run dev` is running), it generates `<link>` and `<script>` tags pointing to Vite's local dev server at `http://localhost:5173`, which enables hot module replacement and instant browser refresh on file save. In production mode (after `npm run build`), it reads `public/build/manifest.json` to find the content-hashed filenames of your compiled assets and generates the appropriate tags pointing to those static files. You write one directive and both modes work automatically.

After the change, the full `layout.blade.php` looks like this:

```blade
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Catatku' }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>

<body class="bg-gray-50 min-h-screen">

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
                    <button type="submit" class="text-sm text-gray-500 hover:text-gray-900 transition-colors">
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

    <main class="max-w-2xl mx-auto px-4 py-8">

        @if (session('success'))
            <x-alert type="success">
                {{ session('success') }}
            </x-alert>
        @endif

        @if (session('error'))
            <x-alert type="error">
                {{ session('error') }}
            </x-alert>
        @endif

        {{ $slot }}
    </main>

</body>

</html>
```

---

## 4. Migrate a View to Tailwind

With Vite now supplying the CSS, the next step is to update the views so they take full advantage of it. This section migrates the entry index view and the entry card component from inline styles to Tailwind utility classes.

### Step 1: Update the Entry Index View

Open `resources/views/entries/index.blade.php` and replace its content with the following.

```
<x-layout title="My Entries — Catatku">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
        <a href="{{ route('entries.create') }}"
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
                <p class="text-sm text-gray-400 mt-1">Start writing your first entry!</p>
                <a href="{{ route('entries.create') }}" class="inline-block mt-4 text-sm text-blue-600 hover:underline">
                    Write now →
                </a>
            </div>
        @endforelse
    </div>

    <div class="mt-6">
        {{ $entries->links() }}
    </div>

</x-layout>
```

The `title="My Entries — Catatku"` prop passes the page title to the layout component, which uses it in the `<title>{{ $title ?? 'Catatku' }}</title>` tag. The `@forelse` directive handles both cases in one block: when entries exist it renders the loop, and when the list is empty it shows the centered empty-state prompt. The `space-y-4` utility on the container div adds consistent vertical spacing between entry cards without needing a `mb-4` class on each card component. The `{{ $entries->links() }}` call renders pagination controls at the bottom; this works because the `index()` method in `EntryController` uses `paginate(15)` rather than `get()`.

### Step 2: Update the Entry Card Component

Open `resources/views/components/entry-card.blade.php` and replace all inline styles with Tailwind classes. This update preserves the Read, Edit, and Delete action buttons from the previous lesson.

```
<div class="bg-white rounded-xl border border-gray-200 p-4 hover:border-gray-300 transition-colors">

    <div class="flex items-start justify-between gap-3 mb-3">
        <a href="{{ route('entries.show', $entry) }}"
            class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
            {{ $truncatedTitle() }}
        </a>
        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    <p class="text-sm text-gray-500 line-clamp-2 mb-2">
        {{ $entry->excerpt }}
    </p>

    <span class="text-xs text-gray-400">
        {{ $entry->reading_time }} min read
    </span>

    @if($entry->tags->isNotEmpty())
        <div class="mt-2 flex flex-wrap gap-1">
            @foreach($entry->tags as $tag)
                <span class="bg-blue-100 text-blue-800 text-xs px-2 py-0.5 rounded-full font-semibold">
                    {{ $tag->name }}
                </span>
            @endforeach
        </div>
    @endif

    <div class="flex items-center gap-3 pt-3 border-t border-gray-100 mt-3">
        <a href="{{ route('entries.show', $entry) }}" class="text-xs text-blue-600 hover:text-blue-800">
            Read
        </a>
        @can('update', $entry)
            <a href="{{ route('entries.edit', $entry) }}" class="text-xs text-amber-500 hover:text-amber-700">
                Edit
            </a>
        @endcan
        @can('delete', $entry)
            <form method="POST" action="{{ route('entries.destroy', $entry) }}" class="inline">
                @csrf
                @method('DELETE')
                <button type="submit" onclick="return confirm('Delete this entry?')"
                    class="text-xs text-red-600 hover:text-red-800 bg-transparent border-0 cursor-pointer p-0">
                    Delete
                </button>
            </form>
        @endcan
    </div>

</div>
```

Every inline `style` attribute from lesson-15's version is now a Tailwind utility class. The `bg-white rounded-xl border border-gray-200` classes on the outer div replace the raw CSS border and background. The `hover:border-gray-300 transition-colors` pair animates the border color on hover, making the card feel interactive. The action button row at the bottom uses `@can('update', $entry)` and `@can('delete', $entry)` to show buttons only for the entry owner, which is the Policy from Lesson 5. The Delete form uses `bg-transparent border-0 cursor-pointer p-0` to strip the default button appearance without adding separate CSS reset rules.

---

## 5. Run and Test

With Vite configured and the views migrated to Tailwind, you need two processes running simultaneously: the Laravel dev server and the Vite dev server. The steps below walk through starting both, verifying hot reload works, and building for production.

### Step 1: Start the Vite Dev Server

Open a new terminal (keep `php artisan serve` running in another) and run the following command.

```bash
npm run dev
```

You should see output confirming Vite is ready.

```
VITE v5.0 ready in 300 ms
➜  Local:   http://localhost:5173/
```

Vite is now watching your files. When you edit a Blade view, CSS file, or JavaScript file, the browser updates almost instantly without a manual refresh.

### Step 2: Load the Page

Navigate to `http://localhost:8000/entries`. The page should render with Tailwind styling: the new header, the blue button, the gray background, and styled entry cards. If you see unstyled HTML (plain black text on white background), verify that the `@vite(...)` directive is in your layout and that both `php artisan serve` and `npm run dev` are running simultaneously.

### Step 3: Test Hot Reload

Open `resources/views/entries/index.blade.php` and change the heading class from `text-lg` to `text-xl` on the `<h2>` tag. Save the file. The browser should update almost instantly without a manual refresh, showing the slightly larger heading. This confirms the Vite hot reload feature is active, and you can revert the class back to `text-lg` after confirming.

### Step 4: Build for Production

When you are ready to test the production output, run the following.

```bash
npm run build
```

This command compiles everything into optimized bundles in the `public/build/` directory with content-hashed filenames (like `app-abc123.css`) for browser cache busting. Run this before every production deployment so the `@vite(...)` directive picks up the built files. In production, no Vite dev server runs; files are served as static assets by your web server.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when setting up Vite and Tailwind in a Laravel project.

**Error 1: Blade file paths not covered by `@source` directives in `app.css`.**

This error occurs when Tailwind cannot find class names in your Blade files because the file path is not declared in a `@source` directive. Tailwind v4 scans only the files matching the patterns listed in `@source` declarations and generates CSS only for classes it finds. If a path is missing, those classes are absent from the output and the affected pages render unstyled.

```css
/* Wrong: no @source pointing to Blade files */
@import 'tailwindcss';

/* Tailwind scans nothing — all utility classes missing from output */

/* Correct: declare @source directives covering Blade and JS files */
@import 'tailwindcss';

@source '../**/*.blade.php';
@source '../**/*.js';
```

The wrong version imports Tailwind but declares no `@source` paths, so Tailwind has no files to scan for class names. The generated CSS contains only base reset styles with no utility classes. The correct version adds `@source` declarations that cover all Blade views and JavaScript files in the `resources/` directory. After adding a missing source path, restart `npm run dev` to trigger a full rebuild.

---

**Error 2: Using dynamic class names that Tailwind cannot detect.**

This error occurs when you compose a class name by concatenating PHP variables with string fragments. Tailwind scans files as raw text and cannot evaluate PHP expressions, so a partial class name like `bg-{{ $color }}-500` is never recognized as `bg-red-500` or `bg-blue-500`.

```blade
{{-- Wrong: Tailwind cannot detect the full class name in the source text --}}
<div class="bg-{{ $color }}-500">...</div>

{{-- Correct: use complete class names in conditional expressions --}}
<div class="{{ $color === 'red' ? 'bg-red-500' : 'bg-blue-500' }}">...</div>
```

The wrong version produces `bg-red-500` at runtime, but Tailwind never saw `bg-red-500` in the source file because it only saw the fragment `bg-`. The correct version uses a ternary expression with full class names as both branches. Tailwind's scanner finds `bg-red-500` and `bg-blue-500` as complete strings in the file and generates CSS for both.

---

**Error 3: Forgetting to run `npm run build` before deploying to production.**

This error occurs when the production server does not have the built assets in `public/build/`. The `@vite(...)` directive in production mode reads the manifest file at `public/build/manifest.json` to find the correct asset filenames. If `public/build/` does not exist, Vite throws an exception on every page request.

```bash
# Wrong: deploy code without building assets first
git push origin main
# Deploy completes, but public/build/ is empty or missing
# Result: every page throws "Vite manifest not found" exception

# Correct: build assets as part of the deployment script
npm ci && npm run build
# Then deploy, so public/build/ contains the compiled files
```

The wrong version skips the build step. The `@vite(...)` directive tries to read `public/build/manifest.json`, finds the file missing, and throws an exception visible to every user. The correct version runs `npm ci` (installs locked dependencies) followed by `npm run build` before or during deployment, ensuring `public/build/` contains the compiled CSS, JavaScript, and the manifest. Add this as a step in your deploy script so it runs automatically every time.

---

## 7. Exercises

Practice migrating and extending the Tailwind setup independently using the patterns from this lesson.

**Exercise 1:** Migrate the entry show view (`resources/views/entries/show.blade.php`) to Tailwind. Replace all inline styles with utility classes, and add a cover image display section that uses `object-cover` and `rounded-lg`.

**Exercise 2:** Add a dark mode toggle. Add `dark:` variants to key classes (for example `bg-white dark:bg-gray-900`) and add a button that toggles the `dark` class on the `<html>` element using a small JavaScript snippet.

**Exercise 3:** Create a custom component class using `@layer components` in `resources/css/app.css` so that `<button class="btn-primary">` works without repeating the full set of utility classes on every button.

---

## 8. Solutions

Compare your implementations with the ones below. Focus on how `object-cover` keeps images proportional, how `@custom-variant dark` enables class-based dark mode in Tailwind v4, and why `@layer components` is appropriate for repeated utility combinations.

**Solution for Exercise 1:**

Open `resources/views/entries/show.blade.php` and replace its content with the following.

```blade
<x-layout>
    <div class="max-w-2xl mx-auto">
        @if($entry->cover_image)
            <img
                src="{{ Storage::url($entry->cover_image) }}"
                alt="Cover image"
                class="w-full h-64 object-cover rounded-lg mb-6"
            >
        @endif

        <div class="flex items-center justify-between mb-4">
            <h1 class="text-3xl font-bold text-gray-900">{{ $entry->title }}</h1>
            @can('update', $entry)
                <a href="{{ route('entries.edit', $entry) }}"
                   class="text-sm text-brand-600 hover:text-brand-700 font-medium">
                    Edit
                </a>
            @endcan
        </div>

        <div class="flex items-center gap-4 text-sm text-gray-400 mb-6">
            <span>{{ $entry->reading_time }} min read</span>
            <span>{{ $entry->created_at->diffForHumans() }}</span>
        </div>

        @if($entry->tags->isNotEmpty())
            <div class="flex flex-wrap gap-2 mb-6">
                @foreach($entry->tags as $tag)
                    <span class="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">
                        {{ $tag->name }}
                    </span>
                @endforeach
            </div>
        @endif

        <div class="text-gray-700 leading-relaxed whitespace-pre-line mb-8">
            {{ $entry->content }}
        </div>
    </div>
</x-layout>
```

The `object-cover` class on the image makes it fill the container (`w-full h-64`) without distorting the aspect ratio, cropping the edges instead. This is the correct behavior for a hero/cover image where consistent height matters more than showing the full image. The `rounded-lg` class gives it soft corners matching the card style on the index page. The `whitespace-pre-line` class on the content div preserves line breaks from the saved text so paragraphs display correctly without requiring HTML markup.

---

**Solution for Exercise 2:**

First, enable class-based dark mode by adding a `@custom-variant` directive to `resources/css/app.css`, after the `@import` line.

```css
@import 'tailwindcss';

@custom-variant dark (&:where(.dark, .dark *));
```

This is Tailwind v4's way of enabling class-based dark mode. The `@custom-variant dark` declaration tells Tailwind that the `dark:` prefix should match elements that are inside an ancestor with the `dark` class, which is what `&:where(.dark, .dark *)` expresses as a CSS selector. No configuration file changes are needed.

Open `resources/views/components/layout.blade.php` and add `dark:` variants to the key layout elements, plus a toggle button in the nav.

```blade
<body class="bg-gray-50 dark:bg-gray-900 text-gray-800 dark:text-gray-100 font-sans antialiased">
    <nav class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-4 py-3">
        <div class="max-w-4xl mx-auto flex items-center justify-between">
            <a href="/" class="text-xl font-bold text-brand-700 dark:text-brand-500">Catatku</a>
            <div class="flex items-center gap-4">
                <button
                    onclick="document.documentElement.classList.toggle('dark')"
                    class="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                >
                    Toggle Dark
                </button>
                @auth
                    <form method="POST" action="{{ route('logout') }}">
                        @csrf
                        <button type="submit" class="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white">
                            Logout
                        </button>
                    </form>
                @endauth
            </div>
        </div>
    </nav>

    <main class="max-w-4xl mx-auto p-4">
        {{ $slot }}
    </main>
</body>
```

The `@custom-variant dark` directive added to `app.css` tells Tailwind to activate `dark:` variants only when an ancestor element has the `dark` class, which is what the `&:where(.dark, .dark *)` selector specifies. The toggle button's `onclick` handler adds or removes the `dark` class on `document.documentElement` (the `<html>` tag). To persist the preference across page loads, extend the script to save the state in `localStorage` and restore it on page load. Without persistence, dark mode resets on every navigation.

---

**Solution for Exercise 3:**

Open `resources/css/app.css` and add custom component classes inside a `@layer components` block, after the existing `@import` line.

```css
@import 'tailwindcss';

@layer components {
    .btn-primary {
        @apply bg-brand-600 hover:bg-brand-700 text-white px-5 py-2 rounded-md font-semibold transition;
    }

    .btn-danger {
        @apply bg-red-600 hover:bg-red-700 text-white px-5 py-2 rounded-md font-semibold transition;
    }
}
```

The `@apply` directive lets you compose Tailwind utilities inside a custom CSS class. Now any element can use `class="btn-primary"` instead of the full string of utilities. Tailwind processes the `@apply` instruction and inlines the referenced utility styles into your custom class in the output CSS. This approach is best for elements you repeat very frequently (like buttons) where typing the full utility string every time is impractical. For most components, however, the Blade component approach from Lesson 15 is preferable because it keeps the styling decisions inside a single component file.

---

## Next Up - Lesson 17

In this lesson you set up a complete frontend build pipeline for Catatku. You ran `npm install` to confirm all dependencies, verified the `@import 'tailwindcss'` entry point in `resources/css/app.css`, added brand color tokens using the `@theme {}` block, confirmed the `vite.config.js` setup with the `@tailwindcss/vite` plugin, and replaced the CDN script tag in your layout with the `@vite([...])` directive. You migrated the entries index view to use `<x-entry-card>` and pagination links, updated the entry card component template to use Tailwind utility classes instead of inline styles, and ran `npm run dev` to enable hot reloading with instant browser refresh on every file save.

In Lesson 17, you will learn deploying to production: how to configure the environment securely, run optimization commands, keep queue workers running with Supervisor, and set up Nginx for HTTPS with zero-downtime deployment.