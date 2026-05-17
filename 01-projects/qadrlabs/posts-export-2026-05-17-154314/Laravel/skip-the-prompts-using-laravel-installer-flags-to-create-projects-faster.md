---
title: "Skip the Prompts: Using Laravel Installer Flags to Create Projects Faster"
slug: "skip-the-prompts-using-laravel-installer-flags-to-create-projects-faster"
category: "Laravel"
date: "2026-04-14"
status: "published"
---

Every time you run `laravel new`, the installer greets you with a series of questions. Which starter kit? Which authentication provider? Which database? Which testing framework? Would you like to run the package manager? The interactive experience is helpful the first time around, but once you know exactly what you want, answering each prompt one by one starts to feel like friction. If you create projects frequently, whether for production, client work, or quick experiments, those repeated prompts add up. The Laravel Installer supports a full set of flags that let you answer all of those questions upfront, directly in the command itself. A single well-constructed command can spin up a configured project without a single prompt appearing. This article walks through every available flag, what each one does under the hood, and how to combine them into commands for common project scenarios.

## Overview {#overview}

This article is a reference guide for the flags available in the `laravel new` command. Rather than following sequential steps, you will read through each flag category and then see practical command examples that combine them for real scenarios.

### What You'll Learn

By the end of this article, you will understand how to:

- Skip every interactive prompt when creating a new Laravel project.
- Choose a starter kit, authentication provider, database driver, testing framework, and Node package manager entirely from the command line.
- Set up Git and GitHub integration as part of project creation.
- Combine multiple flags into a single command for common project types.

### What You'll Need

Before getting started, make sure you have:

- The Laravel Installer installed globally via Composer (`composer global require laravel/installer`).
- PHP 8.2 or higher.
- For GitHub-related flags: the GitHub CLI (`gh`) installed and authenticated.


## Choosing a Starter Kit {#choosing-a-starter-kit}

When you run `laravel new` interactively, the first prompt asks which starter kit you want. A starter kit is a pre-built application scaffold that wires up a frontend framework with Laravel's backend, including routing, Vite configuration, and authentication views. There are four official options and one community escape hatch.

The `--react`, `--vue`, and `--svelte` flags each install their respective first-party starter kit. These kits include a complete Inertia.js setup with TypeScript, Tailwind CSS, and authentication scaffolding ready to go. The `--livewire` flag installs the Livewire starter kit, which uses server-rendered Blade components instead of a JavaScript SPA approach.

```
# React starter kit
laravel new my-app --react

# Vue starter kit
laravel new my-app --vue

# Svelte starter kit
laravel new my-app --svelte

# Livewire starter kit
laravel new my-app --livewire
```

The `--livewire-class-components` flag is a sub-option specific to the Livewire kit. By default, the Livewire starter kit uses single-file components where the class and the Blade template live together. If you prefer stand-alone class files separate from their templates, add `--livewire-class-components`. This flag has no effect when used with React, Vue, or Svelte.

```
# Livewire with stand-alone class components
laravel new my-app --livewire --livewire-class-components
```

If you want to use a community-maintained or custom starter kit instead of one of the official four, use `--using` followed by the package name or a repository URL:

```
# A community package on Packagist
laravel new my-app --using=vendor/starter-kit

# A GitHub repository via tiged
laravel new my-app --using=https://github.com/vendor/starter-kit
```

When no starter kit flag is provided and you want a plain Laravel installation without any frontend scaffolding, simply omit all starter kit flags and the installer will create a minimal project. If you are running in non-interactive mode (for example in a CI pipeline), no prompt will appear and the project will be created without a starter kit.


## Configuring Authentication {#configuring-authentication}

When you use one of the four official starter kits, the installer next asks how you want to handle authentication. Three flags control this, and they are only meaningful when a starter kit is selected.

The default behavior, with no authentication flag, is to use Laravel's built-in authentication system. If you want that default, you do not need to add any flag. The `--workos` flag switches the authentication provider to WorkOS, a third-party identity platform. This is useful if you need enterprise-grade features like SSO, SCIM provisioning, or social login out of the box, but it does require a WorkOS account.

```
# Vue starter kit with WorkOS authentication
laravel new my-app --vue --workos
```

The `--no-authentication` flag removes authentication scaffolding entirely. The installer will still set up the starter kit's frontend tooling, but it will use a blank variant of the kit that has no login, registration, or user management views. This is the right choice when you want the frontend stack but plan to build your own authentication flow from scratch, or when the project does not need authentication at all.

```
# React starter kit without any authentication views
laravel new my-app --react --no-authentication
```

The `--teams` flag adds team support to the application, creating the database structure and UI scaffolding for multi-tenant team management. It is compatible with the default Laravel authentication but not with `--workos` or `--no-authentication`.

```
# Livewire starter kit with teams support
laravel new my-app --livewire --teams
```

One combination worth understanding is `--workos` with `--livewire`. WorkOS and the `--teams` flag are mutually exclusive when using Livewire, so if you specify both `--workos` and `--teams`, the installer resolves to the WorkOS-teams variant of the starter kit automatically using a specific branch of the repository. The installer handles this branch selection for you; you just need to pass the right flags and it figures out which version to install.


## Selecting a Database {#selecting-a-database}

The `--database` flag accepts a single value that tells the installer which database driver to configure. The five valid values are `mysql`, `mariadb`, `pgsql`, `sqlite`, and `sqlsrv`. When you pass this flag, the installer updates both `.env` and `.env.example` automatically, setting `DB_CONNECTION` and adjusting `DB_PORT` where the default differs from MySQL's port 3306.

```
# MySQL (default port 3306, no port adjustment needed)
laravel new my-app --database=mysql

# PostgreSQL (installer automatically sets DB_PORT=5432)
laravel new my-app --database=pgsql

# SQL Server (installer automatically sets DB_PORT=1433)
laravel new my-app --database=sqlsrv

# SQLite
laravel new my-app --database=sqlite
```

SQLite deserves a special mention because its behavior differs from the other drivers. When you select SQLite, the installer comments out the `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, and `DB_PASSWORD` entries in `.env` and `.env.example`, since SQLite does not use a server-based connection. It also automatically runs the migrations for you after project creation, touching the `database/database.sqlite` file so the file-based database exists before the migrations run. This makes SQLite the fastest option for getting a fully migrated project with a single command, which is why it is a good choice for throwaway projects or local prototyping.

For the other drivers, the installer will ask in interactive mode whether you want to run migrations after updating the database configuration. If you are running non-interactively with `--database=mysql` (or any non-SQLite driver), migrations are not run automatically. You will need to run `php artisan migrate` manually after setting up your database credentials.


## Choosing a Testing Framework {#choosing-a-testing-framework}

Laravel ships with PHPUnit by default, but the installer can configure Pest instead during project creation. Two flags handle this: `--pest` installs Pest and runs the Drift tool to convert any existing test stubs from PHPUnit syntax to Pest syntax, and `--phpunit` explicitly keeps PHPUnit without being asked.

```
# Install with Pest
laravel new my-app --pest

# Keep PHPUnit explicitly (same as the default, but skips the prompt)
laravel new my-app --phpunit
```

The `--pest` flag does more than just add Pest to `composer.json`. It removes `phpunit/phpunit` as a dev dependency, requires `pestphp/pest` and `pestphp/pest-plugin-laravel`, runs `pest --init` to set up the Pest configuration file, and then temporarily installs `pestphp/pest-plugin-drift` to migrate the existing test stubs before removing it again. If you are using a starter kit, it also updates the GitHub Actions workflow file to use `./vendor/bin/pest` instead of `./vendor/bin/phpunit`.

The practical takeaway is that `--pest` produces a project that is fully configured and ready to write Pest tests immediately, with no manual setup required. If you neither pass `--pest` nor `--phpunit`, the installer will prompt you to choose. If you want to suppress that prompt in a non-interactive context, always pass one of the two flags explicitly.


## Selecting a Node Package Manager {#selecting-a-node-package-manager}

The installer can run the front-end build step for you immediately after creating the project. Four flags control which package manager it uses: `--npm`, `--pnpm`, `--bun`, and `--yarn`. When any of these flags is passed, the installer runs both the install command and the build command for that package manager without asking.

```
# Install and build with npm
laravel new my-app --vue --npm

# Install and build with pnpm
laravel new my-app --vue --pnpm

# Install and build with Bun
laravel new my-app --vue --bun

# Install and build with Yarn
laravel new my-app --vue --yarn
```

If none of these flags is passed, the installer checks the project directory for an existing lock file to determine which package manager was already in use. If it finds a `pnpm-lock.yaml` it will use PNPM, a `bun.lockb` it will use Bun, a `yarn.lock` it will use Yarn, and so on. For a fresh project there is no lock file, so it falls back to NPM. In that case the installer will ask interactively whether you want to run the install and build commands.

It is also worth noting that passing a package manager flag implicitly opts you into running the build. The installer treats the explicit flag as confirmation that you want it to proceed, so you will not be asked for confirmation. If you want to choose the package manager but defer the build to later, omit these flags and respond to the interactive prompt when it appears.


## Setting Up Git and GitHub {#setting-up-git-and-github}

The installer can initialize a local Git repository and optionally push it to GitHub as part of project creation. Two primary flags handle this, with two supporting flags for finer control.

The `--git` flag initializes a Git repository in the project directory, stages all files, and creates an initial commit with the message "Set up a fresh Laravel app". It also sets the default branch name. By default this is determined by your global Git configuration (`git config --global init.defaultBranch`), falling back to `main` if no value is set. You can override this with the `--branch` flag.

```
# Initialize a Git repo with the default branch name
laravel new my-app --git

# Initialize a Git repo with a custom branch name
laravel new my-app --git --branch=develop
```

The `--github` flag goes further. It initializes a Git repository (so you do not need `--git` separately), creates a new repository on GitHub using the GitHub CLI, and pushes the initial commit to it. The repository is created as private by default. You can pass a GitHub visibility flag as the value to override this:

```
# Create a private GitHub repository (default)
laravel new my-app --github

# Create a public GitHub repository
laravel new my-app --github="--public"
```

The `--organization` flag specifies a GitHub organization to create the repository under, rather than your personal account:

```
# Create the repository under a GitHub organization
laravel new my-app --github --organization=my-org
```

For the `--github` flag to work, the GitHub CLI must be installed and you must be authenticated (`gh auth login`). If the CLI is not found or authentication fails, the installer will print a warning and skip the GitHub step without failing the rest of the installation.


## Installing Laravel Boost {#installing-laravel-boost}

Laravel Boost is a package designed to improve the experience of coding with AI assistants such as Claude Code or Cursor. It adds project-specific context files that help AI tools understand the structure and conventions of a Laravel project more accurately. The installer can add it during project creation via the `--boost` flag, or explicitly skip it with `--no-boost`.

```
# Install Laravel Boost
laravel new my-app --boost

# Skip the Boost prompt without installing it
laravel new my-app --no-boost
```

When `--boost` is passed, the installer runs `composer require laravel/boost --dev`, calls `php artisan boost:install`, commits the changes to Git if a repository was initialized, and adds a `boost:update` entry to the `post-update-cmd` Composer script so Boost stays up to date automatically when you run `composer update`.

The reason `--no-boost` exists as a separate flag, rather than simply omitting `--boost`, is that the installer asks about Boost interactively when neither flag is provided. In a non-interactive environment, you need to explicitly tell the installer what to do to prevent it from hanging on the prompt. If you are running `laravel new` in a CI pipeline or a script, always include either `--boost` or `--no-boost`.


## Other Flags {#other-flags}

Two additional flags do not fit neatly into the categories above but are worth knowing.

The `--dev` flag installs the latest development release of Laravel instead of the current stable version. This pulls from the `dev-master` branch of `laravel/laravel` on Packagist. It is intended for testing against unreleased changes and is not appropriate for production projects.

```
laravel new my-app --dev
```

The `--force` flag (shorthand `-f`) allows installation into a directory that already exists. Normally the installer refuses to proceed if the target directory is present, to prevent accidentally overwriting a project. With `--force`, it deletes the existing directory first and starts fresh. There is one exception: `--force` cannot be used when the target directory is the current working directory (`.`), since deleting your current working directory would cause unpredictable behavior.

```
# Overwrite an existing directory
laravel new my-app --force

# Shorthand version
laravel new my-app -f
```


## Practical Command Examples {#practical-command-examples}

Understanding individual flags is useful, but the real value comes from combining them. Here are several ready-to-use commands for common project scenarios, each one designed to create a fully configured project with no interactive prompts.

The first example is a plain API project with no frontend scaffolding. It uses MySQL, keeps PHPUnit, initializes a Git repository, and skips Boost. This is a good starting point for a Laravel API that will be consumed by a separate frontend application.

```
laravel new my-api --database=mysql --phpunit --git --no-boost
```

The second example is a fullstack project with Vue, PostgreSQL, Pest, and Bun. It uses the default Laravel authentication and initializes a private GitHub repository. This command is typical for a production application where you want everything wired up from the start.

```
laravel new my-app --vue --database=pgsql --pest --bun --git --no-boost
```

The third example is a fast local prototype. SQLite is the right choice here because the installer creates and migrates the database automatically, so the project is ready to use the moment the command finishes. Pest and Bun keep the toolchain modern.

```
laravel new my-prototype --database=sqlite --pest --bun --no-boost
```

The fourth example targets a team environment where the project needs multi-tenancy support, a real database, and should be pushed to a GitHub organization repository immediately after creation.

```
laravel new my-app --vue --teams --database=mysql --pest --bun --github --organization=my-org --no-boost
```

The fifth example is for a Livewire project that uses WorkOS for authentication, suitable when you want enterprise SSO capabilities without building the authentication layer yourself.

```
laravel new my-app --livewire --workos --database=mysql --pest --npm --git --no-boost
```

Each of these commands will run from start to finish without pausing for any input. The only exception is the GitHub-related flags, which require the GitHub CLI to be authenticated before running.


## Conclusion {#conclusion}

The Laravel Installer's flag system is a direct map of every question the interactive prompts ask. Once you know the available options, you can move from prompt-by-prompt setup to a single declarative command that captures your full intent upfront.

Here are the key takeaways from this article:

- **Starter kit flags are `--react`, `--vue`, `--svelte`, and `--livewire`.** Omitting all of them creates a plain Laravel installation with no frontend scaffolding.
- **Authentication flags only apply when a starter kit is selected.** Use `--workos` for WorkOS authentication, `--teams` to add team support, and `--no-authentication` to remove auth scaffolding entirely.
- **`--database` accepts `mysql`, `mariadb`, `pgsql`, `sqlite`, and `sqlsrv`.** The installer adjusts the `.env` configuration automatically for each driver, and runs migrations automatically for SQLite.
- **`--pest` does a full Pest installation**, including removing PHPUnit, running the Drift migration tool, and updating CI configuration. Always include either `--pest` or `--phpunit` in non-interactive environments.
- **Package manager flags (`--npm`, `--pnpm`, `--bun`, `--yarn`) trigger both install and build immediately.** If none is passed, the installer falls back to NPM after checking for existing lock files.
- **`--github` requires the GitHub CLI to be installed and authenticated.** It handles both the local Git initialization and the remote repository creation in one step.
- **Always include either `--boost` or `--no-boost` in non-interactive environments.** Without one of these, the installer will pause on the Boost prompt.
- **`--force` overwrites an existing directory.** Use it with care, and never against the current working directory.