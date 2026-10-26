## 1. Before You Begin

In Lesson 12, you lifted the search text up to `App`, and the transaction list now shows only the transactions that match. Along the way, you met an important idea: `visibleTransactions` is not stored in state. It is calculated from `transactions` and `search` every time `App` renders.

This lesson puts that idea at the center. The summary cards have shown the same three numbers since Module 2, because `App` passes fixed values to `Summary`. You will replace them with totals calculated from the transactions, so every add, edit, and delete updates the dashboard instantly. Then you will add a category filter next to the search box, combine both filters, and sort the list by date. All of these values are **derived data**: values computed from existing state rather than stored as state. Knowing what belongs in state and what should be derived is one of the most valuable skills in React, and a common source of bugs in AI-generated code.

### What You'll Build

- A `getTotals` helper that calculates income, expense, and balance from any list of transactions.
- Summary cards and a spending bar that update the moment a transaction is added, edited, or deleted.
- A shared list of categories, used by both the form and the filters.
- A category dropdown next to the search box, which works together with the search.
- A transaction list that is always sorted by date, newest first, wherever a transaction was added.

### What You'll Learn

- ✅ What derived data is and how it differs from state
- ✅ How to calculate totals from an array in a helper function
- ✅ How to combine several filters with chained `filter` calls
- ✅ How to sort a list by date with `sort` and `localeCompare`
- ✅ Why `sort` changes an array in place, and why that is safe after `filter`
- ✅ How to share constant data between components with a module
- ✅ Why storing derived values in state causes bugs

### What You'll Need

- The Spendly project from Lesson 12
- The development server running with `npm run dev`
- If you completed the Lesson 12 exercises, remove the `totalCount` prop and the category part of the search before you start, so your code matches this lesson.

---

## 2. Calculate the Totals from the Transactions

In Lesson 1, you calculated Spendly's income, expense, and balance in the browser console with a `for...of` loop. That exact logic belongs in Spendly now. Instead of writing it inside a component, you will put it in a helper function, like `formatAmount`, so it can be reused and tested on its own.

### Step 1: Create the getTotals Helper

Create `src/utils/transactions.js`.

```javascript
export function getTotals(transactions) {
  let income = 0;
  let expense = 0;

  for (const transaction of transactions) {
    if (transaction.type === "income") {
      income = income + transaction.amount;
    } else {
      expense = expense + transaction.amount;
    }
  }

  return { income, expense, balance: income - expense };
}
```

Here is what this code does:

- `getTotals` receives any array of transactions as a parameter, instead of using a fixed array. You can pass it all transactions, filtered transactions, or an empty array.
- The loop is the one you wrote in Lesson 1: income amounts are added to `income`, and everything else is added to `expense`.
- `return { income, expense, balance: income - expense };` returns all three values in one object. `{ income, expense }` is a shorthand for `{ income: income, expense: expense }`, used when a property has the same name as the variable that holds its value.

The function has no JSX and no React in it. It takes data in and returns data out, which makes it easy to understand and to reuse.

### Step 2: Use the Totals in App

Open `src/App.jsx`. Import the helper next to the other imports:

```jsx
import { getTotals } from "./utils/transactions.js";
```

Then add this line inside `App`, right before the line that defines `editingTransaction`:

```jsx
const totals = getTotals(transactions);
```

Finally, replace the fixed numbers passed to `Summary`:

```jsx
<Summary income={totals.income} expense={totals.expense} />
```

Here is what this does:

- `getTotals(transactions)` runs on every render of `App`, using the current `transactions` state.
- `totals.income` and `totals.expense` are passed to `Summary`, which already calculates the balance and the spending bar from those two props. `Summary` itself needs no changes.

Save the file. The summary looks the same as before, because the sample data really does add up to $3,400 of income and $177 of expenses. Now add a lunch for `12.50`, dated October 20, 2026.

What you see in the summary:

```text
Income
$3,400
Expense
$189.50
Balance
$3,210.50

You have spent 6% of your income.
```

Then delete "Monthly salary".

What you see in the summary:

```text
Income
$400
Expense
$189.50
Balance
$210.50

You have spent 47% of your income.
```

The dashboard is finally live. You did not write any code to "update the totals" when adding or deleting. The handlers only change `transactions`, React re-renders `App`, and `getTotals` calculates fresh totals from the new state. Refresh the page to restore the sample data.

---

## 3. Filter by Category and Sort by Date

Search alone is not enough for a finance app. Users also want to answer questions like "how much did I spend on food?" In this section you will add a category filter, combine it with the search, and make sure the list is always in date order.

### Step 1: Share the Category List

The category filter needs the same list of categories as the form. Copying the array into a second file would give you two lists that could drift apart. Instead, move it into its own module. Create `src/data/categories.js`.

```javascript
export const categories = ["Food", "Transport", "Shopping", "Bills", "Entertainment", "Salary", "Freelance", "Other"];
```

Then open `src/components/TransactionForm.jsx`, delete the `const categories = [...]` line at the top, and import the shared list instead. The top of the file now looks like this:

```jsx
import { useState } from "react";
import { categories } from "../data/categories.js";
```

The rest of `TransactionForm` stays exactly the same, because the imported variable has the same name. Save the file and open the form to check that the category dropdown still lists all eight categories.

### Step 2: Add the Category Dropdown to Filters

Replace `src/components/Filters.jsx` with this version.

```jsx
import { categories } from "../data/categories.js";

function Filters({ search, onSearchChange, category, onCategoryChange }) {
  return (
    <form className="filters" onSubmit={(event) => event.preventDefault()}>
      <div className="filter-field">
        <label htmlFor="search">Search transactions</label>
        <div className="search-row">
          <input
            id="search"
            type="text"
            placeholder="e.g. Groceries"
            value={search}
            onChange={(event) => onSearchChange(event.target.value)}
          />
          <button type="button" className="button" onClick={() => onSearchChange("")}>
            Clear
          </button>
        </div>
      </div>

      <div className="filter-field">
        <label htmlFor="category-filter">Category</label>
        <select id="category-filter" value={category} onChange={(event) => onCategoryChange(event.target.value)}>
          <option value="All">All categories</option>
          {categories.map((name) => (
            <option key={name} value={name}>
              {name}
            </option>
          ))}
        </select>
      </div>
    </form>
  );
}

export default Filters;
```

Here is what changed:

- The search label and row are wrapped in a `filter-field` div, so the form can lay out two fields side by side.
- The new dropdown follows the same "controlled by the parent" pattern as the search box: `value={category}` shows the parent's state, and `onChange` reports the new value with `onCategoryChange`.
- The first option, "All categories", has the value `"All"`. It is a special value that means "do not filter by category". The other options come from the shared `categories` list.
- The id is `category-filter`, not `category`, because the form already has an input with the id `category`. Ids must be unique on the page, and when the form panel is open, both elements exist at the same time.

Update the filter styles in `src/App.css`. Replace the `.filters` rule and the `.filters input` rule with these rules, and keep the `.search-row` rules from Lesson 12 between them.

```css
.filters {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 16px;
}

.filter-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
```

```css
.filters input,
.filters select {
  padding: 10px 12px;
  font-size: 16px;
  font-family: inherit;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background-color: var(--color-surface);
}
```

The filters now use a grid with a wider column for the search and a narrower one for the category. The input rule also covers the new `select`. Finally, make the filters stack on small screens by adding `.filters` to the media query at the end of the file:

```css
@media (max-width: 600px) {
  .summary,
  .filters {
    grid-template-columns: 1fr;
  }
}
```

### Step 3: Combine the Filters and Sort in App

Replace `src/App.jsx` with the final version for this lesson.

```jsx
import { useState } from "react";
import "./App.css";
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import TransactionForm from "./components/TransactionForm.jsx";
import { sampleTransactions } from "./data/transactions.js";
import { getTotals } from "./utils/transactions.js";

function App() {
  const [transactions, setTransactions] = useState(sampleTransactions);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("All");

  const totals = getTotals(transactions);
  const editingTransaction = transactions.find((transaction) => transaction.id === editingId);

  const visibleTransactions = transactions
    .filter((transaction) => category === "All" || transaction.category === category)
    .filter((transaction) => transaction.title.toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => b.date.localeCompare(a.date));

  const isFiltering = search !== "" || category !== "All";

  function closeForm() {
    setIsFormOpen(false);
    setEditingId(null);
  }

  function handleAddClick() {
    if (isFormOpen) {
      closeForm();
    } else {
      setIsFormOpen(true);
    }
  }

  function handleEdit(id) {
    setEditingId(id);
    setIsFormOpen(true);
  }

  function handleSave(transactionData) {
    if (editingTransaction) {
      setTransactions(
        transactions.map((transaction) =>
          transaction.id === editingId ? { ...transaction, ...transactionData } : transaction,
        ),
      );
    } else {
      const newTransaction = { id: Date.now(), ...transactionData };
      setTransactions([newTransaction, ...transactions]);
    }
    closeForm();
  }

  function handleDelete(id) {
    setTransactions(transactions.filter((transaction) => transaction.id !== id));
  }

  return (
    <main className="app">
      <Header userName="Dina" />
      <Summary income={totals.income} expense={totals.expense} />
      <div className="toolbar">
        <button type="button" className="button button-primary" onClick={handleAddClick}>
          {isFormOpen ? "Close" : "+ Add transaction"}
        </button>
      </div>
      {isFormOpen && (
        <section className="panel">
          <TransactionForm
            key={editingId ?? "new"}
            initialTransaction={editingTransaction}
            onSubmit={handleSave}
            onCancel={closeForm}
          />
        </section>
      )}
      <Filters
        search={search}
        onSearchChange={setSearch}
        category={category}
        onCategoryChange={setCategory}
      />
      <TransactionList
        transactions={visibleTransactions}
        emptyMessage={isFiltering ? "No transactions match your filters." : undefined}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />
    </main>
  );
}

export default App;
```

Here is what is new:

- `const [category, setCategory] = useState("All");` stores the selected category, starting with "All".
- `visibleTransactions` is now built in three steps, chained one after another. Each method returns a new array, and the next method works on that array:
  1. `.filter((transaction) => category === "All" || transaction.category === category)` keeps every transaction when the category is "All". Otherwise it keeps only the ones in the chosen category. The `||` means "or": the condition is true if either side is true.
  2. `.filter(...)` with the search text, unchanged from Lesson 12.
  3. `.sort((a, b) => b.date.localeCompare(a.date))` puts the result in date order, newest first. `sort` calls the function with two transactions, `a` and `b`. `localeCompare` compares two strings and returns a negative number, zero, or a positive number, which tells `sort` which one comes first. Because Spendly stores dates as `YYYY-MM-DD` text, comparing them as strings gives the right date order. Writing `b` before `a` reverses the order, so later dates come first.
- `isFiltering` is `true` when either filter is active. It replaces the search-only check for the empty message, which now says "No transactions match your filters."
- `Filters` receives the category value and its setter, next to the search props.

`sort` has one trap: unlike `filter` and `map`, it **changes the array it is called on**. Here that is safe, because it is called on the brand-new array returned by `filter`, never on the `transactions` state itself. You will read more about this in Section 5.

Save all files. Choose "Food" in the category dropdown.

What you see in the transactions section:

```text
Transactions

Showing 2 transactions

Coffee with friends
Food · 2026-10-09
-$12
Edit
Delete
Groceries
Food · 2026-10-03
-$120
Edit
Delete
```

Keep "Food" selected and type `gro` in the search box. The list narrows to "Groceries" only, because a transaction must pass both filters. Then switch the category to "Transport" while `gro` is still in the search box.

What you see in the transactions section:

```text
Transactions

No transactions match your filters.
```

---

## 4. Run and Test

Clear the search and set the category back to "All categories". Now check the sorting: add a transaction titled `Phone bill`, amount `35`, category Bills, dated October 2, 2026. New transactions are added to the start of the `transactions` array, but the list does not show them at the top anymore. "Phone bill" lands between "Groceries" (October 3) and "Monthly salary" (October 1), because the list is sorted by date.

The titles in the list, from top to bottom (the salary's title element also contains its "Large" badge):

```text
Coffee with friends | Freelance design | Bus pass | Groceries | Phone bill | Monthly salaryLarge
```

What you see in the summary:

```text
Income
$3,400
Expense
$212
Balance
$3,188

You have spent 6% of your income.
```

The expense total went from $177 to $212, and the spending bar grew a little. Edit the phone bill's amount, or delete it, and the cards follow every change.

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

## 5. State or Derived Data?

`App` now has five pieces of state and four derived values. Here they are side by side:

| Stored in state | Derived on every render |
| --- | --- |
| `transactions` | `totals` (from `transactions`) |
| `isFormOpen` | `editingTransaction` (from `transactions` and `editingId`) |
| `editingId` | `visibleTransactions` (from `transactions`, `category`, and `search`) |
| `search` | `isFiltering` (from `search` and `category`) |
| `category` | |

The rule behind this split is simple: **if a value can be calculated from other state or props, calculate it; do not store it.** State should hold only the minimal set of facts that cannot be worked out from anything else: what the transactions are, what the user typed, which transaction is being edited.

Why does this matter so much? Imagine storing the totals in state. Every handler that changes `transactions` (add, edit, delete, and any future ones like "import" or "duplicate") would also have to remember to update the totals. Forget one, and the dashboard shows wrong numbers. Derived values cannot get out of sync, because they are recalculated from the source every time. Fewer pieces of state also mean fewer things to keep in your head.

**"Isn't recalculating on every render slow?"** For lists of hundreds or even thousands of items, filtering and summing take a fraction of a millisecond. Do not optimize until you have measured a real problem. React does provide a hook called `useMemo` for caching expensive calculations, but Spendly does not need it.

**Array methods that change the original.** Most of the array methods you use in React return a new array and leave the original alone: `filter`, `map`, `slice`, and `concat`. A few change the array they are called on: `sort`, `reverse`, `push`, `pop`, `splice`, `shift`, and `unshift`. Never call those directly on state. When you need to sort or reverse, make a copy first. In Spendly, `filter` already makes the copy. When no filter comes first, use `[...array].sort(...)`. Modern browsers also support `toSorted()`, which returns a sorted copy.

---

## 6. Fix the Errors in Your Code

Derived data bugs are subtle, because the code usually runs without any error.

**Error 1: Storing derived data in state.**

It can look reasonable to keep the totals in state, so they are "saved".

```jsx
// Wrong
const [totals] = useState(getTotals(transactions));

// Correct
const totals = getTotals(transactions);
```

The wrong version shows correct totals at first. Then add a lunch for `12.50`.

What you see in the summary after adding the lunch:

```text
Income
$3,400
Expense
$177
Balance
$3,223

You have spent 5% of your income.
```

And in the count line of the transaction list:

```text
Showing 6 transactions
```

The list has six transactions, but the summary still shows the totals of the original five. Remember from Lesson 9 that `useState` uses its initial value only on the first render. After that, the totals in state never change, because no code calls a setter for them. Derived values belong in plain variables, recalculated on each render.

**Error 2: Forgetting the "All" option in the filter.**

```jsx
// Wrong
.filter((transaction) => transaction.category === category)

// Correct
.filter((transaction) => category === "All" || transaction.category === category)
```

With the wrong version, the list is empty as soon as the page loads.

What you see in the transactions section:

```text
Transactions

No transactions yet. Add your first one to get started!
```

No transaction has the category `"All"`, so the filter removes everything. The message is also misleading, because `isFiltering` is `false` when "All" is selected. A filter must handle its "show everything" value explicitly. Read the correct condition aloud: "keep it if the category is All, or if it matches the chosen category".

**Error 3: Totals calculated from text amounts.**

This error is caused by data, not by `getTotals` itself. Suppose one amount was stored as text, which is exactly what happens if you forget `Number(amount)` in the form (Error 3 in Lesson 10). Here the bus pass is stored as `"45"`:

```javascript
// Wrong
{ id: 3, title: "Bus pass", amount: "45", type: "expense", category: "Transport", date: "2026-10-05" },

// Correct
{ id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
```

With the wrong data, the summary goes haywire.

What you see in the summary:

```text
Income
$3,400
Expense
$1,245,120.00
Balance
-$1,241,720

You have spent 100% of your income.
```

The loop adds `12`, then reaches `"45"`, and `+` with a string joins text: `12 + "45"` is `"1245"`. Adding `120` gives `"1245120"`. `formatAmount` then turns that text into a large number. This is why every amount must be converted to a number at the moment it enters the app, in the form's submit handler. Data mistakes travel: a bug in Lesson 10's form only becomes visible in Lesson 13's totals.

---

## 7. Exercises

**Exercise 1:** Make the summary follow the filters. When a filter is active, the summary cards should show the totals of the visible transactions only; when no filter is active, they show the totals of all transactions. Selecting "Food" should show an income of `$0` and an expense of `$132`.

**Exercise 2:** Let users choose the sort order. Add a third field to `Filters`, labeled "Sort by", with two options: "Newest first" (value `newest`) and "Oldest first" (value `oldest`). Store the choice in a `sortOrder` state in `App` and use it in the `sort` call.

**Exercise 3:** Add a `getBiggestExpense(transactions)` helper to `src/utils/transactions.js` that returns the expense with the largest amount, or `undefined` if there are no expenses. Show it in `Summary`, under the spending text, as `Biggest expense: Groceries ($120)`. Pass it from `App` as a prop named `biggestExpense`, calculated from all transactions.

---

## 8. Solutions

**Solution for Exercise 1:**

Move the `totals` line in `src/App.jsx` below `isFiltering`, and choose which list to total.

```jsx
const isFiltering = search !== "" || category !== "All";
const totals = getTotals(isFiltering ? visibleTransactions : transactions);
```

The line has to come after `visibleTransactions` and `isFiltering`, because it uses both. When no filter is active, `visibleTransactions` contains the same transactions as `transactions`, so the ternary is mostly about making the intention clear. With "Food" selected, the summary shows:

```text
Income
$0
Expense
$132
Balance
-$132

You have spent 0% of your income.
```

The spending text says `0%` because `Summary` returns `0` when there is no income, to avoid dividing by zero. Because `getTotals` takes any array as a parameter, this change needed one line. That is the benefit of writing helpers that receive their data instead of reaching for a fixed variable.

**Solution for Exercise 2:**

Add the state to `src/App.jsx`.

```jsx
const [sortOrder, setSortOrder] = useState("newest");
```

Use it in the `sort` call.

```jsx
.sort((a, b) => (sortOrder === "newest" ? b.date.localeCompare(a.date) : a.date.localeCompare(b.date)));
```

Pass it to `Filters`.

```jsx
<Filters
  search={search}
  onSearchChange={setSearch}
  category={category}
  onCategoryChange={setCategory}
  sortOrder={sortOrder}
  onSortOrderChange={setSortOrder}
/>
```

In `src/components/Filters.jsx`, add the two props to the parameter list and a third field after the category field.

```jsx
function Filters({ search, onSearchChange, category, onCategoryChange, sortOrder, onSortOrderChange }) {
```

```jsx
<div className="filter-field">
  <label htmlFor="sort-order">Sort by</label>
  <select id="sort-order" value={sortOrder} onChange={(event) => onSortOrderChange(event.target.value)}>
    <option value="newest">Newest first</option>
    <option value="oldest">Oldest first</option>
  </select>
</div>
```

Swapping `a` and `b` reverses the comparison. Choosing "Oldest first" lists the titles in this order (again with the salary's badge text attached):

```text
Monthly salaryLarge | Groceries | Bus pass | Freelance design | Coffee with friends
```

The sort order is state, because it is a choice the user makes. The sorted list is still derived. You can also change `grid-template-columns` in `.filters` to `2fr 1fr 1fr` to fit the third field on one row.

**Solution for Exercise 3:**

Add the helper to `src/utils/transactions.js`.

```javascript
export function getBiggestExpense(transactions) {
  let biggest = undefined;

  for (const transaction of transactions) {
    if (transaction.type === "expense" && (biggest === undefined || transaction.amount > biggest.amount)) {
      biggest = transaction;
    }
  }

  return biggest;
}
```

The loop remembers the biggest expense seen so far. The first expense always wins, because `biggest` starts as `undefined`, and every later expense replaces it only if its amount is larger.

In `src/App.jsx`, import it and pass it to `Summary`.

```jsx
import { getTotals, getBiggestExpense } from "./utils/transactions.js";
```

```jsx
<Summary income={totals.income} expense={totals.expense} biggestExpense={getBiggestExpense(transactions)} />
```

In `src/components/Summary.jsx`, receive the prop and show it after the spending text.

```jsx
function Summary({ income, expense, biggestExpense }) {
```

```jsx
<p className="spending-text">You have spent {spentPercent}% of your income.</p>
{biggestExpense && (
  <p className="spending-text">
    Biggest expense: {biggestExpense.title} ({formatAmount(biggestExpense.amount)})
  </p>
)}
```

`biggestExpense && (...)` hides the line when there are no expenses, because `undefined` renders nothing. The value is derived, calculated on every render and never stored. With the sample data, the summary ends with:

```text
Biggest expense: Groceries ($120)
```

---

## Next Up - Lesson 14

In this lesson you made Spendly's dashboard live. A `getTotals` helper calculates income, expense, and balance from the transactions on every render, a shared category list feeds both the form and a new category filter, and the visible list is filtered by category and search and sorted by date in one chain. Most importantly, you learned to tell state apart from derived data, and why derived values should be calculated instead of stored. That completes Module 4.

There is one big problem left that every user will notice: refresh the page, and everything you added is gone. In Lesson 14, you will start Module 5 by learning about side effects and the `useEffect` hook, and you will use them to save Spendly's transactions in the browser's `localStorage` so they survive a refresh.
