## 1. Before You Begin

So far every interesting piece of code has lived inside `main`. That works for tiny programs, but anything larger than a few dozen lines starts to feel cramped. Functions are how you take a chunk of logic, give it a name, parameters, and a return value, and use it from anywhere else in your program. They are also a unit of thinking: when you give a piece of work a name, you can reason about that work as a single thing rather than as a sequence of statements. Every nontrivial program is built from functions calling other functions, and Kotlin makes function-writing genuinely pleasant compared to most other languages.

Kotlin's function syntax has several features that are unusual in other mainstream languages and that you will use constantly. Default arguments let you give parameters a sensible default so callers do not have to specify everything. Named arguments let callers say which parameter they are passing by name, which dramatically improves readability for functions with many parameters. Single-expression functions remove the curly-brace ceremony when a function is just a one-line expression. Top-level functions exist outside any class, the way you have already been writing `main`. Together these features make Kotlin functions feel lightweight and composable, which encourages you to break code into small named pieces rather than letting one giant function do everything.

### What You'll Build

A series of small helper functions inside `Main.kt` that demonstrate every aspect of function declarations. You will write a function with no parameters and no return, a function with parameters and a return value, a single-expression function, a function with default arguments, a function with named arguments, and a refactored version of the Catatku-style task printing example from Lesson 5 where each part of the printing logic is a named function. By the end the `main` function will be considerably shorter because the actual work has moved into well-named helpers.

### What You'll Learn

- ✅ How to declare functions with `fun` and explicit parameter types
- ✅ How to specify a return type with `:` and return a value with `return`
- ✅ How to write single-expression functions with `=` instead of `{ }`
- ✅ How to use default arguments and named arguments at call sites
- ✅ When the `Unit` return type appears and what it means

### What You'll Need

- The `catatku` Gradle project from the previous lessons, with IntelliJ IDEA open
- Familiarity with variables, types, and control flow from Lessons 4 and 5
- About thirty-five minutes
- A willingness to refactor working code into smaller pieces

---

## 2. Declaring Functions

Functions in Kotlin are declared with the `fun` keyword. The simplest function takes no arguments and returns nothing meaningful. We have been writing one such function (`main`) since Lesson 1; now let us write some that do real work.

### Step 1: Write a No-Parameter Function

Open `Main.kt` and replace its contents with the example below. We will keep things minimal so the function structure is the focus.

```kotlin
fun printBanner() {
    println("===========================================")
    println("            Welcome to Catatku             ")
    println("===========================================")
}

fun main() {
    printBanner()
    println("Ready to manage tasks!")
}
```

Save and run with the green triangle next to `main`. The output is:

```text
===========================================
            Welcome to Catatku             
===========================================
Ready to manage tasks!
```

Walk through what each piece does. The `fun printBanner() { ... }` declaration introduces a function named `printBanner`. The empty parentheses indicate it takes no parameters. There is no `:` after the parentheses to specify a return type, which means this function returns the special `Unit` type meaning "no useful value". The body uses three `println` calls to print three lines.

The `main` function calls `printBanner()` by writing the function name followed by parentheses. Even though there are no arguments to pass, the parentheses are required because they distinguish "call this function" from "refer to this function as a value" (the latter being a thing you can do with function references, which we will see in Lesson 13). After `printBanner()` returns, `main` continues with the next `println`.

The naming convention for Kotlin functions is `camelCase`: lowercase first word, capitalized first letters for subsequent words. So `printBanner`, `addTask`, `findById`, and so on. This matches Java's convention and is what IntelliJ's autocomplete and refactoring tools assume. Class names use `PascalCase` (capitalized first letter), and constants use `SCREAMING_SNAKE_CASE`. Following these conventions makes your code blend in with the rest of the Kotlin ecosystem and lets readers focus on the logic rather than getting distracted by unfamiliar naming.

### Step 2: Add Parameters

Functions become useful when they accept parameters. Each parameter has a name and an explicit type, separated by a colon, and multiple parameters are separated by commas.

```kotlin
fun greetUser(name: String) {
    println("Hello, $name!")
    println("Welcome to Catatku.")
}

fun main() {
    greetUser("Reader")
    greetUser("Informatika")
}
```

Save and run. Output:

```text
Hello, Reader!
Welcome to Catatku.
Hello, Informatika!
Welcome to Catatku.
```

The parameter `name: String` declares that this function takes one argument named `name` of type `String`. Inside the function body, `name` behaves like a `val` variable (you can read it but cannot reassign it). At each call site, we pass a different string, and the function uses that string in its output.

Parameter types are required in Kotlin function declarations. Unlike variable declarations where the compiler can infer the type from the initial value, function parameters have no initial value to inspect, so you must always write the type explicitly. This is the same rule as in Java and most other statically typed languages, and it serves as a kind of lightweight documentation: anyone reading the function signature knows exactly what it expects without having to read the body.

### Step 3: Return a Value

Functions become much more useful when they produce values. The return type goes after the parameter list, separated by a colon, and the body uses `return` to send a value back to the caller.

```kotlin
fun double(value: Int): Int {
    return value * 2
}

fun fullName(first: String, last: String): String {
    return "$first $last"
}

fun main() {
    val ten = double(5)
    println("double of 5 is $ten")
    
    val name = fullName("Ada", "Lovelace")
    println("name: $name")
}
```

Save and run. Output:

```text
double of 5 is 10
name: Ada Lovelace
```

The function `double(value: Int): Int` says "take an `Int` and return an `Int`". Inside, `return value * 2` produces the result. The function `fullName(first: String, last: String): String` takes two `String` parameters and returns a `String`. Inside, we use a string template to combine them.

The return type is required when a function returns a value. Without the `: Int` after the parameters of `double`, the compiler would assume the function returns `Unit` (no useful value) and would complain when we try to assign the result to `val ten`. The explicit return type also serves as documentation; readers of the function signature know what they are getting back without reading the body.

A small but important habit: do not skip the return type even when it could be inferred. We will see in Section 4 that single-expression functions allow the compiler to infer the return type, but for multi-line function bodies, idiomatic Kotlin always writes the return type explicitly. This matches the convention in Kotlin's standard library and makes function signatures self-documenting.

---

## 3. Default Arguments and Named Arguments

Two of Kotlin's most pleasant function features come into play when functions have many parameters: default arguments let you give a sensible value when the caller does not specify one, and named arguments let callers say which parameter they are setting by name. Together they replace the builder patterns and overload chains that Java code is full of.

### Step 1: Add Default Arguments

Replace `Main.kt` with this example showing default arguments in action:

```kotlin
fun greetUser(name: String, greeting: String = "Hello") {
    println("$greeting, $name!")
}

fun main() {
    greetUser("Reader")
    greetUser("Reader", "Hi")
    greetUser("Reader", "Welcome")
}
```

Save and run. Output:

```text
Hello, Reader!
Hi, Reader!
Welcome, Reader!
```

The parameter `greeting: String = "Hello"` declares that `greeting` has a default value of `"Hello"`. If the caller does not provide a value for `greeting`, the default is used. In the first call, only `name` is given, so `greeting` defaults to `"Hello"`. In the second and third calls, the caller provides both arguments, overriding the default.

Default arguments are useful when most callers use the same value but a few callers want to customize. The Java equivalent would be writing two overloaded functions: `greetUser(String name)` that calls `greetUser(name, "Hello")`, plus `greetUser(String name, String greeting)` that does the actual work. Kotlin lets you write one function with a default argument, which is shorter and easier to maintain.

You can have multiple default arguments, and they can appear in any position (not just at the end):

```kotlin
fun describeTask(
    description: String,
    priority: String = "Medium",
    isDone: Boolean = false
) {
    val marker = if (isDone) "[x]" else "[ ]"
    println("$marker ($priority) $description")
}

fun main() {
    describeTask("Buy groceries")
    describeTask("Pay rent", "High")
    describeTask("Read for fun", "Low", true)
}
```

Save and run. Output:

```text
[ ] (Medium) Buy groceries
[ ] (High) Pay rent
[x] (Low) Read for fun
```

The function `describeTask` has three parameters, two of which have defaults. Each call site provides as many arguments as it wants, with the rest taking their defaults. In Java this same flexibility would require six or seven overloaded methods to cover all the combinations; Kotlin's defaults handle them all in one declaration.

### Step 2: Use Named Arguments

When a function has several parameters, especially with defaults, callers can specify arguments by name to make the call site self-documenting:

```kotlin
fun describeTask(
    description: String,
    priority: String = "Medium",
    isDone: Boolean = false
) {
    val marker = if (isDone) "[x]" else "[ ]"
    println("$marker ($priority) $description")
}

fun main() {
    describeTask("Pay rent", isDone = true)
    describeTask("Read for fun", priority = "Low", isDone = false)
    describeTask(description = "Buy groceries", priority = "High")
}
```

Save and run. Output:

```text
[x] (Medium) Pay rent
[ ] (Low) Read for fun
[ ] (High) Buy groceries
```

The syntax `isDone = true` says "set the parameter named `isDone` to `true`, regardless of position". This lets you skip parameters that have defaults: in the first call, we provide `description` positionally and `isDone` by name, while `priority` takes its default. Without named arguments, you would have to either provide `priority` even when you wanted the default (passing the default value explicitly) or rely on positional ordering, which gets confusing when there are multiple parameters with the same type.

Named arguments also document what each value at the call site is. Compare `describeTask("Buy groceries", "High", false)` to `describeTask(description = "Buy groceries", priority = "High", isDone = false)`. The named version is harder to misread, especially for booleans where "true" and "false" by themselves do not tell you which parameter they are setting. Many style guides recommend using named arguments for any boolean parameter and any function with three or more parameters.

You can mix positional and named arguments in the same call, but once you start using names, every subsequent argument must also be named. So `describeTask("Buy groceries", priority = "High", isDone = false)` works, but you cannot put a positional argument after a named one.

### Combining Defaults and Naming

The combination of default arguments and named arguments is one of Kotlin's nicest ergonomic features. It replaces the builder pattern that Java code uses for object construction with named arguments that are checked by the type system at compile time. We will see this come up especially in Lessons 9 and 10 when we start defining classes; constructors with default arguments and named-argument calls produce code that is both safe and readable, without any of the boilerplate of explicit builders.

For Catatku, we will use this pattern when creating `Entry` instances. The constructor will have parameters for description, priority, status, and createdAt, and most callers will only specify the description while letting priority default to medium and status default to pending. Naming arguments will make the few customized calls clear about what is being overridden.

---

## 4. Single-Expression Functions

When a function consists of a single expression, Kotlin lets you write it without curly braces and without a `return` statement. The syntax is `fun name(...): Type = expression`. This is one of the small features that makes Kotlin code dramatically shorter than Java.

### Step 1: Convert a Multi-Line Function

Take the simple `double` function from Section 2 and rewrite it as a single-expression function:

```kotlin
fun double(value: Int): Int = value * 2

fun main() {
    println(double(5))
    println(double(7))
}
```

Save and run. Output:

```text
10
14
```

The function body is replaced by `= expression`. The `=` says "this function's value is the expression that follows". The result of the expression is automatically returned; there is no `return` keyword. The whole declaration is one line, which makes simple helpers like this almost as compact as the value they compute.

Notice that we kept the explicit return type `: Int`. For single-expression functions, you can also omit the return type and let the compiler infer it from the expression:

```kotlin
fun double(value: Int) = value * 2
```

This compiles to the same thing. The compiler examines `value * 2`, sees that it produces an `Int`, and infers the return type. For very short functions like `double`, the inferred form is fine; for longer or more complex single-expression functions, including the explicit type is clearer for readers.

### Step 2: Use Single-Expression Functions for Mappings

Single-expression functions shine when the function is a mapping from input to output. Many functions you will write in real code have this shape, and the single-expression form removes ceremony.

```kotlin
fun priorityLetter(priority: String): Char = when (priority) {
    "High" -> 'H'
    "Medium" -> 'M'
    "Low" -> 'L'
    else -> '?'
}

fun statusMarker(isDone: Boolean): String = if (isDone) "[x]" else "[ ]"

fun main() {
    println("High -> ${priorityLetter("High")}")
    println("Done? ${statusMarker(true)}")
    println("Pending? ${statusMarker(false)}")
}
```

Save and run. Output:

```text
High -> H
Done? [x]
Pending? [ ]
```

Both functions are single expressions: a `when` expression and an `if` expression. Because Kotlin's control flow constructs are expressions (Lesson 5), they fit perfectly into the single-expression function pattern. The result is two helper functions whose code is barely longer than their values.

This is exactly the style we will use throughout Catatku. Small mapping functions stay as single expressions; functions with more complex logic use the curly-brace form. The visual difference helps readers: a function with `=` is a "computation", while a function with `{ ... }` is a "procedure". Both are functions, but the visual cue suggests how to read each one.

### Step 3: Notice the Limit

Single-expression functions can do anything that fits into one expression, but they cannot have multiple statements without using a block expression `run { ... }` or similar. For functions that genuinely have several steps, you keep the curly-brace form:

```kotlin
fun printTaskDetails(description: String, priority: String, isDone: Boolean) {
    val marker = if (isDone) "[x]" else "[ ]"
    val priorityLabel = priority.uppercase()
    println("$marker $priorityLabel: $description")
}

fun main() {
    printTaskDetails("Pay rent", "high", true)
    printTaskDetails("Call dentist", "low", false)
}
```

Save and run. Output:

```text
[x] HIGH: Pay rent
[ ] LOW: Call dentist
```

This function has three steps (compute the marker, compute the priority label, print the result) and would not naturally fit into one expression. Forcing it would make the code harder to read, not easier. The right choice is to use the multi-step form when there are multiple steps and the single-expression form when there is one.

The general rule is: if you can write the function as one clean expression, do that. If not, the multi-step form with `{ ... }` and explicit `return` (or `Unit` return) is correct. Both forms produce the same bytecode, so the choice is purely about readability.

---

## 5. Composing Functions: Refactoring the Lesson 5 Example

Real programs are built by composing small functions. Each function does one thing well, and other functions call them to do bigger things. Let us refactor the parallel-list task printer from Lesson 5 into a set of named functions to see this composition in action.

### Step 1: The Original Code

Recall the inline version from Lesson 5:

```kotlin
fun main() {
    val descriptions = listOf("Pay rent", "Finish Kotlin course", "Call dentist", "Walk the dog")
    val statuses = listOf("done", "pending", "cancelled", "pending")
    val priorities = listOf("H", "M", "L", "M")
    
    println("Catatku task list:")
    
    for (i in descriptions.indices) {
        val description = descriptions[i]
        val status = statuses[i]
        val priority = priorities[i]
        
        val marker = when (status) {
            "pending" -> "[ ]"
            "done" -> "[x]"
            "cancelled" -> "[!]"
            else -> "[?]"
        }
        
        val priorityLabel = when (priority) {
            "H" -> "High"
            "M" -> "Medium"
            "L" -> "Low"
            else -> "?"
        }
        
        println("$marker (${priorityLabel}) ${i + 1}. $description")
    }
}
```

Save and run. Output:

```text
Catatku task list:
[x] (High) 1. Pay rent
[ ] (Medium) 2. Finish Kotlin course
[!] (Low) 3. Call dentist
[ ] (Medium) 4. Walk the dog
```

The `main` function does several distinct things: it sets up data, it loops, and inside the loop it derives display values from raw fields and prints them. Three or four concerns are mixed together, and the function is becoming hard to read at a glance. Refactoring extracts the concerns into named helpers.

### Step 2: Extract the Mapping Functions

The two `when` expressions inside the loop are perfect candidates for single-expression helper functions. They are pure mappings from input to output with no side effects, and giving them names makes the loop body shorter.

```kotlin
fun statusMarker(status: String): String = when (status) {
    "pending" -> "[ ]"
    "done" -> "[x]"
    "cancelled" -> "[!]"
    else -> "[?]"
}

fun priorityLabel(priority: String): String = when (priority) {
    "H" -> "High"
    "M" -> "Medium"
    "L" -> "Low"
    else -> "?"
}

fun main() {
    val descriptions = listOf("Pay rent", "Finish Kotlin course", "Call dentist", "Walk the dog")
    val statuses = listOf("done", "pending", "cancelled", "pending")
    val priorities = listOf("H", "M", "L", "M")
    
    println("Catatku task list:")
    
    for (i in descriptions.indices) {
        val description = descriptions[i]
        val status = statuses[i]
        val priority = priorities[i]
        
        val marker = statusMarker(status)
        val label = priorityLabel(priority)
        
        println("$marker ($label) ${i + 1}. $description")
    }
}
```

Save and run. The output is unchanged:

```text
Catatku task list:
[x] (High) 1. Pay rent
[ ] (Medium) 2. Finish Kotlin course
[!] (Low) 3. Call dentist
[ ] (Medium) 4. Walk the dog
```

The behavior is the same, but the structure is much cleaner. The two `when` expressions live in named functions that anyone can find, understand, and modify. The loop body inside `main` is now four lines of clear data-flow: extract the fields, compute the marker and label, print the result. Reading the code is faster because each line has one obvious meaning.

### Step 3: Extract the Print Function

We can take the refactor further by pulling the per-task printing into its own function:

```kotlin
fun statusMarker(status: String): String = when (status) {
    "pending" -> "[ ]"
    "done" -> "[x]"
    "cancelled" -> "[!]"
    else -> "[?]"
}

fun priorityLabel(priority: String): String = when (priority) {
    "H" -> "High"
    "M" -> "Medium"
    "L" -> "Low"
    else -> "?"
}

fun printTask(index: Int, description: String, status: String, priority: String) {
    val marker = statusMarker(status)
    val label = priorityLabel(priority)
    println("$marker ($label) ${index + 1}. $description")
}

fun main() {
    val descriptions = listOf("Pay rent", "Finish Kotlin course", "Call dentist", "Walk the dog")
    val statuses = listOf("done", "pending", "cancelled", "pending")
    val priorities = listOf("H", "M", "L", "M")
    
    println("Catatku task list:")
    
    for (i in descriptions.indices) {
        printTask(i, descriptions[i], statuses[i], priorities[i])
    }
}
```

Save and run. Output:

```text
Catatku task list:
[x] (High) 1. Pay rent
[ ] (Medium) 2. Finish Kotlin course
[!] (Low) 3. Call dentist
[ ] (Medium) 4. Walk the dog
```

The output is still unchanged. The `main` function is now extremely short. It sets up the data, prints a header, and delegates each task to `printTask`. The actual rendering logic lives in `printTask`, which composes `statusMarker` and `priorityLabel` to do its work. Each function has one job, and reading the program top-to-bottom feels like reading a description rather than puzzling out what an inline block of code is doing.

The refactor demonstrates a fundamental pattern: when `main` (or any function) starts having multiple concerns, extract each concern into its own named function. The total amount of code stays roughly the same (sometimes a bit longer because of the extra function declarations), but the readability improves dramatically. As Catatku grows in later lessons, we will keep applying this pattern: every new concern gets its own function or class, and `main` stays at the top-level orchestration role.

---

## 6. The Unit Type

You have seen functions that return values (with explicit `: Int` or `: String` return types) and functions that do not (the various `printXxx` helpers). The functions that "do not return a value" actually do return something; they return `Unit`, Kotlin's name for "no useful value".

### Step 1: Write Unit Explicitly

Add a function with an explicit `Unit` return type:

```kotlin
fun greet(name: String): Unit {
    println("Hello, $name!")
}

fun main() {
    greet("Reader")
    val result = greet("Catatku")
    println("Result of greet: $result")
}
```

Save and run. Output:

```text
Hello, Reader!
Hello, Catatku!
Result of greet: kotlin.Unit
```

The function `greet` returns `Unit`, which we write explicitly. The line `val result = greet("Catatku")` captures the return value, and printing it shows `kotlin.Unit`, which is the singleton instance of the `Unit` type.

In practice you almost never write `: Unit` explicitly because it is the default when no return type is specified. Writing `fun greet(name: String) { ... }` is equivalent to `fun greet(name: String): Unit { ... }`. The Kotlin convention is to omit `: Unit` and let the absence of a return type indicate "no return value". We do not need to dwell on this; just understand that "void" in Java becomes `Unit` in Kotlin, and you will rarely see it written explicitly.

### Compare to Other Languages

Other languages handle "no return value" in similar ways. Java uses `void`, which is a special keyword that does not produce a value at all. C and C++ also use `void`. Python uses `None`, which is similar to Kotlin's `Unit` in being a real value. JavaScript uses `undefined`. The differences are mostly philosophical: Java treats "no value" as a special case in the type system, while Kotlin and Python treat it as a regular type with one value.

The benefit of `Unit` being a real type is that it can be used in generic contexts. We will not write generic code in this course beyond what the standard library provides, but it is good to know that `Unit` works as a type parameter the same way `Int` or `String` do. This consistency is one of the small improvements Kotlin makes over Java; you do not have to remember a special case for "void" because there is no special case.

### Remember the Convention

For everyday Kotlin, just write `fun name(...) { ... }` for functions that do not return a value, and `fun name(...): Type { ... }` for functions that do. The compiler handles the rest. Do not write `: Unit` unless you have a specific reason; it adds noise without adding clarity.

---

## 7. Run and Test

Combine everything from this lesson into one program that exercises the full set of function features.

### Step 1: Build the Combined Example

Replace `Main.kt` with this comprehensive demonstration:

```kotlin
// Single-expression mappings
fun statusMarker(status: String): String = when (status) {
    "pending" -> "[ ]"
    "in-progress" -> "[~]"
    "done" -> "[x]"
    "cancelled" -> "[!]"
    else -> "[?]"
}

fun priorityLabel(priority: String): String = when (priority) {
    "H" -> "High"
    "M" -> "Medium"
    "L" -> "Low"
    else -> "Unknown"
}

// Compose with default arguments and named arguments
fun printTask(
    index: Int,
    description: String,
    status: String = "pending",
    priority: String = "M"
) {
    val marker = statusMarker(status)
    val label = priorityLabel(priority)
    println("$marker ($label) ${index + 1}. $description")
}

// Multi-step function
fun printSummary(total: Int, doneCount: Int) {
    val pct = if (total == 0) 0.0 else (doneCount.toDouble() / total) * 100.0
    println("Total: $total, Done: $doneCount (${"%.1f".format(pct)}%)")
}

fun main() {
    println("=== Catatku Task Demo ===")
    
    // Use defaults
    printTask(0, "Pay rent")
    
    // Override one parameter by name
    printTask(1, "Finish Kotlin course", priority = "H")
    
    // Override multiple parameters
    printTask(2, "Call dentist", status = "done", priority = "L")
    
    // Use positional arguments
    printTask(3, "Walk the dog", "in-progress", "M")
    
    println()
    printSummary(total = 4, doneCount = 1)
}
```

Save and run.

### Step 2: Read the Output

The output is:

```text
=== Catatku Task Demo ===
[ ] (Medium) 1. Pay rent
[ ] (High) 2. Finish Kotlin course
[x] (Low) 3. Call dentist
[~] (Medium) 4. Walk the dog

Total: 4, Done: 1 (25.0%)
```

Walk through what each piece contributed. The first call to `printTask` provides only the index and description; the status and priority take their defaults ("pending" and "M"). The second call adds `priority = "H"` by name, leaving status as the default. The third call overrides both status and priority by name. The fourth call uses positional arguments for both. Each call demonstrates a different combination of default and explicit arguments.

The `printSummary` function is the multi-step kind; it has two parameters and a body that computes a percentage and formats output. The format string `"%.1f".format(pct)` is a string method that produces a formatted decimal number with one digit after the decimal point. We have not covered string formatting in detail, but you can read this as "format the percentage with one decimal place".

The named arguments at the `printSummary` call site (`total = 4, doneCount = 1`) make the meaning clear without anyone having to look up the function signature. This is a small but real benefit: code that reads naturally without cross-referencing.

### Step 3: Modify and Re-Run

Try a few variations. Add a fifth `printTask` call with all four arguments. Change the default values in the function signature and observe how the calls that did not specify those parameters change. Add another helper function (like `printHeader(title: String)`) and use it. Each variation reinforces a piece of the function machinery.

The point of this kind of experimentation is not to memorize syntax but to build a sense of how the pieces compose. Once you have used named arguments three or four times, you stop having to think about the syntax and just reach for them when they would help. Same with default arguments, single-expression functions, and the rest of the toolkit. Fluency comes from use, not from study.

---

## 8. Fix the Errors in Your Code

Three function-related mistakes are common in early Kotlin code.

**Error 1: Leaving out parameter types**

```kotlin
// Wrong
fun add(a, b) {
    return a + b
}

fun main() {
    println(add(2, 3))
}

// Correct
fun add(a: Int, b: Int): Int {
    return a + b
}

fun main() {
    println(add(2, 3))
}
```

Function parameter types are required and never inferred. For the wrong version the compiler reports `A type annotation is required on a value parameter.` for both `a` and `b`, followed by a long list of `plus` candidates because it cannot tell what `a + b` should mean. The fix is to add explicit types: `fun add(a: Int, b: Int): Int`, after which the program prints `5`. Kotlin's type system is precise about what it can and cannot infer; parameters fall into the "cannot" bucket because the compiler does not try to derive a parameter's type from how the body uses it. As a habit, write the type next to the parameter name automatically.

**Error 2: Returning a value without declaring a return type**

```kotlin
// Wrong
fun double(value: Int) {
    return value * 2
}

fun main() {
    println(double(4))
}

// Correct
fun double(value: Int): Int {
    return value * 2
}

fun main() {
    println(double(4))
}
```

A function with a block body and no declared return type returns `Unit`. If the body uses `return` with a value, the compiler complains: `Return type mismatch: expected 'kotlin.Unit', actual 'kotlin.Int'.` The fix is to add the explicit return type, `fun double(value: Int): Int`, and the program prints `8`. As a defensive habit, always write the return type when the function returns something, even though single-expression functions can infer it. The signature becomes self-documenting and the compiler catches mismatches between what you said and what you wrote.

**Error 3: Putting a positional argument in the wrong slot after a named one**

```kotlin
// Wrong
fun describeTask(description: String, priority: String, isDone: Boolean) {
    println("$description ($priority), done: $isDone")
}

fun main() {
    describeTask(priority = "H", "Pay rent", isDone = true)
}

// Correct
fun describeTask(description: String, priority: String, isDone: Boolean) {
    println("$description ($priority), done: $isDone")
}

fun main() {
    describeTask("Pay rent", priority = "H", isDone = true)
}
```

Kotlin lets you mix named and positional arguments only while every positional argument still sits in its own position. In the wrong version, `priority = "H"` fills the first slot by name, so the positional `"Pay rent"` no longer lines up with `description`, and the compiler reports `No value passed for parameter 'description'.` The fix is to either name everything (`describeTask(description = "Pay rent", priority = "H", isDone = true)`) or to put the positional arguments first, as the correct version does; it prints `Pay rent (H), done: true`. The positional-first style is more common because it is shorter while still being clear; naming everything is good when you want every argument to be self-documenting.

---

## 9. Exercises

These exercises practice declaring and using functions.

**Exercise 1:** Write a single-expression function `isPassing(score: Int): Boolean` that returns `true` if the score is at least 60, `false` otherwise. Test it from `main` with a few different scores using `println`.

**Exercise 2:** Write a function `formatTask(description: String, priority: String = "Medium", isDone: Boolean = false): String` that returns a formatted string suitable for printing. Test it with several combinations of arguments, using named arguments for clarity. Note that this function returns the formatted string rather than printing it.

**Exercise 3:** Refactor the following code into a named helper function. The original code is in `main`:

```kotlin
fun main() {
    val a = 10
    val b = 20
    val c = 30
    val avg = (a + b + c).toDouble() / 3.0
    println("Average: $avg")
    
    val x = 5
    val y = 7
    val z = 9
    val avg2 = (x + y + z).toDouble() / 3.0
    println("Average: $avg2")
}
```

Define a function `average` that takes three integers and returns their average as a `Double`. Use it in `main` to replace the duplicated calculation.

---

## 10. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

The check is a single comparison, so the function fits naturally in the single-expression form.

```kotlin
fun isPassing(score: Int): Boolean = score >= 60

fun main() {
    println("45 passing: ${isPassing(45)}")
    println("60 passing: ${isPassing(60)}")
    println("92 passing: ${isPassing(92)}")
}
```

Save and run. Output:

```text
45 passing: false
60 passing: true
92 passing: true
```

The expression `score >= 60` already produces a `Boolean`, so the function body is just that comparison; there is no need for `if (score >= 60) true else false`. Testing the boundary value 60 is a good habit, because "at least 60" means 60 itself must pass, and an accidental `>` instead of `>=` would only show up at that exact value.

**Solution for Exercise 2:**

The function builds a string from its parameters and returns it, leaving the printing to the caller.

```kotlin
fun formatTask(description: String, priority: String = "Medium", isDone: Boolean = false): String {
    val marker = if (isDone) "[x]" else "[ ]"
    return "$marker ($priority) $description"
}

fun main() {
    println(formatTask("Pay rent"))
    println(formatTask("Finish Kotlin course", priority = "High"))
    println(formatTask("Call dentist", isDone = true))
    println(formatTask(description = "Walk the dog", priority = "Low", isDone = true))
}
```

Save and run. Output:

```text
[ ] (Medium) Pay rent
[ ] (High) Finish Kotlin course
[x] (Medium) Call dentist
[x] (Low) Walk the dog
```

The first call relies on both defaults, so the task is medium priority and not done. The second call overrides only `priority` by name. The third call skips `priority` entirely and sets `isDone` by name, which is only possible because named arguments let you jump over a parameter that has a default. The last call names every argument, which reads like a small sentence. Because `formatTask` returns a `String` instead of printing, the same function could later feed a file writer or a test, not just the console.

**Solution for Exercise 3:**

This exercise practices the most fundamental refactoring move: identifying duplicated code and extracting it into a named function. The duplication in the original was the `(... + ... + ...).toDouble() / 3.0` pattern, which appears twice with different inputs. Pulling it into a function means the formula lives in one place and either set of inputs uses the same code.

```kotlin
fun average(a: Int, b: Int, c: Int): Double = (a + b + c).toDouble() / 3.0

fun main() {
    val avg1 = average(10, 20, 30)
    println("Average: $avg1")
    
    val avg2 = average(5, 7, 9)
    println("Average: $avg2")
}
```

Save and run. Output:

```text
Average: 20.0
Average: 7.0
```

The function uses a single-expression body because the calculation is one expression. The return type is `Double` because the calculation produces a floating-point result (the `.toDouble()` makes the division produce a `Double` rather than an `Int`).

The refactor makes several improvements visible. The formula is in one place, so a bug in the formula is fixed in one place. The intent of each call site is clearer: `average(10, 20, 30)` says explicitly that we are computing an average, while `(a + b + c).toDouble() / 3.0` requires the reader to recognize the pattern. New code can use `average` without having to reinvent the formula. If we later decide to change the formula (perhaps to use a different rounding, or to handle empty inputs differently), we change it in one place rather than searching the whole codebase.

This kind of refactor (extract function, replace duplications with calls) is one of the most common refactorings in real software development, and Kotlin's lightweight function syntax makes it cheap to do. Every time you see the same calculation appearing twice, ask whether it deserves a name. Often the answer is yes, and the resulting code is easier to read and easier to change.

A more idiomatic generalization would let `average` work on any number of integers using `vararg` or a `List<Int>` parameter:

```kotlin
fun average(vararg numbers: Int): Double = numbers.sum().toDouble() / numbers.size

fun main() {
    println(average(10, 20, 30))
    println(average(5, 7, 9))
    println(average(1, 2, 3, 4, 5))
}
```

Save and run. Output:

```text
20.0
7.0
3.0
```

The `vararg numbers: Int` declares that the function accepts any number of `Int` arguments, which inside the function appear as an `IntArray` named `numbers`. This is the same as Java's `int...` syntax. We will not use `vararg` heavily in this course, but seeing it here illustrates that Kotlin functions can accept variable numbers of arguments when the situation calls for it. The standard library uses `vararg` for functions like `listOf` (which takes any number of elements) and `arrayOf`.

---

## 11. Understanding the Function-First Style

Kotlin's emphasis on lightweight functions is one of the differences that gives it a different feel from Java. In Java, the natural unit of organization is the class: every function lives inside a class, every utility goes into a `static` method on a `Utils` class, and even simple helpers carry the weight of their enclosing class. In Kotlin, functions are first-class citizens at every level: they can be top-level (no class needed), they can be members of classes, they can be nested inside other functions (covered briefly in Lesson 13), they can be stored in variables, and they can be passed around as values. This shift from "everything is a class" to "functions are primary, classes when needed" produces a different style of code.

The practical effect is that you reach for functions more often. When a piece of logic could be a method on a class or a top-level function, the top-level function is often clearer because it does not require inventing a class to hold it. When you need to extract a small computation, you write a function rather than a static method. When you compose code, you compose functions rather than building elaborate object hierarchies. The result is code that reads more like a series of small named operations rather than like a graph of objects calling each other.

This style is sometimes called "functional" or "function-first" programming, and it has benefits beyond just looking cleaner. Small named functions are easier to test in isolation: you give them inputs and check the outputs, with no setup required. They are easier to reason about: each function has a clear input-output contract that you can hold in your head. They compose naturally: a function that takes a list and returns a list can feed into another function that takes a list, and the chain of operations is explicit. The functional collection methods we will see in Lesson 13 (`filter`, `map`, `reduce`) are pure expressions of this idea, but the foundation is built throughout the language: top-level functions, single-expression functions, expression-form control flow, and the discouragement of mutable state via `val`.

The cost is a small mindset shift if you are coming from Java. Kotlin does not push you to write classes for every small concept the way Java does, and at first the absence of classes can feel like missing structure. With practice, you realize that classes are still there when they help and absent when they would just be ceremony, which is the right tradeoff. Many experienced Kotlin programmers report that they write fewer classes than they did in Java, and the classes they do write are smaller and more focused. The codebase ends up flatter and easier to navigate.

A related observation is that this style scales. For a tiny program, the difference between Kotlin and Java might just be a few lines. For a large program, the savings compound: thousands of lines of "class wrapping a single static method" boilerplate vanish, and the actual logic is more visible. Anyone who has worked on large Java codebases knows the pain of `Utils` classes that grow into 5000-line dumping grounds; Kotlin's top-level functions in package-organized files solve this without the dumping ground.

---

## Next Up - Lesson 7

Kotlin functions are declared with `fun`, take parameters with explicit types, and optionally return values via a return type after `:`. Default arguments and named arguments together let you write functions with many parameters that are easy to call, without needing builder patterns or overload chains. Single-expression functions use `=` instead of `{ ... }` for one-line bodies, often with the return type inferred. The `Unit` type is Kotlin's name for "no useful return value" and is the implicit return type when none is specified. Top-level functions live outside any class, which is one of the small features that makes Kotlin feel lighter than Java for small utilities and helpers. You refactored the Lesson 5 example into named helpers (`statusMarker`, `priorityLabel`, `printTask`) that compose into a clean `main`, which is the everyday pattern for keeping codebases maintainable as they grow.

In Lesson 7 you will meet the most distinctive Kotlin feature: null safety. The type system tracks whether a value can be null, the compiler refuses operations that might crash on null, and a small set of operators (`?.`, `?:`, `let`) lets you handle nullable values without the verbose null checks that fill Java code.
