---
title: "How Laravel Installer 5.25.2 Protects Your Projects from npm Supply Chain Attacks"
slug: "how-laravel-installer-5252-protects-your-projects-from-npm-supply-chain-attacks"
category: "Laravel"
date: "2026-04-02"
status: "published"
---

If you read our previous breakdown of [the axios npm supply chain attack](https://qadrlabs.com/post/the-axios-npm-supply-chain-attack-how-a-hijacked-maintainer-account-delivered-a-cross-platform-rat), you already know how a single `postinstall` script in a transitive npm dependency can silently execute arbitrary code the moment `npm install` runs. What you may not know is that the Laravel ecosystem responded to that incident on the same day it happened. On March 31, 2026, [PR #489](https://github.com/laravel/installer/pull/489) was merged into the Laravel Installer, adding a single flag to every install command Laravel scaffolds: `--ignore-scripts`. This article explains what that change does, why it matters for every Laravel developer, and what you should do for projects that were scaffolded before the fix.

---

## Overview {#overview}

### What You'll Learn

- Why `--ignore-scripts` is an effective defense against `postinstall`-based supply chain attacks
- What changed in Laravel Installer 5.25.2 and how to verify you are running the patched version
- How to apply the same protection to existing projects that were created before the fix

### What You'll Need

- Laravel Installer installed globally via Composer
- PHP and Composer available in your terminal
- Basic familiarity with npm and how Laravel scaffolds frontend dependencies

---

## What Changed and Why It Matters {#what-changed-and-why-it-matters}

The core of the fix lives in a single file: `src/Enums/NodePackageManager.php`. Before the patch, the `installCommand()` method returned a bare install command for each supported package manager. After the patch, every command includes `--ignore-scripts`:

```php
// Before: any postinstall hook in any installed package would run automatically
self::NPM  => 'npm install',
self::YARN => 'yarn install',
self::PNPM => 'pnpm install',
self::BUN  => 'bun install',

// After: postinstall hooks are suppressed entirely during project scaffolding
self::NPM  => 'npm install --ignore-scripts',
self::YARN => 'yarn install --ignore-scripts',
self::PNPM => 'pnpm install --ignore-scripts',
self::BUN  => 'bun install --ignore-scripts',
```

The `--ignore-scripts` flag tells the package manager to skip all lifecycle scripts defined in any installed package, including `preinstall`, `install`, `postinstall`, and `prepare`. This means even if a compromised or malicious package is somewhere in your dependency tree, it cannot execute code on your machine during installation.

To understand why this matters, consider the axios attack. The malicious `plain-crypto-js` package did not contain any code that you would ever import or run intentionally. It existed purely to trigger a `postinstall` hook. With `--ignore-scripts` in place, that hook would never have fired. The package would have been written to `node_modules` and nothing else would have happened. No curl request, no background process, no RAT.

The same protection applies to any future attack that follows the same pattern, which is precisely why this is a structural defense rather than a reactive one.

---

## Checking Your Laravel Installer Version {#checking-your-laravel-installer-version}

Before anything else, verify which version of the Laravel Installer you are currently running.

```bash
laravel --version
```

Output:

```
$ laravel --version
Laravel Installer 5.25.1
```

If you see `5.25.1` or earlier, you are on an unpatched version. The fix is in `5.25.2`.

---

## Updating to the Patched Version {#updating-to-the-patched-version}

Update the Laravel Installer globally through Composer. Composer manages the installer as a global package, so the update command targets your global package registry rather than a specific project.

```bash
composer global update laravel/installer
```

This pulls the latest release from Packagist and replaces your existing installation. Composer will resolve any dependency changes and update the autoloader automatically.

---

## Verifying the Update {#verifying-the-update}

Once the update completes, confirm you are now on the patched version.

```bash
laravel --version
```

Output:

```
laravel --version
Laravel Installer 5.25.2
```

Version `5.25.2` confirms the fix is in place. Any new project you create from this point forward will install frontend dependencies with `--ignore-scripts` applied automatically.

---

## Creating a New Project to Confirm the Behavior {#creating-a-new-project-to-confirm-the-behavior}

You can verify the change is active by creating a test project and observing the install prompt. Run `laravel new` as you normally would:

```bash
laravel new test-project
```

The installer will walk you through the usual scaffolding questions. Once you reach the frontend dependency step, notice how the prompt now reads differently from what you may have seen before:

```
 ┌ Would you like to run npm install --ignore-scripts and npm run build? ┐
 │ ● Yes / ○ No                                                          │
 └───────────────────────────────────────────────────────────────────────┘
```

The phrase `npm install --ignore-scripts` in the prompt confirms the patched behavior is active. In previous versions, this prompt simply read `npm install`. The flag is now explicit and visible, which also serves as a teaching moment for developers who may not have been aware of it before.

Here is the full scaffolding output for reference, showing the complete flow from project creation through the dependency install step:

```
laravel new test-project

 ██╗       █████╗  ██████╗   █████╗  ██╗   ██╗ ███████╗ ██╗
 ██║      ██╔══██╗ ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ██║
 ██║      ███████║ ██████╔╝ ███████║ ██║   ██║ █████╗   ██║
 ██║      ██╔══██║ ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║
 ███████╗ ██║  ██║ ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ███████╗
 ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝

 ┌ Which starter kit would you like to install? ────────────────┐
 │ Livewire                                                     │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which authentication provider do you prefer? ────────────────┐
 │ Laravel's built-in authentication                            │
 └──────────────────────────────────────────────────────────────┘

 ┌ Would you like to use single-file Livewire components? ──────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

 ┌ Would you like to add teams support to your application? ────┐
 │ No                                                           │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ Pest                                                         │
 └──────────────────────────────────────────────────────────────┘

 ┌ Do you want to install Laravel Boost to improve AI assisted coding? ┐
 │ Yes                                                                 │
 └─────────────────────────────────────────────────────────────────────┘

 ┌ Would you like to run npm install --ignore-scripts and npm run build? ┐
 │ ● Yes / ○ No                                                          │
 └───────────────────────────────────────────────────────────────────────┘
```

---

## Applying the Fix to Existing Projects {#applying-the-fix-to-existing-projects}

The update to the Laravel Installer only affects projects created after `5.25.2`. For existing projects, the `package.json` and any CI/CD pipeline scripts that run `npm install` are not automatically updated. You need to apply the flag manually.

For local development, whenever you install or reinstall frontend dependencies in an existing project, add the flag explicitly:

```bash
npm install --ignore-scripts
```

For CI/CD pipelines, update any step that runs `npm install` or `npm ci` to include the flag. The `npm ci` command, which is the recommended approach for automated environments because it installs from a lockfile and ensures reproducibility, also supports the flag:

```bash
npm ci --ignore-scripts
```

Using `npm ci --ignore-scripts` in CI/CD is the stronger choice because it combines two independent protections: `ci` ensures you install exactly what is in your lockfile rather than resolving to a newer version, and `--ignore-scripts` ensures that nothing in what you install can run arbitrary code during the process.

One thing to keep in mind: `--ignore-scripts` suppresses all lifecycle scripts, including legitimate ones. Most frontend packages used in Laravel projects (Vite, Tailwind, Alpine.js) do not rely on `postinstall` hooks and will work correctly with the flag. If a specific package does require a lifecycle script to function (for example, some packages that compile native binaries), you will need to run that script manually after install. This is a deliberate tradeoff: you give up a small amount of automation in exchange for a meaningful reduction in attack surface.

---

## Conclusion {#conclusion}

The four-line change in Laravel Installer 5.25.2 is a small diff with a large implication. It reflects a broader lesson that the axios incident put into sharp focus: the npm install process, by default, is a code execution surface. Any package in your dependency tree can run arbitrary code on your machine the moment you install it, unless you explicitly opt out.

Key takeaways from this article:

- **Update your Laravel Installer immediately.** Run `composer global update laravel/installer` and verify you are on `5.25.2` or later. New projects you create from this point will have `--ignore-scripts` applied automatically.
- **`--ignore-scripts` is a structural defense, not a workaround.** It does not depend on knowing which packages are malicious in advance. It blocks the entire attack vector that `postinstall`-based supply chain attacks rely on.
- **Existing projects are not automatically protected.** Any project created before `5.25.2` still runs bare `npm install` unless you update your development workflow and CI/CD pipeline manually.
- **`npm ci --ignore-scripts` is the right pattern for CI/CD.** The combination of lockfile enforcement and script suppression gives you both reproducibility and protection in automated build environments.
- **The tradeoff is minimal for most Laravel projects.** The vast majority of frontend packages Laravel uses do not require `postinstall` hooks. The flag will not break your build in typical setups.

The axios attack was resolved in roughly three hours. The next one targeting a package with 100 million weekly downloads may not be caught as quickly. Applying `--ignore-scripts` now means that even if a malicious package ends up in your dependency tree, it cannot execute code during install, regardless of when the community discovers it.

---

*References: [laravel/installer PR #489](https://github.com/laravel/installer/pull/489) by crynobone, merged March 31, 2026. For background on the axios incident that prompted this fix, see [The axios npm Supply Chain Attack](https://qadrlabs.com/post/the-axios-npm-supply-chain-attack-how-a-hijacked-maintainer-account-delivered-a-cross-platform-rat).*