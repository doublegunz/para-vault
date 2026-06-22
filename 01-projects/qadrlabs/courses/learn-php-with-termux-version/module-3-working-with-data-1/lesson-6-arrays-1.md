## 1. Before You Begin

So far, each variable you have created stores exactly one value: one name, one number, one boolean. But what if you need to store the names of 30 students, the prices of 50 products, or the list of items in a shopping cart? Creating a separate variable for each one would be completely impractical.

This is where **arrays** come in. An array is a special type of variable that can hold multiple values at once, organized in an ordered structure. Paired with the `foreach` loop from Lesson 5, arrays become an incredibly powerful tool for managing collections of data.

### What You'll Build

You will create a product catalog using indexed arrays, a student profile using associative arrays, and a class grade report using multidimensional arrays.

### What You'll Learn

- ✅ How to create and access indexed arrays (numbered lists)
- ✅ How to create and access associative arrays (key-value pairs)
- ✅ How to work with multidimensional arrays (arrays inside arrays)
- ✅ Frequently used array functions: `count()`, `sort()`, `in_array()`, `implode()`, `explode()`

### What You'll Need

- Termux open with Apache running (`apachectl`)
- Lessons 1 through 5 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson inside your project directory. All files you create in Lesson 6 should live here.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-06
cd lesson-06
```

`mkdir lesson-06` creates the subfolder and `cd lesson-06` moves you into it. Any file you create after running these commands will be accessible through the browser at `http://localhost:8080/learn-php/lesson-06/`.

---

## 3. Indexed Arrays

An indexed array stores values in a numbered list. PHP automatically assigns each value a numeric index, starting from zero. You access individual values by specifying their index in square brackets.

### Step 1: Create a New File

Make sure you are in the `lesson-06` folder, then open a new file:

```bash
micro indexed-array.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
$fruits = ["Apple", "Mango", "Orange", "Banana", "Grape"];

echo "<h2>Accessing Array Elements</h2>";
echo "First element (index 0): " . $fruits[0] . "<br>";
echo "Second element (index 1): " . $fruits[1] . "<br>";
echo "Fifth element (index 4): " . $fruits[4] . "<br>";

echo "<h2>Displaying All Elements with Foreach</h2>";
foreach ($fruits as $fruit) {
    echo "- $fruit <br>";
}

echo "<h2>Displaying Elements with Their Index</h2>";
foreach ($fruits as $index => $fruit) {
    echo "[$index] $fruit <br>";
}

echo "<h2>Counting Elements</h2>";
$total = count($fruits);
echo "Number of fruits in array: $total <br>";

echo "<h2>Adding and Changing Elements</h2>";
$fruits[] = "Melon";
echo "After adding Melon: " . implode(", ", $fruits) . "<br>";

$fruits[0] = "Durian";
echo "After replacing index 0 with Durian: " . implode(", ", $fruits) . "<br>";

echo "<h2>Removing Elements</h2>";
unset($fruits[1]);
echo "After removing Mango: " . implode(", ", $fruits) . "<br>";
echo "Count now: " . count($fruits) . " elements<br>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-06/indexed-array.php
```

Array indexes start from **0**, not 1. In `["Apple", "Mango", "Orange"]`, Apple is at index 0, Mango at index 1, and Orange at index 2. This is called zero-based indexing and is a convention used in most programming languages. The `foreach ($fruits as $index => $fruit)` syntax gives you access to both the numeric index and the value in each iteration. `count($fruits)` returns the total number of elements in the array as an integer. `$fruits[] = "Melon"` with empty square brackets is the standard way to append a new value to the end of an indexed array. `implode(", ", $fruits)` joins all array elements into a single string, separating each one with a comma and space. `unset($fruits[1])` removes the element at index 1, but it does not re-index the remaining elements - the gaps are preserved. Use `array_values($fruits)` after `unset` if you need continuous indexes.

---

## 4. Associative Arrays

An associative array uses named keys instead of numbers to identify each value. This makes the data more readable because you access values by a meaningful label rather than a position number. Associative arrays are used constantly in PHP for things like form data, database rows, and configuration settings.

### Step 1: Create a New File

Navigate to the `lesson-06` folder and create the file:

```bash
micro associative-array.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
$product = [
    "name"      => "Laptop ProBook 14",
    "category"  => "Electronics",
    "price"     => 8500000,
    "stock"     => 25,
    "available" => true,
];

echo "<h2>Accessing by Key</h2>";
echo "Product: " . $product["name"] . "<br>";
echo "Price: Rp" . $product["price"] . "<br>";
echo "In stock: " . ($product["available"] ? "Yes" : "No") . "<br>";

echo "<h2>Iterating with Foreach</h2>";
foreach ($product as $key => $value) {
    echo "<strong>" . ucfirst($key) . ":</strong> $value <br>";
}

echo "<h2>Adding and Modifying</h2>";
$product["brand"] = "ProTech";
$product["price"] = 7999000;
echo "Brand: " . $product["brand"] . "<br>";
echo "New price: Rp" . $product["price"] . "<br>";

echo "<h2>Checking if a Key Exists</h2>";
echo "<pre>";
echo "Key 'name' exists? ";
var_dump(array_key_exists("name", $product));
echo "Key 'color' exists? ";
var_dump(array_key_exists("color", $product));
echo "</pre>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-06/associative-array.php
```

You access a value in an associative array by writing its key inside square brackets as a string: `$product["name"]`. This is more readable than `$product[0]` because the key describes what the value represents. The `foreach ($product as $key => $value)` syntax works the same way as with indexed arrays, but `$key` now holds the string label rather than a number. `ucfirst($key)` capitalizes the first letter of the key, turning `"name"` into `"Name"` for a cleaner display. To add a new key, simply assign to it: `$product["brand"] = "ProTech"`. If the key already exists, the assignment replaces the existing value. `array_key_exists("color", $product)` checks whether a given key is present in the array and returns a boolean. Use this function before accessing a key that might not exist to avoid undefined index errors.

---

## 5. Multidimensional Arrays

A multidimensional array is an array that contains other arrays as its elements. This creates layers of structured data, similar to a spreadsheet with rows and columns. Each row is itself an associative array, and you access values by first selecting the row (by index) and then the column (by key).

### Step 1: Create a New File

Navigate to the `lesson-06` folder and create the file:

```bash
micro multidimensional.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
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

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-06/multidimensional.php
```

The outer `foreach` iterates through each element of `$students`. Each element is itself an associative array, so `$student["name"]` gives the name and `$student["grade"]` gives the grade for that particular row. The ternary operator sets `$status` and `$color` based on whether the grade is 70 or above, and the color is applied directly as an inline CSS style on the table cell. `htmlspecialchars()` converts special HTML characters (like `<`, `>`, and `&`) in user-supplied data into their safe HTML equivalents, preventing the browser from interpreting them as HTML code. `$total_grade` accumulates the sum of all grades across every iteration, and after the loop finishes, dividing by `count($students)` gives the class average. `round($average, 1)` rounds the result to one decimal place.

---

## 6. Frequently Used Array Functions

PHP ships with over 80 built-in functions for working with arrays. This section covers the ones you will encounter most often, covering sorting, searching, and converting between arrays and strings.

### Step 1: Create a New File

Navigate to the `lesson-06` folder and create the file:

```bash
micro array-functions.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "<h2>Sorting</h2>";
$numbers = [42, 17, 8, 33, 25, 5];
echo "Before sort: " . implode(", ", $numbers) . "<br>";
sort($numbers);
echo "After sort: " . implode(", ", $numbers) . "<br>";

rsort($numbers);
echo "After rsort: " . implode(", ", $numbers) . "<br>";

echo "<h2>Searching</h2>";
$cities = ["Jakarta", "Bandung", "Surabaya", "Yogyakarta"];
echo "<pre>";
echo "Is 'Bandung' in the list? ";
var_dump(in_array("Bandung", $cities));
echo "Is 'Semarang' in the list? ";
var_dump(in_array("Semarang", $cities));
echo "</pre>";

echo "<h2>implode() and explode()</h2>";
$tags       = ["php", "web", "programming"];
$tag_string = implode(", ", $tags);
echo "implode: $tag_string <br>";

$csv_line = "Budi,Jakarta,25";
$parts    = explode(",", $csv_line);
echo "explode: Name=" . $parts[0] . ", City=" . $parts[1] . ", Age=" . $parts[2] . "<br>";

echo "<h2>array_push() and array_pop()</h2>";
$stack = ["A", "B", "C"];
array_push($stack, "D");
echo "After push: " . implode(", ", $stack) . "<br>";

$removed = array_pop($stack);
echo "Popped: $removed <br>";
echo "After pop: " . implode(", ", $stack) . "<br>";

echo "<h2>array_merge()</h2>";
$first  = ["Apple", "Banana"];
$second = ["Cherry", "Date"];
$merged = array_merge($first, $second);
echo "Merged: " . implode(", ", $merged) . "<br>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-06/array-functions.php
```

`sort()` sorts an indexed array in ascending order by modifying the original array directly, not returning a new one. `rsort()` does the same in descending order. For associative arrays, use `asort()` to sort by value while preserving keys, or `ksort()` to sort by key. `in_array("Bandung", $cities)` scans the array for the given value and returns `true` if found, `false` if not. It uses loose comparison by default; pass `true` as a third argument to use strict comparison. `implode(", ", $tags)` takes the separator as the first argument and the array as the second, joining all elements into one string. `explode(",", $csv_line)` is the reverse: it splits a string at every occurrence of the separator and returns an indexed array of the resulting pieces. `array_push()` adds one or more values to the end of an array. `array_pop()` removes the last element and returns it. `array_merge()` combines two or more arrays into a new array, reindexing numeric keys sequentially.

---

## 7. Fix the Errors in Your Code

This section presents three mistakes that are common when first working with arrays. Each one either produces a warning, causes invalid syntax, or generates output that looks wrong.

**Error 1: Accessing an index that does not exist.**

An indexed array with three elements has indexes 0, 1, and 2. Attempting to access index 3 goes beyond the array boundary and triggers an "Undefined offset" notice. PHP produces no output for that value, which can silently corrupt your output.

```php
// Wrong
$fruits = ["Apple", "Mango", "Orange"];
echo $fruits[3];

// Correct
$fruits = ["Apple", "Mango", "Orange"];
$last_index = count($fruits) - 1;
echo $fruits[$last_index];
```

`count($fruits)` returns 3, so `count($fruits) - 1` correctly gives index 2, which is the last valid position. Alternatively, when you need the last element, use `end($fruits)` which moves the internal array pointer to the last element and returns its value.

---

**Error 2: Invalid syntax when appending to an array.**

The correct syntax to add an element to the end of an indexed array is `$fruits[] = "Grape"` (empty square brackets). Writing `$fruits[+]` is not valid PHP and causes an immediate parse error.

```php
// Wrong
$fruits[+] = "Grape";

// Correct
$fruits[] = "Grape";
```

Empty square brackets on the left side of an assignment tell PHP to append the new value at the next available index. Alternatively, `array_push($fruits, "Grape")` produces the same result and is useful when you want to add multiple values in one call.

---

**Error 3: Calling `implode()` without a separator.**

`implode()` requires two arguments: the separator string and the array. Calling it with only the array will either produce an error or concatenate all elements without any separation, making the output unreadable.

```php
// Wrong
echo implode($fruits);

// Correct
echo implode(", ", $fruits);
```

The first argument to `implode()` is the string that goes between each element. Passing `", "` inserts a comma and a space between every item. If you want no separator at all (all elements joined with nothing between them), pass an empty string: `implode("", $fruits)`. Note: `join()` is an alias for `implode()` and behaves identically.

---

## 8. Exercises

Complete the following exercises in the `lesson-06` folder. Use `micro` to create each file and view the results through `http://localhost:8080/learn-php/lesson-06/`.

**Exercise 1:** Create `exercise-1.php`. Define an indexed array of 6 country names. Display them as a numbered HTML list using `<ol>` and `<li>` tags with a `foreach` loop. At the bottom, display the total count using `count()`.

**Exercise 2:** Create `exercise-2.php`. Define an associative array with information about a book (title, author, year, pages, genre). Display all the information in a two-column HTML table where the left column shows the field name and the right column shows the value.

**Exercise 3:** Create `exercise-3.php`. Define a multidimensional array containing at least 4 products, each with a name, price, and stock count. Display them in an HTML table. After the table, calculate and display the total inventory value (price multiplied by stock for each product, then summed).

---

## 9. Solutions

**Solution for Exercise 1:**

```php
<?php
$countries = ["Indonesia", "Japan", "Australia", "Brazil", "Germany", "Canada"];

echo "<h2>Country List</h2>";
echo "<ol>";
foreach ($countries as $country) {
    echo "<li>" . htmlspecialchars($country) . "</li>";
}
echo "</ol>";
echo "<p>Total: " . count($countries) . " countries</p>";
?>
```

`foreach` visits each country in order and wraps it in an `<li>` tag. The `<ol>` wrapper tells the browser to render the list with automatic numbering, so you do not need a manual counter variable. `htmlspecialchars()` protects against any country name that might accidentally contain a character that the browser would treat as HTML markup. `count($countries)` returns the exact number of elements without you having to count manually.

---

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

`foreach ($book as $key => $value)` iterates through every field in the associative array. Each iteration produces one table row, with the key in the left cell and the value in the right. `ucfirst($key)` capitalizes the first letter of the key so `"author"` becomes `"Author"` in the output. Because the keys are hardcoded strings under your control, no `htmlspecialchars()` is needed on them here, but the values from external sources should always be escaped.

---

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

`$value = $p["price"] * $p["stock"]` calculates the inventory value for each product. This result is added to `$total_value` on every iteration using `+=`, so by the time the loop finishes `$total_value` holds the sum across all products. `number_format($p["price"])` formats the number with thousands separators (for example, `8500000` becomes `8,500,000`), making large prices much easier to read. The final table row uses `colspan='3'` to merge the first three cells into one, leaving the fourth cell for the total value.

---

## Next Up - Lesson 7

Arrays allow a single variable to hold entire collections of data, from a simple list of names to a complex table of products with multiple attributes. Indexed arrays use numbered positions starting from zero. Associative arrays use named keys for more descriptive access. Multidimensional arrays nest arrays inside arrays for table-like structures. Functions like `count()`, `sort()`, `in_array()`, `implode()`, and `explode()` give you the tools to manipulate those collections without writing the logic yourself.

In Lesson 7, you will learn about functions: how to package reusable logic into named blocks that can be called anywhere in your code with different inputs each time. Functions are what transform repetitive scripts into clean, maintainable programs.