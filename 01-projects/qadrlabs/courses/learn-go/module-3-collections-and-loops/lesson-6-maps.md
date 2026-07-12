## 1. Before You Begin

Slices store ordered data by index. Maps store data by key: a student name maps to a score, a product code maps to a price, a word maps to how many times it appears. Maps are Go's equivalent of dictionaries in Python, hash maps in Java, or associative arrays in PHP. They are one of the most useful data structures in any language, and Go's map syntax is clean and consistent.

In Lesson 5, you learned slices and the `for` loop. Maps build on the same iteration pattern but address a different problem: lookup by name rather than by position. When you know the key, retrieving a value from a map is an O(1) operation regardless of how many entries are stored.

### What You'll Build

You will build a word frequency counter that analyzes a sentence and counts how many times each word appears, and a student grade lookup system that groups students by city using maps of slices.

### What You'll Learn

- ✅ Creating maps with `make` and map literals
- ✅ Adding, accessing, updating, and deleting entries
- ✅ The comma-ok idiom for checking existence
- ✅ Iterating maps with `for range`
- ✅ Maps of slices and nested maps
- ✅ Common patterns: counting, grouping, lookup

### What You'll Need

- Lesson 5 completed

---

## 2. Setup

Create a new folder `lesson-06` inside `learn-go`. Open the terminal and initialize the module:

```bash
cd lesson-06
go mod init learn-go/lesson-06
```

This creates the `go.mod` file for this lesson. Create `main.go` inside `lesson-06` before continuing.

---

## 3. Map Basics

Maps in Go are declared with a key type and a value type: `map[KeyType]ValueType`. The key can be any comparable type (string, int, bool), and the value can be any type including slices and other maps.

### Step 1: Create `main.go`

Create `main.go` in the `lesson-06` folder. This file will demonstrate map creation, access, update, deletion, and the comma-ok idiom.

### Step 2: Write the Code

Write the following program to see all fundamental map operations:

```go
package main

import "fmt"

func main() {
    scores := map[string]int{
        "Andi":  85,
        "Budi":  72,
        "Citra": 90,
    }
    fmt.Println("Scores:", scores)

    prices := make(map[string]int)
    prices["Laptop"] = 8500000
    prices["Mouse"] = 150000
    prices["Keyboard"] = 750000
    fmt.Println("Prices:", prices)

    fmt.Println("\nAndi's score:", scores["Andi"])

    scores["Budi"] = 80
    fmt.Println("Budi updated:", scores["Budi"])

    delete(scores, "Citra")
    fmt.Println("After delete Citra:", scores)

    value, exists := scores["Dewi"]
    if exists {
        fmt.Println("Dewi:", value)
    } else {
        fmt.Println("Dewi not found")
    }

    if val, ok := scores["Andi"]; ok {
        fmt.Println("Andi found:", val)
    }

    fmt.Println("\nMap size:", len(scores))

    fmt.Println("\n=== All Prices ===")
    for product, price := range prices {
        fmt.Printf("  %s: Rp %d\n", product, price)
    }
}
```

`map[string]int{"Andi": 85, "Budi": 72, "Citra": 90}` is a map literal: it declares and initializes the map in one step. `make(map[string]int)` creates an empty, initialized map ready to receive entries. You can also write `map[string]int{}` for an empty map literal, but `make` is the conventional style when starting with an empty map.

`scores["Andi"]` reads the value associated with the key `"Andi"`. `scores["Budi"] = 80` overwrites the existing value for key `"Budi"`. `delete(scores, "Citra")` removes the entry entirely. If the key does not exist, `delete` does nothing.

`value, exists := scores["Dewi"]` uses the comma-ok idiom. When you access a map with a missing key using just `value := scores["Dewi"]`, Go returns the zero value for the value type (`0` for `int`) silently. This can cause bugs where you think a key exists but it does not. The comma-ok form gives you an explicit boolean `exists` to check.

`for product, price := range prices` iterates over the map. Note that map iteration order in Go is deliberately randomized on each run. Never write code that depends on a specific iteration order.

### Step 3: Save and Run

```bash
go run main.go
```

Run the program multiple times and observe that the prices print in a different order each time. This confirms that Go randomizes map iteration.

### The Comma-Ok Idiom

This pattern is central to safe map access in Go:

```go
value, ok := myMap[key]
```

`ok` is `true` if the key exists, `false` if not. Without the comma-ok, accessing a missing key returns the zero value silently, which can lead to calculations or lookups proceeding with incorrect data.

---

## 4. Practical: Word Frequency Counter

One of the most common uses of maps is counting occurrences. This pattern exploits Go's zero value: when a key does not yet exist in the map, its value is `0`, so you can increment it directly without initializing it first.

Replace the content of `main.go` with the following program:

```go
package main

import (
    "fmt"
    "strings"
)

func main() {
    text := "go is simple go is fast go is fun python is also fun"
    words := strings.Fields(text)

    freq := make(map[string]int)
    for _, word := range words {
        freq[word]++
    }

    fmt.Println("=== Word Frequency ===")
    for word, count := range freq {
        fmt.Printf("  %-10s %d\n", word, count)
    }

    maxWord := ""
    maxCount := 0
    for word, count := range freq {
        if count > maxCount {
            maxWord = word
            maxCount = count
        }
    }
    fmt.Printf("\nMost frequent: %q (%d times)\n", maxWord, maxCount)
}
```

`strings.Fields(text)` splits the text on any whitespace and returns a slice of words. It handles multiple consecutive spaces better than `strings.Split(text, " ")`.

`freq[word]++` is the counting pattern. When `word` appears for the first time, `freq[word]` returns the zero value `0`, and `++` increments it to `1`. On the second occurrence, `freq[word]` is `1`, and `++` makes it `2`. This works because Go's map zero value for `int` is `0`, so you never need to initialize a counter before incrementing it.

The second `for range` loop finds the most frequent word by comparing each count against `maxCount`. Starting `maxCount` at `0` works correctly here because all word counts are at least `1`.

Run `go run main.go` to see the word frequencies. The word `"go"` should appear 3 times and `"is"` should appear 4 times.

---

## 5. Maps of Slices

Maps can hold any value type, including slices. This is useful for grouping: one key maps to multiple values. The pattern is a `map[string][]string` (a map from string to a slice of strings).

Replace the content of `main.go` with the following program:

```go
package main

import "fmt"

func main() {
    students := map[string][]string{
        "Jakarta":  {"Andi", "Dewi"},
        "Bandung":  {"Budi", "Eka"},
        "Surabaya": {"Citra"},
    }

    students["Jakarta"] = append(students["Jakarta"], "Fani")
    students["Yogyakarta"] = []string{"Gita"}

    fmt.Println("=== Students by City ===")
    for city, names := range students {
        fmt.Printf("  %s: %v\n", city, names)
    }

    total := 0
    for _, names := range students {
        total += len(names)
    }
    fmt.Println("\nTotal students:", total)
}
```

`map[string][]string{"Jakarta": {"Andi", "Dewi"}}` creates a map where each key is a city name and each value is a slice of student names. Adding a student to Jakarta uses `students["Jakarta"] = append(students["Jakarta"], "Fani")`. This reads the existing slice for Jakarta, appends the new name, and writes the updated slice back to the map.

Adding a new city is as simple as `students["Yogyakarta"] = []string{"Gita"}`. There is no need to initialize the map entry before writing to it, because you are assigning a `[]string` value directly.

The total students count iterates over all cities and sums the length of each city's name slice. Using `_` discards the city key since only the slice length is needed.

Run `go run main.go` to see the grouping output. Notice that Jakarta now has three students.

---

## 6. Fix the Errors in Your Code

These three errors are the most common mistakes when working with maps in Go.

**Error 1: Writing to a nil map.**

A map declared with `var m map[string]int` is `nil`. You can read from a nil map safely (it returns the zero value), but writing to it causes a runtime panic.

```go
// Wrong: m is nil, assignment panics
var m map[string]int
m["key"] = 1

// Correct: initialize the map before writing
m := make(map[string]int)
m["key"] = 1
```

The runtime error is `assignment to entry in nil map`. The fix is to always initialize a map with `make` or a map literal before writing to it. Reading from a nil map returns the zero value safely, but writing always requires initialization.

**Error 2: Depending on map iteration order.**

Go randomizes map iteration order intentionally. Writing code that relies on a specific key order is a bug that may work by chance initially but will fail unpredictably in production.

```go
// Wrong: assumes keys iterate in insertion order
months := map[int]string{1: "Jan", 2: "Feb", 3: "Mar"}
for num, name := range months {
    fmt.Println(num, name) // order is NOT guaranteed
}

// Correct: if order matters, collect keys, sort, then iterate
import "sort"
keys := make([]int, 0, len(months))
for k := range months {
    keys = append(keys, k)
}
sort.Ints(keys)
for _, k := range keys {
    fmt.Println(k, months[k])
}
```

If your program requires a specific output order (for display, CSV export, etc.), always sort the keys explicitly before iterating. The `sort` package provides `sort.Strings`, `sort.Ints`, and a generic sort function for custom types.

**Error 3: Comparing maps with `==`.**

Go does not allow maps to be compared with the `==` operator. The only comparison allowed is `myMap == nil`.

```go
// Wrong: compile error, cannot compare maps with ==
a := map[string]int{"x": 1}
b := map[string]int{"x": 1}
fmt.Println(a == b)

// Correct: compare element by element manually
equal := len(a) == len(b)
if equal {
    for k, v := range a {
        if b[k] != v {
            equal = false
            break
        }
    }
}
fmt.Println("Equal:", equal)
```

The compile error is `invalid operation: a == b (map can only be compared to nil)`. For testing purposes only, you can use `reflect.DeepEqual(a, b)`, but in production code, write the comparison explicitly so the logic is visible.

---

## 7. Exercises

**Exercise 1:** Create a map of 5 country capitals where the key is the country name and the value is the capital city. Ask the user to type a country name and display its capital. Handle the case where the country is not in the map.

**Exercise 2:** Create a program that counts the frequency of each character in the string `"hello world"`. Use a `map[rune]int` and iterate over the string with `for range`. Display the result.

**Exercise 3:** Create a student grade lookup where each student maps to a slice of three scores. Calculate and display each student's average score. Find and display the student with the highest average.

---

## 8. Solutions

**Solution for Exercise 1:**

```go
package main

import "fmt"

func main() {
    capitals := map[string]string{
        "Indonesia":  "Jakarta",
        "Japan":      "Tokyo",
        "Australia":  "Canberra",
        "Germany":    "Berlin",
        "Brazil":     "Brasilia",
    }

    var country string
    fmt.Print("Enter country: ")
    fmt.Scan(&country)

    if capital, ok := capitals[country]; ok {
        fmt.Printf("Capital of %s: %s\n", country, capital)
    } else {
        fmt.Printf("%s not found in the database\n", country)
    }
}
```

`if capital, ok := capitals[country]; ok` uses the comma-ok idiom inside an `if` initialization statement. If the country exists, `capital` holds the city name and `ok` is `true`. If not, `ok` is `false` and the `else` branch runs. Without the comma-ok, a missing country would silently return the empty string `""`, which could be printed as an empty capital city with no indication of the error.

**Solution for Exercise 2:**

```go
package main

import "fmt"

func main() {
    text := "hello world"
    freq := make(map[rune]int)

    for _, ch := range text {
        freq[ch]++
    }

    for ch, count := range freq {
        fmt.Printf("  '%c': %d\n", ch, count)
    }
}
```

`for _, ch := range text` iterates over the string rune by rune. Each `ch` is of type `rune` (an alias for `int32`), which is why the map is declared as `map[rune]int`. `freq[ch]++` follows the same counting pattern as the word frequency counter. The space character (`' '`) is also a valid rune and will appear in the output with a count of `1`.

**Solution for Exercise 3:**

```go
package main

import "fmt"

func main() {
    grades := map[string][]int{
        "Andi":  {85, 78, 90},
        "Budi":  {72, 65, 80},
        "Citra": {92, 88, 95},
    }

    bestName := ""
    bestAvg := 0.0

    for name, scores := range grades {
        sum := 0
        for _, s := range scores {
            sum += s
        }
        avg := float64(sum) / float64(len(scores))
        fmt.Printf("%s: avg %.1f\n", name, avg)
        if avg > bestAvg {
            bestAvg = avg
            bestName = name
        }
    }

    fmt.Printf("Best student: %s (%.1f)\n", bestName, bestAvg)
}
```

The outer loop iterates over each student. The inner loop sums their three scores. `float64(sum) / float64(len(scores))` computes the average as a floating-point number. The `if avg > bestAvg` check tracks the highest average seen so far and updates `bestName` whenever a higher average is found. Citra has the highest average at 91.7.

---

## Next Up - Lesson 7

Maps store key-value pairs and provide O(1) lookup by key. Create them with `make(map[K]V)` or map literals. The comma-ok idiom (`val, ok := m[key]`) is the safe way to check whether a key exists before using its value. `for range` iterates maps in random order. Zero value for missing keys is the type's zero value, which enables the counting pattern `freq[word]++`. Maps of slices (`map[string][]string`) group multiple values under one key.

In Lesson 7, you will learn about functions: how to write reusable code blocks with multiple return values, variadic parameters, and closures.