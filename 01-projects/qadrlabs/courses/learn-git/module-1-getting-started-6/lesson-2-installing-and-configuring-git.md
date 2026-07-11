## 1. Before You Begin

Before you can use any Git command, Git must be installed on your machine and configured with your identity. Every commit you make records your name and email address, so Git needs to know who you are before you make your first commit. This lesson walks through installation on all major operating systems and the essential first-time configuration steps that every developer runs exactly once on a new machine.

This lesson covers installing Git on Windows, macOS, and Linux, verifying the installation, and configuring your identity (name and email). You will also set the default branch name to `main` and choose a default text editor. By the end, running `git --version` will confirm everything is ready.

### What You'll Build

You will set up a fully configured Git environment: Git installed, your name and email registered globally, the default branch set to `main`, and your preferred editor selected. This environment is what every lesson from Lesson 3 onward depends on.

### What You'll Learn

- ✅ Installing Git on Windows, macOS, and Linux
- ✅ Verifying the installation with `git --version`
- ✅ Configuring your name and email with `git config`
- ✅ Setting the default branch name to `main`
- ✅ Choosing a default editor
- ✅ Viewing your configuration with `git config --list`

### What You'll Need

- A computer running Windows, macOS, or Linux
- An internet connection for downloading Git
- A terminal (Command Prompt/PowerShell on Windows, Terminal on macOS/Linux)

---

## 2. Install Git

Git installation varies by operating system. Follow the instructions for your platform below. If you are unsure which operating system you are running, check your system settings before proceeding.

### Windows

Download the installer from the official Git website.

```
https://git-scm.com/download/win
```

Visit the URL above in your browser and download the installer for your system (usually the 64-bit version). Run the downloaded `.exe` file. During installation, accept the default settings with one recommendation: when asked about the default editor, select **VS Code** if you have it installed. When asked about the default branch name, select **Override the default branch name** and type `main`.

After installation, open **Git Bash** (installed alongside Git) or **PowerShell** and verify the installation.

```bash
git --version
```

You should see output like `git version 2.47.0.windows.1` (the exact version number may differ). If you see "command not found," restart your terminal and try again. If it still fails, the installer may not have added Git to your system PATH - reinstall and make sure to select "Git from the command line and also from 3rd-party software."

### macOS

macOS may include an older version of Git, but you should install the latest version via Homebrew for proper updates. The easiest method is through Homebrew.

```bash
brew install git
```

The `brew install git` command downloads and installs the latest stable version of Git from the Homebrew package repository. If you do not have Homebrew installed yet, visit `https://brew.sh` and follow the one-line installation instruction shown on the homepage. After the installation completes, verify:

```bash
git --version
```

You should see `git version 2.47.0` or higher. If the version shown is older (for example, `2.24.x` from Apple's built-in tools), your terminal may still be pointing to the system Git. Run `which git` to confirm the path is `/opt/homebrew/bin/git` or `/usr/local/bin/git`.

### Linux (Ubuntu/Debian)

On Ubuntu and Debian-based systems, install Git using the system package manager. First update the package list, then install.

```bash
sudo apt update
sudo apt install git
```

`sudo apt update` refreshes the list of available packages from the configured repositories. `sudo apt install git` then downloads and installs the Git package. After the installation finishes, verify:

```bash
git --version
```

You should see `git version 2.43.0` or higher. On other Linux distributions (Fedora, Arch, etc.), replace `apt` with your distribution's package manager (`dnf`, `pacman`, etc.).

---

## 3. Configure Your Identity

Git attaches your name and email to every commit. This is how teammates know who made each change, and how GitHub links your commits to your account. Configure these settings once, and they apply to all repositories on your machine.

### Step 1: Set Your Name

Open a terminal and run the following command, replacing the name in quotes with your own full name.

```bash
git config --global user.name "Budi Santoso"
```

This stores your name in the global Git configuration file at `~/.gitconfig` on macOS/Linux, or `C:\Users\YourName\.gitconfig` on Windows. The `--global` flag means this setting applies to every repository you work with on this machine. Without `--global`, the setting would only apply to the current repository directory.

### Step 2: Set Your Email

Run the following command, replacing the email with the one you plan to use for your GitHub account.

```bash
git config --global user.email "budi@example.com"
```

Use the same email address you will use when signing up for GitHub. GitHub uses this email to link your commits to your account dashboard and contribution graph. If the email does not match your GitHub account, your commits will show as unlinked.

### Step 3: Set the Default Branch Name

Older versions of Git name the first branch in a new repository `master` by default. The modern convention across the industry is `main`. Run the following command to set this preference globally.

```bash
git config --global init.defaultBranch main
```

This ensures every new repository you create starts with a branch named `main` instead of `master`. This setting was introduced in Git 2.28, so if you installed an older version, update Git first.

### Step 4: Set the Default Editor

When Git needs you to write a commit message in certain situations (such as when you forget the `-m` flag), it opens a text editor. Set VS Code as that editor so the experience is familiar.

```bash
git config --global core.editor "code --wait"
```

The `--wait` flag is critical: it tells Git to pause and wait until you close the VS Code tab before continuing the Git operation. Without `--wait`, Git would continue immediately while the editor is still open, which causes Git to receive an empty commit message. If you prefer a terminal-based editor, you can use `git config --global core.editor "nano"` instead.

---

## 4. Verify Your Configuration

After setting everything up, verify that all values were saved correctly before creating your first repository.

```bash
git config --list --global
```

You should see output similar to:

```
user.name=Budi Santoso
user.email=budi@example.com
init.defaultbranch=main
core.editor=code --wait
```

`git config --list --global` reads and prints every key-value pair stored in your global `~/.gitconfig` file. If a value is missing, it was not set. If a value is wrong, re-run the appropriate `git config --global` command to overwrite it.

You can also check individual values when you only need to verify one setting at a time.

```bash
git config user.name
git config user.email
```

Each command prints the current value for that specific key. This is faster than reading the full list when you only need to confirm one setting is correct.

---

## 5. Run and Test

Before moving on to Lesson 3, verify that the complete setup is working correctly by running a quick sanity check. This sequence tests every piece of the configuration you just applied.

### Step 1: Check Git Version

Run the version check to confirm Git is installed and accessible from your terminal.

```bash
git --version
```

Expected output: `git version 2.x.x` (any version 2.28 or higher is fine for all lessons in this course).

### Step 2: Check Your Identity

Confirm your name and email are saved correctly.

```bash
git config user.name
git config user.email
```

Expected output: your name on the first line and your email on the second line. If either is blank, re-run the `git config --global` commands from Section 3.

### Step 3: Check the Default Branch

Confirm the default branch setting is applied.

```bash
git config init.defaultBranch
```

Expected output: `main`. If you see nothing or see `master`, re-run Step 3 from Section 3.

### Step 4: Quick Sanity Test

The most reliable test is to create a temporary repository and observe the default branch name in action.

```bash
mkdir git-test
cd git-test
git init
git branch
```

The `git init` command should print "Initialized empty Git repository." The `git branch` command may show nothing (no commits yet means no branch is displayed), or it may show `* main`. If it shows `* master`, your `init.defaultBranch` setting did not apply correctly - re-run the config command from Step 3 of Section 3.

After testing, clean up the temporary folder.

```bash
cd ..
rm -rf git-test
```

On Windows using PowerShell, use `Remove-Item -Recurse -Force git-test` instead of the `rm -rf` command, since `rm -rf` is a Linux/macOS syntax.

---

## 6. Fix the Errors in Your Code

These are the most common installation and configuration problems and how to resolve them.

**Error 1: Git not found after installation.**

After running the installer, the terminal reports "git: command not found" or "git is not recognized." This happens because Git's executable was not added to the system's PATH environment variable during installation.

```bash
# Wrong: Git was installed but terminal cannot find it
git --version
# bash: git: command not found

# Correct: reinstall and choose the right PATH option
# On Windows: reinstall, select "Git from the command line and also from 3rd-party software"
# On macOS: run xcode-select --install to install command line tools
# Then restart the terminal and verify
git --version
# git version 2.47.0
```

Restarting the terminal is always the first step. The terminal reads PATH only when it starts, so installing Git while the terminal is open means the old PATH (without Git) is still active.

**Error 2: Commits show blank or system name as the author.**

This happens when you make a commit before running `git config --global user.name` and `git config --global user.email`. Git falls back to the system hostname or leaves the fields empty.

```bash
# Wrong: committed before configuring identity
git log --oneline
# a1b2c3d (unknown) Initial commit

# Correct: configure identity first, then commit
git config --global user.name "Budi Santoso"
git config --global user.email "budi@example.com"
git commit -m "Initial commit"
```

If you have already committed with the wrong identity, the commit is stored with that name. For future commits, configuring the identity now is enough. To amend the most recent commit's author, you can use `git commit --amend --reset-author` - this will be covered in Lesson 16.

**Error 3: Default branch shows as `master` instead of `main`.**

After running `git init`, the first branch is named `master` even though you ran `git config --global init.defaultBranch main`. This typically means the installed Git version is older than 2.28, which does not support the `init.defaultBranch` setting.

```bash
# Wrong: old Git version ignores the defaultBranch config
git init
git branch
# * master

# Correct: update Git, then rename the existing branch
git branch -m master main
git branch
# * main
```

`git branch -m master main` renames the `master` branch to `main` without affecting commits or history. After renaming, all future work on that repository uses `main`. To avoid this situation in new repositories, update Git to 2.28 or higher.

---

## 7. Exercises

**Exercise 1:** Run `git config --list --global` and verify all four settings are correct (name, email, default branch, editor). Copy the output to a text file for your own reference.

**Exercise 2:** Check your Git version. If it is older than 2.40, update to the latest version from `git-scm.com`. Compare the version numbers before and after.

**Exercise 3:** Create a temporary repository with `git init`, verify the default branch is `main` using `git branch`, then delete the test folder. This rehearses the workflow you will use in Lesson 3.

---

## 8. Solutions

**Solution for Exercise 1:**

Run the following command to read back every global configuration setting.

```bash
git config --list --global
```

Expected output (with your own values):

```
user.name=Your Name
user.email=your@email.com
init.defaultbranch=main
core.editor=code --wait
```

`git config --list --global` reads the `~/.gitconfig` file and prints each setting as a `key=value` pair. If any key is missing, it was never set. Re-run the corresponding `git config --global <key> <value>` command to add it.

**Solution for Exercise 2:**

Run the version check first to see your current version.

```bash
git --version
```

Visit `https://git-scm.com` and compare the displayed version with the latest release shown on the homepage. On Windows, download and run the new installer (it overwrites the old version automatically). On macOS with Homebrew, run `brew upgrade git`. On Ubuntu/Debian, run `sudo apt update && sudo apt upgrade git`. After updating, run `git --version` again to confirm the new version is active.

**Solution for Exercise 3:**

Run the following sequence to create a temporary repository, inspect the default branch, and clean up.

```bash
mkdir test-repo
cd test-repo
git init
git branch
cd ..
rm -rf test-repo
```

The `git init` output should say "Initialized empty Git repository in .../test-repo/.git/". The `git branch` command may print nothing (because no commit has been made yet) or print `* main`. Both are correct - the branch exists, but Git only displays it in `git branch` output once at least one commit exists. The absence of output does not mean the configuration failed.

---

## 9. Understanding Git Configuration Levels

Git's configuration system has three levels, each with a different scope, and each more specific level overrides the more general one. Understanding this hierarchy prevents confusion when settings seem to not apply.

**System** configuration is stored in `/etc/gitconfig` (or `C:\ProgramData\Git\config` on Windows) and applies to every user on the machine. This is typically set by a system administrator and not something you modify directly.

**Global** configuration is stored in `~/.gitconfig` and applies to all repositories for your user account. This is the level you configure with `--global`, and it is what you have been setting in this lesson.

**Local** configuration is stored in `.git/config` inside a specific repository and applies only to that repository. Running `git config user.name "Different Name"` without `--global` writes to the local config for the current repository only.

When you run `git config --global user.name "Budi"`, Git writes to `~/.gitconfig`. When you run `git config user.name "Work Name"` inside a specific repository (without `--global`), Git writes to `.git/config` for that repository. The local setting overrides the global one for that repository only - useful when you contribute to a work project with a different email than your personal projects.

---

## Next Up - Lesson 3

Git is now installed and configured on your machine. The `git config --global` command saved your name, email, preferred branch name, and editor to the global configuration file. These settings apply to every repository you create and are the foundation every future lesson depends on. Configuration works in three layers: system, global, and local, with more specific layers overriding more general ones.

In Lesson 3, you will create your first Git repository, write your first tracked file, and make your first commit to start building the portfolio project that runs throughout the course.