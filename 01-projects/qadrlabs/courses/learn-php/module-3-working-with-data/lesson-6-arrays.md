## 1. Before You Begin

Every variable you have created so far holds exactly one value. That works for a single name or a single price, but what about a shopping cart with 10 items, a class roster with 30 students, or a list of 500 products? Creating a separate variable for each value would make your code unmanageable. Arrays solve this by letting one variable hold an entire collection of values at once.

### Introduction

An array is PHP's way of organizing multiple values into a single named container with a structure that makes them easy to access, loop through, sort, and search. Arrays are the data structure you will use more than any other in web development, because data from databases, forms, and external APIs almost always arrives as collections. Paired with the `foreach` loop from Lesson 5, arrays are where PHP's real power starts to show.

### What You'll Build

You will create a product catalog using indexed arrays, a student profile using associative arrays, and a class grade report using multidimensional arrays. You will also explore the most commonly used array functions.

### What You'll Learn

- ✅ Indexed arrays: numbered lists starting from zero
- ✅ Associative arrays: key-value pairs with named keys
- ✅ Multidimensional arrays: arrays that contain other arrays
- ✅ Essential functions: `count()`, `sort()`, `in_array()`, `implode()`, `explode()`

### What You'll Need

- Laragon running
- VS Code open in the `learn-php` folder
- Lessons 1 through 5 completed

---

## 2. Setup

Create a new subfolder called `lesson-06` inside the `learn-php` folder.

---

## 3. Indexed Arrays

An indexed array stores values in a numbered sequence. PHP automatically assigns positions starting from 0 (not 1), and you access any value by specifying its position number in square brackets.

### Step 1: Create a New File

Create a file called `indexed-array.php` in the `lesson-06` folder.

### Step 2: Write the Code

Open `indexed-array.php` and type the following code:

```php
<?php
// Create an indexed array using square bracket syntax
$fruits = ["Apple", "Mango", "Orange", "Banana", "Grape"];

echo "<h2>Accessing Array Elements by Index</h2>";
// Indexes start at 0, not 1 — this is called zero-based indexing
echo "First element (index 0): " . $fruits[0] . "<br>";    // Apple
echo "Second element (index 1): " . $fruits[1] . "<br>";   // Mango
echo "Last element (index 4): " . $fruits[4] . "<br>";     // Grape

echo "<h2>Looping with Foreach</h2>";
foreach ($fruits as $fruit) {
    echo "- $fruit <br>";
}

echo "<h2>Foreach with Index Numbers</h2>";
foreach ($fruits as $index => $fruit) {
    echo "[$index] $fruit <br>";
}

echo "<h2>Counting: count()</h2>";
$total = count($fruits);
echo "Number of fruits: $total <br>";

echo "<h2>Adding and Modifying Elements</h2>";
// Empty brackets [] appends to the end of the array
$fruits[] = "Melon";
echo "After adding Melon: " . implode(", ", $fruits) . "<br>";

// Assign to a specific index to change that element
$fruits[0] = "Durian";
echo "After replacing index 0 with Durian: " . implode(", ", $fruits) . "<br>";

echo "<h2>Removing Elements: unset()</h2>";
unset($fruits[1]);
// Note: unset() removes the element but leaves a gap in the indexes
echo "After removing index 1: " . implode(", ", $fruits) . "<br>";
echo "Count now: " . count($fruits) . " elements<br>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-06/indexed-array.php
```

The most important thing to internalize about indexed arrays is zero-based indexing: the first element is at position 0, the second at position 1, and so on. An array with 5 elements has valid indexes from 0 to 4 — there is no element at index 5. Trying to access `$fruits[5]` would produce a warning and return `null`. The `implode(", ", $fruits)` call joins all array elements into a single string with the separator you specify, which is a convenient way to display an entire array as a comma-separated list for quick output.

---

## 4. Associative Arrays

An associative array uses descriptive string keys instead of numbers. This makes code more readable because you refer to values by what they are (`$product["name"]`) rather than where they are (`$product[0]`).

### Step 1: Create a New File

Create a file called `associative-array.php` in the `lesson-06` folder.

### Step 2: Write the Code

Open `associative-array.php` and type the following code:

```php
<?php
// Each element uses a "key" => "value" pair
$product = [
    "name"      => "Laptop ProBook 14",
    "category"  => "Electronics",
    "price"     => 8500000,
    "stock"     => 25,
    "available" => true,
];

echo "<h2>Accessing by Key</h2>";
// Square brackets with the key name retrieves that value
echo "Product: " . $product["name"] . "<br>";
echo "Price: Rp" . $product["price"] . "<br>";
echo "In stock: " . ($product["available"] ? "Yes" : "No") . "<br>";

echo "<h2>Iterating with Foreach</h2>";
// $key receives the key name, $value receives the corresponding value
foreach ($product as $key => $value) {
    echo "<strong>" . ucfirst($key) . ":</strong> $value <br>";
}

echo "<h2>Adding and Modifying</h2>";
$product["brand"] = "ProTech";       // Add a completely new key
$product["price"] = 7999000;         // Overwrite an existing key's value
echo "Brand: " . $product["brand"] . "<br>";
echo "New price: Rp" . $product["price"] . "<br>";

echo "<h2>Checking if a Key Exists</h2>";
echo "<pre>";
echo "Key 'name' exists? ";
var_dump(array_key_exists("name", $product));    // true
echo "Key 'color' exists? ";
var_dump(array_key_exists("color", $product));   // false
echo "</pre>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-06/associative-array.php
```

Associative arrays are particularly useful when representing a real-world entity that has named properties, like a product, a user profile, or a database row. Instead of trying to remember that `$product[0]` is the name and `$product[2]` is the price, you write `$product["name"]` and `$product["price"]` — the code reads almost like plain English. The `array_key_exists()` function is your safety tool when working with external data: before accessing a key that might not be there, check first to avoid "undefined index" warnings.

---

## 5. Multidimensional Arrays

A multidimensional array is an array where each element is itself another array. This creates a table-like structure: the outer array holds rows, and each inner array holds columns of data for one row. This is exactly how database query results are typically structured in PHP.

### Step 1: Create a New File

Create a file called `multidimensional.php` in the `lesson-06` folder.

### Step 2: Write the Code

Open `multidimensional.php` and type the following code:

```php
<?php
// An array of associative arrays — essentially a table where
// each "row" is an associative array with the same keys
$students = [
    ["name" => "Andi",  "grade" => 85, "city" => "Jakarta"],
    ["name" => "Budi",  "grade" => 55, "city" => "Bandung"],
    ["name" => "Citra", "grade" => 92, "city" => "Surabaya"],
    ["name" => "Dewi",  "grade" => 78, "city" => "Jakarta"],
    ["name" => "Eka",   "grade" => 67, "city" => "Yogyakarta"],
];

echo "<h2>Student Grade Report</h2>";
echo "<table border='1' cellpadding='8' cellspacing='0'>";
echo "<tr><th>No</th><th>Name</th><th>Grade</th><th>City</th><th>Status</th></tr>";

$no          = 1;
$total_grade = 0;

foreach ($students as $student) {
    // Access nested values using the key on the inner array
    $status = ($student["grade"] >= 70) ? "Pass" : "Fail";
    $color  = ($student["grade"] >= 70) ? "green" : "red";
    $total_grade += $student["grade"];

    echo "<tr>";
    echo "<td>$no</td>";
    echo "<td>" . htmlspecialchars($student["name"]) . "</td>";
    echo "<td>" . $student["grade"] . "</td>";
    echo "<td>" . htmlspecialchars($student["city"]) . "</td>";
    echo "<td style='color: $color;'><strong>$status</strong></td>";
    echo "</tr>";
    $no++;
}

echo "</table>";

$average = $total_grade / count($students);
echo "<p>Class average: " . round($average, 1) . "</p>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-06/multidimensional.php
```

You access a value in a multidimensional array using two sets of brackets: the first selects the outer (row) element, and the second selects the inner (column) value. For example, `$students[2]["name"]` would give "Citra". When you use `foreach`, each iteration gives you one inner array as `$student`, and you then access `$student["name"]`, `$student["grade"]`, and so on. This exact pattern is how you will display database query results in Lesson 11, making this one of the most important data structures to practice.

---

## 6. Essential Array Functions

PHP provides over 80 built-in functions for working with arrays. Here are the ones you will use most frequently in real projects.

### Step 1: Create a New File

Create a file called `array-functions.php` in the `lesson-06` folder.

### Step 2: Write the Code

Open `array-functions.php` and type the following code:

```php
<?php
echo "<h2>Sorting</h2>";
$numbers = [42, 17, 8, 33, 25, 5];
echo "Before: " . implode(", ", $numbers) . "<br>";

sort($numbers);   // Sort ascending — modifies the ORIGINAL array in place
echo "After sort(): " . implode(", ", $numbers) . "<br>";

rsort($numbers);  // Sort descending
echo "After rsort(): " . implode(", ", $numbers) . "<br>";

echo "<h2>Searching: in_array()</h2>";
$cities = ["Jakarta", "Bandung", "Surabaya", "Yogyakarta"];
echo "<pre>";
echo "Is 'Bandung' in the list? ";
var_dump(in_array("Bandung", $cities));      // true
echo "Is 'Semarang' in the list? ";
var_dump(in_array("Semarang", $cities));     // false
echo "</pre>";

echo "<h2>implode() and explode()</h2>";
// implode(): join array elements into a string with a separator
$tags       = ["php", "web", "programming"];
$tag_string = implode(", ", $tags);
echo "implode result: $tag_string <br>";     // php, web, programming

// explode(): split a string into an array using a delimiter
$csv_line = "Budi,Jakarta,25";
$parts    = explode(",", $csv_line);
echo "explode result: Name=" . $parts[0] . ", City=" . $parts[1] . ", Age=" . $parts[2] . "<br>";

echo "<h2>array_push() and array_pop()</h2>";
$stack = ["A", "B", "C"];
array_push($stack, "D");         // Add element to the end
echo "After push: " . implode(", ", $stack) . "<br>";   // A, B, C, D

$removed = array_pop($stack);    // Remove and return the last element
echo "Popped: $removed <br>";
echo "After pop: " . implode(", ", $stack) . "<br>";    // A, B, C

echo "<h2>array_merge()</h2>";
$first  = ["Apple", "Banana"];
$second = ["Cherry", "Date"];
$merged = array_merge($first, $second);
echo "Merged: " . implode(", ", $merged) . "<br>";      // Apple, Banana, Cherry, Date
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-06/array-functions.php
```

A few important notes about these functions: `sort()` and `rsort()` modify the original array in place rather than returning a new one, which is different from some other languages. `implode()` takes the separator as the first argument and the array as the second — remember this order because reversing them is a common error. The `explode()` function is extremely useful when processing CSV data or URL parameters where values are packed into a single string with a known delimiter.

---

## 7. Fix the Errors in Your Code

```php
<?php
$fruits = ["Apple", "Mango", "Orange"];

// Error 1: Accessing an index that does not exist
echo $fruits[3];

// Error 2: Incorrect syntax for appending an element
$fruits[+] = "Grape";

// Error 3: Missing separator argument in implode()
echo join($fruits);
?>
```

The first error tries to access index 3 on a three-element array whose valid indexes are 0, 1, and 2. This causes an "undefined array key 3" warning. Always verify that an index exists before accessing it, or use `count()` to know the valid range. The second error uses `[+]` which is invalid syntax. To append to an array, use empty brackets `$fruits[] = "Grape"` or the `array_push($fruits, "Grape")` function. The third error passes only one argument to `implode()` (or its alias `join()`), but it requires two: the separator string and the array. Without a separator, you would get an error. The correct form is `implode(", ", $fruits)`.

---

## 8. Exercises

**Exercise 1:** Create `exercise-1.php`. Build an indexed array of 6 country names. Display them as an HTML ordered list (`<ol>`) using `foreach`. Show the total count at the end.

**Exercise 2:** Create `exercise-2.php`. Build an associative array with book data (title, author, year, pages, genre). Display all fields in an HTML table.

**Exercise 3:** Create `exercise-3.php`. Build a multidimensional array with at least 4 products, each having name, price, and stock. Display them in an HTML table. Calculate and show the total inventory value (price × stock, summed across all products).

---

## 9. Solutions

**Solution for Exercise 1:**

```php
<?php
$countries = ["Indonesia", "Japan", "Australia", "Brazil", "Germany", "Canada"];

echo "<h2>Country List</h2><ol>";
foreach ($countries as $country) {
    echo "<li>" . htmlspecialchars($country) . "</li>";
}
echo "</ol>";
echo "<p>Total: " . count($countries) . " countries</p>";
?>
```

**Solution for Exercise 2:**

```php
<?php
$book = [
    "title"  => "Clean Code",
    "author" => "Robert C. Martin",
    "year"   => 2008,
    "pages"  => 464,
    "genre"  => "Software Engineering",
];

echo "<h2>Book Information</h2>";
echo "<table border='1' cellpadding='8'>";
foreach ($book as $key => $value) {
    echo "<tr><td><strong>" . ucfirst($key) . "</strong></td><td>$value</td></tr>";
}
echo "</table>";
?>
```

**Solution for Exercise 3:**

```php
<?php
$products = [
    ["name" => "Laptop",   "price" => 8500000, "stock" => 10],
    ["name" => "Mouse",    "price" => 150000,  "stock" => 50],
    ["name" => "Keyboard", "price" => 750000,  "stock" => 30],
    ["name" => "Monitor",  "price" => 2800000, "stock" => 15],
];

echo "<h2>Product Catalog</h2>";
echo "<table border='1' cellpadding='8' cellspacing='0'>";
echo "<tr><th>Product</th><th>Price</th><th>Stock</th><th>Value</th></tr>";

$total_value = 0;
foreach ($products as $p) {
    $value        = $p["price"] * $p["stock"];
    $total_value += $value;
    echo "<tr>";
    echo "<td>" . htmlspecialchars($p["name"]) . "</td>";
    echo "<td>Rp" . number_format($p["price"]) . "</td>";
    echo "<td>" . $p["stock"] . "</td>";
    echo "<td>Rp" . number_format($value) . "</td>";
    echo "</tr>";
}
echo "<tr><td colspan='3'><strong>Total Inventory Value</strong></td>";
echo "<td><strong>Rp" . number_format($total_value) . "</strong></td></tr>";
echo "</table>";
?>
```

---

## 10. Understanding Arrays

Arrays are the backbone of data handling in PHP because web applications are fundamentally about moving collections of data around. Every database query returns an array of rows. Every form with multiple checkboxes submits an array. Every API response you parse arrives as a nested array structure. Becoming fluent with arrays is one of the highest-leverage skills in PHP development.

Zero-based indexing is the norm across most programming languages, and the reason is historical: the index is actually an offset from the start of the array in memory, so the first element is 0 positions from the start. Understanding this removes the confusion whenever you feel the urge to write `$arr[1]` for the first element.

Associative arrays are PHP's version of a "dictionary" or "hash map" in other languages. Using meaningful string keys instead of numeric indexes makes code self-documenting: `$user["email"]` tells you immediately what is stored there, while `$user[2]` requires you to remember or look up what index 2 means. When in doubt between indexed and associative, choose associative for any data with named fields.

Multidimensional arrays are where the conceptual leap happens. Once you realize that an "array of associative arrays" is structurally identical to a database table (rows and columns), reading and generating PHP arrays from database queries becomes intuitive rather than confusing.

---

## 11. Conclusion

Arrays let a single variable hold an entire collection. Indexed arrays use zero-based numeric positions. Associative arrays use string keys for named access. Multidimensional arrays nest arrays inside arrays for table-like structures. Essential functions include `count()`, `sort()`, `in_array()`, `implode()`, and `explode()`. The `foreach` loop is the primary tool for iterating through arrays of any type.

**In Lesson 7**, you will learn about functions — how to package reusable logic into named blocks that can be called with different inputs and return results, turning repetitive scripts into clean, maintainable code.