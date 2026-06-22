## 1. Before You Begin

In the previous lesson you displayed text to the browser using `echo`. But everything you displayed was static — always exactly the same text, written directly into the code. In the real world, programs must handle data that changes: a user's name, a product's price, today's date, or whether someone is logged in. Variables are how PHP handles data that needs to be stored, reused, or processed.

### Introduction

This lesson introduces two of the most fundamental concepts in all of programming. A variable is a named container that holds a value, and a data type describes what kind of value that container holds. Together they form the vocabulary that every PHP program is built from. You cannot build a login form, a shopping cart, or a database query without understanding how to store and classify data.

### What You'll Build

You will create several small programs: one that displays a "profile card" styled with CSS and populated entirely from variables, one that calculates the area and perimeter of a rectangle, and one that demonstrates how to inspect variable types for debugging.

### What You'll Learn

- ✅ How to create and use variables in PHP
- ✅ The naming rules that every variable must follow
- ✅ The four basic PHP data types: integer, float, string, and boolean
- ✅ How to use `var_dump()` and `gettype()` to inspect variables during debugging
- ✅ The critical difference between double quotes and single quotes when using variables

### What You'll Need

- Laragon running (Apache is green)
- Visual Studio Code open in the `learn-php` folder
- Lesson 1 and 2 completed

---

## 2. Setup

Inside the `learn-php` folder in VS Code, right-click and select **New Folder**, type `lesson-03`, and press Enter. You should now see it in the Explorer panel alongside the `lesson-02` folder you created earlier.

---

## 3. Your First Variables

A variable in PHP is like a labeled box. You give the box a name, put a value inside it, and any time you need that value later, you refer to the box by its name. PHP will open the box and hand you what is inside.

### Step 1: Create a New File

In the `lesson-03` folder, create a new file called `basic-variables.php`.

### Step 2: Write the Code

Open `basic-variables.php` and type the following code:

```php
<?php
// All variables in PHP start with a dollar sign ($)
// followed by the variable name, an equals sign (=), then the value

$name = "Budi Santoso";
$city = "Bandung";
$age  = 25;

// After a variable is created, you can use it anywhere
echo "Hello, my name is " . $name . ".";
echo "<br>";
echo "I live in " . $city . ".";
echo "<br>";
echo "I am " . $age . " years old.";
?>
```

### Step 3: Save the File

Press **Ctrl+S**.

### Step 4: Run in the Browser

```
http://localhost/learn-php/lesson-03/basic-variables.php
```

You should see three lines of text with the values from your variables filled in. Now try changing the value of `$name` from "Budi Santoso" to your own name and refresh the browser. All three output lines that reference the variable update instantly. This is the fundamental power of variables: you change the data in one place and all outputs that depend on it reflect the change.

Now let us look at each part of the code carefully. The dollar sign `$` is mandatory in PHP — without it, PHP treats the word as a constant or keyword, not a variable. The variable name `name` follows specific rules: it must start with a letter or underscore, can contain letters, numbers, and underscores, cannot contain spaces, and is case-sensitive (meaning `$name` and `$Name` are two entirely different variables). The equals sign `=` is the assignment operator — it means "store the value on the right inside the container on the left." The dot `.` between strings and variables is PHP's concatenation operator; it joins multiple values into a single piece of text for output. Notice that `$age = 25` does not use quotation marks, because 25 is a number, not text. Data types determine this distinction, which is the topic of Section 5.

---

## 4. Double Quotes vs Single Quotes with Variables

PHP provides a more concise way to include variables inside text, but it only works with one type of quote. Understanding this distinction saves a lot of debugging time.

### Step 1: Create a New File

Create a file called `double-vs-single-quotes.php` in the `lesson-03` folder.

### Step 2: Write the Code

Open `double-vs-single-quotes.php` and type the following code:

```php
<?php
$product = "Laptop";
$price   = 8500000;

// Method 1: Concatenation with dot (.) — always works
echo "Product: " . $product . ", Price: Rp" . $price;
echo "<br>";

// Method 2: Variable interpolation — variable directly inside double-quoted string
// PHP sees the $ sign inside double quotes and replaces it with the variable's value
echo "Product: $product, Price: Rp$price";
echo "<br>";

// Method 3: Interpolation with curly braces — clearer when variable is adjacent to other text
echo "Product: {$product}, Price: Rp{$price}";
echo "<br>";

// CRITICAL DIFFERENCE:
// Inside DOUBLE quotes — variables are replaced with their value
echo "Value: $product";
echo "<br>";

// Inside SINGLE quotes — the dollar sign is treated as a literal character
// The variable name is printed as-is, NOT replaced
echo 'Value: $product';
echo "<br>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-03/double-vs-single-quotes.php
```

Look at the last two lines of output carefully. The double-quote line shows `Value: Laptop` while the single-quote line shows `Value: $product` literally. This difference is called string interpolation and it only works inside double-quoted strings. PHP scans double-quoted strings and replaces anything that looks like a variable name (starting with `$`) with the variable's actual value. Single-quoted strings are completely literal — PHP never processes their contents. This is why the choice of quote type matters when you intend to embed a variable.

The curly brace form `{$product}` is useful when you need a variable immediately next to other characters without a space: for example `"I own {$count}kg"` makes it clear that `count` is the variable name and `kg` is separate text. Without braces, `"$countkg"` would try to find a variable named `$countkg`.

---

## 5. The Four Basic PHP Data Types

PHP recognizes different categories of values, and understanding these categories is essential because data types affect how PHP performs operations, how values compare, and how data is stored in databases. For beginners, four types cover the vast majority of situations.

### Step 1: Create a New File

Create a file called `data-types.php` in the `lesson-03` folder.

### Step 2: Write the Code

Open `data-types.php` and type the following code:

```php
<?php
// ===== TYPE 1: INTEGER (whole numbers) =====
// Integers are numbers without decimal points
// They can be positive, negative, or zero
$student_count = 30;
$temperature   = -5;
$zero_value    = 0;

echo "<h2>Integer</h2>";
echo "Student count: $student_count <br>";
echo "Temperature: $temperature degrees <br>";

// ===== TYPE 2: FLOAT (decimal numbers) =====
// Floats (also called doubles) hold numbers with decimal points
// In PHP, always use a dot (.) as the decimal separator, never a comma
$price  = 15500.50;
$height = 1.75;
$pi     = 3.14159;

echo "<h2>Float</h2>";
echo "Price: Rp$price <br>";
echo "Height: $height meters <br>";
echo "PI value: $pi <br>";

// ===== TYPE 3: STRING (text) =====
// Strings hold any sequence of characters — one letter, a word, a sentence,
// even a number inside quotes is a string!
$name       = "Citra Dewi";
$city       = 'Surabaya';
$message    = "Happy learning PHP!";
$number_str = "123";  // This is a STRING even though it looks like a number

echo "<h2>String</h2>";
echo "Name: $name <br>";
echo "City: $city <br>";
echo "Message: $message <br>";
echo "Number as string: $number_str <br>";

// ===== TYPE 4: BOOLEAN (true or false) =====
// Booleans have only two possible values: true or false
// They are the foundation of all conditional logic
$is_logged_in  = true;
$has_error     = false;
$passing_grade = true;

echo "<h2>Boolean</h2>";
// When you echo a boolean, true shows as "1" and false shows as "" (nothing)
echo "Logged in: ";
echo $is_logged_in;   // Displays: 1
echo "<br>";
echo "Has error: ";
echo $has_error;       // Displays: (empty — nothing is shown)
echo "<br>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-03/data-types.php
```

Notice how the boolean `$has_error` outputs nothing at all on the screen. This can be confusing when debugging, which is why the `var_dump()` function in the next section is so useful. Also pay attention to `$number_str = "123"` — this is a string that contains digit characters, not an integer. The value has quotation marks around it, which makes it a string. PHP can sometimes convert it automatically when you do arithmetic, but it is important to recognize the difference between the number `123` (no quotes) and the string `"123"` (with quotes).

---

## 6. Inspecting Variables with var_dump() and gettype()

As programs grow more complex, you will frequently need to check what type of value a variable holds and what its current value is. PHP provides two excellent tools for this.

### Step 1: Create a New File

Create a file called `inspect-variables.php` in the `lesson-03` folder.

### Step 2: Write the Code

Open `inspect-variables.php` and type the following code:

```php
<?php
$name   = "Ahmad";
$age    = 22;
$height = 1.68;
$active = true;

echo "<h2>Using gettype()</h2>";
// gettype() returns the type name as a plain string
echo "Type of \$name: "   . gettype($name)   . "<br>";   // string
echo "Type of \$age: "    . gettype($age)    . "<br>";   // integer
echo "Type of \$height: " . gettype($height) . "<br>";   // double (PHP's name for float)
echo "Type of \$active: " . gettype($active) . "<br>";   // boolean

echo "<h2>Using var_dump()</h2>";
// var_dump() is more powerful — it shows type AND value together
// Wrap in <pre> to format the output neatly
echo "<pre>";
var_dump($name);    // string(5) "Ahmad"  — type, length, value
var_dump($age);     // int(22)            — type and value
var_dump($height);  // float(1.68)        — type and value
var_dump($active);  // bool(true)         — type and value (shows "true" not "1"!)
echo "</pre>";

echo "<h2>Changing Variable Values</h2>";
// Variables can be reassigned at any time
$score = 75;
echo "Initial score: $score <br>";

$score = 90;  // The old value 75 is gone, replaced by 90
echo "Updated score: $score <br>";

// PHP even allows changing the type of a variable (dynamic typing)
$data = 100;
echo "Before: ";
var_dump($data);   // int(100)
echo "<br>";

$data = "one hundred";  // Now a string lives in the same variable
echo "After: ";
var_dump($data);   // string(11) "one hundred"
echo "<br>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-03/inspect-variables.php

```

Look at the `var_dump()` output carefully. For the string "Ahmad", it shows `string(5) "Ahmad"` — the number 5 is the length of the string in characters. For the boolean `$active`, it shows `bool(true)` rather than just `1`, which is much clearer than `echo`. When a variable contains something unexpected, `var_dump()` will tell you both what is there and what type it is. Whenever a program behaves unexpectely, adding a `var_dump()` call is usually the fastest way to diagnose the problem, which is why this is sometimes called the "PHP developer's best friend."

The note about `gettype()` returning `double` for floats is a technical quirk inherited from the C programming language where PHP was built. The type is functionally identical to "float" — just PHP calling it by a different name.

---

## 7. Small Project: Profile Card

Now bring everything together to build something that looks like a real web component. This project demonstrates how separating data from presentation makes code easy to change.

### Step 1: Create a New File

Create a file called `profile-card.php` in the `lesson-03` folder.

### Step 2: Write the Code

Open `profile-card.php` and type the following code:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Profile Card</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f0f0f0; }
        .card {
            background: white;
            width: 300px;
            margin: 50px auto;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h2 { color: #333; margin-bottom: 5px; }
        p  { color: #666; margin: 5px 0; }
    </style>
</head>
<body>
<?php
    // All the profile data lives up here as variables
    // This is the "data" section — easy to change in one place
    $name       = "Rina Kusuma";
    $occupation = "Web Developer";
    $city       = "Jakarta";
    $age        = 28;
    $email      = "rina@example.com";
    $active     = true;

    // The ternary operator (? :) produces one of two values based on a condition
    // If $active is true, $status gets "Active"; otherwise it gets "Inactive"
    $status = $active ? "Active" : "Inactive";
?>
    <div class="card">
        <h2><?php echo $name; ?></h2>
        <p><strong>Occupation:</strong> <?php echo $occupation; ?></p>
        <p><strong>City:</strong> <?php echo $city; ?></p>
        <p><strong>Age:</strong> <?php echo $age; ?> years</p>
        <p><strong>Email:</strong> <?php echo $email; ?></p>
        <p><strong>Status:</strong> <?php echo $status; ?></p>
    </div>
</body>
</html>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-03/profile-card.php
```

You should see a neat white card with a subtle shadow on a gray background. Now try changing the values at the top of the PHP block — swap the name, city, age — and refresh the browser. The card updates its content without touching any of the HTML structure or CSS styling below. This separation of data from presentation is a principle that scales all the way up to professional-grade frameworks.

---

## 8. Fix the Errors in Your Code

Examine the following code and identify all three errors before reading the answers below:

```php
<?php
$user Name = "Siti";          // Error 1
$age = 20
$city = 'Yogyakarta';
echo "Hello $username";        // Error 2
echo "Age: " . $age . " years";
echo "City: " + $city;         // Error 3
?>
```

The first error is that variable names cannot contain spaces. `$user Name` is invalid syntax. It should be written as either `$userName` (camelCase) or `$user_name` (snake_case). The second error is a case mismatch: the variable is defined as `$user Name` (even after correcting the space issue, as `$userName`) but referenced as `$username`. PHP's case-sensitivity means `$username` and `$userName` are two entirely different variables. The third error uses the wrong operator for joining text. The `+` sign in PHP is the arithmetic addition operator, not a string joiner. PHP would try to add "Yogyakarta" to an empty left-hand side numerically, producing 0. The concatenation operator is the dot `.`, not the plus sign.

The corrected code:

```php
<?php
$userName = "Siti";             // No spaces, consistent casing
$age      = 20;                 // Semicolon added
$city     = 'Yogyakarta';
echo "Hello $userName";         // Spelling matches the variable definition
echo "<br>";
echo "Age: " . $age . " years";
echo "<br>";
echo "City: " . $city;          // Dot for concatenation, not plus
?>
```

---

## 9. Exercises

**Exercise 1:** Create a file called `exercise-1.php` that stores your personal data (name, age, height, city, and a student status boolean) in variables, then displays everything in a clean HTML format. Use the ternary operator to display "Still studying" or "Graduated" based on the boolean.

**Exercise 2:** Create a file called `exercise-2.php` that stores the length (15) and width (8) of a rectangle in variables, calculates the area (length × width) and perimeter (2 × (length + width)), then displays all four values clearly.

**Exercise 3:** Create a file called `exercise-3.php` with one variable of each of the four basic types, then use `var_dump()` to display full type information for each, wrapped in `<pre>` tags for readability.

---

## 10. Solutions

**Solution for Exercise 1:**

```php
<?php
$name      = "Your Name";
$age       = 20;
$height    = 1.70;
$city      = "Your City";
$isStudent = true;

// The ternary operator chooses between two values based on the condition
$status = $isStudent ? "Still studying" : "Graduated";

echo "<h2>Personal Data</h2>";
echo "<p>Name: $name</p>";
echo "<p>Age: $age years</p>";
echo "<p>Height: $height meters</p>";
echo "<p>City: $city</p>";
echo "<p>Status: $status</p>";
?>
```

**Solution for Exercise 2:**

```php
<?php
$length    = 15;
$width     = 8;
$area      = $length * $width;
$perimeter = 2 * ($length + $width);

echo "<h2>Rectangle</h2>";
echo "<p>Length: $length cm</p>";
echo "<p>Width: $width cm</p>";
echo "<p>Area: $area cm²</p>";
echo "<p>Perimeter: $perimeter cm</p>";
?>
```

**Solution for Exercise 3:**

```php
<?php
$wholeNumber   = 42;
$decimalNumber = 3.14;
$text          = "Learning PHP";
$isTrue        = true;

echo "<pre>";
var_dump($wholeNumber);    // int(42)
var_dump($decimalNumber);  // float(3.14)
var_dump($text);           // string(12) "Learning PHP"
var_dump($isTrue);         // bool(true)
echo "</pre>";
?>
```

---

## 11. Understanding Variables and Data Types

Variables are the most fundamental tool in any programming language because programs exist to process data, and data needs somewhere to live. The naming rules (start with `$`, no spaces, case-sensitive) are not arbitrary restrictions — they exist so PHP can unambiguously parse your code. A space inside a variable name would make it impossible for PHP to tell where the variable name ends and the next part of the statement begins.

Data types exist because the computer stores integers, decimals, text, and boolean flags completely differently in memory, and different operations make sense for different types. You can add two integers, you can concatenate two strings, but adding a string to an integer is ambiguous (should "100" become 100 first?). PHP handles type mismatches automatically in many cases through a process called type coercion, but understanding types helps you predict and control that behavior rather than being surprised by it.

The `var_dump()` function is your most reliable debugging tool when starting out. Whenever a variable contains an unexpected value, or you are not sure whether a value is an integer or a string, wrapping it in `var_dump()` and refreshing the browser tells you exactly what PHP sees. This habit of checking your assumptions with `var_dump()` saves far more time than it costs.

---

## 12. Conclusion

Variables are the storage containers of every PHP program. They always start with `$`, follow naming rules, and are case-sensitive. PHP's four basic data types — integer for whole numbers, float for decimals, string for text, and boolean for true/false — determine what kind of data a variable holds and what operations you can perform on it. Double quotes allow variable interpolation, single quotes treat content literally. Use `var_dump()` when you need to see exactly what is inside a variable.

**In Lesson 4**, you will learn about operators and control structures — how to perform calculations, compare values, and make your program choose different paths based on conditions.