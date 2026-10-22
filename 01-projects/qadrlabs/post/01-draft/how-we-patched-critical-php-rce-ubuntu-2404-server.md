# How We Patched Critical PHP RCE Vulnerabilities on an Ubuntu 24.04 Server

A critical security release does not protect a production server until the patched runtime is actually installed and serving requests. PHP released fixes for two remote code execution vulnerabilities on October 21, 2026, and we needed to update the PHP packages on an Ubuntu 24.04 server. The immediate package upgrade was simple. The additional work came afterward, when we discovered that our PHP installations still used builds associated with the older Launchpad repository even though a new Sury repository was available.

Our [earlier article about CVE-2026-109618 and CVE-2026-109619](https://qadrlabs.com/post/php-critical-rce-vulnerabilities-cve-2026-109618-and-cve-2026-109619-what-happened-and-how-to-protect-your-servers) explains the vulnerabilities and their potential impact. This article follows what happened when we applied the security updates to our server, why we also migrated our PHP package builds, and how we checked the environment afterward.

This is a **production maintenance case study**, not a sequence of mandatory steps for every Ubuntu installation. Commands are included to show the important decisions and checks. Some operational precautions are noted separately, rather than presented as actions we can verify from our session.

## Overview {#overview}

Our server ran Ubuntu 24.04 with Nginx, PHP-FPM, and PHP 8.4 and 8.5 packages managed through APT. The primary objective was to install PHP versions containing the security fixes and confirm that the web runtime could still serve the application. We later decided to align the installed PHP package builds with `packages.sury.org`, which was a separate maintenance task.

### The security releases

According to [PHP's official announcement](https://www.php.net/), the October 21, 2026 releases addressed CVE-2026-109618 and CVE-2026-109619. The relevant fixed upstream versions were:

| PHP branch | Patched release |
| --- | --- |
| PHP 8.5 | 8.5.12 |
| PHP 8.4 | 8.4.27 |
| PHP 8.3 | 8.3.36 |
| PHP 8.2 | 8.2.35 |

Our active environment used PHP 8.4 and PHP 8.5, so those were the two releases we verified. The PHP project does not publish new security releases for end-of-life branches. A vendor backport must be evaluated separately from an official upstream release.

### What we wanted to confirm

The maintenance was complete only if the PHP packages had the expected security versions, the required PHP-FPM services could start, Nginx still routed requests to the intended runtime, and the application remained accessible. Repository changes alone would not establish any of those outcomes.

## The First Action: Updating the Server's Packages {#initial-php-security-update}

Before we started discussing the repository migration, the command we ran was:

```bash
sudo apt update && sudo apt upgrade -y
```

The first command refreshed APT's package indexes. The second installed available upgrades from the repositories configured at that time. The `&&` ensured that the upgrade would start only if the index refresh succeeded, while `-y` automatically accepted APT's confirmation prompts.

That is an important distinction in this case study. **This was the actual initial update command.** We did not first write a migration script, explicitly select 29 packages, or downgrade anything to install the security release. Those operations came later.

The full installation transcript from this initial upgrade was not preserved in the conversation, so we cannot attribute each individual package change to a specific APT transaction line. What we can document is the state we observed in the checks immediately afterward.

For a production server, it is generally safer to inspect the pending package transaction and have a recoverable backup or snapshot before running an automatically confirmed upgrade. That is an operational recommendation, not an additional step being claimed as part of our original command.

## What We Verified After the Initial Upgrade {#initial-verification}

We checked the CLI binary and the package inventory:

```bash
php -v
which php
readlink -f "$(which php)"
```

The PHP CLI reported the following in our initial check:

```text
PHP 8.5.12 (cli) (built: Oct 21 2026 14:37:30) (NTS)
Copyright (c) The PHP Group
Built by Ubuntu
Zend Engine v4.5.12, Copyright (c) Zend Technologies
    with Zend OPcache v8.5.12, Copyright (c), by Zend Technologies
```

The package inventory also showed PHP 8.4 packages at `8.4.27`. Both branches had therefore reached the fixed upstream versions we were looking for.

We also checked the PHP-FPM version directly, because `php -v` describes the CLI runtime, not necessarily the version handling HTTP requests:

```bash
/usr/sbin/php-fpm8.5 -v
systemctl list-units --all 'php*-fpm.service'
```

Both PHP 8.4-FPM and PHP 8.5-FPM were running. At this point, the evidence supported that the patched versions were installed. It did not yet tell us whether our APT repository configuration was clean.

## The Repository Situation We Discovered {#repository-situation}

While reviewing where the PHP packages were coming from, we found two repository definitions:

```text
/etc/apt/sources.list.d/ondrej-ubuntu-php-noble.sources:2:URIs: https://ppa.launchpadcontent.net/ondrej/php/ubuntu/
/etc/apt/sources.list.d/php.list:1:deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ noble main
```

The older `ppa:ondrej/php` Launchpad source and the newer `packages.sury.org/php` source were both present. We had already consulted the [official Sury repository README](https://packages.sury.org/php/README.txt), which describes installing the repository keyring and registering the new APT source.

We did not need to change the PHP major version. The question was whether package management should continue using an older source definition while the new repository provided its own builds.

We disabled the old PHP Launchpad source and refreshed the package indexes. The installed PHP versions did not change at this stage; removing a repository definition does not uninstall its packages.

## Why APT Did Not Automatically Switch the Builds {#apt-build-version-mismatch}

After disabling the old PPA, `apt-cache policy` still preferred the installed package revision. For PHP 8.5-FPM, the important values were:

| Package state | Version |
| --- | --- |
| Installed after the initial upgrade | `8.5.12-1+ubuntu24.04.1+deb.sury.org+1` |
| Available from packages.sury.org | `8.5.12-1+0~20261021.27+ubuntu24.04~1.gbp1a3e8a` |

Both packages identified upstream PHP **8.5.12**, but Debian's version comparison ranked the installed revision higher. APT therefore did not replace it automatically with the differently numbered Sury build. The same pattern applied to PHP 8.4.27.

We had already installed the patched PHP releases. **The next task was package build alignment for future maintenance, not a second security patch installation.** This difference matters because a server that already runs a patched release should not be told to force a downgrade merely to complete this particular CVE fix.

## The Dependency Conflict During Build Alignment {#dependency-conflict}

We tried simulating the replacement of the three PHP 8.5 core packages with their exact versions from the new repository:

```bash
sudo apt-get -s install --allow-downgrades \
  php8.5-cli=8.5.12-1+0~20261021.27+ubuntu24.04~1.gbp1a3e8a \
  php8.5-fpm=8.5.12-1+0~20261021.27+ubuntu24.04~1.gbp1a3e8a \
  php8.5-common=8.5.12-1+0~20261021.27+ubuntu24.04~1.gbp1a3e8a
```

The `-s` option made this a simulation, so APT did not install anything. It failed because `php8.5-readline` still depended on the old, exact revision of `php8.5-common`. A similar simulation for PHP 8.4 failed on `php8.4-opcache` and `php8.4-readline`.

This was not an indication of a broken security release. It was a dependency consistency issue: related extension packages needed to be replaced alongside the PHP core packages.

We then used a Bash command to discover all *installed* `php8.4-*` and `php8.5-*` packages and resolve their exact available Sury revisions before simulating them together. That approach included optional extensions such as Redis and igbinary for PHP 8.4, rather than assuming the server only had `cli`, `fpm`, and `common`.

The successful simulation produced this actual APT summary:

```text
0 upgraded, 0 newly installed, 29 downgraded, 0 to remove and 1 not upgraded.
```

Here, *downgraded* referred to **Debian package revision ordering**. PHP was not being changed from 8.5 to 8.4, or from 8.5.12 to an earlier upstream version.

The 29-package count describes our server, not a package list that other installations must reproduce. A coordinated transaction and a removal check were important because forcing only part of the installed PHP package set had already failed.

## Moving All 29 PHP Packages to the Sury Builds {#migrating-sury-builds}

After the simulation succeeded, we executed the corresponding installation transaction for the 29 installed PHP 8.4 and 8.5 packages. The command selected each package's concrete Sury revision and used `--allow-downgrades` because APT considered those package revisions lower. It also used `--no-remove` to prevent package removal as part of the operation.

The installation completed without a reported dependency error. The important confirmation came from checking the installed package revisions afterward:

```bash
apt-cache policy php8.5-fpm php8.4-fpm
```

The resulting package state was:

| Package | Installed Sury revision |
| --- | --- |
| `php8.5-fpm` | `8.5.12-1+0~20261021.27+ubuntu24.04~1.gbp1a3e8a` |
| `php8.4-fpm` | `8.4.27-1+0~20261021.57+ubuntu24.04~1.gbp7636b9` |

For both, the `Installed` and `Candidate` values matched and the available package was associated with `https://packages.sury.org/php`.

This completed the build alignment. We did not use permanent repository pinning or remove the entire older PHP installation. We also did not run `apt autoremove` simply because APT listed some old kernel packages as no longer required.

## Verifying PHP-FPM, Nginx, and the Application {#runtime-verification}

We tested both PHP-FPM configuration files with elevated permissions:

```bash
sudo php-fpm8.5 -t
sudo php-fpm8.4 -t
sudo nginx -t
```

All three checks succeeded. An earlier PHP-FPM test without `sudo` had failed when attempting to open a protected log file. Running the configuration check with the appropriate permissions resolved that testing issue without changing the log file permissions.

We also inspected Nginx's active FastCGI destinations:

```bash
sudo nginx -T 2>/dev/null | grep -nE \
  'fastcgi_pass|php[0-9]\.[0-9]-fpm.sock'
```

The relevant configured locations pointed to the PHP 8.5-FPM socket, `/run/php/php8.5-fpm.sock`. PHP 8.4-FPM was still installed and running, but we did not disable it as part of this maintenance.

The PHP-FPM service log subsequently showed a successful restart after the package migration. A public HTTP check returned status **200** for QadrLabs. Because the site uses Cloudflare, that result confirmed that the public endpoint responded successfully; it did not independently prove that every authenticated or background application path had been tested.

We have intentionally omitted the raw HTTP headers from this case study. They included cookies and other values that are unnecessary in a public technical article.

## Why We Rebooted the Server {#why-we-rebooted}

The PHP updates themselves were not the only packages affected by the day's maintenance. Ubuntu also reported pending reboot requirements for system components, including kernel packages.

Before reboot, the running kernel was:

```text
6.8.0-101-generic
```

A newer kernel image, `6.8.0-147-generic`, was installed. We rebooted in order to start the updated kernel and complete the system maintenance. After reconnecting, `uname -r` reported:

```text
6.8.0-147-generic
```

This is specific to our server. Updating PHP does not inherently require every Ubuntu host to reboot. Whether to restart PHP-FPM, Nginx, or the full operating system depends on the packages changed and the services using them.

## The Final Post-Reboot Checks {#post-reboot-checks}

We checked the status of Nginx and both PHP-FPM services, the CLI PHP version, the outstanding restart notices, and the public application endpoint:

```bash
systemctl is-active nginx php8.5-fpm php8.4-fpm
php -v
sudo needrestart -r l
```

The three services reported `active`. PHP CLI still reported 8.5.12, and `needrestart` reported that the running kernel was up to date with no user sessions running outdated binaries. The website continued returning HTTP 200 after reboot.

Other unrelated maintenance issues encountered during the session are deliberately outside the scope of this article.

These checks support our conclusion that the PHP patch versions were installed, the runtime services survived the package changes and reboot, and the public application endpoint remained available. They do not constitute a penetration test or a complete functional test of every application feature.

## What This Maintenance Taught Us {#lessons-learned}

The most useful lesson was that **the security upgrade and the repository build migration were two different events**. Our first action was a normal APT update and upgrade. The later APT simulations and coordinated package transaction solved a build-selection problem discovered during verification.

A few other details are worth remembering:

- **Check the runtime that serves requests.** A patched CLI binary does not prove that every web application uses that same PHP-FPM service.
- **Treat repository changes as package-management work.** Registering a new APT source does not replace already installed binaries, particularly when their complete Debian revisions sort higher.
- **Simulate coordinated changes.** PHP extensions can require exactly matching core package revisions, so replacing only `cli`, `fpm`, and `common` may fail.
- **Separate evidence from recommendations.** Record observed package versions and service status; avoid implying that additional best-practice commands were run if they were not.
- **Verify after reboot.** A successful installer message does not replace checking the running kernel, services, and application response.

## Conclusion {#conclusion}

The QadrLabs server maintenance began as a response to the critical PHP RCE security release. We ran `sudo apt update && sudo apt upgrade -y`, verified PHP 8.5.12 and PHP 8.4.27, discovered a repository overlap, and then migrated 29 installed PHP packages to the new Sury build revisions. After validating PHP-FPM and Nginx, we rebooted to activate a separately installed kernel update and confirmed that the services and public website were still responsive.

- **Security patch first.** The practical objective was to run the patched PHP versions, not simply change repository addresses.
- **Repository alignment second.** Moving installed build revisions to `packages.sury.org` helped establish a clear source for future package maintenance.
- **Dependency checks matter.** The initial partial migrations failed, while the coordinated 29-package simulation found a transaction without removals.
- **Verification is part of the patch.** PHP-FPM startup, Nginx routing, kernel status, and application availability provided more useful evidence than the upgrade command alone.
- **A case study is not a checklist for every server.** The commands and results reflect this Ubuntu 24.04 environment. Other servers may have different PHP branches, package sources, service layouts, and reboot requirements.

References: [PHP security releases](https://www.php.net/), [The PHP Foundation's security release summary](https://thephp.foundation/blog/2026/10/21/todays-php-security-release-and-how-were-strengthening-php-security/), [Sury PHP repository README](https://packages.sury.org/php/README.txt), and the [earlier QadrLabs CVE analysis](https://qadrlabs.com/post/php-critical-rce-vulnerabilities-cve-2026-109618-and-cve-2026-109619-what-happened-and-how-to-protect-your-servers).
