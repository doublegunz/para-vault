## 1. Before You Begin

Everything you have built so far has used data you wrote directly into the code. In the real world, programs must accept input from the people using them: a name typed in a registration form, a search keyword, or a score entered by a teacher. HTML forms are the interface where users fill in and submit data, and PHP's `$_GET` and `$_POST` superglobals are how PHP receives that data on the server side.

### Introduction

This lesson connects the two worlds of HTML and PHP through form submissions. Almost every meaningful web interaction — logging in, posting a comment, placing an order, filling a registration — begins with a form. By the end of this lesson, your PHP programs will accept real user input, validate it, and respond appropriately. You will also learn about XSS protection, which is one of the most important security skills in web development.

### What You'll Build

You will build three interactive programs: a greeting form that demonstrates the GET method and shows how data appears in URLs, a BMI calculator that validates numeric input and handles errors gracefully, and a registration form with comprehensive multi-field validation.

### What You'll Learn

- ✅ How HTML forms send data to PHP using GET and POST methods
- ✅ Retrieving submitted data with `$_GET` and `$_POST`
- ✅ The XSS attack and how `htmlspecialchars()` prevents it
- ✅ Validating input before processing: empty checks, type checks, range checks
- ✅ Sticky forms that preserve user input after validation errors
- ✅ Detecting whether the page was reached via form submission or direct visit

### What You'll Need

- Laragon running
- VS Code open in the `learn-php` folder
- Lessons 1 through 7 completed

---

## 2. Setup

Create a new subfolder called `lesson-08` inside the `learn-php` folder.

---

## 3. GET vs POST

Before writing code, understanding the difference between these two methods will help you make the right choice for every form you build.

The **GET method** appends form data to the URL. When a user submits a GET form with a name field containing "Budi", the browser URL changes to `page.php?name=Budi`. This data is visible to anyone, can be bookmarked, shared as a link, and appears in browser history. Use GET for searches, filters, and any action that reads data without changing anything.

The **POST method** sends data in the HTTP request body, invisible in the URL. It cannot be bookmarked. Use POST for login forms, registration, creating or editing records, or any action that changes data on the server. A good rule of thumb: if submitting the form twice would cause a problem (like charging a credit card twice or creating duplicate accounts), use POST.

---

## 4. Your First Form: The GET Method

### Step 1: Create a New File

Create a file called `form-get.php` in the `lesson-08` folder.

### Step 2: Write the Code

Open `form-get.php` and type the following code:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <title>GET Form — Greeting</title>
    <style>
        body  { font-family: Arial, sans-serif; max-width: 500px; margin: 50px auto; padding: 0 20px; }
        input, select { padding: 8px; border: 1px solid #ccc; border-radius: 4px; width: 100%; box-sizing: border-box; margin-top: 4px; }
        button { padding: 10px 20px; background: #0077cc; color: white; border: none; border-radius: 4px; cursor: pointer; margin-top: 10px; }
        .result { background: #e8f4fd; padding: 15px; border-radius: 8px; margin-top: 20px; }
    </style>
</head>
<body>

<h2>Greeting Form (GET Method)</h2>

<form method="GET" action="form-get.php">
    <label>Your name:</label>
    <input type="text" name="name" placeholder="Type your name"
           value="<?= isset($_GET['name']) ? htmlspecialchars($_GET['name']) : '' ?>">

    <label style="margin-top: 12px; display: block;">Favorite time of day:</label>
    <select name="time">
        <option value="morning"   <?= (isset($_GET['time']) && $_GET['time'] === 'morning')   ? 'selected' : '' ?>>Morning</option>
        <option value="afternoon" <?= (isset($_GET['time']) && $_GET['time'] === 'afternoon') ? 'selected' : '' ?>>Afternoon</option>
        <option value="evening"   <?= (isset($_GET['time']) && $_GET['time'] === 'evening')   ? 'selected' : '' ?>>Evening</option>
    </select>

    <button type="submit">Send</button>
</form>

<?php
if (isset($_GET['name'])) {
    $name = htmlspecialchars($_GET['name']);
    $time = htmlspecialchars($_GET['time']);

    if (empty(trim($name))) {
        echo "<div class='result'><p>Warning: Name cannot be empty!</p></div>";
    } else {
        $greetings = [
            "morning"   => "Good morning ☀️",
            "afternoon" => "Good afternoon 🌤️",
            "evening"   => "Good evening 🌙",
        ];
        $greeting = $greetings[$time] ?? "Hello";
        echo "<div class='result'>
            <h3>$greeting, $name!</h3>
            <p>Nice to meet you. Have a wonderful day!</p>
        </div>";
    }
}
?>

<p style="color: #888; font-size: 0.85em; margin-top: 20px;">
    After submitting, notice the name and time appear in the URL bar above!
</p>

</body>
</html>
```

### Step 3: Save the File

Press **Ctrl+S**.

### Step 4: Run in the Browser

```
http://localhost/learn-php/lesson-08/form-get.php
```

Fill in a name and select a time, then click Send. Watch the URL change to something like `form-get.php?name=Budi&time=morning`. This is the GET method in action.

Let us examine the three key patterns in this code that you will reuse throughout the course. First, `isset($_GET['name'])` checks whether the key `name` exists in the `$_GET` array. When the page first loads (before any form submission), `$_GET` is empty, so `isset()` returns `false` and the processing block is skipped entirely. Only after the form is submitted does `$_GET['name']` exist. Second, `htmlspecialchars()` is a security function you must apply whenever displaying user-submitted data. Without it, a user could enter `<script>alert('hacked')</script>` as their name and that JavaScript would execute in every visitor's browser — this is called a **Cross-Site Scripting (XSS) attack**. `htmlspecialchars()` converts the `<` and `>` characters to their safe HTML equivalents (`&lt;` and `&gt;`), so the text displays as-is rather than being executed. Third, the `value="<?= isset($_GET['name']) ? htmlspecialchars($_GET['name']) : '' ?>"` attribute on the input field makes the form "sticky" — after submission, the previously typed value is restored, so the user does not have to retype everything if there is an error.

---

## 5. BMI Calculator: POST Method with Validation

Now build something more substantial using POST, with proper validation before processing.

### Step 1: Create a New File

Create a file called `bmi-calculator.php` in the `lesson-08` folder.

### Step 2: Write the Code

Open `bmi-calculator.php` and type the following code:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <title>BMI Calculator</title>
    <style>
        body  { font-family: Arial, sans-serif; max-width: 500px; margin: 50px auto; padding: 0 20px; }
        .form-group { margin-bottom: 15px; }
        label  { display: block; font-weight: bold; margin-bottom: 4px; }
        input  { padding: 10px; border: 1px solid #ccc; border-radius: 6px; width: 100%; box-sizing: border-box; }
        input.error { border-color: red; }
        .error-msg  { color: red; font-size: 0.85em; margin-top: 4px; }
        button { padding: 12px 25px; background: #28a745; color: white; border: none; border-radius: 6px; cursor: pointer; width: 100%; }
        .result { margin-top: 25px; padding: 20px; border-radius: 10px; text-align: center; }
    </style>
</head>
<body>

<h2>BMI Calculator</h2>

<?php
// The null coalescing operator ?? returns the left side if it exists, otherwise ''
// This way $weight_input has a safe default on the first page load (before POST)
$weight_input = $_POST['weight'] ?? '';
$height_input = $_POST['height'] ?? '';
$errors       = [];
$bmi_result   = null;

// $_SERVER['REQUEST_METHOD'] tells us how this page was reached
// 'POST' means the form was submitted; anything else means a direct page visit
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Validate weight
    if (empty(trim($weight_input))) {
        $errors['weight'] = "Weight cannot be empty.";
    } elseif (!is_numeric($weight_input) || $weight_input <= 0) {
        $errors['weight'] = "Enter a valid positive number.";
    } elseif ($weight_input > 300) {
        $errors['weight'] = "Enter a realistic weight (max 300 kg).";
    }

    // Validate height
    if (empty(trim($height_input))) {
        $errors['height'] = "Height cannot be empty.";
    } elseif (!is_numeric($height_input) || $height_input <= 0) {
        $errors['height'] = "Enter a valid positive number.";
    } elseif ($height_input > 250) {
        $errors['height'] = "Enter a realistic height (max 250 cm).";
    }

    // Only calculate if validation passed (no errors)
    if (empty($errors)) {
        $weight     = (float) $weight_input;
        $height     = (float) $height_input / 100;  // convert cm to meters
        $bmi_result = round($weight / ($height * $height), 1);
    }
}
?>

<form method="POST" action="">
    <div class="form-group">
        <label>Weight (kg):</label>
        <input type="text" name="weight" placeholder="e.g. 65"
               class="<?= isset($errors['weight']) ? 'error' : '' ?>"
               value="<?= htmlspecialchars($weight_input) ?>">
        <?php if (isset($errors['weight'])): ?>
            <p class="error-msg"><?= $errors['weight'] ?></p>
        <?php endif; ?>
    </div>

    <div class="form-group">
        <label>Height (cm):</label>
        <input type="text" name="height" placeholder="e.g. 170"
               class="<?= isset($errors['height']) ? 'error' : '' ?>"
               value="<?= htmlspecialchars($height_input) ?>">
        <?php if (isset($errors['height'])): ?>
            <p class="error-msg"><?= $errors['height'] ?></p>
        <?php endif; ?>
    </div>

    <button type="submit">Calculate BMI</button>
</form>

<?php if ($bmi_result !== null):
    if ($bmi_result < 18.5)   { $category = "Underweight"; $bg = "#cce5ff"; }
    elseif ($bmi_result < 25) { $category = "Normal";      $bg = "#d4edda"; }
    elseif ($bmi_result < 30) { $category = "Overweight";  $bg = "#fff3cd"; }
    else                      { $category = "Obese";       $bg = "#f8d7da"; }
?>
    <div class="result" style="background: <?= $bg ?>">
        <h3>Your BMI: <?= $bmi_result ?></h3>
        <p>Category: <strong><?= $category ?></strong></p>
    </div>
<?php endif; ?>

</body>
</html>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-08/bmi-calculator.php
```

Test by submitting with empty fields, then with non-numeric text, then with valid numbers. Notice that the URL does not change after POST submission (unlike the GET form). Also notice that the values you typed remain in the fields after a validation error — this is the sticky form pattern using `value="<?= htmlspecialchars($weight_input) ?>"`.

The `$_SERVER['REQUEST_METHOD'] === 'POST'` check is the standard pattern for a single-file form handler. When the user visits the page the first time, the method is GET (a regular page request), and the processing block is skipped. When they submit the form, the method becomes POST, and the validation and calculation code runs. The `$errors` array collects validation messages, and `empty($errors)` is the gate that prevents the calculation from running if anything failed validation.

---

## 6. Run and Test

After building both forms, take a few minutes to deliberately test edge cases that real users might hit. For the greeting form, try submitting with an empty name field — you should see the warning message. For the BMI calculator, try entering letters instead of numbers — you should see the validation error on that specific field while the other field retains its value.

Open your browser's developer tools (F12) and look at the Network tab when you submit each form. For the GET form you will see the data in the URL. For the POST form you will see the data in the Request Body section, invisible in the URL. This confirms the difference between the two methods at the network level, not just the PHP level.

---

## 7. Fix the Errors in Your Code

```php
<?php
// Error 1: Displaying user input without protection
$name = $_GET['name'];
echo "Hello, " . $name;  // XSS vulnerability!

// Error 2: Wrong method for checking if input arrived
if ($_GET['name']) {      // Error when name is not in $_GET
    echo "Processing...";
}

// Error 3: Displaying data without htmlspecialchars even after validation
$safe_name = strip_tags($_POST['name']);  // strip_tags is NOT enough for display
echo "<p>Welcome, $safe_name!</p>";
?>
```

The first error is an XSS vulnerability: user input is echoed directly without any escaping. If `name` contains `<script>alert('xss')</script>`, that JavaScript will execute. Always wrap user-submitted data in `htmlspecialchars()` before outputting it. The second error uses `$_GET['name']` directly without checking `isset()` first. If no name is in the URL, this produces an "undefined index" notice and the boolean evaluation of a non-existent key is unreliable. Always check `isset($_GET['name'])` first. The third error is a common misconception: `strip_tags()` removes HTML tags but does not escape special characters for HTML display. It is a different tool for a different purpose. For safe output in HTML context, you always need `htmlspecialchars()`.

---

## 8. Exercises

**Exercise 1:** Create `exercise-1.php`. Build a simple search form (GET method) with one text field. When submitted, display "You searched for: [term]" below the form using `htmlspecialchars()`. Handle the case where the form has not yet been submitted.

**Exercise 2:** Create `exercise-2.php`. Build a POST form with fields for name, age, and email. Validate that name is not empty, age is a number between 1 and 120, and email is valid using `filter_var()`. Display errors or a success summary.

**Exercise 3:** Create `exercise-3.php`. Build a basic login form (POST) that checks against hardcoded credentials (username "admin", password "1234"). Display "Login successful" or "Invalid credentials" as appropriate. Do not actually store sessions yet.

---

## 9. Solutions

**Solution for Exercise 1:**

```php
<?php
$search = isset($_GET['q']) ? trim($_GET['q']) : '';
?>
<!DOCTYPE html>
<html lang="en">
<head><title>Search</title></head>
<body>
<form method="GET" action="">
    <input type="text" name="q" value="<?= htmlspecialchars($search) ?>" placeholder="Search...">
    <button type="submit">Search</button>
</form>

<?php if (isset($_GET['q'])): ?>
    <p>You searched for: <strong><?= htmlspecialchars($search) ?></strong></p>
<?php endif; ?>
</body>
</html>
```

**Solution for Exercise 2:**

```php
<?php
$name  = trim($_POST['name']  ?? '');
$age   = trim($_POST['age']   ?? '');
$email = trim($_POST['email'] ?? '');
$errors  = [];
$success = false;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (empty($name)) $errors['name'] = "Name is required.";
    if (!is_numeric($age) || $age < 1 || $age > 120) $errors['age'] = "Enter a valid age (1–120).";
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) $errors['email'] = "Enter a valid email.";
    if (empty($errors)) $success = true;
}
?>
<!DOCTYPE html>
<html lang="en">
<head><title>Registration</title></head>
<body>
<?php if ($success): ?>
    <p style="color:green">Registered: <?= htmlspecialchars($name) ?>, age <?= htmlspecialchars($age) ?>, <?= htmlspecialchars($email) ?></p>
<?php else: ?>
<form method="POST" action="">
    Name: <input name="name" value="<?= htmlspecialchars($name) ?>">
    <?= isset($errors['name']) ? "<span style='color:red'>{$errors['name']}</span>" : "" ?><br>
    Age: <input name="age" value="<?= htmlspecialchars($age) ?>">
    <?= isset($errors['age']) ? "<span style='color:red'>{$errors['age']}</span>" : "" ?><br>
    Email: <input name="email" value="<?= htmlspecialchars($email) ?>">
    <?= isset($errors['email']) ? "<span style='color:red'>{$errors['email']}</span>" : "" ?><br>
    <button type="submit">Submit</button>
</form>
<?php endif; ?>
</body>
</html>
```

---

## 10. Understanding Forms and Security

Forms create a direct channel from the user's browser to your server-side code, which is why security is not optional — it is the first thing to think about. The XSS attack pattern is important enough to understand deeply: when user input is echoed into an HTML page without escaping, any HTML or JavaScript in that input becomes part of the page. An attacker could store a `<script>` tag in a database, and every user who loads the page would execute it. `htmlspecialchars()` prevents this by converting the dangerous characters (`<`, `>`, `"`, `'`, `&`) to their safe HTML entity equivalents, so they display as text rather than being interpreted as code.

Validation is both a security and a usability concern. From a security perspective, you can never trust data that comes from the browser — it might be from a real user, or from an automated tool sending malicious inputs. From a usability perspective, clear error messages that preserve the user's previous input (sticky forms) reduce frustration and abandonment. The `$errors` array pattern used in this lesson is the foundation of almost every form validation system in PHP, from simple scripts to full frameworks.

The `$_SERVER['REQUEST_METHOD']` check cleanly separates first visits from form submissions without needing separate URL routes for showing the form and processing it. This "single-file handler" pattern is clean for simple forms, though larger applications typically separate form display from processing into different routes or controllers.

---

## 11. Conclusion

HTML forms send data to PHP using either GET (visible in URL, bookmarkable, for read operations) or POST (hidden in request body, for write operations). `$_GET` and `$_POST` superglobal arrays receive the submitted values. Always use `isset()` before accessing form data, `htmlspecialchars()` before displaying it, and validation before processing it. Sticky forms preserve user input after errors by setting the `value` attribute on inputs from the previously submitted data.

**In Lesson 9**, you will learn how to organize growing projects by splitting code into multiple files using PHP includes, separating shared layouts from page-specific content.