## 1. Before You Begin

Some kinds of data only make sense as one of a small set of distinct shapes. A traffic light is red, yellow, or green. An HTTP response is either successful with a body, redirected to another URL, or failed with an error code. A task in Catatku is pending, in progress, done, or cancelled with a reason. Trying to represent these with strings (like we did in Lesson 10's `Entry` class) works in the short term but invites bugs: nothing stops you from setting a status to "Penidng" with a typo, or to "InProgressss" with extra characters, and the compiler cannot help you catch the mistake. Worse, when you write code that branches on the status, you have no compiler check that you handled every possible case. If a new status is introduced later, every place that branches on the status quietly continues with stale logic.

Kotlin's solution is sealed classes. A sealed class is a closed type hierarchy: a parent class with a fixed set of subclasses, all known to the compiler at compile time. When you write a `when` expression on a sealed class, the compiler can check that every variant is handled, refusing to compile code that misses a case. Some variants are simple objects (no extra data), and some are full classes that carry data. This combination, sealed classes plus exhaustive `when`, is one of the most expressive features in Kotlin and the right way to model "a value is exactly one of these specific shapes". By the end of this lesson, Catatku's `Status` will be a sealed class with four variants, three of which carry no data and one of which (Cancelled) carries a reason string, and it will replace the `String`-based `status` field of the `Entry` from Lesson 10.

### What You'll Build

A `Status` sealed class with four variants: `Pending`, `InProgress`, `Done`, and `Cancelled(reason: String)`. You will update the `Entry` data class to use the new `Status` type for its status field, write a `statusMarker` function that uses an exhaustive `when` to map each status to a display marker, see what happens when you forget a variant, and use destructuring to extract the cancellation reason from a `Cancelled` instance. By the end the `Status` is properly typed and the compiler checks every place that branches on it.

### What You'll Learn

- ✅ How to declare a sealed class and its variants
- ✅ The difference between an `object` variant (no data) and a `class` variant (with data)
- ✅ How exhaustive `when` works on sealed types
- ✅ How smart casts let you use variant-specific data inside a `when` arm
- ✅ When to use a sealed class versus an enum class

### What You'll Need

- The `catatku` Gradle project from previous lessons
- A working understanding of classes from Lesson 9 and data classes from Lesson 10
- About forty minutes
- Familiarity with `when` from Lesson 5

---

## 2. Defining a Sealed Class

A sealed class is declared with the `sealed` keyword before `class`. The variants are declared as either nested objects or nested classes inside the sealed class body, or as separate classes in the same file that explicitly extend the sealed parent.

### Step 1: A Minimal Sealed Class

Open `Main.kt` and replace its contents with this minimal example:

```kotlin
sealed class Status {
    object Pending : Status()
    object InProgress : Status()
    object Done : Status()
}

fun main() {
    val s1 = Status.Pending
    val s2 = Status.InProgress
    val s3 = Status.Done
    
    println("s1: $s1")
    println("s2: $s2")
    println("s3: $s3")
}
```

Save and run. Output:

```text
s1: Status$Pending@18b4aac2
s2: Status$InProgress@764c12b6
s3: Status$Done@c387f44
```

The class declaration `sealed class Status` introduces a sealed parent named `Status`. Inside the body, three `object` declarations create the three variants. Each `object` is both a class and a single instance of that class; `Status.Pending` is the unique instance of the `Pending` object, and there is no way to create a second one.

The `: Status()` after each object declaration says "this object extends `Status`". The parentheses look like a constructor call because a sealed class has an implicit empty constructor that the variants invoke. We will not need parameters on `Status` itself, but the parentheses are required syntax.

The default `toString` for objects shows the class name (with a `$` between the parent and the nested name, which is how the JVM names nested classes) plus a hash code, which is not very pretty. The hash codes change between runs and machines, so yours will look different. We will improve this in Section 3 by overriding `toString`. For now, just notice that we have three distinct instances representing three logical states.

### Step 2: Use the Variants in a when

The whole point of a sealed class is that you can branch on which variant a value is, and the compiler will check that you handle every variant. Add a function:

```kotlin
sealed class Status {
    object Pending : Status()
    object InProgress : Status()
    object Done : Status()
}

fun statusMarker(status: Status): String = when (status) {
    is Status.Pending -> "[ ]"
    is Status.InProgress -> "[~]"
    is Status.Done -> "[x]"
}

fun main() {
    println(statusMarker(Status.Pending))
    println(statusMarker(Status.InProgress))
    println(statusMarker(Status.Done))
}
```

Save and run. Output:

```text
[ ]
[~]
[x]
```

The function `statusMarker` takes a `Status` and uses `when` to map each variant to a display marker. The `is Status.Pending` branch matches if `status` is the `Pending` object, and similarly for the others. The whole `when` is an expression that returns the matched value, captured as the return value of the function.

Notice there is no `else` branch in the `when`. The compiler can prove that every possible value of `Status` is covered (because the only values are the three variants we listed), so an `else` is unnecessary. This is the heart of exhaustive matching: the compiler knows the closed set of possibilities and verifies that every one is handled.

To see the compiler's exhaustiveness check at work, comment out the `is Status.Done` line and try to compile. The error is:

```text
'when' expression must be exhaustive. Add the 'Done' branch or an 'else' branch.
```

The compiler tells you exactly which case is missing. Add the line back. This kind of automated check is one of the best features of sealed classes; it makes refactoring safe in a way that string-based enums cannot match.

### Step 3: Add a Variant With Data

The fourth variant Catatku needs is `Cancelled`, which carries a reason for the cancellation. Variants with data are declared as classes (not objects) and have a constructor:

```kotlin
sealed class Status {
    object Pending : Status()
    object InProgress : Status()
    object Done : Status()
    data class Cancelled(val reason: String) : Status()
}

fun statusMarker(status: Status): String = when (status) {
    is Status.Pending -> "[ ]"
    is Status.InProgress -> "[~]"
    is Status.Done -> "[x]"
    is Status.Cancelled -> "[!]"
}

fun describeStatus(status: Status): String = when (status) {
    is Status.Pending -> "task is waiting"
    is Status.InProgress -> "task is being worked on"
    is Status.Done -> "task is finished"
    is Status.Cancelled -> "task was cancelled because: ${status.reason}"
}

fun main() {
    val statuses = listOf(
        Status.Pending,
        Status.InProgress,
        Status.Done,
        Status.Cancelled("rescheduled")
    )
    
    for (s in statuses) {
        println("${statusMarker(s)} ${describeStatus(s)}")
    }
}
```

Save and run. Output:

```text
[ ] task is waiting
[~] task is being worked on
[x] task is finished
[!] task was cancelled because: rescheduled
```

The `data class Cancelled(val reason: String) : Status()` declaration creates a variant that carries a `String` property. Because we used `data class`, we get all the data class benefits (auto-generated `equals`, `hashCode`, `toString`, `copy`) for free.

In `describeStatus`, the `is Status.Cancelled` branch is interesting. After the `is` check, the compiler smart-casts `status` to `Status.Cancelled`, which means we can access `status.reason` directly inside that branch. The smart cast is the same mechanism we saw in Lesson 7 with null checks: once the compiler proves a type, you can use the type-specific properties without any explicit cast.

The pattern of "object variants for simple cases, class variants for cases with data" is exactly how sealed classes are used in real Kotlin code. The four-variant `Status` we have built is structurally identical to what production task management apps use, just simplified for educational purposes.

---

## 3. Sealed Classes and Data Classes Together

Now let us update `Entry` to use the new `Status` type instead of a `String`.

### Step 1: Update the Entry Class

Replace the body of the file with this:

```kotlin
sealed class Status {
    object Pending : Status()
    object InProgress : Status()
    object Done : Status()
    data class Cancelled(val reason: String) : Status()
}

data class Entry(
    val id: Int,
    val description: String,
    val priority: String = "Medium",
    val status: Status = Status.Pending,
    val createdAt: String = "2026-04-26"
)

fun main() {
    val e1 = Entry(1, "Pay rent")
    val e2 = Entry(2, "Finish Kotlin course", priority = "High")
    val e3 = Entry(3, "Read for fun", status = Status.Done)
    val e4 = Entry(4, "Call dentist", status = Status.Cancelled("rescheduled"))
    
    println(e1)
    println(e2)
    println(e3)
    println(e4)
}
```

Save and run. Output:

```text
Entry(id=1, description=Pay rent, priority=Medium, status=Status$Pending@5cad8086, createdAt=2026-04-26)
Entry(id=2, description=Finish Kotlin course, priority=High, status=Status$Pending@5cad8086, createdAt=2026-04-26)
Entry(id=3, description=Read for fun, priority=Medium, status=Status$Done@6e0be858, createdAt=2026-04-26)
Entry(id=4, description=Call dentist, priority=Medium, status=Cancelled(reason=rescheduled), createdAt=2026-04-26)
```

The `Entry` data class now has a `status: Status` field with a default of `Status.Pending`. We pass real `Status` instances at construction (not strings), so the type system enforces that only valid statuses can ever be stored. There is no way to accidentally write `status = "Penidng"` because the type does not accept strings.

Notice how the auto-generated `toString` shows the cancelled entry with its reason because `Cancelled` is a data class. The other variants (object instances) print as `Status$Pending@...` with a hash code, which is not pretty. Notice that entries 1 and 2 show the same hash code, because there is only one `Pending` object and both entries point to it. Let us fix that with custom `toString` overrides.

### Step 2: Override toString on Each Variant

```kotlin
sealed class Status {
    object Pending : Status() {
        override fun toString(): String = "Pending"
    }
    object InProgress : Status() {
        override fun toString(): String = "InProgress"
    }
    object Done : Status() {
        override fun toString(): String = "Done"
    }
    data class Cancelled(val reason: String) : Status()
}

data class Entry(
    val id: Int,
    val description: String,
    val priority: String = "Medium",
    val status: Status = Status.Pending,
    val createdAt: String = "2026-04-26"
)

fun main() {
    val e1 = Entry(1, "Pay rent")
    val e4 = Entry(4, "Call dentist", status = Status.Cancelled("rescheduled"))
    
    println(e1)
    println(e4)
}
```

Save and run. Output:

```text
Entry(id=1, description=Pay rent, priority=Medium, status=Pending, createdAt=2026-04-26)
Entry(id=4, description=Call dentist, priority=Medium, status=Cancelled(reason=rescheduled), createdAt=2026-04-26)
```

Each object now overrides `toString()` to return a friendly name. The `override` keyword is required when overriding a method from a parent class, which we will see more in Lesson 12 with regular inheritance. For sealed class objects, overriding `toString` is a one-line addition that makes debug output much cleaner.

The `Cancelled` variant uses the auto-generated `toString` from `data class`, which already produces the readable `Cancelled(reason=rescheduled)` form. We do not need to override it.

### Step 3: Mark an Entry Done with copy

Use the `copy` method from Lesson 10 to produce a new entry with a different status:

```kotlin
sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    data class Cancelled(val reason: String) : Status()
}

data class Entry(
    val id: Int,
    val description: String,
    val status: Status = Status.Pending
)

fun main() {
    val original = Entry(1, "Pay rent")
    val markedDone = original.copy(status = Status.Done)
    val cancelled = original.copy(status = Status.Cancelled("changed mind"))
    
    println("original:    $original")
    println("markedDone:  $markedDone")
    println("cancelled:   $cancelled")
}
```

Save and run. Output:

```text
original:    Entry(id=1, description=Pay rent, status=Pending)
markedDone:  Entry(id=1, description=Pay rent, status=Done)
cancelled:   Entry(id=1, description=Pay rent, status=Cancelled(reason=changed mind))
```

Each `copy` produces a new entry with the status changed. The original is untouched, and the new entry has the new status. This is the same immutable update pattern from Lesson 10, now using real types instead of strings. The combination of data classes for the entry plus sealed classes for the status gives Catatku a clean type system: every value is well-typed, every transformation is explicit, and the compiler catches mistakes at compile time.

---

## 4. Exhaustive when in Practice

Exhaustive matching is the killer feature of sealed classes. Let us see it work and see what happens when you violate it.

### Step 1: Watch the Compiler Catch a Missing Case

Replace the body of the file with:

```kotlin
sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    data class Cancelled(val reason: String) : Status()
}

fun marker(status: Status): String = when (status) {
    is Status.Pending -> "[ ]"
    is Status.InProgress -> "[~]"
    is Status.Done -> "[x]"
    is Status.Cancelled -> "[!]"
}

fun main() {
    println(marker(Status.Pending))
    println(marker(Status.Done))
    println(marker(Status.Cancelled("test")))
}
```

Save and run. Output:

```text
[ ]
[x]
[!]
```

This compiles and runs fine, because `marker` handles all four variants.

### Step 2: Add a New Variant

Now suppose Catatku evolves and adds a fifth status, `OnHold`. Add it to the sealed class but leave `marker` as it is:

```kotlin
sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    object OnHold : Status() { override fun toString() = "OnHold" }
    data class Cancelled(val reason: String) : Status()
}

fun marker(status: Status): String = when (status) {
    is Status.Pending -> "[ ]"
    is Status.InProgress -> "[~]"
    is Status.Done -> "[x]"
    is Status.Cancelled -> "[!]"
}

fun main() {
    println(marker(Status.Pending))
    println(marker(Status.Done))
    println(marker(Status.Cancelled("test")))
}
```

Save and run. This time the program does not compile, and the compiler points at the `marker` function:

```text
'when' expression must be exhaustive. Add the 'OnHold' branch or an 'else' branch.
```

The error tells you exactly which case is missing. Adding a variant to the sealed class did not break anything visibly in the class itself, but every `when` that branches on `Status` is now incomplete, and the compiler refuses to build until each one is fixed.

### Step 3: Handle the New Variant

The fix is to add a branch for the new variant:

```kotlin
sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    object OnHold : Status() { override fun toString() = "OnHold" }
    data class Cancelled(val reason: String) : Status()
}

fun marker(status: Status): String = when (status) {
    is Status.Pending -> "[ ]"
    is Status.InProgress -> "[~]"
    is Status.Done -> "[x]"
    is Status.OnHold -> "[-]"
    is Status.Cancelled -> "[!]"
}

fun main() {
    println(marker(Status.Pending))
    println(marker(Status.OnHold))
    println(marker(Status.Cancelled("test")))
}
```

Save and run. Output:

```text
[ ]
[-]
[!]
```

Now everything compiles. The exhaustiveness check has done its job: any time you add a new variant to the sealed class, every place that branches on it becomes a compile error until you handle the new case. This is dramatically safer than string-based statuses, where forgetting a case typically just means the new value goes through some default branch silently.

### Step 4: When else Is Acceptable

Sometimes you genuinely want to handle one or two specific cases and lump everything else together. The `else` branch in `when` is for this:

```kotlin
sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    object OnHold : Status() { override fun toString() = "OnHold" }
    data class Cancelled(val reason: String) : Status()
}

fun isTerminal(status: Status): Boolean = when (status) {
    is Status.Done -> true
    is Status.Cancelled -> true
    else -> false
}

fun main() {
    println("Pending terminal? ${isTerminal(Status.Pending)}")
    println("OnHold terminal? ${isTerminal(Status.OnHold)}")
    println("Done terminal? ${isTerminal(Status.Done)}")
    println("Cancelled terminal? ${isTerminal(Status.Cancelled("rescheduled"))}")
}
```

Save and run. Output:

```text
Pending terminal? false
OnHold terminal? false
Done terminal? true
Cancelled terminal? true
```

The function `isTerminal` returns true for "done" or "cancelled" and false for anything else. The `else` branch covers all other cases (`Pending`, `InProgress`, and `OnHold`) without listing them.

The danger of `else` in a sealed-class `when` is that it disables exhaustiveness checking. If we add a sixth variant later, this `when` will silently treat it as "not terminal" without any compile error. That might be the right behavior, or it might be a bug. As a habit, prefer to enumerate every variant explicitly when you can, and reach for `else` only when you specifically want all-other-cases behavior.

A useful pattern is to keep most `when` blocks exhaustive (no `else`) and use `else` only when the meaning genuinely is "everything else". For Catatku, the `marker` function should be exhaustive (each status has a specific marker), but a function like "is this an active status that shows up in the default list" might naturally use `else`.

### Step 5: Use when as a Statement

Sometimes you do not need a returned value; you just want to dispatch on the variant. `when` works as a statement too:

```kotlin
sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    object OnHold : Status() { override fun toString() = "OnHold" }
    data class Cancelled(val reason: String) : Status()
}

fun handleStatus(status: Status) {
    when (status) {
        is Status.Pending -> println("Just added")
        is Status.InProgress -> println("Working on it")
        is Status.Done -> println("Completed!")
        is Status.OnHold -> println("Paused")
        is Status.Cancelled -> println("Cancelled: ${status.reason}")
    }
}

fun main() {
    handleStatus(Status.Pending)
    handleStatus(Status.Done)
    handleStatus(Status.Cancelled("rescheduled"))
}
```

Save and run. Output:

```text
Just added
Completed!
Cancelled: rescheduled
```

Here `when` is used as a statement: each branch calls `println`, and nothing is returned. Even in this form, Kotlin checks exhaustiveness when the subject is a sealed class. Delete the `is Status.OnHold` line and run again, and the compiler stops with the same kind of message as before:

```text
'when' expression must be exhaustive. Add the 'OnHold' branch or an 'else' branch.
```

This means you get the same safety whether you use `when` to compute a value or just to run some code for each variant. Older Kotlin versions only warned about a non-exhaustive `when` statement, so you may still see tricks in older code to force the check; with current Kotlin you do not need them.

---

## 5. Sealed Interfaces

Kotlin also has sealed interfaces, which work the same way as sealed classes but are interfaces instead. Sealed interfaces are useful when you want a sealed type that other classes can implement, especially when the variants need to extend other classes too.

### Step 1: A Sealed Interface Example

```kotlin
sealed interface Result<T> {
    data class Success<T>(val value: T) : Result<T>
    data class Failure<T>(val error: String) : Result<T>
}

fun parseInt(s: String): Result<Int> {
    val n = s.toIntOrNull()
    return if (n != null) Result.Success(n) else Result.Failure("not a number: '$s'")
}

fun main() {
    val results = listOf(parseInt("42"), parseInt("abc"), parseInt("100"))
    
    for (r in results) {
        when (r) {
            is Result.Success -> println("Got value: ${r.value}")
            is Result.Failure -> println("Error: ${r.error}")
        }
    }
}
```

Save and run. Output:

```text
Got value: 42
Error: not a number: 'abc'
Got value: 100
```

The `sealed interface Result<T>` declares a generic sealed interface with two variants: `Success` (carrying a value) and `Failure` (carrying an error message). This is essentially the same shape as Kotlin's standard library `Result` (covered briefly in Lesson 16) but defined ourselves here for the example.

The advantage of a sealed interface over a sealed class is flexibility. Variants can extend other classes (since Kotlin supports only single inheritance for classes), implement multiple interfaces, and so on. For most cases the `sealed class` form is fine, but when you need this extra flexibility, `sealed interface` is the answer.

### When to Use Sealed Class vs Sealed Interface

The choice between sealed class and sealed interface mostly comes down to whether you need single inheritance from another class. If your variants will all be simple (just data classes or objects), a sealed class is fine and slightly simpler. If your variants need to extend other classes (perhaps because you are integrating with a third-party type hierarchy), a sealed interface is the right choice.

For Catatku's `Status`, we used a sealed class. The variants are all simple, and there is no other class hierarchy that any variant needs to extend. The sealed class form is the standard choice for this kind of model.

### Generic Sealed Types

Notice the `Result<T>` was generic, parameterized by the type `T`. We will see generics in slightly more depth in Lesson 13 when we cover higher-order functions; for now, just notice that sealed classes and interfaces can be generic, and the variants inherit the type parameters. This is what makes types like the standard library's `Result<T>` possible.

---

## 6. Sealed Classes vs Enum Classes

Lesson 12 will cover enum classes, but it is worth previewing the comparison here because sealed classes and enum classes solve overlapping problems.

### Step 1: An Enum Class for Comparison

An enum class is a closed set of named constants:

```kotlin
enum class Priority {
    HIGH, MEDIUM, LOW
}

fun describePriority(p: Priority): String = when (p) {
    Priority.HIGH -> "High priority"
    Priority.MEDIUM -> "Medium priority"
    Priority.LOW -> "Low priority"
}

fun main() {
    for (p in Priority.values()) {
        println("$p: ${describePriority(p)}")
    }
}
```

Save and run. Output:

```text
HIGH: High priority
MEDIUM: Medium priority
LOW: Low priority
```

The enum class is shorter than a sealed class for this kind of "fixed set of named values" use case. The compiler also gives you exhaustive `when` checking for enums, just like for sealed classes.

### When Enums Cannot Carry Variant-Specific Data

The limitation of enums shows up when you want different variants to carry different data. Suppose you want `HIGH` to carry an extra "urgency level" but `LOW` to carry no extra info. With enums, every variant has the same shape (the same fields), so this does not work cleanly. With a sealed class, each variant can have its own fields.

Catatku's `Status` is the canonical example. `Pending`, `InProgress`, and `Done` carry no extra data. `Cancelled` carries a reason. An enum cannot easily express this; a sealed class can.

### The Rule of Thumb

Use an enum class when every variant has the same shape (no variant-specific data, or all variants share the same fields). Use a sealed class when variants might have different fields, or when you want full class flexibility (multiple constructors, methods, properties). The two are not interchangeable; they are tools for different jobs.

For Catatku, `Priority` will be an enum class (Lesson 12) because the three variants are simple named values. `Status` is a sealed class because `Cancelled` carries a reason while the others do not. This split is exactly the right modeling for the domain.

---

## 7. Run and Test

Combine everything into one comprehensive example.

### Step 1: A Complete Status System

Replace `Main.kt` with this:

```kotlin
sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    data class Cancelled(val reason: String) : Status()
}

data class Entry(
    val id: Int,
    val description: String,
    val priority: String = "Medium",
    val status: Status = Status.Pending,
    val createdAt: String = "2026-04-26"
)

fun marker(status: Status): String = when (status) {
    is Status.Pending -> "[ ]"
    is Status.InProgress -> "[~]"
    is Status.Done -> "[x]"
    is Status.Cancelled -> "[!]"
}

fun statusText(status: Status): String = when (status) {
    is Status.Pending -> "pending"
    is Status.InProgress -> "in progress"
    is Status.Done -> "done"
    is Status.Cancelled -> "cancelled (${status.reason})"
}

fun isTerminal(status: Status): Boolean = when (status) {
    is Status.Done -> true
    is Status.Cancelled -> true
    is Status.Pending -> false
    is Status.InProgress -> false
}

fun formatEntry(e: Entry): String {
    return "${marker(e.status)} ${e.id}. ${e.description} (${statusText(e.status)})"
}

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent"),
        Entry(2, "Finish Kotlin course", status = Status.InProgress),
        Entry(3, "Read for fun", status = Status.Done),
        Entry(4, "Call dentist", status = Status.Cancelled("rescheduled")),
        Entry(5, "Walk the dog")
    )
    
    println("All entries:")
    for (e in entries) {
        println("  ${formatEntry(e)}")
    }
    
    val active = entries.filter { !isTerminal(it.status) }
    println("\nActive entries:")
    for (e in active) {
        println("  ${formatEntry(e)}")
    }
    
    val cancelled = entries.filter { it.status is Status.Cancelled }
    println("\nCancelled with reasons:")
    for (e in cancelled) {
        val reason = (e.status as Status.Cancelled).reason
        println("  Entry #${e.id}: '${e.description}' was cancelled because: $reason")
    }
}
```

Save and run.

### Step 2: Read the Output

The output is:

```text
All entries:
  [ ] 1. Pay rent (pending)
  [~] 2. Finish Kotlin course (in progress)
  [x] 3. Read for fun (done)
  [!] 4. Call dentist (cancelled (rescheduled))
  [ ] 5. Walk the dog (pending)

Active entries:
  [ ] 1. Pay rent (pending)
  [~] 2. Finish Kotlin course (in progress)
  [ ] 5. Walk the dog (pending)

Cancelled with reasons:
  Entry #4: 'Call dentist' was cancelled because: rescheduled
```

Walk through what each piece contributed. The sealed class `Status` defines four variants. The data class `Entry` uses `Status` as the type of its status field. Three functions branch on the status: `marker` produces a display marker, `statusText` produces a human-readable description, and `isTerminal` returns whether the status is in a finished state.

The `filter` calls demonstrate two ways to test status. The first uses `isTerminal` (which is itself an exhaustive `when`). The second uses `status is Status.Cancelled` directly in the predicate, which is a type check using the `is` operator. The cast `e.status as Status.Cancelled` after the check accesses the variant-specific `reason` field; we could also use a smart cast inside an `if (e.status is Status.Cancelled)` block.

Every branch on `Status` in this code is exhaustive (no `else` branches). If we added a fifth variant tomorrow, the compiler would point at every place that needs updating. This safety, combined with the readable structure of the variants, is what makes sealed classes one of Kotlin's quietly delightful features.

### Try Adding a New Variant

To experience the safety in action on the full program, add this `OnHold` line inside the `Status` sealed class, right below `Done`:

```kotlin
object OnHold : Status() { override fun toString() = "OnHold" }
```

Save and run. The compiler now flags all three functions (`marker`, `statusText`, and `isTerminal`), each with a message like `'when' expression must be exhaustive. Add the 'OnHold' branch or an 'else' branch.` Update each one (perhaps `is Status.OnHold -> "[-]"` for the marker, `is Status.OnHold -> "on hold"` for statusText, and `is Status.OnHold -> false` for isTerminal). Now everything compiles again. This refactoring loop, where the compiler walks you through every place that needs updating, is one of the genuinely best parts of working with sealed classes. There is no "I forgot to update this code" bug because the compiler will not let you forget.

---

## 8. Fix the Errors in Your Code

Three sealed-class mistakes are common.

**Error 1: Forgetting the parentheses after the parent class**

```kotlin
// Wrong
sealed class Status {
    object Pending : Status
}

// Correct
sealed class Status {
    object Pending : Status()
}
```

The wrong version stops with `This type has a constructor, so it must be initialized here.` Variants of a sealed class extend the sealed parent, and extending a class requires calling its constructor, which is what the parentheses do. The fix is to add them: `object Pending : Status()`. If the parent has constructor parameters, you pass them in: `class Variant(val foo: Int) : Parent(foo)`. As a habit, when a variant extends a class (`: Parent`), follow the parent type with parentheses just like a constructor call.

**Error 2: Matching a class variant by value instead of by type**

```kotlin
// Wrong
fun marker(status: Status): String = when (status) {
    Status.Pending -> "[ ]"
    Status.InProgress -> "[~]"
    Status.Done -> "[x]"
    Status.Cancelled -> "[!]"
}

// Correct
fun marker(status: Status): String = when (status) {
    is Status.Pending -> "[ ]"
    is Status.InProgress -> "[~]"
    is Status.Done -> "[x]"
    is Status.Cancelled -> "[!]"
}
```

With the four-variant `Status` from this lesson, the wrong version stops with two errors: `Classifier 'data class Cancelled : Status' does not have a companion object, so it cannot be used as an expression.` and `'when' expression must be exhaustive. Add the 'is Cancelled' branch or an 'else' branch.` For object variants like `Pending`, writing `Status.Pending ->` works because there is exactly one `Pending` value to compare against. For class variants like `Cancelled`, there are many possible values (one per reason), so `Status.Cancelled` is not a value at all; you have to match by type with `is Status.Cancelled`. As a habit, use the `is Type` form consistently for every variant in a sealed class match; it is uniform and works for both object and class variants.

**Error 3: Missing a variant in a when**

```kotlin
// Wrong
fun statusText(status: Status): String = when (status) {
    is Status.Pending -> "pending"
    is Status.Done -> "done"
}

// Correct
fun statusText(status: Status): String = when (status) {
    is Status.Pending -> "pending"
    is Status.InProgress -> "in progress"
    is Status.Done -> "done"
    is Status.Cancelled -> "cancelled (${status.reason})"
}
```

The wrong version stops with `'when' expression must be exhaustive. Add the 'is Cancelled', 'InProgress' branches or an 'else' branch.` Without an `else`, a `when` on a sealed type must cover every variant, and the compiler names exactly which ones are missing. The fix is to add the missing branches. As a habit, when you write a `when` on a sealed type, list every variant up front and fill in the bodies, rather than writing a few branches and adding more later.

---

## 9. Exercises

These exercises practice sealed classes.

**Exercise 1:** Define a sealed class `Shape` with three variants: `Circle(val radius: Double)`, `Square(val side: Double)`, and `Rectangle(val width: Double, val height: Double)`. Write a function `area(shape: Shape): Double` that returns the area of any shape, using exhaustive `when`. Test with examples of each variant.

**Exercise 2:** Define a sealed class `LoadResult` with variants `Loading`, `Success(val data: String)`, and `Error(val message: String)`. Write a function `describe(result: LoadResult): String` that returns a user-friendly description for each case. Test by calling it with each variant.

**Exercise 3:** Add an `Updated(val newDescription: String)` variant to Catatku's `Status` (just as an exercise; we will not keep it). Watch the compiler complain about every existing `when`. Fix each one with a sensible behavior for the new variant.

---

## 10. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

This exercise practices sealed classes with class variants that carry data.

```kotlin
import kotlin.math.PI

sealed class Shape {
    data class Circle(val radius: Double) : Shape()
    data class Square(val side: Double) : Shape()
    data class Rectangle(val width: Double, val height: Double) : Shape()
}

fun area(shape: Shape): Double = when (shape) {
    is Shape.Circle -> PI * shape.radius * shape.radius
    is Shape.Square -> shape.side * shape.side
    is Shape.Rectangle -> shape.width * shape.height
}

fun main() {
    val shapes = listOf(
        Shape.Circle(5.0),
        Shape.Square(4.0),
        Shape.Rectangle(3.0, 6.0)
    )
    
    for (shape in shapes) {
        println("$shape -> area = ${"%.2f".format(area(shape))}")
    }
}
```

Save and run. Output:

```text
Circle(radius=5.0) -> area = 78.54
Square(side=4.0) -> area = 16.00
Rectangle(width=3.0, height=6.0) -> area = 18.00
```

The sealed class `Shape` has three variants, each a data class carrying its own dimensions. The `area` function uses exhaustive `when` to handle each variant; inside each branch, the smart cast lets us access the variant-specific properties (`shape.radius` inside the `Circle` branch, `shape.side` inside the `Square` branch, and so on). The `import kotlin.math.PI` brings in the standard mathematical constant.

The function is exhaustive: every variant of `Shape` is handled, so no `else` is needed. If you added a new variant like `Triangle(...)`, the compiler would point at this `area` function and require you to add a branch for it, with whatever formula is appropriate.

Another option is to put the area computation inside each variant as a method:

```kotlin
import kotlin.math.PI

sealed class Shape {
    abstract fun area(): Double
    
    data class Circle(val radius: Double) : Shape() {
        override fun area() = PI * radius * radius
    }
    data class Square(val side: Double) : Shape() {
        override fun area() = side * side
    }
    data class Rectangle(val width: Double, val height: Double) : Shape() {
        override fun area() = width * height
    }
}

fun main() {
    val shapes = listOf(Shape.Circle(5.0), Shape.Square(4.0), Shape.Rectangle(3.0, 6.0))
    for (shape in shapes) {
        println("$shape -> area = ${"%.2f".format(shape.area())}")
    }
}
```

Save and run. Output:

```text
Circle(radius=5.0) -> area = 78.54
Square(side=4.0) -> area = 16.00
Rectangle(width=3.0, height=6.0) -> area = 18.00
```

The `abstract fun area(): Double` declares that every variant must provide an implementation. Each variant overrides it with its own formula. The advantage is that the area logic lives close to the data it operates on; the disadvantage is that you have to update three places when changing the abstract interface, which is more friction than a single function with a `when`.

Both styles are valid; the choice depends on whether the operation feels like a property of the shape (member function) or a separate concern (free function with `when`). For Catatku's `Status`, we used free functions because the various status-related operations (marker, statusText, isTerminal) are presentation logic that does not feel like part of the status itself.

**Solution for Exercise 2:**

This exercise mixes an `object` variant (no data) with two data class variants.

```kotlin
sealed class LoadResult {
    object Loading : LoadResult()
    data class Success(val data: String) : LoadResult()
    data class Error(val message: String) : LoadResult()
}

fun describe(result: LoadResult): String = when (result) {
    is LoadResult.Loading -> "Loading, please wait..."
    is LoadResult.Success -> "Loaded: ${result.data}"
    is LoadResult.Error -> "Something went wrong: ${result.message}"
}

fun main() {
    val results = listOf(
        LoadResult.Loading,
        LoadResult.Success("3 entries"),
        LoadResult.Error("file not found")
    )

    for (r in results) {
        println(describe(r))
    }
}
```

Save and run. Output:

```text
Loading, please wait...
Loaded: 3 entries
Something went wrong: file not found
```

`Loading` is an `object` because there is nothing to say about it besides "still loading". `Success` and `Error` are data classes because each one carries a different piece of information. Inside the `is LoadResult.Success` branch, the smart cast lets us read `result.data`, and inside `is LoadResult.Error` we can read `result.message`. The `when` has no `else`, so adding a fourth variant later would make the compiler point straight at `describe`.

**Solution for Exercise 3:**

Start from the complete program in Section 7 and add the new variant to `Status`:

```kotlin
data class Updated(val newDescription: String) : Status()
```

Save and run. The compiler reports the same message three times, once for each function that branches on `Status`:

```text
'when' expression must be exhaustive. Add the 'is Updated' branch or an 'else' branch.
```

Here is one way to fix every `when`, shown as a complete program with a small `main` that tries each kind of status:

```kotlin
sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    data class Cancelled(val reason: String) : Status()
    data class Updated(val newDescription: String) : Status()
}

fun marker(status: Status): String = when (status) {
    is Status.Pending -> "[ ]"
    is Status.InProgress -> "[~]"
    is Status.Done -> "[x]"
    is Status.Cancelled -> "[!]"
    is Status.Updated -> "[*]"
}

fun statusText(status: Status): String = when (status) {
    is Status.Pending -> "pending"
    is Status.InProgress -> "in progress"
    is Status.Done -> "done"
    is Status.Cancelled -> "cancelled (${status.reason})"
    is Status.Updated -> "updated to '${status.newDescription}'"
}

fun isTerminal(status: Status): Boolean = when (status) {
    is Status.Done -> true
    is Status.Cancelled -> true
    is Status.Pending -> false
    is Status.InProgress -> false
    is Status.Updated -> false
}

fun main() {
    val statuses = listOf(
        Status.Pending,
        Status.Done,
        Status.Cancelled("rescheduled"),
        Status.Updated("Pay rent and water bill")
    )

    for (s in statuses) {
        println("${marker(s)} ${statusText(s)}, terminal: ${isTerminal(s)}")
    }
}
```

Save and run. Output:

```text
[ ] pending, terminal: false
[x] done, terminal: true
[!] cancelled (rescheduled), terminal: true
[*] updated to 'Pay rent and water bill', terminal: false
```

Each function got one new branch. `marker` uses `[*]` to flag an updated entry, `statusText` reads the variant's `newDescription` thanks to the smart cast, and `isTerminal` treats an update as still active. The point of the exercise is the workflow: you changed the type in one place, and the compiler gave you a precise to-do list of every function that needed a decision about the new variant. Remove the `Updated` variant again before moving on, since Catatku does not keep it.

---

## 11. Understanding Why Sealed Classes Beat Strings

Modeling status as a string seems convenient at first: you write `status = "Pending"` and move on. The cost only becomes visible when the codebase grows and bugs start to surface. Understanding the bug categories that strings allow and sealed classes prevent makes the case for sealed classes concrete.

The first bug category is typos. With strings, nothing stops you from writing `status = "Pendng"` (missing letter) or `status = "pending"` (wrong capitalization) at one place in the code while every other place uses `"Pending"`. The typo creates a status value that is technically valid (any string is a valid string) but semantically wrong: code that checks for "Pending" misses this entry. The bug might survive testing because the typo is in an uncommon code path. Sealed classes prevent this entirely: `Status.Pending` is a known type at compile time, and the compiler refuses to compile `Status.Pendng` because no such variant exists.

The second bug category is the "forgotten case" problem. With strings, code that branches on the status (using `if/else` or `when` with strings) typically has a fallback for "anything else", which silently catches new statuses introduced later. The fallback might be reasonable (treat unknown statuses as pending) or might be a bug (unknown statuses get a wrong marker), but either way, the code does not break loudly when a new status is introduced. With sealed classes and exhaustive `when`, the compiler refuses to compile any `when` that misses a variant, forcing every branch site to acknowledge the new variant. Refactoring is dramatically safer because the compiler walks you through every place that needs updating.

The third bug category is implicit type pollution. With a `String` field, code that consumes the entry has to know the convention for what status strings can appear. Any documentation about the valid values lives in comments or wikis, not in the code. With a sealed class field, the type itself is the documentation: anyone reading the `Entry` data class sees that `status: Status`, and looking at `Status` shows them every valid value. The contract is precise and verifiable.

The fourth bug category is variant-specific data. With strings, if some statuses carry extra data (like a cancellation reason), you have to either pollute the entry with an unrelated field (`val cancellationReason: String?`) or use a separate parallel field (`val cancellation: CancellationDetails?`). Both are awkward, and both leak the implementation of "cancellation" into the structure of every entry, even ones that are not cancelled. With a sealed class, the cancellation reason lives inside the `Cancelled` variant, where it belongs. Other variants do not see it and do not need to know about it.

The cost of using sealed classes is small. The class declaration is a few lines longer than a string. The variants need to be created with `Status.Pending` rather than the literal `"Pending"`. The `is` checks in `when` are slightly different syntax. None of these are significant burdens, especially when weighed against the bug categories sealed classes prevent. Most experienced Kotlin programmers default to sealed classes (or enums for the simpler cases) for any field that has a fixed set of meaningful values, and the time savings on debugging more than cover the upfront design cost.

A subtler benefit is that designing with sealed classes encourages you to think about your data carefully. When you sit down to model a status, you have to decide upfront which states are valid and which carry extra data. This forces you to make design decisions explicit instead of letting them emerge as the codebase grows. The upfront effort produces cleaner code, and the explicit design becomes documentation that does not go stale because the compiler enforces it.

---

## Next Up - Lesson 12

Sealed classes are Kotlin's mechanism for closed type hierarchies. The `sealed` keyword on a class limits the subclasses to those declared in the same package and module (in this course, always the same file), which lets the compiler enumerate every possible value of the type at compile time. Variants without data are typically `object` declarations; variants with data are `class` (or `data class`) declarations. The exhaustive `when` expression checks every variant and requires you to handle each one, refusing to compile if any case is missed. Smart casts inside `is` branches give you access to variant-specific data. Sealed classes contrast with enum classes (Lesson 12) by allowing variant-specific fields, while enums require all variants to share the same shape. Catatku's `Status` is now a sealed class with four variants: `Pending`, `InProgress`, `Done`, and `Cancelled(reason)`, and the rest of the course will use this type wherever status information matters.

In Lesson 12 you will learn enum classes (the closely related but simpler tool for fixed sets of named constants), inheritance with `open` classes and `override`, abstract classes, and interfaces. The combination of all these tools, plus sealed classes, gives you the full type-modeling vocabulary of Kotlin.
