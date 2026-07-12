## 1. Before You Begin

So far, every program in this course has been a single `main.go` file. Real Go projects split code into packages: folders of related `.go` files where each folder represents a unit of functionality. Packages let you reuse code across files, enforce boundaries with exported and unexported names, and share code with other developers through modules.

In Lessons 7 through 10, you wrote functions, structs, interfaces, and error handling patterns. This lesson shows you how to organize all of that into a proper project structure. Understanding packages is essential for Lesson 12 and 14, where you will work with the standard library's `os`, `bufio`, and `encoding/json` packages and build a multi-file project.

### What You'll Build

You will create a multi-package project with separate packages for mathematical utilities and text processing, then import and test them from the main application.

### What You'll Learn

- ✅ What packages are and how they work
- ✅ Exported vs unexported names (uppercase vs lowercase)
- ✅ Creating and importing your own packages
- ✅ `go mod init` and the `go.mod` file
- ✅ Installing third-party packages with `go get`
- ✅ The `init()` function

### What You'll Need

- Lesson 10 completed

---

## 2. Setup

Create a new folder `lesson-11` inside `learn-go`. Open the terminal and initialize the module:

```bash
mkdir lesson-11
cd lesson-11
go mod init lesson-11
```

This creates a `go.mod` file that identifies this directory as a Go module named `lesson-11`. Every package you create inside `lesson-11` will have an import path that starts with `lesson-11/`. Note that this lesson uses `lesson-11` as the module name (without `learn-go/` prefix) to keep import paths shorter in the examples.

---

## 3. Creating Your Own Packages

A Go package is a directory containing one or more `.go` files that all share the same `package` declaration. The package name is typically the last component of the directory path. Exported functions and types (uppercase first letter) are accessible from other packages; unexported ones (lowercase) stay private.

### Step 1: Create the Directory Structure

Before writing any code, create the folders that will hold each package. This is the structure you will build:

```
lesson-11/
    go.mod
    main.go
    mathutil/
        mathutil.go
    greeting/
        greeting.go
```

Create the `mathutil` and `greeting` folders inside `lesson-11`. You can do this in VS Code's sidebar or with `mkdir mathutil greeting` in the terminal.

### Step 2: Create `mathutil/mathutil.go`

The `mathutil` package will provide mathematical helper functions. Create the file `mathutil/mathutil.go` and write the following code:

```go
package mathutil

import "math"

func Add(a, b float64) float64 {
    return a + b
}

func Subtract(a, b float64) float64 {
    return a - b
}

func CircleArea(radius float64) float64 {
    return math.Pi * radius * radius
}

func max(a, b float64) float64 {
    if a > b {
        return a
    }
    return b
}

func Max(a, b float64) float64 {
    return max(a, b)
}
```

`package mathutil` declares that this file belongs to the `mathutil` package. The name matches the folder name, which is the Go convention.

`Add`, `Subtract`, `CircleArea`, and `Max` start with uppercase letters, so they are exported: any package that imports `mathutil` can call them. `max` starts with a lowercase letter, so it is unexported: it is an internal helper function that only code inside the `mathutil` package can use. This is Go's visibility system: uppercase is public, lowercase is private.

### Step 3: Create `greeting/greeting.go`

The `greeting` package will provide text greeting functions. Create the file `greeting/greeting.go` and write:

```go
package greeting

import "fmt"

func Hello(name string) string {
    return fmt.Sprintf("Hello, %s! Welcome to Go.", name)
}

func Farewell(name string) string {
    return fmt.Sprintf("Goodbye, %s! See you next time.", name)
}
```

Both `Hello` and `Farewell` are exported (uppercase). They return strings containing formatted messages. Notice that the package imports `"fmt"` just like `main` packages do. Any package can import any other package from the standard library.

### Step 4: Create `main.go`

The main application imports both packages and calls their functions. Create `main.go` in the `lesson-11` root:

```go
package main

import (
    "fmt"
    "lesson-11/mathutil"
    "lesson-11/greeting"
)

func main() {
    fmt.Println("=== Math Utilities ===")
    fmt.Printf("Add(10, 5) = %.0f\n", mathutil.Add(10, 5))
    fmt.Printf("Subtract(10, 5) = %.0f\n", mathutil.Subtract(10, 5))
    fmt.Printf("CircleArea(7) = %.2f\n", mathutil.CircleArea(7))
    fmt.Printf("Max(42, 17) = %.0f\n", mathutil.Max(42, 17))

    fmt.Println("\n=== Greetings ===")
    fmt.Println(greeting.Hello("Budi"))
    fmt.Println(greeting.Farewell("Budi"))
}
```

`"lesson-11/mathutil"` is the import path for the `mathutil` package. It is constructed as `<module-name>/<package-folder>`. The module name `lesson-11` comes from the first line of `go.mod`. After importing, functions are accessed with the package name as a prefix: `mathutil.Add(10, 5)`. This prefix makes it clear where each function comes from when reading the code.

### Step 5: Save and Run

```bash
go run main.go
```

Go will compile all three packages together and run the program. You should see the math utility results and the greeting messages.

### Key Points

The package name equals the folder name by convention. The `main` package is special: it is the only package that produces an executable binary when compiled. Exported names start with uppercase. Import paths are always `module-name/package-folder`, not just the folder name alone.

---

## 4. The `go.mod` File

The `go.mod` file is the foundation of every Go module. It records the module name, the minimum Go version required, and all external dependencies. Understanding its structure helps you manage dependencies and share your code.

Opening `go.mod` reveals a simple text format:

```
module lesson-11

go 1.21
```

The `module` line declares the module name, which becomes the prefix for all import paths in this module. The `go` line specifies the minimum Go version. When you add external dependencies, they appear in a `require` block.

### Installing a Third-Party Package

The `go get` command downloads and installs external packages. Run the following to install the popular `color` package:

```bash
go get github.com/fatih/color
```

After running this, `go.mod` gains a `require` block:

```
require github.com/fatih/color v1.16.0
```

A `go.sum` file is also created, which records the cryptographic hashes of downloaded packages to prevent tampering. You can then import and use the package:

```go
import "github.com/fatih/color"

func main() {
    color.Green("This text is green!")
    color.Red("This text is red!")
}
```

> **Note:** This course's exercises do not use external packages. The exercises rely only on the standard library so you can focus on learning Go itself. This section shows the pattern for your own projects after the course.

---

## 5. Multiple Files in One Package

A single package can span multiple `.go` files. All files in the same folder with the same `package` declaration share the same namespace: functions in one file can call functions in another without any imports.

To demonstrate this, create an additional file `mathutil/stats.go` inside the `mathutil` folder:

```go
package mathutil

func Average(numbers []float64) float64 {
    if len(numbers) == 0 {
        return 0
    }
    var sum float64
    for _, n := range numbers {
        sum += n
    }
    return sum / float64(len(numbers))
}

func Sum(numbers []float64) float64 {
    var total float64
    for _, n := range numbers {
        total += n
    }
    return total
}
```

`Average` and `Sum` belong to the `mathutil` package because the file declares `package mathutil`. Now `main.go` can call `mathutil.Average(...)` and `mathutil.Sum(...)` with no additional imports. Go compiles all `.go` files in the same folder together as a single package, so the compiler sees `mathutil.go` and `stats.go` as one unit.

This is a powerful organizational tool: you can split large packages into multiple files by topic without changing any import paths or function call syntax.

---

## 6. The `init()` Function

Every Go package can define an `init()` function. This function runs automatically when the package is first imported, before `main()` runs. It takes no parameters and returns nothing. Use it for setup that must happen before any code in the package runs.

Add the following to the top of `greeting/greeting.go`:

```go
package greeting

import "fmt"

func init() {
    fmt.Println("[greeting package initialized]")
}

func Hello(name string) string {
    return "Hello, " + name
}
```

When `main.go` imports `"lesson-11/greeting"`, Go calls `init()` automatically before `main()` starts. The output `[greeting package initialized]` appears before any output from `main()` itself.

`init()` runs once per package per program execution, even if the package is imported by multiple other packages. Use `init()` for one-time setup tasks like loading configuration or initializing package-level variables. Avoid heavy computation or operations that can fail in `init()`, because errors in `init()` are not easily recoverable.

---

## 7. Fix the Errors in Your Code

These three errors are the most common mistakes when organizing Go code into packages.

**Error 1: Importing a package but not using it.**

Go does not allow unused imports. If you import a package but call none of its functions, the program will not compile.

```go
// Wrong: math is imported but never used in this file
import "fmt"
import "math"
func main() {
    fmt.Println("Hello")
}

// Correct: remove unused imports
import "fmt"
func main() {
    fmt.Println("Hello")
}
```

The compile error is `"math" imported and not used`. Remove the import, or if you need a package's side effects without calling any functions (for example, registering a database driver), use the blank import: `import _ "database/sql/driver"`.

**Error 2: Circular imports.**

Go does not allow two packages to import each other. If package A imports package B and package B imports package A, the compiler refuses to compile.

```go
// Wrong: packageA imports packageB, which imports packageA
// This creates a circular dependency that Go forbids.

// Correct: extract shared code into a third package (packageC)
// packageA imports packageC
// packageB imports packageC
// Neither A nor B imports the other
```

Circular imports usually indicate that two packages are too tightly coupled. The solution is to extract the shared code into a new, lower-level package that both A and B can import without depending on each other.

**Error 3: Wrong import path.**

The import path must be `module-name/package-folder`. Using only the folder name without the module name prefix causes a compile error.

```go
// Wrong: missing module name prefix
import "mathutil"

// Correct: full import path including module name
import "lesson-11/mathutil"
```

The compile error is `cannot find package "mathutil"`. Go looks for packages by their full import path starting from the module root. If your module is named `lesson-11`, every package inside it must be imported as `lesson-11/packagename`.

---

## 8. Exercises

**Exercise 1:** Create a `stringutil` package with three exported functions: `Reverse(s string) string` (reverses a string), `IsPalindrome(s string) bool` (checks if a string reads the same forward and backward, case-insensitive), and `WordCount(s string) int` (counts the number of words). Import and test all three from `main.go`.

**Exercise 2:** Create a `validator` package with three exported functions: `IsEmail(s string) bool` (simple check: must contain both `"@"` and `"."`), `IsNotEmpty(s string) bool` (returns false if the string is blank after trimming), and `IsInRange(n, min, max int) bool` (checks if n is within the inclusive range). Test all three from `main.go` with valid and invalid inputs.

**Exercise 3:** Create a `models` package with a `Student` struct (fields: `Name string`, `Grade float64`) and a `Status() string` method on it. Import `models` from `main.go`, create a slice of students, display their names, grades, and statuses, and calculate the class average grade.

---

## 9. Solutions

**Solution for Exercise 1:**

Create `stringutil/stringutil.go`:

```go
package stringutil

import "strings"

func Reverse(s string) string {
    runes := []rune(s)
    for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
        runes[i], runes[j] = runes[j], runes[i]
    }
    return string(runes)
}

func IsPalindrome(s string) bool {
    lower := strings.ToLower(strings.ReplaceAll(s, " ", ""))
    return lower == Reverse(lower)
}

func WordCount(s string) int {
    return len(strings.Fields(s))
}
```

Create `main.go`:

```go
package main

import (
    "fmt"
    "lesson-11/stringutil"
)

func main() {
    fmt.Println(stringutil.Reverse("Hello"))
    fmt.Println(stringutil.IsPalindrome("racecar"))
    fmt.Println(stringutil.IsPalindrome("hello"))
    fmt.Println(stringutil.WordCount("Go is a great language"))
}
```

`Reverse` converts the string to a `[]rune` slice before reversing. This is necessary because strings in Go are sequences of bytes, not characters. Unicode characters can be multiple bytes wide. Operating on runes ensures each Unicode character is reversed as a unit rather than as individual bytes. `IsPalindrome` converts to lowercase and removes spaces before comparing, so `"Race Car"` is correctly identified as a palindrome. `strings.Fields` splits by any whitespace, making `WordCount` robust to multiple spaces between words.

**Solution for Exercise 2:**

Create `validator/validator.go`:

```go
package validator

import "strings"

func IsEmail(s string) bool {
    return strings.Contains(s, "@") && strings.Contains(s, ".")
}

func IsNotEmpty(s string) bool {
    return strings.TrimSpace(s) != ""
}

func IsInRange(n, min, max int) bool {
    return n >= min && n <= max
}
```

`IsEmail` performs a simple structural check: a valid email must contain both `"@"` and `"."`. This is intentionally simple and does not validate complex email formats. In a real application you would use a regular expression or a dedicated email validation library. `IsNotEmpty` uses `strings.TrimSpace` to handle strings that contain only whitespace: a string of spaces should be considered empty. `IsInRange` uses `>=` and `<=` for inclusive bounds on both ends.

**Solution for Exercise 3:**

Create `models/student.go`:

```go
package models

import "fmt"

type Student struct {
    Name  string
    Grade float64
}

func (s Student) Status() string {
    if s.Grade >= 70 {
        return "Pass"
    }
    return "Fail"
}

func (s Student) Display() {
    fmt.Printf("%-10s %.1f (%s)\n", s.Name, s.Grade, s.Status())
}
```

Create `main.go`:

```go
package main

import (
    "fmt"
    "lesson-11/models"
)

func main() {
    students := []models.Student{
        {Name: "Andi", Grade: 85},
        {Name: "Budi", Grade: 65},
        {Name: "Citra", Grade: 92},
    }

    for _, s := range students {
        s.Display()
    }

    var total float64
    for _, s := range students {
        total += s.Grade
    }
    fmt.Printf("\nAverage: %.1f\n", total/float64(len(students)))
}
```

`models.Student` is accessed with the package prefix `models`. This makes it clear in `main.go` that `Student` is defined in the `models` package, not in the current file. The `Display()` method is defined on `Student` in the package, so `main.go` does not need to know anything about the formatting logic. This separation of concerns is exactly why packages are valuable.

---

## Next Up - Lesson 12

Go organizes code into packages (folders with matching `package` declarations). Exported names start with uppercase and are accessible from other packages; unexported names start with lowercase and stay private. `go.mod` tracks the module name and all dependencies. Import paths are always `module-name/package-folder`. Multiple `.go` files in the same folder share the same package namespace. `go get` installs third-party packages. `init()` runs once when a package is first imported.

In Lesson 12, you will learn about file handling and JSON: reading and writing files with the `os` and `bufio` packages, and serializing and deserializing data with `encoding/json`.