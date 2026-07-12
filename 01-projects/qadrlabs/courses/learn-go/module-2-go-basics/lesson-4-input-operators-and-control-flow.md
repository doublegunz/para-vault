## 1. Before You Begin

Programs that only output predefined text are not very useful. Real programs read input from users, perform calculations, and make decisions based on conditions. This lesson adds all three capabilities: reading input from the terminal, working with Go's operators, and controlling program flow with `if-else` and `switch`.

Go's control flow syntax has a few notable differences from other languages. Conditions in `if` and `switch` do not require parentheses. `switch` cases do not fall through by default, so you never need `break`. And Go has a unique `if` form that combines a short statement with the condition, which you will use constantly for error checking from Lesson 8 onward.

### What You'll Build

You will build a grade classifier that reads a score from the user and assigns a letter grade, and a menu-driven calculator that reads two numbers and an operator, then performs the correct calculation.

### What You'll Learn

- ✅ Reading input with `fmt.Scan` and `bufio.Scanner`
- ✅ Arithmetic, comparison, and logical operators
- ✅ `if`, `else if`, `else` (no parentheses needed)
- ✅ `switch` with and without a condition
- ✅ Go's unique `if` with initialization statement

### What You'll Need

- Lesson 3 completed

---

## 2. Setup

Create a new folder `lesson-04` inside `learn-go`. Open the terminal and initialize the module:

```bash
cd lesson-04
go mod init learn-go/lesson-04
```

This creates the `go.mod` file that identifies this directory as a Go module. Create `main.go` inside `lesson-04` to hold your code for this lesson.

---

## 3. Reading User Input

Go provides two standard ways to read terminal input: `fmt.Scan` for reading a single word or number, and `bufio.Scanner` for reading an entire line that may include spaces. Knowing when to use each one prevents a common source of confusion with mixed input.

### Step 1: Create `main.go`

Create the file `main.go` in the `lesson-04` folder. This file will demonstrate both input methods and show how to read different data types.

### Step 2: Write the Code

Write the following program to see both input methods in action:

```go
package main

import (
    "bufio"
    "fmt"
    "os"
    "strings"
)

func main() {
    var name string
    fmt.Print("Enter your name: ")
    fmt.Scan(&name)
    fmt.Println("Hello,", name)

    scanner := bufio.NewReader(os.Stdin)
    fmt.Print("Enter your full name: ")
    fullName, _ := scanner.ReadString('\n')
    fullName = strings.TrimSpace(fullName)
    fmt.Println("Full name:", fullName)

    var age int
    fmt.Print("Enter your age: ")
    fmt.Scan(&age)
    fmt.Printf("You are %d years old. Next year: %d\n", age, age+1)

    var height float64
    fmt.Print("Enter your height (m): ")
    fmt.Scan(&height)
    fmt.Printf("Height: %.2f m\n", height)
}
```

`fmt.Scan(&name)` reads one whitespace-delimited token from the terminal. The `&` operator passes the memory address of `name` instead of its value. This is necessary because `Scan` needs to write into the variable, not read from it. Without `&`, Go would pass a copy of the value and `Scan` would have no way to update the original variable.

`bufio.NewReader(os.Stdin)` creates a buffered reader that reads from standard input. `ReadString('\n')` reads characters until it encounters a newline, returning the entire line including the newline character. `strings.TrimSpace` removes leading and trailing whitespace (including that newline) from the result. Use `bufio` when the input may contain spaces, because `fmt.Scan` stops reading at the first space.

### Step 3: Save and Run

```bash
go run main.go
```

Enter different values at each prompt. Notice that `fmt.Scan` only captures the first word when you type a full name - this is why `bufio` is needed for multi-word input.

---

## 4. Operators and if-else

Go's operators are standard, but its `if` syntax is cleaner than most languages. Braces are mandatory, parentheses around the condition are not allowed by `gofmt`, and there is a special initialization form unique to Go.

Replace the content of `main.go` with the following program:

```go
package main

import "fmt"

func main() {
    a, b := 17, 5
    fmt.Println("=== Arithmetic ===")
    fmt.Printf("%d + %d = %d\n", a, b, a+b)
    fmt.Printf("%d - %d = %d\n", a, b, a-b)
    fmt.Printf("%d * %d = %d\n", a, b, a*b)
    fmt.Printf("%d / %d = %d\n", a, b, a/b)
    fmt.Printf("%d %% %d = %d\n", a, b, a%b)

    fmt.Println("\n=== Comparison ===")
    fmt.Println("10 == 20:", 10 == 20)
    fmt.Println("10 != 20:", 10 != 20)
    fmt.Println("10 > 20:", 10 > 20)
    fmt.Println("10 < 20:", 10 < 20)

    fmt.Println("\n=== Logical ===")
    fmt.Println("true && false:", true && false)
    fmt.Println("true || false:", true || false)
    fmt.Println("!true:", !true)

    fmt.Println("\n=== Grade Classifier ===")
    var score int
    fmt.Print("Enter score (0-100): ")
    fmt.Scan(&score)

    var grade string
    if score >= 90 {
        grade = "A"
    } else if score >= 80 {
        grade = "B"
    } else if score >= 70 {
        grade = "C"
    } else if score >= 60 {
        grade = "D"
    } else {
        grade = "E"
    }
    fmt.Printf("Score %d = Grade %s\n", score, grade)

    if remainder := score % 2; remainder == 0 {
        fmt.Println("Score is even")
    } else {
        fmt.Println("Score is odd")
    }
}
```

The arithmetic section shows that `17 / 5` returns `3`, not `3.4`, because Go performs integer division when both operands are `int`. The `%` operator returns the remainder: `17 % 5` is `2`. The `%%` in the format string is how you print a literal `%` sign inside `Printf`.

The `if-else if` chain does not require parentheses around `score >= 90`. Go's `gofmt` formatter will actually remove them if you add them. The braces `{ }` are always required, even for single-line bodies. The `else if` branches are evaluated in order from top to bottom, so a score of `95` matches the first condition and skips the rest.

The last `if` statement uses Go's initialization form: `if remainder := score % 2; remainder == 0`. The semicolon separates an initialization statement from the condition. The variable `remainder` is declared and initialized in the `if` line, then checked as the condition. Crucially, `remainder` only exists inside this `if-else` block. This pattern keeps variable scope as narrow as possible, which reduces bugs and improves readability.

Run `go run main.go` and try different scores to verify the grade classification works correctly.

### Go's Unique: if with Init Statement

This pattern appears constantly in real Go code, especially for error handling:

```go
if val := someFunction(); val > 0 {
    // val is scoped to this if-else block
}
```

The variable is declared and checked in one line. Because it only exists inside the `if-else` block, it cannot accidentally be used elsewhere in the function. You will use this form in nearly every lesson from Lesson 7 onward when calling functions that return errors.

---

## 5. Switch

Go's `switch` statement is cleaner and safer than in C, Java, or PHP. It does not fall through between cases by default, it supports multiple values in a single case, and it can be used without an expression to replace long `if-else` chains.

Replace the content of `main.go` with the following program:

```go
package main

import "fmt"

func main() {
    fmt.Print("Enter day number (1-7): ")
    var day int
    fmt.Scan(&day)

    switch day {
    case 1:
        fmt.Println("Monday")
    case 2:
        fmt.Println("Tuesday")
    case 3:
        fmt.Println("Wednesday")
    case 4:
        fmt.Println("Thursday")
    case 5:
        fmt.Println("Friday")
    case 6, 7:
        fmt.Println("Weekend!")
    default:
        fmt.Println("Invalid day")
    }

    fmt.Print("\nEnter temperature: ")
    var temp int
    fmt.Scan(&temp)

    switch {
    case temp >= 35:
        fmt.Println("Hot!")
    case temp >= 25:
        fmt.Println("Warm")
    case temp >= 15:
        fmt.Println("Cool")
    default:
        fmt.Println("Cold!")
    }
}
```

`switch day` compares `day` against each `case` value in order. When a match is found, that case's body executes and the `switch` exits. There is no `break` statement because Go does not fall through automatically. `case 6, 7:` demonstrates that a single `case` can match multiple values separated by commas.

The `switch {}` form (without an expression) is called an expressionless switch. Each case provides its own boolean condition. The first case whose condition is `true` executes. This is exactly equivalent to an `if-else if` chain but more readable when there are many conditions. `switch` is always preferred over long `if-else if` chains in idiomatic Go.

Run `go run main.go` and test it with day number 6, then with a temperature below 15.

### Switch Differences from Java/C

In Java and C, `switch` falls through from one case to the next unless you add `break`. This is a notorious source of bugs. Go made the opposite choice: no fall-through by default. If you genuinely need fall-through behavior (rare), use the `fallthrough` keyword explicitly. This makes the intent visible and the code safe by default.

---

## 6. Fix the Errors in Your Code

These three errors are extremely common in Go programs that involve user input and conditional logic.

**Error 1: Missing `&` in Scan.**

`fmt.Scan` needs to write into your variable. To do that, it needs the variable's memory address, not its current value. Omitting `&` causes a runtime panic, not a compile error.

```go
// Wrong: passes the value (0), not the address
var age int
fmt.Scan(age)

// Correct: passes the memory address so Scan can write into age
var age int
fmt.Scan(&age)
```

Without `&`, `fmt.Scan` receives the integer value `0`, attempts to use it as a memory address, and the program panics immediately. This is one of the most common mistakes for developers who have not used pointers before. Always use `&variableName` with `fmt.Scan`.

**Error 2: Parentheses around `if` condition.**

Go does not allow parentheses around `if` conditions. The `gofmt` tool removes them automatically, but understanding this difference helps when reading code from other developers.

```go
// Wrong: parentheses around condition (not idiomatic Go)
if (score >= 70) {
    fmt.Println("Pass")
}

// Correct: no parentheses
if score >= 70 {
    fmt.Println("Pass")
}
```

The version with parentheses actually compiles and runs correctly in Go - it is not a syntax error. However, `gofmt` will remove the parentheses when you save the file, and Go's style guide explicitly says not to use them. Keeping your code consistent with `gofmt` output is important for readability across Go projects.

**Error 3: Case-sensitive string comparison.**

Go's `==` operator compares strings exactly, character by character. Upper and lower case are different characters, so `"Go" == "go"` is `false`.

```go
// Wrong: case-sensitive, will not match "go" or "GO"
name := "Go"
if name == "go" {
    fmt.Println("Match")
}

// Correct: use strings.EqualFold for case-insensitive comparison
import "strings"
name := "Go"
if strings.EqualFold(name, "go") {
    fmt.Println("Match")
}
```

`strings.EqualFold(a, b)` returns `true` if `a` and `b` are equal when compared without regard to case. Use it whenever you are comparing user input to a known string and the case might vary.

---

## 7. Exercises

**Exercise 1:** Build a BMI calculator. Read weight in kilograms and height in centimeters from the user. Calculate BMI using the formula `weight / (height_m * height_m)` where `height_m` is height converted to meters. Display the BMI value and its category: Underweight (below 18.5), Normal (below 25), Overweight (below 30), Obese (30 and above).

**Exercise 2:** Build a simple calculator. Read two numbers and an operator (`+`, `-`, `*`, `/`) from the user. Use `switch` on the operator string to perform the correct calculation. Handle division by zero as a special case.

**Exercise 3:** Read a year from the user. Determine if it is a leap year using `if`. A year is a leap year if it is divisible by 4 but not by 100, OR if it is divisible by 400.

---

## 8. Solutions

**Solution for Exercise 1:**

```go
package main

import "fmt"

func main() {
    var weight, heightCm float64
    fmt.Print("Weight (kg): ")
    fmt.Scan(&weight)
    fmt.Print("Height (cm): ")
    fmt.Scan(&heightCm)

    h := heightCm / 100
    bmi := weight / (h * h)

    fmt.Printf("BMI: %.1f - ", bmi)
    switch {
    case bmi < 18.5:
        fmt.Println("Underweight")
    case bmi < 25:
        fmt.Println("Normal")
    case bmi < 30:
        fmt.Println("Overweight")
    default:
        fmt.Println("Obese")
    }
}
```

`heightCm / 100` converts centimeters to meters. The formula `weight / (h * h)` calculates BMI as kilograms per square meter. The expressionless `switch` then compares the BMI against category thresholds in order from lowest to highest. Because a BMI of `22.5` satisfies `bmi < 25` but not `bmi < 18.5`, it correctly lands in the Normal category.

**Solution for Exercise 2:**

```go
package main

import "fmt"

func main() {
    var a, b float64
    var op string
    fmt.Print("Enter: num1 op num2: ")
    fmt.Scan(&a, &op, &b)

    switch op {
    case "+":
        fmt.Printf("%.2f\n", a+b)
    case "-":
        fmt.Printf("%.2f\n", a-b)
    case "*":
        fmt.Printf("%.2f\n", a*b)
    case "/":
        if b == 0 {
            fmt.Println("Cannot divide by zero")
        } else {
            fmt.Printf("%.2f\n", a/b)
        }
    default:
        fmt.Println("Unknown operator")
    }
}
```

`fmt.Scan(&a, &op, &b)` reads three whitespace-separated values in one call. `a` and `b` are read as `float64` to support decimal inputs. `op` is read as a `string`. The `switch op` statement compares the operator string against each case. The division case uses a nested `if` to check for zero before dividing, because dividing by zero would cause a runtime panic in Go.

**Solution for Exercise 3:**

```go
package main

import "fmt"

func main() {
    var year int
    fmt.Print("Enter year: ")
    fmt.Scan(&year)

    if (year%4 == 0 && year%100 != 0) || year%400 == 0 {
        fmt.Printf("%d is a leap year\n", year)
    } else {
        fmt.Printf("%d is not a leap year\n", year)
    }
}
```

The leap year condition has two parts joined by `||`. The first part `(year%4 == 0 && year%100 != 0)` matches years divisible by 4 but not by 100 - for example, 2024. The second part `year%400 == 0` matches years divisible by 400 - for example, 2000. The year 1900 is not a leap year (divisible by 100 but not 400). The year 2000 is a leap year (divisible by 400). Test both to verify your understanding.

---

## Next Up - Lesson 5

`fmt.Scan(&var)` reads input by writing directly to the variable's memory address - the `&` is essential. Go's `if` requires no parentheses but always requires braces. The `if` initialization statement (`if val := expr; condition`) scopes a variable to the block that needs it. `switch` does not fall through by default, supports multiple values per case with commas, and works without an expression for range-based conditions. These control flow tools are the foundation for every decision your programs will make.

In Lesson 5, you will learn about arrays, slices, and the `for` loop: Go's primary collection type and its single, versatile loop construct.