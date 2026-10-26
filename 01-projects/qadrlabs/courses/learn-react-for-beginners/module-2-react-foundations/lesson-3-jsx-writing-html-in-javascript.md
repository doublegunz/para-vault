## 1. Before You Begin

In Lesson 2, you created the Spendly project with Vite and replaced the starter page with a small `App` component that returns a heading and a tagline. That component already used JSX, the HTML-like syntax inside the `return` statement, but so far it only contained fixed text. A real app shows data that changes: the user's name, this month's totals, the current balance.

This lesson teaches you JSX properly. You will insert JavaScript values into your markup with curly braces, calculate values directly inside JSX, and learn the handful of rules that make JSX different from the HTML you already know, such as `className` instead of `class` and style objects instead of style strings. You will use those rules to build the first real version of Spendly's dashboard header and summary.

### What You'll Build

An updated `App` component that shows Spendly's logo and name, a personal welcome message, and a summary section with income, expense, and balance. The balance is calculated from the other two values and shown in green when it is positive and red when it is negative. The page also gets a labeled search box that you will make functional later in the course.

### What You'll Learn

- ✅ What JSX is and why React uses it
- ✅ How to insert variables and expressions into JSX with curly braces
- ✅ How to call methods, do math, and use the ternary operator inside JSX
- ✅ How JSX attributes differ from HTML: `className`, `htmlFor`, and camelCase names
- ✅ Why every tag must be closed, including `<img />` and `<input />`
- ✅ How to write inline styles as JavaScript objects
- ✅ How fragments and JSX comments work

### What You'll Need

- The Spendly project from Lesson 2
- The development server running with `npm run dev`, and `http://localhost:5173` open in your browser

---

## 2. Insert JavaScript Values with Curly Braces

JSX looks like HTML, but it lives inside a JavaScript file. Before the browser sees it, Vite translates every JSX tag into an ordinary JavaScript function call that creates a description of the element. Because JSX is really JavaScript, you can mix the two: whenever you write curly braces `{ }` inside JSX, you step out of markup and back into JavaScript. Whatever the JavaScript between the braces evaluates to is placed on the page.

### Step 1: Show Variables in the Page

Open `src/App.jsx` and replace its contents with the following code.

```jsx
function App() {
  const appName = "Spendly";
  const userName = "Dina";
  const month = "October 2026";

  return (
    <main>
      <h1>{appName}</h1>
      <p>Welcome back, {userName}!</p>
      <p>Here is your summary for {month}.</p>
    </main>
  );
}

export default App;
```

Here is what this code does:

- The three `const` lines at the top of the function are plain JavaScript. They run every time React calls `App`, before the `return`.
- `<h1>{appName}</h1>` puts the value of `appName` inside the heading. The curly braces tell JSX "this is JavaScript, not text".
- `Welcome back, {userName}!` mixes fixed text with a value. The text around the braces stays exactly as written.
- `{month}` works the same way inside the second paragraph.

Save the file. The browser updates automatically.

What you see in the browser:

```text
Spendly

Welcome back, Dina!

Here is your summary for October 2026.
```

Change `userName` to your own name and save again. The greeting changes, but the JSX did not. This is the core idea of React: the markup describes the shape of the page, and the data fills it in.

### Step 2: Use Expressions Inside Curly Braces

Curly braces accept any JavaScript **expression**, which is any piece of code that produces a value. That includes math, method calls, and the ternary operator from Lesson 1. Replace `src/App.jsx` with this version.

```jsx
function App() {
  const appName = "Spendly";
  const userName = "Dina";
  const month = "October 2026";
  const income = 3400;
  const expense = 177;
  const transactionCount = 5;

  return (
    <main>
      <h1>{appName}</h1>
      <p>Welcome back, {userName.toUpperCase()}!</p>
      <p>Here is your summary for {month}.</p>
      <p>Income: ${income}</p>
      <p>Expense: ${expense}</p>
      <p>Balance: ${income - expense}</p>
      <p>You recorded {transactionCount} transactions this month.</p>
      <p>{income > expense ? "You are saving money. Nice work!" : "You are spending more than you earn."}</p>
    </main>
  );
}

export default App;
```

Here is what is new:

- `{userName.toUpperCase()}` calls a string method. The method returns `"DINA"`, and that value is what appears on the page.
- In `Income: ${income}`, the `$` is not special. It sits outside the braces, so it is plain text, a dollar sign. Only `{income}` is JavaScript. Be careful not to confuse this with template literals, where `${...}` inserts a value; in JSX, braces alone do that job.
- `{income - expense}` calculates the balance right inside the markup.
- The last paragraph uses the ternary operator. If `income > expense` is true, the first string is shown; otherwise, the second one is.

Save the file.

What you see in the browser:

```text
Spendly

Welcome back, DINA!

Here is your summary for October 2026.

Income: $3400

Expense: $177

Balance: $3223

You recorded 5 transactions this month.

You are saving money. Nice work!
```

These are the same totals you calculated in the console in Lesson 1, now on the page. For now the numbers are typed by hand. In Lesson 13, Spendly will calculate them from the transaction list automatically.

---

## 3. Write Attributes the JSX Way

Most HTML attributes work in JSX exactly as you know them: `id`, `src`, `alt`, `type`, `placeholder`, and so on. A few are different, because JSX is JavaScript and some HTML attribute names clash with JavaScript words. In this section you will build Spendly's header and summary and meet those differences one at a time.

### Step 1: Add the Header, Classes, and a Search Box

Replace `src/App.jsx` with the following code.

```jsx
function App() {
  const appName = "Spendly";
  const userName = "Dina";
  const month = "October 2026";
  const income = 3400;
  const expense = 177;
  const balance = income - expense;

  return (
    <main className="app">
      <header className="app-header">
        <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
        <h1>{appName}</h1>
      </header>

      <p>Welcome back, {userName}! Here is your summary for {month}.</p>

      <section className="summary">
        <p>Income: ${income}</p>
        <p>Expense: ${expense}</p>
        <p>Balance: ${balance}</p>
      </section>

      <label htmlFor="search">Search transactions</label>
      <input id="search" type="text" placeholder="e.g. Groceries" />
    </main>
  );
}

export default App;
```

Here is what this code does:

- `const balance = income - expense;` calculates the balance once, before the `return`, and gives it a name. When a calculation is used more than once or gets long, a variable keeps the JSX readable.
- `className="app"` is how you write the HTML `class` attribute in JSX. `class` is a reserved word in JavaScript (it is used to define classes), so React uses `className`. In the browser, it becomes a normal `class` attribute. You will use these classes for styling in Lesson 7.
- `<img ... />` ends with `/>`. In HTML, `<img>` and `<input>` do not need closing tags, but in JSX **every tag must be closed**. Tags with no content close themselves with `/>`.
- `src="/favicon.svg"` points to the file in the `public` folder. Files in `public` are served from the root of the site, so the path starts with `/`.
- `<label htmlFor="search">` is the JSX version of the HTML `for` attribute, which connects a label to an input. `for` is also a reserved word in JavaScript (think of `for` loops), so React uses `htmlFor`.
- `<input id="search" type="text" placeholder="e.g. Groceries" />` is a self-closing input. Clicking the label now moves the cursor into the input, because their `htmlFor` and `id` match.

Save the file.

What you see in the browser:

```text
Spendly

Welcome back, Dina! Here is your summary for October 2026.

Income: $3400

Expense: $177

Balance: $3223

Search transactions
```

The small Vite logo from `favicon.svg` appears next to the heading, and an empty text box with the grey placeholder "e.g. Groceries" appears after the label. Right-click the heading and choose **Inspect** to open the developer tools. In the Elements panel you will see `<main class="app">`: React has turned `className` back into the normal HTML attribute.

### Step 2: Add an Inline Style

In HTML, the `style` attribute is a string such as `style="font-weight: bold"`. In JSX, `style` takes a JavaScript **object** instead, and CSS property names are written in camelCase. Update `src/App.jsx` so the balance paragraph has a style.

```jsx
function App() {
  const appName = "Spendly";
  const userName = "Dina";
  const month = "October 2026";
  const income = 3400;
  const expense = 177;
  const balance = income - expense;

  return (
    <main className="app">
      <header className="app-header">
        <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
        <h1>{appName}</h1>
      </header>

      <p>Welcome back, {userName}! Here is your summary for {month}.</p>

      <section className="summary">
        <p>Income: ${income}</p>
        <p>Expense: ${expense}</p>
        <p style={{ fontWeight: "bold", color: balance >= 0 ? "green" : "red" }}>
          Balance: ${balance}
        </p>
      </section>

      <label htmlFor="search">Search transactions</label>
      <input id="search" type="text" placeholder="e.g. Groceries" />
    </main>
  );
}

export default App;
```

Here is what changed:

- `style={{ ... }}` has two pairs of braces, and they mean different things. The outer pair says "here comes JavaScript". The inner pair is a JavaScript object literal, the same `{ key: value }` syntax you used for transactions in Lesson 1.
- `fontWeight: "bold"` is the CSS property `font-weight` written in camelCase. A hyphen is not allowed in a plain JavaScript property name, so every CSS property with a hyphen is written this way: `background-color` becomes `backgroundColor`, `font-size` becomes `fontSize`.
- `color: balance >= 0 ? "green" : "red"` uses a ternary operator to choose the color from the data. A positive or zero balance is green; a negative balance is red.
- The paragraph's content now sits on its own line between the opening and closing tags. JSX ignores the line breaks and indentation around it, so the text on the page is unchanged.

Save the file. The balance line is now bold and green. Right-click it and choose **Inspect**: the element is rendered as `<p style="font-weight: bold; color: green;">`. React converted the object into a normal CSS string.

---

## 4. Run and Test

Make sure the development server is running, then check the finished page at `http://localhost:5173`.

What you see in the browser:

```text
Spendly

Welcome back, Dina! Here is your summary for October 2026.

Income: $3400

Expense: $177

Balance: $3223

Search transactions
```

Check these details:

- The logo appears to the left of the "Spendly" heading.
- "Balance: $3223" is bold and green.
- Clicking the words "Search transactions" puts the cursor inside the text box.

Now test the ternary operator in the style. Change `const expense = 177;` to `const expense = 3600;` and save. The balance line changes to `Balance: $-200` and turns red, because `balance >= 0` is now false. Change the expense back to `177` before moving on.

Finally, run the linter in a second terminal to make sure the code has no problems.

```bash
npm run lint
```

Output:

```text

> spendly@0.0.0 lint
> oxlint

```

No messages after the header means no problems were found.

---

## 5. JSX Rules Reference

You have now used most of JSX's rules in practice. This section collects them in one place, plus two more you will need soon, so you can come back to it whenever a JSX error appears.

**A component returns one parent element.** A function can only return one value, so the JSX in `return` must have a single outer element. If you need several elements side by side without an extra wrapper in the HTML, use a **fragment**: an empty tag `<>` and `</>`. A fragment groups elements in JSX but adds nothing to the page.

```jsx
function App() {
  return (
    <>
      <h1>Spendly</h1>
      <p>Track where your money goes.</p>
    </>
  );
}

export default App;
```

**Every tag must be closed.** Tags with content need a closing tag (`<p>...</p>`), and tags without content close themselves (`<img />`, `<input />`, `<br />`, `<hr />`).

**Attribute names are camelCase, with two renames.** `class` becomes `className`, and `for` becomes `htmlFor`. Other multi-word attributes use camelCase too, such as `tabIndex`, `readOnly`, and `maxLength`. Event attributes, which you will meet in Lesson 8, follow the same pattern: `onclick` becomes `onClick`.

**`style` takes an object.** Use `style={{ color: "red" }}` with camelCase property names. Most of Spendly's styling will use CSS classes instead, and inline styles only for values that depend on data.

**Curly braces take expressions, not statements.** You can put variables, math, function calls, and ternaries inside braces, because they all produce a value. You cannot put an `if` statement, a `for` loop, or a variable declaration inside them, because those do not produce a value. Do that work before the `return`, as you did with `balance`, or use a ternary.

**Some values render nothing.** Strings and numbers appear on the page as text. `true`, `false`, `null`, and `undefined` render nothing at all, which is useful for showing or hiding content, as you will see in Lesson 6. Plain objects cannot be rendered, and cause an error.

**Comments go inside braces.** Inside JSX, HTML comments (`<!-- -->`) do not work. Wrap a JavaScript block comment in braces instead.

```jsx
function App() {
  return (
    <main>
      {/* The summary section will move into its own component in Lesson 4 */}
      <h1>Spendly</h1>
    </main>
  );
}

export default App;
```

The comment is visible to you in the code but produces nothing on the page.

---

## 6. Fix the Errors in Your Code

These are the JSX mistakes beginners make most often, especially when pasting HTML from somewhere else.

**Error 1: Using `class` instead of `className`.**

HTML copied into a component often still contains `class`.

```jsx
// Wrong
function App() {
  return (
    <main class="app">
      <h1>Spendly</h1>
    </main>
  );
}

export default App;

// Correct
function App() {
  return (
    <main className="app">
      <h1>Spendly</h1>
    </main>
  );
}

export default App;
```

The wrong version still shows the page, so this mistake is easy to miss. Open the browser console (`F12`, then the **Console** tab) and you will see a red warning from React:

```text
Invalid DOM property `class`. Did you mean `className`?
```

React tells you exactly what to change. Always keep the console open while you develop; many React problems are only reported there.

**Error 2: Returning two elements without a parent.**

A component that returns two side-by-side elements has no single value to return.

```jsx
// Wrong
function App() {
  return (
    <h1>Spendly</h1>
    <p>Track where your money goes.</p>
  );
}

export default App;

// Correct
function App() {
  return (
    <>
      <h1>Spendly</h1>
      <p>Track where your money goes.</p>
    </>
  );
}

export default App;
```

The wrong version does not even compile. Instead of the page, the browser shows Vite's error overlay with this message:

```text
[plugin:vite:oxc] Transform failed with 1 error:

[PARSE_ERROR] Adjacent JSX elements must be wrapped in an enclosing tag.
   ╭─[ src/App.jsx:4:5 ]
   │
 4 │     <p>Track where your money goes.</p>
   │     ┬  
   │     ╰── 
   │ 
   │ Help: Did you want a JSX fragment `<>...</>`?
───╯
```

`src/App.jsx:4:5` means line 4, column 5 of the file. The help line even suggests the fix: wrap the elements in a fragment, or in any parent element such as `<main>`.

**Error 3: Leaving an `<input>` unclosed.**

In HTML, `<input>` has no closing tag. In JSX, it must close itself.

```jsx
// Wrong
function App() {
  return (
    <main>
      <label htmlFor="search">Search transactions</label>
      <input id="search" type="text">
    </main>
  );
}

export default App;

// Correct
function App() {
  return (
    <main>
      <label htmlFor="search">Search transactions</label>
      <input id="search" type="text" />
    </main>
  );
}

export default App;
```

The wrong version shows this in the error overlay:

```text
[plugin:vite:oxc] Transform failed with 2 errors:

[PARSE_ERROR] Expected corresponding JSX closing tag for 'input'.
   ╭─[ src/App.jsx:6:7 ]
   │
 5 │       <input id="search" type="text">
   │        ──┬──  
   │          ╰──── Opened here
 6 │     </main>
   │       ──┬─  
   │         ╰─── Expected `</input>`
───╯

[PARSE_ERROR] Unexpected token. Did you mean `{'}'}` or `&rbrace;`?
   ╭─[ src/App.jsx:8:1 ]
   │
 8 │ }
   │ │ 
   │ ╰─ 
───╯
```

JSX treats the unclosed `<input>` as an open tag and then finds `</main>` where it expected `</input>`. The second error is a side effect of the first: once the tags are out of balance, the rest of the file no longer makes sense to the parser. Fix the first error and the second one disappears. Adding ` />` at the end of the input is all it takes.

**Error 4: Putting an object inside curly braces.**

Curly braces can show strings and numbers, but not a whole object.

```jsx
// Wrong
function App() {
  const user = { name: "Dina", city: "Sukabumi" };

  return (
    <main>
      <p>Welcome back, {user}!</p>
    </main>
  );
}

export default App;

// Correct
function App() {
  const user = { name: "Dina", city: "Sukabumi" };

  return (
    <main>
      <p>Welcome back, {user.name}!</p>
    </main>
  );
}

export default App;
```

With the wrong version, the page goes completely blank, and the console shows this error:

```text
Error: Objects are not valid as a React child (found: object with keys {name, city}). If you meant to render a collection of children, use an array instead.
```

React does not know how to turn an object into text, so it stops rendering. The message lists the object's keys, which helps you find it. Pick the property you want to show, such as `user.name`. You will see this error again when working with transactions, because each transaction is an object.

---

## 7. Exercises

**Exercise 1:** Add a "savings rate" line to the summary section that shows what percentage of income is left after expenses. Calculate it as `(balance / income) * 100`, rounded to a whole number with `Math.round`, and display it as `Savings rate: 95%`.

**Exercise 2:** Add a `<footer>` at the bottom of `<main>` that shows `© 2026 Spendly. Made by DINA.` Store the year in a variable named `year`, reuse the existing `appName` and `userName` variables, and show the name in uppercase. Use `&copy;` for the copyright symbol.

**Exercise 3:** Without changing the JSX, make the balance turn red. Which single value do you change, what does the balance line show, and what does the paragraph's `style` attribute look like in the Elements panel afterward?

---

## 8. Solutions

**Solution for Exercise 1 and Exercise 2:**

Both exercises extend the same component, so here is the complete file with both changes.

```jsx
function App() {
  const appName = "Spendly";
  const userName = "Dina";
  const month = "October 2026";
  const income = 3400;
  const expense = 177;
  const balance = income - expense;
  const savingsRate = Math.round((balance / income) * 100);
  const year = 2026;

  return (
    <main className="app">
      <header className="app-header">
        <img src="/favicon.svg" alt="Spendly logo" width="32" height="32" />
        <h1>{appName}</h1>
      </header>

      <p>Welcome back, {userName}! Here is your summary for {month}.</p>

      <section className="summary">
        <p>Income: ${income}</p>
        <p>Expense: ${expense}</p>
        <p style={{ fontWeight: "bold", color: balance >= 0 ? "green" : "red" }}>
          Balance: ${balance}
        </p>
        <p>Savings rate: {savingsRate}%</p>
      </section>

      <label htmlFor="search">Search transactions</label>
      <input id="search" type="text" placeholder="e.g. Groceries" />

      <footer>
        <p>&copy; {year} {appName}. Made by {userName.toUpperCase()}.</p>
      </footer>
    </main>
  );
}

export default App;
```

For Exercise 1, `savingsRate` is calculated before the `return`, because the formula is long enough to make the JSX hard to read. `3223 / 3400` is about `0.948`, times `100` is `94.8`, and `Math.round` turns it into `95`. The `%` after the braces is plain text, just like the `$` before the amounts.

For Exercise 2, the footer combines three values with plain text. `&copy;` is an HTML entity that JSX understands, and it displays as `©`. The spaces between `{year}` and `{appName}` are kept because they are part of the text on the same line.

What you see in the browser:

```text
Spendly

Welcome back, Dina! Here is your summary for October 2026.

Income: $3400

Expense: $177

Balance: $3223

Savings rate: 95%

Search transactions

© 2026 Spendly. Made by DINA.
```

**Solution for Exercise 3:**

Change only the expense value, so that it is larger than the income.

```jsx
const expense = 3600;
```

The balance becomes `3400 - 3600 = -200`, so the condition `balance >= 0` is false and the ternary returns `"red"`. The page shows `Expense: $3600` and `Balance: $-200`, and in the Elements panel the paragraph is rendered as `<p style="font-weight: bold; color: red;">`. The JSX never changed; only the data did, and React updated the style to match. A minus sign after the dollar sign looks a little odd, and you will fix how amounts are formatted when you build the `Summary` component.

---

## Next Up - Lesson 4

In this lesson you learned that JSX is JavaScript with an HTML-like syntax. You inserted variables and expressions with curly braces, used method calls, math, and the ternary operator inside markup, and learned the rules that make JSX different from HTML: `className`, `htmlFor`, self-closing tags, style objects, a single parent element, fragments, and comments. Spendly now has a header, a welcome message, a summary with a colored balance, and a search box.

All of that lives in one long `App` function, and it is already getting crowded. In Lesson 4, you will split the page into components such as `Header`, `Summary`, and `TransactionList`, move each one into its own file, and connect them with `import` and `export`.
