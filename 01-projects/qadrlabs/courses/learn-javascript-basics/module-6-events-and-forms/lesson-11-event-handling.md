## 1. Before You Begin

A web page that cannot respond to user input is a static document. What makes a page interactive is its ability to detect user actions and run code in response. A click, a key press, a mouse movement, a form submission - these are all events. JavaScript listens for them and executes the appropriate code when they occur.

In Lesson 10, you learned to create and remove DOM elements dynamically. In this lesson, you will attach event listeners to those elements so they actually respond to what users do.

### What You'll Build

You will create an interactive page with a click counter, a live search input, hover effects, and a delegated list where clicking any item toggles its state - all driven by event listeners.

### What You'll Learn

- ✅ `addEventListener()` for attaching event handlers
- ✅ Common events: click, input, keydown, submit, mouseover
- ✅ The event object and its properties
- ✅ `event.preventDefault()` for stopping default behavior
- ✅ Event delegation (handling events on parent elements)
- ✅ Removing event listeners

### What You'll Need

- Lesson 10 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-11`. Inside it, create `index.html` and `script.js`. Your HTML should include a button, a paragraph for output, a text input, and an unordered list for the delegation example.

---

## 3. addEventListener

`addEventListener` is the standard way to attach event handling code to a DOM element. It accepts an event type string, a callback function, and an optional options object. The callback runs every time that event occurs on that element.

Add the following HTML to `index.html`:

```html
<button id="btn" style="padding: 8px 16px; background: #2563eb; color: white; border: none; border-radius: 4px; cursor: pointer;">Click Me</button>
<p id="output"></p>
<input type="text" id="search" placeholder="Type something...">
<ul id="results"></ul>
```

Add the following to `script.js`:

```javascript
const btn = document.getElementById("btn");
const output = document.getElementById("output");
const search = document.getElementById("search");

let clickCount = 0;
btn.addEventListener("click", () => {
    clickCount++;
    output.textContent = `Clicked ${clickCount} times`;
});

search.addEventListener("input", (event) => {
    output.textContent = `You typed: ${event.target.value}`;
});

search.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
        console.log("Enter pressed! Search for:", event.target.value);
    }
    if (event.key === "Escape") {
        event.target.value = "";
    }
});

btn.addEventListener("mouseover", () => {
    btn.style.background = "#1d4ed8";
});

btn.addEventListener("mouseout", () => {
    btn.style.background = "#2563eb";
});
```

`btn.addEventListener("click", callback)` registers the callback so it runs every time the button is clicked. The `clickCount` variable lives outside the callback and retains its value between clicks because it is declared in the enclosing scope. Each time the callback runs, `clickCount++` increments it, and `output.textContent` is updated to reflect the new total.

The `"input"` event fires on every single keystroke inside an input field. The callback receives the event object as its first argument, named `event` here. `event.target` is a reference to the element that triggered the event - in this case, the search input. `event.target.value` is the current text in the field.

The `"keydown"` event fires when any key is pressed while the input field has focus. `event.key` is a string representing the key that was pressed. `"Enter"` and `"Escape"` are the string values for those specific keys. Setting `event.target.value = ""` clears the input when Escape is pressed.

`"mouseover"` fires when the mouse pointer moves onto an element, and `"mouseout"` fires when it moves off. Together they create a hover color change effect, though the CSS `:hover` pseudo-class is a simpler way to achieve the same visual result.

---

## 4. The Event Object

Every event handler callback receives an event object as its first argument. This object contains detailed information about the event that occurred, including what triggered it, where it happened, and what key was pressed. The same object type is passed for all event types, but different events populate different properties.

Add the following to `script.js`:

```javascript
document.addEventListener("click", (event) => {
    console.log("Event type:", event.type);
    console.log("Target:", event.target.tagName);
    console.log("X:", event.clientX, "Y:", event.clientY);
});
```

`event.type` is a string describing the kind of event that occurred, such as `"click"`, `"keydown"`, or `"input"`. `event.target` is the DOM element that directly received the event - the element the user actually clicked, not the element the listener is attached to. `event.target.tagName` returns the uppercase tag name of that element, such as `"BUTTON"` or `"P"`. `event.clientX` and `event.clientY` are numbers representing the horizontal and vertical position of the mouse pointer within the browser viewport at the moment the event occurred. These are available on mouse events but not on keyboard events.

---

## 5. Event Delegation

Adding an individual event listener to every item in a large list is inefficient and breaks for dynamically added items. Event delegation solves this by placing a single listener on the parent element and using the event object to determine which child was clicked.

Add the following to `script.js`:

```javascript
const list = document.getElementById("results");
list.addEventListener("click", (event) => {
    if (event.target.tagName === "LI") {
        event.target.classList.toggle("completed");
        console.log("Toggled:", event.target.textContent);
    }
});
```

When a user clicks an `<li>` element inside the `<ul>`, the event fires on the `<li>` and then travels up through the DOM tree to its ancestors - a process called event bubbling. The `<ul>` listener catches the event as it bubbles up. `event.target.tagName === "LI"` checks that the original source of the click was an `<li>` element rather than the `<ul>` container itself or any other element inside it.

`classList.toggle("completed")` adds the class if it is absent and removes it if it is present. This single method handles both directions of the toggle without an `if/else` check. The listener on the `<ul>` also automatically handles any `<li>` items that are added to the list dynamically after the listener is registered, because the listener is on the parent, not on the individual items.

---

## 6. preventDefault

Certain HTML elements have default behaviors built into the browser. Links navigate to a new URL. Form submit buttons reload the page. The `preventDefault` method on the event object cancels these default behaviors, giving JavaScript full control over what happens instead.

Add the following to `script.js`:

```javascript
document.querySelector("a")?.addEventListener("click", (event) => {
    event.preventDefault();
    console.log("Link click prevented!");
});

document.querySelector("form")?.addEventListener("submit", (event) => {
    event.preventDefault();
    console.log("Form submitted via JS!");
});
```

`event.preventDefault()` must be called inside the event handler before the default behavior would normally execute. For a link click, calling it prevents navigation. For a form submit, calling it prevents the page from reloading. The `?.` optional chaining operator ensures that if no `<a>` or `<form>` element exists on the page, `addEventListener` is not called on `null`.

---

## 7. Fix the Errors in Your Code

Three event handling mistakes appear with high frequency and each one either breaks the listener entirely or makes it impossible to remove.

**Error 1: Passing a function call instead of a function reference.**

`addEventListener` expects a function as its second argument. Adding parentheses after the function name calls it immediately and passes its return value instead. If the return value is not a function, the listener will never fire.

```javascript
// Wrong: handleClick() is called immediately, its return value (undefined) is passed
btn.addEventListener("click", handleClick());

// Correct: handleClick is passed as a reference, called when the event fires
btn.addEventListener("click", handleClick);
```

The rule is simple: if you want a function to be called when the event fires, do not add parentheses. Parentheses execute the function right now. Without parentheses, you are passing the function itself.

**Error 2: Adding a listener to an element that does not exist.**

If `getElementById` or `querySelector` returns `null` because the element is not found, calling `addEventListener` on `null` throws a `TypeError` that stops the entire script.

```javascript
// Wrong: if the element with id "nonexistent" does not exist, this throws an error
document.getElementById("nonexistent").addEventListener("click", () => {});

// Correct: check that the element was found before using it
const el = document.getElementById("nonexistent");
if (el) {
    el.addEventListener("click", () => {});
}
```

Defensive null checks like this are especially important in scripts that run on multiple pages where some elements may not be present.

**Error 3: Trying to remove an anonymous function listener.**

`removeEventListener` requires the exact same function reference that was used in `addEventListener`. Two arrow functions with identical code are two separate function objects and will not match.

```javascript
// Wrong: the two arrow functions are different objects, the listener is not removed
btn.addEventListener("click", () => console.log("click"));
btn.removeEventListener("click", () => console.log("click"));

// Correct: use a named function reference so both calls share the same reference
function handleClick() {
    console.log("click");
}
btn.addEventListener("click", handleClick);
btn.removeEventListener("click", handleClick);
```

If you need to remove an event listener, always store the callback in a named variable or function before adding it.

---

## 8. Exercises

**Exercise 1:** Create a page with three buttons labeled `+`, `-`, and `Reset`, and a `<span>` showing the current count. Write event listeners so `+` increments the count, `-` decrements it (but never below 0), and `Reset` sets it back to 0. Update the displayed count on every change.

**Exercise 2:** Create a `<textarea>` and a `<p>` below it. Write an `input` event listener on the textarea that displays `"X/200 characters"` where X is the current length. When the count exceeds 200, change the text color to red.

**Exercise 3:** Create an unordered list with five items. Using event delegation on the `<ul>`, write a click listener so that clicking any `<li>` toggles a CSS class `"completed"` that applies a line-through style. Do not attach listeners to the individual list items.

---

## 9. Solutions

**Solution for Exercise 1:**

Add the HTML structure with id attributes for each button and the count display, then write the following in `script.js`:

```javascript
let count = 0;
const display = document.getElementById("count");

document.getElementById("inc").addEventListener("click", () => {
    count++;
    display.textContent = count;
});

document.getElementById("dec").addEventListener("click", () => {
    if (count > 0) count--;
    display.textContent = count;
});

document.getElementById("reset").addEventListener("click", () => {
    count = 0;
    display.textContent = count;
});
```

`count` is declared in the outer scope and shared across all three callbacks. Each callback modifies `count` and then updates `display.textContent` to reflect the new value. The decrement handler uses `if (count > 0)` to prevent the count from going negative.

**Solution for Exercise 2:**

Add the textarea and status paragraph to your HTML, then write the following in `script.js`:

```javascript
const textarea = document.querySelector("textarea");
const counter = document.getElementById("char-count");

textarea.addEventListener("input", () => {
    const len = textarea.value.length;
    counter.textContent = `${len}/200 characters`;
    counter.style.color = len > 200 ? "#dc2626" : "#6b7280";
});
```

The `"input"` event fires after every character is typed or deleted. `textarea.value.length` gives the current character count. The ternary expression sets the color to red when the limit is exceeded and gray otherwise.

**Solution for Exercise 3:**

Add `<style>.completed { text-decoration: line-through; color: #9ca3af; }</style>` to your HTML, then write the following in `script.js`:

```javascript
document.querySelector("ul").addEventListener("click", (e) => {
    if (e.target.tagName === "LI") {
        e.target.classList.toggle("completed");
    }
});
```

The single listener on the `<ul>` catches all clicks that bubble up from list items. `e.target.tagName === "LI"` ensures only actual list item clicks trigger the toggle, ignoring any clicks on the `<ul>` background.

---

## Next Up - Lesson 12

`addEventListener(event, callback)` attaches a function to run whenever the specified event fires on an element. The callback receives an event object with properties like `type`, `target`, `key`, and `clientX/clientY`. `event.preventDefault()` cancels the browser's default behavior for links, form submissions, and other interactive elements. Event delegation places one listener on a parent element and uses `event.target` to identify which child triggered the event - this also works for dynamically added children. Always pass a function reference (no parentheses) to `addEventListener`. To remove a listener, you must pass the exact same function reference used when adding it.

In Lesson 12, you will learn how to work with HTML forms: reading input values, validating them in real time, showing error messages, and handling form submissions entirely with JavaScript.