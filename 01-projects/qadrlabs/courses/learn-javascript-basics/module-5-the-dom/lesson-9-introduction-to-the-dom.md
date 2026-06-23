## 1. Before You Begin

So far, every program you have written has printed output to the console. Real web pages do not use the console - they display content to users through HTML elements. JavaScript can reach into the page's HTML, read any element, change its text, update its styles, add or remove CSS classes, and modify its attributes. The interface that makes all of this possible is the DOM.

The DOM (Document Object Model) is the browser's in-memory representation of an HTML page as a tree of JavaScript objects. Every HTML element becomes a node in that tree. JavaScript can navigate the tree, select specific nodes, and modify them - and the browser instantly reflects those changes on screen.

### What You'll Build

You will create an HTML page with headings, paragraphs, a list, a button, and a link, then write `script.js` to select those elements, read their content, change their text and styles, toggle CSS classes, and modify attributes - all without reloading the page.

### What You'll Learn

- ✅ What the DOM is (HTML as a JavaScript object tree)
- ✅ `document.getElementById()` and `document.querySelector()`
- ✅ `document.querySelectorAll()` for multiple elements
- ✅ Reading and changing `textContent` and `innerHTML`
- ✅ Modifying styles with `element.style`
- ✅ Adding and removing CSS classes with `classList`
- ✅ Reading and changing attributes with `getAttribute` and `setAttribute`

### What You'll Need

- Lesson 8 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-09`. Inside it, create three files: `index.html`, `style.css`, and `script.js`.

---

## 3. Selecting Elements

Before JavaScript can change an element, it must first find it. The DOM provides several methods for selecting elements. Each one takes a different kind of identifier and returns a different kind of result.

### Step 1: Create index.html

Add the following to `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOM Basics</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1 id="title">Hello, DOM!</h1>
    <p class="description">This paragraph will be changed by JavaScript.</p>
    <p class="description">This is the second paragraph.</p>

    <ul id="fruit-list">
        <li>Apple</li>
        <li>Banana</li>
        <li class="highlight">Cherry</li>
    </ul>

    <button id="change-btn">Change Title</button>
    <a href="https://example.com" id="link">Visit Example</a>

    <script src="script.js"></script>
</body>
</html>
```

Each element that JavaScript will interact with has either an `id` or a `class` attribute. `id` attributes must be unique within the page - no two elements should share the same `id`. `class` attributes can be shared - multiple elements can have the same class name.

### Step 2: Create style.css

Add the following to `style.css`:

```css
body { font-family: Arial, sans-serif; max-width: 600px; margin: 20px auto; padding: 0 15px; }
.highlight { background: #fef3c7; padding: 4px 8px; }
.active { background: #d1fae5; padding: 4px 8px; font-weight: bold; }
button { padding: 8px 16px; background: #2563eb; color: white; border: none; border-radius: 4px; cursor: pointer; }
```

The `.highlight` and `.active` classes are defined here so that JavaScript can add and remove them from elements. The visual change happens automatically when the class is present or absent.

### Step 3: Write script.js

Add the following to `script.js`:

```javascript
const title = document.getElementById("title");
console.log("Title:", title.textContent);

const firstDesc = document.querySelector(".description");
console.log("First p:", firstDesc.textContent);

const btn = document.querySelector("#change-btn");
const highlightItem = document.querySelector("li.highlight");

const allDesc = document.querySelectorAll(".description");
console.log("Paragraph count:", allDesc.length);
allDesc.forEach(p => console.log("  -", p.textContent));

const allItems = document.querySelectorAll("#fruit-list li");
console.log("List items:", allItems.length);
```

`document.getElementById("title")` searches the entire page for an element with the `id` attribute equal to `"title"` and returns that single element. If no element with that id exists, it returns `null`.

`document.querySelector(".description")` accepts any valid CSS selector and returns the first element that matches. `".description"` selects by class, `"#change-btn"` selects by id, and `"li.highlight"` selects `<li>` elements that also have the `highlight` class. `querySelector` always returns one element (or `null`), even if multiple elements match.

`document.querySelectorAll(".description")` returns a NodeList containing all elements that match the selector. A NodeList is similar to an array but is not one. It supports `forEach` and index access, but methods like `map` and `filter` are not available unless you first convert it with `Array.from(nodeList)` or `[...nodeList]`.

`document.querySelectorAll("#fruit-list li")` passes a descendant selector: it selects all `<li>` elements that are inside the element with `id="fruit-list"`.

---

## 4. Changing Content and Styles

Once you have a reference to a DOM element, you can read and change almost any aspect of it: the text it displays, the HTML inside it, its inline styles, its CSS classes, and its HTML attributes.

Add the following to `script.js`:

```javascript
title.textContent = "DOM is Powerful!";

firstDesc.innerHTML = "This was changed by <strong>JavaScript</strong>.";

title.style.color = "#2563eb";
title.style.fontSize = "2rem";
title.style.textAlign = "center";

highlightItem.classList.add("active");
highlightItem.classList.remove("highlight");

const link = document.getElementById("link");
console.log("href:", link.getAttribute("href"));
link.setAttribute("target", "_blank");
```

Setting `textContent` replaces all visible text inside an element. Any HTML tags in the new string are treated as literal text, not as markup. This makes `textContent` safe to use with user-provided input.

Setting `innerHTML` replaces the element's inner content and parses HTML tags within the string. This allows inserting formatted content but is dangerous when the string contains user input, because a malicious user could inject script tags or event-handling attributes.

`element.style.property` sets an inline style directly on the element. CSS property names with hyphens are written in camelCase in JavaScript: `font-size` becomes `fontSize`, `background-color` becomes `backgroundColor`, and `text-align` becomes `textAlign`. Inline styles have the highest specificity and override any class-based styles.

`classList.add("active")` adds the class `"active"` to the element's class list without disturbing any existing classes. `classList.remove("highlight")` removes that specific class. `classList.toggle("className")` adds the class if it is absent and removes it if it is present - useful for toggle buttons.

`getAttribute("href")` reads the current value of the `href` attribute and returns it as a string. `setAttribute("target", "_blank")` adds or updates the `target` attribute on the element.

---

## 5. Fix the Errors in Your Code

Three DOM mistakes cause the majority of JavaScript errors that beginners encounter. Each one has a predictable root cause and a straightforward fix.

**Error 1: Selecting an element before the DOM has loaded.**

When a `<script>` tag in `<head>` runs, the browser has not yet parsed the `<body>` elements. Any call to `getElementById` or `querySelector` returns `null` because the element does not exist in the DOM yet.

```html
<!-- Wrong: script runs before body elements are parsed -->
<head>
    <script src="script.js"></script>
</head>
<body>
    <h1 id="title">Hello</h1>
</body>

<!-- Correct: script runs after all body elements exist -->
<body>
    <h1 id="title">Hello</h1>
    <script src="script.js"></script>
</body>
```

Placing `<script>` at the bottom of `<body>` guarantees that every element in the page exists before your JavaScript tries to select them. Alternatively, adding the `defer` attribute to a `<head>` script (`<script defer src="script.js">`) tells the browser to execute the script only after the HTML is fully parsed.

**Error 2: Calling array methods directly on a NodeList.**

`querySelectorAll` returns a NodeList, not a true JavaScript array. While a NodeList supports `forEach` and index access, methods like `map`, `filter`, and `reduce` are not available on it.

```javascript
// Wrong: NodeList does not have a .map() method
const items = document.querySelectorAll("li");
const texts = items.map(item => item.textContent);

// Correct: convert to a real array first
const texts = Array.from(items).map(item => item.textContent);
// or using spread:
const texts = [...items].map(item => item.textContent);
```

`Array.from(nodeList)` creates a true array from the NodeList, enabling all array methods. The spread syntax `[...nodeList]` achieves the same result.

**Error 3: Writing CSS property names with hyphens in JavaScript.**

In CSS, multi-word property names use hyphens. In JavaScript, the same properties are accessed using camelCase because hyphens are interpreted as the subtraction operator.

```javascript
// Wrong: interpreted as title.style.font minus size, throws a syntax error
title.style.font-size = "20px";

// Correct: camelCase version of the CSS property name
title.style.fontSize = "20px";
```

Every hyphenated CSS property has a camelCase JavaScript equivalent: `background-color` is `backgroundColor`, `border-radius` is `borderRadius`, `margin-top` is `marginTop`. When in doubt, write the CSS property name and capitalize the letter after each hyphen.

---

## 6. Exercises

**Exercise 1:** Create an HTML page with three paragraphs. Use `querySelectorAll` to select all of them, then use a `forEach` loop to change each paragraph's text color to a different color (use an array of three colors and index into it).

**Exercise 2:** Create an HTML page with a single `<h1>` element. Use JavaScript to change its text, color, background color, padding, and border-radius so it looks like a styled badge.

**Exercise 3:** Create an HTML page with an unordered list of five items. Use JavaScript to select all `<li>` elements and add the class `"highlight"` to every even-indexed item (indexes 0, 2, 4). Define the `.highlight` class in a `<style>` block with a background color.

---

## 7. Solutions

**Solution for Exercise 1:**

Add three paragraphs to your HTML, then write the following in `script.js`:

```javascript
const colors = ["#e11d48", "#16a34a", "#2563eb"];
document.querySelectorAll("p").forEach((p, i) => {
    p.style.color = colors[i % colors.length];
});
```

`querySelectorAll("p")` selects all paragraph elements on the page. `forEach` provides both the element and its index. `i % colors.length` cycles through the colors array: when `i` is `0`, `1`, or `2`, it maps to indexes `0`, `1`, and `2`. If there were more paragraphs than colors, the modulo would wrap back to `0` and repeat the cycle.

**Solution for Exercise 2:**

Add `<h1 id="badge">My Badge</h1>` to your HTML, then write the following in `script.js`:

```javascript
const h = document.querySelector("h1");
h.textContent = "JavaScript Badge";
h.style.color = "white";
h.style.background = "#2563eb";
h.style.padding = "10px 20px";
h.style.borderRadius = "20px";
h.style.display = "inline-block";
```

Setting `display` to `"inline-block"` prevents the heading from stretching across the full width of the page, so the background color and border-radius only surround the text itself rather than the entire line. Each `style` property assignment applies to the element immediately.

**Solution for Exercise 3:**

Add five `<li>` elements inside a `<ul>` to your HTML, define `.highlight { background: #fef9c3; }` in a `<style>` block, then write the following in `script.js`:

```javascript
document.querySelectorAll("li").forEach((li, i) => {
    if (i % 2 === 0) {
        li.classList.add("highlight");
    }
});
```

`i % 2 === 0` is true for indexes `0`, `2`, and `4`, which are the even-indexed items. `classList.add("highlight")` applies the class to those specific elements. The list items at indexes `1` and `3` are left unstyled.

---

## Next Up - Lesson 10

The DOM is the browser's representation of an HTML page as a tree of JavaScript objects. `document.getElementById()` selects a single element by its unique id. `document.querySelector()` selects the first element matching any CSS selector. `document.querySelectorAll()` returns a NodeList of all matching elements, which must be converted to an array before using methods like `map`. `textContent` changes visible text safely. `innerHTML` changes HTML markup but is unsafe with user input. `element.style.propertyName` sets inline styles using camelCase property names. `classList.add()`, `classList.remove()`, and `classList.toggle()` manage CSS classes. `getAttribute()` and `setAttribute()` read and write HTML attributes.

In Lesson 10, you will learn how to create new HTML elements with JavaScript, insert them into the page, and remove existing elements to build fully dynamic user interfaces.