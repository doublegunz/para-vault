Supply chain attacks do not always come from outside the ecosystem we trust. On May 23, 2026, SocketSecurity disclosed that more than 700 historical versions of packages under the `laravel-lang` organization had been compromised with an RCE backdoor. The affected packages included `laravel-lang/lang`, `laravel-lang/http-statuses`, `laravel-lang/attributes`, and `laravel-lang/actions`, all packages that thousands of Laravel projects had been installing without a second thought. The payload targeted cloud credentials, CI/CD secrets, Kubernetes tokens, Vault configurations, browser data, password managers, and SSH keys. No elaborate server exploit required. Just `composer install`, and any machine that ran it was already compromised.

Two days later, on May 25, 2026, Nuno Maduro introduced Laravel Moat. In his own words: "as an open source maintainer, recent supply chain attacks in the ecosystem made me want a simple cli to audit the security of my GitHub organizations and repositories." The connection was direct and deliberate.

Most developers set up a GitHub repository, push some code, and move on. Branch protection rules, Dependabot alerts, secret scanning, workflow permissions: each of these lives on a different settings screen, and none of them alerts you when it is misconfigured. They just sit there, quietly creating gaps. The Laravel Lang incident is proof of how much damage can happen before anyone notices.

## Overview {#overview}

Moat is a read-only CLI tool written in Rust. It connects to the GitHub API using a token you provide, inspects the security controls your repositories and organization already have available, and reports which ones are not enabled or not configured in line with common recommendations. It covers two-factor authentication, branch protection, signed commits, secret scanning, Dependabot alerts, workflow permissions, pinned actions, repository webhooks, and more.

The important word is "read-only." Moat does not change any settings. It does not harden anything automatically. It surfaces suggestions, and the decisions remain yours.

In this article, you will go from a fresh Moat installation to a repository that scores 100% hardened, using a real audit run as the guide.

### What You'll Build

- A complete security audit of a GitHub repository using the `moat` CLI, going from an initial score of 27% hardened to 100% hardened by working through each finding systematically.

### What You'll Learn

- How to install Moat via Homebrew on macOS or Linux.
- How to create a GitHub Personal Access Token (PAT) with the correct scopes for Moat to work properly.
- How to read Moat's output: what PASS, FAIL, SKIPPED, and the security score mean.
- How to fix each category of finding using the suggested fix Moat provides directly in its output.
- How to use `moat.toml` to configure checks per repository.

### What You'll Need

- macOS or Linux with Homebrew installed. Moat also ships prebuilt binaries for other platforms.
- Admin access to the GitHub repository or organization you want to audit.
- A GitHub account with the ability to create Personal Access Tokens.

## Step 1: Install Moat {#step-1-install-moat}

Moat is distributed as a Homebrew formula via its own tap. The tap is hosted at `https://github.com/laravel/moat`, and you need to add it before installing the formula.

```bash
brew tap laravel/moat https://github.com/laravel/moat
brew install laravel/moat/moat
```

The first command registers the custom tap with Homebrew so it knows where to find the `moat` formula. The second command downloads and installs the prebuilt binary for your platform. Once the installation completes, verify that it worked:

```bash
moat --version
```

You should see output like this:

```
╭─ Version ────────────────────────────────────────────────────────────────────╮
│                                                                              │
│   Moat v1.0.4                                                                │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
```

If you are on a platform where Homebrew is not available, you can download a prebuilt binary directly from the [releases page](https://github.com/laravel/moat/releases) and place the `moat` binary somewhere on your `PATH`, such as `/usr/local/bin`.

## Step 2: Create a GitHub Personal Access Token {#step-2-create-github-pat}

Moat needs a GitHub token to read your repository and organization settings via the API. Without a token, it cannot retrieve branch protection rules, secret scanning status, Dependabot configuration, workflow settings, or any of the other data it needs to run its checks.

The scope of the token matters significantly. Moat resolves a token in this order: the `GITHUB_TOKEN` environment variable, then `GH_TOKEN`, then the output of `gh auth token` if the GitHub CLI is installed. If none of those are available, or if the token it finds does not have the required scopes, Moat will either refuse to run or will skip most checks silently.

For auditing a repository, you need a **classic PAT** with these three scopes:

- `repo`: reads branch protection, required reviews, secret scanning, Dependabot alerts, repository contents like `SECURITY.md`, and repository webhooks.
- `workflow`: reads `.github/workflows/*` files to detect unpinned actions, `pull_request_target` misuse, and overly permissive `permissions:` blocks.
- `admin:org`: required only if you are auditing an entire GitHub organization rather than a single repository. For org-level audits, this scope reads members, admins, outside collaborators, 2FA enforcement, and org-level Actions policies.

Go to [github.com/settings/tokens](https://github.com/settings/tokens), click "Generate new token (classic)", give it a descriptive name like `moat-audit-temp`, set an expiration of 1 day, and check the three scopes above. Copy the token immediately after creation because GitHub will not show it again.

**Important:** Moat itself warns you about this, and it is worth repeating. Revoke this token as soon as you are done running Moat. A token sitting in your shell history or in a `.env` file is itself a security risk. Visit [github.com/settings/tokens](https://github.com/settings/tokens) and delete it the moment you have finished your audit.

## Step 3: Run Moat {#step-3-run-moat}

With the token in hand, export it as an environment variable and run Moat against your repository. The argument can be a GitHub organization name, a username, or an `<owner>/<repo>` slug.

```bash
export GITHUB_TOKEN=<your-token-here>
moat <owner>/<repo>
```
For example, here we run the following command
```
moat qadrLabs/belajar-kontribusi
```

It is worth seeing what happens when the token does not have the right scopes, because this is a failure mode you will likely encounter if you reuse an existing token.

### Scenario A: Token Without Required Scopes

When Moat runs with a token that has insufficient permissions, it cannot retrieve the data it needs. Here is what the output looks like in that situation:

```
$ moat qadrLabs/belajar-kontribusi

╭──────────────────────────────────────────────────────────────────────────────╮
│  ◈ Moat v1.0.4 · qadrLabs/belajar-kontribusi                    3/16 checks  │
╰──────────────────────────────────────────────────────────────────────────────╯

│  ◈ Moat v1.0.4 · qadrLabs/belajar-kontribusi                     Repository  │
/belajar-kontribusi` — check that your token has the required scopes (`admin:org`, `repo`, `workflow`) and that the account is an organization admin
╭─ Checks ─────────────────────────────────────────────────────────────────────╮
│                                                                              │
│  —  SKIPPED   Repositories actions workflow token is read only               │
│                                                                              │
│     Reason:                                                                  │
│     No repositories in scope to evaluate.                                    │
│
│  ... (all 18 checks show SKIPPED with "No repositories in scope to evaluate")
│
╰──────────────────────────────────────────────────────────────────────────────╯

╭─ Security posture ───────────────────────────────────────────────────────────╮
│                                                                              │
│   100% hardened                                                              │
│   ████████████████████████████████████████████████████████████               │
│                                                                              │
│   ✓  0 passed    ✕  0 fails    !  0 warnings    —  18 skipped    ·  18 total │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
```

Notice the deceptive "100% hardened" score. When every check is `SKIPPED`, Moat has no failures to count, so the score looks perfect. This is not a clean bill of health; it means Moat could not see anything. The header also shows only `3/16 checks` were actually reachable. If you see all `SKIPPED` with "No repositories in scope to evaluate" as the reason, your token scope is almost certainly the problem.

### Scenario B: Token With Correct Scopes

With a token that has `repo` and `workflow` scope, the picture changes entirely:

```
$ moat qadrLabs/belajar-kontribusi

╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│  ◈ Moat v1.0.4 · qadrLabs/belajar-kontribusi                                                             Repository  │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

╭─ Checks ─────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│                                                                                                                      │
│  ✓  PASS   Repositories webhooks are secure                                1/1 repositories passing  │
│                                                                                                                      │
│     Currently: no repository webhooks across 1 repository.                                                           │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✕  FAIL   Repositories actions workflow token is read only                                1/1 repositories failing  │
│                                                                                                                      │
│     Currently: 1 repository grant workflow tokens write access to repository contents.                               │
│                                                                                                                      │
│     Suggested fix:                                                                                                   │
│     1. Open: https://github.com/qadrLabs/belajar-kontribusi/settings/actions                                         │
│     2. Workflow permissions › *Select* › Read repository contents and packages permissions                           │
│     3. *Click* › Save                                                                                                │
│                                                                                                                      │
│  ✕  FAIL   Repositories secret scanning is enabled                                         1/1 repositories failing  │
│  ✕  FAIL   Repositories secret push protection is enabled                                  1/1 repositories failing  │
│  ✕  FAIL   Repositories Dependabot alerts are enabled                                      1/1 repositories failing  │
│  ✕  FAIL   Repositories Dependabot security updates are enabled                            1/1 repositories failing  │
│  ✕  FAIL   Repositories releases are immutable                                             1/1 repositories failing  │
│  ✕  FAIL   Repositories fork pull requests require approval                                1/1 repositories failing  │
│  ✕  FAIL   Repositories commits are signed                                                 1/1 repositories failing  │
│  ✕  FAIL   Repositories pull requests require reviews                                      1/1 repositories failing  │
│  ✕  FAIL   Repositories release branches are locked                                        1/1 repositories failing  │
│  ✕  FAIL   Repositories release branches have linear history                               1/1 repositories failing  │
│  ✕  FAIL   Repositories private vulnerability reporting is enabled                         1/1 repositories failing  │
│  ✕  FAIL   Repositories have security policy                                               1/1 repositories failing  │
│                                                                                                                      │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

╭─ Security posture ───────────────────────────────────────────────────────────────────────────────────────────────────╮
│                                                                                                                      │
│   27% hardened                                                                                                       │
│   ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                                                       │
│                                                                                                                      │
│   ✓  1 passed    ✕  13 fails    !  0 warnings    —  4 skipped    ·  18 total                                         │
│                                                                                                                      │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
```

This is the honest view. One check passes (webhooks, because there are none configured and none means none are insecure), thirteen fail, and four are skipped because the repository has no GitHub Actions workflows. The score is 27% hardened, which is an accurate picture of where most repositories start.

Every `FAIL` entry includes a "Suggested fix" section with the exact URL to open and the exact UI steps to follow. The next step is to work through each of those.

## Step 4: Fix the Findings {#step-4-fix-findings}

Each finding in Moat's output includes a "Suggested fix" section that gives you the exact URL to open and the exact steps to take. This walkthrough follows those suggestions one category at a time.

### Workflow Token Permissions

The workflow token is a `GITHUB_TOKEN` that GitHub automatically injects into every Actions workflow run. By default, many repositories leave this token with write access, which means any compromised or malicious action running in your workflow can push commits, overwrite tags, and modify releases without needing any credentials beyond the token it already has.

Open `https://github.com/<owner>/<repo>/settings/actions`, scroll to the "Workflow permissions" section, select "Read repository contents and packages permissions", and click Save. This change takes effect immediately for all future workflow runs.

### Secret Scanning and Push Protection

Secret scanning monitors your repository for accidentally committed credentials like API keys, tokens, and passwords. When a secret is detected, GitHub notifies you so you can rotate it. Push protection goes one step further: it blocks a `git push` at the network layer if the incoming commits contain a recognized secret pattern, so the credential never reaches GitHub's servers at all.

Both settings live at `https://github.com/<owner>/<repo>/settings/security_analysis`. Enable "Secret scanning" first, then enable "Push protection" under it.

### Dependabot Alerts and Security Updates

Dependabot alerts notify you when a dependency you are using has a published vulnerability. Dependabot security updates go further and automatically open a pull request that bumps the vulnerable dependency to a safe version. Without security updates, an alert sits in the dashboard until a human notices; with them, you get a PR you can review and merge.

Both are on the same settings page at `https://github.com/<owner>/<repo>/settings/security_analysis`. Enable "Dependabot alerts" and then enable "Dependabot security updates" directly below it.

### Immutable Releases

Without immutable releases, anyone with push access can move an existing tag to a different commit, or replace the assets attached to a release, without creating a new release. A downstream user pinned to `v1.2.3` could silently receive different bytes after a tag has been moved.

Open `https://github.com/<owner>/<repo>/settings#releases`, check "Immutable releases", and click Save.

### Fork Pull Request Approval

When a contributor forks your public repository and opens a pull request, GitHub can run the workflow files from the PR's branch. If your repository does not require approval before running those workflows, the fork PR can execute arbitrary code on your runners the moment it is opened. This is particularly dangerous because the runner has access to your repository's filesystem and can make network requests.

Open `https://github.com/<owner>/<repo>/settings/actions`, find the "Fork pull request workflows" section, select "Require approval for all external contributors", and click Save.

### Branch Rulesets: Signed Commits, PR Reviews, Branch Lock, and Linear History

The next four findings all live inside GitHub's branch rulesets. A branch ruleset is a policy you define once and apply to a set of target branches. All four of these checks can be addressed within a single ruleset.

Open `https://github.com/<owner>/<repo>/settings/rules` and click "New ruleset" then "New branch ruleset". Give it a name like `release-branch-protection`, set Enforcement status to "Active", and under Target branches, add your default branch (typically `main` or `master`) plus any release branches.

Under Branch rules, enable these four options:

- **Require signed commits.** A stolen developer token can push commits authored as anyone on the team. Requiring a GPG or SSH verified signature ties each commit to a cryptographic key the attacker does not have.
- **Require a pull request before merging.** Set Required approvals to at least 1. Also enable "Dismiss stale pull request approvals when new commits are pushed" and "Require approval of the most recent reviewable push." These two sub-options close the gap where an attacker amends a previously-approved PR with a malicious commit after approval.
- **Restrict deletions** and **Block force pushes.** Together these prevent anyone from rewriting branch history or erasing the audit trail of a malicious commit.
- **Require linear history.** A merge commit can include an unreviewed parent branch. Requiring linear history (rebase merges only) means every commit on the release branch was individually reviewed.

Click Create. A note on friction: strict branch rules can block a solo maintainer from merging their own changes. If that applies to your situation, use the ruleset's Bypass list to specify which roles, teams, or GitHub Apps are allowed to bypass the rule rather than weakening it for everyone.

### Private Vulnerability Reporting

Without a private vulnerability disclosure channel, a researcher who finds a security bug in your public repository has two bad options: file a public issue (which announces the bug to the world before it is fixed) or give up and say nothing. Private vulnerability reporting gives them a third option: a private channel directly to you.

Open `https://github.com/<owner>/<repo>/settings/security_analysis`, find "Advanced Security", and enable "Private vulnerability reporting."

### Security Policy (SECURITY.md)

Even with private vulnerability reporting enabled, researchers need to know it exists. A `SECURITY.md` file at the root of your repository is the standard place to document how to responsibly disclose security issues. GitHub surfaces it automatically in the Security tab.

Open `https://github.com/<owner>/<repo>/security/policy` and click "Start setup." Edit the file to include a private disclosure channel. A minimal `SECURITY.md` looks like this:

```markdown
# Security Policy

**Please do not disclose security vulnerabilities publicly. See below for the private reporting channel.**

## Reporting a Vulnerability

If you discover a security vulnerability, please report it privately using one of the following channels:

1. **GitHub Private Vulnerability Reporting** (preferred): go to the repository's Security tab and click "Report a vulnerability."
2. **Email**: send the details to your@email.com.

All security vulnerabilities will be promptly addressed.
```

Commit the file directly to the default branch.

## Step 5: Verify the Fixes {#step-5-verify-fixes}

After applying all the changes above, re-run Moat with the same command:

```bash
moat <owner>/<repo>
```
For example, here we run the following command again in the terminal.
```
moat qadrLabs/belajar-kontribusi
```

The output should now look like this:

```
$ moat qadrLabs/belajar-kontribusi

╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│  ◈ Moat v1.0.4 · qadrLabs/belajar-kontribusi                                                             Repository  │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

╭─ Checks ─────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│                                                                                                                      │
│  ✓  PASS   Repositories actions workflow token is read only                                1/1 repositories passing  │
│                                                                                                                      │
│     Currently: workflow tokens are read-only across all 1 repository.                                                │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories secret scanning is enabled                                         1/1 repositories passing  │
│                                                                                                                      │
│     Currently: secret scanning is enabled on all 1 repository.                                                       │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories secret push protection is enabled                                  1/1 repositories passing  │
│                                                                                                                      │
│     Currently: secret push protection is enabled on all 1 repository.                                                │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories Dependabot alerts are enabled                                      1/1 repositories passing  │
│                                                                                                                      │
│     Currently: Dependabot alerts is enabled on all 1 repository.                                                     │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories Dependabot security updates are enabled                            1/1 repositories passing  │
│                                                                                                                      │
│     Currently: Dependabot security updates is enabled on all 1 repository.                                           │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories releases are immutable                                             1/1 repositories passing  │
│                                                                                                                      │
│     Currently: immutable releases are enabled on all 1 repository.                                                   │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories fork pull requests require approval                                1/1 repositories passing  │
│                                                                                                                      │
│     Currently: fork PR workflows require manual approval for all external contributors across all 1 public           │
│     repository.                                                                                                      │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories commits are signed                                                 1/1 repositories passing  │
│                                                                                                                      │
│     Currently: signed commits is enforced on release branches across all 1 repository.                               │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories pull requests require reviews                                      1/1 repositories passing  │
│                                                                                                                      │
│     Currently: the full pull-request review policy is enforced on release branches across all 1 repository.          │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories release branches are locked                                        1/1 repositories passing  │
│                                                                                                                      │
│     Currently: release branches are locked against force pushes and deletions across all 1 repository.               │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories release branches have linear history                               1/1 repositories passing  │
│                                                                                                                      │
│     Currently: linear history is enforced on release branches across all 1 repository.                               │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories webhooks are secure                                                1/1 repositories passing  │
│                                                                                                                      │
│     Currently: no repository webhooks across 1 repository.                                                           │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories private vulnerability reporting is enabled                         1/1 repositories passing  │
│                                                                                                                      │
│     Currently: private vulnerability reporting is enabled on all 1 public repository.                                │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  ✓  PASS   Repositories have security policy                                               1/1 repositories passing  │
│                                                                                                                      │
│     Currently: all 1 public repository publish a SECURITY.md disclosure policy.                                      │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  —  SKIPPED   Repositories workflow actions are pinned                                                               │
│                                                                                                                      │
│     Reason:                                                                                                          │
│     None of the repositories in scope had the data required for this check (for example, no workflows or no relevant │
│     configuration to evaluate).                                                                                      │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  —  SKIPPED   Repositories pull request target is safe                                                               │
│                                                                                                                      │
│     Reason:                                                                                                          │
│     None of the repositories in scope had the data required for this check (for example, no workflows or no relevant │
│     configuration to evaluate).                                                                                      │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  —  SKIPPED   Repositories workflow permissions are restricted                                                       │
│                                                                                                                      │
│     Reason:                                                                                                          │
│     None of the repositories in scope had the data required for this check (for example, no workflows or no relevant │
│     configuration to evaluate).                                                                                      │
│                                                                                                                      │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                      │
│  —  SKIPPED   Repositories have Dependabot config                                                                    │
│                                                                                                                      │
│     Reason:                                                                                                          │
│     None of the repositories in scope had the data required for this check (for example, no workflows or no relevant │
│     configuration to evaluate).                                                                                      │
│                                                                                                                      │
│                                                                                                                      │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

╭─ Security posture ───────────────────────────────────────────────────────────────────────────────────────────────────╮
│                                                                                                                      │
│   100% hardened                                                                                                      │
│   ████████████████████████████████████████████████████████████                                                       │
│                                                                                                                      │
│   ✓  14 passed    ✕  0 fails    !  0 warnings    —  4 skipped    ·  18 total                                         │
│                                                                                                                      │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
```

Fourteen checks pass, zero fail, and the four remaining skips are legitimate: the repository has no GitHub Actions workflows, so the workflow-specific checks (pinned actions, `pull_request_target` safety, workflow permissions, and Dependabot config for action pins) have no data to evaluate. When you add workflows later, those checks will activate automatically.

Once you see this output, remember to revoke your PAT at [github.com/settings/tokens](https://github.com/settings/tokens).

## Understanding Moat's Checks {#understanding-moats-checks}

Moat's checks fall into four broad categories, and understanding which category a check belongs to helps you predict what will trigger a FAIL versus a SKIPPED result.

**Repository-level checks** cover settings that apply to a single repository regardless of whether it belongs to an organization. These include secret scanning, Dependabot alerts, immutable releases, webhooks, branch rulesets (signed commits, PR reviews, branch lock, linear history), fork PR approval, private vulnerability reporting, and `SECURITY.md`. These are the checks you will encounter most often when auditing individual repositories.

**Workflow-level checks** require that the repository actually has GitHub Actions workflow files. Moat reads the `.github/workflows/*.yml` files to inspect them for unpinned `uses:` references, dangerous `pull_request_target` patterns, and missing `permissions:` declarations. If the repository has no workflows, all four of these checks will show `SKIPPED` with the reason "no workflows or no relevant configuration to evaluate." This is the expected state for repositories that do not use Actions.

**Organization-level checks** only run when you audit an entire organization (`moat <your-org>`) rather than a single repository. These include 2FA enforcement at the org level, default member permissions, and org-wide Actions token permissions. They require the `admin:org` scope, which is why you can omit that scope from your PAT when auditing a single repository.

**Plan-restricted checks** are features that GitHub only makes available on paid plans for private repositories. If your repository is private and on GitHub Free, Moat will mark several checks as `N/A (plan)` rather than `FAIL`. The affected checks are signed commits, PR review requirements, branch lock, linear history, secret scanning, and push protection. These features are available for all public repositories regardless of plan, which is one more reason to make your open-source repositories public rather than keeping them private on a free plan.

The distinction between `SKIPPED` and `FAIL` is important. A `FAIL` means Moat checked the setting and found it not configured as recommended. A `SKIPPED` means Moat could not evaluate the check at all, either because the necessary data does not exist (no workflows, no public repos), the feature is not available on your plan, or you explicitly disabled the check in `moat.toml`.

## Configuring moat.toml {#configuring-moat-toml}

Every check Moat runs is appropriate for most repositories, but some checks will not apply to every project. A solo personal project may not need required PR reviews because there are no other contributors. A repository that intentionally uses annotated tags rather than a release workflow may have a legitimate reason to skip the immutable releases check.

Moat looks for a `moat.toml` file at the root of each repository it audits. Any check disabled in this file renders as `SKIPPED` in the output rather than `FAIL`, and skipped checks do not count toward the failure total.

Create `moat.toml` at the root of your repository with content like this:

```toml
[checks]
repositories_commits_are_signed = "off"
repositories_pull_requests_require_reviews = "off"
```

Each key is the check ID from Moat's documentation. The value is `"on"` (the default) or `"off"`. Setting a check to `"off"` tells Moat that you have consciously decided this check does not apply to this repository. It does not mean the underlying security setting is enabled; it means Moat will stop reporting it as a failure.

The value of this approach is auditability. When you disable a check in `moat.toml`, the decision is committed to version control alongside the code it applies to. Anyone reviewing the repository can see which checks were intentionally skipped and why (if you add a comment above the entry). This is far more auditable than a "100% hardened" score that was achieved by running Moat with an insufficient token.

You can also declare additional release branches that Moat should treat as protected alongside the default branch:

```toml
release_branches = ["0.x", "1.x"]
```

This is useful if you maintain multiple active release lines, such as an older LTS branch alongside the current development branch. Moat will apply all branch-level checks to these additional branches in the same way it applies them to `main`.

## Conclusion {#conclusion}

Working through a Moat audit from scratch demonstrates that GitHub security is not a binary "secure or not secure" state. It is a collection of independent settings, each of which closes a specific attack surface. Moat's value is in making all of those settings visible at once rather than requiring you to know which settings page to check.

- **Moat is a read-only audit tool.** It surfaces recommendations based on GitHub's existing security settings and does not change anything automatically. Every suggested fix requires a deliberate action from you, which keeps the decision-making where it belongs.
- **Token scope determines what Moat can see.** A token with insufficient scope produces an all-SKIPPED output that looks like a perfect score. Always verify that your PAT has `repo` and `workflow` for repository audits, plus `admin:org` for organization audits.
- **SKIPPED is not the same as PASS.** A `SKIPPED` result means Moat had no data to evaluate. The four workflow checks skipping on a repository with no `.github/workflows/` files is correct behavior, not a problem. A `PASS` means Moat checked the setting and found it correctly configured.
- **Branch rulesets are the single highest-leverage change.** One ruleset covering your release branches can simultaneously enforce signed commits, required reviews, branch lock, and linear history. All four Moat checks in that category resolve together.
- **Revoke your PAT immediately after use.** The token required for Moat to do its work is powerful. A token sitting in shell history or a `.env` file is itself the kind of secret that Moat is trying to help you protect.
- **`moat.toml` makes exceptions auditable.** Disabling a check in `moat.toml` and committing that file to the repository creates a documented, version-controlled record of intentional exceptions rather than a silent gap.