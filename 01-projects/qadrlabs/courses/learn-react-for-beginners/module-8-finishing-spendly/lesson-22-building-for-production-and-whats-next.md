## 1. Before You Begin

Spendly is finished. Over twenty-one lessons, it grew from a heading and a tagline into a multi-page app: a live dashboard with totals, a spending bar, a currency converter, and a category breakdown; a searchable, filterable transaction list; detail and edit pages; a form with validation; monthly budgets; and data that survives a refresh. In Module 7, you also learned to read, review, and fix AI-generated code for it.

Until now, Spendly has only run on the Vite development server, which is built for writing code: it translates files on demand, reloads instantly, and runs extra checks. Real users need something else: a small set of optimized files that any web server can deliver quickly. In this final lesson, you will **build** Spendly for production, look at what Vite produces, preview the production version, and learn what a web host needs to serve a single-page app correctly. Then you will look back at every concept you used, and plan where to go next.

### What You'll Build

- A production build of Spendly in a `dist` folder: one HTML file, one JavaScript file, one CSS file, and the files from `public`.
- A local preview of that build at `http://localhost:4173`, working exactly like the development version, including direct links to pages such as `/transactions`.

### What You'll Learn

- ✅ The difference between the development server and a production build
- ✅ How to build a Vite app with `npm run build` and read the build report
- ✅ What is inside the `dist` folder and why file names contain hashes
- ✅ How to preview a production build with `npm run preview`
- ✅ What a web host needs to serve a single-page app with client-side routing
- ✅ How every Spendly feature maps to the React concepts in this course
- ✅ Where to go next as a React developer

### What You'll Need

- The finished Spendly project from Lesson 21
- A terminal in the `spendly` folder. Stop the development server with `Ctrl+C` before you start; you will not need it in this lesson.

---

## 2. Build Spendly for Production

The development server is convenient but heavy. It serves your source files one by one, translates JSX every time a file is requested, and includes React's development checks, such as the warnings about keys and the double rendering of `StrictMode`. A production build does all the translation once, ahead of time, combines everything into a few files, removes the development-only code, and shrinks the result.

### Step 1: Run the Build

Run the build script from Lesson 2's `package.json`:

```bash
npm run build
```

Output:

```text

> spendly@0.0.0 build
> vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 117 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.45 kB │ gzip:  0.29 kB
dist/assets/index-COzN_3z3.css    5.81 kB │ gzip:  1.41 kB
dist/assets/index-T_ABZElC.js   271.74 kB │ gzip: 85.37 kB

✓ built in 145ms
```

Here is how to read the report:

- `117 modules transformed` counts every JavaScript, JSX, and CSS file that went into the build: your 28 source files plus the code from React, React DOM, and React Router.
- **Rendering chunks** is the step where Vite combines those modules into a few output files.
- Each `dist/...` line is one output file with its size. The first number is the file's actual size; the `gzip` number is roughly how much data is transferred over the network, because web servers usually compress files before sending them. The whole of Spendly is about 87 kB compressed, most of it React and React Router.
- The file names `index-COzN_3z3.css` and `index-T_ABZElC.js` contain a **hash**, a short code calculated from the file's content. Your hashes will be different.

Before you build, it is also a good habit to run `npm run lint`, so you never ship code with known problems. You will automate that in Exercise 1.

### Step 2: Look Inside the dist Folder

The build created a new `dist` folder (short for "distribution") next to `src`. It contains everything a web server needs and nothing else:

```text
dist/
├── assets/
│   ├── index-COzN_3z3.css
│   └── index-T_ABZElC.js
├── categories.json
├── favicon.svg
└── index.html
```

`categories.json` and `favicon.svg` were copied unchanged from `public`, as Lesson 2 promised. Open `dist/index.html` in your editor:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Spendly</title>
    <script type="module" crossorigin src="/assets/index-T_ABZElC.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-COzN_3z3.css">
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
```

It is your `index.html` from Lesson 2, with one difference: the `<script>` tag that loaded `/src/main.jsx` has been replaced by tags for the built JavaScript and CSS files. The `<div id="root"></div>` is still empty; React still builds the whole page in the browser.

Open `dist/assets/index-T_ABZElC.js` and scroll through it. It is one enormous line of code with short, meaningless variable names. This is **minified** code: the build removed spaces, line breaks, and comments, and shortened names, to make the file as small as possible. Browsers read it just as well as your source code. You never edit files in `dist`; you edit `src` and build again.

The hashes in the file names solve an important problem. Browsers **cache** files, keeping copies so they do not have to download them again. If the file were always named `index.js`, a browser might keep using an old version after you publish an update. With a hash, every change to the code produces a new file name, so browsers download the new version automatically, while unchanged files can be cached for a long time.

The `dist` folder is already listed in `.gitignore`, because it can always be recreated from the source with `npm run build`.

### Step 3: Preview the Build

To check the production version before publishing it, Vite includes a small server that serves the `dist` folder:

```bash
npm run preview
```

Output:

```text

> spendly@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

The preview runs on port `4173`, not `5173`, so you never confuse it with the development server. Open `http://localhost:4173` and use Spendly as usual.

---

## 3. Run and Test

Test the production build the way a user would:

1. The Dashboard shows the summary, the converter, the category breakdown, and the recent transactions. Your data from the development server is **not** there: `localStorage` belongs to an address, and `localhost:4173` is a different address from `localhost:5173`. The app starts with the sample data, as it would for a new user.
2. Add, edit, and delete a transaction, set a budget, and switch currencies. Everything works as before.
3. Type `http://localhost:4173/transactions` directly into the address bar.

What the browser shows:

```text
Page: /transactions
Tab title: Spendly ($3,223)
```

The Transactions page appears with its filters and list. Like the development server, `vite preview` answers every unknown address with `index.html`, so React Router can show the right page.

4. Open the console. The message suggesting the React DevTools extension is gone, and if you add a `console.log` to a component, you will see it only once per render: the `StrictMode` double render and React's development warnings are not included in production builds.

When you change the code, the preview does **not** update by itself. Stop it, run `npm run build` again, and start the preview again. During development, keep using `npm run dev`.

---

## 4. Publishing Spendly

The `dist` folder is a **static site**: plain files that any web server can deliver, with no server-side code. Many hosting services publish static sites for free, usually by connecting to a Git repository and running `npm run build` for you. Popular choices include Netlify, Vercel, Cloudflare Pages, and GitHub Pages. Publishing is a matter of following your host's guide, so this course does not walk through a specific service. There is, however, one setting every single-page app with client-side routing needs, and AI-generated deployment instructions often forget it.

**Every address must return `index.html`.** When a user opens `/transactions/2` directly, or refreshes that page, the browser asks the server for the file `/transactions/2`. No such file exists in `dist`. The development server and `vite preview` handle this by returning `index.html` for unknown addresses, and React Router takes it from there. A plain web server does not: it answers with a 404 error. Hosts call the fix a "rewrite", a "redirect", or "SPA fallback". For example, on Netlify you add a file named `_redirects` to `public` with this line:

```text
/*    /index.html   200
```

It means "for any address, serve `/index.html` with a success status". Other hosts have an equivalent setting in their configuration file or dashboard; search your host's documentation for "single-page app" or "SPA".

**Remember where the data lives.** Spendly stores its transactions in each visitor's own browser with `localStorage`. Publishing the app does not give it a database: every visitor starts with the sample data, and nobody can see anyone else's transactions. That is fine for a personal tool, and it is the next big thing to learn if you want to build apps where data is shared, as Section 10 describes.

---

## 5. What You Built

Here is the final structure of Spendly's source code:

```text
spendly/
├── public/
│   ├── categories.json
│   └── favicon.svg
├── src/
│   ├── components/
│   │   ├── CategoryBreakdown.jsx
│   │   ├── CurrencyConverter.jsx
│   │   ├── Filters.jsx
│   │   ├── Header.jsx
│   │   ├── Layout.jsx
│   │   ├── Summary.jsx
│   │   ├── TransactionForm.jsx
│   │   ├── TransactionItem.jsx
│   │   └── TransactionList.jsx
│   ├── context/
│   │   ├── TransactionsContext.js
│   │   └── TransactionsProvider.jsx
│   ├── data/
│   │   └── transactions.js
│   ├── hooks/
│   │   ├── useFetch.js
│   │   ├── useLocalStorage.js
│   │   └── useTransactions.js
│   ├── pages/
│   │   ├── AddTransactionPage.jsx
│   │   ├── BudgetsPage.jsx
│   │   ├── DashboardPage.jsx
│   │   ├── EditTransactionPage.jsx
│   │   ├── NotFoundPage.jsx
│   │   ├── TransactionDetailPage.jsx
│   │   └── TransactionsPage.jsx
│   ├── utils/
│   │   ├── format.js
│   │   └── transactions.js
│   ├── App.css
│   ├── App.jsx
│   ├── index.css
│   └── main.jsx
├── index.html
├── package.json
└── vite.config.js
```

And here is how each feature maps to the concepts behind it:

| Feature | React concepts | Lessons |
| --- | --- | --- |
| Header, cards, and lists | JSX, components, props, `children` | 3, 4, 5 |
| Transaction list with empty state | `map`, keys, conditional rendering | 6 |
| Green incomes, red expenses, spending bar | `className` from data, inline styles | 7 |
| Buttons and search box | Event handlers, callback props | 8 |
| Adding transactions | `useState`, immutable updates | 9 |
| Transaction form with validation | Controlled inputs, `onSubmit`, `Number` | 10 |
| Editing and deleting | `filter`, `map`, object spread, `key` reset | 11 |
| Search shared by filter and list | Lifting state up | 12 |
| Live totals, category filter, sorting | Derived data | 13 |
| Data that survives a refresh, tab title | `useEffect`, `localStorage` | 14 |
| Categories file and currency converter | `fetch`, loading and error states, cleanup | 15 |
| `useLocalStorage` and `useFetch` | Custom hooks | 16 |
| Dashboard, Transactions, and Add pages | React Router, layout routes, `NavLink` | 17 |
| Detail and edit pages | Dynamic routes, `useParams`, `useNavigate` | 18 |
| Data available on every page | Context, providers, `useContext` | 19 |
| Spending by category | Reading AI code, `reduce`, `useMemo` | 20 |
| Budgets | Reviewing and fixing AI code | 21 |

Every row is a skill you can now use in any React project, and recognize in any React code, whether a person or an AI wrote it.

---

## 6. Fix the Errors in Your Code

These are the most common surprises the first time a React app leaves the development server.

**Error 1: Opening dist/index.html directly from the file system.**

It is tempting to double-click `dist/index.html`, the way you opened `counter.html` in Lesson 1. The browser shows a completely blank page, and the console shows errors like these:

```text
Access to script at 'file:///assets/index-T_ABZElC.js' from origin 'null' has been blocked by CORS policy: Cross origin requests are only supported for protocol schemes: chrome, chrome-experimental-site-token-provider, chrome-extension, chrome-untrusted, data, http, https, isolated-app.
Failed to load resource: net::ERR_FAILED
```

```bash
# Wrong
# double-clicking dist/index.html, which opens file:///.../dist/index.html

# Correct
npm run build
npm run preview
```

The built files use addresses that start with `/`, such as `/assets/index-T_ABZElC.js`, which only make sense on a web server. On the file system, `/assets` points to the root of your disk. Browsers also refuse to load JavaScript modules from `file://` addresses for security reasons. A production build must be served over `http`, by `vite preview` locally or by a host online.

**Error 2: Deep links returning 404 on a plain web server.**

Any simple static server shows the problem from Section 4. For example, serving `dist` with Python's built-in server and opening `/` works, but opening `/transactions` directly returns an error page:

```text
Error response
Error code: 404
Message: File not found.
Error code explanation: 404 - Nothing matches the given URI.
```

The difference between a host that fails and one that works:

```text
# Wrong
A host that only serves files that exist in dist.

# Correct
A host configured to answer every unknown address with index.html,
such as Netlify with "/*    /index.html   200" in public/_redirects.
```

Clicking links inside the app still works, because React Router changes the address without asking the server. Only direct visits and refreshes fail, which is why this bug is often discovered only after publishing. Test every published app by opening a deep link in a new tab.

**Error 3: Previewing an old build.**

You fix a bug, open `http://localhost:4173`, and the bug is still there.

```bash
# Wrong
npm run preview

# Correct
npm run build
npm run preview
```

`vite preview` only serves what is already in `dist`; it does not look at `src`. Every change needs a new build before it appears in the preview, or on a host. Hosts that connect to a Git repository run the build automatically on every push, which is one of the main reasons to use them.

---

## 7. Exercises

**Exercise 1:** Add a script named `check` to `package.json` that runs the linter and then the build, and stops if the linter finds an error. Run it with `npm run check`.

**Exercise 2:** Add a `<meta name="description">` tag to `index.html` with a one-sentence description of Spendly. Rebuild, and confirm that the tag appears in `dist/index.html`. How much did `index.html` grow?

**Exercise 3:** Change the value of `--color-primary` in `src/index.css`, build again, and compare the file names in the build report with the previous build. Which hashes changed? Then change the color back.

---

## 8. Solutions

**Solution for Exercise 1:**

Add the script to the `scripts` section of `package.json`:

```json
"scripts": {
  "dev": "vite",
  "build": "vite build",
  "lint": "oxlint",
  "preview": "vite preview",
  "check": "npm run lint && npm run build"
}
```

`&&` runs the second command only if the first one succeeds. Oxlint exits with an error when it finds an error-level problem, such as a broken rule of hooks, so the build never runs on code with known errors.

```bash
npm run check
```

Output:

```text

> spendly@0.0.0 check
> npm run lint && npm run build


> spendly@0.0.0 lint
> oxlint


> spendly@0.0.0 build
> vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 117 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.55 kB │ gzip:  0.34 kB
dist/assets/index-COzN_3z3.css    5.81 kB │ gzip:  1.41 kB
dist/assets/index-T_ABZElC.js   271.74 kB │ gzip: 85.37 kB

✓ built in 142ms
```

This output already includes the description tag from Exercise 2, which is why `index.html` is `0.55 kB` instead of `0.45 kB`. Many teams run a script like this automatically before every deployment.

**Solution for Exercise 2:**

Add the tag inside `<head>` in `index.html`, before `<title>`:

```html
<meta name="description" content="Spendly is a personal expense tracker built with React." />
```

Search engines and link previews in chat apps often show this description. After `npm run build`, `dist/index.html` contains the same line:

```html
<meta name="description" content="Spendly is a personal expense tracker built with React." />
```

The build report shows `dist/index.html` at `0.55 kB` instead of `0.45 kB`, about 100 bytes larger, exactly the size of the new line. The JavaScript and CSS files keep their names, because their content did not change.

**Solution for Exercise 3:**

Changing `--color-primary` from `#4f46e5` to `#4338ca` and building again gives this report:

```text
dist/index.html                   0.55 kB │ gzip:  0.33 kB
dist/assets/index-ClgrEOs3.css    5.81 kB │ gzip:  1.41 kB
dist/assets/index-D2B4126t.js   271.74 kB │ gzip: 85.37 kB
```

The CSS file's hash changed, from `COzN_3z3` to `ClgrEOs3`, because its content changed. The JavaScript file's hash changed too, because the JavaScript contains a reference to the CSS file's name. A browser that cached the old files will download both new ones, so every visitor sees the new color immediately. After changing the color back and building again, the old names `index-COzN_3z3.css` and `index-T_ABZElC.js` return: the same content always produces the same hash.

---

## 9. Course Wrap-Up and Next Steps

You started this course knowing some HTML, CSS, and JavaScript, or maybe none at all. You finish it having built a complete React application from an empty folder, one concept at a time, and having reviewed and fixed React code written by AI.

Look at what you can do now:

- Set up a React project with Vite, and understand every file in it.
- Build interfaces from components, pass data with props, and style them from data.
- Make them interactive with events, state, and controlled forms, updating state immutably.
- Decide where state should live, and derive everything that can be calculated.
- Synchronize with the outside world using effects, `localStorage`, and APIs, with loading and error states.
- Package logic into custom hooks, split an app into pages with React Router, and share data with context.
- Read unfamiliar React code, review it with a checklist, and fix the bugs AI tools commonly produce.
- Build and preview a production version of your app.

That last group of skills is why this course exists. AI tools will keep getting better at writing code, but someone still has to know whether the code is right. You now can.

Here are good next steps, roughly in the order many developers take them:

1. **Make Spendly your own.** Add a feature without following a lesson: a monthly filter (you wrote the prompt for it in Lesson 20), recurring transactions, export to CSV, or a dark theme. Use an AI assistant if you like, and review its code with the checklist from Lesson 21.
2. **Publish it.** Deploy the `dist` folder to a free static host, set up the SPA fallback from Section 4, and share the link.
3. **Learn TypeScript.** TypeScript adds types to JavaScript, so mistakes such as comparing a string id with a number (Lesson 18) or passing the wrong props (Lesson 20) are caught before the code runs. Vite has a `react-ts` template, and most React jobs and AI-generated projects use it.
4. **Write tests.** Tools such as Vitest and React Testing Library let you check automatically that a component shows the right content and responds to clicks, so you can change code with confidence.
5. **Add a backend.** To share data between devices and users, Spendly needs a server and a database. You already know how to fetch data from an API; the next step is building one. The qadrlabs course "[Learn Laravel for Beginners](https://qadrlabs.com/course/learn-laravel-for-beginners)" builds exactly that kind of application with PHP, and a Laravel API could replace Spendly's `localStorage`.
6. **Explore a React framework.** Next.js and React Router's framework mode add server rendering, file-based routing, and data loading on top of everything you learned here. They are where much of the React ecosystem, and much AI-generated code, is heading.

Whatever you build next, keep the habits from this course: build in small steps, run the code after every change, read the console, keep state minimal, derive the rest, and never ship code you do not understand. Congratulations on finishing Learn React for Beginners, and happy building!
