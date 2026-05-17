---
title: "How to Install Composer Globally on macOS"
slug: "how-to-install-composer-globally-on-macos"
category: "How To Install"
date: "2026-04-17"
status: "published"
---

In a previous guide, we covered [how to install and use Composer on Ubuntu](https://qadrlabs.com/post/cara-installasi-dan-penggunaan-composer-pada-ubuntu-16-04). This time, we are doing the same thing on macOS. The steps are slightly different: macOS does not have a system package manager like apt out of the box, and the default shell is Zsh instead of Bash. This guide walks you through the complete process, from downloading Composer to making it globally accessible from any directory in your terminal.

## Overview {#overview}

### What You'll Learn

- How to download the official Composer installer and verify its integrity
- How to install Composer and make it globally accessible from any directory
- How to set up the Composer vendor bin directory in your PATH
- How to keep Composer updated

### What You'll Need

- macOS (Apple Silicon or Intel)
- PHP already installed (PHP 7.2.5 or higher required; PHP 8.x recommended)
- Terminal access with `sudo` privileges



## Step 1: Check Your PHP Version {#check-php}

Composer is a PHP tool, so PHP must be installed and accessible from your terminal before you proceed. Run this command to confirm:

```bash
php -v
```

You should see output similar to this:

```
PHP 8.4.15 (cli) (built: Nov 18 2025 17:26:05) (NTS)
Copyright (c) The PHP Group
Built by Homebrew
Zend Engine v4.4.15, Copyright (c) Zend Technologies
    with Xdebug v3.4.6, Copyright (c) 2002-2025, by Derick Rethans
    with Zend OPcache v8.4.15, Copyright (c), by Zend Technologies
```

If the command returns `command not found`, install PHP first via Homebrew with `brew install php` before continuing.



## Step 2: Download and Run the Composer Installer {#download-composer}

The official way to install Composer is through its PHP-based installer script. The process involves four commands that you run in sequence. Rather than copying them blindly, here is what each one does.

**Command 1: Download the installer**

```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
```

This uses PHP's built-in `copy()` function to download the Composer installer script from the official server and save it locally as `composer-setup.php`.

**Command 2: Verify the installer's integrity**

```bash
php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
```

This verifies the downloaded file by comparing its SHA-384 hash against the expected value published by the Composer team. If the hashes do not match, the script deletes the file and exits, protecting you from running a corrupted or tampered installer.

> **Note:** The hash above changes with each new Composer release. Always get the latest hash from [getcomposer.org/download](https://getcomposer.org/download/) before running this command.

**Command 3: Run the installer**

```bash
php composer-setup.php
```

This executes the installer, which checks your PHP configuration, downloads the latest stable `composer.phar`, and saves it to your current directory.

**Command 4: Remove the installer script**

```bash
php -r "unlink('composer-setup.php');"
```

This cleans up the temporary installer file since it is no longer needed after the installation completes.

After running all four commands, you should see:

```
Installer verified
All settings correct for using Composer
Downloading...

Composer (version 2.9.7) successfully installed to: /Users/your-username/composer.phar
Use it: php composer.phar
```

At this point, `composer.phar` is installed locally in your home directory. The next steps make it globally accessible.



## Step 3: Move Composer to a Global Location {#move-composer}

The `/usr/local/bin` directory is part of macOS's default `$PATH`, which means any executable placed there can be called by name from any directory in your terminal. Move `composer.phar` there and rename it to `composer`:

```bash
sudo mv ~/composer.phar /usr/local/bin/composer
```

Breaking this down:

- `sudo` runs the command with superuser privileges because `/usr/local/bin` requires elevated permissions to modify.
- `mv` moves and renames the file in a single operation.
- `~/composer.phar` is the source file in your home directory.
- `/usr/local/bin/composer` is the destination, with the filename simplified to `composer` (no `.phar` extension required).

Enter your macOS password when prompted, then press Enter.



## Step 4: Set Executable Permissions {#set-permissions}

After moving the file, ensure it has the correct executable permissions. Without this, macOS may refuse to run it as a program.

```bash
sudo chmod +x /usr/local/bin/composer
```

- `chmod +x` adds the execute permission to the file.
- This tells macOS to treat `composer` as a runnable executable rather than a plain data file.



## Step 5: Add the Composer Vendor Bin to Your PATH {#vendor-bin-path}

When you install packages globally with `composer global require` (such as the Laravel installer), the resulting executables are placed in `~/.composer/vendor/bin`. This directory is not in your PATH by default, so those commands would not be recognized without this step.

First, confirm the exact path on your machine:

```bash
composer global config bin-dir --absolute
```

The output will be something like:

```
~/.composer/vendor/bin
```

Next, add it to your shell configuration. macOS uses Zsh by default since Catalina, so open `~/.zshrc`:

```bash
echo 'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> ~/.zshrc
```

If you use Bash instead, use `~/.bash_profile`:

```bash
echo 'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> ~/.bash_profile
```

- `echo '...' >> ~/.zshrc` appends the line to the file without overwriting the rest of your configuration.
- `$HOME/.composer/vendor/bin` resolves to the full absolute path of your Composer global bin directory.

Finally, reload your shell configuration to apply the changes in your current session:

```bash
source ~/.zshrc
```

Or for Bash:

```bash
source ~/.bash_profile
```



## Try It Out {#try-it-out}

Open a new Terminal window, navigate to any directory, and run:

```bash
composer --version
```

Expected output:

```
Composer version 2.9.7 2025-xx-xx xx:xx:xx
PHP version 8.4.15 (/opt/homebrew/Cellar/php@8.4/8.4.15/bin/php)
Run the "diagnose" command to get more detailed diagnostics output.
```

Run `composer` with no arguments to confirm the full command list loads:

```bash
composer
```

```
   ______
  / ____/___  ____ ___  ____  ____  ________  _____
 / /   / __ \/ __ `__ \/ __ \/ __ \/ ___/ _ \/ ___/
/ /___/ /_/ / / / / / / /_/ / /_/ (__  )  __/ /
\____/\____/_/ /_/ /_/ .___/\____/____/\___/_/
                    /_/
Composer version 2.8.12 2025-09-19 13:41:59

Usage:
  command [options] [arguments]

Options:
  -h, --help                     Display help for the given command. When no command is given display help for the list command
  -q, --quiet                    Do not output any message
  -V, --version                  Display this application version
      --ansi|--no-ansi           Force (or disable --no-ansi) ANSI output
  -n, --no-interaction           Do not ask any interactive question
      --profile                  Display timing and memory usage information
      --no-plugins               Whether to disable plugins.
      --no-scripts               Skips the execution of all scripts defined in composer.json file.
  -d, --working-dir=WORKING-DIR  If specified, use the given directory as working directory.
      --no-cache                 Prevent use of the cache
  -v|vv|vvv, --verbose           Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug

Available commands:
  about                Shows a short information about Composer
  archive              Creates an archive of this composer package
  audit                Checks for security vulnerability advisories for installed packages
  browse               [home] Opens the package's repository URL or homepage in your browser
  bump                 Increases the lower limit of your composer.json requirements to the currently installed versions
  check-platform-reqs  Check that platform requirements are satisfied
  clear-cache          [clearcache|cc] Clears composer's internal package cache
  completion           Dump the shell completion script
  config               Sets config options
  create-project       Creates new project from a package into given directory
  depends              [why] Shows which packages cause the given package to be installed
  diagnose             Diagnoses the system to identify common errors
  dump-autoload        [dumpautoload] Dumps the autoloader
  exec                 Executes a vendored binary/script
  fund                 Discover how to help fund the maintenance of your dependencies
  global               Allows running commands in the global composer dir ($COMPOSER_HOME)
  help                 Display help for a command
  init                 Creates a basic composer.json file in current directory
  install              [i] Installs the project dependencies from the composer.lock file if present, or falls back on the composer.json
  licenses             Shows information about licenses of dependencies
  list                 List commands
  outdated             Shows a list of installed packages that have updates available, including their latest version
  prohibits            [why-not] Shows which packages prevent the given package from being installed
  reinstall            Uninstalls and reinstalls the given package names
  remove               [rm|uninstall] Removes a package from the require or require-dev
  require              [r] Adds required packages to your composer.json and installs them
  run-script           [run] Runs the scripts defined in composer.json
  search               Searches for packages
  self-update          [selfupdate] Updates composer.phar to the latest version
  show                 [info] Shows information about packages
  status               Shows a list of locally modified packages
  suggests             Shows package suggestions
  update               [u|upgrade] Updates your dependencies to the latest version according to composer.json, and updates the composer.lock file
  validate             Validates a composer.json and composer.lock
```

Composer is fully accessible globally.



## How Composer Global Installation Works {#how-it-works}

Understanding the mechanics helps you troubleshoot if something breaks.

**The `$PATH` variable** is an ordered list of directories your shell searches whenever you type a command. When you run `composer`, macOS scans each directory in `$PATH` from left to right until it finds a matching executable. Because `/usr/local/bin` is included in the default PATH on macOS, placing the `composer` binary there makes it discoverable from any working directory.

**The `.phar` format** stands for PHP Archive. It is a self-contained PHP application bundled into a single file, similar to a Java `.jar`. When you rename `composer.phar` to `composer` and set it as executable, the shell can run it directly without the `php` prefix.

**The `~/.composer/vendor/bin` directory** is a separate location where globally required Composer packages store their CLI executables. It is distinct from `/usr/local/bin`, which is why you need to add it to `$PATH` explicitly. Without this, commands like `laravel new project` would not be recognized after running `composer global require laravel/installer`.



## How to Update Composer {#update-composer}

Composer can update itself without a full reinstall. Run:

```bash
composer self-update
```

This fetches the latest stable release and replaces the binary at `/usr/local/bin/composer` automatically. If an update causes issues with an existing project, you can roll back to the previous version:

```bash
composer self-update --rollback
```

To update to a specific version:

```bash
composer self-update 2.9.7
```



## Conclusion {#conclusion}

Here are the key takeaways from this tutorial:

- Always verify the SHA-384 hash when downloading the Composer installer to ensure the file has not been tampered with.
- Moving `composer.phar` to `/usr/local/bin/composer` makes it a globally available command because that directory is in macOS's default `$PATH`.
- `sudo chmod +x` grants executable permission so macOS treats the file as a runnable program.
- Adding `~/.composer/vendor/bin` to your `$PATH` is a separate but necessary step to use globally installed tools like the Laravel installer.
- `composer self-update` keeps Composer current without needing to repeat the installation process.