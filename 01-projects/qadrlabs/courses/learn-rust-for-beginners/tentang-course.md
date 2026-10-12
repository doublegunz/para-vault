---
title: "Learn Rust for Beginners: Programming Fundamentals from Zero"
slug: "learn-rust-for-beginners"
status: "draft"
---

# Learn Rust for Beginners: Programming Fundamentals from Zero

## Deskripsi
```
Learn programming from zero with Rust. Master variables, control flow, functions, ownership, structs, enums, collections, error handling, and traits, then build a command-line to-do list.
```


## Konten

```
Rust is a compiled, statically typed programming language known for speed, reliability, and careful control over memory. It powers command-line tools, web services, embedded devices, and parts of the software you already use every day. Rust is often described as a language for experienced developers, but its strict compiler is also a patient teacher: it checks your code before it runs and explains, in plain language, what went wrong and how to fix it.

This course uses Rust to teach programming fundamentals from the very beginning. You do not need any previous programming experience. Every lesson introduces one concept, shows it in a small Cargo project you create and run yourself, and then asks you to fix common mistakes and practice with exercises. Along the way, you will learn to read compiler messages as guidance instead of obstacles, a skill that makes every later lesson easier.

The course finishes with a mini project: a command-line to-do list that adds, lists, completes, and removes tasks and saves them to a text file. It brings together everything you have learned, from variables and loops to structs, enums, error handling, modules, and tests. Only the Rust standard library is used, so there are no extra packages to install. If you want a short preview first, the article "[Getting to Know Rust: A First Look with Ubuntu and Hello World](https://qadrlabs.com/post/getting-to-know-rust-ubuntu-hello-world)" is optional reading.

**Prerequisites:**
- No previous programming experience required
- A computer running Ubuntu (or another Linux distribution) with terminal access and permission to use `sudo`
- A text editor such as Visual Studio Code
- An internet connection to install the Rust toolchain

**By the end, you will have:**
- A working Rust toolchain (rustup, rustc, Cargo) and a clear picture of the compile-and-run workflow
- A solid grasp of variables, data types, operators, conditionals, loops, and functions
- An understanding of ownership, borrowing, and slices, the ideas that make Rust different
- Experience modeling data with structs, enums, Option, and pattern matching
- Practice with vectors, strings, hash maps, iterators, and closures
- Reliable error handling with Result and the ? operator
- Basic traits and generics, modules, file reading and writing, and unit tests with cargo test
- A command-line to-do list application that ties every concept together
```

## Daftar Modul

### 1. `Module 1 - Getting Started`

```
Understand what programming is and why Rust is worth learning, then install the toolchain and run your first program with rustc and Cargo.
```


- Lesson 1 - What Is Programming and Why Rust?
    lesson short description
    ```
    Learn what a program is, how a compiler turns source code into an executable, and why Rust's strict compiler makes it a great first language, then run your first program in the Rust Playground.
    
    ```
- Lesson 2 - Installing Rust and Your First Program
    lesson short description
    ```
    Install Rust on Ubuntu with rustup, compile Hello World by hand with rustc, and create, build, check, and run your first Cargo project.
    
    ```

### 2. `Module 2 - Values and Types`

```
Store and print data with variables, learn when values can change, and work with numbers, text characters, and booleans using Rust's operators.
```


- Lesson 3 - Variables, Mutability, and Printing
    lesson short description
    ```
    Store values with let, allow changes with mut, use constants and shadowing, and format output with placeholders, alignment, widths, and decimal rounding.
    
    ```
- Lesson 4 - Data Types and Operators
    lesson short description
    ```
    Work with integers, floats, booleans, and characters, group values in tuples and arrays, and calculate, compare, and convert values with Rust's operators.
    
    ```

### 3. `Module 3 - Control Flow`

```
Make programs decide and repeat with if expressions, match, and the three loop forms: loop, while, and for.
```


- Lesson 5 - Making Decisions with if and match
    lesson short description
    ```
    Choose between paths with if, else if, and else, use if as an expression, and compare values against ranges and patterns with an exhaustive match.
    
    ```
- Lesson 6 - Repeating Work with Loops
    lesson short description
    ```
    Repeat work with loop, while, and for, iterate over ranges and arrays, control loops with break and continue, and build running totals and nested loops.
    
    ```

### 4. `Module 4 - Functions and User Input`

```
Break programs into reusable functions with parameters and return values, and make them interactive by reading and parsing keyboard input.
```


- Lesson 7 - Functions, Parameters, and Return Values
    lesson short description
    ```
    Split programs into functions with typed parameters and return values, and understand statements, expressions, early returns, and returning tuples.
    
    ```
- Lesson 8 - Reading User Input
    lesson short description
    ```
    Read keyboard input with stdin, trim and parse it into numbers, handle invalid input with match on Result, and build a number guessing game.
    
    ```

### 5. `Module 5 - Ownership and Borrowing`

```
Learn the rules that let Rust manage memory without a garbage collector: ownership, moves, references, borrowing, and slices.
```


- Lesson 9 - Understanding Ownership
    lesson short description
    ```
    Learn how Rust manages memory without a garbage collector through scope, moves, clone, and Copy types, and how ownership moves into and out of functions.
    
    ```
- Lesson 10 - References, Borrowing, and Slices
    lesson short description
    ```
    Use values without owning them through immutable and mutable references, follow the borrowing rules, and borrow parts of strings and arrays with slices.
    
    ```

### 6. `Module 6 - Custom Types`

```
Model real data with structs and methods, and represent choices with enums, Option, and pattern matching.
```


- Lesson 11 - Structs and Methods
    lesson short description
    ```
    Create your own types with structs, print them with derive(Debug), and add constructors and methods that read with &self and change with &mut self.
    
    ```
- Lesson 12 - Enums, Option, and Pattern Matching
    lesson short description
    ```
    Model choices with enums that carry data, handle missing values safely with Option, and extract data with match, if let, and unwrap_or.
    
    ```

### 7. `Module 7 - Collections and Iterators`

```
Work with groups of data using vectors, strings, and hash maps, and process them cleanly with iterators and closures.
```


- Lesson 13 - Vectors, Iterators, and Closures
    lesson short description
    ```
    Store growing lists in vectors, loop over and modify them safely, and process data with iterator chains such as map, filter, sum, and collect.
    
    ```
- Lesson 14 - Strings and Hash Maps
    lesson short description
    ```
    Build, search, split, and transform text while respecting bytes and characters, and store, update, and count values by key with HashMap.
    
    ```

### 8. `Module 8 - Errors and Traits`

```
Handle failure safely with panic, Result, and the ? operator, and share behavior across types with traits and basic generics.
```


- Lesson 15 - Error Handling with Result
    lesson short description
    ```
    Tell panics from recoverable errors, return Result from your own functions, propagate errors with the ? operator, and let main return a Result.
    
    ```
- Lesson 16 - Traits and Generics Basics
    lesson short description
    ```
    Share behavior across types with traits and default methods, derive and implement standard traits like Display, and write generic functions with trait bounds.
    
    ```

### 9. `Module 9 - Organizing Code and Final Project`

```
Split code into modules, read and write files, test it with cargo test, and combine everything into a command-line to-do list application.
```


- Lesson 17 - Modules, Files, and Unit Tests
    lesson short description
    ```
    Split code into modules with pub and use, read and write files with std::fs, and protect your logic with unit tests run by cargo test.
    
    ```
- Lesson 18 - Mini Project: Command-Line To-Do List
    lesson short description
    ```
    Combine everything from the course into a tested command-line to-do list that parses commands into an enum and saves tasks to a text file.
    
    ```
