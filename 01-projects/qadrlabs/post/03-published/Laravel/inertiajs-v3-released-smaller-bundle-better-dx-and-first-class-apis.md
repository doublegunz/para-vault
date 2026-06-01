---
title: "Inertia.js v3 Released: Smaller Bundle, Better DX, and First-Class APIs"
slug: "inertiajs-v3-released-smaller-bundle-better-dx-and-first-class-apis"
category: "Laravel"
date: "2026-03-28"
status: "published"
---

If you have been building Laravel + Inertia applications for a while, you have likely run into the same friction points: Axios bundled into your app whether you needed it or not, SSR that required a separate dev process to see any result, and no clean way to pass data from a page component up to its persistent layout. Inertia v2 solved many problems well, but these rough edges stuck around.

Inertia.js v3 addresses all of them directly. This is a major release that covers the core package and all three framework adapters: React, Vue, and Svelte. The headline changes are a built-in XHR client that replaces Axios, a new `useHttp` hook for non-navigation requests, first-class optimistic update support, a clean layout props API, and SSR that works in Vite dev mode without a separate Node.js process.

> **Note:** We covered the beta earlier at [qadrlabs.com/post/inertiajs-v3-beta-released-lighter-faster-less-configuration](https://qadrlabs.com/post/inertiajs-v3-beta-released-lighter-faster-less-configuration). This article covers the stable release.

## Overview {#overview}

### What You'll Learn

- What is new in Inertia.js v3 and why it matters
- How the built-in XHR client replaces Axios and reduces your bundle size
- How `useHttp` handles non-navigation HTTP requests with reactive state
- How first-class optimistic updates work across the router, `useForm`, and `useHttp`
- How layout props replace event bus and `provide`/`inject` workarounds
- What breaking changes to watch out for when upgrading from v2

### What You'll Need

- PHP 8.2 or higher (PHP 8.3+ if you are on Laravel 13)
- Laravel 11 or higher (Laravel 13 is the current stable release and is supported)
- Node.js with npm
- An existing Inertia v2 project, or a fresh Laravel project
- React 19+ (if using the React adapter), or Svelte 5+ (if using the Svelte adapter)


## Built-In XHR Client: Axios is No Longer Required {#built-in-xhr-client}

Axios has been removed as a required dependency. Inertia v3 ships its own XHR client that handles all internal HTTP communication. For most projects this means one less dependency and approximately 15KB removed from the gzipped bundle without any code changes on your end.

The `qs` package for query string serialization and `lodash-es` have also been removed. Both have been replaced with lighter internal alternatives (`es-toolkit` replaces `lodash-es`).

If your application uses Axios interceptors or relies on Axios-specific behavior, Axios is still available as an optional peer dependency. The built-in client also supports interceptors natively, so migrating is straightforward. If you still need Axios, install it manually and configure the Axios adapter.

If your application imports `qs` or `lodash-es` directly anywhere in your own code, install them as direct dependencies:

```bash
npm install qs
npm install lodash-es
```


## `useHttp`: Non-Navigation HTTP Requests with Reactive State {#usehttp}

Making a plain HTTP request in Inertia v2, for example to a search endpoint or an autocomplete API, meant stepping outside the Inertia ecosystem entirely. You would reach for `fetch` or Axios directly and lose the reactive loading state and error handling that `useForm` gives you.

`useHttp` closes that gap. Its API mirrors `useForm` intentionally, so there is no new pattern to learn. The hook returns reactive `processing`, `errors`, `progress`, and `isDirty` state that you can bind directly in your template:

```js
const http = useHttp({
    query: '',
})

const search = () => {
    http.get('/api/search').then((results) => {
        console.log('Found:', results.length)
    })
}
```

This hook is intended for routes that return `response()->json()`, not `Inertia::render()`. For standard Inertia page navigation, use the router as usual.

A `withAllErrors` option is also available. Laravel returns only the first validation error per field by default. Setting `withAllErrors: true` returns all errors at once, which is useful for forms that need to surface every rule violation simultaneously:

```js
const http = useHttp({ name: '' }, { withAllErrors: true })
```


## Optimistic Updates {#optimistic-updates}

Optimistic UI means applying a state change to the page immediately before the server confirms the operation. If the request fails, the change rolls back automatically. Before v3, implementing this required manually managing local state, writing rollback logic, and being careful about concurrent requests.

In v3, Inertia handles all of this. Chain `optimistic()` before your request and declare the expected change. Only the keys you return in the callback are snapshotted for rollback — Inertia does not snapshot your entire page state:

```js
// Fluent API
router
    .optimistic((props) => ({
        todos: [...props.todos, { id: Date.now(), name, done: false }],
    }))
    .post('/todos', { name })

// Inline option
router.post('/todos', { name }, {
    optimistic: (props) => ({
        todos: [...props.todos, { id: Date.now(), name, done: false }],
    }),
})
```

Both approaches are equivalent. Optimistic updates also work with `useForm`:

```js
const form = useForm({ name: '' })

const addTodo = () => {
    form
        .optimistic((props) => ({
            todos: [...props.todos, { id: Date.now(), name: form.name, done: false }],
        }))
        .post('/todos')
}
```

The feature works across the router, `useForm`, and `useHttp`. Concurrent optimistic updates are handled correctly as well: each in-flight request carries its own rollback snapshot, so multiple simultaneous updates do not interfere with each other.


## Layout Props {#layout-props}

Persistent layouts are one of Inertia's most useful features, but two-way communication between a page and its layout has never had an official solution. Developers typically reached for an event bus or Vue's `provide`/`inject` to do things like update the page title or toggle a sidebar from within a page component.

`useLayoutProps` and `setLayoutProps` are the official answer. A layout declares its props and default values:

```js
// Layout.vue
import { useLayoutProps } from '@inertiajs/vue3'

const { title, showSidebar } = useLayoutProps({
    title: 'My App',
    showSidebar: true,
})
```

A page component overrides them by calling `setLayoutProps()`:

```js
// Dashboard.vue
import { setLayoutProps } from '@inertiajs/vue3'

setLayoutProps({
    title: 'Dashboard',
    showSidebar: false,
})
```

The layout receives these as direct component props. Named layouts, nested layouts, and static props are all supported.


## SSR in Vite Development Mode {#ssr-dev}

SSR development in Inertia v2 required building the SSR bundle first, then starting a separate Node.js server process, and only then seeing the result. That workflow was slow and interrupted the fast iteration loop that development requires.

In v3, the `@inertiajs/vite` plugin handles SSR automatically during development. Run your dev server normally and SSR is active out of the box:

```bash
npm run dev
```

No build step, no extra process to manage. A flash-of-unstyled-content fix is included as well.

For production, the workflow is unchanged:

```bash
vite build && vite build --ssr
php artisan inertia:start-ssr
```


## Other Notable Features {#other-features}

### Instant Visits

Instant visits are a new navigation mode where the target page component renders immediately using shared props that are already available on the client, while the actual server request continues in the background. Page-specific props are merged in once the response arrives:

```jsx
<Link href="/dashboard" component="Dashboard">Dashboard</Link>
```

The result is navigation that feels instant to the user without skipping the server round-trip for fresh data.

### `createInertiaApp()` Without Arguments

When using the `@inertiajs/vite` plugin, `createInertiaApp()` can now be called with zero configuration. The plugin handles component resolution, lazy-loading, and code splitting automatically:

```js
import { createInertiaApp } from '@inertiajs/vue3'

createInertiaApp()
```

A `layout` option and `withApp` callback are still available for cases where you need custom behavior.

### Nested Prop Types

`Inertia::optional()`, `Inertia::defer()`, and `Inertia::merge()` now work inside closures and nested arrays. Inertia resolves them at any depth, and dot-notation is supported on the client side for partial reloads:

```php
return Inertia::render('Dashboard', [
    'auth' => fn () => [
        'user' => Auth::user(),
        'notifications' => Inertia::defer(fn () => Auth::user()->unreadNotifications),
        'invoices' => Inertia::optional(fn () => Auth::user()->invoices),
    ],
]);
```

```js
router.reload({ only: ['auth.notifications'] })
```

### Blade Components

v3 introduces `<x-inertia::head>` and `<x-inertia::app>` as Blade component alternatives to the `@inertiaHead` and `@inertia` directives. The head component accepts a fallback slot that only renders when SSR is not active, which solves the long-standing duplicate `<title>` tag problem in SSR applications:

```blade
<html>
    <head>
        @vite('resources/js/app.js')
        <x-inertia::head>
            <title>{{ config('app.name') }}</title>
        </x-inertia::head>
    </head>
    <body>
        <x-inertia::app />
    </body>
</html>
```

The existing `@inertia` and `@inertiaHead` directives continue to work and require no changes.

### Event Renames

Two global router events have been renamed for clarity:

| v2 | v3 |
|---|---|
| `invalid` | `httpException` |
| `exception` | `networkError` |

Update any global listeners accordingly:

```js
// Before (v2)
router.on('invalid', (event) => { ... })
router.on('exception', (event) => { ... })

// After (v3)
router.on('httpException', (event) => { ... })
router.on('networkError', (event) => { ... })
```

v3 also adds per-visit callbacks `onHttpException` and `onNetworkError`. Returning `false` from `onHttpException` prevents Inertia from navigating to the error page, which is useful when you want to handle a 4xx or 5xx response without leaving the current page:

```js
router.post('/users', data, {
    onHttpException: (response) => {
        return false
    },
    onNetworkError: (error) => { ... },
})
```

### `preserveErrors` Option

Validation errors are now retained during partial reloads when `preserveErrors: true` is set. Previously, partial reloads would clear validation errors even when the errored field was not part of the reload.

### React Strict Mode

Pass `strictMode: true` to `createInertiaApp()` to wrap your application in `React.StrictMode`:

```js
createInertiaApp({
    strictMode: true,
    // ...
})
```

### `HttpError` Base Class

A typed base class for HTTP exceptions in the event system. This makes it easier to distinguish HTTP errors from network errors in your event handlers using `instanceof` checks.


## Upgrading from v2 {#upgrade}

Run the following commands to upgrade. Replace `@inertiajs/vue3` with `@inertiajs/react` or `@inertiajs/svelte` depending on your adapter:

```bash
npm install @inertiajs/vue3@^3.0
npm install @inertiajs/vite@^3.0
composer require inertiajs/inertia-laravel:^3.0
```

Republish the config file since its structure has changed in v3:

```bash
php artisan vendor:publish --provider="Inertia\ServiceProvider" --force
```

Clear cached Blade views since the `@inertia` directive output has changed:

```bash
php artisan view:clear
```

### Breaking changes checklist

Before upgrading a production application, review these breaking changes:

- **Axios is removed.** If you use Axios interceptors, install Axios manually and configure the adapter.
- **`qs` is removed.** If your app imports it, add it as a direct dependency.
- **`lodash-es` is removed.** If your app imports it, add it as a direct dependency.
- **`Inertia::lazy()` is removed.** Switch to `Inertia::optional()`.
- **`router.cancel()` is now `router.cancelAll()`.** Update any call sites.
- **All `future` flags from v2 are now always active.** Remove any `future` configuration block.
- **`<head>` attribute renamed.** The `inertia` attribute on head elements in Blade templates must be updated to `data-inertia`.
- **Progress indicator exports removed.** `hideProgress()` and `revealProgress()` have been removed. Use `import { progress } from '@inertiajs/vue3'` and call `progress.hide()` / `progress.reveal()` instead.
- **Global events renamed.** `invalid` is now `httpException` and `exception` is now `networkError`. Update any `router.on()` listeners.
- **`useForm` processing reset timing changed.** The `processing` and `progress` state now only resets in `onFinish`, not immediately upon receiving a response.
- **ESM only.** CommonJS `require()` imports are no longer supported.
- **React 19+ required** for the React adapter.
- **Svelte 5+ required.** Svelte 4 is dropped and the adapter is rewritten with rune syntax.
- **On Laravel 13.** Laravel 13 (released March 17, 2026) ships with zero breaking changes from Laravel 12 and is fully compatible with Inertia v3. Note that Laravel 13 requires PHP 8.3 as its minimum, so make sure your PHP version is up to date.

The full upgrade guide is available at [inertiajs.com](https://inertiajs.com).


## Conclusion {#conclusion}

Inertia.js v3 is a significant release that resolves several long-standing friction points and raises the baseline developer experience of the framework:

- **Axios removed by default**, cutting roughly 15KB from the gzipped bundle and simplifying the dependency tree
- **`useHttp`** closes the gap for non-navigation HTTP requests with the same reactive DX as `useForm`
- **First-class optimistic updates** across the router, `useForm`, and `useHttp` handle state changes, rollbacks, and concurrent requests automatically
- **Layout props** replace event bus and `provide`/`inject` workarounds with a clean official API
- **SSR in Vite dev mode** eliminates the separate server process requirement during development
- **Instant visits** make client-side navigation feel faster without skipping the server round-trip
- **Nested prop types** and **Blade components** round out the server-side improvements
- **This is a major release with breaking changes**: review the upgrade guide carefully before upgrading, paying attention to PHP 8.2+ (8.3+ on Laravel 13), removed dependencies, renamed events, ESM-only output, and the `data-inertia` Blade attribute change