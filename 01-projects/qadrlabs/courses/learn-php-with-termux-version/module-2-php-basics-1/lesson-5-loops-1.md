## 1. Before You Begin

Imagine being asked to display the numbers 1 through 100 in the browser. Without loops, you would have to write a hundred `echo` lines - work that is inefficient and error-prone. Now imagine a grade table for 30 students, or a list of 500 products in an online store. Clearly, writing one line per item is not a realistic approach.

A **loop** is an instruction to PHP to execute a set of commands multiple times automatically. You write the code once, and PHP repeats it as many times as needed. Combined with the conditionals from Lesson 4, loops are one of the most powerful tools a programmer has.

PHP has four types of loops: `for`, `while`, `do-while`, and `foreach`. Each has its own use case, and you will learn when to use which.

### What You'll Build

You will build a multiplication table using `for`, a savings simulation using `while`, and a food menu list using `foreach`. You will also learn to control loop execution with `break` and `continue`.

### What You'll Learn

- ✅ How to use `for` loops when the number of repetitions is already known
- ✅ How to use `while` loops for dynamic conditions
- ✅ How to use `do-while` loops that always run at least once
- ✅ How to use `foreach` to iterate through every item in an array
- ✅ How to stop loops early with `break` and skip iterations with `continue`

### What You'll Need

- Termux open with Apache running (`apachectl`)
- Lessons 1 through 4 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson inside your project directory. All files you create in Lesson 5 should live here.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-05
cd lesson-05
```

`mkdir lesson-05` creates the subfolder and `cd lesson-05` moves you into it. Any file you create after running these commands will be served by Apache at `http://localhost:8080/learn-php/lesson-05/`.

---

## 3. The For Loop

The `for` loop is best suited when you already know exactly how many times the loop should run. Its structure consists of three parts that you write inside parentheses and separate with semicolons. Once you understand those three parts, every `for` loop you ever encounter will be immediately readable.

### Step 1: Create a New File

Make sure you are in the `lesson-05` folder, then open a new file:

```bash
micro for-loop.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "<h2>Basic For Loop</h2>";
for ($i = 1; $i <= 5; $i++) {
    echo "Iteration #$i <br>";
}

echo "<h2>Displaying Even Numbers 1-20</h2>";
for ($i = 2; $i <= 20; $i += 2) {
    echo "$i ";
}
echo "<br>";

echo "<h2>Counting Down</h2>";
for ($i = 10; $i >= 1; $i--) {
    echo "$i... ";
}
echo "Liftoff! <br>";

echo "<h2>Multiplication Table of 5</h2>";
echo "<table border='1' cellpadding='8'>";
echo "<tr><th>Multiplication</th><th>Result</th></tr>";
for ($i = 1; $i <= 10; $i++) {
    $result = 5 * $i;
    echo "<tr><td>5 x $i</td><td>$result</td></tr>";
}
echo "</table>";

echo "<h2>Nested For - Full Multiplication Table</h2>";
echo "<table border='1' cellpadding='6'>";
for ($row = 1; $row <= 5; $row++) {
    echo "<tr>";
    for ($col = 1; $col <= 5; $col++) {
        echo "<td>" . ($row * $col) . "</td>";
    }
    echo "</tr>";
}
echo "</table>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

The `for` loop is structured as `for (initialization; condition; change)`. The initialization (`$i = 1`) runs once at the very start and creates a counter variable. The condition (`$i <= 5`) is checked before every iteration - if it is true, the loop body runs; if it is false, PHP exits the loop. The change (`$i++`) runs after each iteration completes, modifying the counter so the loop makes progress. In the even-numbers example, `$i += 2` jumps by two instead of one, so only even values are processed. In the countdown, `$i--` decrements the counter so the loop runs in reverse. The nested `for` loop demonstrates rows and columns: the outer loop controls which row is being built, and for each row the inner loop runs a complete cycle to fill every column. Every time the outer loop completes one iteration, the inner loop has already run five complete cycles.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-05/for-loop.php
```

---

## 4. The While Loop

The `while` loop is suited when the number of repetitions is not known in advance. The loop keeps running as long as a condition remains `true`, and stops the moment that condition becomes `false`. This makes `while` ideal for situations where the stopping point depends on something that changes during execution, such as user input, a running total, or data from a database.

### Step 1: Create a New File

Navigate to the `lesson-05` folder and create the file:

```bash
micro while-loop.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "<h2>Basic While</h2>";

$count = 1;

while ($count <= 5) {
    echo "Count: $count <br>";
    $count++;
}

echo "<h2>Calculating Total Savings</h2>";
$savings       = 0;
$target        = 500000;
$weekly_saving = 50000;
$week          = 0;

while ($savings < $target) {
    $week++;
    $savings += $weekly_saving;
    echo "Week $week: Savings = Rp$savings <br>";
}
echo "<strong>Target reached in $week weeks!</strong> <br>";

echo "<h2>Do-While Loop</h2>";
$number = 10;

do {
    echo "Current value: $number <br>";
    $number++;
} while ($number < 10);

echo "(The block above ran once even though the condition was immediately false)";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-05/while-loop.php
```

The basic while loop starts with `$count = 1` and the condition `$count <= 5`. Before each iteration, PHP checks the condition. If true, it executes the block and then runs `$count++` to move the counter forward. When `$count` reaches 6, the condition becomes false and the loop stops. The `$count++` line is critical: if you forget it, `$count` never changes, the condition is always true, and PHP loops forever. This is called an infinite loop. The server will eventually time out, but the browser will feel frozen. Always make sure there is something inside the `while` block that will eventually make the condition false.

The savings simulation shows a practical use of `while`: the loop does not know in advance how many weeks are needed. It keeps adding `$weekly_saving` to `$savings` each week until `$savings` reaches `$target`, then stops.

The `do-while` variant always executes its block at least once before checking the condition. In the example, `$number = 10` already fails the condition `$number < 10`, but the block still runs once and prints `"Current value: 10"`. Use `do-while` when the first execution must happen regardless of the condition.

---

## 5. The Foreach Loop

`foreach` is a loop designed specifically to iterate through every item in an array, one by one, from start to end. You do not need to know how many items the array contains - `foreach` handles that automatically. Arrays will be covered in full in Lesson 6. For now, think of an array as a list of values stored in a single variable.

### Step 1: Create a New File

Navigate to the `lesson-05` folder and create the file:

```bash
micro foreach-loop.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "<h2>Basic Foreach</h2>";

$fruits = ["Apple", "Mango", "Orange", "Banana", "Watermelon"];

foreach ($fruits as $item) {
    echo "- $item <br>";
}

echo "<h2>Foreach with Associative Arrays</h2>";
$profile = [
    "name"       => "Dinda Pratiwi",
    "city"       => "Semarang",
    "occupation" => "Designer",
    "age"        => 26
];

foreach ($profile as $key => $value) {
    echo "<strong>" . ucfirst($key) . ":</strong> $value <br>";
}

echo "<h2>Foreach with Conditions</h2>";
$student_grades = [
    "Andi"  => 85,
    "Budi"  => 55,
    "Citra" => 92,
    "Doni"  => 67,
    "Eka"   => 78
];

echo "<strong>Student results (passing grade: 70):</strong><br>";
foreach ($student_grades as $name => $grade) {
    if ($grade >= 70) {
        echo "PASS - $name: $grade <br>";
    } else {
        echo "FAIL - $name: $grade <br>";
    }
}
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-05/foreach-loop.php
```

`foreach ($fruits as $item)` tells PHP: "Take each element from `$fruits` one at a time, put it in the temporary variable `$item`, and run the block." When the block finishes for one item, PHP automatically moves to the next. There is no counter to manage and no condition to write. When using an associative array (one that stores key-value pairs), the syntax `foreach ($profile as $key => $value)` gives you access to both the key and the value in every iteration. `ucfirst($key)` is a built-in PHP function that capitalizes the first letter of a string, giving the output a cleaner look. The third example shows how `foreach` and `if` work together: the loop visits every student, and the conditional inside it decides what label to display based on the grade.

---

## 6. Break and Continue: Controlling Loop Flow

Sometimes you need more control over how a loop runs. `break` exits the loop immediately, regardless of the condition. `continue` skips the rest of the current iteration and jumps to the next one. Both are useful when you need to respond to a specific value inside the loop without changing the loop's overall structure.

### Step 1: Create a New File

Navigate to the `lesson-05` folder and create the file:

```bash
micro break-continue.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "<h2>Break - Stopping a Loop</h2>";

echo "Find the number 7 in the list: <br>";
$target = 7;
for ($i = 1; $i <= 20; $i++) {
    echo "$i ";
    if ($i === $target) {
        echo "<-- found! Loop stopped.";
        break;
    }
}
echo "<br>";

echo "<h2>Continue - Skip One Iteration</h2>";

echo "Display 1-10 except odd numbers: <br>";
for ($i = 1; $i <= 10; $i++) {
    if ($i % 2 !== 0) {
        continue;
    }
    echo "$i ";
}
echo "<br>";

echo "<h2>Practical Example: Available Products</h2>";
$products = [
    ["name" => "Notebook",    "stock" => 50],
    ["name" => "Pencil",      "stock" => 0],
    ["name" => "Ruler",       "stock" => 25],
    ["name" => "Eraser",      "stock" => 0],
    ["name" => "Highlighter", "stock" => 15],
];

echo "<strong>Available products:</strong><br>";
foreach ($products as $p) {
    if ($p["stock"] === 0) {
        continue;
    }
    echo "In stock: {$p['name']} ({$p['stock']} units) <br>";
}
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-05/break-continue.php
```

In the `break` example, the loop is set to run from 1 to 20. When `$i` reaches 7 and matches the target, `break` immediately terminates the loop. PHP exits the `for` block and continues with the code after it, so numbers 8 through 20 are never printed. `break` is useful when you have found what you were looking for and further iterations would be wasted work.

In the `continue` example, every odd number causes `continue` to fire. PHP skips the `echo "$i "` line for that iteration and jumps directly to `$i++` and the next cycle. Only even numbers reach the `echo` statement. The product list example applies `continue` to skip any product with zero stock, so only available items appear in the output.

---

## 7. Fix the Errors in Your Code

This section covers three mistakes that are common when writing loops for the first time. Each one either causes an infinite loop, produces unexpected output, or crashes PHP entirely.

**Error 1: Infinite loop because the counter is never incremented.**

A `while` loop relies on something inside its body to eventually make the condition false. If nothing changes the variable being checked, the condition stays true forever and PHP loops without stopping.

```php
// Wrong
$i = 1;
while ($i <= 5) {
    echo "Number: $i <br>";
}

// Correct
$i = 1;
while ($i <= 5) {
    echo "Number: $i <br>";
    $i++;
}
```

Without `$i++`, `$i` remains 1 on every iteration. The condition `$i <= 5` is always true, so the loop never exits. Adding `$i++` at the end of the block increments the counter after each iteration, and eventually `$i` reaches 6, making the condition false and stopping the loop.

---

**Error 2: Wrong variable name in the loop condition.**

The counter variable in a `for` loop must be the same variable in all three parts: the initialization, the condition, and the change expression. Using a different variable name in the condition means the condition is checking a completely different value.

```php
// Wrong
for ($x = 1; $i <= 10; $x++) {
    echo $x . " ";
}

// Correct
for ($x = 1; $x <= 10; $x++) {
    echo $x . " ";
}
```

In the wrong version, `$x` is the counter being incremented, but the condition checks `$i`, which was set in a previous block and has a value of 6. Since `$i <= 10` is still true (6 is less than or equal to 10), PHP will keep running based on `$i`, not `$x`. The loop will not behave as intended. The fix is to use the same variable (`$x`) consistently across all three parts of the `for` statement.

---

**Error 3: `foreach` without parentheses.**

`foreach` requires its collection and alias variable to be wrapped in parentheses, just like `if` and `while`. Leaving out the parentheses causes an immediate parse error and PHP will not run the file at all.

```php
// Wrong
foreach $colors as $c {
    echo $c . "<br>";
}

// Correct
foreach ($colors as $c) {
    echo $c . "<br>";
}
```

The parentheses around `$colors as $c` are not optional. PHP's parser expects them and will throw a `Parse error: syntax error` if they are missing. This is one of the easiest errors to introduce when typing quickly, so always double-check that both the opening `(` after `foreach` and the closing `)` before `{` are present.

---

## 8. Exercises

Complete the following exercises in the `lesson-05` folder. Use `micro` to create each file and view the results through `http://localhost:8080/learn-php/lesson-05/`.

**Exercise 1:** Create `exercise-1.php`. Use a `for` loop to display the multiplication table of 7, from 7x1 to 7x10, formatted as an HTML table with two columns: "Multiplication" and "Result".

**Exercise 2:** Create `exercise-2.php`. Define an associative array called `$shopping` with at least 5 items and their prices (for example: `"Rice" => 65000`). Use `foreach` to display each item name and price, then calculate and display the total at the bottom.

**Exercise 3:** Create `exercise-3.php`. Use a `while` loop to simulate coin flipping: start from a total of 0, add a random value of 0 or 1 each iteration using `rand(0, 1)`, and stop when the total reaches 10. Display each flip result and the running total, then show how many flips it took.

---

## 9. Solutions

**Solution for Exercise 1:**

```php
<?php
$number = 7;
echo "<h2>Multiplication Table of $number</h2>";
echo "<table border='1' cellpadding='10'>";
echo "<tr><th>Multiplication</th><th>Result</th></tr>";
for ($i = 1; $i <= 10; $i++) {
    echo "<tr><td>$number x $i</td><td>" . ($number * $i) . "</td></tr>";
}
echo "</table>";
?>
```

The `for` loop runs from `$i = 1` to `$i = 10`, producing exactly ten table rows. Inside each iteration, `$number * $i` calculates the result and the expression is wrapped in parentheses so PHP evaluates the multiplication before passing the value to string concatenation. Storing the multiplier in `$number` rather than hardcoding `7` directly inside the loop makes it easy to change the table to any other number by updating only one variable.

---

**Solution for Exercise 2:**

```php
<?php
$shopping = [
    "Rice 5kg"    => 65000,
    "Cooking Oil" => 28000,
    "Sugar"       => 15000,
    "Eggs 1kg"    => 30000,
    "UHT Milk"    => 18000,
];

echo "<h2>Shopping List</h2>";
$total = 0;
foreach ($shopping as $name => $price) {
    echo "$name: Rp$price <br>";
    $total += $price;
}
echo "<hr>";
echo "<strong>Total: Rp$total</strong>";
?>
```

`$total` is initialized to `0` before the loop. On every iteration, `$total += $price` adds the current item's price to the running total. By the time `foreach` finishes, `$total` holds the sum of all prices. The `<hr>` tag draws a horizontal separator between the list and the total, giving the output a clean receipt-like appearance.

---

**Solution for Exercise 3:**

```php
<?php
$total     = 0;
$iteration = 0;
$target    = 10;

echo "<h2>Coin Flip Simulation</h2>";
while ($total < $target) {
    $flip      = rand(0, 1);
    $total    += $flip;
    $iteration++;
    $label     = ($flip === 1) ? "Heads (+1)" : "Tails (0)";
    echo "Flip $iteration: $label | Total: $total <br>";
}
echo "<strong>Done! Reached total $target in $iteration flips.</strong>";
?>
```

`rand(0, 1)` returns either 0 or 1 randomly on each call. Adding this value to `$total` means heads (+1) advances the total while tails (+0) does not. The loop continues until `$total` reaches 10, which will take a different number of flips every time the page is loaded because the results are random. The ternary operator converts the numeric flip result into a readable label. Because the output changes on every page load, this exercise also demonstrates that PHP code runs fresh from scratch on every browser request.

---

## Next Up - Lesson 6

Loops allow you to process unlimited amounts of data with a fixed amount of code. Use `for` when the number of iterations is known in advance, `while` when the stopping point depends on a condition that changes during execution, `do-while` when the block must run at least once before checking, and `foreach` to walk through every item in an array without managing a counter. `break` exits a loop immediately, and `continue` skips one iteration and moves to the next.

In Lesson 6, you will learn about arrays in depth - the data structure that allows a single variable to store many values at once. You will learn indexed arrays, associative arrays, multi-dimensional arrays, and the built-in functions PHP provides for working with them.