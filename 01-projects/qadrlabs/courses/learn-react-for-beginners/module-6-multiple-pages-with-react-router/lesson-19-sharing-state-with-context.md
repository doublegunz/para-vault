## 1. Before You Begin

In Lesson 18, you gave every transaction its own detail page and moved editing to its own route. Spendly now has six routes, and almost all of them need the same data. Look at the route list in `App` from that lesson: `transactions` is passed to four pages, `categories` to three, and `onAdd`, `onUpdate`, and `onDelete` are spread across the rest. Every new page means more props to pass, and every new action means updating several routes.

Passing props through many components, often through components that do not use them, is called **prop drilling**. It is not wrong, and for short distances it is the clearest way to share data. But when many components across the app need the same data, React offers a better tool: **Context**. A context lets a component high in the tree provide a value, and lets any component below it read that value directly, without passing it through every level. In this lesson you will create a `TransactionsContext` that holds Spendly's transactions, categories, and actions, and rewrite every page to read from it.

### What You'll Build

- `src/context/TransactionsContext.js`: the context object itself.
- `src/context/TransactionsProvider.jsx`: a component that owns the transactions and categories and provides them, together with `addTransaction`, `updateTransaction`, and `deleteTransaction`, to everything inside it.
- `src/hooks/useTransactions.js`: a custom hook that reads the context and reports a clear error when it is used in the wrong place.
- A much shorter `App` whose routes pass no data props at all, and pages that each take exactly what they need from the context.

### What You'll Learn

- ✅ What prop drilling is and when it becomes a problem
- ✅ How to create a context with `createContext`
- ✅ How to provide a value with a provider component and the `children` prop
- ✅ How to read a context with `useContext`
- ✅ How to wrap context access in a custom hook with a helpful error
- ✅ When to use context and when props are the better choice

### What You'll Need

- The Spendly project from Lesson 18
- The development server running with `npm run dev`
- If you completed the Lesson 18 exercises, this lesson's code does not include them. You can keep them, but you will need to adapt `onAdd` in the detail page to use the context, as shown in Exercise 3 below.

---

## 2. The Problem: Prop Drilling

Here is how Spendly's shared data travels today:

```text
App  (owns transactions, categories, handleAdd, handleUpdate, handleDelete)
├── Layout                 <- errorMessage
└── routes
    ├── DashboardPage      <- transactions, totals
    ├── TransactionsPage   <- transactions, categories, onDelete
    │   └── TransactionList    <- onDelete
    │       └── TransactionItem    <- onDelete
    ├── TransactionDetailPage  <- transactions, onDelete
    ├── EditTransactionPage    <- transactions, categories, onUpdate
    └── AddTransactionPage     <- categories, onAdd
```

`App` itself does not display any transactions. It only holds the data so that it can hand it to the pages. If you wanted the header to show the number of transactions, you would have to pass `transactions` to `Layout`, which would pass it to `Header`. If you added a fourth action, such as "delete everything", you would add a function in `App` and another prop on a route.

Context solves this by changing **how** data travels, not where it is stored. The data still lives in one place, but instead of being handed down level by level, it is made available to the whole subtree at once. Any component can then pick it up directly:

```text
TransactionsProvider  (owns transactions, categories, and the actions)
└── App
    ├── Layout                 -> reads categoriesError
    └── routes
        ├── DashboardPage      -> reads transactions
        ├── TransactionsPage   -> reads transactions, categories, deleteTransaction
        ├── TransactionDetailPage  -> reads transactions, deleteTransaction
        ├── EditTransactionPage    -> reads transactions, categories, updateTransaction
        └── AddTransactionPage     -> reads categories, addTransaction
```

Using context takes three steps: **create** a context, **provide** a value to it, and **read** it where needed. You will do them in that order.

---

## 3. Create and Provide the Context

### Step 1: Create the Context

Create a new folder `src/context`, and inside it a file named `TransactionsContext.js`.

```javascript
import { createContext } from "react";

export const TransactionsContext = createContext(null);
```

Here is what this code does:

- `createContext` creates a context object. Think of it as a named channel that components can publish a value on and listen to.
- The argument, `null`, is the **default value**: what a component receives if it reads the context without any provider above it. Using `null` lets you detect that mistake later.
- The context is exported as a named constant so the provider and the hook can both import it.

The context object lives in its own small `.js` file. The linter's Fast Refresh rule (the `only-export-components` check in `.oxlintrc.json`) expects files that export components to export **only** components, so that Vite can update them without reloading the page. Keeping the context, the provider component, and the hook in separate files follows that rule.

### Step 2: Write the Provider Component

A **provider** is the component that owns the data and publishes it. Create `src/context/TransactionsProvider.jsx`.

```jsx
import { TransactionsContext } from "./TransactionsContext.js";
import { useLocalStorage } from "../hooks/useLocalStorage.js";
import { useFetch } from "../hooks/useFetch.js";
import { sampleTransactions } from "../data/transactions.js";

function TransactionsProvider({ children }) {
  const [transactions, setTransactions] = useLocalStorage("spendly-transactions", sampleTransactions);
  const { data: categories, error: categoriesError } = useFetch("/categories.json");

  function addTransaction(transactionData) {
    const newTransaction = { id: Date.now(), ...transactionData };
    setTransactions([newTransaction, ...transactions]);
    return newTransaction.id;
  }

  function updateTransaction(id, transactionData) {
    setTransactions(
      transactions.map((transaction) => (transaction.id === id ? { ...transaction, ...transactionData } : transaction)),
    );
  }

  function deleteTransaction(id) {
    setTransactions(transactions.filter((transaction) => transaction.id !== id));
  }

  const value = {
    transactions: transactions,
    categories: categories ?? [],
    categoriesError: categoriesError,
    addTransaction: addTransaction,
    updateTransaction: updateTransaction,
    deleteTransaction: deleteTransaction,
  };

  return <TransactionsContext value={value}>{children}</TransactionsContext>;
}

export default TransactionsProvider;
```

Most of this code moved here from `App`, with clearer names:

- The `transactions` state (saved with `useLocalStorage`) and the categories (loaded with `useFetch`) now live in the provider.
- `handleAdd`, `handleUpdate`, and `handleDelete` become `addTransaction`, `updateTransaction`, and `deleteTransaction`. They are no longer event handlers for one component, but actions that any component can call, so they are named after what they do.
- `value` is one object that collects everything the provider shares: the data and the actions. `categories ?? []` means consumers always receive an array, so no page needs its own fallback.
- `<TransactionsContext value={value}>` renders the context as a component and publishes `value` to every component inside it. (In older React code you will see `<TransactionsContext.Provider value={value}>`, which does the same thing.)
- `{children}` is the special prop from Lesson 5: whatever is placed between `<TransactionsProvider>` and `</TransactionsProvider>`. The provider shows it unchanged, just wrapped in the context. Without it, nothing inside the provider would be displayed at all.

### Step 3: Write a Hook to Read the Context

Components read a context with React's `useContext` hook. Instead of calling it directly in every page, wrap it in a custom hook, as you learned in Lesson 16. Create `src/hooks/useTransactions.js`.

```javascript
import { useContext } from "react";
import { TransactionsContext } from "../context/TransactionsContext.js";

export function useTransactions() {
  const context = useContext(TransactionsContext);
  if (context === null) {
    throw new Error("useTransactions must be used inside a TransactionsProvider.");
  }
  return context;
}
```

Here is what this code does:

- `useContext(TransactionsContext)` returns the `value` from the nearest `TransactionsContext` provider above the component. When the value changes, every component that reads it re-renders automatically.
- If there is no provider above, `useContext` returns the default value, `null`. Instead of letting the page crash later with a confusing message, the hook throws an error that says exactly what is wrong.
- Pages will import `useTransactions` and never need to know which context it uses. If you change how the data is stored one day, only this hook and the provider change.

### Step 4: Wrap the App in the Provider

The provider must be above every component that reads the context. Update `src/main.jsx`.

```jsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router'
import './index.css'
import App from './App.jsx'
import TransactionsProvider from './context/TransactionsProvider.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <TransactionsProvider>
        <App />
      </TransactionsProvider>
    </BrowserRouter>
  </StrictMode>,
)
```

`<App />` is now the `children` of `TransactionsProvider`, so every component in the app, including every page, can read the context. Do not save yet; the pages still expect props, which you will remove in the next section.

---

## 4. Read the Context in the Pages

Now every component that needs shared data takes it from the context, and `App` stops passing it.

### Step 1: Simplify App

Replace `src/App.jsx`.

```jsx
import { useEffect } from "react";
import { Route, Routes } from "react-router";
import "./App.css";
import Layout from "./components/Layout.jsx";
import DashboardPage from "./pages/DashboardPage.jsx";
import TransactionsPage from "./pages/TransactionsPage.jsx";
import TransactionDetailPage from "./pages/TransactionDetailPage.jsx";
import EditTransactionPage from "./pages/EditTransactionPage.jsx";
import AddTransactionPage from "./pages/AddTransactionPage.jsx";
import NotFoundPage from "./pages/NotFoundPage.jsx";
import { useTransactions } from "./hooks/useTransactions.js";
import { getTotals } from "./utils/transactions.js";
import { formatAmount } from "./utils/format.js";

function App() {
  const { transactions } = useTransactions();
  const balance = getTotals(transactions).balance;

  useEffect(() => {
    document.title = `Spendly (${formatAmount(balance)})`;
  }, [balance]);

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<DashboardPage userName="Dina" />} />
        <Route path="transactions" element={<TransactionsPage />} />
        <Route path="transactions/:id" element={<TransactionDetailPage />} />
        <Route path="transactions/:id/edit" element={<EditTransactionPage />} />
        <Route path="add" element={<AddTransactionPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}

export default App;
```

Here is what changed:

- The state, the categories, and the three handlers are gone; they live in the provider now.
- `App` still updates the page title, so it reads the transactions from the context with `const { transactions } = useTransactions();`. Destructuring picks only the property this component needs.
- Every route is now a single readable line. The only prop left is `userName`, which is a simple setting for one page, not shared data.

### Step 2: Read the Context in Layout and the Dashboard

Replace `src/components/Layout.jsx`.

```jsx
import { Outlet } from "react-router";
import Header from "./Header.jsx";
import { useTransactions } from "../hooks/useTransactions.js";

function Layout() {
  const { categoriesError } = useTransactions();

  return (
    <div className="app">
      <Header />
      {categoriesError && <p className="error-banner">Could not load categories: {categoriesError}</p>}
      <main className="page">
        <Outlet />
      </main>
    </div>
  );
}

export default Layout;
```

The `errorMessage` prop is replaced by `categoriesError` from the context, and the layout builds the message itself.

Replace `src/pages/DashboardPage.jsx`.

```jsx
import { Link } from "react-router";
import Summary from "../components/Summary.jsx";
import CurrencyConverter from "../components/CurrencyConverter.jsx";
import TransactionList from "../components/TransactionList.jsx";
import { useTransactions } from "../hooks/useTransactions.js";
import { getTotals, sortByNewest } from "../utils/transactions.js";

function DashboardPage({ userName }) {
  const { transactions } = useTransactions();
  const totals = getTotals(transactions);
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

The Dashboard reads the transactions from the context and calculates its own totals. `Summary`, `CurrencyConverter`, and `TransactionList` still receive props from the page. Context replaces long chains of props, not every prop: these components are reusable precisely because they display whatever they are given.

### Step 3: Read the Context in the Transaction Pages

Replace `src/pages/TransactionsPage.jsx`.

```jsx
import { useState } from "react";
import { useNavigate } from "react-router";
import Filters from "../components/Filters.jsx";
import TransactionList from "../components/TransactionList.jsx";
import { useTransactions } from "../hooks/useTransactions.js";
import { sortByNewest } from "../utils/transactions.js";

function TransactionsPage() {
  const { transactions, categories, deleteTransaction } = useTransactions();
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("All");
  const navigate = useNavigate();

  const visibleTransactions = sortByNewest(
    transactions
      .filter((transaction) => category === "All" || transaction.category === category)
      .filter((transaction) => transaction.title.toLowerCase().includes(search.toLowerCase())),
  );

  const isFiltering = search !== "" || category !== "All";

  return (
    <>
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
        onEdit={(id) => navigate(`/transactions/${id}/edit`)}
        onDelete={deleteTransaction}
      />
    </>
  );
}

export default TransactionsPage;
```

The page no longer has props. Its first line takes the three things it needs from the context. The filter state stays local, because only this page uses it.

Replace `src/pages/TransactionDetailPage.jsx`.

```jsx
import { Link, useNavigate, useParams } from "react-router";
import { useTransactions } from "../hooks/useTransactions.js";
import { formatAmount } from "../utils/format.js";

function TransactionDetailPage() {
  const { transactions, deleteTransaction } = useTransactions();
  const { id } = useParams();
  const navigate = useNavigate();

  const transaction = transactions.find((item) => item.id === Number(id));

  if (!transaction) {
    return (
      <section className="panel">
        <h2 className="page-title">Transaction not found</h2>
        <p className="empty-state">There is no transaction with the id {id}. It may have been deleted.</p>
        <p>
          <Link to="/transactions">Back to all transactions</Link>
        </p>
      </section>
    );
  }

  const { title, amount, type, category, date } = transaction;

  function handleDelete() {
    deleteTransaction(transaction.id);
    navigate("/transactions");
  }

  return (
    <section className="panel detail">
      <Link to="/transactions">Back to all transactions</Link>
      <h2 className="page-title">{title}</h2>
      <p className={`detail-amount ${type}`}>
        {type === "income" ? "+" : "-"}
        {formatAmount(amount)}
      </p>
      <dl className="detail-list">
        <dt>Type</dt>
        <dd>{type === "income" ? "Income" : "Expense"}</dd>
        <dt>Category</dt>
        <dd>{category}</dd>
        <dt>Date</dt>
        <dd>{date}</dd>
      </dl>
      <div className="form-actions">
        <button type="button" className="button delete-button" onClick={handleDelete}>
          Delete
        </button>
        <Link to="edit" className="button button-primary">
          Edit
        </Link>
      </div>
    </section>
  );
}

export default TransactionDetailPage;
```

Only the first lines changed: the props are gone, `useTransactions()` provides `transactions` and `deleteTransaction`, and `handleDelete` calls `deleteTransaction`. All three hooks are called at the top, before the early return.

Replace `src/pages/EditTransactionPage.jsx`.

```jsx
import { Link, useNavigate, useParams } from "react-router";
import TransactionForm from "../components/TransactionForm.jsx";
import { useTransactions } from "../hooks/useTransactions.js";

function EditTransactionPage() {
  const { transactions, categories, updateTransaction } = useTransactions();
  const { id } = useParams();
  const navigate = useNavigate();

  const transaction = transactions.find((item) => item.id === Number(id));

  if (!transaction) {
    return (
      <section className="panel">
        <h2 className="page-title">Transaction not found</h2>
        <p>
          <Link to="/transactions">Back to all transactions</Link>
        </p>
      </section>
    );
  }

  function handleSubmit(transactionData) {
    updateTransaction(transaction.id, transactionData);
    navigate(`/transactions/${transaction.id}`);
  }

  return (
    <section className="panel">
      <TransactionForm
        initialTransaction={transaction}
        categories={categories}
        onSubmit={handleSubmit}
        onCancel={() => navigate(`/transactions/${transaction.id}`)}
      />
    </section>
  );
}

export default EditTransactionPage;
```

And replace `src/pages/AddTransactionPage.jsx`.

```jsx
import { useNavigate } from "react-router";
import TransactionForm from "../components/TransactionForm.jsx";
import { useTransactions } from "../hooks/useTransactions.js";

function AddTransactionPage() {
  const { categories, addTransaction } = useTransactions();
  const navigate = useNavigate();

  function handleSubmit(transactionData) {
    const newId = addTransaction(transactionData);
    navigate(`/transactions/${newId}`);
  }

  return (
    <section className="panel">
      <TransactionForm categories={categories} onSubmit={handleSubmit} onCancel={() => navigate(-1)} />
    </section>
  );
}

export default AddTransactionPage;
```

The pattern is the same in every page: one line at the top takes what the page needs from the context.

---

## 5. Run and Test

Save all files. The app should behave exactly as it did at the end of Lesson 18. Test every action, because each one now goes through the context:

1. The Dashboard shows the same totals, and the tab title says `Spendly ($3,223)`.
2. Open "Groceries", click "Edit", change the title to `Weekly groceries` and the amount to `135.75`, and save. The detail page shows `Weekly groceries -$135.75`.
3. Click "Delete". You land on `/transactions` with "Showing 4 transactions".
4. Add a lunch for `12.50`. Its detail page opens.
5. Go to the Dashboard.

What you see in the summary:

```text
Income
$3,400
Expense
$69.50
Balance
$3,330.50

You have spent 2% of your income.
```

The expense started at $177, lost the $120 groceries, and gained the $12.50 lunch. The tab title says `Spendly ($3,330.50)`. Every page saw every change, because they all read the same context.

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

## 6. When to Use Context

Context is powerful, which makes it tempting to use everywhere. Here is how to decide.

**Use context for data that many components across the app need**, especially when the components that need it are far apart in the tree. Typical examples are the current user, the theme, the language, and app-wide data like Spendly's transactions.

**Use props for everything else.** Props make data flow visible: you can read a component's props and know exactly what it depends on. Components that receive data through props, like `Summary` and `TransactionItem`, are easy to reuse and test, because they work anywhere you give them the right props. A component that reads a context only works inside that context's provider.

**Try simpler options first.** Before reaching for context, consider whether the state could live closer to where it is used, or whether passing a prop one or two levels is actually fine. Context fixes long distances, not short ones.

**Context and state work together.** Context does not store anything by itself. It only transports a value. The state still comes from `useState` (or, here, `useLocalStorage`) inside the provider. When the provider's state changes, it renders with a new `value`, and every component that reads the context re-renders with it.

**Providers can be combined and nested.** A real app often has several providers, for example one for the signed-in user and one for settings, each wrapping the app in `main.jsx`. A component reads the closest provider of each context above it.

**About libraries.** For larger apps, you will see state management libraries such as Redux Toolkit or Zustand in AI-generated code and job listings. They solve the same problem as context, with extra tools for very large apps. The ideas are the same: one place owns the state, components read it, and actions change it.

---

## 7. Fix the Errors in Your Code

**Error 1: Using the context without a provider.**

```jsx
// Wrong
<BrowserRouter>
  <App />
</BrowserRouter>

// Correct
<BrowserRouter>
  <TransactionsProvider>
    <App />
  </TransactionsProvider>
</BrowserRouter>
```

With the wrong version, the page is blank and the console shows the error from `useTransactions`:

```text
Error: useTransactions must be used inside a TransactionsProvider.
```

This is why the hook checks for `null`. Without that check, the first page would fail with a much less helpful message about destructuring `null`. The linter also notices that `TransactionsProvider` is imported but unused:

```text
src/main.jsx:6:8: warning eslint(no-unused-vars): Identifier 'TransactionsProvider' is imported but never used. help: Consider removing this import.
```

**Error 2: Forgetting to add an action to the context value.**

```jsx
// Wrong
const value = {
  transactions: transactions,
  categories: categories ?? [],
  categoriesError: categoriesError,
  addTransaction: addTransaction,
  updateTransaction: updateTransaction,
};

// Correct
const value = {
  transactions: transactions,
  categories: categories ?? [],
  categoriesError: categoriesError,
  addTransaction: addTransaction,
  updateTransaction: updateTransaction,
  deleteTransaction: deleteTransaction,
};
```

The wrong version produces two different symptoms. On the Transactions page, the Delete buttons simply disappear: `deleteTransaction` is `undefined`, so `onDelete` is `undefined`, and `TransactionItem` hides the button, as designed in Lesson 17. On a detail page, the Delete button is still there, and clicking it fails:

```text
TypeError: deleteTransaction is not a function
```

The linter points to the cause:

```text
src/context/TransactionsProvider.jsx:22:12: warning eslint(no-unused-vars): Function 'deleteTransaction' is declared but never used. help: Consider removing this declaration.
```

A function that is defined in the provider but never used is almost always a function that was meant to go into `value`.

**Error 3: Forgetting to render the children.**

```jsx
// Wrong
return <TransactionsContext value={value} />;

// Correct
return <TransactionsContext value={value}>{children}</TransactionsContext>;
```

With the wrong version, the page is completely empty: no header, no content, and no error in the console. The provider rendered the context, but nothing inside it, so the whole app vanished. The linter gives the only clue:

```text
src/context/TransactionsProvider.jsx:6:33: warning eslint(no-unused-vars): Parameter 'children' is declared but never used. Unused parameters should start with a '_'. help: Consider removing this parameter.
```

A wrapper component must render `{children}`, or it hides everything it wraps.

---

## 8. Exercises

**Exercise 1:** Show the number of transactions in the navigation bar, such as `Transactions (5)`. `Header` should read the transactions from the context itself, without any new props.

**Exercise 2:** Add a fourth action to the context, `clearTransactions`, that removes every transaction. On the Transactions page, add a "Delete all transactions" button below the list, shown only when there is at least one transaction. Ask for confirmation with `window.confirm("Delete all transactions? This cannot be undone.")`.

**Exercise 3:** Make `Summary` read the transactions from the context and calculate its own totals, so the Dashboard can render `<Summary />` with no props. Then think about the trade-off: what does `Summary` gain, and what does it lose?

---

## 9. Solutions

**Solution for Exercise 1:**

Update `src/components/Header.jsx`.

```jsx
import { NavLink } from "react-router";
import { useTransactions } from "../hooks/useTransactions.js";

function Header() {
  const { transactions } = useTransactions();

  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <nav className="nav">
        <NavLink to="/">Dashboard</NavLink>
        <NavLink to="/transactions">Transactions ({transactions.length})</NavLink>
        <NavLink to="/add">+ Add</NavLink>
      </nav>
    </header>
  );
}

export default Header;
```

`Header` is rendered by `Layout`, which is rendered by a route. Without context, this would have meant passing `transactions` through `App` and `Layout`. With context, it is one line. The navigation reads `Dashboard | Transactions (5) | + Add`, and the number updates immediately when you add or delete a transaction, on any page.

**Solution for Exercise 2:**

In `src/context/TransactionsProvider.jsx`, add the action and include it in `value`:

```jsx
function clearTransactions() {
  setTransactions([]);
}
```

```jsx
const value = {
  transactions: transactions,
  categories: categories ?? [],
  categoriesError: categoriesError,
  addTransaction: addTransaction,
  updateTransaction: updateTransaction,
  deleteTransaction: deleteTransaction,
  clearTransactions: clearTransactions,
};
```

In `src/pages/TransactionsPage.jsx`, take it from the context, add a handler, and add the button after `<TransactionList />`:

```jsx
const { transactions, categories, deleteTransaction, clearTransactions } = useTransactions();
```

```jsx
function handleClearAll() {
  if (window.confirm("Delete all transactions? This cannot be undone.")) {
    clearTransactions();
  }
}
```

```jsx
{transactions.length > 0 && (
  <button type="button" className="button delete-button" onClick={handleClearAll}>
    Delete all transactions
  </button>
)}
```

Adding an app-wide action now takes two edits in the provider and none in `App`. After confirming, the list shows "No transactions yet. Add your first one to get started!", the button disappears, the navigation shows `Transactions (0)`, and the Dashboard summary shows `$0` everywhere. Use the browser's Application tab, or add a few transactions, to get data back.

**Solution for Exercise 3:**

Update the top of `src/components/Summary.jsx`.

```jsx
import { useTransactions } from "../hooks/useTransactions.js";
import { getTotals } from "../utils/transactions.js";
import { formatAmount } from "../utils/format.js";

function Summary() {
  const { transactions } = useTransactions();
  const { income, expense, balance } = getTotals(transactions);
```

Remove the old `const balance = income - expense;` line, since `getTotals` already returns the balance; the rest of the component stays the same. In `DashboardPage`, the tag becomes `<Summary />`. The summary looks exactly the same.

What does `Summary` gain? The Dashboard no longer has to pass anything, and `Summary` can be dropped onto any page. What does it lose? It can now only show the totals of **all** transactions, and only inside a `TransactionsProvider`. In Lesson 13's exercise you showed the totals of a filtered list by passing different numbers; with this version that is no longer possible without changing `Summary` again. Display components that receive props are more flexible; components that read context are more convenient. Choose based on how the component is used, and when in doubt, keep display components on props.

---

## Next Up - Lesson 20

In this lesson you replaced prop drilling with React Context. You created `TransactionsContext`, moved Spendly's data and actions into a `TransactionsProvider`, read them through a `useTransactions` hook that reports a clear error outside the provider, and reduced `App` to a list of routes. You also learned when context is the right tool and when props are better. That completes Module 6, and with it, the core of React: components, props, state, events, effects, custom hooks, routing, and context.

In Module 7, you will put all of that knowledge to work with AI coding tools. In Lesson 20, you will write a clear prompt asking an AI assistant to add a new feature to Spendly, and then read the code it returns line by line, mapping every part to the concepts you have learned, before you decide whether to use it.
