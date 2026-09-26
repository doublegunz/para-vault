# 3 Simple Actions to Protect Your Project from Malicious Packages

Every time you type `npm update`, `pnpm install`, or `composer update`, your project accepts code that nobody on your team has read. The package manager resolves a version, downloads a tarball, and drops it into `node_modules/` or `vendor/`. From that moment the code runs with the same permissions as your application, on your laptop, in your CI runner, and eventually on your production server.

That trust has been abused again and again. In May 2026 more than 700 historical versions of packages under the `laravel-lang` organization were found to carry a remote code execution backdoor, and `intercom/intercom-php` was hijacked through a stolen token in the same year. The payloads went after cloud credentials, CI/CD secrets, SSH keys, and password managers. Nobody who installed those versions did anything unusual. They ran a routine update at the wrong moment, and that was enough. The JavaScript, Rust, and Go ecosystems have seen the same pattern many times, so this is not a PHP problem or an npm problem. It is a supply chain problem.

The good news is that you do not need a security team or an expensive platform to shrink that risk dramatically. Three simple actions cover most of the ground: make your package manager wait before it trusts a new release, audit the GitHub settings that protect your code and your releases, and review dependency changes before they land. Each one takes minutes to set up, and the ideas apply to almost any language you work with.

## Overview {#overview}

This article is a practical reference rather than a build-along tutorial. Each action is explained on its own, with the exact configuration or command you need to apply it to an existing project. You can adopt all three in one sitting, or start with the one that fits your stack and add the others later, because none of them depends on the others.

### What You'll Build

- A **minimum release age cooldown** for npm, pnpm, or Composer that refuses to install versions younger than seven days.
- A **GitHub security audit** of your user account, organization, or repository, with a list of settings worth turning on.
- A **dependency vetting workflow** that shows you what an update changes before the code lands in your project.

### What You'll Learn

- Why the first hours after a package is published are the most dangerous window, and how a cooldown avoids it.
- How to configure `min-release-age` in npm, `minimumReleaseAge` in pnpm, and a release age policy for Composer through Laravel Vet.
- What Composer 2.10's built-in malware filtering does, and where its limits are.
- How to run Laravel Moat against your GitHub account and which of its checks matter most.
- How dependency vetting works with Laravel Vet for PHP and Cargo Vet for Rust, including AI-assisted review.

### What You'll Need

- An existing JavaScript project using npm 11 or pnpm 10.16+, or a PHP project using Composer 2.10+.
- PHP 8.4+ if you want to use Laravel Vet (it works in any Composer project, not only Laravel).
- A GitHub account, plus the [GitHub CLI](https://cli.github.com/) (`gh`) for authenticating Laravel Moat.
- Homebrew on macOS or Linux for the easiest Moat install, or the ability to download a prebuilt binary.
- Basic comfort with the terminal and your package manager's config files.
- Optional background reading: [PHP Supply Chain Security: What Changed in Composer 2.10 and Why It Matters](https://qadrlabs.com/post/php-supply-chain-security-what-changed-in-composer-210-and-why-it-matters).

## Why Supply Chain Attacks Keep Working {#why-supply-chain-attacks-keep-working}

Before looking at the fixes, it helps to understand why these attacks succeed so often. A supply chain attack does not break into your application directly. It breaks into something your application trusts, and then waits for you to install it.

### The Common Attack Paths

Most malicious packages reach developers through one of a few routes:

- **Hijacked maintainer accounts.** An attacker steals a publishing token or a password without two-factor authentication, then publishes a new version of a legitimate, popular package with a payload inside.
- **Typosquatting.** A package with a name one character away from a popular one (`lodahs` instead of `lodash`) waits for someone to mistype an install command.
- **Dependency confusion.** A public package uses the same name as a private internal package, and a misconfigured resolver picks the public one because it has a higher version number.
- **Compromised CI pipelines.** A weak GitHub Actions workflow leaks a publishing secret, and the attacker publishes through the project's own release process.

The first route is the most damaging, because the package name is one you already depend on. Your lock file points at it, your update command pulls it, and nothing looks out of place.

### Why the First Few Days Matter

Malicious releases rarely stay online for long. Security vendors, registry operators, and the maintainers themselves usually spot a hijacked version within hours or days, and the registry pulls it. The people who get hurt are the ones who installed it during that window. That observation is the foundation of the first action in this article.

### What Package Managers Already Do for You

Registries are fighting back. Packagist.org integrated Aikido's malware intelligence in 2026, and Composer 2.10 ships native malware filtering that is enabled by default. When a version is flagged as malware, Composer refuses to install it. The behavior is controlled by a `policy` block in `composer.json`:

```json
{
    "config": {
        "policy": {
            "malware": {
                "block-scope": "all"
            }
        }
    }
}
```

The `block-scope` option decides which commands are allowed to block. The default, `all`, blocks during both `update`/`require`/`remove` and `install`. The value `update` only blocks when resolving new versions, and `install` only blocks when installing from an existing lock file. You do not need to add this block at all to be protected, since `all` is already the default. It is shown here so you know where the setting lives and can confirm nobody on your team has weakened it.

Built-in filtering has one important limit: it can only block what has already been reported. A payload published an hour ago is on nobody's list yet. The three actions below cover exactly that gap.

## Action 1: Add a Minimum Release Age Cooldown {#action-1-minimum-release-age}

The simplest defense against a fresh malicious release is to not install fresh releases at all. A minimum release age, often called a cooldown, tells your package manager to ignore any version that was published less than a set amount of time ago. If a hijacked version is published and pulled within three days, a seven day cooldown means your project never sees it.

### How a Cooldown Works

When the package manager resolves dependencies, it checks the publish timestamp of each candidate version. Versions younger than the configured age are treated as if they do not exist yet, so the resolver falls back to the newest version that is old enough. Nothing is blocked permanently. The new version simply becomes eligible once it has aged past the threshold.

Seven days is a common starting value. It is long enough for most malicious releases to be detected and removed, and short enough that you still stay close to current versions. Keep in mind that different tools use different units. npm counts in days, pnpm counts in minutes (seven days is `10080` minutes), and Laravel Vet counts in days.

### npm: `min-release-age`

npm supports a `min-release-age` setting measured in days. Add it to the project's `.npmrc` file so that everyone who clones the repository gets the same behavior:

```ini
# .npmrc
min-release-age=7
```

With this line in place, `npm install` and `npm update` build the dependency tree using only versions that were published more than seven days ago. Putting it in the project `.npmrc` rather than your personal `~/.npmrc` matters, because it makes the policy part of the repository and applies it in CI as well.

You can confirm the value npm actually sees with:

```bash
npm config get min-release-age
```

This reads the merged configuration from the command line, environment, project, user, and global sources, so it tells you which value wins. Note that npm also has an older `before` setting that takes a fixed date. If both are set in the same config source, `before` takes precedence, so avoid mixing them.

### pnpm: `minimumReleaseAge`

pnpm added `minimumReleaseAge` in version 10.16, and since pnpm 11 it defaults to `1440` minutes, which is one day. That default is already a big improvement, but you can raise it to seven days in `pnpm-workspace.yaml`:

```yaml
# pnpm-workspace.yaml
minimumReleaseAge: 10080

minimumReleaseAgeExclude:
  - '@myorg/*'
```

The first key sets the cooldown to 10080 minutes (7 × 24 × 60). The `minimumReleaseAgeExclude` list names packages that skip the cooldown. Scoped patterns like `'@myorg/*'` are a good fit for your own internal packages, because you control those releases and usually want them immediately. pnpm also accepts exact versions in this list, such as `webpack@5.102.1`, which is useful when you need one specific fresh release without opening the door to every future version.

### Composer: A Cooldown Through Laravel Vet

At the time of writing, Composer does not have a native minimum release age option. The name `minimum-release-age` is reserved in Composer's policy schema for a future built-in policy, but it is not something you can configure in `composer.json` today. Packagist first needs release metadata to be reliably immutable before publish time can be trusted as a security input.

Until then, [Laravel Vet](https://github.com/laravel/vet) fills the gap. It is a Composer plugin that works in any PHP project, not only Laravel applications. Install it as a development dependency:

```bash
composer require laravel/vet --dev
```

Then initialize it with a seven day cooldown:

```bash
./vendor/bin/vet --init --minimum-release-age=7
```

This command does two things. It records every package currently in `vendor/` as trusted in a new `vet.json` file, and it writes the release age policy into that same file. The relevant part of `vet.json` looks like this:

```json
{
    "minimum-release-age": 7,
    "minimum-release-age-exclude": ["laravel/*"]
}
```

`minimum-release-age` is measured in days. `minimum-release-age-exclude` works like pnpm's exclude list and accepts vendor wildcards, so you can let first-party or internal packages through without waiting. Commit `vet.json` next to `composer.lock` so that the policy follows the repository into every teammate's machine and every CI run.

### Trade-offs to Keep in Mind

A cooldown also delays good releases, and that includes security patches. When a critical vulnerability fix is published, you probably do not want to wait a week for it. This is exactly what the exclude lists are for: add the specific package, or better, the specific fixed version, to the exclude list, update, and then remove the entry once the version has aged past the threshold.

Other ecosystems are moving in the same direction. Yarn 4 ships its own release age gate, and Cargo has an experimental `-Zmin-publish-age` flag on nightly. Check your package manager's documentation for the exact setting name, because it is quickly becoming a standard feature.

## Action 2: Audit Your GitHub Security Posture {#action-2-audit-github-security}

The first action protects you from other people's compromised packages. The second one protects the packages and applications you publish yourself. Many supply chain attacks start with a weak link on GitHub: a maintainer without two-factor authentication, a workflow token with write access, an unpinned third-party action, or a secret pushed by accident. Each of those settings lives on a different screen, and none of them warns you when it is misconfigured.

[Laravel Moat](https://github.com/laravel/moat) is a small, read-only CLI written in Rust that reviews those settings in one command. Despite the name, it works for any GitHub account and any kind of project. It does not change anything. It reads your configuration and tells you what to consider turning on.

### Install Moat

On macOS or Linux, install it through Homebrew:

```bash
brew tap laravel/moat https://github.com/laravel/moat
brew install laravel/moat/moat
```

The first command registers Moat's repository as a Homebrew tap, and the second installs the `moat` binary from it. If you do not use Homebrew, download a prebuilt binary from the project's releases page and place it somewhere on your `PATH`.

### Authenticate

Moat looks for a token in this order: the `GITHUB_TOKEN` environment variable, then `GH_TOKEN`, then `gh auth token` from the GitHub CLI. The easiest route is to reuse your existing GitHub CLI login:

```bash
gh auth login
gh auth refresh --scopes admin:org,repo,workflow
```

`gh auth login` signs you in if you are not already. `gh auth refresh` adds the scopes Moat needs. Auditing an organization requires `admin:org`, `repo`, and `workflow`. Auditing a personal account only needs `repo` and `workflow`, so you can leave out `admin:org` in that case.

If you create a personal access token specifically for Moat instead, revoke it as soon as you are done. A long-lived token with `admin:org` scope is exactly the kind of credential attackers look for.

### Run the Audit

Point Moat at an organization, a user, or a single repository:

```bash
# Audit a whole organization or user account
moat your-org

# Audit a single repository
moat your-org/your-repo
```

The account argument accepts an organization name, a username, or an `owner/repo` slug. For an organization, Moat checks organization-level settings and then walks through its repositories. Each check is reported as passing or as a recommendation, so you end up with a concrete list of settings to review.

### The Checks That Matter Most

Moat covers a long list of settings. If you only have time for a few, these give the biggest return:

- **Two-factor authentication.** Moat checks that the organization requires 2FA and that every member has it enabled. A stolen password alone should never be enough to publish a release.
- **Secret scanning and push protection.** Secret scanning finds leaked keys in your history, and push protection blocks new ones before they reach GitHub.
- **Dependabot alerts and security updates.** These tell you when one of your own dependencies has a known vulnerability, and open pull requests to fix it.
- **Read-only workflow token.** The default `GITHUB_TOKEN` for Actions should be read-only, with write permission granted per job only where needed.
- **SHA-pinned actions.** Referencing a third-party action by tag (`@v4`) means whoever controls that tag controls your pipeline. Pinning to a full commit SHA removes that risk.
- **Safe `pull_request_target` usage.** Workflows triggered by `pull_request_target` run with secrets available, so they must not check out and execute untrusted fork code.
- **Branch protection and signed commits.** Required reviews, locked release branches, and signed commits make it much harder to slip malicious code into a release unnoticed.
- **Immutable releases.** Once published, a release should not be silently replaceable.

Moat is intentionally narrow. It is not a dependency scanner, it does not read `composer.lock` or `package-lock.json`, and it does not fix anything for you. Its job is to make your GitHub configuration visible.

### Look Beyond Your Own Repositories

Securing your own account matters, but your application also depends on dozens of maintainers you have never met. If a package you rely on is maintained by a small team, it is worth suggesting these settings to them, or opening an issue that points to Moat. Every maintainer who enables 2FA and push protection makes the whole ecosystem a little safer, including your project.

For a complete walkthrough with real output, see [Audit GitHub Repository Security with Laravel Moat](https://qadrlabs.com/post/audit-github-repository-security-with-laravel-moat).

## Action 3: Vet Dependency Changes Before They Land {#action-3-vet-dependencies}

A cooldown avoids brand new releases, and malware filtering blocks known bad ones. Neither of them tells you what an update actually changes. The third action closes that gap by adding a review step: before new code is written into your project, you see the diff and decide whether you trust it.

### The Vetting Concept

Dependency vetting borrows the idea of code review and applies it to third-party code. The workflow has three parts:

1. **Diff.** When a package changes version, the tool shows you the difference between the version you already trust and the incoming one.
2. **Review.** You (or an assistant) read the changes, looking for anything that does not belong: network calls in a string helper, obfuscated code, new install scripts, or code that reads environment variables it never needed before.
3. **Record.** Once you are satisfied, you mark that exact version as trusted in a file that lives in your repository.

The trust file is what makes vetting scale. After the initial baseline, you only ever review what changed, not the entire dependency tree again.

### Laravel Vet for PHP

Laravel Vet, the same tool used for the Composer cooldown in Action 1, is built around this workflow. Because it runs as a Composer plugin, it intercepts every `composer install` and `composer update`. When a package arrives that is not in `vet.json`, Vet shows the pending change and refuses to let it through until someone has reviewed it.

The day-to-day commands are short:

```bash
# Show every package that is waiting for review
./vendor/bin/vet

# Inspect the pending change for one package
./vendor/bin/vet acme/logger

# Show the full diff of every pending change
./vendor/bin/vet -v
```

Running `./vendor/bin/vet` with no arguments in a terminal walks you through the packages that are not trusted yet and lets you pick the ones to record. Passing a package name focuses on a single dependency, which is handy when one update touches many packages but only one of them looks suspicious. The `-v` flag prints the complete changes rather than a summary. If you ever want to rebuild the trust file from scratch, `./vendor/bin/vet --fresh` starts over.

Outside an interactive terminal, such as in CI, Vet never asks questions. It either passes because every package is trusted, or fails and lists the packages nobody has reviewed. That makes it a natural gate in a pipeline: an unreviewed dependency cannot reach your main branch without a human looking at it first.

### AI-Assisted Review

Reading every diff by hand works for a small update, but a framework upgrade can touch dozens of packages. Vet can hand each change to a coding agent already installed on your machine. It supports Claude Code, Codex, Gemini, and opencode. When you run `./vendor/bin/vet` in a terminal, you can choose to let the agent read the changes first, and it answers each package with a verdict:

- **PASS** means the agent read every changed file and found no security concerns.
- **FAIL** means the agent found something suspicious, and it names the file and the reason.
- **WARN** means the analysis was partial, for example because a file was too large for the agent's context, so the rest of the reading is yours.

The agent only runs when you ask for it. The Composer plugin itself never calls an agent, and neither does a CI run. The agent advises, and you still make the final decision about what goes into `vet.json`.

For a full hands-on walkthrough, including a real intercepted update and an agent verdict, read [Laravel Vet: Audit What composer update Writes Into vendor/ Before It Lands](https://qadrlabs.com/post/laravel-vet-audit-what-composer-update-writes-into-vendor-before-it-lands).

### Cargo Vet and Other Ecosystems

The vetting idea did not start with PHP. Mozilla's [cargo-vet](https://mozilla.github.io/cargo-vet/) brought it to Rust, where the same diff, review, and record loop is used by large projects:

```bash
cargo install --locked cargo-vet
cargo vet init
cargo vet
```

`cargo vet init` creates the `supply-chain/` directory that holds your audits and imports, and treats your current dependencies as the starting baseline. Running `cargo vet` afterwards checks that every dependency is covered by an audit, and tells you which crates need review when something changes. Audits can also be shared and imported between organizations, so you can trust reviews already done by teams you trust.

If your language does not have a dedicated vetting tool yet, the principle still applies. Review lock file diffs in pull requests, look at the actual source changes of important dependencies before merging an update, and keep the review in version control where the whole team can see it.

## How the Three Actions Work Together {#how-the-three-actions-work-together}

Each action covers a different part of the problem, and together they form layers of defense. None of them is perfect alone, but an attacker has to get past all three to reach your project.

The cooldown is a defense based on **time**. It assumes that most malicious releases are found quickly and keeps you out of that early window. The GitHub audit is a defense of the **platform**. It makes it harder for anyone to hijack your repositories or your release process in the first place. Vetting is a defense at the level of the **code**. It catches what the other layers miss by putting a reviewer between the registry and your `vendor/` or `node_modules/` directory.

| Action | Protects against | Main tools | Effort |
| --- | --- | --- | --- |
| Minimum release age | Freshly published malicious versions | npm `min-release-age`, pnpm `minimumReleaseAge`, Laravel Vet | One config line |
| GitHub security audit | Account takeover, leaked secrets, weak CI | Laravel Moat, GitHub settings | One command, then settings changes |
| Dependency vetting | Malicious code that is old enough and not yet reported | Laravel Vet, cargo-vet | Ongoing review of each update |

A good order for adoption follows the effort column. Add the cooldown today, because it costs almost nothing. Run Moat this week and fix the most important findings. Then introduce vetting into your workflow and CI, where it becomes part of how your team handles every update.

## Conclusion {#conclusion}

Supply chain attacks work because installing a package is an act of trust that most of us perform without thinking. You cannot read every line of every dependency, but you can make that trust much harder to abuse. A cooldown keeps you away from the riskiest releases, a GitHub audit closes the doors attackers use to publish them, and vetting gives you a chance to see the code before it runs.

- **Supply chain attacks target trust, not your code.** Hijacked maintainer accounts, typosquatting, and dependency confusion all rely on you installing something that looks legitimate.
- **Built-in malware filtering is a floor, not a ceiling.** Composer 2.10 blocks versions flagged by Aikido by default, but it can only block what has already been reported.
- **A minimum release age avoids the most dangerous window.** Use `min-release-age=7` in npm, `minimumReleaseAge: 10080` in pnpm, and Laravel Vet's `--minimum-release-age=7` for Composer until Composer ships its own option.
- **Exclude lists handle urgent patches.** Let specific packages or versions skip the cooldown instead of disabling it entirely.
- **Laravel Moat makes GitHub security visible.** One read-only command reveals missing 2FA, disabled secret scanning, unpinned actions, and write-enabled workflow tokens.
- **Revoke audit tokens when you are done.** A long-lived token with `admin:org` scope is a valuable target in its own right.
- **Vetting puts a review step before new code lands.** Laravel Vet and cargo-vet record trusted versions in your repository, so each update only requires reviewing what changed.
- **AI review scales vetting without removing your judgment.** Vet's agent verdicts of PASS, FAIL, and WARN speed up large updates, while the final trust decision stays with you.
- **These ideas work in any ecosystem.** The tools differ between npm, Composer, Cargo, and others, but cooldowns, account hardening, and code review apply everywhere.
