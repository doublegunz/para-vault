# Laravel 13 artisan dev Command: A Complete Guide

Starting work on a Laravel project usually begins with a small ritual that has nothing to do with code. You open a terminal, then split it or spawn a second tab for `php artisan serve`, a third for `npm run dev`, a fourth for `php artisan queue:listen`, and a fifth if you want `php artisan pail` tailing your logs. Five panes before you have written a single line.

The cost is not the typing; it is everything that follows. Half an hour in, you no longer remember which pane holds which process, so finding an error means clicking through all of them. When you close your editor and walk away, one or two of those processes survive as orphans and quietly hold onto port 8000, which you discover tomorrow morning when `serve` refuses to start. Onboarding a new teammate means writing the whole ritual down in the README and hoping they follow it in the right order.

Laravel 13 replaces the ritual with one command. `php artisan dev` starts every process your project needs for local development, labels each one, and shuts them all down together when you quit. This guide walks through using it, customizing which processes it runs, and moving over from the `composer run dev` script that came before it. If you followed [How to Use Composer Run Dev in Laravel 11](https://qadrlabs.com/post/cara-menggunakan-composer-run-dev-di-laravel-11), this is the direct successor to that setup, and it was first announced among the other additions in [What's New in Laravel 13.16.0](https://qadrlabs.com/post/whats-new-in-laravel-13160-artisan-dev-whenenum-and-flexible-json-schema-validation#artisan-dev-command).

## Overview {#overview}

The `dev` command is registered by the framework itself, so there is nothing to install and nothing to configure before your first run. Out of the box it starts four processes concurrently. What makes it worth a full guide is the second half of the story: the process list is defined in PHP through a class called `DevCommands`, which means you can add your own processes, replace the defaults, color them, and filter them per machine using ordinary code inside a service provider.

One detail matters before you begin, because it changes what you see on screen. The `dev` command arrived in Laravel 13.16.0 running on the `concurrently` npm package. In Laravel 13.25.0, released on 11 August 2026, the engine was replaced with `@laravel/multiplex`, which renders a genuine terminal UI with one tab per process, searchable and scrollable output, and automatic restarts. Everything in this guide was run against Laravel 13.25.0.

### What You'll Build

A fresh Laravel 13 project whose development environment starts from a single command, with a customized process list that runs the HTTP server on port 9000 instead of the default, adds the task scheduler and a log tail as named and color coded processes, and excludes the queue worker. You will verify the whole configuration with `php artisan dev:list` before running it, then confirm the running result by hitting the application in a browser.

### What You'll Learn

- How to run `php artisan dev` and what its four default processes actually are, taken from the framework source rather than the documentation.
- How to register your own processes with `DevCommands::register()`, `::artisan()`, `::node()`, and `::nodeExec()`, and when each one is the right choice.
- How to replace a default process, such as changing the development server port, by registering a process under the same name.
- How to color process labels using the six named methods or a custom hex value.
- How to inspect the registered process list without starting anything, using `php artisan dev:list`.
- How to filter which processes run with `DevCommands::only()` and `DevCommands::except()`, including conditionally per machine.
- How the command behaves under the hood: the multiplex UI, the `pcntl_fork` requirement for log tailing, process priority ordering, and package manager detection.
- How to migrate an existing `composer run dev` setup, and why you may not need to change your muscle memory at all.

### What You'll Need

- PHP 8.3 or newer. The output in this guide was produced on PHP 8.5.6.
- Laravel 13.25.0 or newer. The command exists from 13.16.0, but the tabbed UI shown here arrived in 13.25.0.
- Node 22.13 or newer, which is required for the multiplex UI. This guide used Node v22.15.1 and npm 10.9.2.
- Composer 2.x. This guide used Composer 2.10.0.
- macOS or Linux for the tabbed interface. Windows works, but falls back to `concurrently` without tabs.
- Basic familiarity with Laravel service providers, since all customization happens inside `AppServiceProvider::boot()`.
- Optional background reading: [How to Use Composer Run Dev in Laravel 11](https://qadrlabs.com/post/cara-menggunakan-composer-run-dev-di-laravel-11).

## Step 1: Set Up the Laravel 13 Project {#step-1-set-up-the-project}

Before creating anything, confirm your Node version, because it determines which interface you get:

```bash
node -v
```

If this prints anything below `v22.13`, the `dev` command still works but silently falls back to `concurrently`, and the tabs described later in this guide will not appear.

Now create the project:

```bash
laravel new dev-command-demo --no-interaction --database=sqlite --pest --no-boost
cd dev-command-demo
```

This creates a Laravel 13 project configured with SQLite and Pest, skipping the interactive prompts. SQLite keeps the setup light since this guide does not touch the database, and the `--no-interaction` flag means the installer picks sensible defaults without asking about starter kits.

Next, install the JavaScript dependencies:

```bash
npm install
```

This step is not optional. The `@laravel/multiplex` package that renders the `dev` command interface is installed here, alongside Vite. Skipping it leaves the `vite` process unable to start and removes the tabbed UI entirely.

Confirm the framework version, since the interface described in this guide depends on it:

```bash
php artisan --version
```

The result should look like this:

```
Laravel Framework 13.25.0
```

Anything at 13.25.0 or above will match this guide. Between 13.16.0 and 13.24.x the command is present but runs on the older engine.

It is worth opening `package.json` to see how Laravel hedges its bets here:

```json
"devDependencies": {
    "@tailwindcss/vite": "^4.0.0",
    "concurrently": "^10.0.3",
    "laravel-vite-plugin": "^3.1",
    "tailwindcss": "^4.0.0",
    "vite": "^8.0.0"
},
"optionalDependencies": {
    "@laravel/multiplex": "^0.4.1"
}
```

Two things stand out. `@laravel/multiplex` sits under `optionalDependencies` rather than `devDependencies`, which means a failed install on an unsupported platform will not break `npm install` for the whole project. Meanwhile `concurrently` remains a regular dev dependency specifically because it is the fallback engine when multiplex cannot run. The framework ships both paths deliberately.

## Step 2: Run the Dev Command with Its Defaults {#step-2-run-the-dev-command}

Before starting anything, you can inspect exactly what is registered. The `dev:list` command prints the process list without launching a single process, which makes it the safest way to understand your current configuration:

```bash
php artisan dev:list
```

On a fresh project the output is:

```
 server php artisan serve .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 queue php artisan queue:listen --tries=1 --timeout=0 .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 logs php artisan pail --timeout=0 .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [4] dev commands
```

Each line shows three things: the process name, the command it will run, and the class and method that registered it. That last column becomes valuable once you start adding your own processes, because it tells you exactly where any given entry came from.

Summarized, the four defaults are:

| Name | Command |
| --- | --- |
| `server` | `php artisan serve` |
| `queue` | `php artisan queue:listen --tries=1 --timeout=0` |
| `logs` | `php artisan pail --timeout=0` |
| `vite` | `npm run dev` |

There is a discrepancy worth flagging here. The official documentation lists the `server` process as `php artisan serve --host=localhost`, but both the `dev:list` output above and the framework source show plain `php artisan serve` with no host option. You can confirm this yourself by opening `vendor/laravel/framework/src/Illuminate/Foundation/DevCommands.php` and reading the `registerDefaults()` method, which is also where you will find that the `logs` process is wrapped in a `function_exists('pcntl_fork')` check. Where the documentation and the source disagree, the source is what runs.

Now start everything:

```bash
php artisan dev
```

Running it produces the following, captured from a real run:

```
  vite │ 
  vite │ > dev
  vite │ > vite
  vite │ 
 queue │ 
 queue │  INFO Processing jobs from the [default] queue. 
 queue │ 
  logs │ 
  logs │  INFO Tailing application logs. Press Ctrl+C to exit 
  logs │  Use -v|-vv to show more details 
server │ 
server │  INFO Server running on [http://127.0.0.1:8000]. 
server │ 
server │  Press Ctrl+C to stop the server
server │ 
  vite │ 
  vite │   VITE v8.2.1  ready in 2031 ms
  vite │ 
  vite │   ➜  Local:   http://localhost:5173/
  vite │   ➜  Network: use --host to expose
  vite │ 
  vite │   LARAVEL v13.25.0  plugin v3.2.0
  vite │ 
  vite │   ➜  APP_URL: http://localhost:8000
  vite │ [laravel:fonts] Optimized font fallbacks require the optional "fontaine" package. Install it, or set "optimizedFallbacks: false" on your fonts to disable the feature.
```

Every line carries the name of the process that emitted it, so interleaved output from four programs stays readable. The HTTP server is on port 8000, Vite on port 5173, the queue worker is polling, and Pail is tailing.

That output is the command's inline mode, which Laravel selects automatically whenever output is redirected to a file or the process is not attached to an interactive terminal. It was used here so the text could be reproduced exactly. Running the same command directly in a terminal gives you the tabbed interface instead, covered later in this guide.

## Step 3: Customize Processes with DevCommands {#step-3-customize-processes}

The default four are useful, but the reason this command replaced a `composer.json` script is what happens when you need a fifth. Previously that meant editing a single long shell string embedded in JSON, with no autocompletion, no static analysis, and no way to apply any logic. Now the list is built in PHP.

Open `app/Providers/AppServiceProvider.php` and replace its contents with the following:

```php
<?php

namespace App\Providers;

use Illuminate\Foundation\DevCommands;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Registering under the name of an existing default replaces it,
        // which is how you change the development server port.
        DevCommands::artisan('serve --host=localhost --port=9000', 'server');

        // artisan() prefixes the command with "php artisan" automatically.
        DevCommands::artisan('schedule:work', 'scheduler')->orange();

        // nodeExec() prefixes with the package manager's exec command, so "npx".
        DevCommands::nodeExec(
            'tailwindcss -i resources/css/app.css -o public/css/app.css --watch',
            'tailwind'
        )->green();

        // register() adds no prefix; the command runs exactly as written.
        DevCommands::register('tail -f storage/logs/laravel.log', 'tail')->color('#ff6347');
    }
}
```

Save the file. There are four distinct registration methods in play, and choosing correctly between them is most of the learning curve.

`DevCommands::artisan()` prefixes your string with `php artisan`, which is why the scheduler entry needs only `schedule:work`. `DevCommands::node()`, not used above, prefixes with the detected package manager's run command, so `DevCommands::node('storybook', 'storybook')` becomes `npm run storybook`; this is the method the framework itself uses to register the default `vite` process. `DevCommands::nodeExec()` prefixes with the exec command instead, normally `npx`, which suits one off binaries like the Tailwind CLI. `DevCommands::register()` applies no prefix at all and runs the string verbatim, making it the correct choice for anything outside the Laravel and Node ecosystems, such as `stripe listen` for webhook forwarding.

The second argument in each call is the process name, which becomes the tab label. It is technically optional, and Laravel will derive one from the first word of your command if you omit it. Passing it explicitly is still worth the few extra characters, because two unnamed commands beginning with the same word would otherwise collide.

Colors are applied by chaining off the returned object. Six named methods are available: `blue()`, `purple()`, `pink()`, `orange()`, `green()`, and `yellow()`. For anything else, `color()` accepts a six digit hex value as shown on the `tail` process. Three digit shorthand such as `#fff` is rejected rather than expanded.

Now verify the result without starting anything:

```bash
php artisan dev:list
```

The output is:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 scheduler php artisan schedule:work .. App\Providers\AppServiceProvider@boot
 tailwind npx tailwindcss -i resources/css/app.css -o public/css/app.css --watch .. App\Providers\AppServiceProvider@boot
 tail tail -f storage/logs/laravel.log .. App\Providers\AppServiceProvider@boot
 queue php artisan queue:listen --tries=1 --timeout=0 .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 logs php artisan pail --timeout=0 .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [7] dev commands
```

This single output confirms four separate behaviors at once. The total is seven rather than eight, proving that registering `server` replaced the default instead of duplicating it, and the surviving `server` row carries the custom port. The right hand column distinguishes your registrations, attributed to `App\Providers\AppServiceProvider@boot`, from the framework's, attributed to `Illuminate\Foundation\Providers\ArtisanServiceProvider@boot`. Your processes are sorted above the defaults rather than appended. Finally, `nodeExec()` resolved to a real `npx` invocation, while the default `vite` process stayed on `npm run dev` because this project uses npm.

## Step 4: Filter Processes with only and except {#step-4-filter-processes}

Not every session needs every process. Working purely on front end markup makes the queue worker and log tailer noise, and on a constrained machine they are noise that costs battery. Two methods control this, and both go in the same `boot()` method after your registrations.

Add the following line at the end of `boot()`:

```php
DevCommands::except('queue', 'logs');
```

Save the file and run `php artisan dev:list` again:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 scheduler php artisan schedule:work .. App\Providers\AppServiceProvider@boot
 tailwind npx tailwindcss -i resources/css/app.css -o public/css/app.css --watch .. App\Providers\AppServiceProvider@boot
 tail tail -f storage/logs/laravel.log .. App\Providers\AppServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [5] dev commands
```

The count drops from seven to five, and the two named processes are gone. `except()` works subtractively, running everything that was registered apart from the names you list.

Now change that line to its inverse:

```php
DevCommands::only('server', 'vite');
```

Save and run `php artisan dev:list` once more:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [2] dev commands
```

Only the two named processes survive. Note that `only()` does not privilege your own registrations: `scheduler`, `tailwind`, and `tail` were all filtered out despite being defined by you, because filtering happens on names alone after the full list is assembled.

Because this is PHP rather than a JSON string, the filter can be conditional. A common pattern is letting each developer opt into a lighter setup through their own environment file:

```php
if (env('DEV_LIGHT_MODE', false)) {
    DevCommands::only('server', 'vite');
}
```

With `DEV_LIGHT_MODE=true` in a given machine's `.env`, that machine runs a two process setup while everyone else on the team gets the full list from the same committed code. This kind of per machine branching was effectively impossible when the process list lived as a static string in `composer.json`.

## Step 5: Try It Out {#step-5-try-it-out}

Time to run the finished configuration. Replace the `boot()` method with a realistic setup: the server on a custom port, the scheduler and a log tail as extra processes, and the queue worker excluded since this project has no jobs to process.

```php
public function boot(): void
{
    DevCommands::artisan('serve --host=localhost --port=9000', 'server');

    DevCommands::artisan('schedule:work', 'scheduler')->orange();

    DevCommands::register('tail -f storage/logs/laravel.log', 'tail')->color('#ff6347');

    DevCommands::except('queue');
}
```

Save the file, then confirm the list before launching:

```bash
php artisan dev:list
```

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 scheduler php artisan schedule:work .. App\Providers\AppServiceProvider@boot
 tail tail -f storage/logs/laravel.log .. App\Providers\AppServiceProvider@boot
 logs php artisan pail --timeout=0 .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [5] dev commands
```

Five processes, the queue worker absent, and the server carrying port 9000. Now start them:

```bash
php artisan dev
```

The captured output is:

```
     vite │ 
     vite │ > dev
     vite │ > vite
     vite │ 
scheduler │ 
scheduler │  INFO Running scheduled tasks. 
scheduler │ 
     logs │ 
     logs │  INFO Tailing application logs. Press Ctrl+C to exit 
     logs │  Use -v|-vv to show more details 
     vite │ 
     vite │   VITE v8.2.1  ready in 226 ms
     vite │ 
     vite │   ➜  Local:   http://localhost:5173/
     vite │   ➜  Network: use --host to expose
     vite │ [laravel:fonts] Optimized font fallbacks require the optional "fontaine" package. Install it, or set "optimizedFallbacks: false" on your fonts to disable the feature.
     vite │ 
     vite │   LARAVEL v13.25.0  plugin v3.2.0
     vite │ 
     vite │   ➜  APP_URL: http://localhost:8000
   server │ 
   server │  INFO Server running on [http://localhost:9000]. 
   server │ 
   server │  Press Ctrl+C to stop the server
   server │ 
   server │  2026-08-15 19:45:41 / .. ~ 505.59ms
```

Three things confirm the configuration took effect. The `server` line reports `http://localhost:9000` rather than the default port, so the process replacement from Step 3 worked. The `scheduler` process reports `Running scheduled tasks.`, so the added process is live. No line is labeled `queue`, so `except()` filtered it as intended.

The final line is the verification that matters most. `2026-08-15 19:45:41 / .. ~ 505.59ms` is the access log entry produced by opening `http://localhost:9000` in a browser, which returned HTTP 200 and rendered the Laravel welcome page. The whole environment came up from one command.

To stop everything, press `q` in the tabbed interface or `Ctrl+C` in inline mode. Either way all five processes terminate together, which removes the orphaned process problem described at the start of this guide.

## How the Dev Command Works Under the Hood {#how-the-dev-command-works}

Understanding the mechanics helps when behavior differs between machines on the same team, which with this command it often will.

The process list is assembled at boot time. `Illuminate\Foundation\Providers\ArtisanServiceProvider` calls `DevCommands::registerDefaults()`, which immediately returns unless the application is running in console context. That guard is why calling `DevCommands::register()` from a shared `AppServiceProvider::boot()` costs nothing during ordinary web requests; the registration simply does not happen outside Artisan.

Inside `registerDefaults()`, the `logs` process is conditional:

```php
if (function_exists('pcntl_fork')) {
    self::artisan('pail --timeout=0', 'logs');
}
```

The `pcntl` extension is typically unavailable on Windows and is sometimes disabled on shared hosting PHP builds. On those systems the `logs` process is never registered at all, so a teammate reporting three processes instead of four is seeing correct behavior rather than a broken install.

Ordering is not alphabetical or registration based. The class assigns each entry one of three priorities: `PRIORITY_DEFAULT` for framework registrations, `PRIORITY_VENDOR` for anything registered from a file inside `vendor/`, and `PRIORITY_USERLAND` for your own application code. Laravel determines which applies by walking the call stack and inspecting the file that made the call, which is why your processes consistently sort above the defaults without you doing anything.

Package manager detection happens on the `node()` and `nodeExec()` methods rather than being configured. Laravel looks for lock files to decide what to run, so a project containing `pnpm-lock.yaml` resolves `DevCommands::node('dev', 'vite')` to `pnpm run dev` while an npm project resolves the identical call to `npm run dev`. If you are considering switching, we covered the alternative in [How to Use Bun in Laravel](https://qadrlabs.com/post/cara-menggunakan-bun-di-laravel-package-manager-alternatif-npm).

The rendering layer is where 13.25.0 changed most. `@laravel/multiplex` requires Node 22.13 or later and an interactive terminal, meaning both stdin and stdout must be a TTY and the window must be at least 26 columns by 8 rows. When any of those conditions fail, multiplex falls back to inline mode rather than erroring, which is exactly what produced the copyable output used throughout this guide.

One constraint deserves attention because it will bite eventually: child processes are spawned without stdin. Anything that prompts for input cannot run as a dev process. `php artisan tinker` will not work, and neither will a migration that stops to ask for confirmation. Commands registered here need to be non-interactive.

## Keyboard Shortcuts and Display Modes {#keyboard-shortcuts-and-display-modes}

When the tabbed interface is active, the command is interactive rather than a passive log dump. Each process occupies its own tab with an independently scrollable and searchable buffer, and quitting flushes the combined output back into your terminal scrollback so nothing is lost.

The keys below come from the README of `@laravel/multiplex` version 0.4.2, the version installed in this project:

| Key | Action |
| --- | --- |
| `1` to `9` | Jump directly to a tab by number |
| `Tab` | Toggle focus between the sidebar and content |
| `Up` / `Down` or `j` / `k` | Move between tabs, or scroll the content |
| `Page Up` / `Page Down` | Scroll one page |
| `g` / `G` | Jump to the top or bottom of the buffer |
| `r` | Restart the selected process |
| `c` | Clear the current tab's output |
| `/` | Open search, then `n` and `N` to move between matches |
| `f` | Filter which commands appear in the stream |
| `s` | Switch to stream mode |
| `t` | Switch back to tabbed mode |
| `q` | Quit and stop every process |

The `r` key is the most immediately useful of these. Restarting a single misbehaving Vite process no longer requires tearing down and restarting your entire environment.

Crash handling is automatic by default. A process that dies is restarted after a short delay, up to five attempts, before being marked as failed. A process that dies within one second of starting is not restarted, on the assumption that it never started successfully in the first place, and restarting manually with `r` resets the counter.

The command exposes these behaviors as flags too, which you can inspect with `php artisan help dev`:

```
Options:
  -s, --stream                                   Start in stream mode
  -t, --tabs                                     Start in tabs mode
  -i, --inline                                   Print output inline instead of rendering the TUI (the default when not a TTY)
      --timestamps                               Display timestamps on each output line
      --no-restart                               Disable auto-restart on crash
      --json                                     Emit newline-delimited JSON events. Implies --inline
      --buffer-size[=BUFFER-SIZE]                Set the max lines per command buffer
      --stream-buffer-size[=STREAM-BUFFER-SIZE]  Set the max lines in the stream buffer
```

Anything you can pass as a flag can also be made the default for your project from the same service provider, using `DevCommands::stream()`, `DevCommands::tabs()`, `DevCommands::inline()`, `DevCommands::withTimestamps()`, `DevCommands::disableAutoRestart()`, or `DevCommands::bufferSize()`. The `--json` flag is the one worth remembering for automation, since it emits newline delimited events describing process starts, output lines, exits, and restarts, which is a reasonable foundation for a CI wrapper.

## Migrating from composer run dev {#migrating-from-composer-run-dev}

If your project predates Laravel 13.16.0, `composer run dev` remains correct and there is no reason to feel behind. The Artisan command simply does not exist on Laravel 11 or 12. When you are ready to move, the upgrade itself is covered in [How to Upgrade Laravel 12 to Laravel 13](https://qadrlabs.com/post/how-to-upgrade-laravel-12-to-laravel-13-a-step-by-step-guide).

The two approaches compare as follows:

| Aspect | `composer run dev` | `php artisan dev` |
| --- | --- | --- |
| Process list location | A shell string inside `composer.json` | PHP code in a service provider |
| Autocompletion and static analysis | Unavailable | Available |
| Engine | `concurrently` | `@laravel/multiplex` since 13.25.0 |
| Output presentation | Color labeled interleaved lines | One tab per process, scrollable and searchable |
| Restart a single process | Not supported | Supported with `r` |
| Automatic restart on crash | Not supported | Enabled by default |
| Conditional or per machine filtering | Effectively impossible | `only()` and `except()`, with full PHP logic |
| Node requirement | None | 22.13 or later for the tabbed UI |

Here is the part that removes most of the migration pressure. A fresh Laravel 13 project still ships a `dev` script, but it now delegates:

```json
"scripts": {
    "dev": [
        "Composer\\Config::disableProcessTimeout",
        "@php artisan dev"
    ]
}
```

Typing `composer run dev` on Laravel 13 therefore runs the Artisan command and gives you the full tabbed experience. Existing habits, README instructions, and CI scripts referencing `composer run dev` keep working untouched.

What does need attention is a customized script carried over from Laravel 11, which typically looks like this:

```json
"scripts": {
    "dev": [
      "Composer\\Config::disableProcessTimeout",
      "npx concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail\" \"npm run dev\" --names=server,queue,logs,vite"
    ]
}
```

Left in place, this block keeps invoking `concurrently` directly, so the project never reaches the new interface regardless of its Laravel version. Replace it with the two line delegating version above, then move the customizations into `AppServiceProvider::boot()` using this mapping:

| Old `composer.json` construct | New `DevCommands` equivalent |
| --- | --- |
| One command string inside `concurrently` | One `DevCommands::register()` or `::artisan()` call |
| `--names=server,queue,logs,vite` | The second argument of each registration |
| `-c "#93c5fd,#c4b5fd,..."` | A color method such as `->orange()` or `->color('#93c5fd')` |
| Removing a command from the string | `DevCommands::except('name')` |
| Maintaining separate scripts per developer | A conditional wrapping `only()` or `except()` |

A Reverb server previously wedged into that string, for instance, becomes a single readable line:

```php
DevCommands::artisan('reverb:start', 'reverb')->purple();
```

One safeguard is worth knowing if you maintain packages. Calling `DevCommands::register()` from a file inside `vendor/` throws an exception, so a package cannot silently attach processes to your development environment. A package may expose a helper that your own service provider calls explicitly, but the registration has to originate from your application code.

## Conclusion {#conclusion}

The `dev` command does not do anything you could not already accomplish with four terminal tabs and some discipline. What changed is where the definition lives. Moving the process list out of a JSON string and into PHP turned local environment setup into ordinary, reviewable, conditional code that ships with the repository, and the multiplex interface added in 13.25.0 turned the combined output into something you can actually navigate.

- **`php artisan dev` starts four processes by default.** The real defaults, read from `registerDefaults()`, are `php artisan serve`, `php artisan queue:listen --tries=1 --timeout=0`, `php artisan pail --timeout=0`, and `npm run dev`, and the documented `--host=localhost` on the server process does not match what ships in 13.25.0.
- **`dev:list` is the safe way to inspect configuration.** It prints every registered process, its resolved command, and the class that registered it, without launching anything.
- **Choose your registration method by prefix.** `artisan()` prepends `php artisan`, `node()` prepends the detected package manager's run command, `nodeExec()` prepends its exec command, and `register()` prepends nothing.
- **Registering a duplicate name replaces rather than duplicates.** This is the supported way to change the development server port or otherwise override a framework default.
- **`only()` and `except()` filter by name after the list is built.** They apply to your own processes as readily as to the defaults, and because they are PHP they can be wrapped in per machine conditionals.
- **The `logs` process depends on `pcntl_fork`.** Teammates on Windows or a PHP build without `pcntl` will see three processes rather than four, which is expected behavior and not a misconfiguration.
- **The tabbed UI requires Node 22.13 and a real TTY.** Without either, the command falls back to inline mode instead of failing, which also makes inline mode the right choice for CI and for capturing output.
- **Dev processes must be non-interactive.** Children are spawned without stdin, so anything that prompts, including `php artisan tinker`, cannot be registered as a dev process.
- **Migration is optional in the short term.** Laravel 13's `composer.json` still defines a `dev` script that forwards to `@php artisan dev`, so only a customized legacy script actually needs rewriting.
