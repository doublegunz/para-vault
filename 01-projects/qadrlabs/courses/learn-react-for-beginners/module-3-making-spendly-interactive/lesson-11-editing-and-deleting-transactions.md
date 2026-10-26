## 1. Before You Begin

In Lesson 10, you built `TransactionForm`, and users can now add their own transactions to Spendly. But everyone makes mistakes: a typo in a title, the wrong amount, a transaction entered twice. Right now the Delete buttons only write to the console, and there is no way to change a transaction once it is saved.

This lesson completes the basic operations every list app needs. You will make the Delete buttons remove transactions with the array method `filter`, add an Edit button that opens the same form already filled with a transaction's data, and save the changes with `map`. Behind both features is one rule that matters more than any other in React: **state is never changed in place**. You always build a new array or a new object. By the end of the lesson you will know the standard immutable patterns for adding, removing, and updating items, and you will have seen what goes wrong when the rule is broken.

### What You'll Build

- Delete buttons that remove a transaction from the list immediately.
- An Edit button on every row that opens the form with the title "Edit transaction", filled with that transaction's values.
- A "Save changes" button that updates the transaction in the list without changing its position or id.
- A `TransactionForm` that works for both adding and editing.

### What You'll Learn

- ✅ How to remove an item from state with `filter`
- ✅ How to update one item in an array with `map` and the object spread syntax
- ✅ What immutability means and why React depends on it
- ✅ How to find an item with `find` and derive it from state instead of copying it
- ✅ How to reuse one form for adding and editing with an optional prop and a default value
- ✅ How the `key` prop resets a component's state
- ✅ The nullish coalescing operator `??`

### What You'll Need

- The Spendly project from Lesson 10
- The development server running with `npm run dev`

---

## 2. Delete a Transaction with filter

Deleting is the simplest change, so it is a good place to start. You already have every piece: each Delete button calls `onDelete(id)`, and the call arrives in `App`'s `handleDelete`. All that is missing is the code that removes the transaction from state.

### Step 1: Remove the Transaction in handleDelete

You learned the `filter` method in Lesson 6: it returns a **new array** containing only the items for which a function returns `true`. To delete a transaction, keep every transaction whose id is **not** the one to delete. Open `src/App.jsx` and replace `handleDelete`.

```jsx
function handleDelete(id) {
  setTransactions(transactions.filter((transaction) => transaction.id !== id));
}
```

Here is what this code does:

- `transactions.filter(...)` walks through every transaction and calls the arrow function for each one.
- `transaction.id !== id` is `true` for every transaction except the one being deleted, so all the others are kept.
- `filter` returns a new array with one item fewer, and `setTransactions` stores it as the new state. The original array is never touched.

Save the file and click "Delete" on "Bus pass".

What you see in the transactions section:

```text
Transactions

Showing 4 transactions

Coffee with friends
Food · 2026-10-09
-$12
Delete
Freelance design
Freelance · 2026-10-08
+$400
Delete
Groceries
Food · 2026-10-03
-$120
Delete
Monthly salaryLarge
Salary · 2026-10-01
+$3,000
Delete
```

The row disappears and the count drops to 4. One line of code was enough, because the plumbing from Lesson 8 was already in place. Refresh the page to bring the sample data back.

---

## 3. Edit a Transaction

Editing needs more pieces. The user clicks Edit on a row, the form opens with that row's values, the user changes something, and the form saves the changes back to the same transaction. Rather than building a second form, you will teach `TransactionForm` to do both jobs.

### Step 1: Add an Edit Button to Every Row

The Edit button follows the same pattern as Delete: the row calls a prop with its id. Replace `src/components/TransactionItem.jsx`.

```jsx
import { formatAmount } from "../utils/format.js";

function TransactionItem({ transaction, onEdit, onDelete }) {
  const { id, title, amount, type, category, date } = transaction;
  const sign = type === "income" ? "+" : "-";

  return (
    <li className="transaction-item">
      <div className="transaction-info">
        <span className="transaction-title">
          {title}
          {amount >= 1000 && <span className="badge">Large</span>}
        </span>
        <span className="transaction-meta">
          {category} · {date}
        </span>
      </div>
      <div className="transaction-actions">
        <span className={`transaction-amount ${type}`}>
          {sign}
          {formatAmount(amount)}
        </span>
        <button type="button" className="button small-button" onClick={() => onEdit(id)}>
          Edit
        </button>
        <button type="button" className="button small-button delete-button" onClick={() => onDelete(id)}>
          Delete
        </button>
      </div>
    </li>
  );
}

export default TransactionItem;
```

Here is what changed:

- The component receives a new `onEdit` prop and calls it with the row's id when "Edit" is clicked.
- Both small buttons now share a `small-button` class for their size, and the Delete button adds `delete-button` only for its red color.

Pass `onEdit` through `src/components/TransactionList.jsx`.

```jsx
import TransactionItem from "./TransactionItem.jsx";

function TransactionList({ transactions, onEdit, onDelete }) {
  if (transactions.length === 0) {
    return (
      <section className="transactions">
        <h2>Transactions</h2>
        <p className="empty-state">No transactions yet. Add your first one to get started!</p>
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

The list simply forwards the new function to every row, as it already does with `onDelete`.

Finally, in `src/App.css`, replace the `.delete-button` rule from Lesson 8 with these two rules.

```css
.small-button {
  padding: 4px 10px;
  font-size: 12px;
}

.delete-button {
  color: var(--color-expense);
}
```

The size moves to `.small-button` so that both buttons share it, and `.delete-button` keeps only the color. Do not save `App.jsx` yet; it does not pass `onEdit` until Step 3.

### Step 2: Make the Form Work for Adding and Editing

The form needs to start with existing values when editing, and with empty values when adding. You can do that with one optional prop, `initialTransaction`. Replace `src/components/TransactionForm.jsx`.

```jsx
import { useState } from "react";

const categories = ["Food", "Transport", "Shopping", "Bills", "Entertainment", "Salary", "Freelance", "Other"];

const emptyTransaction = {
  title: "",
  amount: "",
  type: "expense",
  category: "Food",
  date: "",
};

function TransactionForm({ initialTransaction = emptyTransaction, onSubmit, onCancel }) {
  const [title, setTitle] = useState(initialTransaction.title);
  const [amount, setAmount] = useState(String(initialTransaction.amount));
  const [type, setType] = useState(initialTransaction.type);
  const [category, setCategory] = useState(initialTransaction.category);
  const [date, setDate] = useState(initialTransaction.date);
  const [error, setError] = useState("");

  const isEditing = initialTransaction !== emptyTransaction;

  function handleSubmit(event) {
    event.preventDefault();

    const amountNumber = Number(amount);

    if (title.trim() === "") {
      setError("Please enter a title.");
      return;
    }

    if (!(amountNumber > 0)) {
      setError("Please enter an amount greater than 0.");
      return;
    }

    if (date === "") {
      setError("Please choose a date.");
      return;
    }

    onSubmit({
      title: title.trim(),
      amount: amountNumber,
      type: type,
      category: category,
      date: date,
    });
  }

  return (
    <form className="transaction-form" onSubmit={handleSubmit}>
      <h2>{isEditing ? "Edit transaction" : "New transaction"}</h2>

      <div className="form-field">
        <label htmlFor="title">Title</label>
        <input
          id="title"
          type="text"
          placeholder="e.g. Lunch"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
        />
      </div>

      <div className="form-field">
        <label htmlFor="amount">Amount</label>
        <input
          id="amount"
          type="number"
          min="0"
          step="0.01"
          placeholder="e.g. 12.50"
          value={amount}
          onChange={(event) => setAmount(event.target.value)}
        />
      </div>

      <div className="form-field">
        <label htmlFor="type">Type</label>
        <select id="type" value={type} onChange={(event) => setType(event.target.value)}>
          <option value="expense">Expense</option>
          <option value="income">Income</option>
        </select>
      </div>

      <div className="form-field">
        <label htmlFor="category">Category</label>
        <select id="category" value={category} onChange={(event) => setCategory(event.target.value)}>
          {categories.map((name) => (
            <option key={name} value={name}>
              {name}
            </option>
          ))}
        </select>
      </div>

      <div className="form-field">
        <label htmlFor="date">Date</label>
        <input id="date" type="date" value={date} onChange={(event) => setDate(event.target.value)} />
      </div>

      {error && <p className="form-error">{error}</p>}

      <div className="form-actions">
        <button type="button" className="button" onClick={onCancel}>
          Cancel
        </button>
        <button type="submit" className="button button-primary">
          {isEditing ? "Save changes" : "Add transaction"}
        </button>
      </div>
    </form>
  );
}

export default TransactionForm;
```

Here is what changed compared to Lesson 10:

- `emptyTransaction` describes a blank form. It lives outside the component, like `categories`.
- `initialTransaction = emptyTransaction` gives the new prop a default value, the technique from Lesson 5. When `App` passes a transaction, the form starts with its values. When `App` passes nothing (or `undefined`), the form starts blank.
- Each `useState` now takes its initial value from `initialTransaction`. Remember from Lesson 9 that `useState` only uses the initial value on the **first** render. That detail becomes important in Step 3.
- `String(initialTransaction.amount)` turns a stored number like `120` back into the text `"120"`, because input values are strings. For the blank form, `String("")` is still `""`.
- `isEditing` is `true` when a real transaction was passed in. It changes the heading and the submit button's text.
- The callback prop is renamed from `onAdd` to `onSubmit`, because the form no longer knows whether it is adding or editing. It just submits, and `App` decides what that means.
- The five reset calls at the end of `handleSubmit` are gone. `App` closes the form after every successful submit, and a closed form disappears completely, so there is nothing left to reset.

### Step 3: Track and Save the Edit in App

`App` needs to remember **which** transaction is being edited. Replace `src/App.jsx` with this version.

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

  const editingTransaction = transactions.find((transaction) => transaction.id === editingId);

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
      <Filters />
      <TransactionList transactions={transactions} onEdit={handleEdit} onDelete={handleDelete} />
    </main>
  );
}

export default App;
```

There is a lot here, so take it piece by piece:

- `const [editingId, setEditingId] = useState(null);` stores the id of the transaction being edited, or `null` when adding a new one. `null` means "no value on purpose".
- `const editingTransaction = transactions.find(...)` looks up the full transaction object from the id. `find` returns the first matching item, or `undefined` if there is none. Notice that `App` stores only the **id** in state and calculates the object on every render. If it stored a copy of the object instead, the copy could get out of date. Keeping one source of truth and deriving the rest is a pattern you will use again in Lesson 13.
- `closeForm` closes the panel and clears `editingId`. Saving and cancelling both need it, so it gets its own function.
- `handleAddClick` now opens the blank form, or closes the form if it is already open. Using `closeForm` here also clears `editingId`, so the next "+ Add transaction" click opens a blank form even if the user was editing.
- `handleEdit(id)` remembers which transaction to edit and opens the form.
- `handleSave` replaces `handleAdd`. When editing, it uses `map` to build a new array:
  - For every transaction that is **not** being edited, the arrow function returns it unchanged.
  - For the one being edited, it returns a **new object**: `{ ...transaction, ...transactionData }` first copies every property of the old transaction, including its `id`, and then copies the form's five properties over them. Later properties win, so the new title, amount, and so on replace the old ones, while the `id` is kept.
  - The result is a new array, the same length, in the same order, with one replaced object. When adding, `handleSave` does exactly what `handleAdd` did before.
- `initialTransaction={editingTransaction}` passes the transaction to the form. When adding, `editingTransaction` is `undefined`, so the form uses its default, `emptyTransaction`.
- `key={editingId ?? "new"}` is the subtle part. The **nullish coalescing operator** `??` returns the left side unless it is `null` or `undefined`, in which case it returns the right side. So the key is the transaction's id when editing, and `"new"` when adding. Why does the form need a key at all? Because `useState` only reads its initial value once. If the form is already open for "Coffee with friends" and the user clicks Edit on "Freelance design", React would reuse the same form, and its state would still say "Coffee with friends". Changing the `key` tells React that this is a **different** form: React throws away the old one and creates a new one, whose `useState` calls start fresh from the new `initialTransaction`. You will see what happens without it in the Fix the Errors section.

Save all files. Click "Edit" on "Groceries".

The panel shows the heading, the five fields already filled in, and the two buttons:

```text
Edit transaction
Title: Groceries
Amount: 120
Type: Expense
Category: Food
Date: 2026-10-03
[Cancel] [Save changes]
```

(The date field displays the date in your system's format.) Change the title to `Weekly groceries` and the amount to `135.75`, then click "Save changes". The panel closes.

What you see in the transactions section:

```text
Transactions

Showing 5 transactions

Coffee with friends
Food · 2026-10-09
-$12
Edit
Delete
Freelance design
Freelance · 2026-10-08
+$400
Edit
Delete
Bus pass
Transport · 2026-10-05
-$45
Edit
Delete
Weekly groceries
Food · 2026-10-03
-$135.75
Edit
Delete
Monthly salaryLarge
Salary · 2026-10-01
+$3,000
Edit
Delete
```

The transaction kept its place in the list and its id, and only the changed values are different.

---

## 4. Run and Test

Refresh the page and test every path through the form:

1. Click "Edit" on "Coffee with friends". The form says "Edit transaction" and shows the coffee's values. The toolbar button says "Close".
2. While the form is still open, click "Edit" on "Freelance design". The form switches to the freelance values. This is the `key` at work.
3. Click "Close" in the toolbar. The form closes. Click "+ Add transaction": the form is blank and says "New transaction".
4. Add a transaction, then edit it, then delete it. Each step updates the list immediately.
5. Edit any transaction, clear its title, and click "Save changes". The message "Please enter a title." appears, and nothing changes in the list. Validation works for editing too, because it is the same form.

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

## 5. Immutable Updates Cheat Sheet

React decides whether to re-render by checking whether the new state is a **different value** from the old one. For arrays and objects, "different" means a different array or object, not the same one with modified contents. That is why every update in Spendly creates a new array or object. This habit is called **immutability**: you treat existing state as if it cannot be changed, and you replace it instead.

Here are the patterns you have now used, plus their mutating equivalents to avoid:

| Goal | Immutable (do this) | Mutating (avoid) |
| --- | --- | --- |
| Add to the start | `[newItem, ...items]` | `items.unshift(newItem)` |
| Add to the end | `[...items, newItem]` | `items.push(newItem)` |
| Remove | `items.filter((item) => item.id !== id)` | `items.splice(index, 1)` |
| Update one item | `items.map((item) => item.id === id ? { ...item, ...changes } : item)` | `item.title = "New"` |
| Change an object's property | `{ ...object, title: "New" }` | `object.title = "New"` |

A few things to notice:

- `filter`, `map`, and the spread syntax always return something **new**. `push`, `unshift`, `splice`, `sort`, `reverse`, and direct property assignment change the existing array or object.
- The spread syntax only copies **one level** deep. `{ ...transaction }` creates a new object, but if a property held another object, both copies would share it. Spendly's transactions only contain strings and numbers, so one level is all you need.
- Immutable updates are not only about re-rendering. Because the old array is never changed, it can safely be kept, for example to implement an "Undo" button later.

**The `key` trick for resetting state.** In Step 3, changing a component's `key` made React create a fresh component with fresh state. You will see this technique in many React apps: whenever a component should "start over" for a different item, give it a key based on that item.

---

## 6. Fix the Errors in Your Code

These three bugs are easy to write and, in the case of the first two, easy to miss.

**Error 1: Mutating the array with splice.**

```jsx
// Wrong
function handleDelete(id) {
  const index = transactions.findIndex((transaction) => transaction.id === id);
  transactions.splice(index, 1);
  setTransactions(transactions);
}

// Correct
function handleDelete(id) {
  setTransactions(transactions.filter((transaction) => transaction.id !== id));
}
```

With the wrong version, clicking "Delete" appears to do nothing, and there is no error or linter warning.

What you see in the count line after clicking Delete on "Bus pass":

```text
Showing 5 transactions
```

`splice` removed the item from the existing array, but `setTransactions(transactions)` passes React the same array it already had. React sees no change and skips the re-render. It is the same problem as `push` in Lesson 9, and it has the same fix: build a new array.

**Error 2: Using === instead of !== in the filter.**

```jsx
// Wrong
setTransactions(transactions.filter((transaction) => transaction.id === id));

// Correct
setTransactions(transactions.filter((transaction) => transaction.id !== id));
```

The wrong version keeps only the transaction you wanted to delete, and deletes everything else.

What you see in the transactions section after clicking Delete on "Bus pass":

```text
Transactions

Showing 1 transaction

Bus pass
Transport · 2026-10-05
-$45
Edit
Delete
```

`filter` keeps the items for which the function returns `true`. Read the condition aloud as "keep the transactions whose id is not the deleted id" to check it. AI tools produce this bug surprisingly often when asked to "filter out" an item, so it is worth testing every delete button you did not write yourself.

**Error 3: Forgetting the key on the form.**

```jsx
// Wrong
<TransactionForm initialTransaction={editingTransaction} onSubmit={handleSave} onCancel={closeForm} />

// Correct
<TransactionForm
  key={editingId ?? "new"}
  initialTransaction={editingTransaction}
  onSubmit={handleSave}
  onCancel={closeForm}
/>
```

With the wrong version, editing one transaction works fine. The bug appears when you click "Edit" on a second transaction while the form is still open.

Values in the form after clicking Edit on "Coffee with friends", then Edit on "Freelance design":

```text
Title: Coffee with friends
Amount: 12
```

The form still shows the coffee. React kept the existing form, because it is the same component in the same place, and its `useState` calls ignored the new initial values. If the user now clicks "Save changes", the coffee's values are saved onto the freelance transaction. The `key` forces React to create a fresh form whenever the edited transaction changes.

---

## 7. Exercises

**Exercise 1:** Ask for confirmation before deleting. In `handleDelete`, find the transaction, then use the browser's `window.confirm` with a message such as `Delete "Groceries"?`. Only delete when the user clicks OK.

**Exercise 2:** Add a "Duplicate" button to every row, before "Edit". It should add a copy of the transaction to the top of the list, with a new id and " (copy)" added to the end of its title. Write the handler in `App` as `handleDuplicate(id)` and pass it down as `onDuplicate`.

**Exercise 3:** Highlight the row that is being edited. Pass `editingId` from `App` to `TransactionList`, give each `TransactionItem` an `isEditing` prop that is `true` only for the edited row, and add the class `editing` to that row's `<li>`. Style `.transaction-item.editing` with a light indigo background.

---

## 8. Solutions

**Solution for Exercise 1:**

```jsx
function handleDelete(id) {
  const transaction = transactions.find((item) => item.id === id);
  if (!window.confirm(`Delete "${transaction.title}"?`)) {
    return;
  }
  setTransactions(transactions.filter((item) => item.id !== id));
}
```

`find` gets the transaction so the message can include its title. `window.confirm` shows a dialog with OK and Cancel buttons and returns `true` for OK and `false` for Cancel. If the user cancels, the early `return` stops the function before anything is deleted. The callback parameters are named `item` here so they do not clash with the `transaction` variable. Clicking "Delete" on "Groceries" shows `Delete "Groceries"?`; Cancel leaves 5 transactions, and OK leaves 4.

**Solution for Exercise 2:**

Add the handler to `src/App.jsx`.

```jsx
function handleDuplicate(id) {
  const original = transactions.find((transaction) => transaction.id === id);
  const copy = { ...original, id: Date.now(), title: `${original.title} (copy)` };
  setTransactions([copy, ...transactions]);
}
```

Pass it down: add `onDuplicate={handleDuplicate}` to `<TransactionList />` in `App`, add `onDuplicate` to the props of `TransactionList` and forward it with `onDuplicate={onDuplicate}`, and add the button in `TransactionItem`, receiving `onDuplicate` in its props:

```jsx
<button type="button" className="button small-button" onClick={() => onDuplicate(id)}>
  Duplicate
</button>
```

`{ ...original, id: Date.now(), title: ... }` copies every property of the original and then overrides two of them, the same "later properties win" rule used in `handleSave`. Duplicating "Coffee with friends" puts this row at the top:

```text
Coffee with friends (copy) | Food · 2026-10-09 | -$12
```

**Solution for Exercise 3:**

In `src/App.jsx`, pass the id down.

```jsx
<TransactionList transactions={transactions} onEdit={handleEdit} onDelete={handleDelete} editingId={editingId} />
```

In `src/components/TransactionList.jsx`, receive `editingId` and calculate `isEditing` for each row.

```jsx
function TransactionList({ transactions, onEdit, onDelete, editingId }) {
```

```jsx
<TransactionItem
  key={transaction.id}
  transaction={transaction}
  onEdit={onEdit}
  onDelete={onDelete}
  isEditing={transaction.id === editingId}
/>
```

In `src/components/TransactionItem.jsx`, receive `isEditing` and build the class name.

```jsx
function TransactionItem({ transaction, onEdit, onDelete, isEditing }) {
```

```jsx
<li className={`transaction-item ${isEditing ? "editing" : ""}`}>
```

Finally, add the style to `src/App.css`.

```css
.transaction-item.editing {
  background-color: #eef2ff;
}
```

`isEditing` is a boolean prop calculated by the list, so each row only needs to know about itself. Clicking "Edit" on the third row gives the rows these class lists:

```text
transaction-item , transaction-item , transaction-item editing, transaction-item , transaction-item 
```

Only the edited row has the `editing` class, and it gets the indigo background until the form is closed.

---

## Next Up - Lesson 12

In this lesson you completed Spendly's core list operations. Delete buttons remove transactions with `filter`, Edit buttons open the form filled with existing values, and "Save changes" replaces the edited transaction with `map` and the object spread syntax. You made one form handle both adding and editing with an optional prop and a default value, and used the `key` prop to reset the form's state. Most importantly, you learned the immutable update patterns and saw why mutating state breaks React. That completes Module 3: Spendly is now a fully interactive app.

As Spendly grows, an important question keeps coming up: which component should own each piece of state? In Lesson 12, you will start Module 4 by making the search box and category filter work. You will discover that the `Filters` component cannot share its state with `TransactionList`, and you will solve it by **lifting state up** to their common parent.
