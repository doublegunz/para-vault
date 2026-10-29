## 1. Before You Begin

Every other lesson so far has introduced features that exist in some form in most modern programming languages: variables, types, conditionals, loops, functions. This lesson covers something that genuinely sets Kotlin apart from many of its peers, including Java. Null safety is the rule that the type system tracks whether a value can be null, refusing at compile time to let you call methods or access properties on values that might be null. The result is that the most common runtime crash in JVM applications, the `NullPointerException`, simply does not happen in idiomatic Kotlin code unless you go out of your way to use the unsafe escape hatch.

Tony Hoare, the computer scientist who introduced null references in the 1960s, has called null his "billion-dollar mistake" because of how much engineering time has been spent fighting null bugs across the industry over the decades since. Kotlin's response is to make nullability visible in the type system. A `String` cannot be null. A `String?` can be null but cannot be used without explicitly handling the null case. The compiler enforces this everywhere: at every assignment, every method call, every parameter pass. By the end of this lesson you will know exactly how to declare nullable values, how to safely call methods on them, how to provide fallbacks, and how to convert between nullable and non-null forms when you genuinely have proof that a value is not null. This is the conceptual centerpiece of Kotlin's type system, and getting it into your bones is what separates Kotlin written in Kotlin style from Kotlin written in Java style.

### What You'll Build

A series of small experiments inside `Main.kt` that demonstrate every aspect of null safety: declaring nullable variables, calling methods through `?.`, providing fallbacks with `?:`, doing work conditionally with `let`, and seeing how Kotlin's compiler refuses code that would crash with a null pointer exception in Java. By the end you will have written code that handles nullable values fluently and you will recognize the patterns when they appear in later lessons and in any Kotlin code you read elsewhere.

### What You'll Learn

- ✅ How `T` and `T?` differ as types
- ✅ How to read and write the safe-call operator `?.`
- ✅ How to provide defaults with the Elvis operator `?:`
- ✅ When `!!` is appropriate and why it is rarely the right choice
- ✅ How smart casts let the compiler track nullability across `if` checks

### What You'll Need

- The `catatku` Gradle project from previous lessons, with IntelliJ IDEA open
- A solid understanding of variables and functions from Lessons 4 and 6
- About forty minutes
- Patience for examples that might feel pedantic at first; the rules pay off as the lesson progresses

---

## 2. Nullable and Non-Null Types

Every type in Kotlin comes in two flavors: the non-null version that cannot hold null and the nullable version that can. The distinction is made by adding `?` to the end of the type name.

### Step 1: Try Assigning null to a Regular Variable

Open `Main.kt` and replace its contents with this experiment:

```kotlin
fun main() {
    val name: String = "Catatku"
    println("name: $name")
    
    // The next line is a compile error if uncommented:
    // val empty: String = null
}
```

Save and run. Output:

```text
name: Catatku
```

Now uncomment the `val empty: String = null` line and run again. The compiler immediately rejects it with this message:

```text
Null cannot be a value of a non-null type 'kotlin.String'.
```

The type `String` (without the `?`) means "a string that is definitely not null". The compiler refuses to put `null` into a non-null type because doing so would later let code crash when it tried to use the value. This is the first guarantee Kotlin gives you: any variable declared with a non-null type is guaranteed to hold a real value at every point where you read it.

Comment the offending line out again. We will introduce nullable types in the next step.

### Step 2: Declare a Nullable Variable

Add `?` to the type to make it nullable:

```kotlin
fun main() {
    val name: String = "Catatku"
    val maybeName: String? = null
    val anotherName: String? = "Reader"
    
    println("name: $name")
    println("maybeName: $maybeName")
    println("anotherName: $anotherName")
}
```

Save and run. Output:

```text
name: Catatku
maybeName: null
anotherName: Reader
```

The variable `maybeName` has type `String?`, which can hold either a string or null. We assigned it null, which is allowed for nullable types. The variable `anotherName` is also `String?` but holds a real string. Both are valid uses of the nullable type.

Notice that `println` happily prints null without crashing. This is because `println` accepts any value, including null, and converts it to the literal string "null". This is one of the few places in Kotlin where null is treated as a regular value; for almost every other operation, the compiler will require you to handle the null case explicitly.

### Step 3: Try to Use a Nullable Variable Like a Non-Null One

The strictness comes when you try to call a method or access a property:

```kotlin
fun main() {
    val nonNull: String = "Catatku"
    val maybeNull: String? = "Reader"
    
    println(nonNull.length)         // ok, can always call .length on a String
    // println(maybeNull.length)    // error: only safe (?.) or !! calls allowed
}
```

Save and run. Output:

```text
7
```

The line `nonNull.length` works because `nonNull` is guaranteed to be a real string; calling `.length` is safe. The commented line `maybeNull.length` is a compile error because `maybeNull` might be null, and calling `.length` on null would crash with a `NullPointerException`. Kotlin refuses the operation at compile time, which is what makes null safety effective.

Try uncommenting the line and run again. The compiler reports:

```text
Only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'kotlin.String?'.
```

The error tells you exactly what to do: use `?.` (the safe-call operator) or `!!` (the not-null assertion). The next sections cover both, with `?.` being the right choice in almost every case.

---

## 3. The Safe-Call Operator

The safe-call operator `?.` says "if the receiver is not null, call the method or access the property; if it is null, the whole expression evaluates to null". This lets you chain method calls without worrying about null propagating through and crashing.

### Step 1: Use ?. for a Single Call

Replace the body of `main` with this:

```kotlin
fun main() {
    val maybeName: String? = "Reader"
    val nullName: String? = null
    
    println(maybeName?.length)   // 6, the length of "Reader"
    println(nullName?.length)    // null, because nullName is null
    
    val maybeUpper: String? = maybeName?.uppercase()
    val nullUpper: String? = nullName?.uppercase()
    
    println(maybeUpper)          // READER
    println(nullUpper)           // null
}
```

Save and run. Output:

```text
6
null
READER
null
```

Walk through each call. `maybeName?.length` is "if `maybeName` is not null, give me its length; otherwise null". Since `maybeName` is "Reader", we get 6. `nullName?.length` evaluates to null because `nullName` is null. The whole expression has type `Int?` (nullable Int) because the result might be either a number or null.

The same pattern works with `uppercase()`. `maybeName?.uppercase()` returns a `String?` (nullable string), which we capture in `maybeUpper`. The result is "READER" because the call succeeded. For `nullName?.uppercase()`, the result is null because the safe call short-circuited.

The key takeaway is that `?.` propagates null. If the receiver is null, the entire chain produces null without ever calling the method. This is the same idea as JavaScript's optional chaining (`?.`) and Swift's optional chaining, but Kotlin has had it from the start.

### Step 2: Chain ?. Calls

You can chain `?.` calls to safely walk through a series of nullable values:

```kotlin
fun main() {
    val maybeName: String? = "Catatku User"
    
    val firstWordLength = maybeName?.split(" ")?.firstOrNull()?.length
    println("First word length: $firstWordLength")
    
    val nullName: String? = null
    val length2 = nullName?.split(" ")?.firstOrNull()?.length
    println("From null: $length2")
}
```

Save and run. Output:

```text
First word length: 7
From null: null
```

The first chain `maybeName?.split(" ")?.firstOrNull()?.length` does four things: check if `maybeName` is not null, then split it by spaces, then take the first element if any (using `firstOrNull` which returns null for empty lists), then get its length. Each `?.` link in the chain short-circuits if its receiver is null. If anything along the way is null, the whole expression evaluates to null without crashing.

The second chain shows the short-circuit behavior: `nullName` is null, so the chain immediately produces null without ever calling `split`. The whole expression has type `Int?` because the final operation `.length` would produce an `Int`, but the chain might produce null at any earlier point.

This kind of safe chaining is one of Kotlin's most pleasant features. The Java equivalent would be a series of nested null checks, each one with its own `if (... != null)` guard, which obscures the actual logic. With `?.` the logic stays visible and the null handling is implicit.

### Step 3: Combine ?. with Other Operations

You can use `?.` with property access, method calls, and indexing:

```kotlin
fun main() {
    val name: String? = "Catatku"
    
    println(name?.length)              // property access through ?.
    println(name?.uppercase())          // method call through ?.
    println(name?.get(0))               // indexing through ?.
    println(name?.substring(0, 3))      // method with args through ?.
}
```

Save and run. Output:

```text
7
CATATKU
C
Cat
```

All four operations work the same way: if `name` is non-null, perform the operation; if null, return null. The `name?.get(0)` is equivalent to `name?.let { it[0] }` for nullable receivers; you cannot write `name?[0]` because the indexing syntax does not have a safe-call form, but `name?.get(0)` accomplishes the same thing.

---

## 4. The Elvis Operator

The safe-call operator returns null when the receiver is null. Often you want a default value instead. The Elvis operator `?:` does exactly this: it returns the left side if it is not null, or evaluates the right side otherwise.

### Step 1: Provide a Default with ?:

Replace the body of `main` with this:

```kotlin
fun main() {
    val maybeName: String? = "Reader"
    val nullName: String? = null
    
    val display1 = maybeName ?: "Anonymous"
    val display2 = nullName ?: "Anonymous"
    
    println("display1: $display1")
    println("display2: $display2")
}
```

Save and run. Output:

```text
display1: Reader
display2: Anonymous
```

The expression `maybeName ?: "Anonymous"` says "if `maybeName` is non-null, use it; otherwise use 'Anonymous'". The result type is `String` (non-null) because we always end up with a value: either the real string or the default.

The operator gets its name because `?:` looks like the eyes and hair of Elvis Presley if you tilt your head sideways. It is a little silly, but the name has stuck and is universally understood among Kotlin programmers. Other languages have similar operators with different names: SQL's `COALESCE`, JavaScript's `??` (nullish coalescing), Swift's `??`.

### Step 2: Combine ?. with ?:

The combination of safe-call and Elvis is one of the most common patterns in idiomatic Kotlin:

```kotlin
fun main() {
    val maybeName: String? = "Reader"
    val nullName: String? = null
    
    val len1 = maybeName?.length ?: 0
    val len2 = nullName?.length ?: 0
    
    println("len1: $len1")
    println("len2: $len2")
    
    val firstChar1 = maybeName?.get(0) ?: '?'
    val firstChar2 = nullName?.get(0) ?: '?'
    
    println("firstChar1: $firstChar1")
    println("firstChar2: $firstChar2")
}
```

Save and run. Output:

```text
len1: 6
len2: 0
firstChar1: R
firstChar2: ?
```

Read each `val` declaration as a small recipe. `maybeName?.length ?: 0` means "give me `maybeName`'s length if `maybeName` is non-null, otherwise zero". The result type is `Int` (non-null) because the Elvis operator guarantees a value either way. This pattern of `nullable_call ?: default_value` is genuinely everywhere in Kotlin code, and once you read it fluently it becomes one of the small joys of the language.

### Step 3: Use ?: for Early Returns and Throws

The right side of `?:` can also be a `return` or `throw`, which lets you exit the current function or raise an exception when a value is unexpectedly null:

```kotlin
fun describeFirstChar(name: String?) {
    val first = name?.firstOrNull() ?: return
    println("First character: $first")
}

fun main() {
    describeFirstChar("Catatku")
    describeFirstChar(null)
    describeFirstChar("")
    println("After all calls")
}
```

Save and run. Output:

```text
First character: C
After all calls
```

When `name` is null, the safe call `name?.firstOrNull()` returns null, so the Elvis operator triggers `return`, which exits `describeFirstChar` immediately. The third call passes an empty string. An empty string has no first character, so `firstOrNull()` also returns null and the function returns early again. (Using `name?.get(0)` instead would crash on the empty string, because `get(0)` throws when there is no character at index 0.) Notice that "After all calls" is printed once, after both early returns, because `return` only exits the current function (not `main`).

This early-return pattern is useful when you want to "guard" against null input and skip the rest of the function. It is a clean alternative to wrapping everything in an `if (name != null) { ... }` block, which would indent the rest of the function by one level. The `?: return` reads as "if this was supposed to be non-null but is, bail out".

A related pattern uses `?: throw IllegalStateException(...)` to raise an exception when null is unexpected:

```kotlin
fun requireFirstChar(name: String?): Char {
    return name?.firstOrNull() ?: throw IllegalStateException("name was null or empty")
}

fun main() {
    println(requireFirstChar("Catatku"))
    println(requireFirstChar(""))
}
```

Save and run. The first call prints `C`. The second call finds no first character, so the program stops with `Exception in thread "main" java.lang.IllegalStateException: name was null or empty`, followed by a short stack trace that points at the `throw`.

This is less common than the standard library's `requireNotNull` (covered in Section 8), but it shows that `?:` can take any expression on the right side, including ones that do not return normally.

---

## 5. The Not-Null Assertion Operator

Sometimes you have a nullable value and you are absolutely certain that it is not null at this point. The not-null assertion operator `!!` says "trust me, this is not null". If you are wrong, the program crashes with a `NullPointerException`.

### Step 1: Use !! Only When You Are Certain

Replace the body of `main` with this:

```kotlin
fun main() {
    val maybeName: String? = "Catatku"
    
    val length = maybeName!!.length
    println("Length: $length")
    
    // The next two lines would crash:
    // val nullName: String? = null
    // val crash = nullName!!.length
}
```

Save and run. Output:

```text
Length: 7
```

The expression `maybeName!!.length` says "I assert that `maybeName` is not null; treat it as `String` (non-null) and call `.length`". Since `maybeName` is actually "Catatku", the assertion holds and we get the length.

Now uncomment the two lines about `nullName`. Run again. The program prints `Length: 7` and then crashes with this line, followed by a short stack trace that points at the `!!` line:

```text
Exception in thread "main" java.lang.NullPointerException
```

The `!!` operator does not avoid null pointer exceptions; it just lets them happen. Using `!!` puts the responsibility on you (the programmer) to be certain the value is not null. If you are wrong, you get the same crash you would have gotten in Java.

### Why !! Is a Code Smell

The `!!` operator exists for the rare cases where you have proof that a value is not null but the type system cannot see that proof. For example, you might have called a Java method that returns `String?` (nullable in Kotlin's view) but you know the Java code never returns null because of how it is used in your application. In that case, `!!` is the way to tell Kotlin "I know better than the type system here".

But `!!` is dangerous because it bypasses the safety net that null safety provides. If your assumption is wrong, you get the crash that null safety was supposed to prevent. And worse, the crash happens at the `!!` site rather than at the place where the value was supposed to be non-null but became null. This makes debugging harder because the crash location does not point at the bug.

For these reasons, idiomatic Kotlin avoids `!!` whenever possible. The replacement is usually `?.` and `?:` (or the `let` pattern in the next section). When you find yourself reaching for `!!`, ask whether you can rewrite the code to handle the null case properly. Most of the time you can, and the result is more robust. Reserve `!!` for the genuinely rare cases where Kotlin truly cannot infer non-nullness despite obvious correctness.

A common smell pattern is `something!!.field!!.method()!!`, with `!!` sprinkled throughout because each step is nullable. This is almost always wrong; the right fix is to use `?.` chains and handle the null case once at the end with `?:` or `let`. If you see `!!` in your own code, treat it as a flag to look at the surrounding logic and see if there is a cleaner approach.

### When !! Is Acceptable

The legitimate uses of `!!` are narrow. The most common is when you control how a value gets created and you know it is set before any code reads it. For example, if you initialize a field in a constructor and never set it back to null, the field is effectively non-null even if its declared type is nullable. In these cases, `!!` is a way of saying "the type system cannot see this invariant, but it is true". Even then, Kotlin often offers cleaner alternatives: `lateinit var` for late-initialized fields, or refactoring to make the value non-null from the start.

For Catatku, we will not use `!!` at all. Every nullable case will be handled with `?.`, `?:`, `let`, or by ensuring the value is non-null in the first place. This is achievable for almost any application code, and the discipline pays off in code that does not crash on null inputs.

---

## 6. Smart Casts

Once you check that a nullable value is not null using `if (x != null)`, the compiler is smart enough to treat `x` as non-null inside the `if` body. This is called a smart cast, and it lets you write code that handles nullable values without sprinkling `?.` everywhere.

### Step 1: See Smart Casts at Work

Replace the body of `main` with this:

```kotlin
fun main() {
    val maybeName: String? = "Catatku"
    
    if (maybeName != null) {
        // Inside this block, maybeName is smart-cast to String (non-null)
        println("Length: ${maybeName.length}")
        println("Uppercase: ${maybeName.uppercase()}")
    } else {
        println("Was null")
    }
}
```

Save and run. Output:

```text
Length: 7
Uppercase: CATATKU
```

Inside the `if (maybeName != null)` block, the compiler knows that `maybeName` cannot be null (because we just checked). It smart-casts `maybeName` from `String?` to `String`, which means we can call `.length` and `.uppercase()` directly without `?.`. The Kotlin compiler tracks this kind of flow-sensitive type information automatically, which makes null checks feel natural.

Smart casts work for `if` checks, `when` checks, and any other place where the compiler can prove that a value cannot be null. They also work for type checks (using `is`), which we will see in Lesson 12.

### Step 2: Smart Casts and Local Variables

Smart casts need the compiler to be sure the value cannot change between the check and the use. For a local variable, even a `var`, the compiler can see every assignment, so the smart cast still applies as long as nothing reassigns the variable in between:

```kotlin
fun main() {
    var maybeName: String? = "Catatku"
    
    if (maybeName != null) {
        // This works because maybeName is local and not modified between check and use
        println("Length: ${maybeName.length}")
    }
}
```

Save and run. Output:

```text
Length: 7
```

For local variables this is usually fine. The trickier case is properties on a class that might be modified by another thread or by a getter method. We will see that nuance in Lesson 9 when we cover classes; for now, just notice that smart casts work on local variables, and that is enough for almost all everyday code.

### Step 3: Smart Casts vs Safe-Calls

Smart casts and safe-calls are both ways to handle nullable values, and you choose between them based on what makes the code clearer. Compare these two equivalent versions:

```kotlin
fun main() {
    val maybeName: String? = "Catatku"
    
    // Version 1: smart cast
    if (maybeName != null) {
        println("Length: ${maybeName.length}")
    }
    
    // Version 2: safe call with Elvis
    val length = maybeName?.length ?: 0
    println("Length: $length")
}
```

Save and run. Output:

```text
Length: 7
Length: 7
```

Both versions print the same line. Version 1 is clearer when you have multiple operations to do on the non-null value (the entire `if` body can use the smart-cast variable). Version 2 is shorter when you just want a single value with a default. Idiomatic Kotlin uses both styles, picking whichever fits the situation.

---

## 7. The let Pattern

A particularly clean way to do work with a nullable value only when it is not null is the `?.let { ... }` idiom. Inside the lambda, the value is non-null (passed as `it` by default), and the whole expression returns the result of the lambda or null.

### Step 1: Use let for Conditional Work

Replace the body of `main` with this:

```kotlin
fun main() {
    val maybeName: String? = "Catatku"
    val nullName: String? = null
    
    maybeName?.let { name ->
        println("Got a name: $name (length ${name.length})")
    }
    
    nullName?.let { name ->
        println("This will not print")
    }
    
    println("Done")
}
```

Save and run. Output:

```text
Got a name: Catatku (length 7)
Done
```

The `?.let { ... }` pattern says: if the receiver is not null, run the lambda body with the receiver as the parameter; if null, do nothing. Inside the lambda, the parameter (we named it `name`, but the default is `it` if you do not name it) is non-null. The whole expression has the type of whatever the lambda returns.

This is genuinely useful when you want to do several operations on a non-null value but do not want to nest inside an `if` block. The `let` keeps the code linear. It is also useful in chains:

```kotlin
fun main() {
    val maybeNumber: String? = "42"
    
    val parsed = maybeNumber?.toIntOrNull()?.let { num ->
        num * 2
    }
    
    println("parsed: $parsed")
}
```

The chain is: if `maybeNumber` is not null, call `toIntOrNull()` (which returns `Int?`); if the parse succeeds, run the lambda with the integer to compute its double. If anything in the chain is null, the result is null.

Save and run. Output:

```text
parsed: 84
```

### Step 2: Use let with the Default it Parameter

If the lambda has a single parameter, you can omit naming it and use `it` instead:

```kotlin
fun main() {
    val maybeName: String? = "Catatku"
    
    maybeName?.let {
        println("Name: $it (length ${it.length})")
    }
}
```

Save and run. Output:

```text
Name: Catatku (length 7)
```

This is shorter and is the more common style for short lambdas. For longer lambdas, naming the parameter (like `name` in the previous example) makes the code clearer.

### Step 3: Compare let with Smart Casts

`let` and smart casts overlap, and you can usually pick either. Compare:

```kotlin
fun main() {
    val maybeName: String? = "Catatku"
    
    // Smart cast version
    if (maybeName != null) {
        val upper = maybeName.uppercase()
        println(upper)
    }
    
    // Let version
    maybeName?.let {
        val upper = it.uppercase()
        println(upper)
    }
}
```

Save and run. Output:

```text
CATATKU
CATATKU
```

Both versions print the same line. The smart cast version is slightly more verbose but reads more like familiar imperative code. The `let` version is more concise and chains naturally with other safe-call operations. Pick whichever fits the surrounding code; both are idiomatic.

A small advantage of `let` is that it works on any expression, not just simple variables. For example, `someFunction()?.let { ... }` does not need to assign the result of `someFunction()` to a variable first; the safe-call and `let` chain together. With the `if` pattern, you would have to write `val tmp = someFunction(); if (tmp != null) { ... }`.

---

## 8. Standard Library Helpers

The Kotlin standard library has a few helpers for null handling that are worth knowing.

### Step 1: requireNotNull and checkNotNull

These functions throw an exception if their argument is null and return the non-null value otherwise:

```kotlin
fun main() {
    val maybeName: String? = "Catatku"
    val name = requireNotNull(maybeName) { "name must not be null" }
    println("name: $name (type: ${name::class.simpleName})")
    
    // val nullName: String? = null
    // val crash = requireNotNull(nullName) { "name must not be null" }
    // throws IllegalArgumentException with the message
}
```

Save and run. Output:

```text
name: Catatku (type: String)
```

Uncommenting the crash lines makes the program stop with `Exception in thread "main" java.lang.IllegalArgumentException: name must not be null`, which carries your custom message. The function `requireNotNull` is similar to `!!` but with a custom error message, which is more useful for debugging. The companion function `checkNotNull` does the same thing but throws `IllegalStateException` instead of `IllegalArgumentException`. The convention is `requireNotNull` for input validation (precondition violated by the caller) and `checkNotNull` for state validation (invariant violated within the function).

These are useful at the boundary between trusted code and untrusted code: when you need to assert that a value is not null and you want a meaningful error if you are wrong. They are still escape hatches around null safety, but with better error messages than bare `!!`.

### Step 2: orEmpty

For nullable strings and collections, `orEmpty()` returns the value if non-null or an empty value otherwise. This is a tidy alternative to `?: ""` or `?: emptyList()`:

```kotlin
fun main() {
    val maybeName: String? = null
    val safe1 = maybeName.orEmpty()
    println("safe1: '$safe1' (length ${safe1.length})")
    
    val maybeList: List<Int>? = null
    val safe2 = maybeList.orEmpty()
    println("safe2: $safe2 (size ${safe2.size})")
}
```

Save and run. Output:

```text
safe1: '' (length 0)
safe2: [] (size 0)
```

The `orEmpty()` method exists on `String?`, `List?`, `Set?`, `Map?`, `Array?`, and a few other types. It is a small convenience but a frequently useful one because empty strings and empty collections are the natural fallback for many operations.

### Step 3: isNullOrEmpty and isNullOrBlank

For strings, two predicates check for null and emptiness in one operation:

```kotlin
fun main() {
    val empty: String? = ""
    val blank: String? = "   "
    val real: String? = "hello"
    val nullName: String? = null
    
    println("empty.isNullOrEmpty(): ${empty.isNullOrEmpty()}")
    println("blank.isNullOrEmpty(): ${blank.isNullOrEmpty()}")
    println("blank.isNullOrBlank(): ${blank.isNullOrBlank()}")
    println("real.isNullOrBlank(): ${real.isNullOrBlank()}")
    println("nullName.isNullOrEmpty(): ${nullName.isNullOrEmpty()}")
}
```

Save and run. Output:

```text
empty.isNullOrEmpty(): true
blank.isNullOrEmpty(): false
blank.isNullOrBlank(): true
real.isNullOrBlank(): false
nullName.isNullOrEmpty(): true
```

Notice the second line: a string of spaces is not empty, but it is blank. `isNullOrEmpty` returns true if the string is null or empty (zero characters). `isNullOrBlank` returns true if the string is null, empty, or contains only whitespace. These predicates eliminate the need to write `name == null || name.isEmpty()` patterns, which are verbose and easy to get wrong.

---

## 9. Run and Test

Combine everything from this lesson into one program that exercises null safety end to end.

### Step 1: Build the Combined Example

Replace `Main.kt` with this comprehensive demonstration:

```kotlin
fun describeUser(name: String?, email: String?, age: Int?) {
    println("User Info:")
    println("  Name: ${name ?: "(unknown)"}")
    println("  Email: ${email?.lowercase() ?: "(no email)"}")
    println("  Email length: ${email?.length ?: 0}")
    
    if (age != null) {
        println("  Age: $age years")
        println("  In ten years: ${age + 10}")
    } else {
        println("  Age: not provided")
    }
    
    name?.let {
        println("  Greeting: Hello, $it!")
    }
    
    println("---")
}

fun main() {
    describeUser("Reader", "reader@example.com", 25)
    describeUser(null, "anon@example.com", null)
    describeUser("Catatku", null, 1)
    describeUser(null, null, null)
}
```

Save and run.

### Step 2: Read the Output

The output is:

```text
User Info:
  Name: Reader
  Email: reader@example.com
  Email length: 18
  Age: 25 years
  In ten years: 35
  Greeting: Hello, Reader!
---
User Info:
  Name: (unknown)
  Email: anon@example.com
  Email length: 16
  Age: not provided
---
User Info:
  Name: Catatku
  Email: (no email)
  Email length: 0
  Age: 1 years
  In ten years: 11
  Greeting: Hello, Catatku!
---
User Info:
  Name: (unknown)
  Email: (no email)
  Email length: 0
  Age: not provided
---
```

Walk through what each piece contributed. The `name ?: "(unknown)"` provides a default name when null. The `email?.lowercase() ?: "(no email)"` chains a safe call with an Elvis fallback. The `email?.length ?: 0` gives a numeric fallback. The `if (age != null) { ... }` uses smart casting so we can do arithmetic with `age` directly inside the block. The `name?.let { ... }` block runs only when `name` is non-null, demonstrating conditional execution.

Each of the four calls exercises a different combination of null and non-null arguments, and the function handles every combination gracefully without crashing. This is what null safety buys you: code that treats null as a normal case to handle rather than as an error to be caught at runtime.

### Step 3: Notice the Absence of Crashes

In Java, the same logic written naively would have several places where a `NullPointerException` could occur. Calling `.lowercase()` on a null email, accessing the integer value of a null `Integer` (which would unbox to a primitive int), formatting a null name, all of these would crash. In Kotlin, none of them do, because the compiler refused to compile any code that would have caused a crash. The crashes were caught at compile time, and we wrote explicit handling for each case.

This is the value proposition of null safety: less code that crashes in production, more bugs caught at compile time, and a clearer story about what each value can and cannot be. The cost is a slight learning curve while you get used to the operators (`?.`, `?:`, `!!`, `let`), but the benefit pays back the investment within a few weeks of consistent use.

---

## 10. Fix the Errors in Your Code

Three null safety mistakes are common in early Kotlin code.

**Error 1: Reaching for !! to silence the compiler**

```kotlin
// Wrong
fun greet(name: String?) {
    println("Hello, ${name!!}!")
}

fun main() {
    greet("Reader")
    greet(null)
}

// Correct
fun greet(name: String?) {
    println("Hello, ${name ?: "stranger"}!")
}

fun main() {
    greet("Reader")
    greet(null)
}
```

Reaching for `!!` to silence the compiler is a classic beginner reflex when the type system rejects code. The `!!` does silence the compiler, but it does not solve the underlying problem; it just delays the crash from compile time to runtime, which is worse. The wrong version prints `Hello, Reader!` and then crashes on the second call with `Exception in thread "main" java.lang.NullPointerException`. The fix is to handle the null case properly with `?.`, `?:`, smart casts, or `let`. The correct version uses Elvis to supply a fallback and prints `Hello, Reader!` followed by `Hello, stranger!`. As a habit, when you find yourself typing `!!`, pause and ask whether the value really cannot be null at this point, and if it cannot, why the type system thinks it might be. Often the right answer is to refactor so the type is non-null from the start.

**Error 2: Forgetting that ?. keeps the chain nullable**

```kotlin
// Wrong
fun firstChar(name: String?): Char? {
    return name?.uppercase().get(0)
}

fun main() {
    println(firstChar("catatku"))
}

// Correct
fun firstChar(name: String?): Char? {
    return name?.uppercase()?.get(0)
}

fun main() {
    println(firstChar("catatku"))
    println(firstChar(null))
}
```

When you chain `?.` and a regular `.`, the result of the safe call is still nullable, so you cannot use it directly. The expression `name?.uppercase().get(0)` is rejected with `Only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'kotlin.String?'.` because `name?.uppercase()` has type `String?`. The fix is to keep using safe calls through the chain: `name?.uppercase()?.get(0)`, which has type `Char?`. The correct version prints `C` for `"catatku"` and `null` for a null input. Alternatively, you can decide on a fallback at some earlier point with `?:`. The choice depends on whether the chain might return null in your real usage.

**Error 3: Writing == where you meant != in a null check**

```kotlin
// Wrong
fun describe(name: String?) {
    if (name == null) {
        println("Length: ${name.length}")
    }
}

fun main() {
    describe("Catatku")
}

// Correct
fun describe(name: String?) {
    if (name != null) {
        println("Length: ${name.length}")
    }
}

fun main() {
    describe("Catatku")
}
```

This one is subtle. The smart cast is contextual: inside `if (name == null) { ... }`, the compiler knows `name` holds nothing but null, so calling `name.length` is rejected with `Only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'kotlin.Nothing?'.` The odd type `Nothing?` is the compiler's way of saying "this can only be null here". The intent was the opposite: `if (name != null) { ... }`, so the smart cast makes `name` non-null inside the block. With `!=`, the program prints `Length: 7`. As a habit, when you write a null check, ask whether you want the smart cast to apply for the null case (rare) or the non-null case (common).

---

## 11. Exercises

These exercises practice null safety patterns.

**Exercise 1:** Write a function `lengthOrZero(s: String?): Int` that returns the length of the string, or 0 if the string is null. Use `?.` and `?:` together. Test it with a few different inputs including null.

**Exercise 2:** Write a function `firstWordUpper(s: String?): String` that returns the first word of the input string, uppercased, or `"NOTHING"` if the input is null or empty. The first word is everything before the first space; if there is no space, the whole string is one word.

**Exercise 3:** Write a function `incrementOrZero(s: String?): Int` that parses the string as an integer and returns the value plus 1, or 0 if the string is null or cannot be parsed. Use `toIntOrNull()` and `?:`.

---

## 12. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

A safe call reads the length when the string exists, and Elvis supplies 0 when it does not.

```kotlin
fun lengthOrZero(s: String?): Int = s?.length ?: 0

fun main() {
    println(lengthOrZero("Catatku"))
    println(lengthOrZero(""))
    println(lengthOrZero(null))
}
```

Save and run. Output:

```text
7
0
0
```

The expression `s?.length` has type `Int?`: the length when `s` is a string, or null when `s` is null. The Elvis operator `?: 0` turns that into a plain `Int`, which matches the declared return type. Notice that the empty string and null both produce 0, but for different reasons: the empty string really has length 0, while null takes the Elvis fallback.

**Solution for Exercise 2:**

This exercise practices chaining safe calls with multiple operations.

```kotlin
fun firstWordUpper(s: String?): String {
    if (s.isNullOrEmpty()) {
        return "NOTHING"
    }
    val firstWord = s.split(" ").first()
    return firstWord.uppercase()
}

fun main() {
    println(firstWordUpper("hello world"))
    println(firstWordUpper("kotlin"))
    println(firstWordUpper(null))
    println(firstWordUpper(""))
}
```

Save and run. Output:

```text
HELLO
KOTLIN
NOTHING
NOTHING
```

The function uses `isNullOrEmpty()` to handle both the null case and the empty-string case in one check, returning early with "NOTHING" when either applies. After that early return, the smart cast lets us treat `s` as a non-null `String` for the rest of the function. We split on spaces and take the first part with `.first()`, then uppercase the result.

A more concise version uses chained safe calls and Elvis:

```kotlin
fun firstWordUpper(s: String?): String =
    s?.takeIf { it.isNotEmpty() }
        ?.split(" ")
        ?.firstOrNull()
        ?.uppercase()
        ?: "NOTHING"

fun main() {
    println(firstWordUpper("hello world"))
    println(firstWordUpper("kotlin"))
    println(firstWordUpper(null))
    println(firstWordUpper(""))
}
```

Save and run. Output:

```text
HELLO
KOTLIN
NOTHING
NOTHING
```

This version reads as "if `s` is not null and not empty, split it, take the first piece if any, uppercase it; otherwise give 'NOTHING'". The `takeIf` (covered briefly in Lesson 15) returns the receiver if the predicate is true and null otherwise, which lets us chain emptiness handling into the safe-call sequence. Each link in the chain might produce null, and the final `?:` provides the fallback.

Both versions are idiomatic. The first is easier to read for beginners; the second is more compact and is the kind of code experienced Kotlin programmers gravitate toward. Either is correct, and the choice is about what feels right for the situation. As your fluency grows, you will start writing the chained version more naturally.

**Solution for Exercise 3:**

`toIntOrNull()` already returns null for text that is not a number, so the safe call and Elvis can handle both the null input and the failed parse in one line.

```kotlin
fun incrementOrZero(s: String?): Int {
    val number = s?.toIntOrNull() ?: return 0
    return number + 1
}

fun main() {
    println(incrementOrZero("41"))
    println(incrementOrZero(" 7"))
    println(incrementOrZero("abc"))
    println(incrementOrZero(null))
}
```

Save and run. Output:

```text
42
0
0
0
```

If `s` is null, `s?.toIntOrNull()` is null. If `s` is text that does not parse, `toIntOrNull()` returns null too. In both cases the Elvis operator runs `return 0` and leaves the function early. Otherwise `number` is a non-null `Int`, and the function returns it plus one. The second call is worth a closer look: `" 7"` has a leading space, and `toIntOrNull()` does not trim whitespace, so it fails to parse and the result is 0. When input comes from a user, calling `trim()` first (`s?.trim()?.toIntOrNull()`) is a common safeguard.

---

## 13. Understanding Why Null Safety Matters

The amount of engineering time spent fighting null pointer exceptions in Java applications is genuinely staggering. Null is the single most common cause of runtime crashes in JVM code, by a wide margin. Studies of large Java codebases have estimated that 20 to 40 percent of runtime exceptions are NullPointerExceptions, and the percentage tends to be higher in code that has not been heavily debugged. Each crash costs engineering time to diagnose and fix, and many of them ship to production because the trigger conditions are unusual and not exercised in testing. This is the "billion dollar mistake" Tony Hoare apologized for: a single design decision in 1965 that has caused more bugs than any other.

Kotlin's response is to encode nullability in the type system. Every type is either definitely non-null or definitely nullable, and the compiler tracks the distinction. Operations that would crash on null are caught at compile time and rejected, forcing you to handle the null case explicitly. The result is that idiomatic Kotlin code does not crash with NullPointerException unless you go out of your way to use `!!`, and the rare crashes that do happen point at exactly where the assumption was wrong. This is a categorically different debugging experience from Java, where null crashes can come from anywhere in deeply nested call stacks.

The cost of this safety is a small set of operators to learn (`?.`, `?:`, `!!`, `let`) and a slight verbosity when you genuinely have a value that might be null. The verbosity is the entire point: nullability is now visible in the source code rather than hidden as a runtime surprise. Once you have used these operators for a few weeks, they become second nature, and you start to feel naked writing Java without them. Many programmers who switch from Java to Kotlin describe this as one of the biggest day-to-day quality-of-life improvements: the constant low-level worry about null disappears, replaced by deliberate handling at the small number of places where null matters.

A subtler benefit is that null safety changes how you design APIs. When you write a function in Java, the parameter type does not tell callers whether null is acceptable, so each function has to either tolerate null (with manual checks) or trust callers to never pass null (with all the bugs that implies). Documentation conventions like `@Nullable` and `@NonNull` annotations exist but are inconsistent and not enforced. In Kotlin, the parameter type is the documentation: `String` means non-null, `String?` means nullable, and the compiler enforces both. This shifts API design toward making nullability deliberate: each parameter and return value is marked according to whether null makes sense in that role. The resulting APIs are clearer because the contract is precise.

A common worry from people coming from Java is that Kotlin's null safety will be a hassle when interoperating with Java code. The reality is more pleasant than expected. Kotlin treats Java types as "platform types" (written `String!`), which can be either nullable or non-null depending on usage. The compiler does not enforce null safety on platform types but does flag them in IDE warnings when you do something risky. Most Java APIs end up being usable with Kotlin null safety either by treating their results as nullable (the safe choice) or by using `@Nullable` or `@NonNull` annotations in the Java code (which Kotlin reads). For new code in pure Kotlin, the type system gives you full guarantees; for legacy interop, you get sensible defaults plus the option to add precision where it matters.

The deepest benefit is conceptual. Once you start thinking about types as carrying nullability information, you start asking different questions when you design data: can this field be missing, or is it always required? Can this function return nothing meaningful, or does it always have a result? These questions are valuable in any language, but Kotlin makes them visible in the type signatures. Your type definitions become a kind of design document where the absence of null is a meaningful statement. Programming with this awareness makes you a better designer in any language, because you internalize the discipline of being precise about what your data really means.

---

## Next Up - Lesson 8

Null safety is built into Kotlin's type system. Every type comes in two flavors: the non-null version (`T`) which the compiler refuses to let hold null, and the nullable version (`T?`) which can hold null but cannot be used without explicit handling. Five tools cover the common cases. The safe-call operator `?.` calls a method or accesses a property if the receiver is non-null, returning null otherwise. The Elvis operator `?:` provides a default value when the left side is null. The not-null assertion `!!` says "trust me, this is not null" but crashes if you are wrong, and is rarely the right choice. Smart casts let the compiler track nullability across `if (x != null)` checks so you can treat the value as non-null inside the block. The `?.let { ... }` idiom runs a lambda only when the receiver is non-null, with the receiver as the `it` parameter inside. Together these tools handle every nullable situation you will encounter, and after a few weeks of practice they become as natural as any other piece of Kotlin syntax.

In Lesson 8 you will learn about collections: `List`, `MutableList`, `Map`, `MutableMap`, `Set`, `MutableSet`, and the rich set of standard-library functions for working with them. Collections are how Catatku will store its tasks, and Kotlin's collection API is one of the most pleasant in any language.
