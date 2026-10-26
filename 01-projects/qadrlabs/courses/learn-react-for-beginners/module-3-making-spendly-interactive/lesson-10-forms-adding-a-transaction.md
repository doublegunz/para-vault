## 1. Before You Begin

In Lesson 9, you learned state and used it to open and close a panel and to add a $5 coffee with one click. The quick-add button proved that Spendly's list can change, but it always adds the same transaction. Real users need to type their own: "Lunch, $12.50, Food, October 20".

In this lesson you will build Spendly's first real form, `TransactionForm`. Each input will be a **controlled input**: its value lives in React state and is updated on every keystroke. When the form is submitted, the component will validate the input, convert the amount from text to a number, and send a new transaction up to `App`, which adds it to the list. Along the way you will improve `formatAmount` so that amounts with cents display properly.

### What You'll Build

- A `TransactionForm` component with five fields: title, amount, type (expense or income), category, and date.
- Inputs whose values are stored in state, with a live preview to prove it.
- A submit handler that sends the new transaction to `App`, which gives it an id, adds it to the top of the list, and closes the panel.
- A Cancel button, and a form that resets after a successful submit.
- Validation messages such as "Please enter a title." when the input is incomplete.
- Amounts with cents displayed as `$12.50` instead of `$12.5`.

### What You'll Learn

- ✅ What a controlled input is and why React uses them
- ✅ How to connect `value` and `onChange` for text, number, select, and date inputs
- ✅ How to render `<option>` elements from an array
- ✅ How to handle a form submission and send data to a parent with a callback prop
- ✅ Why every input value is a string, and how to convert it with `Number`
- ✅ How to validate input and show an error message with state
- ✅ How to reset a form after submitting

### What You'll Need

- The Spendly project from Lesson 9
- The development server running with `npm run dev`
- If you completed the Lesson 9 exercises, remove the quick-add counter, the "Hide amounts" button, and the "Add 3 coffees" button, so your project matches the starting point of this lesson

---

## 2. Build Controlled Inputs

In plain HTML, an input keeps its own value: the browser stores whatever the user types, and your JavaScript reads it when needed. React prefers a different arrangement. The value lives in **state**, the input displays that state through its `value` attribute, and every keystroke updates the state through `onChange`. Because React controls what the input shows, this is called a **controlled input**. State is the single source of truth, so the value is always available for validation, previews, and submitting.

### Step 1: Create a Form with One Controlled Input

Create `src/components/TransactionForm.jsx` with a single field first.

```jsx
import { useState } from "react";

function TransactionForm() {
  const [title, setTitle] = useState("");

  return (
    <form className="transaction-form">
      <label htmlFor="title">Title</label>
      <input id="title" type="text" value={title} onChange={(event) => setTitle(event.target.value)} />
      <p>Preview: {title}</p>
    </form>
  );
}

export default TransactionForm;
```

Here is what this code does:

- `const [title, setTitle] = useState("");` creates state for the title, starting with an empty string. The initial value must be a string, not `undefined`, for reasons you will see in the Fix the Errors section.
- `value={title}` tells the input to always display the current state.
- `onChange={(event) => setTitle(event.target.value)}` runs on every keystroke and stores the input's new text in state. React then re-renders, and the input displays the updated state.
- `<p>Preview: {title}</p>` shows the same state below the input, which proves the value is in React's hands.

Now show the form in the panel. Open `src/App.jsx`, delete the whole `handleQuickAdd` function, import the new component, and replace the panel's contents.

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
          <TransactionForm />
        </section>
      )}
      <Filters />
      <TransactionList transactions={transactions} onDelete={handleDelete} />
    </main>
  );
}

export default App;
```

The panel now contains `<TransactionForm />` instead of the placeholder text and the quick-add button. `setTransactions` is temporarily unused, and the linter will mention it; you will use it again in Section 3.

Save both files, click "+ Add transaction", and type `Lunch` in the Title box.

What you see in the panel:

```text
Title

Preview: Lunch
```

The preview updates letter by letter as you type, because each keystroke changes the state and React re-renders the form.

### Step 2: Add the Remaining Fields

A transaction needs four more values. Replace `src/components/TransactionForm.jsx` with the full set of fields.

```jsx
import { useState } from "react";

const categories = ["Food", "Transport", "Shopping", "Bills", "Entertainment", "Salary", "Freelance", "Other"];

function TransactionForm() {
  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("");
  const [type, setType] = useState("expense");
  const [category, setCategory] = useState("Food");
  const [date, setDate] = useState("");

  return (
    <form className="transaction-form">
      <h2>New transaction</h2>

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

      <p className="form-preview">
        Preview: {title} · {amount} · {type} · {category} · {date}
      </p>
    </form>
  );
}

export default TransactionForm;
```

Here is what is new:

- `const categories = [...]` is defined **outside** the component, at the top of the file. The list never changes, so there is no reason to recreate it on every render.
- Every field follows the same pattern: one piece of state, `value={state}`, and `onChange` that calls the setter with `event.target.value`. Each field is wrapped in a `form-field` div with its label.
- The amount uses `type="number"`, which shows a numeric keyboard on phones and lets users step up and down. `min="0"` blocks negative numbers in the browser's own check, and `step="0.01"` allows cents. The amount state starts as an empty string, not `0`, so the box starts empty instead of showing a zero.
- A `<select>` is controlled the same way as an input: `value={type}` selects the matching option. `type` starts as `"expense"`, the most common choice, and `category` starts as `"Food"`.
- The category options are generated with `map`, exactly like the transaction list. Each category name is unique, so the name itself is a good `key`.
- `type="date"` shows the browser's date picker. Whatever format it displays, its value is always a string in `YYYY-MM-DD` format, which matches Spendly's `date` property.
- The preview line now shows all five values.

Add the form styles to the end of `src/App.css`. Also delete the `.panel p` rule from Lesson 9, because the panel no longer contains that placeholder paragraph.

```css
/* Transaction form */
.transaction-form {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.transaction-form h2 {
  grid-column: 1 / -1;
  font-size: 20px;
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-field input,
.form-field select {
  padding: 8px 10px;
  font-size: 16px;
  font-family: inherit;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background-color: var(--color-surface);
}

.form-preview,
.form-error,
.form-actions {
  grid-column: 1 / -1;
}

.form-error {
  color: var(--color-expense);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
```

The form uses a two-column grid, so the fields sit in pairs. The heading, the preview, the error message, and the buttons span the full width with `grid-column: 1 / -1`. The `.form-error` and `.form-actions` rules are for elements you will add later in this lesson.

Save both files. Fill in the form: title `Lunch`, amount `12.5`, leave the type as Expense and the category as Food, and choose October 20, 2026 as the date.

What you see in the preview line:

```text
Preview: Lunch · 12.5 · expense · Food · 2026-10-20
```

All five values are in state, and the date arrives as `2026-10-20` even though the date picker may display it as `10/20/2026` depending on your system.

---

## 3. Submit the Form

The data is collected. Now the form has to send it somewhere. `TransactionForm` does not own the list of transactions; `App` does. So the form will follow the pattern from Lesson 8: it receives a function as a prop and calls it with the new data. `App` decides what to do with it.

### Step 1: Handle the Submission

Replace `src/components/TransactionForm.jsx` with this version.

```jsx
import { useState } from "react";

const categories = ["Food", "Transport", "Shopping", "Bills", "Entertainment", "Salary", "Freelance", "Other"];

function TransactionForm({ onAdd, onCancel }) {
  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("");
  const [type, setType] = useState("expense");
  const [category, setCategory] = useState("Food");
  const [date, setDate] = useState("");

  function handleSubmit(event) {
    event.preventDefault();

    onAdd({
      title: title,
      amount: Number(amount),
      type: type,
      category: category,
      date: date,
    });

    setTitle("");
    setAmount("");
    setType("expense");
    setCategory("Food");
    setDate("");
  }

  return (
    <form className="transaction-form" onSubmit={handleSubmit}>
      <h2>New transaction</h2>

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

      <div className="form-actions">
        <button type="button" className="button" onClick={onCancel}>
          Cancel
        </button>
        <button type="submit" className="button button-primary">
          Add transaction
        </button>
      </div>
    </form>
  );
}

export default TransactionForm;
```

Here is what changed:

- The component now receives two callback props: `onAdd`, called with the new transaction, and `onCancel`, called when the user gives up.
- `onSubmit={handleSubmit}` is on the `<form>`, so both clicking "Add transaction" and pressing `Enter` in a field submit the form.
- `event.preventDefault()` stops the page reload, as you learned in Lesson 8.
- `onAdd({ ... })` sends an object with five properties. There is no `id`: creating ids is the job of whoever stores the list, which is `App`.
- `amount: Number(amount)` converts the amount. Every input value is a **string**, even in a `type="number"` input. `Number("12.5")` returns the number `12.5`. Without this conversion, Spendly would store text, and calculations such as totals would break, just like Error 2 in Lesson 1.
- The five setter calls at the end reset the form to its initial values, so it is empty for the next transaction.
- The preview paragraph is gone, and the bottom of the form now has two buttons. "Cancel" is `type="button"`, so it does not submit the form; it just calls `onCancel`. "Add transaction" is `type="submit"`.

Next, update `src/App.jsx` to receive the new transaction.

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

  function handleAddClick() {
    setIsFormOpen(!isFormOpen);
  }

  function handleAdd(transactionData) {
    const newTransaction = { id: Date.now(), ...transactionData };
    setTransactions([newTransaction, ...transactions]);
    setIsFormOpen(false);
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
          <TransactionForm onAdd={handleAdd} onCancel={() => setIsFormOpen(false)} />
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

- `handleAdd(transactionData)` receives the object from the form.
- `{ id: Date.now(), ...transactionData }` creates the complete transaction. The **object spread** `...transactionData` copies all five properties from the form's object into the new object, next to the new `id`. This is the object version of the array spread you used in Lesson 9.
- `setTransactions([newTransaction, ...transactions])` adds it to the top of the list, and `setIsFormOpen(false)` closes the panel.
- `onCancel={() => setIsFormOpen(false)}` is a short inline arrow function that closes the panel without adding anything.

Save both files. Open the form, enter `Lunch`, `12.50`, Expense, Food, and October 20, 2026, then click "Add transaction". The panel closes and the new transaction appears at the top of the list.

What you see at the top of the transactions section:

```text
Transactions

Showing 6 transactions

Lunch
Food · 2026-10-20
-$12.5
```

It works, but `-$12.5` looks wrong for money. You will fix that in the next step. Open the form again: all fields are empty, because the form reset itself before closing. Click "Cancel" to close it.

### Step 2: Format Amounts with Cents

`formatAmount` from Lesson 5 uses `toLocaleString("en-US")`, which drops trailing zeros. Whole amounts like `3400` should stay as `$3,400`, but amounts with cents should always show two decimals. Replace `src/utils/format.js`.

```javascript
export function formatAmount(amount) {
  const sign = amount < 0 ? "-" : "";
  const formatted = Math.abs(amount).toLocaleString("en-US", {
    minimumFractionDigits: Number.isInteger(amount) ? 0 : 2,
    maximumFractionDigits: 2,
  });
  return `${sign}$${formatted}`;
}
```

Here is what changed:

- `toLocaleString` accepts a second argument, an options object, that controls the number of decimal places.
- `Number.isInteger(amount)` is `true` for whole numbers like `3400`. For those, `minimumFractionDigits` is `0`, so no decimals are added.
- For amounts with cents, `minimumFractionDigits` is `2`, so `12.5` becomes `12.50`.
- `maximumFractionDigits: 2` rounds anything longer, so `1234.567` becomes `1,234.57`.

Save the file. The lunch row now shows `-$12.50`, and every other amount in Spendly looks exactly as before, because every component uses the same helper. This is the payoff of putting formatting in one shared function.

---

## 4. Validate the Input

Try submitting the form empty. Spendly happily adds a transaction with no title, an amount of `$0`, and no date, because `Number("")` is `0`. A form should check its input before accepting it, and tell the user what is wrong.

### Step 1: Check the Fields and Show an Error

Replace `src/components/TransactionForm.jsx` with the final version for this lesson.

```jsx
import { useState } from "react";

const categories = ["Food", "Transport", "Shopping", "Bills", "Entertainment", "Salary", "Freelance", "Other"];

function TransactionForm({ onAdd, onCancel }) {
  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("");
  const [type, setType] = useState("expense");
  const [category, setCategory] = useState("Food");
  const [date, setDate] = useState("");
  const [error, setError] = useState("");

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

    onAdd({
      title: title.trim(),
      amount: amountNumber,
      type: type,
      category: category,
      date: date,
    });

    setTitle("");
    setAmount("");
    setType("expense");
    setCategory("Food");
    setDate("");
    setError("");
  }

  return (
    <form className="transaction-form" onSubmit={handleSubmit}>
      <h2>New transaction</h2>

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
          Add transaction
        </button>
      </div>
    </form>
  );
}

export default TransactionForm;
```

Here is what is new:

- `const [error, setError] = useState("");` stores the current error message. An empty string means "no error".
- `const amountNumber = Number(amount);` converts the amount once, before the checks, so the checks and `onAdd` use the same number.
- `title.trim() === ""` catches a title that is empty or only spaces. `trim()` removes spaces from both ends. The trimmed title is also what gets saved, so `"  Lunch "` is stored as `"Lunch"`.
- `!(amountNumber > 0)` rejects anything that is not a positive number. It is written this way, instead of `amountNumber <= 0`, because it also catches `NaN` ("not a number"), which `Number` returns for text it cannot convert. Every comparison with `NaN` is `false`, so `NaN > 0` is `false`, and the `!` turns that into `true`.
- Each check sets a message and then `return`s, which stops the function before `onAdd` is called. The user sees the first problem, fixes it, and submits again.
- After a successful submit, `setError("")` clears any old message.
- `{error && <p className="form-error">{error}</p>}` shows the message in red, only when there is one. An empty string is falsy, so nothing is rendered when there is no error. Unlike a number, an empty string renders nothing even when it ends up on the left of `&&`, so there is no `0 &&` problem here.

Save the file and test the checks in order, clicking "Add transaction" after each change.

What you see in the form's error line at each step:

```text
1. Empty form                          -> Please enter a title.
2. Title is three spaces               -> Please enter a title.
3. Title "Lunch", no amount            -> Please enter an amount greater than 0.
4. Amount 0                            -> Please enter an amount greater than 0.
5. Amount 12.50, no date               -> Please choose a date.
6. Date October 20, 2026               -> (form closes, Lunch is added)
```

The browser also has its own checks for some input types. For example, typing `-5` in the amount field and submitting shows a small browser message, because of `min="0"`. React's validation and the browser's validation work together, but you should never rely on the browser alone, because its rules are easy to bypass.

---

## 5. Run and Test

Refresh the page to start from the sample data, then run through the whole flow:

1. Click "+ Add transaction". The form appears in the panel, and the button says "Close".
2. Click "Add transaction" without filling anything in. The message "Please enter a title." appears in red.
3. Fill in `Lunch`, `12.50`, Expense, Food, and October 20, 2026, then click "Add transaction".

What you see at the top of the transactions section:

```text
Transactions

Showing 6 transactions

Lunch
Food · 2026-10-20
-$12.50
Delete
```

4. Open the form again. It is empty and has no error message.
5. Type something, then click "Cancel". The panel closes and nothing is added.
6. Add an income: `Birthday gift`, `50`, Income, Other, any date. It appears at the top with a green `+$50`.

The summary cards still show the original totals; they become live in Lesson 13. Run the linter as a final check.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

```

---

## 6. Controlled Inputs in Depth

You have now built a complete controlled form. Here are the ideas behind it in one place.

**The controlled loop.** Every keystroke goes through the same cycle: the user types, `onChange` fires, the setter stores the new text, React re-renders, and the input displays the state through `value`. It sounds like a lot of work for one letter, but it happens instantly, and it means the value is always in your hands.

**Why bother?** Because the value lives in state, you can:

- show it somewhere else, like the preview line;
- validate it or format it while the user types;
- reset the whole form with a few setter calls;
- fill the form with existing data, which you will do in Lesson 11 to edit transactions.

**Uncontrolled inputs.** React also supports inputs that keep their own value, read with a **ref** when needed, or set once with `defaultValue`. Some form libraries use that approach for performance. For a beginner app like Spendly, controlled inputs are simpler to reason about, and they are what most tutorials and AI tools produce.

**Input values are always strings.** `event.target.value` is a string for text inputs, number inputs, date inputs, and selects. Convert numbers with `Number(...)` when you read them for calculations or storage, and keep the string in state while the user types, so that partial input such as `12.` is not lost.

**One state per field, or one object?** This form uses one `useState` per field, which is the clearest approach while learning. Larger forms sometimes store all fields in a single object, `{ title, amount, ... }`, and update it with the object spread syntax. Both are valid. You will see the object style in AI-generated code; it follows exactly the same controlled-input rules.

---

## 7. Fix the Errors in Your Code

Forms are where many React bugs hide. Here are three that produce real messages.

**Error 1: Giving an input a value without onChange.**

```jsx
// Wrong
<input id="date" type="date" value={date} />

// Correct
<input id="date" type="date" value={date} onChange={(event) => setDate(event.target.value)} />
```

With the wrong version, picking a date has no effect: the field stays empty. The console explains why:

```text
You provided a `value` prop to a form field without an `onChange` handler. This will render a read-only field. If the field should be mutable use `defaultValue`. Otherwise, set either `onChange` or `readOnly`.
```

The input always shows `value={date}`, and nothing ever changes `date`, so the input is effectively read-only. A controlled input always needs both halves: `value` and `onChange`.

**Error 2: Starting the state as undefined.**

```jsx
// Wrong
const [title, setTitle] = useState();

// Correct
const [title, setTitle] = useState("");
```

`useState()` with no argument starts the state as `undefined`. An input with `value={undefined}` is treated as uncontrolled. When the user types the first letter, the state becomes a string, and the input suddenly becomes controlled. React warns about the switch in the console:

```text
A component is changing an uncontrolled input to be controlled. This is likely caused by the value changing from undefined to a defined value, which should not happen. Decide between using a controlled or uncontrolled input element for the lifetime of the component. More info: https://react.dev/link/controlled-components
```

Always initialize text fields with an empty string `""`.

**Error 3: Forgetting to convert the amount.**

```jsx
// Wrong
onAdd({
  title: title.trim(),
  amount: amount,
  type: type,
  category: category,
  date: date,
});

// Correct
onAdd({
  title: title.trim(),
  amount: amountNumber,
  type: type,
  category: category,
  date: date,
});
```

The wrong version seems to work: the lunch appears in the list as `-$12.50`. But the stored amount is text. To see it, add this line inside `handleAdd` in `App.jsx`, right after `newTransaction` is created:

```jsx
console.log("Amount:", newTransaction.amount, "Type:", typeof newTransaction.amount);
```

Output in the console after adding the lunch:

```text
Amount: 12.50 Type: string
```

`typeof` reveals that the amount is the string `"12.50"`, not a number. The list hides the problem because `formatAmount` happens to cope with it, but in Lesson 13, adding up the expenses with `+` would join strings together instead of adding numbers, exactly like Error 2 in Lesson 1. Always convert with `Number` before storing, and remove the debug `console.log` when you are done.

---

## 8. Exercises

**Exercise 1:** Limit titles to 40 characters with the `maxLength` attribute, and show a small counter under the title input, such as `5/40`, that updates as the user types. Give it the class `form-hint`.

**Exercise 2:** Make the form smarter: when the user changes the type to Income, automatically switch the category to Salary, and when they change it back to Expense, switch the category to Food. Write a named handler, `handleTypeChange`, for the type dropdown.

**Exercise 3:** Add one more validation rule: an amount above `1000000` shows the message "That amount looks too large. Please check it." The check should run after the "greater than 0" check and before the date check.

---

## 9. Solutions

**Solution for Exercise 1:**

Update the title field in `src/components/TransactionForm.jsx`.

```jsx
<div className="form-field">
  <label htmlFor="title">Title</label>
  <input
    id="title"
    type="text"
    placeholder="e.g. Lunch"
    maxLength={40}
    value={title}
    onChange={(event) => setTitle(event.target.value)}
  />
  <small className="form-hint">{title.length}/40</small>
</div>
```

`maxLength={40}` makes the browser stop accepting characters after 40. It is written with curly braces because it is a number. The counter reads `title.length` straight from state, so it updates on every keystroke without any extra code. Before typing it shows `0/40`, and after typing `Lunch` it shows `5/40`. You can style the hint in `App.css`, for example with `font-size: 12px;` and the muted color.

**Solution for Exercise 2:**

Add the handler inside `TransactionForm`, before `handleSubmit`.

```jsx
function handleTypeChange(event) {
  const newType = event.target.value;
  setType(newType);
  setCategory(newType === "income" ? "Salary" : "Food");
}
```

Then use it on the type dropdown.

```jsx
<select id="type" value={type} onChange={handleTypeChange}>
  <option value="expense">Expense</option>
  <option value="income">Income</option>
</select>
```

One event can update several pieces of state. The handler reads the new type from the event, not from the `type` state, because `type` still holds the old value until the next render, as you learned in Lesson 9. Choosing Income now selects Salary, and choosing Expense selects Food. The user can still pick any other category afterward.

**Solution for Exercise 3:**

Add the check in `handleSubmit`, between the amount check and the date check.

```jsx
if (amountNumber > 1000000) {
  setError("That amount looks too large. Please check it.");
  return;
}
```

With a title, a date, and an amount of `2500000`, submitting shows:

```text
That amount looks too large. Please check it.
```

The order of checks decides which message the user sees first. Grouping the two amount checks together keeps the code easy to follow.

---

## Next Up - Lesson 11

In this lesson you built `TransactionForm` with controlled inputs for text, numbers, dropdowns, and dates. You submitted the form with `onSubmit` and `preventDefault`, sent the data up to `App` with an `onAdd` callback, converted the amount with `Number`, validated the input with an error message in state, reset the form after a successful submit, and improved `formatAmount` for amounts with cents. Users can now add their own transactions to Spendly.

In Lesson 11, you will complete the basic set of list operations. The Delete buttons will finally remove transactions, using `filter`, and a new Edit button will open the same form filled with an existing transaction, so users can fix mistakes. Along the way, you will learn why React state must always be updated immutably, and how to update one object inside an array with `map`.
