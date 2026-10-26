## 1. Before You Begin

Over the last nineteen lessons, you built Spendly from an empty folder: components and props, state and events, forms, derived data, effects, custom hooks, routing, and context. You wrote every line yourself, and you understand why each one is there. That understanding is exactly what most people who "vibe code" with AI tools are missing, and it is what this module is about.

AI coding assistants are genuinely useful. They can write a new component in seconds, suggest a solution you had not thought of, or explain an unfamiliar piece of code. But they write code based on patterns, not on your project. They guess at your file names, your helpers, and your conventions, and they sometimes produce code that looks right and is subtly wrong. In this lesson you will practice the workflow that makes AI help safe: write a clear prompt for a new Spendly feature, read the code that comes back line by line, map every part to a concept you already know, check it against your project, and only then add it to the app.

### What You'll Build

A **Spending by category** card on the Dashboard. It lists each expense category with its total, its share of all expenses, and a red bar showing that share, sorted from the largest category to the smallest. With the sample data, it shows Food at $132 (75%) and Transport at $45 (25%). The component is an example of the kind of code an AI assistant returns for the prompt in this lesson.

### What You'll Learn

- ✅ How to write a prompt that gives an AI assistant the context it needs
- ✅ A step-by-step method for reading unfamiliar React code
- ✅ How to recognize components, props, state, effects, hooks, and context in someone else's code
- ✅ What `reduce` and `useMemo` do, two tools AI-generated code uses often
- ✅ How to check generated code against your project's conventions and edge cases
- ✅ How to diagnose the integration errors that appear when generated code meets a real project

### What You'll Need

- The Spendly project from Lesson 19
- The development server running with `npm run dev`
- Optional: access to an AI coding assistant, such as Claude, ChatGPT, GitHub Copilot, or the assistant built into your editor. You can follow the whole lesson without one, using the example response provided.

---

## 2. Write a Clear Prompt

An AI assistant only knows what you tell it. A prompt like "add a category chart to my app" leaves it to guess everything: which framework, which files, what the data looks like, how the result should be styled. Every guess is a chance for a mistake. A good prompt answers those questions up front. It has three parts: the **context**, the **task**, and the **constraints**.

### Step 1: Describe the Project Context

Start by describing the project as if to a new teammate: the tools, the relevant files, and the shape of the data. For Spendly, that looks like this:

```text
I'm building Spendly, a personal expense tracker, with React 19 and Vite, written in
JavaScript (not TypeScript), with React Router 8 and plain CSS. Imports from React Router
come from "react-router".

Transactions are stored in a React context. Any component can read them with:
  import { useTransactions } from "../hooks/useTransactions.js";
  const { transactions } = useTransactions();

Each transaction looks like this:
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" }
"amount" is always a positive number, and "type" is either "income" or "expense".

To display money, I use this helper:
  import { formatAmount } from "../utils/format.js";
  formatAmount(132) returns "$132"
```

Each line removes a guess. The assistant now knows not to write TypeScript, which package to import routing from, where the data comes from, what the data looks like, and which helper to use for money, so it does not invent a new one.

### Step 2: Describe the Task

Next, describe exactly what you want, including what it should look like and where it goes:

```text
Please create a component named CategoryBreakdown in src/components/CategoryBreakdown.jsx.
It should show a card titled "Spending by category" with one row per expense category:
the category name, the total amount, and the percentage of all expenses, plus a horizontal
bar whose width is that percentage. Sort the rows from the largest total to the smallest.
Ignore income transactions. I will add it to src/pages/DashboardPage.jsx myself.
```

The task names the file and the component, describes the result precisely, and says what to ignore. It also says what you will do yourself, so the assistant does not rewrite other files.

### Step 3: State the Constraints

Finally, list the rules the code must follow, and ask for an explanation:

```text
Requirements:
- Read the transactions from useTransactions(), not from props.
- Use plain CSS class names (no Tailwind, no CSS-in-JS libraries), and give me the CSS separately.
- Do not add any new npm packages.
- Show a short message if there are no expenses yet.
- Explain any part of the code that uses something beyond useState, useEffect, and array methods.
```

The last line is important: asking for an explanation makes the assistant point out the parts you are most likely not to know, which tells you where to read carefully.

Combine the three parts into one message, in this order: context, task, constraints. If you have an AI assistant, send it now. Its answer will be different from the example in the next section, because AI tools produce different code each time, but it should have a similar structure. Compare the two as you read.

---

## 3. Read the Response

Here is an example of the kind of response an assistant returns for this prompt. It was written for this lesson to match what assistants typically produce, so that everyone can follow along with the same code.

```jsx
import { useMemo } from "react";
import { useTransactions } from "../hooks/useTransactions.js";
import { formatAmount } from "../utils/format.js";

function CategoryBreakdown() {
  const { transactions } = useTransactions();

  const categoryTotals = useMemo(() => {
    const totals = transactions
      .filter((transaction) => transaction.type === "expense")
      .reduce((result, transaction) => {
        result[transaction.category] = (result[transaction.category] ?? 0) + transaction.amount;
        return result;
      }, {});

    return Object.entries(totals)
      .map(([category, total]) => ({ category, total }))
      .sort((a, b) => b.total - a.total);
  }, [transactions]);

  const totalExpense = categoryTotals.reduce((sum, item) => sum + item.total, 0);

  if (categoryTotals.length === 0) {
    return (
      <section className="breakdown">
        <h2>Spending by category</h2>
        <p className="empty-state">No expenses yet.</p>
      </section>
    );
  }

  return (
    <section className="breakdown">
      <h2>Spending by category</h2>
      <ul className="breakdown-list">
        {categoryTotals.map(({ category, total }) => {
          const percent = Math.round((total / totalExpense) * 100);
          return (
            <li key={category} className="breakdown-item">
              <div className="breakdown-row">
                <span>{category}</span>
                <span>
                  {formatAmount(total)} ({percent}%)
                </span>
              </div>
              <div className="breakdown-bar">
                <div className="breakdown-bar-fill" style={{ width: `${percent}%` }} />
              </div>
            </li>
          );
        })}
      </ul>
    </section>
  );
}

export default CategoryBreakdown;
```

Do not copy it into your project yet. A good habit is to read generated code **before** running it, in a fixed order: the edges first (imports and the component's inputs), then the logic in the middle, then the JSX at the bottom.

### Step 1: Read the Imports and the Inputs

Start at the top. Imports tell you what the code depends on, and the first lines of the component tell you what data it uses.

| Line | What it is | Where you learned it |
| --- | --- | --- |
| `import { useMemo } from "react";` | A React hook you have not used yet | New, explained in Step 2 |
| `import { useTransactions } from "../hooks/useTransactions.js";` | Your own context hook | Lesson 19 |
| `import { formatAmount } from "../utils/format.js";` | Your own helper | Lessons 5 and 10 |
| `function CategoryBreakdown() {` | A component with no props | Lesson 4 |
| `const { transactions } = useTransactions();` | Reading the context, with destructuring | Lesson 19 |

This is reassuring. Every import points to a file that exists in Spendly, the component reads its data from the context as the prompt asked, and there is only one unfamiliar name, `useMemo`. If an import pointed to a file or package you do not have, that would be the first thing to fix, as you will see in the Fix the Errors section.

### Step 2: Read the Calculation

The middle of the component calculates the totals per category. It uses two tools that appear in AI-generated code all the time: `reduce` and `useMemo`.

**`useMemo`** is a React hook that remembers the result of a calculation between renders. It takes a function and a dependency array, just like `useEffect`. It runs the function on the first render, and afterwards only when a dependency changes; otherwise it returns the remembered result. Here, the totals are recalculated only when `transactions` changes. The important thing to recognize is that `categoryTotals` is still **derived data**, as in Lesson 13. `useMemo` is only a performance optimization: if you removed it and calculated the totals directly, the component would show exactly the same result. For a few transactions it makes no visible difference, which is why Spendly has not needed it so far. Assistants add it often, sometimes where it is not needed.

**`reduce`** is an array method that combines all items of an array into a single value. It takes a function and a starting value. The function receives the result so far (here called `result`) and the current item, and returns the new result. Here, the starting value is an empty object `{}`, and each expense adds its amount to the property named after its category. The `??` operator from Lesson 11 makes a category that has not been seen yet start at `0`.

You do not have to take the explanation on trust. Paste this experiment into the browser console. It is the same calculation, with a `console.log` added inside `reduce` so you can watch it work.

```javascript
const transactions = [
  { id: 5, title: "Coffee with friends", amount: 12, type: "expense", category: "Food", date: "2026-10-09" },
  { id: 4, title: "Freelance design", amount: 400, type: "income", category: "Freelance", date: "2026-10-08" },
  { id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" },
];

const totals = transactions
  .filter((transaction) => transaction.type === "expense")
  .reduce((result, transaction) => {
    result[transaction.category] = (result[transaction.category] ?? 0) + transaction.amount;
    console.log(`After ${transaction.title}:`, JSON.stringify(result));
    return result;
  }, {});

const categoryTotals = Object.entries(totals)
  .map(([category, total]) => ({ category, total }))
  .sort((a, b) => b.total - a.total);

console.log(JSON.stringify(Object.entries(totals)));
console.log(JSON.stringify(categoryTotals));
```

Output in the console:

```text
After Coffee with friends: {"Food":12}
After Bus pass: {"Food":12,"Transport":45}
After Groceries: {"Food":132,"Transport":45}
[["Food",132],["Transport",45]]
[{"category":"Food","total":132},{"category":"Transport","total":45}]
```

Now every line of the calculation is clear:

- `filter` keeps only the expenses (Lesson 6), so the salary and the freelance income never reach `reduce`.
- `reduce` builds `{ Food: 132, Transport: 45 }`, one property per category.
- `Object.entries(totals)` turns that object into an array of `[key, value]` pairs (Lesson 15, Exercise 3).
- `.map(([category, total]) => ({ category, total }))` destructures each pair and turns it into an object. The parentheses around `{ category, total }` are needed so that JavaScript reads the braces as an object, not as a function body.
- `.sort((a, b) => b.total - a.total)` sorts by total, largest first. Subtracting two numbers is the usual way to sort numbers; for the dates in Lesson 13 you used `localeCompare` because they were strings.

One more detail is worth noticing. The function inside `reduce` changes `result` directly with `result[...] = ...`, which looks like the mutation you were warned about in Lessons 9 and 11. Here it is safe: `result` is a brand-new object created by `reduce` from `{}`, not React state, and it never escapes until it is complete. The rule is "never mutate **state**", not "never mutate anything". Recognizing the difference is part of reading code well.

Finally, `totalExpense` uses `reduce` again, this time with a starting value of `0`, to add up all the category totals.

### Step 3: Read the JSX

The bottom half is ordinary JSX, built from patterns you have used many times:

- `if (categoryTotals.length === 0) { return ...; }` is an early return for the empty state (Lesson 6). The prompt asked for it, and the assistant delivered it.
- `categoryTotals.map(({ category, total }) => { ... })` renders one `<li>` per category. This arrow function uses curly braces, so it has an explicit `return`, which is correct (Lesson 6, Error 2). The braces are needed because it calculates `percent` before returning the JSX.
- `key={category}` uses the category name as the key. Category names are unique within this list, so they are good keys (Lesson 6).
- `{formatAmount(total)} ({percent}%)` formats the money with your helper.
- `style={{ width: `${percent}%` }}` sets the bar's width with an inline style, including the `%` unit (Lesson 7, Error 3). It is the same technique as the spending bar in `Summary`.

You have now read every line, and none of it is a mystery: every part maps to something you learned, plus two new tools that you verified yourself.

---

## 4. Check It Against Your Project

Reading tells you what the code does. Before using it, you also need to know whether it does the **right** thing for **your** app. Go through these questions. Most bugs in generated code are found here, not by the computer.

### Step 1: Check the Conventions

Does the code follow the way Spendly is written?

- It imports from files that exist, with the `.js` and `.jsx` extensions Spendly uses. Yes.
- It reads data with `useTransactions()`, not props. Yes, as requested.
- It formats money with `formatAmount` instead of inventing a new formatter. Yes.
- It uses plain CSS class names, and no new packages. Yes.
- It is written in JavaScript with function components, double quotes, and semicolons, like the rest of Spendly. Yes.

When a convention is broken, fix it before integrating the code, even if the code works. A project where every file follows different conventions becomes hard to read, for you and for the next AI prompt.

### Step 2: Check the Edge Cases

Ask "what if?" about unusual data:

- **What if there are no expenses?** `categoryTotals` is empty, and the early return shows "No expenses yet." Good. Without that check, `totalExpense` would be `0`, and `total / totalExpense` would divide by zero.
- **What if there is only income?** Same as above, because income is filtered out first.
- **What if there is only one category?** It gets 100%. Good.
- **Do the percentages always add up to 100?** Not always. Each one is rounded separately, so three categories of exactly one third each would show 33% three times. For a dashboard card that is acceptable, but it is the kind of detail you should notice and decide on consciously.
- **Does it update when data changes?** `useMemo` depends on `[transactions]`, and every add, edit, and delete creates a new array, so yes.

The code passes. Now you can add it to Spendly with confidence.

---

## 5. Add the Feature to Spendly

### Step 1: Create the Component

Create `src/components/CategoryBreakdown.jsx` and paste the component from Section 3 into it, exactly as shown.

### Step 2: Show It on the Dashboard

Open `src/pages/DashboardPage.jsx`, import the component, and place it after the currency converter.

```jsx
import CategoryBreakdown from "../components/CategoryBreakdown.jsx";
```

```jsx
<CurrencyConverter amount={totals.balance} />
<CategoryBreakdown />
```

`<CategoryBreakdown />` has no props, because the component reads the transactions from the context itself.

### Step 3: Add the Styles

Add the CSS for the new card to the end of `src/App.css`. This is the CSS the prompt asked for, using Spendly's existing color variables.

```css
/* Category breakdown */
.breakdown {
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 12px;
  padding: 16px;
}

.breakdown-list {
  list-style: none;
  margin: 12px 0 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.breakdown-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 4px;
}

.breakdown-bar {
  height: 8px;
  background-color: var(--color-border);
  border-radius: 999px;
  overflow: hidden;
}

.breakdown-bar-fill {
  height: 100%;
  background-color: var(--color-expense);
}
```

The card matches the other white cards on the Dashboard, each row puts the category on the left and the amount on the right, and the bar is the same track-and-fill design as the spending bar, in the expense color.

---

## 6. Run and Test

Save all files and open the Dashboard. If you have changed the data in earlier lessons, delete the `spendly-transactions` key in the Application tab and refresh to start from the sample data.

What you see in the new card:

```text
Spending by category
Food
$132 (75%)
Transport
$45 (25%)
```

The Food bar fills three quarters of its track, and the Transport bar one quarter; in the Elements panel their styles are `width: 75%;` and `width: 25%;`. Now add an expense titled `Cinema`, amount `30`, category Entertainment, and return to the Dashboard.

What you see in the card:

```text
Spending by category
Food
$132 (64%)
Transport
$45 (22%)
Entertainment
$30 (14%)
```

The new category appears, the percentages are recalculated from the new total of $207, and the rows stay sorted. The context makes the new card update with every change, just like the rest of the Dashboard.

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

## 7. A Method for Reading Any Code

The process you followed works for any code you did not write: from an AI assistant, a tutorial, a library's documentation, or a teammate.

1. **Write a prompt with context, task, and constraints.** The more the assistant knows about your project, the less it guesses.
2. **Read the edges first.** Imports show dependencies; the first lines of a component show its inputs (props, context, URL parameters). Check that every import exists in your project.
3. **Read the logic in the middle.** Find the state, the derived values, and the effects. For any unfamiliar function, look it up, or test it in the console with sample data, as you did with `reduce`.
4. **Read the JSX last.** Look for the patterns you know: `map` with keys, conditional rendering, event handlers, and class names.
5. **Check conventions and edge cases.** Does it fit your project? What happens with empty, single, or unusual data?
6. **Integrate in small steps, then test.** Add the component, run the app, and compare the result with what you expected from reading.

It helps to keep a short list of questions in mind while reading React code:

| Question | Where to look |
| --- | --- |
| Where does the data come from? | Props, `useState`, context hooks, `useParams`, `useFetch` |
| What can change? | Every `useState` and every setter call |
| What is calculated from other values? | Variables computed in the component body, `useMemo` |
| What touches the outside world? | `useEffect`, `fetch`, `localStorage`, `document` |
| What happens on user actions? | `onClick`, `onChange`, `onSubmit` handlers |

If you can answer these five questions about a component, you understand it well enough to change it, fix it, or decide not to use it.

---

## 8. Fix the Errors in Your Code

When generated code meets a real project, the first errors are usually about **connections**: imports, names, and props that the assistant guessed. Here are three common ones, each produced by changing one line of `CategoryBreakdown`.

**Error 1: Importing from a package you do not have.**

Assistants trained on older code often import routing tools from `react-router-dom`.

```jsx
// Wrong
import { Link } from "react-router-dom";

// Correct
import { Link } from "react-router";
```

The wrong version stops the whole app. The browser shows Vite's error overlay:

```text
[plugin:vite:import-analysis] Failed to resolve import "react-router-dom" from "src/components/CategoryBreakdown.jsx". Does the file exist?
```

"Failed to resolve import" means the package or file does not exist in your project. Do not install packages just because generated code imports them. First check whether you already have an equivalent; here, `react-router` already provides everything, as you learned in Lesson 17. This is why the prompt in this lesson named the package explicitly.

**Error 2: Using a helper that does not exist.**

Assistants often invent a plausible helper name instead of the one you have.

```jsx
// Wrong
import { formatCurrency } from "../utils/format.js";

// Correct
import { formatAmount } from "../utils/format.js";
```

With the wrong version (and `formatCurrency(total)` in the JSX), the page goes blank, and the console shows:

```text
SyntaxError: The requested module '/src/utils/format.js' does not provide an export named 'formatCurrency'
```

The file exists, but it has no export with that name. Open the file to see what it does export, and use that. You met the same message in Lesson 4, when an export was missing. Giving the assistant your helper's exact name and import line in the prompt prevents this.

**Error 3: Expecting props that are never passed.**

Without the context information in the prompt, an assistant has to guess how the component gets its data, and props are the most common guess.

```jsx
// Wrong
function CategoryBreakdown({ transactions }) {

// Correct
function CategoryBreakdown() {
  const { transactions } = useTransactions();
```

The Dashboard renders `<CategoryBreakdown />` with no props, so with the wrong version `transactions` is `undefined`. The page goes blank, and the console shows:

```text
TypeError: Cannot read properties of undefined (reading 'filter')
```

The error points at `.filter`, but the real cause is the component's inputs. Whenever generated code crashes on a value that is `undefined`, compare what the component **expects** (its parameters and hooks) with what your app **gives** it (the props on its tag). You could also fix this by passing the data from the Dashboard; the important thing is that both sides agree.

---

## 9. Exercises

**Exercise 1:** Before running anything, read the component and predict what the card shows if every expense is deleted and only income remains. Then test your prediction: delete "Coffee with friends", "Bus pass", and "Groceries", and look at the Dashboard.

**Exercise 2:** Change the component so that it shows only the three largest categories, followed by a line such as `Other categories: $18` that adds up the rest. Show the line only when there are more than three categories. Use `slice` and `reduce`.

**Exercise 3:** Write a complete prompt, with context, task, and constraints, asking an AI assistant to add a **month filter** to the Transactions page: a dropdown listing the months that have transactions, such as "October 2026", which limits the list to the chosen month. You do not need to implement it.

---

## 10. Solutions

**Solution for Exercise 1:**

Reading the code: `filter` keeps only expenses, so with no expenses `categoryTotals` is an empty array, and the early return shows the empty state. That is exactly what happens.

What you see in the card:

```text
Spending by category

No expenses yet.
```

Predicting the result before running the code is the best way to check that you really understood it. When the app surprises you, either the code or your understanding was wrong, and finding out which is how you learn.

**Solution for Exercise 2:**

Add two derived values after `totalExpense`:

```jsx
const topCategories = categoryTotals.slice(0, 3);
const otherTotal = categoryTotals.slice(3).reduce((sum, item) => sum + item.total, 0);
```

Map over `topCategories` instead of `categoryTotals`:

```jsx
{topCategories.map(({ category, total }) => {
```

And add the summary line after the closing `</ul>`:

```jsx
{otherTotal > 0 && <p className="spending-text">Other categories: {formatAmount(otherTotal)}</p>}
```

`slice(0, 3)` takes the first three categories, which are the largest because the array is already sorted. `slice(3)` takes everything after them, and `reduce` adds up their totals. The percentages still use `totalExpense`, so they stay relative to all expenses. With a $30 cinema ticket (Entertainment) and an $18 pharmacy purchase (Health) added to the sample data, the card shows:

```text
Spending by category
Food
$132 (59%)
Transport
$45 (20%)
Entertainment
$30 (13%)

Other categories: $18
```

**Solution for Exercise 3:**

Here is one possible prompt. Yours will be worded differently, but it should contain the same kinds of information.

```text
Context:
I'm building Spendly, a personal expense tracker, with React 19 and Vite, in JavaScript
(not TypeScript), with React Router 8 (imported from "react-router") and plain CSS.
Transactions come from a context:
  import { useTransactions } from "../hooks/useTransactions.js";
  const { transactions } = useTransactions();
Each transaction looks like:
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" }
The date is always a "YYYY-MM-DD" string.

Task:
In src/pages/TransactionsPage.jsx, the visible list is calculated like this:
  const visibleTransactions = sortByNewest(
    transactions
      .filter((transaction) => category === "All" || transaction.category === category)
      .filter((transaction) => transaction.title.toLowerCase().includes(search.toLowerCase())),
  );
Add a month filter: a new piece of state "month" (default "All"), and a dropdown in
src/components/Filters.jsx that lists "All months" plus every month that has at least one
transaction, newest first, labeled like "October 2026", with values like "2026-10".
Combine it with the existing category and search filters.

Constraints:
- Keep the existing props and code style (function components, double quotes, semicolons).
- Derive the list of months from the transactions; do not store it in state.
- Do not add any npm packages.
- Show me the full updated versions of both files, and explain any new JavaScript you use.
```

It gives the stack, the data shape, the exact existing code to change, the expected labels and values, and the rules from earlier lessons, such as deriving data instead of storing it. When the answer comes back, you would read it with the method from Section 7.

---

## Next Up - Lesson 21

In this lesson you practiced the workflow that makes AI coding tools safe to use. You wrote a prompt with context, task, and constraints, read an AI-style component from the imports to the JSX, verified the unfamiliar `reduce` logic in the console, learned what `useMemo` does, checked the code against Spendly's conventions and edge cases, and added a Spending by category card to the Dashboard. You also saw the integration errors that appear when generated code guesses wrong about your project.

The component in this lesson was correct. Generated code often is not. In Lesson 21, you will review an AI-generated feature that contains real bugs, the kinds that AI tools produce most often: missing keys, mutated state, an effect that never stops running, and stale state. You will find each one with a review checklist, and fix it with what you have learned.
