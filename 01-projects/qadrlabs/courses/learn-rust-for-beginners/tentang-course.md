---
title: "Learn Rust for Beginners: Programming Fundamentals from Zero"
slug: "learn-rust-for-beginners"
status: "draft"
---

# Learn Rust for Beginners: Programming Fundamentals from Zero

## Deskripsi
Learn programming from zero with Rust. Master variables, control flow, functions, ownership, structs, enums, collections, error handling, and traits, then build a command-line to-do list.

## Konten
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

## Daftar Modul

### 1. Module 1 - Getting Started
Understand what programming is and why Rust is worth learning, then install the toolchain and run your first program with rustc and Cargo.

- Lesson 1 - What Is Programming and Why Rust?
- Lesson 2 - Installing Rust and Your First Program

### 2. Module 2 - Values and Types
Store and print data with variables, learn when values can change, and work with numbers, text characters, and booleans using Rust's operators.

- Lesson 3 - Variables, Mutability, and Printing
- Lesson 4 - Data Types and Operators

### 3. Module 3 - Control Flow
Make programs decide and repeat with if expressions, match, and the three loop forms: loop, while, and for.

- Lesson 5 - Making Decisions with if and match
- Lesson 6 - Repeating Work with Loops

### 4. Module 4 - Functions and User Input
Break programs into reusable functions with parameters and return values, and make them interactive by reading and parsing keyboard input.

- Lesson 7 - Functions, Parameters, and Return Values
- Lesson 8 - Reading User Input

### 5. Module 5 - Ownership and Borrowing
Learn the rules that let Rust manage memory without a garbage collector: ownership, moves, references, borrowing, and slices.

- Lesson 9 - Understanding Ownership
- Lesson 10 - References, Borrowing, and Slices

### 6. Module 6 - Custom Types
Model real data with structs and methods, and represent choices with enums, Option, and pattern matching.

- Lesson 11 - Structs and Methods
- Lesson 12 - Enums, Option, and Pattern Matching

### 7. Module 7 - Collections and Iterators
Work with groups of data using vectors, strings, and hash maps, and process them cleanly with iterators and closures.

- Lesson 13 - Vectors, Iterators, and Closures
- Lesson 14 - Strings and Hash Maps

### 8. Module 8 - Errors and Traits
Handle failure safely with panic, Result, and the ? operator, and share behavior across types with traits and basic generics.

- Lesson 15 - Error Handling with Result
- Lesson 16 - Traits and Generics Basics

### 9. Module 9 - Organizing Code and Final Project
Split code into modules, read and write files, test it with cargo test, and combine everything into a command-line to-do list application.

- Lesson 17 - Modules, Files, and Unit Tests
- Lesson 18 - Mini Project: Command-Line To-Do List
