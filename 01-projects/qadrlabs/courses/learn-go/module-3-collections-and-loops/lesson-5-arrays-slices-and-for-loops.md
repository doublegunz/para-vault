## 1. Before You Begin

Go has two types of ordered collections: arrays and slices. Arrays have a fixed size set at compile time and are rarely used directly in application code. Slices are dynamically sized, can grow and shrink at runtime, and are the collection type you will use in virtually every Go program you write. Understanding slices and how they grow with `append` is foundational to idiomatic Go.

Go also has only one loop construct: the `for` keyword. Unlike other languages that provide `for`, `while`, `do-while`, and `foreach` as separate constructs, Go uses `for` for all of them. This simplicity is deliberate: one loop that handles every case, readable by anyone.

### What You'll Build

You will build a score analyzer that stores exam grades in a slice, calculates statistics (sum, average, min, max), and filters passing scores.

### What You'll Learn

- ✅ Arrays (fixed size) vs slices (dynamic)
- ✅ Creating slices with `make` and slice literals
- ✅ `append`, `len`, `cap`, and slicing syntax
- ✅ The `for` loop: three-component, while-style, range
- ✅ `break` and `continue`
- ✅ Common slice patterns: sum, min, max, filter

### What You'll Need

- Lesson 4 completed

---

## 2. Setup

Create a new folder `lesson-05` inside `learn-go`. Open the terminal and initialize the module:

```bash
cd lesson-05
go mod init learn-go/lesson-05
```

This creates the `go.mod` file for this lesson's module. Create `main.go` inside `lesson-05` before moving to the next section.

---

## 3. Arrays and Slices

Arrays and slices look similar in syntax but behave very differently. This section shows both so you understand the distinction before focusing on slices, which are what you will use in practice.

### Step 1: Create `main.go`

Create the file `main.go` in the `lesson-05` folder. This program demonstrates array limitations, slice operations, and the `make` function for pre-allocating slices.

### Step 2: Write the Code

Write the following program to explore both arrays and slices:

```go
package main

import "fmt"

func main() {
    var arr [5]int = [5]int{10, 20, 30, 40, 50}
    fmt.Println("Array:", arr)
    fmt.Println("Length:", len(arr))
    fmt.Println("arr[0]:", arr[0])
    fmt.Println("arr[4]:", arr[4])

    scores := []int{85, 72, 90, 65, 78}
    fmt.Println("\nSlice:", scores)
    fmt.Println("Length:", len(scores))
    fmt.Println("Capacity:", cap(scores))

    scores = append(scores, 92, 88)
    fmt.Println("After append:", scores)

    fmt.Println("\nFirst 3:", scores[:3])
    fmt.Println("Last 3:", scores[len(scores)-3:])
    fmt.Println("Middle:", scores[2:5])

    data := make([]int, 5)
    fmt.Println("\nmake([]int, 5):", data)

    data2 := make([]int, 0, 10)
    fmt.Println("make([]int, 0, 10):", data2, "len:", len(data2), "cap:", cap(data2))

    scores[0] = 95
    fmt.Println("\nAfter scores[0]=95:", scores)

    var empty []int
    fmt.Println("\nNil slice:", empty, "is nil:", empty == nil)
    empty = append(empty, 1, 2, 3)
    fmt.Println("After append:", empty)
}
```

`[5]int{10, 20, 30, 40, 50}` declares an array of exactly five integers. The size `5` is part of the type: a `[5]int` and a `[6]int` are different types and cannot be used interchangeably. Arrays are copied when passed to functions, which can be expensive for large arrays.

`[]int{85, 72, 90, 65, 78}` declares a slice literal (no size in the brackets). Slices are lightweight views into an underlying array. `len(scores)` returns the number of elements. `cap(scores)` returns the size of the underlying array. When you append beyond the current capacity, Go allocates a new, larger underlying array and copies the data.

`append(scores, 92, 88)` adds two elements to the end of the slice and returns the new slice. The original slice variable is unchanged unless you reassign it: always write `scores = append(scores, ...)`.

`scores[:3]` returns a new slice containing the first three elements (indices 0, 1, 2). The end index is exclusive. `scores[2:5]` returns elements at indices 2, 3, and 4. Omitting the start index defaults to 0; omitting the end index defaults to `len(slice)`.

`make([]int, 5)` creates a slice of length 5 with all elements initialized to their zero value (`0` for `int`). `make([]int, 0, 10)` creates a slice with zero elements but a pre-allocated capacity of 10. Pre-allocating capacity avoids repeated memory allocations when you know roughly how many elements you will append.

A `nil` slice (declared with `var empty []int`) has zero length and capacity, and `append` works on it exactly like an empty slice. You do not need to initialize a slice before appending to it.

### Step 3: Save and Run

```bash
go run main.go
```

Pay attention to the capacity values. Notice how `cap` stays at the original value until `append` exceeds it, at which point Go doubles the underlying array.

### Array vs Slice

| Feature | Array | Slice |
|---------|-------|-------|
| Size | Fixed at compile time | Dynamic (grows with `append`) |
| Declaration | `[5]int{1,2,3,4,5}` | `[]int{1,2,3,4,5}` |
| Usage | Rare | Everywhere |
| Pass to function | Copied (value) | Reference (points to same data) |

Use slices in your Go programs. Arrays exist in the language but slices are what you use 99% of the time.

---

## 4. The for Loop

Go has one loop keyword: `for`. It replaces `for`, `while`, and `do-while` from other languages. The `range` clause provides Python-style iteration over slices, maps, and strings.

Replace the content of `main.go` with the following program:

```go
package main

import "fmt"

func main() {
    fmt.Println("=== Classic for ===")
    for i := 0; i < 5; i++ {
        fmt.Print(i, " ")
    }
    fmt.Println()

    fmt.Println("\n=== While-style ===")
    count := 0
    for count < 5 {
        fmt.Print(count, " ")
        count++
    }
    fmt.Println()

    fmt.Println("\n=== Infinite with break ===")
    n := 0
    for {
        if n >= 3 {
            break
        }
        fmt.Print(n, " ")
        n++
    }
    fmt.Println()

    fruits := []string{"Apple", "Mango", "Orange", "Banana"}

    fmt.Println("\n=== Range (index + value) ===")
    for i, fruit := range fruits {
        fmt.Printf("  [%d] %s\n", i, fruit)
    }

    fmt.Println("\n=== Range (value only) ===")
    for _, fruit := range fruits {
        fmt.Println(" ", fruit)
    }

    fmt.Println("\n=== Range (index only) ===")
    for i := range fruits {
        fmt.Printf("  Index %d\n", i)
    }

    fmt.Println("\n=== Range over string ===")
    for i, ch := range "Go!" {
        fmt.Printf("  [%d] %c\n", i, ch)
    }

    fmt.Println("\n=== continue (skip odd) ===")
    for i := 0; i < 10; i++ {
        if i%2 != 0 {
            continue
        }
        fmt.Print(i, " ")
    }
    fmt.Println()
}
```

`for i := 0; i < 5; i++` is the classic three-component form: initialization, condition, and post statement. It works exactly like a `for` loop in C or Java. The while-style form `for count < 5` omits the initialization and post statement and behaves like a `while` loop. `for {}` is an infinite loop; use `break` to exit it.

`for i, fruit := range fruits` iterates over the slice, providing the index and value for each element. When you do not need the index, use `_` (the blank identifier) to discard it: `for _, fruit := range fruits`. When you only need the index (to modify elements in place), use `for i := range fruits`.

`for i, ch := range "Go!"` iterates over a string rune by rune (Unicode character by character), not byte by byte. `ch` is of type `rune` (an alias for `int32`), and `%c` prints it as a character.

`continue` skips the rest of the current iteration and jumps to the next one. `break` exits the loop immediately.

Run `go run main.go` to see all loop variations and their output.

---

## 5. Practical: Score Analyzer

Now combine slices and loops to build the score analyzer. Replace the content of `main.go` with the following program:

```go
package main

import "fmt"

func main() {
    scores := []int{85, 72, 90, 65, 78, 55, 92, 68, 81, 77}

    sum := 0
    for _, s := range scores {
        sum += s
    }
    avg := float64(sum) / float64(len(scores))

    min, max := scores[0], scores[0]
    for _, s := range scores {
        if s < min {
            min = s
        }
        if s > max {
            max = s
        }
    }

    var passed []int
    for _, s := range scores {
        if s >= 70 {
            passed = append(passed, s)
        }
    }

    fmt.Println("=== Score Analysis ===")
    fmt.Println("Scores:", scores)
    fmt.Printf("Count:   %d\n", len(scores))
    fmt.Printf("Sum:     %d\n", sum)
    fmt.Printf("Average: %.1f\n", avg)
    fmt.Printf("Min:     %d\n", min)
    fmt.Printf("Max:     %d\n", max)
    fmt.Printf("Passed:  %d/%d (%.0f%%)\n", len(passed), len(scores),
        float64(len(passed))/float64(len(scores))*100)
    fmt.Println("Passing scores:", passed)
}
```

The sum loop uses `sum += s` which is shorthand for `sum = sum + s`. This is the standard pattern for accumulating values. After the loop, `avg` requires converting both `sum` and `len(scores)` to `float64` before dividing. If you divide two `int` values, Go performs integer division and the decimal part is lost.

The min/max loop initializes both variables with `scores[0]` before iterating. This is the correct approach because you need a real value from the slice to start comparing against, not an arbitrary number like `0` which might itself be larger than all elements.

The filter loop uses `append` to build the `passed` slice. Starting with `var passed []int` (a `nil` slice), the loop appends qualifying scores. `append` works on `nil` slices, so no initialization is needed before the loop.

Run `go run main.go` to verify the statistics. The pass rate should be 70% since 7 out of 10 scores are 70 or above.

---

## 6. Fix the Errors in Your Code

These three errors are among the most frequent mistakes when working with Go slices for the first time.

**Error 1: Appending to an array.**

Arrays have a fixed size and cannot grow. The `append` function only works with slices.

```go
// Wrong: arr is an array, append is not valid
arr := [5]int{1, 2, 3, 4, 5}
arr = append(arr, 6)

// Correct: use a slice (no size in the brackets)
arr := []int{1, 2, 3, 4, 5}
arr = append(arr, 6)
```

The compile error for the wrong version is `first argument to append must be a slice; have [5]int`. Removing the `5` from the brackets changes the declaration from a fixed-size array to a dynamic slice, which `append` can grow as needed.

**Error 2: Index out of range.**

Accessing a slice with an index that does not exist causes a runtime panic. Go checks bounds at runtime, not at compile time.

```go
// Wrong: index 3 does not exist in a 3-element slice
s := []int{10, 20, 30}
fmt.Println(s[3])

// Correct: check length before accessing
s := []int{10, 20, 30}
if len(s) > 3 {
    fmt.Println(s[3])
}
```

The panic message is `runtime error: index out of range [3] with length 3`. Valid indices for a slice of length 3 are 0, 1, and 2. Always use `len(s)` to check bounds before accessing elements when the index is dynamic.

**Error 3: Forgetting to reassign the result of `append`.**

`append` does not modify the original slice in place. It returns a new slice (which may point to a new underlying array). If you discard the return value, the original slice remains unchanged.

```go
// Wrong: the return value of append is discarded
nums := []int{1, 2, 3}
append(nums, 4)
fmt.Println(nums) // still [1 2 3]

// Correct: always reassign the result
nums := []int{1, 2, 3}
nums = append(nums, 4)
fmt.Println(nums) // [1 2 3 4]
```

The Go compiler actually catches the discarded return value and produces the error `append(nums, 4) evaluated but not used`. Always write `nums = append(nums, 4)` to capture the returned slice.

---

## 7. Exercises

**Exercise 1:** Create a slice of 7 daily temperatures (as integers). Use a `for range` loop to find the hottest and coldest days. Display the day name (Monday through Sunday), the temperature value for the hottest day, and the temperature value for the coldest day.

**Exercise 2:** Write a program that reads numbers from the user until they enter `0`. Store each non-zero number in a slice. After the loop, display the count of numbers entered, their sum, and their average.

**Exercise 3:** Create a slice of 10 names (mix short and long names). Use a loop to build a second slice containing only names that are longer than 4 characters. Display both slices.

---

## 8. Solutions

**Solution for Exercise 1:**

```go
package main

import "fmt"

func main() {
    temps := []int{32, 28, 35, 30, 33, 29, 31}
    days := []string{"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"}

    minI, maxI := 0, 0
    for i, t := range temps {
        if t < temps[minI] {
            minI = i
        }
        if t > temps[maxI] {
            maxI = i
        }
    }

    fmt.Printf("Hottest: %s (%d C)\n", days[maxI], temps[maxI])
    fmt.Printf("Coldest: %s (%d C)\n", days[minI], temps[minI])
}
```

Instead of tracking the actual temperature values for min and max, the solution tracks the indices (`minI` and `maxI`). Both start at `0`, meaning the first element is initially assumed to be both the hottest and coldest. The loop updates the index whenever it finds a more extreme temperature. At the end, both `days[maxI]` and `temps[maxI]` can be accessed using the same index, so you automatically have both the day name and the temperature value without duplicating data.

**Solution for Exercise 2:**

```go
package main

import "fmt"

func main() {
    var nums []int

    for {
        var n int
        fmt.Print("Number (0 to stop): ")
        fmt.Scan(&n)
        if n == 0 {
            break
        }
        nums = append(nums, n)
    }

    if len(nums) == 0 {
        fmt.Println("No numbers entered.")
        return
    }

    sum := 0
    for _, n := range nums {
        sum += n
    }
    fmt.Printf("Count: %d, Sum: %d, Avg: %.1f\n", len(nums), sum, float64(sum)/float64(len(nums)))
}
```

The infinite `for` loop reads one number per iteration. When the user enters `0`, `break` exits the loop. The `if len(nums) == 0` guard prevents a division-by-zero panic in cases where the user immediately enters `0`. `float64(sum)/float64(len(nums))` ensures the average is computed as a floating-point number, not truncated integer division.

**Solution for Exercise 3:**

```go
package main

import "fmt"

func main() {
    names := []string{"Andi", "Bo", "Citra", "Dewi", "Eka", "Fani", "Gun", "Hadi", "Ira", "Jo"}

    var long []string
    for _, n := range names {
        if len(n) > 4 {
            long = append(long, n)
        }
    }

    fmt.Println("All:", names)
    fmt.Println("Long:", long)
}
```

`len(n)` when used on a string returns the number of bytes, which for ASCII characters is the same as the number of characters. Names like `"Citra"`, `"Fani"`, and `"Hadi"` have 5 characters and pass the filter. Names like `"Andi"`, `"Bo"`, `"Gun"`, `"Ira"`, and `"Jo"` have 4 or fewer characters and are excluded. The `long` slice starts as `nil` and grows with each qualifying name.

---

## Next Up - Lesson 6

Slices are Go's primary collection type: dynamic, flexible, and used everywhere. `append` grows slices but always returns a new slice that must be reassigned. `for` is Go's only loop: use the three-component form for counting, the single-condition form for while-style loops, the empty form for infinite loops, and `range` for iterating over slices and strings. `break` exits a loop immediately; `continue` skips to the next iteration.

In Lesson 6, you will learn about maps: Go's key-value collection type for storing and looking up data by name rather than by position.