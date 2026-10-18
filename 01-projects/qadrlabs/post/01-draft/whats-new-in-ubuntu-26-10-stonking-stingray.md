# What's New in Ubuntu 26.10 "Stonking Stingray": Rust Coreutils, GNOME 51, and Linux 7.3

Most teams running Ubuntu treat interim releases as background noise. The servers stay on the LTS, the laptops stay on the LTS, and the October release passes by with a quick glance at the headlines. The problem is that interim releases are where the next LTS gets assembled. Changes like a new implementation of `cp` and `rm`, the removal of SysV init script support, or OpenSSH being split into two packages do not appear out of nowhere in April 2028; they land first in releases like this one, and a team that skipped them meets all of them at once during a production upgrade. Ubuntu 26.10 "Stonking Stingray" arrived on 15 October 2026, and it is worth a careful look even if your machines will stay on 26.04 LTS for now.

## Overview {#overview}

This article is an informational tour of Ubuntu 26.10, not a step-by-step installation guide. It walks through the kernel, the desktop, the core system, the developer toolchains, and the breaking changes, then finishes with a practical view on who should upgrade and who should wait. Where a change can be observed directly, a short command is included so you can verify it on a 26.10 machine or virtual machine.

### What You'll Get

- A clear mental map of what changed between Ubuntu 26.04 LTS and Ubuntu 26.10.
- A short checklist of commands to confirm the most important changes on a running 26.10 system.
- An informed decision about whether to upgrade a desktop, a development machine, or a server.

### What You'll Learn

- Which kernel, GNOME, and Mesa versions ship in Ubuntu 26.10 and what hardware they enable.
- What the completed switch to Rust-based coreutils means in practice.
- Which developer toolchains and server packages were updated, including PHP, Python, Rust, and MySQL.
- Which features were removed or changed in backward-incompatible ways.
- How long 26.10 is supported and how to upgrade from 26.04 LTS.

### What You'll Need

- Basic familiarity with the Linux terminal and `apt`.
- Optional: a machine or virtual machine running Ubuntu 26.10 if you want to run the verification commands.
- Optional: the earlier article [Getting to Know Rust: A First Look with Ubuntu and Hello World](https://qadrlabs.com/post/getting-to-know-rust-a-first-look-with-ubuntu-and-hello-world) for background on Rust, since Rust plays a large role in this release.

## Release at a Glance {#release-at-a-glance}

Ubuntu 26.10 is an interim release, which means it receives nine months of maintenance updates instead of the five years (or more) that an LTS release gets. It builds on top of Ubuntu 26.04 LTS and acts as the first step toward the next LTS. The table below summarizes the headline facts from the official release notes and the release announcement.

| Item | Ubuntu 26.10 |
| --- | --- |
| Codename | Stonking Stingray |
| Release date | 15 October 2026 |
| Support window | 9 months, until July 2027 |
| Linux kernel | 7.3 |
| Desktop | GNOME 51 |
| Graphics | Mesa 26.2 |
| Init system | systemd 261.3 |
| Installer | Subiquity 26.10 |
| Official flavors | Edubuntu, Kubuntu, Lubuntu, Ubuntu Budgie, Ubuntu Cinnamon, Ubuntu Kylin, Ubuntu MATE, Ubuntu Studio, Ubuntu Unity, Xubuntu |

The nine-month support window is the most important number in this table. A machine that installs 26.10 today needs to move to 27.04 before July 2027 to keep receiving security updates. That makes 26.10 a good fit for personal machines and test environments, and a poor fit for servers that should be left alone for years.

## Linux 7.3 and Hardware Support {#linux-7-3-and-hardware-support}

The kernel is usually the main reason people install an interim release on new hardware. Ubuntu 26.10 ships Linux 7.3, and the release images use kernel version `7.3.0-9.9`. You can confirm the running kernel with a single command.

```bash
uname -r
```

The `uname -r` command prints the release string of the kernel that is currently running. On a fresh Ubuntu 26.10 installation, the output starts with `7.3.0`, followed by the Ubuntu build number and the flavor suffix such as `generic`. If you see a 6.x or 7.0 kernel instead, the machine is still booting an older kernel, which can happen after an upgrade that has not been followed by a reboot.

### New Hardware Enablement

Linux 7.3 brings several notable hardware additions:

- **Snapdragon X2 Elite laptops** receive early support, continuing Ubuntu's push toward Arm-based laptops.
- **AMD Zen 6** client platforms are enabled ahead of their wider availability.
- **NVIDIA 615 driver series** packages are available. These use the open kernel modules only, so they support Turing GPUs and newer.
- **SBOMs** (software bills of materials) are now published for the amd64 and arm64 kernels, which helps teams that need to audit what goes into their systems.

The release notes also list a known regression: some Snapdragon X2 Elite laptops may have an unusable built-in keyboard because of a Linux 7.3 issue. Check the known issues before installing on that hardware.

### New Installation Images

Two new kinds of images appear in this release. The first is an **amd64v3** image, built for CPUs that support the x86-64-v3 instruction set level (roughly, Intel Haswell and AMD Excavator or newer). Early reports suggest the gains are modest, around 1% in some workloads, and the image is only available from the cdimage server rather than the main download page.

The second is a set of **experimental RISC-V desktop images**: a GNOME image for SpacemiT K3 boards and a minimal Xubuntu image for QEMU. These are not officially supported yet, and the GNOME image does not include App Center. They are mostly interesting as a signal that RISC-V desktops are moving from "possible" to "planned".

## GNOME 51 Desktop Changes {#gnome-51-desktop-changes}

The desktop side of 26.10 is built on GNOME 51 plus Ubuntu's own extensions and defaults. Most of the changes are refinements rather than redesigns, but several of them fix long-standing annoyances. The sections below group them by area.

### Window Tiling Layout Picker

The Tiling Assistant extension that Ubuntu ships by default gains a layout picker. When you start dragging a window, a picker appears at the top of the screen. Moving the window over one of the layouts shows a ghost preview of where it will land, and releasing the mouse snaps it into place. This works similarly to the snap layouts feature on Windows.

If you prefer the old behavior, the picker can be turned off with `gsettings`:

```bash
gsettings set org.gnome.shell.extensions.tiling-assistant enable-layout-picker false
```

This command writes a new value to the Tiling Assistant's settings schema. Setting `enable-layout-picker` to `false` disables the drag-up picker while keeping the rest of the tiling features. To bring the picker back, run the same command with `true` at the end. You can read the current value at any time:

```bash
gsettings get org.gnome.shell.extensions.tiling-assistant enable-layout-picker
```

The `get` subcommand prints the stored value, which will be either `true` or `false`.

### Displays, Accessibility, and Settings

Several small Settings changes add up to a noticeably smoother experience:

- **Per-monitor brightness and color mode** (including HDR) are now remembered across reboots. GNOME identifies each monitor by its EDID, so external displays keep their settings too.
- **Automatic screen rotation** works on devices with an accelerometer, and a new toggle in Displays lets you turn it off.
- **Reduce Motion** in Accessibility turns down most animations, which helps users sensitive to motion and also makes slower machines feel snappier.
- **DNS search domains** can now be configured directly in the network settings.
- **Touchpad auto-disable** can switch the touchpad off when a mouse is connected.
- **Ubuntu Certified check** in Settings > System tells you whether the device is certified, not certified, or a close match.

GNOME Shell also changed how it behaves under memory pressure. When the system runs low on memory, applications are now terminated before the services that hold the session together, which reduces the chance of being logged out unexpectedly.

### Login and Enterprise Authentication

Authentication received significant attention in this release. The GDM login and lock screens now support FIDO2 passkeys and web-based sign-in flows, in addition to the smart card support that already existed.

For organizations, the integration with **Microsoft Entra ID** goes deeper. Users can sign in with their Entra password and approve multi-factor authentication through Microsoft Authenticator or a one-time code. This works on the graphical login, in the terminal, and over SSH, so a managed Ubuntu machine can follow the same identity policy as the rest of the fleet. The supporting components are `authd` 0.7.1 and ADSys 0.17.0.

### App Center and Default Applications

App Center gets a new Add-ons section that offers **Additional Drivers** (for example, NVIDIA drivers) and **Media Support** for codecs. It also merges the Snap and Deb versions of an application into a single details page, so you can compare size, publisher, permissions, and version in one place before choosing.

The default applications also improved:

- **Papers** (the document viewer) can add handwritten signatures drawn with a mouse, stylus, or touchscreen, or imported from a photo with the background removed. These are visual annotations, not cryptographic signatures.
- **Nautilus** shows a file count while dragging multiple files, and large folders refresh faster.
- **Screenshots** lets you adjust a selection with the arrow keys, using Shift for larger steps and Ctrl for smaller ones.
- **Resources** can report NPU activity on recent AMD Ryzen chips (7040, 8040, and Ryzen AI 300 and 400 series).
- **Desktop icons (DING)** were ported to GTK4, and the right-click menu opens faster.

### Myna: Local Speech-to-Text Preview

Ubuntu 26.10 introduces **Myna**, an opt-in speech-to-text feature that processes audio locally on the machine instead of sending it to a cloud service. It is a technology preview and is not preinstalled, so nothing changes unless you choose to install it. The local processing model is the interesting part: dictation without a network round trip and without audio leaving the device.

## Rust Coreutils and Other Core System Changes {#rust-coreutils-and-core-system-changes}

The changes in this section are the ones most likely to affect scripts, servers, and automation, because they replace components that almost every shell script depends on. None of them change the commands you type, but they change what runs underneath.

### Rust-Based Coreutils Are Now the Default

The transition that started in earlier releases is complete. In Ubuntu 26.10, the Rust-based `uutils` project provides all of the default coreutils, including the most sensitive ones: `cp`, `mv`, and `rm`. The motivation is memory safety rather than new features. Utilities that run as root on every system are an attractive target for memory corruption bugs, and Rust removes a whole class of those bugs at compile time.

You can check which implementation provides a command on your system:

```bash
ls --version
```

The `--version` flag asks the utility to print its own name and version. On a system using the Rust implementation, the first line mentions `uutils coreutils` instead of `GNU coreutils`. The same check works for `cp`, `mv`, `rm`, and the other utilities.

To see where the binary actually lives, resolve the symlink behind the command:

```bash
readlink -f "$(command -v cp)"
```

The `command -v cp` part finds the path that the shell would run for `cp`, and `readlink -f` follows any symlinks to the final file. This is useful for seeing how the packaging wires the Rust binaries into the standard paths.

For most users this change is invisible. If you maintain scripts that depend on rare GNU-specific flags or on exact error message text, this is the release in which to test them, well before the next LTS makes the switch unavoidable.

### dbus-broker Replaces dbus-daemon

The system message bus now uses `dbus-broker` by default instead of the classic `dbus-daemon`. D-Bus is how many desktop and system services talk to each other, and `dbus-broker` is a faster implementation designed to work closely with systemd. You can confirm which one is running:

```bash
systemctl status dbus-broker.service
```

This command shows the status of the `dbus-broker` systemd unit. On Ubuntu 26.10 it should report `active (running)`. Press `q` to leave the status view.

### Sequoia PGP and APT 3.3.3

Sequoia PGP, another Rust project, is now in the main archive and provides the `sq` and `sqv` tools. The familiar `gpg` and `gpgv` remain available, so existing workflows keep working; Sequoia is preinstalled but not yet the default. Ubuntu also describes its package signing as prepared for post-quantum cryptography, which is part of the same long-term security effort.

APT moves to version 3.3.3. One small but practical improvement is that `--help` is now specific to each subcommand for many commands:

```bash
apt install --help
```

Instead of printing the generic APT help text, this lists the options that apply to `apt install`. Not every subcommand has been converted yet, but the common ones are covered.

## Developer Toolchains and Server Packages {#developer-toolchains-and-server-packages}

For developers, an interim release is often the easiest way to get newer compilers and runtimes from the official archive without adding third-party repositories. Ubuntu 26.10 updates nearly every major toolchain.

### Toolchains

| Toolchain | Version in 26.10 |
| --- | --- |
| GCC | 15.2.0 |
| LLVM | 22.1.8 |
| Python | 3.14.7 |
| Rust | 1.97.1 |
| Go | 1.27 |
| OpenJDK | 25.0.4 (OpenJDK 27 available as `openjdk-27`) |
| .NET | 10.0.112 |
| Zig | 0.16 |

You can check the default versions directly from the terminal:

```bash
gcc --version
python3 --version
rustc --version
```

Each command prints the version of the default compiler or interpreter. Note that `rustc` is only present if the Ubuntu `rustc` package is installed. If you installed Rust with `rustup`, as described in the Rust introduction article, the `rustup` toolchain takes priority in your `PATH` and its version is what you will see.

### Server Packages

| Package | Version in 26.10 |
| --- | --- |
| PHP | 8.5.9 |
| Apache | 2.4.68 |
| MySQL | 9.7 LTS |
| Valkey | 9.1.2 |
| HAProxy | 3.4.2 (LTS branch) |
| OpenSSL | 4.0 |
| OpenSSH | 10.5 |
| Samba | 4.24.7 |
| Postfix | 3.11.7 |

For PHP and Laravel developers, PHP 8.5.9 from the main archive is the headline here. You can confirm it after installing the CLI package:

```bash
sudo apt install php8.5-cli
php --version
```

The first command installs the PHP 8.5 command-line interpreter from the Ubuntu archive, and the second prints its version, which should start with `PHP 8.5.9`. Laravel 13 requires PHP 8.3 or newer, so this version is comfortably within range. MySQL moves to the 9.7 LTS series, and Valkey (the open source fork of Redis) is available at 9.1.2 for cache and queue backends.

## Security and Encryption {#security-and-encryption}

Security changes in 26.10 range from disk encryption to the cryptographic libraries that every TLS connection depends on. Some of them are pure improvements, while others require configuration changes on servers.

### TPM-Backed Full-Disk Encryption on More Devices

TPM-backed full-disk encryption is now available on devices without a hardware root of trust, as long as a PIN or passphrase is set during installation. On supported hardware, PCs made since around 2021 can unlock automatically at boot. This makes strong disk encryption practical on far more laptops.

There is an important limitation: systems that already use TPM-backed full-disk encryption **cannot upgrade from 26.04 to 26.10 at release**. Canonical expects to enable that upgrade path later in the cycle.

### OpenSSL 4 and the End of ENGINE

Ubuntu 26.10 ships OpenSSL 4, which removes the old ENGINE interface. Configurations that relied on an ENGINE, typically for hardware security modules or smart cards, need to migrate to the PKCS#11 provider. If a server uses `engine` directives in its OpenSSL configuration, test it carefully before upgrading.

### OpenSSH Split into Two Packages

OpenSSH 10.5 is now packaged as two conflicting variants: `openssh` without GSSAPI support and `openssh-gssapi` with it. Fresh installations get the non-GSSAPI variant. During an upgrade, systems that use Kerberos with OpenSSH are automatically moved to the GSSAPI packages.

The release notes also include a specific warning: do not purge an OpenSSH package that is in the `rc` state (removed but with configuration files left behind) until the fix for Launchpad bug #2169738 is released, because doing so can break remote access. You can list packages in that state with:

```bash
dpkg -l | grep '^rc' | grep openssh
```

The `dpkg -l` command lists every package known to dpkg with a two-letter status prefix. Filtering for `^rc` keeps only packages that were removed but still have configuration files, and the second `grep` narrows the list to OpenSSH. If this prints anything, leave those packages alone for now.

## Removals and Breaking Changes {#removals-and-breaking-changes}

Every release removes something, and the removals are usually more important to operations teams than the new features. These are the changes in 26.10 that can break an existing setup.

### Removed Features

- **SysV init scripts no longer run.** The `systemd-sysv-generator`, which automatically turned scripts in `/etc/init.d` into systemd units, has been removed. Any service that still ships only a SysV script will not start.
- **WEP Wi-Fi** is no longer offered in Settings. WEP has been insecure for many years, but some old routers and embedded devices still use it.
- **OpenSSL ENGINE** is gone, as covered in the security section.
- **HAProxy** removes the `program` section and now rejects duplicate section names.
- **`pollinate`** is dropped from the server cloud minimal seed.

### Deprecations to Watch

- **Postfix** deprecates the BerkeleyDB `hash:` and `btree:` map types and now prints warnings when they are used.
- **HAProxy** deprecates `dispatch` and `option transparent`.

### Checking for Legacy SysV Services

Before upgrading a machine, it is worth checking whether anything still depends on a SysV init script. Run the following on the current 26.04 system, where the generator still exists:

```bash
ls /run/systemd/generator.late/*.service 2>/dev/null
```

The `systemd-sysv-generator` writes the units it creates from `/etc/init.d` scripts into `/run/systemd/generator.late`. Listing the `.service` files in that directory shows exactly which services are currently running only thanks to the generator. If the command prints nothing, no service depends on SysV compatibility. Any file it does print is a candidate for a hand-written systemd unit before you move to 26.10, because on 26.10 the generator that bridged the gap no longer exists.

## Should You Upgrade? {#should-you-upgrade}

The answer depends on what the machine does. Ubuntu 26.10 is stable and well tested, but its short support window and its breaking changes make it a better fit for some roles than others.

### Good Candidates for 26.10

- **New hardware**, such as Snapdragon X2 Elite laptops or AMD Zen 6 systems, which benefit from Linux 7.3.
- **Developer workstations** that want newer toolchains like GCC 15.2, Python 3.14, Rust 1.97, and PHP 8.5 from the official archive.
- **Test and staging environments** where teams want to validate Rust coreutils, OpenSSL 4, and the SysV removal before the next LTS.

### Better to Stay on 26.04 LTS

- **Production servers** that need long-term stability and should not be upgraded every six months.
- **Machines using TPM-backed full-disk encryption**, which cannot upgrade to 26.10 at release.
- **Systems that rely on OpenSSL ENGINE, SysV init scripts, or WEP**, until those dependencies are migrated.

### How to Upgrade from 26.04 LTS

By default, Ubuntu 26.04 LTS only offers upgrades to the next LTS release. To receive the 26.10 upgrade, the release upgrader needs to be set to offer all new versions. On the desktop, open Software & Updates, go to the Updates tab, and set "Notify me of a new Ubuntu version" to "For any new version". On a server or from the terminal, check the setting directly:

```bash
grep Prompt /etc/update-manager/release-upgrades
```

This prints the `Prompt` line from the release upgrader configuration. A value of `lts` means only LTS upgrades are offered, while `normal` means every release is offered. After changing the value to `normal` and fully updating the current system, start the upgrade:

```bash
sudo apt update && sudo apt full-upgrade
sudo do-release-upgrade
```

The first line makes sure the current 26.04 system is fully up to date, which the release upgrader expects. The second line launches the interactive upgrade to 26.10. Make a backup first, read the prompts carefully, and keep a second way into the machine (such as a console) if you are upgrading over SSH. The release notes also mention that the upgrader may stop on a dangling `/lib32` symlink while installing `base-files`, so check the known issues page if the upgrade halts there.

## Conclusion {#conclusion}

Ubuntu 26.10 "Stonking Stingray" looks like a quiet interim release from the outside, but it carries some of the most significant plumbing changes Ubuntu has made in years. Rust now provides the core utilities, D-Bus runs on a new broker, SysV scripts no longer run, and OpenSSL and OpenSSH changed in ways that matter for servers. Even teams that stay on 26.04 LTS benefit from understanding these changes now, because they are the foundation of the next LTS.

- **Interim support window.** Ubuntu 26.10 is supported for nine months, until July 2027, so it suits desktops and test machines better than long-lived servers.
- **Linux 7.3 and GNOME 51.** The new kernel enables Snapdragon X2 Elite and AMD Zen 6 hardware, while GNOME 51 adds a tiling layout picker, remembered monitor brightness, and Reduce Motion.
- **Rust coreutils.** The `uutils` implementation now provides every default core utility, including `cp`, `mv`, and `rm`, with memory safety as the main goal.
- **Updated toolchains.** GCC 15.2, Python 3.14.7, Rust 1.97.1, Go 1.27, and PHP 8.5.9 are available straight from the official archive.
- **Security upgrades.** TPM-backed disk encryption reaches more devices, Entra ID supports MFA at login, and Sequoia PGP joins the main archive.
- **Breaking changes.** SysV init script support, WEP, and OpenSSL ENGINE are gone, and OpenSSH is split into GSSAPI and non-GSSAPI packages.
- **Upgrade with care.** Switch the release upgrader to `normal`, back up first, and skip this release on TPM-encrypted machines until the upgrade path is enabled.
