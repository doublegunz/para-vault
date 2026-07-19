# What's New in Laravel Installer 5.31.0: Package Scaffolding Comes to the CLI

Laravel Installer has always been the fastest way to start a new application, but it stopped at applications. If you wanted to build a reusable package, you were on your own: pick a directory structure, wire up Composer autoloading, register a service provider, prepare tests, and strip out every placeholder that did not fit your package.

That gap is easy to overlook because most developers think of Laravel Installer as the `laravel new` command and nothing more. Yet the tool ships focused improvements on its own schedule, and this release is a good example of why it is worth watching.

Laravel Installer 5.31.0, published on July 16, 2026, adds a `laravel package` command built around Laravel's official package skeleton, and it ships four smaller fixes for compatibility, Windows queue development, starter kit hooks, and GitHub Actions configuration. This article walks through each change and explains where it matters.

## Overview {#overview}

This is a release overview rather than a build-along tutorial. The goal is to understand what changed in v5.31.0, why each change exists, and whether the update is worth pulling onto your machine. Code appears throughout as illustration of the new behavior, not as steps to reproduce a specific project.

### What's New in This Release

- A new `laravel package` command that scaffolds a Laravel package from the official skeleton.
- A compatibility fallback for older versions of `laravel/prompts` that lack `callout()`.
- An explicit `--timeout=0` on the generated Windows queue listener.
- Propagation of `--no-node` into starter kit installer hooks.
- Automatic alignment of a starter kit's GitHub Actions PHP version with your local PHP.

### What You'll Learn

- What the `laravel package` command does and how it works under the hood.
- Which feature flags and metadata options the package command accepts.
- How the four application-creation fixes change day-to-day development.
- Whether this release is worth upgrading to for your workflow.

### What You'll Need

- Laravel Installer 5.31.0 to try any of the new behavior.
- Composer 2, plus Git and an internet connection for the package skeleton.
- PHP 8.3 or newer for the current official package skeleton.
- Basic familiarity with Composer packages and Laravel service providers.

## The New laravel package Command {#the-new-laravel-package-command}

The headline of v5.31.0 is a new command that extends Laravel Installer from an application generator into a package generator. [Pull request #546](https://github.com/laravel/installer/pull/546) adds a dedicated `PackageCommand` that coordinates the installer with the separate official skeleton repository, so the same tool you already use for `laravel new` can now bootstrap a distributable package.

The simplest form accepts a directory name and opens an interactive configurator:

```bash
laravel package my-package
```

Laravel Installer clones the official skeleton and then asks for package metadata, optional package features, development tools, and repository preferences. The interactive path is convenient when you want to see the available choices without memorizing flags.

### Flag-Driven Configuration

The same command accepts every choice as an option, which produces a deterministic scaffold without any prompts. A fully specified invocation looks like this:

```bash
laravel package my-package \
    --config \
    --routes \
    --migrations \
    --commands \
    --facade \
    --author-name="Acme Team" \
    --author-email="developer@example.com" \
    --package-name="acme/my-package" \
    --package-name-human="My Package" \
    --package-description="Example tools for Laravel applications" \
    --vendor-namespace="Acme" \
    --class-name="MyPackage" \
    --no-interaction
```

The first argument, `my-package`, is the local directory name. The `--package-name` value becomes the Composer package name, while `--vendor-namespace` and `--class-name` determine the PHP namespace and primary class names.

The boolean flags request concrete package capabilities. For example, `--config` keeps a publishable configuration file, `--commands` creates an Artisan command structure, and `--facade` prepares a facade for the package's main service. The `--no-interaction` option tells both Laravel Installer and the skeleton's configurator to use the supplied values without pausing, which makes the command a good fit for scripts and coding agents that need to scaffold packages the same way every time.

### How the Command Works Under the Hood

The command is more than a shortcut for copying files. It runs the following stages in order:

1. Laravel Installer clones `https://github.com/laravel/package-skeleton.git` into the target directory.
2. It removes the skeleton's `.git` directory so the new package does not inherit Laravel's repository history.
3. It runs `composer install --no-scripts` inside the package directory.
4. It invokes the skeleton's `configure.php` script and forwards the selected features and metadata.

Installing dependencies without Composer scripts matters during the third stage. The generic skeleton has not been customized yet, so Laravel Installer waits until the metadata is available before running the configurator. This ordering is why the installer can delegate all package-specific customization to `laravel/package-skeleton` rather than duplicating that logic itself.

### Available Feature and Metadata Options

Laravel Installer 5.31.0 exposes these boolean feature options:

```text
--config
--routes
--views
--translations
--migrations
--assets
--commands
--facade
--boost-skill
```

You only pass the features that belong in the package. Leaving a flag out allows the configurator to remove the corresponding placeholder structure, so the generated package contains only what you asked for.

The command also accepts these metadata options:

```text
--author-name
--author-email
--package-name
--package-name-human
--package-description
--vendor-namespace
--class-name
```

These are especially helpful when a script or coding agent needs to scaffold a package deterministically. If you omit them in an interactive terminal, the configurator prompts for the missing information or derives sensible defaults.

### Current Directory and Force Mode

A dot installs the package into the current directory:

```bash
laravel package .
```

Use this form only inside an empty directory prepared for the package, because Git cannot clone the skeleton into a non-empty directory that already contains unrelated files.

The `--force` option has stronger, destructive behavior:

```bash
laravel package my-package --force
```

Before cloning the skeleton, Laravel Installer removes the existing `my-package` target. It also rejects `--force` when the target is the current directory. Treat this option as destructive and confirm the target name before running it.

## Compatible Output for Older Laravel Prompts {#compatible-output-for-older-laravel-prompts}

Beyond the new command, v5.31.0 tightens several integration points around ordinary application creation. The first involves the `Application ready` callout that Laravel Installer can display after creating a project. Not every supported version of `laravel/prompts` provides the `Laravel\Prompts\callout()` function, so calling it unconditionally could break output on older resolved versions.

[Pull request #549](https://github.com/laravel/installer/pull/549) now checks the function before calling it:

```php
if (function_exists('Laravel\\Prompts\\callout')) {
    // Render the newer Application ready callout.
} else {
    // Render the compatible plain output.
}
```

This fallback changes only the final presentation. Project creation still finishes cleanly when Composer resolves an older compatible release of Laravel Prompts, so the installer keeps working across the full supported range of that dependency.

## Unlimited Queue Listener Timeout on Windows {#unlimited-queue-listener-timeout-on-windows}

The next fix targets local queue development on Windows. Laravel Installer adjusts the generated Composer development script on Windows to use `queue:listen`, and [pull request #550](https://github.com/laravel/installer/pull/550) adds an explicit timeout to that command:

```bash
php artisan queue:listen --tries=1 --timeout=0
```

The zero value disables the per-job timeout for this local listener, which prevents the generated Windows development command from stopping a long-running job after the default timeout.

The change applies to the local `composer run dev` workflow only. Production queue workers still need timeout and process supervision settings chosen for the application's jobs and deployment environment, so this fix improves the developer experience without touching how you should run queues in production.

## Passing --no-node Into Starter Kit Hooks {#passing-no-node-into-starter-kit-hooks}

The fourth change closes a gap between the installer and starter kits. The `laravel new` command already supports skipping frontend dependency installation:

```bash
laravel new backend-app --no-node
```

Starter kits can define their own `post-create-project` hooks, so skipping Node.js in the main installer did not automatically communicate the choice to those hooks. [Pull request #551](https://github.com/laravel/installer/pull/551) now runs starter kit hooks with this environment value when `--no-node` is present:

```text
LARAVEL_INSTALLER_NO_NODE=1
```

The environment variable gives a starter kit's hook enough context to skip its own Node.js work. The hook still has to read and honor the value, but it no longer has to guess how the application was created.

## Matching GitHub Actions to the Local PHP Version {#matching-github-actions-to-the-local-php-version}

The final fix keeps generated continuous integration in sync with your machine. A starter kit may include a test workflow at `.github/workflows/tests.yml`, and before this release the workflow could retain the PHP version baked into the starter kit even when you created the application with a different local version.

[Pull request #553](https://github.com/laravel/installer/pull/553) updates matching `php-version` declarations to the major and minor version of the PHP runtime executing Laravel Installer. Creating a starter kit project with PHP 8.4, for example, produces:

```yaml
php-version: '8.4'
```

The adjustment only runs when a starter kit is selected, and it returns without making changes when `.github/workflows/tests.yml` does not exist. You can still replace the single value with a version matrix when the project needs to test multiple supported PHP releases.

## How to Update {#how-to-update}

Laravel Installer is installed globally through Composer, separate from the Laravel Framework dependency inside an application. Updating a project does not update this command-line tool, so you update it explicitly:

```bash
composer global update laravel/installer --with-all-dependencies
```

This asks Composer to update `laravel/installer` and allows its transitive dependencies to move to compatible versions. If Laravel Installer is not installed yet, install it with:

```bash
composer global require laravel/installer
```

Confirm the installed version before relying on the new features:

```bash
laravel --version
```

With v5.31.0 installed, the command returns:

```text
Laravel Installer 5.31.0
```

If your shell cannot find the `laravel` command, the official [Laravel installation documentation](https://laravel.com/docs/13.x/installation#creating-a-laravel-application) covers Composer's global binary directory.

## Should You Upgrade? {#should-you-upgrade}

Package authors receive the most visible benefit, because `laravel package` removes the repetitive first stage of package development. Application developers gain safer behavior across supported Prompts versions, Windows development queues, Node-free starter kit installation, and generated CI workflows.

The upgrade does not change existing Laravel applications. It changes what the global installer does the next time you run `laravel new` or `laravel package`, which makes it a low-friction update for most development machines. For the complete list of contributors and merged changes, see the official [Laravel Installer v5.31.0 release notes](https://github.com/laravel/installer/releases/tag/v5.31.0).

## Conclusion {#conclusion}

Laravel Installer 5.31.0 grows the tool from an application generator into a package generator while tightening several integration points around project creation.

- **Package scaffolding.** The new `laravel package` command creates a package from Laravel's official skeleton and supports both interactive and flag-driven configuration.
- **Repeatable metadata.** Feature and metadata options let developers or automation produce a consistent starting structure without answering prompts.
- **Output compatibility.** The installer falls back cleanly when the installed Laravel Prompts version does not provide `callout()`.
- **Windows queue development.** The generated Windows listener now uses `--timeout=0` for long-running local jobs.
- **Starter kit coordination.** Hooks can detect `--no-node`, and generated GitHub Actions workflows match the local PHP major and minor version.
