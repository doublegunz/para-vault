---
title: "What's New in Ubuntu 26.04 LTS \"Resolute Raccoon\""
slug: "whats-new-in-ubuntu-2604-lts-resolute-raccoon"
category: "Ubuntu"
date: "2026-04-24"
status: "published"
---

Ubuntu 26.04 LTS, codenamed "Resolute Raccoon", was released on April 23, 2026, and it is the first Long-Term Support release since Ubuntu 24.04 LTS. Canonical will support it with security and maintenance updates until April 2031, with an additional five years of Extended Security Maintenance (ESM) available through Ubuntu Pro. This release ships more substantial changes than a typical LTS cycle, including a new kernel major version, a Wayland-only desktop, mandatory cgroup v2, and updated server and developer tooling across the board. Whether you are running Ubuntu on a workstation, a server, or inside containers, understanding what changed in 26.04 will help you plan your upgrade with confidence.

## Overview {#overview}

This article walks through every major change in Ubuntu 26.04 LTS from the developer's perspective, covering the desktop, kernel, server stack, and breaking changes you need to be aware of before upgrading.

### What You'll Learn

- What is new in the Linux kernel 7.0 shipped with Ubuntu 26.04
- How the GNOME 50 Wayland-only desktop affects developers and GUI tooling
- Why cgroup v2 is now mandatory and what that means for Docker and container workloads
- What changed in PHP 8.5, PostgreSQL 18, Python 3.13, and other key developer tools
- Which breaking changes could affect your scripts, automation, or container images
- How to check readiness and perform an upgrade from Ubuntu 24.04 LTS

### What You'll Need

- Familiarity with Ubuntu or any Debian-based Linux distribution
- Basic comfort with the terminal and package management via `apt`
- (Optional) A running Ubuntu 24.04 LTS instance if you intend to follow the upgrade section

## Release Snapshot {#release-snapshot}

Ubuntu 26.04 LTS shipped on April 23, 2026, marking the second LTS release in the Noble-to-Resolute cycle. The support timeline gives you five years of standard updates, with Ubuntu Pro extending that to ten years through ESM. The first point release, **26.04.1**, is scheduled for August 6, 2026, and that is when the stable do-release-upgrade path from Ubuntu 24.04 LTS will become officially available.

| Milestone                        | Date           |
| -------------------------------- | -------------- |
| Ubuntu 26.04 LTS release         | April 23, 2026 |
| Point release 26.04.1            | August 6, 2026 |
| Upgrade from 24.04 LTS available | August 6, 2026 |
| Standard support end             | April 2031     |
| ESM end (Ubuntu Pro)             | April 2036     |

## Linux Kernel 7.0 {#linux-kernel-7}

Ubuntu 26.04 ships with Linux kernel 7.0, the first major kernel version bump in years. The upstream kernel team concluded the long-running Rust-in-kernel experiment and declared it stable; Rust support in the kernel is no longer flagged as experimental. This has direct implications for the security and reliability of kernel drivers written in Rust going forward.

Hardware support has been extended to include Intel Core Ultra Series 3 processors (codenamed Panther Lake), with targeted optimizations for Intel Xe3 integrated graphics and the onboard Neural Processing Unit. The `cgroupfs` is now mounted with `nsdelegate`, `memory_recursiveprot`, and `memory_hugetlb_accounting` by default.

Two highlights that benefit server and real-time workloads stand out. First, the real-time Linux kernel (`PREEMPT_RT`) is now available in the main Ubuntu archive for free, without requiring an Ubuntu Pro subscription, following its upstreaming into mainline. Second, Kernel Livepatch now supports the ARM64 architecture in addition to AMD64. ZFS has also been updated to version 2.4.1.

## Desktop: GNOME 50 and Wayland-Only {#gnome-50-wayland}

Ubuntu 26.04 ships with GNOME 50 as the default desktop environment. The most significant architectural change is that the X11 session has been removed entirely. Wayland is now the only native desktop session. XWayland remains available, so applications that have not yet been ported to Wayland natively will still run, but they do so through the XWayland compatibility layer rather than a native X11 session.

GNOME 50 also brings a notable list of refinements: Variable Refresh Rate (VRR) and Fractional Scaling have been improved, color management has been updated to the latest Wayland standard, the GNOME remote desktop solution gains hardware acceleration and a more stable NVIDIA experience, and a new Reduced Motion option lets users minimize interface animations for accessibility or preference.

### New Default Applications

Several default applications have been swapped out in this release:

- **Resources** replaces both the System Monitor app and the Power Statistics app. Written in Rust, it groups processes into apps, tracks GPU and NPU usage, and monitors hardware clock frequencies using a GTK 4 interface.
- **Ptyxis** is the default terminal, and it now ships a new Ubuntu color palette with accessible contrast ratios and a light theme variant.
- **Yaru** icon theme has been refreshed to move closer to the upstream GNOME theme aesthetic.
- **Snap integration** has been improved: snap apps using XDG Desktop Portals now support camera, notification, USB, and file access portals in a more natural way, with portal permissions controllable from GNOME Settings.

### What This Means for Developers

If you run GUI-based test pipelines or Electron applications, your apps will run via XWayland when they lack native Wayland support. This is generally transparent, but some edge cases around clipboard handling or screen capture may behave differently. Remote desktop via GNOME now supports hardware acceleration, which benefits developers working over remote sessions. The removal of `PreLogin` and `PostSession` GDM scripts as part of the X11 cleanup means corporate environments that relied on them will need to migrate that logic to PAM modules.

## cgroup v2 Is Now Mandatory {#cgroup-v2-mandatory}

This is the single most impactful breaking change for DevOps and container workloads in Ubuntu 26.04. `systemd` version 259, which ships with this release, has dropped support for cgroup v1 (`legacy` and `hybrid` hierarchies) entirely. Three direct consequences follow from this:

- Ubuntu installations currently running cgroup v1 will be **blocked** from upgrading to 26.04.
- Ubuntu 26.04 container workloads will not run on a **host** that has booted with cgroup v1.
- Ubuntu 26.04 hosts do not support container images older than Ubuntu 18.04 LTS, since those images require cgroup v1.

### How to Check Your cgroup Version

Before upgrading, verify which cgroup version your system is currently using:

```bash
cat /sys/fs/cgroup/cgroup.controllers
```

If the file exists and contains output like `cpuset cpu io memory hugetlb pids rdma misc`, your system is already on cgroup v2. If the command returns no output or the file does not exist, you are still on cgroup v1 and you will need to address this before upgrading.

### Migrating Docker Workloads to cgroup v2

Docker has supported cgroup v2 since Docker 20.10, so most modern setups will work without changes. However, it is worth verifying your daemon configuration explicitly. Open or create `/etc/docker/daemon.json` and confirm there is no setting forcing cgroup v1:

```json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```

On Ubuntu 26.04 fresh installs, Docker 29 sets the `containerd` image store as the default. If you are upgrading an existing daemon with `userns-remap` enabled, the containerd image store default does not apply automatically. Also note that `pids.limit` set to `0` in runc 1.4.0 will now be treated as an actual limit of 1, not as unlimited. Review any container definitions that explicitly set `pids.limit = 0`.

## PHP 8.5 {#php-85}

Ubuntu 26.04 ships with **PHP 8.5.2**, a significant jump from PHP 8.3 in Ubuntu 24.04 LTS. This brings a new set of language features that Laravel and modern PHP developers will find immediately useful.

New features in PHP 8.5:

- **URI Extension**: A built-in `Uri\Rfc3986Uri` and `Uri\WhatWgUrl` class hierarchy for parsing, building, and modifying URIs without a third-party library.
- **Pipe Operator (`|>`)**: Allows chaining function calls in a left-to-right pipeline style, for example `$result = $value |> trim(...) |> strtolower(...) |> htmlspecialchars(...)`.
- **Clone With**: Allows creating a modified clone of an object with updated properties inline, for example `$new = clone($obj) with { property: $value }`.
- **`#[NoDiscard]` Attribute**: Marks a function return value as one that must not be ignored; the runtime emits a notice if the return value is discarded.
- **`array_first()` and `array_last()`**: Returns the first or last element of an array without resetting the internal pointer or needing `reset()` and `end()`.
- **Persistent cURL Share Handles**: Allows cURL share handles to persist across requests in long-running processes, improving performance for high-throughput HTTP workloads.
- **Closures and First-Class Callables in Constant Expressions**: Enables using closures and callable syntax in `const`, attribute arguments, and similar constant contexts.

### Breaking Changes in PHP 8.5

Before upgrading, audit your codebase for the following:

- `array` and `callable` can no longer be used as class alias names in `class_alias()`.
- The backtick operator (`` `command` ``) is deprecated; use `shell_exec()` instead.
- Non-canonical cast names are deprecated: `(boolean)`, `(integer)`, `(double)`, and `(binary)` must be written as `(bool)`, `(int)`, `(float)`, and `(string)`.
- Using `null` as an array offset or as an argument to `array_key_exists()` is deprecated; use an empty string `""` instead.

### Quick Verification

After upgrading or on a fresh 26.04 install, confirm your PHP version:

```bash
php -v
```

Expected output:

```
PHP 8.5.2 (cli) (built: Apr  2 2026 08:00:00) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.5.2, Copyright (c), by Zend Technologies
    with Zend OPcache v8.5.2, Copyright (c), by Zend Technologies
```

## Developer Toolchain Updates {#developer-toolchain}

Ubuntu 26.04 refreshes the full developer toolchain. The following table shows the version shipped in 26.04 compared to what was available in 24.04 LTS:

| Tool       | Ubuntu 24.04 LTS | Ubuntu 26.04 LTS   |
| ---------- | ---------------- | ------------------ |
| PHP        | 8.3              | 8.5.2              |
| Python     | 3.12             | 3.13               |
| PostgreSQL | 16               | 18                 |
| MariaDB    | 10.11 LTS        | 11.8.6 LTS         |
| MySQL      | 8.0              | 8.4.8 LTS          |
| Docker     | 25               | 29                 |
| containerd | 1.7              | 2.2.2              |
| OpenJDK    | 21               | 25 (TCK certified) |
| .NET       | 8                | 10                 |
| LLVM       | 17               | 21                 |
| Rust       | 1.75             | 1.93.1             |
| Zig        | not available    | 0.15.2             |
| Valkey     | not available    | 9.0.3              |

A few of these deserve additional notes:

- **PostgreSQL 18** introduces a new I/O subsystem that demonstrates up to 3x performance improvement for storage reads, virtual generated columns that compute values at query time, the `uuidv7()` function for better indexing, and OAuth 2.0 authentication support.
- **Python 3.13** removes the `crypt` module from the standard library. Any code that imports `crypt` directly will need to migrate to a third-party library such as `passlib`. This affects packages like `walinuxagent` on Azure as well.
- **Docker 29** makes the `containerd` image store the default for fresh installs and introduces experimental `nftables` support. The output of `docker image ls` has changed to a new tree-collapsed view by default.
- **OpenJDK 25** is TCK certified on AMD64, ARM64, S390X, and PPC64EL, guaranteeing full Java SE specification conformance.
- **Valkey 9.0** (the Redis-compatible fork) adds atomic slot migrations and hash field expiration.

## Security and Encryption {#security-encryption}

Ubuntu 26.04 brings several security improvements that are worth being aware of, especially in server and cloud deployments.

**TPM-backed Full Disk Encryption (FDE)** graduates to general availability in this release. The installer now includes readiness checks, PIN support is fully integrated, and recovery key prompts appear automatically before firmware updates that might trigger key regeneration.

**TLS 1.0 and 1.1 are disabled in Apache** by default, following RFC 8996. If you have clients or internal tooling that still connects using TLS 1.0 or 1.1, you will need to update them before deploying Ubuntu 26.04. OpenSSL already had these disabled by default; Apache now aligns with that.

**Sandboxed image loading** via `glycin` has replaced the built-in `gdk-pixbuf` parsers. Glycin is written in Rust and provides process-isolated image parsing, eliminating a category of image-based vulnerabilities that affected nearly 700 packages relying on `gdk-pixbuf`.

**Cryptography library updates** include OpenSSL updated to the latest LTS version, GnuTLS 3.8.12, NSS to the latest version, `libgcrypt` 1.12.0, and `libsodium` 1.0.18 with security fixes.

### sudo-rs: Password Feedback Now Default

The `sudo` implementation on Ubuntu 26.04 is `sudo-rs`, rewritten in Rust. Starting with this release, password feedback (displaying asterisks while typing your sudo password) is enabled by default. If you prefer the silent behavior, you can disable it:

```bash
sudo visudo
```

Add the following line to the sudoers configuration:

```
Defaults !pwfeedback
```

Save and exit. The change takes effect immediately for new sudo sessions.

## Other Notable Changes {#other-notable-changes}

Several smaller but important changes affect day-to-day development and scripting on Ubuntu 26.04.

**Removable media mount path changed.** USB drives and other removable media are now mounted under `/run/media` instead of `/media`. If you have shell scripts, backup tools, or automation that references the `/media` path, update them before upgrading.

**Google Drive integration removed from Files.** The GNOME Online Accounts service dropped Google Drive integration because the `libgdata` library it depended on is unmaintained and posed a security risk. You can still access Google Drive through a browser.

**SSSD now runs as user `sssd`, not root.** If you have integrations where SSSD reads secrets or connects to external identity providers, verify that the `sssd` user has appropriate permissions after upgrading.

**SysV init scripts are deprecated.** Ubuntu 26.04 LTS is the last release that will support System V init script compatibility in `systemd`. Migrate any legacy SysV scripts to native `systemd` unit files before the Ubuntu 26.10 release.

**AMD64v3 optimization variants** are now available as optional package variants for modern CPUs that support the x86-64-v3 microarchitecture level. Google Cloud's AMD64 images are now built with AMD64v3 by default, dropping support for older N1 machine types on Intel Ivy Bridge and Sandy Bridge.

**ROCm for AMD GPUs** is now available in the official Ubuntu archive for the first time. Install it with:

```bash
sudo apt install rocm
```

This makes Ubuntu 26.04 a first-class platform for AMD GPU compute workloads without requiring manual repository configuration.

## Upgrading to Ubuntu 26.04 LTS {#upgrading}

The stable upgrade path from Ubuntu 24.04 LTS will be available starting August 6, 2026, when the 26.04.1 point release ships. If you want to upgrade earlier on a non-production machine, you can use the development flag. Clean installs from the Ubuntu 26.04 ISO are available now from [ubuntu.com/download](https://ubuntu.com/download).

### Pre-Upgrade Checklist

Work through this list before upgrading any Ubuntu 24.04 LTS system:

- **Check cgroup version**: Run `cat /sys/fs/cgroup/cgroup.controllers`. If the file does not exist or returns empty, you are on cgroup v1 and the upgrade will be blocked.
- **Audit PHP code**: Search for deprecated casts, backtick operators, and `class_alias()` calls using `array` or `callable` as alias names.
- **Check Python `crypt` usage**: Run `grep -r "import crypt" .` in your project directories. Migrate any findings to `passlib` or `bcrypt`.
- **Review Docker workloads**: Confirm no containers set `pids.limit = 0`, and check that container images are based on Ubuntu 18.04 or newer.
- **Update scripts referencing `/media`**: Replace with `/run/media` where appropriate.
- **Check SSSD permissions**: If SSSD is configured, ensure the `sssd` user can access all required secrets and certificates.
- **Review SysV scripts**: Identify and convert any remaining `/etc/init.d/` scripts to `systemd` unit files.
- **Apache TLS config**: Confirm no clients require TLS 1.0 or 1.1 connections to your Apache server.

### Upgrade Commands (Non-Production Only)

The following steps perform an early upgrade using the development release flag. Run this only on machines where downtime and potential instability are acceptable.

```bash
sudo apt update && sudo apt upgrade -y
```

```bash
sudo apt install update-manager-core
```

```bash
sudo sed -i 's/^Prompt=lts/Prompt=normal/' /etc/update-manager/release-upgrades
```

```bash
sudo do-release-upgrade -d
```

> **Warning:** The `-d` flag targets the development channel. Do not run this on production systems. Wait for the 26.04.1 point release on August 6, 2026 for the stable upgrade path.

## Conclusion {#conclusion}

Ubuntu 26.04 LTS "Resolute Raccoon" is a release with real depth. The changes are broader and more breaking than a typical LTS cycle, which makes preparation more important than usual.

- **Linux kernel 7.0.** Rust support in the kernel is now stable and non-experimental. The real-time kernel is available for free without Ubuntu Pro, and Kernel Livepatch supports ARM64 for the first time.
- **Wayland-only desktop.** The X11 session has been removed. Applications without native Wayland support run via XWayland, which is transparent for most use cases but may require attention in GUI test pipelines and remote desktop setups.
- **cgroup v2 is mandatory.** This is the hardest breaking change for container workloads. Systems still running cgroup v1 will be blocked from upgrading, and container images older than Ubuntu 18.04 LTS will not run on a 26.04 host.
- **PHP 8.5.** New language features including the pipe operator, clone with syntax, URI extension, and `array_first()`/`array_last()` are available. Deprecations around cast names, the backtick operator, and `null` array offsets need attention before upgrading production PHP applications.
- **Full toolchain refresh.** PostgreSQL 18, Docker 29, Python 3.13, OpenJDK 25, Rust 1.93.1, and Valkey 9.0 are all available out of the box, giving you a modern foundation without manual PPA management.
- **Security improvements.** TPM-backed FDE is now GA, TLS 1.0/1.1 is disabled in Apache, image loading is sandboxed via Rust-based glycin, and `sudo-rs` replaces the C-based sudo implementation.
- **Upgrade timing.** The stable upgrade path from Ubuntu 24.04 LTS opens on August 6, 2026. Use the pre-upgrade checklist in this article to prepare your systems well in advance.