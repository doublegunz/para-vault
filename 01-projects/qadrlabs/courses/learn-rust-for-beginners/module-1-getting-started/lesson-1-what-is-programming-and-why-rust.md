## 1. Before You Begin

Every app on your phone, every website you visit, and every game you play started as text written by a person. That text is called a program, and the act of writing it is called programming. If you have never written a program before, you are in exactly the right place. This course assumes nothing except curiosity and a willingness to type, run, and fix things.

This first lesson is about building the right mental model before you install anything. You will learn what a program actually is, how a computer turns text into something it can run, and why Rust is a surprisingly good language to learn these ideas with. At the end, you will run a real Rust program in your browser, read it line by line, and break it on purpose to see how Rust responds.

### What You'll Build

A small Rust program that stores a name and a number, then prints three lines of text. You will run it in the Rust Playground, a free website that compiles and runs Rust code without any installation. In Lesson 2 you will install Rust on your own computer and run programs locally.

### What You'll Learn

- ✅ What a program is and what "programming" means in practice
- ✅ The difference between source code, a compiler, and an executable
- ✅ The difference between compiled and interpreted languages
- ✅ What Rust is, who uses it, and why it suits beginners who want solid foundations
- ✅ How to run Rust code in the Rust Playground
- ✅ How to read a Rust compiler error message
- ✅ The roadmap for the rest of this course

### What You'll Need

- A web browser and an internet connection
- No installation and no previous programming experience

---

## 2. What Is a Program?

A program is a list of instructions that a computer follows, one after another, to complete a task. A recipe is a good comparison. A recipe says "crack two eggs, add a cup of flour, stir for one minute." A cook who follows those instructions in order ends up with batter. A program says things like "store this number, add five to it, show the result on the screen." A computer that follows those instructions ends up with a result.

There is one big difference between a cook and a computer. A cook can fill in gaps: if a recipe says "add some salt," the cook decides how much. A computer cannot guess. Every instruction must be precise, complete, and written in a form the computer understands. That is why programming languages have strict rules about spelling, punctuation, and structure. A missing semicolon in an essay is a small mistake; a missing semicolon in a program can stop it from running at all.

Programs are made of a few basic ingredients, and you will meet each one in this course:

| Ingredient | What it does | Where you learn it |
| --- | --- | --- |
| Values and variables | Store data such as numbers and text | Lessons 3 and 4 |
| Decisions | Choose what to do based on a condition | Lesson 5 |
| Loops | Repeat work without rewriting it | Lesson 6 |
| Functions | Package instructions under a name so you can reuse them | Lesson 7 |
| Data structures | Group related data together | Lessons 11 to 14 |
| Error handling | Deal with things that go wrong | Lesson 15 |

Almost every program ever written, from a calculator to an operating system, is built from these same ingredients. Learning them well in one language makes every other language easier to pick up later.

---

## 3. From Source Code to a Running Program

The text you write is called source code. Computers do not run source code directly. The processor inside your computer only understands machine code, a long sequence of numbers that is extremely hard for humans to read or write. Something has to translate between the two.

There are two common ways to do that translation. Some languages, such as Python and PHP, use an interpreter: a program that reads your source code and carries out the instructions immediately, line by line, every time you run it. Other languages, such as Rust, C, and Go, use a compiler: a program that reads all of your source code ahead of time and translates it into a separate file called an executable (or binary). You then run the executable, and the compiler is no longer involved.

The compiled workflow looks like this:

```text
source code (main.rs)  ->  compiler (rustc)  ->  executable (main)  ->  output on screen
```

Each arrow is a separate step. You write `main.rs`, the Rust compiler `rustc` checks and translates it, and the resulting executable runs on your computer. Lesson 2 shows you each of these steps in the terminal.

A compiler has an important advantage for learners: it checks the whole program before anything runs. If you misspell something or use a value in a way that does not make sense, the compiler refuses to produce an executable and tells you what went wrong. In an interpreted language, the same mistake might only show up later, while the program is already running, sometimes in front of a user.

---

## 4. What Is Rust?

Rust is a compiled, statically typed programming language. "Statically typed" means every value has a type (a whole number, a decimal number, a piece of text, and so on) and the compiler checks those types before the program runs. Rust started as a personal project at Mozilla, reached its stable 1.0 release in 2015, and is now developed by an open source community and supported by the Rust Foundation.

Rust is used for programs where speed and reliability matter: command-line tools, web servers, game engines, embedded devices, browser components, and parts of operating systems. The Linux kernel accepts drivers written in Rust, and large companies use it for infrastructure that has to run for months without crashing. The [official Rust website](https://www.rust-lang.org/) summarizes the language with three words: performance, reliability, and productivity.

Rust's most distinctive feature is how it manages memory. Every program stores data in the computer's memory, and that memory must eventually be given back. Some languages leave this job to the programmer, which is fast but error prone. Others use a garbage collector, a background process that cleans up unused data, which is safe but adds overhead. Rust takes a third path called ownership: a set of rules the compiler checks at compile time so memory is cleaned up automatically, safely, and without a garbage collector. You will study ownership in Module 5. For now, it is enough to know that this is why Rust's compiler is strict.

---

## 5. Why Learn Programming with Rust?

Rust has a reputation for being hard. That reputation comes mostly from experienced developers who bring habits from other languages and find that Rust rejects them. As a complete beginner, you do not have those habits yet, and Rust's strictness becomes a strength instead of a hurdle.

There are four reasons Rust works well as a first language in this course:

- **The compiler is a patient mentor.** Rust's error messages explain what went wrong, point to the exact line, and often suggest the fix. You will see this for yourself in Section 7.
- **You learn how computers actually work.** Rust makes you think about types, memory, and errors explicitly. Those ideas exist in every language; Rust simply does not hide them.
- **The tooling is excellent and consistent.** A single official tool, Cargo, creates projects, builds them, runs them, formats your code, and runs tests. You will not need to choose between competing tools.
- **The skills transfer.** Variables, conditions, loops, functions, structs, and error handling look slightly different in other languages, but the ideas are the same. Learning them in a strict language makes looser languages feel easy.

To be fair, Rust also asks for patience. Some lessons will include code that the compiler rejects, and understanding why is part of the learning. That is deliberate: reading compiler messages is a core skill, and this course practices it in every lesson.

---

## 6. Run Your First Rust Program in the Browser

The fastest way to see Rust in action is the Rust Playground, an official website that compiles and runs Rust code on a remote server. You will install Rust locally in Lesson 2, but the Playground lets you start right now.

### Step 1: Open the Rust Playground

Open [https://play.rust-lang.org](https://play.rust-lang.org) in your browser. You will see an editor on the left (or top, on narrow screens) that already contains a small program, and a **Run** button above it. The editor is where you type source code. When you click **Run**, the Playground compiles your code with the Rust compiler and shows the result below the editor.

### Step 2: Replace the Code

Select all the code in the editor, delete it, and type the following program. Typing it yourself instead of pasting helps you notice the punctuation.

```rust
fn main() {
    // Step 1: store a name and a number.
    let name = "Rustacean";
    let lessons = 18;

    // Step 2: print them, one line at a time.
    println!("Hello, {name}!");
    println!("This course has {lessons} lessons.");
    println!("Let's start programming.");
}
```

Here is what each line does. `fn main() {` declares a function named `main`. A function is a named group of instructions, and `main` is special: it is the entry point, the place where every Rust program starts running. The curly braces `{` and `}` mark where the function's body begins and ends, and everything between them runs from top to bottom.

The lines that start with `//` are comments. The compiler ignores them completely; they exist only for humans reading the code. Writing short comments that explain *why* something is done is a good habit from day one.

`let name = "Rustacean";` creates a variable called `name` and stores the text `"Rustacean"` in it. (Rustacean is the nickname Rust programmers use for themselves.) Text inside double quotes is called a string. `let lessons = 18;` creates another variable and stores the whole number `18`. The semicolon at the end of each line marks the end of an instruction, called a statement.

`println!("Hello, {name}!");` prints a line of text to the screen. The exclamation mark tells you `println!` is a macro, a special kind of Rust instruction that generates code for you. You will use macros long before you need to understand how they work. The `{name}` inside the string is a placeholder: when the program runs, Rust replaces it with the value stored in the `name` variable. The next two `println!` lines work the same way, and each one ends its output with a new line.

### Step 3: Run the Program

Click **Run**. The Playground compiles the code and runs it. The output panel shows the program's output:

```text
Hello, Rustacean!
This course has 18 lessons.
Let's start programming.
```

Each `println!` produced one line, in the same order they appear in the code. The `{name}` and `{lessons}` placeholders were replaced by the values you stored. The Playground also shows some messages from the compiler in a separate panel (for example, that it is compiling and that it finished); those messages are about the build, not output from your program.

### Step 4: Change a Value and Run Again

Change `"Rustacean"` to your own name, and change the third `println!` to say something different. Click **Run** again. The output changes to match your edits. This edit, run, observe cycle is the heart of programming, and you will repeat it thousands of times. Every change to source code needs a fresh compile before the result reflects it; the Playground just does that for you each time you click **Run**.

---

## 7. Read Your First Compiler Error

Mistakes are not a sign that you are bad at programming. They are a normal, constant part of it, even for experts. What separates beginners from experienced programmers is how quickly they can read an error and fix it. Rust gives you excellent practice.

In the Playground, remove the exclamation mark from the first `println!`, so the line reads `println("Hello, {name}!");`, and click **Run**. The compiler stops and reports an error instead of running the program. The first line of the error says:

```text
error[E0423]: cannot find function `println` in this scope
```

Rust error messages follow a consistent structure, and it is worth learning to read them now:

- `error[E0423]` is the error code. Every code has a longer explanation you can look up, either with `rustc --explain E0423` once Rust is installed, or in the [Rust error code index](https://doc.rust-lang.org/error_codes/error-index.html).
- The message after the colon describes the problem in plain words: there is no *function* called `println`.
- Below that, an arrow `-->` points to the file, line, and column where the problem is, followed by the line of code itself with `^^^^^^^` markers under the exact spot.
- Finally, `note` and `help` lines explain more and often suggest the fix. Here, the compiler notes that a *macro* named `println` exists and suggests adding `!`.

Put the exclamation mark back and run again. The program works. Get into the habit of reading the whole error, top to bottom, before changing anything. The answer is usually right there.

---

## 8. How This Course Works

Each lesson after this one follows the same rhythm. You create a small Cargo project on your own computer, write code step by step, run it, and compare your output with the expected output in the lesson. Then you work through common mistakes, practice with exercises, and check your work against the solutions.

The course is organized into nine modules:

| Module | Topic | Lessons |
| --- | --- | --- |
| 1 | Getting Started | 1 to 2 |
| 2 | Values and Types | 3 to 4 |
| 3 | Control Flow | 5 to 6 |
| 4 | Functions and User Input | 7 to 8 |
| 5 | Ownership and Borrowing | 9 to 10 |
| 6 | Custom Types | 11 to 12 |
| 7 | Collections and Iterators | 13 to 14 |
| 8 | Errors and Traits | 15 to 16 |
| 9 | Organizing Code and Final Project | 17 to 18 |

Modules 2 to 4 cover the fundamentals shared by almost every programming language. Module 5 covers the ideas that make Rust different. Modules 6 to 8 teach you to model real data and handle errors properly. Module 9 ties everything together in a mini project: a command-line to-do list that saves tasks to a file. The whole course uses only the Rust standard library, so there are no extra packages to install.

---

## 9. Fix the Errors in Your Code

These are the mistakes beginners make most often with a first Rust program. Try each wrong version in the Playground to see the compiler's message, then fix it.

**Error 1: Calling `println` without the exclamation mark.**

`println!` is a macro, not a regular function, and macros are always called with `!`. Without it, Rust looks for a function named `println` and cannot find one.

```rust
// Wrong
fn main() {
    println("Hello, world!");
}

// Correct
fn main() {
    println!("Hello, world!");
}
```

The wrong version produces ``error[E0423]: cannot find function `println` in this scope``, together with a `help` line suggesting ``use `!` to invoke the macro``. The correct version adds the `!` directly after `println`, with no space in between.

**Error 2: Forgetting a semicolon between statements.**

Each statement inside `main` needs to end with a semicolon. When one is missing, the compiler reaches the next line and finds something it did not expect.

```rust
// Wrong
fn main() {
    println!("Hello, world!")
    println!("Welcome to Rust.");
}

// Correct
fn main() {
    println!("Hello, world!");
    println!("Welcome to Rust.");
}
```

The wrong version produces ``error: expected `;`, found `println` ``. The compiler points at the end of line 2 with `help: add `;` here` and marks the second `println` as the `unexpected token`. Notice that the error is reported where the semicolon should be, not on the line that looks unusual. When you see an error on one line, always check the line just before it too.

**Error 3: Misspelling `main`.**

Rust names are case sensitive: `main`, `Main`, and `MAIN` are three different names. A program must have a function named exactly `main`, or the compiler does not know where to start.

```rust
// Wrong
fn Main() {
    println!("Hello, world!");
}

// Correct
fn main() {
    println!("Hello, world!");
}
```

The wrong version produces ``error[E0601]: `main` function not found``, followed by the name of the crate (the name of the program being compiled) and a hint to add a `main` function. The function body is perfectly fine; only the name is wrong. Lowercase `main` fixes it.

---

## 10. Exercises

**Exercise 1:** In your own words, explain the difference between source code and an executable. Then describe what happens in each of the three steps of the compiled workflow: writing, compiling, and running.

**Exercise 2:** In the Rust Playground, write a program that prints a short self-introduction on three lines: your name, the city you live in, and why you want to learn programming. Store your name and city in variables and use `{}` placeholders to print them.

**Exercise 3:** Take your program from Exercise 2 and remove the closing curly brace `}` at the very end. Run it, read the error message from top to bottom, and write down: the error message, the line the compiler points to, and the fix. Then put the brace back.

---

## 11. Solutions

**Solution for Exercise 1:**

Source code is the human readable text you write, such as the contents of `main.rs`. An executable is the file the compiler produces, containing machine code the processor can run directly. In the writing step, you type instructions in a text editor and save them as a `.rs` file. In the compiling step, the Rust compiler reads the whole file, checks it for mistakes, and, if everything is valid, translates it into an executable. In the running step, you start the executable and it carries out the instructions, producing output such as text on the screen. If the source changes, you must compile again before the executable reflects the change.

**Solution for Exercise 2:**

One possible program looks like this.

```rust
fn main() {
    let name = "Dina";
    let city = "Sukabumi";

    println!("My name is {name}.");
    println!("I live in {city}.");
    println!("I want to learn programming to build my own tools.");
}
```

The two `let` lines store text values in variables called `name` and `city`. The first two `println!` lines use placeholders that Rust replaces with those values, and the third line prints fixed text. Running it prints:

```text
My name is Dina.
I live in Sukabumi.
I want to learn programming to build my own tools.
```

Your name, city, and reason will differ, which is the point: the structure stays the same while the data changes.

**Solution for Exercise 3:**

Without the final `}`, the compiler reaches the end of the file while the `main` function is still open. It reports an error that starts with `error: this file contains an unclosed delimiter`. The compiler points to the opening `{` of `main` that was never closed and to the end of the file, where it expected the closing brace. The fix is to add `}` back as the last line. The lesson here is that braces always come in pairs: every `{` needs a matching `}`. Editors such as Visual Studio Code highlight matching pairs, which makes this kind of mistake easier to spot.

---

## Next Up - Lesson 2

In this lesson you learned what a program is, how a compiler turns source code into an executable, and why Rust's strict compiler makes it a strong first language. You ran a real Rust program in the Playground, changed it, and read your first compiler error from top to bottom.

In Lesson 2, you will install Rust on Ubuntu with `rustup`, compile a program by hand with `rustc`, and create your first Cargo project. From then on, every lesson runs on your own computer.
