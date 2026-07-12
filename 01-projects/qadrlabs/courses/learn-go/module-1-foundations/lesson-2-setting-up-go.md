## 1. Before You Begin

Go has one of the simplest setups of any compiled language. You download one installer, run it, and you are ready to write code. There is no build tool configuration like Maven or Gradle, no virtual environment like Python's `venv`, and no separate runtime to install. The Go toolchain handles everything: compiling, formatting, testing, and dependency management.

In Lesson 1, you learned why Go was created. Now you will set it up and write your first program. By the end of this lesson, you will have a working Go development environment and a clear understanding of what happens when you run a Go program.

### What You'll Build

You will install Go and VS Code, create a Go module, write a program that prints formatted output, and learn the core Go toolchain commands that you will use in every lesson from here on.

### What You'll Learn

- ✅ How to install Go on your computer
- ✅ How to configure VS Code with the Go extension
- ✅ The Go toolchain: `go run`, `go build`, `go mod`
- ✅ The structure of a Go source file
- ✅ `fmt.Println` and `fmt.Printf` for output

### What You'll Need

- A computer running Windows, macOS, or Linux
- An internet connection

---

## 2. Install Go

Go provides official installers for all major operating systems. The installer handles all path configuration automatically on Windows and macOS. On Linux, a few manual commands are required.

### Step 1: Download Go

Go to [go.dev/dl](https://go.dev/dl/) and download the installer for your operating system. Always download the latest stable version listed at the top of the page.

### Step 2: Run the Installer

The installation process differs slightly by operating system. Choose the instructions for your system below.

**Windows:** Run the `.msi` installer. It adds Go to your PATH automatically. Open a new terminal after installation.

**macOS:** Run the `.pkg` installer. It installs Go to `/usr/local/go` and updates your PATH.

**Linux:** Extract the tarball and add Go to your PATH manually by running these commands in the terminal:

```bash
sudo tar -C /usr/local -xzf go1.22.x.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
source ~/.profile
```

The first command extracts the Go toolchain to `/usr/local/go`. The second line adds the Go binary directory to your PATH so the `go` command is available in any terminal. The third command applies the change to your current session immediately without requiring a logout.

### Step 3: Verify Installation

Open a terminal and run the following command to confirm Go is installed correctly:

```bash
go version
```

You should see output like `go version go1.22.x linux/amd64`. If you see a "command not found" error, restart your terminal and try again.

---

## 3. Install VS Code with Go Extension

VS Code is the recommended editor for Go beginners because the official Go extension provides code completion, error highlighting, automatic formatting, and debugging support out of the box.

### Step 1: Install VS Code

Download VS Code from [code.visualstudio.com](https://code.visualstudio.com/) if it is not already installed. The installer is available for Windows, macOS, and Linux.

### Step 2: Install the Go Extension

The Go extension is published by the Go Team at Google and integrates the Go toolchain directly into VS Code.

Open VS Code. Click **Extensions** (Ctrl+Shift+X). Search for **"Go"** by the Go Team at Google. Click **Install**.

When prompted to install Go tools (gopls, dlv, staticcheck, etc.), click **Install All**. These tools provide code completion via `gopls`, formatting via `gofmt`, and debugging via `dlv`. They run automatically in the background while you code.

---

## 4. Create Your First Go Program

With Go and VS Code installed, you are ready to write your first program. Go requires a specific file structure that you will use in every lesson: a module file (`go.mod`) and at least one `.go` source file.

### Step 1: Create the Project Folder

Create a folder called `learn-go` on your computer. Inside it, create a folder called `lesson-02`. This `learn-go` folder will contain all your work for this course, with one subfolder per lesson.

Open VS Code, select **File** then **Open Folder**, navigate to `learn-go`, and click **Select Folder**.

### Step 2: Initialize a Go Module

Every Go project must be a module. A module is a collection of Go packages with a defined name and dependency list. Initialize the module by opening the VS Code terminal (Ctrl+`) and running:

```bash
cd lesson-02
go mod init learn-go/lesson-02
```

This creates a `go.mod` file in the `lesson-02` directory. The `go.mod` file records the module name (`learn-go/lesson-02`) and the Go version. Every Go project starts with `go mod init`. Without a `go.mod` file, the Go compiler cannot resolve imports or build the project.

### Step 3: Create the File

Right-click on the `lesson-02` folder in VS Code's sidebar, select **New File**, type `main.go`, and press Enter.

### Step 4: Write the Code

Open `main.go` and type the following program:

```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, Go!")
    fmt.Println("Welcome to the Learn Go course.")

    name := "Budi"
    age := 25
    fmt.Printf("Name: %s, Age: %d\n", name, age)

    fmt.Println("Go is simple.")
    fmt.Println("Go is fast.")
    fmt.Println("Go is fun.")
}
```

Every Go file follows the same three-part structure: a package declaration, import statements, and then functions. The `package main` line declares this file belongs to the executable package. The `import "fmt"` line brings in the format package for output functions. The `func main()` block is where the program starts running.

### Step 5: Save the File

Press **Ctrl+S**. Notice that VS Code automatically formats your code on save. This is `gofmt` running in the background. Go enforces a single standard code style, so there is no debate about indentation or spacing.

### Step 6: Run the Program

In the terminal, run the program with:

```bash
go run main.go
```

Expected output:

```
Hello, Go!
Welcome to the Learn Go course.
Name: Budi, Age: 25
Go is simple.
Go is fast.
Go is fun.
```

`go run` compiles the file to a temporary binary and runs it immediately. The compiled binary is discarded after execution. This is the fastest way to test code during development.

### Step 7: Build the Program (Optional)

If you want to create a standalone executable file that you can distribute or run without the `go` command, use `go build`:

```bash
go build -o hello main.go
```

This creates an executable file named `hello` (or `hello.exe` on Windows). Run it directly with:

```bash
./hello
```

The output is identical to `go run`. The key difference is that `go build` produces a self-contained binary that can run on any machine with the same operating system, even without Go installed.

---

## 5. Go File Structure Explained

Every Go source file follows the same three-section structure. Understanding this structure is essential because the Go compiler enforces it strictly.

```go
package main          // 1. Package declaration (must be first line)

import "fmt"          // 2. Import packages

func main() {         // 3. main function = entry point
    fmt.Println("Hello")
}
```

`package main` declares this file belongs to the `main` package. The `main` package is special in Go: it is the only package that produces an executable binary. All other packages produce libraries that are imported by other packages.

`import "fmt"` imports the `fmt` (format) package from Go's standard library. The standard library provides hundreds of packages for file I/O, networking, JSON parsing, HTTP servers, and more. You will use `fmt` in nearly every lesson.

`func main()` is the entry point of the program. Every executable Go program must have exactly one `main` function in the `main` package. The Go runtime calls this function when the program starts. Without it, `go build` produces a linker error.

### Output Functions

Go's `fmt` package provides three primary output functions, each suited to different situations:

```go
fmt.Println("Hello")              // Print with newline
fmt.Print("Hello ")               // Print without newline
fmt.Printf("Name: %s\n", name)   // Formatted print (like C's printf)
```

`fmt.Println` is the simplest: it prints its arguments separated by spaces and appends a newline automatically. `fmt.Print` does the same but without the trailing newline. `fmt.Printf` formats its output using verbs, which are placeholders that describe the type and format of each value.

Common format verbs for `Printf`:

| Verb | Type | Example |
|------|------|---------|
| `%s` | string | `fmt.Printf("%s", "Budi")` |
| `%d` | integer | `fmt.Printf("%d", 25)` |
| `%f` | float | `fmt.Printf("%.2f", 3.14)` |
| `%v` | any value | `fmt.Printf("%v", anything)` |
| `%T` | type name | `fmt.Printf("%T", 42)` prints `int` |
| `%t` | boolean | `fmt.Printf("%t", true)` |
| `\n` | newline | Must be explicit in Printf |

Unlike `Println`, `Printf` does not add a newline automatically. You must include `\n` at the end of your format string when you want the cursor to move to the next line.

---

## 6. Go Toolchain Commands

The `go` command is the single entry point for everything in Go development. You do not need separate tools for building, formatting, testing, and managing dependencies. The following table shows the commands you will use most often throughout this course:

| Command | Purpose |
|---------|---------|
| `go run main.go` | Compile and run in one step |
| `go build` | Compile to executable |
| `go mod init name` | Initialize a module |
| `go mod tidy` | Clean up dependencies |
| `go fmt ./...` | Format all Go files |
| `go vet ./...` | Check for common mistakes |
| `go test ./...` | Run tests |

`go mod tidy` is particularly useful after adding or removing imports: it updates `go.mod` and `go.sum` to reflect only the packages your code actually uses.

---

## 7. Fix the Errors in Your Code

Go's compiler is intentionally strict. Three errors that beginners encounter constantly are missing package declarations, unused imports, and unused variables. Each one prevents compilation.

**Error 1: Missing package declaration.**

Every Go file must begin with a package declaration. Without it, the compiler does not know what package the file belongs to and refuses to compile.

```go
// Wrong: no package declaration
import "fmt"
func main() {
    fmt.Println("Hello")
}

// Correct: package declaration is always the first line
package main
import "fmt"
func main() {
    fmt.Println("Hello")
}
```

The compiler message for this error is `expected 'package', found 'import'`. The fix is always the same: add `package main` as the very first line.

**Error 2: Unused import.**

Go does not allow unused imports. If you import a package but never call any of its functions, the code will not compile. This rule keeps codebases clean by preventing dead dependencies from accumulating over time.

```go
// Wrong: math is imported but never used
package main
import "fmt"
import "math"
func main() {
    fmt.Println("Hello")
}

// Correct: remove unused imports
package main
import "fmt"
func main() {
    fmt.Println("Hello")
}
```

The compiler error is `"math" imported and not used`. Remove the import or add code that uses it.

**Error 3: Unused variable.**

Go also does not allow unused local variables. If you declare a variable inside a function but never read its value, the code will not compile. This prevents situations where a developer declares a variable thinking they will use it, then forgets - a common source of subtle bugs in other languages.

```go
// Wrong: name is declared but never used
package main
import "fmt"
func main() {
    name := "Budi"
    fmt.Println("Hello")
}

// Correct: use the variable or remove it
package main
import "fmt"
func main() {
    name := "Budi"
    fmt.Println("Hello,", name)
}
```

If you genuinely want to declare a variable but discard its value, use the blank identifier: `_ = name`. This signals to the compiler and to readers that the discard is intentional.

> **Go's strictness is a feature.** Unused imports and variables are banned because they create confusion and waste. The compiler enforces clean code so you do not have to.

---

## 8. Exercises

**Exercise 1:** Create a new folder `exercise` inside `lesson-02`. Initialize a module with `go mod init learn-go/exercise`. Create `main.go` that prints your name, city, and favorite programming language on three separate lines. Run with `go run main.go`.

**Exercise 2:** Use `fmt.Printf` to display a formatted table with proper alignment:

```
Name       Age    City
Budi        25    Bandung
Citra       28    Jakarta
```

Use `%-10s`, `%3d`, and `%-10s` as format verbs to align the columns. Save the file as `main.go` and run it.

**Exercise 3:** Use `fmt.Printf` with the `%T` verb to print the types of these four values: `42`, `3.14`, `"hello"`, `true`. Write down your prediction of the output before running the program, then compare.

---

## 9. Solutions

**Solution for Exercise 1:**

```go
package main

import "fmt"

func main() {
    fmt.Println("Name: Budi Santoso")
    fmt.Println("City: Bandung")
    fmt.Println("Language: Go")
}
```

Each call to `fmt.Println` prints its argument followed by a newline. Because the three values are separate and do not need alignment or special formatting, `Println` is the clearest choice here. Run with `go run main.go` from inside the `exercise` directory.

**Solution for Exercise 2:**

```go
package main

import "fmt"

func main() {
    fmt.Printf("%-10s %3s    %-10s\n", "Name", "Age", "City")
    fmt.Printf("%-10s %3d    %-10s\n", "Budi", 25, "Bandung")
    fmt.Printf("%-10s %3d    %-10s\n", "Citra", 28, "Jakarta")
}
```

`%-10s` pads a string to 10 characters wide and left-aligns it (the `-` flag means left-align). `%3d` pads an integer to 3 characters wide and right-aligns it by default. Using the same format string for the header row and each data row ensures the columns always line up perfectly regardless of the actual string lengths.

**Solution for Exercise 3:**

```go
package main

import "fmt"

func main() {
    fmt.Printf("42:      %T\n", 42)
    fmt.Printf("3.14:    %T\n", 3.14)
    fmt.Printf("hello:   %T\n", "hello")
    fmt.Printf("true:    %T\n", true)
}
```

The `%T` verb prints the Go type name of a value, not the value itself. The output will be `int`, `float64`, `string`, and `bool` respectively. Go infers `42` as `int` (not `int32` or `int64`) and `3.14` as `float64` (not `float32`). These are Go's default numeric types, which you will learn more about in Lesson 3.

---

## Next Up - Lesson 3

Go is installed with a single download. Every Go file starts with `package`, then `import`, then functions. `func main()` is the entry point of every executable program. `fmt.Println` prints with a newline; `fmt.Printf` prints with format verbs for precise control. Go enforces clean code at the compiler level: unused imports and unused variables are compile errors, not warnings.

In Lesson 3, you will learn about variables, data types, and output: Go's type system with both explicit declarations and type inference using `:=`.