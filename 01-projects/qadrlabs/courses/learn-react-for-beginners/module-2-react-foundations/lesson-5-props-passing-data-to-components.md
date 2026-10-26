## 1. Before You Begin

In Lesson 4, you split Spendly into four components: `Header`, `Summary`, `Filters`, and `TransactionList`. The code is much tidier, but the components are rigid. `Header` always greets Dina, `Summary` always shows the same three numbers, and every row in `TransactionList` is typed out by hand. If you wanted a second summary for last month, or a sixth transaction, you would have to copy and edit markup.

This lesson fixes that with **props**, short for properties. Props are how a parent component passes data to a child component, in the same way that attributes pass information to an HTML element. With props, one component can show different data each time it is used. You will pass the user's name to `Header`, pass the totals to `Summary`, and build a reusable `TransactionItem` component that displays whichever transaction it receives.

### What You'll Build

- A `Header` that greets whichever name it receives, and falls back to "Guest" when no name is given.
- A `Summary` that displays the income and expense it receives and calculates the balance.
- A `formatAmount` helper that formats amounts like `$3,400` and `-$250`.
- A new `TransactionItem` component that displays one transaction, used five times in `TransactionList` with different data.

### What You'll Learn

- ✅ What props are and how data flows from parent to child
- ✅ How to pass props as JSX attributes, including strings and numbers
- ✅ How to read props with destructuring in the function parameters
- ✅ How to give a prop a default value
- ✅ Why props are read-only
- ✅ How the special `children` prop works
- ✅ How to share a helper function between components with a named export

### What You'll Need

- The Spendly project from Lesson 4
- The development server running with `npm run dev`

---

## 2. Pass Your First Prop

You already know how to pass information to an HTML element: `<img src="/favicon.svg" alt="Spendly logo" />`. The `src` and `alt` attributes tell the `img` element what to show. Props work exactly the same way for your own components. You write them as attributes on the component's tag, and React collects them into one object that it passes to the component function as its first argument.

### Step 1: Send the User Name to Header

Open `src/components/Header.jsx` and replace its contents with this code.

```jsx
function Header({ userName }) {
  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <p>Welcome back, {userName}!</p>
    </header>
  );
}

export default Header;
```

Here is what changed:

- The function now has a parameter: `{ userName }`. React calls `Header` with a single object containing all of its props, for example `{ userName: "Dina" }`. The curly braces in the parameter are **destructuring**: they take the `userName` property out of that object and put it in a variable with the same name.
- The line `const userName = "Dina";` is gone. The component no longer decides who to greet; whoever uses `Header` decides.
- `{userName}` in the JSX works exactly as before, because `userName` is still a normal variable.

Now open `src/App.jsx` and pass the name as an attribute.

```jsx
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";

function App() {
  return (
    <main className="app">
      <Header userName="Dina" />
      <Summary />
      <Filters />
      <TransactionList />
    </main>
  );
}

export default App;
```

The only change is `<Header userName="Dina" />`. The attribute name, `userName`, must match the name the component destructures. Save both files and check the top of the page.

What you see in the browser:

```text
Spendly

Welcome back, Dina!
```

The page looks the same as before, but the data now flows from `App` down into `Header`. Change `"Dina"` to your own name in `App.jsx` and save: the greeting follows. Then change it back.

### Step 2: Give the Prop a Default Value

What happens if `App` forgets to pass the name? Temporarily change the tag in `App.jsx` to `<Header />` and save.

What you see in the browser:

```text
Spendly

Welcome back, !
```

The prop was never passed, so `userName` is `undefined`, and React renders `undefined` as nothing. You can protect against this with a **default value**, written with `=` inside the destructuring. Update `src/components/Header.jsx`.

```jsx
function Header({ userName = "Guest" }) {
  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <p>Welcome back, {userName}!</p>
    </header>
  );
}

export default Header;
```

`{ userName = "Guest" }` means "use the `userName` prop if it was passed, otherwise use `"Guest"`". This is the same default-value syntax JavaScript uses for function parameters. Save the file while `App.jsx` still has `<Header />`.

What you see in the browser:

```text
Spendly

Welcome back, Guest!
```

Now put the prop back in `App.jsx` so the tag reads `<Header userName="Dina" />` again, and save. The greeting returns to "Welcome back, Dina!", because a passed prop always wins over the default.

---

## 3. Make Summary Reusable

`Summary` holds its own numbers, so it can only ever show one month. In this section you will move the numbers out of the component and pass them in as props. You will also create a small helper that formats amounts consistently, because `$3400` is harder to read than `$3,400`.

### Step 1: Create the formatAmount Helper

Several components will need to display money, so the formatting logic belongs in one shared place. Create a new folder `src/utils` and inside it a file named `format.js`. If you completed Exercise 3 in Lesson 4, the file already exists; replace its contents with this improved version.

```javascript
export function formatAmount(amount) {
  const sign = amount < 0 ? "-" : "";
  return `${sign}$${Math.abs(amount).toLocaleString("en-US")}`;
}
```

Here is what this code does:

- `export function formatAmount(amount)` creates a **named export**, so other files can import it by name with curly braces.
- `const sign = amount < 0 ? "-" : "";` remembers whether the amount is negative. Negative amounts get a minus sign; positive amounts get an empty string.
- `Math.abs(amount)` removes the minus sign from the number itself, so the result is always positive.
- `.toLocaleString("en-US")` turns the number into text with thousands separators, so `3400` becomes `"3,400"`.
- The template literal puts the pieces together: the sign, then a dollar sign, then the formatted number. A balance of `-250` becomes `"-$250"` instead of the odd-looking `"$-250"` you saw in Lesson 3.

This file uses the `.js` extension, not `.jsx`, because it contains no JSX.

### Step 2: Pass Income and Expense to Summary

Replace `src/components/Summary.jsx` with this code.

```jsx
import { formatAmount } from "../utils/format.js";

function Summary({ income, expense }) {
  const balance = income - expense;

  return (
    <section className="summary">
      <h2>Summary</h2>
      <p>Income: {formatAmount(income)}</p>
      <p>Expense: {formatAmount(expense)}</p>
      <p>Balance: {formatAmount(balance)}</p>
    </section>
  );
}

export default Summary;
```

Here is what this code does:

- `import { formatAmount } from "../utils/format.js";` brings in the helper. The `../` goes up from `src/components` to `src`, then into `utils`.
- `function Summary({ income, expense })` destructures two props instead of declaring the numbers inside the component.
- `const balance = income - expense;` is still calculated inside `Summary`. The balance depends entirely on the other two values, so there is no reason to pass it in as a third prop.
- Each amount is displayed with `formatAmount(...)` instead of a hand-written dollar sign.

Then update the `Summary` tag in `src/App.jsx`.

```jsx
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";

function App() {
  return (
    <main className="app">
      <Header userName="Dina" />
      <Summary income={3400} expense={177} />
      <Filters />
      <TransactionList />
    </main>
  );
}

export default App;
```

Notice the difference between the two kinds of prop values:

- `userName="Dina"` uses quotes, which always pass a **string**.
- `income={3400}` uses curly braces, which pass a JavaScript value, here the **number** `3400`. If you wrote `income="3400"`, `Summary` would receive the text `"3400"`. Use curly braces for numbers, booleans, arrays, objects, and variables.

Save both files.

What you see in the browser:

```text
Summary

Income: $3,400

Expense: $177

Balance: $3,223
```

The amounts now have thousands separators, and `Summary` can show any month you give it.

---

## 4. Build a Reusable TransactionItem

The best use of props is a component that appears many times with different data. Each row in the transaction list has the same structure: a title, a category, a date, and a signed amount. Only the values change. That is a perfect job for one component.

### Step 1: Create the TransactionItem Component

Create `src/components/TransactionItem.jsx` with this code.

```jsx
import { formatAmount } from "../utils/format.js";

function TransactionItem({ title, amount, type, category, date }) {
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

Here is what this code does:

- The component receives five props, one for each property of a transaction except `id`, which is not displayed.
- `const sign = type === "income" ? "+" : "-";` is the same logic you wrote in the console in Lesson 1. Amounts are always positive in Spendly's data, and `type` decides the sign.
- The `<li>` contains two parts. The `transaction-info` block holds the title and a "meta" line with the category and date, separated by a middle dot (`·`). The `transaction-amount` span holds the signed, formatted amount.
- `{sign}` and `{formatAmount(amount)}` sit next to each other, so a `-` followed by `$120` displays as `-$120`.
- The class names do nothing yet. In Lesson 7 you will use them to lay out each row neatly.

### Step 2: Use TransactionItem in the List

Replace `src/components/TransactionList.jsx` so that it uses the new component for every row.

```jsx
import TransactionItem from "./TransactionItem.jsx";

function TransactionList() {
  return (
    <section className="transactions">
      <h2>Transactions</h2>
      <ul>
        <TransactionItem title="Coffee with friends" amount={12} type="expense" category="Food" date="2026-10-09" />
        <TransactionItem title="Freelance design" amount={400} type="income" category="Freelance" date="2026-10-08" />
        <TransactionItem title="Bus pass" amount={45} type="expense" category="Transport" date="2026-10-05" />
        <TransactionItem title="Groceries" amount={120} type="expense" category="Food" date="2026-10-03" />
        <TransactionItem title="Monthly salary" amount={3000} type="income" category="Salary" date="2026-10-01" />
      </ul>
    </section>
  );
}

export default TransactionList;
```

Here is what this code does:

- `import TransactionItem from "./TransactionItem.jsx";` uses `./` because both files are in the same `components` folder.
- Each `<TransactionItem ... />` passes one transaction's data as props. Text values use quotes, and `amount` uses curly braces so that it arrives as a number.
- The five rows share one component. If you want to change how every row looks, you change `TransactionItem.jsx` once.

Save both files.

What you see in the browser:

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

The title and the category run together, as in "Coffee with friendsFood". That is not a bug in your component: `<span>` elements sit side by side on the same line, and there is no CSS yet to separate them. Each `<div>` starts a new line, which is why the amount appears below. Lesson 7 turns each row into a tidy layout with the title on top, the category and date underneath, and the amount on the right.

---

## 5. Run and Test

Open `http://localhost:5173` with the development server running.

What you see in the browser:

```text
Spendly

Welcome back, Dina!

Summary

Income: $3,400

Expense: $177

Balance: $3,223

Search transactions
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

Now test that the data really flows through props:

- In `App.jsx`, change `expense={177}` to `expense={3650}` and save. The summary shows `Expense: $3,650` and `Balance: -$250`, with the minus sign in front of the dollar sign thanks to `formatAmount`. Change it back to `177`.
- In `TransactionList.jsx`, change the coffee's `type="expense"` to `type="income"` and save. The row's amount changes from `-$12` to `+$12`. Change it back.

Run the linter as a final check.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

```

---

## 6. How Props Work

You have used props in three components. Here are the ideas behind them, collected in one place.

**Data flows one way, from parent to child.** `App` passes `userName` to `Header`, and `TransactionList` passes transaction data to `TransactionItem`. A child can read its props, but it cannot send data back up through them. This one-way flow makes React apps predictable: to find out where a value comes from, you look at the parent. (In Lesson 8 you will see how a child can ask its parent to do something, by calling a function that the parent passed down as a prop.)

**Props are read-only.** A component must never change its own props. Think of props like the arguments to a function: `formatAmount(3400)` should not change the number `3400` that was passed in. React even enforces this during development, as you will see in the Fix the Errors section. When a component needs data that changes over time, it uses **state** instead, which you will learn in Lesson 9.

**Destructuring is a shortcut.** These two versions of a component are identical:

```jsx
function Header(props) {
  return <p>Welcome back, {props.userName}!</p>;
}

function Header({ userName }) {
  return <p>Welcome back, {userName}!</p>;
}
```

The first receives the whole props object and reads `props.userName`. The second destructures `userName` directly in the parameter list. Most React code, including code written by AI assistants, uses the second style because it shows at a glance which props a component expects. Notice also that when a component returns a single element on one line, the parentheses around the JSX are optional.

**Any value can be a prop.** Strings, numbers, booleans, arrays, objects, and even functions can be passed. Strings can use quotes; everything else needs curly braces.

**`children` is a special prop.** So far, every component has been self-closing, like `<Header />`. A component can also wrap content, like an HTML element does: `<Card>...</Card>`. Whatever you put between the opening and closing tags arrives in a prop named `children`. You will try this in Exercise 3, and you will use it in Lesson 17 to build a shared page layout.

---

## 7. Fix the Errors in Your Code

These are the mistakes beginners make most often with props.

**Error 1: Forgetting the curly braces around the props.**

Without destructuring braces, the parameter receives the whole props object, not the single value.

```jsx
// Wrong
function Header(userName) {
  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <p>Welcome back, {userName}!</p>
    </header>
  );
}

export default Header;

// Correct
function Header({ userName = "Guest" }) {
  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <p>Welcome back, {userName}!</p>
    </header>
  );
}

export default Header;
```

In the wrong version, the variable named `userName` actually holds the object `{ userName: "Dina" }`. Putting that object in JSX makes the page go blank, and the console shows the error you met in Lesson 3:

```text
Error: Objects are not valid as a React child (found: object with keys {userName}). If you meant to render a collection of children, use an array instead.
```

The message helpfully lists `{userName}` as the object's keys, which tells you that you have the props object instead of the prop. Add the curly braces to destructure it.

**Error 2: Passing a prop under a different name.**

The attribute name in the parent and the destructured name in the child must match exactly, including capital letters.

```jsx
// Wrong
<Header name="Dina" />

// Correct
<Header userName="Dina" />
```

This mistake does not produce any error. `Header` receives a prop called `name`, which it never reads, and `userName` falls back to its default value.

What you see in the browser with the wrong version:

```text
Spendly

Welcome back, Guest!
```

When a component shows a default value or nothing where you expected data, compare the prop name in the parent with the name the child destructures. AI-generated code often has exactly this kind of mismatch when two components were generated separately.

**Error 3: Changing a prop inside the component.**

It is tempting to adjust a prop before displaying it, for example to make the name uppercase, by assigning to it.

```jsx
// Wrong
function Header(props) {
  props.userName = props.userName.toUpperCase();

  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <p>Welcome back, {props.userName}!</p>
    </header>
  );
}

export default Header;

// Correct
function Header({ userName = "Guest" }) {
  const displayName = userName.toUpperCase();

  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <p>Welcome back, {displayName}!</p>
    </header>
  );
}

export default Header;
```

In development, React freezes the props object, so the wrong version crashes. The page goes blank and the console shows:

```text
TypeError: Cannot assign to read only property 'userName' of object '#<Object>'
```

Props belong to the parent. To show a changed version of a prop, store the result in a new variable, such as `displayName`, and leave the prop itself untouched.

---

## 8. Exercises

**Exercise 1:** Add an optional `title` prop to `Summary`, with the default value `"Summary"`, and display it in the `<h2>`. Then use two summaries in `App`: one titled `"October 2026"` with income `3400` and expense `177`, and one titled `"September 2026"` with income `3000` and expense `3250`.

**Exercise 2:** Add a second prop to `Header` named `month`, with the default value `"this month"`, and show it in a new paragraph: `Here is your summary for October 2026.` Check what the paragraph says both with and without passing `month="October 2026"` from `App`.

**Exercise 3:** Create a `Card` component in `src/components/Card.jsx` that receives a `title` prop and the special `children` prop, and returns a `<div className="card">` containing an `<h3 className="card-title">` with the title, followed by the children. Use three cards in `Summary`, one each for income, expense, and balance. In the balance card, add a `<small>Income minus expense</small>` note under the amount.

---

## 9. Solutions

**Solution for Exercise 1:**

Update `src/components/Summary.jsx`.

```jsx
import { formatAmount } from "../utils/format.js";

function Summary({ title = "Summary", income, expense }) {
  const balance = income - expense;

  return (
    <section className="summary">
      <h2>{title}</h2>
      <p>Income: {formatAmount(income)}</p>
      <p>Expense: {formatAmount(expense)}</p>
      <p>Balance: {formatAmount(balance)}</p>
    </section>
  );
}

export default Summary;
```

Then use two summaries in `src/App.jsx`.

```jsx
import Header from "./components/Header.jsx";
import Summary from "./components/Summary.jsx";
import Filters from "./components/Filters.jsx";
import TransactionList from "./components/TransactionList.jsx";

function App() {
  return (
    <main className="app">
      <Header userName="Dina" />
      <Summary title="October 2026" income={3400} expense={177} />
      <Summary title="September 2026" income={3000} expense={3250} />
      <Filters />
      <TransactionList />
    </main>
  );
}

export default App;
```

`title = "Summary"` gives the new prop a default, so any `<Summary />` that does not pass a title still shows "Summary". The two tags reuse the same component with different data.

What you see in the two summary sections:

```text
October 2026

Income: $3,400

Expense: $177

Balance: $3,223

September 2026

Income: $3,000

Expense: $3,250

Balance: -$250
```

September's balance is negative, and `formatAmount` displays it as `-$250`. Remove the September summary and the title prop from `App` afterward, so your project matches the next lesson.

**Solution for Exercise 2:**

Update `src/components/Header.jsx`.

```jsx
function Header({ userName = "Guest", month = "this month" }) {
  return (
    <header className="app-header">
      <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
      <h1>Spendly</h1>
      <p>Welcome back, {userName}!</p>
      <p>Here is your summary for {month}.</p>
    </header>
  );
}

export default Header;
```

A component can destructure as many props as it needs, each with its own default, separated by commas. With `<Header userName="Dina" />` in `App`, the header shows:

```text
Spendly

Welcome back, Dina!

Here is your summary for this month.
```

With `<Header userName="Dina" month="October 2026" />`, it shows:

```text
Spendly

Welcome back, Dina!

Here is your summary for October 2026.
```

The order of attributes on the tag does not matter, because props are matched by name, not by position.

**Solution for Exercise 3:**

Create `src/components/Card.jsx`.

```jsx
function Card({ title, children }) {
  return (
    <div className="card">
      <h3 className="card-title">{title}</h3>
      {children}
    </div>
  );
}

export default Card;
```

Then update `src/components/Summary.jsx` to use it.

```jsx
import Card from "./Card.jsx";
import { formatAmount } from "../utils/format.js";

function Summary({ income, expense }) {
  const balance = income - expense;

  return (
    <section className="summary">
      <h2>Summary</h2>
      <Card title="Income">
        <p>{formatAmount(income)}</p>
      </Card>
      <Card title="Expense">
        <p>{formatAmount(expense)}</p>
      </Card>
      <Card title="Balance">
        <p>{formatAmount(balance)}</p>
        <small>Income minus expense</small>
      </Card>
    </section>
  );
}

export default Summary;
```

`Card` is not self-closing here. Everything between `<Card title="Income">` and `</Card>` is passed to `Card` as `children`, and `{children}` places it after the title. The balance card shows that `children` can hold several elements. Right-click the summary and choose **Inspect** to see the resulting HTML:

```html
<section class="summary"><h2>Summary</h2><div class="card"><h3 class="card-title">Income</h3><p>$3,400</p></div><div class="card"><h3 class="card-title">Expense</h3><p>$177</p></div><div class="card"><h3 class="card-title">Balance</h3><p>$3,223</p><small>Income minus expense</small></div></section>
```

`Card` adds the frame (the `div` and the title), and the parent decides what goes inside. Undo these changes afterward, so `Summary` matches the version in Section 3.

---

## Next Up - Lesson 6

In this lesson you learned props, the way data flows from a parent component to its children. You passed a name to `Header` with a default value, passed numbers to `Summary`, created a shared `formatAmount` helper, and built a reusable `TransactionItem` that `TransactionList` uses five times. You also learned that props are read-only and met the special `children` prop.

`TransactionList` still lists its five transactions by hand, one tag per row. In Lesson 6, you will move the transactions into a data file and let React generate the rows from the array with `map`. You will also learn why every list item needs a `key`, and how to show different content depending on the data, such as a friendly message when there are no transactions at all.
