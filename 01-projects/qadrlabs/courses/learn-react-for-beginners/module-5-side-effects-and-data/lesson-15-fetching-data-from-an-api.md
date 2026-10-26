## 1. Before You Begin

In Lesson 14, you used `useEffect` to keep Spendly in sync with two things outside React: the page title and the browser's `localStorage`. Both live inside the browser, so they respond instantly. Most real apps also need data from somewhere else: a file on the server, a company's backend, or a public API on the internet. That data takes time to arrive, and sometimes it never does.

In this lesson Spendly goes online. You will move the category list out of the JavaScript code and into a JSON file that the app downloads when it starts. Then you will build a currency converter that fetches live exchange rates from Frankfurter, a free public API, and shows your balance in euros, pounds, yen, or rupiah. Along the way you will learn `fetch` with `async` and `await`, how to show loading and error states, and how an effect **cleanup** function protects you from answers that arrive in the wrong order.

### What You'll Build

- A `public/categories.json` file that holds Spendly's categories, loaded with `fetch` when the app starts and passed to the form and the filters.
- A red banner that explains what went wrong if the categories cannot be loaded.
- A `CurrencyConverter` component that shows text such as `$3,223 is about €2,880.75 (1 USD = 0.89381 EUR)`, with a dropdown to choose the currency.
- A "Loading exchange rate..." message while a request is on its way, and a clear error message when it fails.

### What You'll Learn

- ✅ What an API is and what a JSON response looks like
- ✅ How to request data with `fetch`, `async`, and `await`
- ✅ How to check `response.ok` and handle errors with `try...catch`
- ✅ How to fetch data in an effect without making the effect itself `async`
- ✅ How to show loading and error states while data arrives
- ✅ What a race condition is and how an effect cleanup function prevents it
- ✅ How files in the `public` folder are served

### What You'll Need

- The Spendly project from Lesson 14
- The development server running with `npm run dev`
- An internet connection for the exchange rate API. Frankfurter is free and does not need an account or an API key.
- If you completed the Lesson 14 exercises, you can keep them. The code in this lesson shows `App` without them.

---

## 2. Load the Categories from a JSON File

So far, Spendly's categories are an array inside `src/data/categories.js`. To add a category, someone has to change the code and rebuild the app. In many real apps, lists like this come from a server, so they can change without touching the code. You will simulate that with a JSON file that the browser downloads, exactly as it would download data from a real API.

### Step 1: Create the JSON File

Create a file named `categories.json` in the `public` folder (not in `src`).

```json
["Food", "Transport", "Shopping", "Bills", "Entertainment", "Health", "Salary", "Freelance", "Other"]
```

The content is the same list as before, with one new category, `Health`, so you can tell the new list apart from the old one. A JSON file can hold an array, an object, a string, a number, a boolean, or `null`. Strings must use double quotes.

Remember from Lesson 2 that Vite serves everything in `public` as-is, at the root of the site. Open `http://localhost:5173/categories.json` in your browser and you will see the raw list. That address is what Spendly will request.

### Step 2: Fetch the Categories in App

`fetch` is a function built into every browser. It sends a request to an address and returns a **promise**: an object that represents a result that will arrive later. The `async` and `await` keywords let you write code that waits for promises as if it were ordinary step-by-step code. You will use them inside an effect, because downloading data is a side effect: the app reaches outside itself.

Open `src/App.jsx` and add two pieces of state next to the others:

```jsx
const [categories, setCategories] = useState([]);
const [categoriesError, setCategoriesError] = useState("");
```

Then add this effect as the first effect in `App`, before the `localStorage` effect:

```jsx
useEffect(() => {
  async function loadCategories() {
    try {
      const response = await fetch("/categories.json");
      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }
      const data = await response.json();
      setCategories(data);
    } catch (error) {
      setCategoriesError(error.message);
    }
  }

  loadCategories();
}, []);
```

Here is what this code does, line by line:

- `categories` starts as an empty array, because there is nothing to show until the file arrives. `categoriesError` starts as an empty string, meaning "no error".
- `async function loadCategories()` declares an **async function**. Only async functions may use `await`.
- `await fetch("/categories.json")` sends the request and waits for the server's answer. The path starts with `/`, so it means "from the root of this site". The result is a **response** object that describes the answer: its status code, its headers, and a body that has not been read yet.
- `response.ok` is `true` when the status code is in the 200 to 299 range, which means success. For anything else, such as `404 Not Found` or `500 Internal Server Error`, the code throws an error on purpose. `fetch` does not do this by itself: it only fails when the request could not be sent at all.
- `await response.json()` reads the body and parses it as JSON, giving you a normal JavaScript array. It is a second `await`, because reading the body also takes time.
- `setCategories(data)` stores the list in state, which re-renders `App`.
- `try { ... } catch (error) { ... }` catches anything that goes wrong in the `try` block: a network failure, a bad status, or a body that is not valid JSON. `error.message` holds a short description, which is stored for display.
- `loadCategories();` calls the async function right away. The effect function itself is **not** async. You will see why in the Fix the Errors section.
- `[]` as the dependency array means the effect runs once, when `App` first appears. In development you will see the request twice because of `StrictMode`, which is harmless here.

Next, show the error if there is one. Add this line in the JSX, right after `<Header userName="Dina" />`:

```jsx
{categoriesError && <p className="error-banner">Could not load categories: {categoriesError}</p>}
```

And add the banner style to the end of `src/App.css`:

```css
/* Messages */
.error-banner {
  padding: 12px 16px;
  color: var(--color-expense);
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 8px;
}
```

### Step 3: Pass the Categories Down

The categories now live in `App`'s state, so `App` must pass them to the two components that use them. Add a `categories` prop to both in the JSX of `src/App.jsx`:

```jsx
<TransactionForm
  key={editingId ?? "new"}
  initialTransaction={editingTransaction}
  categories={categories}
  onSubmit={handleSave}
  onCancel={closeForm}
/>
```

```jsx
<Filters
  search={search}
  onSearchChange={setSearch}
  category={category}
  onCategoryChange={setCategory}
  categories={categories}
/>
```

In `src/components/Filters.jsx`, delete the `import { categories } ...` line and receive the list as a prop instead:

```jsx
function Filters({ search, onSearchChange, category, onCategoryChange, categories }) {
```

In `src/components/TransactionForm.jsx`, delete the same import line and add `categories` to the props:

```jsx
function TransactionForm({ initialTransaction = emptyTransaction, categories, onSubmit, onCancel }) {
```

The rest of both components stays the same, because they already loop over a variable called `categories`. Finally, delete the file `src/data/categories.js`, since nothing uses it anymore.

Save all files. Open the category dropdown in the filters, then open the form and check its category dropdown.

The options in each dropdown:

```text
Filters: All, Food, Transport, Shopping, Bills, Entertainment, Health, Salary, Freelance, Other
Form:    Food, Transport, Shopping, Bills, Entertainment, Health, Salary, Freelance, Other
```

"Health" appears in both, which proves the list now comes from the JSON file. Open the developer tools, go to the **Network** tab, and refresh the page. You will see a request for `categories.json` with the status `200`.

---

## 3. Fetch Live Exchange Rates

A local file always answers quickly. A real API on the internet is slower, can fail, and its data changes over time. Frankfurter (`https://api.frankfurter.dev`) is a free API that publishes daily exchange rates from the European Central Bank. You will use it to show Spendly's balance in another currency.

### Step 1: Look at the API Response

Open this address in your browser:

```text
https://api.frankfurter.dev/v1/latest?base=USD&symbols=EUR
```

The part after `?` is called the **query string**. It passes options to the API: `base=USD` asks for rates relative to the US dollar, and `symbols=EUR` limits the answer to euros. The browser shows a JSON response like this one, captured while writing this lesson:

```json
{"amount":1.0,"base":"USD","date":"2026-10-26","rates":{"EUR":0.89381}}
```

Your numbers and date will be different, because the rates are updated every working day. The useful parts are `rates.EUR`, the number of euros for one dollar, and `date`, the day the rate was published. Whenever you work with an API, look at a real response like this first, so you know the shape of the data before writing code.

### Step 2: Create the CurrencyConverter Component

Create `src/components/CurrencyConverter.jsx`.

```jsx
import { useEffect, useState } from "react";
import { formatAmount } from "../utils/format.js";

const currencies = ["EUR", "GBP", "JPY", "IDR"];

function CurrencyConverter({ amount }) {
  const [currency, setCurrency] = useState("EUR");
  const [rate, setRate] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let ignore = false;

    async function loadRate() {
      try {
        const response = await fetch(`https://api.frankfurter.dev/v1/latest?base=USD&symbols=${currency}`);
        if (!response.ok) {
          throw new Error(`Request failed with status ${response.status}`);
        }
        const data = await response.json();
        if (!ignore) {
          setRate(data.rates[currency]);
          setIsLoading(false);
        }
      } catch (error) {
        if (!ignore) {
          setError(error.message);
          setIsLoading(false);
        }
      }
    }

    loadRate();

    return () => {
      ignore = true;
    };
  }, [currency]);

  function handleCurrencyChange(event) {
    setCurrency(event.target.value);
    setIsLoading(true);
    setError("");
  }

  return (
    <section className="converter">
      <label htmlFor="currency">Show my balance in</label>
      <select id="currency" value={currency} onChange={handleCurrencyChange}>
        {currencies.map((code) => (
          <option key={code} value={code}>
            {code}
          </option>
        ))}
      </select>

      {isLoading && <p className="converter-result">Loading exchange rate...</p>}
      {!isLoading && error && <p className="converter-result form-error">Could not load the exchange rate: {error}</p>}
      {!isLoading && !error && (
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

This component combines everything from this module. Here it is in parts.

**The state.** Four pieces describe what the user chose and where the request stands:

- `currency` is the user's choice, starting with euros.
- `rate` is the latest exchange rate, `null` until the first answer arrives.
- `isLoading` is `true` while a request is on its way. It starts as `true`, because the first request starts immediately.
- `error` holds an error message, or an empty string.

**The effect.** It fetches the rate for the current currency:

- The URL is built with a template literal, so `${currency}` puts the chosen code into the query string.
- `[currency]` makes the effect run on the first render and again every time the user picks another currency.
- The `try...catch` block, the `response.ok` check, and `await response.json()` work exactly like the categories effect.
- `data.rates[currency]` uses **bracket notation** to read a property whose name is in a variable. When `currency` is `"GBP"`, it reads `data.rates.GBP`.

**The cleanup.** This is the new part:

- `let ignore = false;` is a local variable created every time the effect runs.
- `return () => { ignore = true; };` returns a **cleanup function**. React calls it before running the effect again (when `currency` changes) and when the component disappears from the page.
- Both `if (!ignore)` checks only update state when this effect's cleanup has **not** run yet.

Why is that needed? Imagine the user picks GBP and then, a moment later, JPY. Two requests are now on their way, and the internet does not promise that answers arrive in order. If the GBP answer arrives last, it would overwrite the JPY rate, and the page would show a pound rate next to the yen label. This is called a **race condition**. With the cleanup, choosing JPY sets `ignore = true` for the GBP effect, so its late answer is simply ignored. Only the answer for the current currency can update the state.

**The handler.** `handleCurrencyChange` stores the new currency and immediately switches to the loading state and clears any old error. Doing this in the handler, rather than at the start of the effect, follows the advice from Lesson 14's linter warning: update state from the event that caused the change.

**The display.** Exactly one of three paragraphs is shown:

- While loading: "Loading exchange rate...".
- After an error: the message in red, using the existing `form-error` class.
- After success: the converted amount. `toLocaleString` with `{ style: "currency", currency: currency }` formats a number as money in the chosen currency, with the right symbol, such as `€` or `£`. The `{" "}` adds a space between "about" and the bold amount: JSX removes line breaks between elements, so a space at the end of a line has to be written as an expression.

### Step 3: Show the Converter

Import the component in `src/App.jsx`:

```jsx
import CurrencyConverter from "./components/CurrencyConverter.jsx";
```

And place it right after `<Summary ... />`, passing the balance:

```jsx
<CurrencyConverter amount={totals.balance} />
```

Add the styles to the end of `src/App.css`:

```css
/* Currency converter */
.converter {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px 12px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 12px;
  padding: 12px 16px;
}

.converter select {
  padding: 6px 8px;
  font-size: 14px;
  font-family: inherit;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background-color: var(--color-surface);
}

.converter-result {
  flex-basis: 100%;
}

.converter-result small {
  color: var(--color-muted);
}
```

The converter is a white card like the others. `flex-wrap: wrap` together with `flex-basis: 100%` on the result puts the label and dropdown on the first line and the result on its own line below.

Save all files. For a moment you will see "Loading exchange rate...", then the result.

What you see in the converter:

```text
$3,223 is about €2,880.75 (1 USD = 0.89381 EUR)
```

Now choose IDR. The message switches to "Loading exchange rate..." while the new request runs, and then shows the result.

What you see in the converter:

```text
$3,223 is about IDR 58,536,126 (1 USD = 18162 IDR)
```

Your amounts will differ slightly, because the rates change daily. The converter also updates when the balance changes: delete a transaction, and the converted amount follows, without a new request, because `amount` is a prop used during rendering, not a dependency of the effect.

---

## 4. Run and Test

Test both features in the browser:

1. Open both category dropdowns and check that "Health" is listed.
2. Switch the converter between EUR, GBP, JPY, and IDR. Each switch briefly shows "Loading exchange rate..." and then the result with the right currency symbol.
3. Open the **Network** tab in the developer tools, then switch currencies. You can see each request to `api.frankfurter.dev` and its JSON response.
4. Simulate a lost connection: in the Network tab, change the throttling dropdown (it usually says "No throttling") to **Offline**, then switch the currency. The converter shows "Could not load the exchange rate: Failed to fetch". `Failed to fetch` is the browser's message when a request cannot be sent at all. Switch back to "No throttling" and choose another currency to recover.
5. Add a transaction and check that the converted amount changes with the balance.

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

## 5. Fetching Data in React

You have now written two data-fetching effects. Here are the general ideas behind them.

**Every request has three possible states.** Loading, success, and error. A good user interface shows something meaningful for each one: a loading message or spinner, the data, and a helpful error message. AI-generated code often handles only the success case, so the screen stays empty or crashes when the network is slow or offline. Whenever you review fetching code, look for all three.

**Always check `response.ok`.** `fetch` only rejects its promise when the request could not be made, for example without an internet connection. A `404 Not Found` or a `500 Internal Server Error` is still a "successful" fetch from its point of view. Throwing an error when `response.ok` is `false` sends those cases to your `catch` block.

**Never make the effect function itself async.** An `async` function always returns a promise, but an effect may only return nothing or a cleanup function. Declare an async function inside the effect and call it, as both effects in this lesson do.

**Clean up effects that can finish late.** Any effect whose work finishes after a delay, such as a request or a timer, can outlive the situation it was started for. The `ignore` flag is the simplest cleanup for requests. Effects that start something ongoing, such as an interval with `setInterval`, use their cleanup to stop it with `clearInterval`.

**APIs in the real world.** Frankfurter is unusually convenient: it needs no account, no API key, and allows requests from any website. Many APIs require a key, and some do not allow requests directly from the browser. Never put a secret API key in React code, because everything in a front-end app can be read by anyone who opens the developer tools. Real apps keep secret keys on a server.

**Beyond useEffect.** Fetching in effects is the foundation, and it is enough for Spendly. Larger apps often use a data-fetching library, such as TanStack Query, or a framework, such as Next.js, that handles caching, retries, and race conditions for you. You will meet them in AI-generated code, and the ideas from this lesson will help you understand what they do.

---

## 6. Fix the Errors in Your Code

These are the data-fetching mistakes you will meet most often, in your own code and in AI-generated code.

**Error 1: Requesting a file that does not exist.**

```jsx
// Wrong
const response = await fetch("/category.json");

// Correct
const response = await fetch("/categories.json");
```

With the wrong file name, Spendly shows the error banner:

```text
Could not load categories: Unexpected token '<', "<!doctype "... is not valid JSON
```

You might expect a "404 Not Found" message, but the error is about JSON. During development, Vite answers requests for unknown paths with the app's own `index.html` page and a `200` status, so `response.ok` is `true`. The body, however, starts with `<!doctype html>`, and `response.json()` fails at the first `<`. When you see `Unexpected token '<'` while parsing JSON, the server almost always sent an HTML page instead of data: check the URL. Notice also that the rest of Spendly keeps working, because the error was caught and turned into a message.

**Error 2: Skipping the response.ok check.**

To see this, temporarily add a currency code that does not exist, `EURO`, to the `currencies` array and choose it.

```jsx
// Wrong
const response = await fetch(`https://api.frankfurter.dev/v1/latest?base=USD&symbols=${currency}`);
const data = await response.json();

// Correct
const response = await fetch(`https://api.frankfurter.dev/v1/latest?base=USD&symbols=${currency}`);
if (!response.ok) {
  throw new Error(`Request failed with status ${response.status}`);
}
const data = await response.json();
```

The API answers an unknown currency with a `404` status and the body `{"message":"not found"}`. With the correct version, the converter shows a clear message:

```text
Could not load the exchange rate: Request failed with status 404
```

With the wrong version, the code continues as if the request succeeded, and fails one line later:

```text
Could not load the exchange rate: Cannot read properties of undefined (reading 'EURO')
```

The error body has no `rates` property, so `data.rates` is `undefined`, and reading `EURO` from it throws. The message is about a missing property, not about the failed request, which sends you looking in the wrong place. Remove `EURO` from the array when you are done.

**Error 3: Making the effect function async.**

```jsx
// Wrong
useEffect(async () => {
  try {
    const response = await fetch("/categories.json");
    if (!response.ok) {
      throw new Error(`Request failed with status ${response.status}`);
    }
    const data = await response.json();
    setCategories(data);
  } catch (error) {
    setCategoriesError(error.message);
  }
}, []);

// Correct
useEffect(() => {
  async function loadCategories() {
    try {
      const response = await fetch("/categories.json");
      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }
      const data = await response.json();
      setCategories(data);
    } catch (error) {
      setCategoriesError(error.message);
    }
  }

  loadCategories();
}, []);
```

The wrong version looks shorter, but it breaks the whole app. The console shows a long explanation from React, starting with:

```text
useEffect must not return anything besides a function, which is used for clean-up.
```

React even prints the correct pattern in the message. A moment later the page goes blank with `TypeError: destroy is not a function`: React tried to call the returned promise as a cleanup function. The linter warns about it as well:

```text
src/App.jsx:39:13: warning react-hooks(exhaustive-deps): Effect callbacks are synchronous to prevent race conditions. help: Consider putting the asynchronous code inside a function and calling it from the effect.
```

---

## 7. Exercises

**Exercise 1:** Show the date of the exchange rate. The API response contains a `date` property. Store it in a new piece of state named `rateDate`, and show it in the small text, such as `(1 USD = 0.89381 EUR, rates from 2026-10-26)`.

**Exercise 2:** Add a "Try again" button to the converter's error message. Clicking it should fetch the rate again for the same currency. Hint: add a `retryCount` state, include it in the effect's dependency array, and increase it in the button's handler.

**Exercise 3:** Instead of four fixed currencies, load the full list from `https://api.frankfurter.dev/v1/currencies`, which returns an object such as `{"AUD":"Australian Dollar","BRL":"Brazilian Real", ...}`. Show each option as `EUR - Euro`, and remove `USD` from the list, since Spendly's amounts are already in dollars. Start the state with `{ EUR: "Euro" }` so the dropdown is never empty.

---

## 8. Solutions

**Solution for Exercise 1:**

Add the state in `src/components/CurrencyConverter.jsx`:

```jsx
const [rateDate, setRateDate] = useState("");
```

Store the date next to the rate inside the effect:

```jsx
if (!ignore) {
  setRate(data.rates[currency]);
  setRateDate(data.date);
  setIsLoading(false);
}
```

And show it in the small text:

```jsx
<small>
  {" "}
  (1 USD = {rate} {currency}, rates from {rateDate})
</small>
```

The date comes from the same response as the rate, so it is stored at the same moment. Users can now see how fresh the number is.

What you see in the converter:

```text
$3,223 is about €2,880.75 (1 USD = 0.89381 EUR, rates from 2026-10-26)
```

**Solution for Exercise 2:**

Add the state and the handler:

```jsx
const [retryCount, setRetryCount] = useState(0);
```

```jsx
function handleRetry() {
  setIsLoading(true);
  setError("");
  setRetryCount(retryCount + 1);
}
```

Add `retryCount` to the effect's dependencies:

```jsx
}, [currency, retryCount]);
```

And add the button to the error message:

```jsx
{!isLoading && error && (
  <p className="converter-result form-error">
    Could not load the exchange rate: {error}{" "}
    <button type="button" className="button small-button" onClick={handleRetry}>
      Try again
    </button>
  </p>
)}
```

The effect does not use `retryCount` inside its code, but listing it as a dependency makes the effect run again whenever it changes. Increasing a counter is a simple way to say "please run this effect again". To test it, go offline in the Network tab, switch the currency, go back online, and click "Try again".

What you see in the converter before clicking "Try again":

```text
Could not load the exchange rate: Failed to fetch Try again
```

And after clicking it:

```text
$3,223 is about £2,414.67 (1 USD = 0.7492 GBP, rates from 2026-10-26)
```

**Solution for Exercise 3:**

Replace the fixed array with state, at the top of the component:

```jsx
const [currencies, setCurrencies] = useState({ EUR: "Euro" });
```

Add a second effect that loads the list once:

```jsx
useEffect(() => {
  async function loadCurrencies() {
    const response = await fetch("https://api.frankfurter.dev/v1/currencies");
    const data = await response.json();
    delete data.USD;
    setCurrencies(data);
  }

  loadCurrencies();
}, []);
```

And build the options from the object:

```jsx
{Object.entries(currencies).map(([code, name]) => (
  <option key={code} value={code}>
    {code} - {name}
  </option>
))}
```

`Object.entries` turns an object into an array of `[key, value]` pairs, such as `["EUR", "Euro"]`, so you can loop over it with `map`. The square brackets in `([code, name])` destructure each pair. `delete data.USD` removes the US dollar from the list before it is stored. Starting with `{ EUR: "Euro" }` keeps the selected value valid before the list arrives. When this lesson was written, the dropdown had 29 options, the first being `AUD - Australian Dollar`. For a real app you would also add `response.ok` checks and an error state to this effect, as in the other two.

---

## Next Up - Lesson 16

In this lesson Spendly started talking to the outside world. You loaded the categories from a JSON file in `public`, fetched live exchange rates from the Frankfurter API with `fetch`, `async`, and `await`, checked `response.ok`, and handled failures with `try...catch`. You showed loading, error, and success states, and you used an effect cleanup to ignore answers that arrive too late.

`App` and `CurrencyConverter` now contain several effects, and some of them follow the same pattern: load something, keep it in state, track loading and errors. In Lesson 16, you will learn how to move logic like that out of components and into your own **custom hooks**, such as `useLocalStorage` and `useFetch`, so that components stay short and the logic can be reused.
