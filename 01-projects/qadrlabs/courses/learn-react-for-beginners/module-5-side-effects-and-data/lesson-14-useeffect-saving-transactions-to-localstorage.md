## 1. Before You Begin

Module 4 turned Spendly into a well-organized app: state lives in the right places, and totals, filters, and sorting are all derived from that state. But Spendly still has a problem every user would notice in their first minute. Add a few transactions, refresh the page, and they are gone. State lives in the browser's memory, and a refresh starts the app from scratch.

Module 5 is about the world outside React: the browser's storage, the page title, and data from the internet. This lesson introduces **side effects** and the `useEffect` hook, React's tool for keeping your component in sync with something outside it. You will use an effect to show the current balance in the browser tab, and another to save Spendly's transactions in `localStorage`, the browser's built-in storage. You will also load the saved transactions when the app starts, so your data finally survives a refresh.

### What You'll Build

- A browser tab title that shows the current balance, such as `Spendly ($3,223)`, and updates when the balance changes.
- Automatic saving: every time the transactions change, Spendly writes them to `localStorage`.
- Automatic loading: when Spendly starts, it reads the saved transactions, and falls back to the sample data on the very first visit.

### What You'll Learn

- ✅ What a side effect is and why it does not belong in the render
- ✅ How to run code after rendering with `useEffect`
- ✅ How the dependency array controls when an effect runs
- ✅ How to store and read data with `localStorage`
- ✅ How to save objects as text with `JSON.stringify` and read them back with `JSON.parse`
- ✅ How to load initial state lazily by passing a function to `useState`
- ✅ Why effects run twice in development, and how to avoid infinite loops

### What You'll Need

- The Spendly project from Lesson 13
- The development server running with `npm run dev`, and the browser console open
- If you completed the Lesson 13 exercises, you can keep them; the code in this lesson only adds new lines to `App`.

---

## 2. Run Code After Rendering with useEffect

A React component has one main job: take props and state, and return JSX. That calculation should be **pure**: given the same inputs, it returns the same output and changes nothing else. Anything that reaches outside the component, such as changing the page title, writing to storage, talking to a server, or starting a timer, is called a **side effect**.

Side effects should not run in the middle of rendering. React may render a component many times, sometimes without even showing the result. Instead, React gives you `useEffect`: a hook that says "after you have updated the screen, run this code". The first effect you will write keeps the browser tab's title in sync with the balance.

### Step 1: Show the Balance in the Tab Title

Open `src/App.jsx` and change the React import at the top so it also brings in `useEffect`. Then import `formatAmount`, which `App` has not needed until now.

```jsx
import { useEffect, useState } from "react";
```

```jsx
import { formatAmount } from "./utils/format.js";
```

Then add this effect inside `App`, right after the line that defines `isFiltering`:

```jsx
useEffect(() => {
  console.log("Updating the page title");
  document.title = `Spendly (${formatAmount(totals.balance)})`;
}, [totals.balance]);
```

Here is what this code does:

- `useEffect` takes two arguments. The first is a function, the **effect**, which React runs after the component has rendered and the screen has been updated.
- Inside the effect, `document.title = ...` sets the text in the browser tab. `document.title` is part of the browser, outside React's control, which is exactly what effects are for.
- The second argument, `[totals.balance]`, is the **dependency array**. It lists the values the effect uses. After every render, React compares them with their values from the previous render, and only runs the effect again if one of them changed.
- The `console.log` line is temporary, so you can see when the effect runs.

Like `useState`, `useEffect` must be called at the top level of the component, never inside a condition or a handler.

Save the file. The tab title changes from "Spendly" to `Spendly ($3,223)`. Now type `bus` in the search box, then delete "Bus pass".

Output in the console:

```text
Updating the page title
Updating the page title
--- typing in the search box
--- deleting a transaction
Updating the page title
```

The two lines starting with `---` are labels added to mark what happened when; your console will not show them. Here is how to read the result:

- The effect ran **twice** when the page loaded. In development, `StrictMode` (from `main.jsx`) deliberately runs every effect, cleans it up, and runs it again, to help you find effects that do not handle being repeated. This does not happen in a production build.
- Typing `bus` re-rendered `App` three times, but the effect did **not** run, because `totals.balance` did not change. Searching does not change the balance.
- Deleting the bus pass changed the balance, so the effect ran once and the title became `Spendly ($3,268)`.

Remove the `console.log` line from the effect before continuing. The effect is now:

```jsx
useEffect(() => {
  document.title = `Spendly (${formatAmount(totals.balance)})`;
}, [totals.balance]);
```

---

## 3. Save the Transactions in localStorage

Every browser has a small storage area for each website called `localStorage`. It keeps data even when the page is refreshed or the browser is closed. It is the simplest way to make Spendly's data last, and it needs no server or database.

### Step 1: Try localStorage in the Console

Before using it in Spendly, try it directly. With Spendly open, paste this code into the browser console and press `Enter`.

```javascript
localStorage.setItem("greeting", "Hello");
console.log(localStorage.getItem("greeting"));

localStorage.setItem("lunch", { title: "Lunch", amount: 12.5 });
console.log(localStorage.getItem("lunch"));

console.log(JSON.stringify({ title: "Lunch", amount: 12.5 }));

localStorage.setItem("lunch", JSON.stringify({ title: "Lunch", amount: 12.5 }));
const lunch = JSON.parse(localStorage.getItem("lunch"));
console.log(lunch.amount + 1);

console.log(localStorage.getItem("missing"));
```

Output in the console:

```text
Hello
[object Object]
{"title":"Lunch","amount":12.5}
13.5
null
```

Here is what each part shows:

- `localStorage.setItem(key, value)` saves a value under a name, and `localStorage.getItem(key)` reads it back. Saving `"Hello"` and reading it returns `"Hello"`.
- `localStorage` can only store **text**. When you give it an object, it converts it to text in the most useless way possible: `"[object Object]"`. The data is lost.
- `JSON.stringify(...)` converts an object or array into text in **JSON** format, which keeps all of its data. JSON (JavaScript Object Notation) looks almost exactly like a JavaScript object literal, with every property name in double quotes.
- `JSON.parse(...)` turns that text back into a real object. `lunch.amount + 1` gives `13.5`, which proves the amount came back as a number.
- `getItem` returns `null` when nothing has been saved under that key.

These five lines contain everything Spendly needs: save with `setItem` and `JSON.stringify`, load with `getItem` and `JSON.parse`, and check for `null` on the first visit. To clean up, run `localStorage.clear()` in the console, which removes everything this site has stored.

### Step 2: Save on Every Change

Saving the transactions is a side effect: it writes to something outside React whenever the transactions change. That is exactly the pattern from Section 2. Add a constant for the storage key above the `App` function in `src/App.jsx`, and an effect inside `App`, right before the title effect.

```jsx
const STORAGE_KEY = "spendly-transactions";
```

```jsx
useEffect(() => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
}, [transactions]);
```

Here is what this code does:

- `STORAGE_KEY` holds the name under which Spendly stores its data. Using a constant avoids typos when the same key is needed in two places. The name is prefixed with `spendly-` because all apps running on the same address (such as `localhost:5173`) share one `localStorage`.
- The effect converts the whole array to JSON text and saves it.
- `[transactions]` makes the effect run after the first render and then whenever `transactions` is a different array. Thanks to immutable updates, every add, edit, and delete creates a new array, so every change is saved. Typing in the search box or opening the form does not touch `transactions`, so nothing is saved needlessly.

Save the file. Spendly now writes its data, but it still ignores it when starting. Add a transaction and refresh: it disappears, and the sample data is saved over it again. The next step fixes that.

### Step 3: Load the Saved Transactions on Start

The initial value of the `transactions` state should come from `localStorage` when there is something saved there. Add a helper function above `App`, below `STORAGE_KEY`, and pass it to `useState`. Here is the full `src/App.jsx` for this lesson.

```jsx
import { useEffect, useState } from "react";
import "./App.css";
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import TransactionForm from "./components/TransactionForm.jsx";
import { sampleTransactions } from "./data/transactions.js";
import { getTotals } from "./utils/transactions.js";
import { formatAmount } from "./utils/format.js";

const STORAGE_KEY = "spendly-transactions";

function loadTransactions() {
  const saved = localStorage.getItem(STORAGE_KEY);
  return saved ? JSON.parse(saved) : sampleTransactions;
}

function App() {
  const [transactions, setTransactions] = useState(loadTransactions);
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

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
  }, [transactions]);

  useEffect(() => {
    document.title = `Spendly (${formatAmount(totals.balance)})`;
  }, [totals.balance]);

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

- `loadTransactions()` reads the saved text. If there is some, it parses it back into an array. If `getItem` returned `null`, which is the case on the very first visit, the ternary returns the sample data instead.
- `useState(loadTransactions)` passes the **function itself**, without parentheses, to `useState`. When `useState` receives a function, it calls it once to get the initial value, on the first render only. This is called **lazy initialization**. If you wrote `useState(loadTransactions())` with parentheses, the function would run on every render, reading and parsing storage each time, even though React ignores the result after the first render.
- `loadTransactions` lives outside `App`, like `STORAGE_KEY`, because it does not use any props or state.

Save the file and test the full cycle. Add a lunch for `12.50`, dated October 20, 2026, and delete "Monthly salary". The tab title reads `Spendly ($210.50)`. Now refresh the page.

What you see after the refresh:

```text
Tab title: Spendly ($210.50)
Showing 5 transactions
Lunch | Coffee with friends | Freelance design | Bus pass | Groceries
```

The lunch is still there and the salary is still gone. The summary also shows the saved data:

```text
Income
$400
Expense
$189.50
Balance
$210.50

You have spent 47% of your income.
```

Spendly finally remembers.

---

## 4. Run and Test

Test persistence from a few angles:

1. Edit a transaction, refresh, and confirm the change is still there.
2. Close the browser tab completely, open `http://localhost:5173` again, and check that your data is still there.
3. Open the developer tools, go to the **Application** tab (in Firefox: **Storage**), expand **Local Storage**, and click `http://localhost:5173`. You will see the `spendly-transactions` key, and its value is your transactions as JSON text. Add a transaction and watch the value update.
4. To start over with the sample data, right-click the key in the Application tab and delete it (or run `localStorage.removeItem("spendly-transactions")` in the console), then refresh. `loadTransactions` finds nothing and falls back to the sample data.

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

## 5. Understanding Effects

Effects are powerful and easy to misuse, so here are the key ideas in one place.

**The dependency array decides when an effect runs.**

| How you call it | When the effect runs |
| --- | --- |
| `useEffect(fn)` with no array | After **every** render |
| `useEffect(fn, [])` with an empty array | Once, after the first render |
| `useEffect(fn, [a, b])` | After the first render, and again whenever `a` or `b` changed |

List every prop, state value, or derived value from the component that the effect **uses**. The linter's `exhaustive-deps` check warns you when one is missing.

**Effects are for synchronizing with things outside React.** The page title, `localStorage`, network requests, timers, and browser APIs are all good reasons for an effect. Calculating values from state is not: use derived data, as in Lesson 13. Responding to a click is not either: put that code in the event handler. A useful question is "does this code need to run because the component is **displayed**, or because the user **did** something?" If the user did something, use a handler.

**Development runs effects twice.** `StrictMode` mounts every component, unmounts it, and mounts it again, so each effect runs, is cleaned up, and runs again. Saving to storage twice or setting a title twice is harmless, which is a good sign your effect is written correctly. In Lesson 15 you will meet effects that need a **cleanup function** to undo their work, and the double run will help you test it.

**Effects run after the screen updates.** The user sees the new render first, and then the effect runs. This keeps slow work, like saving, from delaying what the user sees.

**About localStorage.** It is perfect for a personal app like Spendly, but it has limits. It stores only text, typically up to about 5 MB per site. It lives in **one** browser on **one** device, so data does not sync to your phone. Anyone with access to the browser can read it, so it is not a place for passwords or secrets. Real multi-device apps save data to a server, which is beyond this course.

---

## 6. Fix the Errors in Your Code

Effects produce some of the most confusing bugs in React. All three of these are common in AI-generated code.

**Error 1: Forgetting the dependency array.**

```jsx
// Wrong
useEffect(() => {
  console.log("Saving transactions");
  localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
});

// Correct
useEffect(() => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
}, [transactions]);
```

The wrong version still saves correctly, so it looks fine. The log line reveals the problem when you type `bus` in the search box.

Output in the console:

```text
Saving transactions
Saving transactions
--- typing 'bus' in the search box
Saving transactions
Saving transactions
Saving transactions
```

Without a dependency array, the effect runs after **every** render, and every keystroke in the search box re-renders `App`. Spendly writes the whole list to storage three times without anything changing. With a large list or a slow operation such as a network request, this waste becomes a real problem. Always state the dependencies.

**Error 2: Saving the array without JSON.stringify.**

```jsx
// Wrong
localStorage.setItem(STORAGE_KEY, transactions);

// Correct
localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
```

The wrong version seems to work until the page is refreshed. Then the whole app goes blank, and the console shows:

```text
SyntaxError: Unexpected token 'o', "[object Obj"... is not valid JSON
```

`localStorage` converted the array to the text `[object Object],[object Object],...`, and on the next start, `JSON.parse` could not read it. After fixing the code, you also need to remove the broken saved value, because it is still in storage: run `localStorage.removeItem("spendly-transactions")` in the console and refresh. Bad data in storage can keep breaking an app long after the code is fixed, which is why some apps wrap `JSON.parse` in a `try...catch` block and fall back to default data.

**Error 3: Setting state in an effect with no dependency array.**

Suppose you load the saved transactions in an effect instead of with lazy initialization.

```jsx
// Wrong
useEffect(() => {
  setTransactions(loadTransactions());
});

// Correct
const [transactions, setTransactions] = useState(loadTransactions);
```

When there is saved data, the wrong version starts an endless loop. The console fills with this error, repeated over and over:

```text
Maximum update depth exceeded. This can happen when a component calls setState inside useEffect, but useEffect either doesn't have a dependency array, or one of the dependencies changes on every render.
```

Here is the loop: the effect sets state, setting state causes a render, and the render runs the effect again, because it has no dependency array. `JSON.parse` creates a brand-new array every time, so React always sees a change and never stops. In one test, `App` rendered more than 12,000 times within a few seconds of loading. The linter warns about this pattern before you ever run it:

```text
src/App.jsx:37:5: warning react(set-state-in-effect): Calling setState synchronously within an effect can trigger cascading renders help: Effects should synchronize React with external systems. Calling setState synchronously inside an effect starts another render and is usually unnecessary. Derive the value during render, initialize state directly, or update it from the event that caused the change. Use an effect only when synchronizing with an external system.
src/App.jsx:36:3: warning react-hooks(exhaustive-deps): React Hook useEffect contains a call to setState. Without a list of dependencies, this can lead to an infinite chain of updates. help: Consider adding an empty list of dependencies to make it clear which values are intended to be stable.
```

The first warning points to the better design: "initialize state directly". Reading the initial value from storage is what lazy initialization with `useState(loadTransactions)` is for, and it needs no effect at all.

---

## 7. Exercises

**Exercise 1:** Add a "Reset to sample data" button to the toolbar, to the left of "+ Add transaction". When clicked, it should ask for confirmation with `window.confirm("Replace all transactions with the sample data?")` and, if confirmed, replace the transactions with the sample data. Check that the reset is saved: refresh after resetting. Add `gap: 8px;` to the `.toolbar` rule so the buttons do not touch.

**Exercise 2:** Remember the selected category between visits. Load the initial category from `localStorage` under the key `spendly-category` (falling back to `"All"`), and save it with its own effect whenever it changes.

**Exercise 3:** Add an effect that logs `Spendly has 5 transactions` (with the current count) whenever the **number** of transactions changes, but not when a transaction is edited or when the user searches. Think carefully about the dependency array.

---

## 8. Solutions

**Solution for Exercise 1:**

Add the handler to `src/App.jsx`.

```jsx
function handleReset() {
  if (window.confirm("Replace all transactions with the sample data?")) {
    setTransactions(sampleTransactions);
  }
}
```

Add the button inside the toolbar, before the existing button.

```jsx
<div className="toolbar">
  <button type="button" className="button" onClick={handleReset}>
    Reset to sample data
  </button>
  <button type="button" className="button button-primary" onClick={handleAddClick}>
    {isFormOpen ? "Close" : "+ Add transaction"}
  </button>
</div>
```

And update the rule in `src/App.css`.

```css
.toolbar {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
```

The handler only changes state. It does not touch `localStorage` itself, because the saving effect already reacts to every change of `transactions`. After deleting two transactions and refreshing, the list shows 3 transactions; after clicking "Reset to sample data" and confirming, it shows 5, and a refresh keeps the 5. This is the advantage of an effect that keeps storage in sync: every way of changing the data is saved automatically.

**Solution for Exercise 2:**

Change the category state in `src/App.jsx` to load lazily, and add an effect next to the others.

```jsx
const [category, setCategory] = useState(() => localStorage.getItem("spendly-category") ?? "All");
```

```jsx
useEffect(() => {
  localStorage.setItem("spendly-category", category);
}, [category]);
```

This time the lazy initializer is an inline arrow function, which is handy when the loading code is a single expression. The category is already a string, so it needs no JSON. `??` falls back to `"All"` when `getItem` returns `null`. Choosing "Food" and refreshing keeps "Food" selected, and the list still shows only the food transactions.

**Solution for Exercise 3:**

```jsx
useEffect(() => {
  console.log(`Spendly has ${transactions.length} transactions`);
}, [transactions.length]);
```

The dependency is `transactions.length`, not `transactions`. Editing a transaction creates a new array with the same length, so the effect does not run, and searching does not touch `transactions` at all. Loading the page, typing in the search box, and then deleting two transactions logs:

```text
Spendly has 5 transactions
Spendly has 5 transactions
Spendly has 4 transactions
Spendly has 3 transactions
```

The first two lines are the development double run on mount. Then each deletion changes the length, and the effect runs once per change. A dependency can be any value, including a property of an object or a calculated number. Choosing exactly the values the effect cares about keeps it from running when it does not need to.

---

## Next Up - Lesson 15

In this lesson you learned that side effects reach outside React, and that `useEffect` runs them after rendering. You kept the tab title in sync with the balance, saved the transactions to `localStorage` whenever they change, and loaded them back on start with a lazy initializer. You also learned how the dependency array works, why effects run twice in development, and how a missing dependency array can turn an effect into an infinite loop.

In Lesson 15, Spendly will reach even further outside: across the network. You will fetch the list of categories from a JSON file and live currency exchange rates from a free public API with `fetch` and `async`/`await`. You will show a loading message while the data arrives, an error message if something goes wrong, and you will write your first effect cleanup.
