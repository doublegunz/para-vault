## 1. Before You Begin

Go is **statically typed**: every variable has a fixed type determined at compile time, and you cannot assign a `string` to an `int` variable. But Go also has **type inference** with the `:=` operator, so you get the safety of static typing without the verbosity of writing `int` or `string` everywhere. This combination is one of Go's most ergonomic design decisions: strict types, minimal ceremony.

In Lesson 2, you wrote your first Go program and learned the basic structure of a Go file. This lesson goes deeper into how Go stores and works with values. You will learn both declaration styles (`var` and `:=`), Go's basic types, how Go initializes variables automatically, and how to format output precisely.

### What You'll Build

You will build a formatted product receipt that calculates a subtotal, tax, and total using typed variables and `fmt.Printf` for aligned output.

### What You'll Learn

- ✅ Variable declaration: `var` (explicit) vs `:=` (short/inferred)
- ✅ Basic types: `int`, `float64`, `string`, `bool`, `byte`, `rune`
- ✅ Zero values (Go's default initialization)
- ✅ Constants with `const`
- ✅ Type conversion
- ✅ Formatted output with `fmt.Printf`

### What You'll Need

- Go and VS Code installed (Lesson 2 completed)

---

## 2. Setup

Every lesson gets its own folder and module. This keeps each lesson's code isolated so you can return to any lesson without conflicts.

Create a new folder `lesson-03` inside `learn-go`. Open the terminal and run:

```bash
cd lesson-03
go mod init learn-go/lesson-03
```

This initializes a new Go module called `learn-go/lesson-03`. The resulting `go.mod` file tells the Go compiler the module name and the minimum Go version required. Now create `main.go` inside `lesson-03` to hold your code.

---

## 3. Variable Declaration

Go provides three ways to declare variables. Understanding when to use each one is essential for writing idiomatic Go code.

### Step 1: Create `main.go`

Right-click on the `lesson-03` folder in VS Code, select **New File**, and type `main.go`. This is the file you will build in this section.

### Step 2: Write the Code

Write the following program to see all three declaration styles and Go's zero values in action:

```go
package main

import "fmt"

func main() {
    var name string = "Budi Santoso"
    var age int = 25
    var height float64 = 1.75
    var isStudent bool = true

    fmt.Println("=== Explicit Declaration ===")
    fmt.Println("Name:", name)
    fmt.Println("Age:", age)
    fmt.Println("Height:", height)
    fmt.Println("Student:", isStudent)

    var city = "Bandung"
    var score = 85
    fmt.Println("\nCity:", city)
    fmt.Println("Score:", score)

    language := "Go"
    version := 1.22
    fmt.Println("\nLanguage:", language)
    fmt.Println("Version:", version)

    var defaultInt int
    var defaultFloat float64
    var defaultString string
    var defaultBool bool

    fmt.Println("\n=== Zero Values ===")
    fmt.Printf("int: %d, float64: %f, string: %q, bool: %t\n",
        defaultInt, defaultFloat, defaultString, defaultBool)

    const taxRate = 0.11
    const appName = "Go Store"
    fmt.Println("\n=== Constants ===")
    fmt.Println("App:", appName)
    fmt.Printf("Tax Rate: %.0f%%\n", taxRate*100)

    var (
        firstName = "Budi"
        lastName  = "Santoso"
        email     = "budi@example.com"
    )
    fmt.Printf("\n%s %s (%s)\n", firstName, lastName, email)

    fmt.Printf("\nType of name: %T\n", name)
    fmt.Printf("Type of age: %T\n", age)
    fmt.Printf("Type of height: %T\n", height)
    fmt.Printf("Type of isStudent: %T\n", isStudent)
}
```

The first block uses `var name string = "Budi Santoso"` - the fully explicit form that specifies both the keyword, the name, the type, and the value. The second block uses `var city = "Bandung"` - Go infers the type from the value so you do not need to write `string` explicitly. The third block uses `:=` (short declaration), which is the most common style inside functions. It declares the variable and infers its type in a single step.

The zero values section demonstrates one of Go's safety guarantees: variables are always initialized. An uninitialized `int` is `0`, not garbage memory. An uninitialized `string` is `""`, not `null`. An uninitialized `bool` is `false`. This eliminates an entire class of bugs common in C and C++.

The `const` keyword declares a constant whose value cannot change after compilation. Attempting to assign a new value to a constant is a compile error. Constants are ideal for values like tax rates, application names, and mathematical constants that must never change at runtime.

The grouped `var ( ... )` block is a clean way to declare multiple variables at once without repeating the `var` keyword. It is commonly used at the package level for related variables.

### Step 3: Save and Run

Press **Ctrl+S** to save. Then run the program from the terminal:

```bash
go run main.go
```

Verify that you see output for each section: explicit declarations, city and score, language and version, zero values, constants, and type names.

---

## 4. Type Conversion

Go never converts types automatically. If you have an `int` and need a `float64`, you must convert it explicitly. This is by design: implicit conversions in other languages (like JavaScript's type coercion) are a major source of subtle bugs.

### Step 1: Replace `main.go`

Replace the entire content of `main.go` with the following code to explore numeric and string type conversions:

```go
package main

import (
    "fmt"
    "strconv"
)

func main() {
    var intVal int = 42
    var floatVal float64 = float64(intVal)
    var backToInt int = int(floatVal)

    fmt.Println("=== Numeric Conversion ===")
    fmt.Printf("int %d -> float64 %f\n", intVal, floatVal)
    fmt.Printf("float64 %f -> int %d\n", floatVal, backToInt)

    a, b := 10, 3
    fmt.Printf("\n10 / 3 (int) = %d\n", a/b)
    fmt.Printf("10.0 / 3.0 (float) = %.4f\n", float64(a)/float64(b))

    fmt.Println("\n=== String Conversion ===")

    numStr := strconv.Itoa(42)
    fmt.Printf("Itoa(42) = %q (type: %T)\n", numStr, numStr)

    num, err := strconv.Atoi("123")
    if err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Printf("Atoi(\"123\") = %d (type: %T)\n", num, num)
    }

    f, err := strconv.ParseFloat("3.14", 64)
    if err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Printf("ParseFloat(\"3.14\") = %f\n", f)
    }

    price := 8500000
    formatted := fmt.Sprintf("Rp %d", price)
    fmt.Println("Formatted:", formatted)
}
```

`float64(intVal)` converts an `int` to a `float64`. The conversion is explicit: you write the target type followed by the value in parentheses. `int(floatVal)` converts in the opposite direction, truncating the decimal part. The example `10 / 3` returns `3` because Go performs integer division when both operands are integers. Writing `float64(a) / float64(b)` forces floating-point division, which returns `3.3333`.

`strconv.Itoa` converts an integer to its string representation. The name stands for "integer to ASCII". `strconv.Atoi` does the reverse: "ASCII to integer". Unlike `Itoa`, `Atoi` can fail if the string is not a valid integer, so it returns two values: the result and an error. The pattern `num, err := strconv.Atoi(...)` followed by `if err != nil` is Go's standard error handling pattern. You will learn this thoroughly in Lesson 8.

`fmt.Sprintf` works exactly like `fmt.Printf` but returns the formatted string instead of printing it. This is useful when you need to build a formatted string to store or pass to another function.

### Step 2: Save and Run

```bash
go run main.go
```

Compare the result of integer division (`3`) vs floating-point division (`3.3333`) to confirm you understand the difference.

---

## 5. Practical: Product Receipt

Now apply what you have learned to build a real output. Replace the content of `main.go` with the following receipt calculator:

```go
package main

import "fmt"

func main() {
    const taxRate = 0.11

    product := "Laptop ProBook 14"
    price := 8500000
    quantity := 2

    subtotal := price * quantity
    tax := float64(subtotal) * taxRate
    total := float64(subtotal) + tax

    fmt.Println("================================")
    fmt.Println("         RECEIPT")
    fmt.Println("================================")
    fmt.Printf("Product  : %s\n", product)
    fmt.Printf("Price    : Rp %d\n", price)
    fmt.Printf("Quantity : %d\n", quantity)
    fmt.Println("--------------------------------")
    fmt.Printf("Subtotal : Rp %d\n", subtotal)
    fmt.Printf("Tax (11%%): Rp %.0f\n", tax)
    fmt.Printf("Total    : Rp %.0f\n", total)
    fmt.Println("================================")
}
```

`subtotal := price * quantity` multiplies two `int` values and stores the result as an `int`. However, `tax := float64(subtotal) * taxRate` requires a `float64` multiplication because `taxRate` is an untyped floating-point constant. Converting `subtotal` with `float64(subtotal)` ensures the multiplication is done in floating-point precision. The `%%` in `"Tax (11%%)"` is how you print a literal percent sign inside `Printf`: one `%` would begin a verb, so two `%%` outputs exactly one `%` character.

Run `go run main.go` to see the formatted receipt output. Verify that the numbers are correct and the columns are aligned.

---

## 6. Fix the Errors in Your Code

These three errors appear constantly in Go programs written by developers coming from other languages. Each one is a compile error in Go.

**Error 1: Using `:=` at package level.**

The short declaration operator `:=` only works inside functions. At the package level (outside any function), you must use `var`.

```go
// Wrong: := is not allowed outside functions
package main
name := "Budi"

// Correct: use var at package level
package main
var name = "Budi"
```

The compile error is `syntax error: non-declaration statement outside function body`. If you need a package-level variable, switch to `var name = "Budi"` or `var name string = "Budi"`.

**Error 2: Implicit type conversion.**

Go never converts types automatically. Assigning an `int` to a `float64` variable without explicit conversion is a compile error.

```go
// Wrong: cannot use int as float64 implicitly
var a int = 10
var b float64 = a

// Correct: convert explicitly
var a int = 10
var b float64 = float64(a)
```

The compile error is `cannot use a (variable of type int) as type float64`. The fix is always the same: wrap the value with the target type as a function call.

**Error 3: Redeclaring a variable with `:=`.**

The `:=` operator declares a new variable. If that variable name already exists in the same scope, the compiler rejects it.

```go
// Wrong: name is declared twice in the same scope
name := "Budi"
name := "Citra"

// Correct: use = for reassignment after the first declaration
name := "Budi"
name = "Citra"
```

The compile error is `no new variables on left side of :=`. Use `=` (without the colon) to assign a new value to an existing variable. Use `:=` only the first time you introduce a variable name.

---

## 7. Exercises

**Exercise 1:** Declare variables for a student profile: name (string), student ID (string), semester (int), GPA (float64), active (bool). Display all values using `fmt.Printf` with proper formatting so each label is left-aligned in a 12-character column.

**Exercise 2:** Calculate the area and circumference of a circle with radius 7. Use `const pi = 3.14159`. Display the results with 2 decimal places using `fmt.Printf`.

**Exercise 3:** Start with the string `"255"`. Convert it to an `int`, then convert that `int` to a `float64`. Print the value and its type at each step using `%v` and `%T`.

---

## 8. Solutions

**Solution for Exercise 1:**

```go
package main

import "fmt"

func main() {
    name := "Citra Dewi"
    studentID := "IF-2026001"
    semester := 3
    gpa := 3.87
    active := true

    fmt.Printf("%-12s: %s\n", "Name", name)
    fmt.Printf("%-12s: %s\n", "Student ID", studentID)
    fmt.Printf("%-12s: %d\n", "Semester", semester)
    fmt.Printf("%-12s: %.2f\n", "GPA", gpa)
    fmt.Printf("%-12s: %t\n", "Active", active)
}
```

`%-12s` pads the label to 12 characters wide and left-aligns it using the `-` flag. This ensures the colons appear in a consistent column regardless of label length. Each data value uses the appropriate verb for its type: `%s` for strings, `%d` for the integer semester, `%.2f` for the float GPA with two decimal places, and `%t` for the boolean active status.

**Solution for Exercise 2:**

```go
package main

import "fmt"

func main() {
    const pi = 3.14159
    radius := 7.0
    area := pi * radius * radius
    circumference := 2 * pi * radius

    fmt.Printf("Radius: %.2f\n", radius)
    fmt.Printf("Area: %.2f\n", area)
    fmt.Printf("Circumference: %.2f\n", circumference)
}
```

`const pi = 3.14159` declares an untyped constant. When used in an expression with `float64` values, Go treats it as `float64` automatically. The `radius` variable is declared as `7.0` (not `7`) so Go infers it as `float64`. If you wrote `7`, Go would infer `int`, and the multiplication `pi * radius` would be a type mismatch error. The `%.2f` verb formats the result with exactly two decimal places.

**Solution for Exercise 3:**

```go
package main

import (
    "fmt"
    "strconv"
)

func main() {
    s := "255"
    fmt.Printf("String: %v (%T)\n", s, s)

    i, _ := strconv.Atoi(s)
    fmt.Printf("Int: %v (%T)\n", i, i)

    f := float64(i)
    fmt.Printf("Float64: %v (%T)\n", f, f)
}
```

`strconv.Atoi` returns two values: the converted integer and an error. The `_` (blank identifier) discards the error here because `"255"` is always a valid integer. In production code, you should always check the error. `float64(i)` performs an explicit numeric type conversion from `int` to `float64`. The output shows the value and type at each step: `string`, `int`, then `float64`.

---

## Next Up - Lesson 4

Go has two declaration styles: `var name string = "Budi"` (explicit) and `name := "Budi"` (inferred, most common inside functions). Every undeclared variable has a zero value: `0` for numbers, `""` for strings, `false` for bools. Constants use `const` and cannot be changed after compilation. Type conversion is always explicit - Go never converts types automatically. `fmt.Printf` formats output with type-specific verbs like `%s`, `%d`, `%f`, and `%T`.

In Lesson 4, you will learn about input, operators, and control flow: reading user input from the terminal and making decisions with `if-else` and `switch`.