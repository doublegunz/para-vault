## 1. Before You Begin

JavaScript can be written directly in the browser console or in a `.js` file linked to an HTML page. Both approaches are useful and serve different purposes. The console is ideal for quick experiments - you type a line and see the result immediately. External files are how real projects are built - your JavaScript lives in a separate file and runs every time the page loads.

In Lesson 1, you learned what JavaScript does and why it exists. In this lesson, you will write actual JavaScript for the first time using both approaches.

### What You'll Build

You will write JavaScript in the browser console, create an external `.js` file linked to an HTML page, and use `console.log()` and `document.getElementById()` to display output both in the console and on the page itself.

### What You'll Learn

- ✅ How to open the browser console (DevTools)
- ✅ Writing JavaScript directly in the console
- ✅ Linking a `.js` file to an HTML page with `<script>`
- ✅ Output methods: `console.log()`, `alert()`, `document.write()`
- ✅ Where to place the `<script>` tag (head vs body)
- ✅ Comments in JavaScript

### What You'll Need

- VS Code installed
- Chrome browser
- The `learn-html-css` folder or a new `learn-javascript` folder

---

## 2. Setup

Before writing any code, you need a dedicated folder for this lesson. Create a folder called `learn-javascript` on your computer. Open it in VS Code by clicking **File** then **Open Folder**. Inside the `learn-javascript` folder, create a subfolder called `lesson-02` using the VS Code Explorer panel.

---

## 3. The Browser Console

The browser console is a built-in tool that lets you run JavaScript instantly without creating any files. It is the fastest way to test a line of code or check the value of a variable. Every JavaScript developer uses the console daily, and you will use it throughout this course.

### Step 1: Open Chrome DevTools

Open Chrome. Press **F12** (or Ctrl+Shift+I, or right-click anywhere on the page and select **Inspect**). Click the **Console** tab at the top of the DevTools panel. You will see a cursor waiting for input.

### Step 2: Type JavaScript in the Console

The console evaluates any JavaScript expression you type and shows the result immediately. Start with a simple arithmetic expression.

```javascript
2 + 3
```

The console responds with `5`. It evaluated the expression and printed the result. Now try a string value.

```javascript
"Hello, World!"
```

The console responds with `"Hello, World!"`. Strings are returned as-is. Now try the `console.log()` function, which is how JavaScript explicitly sends a message to the console.

```javascript
console.log("Hello from the console!");
```

The console prints `Hello from the console!` without the surrounding quotes. `console.log()` is distinct from typing an expression directly: it is a deliberate output command you write in your code, while typing an expression is only possible in the console itself.

The console is perfect for quick experiments. You will use it throughout this course to test snippets of code before adding them to a file.

---

## 4. Your First HTML and JavaScript Page

The console is useful for experiments, but real projects require JavaScript written in a file. The simplest way to add JavaScript to a web page is with an inline `<script>` block inside the HTML file itself.

### Step 1: Create the File

Right-click on the `lesson-02` folder in the VS Code Explorer panel, select **New File**, and type `index.html`.

### Step 2: Write the Code

Add the following to `index.html`. Notice that the `<script>` block is placed at the bottom of `<body>`, just before the closing `</body>` tag.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My First JavaScript</title>
</head>
<body>
    <h1>Hello, JavaScript!</h1>
    <p id="output"></p>

    <script>
        console.log("Script loaded!");
        document.getElementById("output").textContent = "This text was set by JavaScript.";
    </script>
</body>
</html>
```

`console.log("Script loaded!")` sends a message to the browser console, which you can see by opening DevTools (F12). `document.getElementById("output")` finds the `<p>` element whose `id` attribute is `"output"`. Setting `.textContent` on that element replaces whatever text is inside it with the string you provide. Because the `<script>` is at the bottom of `<body>`, the `<p id="output">` element already exists in the page by the time JavaScript tries to find it.

### Step 3: Save and Open

Press **Ctrl+S**. Open `index.html` with Live Server, or double-click the file to open it in Chrome. You should see the heading and a paragraph that reads "This text was set by JavaScript." Open the console (F12) to confirm you also see "Script loaded!" there.

---

## 5. External JavaScript File

Placing JavaScript directly inside `<script>` blocks in your HTML works for small examples, but it creates a maintenance problem as projects grow. The industry standard is to write JavaScript in separate `.js` files and link them to your HTML, exactly as you link external CSS files.

### Step 1: Create the JavaScript File

Right-click on the `lesson-02` folder in the VS Code Explorer panel, select **New File**, and type `script.js`.

### Step 2: Write the JavaScript

Add the following to `script.js`.

```javascript
// This is a single-line comment

/*
  This is a
  multi-line comment
*/

console.log("Hello from script.js!");
console.log("2 + 3 =", 2 + 3);

document.getElementById("demo").textContent = "JavaScript is working!";
```

Single-line comments begin with `//`. Everything on that line to the right of `//` is ignored by JavaScript. Multi-line comments begin with `/*` and end with `*/`. Anything between those markers, across any number of lines, is ignored. Use comments to explain why code exists, not just what it does.

`console.log("2 + 3 =", 2 + 3)` passes two arguments to `console.log()`. When you pass multiple arguments, they are printed on the same line separated by a space. The second argument `2 + 3` is evaluated to `5` before being printed, so the console shows `2 + 3 = 5`.

### Step 3: Create the HTML File

Right-click on `lesson-02`, select **New File**, and type `external.html`. Add the following content.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>External Script</title>
</head>
<body>
    <h1>External JavaScript</h1>
    <p id="demo">This will be changed by JavaScript.</p>

    <script src="script.js"></script>
</body>
</html>
```

`<script src="script.js">` links the external JavaScript file to this HTML page. The `src` attribute contains the file path, which works exactly like the `href` attribute on a CSS `<link>` tag. The browser downloads `script.js` and executes it at the point where the `<script>` tag appears. Placing it at the bottom of `<body>` ensures all HTML elements are available to JavaScript before the script runs.

### Step 4: Save and Open

Press **Ctrl+S** for both files. Open `external.html` with Live Server. The paragraph text should change from "This will be changed by JavaScript." to "JavaScript is working!" and the console should show both log messages.

External `.js` files have three advantages over inline scripts: they keep HTML files clean and focused on structure, the same file can be linked by multiple pages without duplicating code, and browsers cache the file so it does not need to be re-downloaded on subsequent page visits.

---

## 6. Output Methods

There are four ways JavaScript can produce output. Each one targets a different location, which makes each one appropriate for different situations.

| Method | Output Location | Use Case |
|--------|----------------|----------|
| `console.log()` | Browser console (F12) | Debugging and development |
| `alert()` | Popup dialog box | Quick testing only |
| `document.write()` | Directly into the page body | Avoid entirely |
| `element.textContent` | A specific HTML element | Updating page content |

`console.log()` is the tool you will use most. It accepts any number of arguments, evaluates each one, and prints them to the console separated by spaces. `alert()` is useful for a quick sanity check but disrupts the user's experience and should never appear in finished projects. `document.write()` overwrites the entire page content when called after the page loads, which makes it destructive and unreliable - it exists for historical reasons only. `element.textContent` is the correct way to update the text inside any HTML element and is what you will use throughout this course to display dynamic content.

---

## 7. Fix the Errors in Your Code

Three mistakes appear very consistently when developers first link JavaScript to an HTML page. Each one prevents the script from working, but each has a clear and specific fix.

**Error 1: Placing `<script>` in `<head>` without `defer`.**

When a browser encounters a `<script>` tag in the `<head>`, it immediately downloads and executes the script before parsing the rest of the page. This means the `<body>` elements do not exist yet when the script runs, so any call to `document.getElementById()` returns `null`.

```html
<!-- Wrong: script runs before body elements exist -->
<head>
    <script src="script.js"></script>
</head>
<body>
    <p id="demo">Hello</p>
</body>

<!-- Correct: script runs after all body elements are parsed -->
<body>
    <p id="demo">Hello</p>

    <script src="script.js"></script>
</body>
```

Moving `<script>` to the bottom of `<body>` guarantees that every HTML element on the page exists before JavaScript tries to access them. If you prefer to keep `<script>` in `<head>`, add the `defer` attribute: `<script defer src="script.js">`. The `defer` attribute tells the browser to download the script in the background and execute it only after the HTML has been fully parsed.

**Error 2: A typo in the `src` filename.**

The `src` attribute value must match the actual filename exactly, including capitalization and extension. A single character difference means the browser cannot find the file and the script silently fails to load.

```html
<!-- Wrong: file is named "script.js" but src says "scripts.js" -->
<script src="scripts.js"></script>

<!-- Correct: filename matches exactly -->
<script src="script.js"></script>
```

If your script is not running and you see no output, open the browser console (F12). A failed file load produces a clear error message showing the path the browser tried to access, which makes the typo easy to spot.

**Error 3: Using a self-closing `<script>` tag.**

In HTML, `<script>` cannot be self-closed with `/>`. Unlike `<img>` or `<br>`, the `<script>` tag requires a separate, explicit closing tag. A self-closed `<script>` is treated as an unclosed tag and the browser may not load the file at all.

```html
<!-- Wrong: script cannot be self-closing -->
<script src="script.js" />

<!-- Correct: always use a full closing tag -->
<script src="script.js"></script>
```

This rule applies whether the `<script>` tag links an external file using `src` or contains inline JavaScript between the tags.

---

## 8. Exercises

**Exercise 1:** Create `exercise-1.html` with an `<h1>` and three `<p>` elements with `id` attributes: `"p1"`, `"p2"`, and `"p3"`. In a separate `exercise-1.js` file, use `document.getElementById().textContent` to set each paragraph to a different message. Link the JS file at the bottom of `<body>`.

**Exercise 2:** Open the browser console. Type each of the following expressions one at a time and observe the result: `typeof "hello"`, `typeof 42`, `typeof true`, `typeof undefined`, `typeof null`. Write down what each one returns. We will explain these data types fully in Lesson 3.

**Exercise 3:** Create a file `math.js` and write five `console.log()` statements: one each for `10 + 5`, `10 - 5`, `10 * 5`, `10 / 5`, and `10 % 3`. Link it to an HTML file and confirm all five results appear in the browser console.

---

## 9. Solutions

**Solution for Exercise 1:**

Create `exercise-1.html` with the following content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exercise 1</title>
</head>
<body>
    <h1>My Page</h1>
    <p id="p1"></p>
    <p id="p2"></p>
    <p id="p3"></p>
    <script src="exercise-1.js"></script>
</body>
</html>
```

Create `exercise-1.js` with the following content:

```javascript
document.getElementById("p1").textContent = "This is paragraph one.";
document.getElementById("p2").textContent = "This is paragraph two.";
document.getElementById("p3").textContent = "This is paragraph three.";
```

Each call to `document.getElementById()` returns the element whose `id` matches the string argument. Setting `.textContent` on the returned element replaces the visible text inside that element. Because the `<p>` tags start empty, the page initially shows nothing - the text only appears after JavaScript runs.

**Solution for Exercise 2:**

Open the browser console and type each expression:

```
typeof "hello"    → "string"
typeof 42         → "number"
typeof true       → "boolean"
typeof undefined  → "undefined"
typeof null       → "object"
```

`typeof` is a JavaScript operator that returns a string describing the data type of its operand. The result for `typeof null` being `"object"` is a well-known quirk of JavaScript that dates back to its original 1995 implementation. `null` is not actually an object. It is an intentional empty value, but the operator returns `"object"` for historical reasons that cannot be changed without breaking existing code.

**Solution for Exercise 3:**

Create `math.js` with the following content:

```javascript
console.log("10 + 5 =", 10 + 5);
console.log("10 - 5 =", 10 - 5);
console.log("10 * 5 =", 10 * 5);
console.log("10 / 5 =", 10 / 5);
console.log("10 % 3 =", 10 % 3);
```

The `%` operator is the modulo operator. It returns the remainder after dividing the first number by the second. `10 % 3` equals `1` because 3 goes into 10 three times (3 x 3 = 9) with a remainder of 1. The modulo operator is useful whenever you need to determine if a number is even or odd, or to cycle through a sequence of values.

---

## Next Up - Lesson 3

JavaScript runs in the browser's built-in JavaScript engine. You can test code instantly in the console by pressing F12 in Chrome. For real projects, JavaScript belongs in external `.js` files linked with `<script src="..."></script>` at the bottom of `<body>`. `console.log()` is the primary tool for printing values during development. Comments use `//` for a single line and `/* */` for a block. Placing `<script>` in `<head>` without the `defer` attribute causes scripts to run before the page elements exist.

In Lesson 3, you will learn about variables, data types, and operators - the building blocks of every JavaScript program.