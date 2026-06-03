# PHP Supply Chain Security: What Changed in Composer 2.10 and Why It Matters

In May 2026, two widely-used PHP packages were compromised within weeks of each other. The `laravel-lang` package and `intercom/intercom-php` were both hijacked through stolen GitHub tokens, allowing attackers to publish malicious tags on packages they did not own. The worst part? Developers running `composer update` on older Composer versions had no idea anything was wrong. Their dependency manager fetched the malicious code, installed it silently, and moved on. No warning, no error, no indication that something had gone terribly wrong.

This is not a theoretical threat anymore. Supply chain attacks against open-source ecosystems are increasing, and PHP is now a direct target. Composer 2.10 was released on May 28, 2026, specifically to address this. It introduces native malware filtering, a unified dependency policy system, and version immutability on Packagist.org. In this article, you will learn exactly what changed, how to upgrade your project, and how to verify that your Laravel application is protected.

## Overview {#overview}

This is a conceptual and practical reference article. There is no single application to build from scratch, but you will follow along with a real Laravel project to verify each security feature using actual Composer commands.

### What You'll Learn

- How supply chain attacks hit the PHP ecosystem and what made them possible
- How Composer resolves and downloads packages, and where the security gaps were
- What the new `config.policy` system in Composer 2.10 does and how to configure it
- How to upgrade to Composer 2.10 and run a security audit on a Laravel project
- What version immutability on Packagist.org means for your dependencies

### What You'll Need

- PHP 8.3 or higher
- Composer 2.x installed (you will upgrade to 2.10 during this article)
- Basic familiarity with Laravel and `composer.json`
- A terminal and a Laravel project (you will create a demo project to follow along)

## The Attacks That Changed Everything {#the-attacks}

To understand why Composer 2.10 matters, you need to understand what actually happened. Both the `laravel-lang` and `intercom/intercom-php` compromises followed the same pattern: an attacker obtained a valid access token (through phishing, credential leaks, or session hijacking) and used it to push a new git tag on a GitHub repository they did not own. Because Packagist.org listens to GitHub webhooks, it immediately picked up the new tag as a legitimate new version.

The malicious version was now live on Packagist.org. Any developer running `composer update` or `composer require` at the wrong moment could pull down the compromised package. What made this particularly dangerous was the fallback behavior in older Composer versions: even if a package repository tried to block the download, Composer would silently try the next available source, including the raw GitHub URL. The attacker controlled that GitHub URL too.

## How Composer Downloads Packages {#how-composer-downloads}

Before diving into the fixes, it helps to understand the download chain Composer follows for every package. When you run `composer install`, Composer does not just fetch a single URL. It works through a priority list embedded in your `composer.lock` file.

The typical order is:

- **Mirror or private repository dist URL**: The preferred source, often a zip archive hosted by a service like Private Packagist
- **Upstream dist URL**: Usually a GitHub zip archive, referenced directly in the package metadata
- **Source checkout**: A full `git clone` of the repository

In older versions of Composer, if the first source returned an error (including a deliberate "this version is blocked" error), Composer would log a warning and silently try the next source in the list. This meant that blocking a malicious version at the repository level was not enough. An attacker who controlled the GitHub repository could still deliver malware through the fallback path. Composer 2.10 closes this gap by treating a blocked version as a hard failure rather than a recoverable error.

## What Composer 2.10 Brings to the Table {#composer-2-10-features}

Composer 2.10 ships three major security improvements: native malware filtering, a unified dependency policy framework, and version immutability on Packagist.org. Each one addresses a different layer of the supply chain.

### Native Malware Filtering

Composer now ships with a malware feed provided by Aikido Security under a CC-BY 4.0 license. When a version is flagged as malware, Composer excludes it from the dependency resolution pool entirely. This happens before any download attempt. The protection applies to every Composer command that touches dependencies.

Here is what each command does with a flagged version:

- `composer update` and `composer require`: The flagged version is excluded from the candidate pool. Composer will not select it, even if it is the latest version
- `composer create-project`: The flagged version cannot be used as a project template
- `composer install`: Even if the flagged version is already in `composer.lock`, the install will **fail**. This is the most important behavior because it protects CI/CD pipelines that replay existing lock files

### The Dependency Policy Framework

Before Composer 2.10, security advisory blocking (introduced in 2.9) and abandoned package warnings each had their own configuration keys. Composer 2.10 consolidates everything into a single `config.policy` object in `composer.json`.

```json
{
    "config": {
        "policy": {
            "malware": {
                "block": true
            },
            "advisories": {
                "block": true
            },
            "abandoned": {
                "audit": "report"
            }
        }
    }
}
```

The `malware.block` key tells Composer to treat flagged malware versions as hard failures. Setting it to `true` is the default behavior in 2.10 and the recommended setting. The `advisories.block` key was introduced in Composer 2.9 and is also `true` by default. The `abandoned.audit` key controls how abandoned packages are surfaced by `composer audit`: `"report"` shows a warning without a failing exit code, `"ignore"` suppresses the audit finding, and `"fail"` makes the audit fail. If you want abandoned packages to block dependency changes during `composer update`, `composer require`, or `composer remove`, use `abandoned.block: true`.

The default behavior for each policy type in Composer 2.10 is:

| Policy | Blocks `update` | Blocks `install` | `composer audit` result |
|--------|----------------|-----------------|------------------------|
| Malware | Yes | Yes | Fail |
| Security Advisories | Yes | No | Fail |
| Abandoned Packages | No | No | Report only |

If you need to temporarily disable blocking without editing `composer.json`, you can use the `--no-blocking` flag or set the `COMPOSER_NO_BLOCKING=1` environment variable. This is useful in migration scenarios but should not be a permanent configuration.

### Version Immutability on Packagist.org

This is a quieter but equally important change. Packagist.org now rejects attempts to overwrite an existing stable version tag. The exact technique used in the `laravel-lang` and `intercom/intercom-php` attacks (pushing a new commit to an existing tag) is now rejected at the registry level. A version, once published, cannot be silently replaced with different code.

## Upgrading to Composer 2.10 {#upgrading-composer-2-10}

Let us start a fresh Laravel project and walk through upgrading Composer and running a security audit.

First, create a new Laravel project using the standard command. This project will serve as your sandbox for verifying the security features.

```bash
laravel new supply-chain-demo --no-interaction --database=sqlite --pest --no-boost
cd supply-chain-demo
```

This creates a new Laravel 13 project with SQLite as the database and Pest as the testing framework.

Next, upgrade Composer itself to 2.10.

```bash
composer self-update
```

Composer will download and install the latest stable version. After it finishes, verify the installed version.

```bash
composer --version
```

You should see output similar to:

```
Composer version 2.10.0 2026-05-28 15:50:00
```

Now run a security audit on your new project. Even a fresh Laravel install can have transitive dependencies with known advisories.

```bash
composer audit
```

On a clean Laravel 13 install with no known vulnerabilities, you will see:

```
No security vulnerability advisories found.
```

If any advisories exist, Composer will list them with the package name, version, CVE identifier, affected version range, and a link to the advisory. Here is a real audit result from an older Laravel starter kit with outdated Symfony dependencies:

```bash
composer audit
```

```
Found 11 security vulnerability advisories affecting 7 packages:
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/http-foundation                                                          |
| Severity          |                                                                                  |
| Advisory ID       | PKSA-y6py-qpv1-h52p                                                              |
| CVE               | CVE-2026-48736                                                                   |
| Title             | CVE-2026-48736: IpUtils::PRIVATE_SUBNETS Omits IPv6 Transition Forms (6to4,      |
|                   | NAT64, Teredo, IPv4-compatible): SSRF Bypass in NoPrivateNetworkHttpClient       |
| URL               | https://symfony.com/cve-2026-48736                                               |
| Affected versions | >=6.4.0,<6.4.41|>=7.0.0,<7.1.0|>=7.1.0,<7.2.0|>=7.2.0,<7.3.0|>=7.3.0,<7.4.0|>=7. |
|                   | 4.0,<7.4.13|>=8.0.0,<8.0.13                                                      |
| Reported at       | 2026-05-26T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/http-kernel                                                              |
| Severity          | medium                                                                           |
| Advisory ID       | PKSA-dw7n-x7f5-zf63                                                              |
| CVE               | CVE-2026-45075                                                                   |
| Title             | CVE-2026-45075: HEAD Request Bypasses methods: ['GET'] Filter in #[IsGranted] /  |
|                   | #[IsSignatureValid] / #[IsCsrfTokenValid]                                        |
| URL               | https://symfony.com/cve-2026-45075                                               |
| Affected versions | >=7.4.0,<7.4.12|>=8.0.0,<8.0.12                                                  |
| Reported at       | 2026-05-20T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/mailer                                                                   |
| Severity          | medium                                                                           |
| Advisory ID       | PKSA-28rh-rzzn-djk4                                                              |
| CVE               | CVE-2026-45068                                                                   |
| Title             | CVE-2026-45068: Argument Injection in SendmailTransport via Dash-Prefixed        |
|                   | Recipient Address                                                                |
| URL               | https://symfony.com/cve-2026-45068                                               |
| Affected versions | >=2.0.0,<3.0.0|>=3.0.0,<4.0.0|>=4.0.0,<5.0.0|>=5.0.0,<5.1.0|>=5.1.0,<5.2.0|>=5.2 |
|                   | .0,<5.3.0|>=5.3.0,<5.4.0|>=5.4.0,<5.4.52|>=6.0.0,<6.1.0|>=6.1.0,<6.2.0|>=6.2.0,< |
|                   | 6.3.0|>=6.3.0,<6.4.0|>=6.4.0,<6.4.40|>=7.0.0,<7.1.0|>=7.1.0,<7.2.0|>=7.2.0,<7.3. |
|                   | 0|>=7.3.0,<7.4.0|>=7.4.0,<7.4.12|>=8.0.0,<8.0.12                                 |
| Reported at       | 2026-05-20T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/mime                                                                     |
| Severity          | medium                                                                           |
| Advisory ID       | PKSA-wtxr-p26d-nn42                                                              |
| CVE               | CVE-2026-45070                                                                   |
| Title             | CVE-2026-45070: Email Header Injection via Non-Token Characters in Mime          |
|                   | Parameter Names                                                                  |
| URL               | https://symfony.com/cve-2026-45070                                               |
| Affected versions | >=2.0.0,<3.0.0|>=3.0.0,<4.0.0|>=4.0.0,<5.0.0|>=5.0.0,<5.1.0|>=5.1.0,<5.2.0|>=5.2 |
|                   | .0,<5.3.0|>=5.3.0,<5.4.0|>=5.4.0,<5.4.52|>=6.0.0,<6.1.0|>=6.1.0,<6.2.0|>=6.2.0,< |
|                   | 6.3.0|>=6.3.0,<6.4.0|>=6.4.0,<6.4.40|>=7.0.0,<7.1.0|>=7.1.0,<7.2.0|>=7.2.0,<7.3. |
|                   | 0|>=7.3.0,<7.4.0|>=7.4.0,<7.4.12|>=8.0.0,<8.0.12                                 |
| Reported at       | 2026-05-20T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/mime                                                                     |
| Severity          | high                                                                             |
| Advisory ID       | PKSA-2n2k-66v2-bwg3                                                              |
| CVE               | CVE-2026-45067                                                                   |
| Title             | CVE-2026-45067: Email Header / SMTP Command Injection via CRLF in                |
|                   | Symfony\Component\Mime\Address                                                   |
| URL               | https://symfony.com/cve-2026-45067                                               |
| Affected versions | >=2.0.0,<3.0.0|>=3.0.0,<4.0.0|>=4.0.0,<5.0.0|>=5.0.0,<5.1.0|>=5.1.0,<5.2.0|>=5.2 |
|                   | .0,<5.3.0|>=5.3.0,<5.4.0|>=5.4.0,<5.4.52|>=6.0.0,<6.1.0|>=6.1.0,<6.2.0|>=6.2.0,< |
|                   | 6.3.0|>=6.3.0,<6.4.0|>=6.4.0,<6.4.40|>=7.0.0,<7.1.0|>=7.1.0,<7.2.0|>=7.2.0,<7.3. |
|                   | 0|>=7.3.0,<7.4.0|>=7.4.0,<7.4.12|>=8.0.0,<8.0.12                                 |
| Reported at       | 2026-05-20T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/polyfill-intl-idn                                                        |
| Severity          | low                                                                              |
| Advisory ID       | PKSA-dwsq-ppd2-mb1x                                                              |
| CVE               | CVE-2026-46644                                                                   |
| Title             | CVE-2026-46644: symfony/polyfill-intl-idn accepts xn-- labels whose Punycode     |
|                   | payload decodes to ASCII-only: insecure equivalence                              |
| URL               | https://symfony.com/cve-2026-46644                                               |
| Affected versions | >=1.17.1,<1.38.1                                                                 |
| Reported at       | 2026-05-26T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/routing                                                                  |
| Severity          |                                                                                  |
| Advisory ID       | PKSA-bf7t-jnpz-492k                                                              |
| CVE               | CVE-2026-48784                                                                   |
| Title             | CVE-2026-48784: UrlGenerator Dot-Segment Encoding Skips Every Other Chained      |
|                   | `../` or `./` → Generated URL Collapses Off-Route Under RFC 3986 Normalization   |
| URL               | https://symfony.com/cve-2026-48784                                               |
| Affected versions | >=2.0.0,<3.0.0|>=3.0.0,<4.0.0|>=4.0.0,<5.0.0|>=5.0.0,<5.1.0|>=5.1.0,<5.2.0|>=5.2 |
|                   | .0,<5.3.0|>=5.3.0,<5.4.0|>=5.4.0,<5.4.53|>=6.0.0,<6.1.0|>=6.1.0,<6.2.0|>=6.2.0,< |
|                   | 6.3.0|>=6.3.0,<6.4.0|>=6.4.0,<6.4.41|>=7.0.0,<7.1.0|>=7.1.0,<7.2.0|>=7.2.0,<7.3. |
|                   | 0|>=7.3.0,<7.4.0|>=7.4.0,<7.4.13|>=8.0.0,<8.0.13                                 |
| Reported at       | 2026-05-26T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/routing                                                                  |
| Severity          | medium                                                                           |
| Advisory ID       | PKSA-yc7t-91v9-99xs                                                              |
| CVE               | CVE-2026-45065                                                                   |
| Title             | CVE-2026-45065: UrlGenerator Route-Requirement Bypass via Unanchored Regex       |
|                   | Alternation → Off-Site //host URL Injection                                      |
| URL               | https://symfony.com/cve-2026-45065                                               |
| Affected versions | >=2.0.0,<3.0.0|>=3.0.0,<4.0.0|>=4.0.0,<5.0.0|>=5.0.0,<5.1.0|>=5.1.0,<5.2.0|>=5.2 |
|                   | .0,<5.3.0|>=5.3.0,<5.4.0|>=5.4.0,<5.4.52|>=6.0.0,<6.1.0|>=6.1.0,<6.2.0|>=6.2.0,< |
|                   | 6.3.0|>=6.3.0,<6.4.0|>=6.4.0,<6.4.40|>=7.0.0,<7.1.0|>=7.1.0,<7.2.0|>=7.2.0,<7.3. |
|                   | 0|>=7.3.0,<7.4.0|>=7.4.0,<7.4.12|>=8.0.0,<8.0.12                                 |
| Reported at       | 2026-05-20T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/yaml                                                                     |
| Severity          | low                                                                              |
| Advisory ID       | PKSA-v5yj-8nmz-sk2q                                                              |
| CVE               | CVE-2026-45304                                                                   |
| Title             | CVE-2026-45304: YAML Parser Exponential Memory Allocation via Recursive          |
|                   | Collection-Alias Expansion ("Billion Laughs")                                    |
| URL               | https://symfony.com/cve-2026-45304                                               |
| Affected versions | >=2.0.0,<3.0.0|>=3.0.0,<4.0.0|>=4.0.0,<5.0.0|>=5.0.0,<5.1.0|>=5.1.0,<5.2.0|>=5.2 |
|                   | .0,<5.3.0|>=5.3.0,<5.4.0|>=5.4.0,<5.4.52|>=6.0.0,<6.1.0|>=6.1.0,<6.2.0|>=6.2.0,< |
|                   | 6.3.0|>=6.3.0,<6.4.0|>=6.4.0,<6.4.40|>=7.0.0,<7.1.0|>=7.1.0,<7.2.0|>=7.2.0,<7.3. |
|                   | 0|>=7.3.0,<7.4.0|>=7.4.0,<7.4.12|>=8.0.0,<8.0.12                                 |
| Reported at       | 2026-05-20T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/yaml                                                                     |
| Severity          | low                                                                              |
| Advisory ID       | PKSA-ft77-7h5f-p3r6                                                              |
| CVE               | CVE-2026-45305                                                                   |
| Title             | CVE-2026-45305: YAML Parser ReDoS via Catastrophic Backtracking in               |
|                   | Parser::cleanup() Regex                                                          |
| URL               | https://symfony.com/cve-2026-45305                                               |
| Affected versions | >=2.0.0,<3.0.0|>=3.0.0,<4.0.0|>=4.0.0,<5.0.0|>=5.0.0,<5.1.0|>=5.1.0,<5.2.0|>=5.2 |
|                   | .0,<5.3.0|>=5.3.0,<5.4.0|>=5.4.0,<5.4.52|>=6.0.0,<6.1.0|>=6.1.0,<6.2.0|>=6.2.0,< |
|                   | 6.3.0|>=6.3.0,<6.4.0|>=6.4.0,<6.4.40|>=7.0.0,<7.1.0|>=7.1.0,<7.2.0|>=7.2.0,<7.3. |
|                   | 0|>=7.3.0,<7.4.0|>=7.4.0,<7.4.12|>=8.0.0,<8.0.12                                 |
| Reported at       | 2026-05-20T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
+-------------------+----------------------------------------------------------------------------------+
| Package           | symfony/yaml                                                                     |
| Severity          | low                                                                              |
| Advisory ID       | PKSA-b14r-zh1d-vdrc                                                              |
| CVE               | CVE-2026-45133                                                                   |
| Title             | CVE-2026-45133: YAML Parser Stack Exhaustion via Unbounded Recursion in Nested   |
|                   | Blocks, Sequences, and Mappings                                                  |
| URL               | https://symfony.com/cve-2026-45133                                               |
| Affected versions | >=2.0.0,<3.0.0|>=3.0.0,<4.0.0|>=4.0.0,<5.0.0|>=5.0.0,<5.1.0|>=5.1.0,<5.2.0|>=5.2 |
|                   | .0,<5.3.0|>=5.3.0,<5.4.0|>=5.4.0,<5.4.52|>=6.0.0,<6.1.0|>=6.1.0,<6.2.0|>=6.2.0,< |
|                   | 6.3.0|>=6.3.0,<6.4.0|>=6.4.0,<6.4.40|>=7.0.0,<7.1.0|>=7.1.0,<7.2.0|>=7.2.0,<7.3. |
|                   | 0|>=7.3.0,<7.4.0|>=7.4.0,<7.4.12|>=8.0.0,<8.0.12                                 |
| Reported at       | 2026-05-20T08:00:00+00:00                                                        |
+-------------------+----------------------------------------------------------------------------------+
```

Because `advisories.block` is `true` by default, any subsequent `composer update` command will refuse to install a version with a known advisory. That is the behavior you want in CI/CD: the audit output tells you what is already present in the lock file, while dependency resolution prevents vulnerable versions from being selected again.

To see the policy configuration your project is using, run:

```bash
composer config policy
```

On a fresh project without any explicit `config.policy` in `composer.json`, Composer uses the built-in defaults. The output will reflect those defaults.

### Adding an Explicit Policy to composer.json

It is good practice to document the security posture of your project explicitly rather than relying on Composer defaults. Open `composer.json` and add the policy block inside the `config` section.

```json
{
    "name": "laravel/laravel",
    "require": {
        "php": "^8.3",
        "laravel/framework": "^13.0"
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true,
        "allow-plugins": {
            "pestphp/pest-plugin": true,
            "php-http/discovery": true
        },
        "policy": {
            "malware": {
                "block": true
            },
            "advisories": {
                "block": true
            },
            "abandoned": {
                "audit": "report"
            }
        }
    }
}
```

The `malware.block: true` setting ensures that Composer 2.10 will refuse to install or update to any version flagged by the Aikido malware feed. The `advisories.block: true` setting was already the default since Composer 2.9, but declaring it explicitly makes the intent clear to anyone reading the project configuration. The `abandoned.audit: "report"` setting means Composer will report abandoned packages during `composer audit` without failing the command.

After saving `composer.json`, run the audit one more time to confirm everything is clean.

```bash
composer audit
```

```
No security vulnerability advisories found.
```

## Verifying the Malware Blocking Behavior {#verifying-malware-blocking}

You cannot install a real malware-flagged package to test this (for obvious reasons), but you can observe how Composer behaves when the policy blocks a dependency. The easiest way is to use the `--dry-run` flag on an update and inspect the output. If a malware-flagged version existed in your dependency tree, the command would exit with a non-zero status code and print a message like:

```
Package acme/example version 1.2.3 is flagged as malware and cannot be installed.
```

The important distinction from older behavior is that Composer will not continue and fall back to another source. The command stops. Your lock file is not updated. Your CI/CD pipeline fails loudly rather than succeeding silently with compromised code.

## Understanding the Disabled Source Fallback {#disabled-source-fallback}

One behavioral change in Composer 2.10 that deserves special attention is the disabled automatic source fallback. In previous versions, if downloading a zip archive (the "dist" format) failed for any reason, Composer would automatically fall back to cloning the full git repository (the "source" format) without asking you.

This fallback was convenient for development, but it created a security gap: an attacker who managed to get a dist download blocked could still deliver malicious code through the git clone path, since they controlled the GitHub repository. In Composer 2.10, the default `source-fallback` setting is `false`. When a dist download fails, Composer throws an error immediately instead of silently trying a source checkout. The temporary `source-fallback` option exists only for teams that must restore the older behavior, and Composer plans to remove it entirely in Composer 2.11.

If you have a workflow that genuinely needs source checkouts (for example, contributing patches to a package), use the explicit `--prefer-source` flag. This makes the intent clear and does not silently fall back.

```bash
composer install --prefer-source
```

Using `--prefer-source` explicitly tells Composer you want git checkouts. It is an intentional choice, not a silent fallback.

## What's Coming Next {#whats-coming}

The Composer 2.10 release is one part of a longer roadmap that the Packagist team has outlined publicly. Several features are still in development as of June 2026.

The roadmap includes:

- **Mandatory MFA on Packagist.org**: All maintainer accounts will eventually require multi-factor authentication. The timeline is not fixed yet, but the team has stated that MFA status will become publicly visible on maintainer profiles first
- **FIDO2-backed staged releases**: New versions would require confirmation from a hardware security key before going live on Packagist. This means a stolen GitHub token alone would not be enough to publish a malicious release
- **SLSA build provenance and Sigstore attestations**: Packagist.org plans to host package artifacts directly (rather than pointing to GitHub zips) and attach signed provenance records to every release
- **Transparency log improvements**: The existing public transparency log (which records ownership changes, tag modifications, and maintainer additions) will be expanded to include MFA events

The SLSA and Sigstore work represents the most significant architectural change. It would make Packagist.org a first-class artifact host rather than a metadata registry, and it would allow developers to verify the build provenance of any package they install.

## Conclusion {#conclusion}

Composer 2.10 is a meaningful step forward for PHP supply chain security, not just an incremental release. Here are the key things to take away from this article.

- **Upgrade immediately.** Running `composer self-update` takes seconds and gives you native malware filtering that is active by default on all subsequent installs and updates.
- **The malware block applies to `composer install` too.** This is the most important behavioral change. Even if a compromised version is already in your `composer.lock`, Composer 2.10 will refuse to install it.
- **Version immutability on Packagist.org closes the re-tagging attack vector.** The exact technique used in the May 2026 attacks is now rejected at the registry level.
- **The silent source fallback is disabled by default.** Composer 2.10 no longer silently falls back from a blocked dist download to a git clone. This eliminates a bypass path that attackers could exploit.
- **Declare your policy explicitly in `composer.json`.** Adding a `config.policy` block documents your project's security posture and ensures consistent behavior across all environments and team members.
- **Enable MFA on your Packagist.org account now.** If you maintain any public PHP packages, this is the single most impactful thing you can do today while the larger infrastructure improvements are still being built.
