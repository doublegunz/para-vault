---
title: "How to Build and Publish a PHP Library to Packagist"
slug: "how-to-build-and-publish-a-php-library-to-packagist"
category: "php"
date: "2026-05-03"
status: "published"
---

Every PHP project that handles money in Indonesia usually has the same snippet buried somewhere in a helper file or a service class: `"Rp " . number_format($amount, 0, ',', '.')`. You write it once, it works, and then you copy it to the next project. And the next. Before long, one teammate is formatting currency as `"Rp1.500.000"`, another as `"Rp 1,500,000"`, and a third has gone rogue with `"IDR1500000"`. The inconsistency leaks into your UI, your PDF reports, and sometimes even your API responses.

The right fix is to extract that logic into a proper, tested, and versioned PHP library, then publish it to Packagist so every project on your team can pull it in with a single `composer require`. Once it is published, updating the formatting rules in one place updates every project that depends on it. This tutorial walks you through the complete journey: from writing the first line of code to seeing your package live on packagist.org.

## Overview {#overview}

This article is a practical end-to-end guide for building and publishing your first PHP package. The library we build, `qadrlabs/php-rupiah`, is intentionally minimal so the focus stays on the packaging workflow rather than the business logic.

### What You'll Build

- A PHP library called `qadrlabs/php-rupiah` that formats integers and floats as Indonesian Rupiah strings and parses those strings back to integers.
- A backed PHP Enum called `RupiahStyle` that controls the output format (standard `Rp` prefix, ISO `IDR` code, or no prefix at all). If you are not yet familiar with PHP Enums, the article [Getting Started with PHP Enums: A Practical Guide for Beginners](https://qadrlabs.com/post/getting-started-with-php-enums-a-practical-guide-for-beginners) covers everything you need to know before continuing.
- A Pest test suite that verifies all formatting and parsing behavior.
- A published package on packagist.org, installable by anyone via `composer require`.

### What You'll Learn

- How to structure a PHP library from scratch with PSR-4 autoloading.
- How to write and run Pest tests in a standalone PHP project (without Laravel).
- How to prepare `composer.json` with proper metadata for Packagist.
- How to tag a release with Semantic Versioning and publish it to Packagist.
- How to connect your GitHub repository to Packagist for automatic package updates.

### What You'll Need

- PHP 8.3 or higher installed locally.
- Composer installed globally.
- A GitHub account with a public repository ready to receive the library code.
- A Packagist account (free registration at packagist.org, login via GitHub is the easiest option).
- Basic familiarity with PHP namespaces, static methods, and the command line.

## Step 1: Set Up the Project Structure {#step-1-setup}

The first thing you need is a clean directory that will become both your local development workspace and your GitHub repository. Run the following commands to create the directory and move into it.

```bash
mkdir php-rupiah
cd php-rupiah
```

Now run `composer init` to generate the initial `composer.json` file. Composer will walk you through a series of prompts. Here is what to enter for each one.

```
Package name (<vendor>/<name>) [user/php-rupiah]: qadrlabs/php-rupiah
Description []: A lightweight PHP library to format and parse Indonesian Rupiah (IDR) currency values.
Author [Your Name <email>, n to skip]: n
Minimum Stability []:
Package Type []: library
License []: MIT

Would you like to define your dependencies (require) interactively [yes]? no
Would you like to define your dev dependencies (require-dev) interactively [yes]? no
Add PSR-4 autoload mapping? [src/, n to skip]: src/
```

When Composer asks to add a PSR-4 autoload mapping and suggests `src/`, press Enter to accept it. Composer will infer the namespace from the package name and generate an entry for you. Because the auto-generated namespace (`Qadrlabs\PhpRupiah`) does not match the convention we want, you need to open the newly created `composer.json` and update it to match the following complete version.

```json
{
    "name": "qadrlabs/php-rupiah",
    "description": "A lightweight PHP library to format and parse Indonesian Rupiah (IDR) currency values.",
    "type": "library",
    "license": "MIT",
    "keywords": ["rupiah", "idr", "currency", "formatter", "indonesia", "php"],
    "homepage": "https://qadrlabs.com",
    "authors": [
        {
            "name": "Qadr Labs",
            "email": "hello@qadrlabs.com",
            "homepage": "https://qadrlabs.com"
        }
    ],
    "require": {
        "php": "^8.3"
    },
    "require-dev": {
        "pestphp/pest": "^3.0"
    },
    "autoload": {
        "psr-4": {
            "QadrLabs\\Rupiah\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "QadrLabs\\Rupiah\\Tests\\": "tests/"
        }
    },
    "scripts": {
        "test": "./vendor/bin/pest"
    },
    "config": {
        "allow-plugins": {
            "pestphp/pest-plugin": true
        }
    }
}
```

A few things worth noting here. The `autoload` block maps the namespace `QadrLabs\Rupiah` to the `src/` directory. This means any class under `src/` that declares `namespace QadrLabs\Rupiah;` will be automatically discovered by Composer. The `autoload-dev` block does the same for the `tests/` directory, but only in development environments. Libraries should never push test-related classes into production installs, which is exactly what this separation achieves. The `scripts.test` entry is a convenience shortcut so you can run `composer test` instead of typing the full Pest path every time.

Create the `src/` and `tests/` directories.

```bash
mkdir src tests
```

Then run `composer install` to generate the `vendor/` directory and the autoloader.

```bash
composer install
```

Your project structure should now look like this.

```
php-rupiah/
├── src/
├── tests/
├── vendor/
└── composer.json
```

## Step 2: Write the Library Code {#step-2-library-code}

The library has two source files: a backed enum that defines the available formatting styles, and a class that provides the `format()` and `parse()` methods. Start with the enum because the main class depends on it.

### Creating the RupiahStyle Enum

Create the file `src/RupiahStyle.php` and add the following content.

```php
<?php

namespace QadrLabs\Rupiah;

enum RupiahStyle: string
{
    // The standard Indonesian currency prefix: "Rp 1.500.000"
    case WithPrefix = 'Rp';

    // The ISO 4217 currency code: "IDR 1.500.000"
    case ISO = 'IDR';

    // No prefix, useful for tables or custom display contexts: "1.500.000"
    case Plain = '';
}
```

This is a backed enum where each case carries a string value. The string value is not arbitrary; it is the exact prefix that will be prepended to the formatted number. When the style is `Plain`, the value is an empty string, which means no prefix is added. Using a backed enum here is better than a set of string constants because PHP will reject any value that is not a valid case at the call site, giving you a type error rather than a silent formatting bug.

### Creating the Rupiah Class

Create the file `src/Rupiah.php` and add the following content.

```php
<?php

namespace QadrLabs\Rupiah;

class Rupiah
{
    /**
     * Format a numeric amount as Indonesian Rupiah.
     *
     * @param int|float $amount The amount to format. Float values are rounded to the nearest integer.
     * @param RupiahStyle $style The output style. Defaults to the standard "Rp" prefix.
     */
    public static function format(int|float $amount, RupiahStyle $style = RupiahStyle::WithPrefix): string
    {
        // Round float values to the nearest integer first.
        // The Indonesian Rupiah has no subunit (no sen), so decimal places are meaningless.
        $rounded = (int) round($amount);

        // Format the number using period as the thousands separator.
        // number_format(amount, decimals, decimal_separator, thousands_separator)
        $formatted = number_format($rounded, 0, ',', '.');

        // Retrieve the prefix from the enum's backing value.
        $prefix = $style->value;

        // If the style is Plain, there is no prefix to prepend.
        if ($prefix === '') {
            return $formatted;
        }

        return $prefix . ' ' . $formatted;
    }

    /**
     * Parse a Rupiah-formatted string back to an integer.
     *
     * Handles "Rp 1.500.000", "IDR 1.500.000", and "1.500.000" equally.
     */
    public static function parse(string $value): int
    {
        // Strip every character that is not a digit.
        // This removes "Rp", "IDR", spaces, and period thousand separators in one pass.
        $digits = preg_replace('/[^0-9]/', '', $value);

        return (int) $digits;
    }
}
```

The `format()` method accepts both `int` and `float` because developers often work with amounts that arrive from calculations or API responses as floats. The `round()` call converts those floats to the nearest integer before formatting, which reflects how Rupiah amounts are actually displayed in practice. The `number_format()` call is where the Indonesian convention is applied: zero decimal places, a comma as the (unused) decimal separator, and a period as the thousands separator.

The `parse()` method takes the opposite approach. Instead of mapping prefixes to logic, it simply strips every character that is not a digit. This is safe for Rupiah because the currency has no decimal component; there are no cents to worry about. A string like `"Rp 1.500.000"` becomes `"1500000"` after stripping, which then casts cleanly to the integer `1500000`.

## Step 3: Write Tests with Pest {#step-3-tests}

The library code is ready, but shipping code without tests means every consumer of the library is implicitly acting as your test suite. Before pushing anything to GitHub, you should verify that each behavior is correct and document it through tests.

Install Pest as a development dependency.

```bash
composer require pestphp/pest --dev
```

Then initialize Pest, which creates the `tests/Pest.php` configuration file.

```bash
./vendor/bin/pest --init
```

The `--init` command creates a `tests/Pest.php` file and a base `tests/TestCase.php` class. By default, Pest generates these using the `Tests` namespace. However, since we mapped the `tests/` directory to the `QadrLabs\Rupiah\Tests\` namespace in our `composer.json`, we need to update both files to prevent autoloading errors.

First, open `tests/TestCase.php` and update the namespace:

```php
<?php

namespace QadrLabs\Rupiah\Tests;

use PHPUnit\Framework\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    //
}
```

Next, open `tests/Pest.php` and update the `pest()->extend(...)` reference to use the correct namespace:

```php
// ...
pest()->extend(QadrLabs\Rupiah\Tests\TestCase::class)->in('Feature');
// ...
```

This configuration file (`tests/Pest.php`) is loaded automatically before every test run and is where you configure global test behavior.

Now you are ready to write the actual tests. Create the test file at `tests/RupiahTest.php`.

```php
<?php

use QadrLabs\Rupiah\Rupiah;
use QadrLabs\Rupiah\RupiahStyle;

it('formats a basic amount with the Rp prefix', function () {
    expect(Rupiah::format(1500000))->toBe('Rp 1.500.000');
});

it('formats zero correctly', function () {
    // Zero is a valid amount and should format without error.
    expect(Rupiah::format(0))->toBe('Rp 0');
});

it('formats using the ISO style', function () {
    expect(Rupiah::format(2500000, RupiahStyle::ISO))->toBe('IDR 2.500.000');
});

it('formats without any prefix using the Plain style', function () {
    expect(Rupiah::format(750000, RupiahStyle::Plain))->toBe('750.000');
});

it('rounds a float value before formatting', function () {
    // 99999.5 rounds up to 100000.
    expect(Rupiah::format(99999.5))->toBe('Rp 100.000');
});

it('parses a Rp prefixed string back to an integer', function () {
    expect(Rupiah::parse('Rp 1.500.000'))->toBe(1500000);
});

it('parses an IDR prefixed string back to an integer', function () {
    expect(Rupiah::parse('IDR 2.500.000'))->toBe(2500000);
});

it('parses a plain formatted string back to an integer', function () {
    expect(Rupiah::parse('750.000'))->toBe(750000);
});
```

Each test has a single, clear responsibility. Notice that the tests for `parse()` cover all three string formats that `format()` can produce. If you ever change the output format, these tests will immediately tell you whether `parse()` still handles the new format correctly.

Run the tests using the `composer test` script you defined earlier.

```bash
composer test
```

You should see the following output.

```
   PASS  RupiahTest
  ✓ it formats a basic amount with the Rp prefix                   0.02s
  ✓ it formats zero correctly                                       0.01s
  ✓ it formats using the ISO style                                  0.01s
  ✓ it formats without any prefix using the Plain style             0.01s
  ✓ it rounds a float value before formatting                       0.01s
  ✓ it parses a Rp prefixed string back to an integer              0.01s
  ✓ it parses an IDR prefixed string back to an integer            0.01s
  ✓ it parses a plain formatted string back to an integer          0.01s

  Tests:    8 passed (8 assertions)
  Duration: 0.13s
```

All eight tests pass. The library behaves exactly as designed.

## Step 4: Prepare for Publishing {#step-4-prepare}

Before you push anything to GitHub and submit to Packagist, there are three files you should create: a README, a LICENSE, and a `.gitignore`. Together, these make the difference between a package that looks trustworthy and one that looks abandoned after a first release.

### Creating the README

The `README.md` file is what Packagist displays on your package's detail page and what GitHub shows at the root of the repository. Keep it focused: explain what the package does, show the installation command, and give usage examples. Create `README.md` in the project root.

```markdown
# php-rupiah

A lightweight PHP 8.3+ library to format and parse Indonesian Rupiah (IDR) currency values. Zero external dependencies.

## Installation

composer require qadrlabs/php-rupiah

## Usage

use QadrLabs\Rupiah\Rupiah;
use QadrLabs\Rupiah\RupiahStyle;

// Standard Rp prefix (default)
Rupiah::format(1500000);                        // "Rp 1.500.000"

// ISO currency code
Rupiah::format(1500000, RupiahStyle::ISO);      // "IDR 1.500.000"

// No prefix, useful for tables or custom rendering
Rupiah::format(1500000, RupiahStyle::Plain);    // "1.500.000"

// Float values are rounded to the nearest integer
Rupiah::format(99999.5);                        // "Rp 100.000"

// Parse any of the above formats back to an integer
Rupiah::parse('Rp 1.500.000');                  // 1500000
Rupiah::parse('IDR 1.500.000');                 // 1500000
Rupiah::parse('1.500.000');                     // 1500000

## Testing

composer test

## License

MIT
```

### Creating the LICENSE

Create a `LICENSE` file in the project root with the following MIT license text. Replace `[year]` with the current year and `[fullname]` with your name or organization.

```
MIT License

Copyright (c) 2025 Qadr Labs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Creating the .gitignore

The `vendor/` directory must not be committed to version control. Libraries also must not commit `composer.lock` (more on why in the [Understanding the Package Structure](#understanding-structure) section below). Create `.gitignore` in the project root.

```
/vendor/
composer.lock
.phpunit.result.cache
/.pest
```

### Pushing to GitHub and Tagging a Release

Initialize a Git repository, make the initial commit, and push to your GitHub repository.

```bash
git init
git add .
git commit -m "Initial release: format and parse Indonesian Rupiah"
git branch -M main
git remote add origin https://github.com/qadrlabs/php-rupiah.git
git push -u origin main
```

After the push, tag the first release. Packagist uses Git tags as version identifiers, so this step is what makes `v1.0.0` appear as an installable version on Packagist.

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `v` prefix in `v1.0.0` is a convention that Packagist and Composer both recognize. Always prefix your tags with `v`.

## Step 5: Submit to Packagist {#step-5-packagist}

With the code on GitHub and a release tagged, you are ready to publish. Open your browser and go to packagist.org. If you do not have an account yet, click "Login" and use the "Login with GitHub" option. This is the easiest path because Packagist can then connect directly to your GitHub repositories.

Once you are logged in, click "Submit" in the top navigation bar. You will see a single input field asking for the repository URL. Enter the HTTPS URL of your GitHub repository, for example `https://github.com/qadrlabs/php-rupiah`. Click "Check". Packagist will read your `composer.json`, validate the package name, and show you a preview of how the package will appear.

Click "Submit". Packagist will index your repository, pull the tags, and within a few seconds your package page at `packagist.org/packages/qadrlabs/php-rupiah` will be live.

### Connecting the GitHub Webhook

By default, Packagist checks for updates every 12 hours. To get instant updates every time you push a new tag, you should connect the GitHub webhook. On your Packagist package page, look for the "GitHub Hook" section and click "Connect". Packagist will automatically configure a webhook on your GitHub repository. From that point on, every push to GitHub (including new tags) will immediately trigger a Packagist re-index.

## Step 6: Try It Out {#step-6-try}

The real proof that everything worked is installing your own package in a fresh project. Open a new terminal window, navigate outside your library directory, and create a test project.

```bash
mkdir rupiah-demo
cd rupiah-demo
composer require qadrlabs/php-rupiah
```

Composer will fetch the package from Packagist and install it into `vendor/`. Now create a file called `demo.php` in the project root.

```php
<?php

require __DIR__ . '/vendor/autoload.php';

use QadrLabs\Rupiah\Rupiah;
use QadrLabs\Rupiah\RupiahStyle;

$amount = 1750000;

echo "Standard:  " . Rupiah::format($amount) . PHP_EOL;
echo "ISO:       " . Rupiah::format($amount, RupiahStyle::ISO) . PHP_EOL;
echo "Plain:     " . Rupiah::format($amount, RupiahStyle::Plain) . PHP_EOL;

$parsed = Rupiah::parse('Rp 1.750.000');
echo "Parsed:    " . $parsed . PHP_EOL;
```

Run it.

```bash
php demo.php
```

You should see the following output.

```
Standard:  Rp 1.750.000
ISO:       IDR 1.750.000
Plain:     1.750.000
Parsed:    1750000
```

Your library is live on Packagist and installable by any PHP developer in the world.

## Understanding the Package Structure {#understanding-structure}

Now that everything is working, it is worth taking a closer look at the decisions behind the structure and configuration so you can apply the same reasoning to your own libraries.

### Anatomy of composer.json

The `name` field uses the `vendor/package` format and must be globally unique across all of Packagist. The vendor name (`qadrlabs`) typically matches your GitHub organization or username. The `type` field being set to `library` is important because it tells Composer and Packagist that this is a reusable package rather than a full application or plugin. The `keywords` array improves discoverability on Packagist's search. The `require` block specifies only production dependencies; `require-dev` lists tools that are only needed during development. When someone runs `composer require qadrlabs/php-rupiah` in their project, Composer installs only what is in `require`, not `require-dev`.

The `autoload` and `autoload-dev` blocks define PSR-4 namespace mappings. PSR-4 is the modern PHP standard for autoloading: Composer maps a namespace prefix to a directory, and any class that lives under that namespace is found by following a predictable path convention. The class `QadrLabs\Rupiah\Rupiah` is loaded from `src/Rupiah.php` because the mapping says that `QadrLabs\Rupiah\` corresponds to `src/`. You never need to write a `require_once` statement manually.

### Why Libraries Must Not Commit composer.lock

A `composer.lock` file records the exact versions of every dependency that were installed at a specific point in time. For applications (web projects, APIs, CLI tools), committing the lock file is correct because it guarantees that every environment, from your laptop to production, uses the exact same dependency tree.

For libraries, committing `composer.lock` causes a conflict. When your library is installed as a dependency inside someone else's project, Composer ignores your library's lock file entirely and uses only the project's own lock file. So a committed `composer.lock` in a library only locks versions for your own development environment, which is far less useful. More importantly, it pollutes the repository with a file that gives consumers the false impression that those locked versions are required. The correct approach is to keep the lock file in `.gitignore` and let the `composer.json` version constraints do the work.

## How Semantic Versioning Works {#semver}

Packagist organizes installable versions by reading your Git tags. Every tag that follows the format `vMAJOR.MINOR.PATCH` becomes a version on the package page. Understanding when to increment each segment is important because it communicates the nature of a change to everyone who depends on your library.

The `PATCH` segment (the rightmost number) is incremented when you fix a bug without changing any existing behavior. If `Rupiah::format(0)` was returning an empty string and you fix it to return `"Rp 0"`, that is a patch release: `v1.0.1`.

The `MINOR` segment is incremented when you add new functionality in a way that is fully backward compatible. If you add a new method `Rupiah::formatShort()` without changing `format()` or `parse()`, that is a minor release: `v1.1.0`. Existing code that uses only `format()` and `parse()` will continue to work without any changes.

The `MAJOR` segment is incremented when you make a breaking change, meaning a change that requires existing consumers to update their code. If you rename `RupiahStyle::WithPrefix` to `RupiahStyle::Standard`, any project that references `RupiahStyle::WithPrefix` will break. That warrants a major release: `v2.0.0`. Composer's `^1.0` constraint means "any version compatible with 1.0", so it will never automatically upgrade past `v1.x.x`. This protects consumers from accidental breaking changes.

To release a new version, the workflow is: make your changes, commit, add a new tag, and push the tag.

```bash
git add .
git commit -m "feat: add formatShort method for compact display"
git tag v1.1.0
git push origin main
git push origin v1.1.0
```

If the GitHub webhook is connected, Packagist will pick up `v1.1.0` within seconds.

## Conclusion {#conclusion}

Building and publishing a PHP library is a skill that pays dividends far beyond the first package. Once you understand the workflow, any piece of reusable logic in your codebase becomes a candidate for extraction. Here are the key takeaways from this tutorial.

- **PSR-4 autoloading removes manual `require` calls.** By mapping a namespace to a directory in `composer.json`, Composer resolves and loads every class automatically. You only need to declare the `use` statement in your files.
- **Backed enums make APIs self-documenting.** Using `RupiahStyle::ISO` instead of a plain string `"IDR"` means PHP validates the input at the type level and your IDE can autocomplete the options. Callers cannot pass an invalid style.
- **`require` and `require-dev` must be kept separate.** Only production dependencies go in `require`. Test frameworks and static analysis tools belong in `require-dev` so they are never installed in consumer projects.
- **Libraries must not commit `composer.lock`.** The lock file belongs in applications, not in reusable packages. Add it to `.gitignore` and let `composer.json` version constraints express your compatibility guarantees.
- **Git tags are versions.** Packagist reads your repository tags to build the version list. Follow the `vMAJOR.MINOR.PATCH` format and the GitHub webhook will automatically keep your Packagist listing in sync.
- **Semantic versioning communicates intent.** A `PATCH` bump means "safe to update, bug fix only". A `MINOR` bump means "safe to update, new features added". A `MAJOR` bump means "review the changelog before updating, there are breaking changes."