## 1. Before You Begin

Go has no exceptions. There is no `try`, no `catch`, and no `throw`. Instead, functions that can fail return an `error` as their last return value. You check `if err != nil` immediately after the call and handle the failure at the point where it happens. This makes error paths explicit and visible in the code, not hidden inside stack traces that appear at an unexpected moment.

This is Go's most distinctive design choice and the one that developers coming from Java, Python, or PHP find most unfamiliar. But after working with it for a few lessons, the pattern becomes second nature. Explicit error handling leads to more reliable programs because nothing is swept under the rug.

### What You'll Build

You will build a safe file reader with proper error wrapping and a validated user registration function that uses a custom error type to carry structured failure information.

### What You'll Learn

- ✅ The `error` interface and `nil` for success
- ✅ Creating errors: `errors.New` and `fmt.Errorf`
- ✅ The `if err != nil` pattern
- ✅ Wrapping errors with `%w` and `errors.Is` / `errors.As`
- ✅ Custom error types
- ✅ `panic` and `recover` (rare: only for truly unrecoverable situations)

### What You'll Need

- Lesson 7 completed

---

## 2. Setup

Create a new folder `lesson-08` inside `learn-go`. Open the terminal and initialize the module:

```bash
cd lesson-08
go mod init learn-go/lesson-08
```

This creates the `go.mod` file for this lesson. Create `main.go` inside `lesson-08` before continuing.

---

## 3. The Error Pattern

The `error` type in Go is a built-in interface with a single method: `Error() string`. Any type that implements this method satisfies the `error` interface. `nil` represents the absence of an error. When a function returns `nil` as the error, the call succeeded.

### Step 1: Create `main.go`

Create `main.go` in the `lesson-08` folder. This file will define several functions that can fail and demonstrate how to handle their errors at the call site.

### Step 2: Write the Code

Write the following program to see the error pattern in action across different scenarios:

```go
package main

import (
    "errors"
    "fmt"
    "math"
    "strconv"
)

func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}

func sqrt(n float64) (float64, error) {
    if n < 0 {
        return 0, fmt.Errorf("cannot calculate square root of negative number: %.2f", n)
    }
    return math.Sqrt(n), nil
}

func parseAge(s string) (int, error) {
    age, err := strconv.Atoi(s)
    if err != nil {
        return 0, fmt.Errorf("invalid age %q: %w", s, err)
    }
    if age < 0 || age > 150 {
        return 0, fmt.Errorf("age out of range: %d", age)
    }
    return age, nil
}

func main() {
    result, err := divide(10, 3)
    if err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Printf("10 / 3 = %.2f\n", result)
    }

    _, err = divide(10, 0)
    if err != nil {
        fmt.Println("Error:", err)
    }

    val, err := sqrt(-4)
    if err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Println("sqrt:", val)
    }

    fmt.Println("\n=== Wrapped Errors ===")
    age, err := parseAge("abc")
    if err != nil {
        fmt.Println("Error:", err)

        var numErr *strconv.NumError
        if errors.As(err, &numErr) {
            fmt.Println("  Underlying NumError:", numErr)
        }
    }

    age, err = parseAge("25")
    if err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Println("Valid age:", age)
    }
}
```

`errors.New("division by zero")` creates a simple error with a static message. It returns a non-nil `error` value that satisfies the `error` interface. The caller checks `if err != nil` and handles or returns the error before using the result.

`fmt.Errorf("cannot calculate square root of negative number: %.2f", n)` creates an error with formatted context. Unlike `errors.New`, `fmt.Errorf` supports format verbs so you can include the problematic value in the error message. This makes errors much easier to debug.

`fmt.Errorf("invalid age %q: %w", s, err)` uses `%w` to wrap an existing error inside a new error. Wrapping adds context (which operation failed and with what input) while preserving the original error so callers can inspect it. `errors.As(err, &numErr)` unwraps the error chain and checks whether any error in the chain is of type `*strconv.NumError`. If it finds one, it assigns it to `numErr` so you can access its fields.

### Step 3: Save and Run

```bash
go run main.go
```

Observe that `parseAge("abc")` prints both the wrapped error message and the underlying `NumError` detail. `parseAge("25")` succeeds and prints the valid age.

### The Pattern

Every call to a fallible function in Go follows this shape:

```go
result, err := someFunction()
if err != nil {
    return err
}
```

This pattern appears hundreds of times in every Go project. It is more verbose than try-catch, but it makes every error path visible in the code. You always know exactly where an error can occur and how it is handled.

---

## 4. Custom Error Types

For complex applications, simple string errors are not enough. A custom error type can carry structured information: which field failed, what value was invalid, or what the expected range was. Go's `error` interface requires only one method: `Error() string`.

Replace the content of `main.go` with the following program:

```go
package main

import "fmt"

type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error: %s - %s", e.Field, e.Message)
}

func validateUser(name, email string) error {
    if name == "" {
        return &ValidationError{Field: "name", Message: "cannot be empty"}
    }
    if email == "" {
        return &ValidationError{Field: "email", Message: "cannot be empty"}
    }
    if len(name) < 2 {
        return &ValidationError{Field: "name", Message: "must be at least 2 characters"}
    }
    return nil
}

func main() {
    err := validateUser("Budi", "budi@example.com")
    if err != nil {
        fmt.Println(err)
    } else {
        fmt.Println("User is valid!")
    }

    err = validateUser("", "budi@example.com")
    if err != nil {
        fmt.Println(err)

        if ve, ok := err.(*ValidationError); ok {
            fmt.Printf("  Field: %s\n  Message: %s\n", ve.Field, ve.Message)
        }
    }
}
```

`type ValidationError struct` defines a custom struct with two fields: `Field` and `Message`. Any type that has an `Error() string` method satisfies the `error` interface, so `*ValidationError` can be returned wherever an `error` is expected.

`&ValidationError{Field: "name", Message: "cannot be empty"}` creates a pointer to a new `ValidationError` value. Using a pointer receiver (`*ValidationError`) for `Error()` is the convention for custom error types. The `validateUser` function returns `nil` on success and a `*ValidationError` on any validation failure.

`err.(*ValidationError)` is a type assertion: it attempts to unwrap the `error` interface value and retrieve the underlying `*ValidationError`. The two-value form (`ve, ok := err.(*ValidationError)`) is safe: if the assertion fails, `ok` is `false` and `ve` is `nil`, so no panic occurs.

Run `go run main.go` and verify that the valid user prints "User is valid!" and the invalid user prints both the full error message and the individual field details.

---

## 5. Fix the Errors in Your Code

These three patterns represent the most serious error handling mistakes in Go. Each one makes programs unreliable in different ways.

**Error 1: Ignoring errors with `_`.**

Silently discarding error return values is the most dangerous mistake in Go. When the function fails, you proceed with a zero-value result that will cause incorrect behavior or a panic elsewhere in the program.

```go
// Wrong: if Open fails, file is nil, and any use of file will panic
file, _ := os.Open("config.txt")
data, _ := io.ReadAll(file)

// Correct: check every error before proceeding
file, err := os.Open("config.txt")
if err != nil {
    fmt.Println("Error opening file:", err)
    return
}
data, err := io.ReadAll(file)
if err != nil {
    fmt.Println("Error reading file:", err)
    return
}
```

Every `_` that discards an error is a place where the program can fail silently. In production, these silent failures are almost always harder to debug than a clear error message. The rule is simple: if a function returns an error, check it.

**Error 2: Returning errors without context.**

Returning an error as-is, without wrapping it, tells the caller that something went wrong but not what operation failed or with what input.

```go
// Wrong: caller receives the error but does not know what file failed or why
func processFile(path string) error {
    _, err := os.Open(path)
    return err
}

// Correct: wrap the error with context about the operation that failed
func processFile(path string) error {
    _, err := os.Open(path)
    if err != nil {
        return fmt.Errorf("processFile %s: %w", path, err)
    }
    return nil
}
```

`fmt.Errorf("processFile %s: %w", path, err)` creates a new error that includes the file path and wraps the original error. When this error propagates up the call stack, each layer can add more context. The `%w` verb preserves the original error so `errors.Is` and `errors.As` can still inspect it.

**Error 3: Using `panic` for normal error conditions.**

`panic` terminates the program unless recovered. It is designed for programming bugs that should never happen. Using `panic` for expected error conditions like invalid input or missing files is incorrect.

```go
// Wrong: panic terminates the program on a predictable input error
func divide(a, b int) int {
    if b == 0 {
        panic("division by zero")
    }
    return a / b
}

// Correct: return an error so the caller can handle it
func divide(a, b int) (int, error) {
    if b == 0 {
        return 0, fmt.Errorf("cannot divide %d by zero", a)
    }
    return a / b, nil
}
```

Reserve `panic` for situations that represent programming errors: accessing a nil pointer that should never be nil, or reaching code that is logically impossible. For any error that a user or caller might cause (invalid input, missing file, network failure), always use the error return pattern.

---

## 6. Exercises

**Exercise 1:** Write a function `safeDivide(a, b int) (int, error)` that returns an error for division by zero with the message including `a`. Write a second function `safeModulo(a, b int) (int, error)` that also checks for zero. Call both from `main` with valid and invalid inputs.

**Exercise 2:** Write a `parseTemperature(s string) (float64, error)` function that parses a string to `float64` using `strconv.ParseFloat`. Wrap the parse error with context. Also validate that the value is between -100 and 100, returning a descriptive error for out-of-range values.

**Exercise 3:** Create a custom `InsufficientFundsError` struct with `Balance` and `Amount` fields (both `float64`). Implement the `error` interface on it. Use it in a `withdraw(balance, amount float64) (float64, error)` function. In `main`, use `errors.As` to extract and display the structured error fields when withdrawal fails.

---

## 7. Solutions

**Solution for Exercise 1:**

```go
package main

import "fmt"

func safeDivide(a, b int) (int, error) {
    if b == 0 {
        return 0, fmt.Errorf("cannot divide %d by zero", a)
    }
    return a / b, nil
}

func safeModulo(a, b int) (int, error) {
    if b == 0 {
        return 0, fmt.Errorf("cannot take modulo of %d by zero", a)
    }
    return a % b, nil
}

func main() {
    if result, err := safeDivide(10, 3); err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Println("10 / 3 =", result)
    }

    if _, err := safeDivide(10, 0); err != nil {
        fmt.Println("Error:", err)
    }

    if result, err := safeModulo(17, 5); err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Println("17 % 5 =", result)
    }
}
```

Both functions follow the same structure: guard clause at the top checks for the invalid condition and returns a descriptive error, and the success path at the bottom returns the result with `nil`. Including `a` in the error message (`"cannot divide %d by zero", a`) gives the caller enough information to understand what input caused the failure without needing additional logging.

**Solution for Exercise 2:**

```go
package main

import (
    "fmt"
    "strconv"
)

func parseTemperature(s string) (float64, error) {
    t, err := strconv.ParseFloat(s, 64)
    if err != nil {
        return 0, fmt.Errorf("parseTemperature: invalid format %q: %w", s, err)
    }
    if t < -100 || t > 100 {
        return 0, fmt.Errorf("parseTemperature: value %.1f is out of range [-100, 100]", t)
    }
    return t, nil
}

func main() {
    for _, input := range []string{"36.5", "abc", "200", "-50"} {
        if temp, err := parseTemperature(input); err != nil {
            fmt.Println("Error:", err)
        } else {
            fmt.Printf("Temperature: %.1f C\n", temp)
        }
    }
}
```

The function name appears in the error message (`"parseTemperature: ..."`). This convention, used throughout the Go standard library, makes error messages traceable: as errors propagate up the call stack, each layer's prefix tells you exactly which function generated or wrapped the error. The `%w` verb wraps the original `strconv` error so callers can use `errors.As` to inspect the underlying `*strconv.NumError` if needed.

**Solution for Exercise 3:**

```go
package main

import (
    "errors"
    "fmt"
)

type InsufficientFundsError struct {
    Balance float64
    Amount  float64
}

func (e *InsufficientFundsError) Error() string {
    return fmt.Sprintf("insufficient funds: balance Rp %.0f, need Rp %.0f", e.Balance, e.Amount)
}

func withdraw(balance, amount float64) (float64, error) {
    if amount > balance {
        return balance, &InsufficientFundsError{Balance: balance, Amount: amount}
    }
    return balance - amount, nil
}

func main() {
    balance := 1000000.0

    newBalance, err := withdraw(balance, 300000)
    if err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Printf("Withdrew 300000. New balance: Rp %.0f\n", newBalance)
        balance = newBalance
    }

    _, err = withdraw(balance, 900000)
    if err != nil {
        fmt.Println("Error:", err)

        var fundErr *InsufficientFundsError
        if errors.As(err, &fundErr) {
            fmt.Printf("  Balance: Rp %.0f\n", fundErr.Balance)
            fmt.Printf("  Needed:  Rp %.0f\n", fundErr.Amount)
            fmt.Printf("  Shortage: Rp %.0f\n", fundErr.Amount-fundErr.Balance)
        }
    }
}
```

`withdraw` returns a pointer to `InsufficientFundsError` rather than a simple string because the fields `Balance` and `Amount` are useful to the caller for displaying a specific message or computing the shortage. `errors.As(err, &fundErr)` unwraps the error chain and assigns the `*InsufficientFundsError` to `fundErr`. Once extracted, the caller can access `fundErr.Balance` and `fundErr.Amount` directly without parsing the error string.

---

## Next Up - Lesson 9

Go handles errors as values, not exceptions. Functions return `(result, error)` and callers check `if err != nil` immediately. `errors.New` creates simple static errors; `fmt.Errorf` creates formatted errors; `fmt.Errorf` with `%w` wraps existing errors with context. `errors.As` unwraps an error chain to find a specific type. Custom error types implement the `error` interface with an `Error() string` method. `panic` is reserved for unrecoverable programming bugs only.

In Lesson 9, you will learn about structs and methods: how Go organizes data and behavior without classes, using composition instead of inheritance.