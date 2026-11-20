# How to Install PHP 8.6 on Ubuntu 26.04 from packages.sury.org

PHP 8.6.0 was released on November 19, 2026[^1], and Ubuntu 26.04 does not ship it in its own archive. A machine set up with the Sury repository in the [previous tutorial](https://qadrlabs.com/post/how-to-install-php-85-and-php-fpm-from-packagessuryorg-on-ubuntu-2604-for-laravel-and-nginx) already has everything needed to get it: the same repository that provided PHP 8.5 now carries PHP 8.6 packages for `resolute`. The upgrade does not have to replace anything either, because Sury packages are versioned by name (`php8.5-*`, `php8.6-*`), so the new version installs next to the old one. This short tutorial installs PHP 8.6 with PHP-FPM and the common Laravel extensions, and then checks the result. For a tour of what the new version brings, see [PHP 8.6 Released: What's New and Changed](https://qadrlabs.com/post/php-86-whats-new-and-changed).

## Overview {#overview}

This tutorial is a record of a real installation on an Ubuntu 26.04 laptop that already ran PHP 8.5.12 from the Sury repository. Every output below was copied from that terminal session. The Ondrej PPA for Ubuntu has moved to `packages.sury.org/php`[^2], so "Ondrej PHP" and "Sury" refer to the same maintainer and the same packages here.

### What You'll Build

- PHP 8.6 CLI and PHP-FPM installed from `packages.sury.org`.
- The extensions a typical Laravel project needs: mbstring, xml, curl, zip, bcmath, intl, gd, mysql, and sqlite3.
- PHP 8.6 running side by side with the existing PHP 8.5 installation.

### What You'll Learn

- How to check which PHP version the system currently uses.
- How to install a new PHP minor version and its extensions with one `apt` command.
- How to read the `apt` summary to confirm the packages come from the Sury repository.
- Why the `php` command switches to the newest version after the installation.

### What You'll Need

- Ubuntu 26.04 (`resolute`) with a user that has `sudo` access.
- The `packages.sury.org/php` repository already added. If it is not, follow Step 5 and Step 6 of [How to Install PHP 8.5 and PHP-FPM from packages.sury.org on Ubuntu 26.04](https://qadrlabs.com/post/how-to-install-php-85-and-php-fpm-from-packagessuryorg-on-ubuntu-2604-for-laravel-and-nginx) first. The official setup script is in the repository README[^3].
- Basic comfort with the terminal.

## Step 1: Check the Current PHP Version {#step-1-check-the-current-php-version}

Before installing anything, check which PHP version the `php` command runs right now. This gives a baseline to compare against after the installation.

```bash
php -v
```

Output:

```
$ php -v
PHP 8.5.12 (cli) (built: Oct 21 2026 08:07:33) (NTS)
Copyright (c) The PHP Group
Built by Ubuntu
Zend Engine v4.5.12, Copyright (c) Zend Technologies
    with Zend OPcache v8.5.12, Copyright (c), by Zend Technologies

```

The machine runs PHP 8.5.12 with OPcache. This is the version installed in the previous tutorial, and it stays installed after this tutorial.

## Step 2: Install PHP 8.6 and Its Extensions {#step-2-install-php-86-and-its-extensions}

Now install PHP 8.6. Every package name starts with `php8.6-`, so apt treats it as a separate set of packages and does not touch PHP 8.5.

```bash
sudo apt install php8.6-cli php8.6-fpm php8.6-common php8.6-mbstring php8.6-xml php8.6-curl php8.6-zip php8.6-bcmath php8.6-intl php8.6-gd php8.6-mysql php8.6-sqlite3
```

Here is what each package provides:

- `php8.6-cli` is the command-line interpreter used by `php`, Composer, and `artisan`.
- `php8.6-fpm` is the FastCGI Process Manager that a web server such as nginx sends PHP requests to.
- `php8.6-common` holds the shared files and the core extensions every PHP 8.6 package depends on.
- `php8.6-mbstring`, `php8.6-xml`, `php8.6-curl`, `php8.6-zip`, `php8.6-bcmath`, and `php8.6-intl` are extensions Laravel and Composer use for strings, XML, HTTP requests, archives, precise math, and internationalization.
- `php8.6-gd` handles image processing.
- `php8.6-mysql` and `php8.6-sqlite3` are the database drivers for MySQL/MariaDB and SQLite.

apt asks for the sudo password and then shows a summary before it changes anything. Output:

```
$ sudo apt install php8.6-cli php8.6-fpm php8.6-common php8.6-mbstring php8.6-xml php8.6-curl php8.6-zip php8.6-bcmath php8.6-intl php8.6-gd php8.6-mysql php8.6-sqlite3
[sudo: authenticate] Password:                
Installing:                     
  php8.6-bcmath  php8.6-cli  php8.6-common  php8.6-curl  php8.6-fpm  php8.6-gd  php8.6-intl  php8.6-mbstring  php8.6-mysql  php8.6-sqlite3  php8.6-xml  php8.6-zip

Installing dependencies:
  php8.6-readline

Suggested packages:
  php-pear

Summary:
  Upgrading: 0, Installing: 13, Removing: 0, Not Upgrading: 88
  Download size: 8,966 kB
  Space needed: 41.5 MB / 61.7 GB available

Continue? [Y/n] 
```

Read the summary before confirming. apt installs the 12 requested packages plus `php8.6-readline` as a dependency, 13 in total. The important line is `Removing: 0`: nothing from PHP 8.5 or any other package will be removed. `php-pear` is only a suggestion and is not installed.

Type `Y` and press Enter to continue. Output:

```
 sudo apt install php8.6-cli php8.6-fpm php8.6-common php8.6-mbstring php8.6-xml php8.6-curl php8.6-zip php8.6-bcmath php8.6-intl php8.6-gd php8.6-mysql php8.6-sqlite3
[sudo: authenticate] Password:                
Installing:                     
  php8.6-bcmath  php8.6-cli  php8.6-common  php8.6-curl  php8.6-fpm  php8.6-gd  php8.6-intl  php8.6-mbstring  php8.6-mysql  php8.6-sqlite3  php8.6-xml  php8.6-zip

Installing dependencies:
  php8.6-readline

Suggested packages:
  php-pear

Summary:
  Upgrading: 0, Installing: 13, Removing: 0, Not Upgrading: 88
  Download size: 8,966 kB
  Space needed: 41.5 MB / 61.7 GB available

Continue? [Y/n] y
Get:1 https://packages.sury.org/php resolute/main amd64 php8.6-common amd64 8.6.0-2+0~deb.sury.org.1+ubuntu26.04 [862 kB]
.
.
.
.
Processing triggers for php8.6-cli (8.6.0-2+0~deb.sury.org.1+ubuntu26.04)…
Processing triggers for php8.6-fpm (8.6.0-2+0~deb.sury.org.1+ubuntu26.04)…

```

The `Get:1` line confirms the source: the package is downloaded from `https://packages.sury.org/php` for the `resolute` suite, which is Ubuntu 26.04. The version string `8.6.0-2+0~deb.sury.org.1+ubuntu26.04` shows PHP 8.6.0, built by Sury for Ubuntu 26.04. The final `Processing triggers` lines mean the CLI and FPM packages finished their setup without errors.

## Step 3: Verify the Installation {#step-3-verify-the-installation}

Run the same version check as in Step 1.

```bash
php -v
```

Output:

```
$ php -v
PHP 8.6.0 (cli) (built: Nov 18 2026 12:39:07) (NTS)
Copyright © The PHP Group and Contributors
Built by Ubuntu
Zend Engine v4.6.0, Copyright © Zend by Perforce
    with Zend OPcache v8.6.0, Copyright ©, by Zend by Perforce
```

The `php` command now runs PHP 8.6.0 with Zend Engine 4.6.0 and OPcache 8.6.0. It switched on its own because `/usr/bin/php` is managed by the Debian alternatives system, where each installed version registers itself with a priority based on its version number. A newer version gets a higher priority, so PHP 8.6 becomes the default for the `php` command. PHP 8.5 is still installed next to it, and both binaries remain available by their full names, `php8.5` and `php8.6`.

## Conclusion {#conclusion}

Installing PHP 8.6 on Ubuntu 26.04 takes a single command once the Sury repository is in place, and it leaves the existing PHP 8.5 setup untouched.

- **Same repository, new version.** The `packages.sury.org/php` repository from the PHP 8.5 tutorial already provides PHP 8.6 for Ubuntu 26.04 `resolute`, so no new source is needed.
- **Versioned package names.** Packages named `php8.6-*` install alongside `php8.5-*`, and the `Removing: 0` line in the summary confirms nothing is replaced.
- **Read the apt output.** The `Get:` lines show where packages come from, and the version string `deb.sury.org` plus `ubuntu26.04` confirms the right build.
- **The default `php` switches.** The alternatives system points `php` to the newest installed version, while `php8.5` and `php8.6` stay available by name.
- **Next step.** Explore the new language features in [PHP 8.6 Released: What's New and Changed](https://qadrlabs.com/post/php-86-whats-new-and-changed).

## References {#references}

[^1]: PHP 8.6 Release Announcement @ [https://www.php.net/releases/8.6/en.php](https://www.php.net/releases/8.6/en.php)
[^2]: Ondřej Surý PHP PPA @ [https://launchpad.net/~ondrej/+archive/ubuntu/php](https://launchpad.net/~ondrej/+archive/ubuntu/php)
[^3]: packages.sury.org PHP Repository README @ [https://packages.sury.org/php/README.txt](https://packages.sury.org/php/README.txt)
