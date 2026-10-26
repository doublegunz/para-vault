## 1. Before You Begin

By the end of Module 5, Spendly could do a lot: show live totals, convert the balance into other currencies, add, edit, delete, search, and filter transactions, and remember everything between visits. But all of it is stacked on one long page. As features grow, a single page gets crowded, and users cannot bookmark or share a link to one specific part of the app.

Module 6 splits Spendly into separate pages with **React Router**, the most widely used routing library for React. In this lesson you will install it, give Spendly three pages (a Dashboard, a Transactions page, and an Add Transaction page), connect them with a navigation bar that highlights the current page, wrap them in a shared layout, and show a friendly "Page not found" screen for unknown addresses. Spendly stays a single-page application: switching pages never reloads the browser, so it stays fast and keeps its state.

### What You'll Build

- A navigation bar in the header with links to Dashboard, Transactions, and + Add. The link for the current page is highlighted.
- A **Dashboard** at `/` with a welcome message, the summary cards, the currency converter, the three most recent transactions, and a "See all transactions" button.
- A **Transactions** page at `/transactions` with the search, category filter, and full list, including editing and deleting.
- An **Add Transaction** page at `/add` with the form and a confirmation message after saving.
- A **Page not found** screen for any other address, such as `/reports`.

### What You'll Learn

- ✅ What client-side routing is and how it differs from loading new HTML pages
- ✅ How to install a package with npm
- ✅ How to set up `BrowserRouter`, `Routes`, and `Route`
- ✅ How to build a shared layout with a layout route and `Outlet`
- ✅ How to link between pages with `Link` and `NavLink`
- ✅ How to handle unknown URLs with a catch-all route
- ✅ How to organize components into pages

### What You'll Need

- The Spendly project from Lesson 16
- The development server running with `npm run dev`
- An internet connection to install React Router

---

## 2. Install React Router

In a traditional website, every page is a separate HTML file. Clicking a link asks the server for a new file, and the browser throws away the current page and draws the new one. A React app works differently: there is only one HTML page, `index.html`, and React draws everything inside it. **Client-side routing** means that when the address in the browser changes, JavaScript decides which components to show, without asking the server for a new page. React itself has no routing, so you add a library for it.

### Step 1: Install the Package

Stop the development server with `Ctrl+C`, then run this command in the `spendly` folder.

```bash
npm install react-router
```

`npm install` followed by a package name downloads that package into `node_modules` and adds it to the `dependencies` list in `package.json`.

Output:

```text
added 3 packages, and audited 28 packages in 2s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Open `package.json` and you will find a new line in `dependencies`:

```json
"react-router": "^8.5.0"
```

This course was tested with React Router 8.5.0. You might get a newer version, and everything in this lesson works the same way. Older tutorials and AI-generated code often import from a package called `react-router-dom`. That package was merged into `react-router` and is no longer needed: everything in this module is imported from `react-router`.

Start the development server again with `npm run dev`.

### Step 2: Wrap the App in BrowserRouter

React Router needs to watch the browser's address bar. You turn that on by wrapping the whole app in a `BrowserRouter` component. Open `src/main.jsx` and update it.

```jsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router'
import './index.css'
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>,
)
```

Here is what changed:

- `import { BrowserRouter } from 'react-router'` loads the router component. This file keeps the generated style with single quotes and no semicolons, as in Lesson 2.
- `<BrowserRouter>` wraps `<App />`. Every component inside it can now read the current address and navigate to other addresses. It uses the browser's History API, the same mechanism the Back and Forward buttons use, to change the URL without reloading the page.

Save the file. Nothing looks different yet, because no routes are defined.

---

## 3. Split Spendly into Pages

A **page** in a React Router app is just a component that is shown for a particular address. To keep things organized, create a new folder, `src/pages`, for these page components. The smaller building blocks, such as `Summary` and `TransactionItem`, stay in `src/components`.

### Step 1: Make Two Small Components More Flexible

Pages will reuse existing components in slightly different ways. The Dashboard shows a short list with its own title and no buttons, and the Add page shows the form with no Cancel button. Make three small changes.

In `src/components/TransactionList.jsx`, add a `title` prop with a default value, and use it in both `<h2>` elements:

```jsx
function TransactionList({
  title = "Transactions",
  transactions,
  emptyMessage = "No transactions yet. Add your first one to get started!",
  onEdit,
  onDelete,
}) {
```

```jsx
<h2>{title}</h2>
```

In `src/components/TransactionItem.jsx`, only show each button when its handler was passed:

```jsx
{onEdit && (
  <button type="button" className="button small-button" onClick={() => onEdit(id)}>
    Edit
  </button>
)}
{onDelete && (
  <button type="button" className="button small-button delete-button" onClick={() => onDelete(id)}>
    Delete
  </button>
)}
```

In `src/components/TransactionForm.jsx`, do the same for the Cancel button:

```jsx
{onCancel && (
  <button type="button" className="button" onClick={onCancel}>
    Cancel
  </button>
)}
```

When a function prop is not passed, it is `undefined`, so `onEdit && (...)` renders nothing. A component that adapts to the props it receives is easier to reuse in new places.

Also add a small helper to `src/utils/transactions.js`, since two pages will need to sort transactions:

```javascript
export function sortByNewest(transactions) {
  return [...transactions].sort((a, b) => b.date.localeCompare(a.date));
}
```

`[...transactions]` makes a copy before sorting, so the helper never changes the array it receives, as you learned in Lesson 13.

### Step 2: Create the Dashboard Page

Create `src/pages/DashboardPage.jsx`.

```jsx
import { Link } from "react-router";
import Summary from "../components/Summary.jsx";
import CurrencyConverter from "../components/CurrencyConverter.jsx";
import TransactionList from "../components/TransactionList.jsx";
import { sortByNewest } from "../utils/transactions.js";

function DashboardPage({ userName, transactions, totals }) {
  const recentTransactions = sortByNewest(transactions).slice(0, 3);

  return (
    <>
      <h2 className="page-title">Welcome back, {userName}!</h2>
      <Summary income={totals.income} expense={totals.expense} />
      <CurrencyConverter amount={totals.balance} />
      <TransactionList title="Recent transactions" transactions={recentTransactions} />
      <Link to="/transactions" className="button">
        See all transactions
      </Link>
    </>
  );
}

export default DashboardPage;
```

Here is what this code does:

- The page receives the data it needs as props: the user's name, the transactions, and the totals.
- `sortByNewest(transactions).slice(0, 3)` derives the three newest transactions.
- The list gets the title "Recent transactions" and no `onEdit` or `onDelete`, so its rows are read-only.
- `<Link to="/transactions">` is React Router's version of an `<a>` tag. It renders a normal link in the HTML, but when clicked, it changes the address without reloading the page. The `button` class makes it look like Spendly's buttons.
- The fragment `<>...</>` returns several elements without an extra wrapper, as you learned in Lesson 3.

### Step 3: Create the Transactions Page

Create `src/pages/TransactionsPage.jsx`. Most of its code comes from `App`: the search and category filters, the sorting, and the inline editing.

```jsx
import { useState } from "react";
import Filters from "../components/Filters.jsx";
import TransactionList from "../components/TransactionList.jsx";
import TransactionForm from "../components/TransactionForm.jsx";
import { sortByNewest } from "../utils/transactions.js";

function TransactionsPage({ transactions, categories, onUpdate, onDelete }) {
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("All");
  const [editingId, setEditingId] = useState(null);

  const editingTransaction = transactions.find((transaction) => transaction.id === editingId);

  const visibleTransactions = sortByNewest(
    transactions
      .filter((transaction) => category === "All" || transaction.category === category)
      .filter((transaction) => transaction.title.toLowerCase().includes(search.toLowerCase())),
  );

  const isFiltering = search !== "" || category !== "All";

  function handleSave(transactionData) {
    onUpdate(editingId, transactionData);
    setEditingId(null);
  }

  return (
    <>
      {editingTransaction && (
        <section className="panel">
          <TransactionForm
            key={editingId}
            initialTransaction={editingTransaction}
            categories={categories}
            onSubmit={handleSave}
            onCancel={() => setEditingId(null)}
          />
        </section>
      )}
      <Filters
        search={search}
        onSearchChange={setSearch}
        category={category}
        onCategoryChange={setCategory}
        categories={categories}
      />
      <TransactionList
        transactions={visibleTransactions}
        emptyMessage={isFiltering ? "No transactions match your filters." : undefined}
        onEdit={setEditingId}
        onDelete={onDelete}
      />
    </>
  );
}

export default TransactionsPage;
```

Here is what is different from the old `App` code:

- `search`, `category`, and `editingId` now live in this page, because nothing outside it uses them. This is the "keep state as low as possible" rule from Lesson 12. The transactions themselves stay in `App`, because all three pages need them.
- Saving an edit calls `onUpdate(editingId, transactionData)`, a new callback that `App` will provide. The page decides **which** transaction to update; `App` performs the update on its state.
- `onEdit={setEditingId}` passes the setter directly, because clicking Edit only needs to store the id.
- The edit form appears at the top of the page when a transaction is being edited. Lesson 18 will move editing to its own page.

### Step 4: Create the Add Transaction Page

Create `src/pages/AddTransactionPage.jsx`.

```jsx
import { useState } from "react";
import { Link } from "react-router";
import TransactionForm from "../components/TransactionForm.jsx";

function AddTransactionPage({ categories, onAdd }) {
  const [lastAddedTitle, setLastAddedTitle] = useState("");

  function handleSubmit(transactionData) {
    onAdd(transactionData);
    setLastAddedTitle(transactionData.title);
  }

  if (lastAddedTitle !== "") {
    return (
      <section className="panel">
        <p className="success-message">"{lastAddedTitle}" was added to your transactions.</p>
        <div className="form-actions">
          <button type="button" className="button" onClick={() => setLastAddedTitle("")}>
            Add another
          </button>
          <Link to="/transactions" className="button button-primary">
            View all transactions
          </Link>
        </div>
      </section>
    );
  }

  return (
    <section className="panel">
      <TransactionForm categories={categories} onSubmit={handleSubmit} />
    </section>
  );
}

export default AddTransactionPage;
```

Here is what this code does:

- The page shows the blank form. It passes no `onCancel`, so the Cancel button is hidden; to leave the page, the user clicks a link in the navigation bar.
- After a successful submit, `handleSubmit` sends the data to `App` with `onAdd`, then remembers the new transaction's title.
- When `lastAddedTitle` is not empty, an early return shows a confirmation with two choices: "Add another" clears the title, which brings the form back, and "View all transactions" links to the Transactions page.

### Step 5: Create the Not Found Page

Create `src/pages/NotFoundPage.jsx`.

```jsx
import { Link } from "react-router";

function NotFoundPage() {
  return (
    <section className="panel">
      <h2 className="page-title">Page not found</h2>
      <p className="empty-state">The page you are looking for does not exist.</p>
      <p>
        <Link to="/">Go back to the dashboard</Link>
      </p>
    </section>
  );
}

export default NotFoundPage;
```

A simple message and a way back. Every app with routes should have one, because users mistype addresses and old links break.

---

## 4. Define the Routes and the Layout

The pages exist; now React Router needs to know which page belongs to which address, and what should appear around every page.

### Step 1: Add Navigation to the Header

Replace `src/components/Header.jsx`.

```jsx
import { NavLink } from "react-router";

function Header() {
  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <nav className="nav">
        <NavLink to="/">Dashboard</NavLink>
        <NavLink to="/transactions">Transactions</NavLink>
        <NavLink to="/add">+ Add</NavLink>
      </nav>
    </header>
  );
}

export default Header;
```

Here is what changed:

- The greeting moved to the Dashboard page, so `Header` no longer needs a `userName` prop.
- `<NavLink>` works like `<Link>`, but it knows whether its address is the current one. When it is, React Router adds the class `active` to the link (and `aria-current="page"` for screen readers), so you can highlight it with CSS. A link to `/transactions` is also active on deeper addresses such as `/transactions/5`, which you will use in Lesson 18; the link to `/` is only active on the dashboard itself.

### Step 2: Create the Layout

Every page should show the header, and the error banner when the categories fail to load. Instead of repeating them in every page, you create a **layout** component. Create `src/components/Layout.jsx`.

```jsx
import { Outlet } from "react-router";
import Header from "./Header.jsx";

function Layout({ errorMessage }) {
  return (
    <div className="app">
      <Header />
      {errorMessage && <p className="error-banner">{errorMessage}</p>}
      <main className="page">
        <Outlet />
      </main>
    </div>
  );
}

export default Layout;
```

`<Outlet />` is a placeholder. React Router replaces it with whichever page matches the current address. The layout stays on screen while only the content of `<main>` changes. The outer `div` uses the `app` class, so the page keeps its width and spacing. The `main` element was the outer element of `App` until now; it gets a new class, `page`.

### Step 3: Replace App with Routes

`App` no longer draws a page itself. It owns the shared data and decides which page to show. Replace `src/App.jsx`.

```jsx
import { useEffect } from "react";
import { Route, Routes } from "react-router";
import "./App.css";
import Layout from "./components/Layout.jsx";
import DashboardPage from "./pages/DashboardPage.jsx";
import TransactionsPage from "./pages/TransactionsPage.jsx";
import AddTransactionPage from "./pages/AddTransactionPage.jsx";
import NotFoundPage from "./pages/NotFoundPage.jsx";
import { sampleTransactions } from "./data/transactions.js";
import { getTotals } from "./utils/transactions.js";
import { formatAmount } from "./utils/format.js";
import { useLocalStorage } from "./hooks/useLocalStorage.js";
import { useFetch } from "./hooks/useFetch.js";

function App() {
  const [transactions, setTransactions] = useLocalStorage("spendly-transactions", sampleTransactions);
  const { data: categories, error: categoriesError } = useFetch("/categories.json");

  const totals = getTotals(transactions);

  useEffect(() => {
    document.title = `Spendly (${formatAmount(totals.balance)})`;
  }, [totals.balance]);

  function handleAdd(transactionData) {
    const newTransaction = { id: Date.now(), ...transactionData };
    setTransactions([newTransaction, ...transactions]);
  }

  function handleUpdate(id, transactionData) {
    setTransactions(
      transactions.map((transaction) => (transaction.id === id ? { ...transaction, ...transactionData } : transaction)),
    );
  }

  function handleDelete(id) {
    setTransactions(transactions.filter((transaction) => transaction.id !== id));
  }

  return (
    <Routes>
      <Route element={<Layout errorMessage={categoriesError && `Could not load categories: ${categoriesError}`} />}>
        <Route index element={<DashboardPage userName="Dina" transactions={transactions} totals={totals} />} />
        <Route
          path="transactions"
          element={
            <TransactionsPage
              transactions={transactions}
              categories={categories ?? []}
              onUpdate={handleUpdate}
              onDelete={handleDelete}
            />
          }
        />
        <Route path="add" element={<AddTransactionPage categories={categories ?? []} onAdd={handleAdd} />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}

export default App;
```

Here is how the routing works:

- `<Routes>` looks at the current address and renders the first `<Route>` that matches it.
- The outer `<Route element={<Layout ... />}>` has no `path`. It is a **layout route**: it does not match any address by itself, but it wraps every route inside it. Whatever child route matches is rendered at the layout's `<Outlet />`.
- `<Route index ...>` is the **index route**: the page shown at the parent's own address, which here is `/`. That is the Dashboard.
- `path="transactions"` matches `/transactions`, and `path="add"` matches `/add`. Child paths are written without a leading slash, because they are relative to their parent.
- `path="*"` is the **catch-all route**. The `*` matches any address that no other route matched, so it must come last. It shows the Not Found page.
- Each route's `element` is ordinary JSX, so the pages receive their props exactly as components always have.
- `handleUpdate(id, transactionData)` and `handleAdd` take over the jobs of the old `handleSave`, now that adding and editing happen on different pages. `isFormOpen`, `editingId`, `search`, and `category` are gone from `App`, because they moved into the pages that use them.
- `errorMessage` uses `&&` so that the layout receives the full message when there is an error, and an empty string, which shows nothing, when there is none.

### Step 4: Style the Navigation and Pages

In `src/App.css`, replace the `.app-header p` rule (the greeting no longer lives in the header) with these rules.

```css
/* Navigation */
.nav {
  margin-left: auto;
  display: flex;
  gap: 4px;
}

.nav a {
  padding: 6px 12px;
  border-radius: 8px;
  color: var(--color-muted);
  font-weight: 600;
  text-decoration: none;
}

.nav a:hover {
  color: var(--color-text);
}

.nav a.active {
  color: var(--color-primary);
  background-color: #eef2ff;
}

/* Pages */
.page {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.page-title {
  font-size: 22px;
}

a.button {
  align-self: flex-start;
  text-decoration: none;
}

.success-message {
  margin-bottom: 12px;
  color: var(--color-income);
}
```

Here is what these rules do:

- `.nav` pushes the links to the right of the header with `margin-left: auto`, and `.nav a.active` gives the current page's link an indigo color and a light background, using the `active` class that `NavLink` adds.
- `.page` stacks each page's sections with the same 24-pixel gap the old single page had.
- `a.button` lets links use the `button` class without an underline, and `align-self: flex-start` stops them from stretching to the full width of the page.

The `toolbar` and `panel` rules from earlier lessons are still used by the pages, so keep them.

---

## 5. Run and Test

Open `http://localhost:5173`. The Dashboard appears, and "Dashboard" is highlighted in the navigation bar.

What you see on the Dashboard:

```text
Welcome back, Dina!
Income
$3,400
Expense
$177
Balance
$3,223

You have spent 5% of your income.

Show my balance in
EUR
GBP
JPY
IDR

$3,223 is about €2,880.75 (1 USD = 0.89381 EUR)

Recent transactions

Showing 3 transactions

Coffee with friends
Food · 2026-10-09
-$12
Freelance design
Freelance · 2026-10-08
+$400
Bus pass
Transport · 2026-10-05
-$45
See all transactions
```

(The dropdown lists its options in the page text; on screen it is a single dropdown.) Now test the routing:

1. Click "Transactions" in the navigation bar. The address changes to `/transactions`, the "Transactions" link is highlighted, and the page shows the filters and all five transactions with Edit and Delete buttons. The page did not flash or reload.
2. Click "+ Add". The address changes to `/add` and the form appears. Fill in `Lunch`, `12.50`, and October 20, 2026, and click "Add transaction".

What you see on the Add page:

```text
"Lunch" was added to your transactions.

Add another
View all transactions
```

3. Click "View all transactions". The address is `/transactions`, and the count says "Showing 6 transactions", with Lunch at the top.
4. Use the browser's Back button. You go back through the pages you visited, because React Router records each navigation in the browser history.
5. Type `http://localhost:5173/reports` in the address bar and press `Enter`.

What you see on the page:

```text
Page not found

The page you are looking for does not exist.

Go back to the dashboard
```

The header with the navigation bar is still there, because the Not Found route lives inside the layout route. Typing an address directly also works for `/transactions` and `/add`: the Vite development server answers every address with `index.html`, and React Router then shows the right page.

Run the linter.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

```

---

## 6. How React Router Fits Together

Here is the structure you just built, as a tree:

```text
BrowserRouter                 (main.jsx: watches the address bar)
└── App                       (owns transactions and categories)
    └── Routes
        └── Route (Layout)    (header + error banner + <Outlet />)
            ├── index         -> DashboardPage
            ├── transactions  -> TransactionsPage
            ├── add           -> AddTransactionPage
            └── *             -> NotFoundPage
```

And the main pieces of React Router:

| Piece | What it does |
| --- | --- |
| `BrowserRouter` | Connects React Router to the browser's address bar and history. Wrap the whole app in it once. |
| `Routes` | Picks the route that matches the current address. |
| `Route` | Links a `path` to an `element`. Can be nested. |
| `index` route | The child shown at the parent's own address. |
| Layout route | A `Route` with an `element` but no `path`, which wraps its children. |
| `Outlet` | The spot in a layout where the matching child route is rendered. |
| `Link` | A link that changes the address without reloading the page. |
| `NavLink` | A `Link` that adds the `active` class when its address is current. |
| `path="*"` | Matches any address that nothing else matched. |

**Why not just use `<a href>`?** A normal link makes the browser request a whole new page. That reloads every JavaScript file, restarts React, and throws away all state that is not saved somewhere, such as what you typed in a search box. `Link` and `NavLink` only update the address and let React swap the page content, which is instant.

**Where should state live now?** The same rules from Lesson 12 apply, with pages as components. Data used by several pages, like the transactions, lives above the routes in `App`. Data used by one page, like the search text, lives in that page. Notice a consequence: if you search on the Transactions page, go to the Dashboard, and come back, the search box is empty again. Leaving a page removes it from the screen, and its state goes with it. That is usually what users expect.

**What about production?** The Vite development server returns `index.html` for every address, so typing `/transactions` directly works. When you publish the app to a web host, the host must be configured to do the same. You will look at this in Lesson 22.

---

## 7. Fix the Errors in Your Code

Routing mistakes often produce an empty page, so it helps to know the typical causes.

**Error 1: Forgetting BrowserRouter.**

```jsx
// Wrong
createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)

// Correct
createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>,
)
```

With the wrong version, the page is blank and the console shows:

```text
Error: useRoutes() may be used only in the context of a <Router> component.
```

`<Routes>` uses a hook called `useRoutes` internally, and it needs a router above it in the tree to know the current address. The same kind of error appears if you use `Link`, `NavLink`, or the hooks in the next lessons outside a router. The fix is always to make sure `BrowserRouter` wraps the whole app, in `main.jsx`.

**Error 2: Forgetting the catch-all route.**

```jsx
// Wrong
<Route element={<Layout errorMessage={categoriesError && `Could not load categories: ${categoriesError}`} />}>
  <Route index element={<DashboardPage userName="Dina" transactions={transactions} totals={totals} />} />
  {/* transactions and add routes */}
</Route>

// Correct
<Route element={<Layout errorMessage={categoriesError && `Could not load categories: ${categoriesError}`} />}>
  <Route index element={<DashboardPage userName="Dina" transactions={transactions} totals={totals} />} />
  {/* transactions and add routes */}
  <Route path="*" element={<NotFoundPage />} />
</Route>
```

Without the catch-all route, visiting `/reports` shows a completely empty page, not even the header. The console explains:

```text
No routes matched location "/reports"
```

When no route matches, `<Routes>` renders nothing at all, including the layout. A catch-all route at the end guarantees that every address shows something useful.

**Error 3: Using a plain link instead of Link.**

```jsx
// Wrong
<a href="/transactions" className="button">
  See all transactions
</a>

// Correct
<Link to="/transactions" className="button">
  See all transactions
</Link>
```

The wrong version seems to work: clicking it shows the Transactions page. But watch closely and you will see the page flash white, and in the Network tab every file is downloaded again. The browser loaded a brand-new page, and React started from scratch. In this app, data saved in `localStorage` survives, but anything that only lived in state, such as an unsaved form or a search, is lost. AI-generated code mixes `<a href>` and `Link` surprisingly often, so check every internal link. Use `<a href>` only for links that leave your app, such as a link to the React documentation.

---

## 8. Exercises

**Exercise 1:** Add a footer to `Layout`, after `<main>`, with the text `© 2026 Spendly. Built with React.` and the class `app-footer`. Check that it appears on every page, including the Not Found page.

**Exercise 2:** Make the logo and the "Spendly" title in the header a link back to the Dashboard. Wrap them in a `Link` with the class `brand`. Use `Link`, not `NavLink`, since the logo does not need an active style.

**Exercise 3:** Add an About page at `/about`, with a heading "About Spendly" and one sentence describing the app. Create it in `src/pages/AboutPage.jsx`, add its route before the catch-all route, and add an "About" link to the navigation bar.

---

## 9. Solutions

**Solution for Exercise 1:**

Update `src/components/Layout.jsx`.

```jsx
import { Outlet } from "react-router";
import Header from "./Header.jsx";

function Layout({ errorMessage }) {
  return (
    <div className="app">
      <Header />
      {errorMessage && <p className="error-banner">{errorMessage}</p>}
      <main className="page">
        <Outlet />
      </main>
      <footer className="app-footer">&copy; 2026 Spendly. Built with React.</footer>
    </div>
  );
}

export default Layout;
```

Because every route is nested inside the layout route, the footer appears on every page without touching any page component. Changing the layout changes the whole app. You can style it with `.app-footer { color: var(--color-muted); font-size: 14px; }`.

**Solution for Exercise 2:**

Update `src/components/Header.jsx`.

```jsx
import { Link, NavLink } from "react-router";

function Header() {
  return (
    <header className="app-header">
      <Link to="/" className="brand">
        <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
        <h1>Spendly</h1>
      </Link>
      <nav className="nav">
        <NavLink to="/">Dashboard</NavLink>
        <NavLink to="/transactions">Transactions</NavLink>
        <NavLink to="/add">+ Add</NavLink>
      </nav>
    </header>
  );
}

export default Header;
```

`Link` and `NavLink` are both named exports, imported together. A link can contain other elements, here the image and the heading. Clicking the logo from any page returns to `/`. To keep the logo and title side by side without an underline, add `.brand { display: flex; align-items: center; gap: 12px; text-decoration: none; }` to `App.css`.

**Solution for Exercise 3:**

Create `src/pages/AboutPage.jsx`.

```jsx
function AboutPage() {
  return (
    <section className="panel">
      <h2 className="page-title">About Spendly</h2>
      <p>Spendly is a personal expense tracker built with React while learning React on qadrlabs.</p>
    </section>
  );
}

export default AboutPage;
```

In `src/App.jsx`, import it and add the route before the catch-all:

```jsx
import AboutPage from "./pages/AboutPage.jsx";
```

```jsx
<Route path="about" element={<AboutPage />} />
<Route path="*" element={<NotFoundPage />} />
```

In `src/components/Header.jsx`, add the link after "+ Add":

```jsx
<NavLink to="/about">About</NavLink>
```

Clicking "About" shows:

```text
About Spendly

Spendly is a personal expense tracker built with React while learning React on qadrlabs.
```

Adding a page always takes the same three steps: create the page component, add a `Route`, and link to it.

---

## Next Up - Lesson 18

In this lesson you installed React Router and turned Spendly into a multi-page app. You wrapped the app in `BrowserRouter`, defined routes with `Routes` and `Route`, built a shared layout with a layout route and `Outlet`, linked pages with `Link` and `NavLink`, and handled unknown addresses with a catch-all route. Each page owns its own state, while the shared data stays in `App`.

So far, every route has a fixed address. In Lesson 18, you will create a **detail page** for each transaction, at addresses such as `/transactions/3`, using a dynamic route. You will read the id from the address with `useParams`, move editing to its own page, navigate from code with `useNavigate`, and show a helpful message when a transaction does not exist.
