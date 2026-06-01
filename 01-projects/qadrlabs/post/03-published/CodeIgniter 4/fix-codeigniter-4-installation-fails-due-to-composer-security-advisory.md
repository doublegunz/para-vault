---
title: "Fix: CodeIgniter 4 Installation Fails Due to Composer Security Advisory"
slug: "fix-codeigniter-4-installation-fails-due-to-composer-security-advisory"
category: "CodeIgniter 4"
date: "2026-04-18"
status: "published"
---

You open your terminal, run `composer create-project codeigniter4/appstarter blog`, and expect to see a fresh CodeIgniter 4 project ready to work with. Instead, the installation halts with a wall of red text about security advisories, package conflicts, and PHPUnit. Your project folder exists, but there is no `vendor` directory inside it, which means nothing runs.

The error message itself is not very helpful. It tells you something is blocked for security reasons, offers a few vague options, and leaves you to figure out the rest. If you upgraded Composer recently or are setting up CodeIgniter 4 for the first time in 2026, this is the error you will almost certainly hit.

This article documents the exact fix, tested on 18 April 2026, on Ubuntu 25.04 with PHP 8.4.5 and the latest Composer. You will have a fully working CodeIgniter 4.7.2 installation with PHPUnit running cleanly by the end.

## Overview {#overview}

### What You'll Build

A clean, fully functional CodeIgniter 4.7.2 installation with all dependencies resolved and PHPUnit 13 installed and verified. Every default test will pass.

### What You'll Learn

- Why Composer 2.9 blocks certain package installations by default and what triggers this behavior
- How to inspect what was actually created when the installation appears to fail
- The two-step workaround: removing the conflicting package first, then reinstalling with a clean version
- How to verify that both the web server and the test suite are working correctly after the fix

### What You'll Need

- PHP 8.4.5 or any PHP 8.2+ installation (this article was tested on PHP 8.4.5)
- Composer 2.9 or newer
- Ubuntu 25.04 (the steps are identical on any Linux distribution or macOS with minor path differences)
- A terminal and a browser to verify the running project

## Step 1: Run the Installation and Observe the Error {#step-1-install}

Start by running the standard CodeIgniter 4 project creation command. If you have not done this yet, navigate to the directory where you want your project to live and run the following.

```bash
composer create-project codeigniter4/appstarter blog
```

Composer will begin by downloading and extracting the CodeIgniter 4 starter template. The extraction itself succeeds, but the dependency resolution phase fails. You will see output similar to this.

```
$ composer create-project codeigniter4/appstarter blog
Creating a "codeigniter4/appstarter" project at "./blog"
Installing codeigniter4/appstarter (v4.7.2)
  - Installing codeigniter4/appstarter (v4.7.2): Extracting archive
Created project in /home/gun-gun-priatna/learning-lab/codeigniter/blog
Loading composer repositories with package information
Updating dependencies
Your requirements could not be resolved to an installable set of packages.
  Problem 1
    - Root composer.json requires phpunit/phpunit ^10.5.16, found phpunit/phpunit[10.5.16, ..., 10.5.63] but these were not loaded, because they are affected by security advisories ("PKSA-5jz8-6tcw-pbk4", "PKSA-z3gr-8qht-p93v"). Go to https://packagist.org/security-advisories/ to find advisory details. To ignore the advisories, add them to the audit "ignore" config. To turn the feature off entirely, you can set "block-insecure" to false in your "audit" config.
```

The key phrase in this error is "these were not loaded, because they are affected by security advisories." Composer found the PHPUnit versions that match the version constraint declared in CodeIgniter 4's `composer.json` (`^10.5.16`), but it refused to install any of them because every version in that range carries one or more known security vulnerabilities. Since PHPUnit is listed as a required package, the entire dependency resolution fails and no `vendor` folder is created.

## Step 2: Check What Was Actually Created {#step-2-check}

Even though the installation appeared to fail, Composer already extracted the CodeIgniter 4 skeleton before the dependency resolution started. It is worth confirming this before doing anything else, because the project structure is already in place and you do not need to start from scratch.

Run `ls` from the parent directory to confirm the `blog` folder was created.

```bash
$ ls
blog
```

Now navigate into the project directory.

```bash
cd blog
```

Run `ls` again to inspect the contents.

```bash
$ ls
app     composer.json  LICENSE           preload.php  README.md  tests
builds  env            phpunit.xml.dist  public       spark      writable
```

The CodeIgniter 4 skeleton is fully present: the `app` directory, configuration files, the `spark` CLI tool, the `tests` folder, and everything else. The only thing missing is `vendor`, which is the directory Composer creates when it successfully installs all dependencies. Without it, neither `php spark serve` nor PHPUnit can run, because all third-party code lives inside `vendor`.

This confirms the situation precisely: the project scaffold is fine, and only the dependency installation needs to be fixed.

## Step 3: Remove PHPUnit to Unlock Dependency Resolution {#step-3-remove-phpunit}

The fix works in two stages. The first stage is removing PHPUnit from the project's requirements so that Composer can resolve and install all the other dependencies without obstruction. Run the following command from inside the `blog` directory.

```bash
composer remove phpunit/phpunit --dev
```

This command modifies `composer.json` to remove the PHPUnit entry from the `require-dev` section and then re-runs dependency resolution for everything that remains. Because the only blocked package is now absent, Composer can install all of CodeIgniter 4's other dependencies without triggering the security check.

Once this command completes, run `ls` to verify that the `vendor` folder now exists.

```bash
$ ls
app     composer.json  env      phpunit.xml.dist  public     spark  vendor
builds  composer.lock  LICENSE  preload.php       README.md  tests  writable
```

The `vendor` directory is now present alongside a `composer.lock` file, which records the exact resolved versions of every installed package. All dependencies except PHPUnit are installed and ready.

## Step 4: Verify the Project Runs {#step-4-verify}

Before reinstalling PHPUnit, confirm that the CodeIgniter 4 application itself is working correctly. Start the built-in development server using the Spark CLI tool.

```bash
php spark serve
```

You should see the following output.

```
$ php spark serve
CodeIgniter v4.7.2 Command Line Tool - Server Time: 2026-04-18 03:11:08 UTC+00:00
CodeIgniter development server started on http://localhost:8080
Press Control-C to stop.
[Sat Apr 18 10:11:08 2026] PHP 8.4.5 Development Server (http://localhost:8080) started
```

Open your browser and navigate to `http://localhost:8080`. The default CodeIgniter 4 welcome page should appear, confirming that the framework is installed and working correctly.

Once verified, stop the development server by pressing `Control-C` in your terminal. You are now ready to restore PHPUnit.

## Step 5: Reinstall PHPUnit with the Latest Version {#step-5-reinstall-phpunit}

The second stage of the fix is reinstalling PHPUnit. Because you are doing this as a separate installation step rather than as part of the initial project creation, Composer will fetch the latest available version rather than being constrained by the version range specified in the original CodeIgniter 4 `composer.json`. The latest version is free from the security advisories that caused the initial failure.

```bash
composer require phpunit/phpunit --dev --prefer-dist
```

The `--prefer-dist` flag tells Composer to download the packaged distribution archive rather than cloning the source repository, which is faster and more appropriate for a development dependency.

Once the installation completes, run the test suite to confirm everything is working.

```bash
./vendor/bin/phpunit --no-coverage
```

You should see the following output.

```
$ ./vendor/bin/phpunit --no-coverage
PHPUnit 13.1.6 by Sebastian Bergmann and contributors.
Runtime:       PHP 8.4.5
Configuration: /home/gun-gun-priatna/learning-lab/codeigniter/blog/phpunit.xml.dist
.....                                                               5 / 5 (100%)
Time: 00:00.025, Memory: 22.00 MB
OK (5 tests, 6 assertions)
```

PHPUnit 13.1.6 is installed and all five of CodeIgniter 4's default tests pass cleanly. The installation is complete.

## Understanding the Error {#understanding-the-error}

Now that everything is working, it is worth taking a moment to understand why this error exists in the first place. This context will help you recognize and handle similar situations in the future.

### What Changed in Composer 2.9

Composer 2.9, released in November 2025, introduced a stricter default security posture. Before this version, Composer would emit warnings about packages with known vulnerabilities but would still install them. Starting with 2.9, Composer actively blocks the installation of any package that has an unresolved security advisory listed in the Packagist security database. This behavior is controlled by the `audit.block-insecure` configuration option, which defaults to `true` in Composer 2.9 and later.

This is a meaningful improvement for production applications, but it can cause friction during framework setup when the framework's `composer.json` pins a dependency version range that happens to overlap entirely with vulnerable releases.

### The Two Security Advisories Involved

The two advisories blocking PHPUnit in this case are `PKSA-5jz8-6tcw-pbk4` (mapped to `GHSA-qrr6-mg7r-m243`) and `PKSA-z3gr-8qht-p93v` (mapped to `GHSA-vvj3-c3rp-c85p`). Both affect PHPUnit versions in the 10.x range that CodeIgniter 4's `composer.json` specifies. The advisories themselves are not catastrophic production vulnerabilities; they are issues within PHPUnit's test runner context. However, Composer has no mechanism for evaluating severity, so any advisory results in a block.

### Why Removing and Reinstalling Works

When you run `composer remove phpunit/phpunit --dev`, Composer removes the PHPUnit entry from `composer.json` and re-solves the dependency graph for everything else. Because PHPUnit is no longer in the requirements, the security check no longer finds a conflict, and all other packages install successfully.

When you subsequently run `composer require phpunit/phpunit --dev --prefer-dist` as a standalone command, Composer is no longer bound by CodeIgniter's original version constraint of `^10.5.16`. It resolves the latest stable release of PHPUnit instead, which in this case is version 13.1.6. This version is not affected by either advisory, so the installation succeeds cleanly and you end up with a newer, more secure version than what CodeIgniter originally specified.

### What About the `audit ignore` Alternative

The error message itself suggests two other options: adding the advisory identifiers to an `audit.ignore` list in your Composer configuration, or disabling the `block-insecure` feature entirely by setting it to `false`. Both of these approaches would also unblock the installation, but they do so by telling Composer to look the other way rather than by resolving the underlying issue.

The approach documented in this article is preferable because you end up with PHPUnit 13, which is a significantly newer and more capable version than PHPUnit 10. You are not bypassing the security check; you are satisfying it by installing a version that passes it.

## Conclusion {#conclusion}

- **Composer 2.9 introduced automatic blocking of packages with known security advisories.** This is a net improvement for security, but it can surface installation errors in frameworks whose `composer.json` pins a dependency to a version range that is entirely flagged.
- **The CodeIgniter 4 skeleton is created before dependency resolution fails.** When you see this error, the project structure is already in place. You do not need to delete the folder and start over.
- **The fix is a two-step process.** First, remove PHPUnit with `composer remove phpunit/phpunit --dev` to allow all other dependencies to install. Then reinstall it with `composer require phpunit/phpunit --dev --prefer-dist` to get the latest version, which is free from the flagged advisories.
- **The result is a better outcome than the original intent.** Instead of PHPUnit 10.x as specified in CodeIgniter's `composer.json`, you end up with PHPUnit 13.x, a newer version that passes all default CodeIgniter tests without modification.
- **Do not disable `block-insecure` to work around this.** Ignoring the advisory or turning off the security feature trades a solvable problem for an invisible one. The reinstall approach resolves the root cause cleanly.