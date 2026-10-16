# How to Fix Laravel Installer Timeout: "valet paths -v" Exceeded 60 Seconds on macOS

A new Laravel project can appear to install normally until the installer reaches application initialization. Then the terminal waits, a password prompt may appear, and the process eventually fails with a 60-second timeout. The application directory may already exist, but database setup, testing tools, and frontend dependencies can be left unfinished. In one macOS development environment, the problem came down to how Laravel Installer invoked Laravel Valet. Investigating the Valet executable paths and adjusting shell `PATH` allowed the installation to finish.

This guide follows that troubleshooting session using Laravel Installer 5.32.0 and Laravel Valet 4.12.0. It also explains how to distinguish the observed behavior from other possible causes of an installer timeout.

## Overview {#overview}

We will diagnose the command that stalled during project creation, compare how Valet behaves when invoked through different executable paths, and apply a targeted fix. The final check is a complete Laravel installation rather than merely a successful `valet` command.

### What You'll Fix

- The Laravel Installer timeout caused by a Valet subprocess that requests a password during project creation.
- The executable path mismatch that causes Valet to request a password even after running `valet trust`.
- The shell `PATH` configuration so Laravel Installer can use the intended Valet executable without interrupting the installation process.

### What You'll Learn

- How to identify the subprocess behind a Laravel Installer timeout.
- How to inspect Composer and Homebrew executable paths.
- Why `valet trust` may not eliminate a password prompt when the invoked executable path differs.
- How to test a `PATH` change before making it permanent.
- How to verify the fix by creating a complete Laravel application.

### What You'll Need

- macOS with Homebrew and Zsh.
- PHP 8.3 or later for a Laravel 13 project.
- Composer and Laravel Installer. The troubleshooting session used Laravel Installer 5.32.0.
- Laravel Valet. The troubleshooting session used Valet 4.12.0.
- Permission to inspect your shell configuration and, if appropriate, run Valet's trusted-commands setup.
- Familiarity with basic Terminal commands. No existing Laravel application code is required.

This article applies specifically to Laravel Valet. Laravel Herd and other local development environments may have different executable paths and permission requirements.

## Step 1: Identify the Laravel Installer Timeout {#step-1-identify-the-laravel-installer-timeout}

Start with the error produced by Laravel Installer. The important clue is not the Symfony file name in the exception, but the external command that exceeded the time limit.

During the initial failed installation, the terminal reported:

```text
In Process.php line 1212:

  The process "'valet' 'paths' '-v'" exceeded the timeout of 60 seconds.
```

This output identifies `valet paths -v` as the subprocess that failed to complete. The error does not say that Laravel's application code or database migrations caused the timeout.

A later attempt to create `laravel-update-demo` reached the following point and requested a password:

```text
 • Creating Laravel application
   ✔ Application installed
   ✔ Application initialized

Password:
```

The installer had created and initialized the application, but the overall installation workflow was not yet finished. A password prompt can prevent an unattended subprocess from completing. In this case, the combination of that prompt and the original timeout pointed to Valet as the next component to investigate.

**Before retrying:** if a previous attempt already created a project directory, check its contents. Use a new project name for another test unless you intentionally want to work with the existing directory. Avoid deleting a partially created project without checking it first.

## Step 2: Check the Installed Tool Versions {#step-2-check-the-installed-tool-versions}

Confirm which Laravel Installer and Valet versions are involved. This helps match the observed behavior to the correct source code instead of assuming that every version works identically.

```bash
laravel --version
composer global show laravel/installer
valet --version
```

The first command checks the Laravel Installer CLI version. The second displays Composer's globally installed Laravel Installer package. The third checks the Valet version accessible from the current shell.

In the troubleshooting session, the version checks identified **Laravel Installer 5.32.0** and **Laravel Valet 4.12.0**. These version numbers establish the environment used for this example; they do not, by themselves, prove a bug in either package.

Next, test the exact command named in the exception.

```bash
valet paths -v
```

The `paths` command lists directories registered with Valet. The `-v` option is significant here because it is the form used by Laravel Installer. In the affected environment, Valet asked for a password before printing the paths. This was the first useful behavior we could reproduce outside the installer.

## Step 3: Inspect Which Valet Executable Runs {#step-3-inspect-which-valet-executable-runs}

Multiple `valet` entries can exist on the same machine. The command typed in the shell is resolved through `PATH`, so its location can affect subsequent privilege checks.

### Find the Available Executable Paths

```bash
which -a valet
```

This command reports matches named `valet` found through the shell's search paths. In the recorded environment, it reported repeated entries for two distinct locations: `/Users/yourusername/.composer/vendor/bin/valet` and `/opt/homebrew/bin/valet`.

Repeated entries do not necessarily mean multiple installations. They can also result from repeated directories in `PATH`. The relevant observation is that the Composer executable appeared before the Homebrew executable.

### Inspect the Files and Symbolic Link

```bash
ls -l ~/.composer/vendor/bin/valet
ls -l /opt/homebrew/bin/valet
```

These commands show whether each entry is a regular file or a symbolic link, and where a symbolic link points. The original output was:

```text
-rwxr-xr-x  1 yourusername  staff  949 Jun  3 21:56 /Users/yourusername/.composer/vendor/bin/valet
lrwxr-xr-x  1 yourusername  staff  57 Jun  3 21:59 /opt/homebrew/bin/valet -> /Users/yourusername/.composer/vendor/laravel/valet/valet
```

The Composer location was an executable file, while the Homebrew location was a symbolic link to the installed Valet script. The `staff` field is the standard macOS group name in the file listing, not evidence of a permission problem.

### Confirm the Password Prompt

```bash
sudo -k
valet paths -v
```

`sudo -k` invalidates the cached sudo authentication for the current user. Running Valet afterward tests whether the command can execute without relying on a recently entered password.

The original Valet output included this prompt and directory listing:

```text
Password:
[
    "/Users/yourusername/.config/valet/Sites",
    "/Users/yourusername/Sites",
    "/Users/yourusername/Sites/a-project",
    "/Users/yourusername/Sites/b-project",
    "/Users/yourusername/Sites/c-project"
]
```

This is a direct observation: Valet asked for a password even though the command ultimately returned the list after authentication.

### Understand What Happened with `valet trust`

The troubleshooting session also included:

```bash
valet trust
```

Valet documents this command as a way to add sudoers entries that let supported Brew and Valet operations run without repeatedly prompting for a password. It changes privileged system configuration, so run it only on a trusted development machine and only if that configuration is appropriate for your environment.

The command returned the following output:

```text
Sudoers entries have been added for Brew and Valet.
```

However, `sudo -k` followed by `valet paths -v` still produced a password prompt. The successful `valet trust` message therefore did not mean the problem had been resolved. We needed to compare the two executable paths directly.

## Step 4: Test the Homebrew Valet Path Directly {#step-4-test-the-homebrew-valet-path-directly}

Instead of changing any configuration immediately, bypass the shell's choice of executable. Invoke the Valet script through the Homebrew path shown in the earlier file listing.

```bash
sudo -k
/opt/homebrew/bin/valet paths -v
```

The absolute path ensures that the command uses the Homebrew entry. Running `sudo -k` first makes this a more useful comparison with the previous test.

In the recorded test, **the direct Homebrew command returned the configured Valet paths without displaying `Password:`**. The full output of this password-free run was not separately captured, so the important verified result is the absence of the prompt, not a reconstructed terminal transcript.

The difference is meaningful. Both commands accessed Valet, but the path used to invoke it affected whether a password was requested. This result strongly supported a mismatch between the executable selected through `PATH` and the executable allowed by Valet's sudoers configuration.

For a Mac where Homebrew is installed elsewhere, use the actual `valet` path found on that machine rather than copying `/opt/homebrew/bin/valet` blindly.

## Step 5: Prioritize the Working Valet Executable {#step-5-prioritize-the-working-valet-executable}

Once the Homebrew executable works without a password prompt, test a temporary change to the shell search order. Keeping this change temporary makes it easy to verify before modifying startup files.

```bash
export PATH="/opt/homebrew/bin:$PATH"
rehash
command -v valet
```

The `export` command prepends Homebrew's bin directory to the existing `PATH`. `rehash` refreshes Zsh's cached executable locations. `command -v valet` then reports which executable the shell will use.

For this setup, the intended result from `command -v valet` is `/opt/homebrew/bin/valet`. This is an expected path, not a verbatim terminal output captured during the original session.

Now repeat the test:

```bash
sudo -k
valet paths -v
```

The command should return the registered paths without requesting a password. If it still prompts, stop here and investigate the current executable path or sudoers configuration instead of assuming the issue is fixed.

This `PATH` change affects executable lookup for other Homebrew programs as well, not just Valet. It also lasts only for the current shell session.

## Step 6: Make the PATH Change Persistent {#step-6-make-the-path-change-persistent}

After verifying the temporary change, configure a future Zsh session to use the same search order. This is a recommended follow-up; the original troubleshooting session established a successful installer run, but it did not include a separately captured verification after opening a new Terminal session.

First, open the existing shell configuration:

```bash
nano ~/.zshrc
```

Inspect the file for existing `PATH` assignments. If the appropriate Homebrew priority is not already configured, add this line near the end, after other entries that may modify `PATH`:

```bash
export PATH="/opt/homebrew/bin:$PATH"
```

Save the file, then reload it:

```bash
source ~/.zshrc
rehash
```

The `source` command applies the updated configuration to the current shell. `rehash` refreshes Zsh's command lookup. Next, open a new Terminal window and verify both the selected executable and the password behavior:

```bash
command -v valet
sudo -k
valet paths -v
```

`command -v valet` should point to the intended Homebrew executable, and `valet paths -v` should complete without a password prompt. If the location changes again in a new session, review other shell startup files or environment managers that may reorder `PATH`.

## Step 7: Try It Out {#step-7-try-it-out}

The final test is to run the original workflow: create a Laravel application with the Laravel Installer. A successful standalone Valet command is useful, but a complete project creation confirms that the installer can proceed beyond its Valet check.

### Create a New Laravel Application

```bash
laravel new laravel-update-demo
```

This launches Laravel Installer's interactive project setup. In the successful session, **No** was selected for the starter kit and **Blade** was selected for the frontend stack.

The following is the actual successful terminal output from the session, preserving the original formatting:

```text
 ██╗       █████╗  ██████╗   █████╗  ██╗   ██╗ ███████╗ ██╗
 ██║      ██╔══██╗ ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ██║
 ██║      ███████║ ██████╔╝ ███████║ ██║   ██║ █████╗   ██║
 ██║      ██╔══██║ ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║
 ███████╗ ██║  ██║ ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ███████╗
 ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝  ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝

 ┌ Do you want to use a starter kit? ───────────────────────────┐
 │ No                                                           │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which frontend stack do you want to build on? ───────────────┐
 │ Blade                                                        │
 └──────────────────────────────────────────────────────────────┘

 • Creating Laravel application
   ✔ Application installed
   ✔ Application initialized

 • Running database migrations
   ✔ Database migrated

 • Setting up Pest
   ✔ Pest installed
   ✔ Pest initialized

 • Fixing test code style
   ✔ Test code style fixed

 • Setting up frontend dependencies with npm
   ✔ Packages installed
   ✔ Assets built

 • Setting up Laravel Boost for AI assisted coding
   ✔ Boost installed
   ✔ Boost initialized

 ┌ Application ready ───────────────────────────────────────────┐
 │ You can start your local development using:                  │
 │                                                              │
 │ 1. cd laravel-update-demo                                    │
 │ 2. composer run dev                                          │
 │                                                              │
 │ New to Laravel? Check out our documentation.                 │
 │                                                              │
 │ Build something amazing!                                     │
 └──────────────────────────────────────────────────────────────┘
```

Unlike the failed run, this installation advanced through migrations, Pest initialization, frontend asset compilation, and Laravel Boost setup. Most importantly, it reached **Application ready** without another password prompt or 60-second Valet timeout.

### Start the New Application

```bash
cd laravel-update-demo
composer run dev
```

The first command enters the newly created project. The second starts the development processes configured by Laravel's Composer script. Open the local URL printed by the development server to check the application in a browser.

The browser check is a follow-up readers can perform. The captured troubleshooting session confirms successful project creation, not a separately recorded browser result.

## Understanding Why the Executable Path Matters {#understanding-why-the-executable-path-matters}

The practical tests become easier to explain when looking at the relevant implementations. Laravel Installer and Laravel Valet handle different parts of this workflow, and the command path bridges them.

### Laravel Installer Checks for Parked Directories

In [Laravel Installer 5.32.0's `InteractsWithHerdOrValet` implementation](https://github.com/laravel/installer/blob/v5.32.0/src/Concerns/InteractsWithHerdOrValet.php), the installer tries the Herd and Valet command-line tools to determine whether a project directory is in a registered location. The Valet branch invokes `valet paths -v` through Symfony Process.

If that subprocess cannot complete, it can interrupt the later project setup steps. The default Symfony Process timeout explains why the terminal eventually reported 60 seconds rather than waiting indefinitely.

### Valet Can Reinvoke Its Script with Sudo

The [Valet 4.12.0 executable script](https://github.com/laravel/valet/blob/v4.12.0/valet#L786-L803) contains a branch that uses `sudo` to invoke the Valet script when the command is not already running as root. It passes along the executable path represented by its `SOURCE` variable.

This matters when a developer's shell resolves `valet` to a Composer binary path, but a different path is registered for passwordless execution.

### Valet Trust Uses a Specific Executable Path

The [Valet 4.12.0 `createSudoersEntry()` implementation](https://github.com/laravel/valet/blob/v4.12.0/cli/Valet/Valet.php#L67-L78) creates a sudoers rule referencing `BREW_PREFIX.'/bin/valet'`. The [official Valet documentation](https://laravel.com/docs/13.x/valet#other-valet-commands) describes `valet trust` as the command for setting up trusted Brew and Valet operations.

In the tested environment, `valet` initially resolved to the Composer executable, while `/opt/homebrew/bin/valet` was the Homebrew entry. The direct Homebrew invocation did not require a password, and a subsequent installation succeeded after changing command lookup priority.

That chain of observations strongly supports an executable path mismatch as the cause of this particular failure. It does not establish that every Laravel Installer timeout has the same root cause.

## Troubleshooting If the Password Prompt Remains {#troubleshooting-if-the-password-prompt-remains}

If the Homebrew executable still asks for a password, the comparison above has not isolated the same issue. Continue with read-only diagnostics before changing permissions or reinstalling tools.

Check the executable locations and current shell search order:

```bash
command -v valet
which -a valet
printf '%s\n' "$PATH"
```

These commands show the selected executable, other matching executables, and the directories searched by the shell. Look for startup scripts or environment managers that put another Composer bin directory ahead of Homebrew.

Next, run Valet's built-in diagnostic command:

```bash
valet diagnose
```

This gathers environment information that may reveal a different problem. If the output contains sensitive local configuration, review it before sharing publicly.

When necessary, ask a system administrator to inspect the effective sudoers configuration using the appropriate system tools. Avoid editing `/etc/sudoers` directly, adding blanket passwordless sudo privileges, removing Composer binaries, or changing executable permissions simply to suppress the prompt. Those actions are not required by the successful fix demonstrated here.

## Conclusion {#conclusion}

The timeout initially looked like a Laravel project creation failure. Reproducing the exact Valet command revealed a password prompt, and comparing executable paths narrowed the issue to the way Valet was invoked. Prioritizing the working Homebrew executable allowed Laravel Installer to complete its setup successfully.

- **Installer subprocess timeout.** An external Valet command can interrupt the Laravel installation workflow even after the project directory has been created.
- **Password prompt.** A Valet command that waits for sudo authentication can prevent an installer subprocess from finishing.
- **Executable path.** Composer and Homebrew may expose different paths for the same Valet package, and the path used to invoke the command can matter.
- **Valet trust.** A successful trust command does not guarantee that every Valet executable path will match the configured sudoers rule.
- **Temporary PATH fix.** Test the intended Homebrew executable and shell search order before making a permanent configuration change.
- **Final verification.** A complete `laravel new` run reaching `Application ready` is stronger evidence than a successful diagnostic command alone.
