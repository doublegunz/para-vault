---
title: "The axios npm Supply Chain Attack: How a Hijacked Maintainer Account Delivered a Cross-Platform RAT"
slug: "the-axios-npm-supply-chain-attack-how-a-hijacked-maintainer-account-delivered-a-cross-platform-rat"
category: "Security"
date: "2026-04-01"
status: "published"
---

You run `npm install axios` and your terminal prints a clean install log. No warnings, no errors, exit code 0. What you do not see is that within two seconds of that command, a background process has already dialed home to an attacker's server in a hidden curl request. This is exactly what happened on March 31, 2026, when two malicious releases of the most popular JavaScript HTTP client were live on npm for nearly three hours. If you or your CI/CD pipeline installed `axios@1.14.1` or `axios@0.30.4` during that window, your system should be treated as fully compromised.

This article breaks down the entire attack chain: how the maintainer account was taken over, how the malicious dependency was staged and injected, how the dropper worked on each platform, and what you need to do to check whether you were affected. Understanding this attack in detail is one of the best ways to build instincts for catching similar threats in the future.



## Overview {#overview}

### What You'll Learn

- How a supply chain attack is staged over multiple hours before the payload goes live
- Why a `postinstall` hook in a transitive npm dependency is enough to compromise any machine that runs `npm install`
- How to read npm registry metadata to detect unauthorized publishes
- How the dropper delivered a cross-platform remote access trojan (RAT) on macOS, Windows, and Linux
- How to verify whether your system or CI/CD pipeline was affected and what to do if it was

### What You'll Need

- Basic familiarity with npm and `package.json`
- A terminal with `npm` and `node` installed (for running the detection checks)
- Access to your CI/CD pipeline logs if you run automated builds



## What Was Compromised {#what-was-compromised}

axios is the most widely used JavaScript HTTP client library, with over 100 million weekly downloads and roughly 174,000 dependent npm packages. On March 31, 2026, an attacker hijacked the npm account of the primary axios maintainer (`jasonsaayman`) and published two malicious patch releases:

- `axios@1.14.1` (published 00:21 UTC, tagged as `latest`)
- `axios@0.30.4` (published 01:00 UTC)

Both versions were live for approximately three hours before npm removed them and reverted the `latest` tag back to `axios@1.14.0`.

Neither release contained any malicious code directly inside axios. Every source file in `axios@1.14.1` is bit-for-bit identical to `axios@1.14.0`. The only change in `package.json` was the addition of a single new dependency:

```json
"dependencies": {
  "follow-redirects": "^2.1.0",
  "form-data": "^4.0.1",
  "proxy-from-env": "^2.1.0",
  "plain-crypto-js": "^4.2.1"
}
```

`plain-crypto-js` is not imported anywhere in the axios source code. It is never `require()`'d in any of the 86 files in the package. Its sole purpose is to exist as a dependency so that npm automatically installs it, and npm then automatically runs its `postinstall` script.

There is also a third, subtle change: the `"prepare": "husky"` script entry was removed. `husky` manages git hook enforcement in the axios project. Its removal is a forensic signal that this release was published manually, bypassing the normal CI/CD workflow that would have re-added it.



## How the Account Was Taken Over {#how-the-account-was-taken-over}

Every legitimate axios 1.x release is published through GitHub Actions using npm's OIDC Trusted Publishing. This means the publish action is cryptographically tied to a verified GitHub Actions workflow and produces a `trustedPublisher` field in the npm registry metadata.

You can verify this by querying the npm registry API directly:

```bash
# Check who published a specific version of axios
curl -s https://registry.npmjs.org/axios | \
  node -e "
    const d = require('fs').readFileSync('/dev/stdin','utf8');
    const pkg = JSON.parse(d);
    console.log('1.14.0 publisher:', JSON.stringify(pkg.versions['1.14.0']._npmUser, null, 2));
  "
```

For `axios@1.14.0`, the `_npmUser` field in the registry metadata looks like this:

```json
{
  "name": "GitHub Actions",
  "email": "npm-oidc-no-reply@github.com",
  "trustedPublisher": {
    "id": "github",
    "oidcConfigId": "oidc:9061ef30-3132-49f4-b28c-9338d192a1a9"
  }
}
```

This tells us the release came from a GitHub Actions workflow with OIDC-bound credentials. Those credentials are ephemeral and scoped to the specific workflow run. They cannot be stolen or reused.

For `axios@1.14.1` (before npm removed it), the metadata looked like this:

```json
{
  "name": "jasonsaayman",
  "email": "ifstap@proton.me"
}
```

No `trustedPublisher`. No `gitHead`. No corresponding tag or commit in the GitHub repository. The attacker had obtained a long-lived classic npm access token for the account (the `v0.x` branch still used one, which had never been rotated) and changed the registered email address to an attacker-controlled ProtonMail address.

The maintainer confirmed that 2FA was enabled on the account and speculated that a recovery code may have been used to bypass it. The OIDC publishing path was only configured for `v1.x`, so the `v0.x` branch was fully exposed through the old token.

**What this teaches us:** An account having 2FA enabled does not guarantee it is secure if recovery codes are not stored safely, if long-lived tokens are still in use alongside OIDC-based workflows, or if those tokens are never rotated. The metadata pattern of a missing `trustedPublisher` on a package that normally uses trusted publishing is a meaningful anomaly signal.



## How the Malicious Dependency Was Staged {#how-the-malicious-dependency-was-staged}

The attacker did not publish `plain-crypto-js` at the same time as the axios releases. The staging happened over 18 hours:

| Timestamp (UTC) | Event |
|||
| Mar 30, 05:57 | `plain-crypto-js@4.2.0` published from `nrwise@proton.me`. Clean clone of `crypto-js@4.2.0`, no `postinstall`. Establishes publishing history so the account does not appear brand-new to scanners. |
| Mar 30, 23:59 | `plain-crypto-js@4.2.1` published. Malicious `postinstall` hook and obfuscated dropper added. |
| Mar 31, 00:21 | `axios@1.14.1` published with `plain-crypto-js@^4.2.1` as a dependency. |
| Mar 31, 01:00 | `axios@0.30.4` published with the same injection. |
| Mar 31, ~03:25 | npm removes the compromised axios versions and places a security hold on `plain-crypto-js`. |

Publishing the clean decoy version first is a deliberate tactic. Many security scanners flag packages from zero-history accounts. By publishing a legitimate-looking version first, the attacker gave `nrwise` a publishing record that would pass a surface-level inspection.

`plain-crypto-js` itself is a typosquat of `crypto-js`, the legitimate cryptography library. The package description, author name, homepage, and repository URL in its `package.json` all point to the real `crypto-js` project. The 56 cryptographic source files are bit-for-bit identical to `crypto-js@4.2.0`. The only difference between the malicious package and the real library is a single added field:

```json
"scripts": {
  "test": "grunt",
  "postinstall": "node setup.js"
}
```

That one line is the entire weapon.



## How the Dropper Works {#how-the-dropper-works}

When npm installs a package, it automatically runs the `postinstall` script defined in that package's `package.json`. Since `plain-crypto-js` is listed as a dependency of `axios@1.14.1`, installing axios triggers the full chain: npm installs `plain-crypto-js`, then runs `setup.js`.

`setup.js` hides all of its sensitive strings behind a two-layer obfuscation scheme. The outer layer (`_trans_2`) reverses a string, replaces `_` with `=`, and base64-decodes the result. The inner layer (`_trans_1`) applies a character-by-character XOR using digits derived from the key `"OrDeR_7077"` and the constant `333`.

Here is how the inner XOR cipher works:

```javascript
// Each character is decoded using this formula:
// decoded_char = char XOR key_digit XOR 333
//
// The key "OrDeR_7077" is parsed through Number().
// Alphabetic characters become NaN, which falls to 0 in bitwise XOR.
// Only the last four characters "7077" produce usable numbers.
// The effective key becomes [0,0,0,0,0,0,7,0,7,7].

function _trans_1(str, key) {
    const digits = key.split("").map(Number);
    let result = "";
    for (let i = 0; i < str.length; i++) {
        const d = digits[7 * i * i % 10] || 0;
        result += String.fromCharCode(str.charCodeAt(i) ^ d ^ 333);
    }
    return result;
}
```

This obfuscation is designed to evade static analysis tools that scan for known strings like C2 domain names or shell commands. A scanner looking for `"sfrclak.com"` in plain text would find nothing.

After deobfuscating all strings, the dropper detects the operating system and branches into platform-specific logic. The overall flow is:

1. Load Node.js built-ins (`fs`, `os`, `child_process`) using decoded module names from the obfuscated string table.
2. Construct the C2 URL by concatenating the decoded base URL with the campaign ID hardcoded as the entry point argument.
3. Call `os.platform()` to detect whether the system is macOS (`darwin`), Windows (`win32`), or anything else (treated as Linux).
4. Build a platform-specific shell command string that downloads and executes the second-stage payload.
5. Run the command with `execSync()`, which blocks until the shell process returns. Because all three platform commands immediately detach the payload to the background, `execSync` returns in milliseconds and npm finishes normally.
6. Perform anti-forensics cleanup: delete `setup.js` itself, delete the malicious `package.json`, and rename the pre-staged clean stub (`package.md`) to `package.json`.

Three things about this design are worth understanding:

**Silent failure.** The entire function is wrapped in a `try/catch` with an empty handler. If the C2 server is unreachable, if a permission check fails, if anything goes wrong, the dropper exits silently and `npm install` completes with exit code `0`. There is no error output, no warning, nothing in your terminal to suggest anything went wrong.

**Immediate detachment.** `execSync` is a blocking call, but all three platform commands use background execution (`nohup ... &` on Linux and macOS, `cscript ... 0, False` on Windows). The dropper returns almost instantly and npm finishes normally. The payload continues running in the background, detached from the npm process tree and re-parented to PID 1 (`init`).

**Evidence destruction.** After launching the payload, the dropper deletes `setup.js`, deletes the malicious `package.json`, and renames `package.md` (a pre-staged clean stub) to `package.json`. The clean stub reports version `4.2.0` and contains no `scripts` entry. After this swap, running `npm list` shows `plain-crypto-js@4.2.0`, not `4.2.1`. An incident responder checking for the malicious version number would find no match.



## Platform-Specific Payloads {#platform-specific-payloads}

Each platform receives a different second-stage payload delivered from the same C2 endpoint. The POST body sent with each request identifies the platform: `packages.npm.org/product0` for macOS, `packages.npm.org/product1` for Windows, and `packages.npm.org/product2` for Linux. The `packages.npm.org/` prefix is designed to look like legitimate npm registry traffic in network logs.

### macOS

The dropper writes a temporary AppleScript file to the system temp directory and executes it silently via `nohup osascript`. The AppleScript does three things in sequence: it sends a POST request to the C2 server to download a Mach-O binary, saves the binary to `/Library/Caches/com.apple.act.mond`, makes it executable with `chmod 770`, and launches it via `/bin/zsh` in the background. The AppleScript then deletes itself.

The Mach-O binary is a universal build (x86_64 + arm64) compiled with Xcode. It saves to `/Library/Caches/com.apple.act.mond`. The name mimics Apple's reverse-DNS daemon naming convention, intended to blend with legitimate system processes in a process list. The binary is compiled with Xcode and implements the same C2 protocol as the Linux Python payload, including the same commands and system enumeration logic. Build artifacts leaked in the binary reveal the attacker's development path: `/Users/mac/Desktop/Jain_DEV/client_mac/macWebT/`.

### Windows

The dropper first locates the PowerShell binary using `where powershell`, then copies it to `%PROGRAMDATA%\wt.exe` to mimic Windows Terminal. It then writes a VBScript file to the temp directory and executes it via `cscript //nologo` in a hidden window. The VBScript performs the following steps in a single hidden `cmd.exe` invocation: it downloads a PowerShell script from the C2 server to `%TEMP%\6202033.ps1`, executes that script with `-WindowStyle Hidden` and `-ExecutionPolicy Bypass` using the renamed PowerShell binary, then deletes the `.ps1` file. The VBScript also deletes itself after execution. The Windows variant is the only one with built-in persistence: the PowerShell script writes `%PROGRAMDATA%\system.bat` (a one-liner that re-fetches the payload) and registers it under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\MicrosoftUpdate`. This means the payload re-downloads and re-executes on every user login, even after the initial infection is cleaned up.

Note: Researchers found that the PowerShell script defines a `work()` function containing the full RAT implementation but never calls it. On first execution, the attacker gets persistence but no active C2 session. This appears to be an incomplete implementation or a bug in the final payload.

### Linux

### Linux

On Linux and all other non-macOS, non-Windows platforms, the dropper runs a two-part shell command chained with `&&`. The first part uses curl to download a Python script from the C2 server and save it to `/tmp/ld.py`, sending a platform-identifying POST body so the server knows which payload to return. The second part launches that Python script in the background via `nohup`, fully detached from the npm process tree.

The `&&` chain serves as a liveness check: if curl cannot reach the C2 server, the Python script is never executed and npm finishes cleanly with no visible error. The Python script implements the full RAT beacon loop, but researchers found a bug: `get_user_name()` calls `os.getlogin()`, which requires a TTY attached to stdin. In containers, CI environments, and background services (common places where `npm install` runs), there is no TTY and the call throws `FileNotFoundError`. The `pwd` module, which provides a portable alternative, was imported but never used.

There is also a second bug in the binary execution handler: it references an undefined variable `b64_string` instead of its parameter `ijtbin`, so even on systems where the beacon loop does run, the C2 cannot deliver binary payloads via the `peinject` command.



## Checking If You Are Affected {#checking-if-you-are-affected}

Run these checks on any system or CI environment that may have run `npm install` between 00:21 UTC and 03:25 UTC on March 31, 2026.

**Check 1: Look for the malicious axios versions**

```bash
npm list axios 2>/dev/null | grep -E "1\.14\.1|0\.30\.4"
grep -A1 '"axios"' package-lock.json | grep -E "1\.14\.1|0\.30\.4"
```

If either command returns output, the malicious version was installed.

**Check 2: Look for the `plain-crypto-js` directory**

```bash
ls node_modules/plain-crypto-js 2>/dev/null && echo "POTENTIALLY AFFECTED"
```

This directory should not exist in any legitimate project that uses axios. Its presence alone is sufficient evidence that the dropper ran, even if `setup.js` has already deleted itself and replaced `package.json` with the clean stub.

**Check 3: Look for platform-specific RAT artifacts**

```bash
# macOS: check for the downloaded binary
ls -la /Library/Caches/com.apple.act.mond 2>/dev/null && echo "COMPROMISED"

# Linux: check for the downloaded Python payload
ls -la /tmp/ld.py 2>/dev/null && echo "COMPROMISED"

# Windows (run in cmd.exe): check for the persistent PowerShell copy
dir "%PROGRAMDATA%\wt.exe" 2>nul && echo COMPROMISED
```

**Check 4: Check CI/CD pipeline logs**

Search your pipeline logs for any `npm install` step that ran during the affected window. Look for outbound connections to `sfrclak.com` or `142.11.206.73:8000` in your network logs or firewall rules.



## Remediation {#remediation}

**Do not attempt to clean a compromised system in place.** If a RAT artifact is found, rebuild from a known-good image and rotate all credentials.

**For all affected systems, rotate:**

- npm access tokens
- AWS access keys and IAM credentials
- GCP and Azure service account credentials
- SSH private keys
- CI/CD secrets (GitHub Actions secrets, environment variables, vault tokens)
- Any credentials stored in `.env` files that were accessible at install time

**For projects, downgrade axios and pin the version:**

```bash
# For 1.x users
npm install axios@1.14.0

# For 0.x users
npm install axios@0.30.3
```

Add an `overrides` block to `package.json` to prevent transitive resolution back to the malicious versions:

```json
{
  "dependencies": { "axios": "1.14.0" },
  "overrides": { "axios": "1.14.0" },
  "resolutions": { "axios": "1.14.0" }
}
```

Remove `plain-crypto-js` from `node_modules` and reinstall without running scripts:

```bash
rm -rf node_modules/plain-crypto-js
npm install --ignore-scripts
```

As an additional precaution on any potentially exposed system, block outbound traffic to the C2 domain and IP at the firewall or DNS level. On Linux this can be done via `iptables` by dropping outbound traffic to the attacker's IP. On macOS and Linux, adding a null-route entry for the C2 domain in `/etc/hosts` is a quick host-level block. On managed environments, apply the block through your existing firewall policy or DNS filtering tool using the network indicators listed in the IOC Reference section below.



## Indicators of Compromise (IOC) Reference {#ioc-reference}

### Malicious npm Packages

| Package | Version | Shasum |
||||
| `axios` | 1.14.1 | `2553649f232204966871cea80a5d0d6adc700ca` |
| `axios` | 0.30.4 | `d6f3f62fd3b9f5432f5782b62d8cfd5247d5ee71` |
| `plain-crypto-js` | 4.2.1 | `07d889e2dadce6f3910dcbc253317d28ca61c766` |

### Network Indicators

| Indicator | Type | Notes |
||||
| `sfrclak.com` | Domain | C2 server, registered 2026-03-30 via Namecheap |
| `142.11.206.73` | IPv4 | A record for `sfrclak.com` (Hostwinds) |
| `http://sfrclak.com:8000/6202033` | URL | Stage 2 download and C2 beacon endpoint |
| `mozilla/4.0 (compatible; msie 8.0; windows nt 5.1; trident/4.0)` | User-Agent | Hardcoded in all RAT variants |

### File System Artifacts

| OS | Path | Description |
||||
| macOS | `/Library/Caches/com.apple.act.mond` | Downloaded binary, disguised as Apple daemon |
| macOS | `$TMPDIR/6202033` | AppleScript dropper, self-deletes |
| Windows | `%PROGRAMDATA%\wt.exe` | Persistent copy of PowerShell |
| Windows | `%PROGRAMDATA%\system.bat` | Persistence script, re-fetches payload on login |
| Windows | `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\MicrosoftUpdate` | Registry Run key for persistence |
| Linux | `/tmp/ld.py` | Downloaded Python RAT payload |

### Safe Version Reference

| Package | Safe Version | Shasum |
||||
| `axios` | 1.14.0 | `7c29f4cf2ea91ef05018d5aa5399bf23ed3120eb` |



## How This Attack Compares to Past Supply Chain Incidents {#attack-context}

This incident fits a well-established pattern in npm supply chain attacks, but with a higher level of operational sophistication than most.

The use of a `postinstall` hook to execute arbitrary code on install is not new. npm provides no sandboxing for install scripts by default. Any package in your dependency tree, no matter how far down the transitive chain, can run arbitrary code on your machine during `npm install`. The attack surface has always existed. What changed here was the target: rather than publishing a new malicious package and hoping developers would install it, the attacker hijacked an account that controls a package with over 100 million weekly downloads.

The 18-hour pre-staging window is noteworthy. Staging the malicious dependency before the main event, and using a clean decoy version to build publishing history, shows a threat actor that understood how security scanners work and planned around them. The fake npm POST body (`packages.npm.org/product0`) designed to mimic legitimate registry traffic in network logs shows similar awareness of detection mechanisms.

The RAT's bugs (the `os.getlogin()` crash on Linux, the uncalled `work()` function on Windows) do not diminish the significance of the attack. The C2 was live, the dropper was executing, and directory listing data was being exfiltrated via the `FirstInfo` beacon on affected Linux systems before the crash. On Windows, the persistence mechanism was being installed. Developers and CI systems that ran `npm install` in the exposure window should not draw comfort from the bugs.

The incident also highlights how trusting the OIDC trusted publishing pattern is as a signal. Every legitimate recent axios 1.x release has a `trustedPublisher` field in its npm registry metadata. The absence of that field for `1.14.1` was a detectable anomaly. Tooling that monitors publishing metadata for this pattern could have flagged the release within seconds of it appearing.



## Conclusion {#conclusion}

This attack is a case study in how a single compromised maintainer account can become a vector for compromising any machine that runs `npm install` with a popular package. Here are the key takeaways:

- **The malicious code was zero lines inside axios itself.** The entire attack ran through a transitive dependency, `plain-crypto-js`, added as a phantom dependency that was never imported by any axios code. A dependency that exists in `package.json` but has zero `require()` calls in the source is a high-confidence indicator of a compromised release.
- **`postinstall` scripts run automatically and silently.** npm gives packages in your dependency tree the ability to run arbitrary code on your machine. Unless you use `npm ci --ignore-scripts`, this happens without prompting on every install.
- **The dropper cleaned up after itself.** After executing, `setup.js` deleted itself, deleted the malicious `package.json`, and replaced it with a clean stub. Running `npm list` after the fact would show `plain-crypto-js@4.2.0` with no scripts entry. The only reliable post-infection artifact is the presence of the `node_modules/plain-crypto-js/` directory itself.
- **The `trustedPublisher` field is a meaningful signal.** If a package that previously used OIDC trusted publishing suddenly has a release without a `trustedPublisher` field, and especially if the publisher email changed, that is a significant anomaly worth investigating.
- **2FA alone is not sufficient if long-lived tokens exist alongside it.** The attacker bypassed 2FA (possibly via a recovery code) and used a long-lived npm access token that had never been rotated. OIDC trusted publishing eliminates long-lived token exposure for packages with a CI/CD pipeline.
- **Recovery steps must include credential rotation.** If the dropper ran on your system, it exfiltrated directory listings and could have accessed any credential stored in files accessible at install time. Treat every secret on the affected system as compromised.
- **Add `--ignore-scripts` to your CI/CD pipeline as a standing policy.** Running `npm ci --ignore-scripts` prevents `postinstall` hooks from executing during automated builds. For packages that require legitimate install scripts, allowlist them explicitly rather than allowing all scripts to run.



*Sources: Datadog Security Labs (March 31, 2026) and StepSecurity (March 30, 2026). IOCs and payload hashes sourced from both reports and independently crosschecked.*