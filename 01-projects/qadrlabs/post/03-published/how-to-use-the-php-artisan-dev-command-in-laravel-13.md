---
title: "How to Use the php artisan dev Command in Laravel 13"
slug: "how-to-use-the-php-artisan-dev-command-in-laravel-13"
category: "Laravel"
date: "2026-08-15"
status: "draft"
---

There is an old habit you might recognize. Every time I start working on a Laravel project, the first thing I open is not my text editor, it is the terminal. Then a new tab. Then another one. One tab for `php artisan serve`, one for `npm run dev`, one for the queue worker, and one more to watch the logs. Four tabs, all running, and half an hour later I have completely forgotten what tab number three was for. When something breaks, the ritual becomes clicking through them one by one, guessing.

That problem already had an answer once: `composer run dev`, which we covered back in [How to Use Composer Run Dev in Laravel 11](https://qadrlabs.com/post/cara-menggunakan-composer-run-dev-di-laravel-11). One command, four processes, done. Then Laravel 13.16.0 shipped, and while writing up the highlights in [What's New in Laravel 13.16.0](https://qadrlabs.com/post/whats-new-in-laravel-13160-artisan-dev-whenenum-and-flexible-json-schema-validation#artisan-dev-command) one new command made me pause: `php artisan dev`.

And there it was, the question. *"Hold on, if `composer run dev` already exists, why build an Artisan command that does the same job? What is actually different? And do I need to move my old projects over?"*

The answer turned out to be more interesting than I expected, especially after Laravel 13.25.0 landed a few days ago and swapped out the engine behind this command entirely. That curiosity is what turned into this tutorial.

## Overview{#overview}

In this tutorial we'll dig into the practical side of the `php artisan dev` command in **Laravel 13**. We start by spinning up a fresh Laravel 13 project, running the command, and getting to know the four default processes it fires up at once. After that we'll reshape that process list ourselves through the `DevCommands` class in `AppServiceProvider`, give each process a color, change the server port, and filter down which ones actually run using `only` and `except`.

Here is the fun part. Since **Laravel 13.25.0**, released on 11 August 2026, this command no longer runs on the `concurrently` npm package the way `composer run dev` did. It now uses `@laravel/multiplex`, a real terminal UI with a tab per process, built in search, and automatic restarts when a process dies. So if you happened to read my 13.16.0 write up mentioning `concurrently`, that part has already aged. :)

In the last step before we test everything, we'll also walk through moving from `composer run dev` to `php artisan dev`, specifically for friends whose projects are still on Laravel 11 or 12.

Every piece of terminal output in this tutorial comes straight from a real run on my machine, unedited, so you can compare it against what you get on yours. So what are the steps? *Check this out!*

**Table of Contents**
- [Overview](#overview)
- [Step 1 - Preparing the Development Environment](#step-1-preparing-development)
- [Step 2 - Running php artisan dev for the First Time](#step-2-running-artisan-dev)
- [Step 3 - Customizing Processes with DevCommands](#step-3-customizing-devcommands)
- [Step 4 - Filtering Processes with only and except](#step-4-filtering-processes)
- [Step 5 - Migrating from composer run dev to php artisan dev](#step-5-migrating)
- [Step 6 - Try It Out](#step-6-try-it-out)
- [Wrap Up](#wrap-up)
- [References](#references)

## Step 1 - Preparing the Development Environment {#step-1-preparing-development}

Before we start, let's say a little prayer so the coding goes smoothly. :)

Done?

Alright, let's check our tools first. Here are the specs on my machine at the time of writing:

1. PHP 8.5.6
2. Node v22.15.1
3. npm 10.9.2
4. Composer 2.10.0
5. Laravel Installer 5.31.0
6. macOS

There is one requirement here that really matters and you should not skip it: **`php artisan dev` needs Node 22.13 or later** to render its tabbed UI. If your Node is older than that, or you are on Windows, Laravel quietly falls back to the old `concurrently` package and the tabs never show up. Everything still works, the interface is just plainer. So before going further, check this:

```bash
node -v
```

If your Node is good to go, let's create the project. Move into your working folder and type:

```bash
laravel new dev-command-demo
```

If you prefer Composer directly, that works too:

```bash
composer create-project laravel/laravel dev-command-demo
```

The command above downloads and sets up a fresh Laravel project in a folder named `dev-command-demo`. If the Laravel Installer asks about a starter kit or a testing framework, just pick the simplest option, since our focus here is the `dev` command itself rather than any particular feature.

Next, move into the project folder and install the JavaScript dependencies:

```bash
cd dev-command-demo
npm install
```

That `npm install` step is mandatory. The `@laravel/multiplex` package that powers the `php artisan dev` interface gets installed from here. Skip it and the `vite` process will error out, and the tabbed UI will never appear.

Now let's confirm the Laravel version:

```bash
php artisan --version
```

On my machine the result is:

```
Laravel Framework 13.25.0
```

Make sure yours reads **13.25.0 or newer**. Why? Because the `@laravel/multiplex` tabbed UI only arrived in this release. If you are anywhere between 13.16 and 13.24, the `php artisan dev` command still exists and still works fine, but it runs on `concurrently` and looks different from what you'll see here.

We can also peek inside `package.json` to see exactly which packages Laravel installed:

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

Interesting, right? `@laravel/multiplex` is listed under `optionalDependencies` rather than as a hard dependency. That means if it fails to install on your machine, say because your Node is too old, `npm install` does not fail along with it. And `concurrently` is still sitting in `devDependencies` precisely because it is the backup plan when multiplex cannot run. Laravel prepared a plan B from the start. :D

## Step 2 - Running php artisan dev for the First Time {#step-2-running-artisan-dev}

Setup is out of the way, so here comes the part we've been waiting for. Let's run the command and see what happens. Type this in your terminal:

```bash
php artisan dev
```

That's all. No configuration, no flags, nothing else to prepare. From this single command Laravel spins up four processes at once inside one terminal window.

Before we look at the result, let's get acquainted with who exactly is being started. The four defaults are:

| Name | Command |
| --- | --- |
| `server` | `php artisan serve` |
| `queue` | `php artisan queue:listen --tries=1 --timeout=0` |
| `logs` | `php artisan pail --timeout=0` |
| `vite` | `npm run dev` |

I pulled this list straight from the framework source at `vendor/laravel/framework/src/Illuminate/Foundation/DevCommands.php`, in the `registerDefaults()` method. Why mention that? Because the official documentation still lists the `server` process as `php artisan serve --host=localhost`, while what actually gets registered in 13.25.0 is plain `php artisan serve` with no `--host` option. When the docs and the source disagree, trust the source. :)

There is one more detail that rarely gets mentioned. The `logs` process is only registered **if the `pcntl_fork()` function is available** in your PHP installation. That extension is typically inactive on Windows, so do not be surprised if `logs` never shows up there and you only get three processes. That is not a bug, it is by design.

Now, the result on my machine. Here is the real output:

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

Look at the far left. Every output line is labeled with the name of the process it came from, so you immediately know who is talking. The server is on `http://127.0.0.1:8000`, Vite on `http://localhost:5173`, the queue worker is waiting for jobs, and Pail has started watching the logs. All from one terminal. *yay!*

**Note:** the output above is **inline mode**, which Laravel switches to automatically when output is redirected to a file or running in CI. I used it on purpose so I could copy the text into this article intact. When you run it in a normal terminal, you won't see stacked lines like this, you'll get the much tidier tabbed UI instead.

\* \* \*

Speaking of that tabbed UI, this is the new bit in Laravel 13.25.0. Every process gets its own tab in the sidebar, its output can be scrolled and searched, and you can restart a single process without disturbing the others. When you quit, the whole output is flushed back into your terminal scrollback, so your logs do not just vanish.

Here are the keys I reach for most often:

| Key | Action |
| --- | --- |
| `1` through `9` | Jump to a tab by number |
| `Up` / `Down` or `j` / `k` | Move between tabs, or scroll the content |
| `g` / `G` | Jump to the top / bottom |
| `r` | Restart the selected process |
| `c` | Clear the output of the current tab |
| `/` | Open search |
| `s` | Switch to stream mode (all output in one feed) |
| `t` | Switch back to tabbed mode |
| `q` | Quit |

I took this list from the README of the `@laravel/multiplex` package version 0.4.2 installed in `node_modules`, so it matches what actually runs in this project.

That `r` key is a lifesaver, by the way. It used to be that when Vite threw a tantrum I had to kill everything and start over from scratch. Now I just select the `vite` tab, hit `r`, and only that process is reborn. :)

Oh, and if a process crashes, Laravel restarts it automatically after a short delay. When you don't want that behavior, for example while debugging why a process keeps dying, turn it off with this flag:

```bash
php artisan dev --no-restart
```

## Step 3 - Customizing Processes with DevCommands {#step-3-customizing-devcommands}

So far `php artisan dev` doesn't feel all that different from `composer run dev`. Both start four processes, right? Well, the difference shows up the moment you want to add a process of your own.

Back in the `composer run dev` days, adding a process meant editing one long string inside `composer.json`. No autocompletion, no static analysis, and a single misplaced quote could break the whole script. Now the list is written in PHP, in a sensible place: a service provider.

Let's try it. Open `app/Providers/AppServiceProvider.php` in your favorite text editor and change it to look like this. *Type this code!*

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
        DevCommands::artisan('serve --host=localhost --port=9000', 'server');

        DevCommands::artisan('schedule:work', 'scheduler')->orange();

        DevCommands::nodeExec(
            'tailwindcss -i resources/css/app.css -o public/css/app.css --watch',
            'tailwind'
        )->green();

        DevCommands::register('tail -f storage/logs/laravel.log', 'tail')->color('#ff6347');
    }
}
```

Don't forget to save the file by pressing `ctrl+s`.

Now let's break it down, because there are four different registration styles in there and each has its own purpose.

**`DevCommands::artisan()`** automatically prefixes whatever you pass it with `php artisan`. That is why running the scheduler only needs `schedule:work` rather than the full `php artisan schedule:work`. The first line uses this method too, but there is a trick hiding in it that we'll get to shortly.

**`DevCommands::nodeExec()`** prefixes the command with the *exec* command of your detected package manager, so usually `npx`. Its sibling is **`DevCommands::node()`**, which prefixes with the *run* command instead, so `npm run`. For example `DevCommands::node('storybook', 'storybook')` runs as `npm run storybook`. That is also how Laravel registers the default `vite` process we saw earlier.

**`DevCommands::register()`** adds no prefix at all. Your command runs exactly as you typed it, as if you had entered it in the terminal yourself. That makes it the right pick for anything outside the Laravel and Node ecosystems, like running `stripe listen` to catch webhooks, or in our case, a humble `tail -f` on the log file.

That second argument in each method is the **process name**, which becomes the tab label in your terminal. It is technically optional, and if you leave it out Laravel guesses one from the first word of your command. My advice though: write it explicitly. It reads better, and it saves you from name collisions when two commands happen to start with the same word.

\* \* \*

About colors, you'll notice `->orange()` and `->green()` in the code above. There are six color methods available: `blue()`, `purple()`, `pink()`, `orange()`, `green()`, and `yellow()`. If none of those suit your terminal theme, use `->color()` and pass a six digit hex value, like the `tail` process above does. Worth noting: the hex has to be the full six digits. Shorthand like `#fff` is rejected.

Now for my favorite part. Take another look at that first line:

```php
DevCommands::artisan('serve --host=localhost --port=9000', 'server');
```

We registered a process named `server`, even though Laravel already has a default process with exactly that name. So what happens? Do we end up with two of them fighting over a port?

Nope. When you register a process using the same name as a default one, yours **replaces** it. So this is the official way to change the development server port without touching anything beyond this single line. Tidy, isn't it? :D

To confirm everything registered correctly, we don't even need to start the processes. There is a dedicated command for inspecting the list:

```bash
php artisan dev:list
```

And here is the real output from my machine:

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

Let's read this together, because this output tells us quite a lot.

First, the count is **7**, not 8. We added four processes to the four defaults, yet we ended up with seven. That is proof our `server` genuinely replaced the default `server` instead of joining it. And look at the top line, its command already carries our port 9000.

Second, the rightmost column shows **where** each process was registered from. Ours read `App\Providers\AppServiceProvider@boot`, while the defaults read `Illuminate\Foundation\Providers\ArtisanServiceProvider@boot`. If a mystery process ever shows up in your list, this column tells you who to blame.

Third, the order is not random. Processes you register yourself always float above Laravel's defaults.

Fourth, our `nodeExec` really did resolve to `npx tailwindcss ...`, exactly as we hoped. And the default `vite` process stayed as `npm run dev` because this project uses npm. If your project has a `bun.lock`, `pnpm-lock.yaml`, or `yarn.lock`, Laravel detects it and adjusts the command on its own with no configuration from you. If Bun has your curiosity, we covered it in [How to Use Bun in Laravel](https://qadrlabs.com/post/cara-menggunakan-bun-di-laravel-package-manager-alternatif-npm).

## Step 4 - Filtering Processes with only and except {#step-4-filtering-processes}

Some days you simply don't need everything running. Say today you're only polishing the landing page. All you need is the server and Vite. The queue worker and log tailing? They just crowd the terminal and spin up your laptop fan.

For that there are two very easy methods: `only()` and `except()`. Add one of them inside `boot()`, after all your process registrations:

```php
DevCommands::except('queue', 'logs');
```

The `except()` method runs every process **apart from** the names you list. Save the file and let's check the list again:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 scheduler php artisan schedule:work .. App\Providers\AppServiceProvider@boot
 tailwind npx tailwindcss -i resources/css/app.css -o public/css/app.css --watch .. App\Providers\AppServiceProvider@boot
 tail tail -f storage/logs/laravel.log .. App\Providers\AppServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [5] dev commands
```

Down from 7 to 5. The `queue` and `logs` processes are genuinely gone from the list. :)

Now let's try the opposite. Change that line to:

```php
DevCommands::only('server', 'vite');
```

Where `except()` works by crossing names off, `only()` works by picking them out. **Only** the processes you name will run, everything else is ignored. The result:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [2] dev commands
```

Two processes, exactly what we asked for. Notice too that `only()` plays no favorites. Our own `scheduler`, `tailwind`, and `tail` processes got filtered out as well, simply because their names were not on the list.

And because this filter lives in PHP, you can wrap it in logic. For instance, a slower machine can run a lighter setup through a variable in its own `.env` file:

```php
if (env('DEV_LIGHT_MODE', false)) {
    DevCommands::only('server', 'vite');
}
```

This is one of those things that was practically impossible with a `composer.json` script, since it was just a dead string with no ability to make decisions.

## Step 5 - Migrating from composer run dev to php artisan dev {#step-5-migrating}

Okay, this part is for friends whose projects are still on Laravel 11 or 12 and have grown comfortable with `composer run dev`. The question is simple: do you need to move, and if so, how?

The short answer is that `php artisan dev` only exists from Laravel 13.16.0 onward. So as long as your project sits on 11 or 12, `composer run dev` remains the correct choice and there is nothing wrong with staying there. If you are planning to upgrade anyway, we have a walkthrough in [How to Upgrade Laravel 12 to Laravel 13](https://qadrlabs.com/post/how-to-upgrade-laravel-12-to-laravel-13-a-step-by-step-guide).

For context, here is how the two compare:

| Aspect | `composer run dev` | `php artisan dev` |
| --- | --- | --- |
| Where processes are registered | A string in `composer.json` | PHP code in a service provider |
| Autocompletion and static analysis | None | Yes |
| Engine | `concurrently` | `@laravel/multiplex` (since 13.25.0) |
| Output display | Color labeled lines | A tab per process, scrollable and searchable |
| Restart a single process | Not possible | Yes, press `r` |
| Auto restart on crash | None | Yes |
| Per machine process filtering | Practically impossible | Yes, via `only()` and `except()` |
| Node requirement | Any | 22.13 or later for the tabbed UI |

Now here is the part that might put you at ease. After upgrading to Laravel 13, **you don't actually have to change any habits**. Take a look at `composer.json` in a fresh Laravel 13 project:

```json
"scripts": {
    "dev": [
        "Composer\\Config::disableProcessTimeout",
        "@php artisan dev"
    ]
}
```

Yeah, you got it. The `dev` script is still there, but all it does now is forward to `@php artisan dev`. So if your fingers already know how to type `composer run dev`, go right ahead, the result is identical. Laravel deliberately built this bridge so nobody is forced to change anything.

There is only one thing you do need to do: **remove your old customizations** from `composer.json`. If you have been carrying a long block like this since the Laravel 11 days:

```json
"scripts": {
    "dev": [
      "Composer\\Config::disableProcessTimeout",
      "npx concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail\" \"npm run dev\" --names=server,queue,logs,vite"
    ]
}
```

That block should be replaced with the short version that simply calls `@php artisan dev`. Leave it as is and your project keeps invoking `concurrently` directly, which means you'll never get the tabbed UI.

So where do those customizations go instead? Into `AppServiceProvider`, mapping across like this:

| In `composer.json` (the old way) | In `AppServiceProvider` (the new way) |
| --- | --- |
| One command string inside `concurrently` | One `DevCommands::register()` or `::artisan()` call |
| The `--names=server,queue,logs,vite` option | The second argument on each registration |
| The `-c "#93c5fd,#c4b5fd,..."` option | A color method like `->orange()` or `->color('#93c5fd')` |
| Deleting one command from the string | `DevCommands::except('name')` |

So if you used to squeeze Reverb into that `concurrently` string, it is now a single line:

```php
DevCommands::artisan('reverb:start', 'reverb')->purple();
```

Far nicer to read than threading quotes through an already crowded JSON string. :D

## Step 6 - Try It Out {#step-6-try-it-out}

Time to prove it all works. Let's tidy up `AppServiceProvider` first, this time with a more realistic configuration. We'll put the server on port 9000, add the scheduler and a log tail, then drop the queue worker since we have no jobs to process in this experiment.

```php
public function boot(): void
{
    DevCommands::artisan('serve --host=localhost --port=9000', 'server');

    DevCommands::artisan('schedule:work', 'scheduler')->orange();

    DevCommands::register('tail -f storage/logs/laravel.log', 'tail')->color('#ff6347');

    DevCommands::except('queue');
}
```

Save the file, then let's confirm the list matches our expectations before actually starting anything:

```bash
php artisan dev:list
```

The result:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 scheduler php artisan schedule:work .. App\Providers\AppServiceProvider@boot
 tail tail -f storage/logs/laravel.log .. App\Providers\AppServiceProvider@boot
 logs php artisan pail --timeout=0 .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [5] dev commands
```

Five processes, `queue` is gone, and `server` is on port 9000. Just as ordered. Now run it:

```bash
php artisan dev
```

And here is the real output:

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

Take a look at the `server` line. It is running on `http://localhost:9000`, not the default port 8000, which means the process replacement we did in Step 3 genuinely worked. The `scheduler` process has reported `Running scheduled tasks.` too, and there is not a single line labeled `queue` anywhere, because we filtered it out with `except()`.

That last line is a bonus. `2026-08-15 19:45:41 / .. ~ 505.59ms` is the request that came in when I opened `http://localhost:9000` in the browser, and the server answered with a 200. The Laravel welcome page loaded normally.

*Tadaaa!!!* Five processes running side by side from one terminal, with the ports and colors we chose, and not a single extra terminal tab in sight. :D

When you run this directly in your terminal, rather than redirecting it to a file the way I did to capture the text, you'll get the tabbed UI. Try pressing `2` to jump to the `scheduler` tab, `/` to search through the logs, or `r` to restart whichever process is selected. Once you've had your fun, press `q` to quit and every process shuts down together.

## Wrap Up{#wrap-up}

And here we are at the end. Along the way we got to know `php artisan dev` in Laravel 13, starting from running it bare with no configuration at all, meeting the four default processes and their little quirks like the `logs` process depending on `pcntl_fork`, and then composing our own process list through `DevCommands` in `AppServiceProvider`. We also changed the server port by re registering a process under the same name, colored each label, filtered processes with `only()` and `except()`, and closed with a guide for moving off `composer run dev`.

If I had to sum up the difference in one sentence, it is this: what separates `php artisan dev` from its predecessor is not what it runs, but where you write the list. The moment that list moved from a JSON string into PHP code, everything suddenly became possible: autocompletion, conditional logic, per machine filtering, and colors you can tune one by one.

The project we built here is obviously still very simple. We only ran the scheduler and a `tail` as examples, when in a real project that is exactly where this command shines. Try registering the things that have been forcing you to open extra terminals all this time. Reverb for websockets with `DevCommands::artisan('reverb:start', 'reverb')`, Horizon for watching your queues, a Stripe webhook listener through `DevCommands::register()`, or even Storybook with `DevCommands::node()`. The more processes you fold into one place, the more the benefit shows.

A few things were deliberately left out to keep this tutorial focused, like tuning the output buffer size, the `stream` and `inline` modes you can set as your default through `DevCommands::stream()`, and the `--timestamps` and `--json` options. If you're curious, run `php artisan help dev` and browse the options yourself. You might find one that fits exactly what you need.

If you haven't followed along from the beginning, [How to Use Composer Run Dev in Laravel 11](https://qadrlabs.com/post/cara-menggunakan-composer-run-dev-di-laravel-11) makes a good companion read, and the [What's New in Laravel 13.16.0](https://qadrlabs.com/post/whats-new-in-laravel-13160-artisan-dev-whenenum-and-flexible-json-schema-validation#artisan-dev-command) roundup covers the other features that shipped alongside this command.

If anything here is unclear, or your machine gives you something different, don't hesitate to leave a comment. Windows users especially, I'm genuinely curious what the `concurrently` fallback looks like on your side.

Keep it up! Happy learning.. Hope it's fun.. :D

## References:{#references}

- [Laravel Documentation: The Dev Command](https://laravel.com/docs/13.x/artisan#the-dev-command)
- [Laravel Documentation: Customizing Dev Processes](https://laravel.com/docs/13.x/artisan#customizing-dev-processes)
- [Laravel Documentation: Filtering Dev Processes](https://laravel.com/docs/13.x/artisan#filtering-dev-processes)
- [Laravel Documentation: Tailing Log Messages Using Pail](https://laravel.com/docs/13.x/logging#tailing-log-messages-using-pail)
- [laravel/multiplex on GitHub](https://github.com/laravel/multiplex)
- [Laravel News: Pause All Queues and a New artisan dev UI in Laravel 13.25](https://laravel-news.com/laravel-13-25-0)
