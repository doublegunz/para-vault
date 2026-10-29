## 1. Before You Begin

Variables are the smallest unit of state in any program. They give names to values so that the rest of your code can refer to those values, modify them, and use them in computations. Every interesting program is built up from variables, expressions that combine them, and operations that change their values over time. Understanding how variables work in Kotlin is therefore the foundation that every later lesson rests on, and the choices Kotlin makes about variables (immutable by default, strong static typing, no implicit conversions) are choices that shape the way idiomatic Kotlin code looks and feels.

This lesson covers Kotlin's two variable declaration keywords (`val` for read-only and `var` for mutable), the basic types you will use most often (numeric types, booleans, characters, strings), Kotlin's deliberate refusal to do implicit numeric conversions, and a first glimpse of the nullable type system that Lesson 7 covers in depth. By the end of the lesson you will be able to declare and use variables with confidence, you will know which type to reach for in common situations, and you will have a preview of the kind of bugs Kotlin's type system catches at compile time that other languages let through to runtime.

### What You'll Build

A series of small experiments inside `Main.kt` that exercise every aspect of variable declaration and type usage. You will declare immutable and mutable variables, observe what type inference produces in different situations, write explicit type annotations, see what happens when you try to assign across incompatible types, perform numeric conversions, and meet your first nullable variable. By the end of the lesson, the basic vocabulary of Kotlin's type system is in your head and you are ready to write code that uses it fluently.

### What You'll Learn

- ✅ The difference between `val` and `var` and when to use each
- ✅ How Kotlin's type inference picks the right type from a value
- ✅ When you need explicit type annotations versus when inference is enough
- ✅ The numeric, boolean, character, and string types and their conversion functions
- ✅ Why Kotlin refuses to do implicit numeric conversions and how to handle that

### What You'll Need

- The `catatku` Gradle project from Lessons 2 and 3, with IntelliJ IDEA open on it
- A working `Main.kt` from Lesson 3 (we will replace its contents)
- About thirty-five minutes
- Patience for typing and re-running experiments to see how each example behaves

---

## 2. The Two Variable Keywords

Kotlin has two ways to declare a variable: `val` and `var`. The choice between them determines whether the variable can be reassigned after its initial value is set. This distinction is central to Kotlin's design philosophy and shapes how idiomatic Kotlin code is written.

### Step 1: Declare a val

Replace the body of `main` in `Main.kt` with this small experiment:

```kotlin
fun main() {
    val name = "Catatku"
    println("App name: $name")
    
    // The next line would be a compile error if uncommented:
    // name = "Other name"
}
```

Save and run.

Output:

```text
App name: Catatku
```

The keyword `val` declares a read-only variable. After its initial value is set, the variable cannot be reassigned. If you uncomment the line `name = "Other name"`, the program no longer compiles, and the compiler reports `'val' cannot be reassigned.` at that line.

The error is clear and specific. The fix would be to either accept that the value is fixed, or to change the declaration from `val` to `var` if you really do need to reassign. The keyword `val` is short for "value", and the convention is to use it for any variable whose value should not change after initialization.

### Step 2: Declare a var

Now try a `var` declaration:

```kotlin
fun main() {
    var counter = 0
    println("Counter starts at: $counter")
    
    counter = counter + 1
    println("After increment: $counter")
    
    counter = 100
    println("After reassignment: $counter")
}
```

Save and run.

Output:

```text
Counter starts at: 0
After increment: 1
After reassignment: 100
```

The keyword `var` declares a mutable variable. You can reassign it as many times as you want, and each new value replaces the old one. The keyword is short for "variable", which captures the idea that the value can vary over time. We used `counter = counter + 1` as a way to show explicit reassignment, but Kotlin also has the shorthand `counter += 1` that you will see in real code.

### When to Use Each

The rule of thumb is simple: prefer `val` whenever possible. Use `var` only when you genuinely need to reassign the variable later. This advice sounds restrictive but is genuinely good practice for several reasons.

First, immutable variables are easier to reason about. When you see `val x = 10` and then look at code that uses `x`, you do not have to wonder whether some line in between changed `x`'s value; the compiler guarantees it did not. With `var`, you have to trace through every place the variable might be reassigned to know what its current value is, which adds mental overhead with every line of code.

Second, immutable variables prevent a class of bugs related to accidental reassignment. If you write a hundred-line function that uses `var name = "..."` near the top, you might later (accidentally or while refactoring) write `name = ...` somewhere in the middle, breaking some assumption your code was making. With `val`, the compiler would refuse that reassignment, catching the bug at compile time rather than at runtime.

Third, immutable variables are more thread-safe. We will not cover concurrency in this course, but when you do start writing multi-threaded code, immutable values are dramatically easier to share between threads safely. Kotlin's encouragement of `val` over `var` pays off enormously when you eventually move into concurrent code.

For all of these reasons, Kotlin programmers use `val` heavily and `var` sparingly. As a habit, write `val` first, and switch to `var` only when the compiler tells you that you really do need reassignment. Over time, you will find that most of your variables can be `val`, which is a sign that your code is becoming more declarative and easier to follow.

---

## 3. Type Inference and Annotations

Kotlin is a statically typed language, meaning every variable has a fixed type that the compiler knows at compile time. But Kotlin uses type inference, so you usually do not have to write the type out explicitly. The compiler figures out the type from the initial value.

### Step 1: Watch Type Inference at Work

Try declaring several variables with different types and let Kotlin infer them:

```kotlin
fun main() {
    val name = "Catatku"        // inferred as String
    val count = 42              // inferred as Int
    val price = 19.99           // inferred as Double
    val isReady = true          // inferred as Boolean
    val initial = 'C'           // inferred as Char
    
    println("name: $name")
    println("count: $count")
    println("price: $price")
    println("isReady: $isReady")
    println("initial: $initial")
}
```

Save and run.

Output:

```text
name: Catatku
count: 42
price: 19.99
isReady: true
initial: C
```

Each variable was declared without writing a type. The compiler examined the value on the right side and inferred the type. A double-quoted string literal becomes `String`. A whole number literal becomes `Int` (the default integer type). A literal with a decimal point becomes `Double` (the default floating-point type). The literal `true` or `false` becomes `Boolean`. A single-quoted character literal becomes `Char`.

You can confirm the inferred types by hovering over each variable in IntelliJ; the IDE shows a tooltip with the type. This is one of the small pleasures of working in IntelliJ: you can ask the compiler what it thinks the type is at any point, which makes type inference feel less mysterious.

### Step 2: Add Explicit Type Annotations

Sometimes you want to write the type explicitly, either for clarity or because the compiler cannot infer the type from context. The syntax is `val name: Type = value`, with a colon between the variable name and the type.

```kotlin
fun main() {
    val name: String = "Catatku"
    val count: Int = 42
    val price: Double = 19.99
    val isReady: Boolean = true
    val initial: Char = 'C'
    
    println("All explicit annotations work the same as inferred ones.")
}
```

Save and run.

Output:

```text
All explicit annotations work the same as inferred ones.
```

The behavior is identical to the inferred version; the explicit annotations just make the types visible in the source code. Most idiomatic Kotlin omits annotations when they can be inferred and includes them when they add clarity. For example, in a function signature you usually annotate the return type explicitly, even if it could be inferred, because it documents the function's contract for readers.

### Step 3: When You Must Annotate

There are situations where the compiler cannot infer the type, and you must provide an annotation. The most common is declaring a variable without an initial value:

```kotlin
fun main() {
    // val x  // error: must either have a type annotation or be initialized
    val x: Int  // ok, but x cannot be used until assigned
    
    var y: String  // declared without initialization
    y = "hello"
    println(y)
}
```

Save and run.

Output:

```text
hello
```

If you uncomment the first line, the compiler reports `This variable must either have a type annotation or be initialized.`

When a variable is declared without an initializer, the compiler has no value to inspect for type inference, so an annotation is required. This pattern is more common with `var` than `val` because `val` variables typically get their value at the declaration site. We will see this pattern come up rarely; in everyday code, you almost always have an initial value and inference works fine.

A subtler situation is when you want a different type than what inference would give you. For example, an integer literal is inferred as `Int` by default, but maybe you want a `Long`:

```kotlin
fun main() {
    val small = 42         // Int (32-bit)
    val large: Long = 42   // Long (64-bit)
    val largeAlt = 42L     // Long, using the L suffix
    
    println("small: $small, large: $large, largeAlt: $largeAlt")
}
```

Save and run.

Output:

```text
small: 42, large: 42, largeAlt: 42
```

All three print the same digits, because the difference is in the type, not in the value.

The explicit annotation `: Long` overrides the default inference of `Int`. Alternatively, the literal suffix `L` makes the literal itself a `Long`. Both approaches work; the annotation is clearer when the type is the important thing, while the suffix is briefer when the value is the focus. You will see both styles in real code.

---

## 4. The Numeric Types

Kotlin has six numeric types: four integers (`Byte`, `Short`, `Int`, `Long`) and two floating-point (`Float`, `Double`). Each has a fixed size in memory and a fixed range of values it can represent. Picking the right type is mostly about matching your needs for size and precision.

### Step 1: The Integer Types

The four integer types differ in how many bits they use and consequently the range of values they can hold. `Byte` is 8 bits and holds values from -128 to 127. `Short` is 16 bits and holds values from -32768 to 32767. `Int` is 32 bits and holds values from roughly -2.1 billion to +2.1 billion. `Long` is 64 bits and holds values up to about 9.2 quintillion in either direction.

For everyday code you almost always use `Int`. It is the default integer type, and its range is large enough for almost any counting or indexing you will do. `Long` becomes necessary when you need to represent very large numbers, like timestamps in milliseconds, file sizes for huge files, or unique identifiers from a system that uses 64-bit IDs. `Byte` and `Short` are rarely used in application code; they exist mostly for low-level work like reading binary file formats or interfacing with hardware.

Try this small example:

```kotlin
fun main() {
    val tinyNumber: Byte = 100
    val smallNumber: Short = 30000
    val regularNumber: Int = 1_000_000
    val bigNumber: Long = 9_000_000_000L
    
    println("tiny: $tinyNumber")
    println("small: $smallNumber")
    println("regular: $regularNumber")
    println("big: $bigNumber")
}
```

Save and run.

Output:

```text
tiny: 100
small: 30000
regular: 1000000
big: 9000000000
```

Notice the underscores in `1_000_000` and `9_000_000_000L`. Kotlin allows underscores in numeric literals as visual separators; they are ignored by the compiler. Using them for thousands separators makes large numbers much easier to read at a glance. The `L` suffix on `9_000_000_000L` is required because that value is larger than the maximum `Int`; without the suffix the compiler would refuse to fit it into an `Int`.

### Step 2: The Floating-Point Types

Kotlin has two floating-point types: `Float` (32 bits, single precision) and `Double` (64 bits, double precision). Floating-point numbers represent values with fractional parts, like 3.14 or 0.001. The two types differ in precision: `Double` can represent more digits before rounding errors creep in.

For everyday code you almost always use `Double`. It is the default floating-point type and has enough precision for most calculations. `Float` is rarely needed except for memory-intensive applications like graphics or scientific computing where you have millions of numbers and the memory savings matter.

```kotlin
fun main() {
    val pi = 3.14159              // Double by default
    val e: Float = 2.71828F       // Float, using F suffix
    val little = 0.00001
    val tiny = 1.5e-10            // scientific notation, Double
    
    println("pi: $pi")
    println("e: $e")
    println("little: $little")
    println("tiny: $tiny")
}
```

Save and run.

Output:

```text
pi: 3.14159
e: 2.71828
little: 1.0E-5
tiny: 1.5E-10
```

The `F` suffix on `2.71828F` makes it a `Float` rather than a `Double`. Scientific notation like `1.5e-10` is parsed as `Double`. Notice that very small numbers print in scientific notation by default; if you want a specific format, Kotlin has formatting helpers we will not cover in this lesson.

A small caution about floating-point: these types cannot represent all decimal numbers exactly. For example, `0.1 + 0.2` produces `0.30000000000000004` rather than exactly `0.3` because of how binary floating-point representation works. This is universal across all programming languages that use IEEE 754 floating-point (which is essentially all of them). For financial calculations where exact decimal arithmetic matters, you would use `BigDecimal` from the Java standard library. For Catatku and most application code, `Double` is fine.

### Step 3: Arithmetic and Common Operations

Numeric types support the usual arithmetic operators: `+`, `-`, `*`, `/`, and `%` (modulo). They also have many useful methods like `toString`, `toInt`, `toDouble`, `compareTo`, and so on. Try a few:

```kotlin
fun main() {
    val a = 17
    val b = 5
    
    println("$a + $b = ${a + b}")
    println("$a - $b = ${a - b}")
    println("$a * $b = ${a * b}")
    println("$a / $b = ${a / b}")           // integer division
    println("$a % $b = ${a % b}")           // remainder
    println("$a / $b (as double) = ${a.toDouble() / b}")
}
```

Save and run.

Output:

```text
17 + 5 = 22
17 - 5 = 12
17 * 5 = 85
17 / 5 = 3
17 % 5 = 2
17 / 5 (as double) = 3.4
```

Two things to note. First, integer division (`/` between two `Int` values) discards the remainder, so `17 / 5` is `3`, not `3.4`. To get the fractional result, at least one operand must be a floating-point type, hence `a.toDouble() / b` produces `3.4`. Second, the `%` operator is the modulo (remainder after division), which is useful for things like checking whether a number is even (`x % 2 == 0`) or wrapping around (`(i + 1) % 7` for cycling through days of the week).

---

## 5. Booleans, Characters, and Strings

Beyond numbers, the other basic types you use every day are `Boolean`, `Char`, and `String`. We have already touched on each of them in passing; this section gives them a more careful look.

### Step 1: Booleans

A `Boolean` is a simple type with exactly two values: `true` and `false`. They are used in conditional logic and as the result of comparison operators.

```kotlin
fun main() {
    val isReady = true
    val isComplete = false
    
    val a = 10
    val b = 20
    val isLess = a < b
    val isEqual = a == b
    
    println("isReady: $isReady")
    println("isComplete: $isComplete")
    println("isLess: $isLess")
    println("isEqual: $isEqual")
    
    val both = isReady && !isComplete    // logical AND, NOT
    val either = isReady || isComplete   // logical OR
    println("both: $both")
    println("either: $either")
}
```

Save and run.

Output:

```text
isReady: true
isComplete: false
isLess: true
isEqual: false
both: true
either: true
```

Three operators work on booleans: `&&` (logical AND, true if both operands are true), `||` (logical OR, true if either operand is true), and `!` (logical NOT, flips the value). The comparison operators (`<`, `>`, `<=`, `>=`, `==`, `!=`) produce `Boolean` results from numeric or other comparable values.

Kotlin's booleans are strict: you cannot use a number as a boolean the way you might in JavaScript or Python. Writing `if (5)` is a compile error in Kotlin (the condition must be `Boolean`, not `Int`). This strictness prevents a class of bugs where a value's "truthiness" depends on subtle rules. If you want to check whether a number is non-zero, you write `if (count != 0)` explicitly, which is both clearer to read and harder to misuse.

### Step 2: Characters

A `Char` is a single character, written with single quotes: `'A'`, `'7'`, `'!'`, `' '` (a space). Internally, a `Char` is a 16-bit value that holds a Unicode code unit, which means most characters from most writing systems can be stored in a single `Char`. Some less common characters (emoji, certain Asian scripts) require two `Char` values to represent, which becomes relevant for advanced text processing but rarely matters in application code.

```kotlin
fun main() {
    val grade: Char = 'A'
    val digit: Char = '7'
    val newline: Char = '\n'
    val tab: Char = '\t'
    val backslash: Char = '\\'
    val unicode: Char = '\u00E9'    // é
    
    println("grade: $grade")
    println("digit: $digit")
    println("newline char value (as Int): ${newline.code}")
    println("unicode: $unicode")
}
```

Save and run.

Output:

```text
grade: A
digit: 7
newline char value (as Int): 10
unicode: é
```

Several things to notice. Special characters use escape sequences: `\n` is a newline, `\t` is a tab, `\\` is a literal backslash, `\'` is a literal single quote inside a `Char` literal, and `\"` is a literal double quote inside a `String` literal. Unicode characters can be specified with `\u` followed by four hex digits, like `\u00E9` for é.

The `.code` property of a `Char` gives you its numeric Unicode value as an `Int`, which is occasionally useful for character arithmetic or for reading character codes from binary data.

### Step 3: Strings

A `String` is a sequence of characters, written with double quotes. We have used strings throughout the course already, but a few additional features are worth knowing.

```kotlin
fun main() {
    val greeting = "Hello, Catatku!"
    
    println("Length: ${greeting.length}")
    println("First char: ${greeting[0]}")
    println("Last char: ${greeting[greeting.length - 1]}")
    println("Uppercase: ${greeting.uppercase()}")
    println("Lowercase: ${greeting.lowercase()}")
    println("Contains 'Cat': ${greeting.contains("Cat")}")
    println("Length of trimmed '  hello  ': ${"  hello  ".trim().length}")
}
```

Save and run.

Output:

```text
Length: 15
First char: H
Last char: !
Uppercase: HELLO, CATATKU!
Lowercase: hello, catatku!
Contains 'Cat': true
Length of trimmed '  hello  ': 5
```

Strings have a `.length` property, can be indexed with `[i]` to get individual characters, and have many methods like `uppercase`, `lowercase`, `contains`, `trim`, `startsWith`, `endsWith`, `replace`, and `split`. The full list is in the Kotlin standard library documentation, and IntelliJ's autocomplete will show you the available methods when you type `.` after a string.

Kotlin also supports multi-line string literals, called raw strings, written with triple quotes:

```kotlin
fun main() {
    val message = """
        Welcome to Catatku!
        This is a multi-line
        message that preserves
        line breaks exactly.
    """.trimIndent()
    
    println(message)
}
```

Save and run.

Output:

```text
Welcome to Catatku!
This is a multi-line
message that preserves
line breaks exactly.
```

Raw strings are useful for blocks of text where you want exact formatting: SQL queries, help text, file templates, and so on. The `.trimIndent()` call at the end removes the common leading whitespace from each line, which lets you indent the string in source code while keeping the output unindented. We will use raw strings in Lesson 18 for printing usage messages.

---

## 6. Conversions Between Types

Kotlin is strict about type conversions: it does not perform implicit conversions between numeric types, even when the conversion would lose no information. This catches a class of bugs that appear in languages like C and Java where integer types silently widen or narrow.

### Step 1: Try an Implicit Conversion

What happens if you try to assign an `Int` to a `Long` variable without an explicit conversion?

```kotlin
fun main() {
    val small: Int = 42
    // val big: Long = small  // error: type mismatch
    val big: Long = small.toLong()  // ok, explicit conversion
    
    println("big: $big")
}
```

Save and run.

Output:

```text
big: 42
```

The commented line `val big: Long = small` does not compile. Kotlin refuses the implicit conversion from `Int` to `Long`, even though every `Int` value fits in a `Long` and there is no information lost. You must call `.toLong()` explicitly to perform the conversion.

This strictness might seem pedantic, but it is deliberate. In Java, implicit conversions can hide bugs: a piece of code might silently convert from `Int` to `Long`, then back to `Int`, and along the way an arithmetic operation could overflow without anyone noticing. Kotlin's "no implicit conversions" rule means every conversion is visible in the source, which makes it harder for these subtle bugs to slip through.

### Step 2: Use the Conversion Functions

Every numeric type has methods named `toInt`, `toLong`, `toDouble`, `toFloat`, `toByte`, `toShort`, `toChar`, and `toString` for converting to other types.

```kotlin
fun main() {
    val pi = 3.14159
    val rounded = pi.toInt()       // truncates toward zero, gives 3
    val asLong = pi.toLong()
    
    val count = 42
    val asDouble = count.toDouble()
    val asString = count.toString()
    
    println("rounded: $rounded")
    println("asLong: $asLong")
    println("asDouble: $asDouble")
    println("asString: '$asString' (length ${asString.length})")
}
```

Save and run.

Output:

```text
rounded: 3
asLong: 3
asDouble: 42.0
asString: '42' (length 2)
```

Notice that `pi.toInt()` truncates to 3 rather than rounding to 3 (which would give 3 as well in this case, but if the value were 3.7 then truncation gives 3 while rounding would give 4). To round explicitly, use `Math.round(pi)` or `pi.roundToInt()`. The choice between truncation and rounding is yours, but you have to make it explicitly; Kotlin will not pick a default for you.

### Step 3: Parse Strings to Numbers

A common conversion is parsing a string into a number, which we will need in Lesson 18 when Catatku reads task ids from the command line.

```kotlin
fun main() {
    val input = "42"
    val parsed = input.toInt()
    println("parsed: $parsed")
    
    val bad = "hello"
    // val crash = bad.toInt()  // throws NumberFormatException at runtime
    val safe = bad.toIntOrNull()  // returns null instead of throwing
    println("safe: $safe")
}
```

Save and run.

Output:

```text
parsed: 42
safe: null
```

Two methods exist: `toInt` throws an exception if the string is not a valid integer, while `toIntOrNull` returns `null` instead. The "OrNull" variants are useful when you want to handle parse failures gracefully without exception handling. We will use `toIntOrNull` heavily in Lesson 18 for command-line argument parsing.

---

## 7. A Glimpse of Nullable Types

Lesson 7 covers null safety in detail, but you should meet nullable types here so they are not surprising when they appear in later examples.

### Step 1: Try to Assign null

Try assigning `null` to a regular variable:

```kotlin
fun main() {
    // val name: String = null  // error: null cannot be a value of a non-null type String
    val name: String? = null    // ok, the ? makes it nullable
    println("name: $name")
}
```

Save and run.

Output:

```text
name: null
```

The commented line does not compile: the compiler reports `Null cannot be a value of a non-null type 'kotlin.String'.` By default in Kotlin, no variable can hold `null`. To allow `null`, you have to opt in by writing the type with a `?` suffix: `String?` instead of `String`. The `?` is part of the type, and the type system tracks the difference everywhere.

### Step 2: See What Nullability Affects

Once a variable is nullable, you cannot use it the same way as a non-null variable:

```kotlin
fun main() {
    val nonNullName: String = "Catatku"
    val nullableName: String? = "Maybe"
    
    println(nonNullName.length)         // ok, nonNullName cannot be null
    // println(nullableName.length)     // error: must handle null possibility
    println(nullableName?.length)       // ok, ?. returns null if nullableName is null
    
    val anotherNullable: String? = null
    println(anotherNullable?.length)    // prints "null"
}
```

Save and run.

Output:

```text
7
5
null
```

The line `nullableName.length` is a compile error (the compiler reports `Only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'kotlin.String?'.`) because the compiler does not know whether `nullableName` is null at that point; calling `.length` on null would crash. The `?.` operator (called the safe-call operator) handles the null case for you: if the receiver is non-null, it calls the method or accesses the property normally; if the receiver is null, the whole expression evaluates to null.

This is the core of Kotlin's null safety story: nullability is part of the type, the compiler tracks it, and operations that would crash on null are caught at compile time. We will spend an entire lesson on this in Lesson 7, and you will see it appear regularly in the lessons in between as a hint that the full story is coming. For now, just notice that the two types `String` and `String?` are different in Kotlin's eyes, and the `?.` operator is how you safely work with the nullable form.

---

## 8. Run and Test

Combine everything you have learned in this lesson into one program that exercises every concept.

### Step 1: Build the Combined Example

Replace the contents of `Main.kt` with this comprehensive demonstration:

```kotlin
fun main() {
    // Immutable variables (val) for things that should not change
    val appName = "Catatku"
    val version = "0.1.0"
    val maxTasks: Int = 100
    val taskMultiplier = 1.5
    val isReady = true
    
    // Mutable variable (var) for state that changes
    var taskCount = 0
    
    // String operations
    println("Welcome to ${appName.uppercase()} v$version")
    println("Max tasks supported: $maxTasks")
    
    // Numeric arithmetic
    val capacity = (maxTasks * taskMultiplier).toInt()
    println("Adjusted capacity: $capacity")
    
    // Increment a mutable variable
    taskCount = taskCount + 1
    println("After adding first task, count is: $taskCount")
    taskCount += 1  // shorthand
    println("After adding second task, count is: $taskCount")
    
    // Boolean logic
    val canAddMore = taskCount < maxTasks && isReady
    println("Can add more tasks: $canAddMore")
    
    // Conversion and parsing
    val countAsString = taskCount.toString()
    val parsedBack = countAsString.toIntOrNull() ?: 0
    println("Round-trip through string: $parsedBack")
    
    // A nullable preview
    val maybeUser: String? = if (isReady) "Reader" else null
    println("Hello, ${maybeUser ?: "anonymous"}!")
}
```

Save and run.

### Step 2: Read the Output

The program prints one line per experiment.

Output:

```text
Welcome to CATATKU v0.1.0
Max tasks supported: 100
Adjusted capacity: 150
After adding first task, count is: 1
After adding second task, count is: 2
Can add more tasks: true
Round-trip through string: 2
Hello, Reader!
```

Walk through what each piece contributed. The first line uses `appName.uppercase()` to convert to uppercase and string templates to combine with `version`. The capacity calculation multiplies an `Int` by a `Double`, producing a `Double`, which we then convert back to `Int` with `.toInt()`. The `taskCount` increments first with `=` and then with `+=`, both of which work on the same `var`. The boolean `canAddMore` combines a comparison and a boolean variable with `&&`.

The `countAsString` line converts an `Int` to a `String`, and `parsedBack` converts back, using `?: 0` as a fallback in case parsing returned `null` (it will not in this case, but the `?:` operator is good practice). The final line shows a nullable variable that gets a default value via the same `?:` operator (called the Elvis operator, which we will see again in Lesson 7).

### Step 3: Experiment

Try a few small modifications. Change `isReady` to `false` and rerun; the last line should change to "Hello, anonymous!" because the nullable would become null. Change `maxTasks` to a larger or smaller number and watch the calculations adjust. Add more `taskCount += 1` lines to push the count higher and see how `canAddMore` reacts. Each modification confirms a small piece of your model of how the code works, which is exactly what you want as you build fluency.

---

## 9. Fix the Errors in Your Code

Three variable-related mistakes are common.

**Error 1: Reassigning a val**

```kotlin
// Wrong
fun main() {
    val name = "Catatku"
    name = "Other"
    println(name)
}

// Correct
fun main() {
    var name = "Catatku"
    name = "Other"
    println(name)
}
```

A `val` is read-only after initialization, so the wrong version stops with `'val' cannot be reassigned.` The fix is to either change the declaration to `var` if reassignment is genuinely needed (as in the correct version), or to keep the `val` and store the new value in a second variable with a different name. As a habit, try `val` first; the moment the compiler complains about reassignment, ask whether you really need the variable to change.

**Error 2: Mixing Numeric Types Without a Conversion**

```kotlin
// Wrong
fun main() {
    val count = 5
    val rate: Long = count
    println(rate)
}

// Correct
fun main() {
    val count = 5
    val rate: Long = count.toLong()
    println(rate)
}
```

Kotlin does not implicitly convert between numeric types. The wrong version fails with `Initializer type mismatch: expected 'kotlin.Long', actual 'kotlin.Int'.` The fix is to add the explicit conversion with `.toLong()`. This catches bugs that languages with implicit widening let through silently. The cost is a tiny bit more typing; the benefit is precise control over every numeric conversion in your program.

**Error 3: Storing a Nullable Result in a Non-Null Variable**

```kotlin
// Wrong
fun main() {
    val taskId: Int = "42abc".toIntOrNull()
    println(taskId)
}

// Correct
fun main() {
    val taskId: Int = "42abc".toIntOrNull() ?: 0
    println(taskId)
}
```

`toIntOrNull` returns `Int?`, because the text might not be a valid number. Assigning it to an `Int` variable fails with `Initializer type mismatch: expected 'kotlin.Int', actual 'kotlin.Int?'.` because the non-null type cannot hold `null`. The fix is either to change the variable type to `Int?` (accepting that it might be null and dealing with that later), or to provide a default with `?:`, as in the correct version, which prints `0` because `"42abc"` is not a number. Lesson 7 covers this in much more depth; for now, just notice that the type system catches these "this might be null" cases at compile time.

---

## 10. Exercises

These exercises practice variable declaration and the basic types.

**Exercise 1:** Declare three variables for a small product description: a name (String), a price (Double), and an in-stock flag (Boolean). Use `val` because none of them change. Print a single line summarizing the product, like "Widget costs 19.99, in stock: true".

**Exercise 2:** Write a small program that converts a temperature from Celsius to Fahrenheit. Use the formula `F = C * 9.0 / 5.0 + 32.0`. Declare the Celsius value as a `val`, compute the Fahrenheit value as another `val`, and print both with appropriate labels. Try changing the Celsius value and rerunning to confirm the formula works.

**Exercise 3:** Demonstrate the difference between `val` and `var` by writing a short program where a `val` holds a constant tax rate (0.10) and a `var` holds a running total. Add three different prices to the running total (using `+=`), then compute the total with tax and print the result.

---

## 11. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

None of the three values change, so all three are `val`, and their types are inferred from the literals:

```kotlin
fun main() {
    val productName = "Widget"
    val price = 19.99
    val inStock = true
    println("$productName costs $price, in stock: $inStock")
}
```

Save and run.

Output:

```text
Widget costs 19.99, in stock: true
```

The literal `"Widget"` makes `productName` a `String`, `19.99` makes `price` a `Double`, and `true` makes `inStock` a `Boolean`. A single string template embeds all three values. Hover over each variable in IntelliJ IDEA to confirm the inferred types.

**Solution for Exercise 2:**

The temperature conversion exercise practices arithmetic, type inference, and string templates all together.

```kotlin
fun main() {
    val celsius = 25.0
    val fahrenheit = celsius * 9.0 / 5.0 + 32.0
    println("$celsius°C is $fahrenheit°F")
}
```

Save and run.

Output:

```text
25.0°C is 77.0°F
```

The variable `celsius` is declared with the literal `25.0`, so it is inferred as `Double`. The arithmetic `celsius * 9.0 / 5.0 + 32.0` involves only `Double` values, so the result is `Double`, which is what we want for a floating-point temperature. Using `9` and `5` instead of `9.0` and `5.0` would have caused integer division: `9 / 5` would produce `1` rather than `1.8`, and the answer would be wrong. This is a classic source of bugs in numeric code, and Kotlin's strict typing is what makes it visible: if you accidentally wrote `celsius * 9 / 5 + 32`, the result would still be wrong, but the type would still be `Double`, so you might not notice. The defensive practice is to write floating-point literals with the decimal point (`9.0`, `5.0`) when you want floating-point arithmetic, even if the value happens to be a whole number.

The output uses string templates to embed both temperatures with their units. The degree symbol `°` is just a Unicode character that Kotlin handles fine in string literals. If you wanted more formatting control (like rounding to one decimal place), you could use the `String.format` method or a string template with arithmetic to round explicitly. For this exercise, the default formatting is fine.

A useful follow-up would be to also compute the conversion in the other direction (Fahrenheit to Celsius using `C = (F - 32.0) * 5.0 / 9.0`) and print both results. This kind of "do the reverse to verify" check is a small but useful habit when working with formulas; if both directions agree, you have stronger evidence that your arithmetic is right.

**Solution for Exercise 3:**

The tax rate never changes, so it is a `val`. The running total changes three times, so it must be a `var`:

```kotlin
fun main() {
    val taxRate = 0.10
    var total = 0.0

    total += 12.50
    total += 7.25
    total += 30.00

    val totalWithTax = total * (1 + taxRate)
    println("Subtotal: $total")
    println("Total with tax: $totalWithTax")
}
```

Save and run.

Output:

```text
Subtotal: 49.75
Total with tax: 54.725
```

`total` starts at `0.0` (not `0`), so it is inferred as `Double` and can accept decimal prices; starting at `0` would make it an `Int`, and `total += 12.50` would not compile. Each `+=` adds a price to the current total and stores the result back in the same variable, which is only allowed because `total` is a `var`. The final result is a new `val`, because once computed it does not change. If you try to write `taxRate = 0.11` anywhere, the compiler stops you with `'val' cannot be reassigned.`, which is exactly the protection you want for a constant.

---

## 12. Understanding Why val Is the Default

Kotlin's preference for `val` over `var` is one of the small choices that compounds into big differences in code quality over time. Understanding why it matters helps you build the habit of reaching for `val` automatically.

The deepest reason is that immutable values are easier to reason about. When you read code that uses a `val`, you know the value is fixed; you do not have to track every line of code looking for places where it might change. When you read code that uses a `var`, you have to consider every assignment to that variable as a potential source of confusion. In a hundred-line function with five `var` declarations, the cognitive load is significantly higher than in the same function with five `val` declarations, because you have to mentally simulate the changing values rather than treating each name as a fixed reference.

A second reason is that immutable values prevent a class of bugs related to aliasing and accidental modification. If you pass a `val` reference into a function, the function cannot reassign it (and if the underlying data is also immutable, like with `data class` instances, it cannot modify the contents either). With `var`, especially `var` referring to a mutable object, function calls can have hidden side effects that are not visible at the call site. This makes code harder to test, harder to refactor, and more prone to bugs that only show up under specific timing or input conditions.

A third reason is thread safety. We are not covering concurrency in this course, but when you start writing multi-threaded code (for example with Kotlin coroutines), immutable values are safe to share across threads without locking, while mutable values are not. Code written with a `val`-first mindset transitions to concurrent code dramatically more easily than code written with `var` everywhere. Even if you never write concurrent code, the discipline of immutability makes refactoring into concurrent code possible later, which is a kind of optionality that is worth preserving.

The cost of using `val` everywhere is that some operations (like a counter that increments, or a buffer that accumulates results) genuinely require mutation. Kotlin does not require you to twist these into a functional style; `var` exists for these cases, and there is no shame in using it. The right rule is "use `val` whenever possible, and `var` when you genuinely need to reassign". Over time, you will find that most of your variables can be `val`, and the resulting code is shorter, clearer, and more reliable. This is one of the small but real reasons why experienced Kotlin programmers say their code feels more solid than the equivalent Java code.

A related observation is that `val` does not mean "deeply immutable". A `val` variable holding a `MutableList` still lets you modify the list contents through methods like `add` and `remove`; only the variable's binding is frozen. For deep immutability you also need an immutable type like `List<T>` (which is the read-only view, covered in Lesson 8). The two ideas (binding immutability with `val`, type immutability with `List<T>`) work together: a `val list: List<T>` is fully immutable, while a `var list: MutableList<T>` is mutable on both axes. Most real Kotlin code uses combinations of these, picking the level of immutability that matches the actual semantics of the data.

---

## Next Up - Lesson 5

Kotlin's variable system is built on two keywords (`val` for read-only and `var` for mutable) and a strong static type system that infers types from initial values when possible and requires explicit annotations otherwise. The numeric types come in four integer sizes (`Byte`, `Short`, `Int`, `Long`) and two floating-point sizes (`Float`, `Double`), with `Int` and `Double` as the everyday defaults. `Boolean`, `Char`, and `String` round out the basic types you use constantly. Kotlin refuses implicit numeric conversions, which catches bugs but requires you to write conversions like `.toLong()` or `.toDouble()` explicitly. Nullable types written with a trailing `?` are a preview of the null safety story that Lesson 7 will cover in depth, distinguishing types that can hold `null` from types that cannot.

In Lesson 5 you will learn control flow: if, when, for, while, and the way Kotlin treats most of these as expressions that return values rather than just statements that change program state.
