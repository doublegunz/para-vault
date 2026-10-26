## 1. Before You Begin

In Lesson 15, Spendly started fetching data: categories from a JSON file and exchange rates from a public API. Both features work, but look at the code they needed. `App` has an effect to load categories and another to save transactions, plus a helper and a constant for storage. `CurrencyConverter` has four pieces of state and an effect with a cleanup, and most of that code is the same "fetch, check, store, handle errors" routine you wrote for the categories.

When the same logic appears in more than one component, React lets you package it into your own hook. A **custom hook** is a JavaScript function whose name starts with `use` and that calls other hooks. In this lesson you will write two of them: `useLocalStorage`, which works like `useState` but remembers its value between visits, and `useFetch`, which loads data from a URL and reports loading and errors. Then you will rewrite `App` and `CurrencyConverter` to use them. The app will behave exactly as before, but the components will be shorter, and the logic will be written once.

### What You'll Build

- `src/hooks/useLocalStorage.js`: a hook that stores a value in state and saves it to `localStorage` whenever it changes.
- `src/hooks/useFetch.js`: a hook that fetches JSON from a URL and returns the data, a loading flag, and an error message, refetching when the URL changes.
- A shorter `App` that loads and saves its transactions with one line, and loads the categories with another.
- A `CurrencyConverter` that shrinks from four pieces of state and an effect to one piece of state and one hook call.

### What You'll Learn

- ✅ What a custom hook is and when to write one
- ✅ The naming rule for hooks and why it matters
- ✅ How to give a custom hook parameters and return values
- ✅ How to return an array like `useState` or an object with named values
- ✅ How to rename values while destructuring an object
- ✅ That each component calling a hook gets its own independent state
- ✅ Why hooks must never be called conditionally

### What You'll Need

- The Spendly project from Lesson 15
- The development server running with `npm run dev`
- If you completed the Lesson 15 exercises, your `CurrencyConverter` has extra features. This lesson rewrites it from the version in Section 3 of Lesson 15, so either remove the exercise changes first or adapt the new code to keep them.

---

## 2. Write a useLocalStorage Hook

Look at how Spendly saves its transactions today. Three separate pieces work together: a `STORAGE_KEY` constant, a `loadTransactions` function for the initial state, and an effect that saves on every change. If you wanted to remember a second value, such as the selected category, you would need all three pieces again. A custom hook can bundle them into a single call that feels just like `useState`.

### Step 1: Create the Hook

Create a new folder named `hooks` inside `src`, and inside it a file named `useLocalStorage.js`.

```javascript
import { useEffect, useState } from "react";

export function useLocalStorage(key, initialValue) {
  const [value, setValue] = useState(() => {
    const saved = localStorage.getItem(key);
    return saved !== null ? JSON.parse(saved) : initialValue;
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue];
}
```

Here is what this code does:

- `export function useLocalStorage(key, initialValue)` is an ordinary JavaScript function with two parameters: the name to store the value under, and the value to use when nothing is saved yet. Its name starts with `use`, which tells React and the linter that it is a hook and that the rules of hooks apply inside it.
- `useState(() => { ... })` uses lazy initialization, as in Lesson 14, but with an inline arrow function. On the first render, it reads `localStorage`. If something was saved under `key`, it parses it; otherwise, it uses `initialValue`. The check is `saved !== null` rather than just `saved`, so that a saved empty string or `0` is not mistaken for "nothing saved".
- The effect saves the value as JSON whenever it changes. It lists both `key` and `value` as dependencies, because it uses both.
- `return [value, setValue];` returns the same two things `useState` returns, in the same order. Code that uses this hook can destructure it exactly like `useState`.

The file uses the `.js` extension, because it contains no JSX. Notice that nothing in the hook mentions transactions. It works for any value that can be turned into JSON: an array, an object, a string, a number, or a boolean.

### Step 2: Use It for the Transactions

Open `src/App.jsx`. Delete the `STORAGE_KEY` constant, the `loadTransactions` function, and the effect that calls `localStorage.setItem`. Import the hook:

```jsx
import { useLocalStorage } from "./hooks/useLocalStorage.js";
```

And replace the `transactions` state line with this one:

```jsx
const [transactions, setTransactions] = useLocalStorage("spendly-transactions", sampleTransactions);
```

The line reads almost exactly like the `useState` line it replaces, with one extra argument: the storage key. Everything else in `App` keeps working, because `transactions` and `setTransactions` behave just as before. The difference is that they are now automatically loaded from and saved to the browser.

Save the file, add a transaction, and refresh the page. The transaction is still there, as it was in Lesson 14, but `App` no longer contains any storage code.

---

## 3. Write a useFetch Hook

Fetching data needs more code than saving it: loading and error states, the `response.ok` check, `try...catch`, and the cleanup that prevents race conditions. `App` and `CurrencyConverter` each contain a copy of this routine. A `useFetch` hook will hold the only copy.

### Step 1: Create the Hook

Create `src/hooks/useFetch.js`.

```javascript
import { useEffect, useState } from "react";

export function useFetch(url) {
  const [result, setResult] = useState({ url: null, data: null, error: "" });

  useEffect(() => {
    let ignore = false;

    async function load() {
      try {
        const response = await fetch(url);
        if (!response.ok) {
          throw new Error(`Request failed with status ${response.status}`);
        }
        const data = await response.json();
        if (!ignore) {
          setResult({ url: url, data: data, error: "" });
        }
      } catch (error) {
        if (!ignore) {
          setResult({ url: url, data: null, error: error.message });
        }
      }
    }

    load();

    return () => {
      ignore = true;
    };
  }, [url]);

  const isLoading = result.url !== url;

  return {
    data: isLoading ? null : result.data,
    error: isLoading ? "" : result.error,
    isLoading: isLoading,
  };
}
```

Most of this code is the effect from Lesson 15, moved into a function that receives the URL as a parameter. Two things are new:

- **One piece of state for the result.** Instead of separate `data`, `error`, and `isLoading` state, the hook keeps a single `result` object that records which URL the result belongs to, along with the data or the error. Every time a request finishes, the whole object is replaced at once.
- **Loading is derived, not stored.** `const isLoading = result.url !== url;` compares the URL of the last result with the URL being asked for right now. On the first render, `result.url` is `null`, so the hook is loading. When the URL changes, for example because the user chose another currency, the old result belongs to the old URL, so the hook is loading again, immediately, without any state update. When the new answer arrives, `result.url` matches and loading ends. This is the derived-data idea from Lesson 13, and it removes the need to set `isLoading` back to `true` in an event handler.

The hook returns an **object** rather than an array: `{ data, error, isLoading }`. With three values, names are clearer than positions, and a component can pick only the ones it needs. While loading, the hook returns `null` and an empty error instead of the previous result, so a component never shows an old URL's data under a new label.

### Step 2: Use It for the Categories

In `src/App.jsx`, delete the two category state lines and the whole category-loading effect. Import the hook:

```jsx
import { useFetch } from "./hooks/useFetch.js";
```

Add this line where the category state used to be:

```jsx
const { data: categories, error: categoriesError } = useFetch("/categories.json");
```

This destructures the returned object and **renames** two values at the same time: `data: categories` means "take the `data` property and call it `categories`". Renaming matters here, because `App` may call `useFetch` more than once, and every call returns a property named `data`.

While the file is loading, `categories` is `null`, and the form and filters expect an array they can `map` over. Change both places that pass the categories so they fall back to an empty array:

```jsx
categories={categories ?? []}
```

The `??` operator from Lesson 11 returns the empty array while `categories` is `null`.

Here is the top of `App` after these changes, so you can compare it with yours:

```jsx
import { useEffect, useState } from "react";
import "./App.css";
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import TransactionForm from "./components/TransactionForm.jsx";
import CurrencyConverter from "./components/CurrencyConverter.jsx";
import { sampleTransactions } from "./data/transactions.js";
import { getTotals } from "./utils/transactions.js";
import { formatAmount } from "./utils/format.js";
import { useLocalStorage } from "./hooks/useLocalStorage.js";
import { useFetch } from "./hooks/useFetch.js";

function App() {
  const [transactions, setTransactions] = useLocalStorage("spendly-transactions", sampleTransactions);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("All");
  const { data: categories, error: categoriesError } = useFetch("/categories.json");

  const totals = getTotals(transactions);
  const editingTransaction = transactions.find((transaction) => transaction.id === editingId);

  const visibleTransactions = transactions
    .filter((transaction) => category === "All" || transaction.category === category)
    .filter((transaction) => transaction.title.toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => b.date.localeCompare(a.date));

  const isFiltering = search !== "" || category !== "All";

  useEffect(() => {
    document.title = `Spendly (${formatAmount(totals.balance)})`;
  }, [totals.balance]);
```

The handlers and the JSX below this part are unchanged, apart from the two `categories ?? []` props. `App` went from three effects to one, and its state is now described in six readable lines.

### Step 3: Simplify CurrencyConverter

Replace `src/components/CurrencyConverter.jsx` with this much shorter version.

```jsx
import { useState } from "react";
import { useFetch } from "../hooks/useFetch.js";
import { formatAmount } from "../utils/format.js";

const currencies = ["EUR", "GBP", "JPY", "IDR"];

function CurrencyConverter({ amount }) {
  const [currency, setCurrency] = useState("EUR");
  const { data, isLoading, error } = useFetch(`https://api.frankfurter.dev/v1/latest?base=USD&symbols=${currency}`);

  const rate = data ? data.rates[currency] : null;

  return (
    <section className="converter">
      <label htmlFor="currency">Show my balance in</label>
      <select id="currency" value={currency} onChange={(event) => setCurrency(event.target.value)}>
        {currencies.map((code) => (
          <option key={code} value={code}>
            {code}
          </option>
        ))}
      </select>

      {isLoading && <p className="converter-result">Loading exchange rate...</p>}
      {error && <p className="converter-result form-error">Could not load the exchange rate: {error}</p>}
      {rate !== null && (
        <p className="converter-result">
          {formatAmount(amount)} is about{" "}
          <strong>{(amount * rate).toLocaleString("en-US", { style: "currency", currency: currency })}</strong>
          <small> (1 USD = {rate} {currency})</small>
        </p>
      )}
    </section>
  );
}

export default CurrencyConverter;
```

Here is what changed:

- The only state left is `currency`, the user's choice. Everything about the request comes from `useFetch`.
- The URL is built from `currency`. When the user picks another currency, the URL changes, and `useFetch` fetches the new rate by itself, because `url` is in its effect's dependency array. The component does not need to know that an effect exists.
- `const rate = data ? data.rates[currency] : null;` derives the rate from the response. While loading or after an error, `data` is `null`, so `rate` is `null`.
- `handleCurrencyChange` is gone. Changing the currency is now a single setter call, because `useFetch` already reports loading as soon as the URL changes.
- The three display conditions are simpler: `isLoading`, `error`, and `rate !== null` can never be true at the same time, because the hook never returns old data while loading.

The component went from about 70 lines to 37, and the fetching logic is now tested and reused in two places.

---

## 4. Run and Test

The goal of this refactoring is that nothing visible changes. Check every feature that used the old code:

1. The category dropdowns still list all nine categories, including "Health".
2. The converter shows the balance in euros, switches to "Loading exchange rate..." when you pick another currency, and then shows the new result. For example, choosing JPY gives:

```text
$3,223 is about ¥507,461 (1 USD = 157.45 JPY)
```

3. Add a transaction, refresh the page, and check that it is still there. With a lunch for `12.50` added, the page after the refresh shows:

```text
Showing 6 transactions
Spendly ($3,210.50)
$3,210.50 is about €2,869.58 (1 USD = 0.89381 EUR)
```

These are the count line, the tab title, and the converter, all loaded from the saved data. Your exchange rate will differ.

4. Go offline in the Network tab and switch the currency. The error message still appears, now produced by `useFetch`.

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

## 5. How Custom Hooks Work

**A custom hook is just a function.** There is no special API for creating one. Any function whose name starts with `use` and that calls other hooks is a custom hook. React does not even know it exists: when `App` calls `useLocalStorage`, React only sees the `useState` and `useEffect` calls inside it, as if they were written directly in `App`.

**Each call has its own state.** Hooks share **logic**, not **data**. If two components both call `useLocalStorage`, or one component calls it twice, each call gets its own independent state. `CurrencyConverter` and `App` both call `useFetch`, and their requests never interfere. If two components need the **same** data, you still lift state up, or use Context, which you will learn in Lesson 19.

**The naming rule is not a style preference.** The `use` prefix is how React's tools find hooks and check the rules of hooks inside them. A function named `localStorageState` that calls `useState` looks like a normal function, so the linter reports an error, as you will see below.

**The rules of hooks apply to custom hooks too.** Call them at the top level of a component or another hook, never inside a condition, a loop, or an event handler, and never after an early `return`.

**When to write a custom hook.** Good signs are: the same combination of state and effects appears in more than one place; a component has so much effect code that its actual purpose is hard to see; or a piece of logic has a clear name, such as "remember this value" or "fetch this URL". Do not wrap a single `useState` call in a hook just because you can. Spendly's form fields, for example, are clearer as plain `useState`.

**What should a hook return?** Return an array when there are two values that callers will rename, as `useState` and `useLocalStorage` do. Return an object when there are three or more values, or when callers will often want only some of them, as `useFetch` does.

You will see many custom hooks in AI-generated code and in libraries: `useAuth`, `useDebounce`, `useMediaQuery`, `useQuery`. Now you know that each one is a function built from the same `useState` and `useEffect` you already understand.

---

## 6. Fix the Errors in Your Code

These mistakes all break the rules that make hooks work.

**Error 1: Naming a hook without the use prefix.**

```javascript
// Wrong
export function localStorageState(key, initialValue) {
  const [value, setValue] = useState(() => {
    const saved = localStorage.getItem(key);
    return saved !== null ? JSON.parse(saved) : initialValue;
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue];
}

// Correct
export function useLocalStorage(key, initialValue) {
  const [value, setValue] = useState(() => {
    const saved = localStorage.getItem(key);
    return saved !== null ? JSON.parse(saved) : initialValue;
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue];
}
```

The wrong version actually runs: the page shows "Showing 5 transactions", and saving works. But the linter reports two errors:

```text
src/hooks/useLocalStorage.js:4:29: error react-hooks(rules-of-hooks): React Hook "useState" is called in function "localStorageState" that is neither a React function component nor a custom React Hook function. React component names must start with an uppercase letter. React Hook names must start with the word "use".
src/hooks/useLocalStorage.js:9:3: error react-hooks(rules-of-hooks): React Hook "useEffect" is called in function "localStorageState" that is neither a React function component nor a custom React Hook function. React component names must start with an uppercase letter. React Hook names must start with the word "use".
```

Without the prefix, the tools can no longer check how the function is used, so mistakes like Error 2 would go unnoticed. Always start a hook's name with `use`.

**Error 2: Calling a hook after an early return.**

Suppose you want the converter to show a short message when there is nothing to convert.

```jsx
// Wrong
function CurrencyConverter({ amount }) {
  const [currency, setCurrency] = useState("EUR");

  if (amount <= 0) {
    return <section className="converter">Nothing to convert yet.</section>;
  }

  const { data, isLoading, error } = useFetch(`https://api.frankfurter.dev/v1/latest?base=USD&symbols=${currency}`);
  // ...
}

// Correct
function CurrencyConverter({ amount }) {
  const [currency, setCurrency] = useState("EUR");
  const { data, isLoading, error } = useFetch(`https://api.frankfurter.dev/v1/latest?base=USD&symbols=${currency}`);

  if (amount <= 0) {
    return <section className="converter">Nothing to convert yet.</section>;
  }
  // ...
}
```

The wrong version works while the balance is positive. Then delete "Monthly salary", "Coffee with friends", and "Freelance design", so the balance drops below zero. The converter crashes the whole page, and the console shows:

```text
Error: Rendered fewer hooks than expected. This may be caused by an accidental early return statement.
```

React identifies hooks by the order in which they are called. On the earlier renders, `CurrencyConverter` called `useState` and then `useFetch` (with its own hooks inside). After the early return, `useFetch` was skipped, and React could no longer match the hooks to their state. The linter catches this before you run anything:

```text
src/components/CurrencyConverter.jsx:14:38: error react-hooks(rules-of-hooks): React Hook "useFetch" is called conditionally. React Hooks must be called in the exact same order in every component render. help: Move the Hook call before the condition, or call it unconditionally and branch inside the Hook/effect instead.
```

Call every hook first, then decide what to return.

**Error 3: Destructuring the hook's result the wrong way.**

`useLocalStorage` returns an array, but it is easy to treat it like an object.

```jsx
// Wrong
const { value: transactions, setValue: setTransactions } = useLocalStorage("spendly-transactions", sampleTransactions);

// Correct
const [transactions, setTransactions] = useLocalStorage("spendly-transactions", sampleTransactions);
```

With the wrong version, the page is blank and the console shows:

```text
TypeError: transactions is not iterable
```

An array has no property named `value`, so `transactions` is `undefined`, and the `for...of` loop in `getTotals` fails on it. The error appears far from the real mistake. When a value from a hook is unexpectedly `undefined`, check whether the hook returns an array (destructure with square brackets) or an object (destructure with curly braces and the exact property names).

---

## 7. Exercises

**Exercise 1:** Write a third hook, `useDocumentTitle(title)`, in `src/hooks/useDocumentTitle.js`, that sets `document.title` whenever the title changes. Use it in `App` to replace the remaining title effect, so `App` no longer imports `useEffect` at all.

**Exercise 2:** Make the converter remember the chosen currency between visits, under the key `spendly-currency`. You should only need to change one line and one import.

**Exercise 3:** Make `App` remember the selected category filter between visits, under the key `spendly-category`, with a one-line change. Then open the Application tab in the developer tools and look at how the two new values are stored. Why are they wrapped in double quotes?

---

## 8. Solutions

**Solution for Exercise 1:**

Create `src/hooks/useDocumentTitle.js`.

```javascript
import { useEffect } from "react";

export function useDocumentTitle(title) {
  useEffect(() => {
    document.title = title;
  }, [title]);
}
```

In `src/App.jsx`, import it, change the React import back to `useState` only, and replace the effect with one line:

```jsx
import { useState } from "react";
```

```jsx
import { useDocumentTitle } from "./hooks/useDocumentTitle.js";
```

```jsx
useDocumentTitle(`Spendly (${formatAmount(totals.balance)})`);
```

A hook does not have to return anything. This one only performs an effect. The calculation of the title stays in `App`, where the data is, and the hook only knows how to apply a title. The tab still reads `Spendly ($3,223)`, and it still updates whenever the balance changes, because the title string changes and the hook's effect depends on it.

**Solution for Exercise 2:**

In `src/components/CurrencyConverter.jsx`, replace the `useState` import with the hook import, and change the state line:

```jsx
import { useLocalStorage } from "../hooks/useLocalStorage.js";
```

```jsx
const [currency, setCurrency] = useLocalStorage("spendly-currency", "EUR");
```

Because `useLocalStorage` returns the same `[value, setValue]` pair as `useState`, nothing else in the component changes. Choose GBP and refresh: the converter starts with GBP and immediately fetches the pound rate:

```text
$3,223 is about £2,414.67 (1 USD = 0.7492 GBP)
```

**Solution for Exercise 3:**

In `src/App.jsx`, change the category state line:

```jsx
const [category, setCategory] = useLocalStorage("spendly-category", "All");
```

Choose "Food" and refresh: the filter is still on Food and the list shows "Showing 2 transactions". In the Application tab, the stored values look like this:

```text
spendly-currency    "GBP"
spendly-category    "Food"
```

They are in double quotes because `useLocalStorage` always stores values with `JSON.stringify`, and the JSON form of a string includes its quotes. `JSON.parse` removes them again when the value is loaded. This is a small cost of writing one general hook for every kind of value: strings are stored as JSON strings, but the hook works the same way for strings, numbers, arrays, and objects.

---

## Next Up - Lesson 17

In this lesson you learned to write custom hooks. `useLocalStorage` gives any component state that survives a refresh, and `useFetch` loads data with loading and error states and protection against race conditions. You rewrote `App` and `CurrencyConverter` to use them, learned that hooks share logic but not state, practiced renaming while destructuring, and saw why the `use` prefix and the order of hook calls matter. That completes Module 5.

Spendly does a lot now, and it all lives on a single page. In Lesson 17, you will start Module 6 by installing React Router and splitting Spendly into separate pages, a Dashboard, a Transactions page, and an Add Transaction page, with a navigation bar, a shared layout, and a "page not found" screen.
