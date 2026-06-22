## 1. Before You Begin

In the previous lesson, you were able to display text to the browser using `echo`. But all the text you displayed was static - always the same every time it ran. In the real world, a useful program must work with data that changes: different usernames, different values, and varying information.

This is where **variables** come in. A variable is a named container that can store a value, and you can use that value repeatedly, change it, or process it further. In addition to variables, you will also get to know **data types**: the categories of values that PHP can store, such as numbers, text, or true/false values.

### What You'll Build

You will create several PHP programs that demonstrate the use of variables and different data types, including a simple profile card built from variables, a rectangle calculator, and a product display page.

### What You'll Learn

- ✅ How to create and use variables in PHP
- ✅ Correct variable naming rules
- ✅ The four basic PHP data types: integer, float, string, and boolean
- ✅ How to use `var_dump()` and `gettype()` to inspect variables
- ✅ The difference between double quotes and single quotes when using variables

### What You'll Need

- Termux open with Apache running (`apachectl`)
- micro editor available in the `learn-php` folder
- Lessons 1 and 2 completed

---

## 2. Setup

Before writing any code, you need to create a dedicated folder for this lesson's files. All PHP files you create in this lesson should live inside the `lesson-03` subfolder of your project directory, so the web server can serve them at the correct URL.

### Create a New Lesson Folder

Open Termux and run the following two commands:

```bash
mkdir -p ~/storage/shared/htdocs/learn-php/lesson-03
cd ~/storage/shared/htdocs/learn-php/lesson-03
```

The first command creates the `lesson-03` folder inside the `learn-php` project folder. The `-p` flag ensures that all intermediate directories are created in one step. The second command moves you into that folder so every file you create next goes into the right place.

---

## 3. Your First Variables

Think of a variable like a labeled box. You give the box a name, put a value inside it, and whenever you need that value later you refer to it by name. PHP uses the `$` sign to mark every variable.

### Step 1: Create a New File

Make sure you are in the `lesson-03` folder, then open a new file:

```bash
micro basic-variables.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
$name = "Budi Santoso";
$city = "Bandung";
$age  = 25;

echo "Hello, my name is " . $name . ".";
echo "<br>";
echo "I live in " . $city . ".";
echo "<br>";
echo "I am " . $age . " years old.";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

`$name = "Budi Santoso";` is called an assignment. The `$` sign marks the variable, `name` is its label, and `"Budi Santoso"` is the value stored inside it. Variable names must start with a letter or underscore, cannot contain spaces, and are case-sensitive, so `$name` and `$Name` are two completely different variables. The dot (`.`) between strings is the concatenation operator - it joins pieces of text together to form a single output. Notice that `$age = 25` stores a number without quotation marks, while `$name` and `$city` use quotes because they store text. This distinction is the beginning of data types.

### Step 3: View in the Browser

Open the following URL in your browser:

```
http://localhost:8080/learn-php/lesson-03/basic-variables.php
```

You should see three lines of text where the values come from the variables you defined. If you change `"Budi Santoso"` to a different name and refresh the page, the browser displays the new value without you touching the `echo` lines. That separation between data and output is one of the most important ideas in programming.

---

## 4. Double Quotes vs Single Quotes with Variables

PHP offers a second way to embed variables inside text called string interpolation. Instead of joining strings with the dot operator, you place the variable directly inside a double-quoted string and PHP replaces it with its value automatically. Understanding when interpolation works - and when it does not - is important because the choice of quote character changes the behavior entirely.

### Step 1: Create a New File

Navigate to the `lesson-03` folder and create the file:

```bash
micro double-vs-single-quotes.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
$product = "Laptop";
$price   = 8500000;

// Method 1: Concatenation with the dot operator
echo "Product: " . $product . ", Price: Rp" . $price;
echo "<br>";

// Method 2: Interpolation inside double quotes
echo "Product: $product, Price: Rp$price";
echo "<br>";

// Method 3: Interpolation with curly braces (clearer and safer)
echo "Product: {$product}, Price: Rp{$price}";
echo "<br>";

// Double quotes: variable is replaced with its value
echo "Value: $product";
echo "<br>";

// Single quotes: variable is displayed as literal text, not replaced
echo 'Value: $product';
echo "<br>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-03/double-vs-single-quotes.php
```

The last line on the page will display `Value: $product` literally, not the word "Laptop". This is the key difference: inside double quotes, PHP scans the string for `$` signs and replaces any variable it finds with its value. Inside single quotes, PHP treats every character as-is and never checks for variables. The curly brace syntax `{$product}` is preferred when a variable sits directly next to other text without a space, because it removes any ambiguity about where the variable name ends.

---

## 5. The Four Basic PHP Data Types

PHP automatically decides what kind of value a variable holds based on how you write it. You do not declare the type explicitly - you just assign the value and PHP figures it out. Understanding the four basic types helps you predict how PHP will behave when you perform operations or comparisons later.

### Step 1: Create a New File

Navigate to the `lesson-03` folder and create the file:

```bash
micro data-types.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
// DATA TYPE 1: INTEGER (whole numbers, positive, negative, or zero)
$student_count = 30;
$temperature   = -5;
$zero_value    = 0;

echo "<h2>Integer</h2>";
echo "Student count: $student_count <br>";
echo "Temperature: $temperature degrees <br>";

// DATA TYPE 2: FLOAT (decimal numbers, use a dot as the separator)
$price  = 15500.50;
$height = 1.75;
$pi     = 3.14159;

echo "<h2>Float</h2>";
echo "Price: Rp$price <br>";
echo "Height: $height meters <br>";
echo "PI value: $pi <br>";

// DATA TYPE 3: STRING (any text, wrapped in double or single quotes)
$name       = "Citra Dewi";
$city       = 'Surabaya';
$message    = "Happy learning PHP!";
$number_str = "123"; // This is a STRING even though it looks like a number

echo "<h2>String</h2>";
echo "Name: $name <br>";
echo "City: $city <br>";
echo "Message: $message <br>";
echo "Number as string: $number_str <br>";

// DATA TYPE 4: BOOLEAN (only two possible values: true or false)
$is_logged_in  = true;
$has_error     = false;
$passing_grade = true;

echo "<h2>Boolean</h2>";
echo "Logged in: ";
echo $is_logged_in;  // Displays: 1
echo "<br>";
echo "Has error: ";
echo $has_error;     // Displays nothing (empty string)
echo "<br>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-03/data-types.php
```

Pay attention to the Boolean section. When you `echo` a boolean, PHP converts `true` to `"1"` and `false` to an empty string. This is why `$has_error` produces no visible output. This automatic conversion between types is called type juggling and it is something you will encounter often, especially in Lesson 4 when you start writing conditions. Also note that PHP uses a dot (`.`) as the decimal separator for floats, never a comma.

---

## 6. Inspecting Variables with var_dump() and gettype()

As programs grow more complex, you need a reliable way to look inside a variable and know exactly what type it holds and what value it contains. PHP provides two built-in functions for this: `gettype()` returns the type name as a string, while `var_dump()` shows the type and value together in a format designed for debugging.

### Step 1: Create a New File

Navigate to the `lesson-03` folder and create the file:

```bash
micro inspect-variables.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
$name   = "Ahmad";
$age    = 22;
$height = 1.68;
$active = true;

echo "<h2>Using gettype()</h2>";
echo "Type of \$name: "   . gettype($name)   . "<br>";  // string
echo "Type of \$age: "    . gettype($age)    . "<br>";  // integer
echo "Type of \$height: " . gettype($height) . "<br>";  // double
echo "Type of \$active: " . gettype($active) . "<br>";  // boolean

echo "<h2>Using var_dump()</h2>";
echo "<pre>";
var_dump($name);    // string(5) "Ahmad"
var_dump($age);     // int(22)
var_dump($height);  // float(1.68)
var_dump($active);  // bool(true)
echo "</pre>";

echo "<h2>Changing Variable Values</h2>";
$score = 75;
echo "Initial score: $score <br>";

$score = 90;
echo "Score after change: $score <br>";

$data = 100;
echo "Before: ";
var_dump($data);
echo "<br>";

$data = "hundred";
echo "After: ";
var_dump($data);
echo "<br>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-03/inspect-variables.php
```

`gettype($height)` returns `"double"` rather than `"float"`. Both words describe the same thing - a number with a decimal point. PHP inherited the term "double" from the C programming language, but you can think of it as a float. `var_dump()` is more informative than `gettype()` because it also shows the value and, for strings, the character length. The `<pre>` tag makes `var_dump()` output line up neatly in the browser. Notice that reassigning `$score = 90` completely replaces the old value, and reassigning `$data` from an integer to a string changes its type too. PHP allows this because it uses dynamic typing - the type of a variable is determined by whatever value it currently holds.

---

## 7. Small Project: Profile Card

Now let's combine variables, data types, and PHP-inside-HTML to build something more complete. This exercise mirrors how real PHP pages work: data is stored in variables at the top, and the HTML below simply reads from those variables to build the page.

### Step 1: Create a New File

Navigate to the `lesson-03` folder and create the file:

```bash
micro profile-card.php
```

### Step 2: Write the Code

Type the following code into the editor:

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
        p { color: #666; margin: 5px 0; }
    </style>
</head>
<body>
<?php
    $name       = "Rina Kusuma";
    $occupation = "Web Developer";
    $city       = "Jakarta";
    $age        = 28;
    $email      = "rina@example.com";
    $active     = true;

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

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-03/profile-card.php
```

You will see a styled profile card rendered in the browser. The PHP block at the top of the file defines all the data, and the HTML below reads from those variables using `<?php echo $name; ?>`. The line `$status = $active ? "Active" : "Inactive"` is called the ternary operator - a shorthand for "if `$active` is true, assign `"Active"`, otherwise assign `"Inactive"`". You will learn conditionals in depth in Lesson 4. Try changing the variable values and refreshing the page - only the data at the top needs to change, and the entire card updates automatically.

---

## 8. Fix the Errors in Your Code

This section presents three errors that beginners commonly make when first working with variables. Each one is a real mistake that either causes PHP to crash or produces unexpected output.

**Error 1: Space inside a variable name.**

PHP variable names follow strict rules: they must start with a letter or underscore and cannot contain spaces. A space inside a variable name causes an immediate parse error, and PHP will refuse to run the file at all.

```php
// Wrong
$user Name = "Siti";

// Correct
$userName = "Siti";
```

`$user Name` is not a valid identifier in PHP. Use camelCase (`$userName`) or snake_case (`$user_name`) to write multi-word variable names. Either convention works, but pick one and use it consistently throughout a project.

---

**Error 2: Case mismatch when using a variable.**

PHP is case-sensitive. A variable assigned as `$userName` is a completely different variable from `$username`. If you assign a value to one and then try to read the other, PHP will treat the second as undefined and produce a warning, typically outputting an empty value.

```php
// Wrong
$userName = "Siti";
echo "Hello $username"; // $username was never assigned

// Correct
$userName = "Siti";
echo "Hello $userName"; // matches the assigned variable exactly
```

When an `echo` statement outputs nothing where you expected a name, case mismatch on a variable is one of the first things to check. The fix is to make sure you spell the variable name exactly the same way every time you use it.

---

**Error 3: Using `+` instead of `.` for string concatenation.**

In PHP, the `+` operator is reserved for arithmetic. Using it to join strings does not concatenate them - PHP will try to treat both sides as numbers. The result is often `0` or an unexpected numeric value instead of the text you intended.

```php
// Wrong
echo "City: " + $city;

// Correct
echo "City: " . $city;
```

Always use the dot (`.`) to join strings in PHP. If you accidentally use `+`, PHP will silently convert the string to a number (usually `0`) and add them, producing an incorrect result without a visible error message.

---

## 9. Exercises

Complete the following exercises in the `lesson-03` folder. Use `micro` to create each file and view the results in your browser through `http://localhost:8080/learn-php/lesson-03/`.

**Exercise 1:** Create `exercise-1.php` that stores your personal data (name, age, height, city, and student status as a boolean) in variables, then displays everything in a clean HTML format using paragraph tags.

**Exercise 2:** Create `exercise-2.php` that calculates the area and perimeter of a rectangle. Store the length (`15`) and width (`8`) in variables, calculate the area (`length * width`) and perimeter (`2 * (length + width)`), and display all four values with labels.

**Exercise 3:** Create `exercise-3.php` with four variables of different types (one integer, one float, one string, one boolean), then use `var_dump()` to display the complete type and value information for each one.

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
$status    = $isStudent ? "Still a student" : "Not a student";

echo "<h2>Personal Data</h2>";
echo "<p>Name: $name</p>";
echo "<p>Age: $age years</p>";
echo "<p>Height: $height meters</p>";
echo "<p>City: $city</p>";
echo "<p>Status: $status</p>";
?>
```

Each variable stores one piece of information: strings for text, an integer for age, a float for height, and a boolean for the student flag. The ternary operator on `$status` converts the boolean into a human-readable label before it is displayed. Using `<p>` tags instead of `<br>` gives each piece of information its own block on the page, which is cleaner and easier to read.

---

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

`$area = $length * $width` stores the result of the multiplication directly into a new variable rather than calculating it inside `echo`. This is good practice because the calculated value can be reused or modified later without touching the display code. `$perimeter = 2 * ($length + $width)` uses parentheses to ensure addition is computed before multiplication, following standard arithmetic order of operations.

---

**Solution for Exercise 3:**

```php
<?php
$wholeNumber   = 42;
$decimalNumber = 3.14;
$text          = "Learning PHP";
$isTrue        = true;

echo "<pre>";
var_dump($wholeNumber);
var_dump($decimalNumber);
var_dump($text);
var_dump($isTrue);
echo "</pre>";
?>
```

`var_dump()` prints the type and value of each variable on its own line. Wrapping the output in `<pre>` tags tells the browser to preserve whitespace and line breaks, so each `var_dump()` result appears on a separate line rather than running together in one block. The output confirms the exact type PHP assigned: `int` for `$wholeNumber`, `float` for `$decimalNumber`, `string(12)` for `$text` (where 12 is the character count), and `bool` for `$isTrue`.

---

## Next Up - Lesson 4

Variables are containers that hold values, and PHP automatically tracks what type of value each one holds: integer, float, string, or boolean. Double-quoted strings allow variable interpolation, while single-quoted strings treat everything literally. `var_dump()` is your best tool for inspecting variables when a program behaves unexpectedly, and `gettype()` is useful when you only need the type name.

In Lesson 4, you will learn about operators and control structures - how to perform calculations with arithmetic operators, compare values with comparison operators, and make decisions with `if`, `else`, `elseif`, and `switch`.