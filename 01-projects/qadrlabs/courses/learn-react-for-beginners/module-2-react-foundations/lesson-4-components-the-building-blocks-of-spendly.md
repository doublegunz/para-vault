## 1. Before You Begin

In Lesson 3, you learned JSX and built the first version of Spendly's dashboard: a header with the logo, a welcome message, a summary with a colored balance, and a search box. All of it lives inside one `App` function. That works for a few elements, but Spendly will soon have a transaction list, a form, filters, and several pages. Keeping everything in one function would turn `App.jsx` into hundreds of lines that are hard to read and harder to change.

React's answer is **components**. In this lesson you will split Spendly's page into small, focused components, each in its own file, and assemble them in `App` like building blocks. By the end, `App` will be just a few lines long, and each part of the page will have a clear home. This matches the component tree you saw in Lesson 1.

### What You'll Build

Four components, each in its own file inside a new `src/components` folder:

- `Header` shows the logo, the app name, and the welcome message.
- `Summary` shows income, expense, and balance.
- `Filters` holds the search box.
- `TransactionList` shows a list of five transactions.

`App` imports all four and places them on the page.

### What You'll Learn

- ✅ What a component is and the two rules every component follows
- ✅ How to define a component and use it as a custom JSX tag
- ✅ How to move a component into its own file with `export default`
- ✅ How to bring a component into another file with `import`
- ✅ How to organize components in a `components` folder
- ✅ How to read a page as a tree of components
- ✅ The difference between default exports and named exports

### What You'll Need

- The Spendly project from Lesson 3
- The development server running with `npm run dev`

---

## 2. Create Your First Component

A component is a JavaScript function that returns JSX. You have already written one: `App`. Every component follows two rules:

1. Its name starts with a **capital letter**, such as `Header` or `TransactionList`. This is how React tells your components apart from built-in HTML tags like `<header>`.
2. It **returns JSX** (or `null` when it should show nothing).

Once a component is defined, you use it like an HTML tag: `<Header />`. When React sees that tag, it calls the `Header` function and puts whatever it returns in that spot.

### Step 1: Define a Header Component in App.jsx

Start by creating a component in the same file as `App`, so you can see both side by side. Replace `src/App.jsx` with this code.

```jsx
function Header() {
  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
    </header>
  );
}

function App() {
  return (
    <main className="app">
      <Header />
      <p>Track where your money goes.</p>
    </main>
  );
}

export default App;
```

Here is what this code does:

- `function Header()` defines a new component. It returns the same `<header>` markup you wrote in Lesson 3, with the logo and the app name.
- Inside `App`, `<Header />` uses the component. It is self-closing because it has no content between tags, exactly like `<img />`.
- `App` no longer contains the header markup itself. It only says "put a `Header` here", and the `Header` function takes care of the details.

Save the file.

What you see in the browser:

```text
Spendly

Track where your money goes.
```

The page looks like a normal page, and that is the point. Right-click the heading and choose **Inspect**. The Elements panel shows only standard HTML:

```html
<main class="app"><header class="app-header"><img alt="Spendly logo" width="32" height="32" src="/favicon.svg"><h1>Spendly</h1></header><p>Track where your money goes.</p></main>
```

There is no `<Header>` tag in the browser. Components exist only in your code. React calls each component function and puts the HTML it returns in the page.

---

## 3. Move Components into Their Own Files

Defining every component in `App.jsx` would bring back the original problem: one huge file. The common practice is one component per file, all collected in a `src/components` folder. To share a component between files, you **export** it from its own file and **import** it where you need it. You have already seen both: `App.jsx` ends with `export default App;`, and `main.jsx` imports it with `import App from './App.jsx'`.

### Step 1: Create the Header File

In Visual Studio Code, right-click the `src` folder, choose **New Folder**, and name it `components`. Inside it, create a file named `Header.jsx` with this code.

```jsx
function Header() {
  const userName = "Dina";

  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <p>Welcome back, {userName}!</p>
    </header>
  );
}

export default Header;
```

Here is what this code does:

- The component is the same `Header` from Step 1 of Section 2, now with the welcome message from Lesson 3 moved inside it, because greeting the user is part of the header's job.
- `const userName = "Dina";` lives inside `Header`. A variable declared inside a component belongs to that component; `App` cannot see it, and does not need to.
- `export default Header;` makes `Header` the main thing this file offers to other files. Each file can have one default export.

The file name matches the component name, `Header.jsx` for `Header`. This is not required, but it makes components easy to find, and almost every React project follows it.

Now replace `src/App.jsx` so that it imports the new file instead of defining `Header` itself.

```jsx
import Header from "./components/Header.jsx";

function App() {
  return (
    <main className="app">
      <Header />
      <p>Track where your money goes.</p>
    </main>
  );
}

export default App;
```

Here is what changed:

- `import Header from "./components/Header.jsx";` loads the default export of `Header.jsx` and names it `Header` in this file. The path starts with `./`, which means "starting from the folder this file is in". `App.jsx` is in `src`, so `./components/Header.jsx` points to `src/components/Header.jsx`.
- The `Header` function definition is gone from `App.jsx`. The rest of `App` is unchanged.

Save both files.

What you see in the browser:

```text
Spendly

Welcome back, Dina!

Track where your money goes.
```

### Step 2: Create the Summary Component

The summary section is the next candidate. Create `src/components/Summary.jsx` with this code.

```jsx
function Summary() {
  const income = 3400;
  const expense = 177;
  const balance = income - expense;

  return (
    <section className="summary">
      <h2>Summary</h2>
      <p>Income: ${income}</p>
      <p>Expense: ${expense}</p>
      <p>Balance: ${balance}</p>
    </section>
  );
}

export default Summary;
```

Here is what this code does:

- The three numbers and the balance calculation move into `Summary`, because only the summary uses them.
- The component returns a `<section>` with an `<h2>` title, so the summary is clearly labeled on the page.
- `export default Summary;` makes it available to `App`.

The inline style for the balance color is left out for now. You will style the whole page with CSS classes in Lesson 7, including the balance color.

Then update `src/App.jsx` to use it.

```jsx
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";

function App() {
  return (
    <main className="app">
      <Header />
      <Summary />
    </main>
  );
}

export default App;
```

A second `import` line brings in `Summary`, and `<Summary />` replaces the tagline paragraph. Save both files.

What you see in the browser:

```text
Spendly

Welcome back, Dina!

Summary

Income: $3400

Expense: $177

Balance: $3223
```

### Step 3: Create the Filters and TransactionList Components

Two components remain: one for the search box and one for the transaction list. Create `src/components/Filters.jsx`.

```jsx
function Filters() {
  return (
    <section className="filters">
      <label htmlFor="search">Search transactions</label>
      <input id="search" type="text" placeholder="e.g. Groceries" />
    </section>
  );
}

export default Filters;
```

`Filters` wraps the label and input from Lesson 3 in a `<section>`. It is named `Filters`, not `SearchBox`, because in Lesson 13 it will also get a category dropdown.

Next, create `src/components/TransactionList.jsx`.

```jsx
function TransactionList() {
  return (
    <section className="transactions">
      <h2>Transactions</h2>
      <ul>
        <li>2026-10-09 Coffee with friends (Food) -$12</li>
        <li>2026-10-08 Freelance design (Freelance) +$400</li>
        <li>2026-10-05 Bus pass (Transport) -$45</li>
        <li>2026-10-03 Groceries (Food) -$120</li>
        <li>2026-10-01 Monthly salary (Salary) +$3000</li>
      </ul>
    </section>
  );
}

export default TransactionList;
```

Here is what this code does:

- The component returns a `<section>` with a title and an unordered list.
- Each `<li>` shows one of the five transactions from Lesson 1, newest first, with the date, title, category, and a signed amount.
- The list is typed by hand for now. In Lesson 5 you will create a reusable component for one row, and in Lesson 6 you will generate the rows from the transactions array automatically.

### Step 4: Assemble the Page in App

Replace `src/App.jsx` with the final version for this lesson.

```jsx
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";

function App() {
  return (
    <main className="app">
      <Header />
      <Summary />
      <Filters />
      <TransactionList />
    </main>
  );
}

export default App;
```

Here is what this code does:

- Four `import` lines bring in the four components. Imports always go at the top of the file.
- The JSX reads almost like a table of contents: a header, then a summary, then filters, then the transaction list. Anyone opening this file understands the page layout in seconds.
- `App` has no data and no detailed markup of its own anymore. Its only job is to arrange the components.

Save the file. Your `src` folder now looks like this:

```text
src/
├── components/
│   ├── Filters.jsx
│   ├── Header.jsx
│   ├── Summary.jsx
│   └── TransactionList.jsx
├── App.jsx
├── index.css
└── main.jsx
```

---

## 4. Run and Test

With the development server running, open `http://localhost:5173`.

What you see in the browser:

```text
Spendly

Welcome back, Dina!

Summary

Income: $3400

Expense: $177

Balance: $3223

Search transactions
Transactions
2026-10-09 Coffee with friends (Food) -$12
2026-10-08 Freelance design (Freelance) +$400
2026-10-05 Bus pass (Transport) -$45
2026-10-03 Groceries (Food) -$120
2026-10-01 Monthly salary (Salary) +$3000
```

The search box appears after the "Search transactions" label, and the transactions appear as a bulleted list. The page is still unstyled; Lesson 7 takes care of that.

Test that each component is independent. Open `Summary.jsx`, change `const expense = 177;` to `const expense = 200;`, and save. Only the summary changes: `Expense: $200` and `Balance: $3200`. You did not touch `App.jsx`, `Header.jsx`, or any other file. Change the value back to `177`.

Then run the linter in a second terminal.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

```

No messages means every import is used and every component is defined.

---

## 5. Thinking in Components

Now that Spendly is split up, it helps to step back and look at the page the way React sees it: as a **tree of components**. `App` is the root, and every component it uses is a child.

```text
App
├── Header
├── Summary
├── Filters
└── TransactionList
```

This is the same tree you saw in Lesson 1, minus the `TransactionItem` component, which you will add in Lesson 5. When React renders the page, it starts at `App`, calls it, sees `<Header />`, calls `Header`, and so on down the tree until it reaches plain HTML elements.

How do you decide where to draw the lines between components? A few practical guidelines:

- **One job per component.** If you can describe a component's job in a short sentence without using "and", it is probably the right size. "Shows the balance summary" is a good component. "Shows the header and the summary and the list" is a page that should be split.
- **Split when something repeats.** A single transaction row will appear dozens of times, so it deserves its own component. That is exactly what Lesson 5 does.
- **Split when a file gets long.** There is no hard limit, but when you have to scroll a lot to understand a component, look for a section with its own heading or purpose and move it out.
- **Do not over-split.** A component for a single `<p>` usually adds more files than clarity.

**Default exports and named exports.** Every component in Spendly uses a default export (`export default Header;`), imported without curly braces (`import Header from "./components/Header.jsx";`). JavaScript also has **named exports**, where a file can export several things by name:

```jsx
export function formatAmount(amount) {
  return `$${amount}`;
}

export function formatDate(date) {
  return date;
}
```

Named exports are imported with curly braces, and the names must match exactly: `import { formatAmount, formatDate } from "./utils/format.js";`. You have already seen this style in `main.jsx`: `import { StrictMode } from 'react'`. In this course, components use default exports (one component per file), and helper functions you add later will use named exports.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when creating and connecting components.

**Error 1: Naming a component with a lowercase letter.**

React decides whether a tag is a component or an HTML element by its first letter. A lowercase name is treated as an HTML tag, even if a component with that name was imported.

```jsx
// Wrong
import transactionList from "./components/TransactionList.jsx";

function App() {
  return (
    <main className="app">
      <transactionList />
    </main>
  );
}

export default App;

// Correct
import TransactionList from "./components/TransactionList.jsx";

function App() {
  return (
    <main className="app">
      <TransactionList />
    </main>
  );
}

export default App;
```

With the wrong version, the transaction list simply does not appear, and the console shows two errors:

```text
<transactionList /> is using incorrect casing. Use PascalCase for React components, or lowercase for HTML elements.
The tag <transactionList> is unrecognized in this browser. If you meant to render a React component, start its name with an uppercase letter.
```

The linter notices something is off too. `npm run lint` prints:

```text
src/App.jsx:4:8: warning eslint(no-unused-vars): Identifier 'transactionList' is imported but never used. help: Consider removing this import.
```

From React's point of view, the imported component is never used, because `<transactionList />` was treated as an unknown HTML tag. Always name components in PascalCase: every word starts with a capital letter, with no spaces.

**Error 2: Forgetting `export default`.**

A component that is not exported cannot be imported.

```jsx
// Wrong
function Summary() {
  const income = 3400;
  const expense = 177;
  const balance = income - expense;

  return (
    <section className="summary">
      <h2>Summary</h2>
      <p>Income: ${income}</p>
      <p>Expense: ${expense}</p>
      <p>Balance: ${balance}</p>
    </section>
  );
}

// Correct
function Summary() {
  const income = 3400;
  const expense = 177;
  const balance = income - expense;

  return (
    <section className="summary">
      <h2>Summary</h2>
      <p>Income: ${income}</p>
      <p>Expense: ${expense}</p>
      <p>Balance: ${balance}</p>
    </section>
  );
}

export default Summary;
```

With the wrong version, the whole page goes blank, and the console shows:

```text
SyntaxError: The requested module '/src/components/Summary.jsx' does not provide an export named 'default'
```

The message names the file that is missing its export. Add `export default Summary;` at the bottom of the file and the page comes back.

**Error 3: Using a component without importing it.**

Each file only knows about the names it defines or imports. Using `<Filters />` in `App.jsx` without the import line fails.

```jsx
// Wrong
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import TransactionList from "./components/TransactionList.jsx";

function App() {
  return (
    <main className="app">
      <Header />
      <Summary />
      <Filters />
      <TransactionList />
    </main>
  );
}

export default App;

// Correct
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";

function App() {
  return (
    <main className="app">
      <Header />
      <Summary />
      <Filters />
      <TransactionList />
    </main>
  );
}

export default App;
```

With the wrong version, the page is blank, and the console shows this error at the top:

```text
ReferenceError: Filters is not defined
```

This is a mistake the linter catches before you even open the browser. `npm run lint` prints:

```text
src/App.jsx:10:8: warning react(jsx-no-undef): 'Filters' is not defined.
```

`src/App.jsx:10:8` points to line 10, where `<Filters />` is used. Add the missing import at the top of the file.

---

## 7. Exercises

**Exercise 1:** Create a `Footer` component in `src/components/Footer.jsx` that shows `© 2026 Spendly`. Import it in `App` and place it after `TransactionList`.

**Exercise 2:** Inside `App`, use `<Summary />` twice in a row. What appears on the page? Then remove the second one. What does this tell you about components and reuse?

**Exercise 3:** Create a `src/utils/format.js` file with a named export function `formatAmount(amount)` that returns the amount with a dollar sign in front, for example `formatAmount(3400)` returns `"$3400"`. Import it in `Summary.jsx` and use it for all three amounts.

---

## 8. Solutions

**Solution for Exercise 1:**

Create `src/components/Footer.jsx`.

```jsx
function Footer() {
  return (
    <footer className="app-footer">
      <p>&copy; 2026 Spendly</p>
    </footer>
  );
}

export default Footer;
```

Then import and use it in `src/App.jsx`.

```jsx
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import Footer from "./components/Footer.jsx";

function App() {
  return (
    <main className="app">
      <Header />
      <Summary />
      <Filters />
      <TransactionList />
      <Footer />
    </main>
  );
}

export default App;
```

`Footer` follows the same pattern as every other component: a capitalized function that returns JSX, a default export, and an import in `App`. The page now ends with `© 2026 Spendly` under the transaction list.

**Solution for Exercise 2:**

```jsx
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";

function App() {
  return (
    <main className="app">
      <Header />
      <Summary />
      <Summary />
      <Filters />
      <TransactionList />
    </main>
  );
}

export default App;
```

The summary section appears twice: two "Summary" headings, each with the same income, expense, and balance. React calls the `Summary` function once for each `<Summary />` tag. This shows that a component is reusable: you write it once and use it as many times as you like. Right now both copies are identical because the numbers are fixed inside `Summary`. In Lesson 5, props will let each copy show different data. Remove the second `<Summary />` when you are done.

**Solution for Exercise 3:**

Create the folder `src/utils` and the file `src/utils/format.js`.

```javascript
export function formatAmount(amount) {
  return `$${amount}`;
}
```

The `export` keyword in front of `function` creates a named export. The template literal puts a dollar sign in front of the amount; inside a template literal, the first `$` is plain text and `${amount}` inserts the value. The file uses the `.js` extension because it contains no JSX.

Then update `src/components/Summary.jsx`.

```jsx
import { formatAmount } from "../utils/format.js";

function Summary() {
  const income = 3400;
  const expense = 177;
  const balance = income - expense;

  return (
    <section className="summary">
      <h2>Summary</h2>
      <p>Income: {formatAmount(income)}</p>
      <p>Expense: {formatAmount(expense)}</p>
      <p>Balance: {formatAmount(balance)}</p>
    </section>
  );
}

export default Summary;
```

`import { formatAmount }` uses curly braces because it is a named export. The path starts with `../`, which means "go up one folder": `Summary.jsx` is in `src/components`, so `../utils/format.js` points to `src/utils/format.js`. The JSX now calls `formatAmount(income)` instead of writing `$` by hand, and the page looks exactly the same as before. The benefit appears later: when you want to change how every amount is displayed, you will change one function instead of dozens of lines.

---

## Next Up - Lesson 5

In this lesson you split Spendly into four components, `Header`, `Summary`, `Filters`, and `TransactionList`, each in its own file in `src/components`. You learned the two rules of components, connected files with `export default` and `import`, and started thinking of the page as a tree of components.

There is one problem left: the components are not flexible. `Summary` always shows the same numbers, and every row of `TransactionList` is typed by hand. In Lesson 5, you will learn **props**, the way a parent component passes data to its children. You will create a reusable `TransactionItem` component and feed it a different transaction each time you use it.
