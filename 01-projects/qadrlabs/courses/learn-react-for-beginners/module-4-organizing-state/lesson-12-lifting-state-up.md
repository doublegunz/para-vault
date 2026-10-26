## 1. Before You Begin

Module 3 made Spendly interactive: users can add, edit, and delete transactions, and the list updates instantly. Each feature needed state, and you put that state in `App`. That was not an accident, but it was also never explained. As an app grows, "where should this state live?" becomes one of the most important questions you answer, and getting it wrong leads to components that cannot talk to each other.

This lesson starts Module 4 by making the search box work. You will first give the `Filters` component its own state, the obvious first attempt, and discover that `TransactionList` has no way to see it. Then you will fix the problem with a technique called **lifting state up**: moving the state to the closest common parent of the components that need it, and passing it down as props. By the end, typing in the search box filters the transaction list instantly, and a Clear button resets the search from outside the input.

### What You'll Build

- A search box whose text is stored in `App`, so both the search box and the list can use it.
- A transaction list that shows only transactions whose title matches the search, ignoring upper and lower case.
- A message such as `No transactions match "pizza".` when nothing matches.
- A Clear button next to the search box that empties it and shows all transactions again.

### What You'll Learn

- ✅ Why sibling components cannot share state directly
- ✅ How to lift state up to the closest common parent
- ✅ How to make a component controlled by its parent through props
- ✅ The "single source of truth" principle
- ✅ How to filter a list by search text without storing the result in state
- ✅ How to decide where a piece of state should live

### What You'll Need

- The Spendly project from Lesson 11
- The development server running with `npm run dev`
- If you completed the Lesson 11 exercises, you can keep the delete confirmation. To match this lesson exactly, remove the Duplicate button and the editing highlight.

---

## 2. The Problem: Siblings Cannot Share State

Right now, `Filters` only logs what the user types. The natural first idea is to give `Filters` its own state for the search text, just like `TransactionForm` has state for its fields. Try it, and see where it leads.

### Step 1: Give Filters Its Own Search State

Replace `src/components/Filters.jsx` with this version.

```jsx
import { useState } from "react";

function Filters() {
  const [search, setSearch] = useState("");

  return (
    <form className="filters" onSubmit={(event) => event.preventDefault()}>
      <label htmlFor="search">Search transactions</label>
      <input
        id="search"
        type="text"
        placeholder="e.g. Groceries"
        value={search}
        onChange={(event) => setSearch(event.target.value)}
      />
      <p className="filters-hint">Searching for: {search}</p>
    </form>
  );
}

export default Filters;
```

Here is what this code does:

- The search input is now a controlled input, exactly like the fields in `TransactionForm`: its value lives in the `search` state.
- The form's `onSubmit` is a short inline arrow function that only prevents the page reload. Pressing `Enter` in the search box no longer needs to do anything else.
- The paragraph below the input shows the current search text, to prove the state works.

Save the file and type `coffee` in the search box.

What you see in the filters section:

```text
Search transactions

Searching for: coffee
```

And in the count line of the transaction list:

```text
Showing 5 transactions
```

`Filters` knows the search text perfectly well, but the list still shows all five transactions. The problem is structural. Look at Spendly's component tree:

```text
App
├── Header
├── Summary
├── TransactionForm (inside the panel)
├── Filters            <- the search text lives here
└── TransactionList    <- the search text is needed here
    └── TransactionItem
```

`Filters` and `TransactionList` are **siblings**: both are children of `App`. In React, data only flows **down** through props. A component can pass data to its children, but it cannot hand data sideways to a sibling or up to a parent. `TransactionList` has no way to read the `search` state, because it lives inside `Filters`, and `Filters` is not its parent.

---

## 3. Lift the State Up to App

The solution is to move the state to a component that is an ancestor of both components that need it. The **closest common parent** of `Filters` and `TransactionList` is `App`. Once `App` owns the search text, it can pass the value down to both: to `Filters` so it can display it in the input, and to the list (filtered) so it can show the matching transactions. `Filters` still needs to change the text when the user types, so `App` also passes down a function to do that. This move is called **lifting state up**.

### Step 1: Make Filters Controlled by Its Parent

Replace `src/components/Filters.jsx` with this version.

```jsx
function Filters({ search, onSearchChange }) {
  return (
    <form className="filters" onSubmit={(event) => event.preventDefault()}>
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
    </form>
  );
}

export default Filters;
```

Here is what changed:

- `useState` is gone, along with its import. `Filters` no longer owns any state.
- The component receives two props: `search`, the current text, and `onSearchChange`, a function to call with new text.
- `value={search}` displays the value that the parent passes down.
- `onChange={(event) => onSearchChange(event.target.value)}` reports the new text to the parent. The parent stores it, re-renders, and passes the new value back down as `search`. The input is still controlled; it is just controlled by `App` now.
- The new Clear button calls `onSearchChange("")`. Because the input always shows the parent's value, clearing the parent's state also clears the input.
- The input and the button are wrapped in a `search-row` div so they can sit side by side, and the "Searching for" paragraph is gone, because the list itself will now show the result.

`Filters` is now what React developers call a **controlled component**: it shows what its props say and reports changes through a callback, just like a single `<input>` with `value` and `onChange`.

Add the styles for the new row to `src/App.css`, right before the `.filters input` rule.

```css
.search-row {
  display: flex;
  gap: 8px;
}

.search-row input {
  flex: 1;
}
```

`display: flex` puts the input and the button in one row, and `flex: 1` lets the input take all the remaining width.

### Step 2: Own the Search in App and Filter the List

Now `App` must own the state and use it. Replace `src/App.jsx` with this version.

```jsx
import { useState } from "react";
import "./App.css";
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import TransactionForm from "./components/TransactionForm.jsx";
import { sampleTransactions } from "./data/transactions.js";

function App() {
  const [transactions, setTransactions] = useState(sampleTransactions);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [search, setSearch] = useState("");

  const editingTransaction = transactions.find((transaction) => transaction.id === editingId);

  const visibleTransactions = transactions.filter((transaction) =>
    transaction.title.toLowerCase().includes(search.toLowerCase()),
  );

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
      <Summary income={3400} expense={177} />
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
      <Filters search={search} onSearchChange={setSearch} />
      <TransactionList
        transactions={visibleTransactions}
        emptyMessage={search === "" ? undefined : `No transactions match "${search}".`}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />
    </main>
  );
}

export default App;
```

Here is what is new:

- `const [search, setSearch] = useState("");` is the lifted state. It has moved from `Filters` to `App`, unchanged.
- `visibleTransactions` is calculated on every render by filtering the full list:
  - `transaction.title.toLowerCase()` and `search.toLowerCase()` turn both texts into lowercase, so `"groc"` matches `"Groceries"`.
  - `.includes(...)` checks whether the title contains the search text anywhere. An empty search is contained in every string, so when the box is empty, every transaction is visible.
- `<Filters search={search} onSearchChange={setSearch} />` passes the value and the setter. You can pass a state setter directly as a callback prop, because `setSearch(text)` is exactly what `Filters` needs to call.
- `TransactionList` now receives `visibleTransactions` instead of `transactions`. It renders whatever it receives, so it needs no changes for the filtering itself.
- `emptyMessage` is a new prop for the list. When the search is empty, it is `undefined`, so the list will use its default message. When the user is searching, it says which search found nothing.

Notice what is **not** in state: `visibleTransactions`. It is calculated from two pieces of state, `transactions` and `search`, every time `App` renders. If you stored it in state too, you would have to remember to update it whenever either of them changes, and sooner or later the copies would disagree. Lesson 13 explores this idea in depth.

### Step 3: Show a Better Empty Message

Update the start of `src/components/TransactionList.jsx` so it accepts the new prop. Replace the whole file.

```jsx
import TransactionItem from "./TransactionItem.jsx";

function TransactionList({
  transactions,
  emptyMessage = "No transactions yet. Add your first one to get started!",
  onEdit,
  onDelete,
}) {
  if (transactions.length === 0) {
    return (
      <section className="transactions">
        <h2>Transactions</h2>
        <p className="empty-state">{emptyMessage}</p>
      </section>
    );
  }

  const count = transactions.length;

  return (
    <section className="transactions">
      <h2>Transactions</h2>
      <p className="transaction-count">
        Showing {count} {count === 1 ? "transaction" : "transactions"}
      </p>
      <ul>
        {transactions.map((transaction) => (
          <TransactionItem key={transaction.id} transaction={transaction} onEdit={onEdit} onDelete={onDelete} />
        ))}
      </ul>
    </section>
  );
}

export default TransactionList;
```

Here is what changed:

- The props are now written on several lines, one per prop. This is purely formatting; it keeps a long parameter list readable.
- `emptyMessage` has a default value, the original message. When `App` passes `undefined`, the default is used. This is why `App` passes `undefined` rather than an empty string when there is no search: an empty string would replace the default with nothing.
- The empty state paragraph displays `{emptyMessage}` instead of fixed text.

Save all files and type `coffee` in the search box.

What you see in the transactions section:

```text
Transactions

Showing 1 transaction

Coffee with friends
Food · 2026-10-09
-$12
Edit
Delete
```

The list filters as you type. Now type `pizza` instead.

What you see in the transactions section:

```text
Transactions

No transactions match "pizza".
```

Click "Clear". The search box empties and all five transactions come back, because `onSearchChange("")` reset the state in `App`, and both the input and the list follow it.

---

## 4. Run and Test

Test the search with different inputs:

1. Type `Groceries`. One transaction is shown.
2. Replace it with `groc` (lowercase, partial). The same transaction is still shown, and the count says "Showing 1 transaction".
3. Type `pizza`. The message `No transactions match "pizza".` appears.
4. Click "Clear". The input is empty and the count says "Showing 5 transactions".
5. Search for `coffee`, then add a new transaction titled `Coffee beans`. It appears in the filtered list immediately, because `visibleTransactions` is recalculated from the new `transactions` state.
6. While searching, delete or edit a matching transaction. The filtered list updates correctly, for the same reason.

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

## 5. Deciding Where State Lives

Lifting state up is the answer to a question you will ask for every piece of state you create: **which component should own this?** Here is a simple process that works for almost every case:

1. List every component that **reads** the state or **changes** it.
2. Find their **closest common parent** in the component tree.
3. Put the state there, or higher if needed, and pass it down as props, together with callbacks to change it.

Applied to Spendly so far:

| State | Used by | Closest common parent | Lives in |
| --- | --- | --- | --- |
| `title`, `amount`, and the other form fields | `TransactionForm` only | `TransactionForm` | `TransactionForm` |
| `isFormOpen` | the toolbar button and the panel, both rendered by `App` | `App` | `App` |
| `transactions` | the form (adding, editing), the list, and soon `Summary` | `App` | `App` |
| `search` | `Filters` (to show it) and the list (to filter it) | `App` | `App` |

**Keep state as low as possible, but no lower.** State that only one component needs, such as the form fields, should stay in that component. Putting everything in `App` "just in case" makes `App` crowded and causes it to re-render for every keystroke in every field. Lift state only when a second component needs it.

**A single source of truth.** Every piece of data should have exactly one owner. If two components each keep their own copy, the copies will eventually disagree, as you will see in Error 1 below. When you lift state up, delete it from the child, and let the child receive it through props.

**Data down, events up, one more time.** Lifting state up is the pattern from Lesson 8 applied to state: the owner passes data down as props, and the children report changes up by calling functions. Every React app, however large, is built from this pattern.

---

## 6. Fix the Errors in Your Code

These mistakes are typical when state is moved between components.

**Error 1: Keeping a copy of the state in the child.**

A half-finished refactor often leaves state in both places.

```jsx
// Wrong
import { useState } from "react";

function Filters({ onSearchChange }) {
  const [search, setSearch] = useState("");

  function handleChange(event) {
    setSearch(event.target.value);
    onSearchChange(event.target.value);
  }

  return (
    <form className="filters" onSubmit={(event) => event.preventDefault()}>
      <label htmlFor="search">Search transactions</label>
      <div className="search-row">
        <input id="search" type="text" placeholder="e.g. Groceries" value={search} onChange={handleChange} />
        <button type="button" className="button" onClick={() => onSearchChange("")}>
          Clear
        </button>
      </div>
    </form>
  );
}

export default Filters;

// Correct
function Filters({ search, onSearchChange }) {
  return (
    <form className="filters" onSubmit={(event) => event.preventDefault()}>
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
    </form>
  );
}

export default Filters;
```

With the wrong version, typing filters the list correctly, because both copies are updated together. The bug appears when you click "Clear".

Search box value and count line after typing `bus` and clicking Clear:

```text
Search box: bus
Showing 5 transactions
```

The list shows all transactions again, because `App`'s copy was cleared, but the search box still says `bus`, because it displays the child's own copy, which nobody cleared. Two sources of truth now disagree. Remove the child's state and display the prop.

**Error 2: Passing the event instead of the value.**

```jsx
// Wrong
onChange={(event) => onSearchChange(event)}

// Correct
onChange={(event) => onSearchChange(event.target.value)}
```

With the wrong version, the page goes blank as soon as you type the first letter, and the console shows:

```text
TypeError: search.toLowerCase is not a function
```

`onSearchChange` is `setSearch`, so the whole event object was stored as the search state. When `App` re-rendered, `search.toLowerCase()` failed, because an event object has no `toLowerCase` method. When a callback prop expects a value, the child must extract it from the event first. Reading the error carefully helps: it names the variable (`search`) and says it is not what the code expected.

**Error 3: Forgetting to ignore upper and lower case.**

```jsx
// Wrong
const visibleTransactions = transactions.filter((transaction) =>
  transaction.title.includes(search),
);

// Correct
const visibleTransactions = transactions.filter((transaction) =>
  transaction.title.toLowerCase().includes(search.toLowerCase()),
);
```

The wrong version only finds matches with exactly the same capitalization.

What you see in the transactions section after typing `groceries`:

```text
Transactions

No transactions match "groceries".
```

`includes` is case-sensitive: `"Groceries".includes("groceries")` is `false`. Users rarely type capital letters in a search box, so convert both sides to lowercase before comparing.

---

## 7. Exercises

**Exercise 1:** When the list is filtered, the count line should make that clear: show `Showing 2 of 5 transactions` while a search is active, and the usual `Showing 5 transactions` when it is not. Pass the total number of transactions to `TransactionList` as a new prop named `totalCount`.

**Exercise 2:** Make the search match the category as well as the title, so that typing `food` shows both "Coffee with friends" and "Groceries".

**Exercise 3:** Let users clear the search by pressing the `Escape` key while the search box has focus. Use the `onKeyDown` event and `event.key`.

---

## 8. Solutions

**Solution for Exercise 1:**

In `src/App.jsx`, pass the total.

```jsx
<TransactionList
  transactions={visibleTransactions}
  totalCount={transactions.length}
  emptyMessage={search === "" ? undefined : `No transactions match "${search}".`}
  onEdit={handleEdit}
  onDelete={handleDelete}
/>
```

In `src/components/TransactionList.jsx`, add `totalCount` to the props and change the count paragraph.

```jsx
function TransactionList({
  transactions,
  totalCount,
  emptyMessage = "No transactions yet. Add your first one to get started!",
  onEdit,
  onDelete,
}) {
```

```jsx
<p className="transaction-count">
  {count === totalCount
    ? `Showing ${count} ${count === 1 ? "transaction" : "transactions"}`
    : `Showing ${count} of ${totalCount} transactions`}
</p>
```

`App` knows both numbers, so it passes the total down. The list compares the two: when every transaction is shown, the message is unchanged, and otherwise it shows "X of Y". Each branch is a template literal, and the first one contains a nested ternary for the singular and plural. Combined with Exercise 2, searching for `food` gives:

```text
Showing 2 of 5 transactions
```

**Solution for Exercise 2:**

Change the filter in `src/App.jsx` so it searches a combined text.

```jsx
const visibleTransactions = transactions.filter((transaction) =>
  `${transaction.title} ${transaction.category}`.toLowerCase().includes(search.toLowerCase()),
);
```

The template literal joins the title and the category with a space, for example `"Groceries Food"`, and the search checks that combined text. Typing `food` now matches both food transactions.

What you see in the transactions section:

```text
Transactions

Showing 2 of 5 transactions

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

(The "2 of 5" wording comes from Exercise 1.) Only `App` changed. `Filters` and `TransactionList` did not need to know that the search rules are different, which shows the benefit of keeping the logic with the state that owns it.

**Solution for Exercise 3:**

Add an `onKeyDown` handler to the search input in `src/components/Filters.jsx`.

```jsx
<input
  id="search"
  type="text"
  placeholder="e.g. Groceries"
  value={search}
  onChange={(event) => onSearchChange(event.target.value)}
  onKeyDown={(event) => {
    if (event.key === "Escape") {
      onSearchChange("");
    }
  }}
/>
```

`onKeyDown` fires for every key press, and `event.key` holds the name of the key, such as `"Escape"`, `"Enter"`, or `"a"`. The arrow function uses curly braces because it contains an `if` statement. Because the search state lives in `App`, the Escape key and the Clear button both reset it with the same call, and the input, the list, and the count update together. After typing `food` and pressing Escape, the search box is empty and the count says "Showing 5 transactions".

---

## Next Up - Lesson 13

In this lesson you learned why sibling components cannot share state, and you solved it by lifting the search text up to `App`, their closest common parent. `Filters` became a component controlled by its parent through a value prop and a callback, the list now shows only matching transactions, and a Clear button resets the search from outside the input. You also learned a simple process for deciding where any piece of state should live.

There is still one part of Spendly that ignores the data: the summary cards always show `$3,400`, `$177`, and `$3,223`, no matter what you add or delete. In Lesson 13, you will calculate the income, expense, and balance from the transactions, add a category filter next to the search box, and learn why values like totals and filtered lists should be **derived** from state instead of being stored in it.
