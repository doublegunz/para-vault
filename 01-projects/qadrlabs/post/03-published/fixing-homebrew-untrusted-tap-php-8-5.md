# Fixing "Refusing to load formula from untrusted tap" Error When Installing PHP 8.5 via Homebrew

If you tried installing PHP 8.5 from the `shivammathur/php` tap recently and got blocked by Homebrew, you are not alone. A lot of developers hit this wall the moment they upgrade to Homebrew 6.0 and try to run `brew install shivammathur/php/php@8.5` or `brew services start shivammathur/php/php@8.5` on a machine that used to work fine with the same tap.

The error message looks harmless at first glance, but it can loop back at you even after you follow its own instructions. You run the suggested `brew trust` command, retry the install, and the exact same error shows up again. This is confusing, especially if you are in the middle of setting up a new project and just need PHP running so you can get back to work. The good news is that once you understand how Homebrew's new trust model works, the fix takes less than a minute.

## Overview {#overview}

This article walks through the full troubleshooting process for the untrusted tap error, starting from the first failed command up to a verified, running PHP 8.5 service. The case here is based on a real terminal session on a Linux machine using Linuxbrew, but the same steps apply on macOS.

### What You'll Build

- A working PHP 8.5 installation from the `shivammathur/php` tap, running as a Homebrew service.
- A trust configuration that allows Homebrew to load both the versioned formula (`php@8.5`) and its base formula (`php`) without errors.

### What You'll Learn

- Why Homebrew 6.0 introduced the Tap Trust security feature and what problem it solves.
- The difference between trusting a specific formula and trusting an entire tap.
- Why trusting only the versioned formula (`php@8.5`) is not always enough, and when you also need to trust the base formula.
- How to verify that PHP is installed correctly and running as a service.
- How to manage multiple PHP versions side by side using Homebrew services.

### What You'll Need

- Homebrew 6.0 or later, on macOS or Linux (Linuxbrew).
- Terminal access with permission to run `brew` commands.
- Basic familiarity with Homebrew taps and services.

## Step 1: Reproduce the Error {#step-1-reproduce-the-error}

The problem usually starts when you try to install or start a PHP version from a third party tap. Here is the exact error from the terminal session that triggered this troubleshooting session.

```
gun-gun-priatna@qadrlabs:~/Projects/app-qadrlabs$ brew services start shivammathur/php/php@8.5
Error: Refusing to load formula shivammathur/php/php from untrusted tap shivammathur/php.
Run `brew trust --formula shivammathur/php/php` or `brew trust shivammathur/php` to trust it.
gun-gun-priatna@qadrlabs:~/Projects/app-qadrlabs$ brew install shivammathur/php/php@8.5
Error: Refusing to load formula shivammathur/php/php from untrusted tap shivammathur/php.
Run `brew trust --formula shivammathur/php/php` or `brew trust shivammathur/php` to trust it.
```

Notice that both commands fail with the same message, even though one is trying to install and the other is trying to start a service. This tells you the block is happening at a lower level, before Homebrew even gets to the install or service logic. The root cause is Homebrew 6.0's Tap Trust feature, which refuses to evaluate or execute any formula code coming from a third party tap until that tap or formula has been explicitly marked as trusted. Since `shivammathur/php` is not an official Homebrew tap, it falls under this restriction by default.

## Step 2: Trust the Specific Formula {#step-2-trust-the-specific-formula}

The safest way to unblock a formula is to trust it individually instead of trusting the whole tap. This limits the exposure to just the formula you actually intend to use.

```bash
brew trust --formula shivammathur/php/php@8.5
```

This command tells Homebrew that you have reviewed and accept running the code for the `php@8.5` formula specifically from the `shivammathur/php` tap. It does not automatically extend trust to any other formula in that tap, which is intentional since third party taps can contain arbitrary Ruby code that runs on your machine during install.

Running this command produces a straightforward confirmation.

```
gun-gun-priatna@qadrlabs:~$ brew trust --formula shivammathur/php/php@8.5
Trusted formula: shivammathur/php/php@8.5
```

At this point it looks like the problem is solved, since Homebrew confirms the formula is now trusted.

## Step 3: Trust the Base Formula (Edge Case) {#step-3-trust-the-base-formula}

Retrying the install after trusting `php@8.5` still fails, which is the part that trips most people up.

```
gun-gun-priatna@qadrlabs:~$ brew install shivammathur/php/php@8.5
brew services start shivammathur/php/php@8.5
==> Auto-updating Homebrew...
Adjust how often this is run with `$HOMEBREW_AUTO_UPDATE_SECS` or disable with
`$HOMEBREW_NO_AUTO_UPDATE=1`. Hide these hints with `$HOMEBREW_NO_ENV_HINTS=1` (see `man brew`).
Error: Refusing to load formula shivammathur/php/php from untrusted tap shivammathur/php.
Run `brew trust --formula shivammathur/php/php` or `brew trust shivammathur/php` to trust it.
Error: Refusing to load formula shivammathur/php/php from untrusted tap shivammathur/php.
Run `brew trust --formula shivammathur/php/php` or `brew trust shivammathur/php` to trust it.
```

The reason this still fails is that versioned PHP formulae in this tap, such as `php@8.5`, reference or extend the base formula `php` internally. When Homebrew resolves the install or service graph, it needs to load that base formula too, and since it was never explicitly trusted, the trust check blocks it again. Trusting `php@8.5` alone was not enough because the dependency chain pulls in a formula that is still marked untrusted.

The fix is to trust the base formula as well.

```bash
brew trust --formula shivammathur/php/php
```

If you expect to work with several versions from this tap over time, for example `php@8.3`, `php@8.4`, and `php@8.5`, it is often simpler to trust the entire tap once instead of trusting each formula individually.

```bash
brew trust shivammathur/php
```

This grants trust to every formula, cask, and command currently in the tap, plus anything added to it in the future. It is a broader grant of trust, so only use it for taps you are confident about maintaining a working relationship with, such as a well known tap like `shivammathur/php` that many Laravel and PHP developers already rely on.

## Step 4: Install and Verify {#step-4-install-and-verify}

With both the versioned formula and the base formula trusted, the install and service start commands go through without any trust related errors.

```bash
brew install shivammathur/php/php@8.5
brew services start shivammathur/php/php@8.5
```

Once the install finishes, verify the PHP version to confirm it is the correct build from the `shivammathur/php` tap.

```
gun-gun-priatna@qadrlabs:~$ php -v
PHP 8.5.9 (cli) (built: Jul 28 2026 13:06:52) (NTS)
Copyright (c) The PHP Group
Built by Shivam Mathur
Zend Engine v4.5.9, Copyright (c) Zend Technologies
    with Zend OPcache v8.5.9, Copyright (c), by Zend Technologies
```

The output confirms PHP 8.5.9 is active, built by Shivam Mathur, which matches the tap you installed from. Next, check the binary path to confirm it points to the Homebrew installation rather than a system package.

```
gun-gun-priatna@qadrlabs:~$ which php
/home/linuxbrew/.linuxbrew/bin/php
```

Finally, list the Homebrew services to confirm PHP 8.5 is registered and running.

```
gun-gun-priatna@qadrlabs:~$ brew services list | grep php
php     started         gun-gun-priatna ~/.config/systemd/user/homebrew.php.service
php@7.4 started         gun-gun-priatna [~/.config/systemd/user/homebrew.php@7.4.service](mailto:~/.config/systemd/user/homebrew.php@7.4.service)
php@8.2 none                            
php@8.3 none                            
php@8.4 started         gun-gun-priatna [~/.config/systemd/user/homebrew.php@8.4.service](mailto:~/.config/systemd/user/homebrew.php@8.4.service)
```

The `php` entry, which points to the 8.5 build in this case, shows `started`, confirming the service is active. Note that this machine also has `php@7.4` and `php@8.4` running simultaneously, along with `php@8.2` and `php@8.3` installed but not started. This is a common setup for developers who juggle multiple projects on different PHP versions.

## Understanding Homebrew Tap Trust {#understanding-homebrew-tap-trust}

Tap Trust is a security feature introduced in Homebrew 6.0 specifically to address the risk of running arbitrary Ruby code from third party taps. Unlike official Homebrew taps such as `homebrew/core` and `homebrew/cask`, which are trusted by default, any tap you add yourself, like `shivammathur/php`, is treated as untrusted until you say otherwise. Since formula files are Ruby scripts that Homebrew executes during install, an untrusted tap could theoretically run malicious code on your machine without this safeguard.

There are two levels of trust you can grant.

- **Formula level trust**, granted with `brew trust --formula <tap>/<formula>`, only allows that one specific formula to be loaded. This is the more restrictive and generally safer option, especially for taps you use for a single tool.
- **Tap level trust**, granted with `brew trust <tap>`, allows every formula, cask, and command in that tap, both current and future, to be loaded without further prompts. This is more convenient for taps you rely on heavily, like `shivammathur/php` if you regularly switch between PHP versions.

To check whether a tap is currently trusted, you can inspect its info.

```bash
brew tap-info shivammathur/php
```

This will show you the trust status along with other tap metadata, which is useful when debugging why a formula suddenly fails to load after a Homebrew update.

If you ever want to revoke trust, for example after removing a tap you no longer use, the commands mirror the trust commands.

```bash
brew untrust --formula shivammathur/php/php@8.5
brew untrust shivammathur/php
```

One detail worth remembering from the case above: trusting a versioned formula does not automatically trust the base formula it depends on. If a tap structures its formulae so that versioned packages extend a shared base formula, you may need to trust both explicitly, or just trust the whole tap to avoid repeating this step every time a new version is released.

## Managing Multiple PHP Versions with Homebrew {#managing-multiple-php-versions}

Once you have PHP 8.5 running, it is common to end up with several PHP versions installed side by side, especially if you support multiple projects with different requirements. The `brew services list` output from Step 4 already shows this pattern, with `php@7.4`, `php`, and `php@8.4` all running at the same time.

Running multiple PHP versions concurrently is fine on the CLI since each version binds to its own service and socket, but only one version can be the default `php` binary linked in your PATH at a time. To switch which version is active on the command line, use `unlink` and `link`.

```bash
brew unlink shivammathur/php/php@8.4
brew link shivammathur/php/php@8.5
```

This changes which binary `which php` resolves to, without stopping any running services. If you no longer need an older version running in the background, stop its service to free up resources.

```bash
brew services stop shivammathur/php/php@7.4
```

For Laravel projects specifically, after switching versions it is worth confirming that the extensions your project depends on are present in the new version, since Laravel commonly requires `mbstring`, `openssl`, `pdo`, `intl`, and `gd` at minimum.

```bash
php -m | grep -iE "mbstring|openssl|pdo|intl|gd"
```

If any extension is missing, the `shivammathur/php` tap ships them as separate formulae named after the PHP version.

```bash
brew install shivammathur/php/php@8.5-intl
brew install shivammathur/php/php@8.5-gd
```

## Conclusion {#conclusion}

The untrusted tap error looks intimidating the first time you see it, but it comes down to a single new safeguard in Homebrew 6.0 that requires explicit approval before running code from third party taps.

- **Tap Trust is opt in security.** Homebrew 6.0 blocks formula code from any tap you have not explicitly trusted, protecting you from potentially malicious Ruby scripts in third party taps.
- **Formula trust and tap trust are different scopes.** `brew trust --formula` grants access to one formula only, while `brew trust <tap>` grants access to everything in that tap, current and future.
- **Versioned formulae can depend on base formulae.** Trusting `php@8.5` alone was not enough in this case because it depends on the base `php` formula, which also needed to be trusted separately.
- **Verification matters after any trust or install fix.** Commands like `php -v`, `which php`, and `brew services list` confirm the correct version is active and running before you move on.
- **Multiple PHP versions can coexist.** Homebrew services let you run several PHP versions at once, switching the active CLI binary with `link` and `unlink` as needed per project.
