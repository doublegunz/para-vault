## 1. Before You Begin

This is the final lesson of the course, and it is different from the others. Instead of introducing a new concept, it asks you to combine everything you have learned into one complete program: a command-line to-do list. You will type commands such as `add Buy milk`, `list`, and `done 1`, and the program will remember your tasks between runs by saving them to a text file.

Almost every topic from the course appears somewhere in this project. Tasks are structs with methods and a `Display` implementation. Commands are an enum, and user input is parsed into a `Result<Command, String>`. The task list is a vector managed through methods that borrow it immutably or mutably. Loading and saving use `std::fs` and `?`. The logic lives in its own module, and unit tests guard the parts that are easy to break. Take your time with each section; if something feels unfamiliar, the lesson it came from is mentioned along the way.

### What You'll Build

A `todo` application with an interactive prompt. It supports six commands: `add <title>`, `list`, `done <number>`, `remove <number>`, `help`, and `quit`. Invalid commands and task numbers produce friendly error messages instead of crashes. Every change is saved to `tasks.txt` immediately, so the tasks are still there the next time you start the program.

### What You'll Learn

- ✅ How to plan a small application before writing code
- ✅ How to model the data (`Task`) and the user's intent (`Command`) with your own types
- ✅ How to parse text input into an enum with `split_once` and `Result`
- ✅ How to hide a collection inside a struct and expose safe methods
- ✅ How to design a simple text file format and convert to and from it
- ✅ How to build an interactive command loop
- ✅ How to protect the core logic with unit tests

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Everything from Lessons 1 to 17, especially structs and enums (Lessons 11 and 12), vectors (Lesson 13), error handling (Lesson 15), traits (Lesson 16), and modules, files, and tests (Lesson 17)

---

## 2. Plan the Application

Before writing any code, it pays to decide what the program does and how it is organized. A few minutes of planning saves a lot of rewriting.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new todo
cd todo
```

These commands create the `todo` project. Like `grade_book` in Lesson 17, it will have two source files: `src/todo.rs` for the application logic and `src/main.rs` for the interaction with the user.

### Step 2: Decide What Goes Where

The program has three responsibilities, and each one gets its own piece of code:

| Piece | Responsibility | Location |
| --- | --- | --- |
| `Task` | One task: its title and whether it is done; conversion to and from a line of text | `src/todo.rs` |
| `Command` and `parse_command` | Turning what the user typed into a command, or an error message | `src/todo.rs` |
| `TodoList` | The list of tasks, with methods to add, complete, remove, load, and save | `src/todo.rs` |
| `main` and helpers | Reading input, calling the right method, and printing results | `src/main.rs` |

This split keeps the logic in `todo.rs` free of any printing or keyboard input, which is exactly what makes it easy to test: a test can call `parse_command("done 2")` or `list.complete(1)` directly and check the result, without anyone typing anything. `main.rs` stays thin and only connects the user to the logic.

The tasks are saved in `tasks.txt`, one task per line, in a simple format: a status flag (`0` for pending, `1` for done), a vertical bar, and the title. For example:

```text
0|Buy milk
1|Finish the Rust course
```

A plain text format like this is easy to read and to debug: you can open the file in any editor and see exactly what the program saved.

---

## 3. Model a Task

The first building block is the `Task` struct. Everything else in the program works with tasks, so it is a natural place to start.

### Step 1: Define the Task Struct

Create the file `src/todo.rs` and add:

```rust
use std::fmt;
use std::fs;
use std::path::Path;

#[derive(Debug, Clone, PartialEq)]
pub struct Task {
    pub title: String,
    pub done: bool,
}

impl Task {
    pub fn new(title: &str) -> Task {
        Task {
            title: title.to_string(),
            done: false,
        }
    }
```

The three `use` lines import the formatting module for `Display`, the file system module for reading and writing, and `Path`, which you will use to check whether the save file exists. The compiler will warn that `fs` and `Path` are unused until Section 5; that is expected.

`Task` has two public fields: the title, owned as a `String`, and a `done` flag. It derives `Debug`, `Clone`, and `PartialEq` (Lesson 16); `PartialEq` and `Debug` are needed so tests can compare tasks with `assert_eq!`. `Task::new` is the constructor from Lesson 11: every new task starts as not done. The `impl` block stays open for the next step.

### Step 2: Convert a Task to a Line and Back

Add two methods to finish the `impl Task` block:

```rust
    pub fn to_line(&self) -> String {
        let flag = if self.done { 1 } else { 0 };
        format!("{flag}|{}", self.title)
    }

    pub fn from_line(line: &str) -> Result<Task, String> {
        let parts: Vec<&str> = line.splitn(2, '|').collect();
        if parts.len() != 2 {
            return Err(format!("invalid task line: '{line}'"));
        }
        let done = match parts[0] {
            "0" => false,
            "1" => true,
            other => return Err(format!("invalid status '{other}' in line '{line}'")),
        };
        Ok(Task {
            title: parts[1].to_string(),
            done,
        })
    }
}
```

`to_line` produces the file format from Section 2: an `if` expression (Lesson 5) picks the flag, and `format!` joins it to the title with a `|`.

`from_line` is the reverse, and it returns a `Result` because a line in the file might be damaged (Lesson 15). `splitn(2, '|')` splits the line at most into two parts, at the *first* `|` only. That detail matters: a title such as `Write | read files` contains a `|` itself, and a plain `split('|')` would cut it into three pieces. Section 9 shows how a test catches exactly that mistake. The `match` turns the flag into a `bool`, and its last arm binds any other value to `other` and returns an error. If everything is valid, the function builds the task.

### Step 3: Display a Task

Add the `Display` implementation below the `impl Task` block:

```rust
impl fmt::Display for Task {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let mark = if self.done { "x" } else { " " };
        write!(f, "[{mark}] {}", self.title)
    }
}
```

This is the `Display` trait from Lesson 16. It shows a task as a checkbox followed by the title: `[x] Finish the Rust course` for a completed task and `[ ] Buy milk` for a pending one. Because `Task` implements `Display`, `main.rs` can print a task with a plain `{task}` placeholder.

---

## 4. Model the Commands

The user types text, but the program should work with clear, checked values. An enum is the perfect type for "one of several commands," and a parsing function turns the text into it.

### Step 1: Define the Command Enum

Add this enum to `src/todo.rs`:

```rust
#[derive(Debug, PartialEq)]
pub enum Command {
    Add(String),
    List,
    Done(usize),
    Remove(usize),
    Help,
    Quit,
}
```

Each variant is one command, and variants that need data carry it (Lesson 12): `Add` holds the title, and `Done` and `Remove` hold a task number. `usize` is the natural type for a number that refers to a position in a list. Deriving `Debug` and `PartialEq` again makes the enum testable. Enum variants are always as public as the enum itself, so they do not need their own `pub`.

### Step 2: Parse Input into a Command

Add the parser and a small helper:

```rust
pub fn parse_command(input: &str) -> Result<Command, String> {
    let input = input.trim();
    let (word, rest) = match input.split_once(' ') {
        Some((word, rest)) => (word, rest.trim()),
        None => (input, ""),
    };

    match word {
        "add" => {
            if rest.is_empty() {
                Err(String::from("usage: add <task title>"))
            } else {
                Ok(Command::Add(rest.to_string()))
            }
        }
        "list" => Ok(Command::List),
        "done" => Ok(Command::Done(parse_number(rest)?)),
        "remove" => Ok(Command::Remove(parse_number(rest)?)),
        "help" => Ok(Command::Help),
        "quit" => Ok(Command::Quit),
        "" => Err(String::from("please type a command, or 'help'")),
        other => Err(format!("unknown command '{other}', type 'help'")),
    }
}

fn parse_number(text: &str) -> Result<usize, String> {
    text.parse()
        .map_err(|_| format!("'{text}' is not a task number"))
}
```

`split_once(' ')` splits the input at the first space and returns an `Option` with the two parts, or `None` if there is no space. The `match` turns both cases into a `(word, rest)` tuple: for `add Buy milk`, the word is `add` and the rest is `Buy milk`; for `list`, the word is `list` and the rest is empty. Shadowing (Lesson 3) reuses the name `input` for the trimmed text.

The second `match` compares the command word against text patterns and builds the matching variant. `add` requires a title. `done` and `remove` use `parse_number`, and the `?` returns its error if the rest is not a number (Lesson 15). The last two arms handle an empty line and an unknown word. `parse_number` is not marked `pub`, because only this module uses it, a small example of the privacy rules from Lesson 17.

---

## 5. Manage the List

The tasks could simply live in a `Vec<Task>` in `main`, but then any code could change the vector in any way, for example by removing an element with an index that does not exist. Wrapping the vector in a struct with methods lets the module enforce its rules: task numbers are always checked, and the file format is handled in one place.

### Step 1: Wrap the Vector in a Struct

Add the `TodoList` struct and the first methods:

```rust
pub struct TodoList {
    tasks: Vec<Task>,
}

impl TodoList {
    pub fn new() -> TodoList {
        TodoList { tasks: Vec::new() }
    }

    pub fn tasks(&self) -> &[Task] {
        &self.tasks
    }

    pub fn pending_count(&self) -> usize {
        self.tasks.iter().filter(|task| !task.done).count()
    }

    pub fn add(&mut self, title: &str) {
        self.tasks.push(Task::new(title));
    }
```

The struct is public, but its `tasks` field is private, so code outside the module cannot change the vector directly. Instead, `tasks()` returns a read only slice (Lesson 10): `main.rs` can loop over the tasks and count them, but not modify them. `pending_count` counts the tasks that are not done with `filter` and `count` (Lesson 13). `add` takes `&mut self` because it changes the list. The `impl` block stays open.

### Step 2: Complete and Remove Tasks Safely

Add the methods that work with task numbers:

```rust
    pub fn complete(&mut self, number: usize) -> Result<&Task, String> {
        let index = self.index_of(number)?;
        self.tasks[index].done = true;
        Ok(&self.tasks[index])
    }

    pub fn remove(&mut self, number: usize) -> Result<Task, String> {
        let index = self.index_of(number)?;
        Ok(self.tasks.remove(index))
    }

    fn index_of(&self, number: usize) -> Result<usize, String> {
        if number == 0 || number > self.tasks.len() {
            return Err(format!("there is no task number {number}"));
        }
        Ok(number - 1)
    }
```

Users see tasks numbered from 1, but vectors are indexed from 0. The private helper `index_of` does that conversion in one place and rejects numbers that do not exist, so a typo like `done 9` produces an error message instead of an out of bounds panic (Lesson 13).

`complete` marks the task as done and returns a reference to it, so the caller can show the title. `remove` uses `Vec::remove` and returns the removed `Task` itself, moving ownership out of the list to the caller (Lesson 9). Both use `?` to pass on the error from `index_of`.

### Step 3: Load and Save the File

Add the last two methods and close the `impl` block:

```rust
    pub fn load(path: &str) -> Result<TodoList, String> {
        let mut list = TodoList::new();
        if !Path::new(path).exists() {
            return Ok(list);
        }
        let content =
            fs::read_to_string(path).map_err(|error| format!("could not read {path}: {error}"))?;
        for line in content.lines() {
            if line.trim().is_empty() {
                continue;
            }
            list.tasks.push(Task::from_line(line)?);
        }
        Ok(list)
    }

    pub fn save(&self, path: &str) -> Result<(), String> {
        let mut content = String::new();
        for task in &self.tasks {
            content.push_str(&task.to_line());
            content.push('\n');
        }
        fs::write(path, content).map_err(|error| format!("could not write {path}: {error}"))
    }
}
```

`load` is an associated function that builds a list from a file. The first time the program runs, there is no file yet, which is not an error: `Path::new(path).exists()` checks for the file, and if it is missing, `load` returns an empty list. Otherwise it reads the file (Lesson 17) and converts each non empty line with `Task::from_line`. If any line is damaged, `?` returns the error, and the program refuses to start rather than silently losing data.

`save` builds the file content with one `to_line` per task and writes it with `fs::write`. The `map_err` call is the tail expression: `fs::write` returns `Result<(), io::Error>`, and `map_err` converts it to the `Result<(), String>` that `save` promises.

---

## 6. Build the Command Loop

With the logic finished, `main.rs` only needs to connect it to the user: show a prompt, read a line, parse it, run the command, and save. That is a `loop` with a `match` inside, built from pieces you know from Lessons 6, 8, and 12.

### Step 1: Write main

Replace the contents of `src/main.rs` with:

```rust
mod todo;

use std::io;
use std::io::Write;

use todo::{Command, TodoList, parse_command};

const FILE_PATH: &str = "tasks.txt";

fn main() -> Result<(), String> {
    let mut list = TodoList::load(FILE_PATH)?;
    println!("Rust To-Do List: {} task(s) loaded.", list.tasks().len());
    println!("Type 'help' to see the commands.");

    loop {
        let input = read_line("> ")?;
        let command = match parse_command(&input) {
            Ok(command) => command,
            Err(message) => {
                println!("Error: {message}");
                continue;
            }
        };

        match command {
            Command::Add(title) => {
                list.add(&title);
                println!("Added task {}: {title}", list.tasks().len());
            }
            Command::List => print_tasks(&list),
            Command::Done(number) => match list.complete(number) {
                Ok(task) => println!("Completed: {}", task.title),
                Err(message) => println!("Error: {message}"),
            },
            Command::Remove(number) => match list.remove(number) {
                Ok(task) => println!("Removed: {}", task.title),
                Err(message) => println!("Error: {message}"),
            },
            Command::Help => print_help(),
            Command::Quit => {
                println!("Goodbye!");
                break;
            }
        }

        list.save(FILE_PATH)?;
    }
    Ok(())
}
```

`mod todo;` declares the module, and `use` brings in the items `main` needs. The file name is a constant of type `&str`, so it is written once and used for both loading and saving.

`main` returns `Result<(), String>`, so `?` can be used for problems that should stop the program: a damaged save file, or a file that cannot be written. Problems the user can fix by typing again are handled inside the loop instead. If `parse_command` returns an error, the program prints it and `continue` starts the next iteration with a fresh prompt.

The second `match` handles every `Command` variant, and the compiler guarantees that none is forgotten (Lesson 12). `Done` and `Remove` call methods that return `Result`, so they have a nested `match` that prints either the success message or the error. `Quit` prints a goodbye and leaves the loop with `break`. After every other command, the list is saved, so no work is lost even if the terminal is closed. Saving after `list` or `help` is not strictly necessary, but saving in one place keeps the loop simple.

### Step 2: Add the Helper Functions

Add three helpers below `main`:

```rust
fn print_tasks(list: &TodoList) {
    if list.tasks().is_empty() {
        println!("No tasks yet. Add one with: add <task title>");
        return;
    }
    for (index, task) in list.tasks().iter().enumerate() {
        println!("{:>2}. {task}", index + 1);
    }
    println!(
        "{} of {} task(s) still pending.",
        list.pending_count(),
        list.tasks().len()
    );
}

fn print_help() {
    println!("Commands:");
    println!("  add <title>     add a new task");
    println!("  list            show all tasks");
    println!("  done <number>   mark a task as done");
    println!("  remove <number> delete a task");
    println!("  help            show this help");
    println!("  quit            save and exit");
}

fn read_line(prompt: &str) -> Result<String, String> {
    print!("{prompt}");
    io::stdout()
        .flush()
        .map_err(|error| format!("could not write to the terminal: {error}"))?;
    let mut input = String::new();
    let bytes = io::stdin()
        .read_line(&mut input)
        .map_err(|error| format!("could not read input: {error}"))?;
    if bytes == 0 {
        return Ok(String::from("quit"));
    }
    Ok(input.trim().to_string())
}
```

`print_tasks` borrows the list immutably. It numbers the tasks from 1 with `enumerate`, right aligns the numbers, and prints each task with `{task}`, which uses the `Display` implementation from Section 3. `print_help` lists the commands.

`read_line` is the helper from Lesson 8, upgraded to return a `Result` instead of calling `expect`. One more detail: `read_line` on standard input returns the number of bytes it read, and 0 means the input has ended, for example when the user presses `Ctrl` + `D`. Without a check, the loop would read empty lines forever. Treating the end of input as `quit` lets the program finish cleanly.

---

## 7. Test the Logic

The functions in `todo.rs` contain all the rules of the application, so they are the parts worth testing. Because they do not print or read input, testing them is straightforward.

### Step 1: Add the Tests

Add this test module to the end of `src/todo.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_commands() {
        assert_eq!(
            parse_command("add Buy milk"),
            Ok(Command::Add(String::from("Buy milk")))
        );
        assert_eq!(parse_command("  list  "), Ok(Command::List));
        assert_eq!(parse_command("done 2"), Ok(Command::Done(2)));
        assert_eq!(parse_command("remove 1"), Ok(Command::Remove(1)));
        assert_eq!(parse_command("quit"), Ok(Command::Quit));
    }

    #[test]
    fn rejects_invalid_commands() {
        assert!(parse_command("add").is_err());
        assert!(parse_command("done two").is_err());
        assert!(parse_command("dance").is_err());
        assert!(parse_command("").is_err());
    }

    #[test]
    fn converts_tasks_to_lines_and_back() {
        let mut task = Task::new("Write | read files");
        task.done = true;
        let line = task.to_line();
        assert_eq!(line, "1|Write | read files");
        assert_eq!(Task::from_line(&line), Ok(task));
        assert!(Task::from_line("2|Unknown status").is_err());
    }

    #[test]
    fn completes_and_removes_tasks() {
        let mut list = TodoList::new();
        list.add("Buy milk");
        list.add("Call Dina");
        assert_eq!(list.pending_count(), 2);

        list.complete(1).unwrap();
        assert!(list.tasks()[0].done);
        assert_eq!(list.pending_count(), 1);

        let removed = list.remove(2).unwrap();
        assert_eq!(removed.title, "Call Dina");
        assert_eq!(list.tasks().len(), 1);
    }

    #[test]
    fn rejects_task_numbers_out_of_range() {
        let mut list = TodoList::new();
        list.add("Buy milk");
        assert!(list.complete(0).is_err());
        assert!(list.complete(2).is_err());
        assert!(list.remove(5).is_err());
    }
}
```

The tests follow the structure of the module. The first two check that valid input becomes the right `Command`, including input with extra spaces, and that invalid input becomes an error. Comparing whole enum values with `assert_eq!` is possible because `Command` derives `PartialEq` and `Debug`.

`converts_tasks_to_lines_and_back` is a round trip test: it converts a task to a line, converts the line back, and checks that the result equals the original. It deliberately uses a title containing `|`, the tricky case from Section 3. The last two tests exercise `TodoList` the way `main` does, including the edge cases 0 and numbers past the end of the list. Since the tests create their own `TodoList` values and never call `load` or `save`, they do not touch `tasks.txt`.

### Step 2: Run the Tests

```bash
cargo test
```

After Cargo's build messages, the test runner prints:

```text

running 5 tests
test todo::tests::converts_tasks_to_lines_and_back ... ok
test todo::tests::completes_and_removes_tasks ... ok
test todo::tests::rejects_invalid_commands ... ok
test todo::tests::rejects_task_numbers_out_of_range ... ok
test todo::tests::parses_commands ... ok

test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

```

All five tests pass. Remember that tests run in parallel, so the order of the lines may differ on your computer.

---

## 8. Run and Test

Your complete `src/main.rs` is the code from Section 6: the module declaration, the `use` lines, the `FILE_PATH` constant, `main`, and the three helper functions. `src/todo.rs` contains, from top to bottom: the three `use` lines, `Task` with its `impl` block and `Display` implementation (Section 3), `Command` and `parse_command` with `parse_number` (Section 4), `TodoList` with its `impl` block (Section 5), and the test module (Section 7).

Make sure there is no `tasks.txt` in the project folder yet, then start the program and try every command. The lines after each `>` prompt are what you type:

```bash
cargo run -q
```

```text
Rust To-Do List: 0 task(s) loaded.
Type 'help' to see the commands.
> help
Commands:
  add <title>     add a new task
  list            show all tasks
  done <number>   mark a task as done
  remove <number> delete a task
  help            show this help
  quit            save and exit
> list
No tasks yet. Add one with: add <task title>
> add Buy milk
Added task 1: Buy milk
> add Finish the Rust course
Added task 2: Finish the Rust course
> add Call Dina
Added task 3: Call Dina
> list
 1. [ ] Buy milk
 2. [ ] Finish the Rust course
 3. [ ] Call Dina
3 of 3 task(s) still pending.
> done 2
Completed: Finish the Rust course
> remove 3
Removed: Call Dina
> done 9
Error: there is no task number 9
> finish
Error: unknown command 'finish', type 'help'
> add
Error: usage: add <task title>
> list
 1. [ ] Buy milk
 2. [x] Finish the Rust course
1 of 2 task(s) still pending.
> quit
Goodbye!
```

Every command did what it should, and every mistake (a task number that does not exist, an unknown command, `add` without a title) produced a clear message while the program kept running. Now look at the file the program saved:

```bash
cat tasks.txt
```

```text
0|Buy milk
1|Finish the Rust course
```

The file uses exactly the format planned in Section 2. Finally, start the program again to confirm that the tasks survived:

```bash
cargo run -q
```

```text
Rust To-Do List: 2 task(s) loaded.
Type 'help' to see the commands.
> list
 1. [ ] Buy milk
 2. [x] Finish the Rust course
1 of 2 task(s) still pending.
> quit
Goodbye!
```

The list was loaded from `tasks.txt`, including the completed status. You now have a working, tested, persistent command-line application written entirely with the Rust standard library.

---

## 9. Fix the Errors in Your Code

A larger program produces errors that combine several concepts. These are the ones you are most likely to meet while building or extending the to-do list.

**Error 1: Adding a command variant without handling it.**

```rust
// Wrong: Clear is added to the enum...
pub enum Command {
    Add(String),
    List,
    Done(usize),
    Remove(usize),
    Help,
    Quit,
    Clear,
}
// ...but main's match has no arm for it.

// Correct: add an arm in main's match
Command::Clear => {
    let removed = list.clear_completed();
    println!("Removed {removed} completed task(s).");
}
```

When a variant is added but not handled, the build fails with ``error[E0004]: non-exhaustive patterns: `todo::Command::Clear` not covered``, pointing at the `match` in `main.rs` and at the new variant in `todo.rs`. This is the exhaustiveness check from Lesson 12 working for you: it is impossible to add a command and forget to implement it. (`clear_completed` is the method you will write in Exercise 1.)

**Error 2: Using the list while a returned reference is still alive.**

```rust
// Wrong
Command::Done(number) => match list.complete(number) {
    Ok(task) => {
        list.save(FILE_PATH)?;
        println!("Completed: {}", task.title);
    }
    Err(message) => println!("Error: {message}"),
},

// Correct
Command::Done(number) => match list.complete(number) {
    Ok(task) => println!("Completed: {}", task.title),
    Err(message) => println!("Error: {message}"),
},
```

The wrong version produces ``error[E0502]: cannot borrow `list` as immutable because it is also borrowed as mutable``. `complete` borrows `list` mutably and returns `task`, a reference into the list, so the mutable borrow lasts as long as `task` is used. Calling `save` in between would read the list while that borrow is still active (Lesson 10). The correct version uses `task` first and leaves saving to the single `list.save` call after the `match`, when no reference is alive anymore.

**Error 3: Splitting the saved line at every `|`.**

```rust
// Wrong
let parts: Vec<&str> = line.split('|').collect();

// Correct
let parts: Vec<&str> = line.splitn(2, '|').collect();
```

The wrong version compiles and works for most titles, but `cargo test` catches the problem:

```text
failures:

---- todo::tests::converts_tasks_to_lines_and_back stdout ----

thread 'todo::tests::converts_tasks_to_lines_and_back' (66651) panicked at src/todo.rs:183:9:
assertion `left == right` failed
  left: Err("invalid task line: '1|Write | read files'")
 right: Ok(Task { title: "Write | read files", done: true })
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    todo::tests::converts_tasks_to_lines_and_back

test result: FAILED. 4 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

With `split`, the line `1|Write | read files` becomes three parts, and `from_line` rejects it. A user who added such a task would find the program unable to start the next time. `splitn(2, '|')` splits only at the first `|`, keeping the rest of the title intact. This is exactly the kind of bug that round trip tests are good at finding.

**Error 4: A damaged save file.**

If `tasks.txt` is edited by hand and a line gets an invalid status, for example `2|Finish the Rust course`, the program refuses to start:

```text
Error: "invalid status '2' in line '2|Finish the Rust course'"
```

This is deliberate: `load` uses `?`, so a damaged file stops the program instead of silently dropping tasks. The message names the exact line, so the fix is to open `tasks.txt` and change the flag back to `0` or `1`.

---

## 10. Exercises

Each exercise extends the to-do list. For every new command, you will need to add a variant to `Command`, a case in `parse_command`, a method on `TodoList` where appropriate, an arm in `main`'s `match`, and a line in `print_help`. Add a test for each new method.

**Exercise 1:** Add a `clear` command that deletes all completed tasks and reports how many were removed. Implement it as `TodoList::clear_completed(&mut self) -> usize`, using `Vec::retain`, which keeps only the elements for which a closure returns `true`.

**Exercise 2:** Add an `undone <number>` command that marks a completed task as not done again. Implement it as `TodoList::reopen`, following the pattern of `complete`.

**Exercise 3:** Add a `find <text>` command that shows every task whose title contains the text, ignoring upper and lower case, together with each task's real number in the list. Implement it as `TodoList::find(&self, text: &str) -> Vec<(usize, &Task)>`, using `iter`, `enumerate`, `filter`, `map`, and `collect`.

---

## 11. Solutions

**Solution for Exercise 1:**

In `src/todo.rs`, add a `Clear` variant to `Command`, and this arm to the `match` in `parse_command`:

```rust
        "clear" => Ok(Command::Clear),
```

Add the method to `impl TodoList`:

```rust
    pub fn clear_completed(&mut self) -> usize {
        let before = self.tasks.len();
        self.tasks.retain(|task| !task.done);
        before - self.tasks.len()
    }
```

`retain` walks through the vector and keeps every task for which the closure returns `true`, that is, every task that is not done. Comparing the length before and after gives the number of removed tasks. Add the arm shown in Error 1 of Section 9 to `main`'s `match`, and a help line such as `println!("  clear           delete all completed tasks");`. The test:

```rust
    #[test]
    fn clears_completed_tasks() {
        let mut list = TodoList::new();
        list.add("Buy milk");
        list.add("Call Dina");
        list.add("Pay bills");
        list.complete(1).unwrap();
        list.complete(3).unwrap();
        assert_eq!(list.clear_completed(), 2);
        assert_eq!(list.tasks().len(), 1);
        assert_eq!(list.tasks()[0].title, "Call Dina");
    }
```

The test completes the first and third tasks and checks that only the middle one remains.

**Solution for Exercise 2:**

Add an `Undone(usize)` variant to `Command`, and this arm to `parse_command`:

```rust
        "undone" => Ok(Command::Undone(parse_number(rest)?)),
```

Add the method to `impl TodoList`:

```rust
    pub fn reopen(&mut self, number: usize) -> Result<&Task, String> {
        let index = self.index_of(number)?;
        self.tasks[index].done = false;
        Ok(&self.tasks[index])
    }
```

It is `complete` with `false` instead of `true`; `index_of` is reused for the number check. In `main`'s `match`, add:

```rust
            Command::Undone(number) => match list.reopen(number) {
                Ok(task) => println!("Marked as not done: {}", task.title),
                Err(message) => println!("Error: {message}"),
            },
```

Add the help line `println!("  undone <number> mark a task as not done");` and this test:

```rust
    #[test]
    fn reopens_a_completed_task() {
        let mut list = TodoList::new();
        list.add("Buy milk");
        list.complete(1).unwrap();
        list.reopen(1).unwrap();
        assert!(!list.tasks()[0].done);
        assert!(list.reopen(2).is_err());
    }
```

**Solution for Exercise 3:**

Add a `Find(String)` variant to `Command`, and this arm to `parse_command`, which mirrors the `add` arm:

```rust
        "find" => {
            if rest.is_empty() {
                Err(String::from("usage: find <text>"))
            } else {
                Ok(Command::Find(rest.to_string()))
            }
        }
```

Add the method to `impl TodoList`:

```rust
    pub fn find(&self, text: &str) -> Vec<(usize, &Task)> {
        let text = text.to_lowercase();
        self.tasks
            .iter()
            .enumerate()
            .filter(|(_, task)| task.title.to_lowercase().contains(&text))
            .map(|(index, task)| (index + 1, task))
            .collect()
    }
```

Both the search text and each title are converted to lowercase, so `rust` finds `Rust` and `RUST`. `enumerate` attaches each task's index *before* filtering, so the numbers in the result are the real positions in the list, which the user can then pass to `done` or `remove`. The closures destructure the `(index, task)` tuples, and `map` converts each index to a number starting at 1. In `main`'s `match`, add:

```rust
            Command::Find(text) => {
                let found = list.find(&text);
                if found.is_empty() {
                    println!("No task contains '{text}'.");
                }
                for (number, task) in found {
                    println!("{number:>2}. {task}");
                }
            }
```

Add the help line `println!("  find <text>     search tasks by title");` and this test:

```rust
    #[test]
    fn finds_tasks_ignoring_case() {
        let mut list = TodoList::new();
        list.add("Buy milk");
        list.add("Read the Rust book");
        list.add("Buy RUST stickers");
        let found = list.find("rust");
        assert_eq!(found.len(), 2);
        assert_eq!(found[0].0, 2);
        assert_eq!(found[1].1.title, "Buy RUST stickers");
    }
```

With all three exercises in place, `cargo test` reports `8 passed`. Delete `tasks.txt` and try the new commands in a session:

```text
Rust To-Do List: 0 task(s) loaded.
Type 'help' to see the commands.
> add Buy milk
Added task 1: Buy milk
> add Read the Rust book
Added task 2: Read the Rust book
> add Buy RUST stickers
Added task 3: Buy RUST stickers
> done 1
Completed: Buy milk
> done 3
Completed: Buy RUST stickers
> find rust
 2. [ ] Read the Rust book
 3. [x] Buy RUST stickers
> find bread
No task contains 'bread'.
> undone 3
Marked as not done: Buy RUST stickers
> done 1
Completed: Buy milk
> list
 1. [x] Buy milk
 2. [ ] Read the Rust book
 3. [ ] Buy RUST stickers
2 of 3 task(s) still pending.
> clear
Removed 1 completed task(s).
> list
 1. [ ] Read the Rust book
 2. [ ] Buy RUST stickers
2 of 2 task(s) still pending.
> quit
Goodbye!
```

`find rust` found both titles regardless of case and showed their real numbers, `undone 3` reopened a task, and `clear` removed the one task that was still completed.

---

## 12. Course Wrap-Up and Next Steps

Congratulations: you have finished the course. You started in Lesson 1 without knowing what a compiler was, and you have just built a tested, persistent command-line application. Take a moment to look back at the path:

- **Module 1** installed the toolchain and showed the compile and run workflow with `rustc` and Cargo.
- **Modules 2 to 4** covered the fundamentals shared by almost every language: variables, types, operators, decisions, loops, functions, and user input.
- **Module 5** taught ownership and borrowing, the ideas that make Rust memory safe without a garbage collector.
- **Modules 6 and 7** gave you the tools to model real data: structs, enums, `Option`, vectors, strings, hash maps, iterators, and closures.
- **Module 8** covered reliable error handling with `Result` and `?`, and shared behavior with traits and generics.
- **Module 9** organized code into modules, worked with files, added tests, and brought everything together in this project.

Just as important as any single feature, you have practiced reading compiler messages, testing your assumptions, and fixing errors methodically. Those habits carry over to every language you will ever use.

Here are some good directions for what to learn next:

- **Keep improving the to-do list.** Add due dates, priorities, or an `edit <number> <title>` command. Each feature is a chance to practice enums, parsing, and tests.
- **Read The Rust Programming Language.** [The Rust Book](https://doc.rust-lang.org/book/) is free online and goes deeper into every topic in this course, plus lifetimes, smart pointers, concurrency, and more.
- **Practice with small exercises.** [Rustlings](https://github.com/rust-lang/rustlings) offers short exercises you fix one by one, and [Rust by Example](https://doc.rust-lang.org/rust-by-example/) shows runnable examples for each language feature.
- **Use crates from the ecosystem.** This course used only the standard library on purpose. The next step is adding dependencies to `Cargo.toml` from [crates.io](https://crates.io/), for example `rand` for random numbers (a real guessing game), `serde` for saving data as JSON, or `clap` for professional command-line arguments.
- **Build something you need.** A small tool that renames files, summarizes a CSV export, or tracks your expenses will teach you more than any tutorial, because you will meet real problems and solve them with the tools you now have.

Thank you for learning Rust with qadrlabs. Keep the compiler as your mentor, keep your tests green, and keep building.
