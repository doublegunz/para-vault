## 1. Before You Begin

Open almost any modern web app, such as an online store, a banking dashboard, or a chat app, and there is a good chance it was built with React. React is a JavaScript library for building user interfaces, and it has become so common that AI coding assistants reach for it by default. Ask an AI tool to "build me a budget app" and you will probably get a folder full of React files back. That is exciting, but it also leaves many people holding code they did not write and cannot fix when it breaks.

This course changes that. Instead of copying React code, you will learn to write it, read it, and repair it, one concept at a time. Every lesson adds a feature to a single app called Spendly, a personal expense tracker. This first lesson builds the right mental model before you install anything: what React is, what problem it solves compared to the plain JavaScript you may already know, why AI tools love it, and what Spendly will look like when you finish. You will also write the first piece of Spendly today: its data, modeled with plain JavaScript in your browser.

### What You'll Build

Two small things that run directly in your browser, with no installation:

- A click counter written with plain HTML and JavaScript, so you can compare it with the same counter written in React.
- The first version of Spendly's data: a list of transactions stored in a JavaScript array, plus a few lines of code that calculate income, expense, and balance in the browser console.

### What You'll Learn

- ✅ What React is and what "a library for building user interfaces" means
- ✅ The difference between updating the page by hand (imperative) and describing what the page should look like (declarative)
- ✅ What components are and why React apps are built from them
- ✅ Why AI coding tools generate so much React, and why you still need to understand it
- ✅ The features, pages, and data of Spendly, the app you will build in this course
- ✅ How to run JavaScript in the browser console
- ✅ The roadmap for the rest of the course

### What You'll Need

- A modern web browser such as Chrome, Edge, or Firefox
- A text editor such as Visual Studio Code
- Basic HTML and JavaScript: tags, variables, arrays, objects, loops, and `addEventListener`. If any of these feel new, the qadrlabs courses Learn HTML and CSS and Learn JavaScript Basics cover them from zero.

---

## 2. What Is React?

React is a JavaScript library, created at Facebook (now Meta) and released as open source in 2013, for building user interfaces. A user interface is everything a person sees and touches on the screen: text, buttons, forms, lists, and menus. React does not handle databases, servers, or payments. It focuses on one job: keeping what is on the screen in sync with the data in your app.

Two ideas make React different from writing plain JavaScript.

The first idea is **components**. A React app is built from small, reusable pieces of interface, each one written as a JavaScript function. A budget app might have a `Header` component, a `Summary` component that shows the balance, and a `TransactionItem` component that shows one transaction. You write `TransactionItem` once and reuse it for every transaction in the list, the same way you might reuse a CSS class for every button.

The second idea is being **declarative**. In plain JavaScript, you change the page step by step: find this element, change its text, add this class, remove that element. That style is called imperative, because you give the browser commands. In React, you describe what the page should look like for the current data, and React figures out which parts of the page need to change. When the data changes, React updates the screen for you.

A simple comparison helps. Imagine telling a friend how to set a table. The imperative way is: "Walk to the cupboard, take two plates, put one on the left, put one on the right." The declarative way is to show them a photo of the finished table and say: "Make it look like this." React works like the photo. You describe the result, and React handles the steps.

---

## 3. Build a Counter with Plain JavaScript

The fastest way to understand what React does is to see the problem it solves. In this section you will build a tiny click counter with only HTML and JavaScript, the way you learned in the JavaScript Basics course. In the next section you will compare it with the React version.

### Step 1: Create the HTML File

Create a new folder anywhere on your computer, for example `react-practice`, and inside it create a file named `counter.html`. Open the file in your text editor and type the following code.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Plain JavaScript Counter</title>
</head>
<body>
  <p>You clicked <span id="count">0</span> times.</p>
  <button id="add-button">Click me</button>

  <script>
    let count = 0;

    const countText = document.getElementById("count");
    const button = document.getElementById("add-button");

    button.addEventListener("click", function () {
      count = count + 1;
      countText.textContent = count;
    });
  </script>
</body>
</html>
```

Here is what each part does:

- The `<p>` element shows a sentence, and the number inside it lives in a `<span>` with the id `count`, so JavaScript can find it later.
- The `<button>` has the id `add-button` for the same reason.
- `let count = 0;` stores the current number in a variable. This is the app's data.
- The two `document.getElementById` lines find the span and the button on the page and keep references to them.
- `addEventListener("click", ...)` runs the function every time the button is clicked. Inside it, `count = count + 1;` updates the data, and `countText.textContent = count;` updates the screen by writing the new number into the span.

### Step 2: Open the File in the Browser

Save the file, then open it in your browser. You can double-click `counter.html` in your file manager, or drag the file into an open browser window. Click the button three times.

What you see in the browser after three clicks:

```text
You clicked 3 times.
[Click me]
```

It works, but notice something important: the code has to do two separate jobs every time. It updates the data (`count = count + 1`), and then it updates the page by hand (`countText.textContent = count`). If you forget the second line, the data changes but the screen does not. In a tiny counter that is easy to remember. In an app where the same number appears in a header, a summary card, and a chart, keeping every element in sync by hand quickly becomes the hardest part of the job.

---

## 4. The Same Counter in React

Here is the same counter written as a React component. You cannot run it yet, because React needs a small project setup that you will create in Lesson 2. For now, read it and compare it with the plain JavaScript version.

```jsx
import { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>You clicked {count} times.</p>
      <button onClick={() => setCount(count + 1)}>Click me</button>
    </div>
  );
}

export default Counter;
```

Even without knowing React, you can probably guess most of it:

- `function Counter()` is a component. It is a normal JavaScript function whose job is to return a piece of user interface.
- `useState(0)` creates a piece of data called state, starting at `0`. It gives back two things: the current value, `count`, and a function to change it, `setCount`. You will learn state properly in Lesson 9.
- The `return (...)` part looks like HTML, but it is JSX, a syntax that lets you write HTML-like markup inside JavaScript. The `{count}` inside the `<p>` tag inserts the current value. You will learn JSX in Lesson 3.
- `onClick={() => setCount(count + 1)}` tells React to run that arrow function when the button is clicked.

Notice what is missing. There is no `getElementById`, no `textContent`, and no ids on the elements. The component only says "the paragraph shows `count`" and "clicking the button changes `count`". When `setCount` changes the value, React runs the `Counter` function again, compares the new result with what is on the screen, and updates only the text that changed. You describe the page; React keeps it in sync. That is the declarative idea from Section 2 in action, and it is the reason React scales well from a counter to a full app.

---

## 5. React and AI Coding Tools

If you have tried an AI coding assistant or a "vibe coding" tool, where you describe an app in plain language and the tool writes the code, you have probably seen React already. There are a few reasons AI tools generate so much of it:

- **It is everywhere.** React has been one of the most widely used front-end libraries for years, so there is a huge amount of public React code and documentation. AI models learn from that code, so React is what they know best.
- **Components fit how people describe apps.** "A page with a header, a list of expenses, and a form to add a new one" maps naturally to a `Header`, an `ExpenseList`, and an `ExpenseForm` component.
- **It has a huge ecosystem.** Popular frameworks and templates, such as Vite and Next.js, are built around React, so a generated project usually works out of the box.

Here is the catch. An AI tool can produce a React app in seconds, but it cannot guarantee the app is correct. Generated code often contains small mistakes that are easy to miss: a list that updates in the wrong order, a form that loses what you typed, a page that keeps reloading data forever, or a button that changes the data but not the screen. If you do not understand components, props, state, and effects, every one of those bugs looks like magic, and the only option left is to ask the AI again and hope.

This course gives you the understanding to stay in control. Modules 1 to 6 teach React step by step through Spendly. Module 7 then puts that knowledge to work with AI: you will ask an AI tool to write a Spendly feature, read the result line by line, and find and fix the kinds of bugs AI tools commonly produce. The goal is not to avoid AI. The goal is to be the developer who knows what the code is doing.

---

## 6. Meet Spendly

Spendly is a personal expense tracker. It answers a question almost everyone has at the end of the month: "Where did my money go?" You record each transaction, either money coming in (income) or money going out (expense), and Spendly keeps the list, the totals, and the balance up to date.

By the end of the course, Spendly will have these features:

| Feature | What it does | Where you build it |
| --- | --- | --- |
| Transaction list | Shows every transaction with its title, category, date, and amount | Lessons 4 to 7 |
| Add transaction | A form to record new income or expenses | Lessons 8 to 10 |
| Edit and delete | Fix a typo or remove a transaction | Lesson 11 |
| Balance summary | Total income, total expense, and current balance, always up to date | Lessons 12 and 13 |
| Filter and search | Show only one category or search transactions by title | Lesson 13 |
| Saved data | Transactions stay in the browser after a page refresh | Lessons 14 and 16 |
| Categories and exchange rates | Loads categories from a file and currency rates from a public API | Lesson 15 |
| Multiple pages | Dashboard, Transactions, Add Transaction, and Transaction Detail pages | Lessons 17 to 19 |

The main dashboard will look roughly like this sketch:

```text
+======================================================+
| Spendly                 Dashboard | Transactions | + |
+======================================================+
|  Income: $3400    Expense: $177    Balance: $3223    |
+======================================================+
|  Search: [            ]   Category: [ All       v ]  |
|                                                      |
|  2026-10-09  Coffee with friends   Food      -$12    |
|  2026-10-08  Freelance design      Freelance +$400   |
|  2026-10-05  Bus pass              Transport -$45    |
|  2026-10-03  Groceries             Food      -$120   |
|  2026-10-01  Monthly salary        Salary    +$3000  |
+======================================================+
```

In React, this screen is not one big file. It is a tree of components, each responsible for one part:

```text
App
├── Header             (logo and navigation links)
├── Summary            (income, expense, and balance cards)
├── Filters            (search box and category dropdown)
└── TransactionList    (the list)
    └── TransactionItem  (one row, reused for every transaction)
```

You will create each of these components yourself in Module 2 and bring them to life in Module 3.

Behind every screen sits the data. In Spendly, each transaction is a JavaScript object with the same six properties:

| Property | Example | Meaning |
| --- | --- | --- |
| `id` | `2` | A unique number that identifies the transaction |
| `title` | `"Groceries"` | A short description |
| `amount` | `120` | How much money, always a positive number |
| `type` | `"expense"` | Either `"income"` or `"expense"` |
| `category` | `"Food"` | A group such as Food, Transport, or Salary |
| `date` | `"2026-10-03"` | The date in year-month-day format |

The `type` property decides whether the amount adds to or subtracts from the balance, so the amount itself never needs a minus sign. You will use this exact shape all the way to the last lesson.

---

## 7. Model Spendly's Data in the Browser Console

Before writing any React, you will create Spendly's data with plain JavaScript and calculate its totals. Every browser includes a console where you can type JavaScript and see the result immediately, which makes it a perfect place for quick experiments. The code in this section uses only arrays, objects, loops, and template literals from the JavaScript Basics course.

### Step 1: Open the Browser Console

Open a new browser tab and go to `about:blank`, an empty page. Then open the developer tools console:

- Chrome or Edge: press `Ctrl+Shift+J` on Windows or Linux, or `Cmd+Option+J` on macOS.
- Firefox: press `Ctrl+Shift+K` on Windows or Linux, or `Cmd+Option+K` on macOS.

Type the following line into the console and press `Enter`.

```javascript
console.log("Hello, Spendly!");
```

Output in the console:

```text
Hello, Spendly!
```

`console.log` prints a value to the console. You may also see a grey `undefined` on the next line. That is the console showing the return value of `console.log` itself, which returns nothing. You can ignore it.

Each of the next steps is a complete piece of code. If the console shows an error saying that `transactions` has already been declared, refresh the page and paste the code again.

### Step 2: Create the Transactions Array

Paste the following code into the console and press `Enter`.

```javascript
const transactions = [
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" },
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
  { id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
];

console.log(`Spendly has ${transactions.length} transactions.`);
console.log(transactions[1].title);
```

Here is what this code does:

- `const transactions = [ ... ];` creates an array, a list of values, and stores it in a constant named `transactions`.
- Each item in the array is an object written with curly braces. Every object has the same six properties described in Section 6. The objects are separated by commas.
- `transactions.length` is the number of items in the array, inserted into the message with a template literal (the backtick string with `${}`).
- `transactions[1].title` reads the `title` property of the item at index `1`. Arrays start counting at `0`, so index `1` is the second transaction.

Output in the console:

```text
Spendly has 3 transactions.
Groceries
```

### Step 3: Calculate Income, Expense, and Balance

Refresh the page, open the console again, and paste this code.

```javascript
const transactions = [
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" },
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
  { id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
];

let income = 0;
let expense = 0;

for (const transaction of transactions) {
  if (transaction.type === "income") {
    income = income + transaction.amount;
  } else {
    expense = expense + transaction.amount;
  }
}

console.log(`Income: $${income}`);
console.log(`Expense: $${expense}`);
console.log(`Balance: $${income - expense}`);
```

Here is what this code does:

- `let income = 0;` and `let expense = 0;` create two running totals that start at zero. They use `let` because their values change inside the loop.
- `for (const transaction of transactions)` visits each object in the array, one at a time, and names the current one `transaction`.
- The `if` statement compares the `type` property with `===`. Income amounts are added to `income`; everything else is added to `expense`.
- After the loop, the three `console.log` lines print the totals. In `$${income}`, the first `$` is a normal dollar sign in the text, and `${income}` inserts the value. The balance is calculated directly inside the template literal as `income - expense`.

Output in the console:

```text
Income: $3000
Expense: $165
Balance: $2835
```

The expense total is `120 + 45 = 165`, and the balance is `3000 - 165 = 2835`. Keep these numbers in mind. In Lesson 13, Spendly's `Summary` component will calculate exactly the same totals, but it will show them on the page and update them automatically whenever a transaction is added, edited, or deleted.

### Step 4: Print Each Transaction

Refresh the page once more and paste this code to print the list the way Spendly will show it.

```javascript
const transactions = [
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" },
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
  { id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
];

for (const transaction of transactions) {
  const sign = transaction.type === "income" ? "+" : "-";
  console.log(`${transaction.date}  ${transaction.title} (${transaction.category}): ${sign}$${transaction.amount}`);
}
```

Here is what this code does:

- The loop visits every transaction again.
- `const sign = transaction.type === "income" ? "+" : "-";` uses the ternary operator, a short form of `if...else` that picks one of two values. Income gets a plus sign and expenses get a minus sign. You will use the ternary operator a lot in React, because it fits neatly inside JSX.
- The template literal combines the date, title, category, sign, and amount into one line.

Output in the console:

```text
2026-10-01  Monthly salary (Salary): +$3000
2026-10-03  Groceries (Food): -$120
2026-10-05  Bus pass (Transport): -$45
```

This is the core of Spendly: a list of objects and some code that turns them into something readable. Everything React adds on top is about putting that result on the screen and keeping it correct as the data changes.

---

## 8. How This Course Works

The course is organized into eight modules. Each one builds on the previous one and adds new features to Spendly.

| Module | Topic | Lessons |
| --- | --- | --- |
| 1 | Getting to Know Spendly | 1 to 2 |
| 2 | React Foundations: JSX, components, props, lists, styling | 3 to 7 |
| 3 | Making Spendly Interactive: events, state, forms | 8 to 11 |
| 4 | Organizing State: lifting state up and derived data | 12 to 13 |
| 5 | Side Effects and Data: localStorage, APIs, custom hooks | 14 to 16 |
| 6 | Multiple Pages with React Router | 17 to 19 |
| 7 | Coding React with AI | 20 to 21 |
| 8 | Finishing Spendly | 22 |

Every lesson follows the same rhythm. You start with a short overview of what you will build, then follow numbered steps that each end with code you can run and a result you can check. After that comes a "Fix the Errors in Your Code" section with common mistakes, a set of exercises, and full solutions. Try the exercises before reading the solutions; that is where most of the learning happens.

You will write all the code yourself. Typing it, rather than copying it, feels slower at first, but it is how your fingers and eyes learn to spot a missing brace or a misspelled name. That skill matters even more when you start reviewing code written by AI.

---

## 9. Fix the Errors in Your Code

These are common mistakes when working with arrays of objects like Spendly's transactions. Try each wrong version in the console to see what happens, then fix it.

**Error 1: A missing comma between objects.**

Items in an array must be separated by commas. When a comma is missing between two objects, JavaScript cannot tell where one item ends and the next begins.

```javascript
// Wrong
const transactions = [
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" }
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
];

// Correct
const transactions = [
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" },
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
];
```

The wrong version stops with `SyntaxError: Unexpected token '{'` (Chrome adds the word `Uncaught` in front). JavaScript reached the opening `{` of the second object while still expecting a comma or a closing `]`. As with most syntax errors, the real problem is just before the place the error points to.

**Error 2: Storing amounts as text.**

If an amount is written in quotes, it is a string, not a number. The `+` operator then joins text together instead of adding numbers.

```javascript
// Wrong
{ id: 2, title: "Groceries", amount: "120", type: "expense", category: "Food", date: "2026-10-03" },
{ id: 3, title: "Bus pass", amount: "45", type: "expense", category: "Transport", date: "2026-10-05" },

// Correct
{ id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
{ id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
```

With the wrong version, the totals code from Step 3 runs without any error, but prints this:

```text
Income: $3000
Expense: $012045
Balance: $-9045
```

`0 + "120"` becomes the text `"0120"`, and adding `"45"` gives `"012045"`. Then `3000 - "012045"` forces the text back into a number, which produces a nonsense balance. This kind of bug is dangerous because nothing crashes. It will come back in Lesson 10, where every value read from a form input is a string and must be converted to a number.

**Error 3: Using `=` instead of `===` in a condition.**

A single `=` assigns a value. Three equal signs, `===`, compare two values.

```javascript
// Wrong
if (transaction.type = "income") {
  income = income + transaction.amount;
}

// Correct
if (transaction.type === "income") {
  income = income + transaction.amount;
}
```

The wrong version also runs without an error, but prints this:

```text
Income: $3165
Expense: $0
Balance: $3165
```

`transaction.type = "income"` sets the type of every transaction to `"income"`, and the result of that assignment, the non-empty string `"income"`, counts as true. So every amount is added to income. Worse, the loop has quietly changed the original data. Changing data directly like this is called mutation, and in React it causes some of the most confusing bugs. You will learn how to avoid it in Lesson 11.

---

## 10. Exercises

**Exercise 1:** In your own words, explain the difference between the plain JavaScript counter in Section 3 and the React counter in Section 4. Use the words "imperative" and "declarative" in your answer, and name the line in the plain version that React makes unnecessary.

**Exercise 2:** Add two more transactions to Spendly's data: a freelance design job that brought in `400` on `2026-10-08` in the category `Freelance`, and coffee with friends that cost `12` on `2026-10-09` in the category `Food`. Give them the ids `4` and `5`. Then print the number of transactions, the income, the expense, and the balance.

**Exercise 3:** Using the five transactions from Exercise 2, write code that calculates and prints how much was spent in the `Food` category only. Make sure income is never counted, even if an income transaction happens to use the `Food` category.

---

## 11. Solutions

**Solution for Exercise 1:**

The plain JavaScript counter is imperative: it tells the browser each step to take. It stores `count`, finds the `<span>` with `getElementById`, and after every click it updates the data and then writes the new number into the page with `countText.textContent = count;`. The React counter is declarative: it describes what the page should look like, a paragraph that shows `{count}`, and only changes the data with `setCount`. React then updates the screen by itself. The line `countText.textContent = count;`, along with the `getElementById` lookups that support it, is the work React makes unnecessary.

**Solution for Exercise 2:**

Add the two objects to the end of the array, then reuse the totals loop from Step 3.

```javascript
const transactions = [
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" },
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
  { id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
  { id: 4, title: "Freelance design", amount: 400, type: "income", category: "Freelance", date: "2026-10-08" },
  { id: 5, title: "Coffee with friends", amount: 12, type: "expense", category: "Food", date: "2026-10-09" },
];

let income = 0;
let expense = 0;

for (const transaction of transactions) {
  if (transaction.type === "income") {
    income = income + transaction.amount;
  } else {
    expense = expense + transaction.amount;
  }
}

console.log(`Spendly has ${transactions.length} transactions.`);
console.log(`Income: $${income}`);
console.log(`Expense: $${expense}`);
console.log(`Balance: $${income - expense}`);
```

The two new objects follow the same six-property shape as the others, and the comma after the third object is what lets the array continue. The loop does not need to change at all, because it works for any number of transactions.

Output in the console:

```text
Spendly has 5 transactions.
Income: $3400
Expense: $177
Balance: $3223
```

These are the same numbers shown in the dashboard sketch in Section 6.

**Solution for Exercise 3:**

Check both the type and the category with the `&&` operator, which is true only when both conditions are true.

```javascript
const transactions = [
  { id: 1, title: "Monthly salary", amount: 3000, type: "income", category: "Salary", date: "2026-10-01" },
  { id: 2, title: "Groceries", amount: 120, type: "expense", category: "Food", date: "2026-10-03" },
  { id: 3, title: "Bus pass", amount: 45, type: "expense", category: "Transport", date: "2026-10-05" },
  { id: 4, title: "Freelance design", amount: 400, type: "income", category: "Freelance", date: "2026-10-08" },
  { id: 5, title: "Coffee with friends", amount: 12, type: "expense", category: "Food", date: "2026-10-09" },
];

let foodTotal = 0;

for (const transaction of transactions) {
  if (transaction.type === "expense" && transaction.category === "Food") {
    foodTotal = foodTotal + transaction.amount;
  }
}

console.log(`Food spending: $${foodTotal}`);
```

Only transactions that are expenses and belong to `Food` are added, so the groceries (`120`) and the coffee (`12`) are counted. Checking the type as well as the category protects the total from an income transaction that was put in the wrong category.

Output in the console:

```text
Food spending: $132
```

This is a small version of the category filter you will build in Lesson 13.

---

## Next Up - Lesson 2

In this lesson you learned what React is: a library for building user interfaces from components, where you describe what the page should look like and React keeps the screen in sync with the data. You compared a plain JavaScript counter with a React counter, saw why AI tools generate so much React and why understanding it still matters, took a tour of Spendly, and modeled Spendly's transactions with plain JavaScript in the browser console.

In Lesson 2, you will install Node.js and npm, create the Spendly project with Vite, start the development server, and see your first React component running in the browser. You will also take a guided tour of the project's folders and files, so you know exactly where each piece of code belongs.
