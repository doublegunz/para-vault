## 1. Before You Begin

By the end of Lesson 6, your programs had grown into long `main` functions where everything happens in one place. That works for small examples, but it does not scale. When the same calculation appears in three places, you have to fix a bug three times. When `main` is two hundred lines long, it becomes hard to see what the program actually does. The solution is to split the program into functions: small, named pieces of code that each do one job.

You have been using functions since Lesson 1, because `main` is one. In this lesson you will write your own. You will learn how to define and call functions, pass data into them with parameters, get results back with return values, and understand the difference between statements and expressions, which explains why some lines in Rust end with a semicolon and others do not.

### What You'll Build

A `functions` program for a small store. It prints a header, greets customers by name, prints receipt lines, converts temperatures, calculates totals, turns scores into letter grades, and computes the average, lowest, and highest values of an array. Each job lives in its own function, and `main` simply calls them.

### What You'll Learn

- ✅ How to define a function with `fn` and call it
- ✅ How to pass values to a function with parameters, and why parameter types are required
- ✅ How to return a value with `->` and a tail expression
- ✅ The difference between statements and expressions
- ✅ How to leave a function early with `return`
- ✅ How to return several values at once with a tuple
- ✅ How to pass arrays to functions

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with variables, types, `if`, `match`, and `for` loops (Lessons 3 to 6)

---

## 2. Define and Call Functions

A function is a block of code with a name. You define it once, describing what it does, and then call it by name whenever you need it. Calling a function runs its code, and when it finishes, the program continues right after the call.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new functions
cd functions
```

These commands create the `functions` project. This time `src/main.rs` will contain several functions: `main` at the top and your own functions below it.

### Step 2: Write a Function Without Parameters

Replace the contents of `src/main.rs` with:

```rust
fn main() {
    print_header();
}

fn print_header() {
    println!("=== Functions Demo ===");
}
```

`fn print_header() { ... }` defines a new function. The keyword `fn` starts the definition, `print_header` is the name, the empty parentheses mean it takes no input, and the block in curly braces is the body. Function names use `snake_case`, just like variable names.

Inside `main`, the line `print_header();` calls the function. The parentheses after the name are what make it a call; they are required even when there is nothing inside them. When Rust reaches this line, it jumps into `print_header`, runs its body (printing the header), and then returns to `main`.

Notice that `print_header` is defined *after* `main`, yet `main` can call it. Rust does not care about the order in which functions appear in a file, as long as they are defined somewhere. Putting `main` first is a common convention because it gives readers the big picture before the details.

### Step 3: Add Parameters

A function that always does exactly the same thing is limited. Parameters let the caller pass data in. Update `main` and add two new functions:

```rust
fn main() {
    print_header();

    greet("Dina");
    greet("Raka");

    print_receipt_line("Notebook", 3, 12_500);
    print_receipt_line("Pencil", 5, 2_000);
}

fn print_header() {
    println!("=== Functions Demo ===");
}

fn greet(name: &str) {
    println!("Hello, {name}! Welcome to the store.");
}

fn print_receipt_line(item: &str, quantity: u32, unit_price: u32) {
    println!("{item:<10} {quantity:>3} x Rp{unit_price:<6} = Rp{}", quantity * unit_price);
}
```

`fn greet(name: &str)` declares a function with one parameter called `name`. Inside the parentheses, each parameter has a name, a colon, and a type. `&str` is the type of a text value such as `"Dina"`; you will learn exactly what the `&` means in Module 5, but for now read `&str` as "a piece of text." When `main` calls `greet("Dina")`, the value `"Dina"` is called an argument, and it is assigned to the parameter `name` for that call. The second call passes `"Raka"`, so the same function prints a different greeting.

`print_receipt_line` takes three parameters separated by commas. When calling it, the arguments are matched to parameters by position: `"Notebook"` goes to `item`, `3` goes to `quantity`, and `12_500` goes to `unit_price`. The formatting options from Lesson 3 align the receipt into columns.

Unlike `let` variables, function parameters must always have a type annotation. Rust deliberately does not guess parameter types, because a function's signature (its name, parameters, and types) is a contract between the function and everyone who calls it. Writing the types makes that contract clear and lets the compiler check every call.

---

## 3. Return Values from Functions

The functions so far print things. Many functions are more useful when they calculate something and hand the result back to the caller, who can then store it, print it, or use it in another calculation. That result is called the return value.

### Step 1: Return a Value with a Tail Expression

Add these two functions at the bottom of the file:

```rust
fn subtotal(quantity: u32, unit_price: u32) -> u32 {
    quantity * unit_price
}

fn celsius_to_fahrenheit(celsius: f64) -> f64 {
    celsius * 9.0 / 5.0 + 32.0
}
```

The `-> u32` after the parameter list declares the return type: `subtotal` promises to give back a `u32`. The body contains a single line, `quantity * unit_price`, with no semicolon. In Rust, the last expression in a function body, written without a semicolon, is automatically the return value. This is called the tail expression. You already saw the same rule with `if` and `match` blocks in Lesson 5.

`celsius_to_fahrenheit` works the same way with `f64`. The formula multiplies by 9, divides by 5, and adds 32. The literals are written as `9.0`, `5.0`, and `32.0` because they must be floats to combine with the `f64` parameter.

### Step 2: Use the Returned Values

Add these lines at the end of `main`, before its closing brace:

```rust
    let fahrenheit = celsius_to_fahrenheit(30.0);
    println!("30 C is {fahrenheit} F");

    let total = subtotal(3, 12_500) + subtotal(5, 2_000);
    println!("Total: Rp{total}");
```

A call to a function with a return value is itself an expression: it produces a value. `celsius_to_fahrenheit(30.0)` produces `86.0`, which is stored in `fahrenheit`. On the next lines, two calls to `subtotal` are added together directly, without storing them first. Rust runs each call, gets back 37,500 and 10,000, and adds them to get 47,500. Functions with return values can be used anywhere a value of that type is allowed.

### Step 3: Understand Statements and Expressions

The semicolon rule becomes clear once you know the difference between statements and expressions. An expression produces a value: `5`, `a + b`, `subtotal(3, 12_500)`, and `if a > b { a } else { b }` are all expressions. A statement performs an action but does not produce a value: `let x = 5;` is a statement, and adding a semicolon to the end of an expression turns it into a statement that throws its value away.

A block in curly braces is also an expression, and its value is its last expression. Add this to the end of `main` to see it outside a function:

```rust
    let bigger = {
        let a = 7;
        let b = 12;
        if a > b { a } else { b }
    };
    println!("Bigger number: {bigger}");
```

The block contains two `let` statements and ends with an `if` expression without a semicolon. The `if` produces 12, so the whole block produces 12, which is stored in `bigger`. The variables `a` and `b` exist only inside the block. A function body works exactly the same way: it is a block whose final expression becomes the return value. That is why `quantity * unit_price` has no semicolon. If you add one, the function returns nothing instead, and the compiler complains (see Section 6).

---

## 4. Early Returns and Multiple Return Values

Sometimes a function knows its answer before reaching the end, and sometimes it needs to give back more than one value. Rust handles both cases without anything new to install: the `return` keyword and tuples.

### Step 1: Return Early with return

Add a function that converts a score into a letter grade:

```rust
fn letter_grade(score: u32) -> char {
    if score > 100 {
        return '?';
    }
    match score {
        90..=100 => 'A',
        80..=89 => 'B',
        70..=79 => 'C',
        60..=69 => 'D',
        _ => 'E',
    }
}
```

`return '?';` exits the function immediately and gives `'?'` back to the caller. Any code after it is skipped. Here it handles an invalid input up front, which is called a guard: deal with special cases first, then let the main logic handle the normal case. The `match` at the end is the tail expression, so its result is returned for every valid score. You could write `return` before the `match` too, but idiomatic Rust uses `return` only for early exits and lets the tail expression handle the normal return.

Now use it in a loop. Add this to the end of `main`:

```rust
    for score in [95, 83, 71, 40] {
        println!("Score {score}: {}", letter_grade(score));
    }
```

The loop calls `letter_grade` once for each score, and the returned `char` is printed directly. The grading logic is written once and used four times.

### Step 2: Pass an Array and Return a Tuple

Add two functions that work on an array of scores:

```rust
fn average(scores: [i32; 5]) -> f64 {
    let mut total = 0;
    for score in scores {
        total += score;
    }
    total as f64 / scores.len() as f64
}

fn min_max(scores: [i32; 5]) -> (i32, i32) {
    let mut lowest = scores[0];
    let mut highest = scores[0];
    for score in scores {
        if score < lowest {
            lowest = score;
        }
        if score > highest {
            highest = score;
        }
    }
    (lowest, highest)
}
```

Both functions take a parameter of type `[i32; 5]`, an array of exactly five `i32` values, using the array type syntax from Lesson 4. `average` uses the running total pattern from Lesson 6 and returns the division as its tail expression.

A function can only return one value, but that value can be a tuple. `min_max` declares its return type as `(i32, i32)` and ends with the tuple expression `(lowest, highest)`. The caller can destructure it. Add these lines to the end of `main`:

```rust
    let scores = [80, 92, 67, 75, 88];
    let (lowest, highest) = min_max(scores);
    println!("Average: {:.1}, lowest: {lowest}, highest: {highest}", average(scores));
```

`let (lowest, highest) = min_max(scores);` unpacks the two returned values into two variables in one line. The `average(scores)` call is placed directly in the `println!` argument list. The array is passed to both functions; because it contains simple numbers, Rust copies it for each call, so both functions can use it. (Module 5 explains when values are copied and when they are moved.)

---

## 5. Run and Test

Your complete `src/main.rs` should look like this:

```rust
fn main() {
    print_header();

    greet("Dina");
    greet("Raka");

    print_receipt_line("Notebook", 3, 12_500);
    print_receipt_line("Pencil", 5, 2_000);

    let fahrenheit = celsius_to_fahrenheit(30.0);
    println!("30 C is {fahrenheit} F");

    let total = subtotal(3, 12_500) + subtotal(5, 2_000);
    println!("Total: Rp{total}");

    for score in [95, 83, 71, 40] {
        println!("Score {score}: {}", letter_grade(score));
    }

    let scores = [80, 92, 67, 75, 88];
    let (lowest, highest) = min_max(scores);
    println!("Average: {:.1}, lowest: {lowest}, highest: {highest}", average(scores));

    let bigger = {
        let a = 7;
        let b = 12;
        if a > b { a } else { b }
    };
    println!("Bigger number: {bigger}");
}

fn print_header() {
    println!("=== Functions Demo ===");
}

fn greet(name: &str) {
    println!("Hello, {name}! Welcome to the store.");
}

fn print_receipt_line(item: &str, quantity: u32, unit_price: u32) {
    println!("{item:<10} {quantity:>3} x Rp{unit_price:<6} = Rp{}", quantity * unit_price);
}

fn subtotal(quantity: u32, unit_price: u32) -> u32 {
    quantity * unit_price
}

fn celsius_to_fahrenheit(celsius: f64) -> f64 {
    celsius * 9.0 / 5.0 + 32.0
}

fn letter_grade(score: u32) -> char {
    if score > 100 {
        return '?';
    }
    match score {
        90..=100 => 'A',
        80..=89 => 'B',
        70..=79 => 'C',
        60..=69 => 'D',
        _ => 'E',
    }
}

fn average(scores: [i32; 5]) -> f64 {
    let mut total = 0;
    for score in scores {
        total += score;
    }
    total as f64 / scores.len() as f64
}

fn min_max(scores: [i32; 5]) -> (i32, i32) {
    let mut lowest = scores[0];
    let mut highest = scores[0];
    for score in scores {
        if score < lowest {
            lowest = score;
        }
        if score > highest {
            highest = score;
        }
    }
    (lowest, highest)
}
```

Read `main` on its own and notice how it now reads like a summary of the program: print a header, greet two customers, print a receipt, convert a temperature, and so on. The details live in well named functions below. Run it:

```bash
cargo run -q
```

```text
=== Functions Demo ===
Hello, Dina! Welcome to the store.
Hello, Raka! Welcome to the store.
Notebook     3 x Rp12500  = Rp37500
Pencil       5 x Rp2000   = Rp10000
30 C is 86 F
Total: Rp47500
Score 95: A
Score 83: B
Score 71: C
Score 40: E
Average: 80.4, lowest: 67, highest: 92
Bigger number: 12
```

Each line maps to one call in `main`. The same `greet` and `print_receipt_line` functions produced different output for different arguments. `86.0` printed as `86` because it has no fractional part (you saw this with `68.0` in Lesson 4). The letter grades, average, minimum, and maximum all came from return values.

Try calling `letter_grade(150)` in `main` and printing the result to see the early `return` produce `?`.

---

## 6. Fix the Errors in Your Code

Function errors are mostly about signatures: the types and number of parameters, and the return type. The compiler checks every call against the signature.

**Error 1: A semicolon after the tail expression.**

This is the most common function error in Rust. The semicolon turns the return value into a statement, so the function ends up returning nothing.

```rust
// Wrong
fn subtotal(quantity: u32, unit_price: u32) -> u32 {
    quantity * unit_price;
}

// Correct
fn subtotal(quantity: u32, unit_price: u32) -> u32 {
    quantity * unit_price
}
```

The wrong version produces `error[E0308]: mismatched types` with ``expected `u32`, found `()` ``. `()` is the unit type, Rust's way of saying "no value." The compiler explains that the function ``implicitly returns `()` as its body has no tail or `return` expression`` and points at the semicolon with `help: remove this semicolon to return this value`. Follow the help and remove it.

**Error 2: A parameter without a type.**

Every parameter needs a type, even when the answer seems obvious.

```rust
// Wrong
fn greet(name) {
    println!("Hello, {name}!");
}

// Correct
fn greet(name: &str) {
    println!("Hello, {name}!");
}
```

The wrong version produces ``error: expected one of `:`, `@`, or `|`, found `)` ``. The message looks cryptic, but the first `help` line is clear: ``if this is a parameter name, give it a type``. Add a colon and the type after the parameter name.

**Error 3: Calling a function with the wrong number of arguments.**

A call must provide exactly one argument for each parameter.

```rust
// Wrong
fn main() {
    println!("{}", subtotal(3));
}

// Correct
fn main() {
    println!("{}", subtotal(3, 12_500));
}
```

The wrong version produces `error[E0061]: this function takes 2 arguments but 1 argument was supplied`. The compiler marks ``argument #2 of type `u32` is missing``, shows where `subtotal` is defined, and even suggests where to put the missing argument. Check the signature and supply every argument in the right order.

**Error 4: Forgetting the return type.**

Without `->`, a function's return type is `()`, so it cannot return a number.

```rust
// Wrong
fn add(a: i32, b: i32) {
    a + b
}

// Correct
fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

When `main` stores and prints the result of the wrong version, the compiler reports two errors. ``error[E0308]: mismatched types`` says ``expected `()`, found `i32` `` inside `add`, with ``help: try adding a return type: `-> i32` ``. A second error, ``error[E0277]: `()` doesn't implement `std::fmt::Display` ``, appears at the `println!` because the caller received `()`. When you see several errors, fix the first one and compile again; later errors are often consequences of earlier ones.

---

## 7. Exercises

**Exercise 1:** Create a project called `rectangle`. Write two functions, `area` and `perimeter`, that each take a width and a height as `f64` and return an `f64`. Call them from `main` for a rectangle 8.0 wide and 5.5 high, and print the results.

**Exercise 2:** Create a project called `even_counter`. Write a function `is_even(number: i32) -> bool`. Then write a function `count_even` that takes an array of six `i32` values, uses `is_even` inside a loop, and returns how many of them are even. Test it with `[12, 7, 30, 18, 5, 44]`.

**Exercise 3:** Create a project called `math_tools`. Write `power(base: u64, exponent: u32) -> u64` that calculates base raised to the exponent with a loop (without using any built-in power method), and `factorial(n: u64) -> u64` that calculates `1 * 2 * ... * n`. Print `2^10`, `3^4`, `5!`, and `10!`.

---

## 8. Solutions

**Solution for Exercise 1:**

```rust
fn main() {
    let width = 8.0;
    let height = 5.5;
    println!("Rectangle {width} x {height}");
    println!("Area: {}", area(width, height));
    println!("Perimeter: {}", perimeter(width, height));
}

fn area(width: f64, height: f64) -> f64 {
    width * height
}

fn perimeter(width: f64, height: f64) -> f64 {
    2.0 * (width + height)
}
```

Each function has two `f64` parameters and an `f64` return type, and each body is a single tail expression. In `perimeter`, the parentheses make sure the sides are added before multiplying by 2. The parameter names `width` and `height` are the same as the variables in `main`, but they are separate variables: parameters belong to their function. The program prints:

```text
Rectangle 8 x 5.5
Area: 44
Perimeter: 27
```

**Solution for Exercise 2:**

```rust
fn main() {
    let numbers = [12, 7, 30, 18, 5, 44];
    println!("Numbers: {:?}", numbers);
    println!("Even numbers: {}", count_even(numbers));
}

fn is_even(number: i32) -> bool {
    number % 2 == 0
}

fn count_even(numbers: [i32; 6]) -> u32 {
    let mut count = 0;
    for number in numbers {
        if is_even(number) {
            count += 1;
        }
    }
    count
}
```

`is_even` returns the result of a comparison directly; there is no need for `if number % 2 == 0 { true } else { false }`, because the comparison already is a `bool`. `count_even` shows functions calling other functions: it uses `is_even` as its condition. Small functions that answer one question make larger functions easier to read. The program prints:

```text
Numbers: [12, 7, 30, 18, 5, 44]
Even numbers: 4
```

**Solution for Exercise 3:**

```rust
fn main() {
    println!("2^10 = {}", power(2, 10));
    println!("3^4 = {}", power(3, 4));
    println!("5! = {}", factorial(5));
    println!("10! = {}", factorial(10));
}

fn power(base: u64, exponent: u32) -> u64 {
    let mut result = 1;
    for _ in 0..exponent {
        result *= base;
    }
    result
}

fn factorial(n: u64) -> u64 {
    let mut result = 1;
    for i in 1..=n {
        result *= i;
    }
    result
}
```

Both functions use a running product instead of a running total, so `result` starts at 1 (starting at 0 would make every product 0). `power` multiplies by `base` once per unit of the exponent; the loop variable is not needed, so it is `_`. `factorial` multiplies by every number from 1 to `n`. The `u64` return type leaves room for large results; `10!` is already over three million. The program prints:

```text
2^10 = 1024
3^4 = 81
5! = 120
10! = 3628800
```

---

## Next Up - Lesson 8

In this lesson you split programs into functions. You defined functions with `fn`, passed data in through typed parameters, returned values with `->` and tail expressions, left early with `return`, and returned multiple values in a tuple. You also learned that blocks are expressions and that a misplaced semicolon changes what a function returns.

All of your programs so far use values written directly in the source code. In Lesson 8, you will make programs interactive by reading what the user types on the keyboard, cleaning it up, and turning text such as `"42"` into a number your functions can work with.
