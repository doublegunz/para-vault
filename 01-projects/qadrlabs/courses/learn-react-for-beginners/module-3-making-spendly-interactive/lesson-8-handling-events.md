## 1. Before You Begin

Module 2 gave Spendly a clean component structure, data-driven rendering, and a real design. But try clicking anywhere or typing in the search box: nothing happens. A user interface is only half done until it responds to the user.

Module 3 makes Spendly interactive, and it starts with **events**. An event is something that happens on the page: a click, a key press, text typed into an input, a form being submitted. In this lesson you will learn how React components listen for events, how to read what the user typed, how to stop a form from reloading the page, and how a child component can tell its parent that something happened by calling a function the parent passed down as a prop. For now, every handler will report what happened in the browser console. In Lesson 9, the same handlers will start changing what is on the screen.

### What You'll Build

- An "+ Add transaction" button above the search box that reports each click in the console.
- A search box that logs every character the user types.
- A search form that no longer reloads the page when the user presses `Enter`.
- A "Delete" button on every transaction row. Clicking it tells `App` which transaction should be deleted.

### What You'll Learn

- ✅ How to attach an event handler with `onClick`, `onChange`, and `onSubmit`
- ✅ The difference between passing a function and calling it
- ✅ How to write event handlers as named functions and as inline arrow functions
- ✅ How to read the event object and `event.target.value`
- ✅ How to stop the browser's default form behavior with `event.preventDefault()`
- ✅ How to pass a function as a prop so a child can notify its parent
- ✅ How to pass an argument, such as an id, to a handler

### What You'll Need

- The Spendly project from Lesson 7
- The development server running with `npm run dev`
- The browser console open (`F12`, then the **Console** tab). You will read every result there in this lesson.

---

## 2. Respond to a Click

In plain JavaScript, you find an element and attach a listener: `button.addEventListener("click", handleClick)`. In React you never look elements up. Instead, you write the handler directly on the JSX element as an attribute, just like `className`. The attribute name is the event name in camelCase with `on` in front: `onClick`, `onChange`, `onSubmit`, `onKeyDown`, `onMouseEnter`, and so on.

### Step 1: Add a Button with a Named Handler

Open `src/App.jsx` and replace it with this version.

```jsx
import "./App.css";
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import { sampleTransactions } from "./data/transactions.js";

function App() {
  function handleAddClick() {
    console.log("Add transaction button clicked");
  }

  return (
    <main className="app">
      <Header userName="Dina" />
      <Summary income={3400} expense={177} />
      <div className="toolbar">
        <button type="button" className="button button-primary" onClick={handleAddClick}>
          + Add transaction
        </button>
      </div>
      <Filters />
      <TransactionList transactions={sampleTransactions} />
    </main>
  );
}

export default App;
```

Here is what this code does:

- `function handleAddClick() { ... }` is defined **inside** `App`. A function inside a component can use the component's props and variables, which you will need later. Naming handlers `handle` plus what happened (`handleAddClick`, `handleSubmit`) is a common convention that makes them easy to recognize.
- `onClick={handleAddClick}` tells React: "when this button is clicked, call `handleAddClick`". Notice there are **no parentheses** after `handleAddClick`. You are handing React the function itself, so React can call it later, at the moment of the click.
- `type="button"` tells the browser this button does not submit a form. It is a good habit for every button that is not a submit button.
- The `toolbar` div holds the button, so it can be positioned with CSS.

Add the button styles to the end of `src/App.css`.

```css
/* Buttons */
.toolbar {
  display: flex;
  justify-content: flex-end;
}

.button {
  padding: 8px 14px;
  font-size: 14px;
  font-weight: 600;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background-color: var(--color-surface);
  color: var(--color-text);
  cursor: pointer;
}

.button-primary {
  border-color: var(--color-primary);
  background-color: var(--color-primary);
  color: #ffffff;
}
```

`.button` is a base style for every button in Spendly, and `.button-primary` turns a button into the main, indigo call to action. `cursor: pointer` shows the hand cursor on hover, which tells users the element is clickable.

Save both files. An indigo "+ Add transaction" button appears on the right, between the summary and the search box. Click it twice.

Output in the console:

```text
Add transaction button clicked
Add transaction button clicked
```

The handler runs once per click. It does not add anything yet; in Lesson 9 this button will open a form.

---

## 3. Read What the User Types

Clicks are simple: something happened, and that is all you need to know. Other events carry information. When the user types in an input, you want to know **what** they typed. React passes every handler an **event object** as its first argument, and that object describes what happened.

### Step 1: Log the Search Text with onChange

Replace `src/components/Filters.jsx` with this code.

```jsx
function Filters() {
  function handleSearchChange(event) {
    console.log("Searching for:", event.target.value);
  }

  return (
    <section className="filters">
      <label htmlFor="search">Search transactions</label>
      <input id="search" type="text" placeholder="e.g. Groceries" onChange={handleSearchChange} />
    </section>
  );
}

export default Filters;
```

Here is what this code does:

- `onChange={handleSearchChange}` attaches the handler to the input. In React, `onChange` fires on **every keystroke**, not only when the input loses focus as the plain HTML `change` event does.
- `handleSearchChange(event)` receives the event object from React. You can name the parameter anything, but `event` (or the short `e`) is the convention.
- `event.target` is the element that triggered the event, here the `<input>`. `event.target.value` is the text currently in it.

Save the file, click the search box, and type `Gro`.

Output in the console:

```text
Searching for: G
Searching for: Gr
Searching for: Gro
```

Each keystroke triggers the handler, and each time `event.target.value` contains the full text so far, not just the newest character. In Lesson 13, this value will filter the transaction list as you type.

### Step 2: Stop the Form from Reloading the Page

Users expect to press `Enter` in a search box. To support that properly, the search box should be inside a `<form>`. But a form has a built-in behavior from the early days of the web: when it is submitted, the browser sends the data to a server and **reloads the page**. In a React app, that reload wipes out everything on the screen. Update `src/components/Filters.jsx`.

```jsx
function Filters() {
  function handleSearchChange(event) {
    console.log("Searching for:", event.target.value);
  }

  function handleSubmit(event) {
    event.preventDefault();
    console.log("Search submitted");
  }

  return (
    <form className="filters" onSubmit={handleSubmit}>
      <label htmlFor="search">Search transactions</label>
      <input id="search" type="text" placeholder="e.g. Groceries" onChange={handleSearchChange} />
    </form>
  );
}

export default Filters;
```

Here is what changed:

- The outer `<section>` is now a `<form>`. It keeps the `filters` class, so the styles from Lesson 7 still apply.
- `onSubmit={handleSubmit}` goes on the **form**, not on the input or a button. A form is submitted when the user presses `Enter` in a text field or clicks a submit button, and `onSubmit` catches both.
- `event.preventDefault()` cancels the browser's default action for this event, which is the page reload. It must be the first thing the handler does.

Save the file, type something in the search box, and press `Enter`.

Output in the console:

```text
Search submitted
```

The text you typed stays in the box, and the page does not reload. To see the problem `preventDefault` solves, temporarily delete the `event.preventDefault();` line, save, type something, and press `Enter`. The page flashes and reloads, the search box is empty again, and the address bar now ends with `?`. Put the line back before continuing. You will use exactly this pattern for Spendly's transaction form in Lesson 10.

---

## 4. Let a Child Notify Its Parent

Each transaction row needs a "Delete" button. The button lives in `TransactionItem`, but the list of transactions belongs to `App`, which got it from the data file. In Lesson 11, `App` will be the one to remove a transaction from the list. So the question is: how does a button deep inside `TransactionItem` tell `App` that it was clicked?

The answer uses something you already know. Props can be any value, including **functions**. `App` defines a function and passes it down as a prop. The child calls that function when its button is clicked. Data flows down as props, and events flow up through function calls.

### Step 1: Define the Handler in App

Update `src/App.jsx`.

```jsx
import "./App.css";
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import { sampleTransactions } from "./data/transactions.js";

function App() {
  function handleAddClick() {
    console.log("Add transaction button clicked");
  }

  function handleDelete(id) {
    console.log("Delete transaction with id:", id);
  }

  return (
    <main className="app">
      <Header userName="Dina" />
      <Summary income={3400} expense={177} />
      <div className="toolbar">
        <button type="button" className="button button-primary" onClick={handleAddClick}>
          + Add transaction
        </button>
      </div>
      <Filters />
      <TransactionList transactions={sampleTransactions} onDelete={handleDelete} />
    </main>
  );
}

export default App;
```

Here is what is new:

- `handleDelete(id)` takes the id of the transaction to delete. For now it only logs the id.
- `onDelete={handleDelete}` passes the function to `TransactionList` as a prop named `onDelete`. Props that hold event handlers are named `on` plus the event by convention, mirroring `onClick`. Inside the parent, the function itself is named `handle` plus the event.

### Step 2: Pass the Function Through the List

`TransactionList` does not delete anything itself. It only needs to hand the function to every row. Replace `src/components/TransactionList.jsx` with this code.

```jsx
import TransactionItem from "./TransactionItem.jsx";

function TransactionList({ transactions, onDelete }) {
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
          <TransactionItem key={transaction.id} transaction={transaction} onDelete={onDelete} />
        ))}
      </ul>
    </section>
  );
}

export default TransactionList;
```

The two changes are `{ transactions, onDelete }` in the parameter list and `onDelete={onDelete}` on each `TransactionItem`. Every row receives the same function.

### Step 3: Call the Function from the Delete Button

Replace `src/components/TransactionItem.jsx` with this code.

```jsx
import { formatAmount } from "../utils/format.js";

function TransactionItem({ transaction, onDelete }) {
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
        <button type="button" className="button delete-button" onClick={() => onDelete(id)}>
          Delete
        </button>
      </div>
    </li>
  );
}

export default TransactionItem;
```

Here is what this code does:

- The component destructures `onDelete` from its props, and `id` from the transaction, because it now needs the id.
- The amount and the new button are grouped in a `transaction-actions` div, so they sit together on the right side of the row.
- `onClick={() => onDelete(id)}` is the key line. The handler needs to call `onDelete` **with this row's id**. You cannot write `onClick={onDelete(id)}`, because that would call `onDelete` immediately while rendering. Instead, you wrap the call in an arrow function. React receives the arrow function and calls it on click, and the arrow function then calls `onDelete(id)`.

Finally, add styles for the new elements to the end of `src/App.css`.

```css
.transaction-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.delete-button {
  padding: 4px 10px;
  font-size: 12px;
  color: var(--color-expense);
}
```

`.transaction-actions` lines up the amount and the button with a small gap, and `.delete-button` makes the button smaller than the main button, with red text to signal a destructive action. It also uses the `.button` base class, so it gets the border and rounded corners.

Save all the files. Each row now has a small red "Delete" button. Click "Delete" on "Freelance design", then on "Groceries".

Output in the console:

```text
Delete transaction with id: 4
Delete transaction with id: 2
```

The click happened in `TransactionItem`, and the message was logged by `App`. Each row reported its own id, so `App` knows exactly which transaction the user meant. The rows do not disappear yet, because `App` cannot change the data. That is what state is for, in the next lesson.

---

## 5. Run and Test

With the development server running and the console open, test every interaction:

1. Click "+ Add transaction". The console shows `Add transaction button clicked`.
2. Type `Bus` in the search box. The console shows `Searching for: B`, `Searching for: Bu`, and `Searching for: Bus`.
3. Press `Enter` in the search box. The console shows `Search submitted`, the text stays in the box, and the page does not reload.
4. Click "Delete" on "Bus pass". The console shows `Delete transaction with id: 3`.

Then run the linter.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

```

---

## 6. How Events Flow in React

Here is a summary of the ideas from this lesson, for reference.

**Pass a function, do not call it.** `onClick={handleAddClick}` passes the function. `onClick={handleAddClick()}` calls it during rendering and passes its return value, which is `undefined`. When you need to pass an argument, wrap the call in an arrow function: `onClick={() => onDelete(id)}`.

**Named handler or inline arrow function?** Both are correct. A named function (`handleSubmit`) is better when the handler has more than one line, or when its name helps explain what it does. An inline arrow function is convenient for a one-line call that needs an argument, like `() => onDelete(id)`.

**The event object.** Every handler receives an event object. The properties you will use most are:

| Property or method | What it gives you | Example use |
| --- | --- | --- |
| `event.target` | The element that triggered the event | Find which input changed |
| `event.target.value` | The current value of an input, select, or textarea | Read typed text |
| `event.target.checked` | Whether a checkbox is ticked | Read a checkbox |
| `event.key` | The key that was pressed, in keyboard events | React to `Enter` or `Escape` |
| `event.preventDefault()` | Cancels the browser's default action | Stop a form submission from reloading the page |

**Data down, events up.** Props carry data from parents to children. Functions passed as props let children report events back to their parents. The parent decides what to do; the child only reports what happened. This is why `TransactionItem` calls its prop `onDelete` rather than doing the deleting itself: it does not own the list. Remember this pattern, because almost every interactive feature in Spendly uses it.

---

## 7. Fix the Errors in Your Code

Event handler mistakes are common in both hand-written and AI-generated React code.

**Error 1: Calling the handler instead of passing it.**

```jsx
// Wrong
<button type="button" className="button button-primary" onClick={handleAddClick()}>
  + Add transaction
</button>

// Correct
<button type="button" className="button button-primary" onClick={handleAddClick}>
  + Add transaction
</button>
```

With the wrong version, the console shows the message as soon as the page loads, before you click anything.

Output in the console when the page loads:

```text
Add transaction button clicked
Add transaction button clicked
```

Clicking the button afterward logs nothing new. The parentheses make JavaScript call `handleAddClick` while React is rendering the JSX, and the result of that call, `undefined`, becomes the `onClick` value. The message appears twice because, in development, `StrictMode` in `main.jsx` renders every component twice to help you catch mistakes like this one. Remove the parentheses so React receives the function itself.

**Error 2: Writing the event attribute in lowercase.**

HTML uses `onclick`, but React expects camelCase.

```jsx
// Wrong
<button type="button" className="button button-primary" onclick={handleAddClick}>
  + Add transaction
</button>

// Correct
<button type="button" className="button button-primary" onClick={handleAddClick}>
  + Add transaction
</button>
```

With the wrong version, clicking the button does nothing, and the console shows this error when the page loads:

```text
Invalid event handler property `onclick`. Did you mean `onClick`?
```

React ignores attributes it does not recognize as events. The same applies to `onchange`, `onsubmit`, and the others: always capitalize the first letter of the event name.

**Error 3: Forgetting to pass the function down.**

Every component between the parent and the child has to forward the function. If `TransactionList` receives `onDelete` but does not pass it to `TransactionItem`, the row has no function to call.

```jsx
// Wrong
{transactions.map((transaction) => (
  <TransactionItem key={transaction.id} transaction={transaction} />
))}

// Correct
{transactions.map((transaction) => (
  <TransactionItem key={transaction.id} transaction={transaction} onDelete={onDelete} />
))}
```

With the wrong version, the page looks fine until you click "Delete". Then the console shows:

```text
TypeError: onDelete is not a function
```

Inside `TransactionItem`, the `onDelete` prop was never passed, so it is `undefined`, and calling `undefined` as a function fails. The linter gives a hint before you even click. `npm run lint` prints:

```text
src/components/TransactionList.jsx:3:42: warning eslint(no-unused-vars): Parameter 'onDelete' is declared but never used. Unused parameters should start with a '_'. help: Consider removing this parameter.
```

`TransactionList` receives `onDelete` but never uses it, which is a strong clue that it was meant to be passed on. In Lesson 19 you will learn a way to avoid passing functions through many levels like this.

---

## 8. Exercises

**Exercise 1:** Add an "Edit" button to every transaction row, before the "Delete" button. It should use the plain `button` class. When clicked, it should call a new `onEdit` prop with the transaction's id, and `App` should log `Edit transaction with id: 3` (with the right id). Pass the function down the same way as `onDelete`.

**Exercise 2:** Add a category dropdown to `Filters`, under the search box, with a label and these options: All, Food, Transport, Salary, and Freelance. When the user picks an option, log `Category selected: Food` (with the chosen value).

**Exercise 3:** Change the delete flow so that `TransactionItem` passes the **whole transaction object** to `onDelete` instead of only the id, and make `App` log a friendlier message such as `Delete "Groceries" ($120)`. Use `formatAmount` for the amount.

---

## 9. Solutions

**Solution for Exercise 1:**

In `src/App.jsx`, add the handler after `handleDelete` and pass it to the list.

```jsx
function handleEdit(id) {
  console.log("Edit transaction with id:", id);
}
```

```jsx
<TransactionList transactions={sampleTransactions} onDelete={handleDelete} onEdit={handleEdit} />
```

In `src/components/TransactionList.jsx`, receive and forward the new prop.

```jsx
function TransactionList({ transactions, onDelete, onEdit }) {
```

```jsx
<TransactionItem key={transaction.id} transaction={transaction} onDelete={onDelete} onEdit={onEdit} />
```

In `src/components/TransactionItem.jsx`, receive the prop and add the button.

```jsx
import { formatAmount } from "../utils/format.js";

function TransactionItem({ transaction, onDelete, onEdit }) {
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
        <button type="button" className="button" onClick={() => onEdit(id)}>
          Edit
        </button>
        <button type="button" className="button delete-button" onClick={() => onDelete(id)}>
          Delete
        </button>
      </div>
    </li>
  );
}

export default TransactionItem;
```

The Edit button follows exactly the same pattern as Delete: an arrow function that calls a prop with the row's id. Clicking "Edit" on "Bus pass" logs:

```text
Edit transaction with id: 3
```

You will build the real edit feature in Lesson 11. You can keep or remove this button for now; Lesson 11 adds it again with its own handler.

**Solution for Exercise 2:**

```jsx
function Filters() {
  function handleSearchChange(event) {
    console.log("Searching for:", event.target.value);
  }

  function handleCategoryChange(event) {
    console.log("Category selected:", event.target.value);
  }

  function handleSubmit(event) {
    event.preventDefault();
    console.log("Search submitted");
  }

  return (
    <form className="filters" onSubmit={handleSubmit}>
      <label htmlFor="search">Search transactions</label>
      <input id="search" type="text" placeholder="e.g. Groceries" onChange={handleSearchChange} />
      <label htmlFor="category">Category</label>
      <select id="category" onChange={handleCategoryChange}>
        <option value="All">All</option>
        <option value="Food">Food</option>
        <option value="Transport">Transport</option>
        <option value="Salary">Salary</option>
        <option value="Freelance">Freelance</option>
      </select>
    </form>
  );
}

export default Filters;
```

A `<select>` element fires `onChange` when the user picks a different option, and `event.target.value` is the `value` attribute of the chosen `<option>`. The `htmlFor` and `id` pair connects the new label to the dropdown. Choosing "Food" logs:

```text
Category selected: Food
```

Lesson 13 turns this dropdown into a real category filter.

**Solution for Exercise 3:**

In `src/components/TransactionItem.jsx`, pass the whole object.

```jsx
<button type="button" className="button delete-button" onClick={() => onDelete(transaction)}>
  Delete
</button>
```

Since the component no longer uses `id` directly, also remove `id` from the destructuring line: `const { title, amount, type, category, date } = transaction;`. Otherwise the linter warns that `id` is unused.

In `src/App.jsx`, import `formatAmount` and update the handler.

```jsx
import { formatAmount } from "./utils/format.js";
```

```jsx
function handleDelete(transaction) {
  console.log(`Delete "${transaction.title}" (${formatAmount(transaction.amount)})`);
}
```

The handler now receives an object, so it can read any property. Clicking "Delete" on "Groceries" logs:

```text
Delete "Groceries" ($120)
```

Passing the id or passing the whole object are both common. Spendly uses the id, because removing an item from a list only requires knowing which one it is. Undo this change so `onDelete` receives the id again.

---

## Next Up - Lesson 9

In this lesson you made Spendly respond to the user. You handled clicks with `onClick`, read typed text with `onChange` and `event.target.value`, stopped a form from reloading the page with `event.preventDefault()`, and passed functions down as props so that a Delete button inside `TransactionItem` can tell `App` which transaction it belongs to.

Every handler so far only writes to the console, because nothing on the screen can change yet. In Lesson 9, you will learn **state** with the `useState` hook: data that a component remembers and that makes React re-render the screen when it changes. You will use it to open and close a panel with the "+ Add transaction" button, and to add a new transaction to the list with a single click.
