---
title: "How to Install Node.js on Android Using Termux"
slug: "how-to-install-nodejs-on-android-using-termux"
category: "How To Install"
date: "2026-05-08"
status: "published"
---

This tutorial is part of the [Persiapan Belajar Coding di HP](https://qadrlabs.com/series/persiapan-belajar-coding-di-hp) series. In the previous articles, we covered how to set up Termux as your Android terminal environment. Now it is time to take the next step: getting Node.js up and running so you can write and execute JavaScript directly from your phone.

Many developers assume that a laptop or desktop is a hard requirement for learning Node.js. That assumption stops a lot of people from getting started. If your only device right now is an Android phone, Termux removes that barrier completely. With just a few commands, you can have a fully functional Node.js environment, run JavaScript files, and manage packages with npm — all without touching a computer.

## Overview {#overview}

In this tutorial, you will go from a fresh Termux installation to a working Node.js setup. You will verify the install, write your first script, and initialize a real npm project with an external package.

### What You'll Build

- A working Node.js runtime environment inside Termux on Android
- A simple JavaScript file that runs from the terminal
- An npm project directory with an installed package and a runnable script

### What You'll Learn

- Why you should install Termux from F-Droid instead of the Play Store
- How to update Termux packages before installing anything new
- How to install Node.js LTS using the `pkg` package manager
- How to verify that Node.js and npm are correctly installed
- How to create and run a `.js` file from the Termux terminal
- How to initialize an npm project and install a third-party package

### What You'll Need

- An Android smartphone running Android 7.0 (Nougat) or higher
- An active internet connection
- Termux installed from [F-Droid](https://f-droid.org/packages/com.termux/) — not from the Google Play Store
- No prior Node.js knowledge required; basic familiarity with the terminal helps

## Step 1: Install Termux from F-Droid {#step-1-install-termux}

Before anything else, make sure you have the correct version of Termux installed. This is one of the most common points of confusion for beginners.

The version on the Google Play Store has not received updates for years. It is frozen at an old API level and will fail to install many modern packages, including Node.js. The actively maintained version lives on F-Droid, which is a free and open-source app repository for Android.

### Install F-Droid

Go to [f-droid.org](https://f-droid.org) from your Android browser and download the F-Droid APK. You will need to allow installation from unknown sources in your Android settings. The exact path varies by device, but it is usually under **Settings > Security > Install Unknown Apps**.

### Install Termux via F-Droid

Once F-Droid is installed, open it, search for **Termux**, and install it. After installation, open Termux and wait for it to finish its initial setup. You should see a command prompt that looks like this:

```
Welcome to Termux!

Community forum  : https://termux.com/community
Gitter chat      : https://gitter.im/termux/termux
IRC channel      : #termux on libera.chat

Working with packages:

 * Search packages:   pkg search <query>
 * Install a package: pkg install <package>
 * Upgrade packages:  pkg upgrade

$
```

That prompt means Termux is ready. You can now proceed.

## Step 2: Update Termux Packages {#step-2-update-packages}

The first thing you should always do in a fresh Termux environment is update the package repository and upgrade any existing packages. This ensures that the package index is current and avoids version conflicts when installing new software.

Run the following command:

```bash
pkg update && pkg upgrade
```

This command does two things in sequence. `pkg update` fetches the latest list of available packages from the Termux repository mirrors. `pkg upgrade` then upgrades any installed packages that have newer versions available. When prompted with a `[Y/n]` confirmation, type `y` and press Enter to proceed.

The process may take a few minutes depending on your connection speed. You will see a lot of output scrolling by — that is normal. Wait until the prompt returns before moving on.

## Step 3: Install Node.js {#step-3-install-nodejs}

With Termux up to date, you are ready to install Node.js. Termux provides two variants in its repository: `nodejs` (the latest release) and `nodejs-lts` (the Long Term Support release).

For most learning purposes and projects, **LTS is the better choice**. LTS versions receive bug fixes and security patches for an extended period, making them more stable than cutting-edge releases. Unless you specifically need a feature from the latest version, stick with LTS.

### Install Node.js LTS

```bash
pkg install nodejs-lts
```

Termux will resolve the dependencies automatically and ask for confirmation. Type `y` and press Enter. The installation includes both the `node` runtime and `npm` (Node Package Manager).

### Install Build Tools

Some npm packages include native C/C++ code that needs to be compiled during installation. Without the right build tools, those installs will fail. Install them now to avoid surprises later:

```bash
pkg install build-essential python
```

`build-essential` provides the GCC compiler, `make`, and related tools. `python` is required by some npm packages (like `node-gyp`) that use Python scripts during their build process. Having both installed from the start saves a lot of debugging time down the road.

## Step 4: Verify the Installation {#step-4-verify}

Before writing any code, confirm that Node.js and npm are correctly installed and accessible from the terminal.

```bash
node -v
```

You should see output similar to:

```
v24.14.1
```

Now check npm:

```bash
npm -v
```

Expected output:

```
11.14.0
```

The exact version numbers may differ depending on when you install, but as long as both commands return a version number without an error, everything is working correctly.

## Step 5: Run Your First Node.js Script {#step-5-first-script}

Now that Node.js is installed, write a small script to confirm that the runtime executes JavaScript as expected.

### Create the file

Use `nano`, which is a simple terminal text editor, to create a new file:

```bash
nano hello.js
```

`nano` opens an in-terminal editor. You will see a blank screen with a toolbar at the bottom showing keyboard shortcuts.

### Write the script

Type the following code into the editor:

```js
// hello.js
const name = "Termux";
const message = `Hello from Node.js running on ${name}!`;
console.log(message);
```

This script declares a string variable, uses a template literal to build a message, and prints it to the console. It is simple on purpose — the goal here is just to confirm that the Node.js runtime works end to end.

### Save and exit

Press `Ctrl + O` to write the file, then press `Enter` to confirm the filename. Press `Ctrl + X` to exit the editor.

### Run the script

```bash
node hello.js
```

Expected output:

```
Hello from Node.js running on Termux!
```

If you see that message, your Node.js installation is fully functional.

## Step 6: Initialize an NPM Project {#step-6-npm-project}

Running a single script file is useful for quick experiments, but real projects are organized as npm packages with a `package.json` file that tracks metadata and dependencies. This step walks you through creating that structure.

### Create a project directory

```bash
mkdir my-project && cd my-project
```

`mkdir my-project` creates a new folder. `cd my-project` moves you into it. Always work inside a dedicated folder for each project to keep your files organized.

### Initialize the project

```bash
npm init -y
```

The `-y` flag tells npm to accept all default values without asking questions interactively. This generates a `package.json` file immediately. You can inspect it:

```bash
cat package.json
```

Expected output:

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

### Install a package

Install `chalk`, a popular npm package for adding color to terminal output:

```bash
npm install chalk
```

npm will download `chalk` and its dependencies into a `node_modules` folder, and it will add an entry to `package.json` under `"dependencies"`.

Note: `chalk` version 5 and above uses ES Modules. Since we want to keep things simple, the script below uses `import` syntax. To support this, add `"type": "module"` to your `package.json`.

Open `package.json` with nano:

```bash
nano package.json
```

Add `"type": "module"` as a top-level field:

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "description": "",
  "type": "module",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

Save with `Ctrl + O`, confirm with `Enter`, and exit with `Ctrl + X`.

### Create and run the script

```bash
nano index.js
```

Write the following:

```js
// index.js
import chalk from "chalk";

console.log(chalk.green("Node.js is running on Android!"));
console.log(chalk.blue("Package installed via npm works perfectly."));
console.log(chalk.yellow("Happy coding from Termux!"));
```

`chalk.green()`, `chalk.blue()`, and `chalk.yellow()` wrap text with ANSI color codes so the terminal displays the output in the specified colors. This confirms that npm package installation and ES Module imports both work correctly.

Save and exit, then run it:

```bash
node index.js
```

Expected output (with colors in your terminal):

```
Node.js is running on Android!
Package installed via npm works perfectly.
Happy coding from Termux!
```

Each line will appear in green, blue, and yellow respectively.

## Troubleshooting Common Issues {#troubleshooting}

Even with a clean install, you may run into a few common problems. Here is how to handle them.

### Mirror or repository errors during `pkg update`

If `pkg update` hangs or throws a network error, Termux may be pointing to a slow or unavailable mirror. You can change the mirror by running:

```bash
termux-change-repo
```

This opens an interactive menu. Select a mirror that is geographically close to you, such as one in Asia if you are in Indonesia. Retry `pkg update` afterward.

### npm install fails with build errors

If an npm package fails to install with errors mentioning `gyp`, `make`, or `gcc`, it means the package requires native compilation and the build tools are missing. Go back to Step 3 and run:

```bash
pkg install build-essential python
```

Then retry the npm install.

### Termux from Play Store does not work

If packages fail to install or you see errors about API levels or outdated repositories, you are likely using the Play Store version of Termux. Uninstall it, get Termux from [F-Droid](https://f-droid.org/packages/com.termux/), and start fresh.

## Conclusion {#conclusion}

You now have a fully working Node.js environment running directly on your Android phone through Termux. Here is a summary of what you covered:

- **F-Droid is the only reliable source for Termux.** The Play Store version is outdated and will cause package installation failures. Always use the F-Droid release.
- **`pkg update && pkg upgrade` should always be your first command.** Keeping the package index current prevents version mismatch errors before they happen.
- **`nodejs-lts` is the recommended install target.** LTS releases are more stable and receive longer support compared to the latest cutting-edge version.
- **Build tools are not optional for serious projects.** Installing `build-essential` and `python` upfront prevents hard-to-debug npm install failures later.
- **npm projects start with `npm init -y`.** This creates the `package.json` file that tracks your project metadata and dependencies.
- **ES Modules require `"type": "module"` in `package.json`.** Modern npm packages like `chalk` v5 use ESM by default, and Node.js needs this flag to handle `import` syntax correctly.