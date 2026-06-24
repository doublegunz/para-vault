## 1. Before You Begin

Two of the most practical HTML skills are tables and forms. Tables display structured data in rows and columns, similar to a spreadsheet, making it easy to compare information across multiple categories. Forms collect input from users through fields like text boxes, dropdowns, radio buttons, and checkboxes. Together, these two elements cover a large portion of real-world web page content: product comparison pages, login forms, contact pages, and checkout flows all rely on the skills you will practice in this lesson.

In Lesson 4, you learned how to link pages, embed images, and organize content with lists. This lesson adds structured data and user interaction to your toolkit.

### What You'll Build

You will create two files: `tables.html` with a student grade table and a schedule using `colspan` and `rowspan`, and `forms.html` with a complete contact form covering every major input type.

### What You'll Learn

- ✅ Tables: `<table>`, `<tr>`, `<th>`, `<td>`, `<thead>`, `<tbody>`, `<caption>`
- ✅ Table attributes: `colspan` and `rowspan`
- ✅ Forms: `<form>`, `<input>`, `<textarea>`, `<select>`, `<button>`
- ✅ Input types: text, email, password, number, date, checkbox, radio
- ✅ Labels and the `for` attribute for accessibility
- ✅ Form attributes: `action`, `method`, `required`, `placeholder`

### What You'll Need

- VS Code with the `learn-html-css` project folder open
- Lesson 4 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder in the Explorer panel, select **New Folder**, type `lesson-05`, and press Enter.

---

## 3. Tables

An HTML table is built from three nested elements working together: `<table>` is the outer container, `<tr>` creates rows, and `<th>` or `<td>` creates individual cells within those rows. Adding `<thead>` and `<tbody>` gives the table semantic structure, separating the header row from the data rows.

### Step 1: Create the File

Right-click on the `lesson-05` folder in VS Code, select **New File**, type `tables.html`, and press Enter.

### Step 2: Write the Code

Add the following to `tables.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tables</title>
    <style>
        table { border-collapse: collapse; width: 100%; max-width: 600px; }
        th, td { border: 1px solid #ccc; padding: 10px 14px; text-align: left; }
        th { background: #f5f5f5; font-weight: bold; }
        tr:hover { background: #fafafa; }
        caption { font-size: 1.2em; font-weight: bold; margin-bottom: 10px; }
    </style>
</head>
<body>
    <h1>HTML Tables</h1>

    <h2>Student Grades</h2>
    <table>
        <caption>Semester 1 Results</caption>
        <thead>
            <tr>
                <th>No</th>
                <th>Name</th>
                <th>Math</th>
                <th>Science</th>
                <th>Average</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>1</td>
                <td>Andi</td>
                <td>85</td>
                <td>78</td>
                <td>81.5</td>
            </tr>
            <tr>
                <td>2</td>
                <td>Budi</td>
                <td>90</td>
                <td>92</td>
                <td>91.0</td>
            </tr>
            <tr>
                <td>3</td>
                <td>Citra</td>
                <td>72</td>
                <td>80</td>
                <td>76.0</td>
            </tr>
        </tbody>
    </table>

    <h2>Schedule (colspan and rowspan)</h2>
    <table>
        <tr>
            <th>Time</th>
            <th>Monday</th>
            <th>Tuesday</th>
        </tr>
        <tr>
            <td>08:00</td>
            <td rowspan="2">Math (2 hours)</td>
            <td>English</td>
        </tr>
        <tr>
            <td>09:00</td>
            <td>Science</td>
        </tr>
        <tr>
            <td>10:00</td>
            <td colspan="2" style="text-align:center">Break</td>
        </tr>
    </table>
</body>
</html>
```

`<table>` is the outer container for the entire table. `<thead>` wraps the header row and allows browsers and assistive tools to treat it as a separate, repeating header when the table is printed across multiple pages. `<tbody>` wraps all data rows. `<tr>` creates a single row inside either `<thead>` or `<tbody>`. `<th>` creates a header cell, which browsers render as bold by default and which screen readers announce differently from regular data cells. `<td>` creates a data cell containing the actual values.

`<caption>` adds a visible title above the table that is semantically linked to it. Screen readers announce the caption before reading table data, so users know what the table is about before they encounter the first cell.

`colspan="2"` on the "Break" cell tells the browser that this cell spans two columns instead of one, effectively merging two adjacent cells in that row. `rowspan="2"` on the "Math" cell tells the browser that it spans two rows vertically, eliminating the need for a separate cell in the next row for Monday.

### Step 3: Save and View

Press **Ctrl+S** and open with Live Server. You will see two tables: a clean grade table with a visible border and hover effect, and a schedule showing how `colspan` and `rowspan` merge cells.

---

## 4. Forms

A form is a collection of input elements wrapped inside a `<form>` tag. When the user clicks the submit button, the browser gathers all the field values and sends them to the server address specified by the `action` attribute. Learning to write proper form HTML is essential because forms are the primary way users interact with web applications.

### Step 1: Create the File

Right-click on `lesson-05`, select **New File**, type `forms.html`, and press Enter.

### Step 2: Write the Code

Add the following to `forms.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Forms</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 500px; margin: 20px auto; padding: 0 15px; }
        .form-group { margin-bottom: 15px; }
        label { display: block; margin-bottom: 4px; font-weight: bold; font-size: 0.9em; }
        input[type="text"], input[type="email"], input[type="password"],
        input[type="number"], input[type="date"], textarea, select {
            width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box;
        }
        button { background: #2563eb; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; font-size: 1em; }
        button:hover { background: #1d4ed8; }
    </style>
</head>
<body>
    <h1>Contact Form</h1>

    <form action="#" method="post">
        <div class="form-group">
            <label for="name">Full Name</label>
            <input type="text" id="name" name="name" placeholder="Enter your name" required>
        </div>

        <div class="form-group">
            <label for="email">Email Address</label>
            <input type="email" id="email" name="email" placeholder="you@example.com" required>
        </div>

        <div class="form-group">
            <label for="password">Password</label>
            <input type="password" id="password" name="password" placeholder="Min 8 characters" minlength="8" required>
        </div>

        <div class="form-group">
            <label for="age">Age</label>
            <input type="number" id="age" name="age" min="1" max="120" placeholder="25">
        </div>

        <div class="form-group">
            <label for="dob">Date of Birth</label>
            <input type="date" id="dob" name="dob">
        </div>

        <div class="form-group">
            <label for="subject">Subject</label>
            <select id="subject" name="subject" required>
                <option value="">Select a subject</option>
                <option value="general">General Inquiry</option>
                <option value="support">Technical Support</option>
                <option value="billing">Billing</option>
            </select>
        </div>

        <div class="form-group">
            <label>Priority</label>
            <label><input type="radio" name="priority" value="low"> Low</label>
            <label><input type="radio" name="priority" value="medium" checked> Medium</label>
            <label><input type="radio" name="priority" value="high"> High</label>
        </div>

        <div class="form-group">
            <label><input type="checkbox" name="subscribe" value="yes"> Subscribe to newsletter</label>
        </div>

        <div class="form-group">
            <label for="message">Message</label>
            <textarea id="message" name="message" rows="5" placeholder="Type your message..." required></textarea>
        </div>

        <button type="submit">Send Message</button>
        <button type="reset" style="background:#666; margin-left:8px;">Reset</button>
    </form>
</body>
</html>
```

`<form action="#" method="post">` wraps all the form's input elements. The `action` attribute is the URL that will receive the submitted data. Using `#` as a placeholder means the form posts back to the current page. The `method` attribute controls how data is sent: `"get"` appends values to the URL as query parameters (visible in the address bar), while `"post"` sends values inside the request body (not visible in the URL). Use `"post"` for forms that contain sensitive data like passwords.

`<label for="name">` connects a text label to the input with `id="name"`. This connection serves two purposes: clicking the label focuses the corresponding input, making it easier to click on mobile; and screen readers announce the label text before the input field, telling the user what to type.

`type="text"` is the default input for short single-line text. `type="email"` validates that the value looks like an email address before submission. `type="password"` hides the typed characters. `type="number"` accepts only numeric values, with `min` and `max` to constrain the allowed range. `type="date"` renders a native date picker browser widget. `type="radio"` creates a single-choice selector, and all radio buttons that share the same `name` attribute are grouped together so that selecting one automatically deselects the others. `type="checkbox"` is independent and can be checked or unchecked regardless of other checkboxes.

`required` is a boolean attribute that prevents form submission if the field is empty, triggering a browser-native validation message. `placeholder` shows hint text inside the field that disappears when the user starts typing. `minlength="8"` on the password field prevents submission unless at least eight characters are entered.

`<textarea>` creates a multi-line text input. The `rows` attribute sets the visible height of the text area in lines. Unlike `<input>`, `<textarea>` has a closing tag and must not contain any initial content between those tags if you want it to appear empty.

`<select>` creates a dropdown menu. Each option inside `<select>` is an `<option>` element. The `value` attribute on each `<option>` is the data actually sent to the server when the form is submitted, while the text between the opening and closing `<option>` tags is what appears in the dropdown for the user to read.

### Step 3: Save and View

Press **Ctrl+S** and open in the browser. Try clicking the submit button with required fields left empty to see the browser's built-in validation messages appear automatically.

---

## 5. Fix the Errors in Your Code

Three common mistakes appear repeatedly when beginners write tables and forms. Each one either produces invalid HTML or breaks accessibility in a way that affects real users.

**Error 1: Missing `</tr>` closing tag in a table.**

Forgetting to close a table row causes the browser to make assumptions about where the row ends, often producing shifted columns or merged rows.

```html
<!-- Wrong: first tr is never closed -->
<table>
    <tr><td>A</td><td>B</td>
    <tr><td>C</td><td>D</td></tr>
</table>

<!-- Correct: every tr is explicitly closed -->
<table>
    <tr><td>A</td><td>B</td></tr>
    <tr><td>C</td><td>D</td></tr>
</table>
```

Even though most browsers will attempt to render the table correctly despite the missing tag, relying on browser error recovery produces inconsistent results. Always close every `<tr>` explicitly after its last `<td>` or `<th>`.

**Error 2: A `<label>` not connected to its input.**

A label that is not explicitly linked to its input is rendered visually but provides no accessibility benefit. Clicking the label will not focus the input, and screen readers will not associate the label with that field.

```html
<!-- Wrong: label has no for attribute -->
<label>Name</label>
<input type="text" id="name">

<!-- Correct: label for matches input id -->
<label for="name">Name</label>
<input type="text" id="name">
```

The `for` attribute on `<label>` must exactly match the `id` attribute on the corresponding `<input>`. When they match, clicking anywhere on the label text focuses the input field. This is especially important on mobile devices where input targets are small.

**Error 3: Radio buttons with different `name` attributes.**

Radio buttons are designed to be mutually exclusive within a group. The browser groups them by the `name` attribute. If two radio buttons have different names, they belong to separate groups and can both be selected at the same time.

```html
<!-- Wrong: different names, both can be selected -->
<input type="radio" name="color1" value="red"> Red
<input type="radio" name="color2" value="blue"> Blue

<!-- Correct: same name, only one can be selected -->
<input type="radio" name="color" value="red"> Red
<input type="radio" name="color" value="blue"> Blue
```

All radio buttons that should be mutually exclusive must share the exact same `name` value. The `value` attribute distinguishes which option was selected when the form is submitted - the selected radio button's `value` is sent to the server under the shared `name` key.

---

## 6. Exercises

**Exercise 1:** Create `pricing.html` with a pricing comparison table. Include four columns: Feature, Basic, Pro, and Enterprise. Add rows for Price, Storage, Users, and Support. Use `<th>` for all header cells and style the table with a CSS border and alternating row colors.

**Exercise 2:** Create `registration.html` with a user registration form. Include: full name (text), email, password, confirm password, date of birth (date), gender (radio buttons), interests (checkboxes for Sports, Music, and Technology), and a bio (textarea). Add a Submit button.

**Exercise 3:** Create `schedule.html` with a weekly class schedule table. Use five columns for Monday through Friday and six rows for time slots from 08:00 to 13:00. Use `rowspan` for a subject that occupies two consecutive time slots and `colspan` for a break row that spans all five days.

---

## 7. Solutions

**Solution for Exercise 1:**

Create a new file called `pricing.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pricing</title>
    <style>
        table { border-collapse: collapse; width: 100%; max-width: 700px; margin: 20px auto; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: center; }
        th { background: #2563eb; color: white; }
        tr:nth-child(even) { background: #f9f9f9; }
    </style>
</head>
<body>
    <h1 style="text-align:center">Pricing Plans</h1>
    <table>
        <thead>
            <tr><th>Feature</th><th>Basic</th><th>Pro</th><th>Enterprise</th></tr>
        </thead>
        <tbody>
            <tr><td>Price</td><td>$9/mo</td><td>$29/mo</td><td>$99/mo</td></tr>
            <tr><td>Storage</td><td>10 GB</td><td>100 GB</td><td>Unlimited</td></tr>
            <tr><td>Users</td><td>1</td><td>5</td><td>Unlimited</td></tr>
            <tr><td>Support</td><td>Email</td><td>Priority</td><td>24/7 Phone</td></tr>
        </tbody>
    </table>
</body>
</html>
```

The table uses `<thead>` and `<tbody>` to semantically separate the column headers from the data rows. `tr:nth-child(even)` applies a light background color to every second row in the tbody, creating an alternating striped pattern that makes the rows easier to scan horizontally. `border-collapse: collapse` removes the double borders that appear by default when adjacent cells each have their own border.

**Solution for Exercise 2:**

Create a new file called `registration.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registration</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 500px; margin: 20px auto; padding: 0 15px; }
        .form-group { margin-bottom: 12px; }
        label { display: block; font-weight: bold; margin-bottom: 4px; }
        input[type="text"], input[type="email"], input[type="password"],
        input[type="date"], textarea {
            width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box;
        }
        button { background: #2563eb; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>Register</h1>
    <form action="#" method="post">
        <div class="form-group">
            <label for="fullname">Full Name</label>
            <input type="text" id="fullname" name="fullname" required>
        </div>
        <div class="form-group">
            <label for="email">Email</label>
            <input type="email" id="email" name="email" required>
        </div>
        <div class="form-group">
            <label for="pass">Password</label>
            <input type="password" id="pass" name="password" minlength="8" required>
        </div>
        <div class="form-group">
            <label for="confirm">Confirm Password</label>
            <input type="password" id="confirm" name="confirm" required>
        </div>
        <div class="form-group">
            <label for="dob">Date of Birth</label>
            <input type="date" id="dob" name="dob">
        </div>
        <div class="form-group">
            <label>Gender</label>
            <label><input type="radio" name="gender" value="male"> Male</label>
            <label><input type="radio" name="gender" value="female"> Female</label>
        </div>
        <div class="form-group">
            <label>Interests</label>
            <label><input type="checkbox" name="interest" value="sports"> Sports</label>
            <label><input type="checkbox" name="interest" value="music"> Music</label>
            <label><input type="checkbox" name="interest" value="tech"> Technology</label>
        </div>
        <div class="form-group">
            <label for="bio">Bio</label>
            <textarea id="bio" name="bio" rows="4"></textarea>
        </div>
        <button type="submit">Register</button>
    </form>
</body>
</html>
```

Both gender radio buttons share `name="gender"`, which groups them so only one can be selected at a time. The interest checkboxes share `name="interest"` but use `type="checkbox"` instead of `type="radio"`, allowing multiple interests to be checked simultaneously. Each `<label>` uses the `for` attribute to match the corresponding input's `id`, ensuring full accessibility.

**Solution for Exercise 3:**

Create a new file called `schedule.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Schedule</title>
    <style>
        table { border-collapse: collapse; width: 100%; max-width: 700px; margin: 20px auto; }
        th, td { border: 1px solid #ccc; padding: 10px; text-align: center; }
        th { background: #334155; color: white; }
    </style>
</head>
<body>
    <h1>Weekly Class Schedule</h1>
    <table>
        <thead>
            <tr>
                <th>Time</th>
                <th>Monday</th>
                <th>Tuesday</th>
                <th>Wednesday</th>
                <th>Thursday</th>
                <th>Friday</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>08:00</td>
                <td rowspan="2">Math</td>
                <td>English</td>
                <td rowspan="2">Science</td>
                <td>History</td>
                <td>Art</td>
            </tr>
            <tr>
                <td>09:00</td>
                <td>Physics</td>
                <td>Geography</td>
                <td>Music</td>
            </tr>
            <tr>
                <td>10:00</td>
                <td colspan="5" style="background:#fef9c3;">Break</td>
            </tr>
            <tr>
                <td>10:30</td>
                <td>Chemistry</td>
                <td>Math</td>
                <td>English</td>
                <td>Science</td>
                <td>PE</td>
            </tr>
        </tbody>
    </table>
</body>
</html>
```

`rowspan="2"` on Monday's "Math" cell and Wednesday's "Science" cell makes each of those subjects occupy two consecutive rows. This means the row starting at 09:00 does not need a cell for Monday or Wednesday, because the previous row's cell is already spanning into this position. `colspan="5"` on the "Break" cell at 10:00 makes it stretch across all five day columns, representing that the break applies to every day simultaneously.

---

## 8. Next Up - Lesson 6

Tables organize data into rows and columns using `<table>`, `<tr>`, `<th>`, and `<td>`. `<thead>` and `<tbody>` provide semantic structure, while `colspan` and `rowspan` merge cells horizontally or vertically. Forms collect user input through `<input>` fields of various types: text, email, password, number, date, radio, and checkbox. Labels connected to inputs via matching `for` and `id` values improve both usability and accessibility. `required`, `placeholder`, and `minlength` add browser-native validation without any JavaScript.

In Lesson 6, you will learn about semantic HTML elements like `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, and `<footer>`, and how to structure a complete page layout that is meaningful to browsers, search engines, and screen readers.