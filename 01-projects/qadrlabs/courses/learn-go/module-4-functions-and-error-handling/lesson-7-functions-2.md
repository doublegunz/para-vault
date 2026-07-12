## 1. Before You Begin

Functions in Go can return multiple values. This is not a workaround or special syntax: it is a core language feature. The most important use of multiple returns is the pattern `result, err := doSomething()`, which you will write hundreds of times in real Go programs. Instead of exceptions that interrupt the call stack, Go returns errors as regular values that you handle immediately at the call site.

In Lesson 6, you worked with maps and loops to process collections of data. Now you will learn how to organize that logic into reusable, testable functions. Good function design is what separates a script from a maintainable program.

### What You'll Build

You will build a collection of utility functions for data processing and a statistics calculator that demonstrates Go's multi-return pattern, variadic arguments, and closures.

### What You'll Learn

- ✅ Function declaration with `func`
- ✅ Parameters and return values (typed)
- ✅ Multiple return values (Go's foundation for error handling)
- ✅ Named return values
- ✅ Variadic functions (`...`)
- ✅ Anonymous functions and closures
- ✅ Functions as values (first-class functions)

### What You'll Need

- Lesson 6 completed

---

## 2. Setup

Create a new folder `lesson-07` inside `learn-go`. Open the terminal and initialize the module:

```bash
cd lesson-07
go mod init learn-go/lesson-07
```

This creates the `go.mod` file for this lesson. Create `main.go` inside `lesson-07` before continuing.

---

## 3. Function Basics

Go functions are declared with the `func` keyword followed by the function name, parameters in parentheses, and return types. When a function returns multiple values, the return types are listed in parentheses. This section introduces all the fundamental function forms you will use throughout the rest of the course.

### Step 1: Create `main.go`

Create the file `main.go` in the `lesson-07` folder. This file will define several functions above `main` and call them from `main` to demonstrate different return patterns.

### Step 2: Write the Code

Write the following program to see all function forms in a single file:

```go
package main

import "fmt"

func greet(name string) {
    fmt.Printf("Hello, %s!\n", name)
}

func add(a, b int) int {
    return a + b
}

func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, fmt.Errorf("cannot divide by zero")
    }
    return a / b, nil
}

func stats(numbers []int) (min, max, sum int, avg float64) {
    if len(numbers) == 0 {
        return 0, 0, 0, 0
    }
    min, max = numbers[0], numbers[0]
    for _, n := range numbers {
        sum += n
        if n < min {
            min = n
        }
        if n > max {
            max = n
        }
    }
    avg = float64(sum) / float64(len(numbers))
    return
}

func sumAll(nums ...int) int {
    total := 0
    for _, n := range nums {
        total += n
    }
    return total
}

func main() {
    greet("Budi")
    fmt.Println("3 + 5 =", add(3, 5))

    result, err := divide(10, 3)
    if err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Printf("10 / 3 = %.2f\n", result)
    }

    _, err2 := divide(10, 0)
    if err2 != nil {
        fmt.Println("Error:", err2)
    }

    scores := []int{85, 72, 90, 65, 78}
    lo, hi, total, average := stats(scores)
    fmt.Printf("\nScores: %v\nMin: %d, Max: %d, Sum: %d, Avg: %.1f\n",
        scores, lo, hi, total, average)

    fmt.Println("\nSum(1,2,3):", sumAll(1, 2, 3))
    fmt.Println("Sum(10,20,30,40):", sumAll(10, 20, 30, 40))

    nums := []int{5, 10, 15, 20}
    fmt.Println("Sum(slice...):", sumAll(nums...))
}
```

`func greet(name string)` has no return value. `func add(a, b int) int` shows that when multiple parameters share the same type, you can write the type once after the last parameter name.

`func divide(a, b float64) (float64, error)` is the multi-return pattern. It returns both the result and an error. `nil` is Go's zero value for the `error` type, meaning "no error occurred". The caller uses `result, err := divide(10, 3)` and immediately checks `if err != nil`. The `_` in `_, err2 := divide(10, 0)` discards the `float64` result when only the error matters.

`func stats(numbers []int) (min, max, sum int, avg float64)` uses named return values. The return variables `min`, `max`, `sum`, and `avg` are declared as part of the function signature and initialized to their zero values. The bare `return` at the end returns all named variables automatically. Named returns are useful when a function returns many values, because they serve as documentation about what each return value represents.

`func sumAll(nums ...int)` is a variadic function. The `...int` means it accepts zero or more `int` arguments. Inside the function, `nums` is a `[]int` slice. To pass an existing slice to a variadic function, add `...` after the slice: `sumAll(nums...)`.

### Step 3: Save and Run

```bash
go run main.go
```

Verify that the divide function correctly handles both the success case (10 / 3 = 3.33) and the error case (division by zero).

---

## 4. Anonymous Functions and Closures

Go treats functions as first-class values: you can assign them to variables, pass them as arguments, and return them from other functions. This enables closures, which are functions that capture and remember variables from their surrounding scope.

Replace the content of `main.go` with the following program:

```go
package main

import (
    "fmt"
    "sort"
)

func makeCounter() func() int {
    count := 0
    return func() int {
        count++
        return count
    }
}

func filter(nums []int, predicate func(int) bool) []int {
    var result []int
    for _, n := range nums {
        if predicate(n) {
            result = append(result, n)
        }
    }
    return result
}

func main() {
    multiply := func(a, b int) int {
        return a * b
    }
    fmt.Println("3 * 7 =", multiply(3, 7))

    result := func(x int) int {
        return x * x
    }(5)
    fmt.Println("5 squared:", result)

    counter := makeCounter()
    fmt.Println(counter())
    fmt.Println(counter())
    fmt.Println(counter())

    numbers := []int{42, 17, 8, 33, 25}
    sort.Slice(numbers, func(i, j int) bool {
        return numbers[i] < numbers[j]
    })
    fmt.Println("\nSorted:", numbers)

    evens := filter(numbers, func(n int) bool {
        return n%2 == 0
    })
    fmt.Println("Evens:", evens)
}
```

`multiply := func(a, b int) int { return a * b }` assigns an anonymous function to a variable. Once assigned, `multiply(3, 7)` calls it exactly like a named function. The immediately-invoked form `func(x int) int { return x * x }(5)` declares and calls the function in a single expression.

`makeCounter()` returns a closure: a function that captures the variable `count` from its enclosing scope. Each time you call `counter()`, it increments and returns the same `count` variable. The variable persists between calls because the closure holds a reference to it, not a copy. Each call to `makeCounter()` creates a new, independent `count` variable.

`sort.Slice(numbers, func(i, j int) bool { ... })` passes an anonymous function as a callback to sort. The function receives two indices and returns `true` if the element at `i` should appear before the element at `j`. This is Go's standard pattern for sorting arbitrary types with a custom comparator.

`filter(numbers, func(n int) bool { return n%2 == 0 })` demonstrates a higher-order function: `filter` takes a function as a parameter and applies it to each element. The anonymous function passed as `predicate` is called for each number to decide whether to include it.

Run `go run main.go` to verify the counter increments correctly and the filter returns only even numbers.

---

## 5. Fix the Errors in Your Code

These three errors are the most common mistakes when working with Go functions.

**Error 1: Silently discarding errors.**

Using `_` to discard error return values hides failures. If the function fails, you proceed with a zero-value result that will cause incorrect behavior or a panic later. Always check errors.

```go
// Wrong: error is discarded, result is 0 if divide fails
result, _ := divide(10, 0)
fmt.Println(result)

// Correct: always check the error before using the result
result, err := divide(10, 0)
if err != nil {
    fmt.Println("Error:", err)
    return
}
fmt.Println(result)
```

Discarding an error with `_` is sometimes appropriate (for example, when writing to a byte buffer that cannot fail), but it should always be a deliberate, documented choice. When you discard an error for a genuinely fallible operation, the resulting bug is often very difficult to trace back to its source.

**Error 2: Wrong number of return values.**

If a function declares two return values, every `return` statement must provide exactly two values. A mismatch is a compile error.

```go
// Wrong: function declares (string, int) but returns only string
func getInfo() (string, int) {
    return "Budi"
}

// Correct: return both declared values
func getInfo() (string, int) {
    return "Budi", 25
}
```

When using named returns, a bare `return` returns all named values. If you use a bare `return` in a function with unnamed returns, it is a compile error. If you add a bare `return` to a function that should return values, use named return variables.

**Error 3: Discarding return values from non-error functions.**

Go allows you to call a function and discard all its return values, unlike unused local variables which are banned. However, discarding the return value of a function that computes a result is usually a logic bug.

```go
// Wrong: result of add is computed but never used (logic bug)
add(3, 5)

// Correct: assign the result or use it immediately
total := add(3, 5)
fmt.Println(total)
```

The Go compiler does not reject this code, but `go vet` may warn about it depending on the function. If you genuinely want to discard a return value intentionally, write `_ = add(3, 5)` to signal that the discard is deliberate, not accidental.

---

## 6. Exercises

**Exercise 1:** Write a function `isPrime(n int) bool` that returns `true` if `n` is a prime number. Write a second function `primesInRange(start, end int) []int` that uses `isPrime` to collect all prime numbers in the given range. Call both from `main` to find all primes between 1 and 50.

**Exercise 2:** Write a function `minMax(nums []int) (int, int, error)` that returns the minimum and maximum values in a slice. Return an error if the slice is empty. Call it from `main` with both a valid slice and an empty slice, and handle both outcomes.

**Exercise 3:** Write a `transform(nums []int, fn func(int) int) []int` function that applies `fn` to every element and returns a new slice with the results. Test it from `main` by passing three different anonymous functions: one that doubles values, one that squares them, and one that negates them.

---

## 7. Solutions

**Solution for Exercise 1:**

```go
package main

import "fmt"

func isPrime(n int) bool {
    if n < 2 {
        return false
    }
    for i := 2; i*i <= n; i++ {
        if n%i == 0 {
            return false
        }
    }
    return true
}

func primesInRange(start, end int) []int {
    var primes []int
    for i := start; i <= end; i++ {
        if isPrime(i) {
            primes = append(primes, i)
        }
    }
    return primes
}

func main() {
    primes := primesInRange(1, 50)
    fmt.Println("Primes 1-50:", primes)
    fmt.Println("Count:", len(primes))
}
```

`isPrime` checks divisibility up to the square root of `n` (`i*i <= n`). Any factor larger than the square root would have a corresponding factor smaller than the square root, so you only need to check up to that point. This makes the function efficient even for large numbers. `primesInRange` calls `isPrime` for each integer in the range and appends qualifying numbers to the result slice.

**Solution for Exercise 2:**

```go
package main

import (
    "fmt"
)

func minMax(nums []int) (int, int, error) {
    if len(nums) == 0 {
        return 0, 0, fmt.Errorf("minMax: empty slice")
    }
    mn, mx := nums[0], nums[0]
    for _, n := range nums {
        if n < mn {
            mn = n
        }
        if n > mx {
            mx = n
        }
    }
    return mn, mx, nil
}

func main() {
    scores := []int{85, 72, 90, 65, 78}
    mn, mx, err := minMax(scores)
    if err != nil {
        fmt.Println("Error:", err)
    } else {
        fmt.Printf("Min: %d, Max: %d\n", mn, mx)
    }

    _, _, err = minMax([]int{})
    if err != nil {
        fmt.Println("Error:", err)
    }
}
```

The function guards against an empty slice at the top. Without this guard, `nums[0]` would panic with an index-out-of-range error. Returning an error for an empty slice is better than panicking because the caller can handle it gracefully. The three-value return `mn, mx, nil` on success and `0, 0, error` on failure follows Go's multi-return convention: the zero values for failed returns are irrelevant, but they must still be returned to satisfy the function signature.

**Solution for Exercise 3:**

```go
package main

import "fmt"

func transform(nums []int, fn func(int) int) []int {
    result := make([]int, len(nums))
    for i, n := range nums {
        result[i] = fn(n)
    }
    return result
}

func main() {
    nums := []int{1, 2, 3, 4, 5}

    doubled := transform(nums, func(n int) int { return n * 2 })
    squared := transform(nums, func(n int) int { return n * n })
    negated := transform(nums, func(n int) int { return -n })

    fmt.Println("Original:", nums)
    fmt.Println("Doubled: ", doubled)
    fmt.Println("Squared: ", squared)
    fmt.Println("Negated: ", negated)
}
```

`make([]int, len(nums))` pre-allocates a result slice of the same length as the input, with all elements initialized to `0`. Assigning `result[i] = fn(n)` fills each position directly, which is more efficient than using `append` in a loop because no reallocation occurs. The anonymous functions passed as `fn` are concise: each fits on one line because they contain a single expression. This is a typical use of anonymous functions in Go: short, focused operations passed to higher-order functions.

---

## Next Up - Lesson 8

Go functions support multiple return values, and the pattern `result, err := fn()` followed by `if err != nil` is the foundation of all error handling in Go. Variadic functions accept any number of arguments using `...`. Functions are first-class values: they can be assigned to variables, passed as arguments, and returned from other functions. Closures capture variables from their enclosing scope and remember them across calls.

In Lesson 8, you will learn about Go's unique error handling pattern in depth: returning errors as values, wrapping errors with context, and creating custom error types.