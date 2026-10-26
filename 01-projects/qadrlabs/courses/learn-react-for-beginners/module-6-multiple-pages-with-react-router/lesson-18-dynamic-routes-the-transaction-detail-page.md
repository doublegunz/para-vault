## 1. Before You Begin

In Lesson 17, you split Spendly into pages with React Router: a Dashboard, a Transactions page, an Add page, and a Not Found page. Every route has a fixed address, such as `/add`. But some pages are about **one particular item**. A transaction deserves its own page with its own address, so that users can open it, bookmark it, or share the link. You cannot write a route for every transaction by hand, because users keep adding new ones.

This lesson introduces **dynamic routes**: a single route such as `/transactions/:id` that matches `/transactions/1`, `/transactions/2`, and any other id. You will build a detail page that reads the id from the address with `useParams`, move editing out of the list and onto its own page at `/transactions/:id/edit`, and use `useNavigate` to move the user to the right page after adding, saving, or deleting. You will also handle the case every detail page must handle: an id that does not exist.

### What You'll Build

- A **Transaction detail** page at `/transactions/:id`, showing the title, the amount in large colored text, the type, the category, and the date, with Edit and Delete buttons.
- Transaction titles in every list that link to their detail page.
- An **Edit** page at `/transactions/:id/edit`, which opens the form filled with the transaction and returns to the detail page after saving.
- An Add page that opens the new transaction's detail page right after saving.
- A "Transaction not found" message for ids that do not exist, such as `/transactions/999`.

### What You'll Learn

- ✅ How to define a route with a dynamic segment such as `:id`
- ✅ How to read URL parameters with `useParams`
- ✅ Why URL parameters are always strings, and how to compare them with numeric ids
- ✅ How to navigate from code with `useNavigate`, including going back with `navigate(-1)`
- ✅ The difference between absolute and relative links
- ✅ How to handle a missing item on a detail page
- ✅ Why `navigate` belongs in event handlers, not in the render

### What You'll Need

- The Spendly project from Lesson 17
- The development server running with `npm run dev`
- If you completed the Lesson 17 exercises, you can keep them; this lesson does not change the layout or the header.

---

## 2. Create the Transaction Detail Page

A dynamic route has a **dynamic segment**: a part of the path that starts with a colon, such as `:id`. It matches any value in that position, and React Router makes the actual value available to the page. In this section you will create the detail page, register its route, and link to it from the lists.

### Step 1: Write the Detail Page

Create `src/pages/TransactionDetailPage.jsx`.

```jsx
import { Link, useNavigate, useParams } from "react-router";
import { formatAmount } from "../utils/format.js";

function TransactionDetailPage({ transactions, onDelete }) {
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
    onDelete(transaction.id);
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

Here is what this code does:

- `useParams()` is a hook from React Router. It returns an object with the dynamic segments of the current address. For the address `/transactions/2` and a route `transactions/:id`, it returns `{ id: "2" }`. Destructuring gives you `id`.
- `useNavigate()` returns a function, here named `navigate`, that changes the address from your code, the way clicking a `Link` does.
- `transactions.find((item) => item.id === Number(id))` looks up the transaction. **URL parameters are always strings**, because they come from the text of the address, while Spendly's ids are numbers. `Number(id)` converts `"2"` into `2` so the strict comparison `===` works. Forgetting this is the most common dynamic-route bug, as you will see in the Fix the Errors section.
- `if (!transaction)` handles an id that matches nothing, for example because the transaction was deleted or someone typed a wrong address. The page returns a helpful message and a way back, instead of crashing on `transaction.title`. Both hooks are called **before** this early return, following the rules of hooks.
- `handleDelete` deletes the transaction and then calls `navigate("/transactions")`. After deleting, the detail page would only show "not found", so the user is sent back to the list.
- The `<dl>` element is a **description list**, the HTML element for label and value pairs: each `<dt>` is a term and each `<dd>` its description.
- `<Link to="edit">` has no leading slash, so it is a **relative link**. It is resolved from the current route, so on `/transactions/2` it leads to `/transactions/2/edit`. You will create that route in Section 3.

Add the styles for the detail page to the end of `src/App.css`.

```css
/* Transaction detail */
.transaction-title a {
  color: inherit;
  text-decoration: none;
}

.transaction-title a:hover {
  color: var(--color-primary);
  text-decoration: underline;
}

.detail {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.detail > a {
  align-self: flex-start;
  color: var(--color-primary);
}

.detail-amount {
  font-size: 32px;
  font-weight: bold;
}

.detail-list {
  display: grid;
  grid-template-columns: max-content 1fr;
  gap: 8px 24px;
  margin: 0;
}

.detail-list dt {
  color: var(--color-muted);
}

.detail-list dd {
  margin: 0;
}
```

The first two rules are for the title links you will add in Step 3: they look like normal titles until hovered. The detail card stacks its parts vertically, the amount gets a large font, and the description list uses a two-column grid with labels on the left.

### Step 2: Register the Dynamic Route

Open `src/App.jsx`, import the page, and add a route right after the `transactions` route.

```jsx
import TransactionDetailPage from "./pages/TransactionDetailPage.jsx";
```

```jsx
<Route
  path="transactions/:id"
  element={<TransactionDetailPage transactions={transactions} onDelete={handleDelete} />}
/>
```

`transactions/:id` matches `/transactions/` followed by any single segment. It does not match `/transactions` itself, so the list page and the detail page never compete. React Router picks the most specific route that matches, so the order of these two routes does not matter.

Save both files and open `http://localhost:5173/transactions/2` directly in the address bar.

What you see on the page:

```text
Back to all transactions
Groceries

-$120

Type
Expense
Category
Food
Date
2026-10-03
Delete
Edit
```

The navigation bar highlights "Transactions", because the address starts with `/transactions`. Now try `http://localhost:5173/transactions/999`.

What you see on the page:

```text
Transaction not found

There is no transaction with the id 999. It may have been deleted.

Back to all transactions
```

### Step 3: Link to the Detail Page from the Lists

Users should not have to type addresses. Make every transaction title a link. Update the top of `src/components/TransactionItem.jsx`:

```jsx
import { Link } from "react-router";
import { formatAmount } from "../utils/format.js";
```

And replace `{title}` inside the `transaction-title` span with a link:

```jsx
<span className="transaction-title">
  <Link to={`/transactions/${id}`}>{title}</Link>
  {amount >= 1000 && <span className="badge">Large</span>}
</span>
```

The address is built with a template literal from the row's id, such as `/transactions/4`. It starts with a slash, so it is an **absolute** link that works the same on every page. Because `TransactionItem` is used by both the Dashboard and the Transactions page, the titles become links on both pages at once.

Save the file, open the Transactions page, and click "Groceries". The address changes to `/transactions/2` and the detail page appears. Click "Back to all transactions" to return.

---

## 3. Edit on Its Own Page

In Lesson 17, editing opened a form at the top of the Transactions page. Now that every transaction has an address, editing can have one too: `/transactions/:id/edit`. That makes the Transactions page simpler and gives every screen a clear purpose.

### Step 1: Create the Edit Page

Create `src/pages/EditTransactionPage.jsx`.

```jsx
import { Link, useNavigate, useParams } from "react-router";
import TransactionForm from "../components/TransactionForm.jsx";

function EditTransactionPage({ transactions, categories, onUpdate }) {
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
    onUpdate(transaction.id, transactionData);
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

Here is what this code does:

- The page finds the transaction from the URL in exactly the same way as the detail page, and shows a not-found message when needed.
- `TransactionForm` receives the transaction as `initialTransaction`, so it starts filled in and shows "Edit transaction" and "Save changes", as in Lesson 11.
- After saving, `navigate` returns the user to the detail page, where they can see the updated values. Cancel goes to the same place without saving.
- No `key` is needed on the form this time. Each edit page is a separate visit to a route, and React creates a fresh form whenever the page appears.

Register the route in `src/App.jsx`, after the detail route:

```jsx
import EditTransactionPage from "./pages/EditTransactionPage.jsx";
```

```jsx
<Route
  path="transactions/:id/edit"
  element={
    <EditTransactionPage transactions={transactions} categories={categories ?? []} onUpdate={handleUpdate} />
  }
/>
```

### Step 2: Simplify the Transactions Page

The inline edit form is no longer needed. Replace `src/pages/TransactionsPage.jsx`.

```jsx
import { useState } from "react";
import { useNavigate } from "react-router";
import Filters from "../components/Filters.jsx";
import TransactionList from "../components/TransactionList.jsx";
import { sortByNewest } from "../utils/transactions.js";

function TransactionsPage({ transactions, categories, onDelete }) {
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
        onDelete={onDelete}
      />
    </>
  );
}

export default TransactionsPage;
```

Here is what changed:

- `editingId`, `editingTransaction`, `handleSave`, and the panel with the form are gone, along with the `TransactionForm` import and the `onUpdate` prop.
- The Edit buttons now call `navigate` with the edit page's address. `TransactionItem` still calls `onEdit(id)` exactly as before; only what the page does with it has changed.

In `src/App.jsx`, the Transactions route no longer needs `onUpdate`:

```jsx
<Route
  path="transactions"
  element={
    <TransactionsPage transactions={transactions} categories={categories ?? []} onDelete={handleDelete} />
  }
/>
```

### Step 3: Open the New Transaction After Adding

The Add page from Lesson 17 showed a confirmation message. Now there is a better destination: the new transaction's own page. For that, the Add page needs to know the new id, which `App` creates. Make `handleAdd` in `src/App.jsx` return it:

```jsx
function handleAdd(transactionData) {
  const newTransaction = { id: Date.now(), ...transactionData };
  setTransactions([newTransaction, ...transactions]);
  return newTransaction.id;
}
```

A callback prop can return a value to the child that called it, like any function. Then replace `src/pages/AddTransactionPage.jsx`.

```jsx
import { useNavigate } from "react-router";
import TransactionForm from "../components/TransactionForm.jsx";

function AddTransactionPage({ categories, onAdd }) {
  const navigate = useNavigate();

  function handleSubmit(transactionData) {
    const newId = onAdd(transactionData);
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

Here is what changed:

- `handleSubmit` adds the transaction, receives its id, and navigates straight to its detail page. The confirmation state and its `useState` are gone.
- `navigate(-1)` goes **back one step** in the browser history, exactly like the browser's Back button. The form gets a Cancel button again, which returns the user to wherever they came from.

Here are the routes in `App` after this lesson:

```jsx
<Routes>
  <Route element={<Layout errorMessage={categoriesError && `Could not load categories: ${categoriesError}`} />}>
    <Route index element={<DashboardPage userName="Dina" transactions={transactions} totals={totals} />} />
    <Route
      path="transactions"
      element={
        <TransactionsPage transactions={transactions} categories={categories ?? []} onDelete={handleDelete} />
      }
    />
    <Route
      path="transactions/:id"
      element={<TransactionDetailPage transactions={transactions} onDelete={handleDelete} />}
    />
    <Route
      path="transactions/:id/edit"
      element={
        <EditTransactionPage transactions={transactions} categories={categories ?? []} onUpdate={handleUpdate} />
      }
    />
    <Route path="add" element={<AddTransactionPage categories={categories ?? []} onAdd={handleAdd} />} />
    <Route path="*" element={<NotFoundPage />} />
  </Route>
</Routes>
```

---

## 4. Run and Test

Walk through the whole flow:

1. Open the Transactions page and click "Groceries". The address is `/transactions/2`.
2. Click "Edit". The address is `/transactions/2/edit`, and the form shows "Groceries" and `120`.
3. Change the title to `Weekly groceries` and the amount to `135.75`, then click "Save changes". You are back on `/transactions/2`.

What you see on the detail page:

```text
Back to all transactions
Weekly groceries

-$135.75

Type
Expense
Category
Food
Date
2026-10-03
Delete
Edit
```

4. Click "Delete". You are sent to `/transactions`, and the count says "Showing 4 transactions".
5. Click "+ Add", fill in `Lunch`, `12.50`, and October 20, 2026, and click "Add transaction". The address becomes `/transactions/` followed by the new id (a long number from `Date.now()`), and the detail page shows "Lunch" with `-$12.50`.
6. On that page, press the browser's Back button. You return to the Add page, and the form is empty again.
7. Click "+ Add" again, then "Cancel". `navigate(-1)` takes you back to the page you were on.
8. Open `/transactions/999` and `/transactions/999/edit`. Both show "Transaction not found".

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

## 5. Working with URLs

**The URL is state too.** The id in `/transactions/2` is a piece of information that decides what the page shows, just like state. The difference is that it lives in the address bar, so it survives a refresh, can be bookmarked, and can be shared. Whenever a screen is about "one specific thing", putting that thing's id in the URL is usually the right choice. Notice that the detail page stores nothing in state: it derives the transaction from the URL and the transactions on every render.

**Parameters are strings.** Everything you read from a URL is text. Convert it before comparing it with numbers. If your ids were strings to begin with, for example from `crypto.randomUUID()`, no conversion would be needed.

**Absolute and relative links.**

| Link | On `/transactions/2` it leads to | Use it for |
| --- | --- | --- |
| `to="/transactions"` | `/transactions` | Links that should go to the same place from any page |
| `to="edit"` | `/transactions/2/edit` | Links that extend the current route |
| `to={`/transactions/${id}`}` | `/transactions/<id>` | Links built from data, used on many pages |

A link without a leading slash is resolved relative to the route that renders it. That is handy inside a page that belongs to one route, like the Edit link on the detail page, but risky in a component that is reused on different pages, as Error 3 shows.

**`Link` or `navigate`?** Use `Link` when the user clicks something whose only job is to go somewhere: it renders a real link, which works with the keyboard, opens in a new tab with a middle click, and is announced as a link by screen readers. Use `navigate` when navigation is the **result** of an action, such as after saving or deleting.

**Navigate only in event handlers.** Calling `navigate` while a component is rendering changes another component's state in the middle of rendering, which React does not allow. If you ever need to redirect immediately when a page appears, render React Router's `<Navigate to="/somewhere" />` component instead.

---

## 6. Fix the Errors in Your Code

**Error 1: Comparing the URL parameter without converting it.**

```jsx
// Wrong
const transaction = transactions.find((item) => item.id === id);

// Correct
const transaction = transactions.find((item) => item.id === Number(id));
```

With the wrong version, every detail page says the transaction does not exist, even for a valid id.

What you see on `/transactions/2`:

```text
Transaction not found

There is no transaction with the id 2. It may have been deleted.

Back to all transactions
```

`id` is the string `"2"`, and `item.id` is the number `2`. The strict equality operator `===` never considers a string equal to a number, so `find` returns `undefined`. The page shows no error, because it handled the missing transaction correctly. It just looked for the wrong thing. When a detail page always shows "not found", check the types of the values being compared.

**Error 2: Calling navigate during rendering.**

It can seem reasonable to send users back to the list automatically when a transaction is missing:

```jsx
// Wrong
if (!transaction) {
  navigate("/transactions");
  return (
    <section className="panel">
      {/* not found message */}
    </section>
  );
}

// Correct
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
```

The wrong version does redirect, but the console shows a warning from React Router and an error from React:

```text
You should call navigate() in a React.useEffect(), not when your component is first rendered.
Cannot update a component (`BrowserRouter`) while rendering a different component (`TransactionDetailPage`). To locate the bad setState() call inside `TransactionDetailPage`, follow the stack trace as described in https://react.dev/link/setstate-in-render
```

Rendering must only describe the screen. `navigate` updates the router's state, so it belongs in an event handler, as in `handleDelete`. Showing a message with a link, as the correct version does, is also kinder to the user, who learns why the page they wanted is not there. If you really need an automatic redirect, return `<Navigate to="/transactions" />`.

**Error 3: Using a relative link in a shared component.**

```jsx
// Wrong
<Link to={`transactions/${id}`}>{title}</Link>

// Correct
<Link to={`/transactions/${id}`}>{title}</Link>
```

Without the leading slash, the link is relative to the page it appears on. On the Transactions page, clicking "Groceries" leads to the wrong address.

The address and the page after clicking "Groceries" on `/transactions`:

```text
/transactions/transactions/2

Page not found

The page you are looking for does not exist.

Go back to the dashboard
```

The relative path `transactions/2` was added to the current address, `/transactions`. On the Dashboard, at `/`, the same link happens to work, which makes this bug easy to miss. `TransactionItem` is rendered on several pages, so its links must be absolute.

---

## 7. Exercises

**Exercise 1:** Add a "Duplicate" button to the detail page, between Delete and Edit. It should add a copy of the transaction with " (copy)" at the end of its title, and then open the copy's detail page. Pass `onAdd` to the detail page from `App`.

**Exercise 2:** Make the Not Found page show the address that was not found, such as `There is no page at /reports.` Use React Router's `useLocation` hook, which returns an object whose `pathname` property is the current path.

**Exercise 3:** Keep the selected category in the URL, so a filtered list can be bookmarked or shared, such as `/transactions?category=Food`. Replace the `category` state in `TransactionsPage` with React Router's `useSearchParams` hook. It works like `useState`: it returns the current query parameters and a function to set them. Read the category with `searchParams.get("category")`, falling back to `"All"`, and set it with `setSearchParams({ category: newCategory })`, or with `{}` for "All".

---

## 8. Solutions

**Solution for Exercise 1:**

In `src/App.jsx`, pass `onAdd` to the detail route:

```jsx
<Route
  path="transactions/:id"
  element={<TransactionDetailPage transactions={transactions} onAdd={handleAdd} onDelete={handleDelete} />}
/>
```

In `src/pages/TransactionDetailPage.jsx`, receive it, add a handler next to `handleDelete`, and add the button:

```jsx
function TransactionDetailPage({ transactions, onAdd, onDelete }) {
```

```jsx
function handleDuplicate() {
  const newId = onAdd({ title: `${title} (copy)`, amount, type, category, date });
  navigate(`/transactions/${newId}`);
}
```

```jsx
<button type="button" className="button" onClick={handleDuplicate}>
  Duplicate
</button>
```

`handleAdd` already returns the new id, so duplicating is the same "add, then navigate" pattern as the Add page. The object passed to `onAdd` has the five form properties, and `App` gives it a new id. Duplicating "Groceries" opens a new detail page titled "Groceries (copy)" at a new address.

**Solution for Exercise 2:**

Update `src/pages/NotFoundPage.jsx`.

```jsx
import { Link, useLocation } from "react-router";

function NotFoundPage() {
  const location = useLocation();

  return (
    <section className="panel">
      <h2 className="page-title">Page not found</h2>
      <p className="empty-state">There is no page at {location.pathname}.</p>
      <p>
        <Link to="/">Go back to the dashboard</Link>
      </p>
    </section>
  );
}

export default NotFoundPage;
```

`useLocation` returns information about the current address: `pathname` is the path, `search` is the query string, and so on. Visiting `/reports` shows:

```text
Page not found

There is no page at /reports.

Go back to the dashboard
```

**Solution for Exercise 3:**

In `src/pages/TransactionsPage.jsx`, import the hook and replace the category state:

```jsx
import { useNavigate, useSearchParams } from "react-router";
```

```jsx
const [searchParams, setSearchParams] = useSearchParams();
const category = searchParams.get("category") ?? "All";
```

And update the callback passed to `Filters`:

```jsx
onCategoryChange={(newCategory) => setSearchParams(newCategory === "All" ? {} : { category: newCategory })}
```

`searchParams.get("category")` returns the value of `?category=` in the address, or `null` when there is none, so `??` falls back to `"All"`. `setSearchParams` changes the query string, and React Router re-renders the page with the new value. Opening `/transactions?category=Food` directly shows the Food filter already selected and "Showing 2 transactions". Choosing Transport changes the address to `/transactions?category=Transport` and the count to "Showing 1 transaction", and choosing "All categories" removes the query string, leaving `/transactions`. The category is now state stored in the URL: it survives a refresh and works in a shared link.

---

## Next Up - Lesson 19

In this lesson you created dynamic routes. The detail page reads the id from the address with `useParams`, converts it to a number, and handles ids that do not exist. Editing moved to its own page, the Add page opens the new transaction after saving, and `useNavigate` moves users to the right place after each action. You also learned the difference between absolute and relative links, and why `navigate` belongs in event handlers.

Look at the routes in `App`: almost every page receives `transactions`, and several receive `onAdd`, `onUpdate`, `onDelete`, or `categories`. As the app grows, passing the same props through every route gets repetitive, and components in the middle have to forward props they do not use. In Lesson 19, you will solve this with **React Context**: you will create a `TransactionsContext` that makes the transactions and their actions available to any component that asks for them.
