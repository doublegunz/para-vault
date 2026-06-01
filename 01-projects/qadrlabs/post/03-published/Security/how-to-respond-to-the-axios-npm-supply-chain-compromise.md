---
title: "How To Respond To The axios npm Supply Chain Compromise"
slug: "how-to-respond-to-the-axios-npm-supply-chain-compromise"
category: "Security"
date: "2026-04-01"
status: "published"
---

You probably installed axios in dozens of projects and never thought twice about it.
When a core dependency like that turns malicious, your entire stack can become a pivot point for attackers with a single `npm install`.
In late March 2026, a compromised maintainer account published backdoored axios versions that silently dropped a cross platform remote access trojan (RAT) on developer machines and CI runners.
This tutorial walks you through what actually happened, how to check if your projects were affected, and how to harden your JavaScript supply chain so the next incident hits a brick wall instead of your production systems.

> Important: Do not install `axios@1.14.1` or `axios@0.30.4`. Both versions were published from a compromised maintainer account and pull in a malicious `plain-crypto-js@4.2.1` dependency that drops a cross platform remote access trojan during `npm install`.

## Overview {#overview}

### What You will Build

- A repeatable playbook to detect and respond to the axios npm compromise in your own projects
- A minimal axios project wired with safer dependency practices, including version pinning and install hardening

### What You will Learn

- How the axios compromise worked at a high level and why it was so stealthy
- How to scan your codebase, lockfiles, and node_modules for malicious axios versions and the `plain-crypto-js` dropper
- How to downgrade safely, clean up artifacts, and rotate secrets if you find signs of compromise
- How to improve your npm hygiene with overrides, lockfiles, and `--ignore-scripts` so similar attacks are much harder to pull off

### What You will Need

- Node.js and npm installed locally
- A terminal you are comfortable using
- One or more JavaScript or TypeScript projects that depend on axios

## Step 1: Understand what was compromised {#step-1-understand-what-was-compromised}

Before you change anything, you need a clear mental model of what went wrong.
In this incident, the attacker hijacked an axios maintainer npm account and used it to publish two malicious versions:

```text
axios@1.14.1
axios@0.30.4
```

Those releases added a new dependency called `plain-crypto-js@4.2.1`, which is a near perfect clone of the legitimate `crypto-js@4.2.0` package but with a `postinstall` script that runs `node setup.js`.
That `postinstall` script acted as a dropper: on install it contacted a command and control server at `http://sfrclak.com:8000/6202033`, downloaded a platform specific RAT, executed it in the background, then deleted its own traces from `node_modules` and replaced its `package.json` with a clean decoy.

From a defender point of view, the important outcomes are:

- If your environment installed `axios@1.14.1` or `axios@0.30.4`, you must treat that machine or CI runner as compromised unless you can conclusively prove otherwise
- The presence of a `node_modules/plain-crypto-js` directory is itself a strong indicator the dropper ran, even if `package.json` in that folder looks harmless

## Step 2: Create a minimal axios project (safe version) {#step-2-create-a-minimal-axios-project-safe-version}

For the practical parts of this tutorial, you will work with a deliberately simple project that uses a safe axios version.
This lets you experiment with the mitigation techniques without risking real applications.

Create a fresh folder and initialize a Node.js project:

```bash
mkdir axios-supply-chain-lab
cd axios-supply-chain-lab
npm init -y
```

Install a known good axios version explicitly instead of relying on `latest`:

```bash
npm install axios@1.14.0
```

This command pins axios to a version that was published via GitHub Actions with npm trusted publishing and that does not include the malicious dependency.
Pinning an exact version reduces the chance that a silent patch release flips your supply chain without any code changes on your side.

Create a tiny script that uses axios so you can confirm everything works:

```js
// index.js
import axios from "axios";

async function main() {
  const response = await axios.get("https://httpbin.org/json");
  console.log("Status:", response.status);
  console.log("Title:", response.data.slideshow.title);
}

main().catch((err) => {
  console.error("Request failed:", err.message);
  process.exit(1);
});
```

Run the script:

```bash
node index.js
```

You should see a `200` status and a title from the JSON payload, which confirms that axios works correctly and no extra dependencies are involved.

## Step 3: Detect malicious axios versions in your projects {#step-3-detect-malicious-axios-versions-in-your-projects}

Next you will learn how to scan a real codebase for the specific compromised versions.
You will use `npm list` and your lockfile to avoid relying on what you think you installed.

From the root of a project that uses axios, run:

```bash
npm list axios 2>/dev/null | grep -E "1\.14\.1|0\.30\.4"
```

This command asks npm to print the full dependency tree for axios and then uses `grep` to search for the malicious versions.
If there is any output, somewhere in your dependency graph you have `axios@1.14.1` or `axios@0.30.4` installed.

Lockfiles can pin versions even when your `package.json` specifies a range.
To search your `package-lock.json` for the same versions, run:

```bash
grep -A1 '\"axios\"' package-lock.json | grep -E "1\.14\.1|0\.30\.4"
```

This pipeline finds axios entries in the lockfile and prints the adjacent lines, which usually include the concrete version.
If you see `1.14.1` or `0.30.4` here, your project resolved to a compromised version at least once.

If your project resolves to `axios@1.14.1` or `axios@0.30.4`, treat that environment as at least potentially compromised. Do not reinstall those versions to "test" the behavior. Instead, move directly to downgrading to a known good release, cleaning dependencies, and rebuilding the system from a trusted baseline.

## Step 4: Detect the plain-crypto-js dropper {#step-4-detect-the-plain-crypto-js-dropper}

Because the attack used a phantom dependency that is never imported in code, you need to look directly into `node_modules` to find it.
From your project root, run:

```bash
ls node_modules/plain-crypto-js 2>/dev/null && echo "POTENTIALLY AFFECTED"
```

If this command prints `POTENTIALLY AFFECTED`, you know that `plain-crypto-js` was installed in this environment at some point.
Even if `node_modules/plain-crypto-js/package.json` shows version `4.2.0` and no `postinstall` script, recall that the dropper replaces its own manifest with a clean stub after execution.

For systems you consider sensitive, treat the bare existence of this folder as enough justification to assume compromise and move on to containment and recovery.
At a minimum, you should plan to rebuild the machine or container image from a trusted baseline instead of trying to surgically clean it.

## Step 5: Check for RAT artifacts on each platform {#step-5-check-for-rat-artifacts-on-each-platform}

If you confirm that malicious axios versions or `plain-crypto-js` were present, the next step is to look for concrete artifacts from the second stage payloads.
The attacker used different file paths on macOS, Windows, and Linux, which gives you clear indicators to search for.

On macOS, run:

```bash
ls -la /Library/Caches/com.apple.act.mond 2>/dev/null && echo "COMPROMISED"
```

On Linux, run:

```bash
ls -la /tmp/ld.py 2>/dev/null && echo "COMPROMISED"
```

On Windows, from `cmd.exe`, run:

```bat
dir "%PROGRAMDATA%\wt.exe" 2>nul && echo COMPROMISED
```

These commands check for the specific payload locations that the dropper uses for each platform.
If any of them prints `COMPROMISED`, you should assume that host established a connection to the attacker and that secrets may have been exfiltrated.

## Step 6: Downgrade axios and pin safe versions {#step-6-downgrade-axios-and-pin-safe-versions}

Once you have an assessment of impact, you need to force all your projects off the malicious versions.
This starts with downgrading axios to a known good version and pinning it so new installs cannot float back to a bad release.

In projects that use axios 1.x, run:

```bash
npm install axios@1.14.0
```

In projects that use axios 0.x, run:

```bash
npm install axios@0.30.3
```

These commands both update your `package.json` and refresh `node_modules` for the current project.
If you have multiple services in a monorepo, repeat the downgrade in each package that declares axios as a dependency.

To prevent transitive dependencies from reintroducing the compromised versions, add overrides or resolutions at the root of your project configuration.
For npm you can use an `overrides` field, and for Yarn you can use `resolutions`.
Here is a combined example in `package.json` for npm v8+ that also plays well with Yarn in polyrepo setups:

```json
{
  "dependencies": {
    "axios": "1.14.0"
  },
  "overrides": {
    "axios": "1.14.0"
  },
  "resolutions": {
    "axios": "1.14.0"
  }
}
```

This configuration tells your package manager to force axios to `1.14.0` regardless of what any transitive dependency requests.
It also reduces the chance that a nested dependency will silently float back to `1.14.1` or `0.30.4` in environments where the malicious versions remain cached.

## Step 7: Remove plain-crypto-js and reinstall dependencies safely {#step-7-remove-plain-crypto-js-and-reinstall-dependencies-safely}

With axios pinned, you can clean up the dropper package if it is present and reinstall dependencies with scripts disabled.
This reduces the risk that other malicious packages with `postinstall` hooks will run during your recovery.

From your project root, remove the folder manually:

```bash
rm -rf node_modules/plain-crypto-js
```

Then reinstall dependencies without running lifecycle scripts:

```bash
npm install --ignore-scripts
```

The first command removes any remaining code from the `plain-crypto-js` package in your local `node_modules`.
The second command tells npm to install everything according to your lockfile and `package.json` but to skip `preinstall`, `postinstall`, and related hooks, which is particularly important when you are recovering from a package level compromise.

In CI, prefer `npm ci` with the same flag, so reproducible installs never execute untrusted scripts during automated builds:

```bash
npm ci --ignore-scripts
```

This pattern trades a bit of convenience for a significant reduction in attack surface for your pipelines.

## Step 8: Rotate secrets and rebuild compromised systems {#step-8-rotate-secrets-and-rebuild-compromised-systems}

If you found concrete indicators of compromise, or you installed the malicious versions on any machine that held sensitive secrets, you need to proceed as if an attacker had full interactive access.
The safest response is to rebuild and rotate instead of trying to clean.

At minimum, plan to rebuild the following from known good images or fresh operating system installs:

- Developer workstations where `npm install axios@1.14.1` or `axios@0.30.4` ran
- CI runners or build agents that installed those versions
- Long lived servers or containers where those versions were present in `node_modules`

As part of that rebuild, rotate any credentials that might have been accessible during the window of exposure.
Focus on:

- npm access tokens and organization tokens
- Cloud keys and tokens (AWS, GCP, Azure, and others)
- SSH private keys stored on developer machines
- Application secrets from `.env` files or secret managers that a RAT could reach

Treat this like an incident response exercise where supply chain compromise is the initial access vector.
Even if the second stage payloads were buggy on some platforms, you should not rely on attacker mistakes for your risk model.

## Step 9: Add guardrails for future npm installs {#step-9-add-guardrails-for-future-npm-installs}

Responding to this incident is only half the value of this tutorial.
The other half is learning how to adjust your defaults so similar attacks are harder to pull off in the first place.

Here are practical guardrails you can start adding today.

### Prefer `npm ci` and lockfiles in CI

In CI, prefer `npm ci` over `npm install` so your builds always use the exact versions in your lockfile.
Combine it with `--ignore-scripts` where possible:

```bash
npm ci --ignore-scripts
```

This approach ensures that automated builds are deterministic and that `postinstall` hooks from newly compromised packages do not run in your pipelines.
Where you cannot disable scripts entirely, make sure the runner network egress is locked down so unknown domains like `sfrclak.com` cannot be reached.

### Enforce version pinning and overrides

Use exact versions in `package.json` for critical dependencies like HTTP clients, ORM libraries, and frameworks.
For axios, prefer `"axios": "1.14.0"` over a range like `^1.14.0`, then back that up with `overrides` as shown earlier.

In monorepos, centralize these rules in a top level configuration so every package inherits the same pins.
That way you can adjust your exposure with a single change instead of chasing dozens of independent `package.json` files.

### Monitor for strange dependencies and network calls

Make it part of your review culture to scan diffs for new dependencies that are not referenced in code.
A dependency that only appears in `package.json` and is never imported is suspicious by default.

On the runtime side, monitor for outbound network calls from build agents and developer machines to domains that do not belong to your vendors or your own infrastructure.
In the axios incident, early detections came from tools that flagged unexpected traffic to `sfrclak.com:8000` shortly after `npm install` started.
Even simple allowlists and DNS logging can help you catch similar behavior.

## Testing your mitigations: try it out {#testing-your-mitigations-try-it-out}

To make these practices concrete, go back to the small lab project you created earlier and run through a short checklist.
You will not install the malicious versions, but you will exercise the detection and hardening steps.

From the `axios-supply-chain-lab` folder:

1. Run `npm list axios` and confirm it shows `1.14.0`.
2. Search `package-lock.json` to confirm there is no reference to `1.14.1` or `0.30.4`.
3. Confirm that `ls node_modules/plain-crypto-js` fails and does not print `POTENTIALLY AFFECTED`.
4. Add the `overrides` and `resolutions` block from Step 6 and run `npm install`.
5. Verify that axios is still at `1.14.0` and no new dependencies were added.
6. Run `npm ci --ignore-scripts` and confirm your project still builds and runs.

By the time you finish this checklist, you will have a reproducible pattern you can apply to production codebases with much higher confidence.

## Reference: High level attack chain {#reference-high-level-attack-chain}

This section summarizes the attack at a high level so you can reference it later without re reading the full analysis.
It is not a replacement for formal threat reports, but it gives you the main moving parts in one place.

- Attacker compromises an axios maintainer npm account
- Attacker publishes `axios@1.14.1` and `axios@0.30.4` with a new dependency `plain-crypto-js@4.2.1`
- `plain-crypto-js@4.2.1` is a clone of `crypto-js@4.2.0` with a `postinstall` hook that runs `node setup.js`
- `setup.js` contacts `http://sfrclak.com:8000/6202033`, downloads a RAT for macOS, Windows, or Linux, and executes it in the background
- `setup.js` deletes itself and swaps its malicious `package.json` with a clean `package.md` stub to hide evidence
- The RAT sends system info and directory listings to the C2 and can receive commands to run scripts or drop binaries
- On Windows, the attack also installs a persistence mechanism via `%PROGRAMDATA%\wt.exe` and a `MicrosoftUpdate` Run key

When you explain this to your team, try to emphasize how small the code diff was and how much impact it had.
The only meaningful change inside axios was a single new dependency in `package.json`.

## Reference: Indicators you can search for {#reference-indicators-you-can-search-for}

For convenience, here is a shortened list of indicators you can plug into your own inventory, logging, or EDR tools.
Use these as starting points for hunts in your environment.

**Packages and versions**

- `axios@1.14.1`
- `axios@0.30.4`
- `plain-crypto-js@4.2.1`

**File system paths**

- macOS: `/Library/Caches/com.apple.act.mond`
- Windows: `%PROGRAMDATA%\wt.exe`
- Linux: `/tmp/ld.py`

**Network indicators**

- Domain: `sfrclak.com`
- Port: `8000`
- URL: `http://sfrclak.com:8000/6202033`

When you add these indicators to your searches, remember that they are specific to this campaign.
You should combine them with more general patterns, such as unexpected `curl` executions during `npm install`, to catch the next variation that will certainly look slightly different.

## Conclusion {#conclusion}

- A single malicious `postinstall` hook in a transitive dependency was enough to turn a top npm package into a RAT dropper
- You can detect exposure by looking for specific axios versions, `plain-crypto-js`, and platform specific payload files on disk
- Safe recovery means downgrading, cleaning dependencies, rebuilding systems from known good images, and rotating all reachable secrets
- Stronger defaults like version pinning, `npm ci`, `--ignore-scripts`, and network egress controls make similar supply chain attacks much less effective
- Treat supply chain incidents as full security events rather than simple dependency upgrades and rehearse your response before the next one hits