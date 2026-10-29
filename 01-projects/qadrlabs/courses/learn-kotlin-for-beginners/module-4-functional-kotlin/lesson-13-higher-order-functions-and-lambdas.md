## 1. Before You Begin

In Lesson 8 we used iterator-style functions like `filter`, `map`, and `count` on lists, with little snippets of code in curly braces (`{ it.length > 10 }`) passed as arguments. Those snippets are called lambdas, and the functions that accept them are called higher-order functions because they take other functions as arguments. This combination, lambdas plus higher-order functions, is one of the most expressive features of modern Kotlin and the heart of the functional style that makes idiomatic Kotlin feel so different from idiomatic Java. By the end of this lesson, the iterator chains you have been reading will become natural to write yourself, and the standard library's rich vocabulary of collection operations will be available for you to use.

The conceptual shift is that functions are values in Kotlin, not just code structures. A function can be stored in a variable, passed as an argument, returned from another function, or constructed inline as a lambda expression. This is the same idea that makes JavaScript and Python comfortable for many programmers: when functions are values, you can express patterns that would otherwise require classes and methods. In Kotlin's strongly typed setting, function types are also explicit (`(Int) -> Int` is the type of a function from `Int` to `Int`), which gives you the expressiveness of dynamic-language functional programming with the safety of static types. Once you have internalized the syntax, you start writing more concise code that reads as a description of what you want rather than as a series of low-level operations.

### What You'll Build

A series of small examples inside `Main.kt` that show every aspect of lambda and higher-order function usage. You will rewrite a loop-based version of code from Lesson 8 in idiomatic chained-iterator style, define your own higher-order function that takes a lambda parameter, store a function in a variable and pass it around, and use the standard library's collection functions to compute summaries about a list of Catatku entries. By the end you will be writing iterator chains naturally, and the patterns will feel like the right way to express data transformations.

### What You'll Learn

- ✅ How to write lambda expressions with the `{ x -> ... }` syntax
- ✅ The difference between explicit parameter naming and the implicit `it`
- ✅ Function types like `(Int) -> Int` and how to declare and use them
- ✅ How to pass lambdas as arguments and use trailing lambda syntax
- ✅ The most useful collection functions: `filter`, `map`, `fold`, `reduce`, `forEach`, `sumOf`, `count`, `any`, `all`

### What You'll Need

- The `catatku` Gradle project from previous lessons
- A solid understanding of functions from Lesson 6 and collections from Lesson 8
- About forty-five minutes
- Patience for syntax that may look strange at first; lambda code rewards careful reading

---

## 2. Your First Lambda

A lambda is an anonymous function. It has no name, no formal declaration, just a parameter list and a body in curly braces. The simplest case is a lambda with one parameter that returns a value.

### Step 1: Write a Lambda

Open `Main.kt` and replace its contents with this experiment. We will use a higher-order function from the standard library to demonstrate.

```kotlin
fun main() {
    val numbers = listOf(1, 2, 3, 4, 5)
    
    val doubled = numbers.map({ x -> x * 2 })
    println("Doubled: $doubled")
}
```

Save and run. Output:

```text
Doubled: [2, 4, 6, 8, 10]
```

Walk through what happened. The `map` method on a list takes a function and applies it to every element, producing a new list. The argument we passed is a lambda: `{ x -> x * 2 }`. Inside the curly braces, `x ->` declares a parameter named `x`, and `x * 2` is the body. The lambda takes one `Int` (because the list contains `Int` values) and returns an `Int`. The whole `map` call produces a new list where each element is twice the original.

The syntax `{ parameter -> body }` is universal for Kotlin lambdas. You can have multiple parameters separated by commas (`{ a, b -> a + b }`), no parameters (`{ println("hi") }`), and the body can be multiple statements with the last one as the value. We will explore each of these as the lesson progresses.

### Step 2: Use the Trailing Lambda Syntax

When a function's last parameter is a function (which `map` is), you can write the lambda outside the parentheses, after them. This is called the trailing lambda syntax, and it is the more idiomatic Kotlin way:

```kotlin
fun main() {
    val numbers = listOf(1, 2, 3, 4, 5)
    
    val doubled = numbers.map { x -> x * 2 }
    println("Doubled: $doubled")
}
```

Save and run. Output:

```text
Doubled: [2, 4, 6, 8, 10]
```

The output is the same. The only change is that we moved the lambda from inside `map(...)` to after `map`. When the function takes only the lambda (no other arguments), you can also drop the parentheses entirely, which is what we did here. If `map` had other arguments, they would still go in parentheses and the lambda would follow them, in the shape `someFunction(arg1, arg2) { lambdaParam -> lambdaBody }`.

This convention is one of the small features that makes Kotlin code feel uniquely concise. The trailing lambda is visually outside the function call, which makes it easy to read as a "block of code passed in", similar to how a `for` loop body or an `if` body looks.

### Step 3: The it Shortcut

When a lambda has exactly one parameter, you can omit the parameter declaration and use the implicit name `it`:

```kotlin
fun main() {
    val numbers = listOf(1, 2, 3, 4, 5)
    
    val doubled = numbers.map { it * 2 }
    val even = numbers.filter { it % 2 == 0 }
    val sum = numbers.sumOf { it }
    
    println("Doubled: $doubled")
    println("Even: $even")
    println("Sum: $sum")
}
```

Save and run. Output:

```text
Doubled: [2, 4, 6, 8, 10]
Even: [2, 4]
Sum: 15
```

The `{ it * 2 }` is shorthand for `{ x -> x * 2 }`, where `it` is the implicit name for the single parameter. This is the idiomatic style for short lambdas with one obvious parameter. It is universally understood among Kotlin programmers and shows up everywhere in real code.

For longer lambdas or when the meaning of the parameter is not immediately obvious from context, naming the parameter explicitly (as `x ->`, `entry ->`, or whatever fits) is clearer. As a habit, use `it` for short lambdas where the meaning is obvious, and use named parameters for longer or less obvious cases.

---

## 3. Function Types and Storing Functions

A function in Kotlin has a type, just like an `Int` or a `String` does. The type encodes the parameter types and the return type. You can declare variables with function types and pass them around like any other value.

### Step 1: Function Types in a Variable

Replace the body of `main` with this:

```kotlin
fun main() {
    val double: (Int) -> Int = { x -> x * 2 }
    val isEven: (Int) -> Boolean = { it % 2 == 0 }
    
    println("double(5) = ${double(5)}")
    println("double(10) = ${double(10)}")
    println("isEven(4) = ${isEven(4)}")
    println("isEven(7) = ${isEven(7)}")
}
```

Save and run. Output:

```text
double(5) = 10
double(10) = 20
isEven(4) = true
isEven(7) = false
```

The variable `double` has type `(Int) -> Int`, which reads as "a function from Int to Int". The variable holds a lambda that doubles its input. To call the function stored in the variable, we use parentheses: `double(5)`. This is the same syntax as calling a regular function, because at the call site there is no difference between a function declared with `fun` and a function stored in a variable.

The type `(Int) -> Int` is the function type. The parameter types go in parentheses (with multiple parameters separated by commas), then `->`, then the return type. Some examples:

- `() -> Unit` is a function with no parameters that returns nothing useful.
- `(String) -> Int` is a function from `String` to `Int`.
- `(Int, Int) -> Int` is a function from two `Int`s to one `Int`.
- `(String) -> Boolean` is a predicate on strings.

These types appear in function signatures whenever you accept a function as a parameter, which is the heart of higher-order programming.

### Step 2: Pass a Function as an Argument

Now we write our own higher-order function that takes another function as a parameter:

```kotlin
fun applyTwice(value: Int, operation: (Int) -> Int): Int {
    return operation(operation(value))
}

fun main() {
    val result1 = applyTwice(5) { it * 2 }       // double twice: 20
    val result2 = applyTwice(10) { it + 1 }      // increment twice: 12
    val result3 = applyTwice(3) { it * it }      // square twice: 81
    
    println("5 doubled twice: $result1")
    println("10 incremented twice: $result2")
    println("3 squared twice: $result3")
}
```

Save and run. Output:

```text
5 doubled twice: 20
10 incremented twice: 12
3 squared twice: 81
```

The function `applyTwice(value: Int, operation: (Int) -> Int): Int` takes an integer and a function, applies the function twice (once to `value`, then again to that result), and returns the final result. The function parameter `operation` has type `(Int) -> Int`, which means we can call it with `operation(value)` inside the body.

At each call site, we pass a different lambda as the operation. The trailing-lambda syntax means the lambda goes outside the parentheses, after the integer. The result is dramatically different behavior from the same function depending on which lambda we pass: doubling, incrementing, squaring, or any other Int-to-Int operation.

This is the heart of higher-order programming. Instead of writing three different functions for "double twice", "increment twice", and "square twice", you write one general function that takes the operation as a parameter. The caller decides what specific operation to perform. This kind of code reuse through function parameters is one of the main reasons higher-order functions matter.

### Step 3: Return a Function

Functions can also return functions:

```kotlin
fun multiplier(factor: Int): (Int) -> Int {
    return { x -> x * factor }
}

fun main() {
    val triple = multiplier(3)
    val tenfold = multiplier(10)
    
    println("triple(5) = ${triple(5)}")
    println("tenfold(7) = ${tenfold(7)}")
}
```

Save and run. Output:

```text
triple(5) = 15
tenfold(7) = 70
```

The function `multiplier(factor: Int): (Int) -> Int` takes a factor and returns a function. The returned function is a lambda that uses `factor` (which was a parameter to `multiplier`). This is called a "closure" because the lambda "closes over" the surrounding scope, capturing the value of `factor` at the time it was created.

`triple` is `multiplier(3)`, a function that multiplies its input by 3. `tenfold` is `multiplier(10)`, a function that multiplies by 10. Each is a new function object that remembers its specific factor. Calling them produces the appropriate result.

Closures are powerful because they let you create specialized functions on the fly. This is rarely needed in everyday application code but is the foundation that enables many of the standard library patterns. We will not use closures heavily in Catatku, but recognizing them when you see them is useful.

---

## 4. The Standard Library Collection Functions

The Kotlin standard library has dozens of functions that take lambdas to operate on collections. We saw a few in Lesson 8; this section covers the most important ones in detail and gives you the vocabulary that idiomatic Kotlin uses constantly.

### Step 1: filter

`filter` keeps elements where the lambda returns true:

```kotlin
fun main() {
    val numbers = listOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    
    val evens = numbers.filter { it % 2 == 0 }
    val biggerThanFive = numbers.filter { it > 5 }
    val oddsBiggerThanThree = numbers.filter { it > 3 && it % 2 != 0 }
    
    println("Evens: $evens")
    println("Bigger than 5: $biggerThanFive")
    println("Odd and bigger than 3: $oddsBiggerThanThree")
}
```

Save and run. Output:

```text
Evens: [2, 4, 6, 8, 10]
Bigger than 5: [6, 7, 8, 9, 10]
Odd and bigger than 3: [5, 7, 9]
```

Each `filter` call produces a new list containing only elements where the predicate (the lambda) returns true. The original list is unchanged. The lambda's parameter is the current element being checked; the return value tells whether to keep it.

Filters compose cleanly: you can chain `filter` with other operations like `map` or `count` to express richer queries. Most data-processing logic eventually involves a filter step.

### Step 2: map

`map` transforms each element using the lambda and returns a list of the transformed values:

```kotlin
fun main() {
    val tasks = listOf("Pay rent", "Buy groceries", "Call dentist")
    
    val lengths = tasks.map { it.length }
    val upper = tasks.map { it.uppercase() }
    val numbered = tasks.mapIndexed { i, task -> "${i + 1}. $task" }
    
    println("Lengths: $lengths")
    println("Upper: $upper")
    println("Numbered: $numbered")
}
```

Save and run. Output:

```text
Lengths: [8, 13, 12]
Upper: [PAY RENT, BUY GROCERIES, CALL DENTIST]
Numbered: [1. Pay rent, 2. Buy groceries, 3. Call dentist]
```

`map` produces a list of the same length as the original, with each element transformed. The lambda parameter is the current element; the return value is what the new list will contain at that position. The transformation can change the type: `tasks` is `List<String>` but `lengths` is `List<Int>` because the lambda returns an Int.

`mapIndexed` is a useful variant that gives the lambda both the index and the element. When you need positional information, this is cleaner than calling `withIndex()` first and using destructuring.

`map` is probably the most-used collection function. Anywhere you have a list of one thing and want a list of derived things, reach for `map`.

### Step 3: forEach

`forEach` runs a lambda on each element for its side effects, returning nothing useful:

```kotlin
fun main() {
    val tasks = listOf("Pay rent", "Buy groceries", "Call dentist")
    
    tasks.forEach { println("- $it") }
    
    println()
    
    tasks.forEachIndexed { i, task -> println("${i + 1}. $task") }
}
```

Save and run. Output:

```text
- Pay rent
- Buy groceries
- Call dentist

1. Pay rent
2. Buy groceries
3. Call dentist
```

`forEach` is the iterator-style replacement for `for` loops. The semantics are identical, but the syntax is different. Whether to use `forEach` or `for (item in list)` is a style preference; both are common and idiomatic. As a habit, prefer `for` when the body is multiple statements (more readable), and prefer `forEach` when the body is a single short operation that fits naturally in a lambda.

Unlike `filter` and `map`, `forEach` does not return a useful value. It is for side effects (printing, modifying external state, calling other functions for their effects). Inside a `forEach` lambda, you cannot use `break` or `continue` directly; you would have to use a regular `for` loop for those.

### Step 4: fold and reduce

`fold` and `reduce` combine all elements into a single value, using a lambda that takes the accumulator and the next element:

```kotlin
fun main() {
    val numbers = listOf(1, 2, 3, 4, 5)
    
    val sum = numbers.fold(0) { acc, n -> acc + n }
    val product = numbers.fold(1) { acc, n -> acc * n }
    val sumWithReduce = numbers.reduce { acc, n -> acc + n }
    
    println("Sum: $sum")
    println("Product: $product")
    println("Sum (reduce): $sumWithReduce")
    
    // fold also works for non-numeric reductions
    val joined = numbers.fold("") { acc, n -> "$acc$n," }
    println("Joined: $joined")
}
```

Save and run. Output:

```text
Sum: 15
Product: 120
Sum (reduce): 15
Joined: 1,2,3,4,5,
```

`fold(initial) { acc, x -> ... }` starts with the initial value and applies the lambda to each element in turn, with the accumulator carrying the running result. For `sum`, we start at 0 and add each number. For `product`, we start at 1 and multiply.

`reduce` is similar but uses the first element as the initial accumulator instead of taking one explicitly. This is convenient when summing or multiplying numbers (where the operation has a natural identity), but `fold` is more general because the initial value can be any type and is explicit. As a habit, prefer `fold` because it makes the start value visible and works on empty lists (where `reduce` would throw).

The `joined` example shows that `fold` is not just for numbers: the accumulator can be any type, and the lambda can do any kind of combination. For string-joining specifically, `joinToString` is usually clearer, but `fold` is the general tool for "combine everything into one value".

### Step 5: count, any, all, none

These four predicates return integers or booleans about how many elements match a condition:

```kotlin
fun main() {
    val numbers = listOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    
    println("Total: ${numbers.size}")
    println("Even count: ${numbers.count { it % 2 == 0 }}")
    println("Any > 7: ${numbers.any { it > 7 }}")
    println("All > 0: ${numbers.all { it > 0 }}")
    println("None > 100: ${numbers.none { it > 100 }}")
}
```

Save and run. Output:

```text
Total: 10
Even count: 5
Any > 7: true
All > 0: true
None > 100: true
```

Each function answers a specific question. `count(predicate)` returns the number of matching elements. `any(predicate)` returns true if at least one matches. `all(predicate)` returns true if every element matches. `none(predicate)` returns true if none matches.

These are short and readable replacements for hand-written loops with counters and flags. The intent is clearer, and the chance of an off-by-one or an early-exit bug is lower because the standard library handles the iteration.

### Step 6: sumOf and averageBy

For numeric aggregations, `sumOf` and related functions are dedicated:

```kotlin
fun main() {
    val tasks = listOf("Pay rent", "Buy groceries", "Call dentist")
    
    val totalChars = tasks.sumOf { it.length }
    val maxLength = tasks.maxOf { it.length }
    val minLength = tasks.minOf { it.length }
    
    println("Total chars: $totalChars")
    println("Max length: $maxLength")
    println("Min length: $minLength")
}
```

Save and run. Output:

```text
Total chars: 33
Max length: 13
Min length: 8
```

`sumOf { lambda }` applies the lambda to each element and sums the results. This is more direct than `map { ... }.sum()` because there is no intermediate list. `maxOf` and `minOf` find the largest and smallest values produced by the lambda.

There is also `maxByOrNull` and `minByOrNull`, which return the element (not the value) that maximizes or minimizes the lambda's result. Use `maxOf`/`minOf` when you want the value; use `maxByOrNull`/`minByOrNull` when you want the element.

---

## 5. Chaining Operations

The real power of higher-order functions comes from chaining them together. Each operation produces a new collection, which the next operation processes. The chain reads like a description of what you want, not how to compute it.

### Step 1: A Multi-Step Chain

```kotlin
data class Entry(val id: Int, val description: String, val priority: Int)

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", 1),
        Entry(2, "Read for fun", 3),
        Entry(3, "Finish Kotlin course", 1),
        Entry(4, "Call dentist", 2),
        Entry(5, "Walk the dog", 2),
        Entry(6, "Buy groceries", 1)
    )
    
    // Get descriptions of high-priority entries (priority 1), uppercased, comma-separated
    val highPrioritySummary = entries
        .filter { it.priority == 1 }
        .map { it.description.uppercase() }
        .joinToString(", ")
    
    println("High priority: $highPrioritySummary")
    
    // Total characters in descriptions of all entries except priority 3
    val totalChars = entries
        .filter { it.priority != 3 }
        .sumOf { it.description.length }
    
    println("Total chars (not priority 3): $totalChars")
    
    // Average priority across all entries
    val avgPriority = entries.map { it.priority }.average()
    println("Average priority: ${"%.2f".format(avgPriority)}")
}
```

Save and run. Output:

```text
High priority: PAY RENT, FINISH KOTLIN COURSE, BUY GROCERIES
Total chars (not priority 3): 65
Average priority: 1.67
```

Each chain reads as a sentence: "from the entries, keep the ones with priority 1, transform each to its uppercase description, and join with commas". The Kotlin code mirrors that description directly. There are no manual loops, no mutable accumulators, no off-by-one risks. The standard library handles the iteration, and the lambdas express the operations.

This style is sometimes called "fluent" or "pipelined" or "expression-oriented". It is the same idea as Java 8 streams or LINQ in C#: a chain of small operations that compose into a larger transformation. The Kotlin version is more concise than the Java equivalent because of trailing lambdas and `it`, and it uses lazy evaluation in some cases (we will not cover laziness in this lesson but it is worth knowing about for performance).

### Step 2: Combining filter, map, and Aggregation

The pattern "filter to interesting elements, transform them, aggregate the result" is genuinely common:

```kotlin
data class Entry(val id: Int, val description: String, val priority: Int, val done: Boolean)

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", 1, false),
        Entry(2, "Read for fun", 3, true),
        Entry(3, "Finish Kotlin course", 1, false),
        Entry(4, "Call dentist", 2, true),
        Entry(5, "Walk the dog", 2, false)
    )
    
    val pendingHigh = entries.count { !it.done && it.priority == 1 }
    val doneCount = entries.count { it.done }
    val totalPendingChars = entries.filter { !it.done }.sumOf { it.description.length }
    val anyHighPending = entries.any { it.priority == 1 && !it.done }
    val allDone = entries.all { it.done }
    
    println("Pending high-priority: $pendingHigh")
    println("Done count: $doneCount")
    println("Pending chars: $totalPendingChars")
    println("Any high-priority pending: $anyHighPending")
    println("All done: $allDone")
}
```

Save and run. Output:

```text
Pending high-priority: 2
Done count: 2
Pending chars: 40
Any high-priority pending: true
All done: false
```

Each line answers a specific question about the entries. The chain reads like a query in a query language: "count entries where not done and priority is 1", "any entries where priority is 1 and not done". With the standard library, expressing these queries is just a matter of picking the right function and writing the predicate.

This kind of expressive querying is one of the things that makes Kotlin pleasant for data-heavy code. Every common query has a one-or-two-line expression. Hand-writing equivalent loops would take five to ten lines per query and would be more error-prone.

### Step 3: groupBy

A particularly useful function is `groupBy`, which produces a map from key to list of elements:

```kotlin
data class Entry(val id: Int, val description: String, val priority: Int)

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", 1),
        Entry(2, "Read for fun", 3),
        Entry(3, "Finish Kotlin course", 1),
        Entry(4, "Call dentist", 2),
        Entry(5, "Walk the dog", 2)
    )
    
    val byPriority = entries.groupBy { it.priority }
    
    for ((priority, entries) in byPriority) {
        println("Priority $priority:")
        for (e in entries) {
            println("  ${e.id}. ${e.description}")
        }
    }
}
```

Save and run. Output:

```text
Priority 1:
  1. Pay rent
  3. Finish Kotlin course
Priority 3:
  2. Read for fun
Priority 2:
  4. Call dentist
  5. Walk the dog
```

`groupBy { lambda }` returns a `Map<Key, List<T>>`, where the key is whatever the lambda returns and the value is the list of elements that produce that key. Here we group by priority, getting one list of entries per priority level.

`groupBy` is the iterator-style equivalent of writing a `for` loop with a manually-built map. It expresses the intent clearly and handles the bookkeeping. There is also `groupingBy` for the case where you want to apply additional reductions per group, but for most cases `groupBy` followed by another transformation is sufficient.

---

## 6. Run and Test

Combine everything into a comprehensive Catatku-flavored example.

### Step 1: A Catatku Summary Generator

Replace `Main.kt` with this:

```kotlin
enum class Priority { HIGH, MEDIUM, LOW }

sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object Done : Status() { override fun toString() = "Done" }
    data class Cancelled(val reason: String) : Status()
}

data class Entry(
    val id: Int,
    val description: String,
    val priority: Priority,
    val status: Status
)

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", Priority.HIGH, Status.Pending),
        Entry(2, "Read for fun", Priority.LOW, Status.Done),
        Entry(3, "Finish Kotlin course", Priority.HIGH, Status.Pending),
        Entry(4, "Call dentist", Priority.MEDIUM, Status.Cancelled("rescheduled")),
        Entry(5, "Walk the dog", Priority.MEDIUM, Status.Done),
        Entry(6, "Buy groceries", Priority.HIGH, Status.Done),
        Entry(7, "Plan vacation", Priority.LOW, Status.Pending)
    )
    
    println("=== Catatku Summary ===")
    println("Total entries: ${entries.size}")
    
    val pendingCount = entries.count { it.status is Status.Pending }
    val doneCount = entries.count { it.status is Status.Done }
    val cancelledCount = entries.count { it.status is Status.Cancelled }
    println("Pending: $pendingCount, Done: $doneCount, Cancelled: $cancelledCount")
    
    println("\n=== High-Priority Pending ===")
    entries
        .filter { it.priority == Priority.HIGH && it.status is Status.Pending }
        .forEach { println("  #${it.id}: ${it.description}") }
    
    println("\n=== Cancelled with Reasons ===")
    entries
        .filter { it.status is Status.Cancelled }
        .forEach { e ->
            val cancelled = e.status as Status.Cancelled
            println("  #${e.id}: ${e.description} (reason: ${cancelled.reason})")
        }
    
    println("\n=== Average Description Length ===")
    val avgLength = entries.map { it.description.length }.average()
    println("  ${"%.1f".format(avgLength)} characters")
    
    println("\n=== Entries Grouped by Priority ===")
    val byPriority = entries.groupBy { it.priority }
    for (priority in Priority.values()) {
        val group = byPriority[priority] ?: emptyList()
        println("$priority (${group.size} entries):")
        group.forEach { println("  #${it.id}: ${it.description}") }
    }
    
    println("\n=== All Pending Entries Have High or Medium Priority? ===")
    val allActiveAreImportant = entries
        .filter { it.status is Status.Pending }
        .all { it.priority != Priority.LOW }
    println("  $allActiveAreImportant")
}
```

Save and run.

### Step 2: Read the Output

Output:

```text
=== Catatku Summary ===
Total entries: 7
Pending: 3, Done: 3, Cancelled: 1

=== High-Priority Pending ===
  #1: Pay rent
  #3: Finish Kotlin course

=== Cancelled with Reasons ===
  #4: Call dentist (reason: rescheduled)

=== Average Description Length ===
  12.9 characters

=== Entries Grouped by Priority ===
HIGH (3 entries):
  #1: Pay rent
  #3: Finish Kotlin course
  #6: Buy groceries
MEDIUM (2 entries):
  #4: Call dentist
  #5: Walk the dog
LOW (2 entries):
  #2: Read for fun
  #7: Plan vacation

=== All Pending Entries Have High or Medium Priority? ===
  false
```

Walk through what each piece contributed. The first summary uses `count` with a lambda for each status type. The high-priority-pending section uses `filter` then `forEach`. The cancelled section uses `filter`, then `forEach` with smart cast inside the lambda body. The average uses `map` to extract lengths and then `average()`. The grouping uses `groupBy` to partition entries by priority, then iterates to display each group. The final question uses `filter` followed by `all` to check a property of a subset.

Every section is a chain of two or three operations from the standard library. Hand-writing the equivalent code with explicit loops and accumulators would be many times longer and considerably less readable. This is the everyday style of idiomatic Kotlin, and once you have used these functions for a few weeks, they become second nature.

### Step 3: Modify and Re-Run

Try a few experiments. Add more entries. Filter by description content (`filter { it.description.contains("rent") }`). Compute the longest description (`maxByOrNull { it.description.length }?.description`). Each variation builds your fluency with the standard library.

The key insight is to think of collection operations as a vocabulary you compose into sentences. Each function does one specific thing well, and chains of them can express any data transformation you need. Once you see this pattern, you stop reaching for hand-written loops in most cases.

---

## 7. Fix the Errors in Your Code

Three lambda and higher-order function mistakes are common. Each one below shows the wrong version first, then the corrected version.

**Error 1: Using a parameter name the lambda never declared**

```kotlin
// Wrong
fun main() {
    val numbers = listOf(1, 2, 3)
    val doubled = numbers.map { x * 2 }
    println(doubled)
}

// Correct
fun main() {
    val numbers = listOf(1, 2, 3)
    val doubled = numbers.map { it * 2 }
    println(doubled)
}
```

The compiler stops at the wrong version with `Unresolved reference 'x'.` Inside a lambda, you must use either an explicit parameter name (declared with `parameter ->`) or the implicit `it` (when there is exactly one parameter). The name `x` was never declared, so the compiler has no idea what it refers to. The fix is to either write `{ x -> x * 2 }` to declare the parameter, or `{ it * 2 }` to use the implicit name. As a habit, when a lambda has one parameter, use `it` for short bodies and a named parameter for longer or less obvious bodies.

**Error 2: Using forEach when you need the result**

```kotlin
// Wrong
fun main() {
    val numbers = listOf(1, 2, 3)
    val doubled = numbers.forEach { it * 2 }
    println(doubled)
}

// Correct
fun main() {
    val numbers = listOf(1, 2, 3)
    val doubled = numbers.map { it * 2 }
    println(doubled)
}
```

This mistake is sneaky because the wrong version compiles and runs. It prints `kotlin.Unit` instead of a list, while the correct version prints `[2, 4, 6]`. `forEach` is for side effects, not for transformations. It returns `Unit` (no useful value), so capturing its result gives you `Unit` back and the doubled values are thrown away. The fix is to use `map` when you want a transformed list. As a habit, `forEach` is for "do something with each element", `map` is for "compute a value for each element". The two are not interchangeable.

**Error 3: Trying to break out of forEach**

```kotlin
// Wrong
fun main() {
    listOf(1, 2, 3, 4, 5).forEach {
        if (it > 3) break
        println(it)
    }
}

// Correct
fun main() {
    for (n in listOf(1, 2, 3, 4, 5)) {
        if (n > 3) break
        println(n)
    }
}
```

The compiler rejects the wrong version with `'break' and 'continue' are only allowed inside loops.` `break` and `continue` work inside loop constructs (`for`, `while`, `do-while`) but not inside lambdas. A `forEach` lambda is just a function, and the loop is happening inside the standard library's implementation of `forEach`, which your `break` cannot reach. The fix is to either use a regular `for` loop (where `break` works, printing `1`, `2`, and `3`), or use `takeWhile` or `firstOrNull` to express the early-exit behavior in iterator style. As a habit, when you find yourself wanting `break` inside `forEach`, that is a signal to either switch to a `for` loop or to use a different iterator function like `firstOrNull` that handles early termination cleanly.

---

## 8. Exercises

These exercises practice lambdas and higher-order functions.

**Exercise 1:** Given a list of integers, write code that finds the sum of the squares of the even numbers. Use `filter`, `map`, and `sum` (or `sumOf`) chained together.

**Exercise 2:** Write a higher-order function `applyN(value: Int, times: Int, operation: (Int) -> Int): Int` that applies the operation to value `times` many times in sequence. Test it with a few different lambdas.

**Exercise 3:** Given a list of `Entry` objects (using the `Entry` data class from this lesson), produce a comma-separated string of descriptions for entries where priority is `Priority.HIGH` and status is `Status.Pending`. Use the iterator chain style.

---

## 9. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

The chain reads exactly like the task: keep the even numbers, square them, then add them up.

```kotlin
fun main() {
    val numbers = listOf(1, 2, 3, 4, 5, 6, 7, 8)

    val sumOfEvenSquares = numbers
        .filter { it % 2 == 0 }
        .map { it * it }
        .sum()

    val sameWithSumOf = numbers
        .filter { it % 2 == 0 }
        .sumOf { it * it }

    println("Sum of squares of evens: $sumOfEvenSquares")
    println("Same result with sumOf: $sameWithSumOf")
}
```

Save and run. Output:

```text
Sum of squares of evens: 120
Same result with sumOf: 120
```

The first chain uses three steps: `filter { it % 2 == 0 }` keeps 2, 4, 6, and 8, `map { it * it }` turns them into 4, 16, 36, and 64, and `sum()` adds them to 120. The second chain merges the last two steps with `sumOf`, which squares and sums in one pass without building the intermediate list of squares. Both are correct; `sumOf` is slightly more efficient and just as readable.

**Solution for Exercise 2:**

This exercise practices defining your own higher-order function and using it with various lambdas.

```kotlin
fun applyN(value: Int, times: Int, operation: (Int) -> Int): Int {
    var result = value
    repeat(times) {
        result = operation(result)
    }
    return result
}

fun main() {
    val tripled = applyN(2, 3) { it * 3 }       // 2 -> 6 -> 18 -> 54
    val incremented = applyN(0, 5) { it + 1 }   // 0 -> 1 -> 2 -> 3 -> 4 -> 5
    val negated = applyN(7, 2) { -it }          // 7 -> -7 -> 7
    
    println("2 tripled 3 times: $tripled")
    println("0 incremented 5 times: $incremented")
    println("7 negated twice: $negated")
}
```

Save and run. Output:

```text
2 tripled 3 times: 54
0 incremented 5 times: 5
7 negated twice: 7
```

The function `applyN(value: Int, times: Int, operation: (Int) -> Int): Int` takes three parameters: the starting value, the number of iterations, and the operation to apply. Inside, we use `repeat(times)` (a standard library function that runs its lambda `times` times) and a `var result` accumulator. Each iteration applies the operation to `result` and stores the new value back. After all iterations, we return `result`.

The function uses three different lambdas at the call sites: tripling, incrementing, and negating. Each one is a different `(Int) -> Int` function, but the same `applyN` function handles all three cases without any modification. This is the essence of higher-order programming: write the iteration once, parameterize it by the operation, and reuse for many specific cases.

A more functional version using `fold` would avoid the explicit `var`:

```kotlin
fun applyN(value: Int, times: Int, operation: (Int) -> Int): Int =
    (1..times).fold(value) { acc, _ -> operation(acc) }

fun main() {
    println("2 tripled 3 times: ${applyN(2, 3) { it * 3 }}")
    println("0 incremented 5 times: ${applyN(0, 5) { it + 1 }}")
    println("7 negated twice: ${applyN(7, 2) { -it }}")
}
```

Save and run. Output:

```text
2 tripled 3 times: 54
0 incremented 5 times: 5
7 negated twice: 7
```

Here `(1..times)` is a range, and `fold(value) { acc, _ -> operation(acc) }` applies `operation` to the accumulator `times` times, ignoring the range value (`_` is the conventional name for "I do not need this parameter"). The return value of `fold` is the final accumulator, which becomes the return value of `applyN`. This is shorter and avoids the mutable variable, which is more in the functional style.

Both versions are correct. The first is more obviously imperative; the second is more functional. Both are idiomatic Kotlin in different ways. Pick whichever fits the surrounding code's style.

**Solution for Exercise 3:**

This solution reuses the `Priority`, `Status`, and `Entry` types from the Run and Test section.

```kotlin
enum class Priority { HIGH, MEDIUM, LOW }

sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object Done : Status() { override fun toString() = "Done" }
    data class Cancelled(val reason: String) : Status()
}

data class Entry(
    val id: Int,
    val description: String,
    val priority: Priority,
    val status: Status
)

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", Priority.HIGH, Status.Pending),
        Entry(2, "Read for fun", Priority.LOW, Status.Done),
        Entry(3, "Finish Kotlin course", Priority.HIGH, Status.Pending),
        Entry(4, "Call dentist", Priority.MEDIUM, Status.Cancelled("rescheduled")),
        Entry(6, "Buy groceries", Priority.HIGH, Status.Done)
    )

    val urgent = entries
        .filter { it.priority == Priority.HIGH && it.status is Status.Pending }
        .joinToString(", ") { it.description }

    println("Urgent: $urgent")
}
```

Save and run. Output:

```text
Urgent: Pay rent, Finish Kotlin course
```

The `filter` keeps only entries that are both high priority and pending, which drops the done "Buy groceries" entry even though it is high priority. Instead of a separate `map` step, `joinToString` takes a lambda as its last argument that turns each entry into the text to join, so `joinToString(", ") { it.description }` is the same as `.map { it.description }.joinToString(", ")` in a single call.

---

## 10. Understanding Why Higher-Order Functions Matter

Higher-order functions and lambdas are the heart of the functional programming style. Understanding why they produce so much value helps you reach for them naturally in your own code.

The deepest reason is that they make code reuse natural for behavioral patterns. When two pieces of code differ only in some small operation (multiply by this versus that, check for this condition versus that, transform this way versus that way), traditional code requires you to either duplicate the surrounding logic for each variant, or to extract the surrounding logic into a function with some kind of dispatch (interface, switch statement, callback). Higher-order functions let you parameterize the surrounding logic by the operation directly: write the loop once, take the per-iteration logic as a function parameter. The result is dramatically more reuse without the ceremony of class-based dispatch.

The standard library's collection functions are all examples of this pattern. `filter` is a "loop that keeps elements where the predicate is true". `map` is a "loop that transforms each element by the function". `fold` is a "loop that combines all elements into one value using the combiner". Each one is a few lines of generic code, parameterized by the lambda, that handles a common iteration pattern. Without higher-order functions, every program would be reimplementing these loops with slight variations.

The second reason is composition. Each higher-order function takes one or more lambdas and produces a result. Often that result is itself a collection, which can be passed to another higher-order function. This is the chaining we have been doing throughout the lesson. The chain is a composition of small operations into a larger one, and the meaning of the composition is the sum of the parts. You do not need to invent new abstractions; the standard library's vocabulary already covers most of what you need.

The third reason is testability and isolation. A function that takes a lambda is intrinsically more testable because you can pass in different lambdas for different test cases. The function's logic is decoupled from the specific operation, which lets you test it in isolation. This is the "dependency injection" pattern from object-oriented programming, but expressed more directly: the dependency is just a function value, not a whole object with state.

The fourth reason is that lambdas turn out to be a clean way to express "delayed computation". A lambda `{ ... }` does not run when you write it; it runs when something calls it. This means you can pass a lambda to a function that decides whether and when to call it. Common uses include logging (the lambda runs only if log level matches), caching (the lambda runs only on cache miss), and lazy initialization (the lambda runs only on first access). Without lambdas, these patterns require auxiliary classes; with lambdas, they are one-line idioms.

The cost of all this is a small mental shift. Code that uses higher-order functions reads differently from code that uses explicit loops: you have to think in terms of operations on collections rather than step-by-step iteration. Beginners sometimes find chained iterator code harder to read at first because each step is hidden behind a function call. With practice, the opposite becomes true: chained iterator code reads like a description of what you want, while the equivalent loop reads like an implementation that you have to mentally execute. The shift takes a few weeks of consistent use, and once it happens, it stays.

A subtler benefit is that higher-order code tends to have fewer bugs related to indexing, off-by-one errors, and accumulator mismanagement. The standard library's functions handle these details correctly; you just provide the per-element logic. Bugs in your loops become bugs in your lambdas, but lambdas are typically shorter and more focused, which makes them easier to get right.

---

## Next Up - Lesson 14

Higher-order functions and lambdas are the heart of Kotlin's functional style. A lambda is an anonymous function written with `{ params -> body }` syntax, with shortcuts like the implicit `it` parameter for single-argument cases and the trailing-lambda syntax for placing lambdas outside parentheses when they are the last argument. Function types like `(Int) -> Int` are first-class types, letting you store functions in variables, pass them as parameters, and return them from other functions. The Kotlin standard library has dozens of collection functions that take lambdas, including `filter`, `map`, `forEach`, `fold`, `reduce`, `count`, `any`, `all`, `none`, `sumOf`, `maxOf`, `minOf`, and `groupBy`. Chaining these functions produces expressive data-processing pipelines that read like descriptions of what you want, replacing hand-written loops in most data manipulation code.

In Lesson 14 you will learn extension functions and properties, which let you add methods to types you do not own. Combined with higher-order functions, extension functions are how Kotlin's standard library feels so cohesive and how you can make your own libraries equally pleasant to use.
