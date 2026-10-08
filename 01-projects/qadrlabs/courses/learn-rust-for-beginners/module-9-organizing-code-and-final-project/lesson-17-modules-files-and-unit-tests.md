## 1. Before You Begin

Every program in this course so far has lived in a single file, `src/main.rs`, and has worked only with data written in the code or typed by the user. Both limits disappear in real projects. As a program grows, keeping everything in one file makes it hard to find anything, so code is split into modules with clear boundaries. And most useful programs read data from files and save their results, so the data survives after the program ends.

There is a third habit that separates hobby code from reliable code: tests. A test is a small piece of code that calls your functions with known inputs and checks the results automatically. Instead of running the program and reading its output by eye after every change, you run `cargo test` and the computer tells you whether everything still works. This lesson covers all three, which are exactly the tools you need for the mini project in Lesson 18.

### What You'll Build

A `grade_book` program split into two files. A `grades` module parses lines like `Dina,85`, converts scores to letter grades, and calculates the average, with unit tests for each function. `main.rs` reads student scores from `scores.txt`, skips invalid lines with a clear message, prints a report, and saves it to `report.txt`.

### What You'll Learn

- ✅ How to move code into a module in its own file with `mod`
- ✅ How `pub` controls what other modules can use
- ✅ How to bring items into scope with `use`
- ✅ How to read a whole file with `fs::read_to_string` and process it line by line
- ✅ How to write a file with `fs::write`
- ✅ How to write unit tests with `#[test]`, `assert!`, and `assert_eq!`
- ✅ How to run tests with `cargo test` and read a failing test's output
- ✅ How to format code with `cargo fmt` and check it with `cargo clippy`

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with structs, `Option`, and `Result` with `?` and `map_err` (Lessons 11, 12, and 15)
- Comfort with `split`, `lines`, and iterators (Lessons 13 and 14)

---

## 2. Split Code into a Module

A module is a named container for related code: structs, enums, functions, and traits. Modules give code a structure, much like folders give files a structure. In a Cargo project, the simplest way to create a module is to put it in its own file next to `main.rs`.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new grade_book
cd grade_book
```

These commands create the `grade_book` project. This time you will create a second source file, `src/grades.rs`, in addition to `src/main.rs`.

### Step 2: Write the grades Module

Create a new file called `src/grades.rs` and add the following code:

```rust
pub struct Student {
    pub name: String,
    pub score: u32,
}

pub fn parse_line(line: &str) -> Result<Student, String> {
    let parts: Vec<&str> = line.split(',').collect();
    if parts.len() != 2 {
        return Err(format!("'{line}' should look like 'name,score'"));
    }
    let name = parts[0].trim();
    if name.is_empty() {
        return Err(format!("'{line}' has an empty name"));
    }
    let score: u32 = parts[1]
        .trim()
        .parse()
        .map_err(|_| format!("'{}' is not a valid score", parts[1].trim()))?;
    if score > 100 {
        return Err(format!("{score} is above the maximum of 100"));
    }
    Ok(Student {
        name: name.to_string(),
        score,
    })
}

pub fn letter(score: u32) -> char {
    match score {
        90..=100 => 'A',
        80..=89 => 'B',
        70..=79 => 'C',
        60..=69 => 'D',
        _ => 'E',
    }
}

pub fn average(students: &[Student]) -> Option<f64> {
    if students.is_empty() {
        return None;
    }
    let total: u32 = students.iter().map(|s| s.score).sum();
    Some(total as f64 / students.len() as f64)
}
```

Everything in this file uses ideas from earlier lessons. `Student` is a struct (Lesson 11). `parse_line` turns a line such as `Dina,85` into a `Student`, returning a `Result` with a clear message for each kind of invalid line, using `split`, `trim`, `map_err`, and `?` (Lessons 14 and 15). `letter` is the grading `match` from Lesson 5, and `average` returns `None` for an empty list (Lesson 12) and uses an iterator chain (Lesson 13).

The new keyword is `pub`, short for public. Everything in a module is private by default: only code inside the same module can use it. `pub` makes an item visible to the code that uses the module. The struct, its fields, and the three functions are all marked `pub`, because `main.rs` needs all of them. Notice that the fields need their own `pub`: making a struct public does not automatically make its fields public. Privacy by default lets a module hide its internal details and expose only what others should rely on.

### Step 3: Declare and Use the Module in main.rs

Replace the contents of `src/main.rs` with the first lines of the program:

```rust
mod grades;

use std::fs;

use grades::{Student, average, letter, parse_line};
```

`mod grades;` declares a module named `grades`. When Rust sees a `mod` declaration ending in a semicolon, it looks for the module's code in `src/grades.rs`. Without this line, `grades.rs` is just a file on disk that the compiler ignores.

`use std::fs;` brings the standard library's file system module into scope, as `use std::io;` did in Lesson 8. `use grades::{...};` brings four items from your module into scope at once; the curly braces list several items from the same module. After this line, you can write `parse_line(line)` instead of `grades::parse_line(line)`. Both forms work; `use` just saves typing. The rest of `main.rs` follows in Section 3.

---

## 3. Read and Write Files

The `std::fs` module provides simple functions for working with files. Reading and writing can fail for reasons outside your program's control (a missing file, a full disk, missing permissions), so they return `Result`, and you handle them with the tools from Lesson 15.

### Step 1: Create the Input File

In the project's root folder, next to `Cargo.toml` (not inside `src`), create a file named `scores.txt` with this content:

```text
Dina,85
Raka, 92
Sari,abc

Budi,74
Maya,105
Tono
```

The file contains three valid lines and several problems on purpose: a score that is not a number, an empty line, a score above 100, and a line without a comma. Real input files are rarely perfect, and a good program handles every one of these cases gracefully. `cargo run` runs the program from the project's root folder, which is why the file belongs there.

### Step 2: Read and Parse the File

Add the `main` function below the `use` lines:

```rust
fn main() -> Result<(), String> {
    let content = fs::read_to_string("scores.txt")
        .map_err(|error| format!("could not read scores.txt: {error}"))?;

    let mut students: Vec<Student> = Vec::new();
    for (index, line) in content.lines().enumerate() {
        if line.trim().is_empty() {
            continue;
        }
        match parse_line(line) {
            Ok(student) => students.push(student),
            Err(message) => println!("Skipping line {}: {message}", index + 1),
        }
    }
```

`fs::read_to_string("scores.txt")` opens the file, reads its entire contents into a `String`, and closes it again. It returns a `Result`: `Ok` with the text, or `Err` with an `io::Error` describing what went wrong. `map_err` converts that error into a `String` message that includes the original error, and `?` returns it from `main` if reading failed. That is why `main` returns `Result<(), String>`, as in Lesson 15.

`content.lines()` splits the text into lines without their newline characters, and `enumerate` adds a position to each one (Lesson 13). Empty lines are skipped with `continue`. Every other line goes through `parse_line`. Valid students are pushed into the vector, and invalid lines produce a message with a human friendly line number (`index + 1`) instead of stopping the whole program. One bad line should not prevent the report for everyone else.

### Step 3: Build the Report and Write It to a File

Add the rest of `main`:

```rust
    let mut report = String::new();
    for student in &students {
        let row = format!(
            "{:<6} {:>3}  {}\n",
            student.name,
            student.score,
            letter(student.score)
        );
        report.push_str(&row);
    }
    match average(&students) {
        Some(value) => report.push_str(&format!("Average: {value:.1}\n")),
        None => report.push_str("No valid scores.\n"),
    }

    print!("{report}");
    fs::write("report.txt", &report)
        .map_err(|error| format!("could not write report.txt: {error}"))?;
    println!("Report saved to report.txt");
    Ok(())
}
```

The report is built as a single `String`, one formatted row per student, followed by the average. Each row ends with `\n`, a newline, because the text will be written to a file as well as printed. Building the text once and using it twice keeps the screen output and the file identical.

`print!("{report}")` prints the report; `print!` is used because the text already ends with a newline. `fs::write("report.txt", &report)` creates the file (or replaces it if it exists) and writes the text into it. It also returns a `Result`, handled the same way as the read. `Ok(())` signals that `main` finished successfully.

---

## 4. Write Unit Tests

Checking the output by eye works for one run, but it does not scale. Every time you change `parse_line`, you would have to re-check every kind of line by hand. Unit tests automate that: each test calls a function with a known input and asserts that the result is what you expect.

### Step 1: Add a Test Module to grades.rs

Add this block to the end of `src/grades.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_a_valid_line() {
        let student = parse_line("Dina, 85").unwrap();
        assert_eq!(student.name, "Dina");
        assert_eq!(student.score, 85);
    }

    #[test]
    fn rejects_a_score_that_is_not_a_number() {
        let result = parse_line("Sari,abc");
        assert!(result.is_err());
    }

    #[test]
    fn rejects_a_score_above_100() {
        assert_eq!(
            parse_line("Budi,120").err(),
            Some(String::from("120 is above the maximum of 100"))
        );
    }

    #[test]
    fn converts_scores_to_letters() {
        assert_eq!(letter(95), 'A');
        assert_eq!(letter(80), 'B');
        assert_eq!(letter(59), 'E');
    }

    #[test]
    fn averages_scores() {
        let students = vec![
            Student {
                name: String::from("A"),
                score: 80,
            },
            Student {
                name: String::from("B"),
                score: 90,
            },
        ];
        assert_eq!(average(&students), Some(85.0));
        assert_eq!(average(&[]), None);
    }
}
```

By convention, tests live in a module named `tests` inside the file they test. `#[cfg(test)]` tells the compiler to include this module only when running tests, so it adds nothing to the normal program. `mod tests { ... }` with curly braces defines a module inline instead of in a separate file. `use super::*;` imports everything from the parent module (`grades`), so the tests can call `parse_line`, `letter`, and `average` directly. Tests in the same file can also use private items.

Each function marked with `#[test]` is one test. Its name describes what it checks, so a failure message tells you immediately what broke. Inside, the assertion macros do the checking:

- `assert_eq!(left, right)` passes if the two values are equal, and fails the test otherwise, showing both values.
- `assert!(condition)` passes if the condition is `true`.

In a test, `unwrap()` is fine: if `parse_line` unexpectedly returns an error, the panic makes the test fail, which is exactly what should happen. `.err()` turns a `Result` into an `Option` containing the error, which lets the third test compare the exact message. The tests check edge cases on purpose: 80 is the lowest `B`, and an empty list has no average.

### Step 2: Run the Tests

Run all tests in the project:

```bash
cargo test
```

Cargo compiles the project in test mode and runs every `#[test]` function. After its `Finished` and `Running unittests src/main.rs (...)` lines, the test runner prints:

```text

running 5 tests
test grades::tests::averages_scores ... ok
test grades::tests::converts_scores_to_letters ... ok
test grades::tests::parses_a_valid_line ... ok
test grades::tests::rejects_a_score_above_100 ... ok
test grades::tests::rejects_a_score_that_is_not_a_number ... ok

test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

```

Each line shows the test's full path (module `grades`, module `tests`, test name) and its result. The summary says all five passed. Tests run in parallel, so the order of the lines can differ between runs.

### Step 3: See a Test Fail

A test is only useful if it fails when the code is wrong. Introduce a bug on purpose: in `letter`, change `80..=89` to `81..=89`, and run `cargo test` again. This time the output includes:

```text

running 5 tests
test grades::tests::averages_scores ... ok
test grades::tests::rejects_a_score_above_100 ... ok
test grades::tests::parses_a_valid_line ... ok
test grades::tests::rejects_a_score_that_is_not_a_number ... ok
test grades::tests::converts_scores_to_letters ... FAILED

failures:

---- grades::tests::converts_scores_to_letters stdout ----

thread 'grades::tests::converts_scores_to_letters' (62926) panicked at src/grades.rs:74:9:
assertion `left == right` failed
  left: 'E'
 right: 'B'
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    grades::tests::converts_scores_to_letters

test result: FAILED. 4 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

```

The failing test is marked `FAILED`, and the `failures` section shows exactly which assertion failed and where: `letter(80)` returned `'E'` (`left`), but the test expected `'B'` (`right`). Score 80 now falls through to the wildcard arm. The test caught an off by one mistake that is easy to miss when reading code. Change the range back to `80..=89` and run `cargo test` to confirm all five tests pass again.

---

## 5. Run and Test

Your complete `src/main.rs` should look like this:

```rust
mod grades;

use std::fs;

use grades::{Student, average, letter, parse_line};

fn main() -> Result<(), String> {
    let content = fs::read_to_string("scores.txt")
        .map_err(|error| format!("could not read scores.txt: {error}"))?;

    let mut students: Vec<Student> = Vec::new();
    for (index, line) in content.lines().enumerate() {
        if line.trim().is_empty() {
            continue;
        }
        match parse_line(line) {
            Ok(student) => students.push(student),
            Err(message) => println!("Skipping line {}: {message}", index + 1),
        }
    }

    let mut report = String::new();
    for student in &students {
        let row = format!(
            "{:<6} {:>3}  {}\n",
            student.name,
            student.score,
            letter(student.score)
        );
        report.push_str(&row);
    }
    match average(&students) {
        Some(value) => report.push_str(&format!("Average: {value:.1}\n")),
        None => report.push_str("No valid scores.\n"),
    }

    print!("{report}");
    fs::write("report.txt", &report)
        .map_err(|error| format!("could not write report.txt: {error}"))?;
    println!("Report saved to report.txt");
    Ok(())
}
```

`src/grades.rs` contains the struct, the three functions from Section 2, and the test module from Section 4. Run the program from the project's root folder:

```bash
cargo run -q
```

```text
Skipping line 3: 'abc' is not a valid score
Skipping line 6: 105 is above the maximum of 100
Skipping line 7: 'Tono' should look like 'name,score'
Dina    85  B
Raka    92  A
Budi    74  C
Average: 83.7
Report saved to report.txt
```

Three lines were skipped, each with the reason and the correct line number; the empty line 4 was skipped silently. `Raka, 92` was accepted because `parse_line` trims the score. The average of 85, 92, and 74 is 83.7. Now look at the saved file:

```bash
cat report.txt
```

```text
Dina    85  B
Raka    92  A
Budi    74  C
Average: 83.7
```

`report.txt` contains exactly the report, without the skip messages, because only the `report` string was written. To see the file error handling, rename `scores.txt` to something else and run the program again:

```text
Error: "could not read scores.txt: No such file or directory (os error 2)"
```

The `?` in `main` returned the error, and the message includes both your context and the operating system's reason. Rename the file back afterward.

### Format and Lint Your Code

Cargo includes two more tools that professional Rust developers run constantly. `cargo fmt` rewrites your source files in the official Rust style: indentation, line breaks, spacing, and the order of items in `use` lists. Try it by messing up the indentation of a few lines in `main.rs` and running:

```bash
cargo fmt
```

The command prints nothing, but the file is now neatly formatted again. (The code in this lesson is already formatted with `cargo fmt`, which is why the long `format!` call is split over several lines.)

`cargo clippy` runs Clippy, a linter that checks your code for common mistakes and unidiomatic patterns, and suggests improvements:

```bash
cargo clippy
```

For this project, Clippy reports only its `Checking` and `Finished` lines, which means it found nothing to improve. On your own code, read its suggestions the same way you read compiler messages; each one includes an explanation and usually the fix. Both tools are installed with the default Rust toolchain from Lesson 2.

---

## 6. Fix the Errors in Your Code

Module errors are about visibility and declarations, and file errors happen at runtime. Here are the most common ones.

**Error 1: Using a private function from another module.**

```rust
// Wrong (in src/grades.rs)
fn letter(score: u32) -> char {
    // ...
}

// Correct
pub fn letter(score: u32) -> char {
    // ...
}
```

With the wrong version, `main.rs` fails with ``error[E0603]: function `letter` is private``, and a note points to where `letter` is defined. Items are private by default; add `pub` to anything other modules need to use.

**Error 2: Using a private field.**

```rust
// Wrong
pub struct Student {
    pub name: String,
    score: u32,
}

// Correct
pub struct Student {
    pub name: String,
    pub score: u32,
}
```

With the wrong version, every use of `student.score` in `main.rs` fails with ``error[E0616]: field `score` of struct `Student` is private``. A public struct can still have private fields, and each field needs its own `pub` to be readable from outside the module.

**Error 3: Forgetting to declare the module.**

```rust
// Wrong (src/main.rs)
use std::fs;

use grades::{Student, average, letter, parse_line};

// Correct
mod grades;

use std::fs;

use grades::{Student, average, letter, parse_line};
```

The wrong version produces ``error[E0432]: unresolved import `grades` ``, and the `help` line explains: ``to make use of source file src/grades.rs, use `mod grades` in this file to declare the module``. Creating the file is not enough; `mod grades;` tells the compiler to include it.

**Error 4: Putting the input file in the wrong folder.**

This is a runtime error rather than a compile error: the program builds fine but cannot find its file.

```bash
# Wrong: the file is inside src
src/scores.txt

# Correct: the file is in the project root, next to Cargo.toml
scores.txt
```

With the wrong layout, `cargo run` prints `Error: "could not read scores.txt: No such file or directory (os error 2)"`. A relative path like `"scores.txt"` is looked up in the folder the program runs from, which is the project root when you use `cargo run`, not the folder containing the source code.

---

## 7. Exercises

**Exercise 1:** In the `grade_book` project, add two tests to the `tests` module: one that checks that `parse_line(" ,80")` returns the error `' ,80' has an empty name`, and one that checks that `parse_line("Tono")` returns an error. Run `cargo test` and confirm that seven tests pass.

**Exercise 2:** Add a function `pub fn highest(students: &[Student]) -> Option<&Student>` to the `grades` module that returns the student with the highest score (use `max_by_key`). Add a test for it that covers both a non empty list and an empty one. Then use it in `main.rs` to add a `Highest: Raka (92)` line to the report, before it is printed and saved.

**Exercise 3:** Create a new project called `text_stats` with a module `stats` in `src/stats.rs` containing `count_words(text: &str) -> usize` and `longest_word(text: &str) -> Option<&str>`, each with a test. In `main.rs`, read a file `notes.txt` (create it with three lines of text), print the number of lines, words, and the longest word, and save the same summary to `summary.txt`.

---

## 8. Solutions

**Solution for Exercise 1:**

Add these two tests inside `mod tests` in `src/grades.rs`:

```rust
    #[test]
    fn rejects_an_empty_name() {
        assert_eq!(
            parse_line(" ,80").err(),
            Some(String::from("' ,80' has an empty name"))
        );
    }

    #[test]
    fn rejects_a_line_without_a_comma() {
        assert!(parse_line("Tono").is_err());
    }
```

The first test compares the exact message, which also documents the expected wording. The second only checks that the result is an error, which is enough when the exact message does not matter. Running `cargo test` now reports `7 passed`. (The output for Exercise 2 below shows these tests running together with the new one.)

**Solution for Exercise 2:**

Add the function to `src/grades.rs`, above the test module:

```rust
pub fn highest(students: &[Student]) -> Option<&Student> {
    students.iter().max_by_key(|s| s.score)
}
```

And add this test inside `mod tests`:

```rust
    #[test]
    fn finds_the_highest_score() {
        let students = vec![
            Student {
                name: String::from("Dina"),
                score: 85,
            },
            Student {
                name: String::from("Raka"),
                score: 92,
            },
        ];
        assert_eq!(highest(&students).unwrap().name, "Raka");
        assert!(highest(&[]).is_none());
    }
```

`max_by_key` returns an `Option` containing a reference to the best element, which matches the return type directly. The returned reference borrows from the slice, so no `Student` is copied. In `main.rs`, add `highest` to the `use grades::{...}` list, and insert these lines just before `print!("{report}");`:

```rust
    if let Some(best) = highest(&students) {
        report.push_str(&format!("Highest: {} ({})\n", best.name, best.score));
    }
```

`if let` adds the line only when there is at least one valid student. `cargo run -q` now prints:

```text
Skipping line 3: 'abc' is not a valid score
Skipping line 6: 105 is above the maximum of 100
Skipping line 7: 'Tono' should look like 'name,score'
Dina    85  B
Raka    92  A
Budi    74  C
Average: 83.7
Highest: Raka (92)
Report saved to report.txt
```

And `cargo test` prints:

```text

running 8 tests
test grades::tests::averages_scores ... ok
test grades::tests::converts_scores_to_letters ... ok
test grades::tests::finds_the_highest_score ... ok
test grades::tests::parses_a_valid_line ... ok
test grades::tests::rejects_a_line_without_a_comma ... ok
test grades::tests::rejects_a_score_above_100 ... ok
test grades::tests::rejects_a_score_that_is_not_a_number ... ok
test grades::tests::rejects_an_empty_name ... ok

test result: ok. 8 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

```

**Solution for Exercise 3:**

```bash
cd ~/rust-basics
cargo new text_stats
cd text_stats
```

Create `src/stats.rs`:

```rust
pub fn count_words(text: &str) -> usize {
    text.split_whitespace().count()
}

pub fn longest_word(text: &str) -> Option<&str> {
    text.split_whitespace()
        .max_by_key(|word| word.chars().count())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn counts_words_across_lines() {
        assert_eq!(count_words("one two\nthree"), 3);
        assert_eq!(count_words("   "), 0);
    }

    #[test]
    fn finds_the_longest_word() {
        assert_eq!(longest_word("a rusty compiler"), Some("compiler"));
        assert_eq!(longest_word(""), None);
    }
}
```

`split_whitespace` treats newlines as whitespace too, so it counts words across all lines. `longest_word` compares words by their character count and returns a slice of the input text, wrapped in `Option` for empty text. Replace `src/main.rs` with:

```rust
mod stats;

use std::fs;

fn main() -> Result<(), String> {
    let text = fs::read_to_string("notes.txt")
        .map_err(|error| format!("could not read notes.txt: {error}"))?;

    let words = stats::count_words(&text);
    let lines = text.lines().count();
    let longest = stats::longest_word(&text).unwrap_or("(none)");

    let summary = format!("Lines: {lines}\nWords: {words}\nLongest word: {longest}\n");
    print!("{summary}");
    fs::write("summary.txt", &summary)
        .map_err(|error| format!("could not write summary.txt: {error}"))?;
    Ok(())
}
```

This `main.rs` does not use `use stats::...`; it calls the functions with the module path, `stats::count_words`, which works just as well and shows clearly where each function comes from. Create `notes.txt` in the project root:

```text
Rust programs are compiled before they run.
The compiler checks ownership and borrowing.
Tests keep refactoring safe.
```

`cargo run -q` prints the summary and writes the same text to `summary.txt`:

```text
Lines: 3
Words: 17
Longest word: refactoring
```

`cargo test` reports `2 passed`. Note that punctuation counts as part of a word here (`borrowing.` has ten characters); handling it would be a good extra challenge.

---

## Next Up - Lesson 18

In this lesson you organized code into a module in its own file, controlled visibility with `pub`, and imported items with `use`. You read a file with `fs::read_to_string`, processed it line by line while skipping invalid data, and saved a report with `fs::write`. You wrote unit tests with `#[test]`, `assert!`, and `assert_eq!`, ran them with `cargo test`, watched one catch a bug, and kept your code tidy with `cargo fmt` and `cargo clippy`.

You now have every tool you need for the final lesson. In Lesson 18, you will build a complete command-line to-do list application: tasks stored in a vector of structs, commands modeled as an enum, input parsed into `Result`s, data saved to and loaded from a text file, logic organized in a module, and the important parts covered by tests.
