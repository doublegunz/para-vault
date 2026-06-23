## 1. Before You Begin

Forms are the primary mechanism through which users send data to a web application. Every login page, registration form, search bar, and contact form relies on the same underlying mechanics: reading values from input fields, checking whether those values meet requirements, showing feedback when they do not, and deciding what to do when the user submits.

In Lesson 11, you learned how to listen for events. In this lesson, you will apply that knowledge specifically to form interactions, combining the `submit` event, the `input` event, DOM manipulation, and conditional logic into a complete real-time validation system.

### What You'll Build

You will create a registration form with three fields: full name, email, and password. Each field validates in real time as the user types, displaying specific error messages below failing fields and a green border on passing ones. The submit button stays disabled until all fields are valid.

### What You'll Learn

- ✅ Reading input values with `.value`
- ✅ Handling form submission with the `submit` event
- ✅ Real-time validation with the `input` event
- ✅ Displaying and clearing error messages
- ✅ Disabling the submit button until the form is valid
- ✅ Common validation rules: required, email format, minimum length

### What You'll Need

- Lesson 11 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-12`. Inside it, create `index.html`, `style.css`, and `script.js`.

---

## 3. Registration Form

This section builds the complete registration form in three stages: the HTML structure, the CSS styling, and the JavaScript validation logic.

### Step 1: Create index.html

Add the following to `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Form Validation</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>Register</h1>
    <form id="register-form">
        <div class="form-group">
            <label for="name">Full Name</label>
            <input type="text" id="name" placeholder="Enter your name">
            <p class="error-msg" id="name-error"></p>
        </div>
        <div class="form-group">
            <label for="email">Email</label>
            <input type="email" id="email" placeholder="you@example.com">
            <p class="error-msg" id="email-error"></p>
        </div>
        <div class="form-group">
            <label for="password">Password</label>
            <input type="password" id="password" placeholder="Min 8 characters">
            <p class="error-msg" id="password-error"></p>
        </div>
        <button type="submit" id="submit-btn" disabled>Register</button>
    </form>
    <div id="result" style="margin-top: 16px;"></div>
    <script src="script.js"></script>
</body>
</html>
```

Each input field is paired with a `<p class="error-msg">` element that starts hidden and becomes visible only when a validation error occurs. The submit button starts with the `disabled` attribute so it cannot be clicked until the form becomes valid. The `<div id="result">` will display a success message after a successful submission.

### Step 2: Create style.css

Add the following to `style.css`:

```css
body { font-family: Arial, sans-serif; max-width: 450px; margin: 30px auto; padding: 0 16px; }
h1 { margin-bottom: 20px; }
.form-group { margin-bottom: 14px; }
label { display: block; font-weight: bold; margin-bottom: 4px; font-size: 0.9em; }
input { width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
input.error { border-color: #dc2626; }
input.valid { border-color: #16a34a; }
.error-msg { color: #dc2626; font-size: 0.8em; margin-top: 4px; display: none; }
.error-msg.show { display: block; }
button { width: 100%; padding: 10px; background: #2563eb; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 1em; }
button:disabled { background: #94a3b8; cursor: not-allowed; }
```

The `.error-msg` class has `display: none` by default, keeping the error paragraph invisible. When the `.show` class is added, `display: block` overrides it and makes the paragraph appear. Similarly, `input.error` turns the border red and `input.valid` turns it green. This class-toggle approach keeps all visual state in the CSS where it belongs.

### Step 3: Write script.js

Add the following to `script.js`:

```javascript
const form = document.getElementById("register-form");
const nameInput = document.getElementById("name");
const emailInput = document.getElementById("email");
const passwordInput = document.getElementById("password");
const submitBtn = document.getElementById("submit-btn");
const result = document.getElementById("result");

function showError(input, errorEl, message) {
    errorEl.textContent = message;
    errorEl.classList.add("show");
    input.classList.add("error");
    input.classList.remove("valid");
}

function clearError(input, errorEl) {
    errorEl.textContent = "";
    errorEl.classList.remove("show");
    input.classList.remove("error");
    input.classList.add("valid");
}

function validateName() {
    const val = nameInput.value.trim();
    const err = document.getElementById("name-error");
    if (val.length === 0) {
        showError(nameInput, err, "Name is required.");
        return false;
    }
    if (val.length < 3) {
        showError(nameInput, err, "Name must be at least 3 characters.");
        return false;
    }
    clearError(nameInput, err);
    return true;
}

function validateEmail() {
    const val = emailInput.value.trim();
    const err = document.getElementById("email-error");
    if (val.length === 0) {
        showError(emailInput, err, "Email is required.");
        return false;
    }
    if (!val.includes("@") || !val.includes(".")) {
        showError(emailInput, err, "Enter a valid email address.");
        return false;
    }
    clearError(emailInput, err);
    return true;
}

function validatePassword() {
    const val = passwordInput.value;
    const err = document.getElementById("password-error");
    if (val.length === 0) {
        showError(passwordInput, err, "Password is required.");
        return false;
    }
    if (val.length < 8) {
        showError(passwordInput, err, "Password must be at least 8 characters.");
        return false;
    }
    clearError(passwordInput, err);
    return true;
}

function checkForm() {
    const allValid = validateName() & validateEmail() & validatePassword();
    submitBtn.disabled = !allValid;
}

nameInput.addEventListener("input", checkForm);
emailInput.addEventListener("input", checkForm);
passwordInput.addEventListener("input", checkForm);

form.addEventListener("submit", (e) => {
    e.preventDefault();
    result.innerHTML = `<p style="color: #16a34a;">Welcome, ${nameInput.value}! Registration successful.</p>`;
    form.reset();
    submitBtn.disabled = true;
});
```

`showError` and `clearError` are helper functions that centralize the visual feedback logic. Rather than repeating the class add/remove code in every validation function, both helpers accept the input element and its corresponding error element as arguments. `showError` sets the message text, adds the `"show"` class to make the error visible, adds the `"error"` class to the input, and removes `"valid"`. `clearError` does the reverse.

Each `validateX` function reads the field's current value, trims whitespace, checks it against the validation rules in order of priority, and returns `true` or `false`. Returning `false` from the earliest failing check means the function exits immediately without running later checks.

`checkForm` calls all three validators and combines their return values using the bitwise AND operator `&`. Unlike the logical AND `&&`, the bitwise version always evaluates all three operands rather than short-circuiting when the first is `false`. This matters here because we want all three fields to show their errors simultaneously, not just the first failing one.

`form.addEventListener("submit", ...)` listens for the `submit` event. `e.preventDefault()` stops the page from reloading. After a successful submission, `form.reset()` clears all the input fields back to their default state, and `submitBtn.disabled = true` prevents a second identical submission.

---

## 4. Fix the Errors in Your Code

Three form-related mistakes are common enough to address specifically. Each one either reads the wrong value or prevents the form from behaving as intended.

**Error 1: Reading `textContent` instead of `value` from an input.**

`textContent` reads the text content of an element as it appears in the HTML. For input fields, the visible value the user typed is stored in the `.value` property, not in `textContent`. Attempting to read `textContent` from an input always returns an empty string.

```javascript
// Wrong: input elements do not have text content, this returns ""
const val = input.textContent;

// Correct: .value contains the user's typed input
const val = input.value;
```

This applies to all interactive form elements: `<input>`, `<textarea>`, and `<select>`. Use `.value` for all of them.

**Error 2: Forgetting `event.preventDefault()` on form submission.**

Without calling `preventDefault()`, the browser performs its default form submission behavior, which sends a request to the server and reloads the page. Any JavaScript logic you intended to run after the submission will not execute.

```javascript
// Wrong: page reloads before any JS logic runs
form.addEventListener("submit", () => {
    console.log("submitted");
});

// Correct: stop the default reload, handle everything in JavaScript
form.addEventListener("submit", (e) => {
    e.preventDefault();
    console.log("submitted");
});
```

`e.preventDefault()` must be the first line inside the submit handler to ensure the page reload is cancelled before anything else runs.

**Error 3: Using `&&` instead of `&` when all validators must run.**

Logical `&&` short-circuits: if the first operand is `false`, it does not evaluate the remaining operands. In a validation chain where you want all fields to show their errors at the same time, this means errors in the second and third fields are hidden when the first field fails.

```javascript
// Wrong: if validateName() returns false, validateEmail() and validatePassword() never run
const allValid = validateName() && validateEmail() && validatePassword();

// Correct: bitwise & evaluates all three regardless of earlier results
const allValid = validateName() & validateEmail() & validatePassword();
```

For conditional logic where short-circuit behavior is intended (stopping early when a condition fails), use `&&`. When you deliberately need all functions to run regardless of each other's results, use the bitwise `&`.

---

## 5. Exercises

**Exercise 1:** Add a fourth field, "Confirm Password," to the registration form. Write a `validateConfirm()` function that shows an error if the confirm password field does not exactly match the password field. Include it in `checkForm`.

**Exercise 2:** Add a password strength indicator below the password field. As the user types, display the text `"Weak"` in red for passwords shorter than 8 characters, `"Medium"` in orange for passwords of 8 to 12 characters without special characters, and `"Strong"` in green for passwords longer than 12 characters that contain at least one number and one special character.

**Exercise 3:** Build a separate search page with a text input and an unordered list of at least eight country names. As the user types in the search input, hide any list item whose text does not contain the search query (case-insensitive). Show all items when the input is cleared.

---

## 6. Solutions

**Solution for Exercise 1:**

Add a confirm password input to your HTML with id `"confirm"` and a matching error paragraph with id `"confirm-error"`. Then add the following to `script.js`:

```javascript
const confirmInput = document.getElementById("confirm");

function validateConfirm() {
    const val = confirmInput.value;
    const err = document.getElementById("confirm-error");
    if (val.length === 0) {
        showError(confirmInput, err, "Please confirm your password.");
        return false;
    }
    if (val !== passwordInput.value) {
        showError(confirmInput, err, "Passwords do not match.");
        return false;
    }
    clearError(confirmInput, err);
    return true;
}

function checkForm() {
    const allValid = validateName() & validateEmail() & validatePassword() & validateConfirm();
    submitBtn.disabled = !allValid;
}

confirmInput.addEventListener("input", checkForm);
```

`val !== passwordInput.value` uses strict inequality to compare the two fields. Because both are strings, `!==` is the correct operator. For the confirm field to stay in sync, `checkForm` should also be called whenever the password field changes, so that if the user goes back and changes the original password, the confirm validation reruns automatically.

**Solution for Exercise 2:**

Add a `<p id="strength"></p>` below the password input, then write the following in `script.js`:

```javascript
const strengthEl = document.getElementById("strength");

passwordInput.addEventListener("input", () => {
    const val = passwordInput.value;
    let strength = "Weak";
    let color = "#dc2626";

    if (val.length >= 12 && /[0-9]/.test(val) && /[^a-zA-Z0-9]/.test(val)) {
        strength = "Strong";
        color = "#16a34a";
    } else if (val.length >= 8) {
        strength = "Medium";
        color = "#d97706";
    }

    strengthEl.textContent = val.length > 0 ? `Strength: ${strength}` : "";
    strengthEl.style.color = color;
    strengthEl.style.fontSize = "0.85em";
});
```

`/[0-9]/.test(val)` uses a regular expression to check whether the value contains at least one digit. `/[^a-zA-Z0-9]/.test(val)` checks for at least one character that is not a letter or digit. The conditions are evaluated from strong to weak so the most specific condition is checked first.

**Solution for Exercise 3:**

Add a text input with id `"search-input"` and a `<ul>` with eight `<li>` country names, then write the following in `script.js`:

```javascript
const searchInput = document.getElementById("search-input");

searchInput.addEventListener("input", () => {
    const query = searchInput.value.toLowerCase();
    document.querySelectorAll("li").forEach(li => {
        const matches = li.textContent.toLowerCase().includes(query);
        li.style.display = matches ? "" : "none";
    });
});
```

Converting both the query and each item's text to lowercase with `.toLowerCase()` makes the comparison case-insensitive. Setting `li.style.display = ""` removes any inline display style, allowing the element's default or CSS-defined display to take effect. Setting it to `"none"` hides the item. When the input is empty, `query` is `""`, and every string includes `""`, so all items pass the check and become visible.

---

## Next Up - Lesson 13

Read form input values with `.value`, not `.textContent`. Handle form submissions with the `submit` event and always call `event.preventDefault()` to stop the page from reloading. Validate in real time by listening to the `input` event on each field. Show and hide error messages by toggling CSS classes rather than setting style properties directly. Use the bitwise `&` operator when all validation functions must run regardless of each other's results. Disable the submit button and enable it only when all fields pass validation. `form.reset()` clears all fields back to their default state after a successful submission.

In Lesson 13, you will combine every concept from this course into a complete mini project: a fully functional interactive to-do list with task creation, completion toggling, deletion, filtering, and localStorage persistence.