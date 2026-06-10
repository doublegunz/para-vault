# Integrating Vite, Tailwind CSS v4, and Bun with CodeIgniter 4 (Without a Vite Package)

If you have worked with Laravel, you know how convenient `@vite('resources/js/app.js')` is: hot module replacement during development, cache-busted hashed filenames in production, and one line in your view to wire everything up. Coming back to CodeIgniter 4 can feel like a step backward. You either commit a pre-built CSS file to your repository, run Tailwind CLI in a separate terminal and reload manually, or pull in a third party package that hides what is actually happening under the hood.

The cost of those workarounds is real. You lose HMR, you lose long-term cache busting, you couple your project to a maintainer you do not control, and you make onboarding harder because new developers have to learn yet another bespoke setup.

The good news is that Vite is framework agnostic. The Laravel Vite plugin is just two ingredients: a JSON manifest that maps source files to hashed output files, and a small "hot" file that tells the backend a dev server is running. We can build the same integration ourselves in CodeIgniter 4 with a custom helper of about fifty lines, a custom inline Vite plugin, and Bun as the package manager to keep installation and builds fast.

## Overview {#overview}

This tutorial walks through wiring Vite, Tailwind CSS v4, and Bun into a fresh CodeIgniter 4 application. The result is a `vite()` helper that you call from any view, exactly like Laravel's `@vite` directive, that automatically switches between development mode (with HMR) and production mode (with hashed assets) without any code changes in your views. We will also build a small demo page so you can see CSS, JavaScript, and assets all flowing through Vite end to end.

### What You'll Build

A CodeIgniter 4 project with Vite serving CSS and JavaScript through Bun, Tailwind CSS v4 active across all view files, a custom `vite()` helper that reads the Vite manifest, a custom inline Vite plugin that writes a hot file when the dev server starts, and a landing page with an interactive counter button to verify CSS and JS bundling.

### What You'll Learn

How Vite's backend integration works with `manifest.json` and `isEntry` chunks, how to deploy a "hot file" pattern to detect development mode, how to build and autoload a custom CodeIgniter 4 helper, how to use the new `@tailwindcss/vite` plugin for Tailwind v4 without a `tailwind.config.js`, and how to swap npm for Bun while keeping the same Vite tooling.

### What You'll Need

PHP 8.1 or later, Composer installed globally, Bun 1.x installed (run `curl -fsSL https://bun.sh/install | bash` to install), and a basic understanding of CodeIgniter 4 controllers, views, and helpers.

## Step 1: Create the CodeIgniter 4 Project {#step-1-create-the-codeigniter-4-project}

We start from a fresh CodeIgniter 4 installation so that nothing in the project assumes any frontend tooling. Composer downloads the starter app and all framework dependencies into a folder called `ci-vite-bun`.

```bash
composer create-project codeigniter4/appstarter ci-vite-bun
cd ci-vite-bun
```

Composer will print the dependency resolution and download progress. Once it finishes, copy `env` to `.env` and verify that the application boots with the built in development server.

```bash
cp env .env
php spark serve
```

The terminal output below confirms the server is listening on port 8080.

```
CodeIgniter v4.7.2 Command Line Tool - Server Time: 2026-05-18 09:14:22 UTC

CodeIgniter development server started on http://localhost:8080
Press Control-C to stop.
```

Open `http://localhost:8080` in your browser. You should see the default CodeIgniter welcome page. Stop the server with `Ctrl+C` and continue.

## Step 2: Initialize Bun and Install Vite and Tailwind v4 {#step-2-initialize-bun-and-install-vite-and-tailwind-v4}

Bun replaces npm as both the package manager and the script runner. We initialize a `package.json` first, then install Vite together with the Tailwind v4 Vite plugin in a single command.

```bash
bun init -y
```

Open `package.json` in your editor and replace its content with the configuration below. The `"type": "module"` line is important because Vite's config file uses ES module syntax. The two scripts give us `bun run dev` for the development server and `bun run build` for the production bundle.

```json
{
  "name": "ci-vite-bun",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  }
}
```

Now install Vite and the Tailwind v4 packages as dev dependencies. Tailwind v4 ships its own Vite plugin (`@tailwindcss/vite`) so you do not need PostCSS, Autoprefixer, or a separate `tailwind.config.js` file for the basic setup.

```bash
bun add -D vite @tailwindcss/vite tailwindcss
```

Bun reports installed packages and writes a `bun.lock` file alongside `package.json`.

```
bun add v1.1.34

installed vite@7.0.4 with binaries:
 - vite
installed @tailwindcss/vite@4.1.7
installed tailwindcss@4.1.7

 3 packages installed [612.00ms]
```

You can also delete the `index.ts` file Bun created by default during `bun init`. We will use our own source layout in the next step.

## Step 3: Create the Frontend Source Files {#step-3-create-the-frontend-source-files}

Vite needs entry points: source files that act as the root of your CSS and JavaScript graphs. Following Laravel's convention, we put them in a `resources/` folder at the project root. This keeps source files clearly separate from the publicly served files in `public/`.

Create the folder structure first.

```bash
mkdir -p resources/css resources/js
```

Create `resources/css/app.css` with the Tailwind v4 import and an `@source` directive that tells Tailwind to scan your CodeIgniter view files for class names. Without `@source`, Tailwind v4 only scans files reachable through the JavaScript graph, which would miss your PHP views entirely.

```css
@import "tailwindcss";

@source "../../app/Views/**/*.php";
```

The `@import "tailwindcss";` line pulls in the entire Tailwind framework. The `@source` directive uses a relative glob pattern starting from this CSS file's location: two levels up takes you to the project root, then into `app/Views/`. Any class you write in any view, including subfolders, will be picked up.

Now create `resources/js/app.js`. We import the CSS so that Vite includes it in the bundle graph and emits the CSS files in the manifest. The rest is a tiny counter widget that wires up a button to increment a number on screen.

```js
import '../css/app.css';

// Wire up the counter button after the DOM is ready so the elements exist.
document.addEventListener('DOMContentLoaded', () => {
  const button = document.getElementById('counter-btn');
  const display = document.getElementById('counter-value');
  let count = 0;

  if (!button || !display) {
    return;
  }

  button.addEventListener('click', () => {
    count += 1;
    display.textContent = String(count);
  });
});
```

The CSS import is what links the two source trees. When Vite builds the JS entry, it follows that import, emits a hashed CSS file, and records both files in the manifest under the JS entry's `css` field. That is the same trick Laravel uses, and it is how we will pull both into the page with a single helper call later.

## Step 4: Configure Vite for Backend Integration {#step-4-configure-vite-for-backend-integration}

Vite's defaults assume an SPA where Vite owns `index.html`. We are using it as a backend integration instead, so we need to tell it to write a manifest, output to the CodeIgniter public folder, and announce its dev server URL. We also include a custom inline plugin that writes the hot file. The hot file is the signal our PHP helper will use to detect whether the dev server is running.

Create `vite.config.js` at the project root with the content below.

```js
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import fs from 'node:fs';
import path from 'node:path';

// Custom plugin that writes public/hot when the dev server starts and removes
// it on shutdown. The PHP helper checks for this file to decide whether to
// load assets from the dev server or from the production manifest.
function codeigniterHot() {
  const hotFile = path.resolve('public/hot');

  const cleanup = () => {
    if (fs.existsSync(hotFile)) {
      fs.unlinkSync(hotFile);
    }
  };

  return {
    name: 'codeigniter-hot',
    configureServer(server) {
      server.httpServer?.once('listening', () => {
        const address = server.httpServer.address();
        const protocol = server.config.server.https ? 'https' : 'http';
        const port = typeof address === 'object' && address ? address.port : 5173;
        fs.writeFileSync(hotFile, `${protocol}://localhost:${port}`);
      });

      process.on('exit', cleanup);
      process.on('SIGINT', () => process.exit());
      process.on('SIGTERM', () => process.exit());
      process.on('SIGHUP', () => process.exit());
    },
    buildEnd() {
      cleanup();
    },
  };
}

export default defineConfig({
  plugins: [
    tailwindcss(),
    codeigniterHot(),
  ],
  server: {
    // The origin Vite will use when generating asset URLs at dev time.
    // CodeIgniter runs on a different port, so we must set this explicitly.
    origin: 'http://localhost:5173',
    cors: true,
  },
  build: {
    // Emit .vite/manifest.json next to the built assets.
    manifest: true,
    // Write build output into CodeIgniter's public folder so spark serve
    // can serve the hashed files directly.
    outDir: 'public/build',
    // Clear the build folder before each rebuild to avoid stale assets.
    emptyOutDir: true,
    rollupOptions: {
      // Declare every file that should be a public entry point. Anything
      // imported from these files becomes part of their bundle graph.
      input: [
        'resources/css/app.css',
        'resources/js/app.js',
      ],
    },
  },
});
```

A few decisions in this config are worth explaining. The `server.origin` value matters because Vite serves assets from its own port (5173) while CodeIgniter serves the HTML from port 8080. Without `server.origin`, asset URLs generated inside CSS files would be relative paths that the browser tries to fetch from the CodeIgniter server, which does not have them. Setting `origin` to `http://localhost:5173` makes those URLs absolute and routed back to Vite. The `cors: true` line allows the browser to fetch those cross-origin assets without errors.

`build.outDir` is set to `public/build` so that the compiled, hashed files end up inside `public/`, which is what CodeIgniter exposes to the web. The manifest will land at `public/build/.vite/manifest.json` (Vite 5 and newer put the manifest in a `.vite/` subfolder by default), and that is the path the helper will read in production.

## Step 5: Build the Vite Helper {#step-5-build-the-vite-helper}

This is the heart of the integration. The helper exposes one function, `vite()`, that you call from your views. It checks for `public/hot`: if it exists, the dev server is running and we emit `<script>` tags pointing at the Vite dev server. If it does not exist, we read `manifest.json` and emit `<link>` and `<script>` tags with the production paths.

Create the folder and the helper file.

```bash
mkdir -p app/Helpers
```

Create `app/Helpers/vite_helper.php` with the content below.

```php
<?php

if (! function_exists('vite')) {
    /**
     * Render the HTML tags needed to load Vite entry points.
     *
     * During development (when public/hot exists), this emits script tags
     * pointing at the Vite dev server, including the @vite/client runtime
     * that powers hot module replacement.
     *
     * In production (no public/hot), this reads the Vite manifest and
     * emits link and script tags with cache-busted hashed filenames.
     *
     * @param array<int, string>|string $entries One or more entry points
     *                                           relative to the project root.
     */
    function vite(array|string $entries): string
    {
        $entries = is_array($entries) ? $entries : [$entries];
        $hotFile = FCPATH . 'hot';

        // Development mode: dev server is running.
        if (is_file($hotFile)) {
            $devUrl = rtrim((string) file_get_contents($hotFile));
            $tags   = '<script type="module" src="' . esc($devUrl . '/@vite/client', 'attr') . '"></script>';

            foreach ($entries as $entry) {
                $tags .= '<script type="module" src="' . esc($devUrl . '/' . $entry, 'attr') . '"></script>';
            }

            return $tags;
        }

        // Production mode: read the manifest and emit hashed asset tags.
        $manifestPath = FCPATH . 'build/.vite/manifest.json';

        if (! is_file($manifestPath)) {
            throw new RuntimeException(
                'Vite manifest not found at ' . $manifestPath
                . '. Run "bun run build" or "bun run dev" before loading the page.'
            );
        }

        $manifest = json_decode((string) file_get_contents($manifestPath), true);
        $tags     = '';
        $seenCss  = [];

        foreach ($entries as $entry) {
            if (! isset($manifest[$entry])) {
                throw new RuntimeException("Entry \"{$entry}\" not found in Vite manifest.");
            }

            $chunk = $manifest[$entry];

            // Emit CSS from the chunk's own css array.
            foreach ($chunk['css'] ?? [] as $cssFile) {
                if (! isset($seenCss[$cssFile])) {
                    $tags             .= '<link rel="stylesheet" href="' . esc('/build/' . $cssFile, 'attr') . '">';
                    $seenCss[$cssFile] = true;
                }
            }

            // Recursively pick up CSS from statically imported chunks so that
            // shared stylesheets are included even when they live in a
            // dependency, not the entry itself.
            foreach ($chunk['imports'] ?? [] as $importKey) {
                $importChunk = $manifest[$importKey] ?? null;

                if ($importChunk === null) {
                    continue;
                }

                foreach ($importChunk['css'] ?? [] as $cssFile) {
                    if (! isset($seenCss[$cssFile])) {
                        $tags             .= '<link rel="stylesheet" href="' . esc('/build/' . $cssFile, 'attr') . '">';
                        $seenCss[$cssFile] = true;
                    }
                }
            }

            // Decide what kind of tag the entry file itself needs.
            $file = $chunk['file'];

            if (str_ends_with($file, '.css')) {
                $tags .= '<link rel="stylesheet" href="' . esc('/build/' . $file, 'attr') . '">';
            } else {
                $tags .= '<script type="module" src="' . esc('/build/' . $file, 'attr') . '"></script>';
            }
        }

        return $tags;
    }
}
```

The helper is built around three ideas. First, `FCPATH` is CodeIgniter's constant for the `public/` directory, which is where both the hot file and the build folder live. Using it keeps the helper portable across machines.

Second, the development branch is intentionally minimal: it just emits the `@vite/client` script (which establishes the HMR WebSocket and replaces modules on save) and then one `<script type="module">` per entry, with full URLs that point at the Vite dev server.

Third, the production branch walks the manifest the same way the official Laravel plugin does. For each entry it emits the CSS files from the chunk's `css` array, the CSS files of any chunks listed under `imports` (so shared stylesheets are not missed), and finally a `<script type="module">` for the JS chunk itself (or a `<link>` if the entry was a CSS file). The `$seenCss` array prevents the same CSS file from being included twice when two entries share a dependency.

## Step 6: Autoload the Helper {#step-6-autoload-the-helper}

By default CodeIgniter only loads helpers on demand. Since we want `vite()` available in every view without a manual `helper()` call, we add it to the autoload list.

Open `app/Config/Autoload.php` and find the `$helpers` property. Update it to include `vite`.

```php
public $helpers = ['vite'];
```

That is all it takes. CodeIgniter's autoloader will now load `app/Helpers/vite_helper.php` (it automatically appends the `_helper.php` suffix) on every request, which makes the `vite()` function globally available.

If you ever prefer not to autoload it, you can call `helper('vite')` at the top of any controller method or view and the function will become available only there.

## Step 7: Create the Controller and View {#step-7-create-the-controller-and-view}

We need a page that actually uses `vite()`, otherwise nothing happens. CodeIgniter ships with a `Home` controller that renders `welcome_message`. We will change it to render a new view of our own so we do not modify the framework defaults.

Update `app/Controllers/Home.php` to load a custom view and pass a small data payload.

```php
<?php

namespace App\Controllers;

class Home extends BaseController
{
    public function index(): string
    {
        // The view will use the vite() helper to load CSS and JS,
        // so we only need to pass page-level data here.
        return view('welcome_vite', [
            'title' => 'CodeIgniter 4 + Vite + Tailwind',
        ]);
    }
}
```

Now create `app/Views/welcome_vite.php`. The view is a standalone HTML document. The call to `vite('resources/js/app.js')` in the `<head>` produces both the CSS `<link>` and JS `<script>` tags, because the JS entry imports `app.css` and Vite knows to include that CSS in the JS chunk's manifest entry.

```php
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= esc($title) ?></title>
    <?= vite('resources/js/app.js') ?>
</head>

<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-3xl font-bold text-blue-700 mb-2">
            CodeIgniter 4 meets Vite
        </h1>
        <p class="text-gray-600 mb-6">
            This page is styled by Tailwind CSS v4, bundled by Vite, served by
            Bun in development, and pulled into the view by a single vite()
            helper call.
        </p>

        <div class="bg-blue-50 border border-blue-200 rounded-md p-4 mb-6">
            <p class="text-sm text-blue-800 mb-2">
                Click the button to confirm the JavaScript bundle is wired up.
            </p>
            <div class="flex items-center gap-4">
                <button
                    id="counter-btn"
                    class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md transition">
                    Increment
                </button>
                <span class="text-lg font-semibold text-blue-900">
                    Count: <span id="counter-value">0</span>
                </span>
            </div>
        </div>

        <ul class="list-disc list-inside text-gray-700 space-y-1">
            <li>CSS arrives through the Vite dev server during development.</li>
            <li>JS arrives the same way and supports hot module replacement.</li>
            <li>Production swaps both for hashed files from the manifest.</li>
        </ul>
    </div>

    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
            target="_blank">Tutorial CodeIgniter 4 + Vite + Tailwind at qadrlabs.com</a>
    </div>
</body>

</html>
```

Notice there is no manual `<link rel="stylesheet">` and no manual `<script>` tag. The single `vite()` call replaces them all, and the same view file works identically in development and production.

## Step 8: Try It Out {#step-8-try-it-out}

We have two modes to verify: development with Vite running and HMR active, and production with the bundle built and the manifest in place.

### Development Mode with HMR

Open two terminals. In the first, start the Vite dev server with Bun.

```bash
bun run dev
```

Vite prints a banner showing its local URL and the network address. As soon as it is listening, our custom plugin writes `public/hot` so the helper can pick it up.

```
  VITE v7.0.4  ready in 218 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

In the second terminal, start CodeIgniter.

```bash
php spark serve
```

```
CodeIgniter v4.7.2 Command Line Tool - Server Time: 2026-05-18 09:42:17 UTC

CodeIgniter development server started on http://localhost:8080
Press Control-C to stop.
```

Visit `http://localhost:8080` in your browser. The page should be fully styled with Tailwind, and clicking the button should increment the counter. Open your browser's developer tools, look at the `<head>` of the page, and you should see three `<script type="module">` tags: one for `/@vite/client`, one for `/resources/js/app.js`, all pointing at `http://localhost:5173`.

To confirm HMR works, leave both terminals running and edit `resources/css/app.css`. Add a custom rule below the imports.

```css
@import "tailwindcss";

@source "../../app/Views/**/*.php";

body {
    background-color: #fef3c7;
}
```

Save the file. Without reloading the page, the background should change to a soft yellow within a fraction of a second. That is HMR doing its job through the dev server connection. Revert the change before continuing.

### Production Mode with the Manifest

Stop the Vite dev server with `Ctrl+C`. Our cleanup hook removes `public/hot`, which signals the helper to switch into production mode. You can verify the file is gone with `ls public/hot`, which should return "No such file or directory".

Run the production build.

```bash
bun run build
```

Vite prints the list of emitted files. The exact hash suffixes will differ on your machine because they are derived from the file contents.

```
vite v7.0.4 building for production...
✓ 4 modules transformed.
public/build/.vite/manifest.json          0.20 kB │ gzip: 0.13 kB
public/build/assets/app-BqLm9xH3.css     12.84 kB │ gzip: 3.41 kB
public/build/assets/app-DkR8nQ2c.js       0.47 kB │ gzip: 0.32 kB
✓ built in 412ms
```

Open `public/build/.vite/manifest.json` to see what Vite produced. It will look similar to the example below.

```json
{
  "resources/css/app.css": {
    "file": "assets/app-BqLm9xH3.css",
    "src": "resources/css/app.css",
    "isEntry": true
  },
  "resources/js/app.js": {
    "file": "assets/app-DkR8nQ2c.js",
    "name": "app",
    "src": "resources/js/app.js",
    "isEntry": true,
    "css": ["assets/app-BqLm9xH3.css"]
  }
}
```

Notice that the JS entry has a `css` field listing the same CSS file as the standalone CSS entry. That is why calling `vite('resources/js/app.js')` is enough by itself: the helper sees the `css` array on the JS chunk and emits the `<link>` tag automatically.

Reload `http://localhost:8080` in your browser. The page should still look identical, the counter should still work, and now the `<head>` should contain two tags with hashed filenames.

```html
<link rel="stylesheet" href="/build/assets/app-BqLm9xH3.css">
<script type="module" src="/build/assets/app-DkR8nQ2c.js"></script>
```

The hashes are content based, so any future change to the source files will produce different filenames and bypass browser caches automatically. That is the entire point of the manifest dance.

## How the Vite Helper Works Under the Hood {#how-the-vite-helper-works-under-the-hood}

The integration we built is small, but it relies on a few moving parts that are worth understanding so you can extend it later. Let us walk through each.

The hot file is a one line text file at `public/hot` that contains the URL of the running Vite dev server, for example `http://localhost:5173`. Our custom Vite plugin writes it in `configureServer` once the HTTP server is listening, and removes it on `SIGINT`, `SIGTERM`, and `SIGHUP`. The presence of this file is the only signal the PHP helper uses to decide between development and production output. This is identical to how Laravel's official plugin works; we just inlined it instead of installing a package.

The manifest is a JSON map written by Vite during `vite build`. Each key in the map is the source path of an entry (or a hashed identifier for shared chunks), and each value is a small object describing the output `file`, any `css` files imported by that chunk, and any `imports` it has on other chunks. The Vite documentation describes the manifest as containing entry chunks marked with `isEntry: true` whose keys are the relative source paths from the project root. Our helper reads this file, looks up each requested entry, and recursively follows the `imports` field to pick up CSS from any statically imported chunks. That recursive step matters as soon as you split shared utilities into their own chunk: without it, common styles would silently disappear from one of the pages.

The `@vite/client` script we inject during development is what makes HMR work. It opens a WebSocket back to the dev server and listens for module update messages. When you save a CSS file, Vite recompiles it on the server, pushes a message over the socket, and the client swaps the affected stylesheet in place without a full page reload.

The `server.origin` setting in `vite.config.js` tells Vite the absolute origin to use when generating asset URLs at dev time. Because Vite runs on port 5173 and CodeIgniter runs on port 8080, any relative URL Vite emits inside a CSS file would otherwise be requested from port 8080, which has no idea what to serve. Setting `origin` to `http://localhost:5173` makes those URLs absolute and routed back to Vite.

## Adding More Entry Points {#adding-more-entry-points}

Most real projects have more than one page bundle. An admin panel typically has its own JavaScript, and you might want a marketing landing page with its own minimal bundle that does not pull in your full app code.

You can extend the integration without changing the helper. Add a second entry file under `resources/`, for example `resources/js/admin.js`, and register it as an entry in `vite.config.js`.

```js
rollupOptions: {
  input: [
    'resources/css/app.css',
    'resources/js/app.js',
    'resources/js/admin.js',
  ],
},
```

Then call the helper with the admin entry in the relevant view.

```php
<?= vite('resources/js/admin.js') ?>
```

Vite will produce a second hashed JS file and a second manifest entry. Each view loads only what it needs, and Vite still de-duplicates any shared chunks. If both entries import the same Tailwind CSS file, the manifest's `imports` field plus our `$seenCss` guard ensure the CSS is included once per page, not twice.

You can also pass multiple entries at once if a single page needs both.

```php
<?= vite(['resources/css/app.css', 'resources/js/admin.js']) ?>
```

## Conclusion {#conclusion}

You now have a Laravel-style Vite integration in CodeIgniter 4 that you fully control, with no third party CodeIgniter packages locking you to someone else's release cycle. The same view file works in development and production, HMR is available out of the box, and your production assets are cache-busted automatically. The whole integration is about fifty lines of PHP and fifty lines of JavaScript, all written by you.

- **Hot file pattern.** A simple text file at `public/hot` is enough to switch the helper between development and production. The Vite dev server writes it on start and removes it on stop, so the PHP side just checks for its existence.
- **Manifest as a source of truth.** In production, every script and stylesheet tag is derived from `public/build/.vite/manifest.json`. As long as the manifest exists, your views never need to know what the hashed filenames are.
- **Recursive CSS resolution.** Walking the `imports` field of each entry chunk picks up CSS from shared dependencies, which keeps the helper correct even when you start splitting bundles.
- **Bun for speed.** Bun installs packages and runs Vite faster than npm without changing any Vite configuration. The CodeIgniter side never knows or cares which runtime built the assets.
- **Tailwind v4 simplicity.** The `@tailwindcss/vite` plugin and a single `@import "tailwindcss"` line replace the entire v3 setup of `tailwind.config.js`, PostCSS, and Autoprefixer. The `@source` directive in your CSS file tells Tailwind where your CodeIgniter views live so it can find the classes you actually use.
- **Extensibility.** Adding more entry points, supporting subresource integrity, or pointing the build directory somewhere else is a small change to either the Vite config or the helper, never both at once.

<div class="mt-8 mb-6 text-center text-sm text-gray-500"> <a href="https://qadrlabs.com" target="_blank">Tutorial CodeIgniter 4 + Vite + Tailwind at qadrlabs.com</a> </div>