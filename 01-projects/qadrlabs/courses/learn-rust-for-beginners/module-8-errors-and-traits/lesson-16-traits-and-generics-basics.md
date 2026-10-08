## 1. Before You Begin

You have written `#[derive(Debug)]` above your structs since Lesson 11, imported `std::io::Write` in Lesson 8 just to make `flush` work, and read compiler messages about types that "do not implement the `Copy` trait" or "doesn't implement `Display`." All of these are about traits, the last big building block in this course.

A trait describes behavior that different types can share: "can be summarized," "can be printed with `{}`," "can be compared." Once several types implement the same trait, you can write one function that works with all of them. Generics take that idea further: a generic function is written once with a placeholder type, and works with any type that has the behavior it needs. In this lesson you will define and implement your own trait, use the most important standard traits, and write generic functions with trait bounds.

### What You'll Build

A `traits` program for a small media library. A `Summary` trait gives books and movies a summary and a headline, a `Display` implementation lets books be printed with `{}`, derived traits let books be cloned and compared, and a single generic `largest` function finds the largest number, price, or letter in a list.

### What You'll Learn

- ✅ How to define a trait and implement it for several types
- ✅ How default methods work and how to override them
- ✅ How to accept "any type that implements a trait" as a parameter
- ✅ What `#[derive(Debug, Clone, PartialEq)]` generates for you
- ✅ How to implement `Display` so your type works with `{}` and `format!`
- ✅ How to write generic functions with type parameters and trait bounds
- ✅ How the struct update syntax `..other` fills in remaining fields

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with structs, `impl` blocks, and methods (Lesson 11)
- Comfort with slices and references (Lesson 10)

---

## 2. Define and Implement a Trait

A trait is a list of method signatures that a type promises to provide. Defining a trait says "here is a capability." Implementing it for a type says "this type has that capability, and here is how it works for this type."

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new traits
cd traits
```

These commands create the `traits` project. The file will contain a trait, two structs, several `impl` blocks, three functions, and `main` at the bottom.

### Step 2: Define the Summary Trait

Replace the contents of `src/main.rs` with:

```rust
use std::fmt;

// A trait describes shared behavior.
trait Summary {
    fn summary(&self) -> String;

    fn headline(&self) -> String {
        format!("[NEW] {}", self.summary())
    }
}
```

The `use std::fmt;` line imports the formatting module, which you will need for `Display` in Section 3.

`trait Summary { ... }` defines a trait with two methods. The first, `summary`, ends with a semicolon instead of a body: it is a required method, a signature that every implementing type must fill in. The second, `headline`, has a body: it is a default method. Types get it for free, and they can replace it with their own version if they want. Notice that the default `headline` calls `self.summary()`. A default method can use the required methods, even though it does not know yet which type it will run on.

### Step 3: Implement the Trait for Two Types

Add two structs and implement the trait for each:

```rust
#[derive(Debug, Clone, PartialEq)]
struct Book {
    title: String,
    author: String,
    pages: u32,
}

#[derive(Debug, Clone, PartialEq)]
struct Movie {
    title: String,
    minutes: u32,
}

impl Summary for Book {
    fn summary(&self) -> String {
        format!("{} by {}, {} pages", self.title, self.author, self.pages)
    }
}

impl Summary for Movie {
    fn summary(&self) -> String {
        format!("{} ({} minutes)", self.title, self.minutes)
    }

    fn headline(&self) -> String {
        format!("[NOW SHOWING] {}", self.summary())
    }
}
```

The structs derive three traits, which Section 3 explains. The interesting part is `impl Summary for Book`. This is like the `impl Book` blocks from Lesson 11, but it says "implement the `Summary` trait for `Book`." Inside, `Book` provides the required `summary` method. It does not write `headline`, so it uses the default.

`Movie` implements `summary` differently, because a movie has minutes instead of an author and pages. It also overrides `headline` with its own version. The trait guarantees that both types *have* these methods; each type decides *how* they work.

### Step 4: Call Trait Methods

Add the start of `main`:

```rust
fn main() {
    let book = Book {
        title: String::from("Morning Coffee"),
        author: String::from("Budi Santoso"),
        pages: 96,
    };
    let movie = Movie {
        title: String::from("Rivers of Java"),
        minutes: 112,
    };

    // Trait methods and default methods.
    println!("{}", book.summary());
    println!("{}", book.headline());
    println!("{}", movie.headline());
```

Trait methods are called with dot notation, exactly like regular methods. `book.headline()` runs the default method, which calls `Book`'s `summary`. `movie.headline()` runs `Movie`'s overriding version. The trait must be in scope for its methods to be callable; it is defined in the same file here, so it is. That is also why `flush` needed `use std::io::Write;` in Lesson 8: `flush` is a method of the `Write` trait.

---

## 3. Use the Standard Traits

The standard library defines many traits that the rest of Rust relies on. Implementing them makes your types work with built-in features: `{:?}` needs `Debug`, `{}` needs `Display`, `==` needs `PartialEq`, `.clone()` needs `Clone`. For some of these traits, the compiler can write the implementation for you.

### Step 1: Derive Debug, Clone, and PartialEq

Add these lines to `main`:

```rust
    // Derived traits: Debug, Clone, PartialEq.
    let copy = book.clone();
    println!("{:?}", copy);
    println!("Same book? {}", book == copy);
    let other = Book { pages: 120, ..book.clone() };
    println!("Same as the new edition? {}", book == other);
```

`#[derive(Debug, Clone, PartialEq)]` asks the compiler to generate implementations of three traits based on the struct's fields. `Debug` prints every field, as you have seen since Lesson 11. `Clone` provides `.clone()`, which clones every field to make an independent copy. `PartialEq` provides `==` and `!=`, which compare every field. Deriving works only when every field's type implements the trait too, which is true for `String` and `u32`.

`book == copy` is `true`, because every field matches. The next line uses the struct update syntax: `Book { pages: 120, ..book.clone() }` creates a new `Book` with `pages` set to 120 and every other field taken from `book.clone()`. The clone is needed because the update syntax moves the remaining fields, and without it the `String`s would be moved out of `book`. The new edition has different pages, so the comparison is `false`.

### Step 2: Implement Display by Hand

`Debug` output is meant for programmers. To print a type for users with plain `{}`, you implement `Display` yourself, because only you know how your type should look. Add this block below the `impl Summary for Movie` block:

```rust
impl fmt::Display for Book {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "\"{}\" ({})", self.title, self.author)
    }
}
```

`impl fmt::Display for Book` implements the standard `Display` trait, which lives in the `fmt` module you imported. The trait has one required method, `fmt`, and its signature must match the trait exactly. `f` is a formatter, the destination the text is written to, and `fmt::Result` is a `Result` type that reports whether writing succeeded.

`write!` works like `format!`, but writes into `f` instead of creating a `String`, and it returns the `fmt::Result`, which becomes the method's return value. `\"` is an escaped double quote, so the title is printed inside quotes. Now add these lines to `main`:

```rust
    // Display: our type works with {}.
    println!("Display: {book}");
    let line = format!("Reading {book} today");
    println!("{line}");
```

Once `Display` is implemented, `Book` works anywhere `{}` does: in `println!`, inline placeholders, and `format!`. Implementing `Display` also gives you a `to_string()` method for free.

---

## 4. Accept Any Type That Implements a Trait

The real power of traits shows up in function parameters. Instead of writing `announce_book` and `announce_movie`, you can write one `announce` function that accepts *anything* that implements `Summary`.

### Step 1: Use impl Trait in a Parameter

Add these two functions below the `impl fmt::Display for Book` block:

```rust
// Functions that accept any type with the Summary trait.
fn announce(item: &impl Summary) {
    println!("{}", item.headline());
}

fn print_all<T: Summary>(items: &[T]) {
    for item in items {
        println!("- {}", item.summary());
    }
}
```

The parameter type `&impl Summary` means "a reference to some type that implements `Summary`." Inside the function, you can call any `Summary` method on `item`, and nothing else, because that is all the function knows about it. When you call `announce(&book)`, Rust uses `Book`'s methods; for `announce(&movie)`, it uses `Movie`'s.

`print_all` shows the longer form of the same idea. `<T: Summary>` after the function name declares a type parameter named `T` with a trait bound: `T` can be any type, as long as it implements `Summary`. The parameter `&[T]` is then a slice of that type. The longer form is needed here because the type appears inside another type (a slice), and it guarantees that all items in the slice are the *same* type. Add these lines to `main`:

```rust
    // Trait as a parameter.
    announce(&book);
    announce(&movie);

    let movies = vec![
        Movie { title: String::from("Small Steps"), minutes: 95 },
        Movie { title: String::from("Coding at Dawn"), minutes: 128 },
    ];
    print_all(&movies);
```

The same `announce` function handles a `Book` and a `Movie`. `print_all(&movies)` passes a vector of movies as a slice, so `T` is `Movie` for this call. If you tried to pass a type that does not implement `Summary`, the compiler would reject the call (see Section 6).

---

## 5. Write Generic Functions

In Lesson 10 you wrote `largest(numbers: &[i32])`, which only works for `i32`. Finding the largest `f64` or `char` would need two more copies of the same function. Generics let you write it once.

### Step 1: Write largest with Trait Bounds

Add this function below `print_all`:

```rust
// A generic function with trait bounds.
fn largest<T: PartialOrd + Copy>(values: &[T]) -> T {
    let mut result = values[0];
    for value in values {
        if *value > result {
            result = *value;
        }
    }
    result
}
```

`largest<T: ...>` declares a type parameter `T`, and the function takes a slice of `T` and returns a `T`. The body is the same algorithm as before, but it says nothing about which concrete type `T` is. That is why it needs bounds. To compare values with `>`, the type must implement `PartialOrd`, the trait for ordering. To copy values out of the slice with `values[0]` and `*value`, the type must implement `Copy`. `PartialOrd + Copy` requires both. Numbers and `char` implement both traits, so they all qualify.

### Step 2: Call It with Different Types

Add the last lines and close `main`:

```rust
    // Generics.
    println!("Largest number: {}", largest(&[34, 50, 25, 100, 65]));
    println!("Largest price: {}", largest(&[12.5, 3.75, 18.0]));
    println!("Largest letter: {}", largest(&['r', 'u', 's', 't']));
}
```

The same function is called with an array of integers, an array of floats, and an array of characters. Rust works out `T` from the argument each time and checks that the type meets the bounds. Behind the scenes, the compiler generates a separate, fully optimized copy of `largest` for each type it is used with, so generic code is just as fast as code written for one type. You have been using generic types all along: `Vec<T>`, `Option<T>`, `Result<T, E>`, and `HashMap<K, V>` are all generic.

---

## 6. Run and Test

Your complete `src/main.rs` should look like this:

```rust
use std::fmt;

// A trait describes shared behavior.
trait Summary {
    fn summary(&self) -> String;

    fn headline(&self) -> String {
        format!("[NEW] {}", self.summary())
    }
}

#[derive(Debug, Clone, PartialEq)]
struct Book {
    title: String,
    author: String,
    pages: u32,
}

#[derive(Debug, Clone, PartialEq)]
struct Movie {
    title: String,
    minutes: u32,
}

impl Summary for Book {
    fn summary(&self) -> String {
        format!("{} by {}, {} pages", self.title, self.author, self.pages)
    }
}

impl Summary for Movie {
    fn summary(&self) -> String {
        format!("{} ({} minutes)", self.title, self.minutes)
    }

    fn headline(&self) -> String {
        format!("[NOW SHOWING] {}", self.summary())
    }
}

impl fmt::Display for Book {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "\"{}\" ({})", self.title, self.author)
    }
}

// Functions that accept any type with the Summary trait.
fn announce(item: &impl Summary) {
    println!("{}", item.headline());
}

fn print_all<T: Summary>(items: &[T]) {
    for item in items {
        println!("- {}", item.summary());
    }
}

// A generic function with trait bounds.
fn largest<T: PartialOrd + Copy>(values: &[T]) -> T {
    let mut result = values[0];
    for value in values {
        if *value > result {
            result = *value;
        }
    }
    result
}

fn main() {
    let book = Book {
        title: String::from("Morning Coffee"),
        author: String::from("Budi Santoso"),
        pages: 96,
    };
    let movie = Movie {
        title: String::from("Rivers of Java"),
        minutes: 112,
    };

    // Trait methods and default methods.
    println!("{}", book.summary());
    println!("{}", book.headline());
    println!("{}", movie.headline());

    // Derived traits: Debug, Clone, PartialEq.
    let copy = book.clone();
    println!("{:?}", copy);
    println!("Same book? {}", book == copy);
    let other = Book { pages: 120, ..book.clone() };
    println!("Same as the new edition? {}", book == other);

    // Display: our type works with {}.
    println!("Display: {book}");
    let line = format!("Reading {book} today");
    println!("{line}");

    // Trait as a parameter.
    announce(&book);
    announce(&movie);

    let movies = vec![
        Movie { title: String::from("Small Steps"), minutes: 95 },
        Movie { title: String::from("Coding at Dawn"), minutes: 128 },
    ];
    print_all(&movies);

    // Generics.
    println!("Largest number: {}", largest(&[34, 50, 25, 100, 65]));
    println!("Largest price: {}", largest(&[12.5, 3.75, 18.0]));
    println!("Largest letter: {}", largest(&['r', 'u', 's', 't']));
}
```

Run it:

```bash
cargo run -q
```

```text
Morning Coffee by Budi Santoso, 96 pages
[NEW] Morning Coffee by Budi Santoso, 96 pages
[NOW SHOWING] Rivers of Java (112 minutes)
Book { title: "Morning Coffee", author: "Budi Santoso", pages: 96 }
Same book? true
Same as the new edition? false
Display: "Morning Coffee" (Budi Santoso)
Reading "Morning Coffee" (Budi Santoso) today
[NEW] Morning Coffee by Budi Santoso, 96 pages
[NOW SHOWING] Rivers of Java (112 minutes)
- Small Steps (95 minutes)
- Coding at Dawn (128 minutes)
Largest number: 100
Largest price: 18
Largest letter: u
```

Compare the two headlines: the book used the default `[NEW]` method, and the movie used its own `[NOW SHOWING]` override. The debug line and the display line show the same book in two very different styles. `announce` printed both kinds of media, and `largest` worked for three different types. `'u'` is the largest letter because characters are ordered by their Unicode values, which follow alphabetical order for lowercase English letters.

---

## 7. Fix the Errors in Your Code

Trait errors are about promises: a type promised to implement something and did not, or a function used a capability it never asked for.

**Error 1: Implementing a trait without its required methods.**

```rust
// Wrong
impl Summary for Movie {}

// Correct
impl Summary for Movie {
    fn summary(&self) -> String {
        format!("{} ({} minutes)", self.title, self.minutes)
    }
}
```

The wrong version produces ``error[E0046]: not all trait items implemented, missing: `summary` ``. The compiler points to the required method in the trait definition and to the incomplete `impl` block. Default methods such as `headline` can be left out, but every required method must be written.

**Error 2: Passing a type that does not implement the trait.**

```rust
// Wrong
struct Podcast {
    name: String,
}

announce(&podcast);

// Correct
struct Podcast {
    name: String,
}

impl Summary for Podcast {
    fn summary(&self) -> String {
        format!("Podcast: {}", self.name)
    }
}

announce(&podcast);
```

The wrong version produces ``error[E0277]: the trait bound `Podcast: Summary` is not satisfied``. The `help` sections explain that ``the trait `Summary` is not implemented for `Podcast` `` and show the bound in `announce` that requires it. Implement the trait for the type, and the call works.

**Error 3: A generic function that uses an ability without a bound.**

```rust
// Wrong
fn largest<T>(values: &[T]) -> T {
    let mut result = values[0];
    for value in values {
        if *value > result {
            result = *value;
        }
    }
    result
}

// Correct
fn largest<T: PartialOrd + Copy>(values: &[T]) -> T {
    let mut result = values[0];
    for value in values {
        if *value > result {
            result = *value;
        }
    }
    result
}
```

The wrong version produces ``error[E0369]: binary operation `>` cannot be applied to type `T` ``, with the suggestion ``consider restricting type parameter `T` with trait `PartialOrd` ``. A plain `T` could be any type, including ones that cannot be compared. If you add only `PartialOrd`, the next error is ``error[E0508]: cannot move out of type `[T]`, a non-copy slice``, because copying values out of the slice needs `Copy`. Bounds list exactly the abilities the function uses.

**Error 4: Printing a type with `{}` without implementing `Display`.**

```rust
// Wrong
struct Book {
    title: String,
}

println!("{book}");

// Correct
use std::fmt;

struct Book {
    title: String,
}

impl fmt::Display for Book {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.title)
    }
}

println!("{book}");
```

The wrong version produces ``error[E0277]: `Book` doesn't implement `std::fmt::Display` ``, and the note suggests using `{:?}` instead. `Display` cannot be derived, because there is no single correct way to show a type to users. Implement it by hand, or use `{:?}` with `#[derive(Debug)]` while developing.

---

## 8. Exercises

**Exercise 1:** Create a project called `shape_trait`. Define a `Shape` trait with required methods `area(&self) -> f64` and `name(&self) -> String`, and a default method `describe(&self) -> String` that returns the name and the area with two decimal places. Implement it for a `Circle` (with a `radius`) and a `Square` (with a `side`), and write a function `report(shape: &impl Shape)` that prints the description. Report a circle with radius 1.5 and a square with side 4.0.

**Exercise 2:** Create a project called `temperature_display`. Define a `Temperature` struct with a `celsius: f64` field that derives `Debug`, `Clone`, and `PartialEq`, and implement `Display` so it prints like `24.4°C` (one decimal place). Create a morning temperature of 24.36 and a noon temperature of 31.0, then print both with `{}`, print the morning one with `{:?}`, compare it with a clone and with noon, and build a sentence with `format!`.

**Exercise 3:** Create a project called `generic_tools`. Write a generic `count_matching<T: PartialEq>(items: &[T], target: &T) -> usize` that counts how many items equal the target, and a generic `smallest<T: PartialOrd + Copy>(values: &[T]) -> T`. Use `count_matching` on an array of letter grades and a vector of words, and `smallest` on integers, floats, and the letter grades.

---

## 9. Solutions

**Solution for Exercise 1:**

```rust
trait Shape {
    fn area(&self) -> f64;
    fn name(&self) -> String;

    fn describe(&self) -> String {
        format!("{} with area {:.2}", self.name(), self.area())
    }
}

struct Circle {
    radius: f64,
}

struct Square {
    side: f64,
}

impl Shape for Circle {
    fn area(&self) -> f64 {
        3.14159 * self.radius * self.radius
    }

    fn name(&self) -> String {
        String::from("Circle")
    }
}

impl Shape for Square {
    fn area(&self) -> f64 {
        self.side * self.side
    }

    fn name(&self) -> String {
        format!("Square {}x{}", self.side, self.side)
    }
}

fn report(shape: &impl Shape) {
    println!("{}", shape.describe());
}

fn main() {
    report(&Circle { radius: 1.5 });
    report(&Square { side: 4.0 });
}
```

The default `describe` method uses both required methods, so each shape only implements the parts that differ. `report` works with any `Shape`, and `main` passes references to shapes created directly in the call. Compare this with the `Shape` enum from Lesson 12: an enum is a closed list of variants defined in one place, while a trait is open, so anyone can add a new shape type later by implementing the trait. The program prints:

```text
Circle with area 7.07
Square 4x4 with area 16.00
```

**Solution for Exercise 2:**

```rust
use std::fmt;

#[derive(Debug, Clone, PartialEq)]
struct Temperature {
    celsius: f64,
}

impl fmt::Display for Temperature {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{:.1}°C", self.celsius)
    }
}

fn main() {
    let morning = Temperature { celsius: 24.36 };
    let noon = Temperature { celsius: 31.0 };
    let copy = morning.clone();

    println!("Morning: {morning}, noon: {noon}");
    println!("Debug: {:?}", morning);
    println!("Morning equals its copy? {}", morning == copy);
    println!("Morning equals noon? {}", morning == noon);
    let report = format!("Today ranges from {morning} to {noon}.");
    println!("{report}");
}
```

Inside `write!`, all the formatting options from Lesson 3 are available, so `{:.1}` rounds to one decimal place. The `°` symbol is an ordinary Unicode character in the string. The derived `Debug` shows the exact stored value, while `Display` shows the rounded, user friendly one. The program prints:

```text
Morning: 24.4°C, noon: 31.0°C
Debug: Temperature { celsius: 24.36 }
Morning equals its copy? true
Morning equals noon? false
Today ranges from 24.4°C to 31.0°C.
```

**Solution for Exercise 3:**

```rust
fn count_matching<T: PartialEq>(items: &[T], target: &T) -> usize {
    let mut count = 0;
    for item in items {
        if item == target {
            count += 1;
        }
    }
    count
}

fn smallest<T: PartialOrd + Copy>(values: &[T]) -> T {
    let mut result = values[0];
    for value in values {
        if *value < result {
            result = *value;
        }
    }
    result
}

fn main() {
    let grades = ['B', 'A', 'C', 'A', 'B', 'A'];
    let words = vec!["tea", "coffee", "tea", "cake"];
    println!("Grade A appears {} times", count_matching(&grades, &'A'));
    println!("'tea' appears {} times", count_matching(&words, &"tea"));

    println!("Smallest number: {}", smallest(&[42, 17, 88, 5]));
    println!("Smallest price: {}", smallest(&[12.5, 3.75, 18.0]));
    println!("Earliest letter: {}", smallest(&grades));
}
```

`count_matching` only compares items, so `PartialEq` is its only bound; it never copies values, so it does not need `Copy`. Both `item` and `target` are references, and `==` compares the values they point to. In the calls, `&'A'` and `&"tea"` pass references to match the `&T` parameter. `smallest` is `largest` with the comparison reversed. The program prints:

```text
Grade A appears 3 times
'tea' appears 2 times
Smallest number: 5
Smallest price: 3.75
Earliest letter: A
```

---

## Next Up - Lesson 17

In this lesson you learned to describe shared behavior with traits. You defined a trait with required and default methods, implemented it for several types, derived `Debug`, `Clone`, and `PartialEq`, implemented `Display` by hand, accepted any implementing type with `&impl Trait`, and wrote generic functions whose trait bounds list exactly the abilities they need.

You now know all the language features this course covers. In Lesson 17, you will start the final module by organizing code into modules spread over several files, reading and writing files with `std::fs`, and writing unit tests that `cargo test` runs for you, the last tools you need before the mini project.
