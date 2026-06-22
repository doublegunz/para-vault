## 1. Before You Begin

For the last seven lessons, you have written PHP programs that receive data directly from the code - variable values are determined by the programmer, not by the user. In the real world, programs must be able to receive input from the people using them: a name typed in a registration form, a keyword in a search field, or data filled in an order form.

This is where **HTML forms** and **PHP superglobals** (`$_GET` and `$_POST`) come in. HTML forms are the interface in the browser where users fill in and send data, while PHP on the server side captures, validates, and processes that data. This flow underlies almost every interaction on the web: login, search, ordering, profile editing - they all begin with a form.

### What You'll Build

You will build three interactive programs: a simple greeting form using the GET method, a BMI calculator that receives height and weight from the user using the POST method, and a complete registration form with comprehensive input validation.

### What You'll Learn

- ✅ How to create HTML forms and connect them to PHP files
- ✅ The difference between GET and POST methods and when to use each
- ✅ How to retrieve data from forms using `$_GET` and `$_POST`
- ✅ How to protect output from XSS attacks using `htmlspecialchars()`
- ✅ How to perform basic input validation before processing data
- ✅ How to display informative error and success messages

### What You'll Need

- Termux open with Apache running (`apachectl`)
- Lessons 1 through 7 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson inside your project directory. All files you create in Lesson 8 should live here.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-08
cd lesson-08
```

`mkdir lesson-08` creates the subfolder and `cd lesson-08` moves you into it. Any file you create from this point will be served by Apache at `http://localhost:8080/learn-php/lesson-08/`.

---

## 3. GET vs POST: Two Ways to Send Data

Before writing any form code, you need to understand the fundamental difference between the two submission methods, because this choice affects both security and user experience in every form you will ever build.

**The GET method** sends data by appending it directly to the URL. When you fill in the name "Budi" in a GET form, the browser URL changes to `page.php?name=Budi`. The data is visible in the URL, can be bookmarked, and can be shared as a link. Because of this visibility, GET is not safe for sensitive information. Use GET for searches or filters where the data is acceptable to expose.

**The POST method** sends data hidden inside the HTTP request body. It does not appear in the URL, cannot be bookmarked directly, and is the correct choice for sensitive information like passwords or personal data. Use POST for login forms, registration, data entry, or any operation that changes something on the server.

---

## 4. First Form: The GET Method

The GET method is the simpler of the two to understand because its results are visible in the browser address bar. This makes it easy to observe exactly what data was sent and how PHP receives it.

### Step 1: Create a New File

Make sure you are in the `lesson-08` folder, then open a new file:

```bash
micro form-get.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <title>GET Form - Greeting</title>
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
    <input type="text" name="name" placeholder="Type your name here"
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
            "morning"   => "Good morning",
            "afternoon" => "Good afternoon",
            "evening"   => "Good evening",
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
    Notice the URL when the form is submitted - the name and time data appear in the URL!
</p>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL, fill in a name, select a time, and click "Send":

```
http://localhost:8080/learn-php/lesson-08/form-get.php
```

After submitting, the browser URL will change to something like `form-get.php?name=Budi&time=morning`. That is the GET method at work: the form data is serialized into the URL as a query string.

`isset($_GET['name'])` checks whether the key `'name'` exists in the `$_GET` superglobal. On the very first page load before any form is submitted, `$_GET` is empty and `isset()` returns `false`, so the processing block is skipped entirely. After submission, `$_GET['name']` contains whatever the user typed. `htmlspecialchars()` is a security function you must call on every piece of user-supplied data before inserting it into HTML output. Without it, a user could type `<script>alert('hacked')</script>` as their name, and that code would execute in every browser that loads the page. This attack is called XSS (Cross-Site Scripting). `htmlspecialchars()` neutralizes it by converting `<` to `&lt;` and `>` to `&gt;`, so the text is displayed literally rather than interpreted as HTML. `empty(trim($name))` combines two checks: `trim()` strips surrounding whitespace so that a name field filled with only spaces counts as empty, and `empty()` confirms the resulting string has no content.

---

## 5. Form with POST Method: BMI Calculator

POST is more appropriate than GET when the form sends sensitive or numerically calculated data. This BMI calculator also introduces the pattern of server-side validation: PHP checks the submitted values before doing any computation and collects error messages that are displayed back to the user.

### Step 1: Create a New File

Navigate to the `lesson-08` folder and create the file:

```bash
micro bmi-calculator.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <title>BMI Calculator</title>
    <style>
        body  { font-family: Arial, sans-serif; max-width: 500px; margin: 50px auto; padding: 0 20px; }
        .form-group { margin-bottom: 15px; }
        label { display: block; font-weight: bold; margin-bottom: 4px; }
        input { padding: 10px; border: 1px solid #ccc; border-radius: 6px; width: 100%; box-sizing: border-box; }
        input.error { border-color: red; }
        .error-msg { color: red; font-size: 0.85em; margin-top: 4px; }
        button { padding: 12px 25px; background: #28a745; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 1em; width: 100%; }
        .result { margin-top: 25px; padding: 20px; border-radius: 10px; text-align: center; }
    </style>
</head>
<body>

<h2>BMI Calculator</h2>
<p>Calculate your Body Mass Index!</p>

<?php
$weight_input = $_POST['weight'] ?? '';
$height_input = $_POST['height'] ?? '';
$errors       = [];
$bmi_result   = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (empty(trim($weight_input))) {
        $errors['weight'] = "Weight cannot be empty.";
    } elseif (!is_numeric($weight_input) || $weight_input <= 0) {
        $errors['weight'] = "Enter a valid positive number.";
    } elseif ($weight_input > 300) {
        $errors['weight'] = "Enter a realistic weight (max 300 kg).";
    }

    if (empty(trim($height_input))) {
        $errors['height'] = "Height cannot be empty.";
    } elseif (!is_numeric($height_input) || $height_input <= 0) {
        $errors['height'] = "Enter a valid positive number.";
    } elseif ($height_input > 250) {
        $errors['height'] = "Enter a realistic height (max 250 cm).";
    }

    if (empty($errors)) {
        $weight     = (float) $weight_input;
        $height     = (float) $height_input / 100;
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
    if ($bmi_result < 18.5)     { $category = "Underweight"; $bg = "#cce5ff"; }
    elseif ($bmi_result < 25)   { $category = "Normal";      $bg = "#d4edda"; }
    elseif ($bmi_result < 30)   { $category = "Overweight";  $bg = "#fff3cd"; }
    else                        { $category = "Obese";        $bg = "#f8d7da"; }
?>
    <div class="result" style="background: <?= $bg ?>">
        <h3>Your BMI: <?= $bmi_result ?></h3>
        <p>Category: <strong><?= $category ?></strong></p>
        <p style="font-size: 0.85em; color: #666;">
            BMI = weight(kg) / height(m)² = <?= $weight_input ?>kg / (<?= $height_input/100 ?>m)²
        </p>
    </div>
<?php endif; ?>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL and test it with empty fields, non-numeric values, and finally valid data:

```
http://localhost:8080/learn-php/lesson-08/bmi-calculator.php
```

Notice that the URL does not change after submission - that is the POST method. Also notice that previously filled values stay in the fields after a validation error. This behavior is called sticky forms.

`$_SERVER['REQUEST_METHOD'] === 'POST'` checks how the page was reached. On the first load, the method is `GET` (a regular browser navigation), so the validation block is skipped. Only after the form is submitted does `REQUEST_METHOD` become `'POST'`, triggering the validation. The `$errors` array collects all validation failures by field name. Each field's error is stored at a key matching the field name (for example, `$errors['weight']`), which makes it easy to check and display the error right next to the corresponding input. `is_numeric()` returns true if the value can be interpreted as a number, which handles both integer and float inputs. Checking `$weight_input > 300` validates the plausible range. The BMI formula is `weight / (height_in_meters * height_in_meters)`, so the centimeter value from the form must be divided by 100 before squaring. Placing validation logic before the HTML form in the file is the standard pattern: PHP runs the check first, populates `$errors`, then the HTML below reads from that array.

---

## 6. Complete Registration Form

A registration form is the most complete form you will build in this course. It brings together all form techniques - multiple field types, validation for each field, sticky values on error, and a success message when everything passes. The patterns here are directly applicable to every login, signup, or data-entry form you will build in any future project.

### Step 1: Create a New File

Navigate to the `lesson-08` folder and create the file:

```bash
micro registration-form.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Registration Form</title>
    <style>
        body  { font-family: Arial, sans-serif; max-width: 500px; margin: 50px auto; padding: 0 20px; }
        .form-group { margin-bottom: 15px; }
        label { display: block; font-weight: bold; margin-bottom: 4px; }
        input, select, textarea { padding: 8px; border: 1px solid #ccc; border-radius: 4px; width: 100%; box-sizing: border-box; }
        input.error, select.error { border-color: red; }
        .error-msg { color: red; font-size: 0.85em; margin-top: 4px; }
        button { padding: 12px 25px; background: #0077cc; color: white; border: none; border-radius: 6px; cursor: pointer; width: 100%; }
        .success { background: #d1e7dd; padding: 20px; border-radius: 8px; }
    </style>
</head>
<body>
<h2>Create an Account</h2>

<?php
function val($arr, $key) { return htmlspecialchars($arr[$key] ?? ''); }

$field   = ['username' => '', 'email' => '', 'gender' => '', 'bio' => ''];
$errors  = [];
$success = false;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    foreach ($field as $k => $v) { $field[$k] = trim($_POST[$k] ?? ''); }
    $password = $_POST['password'] ?? '';

    if (empty($field['username'])) {
        $errors['username'] = 'Username is required.';
    } elseif (strlen($field['username']) < 3) {
        $errors['username'] = 'Username must be at least 3 characters.';
    } elseif (!preg_match('/^[a-zA-Z0-9_]+$/', $field['username'])) {
        $errors['username'] = 'Username can only contain letters, numbers, and underscores.';
    }

    if (empty($field['email'])) {
        $errors['email'] = 'Email is required.';
    } elseif (!filter_var($field['email'], FILTER_VALIDATE_EMAIL)) {
        $errors['email'] = 'Please enter a valid email address.';
    }

    if (empty($password)) {
        $errors['password'] = 'Password is required.';
    } elseif (strlen($password) < 8) {
        $errors['password'] = 'Password must be at least 8 characters.';
    }

    if (empty($field['gender']) || !in_array($field['gender'], ['male', 'female'])) {
        $errors['gender'] = 'Please select a valid gender.';
    }

    if (empty($errors)) { $success = true; }
}

if ($success): ?>
    <div class="success">
        <h3>Registration Successful!</h3>
        <p>Welcome, <strong><?= val($field, 'username') ?></strong>!</p>
        <p>Email: <?= val($field, 'email') ?></p>
        <p>Gender: <?= val($field, 'gender') ?></p>
        <?php if (!empty($field['bio'])): ?>
            <p>Bio: <?= val($field, 'bio') ?></p>
        <?php endif; ?>
    </div>
<?php else: ?>
    <form method="POST" action="">
        <div class="form-group">
            <label>Username</label>
            <input type="text" name="username" placeholder="e.g. budi_santoso"
                   class="<?= isset($errors['username']) ? 'error' : '' ?>"
                   value="<?= val($field, 'username') ?>">
            <?php if (isset($errors['username'])): ?>
                <p class="error-msg"><?= $errors['username'] ?></p>
            <?php endif; ?>
        </div>

        <div class="form-group">
            <label>Email</label>
            <input type="text" name="email" placeholder="name@example.com"
                   class="<?= isset($errors['email']) ? 'error' : '' ?>"
                   value="<?= val($field, 'email') ?>">
            <?php if (isset($errors['email'])): ?>
                <p class="error-msg"><?= $errors['email'] ?></p>
            <?php endif; ?>
        </div>

        <div class="form-group">
            <label>Password</label>
            <input type="password" name="password" placeholder="At least 8 characters"
                   class="<?= isset($errors['password']) ? 'error' : '' ?>">
            <?php if (isset($errors['password'])): ?>
                <p class="error-msg"><?= $errors['password'] ?></p>
            <?php endif; ?>
        </div>

        <div class="form-group">
            <label>Gender</label>
            <select name="gender" class="<?= isset($errors['gender']) ? 'error' : '' ?>">
                <option value="">Select gender</option>
                <option value="male"   <?= $field['gender'] === 'male'   ? 'selected' : '' ?>>Male</option>
                <option value="female" <?= $field['gender'] === 'female' ? 'selected' : '' ?>>Female</option>
            </select>
            <?php if (isset($errors['gender'])): ?>
                <p class="error-msg"><?= $errors['gender'] ?></p>
            <?php endif; ?>
        </div>

        <div class="form-group">
            <label>Short Bio <span style="font-weight:normal;color:#888">(optional)</span></label>
            <textarea name="bio" rows="3" placeholder="Tell us a bit about yourself..."><?= val($field, 'bio') ?></textarea>
        </div>

        <button type="submit">Register Now</button>
    </form>
<?php endif; ?>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL and test all scenarios:

```
http://localhost:8080/learn-php/lesson-08/registration-form.php
```

Try submitting the empty form, entering an invalid email, a username that is too short or contains special characters, and a password under 8 characters. Notice that all previously filled values remain in their fields after validation fails, and error messages appear directly below the field that caused them.

The `val($arr, $key)` helper function at the top applies `htmlspecialchars()` and the null-coalescing operator in one call, preventing repetition across every field. The `foreach` loop that collects POST data applies `trim()` to every field at once, removing the need to call it individually in each validation rule. `preg_match('/^[a-zA-Z0-9_]+$/', $field['username'])` is a regular expression that matches the entire string from start (`^`) to end (`$`) and only accepts letters, digits, and underscores. If the username contains any other character, the match fails and the error is recorded. `filter_var($field['email'], FILTER_VALIDATE_EMAIL)` uses PHP's built-in email validator, which is more reliable than writing a custom regular expression. The `if ($success): ... else: ... endif;` block uses PHP's alternative syntax for mixing PHP control structures with HTML, which is easier to read than nested curly braces when large HTML blocks are involved.

---

## 7. Fix the Errors in Your Code

This section presents three mistakes that are extremely common when developers first write form-processing PHP. Two of them produce PHP warnings, and one creates a serious security vulnerability.

**Error 1: Accessing `$_POST` directly without checking if a submission has occurred.**

When the page loads for the first time, no form has been submitted yet and `$_POST` is empty. Accessing `$_POST['message']` directly produces an "Undefined array key" warning in PHP 8 and silently returns `null` in earlier versions. Either way, the code is unreliable.

```php
// Wrong
$message = $_POST['message'];

// Correct
$message = $_POST['message'] ?? '';
```

The null-coalescing operator (`??`) returns the left side if it exists, or the right side if it does not. Assigning a safe default of `''` means `$message` is always a string, even on the first page load before any POST data arrives. An alternative is wrapping the entire block in `if ($_SERVER['REQUEST_METHOD'] === 'POST')` so the processing code only runs after a real form submission.

---

**Error 2: Displaying user input directly without `htmlspecialchars()`.**

Printing `$message` directly into the HTML page creates an XSS (Cross-Site Scripting) vulnerability. A user could submit `<script>alert('hacked')</script>` as their message, and that JavaScript would execute in every browser that loads the page.

```php
// Wrong
echo "Your message: " . $message;

// Correct
echo "Your message: " . htmlspecialchars($message);
```

`htmlspecialchars()` converts the characters `<`, `>`, `"`, `'`, and `&` to their HTML entity equivalents. The dangerous `<script>` tag becomes the harmless text `&lt;script&gt;`, which the browser displays as literal characters rather than executing as code. Always apply `htmlspecialchars()` to any value that came from user input before inserting it into HTML output.

---

**Error 3: Using `$_POST['message']` directly inside a condition instead of the sanitized variable.**

After sanitizing `$message`, using `$_POST['message']` again in the condition bypasses the sanitization and reintroduces the exact same problems as Error 1 and Error 2.

```php
// Wrong
if ($_POST['message'] == "") {
    echo "Message is empty!";
}

// Correct
if (empty(trim($message))) {
    echo "Message is empty!";
}
```

`empty(trim($message))` is the correct check because it uses the already-sanitized variable and handles both an empty string and a string containing only whitespace. Calling `trim()` first strips spaces, so a message of `"   "` (several spaces) is correctly recognized as empty.

---

## 8. Exercises

Complete the following exercises in the `lesson-08` folder. Use `micro` to create each file and view the results through `http://localhost:8080/learn-php/lesson-08/`.

**Exercise 1:** Create `exercise-1.php`. Build a simple calculator form using the GET method with two number fields and an operation dropdown (add, subtract, multiply, divide). Display the calculation result and handle division by zero with an error message.

**Exercise 2:** Create `exercise-2.php`. Build a temperature converter form using POST. Include a number input for the temperature value and a dropdown with two conversion directions: Celsius to Fahrenheit, or Fahrenheit to Celsius. Display the result and the formula used. Validate that the input is numeric.

**Exercise 3:** Create `exercise-3.php`. Build a ticket booking form using POST with fields for passenger name, destination (dropdown: Yogyakarta, Surabaya, Bali), departure date, and number of tickets (1 to 5). Validate all fields, calculate the total price based on the selected destination (assign a different price to each city), and display a booking summary when all inputs are valid.

---

## 9. Solutions

**Solution for Exercise 1:**

```php
<!DOCTYPE html>
<html lang="en">
<head><title>Simple Calculator</title></head>
<body>
<h2>GET Calculator</h2>
<form method="GET" action="">
    <input type="number" name="a" value="<?= htmlspecialchars($_GET['a'] ?? '') ?>" placeholder="First number">
    <select name="op">
        <?php foreach (['+' => 'Add', '-' => 'Subtract', '*' => 'Multiply', '/' => 'Divide'] as $v => $l): ?>
            <option value="<?= $v ?>" <?= ($_GET['op'] ?? '') === $v ? 'selected' : '' ?>><?= $l ?></option>
        <?php endforeach; ?>
    </select>
    <input type="number" name="b" value="<?= htmlspecialchars($_GET['b'] ?? '') ?>" placeholder="Second number">
    <button type="submit">Calculate</button>
</form>
<?php
if (isset($_GET['a'], $_GET['b'], $_GET['op'])) {
    $a  = (float) $_GET['a'];
    $b  = (float) $_GET['b'];
    $op = $_GET['op'];

    if ($op === '/' && $b == 0) {
        echo "<p style='color:red'>Cannot divide by zero!</p>";
    } else {
        $result = match($op) {
            '+' => $a + $b,
            '-' => $a - $b,
            '*' => $a * $b,
            '/' => $a / $b,
        };
        echo "<p>Result: <strong>$a $op $b = $result</strong></p>";
    }
}
?>
</body>
</html>
```

`isset($_GET['a'], $_GET['b'], $_GET['op'])` checks all three required values at once: if any of them is missing, the processing block is skipped. Casting with `(float)` converts the string values from `$_GET` into numbers before any arithmetic, preventing PHP from treating them as strings. The `match` expression (available in PHP 8+) maps each operator symbol to its corresponding arithmetic operation. Division by zero is checked before the `match` block because dividing by zero in PHP triggers a warning and returns either `INF` or `NAN`, not the error message you want to show.

---

**Solution for Exercise 2:**

```php
<!DOCTYPE html>
<html lang="en">
<head><title>Temperature Converter</title></head>
<body>
<h2>Temperature Converter</h2>
<form method="POST" action="">
    <input type="number" step="0.1" name="temp" value="<?= htmlspecialchars($_POST['temp'] ?? '') ?>" placeholder="Temperature value">
    <select name="direction">
        <option value="cf" <?= ($_POST['direction'] ?? '') === 'cf' ? 'selected' : '' ?>>Celsius to Fahrenheit</option>
        <option value="fc" <?= ($_POST['direction'] ?? '') === 'fc' ? 'selected' : '' ?>>Fahrenheit to Celsius</option>
    </select>
    <button type="submit">Convert</button>
</form>
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $temp      = trim($_POST['temp'] ?? '');
    $direction = $_POST['direction'] ?? 'cf';

    if (empty($temp) || !is_numeric($temp)) {
        echo "<p style='color:red'>Please enter a valid number.</p>";
    } else {
        $temp = (float) $temp;
        if ($direction === 'cf') {
            $result = round(($temp * 9/5) + 32, 2);
            echo "<p>$temp Celsius = <strong>$result Fahrenheit</strong></p>";
            echo "<p><small>Formula: (C x 9/5) + 32</small></p>";
        } else {
            $result = round(($temp - 32) * 5/9, 2);
            echo "<p>$temp Fahrenheit = <strong>$result Celsius</strong></p>";
            echo "<p><small>Formula: (F - 32) x 5/9</small></p>";
        }
    }
}
?>
</body>
</html>
```

Checking `$_SERVER['REQUEST_METHOD'] === 'POST'` ensures the conversion only runs after the form is submitted, not on the initial page load. `is_numeric($temp)` validates that the input can be used in a mathematical formula before the cast to float. The two conversion formulas are standard temperature conversions: multiplying Celsius by 9/5 and adding 32 gives Fahrenheit, while subtracting 32 from Fahrenheit and multiplying by 5/9 gives Celsius. `round(..., 2)` limits the result to two decimal places, which is sufficient precision for temperature display.

---

**Solution for Exercise 3:**

```php
<!DOCTYPE html>
<html lang="en">
<head><title>Book Ticket</title></head>
<body>
<h2>Book Bus Ticket</h2>
<?php
$prices  = ['Yogyakarta' => 85000, 'Surabaya' => 120000, 'Bali' => 250000];
$field   = ['name' => '', 'destination' => '', 'date' => '', 'quantity' => ''];
$errors  = [];
$success = false;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    foreach ($field as $k => $v) $field[$k] = trim($_POST[$k] ?? '');
    if (empty($field['name']))                              $errors['name']        = "Name is required.";
    if (!array_key_exists($field['destination'], $prices))  $errors['destination'] = "Select a valid destination.";
    if (empty($field['date']))                              $errors['date']        = "Select a departure date.";
    if (!is_numeric($field['quantity']) || $field['quantity'] < 1 || $field['quantity'] > 5)
        $errors['quantity'] = "Ticket quantity must be between 1 and 5.";
    if (empty($errors)) $success = true;
}
if ($success):
    $total = $prices[$field['destination']] * $field['quantity'];
?>
    <div style="background:#d1e7dd;padding:20px;border-radius:8px">
        <h3>Booking Successful!</h3>
        <p>Name: <strong><?= htmlspecialchars($field['name']) ?></strong></p>
        <p>Destination: <strong><?= $field['destination'] ?></strong></p>
        <p>Date: <strong><?= $field['date'] ?></strong></p>
        <p>Tickets: <strong><?= $field['quantity'] ?></strong></p>
        <p>Total: <strong>Rp<?= number_format($total, 0, ',', '.') ?></strong></p>
    </div>
<?php else: ?>
<form method="POST">
    <p>Name: <input type="text" name="name" value="<?= htmlspecialchars($field['name']) ?>">
        <?= isset($errors['name']) ? "<br><span style='color:red'>{$errors['name']}</span>" : '' ?></p>
    <p>Destination: <select name="destination">
        <option value="">Select destination</option>
        <?php foreach ($prices as $city => $price): ?>
            <option value="<?= $city ?>" <?= $field['destination'] === $city ? 'selected' : '' ?>>
                <?= $city ?> (Rp<?= number_format($price, 0, ',', '.') ?>)
            </option>
        <?php endforeach; ?>
    </select> <?= isset($errors['destination']) ? "<br><span style='color:red'>{$errors['destination']}</span>" : '' ?></p>
    <p>Date: <input type="date" name="date" value="<?= $field['date'] ?>">
        <?= isset($errors['date']) ? "<br><span style='color:red'>{$errors['date']}</span>" : '' ?></p>
    <p>Tickets (1-5): <input type="number" name="quantity" min="1" max="5" value="<?= htmlspecialchars($field['quantity']) ?>">
        <?= isset($errors['quantity']) ? "<br><span style='color:red'>{$errors['quantity']}</span>" : '' ?></p>
    <button type="submit">Book Ticket</button>
</form>
<?php endif; ?>
</body>
</html>
```

`array_key_exists($field['destination'], $prices)` validates the destination by checking whether the submitted value exists as a key in the `$prices` array, which is more reliable than comparing against a hardcoded list of strings. If someone manually edits the URL to submit an unexpected destination, this check catches it. The `foreach ($prices as $city => $price)` loop in the form builds the dropdown options dynamically from the same array used for pricing, so adding a new destination only requires updating the `$prices` array in one place. The total is calculated as `$prices[$field['destination']] * $field['quantity']`, which only runs after validation confirms both that the destination is valid and that the quantity is a number between 1 and 5.

---

## Next Up - Lesson 9

HTML forms are the bridge between the user and your PHP code. The GET method sends data visibly in the URL and is suited for searches and filters. The POST method hides data in the request body and is correct for logins, registrations, and any operation that modifies data. Always use `htmlspecialchars()` on user input before displaying it, always validate server-side before trusting any value, and use the `$errors` array pattern to collect and display validation messages field by field.

In Lesson 9, you will learn how to organize code across multiple files using `require` and `include`. This is the technique that lets you write a header once and reuse it across every page, keeping your project clean and consistent as it grows.