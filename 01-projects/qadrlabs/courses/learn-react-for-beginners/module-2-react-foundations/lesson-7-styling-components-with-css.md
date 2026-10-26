## 1. Before You Begin

In Lesson 6, Spendly learned to render its transactions from data with `map`, show an empty state, and add a "Large" badge to big transactions. The structure is solid, but the page still looks like a plain document: the summary is a column of paragraphs, and each transaction's title and category run together.

In this lesson you will give Spendly a real design using plain CSS, the same CSS you know from the HTML and CSS course. You will see how CSS files are connected to a React project, how to apply classes with `className`, and, most importantly, how to make styles depend on data: income in green, expenses in red, a balance card that changes color, and a spending bar whose width is calculated from the numbers. You will finish with a small media query so Spendly also works on a phone.

### What You'll Build

- Global colors defined once as CSS variables in `src/index.css`.
- A new `src/App.css` file with styles for the header, summary cards, search box, and transaction list.
- A `Summary` component redesigned as three cards: income, expense, and balance.
- Income amounts in green and expense amounts in red, chosen from each transaction's `type`.
- A spending bar that shows what percentage of income has been spent, using an inline style.
- A one-column layout for screens narrower than 600 pixels.

### What You'll Learn

- ✅ How CSS files are imported and applied in a Vite React project
- ✅ The difference between global styles and component styles
- ✅ How to use CSS variables for a consistent color palette
- ✅ How to build a `className` from data with a template literal
- ✅ When to use an inline `style` instead of a class
- ✅ How React handles numbers in inline styles
- ✅ How to make the layout responsive with a media query

### What You'll Need

- The Spendly project from Lesson 6
- The development server running with `npm run dev`
- Basic CSS knowledge: selectors, colors, padding, margins, and Flexbox. The qadrlabs Learn HTML and CSS course covers all of these.

---

## 2. Set Up Global Styles

In a Vite project, a CSS file is applied when a JavaScript file imports it. You have already seen this: `main.jsx` contains `import './index.css'`, which is why the background color from Lesson 2 appears. Vite adds the CSS to the page for you; you never write a `<link>` tag.

Whatever is imported, the CSS itself is still normal, global CSS: a rule in any imported file applies to the whole page. A common way to stay organized is to keep **global styles** (colors, fonts, the body) in `index.css` and **component styles** in a separate file. Start with the global part.

### Step 1: Define the Color Palette

Replace the contents of `src/index.css` with this code.

```css
:root {
  --color-bg: #f5f6fa;
  --color-surface: #ffffff;
  --color-text: #1f2937;
  --color-muted: #6b7280;
  --color-border: #e5e7eb;
  --color-primary: #4f46e5;
  --color-income: #16a34a;
  --color-expense: #dc2626;
}

body {
  margin: 0;
  padding: 24px;
  font-family: system-ui, "Segoe UI", Roboto, sans-serif;
  background-color: var(--color-bg);
  color: var(--color-text);
}

h1,
h2,
p {
  margin: 0;
}
```

Here is what this code does:

- `:root` selects the top of the document, and the lines starting with `--` define **CSS variables** (officially called custom properties). Each one gives a color a meaningful name: `--color-income` instead of `#16a34a`.
- `var(--color-bg)` reads a variable. The `body` rule now uses the variables instead of fixed color codes. If you want to change Spendly's green later, you change it in one place.
- `--color-surface` is the white used for cards, `--color-muted` is a soft grey for secondary text, and `--color-primary` is Spendly's indigo brand color.
- The last rule removes the default margins browsers add to headings and paragraphs. You will control spacing yourself with Flexbox and Grid gaps instead.

Save the file. The page gets tighter spacing, because the default margins are gone. Everything else is still unstyled.

---

## 3. Style the Components

Now create the stylesheet for Spendly's components. You already added class names in the previous lessons (`app`, `app-header`, `transaction-item`, and so on); now they finally get rules.

### Step 1: Create App.css

Create a new file `src/App.css` with the following rules.

```css
.app {
  max-width: 720px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* Header */
.app-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.app-header h1 {
  font-size: 28px;
  color: var(--color-primary);
}

.app-header p {
  margin-left: auto;
  color: var(--color-muted);
}

/* Summary */
.summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.summary-card {
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 12px;
  padding: 16px;
}

.summary-label {
  display: block;
  font-size: 14px;
  color: var(--color-muted);
}

.summary-value {
  display: block;
  margin-top: 4px;
  font-size: 24px;
  font-weight: bold;
}

/* Filters */
.filters {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.filters input {
  padding: 10px 12px;
  font-size: 16px;
  border: 1px solid var(--color-border);
  border-radius: 8px;
}

/* Transactions */
.transactions {
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 12px;
  padding: 16px;
}

.transaction-count {
  margin-top: 4px;
  font-size: 14px;
  color: var(--color-muted);
}

.transactions ul {
  list-style: none;
  margin: 12px 0 0;
  padding: 0;
}

.transaction-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-top: 1px solid var(--color-border);
}

.transaction-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.transaction-title {
  font-weight: 600;
}

.transaction-meta {
  font-size: 14px;
  color: var(--color-muted);
}

.transaction-amount {
  font-weight: bold;
}

.badge {
  margin-left: 8px;
  padding: 2px 8px;
  font-size: 12px;
  font-weight: normal;
  color: var(--color-primary);
  background-color: #eef2ff;
  border-radius: 999px;
}

.empty-state {
  margin-top: 12px;
  color: var(--color-muted);
}
```

Here is what the main groups of rules do:

- `.app` centers the page with a maximum width of 720 pixels and stacks its children vertically with a 24-pixel `gap`, so you never need margins between sections.
- `.app-header` puts the logo, title, and greeting in one row. `margin-left: auto` on the greeting pushes it to the right edge.
- `.summary` uses CSS Grid with three equal columns (`repeat(3, 1fr)`), and `.summary-card` gives each card a white background, a border, and rounded corners. The summary cards do not exist yet; you will create them in the next step.
- `.filters` stacks the label above the input and gives the input comfortable padding.
- `.transactions` turns the list section into a white card. `list-style: none` removes the bullets.
- `.transaction-item` is the key rule for each row: `display: flex` with `justify-content: space-between` puts the title and meta on the left and the amount on the right. `.transaction-info` stacks the title above the meta line, which fixes the "Coffee with friendsFood" problem from the last two lessons.
- `.badge` turns the "Large" label into a small rounded pill. `border-radius: 999px` is a common trick for fully rounded ends.

Now import the stylesheet in `src/App.jsx`. Add the import as the first line.

```jsx
import "./App.css";
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

`import "./App.css";` has no name and no `from`, because a CSS file does not export anything to use in JavaScript. The import only tells Vite to add the file to the page. Save both files. The header, search box, and transaction list are now styled: each transaction is a clean row with its title in bold, the category and date underneath in grey, the amount on the right, and the "Large" badge as a small pill next to "Monthly salary".

### Step 2: Turn the Summary into Cards

The summary still uses the paragraphs from Lesson 5. Replace `src/components/Summary.jsx` with a card layout.

```jsx
import { formatAmount } from "../utils/format.js";

function Summary({ income, expense }) {
  const balance = income - expense;

  return (
    <section className="summary">
      <div className="summary-card">
        <span className="summary-label">Income</span>
        <span className="summary-value">{formatAmount(income)}</span>
      </div>
      <div className="summary-card">
        <span className="summary-label">Expense</span>
        <span className="summary-value">{formatAmount(expense)}</span>
      </div>
      <div className="summary-card">
        <span className="summary-label">Balance</span>
        <span className="summary-value">{formatAmount(balance)}</span>
      </div>
    </section>
  );
}

export default Summary;
```

Here is what changed:

- The `<h2>Summary</h2>` heading is gone. The three cards explain themselves, and the dashboard looks cleaner without it.
- Each value now lives in a `summary-card` with a small grey label (`summary-label`) and a large bold number (`summary-value`).
- The `.summary` grid from `App.css` places the three cards side by side.

Save the file. The summary is now a row of three white cards. All three numbers are dark grey, which is the next thing to fix.

---

## 4. Style Based on Data

Static classes make Spendly look tidy, but a finance app should also communicate meaning through color: green for money coming in, red for money going out. The color depends on the data, so it cannot be hard-coded in the JSX. Because `className` is just a string, you can build it with JavaScript.

### Step 1: Color Amounts by Type

First, add two color classes at the end of `src/App.css`.

```css
/* Colors based on data */
.income {
  color: var(--color-income);
}

.expense {
  color: var(--color-expense);
}
```

The class names are exactly the two possible values of a transaction's `type` property: `"income"` and `"expense"`. That is deliberate, because it means you can use the `type` value directly as a class name.

Now update the amount in `src/components/TransactionItem.jsx`.

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
      <span className={`transaction-amount ${type}`}>
        {sign}
        {formatAmount(amount)}
      </span>
    </li>
  );
}

export default TransactionItem;
```

The only change is `className={`transaction-amount ${type}`}`. Here is how it works:

- The curly braces switch to JavaScript, as with any JSX attribute value that is not a plain string.
- Inside them is a template literal (backticks). It always contains `transaction-amount`, followed by a space, followed by the value of `type`.
- For the coffee, `type` is `"expense"`, so the element gets `class="transaction-amount expense"`. For the salary, it gets `class="transaction-amount income"`.

Next, color the summary values. Update `src/components/Summary.jsx`.

```jsx
import { formatAmount } from "../utils/format.js";

function Summary({ income, expense }) {
  const balance = income - expense;

  return (
    <section className="summary">
      <div className="summary-card">
        <span className="summary-label">Income</span>
        <span className="summary-value income">{formatAmount(income)}</span>
      </div>
      <div className="summary-card">
        <span className="summary-label">Expense</span>
        <span className="summary-value expense">{formatAmount(expense)}</span>
      </div>
      <div className="summary-card">
        <span className="summary-label">Balance</span>
        <span className={`summary-value ${balance >= 0 ? "income" : "expense"}`}>
          {formatAmount(balance)}
        </span>
      </div>
    </section>
  );
}

export default Summary;
```

Here is what changed:

- The income value always gets the `income` class, and the expense value always gets the `expense` class. These never change, so they are written as plain strings.
- The balance can be positive or negative, so its class is calculated: `${balance >= 0 ? "income" : "expense"}` puts a ternary inside the template literal. A positive or zero balance is green; a negative balance is red. This replaces the inline style you used for the same purpose in Lesson 3.

Save both files. Income amounts in the list are green with a `+`, expenses are red with a `-`, and the three summary cards show green, red, and green.

### Step 2: Add a Spending Bar with an Inline Style

Classes are perfect when there are a few fixed options, such as green or red. But some styles are a continuous value calculated from data, such as a bar that is 5% or 73% wide. You cannot write a class for every possible percentage. That is the right time for an inline `style`.

Add these rules to the end of `src/App.css`.

```css
/* Spending bar */
.spending {
  grid-column: 1 / -1;
}

.spending-bar {
  height: 8px;
  background-color: var(--color-border);
  border-radius: 999px;
  overflow: hidden;
}

.spending-bar-fill {
  height: 100%;
  background-color: var(--color-primary);
}

.spending-text {
  margin-top: 6px;
  font-size: 14px;
  color: var(--color-muted);
}
```

Here is what these rules do:

- `.spending` sits inside the summary grid, and `grid-column: 1 / -1` makes it span from the first column line to the last, so it is as wide as all three cards together.
- `.spending-bar` is the grey track, and `overflow: hidden` keeps the fill inside its rounded corners.
- `.spending-bar-fill` is the colored part. Its height fills the track, but its width is missing on purpose: that is the part React will set.

Then replace `src/components/Summary.jsx` with the final version for this lesson.

```jsx
import { formatAmount } from "../utils/format.js";

function Summary({ income, expense }) {
  const balance = income - expense;
  const spentPercent = income > 0 ? Math.min(100, Math.round((expense / income) * 100)) : 0;

  return (
    <section className="summary">
      <div className="summary-card">
        <span className="summary-label">Income</span>
        <span className="summary-value income">{formatAmount(income)}</span>
      </div>
      <div className="summary-card">
        <span className="summary-label">Expense</span>
        <span className="summary-value expense">{formatAmount(expense)}</span>
      </div>
      <div className="summary-card">
        <span className="summary-label">Balance</span>
        <span className={`summary-value ${balance >= 0 ? "income" : "expense"}`}>
          {formatAmount(balance)}
        </span>
      </div>
      <div className="spending">
        <div className="spending-bar">
          <div className="spending-bar-fill" style={{ width: `${spentPercent}%` }}></div>
        </div>
        <p className="spending-text">You have spent {spentPercent}% of your income.</p>
      </div>
    </section>
  );
}

export default Summary;
```

Here is what is new:

- `spentPercent` calculates how much of the income has been spent: `(expense / income) * 100`, rounded to a whole number. `Math.min(100, ...)` caps it at 100, so the bar never grows past its track when expenses exceed income. The ternary `income > 0 ? ... : 0` avoids dividing by zero when there is no income yet.
- `style={{ width: `${spentPercent}%` }}` sets the fill's width. The template literal builds a string such as `"5%"`. The unit matters, as you will see in the Fix the Errors section.
- The `<div className="spending-bar-fill"></div>` has no content; it is only a colored shape. You could also write it as a self-closing `<div ... />`.
- The paragraph repeats the percentage in words, so the information does not depend on color or shape alone.

Save both files. Under the cards, a thin indigo bar fills 5% of the track, followed by the text "You have spent 5% of your income."

### Step 3: Make the Layout Responsive

Three cards side by side are too cramped on a phone. Add a media query to the end of `src/App.css`.

```css
/* Small screens */
@media (max-width: 600px) {
  .summary {
    grid-template-columns: 1fr;
  }
}
```

When the browser window is 600 pixels wide or less, the summary grid switches to a single column, and the cards stack vertically. Save the file, then make your browser window narrow (or open the developer tools and click the device toolbar icon) to see the cards stack. The transaction rows already adapt, because Flexbox shrinks them to fit.

---

## 5. Run and Test

With the development server running, open `http://localhost:5173`. Spendly now looks like a real app:

- A header with the logo and the indigo "Spendly" title on the left, and "Welcome back, Dina!" in grey on the right.
- Three summary cards: Income `$3,400` in green, Expense `$177` in red, Balance `$3,223` in green.
- A thin indigo bar and the line "You have spent 5% of your income."
- A labeled search box with rounded corners.
- A white transactions card with "Showing 5 transactions" and five neat rows, green incomes and red expenses, and a "Large" pill next to "Monthly salary".

The text content of the page has not changed; only its presentation has.

What the browser reports as the page text:

```text
Spendly

Welcome back, Dina!

Income
$3,400
Expense
$177
Balance
$3,223

You have spent 5% of your income.

Search transactions
Transactions

Showing 5 transactions

Coffee with friends
Food · 2026-10-09
-$12
Freelance design
Freelance · 2026-10-08
+$400
Bus pass
Transport · 2026-10-05
-$45
Groceries
Food · 2026-10-03
-$120
Monthly salaryLarge
Salary · 2026-10-01
+$3,000
```

Notice that each title is now on its own line, because the CSS stacks the title and the meta line.

Now test the data-driven styles. In `App.jsx`, change `expense={177}` to `expense={3650}` and save:

- The expense card shows `$3,650`, and the balance card shows `-$250` in **red**.
- The spending bar fills the whole track, and the text says "You have spent 100% of your income." Without `Math.min`, the calculation would give 107%.

Right-click the balance value and choose **Inspect**: the element has `class="summary-value expense"`. Right-click the bar: the fill has `style="width: 100%;"`. Change the expense back to `177`.

---

## 6. Choosing How to Style a React Component

You used three styling tools in this lesson. Here is when to reach for each one.

| Tool | Use it for | Spendly example |
| --- | --- | --- |
| Global CSS (`index.css`) | Colors, fonts, the page background, resets | CSS variables and the `body` rule |
| Classes (`className`) | Almost all component styling, including a small set of states | `.transaction-item`, `.income`, `.expense` |
| Inline `style` | Values calculated from data that cannot be listed in advance | The spending bar's width |

Prefer classes whenever you can. They keep the design in CSS, where it is easy to find and change, and they support things inline styles cannot, such as `:hover`, `:focus`, and media queries.

**All CSS is global.** Importing `App.css` from `App.jsx` does not limit its rules to the `App` component; every rule applies to the whole page. In a small app like Spendly, clear and specific class names, such as `transaction-amount` instead of `amount`, are enough to avoid clashes. Larger projects often use **CSS Modules**, a Vite feature where a file named `Something.module.css` produces class names that are unique to one component, or utility-class frameworks such as Tailwind CSS. You will see both in AI-generated code. The ideas from this lesson, building class names from data and using inline styles only for calculated values, apply to all of them.

**Building class names.** For a single condition, a template literal with a ternary is clear enough: `className={`summary-value ${balance >= 0 ? "income" : "expense"}`}`. When a component needs many conditional classes, the code can get hard to read. Many projects then use a small helper library such as `clsx`. Spendly does not need one.

---

## 7. Fix the Errors in Your Code

These styling mistakes often produce no error at all, which makes them tricky to spot.

**Error 1: Writing a variable inside a plain string className.**

Curly braces inside quotes are just characters, not JavaScript.

```jsx
// Wrong
<span className="transaction-amount {type}">

// Correct
<span className={`transaction-amount ${type}`}>
```

The wrong version does not show an error, but the amounts are no longer green or red. Inspect one in the Elements panel and you will see the literal text:

```html
<span class="transaction-amount {type}">-$12</span>
```

The browser looks for a class named `{type}`, which does not exist. To build a class name from data, the whole attribute value must be JavaScript: curly braces around a template literal with backticks and `${}`.

**Error 2: Passing a CSS string to style.**

In HTML you write `style="width: 50%"`. In JSX that is not allowed.

```jsx
// Wrong
<div className="spending-bar-fill" style="width: 50%"></div>

// Correct
<div className="spending-bar-fill" style={{ width: "50%" }}></div>
```

The wrong version crashes the app. The page goes blank, and the console shows:

```text
Error: The `style` prop expects a mapping from style properties to values, not a string. For example, style={{marginRight: spacing + 'em'}} when using JSX.
```

"A mapping from style properties to values" means an object. Use double curly braces, camelCase property names, and quoted values.

**Error 3: Forgetting the unit in an inline style.**

When an inline style value is a plain number, React adds `px` for most properties.

```jsx
// Wrong
<div className="spending-bar-fill" style={{ width: spentPercent }}></div>

// Correct
<div className="spending-bar-fill" style={{ width: `${spentPercent}%` }}></div>
```

The wrong version runs without any message, but the bar is almost invisible. Inspecting the fill shows why:

```text
width: 5px;
```

React turned the number `5` into `5px`, not `5%`. Whenever you need a unit other than pixels, build a string that includes the unit, as the correct version does.

---

## 8. Exercises

**Exercise 1:** Give the search input a clear focus state: when it is focused, its border should change to Spendly's primary color, the default browser outline should be removed, and a soft indigo glow should appear around it. Use only CSS.

**Exercise 2:** Make the whole balance card reflect the balance, not just the number. Add a `positive` class to the balance card when the balance is zero or more, and a `negative` class otherwise. Style `.summary-card.positive` with a light green background (`#f0fdf4`) and `.summary-card.negative` with a light red background (`#fef2f2`).

**Exercise 3:** Turn the spending bar into a warning when spending gets high. When `spentPercent` is 80 or more, give the fill an extra class named `warning`, and style `.spending-bar-fill.warning` with the expense color. Test it with an expense of `3000`.

---

## 9. Solutions

**Solution for Exercise 1:**

Add this rule to `src/App.css`, after the `.filters input` rule.

```css
.filters input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px #e0e7ff;
}
```

`:focus` applies only while the input is active, for example after you click it or reach it with the `Tab` key. Removing the outline is only acceptable because the border color and the `box-shadow` glow replace it with an equally visible focus indicator. Never remove the outline without a replacement, because keyboard users rely on it to see where they are. This exercise needs no JSX changes, which is a good example of why classes and CSS files are preferred over inline styles: inline styles cannot express `:focus` at all.

**Solution for Exercise 2:**

Change the balance card's opening tag in `src/components/Summary.jsx`.

```jsx
<div className={`summary-card ${balance >= 0 ? "positive" : "negative"}`}>
```

Then add these rules to `src/App.css`.

```css
.summary-card.positive {
  background-color: #f0fdf4;
}

.summary-card.negative {
  background-color: #fef2f2;
}
```

The template literal always includes `summary-card`, so the card keeps its border, radius, and padding, and adds one of the two state classes. The selector `.summary-card.positive`, with no space, means "an element that has both classes". Inspecting the three cards gives these class lists with the sample data:

```text
summary-card
summary-card
summary-card positive
```

With an expense of `3650`, the third one becomes `summary-card negative`, and the card turns light red.

**Solution for Exercise 3:**

Change the fill's opening tag in `src/components/Summary.jsx`.

```jsx
<div className={`spending-bar-fill ${spentPercent >= 80 ? "warning" : ""}`} style={{ width: `${spentPercent}%` }}></div>
```

Then add this rule to `src/App.css`, after the `.spending-bar-fill` rule.

```css
.spending-bar-fill.warning {
  background-color: var(--color-expense);
}
```

When `spentPercent` is below 80, the ternary returns an empty string, so the class is `spending-bar-fill ` (with a harmless trailing space). With an expense of `3000`, `spentPercent` is `88`, the class becomes `spending-bar-fill warning`, and the bar turns red. This element uses both techniques at once: a class for the state that has two fixed options, and an inline style for the width that can be any number. Set the expense back to `177` when you are done.

---

## Next Up - Lesson 8

In this lesson you styled Spendly with plain CSS. You defined a color palette with CSS variables in `index.css`, created `App.css` for component styles, and redesigned the summary as cards. You built class names from data with template literals so that amounts and the balance are colored by meaning, used an inline style for the spending bar's calculated width, and added a media query for small screens. That completes Module 2: Spendly now has a clear component structure, data-driven rendering, and a real design.

There is one big thing missing: nothing on the page responds to the user. In Lesson 8, you will start Module 3 by handling events. You will make buttons respond to clicks, read what the user types into the search box, and pass functions from a parent component to a child, the technique that lets a child component tell its parent that something happened.
