## 1. Before You Begin

Every program you have written so far does exactly the same thing each time it runs, because all of its data is written in the source code. To change the name in a greeting or the score being graded, you had to edit the code and compile again. Real programs get their data from outside: from the keyboard, from files, or from the network. In this lesson you will take the first step and read what the user types in the terminal.

Reading input introduces two new challenges. First, input always arrives as text, even when the user types a number, so you need to convert it. Second, users make mistakes: they type letters where you expect digits, or press Enter too early. You will learn how Rust represents an operation that might fail, how to check whether it succeeded, and how to ask again until the input is valid. Along the way, you will put the functions from Lesson 7 to work by writing reusable input helpers.

### What You'll Build

A `user_input` program that asks for your name and age, then plays a number guessing game: the program has a secret number, you type guesses, and it tells you whether each guess is too small, too big, or correct, counting your tries. Invalid input such as `abc` is handled gracefully instead of crashing the program.

### What You'll Learn

- ✅ How to read a line from the keyboard with `std::io::stdin`
- ✅ What `use` statements do
- ✅ How `String` differs from `&str` at a basic level
- ✅ Why input contains a newline and how `trim` removes it
- ✅ How to convert text into a number with `parse`
- ✅ How to check the `Result` of `parse` with `match`, `Ok`, and `Err`
- ✅ How to write helper functions that keep asking until the input is valid
- ✅ How to show a prompt on the same line with `print!` and `flush`

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with `match`, loops, and functions (Lessons 5 to 7)

---

## 2. Read a Line of Text

Rust's standard library, the collection of code that comes with every Rust installation, includes a module called `std::io` for input and output. You will use one part of it, `stdin` (standard input), which is the stream of text the user types into the terminal.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new user_input
cd user_input
```

These commands create the `user_input` project and move into it.

### Step 2: Read the User's Name

Replace the contents of `src/main.rs` with:

```rust
use std::io;

fn main() {
    println!("What is your name?");

    let mut name = String::new();
    io::stdin()
        .read_line(&mut name)
        .expect("Failed to read line");

    println!("Hello, [{name}]!");
}
```

`use std::io;` brings the `io` module from the standard library into scope, so you can write `io::stdin()` instead of the full path `std::io::stdin()`. `use` statements go at the top of the file, outside any function.

`let mut name = String::new();` creates an empty `String`. A `String` is Rust's growable, owned text type: unlike the fixed text literals (`&str`) you have used so far, a `String` can be created at runtime and filled with content. `String::new()` calls a function named `new` that belongs to the `String` type and returns an empty string. The variable must be `mut` because reading input will change its contents.

The next three lines are one statement split across lines for readability. `io::stdin()` gets a handle to standard input. `.read_line(&mut name)` waits for the user to type a line and press Enter, then appends that text to `name`. The `&mut` part gives `read_line` permission to modify `name` without taking it away from you; you will learn exactly how this works in Lesson 10. `read_line` can fail in rare cases (for example, if the terminal is closed), so it returns a result that has to be dealt with. `.expect("Failed to read line")` says "if this failed, stop the program with this message." For reading from a terminal, that is an acceptable choice.

The square brackets in the final `println!` make the exact contents of `name` visible.

### Step 3: Run It and Find the Hidden Newline

Run the program, type `Dina`, and press Enter:

```bash
cargo run -q
```

```text
What is your name?
Dina
Hello, [Dina
]!
```

The second line is what you typed. The closing bracket ended up on a new line, because `read_line` keeps the Enter key you pressed as a newline character at the end of the string. The string is really `"Dina\n"`, where `\n` is the newline. When you compare or convert input, that invisible character causes problems, so the next step removes it.

---

## 3. Convert Text into Numbers

Input is always text. If the user types `19`, your program receives the string `"19\n"`, not the number 19, and you cannot add 10 to a string. You need to trim the newline and parse the text into a number. Parsing might fail, because the user can type anything, and Rust makes you handle that possibility.

### Step 1: Trim the Input and Ask for an Age

Replace `src/main.rs` with:

```rust
use std::io;

fn main() {
    println!("What is your name?");

    let mut name = String::new();
    io::stdin()
        .read_line(&mut name)
        .expect("Failed to read line");
    let name = name.trim();

    println!("Hello, [{name}]!");

    println!("How old are you?");
    let mut age = String::new();
    io::stdin()
        .read_line(&mut age)
        .expect("Failed to read line");

    match age.trim().parse::<u32>() {
        Ok(age) => println!("In ten years you will be {}.", age + 10),
        Err(_) => println!("That is not a valid age."),
    }
}
```

`let name = name.trim();` uses shadowing from Lesson 3. `trim()` returns the text without whitespace (spaces, tabs, and newlines) at the start and end, and the new `name` variable holds that clean text.

The age is read the same way into a second `String`. Then comes the conversion: `age.trim().parse::<u32>()`. `trim()` removes the newline, and `parse` tries to turn the text into the type written between `::<` and `>`, here a `u32`. That `::<u32>` syntax is nicknamed the turbofish, and it tells `parse` which type you want.

### Step 2: Handle Success and Failure with match

`parse` does not return a plain number. It returns a `Result`, a special type that holds either a success or a failure. A `Result` is always one of two variants:

- `Ok(value)`: the operation succeeded, and `value` is the result, here the parsed number.
- `Err(error)`: the operation failed, and `error` describes what went wrong.

You check which one you got with `match`, exactly as you matched numbers in Lesson 5. The arm `Ok(age) => ...` matches a success and gives the number inside it the name `age`, which shadows the `String` called `age` within that arm. The program can now do arithmetic with it: `age + 10`. The arm `Err(_) => ...` matches a failure; the `_` ignores the error details, because the message to the user is the same whatever the reason. A `Result` has only these two variants, so the `match` is exhaustive without a wildcard arm. (Lesson 15 covers `Result` in depth.)

### Step 3: Test Valid and Invalid Input

Run the program and type `Dina` and `19`:

```text
What is your name?
Dina
Hello, [Dina]!
How old are you?
19
In ten years you will be 29.
```

The brackets now hug the name, because the newline was trimmed. The age was parsed into the number 19, so adding 10 worked. Run it again and type `nineteen` as the age:

```text
What is your name?
Dina
Hello, [Dina]!
How old are you?
nineteen
That is not a valid age.
```

`"nineteen"` is not a sequence of digits, so `parse` returned `Err`, and the second arm ran. The program did not crash; it told the user what went wrong. Try `-5` and `19.5` as well. Both fail, because a `u32` cannot be negative and must be a whole number.

---

## 4. Write Reusable Input Functions

Reading input takes four lines every time, and so far the program only asks once when the input is invalid. Both problems are solved with functions, as you learned in Lesson 7. You will write two helpers: `read_line`, which shows a prompt and returns the trimmed text, and `read_number`, which keeps asking until the user types a valid whole number.

### Step 1: A Helper That Shows a Prompt and Reads a Line

Add this function below `main` (you will rewrite `main` in Section 5):

```rust
fn read_line(prompt: &str) -> String {
    print!("{prompt}");
    io::stdout().flush().expect("Failed to flush stdout");

    let mut input = String::new();
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    input.trim().to_string()
}
```

The function takes the prompt text as a parameter and returns a `String`. It prints the prompt with `print!` instead of `println!`, so the user types on the same line as the question, which looks more natural.

The second line is needed because of how terminals work. Output is collected in a buffer and normally sent to the screen when a newline is printed. `print!` does not print a newline, so the prompt could sit in the buffer, invisible, while the program waits for input. `io::stdout().flush()` forces the buffer to be written immediately. `flush` comes from a trait called `Write`, so you need to import it too; add this line at the top of the file, below `use std::io;`:

```rust
use std::io::Write;
```

A trait is a set of abilities that a type can have; you will learn about traits in Lesson 16. For now, remember that `flush` only works when `std::io::Write` is imported.

The rest reads a line as before. The tail expression `input.trim().to_string()` trims the text and converts the result into a new `String` to return. The conversion is needed because `trim()` returns a view into `input` (a `&str`), and `input` is cleaned up when the function ends, so the function must return its own copy of the text. Module 5 explains the reasoning in detail.

### Step 2: A Helper That Asks Until the Number Is Valid

Add a second helper:

```rust
fn read_number(prompt: &str) -> i32 {
    loop {
        let text = read_line(prompt);
        match text.parse::<i32>() {
            Ok(number) => return number,
            Err(_) => println!("Please type a whole number."),
        }
    }
}
```

`read_number` uses `read_line` to get the text, so all the reading and trimming logic is reused. The `loop` from Lesson 6 repeats forever, and the only way out is `return number` in the `Ok` arm, which exits both the loop and the function with the parsed value. In the `Err` arm, the program prints a hint, the loop starts again, and the prompt is shown once more. The caller never sees invalid input: from its point of view, `read_number` always returns a valid `i32`.

This "ask until valid" loop is one of the most common patterns in interactive programs. The return type `i32` allows negative numbers, which is fine for guesses; the caller can add its own range check.

---

## 5. Build a Number Guessing Game

With the helpers in place, an interactive game takes only a few lines. A real guessing game would pick a random secret number, but random numbers require an external package, and this course uses only the standard library. A constant secret number works just as well for practicing input, comparisons, and loops.

### Step 1: Write main

Replace the `main` function with this version, and add the constant above it:

```rust
const SECRET_NUMBER: i32 = 42;

fn main() {
    // Read text.
    let name = read_line("What is your name? ");
    println!("Nice to meet you, {name}!");

    // Read a number, handling invalid input once.
    let age_text = read_line("How old are you? ");
    match age_text.parse::<u32>() {
        Ok(age) => println!("In ten years you will be {}.", age + 10),
        Err(_) => println!("'{age_text}' is not a valid age."),
    }

    // A tiny guessing game.
    println!();
    println!("I am thinking of a number between 1 and 100.");
    let mut tries = 0;
    loop {
        let guess = read_number("Your guess: ");
        tries += 1;

        if guess < SECRET_NUMBER {
            println!("Too small!");
        } else if guess > SECRET_NUMBER {
            println!("Too big!");
        } else {
            println!("Correct! You needed {tries} tries.");
            break;
        }
    }
}
```

The name and age parts now use `read_line`, so each takes one line instead of five. The age still uses a single `match`, so an invalid age is reported once and the program moves on; the error message includes the text the user typed.

The game is a `loop` that reads a guess with `read_number`, counts it, and compares it with the secret using `if`, `else if`, and `else` from Lesson 5. When the guess is correct, it prints the number of tries and `break` ends the loop. Because `read_number` handles invalid input itself, `abc` never reaches the comparison and never counts as a try.

---

## 6. Run and Test

Your complete `src/main.rs` should look like this:

```rust
use std::io;
use std::io::Write;

const SECRET_NUMBER: i32 = 42;

fn main() {
    // Read text.
    let name = read_line("What is your name? ");
    println!("Nice to meet you, {name}!");

    // Read a number, handling invalid input once.
    let age_text = read_line("How old are you? ");
    match age_text.parse::<u32>() {
        Ok(age) => println!("In ten years you will be {}.", age + 10),
        Err(_) => println!("'{age_text}' is not a valid age."),
    }

    // A tiny guessing game.
    println!();
    println!("I am thinking of a number between 1 and 100.");
    let mut tries = 0;
    loop {
        let guess = read_number("Your guess: ");
        tries += 1;

        if guess < SECRET_NUMBER {
            println!("Too small!");
        } else if guess > SECRET_NUMBER {
            println!("Too big!");
        } else {
            println!("Correct! You needed {tries} tries.");
            break;
        }
    }
}

fn read_line(prompt: &str) -> String {
    print!("{prompt}");
    io::stdout().flush().expect("Failed to flush stdout");

    let mut input = String::new();
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    input.trim().to_string()
}

fn read_number(prompt: &str) -> i32 {
    loop {
        let text = read_line(prompt);
        match text.parse::<i32>() {
            Ok(number) => return number,
            Err(_) => println!("Please type a whole number."),
        }
    }
}
```

Run the program and type the inputs shown after each prompt: `Dina`, `19`, `50`, `abc`, `25`, and `42`:

```bash
cargo run -q
```

```text
What is your name? Dina
Nice to meet you, Dina!
How old are you? 19
In ten years you will be 29.

I am thinking of a number between 1 and 100.
Your guess: 50
Too big!
Your guess: abc
Please type a whole number.
Your guess: 25
Too small!
Your guess: 42
Correct! You needed 3 tries.
```

The prompts and answers share a line thanks to `print!` and `flush`. The invalid guess `abc` was rejected by `read_number` and did not count, so the program reports three tries (50, 25, and 42). Play a few more rounds with different guesses; a smart strategy (always guessing the middle of the remaining range) never needs more than seven tries for numbers from 1 to 100.

---

## 7. Fix the Errors in Your Code

Input code has its own set of classic mistakes. Some are caught by the compiler; one only shows up when the program runs.

**Error 1: Forgetting to trim before parsing.**

The newline from the Enter key makes the text invalid as a number.

```rust
// Wrong
let age: u32 = input.parse().expect("Please type a number");

// Correct
let age: u32 = input.trim().parse().expect("Please type a number");
```

The wrong version compiles, but when you type `19` the program panics with `Please type a number: ParseIntError { kind: InvalidDigit }`. The text was `"19\n"`, and the newline is not a digit. The correct version trims first. Notice also that this example tells `parse` the target type through the variable's annotation (`let age: u32`) instead of the turbofish; both styles work.

**Error 2: Reading into a `String` that is not mutable.**

`read_line` changes the string, so the string must be declared with `mut`.

```rust
// Wrong
let input = String::new();
io::stdin()
    .read_line(&mut input)
    .expect("Failed to read line");

// Correct
let mut input = String::new();
io::stdin()
    .read_line(&mut input)
    .expect("Failed to read line");
```

The wrong version produces ``error[E0596]: cannot borrow `input` as mutable, as it is not declared as mutable``. The word "borrow" refers to the `&mut` you are passing to `read_line`, a concept you will study in Lesson 10. The `help` section shows where to add `mut`.

**Error 3: Parsing without saying which type you want.**

`parse` can produce many different types: `i32`, `u8`, `f64`, and more. If nothing tells it which one, the compiler cannot choose.

```rust
// Wrong
let number = input.trim().parse().expect("Not a number");

// Correct
let number: i32 = input.trim().parse().expect("Not a number");
```

The wrong version produces `error[E0284]: type annotations needed`, and the `help` section suggests ``consider giving `number` an explicit type``. Either annotate the variable as in the correct version or use the turbofish: `parse::<i32>()`.

**Error 4: Forgetting the `use` statement.**

`io` is not available automatically; it has to be imported.

```rust
// Wrong
fn main() {
    let mut input = String::new();
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");
}

// Correct
use std::io;

fn main() {
    let mut input = String::new();
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");
}
```

The wrong version produces ``error[E0433]: cannot find module or crate `io` in this scope``. Among several suggestions, the last `help` gives the right fix: ``consider importing this module`` with `use std::io;`. Ignore the suggestion to run `cargo add io`; that would try to download an unrelated external package. In the same way, if `flush()` reports that no method named `flush` was found, add `use std::io::Write;`.

---

## 8. Exercises

Every solution below needs `use std::io;`, `use std::io::Write;`, and the `read_line` helper from Section 4 copied into the file.

**Exercise 1:** Create a project called `calculator`. Ask the user for a first number, an operator (`+`, `-`, `*`, or `/`), and a second number. Accept decimal numbers by writing a `read_f64` helper that keeps asking until the input is a valid `f64`. Use `match` on the operator to print the result. Refuse to divide by zero and report unknown operators.

**Exercise 2:** Create a project called `temperature`. Ask for a temperature in Celsius, repeating the question until the input is a valid number, and print the temperature in Fahrenheit with one decimal place. This time, do not write a separate number helper; instead, use a `loop` that returns the parsed value with `break value` (Lesson 6).

**Exercise 3:** Create a project called `guessing_game`. Improve the game from this lesson: the player has at most 5 tries, guesses outside 1 to 100 are rejected and do not count, each hint shows how many tries are left, and the game ends with either a success message or `Game over` and the secret number.

---

## 9. Solutions

**Solution for Exercise 1:**

```rust
use std::io;
use std::io::Write;

fn main() {
    let a = read_f64("First number: ");
    let operator = read_line("Operator (+, -, *, /): ");
    let b = read_f64("Second number: ");

    match operator.as_str() {
        "+" => println!("{a} + {b} = {}", a + b),
        "-" => println!("{a} - {b} = {}", a - b),
        "*" => println!("{a} * {b} = {}", a * b),
        "/" => {
            if b == 0.0 {
                println!("Cannot divide by zero.");
            } else {
                println!("{a} / {b} = {}", a / b);
            }
        }
        _ => println!("Unknown operator: {operator}"),
    }
}

fn read_f64(prompt: &str) -> f64 {
    loop {
        match read_line(prompt).parse::<f64>() {
            Ok(number) => return number,
            Err(_) => println!("Please type a number."),
        }
    }
}

fn read_line(prompt: &str) -> String {
    print!("{prompt}");
    io::stdout().flush().expect("Failed to flush stdout");

    let mut input = String::new();
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    input.trim().to_string()
}
```

`read_f64` is `read_number` with `f64` instead of `i32`, and it calls `parse` directly on the value returned by `read_line`. The operator is a `String`, but the patterns `"+"`, `"-"`, and so on are text literals (`&str`). `operator.as_str()` gives a `&str` view of the `String` so the two can be compared in `match`. The `"/"` arm uses a block with an `if` to check for zero before dividing. Two sample runs:

```text
First number: 12.5
Operator (+, -, *, /): *
Second number: 4
12.5 * 4 = 50
```

```text
First number: 10
Operator (+, -, *, /): /
Second number: x
Please type a number.
Second number: 0
Cannot divide by zero.
```

**Solution for Exercise 2:**

```rust
use std::io;
use std::io::Write;

fn main() {
    let celsius = loop {
        let text = read_line("Temperature in Celsius: ");
        match text.parse::<f64>() {
            Ok(value) => break value,
            Err(_) => println!("'{text}' is not a number, try again."),
        }
    };
    let fahrenheit = celsius * 9.0 / 5.0 + 32.0;
    println!("{celsius} C = {fahrenheit:.1} F");
}

fn read_line(prompt: &str) -> String {
    print!("{prompt}");
    io::stdout().flush().expect("Failed to flush stdout");

    let mut input = String::new();
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    input.trim().to_string()
}
```

The `loop` is used as an expression. In the `Ok` arm, `break value` ends the loop and makes `value` the result of the whole `loop`, which is stored in `celsius`. In the `Err` arm, the message includes the text the user typed, and the loop repeats. `{fahrenheit:.1}` rounds the output to one decimal place. A sample run:

```text
Temperature in Celsius: hot
'hot' is not a number, try again.
Temperature in Celsius: 36.6
36.6 C = 97.9 F
```

**Solution for Exercise 3:**

```rust
use std::io;
use std::io::Write;

const SECRET_NUMBER: i32 = 42;
const MAX_TRIES: u32 = 5;

fn main() {
    println!("Guess the number between 1 and 100. You have {MAX_TRIES} tries.");
    let mut tries = 0;
    let mut won = false;

    while tries < MAX_TRIES {
        let guess = read_number("Your guess: ");
        if guess < 1 || guess > 100 {
            println!("Stay between 1 and 100. This try does not count.");
            continue;
        }
        tries += 1;

        if guess < SECRET_NUMBER {
            println!("Too small! {} tries left.", MAX_TRIES - tries);
        } else if guess > SECRET_NUMBER {
            println!("Too big! {} tries left.", MAX_TRIES - tries);
        } else {
            won = true;
            break;
        }
    }

    if won {
        println!("Correct! You needed {tries} tries.");
    } else {
        println!("Game over. The number was {SECRET_NUMBER}.");
    }
}

fn read_number(prompt: &str) -> i32 {
    loop {
        let text = read_line(prompt);
        match text.parse::<i32>() {
            Ok(number) => return number,
            Err(_) => println!("Please type a whole number."),
        }
    }
}

fn read_line(prompt: &str) -> String {
    print!("{prompt}");
    io::stdout().flush().expect("Failed to flush stdout");

    let mut input = String::new();
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    input.trim().to_string()
}
```

The `while` condition limits the game to `MAX_TRIES` counted guesses. The range check runs before `tries += 1`, and `continue` skips straight to the next iteration, so out of range guesses are not counted. The `won` flag remembers *why* the loop ended: through `break` after a correct guess, or because the tries ran out. The final `if` uses it to pick the right message. A sample run where the player loses:

```text
Guess the number between 1 and 100. You have 5 tries.
Your guess: 150
Stay between 1 and 100. This try does not count.
Your guess: 50
Too big! 4 tries left.
Your guess: 30
Too small! 3 tries left.
Your guess: 40
Too small! 2 tries left.
Your guess: 45
Too big! 1 tries left.
Your guess: 41
Too small! 0 tries left.
Game over. The number was 42.
```

The message `1 tries left` is grammatically awkward. As an extra challenge, use an `if` expression to print `try` when only one is left.

---

## Next Up - Lesson 9

In this lesson you made programs interactive. You read lines with `io::stdin().read_line`, removed the trailing newline with `trim`, converted text to numbers with `parse`, and handled the `Ok` and `Err` cases of a `Result` with `match`. You wrote reusable `read_line` and `read_number` helpers and used them to build a guessing game that survives invalid input.

Along the way, you met several things that were explained only briefly: why `String` and `&str` are different types, what `&mut` means, and why `read_line` returns `input.trim().to_string()` instead of `input.trim()`. All of them come from Rust's most distinctive idea: ownership. Lesson 9 opens Module 5 by explaining how Rust decides who owns each value and when memory is cleaned up.
