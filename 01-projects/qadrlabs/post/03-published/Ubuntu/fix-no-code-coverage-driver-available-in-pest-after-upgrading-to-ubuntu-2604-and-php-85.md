---
title: "Fix \"No Code Coverage Driver Available\" in Pest After Upgrading to Ubuntu 26.04 and PHP 8.5"
slug: "fix-no-code-coverage-driver-available-in-pest-after-upgrading-to-ubuntu-2604-and-php-85"
category: "Ubuntu"
date: "2026-05-07"
status: "published"
---

We had just upgraded the machine to Ubuntu 26.04 and PHP 8.5, and were in the middle of setting up a new article in our [Testing CRUD Features in CodeIgniter 4 with Pest](https://qadrlabs.com/post/testing-crud-features-in-codeigniter-4-with-pest-part-2-of-2) series. No tests had been written yet. We ran Pest for the first time just to confirm the setup was working, and this appeared at the top of the output:

```
   WARN  No code coverage driver available
```

At first it was not obvious where the warning was coming from, since we had not written any tests or configured anything coverage-related ourselves. It turns out CodeIgniter 4 ships with a `phpunit.xml.dist` that already includes code coverage configuration by default. Pest picks that up and immediately looks for a coverage driver, which is why the warning appears even before a single test is written.

There were two ways to handle this. The quick option was to remove or comment out the coverage configuration in `phpunit.xml.dist`. The better option was to set up Xdebug properly, because code coverage is something we plan to use in upcoming articles anyway. Doing it now means it is ready when we need it. This post documents how we did that on Ubuntu 26.04 with PHP 8.5.

## Overview {#overview}

We were not troubleshooting a broken project. We were just getting started on a new article, ran Pest once to confirm everything was wired up, and got that warning before writing a single line of test code. Tracing it back to the default `phpunit.xml` coverage configuration in CodeIgniter 4 took a moment, and once we understood what was happening we decided to fix it properly rather than comment it out. This post documents what we found and how we resolved it on Ubuntu 26.04 with PHP 8.5.

### What You'll Build

A restored Xdebug code coverage setup for PHP 8.5 on Ubuntu 26.04, bringing `vendor/bin/pest --coverage` back to the same working state it was in before the OS upgrade.

### What You'll Learn

- Why PHP version upgrades break existing Xdebug configurations on Ubuntu
- How to install Xdebug for PHP 8.5 using the correct package name
- How to set `xdebug.mode=coverage` in the ini file created automatically by apt
- How to diagnose and fix the "Cannot load Xdebug - it was already loaded" conflict caused by duplicate ini files
- How to verify the fix and confirm that coverage is running correctly

### What You'll Need

- Ubuntu 26.04 LTS, freshly upgraded or clean install
- PHP 8.5, the version shipped natively by Ubuntu 26.04
- A project using Pest; our [CodeIgniter 4 Pest series](https://qadrlabs.com/post/testing-crud-features-in-codeigniter-4-with-pest-part-2-of-2) provides the reference project used in this post
- `sudo` access on the machine

## Step 1: Confirm the Problem {#step-1-confirm}

Before making any changes, run Pest from your project directory and capture the warning as a baseline. This confirms that the issue is specifically the missing coverage driver and not something unrelated in the test suite.

```bash
vendor/bin/pest
```

Our actual terminal output looked exactly like this:

```
$ vendor/bin/pest

   WARN  No code coverage driver available
gun-gun-priatna@qadrlabs:~/learning-lab/codeigniter/testing/bookshelf$
```

The test results appear below the warning and remain unaffected. Pest checks at startup whether Xdebug or PCOV is loaded in the current PHP process. When neither is found, it prints the warning and continues running without collecting any coverage data.

Confirm which PHP version the machine is currently using:

```bash
php -v
```

On Ubuntu 26.04 with the native PHP package, the output will be:

```
PHP 8.5.4 (cli) (built: Apr  1 2026 09:36:11) (NTS)
Copyright (c) The PHP Group
Built by Ubuntu
Zend Engine v4.5.4, Copyright (c) Zend Technologies
    with Zend OPcache v8.5.4, Copyright (c), by Zend Technologies
```

Notice that there is no `with Xdebug` line. Under PHP 8.4 on Ubuntu 24.04, that line was present because we had installed `php8.4-xdebug`. The upgrade to PHP 8.5 does not migrate extension configurations. Ubuntu treats each PHP minor version as a separate package tree, so PHP 8.5 starts fresh with no user-installed extensions.

## Step 2: Install Xdebug for PHP 8.5 {#step-2-install}

The Xdebug package name on Ubuntu includes the PHP minor version. This is intentional because the extension must be compiled against the exact PHP binary it will be loaded by. Under PHP 8.4 we used `php8.4-xdebug`. Under PHP 8.5 the correct package is `php8.5-xdebug`.

Update the package index, then install the extension:

```bash
sudo apt update
sudo apt install php8.5-xdebug
```

Running `apt update` first ensures the package index reflects the latest available versions before we install. The `php8.5-xdebug` package installs the compiled extension binary and, importantly, creates a configuration file at `/etc/php/8.5/cli/conf.d/20-xdebug.ini`. PHP reads this file automatically on every invocation. Its presence, and what is written inside it, matters significantly in the next step.

## Step 3: Configure Xdebug Coverage Mode {#step-3-configure}

Installing Xdebug is not enough on its own. Starting from Xdebug 3, the extension was redesigned around explicit operational modes. When no mode is specified, Xdebug loads into the PHP process but activates none of its instrumentation hooks. It is present but entirely passive, which is exactly why `vendor/bin/pest` still warns about a missing coverage driver even after the package is installed.

First, inspect what the apt package wrote into the ini file:

```bash
cat /etc/php/8.5/cli/conf.d/20-xdebug.ini
```

The file will likely contain only a `zend_extension` line. We need to write the complete correct configuration into this same file. The key point here is that we edit the file apt already created, rather than creating a new one. The reason this matters is explained in Step 4.

Write the correct configuration using `tee`:

```bash
sudo tee /etc/php/8.5/cli/conf.d/20-xdebug.ini <<EOF
zend_extension=xdebug.so
xdebug.mode=coverage
EOF
```

The `tee` command writes the content to the file with sudo privileges, replacing whatever was there before. The `zend_extension=xdebug.so` line tells PHP which binary to load for the Xdebug extension. The `xdebug.mode=coverage` line activates only the coverage instrumentation, which keeps overhead low compared to enabling step debugging at the same time.

## Step 4: Avoid the "Already Loaded" Conflict {#step-4-avoid-conflict}

This step documents a mistake that is easy to make when adapting general Xdebug tutorials. Many guides instruct you to create a new ini file, typically named `99-xdebug.ini`, to avoid overwriting existing configurations. On a machine where no Xdebug ini file exists yet, that approach works fine. After running `apt install php8.5-xdebug`, it causes a conflict.

When apt installs the extension it creates `20-xdebug.ini` automatically. If you then create a separate `99-xdebug.ini` with the same `zend_extension=xdebug.so` line, PHP will process both files in alphabetical order from the `conf.d` directory. It loads Xdebug from `20-xdebug.ini` successfully, then encounters `99-xdebug.ini` and tries to load Xdebug a second time. The result is this error:

```
Cannot load Xdebug - it was already loaded
```

If you encounter this error, the fix is to remove the duplicate file:

```bash
sudo rm /etc/php/8.5/cli/conf.d/99-xdebug.ini
```

With the duplicate removed, PHP loads Xdebug exactly once from `20-xdebug.ini`, which already contains the `xdebug.mode=coverage` setting we wrote in Step 3.

## Step 5: Verify and Run Coverage {#step-5-verify}

Confirm that Xdebug is now loaded and visible in the PHP version output:

```bash
php -v
```

You should now see the Xdebug line included alongside the Zend Engine entry:

```
PHP 8.5.4 (cli) (built: Apr  1 2026 09:36:11) (NTS)
Copyright (c) The PHP Group
Built by Ubuntu
Zend Engine v4.5.4, Copyright (c) Zend Technologies
    with Zend OPcache v8.5.4, Copyright (c), by Zend Technologies
    with Xdebug v3.x.x, Copyright (c), by Derick Rethans
```

You can also confirm that coverage mode specifically is active by querying it directly:

```bash
php -r "var_dump(xdebug_info('mode'));"
```

Now run Pest normally. The warning should no longer appear:

```bash
vendor/bin/pest
```

To generate a full terminal coverage report:

```bash
vendor/bin/pest --coverage
```

To enforce a minimum coverage threshold, which is the configuration commonly used in CI pipelines:

```bash
vendor/bin/pest --coverage --min=80
```

If coverage falls below the specified percentage, Pest exits with a non-zero status code. This causes CI builds to fail automatically, which is exactly the behavior we had working before the Ubuntu upgrade and have now fully restored.

## How Xdebug Coverage Mode Works {#how-it-works}

It is worth understanding why `xdebug.mode=coverage` is a required line and not an optional one. This context makes the whole installation sequence easier to reason about.

Xdebug 3 was redesigned around explicit modes to reduce performance overhead. In older versions, all Xdebug features were active whenever the extension was loaded, which made PHP noticeably slower and was unsuitable for CI environments. In Xdebug 3, loading the extension without specifying a mode means the extension occupies memory but performs no instrumentation whatsoever. The output of `php -m` will include Xdebug in the list, but no functionality is active.

Setting `xdebug.mode=coverage` instructs Xdebug to activate only its code coverage instrumentation. It works by hooking into the Zend Engine opcode executor and recording which opcodes are executed during a script run. Pest uses PHPUnit internally, and PHPUnit communicates with the `Xdebug\CodeCoverage` driver to collect those execution traces and build the line-level coverage reports you see in the terminal.

Multiple modes can be combined when needed. For example, `xdebug.mode=coverage,debug` enables both coverage collection and step debugging at the same time. For CI pipelines where no interactive debugger is needed, `xdebug.mode=coverage` alone is the right choice because it keeps execution faster and memory usage lower.

## PCOV as a Lightweight Alternative {#pcov-alternative}

If your environment is dedicated to CI and you never need a step debugger on the same machine, PCOV is a minimal extension built exclusively for code coverage measurement and is worth considering.

```bash
sudo apt install php8.5-pcov
```

PCOV has lower memory usage and faster execution than Xdebug in coverage mode because it has no debugging, profiling, or tracing capabilities at all. The tradeoff is straightforward: it does nothing except coverage. If your team already uses Xdebug for step debugging during local development, it is simpler to use Xdebug for coverage as well so you manage only one extension and one configuration file. Both extensions are fully compatible with Pest and PHPUnit, so the choice comes down to whether debugging capabilities matter on that specific machine.

## Conclusion {#conclusion}

The "No code coverage driver available" warning after an Ubuntu upgrade is not a Pest problem and not a project configuration problem. It is a predictable consequence of how Ubuntu manages PHP extensions across minor versions, and it has a straightforward fix. Here are the key takeaways from this post.

- **PHP version upgrades on Ubuntu do not carry over extension configurations.** Ubuntu treats each PHP minor version as an independent package tree. Moving from PHP 8.4 to PHP 8.5 means all extensions, including Xdebug, must be reinstalled for the new version.
- **The correct package name on Ubuntu 26.04 is `php8.5-xdebug`.** Package names include the PHP minor version number. Always match the package name to the version shown in `php -v` before installing.
- **`xdebug.mode=coverage` must be set explicitly.** Xdebug 3 activates no functionality by default. Installing the package without configuring the mode leaves the extension loaded but entirely passive for coverage purposes.
- **Edit the existing `20-xdebug.ini`, not a new file.** The apt package creates its own ini file during installation. Adding a second ini file with the same `zend_extension` line causes a "already loaded" conflict because PHP processes every file in the `conf.d` directory.
- **PCOV is a valid lightweight alternative for CI-only machines.** If step debugging is never needed on the machine, `php8.5-pcov` offers faster execution and lower memory overhead than Xdebug in coverage mode.