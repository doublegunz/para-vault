## 1. Before You Begin

In Lesson 1, you built a counter with Vue loaded from a CDN, met Tasklane, and modeled Tasklane's cards with plain JavaScript in the browser console. Loading Vue with one `<script>` tag is perfect for small experiments, but a real app is made of many component files, each with its own template, script, and styles. Browsers cannot read those `.vue` files directly, so a real Vue project needs a few tools that turn them into normal JavaScript and serve them to the browser.

In this lesson you will install those tools and create the real Tasklane project. You will install Node.js, which also gives you npm, use Vue's official project generator to create a project powered by Vite, start a development server, and watch the browser update the moment you save a file. Then you will take a tour of every file in the project and clean up the starter code so that Tasklane is ready for Module 2.

### What You'll Build

A fresh Vue project named `tasklane`, running on your computer at `http://localhost:5173`. By the end of the lesson, the starter page is replaced by Tasklane's first screen: a heading and a short tagline on a light grey background.

### What You'll Learn

- ✅ What Node.js, npm, Vite, and create-vue are, and why a Vue project needs them
- ✅ How to install Node.js and check the installed versions
- ✅ How to create a Vue project with `npm create vue@latest`
- ✅ How to install dependencies with `npm install` and start the development server with `npm run dev`
- ✅ What hot module replacement is and how it speeds up your work
- ✅ What each file and folder in a Vue project does, including the three blocks of a `.vue` file
- ✅ How to add global styles and check your code with `npm run lint`

### What You'll Need

- A computer running Windows, macOS, or Linux
- A terminal: Command Prompt or PowerShell on Windows, Terminal on macOS and Linux. The integrated terminal in Visual Studio Code also works well.
- Visual Studio Code or another text editor
- An internet connection to download Node.js and the project packages

---

## 2. Install Node.js and npm

Vue components are written in `.vue` files, which browsers cannot run directly. Before the browser sees them, a tool has to translate them into normal JavaScript and CSS. These tools are written in JavaScript and run outside the browser, on your computer, using **Node.js**.

Node.js is a program that runs JavaScript outside a browser. You will not write Node.js code in this course, but the tools you use need it. Node.js comes with **npm** (Node Package Manager), a command-line tool that downloads JavaScript libraries, called packages, from the npm registry and runs project commands. Vue itself is a package, and so is Vite.

### Step 1: Download and Install Node.js

Open `https://nodejs.org` in your browser and download the version labeled **LTS** (Long Term Support). LTS versions are the stable ones recommended for most people. The project generator used in this lesson needs Node.js 22.18 or newer, or Node.js 24.12 or newer, so any current LTS version works.

- **Windows and macOS:** run the downloaded installer and accept the default options. npm is installed together with Node.js.
- **Linux:** the download page offers instructions for installing with a version manager such as nvm or through your distribution's package manager. Follow the steps shown for your system.

When the installer finishes, close any terminal windows that were already open and open a new one, so the terminal picks up the new commands.

### Step 2: Check the Installed Versions

Run these two commands in the terminal.

```bash
node --version
npm --version
```

`node --version` prints the version of Node.js, and `npm --version` prints the version of npm. If both commands print a version number, the installation worked.

Output:

```text
v26.13.0
11.20.0
```

Your numbers may be different, and that is fine as long as Node.js meets the version requirement above. If the terminal says `command not found` or `'node' is not recognized`, the installation did not finish or the terminal was opened before installing. Open a new terminal and try again, and reinstall if it still fails.

---

## 3. Create the Tasklane Project

You could set up a Vue project by hand, but it would take many configuration steps. Instead, you will use **create-vue**, the official project generator from the Vue team. It creates a project that uses **Vite** (pronounced "veet", the French word for "fast") as its build tool. During development, Vite serves your files to the browser and translates `.vue` files on the fly. When you are done, it bundles everything into small files ready for production.

### Step 1: Generate the Project

In the terminal, move to the folder where you keep your projects, for example your home folder or a `projects` folder, and run this command.

```bash
npm create vue@latest tasklane -- --eslint --bare
```

Here is what each part means:

- `npm create vue@latest` downloads and runs the latest version of create-vue.
- `tasklane` is the name of the project. The generator creates a folder with this name.
- `--` tells npm that the remaining options belong to create-vue, not to npm.
- `--eslint` adds ESLint and Oxlint, two tools that check your code for common mistakes.
- `--bare` creates a minimal project without the example components, so you have less starter code to delete.

Because you passed options, create-vue does not ask any questions and uses JavaScript (not TypeScript), which is what this course uses. If you run `npm create vue@latest` without options, it asks about each feature one by one instead. Vue Router and Pinia are not added now; you will install them yourself in Module 6, so you understand what each one does.

The first time you run the command, npm may ask `Need to install the following packages: create-vue` followed by `Ok to proceed? (y)`. Press `Enter` or type `y` to continue.

Output:

```text
> npx
> 'create-vue' tasklane --eslint --bare

┌  Vue.js - The Progressive JavaScript Framework

Scaffolding project in /home/gun-gun-priatna/obsidian-vault/sandbox/tasklane...
│
└  Done. Now run:

   cd tasklane
   npm install
   npm run dev

| Optional: Initialize Git in your project directory with:

   git init && git add -A && git commit -m "initial commit"
```

"Scaffolding" means generating the starting files. The path after "Scaffolding project in" shows where the folder was created, so yours will be different. The last part tells you exactly what to do next, and suggests creating a Git repository, which is a good habit if you already use Git.

### Step 2: Install the Dependencies

Move into the new folder and install the packages the project needs.

```bash
cd tasklane
npm install
```

`cd tasklane` changes the current folder to the project folder. Every command from now on must be run inside this folder. `npm install` reads the list of packages in `package.json`, downloads them from the npm registry, and saves them in a new folder named `node_modules`.

Output:

```text
added 222 packages, and audited 223 packages in 24s

57 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

npm installed Vue, Vite, the linters, and the packages they depend on. The "looking for funding" message only means some package authors accept donations; you can ignore it. The number of packages and the time may differ slightly on your computer.

### Step 3: Start the Development Server

Start Vite's development server.

```bash
npm run dev
```

`npm run dev` runs the script named `dev` from `package.json`, which starts Vite. Vite then waits for the browser to request files and translates them as they are needed.

Output:

```text

> tasklane@0.0.0 dev
> vite


  VITE v8.3.5  ready in 409 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  Vue DevTools: Open http://localhost:5173/__devtools__/ as a separate window
  ➜  Vue DevTools: Press Alt(⌥)+Shift(⇧)+D in App to toggle the Vue DevTools
```

The important line is `Local: http://localhost:5173/`. `localhost` means "this computer", and `5173` is the port number Vite listens on. The two Vue DevTools lines tell you how to open a panel that shows your components and their data, which is handy later in the course. In an interactive terminal you will also see a line saying `press h + enter to show help`.

Open `http://localhost:5173` in your browser.

What you see in the browser:

```text
You did it!

Visit vuejs.org to read the documentation
```

That page is a Vue component, running on your computer. Leave the server running while you work. The terminal is now busy with Vite, so if you need to run other commands, open a second terminal window or tab in the same folder. To stop the server, click the terminal and press `Ctrl+C`.

---

## 4. Tour the Project Files

Open the `tasklane` folder in Visual Studio Code with **File > Open Folder**. Visual Studio Code may suggest installing the recommended extensions for this project. Accept, or at least install **Vue (Official)**, which adds syntax highlighting and error checking for `.vue` files. Here is what the generator created:

```text
tasklane/
├── .vscode/
│   ├── extensions.json
│   └── settings.json
├── node_modules/        (installed packages, created by npm install)
├── public/
│   └── favicon.ico
├── src/
│   ├── App.vue
│   └── main.js
├── .editorconfig
├── .gitattributes
├── .gitignore
├── .oxlintrc.json
├── eslint.config.js
├── index.html
├── jsconfig.json
├── package-lock.json
├── package.json
├── README.md
└── vite.config.js
```

| File or folder | What it does |
| --- | --- |
| `index.html` | The single HTML page of the app. It contains an empty `<div id="app"></div>` and loads `src/main.js`. |
| `src/main.js` | The entry point. It creates the Vue app from the `App` component and mounts it into the `app` div. |
| `src/App.vue` | The root component, the top of Tasklane's component tree. You will edit this file constantly. |
| `public/` | Files copied as they are, such as the favicon (the small icon in the browser tab). |
| `package.json` | The project's identity card: its name, the scripts you can run, and the packages it depends on. |
| `package-lock.json` | The exact version of every installed package, so everyone who installs the project gets the same versions. Never edit it by hand. |
| `node_modules/` | The installed packages. It is large, it is listed in `.gitignore`, and you can always recreate it with `npm install`. |
| `vite.config.js` | Vite's settings. The Vue plugin and the Vue DevTools plugin are already enabled. |
| `eslint.config.js` and `.oxlintrc.json` | Settings for ESLint and Oxlint, the linters that check your code. |
| `jsconfig.json` | Tells your editor that `@/` is a shortcut for the `src/` folder. |
| `.editorconfig`, `.gitattributes`, `.vscode/` | Editor and Git settings, such as using two spaces for indentation. |

Three files deserve a closer look, because together they explain how Vue reaches the screen. First, `index.html`:

```html
<!DOCTYPE html>
<html lang="">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="/favicon.ico">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vite App</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
```

The body contains almost nothing: an empty `div` with the id `app` and a script tag that loads `src/main.js`. Every piece of Tasklane you will ever see is created by Vue inside that one empty `div`, exactly like the `<div id="app">` in Lesson 1's counter. This is why a Vue app like this one is called a single-page application.

Now `src/main.js`:

```javascript
import { createApp } from 'vue'
import App from './App.vue'

createApp(App).mount('#app')
```

Line by line:

- `import { createApp } from 'vue'` loads the `createApp` function from the Vue package installed in `node_modules`. In Lesson 1 you took it from the global `Vue` object instead.
- `import App from './App.vue'` loads the root component from the file next to it.
- `createApp(App)` creates a Vue app that starts with the `App` component.
- `.mount('#app')` finds the element with the id `app` in `index.html` and renders the app inside it.

Finally, `src/App.vue`:

```vue
<script setup></script>

<template>
  <h1>You did it!</h1>
  <p>
    Visit <a href="https://vuejs.org/" target="_blank" rel="noopener">vuejs.org</a> to read the
    documentation
  </p>
</template>

<style scoped></style>
```

This is a **single-file component** (SFC), the format every Vue component in this course uses. It has up to three blocks:

- `<script setup>` holds the component's JavaScript. It is empty here. In Lesson 1, you returned `count` from `setup()` to make it available in the template; with `<script setup>`, everything you declare in this block is available in the template automatically.
- `<template>` holds the HTML-like markup that the component renders.
- `<style scoped>` holds CSS. The word `scoped` means the styles apply only to this component, not to the rest of the page.

You will learn each block in detail in Lessons 3 and 4. The generated files use single quotes and no semicolons. The code you write in this course uses double quotes and semicolons, the same style as the JavaScript Basics course. JavaScript accepts both styles, so the two can live in the same project.

---

## 5. Make the Project Yours

The starter page is useful for checking that everything works, but Tasklane needs its own first screen. In this section you will replace the starter component, add global styles, and watch Vite update the browser without a refresh.

### Step 1: Replace the App Component

Make sure the development server is still running. Open `src/App.vue`, delete everything inside it, and type the following code.

```vue
<script setup></script>

<template>
  <main>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>
  </main>
</template>
```

Here is what this code does:

- `<script setup></script>` is empty for now. Tasklane's data will live here from Lesson 3 onward.
- `<template>` contains ordinary HTML: a `<main>` element that wraps a heading and a paragraph.
- There is no `<style>` block. A block you do not need can simply be left out.

Save the file and look at the browser without refreshing it. The page changes to Tasklane's heading almost instantly. This feature is called **hot module replacement** (HMR): Vite notices the saved file, sends only the changed module to the browser, and Vue swaps it in. You will rely on it in every lesson.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.
```

The text uses the browser's default font and white background. You will change that next.

### Step 2: Add Global Styles

Some styles, such as the font and the page background, apply to the whole app rather than to one component. They belong in a global stylesheet. Create a new folder named `assets` inside `src`, and inside it create a file named `main.css` with these styles.

```css
body {
  margin: 0;
  padding: 24px;
  font-family: system-ui, "Segoe UI", Roboto, sans-serif;
  background-color: #f4f5f7;
  color: #1f2937;
}
```

Here is what each rule does:

- `margin: 0;` removes the default space browsers add around the page, and `padding: 24px;` adds a comfortable space inside it instead.
- `font-family` uses the operating system's own interface font, falling back to common alternatives.
- `background-color: #f4f5f7;` gives the page a very light grey background, the color of a board that cards can sit on. `color: #1f2937;` makes the text dark grey instead of pure black, which is easier on the eyes.

A CSS file does nothing until something loads it. Open `src/main.js` and add an import for the new file.

```javascript
import { createApp } from 'vue'
import App from './App.vue'
import './assets/main.css'

createApp(App).mount('#app')
```

The only new line is `import './assets/main.css'`. Vite lets you import a CSS file from JavaScript; it adds the styles to the page for you. Because the import happens in the entry point, the styles apply to every component. Save the file, and the browser updates with the new font and background.

### Step 3: Change the Page Title and Language

Open `index.html`, set the `lang` attribute to `en`, and change the title to `Tasklane`.

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="/favicon.ico">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tasklane</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
```

`lang="en"` tells browsers and screen readers that the page is in English. The text inside `<title>` is shown in the browser tab. Save the file and the tab now reads "Tasklane".

Your project now looks like this:

```text
tasklane/
├── node_modules/
├── public/
│   └── favicon.ico
├── src/
│   ├── assets/
│   │   └── main.css
│   ├── App.vue
│   └── main.js
├── eslint.config.js
├── index.html
├── package.json
├── vite.config.js
└── (the other configuration files)
```

---

## 6. Run and Test

Check that everything still works from a fresh start. Stop the server with `Ctrl+C`, then start it again.

```bash
npm run dev
```

Output:

```text

> tasklane@0.0.0 dev
> vite


  VITE v8.3.5  ready in 409 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  Vue DevTools: Open http://localhost:5173/__devtools__/ as a separate window
  ➜  Vue DevTools: Press Alt(⌥)+Shift(⇧)+D in App to toggle the Vue DevTools
```

Open `http://localhost:5173`. The browser tab says "Tasklane", and the page shows the heading and the tagline on a light grey background.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.
```

Next, check the code with the linters. Open a second terminal in the `tasklane` folder, so the server can keep running, and run this command.

```bash
npm run lint
```

Output:

```text

> tasklane@0.0.0 lint
> run-s "lint:*"


> tasklane@0.0.0 lint:oxlint
> oxlint . --fix


> tasklane@0.0.0 lint:eslint
> eslint . --fix --cache

```

`npm run lint` runs two scripts one after the other: Oxlint, a very fast linter, and then ESLint with the official Vue rules. Neither prints anything after its header, which means they found no problems. The `--fix` option lets them repair simple style problems automatically. Later in the course, when you make a mistake such as using a variable that does not exist, this command will point to the exact file and line.

If you use Git, this is a good moment to save your work with a first commit. The `.gitignore` file already excludes `node_modules`, so only your own files are committed.

---

## 7. Fix the Errors in Your Code

These are the most common problems when starting a Vue project.

**Error 1: Running `npm run dev` outside the project folder.**

npm looks for `package.json` in the current folder. If you open a new terminal and forget to move into `tasklane`, there is no `package.json` to read.

```bash
# Wrong
npm run dev

# Correct
cd tasklane
npm run dev
```

The wrong version fails with an error like this:

```text
npm error code ENOENT
npm error syscall open
npm error path /home/gun-gun-priatna/obsidian-vault/sandbox/package.json
npm error errno -2
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/home/gun-gun-priatna/obsidian-vault/sandbox/package.json'
npm error enoent This is related to npm not being able to find a file.
npm error enoent
npm error A complete log of this run can be found in: /home/gun-gun-priatna/.npm/_logs/2026-10-29T16_11_00_311Z-debug-0.log
```

`ENOENT` stands for "Error: no entry", meaning the file does not exist. The `path` line shows where npm looked. Move into the folder that contains `package.json` and run the command again.

**Error 2: Forgetting `npm install`.**

The `node_modules` folder is not part of the project you generate or download; it is created by `npm install`. If you skip that step, or clone a project from GitHub and start it immediately, the `vite` command is not available yet.

```bash
# Wrong
cd tasklane
npm run dev

# Correct
cd tasklane
npm install
npm run dev
```

Without `node_modules`, the wrong version prints this on Linux and macOS:

```text

> tasklane@0.0.0 dev
> vite

sh: 1: vite: not found
```

On Windows the message says that `'vite' is not recognized as an internal or external command`. Run `npm install` once, then start the server again.

**Error 3: A typo in an import path.**

An import path must match the real file name exactly. One swapped letter is enough to break the whole page.

```javascript
// Wrong
import { createApp } from 'vue'
import App from './App.vue'
import './assets/mian.css'

createApp(App).mount('#app')

// Correct
import { createApp } from 'vue'
import App from './App.vue'
import './assets/main.css'

createApp(App).mount('#app')
```

With the wrong version, the browser shows a red error overlay instead of the page, with this message:

```text
[plugin:vite:import-analysis] Failed to resolve import "./assets/mian.css" from "src/main.js". Does the file exist?
```

The terminal running the server shows the same message, with the file name and the line number. The same error appears if the file was created in the wrong folder or deleted. Check that the folder is `src/assets` and the file name is exactly `main.css`, then save again. Whenever you rename or delete a file, search the project for its name (`Ctrl+Shift+F` in Visual Studio Code) and update every import that still points to it.

---

## 8. Exercises

**Exercise 1:** Add a second paragraph under the tagline in `App.vue` that says `Built with Vue and Vite.` Save the file and confirm the browser updates without a refresh.

**Exercise 2:** The development server uses port `5173` by default. Stop the server and start it on port `3000` instead by running `npm run dev -- --port 3000`. Which line of the output changes, and what URL do you open in the browser?

**Exercise 3:** Without looking back at Section 4, explain in your own words how the text "Tasklane" travels from `App.vue` to the screen. Mention `index.html`, `main.js`, `createApp`, and `mount` in your answer.

---

## 9. Solutions

**Solution for Exercise 1:**

Add the new paragraph inside `<main>`, after the existing one.

```vue
<script setup></script>

<template>
  <main>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>
    <p>Built with Vue and Vite.</p>
  </main>
</template>
```

When you save, hot module replacement updates the page immediately, and the browser shows three lines: the heading, the tagline, and the new paragraph. Remove the extra paragraph afterward if you want your project to match the next lesson exactly.

**Solution for Exercise 2:**

Run the server with the `--port` option.

```bash
npm run dev -- --port 3000
```

As with `npm create`, the `--` passes the option through npm to Vite. The `Local:` line of the output changes from `http://localhost:5173/` to `http://localhost:3000/`, and so does the Vue DevTools address. Open `http://localhost:3000` in the browser. The project itself does not change; only the address does. Stop the server and run plain `npm run dev` again to go back to port `5173`, which the rest of the course uses.

**Solution for Exercise 3:**

The browser first loads `index.html`, which contains an empty `<div id="app"></div>` and a script tag that loads `src/main.js`. Vite translates `main.js` and everything it imports, including `App.vue`, into JavaScript the browser understands. In `main.js`, `createApp(App)` creates a Vue app whose root component is `App`, and `.mount('#app')` tells Vue to render that app inside the element with the id `app`. Vue then renders the template of `App.vue`, which contains `<h1>Tasklane</h1>`, and creates the matching HTML elements inside the `app` div. That is how the text appears on the screen.

---

## Next Up - Lesson 3

In this lesson you installed Node.js and npm, created the Tasklane project with create-vue, installed its dependencies, and started the Vite development server. You toured every file in the project, learned how `index.html`, `main.js`, and `App.vue` work together to put Vue on the screen, met the three blocks of a single-file component, added global styles, and checked your code with the linters.

In Lesson 3, you will learn Vue's template syntax properly: how to show JavaScript values with double curly braces, which expressions are allowed inside them, and how to bind attributes with `v-bind`. You will use these tools to display Tasklane's first real card.
