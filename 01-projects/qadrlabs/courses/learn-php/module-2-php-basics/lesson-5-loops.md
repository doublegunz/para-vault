## 1. Before You Begin

Imagine displaying the numbers 1 to 100, or listing every product in a 500-item catalog, or processing each row returned by a database query. Writing each line manually is impractical, and if the data changes, you would need to rewrite everything. Loops are the solution: you write the code once, and PHP repeats it as many times as necessary.

### Introduction

A loop is an instruction that makes PHP execute the same block of code repeatedly until a condition is no longer true. Loops are one of the most powerful tools in programming because they remove the need to repeat yourself and allow programs to process data of any size. This lesson introduces all four PHP loop types and shows when to use each one.

### What You'll Build

You will build a multiplication table using `for`, a savings simulator using `while`, and a shopping list with a running total using `foreach`.

### What You'll Learn

- ✅ `for` loops for when the number of iterations is known in advance
- ✅ `while` loops for when iteration continues until a dynamic condition changes
- ✅ `do-while` loops that always run at least once before checking their condition
- ✅ `foreach` loops for iterating through every item in an array
- ✅ `break` to stop a loop early and `continue` to skip an iteration

### What You'll Need

- Laragon running
- VS Code open in the `learn-php` folder
- Lessons 1 through 4 completed

---

## 2. Setup

Create a new subfolder called `lesson-05` inside the `learn-php` folder.

---

## 3. The For Loop

The `for` loop is ideal when you know exactly how many times the loop should run before it starts. It packs three pieces of control information into a single compact declaration.

### Step 1: Create a New File

Create a file called `for-loop.php` in the `lesson-05` folder.

### Step 2: Write the Code

Open `for-loop.php` and type the following code:

```php
<?php
echo "<h2>Basic For Loop</h2>";

// for (initialization; condition; increment)
// Read it as: "Start with $i = 1, keep going while $i <= 5, add 1 each time"
for ($i = 1; $i <= 5; $i++) {
    echo "Iteration #$i <br>";
}

echo "<h2>Even Numbers 1-20</h2>";
// $i += 2 jumps by 2 each iteration, so only even numbers are visited
for ($i = 2; $i <= 20; $i += 2) {
    echo "$i ";
}
echo "<br>";

echo "<h2>Counting Down</h2>";
// A for loop can also run backwards by decrementing
for ($i = 10; $i >= 1; $i--) {
    echo "$i... ";
}
echo "Liftoff! 🚀 <br>";

echo "<h2>Multiplication Table of 5</h2>";
echo "<table border='1' cellpadding='8'>";
echo "<tr><th>Expression</th><th>Result</th></tr>";
for ($i = 1; $i <= 10; $i++) {
    $result = 5 * $i;
    echo "<tr><td>5 × $i</td><td>$result</td></tr>";
}
echo "</table>";

echo "<h2>Nested For — Full Multiplication Grid</h2>";
// A for loop inside a for loop: outer controls rows, inner controls columns
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

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-05/for-loop.php
```

The `for` loop's declaration `($i = 1; $i <= 5; $i++)` has three parts separated by semicolons. The first part `$i = 1` is the **initialization** — it runs once at the start, creating the counter variable. The second part `$i <= 5` is the **condition** — it is checked before every iteration, and when it becomes false, the loop stops. The third part `$i++` is the **update expression** — it runs after every iteration to change the counter. The standard name `$i` stands for "iterator" and is used by convention, though you can name it anything. The nested loop example shows a common pattern: an outer loop iterates rows while an inner loop iterates columns for each row, producing a two-dimensional table.

---

## 4. The While Loop

The `while` loop is suited for situations where you cannot know in advance how many iterations will be needed because the stopping condition depends on something that changes during execution.

### Step 1: Create a New File

Create a file called `while-loop.php` in the `lesson-05` folder.

### Step 2: Write the Code

Open `while-loop.php` and type the following code:

```php
<?php
echo "<h2>Basic While</h2>";
$count = 1;

// "As long as $count is less than or equal to 5, run this block"
while ($count <= 5) {
    echo "Count: $count <br>";
    $count++;   // CRITICAL: without this, $count never changes and the loop runs forever
}

echo "<h2>Savings Simulator</h2>";
$savings       = 0;
$target        = 500000;
$weekly_saving = 50000;
$week          = 0;

// The stopping condition depends on $savings, which changes during the loop
while ($savings < $target) {
    $week++;
    $savings += $weekly_saving;
    echo "Week $week: Total savings = Rp$savings <br>";
}
echo "<strong>Reached Rp$target in $week weeks!</strong> <br>";

echo "<h2>Do-While Loop</h2>";
// do-while ALWAYS runs the block at least once,
// THEN checks the condition at the end
$number = 10;

do {
    echo "Current value: $number <br>";
    $number++;
} while ($number < 10);  // This condition is false immediately, but the block ran once

echo "(The block above ran once even though the condition was false from the start)";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-05/while-loop.php
```

The most important comment in the `while` loop section is the one about incrementing `$count`. Without `$count++`, the variable stays at 1 forever, the condition `$count <= 5` is always true, and PHP loops indefinitely. This is called an infinite loop, and it will freeze your browser tab while Laragon's server CPU spins at maximum. Always ensure something inside the loop eventually makes the condition false.

The `do-while` loop difference is subtle but useful: the code block runs first, then the condition is checked. This guarantees at least one execution regardless of the condition, which is helpful when you want to "try something once and then decide whether to keep trying."

---

## 5. The Foreach Loop

`foreach` is designed specifically for arrays. It visits every element in the array automatically without needing a counter, making it the cleanest way to process collections.

### Step 1: Create a New File

Create a file called `foreach-loop.php` in the `lesson-05` folder.

### Step 2: Write the Code

Open `foreach-loop.php` and type the following code:

```php
<?php
echo "<h2>Basic Foreach</h2>";
$fruits = ["Apple", "Mango", "Orange", "Banana", "Watermelon"];

// "For each item in $fruits, store it in $item, then run the block"
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

// Use "as $key => $value" to access both the key name and the value
foreach ($profile as $key => $value) {
    echo "<strong>" . ucfirst($key) . ":</strong> $value <br>";
}

echo "<h2>Foreach + Conditions</h2>";
$student_grades = [
    "Andi"  => 85,
    "Budi"  => 55,
    "Citra" => 92,
    "Doni"  => 67,
    "Eka"   => 78
];

echo "<strong>Grade results:</strong><br>";
foreach ($student_grades as $name => $grade) {
    if ($grade >= 70) {
        echo "✅ $name: $grade — Pass <br>";
    } else {
        echo "❌ $name: $grade — Fail <br>";
    }
}
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-05/foreach-loop.php
```

The `foreach ($fruits as $item)` syntax is read as "for each element in the array `$fruits`, assign the current element to the variable `$item` and run the block." When working with associative arrays, the `as $key => $value` form gives you access to both the key name and the corresponding value. The `ucfirst($key)` call capitalizes the first letter of the key so it displays as "Name" instead of "name" — a small formatting touch that makes a real difference in readability.

---

## 6. Break and Continue

Sometimes you need finer control over loop execution: stopping the whole loop early, or skipping just the current iteration without stopping everything.

### Step 1: Create a New File

Create a file called `break-continue.php` in the `lesson-05` folder.

### Step 2: Write the Code

Open `break-continue.php` and type the following code:

```php
<?php
echo "<h2>break — Stop the Loop Early</h2>";
$target = 7;
for ($i = 1; $i <= 20; $i++) {
    echo "$i ";
    if ($i === $target) {
        echo "<-- found! Loop stopped.";
        break;   // exit the for loop immediately
    }
}
echo "<br>";

echo "<h2>continue — Skip One Iteration</h2>";
for ($i = 1; $i <= 10; $i++) {
    if ($i % 2 !== 0) {
        continue;   // if odd, skip the echo and go to the next iteration
    }
    echo "$i ";     // only even numbers reach this line
}
echo "<br>";

echo "<h2>Practical Example: Skip Out-of-Stock Items</h2>";
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
        continue;  // skip this item and move to the next
    }
    echo "✅ {$p['name']} — stock: {$p['stock']} <br>";
}
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-05/break-continue.php
```

The `break` statement in the search loop exits the entire loop the moment the target number is found, rather than continuing to count all the way to 20 after the answer is already known. The `continue` statement in the even-number loop skips the `echo` for odd numbers by jumping straight to the increment and next condition check. Notice how neither statement stops the whole program — `break` only exits the loop, and `continue` only skips one iteration.

---

## 7. Fix the Errors in Your Code

```php
<?php
// Error 1: Missing increment — infinite loop
$i = 1;
while ($i <= 5) {
    echo "Number: $i <br>";
}

// Error 2: Wrong variable name in the condition
for ($x = 1; $i <= 10; $x++) {
    echo $x . " ";
}

// Error 3: Missing parentheses in foreach
$colors = ["Red", "Green", "Blue"];
foreach $colors as $c {
    echo $c . "<br>";
}
?>
```

The first error is the classic infinite loop: `$i` is never changed inside the `while` block, so the condition `$i <= 5` is always true. Add `$i++;` as the last line inside the block. The second error has `$i` in the condition instead of `$x`. If `$i` happens to still be 6 from the previous loop (after it stops when the first error is fixed), the loop condition might immediately be false, or it might never stop depending on `$i`'s current value. Change `$i <= 10` to `$x <= 10`. The third error is simply missing parentheses around the array and alias: `foreach` requires `foreach ($colors as $c) {`.

---

## 8. Exercises

**Exercise 1:** Create `exercise-1.php`. Use a `for` loop to display the full multiplication table of 7 (from 7×1 to 7×10) as an HTML table.

**Exercise 2:** Create `exercise-2.php`. Build an associative array of at least 5 items with their prices (like `"Rice" => 65000`). Use `foreach` to display each item and price, then calculate and display the total.

**Exercise 3:** Create `exercise-3.php`. Use a `while` loop to simulate coin flipping: start from 0, add `rand(0, 1)` each iteration (heads = 1, tails = 0), and stop when the total reaches 10. Display each flip and the total flips needed.

---

## 9. Solutions

**Solution for Exercise 1:**

```php
<?php
$number = 7;
echo "<h2>Multiplication Table of $number</h2>";
echo "<table border='1' cellpadding='10'>";
echo "<tr><th>Expression</th><th>Result</th></tr>";
for ($i = 1; $i <= 10; $i++) {
    echo "<tr><td>$number × $i</td><td>" . ($number * $i) . "</td></tr>";
}
echo "</table>";
?>
```

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
echo "<hr><strong>Total: Rp$total</strong>";
?>
```

**Solution for Exercise 3:**

```php
<?php
$total     = 0;
$iteration = 0;

echo "<h2>Coin Flip Simulation</h2>";
while ($total < 10) {
    $flip      = rand(0, 1);
    $total    += $flip;
    $iteration++;
    $label     = ($flip === 1) ? "Heads (+1)" : "Tails (0)";
    echo "Flip $iteration: $label — Running total: $total <br>";
}
echo "<strong>Reached total 10 in $iteration flips.</strong>";
?>
```

---

## 10. Understanding Loops

Loops exist because computers are very good at doing the same thing over and over, and programmers should not have to write the same code over and over. The four PHP loop types each serve a different pattern. Use `for` when the count is known before the loop starts, such as "repeat exactly 10 times." Use `while` when the count is determined by something that changes during execution, such as "keep going until the savings target is reached." Use `do-while` when the first execution must always happen before any condition is checked. Use `foreach` when processing every element in an array, which is the most common loop in web development because so much data arrives as arrays from forms or databases.

The combination of loops and conditionals from Lesson 4 is where real programming power emerges. `foreach` with an `if` inside is the pattern behind almost every listing page on every website: loop through rows, check conditions, display results differently based on what each row contains.

---

## 11. Conclusion

Loops automate repetition. `for` works when you know the count, `while` when a condition drives stopping, `do-while` when you need at least one execution, and `foreach` for every element in an array. Use `break` to exit a loop early and `continue` to skip one iteration. Always ensure a `while` loop has code that eventually makes its condition false, to avoid infinite loops.

**In Lesson 6**, you will learn arrays in depth — how to organize related data into collections, and the functions PHP provides for sorting, searching, and transforming them.