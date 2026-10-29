## 1. Before You Begin

Lesson 13 introduced higher-order functions and the rich collection of standard library functions like `filter`, `map`, and `count`. Looking at those functions more carefully, you might have noticed something interesting. Functions like `filter` are not declared as members of the `List` class, yet they look and feel like methods you call on a list. The mechanism that makes this work is called extension functions, and it is one of the features that gives Kotlin's standard library its distinctive sense of cohesion. By the end of this lesson, you will know how to define your own extension functions and properties, when to use them, and what makes them useful for organizing code in ways that traditional methods cannot match.

Extension functions let you add methods to types you do not own, including types from the standard library, third-party libraries, or even Java types. The added methods feel like part of the type when you call them, but they are actually defined separately in your own code. The mechanism is purely syntactic; it does not modify the original type, does not break encapsulation, and does not require recompilation of anything. Combined with the rest of Kotlin's features, extension functions enable patterns like fluent APIs and small focused utilities that would be awkward to express in Java without polluting the type with new methods.

### What You'll Build

A series of extension functions that add useful operations to existing types. You will add a `summary()` extension on `Entry` that produces a one-line description, an `isOverdue` extension property on `Entry` (with a stub implementation that we will replace in a real app), a `marker()` extension on `Status` that produces a display marker, and a few helpers on `List<Entry>` for filtering and counting. By the end the code style for Catatku is closer to its final form, with operations attached to the types they belong to via extensions.

### What You'll Learn

- ✅ How to declare an extension function with `fun ReceiverType.name(...)` syntax
- ✅ How extension properties work with `val ReceiverType.name: Type get() = ...`
- ✅ How extensions are dispatched statically based on declared (not actual) type
- ✅ When to use extensions versus member functions versus top-level functions
- ✅ Common idioms from the Kotlin standard library that are extensions

### What You'll Need

- The `catatku` Gradle project from previous lessons
- A working understanding of functions, classes, and lambdas
- About thirty-five minutes
- Patience for the small but important distinction between extensions and member functions

---

## 2. Defining Your First Extension

An extension function looks almost like a regular function, with one extra piece: a "receiver type" before the function name. Inside the function body, you refer to the receiver as `this` (which can usually be omitted, just like inside member functions).

### Step 1: A Simple Extension on String

Open `Main.kt` and replace its contents with this experiment:

```kotlin
fun String.shout(): String = this.uppercase() + "!"

fun main() {
    val phrase = "hello world"
    println(phrase.shout())
    println("kotlin".shout())
}
```

Save and run. Output:

```text
HELLO WORLD!
KOTLIN!
```

The function declaration `fun String.shout(): String = ...` says "I am defining an extension function named `shout` on the receiver type `String`, returning a `String`". Inside the function body, `this` refers to the string the function was called on. We use `this.uppercase()` to uppercase the receiver and append an exclamation mark. The `this.` prefix is optional (we could write just `uppercase()`); the receiver is implicitly available the same way `this` is implicitly available inside member functions.

At the call site, the syntax looks identical to a regular method call: `phrase.shout()` or `"kotlin".shout()`. There is no visible distinction between a member function and an extension function from the caller's perspective. This is the entire point of extensions: they look and feel like methods, while being defined externally.

### Step 2: Extensions Cannot Access Private State

A crucial detail about extensions is that they only see the public API of the receiver type. They cannot access private fields or call private methods. This makes extensions safe to add anywhere; you cannot accidentally break encapsulation.

```kotlin
class Container(private val secret: String) {
    fun reveal(): String = secret
}

fun Container.tryToAccessSecret(): String {
    // return this.secret would not compile, because secret is private
    return this.reveal()  // ok, reveal() is public
}

fun main() {
    val c = Container("hidden value")
    println(c.tryToAccessSecret())
}
```

Save and run. Output:

```text
hidden value
```

The extension function can call `reveal()` (a public method) but cannot access `secret` directly because it is private. From the perspective of access control, an extension is treated as if it were defined outside the class. This is a deliberate design choice: extensions add convenience without weakening the class's encapsulation guarantees.

### Step 3: Extensions on Generic Types

You can write extensions on generic types too. Common examples are extensions on `List<T>` or `String` that work for any element type:

```kotlin
fun <T> List<T>.secondOrNull(): T? {
    return if (this.size >= 2) this[1] else null
}

fun main() {
    val nums = listOf(10, 20, 30)
    val singleton = listOf("only")
    val empty: List<String> = emptyList()
    
    println(nums.secondOrNull())
    println(singleton.secondOrNull())
    println(empty.secondOrNull())
}
```

Save and run. Output:

```text
20
null
null
```

The extension `<T> List<T>.secondOrNull(): T?` introduces a type parameter `T` (declared in angle brackets after `fun`) and uses it both as part of the receiver type (`List<T>`) and as part of the return type (`T?`). The function returns the second element or null if the list is too short.

Generic extensions are the foundation of the standard library's collection methods. `filter`, `map`, `count`, and most of the others are extensions on generic collection types, which is why they work uniformly across `List<Int>`, `List<String>`, `List<Entry>`, and any other element type.

---

## 3. Extension Properties

Extension functions add methods. Extension properties add property-like accessors. They are useful when a value would be more naturally described as an attribute of the type than as a method call.

### Step 1: Add an Extension Property

```kotlin
val String.firstThreeChars: String
    get() = if (this.length >= 3) this.substring(0, 3) else this

fun main() {
    println("Catatku".firstThreeChars)
    println("hi".firstThreeChars)
    println("Kotlin programming".firstThreeChars)
}
```

Save and run. Output:

```text
Cat
hi
Kot
```

The declaration `val String.firstThreeChars: String` introduces an extension property on `String` of type `String`. The `get() = ...` after the declaration is the getter, computed each time the property is read. There is no backing field (extension properties cannot have backing fields because the original type does not know about them), so all extension properties must define a custom getter.

At the call site, accessing the extension looks like accessing a regular property: `name.firstThreeChars` rather than `name.firstThreeChars()`. The choice between an extension function and an extension property is the same as the choice between a regular method and a regular property: use a property when the value is conceptually a state of the object, and use a function when there is action involved or parameters are needed.

### Step 2: Compare to a Method Equivalent

The same logic could have been written as a function:

```kotlin
fun String.firstThreeChars(): String = 
    if (this.length >= 3) this.substring(0, 3) else this

fun main() {
    println("Catatku".firstThreeChars())  // notice the parentheses
}
```

Save and run. Output:

```text
Cat
```

Both work. The extension function has parentheses at call sites because it is a method call; the extension property does not. As a habit, prefer extension property when the result is "an attribute of the value", and prefer extension function when the result depends on parameters or when the operation is more like an action.

For Catatku, things like `entry.summary` or `entry.isOverdue` feel like properties (attributes of the entry), so extension properties make sense. Things like `list.findById(7)` (with a parameter) or `entry.markDone()` (with implied action) feel like functions.

### Step 3: Mutable Extension Properties

If the receiver type has a setter that modifies state, you can add a `var` extension property with a setter:

```kotlin
import java.util.concurrent.atomic.AtomicInteger

class Counter {
    private val value = AtomicInteger(0)
    fun get(): Int = value.get()
    fun set(n: Int) { value.set(n) }
}

var Counter.current: Int
    get() = this.get()
    set(value) { this.set(value) }

fun main() {
    val c = Counter()
    c.current = 42
    println(c.current)
    c.current = 99
    println(c.current)
}
```

Save and run. Output:

```text
42
99
```

The mutable extension property has both a getter and a setter, both delegating to the original class's methods. Mutable extension properties are rarer than read-only ones, but they are useful when you want to expose a clean property interface over a class that uses methods internally.

For Catatku we will not use mutable extension properties; our extension properties are all read-only views derived from the entry's fields.

---

## 4. Extensions on Catatku Types

Now let us add extensions that fit naturally with the Catatku domain. We will use the `Entry`, `Status`, and `Priority` types from Lessons 10 through 12.

### Step 1: Set Up the Domain Types

Replace `Main.kt` with the type declarations and a few extensions:

```kotlin
enum class Priority(val displayName: String) {
    HIGH("High"), MEDIUM("Medium"), LOW("Low");
    
    fun shortLabel(): String = displayName.first().toString()
}

sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    data class Cancelled(val reason: String) : Status()
}

data class Entry(
    val id: Int,
    val description: String,
    val priority: Priority = Priority.MEDIUM,
    val status: Status = Status.Pending,
    val createdAt: String = "2026-04-26"
)

// Extension property on Status producing a one-character marker
val Status.marker: String
    get() = when (this) {
        is Status.Pending -> "[ ]"
        is Status.InProgress -> "[~]"
        is Status.Done -> "[x]"
        is Status.Cancelled -> "[!]"
    }

// Extension property on Entry producing a one-line summary
val Entry.summary: String
    get() = "${this.status.marker} (${this.priority.shortLabel()}) ${this.id}. ${this.description}"

// Extension function on Entry to produce a "marked done" copy
fun Entry.markDone(): Entry = this.copy(status = Status.Done)

// Extension function on Entry to produce a "cancelled with reason" copy
fun Entry.cancel(reason: String): Entry = this.copy(status = Status.Cancelled(reason))

fun main() {
    val e = Entry(1, "Pay rent", priority = Priority.HIGH)
    println(e.summary)
    
    val done = e.markDone()
    println(done.summary)
    
    val cancelled = e.cancel("rescheduled")
    println(cancelled.summary)
}
```

Save and run. Output:

```text
[ ] (H) 1. Pay rent
[x] (H) 1. Pay rent
[!] (H) 1. Pay rent
```

We added four extensions: `Status.marker` (an extension property), `Entry.summary` (another extension property), and two extension functions on `Entry`: `markDone` and `cancel`. Each one operates on the receiver via `this` and returns either a derived value (for the properties) or a new instance (for the functions).

The functions like `markDone()` are particularly useful. They look like methods on `Entry` but are declared externally, which means we did not have to put `markDone` and `cancel` directly on the data class. If we had, the data class would be larger and the methods would be tied to the class. By using extensions, the methods stay nearby (in the same file or module) but do not pollute the data class declaration. As Catatku grows, we can add more extensions without the `Entry` class getting bloated.

### Step 2: Extensions on Lists of Entries

We can also write extensions on `List<Entry>` for collection-level operations. The file below repeats the domain types and the `marker` and `summary` extensions from Step 1, so it compiles and runs on its own:

```kotlin
enum class Priority(val displayName: String) {
    HIGH("High"), MEDIUM("Medium"), LOW("Low");
    
    fun shortLabel(): String = displayName.first().toString()
}

sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    data class Cancelled(val reason: String) : Status()
}

data class Entry(
    val id: Int,
    val description: String,
    val priority: Priority = Priority.MEDIUM,
    val status: Status = Status.Pending,
    val createdAt: String = "2026-04-26"
)

val Status.marker: String
    get() = when (this) {
        is Status.Pending -> "[ ]"
        is Status.InProgress -> "[~]"
        is Status.Done -> "[x]"
        is Status.Cancelled -> "[!]"
    }

val Entry.summary: String
    get() = "${this.status.marker} (${this.priority.shortLabel()}) ${this.id}. ${this.description}"

fun List<Entry>.findById(id: Int): Entry? = this.firstOrNull { it.id == id }

fun List<Entry>.byPriority(priority: Priority): List<Entry> = 
    this.filter { it.priority == priority }

fun List<Entry>.activeOnly(): List<Entry> = 
    this.filter { it.status is Status.Pending || it.status is Status.InProgress }

fun List<Entry>.summarize(): String = 
    "${this.size} entries (${this.activeOnly().size} active)"

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", Priority.HIGH),
        Entry(2, "Read for fun", Priority.LOW),
        Entry(3, "Finish Kotlin course", Priority.HIGH),
        Entry(4, "Call dentist", Priority.MEDIUM, Status.Done),
        Entry(5, "Walk the dog", Priority.MEDIUM, Status.Cancelled("rainy day"))
    )
    
    println(entries.summarize())
    
    val highPriority = entries.byPriority(Priority.HIGH)
    println("\nHigh priority (${highPriority.size} found):")
    highPriority.forEach { println("  ${it.summary}") }
    
    val found = entries.findById(3)
    println("\nFound entry 3: ${found?.summary}")
    
    val notFound = entries.findById(99)
    println("Found entry 99: ${notFound?.summary ?: "(not found)"}")
}
```

Save and run. Output:

```text
5 entries (3 active)

High priority (2 found):
  [ ] (H) 1. Pay rent
  [ ] (H) 3. Finish Kotlin course

Found entry 3: [ ] (H) 3. Finish Kotlin course
Found entry 99: (not found)
```

Each list extension is a small focused operation that calls existing methods on `List` (`filter`, `firstOrNull`, `size`) and adds Catatku-specific semantics. The extensions read like methods of `List<Entry>`: `entries.findById(3)`, `entries.byPriority(Priority.HIGH)`, `entries.activeOnly()`. They are easy to discover via IDE autocomplete and easy to read at the call sites.

This pattern, where you add domain-specific extensions to standard library collection types, is one of the most common uses of extension functions in real Kotlin code. The extensions group naturally with the domain types they operate on, even though they live separately from the type declarations themselves.

### Compare to Member Functions

Could we have made `markDone`, `cancel`, and `summary` regular member functions on `Entry`? Yes. Both styles work. The choice is mostly about how you want to organize the code.

Member functions are right when the operation is so closely tied to the type that it should always be available wherever the type is used, when the operation needs access to private fields, or when the operation is part of the type's core contract. Extensions are right when the operation is one of many possible utilities that does not need to be in the core class, when access to private state is unnecessary, when the operation might be defined in a different file or module, or when you want to add operations to types you do not own (like standard library types).

For Catatku, things like `summary` and `markDone` could go either way. We chose extensions because the data class is intentionally small and focused (just the data), with operations layered on via extensions. This split keeps the type definition itself easy to read and lets the operations be organized by concern (display extensions, mutation extensions, query extensions) rather than mashed into one class.

---

## 5. How Extensions Are Dispatched

Extension functions look like methods but behave slightly differently when polymorphism is involved. Understanding this difference prevents subtle bugs.

### Step 1: Static Dispatch

Extension functions are dispatched statically based on the declared type of the receiver, not the runtime type. This is the opposite of member functions, which use dynamic dispatch.

```kotlin
open class Animal
class Dog : Animal()

fun Animal.speak(): String = "I am an animal"
fun Dog.speak(): String = "I am a dog"

fun main() {
    val d: Dog = Dog()
    val a: Animal = d  // same instance, different declared type
    
    println(d.speak())  // calls Dog.speak: "I am a dog"
    println(a.speak())  // calls Animal.speak: "I am an animal"
}
```

Save and run. Output:

```text
I am a dog
I am an animal
```

Even though `a` and `d` refer to the same `Dog` instance, the extension function called depends on the declared type of the variable. When we declared `a: Animal`, the call `a.speak()` resolves to `Animal.speak()` because the compiler sees the declared type and picks the matching extension. With member functions, the runtime type would matter and `Dog`'s override would be called.

This static dispatch is important to understand because it can be surprising. If you have an extension on a parent type and another on a child type, calling through a parent-typed reference always uses the parent's extension. The runtime type does not change the dispatch.

### When This Matters in Practice

For extensions on data classes, sealed classes, and final classes (which is most of what Catatku uses), this difference is rarely visible because there is no inheritance involved. The receiver type is the only type, and the dispatch is unambiguous.

The static dispatch only becomes a potential pitfall when you have an inheritance hierarchy and define extensions on multiple levels. As a habit, do not define extensions with the same name on a parent type and a subtype. If you find yourself wanting to do that, the operation probably should be a member function (which would dispatch dynamically) rather than an extension.

For Catatku's flat type structure (data classes, sealed classes with separate variants, no inheritance), this consideration does not come up.

### Step 2: Member Functions Win Over Extensions

When a member function and an extension function have the same name, signature, and receiver, the member function wins. This is the rule that prevents extensions from accidentally overriding existing methods.

```kotlin
class Phone {
    fun ring() = println("Ring ring (member)")
}

fun Phone.ring() = println("Ring ring (extension)")

fun main() {
    val p = Phone()
    p.ring()  // calls the member function
}
```

Save and run. Output:

```text
Ring ring (member)
```

The compiler picks the member function over the extension. This is intentional: extensions are an additive feature that should not silently override existing behavior. If you find yourself with a name collision like this, you can either rename the extension to something more specific or use the explicit syntax to call the extension (which is rarely worth the complexity).

For Catatku we will not run into this because our extensions are clearly named (`summary`, `markDone`) and do not collide with any member functions.

---

## 6. Common Idioms from the Standard Library

Most of the collection operations from Lesson 13 are extension functions. Recognizing them as extensions explains why they feel so cohesive and why you can mix and match them naturally.

### filter, map, joinToString as Extensions

The signatures of standard library functions like `filter` and `map` are extensions on `Iterable<T>` or specific collection types:

```text
public inline fun <T> Iterable<T>.filter(predicate: (T) -> Boolean): List<T>
public inline fun <T, R> Iterable<T>.map(transform: (T) -> R): List<R>
public fun <T> Iterable<T>.joinToString(separator: CharSequence = ", ", ...): String
```

These are simplified signatures as they appear in the standard library documentation, shown for reading only.

These are extensions on `Iterable<T>`, which is the parent interface of `List`, `Set`, and many other collection types. Because they are extensions, they work uniformly across any iterable type. When we write `tasks.filter { ... }`, we are calling the extension function `Iterable.filter` with `tasks` as the receiver. The static-dispatch rule does not bite here because no concrete collection type overrides these names.

### Step 1: Define Your Own filter-like Extensions

You can write your own extensions in the same style:

```kotlin
fun <T> List<T>.firstHalf(): List<T> = this.take(this.size / 2)
fun <T> List<T>.secondHalf(): List<T> = this.drop(this.size / 2)

fun main() {
    val tasks = listOf("a", "b", "c", "d", "e", "f")
    println("First half: ${tasks.firstHalf()}")
    println("Second half: ${tasks.secondHalf()}")
}
```

Save and run. Output:

```text
First half: [a, b, c]
Second half: [d, e, f]
```

Each extension takes the receiver list, applies a standard library operation (`take` or `drop`), and returns the result. Defining utilities like this is one of the most common uses of extensions in real Kotlin projects: pulling out small operations into named extensions makes the calling code more expressive.

### Recognize Extensions in IDE Autocomplete

When you type `someList.` in IntelliJ, the autocomplete dropdown shows methods and extensions together, often distinguished by a small icon (a member function has an "M" or method icon, an extension has a different icon). This visual distinction helps you understand which methods are part of the original type and which are extensions added in your code or in libraries.

For Catatku, the extensions we defined (`findById`, `byPriority`, `activeOnly`, `summarize`) all show up in autocomplete on `List<Entry>` values. From the calling code's perspective, they are indistinguishable from member methods, which is exactly the point.

---

## 7. Run and Test

Combine everything into a comprehensive example using extensions for Catatku.

### Step 1: A Full Example

Replace `Main.kt` with this:

```kotlin
enum class Priority(val displayName: String) {
    HIGH("High"), MEDIUM("Medium"), LOW("Low");
    
    fun shortLabel(): String = displayName.first().toString()
}

sealed class Status {
    object Pending : Status() { override fun toString() = "Pending" }
    object InProgress : Status() { override fun toString() = "InProgress" }
    object Done : Status() { override fun toString() = "Done" }
    data class Cancelled(val reason: String) : Status()
}

data class Entry(
    val id: Int,
    val description: String,
    val priority: Priority = Priority.MEDIUM,
    val status: Status = Status.Pending,
    val createdAt: String = "2026-04-26"
)

// === Extensions on Status ===

val Status.marker: String
    get() = when (this) {
        is Status.Pending -> "[ ]"
        is Status.InProgress -> "[~]"
        is Status.Done -> "[x]"
        is Status.Cancelled -> "[!]"
    }

val Status.isTerminal: Boolean
    get() = this is Status.Done || this is Status.Cancelled

// === Extensions on Entry ===

val Entry.summary: String
    get() = "${this.status.marker} (${this.priority.shortLabel()}) ${this.id}. ${this.description}"

val Entry.isActive: Boolean
    get() = !this.status.isTerminal

fun Entry.markDone(): Entry = this.copy(status = Status.Done)
fun Entry.markInProgress(): Entry = this.copy(status = Status.InProgress)
fun Entry.cancel(reason: String): Entry = this.copy(status = Status.Cancelled(reason))
fun Entry.withPriority(p: Priority): Entry = this.copy(priority = p)

// === Extensions on List<Entry> ===

fun List<Entry>.findById(id: Int): Entry? = this.firstOrNull { it.id == id }
fun List<Entry>.activeOnly(): List<Entry> = this.filter { it.isActive }
fun List<Entry>.byPriority(p: Priority): List<Entry> = this.filter { it.priority == p }
fun List<Entry>.totalDescriptionChars(): Int = this.sumOf { it.description.length }

fun main() {
    var entries = listOf(
        Entry(1, "Pay rent", Priority.HIGH),
        Entry(2, "Read for fun", Priority.LOW),
        Entry(3, "Finish Kotlin course", Priority.HIGH),
        Entry(4, "Call dentist", Priority.MEDIUM, Status.Done),
        Entry(5, "Walk the dog")
    )
    
    println("=== Initial state ===")
    entries.forEach { println(it.summary) }
    
    println("\n=== Active entries ===")
    entries.activeOnly().forEach { println(it.summary) }
    
    println("\n=== High priority ===")
    entries.byPriority(Priority.HIGH).forEach { println(it.summary) }
    
    // Update an entry by producing a new list
    entries = entries.map { entry ->
        if (entry.id == 5) entry.markInProgress() else entry
    }
    
    println("\n=== After marking #5 in progress ===")
    entries.forEach { println(it.summary) }
    
    val found = entries.findById(3)
    println("\n=== Looked up entry #3 ===")
    println(found?.summary ?: "(not found)")
    
    println("\n=== Statistics ===")
    println("Total entries: ${entries.size}")
    println("Active entries: ${entries.activeOnly().size}")
    println("Total description chars: ${entries.totalDescriptionChars()}")
}
```

Save and run.

### Step 2: Read the Output

Output:

```text
=== Initial state ===
[ ] (H) 1. Pay rent
[ ] (L) 2. Read for fun
[ ] (H) 3. Finish Kotlin course
[x] (M) 4. Call dentist
[ ] (M) 5. Walk the dog

=== Active entries ===
[ ] (H) 1. Pay rent
[ ] (L) 2. Read for fun
[ ] (H) 3. Finish Kotlin course
[ ] (M) 5. Walk the dog

=== High priority ===
[ ] (H) 1. Pay rent
[ ] (H) 3. Finish Kotlin course

=== After marking #5 in progress ===
[ ] (H) 1. Pay rent
[ ] (L) 2. Read for fun
[ ] (H) 3. Finish Kotlin course
[x] (M) 4. Call dentist
[~] (M) 5. Walk the dog

=== Looked up entry #3 ===
[ ] (H) 3. Finish Kotlin course

=== Statistics ===
Total entries: 5
Active entries: 4
Total description chars: 64
```

Walk through what each piece contributed. The extensions on `Status` (`marker`, `isTerminal`) provide presentation and predicate logic for the status type. The extensions on `Entry` (`summary`, `isActive`, `markDone`, `markInProgress`, `cancel`, `withPriority`) wrap the status changes in convenient methods that return new immutable entries. The extensions on `List<Entry>` (`findById`, `activeOnly`, `byPriority`, `totalDescriptionChars`) make the calling code read fluently.

The result is that `main` reads like a description of what we are doing, not how we are doing it. Each line says something specific: "show all entries", "show active entries", "show high priority", "find entry by id", and so on. The actual implementations are pushed into named extensions where they can be reused and tested in isolation.

### Step 3: Try Adding More Extensions

To get a feel for how natural extensions become, try adding a few more. An `entries.cancelAllPending(reason: String)` that returns a new list with every pending entry cancelled. An `entries.byStatus()` that returns `Map<Status, List<Entry>>` grouped by status. An `entry.daysSinceCreated()` that parses the createdAt and computes a difference (you can fake this with a fixed reference date). Each addition takes a few lines and makes new operations available naturally on the receiver type.

The pattern of "add an extension when you find yourself writing the same operation more than once" is one of the small habits that produces clean Kotlin code over time. Extensions are cheap to add and easy to remove if they turn out not to be useful.

---

## 8. Fix the Errors in Your Code

Three extension-related mistakes are common. Each one below shows the wrong version first, then the corrected version.

**Error 1: Reading private state from an extension**

```kotlin
// Wrong
class Box(private val secret: String)

fun Box.loudPeek(): String = this.secret.uppercase()

// Correct
class Box(private val secret: String) {
    fun peek(): String = secret
}

fun Box.loudPeek(): String = this.peek().uppercase()

fun main() {
    println(Box("treasure").loudPeek())
}
```

The compiler rejects the wrong version with `Cannot access 'val secret: String': it is private in '/Box'.` Extension functions are treated as if they were defined outside the class, so they only see the public API. The corrected version adds a public `peek()` member, and the extension builds on it, printing `TREASURE`. As a habit, when an extension needs private state, that is a signal that the operation should probably be a member function (which has full access).

**Error 2: Giving an extension the same name as a member function**

```kotlin
// Wrong
class Phone {
    fun ring() = "Ring"
}

fun Phone.ring() = "Different ring"

// Correct
class Phone {
    fun ring() = "Ring"
}

fun Phone.ringLoudly() = "Different ring"

fun main() {
    println(Phone().ring())
    println(Phone().ringLoudly())
}
```

The wrong version compiles, and the command-line build prints no message about it, but `Phone().ring()` always prints `Ring`. When a member function and an extension function have the same name and signature, the member wins, and the extension is never called through that name. The fix is to rename the extension to something distinct, like `ringLoudly`, or to make the operation a regular method on the class. As a habit, when defining extensions, check the existing methods of the receiver type to avoid name collisions.

**Error 3: Expecting dynamic dispatch from extensions**

```kotlin
// Wrong
open class Vehicle
class Car : Vehicle()

fun Vehicle.describe() = "vehicle"
fun Car.describe() = "car"

// Correct
open class Vehicle {
    open fun describe() = "vehicle"
}

class Car : Vehicle() {
    override fun describe() = "car"
}

fun main() {
    val v: Vehicle = Car()
    println(v.describe())
}
```

With the wrong version, `v.describe()` prints `vehicle` even though `v` holds a `Car`, because extensions are dispatched statically based on the declared type, which is `Vehicle`. The corrected version uses member functions with `open` and `override`, which dispatch on the runtime type, so it prints `car`. If you want dynamic dispatch, use member functions; if you want extensions, accept that they are static and design accordingly. As a habit, do not define extensions with the same name across an inheritance hierarchy; it produces surprising behavior.

---

## 9. Exercises

These exercises practice writing extensions.

**Exercise 1:** Add an extension property `String.wordCount: Int` that returns the number of words (whitespace-separated tokens) in the string. Test it with several strings including the empty string.

**Exercise 2:** Add an extension function `Int.timesPrint(message: String)` that prints `message` `this` many times (where `this` is the integer the extension is called on). Test with a few small numbers.

**Exercise 3:** Add an extension function `List<Int>.average(): Double` that returns the average of the integers. Note that the standard library's `average()` already exists, so your extension would shadow the existing one for `List<Int>` specifically. Test it with a few sample lists.

---

## 10. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

This exercise practices extension properties on a standard library type.

```kotlin
val String.wordCount: Int
    get() = if (this.isBlank()) 0 else this.trim().split("\\s+".toRegex()).size

fun main() {
    println("hello world".wordCount)
    println("the quick brown fox".wordCount)
    println("oneword".wordCount)
    println("".wordCount)
    println("   ".wordCount)
    println("multiple   spaces   between".wordCount)
}
```

Save and run. Output:

```text
2
4
1
0
0
3
```

The extension property `String.wordCount: Int` has a getter that uses several standard library operations. First, it checks `isBlank()` (true if the string is empty or all whitespace), returning 0 in that case. Otherwise, it `trim()`s leading and trailing whitespace, then `split` by the regex `\\s+` (which matches one or more whitespace characters), then takes the `size` of the resulting list.

The regex `\\s+` is necessary to handle multiple spaces between words correctly. A simple `split(" ")` would fail when there are multiple spaces (it would produce empty strings between them). Using a regex with `\\s+` collapses any run of whitespace into a single splitter, which is what "word count" naturally means.

A useful addition would be to handle other whitespace characters like tabs and newlines. The regex `\\s+` already does this, since `\\s` matches any whitespace character. Try testing with `"line1\nline2\tline3".wordCount`; the result should be 3.

Extension properties on standard library types like `String` are particularly useful because they fit naturally with existing code. Anywhere you have a string, you can immediately ask for its word count without writing a helper function elsewhere. The extension feels like a built-in feature of the type, even though it lives in your own code.

**Solution for Exercise 2:**

Inside the extension, `this` is the integer the function was called on, so it can be passed straight to `repeat`.

```kotlin
fun Int.timesPrint(message: String) {
    repeat(this) { println(message) }
}

fun main() {
    3.timesPrint("Hello")
    1.timesPrint("Once")
    0.timesPrint("Never printed")
}
```

Save and run. Output:

```text
Hello
Hello
Hello
Once
```

The call `3.timesPrint("Hello")` makes `this` equal to 3, and `repeat(this)` runs the lambda three times. Calling it on `0` prints nothing at all, because `repeat(0)` never runs its lambda, which is why "Never printed" does not appear. The receiver does not have to be a variable; a literal like `3` works as a receiver just as well.

**Solution for Exercise 3:**

The extension returns `0.0` for an empty list so it never divides by zero.

```kotlin
fun List<Int>.average(): Double {
    if (this.isEmpty()) return 0.0
    return this.sum().toDouble() / this.size
}

fun main() {
    println(listOf(1, 2, 3, 4).average())
    println(listOf(10, 20, 25).average())
    println(emptyList<Int>().average())
}
```

Save and run. Output:

```text
2.5
18.333333333333332
0.0
```

The sum is converted with `toDouble()` before dividing, so the division keeps the fractional part instead of doing integer division. The long `18.333333333333332` is how a `Double` prints by default; you could round it with `"%.2f".format(...)` if you need a tidy display. Because this extension is declared in your own file, the compiler picks it over the standard library's `average()` for `List<Int>`. That is also a difference you can observe: the standard library version returns `NaN` for an empty list, while this one returns `0.0`.

---

## 11. Understanding When to Reach for Extensions

Extensions are a versatile tool, and knowing when they are the right choice (versus member functions or top-level functions) is part of writing idiomatic Kotlin. The decision is not always clear-cut, but a few principles help.

The first principle is "where does the operation belong conceptually?" If the operation is a property of the type itself, in the sense that any instance of that type might naturally have this property (like a `length` on a `String` or a `summary` on an `Entry`), then a member function or extension is the right home. The choice between member and extension is then about access requirements and modularity.

The second principle is access. Member functions can access private state; extensions cannot. If the operation needs private fields, it must be a member. If it does not, an extension is fine and is often preferable because it keeps the type definition smaller and more focused.

The third principle is who owns the type. If you own the type, you can put operations directly on it (as member functions) or as extensions; both are easy to add and maintain. If you do not own the type (it is from the standard library or a third-party library), extensions are your only option for adding operations that look like methods.

The fourth principle is locality and modularity. Extensions can be defined far from the type itself, even in different files or modules. This lets you organize operations by concern: "presentation extensions go in a presentation file, persistence extensions go in a persistence file, query extensions go in a query file". The type definition stays small and is not crowded with operations from many concerns. This pattern scales as the codebase grows.

The fifth principle is reuse and discoverability. Extensions show up in IDE autocomplete on the receiver type, which makes them discoverable to users of the type. If you want an operation to feel like part of the type's API to outside callers, an extension serves that purpose. Top-level functions, by contrast, are not associated with any specific type and have to be discovered by name.

A subtler point is that extensions are syntactic sugar; they compile to ordinary static methods that take the receiver as the first argument. This means extensions have no runtime overhead and are fully interoperable with Java (Java code calls them as static methods). The tradeoff is that they cannot use the dynamic dispatch that member functions have, which is why static dispatch is the rule.

In practice, you will reach for extensions constantly when writing Kotlin. Standard library extensions like `filter`, `map`, and `joinToString` are universal. Your own extensions on standard library types and on your own domain types are the primary way to organize operations cleanly. Member functions are reserved for operations that genuinely need private access or that are part of the type's core contract. Top-level functions are for operations that do not have a single natural receiver, like a parser that takes both a string and a configuration.

The biggest mindset shift from Java is that you stop thinking of operations as belonging to a class. In Kotlin, an operation can live alongside its receiver type without being inside the class declaration. This decoupling is genuinely freeing once you internalize it; you can add operations without modifying the type, change implementations without rippling through the codebase, and organize code by concern rather than by class hierarchy. The result is code that feels lighter and easier to evolve.

---

## Next Up - Lesson 15

Extension functions and extension properties let you add methods and properties to types you do not own (or to your own types, organized externally). The syntax is `fun ReceiverType.name(...): Type = ...` for functions and `val ReceiverType.name: Type get() = ...` for properties. Inside the body, `this` refers to the receiver, and you can usually omit the explicit `this`. Extensions are dispatched statically based on the declared type, not the runtime type, so they do not participate in inheritance polymorphism. Member functions win over extensions with the same name. Most of the Kotlin standard library is built with extension functions, including `filter`, `map`, `joinToString`, `sumOf`, and many more. For Catatku, we defined extensions on `Status`, `Entry`, and `List<Entry>` that make the calling code read like a description of intent: `entries.activeOnly()`, `entry.markDone()`, `status.marker`, and so on. The pattern produces small focused types and a rich vocabulary of operations layered on via extensions.

In Lesson 15 you will learn the scope functions: `let`, `run`, `with`, `apply`, and `also`. Each one is a higher-order function that runs a lambda in the context of an object, with slightly different semantics. They build on extension functions and lambdas to enable many of the most idiomatic Kotlin patterns.
