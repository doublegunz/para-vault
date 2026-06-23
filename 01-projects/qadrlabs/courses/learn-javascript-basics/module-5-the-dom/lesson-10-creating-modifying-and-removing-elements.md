## 1. Before You Begin

In Lesson 9, you learned to select existing HTML elements and change their content, styles, and classes. But the most powerful DOM capability is the ability to create elements that did not exist when the page first loaded. Every time a to-do app adds a task card, a chat application displays a new message, or a product page renders search results - that is JavaScript building new HTML structure at runtime.

This lesson teaches how to create elements, configure them, assemble them into components, insert them into the page, and remove them on demand.

### What You'll Build

You will build a dynamic list application where users type an item name, click a button, and a new card appears on the page - complete with a delete button that removes it. The page also demonstrates rendering a product array into cards automatically on load.

### What You'll Learn

- ✅ `document.createElement()` to create new elements
- ✅ `parent.appendChild()` and `parent.prepend()` to insert elements
- ✅ `element.remove()` to delete elements
- ✅ `innerHTML` vs `createElement` for security and performance
- ✅ Building UI components dynamically from data arrays

### What You'll Need

- Lesson 9 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-10`. Inside it, create `index.html` and `script.js`. The HTML for this lesson is written as part of Step 1 below.

---

## 3. Creating and Inserting Elements

The standard workflow for adding a new element to the page has three steps: create the element, configure it (set its text, classes, and event listeners), and then insert it into the parent element where it should appear.

### Step 1: Create index.html

Add the following to `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dynamic Elements</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 20px auto; }
        .card { border: 1px solid #e2e8f0; padding: 16px; margin: 8px 0; border-radius: 8px; display: flex; justify-content: space-between; align-items: center; }
        .btn-add { background: #2563eb; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; }
        .btn-delete { background: #dc2626; color: white; border: none; padding: 4px 10px; border-radius: 4px; cursor: pointer; font-size: 0.8em; }
        input { padding: 8px; border: 1px solid #ccc; border-radius: 4px; margin-right: 8px; }
    </style>
</head>
<body>
    <h1>Dynamic List</h1>
    <div>
        <input type="text" id="item-input" placeholder="Enter item...">
        <button class="btn-add" id="add-btn">Add Item</button>
    </div>
    <div id="list"></div>
    <script src="script.js"></script>
</body>
</html>
```

The page provides only the input, button, and an empty container `<div id="list">`. Every card that appears in the list will be created entirely by JavaScript at runtime. The CSS classes `.card`, `.btn-add`, and `.btn-delete` are defined in the `<style>` block so that JavaScript can assign them to newly created elements without needing an external file.

### Step 2: Write script.js

Add the following to `script.js`:

```javascript
const input = document.getElementById("item-input");
const addBtn = document.getElementById("add-btn");
const list = document.getElementById("list");

function addItem(text) {
    const card = document.createElement("div");
    card.className = "card";

    const span = document.createElement("span");
    span.textContent = text;

    const deleteBtn = document.createElement("button");
    deleteBtn.textContent = "Delete";
    deleteBtn.className = "btn-delete";
    deleteBtn.addEventListener("click", () => card.remove());

    card.appendChild(span);
    card.appendChild(deleteBtn);
    list.appendChild(card);
}

addBtn.addEventListener("click", () => {
    const text = input.value.trim();
    if (text) {
        addItem(text);
        input.value = "";
        input.focus();
    }
});

input.addEventListener("keydown", (e) => {
    if (e.key === "Enter") addBtn.click();
});

["Learn JavaScript", "Practice DOM", "Build a project"].forEach(addItem);
```

`document.createElement("div")` creates a new `<div>` element in memory. It does not appear on the page until it is inserted into the DOM. `card.className = "card"` assigns the CSS class, which applies the border, padding, and flex layout from the stylesheet.

`span.textContent = text` sets the visible text inside the span. Using `textContent` rather than `innerHTML` is safe because it treats the value as plain text, never as HTML. If the text contained something like `<script>alert(1)</script>`, `textContent` would display it literally without executing anything.

`deleteBtn.addEventListener("click", () => card.remove())` attaches a click handler to the delete button. When clicked, `card.remove()` removes the entire card element from the DOM. The key insight is that the callback captures a reference to `card` via closure, so when the button is clicked later, it still knows exactly which card to remove.

`card.appendChild(span)` and `card.appendChild(deleteBtn)` insert the span and button as children of the card in that order. `list.appendChild(card)` inserts the completed card at the bottom of the list container.

After the button click handler is set up, `addBtn.click()` is triggered programmatically when the user presses Enter in the input field. `input.value.trim()` removes leading and trailing whitespace so that an input containing only spaces is treated as empty.

The final line uses `forEach` on an array of strings to pre-populate the list with three sample items when the page loads, demonstrating that `addItem` works equally well for both programmatic calls and user interactions.

---

## 4. Building UI from Data

A common pattern in modern web development is taking an array of data objects and rendering each one as a UI component. Rather than hardcoding the HTML for each item, a function builds the element structure from the data and inserts it into the page.

Add the following to `script.js` (or in a separate file for experimentation):

```javascript
const products = [
    { name: "Laptop", price: 8500000 },
    { name: "Mouse", price: 150000 },
    { name: "Keyboard", price: 750000 },
];

function renderProducts(data) {
    const container = document.getElementById("list");
    container.innerHTML = "";

    data.forEach(product => {
        const card = document.createElement("div");
        card.className = "card";
        card.innerHTML = `
            <span><strong>${product.name}</strong> - Rp ${product.price.toLocaleString()}</span>
            <button class="btn-delete">Remove</button>
        `;
        card.querySelector(".btn-delete").addEventListener("click", () => card.remove());
        container.appendChild(card);
    });
}

renderProducts(products);
```

`container.innerHTML = ""` clears any existing content from the container before rendering. This ensures that calling `renderProducts` a second time replaces the current cards rather than appending duplicates.

`card.innerHTML = \`...\`` uses a template literal to set the card's inner HTML in a single statement. This is acceptable here because all the data comes from the `products` array, which is hardcoded in the program and not supplied by the user. The `${product.name}` and `${product.price.toLocaleString()}` expressions embed controlled values that cannot contain malicious scripts.

`card.querySelector(".btn-delete")` selects the button inside the newly created card and attaches a click listener immediately after the `innerHTML` is set. This listener must be attached after `innerHTML` is assigned because setting `innerHTML` destroys and recreates the inner DOM, which would remove any listeners attached before that point.

---

## 5. innerHTML vs createElement

Choosing between `innerHTML` and `createElement` is a recurring decision in DOM manipulation. Each approach has distinct tradeoffs that determine when to use it.

| Approach | Advantages | Disadvantages |
|----------|-----------|---------------|
| `innerHTML` | Concise, readable for multi-element templates | Risk of XSS with user input; destroys existing child elements and their listeners |
| `createElement` | Safe with any input; precise control over each node | More lines of code for complex structures |

The deciding factor is the source of the data. When data comes from the user (form inputs, URL parameters, third-party APIs), always use `createElement` and `textContent` to prevent cross-site scripting (XSS) attacks. When data comes from your own code or a trusted internal source, `innerHTML` with template literals is acceptable and more readable for complex markup.

---

## 6. Fix the Errors in Your Code

Three mistakes appear frequently when developers first work with dynamic DOM creation. Each one either creates a security vulnerability or produces unexpected behavior.

**Error 1: Using `innerHTML` with unsanitized user input.**

Setting `innerHTML` to a value that contains HTML tags executes those tags. If a user can influence the value, they can inject scripts or event handlers that run in the context of your page.

```javascript
// Wrong: if userInput contains HTML, it will be parsed and executed
const userInput = '<img src=x onerror="alert(1)">';
container.innerHTML = userInput;

// Correct: textContent treats the value as plain text, never as HTML
const span = document.createElement("span");
span.textContent = userInput;
container.appendChild(span);
```

The wrong version would cause the browser to parse the injected image tag and execute the `onerror` handler, which is a classic XSS attack. The correct version renders the string exactly as the user typed it, angle brackets and all, as visible text with no script execution.

**Error 2: Calling methods on a DOM element that does not exist yet.**

If `getElementById` or `querySelector` cannot find a matching element, it returns `null`. Calling any method on `null` throws a `TypeError` that stops the script.

```javascript
// Wrong: if #btn does not exist, getElementById returns null and .addEventListener throws
document.getElementById("btn").addEventListener("click", handler);

// Correct: check for null before using the reference
const btn = document.getElementById("btn");
if (btn) {
    btn.addEventListener("click", handler);
}
```

Always check that a selector returned a valid element before calling methods on it, especially when the element might not exist on every page where your script runs.

**Error 3: Removing only the button instead of the parent card.**

When a delete button is inside a card, calling `deleteBtn.remove()` removes only the button, leaving the rest of the card visible. The entire card must be removed.

```javascript
// Wrong: removes only the button, the card stays on the page
deleteBtn.addEventListener("click", () => deleteBtn.remove());

// Correct: remove the entire card, not just the button inside it
deleteBtn.addEventListener("click", () => card.remove());
```

When a closure is available (the `card` variable is in scope when the listener is attached), using it directly is the cleanest solution. If the parent is not in scope, `deleteBtn.parentElement.remove()` navigates to the parent and removes it.

---

## 7. Exercises

**Exercise 1:** Create an HTML page with an empty `<div id="palette">`. Write JavaScript that creates 10 `<div>` elements, each with a randomly generated hex background color. Display the hex code as text inside each div. Append all ten divs to the palette container.

**Exercise 2:** Build a note-taking app with an `<input>` and an **Add Note** button. When the button is clicked, create a card containing the input text and a **Delete** button. Use `textContent` to set the note text (never `innerHTML`) so user input is safe.

**Exercise 3:** Given an array of student objects `{ name, grade }`, write a function `renderTable(students)` that creates an HTML `<table>` with a header row and one data row per student. Use `createElement` for every element and `textContent` for all values. Append the completed table to `document.body`.

---

## 8. Solutions

**Solution for Exercise 1:**

Add `<div id="palette"></div>` to your HTML, then write the following in `script.js`:

```javascript
const palette = document.getElementById("palette");

for (let i = 0; i < 10; i++) {
    const randomHex = Math.floor(Math.random() * 16777215).toString(16).padStart(6, "0");
    const color = "#" + randomHex;

    const div = document.createElement("div");
    div.style.background = color;
    div.style.color = "white";
    div.style.padding = "20px";
    div.style.margin = "4px";
    div.style.display = "inline-block";
    div.style.borderRadius = "4px";
    div.textContent = color;

    palette.appendChild(div);
}
```

`Math.random() * 16777215` produces a random decimal up to `16777215`, which is `#FFFFFF` in decimal. `Math.floor()` rounds it to a whole number. `.toString(16)` converts it to a hexadecimal string. `.padStart(6, "0")` ensures the string is always six characters long by padding with leading zeros - without this, colors like `#0000FF` would be generated as `"ff"` instead of `"0000ff"`.

**Solution for Exercise 2:**

Add the input and button HTML, then write the following in `script.js`:

```javascript
const noteInput = document.getElementById("note-input");
const addNoteBtn = document.getElementById("add-note-btn");
const notesContainer = document.getElementById("notes");

addNoteBtn.addEventListener("click", () => {
    const text = noteInput.value.trim();
    if (!text) return;

    const card = document.createElement("div");
    card.className = "card";

    const noteText = document.createElement("span");
    noteText.textContent = text;

    const deleteBtn = document.createElement("button");
    deleteBtn.textContent = "Delete";
    deleteBtn.className = "btn-delete";
    deleteBtn.addEventListener("click", () => card.remove());

    card.appendChild(noteText);
    card.appendChild(deleteBtn);
    notesContainer.appendChild(card);

    noteInput.value = "";
    noteInput.focus();
});
```

`span.textContent = text` is the critical safety choice here. Because `text` comes from user input, setting it via `textContent` prevents any HTML in the input from being parsed. A user who types `<b>bold</b>` will see that exact string displayed as text, not as bold formatting.

**Solution for Exercise 3:**

Write the following in `script.js`:

```javascript
const students = [
    { name: "Andi", grade: 85 },
    { name: "Budi", grade: 72 },
    { name: "Citra", grade: 90 },
];

function renderTable(data) {
    const table = document.createElement("table");
    table.style.borderCollapse = "collapse";
    table.style.width = "100%";

    const headerRow = document.createElement("tr");
    ["Name", "Grade"].forEach(label => {
        const th = document.createElement("th");
        th.textContent = label;
        th.style.border = "1px solid #ccc";
        th.style.padding = "8px";
        headerRow.appendChild(th);
    });
    table.appendChild(headerRow);

    data.forEach(student => {
        const row = document.createElement("tr");

        const nameCell = document.createElement("td");
        nameCell.textContent = student.name;
        nameCell.style.border = "1px solid #ccc";
        nameCell.style.padding = "8px";

        const gradeCell = document.createElement("td");
        gradeCell.textContent = student.grade;
        gradeCell.style.border = "1px solid #ccc";
        gradeCell.style.padding = "8px";

        row.appendChild(nameCell);
        row.appendChild(gradeCell);
        table.appendChild(row);
    });

    document.body.appendChild(table);
}

renderTable(students);
```

Each element is created with `createElement` and each value is assigned with `textContent`. The header row is built by iterating over a two-element array of label strings, creating a `<th>` for each. Each student row creates two `<td>` elements and appends them in order. The completed table is appended directly to `document.body` so it appears at the bottom of the page.

---

## Next Up - Lesson 11

`document.createElement(tag)` creates a new element in memory without displaying it. Configuring the element (text, classes, attributes, listeners) must happen before or immediately after inserting it into the DOM. `parent.appendChild(child)` inserts the element as the last child of the parent. `element.remove()` deletes the element from the page. Use `textContent` when the value comes from user input. Use `innerHTML` only when all values are from trusted, controlled sources. Calling `container.innerHTML = ""` before rendering clears previous content to avoid duplicates. Always check that `getElementById` or `querySelector` did not return `null` before calling methods on the result.

In Lesson 11, you will learn event handling: how to listen for user clicks, keyboard input, mouse movements, and form submissions to make your pages fully interactive.