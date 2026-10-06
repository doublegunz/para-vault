# Getting to Know Rust: A First Look with Ubuntu and Hello World

An application that needs predictable performance also needs careful control over memory. Mistakes in that control can turn into crashes or security problems, and finding them after deployment is expensive. Rust approaches this problem by checking memory access rules during compilation, helping developers build efficient software while catching certain classes of errors before the program runs.

That is a useful starting point for understanding Rust beyond the posts and discussions surrounding it. This introduction explores what the language offers, installs its tools on Ubuntu, and uses a small Hello World program to make the compile-and-run workflow concrete.

## Overview {#overview}

The goal is to get a first impression of Rust through a working example. The program stays deliberately small so that the language, compiler, and project tools remain easy to distinguish.

### What You'll Build

- A terminal program that prints `Hello, world!`, first compiled directly and then created as a Cargo project.

### What You'll Learn

- What Rust is and where it is commonly used.
- How `rustup`, `rustc`, and Cargo fit together.
- How to install Rust on Ubuntu and run a simple program.
- What ownership and borrowing mean at an introductory level.

### What You'll Need

- Ubuntu with a Bash terminal and permission to install system packages using `sudo`.
- An internet connection to download the toolchain.
- A text editor and basic familiarity with terminal commands.

No previous Rust experience is required.

## What Is Rust? {#what-is-rust}

Rust is a compiled, statically typed programming language. The compiler checks types and turns source code into an executable before the program runs. For this first example, the result will be a binary that runs directly on Ubuntu.

Rust is useful when resource usage, reliability, and control over execution matter. Its applications include command-line tools, network services, embedded software, and WebAssembly modules. These are among the domains highlighted on the [official Rust website](https://rust-lang.org/).

The appeal is the combination of control and tooling: a language designed for efficient execution, a compiler that checks many mistakes early, and a standard tool for managing projects. Whether that combination suits a particular application still depends on its requirements and the team's experience.

## Installing Rust on Ubuntu {#installing-rust-on-ubuntu}

A Rust installation brings together several tools with different responsibilities. Knowing their names makes the terminal commands easier to understand.

| Tool | Responsibility |
| --- | --- |
| `rustup` | Installs and manages Rust toolchains and versions. |
| `rustc` | Compiles Rust source code. |
| `cargo` | Manages projects, builds, and dependencies. |

Prepare Ubuntu's system packages:

```bash
sudo apt update
sudo apt install curl build-essential
```

`apt update` refreshes package information. `curl` downloads the Rust installer, while `build-essential` provides the C compiler and related build tools used for linking. The [Rust installation guide](https://doc.rust-lang.org/book/ch01-01-installation.html) specifically identifies this package for Ubuntu.

Install Rust using the official command:

```bash
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
```

This downloads and runs the `rustup` installer over HTTPS. For a fresh installation, accept the default installation option to install the stable toolchain. Run this command as your normal user; the `sudo` commands above are for Ubuntu packages.

Output:

```text
1) Proceed with standard installation (default - just press enter)
2) Customize installation
3) Cancel installation
>

```

Press **Enter**, then wait for the downloads to finish. The installer displays progress messages:

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

Load the environment into the current Bash session:

```bash
source "$HOME/.cargo/env"
```

This makes the installed tools available through `PATH`. With the default installation, their commands live in `$HOME/.cargo/bin`, as described in the [rustup documentation](https://rust-lang.github.io/rustup/installation/index.html).

Check that both tools are available:

```bash
rustc --version
cargo --version
```

Output:

```text
$ rustc --version
cargo --version
rustc 1.99.0 (b940084d7 2026-09-28)
cargo 1.99.0 (5f94df478 2026-08-27)
```

Each command should report its version. The numbers depend on when Rust was installed. If Bash reports `command not found`, check that installation completed and reload the environment before continuing.

## A Small Hello World Program {#a-small-hello-world-program}

A single source file is enough to see what compiling Rust involves. Use a new directory so that the source and executable are easy to find:

```bash
mkdir -p ~/rust-introduction/hello_world
cd ~/rust-introduction/hello_world
```

These commands create the example directory and make it the terminal's current directory. 

If Visual Studio Code is installed and its `code` command is available, open the current folder with:

```bash
 code .
```

The `.` refers to the current directory, so this command opens the example folder in the editor.

Open a new file named `main.rs` there with your preferred text editor, enter the following code, and save it:

```rust
fn main() {
    // Print a greeting followed by a newline.
    println!("Hello, world!");
}
```

This complete program has one job: write a greeting to the terminal. From the directory containing the saved file, compile and run it:

```bash
rustc main.rs
./main
```

`rustc main.rs` creates an executable named `main`. `./main` runs that executable from the current directory. The expected program output is:

```text
Hello, world!
```

The `.rs` extension identifies Rust source. `fn main()` declares the program's entry point, and the braces contain its body. `println!` is a macro, indicated by `!`, that prints the supplied text with a newline. The semicolon ends the statement. This follows the [Hello World example in The Rust Book](https://doc.rust-lang.org/book/ch01-02-hello-world.html).

Try changing the greeting, saving the file, and running both commands again. The existing executable will keep its old behavior until the changed source is compiled.

## Where Cargo Fits In {#where-cargo-fits-in}

Compiling one file directly makes the process visible. A project also needs a consistent way to organize source files, record settings, and eventually use libraries. Cargo provides that structure and is included in the standard Rust installation.

Create a separate project alongside the first example:

```bash
cd ~/rust-introduction
cargo new hello_rust
cd hello_rust
```

Output:

```text
$ cd ~/rust-introduction 
cargo new hello_rust
cd hello_rust
    Creating binary (application) `hello_rust` package
note: see more `Cargo.toml` keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

```

`cargo new` generates a project directory. Its `Cargo.toml` file holds package configuration, and `src/main.rs` already contains a Hello World program. Open that file to compare it with the code written earlier. There is no need to add dependencies or replace the generated code for this example. The [Cargo introduction](https://doc.rust-lang.org/book/ch01-03-hello-cargo.html) explains this layout.

Run the project from its directory:

```bash
cargo run
```

Cargo coordinates compilation with `rustc`, then launches the resulting executable. It can reuse an existing build when nothing relevant has changed. The following terminal output includes Cargo's build and execution messages, followed by the program's greeting:

```text
:~/rust-introduction/hello_rust$ cargo run
   Compiling hello_rust v0.1.0 (/home/gun-gun-priatna/rust-introduction/hello_rust)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.09s
     Running `target/debug/hello_rust`
Hello, world!

```

For a view focused on the program's output, run:

```bash
cargo run --quiet
```

The `--quiet` option suppresses Cargo's log messages. The [command reference](https://doc.rust-lang.org/cargo/commands/cargo-run.html) documents this option. Cargo has made running the project more convenient, while the underlying idea remains the same: compile source code, then execute the result.

## What Makes Rust Different? {#what-makes-rust-different}

Hello World introduces the tools, but it does not demonstrate Rust's most distinctive memory rules. Those become more visible when a program creates data, passes it between functions, and allows different parts of the code to access it.

### Ownership

Ownership connects a value to the code responsible for it. A value has an owner, ownership can move, and a value is dropped when its owner goes out of scope. Rust uses these rules to manage resources without requiring a garbage collector to periodically find unused objects.

The compiler checks ownership rules before execution. Learning those rules takes practice, especially when another language has hidden most memory management decisions. The [ownership chapter](https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html) develops this idea with strings and scopes.

### Borrowing

Borrowing lets code access a value through a reference without taking ownership. Rust checks how references are used: shared access and exclusive mutable access have different rules. This helps prevent conflicting access to data and references that outlive the values they refer to.

For now, the useful distinction is responsibility versus access. Ownership determines who is responsible for a value; borrowing allows temporary access under compiler-enforced rules. The [borrowing chapter](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html) explains the details.

### A Different Learning Curve

Some early Rust practice involves understanding why the compiler rejects code. That feedback can expose assumptions about data access before they become runtime problems. However, compiling successfully does not prove that business logic is correct. A calculation can use memory safely and still produce the wrong answer.

Treat the small program here as an introduction to the workflow. Variables, types, and functions are useful next topics before returning to ownership with more substantial examples.

## Conclusion {#conclusion}

A first Rust program makes the relationship between source code, compiler, and executable tangible. The same foundation carries into larger projects, where Cargo and Rust's memory rules become more important.

- **Rust.** A compiled language that combines control over execution with checks that catch certain errors before runtime.
- **Toolchain.** `rustup` manages the installation, `rustc` compiles source, and Cargo organizes project work.
- **Compilation.** Changing a source file requires a new build before the executable reflects the change.
- **Cargo.** A small generated project introduces the workflow used as code and dependencies grow.

Continue with [The Rust Book](https://doc.rust-lang.org/book/), starting with common programming concepts and then ownership. That progression gives the compiler's rules something concrete to work with.
