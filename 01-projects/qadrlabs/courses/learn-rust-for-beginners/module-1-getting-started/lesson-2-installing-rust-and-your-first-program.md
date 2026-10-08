## 1. Before You Begin

In Lesson 1 you ran a Rust program in the Playground, where a remote server did the compiling for you. That is a great way to experiment, but real projects live on your own computer. In this lesson you will install the Rust toolchain on Ubuntu, compile a program by hand so you can see every step of the workflow, and then create your first Cargo project, the way every remaining lesson in this course is organized.

By the end of this lesson, you will have a `rust-basics` folder in your home directory. Every later lesson adds a new project inside it, so all your course work stays in one place.

### What You'll Build

Two versions of the classic Hello World program. The first is a single file, `main.rs`, compiled directly with `rustc`. The second is a Cargo project called `hello_cargo` that you build, check, and run with Cargo commands.

### What You'll Learn

- ✅ What `rustup`, `rustc`, and `cargo` each do
- ✅ How to install Rust on Ubuntu with the official installer
- ✅ How to verify the installation from the terminal
- ✅ How to compile and run a single file with `rustc`
- ✅ How to create a project with `cargo new` and what each generated file is for
- ✅ The difference between `cargo build`, `cargo run`, and `cargo check`
- ✅ The difference between debug and release builds

### What You'll Need

- Ubuntu (or another Debian based Linux distribution) with a Bash terminal
- Permission to install system packages with `sudo`
- An internet connection to download the toolchain (a few hundred megabytes)
- A text editor; this lesson mentions Visual Studio Code, but any editor works

---

## 2. Install the Rust Toolchain

A Rust installation is not a single program but a small set of tools that work together. Knowing their names makes every command in this course easier to understand.

| Tool | Responsibility |
| --- | --- |
| `rustup` | Installs Rust and keeps it up to date; manages toolchain versions |
| `rustc` | The Rust compiler; turns `.rs` source files into executables |
| `cargo` | Rust's project manager; creates projects, builds them, runs them, and more |

You will mostly type `cargo` commands. Cargo calls `rustc` for you behind the scenes, and `rustup` only matters when you install or update Rust.

### Step 1: Prepare Ubuntu's Packages

Open a terminal (press `Ctrl` + `Alt` + `T` on Ubuntu) and run:

```bash
sudo apt update
sudo apt install curl build-essential
```

`sudo` runs a command with administrator rights, so Ubuntu asks for your password. `apt update` refreshes Ubuntu's list of available packages. `apt install curl build-essential` installs two things: `curl`, a tool that downloads files from the internet (the Rust installer uses it), and `build-essential`, a bundle of build tools including a C compiler and linker. The Rust compiler needs a linker to combine compiled code into the final executable, which is why the [Rust installation guide](https://doc.rust-lang.org/book/ch01-01-installation.html) recommends this package on Ubuntu.

### Step 2: Run the Official Installer

Run the following command as your normal user, without `sudo`:

```bash
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
```

This command has two halves joined by the pipe character `|`. The left half uses `curl` to download the `rustup` installer script from `sh.rustup.rs`. The options `--proto '=https' --tlsv1.2` force a secure HTTPS connection, `-s` hides the download progress bar, `-S` still shows errors if something fails, and `-f` makes `curl` fail cleanly on a server error instead of saving an error page. The pipe sends the downloaded script to `sh`, which runs it. Rust is installed inside your home directory, so administrator rights are not needed.

The installer asks how you want to proceed:

```text
1) Proceed with standard installation (default - just press enter)
2) Customize installation
3) Cancel installation
>

```

Press **Enter** to choose the standard installation. It installs the latest stable version of Rust with the default set of components. The installer then prints progress messages while it downloads:

```text

info: profile set to default
info: default host tuple is x86_64-unknown-linux-gnu
info: syncing channel updates for stable-x86_64-unknown-linux-gnu
info: latest update on 2026-10-01 for version 1.99.0 (b940084d7 2026-09-28)
info: downloading 6 components
        cargo installed                       10.45 MiB                                clippy installed                        4.99 MiB  
.
.
.
.
.
.
```

The exact version numbers and dates depend on when you install. Wait until the installer finishes and reports that Rust is installed.

### Step 3: Load Rust into Your Current Terminal

The installer adds Rust's tools to a folder called `$HOME/.cargo/bin` and updates your shell configuration so new terminals can find them. The terminal you are using right now was opened before the installation, so load the new settings into it:

```bash
source "$HOME/.cargo/env"
```

`source` runs the commands in a file inside the current shell. The `env` file adds `$HOME/.cargo/bin` to your `PATH`, the list of folders Bash searches when you type a command name. You only need this once; any terminal you open from now on picks up the setting automatically.

### Step 4: Verify the Installation

Check that the compiler and Cargo are available:

```bash
rustc --version
cargo --version
```

Each command prints its version:

```text
$ rustc --version
cargo --version
rustc 1.99.0 (b940084d7 2026-09-28)
cargo 1.99.0 (5f94df478 2026-08-27)
```

The numbers on your computer may be newer; everything in this course works with Rust 1.99 or later. If Bash reports `command not found`, the installation did not finish or the environment was not loaded. Run the `source` command from Step 3 again, or close the terminal and open a new one.

---

## 3. Compile a Program by Hand with rustc

Before using Cargo, it is worth seeing the compile and run workflow with nothing hidden. You will write one source file, compile it into an executable with `rustc`, and run that executable yourself.

### Step 1: Create a Course Folder

Create a folder for all your course projects and a subfolder for this first program:

```bash
mkdir -p ~/rust-basics/hello_world
cd ~/rust-basics/hello_world
```

`mkdir -p` creates a directory, including any missing parent directories (here, `rust-basics` and then `hello_world` inside it). The `~` is a shortcut for your home directory, such as `/home/yourname`. `cd` changes the terminal's current directory, so the next commands run inside `hello_world`.

If Visual Studio Code is installed and its `code` command is available, open the current folder in the editor:

```bash
code .
```

The `.` means "the current directory." Any other text editor works too, as long as it saves plain text files.

### Step 2: Write the Source File

Create a new file named `main.rs` in the `hello_world` folder and enter the following code:

```rust
fn main() {
    // Print a greeting followed by a newline.
    println!("Hello, world!");
}
```

The `.rs` extension tells tools that this file contains Rust source code. `fn main()` declares the `main` function, the entry point where the program starts. The comment on the second line is ignored by the compiler. `println!("Hello, world!");` calls the `println!` macro, which prints the text inside the quotes and then moves to a new line. The semicolon ends the statement, and the closing brace ends the function. This is the same program from [the Hello World chapter of The Rust Book](https://doc.rust-lang.org/book/ch01-02-hello-world.html).

### Step 3: Compile and Run

Save the file, go back to the terminal, and compile it:

```bash
rustc main.rs
```

If the code is correct, `rustc` prints nothing at all. In the world of command-line tools, silence usually means success. List the folder's contents to see what the compiler produced:

```bash
ls
```

```text
main
main.rs
```

There are now two files. `main.rs` is your source code. `main` is the executable that `rustc` created, named after the source file without its extension. Run it:

```bash
./main
```

```text
Hello, world!
```

The `./` prefix tells Bash to run the `main` file in the current directory. Without it, Bash would search only the folders in your `PATH` and report that the command was not found.

### Step 4: Prove That Compiling Is a Separate Step

Change the greeting in `main.rs` to `"Hello, Rust!"` and save the file. Now run `./main` again without compiling. It still prints `Hello, world!`. The executable is a separate file that was built from the old source; it does not know the source changed. Run `rustc main.rs` and then `./main`, and the new greeting appears.

This is the most important idea in this lesson: in a compiled language, every change to the source needs a new build before the executable reflects it.

---

## 4. Create Your First Cargo Project

Compiling one file by hand is fine for a single program, but real projects have many files, settings such as the program's name and version, and often external libraries. Cargo handles all of that with a standard project layout and a handful of commands. From Lesson 3 onward, every program in this course is a Cargo project.

### Step 1: Generate the Project

Go back to the course folder and ask Cargo to create a new project:

```bash
cd ~/rust-basics
cargo new hello_cargo
cd hello_cargo
```

`cargo new hello_cargo` creates a folder called `hello_cargo` with everything a Rust program needs. Cargo prints a short confirmation:

```text
    Creating binary (application) `hello_cargo` package
note: see more `Cargo.toml` keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html
```

"Binary (application)" means the project produces an executable you can run, as opposed to a library that other programs use. The `note` line points to the documentation for the `Cargo.toml` file, which you will look at next.

### Step 2: Explore the Generated Files

List everything in the project folder, including hidden files:

```bash
ls -a
```

```text
.
..
.git
.gitignore
Cargo.toml
src
```

`.` and `..` are shortcuts for the current and parent folder and appear in every `ls -a` listing. `.git` and `.gitignore` show that Cargo also initialized a Git repository so you can track changes; you do not need Git for this course, so you can ignore them. (If you create the project inside a folder that is already a Git repository, Cargo skips this step.) The two files that matter are `Cargo.toml` and the `src` folder.

Open `Cargo.toml`:

```toml
[package]
name = "hello_cargo"
version = "0.1.0"
edition = "2024"

[dependencies]
```

This file is the project's manifest, written in a simple settings format called TOML. The `[package]` section describes the project: its `name`, its `version`, and the Rust `edition` it uses. An edition is a set of language conventions; `2024` is the current one, and you never need to change it in this course. The `[dependencies]` section lists external libraries the project uses. It is empty, and it stays empty for the whole course because you will only use Rust's standard library.

Now open `src/main.rs`:

```rust
fn main() {
    println!("Hello, world!");
}
```

Cargo generated the same Hello World program you wrote by hand. By convention, source code lives in the `src` folder and the entry point of an application is `src/main.rs`.

### Step 3: Build and Run with Cargo

Build the project:

```bash
cargo build
```

Cargo prints a `Compiling hello_cargo v0.1.0 (...)` line showing the project name, version, and folder, followed by a `Finished` line that names the build profile and how long it took. Cargo called `rustc` for you and placed the executable in a new `target/debug` folder. Run it directly:

```bash
./target/debug/hello_cargo
```

```text
Hello, world!
```

Typing that path every time would be tedious, so Cargo combines both steps into one command:

```bash
cargo run
```

`cargo run` builds the project if anything changed and then runs the executable. When you run it right after `cargo build`, there is nothing new to compile, so Cargo prints only a `Finished` line, then ``Running `target/debug/hello_cargo` ``, then your program's output:

```text
Hello, world!
```

The lines that start with `Compiling`, `Finished`, and `Running` come from Cargo, not from your program. They are useful for seeing what Cargo did. When you only want to see the program's output, add `--quiet` (or its short form `-q`):

```bash
cargo run -q
```

```text
Hello, world!
```

### Step 4: Check Your Code Without Building

As programs grow, compiling takes longer. When you only want to know whether your code is valid, use:

```bash
cargo check
```

`cargo check` runs all of the compiler's checks but skips producing an executable, so it is faster than `cargo build`. Cargo reports `Checking hello_cargo v0.1.0 (...)` instead of `Compiling`, followed by a `Finished` line. Many Rust programmers run `cargo check` frequently while writing code and `cargo run` when they want to see the result.

---

## 5. Run and Test

Confirm that everything from this lesson works before moving on. From `~/rust-basics/hello_cargo`, open `src/main.rs` and change it to print two lines:

```rust
fn main() {
    println!("Hello, world!");
    println!("My Rust toolchain works.");
}
```

The second `println!` adds a new line of output. Statements inside `main` run from top to bottom, so the greeting prints first. Save the file and run:

```bash
cargo run -q
```

```text
Hello, world!
My Rust toolchain works.
```

Notice that you did not run `cargo build` first. `cargo run` noticed that `src/main.rs` changed and rebuilt the project automatically before running it. That is the main convenience Cargo adds over calling `rustc` by hand.

Your `rust-basics` folder now contains two projects:

```text
rust-basics/
├── hello_world/
│   ├── main
│   └── main.rs
└── hello_cargo/
    ├── Cargo.toml
    ├── src/
    │   └── main.rs
    └── target/
```

`hello_cargo` also contains `Cargo.lock`, created by the first build to record exact dependency versions, plus the hidden Git files. Every lesson from now on creates a new Cargo project next to these.

---

## 6. Debug and Release Builds

The `Finished` line from `cargo build` mentions the `dev` profile, described as `[unoptimized + debuginfo]`. This is a debug build: it compiles quickly and includes extra information that helps when tracking down problems, but the resulting program runs slower than it could.

When a program is ready to share or measure, build it in release mode:

```bash
cargo build --release
```

Cargo now uses the `release` profile, described as `[optimized]`, and places the executable in `target/release` instead of `target/debug`. The compiler spends more time optimizing the code, so release builds take longer to compile but run faster. For learning, the default debug build is the right choice; you will not need release builds in this course, but it is useful to know why there are two folders inside `target`.

The `target` folder only contains generated files. You can delete it at any time with `cargo clean`, and Cargo recreates it on the next build.

---

## 7. Fix the Errors in Your Code

These are the most common problems when installing Rust and running a first project.

**Error 1: Running Cargo commands outside the project folder.**

Cargo looks for `Cargo.toml` in the current folder (and its parents) to know which project to build. If you run `cargo run` from the wrong place, Cargo cannot find a project.

```bash
# Wrong: running from the course folder, which has no Cargo.toml
cd ~/rust-basics
cargo run

# Correct: run from inside the project folder
cd ~/rust-basics/hello_cargo
cargo run
```

From `~/rust-basics`, Cargo reports ``error: could not find `Cargo.toml` in `/home/yourname/rust-basics` or any parent directory`` (with your own home folder in the path). The fix is to `cd` into the project folder first. When in doubt, run `ls` and check that `Cargo.toml` is listed.

**Error 2: Running the executable without `./`.**

Bash only searches the folders listed in `PATH` for commands. The current folder is not one of them, for security reasons.

```bash
# Wrong
main

# Correct
./main
```

The wrong version produces `main: command not found` (or a suggestion to install a package with a similar name). Adding `./` tells Bash to run the file in the current folder.

**Error 3: Expecting a source change to appear without recompiling.**

When you compile with `rustc` by hand, the executable never updates itself. This is not an error message, but it is the most confusing early mistake because the program "ignores" your edits.

```bash
# Wrong: edit main.rs, then run the old executable
./main

# Correct: recompile, then run
rustc main.rs
./main
```

The wrong version keeps printing the old output because `main` was built from the old source. Recompiling creates a new executable from the current source. With Cargo, `cargo run` handles this automatically, which is one of the reasons you will use it from now on.

---

## 8. Exercises

**Exercise 1:** Run `rustup --version`, `rustc --version`, and `cargo --version`, and write down what each tool is responsible for in one sentence.

**Exercise 2:** Create a new Cargo project called `about_me` inside `~/rust-basics`. Change `src/main.rs` so it prints three lines: your name, your favorite food, and one thing you want to build with Rust. Run it with `cargo run`.

**Exercise 3:** In the `about_me` project, run `cargo build --release`. Then run the release executable directly from the terminal without using `cargo run`. Which path did you use?

---

## 9. Solutions

**Solution for Exercise 1:**

```bash
rustup --version
rustc --version
cargo --version
```

Each command prints the version of one tool. `rustup` installs Rust and keeps it updated. `rustc` is the compiler that turns `.rs` files into executables. `cargo` is the project manager that creates projects, calls `rustc` to build them, and runs the result. The exact numbers on your computer depend on when you installed Rust. Running `rustup update` later downloads newer versions when they are released.

**Solution for Exercise 2:**

```bash
cd ~/rust-basics
cargo new about_me
cd about_me
```

These commands create the project and move into its folder. Replace the contents of `src/main.rs` with:

```rust
fn main() {
    println!("My name is Dina.");
    println!("My favorite food is nasi goreng.");
    println!("I want to build a command-line tool with Rust.");
}
```

Each `println!` prints one line, in order from top to bottom. Run it with `cargo run`. After Cargo's build messages, the program prints:

```text
My name is Dina.
My favorite food is nasi goreng.
I want to build a command-line tool with Rust.
```

Your three lines will contain your own answers.

**Solution for Exercise 3:**

```bash
cargo build --release
./target/release/about_me
```

`cargo build --release` builds an optimized executable in `target/release`. The executable is named after the package name in `Cargo.toml`, so the path is `./target/release/about_me`. Running it prints the same three lines as before. The debug executable from `cargo run` lives in `target/debug/about_me`; both are independent files built from the same source.

---

## Next Up - Lesson 3

In this lesson you installed Rust with `rustup`, verified `rustc` and `cargo`, compiled a single file by hand, and created your first Cargo project. You learned what `Cargo.toml` and `src/main.rs` are for, how `cargo build`, `cargo run`, and `cargo check` differ, and why debug and release builds live in separate folders.

In Lesson 3, you will start writing programs that work with data. You will create variables with `let`, learn why Rust variables cannot change unless you say so, and format output with `println!` placeholders.
