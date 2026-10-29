## 1. Before You Begin

The Kotlin standard library has five small functions that are easy to confuse and worth understanding well: `let`, `run`, `with`, `apply`, and `also`. They are called scope functions because each of them runs a block of code (a lambda) inside the scope of an object, giving you a temporary "scope" where the object is conveniently available. The functions look almost identical at first glance, and beginners often pick one at random and move on. With a little patience, the differences become clear, and each function earns its own use case in idiomatic Kotlin code.

The two questions that distinguish the five functions are: how do you refer to the object inside the lambda (as `this` or as `it`), and what does the function return (the lambda's result or the original object). Each combination of these two answers gives a different scope function, and the right choice depends on what you are trying to express. Once you internalize the matrix, picking the right scope function becomes automatic, and your code reads more clearly because each function carries a specific meaning. By the end of this lesson, you will have a decision tree in your head for "which scope function should I use here", and the small idioms built on these functions will make sense at a glance.

### What You'll Build

A series of small examples that demonstrate each scope function with a clear use case. You will use `let` for null handling and transformation, `run` for grouping operations, `with` for working with an existing object, `apply` for builder-style configuration, and `also` for side effects. By the end you will have a feel for which function fits each situation, and the patterns will appear in your own code naturally going forward.

### What You'll Learn

- ✅ The two questions that distinguish the five scope functions
- ✅ When to use `let` (null handling, transformation, returns lambda result)
- ✅ When to use `run` (grouping, returns lambda result, receiver as `this`)
- ✅ When to use `with` (non-extension form, returns lambda result)
- ✅ When to use `apply` (builder-style configuration, returns receiver)
- ✅ When to use `also` (side effects, returns receiver, receiver as `it`)

### What You'll Need

- The `catatku` Gradle project from previous lessons
- A solid understanding of lambdas from Lesson 13 and extensions from Lesson 14
- About thirty-five minutes
- Patience for the conceptual subtleties; these functions look similar but mean different things

---

## 2. The Two Distinguishing Questions

Before looking at each function individually, it helps to see the matrix that organizes them. The two dimensions are how the receiver is exposed and what the function returns.

### Step 1: The Matrix

Open `Main.kt` and replace its contents with a small example that previews all five functions:

```kotlin
fun main() {
    val name = "Kotlin"
    
    // let: receiver as 'it', returns lambda result
    val letResult = name.let { it.length }
    
    // run: receiver as 'this', returns lambda result
    val runResult = name.run { length }
    
    // with: receiver as 'this', returns lambda result, non-extension form
    val withResult = with(name) { length }
    
    // apply: receiver as 'this', returns receiver
    val applyResult = name.apply { /* would mutate if mutable */ }
    
    // also: receiver as 'it', returns receiver
    val alsoResult = name.also { println("logging: $it") }
    
    println("letResult: $letResult")
    println("runResult: $runResult")
    println("withResult: $withResult")
    println("applyResult: $applyResult")
    println("alsoResult: $alsoResult")
}
```

Save and run. Output:

```text
logging: Kotlin
letResult: 6
runResult: 6
withResult: 6
applyResult: Kotlin
alsoResult: Kotlin
```

Each function ran a small lambda on `name` and produced something. The `let`, `run`, and `with` calls returned the lambda's result (the length, 6). The `apply` and `also` calls returned the receiver itself (the string "Kotlin"). The `let` and `also` lambdas use `it` to refer to the receiver; the `run`, `with`, and `apply` lambdas use `this` (which is implicit, so we just wrote `length` to mean `this.length`).

The matrix is:

```text
                Returns lambda result    Returns receiver
this (implicit)  run, with                apply
it (explicit)    let                      also
```

The choice of function depends on which combination you want. Once you understand the matrix, picking the right function becomes a quick mental check: do I want the lambda's result or the receiver, and do I prefer to write `this` or `it` inside the lambda?

### Why Two Receiver Styles

The choice between `this` (implicit) and `it` (explicit) is mostly about readability in different situations. With `this`, you can call methods and properties without any prefix, which is convenient when you are doing many operations on the same object. With `it`, you have an explicit name for the receiver, which is convenient when the lambda also references other variables or when you want to distinguish the receiver from a possibly-confusing `this` in the surrounding scope.

For short single-operation lambdas, both styles are fine. For longer lambdas or those that nest other lambdas (where `this` would be ambiguous), `it` is usually clearer.

### Why Two Return Styles

The choice between "returns lambda result" and "returns receiver" depends on whether you want to chain further operations on the receiver or use the lambda's result.

If the lambda is producing a derived value (a transformation, a length, a parsed number), you want the lambda's result. Use `let`, `run`, or `with`.

If the lambda is configuring or modifying the receiver (setting properties, calling setup methods), you want the receiver back so you can chain more operations on the same object. Use `apply` or `also`.

These rules of thumb cover most cases, and the next sections show specific idioms for each function.

---

## 3. let: Null Handling and Transformation

`let` runs a lambda with the receiver as `it` and returns the lambda's result. Its most common use is null handling: when chained after a safe-call (`?.let { ... }`), the lambda runs only if the receiver is non-null.

### Step 1: The Null-Handling Idiom

Replace the body of `main` with this:

```kotlin
fun main() {
    val maybeName: String? = "Reader"
    val nullName: String? = null
    
    // The let block runs only if the receiver is non-null
    maybeName?.let { name ->
        println("Got a name: $name (length ${name.length})")
    }
    
    nullName?.let { name ->
        println("This will not print")
    }
    
    println("After")
}
```

Save and run. Output:

```text
Got a name: Reader (length 6)
After
```

The pattern `maybeName?.let { name -> ... }` is a clean way to do work only when the value is non-null. Inside the lambda, `name` (we named the parameter explicitly) is the non-null version of `maybeName`. We could also have used the implicit `it`:

```kotlin
maybeName?.let { println("Got a name: $it (length ${it.length})") }
```

This is the most common use of `let`. We saw it briefly in Lesson 7 with null safety; here it gets a name. The combination of `?.` (safe call) and `let` (run lambda on non-null) makes conditional code that depends on null status much cleaner than nested `if` blocks.

### Step 2: let for Transformation with Capturing

`let` is also useful when you want to transform a value into a different shape, especially when the transformation involves capturing the value into a local name:

```kotlin
fun main() {
    val raw = "  hello world  "
    
    // Without let: trim and then immediately use the result for length
    val length1 = raw.trim().length
    
    // With let: same operation, but lets you name the intermediate value
    val length2 = raw.trim().let { trimmed ->
        println("Trimmed value: '$trimmed'")
        trimmed.length
    }
    
    println("length1: $length1")
    println("length2: $length2")
}
```

Save and run. Output:

```text
Trimmed value: 'hello world'
length1: 11
length2: 11
```

In the second version, we used `let` to capture the trimmed string into a name (`trimmed`), do something with it (print), and return its length. The advantage of `let` over a regular variable assignment is that the intermediate value (`trimmed`) is scoped to the lambda only; it does not leak into the surrounding scope. This is a small but real benefit when you want to keep code blocks self-contained.

For simple cases, `let` is overkill (the first version is shorter). For cases where you want a temporary name and want to do multiple things with the value, `let` is a clean way to introduce a small scope.

### Step 3: let in a Chain

`let` chains naturally with other operations:

```kotlin
fun main() {
    val raw = "  42  "
    
    val parsed = raw
        .trim()
        .toIntOrNull()
        ?.let { it * 2 }
        ?: 0
    
    println("parsed: $parsed")
    
    val invalid = "abc"
        .trim()
        .toIntOrNull()
        ?.let { it * 2 }
        ?: 0
    
    println("invalid: $invalid")
}
```

Save and run. Output:

```text
parsed: 84
invalid: 0
```

The chain reads as "trim the string, parse to int (or null), if non-null double it, otherwise 0". Each step transforms the value, and `let` lets us inject a transformation in the middle of a chain that depends on the value being non-null. The final `?: 0` provides a default for the null case.

This style of chained transformation is common in idiomatic Kotlin and is one reason `let` is so useful: it bridges the gap between safe-call chains and ordinary computation. Without `let`, the "double the value if non-null" step would require breaking the chain into separate statements.

---

## 4. apply: Builder-Style Configuration

`apply` runs a lambda with the receiver as `this` and returns the receiver. Its most common use is configuring an object after construction, especially when the configuration involves setting multiple properties or calling multiple methods.

### Step 1: The Builder Idiom

```kotlin
class Config {
    var host: String = "localhost"
    var port: Int = 80
    var timeout: Int = 30
    var debug: Boolean = false
}

fun main() {
    val config = Config().apply {
        host = "example.com"
        port = 8080
        timeout = 60
        debug = true
    }
    
    println("config: host=${config.host}, port=${config.port}, timeout=${config.timeout}, debug=${config.debug}")
}
```

Save and run. Output:

```text
config: host=example.com, port=8080, timeout=60, debug=true
```

The `apply` block configures the freshly-constructed `Config` object: each line inside sets a property of the receiver (`this.host = ...`, with `this` implicit). After the block, `apply` returns the receiver (`config`), which we capture in `val config`.

This pattern is much cleaner than the alternatives. Without `apply`, you would write:

```kotlin
val config = Config()
config.host = "example.com"
config.port = 8080
config.timeout = 60
config.debug = true
```

This works but introduces the variable `config` mid-construction (you have a reference to a half-configured object), and each line repeats `config.`. With `apply`, the configuration is grouped into a single block, the receiver is implicit (no `config.` prefix), and the result is a fully-configured object captured into the variable in one expression.

### Step 2: apply with Constructors That Cannot Take All Parameters

`apply` is especially useful with classes that have many optional properties or with classes from libraries where you cannot modify the constructor:

```kotlin
import java.util.HashMap

fun main() {
    val taskFlags: Map<Int, Boolean> = HashMap<Int, Boolean>().apply {
        put(1, true)
        put(2, false)
        put(3, true)
        put(4, false)
    }
    
    println("taskFlags: $taskFlags")
}
```

Save and run. Output:

```text
taskFlags: {1=true, 2=false, 3=true, 4=false}
```

We constructed a `HashMap`, then used `apply` to populate it with key-value pairs in one block. The end result is a fully-built map captured in `taskFlags`. Without `apply`, we would have had to introduce a temporary variable, populate it across multiple statements, and then capture it.

For Catatku, we will not use `HashMap` directly (we have `mapOf` and `mutableMapOf`), but the pattern transfers to any class that needs configuration after construction. Many Java libraries that follow the "construct, then configure" pattern become much nicer to use through `apply`.

### Step 3: apply for Configuring Catatku Domain Objects

Suppose we had a builder for entries (we do not, our `Entry` is a data class, but bear with the example):

```kotlin
class EntryBuilder {
    var id: Int = 0
    var description: String = ""
    var priority: String = "Medium"
    
    fun build(): String = "Entry(id=$id, description=$description, priority=$priority)"
}

fun main() {
    val entry = EntryBuilder().apply {
        id = 1
        description = "Pay rent"
        priority = "High"
    }.build()
    
    println(entry)
}
```

Save and run. Output:

```text
Entry(id=1, description=Pay rent, priority=High)
```

The chain `.apply { ... }.build()` shows another typical use: configure with `apply` (which returns the builder), then call `build()` to produce the final object. The chain reads as "construct the builder, set its properties, build the result".

For data classes (which is what Catatku uses), the named-argument constructor is usually clearer than a builder pattern: `Entry(id = 1, description = "Pay rent", priority = Priority.HIGH)`. So `apply` is more useful for non-data classes that follow the builder pattern, especially when integrating with libraries.

---

## 5. also: Side Effects and Logging

`also` runs a lambda with the receiver as `it` and returns the receiver. Its most common use is for side effects that you want to happen alongside an expression: logging, debugging, or triggering external state without breaking a chain.

### Step 1: also for Logging Inside a Chain

```kotlin
fun main() {
    val numbers = listOf(1, 2, 3, 4, 5)
    
    val result = numbers
        .filter { it % 2 == 0 }
        .also { println("After filter: $it") }
        .map { it * 10 }
        .also { println("After map: $it") }
        .sum()
    
    println("Final result: $result")
}
```

Save and run. Output:

```text
After filter: [2, 4]
After map: [20, 40]
Final result: 60
```

Each `also` block prints the current state of the list and returns the same list unchanged, so the chain continues normally. This is a clean way to inspect intermediate values in a long chain without breaking it into separate statements. It is similar to the "tap" or "do" combinators in some functional libraries.

`also` is perfect for this because it returns the receiver, so the chain continues with the same value the `also` was called on. The `it` reference makes the receiver accessible by name without disambiguating from any outer `this`.

### Step 2: also for Validation Side Effects

```kotlin
fun parseAndCheck(s: String): Int {
    return s.toInt().also { 
        check(it > 0) { "value must be positive, got $it" } 
    }
}

fun main() {
    println(parseAndCheck("42"))
    
    // The next line would crash:
    // println(parseAndCheck("-5"))
}
```

Save and run. Output:

```text
42
```

If you uncomment the second call, the program crashes, and the first line of the error report reads `Exception in thread "main" java.lang.IllegalStateException: value must be positive, got -5`.

The `also` block runs after the `toInt()` call, asserts a property of the value, and returns the value unchanged. This is a clean way to inject a precondition check into a chain without changing the result. The `check` function (similar to `require` from Lesson 9) throws if its condition is false.

### Step 3: also for Notifications

Sometimes you want to notify some external system after a computation produces a value:

```kotlin
fun main() {
    val sum = listOf(1, 2, 3, 4, 5)
        .sum()
        .also { 
            println("(notification: sum is $it)")
            // In a real app, this might send to a logger, metrics, event bus, etc.
        }
    
    println("Result: $sum")
}
```

Save and run. Output:

```text
(notification: sum is 15)
Result: 15
```

The `also` block runs after the `sum()` call, performs a side effect (printing in this example, but could be anything), and returns the result unchanged. The variable `sum` ends up bound to 15. This pattern is common when you want to log or measure intermediate values without disrupting the data flow.

---

## 6. run and with: Grouping Operations

`run` and `with` are similar: both run a lambda with the receiver as `this` and return the lambda's result. The difference is syntactic: `run` is an extension method (call as `obj.run { ... }`), while `with` is a top-level function (call as `with(obj) { ... }`).

### Step 1: run for Single-Object Computations

`run` is useful when you want to do a small computation in the context of an object and produce a single result:

```kotlin
data class Point(val x: Int, val y: Int)

fun main() {
    val origin = Point(0, 0)
    
    val distanceFromHome = origin.run {
        val target = Point(3, 4)
        val dx = target.x - x
        val dy = target.y - y
        Math.sqrt((dx * dx + dy * dy).toDouble())
    }
    
    println("distance: $distanceFromHome")
}
```

Save and run. Output:

```text
distance: 5.0
```

Inside the `run` block, we accessed `origin`'s properties as `x` and `y` (without `origin.` prefix because `this` is implicit). We computed a result that combined `origin` with a target point. The lambda's result (the computed distance) becomes the `run` call's result, captured in `distanceFromHome`.

`run` is appropriate when you want to "do a computation in the context of an object". It is especially useful when you have multiple intermediate values to compute that all reference the receiver.

### Step 2: with for the Same Use Case

`with` does the same thing, but the syntax is different:

```kotlin
data class Point(val x: Int, val y: Int)

fun main() {
    val origin = Point(0, 0)
    
    val distanceFromHome = with(origin) {
        val target = Point(3, 4)
        val dx = target.x - x
        val dy = target.y - y
        Math.sqrt((dx * dx + dy * dy).toDouble())
    }
    
    println("distance: $distanceFromHome")
}
```

Save and run. Output:

```text
distance: 5.0
```

The output is the same as the `run` version. The two forms are interchangeable. The choice is mostly stylistic: `run` reads as "do this with the receiver", while `with` reads as "with the receiver, do this". `with` can feel more natural when the receiver expression is long, because the receiver appears at the start of the call. `run` is more natural when you are chaining off another expression, because it fits into the chain syntax.

For Catatku, we will rarely use `run` or `with`. The cases where they are useful (computing a value in the context of one object) are more often handled by extension functions or by simple expression sequences.

### Step 3: run with Null Handling

`run` also works after a safe call, similar to `let` but with `this` instead of `it`:

```kotlin
fun main() {
    val maybeName: String? = "Catatku"
    
    val length = maybeName?.run {
        println("processing $this")
        length
    } ?: 0
    
    println("length: $length")
}
```

Save and run. Output:

```text
processing Catatku
length: 7
```

The `?.run` runs the lambda only if the receiver is non-null, with the receiver as `this`. Inside, we can access string methods and properties directly (`length`). The return is the lambda's result (the length).

The choice between `?.let` and `?.run` is mostly about which receiver style you prefer. `?.let { it.length }` and `?.run { length }` produce the same result; the first uses `it`, the second uses implicit `this`. Most code uses `?.let` because it is the more common and more discoverable pattern, but both are valid.

---

## 7. The Decision Tree

With all five scope functions covered, here is a practical decision tree for picking the right one.

### First Question: What Do You Want to Return?

Ask: do you want the lambda's result or the receiver?

If you want the lambda's result (a transformation or computation): use `let`, `run`, or `with`.

If you want the receiver back (configuration or side effects): use `apply` or `also`.

### Second Question: How Do You Want to Refer to the Receiver?

If returning the lambda's result and you want `this`: use `run` (or `with` if you prefer the call form `with(obj) { ... }`).

If returning the lambda's result and you want `it`: use `let`.

If returning the receiver and you want `this`: use `apply`.

If returning the receiver and you want `it`: use `also`.

### Specific Idioms to Memorize

A few specific patterns are worth committing to memory because they appear constantly:

- `maybeValue?.let { ... }` runs the block only if `maybeValue` is non-null, with the value as `it`. The most common null-handling idiom.
- `obj.apply { ... }` configures `obj` and returns it. The most common builder idiom.
- `obj.also { ... }` runs a side effect on `obj` and returns it. The most common logging-in-chain idiom.

If you remember just these three, you cover 80% of scope-function uses. The other functions are useful but rarer, and you can look them up when you need them.

---

## 8. Run and Test

Combine the scope functions in a single comprehensive example.

### Step 1: A Full Example

Replace `Main.kt` with:

```kotlin
data class Entry(
    val id: Int,
    val description: String,
    val priority: String = "Medium",
    val status: String = "Pending"
)

fun main() {
    println("=== let: null handling ===")
    val maybeName: String? = "Catatku"
    val nullName: String? = null
    maybeName?.let { println("Has name: $it") }
    nullName?.let { println("Will not print") }
    
    println("\n=== let: transformation ===")
    val processed = "  42  "
        .trim()
        .toIntOrNull()
        ?.let { it * 2 }
        ?: 0
    println("processed: $processed")
    
    println("\n=== apply: configuration ===")
    val message = StringBuilder().apply {
        append("Hello, ")
        append("Kotlin!")
        append(" Welcome.")
    }.toString()
    println("message: $message")
    
    println("\n=== also: logging in a chain ===")
    val sum = listOf(1, 2, 3, 4, 5)
        .also { println("starting list: $it") }
        .filter { it > 2 }
        .also { println("after filter: $it") }
        .sum()
    println("sum: $sum")
    
    println("\n=== run: scoped computation ===")
    val entry = Entry(1, "Pay rent", "High")
    val displayLine = entry.run {
        val marker = if (status == "Done") "[x]" else "[ ]"
        val priorityLabel = priority.first()
        "$marker ($priorityLabel) $id. $description"
    }
    println("displayLine: $displayLine")
    
    println("\n=== with: same as run, different syntax ===")
    val withResult = with(entry) {
        "Entry $id has priority $priority"
    }
    println("withResult: $withResult")
    
    println("\n=== Combining scope functions ===")
    val processedEntry = Entry(2, "Read book", "Low")
        .also { println("processing: ${it.description}") }
        .let { it.copy(status = "Done") }
        .also { println("after marking done: $it") }
    println("processedEntry: $processedEntry")
}
```

Save and run.

### Step 2: Read the Output

Output:

```text
=== let: null handling ===
Has name: Catatku

=== let: transformation ===
processed: 84

=== apply: configuration ===
message: Hello, Kotlin! Welcome.

=== also: logging in a chain ===
starting list: [1, 2, 3, 4, 5]
after filter: [3, 4, 5]
sum: 12

=== run: scoped computation ===
displayLine: [ ] (H) 1. Pay rent

=== with: same as run, different syntax ===
withResult: Entry 1 has priority High

=== Combining scope functions ===
processing: Read book
after marking done: Entry(id=2, description=Read book, priority=Low, status=Done)
processedEntry: Entry(id=2, description=Read book, priority=Low, status=Done)
```

Walk through what each piece contributed. The `let` examples show null-conditional execution and chain-based transformation. The `apply` example shows builder-style configuration of a `StringBuilder`. The `also` example shows side-effect logging inside a chain that does not disrupt the data flow. The `run` example shows scoped computation with implicit `this`. The `with` example shows the same thing in non-extension form. The final example combines `also` and `let` to log progress and transform a value.

Each scope function carries a specific intent. Reading code that uses them, you can immediately tell what is happening: `?.let` means null-conditional; `apply` means configuration; `also` means side effect. The vocabulary is precise once you internalize it.

### Step 3: Try Modifications

Try changing some of the scope function calls and see if the code still makes sense. Replace `?.let` with `?.run` and notice the syntax difference. Replace `apply` with `also` and observe the result. Replace `also` with `apply` in the chain example and see how the lambda body changes (because `this` is implicit instead of `it`). Each variation reinforces the matrix in your mind.

---

## 9. Fix the Errors in Your Code

Three scope-function mistakes are common. Each one below shows the wrong version first, then the corrected version.

**Error 1: Using the wrong receiver style**

```kotlin
// Wrong
fun main() {
    val name = "Kotlin"
    val length1 = name.let { this.length }
    val length2 = name.run { it.length }
}

// Correct
fun main() {
    val name = "Kotlin"
    val length1 = name.let { it.length }
    val length2 = name.run { length }
    println("$length1 $length2")
}
```

The compiler rejects the wrong version with three messages: `'this' is not defined in this context.` and `Unresolved reference 'length'.` for the `let` line, and `Unresolved reference 'it'.` for the `run` line. Each scope function has a specific receiver style. `let` and `also` use `it`. `run`, `with`, and `apply` use `this`. The corrected version follows the matrix and prints `6 6`. As a habit, when you write a scope function, look at the function name and recall its receiver style. With practice this becomes automatic.

**Error 2: Expecting apply to return the lambda's value**

```kotlin
// Wrong
fun main() {
    val total = listOf(1, 2, 3).apply { sum() }
    println(total)
}

// Correct
fun main() {
    val total = listOf(1, 2, 3).run { sum() }
    println(total)
}
```

The wrong version compiles and runs, but it prints `[1, 2, 3]` instead of a total. `apply` returns the receiver, not the lambda's result, so the `sum()` inside the block is computed and then thrown away. The corrected version uses `run`, which returns the lambda's result, and prints `6`. As a habit, treat `apply` as "configure and pass through" and `let`/`run`/`with` as "compute a derived value".

**Error 3: Using a scope function where a plain expression is enough**

```kotlin
// Wrong
fun main() {
    val length = "Kotlin".let { it.length }
    println(length)
}

// Correct
fun main() {
    val length = "Kotlin".length
    println(length)
}
```

Both versions print `6`, so this is a readability mistake rather than a compile error. Scope functions are useful when they add clarity, but writing `"Kotlin".let { it.length }` instead of `"Kotlin".length` adds a lambda and an `it` reference for no benefit. The fix is to use scope functions only when they genuinely improve the code. Common signals that they help: handling nullability with `?.let`, configuring an object with `apply`, logging in a chain with `also`. Outside these cases, prefer the simpler form.

---

## 10. Exercises

These exercises practice the scope functions.

**Exercise 1:** Write a function `parsedDouble(s: String?): Double` that parses the string to a `Double` and doubles the result, returning `0.0` if the input is null or unparseable. Use `?.let` and the Elvis operator.

**Exercise 2:** Use `apply` to configure a `MutableList<Int>` with the values 1, 2, 3, 4, 5 in one expression, and capture the result in a `val`. Print the resulting list.

**Exercise 3:** Use `also` to log the size of a list at three points in a chain: before filtering, after filtering, and after mapping. The chain should filter for even numbers, map them to their squares, and sum the result. Print the sum at the end.

---

## 11. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

The whole function is one expression built from safe calls, `let`, and the Elvis operator.

```kotlin
fun parsedDouble(s: String?): Double {
    return s?.toDoubleOrNull()?.let { it * 2 } ?: 0.0
}

fun main() {
    println(parsedDouble("2.5"))
    println(parsedDouble("10"))
    println(parsedDouble("abc"))
    println(parsedDouble(null))
}
```

Save and run. Output:

```text
5.0
20.0
0.0
0.0
```

Read the expression from left to right. `s?.toDoubleOrNull()` produces `null` when `s` is null and also when the text is not a number, such as `"abc"`. The `?.let { it * 2 }` runs only when there is a real number, doubling it. If anything along the way produced `null`, the Elvis operator `?: 0.0` supplies the fallback. Both failure cases (null input and unparseable input) end up at the same `0.0` without a single `if`.

**Solution for Exercise 2:**

`apply` lets you create the list and fill it in one expression.

```kotlin
fun main() {
    val numbers = mutableListOf<Int>().apply {
        add(1)
        add(2)
        add(3)
        add(4)
        add(5)
    }

    println(numbers)
}
```

Save and run. Output:

```text
[1, 2, 3, 4, 5]
```

Inside the `apply` block, `this` is the new empty list, so `add(1)` means `this.add(1)`. Because `apply` returns the receiver, `numbers` ends up holding the filled list rather than the result of the last `add` call (which would have been a `Boolean`). This is the builder idiom from earlier in the lesson applied to a collection.

**Solution for Exercise 3:**

This exercise practices `also` for inserting side effects into a chain without disrupting the data flow.

```kotlin
fun main() {
    val sum = listOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        .also { println("Initial size: ${it.size}") }
        .filter { it % 2 == 0 }
        .also { println("After filter, size: ${it.size}") }
        .map { it * it }
        .also { println("After map, size: ${it.size}") }
        .sum()
    
    println("Sum: $sum")
}
```

Save and run. Output:

```text
Initial size: 10
After filter, size: 5
After map, size: 5
Sum: 220
```

The chain has three `also` calls interleaved with the actual data operations. Each `also` block runs a `println` for its side effect and returns the same list unchanged, so the next operation in the chain sees exactly what it would have seen without the `also`. The value 220 is the sum of `4 + 16 + 36 + 64 + 100`, the squares of the even numbers from 1 to 10.

This pattern is genuinely useful for debugging long chains. When you have a chain of five or six operations and the result does not look right, you can sprinkle `also { println(it) }` between the operations to see what is happening at each step. The chain stays linear and the diagnostics are inline rather than pulled out into separate statements.

A more sophisticated version might use a logger instead of `println`, or might use a debug-only logging library that strips out the calls in production builds. The principle is the same: `also` lets you inject side effects (logging, metrics, debug breakpoints) into a chain without changing the chain's semantics.

A common pitfall is to confuse `also` with `apply`. They are very similar (both return the receiver), but `also` uses `it` while `apply` uses `this`. For the logging case, `also` is usually more readable because `println("size: ${it.size}")` is clearer than `println("size: $size")` (where `size` is implicit `this.size`). But for cases where you do not need to reference the receiver, the two are interchangeable.

---

## 12. Understanding Why Five Functions Exist

It might seem excessive that Kotlin has five almost-identical scope functions instead of just one or two. Understanding why all five exist (and why each one earns its place) makes the matrix click and helps you reach for the right one without thinking.

The deepest reason is that each function expresses a different intent at the call site. When a reader sees `obj.apply { ... }`, they immediately know "this is configuring `obj`". When they see `obj.let { ... }`, they know "this is transforming `obj` into something else". When they see `obj.also { ... }`, they know "this is doing a side effect with `obj`". The function name carries semantic information about what the block is for, even before you read the block's contents. This is one of the small ways Kotlin code can be self-documenting: the choice of scope function tells you the purpose of the block.

A single general "scope function" would lose this distinction. A reader would have to read the block to figure out the intent. With five named functions, the intent is visible in the function call. This is a small but real win for readability, especially in code that uses scope functions heavily.

The two dimensions (receiver style and return) are also genuinely useful in different combinations. The receiver style affects what the lambda body looks like: `this` is shorter for many calls in sequence, while `it` is clearer when there is one specific operation or when the receiver might be shadowed by surrounding `this`. The return choice affects whether the call fits into a chain that continues with the receiver or with a derived value.

Could you achieve everything with just `let` and `apply`? Mostly yes. `run` is `let` with a different receiver style. `also` is `apply` with a different receiver style. `with` is `run` in non-extension form. So if you really wanted to use only `let` and `apply` everywhere, you could. But the result would be code that uses `it` constantly even where `this` would be cleaner, and code that uses `let` for things that are conceptually side effects rather than transformations. The four-and-a-half-function set (treating `run` and `with` as variants) is the minimum that lets each function carry a specific intent.

Beyond intent, the functions enable specific idioms that have become so common in idiomatic Kotlin that they are practically vocabulary. `?.let { ... }` for null handling, `apply { ... }` for builder-style configuration, `also { println(it) }` for inline logging. These idioms appear so often that they have become part of the language's character, not just utilities. Removing any of them would make some code less expressive.

The cost of having five functions is the learning curve. Beginners are often confused about which to use, and pick one at random or use the wrong one and write awkward code. After a few weeks of practice, the matrix becomes clear, and picking the right function becomes automatic. This is a feature of the design: a small upfront cost for a long-term win in readability.

A subtler benefit is that scope functions encourage immutability. `apply` and `also` return the receiver (typically used after construction), making it easy to write fully-configured immutable objects in one expression. `let` lets you transform a value without introducing intermediate variables. Together they support the "build the final value in one expression, no rebinding" style that Kotlin nudges toward. This in turn makes code easier to reason about because each name has a fixed meaning.

The deepest takeaway is that scope functions are about semantics, not just syntax. Each one means something specific, and learning the meanings is worth the effort. Once you have internalized them, you read Kotlin code more quickly because you know what each scope function is doing without having to study the lambda body. And you write Kotlin code more confidently because you know which function expresses your intent.

---

## Next Up - Lesson 16

The five scope functions (`let`, `run`, `with`, `apply`, `also`) are a small but expressive vocabulary for working with objects in Kotlin. The matrix of "receiver style" (`this` vs `it`) and "return type" (lambda result vs receiver) gives each function a specific role. `let` is for null handling and transformation; `apply` is for builder-style configuration; `also` is for side effects in a chain; `run` and `with` are for scoped computation. The most-used patterns are `?.let { ... }` for null handling, `apply { ... }` for configuration, and `also { ... }` for inline side effects. Combined with extension functions, lambdas, and null safety, scope functions enable the small idioms that make idiomatic Kotlin feel concise and expressive.

In Lesson 16 you will learn error handling: `try`/`catch`/`finally`, the absence of checked exceptions in Kotlin, `try` as an expression, the `runCatching` helper for converting exceptions into a `Result`, and how Catatku will use a custom sealed `CatatkuError` class for expected error cases.
