---
title: "Fix HDMI Not Working After Upgrading to Ubuntu 26.04 on NVIDIA Optimus Laptops"
slug: "fix-hdmi-not-working-after-upgrading-to-ubuntu-2604-on-nvidia-optimus-laptops"
category: "Ubuntu"
date: "2026-04-27"
status: "published"
---

You upgraded Ubuntu, rebooted, and everything seemed fine until you plugged in your external monitor via HDMI. Nothing. A blank screen. No signal. The monitor stays dark no matter what you try.

This is frustrating because it worked perfectly before the upgrade. You might start questioning the cable, the monitor, even the port itself. But here is the real problem: on laptops with NVIDIA Optimus (dual GPU), the HDMI port is physically wired to the NVIDIA GPU, not the Intel integrated graphics. When a major Ubuntu upgrade replaces the kernel, the NVIDIA driver frequently breaks or gets removed entirely. No NVIDIA driver means no HDMI output, full stop.

This guide walks you through the exact steps to diagnose the problem, reinstall the NVIDIA driver correctly on Ubuntu 26.04, and get your external monitor working again.
## Overview {#overview}
This article is based on a real troubleshooting session on an ASUS ROG Strix G531GD running Ubuntu 26.04 LTS with kernel 7.0.0-14-generic. The same steps apply to any NVIDIA Optimus laptop that lost HDMI output after upgrading.
### What You'll Build
By the end of this guide, you will have a fully working dual-display setup: the internal laptop screen driven by the Intel GPU, and the external monitor connected via HDMI driven by the NVIDIA GPU.
### What You'll Learn
- How to confirm that a missing NVIDIA driver is the root cause of a blank HDMI screen
- Why NVIDIA drivers break after a major Ubuntu kernel upgrade
- How to cleanly remove broken NVIDIA drivers and blacklist the conflicting `nouveau` driver
- How to install the correct NVIDIA driver on Ubuntu 26.04 using the updated `ubuntu-drivers` syntax
- How to enable `nvidia-drm modeset=1` for Wayland and HDMI compatibility
- How to verify the fix with `nvidia-smi` and `xrandr`
### What You'll Need
- A laptop with dual GPU (Intel integrated + NVIDIA discrete, Optimus architecture)
- Ubuntu 26.04 LTS installed (upgraded from an earlier version or fresh install)
- `sudo` access
- An active internet connection
- The HDMI cable and external monitor you want to connect
## Step 1: Diagnose the Problem {#step-1-diagnose}
Before touching any driver, confirm that a missing NVIDIA driver is actually the cause. This step rules out hardware issues and points you directly at the software root cause.
### Check if HDMI is detected at all
Run the following command to list all display outputs:

```bash
xrandr --query | grep HDMI
```

If nothing is returned, or if you see `HDMI-1 disconnected` even though the cable is plugged in, the system is not recognizing the port. This is the first sign that the NVIDIA GPU is not active.
### Check which GPUs the system sees
```bash
lspci -k | grep -EA3 'VGA|3D|Display'
```

On a working Optimus laptop, you should see two entries: one for Intel and one for NVIDIA. If only the Intel GPU appears, the NVIDIA driver is not loaded.
### Check the NVIDIA driver status directly
```bash
nvidia-smi
```

If the driver is broken or missing, you will see this error:

```
NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running.
```

This output confirms the diagnosis. The NVIDIA driver is not communicating with the kernel. Because the HDMI port on Optimus laptops is wired directly to the NVIDIA GPU, there is no path for any video signal to reach the external monitor until the driver is restored.
## Step 2: Purge Old NVIDIA Drivers {#step-2-purge}
The first fix attempt many people try is reinstalling the driver on top of the broken one. This rarely works. The safer approach is to remove everything NVIDIA-related first, then start fresh.

Run the following commands:

```bash
sudo apt purge 'nvidia*' 'libnvidia*' -y
sudo apt autoremove -y
sudo reboot
```

The `purge` command removes the package and its configuration files. The `autoremove` cleans up any orphaned dependencies that were pulled in by the old driver. The reboot ensures the system starts clean without any partially loaded NVIDIA modules in memory.
## Step 3: Blacklist the Nouveau Driver {#step-3-blacklist-nouveau}
After purging the proprietary NVIDIA driver, the system will fall back to `nouveau`, which is the open-source NVIDIA driver built into the Linux kernel. While `nouveau` provides basic display output, it directly conflicts with the proprietary NVIDIA driver and will prevent it from loading if both are active at the same time.

Create a blacklist file to disable `nouveau` permanently:

```bash
sudo tee /etc/modprobe.d/blacklist-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF
```

This file tells the kernel to never load the `nouveau` module. The `modeset=0` option also disables its display mode-setting capabilities as a secondary safeguard.

Now regenerate the initramfs so the blacklist takes effect on the next boot:

```bash
sudo update-initramfs -u
```

Do not reboot yet. Continue to the next step to install the new driver first, then reboot once after both steps are complete.
## Step 4: Install the NVIDIA Driver {#step-4-install-driver}
Ubuntu 26.04 changed the syntax of the `ubuntu-drivers` command. The `autoinstall` subcommand no longer exists. If you run `sudo ubuntu-drivers autoinstall`, you will get this error:

```
Error: No such command 'autoinstall'.
```

The correct command on Ubuntu 26.04 is:

```bash
sudo ubuntu-drivers install
```

This detects your GPU and installs the recommended driver version automatically. If you want to install a specific version instead, you can use `apt` directly:

```bash
sudo apt install nvidia-driver-580
```

For the ASUS ROG G531GD with GTX 1050, driver version 580 is the appropriate choice. After installation, update the initramfs one more time so the new driver modules are included in the boot image:

```bash
sudo update-initramfs -u
```

Do not reboot yet. Complete Step 5 first.
## Step 5: Enable NVIDIA DRM Modeset {#step-5-drm-modeset}
This step is required for HDMI output to work correctly when running GNOME on Wayland, which is the default windowing system on Ubuntu 26.04.

Without `nvidia-drm modeset=1`, the NVIDIA driver loads but does not register itself as a kernel mode-setting driver. Wayland relies on KMS to manage display outputs, so without this flag, the HDMI port remains inactive even with a working driver.

Create the configuration file:

```bash
sudo tee /etc/modprobe.d/nvidia-drm.conf <<EOF
options nvidia-drm modeset=1
EOF
```

Update the initramfs and reboot:

```bash
sudo update-initramfs -u
sudo reboot
```

This is the final reboot. All three changes (blacklist, new driver, and DRM modeset) will take effect together.
## Step 6: Verify and Test HDMI {#step-6-verify}
After the reboot, verify that the NVIDIA driver is loaded correctly:

```bash
nvidia-smi
```

You should see output similar to this:

```
Mon Apr 27 09:20:53 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.142                Driver Version: 580.142        CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce GTX 1050        Off |   00000000:01:00.0  On |                  N/A |
| N/A   43C    P8            N/A  / 5001W |      33MiB /   4096MiB |      0%      Default |
|                                         |                        |               MIG M. |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A            4346      G   /usr/bin/gnome-shell                      1MiB |
+-----------------------------------------------------------------------------------------+
```

Now plug in the HDMI cable and check if the external monitor is detected:

```bash
xrandr --query | grep HDMI
```

Expected output:

```
HDMI-1 connected 1920x1080+1920+0 (normal left inverted right x axis y axis) 600mm x 330mm
```

The `connected` status and the resolution confirm that the system is successfully routing video signal through the NVIDIA GPU to the external monitor.
### Adjust display layout (optional)
If you want to change the monitor arrangement, open the GNOME display settings:

```bash
gnome-control-center display
```

Or use `xrandr` directly. To move the external monitor to the left of the laptop screen:

```bash
xrandr --output HDMI-1 --auto --left-of eDP-1
```

To set the external monitor as the primary display:

```bash
xrandr --output HDMI-1 --primary
```
## Why NVIDIA Drivers Break After a Major Ubuntu Upgrade {#why-drivers-break}
Understanding what went wrong helps you prevent it next time. There are several reasons why NVIDIA drivers reliably break during a major Ubuntu release upgrade.

The most direct cause is a kernel version jump. When Ubuntu upgrades the kernel (in this case from the 6.x series to Linux 7.0), any kernel module compiled for the old version is no longer valid. NVIDIA drivers are kernel modules, so they need to be recompiled for each new kernel version.

DKMS (Dynamic Kernel Module System) is designed to handle this automatically. When a new kernel is installed, DKMS should detect existing modules and rebuild them. However, during a major release upgrade such as 25.04 to 26.04, the DKMS rebuild process frequently fails silently. The system completes the upgrade without raising an obvious error, but the NVIDIA module is missing from the new kernel.

There is also a package conflict issue. The `do-release-upgrade` process resolves dependency changes between Ubuntu versions. If the version of `nvidia-driver-xxx` installed on the old system is not available in the new Ubuntu repository, or if it conflicts with an updated dependency, the upgrade process may remove it without installing a replacement.

The consequence on an Optimus laptop is more severe than on a desktop. On a desktop with a standalone NVIDIA card, the display falls back to `nouveau` and at least shows something. On an Optimus laptop, the internal display is handled by Intel, which continues to work, but the HDMI port is hardwired to the NVIDIA GPU. Without the driver, that port has no active controller and outputs a blank signal.
### Preventing this in the future
After your next major Ubuntu upgrade, run these commands immediately after the first reboot before testing anything else:

```bash
sudo dkms autoinstall
```

If DKMS reports any errors, reinstall the driver manually:

```bash
sudo apt install --reinstall nvidia-driver-580 nvidia-dkms-580
sudo reboot
```
## Conclusion {#conclusion}
Getting HDMI working again after a major Ubuntu upgrade on an Optimus laptop comes down to one root cause: the NVIDIA driver. Here are the key takeaways from this guide.

- **HDMI on Optimus laptops is wired to the NVIDIA GPU, not Intel.** This is the hardware design that makes the NVIDIA driver non-optional for external monitor use, even when the internal display works fine on Intel alone.
- **Major kernel upgrades routinely break NVIDIA drivers.** DKMS is supposed to rebuild modules automatically, but it silently fails during major release upgrades. Always verify with `nvidia-smi` after upgrading.
- **The `ubuntu-drivers autoinstall` command no longer exists in Ubuntu 26.04.** Use `sudo ubuntu-drivers install` instead, or install the driver directly with `sudo apt install nvidia-driver-580`.
- **`nvidia-drm modeset=1` is required for Wayland and HDMI to work together.** Without it, the NVIDIA driver loads but does not register as a KMS driver, which Wayland requires to manage display outputs.
- **Blacklisting `nouveau` prevents module conflicts.** Even after purging the proprietary driver, `nouveau` can interfere with reinstallation if it is not explicitly disabled.
- **Run `sudo dkms autoinstall` immediately after the next upgrade.** This is the fastest way to catch and fix DKMS rebuild failures before they result in a blank HDMI screen.