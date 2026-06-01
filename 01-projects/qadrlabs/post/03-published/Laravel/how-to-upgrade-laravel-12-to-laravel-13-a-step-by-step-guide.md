---
title: "How to Upgrade Laravel 12 to Laravel 13: A Step-by-Step Guide"
slug: "how-to-upgrade-laravel-12-to-laravel-13-a-step-by-step-guide"
category: "Laravel"
date: "2026-03-21"
status: "published"
---

Laravel 13 was released on March 17, 2026, bringing a first-party AI SDK, native vector search, JSON:API resources, and more. The good news is that the Laravel team intentionally kept breaking changes to a minimum, making the upgrade process smooth for most projects.

In this tutorial, we will walk through the complete process of upgrading a Laravel 12 application to Laravel 13.


## Overview {#overview}

This tutorial covers the step-by-step process of upgrading an existing Laravel 12 project to Laravel 13. We will use a dummy project with a simple CRUD feature and an existing test suite, so you can see exactly how each change affects a real application.

### What You'll Do

You will clone a pre-built Laravel 12 project, update its dependencies to target Laravel 13, and verify that everything still works correctly after the upgrade.

### What You'll Learn

By following this guide, you will learn how to update `composer.json` to point to Laravel 13 and its compatible packages, how to run Composer to pull in the new framework version, and how to verify the upgrade using both version checks and automated tests.

### What You'll Need

Before getting started, make sure you have the following ready on your machine:

- PHP 8.3 or higher (Laravel 13's minimum requirement)
- Composer installed globally
- Git for cloning the starter project
- A terminal or command-line interface
- Basic familiarity with Laravel and Composer


## Preparation {#persiapan}

To keep things practical, we will use a dummy Laravel 12 project as our starting point. This project includes a basic product CRUD module with a complete test suite, giving us a reliable way to confirm that nothing breaks during the upgrade.

Clone the repository from GitHub:

```
git clone https://github.com/qadrLabs/dummy-project-laravel-12.git
```

After cloning, follow the setup instructions in the repository's README to get the project running locally.

Once the project is set up, run the test suite to establish a baseline. This ensures that all tests pass on Laravel 12 before we make any changes:

```
php artisan test
```

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.09s  

   PASS  Tests\Feature\ProductControllerTest
  ✓ index displays products                                              0.07s  
  ✓ create displays form                                                 0.01s  
  ✓ store saves new product and redirects                                0.01s  
  ✓ store validates required fields                                      0.01s  
  ✓ store validates unique code                                          0.01s  
  ✓ show displays product                                                0.01s  
  ✓ edit displays form                                                   0.01s  
  ✓ update modifies product and redirects                                0.01s  
  ✓ update validates required fields                                     0.01s  
  ✓ destroy deletes product and redirects                                0.01s  

  Tests:    12 passed (39 assertions)
  Duration: 0.26s

```

All 12 tests pass with 39 assertions. This is our green baseline. If anything goes wrong after upgrading, we will know immediately.


## Verify PHP Version {#verify-php-version}

Laravel 13 requires PHP 8.3 or higher. Before touching any dependency, it is important to confirm that your PHP installation meets this requirement. Attempting to upgrade without a compatible PHP version will cause Composer to reject the update.

Here is the full list of server requirements for Laravel 13:

- PHP >= 8.3
- Ctype PHP Extension
- cURL PHP Extension
- DOM PHP Extension
- Fileinfo PHP Extension
- Filter PHP Extension
- Hash PHP Extension
- Mbstring PHP Extension
- OpenSSL PHP Extension
- PCRE PHP Extension
- PDO PHP Extension
- Session PHP Extension
- Tokenizer PHP Extension
- XML PHP Extension

Most of these extensions are bundled with standard PHP installations, so the main thing to check is the PHP version itself. Run the following command:

```
php -v
```

```
$ php -v
PHP 8.4.5 (cli) (built: Jan  7 2026 08:43:36) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.4.5, Copyright (c) Zend Technologies
    with Zend OPcache v8.4.5, Copyright (c), by Zend Technologies

```

At the time of writing this tutorial, we are using PHP 8.4.5. This is well within the supported range (8.3 - 8.5), so we can proceed with the upgrade.

If your PHP version is below 8.3, you will need to update PHP first before continuing.


## Update Dependencies {#update-dependensi}

This is the core step of the upgrade. We need to modify `composer.json` to point to Laravel 13 and its compatible package versions.

### Update Core Packages

Open `composer.json` and locate the `require` section. It should currently look like this:

```json
    "require": {
        "php": "^8.2",
        "laravel/framework": "^12.0",
        "laravel/tinker": "^2.10.1"
    },
```

Update it to target Laravel 13 and its compatible dependencies:

```json
    "require": {
        "php": "^8.3",
        "laravel/framework": "^13.0",
        "laravel/tinker": "^3.0"
    },
```

Here is what each change does:

- `"php": "^8.3"` raises the minimum PHP version to match Laravel 13's requirement. The `^` (caret) operator means "8.3 or higher, but below 9.0."
- `"laravel/framework": "^13.0"` tells Composer to pull the latest Laravel 13.x release.
- `"laravel/tinker": "^3.0"` upgrades Tinker to version 3, which is the version compatible with Laravel 13.

### Update PHPUnit

Next, find the PHPUnit entry in the `require-dev` section:

```json
    "require-dev": {
        ...
        "phpunit/phpunit": "^11.5.50"
    },
```

Change the version constraint to `^12.0`:

```json
    "require-dev": {
        ...
        "phpunit/phpunit": "^12.0"
    },
```

PHPUnit 12 is the testing framework version that ships with Laravel 13. Keeping this in sync ensures compatibility between the framework's test helpers and the test runner.

### Run Composer Update

With the dependency changes in place, run Composer to resolve and install the new packages:

```
composer update
```

```
$ composer update
Loading composer repositories with package information
Updating dependencies
Lock file operations: 0 installs, 33 updates, 3 removals
  - Removing sebastian/code-unit (3.0.3)
  - Removing sebastian/code-unit-reverse-lookup (4.0.1)
  - Removing symfony/polyfill-php83 (v1.33.0)
  - Upgrading laravel/framework (v12.55.1 => v13.1.1)
  - Upgrading laravel/tinker (v2.11.1 => v3.0.0)

  .
  .
  .
  .
  .

```

The output confirms that Composer successfully upgraded `laravel/framework` from v12.55.1 to v13.1.1 and `laravel/tinker` from v2.11.1 to v3.0.0. A few packages were also removed, such as `symfony/polyfill-php83`, which is no longer needed since PHP 8.3 is now the minimum version.


## Verify Laravel Version {#verify-laravel-version}

After the dependencies are updated, it is a good practice to verify that the framework is actually running the expected version. Run the following Artisan command:

```
php artisan --version
```

```
$ php artisan --version
Laravel Framework 13.1.1

```

The output confirms that the application is now running on Laravel Framework 13.1.1. The upgrade was applied correctly.


## Run Testing {#run-testing}

The final and most important step is to run the test suite again. This tells us whether the upgrade introduced any regressions or broke existing functionality.

```
php artisan test
```

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.09s  

   PASS  Tests\Feature\ProductControllerTest
  ✓ index displays products                                              0.07s  
  ✓ create displays form                                                 0.01s  
  ✓ store saves new product and redirects                                0.01s  
  ✓ store validates required fields                                      0.01s  
  ✓ store validates unique code                                          0.01s  
  ✓ show displays product                                                0.01s  
  ✓ edit displays form                                                   0.01s  
  ✓ update modifies product and redirects                                0.01s  
  ✓ update validates required fields                                     0.01s  
  ✓ destroy deletes product and redirects                                0.01s  

  Tests:    12 passed (39 assertions)
  Duration: 0.31s

```

All 12 tests still pass with 39 assertions, exactly the same as before the upgrade. The slight difference in duration (0.26s vs 0.31s) is negligible and varies between runs. What matters is that every test remains green, meaning the upgrade did not break any existing behavior.


## Conclusion {#conclusion}

Upgrading from Laravel 12 to Laravel 13 turned out to be a straightforward process. Because the Laravel team focused on minimizing breaking changes in this release, most of the work comes down to updating a few lines in `composer.json` and running `composer update`.

Here are the key takeaways from this tutorial:

- **Check PHP first.** Laravel 13 requires PHP 8.3 or higher. Verify your PHP version before making any changes to avoid confusing Composer errors.
- **Three dependency changes are all you need.** For a standard project, updating `laravel/framework`, `laravel/tinker`, and `phpunit/phpunit` in `composer.json` is sufficient to complete the upgrade.
- **Always run tests before and after.** Establishing a green baseline before the upgrade and re-running tests afterward is the most reliable way to catch regressions. If you don't have tests yet, this is a great reason to start writing them.
- **Read the official upgrade guide.** This tutorial covers a minimal project, but your application may use additional first-party packages (Cashier, Passport, Scout, etc.) that also need version bumps. Always consult the [official Laravel 13 upgrade guide](https://laravel.com/docs/13.x/upgrade) for the complete list of changes.

With the upgrade complete, you now have access to all of Laravel 13's new features, including the AI SDK, native vector search, JSON:API resources, expanded PHP attributes, and more.