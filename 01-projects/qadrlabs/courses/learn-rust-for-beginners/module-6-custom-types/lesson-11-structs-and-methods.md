## 1. Before You Begin

So far, every piece of data in your programs has been a separate variable or a tuple. That works for small examples, but real data comes in bundles. A book has a title, an author, a page count, and a status saying whether it is on the shelf. Keeping those as four loose variables is fragile: nothing ties them together, and a function that works with a book needs four parameters. A tuple groups them, but `book.2` says nothing about what the third value means.

Rust lets you define your own types to solve this. In this lesson you will create a struct (short for structure), a custom type that groups named fields into one value. You will then attach behavior to it with methods, functions that belong to the type, using everything you learned about borrowing in Module 5: methods that read the value take `&self`, and methods that change it take `&mut self`.

### What You'll Build

A small library program built around a `Book` struct. You will create books, read and update their fields, print them for debugging, write methods that summarize a book and estimate reading time, borrow and return a book, and loop over a shelf of books to add up their pages.

### What You'll Learn

- ✅ How to define a struct with named fields
- ✅ How to create instances and read or change their fields
- ✅ How to print a struct with `#[derive(Debug)]` and `{:?}` / `{:#?}`
- ✅ How to add methods in an `impl` block
- ✅ The difference between `&self`, `&mut self`, and associated functions without `self`
- ✅ How to write a constructor function called `new`
- ✅ How to build strings with `format!`
- ✅ How to store structs in an array and loop over them by reference

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- A solid understanding of `String`, references, and borrowing (Lessons 9 and 10)

---

## 2. Define a Struct and Create Instances

A struct definition is a blueprint: it describes what fields a type has and what type each field is. An instance is a concrete value built from that blueprint, with actual data in every field.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new structs
cd structs
```

These commands create the `structs` project. This time the file will have three parts: the struct definition at the top, an `impl` block with its methods, and `main` at the bottom.

### Step 2: Define the Book Struct

Replace the contents of `src/main.rs` with:

```rust
#[derive(Debug)]
struct Book {
    title: String,
    author: String,
    pages: u32,
    available: bool,
}
```

`struct Book` declares a new type named `Book`. Type names use `UpperCamelCase`, where each word starts with a capital letter and there are no underscores, unlike variable and function names. Inside the braces, each line declares a field: a name, a colon, and a type, followed by a comma. A `Book` has four fields: two `String`s for the text, a `u32` for the page count, and a `bool` that says whether the book is on the shelf.

The `title` and `author` fields are `String`, not `&str`. That makes each `Book` the owner of its own text, so a book is self contained and can live as long as needed without borrowing from anything. As a rule of thumb, struct fields should own their data.

`#[derive(Debug)]` is an attribute placed above the struct. It asks the compiler to generate code that lets you print a `Book` with the `{:?}` debug placeholder from Lesson 4. Without it, Rust does not know how to display your type. (Lesson 16 explains what `derive` does in general.)

### Step 3: Create an Instance and Access Its Fields

Add a `main` function below the struct:

```rust
fn main() {
    // Create an instance with struct literal syntax.
    let mut first = Book {
        title: String::from("The Silent Forest"),
        author: String::from("Rina Hartono"),
        pages: 529,
        available: true,
    };
    println!("Title: {}", first.title);
    println!("Pages: {}", first.pages);
    first.pages = 534;
    println!("Pages after the new edition: {}", first.pages);
```

To create an instance, write the struct name followed by braces, and give every field a value with `name: value`. The order of the fields does not matter, but every field must be present. The result is a single value of type `Book`, stored in `first`.

You read a field with dot notation: `first.title` and `first.pages`. You also change a field with dot notation, as in `first.pages = 534;`. This requires the whole instance to be mutable, which is why the variable is declared `let mut first`. Rust does not allow marking only some fields as mutable; mutability belongs to the variable that owns the value.

Do not add the closing brace of `main` yet.

### Step 4: Print the Whole Struct for Debugging

Add these lines:

```rust
    // Debug printing.
    println!("{:?}", first);
    println!("{first:#?}");
```

`{:?}` prints the struct on one line, showing its name and every field. `{:#?}` is the "pretty" version: one field per line with indentation, which is much easier to read for structs with many fields. Both work because of `#[derive(Debug)]`. Debug output is meant for you, the programmer, while you develop and test; for output meant for users, you write your own formatting, as you will do with a method in the next section.

---

## 3. Add Methods with impl

A method is a function that belongs to a type. You define methods inside an `impl` block (short for implementation) for that type, and call them with dot notation on an instance, like `first.summary()`. Methods keep the behavior of a type next to its data, and they read naturally: "book, give me your summary."

### Step 1: Write a Constructor and Read Only Methods

Add this block between the struct definition and `main`:

```rust
impl Book {
    // Associated function: builds a new Book.
    fn new(title: &str, author: &str, pages: u32) -> Book {
        Book {
            title: title.to_string(),
            author: author.to_string(),
            pages,
            available: true,
        }
    }

    // Methods that read the book.
    fn summary(&self) -> String {
        format!("{} by {} ({} pages)", self.title, self.author, self.pages)
    }

    fn is_long(&self) -> bool {
        self.pages > 300
    }

    fn reading_days(&self, pages_per_day: u32) -> u32 {
        (self.pages + pages_per_day - 1) / pages_per_day
    }
```

`impl Book { ... }` opens a block of functions that belong to `Book`. Leave the block open for now; you will add two more methods in the next step and then close it.

`new` has no `self` parameter, which makes it an associated function rather than a method. It belongs to the type, not to an instance, so you call it on the type with `::`, as in `Book::new(...)`. You have already used associated functions: `String::new()` and `String::from(...)`. Rust has no special constructor syntax; by convention, a function named `new` that returns a new instance plays that role. This `new` takes `&str` parameters, which accept text literals, and converts them to owned `String`s with `to_string()`. Every new book starts as available, so callers do not need to pass that value.

Notice `pages,` with no colon. When a variable has the same name as a field, you can write the name once instead of `pages: pages`. This is called field init shorthand.

`summary`, `is_long`, and `reading_days` are methods: their first parameter is `&self`. `self` is the instance the method is called on, and `&self` means the method borrows it immutably, exactly like a `&Book` parameter. Inside the method, `self.title` and `self.pages` read the instance's fields. Because the borrow is immutable, these methods can read the book but not change it.

`summary` uses the `format!` macro. `format!` works exactly like `println!`, with the same placeholders and options, but instead of printing, it returns the formatted text as a new `String`. It is the standard way to build text from several values.

`reading_days` takes an extra parameter after `&self`. It divides the pages by the pages read per day, rounding up so that a partly read last day still counts as a day. Adding `pages_per_day - 1` before the integer division is a common trick for rounding up: 96 pages at 20 per day gives 115 / 20 = 5 days.

### Step 2: Write Methods That Change the Instance

Add two more methods and close the `impl` block:

```rust
    // Methods that change the book.
    fn borrow_book(&mut self) -> bool {
        if self.available {
            self.available = false;
            true
        } else {
            false
        }
    }

    fn return_book(&mut self) {
        self.available = true;
    }
}
```

These methods take `&mut self`: a mutable borrow of the instance, so they can change its fields. `borrow_book` checks whether the book is available. If so, it marks it as borrowed and returns `true` to report success; if the book is already out, it returns `false` and changes nothing. The whole `if` is the tail expression, so its value is the method's return value. `return_book` marks the book as available again.

Choosing between `&self` and `&mut self` follows directly from Lesson 10. Methods that only read should take `&self`, so they can be called on any instance, even through an immutable reference. Methods that modify must take `&mut self`, and can only be called on a mutable instance. A method can also take `self` by value, which moves the instance into the method, but that is needed only rarely.

### Step 3: Call the Associated Function and the Methods

Add these lines to `main`:

```rust
    // Create instances with an associated function.
    let mut second = Book::new("Morning Coffee", "Budi Santoso", 96);
    println!("{}", second.summary());
    println!("Long book? {}", second.is_long());
    println!("Days at 20 pages per day: {}", second.reading_days(20));

    // Methods that change state.
    println!("Borrowed: {}", second.borrow_book());
    println!("Borrowed again: {}", second.borrow_book());
    second.return_book();
    println!("Available after return: {}", second.available);
```

`Book::new(...)` builds a book in one line, compared with the six line struct literal in Section 2. The method calls use dot notation, and you never write `&second` or `&mut second` yourself: Rust borrows the instance automatically, immutably for `&self` methods and mutably for `&mut self` methods. That is why `second` must be declared `mut`, since two of the methods change it.

The first `borrow_book` call succeeds and returns `true`. The second returns `false`, because the book is already borrowed. After `return_book`, the field is `true` again.

---

## 4. Work with Several Instances

A single book is not much of a library. Because `Book` is a type like any other, you can store instances in an array and loop over them, combining structs with what you learned in Lessons 6 and 10.

### Step 1: Loop over a Shelf of Books

Add these lines and close `main`:

```rust
    // Structs in an array.
    let shelf = [
        Book::new("Rivers of Java", "Sari Wulandari", 535),
        Book::new("Small Steps", "Agus Pratama", 320),
        Book::new("Coding at Dawn", "Maya Lestari", 346),
    ];
    let mut total_pages = 0;
    for book in &shelf {
        println!("- {}", book.summary());
        total_pages += book.pages;
    }
    println!("Total pages on the shelf: {total_pages}");
}
```

`shelf` is an array of three `Book` values, each built with `Book::new`. The loop is written `for book in &shelf`, with an `&`. That borrows the array, so each `book` is a `&Book` reference. Without the `&`, the loop would take ownership of the array and move each book out of it, which would make `shelf` unusable after the loop. Borrowing is the right choice whenever the loop only needs to read.

Inside the loop, methods and fields work through the reference exactly as they do on an owned value. `book.pages` is a `u32`, which is `Copy`, so adding it to `total_pages` simply copies the number.

---

## 5. Run and Test

Your complete `src/main.rs` should look like this:

```rust
#[derive(Debug)]
struct Book {
    title: String,
    author: String,
    pages: u32,
    available: bool,
}

impl Book {
    // Associated function: builds a new Book.
    fn new(title: &str, author: &str, pages: u32) -> Book {
        Book {
            title: title.to_string(),
            author: author.to_string(),
            pages,
            available: true,
        }
    }

    // Methods that read the book.
    fn summary(&self) -> String {
        format!("{} by {} ({} pages)", self.title, self.author, self.pages)
    }

    fn is_long(&self) -> bool {
        self.pages > 300
    }

    fn reading_days(&self, pages_per_day: u32) -> u32 {
        (self.pages + pages_per_day - 1) / pages_per_day
    }

    // Methods that change the book.
    fn borrow_book(&mut self) -> bool {
        if self.available {
            self.available = false;
            true
        } else {
            false
        }
    }

    fn return_book(&mut self) {
        self.available = true;
    }
}

fn main() {
    // Create an instance with struct literal syntax.
    let mut first = Book {
        title: String::from("The Silent Forest"),
        author: String::from("Rina Hartono"),
        pages: 529,
        available: true,
    };
    println!("Title: {}", first.title);
    println!("Pages: {}", first.pages);
    first.pages = 534;
    println!("Pages after the new edition: {}", first.pages);

    // Debug printing.
    println!("{:?}", first);
    println!("{first:#?}");

    // Create instances with an associated function.
    let mut second = Book::new("Morning Coffee", "Budi Santoso", 96);
    println!("{}", second.summary());
    println!("Long book? {}", second.is_long());
    println!("Days at 20 pages per day: {}", second.reading_days(20));

    // Methods that change state.
    println!("Borrowed: {}", second.borrow_book());
    println!("Borrowed again: {}", second.borrow_book());
    second.return_book();
    println!("Available after return: {}", second.available);

    // Structs in an array.
    let shelf = [
        Book::new("Rivers of Java", "Sari Wulandari", 535),
        Book::new("Small Steps", "Agus Pratama", 320),
        Book::new("Coding at Dawn", "Maya Lestari", 346),
    ];
    let mut total_pages = 0;
    for book in &shelf {
        println!("- {}", book.summary());
        total_pages += book.pages;
    }
    println!("Total pages on the shelf: {total_pages}");
}
```

Run it:

```bash
cargo run -q
```

```text
Title: The Silent Forest
Pages: 529
Pages after the new edition: 534
Book { title: "The Silent Forest", author: "Rina Hartono", pages: 534, available: true }
Book {
    title: "The Silent Forest",
    author: "Rina Hartono",
    pages: 534,
    available: true,
}
Morning Coffee by Budi Santoso (96 pages)
Long book? false
Days at 20 pages per day: 5
Borrowed: true
Borrowed again: false
Available after return: true
- Rivers of Java by Sari Wulandari (535 pages)
- Small Steps by Agus Pratama (320 pages)
- Coding at Dawn by Maya Lestari (346 pages)
Total pages on the shelf: 1201
```

Compare the two debug lines: `{:?}` fits everything on one line, and `{:#?}` spreads the same data over several lines. The debug output shows text fields in quotes, which makes it clear where each string starts and ends. The summary lines come from `format!` inside `summary`, and the borrowing methods changed `available` as expected.

---

## 6. Fix the Errors in Your Code

Struct errors mostly come from missing fields, missing `self`, and mutability. The compiler's suggestions are especially precise here.

**Error 1: Leaving out a field when creating an instance.**

```rust
// Wrong
let book = Book {
    title: String::from("Morning Coffee"),
    pages: 96,
};

// Correct
let book = Book {
    title: String::from("Morning Coffee"),
    pages: 96,
    available: true,
};
```

(Here `Book` has the fields `title`, `pages`, and `available`.) The wrong version produces ``error[E0063]: missing field `available` in initializer of `Book` ``. Every field must have a value; Rust has no automatic default values for fields. If some fields usually have the same starting value, write a `new` function that fills them in, as `Book::new` does for `available`.

**Error 2: Printing a struct with `{:?}` without deriving `Debug`.**

```rust
// Wrong
struct Book {
    title: String,
    pages: u32,
}

// Correct
#[derive(Debug)]
struct Book {
    title: String,
    pages: u32,
}
```

With the wrong version, `println!("{:?}", book);` produces ``error[E0277]: `Book` doesn't implement `Debug` ``. The `help` section shows the exact fix: ``consider annotating `Book` with `#[derive(Debug)]` ``. Add the attribute directly above the struct.

**Error 3: Changing a field in a method that takes `&self`.**

```rust
// Wrong
impl Book {
    fn return_book(&self) {
        self.available = true;
    }
}

// Correct
impl Book {
    fn return_book(&mut self) {
        self.available = true;
    }
}
```

The wrong version produces ``error[E0594]: cannot assign to `self.available`, which is behind a `&` reference``. `&self` is an immutable borrow, so the method cannot write to any field. Change it to `&mut self`, and make sure the instance you call it on is declared with `let mut`.

**Error 4: Forgetting `self.` inside a method.**

```rust
// Wrong
impl Book {
    fn is_long(&self) -> bool {
        pages > 300
    }
}

// Correct
impl Book {
    fn is_long(&self) -> bool {
        self.pages > 300
    }
}
```

The wrong version produces ``error[E0425]: cannot find value `pages` in this scope``, with the `help` line ``you might have meant to use the available field`` and the fix `self.pages`. Fields are never in scope by their bare names inside a method; you always reach them through `self`.

---

## 7. Exercises

**Exercise 1:** Create a project called `rectangles`. Define a `Rectangle` struct with `width` and `height` fields of type `f64`, deriving `Debug`. Add an associated function `new(width, height)`, a second associated function `square(size)` that creates a rectangle with equal sides, and methods `area`, `perimeter`, and `is_square`. Store an 8.0 by 5.5 rectangle and a 4.0 square in an array and print each one with `{:?}` followed by its three calculated values.

**Exercise 2:** Create a project called `bank`. Define a `BankAccount` struct with an `owner` (`String`) and a `balance` (`u64`). Add `new(owner: &str)`, which starts with a balance of 0, `deposit(&mut self, amount: u64)`, `withdraw(&mut self, amount: u64) -> bool`, which refuses (returns `false`) when the balance is too low, and `report(&self)`, which prints the owner and balance. Deposit Rp500,000, withdraw Rp150,000, try to withdraw Rp1,000,000, and report the balance before and after.

**Exercise 3:** Create a project called `students`. Define a `Student` struct with a `name` and an array of three `u32` scores, plus a `new` function and an `average` method. Create an array of three students, print each student's name and average with one decimal place, and then print the student with the best average. Keep track of the best student with a reference (`&Student`) rather than copying data.

---

## 8. Solutions

**Solution for Exercise 1:**

```rust
#[derive(Debug)]
struct Rectangle {
    width: f64,
    height: f64,
}

impl Rectangle {
    fn new(width: f64, height: f64) -> Rectangle {
        Rectangle { width, height }
    }

    fn square(size: f64) -> Rectangle {
        Rectangle { width: size, height: size }
    }

    fn area(&self) -> f64 {
        self.width * self.height
    }

    fn perimeter(&self) -> f64 {
        2.0 * (self.width + self.height)
    }

    fn is_square(&self) -> bool {
        self.width == self.height
    }
}

fn main() {
    let shapes = [Rectangle::new(8.0, 5.5), Rectangle::square(4.0)];
    for shape in &shapes {
        println!("{:?}", shape);
        println!("  area: {}, perimeter: {}, square: {}", shape.area(), shape.perimeter(), shape.is_square());
    }
}
```

`new` uses field init shorthand for both fields. `square` is a second associated function that shows constructors do not have to be called `new`; it fills both fields with the same value. The three methods only read, so they take `&self`. The program prints:

```text
Rectangle { width: 8.0, height: 5.5 }
  area: 44, perimeter: 27, square: false
Rectangle { width: 4.0, height: 4.0 }
  area: 16, perimeter: 16, square: true
```

Notice that debug formatting shows `8.0` with its decimal point, while `{}` prints `44` without one.

**Solution for Exercise 2:**

```rust
struct BankAccount {
    owner: String,
    balance: u64,
}

impl BankAccount {
    fn new(owner: &str) -> BankAccount {
        BankAccount {
            owner: owner.to_string(),
            balance: 0,
        }
    }

    fn deposit(&mut self, amount: u64) {
        self.balance += amount;
    }

    fn withdraw(&mut self, amount: u64) -> bool {
        if amount > self.balance {
            return false;
        }
        self.balance -= amount;
        true
    }

    fn report(&self) {
        println!("{}: Rp{}", self.owner, self.balance);
    }
}

fn main() {
    let mut account = BankAccount::new("Dina");
    account.deposit(500_000);
    account.report();

    if account.withdraw(150_000) {
        println!("Withdrew Rp150000");
    }
    if !account.withdraw(1_000_000) {
        println!("Withdrawal of Rp1000000 refused: not enough balance");
    }
    account.report();
}
```

`withdraw` uses an early `return` (Lesson 7) as a guard: if the amount is larger than the balance, it refuses before changing anything. This check also protects the `u64` balance, which cannot go below zero; subtracting too much would panic with an overflow. The `bool` return value lets `main` decide what message to show. The program prints:

```text
Dina: Rp500000
Withdrew Rp150000
Withdrawal of Rp1000000 refused: not enough balance
Dina: Rp350000
```

**Solution for Exercise 3:**

```rust
struct Student {
    name: String,
    scores: [u32; 3],
}

impl Student {
    fn new(name: &str, scores: [u32; 3]) -> Student {
        Student {
            name: name.to_string(),
            scores,
        }
    }

    fn average(&self) -> f64 {
        let mut total = 0;
        for score in self.scores {
            total += score;
        }
        total as f64 / self.scores.len() as f64
    }
}

fn main() {
    let students = [
        Student::new("Dina", [85, 90, 78]),
        Student::new("Raka", [92, 88, 95]),
        Student::new("Sari", [70, 82, 76]),
    ];

    let mut best = &students[0];
    for student in &students {
        println!("{:<6} average {:.1}", student.name, student.average());
        if student.average() > best.average() {
            best = student;
        }
    }
    println!("Best average: {} ({:.1})", best.name, best.average());
}
```

A struct field can be an array, and `for score in self.scores` copies the array of `Copy` numbers to loop over it. In `main`, `best` is a mutable variable holding a `&Student` reference: it starts by pointing at the first student, and whenever a better student is found, it is pointed at that student instead. No `Student` is moved or cloned. The program prints:

```text
Dina   average 84.3
Raka   average 91.7
Sari   average 76.0
Best average: Raka (91.7)
```

---

## Next Up - Lesson 12

In this lesson you created your own type. You defined a struct with named fields, created and updated instances, printed them with `#[derive(Debug)]`, wrote a `new` associated function, and added methods that read with `&self` and change with `&mut self`. You also built text with `format!` and looped over an array of structs by reference.

Structs describe data that has several parts at once: a book has a title *and* an author *and* pages. Some data is instead one of several choices: an order is pending *or* shipped *or* delivered. In Lesson 12, you will model choices with enums, meet `Option`, Rust's replacement for "null," and use `match` and `if let` to work with them safely.
