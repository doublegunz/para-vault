## 1. Before You Begin

Every list you have used so far has been an array, and arrays have a fixed length decided when the program is written. A shopping cart, a list of tasks, or the scores entered by a teacher do not work that way: items are added and removed while the program runs, and nobody knows in advance how many there will be. Rust's answer is the vector, a list that can grow and shrink.

Vectors also open the door to one of Rust's most expressive features: iterators. Instead of writing a loop with a running total every time, you can describe what you want as a chain of steps, such as "keep the passing scores, double them, and add them up," and pass small anonymous functions called closures to each step. In this lesson you will create and change vectors, loop over them safely, and process them with iterator chains.

### What You'll Build

A `vectors` program that manages a shopping cart (adding, reading, and removing items), applies a bonus to a list of exam scores, sorts and searches them, and then analyzes the scores with iterators: totals, counts, the highest score, transformed lists, numbered output, and a configurable passing grade.

### What You'll Learn

- ✅ How to create vectors with `Vec::new()` and the `vec!` macro
- ✅ How to add, read, and remove elements with `push`, indexing, `get`, `pop`, and `remove`
- ✅ How to loop over a vector by reference and change its elements with `&mut`
- ✅ How to sort a vector and check whether it contains a value
- ✅ What iterators are and how `iter()`, `sum`, `count`, and `max` work
- ✅ How to write closures with `|x| ...` and pass them to `map` and `filter`
- ✅ How to build a new vector with `collect`, and number items with `enumerate`

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with references, `&mut`, and slices (Lesson 10)
- Comfort with `Option` and `match` (Lesson 12)

---

## 2. Create and Change a Vector

A vector, written `Vec<T>`, stores any number of values of the same type `T` next to each other on the heap. Like a `String`, it owns its data and can grow as needed. In fact, a `String` is essentially a vector of bytes with extra rules for text.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new vectors
cd vectors
```

These commands create the `vectors` project. The whole program lives in `main` this time, built up section by section.

### Step 2: Create a Vector and Push Items

Replace the contents of `src/main.rs` with:

```rust
fn main() {
    // Create a vector and add items.
    let mut cart: Vec<String> = Vec::new();
    cart.push(String::from("rice"));
    cart.push(String::from("eggs"));
    cart.push(String::from("milk"));
    println!("Cart: {:?} ({} items)", cart, cart.len());
```

`Vec::new()` creates an empty vector. Because it is empty, Rust cannot guess what type of elements it will hold, so the annotation `Vec<String>` says "a vector of `String` values." The angle brackets hold the element type, just as with `Option<u32>` in Lesson 12.

`push` adds an element to the end of the vector. It changes the vector, so `cart` must be `mut`. Each `String` is moved into the vector, which becomes its owner. `len()` returns the number of elements, and `{:?}` prints the whole vector, just like an array.

### Step 3: Read Items Safely

Add these lines:

```rust
    // Read items by index and with get.
    println!("First item: {}", cart[0]);
    match cart.get(5) {
        Some(item) => println!("Item 5: {item}"),
        None => println!("There is no item 5."),
    }
```

There are two ways to read an element. Indexing with `cart[0]` works like arrays: it returns the element at that position, and panics if the position does not exist. Because a vector's length changes at runtime, the compiler usually cannot check indexes in advance.

`get(5)` is the safe alternative. It returns an `Option`: `Some(&element)` if the index exists and `None` if it does not. The cart has three items, so position 5 does not exist and the `None` arm runs. Use `get` whenever the index comes from somewhere you do not fully control, such as user input.

### Step 4: Remove Items

Add these lines:

```rust
    // Remove items.
    let last = cart.pop();
    println!("Removed with pop: {:?}", last);
    let first = cart.remove(0);
    println!("Removed with remove(0): {first}");
    println!("Cart now: {:?}", cart);
```

`pop()` removes the last element and returns it wrapped in an `Option`, because the vector might be empty. Here it returns `Some("milk")`, and ownership of that `String` moves out of the vector into `last`. `remove(0)` removes the element at a given position, shifts the following elements one place to the left, and returns the removed element directly (it panics if the index is out of bounds). After both removals, only `"eggs"` is left.

---

## 3. Loop over and Modify a Vector

Looping over a vector works just like looping over an array, with one important detail you already met in Lesson 11: whether the loop borrows the vector or takes ownership of it.

### Step 1: Create a Vector with vec! and Loop over It

Add these lines:

```rust
    // vec! macro, loops, and changing items.
    let mut scores = vec![72, 88, 95, 64, 81];
    for score in &scores {
        print!("{score} ");
    }
    println!();
```

The `vec!` macro creates a vector with initial values, using the same syntax as an array literal. Rust infers the type `Vec<i32>` from the values, so no annotation is needed.

`for score in &scores` borrows the vector, and each `score` is a `&i32` reference. The vector is still usable after the loop. Writing `for score in scores` without `&` would move the vector into the loop, and `scores` could not be used afterward (see Section 6).

### Step 2: Change Every Element

Add a bonus of five points to every score:

```rust
    for score in &mut scores {
        *score += 5;
    }
    println!("After bonus: {:?}", scores);
```

`for score in &mut scores` borrows the vector mutably, so each `score` is a `&mut i32`: a mutable reference to one element. To change the value it points to, you dereference it with `*`, as you learned in Lesson 10. `*score += 5` adds five to the element itself, inside the vector.

### Step 3: Sort and Search

Add these lines:

```rust
    scores.push(70);
    scores.sort();
    println!("Sorted: {:?}", scores);
    println!("Contains 100? {}", scores.contains(&100));
```

After adding one more score, `sort()` arranges the elements from smallest to largest, changing the vector in place. `contains(&100)` returns `true` if any element equals 100. It takes a reference to the value to look for, which is why the argument is `&100`.

---

## 4. Process Data with Iterators and Closures

The loops above are fine, but a lot of everyday code follows the same few patterns: add everything up, count the elements that match a condition, transform every element, keep only some elements. Iterators turn each of those patterns into a named method, so the code says *what* it does instead of *how*.

An iterator is something that produces a sequence of values, one at a time. `scores.iter()` creates an iterator that produces a reference to each element of `scores`, in order. Every `for` loop you have written already used an iterator behind the scenes. Iterator methods let you build a pipeline of steps on top of it.

### Step 1: Sum, Count, and Find the Maximum

Add these lines:

```rust
    // Iterators with closures.
    let total: i32 = scores.iter().sum();
    let passed = scores.iter().filter(|s| **s >= 75).count();
    let highest = scores.iter().max();
    println!("Total: {total}, passed: {passed}, highest: {:?}", highest);
```

`scores.iter().sum()` adds up every element. The annotation `: i32` tells `sum` what type the result should be, because it could sum into several different numeric types.

`filter` keeps only the elements for which a condition is true, and `count` counts how many are left. The condition is written as a closure: `|s| **s >= 75`. A closure is a small, anonymous function written inline. The parameters go between vertical bars, `|s|`, and the body follows, here the expression `**s >= 75`. `filter` calls the closure once for each element and keeps those for which it returns `true`.

Why two stars? `iter()` produces references to the elements (`&i32`), and `filter` passes each item to the closure by reference again, so `s` is a reference to a reference (`&&i32`). Each `*` removes one layer. This double reference only appears in `filter`; in most other methods there is just one layer.

`max()` returns the largest element. It returns an `Option`, because an empty vector has no maximum, so the output shows `Some(100)`. `min()` works the same way for the smallest element.

### Step 2: Transform Elements and Collect a New Vector

Add these lines:

```rust
    let doubled: Vec<i32> = scores.iter().map(|s| s * 2).collect();
    println!("Doubled: {:?}", doubled);

    let high_scores: Vec<i32> = scores.iter().filter(|s| **s >= 85).copied().collect();
    println!("Scores 85 and above: {:?}", high_scores);
```

`map` transforms each element by passing it to a closure and producing the closure's result. `|s| s * 2` doubles each score; arithmetic works directly on references to numbers, so no `*` is needed. Iterators are lazy: `map` alone does not do anything until something consumes the results. `collect()` is the consumer here. It gathers everything the iterator produces into a new collection, and the annotation `Vec<i32>` tells it which kind of collection to build. The original `scores` vector is untouched.

The second line combines `filter` and `collect`. After `filter`, the items are still references (`&i32`), but the target is a `Vec<i32>` of plain numbers. `copied()` turns each `&i32` into an `i32` by copying it, which works for `Copy` types such as numbers.

### Step 3: Number Items with enumerate

Add these lines:

```rust
    for (position, score) in scores.iter().enumerate() {
        println!("#{} -> {score}", position + 1);
    }
```

`enumerate` pairs each item with its position, producing tuples `(index, item)`. The `for` loop destructures each tuple, as `first_word` did with `char_indices` in Lesson 10. Positions start at zero, so the output adds 1 to show human friendly numbers starting at 1. This is the idiomatic replacement for `for i in 0..scores.len()` whenever you need both the position and the value.

### Step 4: Use Variables from the Surrounding Code in a Closure

Add these lines:

```rust
    // Closures can use variables from their surroundings.
    let passing_grade = 80;
    let is_passing = |score: &i32| *score >= passing_grade;
    let passing_count = scores.iter().filter(|s| is_passing(s)).count();
    println!("Passing with grade {passing_grade}: {passing_count}");
```

Closures can be stored in variables and called like functions. `is_passing` is a closure that takes a `&i32` (here the parameter type is written out, which is optional when Rust can infer it). Its body uses `passing_grade`, a variable that is not a parameter but comes from the surrounding code. This is called capturing, and it is the key difference between closures and regular `fn` functions, which cannot see the local variables of the function that calls them. Change `passing_grade` to 90 and the closure follows automatically.

Inside `filter`, the closure `|s| is_passing(s)` calls the stored closure. `s` is a `&&i32`, and Rust automatically removes the extra reference layer when passing it to a parameter that expects `&i32`.

### Step 5: Chain Several Steps

Add the final lines and close `main`:

```rust
    // A chain: keep even numbers, square them, add them up.
    let numbers = vec![1, 2, 3, 4, 5, 6];
    let result: i32 = numbers.iter().filter(|n| *n % 2 == 0).map(|n| n * n).sum();
    println!("Sum of squares of even numbers: {result}");
}
```

This one line reads almost like the comment above it. `filter` keeps 2, 4, and 6. `map` squares them into 4, 16, and 36. `sum` adds them up to 56. With a `for` loop, the same logic needs a mutable total, an `if`, and a multiplication spread over several lines. Rust compiles iterator chains into code that is as fast as the hand written loop, so you can choose whichever is clearer.

In the `filter` closure, `*n % 2` uses a single `*`: the `%` operator works on a `&i32` directly, so removing one layer is enough. As a rule of thumb, if the compiler complains about comparing or calculating with references, add or remove a `*` as its message suggests.

---

## 5. Run and Test

Your complete `src/main.rs` should look like this:

```rust
fn main() {
    // Create a vector and add items.
    let mut cart: Vec<String> = Vec::new();
    cart.push(String::from("rice"));
    cart.push(String::from("eggs"));
    cart.push(String::from("milk"));
    println!("Cart: {:?} ({} items)", cart, cart.len());

    // Read items by index and with get.
    println!("First item: {}", cart[0]);
    match cart.get(5) {
        Some(item) => println!("Item 5: {item}"),
        None => println!("There is no item 5."),
    }

    // Remove items.
    let last = cart.pop();
    println!("Removed with pop: {:?}", last);
    let first = cart.remove(0);
    println!("Removed with remove(0): {first}");
    println!("Cart now: {:?}", cart);

    // vec! macro, loops, and changing items.
    let mut scores = vec![72, 88, 95, 64, 81];
    for score in &scores {
        print!("{score} ");
    }
    println!();

    for score in &mut scores {
        *score += 5;
    }
    println!("After bonus: {:?}", scores);

    scores.push(70);
    scores.sort();
    println!("Sorted: {:?}", scores);
    println!("Contains 100? {}", scores.contains(&100));

    // Iterators with closures.
    let total: i32 = scores.iter().sum();
    let passed = scores.iter().filter(|s| **s >= 75).count();
    let highest = scores.iter().max();
    println!("Total: {total}, passed: {passed}, highest: {:?}", highest);

    let doubled: Vec<i32> = scores.iter().map(|s| s * 2).collect();
    println!("Doubled: {:?}", doubled);

    let high_scores: Vec<i32> = scores.iter().filter(|s| **s >= 85).copied().collect();
    println!("Scores 85 and above: {:?}", high_scores);

    for (position, score) in scores.iter().enumerate() {
        println!("#{} -> {score}", position + 1);
    }

    // Closures can use variables from their surroundings.
    let passing_grade = 80;
    let is_passing = |score: &i32| *score >= passing_grade;
    let passing_count = scores.iter().filter(|s| is_passing(s)).count();
    println!("Passing with grade {passing_grade}: {passing_count}");

    // A chain: keep even numbers, square them, add them up.
    let numbers = vec![1, 2, 3, 4, 5, 6];
    let result: i32 = numbers.iter().filter(|n| *n % 2 == 0).map(|n| n * n).sum();
    println!("Sum of squares of even numbers: {result}");
}
```

Run it:

```bash
cargo run -q
```

```text
Cart: ["rice", "eggs", "milk"] (3 items)
First item: rice
There is no item 5.
Removed with pop: Some("milk")
Removed with remove(0): rice
Cart now: ["eggs"]
72 88 95 64 81 
After bonus: [77, 93, 100, 69, 86]
Sorted: [69, 70, 77, 86, 93, 100]
Contains 100? true
Total: 495, passed: 4, highest: Some(100)
Doubled: [138, 140, 154, 172, 186, 200]
Scores 85 and above: [86, 93, 100]
#1 -> 69
#2 -> 70
#3 -> 77
#4 -> 86
#5 -> 93
#6 -> 100
Passing with grade 80: 3
Sum of squares of even numbers: 56
```

Follow the scores through the program. The bonus turned `[72, 88, 95, 64, 81]` into `[77, 93, 100, 69, 86]`. After adding 70 and sorting, the six scores add up to 495. Four of them are at least 75, three are at least 85, and three pass the stricter grade of 80. The doubled list has the same order as the sorted scores, because `map` keeps the order of the elements.

---

## 6. Fix the Errors in Your Code

Vectors combine ownership, borrowing, and runtime lengths, so their errors cover all three.

**Error 1: Changing a vector while looping over it.**

```rust
// Wrong
let mut scores = vec![72, 88, 95];
for score in &scores {
    if *score > 80 {
        scores.push(*score + 10);
    }
}

// Correct
let mut scores = vec![72, 88, 95];
let extra: Vec<i32> = scores.iter().filter(|s| **s > 80).map(|s| s + 10).collect();
for value in extra {
    scores.push(value);
}
```

The wrong version produces ``error[E0502]: cannot borrow `scores` as mutable because it is also borrowed as immutable``, and the compiler explains that ``this for loop borrows `scores` immutably, preventing mutation within its body``. Pushing could move the vector's data to a bigger block of memory while the loop is still reading the old one. The `help` line suggests ``collecting modifications into a separate collection``, which is what the correct version does: it collects the new values first, then pushes them after the loop.

**Error 2: Using a vector after a `for` loop moved it.**

```rust
// Wrong
let cart = vec![String::from("rice"), String::from("eggs")];
for item in cart {
    println!("{item}");
}
println!("Items: {}", cart.len());

// Correct
let cart = vec![String::from("rice"), String::from("eggs")];
for item in &cart {
    println!("{item}");
}
println!("Items: {}", cart.len());
```

The wrong version produces ``error[E0382]: borrow of moved value: `cart` ``, noting that `` `cart` moved due to this implicit call to `.into_iter()` ``. A `for` loop over a vector by value takes ownership of it. The `help` suggests the fix: iterate over `&cart` to borrow it instead.

**Error 3: Calling `collect` without saying what to collect into.**

```rust
// Wrong
let doubled = scores.iter().map(|s| s * 2).collect();

// Correct
let doubled: Vec<i32> = scores.iter().map(|s| s * 2).collect();
```

The wrong version produces `error[E0283]: type annotations needed`. `collect` can build many kinds of collections (vectors, strings, hash maps, and more), so it needs to know which one you want. Annotate the variable, as the `help` suggests. `Vec<_>` also works: the underscore asks Rust to infer the element type.

**Error 4: Indexing past the end of a vector.**

```rust
// Wrong
let cart = vec![String::from("rice"), String::from("eggs")];
println!("{}", cart[5]);

// Correct
let cart = vec![String::from("rice"), String::from("eggs")];
match cart.get(5) {
    Some(item) => println!("{item}"),
    None => println!("No item at position 5"),
}
```

The wrong version compiles but panics at runtime with `index out of bounds: the len is 2 but the index is 5`. Unlike with arrays, the compiler cannot see this mistake in advance, because a vector's length is only known while the program runs. Use `get` when an index might be invalid.

---

## 7. Exercises

**Exercise 1:** Create a project called `temperature_log`. Start with a vector of three `f64` temperatures (`31.5, 29.8, 33.1`) and push two more (`30.4` and `34.0`). Print all readings, the average with two decimal places, the lowest and highest values (use a `for` loop over `&temperatures`), and the number of days above 32 degrees (use `filter` and `count`).

**Exercise 2:** Create a project called `inventory`. Define a `Product` struct with `name`, `price`, and `stock`, and store four products in a vector, two of them with a stock of 0. Use iterators to calculate the total stock value (price times stock, summed), to collect the names of out of stock products into a `Vec<&str>`, and to find the most expensive product with `max_by_key(|p| p.price)`, which returns an `Option`.

**Exercise 3:** Create a project called `words`. Given `vec!["rust", "is", "a", "friendly", "compiler", "language"]`, collect an uppercase version of every word into a `Vec<String>`, collect the words longer than four letters into a `Vec<&str>` and print them joined with `", "` (vectors of text have a `join` method), and calculate the total number of letters with `map` and `sum`.

---

## 8. Solutions

**Solution for Exercise 1:**

```rust
fn main() {
    let mut temperatures = vec![31.5, 29.8, 33.1];
    temperatures.push(30.4);
    temperatures.push(34.0);

    let count = temperatures.len();
    let total: f64 = temperatures.iter().sum();
    let hot_days = temperatures.iter().filter(|t| **t > 32.0).count();

    let mut lowest = temperatures[0];
    let mut highest = temperatures[0];
    for t in &temperatures {
        if *t < lowest {
            lowest = *t;
        }
        if *t > highest {
            highest = *t;
        }
    }

    println!("Readings: {:?}", temperatures);
    println!("Average: {:.2}", total / count as f64);
    println!("Lowest: {lowest}, highest: {highest}");
    println!("Days above 32 degrees: {hot_days}");
}
```

`sum` works on floats too, with the annotation `: f64`. The lowest and highest values use a loop because `min` and `max` are not available for `f64`: floats include a special "not a number" value that cannot be ordered, so Rust does not provide a simple maximum for them. The program prints:

```text
Readings: [31.5, 29.8, 33.1, 30.4, 34.0]
Average: 31.76
Lowest: 29.8, highest: 34
Days above 32 degrees: 2
```

**Solution for Exercise 2:**

```rust
struct Product {
    name: String,
    price: u32,
    stock: u32,
}

impl Product {
    fn new(name: &str, price: u32, stock: u32) -> Product {
        Product {
            name: name.to_string(),
            price,
            stock,
        }
    }
}

fn main() {
    let products = vec![
        Product::new("Notebook", 12_500, 40),
        Product::new("Pencil", 2_000, 0),
        Product::new("Backpack", 185_000, 5),
        Product::new("Eraser", 1_500, 0),
    ];

    let stock_value: u32 = products.iter().map(|p| p.price * p.stock).sum();
    println!("Total stock value: Rp{stock_value}");

    let out_of_stock: Vec<&str> = products
        .iter()
        .filter(|p| p.stock == 0)
        .map(|p| p.name.as_str())
        .collect();
    println!("Out of stock: {:?}", out_of_stock);

    if let Some(most_expensive) = products.iter().max_by_key(|p| p.price) {
        println!("Most expensive: {} (Rp{})", most_expensive.name, most_expensive.price);
    }
}
```

Closures can reach into struct fields: `|p| p.price * p.stock` calculates each product's stock value, and `sum` adds them. Long iterator chains are usually written one step per line, as in `out_of_stock`, to keep them readable. `p.name.as_str()` borrows each name as a `&str`, so the new vector holds references into `products` instead of copies. `max_by_key` finds the item with the largest value returned by the closure. The program prints:

```text
Total stock value: Rp1425000
Out of stock: ["Pencil", "Eraser"]
Most expensive: Backpack (Rp185000)
```

**Solution for Exercise 3:**

```rust
fn main() {
    let words = vec!["rust", "is", "a", "friendly", "compiler", "language"];

    let shouted: Vec<String> = words.iter().map(|w| w.to_uppercase()).collect();
    println!("{:?}", shouted);

    let long_words: Vec<&str> = words.iter().filter(|w| w.len() > 4).copied().collect();
    println!("Long words: {}", long_words.join(", "));

    let total_letters: usize = words.iter().map(|w| w.len()).sum();
    println!("Total letters: {total_letters}");
}
```

`to_uppercase` creates a new `String` for each word, so the result is a `Vec<String>`. In the second chain, `filter` keeps words longer than four letters; methods like `len` work through any number of reference layers, so no `*` is needed. `copied` turns each `&&str` into a `&str`, and `join(", ")` combines the words into one `String` with the separator between them. The program prints:

```text
["RUST", "IS", "A", "FRIENDLY", "COMPILER", "LANGUAGE"]
Long words: friendly, compiler, language
Total letters: 31
```

---

## Next Up - Lesson 14

In this lesson you worked with vectors, lists that grow and shrink at runtime. You added, read, and removed elements, looped over them by reference and by mutable reference, sorted and searched them, and processed them with iterator chains built from `map`, `filter`, `sum`, `count`, `max`, `enumerate`, and `collect`, using closures to describe each step.

In Lesson 14, you will look more closely at the text type you have used since Lesson 8, learning the most useful `String` and `&str` methods for searching, splitting, and transforming text, and then meet the hash map: a collection that stores values by key, perfect for counting words or looking up prices by name.
