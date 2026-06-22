## 1. Before You Begin

As you write more PHP, you will start noticing patterns: the same calculation appearing in multiple places, the same formatting logic copied from one file to another. Every time you copy code, you create a maintenance problem — when the logic needs to change, you have to find and update every copy. Functions exist to prevent exactly this.

### Introduction

A function is a named block of code that you write once and call by name as many times as needed. Whenever you need that behavior, you simply say the function's name rather than repeating the code. Functions are not just about avoiding repetition — they also make code easier to read by giving complex operations meaningful names, and easier to test because you can verify one function in isolation.

### What You'll Build

You will build a small helper library of functions for the Catatku project, including functions that format currency, calculate statistics, validate email addresses, and generate grade reports.

### What You'll Learn

- ✅ Defining functions and calling them
- ✅ Parameters: giving input to functions
- ✅ Default parameter values
- ✅ Return values: functions that produce results
- ✅ Variable scope: why variables inside functions are private
- ✅ Combining functions to build larger programs

### What You'll Need

- Laragon running
- VS Code open in the `learn-php` folder
- Lessons 1 through 6 completed

---

## 2. Setup

Create a new subfolder called `lesson-07` inside the `learn-php` folder.

---

## 3. Your First Function

The simplest functions perform an action when called, without needing any input from outside. They are perfect for repeatable output patterns.

### Step 1: Create a New File

Create a file called `basic-function.php` in the `lesson-07` folder.

### Step 2: Write the Code

Open `basic-function.php` and type the following code:

```php
<?php
// Define a function using the 'function' keyword, a name, and ()
// The code block inside {} runs ONLY when the function is called
function showGreeting() {
    echo "<p>Welcome to our application!</p>";
    echo "<p>Today: " . date("d F Y") . "</p>";
    echo "<p>Have a great day!</p>";
}

// Defining a function does not execute it — it just makes it available
// To run it, call it by name with parentheses
echo "<h2>First Call</h2>";
showGreeting();

echo "<hr>";
echo "<h2>Second Call — Same Code, No Rewriting</h2>";
showGreeting();

echo "<h2>PHP Allows Calling Before Defining</h2>";
// In PHP, functions can be called BEFORE their definition in the file
// PHP scans the entire file for function definitions before executing
greetUser();   // Called here...

function greetUser() {
    echo "Hello from greetUser()! <br>";
}
// ...but defined here — this still works
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-07/basic-function.php
```

The greeting appears twice from a single definition. If you needed to change the date format or add a new line, you change the function body once and both calls update automatically. The behavior of calling before defining may seem unusual — most languages require functions to be defined before they are used — but PHP performs a pre-scan to collect function definitions before executing any code, which is why it works.

---

## 4. Parameters: Giving Input to Functions

A function without parameters always does the same thing. Parameters are the inputs you pass to a function so it can produce different results for different situations.

### Step 1: Create a New File

Create a file called `function-parameters.php` in the `lesson-07` folder.

### Step 2: Write the Code

Open `function-parameters.php` and type the following code:

```php
<?php
// A parameter is a variable declared inside the () of a function definition
// When the function is called, the caller provides the actual value (called an argument)
function greet($name) {
    echo "Hello, $name! Welcome. <br>";
}

greet("Budi");    // "Budi" is the argument — it becomes $name inside the function
greet("Citra");   // "Citra" becomes $name for this call
greet("Ahmad");

echo "<hr>";

// Multiple parameters — each separated by a comma
function introduce($name, $city, $job) {
    echo "<p>My name is <strong>$name</strong>, ";
    echo "I live in <strong>$city</strong>, ";
    echo "working as a <strong>$job</strong>.</p>";
}

introduce("Rina", "Jakarta", "Designer");
introduce("Dodi", "Surabaya", "Programmer");

echo "<hr>";

// DEFAULT PARAMETER VALUES
// If the caller does not provide an argument, the default is used instead
// RULE: Parameters with defaults must come AFTER parameters without defaults
function makeHeading($text, $level = "h2", $color = "black") {
    echo "<$level style='color: $color;'>$text</$level>";
}

makeHeading("Heading With Defaults");              // Uses h2 and black
makeHeading("Red H1 Heading", "h1", "red");        // All three provided
makeHeading("Blue H3 Heading", "h3", "blue");      // All three provided

echo "<hr>";

// Practical example with a useful default
function calculateDiscount($price, $percent = 10) {
    $savings = $price * ($percent / 100);
    echo "Price Rp$price, discount $percent%: save Rp$savings <br>";
}

calculateDiscount(100000);         // Uses default 10%
calculateDiscount(250000, 20);     // Uses 20%
calculateDiscount(75000, 5);       // Uses 5%
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-07/function-parameters.php
```

Parameters work like variables that are automatically created and assigned when the function is called. Notice the rule about default parameters: they must appear after any parameters without defaults. The reason is that PHP matches arguments to parameters by position — the first argument goes to the first parameter, the second to the second, and so on. If a required parameter came after an optional one, PHP would not know which parameter to skip.

---

## 5. Return Values: Getting Results Back

Functions that only print output are limited because you cannot use their results in further calculations. The `return` keyword lets a function send a result back to the caller, making the function into a building block that other code can use.

### Step 1: Create a New File

Create a file called `function-return.php` in the `lesson-07` folder.

### Step 2: Write the Code

Open `function-return.php` and type the following code:

```php
<?php
// A function with a return value sends data back to the caller using 'return'
// After 'return' executes, the function stops — no code after it runs
function calculateRectangleArea($length, $width) {
    $area = $length * $width;
    return $area;   // send the result to wherever the function was called from
}

// The returned value can be stored in a variable
$room_area = calculateRectangleArea(5, 4);
echo "Room area: $room_area m² <br>";

// Or used directly in expressions
echo "Half area: " . (calculateRectangleArea(10, 6) / 2) . " m² <br>";

echo "<hr>";

// Functions that return formatted strings
function formatRupiah($number) {
    return "Rp" . number_format($number, 0, ",", ".");
}

$price    = 1500000;
$discount = 250000;
$total    = $price - $discount;

// Notice how the return value fits cleanly into concatenation expressions
echo "Price    : " . formatRupiah($price)    . "<br>";
echo "Discount : " . formatRupiah($discount) . "<br>";
echo "Total    : " . formatRupiah($total)    . "<br>";

echo "<hr>";

// Functions that return boolean — very useful for validation
function isValidEmail($email) {
    // PHP's built-in filter_var checks the format rigorously
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

function isStrongPassword($password) {
    return strlen($password) >= 8;
}

$tests = [
    "email"    => ["user@example.com", "not-a-valid-email"],
    "password" => ["secret", "secret123"],
];

foreach ($tests["email"] as $email) {
    $valid = isValidEmail($email) ? "Valid" : "Invalid";
    echo "Email '$email': $valid <br>";
}

foreach ($tests["password"] as $pass) {
    $strong = isStrongPassword($pass) ? "Strong enough" : "Too short";
    echo "Password '$pass': $strong <br>";
}
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-07/function-return.php
```

Return values transform functions from one-way actions into two-way conversations: you send inputs in, and you get a result back. This is what makes functions composable — the output of `formatRupiah()` can become the input to `echo`, or the return of `calculateRectangleArea()` can be divided by 2. Building programs from small, focused functions that communicate through return values is one of the core principles of good software design.

---

## 6. Variable Scope

Variables declared inside a function are private to that function. They do not exist outside it, and variables outside the function are not automatically accessible inside it. This privacy is called scope, and it is a feature, not a limitation.

### Step 1: Create a New File

Create a file called `variable-scope.php` in the `lesson-07` folder.

### Step 2: Write the Code

Open `variable-scope.php` and type the following code:

```php
<?php
$global_message = "I am outside the function";

function showScope() {
    // $global_message is NOT accessible here — it is outside this function's scope
    // Trying to echo it would produce a notice and empty output
    $local_var = "I only exist inside showScope()";
    echo "$local_var <br>";
}

showScope();

// $local_var is NOT accessible here — it only existed during showScope()'s execution
echo "After the function: trying to access local_var: ";
echo isset($local_var) ? $local_var : "(not available — as expected)" ;
echo "<br>";

echo "<hr>";

// The correct way to share data: parameters (in) and return (out)
function doubleAndFormat($number) {
    $doubled = $number * 2;       // $doubled lives only here
    return "Result: " . $doubled; // sends the result out as a return value
}

$input  = 50;
$result = doubleAndFormat($input);  // $result holds the returned value
echo $result . "<br>";

echo "<hr>";

// The global keyword forces access to an outside variable (use sparingly)
$counter = 0;

function incrementCounter() {
    global $counter;   // explicitly declare that we want the global $counter
    $counter++;
}

incrementCounter();
incrementCounter();
echo "Counter: $counter <br>";  // 2

echo "<p><strong>Note:</strong> Using <code>global</code> is generally discouraged. ";
echo "Passing values as parameters and returning results is cleaner and more predictable.</p>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-07/variable-scope.php
```

Scope exists to prevent functions from accidentally interfering with each other. Without scope, every function could read and modify every variable, making programs very difficult to debug because changing one function could mysteriously affect another. The rule is: use parameters to pass data into a function and `return` to send data out. The `global` keyword exists as an escape hatch for special cases, but in general code it leads to hard-to-trace bugs and should be used rarely.

---

## 7. Small Project: Grade Report

Now build something substantial using multiple functions together to demonstrate how functions create clean, readable, and maintainable code.

### Step 1: Create a New File

Create a file called `grade-report.php` in the `lesson-07` folder.

### Step 2: Write the Code

Open `grade-report.php` and type the following code:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Grade Report</title>
    <style>
        body  { font-family: Arial, sans-serif; max-width: 700px; margin: 30px auto; padding: 0 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td{ padding: 10px 12px; border: 1px solid #ddd; text-align: left; }
        th    { background: #f0f0f0; }
        .pass { color: green; font-weight: bold; }
        .fail { color: red;   font-weight: bold; }
    </style>
</head>
<body>
<?php
// ===== FUNCTION DEFINITIONS =====

// Calculates the average of an array of numbers
function calculateAverage($scores) {
    if (count($scores) === 0) return 0;
    return round(array_sum($scores) / count($scores), 1);
}

// Converts a numeric average to a letter grade
function determineGrade($average) {
    if ($average >= 90) return "A";
    if ($average >= 80) return "B";
    if ($average >= 70) return "C";
    if ($average >= 60) return "D";
    return "E";
}

// Checks if the average meets the passing threshold (default: 70)
function determineStatus($average, $passing = 70) {
    return ($average >= $passing) ? "Pass" : "Fail";
}

// Cleans up inconsistently capitalized names
function formatName($name) {
    return ucwords(strtolower(trim($name)));
}

// ===== STUDENT DATA — messy names are intentional to test formatName() =====
$students = [
    ["name" => "andi SETIAWAN",  "scores" => [85, 78, 90, 82]],
    ["name" => "BUDI laksono",   "scores" => [60, 55, 70, 65]],
    ["name" => "citra dewi",     "scores" => [92, 88, 95, 90]],
    ["name" => "DONI pratama",   "scores" => [45, 52, 60, 50]],
    ["name" => "eka wahyuni",    "scores" => [75, 80, 72, 78]],
];

// ===== DISPLAY =====
echo "<h1>Student Grade Report</h1>";
echo "<table>
    <tr>
        <th>No</th><th>Name</th>
        <th>Midterm</th><th>Final</th><th>Assignment</th><th>Practical</th>
        <th>Average</th><th>Grade</th><th>Status</th>
    </tr>";

$total_avg  = 0;
$pass_count = 0;

foreach ($students as $i => $s) {
    $name   = formatName($s["name"]);        // clean up the capitalization
    $avg    = calculateAverage($s["scores"]); // compute the average
    $grade  = determineGrade($avg);           // convert to letter
    $status = determineStatus($avg);          // check pass/fail
    $class  = ($status === "Pass") ? "pass" : "fail";

    $total_avg += $avg;
    if ($status === "Pass") $pass_count++;

    echo "<tr>
        <td>" . ($i + 1) . "</td>
        <td>$name</td>";
    foreach ($s["scores"] as $n) echo "<td>$n</td>";
    echo "<td><strong>$avg</strong></td>
        <td>$grade</td>
        <td class='$class'>$status</td>
    </tr>";
}
echo "</table>";

$class_avg    = round($total_avg / count($students), 1);
$pass_percent = round(($pass_count / count($students)) * 100);
echo "<p>Class average: <strong>$class_avg</strong> | ";
echo "Passed: <strong>$pass_count of " . count($students) . " ($pass_percent%)</strong></p>";
?>
</body>
</html>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-07/grade-report.php
```

Read through the main section of this program after looking at the functions. The lines `$name = formatName(...)`, `$avg = calculateAverage(...)`, `$grade = determineGrade(...)` read almost like a description of the business logic rather than technical code. This self-documenting quality is one of the greatest benefits of well-named functions: someone unfamiliar with the code can understand what it does just by reading the function calls.

---

## 8. Fix the Errors in Your Code

```php
<?php
// Error 1: Function name contains a hyphen
function calculate-total($a, $b) {
    return $a + $b;
}

// Error 2: Default parameter before required parameter
function makeLabel($color = "blue", $text) {
    return "<span style='color:$color'>$text</span>";
}

// Error 3: Trying to use a local variable outside the function
function calculateTax($price) {
    $tax   = $price * 0.11;
    $total = $price + $tax;
}

calculateTax(500000);
echo "Total with tax: $total";   // $total doesn't exist here
?>
```

The first error is in the function name: PHP identifiers can contain only letters, numbers, and underscores. The hyphen `-` is the subtraction operator, so `calculate-total` would be parsed as subtracting `total` from `calculate`, which makes no sense. Rename it `calculateTotal` or `calculate_total`. The second error violates the parameter ordering rule: `$color` has a default value but `$text` does not. Required parameters must always come first. Swap them: `function makeLabel($text, $color = "blue")`. The third error is the classic scope mistake: `$total` is declared inside `calculateTax()` and exists only during that function's execution. After the function returns, `$total` disappears. Fix this by adding `return $total;` inside the function and capturing the result: `$result = calculateTax(500000); echo "Total: $result";`.

---

## 9. Exercises

**Exercise 1:** Create `exercise-1.php`. Write three functions: `circleArea($radius)`, `circleCircumference($radius)`, and `circleInfo($radius)` which calls both and displays the results. Use PI = 3.14159.

**Exercise 2:** Create `exercise-2.php`. Write a function `censorWord($text, $forbidden_word)` that replaces all occurrences of the forbidden word with asterisks. Test it with several sentences.

**Exercise 3:** Create `exercise-3.php`. Write a function `arraySummary($numbers)` that returns an associative array with keys `count`, `total`, `average`, `highest`, and `lowest`. Display all values for the array `[88, 72, 95, 60, 83, 77, 91]`.

---

## 10. Solutions

**Solution for Exercise 1:**

```php
<?php
function circleArea($radius) {
    return 3.14159 * $radius * $radius;
}

function circleCircumference($radius) {
    return 2 * 3.14159 * $radius;
}

function circleInfo($radius) {
    echo "<h3>Circle with radius $radius cm</h3>";
    echo "Area          : " . round(circleArea($radius), 2) . " cm² <br>";
    echo "Circumference : " . round(circleCircumference($radius), 2) . " cm <br>";
}

circleInfo(7);
circleInfo(10);
?>
```

**Solution for Exercise 2:**

```php
<?php
function censorWord($text, $forbidden_word) {
    $stars = str_repeat("*", strlen($forbidden_word));
    return str_ireplace($forbidden_word, $stars, $text);  // case-insensitive replace
}

echo censorWord("I like eating fried rice and steamed rice.", "rice") . "<br>";
echo censorWord("This movie is terrible, the acting is terrible.", "terrible") . "<br>";
?>
```

**Solution for Exercise 3:**

```php
<?php
function arraySummary($numbers) {
    return [
        "count"   => count($numbers),
        "total"   => array_sum($numbers),
        "average" => round(array_sum($numbers) / count($numbers), 2),
        "highest" => max($numbers),
        "lowest"  => min($numbers),
    ];
}

$data   = [88, 72, 95, 60, 83, 77, 91];
$result = arraySummary($data);

echo "<h2>Array Summary</h2>";
foreach ($result as $key => $value) {
    echo ucfirst($key) . ": <strong>$value</strong> <br>";
}
?>
```

---

## 11. Understanding Functions

Functions implement one of the most important principles in software engineering: Don't Repeat Yourself (DRY). Every time you copy a block of code to a new location, you create a future maintenance burden. When that logic needs to change — and it always does eventually — you must find and update every copy. Functions centralize the logic so changes happen in one place.

The discipline of writing functions with clear names also has a secondary benefit: it forces you to think clearly about what each piece of your program does. If you struggle to name a function, it often means the function is doing too many things at once and should be split into smaller, more focused functions. Good function names read like descriptions of behavior: `formatRupiah`, `isValidEmail`, `calculateAverage`.

Variable scope is a safety mechanism, not an obstacle. Without scope, debugging PHP would be significantly harder because any function could accidentally overwrite any variable. Scope means functions are predictable: given the same inputs, they always produce the same outputs, regardless of what other code is running elsewhere in the program.

---

## 12. Conclusion

Functions are named, reusable blocks of code that accept inputs through parameters and return results with `return`. Parameters with default values must appear after required ones. Variables inside functions are private (local scope) and do not affect or see variables outside. Use parameters to pass data in and `return` to send results out. The `global` keyword grants access to outside variables but should be used sparingly. Well-named functions make code readable and maintainable.

**In Lesson 8**, you will learn how to handle HTML form submissions with `$_GET` and `$_POST` — the step that makes your PHP programs interactive and responsive to real user input.