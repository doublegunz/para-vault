---
title: "Inertia.js v3 Beta Released: Lighter, Faster, Less Configuration"
slug: "inertiajs-v3-beta-released-lighter-faster-less-configuration"
category: "Laravel"
date: "2026-03-05"
status: "published"
---

The Inertia.js team has officially released the first beta of Inertia.js v3, announced via the [official Laravel blog](https://laravel.com/blog/inertiajs-v3-is-now-in-beta) and confirmed by Taylor Otwell through [his X account](https://x.com/taylorotwell/status/2029633643442774039). This is a significant release, not just an incremental feature drop but a meaningful overhaul of several core parts of the framework.

The three biggest changes in v3: Axios has been officially dropped in favor of a built-in XHR client, initial app setup is now much leaner thanks to a new Vite plugin, and several patterns that developers previously had to implement manually are now first-class APIs, including optimistic updates, instant visits, and layout props.

Since it is still in beta, this release is intended for community testing before the stable version ships. For those already on v2, a migration guide is available and covers all breaking changes in full detail.

## The Vite Plugin That Kills the Boilerplate {#vite-plugin}

Anyone who has set up an Inertia project from scratch knows the routine: write a `resolve` callback to map page names to components, write a `setup` callback for mounting, create a separate SSR entry point, reconfigure Vite for SSR. That setup was nearly identical across every project.

In v3, all of that boilerplate moves into the `@inertiajs/vite` plugin. The Vite config only needs a single plugin added:

```js
// vite.config.js
import inertia from '@inertiajs/vite'
import laravel from 'laravel-vite-plugin'
import { defineConfig } from 'vite'

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
        inertia(),
    ],
})
```

And the JavaScript entry point becomes as minimal as this:

```js
// resources/js/app.js
import { createInertiaApp } from '@inertiajs/vue3'

createInertiaApp()
```

The plugin automatically resolves page components from the `./Pages` directory, handles lazy-loading, code splitting, and SSR configuration. The `setup` and `resolve` callbacks are still available for custom behavior, and a `pages` shorthand lets you point to a different directory if needed.

## SSR Works in Development Without a Separate Server {#ssr-development}

A common frustration with SSR in Inertia v2 was the friction during development. You had to build the SSR bundle first, spin up a separate Node.js process, and only then could you see the result. That workflow interrupted the fast iteration loop that development requires.

In v3, the Vite plugin solves this. SSR is active automatically when `npm run dev` is running, with no build step and no extra process to manage.

The production workflow stays the same: build with `vite build && vite build --ssr`, then start the SSR server using `php artisan inertia:start-ssr`.

Error reporting during SSR has also been improved considerably. When a component fails to render on the server, Inertia now surfaces the component name, the URL being accessed, and actionable hints to help resolve the issue. SSR can also be disabled per route via middleware or the facade, and a `SsrRenderFailed` event is dispatched for monitoring purposes.

## Axios Removed, Replaced by a Built-in Client {#axios-removed}

Inertia v3 drops its dependency on Axios entirely. All internal HTTP communication is now handled by a custom-built XHR client, which reduces the bundle size and trims the dependency tree. The `qs` package, which was previously bundled alongside Axios, has also been removed.

For projects that rely on Axios-specific features like interceptors, an Axios adapter is available as a transitional option.

## `useHttp` for Requests Outside the Page Lifecycle {#usehttp}

There has always been a small but annoying gap in Inertia's developer experience: when a developer needed to make a plain HTTP request (to a search endpoint or an external API, for example), they had to step outside the Inertia ecosystem and reach for Axios or `fetch` directly. The trade-off was losing the reactive loading state and error handling that `useForm` provides.

`useHttp` is the answer to that. Its API is intentionally modeled after `useForm` so there is no new pattern to learn:

```js
<script setup>
import { useHttp } from '@inertiajs/vue3'

const http = useHttp({
    query: '',
})

function search() {
    http.get('/api/search', {
        onSuccess: (response) => {
            console.log(response)
        },
    })
}
</script>

<template>
    <input v-model="http.query" @input="search" />
    <div v-if="http.processing">Searching...</div>
</template>
```

The hook comes with reactive state, error handling, file upload progress tracking, and request cancellation. It also supports optimistic updates and precognition.

## Optimistic Updates as a First-Class API {#optimistic-updates}

Optimistic UI (showing changes before the server responds) is not a new concept, but implementing it manually has always required a fair amount of code: update local state, handle rollbacks on failure, and make sure concurrent requests do not interfere with each other.

In v3, Inertia handles all of that. Simply chain `optimistic()` before sending a request:

```js
router.optimistic((props) => ({
    post: {
        ...props.post,
        likes: props.post.likes + 1,
    },
})).post(`/posts/${post.id}/like`)
```

Inertia immediately applies the props returned by the callback. Once the server responds, the real data takes over. If the request fails, props are automatically reverted to their previous state. Multiple concurrent optimistic updates are tracked independently so they do not conflict with each other.

This feature works across router visits, the `<Form>` component, `useForm`, and `useHttp`.

## Instant Visits {#instant-visits}

Instant visits are a new navigation mode where the target page component renders immediately using already-available shared props, while the server request continues in the background. Page-specific props are merged in once the response arrives:

```js
<Link href="/dashboard" component="Dashboard">Dashboard</Link>
```

The result is navigation that feels instant to the user, without skipping the actual server round-trip for fresh data.

## Layout Props: Page-to-Layout Communication Without Workarounds {#layout-props}

Persistent layouts in Inertia are one of the framework's most powerful features, but setting up two-way communication between a layout and a page component has never had a clean, official solution. Developers typically had to resort to an event bus or `provide`/`inject` for things like updating the page title or toggling a sidebar from within a page component.

`useLayoutProps` provides the official way to do this. A layout declares its props along with default values:

```js
<!-- Layout.vue -->
<script setup>
import { useLayoutProps } from '@inertiajs/vue3'

const { title, showSidebar } = useLayoutProps({
    title: 'My App',
    showSidebar: true,
})
</script>
```

Pages can then override those values using `setLayoutProps()`. Named layouts, nested layouts, and static props are all supported.

## Cleaner Error Page Handling {#exception-handling}

There is a scenario where exceptions like 404s occur before a request reaches the Inertia middleware, which means the error response has no access to shared props or the root view. In v2, handling this gracefully required a workaround.

The new `handleExceptionsUsing()` method gives full control over this case:

```php
use Inertia\Inertia;
use Inertia\ExceptionResponse;

Inertia::handleExceptionsUsing(function (ExceptionResponse $response) {
    if (in_array($response->statusCode(), [403, 404, 500, 503])) {
        return $response->render('ErrorPage', [
            'status' => $response->statusCode(),
        ])->withSharedData();
    }
});
```

Calling `withSharedData()` forces Inertia to resolve its middleware so that shared props are available on the error page. Returning `null` falls through to Laravel's default exception rendering behavior.

## Other Improvements {#other-improvements}

Beyond the headline features, v3 also ships a number of smaller improvements worth noting:

- **Nested prop types.** `Inertia::optional()`, `Inertia::defer()`, and `Inertia::merge()` now work inside nested arrays, with dot-notation support for partial reloads.
- **Event renames.** `invalid` and `exception` are now `httpException` and `networkError`, with per-visit `onHttpException` and `onNetworkError` callbacks added alongside them.
- **Default layout.** A default layout can now be set directly in `createInertiaApp` rather than declaring it on every individual page.
- **TypeScript generics** on the `<Form>` component for type-safe errors and slot props.
- **PHP Enum support** directly in `Inertia::render()` responses.
- **ESM only.** All packages now ship exclusively as ES Modules. CommonJS `require()` imports are no longer supported.
- **`preserveErrors` option** to retain validation errors during partial reloads.

## Breaking Changes {#breaking-changes}

Before attempting an upgrade, there are a few requirements to be aware of. Inertia v3 requires PHP 8.2+, Laravel 11+, React 19+ (for the React adapter), and Svelte 5+ (for the Svelte adapter).

Other breaking changes to note:

- **Axios is no longer included.** Migrate interceptors to the built-in HTTP client or use the Axios adapter.
- **The `qs` package is no longer bundled.** Install it directly if your application imports it.
- **`Inertia::lazy()` has been removed.** It was deprecated in v2, so switch to `Inertia::optional()`.
- **`router.cancel()` is now `router.cancelAll()`**, with more granular control over which request types get cancelled.
- **All `future` flags from v2 are now always active.** The `future` configuration option no longer exists.
- **The config file structure has changed.** Run `php artisan vendor:publish --provider="Inertia\\ServiceProvider" --force` to republish it.

The full upgrade guide is available at [inertiajs.com](https://inertiajs.com/docs/v3/getting-started/upgrade-guide).