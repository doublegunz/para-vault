## 1. Before You Begin

Programs go wrong. A user types `done abc` instead of `done 5`, and the integer parse fails. A file does not exist when the program tries to open it. A network call times out. A computation runs into a state that the code did not anticipate. Every nontrivial program has to handle these failures somehow, and how a language does this shapes how robust real programs feel. Kotlin's approach to error handling has two pieces. The familiar one is exceptions, which work like Java's exceptions but with one important simplification: there are no checked exceptions, so you do not have to declare every exception a function might throw or be forced to catch them at every call site. The less familiar one is treating errors as regular values, often using sealed classes or the standard library's `Result` type, which lets you handle failures with the same `when` expressions and exhaustive checks you use for any other domain modeling.

This lesson covers both styles and when each is appropriate. By the end you will know how to use `try`/`catch`/`finally`, how `try` works as an expression that returns a value, how `runCatching` converts exception-throwing code into `Result` values, and how Catatku's own `CatatkuError` sealed class will model expected error cases for the application's command processing in later lessons. The general pattern in modern Kotlin is to use exceptions for genuinely unexpected failures (a bug, a corrupt environment) and to use sealed result types for expected failure modes that are part of normal program operation (user typed a wrong id, file does not exist yet on first run, parse failure on user input).

### What You'll Build

A `CatatkuError` sealed class with five variants: `EntryNotFound(id)`, `InvalidId(s)`, `EmptyDescription`, `IoError(msg)`, and `ParseError(msg)`. You will see how `try`/`catch` handles unexpected exceptions, how `try` as an expression captures a value, and how `runCatching` produces a `Result` that you can pattern-match on. By the end the error handling story for Catatku is clear, and you will use this same vocabulary in Lessons 18 (command-line parsing) and 19 (file I/O).

### What You'll Learn

- ✅ How `try`/`catch`/`finally` blocks work, including `try` as an expression
- ✅ Why Kotlin has no checked exceptions and what that means in practice
- ✅ How to define and throw custom exceptions
- ✅ How `runCatching` produces a `Result<T>` from a block that might throw
- ✅ When to model errors as a sealed class instead of using exceptions

### What You'll Need

- The `catatku` Gradle project from previous lessons
- Sealed classes (Lesson 11), data classes (Lesson 10), and scope functions (Lesson 15)
- About forty minutes
- Patience for thinking about when each style is appropriate

---

## 2. Exceptions and try/catch

Kotlin's exception model is mostly the same as Java's: when something goes wrong, code throws an exception, and surrounding `try`/`catch` blocks can catch it and respond. The differences are syntactic and behavioral, not conceptual.

### Step 1: Catch a Standard Exception

Open `Main.kt` and replace its contents with this experiment that triggers a parse error:

```kotlin
fun main() {
    val input = "abc"
    try {
        val number = input.toInt()
        println("Parsed: $number")
    } catch (e: NumberFormatException) {
        println("Could not parse '$input' as a number: ${e.message}")
    }
    
    println("After the try block")
}
```

Save and run. The output is:

```text
Could not parse 'abc' as a number: For input string: "abc"
After the try block
```

The `try { ... }` block runs the code inside; if any line throws an exception that matches a `catch` clause, control transfers to that clause. The exception object is bound to the parameter (we named it `e`), and we can access its `message` property to see what went wrong. After the catch (or after the try block if no exception occurred), execution continues with the code that follows.

The `NumberFormatException` is a standard JVM exception thrown by `toInt` when the string is not a valid integer. We named it explicitly in the catch clause so we only catch that specific kind of exception; if some other exception type occurred, it would propagate up the call stack instead of being caught here. This is the "be specific about what you catch" discipline that prevents bugs where a catch clause accidentally swallows exceptions you did not mean to handle.

### Step 2: Multiple catch Clauses and finally

A `try` can have multiple `catch` clauses for different exception types, plus an optional `finally` clause that always runs:

```kotlin
fun main() {
    val input = "42"
    
    try {
        val number = input.toInt()
        val result = 100 / number
        println("Result: $result")
    } catch (e: NumberFormatException) {
        println("Parse error: ${e.message}")
    } catch (e: ArithmeticException) {
        println("Arithmetic error: ${e.message}")
    } finally {
        println("Cleanup runs no matter what")
    }
    
    println("After the try block")
}
```

Save and run. Output:

```text
Result: 2
Cleanup runs no matter what
After the try block
```

Each `catch` clause handles a specific exception type. The compiler checks them in order; if the thrown exception matches any clause, that clause runs. The `finally` block runs regardless of whether an exception was thrown, whether it was caught, or whether the `try` completed normally. This is useful for cleanup code: closing files, releasing resources, restoring state. We do not have those concerns in our small example, but the mechanism is there for when we do.

Try changing the input to "0" to trigger the divide-by-zero in the arithmetic. Or change it to "abc" to trigger the parse error. Each input exercises a different branch, and `finally` runs in every case.

### Step 3: Catching the Generic Exception

If you really want to catch any exception (rarely a good idea, but sometimes appropriate for top-level error handlers), use the parent `Exception` class:

```kotlin
fun main() {
    val input = "abc"
    
    try {
        val n = input.toInt()
        println("Got $n")
    } catch (e: Exception) {
        println("Something went wrong: ${e::class.simpleName}: ${e.message}")
    }
}
```

Save and run. Output:

```text
Something went wrong: NumberFormatException: For input string: "abc"
```

The `Exception` class is the parent of most exception types in Java and Kotlin, so catching `Exception` catches almost everything. This is occasionally what you want for robust top-level error handlers, but most of the time being more specific is better because it makes the code's intent clearer.

A subtle but important habit is to never catch `Throwable` or `Error`. These are the very top of the exception hierarchy and include things like `OutOfMemoryError` and `StackOverflowError`, which are usually not recoverable. Catching them silences serious problems that should propagate to the runtime for the JVM to handle. As a habit, catch the most specific exception type that makes sense for your situation, and let the rest propagate.

---

## 3. Throwing Exceptions

To raise an exception yourself, use the `throw` keyword followed by an exception instance.

### Step 1: Throw a Standard Exception

```kotlin
fun divide(numerator: Int, denominator: Int): Int {
    if (denominator == 0) {
        throw IllegalArgumentException("denominator cannot be zero")
    }
    return numerator / denominator
}

fun main() {
    println(divide(10, 2))
    
    try {
        println(divide(10, 0))
    } catch (e: IllegalArgumentException) {
        println("Error: ${e.message}")
    }
}
```

Save and run. Output:

```text
5
Error: denominator cannot be zero
```

The `throw IllegalArgumentException("denominator cannot be zero")` creates an `IllegalArgumentException` and throws it. The exception travels up the call stack until it is caught by a matching `catch` clause, or until it reaches the top of the stack and crashes the program with a stack trace.

The `IllegalArgumentException` is the conventional exception for "the caller passed bad input". `IllegalStateException` is for "the object is in an invalid state for this operation". `RuntimeException` is the parent of both and is the right choice for most user-defined exceptions. The Kotlin standard library uses these consistently, and following the same convention in your own code makes it integrate well with other Kotlin and Java code.

The `require` and `check` functions we saw in Lesson 9 are short for `if (!cond) throw IllegalArgumentException(message)` and `if (!cond) throw IllegalStateException(message)` respectively. They produce the same effect with shorter syntax for common precondition and invariant checks.

### Step 2: Define a Custom Exception

You can define your own exception types by extending an existing exception class:

```kotlin
class TaskNotFoundException(val taskId: Int) : Exception("Task with id $taskId not found")

fun findTask(id: Int): String {
    if (id == 99) {
        throw TaskNotFoundException(id)
    }
    return "Task $id"
}

fun main() {
    try {
        println(findTask(5))
        println(findTask(99))
    } catch (e: TaskNotFoundException) {
        println("Could not find task ${e.taskId}: ${e.message}")
    }
}
```

Save and run. Output:

```text
Task 5
Could not find task 99: Task with id 99 not found
```

The `class TaskNotFoundException(val taskId: Int) : Exception(...)` declares a custom exception that extends `Exception`. The constructor takes the task id as a property, and the `Exception(...)` parent constructor receives a message string. From the catch clause, we can access both the `taskId` property and the inherited `message` property.

Custom exceptions are useful when you want to convey domain-specific information through the exception. Generic exceptions like `IllegalArgumentException` are fine for one-off validation, but for errors that callers might genuinely want to handle differently, named exception types make the catch clauses self-documenting.

### Step 3: throw as an Expression

Like `if` and `when`, `throw` can be used as an expression. This is occasionally useful in chains where you want to raise an exception as part of an Elvis-style fallback:

```kotlin
fun parseRequiredInt(s: String?): Int {
    return s?.toIntOrNull() ?: throw IllegalArgumentException("expected a number, got $s")
}

fun main() {
    println(parseRequiredInt("42"))
    
    try {
        println(parseRequiredInt(null))
    } catch (e: IllegalArgumentException) {
        println("Error: ${e.message}")
    }
}
```

Save and run. Output:

```text
42
Error: expected a number, got null
```

The expression `s?.toIntOrNull() ?: throw IllegalArgumentException(...)` reads as "if `s` is not null and parses to a number, use that; otherwise throw an exception". The `throw` does not return normally, so its "type" is the special type `Nothing`, which fits anywhere. The Elvis operator's right side is allowed to be a `throw`, just as it is allowed to be a `return`.

This pattern is useful when you want a function to fail-fast on missing input rather than returning a nullable result. The caller does not have to handle a null; they get either a real value or an exception.

---

## 4. Why Kotlin Has No Checked Exceptions

A significant difference from Java is that Kotlin does not have checked exceptions. Every Kotlin exception is unchecked, meaning the compiler does not require you to declare or catch them.

### Compare to Java

In Java, methods that might throw certain exceptions must declare them with `throws` clauses, and callers must either catch them or propagate them with their own `throws` clauses. This was Java's attempt to make exception handling explicit. The result, in practice, has been mixed: many programmers either ignore the warnings, swallow exceptions silently, or wrap everything in `RuntimeException` to bypass the requirement.

Kotlin's designers concluded that the costs of checked exceptions outweigh the benefits. The boilerplate of `throws` clauses adds noise, the requirement leaks abstractions (the implementation details of "this method calls the network" become part of the public signature), and most checked exceptions in real code are propagated up to a top-level handler anyway, where you can handle them once for the whole subsystem. So Kotlin makes all exceptions unchecked.

### Step 1: What This Means in Practice

In practice, Kotlin exception handling looks like Java with the `throws` declarations removed:

```kotlin
import java.io.File

fun readFile(path: String): String {
    // No 'throws IOException' declaration needed
    return File(path).readText()
}

fun main() {
    try {
        val content = readFile("/this/file/does/not/exist.txt")
        println(content)
    } catch (e: Exception) {
        println("Error: ${e.message}")
    }
}
```

Save and run. Output:

```text
Error: /this/file/does/not/exist.txt (No such file or directory)
```

The function `readFile` calls `File(...).readText()`, which can throw `IOException` if the file does not exist. In Java, this would require a `throws IOException` declaration. In Kotlin, it does not. The exception still propagates the same way; you still need to handle it somewhere if you want to recover. The difference is that the compiler does not force you to declare or catch it.

The cost of this change is that Kotlin programmers have to be more deliberate about which exceptions can occur. There is no compiler reminder that "this function might throw `IOException`". You have to read the documentation or rely on convention. In practice this is similar to Java's runtime exceptions (which Java also does not check), and Kotlin programmers have learned to be careful about IO and similar operations.

### Step 2: Catching Exceptions from Java Libraries

When you call Java code that throws checked exceptions, you can either catch them or let them propagate. From the Kotlin side, all exceptions look the same; the "checked" distinction does not exist:

```kotlin
import java.io.File

fun main() {
    File("notes.txt").writeText("Hello from Catatku")

    val files = listOf("notes.txt", "/nonexistent/file.txt")
    
    for (path in files) {
        try {
            val content = File(path).readText()
            println("$path: ${content.length} chars")
        } catch (e: Exception) {
            println("$path: error: ${e.message}")
        }
    }
}
```

Save and run. Output:

```text
notes.txt: 18 chars
/nonexistent/file.txt: error: /nonexistent/file.txt (No such file or directory)
```

The program first writes a small `notes.txt` file into the project folder (where `./gradlew run` and IntelliJ start the program), so the first read is guaranteed to succeed. The second path does not exist, so `readText()` throws, and the `catch` block reports it. The `try`/`catch` works the same way for any kind of exception, whether the underlying Java code declared it as checked or not. You can delete `notes.txt` afterward; nothing else uses it.

---

## 5. try as an Expression

In Kotlin, `try` blocks are expressions. The whole `try`/`catch` evaluates to a value, just like `if` and `when` do.

### Step 1: Capture a Result from try

Replace the body of `main` with this:

```kotlin
fun main() {
    val input = "42"
    
    val number: Int = try {
        input.toInt()
    } catch (e: NumberFormatException) {
        -1
    }
    
    println("number: $number")
    
    val invalid: Int = try {
        "abc".toInt()
    } catch (e: NumberFormatException) {
        -1
    }
    
    println("invalid: $invalid")
}
```

Save and run. Output:

```text
number: 42
invalid: -1
```

The whole `try { ... } catch (e: ...) { ... }` is an expression. If the `try` block completes without exception, the expression's value is the value of the last expression in the `try` block. If an exception is caught, the value is the value of the matching `catch` block. Both branches must produce values of compatible types (here both are `Int`).

This style is sometimes cleaner than using a `var` to capture the result across branches:

```kotlin
// Statement style with var
var number: Int
try {
    number = input.toInt()
} catch (e: NumberFormatException) {
    number = -1
}

// Expression style with val
val number = try {
    input.toInt()
} catch (e: NumberFormatException) {
    -1
}
```

The expression form lets us use `val` (immutability), keeps the result close to its production, and looks more like a description of "what we want" than a sequence of state mutations. As a habit, prefer the expression form for `try` whenever you are computing a value that depends on whether an exception occurs.

### Step 2: try with a Default for Safe Parsing

A common pattern is "try this, but use a default if it fails":

```kotlin
fun parseOrDefault(s: String, default: Int): Int = try {
    s.toInt()
} catch (e: NumberFormatException) {
    default
}

fun main() {
    println(parseOrDefault("42", 0))
    println(parseOrDefault("not a number", -1))
    println(parseOrDefault("", 999))
}
```

Save and run. Output:

```text
42
-1
999
```

The function uses single-expression syntax (Lesson 6) where the entire body is one `try` expression. For each input, we either get the parsed value or the default if parsing fails.

In practice, the standard library already provides `toIntOrNull` and similar functions that return null instead of throwing, so this specific case rarely needs `try`. But the pattern is there for any operation that might throw, especially when interfacing with code (often Java) that does not have the `OrNull` variant.

### Step 3: Re-Throw to Propagate

If you want to catch an exception, do something with it, and then re-throw, the `throw` keyword works inside `catch`:

```kotlin
fun parseAndLog(s: String): Int {
    return try {
        s.toInt()
    } catch (e: NumberFormatException) {
        println("(logging: failed to parse '$s')")
        throw e
    }
}

fun main() {
    println(parseAndLog("42"))
    
    try {
        parseAndLog("bad")
    } catch (e: NumberFormatException) {
        println("Outer caught: ${e.message}")
    }
}
```

Save and run. Output:

```text
42
(logging: failed to parse 'bad')
Outer caught: For input string: "bad"
```

The inner catch logs the error and re-throws the same exception. The exception then propagates up to the outer `try` in `main`, where it is caught and reported. This pattern is useful when you want to add logging or metrics around exceptions without actually handling them.

---

## 6. Result and runCatching

The Kotlin standard library has a `Result<T>` type that represents "either a successful value of type T or a failure with some exception". The `runCatching` function wraps a block in this type, converting any exception into a failure result. This is a step toward the expressed-as-values style of error handling.

### Step 1: Use runCatching

```kotlin
fun main() {
    val success: Result<Int> = runCatching { "42".toInt() }
    val failure: Result<Int> = runCatching { "bad".toInt() }
    
    println("success: $success")
    println("failure: $failure")
    
    println("\nUsing fold to handle both cases:")
    val msg1 = success.fold(
        onSuccess = { value -> "got $value" },
        onFailure = { error -> "error: ${error.message}" }
    )
    val msg2 = failure.fold(
        onSuccess = { value -> "got $value" },
        onFailure = { error -> "error: ${error.message}" }
    )
    println(msg1)
    println(msg2)
}
```

Save and run. Output:

```text
success: Success(42)
failure: Failure(java.lang.NumberFormatException: For input string: "bad")

Using fold to handle both cases:
got 42
error: For input string: "bad"
```

The `runCatching { ... }` runs the block. If it completes normally, the result is `Result.success(value)`. If it throws, the result is `Result.failure(exception)`. The `Result<T>` type wraps both possibilities into a value you can inspect, transform, and pass around without throwing.

The `fold` method on `Result` takes two lambdas: one for the success case and one for the failure case. It returns the value of whichever lambda matched. There are also methods like `getOrNull()` (returns the value or null), `getOrDefault(default)` (returns the value or a default), `getOrElse { e -> ... }` (returns the value or the result of the lambda), and `map`/`mapCatching` for transformations.

### Step 2: Compare to try/catch

The same logic with `try`/`catch`:

```kotlin
fun main() {
    val msg1 = try {
        val value = "42".toInt()
        "got $value"
    } catch (e: Exception) {
        "error: ${e.message}"
    }
    
    val msg2 = try {
        val value = "bad".toInt()
        "got $value"
    } catch (e: Exception) {
        "error: ${e.message}"
    }
    
    println(msg1)
    println(msg2)
}
```

Save and run. Output:

```text
got 42
error: For input string: "bad"
```

Both versions produce the same output. The `try`/`catch` form is more explicit about the control flow; the `runCatching` form treats the result as a value that can be passed around. Each style has its place. As a habit, use `try`/`catch` for one-off error handling close to where it occurs, and use `runCatching` when you want to pass the result (success or failure) through several layers of code or store it for later inspection.

### Step 3: Map and Transform with Result

The `Result` type has methods for transforming the wrapped value or the error:

```kotlin
fun main() {
    val parsed: Result<Int> = runCatching { "42".toInt() }
    
    // map: transform the success value, leave failure unchanged
    val doubled: Result<Int> = parsed.map { it * 2 }
    println("doubled: ${doubled.getOrNull()}")
    
    // recover: provide a value for the failure case
    val recovered: Result<Int> = runCatching { "bad".toInt() }.recover { -1 }
    println("recovered: ${recovered.getOrNull()}")
    
    // getOrElse: extract the value or compute one from the error
    val value: Int = runCatching { "bad".toInt() }.getOrElse { e ->
        println("got error ${e.message}, returning fallback")
        -1
    }
    println("value: $value")
}
```

Save and run. Output:

```text
doubled: 84
recovered: -1
got error For input string: "bad", returning fallback
value: -1
```

The `map`, `recover`, and `getOrElse` methods are convenient ways to work with `Result` without unwrapping it explicitly. They are similar in spirit to the methods on collections (`map`, `filter`) but operate on a single optional-like value.

For Catatku we will not use `Result` directly because we want a custom domain error type. But knowing `Result` and `runCatching` are there is useful for cases where you want to capture exceptions as values without inventing your own type.

---

## 7. Sealed Class for Domain Errors

For expected error cases that are part of normal program operation, a sealed class is often a better choice than exceptions. The benefits are exhaustive `when` matching (Lesson 11), explicit error handling at every level, and no exception overhead.

### Step 1: Define the CatatkuError Hierarchy

Replace `Main.kt` with this:

```kotlin
sealed class CatatkuError {
    data class EntryNotFound(val id: Int) : CatatkuError()
    data class InvalidId(val text: String) : CatatkuError()
    object EmptyDescription : CatatkuError()
    data class IoError(val message: String) : CatatkuError()
    data class ParseError(val message: String) : CatatkuError()
}

fun describe(error: CatatkuError): String = when (error) {
    is CatatkuError.EntryNotFound -> "Entry with id ${error.id} not found"
    is CatatkuError.InvalidId -> "Invalid id: '${error.text}' is not a valid integer"
    is CatatkuError.EmptyDescription -> "Description cannot be empty"
    is CatatkuError.IoError -> "I/O error: ${error.message}"
    is CatatkuError.ParseError -> "Parse error: ${error.message}"
}

fun main() {
    val errors = listOf(
        CatatkuError.EntryNotFound(99),
        CatatkuError.InvalidId("abc"),
        CatatkuError.EmptyDescription,
        CatatkuError.IoError("Permission denied"),
        CatatkuError.ParseError("Unexpected '}' at line 3")
    )
    
    for (e in errors) {
        println(describe(e))
    }
}
```

Save and run. Output:

```text
Entry with id 99 not found
Invalid id: 'abc' is not a valid integer
Description cannot be empty
I/O error: Permission denied
Parse error: Unexpected '}' at line 3
```

The `CatatkuError` sealed class has five variants. `EntryNotFound`, `InvalidId`, `IoError`, and `ParseError` are data classes carrying error-specific information. `EmptyDescription` is an object because no extra information is needed (it is always "the description was empty").

The `describe` function is exhaustive: every variant has a branch, and the compiler checks this at compile time. If we add a new error variant later, the compiler will point at this function and require us to handle the new case.

### Step 2: Return Result-Like Types

Now we use the error type in a function that returns either a value or an error. We can use a generic `Result`-style sealed class for this, or we can use Kotlin's standard `Result` with a custom exception type. For clarity, let us define our own:

```kotlin
sealed class CatatkuError {
    data class EntryNotFound(val id: Int) : CatatkuError()
    data class InvalidId(val text: String) : CatatkuError()
    object EmptyDescription : CatatkuError() { override fun toString() = "EmptyDescription" }
}

sealed class CatatkuResult<out T> {
    data class Ok<T>(val value: T) : CatatkuResult<T>()
    data class Err(val error: CatatkuError) : CatatkuResult<Nothing>()
}

fun parseId(text: String): CatatkuResult<Int> {
    val n = text.toIntOrNull()
    return if (n != null) {
        CatatkuResult.Ok(n)
    } else {
        CatatkuResult.Err(CatatkuError.InvalidId(text))
    }
}

fun validateDescription(s: String): CatatkuResult<String> {
    return if (s.isBlank()) {
        CatatkuResult.Err(CatatkuError.EmptyDescription)
    } else {
        CatatkuResult.Ok(s.trim())
    }
}

fun main() {
    val ids = listOf("42", "abc", "100")
    for (id in ids) {
        when (val result = parseId(id)) {
            is CatatkuResult.Ok -> println("'$id' -> ${result.value}")
            is CatatkuResult.Err -> println("'$id' -> error: ${result.error}")
        }
    }
    
    val descs = listOf("Pay rent", "  ", "")
    for (d in descs) {
        when (val result = validateDescription(d)) {
            is CatatkuResult.Ok -> println("'$d' -> '${result.value}'")
            is CatatkuResult.Err -> println("'$d' -> error: ${result.error}")
        }
    }
}
```

Save and run. Output:

```text
'42' -> 42
'abc' -> error: InvalidId(text=abc)
'100' -> 100
'Pay rent' -> 'Pay rent'
'  ' -> error: EmptyDescription
'' -> error: EmptyDescription
```

This version of `CatatkuError` keeps only the three variants the example needs. `EmptyDescription` overrides `toString()`, just like the `Status` objects in earlier lessons, because a plain `object` prints as its class name plus a memory address (something like `CatatkuError$EmptyDescription@87aac27`), while data classes such as `InvalidId` already print their fields nicely.

The `CatatkuResult<T>` sealed class wraps either a successful value (`Ok`) or an error (`Err`). Functions like `parseId` and `validateDescription` return this type instead of throwing exceptions. Callers use `when` to handle both cases explicitly.

The notation `CatatkuResult<out T>` uses the `out` variance modifier (an advanced topic we will not cover in detail), which lets `CatatkuResult<Nothing>` from `Err` be a subtype of `CatatkuResult<T>` for any `T`. In practice, this lets you return `CatatkuResult.Err(...)` regardless of what `T` is in the surrounding function.

The key advantage of this style is that errors are values. Every place that uses a function like `parseId` has to acknowledge the possibility of failure, because the compiler will not let them ignore the `Err` variant when destructuring. This makes the error-handling story explicit and consistent throughout the codebase.

### When to Use Each Style

Use exceptions for:
- Unexpected failures (bugs, corrupt environment, hardware errors)
- Failures from libraries you do not control
- Failures that you genuinely cannot recover from at this layer
- Top-level "something went wrong" handling

Use sealed result types for:
- Expected errors that are part of normal operation
- User input validation failures
- Domain-specific errors that callers will handle differently
- Errors that you want to make impossible to ignore

For Catatku, we will use sealed result types for command-processing errors (Lesson 18), where the user might type a wrong id or an empty description and we want to handle these gracefully with a friendly error message. We will use exceptions for genuinely unexpected things like file system errors that we cannot anticipate.

---

## 8. Run and Test

Combine everything from this lesson into a comprehensive example.

### Step 1: A Catatku Error Demo

Replace `Main.kt` with this:

```kotlin
sealed class CatatkuError {
    data class EntryNotFound(val id: Int) : CatatkuError()
    data class InvalidId(val text: String) : CatatkuError()
    object EmptyDescription : CatatkuError()
    data class IoError(val message: String) : CatatkuError()
    data class ParseError(val message: String) : CatatkuError()
    
    fun describe(): String = when (this) {
        is EntryNotFound -> "Entry with id $id not found"
        is InvalidId -> "Invalid id: '$text' is not a valid integer"
        is EmptyDescription -> "Description cannot be empty"
        is IoError -> "I/O error: $message"
        is ParseError -> "Parse error: $message"
    }
}

sealed class CatatkuResult<out T> {
    data class Ok<T>(val value: T) : CatatkuResult<T>()
    data class Err(val error: CatatkuError) : CatatkuResult<Nothing>()
}

fun parseId(text: String): CatatkuResult<Int> {
    val n = text.toIntOrNull() ?: return CatatkuResult.Err(CatatkuError.InvalidId(text))
    return CatatkuResult.Ok(n)
}

fun validateDescription(s: String): CatatkuResult<String> {
    if (s.isBlank()) return CatatkuResult.Err(CatatkuError.EmptyDescription)
    return CatatkuResult.Ok(s.trim())
}

fun findEntry(entries: List<Pair<Int, String>>, id: Int): CatatkuResult<String> {
    val found = entries.firstOrNull { it.first == id }
        ?: return CatatkuResult.Err(CatatkuError.EntryNotFound(id))
    return CatatkuResult.Ok(found.second)
}

fun safeReadConfig(text: String): CatatkuResult<Int> {
    return try {
        val parsed = text.toInt()
        CatatkuResult.Ok(parsed * 2)
    } catch (e: NumberFormatException) {
        CatatkuResult.Err(CatatkuError.ParseError(e.message ?: "unknown parse error"))
    }
}

fun main() {
    val entries = listOf(1 to "Pay rent", 2 to "Read book", 3 to "Walk dog")
    
    println("=== Successful operations ===")
    handleResult("parseId('42')") { parseId("42") }
    handleResult("validateDescription('hello')") { validateDescription("hello") }
    handleResult("findEntry(2)") { findEntry(entries, 2) }
    handleResult("safeReadConfig('21')") { safeReadConfig("21") }
    
    println("\n=== Failing operations ===")
    handleResult("parseId('abc')") { parseId("abc") }
    handleResult("validateDescription('  ')") { validateDescription("  ") }
    handleResult("findEntry(99)") { findEntry(entries, 99) }
    handleResult("safeReadConfig('xyz')") { safeReadConfig("xyz") }
    
    println("\n=== runCatching example ===")
    val r1: Result<Int> = runCatching { "42".toInt() }
    val r2: Result<Int> = runCatching { "abc".toInt() }
    println("r1: ${r1.getOrNull()}")
    println("r2: ${r2.getOrNull()}, ${r2.exceptionOrNull()?.message}")
}

fun <T> handleResult(label: String, block: () -> CatatkuResult<T>) {
    when (val result = block()) {
        is CatatkuResult.Ok -> println("$label -> Ok(${result.value})")
        is CatatkuResult.Err -> println("$label -> Err(${result.error.describe()})")
    }
}
```

Save and run.

### Step 2: Read the Output

Output:

```text
=== Successful operations ===
parseId('42') -> Ok(42)
validateDescription('hello') -> Ok(hello)
findEntry(2) -> Ok(Read book)
safeReadConfig('21') -> Ok(42)

=== Failing operations ===
parseId('abc') -> Err(Invalid id: 'abc' is not a valid integer)
validateDescription('  ') -> Err(Description cannot be empty)
findEntry(99) -> Err(Entry with id 99 not found)
safeReadConfig('xyz') -> Err(Parse error: For input string: "xyz")

=== runCatching example ===
r1: 42
r2: null, For input string: "abc"
```

Walk through what each piece contributed. The `CatatkuError` sealed class has five variants and a `describe()` member function that produces a friendly message via exhaustive `when`. The `CatatkuResult<T>` sealed class wraps either an `Ok(value)` or an `Err(error)`. Each domain function (`parseId`, `validateDescription`, `findEntry`, `safeReadConfig`) returns a `CatatkuResult` and explicitly handles the failure cases.

The `safeReadConfig` function is interesting because it bridges between exceptions and the result type. It uses `try`/`catch` internally to convert a `NumberFormatException` into a `ParseError` variant. This is a common pattern when integrating with code that throws (often Java code or older Kotlin code): catch the exception at the boundary and convert it into your domain error type.

The `handleResult` helper is a small higher-order function that runs a block, captures the result, and prints either the success value or the error description. This is how Catatku's command processor will eventually consume results from validation and persistence layers.

### Step 3: Try Adding a New Error

Add a new variant, `data class DuplicateId(val id: Int) : CatatkuError()`, below `ParseError` inside `CatatkuError`. Save and run. The build fails, and the compiler points at the `when` inside `describe()` with the message `'when' expression must be exhaustive. Add the 'is DuplicateId' branch or an 'else' branch.` Add the missing branch, `is DuplicateId -> "Duplicate id: $id already exists"`, to the `when`, and run again.

Now everything compiles. This is the same exhaustive-checking refactor flow we saw in Lesson 11 with `Status`. The compiler walks you through every place that needs updating, which makes adding new error cases safe and predictable. With exceptions and unstructured error handling, adding a new error type would have no compiler help; you would have to find every catch clause manually.

---

## 9. Fix the Errors in Your Code

Three error-handling mistakes are common. Each one below shows the wrong version first, then the corrected version.

**Error 1: Catching too broadly**

```kotlin
// Wrong
fun riskyOperation(): Int = "abc".toInt()

fun main() {
    try {
        riskyOperation()
    } catch (e: Throwable) {
        println("Caught: $e")
    }
}

// Correct
fun riskyOperation(): Int = "abc".toInt()

fun main() {
    try {
        riskyOperation()
    } catch (e: NumberFormatException) {
        println("Caught: $e")
    }
}
```

Both versions compile and print `Caught: java.lang.NumberFormatException: For input string: "abc"`, which is exactly why this mistake survives so long. Catching `Throwable` also catches `OutOfMemoryError` and `StackOverflowError`, which are typically not recoverable, and catching them lets your program continue in a corrupt state. The fix is to catch the most specific exception type that makes sense, here `NumberFormatException`. As a habit, use `Exception` as the broadest type you catch, never `Throwable` or `Error`.

**Error 2: An empty catch block**

```kotlin
// Wrong
fun parseInt(s: String): Int {
    return try {
        s.toInt()
    } catch (e: Exception) {
    }
}

// Correct
fun parseInt(s: String): Int {
    return try {
        s.toInt()
    } catch (e: NumberFormatException) {
        println("Could not parse '$s', using 0")
        0
    }
}

fun main() {
    println(parseInt("12"))
    println(parseInt("twelve"))
}
```

The compiler rejects the wrong version with `Return type mismatch: expected 'kotlin.Int', actual 'kotlin.Any'.` Because `try` is an expression, the empty `catch` block produces `Unit`, so the whole `try` no longer has the type `Int`. Even in places where an empty catch does compile, it makes bugs invisible: the exception is silently discarded and the program continues as if nothing went wrong. The corrected version reports the problem and returns a sensible default, printing `12`, then `Could not parse 'twelve', using 0`, then `0`. As a habit, never write an empty catch block. Log the exception, return a sensible default, propagate it, or convert it to a domain error.

**Error 3: Using exceptions for normal control flow**

```kotlin
// Wrong
fun findUser(id: Int): String {
    if (id == 1) return "Alice"
    if (id == 2) return "Bob"
    throw RuntimeException("user not found")
}

fun main() {
    for (id in 1..3) {
        try {
            println(findUser(id))
        } catch (e: RuntimeException) {
            println("user $id not found")
        }
    }
}

// Correct
fun findUser(id: Int): String? {
    if (id == 1) return "Alice"
    if (id == 2) return "Bob"
    return null
}

fun main() {
    for (id in 1..3) {
        println(findUser(id) ?: "user $id not found")
    }
}
```

Both versions print `Alice`, `Bob`, and `user 3 not found`, but the wrong one treats an expected case (a user not being found) as an exception. Exceptions are slow (they walk the stack to build a trace), and they obscure the program's intent because the catch block becomes part of normal logic. The corrected version returns a nullable `String?` and handles the missing user with the Elvis operator. For richer cases, a sealed result type like `CatatkuResult` does the same job. As a habit, ask "is this case expected to happen sometimes, as part of normal use of this function?" If yes, use a return value. If it would only happen due to a bug or system failure, an exception is appropriate.

---

## 10. Exercises

These exercises practice error handling.

**Exercise 1:** Write a function `safeDivide(a: Int, b: Int): CatatkuResult<Int>` that returns `Ok(a / b)` if `b != 0`, or `Err(...)` otherwise. Use a sealed class with a `DivideByZero` variant to represent the error.

**Exercise 2:** Write a function `parseDate(s: String): Result<Triple<Int, Int, Int>>` that parses a string in the format "YYYY-MM-DD" using `runCatching`. The string is split on `-` and each part is converted to an `Int`. Return the result as a `Triple`. Any failure (wrong format, non-numeric parts) becomes a `Result.failure`.

**Exercise 3:** Write a function `lookupAndDouble(map: Map<String, Int>, key: String): CatatkuResult<Int>` that returns the value associated with `key` doubled, or an `Err` if `key` is not in the map. Use a custom error variant.

---

## 11. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

The solution defines a small `CatatkuError` with only the `DivideByZero` variant the exercise needs, plus the same `CatatkuResult` wrapper from this lesson.

```kotlin
sealed class CatatkuError {
    data class DivideByZero(val dividend: Int) : CatatkuError()
}

sealed class CatatkuResult<out T> {
    data class Ok<T>(val value: T) : CatatkuResult<T>()
    data class Err(val error: CatatkuError) : CatatkuResult<Nothing>()
}

fun safeDivide(a: Int, b: Int): CatatkuResult<Int> {
    if (b == 0) return CatatkuResult.Err(CatatkuError.DivideByZero(a))
    return CatatkuResult.Ok(a / b)
}

fun main() {
    val pairs = listOf(10 to 2, 7 to 0, 9 to 3)

    for ((a, b) in pairs) {
        when (val result = safeDivide(a, b)) {
            is CatatkuResult.Ok -> println("$a / $b = ${result.value}")
            is CatatkuResult.Err -> println("$a / $b failed: ${result.error}")
        }
    }
}
```

Save and run. Output:

```text
10 / 2 = 5
7 / 0 failed: DivideByZero(dividend=7)
9 / 3 = 3
```

`safeDivide` checks for the one failure case first and returns early with `Err`, so the division `a / b` only runs when `b` is not zero and can never throw `ArithmeticException`. The `DivideByZero` variant carries the dividend so the error message can say which division failed. In `main`, the destructuring `for ((a, b) in pairs)` unpacks each `Pair`, and the `when` must handle both `Ok` and `Err`, so the caller cannot forget about the failure case.

**Solution for Exercise 2:**

This exercise practices `runCatching` for converting exception-throwing code into a `Result` value. The parsing has multiple ways to fail (wrong number of parts, non-numeric parts, out-of-range values), and `runCatching` handles them all uniformly.

```kotlin
fun parseDate(s: String): Result<Triple<Int, Int, Int>> = runCatching {
    val parts = s.split("-")
    require(parts.size == 3) { "expected YYYY-MM-DD format, got '$s'" }
    
    val year = parts[0].toInt()
    val month = parts[1].toInt()
    val day = parts[2].toInt()
    
    Triple(year, month, day)
}

fun main() {
    val inputs = listOf("2026-04-26", "2026/04/26", "abc-de-fg", "2026", "2026-04")
    
    for (input in inputs) {
        val result = parseDate(input)
        result.fold(
            onSuccess = { (y, m, d) -> println("'$input' -> $y/$m/$d") },
            onFailure = { e -> println("'$input' -> error: ${e.message}") }
        )
    }
}
```

Save and run. Output:

```text
'2026-04-26' -> 2026/4/26
'2026/04/26' -> error: expected YYYY-MM-DD format, got '2026/04/26'
'abc-de-fg' -> error: For input string: "abc"
'2026' -> error: expected YYYY-MM-DD format, got '2026'
'2026-04' -> error: expected YYYY-MM-DD format, got '2026-04'
```

The function uses `runCatching { ... }` to wrap the parsing block. Inside, we split the input on `-`, use `require` to validate the part count, and then convert each part to an `Int`. Any failure (the require throwing `IllegalArgumentException`, the `toInt` throwing `NumberFormatException`, or anything else) gets caught and wrapped as a `Result.failure`. Successful parses produce a `Result.success(Triple(year, month, day))`.

The `fold` method on `Result` takes named arguments `onSuccess` and `onFailure`, with a lambda for each case. The success lambda destructures the `Triple` into `(y, m, d)` (Triple is destructurable like data classes) and prints the formatted date. The failure lambda gets the exception (`Throwable`) and prints its message.

The output shows the function gracefully handling several failure modes: wrong separator, non-numeric parts, too few parts. Each failure produces a useful error message rather than a crash. The same logic with manual `try`/`catch` would be considerably more verbose; `runCatching` reduces the ceremony to one wrapping call.

A more rigorous version might validate the ranges (month 1-12, day 1-31, year reasonable), but those checks just add more `require` lines inside the block. The pattern stays the same: validate with `require` and let any failure surface as a `Result.failure`.

For Catatku, this pattern is exactly what we will use in Lesson 19 when reading files: wrap the file operation in `runCatching` (or similar), catch the IO exception, and convert it into a `CatatkuError.IoError` for the rest of the application to handle uniformly.

**Solution for Exercise 3:**

The custom variant is `KeyNotFound`, which records the key that was missing.

```kotlin
sealed class CatatkuError {
    data class KeyNotFound(val key: String) : CatatkuError()
}

sealed class CatatkuResult<out T> {
    data class Ok<T>(val value: T) : CatatkuResult<T>()
    data class Err(val error: CatatkuError) : CatatkuResult<Nothing>()
}

fun lookupAndDouble(map: Map<String, Int>, key: String): CatatkuResult<Int> {
    val value = map[key] ?: return CatatkuResult.Err(CatatkuError.KeyNotFound(key))
    return CatatkuResult.Ok(value * 2)
}

fun main() {
    val stock = mapOf("apples" to 5, "pears" to 12)

    for (key in listOf("apples", "bananas", "pears")) {
        when (val result = lookupAndDouble(stock, key)) {
            is CatatkuResult.Ok -> println("$key doubled: ${result.value}")
            is CatatkuResult.Err -> println("$key: ${result.error}")
        }
    }
}
```

Save and run. Output:

```text
apples doubled: 10
bananas: KeyNotFound(key=bananas)
pears doubled: 24
```

Looking up a missing key in a `Map` with `map[key]` returns `null`, so the Elvis operator turns that `null` into an early `return` of an `Err`. This is the same `?: return` pattern that `parseId` and `findEntry` use in the Run and Test section. When the key exists, the value is doubled and wrapped in `Ok`. Because `KeyNotFound` is a data class, printing the error shows the missing key without any extra formatting code.

---

## 12. Understanding Errors as Values

The deeper question behind this lesson is: when should errors be exceptions, and when should they be return values? The answer comes down to "expected versus unexpected", but understanding the trade-offs makes the choice clearer.

Exceptions have a specific semantic: "something went wrong that the immediate caller probably cannot handle, and the right thing to do is unwind the stack until we find code that knows how to recover". This is the right model for genuinely unexpected failures: a database connection drops, a file system runs out of space, a deeply nested computation hits a bug. The caller two layers up cannot do anything useful with this; only the top-level handler can log it, alert someone, and fail gracefully.

But many "errors" are not unexpected. A user types an invalid id; the validation function should report this and let the caller decide what to do. A file does not exist on first run; the loader should report "no data yet" and let the caller initialize an empty state. A parser hits a syntax error; the parser should report which line and let the caller decide whether to abort or continue. These are not "bugs" or "system failures"; they are normal program states. Treating them as exceptions has several costs.

The first cost is performance. Throwing an exception walks the stack to build a trace, which is expensive (orders of magnitude slower than a regular function call). For one-off errors this does not matter, but for code that handles many "errors" per second (like parsing user input in a tight loop), it can be a real problem.

The second cost is clarity. Exceptions hide the error path from the function signature. A function that returns `Int` looks the same whether or not it might throw, but the calling code's behavior is very different in the two cases. With a return type like `CatatkuResult<Int>`, the signature itself tells the caller "this might fail; you have to handle that". The compiler then enforces this handling, which prevents bugs where the caller forgets that the operation could fail.

The third cost is composability. Exceptions are awkward to chain through layers. If function A calls B which calls C, and C throws, A has to either catch the exception (and translate or rethrow) or propagate it. Each layer is doing exception handling work. With a result type, you can transform the result through `map`, `flatMap`, and similar operations, keeping the failure case visible at every layer without code at every layer to handle it.

The fourth cost is interoperability with the type system. Exceptions are a side channel that bypasses normal type-checking. Sealed result types are part of the type system; the compiler checks that you handled every case, that the types match, that the error variants are appropriate. This is the same benefit that drove us to sealed classes for `Status` in Lesson 11.

The pattern of using sealed result types for expected errors is sometimes called "errors as values" or "the result type pattern". It is the default in languages like Haskell (with `Either`) and Swift (with `Result`). Kotlin programmers can adopt the same style by defining their own sealed result types or using the standard library's `Result<T>` (which uses `Throwable` for the error type, less expressive than a sealed error class but easier to use with existing exception-throwing code).

The cost of "errors as values" is that you have to design the error types upfront. With exceptions, you can throw any new exception type from any function without changing signatures. With sealed result types, adding a new error variant means updating every `when` over that error, which the compiler will catch. This is mostly a benefit (refactoring is safer), but it requires deciding on error types as a design step rather than just throwing them as needed.

For most Kotlin code, the right balance is: use exceptions for unexpected failures and library code that follows the exception convention; use sealed result types for domain logic where errors are part of normal operation and where you want type-system enforcement of error handling. Catatku will use this mixed style: file IO errors come from Java's `File.readText` as exceptions, which we catch at the boundary and convert to `CatatkuError.IoError` variants for the rest of the application.

---

## Next Up - Lesson 17

Kotlin's error handling has two complementary styles. Exceptions work like Java's, with `try`/`catch`/`finally` blocks and `throw` statements, but Kotlin removes the `throws` declaration requirement (no checked exceptions) which keeps function signatures cleaner. The `try` construct is an expression that returns a value, like `if` and `when`. The `runCatching` function wraps any block in a `Result<T>` value that captures success or failure, which is useful when you want to pass the outcome through several layers of code. For expected error cases that are part of normal program operation, a sealed class is often a better choice than exceptions: it gives you exhaustive `when` matching, makes errors explicit at every layer, and avoids the runtime cost of stack-walking exceptions. We defined `CatatkuError` as a sealed class with five variants for Catatku, and a `CatatkuResult<T>` sealed class for wrapping operations that might fail. This vocabulary will be used throughout the remaining lessons for command parsing, file I/O, and validation.

In Lesson 17 you will learn to organize Catatku across multiple files using packages. The `Entry`, `Status`, `Priority`, `CatatkuError`, and `EntryList` types will move into their own files in a sensible package structure, replacing the single-file approach we have been using.
