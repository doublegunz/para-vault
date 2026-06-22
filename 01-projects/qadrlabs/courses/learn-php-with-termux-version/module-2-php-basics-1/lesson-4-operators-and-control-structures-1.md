## 1. Before You Begin

Variables store data. But data that is only stored without being processed is not very useful. You need to calculate, compare, and make decisions based on that data. This is where **operators** and **control structures** come in.

Operators let you perform calculations and comparisons. Control structures let your program choose different paths based on conditions. Together, they transform a program from a simple list of instructions into something that can adapt and respond to different situations.

### What You'll Build

You will build a discount calculator that applies different rates based on conditions, a grade classifier that assigns letter grades from numeric scores, and a time-based greeting page.

### What You'll Learn

- ✅ Arithmetic operators: addition, subtraction, multiplication, division, modulus
- ✅ Comparison operators: `==`, `===`, `!=`, `>`, `<`, `>=`, `<=`
- ✅ The critical difference between `==` and `===`
- ✅ Logical operators: `&&` (AND), `||` (OR), `!` (NOT)
- ✅ How to use `if`, `elseif`, and `else` for branching logic
- ✅ How to use the ternary operator for simple one-line conditions
- ✅ How to use `switch` for matching exact values

### What You'll Need

- Termux open with Apache running (`apachectl`)
- Lessons 1 through 3 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson inside your project directory. Every file you create in Lesson 4 should live here so the web server can serve them at the correct URL.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-04
cd lesson-04
```

`mkdir lesson-04` creates the subfolder, and `cd lesson-04` moves you into it. Any file you create after this command will automatically land in the right place.

---

## 3. Arithmetic Operators

Arithmetic operators are the starting point for working with numeric data. PHP supports all the standard mathematical operations, plus the modulus operator which calculates the remainder after division. Understanding them also sets the foundation for the comparison operators in the next section.

### Step 1: Create a New File

Make sure you are in the `lesson-04` folder, then open a new file:

```bash
micro arithmetic.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
$a = 20;
$b = 6;

echo "<h2>Arithmetic Operators</h2>";

$result = $a + $b;
echo "$a + $b = $result <br>";

$result = $a - $b;
echo "$a - $b = $result <br>";

$result = $a * $b;
echo "$a * $b = $result <br>";

$result = $a / $b;
echo "$a / $b = $result <br>";

$result = $a % $b;
echo "$a % $b = $result <br>";

echo "<h2>Order of Operations</h2>";
$result1 = 2 + 3 * 4;
$result2 = (2 + 3) * 4;
echo "2 + 3 * 4 = $result1 <br>";
echo "(2 + 3) * 4 = $result2 <br>";

echo "<h2>Assignment Shortcuts</h2>";
$score = 70;
echo "Initial: $score <br>";
$score += 15;
echo "After += 15: $score <br>";
$score -= 5;
echo "After -= 5: $score <br>";

$counter = 0;
$counter++;
$counter++;
echo "Counter after ++ twice: $counter <br>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

The `%` (modulus) operator returns the remainder after division. `20 % 6` gives `2` because 6 goes into 20 three times (18), leaving a remainder of 2. Modulus is commonly used to check whether a number is even or odd: any number where `$n % 2 === 0` is even. The order of operations section demonstrates that PHP follows standard mathematical precedence: multiplication happens before addition, so `2 + 3 * 4` evaluates to `14`, not `20`. Parentheses override precedence and force `(2 + 3)` to be calculated first. The `+=` and `-=` shorthand operators combine assignment with arithmetic: `$score += 15` means "add 15 to whatever `$score` currently holds." The `++` operator increments a variable by exactly 1 each time it is used.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-04/arithmetic.php
```

---

## 4. Comparison Operators and == vs ===

Comparison operators are what you use inside `if` statements to test conditions. Each one returns a boolean: either `true` or `false`. The most important distinction in this section is between `==` and `===`, because confusing the two is one of the most common sources of hard-to-catch bugs in PHP.

### Step 1: Create a New File

Make sure you are in the `lesson-04` folder, then open a new file:

```bash
micro comparison.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "<h2>Comparison Operators</h2>";
echo "<pre>";

$a = 10;
$b = 20;

echo "10 == 20 ? "; var_dump($a == $b);
echo "10 == 10 ? "; var_dump($a == 10);
echo "10 > 20 ? ";  var_dump($a > $b);
echo "10 < 20 ? ";  var_dump($a < $b);
echo "10 >= 10 ? "; var_dump($a >= 10);
echo "10 != 20 ? "; var_dump($a != $b);

echo "</pre>";

echo "<h2>== vs === (Very Important)</h2>";
echo "<pre>";

$number = 100;
$string = "100";

echo '100 == "100" ? ';  var_dump($number == $string);
echo '100 === "100" ? '; var_dump($number === $string);
echo "100 === 100 ? ";   var_dump($number === 100);

echo "</pre>";

echo "<p><strong>Rule of thumb:</strong> use <code>===</code> as your default to avoid hard-to-find bugs.</p>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-04/comparison.php
```

`==` compares only the value and performs automatic type conversion before comparing. That is why `100 == "100"` returns `true`: PHP converts the string `"100"` to the integer `100` before checking equality. `===` also compares the type, so `100 === "100"` returns `false` because one is an integer and the other is a string. Always prefer `===` in your code. With `==`, PHP silently converts types in the background, which can produce true comparisons between values that feel like they should be different. Using `===` keeps your comparisons predictable.

---

## 5. If, Elseif, and Else

Comparison operators produce true/false results, but those results are only useful when something happens based on them. The `if` statement is how you tell PHP what to do when a condition is true. Combined with `elseif` and `else`, you can build chains of decisions that cover every possible case.

### Step 1: Create a New File

Make sure you are in the `lesson-04` folder, then open a new file:

```bash
micro conditionals.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
// Simple if
$score = 75;

if ($score >= 60) {
    echo "Congratulations, you passed! <br>";
}

// If - else
$test_score = 45;

if ($test_score >= 60) {
    echo "Score $test_score: PASS <br>";
} else {
    echo "Score $test_score: FAIL <br>";
}

// If - elseif - else
$grade_score = 82;

if ($grade_score >= 90) {
    $letter = "A";
} elseif ($grade_score >= 80) {
    $letter = "B";
} elseif ($grade_score >= 70) {
    $letter = "C";
} elseif ($grade_score >= 60) {
    $letter = "D";
} else {
    $letter = "E";
}

echo "Score $grade_score gets letter grade: <strong>$letter</strong> <br>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-04/conditionals.php
```

PHP evaluates an `if-elseif-else` chain from top to bottom and stops at the first condition that is true. For `$grade_score = 82`, the first condition (`>= 90`) is false, the second (`>= 80`) is true, so PHP assigns `"B"` and skips all remaining branches. The order of `elseif` conditions is critical: they must go from the strictest (highest threshold) down to the most lenient. If you reversed the order and started with `>= 60`, a score of 82 would match that condition first and receive a `"D"` incorrectly, because 82 is indeed greater than or equal to 60.

---

## 6. Logical Operators and Nested Conditions

Single conditions are not always enough. Real programs often need to check multiple things at once: a user must be old enough AND have a valid ID, or a discount applies if someone is a student OR a veteran. Logical operators let you combine multiple conditions into one expression.

### Step 1: Create a New File

Make sure you are in the `lesson-04` folder, then open a new file:

```bash
micro logical.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "<h2>Logical Operators</h2>";

$age    = 22;
$has_id = true;

// && (AND): both conditions must be true
if ($age >= 17 && $has_id) {
    echo "Allowed to purchase an adult ticket. <br>";
} else {
    echo "Does not meet ticket requirements. <br>";
}

// || (OR): at least one condition must be true
$is_student = true;
$is_veteran = false;

if ($is_student || $is_veteran) {
    echo "Eligible for a 50% discount. <br>";
}

// ! (NOT): reverses the boolean value
$is_banned = false;
if (!$is_banned) {
    echo "User is not banned, access granted. <br>";
}

echo "<h2>Age Category System</h2>";
$user_age = 15;

if ($user_age < 0) {
    echo "Invalid age.";
} elseif ($user_age <= 12) {
    echo "Category: Child (age $user_age). Ticket: Rp25,000";
} elseif ($user_age <= 17) {
    echo "Category: Teenager (age $user_age). Ticket: Rp50,000";
} elseif ($user_age <= 59) {
    echo "Category: Adult (age $user_age). Ticket: Rp100,000";
} else {
    echo "Category: Senior (age $user_age). Ticket: Rp25,000";
}
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-04/logical.php
```

Try changing `$user_age` to different values (5, 15, 35, 65) and refresh the browser each time to see the category system respond.

`&&` requires both sides to be true. If `$age >= 17` is true but `$has_id` is false, the entire condition is false. `||` requires only one side to be true. If `$is_student` is true, the result is true regardless of what `$is_veteran` holds. `!` inverts a boolean, so `!$is_banned` reads as "if the user is not banned." This is a common and readable pattern for guarding against negative states without nesting an extra `else` block.

---

## 7. Ternary Operator and Switch

The `if-elseif-else` structure is powerful but verbose. PHP provides two shorter alternatives for specific situations: the ternary operator for simple two-outcome decisions, and `switch` for matching one variable against a list of exact values.

### Step 1: Create a New File

Make sure you are in the `lesson-04` folder, then open a new file:

```bash
micro ternary-switch.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "<h2>Ternary Operator</h2>";

$score = 75;
$status = ($score >= 60) ? "Pass" : "Fail";
echo "Score $score: $status <br>";

$stock = 0;
echo "Stock: " . ($stock > 0 ? "Available ($stock units)" : "Sold out") . "<br>";

$number = 15;
echo "$number is " . ($number % 2 === 0 ? "even" : "odd") . "<br>";

$username = null;
$display  = $username ?? "Guest";
echo "Welcome, $display! <br>";

echo "<h2>Switch</h2>";

$day = "Wednesday";

switch ($day) {
    case "Monday":
        echo "Start of the week! <br>";
        break;
    case "Tuesday":
        echo "Day two, stay productive. <br>";
        break;
    case "Wednesday":
        echo "Midweek, halfway there! <br>";
        break;
    case "Thursday":
        echo "Almost the weekend. <br>";
        break;
    case "Friday":
        echo "Tomorrow is a day off! <br>";
        break;
    case "Saturday":
    case "Sunday":
        echo "Enjoy the weekend! <br>";
        break;
    default:
        echo "Unknown day. <br>";
}
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-04/ternary-switch.php
```

The ternary operator follows the format `condition ? value_if_true : value_if_false`. It must always have all three parts. The `??` operator (null coalescing) is a related shorthand: `$username ?? "Guest"` returns `$username` if it is not null, otherwise it returns `"Guest"`. This is useful when a variable might not be set.

`switch` compares one variable (`$day`) against a list of `case` values using loose equality (`==`). PHP starts at the matching case and executes everything that follows until it hits a `break`. This means that if you forget `break`, execution "falls through" to the next case and runs that code too. The two stacked cases for `"Saturday"` and `"Sunday"` with a single output demonstrate an intentional use of fall-through: both days share the same message. Use `switch` when you are comparing one variable against many exact values. Use `if-elseif-else` when your conditions involve ranges or multiple variables.

---

## 8. Fix the Errors in Your Code

This section presents four mistakes that are all common in code that uses operators and conditionals. Each one either causes PHP to crash or silently produces a wrong result.

**Error 1: Using division instead of multiplication for a percentage discount.**

A 20% discount means the deduction is 20 percent of the price. Dividing the price by the discount number gives a completely different and meaningless result.

```php
// Wrong
$deduction = $price / $discount;

// Correct
$deduction = $price * ($discount / 100);
```

To calculate a percentage, you must first convert the percentage to a decimal by dividing it by 100, and then multiply by the amount. `$price * ($discount / 100)` with `$price = 100000` and `$discount = 20` gives `20000`, which is the correct 20% deduction.

---

**Error 2: Using `=` (assignment) instead of `==` or `===` (comparison) inside an `if` condition.**

Inside an `if` condition, a single `=` does not compare - it assigns. PHP assigns the value to the variable and then evaluates whether the assigned value is truthy. Most non-zero values are truthy, so the `if` block almost always runs, hiding the bug completely.

```php
// Wrong
if ($final_price = 50000) {
    echo "Affordable!";
}

// Correct
if ($final_price === 50000) {
    echo "Affordable!";
}
```

The wrong version assigns `50000` to `$final_price` and then checks if `50000` is truthy, which it is. The `if` block runs every time, regardless of what `$final_price` actually was. Using `===` compares the value without modifying it, which is the intended behavior.

---

**Error 3: Missing `break` in a `switch` case.**

Without a `break` at the end of a `case` block, PHP does not stop after executing that case. It continues executing every subsequent case until it reaches a `break` or the end of the `switch`. This is called fall-through and is almost always unintended.

```php
// Wrong
switch ($day) {
    case "Monday":
        echo "Start of the week";
    case "Tuesday":
        echo "Day two";
        break;
}

// Correct
switch ($day) {
    case "Monday":
        echo "Start of the week";
        break;
    case "Tuesday":
        echo "Day two";
        break;
}
```

In the wrong version, if `$day` is `"Monday"`, PHP prints "Start of the week" and then immediately falls through to the Tuesday case and also prints "Day two". Adding `break` after each case tells PHP to exit the `switch` block after that case is handled.

---

**Error 4: Incomplete ternary operator.**

The ternary operator requires exactly three parts separated by `?` and `:`. Leaving out the false value causes a parse error.

```php
// Wrong
$message = $stock > 0 ? "In stock";

// Correct
$message = $stock > 0 ? "In stock" : "Out of stock";
```

The ternary must always specify what to return when the condition is true (after `?`) and what to return when it is false (after `:`). Without the `:` and the false value, PHP cannot parse the statement and produces a syntax error.

---

## 9. Exercises

Complete the following exercises in the `lesson-04` folder. Use `micro` to create each file and view the results through `http://localhost:8080/learn-php/lesson-04/`.

**Exercise 1:** Create `exercise-1.php`. Store a price (`75000`) and quantity (`4`) in variables. Calculate the subtotal, apply a 10% discount, and display the unit price, quantity, subtotal, discount amount, and final total.

**Exercise 2:** Create `exercise-2.php`. Store a numeric grade between 0 and 100 in a variable. Use `if-elseif-else` to convert it to a letter grade: A (90-100), B (80-89), C (70-79), D (60-69), E (below 60). Display both the numeric and letter grades.

**Exercise 3:** Create `exercise-3.php`. Store a month number (1-12) in a variable. Use `switch` to display the month name in English and the number of days. For February, display "28 or 29 days". Add a `default` case for numbers outside 1-12.

---

## 10. Solutions

**Solution for Exercise 1:**

```php
<?php
$price    = 75000;
$quantity = 4;
$subtotal = $price * $quantity;
$discount = $subtotal * 0.10;
$total    = $subtotal - $discount;

echo "<h2>Purchase Receipt</h2>";
echo "Unit price: Rp$price <br>";
echo "Quantity: $quantity <br>";
echo "Subtotal: Rp$subtotal <br>";
echo "Discount (10%): Rp$discount <br>";
echo "Total: Rp$total <br>";
?>
```

`$subtotal = $price * $quantity` multiplies the unit price by the quantity to get the total before any discount. `$discount = $subtotal * 0.10` calculates 10% by multiplying by the decimal form of the percentage. `$total = $subtotal - $discount` subtracts the discount to produce the final amount. Storing each calculated value in its own variable makes the code readable and allows each intermediate result to be displayed separately in the receipt.

---

**Solution for Exercise 2:**

```php
<?php
$numeric_grade = 82;

if ($numeric_grade >= 90) {
    $letter = "A";
} elseif ($numeric_grade >= 80) {
    $letter = "B";
} elseif ($numeric_grade >= 70) {
    $letter = "C";
} elseif ($numeric_grade >= 60) {
    $letter = "D";
} else {
    $letter = "E";
}

echo "Numeric grade: $numeric_grade <br>";
echo "Letter grade: <strong>$letter</strong> <br>";
?>
```

The `elseif` chain evaluates from the highest threshold to the lowest, so the first matching condition wins. For a score of 82, the `>= 90` check fails and the `>= 80` check succeeds, assigning `"B"`. The `else` at the end acts as a catch-all: any score that does not match any of the `elseif` conditions (that is, below 60) lands here and receives `"E"`.

---

**Solution for Exercise 3:**

```php
<?php
$month = 8;

switch ($month) {
    case 1:  echo "January - 31 days";        break;
    case 2:  echo "February - 28 or 29 days"; break;
    case 3:  echo "March - 31 days";          break;
    case 4:  echo "April - 30 days";          break;
    case 5:  echo "May - 31 days";            break;
    case 6:  echo "June - 30 days";           break;
    case 7:  echo "July - 31 days";           break;
    case 8:  echo "August - 31 days";         break;
    case 9:  echo "September - 30 days";      break;
    case 10: echo "October - 31 days";        break;
    case 11: echo "November - 30 days";       break;
    case 12: echo "December - 31 days";       break;
    default: echo "Invalid month number (must be 1-12)";
}
?>
```

`switch` compares `$month` against each `case` value using loose equality. When `$month` is `8`, PHP finds the matching `case 8` and executes that line. Each `break` exits the `switch` immediately after the matched case finishes, preventing fall-through. The `default` case at the end handles any value that does not match any of the 12 cases, which covers invalid input like `0`, `13`, or a negative number.

---

## Next Up - Lesson 5

Operators let you calculate and compare data, and control structures let your program choose different paths based on those comparisons. The most important distinction from this lesson is between `=` (assignment), `==` (loose comparison), and `===` (strict comparison): using the wrong one is one of the most common sources of bugs in PHP. Use `if-elseif-else` for ranges and comparisons, `switch` for many exact values, and the ternary operator for simple two-outcome decisions. In a `switch`, always include `break` unless fall-through is intentional.

In Lesson 5, you will learn about loops - how to make PHP repeat a block of code automatically, whether for counting, processing lists, or generating dynamic HTML tables.