## 1. Before You Begin

In Lesson 8, Spendly started listening to the user: buttons respond to clicks, the search box reports what is typed, and every Delete button tells `App` which transaction it belongs to. But all of that ends in the console. The page itself never changes, because nothing in Spendly can remember a new value and show it.

This lesson introduces the most important idea in React: **state**. State is data that a component remembers between renders, and changing it tells React to render the component again with the new value. You will first see why an ordinary variable is not enough, then use the `useState` hook to make the "+ Add transaction" button open and close a panel. Finally, you will move Spendly's transactions into state and add a new transaction to the list with one click.

### What You'll Build

- An "+ Add transaction" button that opens a panel and turns into a "Close" button, then closes the panel when clicked again.
- Spendly's transactions stored in state inside `App`, instead of being read straight from the data file.
- A "Quick add: $5 coffee" button in the panel that adds a new transaction to the top of the list every time it is clicked.

### What You'll Learn

- ✅ Why changing a normal variable does not update the screen
- ✅ What state is and how `useState` works
- ✅ How to read state and update it with its setter function
- ✅ What a re-render is and when it happens
- ✅ How to add an item to an array in state without changing the original array
- ✅ The rules of hooks
- ✅ When to use an updater function such as `setTransactions((current) => ...)`

### What You'll Need

- The Spendly project from Lesson 8
- The development server running with `npm run dev`, and the browser console open

---

## 2. Why a Normal Variable Is Not Enough

Before learning state, it helps to see the problem it solves. In this section you will try to open a panel the way you might in plain JavaScript: by changing a variable.

### Step 1: Try to Toggle a Panel with a Variable

Replace `src/App.jsx` with this version. It removes `handleAddClick`'s console message and tries to use a variable named `isFormOpen` to show or hide a panel.

```jsx
import "./App.css";
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import { sampleTransactions } from "./data/transactions.js";

function App() {
  let isFormOpen = false;

  function handleAddClick() {
    isFormOpen = !isFormOpen;
    console.log("isFormOpen is now:", isFormOpen);
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
      {isFormOpen && (
        <section className="panel">
          <p>The form to add a transaction will appear here.</p>
        </section>
      )}
      <Filters />
      <TransactionList transactions={sampleTransactions} onDelete={handleDelete} />
    </main>
  );
}

export default App;
```

Here is the idea behind this code:

- `let isFormOpen = false;` starts with the panel closed.
- `handleAddClick` flips the variable with `!isFormOpen`, so `false` becomes `true` and `true` becomes `false`, and logs the new value.
- `{isFormOpen && (...)}` is the `&&` pattern from Lesson 6: show the panel only when `isFormOpen` is `true`.

Save the file and click the button twice.

Output in the console:

```text
isFormOpen is now: true
isFormOpen is now: false
```

The variable changes exactly as expected, but the panel never appears. Run the linter in a second terminal and it explains the problem before you even look at the browser:

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

src/App.jsx:12:5: warning react(immutability): Cannot reassign variable after render completes help: Reassigning `isFormOpen` after render has completed can cause inconsistent behavior on subsequent renders. Consider using state instead
src/App.jsx:12:5: warning react(immutability): Cannot modify local variables after render completes help: This argument is a function which may reassign or mutate `isFormOpen` after render, which can cause inconsistent behavior on subsequent renders. Consider using state instead
```

There are two reasons the panel does not appear:

1. **Changing a variable does not tell React anything.** React draws the screen by calling your component function and using the JSX it returns. It has no idea that `isFormOpen` changed afterward, so it never calls `App` again.
2. **Even if React did call `App` again, the variable would reset.** Every call to `App` runs `let isFormOpen = false;` from the top. Local variables do not survive between calls.

What Spendly needs is a value that React remembers between calls, and a way to change it that also tells React to draw the screen again. That is exactly what state provides, and the linter's last words, "Consider using state instead", point the way.

---

## 3. Add State with useState

`useState` is a **hook**: a special function provided by React whose name starts with `use`. Hooks let a component "hook into" React features. `useState` gives a component a piece of memory.

### Step 1: Toggle the Panel with State

Replace `src/App.jsx` with this version.

```jsx
import { useState } from "react";
import "./App.css";
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import { sampleTransactions } from "./data/transactions.js";

function App() {
  const [isFormOpen, setIsFormOpen] = useState(false);

  function handleAddClick() {
    setIsFormOpen(!isFormOpen);
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
          {isFormOpen ? "Close" : "+ Add transaction"}
        </button>
      </div>
      {isFormOpen && (
        <section className="panel">
          <p>The form to add a transaction will appear here.</p>
        </section>
      )}
      <Filters />
      <TransactionList transactions={sampleTransactions} onDelete={handleDelete} />
    </main>
  );
}

export default App;
```

Here is what this code does, line by line:

- `import { useState } from "react";` brings in the hook. It is a named export of the `react` package.
- `const [isFormOpen, setIsFormOpen] = useState(false);` creates a piece of state with the initial value `false`. `useState` returns an array with exactly two items, and the square brackets use **array destructuring** to name them:
  - `isFormOpen` is the **current value**.
  - `setIsFormOpen` is the **setter function** that changes the value.
  The names are up to you, but the convention is `something` and `setSomething`.
- `setIsFormOpen(!isFormOpen)` asks React to change the value to the opposite of the current one. React stores the new value and then **re-renders** `App`: it calls the `App` function again. This time, `useState` returns the new value instead of the initial `false`.
- `{isFormOpen ? "Close" : "+ Add transaction"}` changes the button's label to match the state.
- `{isFormOpen && (...)}` shows the panel when the state is `true`.

Then give the panel a style. Add this to the end of `src/App.css`.

```css
/* Panel */
.panel {
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 12px;
  padding: 16px;
}

.panel p {
  margin-bottom: 12px;
  color: var(--color-muted);
}
```

The panel gets the same white card look as the transaction list. Save both files, then click the button.

What you see in the browser after the first click:

```text
Close

The form to add a transaction will appear here.
```

The button now says "Close", and the panel appears under it as a white card. Click "Close": the panel disappears and the button says "+ Add transaction" again. Each click calls the setter, React re-renders `App`, and the JSX produces a different result from the new state.

This is the cycle at the heart of every React app:

```text
render: React calls App(), useState returns the current value, JSX is shown
   ↓
event: the user clicks, the handler calls setIsFormOpen(newValue)
   ↓
re-render: React calls App() again, useState returns the new value, the screen updates
```

---

## 4. Store the Transactions in State

The panel will hold the "add transaction" form in Lesson 10. To add a transaction, though, the list itself must be able to change. Right now `App` passes `sampleTransactions` directly from the data file, and that array never changes. In this section you will put the transactions in state, so that `App` owns a list it can update.

### Step 1: Move the Transactions into State and Add a Quick-Add Button

Replace `src/App.jsx` with this version.

```jsx
import { useState } from "react";
import "./App.css";
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import { sampleTransactions } from "./data/transactions.js";

function App() {
  const [transactions, setTransactions] = useState(sampleTransactions);
  const [isFormOpen, setIsFormOpen] = useState(false);

  function handleAddClick() {
    setIsFormOpen(!isFormOpen);
  }

  function handleQuickAdd() {
    const newTransaction = {
      id: Date.now(),
      title: "Coffee",
      amount: 5,
      type: "expense",
      category: "Food",
      date: "2026-10-26",
    };
    setTransactions([newTransaction, ...transactions]);
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
          {isFormOpen ? "Close" : "+ Add transaction"}
        </button>
      </div>
      {isFormOpen && (
        <section className="panel">
          <p>The form to add a transaction will appear here.</p>
          <button type="button" className="button" onClick={handleQuickAdd}>
            Quick add: $5 coffee
          </button>
        </section>
      )}
      <Filters />
      <TransactionList transactions={transactions} onDelete={handleDelete} />
    </main>
  );
}

export default App;
```

Here is what is new:

- `const [transactions, setTransactions] = useState(sampleTransactions);` creates state whose **initial value** is the sample array. React uses the initial value only on the first render. After that, `transactions` is whatever the latest `setTransactions` call stored.
- A component can have as many pieces of state as it needs. `App` now has two, and each one is independent.
- `handleQuickAdd` builds a new transaction object with the same six properties as every other transaction. `Date.now()` returns the number of milliseconds since 1970, which is a quick way to get a unique number for the `id`. You will use the same trick in the real form.
- `setTransactions([newTransaction, ...transactions])` is the important line. The **spread syntax** `...transactions` copies every item of the current array into a new array literal, and `newTransaction` is placed in front of them. The result is a **brand-new array** with one more item, which becomes the new state. The original array is left untouched.
- `<TransactionList transactions={transactions} ... />` now passes the state, not the imported sample data.

Save the file, click "+ Add transaction", and then click "Quick add: $5 coffee" twice.

What you see in the transactions section:

```text
Transactions

Showing 7 transactions

Coffee
Food · 2026-10-26
-$5
Delete
Coffee
Food · 2026-10-26
-$5
Delete
Coffee with friends
Food · 2026-10-09
-$12
Delete
Freelance design
Freelance · 2026-10-08
+$400
Delete
Bus pass
Transport · 2026-10-05
-$45
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

Two new coffees sit at the top, and the count updates to 7 automatically. You did not touch `TransactionList` at all: it simply receives a new array and renders it.

Notice two things that do **not** happen yet. First, the summary still says Expense `$177`, because `App` still passes fixed numbers to `Summary`; in Lesson 13 the totals will be calculated from the transactions in state. Second, refresh the page and the two coffees are gone. State lives in memory, and a page refresh starts the app from scratch with the initial value. Lesson 14 makes Spendly save its data in the browser.

---

## 5. Run and Test

Refresh the page to start from the sample data, then test the full flow:

1. The button says "+ Add transaction" and there is no panel.
2. Click the button. It changes to "Close" and the panel appears with the "Quick add: $5 coffee" button.
3. Click "Quick add: $5 coffee" three times. Three "Coffee" rows appear at the top of the list, and the count says "Showing 8 transactions".
4. Click "Close". The panel disappears, but the coffees stay in the list, because the two pieces of state are independent.
5. Click "Delete" on any row. The console still logs the id, and the row stays; you will implement deleting in Lesson 11.

Run the linter.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

```

The warnings from Section 2 are gone, because `App` no longer reassigns a variable after rendering.

---

## 6. How State Works

You now have a working mental model of state. Here are the rules and details that complete it.

**State is per component and private.** `isFormOpen` belongs to `App`. If you used the same component twice, each copy would have its own independent state, the way two counters on a page count separately. Other components cannot read or change it unless the owner passes it down as a prop.

**Setting state schedules a re-render; it does not change the variable immediately.** Inside the handler, after `setIsFormOpen(true)`, the variable `isFormOpen` still holds the old value. The new value only appears in the **next** render, when `useState` returns it. If you log the state right after setting it, you will see the old value. This surprises everyone at first, and it is important in the next point.

**Use an updater function when the new value depends on the old one and you set it more than once.** `setTransactions([newTransaction, ...transactions])` builds the new array from the `transactions` variable of the current render. If you call it three times in the same click, all three calls start from the same old array, and only the last one wins. Passing a function instead solves this:

```jsx
setTransactions((current) => [newTransaction, ...current]);
```

React calls the function with the most recent state, including updates that are still waiting, so several updates in a row stack correctly. You will see the difference in the Fix the Errors section. For a single update per event, both forms work, and this course uses the simpler one unless an updater is needed.

**Never change state directly.** State must be replaced, not edited. `transactions.push(...)` changes the existing array, and `isFormOpen = true` changes a local copy. React compares the old and new values to decide whether to re-render, and if you hand it the same array it has already seen, it assumes nothing changed. Always create a new value: spread arrays with `[...array]`, and in Lesson 11 you will do the same for objects.

**The rules of hooks.** Hooks rely on being called in the same order on every render, so React has two rules:

1. Call hooks only at the **top level** of a component, never inside conditions, loops, or nested functions such as event handlers.
2. Call hooks only from **React components** or from your own custom hooks, which you will write in Lesson 16.

The `.oxlintrc.json` file in your project enables the `react/rules-of-hooks` check, so the linter reports any violation as an error.

---

## 7. Fix the Errors in Your Code

These are the classic state mistakes. All three appear regularly in AI-generated React code.

**Error 1: Changing the state array with push.**

```jsx
// Wrong
function handleQuickAdd() {
  const newTransaction = {
    id: Date.now(),
    title: "Coffee",
    amount: 5,
    type: "expense",
    category: "Food",
    date: "2026-10-26",
  };
  transactions.push(newTransaction);
  setTransactions(transactions);
}

// Correct
function handleQuickAdd() {
  const newTransaction = {
    id: Date.now(),
    title: "Coffee",
    amount: 5,
    type: "expense",
    category: "Food",
    date: "2026-10-26",
  };
  setTransactions([newTransaction, ...transactions]);
}
```

With the wrong version, clicking "Quick add: $5 coffee" appears to do nothing. There is no error and no linter warning.

What you see in the count line after one click:

```text
Showing 5 transactions
```

`push` added the coffee to the existing array, so the data did change, but `setTransactions(transactions)` handed React the **same array** it already had. React compared the old and new values, found the same array, and skipped the re-render. The correct version creates a new array, which React recognizes as a change.

**Error 2: Calling useState inside an event handler.**

It can seem logical to create the state at the moment you need it.

```jsx
// Wrong
function App() {
  const [transactions, setTransactions] = useState(sampleTransactions);

  function handleAddClick() {
    const [isFormOpen, setIsFormOpen] = useState(false);
    setIsFormOpen(!isFormOpen);
  }

  // ...the rest of App still uses isFormOpen in its JSX
}

// Correct
function App() {
  const [transactions, setTransactions] = useState(sampleTransactions);
  const [isFormOpen, setIsFormOpen] = useState(false);

  function handleAddClick() {
    setIsFormOpen(!isFormOpen);
  }

  // ...
}
```

The wrong version crashes as soon as the page loads, because the JSX uses `isFormOpen`, which now only exists inside the handler. The console shows:

```text
ReferenceError: isFormOpen is not defined
```

More importantly, the linter reports the real problem as an error:

```text
src/App.jsx:13:41: error react-hooks(rules-of-hooks): React Hook "useState" is called in function "handleAddClick" that is neither a React function component nor a custom React Hook function. React component names must start with an uppercase letter. React Hook names must start with the word "use".
```

Hooks belong at the top level of the component, next to the other `useState` calls. Handlers only call the setter.

**Error 3: Setting state several times in a row from the same old value.**

Imagine an "Add 3 coffees" button that loops three times.

```jsx
// Wrong
function handleAddThree() {
  for (let i = 1; i <= 3; i++) {
    const newTransaction = {
      id: Date.now() + i,
      title: `Coffee ${i}`,
      amount: 5,
      type: "expense",
      category: "Food",
      date: "2026-10-26",
    };
    setTransactions([newTransaction, ...transactions]);
  }
}

// Correct
function handleAddThree() {
  for (let i = 1; i <= 3; i++) {
    const newTransaction = {
      id: Date.now() + i,
      title: `Coffee ${i}`,
      amount: 5,
      type: "expense",
      category: "Food",
      date: "2026-10-26",
    };
    setTransactions((current) => [newTransaction, ...current]);
  }
}
```

With the wrong version, one click adds only one coffee, "Coffee 3".

What you see at the top of the transactions section with the wrong version:

```text
Transactions

Showing 6 transactions

Coffee 3
Food · 2026-10-26
-$5
```

All three calls built their array from the same `transactions` value, the one from the current render, so each call replaced the previous one, and only the last survived. With the updater function, each call receives the result of the previous one, and the count goes from 5 to 8. This is called **stale state**: using a value that is out of date by the time the update is applied. You will meet it again in Module 7, because it is one of the most common bugs in AI-generated code.

---

## 8. Exercises

**Exercise 1:** Add a third piece of state to `App` named `quickAddCount`, starting at `0`. Increase it every time "Quick add: $5 coffee" is clicked, and show `You have quick-added 1 coffee.` or `You have quick-added 2 coffees.` inside the panel, only after the first click.

**Exercise 2:** Give `Summary` its own state: a "Hide amounts" button under the spending text. When clicked, the three amounts are replaced with `••••` and the button says "Show amounts". Clicking again shows the amounts. The state belongs in `Summary`, not in `App`.

**Exercise 3:** Add an "Add 3 coffees" button to the panel, next to the quick-add button, that adds three coffees named "Coffee 1", "Coffee 2", and "Coffee 3" with a single click. Make sure all three are added.

---

## 9. Solutions

**Solution for Exercise 1:**

Add the state next to the others in `src/App.jsx`.

```jsx
const [quickAddCount, setQuickAddCount] = useState(0);
```

Update the counter at the end of `handleQuickAdd`.

```jsx
function handleQuickAdd() {
  const newTransaction = {
    id: Date.now(),
    title: "Coffee",
    amount: 5,
    type: "expense",
    category: "Food",
    date: "2026-10-26",
  };
  setTransactions([newTransaction, ...transactions]);
  setQuickAddCount(quickAddCount + 1);
}
```

Show the message in the panel, after the quick-add button.

```jsx
{quickAddCount > 0 && <p>You have quick-added {quickAddCount} {quickAddCount === 1 ? "coffee" : "coffees"}.</p>}
```

One handler can update several pieces of state; React combines the updates into a single re-render. The condition `quickAddCount > 0` avoids the `0 &&` trap from Lesson 6.

What you see in the panel after two clicks:

```text
The form to add a transaction will appear here.

Quick add: $5 coffee

You have quick-added 2 coffees.
```

Remove this counter afterward; Lesson 10 replaces the panel's content with the real form.

**Solution for Exercise 2:**

Replace `src/components/Summary.jsx`.

```jsx
import { useState } from "react";
import { formatAmount } from "../utils/format.js";

function Summary({ income, expense }) {
  const [isHidden, setIsHidden] = useState(false);
  const balance = income - expense;
  const spentPercent = income > 0 ? Math.min(100, Math.round((expense / income) * 100)) : 0;

  function display(amount) {
    return isHidden ? "••••" : formatAmount(amount);
  }

  return (
    <section className="summary">
      <div className="summary-card">
        <span className="summary-label">Income</span>
        <span className="summary-value income">{display(income)}</span>
      </div>
      <div className="summary-card">
        <span className="summary-label">Expense</span>
        <span className="summary-value expense">{display(expense)}</span>
      </div>
      <div className="summary-card">
        <span className="summary-label">Balance</span>
        <span className={`summary-value ${balance >= 0 ? "income" : "expense"}`}>{display(balance)}</span>
      </div>
      <div className="spending">
        <div className="spending-bar">
          <div className="spending-bar-fill" style={{ width: `${spentPercent}%` }}></div>
        </div>
        <p className="spending-text">You have spent {spentPercent}% of your income.</p>
        <button type="button" className="button" onClick={() => setIsHidden(!isHidden)}>
          {isHidden ? "Show amounts" : "Hide amounts"}
        </button>
      </div>
    </section>
  );
}

export default Summary;
```

`isHidden` only affects how the summary looks, and no other component needs it, so it belongs inside `Summary`. A small helper function, `display`, decides what to show for each amount, which avoids repeating the same ternary three times. The inline arrow function `() => setIsHidden(!isHidden)` is short enough that a named handler is not needed.

Before clicking the button, the summary shows:

```text
Income
$3,400
Expense
$177
Balance
$3,223

You have spent 5% of your income.

Hide amounts
```

After clicking it, the summary shows:

```text
Income
••••
Expense
••••
Balance
••••

You have spent 5% of your income.

Show amounts
```

**Solution for Exercise 3:**

Add this handler to `src/App.jsx`.

```jsx
function handleAddThree() {
  for (let i = 1; i <= 3; i++) {
    const newTransaction = {
      id: Date.now() + i,
      title: `Coffee ${i}`,
      amount: 5,
      type: "expense",
      category: "Food",
      date: "2026-10-26",
    };
    setTransactions((current) => [newTransaction, ...current]);
  }
}
```

And add the button to the panel.

```jsx
<button type="button" className="button" onClick={handleAddThree}>
  Add 3 coffees
</button>
```

Two details matter. `Date.now() + i` keeps the three ids unique, because the loop runs within the same millisecond and `Date.now()` alone would almost always give all three the same id, which breaks the `key` rule from Lesson 6. And the updater function `(current) => [newTransaction, ...current]` makes each update start from the result of the previous one. One click takes the list from 5 to 8 transactions, with "Coffee 3" at the top, followed by "Coffee 2" and "Coffee 1". Remove the button when you are done.

---

## Next Up - Lesson 10

In this lesson you learned state, the memory of a React component. You saw why a normal variable cannot update the screen, used `useState` to open and close a panel, and moved Spendly's transactions into state so that a quick-add button can add new ones. You learned that setting state triggers a re-render, that state must be replaced with new values rather than changed in place, the rules of hooks, and when to use an updater function.

The quick-add button always adds the same coffee. In Lesson 10, you will replace it with a real form for new transactions: text, number, dropdown, and date inputs whose values are stored in state as the user types. You will validate the input, convert text to numbers, and add the user's own transaction to the list when the form is submitted.
