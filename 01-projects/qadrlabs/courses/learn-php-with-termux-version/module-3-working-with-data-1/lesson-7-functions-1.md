## 1. Before You Begin

Notice something in the code you have written in previous lessons: the longer the program gets, the more often you write the same patterns repeatedly. Calculating an average, formatting a name, checking whether a grade meets a requirement - the code for these things is scattered in many places. If a rule changes, you have to find and change it in every location. This is inefficient and very error-prone.

**Functions** are the solution. A function is a block of code that is given a name and can be called whenever you need it, as many times as you want. You write the logic once, give it a descriptive name, then call that name wherever it is needed. If there is a change, you only need to modify the function definition in one place, and the change automatically applies throughout the entire program.

This is not just about typing efficiency. Functions also make code far easier to read, understand, and maintain. A well-structured program reads like a collection of clearly named functions working together, not one long block that is impossible to follow.

### What You'll Build

You will build a small function library containing helper functions for the Catatku journal program. These functions will handle tasks like formatting dates, calculating grade statistics, and validating input.

### What You'll Learn

- ✅ How to define and call functions
- ✅ How to use parameters to give input to functions
- ✅ How to use default values for parameters
- ✅ How to use `return` to send a result back from a function
- ✅ How to understand variable scope inside and outside functions

### What You'll Need

- Termux open with Apache running (`apachectl`)
- Lessons 1 through 6 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson inside your project directory. All files you create in Lesson 7 should live here.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-07
cd lesson-07
```

`mkdir lesson-07` creates the subfolder and `cd lesson-07` moves you into it. Any file you create after running these commands will be accessible through the browser at `http://localhost:8080/learn-php/lesson-07/`.

---

## 3. Your First Function

Before understanding functions with parameters and return values, start with the simplest kind: a function that runs a fixed set of commands every time it is called. Even a function this simple eliminates repetition and makes code easier to change.

### Step 1: Create a New File

Make sure you are in the `lesson-07` folder, then open a new file:

```bash
micro basic-function.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
function showGreeting() {
    echo "<p>Welcome to our application!</p>";
    echo "<p>Today: " . date("d F Y") . "</p>";
    echo "<p>Have a great day!</p>";
}

echo "<h2>Calling a Function</h2>";
showGreeting();

echo "<hr>";
showGreeting();

echo "<hr>";
showGreeting();

echo "<h2>Definition Order vs Call Order</h2>";
greetUser();

function greetUser() {
    echo "Hello from the greetUser() function! <br>";
}
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-07/basic-function.php
```

You will see the same greeting appear three times, all produced by one function called three times. You write `showGreeting()` once, give the block a name with the `function` keyword, and then invoke it anywhere by writing its name followed by parentheses. Defining a function does not immediately run it - the code inside only executes when you explicitly call it. PHP is also flexible about the order of definitions: notice that `greetUser()` is called before its definition appears in the file, and PHP still finds it. This is because PHP scans the file for function definitions before executing any code. In practice, it is cleaner to define functions before calling them, but it is useful to know PHP allows both orders.

---

## 4. Parameters: Giving Input to Functions

Functions without parameters are quite limited - they always do exactly the same thing. Parameters allow you to give input to a function so the result can vary depending on what you pass in. Think of a function like a recipe: the parameters are the ingredient list, and the function body is the instructions.

### Step 1: Create a New File

Navigate to the `lesson-07` folder and create the file:

```bash
micro function-parameters.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
function greet($name) {
    echo "Hello, $name! Welcome. <br>";
}

greet("Budi");
greet("Citra");
greet("Ahmad");

echo "<hr>";

function introduce($name, $city, $job) {
    echo "<p>My name is <strong>$name</strong>, ";
    echo "I live in <strong>$city</strong>, ";
    echo "working as a <strong>$job</strong>.</p>";
}

introduce("Rina", "Jakarta", "Designer");
introduce("Dodi", "Surabaya", "Programmer");

echo "<hr>";

function makeHeading($text, $level = "h2", $color = "black") {
    echo "<$level style='color: $color;'>$text</$level>";
}

makeHeading("Heading with Defaults");
makeHeading("Red H1 Heading", "h1", "red");
makeHeading("H3 Heading", "h3");

echo "<hr>";

function calculateDiscount($price, $percent = 10) {
    $savings = $price * ($percent / 100);
    echo "Price Rp$price, discount $percent%: save Rp$savings <br>";
}

calculateDiscount(100000);
calculateDiscount(250000, 20);
calculateDiscount(75000, 5);
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-07/function-parameters.php
```

When you define `function greet($name)`, `$name` is a parameter - a placeholder variable that receives the value you pass when calling the function. Calling `greet("Budi")` sends the string `"Budi"` into the function, which stores it in `$name` for the duration of that call. Each call gets its own copy of `$name`, so calls do not interfere with each other. The `introduce` function demonstrates multiple parameters: each argument is matched to its corresponding parameter by position, so the first argument goes into `$name`, the second into `$city`, and the third into `$job`.

Default parameter values make some arguments optional. In `makeHeading($text, $level = "h2", $color = "black")`, only `$text` is required. If you call `makeHeading("Hello")` without the other two, PHP uses `"h2"` and `"black"` automatically. Parameters with default values must always be declared after parameters without defaults. Writing `function makeLabel($color = "blue", $text)` is invalid and causes a fatal error because PHP would not know how to handle a call like `makeLabel("Title")`.

---

## 5. Return Value: Functions That Send Back Results

So far the functions you have written only perform output directly. The most powerful functions are those that calculate something and hand the result back to the caller, so the caller can decide what to do with it. This is what the `return` keyword does.

### Step 1: Create a New File

Navigate to the `lesson-07` folder and create the file:

```bash
micro function-return.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
function calculateRectangleArea($length, $width) {
    $area = $length * $width;
    return $area;
}

$room_area = calculateRectangleArea(5, 4);
echo "Room area: $room_area m² <br>";

echo "Half area: " . (calculateRectangleArea(10, 6) / 2) . " m² <br>";

echo "<hr>";

function formatRupiah($number) {
    return "Rp" . number_format($number, 0, ",", ".");
}

$price    = 1500000;
$discount = 250000;
$total    = $price - $discount;

echo "Price    : " . formatRupiah($price)    . "<br>";
echo "Discount : " . formatRupiah($discount) . "<br>";
echo "Total    : " . formatRupiah($total)    . "<br>";

echo "<hr>";

function isValidEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

function isStrongPassword($password) {
    return strlen($password) >= 8;
}

$email1 = "user@example.com";
$email2 = "not-a-valid-email";
$pass1  = "secret";
$pass2  = "secret123";

echo "Email '$email1' valid? " . (isValidEmail($email1) ? "Yes" : "No") . "<br>";
echo "Email '$email2' valid? " . (isValidEmail($email2) ? "Yes" : "No") . "<br>";
echo "Password '$pass1' strong? " . (isStrongPassword($pass1) ? "Yes" : "No") . "<br>";
echo "Password '$pass2' strong? " . (isStrongPassword($pass2) ? "Yes" : "No") . "<br>";

echo "<hr>";

function calculateFinalGrade($midterm, $final, $assignment) {
    $average = ($midterm * 0.35) + ($final * 0.45) + ($assignment * 0.20);
    return round($average, 1);
}

function determineGrade($score) {
    if ($score >= 85) return "A";
    if ($score >= 75) return "B";
    if ($score >= 65) return "C";
    if ($score >= 55) return "D";
    return "E";
}

$final_score = calculateFinalGrade(80, 88, 75);
$grade       = determineGrade($final_score);
echo "Final score: $final_score. Grade: $grade <br>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-07/function-return.php
```

`return $area` sends the value stored in `$area` back to wherever the function was called from. The calling code can capture it in a variable (`$room_area = calculateRectangleArea(5, 4)`) or use it directly in an expression (`calculateRectangleArea(10, 6) / 2`). Any code written after a `return` statement inside the same function is never executed - `return` immediately exits the function. `formatRupiah` shows how return values replace direct output: the function builds and returns a formatted string, and the caller decides where to put it. This is more flexible than using `echo` inside the function, because the formatted value can be stored, concatenated, or passed to another function. `filter_var($email, FILTER_VALIDATE_EMAIL)` is a PHP built-in that checks whether a string is a properly formed email address. It returns the email string if valid, or `false` if not. Comparing its result to `false` using `!== false` gives a clean boolean. The last example shows functions calling other functions: `calculateFinalGrade` computes the weighted average and `determineGrade` converts that number to a letter. Each function has one responsibility, and together they handle the full logic.

---

## 6. Scope: Variable Visibility

Scope defines where a variable can be accessed. In PHP, variables created inside a function only exist inside that function and are destroyed when the function finishes. Variables created outside a function are not automatically available inside it. Understanding scope is essential because violating it is a common source of confusing bugs.

### Step 1: Create a New File

Navigate to the `lesson-07` folder and create the file:

```bash
micro variable-scope.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
$global_message = "This variable is outside the function (global scope)";

function scopeExample() {
    $local_message = "This variable is inside the function (local scope)";
    echo "Inside function: $local_message <br>";
    // $global_message is NOT accessible here without the global keyword
}

scopeExample();

echo "Outside function: $global_message <br>";
// $local_message does NOT exist here - it was destroyed when the function ended

echo "<hr>";

// Best approach: pass values in through parameters
$username = "Dino";

function greetWithParameter($name) {
    echo "Hello, $name! <br>";
}

greetWithParameter($username);

// Alternative: the global keyword (use sparingly)
function showMessage() {
    global $global_message;
    echo "From function: $global_message <br>";
}

showMessage();

echo "<hr>";

function calculateAndShow() {
    $local_result = 100 * 5;
    echo "Result inside function: $local_result <br>";
    return $local_result;
}

$brought_out = calculateAndShow();
echo "Value brought out via return: $brought_out <br>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-07/variable-scope.php
```

PHP uses function scope by design. Each function works in its own isolated space, which means different functions cannot accidentally read or modify each other's variables. In a large program with hundreds of functions, this isolation is what keeps variables predictable and bugs contained. If PHP gave all functions access to all variables automatically, a single typo in one function could silently corrupt a value that another function was relying on.

The correct way to bring a value into a function is through a parameter: `greetWithParameter($username)` passes the value of `$username` as an argument, and the function receives it in its local copy called `$name`. The `global` keyword is an alternative that lets a function directly access a variable from the outer scope, but it is considered bad practice in most situations because it creates hidden dependencies and makes functions harder to test. The recommended pattern is always: data goes into a function through parameters, and data comes out through `return`.

---

## 7. Small Project: Student Grade Report

Now let's combine functions, arrays, and loops to build a grade report that is clean, readable, and easy to modify. The key lesson here is how well-named functions make the main program logic almost self-documenting.

### Step 1: Create a New File

Navigate to the `lesson-07` folder and create the file:

```bash
micro grade-report.php
```

### Step 2: Write the Code

Type the following code into the editor:

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
        .fail { color: red; font-weight: bold; }
    </style>
</head>
<body>
<?php
function calculateAverage($scores) {
    if (count($scores) === 0) return 0;
    return round(array_sum($scores) / count($scores), 1);
}

function determineGrade($average) {
    if ($average >= 90) return "A";
    if ($average >= 80) return "B";
    if ($average >= 70) return "C";
    if ($average >= 60) return "D";
    return "E";
}

function determineStatus($average, $passing = 70) {
    return ($average >= $passing) ? "Pass" : "Fail";
}

function formatName($name) {
    return ucwords(strtolower(trim($name)));
}

$students = [
    ["name" => "andi SETIAWAN",  "scores" => [85, 78, 90, 82]],
    ["name" => "BUDI laksono",   "scores" => [60, 55, 70, 65]],
    ["name" => "citra dewi",     "scores" => [92, 88, 95, 90]],
    ["name" => "DONI pratama",   "scores" => [45, 52, 60, 50]],
    ["name" => "eka wahyuni",    "scores" => [75, 80, 72, 78]],
];

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
    $name   = formatName($s["name"]);
    $avg    = calculateAverage($s["scores"]);
    $grade  = determineGrade($avg);
    $status = determineStatus($avg);
    $class  = ($status === "Pass") ? "pass" : "fail";

    $total_avg += $avg;
    if ($status === "Pass") $pass_count++;

    echo "<tr>
        <td>" . ($i + 1) . "</td>
        <td>$name</td>";
    foreach ($s["scores"] as $n) {
        echo "<td>$n</td>";
    }
    echo "<td><strong>$avg</strong></td>
        <td>$grade</td>
        <td class='$class'>$status</td>
    </tr>";
}
echo "</table>";

$class_avg    = round($total_avg / count($students), 1);
$pass_percent = round(($pass_count / count($students)) * 100);
echo "<p>Class average: <strong>$class_avg</strong> | ";
echo "Passed: <strong>$pass_count of " . count($students) . " students ($pass_percent%)</strong></p>";
?>
</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-07/grade-report.php
```

Notice how clean the main loop is. The lines `$avg = calculateAverage($s["scores"])`, `$grade = determineGrade($avg)`, and `$status = determineStatus($avg)` read almost like plain English. The calculation logic is entirely hidden inside the functions, and the main program only needs to know the function names and what they return. `formatName` uses `trim()` to remove any leading or trailing whitespace, `strtolower()` to convert the entire string to lowercase, and `ucwords()` to capitalize the first letter of every word. This normalizes messy input like `"andi SETIAWAN"` or `"BUDI laksono"` into properly formatted names. `array_sum($scores)` adds all elements in the array and returns the total as a single number, saving you from writing a loop to accumulate the sum manually.

---

## 8. Fix the Errors in Your Code

This section presents three mistakes that are specific to how functions work in PHP. Each one causes either a parse error, unexpected output, or a variable that silently returns an empty value.

**Error 1: A hyphen in a function name.**

PHP function names can only contain letters, numbers, and underscores. The hyphen (`-`) is the subtraction operator in PHP, so `calculate-total` is parsed as "the value of `calculate` minus `total`", not a function name. This causes an immediate parse error.

```php
// Wrong
function calculate-total($a, $b) {
    return $a + $b;
}

// Correct
function calculateTotal($a, $b) {
    return $a + $b;
}
```

Use camelCase (`calculateTotal`) or snake_case (`calculate_total`) for multi-word function names. Both are valid PHP. The PHP community convention for functions and methods is camelCase.

---

**Error 2: A parameter with a default value placed before a required parameter.**

PHP processes function arguments left to right. If a parameter with a default value appears before a required one, PHP has no way to know which argument you intended to skip when you call the function with fewer arguments than it has parameters.

```php
// Wrong
function makeLabel($color = "blue", $text) {
    return "<span style='color:$color'>$text</span>";
}

// Correct
function makeLabel($text, $color = "blue") {
    return "<span style='color:$color'>$text</span>";
}
```

Required parameters must always come first, and optional parameters (with defaults) must follow them. With the correct ordering, calling `makeLabel("Hello")` works fine: `$text` receives `"Hello"` and `$color` falls back to `"blue"`.

---

**Error 3: Trying to access a local variable from outside the function.**

Variables created inside a function are local to that function. They do not exist in the global scope and cannot be read after the function returns without using `return`.

```php
// Wrong
function calculateTax($price) {
    $tax   = $price * 0.11;
    $total = $price + $tax;
}

$item_price = 500000;
calculateTax($item_price);
echo "Total with tax: $total"; // $total does not exist here

// Correct
function calculateTax($price) {
    $tax   = $price * 0.11;
    $total = $price + $tax;
    return $total;
}

$item_price    = 500000;
$total_payment = calculateTax($item_price);
echo "Total with tax: $total_payment";
```

Without `return $total`, the function calculates the value and then destroys it when it finishes. The `echo` outside then tries to access `$total` in the global scope, where it does not exist, and PHP produces either a warning or a blank value. Adding `return $total` sends the value out of the function, and capturing it in `$total_payment` makes it available in the global scope.

---

## 9. Exercises

Complete the following exercises in the `lesson-07` folder. Use `micro` to create each file and view the results through `http://localhost:8080/learn-php/lesson-07/`.

**Exercise 1:** Create `exercise-1.php`. Build three separate functions: `circleArea($radius)` that returns the area of a circle, `circleCircumference($radius)` that returns the circumference, and `circleInfo($radius)` that calls both previous functions and displays the complete results. Use a PI value of `3.14159`.

**Exercise 2:** Create `exercise-2.php`. Build a function `censorWord($text, $forbidden_word)` that accepts a sentence and a word to remove, then returns the sentence with every occurrence of that word replaced by asterisks (`***`). The number of asterisks should match the length of the forbidden word. Test it with several different sentences.

**Exercise 3:** Create `exercise-3.php`. Build a function `arraySummary($number_array)` that accepts an array of numbers and returns a new associative array containing: `total`, `average`, `highest`, `lowest`, and `count`. Use this function to analyze `[88, 72, 95, 60, 83, 77, 91]` and display the results.

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
    $area          = round(circleArea($radius), 2);
    $circumference = round(circleCircumference($radius), 2);
    echo "<h3>Circle with radius $radius cm</h3>";
    echo "Area          : $area cm² <br>";
    echo "Circumference : $circumference cm <br>";
}

circleInfo(7);
circleInfo(10);
circleInfo(3.5);
?>
```

`circleArea` and `circleCircumference` each return a raw number. `circleInfo` calls both of them, wraps the results in `round()` to limit the decimal places, and then handles the output. This separation of calculation and display is good practice: if you later need the area as a number (for further calculation), you can call `circleArea()` directly without the output getting in the way. Calling `circleInfo(3.5)` demonstrates that parameters work with any numeric type, including floats.

---

**Solution for Exercise 2:**

```php
<?php
function censorWord($text, $forbidden_word) {
    $stars = str_repeat("*", strlen($forbidden_word));
    return str_ireplace($forbidden_word, $stars, $text);
}

echo censorWord("I like eating fried rice and steamed rice.", "rice") . "<br>";
echo censorWord("This movie is terrible, the acting is terrible.", "terrible") . "<br>";
echo censorWord("PHP is an awesome language!", "awesome") . "<br>";
?>
```

`strlen($forbidden_word)` counts the number of characters in the forbidden word. `str_repeat("*", strlen(...))` creates a string of that many asterisks, so the replacement visually preserves the word length. `str_ireplace($forbidden_word, $stars, $text)` performs a case-insensitive search-and-replace across the entire sentence and replaces every occurrence. Using `str_ireplace` instead of `str_replace` means the function also catches variations like "Rice" or "RICE", not just the exact case provided.

---

**Solution for Exercise 3:**

```php
<?php
function arraySummary($number_array) {
    return [
        "count"   => count($number_array),
        "total"   => array_sum($number_array),
        "average" => round(array_sum($number_array) / count($number_array), 2),
        "highest" => max($number_array),
        "lowest"  => min($number_array),
    ];
}

$data   = [88, 72, 95, 60, 83, 77, 91];
$result = arraySummary($data);

echo "<h2>Data Summary</h2>";
echo "Data    : " . implode(", ", $data) . "<br>";
echo "Count   : " . $result["count"]   . " numbers<br>";
echo "Total   : " . $result["total"]   . "<br>";
echo "Average : " . $result["average"] . "<br>";
echo "Highest : " . $result["highest"] . "<br>";
echo "Lowest  : " . $result["lowest"]  . "<br>";
?>
```

`arraySummary` returns an associative array rather than a single value, which is a clean way to return multiple related results from one function call. `array_sum()` adds all elements and returns the total. `max()` and `min()` find the largest and smallest values respectively, without needing a loop. The caller accesses each result by key: `$result["highest"]`, `$result["lowest"]`, and so on. This design means you can add more statistics to the function later (like median or variance) without changing how it is called.

---

## Next Up - Lesson 8

Functions are one of the most important concepts in programming: write the logic once in a named block, call it wherever it is needed, and change it in exactly one place when requirements evolve. Parameters bring data into a function, and `return` sends results back out. Variable scope keeps each function isolated in its own space, which prevents accidental interference between unrelated parts of a program. The correct way to share data between functions is always through parameters and return values.

In Lesson 8, you will learn about working with HTML forms - how to capture user input submitted through a form, process it with PHP using `$_GET` and `$_POST`, and validate it before using it. This is the point where your programs become truly interactive.