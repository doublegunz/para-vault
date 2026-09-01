# Laravel Starter Kits Now Ship with Vite+: A Hands-On First Look

Starting a modern Laravel application involves more than PHP. A frontend starter kit also needs a development server, production bundler, formatter, linter, type checker, test runner, Node.js runtime, and package manager. When each responsibility uses a separate tool and configuration file, the initial setup may work, but keeping every part aligned becomes another maintenance task.

Laravel has now simplified that starting point. Taylor Otwell [announced on X](https://x.com/taylorotwell/status/2093374948303618558) that all Laravel starter kits ship with Vite+. The change was merged through the official [Laravel Maestro pull request #60](https://github.com/laravel/maestro/pull/60), which migrated all 21 starter kit variants to Vite+ 0.3 for development and builds.

This tutorial takes a hands-on look at that change. You will create a fresh Laravel 13 application with the React starter kit, inspect its Vite+ configuration, install the global `vp` command on Linux, build the frontend, run the unified checks, and start the complete development environment.

## Overview {#overview}

The goal is to see what the Vite+ migration means inside a real Laravel starter kit instead of treating it as an abstract tooling announcement. Every command and terminal result shown below comes from a fresh project created after the switch.

### What You'll Build

- A fresh Laravel 13 application using the official React starter kit.
- A working global Vite+ CLI installation on Linux.
- A production frontend build generated through `vp build`.
- A starter kit that passes the Vite+ formatter and linter checks.
- A local Laravel development environment powered by `php artisan dev` and Vite+.

### What You'll Learn

- Where Vite+ appears in a newly generated Laravel starter kit.
- What the `vp` command does and how it relates to the local `vite-plus` package.
- How `vp build`, `vp check`, and `vp check --fix` behave in practice.
- How Laravel stores linting and formatting rules inside `vite.config.ts`.
- How to distinguish Vite+ built-in commands from `package.json` scripts.
- How to approach migrating an existing Vite project with `vp migrate`.

### What You'll Need

- PHP 8.3 or newer.
- Composer 2.
- Laravel Installer installed globally through Composer.
- Git and `curl`.
- A Linux environment for the Vite+ installation command used in this tutorial.
- Basic familiarity with Laravel, React, TypeScript, and terminal commands.

The official [Laravel 13 installation documentation](https://laravel.com/docs/13.x/installation#installing-php) covers the required PHP, Composer, and Laravel Installer setup if these tools are not already available on your machine.

## Step 1: Update the Laravel Installer {#step-1-update-the-laravel-installer}

Start by checking the globally installed Laravel Installer version:

```bash
$ laravel --version
Laravel Installer 5.31.0

```

This test started with Laravel Installer 5.31.0. Because starter kits are fetched when a new application is created, updating the installer first provides a clean starting point for generating a project with the current starter kit workflow.

Run the following Composer command:

```bash
composer global update laravel/installer --with-all-dependencies
```

The `--with-all-dependencies` option allows Composer to update dependencies required by the installer instead of limiting the operation to the installer package alone.

Check the version again after Composer finishes:

```bash
$ laravel --version
Laravel Installer 5.32.0

```

The environment now uses Laravel Installer 5.32.0. This confirms that the global command was updated before the new starter kit was created.

## Step 2: Create a Laravel React Starter Kit {#step-2-create-a-laravel-react-starter-kit}

Create a new application with the interactive Laravel Installer:

```bash
laravel new test-new-starter-kit
```

Choose a starter kit, select React as the frontend stack, and use Laravel's built-in authentication. The test also leaves teams support disabled and enables the available authentication features.

The complete project creation output is:

```text
$ laravel new test-new-starter-kit

 ██╗       █████╗  ██████╗   █████╗  ██╗   ██╗ ███████╗ ██╗
 ██║      ██╔══██╗ ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ██║
 ██║      ███████║ ██████╔╝ ███████║ ██║   ██║ █████╗   ██║
 ██║      ██╔══██║ ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║
 ███████╗ ██║  ██║ ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ███████╗
 ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝

 ┌ Do you want to use a starter kit? ───────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which frontend stack should your starter kit use? ───────────┐
 │ React                                                        │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which authentication provider do you prefer? ────────────────┐
 │ Laravel's built-in authentication                            │
 └──────────────────────────────────────────────────────────────┘

 ┌ Would you like to add teams support to your application? ────┐
 │ No                                                           │
 └──────────────────────────────────────────────────────────────┘

 • Creating Laravel application
   ✔ Application initialized


 ┌ Which authentication features would you like to enable? ─────┐
 │ Email verification                                           │
 │ Registration                                                 │
 │ Two-factor authentication                                    │
 │ Passkeys                                                     │
 │ Password confirmation                                        │
 └──────────────────────────────────────────────────────────────┘

 • Composer Lint
   ✔ composer lint

 ⠠ Generate Wayfinder Resources
 • Generate Wayfinder Resources
   ✔ php artisan wayfinder:generate --with-form --no-interaction

 • Running database migrations
   ✔ Database migrated

 • Setting up Pest
   ✔ Pest initialized

 • Fixing test code style
   ✔ Test code style fixed

 • Setting up frontend dependencies with npm
   ✔ Assets built

 • Setting up Laravel Boost for AI assisted coding
   ✔ Boost initialized

 ┌ Application ready ───────────────────────────────────────────┐
 │ You can start your local development using:                  │
 │                                                              │
 │ 1. cd test-new-starter-kit                                   │
 │ 2. composer run dev                                          │
 │                                                              │
 │ New to Laravel? Check out our documentation.                 │
 │                                                              │
 │ Build something amazing!                                     │
 └──────────────────────────────────────────────────────────────┘

```

The installer creates the application, configures authentication, runs the database migrations, initializes Pest, builds the frontend assets, and prepares Laravel Boost. The application is already runnable when the command completes.

Move into the generated directory and open it in Visual Studio Code:

```bash
cd test-new-starter-kit
code .
```

All remaining commands should run from the project root.

## Step 3: Inspect the Vite+ Integration {#step-3-inspect-the-vite-plus-integration}

The first visible sign of the migration is in `package.json`. Open the file and find the `scripts` object:

```json
"scripts": {
    "build": "vp build",
    "build:ssr": "vp build && vp build --ssr",
    "dev": "vp dev",
    "check": "vp check",
    "check:fix": "vp check --fix",
    "types:check": "tsc --noEmit"
},
```

The usual development and build entries now call `vp`. The starter kit also consolidates formatting and linting under `check` and `check:fix`, while retaining `types:check` for an explicit TypeScript compiler pass.

The official [React starter kit package.json](https://github.com/laravel/react-starter-kit/blob/main/package.json) also declares `vite-plus` 0.3.0 as a local development dependency. This local package gives the project a pinned toolchain instead of depending only on whichever global CLI version happens to be installed.

Next, open `vite.config.ts`. The generated file contains both the familiar Laravel and React plugins and the new Vite+ static-check configuration:

```typescript
import inertia from '@inertiajs/vite';
import { wayfinder } from '@laravel/vite-plugin-wayfinder';
import babel from '@rolldown/plugin-babel';
import tailwindcss from '@tailwindcss/vite';
import react, { reactCompilerPreset } from '@vitejs/plugin-react';
import laravel from 'laravel-vite-plugin';
import { bunny } from 'laravel-vite-plugin/fonts';
import { defineConfig, lazyPlugins } from 'vite-plus';

export default defineConfig({
    plugins: lazyPlugins(() => [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.tsx'],
            refresh: true,
            fonts: [
                bunny('Instrument Sans', {
                    weights: [400, 500, 600],
                }),
            ],
        }),
        inertia(),
        react(),
        babel({
            presets: [reactCompilerPreset()],
        }),
        tailwindcss(),
        wayfinder({
            formVariants: true,
        }),
    ]),
    server: {
        watch: {
            ignored: [
                '**/.agents/**',
                '**/.claude/**',
                '**/.cursor/**',
                '**/.junie/**',
                '**/vendor/**',
            ],
        },
    },
    lint: {
        ignorePatterns: [
            'vendor/**',
            'node_modules/**',
            'public/**',
            'bootstrap/ssr/**',
            'tailwind.config.js',
            'resources/js/actions/**',
            'resources/js/components/ui/*',
            'resources/js/routes/**',
            'resources/js/wayfinder/**',
        ],
        options: {
            denyWarnings: true,
            typeAware: true,
        },
    },
    fmt: {
        printWidth: 80,
        tabWidth: 4,
        singleQuote: true,
        semi: true,
        singleAttributePerLine: false,
        htmlWhitespaceSensitivity: 'css',
        ignorePatterns: [
            '.github/**',
            'composer.json',
            'resources/js/components/ui/*',
            'resources/views/mail/*',
        ],
        sortTailwindcss: {
            functions: ['clsx', 'cn', 'cva'],
            entryPoint: 'resources/css/app.css',
        },
    },
});
```

The configuration imports `defineConfig` and `lazyPlugins` from `vite-plus`. The plugin factory remains available for development and builds, while lazy loading prevents unnecessary plugin setup when Vite+ only needs metadata for commands such as formatting and linting. This use of `lazyPlugins` follows the official [Vite+ troubleshooting guidance](https://viteplus.dev/guide/troubleshooting#slow-config-loading-caused-by-heavy-plugins).

The `lint` block enables type-aware linting and treats warnings as failures. The `fmt` block defines line width, indentation, quotes, semicolons, ignored files, and Tailwind CSS class sorting. Vite+ supports these workflow blocks in `vite.config.ts`, as documented in the official [Vite+ configuration reference](https://viteplus.dev/config/#vite-specific-configuration).

## Step 4: Install the Vite+ CLI on Linux {#step-4-install-the-vite-plus-cli-on-linux}

The project includes `vite-plus` locally, so package scripts can resolve the project-owned `vp` binary. Installing the global CLI is useful when you want to run `vp` directly from the terminal, manage Node.js versions, migrate projects, or use Vite+ outside an npm script.

On Linux, run the installation command from the official [Vite+ getting started guide](https://viteplus.dev/guide/#install-vp):

```bash
curl -fsSL https://vite.plus | bash
```

The installer asks whether Vite+ should manage Node.js versions. This test accepted that option:

```text
$ curl -fsSL https://vite.plus | bash

Setting up VITE+...

Would you like Vite+ to manage your Node.js versions?
Vite+ adds `node`, `npm`, `npx`, and `corepack` shims to ~/.local/share/vite-plus/bin.
It selects the required version automatically.
Opt out anytime with `vp env off`.
Press Enter to accept (Y/n): y

✔ VITE+ successfully installed!

  The Unified Toolchain for the Web.

  Get started:
    vp create       Create a new project
    vp env          Manage Node.js versions
    vp install      Install dependencies
    vp migrate      Migrate to Vite+

  Vite+ is now managing Node.js via vp env.
  Run vp env doctor to verify your setup, or vp env off to opt out.

  Run vp help to see available commands.

  Install locations:
    Data directory: ~/.local/share/vite-plus
    Bin directory:  ~/.local/share/vite-plus/bin

  Shell configuration:
    - zsh: skipped (not installed)
    - bash: updated ~/.bashrc, ~/.profile
    - fish: skipped (not installed)
    - nushell: skipped (not installed)

  Note: Restart your terminal to load updated shell configuration.


```

Restart the terminal so the updated shell configuration is loaded. Then verify the installation:

```text
$ vp --version
VITE+ - The Unified Toolchain for the Web

vp v0.3.0

Local vite-plus:
  vite-plus  v0.3.0

Tools:
  vite             v8.2.2
  rolldown         v1.2.5
  vitest           v4.1.11
  oxfmt            v0.64.0
  oxlint           v1.79.0
  oxlint-tsgolint  v7.0.2001
  tsdown           v0.22.14

Environment:
  Package manager  pnpm latest
  Node.js          v24.20.0

```

This output confirms two matching Vite+ versions: the global `vp` CLI and the local `vite-plus` package are both 0.3.0. It also exposes the exact versions of the tools bundled into the active environment, which makes the test reproducible.

## Step 5: Build and Check the Starter Kit {#step-5-build-and-check-the-starter-kit}

With the CLI available, return to the Laravel project and create a production build:

```bash
vp build
```

The command completes successfully and writes the compiled assets to `public/build`:

```text
$ vp build
VITE+ - The Unified Toolchain for the Web

note: You are running `vp build` as a Vite+ built-in command. If you meant to run the build npm script, use `vpr build` instead.
[plugin @laravel/vite-plugin-wayfinder] Types generated for actions, routes, form variants
[plugin laravel:fonts] Optimized font fallbacks require the optional "fontaine" package. Install it, or set "optimizedFallbacks: false" on your fonts to disable the feature.
✓ 2313 modules transformed.
computing gzip size...
public/build/fonts-manifest.json                                 5.74 kB │ gzip:  0.71 kB
public/build/manifest.json                                      12.12 kB │ gzip:  1.52 kB
public/build/assets/instrument-sans-400-normal-DRC__1Mx.woff2   16.86 kB
public/build/assets/instrument-sans-500-normal-Dk9ku72i.woff2   17.23 kB
public/build/assets/instrument-sans-600-normal-B7fBEWYG.woff2   17.40 kB
public/build/assets/instrument-sans-400-normal-D1W7dsQl.woff    21.24 kB
public/build/assets/instrument-sans-500-normal-Z6ESRlEs.woff    21.65 kB
public/build/assets/instrument-sans-600-normal-B9e8oLYv.woff    21.67 kB
public/build/assets/fonts-C9MNnjVw.css                           2.35 kB │ gzip:  0.38 kB
public/build/assets/app-DroZraM1.css                            92.27 kB │ gzip: 15.49 kB
public/build/assets/check-BreEvVnO.js                            0.12 kB │ gzip:  0.14 kB
public/build/assets/loader-circle-DZ39LaR2.js                    0.14 kB │ gzip:  0.15 kB
public/build/assets/input-error-rC5RA1qB.js                      0.26 kB │ gzip:  0.22 kB
public/build/assets/confirm-DeCs2Ne2.js                          0.36 kB │ gzip:  0.22 kB
public/build/assets/text-link-C0B4hmFa.js                        0.38 kB │ gzip:  0.26 kB
public/build/assets/spinner-DQRmZm82.js                          0.48 kB │ gzip:  0.35 kB
public/build/assets/rolldown-runtime-CbXtAM7H.js                 0.58 kB │ gzip:  0.36 kB
public/build/assets/dist-DlX3AoQd.js                             0.70 kB │ gzip:  0.48 kB
public/build/assets/label-B9hgJflx.js                            0.98 kB │ gzip:  0.62 kB
public/build/assets/verify-email-ChjN0wRH.js                     1.34 kB │ gzip:  0.72 kB
public/build/assets/verification-DBhmVDTk.js                     1.48 kB │ gzip:  0.52 kB
public/build/assets/passkey-verify-s6fjCV38.js                   1.87 kB │ gzip:  1.06 kB
public/build/assets/password-input-wGd1HBhv.js                   1.90 kB │ gzip:  1.05 kB
public/build/assets/forgot-password--rlj1WHo.js                  1.96 kB │ gzip:  0.91 kB
public/build/assets/appearance-Dkbh-Eha.js                       2.24 kB │ gzip:  1.08 kB
public/build/assets/reset-password-ChBYeWjq.js                   2.33 kB │ gzip:  0.95 kB
public/build/assets/confirm-password-CpvigK6b.js                 2.34 kB │ gzip:  1.00 kB
public/build/assets/dashboard-Gy-NGIjk.js                        2.56 kB │ gzip:  0.91 kB
public/build/assets/password-b_g3rH5l.js                         2.73 kB │ gzip:  0.73 kB
public/build/assets/two-factor-challenge-C-J41GPc.js             2.81 kB │ gzip:  1.28 kB
public/build/assets/register-BVaddoyc.js                         2.87 kB │ gzip:  1.10 kB
public/build/assets/dialog-DHJkx2yc.js                           4.10 kB │ gzip:  1.28 kB
public/build/assets/button-BvWR7hqm.js                           4.94 kB │ gzip:  2.15 kB
public/build/assets/profile-Bi1Nx1PG.js                          6.91 kB │ gzip:  2.35 kB
public/build/assets/dist-Bw5IEzJi.js                             7.02 kB │ gzip:  2.72 kB
public/build/assets/login-jIJFrUNS.js                            7.76 kB │ gzip:  3.17 kB
public/build/assets/react-Dto0LvZI.js                           13.90 kB │ gzip:  4.62 kB
public/build/assets/use-two-factor-auth-CCZmjXJD.js             17.09 kB │ gzip:  6.19 kB
public/build/assets/createLucideIcon-DBCKXCYk.js                28.28 kB │ gzip:  9.20 kB
public/build/assets/welcome-BlSo6las.js                         30.64 kB │ gzip:  6.45 kB
public/build/assets/security-CxjXJmyu.js                        31.58 kB │ gzip:  9.96 kB
public/build/assets/app-DHadqJ0x.js                            168.47 kB │ gzip: 51.46 kB
public/build/assets/wayfinder-DF0WeuwH.js                      316.89 kB │ gzip: 99.71 kB

✓ built in 2.57s

```

The informational note matters. `vp build` is a built-in Vite+ command, while `vpr build` or `vp run build` executes the script named `build` from `package.json`. Both paths happen to reach `vp build` in this starter kit, but they are not the same command resolution mechanism.

Next, run the unified project check:

```bash
vp check
```

The first check finds formatting issues:

```text
$ vp check
VITE+ - The Unified Toolchain for the Web

note: You are running `vp check` as a Vite+ built-in command. If you meant to run the check npm script, use `vpr check` instead.
error: Formatting issues found
.agents/mcp_config.json (0ms)
.agents/skills/fortify-development/SKILL.md (133ms)
.agents/skills/inertia-react-development/SKILL.md (85ms)
.agents/skills/infer-conventions/SKILL.md (100ms)
.agents/skills/infer-conventions/references/checklist.md (124ms)
.agents/skills/laravel-best-practices/SKILL.md (52ms)
.agents/skills/laravel-best-practices/rules/style.md (56ms)
.agents/skills/tailwindcss-development/SKILL.md (176ms)
.agents/skills/testing-best-practices/SKILL.md (33ms)
.agents/skills/testing-best-practices/rules/assertions.md (41ms)
.agents/skills/testing-best-practices/rules/finding-features.md (26ms)
.agents/skills/wayfinder-development/SKILL.md (211ms)
.claude/skills/fortify-development/SKILL.md (350ms)
.claude/skills/inertia-react-development/SKILL.md (349ms)
.claude/skills/infer-conventions/SKILL.md (361ms)
.claude/skills/infer-conventions/references/checklist.md (350ms)
.claude/skills/laravel-best-practices/SKILL.md (111ms)
.claude/skills/laravel-best-practices/rules/style.md (90ms)
.claude/skills/tailwindcss-development/SKILL.md (392ms)
.claude/skills/testing-best-practices/SKILL.md (78ms)
.claude/skills/testing-best-practices/rules/assertions.md (70ms)
.claude/skills/testing-best-practices/rules/finding-features.md (17ms)
.claude/skills/wayfinder-development/SKILL.md (349ms)
.mcp.json (0ms)
.pi/skills/fortify-development/SKILL.md (120ms)
.pi/skills/inertia-react-development/SKILL.md (66ms)
.pi/skills/infer-conventions/SKILL.md (148ms)
.pi/skills/infer-conventions/references/checklist.md (173ms)
.pi/skills/laravel-best-practices/SKILL.md (46ms)
.pi/skills/laravel-best-practices/rules/style.md (60ms)
.pi/skills/tailwindcss-development/SKILL.md (120ms)
.pi/skills/testing-best-practices/SKILL.md (111ms)
.pi/skills/testing-best-practices/rules/assertions.md (26ms)
.pi/skills/testing-best-practices/rules/finding-features.md (16ms)
.pi/skills/wayfinder-development/SKILL.md (165ms)
AGENTS.md (383ms)
CLAUDE.md (382ms)
boost.json (0ms)
opencode.json (10ms)

Found formatting issues in 39 files (1616ms, 8 threads). Run `vp check --fix` to fix them.

```

The important finding is that the initial formatting scope includes generated coding-agent configuration and skill files, not only application source files. The `server.watch.ignored` list controls development server watching, while `fmt.ignorePatterns` controls formatter exclusions. They serve different purposes.

Before applying an automatic fix in a project with existing work, check `git status` and commit or stash intentional changes. Then run:

```bash
vp check --fix
```

The command formats the reported files and runs the linter:

```text
$ vp check --fix
VITE+ - The Unified Toolchain for the Web

note: You are running `vp check` as a Vite+ built-in command. If you meant to run the check npm script, use `vpr check` instead.
pass: Formatting completed for checked files (4.4s)
pass: Found no warnings or lint errors in 64 files (703ms, 8 threads)

```

Review the resulting Git diff so you understand every formatting change before committing it. Finally, run the non-mutating check again:

```bash
vp check
```

The second check succeeds:

```text
$ vp check
VITE+ - The Unified Toolchain for the Web

note: You are running `vp check` as a Vite+ built-in command. If you meant to run the check npm script, use `vpr check` instead.
pass: All 185 files are correctly formatted (1631ms, 8 threads)
pass: Found no warnings or lint errors in 64 files (680ms, 8 threads)

```

The successful result confirms that the files are formatted and that the checked frontend files have no lint warnings or errors. The React starter kit still provides `npm run types:check` when you also want to run its explicit `tsc --noEmit` script.

## Step 6: Try It Out {#step-6-try-it-out}

The production build and static checks now pass. Start the full Laravel development environment from the project root:

```bash
php artisan dev
```

The Laravel 13 development interface starts the application server, queue worker, log viewer, and frontend process together. The frontend panel shows that the npm development script resolves to `vp dev`:

```text
artisan dev ·                 ~/learning-lab/laravel/laravel-13/test-new-start
╭─────────────╮╭───────────────────────────────────────────────────────────────╮
│ 1 server    ││ npm run dev                                                   │
│ 2 queue     ││───────────────────────────────────────────────────────────────│
│ 3 logs      ││ > vp dev                                                     ││
│ 4 vite      ││                                                              ││
│             ││ Inertia SSR dev endpoint: /__inertia_ssr                     ┃│
│             ││ 8:53:14 AM [vite+] (client) info: Types generated for actio… ┃│
│             ││   Plugin: @laravel/vite-plugin-wayfinder                     ┃│
│             ││ Warming up Inertia SSR module graph...                       ┃│
│             ││                                                              ┃│
│             ││   VITE+ v0.3.0                                               ┃│
│             ││                                                              ┃│
│             ││   ➜  Local:   http://localhost:5173/                         ┃│
│             ││   ➜  Network: use --host to expose                           ┃│
│             ││ [laravel:fonts] Optimized font fallbacks require the option… ┃│
│             ││                                                              ┃│
│             ││   LARAVEL v13.29.0  plugin v3.2.0                            ┃│
│             ││                                                              ┃│
│             ││   ➜  APP_URL: http://localhost:8000                          ┃│
│             ││ Inertia SSR module graph warmed up                           ┃│
│             ││                                                              ┃│
╰─────────────╯╰───────────────────────────────────────────────────────────────╯

```

Open `http://localhost:8000` in a browser. The application should display the generated React starter kit, while Vite+ serves frontend assets from `http://localhost:5173` during development.

At this point, the hands-on path is complete. The starter kit was generated, inspected, built, checked, fixed, checked again, and started locally.

## Understanding vp and vite-plus {#understanding-vp-and-vite-plus}

The name `vp` appears throughout the generated project, but Vite+ has two related parts. According to the official [Vite+ getting started guide](https://viteplus.dev/guide/#getting-started), `vp` is the global command-line tool and `vite-plus` is the local package installed in each project.

The local package pins the project's toolchain version. The global CLI gives you a command that is available from the shell and can coordinate runtimes, package managers, project creation, and migrations. The version output in this tutorial showed both parts at 0.3.0, so the global and project-local releases were aligned.

Vite+ also distinguishes built-in commands from package scripts:

```bash
vp build
vp run build
vpr build
```

The first command invokes Vite+'s built-in production build. The second and third commands run the `build` entry from `package.json`. This distinction also applies to commands such as `dev`, `test`, and `check`. The official [Vite+ command documentation](https://viteplus.dev/guide/#core-commands) explains that built-in commands cannot be overridden by scripts with the same name.

Inside the Laravel starter kit, `npm run build` remains valid because npm reads the `build` script and resolves the project-local binary from `node_modules`. Installing the global CLI is necessary for the direct terminal workflow used in this tutorial, but the project is not relying on the global installation as its only Vite+ dependency.

## What Vite+ Changes in Laravel Starter Kits {#what-vite-plus-changes-in-laravel-starter-kits}

Vite+ is not a replacement for the Laravel Vite plugin, React, Vue, Svelte, or Livewire. It is the unified entry point that coordinates the frontend toolchain around those technologies.

The official [Why Vite+ guide](https://viteplus.dev/guide/why/) lists the main components it brings together:

- Vite and Rolldown for development and application builds.
- Vitest for frontend testing.
- Oxlint and Oxfmt for linting and formatting.
- tsdown for building libraries or standalone executables.
- Vite Task for task orchestration.
- Runtime and package manager coordination through the `vp` CLI.

For Laravel's Inertia starter kits, [Laravel Maestro PR #60](https://github.com/laravel/maestro/pull/60) replaced the separate ESLint and Prettier setup with `vite-plus`, moved linting and formatting configuration into `vite.config.ts`, and consolidated the related scripts into `check` and `check:fix`. React, Vue, and Svelte retain their framework-specific type-check commands. Livewire starter kits use Vite+ for development and builds but do not add the same frontend static-check configuration.

The practical result is a consistent command vocabulary across the official starter kits. Developers can use `vp dev`, `vp check`, `vp test`, and `vp build`, while each starter kit still keeps the configuration and framework integrations it needs.

## Migrating an Existing Laravel Project {#migrating-an-existing-laravel-project}

New starter kit applications already contain the Vite+ dependency, scripts, and configuration. An existing Laravel project created before this change needs a migration instead.

From the project root, the starting command is:

```bash
vp migrate
```

The official [Vite+ migration guide](https://viteplus.dev/guide/migrate/) explains that this command can update dependencies, rewrite imports, merge tool-specific configuration into `vite.config.ts`, update scripts, format the project, and optionally configure hooks, editors, and coding-agent files.

Because migration changes multiple project files, begin with a clean Git working tree and inspect the diff afterward. The official recommended verification sequence is:

```bash
vp install
vp check
vp test
vp build
```

This tutorial did not run `vp migrate` against an older project, so the migration command is included as the official next path rather than as a tested result. Existing projects may have custom ESLint, Prettier, Vite, Vitest, or TypeScript behavior that needs manual review after the automated migration.

## Conclusion {#conclusion}

Laravel's Vite+ migration changes the frontend workflow of every newly generated official starter kit. The React test in this tutorial confirms that the integration covers project scripts, local dependencies, Vite configuration, production builds, static checks, and the local development server.

- **All official starter kits use Vite+.** Laravel merged the migration across 21 starter kit variants, including React, Vue, Svelte, and Livewire configurations.
- **The toolchain is project-aware.** The global `vp` CLI works with a local `vite-plus` package, which lets the project pin its toolchain version.
- **Frontend commands are unified.** Development, checks, tests, and builds share the `vp` command surface instead of requiring a separate command for every underlying tool.
- **Configuration lives in one central file.** The React starter kit keeps Vite plugins, lint rules, formatting preferences, ignore patterns, and Tailwind sorting in `vite.config.ts`.
- **Automatic fixes deserve review.** The first `vp check` included generated agent files, so checking Git status and reviewing the diff around `vp check --fix` is an important part of the workflow.
- **Existing applications have a migration path.** The official `vp migrate` command can convert an older Vite project, followed by installation, checks, tests, and a production build.
