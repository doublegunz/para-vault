## 1. Before You Begin

In Lesson 1, you saw a React counter, met Spendly, and modeled Spendly's transactions with plain JavaScript in the browser console. The React counter could not run yet, because React code is not loaded into a page the way a plain `<script>` tag is. It needs a few tools to turn JSX into normal JavaScript and serve it to the browser.

In this lesson you will install those tools and create the real Spendly project. You will install Node.js, which also gives you npm, use Vite to generate a React project, start a development server, and watch the browser update the moment you save a file. Then you will take a tour of every file in the project and clean up the starter code so that Spendly is ready for Module 2.

### What You'll Build

A fresh React project named `spendly`, running on your computer at `http://localhost:5173`. By the end of the lesson, the starter page is replaced by Spendly's first screen: a heading and a short tagline, styled with a light background.

### What You'll Learn

- ✅ What Node.js, npm, and Vite are, and why a React project needs them
- ✅ How to install Node.js and check the installed versions
- ✅ How to create a React project with `npm create vite`
- ✅ How to install dependencies with `npm install` and start the development server with `npm run dev`
- ✅ What hot module replacement is and how it speeds up your work
- ✅ What each file and folder in a Vite React project does
- ✅ How to remove the starter code and prepare a clean project

### What You'll Need

- A computer running Windows, macOS, or Linux
- A terminal: Command Prompt or PowerShell on Windows, Terminal on macOS and Linux. The integrated terminal in Visual Studio Code also works well.
- Visual Studio Code or another text editor
- An internet connection to download Node.js and the project packages

---

## 2. Install Node.js and npm

React code is written in files that browsers cannot run directly: they contain JSX and import other files by name. Before the browser sees them, a tool has to translate and bundle that code. These tools are written in JavaScript and run outside the browser, on your computer, using **Node.js**.

Node.js is a program that runs JavaScript outside a browser. You will not write Node.js code in this course, but the tools you use need it. Node.js comes with **npm** (Node Package Manager), a command-line tool that downloads JavaScript libraries, called packages, from the npm registry and runs project commands. React itself is a package, and so is Vite.

### Step 1: Download and Install Node.js

Open `https://nodejs.org` in your browser and download the version labeled **LTS** (Long Term Support). LTS versions are the stable ones recommended for most people. This course was tested with Node.js 24, and any LTS version from 22 upward works with the tools used here.

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
v24.22.1
11.19.1
```

Your numbers may be different, and that is fine as long as Node.js is version 22 or newer. If the terminal says `command not found` or `'node' is not recognized`, the installation did not finish or the terminal was opened before installing. Open a new terminal and try again, and reinstall if it still fails.

---

## 3. Create the Spendly Project with Vite

You could set up a React project by hand, but it would take dozens of configuration steps. Instead, you will use **Vite** (pronounced "veet", the French word for "fast"). Vite is a build tool: during development it serves your files to the browser and translates JSX on the fly, and when you are done it bundles everything into small files ready for production. Vite also provides a project generator that creates a working React project in seconds.

### Step 1: Generate the Project

In the terminal, move to the folder where you keep your projects, for example your home folder or a `projects` folder, and run this command.

```bash
npm create vite@latest spendly -- --template react --no-interactive
```

Here is what each part means:

- `npm create vite@latest` downloads and runs the latest version of Vite's project generator, called `create-vite`.
- `spendly` is the name of the project. The generator creates a folder with this name.
- `--` tells npm that the remaining options belong to `create-vite`, not to npm.
- `--template react` chooses the React template with plain JavaScript. There is also a `react-ts` template for TypeScript, which this course does not use.
- `--no-interactive` tells the generator to use its default answers instead of asking questions. Without it, the generator asks which linter to use and whether to install and start the project immediately. Skipping the questions keeps your output identical to this lesson, and you will run each step yourself.

The first time you run the command, npm may ask `Need to install the following packages: create-vite` followed by `Ok to proceed? (y)`. Press `Enter` or type `y` to continue.

Output:

```text
> npx
> 'cva' spendly --template react --no-interactive


create-vite v9.3.1

│
◇  Scaffolding project in /home/gun-gun-priatna/obsidian-vault/sandbox/spendly...
│
└  Done. Now run:

  cd spendly
  npm install
  npm run dev

```

"Scaffolding" means generating the starting files. The path after "Scaffolding project in" shows where the folder was created, so yours will be different. The version of `create-vite` may also be newer when you run it. The last three lines tell you exactly what to do next.

### Step 2: Install the Dependencies

Move into the new folder and install the packages the project needs.

```bash
cd spendly
npm install
```

`cd spendly` changes the current folder to the project folder. Every command from now on must be run inside this folder. `npm install` reads the list of packages in `package.json`, downloads them from the npm registry, and saves them in a new folder named `node_modules`.

Output:

```text
added 24 packages, and audited 25 packages in 26s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

npm installed 24 packages, including React, React DOM, and Vite. The "looking for funding" message only means some package authors accept donations; you can ignore it. The number of packages and the time may differ slightly on your computer.

### Step 3: Start the Development Server

Start Vite's development server.

```bash
npm run dev
```

`npm run dev` runs the script named `dev` from `package.json`, which starts Vite. Vite then waits for the browser to request files and translates them as they are needed.

Output:

```text

> spendly@0.0.0 dev
> vite


  VITE v8.3.5  ready in 196 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

The important line is `Local: http://localhost:5173/`. `localhost` means "this computer", and `5173` is the port number Vite listens on. In an interactive terminal you will also see a line saying `press h + enter to show help`.

Open `http://localhost:5173` in your browser. You will see Vite's starter page with the React and Vite logos, a "Get started" heading, and a button labeled `Count is 0`. Click the button a few times: the number goes up. That button is a React component very similar to the counter from Lesson 1, and now it is running on your computer.

Leave the server running while you work. The terminal is now busy with Vite, so if you need to run other commands, open a second terminal window or tab in the same folder. To stop the server, click the terminal and press `Ctrl+C`.

---

## 4. Tour the Project Files

Open the `spendly` folder in Visual Studio Code with **File > Open Folder**. A React project has more files than a single HTML page, but each one has a clear job. Here is what the generator created:

```text
spendly/
├── node_modules/        (installed packages, created by npm install)
├── public/
│   ├── favicon.svg
│   └── icons.svg
├── src/
│   ├── assets/
│   │   ├── hero.png
│   │   ├── react.svg
│   │   └── vite.svg
│   ├── App.css
│   ├── App.jsx
│   ├── index.css
│   └── main.jsx
├── .gitignore
├── .oxlintrc.json
├── index.html
├── package-lock.json
├── package.json
├── README.md
└── vite.config.js
```

| File or folder | What it does |
| --- | --- |
| `index.html` | The single HTML page of the app. It contains an empty `<div id="root"></div>` and loads `src/main.jsx`. |
| `src/main.jsx` | The entry point. It finds the `root` div and tells React to render the `App` component inside it. |
| `src/App.jsx` | The main component, the top of Spendly's component tree. You will edit this file constantly. |
| `src/index.css` | Global styles that apply to the whole page. |
| `src/App.css` and `src/assets/` | Styles and images used only by the starter page. You will delete them. |
| `public/` | Files copied as they are, such as the favicon (the small icon in the browser tab). |
| `package.json` | The project's identity card: its name, the scripts you can run, and the packages it depends on. |
| `package-lock.json` | The exact version of every installed package, so everyone who installs the project gets the same versions. Never edit it by hand. |
| `node_modules/` | The installed packages. It is large, it is listed in `.gitignore`, and you can always recreate it with `npm install`. |
| `vite.config.js` | Vite's settings. The React plugin is already enabled. |
| `.oxlintrc.json` | Settings for Oxlint, a linter that checks your code for common mistakes. |

Two files deserve a closer look, because together they explain how React reaches the screen. First, `index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>spendly</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
```

The body contains almost nothing: an empty `div` with the id `root` and a script tag that loads `src/main.jsx`. Every piece of Spendly you will ever see is created by React inside that one empty `div`. This is why a React app is often called a single-page application.

Now `src/main.jsx`:

```jsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
```

Line by line:

- `import { StrictMode } from 'react'` loads `StrictMode`, a helper component that turns on extra checks during development.
- `import { createRoot } from 'react-dom/client'` loads the function that connects React to a real page. React itself describes the interface; React DOM puts it into the browser.
- `import './index.css'` applies the global stylesheet. Vite lets you import CSS files from JavaScript.
- `import App from './App.jsx'` loads the `App` component from the file next to it.
- `createRoot(document.getElementById('root'))` finds the empty `div` from `index.html` and turns it into the place where React renders. You already know `getElementById` from the JavaScript Basics course; this is the only time you will need it in a React app.
- `.render(<StrictMode><App /></StrictMode>)` renders the `App` component inside it. `<App />` is how you use a component in JSX: like an HTML tag whose name starts with a capital letter.

The generated files use single quotes and no semicolons. The code you write in this course uses double quotes and semicolons, the same style as the JavaScript Basics course. JavaScript accepts both styles, so the two can live in the same project. You will not need to change `main.jsx` at all.

---

## 5. Make the Project Yours

The starter page is useful for checking that everything works, but Spendly needs a clean slate. In this section you will replace the starter component, remove the files you no longer need, and watch Vite update the browser without a refresh.

### Step 1: Replace the App Component

Make sure the development server is still running. Open `src/App.jsx`, delete everything inside it, and type the following code.

```jsx
function App() {
  return (
    <main>
      <h1>Spendly</h1>
      <p>Track where your money goes.</p>
    </main>
  );
}

export default App;
```

Here is what this code does:

- `function App()` declares the component. A React component is a JavaScript function whose name starts with a capital letter.
- `return ( ... );` returns the JSX that should appear on the screen. The parentheses let the JSX span several lines.
- `<main>`, `<h1>`, and `<p>` are ordinary HTML elements written in JSX. A component must return a single outer element, so `<main>` wraps the heading and the paragraph.
- `export default App;` makes the component available to other files. This is what allows `main.jsx` to write `import App from './App.jsx'`.

Save the file and look at the browser without refreshing it. The page changes to Spendly's heading almost instantly. This feature is called **hot module replacement** (HMR): Vite notices the saved file, sends only the changed module to the browser, and React swaps it in. You will rely on it in every lesson.

What you see in the browser:

```text
Spendly

Track where your money goes.
```

The text uses the browser's default font, because the starter styles in `index.css` were written for the starter page. You will replace them next.

### Step 2: Remove the Starter Files

The new `App.jsx` no longer imports `App.css` or any image, so those files are unused. Delete these files and folders in Visual Studio Code (right-click, then **Delete**):

- `src/App.css`
- `src/assets/` (the whole folder, with `hero.png`, `react.svg`, and `vite.svg`)
- `public/icons.svg`

Keep `public/favicon.svg`, because `index.html` uses it for the browser tab icon.

### Step 3: Write Simple Global Styles

Open `src/index.css`, delete all of its contents, and replace them with these styles.

```css
body {
  margin: 0;
  padding: 24px;
  font-family: system-ui, "Segoe UI", Roboto, sans-serif;
  background-color: #f5f6fa;
  color: #1f2937;
}
```

Here is what each rule does:

- `margin: 0;` removes the default space browsers add around the page, and `padding: 24px;` adds a comfortable space inside it instead.
- `font-family` uses the operating system's own interface font, falling back to common alternatives.
- `background-color: #f5f6fa;` gives the page a very light grey background, and `color: #1f2937;` makes the text dark grey instead of pure black, which is easier on the eyes.

Save the file. The browser updates again, this time with the new font and background. You will build Spendly's full design in Lesson 7.

### Step 4: Change the Page Title

Open `index.html` and change the title from `spendly` to `Spendly`.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Spendly</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
```

The only change is the text inside `<title>`, which is shown in the browser tab. Save the file and the tab now reads "Spendly".

Your project now looks like this:

```text
spendly/
├── node_modules/
├── public/
│   └── favicon.svg
├── src/
│   ├── App.jsx
│   ├── index.css
│   └── main.jsx
├── .gitignore
├── .oxlintrc.json
├── index.html
├── package-lock.json
├── package.json
├── README.md
└── vite.config.js
```

---

## 6. Run and Test

Check that everything still works from a fresh start. Stop the server with `Ctrl+C`, then start it again.

```bash
npm run dev
```

Output:

```text

> spendly@0.0.0 dev
> vite


  VITE v8.3.5  ready in 196 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

Open `http://localhost:5173`. The browser tab says "Spendly", and the page shows the heading "Spendly" and the tagline "Track where your money goes." on a light grey background.

Next, check the code with the linter. Open a second terminal in the `spendly` folder, so the server can keep running, and run this command.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

```

Oxlint prints nothing after its header when it finds no problems. Later in the course, when you make a mistake such as calling a React hook in the wrong place, this command will point to the exact line.

If you use Git, this is a good moment to save your work with a first commit. The `.gitignore` file already excludes `node_modules`, so only your own files are committed.

---

## 7. Fix the Errors in Your Code

These are the most common problems when starting a React project with Vite.

**Error 1: Running `npm run dev` outside the project folder.**

npm looks for `package.json` in the current folder. If you open a new terminal and forget to move into `spendly`, there is no `package.json` to read.

```bash
# Wrong
npm run dev

# Correct
cd spendly
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
npm error A complete log of this run can be found in: /home/gun-gun-priatna/.npm/_logs/2026-10-26T15_21_16_416Z-debug-0.log
```

`ENOENT` stands for "Error: no entry", meaning the file does not exist. The `path` line shows where npm looked. Move into the folder that contains `package.json` and run the command again.

**Error 2: Forgetting `npm install`.**

The `node_modules` folder is not part of the project you generate or download; it is created by `npm install`. If you skip that step, or clone a project from GitHub and start it immediately, the `vite` command is not available yet.

```bash
# Wrong
cd spendly
npm run dev

# Correct
cd spendly
npm install
npm run dev
```

Without `node_modules`, the wrong version prints this on Linux and macOS:

```text

> spendly@0.0.0 dev
> vite

sh: 1: vite: not found
```

On Windows the message says that `'vite' is not recognized as an internal or external command`. Run `npm install` once, then start the server again.

**Error 3: Deleting a file that is still imported.**

If you delete `App.css` while `App.jsx` still contains `import "./App.css";`, Vite cannot find the file.

```jsx
// Wrong
import "./App.css";

function App() {
  return (
    <main>
      <h1>Spendly</h1>
      <p>Track where your money goes.</p>
    </main>
  );
}

export default App;

// Correct
function App() {
  return (
    <main>
      <h1>Spendly</h1>
      <p>Track where your money goes.</p>
    </main>
  );
}

export default App;
```

With the wrong version, the browser shows a red error overlay instead of the page, with this message:

```text
[plugin:vite:import-analysis] Failed to resolve import "./App.css" from "src/App.jsx". Does the file exist?
```

The terminal running the server shows the same message, with the file name and line number. Whenever you delete a file, search the project for its name (`Ctrl+Shift+F` in Visual Studio Code) and remove every import that still points to it.

---

## 8. Exercises

**Exercise 1:** Add a second paragraph under the tagline in `App.jsx` that says `Built with React and Vite.` Save the file and confirm the browser updates without a refresh.

**Exercise 2:** The development server uses port `5173` by default. Stop the server and start it on port `3000` instead by running `npm run dev -- --port 3000`. Which line of the output changes, and what URL do you open in the browser?

**Exercise 3:** Without looking back at Section 4, explain in your own words how the text "Spendly" travels from `App.jsx` to the screen. Mention `index.html`, `main.jsx`, and the `root` element in your answer.

---

## 9. Solutions

**Solution for Exercise 1:**

Add the new paragraph inside `<main>`, after the existing one.

```jsx
function App() {
  return (
    <main>
      <h1>Spendly</h1>
      <p>Track where your money goes.</p>
      <p>Built with React and Vite.</p>
    </main>
  );
}

export default App;
```

The new `<p>` element must be inside `<main>`, because a component returns a single outer element. When you save, hot module replacement updates the page immediately, and the browser shows three lines: the heading, the tagline, and the new paragraph. Remove the extra paragraph afterward if you want your project to match the next lesson exactly.

**Solution for Exercise 2:**

Run the server with the `--port` option.

```bash
npm run dev -- --port 3000
```

As with `npm create`, the `--` passes the option through npm to Vite. The `Local:` line of the output changes from `http://localhost:5173/` to `http://localhost:3000/`, and that is the URL you open in the browser. The project itself does not change; only the address does. Stop the server and run plain `npm run dev` again to go back to port `5173`, which the rest of the course uses.

**Solution for Exercise 3:**

The browser first loads `index.html`, which contains an empty `<div id="root"></div>` and a script tag that loads `src/main.jsx`. Vite translates `main.jsx`, and its code imports the `App` component from `App.jsx`. `main.jsx` then finds the `root` element with `document.getElementById('root')`, creates a React root there with `createRoot`, and renders `<App />` into it. React calls the `App` function, receives the JSX with the `<h1>Spendly</h1>` heading, and creates the matching HTML elements inside the `root` div. That is how the text appears on the screen.

---

## Next Up - Lesson 3

In this lesson you installed Node.js and npm, created the Spendly project with Vite, installed its dependencies, and started the development server. You toured every file in the project, learned how `index.html`, `main.jsx`, and `App.jsx` work together to put React on the screen, and replaced the starter page with Spendly's first, clean screen.

In Lesson 3, you will learn JSX properly: how to insert JavaScript values into your markup with curly braces, which rules make JSX different from HTML, and how to use those rules to build the first real piece of Spendly's interface.
