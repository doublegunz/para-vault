## 1. Before You Begin

In Lesson 5, you built a reusable `TransactionItem` component and used it five times in `TransactionList`, passing each transaction's data as props. It works, but every row is still written by hand. A real Spendly user might have five transactions or five hundred, and you cannot type a tag for each one. The list should be generated from the data automatically.

In this lesson you will move Spendly's transactions into their own data file, pass the whole array down as a prop, and let React turn the array into list items with JavaScript's `map` method. You will learn why React asks for a `key` on every list item, and how to show different content depending on the data: a friendly message when the list is empty, the right singular or plural word, and a small badge on large transactions.

### What You'll Build

- A `src/data/transactions.js` file that holds Spendly's sample transactions in the shape you designed in Lesson 1.
- A `TransactionList` that renders one `TransactionItem` per transaction with `map`, whatever the length of the array.
- An empty state that says "No transactions yet. Add your first one to get started!" when there is nothing to show.
- A line that says "Showing 5 transactions", or "Showing 1 transaction" when there is only one.
- A "Large" badge next to any transaction of $1,000 or more.

### What You'll Learn

- ✅ How to keep app data in its own module and import it
- ✅ How to pass an array and an object as props
- ✅ How to turn an array into JSX elements with `map`
- ✅ What the `key` prop is, why React needs it, and what makes a good key
- ✅ How to render content conditionally with an early `return`, the ternary operator, and `&&`
- ✅ The `0 &&` trap and how to avoid it

### What You'll Need

- The Spendly project from Lesson 5
- The development server running with `npm run dev`

---

## 2. Move the Transactions into a Data File

Right now Spendly's data is scattered across five JSX tags. Data and display are easier to manage when they are separate: the data lives in one place, and components only decide how to show it. Later in the course the data will come from the browser's storage and from user input, but the components will not need to change, because they will still receive an array.

### Step 1: Create the Data File

Create a folder named `data` inside `src`, and inside it a file named `transactions.js`.

```javascript
export const sampleTransactions = [
  { id: 5, title: "Coffee with friends", amount: 12, type: "expense", category: "Food", date: "2026-10-09" },
  { id: 4, title: "Freelance design", amount: 400, type: "income", category: "Freelance", date: "2026-10-08" },
  { id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" },
];
```

Here is what this code does:

- `export const sampleTransactions = [...]` creates a named export holding an array of objects. These are the same five transactions you created in the console in Lesson 1, with the same six properties.
- The array is ordered newest first, so the most recent transaction appears at the top of the list. When users add new transactions later in the course, they will be placed at the front of the array, keeping that order.
- Each transaction has a unique `id`. Until now the `id` property had no job. In this lesson it gets an important one.

### Step 2: Pass the Array from App

Open `src/App.jsx`, import the data, and pass it to `TransactionList` as a prop.

```jsx
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";
import { sampleTransactions } from "./data/transactions.js";

function App() {
  return (
    <main className="app">
      <Header userName="Dina" />
      <Summary income={3400} expense={177} />
      <Filters />
      <TransactionList transactions={sampleTransactions} />
    </main>
  );
}

export default App;
```

Here is what changed:

- `import { sampleTransactions } from "./data/transactions.js";` loads the array with curly braces, because it is a named export.
- `<TransactionList transactions={sampleTransactions} />` passes the whole array as a prop called `transactions`. Arrays need curly braces, like numbers.

`App` is now the place where Spendly's data enters the component tree. In Module 3, this is where the data will start to change as users add and delete transactions. Do not save yet: `TransactionList` still ignores the prop, so the page would look the same. You will update it next.

---

## 3. Render the List with map

You already know the array method `map` from the JavaScript Basics course: it calls a function for every item in an array and collects the results in a new array. For example, `[1, 2, 3].map((n) => n * 2)` returns `[2, 4, 6]`. React adds one more piece: when you put an **array of JSX elements** inside curly braces, React renders every element in it. So `map` can turn an array of transaction objects into an array of `<TransactionItem />` elements.

### Step 1: Let TransactionItem Receive a Whole Transaction

Passing five separate props for every transaction was fine when you typed them by hand. Now that each transaction is an object, it is simpler to pass the object itself as one prop. Replace `src/components/TransactionItem.jsx` with this version.

```jsx
import { formatAmount } from "../utils/format.js";

function TransactionItem({ transaction }) {
  const { title, amount, type, category, date } = transaction;
  const sign = type === "income" ? "+" : "-";

  return (
    <li className="transaction-item">
      <div className="transaction-info">
        <span className="transaction-title">{title}</span>
        <span className="transaction-meta">
          {category} · {date}
        </span>
      </div>
      <span className="transaction-amount">
        {sign}
        {formatAmount(amount)}
      </span>
    </li>
  );
}

export default TransactionItem;
```

Here is what changed:

- The component now destructures a single prop, `transaction`, which holds the whole object.
- `const { title, amount, type, category, date } = transaction;` destructures the object's properties into variables inside the function. This is the same destructuring syntax you use in the parameter list, just on its own line.
- The JSX is unchanged, because the variables have the same names as before.

### Step 2: Map Over the Transactions

Replace `src/components/TransactionList.jsx` with this code.

```jsx
import TransactionItem from "./TransactionItem.jsx";

function TransactionList({ transactions }) {
  return (
    <section className="transactions">
      <h2>Transactions</h2>
      <ul>
        {transactions.map((transaction) => (
          <TransactionItem key={transaction.id} transaction={transaction} />
        ))}
      </ul>
    </section>
  );
}

export default TransactionList;
```

Here is what this code does:

- `function TransactionList({ transactions })` receives the array from `App`.
- `{transactions.map(...)}` runs inside curly braces, so its result, an array of elements, is placed inside the `<ul>`.
- The arrow function `(transaction) => ( ... )` is called once per transaction. The parentheses after `=>` wrap the JSX and **return it automatically**. This short form, with parentheses and no curly braces, is the most common way to write `map` in React.
- `<TransactionItem key={transaction.id} transaction={transaction} />` creates one row and passes the current object as the `transaction` prop.
- `key={transaction.id}` gives each row a unique identifier. `key` is a special attribute that React uses itself; it is not passed to `TransactionItem` as a prop. You will see why it matters in Section 5.

Save all three files (`App.jsx`, `TransactionItem.jsx`, and `TransactionList.jsx`).

What you see in the transactions section:

```text
Transactions
Coffee with friendsFood · 2026-10-09
-$12
Freelance designFreelance · 2026-10-08
+$400
Bus passTransport · 2026-10-05
-$45
GroceriesFood · 2026-10-03
-$120
Monthly salarySalary · 2026-10-01
+$3,000
```

The list looks exactly like Lesson 5, but `TransactionList` now has no idea how many transactions exist. Whatever array it receives, it renders. Add or remove objects in `transactions.js` and the list follows.

---

## 4. Show Content Conditionally

Real data is not always neat. A new Spendly user has no transactions at all, and an empty `<ul>` under a "Transactions" heading looks broken. React components often need to show different content depending on the data. Because components are JavaScript functions, you can use ordinary JavaScript to decide what to return. In this section you will use the three common techniques: an early `return`, the ternary operator, and the `&&` operator.

### Step 1: Show an Empty State with an Early Return

Update `src/components/TransactionList.jsx`.

```jsx
import TransactionItem from "./TransactionItem.jsx";

function TransactionList({ transactions }) {
  if (transactions.length === 0) {
    return (
      <section className="transactions">
        <h2>Transactions</h2>
        <p className="empty-state">No transactions yet. Add your first one to get started!</p>
      </section>
    );
  }

  return (
    <section className="transactions">
      <h2>Transactions</h2>
      <ul>
        {transactions.map((transaction) => (
          <TransactionItem key={transaction.id} transaction={transaction} />
        ))}
      </ul>
    </section>
  );
}

export default TransactionList;
```

Here is what this code does:

- `if (transactions.length === 0)` checks whether the array is empty. An `if` statement cannot go inside JSX curly braces, but it can go anywhere in the function body before the JSX.
- When the array is empty, the component returns the empty-state markup immediately. This is called an **early return**: the rest of the function never runs.
- When the array has items, the `if` is skipped and the second `return` renders the list as before.

Save the file. To see the empty state, temporarily change the prop in `App.jsx` to an empty array: `<TransactionList transactions={[]} />`. Save.

What you see in the transactions section:

```text
Transactions

No transactions yet. Add your first one to get started!
```

If you run the linter now, it warns that `sampleTransactions` is imported but never used, which is true while you are testing. Change the prop back to `transactions={sampleTransactions}` and save.

### Step 2: Choose Singular or Plural with a Ternary

It is helpful to tell users how many transactions they are looking at. Update `src/components/TransactionList.jsx` again.

```jsx
import TransactionItem from "./TransactionItem.jsx";

function TransactionList({ transactions }) {
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
          <TransactionItem key={transaction.id} transaction={transaction} />
        ))}
      </ul>
    </section>
  );
}

export default TransactionList;
```

Here is what is new:

- `const count = transactions.length;` stores the number of transactions in a short, readable name.
- `{count === 1 ? "transaction" : "transactions"}` picks the right word. A ternary is an expression, so it works inside JSX, unlike an `if` statement. Use it when you want to choose between two things.

Save the file.

What you see in the transactions section:

```text
Transactions

Showing 5 transactions

Coffee with friendsFood · 2026-10-09
-$12
Freelance designFreelance · 2026-10-08
+$400
Bus passTransport · 2026-10-05
-$45
GroceriesFood · 2026-10-03
-$120
Monthly salarySalary · 2026-10-01
+$3,000
```

To check the singular form, temporarily pass only the first transaction with `transactions={sampleTransactions.slice(0, 1)}`. `slice(0, 1)` returns a new array containing just the first item.

What you see in the transactions section:

```text
Transactions

Showing 1 transaction

Coffee with friendsFood · 2026-10-09
-$12
```

Change the prop back to `transactions={sampleTransactions}`.

### Step 3: Show a Badge with &&

Sometimes you want to show something or nothing, rather than choose between two things. For that, React code uses the `&&` operator. Update `src/components/TransactionItem.jsx` to add a "Large" badge to transactions of $1,000 or more.

```jsx
import { formatAmount } from "../utils/format.js";

function TransactionItem({ transaction }) {
  const { title, amount, type, category, date } = transaction;
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
      <span className="transaction-amount">
        {sign}
        {formatAmount(amount)}
      </span>
    </li>
  );
}

export default TransactionItem;
```

Here is how `{amount >= 1000 && <span className="badge">Large</span>}` works:

- In JavaScript, `a && b` returns `b` if `a` is truthy, and `a` otherwise.
- When `amount >= 1000` is `true`, the expression returns the `<span>` element, and React renders the badge.
- When it is `false`, the expression returns `false`, and React renders nothing for `false`, as you learned in Lesson 3.

Read it as "if the amount is at least 1,000, then show the badge". Save the file.

What you see in the last row:

```text
Monthly salaryLargeSalary · 2026-10-01
+$3,000
```

Only the salary is large enough to get the badge, and it currently sits right against the title. Lesson 7 will give it a proper style.

---

## 5. Run and Test

With the development server running, open `http://localhost:5173`.

What you see in the transactions section:

```text
Transactions

Showing 5 transactions

Coffee with friendsFood · 2026-10-09
-$12
Freelance designFreelance · 2026-10-08
+$400
Bus passTransport · 2026-10-05
-$45
GroceriesFood · 2026-10-03
-$120
Monthly salaryLargeSalary · 2026-10-01
+$3,000
```

Then check the console (`F12`, **Console** tab). It should show no red errors. Run the linter too.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

```

Finally, test that the list is driven by data: open `src/data/transactions.js`, delete the coffee transaction, and save. The list shrinks to four rows and the count says "Showing 4 transactions", without touching any component. Undo the deletion before moving on.

---

## 6. Why Keys Matter

You added `key={transaction.id}` to every row without seeing what it does. Here is the reason.

When the data changes, React does not throw away the whole list and rebuild it. It compares the new list of elements with the previous one and updates only what changed. That comparison is easy for a single element, but for a list it needs a way to know which item is which. Imagine the list `[Coffee, Groceries]`, and a new transaction, "Movie tickets", is added at the top: `[Movie tickets, Coffee, Groceries]`. Without keys, React compares by position: the first row used to be Coffee and is now Movie tickets, the second used to be Groceries and is now Coffee, and the third is new. It thinks every row changed.

With keys, React matches rows by their `key` instead. It sees that the rows with keys `5` and `2` still exist, only moved down, and that one row with a new key was added. It creates one new element and keeps the rest. This is faster, and more importantly it is correct: if a row contains something the user is interacting with, such as a checkbox or a text field being edited, that state stays with the right transaction.

A good key follows two rules:

- **Unique among its siblings.** Two items in the same list cannot share a key. Items in different lists can.
- **Stable.** The same item gets the same key every time the component renders.

A database or data id, like `transaction.id`, is ideal. The array index (`map((transaction, index) => ... key={index})`) is unique but not stable: when a transaction is added at the top, every index shifts, and React is back to matching by position. Use the index only for lists that never change order, never get items inserted, and never get items removed. Generating a random key, such as `key={Math.random()}`, is worse: every render produces new keys, so React recreates every row every time.

---

## 7. Fix the Errors in Your Code

These mistakes are among the most common in React code, including code generated by AI tools.

**Error 1: Forgetting the key.**

```jsx
// Wrong
{transactions.map((transaction) => (
  <TransactionItem transaction={transaction} />
))}

// Correct
{transactions.map((transaction) => (
  <TransactionItem key={transaction.id} transaction={transaction} />
))}
```

The wrong version still shows the list, so it is easy to miss. The console shows this error:

```text
Each child in a list should have a unique "key" prop.

Check the render method of `TransactionList`. See https://react.dev/link/warning-keys for more information.
```

React names the component that rendered the list, which tells you where to look. The linter catches it too. `npm run lint` prints:

```text
src/components/TransactionList.jsx:22:23: warning react(jsx-key): Missing "key" prop for element in iterator. help: Add a "key" prop to the element in the iterator (https://react.dev/learn/rendering-lists#keeping-list-items-in-order-with-key).
```

Add `key={transaction.id}` to the element returned from `map`. The key goes on the outermost element inside `map`, here `<TransactionItem />`, not on the `<li>` inside `TransactionItem`.

**Error 2: Using curly braces in the map callback without returning.**

An arrow function written with curly braces needs an explicit `return`. Without it, the function returns `undefined` for every item.

```jsx
// Wrong
{transactions.map((transaction) => {
  <TransactionItem key={transaction.id} transaction={transaction} />;
})}

// Correct
{transactions.map((transaction) => (
  <TransactionItem key={transaction.id} transaction={transaction} />
))}
```

There is no error and no warning, from React or from the linter. The list is simply empty.

What you see in the transactions section with the wrong version:

```text
Transactions

Showing 5 transactions
```

The count says 5, but no rows appear: `map` produced an array of five `undefined` values, and React renders `undefined` as nothing. Either switch to parentheses, which return automatically, or keep the curly braces and write `return <TransactionItem ... />;` inside them.

**Error 3: Using a number on the left side of &&.**

`&&` returns the left-hand value when it is falsy. `false` renders nothing, but the number `0` is rendered as text.

```jsx
// Wrong
{count && <p className="transaction-count">Showing {count} transactions</p>}

// Correct
{count > 0 && <p className="transaction-count">Showing {count} transactions</p>}
```

With the wrong version and an empty array, the page shows a stray zero.

What you see in the transactions section with the wrong version:

```text
Transactions
0
```

When `count` is `0`, the expression `0 && <p>...</p>` returns `0`, and React displays it. Always put a real true or false condition on the left of `&&`, such as `count > 0` or `transactions.length > 0`.

---

## 8. Exercises

**Exercise 1:** Without changing `TransactionList`, make the page show only expenses. Use the array method `filter` in `App.jsx` to pass a new array that contains only transactions whose `type` is `"expense"`.

**Exercise 2:** Add a sixth transaction to `src/data/transactions.js`: movie tickets that cost `30` on `2026-10-10`, in the category `Entertainment`, with the id `6`. Place it where it belongs in the newest-first order, and check that the count and list update.

**Exercise 3:** Rewrite `TransactionList` so that it uses a single `return` with a ternary operator inside the JSX to choose between the empty-state paragraph and the list, instead of an early return. You may drop the count line for this exercise.

---

## 9. Solutions

**Solution for Exercise 1:**

Change only the `TransactionList` line in `src/App.jsx`.

```jsx
<TransactionList transactions={sampleTransactions.filter((transaction) => transaction.type === "expense")} />
```

`filter` returns a new array containing only the items for which the function returns `true`. The original `sampleTransactions` array is not changed. `TransactionList` does not know or care that the array was filtered; it renders whatever it receives.

What you see in the transactions section:

```text
Transactions

Showing 3 transactions

Coffee with friendsFood · 2026-10-09
-$12
Bus passTransport · 2026-10-05
-$45
GroceriesFood · 2026-10-03
-$120
```

This is the basic idea behind Spendly's filters in Lesson 13. Change the prop back to `transactions={sampleTransactions}` afterward.

**Solution for Exercise 2:**

The newest transaction goes at the top of the array.

```javascript
export const sampleTransactions = [
  { id: 6, title: "Movie tickets", amount: 30, type: "expense", category: "Entertainment", date: "2026-10-10" },
  { id: 5, title: "Coffee with friends", amount: 12, type: "expense", category: "Food", date: "2026-10-09" },
  { id: 4, title: "Freelance design", amount: 400, type: "income", category: "Freelance", date: "2026-10-08" },
  { id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" },
];
```

The new object follows the same six-property shape, and its `id` of `6` is unique.

What you see in the transactions section:

```text
Transactions

Showing 6 transactions

Movie ticketsEntertainment · 2026-10-10
-$30
Coffee with friendsFood · 2026-10-09
-$12
Freelance designFreelance · 2026-10-08
+$400
Bus passTransport · 2026-10-05
-$45
GroceriesFood · 2026-10-03
-$120
Monthly salaryLargeSalary · 2026-10-01
+$3,000
```

Remove the movie tickets afterward, so the sample data matches the rest of the course.

**Solution for Exercise 3:**

```jsx
import TransactionItem from "./TransactionItem.jsx";

function TransactionList({ transactions }) {
  return (
    <section className="transactions">
      <h2>Transactions</h2>
      {transactions.length === 0 ? (
        <p className="empty-state">No transactions yet. Add your first one to get started!</p>
      ) : (
        <ul>
          {transactions.map((transaction) => (
            <TransactionItem key={transaction.id} transaction={transaction} />
          ))}
        </ul>
      )}
    </section>
  );
}

export default TransactionList;
```

The ternary chooses between two blocks of JSX, each wrapped in parentheses so that it can span several lines. The section and heading are written once, which removes the duplication from the early-return version. With the sample data, the list appears; with `transactions={[]}` in `App`, the section shows "No transactions yet. Add your first one to get started!".

Both styles are correct. An early return is easier to read when the special case is completely different from the normal output. An inline ternary is better when only a small part of the output changes. Restore the version from Section 4 before continuing, since the next lesson builds on it.

---

## Next Up - Lesson 7

In this lesson you moved Spendly's transactions into a data file, passed the array and its objects as props, and generated the list with `map`. You learned why each list item needs a unique, stable `key`, and you rendered content conditionally with an early return, a ternary, and `&&`, while avoiding the `0 &&` trap.

Spendly's components and data are now in good shape, but the page still looks like a plain document, with titles and categories squashed together. In Lesson 7, you will style Spendly with CSS: you will lay out the summary as cards, turn each transaction into a clean row, color income green and expenses red based on the data, and give the "Large" badge a proper look.
