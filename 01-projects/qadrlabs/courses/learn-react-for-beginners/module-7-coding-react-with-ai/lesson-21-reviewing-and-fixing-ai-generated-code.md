## 1. Before You Begin

In Lesson 20, you asked an AI assistant for a new Spendly feature, read the code line by line, checked it against the project, and added a Spending by category card to the Dashboard. That code was correct. In real projects, generated code often is not, and the bugs are rarely obvious. The code compiles, the page appears, and the problem only shows up when someone types a number, clicks a button twice, or watches the console.

This lesson is a code review. You will add an AI-style **Budgets** page to Spendly, where users set a monthly budget for each spending category and see how much they have spent. The code contains four of the most common bugs in AI-generated React code: an effect that never stops running, a list without keys, state that is changed in place, and stale state. You will review the code with a checklist, use the linter and the browser as your assistants, and fix each bug with a concept you already know. Every bug in this lesson is one you have met before, in Lessons 6, 9, 11, 13, and 14. This time you will find them in code you did not write.

### What You'll Build

A **Budgets** page at `/budgets`, linked from the navigation bar. It lists four categories, each with a number input for the monthly budget and a line such as `$132 of $100`. A red banner such as `Over budget: Food` appears when spending passes a budget, and a "Quick setup" button sets every budget to $200. Budgets are saved in `localStorage`. By the end of the lesson, every part of the page works.

### What You'll Learn

- ✅ A review checklist for AI-generated React code
- ✅ How to use the linter as a first reviewer, and what it cannot catch
- ✅ How to recognize and fix an effect that loops forever
- ✅ How to recognize and fix missing keys
- ✅ How to recognize and fix mutated state
- ✅ How to recognize and fix stale state
- ✅ Why some "fixes" only hide the problem

### What You'll Need

- The Spendly project from Lesson 20
- The development server running with `npm run dev`, and the browser console open

---

## 2. Add the AI-Generated Budgets Page

Suppose you sent an assistant a prompt like the one in Lesson 20: Spendly's stack and data shape, the `useTransactions` and `useLocalStorage` hooks and the `formatAmount` helper, and a task: "Create a Budgets page that lists Food, Transport, Shopping, and Entertainment with a budget input for each, shows how much was spent against the budget, shows a banner listing the categories that are over budget, and has a Quick setup button that sets every budget to $200. Save the budgets in localStorage." Here is the kind of code that comes back. It was written for this lesson to reproduce typical mistakes.

### Step 1: Create the Page

Create `src/pages/BudgetsPage.jsx` with the generated code, exactly as shown. Read it once before moving on, and see whether you can already spot anything suspicious.

```jsx
import { useEffect, useState } from "react";
import { useTransactions } from "../hooks/useTransactions.js";
import { useLocalStorage } from "../hooks/useLocalStorage.js";
import { formatAmount } from "../utils/format.js";

const budgetCategories = ["Food", "Transport", "Shopping", "Entertainment"];

function BudgetsPage() {
  const { transactions } = useTransactions();
  const [budgets, setBudgets] = useLocalStorage("spendly-budgets", {});
  const [overBudget, setOverBudget] = useState([]);

  const rows = budgetCategories.map((category) => {
    const spent = transactions
      .filter((transaction) => transaction.type === "expense" && transaction.category === category)
      .reduce((sum, transaction) => sum + transaction.amount, 0);
    return { category, spent, budget: budgets[category] ?? 0 };
  });

  useEffect(() => {
    setOverBudget(rows.filter((row) => row.budget > 0 && row.spent > row.budget));
  }, [rows]);

  function handleBudgetChange(category, value) {
    budgets[category] = Number(value);
    setBudgets(budgets);
  }

  function handleQuickSetup() {
    for (const category of budgetCategories) {
      setBudgets({ ...budgets, [category]: 200 });
    }
  }

  return (
    <section className="panel budgets">
      <h2 className="page-title">Monthly budgets</h2>
      {overBudget.length > 0 && (
        <p className="error-banner">Over budget: {overBudget.map((row) => row.category).join(", ")}</p>
      )}
      <button type="button" className="button" onClick={handleQuickSetup}>
        Quick setup: $200 for every category
      </button>
      <ul className="budget-list">
        {rows.map((row) => (
          <li className="budget-item">
            <label htmlFor={`budget-${row.category}`}>{row.category}</label>
            <input
              id={`budget-${row.category}`}
              type="number"
              min="0"
              value={row.budget}
              onChange={(event) => handleBudgetChange(row.category, event.target.value)}
            />
            <span className={row.budget > 0 && row.spent > row.budget ? "expense" : ""}>
              {formatAmount(row.spent)} of {formatAmount(row.budget)}
            </span>
          </li>
        ))}
      </ul>
    </section>
  );
}

export default BudgetsPage;
```

At first glance, the code looks reasonable. It reads the transactions from the context, stores the budgets with your own hook, uses `formatAmount`, and has clear names. The structure follows everything the prompt asked for. That is exactly why bugs like these get through: the code **looks** like good React.

### Step 2: Add the Route, the Link, and the Styles

To review the page in the browser, connect it to the app. In `src/App.jsx`, import the page and add a route after the `add` route:

```jsx
import BudgetsPage from "./pages/BudgetsPage.jsx";
```

```jsx
<Route path="budgets" element={<BudgetsPage />} />
```

In `src/components/Header.jsx`, add a link before "+ Add":

```jsx
<NavLink to="/budgets">Budgets</NavLink>
```

And add the styles to the end of `src/App.css`:

```css
/* Budgets */
.budgets {
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: flex-start;
}

.budget-list {
  list-style: none;
  margin: 0;
  padding: 0;
  width: 100%;
}

.budget-item {
  display: grid;
  grid-template-columns: 140px 120px 1fr;
  align-items: center;
  gap: 12px;
  padding: 10px 0;
  border-top: 1px solid var(--color-border);
}

.budget-item input {
  padding: 6px 8px;
  font-size: 16px;
  font-family: inherit;
  border: 1px solid var(--color-border);
  border-radius: 8px;
}
```

Each budget row is a three-column grid: the category name, the input, and the spending line. Do not save `App.jsx` yet. First, review.

---

## 3. Review Before You Run

A review has two halves: what tools can tell you, and what only you can tell. Start with the tools, because they are fast.

### Step 1: Run the Linter

Run the linter in a second terminal.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

src/pages/BudgetsPage.jsx:25:5: warning react(immutability): This value cannot be modified help: Modifying a value returned from a hook is not allowed. Consider moving the modification into the hook where the value is constructed
src/pages/BudgetsPage.jsx:21:5: warning react(set-state-in-effect): Calling setState synchronously within an effect can trigger cascading renders help: Effects should synchronize React with external systems. Calling setState synchronously inside an effect starts another render and is usually unnecessary. Derive the value during render, initialize state directly, or update it from the event that caused the change. Use an effect only when synchronizing with an external system.
src/pages/BudgetsPage.jsx:45:15: warning react(jsx-key): Missing "key" prop for element in iterator. help: Add a "key" prop to the element in the iterator (https://react.dev/learn/rendering-lists#keeping-list-items-in-order-with-key).
```

Three warnings, each pointing at a line:

- **Line 25** changes `budgets`, a value returned from a hook. That is state being mutated.
- **Line 21** calls `setOverBudget` inside an effect, and the help text even suggests the fix: "Derive the value during render".
- **Line 45** is a `<li>` in a `map` without a `key`.

The linter already found three of the four bugs, before you ran a single line. Always run it on generated code. But a clean linter does not mean correct code: the fourth bug is invisible to it, as you will see.

### Step 2: Open the Page

Save `App.jsx` and click "Budgets" in the navigation bar. The page appears, with four rows showing `$132 of $0`, `$45 of $0`, `$0 of $0`, and `$0 of $0`. It looks fine. Now look at the console. It is flooded with the same error, repeated over and over:

```text
Maximum update depth exceeded. This can happen when a component calls setState inside useEffect, but useEffect either doesn't have a dependency array, or one of the dependencies changes on every render.
```

There is also a warning about keys:

```text
Each child in a list should have a unique "key" prop.

Check the render method of `BudgetsPage`. See https://react.dev/link/warning-keys for more information.
```

An app that floods the console like this keeps the browser busy, drains laptop batteries, and can freeze slower devices. This is the most urgent bug, so it comes first.

---

## 4. Fix the Bugs One at a Time

Fix one bug, check the result, then move to the next. Changing several things at once makes it hard to tell which change fixed what, or what broke.

### Step 1: Fix the Effect That Never Stops

Here is the loop, step by step:

1. Every render creates `rows` with `map`, which returns a **new array** every time.
2. The effect depends on `[rows]`. Because `rows` is a new array after every render, React always sees a changed dependency and runs the effect.
3. The effect calls `setOverBudget` with the result of `filter`, which is also a new array.
4. Setting state causes a render, which goes back to step 1.

You met this loop in Lesson 14. But look more closely at what the effect does: it calculates `overBudget` from `rows`. That is **derived data** (Lesson 13), and derived data does not need state or an effect at all. It can be calculated directly during rendering. Remove `useEffect` and `useState` from the React import (the import line disappears completely, because nothing else from React is used), delete the `overBudget` state line, and replace the effect with one line:

```jsx
const overBudget = rows.filter((row) => row.budget > 0 && row.spent > row.budget);
```

That one line replaces a `useState`, a `useEffect`, and a bug. `overBudget` is now always in sync with `rows`, because it is calculated from it on every render. Save the file. The console no longer fills with errors; only the key warning remains.

### Step 2: Add the Missing Key

Each row needs a unique, stable key. The category name is unique in this list and never changes, so it is a good key (Lesson 6).

```jsx
<li key={row.category} className="budget-item">
```

Save the file. The key warning is gone from the console, and the linter now reports only the line 21 warning (the line numbers shifted after the previous fix).

### Step 3: Fix the Mutated State

With a clean console, it is time to actually use the page. Type `100` into the Food budget.

What happens in the browser:

```text
Food budget input: 0
localStorage "spendly-budgets": {}
```

The input refuses to change. It is a controlled input showing `row.budget`, and the screen never re-renders after you type. Here is why:

```jsx
budgets[category] = Number(value);
setBudgets(budgets);
```

The first line changes the existing state object. The second line hands React the **same object** it already has, so React sees no change, skips the re-render, and the `useLocalStorage` effect never saves anything. This is the same bug as `push` in Lesson 9 and `splice` in Lesson 11, with an object instead of an array. The fix is to create a new object with the spread syntax:

```jsx
function handleBudgetChange(category, value) {
  setBudgets({ ...budgets, [category]: Number(value) });
}
```

`{ ...budgets }` copies every existing budget into a new object. `[category]: Number(value)` is a **computed property name**: the square brackets mean "use the value of the variable `category` as the property name", so when `category` is `"Food"`, it sets the `Food` property. Because the property comes after the spread, it replaces the old value.

Save the file and type `100` into the Food budget again.

What happens in the browser:

```text
Food budget input: 100
localStorage "spendly-budgets": {"Food":100}
```

The input updates, and the budget is saved. Food spending is $132 against a $100 budget, so the red banner `Over budget: Food` appears, and the Food row's spending line turns red. This also proves that the derived `overBudget` from Step 1 updates correctly.

### Step 4: Fix the Stale State

Now click "Quick setup: $200 for every category". Every budget should become 200.

What happens in the browser:

```text
Inputs: Food=100, Transport=0, Shopping=0, Entertainment=200
localStorage "spendly-budgets": {"Food":100,"Entertainment":200}
```

Only the last category, Entertainment, was set. This is the bug the linter could not see:

```jsx
for (const category of budgetCategories) {
  setBudgets({ ...budgets, [category]: 200 });
}
```

The loop calls `setBudgets` four times, but `budgets` in this render never changes: every call copies the **same old object** and sets one category. Each call replaces the previous one, and only the last survives. This is the stale state bug from Lesson 9, Error 3. There are two good fixes. One is the updater function you learned then: `setBudgets((current) => ({ ...current, [category]: 200 }))`. The other, often clearer, is to build the complete new object first and set state once:

```jsx
function handleQuickSetup() {
  const newBudgets = { ...budgets };
  for (const category of budgetCategories) {
    newBudgets[category] = 200;
  }
  setBudgets(newBudgets);
}
```

`newBudgets` is a fresh copy, so changing its properties inside the loop is safe, just like the `result` object inside `reduce` in Lesson 20. When the loop is done, one `setBudgets` call stores the finished object. Save the file and click "Quick setup" again.

What happens in the browser:

```text
Inputs: Food=200, Transport=200, Shopping=200, Entertainment=200
localStorage "spendly-budgets": {"Food":200,"Transport":200,"Shopping":200,"Entertainment":200}
```

Every category is set, and because Food's $132 is now under its $200 budget, the banner disappears.

### Step 5: Read the Fixed Page

Here is the complete reviewed version of `src/pages/BudgetsPage.jsx`.

```jsx
import { useTransactions } from "../hooks/useTransactions.js";
import { useLocalStorage } from "../hooks/useLocalStorage.js";
import { formatAmount } from "../utils/format.js";

const budgetCategories = ["Food", "Transport", "Shopping", "Entertainment"];

function BudgetsPage() {
  const { transactions } = useTransactions();
  const [budgets, setBudgets] = useLocalStorage("spendly-budgets", {});

  const rows = budgetCategories.map((category) => {
    const spent = transactions
      .filter((transaction) => transaction.type === "expense" && transaction.category === category)
      .reduce((sum, transaction) => sum + transaction.amount, 0);
    return { category, spent, budget: budgets[category] ?? 0 };
  });

  const overBudget = rows.filter((row) => row.budget > 0 && row.spent > row.budget);

  function handleBudgetChange(category, value) {
    setBudgets({ ...budgets, [category]: Number(value) });
  }

  function handleQuickSetup() {
    const newBudgets = { ...budgets };
    for (const category of budgetCategories) {
      newBudgets[category] = 200;
    }
    setBudgets(newBudgets);
  }

  return (
    <section className="panel budgets">
      <h2 className="page-title">Monthly budgets</h2>
      {overBudget.length > 0 && (
        <p className="error-banner">Over budget: {overBudget.map((row) => row.category).join(", ")}</p>
      )}
      <button type="button" className="button" onClick={handleQuickSetup}>
        Quick setup: $200 for every category
      </button>
      <ul className="budget-list">
        {rows.map((row) => (
          <li key={row.category} className="budget-item">
            <label htmlFor={`budget-${row.category}`}>{row.category}</label>
            <input
              id={`budget-${row.category}`}
              type="number"
              min="0"
              value={row.budget}
              onChange={(event) => handleBudgetChange(row.category, event.target.value)}
            />
            <span className={row.budget > 0 && row.spent > row.budget ? "expense" : ""}>
              {formatAmount(row.spent)} of {formatAmount(row.budget)}
            </span>
          </li>
        ))}
      </ul>
    </section>
  );
}

export default BudgetsPage;
```

It is shorter than the generated version: one piece of state instead of two, and no effect. Fixing bugs in AI-generated code often makes it simpler, because many of its bugs come from doing more than necessary.

---

## 5. Run and Test

Start from a clean state: in the Application tab, delete the `spendly-budgets` key, then refresh the Budgets page.

1. The console shows no errors or warnings.
2. Type `100` in the Food budget. The input updates, the banner says `Over budget: Food`, and the Food line reads `$132 of $100` in red.

What you see on the page:

```text
Monthly budgets

Over budget: Food

Quick setup: $200 for every category
Food
$132 of $100
Transport
$45 of $0
Shopping
$0 of $0
Entertainment
$0 of $0
```

3. Click "Quick setup". All four inputs show 200, and the banner disappears.

What you see on the page:

```text
Monthly budgets
Quick setup: $200 for every category
Food
$132 of $200
Transport
$45 of $200
Shopping
$0 of $200
Entertainment
$0 of $200
```

4. Refresh the page. The budgets are still 200, loaded from `localStorage`.
5. Add a $90 Food expense on the Add page and return to Budgets. Food spending becomes $222, over its $200 budget, so the banner returns. The page reacts to the transactions as well as to its own state.

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

## 6. The AI Code Review Checklist

Here is the checklist used in this lesson, extended into one you can apply to any AI-generated React code. Go through it before you accept generated code into your project.

| Check | What to look for | Where you learned it |
| --- | --- | --- |
| Run the linter | Every warning, especially hooks, keys, and immutability | Lessons 2, 9, 14 |
| Imports | Every import exists; the right package names (`react-router`, not `react-router-dom`) | Lessons 17, 20 |
| Inputs | Props, context, and URL parameters match what the app actually provides | Lessons 5, 19, 20 |
| Lists | Every `map` that returns JSX has a unique, stable `key` | Lesson 6 |
| State updates | No `push`, `splice`, `sort`, or property assignment on state; new arrays and objects instead | Lessons 9, 11 |
| Multiple updates | Several `setX` calls from the same value; use an updater function or build the value once | Lesson 9 |
| Derived data | State that only copies or calculates from other state; replace it with a variable | Lesson 13 |
| Effects | Every effect has a dependency array; no `setState` that triggers the effect again; async work has cleanup | Lessons 14, 15 |
| Form inputs | Every controlled input has `value` and `onChange`; numbers are converted with `Number` | Lesson 10 |
| Edge cases | Empty lists, zero, missing items, slow or failed requests | Lessons 6, 15, 18 |
| Behavior | Try it: type, click twice, refresh, go back. Watch the console | Every lesson |

Two lessons from this review are worth remembering:

- **The linter is a strong first reviewer.** It found three of four bugs in seconds. Read its help text: it often contains the fix.
- **Only testing finds behavior bugs.** The stale state bug compiled cleanly, passed the linter, and rendered correctly. It only appeared when the button was clicked. Always use the feature the way a user would before calling it done.

And the most important one: **you can only review what you understand.** Every bug in this lesson was found by recognizing a pattern from an earlier lesson. That understanding is the difference between using AI tools and depending on them.

---

## 7. Fix the Errors in Your Code

When fixing bugs, it is tempting to make the warning go away instead of fixing the cause. These "fixes" are common, including in AI suggestions, and each one hides the bug instead of removing it.

**Error 1: Silencing the effect loop with an empty dependency array.**

```jsx
// Wrong
useEffect(() => {
  setOverBudget(rows.filter((row) => row.budget > 0 && row.spent > row.budget));
}, []);

// Correct
const overBudget = rows.filter((row) => row.budget > 0 && row.spent > row.budget);
```

The wrong version stops the loop, because the effect now runs only once. But it also stops updating. Type `100` in the Food budget (with the mutation bug already fixed): the Food line turns red and reads `$132 of $100`, yet the banner never appears.

What you see at the top of the page:

```text
Monthly budgets | Quick setup: $200 for every category | Food | $132 of $100
```

The effect calculated `overBudget` once, from the first render, when no budgets were set, and never again. The linter still complains, now with a second warning:

```text
src/pages/BudgetsPage.jsx:21:19: warning react-hooks(exhaustive-deps): React Hook useEffect has a missing dependency: 'rows' help: Either include it or remove the dependency array.
```

An empty array is only correct when the effect truly uses nothing that changes. Here, the right fix was to remove the effect, because the value was derived data all along.

**Error 2: Silencing the key warning with a random key.**

```jsx
// Wrong
<li key={Math.random()} className="budget-item">

// Correct
<li key={row.category} className="budget-item">
```

The wrong version removes the console warning, but try typing in a budget input. After the first character, the cursor disappears from the input, and you have to click it again for every digit.

Focused element before and after typing one character:

```text
Before: budget-Food
After:  BODY
```

Every render generates new random keys, so React thinks every row is a brand-new item. It throws away the old `<li>` elements, including the input you were typing in, and creates new ones. The new input does not have focus, so focus falls back to the page body. With the stable `row.category` key, the input keeps its focus. The linter flags the random key too:

```text
src/pages/BudgetsPage.jsx:43:20: warning react(purity): Cannot call impure function during render help: `Math.random` is an impure function. Calling an impure function can produce unstable results that update unpredictably when the component re-renders
```

**Error 3: Turning the linter off.**

Linters can be silenced with comments such as `// oxlint-disable-next-line`, and AI assistants sometimes add them to make warnings disappear.

```jsx
// Wrong
// oxlint-disable-next-line
budgets[category] = Number(value);
setBudgets(budgets);

// Correct
setBudgets({ ...budgets, [category]: Number(value) });
```

The comment removes the warning from the linter output, and nothing else: the input still refuses to change. A disable comment is an admission that a rule does not apply, and that is very rarely true for React's hook and state rules. When you see one in generated code, treat it as a warning sign and look for the problem it is hiding.

---

## 8. Exercises

**Exercise 1:** An assistant suggests this "Reset budgets" handler. Without running it, find the bug, explain what the user sees, and fix it.

```jsx
function handleReset() {
  Object.keys(budgets).forEach((key) => delete budgets[key]);
  setBudgets(budgets);
}
```

**Exercise 2:** The page uses a hard-coded list of four categories, but Spendly loads its categories from `categories.json` (Lesson 15). Change the page to use the categories from `useTransactions()`, without the income categories `Salary` and `Freelance`.

**Exercise 3:** Add a fourth column to each row that shows how much is left, such as `$35 left`, or how much the budget is exceeded by, such as `$32 over`. Show it only when a budget is set. Update the grid to have four columns.

---

## 9. Solutions

**Solution for Exercise 1:**

The handler mutates the state object with `delete`, then passes the same object to `setBudgets`. React sees no change, so nothing re-renders and nothing is saved. The user clicks "Reset budgets" and nothing happens: with a Food budget of 100, the input still shows `100`, and `localStorage` still contains `{"Food":100}`. Interestingly, the linter does not catch this one, because the mutation happens inside a callback. The fix is to set a new, empty object:

```jsx
function handleReset() {
  setBudgets({});
}
```

Add a button for it, for example `<button type="button" className="button delete-button" onClick={handleReset}>Reset budgets</button>`. After clicking it, every input shows `0`, and `localStorage` contains `{}`. The correct version is also much shorter, which is common: immutable updates usually describe the result directly instead of the steps.

**Solution for Exercise 2:**

Replace the `budgetCategories` constant with a list of income categories, and derive the budget categories from the context inside the component:

```jsx
const incomeCategories = ["Salary", "Freelance"];
```

```jsx
const { transactions, categories } = useTransactions();
const budgetCategories = categories.filter((category) => !incomeCategories.includes(category));
```

`includes` checks whether an array contains a value, and `!` reverses it, so only categories that are not income are kept. `handleQuickSetup` still works, because it reads the same `budgetCategories` variable, now derived. The page now lists:

```text
Food, Transport, Shopping, Bills, Entertainment, Health, Other
```

If you add a category to `categories.json`, it appears on the Budgets page automatically.

**Solution for Exercise 3:**

Add a fourth element to each row, after the spending line:

```jsx
{row.budget > 0 && (
  <span className="budget-remaining">
    {row.spent <= row.budget
      ? `${formatAmount(row.budget - row.spent)} left`
      : `${formatAmount(row.spent - row.budget)} over`}
  </span>
)}
```

And change the grid in `src/App.css`:

```css
grid-template-columns: 140px 120px 1fr auto;
```

The value is derived from the row, like everything else on the page. With a Food budget of 100 and a Transport budget of 80, the first two rows read:

```text
Food $132 of $100 $32 over || Transport $45 of $80 $35 left
```

`auto` makes the last column only as wide as its content, so the text sits at the right edge of the row.

---

## Next Up - Lesson 22

In this lesson you reviewed an AI-generated feature like a professional. The linter found three of the four bugs; the browser found the fourth. You fixed an effect loop by turning state into derived data, added stable keys, replaced a mutation with a new object, and fixed stale state by building the new value once. You also saw why silencing warnings with empty dependency arrays, random keys, or disable comments only hides problems, and you now have a checklist for every piece of generated code you meet. That completes Module 7.

Spendly is now a complete app. In Lesson 22, the final lesson, you will build it for production with `npm run build`, preview the result, look at what Vite produces, review the concepts behind every feature you built, and plan your next steps as a React developer.
