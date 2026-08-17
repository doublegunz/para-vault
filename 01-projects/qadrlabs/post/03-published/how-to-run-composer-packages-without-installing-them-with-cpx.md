# How to Run Composer Packages Without Installing Them with CPX

Our [Laracon US 2026 recap](https://qadrlabs.com/post/everything-announced-at-laracon-us-2026-laravel-ai-and-cloud-updates#laravel-framework-and-developer-tooling-announcements) introduced CPX as one of Laravel's developer tooling announcements. The short version was simple: CPX lets PHP developers execute commands from Composer packages without permanently adding those packages to a project.

That description covers the main idea, but CPX becomes more useful once you see how it fits into an actual Composer workflow. It can keep an experimental tool separate from your application, reuse the package on later runs, respect a version constraint, and prefer a binary that your project already has installed.

In this tutorial, you will use CPX 2.x inside a fresh Laravel 13 project. You will run PHP CS Fixer without adding it to the project, compare an isolated package with Laravel Pint's local binary, and create a shorter alias for a package name you do not want to type repeatedly.

## Overview {#overview}

The project itself will remain unchanged while CPX downloads and runs development tools from its own cache. This gives you a concrete way to evaluate a Composer package before deciding whether it belongs in your project's dependencies.

### What You'll Build

- A Laravel 13 test project for trying CPX safely.
- A one-off PHP CS Fixer workflow that does not modify `composer.json` or `composer.lock`.
- A comparison between an isolated Composer package and the local Laravel Pint binary.
- A personal `fixer` alias for the longer `friendsofphp/php-cs-fixer` package name.

### What You'll Learn

- How to install and verify CPX 2.x.
- How to execute a command from a package that is not installed in your project.
- How to select a compatible package version with a Composer constraint.
- How CPX chooses between a local project binary and an isolated package.
- How to force isolated execution with `--skip-local`.
- How to create, inspect, use, and remove a CPX alias.

### What You'll Need

- PHP 8.3 or newer. CPX 2.x requires PHP 8.3 or newer.
- [Composer](https://getcomposer.org/) installed and available from your terminal.
- The [Laravel installer](https://laravel.com/docs/13.x/installation) available as the `laravel` command.
- Composer's global binary directory on your `PATH`.
- Basic familiarity with Composer packages and terminal commands.
- An internet connection for the first installation of each isolated package.

## Step 1: Create the Laravel Test Project {#step-1-create-the-laravel-test-project}

Start with a fresh Laravel 13 application. It gives us a real Composer project and includes Laravel Pint as a development dependency, which will become useful when we examine CPX's local binary behavior.

Run the Laravel installer:

```bash
laravel new cpx-demo --no-interaction --database=sqlite --pest --no-boost
cd cpx-demo
```

The command creates a Laravel project backed by SQLite and includes Pest without installing Laravel Boost. Verify the framework version after the installation finishes:

```bash
php artisan --version
```

The project used for this tutorial returned:

```text
Laravel Framework 13.23.0
```

Laravel releases regularly, so a newer Laravel 13 patch version is fine. The important part is that the application installs successfully and includes its Composer dependencies.

Before adding any other tools, confirm that Laravel Pint is a direct development dependency:

```bash
composer show laravel/pint --direct
```

Composer will display Pint's package information, including its installed version and local path. We will compare this local installation with an isolated CPX package in Step 5.

## Step 2: Install and Verify CPX {#step-2-install-and-verify-cpx}

[CPX](https://github.com/laravel/cpx) is the one global tool required for this workflow. The packages it executes do not need to share CPX's global Composer dependency tree because CPX 2.x is distributed as a self-contained PHAR.

Install CPX globally with Composer:

```bash
composer global require cpx/cpx
```

Composer places the `cpx` executable in its global binary directory. If your shell cannot find the command, ask Composer for the exact directory:

```bash
composer global config bin-dir --absolute
```

Add the returned directory to your shell's `PATH`, reopen the terminal if necessary, and verify the installation:

```bash
cpx --version
```

The tested CPX release returned:

```text
cpx v2.0.0
```

This tutorial targets CPX 2.x. The [official upgrade guide](https://github.com/laravel/cpx/blob/2.x/UPGRADE.md) states that CPX 1.x is frozen and no longer receives bug fixes or security fixes.

## Step 3: Run a Package Without Installing It {#step-3-run-a-package-without-installing-it}

You can now execute a command from a Composer package by passing its package name to CPX. We will use PHP CS Fixer because it provides a clear CLI command and is not installed directly in a fresh Laravel application.

Confirm that the package is not present:

```bash
composer show friendsofphp/php-cs-fixer --direct
```

Composer reports that the package cannot be found. That result is expected because the package is not listed as a direct project dependency.

Run its version command through CPX:

```bash
cpx friendsofphp/php-cs-fixer --version
```

On the first run, CPX resolves the package, installs it in a separate directory under `~/.cpx/`, locates its binary, and forwards `--version` to that binary. The tested command returned:

```text
PHP CS Fixer 3.95.18 Adalbertus by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.5.4
```

Your package and PHP patch versions may be newer. The significant result is that PHP CS Fixer runs even though the Laravel project does not require it.

Run the Composer check again:

```bash
composer show friendsofphp/php-cs-fixer --direct
```

Composer still reports that the package is not installed in the project. You can also ask Git to check the dependency files:

```bash
git diff --exit-code -- composer.json composer.lock
```

A successful command produces no output. CPX has not edited either file because the PHP CS Fixer installation belongs to CPX's isolated package cache.

## Step 4: Select a Package Version {#step-4-select-a-package-version}

Running an unconstrained package is convenient when you want the current compatible release. A version constraint is more appropriate when a command needs to remain within a known release line or when you want another developer to reproduce the same compatibility range.

Append a Composer constraint to the package name:

```bash
cpx friendsofphp/php-cs-fixer:^3.0 --version
```

CPX passes the constraint to Composer and keeps this package specification separate from the unconstrained one. In the tested environment, the constraint resolved to the same current PHP CS Fixer release:

```text
PHP CS Fixer 3.95.18 Adalbertus by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.5.4
```

The matching output is not guaranteed forever. It only means that version 3.95.18 satisfies `^3.0` at the time of the test. If PHP CS Fixer later publishes version 4, the constraint keeps this command on a compatible 3.x release while the unconstrained command may resolve differently.

CPX reuses an existing isolated installation on later runs when the package specification still matches. This makes repeated commands faster than the initial download.

## Step 5: Use Local Project Binaries {#step-5-use-local-project-binaries}

CPX 2.x does not always create an isolated package. It first searches for the nearest Composer project and checks the project's configured binary directory, which is `vendor/bin` by default. If a compatible local binary exists, CPX prefers it.

Check the local Pint version directly:

```bash
vendor/bin/pint --version
```

The test project returned:

```text
Pint 1.30.3
```

Now run the same binary name through CPX:

```bash
cpx pint --version
```

The result matches the project binary:

```text
Pint 1.30.3
```

A bare name works here because CPX finds `vendor/bin/pint` in the current Composer project. This behavior keeps the command aligned with the version recorded in the project's lock file.

Sometimes you may intentionally want to ignore the project binary and evaluate an isolated package. Place `--skip-local` before the package name and run Pint in test mode:

```bash
cpx --skip-local laravel/pint --test
```

The tested command ran the isolated package successfully. In an agent-detected terminal, Pint returned:

```json
{"tool":"pint","result":"passed"}
```

In a regular interactive terminal, Pint renders its normal formatted progress and success output instead. In both cases, `--test` checks formatting without changing files.

You can confirm that CPX now manages an isolated Pint package:

```bash
cpx installed
```

The list includes `laravel/pint` alongside the PHP CS Fixer specifications used in the previous steps. Running `cpx pint` without `--skip-local` still prefers the project's own Pint binary.

## Step 6: Create a Package Alias {#step-6-create-a-package-alias}

Full Composer package names are useful because they are unambiguous, but they can become tedious for a tool you run frequently. CPX lets you associate a short personal alias with a package.

Create `fixer` as an alias for PHP CS Fixer:

```bash
cpx alias friendsofphp/php-cs-fixer fixer
```

CPX stores the alias under `~/.cpx/`, not in the Laravel project. List your aliases to verify it:

```bash
cpx aliases
```

An interactive terminal presents both commands with formatted confirmation messages. CPX also supports JSON output, which is useful when you want a stable machine-readable result:

```bash
cpx aliases --json
```

The tested command returned:

```json
{"success":true,"errors":[],"summary":{"aliases":{"fixer":"friendsofphp/php-cs-fixer"}}}
```

Use the shorter name to run the package:

```bash
cpx fixer --version
```

CPX resolves `fixer` to `friendsofphp/php-cs-fixer`, then runs the package binary:

```text
PHP CS Fixer 3.95.18 Adalbertus by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.5.4
```

Aliases are user-specific conveniences. They are not recorded in `composer.json`, so documentation and team automation should generally use the complete package name unless the team separately standardizes its CPX aliases.

## Step 7: Try It Out {#step-7-try-it-out}

You have now exercised the essential CPX workflow. These final checks bring the isolated package, local binary, alias, and unchanged project dependencies together.

### Run an Isolated Code Style Check

Use the alias to run a real PHP CS Fixer check against the generated route file:

```bash
cpx fixer fix --dry-run --diff --using-cache=no --show-progress=none routes/web.php --rules=@PSR12
```

The `fix` command selects PHP CS Fixer's formatting operation. The `--dry-run` option reports changes without writing them, while `--diff` would show the required changes if the file failed. Disabling the cache prevents this one-off check from creating a cache file in the project, and `--show-progress=none` keeps the result compact.

The test environment used PHP 8.5 for a project whose `composer.json` supports PHP 8.3 and newer, so PHP CS Fixer printed its compatibility warning before the successful result:

```text
You are running PHP CS Fixer on PHP 8.5.4, but the minimum PHP version supported by your project in composer.json is PHP 8.3. Executing PHP CS Fixer on newer PHP versions may introduce syntax or features not yet available in PHP 8.3, which could cause issues under that version. It is recommended to run PHP CS Fixer on PHP 8.3, to fit your project specifics.
If you need help while solving warnings, ask at https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/discussions/, we will help you!

PHP CS Fixer 3.95.18 Adalbertus by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.5.4
Loaded config default.
Running analysis on 7 cores with 10 files per process.
Rules from configuration have been overridden by rules provided as command argument.

Found 0 of 1 files that can be fixed in 0.005 seconds, 16.00 MB memory used
```

The final line confirms that `routes/web.php` already satisfies the selected PSR-12 rules. If you run the tutorial on PHP 8.3, the PHP 8.5 compatibility warning will not appear.

### Check Formatting with the Local Pint Binary

Run Pint through CPX without `--skip-local`:

```bash
cpx pint --test
```

Because the Laravel project already installs Pint, CPX uses `vendor/bin/pint`. The tested agent environment returned:

```json
{"tool":"pint","result":"passed"}
```

The successful result confirms that the generated Laravel project follows its configured Pint rules. A regular interactive terminal may render this result differently.

### Confirm That Project Dependencies Did Not Change

Check the Composer files one final time:

```bash
git diff --exit-code -- composer.json composer.lock
```

The command should complete without output. Neither the isolated PHP CS Fixer package nor the CPX alias changes the project's dependency declarations.

Run the existing Laravel tests as a final project health check:

```bash
php artisan test --colors=never
```

The untouched Laravel 13 project returned:

```text
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.14s  

  Tests:    2 passed (2 assertions)
  Duration: 0.20s
```

After finishing the exercise, remove the personal alias if you do not want to keep it:

```bash
cpx unalias fixer
```

Removing the alias does not uninstall the cached package. CPX provides separate package maintenance commands, but those are outside the focused workflow in this tutorial.

## How CPX Resolves and Runs Packages {#how-cpx-resolves-and-runs-packages}

The commands in this tutorial follow a predictable resolution process. Understanding that process helps explain why the same `cpx` command can sometimes use `vendor/bin` and sometimes use an isolated installation.

When you run a name such as `cpx fixer`, CPX first resolves any user-defined alias. It then looks for the nearest Composer project by walking upward from the current directory. If the project has a matching binary and its installed package satisfies any supplied constraint, CPX runs that local binary.

If CPX cannot find a compatible local binary, it resolves the Composer package in its own cache. The first run installs the package separately from your application and global Composer dependencies. Later runs can reuse that installation, although CPX may check whether an update is available. A different version constraint receives its own cached package location.

The `--skip-local` option bypasses the local binary lookup. It is useful for comparing the project's pinned tool with an isolated release, but it should be intentional. The default local preference is normally the safer choice for commands that belong to the project's established workflow.

CPX 2.x itself avoids the usual global dependency collision problem by shipping as a self-contained PHAR. The packages it executes remain separated from the dependencies bundled inside CPX, from the application's dependencies, and from other globally installed Composer tools.

## When to Use CPX and When to Install a Dependency {#when-to-use-cpx-and-when-to-install-a-dependency}

CPX makes temporary package execution convenient, but it does not make project dependencies unnecessary. The right choice depends on how important the tool is to the project's repeatable workflow.

- **Use CPX for evaluation.** Try a code quality tool, generator, or analyzer before deciding whether the project should adopt it.
- **Use CPX for occasional commands.** A tool used once or rarely does not always need a permanent entry in the project.
- **Use a version constraint for repeatability.** A constraint such as `^3.0` prevents an experiment from unexpectedly crossing a major version boundary.
- **Install recurring tools in the project.** Formatters, test runners, and analyzers used by every contributor or by CI should normally be declared in `require-dev` and locked with the application.
- **Keep automation explicit.** Team scripts should not depend silently on aliases stored in one developer's home directory.
- **Run only trusted packages.** CPX isolates Composer dependencies, but the selected package still executes code with your user permissions and can access the current working directory.

Installing every CLI tool globally is another option, but it gives all those packages one shared global Composer dependency graph. CPX is most valuable when you want one global executor and separate installations for the packages it runs.

## Conclusion {#conclusion}

CPX brings a practical one-off execution workflow to Composer packages. It lets you test a tool without committing it to the application, while still respecting the tools and versions a project has deliberately installed.

- **Isolated package execution.** CPX can install and run a Composer package without adding it to the project's `composer.json` or `composer.lock`.
- **Local binary preference.** CPX 2.x uses a compatible project binary before creating or selecting an isolated installation.
- **Version control.** Composer constraints let an isolated command remain within an intended compatibility range.
- **Convenient aliases.** Personal aliases shorten frequently used package names without changing the application.
- **Intentional adoption.** Tools that become part of development or CI should still be installed and locked as project dependencies.
- **Trusted execution.** Dependency isolation prevents Composer conflicts, but it does not replace reviewing the code you choose to run.
