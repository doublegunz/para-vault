## 1. Before You Begin

In Lesson 11 you modeled data that has several parts at the same time: a book has a title *and* an author *and* a page count. A lot of data has a different shape: it is exactly *one of* several possibilities. An online order is pending, paid, shipped, or delivered, never two at once. A payment is made by cash, by bank transfer, or by e-wallet. A search either finds something or finds nothing.

In many languages, programmers represent such choices with numbers or strings (`status = 2`, `status = "shipped"`), and a typo like `"shiped"` silently becomes a bug. Rust has a dedicated tool: the enum (short for enumeration), a type that lists every possible variant. In this lesson you will define enums, attach data to their variants, and handle every variant safely with `match`. You will also meet `Option`, the enum Rust uses instead of "null" to represent a value that might be missing.

### What You'll Build

An `enums` program for a small online shop. It tracks an order through its status stages, calculates fees for different payment methods, looks up menu prices that might not exist, and finds the first even number in a list, which might not exist either.

### What You'll Learn

- ✅ How to define an enum and create its variants
- ✅ How to add methods to an enum with `impl`
- ✅ How to store data inside enum variants
- ✅ How to extract that data with `match` patterns
- ✅ What `Option`, `Some`, and `None` are, and why Rust has no null
- ✅ How to handle a single case with `if let`
- ✅ How to supply a default with `unwrap_or`, and why `unwrap` can be risky

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with `match` (Lesson 5) and with structs, `impl`, and `&self` (Lesson 11)

---

## 2. Model Choices with an Enum

An enum definition lists every variant a value of that type can be. A value of the enum type is always exactly one of those variants. The compiler knows the complete list, which is what makes enums so safe to work with.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new enums
cd enums
```

These commands create the `enums` project. The file will contain two enums, their `impl` blocks, two helper functions, and `main` at the bottom.

### Step 2: Define the OrderStatus Enum

Replace the contents of `src/main.rs` with:

```rust
#[derive(Debug)]
enum OrderStatus {
    Pending,
    Paid,
    Shipped,
    Delivered,
}
```

`enum OrderStatus` declares a new type, named in `UpperCamelCase` like a struct. Inside the braces are its four variants, also in `UpperCamelCase`, separated by commas. An `OrderStatus` value is always exactly one of `Pending`, `Paid`, `Shipped`, or `Delivered`; there is no fifth possibility and no way to misspell one, because the compiler only accepts these names. `#[derive(Debug)]` lets you print the variant name with `{:?}`, as with structs.

You create a value by naming the enum and the variant, separated by `::`, for example `OrderStatus::Pending`. The variants are namespaced under the enum's name, so a different enum could also have a `Pending` variant without any conflict.

### Step 3: Add Methods to the Enum

Enums can have methods, just like structs. Add this `impl` block below the enum:

```rust
impl OrderStatus {
    fn description(&self) -> &str {
        match self {
            OrderStatus::Pending => "waiting for payment",
            OrderStatus::Paid => "paid, being packed",
            OrderStatus::Shipped => "on the way",
            OrderStatus::Delivered => "delivered",
        }
    }

    fn next(&self) -> OrderStatus {
        match self {
            OrderStatus::Pending => OrderStatus::Paid,
            OrderStatus::Paid => OrderStatus::Shipped,
            OrderStatus::Shipped => OrderStatus::Delivered,
            OrderStatus::Delivered => OrderStatus::Delivered,
        }
    }
}
```

Both methods use `match self`, which compares the current variant against one arm per variant. This is where enums and `match` work together: `match` must be exhaustive (Lesson 5), and since the compiler knows all four variants, it checks that every one is handled. If you add a fifth variant later, such as `Cancelled`, every `match` that forgot it becomes a compile error, so you can never forget to update a part of the program.

`description` returns a text literal for each variant. Its return type is `&str`; the literals live inside the compiled program, so returning them is always valid. `next` returns the following stage of the order as a new `OrderStatus` value. A delivered order stays delivered.

### Step 4: Walk an Order Through Its Stages

Add the start of `main` at the bottom of the file:

```rust
fn main() {
    // A simple enum and its methods.
    let mut status = OrderStatus::Pending;
    println!("Status: {:?} ({})", status, status.description());
    for _ in 0..4 {
        status = status.next();
        println!("Status: {:?} ({})", status, status.description());
    }
```

`status` starts as `OrderStatus::Pending` and is mutable because it is replaced in the loop. Each iteration calls `next` to get the following stage and assigns it back to `status`, then prints the variant name (with `{:?}`) and its description. The loop runs four times, which is one more than needed to reach `Delivered`, to show that `next` keeps a delivered order delivered.

---

## 3. Store Data Inside Variants

The variants of `OrderStatus` carry no extra information. Many choices need some: a bank transfer needs the bank's name, and an e-wallet payment needs the wallet's name. Rust enums allow each variant to hold its own data, and different variants can hold different kinds of data.

### Step 1: Define an Enum with Data

Add this enum below `OrderStatus` (above `impl OrderStatus` or below it; the order of items in a file does not matter):

```rust
enum Payment {
    Cash,
    Transfer { bank: String },
    EWallet(String),
}
```

This enum shows the three shapes a variant can take. `Cash` holds no data. `Transfer { bank: String }` holds named fields in curly braces, just like a struct. `EWallet(String)` holds unnamed values in parentheses, like a tuple. A `Payment` value is one of these three variants together with whatever data that variant carries. Compared with three separate structs, the enum makes it clear that these are alternatives of a single concept.

### Step 2: Extract the Data with match

Add an `impl` block for `Payment`:

```rust
impl Payment {
    fn label(&self) -> String {
        match self {
            Payment::Cash => String::from("cash"),
            Payment::Transfer { bank } => format!("transfer via {bank}"),
            Payment::EWallet(name) => format!("e-wallet {name}"),
        }
    }

    fn fee(&self) -> u32 {
        match self {
            Payment::Cash => 0,
            Payment::Transfer { bank } => {
                if bank == "Bank Kita" {
                    0
                } else {
                    6_500
                }
            }
            Payment::EWallet(_) => 1_000,
        }
    }
}
```

A `match` pattern can do more than recognize a variant: it can also pull the data out of it. In `Payment::Transfer { bank } => ...`, the pattern matches a transfer and binds its `bank` field to a variable named `bank` for use in that arm. In `Payment::EWallet(name) => ...`, the value inside the parentheses is bound to `name`. Because `self` is a reference, these bindings are references too (`&String`), so nothing is moved out of the payment.

`label` builds a user friendly description with `format!` from Lesson 11. `fee` charges nothing for cash, nothing for transfers to the shop's own bank and Rp6,500 for other banks, and Rp1,000 for any e-wallet. In the e-wallet arm, the name is not needed, so the pattern uses `_` to ignore it.

### Step 3: Loop over Different Payments

Add these lines to `main`:

```rust
    // Enum variants that hold data.
    let payments = [
        Payment::Cash,
        Payment::Transfer { bank: String::from("Bank Kita") },
        Payment::Transfer { bank: String::from("Other Bank") },
        Payment::EWallet(String::from("DompetKu")),
    ];
    for payment in &payments {
        println!("Pay by {}: fee Rp{}", payment.label(), payment.fee());
    }
```

You create a variant with data by supplying the data in the same shape as the definition: braces with field names for `Transfer`, parentheses for `EWallet`. All four values have the same type, `Payment`, so they fit in one array even though they carry different data. The loop borrows the array and calls both methods on each payment.

---

## 4. Handle Missing Values with Option

Many operations might not have a result: looking up a price for an item that is not on the menu, finding the first even number in a list of odd numbers, reading a setting that was never set. Many languages use a special value called null for "nothing here," and forgetting to check for null is one of the most common causes of crashes in software. Rust has no null. Instead, it uses an enum from the standard library called `Option`.

### Step 1: Return an Option from a Function

`Option` is defined in the standard library roughly like this:

```rust
enum Option<T> {
    None,
    Some(T),
}
```

You do not write this yourself; it is always available. `Some(T)` holds a value of some type `T`, and `None` holds nothing. The `<T>` means `Option` works with any type: `Option<u32>` is "maybe a `u32`," and `Option<String>` is "maybe a `String`." (You will learn about this kind of type parameter, called generics, in Lesson 16.) `Option`, `Some`, and `None` are so common that you can use them without the `Option::` prefix.

Add two functions above `main`:

```rust
fn find_price(item: &str) -> Option<u32> {
    match item {
        "coffee" => Some(18_000),
        "tea" => Some(12_000),
        "cake" => Some(25_000),
        _ => None,
    }
}

fn first_even(numbers: &[i32]) -> Option<i32> {
    for number in numbers {
        if *number % 2 == 0 {
            return Some(*number);
        }
    }
    None
}
```

`find_price` matches the item name against text patterns. For known items it returns the price wrapped in `Some`; for anything else it returns `None`. The return type `Option<u32>` tells every caller, right in the signature, that a price might be missing. `first_even` uses an early `return` to hand back the first even number it finds, wrapped in `Some`. If the loop finishes without finding one, the tail expression `None` is returned. Compare this with the `days == 0` trick in Lesson 5's Exercise 3, which used a special number to mean "no answer"; `Option` makes that meaning explicit and impossible to confuse with a real value.

### Step 2: Check the Option with match

Add these lines to `main`:

```rust
    // Option: a value that might be missing.
    for item in ["coffee", "cake", "pizza"] {
        match find_price(item) {
            Some(price) => println!("{item}: Rp{price}"),
            None => println!("{item}: not on the menu"),
        }
    }
```

An `Option<u32>` is not a `u32`. You cannot add it, print it as a price, or compare it with a number until you have checked which variant it is. `match` does exactly that: the `Some(price)` arm runs when there is a value and binds it to `price`, and the `None` arm runs when there is not. Because `match` is exhaustive, the compiler forces you to decide what happens in the `None` case. This is how Rust eliminates null related crashes: "I forgot to check" is a compile error, not a runtime surprise.

### Step 3: Handle One Case with if let

Sometimes you only care about one variant. Add these lines:

```rust
    // if let: handle just one case.
    if let Some(price) = find_price("tea") {
        println!("Tea costs Rp{price}");
    }
```

`if let` combines a pattern with an `if`. Read it as "if `find_price("tea")` matches the pattern `Some(price)`, run this block with `price` bound to the value." If the result is `None`, the block is skipped. It is a shorter way to write a `match` with one interesting arm and a `_ => {}` arm that does nothing. You can add an `else` block for the other case if you need one.

### Step 4: Print Options and Supply Defaults

Add the final lines and close `main`:

```rust
    let odd_only = [1, 3, 5];
    let mixed = [7, 9, 10, 12];
    println!("First even in {:?}: {:?}", odd_only, first_even(&odd_only));
    println!("First even in {:?}: {:?}", mixed, first_even(&mixed));

    // unwrap_or: provide a default.
    let pizza_price = find_price("pizza").unwrap_or(0);
    println!("Pizza price with default: {pizza_price}");
}
```

`Option` supports debug printing, so `{:?}` shows `None` or `Some(10)`. This is handy while developing, but not something to show to users.

`unwrap_or(0)` is a method on `Option` that returns the value inside `Some`, or the default you provide if the option is `None`. It is a concise alternative to a `match` when a sensible default exists. There is also `unwrap()`, which returns the value inside `Some` but *panics* (stops the program) on `None`. Avoid `unwrap()` unless you are certain the value exists; Section 6 shows what happens when you are wrong.

---

## 5. Run and Test

Your complete `src/main.rs` should look like this:

```rust
#[derive(Debug)]
enum OrderStatus {
    Pending,
    Paid,
    Shipped,
    Delivered,
}

enum Payment {
    Cash,
    Transfer { bank: String },
    EWallet(String),
}

impl OrderStatus {
    fn description(&self) -> &str {
        match self {
            OrderStatus::Pending => "waiting for payment",
            OrderStatus::Paid => "paid, being packed",
            OrderStatus::Shipped => "on the way",
            OrderStatus::Delivered => "delivered",
        }
    }

    fn next(&self) -> OrderStatus {
        match self {
            OrderStatus::Pending => OrderStatus::Paid,
            OrderStatus::Paid => OrderStatus::Shipped,
            OrderStatus::Shipped => OrderStatus::Delivered,
            OrderStatus::Delivered => OrderStatus::Delivered,
        }
    }
}

impl Payment {
    fn label(&self) -> String {
        match self {
            Payment::Cash => String::from("cash"),
            Payment::Transfer { bank } => format!("transfer via {bank}"),
            Payment::EWallet(name) => format!("e-wallet {name}"),
        }
    }

    fn fee(&self) -> u32 {
        match self {
            Payment::Cash => 0,
            Payment::Transfer { bank } => {
                if bank == "Bank Kita" {
                    0
                } else {
                    6_500
                }
            }
            Payment::EWallet(_) => 1_000,
        }
    }
}

fn find_price(item: &str) -> Option<u32> {
    match item {
        "coffee" => Some(18_000),
        "tea" => Some(12_000),
        "cake" => Some(25_000),
        _ => None,
    }
}

fn first_even(numbers: &[i32]) -> Option<i32> {
    for number in numbers {
        if *number % 2 == 0 {
            return Some(*number);
        }
    }
    None
}

fn main() {
    // A simple enum and its methods.
    let mut status = OrderStatus::Pending;
    println!("Status: {:?} ({})", status, status.description());
    for _ in 0..4 {
        status = status.next();
        println!("Status: {:?} ({})", status, status.description());
    }

    // Enum variants that hold data.
    let payments = [
        Payment::Cash,
        Payment::Transfer { bank: String::from("Bank Kita") },
        Payment::Transfer { bank: String::from("Other Bank") },
        Payment::EWallet(String::from("DompetKu")),
    ];
    for payment in &payments {
        println!("Pay by {}: fee Rp{}", payment.label(), payment.fee());
    }

    // Option: a value that might be missing.
    for item in ["coffee", "cake", "pizza"] {
        match find_price(item) {
            Some(price) => println!("{item}: Rp{price}"),
            None => println!("{item}: not on the menu"),
        }
    }

    // if let: handle just one case.
    if let Some(price) = find_price("tea") {
        println!("Tea costs Rp{price}");
    }

    let odd_only = [1, 3, 5];
    let mixed = [7, 9, 10, 12];
    println!("First even in {:?}: {:?}", odd_only, first_even(&odd_only));
    println!("First even in {:?}: {:?}", mixed, first_even(&mixed));

    // unwrap_or: provide a default.
    let pizza_price = find_price("pizza").unwrap_or(0);
    println!("Pizza price with default: {pizza_price}");
}
```

Run it:

```bash
cargo run -q
```

```text
Status: Pending (waiting for payment)
Status: Paid (paid, being packed)
Status: Shipped (on the way)
Status: Delivered (delivered)
Status: Delivered (delivered)
Pay by cash: fee Rp0
Pay by transfer via Bank Kita: fee Rp0
Pay by transfer via Other Bank: fee Rp6500
Pay by e-wallet DompetKu: fee Rp1000
coffee: Rp18000
cake: Rp25000
pizza: not on the menu
Tea costs Rp12000
First even in [1, 3, 5]: None
First even in [7, 9, 10, 12]: Some(10)
Pizza price with default: 0
```

The order moved through its stages and stayed at `Delivered`. Each payment produced a label and fee from its own data. The menu lookup returned prices for known items and handled pizza without crashing. `first_even` returned `None` for a list of odd numbers and `Some(10)` for the mixed list. `unwrap_or` turned the missing pizza price into the default `0`.

---

## 6. Fix the Errors in Your Code

Enum errors show how much the compiler knows about your types. Most of them are about forgetting a variant or forgetting that an `Option` is not a plain value.

**Error 1: A `match` that misses a variant.**

```rust
// Wrong
fn description(status: &OrderStatus) -> &str {
    match status {
        OrderStatus::Pending => "waiting for payment",
        OrderStatus::Paid => "paid, being packed",
        OrderStatus::Shipped => "on the way",
    }
}

// Correct
fn description(status: &OrderStatus) -> &str {
    match status {
        OrderStatus::Pending => "waiting for payment",
        OrderStatus::Paid => "paid, being packed",
        OrderStatus::Shipped => "on the way",
        OrderStatus::Delivered => "delivered",
    }
}
```

The wrong version produces ``error[E0004]: non-exhaustive patterns: `&OrderStatus::Delivered` not covered``. The compiler even points to the `Delivered` variant in the enum definition and marks it ``not covered``. Prefer adding the missing arm over adding a `_` wildcard: with explicit arms, adding a new variant to the enum later makes the compiler show you every `match` that needs updating.

**Error 2: Using an `Option` as if it were the value inside.**

```rust
// Wrong
let total = find_price("coffee") + 2_000;

// Correct
let total = find_price("coffee").unwrap_or(0) + 2_000;
```

The wrong version produces ``error[E0369]: cannot add `{integer}` to `Option<u32>` ``. An `Option<u32>` might be `None`, and adding 2,000 to nothing has no meaning, so Rust refuses. Get the value out first, with `match`, `if let`, or `unwrap_or`, and decide explicitly what happens when it is missing.

**Error 3: Forgetting the enum name before a variant.**

```rust
// Wrong
let status = Pending;

// Correct
let status = OrderStatus::Pending;
```

The wrong version produces ``error[E0425]: cannot find value `Pending` in this scope``. Variants live inside their enum's namespace, so you write `OrderStatus::Pending`. The compiler suggests importing the variant with a `use` statement, which is possible, but writing the full name is clearer for beginners. (`Some` and `None` are the exception: the standard library imports them for you automatically.)

**Error 4: Calling `unwrap` on `None`.**

```rust
// Wrong
let price = find_price("pizza").unwrap();

// Correct
let price = find_price("pizza").unwrap_or(0);
```

The wrong version compiles, but at runtime the program panics with ``called `Option::unwrap()` on a `None` value``. `unwrap` is a promise that the value exists, and the compiler takes your word for it. Use `match`, `if let`, or `unwrap_or` whenever `None` is a real possibility, which is almost always.

---

## 7. Exercises

**Exercise 1:** Create a project called `traffic_light`. Define a `TrafficLight` enum with `Red`, `Yellow`, and `Green` variants, deriving `Debug`. Add a `duration` method (Red 30 seconds, Green 25, Yellow 3) and a `next` method (Red to Green, Green to Yellow, Yellow to Red). Starting from `Red`, print three steps of the cycle with their durations and the total time of one full cycle.

**Exercise 2:** Create a project called `shapes`. Define a `Shape` enum with three variants: `Circle { radius: f64 }`, `Rectangle { width: f64, height: f64 }`, and `Triangle(f64, f64)` holding a base and a height. Add an `area` method and a `name` method. Store one of each shape in an array, print each name and area with two decimal places, and print the total area.

**Exercise 3:** Create a project called `options`. Write `find_index(names: &[&str], target: &str) -> Option<usize>`, which returns the position of a name in a slice, and `divide(a: f64, b: f64) -> Option<f64>`, which returns `None` when dividing by zero. Search for one name that exists and one that does not, using `match`. Then print a division result with `if let`, and a division by zero with `unwrap_or(0.0)`.

---

## 8. Solutions

**Solution for Exercise 1:**

```rust
#[derive(Debug)]
enum TrafficLight {
    Red,
    Yellow,
    Green,
}

impl TrafficLight {
    fn duration(&self) -> u32 {
        match self {
            TrafficLight::Red => 30,
            TrafficLight::Yellow => 3,
            TrafficLight::Green => 25,
        }
    }

    fn next(&self) -> TrafficLight {
        match self {
            TrafficLight::Red => TrafficLight::Green,
            TrafficLight::Green => TrafficLight::Yellow,
            TrafficLight::Yellow => TrafficLight::Red,
        }
    }
}

fn main() {
    let mut light = TrafficLight::Red;
    let mut total = 0;
    for _ in 0..3 {
        println!("{:?} for {} seconds", light, light.duration());
        total += light.duration();
        light = light.next();
    }
    println!("One full cycle takes {total} seconds.");
}
```

Both methods match every variant, so adding a new light (for example, a flashing yellow) would immediately show which methods need updating. The loop prints the current light, adds its duration to the running total, and moves to the next light. The program prints:

```text
Red for 30 seconds
Green for 25 seconds
Yellow for 3 seconds
One full cycle takes 58 seconds.
```

**Solution for Exercise 2:**

```rust
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Triangle(f64, f64),
}

impl Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle { radius } => 3.14159 * radius * radius,
            Shape::Rectangle { width, height } => width * height,
            Shape::Triangle(base, height) => 0.5 * base * height,
        }
    }

    fn name(&self) -> &str {
        match self {
            Shape::Circle { .. } => "circle",
            Shape::Rectangle { .. } => "rectangle",
            Shape::Triangle(..) => "triangle",
        }
    }
}

fn main() {
    let shapes = [
        Shape::Circle { radius: 2.0 },
        Shape::Rectangle { width: 8.0, height: 5.5 },
        Shape::Triangle(6.0, 4.0),
    ];
    let mut total = 0.0;
    for shape in &shapes {
        println!("{:<10} area {:.2}", shape.name(), shape.area());
        total += shape.area();
    }
    println!("Total area: {total:.2}");
}
```

In `area`, each pattern binds the variant's data: `radius`, `width` and `height`, or `base` and `height`. The bindings are references to `f64`, and Rust's arithmetic operators work directly on references to numbers, so the formulas need no `*`. In `name`, the data is not needed: `{ .. }` ignores all named fields, and `(..)` ignores all tuple values. The program prints:

```text
circle     area 12.57
rectangle  area 44.00
triangle   area 12.00
Total area: 68.57
```

**Solution for Exercise 3:**

```rust
fn find_index(names: &[&str], target: &str) -> Option<usize> {
    for index in 0..names.len() {
        if names[index] == target {
            return Some(index);
        }
    }
    None
}

fn divide(a: f64, b: f64) -> Option<f64> {
    if b == 0.0 {
        None
    } else {
        Some(a / b)
    }
}

fn main() {
    let names = ["Dina", "Raka", "Sari"];
    for target in ["Raka", "Budi"] {
        match find_index(&names, target) {
            Some(index) => println!("{target} is at position {index}"),
            None => println!("{target} is not in the list"),
        }
    }

    if let Some(result) = divide(10.0, 4.0) {
        println!("10 / 4 = {result}");
    }
    let safe = divide(1.0, 0.0).unwrap_or(0.0);
    println!("1 / 0 with a default: {safe}");
}
```

`find_index` takes a slice of `&str`, so it works with an array of names of any length. It loops over the valid positions with an exclusive range and returns `Some(index)` at the first match, or `None` after the loop. `divide` turns the dangerous case, division by zero, into `None` instead of a strange result. The two ways of handling the results show the trade-off: `match` handles both cases explicitly, `if let` handles only the interesting one, and `unwrap_or` supplies a default. The program prints:

```text
Raka is at position 1
Budi is not in the list
10 / 4 = 2.5
1 / 0 with a default: 0
```

---

## Next Up - Lesson 13

In this lesson you modeled choices with enums. You defined variants with and without data, added methods with `impl`, extracted data with `match` patterns, and let the compiler check that every variant is handled. You learned that `Option` replaces null, that `Some` and `None` must be checked before use, and that `if let`, `unwrap_or`, and `unwrap` are different ways to get at the value.

Arrays have a fixed length, which has limited every list in this course so far. In Lesson 13, you will start Module 7 with vectors, lists that can grow and shrink while the program runs, and learn to process them with iterators and closures: short, readable chains like "keep the even numbers, double them, and add them up."
