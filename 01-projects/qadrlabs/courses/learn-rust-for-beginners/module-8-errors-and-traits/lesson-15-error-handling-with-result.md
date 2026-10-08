## 1. Before You Begin

Things go wrong in every real program. Users type `two` where you expected `2`, files are missing, items are not in stock, and lists turn out to be empty. You have already met several ways of dealing with this: `expect` in Lesson 8, `match` on `parse` results, and `Option` with `unwrap_or` in Lesson 12. Each of them was introduced briefly, when it was needed. This lesson puts them together into a complete picture of error handling in Rust.

Rust divides errors into two kinds. Unrecoverable errors are bugs or impossible situations, and the program stops with a panic. Recoverable errors are problems that a program should expect and handle, such as invalid input, and Rust represents them with the `Result` type. You will learn when to use each, write your own functions that return `Result`, and use the `?` operator to pass errors up to the caller without writing a `match` at every step.

### What You'll Build

An `errors` program for a café's order system. It reads order lines such as `"coffee, 2"`, looks up the item's price, validates the quantity, and calculates the total. Every possible problem (an unknown item, a quantity that is not a number, a quantity of zero, a badly formatted line) produces a clear error message instead of a crash.

### What You'll Learn

- ✅ The difference between unrecoverable errors (`panic!`) and recoverable errors (`Result`)
- ✅ How `Result<T, E>` works, with its `Ok` and `Err` variants
- ✅ How to write functions that return `Result` with your own error messages
- ✅ How the `?` operator propagates errors to the caller
- ✅ How to convert one error type into another with `map_err`
- ✅ When `unwrap`, `expect`, and `unwrap_or` are appropriate
- ✅ How to let `main` itself return a `Result`

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with enums, `Option`, and `match` (Lesson 12)
- Comfort with strings, `split`, and `format!` (Lesson 14)

---

## 2. Unrecoverable Errors with panic!

Some situations should never happen if the program is correct. When one does happen, there is no sensible way to continue, and the safest thing is to stop immediately rather than carry on with corrupted data. In Rust, stopping the program this way is called a panic.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new errors
cd errors
```

These commands create the `errors` project. You will start with a short experiment and then replace it with the order program.

### Step 2: Trigger a Panic

Replace the contents of `src/main.rs` with:

```rust
fn main() {
    let scores: Vec<u32> = Vec::new();
    if scores.is_empty() {
        panic!("cannot calculate an average of zero scores");
    }
    println!("This line never runs.");
}
```

The `panic!` macro stops the program and prints the message you give it. Here the vector is empty, so the `if` condition is true and the program panics before reaching the last line. Run it:

```bash
cargo run -q
```

```text

thread 'main' (60386) panicked at src/main.rs:4:9:
cannot calculate an average of zero scores
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

The output says which thread panicked (`main`, followed by a number that will be different on your computer), the file, line, and column of the `panic!`, and your message. The `note` explains how to get a backtrace, a list of the function calls that led to the panic, which helps when debugging larger programs.

You have already seen panics without writing `panic!` yourself: indexing past the end of a vector, integer overflow in debug builds, and calling `unwrap` on `None` all panic. A panic is the right response to a bug. It is the wrong response to something users will do every day, like mistyping a number. For those situations, you need recoverable errors.

---

## 3. Recoverable Errors with Result

A function that might fail in a normal, expected way returns a `Result`. Like `Option`, it is an enum from the standard library, always available without an import:

```rust
enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

You do not write this definition yourself. `Ok(T)` holds the successful value of type `T`. `Err(E)` holds an error value of type `E` that describes what went wrong. Compared with `Option`, which only says "there is nothing," `Result` also says *why*. You met `Result` in Lesson 8, when `parse` returned `Ok(number)` or `Err(_)`.

### Step 1: Inspect a Result from the Standard Library

Replace `src/main.rs` with the beginning of the order program. Note the new signature of `main`; it is explained in Section 6, so for now just type it as shown:

```rust
fn main() -> Result<(), String> {
    // A Result from the standard library.
    let good: Result<i32, _> = "42".parse::<i32>();
    let bad: Result<i32, _> = "4x2".parse::<i32>();
    println!("{:?}", good);
    println!("{:?}", bad);

    match "4x2".parse::<i32>() {
        Ok(number) => println!("Parsed {number}"),
        Err(error) => println!("Could not parse: {error}"),
    }
```

`parse::<i32>()` returns a `Result<i32, ParseIntError>`. The type annotations write the error type as `_`, which asks Rust to infer it. Printing both results with `{:?}` shows the two variants: `Ok(42)` for the valid text, and an `Err` containing a `ParseIntError` with the reason `InvalidDigit` for `"4x2"`.

The `match` handles both cases. This time the `Err` arm binds the error value to `error` instead of ignoring it with `_`, and prints it with `{}`. Standard library errors have a human readable message, here `invalid digit found in string`. Debug output (`{:?}`) is for programmers; display output (`{}`) is for users.

---

## 4. Write Functions That Return Result

Your own functions can return `Result` too. That puts the possibility of failure right in the function's signature, so every caller knows to handle it. In this course, the error type will be `String`, a plain error message, which is simple and good enough for small programs.

### Step 1: Validate a Quantity

Add this function below `main` (you will close `main` later):

```rust
fn parse_quantity(text: &str) -> Result<u32, String> {
    let quantity: u32 = match text.trim().parse() {
        Ok(number) => number,
        Err(_) => return Err(format!("'{}' is not a valid quantity", text.trim())),
    };
    if quantity == 0 {
        return Err(String::from("quantity must be at least 1"));
    }
    Ok(quantity)
}
```

The return type `Result<u32, String>` says: on success you get a `u32`, on failure a `String` message. The `match` turns the parse result into a plain number. Its `Ok` arm produces the number, which is stored in `quantity`. Its `Err` arm returns early from the whole function with an error message built by `format!`. Note that the `return` exits `parse_quantity`, not just the `match`.

Parsing is not the only check. A quantity of 0 is a valid number but not a valid order, so the `if` returns another `Err`. Rules like this are called validation, and `Result` gives them a natural home. If every check passes, the tail expression `Ok(quantity)` wraps the value in the success variant. Forgetting the `Ok(...)` wrapper is a common mistake (see Section 8).

### Step 2: Look Up a Price

Add a second function:

```rust
fn find_price(item: &str) -> Result<u32, String> {
    match item {
        "coffee" => Ok(18_000),
        "tea" => Ok(12_000),
        "cake" => Ok(25_000),
        _ => Err(format!("'{item}' is not on the menu")),
    }
}
```

This is the `find_price` function from Lesson 12, rewritten to return `Result` instead of `Option`. With `Option`, the caller only learns that there is no price. With `Result`, the caller also gets a message explaining which item was missing, which can be shown to the user directly.

### Step 3: Call Your Functions

Add these lines to `main`:

```rust
    // Our own functions that return Result.
    match parse_quantity("3") {
        Ok(quantity) => println!("Quantity: {quantity}"),
        Err(message) => println!("Error: {message}"),
    }
    match parse_quantity("0") {
        Ok(quantity) => println!("Quantity: {quantity}"),
        Err(message) => println!("Error: {message}"),
    }
```

Calling a function that returns `Result` looks exactly like calling `parse`: the caller decides what to do in each case with `match`. `"3"` passes every check, while `"0"` parses as a number but fails the validation and produces the message from the `if`.

---

## 5. Propagate Errors with the ? Operator

Real programs build larger operations out of smaller ones that can each fail. Calculating an order total needs a valid line format, a known item, and a valid quantity. Writing a `match` for every step quickly becomes noisy. Very often the right response to an error in a step is simply "stop and give this error to my caller." That is exactly what the `?` operator does.

### Step 1: Combine Fallible Steps

Add this function:

```rust
fn order_total(line: &str) -> Result<u32, String> {
    let parts: Vec<&str> = line.split(',').collect();
    if parts.len() != 2 {
        return Err(String::from("expected the format 'item, quantity'"));
    }
    let price = find_price(parts[0].trim())?;
    let quantity = parse_quantity(parts[1])?;
    Ok(price * quantity)
}
```

The line is split at the comma, as in Lesson 14. If there are not exactly two parts, the function returns an error about the format.

`find_price(parts[0].trim())?` is where `?` does its work. Placed after an expression that produces a `Result`, it means: if the result is `Ok(value)`, unwrap it and continue with `value`; if it is `Err(error)`, return `Err(error)` from the current function immediately. So `price` is a plain `u32`, and an unknown item ends `order_total` right here, with the error message produced by `find_price`. The same happens for the quantity. When both steps succeed, `Ok(price * quantity)` returns the total.

Without `?`, each of those two lines would need a five line `match`. `?` keeps the "happy path" readable while still handling every error. It can only be used inside a function that itself returns a `Result` (or an `Option`), because it needs somewhere to return the error to.

### Step 2: Process Several Orders

Add these lines to `main`:

```rust
    // Functions that use ? to pass errors up.
    let orders = ["coffee, 2", "cake, 1", "pizza, 1", "tea, two", "tea"];
    for line in orders {
        match order_total(line) {
            Ok(total) => println!("{line:<12} -> Rp{total}"),
            Err(message) => println!("{line:<12} -> error: {message}"),
        }
    }
```

Each order line goes through `order_total`, and the `match` reports either the total or the error. Notice that the messages come from three different functions: the format check in `order_total`, the menu check in `find_price`, and the quantity check in `parse_quantity`. `?` carried each one up to `main`, where it is displayed.

### Step 3: Convert Errors with map_err

The `?` operator requires that the error type of the expression matches the error type of the function. `parse()` fails with a `ParseIntError`, but `parse_quantity` returns `String` errors, so you cannot simply write `text.trim().parse()?` there (Section 8 shows the compiler's message). The `match` in Section 4 handles this, and there is a shorter alternative: `map_err`.

```rust
let quantity: u32 = text
    .trim()
    .parse()
    .map_err(|_| format!("'{}' is not a valid quantity", text.trim()))?;
```

`map_err` leaves an `Ok` value untouched and transforms an `Err` value with a closure, here replacing the `ParseIntError` with a `String` message. After that, the error types match and `?` works. This version is equivalent to the `match` in `parse_quantity`; you can use whichever you find clearer. The exercises use `map_err`.

---

## 6. Shortcuts and a main That Returns Result

`match` and `?` are the main tools, but `Result` also has the same convenience methods as `Option`. And because `?` needs a function that returns `Result`, Rust lets `main` return one too.

### Step 1: unwrap_or and expect

Add these lines to `main`:

```rust
    // Shortcuts.
    let fallback = order_total("pizza, 1").unwrap_or(0);
    println!("Total with fallback: {fallback}");
    let sure = order_total("tea, 3").expect("a valid order");
    println!("Total with expect: {sure}");
```

`unwrap_or(0)` returns the value inside `Ok`, or the default if the result is an `Err`. The error message is discarded, so use it only when a default really is acceptable.

`expect("...")` returns the value inside `Ok`, and panics with your message (followed by the error) if the result is an `Err`. `unwrap()` does the same with a generic message. Use them only when an error would mean a bug in your own program, such as here, where the input is a fixed, known good value, or in quick experiments. For anything that depends on users, files, or the network, handle the error properly.

### Step 2: Use ? in main

Add the last lines and close `main`:

```rust
    // ? also works in main when main returns Result.
    let grand_total = order_total("coffee, 2")? + order_total("cake, 1")?;
    println!("Grand total: Rp{grand_total}");
    Ok(())
}
```

Now the signature you typed in Section 3 makes sense. `fn main() -> Result<(), String>` declares that `main` returns either `Ok(())` or an error message. `()` is the unit type from Lesson 7, meaning "no meaningful value": when `main` succeeds, there is nothing to return except the fact that it succeeded. Because `main` returns a `Result`, `?` can be used inside it. The final line, `Ok(())`, reports success.

If one of these `?` operators meets an `Err`, `main` returns that error. Rust then prints `Error: ` followed by the error in debug format and exits with a failure status, which other programs and scripts can detect. You will see this in Section 7.

---

## 7. Run and Test

Your complete `src/main.rs` should look like this:

```rust
fn main() -> Result<(), String> {
    // A Result from the standard library.
    let good: Result<i32, _> = "42".parse::<i32>();
    let bad: Result<i32, _> = "4x2".parse::<i32>();
    println!("{:?}", good);
    println!("{:?}", bad);

    match "4x2".parse::<i32>() {
        Ok(number) => println!("Parsed {number}"),
        Err(error) => println!("Could not parse: {error}"),
    }

    // Our own functions that return Result.
    match parse_quantity("3") {
        Ok(quantity) => println!("Quantity: {quantity}"),
        Err(message) => println!("Error: {message}"),
    }
    match parse_quantity("0") {
        Ok(quantity) => println!("Quantity: {quantity}"),
        Err(message) => println!("Error: {message}"),
    }

    // Functions that use ? to pass errors up.
    let orders = ["coffee, 2", "cake, 1", "pizza, 1", "tea, two", "tea"];
    for line in orders {
        match order_total(line) {
            Ok(total) => println!("{line:<12} -> Rp{total}"),
            Err(message) => println!("{line:<12} -> error: {message}"),
        }
    }

    // Shortcuts.
    let fallback = order_total("pizza, 1").unwrap_or(0);
    println!("Total with fallback: {fallback}");
    let sure = order_total("tea, 3").expect("a valid order");
    println!("Total with expect: {sure}");

    // ? also works in main when main returns Result.
    let grand_total = order_total("coffee, 2")? + order_total("cake, 1")?;
    println!("Grand total: Rp{grand_total}");
    Ok(())
}

fn parse_quantity(text: &str) -> Result<u32, String> {
    let quantity: u32 = match text.trim().parse() {
        Ok(number) => number,
        Err(_) => return Err(format!("'{}' is not a valid quantity", text.trim())),
    };
    if quantity == 0 {
        return Err(String::from("quantity must be at least 1"));
    }
    Ok(quantity)
}

fn find_price(item: &str) -> Result<u32, String> {
    match item {
        "coffee" => Ok(18_000),
        "tea" => Ok(12_000),
        "cake" => Ok(25_000),
        _ => Err(format!("'{item}' is not on the menu")),
    }
}

fn order_total(line: &str) -> Result<u32, String> {
    let parts: Vec<&str> = line.split(',').collect();
    if parts.len() != 2 {
        return Err(String::from("expected the format 'item, quantity'"));
    }
    let price = find_price(parts[0].trim())?;
    let quantity = parse_quantity(parts[1])?;
    Ok(price * quantity)
}
```

Run it:

```bash
cargo run -q
```

```text
Ok(42)
Err(ParseIntError { kind: InvalidDigit })
Could not parse: invalid digit found in string
Quantity: 3
Error: quantity must be at least 1
coffee, 2    -> Rp36000
cake, 1      -> Rp25000
pizza, 1     -> error: 'pizza' is not on the menu
tea, two     -> error: 'two' is not a valid quantity
tea          -> error: expected the format 'item, quantity'
Total with fallback: 0
Total with expect: 36000
Grand total: Rp61000
```

Every invalid order produced a specific message, and the program kept going after each one. The fallback total is 0 because pizza is not on the menu, and the grand total adds two valid orders: 36,000 plus 25,000.

Now see what happens when `?` fails inside `main`. Change `order_total("cake, 1")?` to `order_total("cake, zero")?` and run the program again. The output is the same until the grand total line, which is replaced by:

```text
Error: "'zero' is not a valid quantity"
```

`main` returned the error, and Rust printed it with `Error: ` in front. The quotes appear because Rust uses debug formatting for this message. The program also exits with a failure status: run `echo $?` right after `cargo run -q` and Bash prints `1` instead of the `0` that a successful run produces. Change the line back before continuing.

---

## 8. Fix the Errors in Your Code

Error handling errors are, fittingly, among the most instructive messages the Rust compiler produces.

**Error 1: Using `?` in a function that does not return `Result`.**

```rust
// Wrong
fn main() {
    let quantity: u32 = "3".parse()?;
    println!("{quantity}");
}

// Correct
fn main() -> Result<(), String> {
    let quantity: u32 = "3".parse().map_err(|_| String::from("not a number"))?;
    println!("{quantity}");
    Ok(())
}
```

The wrong version produces ``error[E0277]: the `?` operator can only be used in a function that returns `Result` or `Option` ``. `?` needs a place to return the error, and a function returning `()` has none. The fix is to change the function's return type, add `Ok(())` at the end, and make sure the error types match (see Error 2). The compiler suggests `Box<dyn std::error::Error>` as the error type, a flexible type that accepts any standard error; it is a good choice for larger programs, but this course keeps to `String`.

**Error 2: Using `?` when the error types do not match.**

```rust
// Wrong
fn parse_quantity(text: &str) -> Result<u32, String> {
    let quantity: u32 = text.trim().parse()?;
    Ok(quantity)
}

// Correct
fn parse_quantity(text: &str) -> Result<u32, String> {
    let quantity: u32 = text
        .trim()
        .parse()
        .map_err(|_| format!("'{}' is not a valid quantity", text.trim()))?;
    Ok(quantity)
}
```

The wrong version produces ``error[E0277]: `?` couldn't convert the error to `String` ``. The note explains that `?` ``implicitly performs a conversion on the error value using the `From` trait``, and there is no automatic conversion from `ParseIntError` to `String`. `map_err` performs the conversion explicitly and gives you the chance to write a better message at the same time.

**Error 3: Returning a plain value where a `Result` is expected.**

```rust
// Wrong
fn find_price(item: &str) -> Result<u32, String> {
    match item {
        "coffee" => 18_000,
        _ => Err(format!("'{item}' is not on the menu")),
    }
}

// Correct
fn find_price(item: &str) -> Result<u32, String> {
    match item {
        "coffee" => Ok(18_000),
        _ => Err(format!("'{item}' is not on the menu")),
    }
}
```

The wrong version produces `error[E0308]: mismatched types`, with ``expected `Result<u32, String>`, found integer`` and the `help` line ``try wrapping the expression in `Ok` ``. A function returning `Result` must return a `Result` on every path, including the successful ones.

**Error 4: Calling `unwrap` on an error.**

```rust
// Wrong
let price = find_price("pizza").unwrap();

// Correct
let price = match find_price("pizza") {
    Ok(price) => price,
    Err(message) => {
        println!("Error: {message}");
        0
    }
};
```

The wrong version compiles, but at runtime it panics with ``called `Result::unwrap()` on an `Err` value: "'pizza' is not on the menu"``. `unwrap` turns a recoverable error into an unrecoverable one. Handle the `Err` case with `match`, `?`, or `unwrap_or` instead.

---

## 9. Exercises

**Exercise 1:** Create a project called `safe_math`. Write `divide(a: f64, b: f64) -> Result<f64, String>`, which returns an error for division by zero, and `average(values: &[f64]) -> Result<f64, String>`, which returns an error for an empty slice and otherwise uses `divide` to compute the average. Print the results of `divide(10.0, 4.0)` and `divide(1.0, 0.0)` with `{:?}`, then the average of a vector of three scores and of an empty vector.

**Exercise 2:** Create a project called `age_parser`. Write `parse_age(text: &str) -> Result<u8, String>` that trims the text, parses it as a `u8` using `map_err` and `?`, and rejects ages above 120 as unrealistic. Test it with `"19"`, `" 42 "`, `"abc"`, `"-5"`, `"300"`, and `"150"`, printing either the age or the error for each.

**Exercise 3:** Create a project called `date_parser`. Write `parse_date(text: &str) -> Result<(u32, u32, u32), String>` that accepts dates in the form `YYYY-MM-DD` and returns `(year, month, day)`. Write a helper `parse_part(text: &str, name: &str) -> Result<u32, String>` whose error message names the part that failed, use `?` to call it three times, and reject months outside 1 to 12 and days outside 1 to 31. Test it with `"2026-10-07"`, `"2026-13-01"`, `"2026-1O-07"` (with a capital letter O), and `"07/10/2026"`.

---

## 10. Solutions

**Solution for Exercise 1:**

```rust
fn divide(a: f64, b: f64) -> Result<f64, String> {
    if b == 0.0 {
        return Err(String::from("division by zero"));
    }
    Ok(a / b)
}

fn average(values: &[f64]) -> Result<f64, String> {
    if values.is_empty() {
        return Err(String::from("cannot average an empty list"));
    }
    let total: f64 = values.iter().sum();
    divide(total, values.len() as f64)
}

fn main() {
    println!("{:?}", divide(10.0, 4.0));
    println!("{:?}", divide(1.0, 0.0));

    let scores = vec![80.0, 92.5, 67.0];
    let empty: Vec<f64> = Vec::new();
    for list in [&scores, &empty] {
        match average(list) {
            Ok(value) => println!("Average of {:?}: {value:.2}", list),
            Err(message) => println!("Average of {:?}: error: {message}", list),
        }
    }
}
```

`average` ends by returning the result of `divide` directly: both functions have the same return type, so there is nothing to unwrap. (The empty check makes the division by zero impossible, but `divide` would catch it anyway.) The loop goes over an array of two vector references, and each `&Vec<f64>` is accepted where `average` expects a `&[f64]` slice. The program prints:

```text
Ok(2.5)
Err("division by zero")
Average of [80.0, 92.5, 67.0]: 79.83
Average of []: error: cannot average an empty list
```

**Solution for Exercise 2:**

```rust
fn parse_age(text: &str) -> Result<u8, String> {
    let age: u8 = text
        .trim()
        .parse()
        .map_err(|_| format!("'{}' is not a number between 0 and 255", text.trim()))?;
    if age > 120 {
        return Err(format!("{age} is not a realistic age"));
    }
    Ok(age)
}

fn main() {
    for input in ["19", " 42 ", "abc", "-5", "300", "150"] {
        match parse_age(input) {
            Ok(age) => println!("{input:>6} -> age {age}"),
            Err(message) => println!("{input:>6} -> error: {message}"),
        }
    }
}
```

The `u8` type does part of the validation for free: `"-5"` and `"300"` fail to parse because they are outside 0 to 255, so `map_err` turns them into a clear message. `"150"` is a valid `u8` but fails the realism check. `" 42 "` succeeds because of `trim`, while the printed input keeps its spaces. The program prints:

```text
    19 -> age 19
   42  -> age 42
   abc -> error: 'abc' is not a number between 0 and 255
    -5 -> error: '-5' is not a number between 0 and 255
   300 -> error: '300' is not a number between 0 and 255
   150 -> error: 150 is not a realistic age
```

**Solution for Exercise 3:**

```rust
fn parse_part(text: &str, name: &str) -> Result<u32, String> {
    text.parse()
        .map_err(|_| format!("the {name} '{text}' is not a number"))
}

fn parse_date(text: &str) -> Result<(u32, u32, u32), String> {
    let parts: Vec<&str> = text.split('-').collect();
    if parts.len() != 3 {
        return Err(format!("'{text}' is not in the format YYYY-MM-DD"));
    }
    let year = parse_part(parts[0], "year")?;
    let month = parse_part(parts[1], "month")?;
    let day = parse_part(parts[2], "day")?;
    if month < 1 || month > 12 {
        return Err(format!("month {month} does not exist"));
    }
    if day < 1 || day > 31 {
        return Err(format!("day {day} does not exist"));
    }
    Ok((year, month, day))
}

fn main() {
    for input in ["2026-10-07", "2026-13-01", "2026-1O-07", "07/10/2026"] {
        match parse_date(input) {
            Ok((year, month, day)) => println!("{input}: day {day}, month {month}, year {year}"),
            Err(message) => println!("{input}: error: {message}"),
        }
    }
}
```

`parse_part` is a single expression: `parse` returns a `Result<u32, ParseIntError>`, and `map_err` converts it to `Result<u32, String>`, which is exactly the return type, so no `?` or `Ok` is needed. `parse_date` checks the format, parses the three parts with `?`, and then validates the ranges. The `Ok` value is a tuple, which `main` destructures directly in the match pattern. The program prints:

```text
2026-10-07: day 7, month 10, year 2026
2026-13-01: error: month 13 does not exist
2026-1O-07: error: the month '1O' is not a number
07/10/2026: error: '07/10/2026' is not in the format YYYY-MM-DD
```

The third input shows why naming the part matters: a capital O instead of a zero is almost invisible, but the message points straight at the month.

---

## Next Up - Lesson 16

In this lesson you learned Rust's two kinds of errors. Panics stop the program for bugs and impossible situations, while `Result` represents failures that a program should expect and handle. You wrote functions that return `Result` with clear messages, propagated errors with `?`, converted error types with `map_err`, chose between `match`, `unwrap_or`, and `expect`, and made `main` return a `Result`.

In Lesson 16, you will learn traits: Rust's way of describing behavior that many types share, such as "can be displayed" or "can be compared." You will finally see what `#[derive(Debug)]` does, implement the `Display` trait so your own types work with `{}`, and write generic functions that work with any type that has the behavior they need.
