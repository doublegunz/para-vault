---
title: "How to Set Up Xdebug Code Coverage on macOS with Homebrew"
slug: "how-to-set-up-xdebug-code-coverage-on-macos-with-homebrew"
category: "php"
date: "2026-05-12"
status: "published"
---

We had just installed PHP 8.5 via Homebrew and set it as the requirement for a project we were working on. Everything looked fine until we ran the test suite for the first time:

```
No code coverage driver is available
```

Xdebug was supposedly there, or at least we assumed it would be after a fresh PHP installation. But the error made it clear that was not the case. Without a working coverage driver, there is no way to know which parts of the application are actually exercised by the tests and which parts are silently untested. So we traced the problem, set up Xdebug properly, and documented every step so others who hit the same wall have a clear path forward.

## Overview {#overview}

This was not a complicated problem in hindsight. A fresh PHP 8.5 installation via Homebrew does not bundle Xdebug, and even after installing it, there is one configuration value that must be set explicitly or the coverage engine will never activate. This post walks through exactly what we did to get from the error to a working coverage report.

### What You'll Build

- A working Xdebug installation on macOS that enables code coverage reporting for your Laravel + Pest project

### What You'll Learn

- How to check whether Xdebug is already installed via `php --ini`
- How to install Xdebug using the `shivammathur/extensions` Homebrew tap
- How to configure `xdebug.mode` to enable code coverage
- How to verify the installation and run coverage reports with Pest

### What You'll Need

- macOS (Intel or Apple Silicon)
- PHP 8.5 installed via Homebrew
- Composer installed globally
- A Laravel project with Pest already set up
- Basic familiarity with the terminal

## Step 1: Check Your PHP and ini Configuration {#step-1-check-php-ini}

Before installing anything, it is worth checking what PHP sees right now. This step tells you which `php.ini` is loaded and whether Xdebug is already present in the `conf.d` directory.

Run the following command in your terminal:

```bash
php --ini
```

You should see output similar to this:

```
Configuration File (php.ini) Path: "/opt/homebrew/etc/php/8.5"
Loaded Configuration File:         "/opt/homebrew/etc/php/8.5/php.ini"
Scan for additional .ini files in: "/opt/homebrew/etc/php/8.5/conf.d"
Additional .ini files parsed:      /opt/homebrew/etc/php/8.5/conf.d/20-xdebug.ini,
/opt/homebrew/etc/php/8.5/conf.d/error_log.ini,
/opt/homebrew/etc/php/8.5/conf.d/php-memory-limits.ini
```

The key line to look at is `Additional .ini files parsed`. If you see `20-xdebug.ini` listed there, Xdebug is already installed and you can skip directly to Step 3. If that file is missing, proceed to Step 2 to install it.

Also run `php -v` to see the current PHP version and confirm it does not yet mention Xdebug:

```bash
php -v
```

Expected output when Xdebug is not yet active:

```
PHP 8.5.0 (cli) (built: Nov 18 2025 08:02:20) (NTS)
Copyright (c) The PHP Group
Built by Homebrew
Zend Engine v4.5.0, Copyright (c) Zend Technologies
    with Zend OPcache v8.5.0, Copyright (c), by Zend Technologies
```

Notice there is no mention of Xdebug. After a correct installation, that will change.

## Step 2: Install Xdebug via Homebrew {#step-2-install-xdebug}

Homebrew does not ship Xdebug in its core formula, but the `shivammathur/extensions` tap provides pre-compiled PHP extensions including Xdebug for all modern PHP versions. This approach is more reliable than using `pecl install` because it handles compilation and linking automatically for both Intel and Apple Silicon Macs.

### Add the Tap

First, add the `shivammathur/extensions` tap to your Homebrew:

```bash
brew tap shivammathur/extensions
```

This registers the external repository so Homebrew knows where to find PHP extension formulae.

### Install Xdebug for PHP 8.5

Next, install the Xdebug extension matching your PHP version:

```bash
brew install shivammathur/extensions/xdebug@8.5
```

Homebrew will download the pre-compiled extension and place the configuration file at `/opt/homebrew/etc/php/8.5/conf.d/20-xdebug.ini`. You do not need to restart any service at this point.

> **Note for Intel Mac users:** The paths above use `/opt/homebrew`, which is the default for Apple Silicon. On Intel Macs, the Homebrew prefix is `/usr/local`, so your path would be `/usr/local/etc/php/8.5/conf.d/20-xdebug.ini`.

## Step 3: Configure Xdebug for Code Coverage {#step-3-configure-xdebug}

Whether you just installed Xdebug or it was already present, you need to verify and set the `xdebug.mode` value. This is the most common reason coverage does not work: Xdebug is installed but its mode is set to `off` or `debug` only, neither of which activates the coverage engine.

Open the Xdebug configuration file:

```bash
# Using VS Code
code /opt/homebrew/etc/php/8.5/conf.d/20-xdebug.ini

# Or using nano
nano /opt/homebrew/etc/php/8.5/conf.d/20-xdebug.ini
```

Set the file contents to the following:

```ini
[xdebug]
zend_extension="xdebug.so"

; Set the mode to include coverage along with debug and develop helpers.
; The "coverage" value is what enables --coverage to work.
xdebug.mode=develop,debug,coverage

; Automatically start debugging for every request.
xdebug.start_with_request=yes

; The host and port your IDE listens on for step debugging.
xdebug.client_host=localhost
xdebug.client_port=9003
```

Save the file after making changes. No service restart is required because PHP CLI reads this file fresh on every invocation.

## Step 4: Verify Xdebug is Active {#step-4-verify}

After saving the configuration file, confirm that PHP now loads Xdebug correctly.

Run `php -v` again:

```bash
php -v
```

This time the output should include an Xdebug line:

```
PHP 8.5.0 (cli) (built: Nov 18 2025 08:02:20) (NTS)
Copyright (c) The PHP Group
Built by Homebrew
Zend Engine v4.5.0, Copyright (c) Zend Technologies
    with Xdebug v3.5.1, Copyright (c) 2002-2026, by Derick Rethans
    with Zend OPcache v8.5.0, Copyright (c), by Zend Technologies
```

You can also check that the extension is loaded by listing PHP modules:

```bash
php -m | grep xdebug
```

Expected output:

```
xdebug
```

If you see `xdebug` in both outputs, the extension is active and the coverage engine is ready to use.

## Step 5: Run Code Coverage with Pest {#step-5-run-coverage}

With Xdebug properly configured, you can now generate a coverage report for your Laravel project.

### Run Without `--parallel` First

Start without the `--parallel` flag as a baseline. This is the most reliable way to confirm everything is working:

```bash
./vendor/bin/pest --coverage
```

You should see Pest run your test suite and then print a coverage summary similar to this:

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                    0.02s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.17s

  Tests:    2 passed (2 assertions)
  Duration: 0.33s

  Http/Controllers/Controller ......................................... 100.0%
  Models/User ........................................................... 0.0%
  Providers/AppServiceProvider ........................................ 100.0%
  ────────────────────────────────────────────────────────────────────────────
                                                                 Total: 33.3 %
```

### Run With `--parallel` (Optional)

Once you confirm coverage works without `--parallel`, you can try adding it back:

```bash
XDEBUG_MODE=coverage ./vendor/bin/pest --parallel --coverage
```

The `XDEBUG_MODE=coverage` prefix here acts as an environment variable override, which ensures every forked worker process also runs with coverage mode enabled. Without this prefix, parallel worker processes may not inherit the mode setting from `php.ini` correctly.

> **When `--parallel` causes issues:** If you still see `No code coverage driver is available` with `--parallel`, it is a known compatibility limitation between Xdebug and parallel process forking. In that case, run coverage without `--parallel` and reserve `--parallel` for regular test runs where speed matters more than coverage reporting.

## Understanding `xdebug.mode` {#understanding-xdebug-mode}

It is worth understanding what `xdebug.mode` actually controls, because it explains why the error appears even when the extension is present.

Xdebug 3 was redesigned around explicit modes to reduce overhead. Each value in the mode list enables a specific engine, and you can combine them with commas. Here is what each value does:

| Mode | What It Enables |
|---|---|
| `off` | Xdebug is loaded but completely inactive |
| `develop` | Enables `var_dump()` improvements and error formatting |
| `debug` | Enables step debugging with an IDE (uses `client_port`) |
| `coverage` | Enables the code coverage engine used by Pest and PHPUnit |
| `gcstats` | Collects garbage collection statistics |
| `profile` | Generates cachegrind profiling files |
| `trace` | Writes a function trace to a file |

For a typical Laravel development machine, `develop,debug,coverage` is a good combination. It gives you better error output in the browser, step debugging in VS Code, and the ability to run coverage reports whenever needed.

The reason `XDEBUG_MODE=coverage` works as a command-line prefix is that Xdebug reads this environment variable at startup and uses it to override whatever is set in `php.ini`. This is useful in CI environments where you want to enable coverage for one specific run without permanently changing the configuration file.

## Conclusion {#conclusion}

The `No code coverage driver is available` error on macOS after a fresh PHP 8.5 installation via Homebrew comes down to one thing: Xdebug is not bundled with the PHP formula, and even after installing it separately, the coverage engine has to be activated explicitly. Here are the key takeaways from this experience.

- **Homebrew PHP does not include Xdebug.** A fresh `brew install php@8.5` gives you a clean PHP installation with no Xdebug. It must be installed separately via the `shivammathur/extensions` tap.
- **`brew tap shivammathur/extensions` is the reliable path.** This tap provides pre-compiled extensions for Homebrew-managed PHP on both Intel and Apple Silicon, avoiding the compilation issues that come with `pecl install`.
- **`20-xdebug.ini` in `conf.d` is the key file.** Homebrew places the Xdebug configuration in `conf.d/20-xdebug.ini`. This is where `xdebug.mode` must be set, not inside `php.ini` itself.
- **`xdebug.mode=coverage` is required.** Without `coverage` in the mode list, Pest and PHPUnit cannot access the coverage engine even when Xdebug is fully installed.
- **`--parallel` and coverage can conflict.** Use `XDEBUG_MODE=coverage` as an environment variable prefix when running parallel coverage, and fall back to running without `--parallel` if the error persists.