## 1. Before You Begin

Variables let you store data, but a program that only stores data without doing anything with it is not very useful. To build programs that calculate totals, check whether a user is allowed to enter a page, or assign letter grades from scores, you need two more tools: operators to perform and compare calculations, and control structures to make your program take different paths based on those comparisons.

### Introduction

This lesson introduces the mathematical and logical machinery of PHP. Operators are the symbols that tell PHP what to do with your data. Control structures are the branching pathways your program follows depending on what the data contains. Together they transform a script from a simple list of instructions into code that can reason and respond.

### What You'll Build

You will build a discount calculator that applies different rates based on conditions, a grade classifier that converts numeric scores to letter grades using an if-elseif chain, and a time-based greeting page.

### What You'll Learn

- ✅ Arithmetic operators: addition, subtraction, multiplication, division, modulus
- ✅ Comparison operators: `==`, `===`, `!=`, `>`, `<`, `>=`, `<=`
- ✅ The critical difference between `==` and `===`
- ✅ Logical operators: `&&` (AND), `||` (OR), `!` (NOT)
- ✅ `if`, `elseif`, and `else` for branching logic
- ✅ The ternary operator for one-line conditions
- ✅ `switch` for matching one value against many exact options

### What You'll Need

- Laragon running
- VS Code open in the `learn-php` folder
- Lessons 1 through 3 completed

---

## 2. Setup

Create a new subfolder called `lesson-04` inside the `learn-php` folder.

---

## 3. Arithmetic Operators

Arithmetic operators perform mathematical calculations. They work the way you expect from mathematics, with one addition: the modulus operator `%`, which gives the remainder after division.

### Step 1: Create a New File

Create a file called `arithmetic.php` in the `lesson-04` folder.

### Step 2: Write the Code

Open `arithmetic.php` and type the following code:

```php
<?php
$a = 20;
$b = 6;

echo "<h2>Arithmetic Operators</h2>";

// Addition
$result = $a + $b;
echo "$a + $b = $result <br>";       // 26

// Subtraction
$result = $a - $b;
echo "$a - $b = $result <br>";       // 14

// Multiplication
$result = $a * $b;
echo "$a * $b = $result <br>";       // 120

// Division — note this produces a decimal if needed
$result = $a / $b;
echo "$a / $b = $result <br>";       // 3.3333...

// Modulus — the REMAINDER after integer division
// 20 divided by 6 equals 3 with a remainder of 2
$result = $a % $b;
echo "$a % $b = $result <br>";       // 2

echo "<h2>Order of Operations</h2>";
// PHP follows standard math precedence — multiplication happens before addition
$result1 = 2 + 3 * 4;     // = 2 + 12 = 14  (NOT 20!)
$result2 = (2 + 3) * 4;   // = 5 * 4 = 20   (parentheses override order)
echo "2 + 3 * 4 = $result1 <br>";
echo "(2 + 3) * 4 = $result2 <br>";

echo "<h2>Shorthand Assignment Operators</h2>";
$score = 70;
echo "Initial: $score <br>";

$score += 15;   // same as: $score = $score + 15
echo "After += 15: $score <br>";

$score -= 5;    // same as: $score = $score - 5
echo "After -= 5: $score <br>";

// ++ and -- are increment/decrement shortcuts used very often in loops
$counter = 0;
$counter++;   // adds 1 — same as $counter = $counter + 1
$counter++;
echo "Counter after ++ twice: $counter <br>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-04/arithmetic.php
```

Pay particular attention to the modulus result. `20 % 6` equals `2` because 20 divided by 6 gives 3 with 2 left over. Modulus is frequently used to determine whether a number is odd or even (any number `% 2` equals either 0 for even or 1 for odd), or to check whether a loop iteration is a multiple of a specific number.

---

## 4. Comparison Operators and == vs ===

Comparison operators produce a boolean result — either `true` or `false`. The result drives decision-making in control structures, which is why understanding them precisely matters.

### Step 1: Create a New File

Create a file called `comparison.php` in the `lesson-04` folder.

### Step 2: Write the Code

Open `comparison.php` and type the following code:

```php
<?php
echo "<h2>Standard Comparison Operators</h2>";
echo "<pre>";

$a = 10;
$b = 20;

var_dump($a == $b);    // false   — is 10 equal to 20?
var_dump($a == 10);    // true    — is 10 equal to 10?
var_dump($a > $b);     // false   — is 10 greater than 20?
var_dump($a < $b);     // true    — is 10 less than 20?
var_dump($a >= 10);    // true    — is 10 greater than or equal to 10?
var_dump($a != $b);    // true    — is 10 NOT equal to 20?

echo "</pre>";

echo "<h2>== vs === (VERY Important!)</h2>";
echo "<pre>";

$number = 100;       // integer
$string = "100";     // string — same digits but different type

// == (loose comparison): PHP converts both to the same type before comparing
// It finds 100 and "100" have the same numeric value, so they match
echo '100 == "100" is: ';  var_dump($number == $string);   // true

// === (strict comparison): checks BOTH value AND type
// 100 is an integer, "100" is a string — different types, so they DO NOT match
echo '100 === "100" is: '; var_dump($number === $string);  // false

// Two values of the same type and value
echo "100 === 100 is: ";   var_dump($number === 100);      // true

echo "</pre>";

echo "<p><strong>The rule:</strong> always use <code>===</code> as your default. ";
echo "Switch to <code>==</code> only when you explicitly want type coercion.</p>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-04/comparison.php
```

The `==` versus `===` distinction is one of the most common sources of bugs in PHP code and deserves careful attention. The double equals `==` performs what PHP calls "loose" comparison: before comparing, it converts both values to the same type. This means `0 == "cat"` is `true` in older PHP versions, because PHP converts `"cat"` to the integer 0. The triple equals `===` is "strict" and never performs type conversion, so both the value and the type must match. As a practical rule, always default to `===` in your condition checks unless you have a specific reason to want PHP's automatic type conversion.

---

## 5. If, Elseif, and Else

Now that you can produce true/false comparisons, you can use those results to make your program take different actions depending on the situation.

### Step 1: Create a New File

Create a file called `conditionals.php` in the `lesson-04` folder.

### Step 2: Write the Code

Open `conditionals.php` and type the following code:

```php
<?php
// ===== SIMPLE IF =====
// Code inside the {} only runs when the condition is true
$score = 75;
if ($score >= 60) {
    echo "Congratulations, you passed! <br>";
}

// ===== IF - ELSE =====
// Provides a fallback that runs when the condition is false
$test_score = 45;
if ($test_score >= 60) {
    echo "Score $test_score: PASS <br>";
} else {
    echo "Score $test_score: FAIL <br>";
}

// ===== IF - ELSEIF - ELSE =====
// PHP checks from top to bottom and STOPS at the first true condition
// Order matters: always write the strictest condition first
$grade_score = 82;

if ($grade_score >= 90) {
    $letter = "A";
} elseif ($grade_score >= 80) {
    $letter = "B";   // 82 meets this condition, so PHP stops here
} elseif ($grade_score >= 70) {
    $letter = "C";   // Never checked for score 82
} elseif ($grade_score >= 60) {
    $letter = "D";
} else {
    $letter = "E";
}

echo "Score $grade_score gets letter grade: <strong>$letter</strong> <br>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-04/conditionals.php
```

Notice the comment about order. If you reversed the elseif chain and wrote `$grade_score >= 60` first, a score of 82 would match that first condition (because 82 is indeed greater than or equal to 60) and PHP would stop there, assigning the wrong letter grade "D". The chain must always go from the most restrictive condition to the least restrictive. Think of it as PHP reading a checklist and ticking the first item it finds — you must put the most specific items at the top.

---

## 6. Logical Operators

Logical operators combine multiple conditions so you can check for more complex situations with a single `if` statement.

### Step 1: Create a New File

Create a file called `logical.php` in the `lesson-04` folder.

### Step 2: Write the Code

Open `logical.php` and type the following code:

```php
<?php
echo "<h2>Logical Operators</h2>";

$age    = 22;
$has_id = true;

// && (AND): BOTH conditions must be true for the whole expression to be true
if ($age >= 17 && $has_id) {
    echo "Allowed to purchase an adult ticket. <br>";
} else {
    echo "Does not meet ticket requirements. <br>";
}

// || (OR): at least ONE condition being true is enough
$is_student = true;
$is_veteran = false;
if ($is_student || $is_veteran) {
    echo "Eligible for a 50% discount. <br>";
}

// ! (NOT): flips true to false and false to true
$is_banned = false;
if (!$is_banned) {
    echo "User is not banned — access granted. <br>";
}

echo "<h2>Age Category System</h2>";
$user_age = 15;

// A complete classification with all ranges covered
if ($user_age < 0) {
    echo "Invalid age.";
} elseif ($user_age <= 12) {
    echo "Category: Child (age $user_age) — Ticket: Rp25,000";
} elseif ($user_age <= 17) {
    echo "Category: Teenager (age $user_age) — Ticket: Rp50,000";
} elseif ($user_age <= 59) {
    echo "Category: Adult (age $user_age) — Ticket: Rp100,000";
} else {
    echo "Category: Senior (age $user_age) — Ticket: Rp25,000";
}
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-04/logical.php
```

Try changing `$user_age` to different values (5, 15, 35, 65) and refreshing. The classification system updates correctly each time, demonstrating how a single if-elseif chain handles the full range of possible inputs.

---

## 7. Ternary Operator and Switch

Two more tools round out your control structure toolkit: the ternary operator for concise one-line conditions and the switch statement for matching one variable against many fixed values.

### Step 1: Create a New File

Create a file called `ternary-switch.php` in the `lesson-04` folder.

### Step 2: Write the Code

Open `ternary-switch.php` and type the following code:

```php
<?php
echo "<h2>Ternary Operator</h2>";
// Format: condition ? value_if_true : value_if_false
// Think of it as a compressed if/else that produces a value

$score  = 75;
$status = ($score >= 60) ? "Pass" : "Fail";
echo "Score $score: $status <br>";

$stock = 0;
echo "Stock: " . ($stock > 0 ? "Available ($stock units)" : "Sold out") . "<br>";

// A common use: convert a number to even/odd label
$number = 15;
echo "$number is " . ($number % 2 === 0 ? "even" : "odd") . "<br>";

// Null coalescing: returns the left side if it is set and not null,
// otherwise returns the right side — very useful for default values
$username = null;
$display  = $username ?? "Guest";
echo "Welcome, $display! <br>";

echo "<h2>Switch Statement</h2>";
// Switch excels when checking ONE variable against MULTIPLE exact values
// It is often cleaner than a long if-elseif chain for this pattern

$day = "Wednesday";

switch ($day) {
    case "Monday":
        echo "Start of the work week! <br>";
        break;   // break exits the switch; without it, PHP falls through to the next case
    case "Tuesday":
        echo "Day two, keep going. <br>";
        break;
    case "Wednesday":
        echo "Midweek, halfway there! <br>";
        break;
    case "Thursday":
        echo "Almost the weekend. <br>";
        break;
    case "Friday":
        echo "Last day, you made it! <br>";
        break;
    case "Saturday":
    case "Sunday":
        // Two cases with no break between them share the same output
        echo "Enjoy the weekend! <br>";
        break;
    default:
        // Runs if no case matched
        echo "Unknown day. <br>";
}
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-04/ternary-switch.php
```

Notice the `break` statement in every switch case. Without `break`, PHP "falls through" and continues executing the next case even if it does not match. This is a deliberate feature — the Saturday/Sunday example uses it intentionally so both days share the same message — but accidental fall-through is one of the most common switch bugs. Always add `break` unless you specifically want fall-through behavior.

---

## 8. Run and Test

At this point you have four working files in `lesson-04`. Take a few minutes to experiment with each one in the browser. Change `$grade_score` in `conditionals.php` to values like 55, 70, 88, and 95 and confirm the letter grades are correct. Change `$day` in `ternary-switch.php` to "Saturday" and verify both weekend days produce the same output. Try setting `$user_age` to negative numbers and confirm the validation catches them. This active experimentation builds intuition much faster than reading alone.

---

## 9. Fix the Errors in Your Code

```php
<?php
$price    = 100000;
$discount = 20;

// Mistake 1: Wrong calculation for a percentage
$deduction   = $price / $discount;
$final_price = $price - $deduction;

// Mistake 2: Assignment instead of comparison
if ($final_price = 50000) {
    echo "Affordable!";
}

// Mistake 3: Missing break in switch
$day = "Monday";
switch ($day) {
    case "Monday":
        echo "Start of the week";
    case "Tuesday":
        echo "Day two";
        break;
}

// Mistake 4: Incomplete ternary — missing the false branch
$stock   = 5;
$message = $stock > 0 ? "In stock";
?>
```

The first mistake uses division to calculate a discount, but a 20% discount means multiplying by a fraction: `$deduction = $price * ($discount / 100)`. The second mistake uses a single `=` inside the `if` condition, which performs assignment (setting `$final_price` to 50000) rather than comparison. Because assignment returns the assigned value and 50000 is truthy, the `if` always evaluates as true. Use `===` for comparison. The third mistake is missing a `break` after the Monday case, so when `$day` is "Monday", PHP prints "Start of the week" and then falls through to also print "Day two". Add `break;` after the Monday echo. The fourth mistake is an incomplete ternary — the syntax requires three parts: condition, value-if-true, and value-if-false. Write: `$message = $stock > 0 ? "In stock" : "Out of stock";`.

---

## 10. Exercises

**Exercise 1:** In the `lesson-04` folder, create `exercise-1.php`. Store a price (75000) and quantity (4) in variables. Calculate the subtotal, apply a 10% discount, and display all figures including the final total.

**Exercise 2:** Create `exercise-2.php`. Store a numeric grade between 0 and 100. Use `if-elseif-else` to assign a letter grade (A for 90-100, B for 80-89, C for 70-79, D for 60-69, E for below 60) and display both values.

**Exercise 3:** Create `exercise-3.php`. Store a month number 1-12 in a variable. Use `switch` to display the month name and its number of days. Use "28 or 29 days" for February. Add a `default` for values outside 1-12.

---

## 11. Solutions

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

**Solution for Exercise 2:**

```php
<?php
$numeric_grade = 82;

if ($numeric_grade >= 90)      { $letter = "A"; }
elseif ($numeric_grade >= 80)  { $letter = "B"; }
elseif ($numeric_grade >= 70)  { $letter = "C"; }
elseif ($numeric_grade >= 60)  { $letter = "D"; }
else                           { $letter = "E"; }

echo "Numeric grade: $numeric_grade <br>";
echo "Letter grade: <strong>$letter</strong> <br>";
?>
```

**Solution for Exercise 3:**

```php
<?php
$month = 8;

switch ($month) {
    case 1:  echo "January — 31 days";        break;
    case 2:  echo "February — 28 or 29 days"; break;
    case 3:  echo "March — 31 days";          break;
    case 4:  echo "April — 30 days";          break;
    case 5:  echo "May — 31 days";            break;
    case 6:  echo "June — 30 days";           break;
    case 7:  echo "July — 31 days";           break;
    case 8:  echo "August — 31 days";         break;
    case 9:  echo "September — 30 days";      break;
    case 10: echo "October — 31 days";        break;
    case 11: echo "November — 30 days";       break;
    case 12: echo "December — 31 days";       break;
    default: echo "Invalid month number (must be 1-12)";
}
?>
```

---

## 12. Understanding Operators and Control Structures

Operators and control structures are how a program thinks. Every web application makes decisions constantly: is this user logged in? Does this password meet the minimum length? Is this price below the budget? Each of those questions is a comparison operator returning true or false, and each resulting action is an if-else branch selecting the appropriate code path.

The `==` versus `===` distinction is worth revisiting because it causes more subtle bugs than almost anything else in PHP. When PHP uses `==` and finds two values of different types, it converts them to a common type before comparing. This type coercion is sometimes convenient but often surprising. `0 == false` is `true`, `"" == false` is `true`, and `"0" == false` is `true`. Strict comparison with `===` never surprises you: both the value and the type must be identical.

The ternary operator `? :` is not just a typing shortcut — it also communicates intent. When you see a ternary, the reader immediately knows you are producing one of exactly two values. When you see an `if-else`, the reader knows there might be more complex logic inside. Using each construct in its appropriate context makes code more readable.

---

## 13. Conclusion

Operators give PHP the ability to calculate and compare. Control structures give PHP the ability to choose. The combination lets your programs adapt to different data rather than always producing the same output. Always use `===` for comparisons unless you have a deliberate reason to want type coercion. Order `elseif` conditions from most specific to least specific. Always include `break` in switch cases unless you intentionally want fall-through.

**In Lesson 5**, you will learn about loops — how to make PHP repeat a block of code automatically, whether for counting, processing lists, or displaying database rows.