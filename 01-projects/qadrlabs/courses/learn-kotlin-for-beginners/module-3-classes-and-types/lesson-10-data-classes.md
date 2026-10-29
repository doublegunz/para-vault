## 1. Before You Begin

Lesson 9 introduced regular classes, with primary constructors, properties, methods, and visibility. Regular classes work for any kind of object, but a particular kind of class shows up so often in real code that Kotlin gives it special syntax: the data class. A data class is a class whose primary purpose is to hold data, like a "user" with a name and email, an "entry" with an id and description, or a "point" with x and y coordinates. For these "value-like records", you almost always want the same set of behaviors: structural equality (two instances with the same field values are considered equal), readable string representations for debugging, the ability to copy an instance with some fields changed, and destructuring into individual variables. Writing all this by hand is tedious and error-prone. Kotlin's `data class` keyword generates all of it for you.

This lesson covers data classes in detail. By the end you will have refactored Catatku's task representation from the parallel lists of earlier lessons into a real `Entry` data class with `id`, `description`, `priority`, `status`, and `createdAt` fields. You will see how `equals`, `hashCode`, and `toString` are generated, how the `copy` method lets you derive new instances from existing ones, and how destructuring declarations work to unpack a data class into named variables. This is the lesson where Catatku starts to look like a real Kotlin application rather than a series of small examples, because once we have an `Entry` type, every later lesson can treat entries as first-class values instead of as scattered fields.

### What You'll Build

An `Entry` data class that represents one entry in Catatku, with id, description, priority, status, and createdAt fields. You will create instances, compare them, copy them with modifications, destructure them, and put them in collections. By the end Catatku has a real domain type that the rest of the course will use, replacing the parallel lists of strings from earlier lessons. You will also see when to use a data class versus a regular class and the requirements for declaring one. The full `Entry` will be slightly simplified for this lesson (priority and status as strings rather than enum/sealed types), with the proper enum and sealed class versions coming in Lessons 11 and 12.

### What You'll Learn

- ✅ How `data class` generates equals, hashCode, toString, and copy automatically
- ✅ How to use the `copy` method to derive new instances from existing ones
- ✅ How destructuring declarations unpack a data class into named variables
- ✅ The requirements for declaring a data class
- ✅ When to use a data class versus a regular class

### What You'll Need

- The `catatku` Gradle project from previous lessons
- A solid understanding of regular classes from Lesson 9
- About thirty-five minutes
- Comfort with constructor parameters and properties

---

## 2. Defining a Data Class

A data class is declared with `data class` instead of just `class`. Other than the keyword, the syntax is the same: a class header with a primary constructor, where each parameter has `val` or `var` to mark it as a property.

### Step 1: Compare to a Regular Class

Open `Main.kt` and replace its contents with this experiment:

```kotlin
class RegularPoint(val x: Int, val y: Int)
data class DataPoint(val x: Int, val y: Int)

fun main() {
    val r1 = RegularPoint(3, 4)
    val r2 = RegularPoint(3, 4)
    
    val d1 = DataPoint(3, 4)
    val d2 = DataPoint(3, 4)
    
    println("RegularPoint instances:")
    println("  r1: $r1")
    println("  r2: $r2")
    println("  r1 == r2? ${r1 == r2}")
    
    println("DataPoint instances:")
    println("  d1: $d1")
    println("  d2: $d2")
    println("  d1 == d2? ${d1 == d2}")
}
```

Save and run. Output:

```text
RegularPoint instances:
  r1: RegularPoint@58644d46
  r2: RegularPoint@14dad5dc
  r1 == r2? false
DataPoint instances:
  d1: DataPoint(x=3, y=4)
  d2: DataPoint(x=3, y=4)
  d1 == d2? true
```

The differences are striking. The regular class prints with a meaningless hash code in `toString` (the exact hash codes change from run to run, so yours will differ), and `==` between two instances with the same field values returns `false` because the default equality is reference equality (the two instances are different objects, so they are not equal). The data class prints with a clean `DataPoint(x=3, y=4)` representation, and `==` returns `true` because data classes implement structural equality (two instances with the same field values are considered equal).

Both differences come from the `data` keyword. The compiler generated different versions of `toString` and `equals` based on the class's properties. For the regular class, you would have to write these methods yourself if you wanted them. For the data class, they come free.

### Step 2: Try the copy Method

The `copy` method is one of the most useful additions:

```kotlin
data class DataPoint(val x: Int, val y: Int)

fun main() {
    val original = DataPoint(3, 4)
    val moved = original.copy(x = 10)
    val flipped = original.copy(y = -original.y)
    
    println("original: $original")
    println("moved (x changed): $moved")
    println("flipped (y negated): $flipped")
    
    // The original is unchanged
    println("original is still: $original")
}
```

Save and run. Output:

```text
original: DataPoint(x=3, y=4)
moved (x changed): DataPoint(x=10, y=4)
flipped (y negated): DataPoint(x=3, y=-4)
original is still: DataPoint(x=3, y=4)
```

The `copy(x = 10)` call creates a new `DataPoint` with `x` set to 10 and all other fields copied from the original. The argument is a named argument to the `copy` method; you can specify any combination of fields to override, and the rest take their original values. The result is a new instance; the original is untouched.

This pattern is enormously useful for "make a small change" operations. In Java, you would either mutate the original (which is dangerous if other code holds references to it) or write boilerplate code to construct a new instance with the modified field. In Kotlin, `copy(field = newValue)` does exactly what you want in one line.

For Catatku, we will use `copy` throughout: when marking a task done, we will produce a copy with `status = Status.Done` rather than mutating the original. This immutable update pattern makes the code easier to reason about because no shared instance ever changes underneath you.

### Step 3: Try Destructuring

Data classes can be destructured into individual variables:

```kotlin
data class DataPoint(val x: Int, val y: Int)

fun main() {
    val p = DataPoint(3, 4)
    
    val (x, y) = p
    println("x = $x, y = $y")
    
    // Destructuring with custom names
    val (horizontal, vertical) = p
    println("horizontal = $horizontal, vertical = $vertical")
}
```

Save and run. Output:

```text
x = 3, y = 4
horizontal = 3, vertical = 4
```

The `val (x, y) = p` declaration unpacks the data class into two new variables, in the order the fields were declared. The names are local to the destructuring; they do not have to match the field names. So `val (horizontal, vertical) = p` also works and gives meaningful names for this specific use.

Destructuring works because data classes automatically generate `componentN` functions: `component1`, `component2`, and so on, one for each property in declaration order. The destructuring syntax calls these methods to get the values, and any class can support destructuring by manually writing `componentN` methods. For data classes, the methods are free.

We saw destructuring briefly in earlier lessons with `withIndex` (which returns `IndexedValue` instances) and with iterating over maps (where each entry is a `Map.Entry`). Both of those types support destructuring through `componentN` functions. With data classes, you get the same support automatically for any custom type you define.

---

## 3. Defining the Entry Class

Now let us define the actual `Entry` class that Catatku will use. We will start with a simple version using `String` for priority and status, and refine to enum/sealed types in Lessons 11 and 12.

### Step 1: First Version of Entry

Replace the body of the file with:

```kotlin
data class Entry(
    val id: Int,
    val description: String,
    val priority: String = "Medium",
    val status: String = "Pending",
    val createdAt: String = "2026-04-26"
)

fun main() {
    val e1 = Entry(id = 1, description = "Pay rent")
    val e2 = Entry(id = 2, description = "Finish Kotlin course", priority = "High")
    val e3 = Entry(id = 3, description = "Read for fun", priority = "Low", status = "Done")
    
    println(e1)
    println(e2)
    println(e3)
}
```

Save and run. Output:

```text
Entry(id=1, description=Pay rent, priority=Medium, status=Pending, createdAt=2026-04-26)
Entry(id=2, description=Finish Kotlin course, priority=High, status=Pending, createdAt=2026-04-26)
Entry(id=3, description=Read for fun, priority=Low, status=Done, createdAt=2026-04-26)
```

The `Entry` data class has five properties, three with default values. We use named arguments at construction (Lesson 6) so each call site is self-documenting and we can skip the defaults when we want them. The first call provides only id and description, so priority defaults to "Medium" and status defaults to "Pending". The second call adds priority. The third overrides priority and status.

The auto-generated `toString` shows all five fields with their names. This is genuinely useful for debugging: when you see this output, you immediately know what every field of the entry contains, without having to write a custom format. We will replace this with a friendlier display format using a function or extension property in Lesson 14, but for debugging the data class default is great.

### Step 2: Compare Entries with ==

Equality on data classes is structural, so two entries with the same field values are equal:

```kotlin
data class Entry(
    val id: Int,
    val description: String,
    val priority: String = "Medium",
    val status: String = "Pending",
    val createdAt: String = "2026-04-26"
)

fun main() {
    val e1 = Entry(id = 1, description = "Pay rent")
    val e2 = Entry(id = 1, description = "Pay rent")
    val e3 = Entry(id = 2, description = "Pay rent")
    
    println("e1 == e2? ${e1 == e2}")  // true: same fields
    println("e1 == e3? ${e1 == e3}")  // false: different id
    println("e1 === e2? ${e1 === e2}")  // false: different objects
}
```

Save and run. Output:

```text
e1 == e2? true
e1 == e3? false
e1 === e2? false
```

Two operators distinguish equality. The `==` operator (which calls `equals` under the hood) checks structural equality: do the two values have the same logical contents. The `===` operator checks reference equality: are they literally the same object in memory. For data classes, `==` is what you want almost always; `===` is rarely used in application code.

Notice that `e1 === e2` is false even though `e1 == e2` is true. The two are different objects (separate allocations) that happen to have the same field values. Structural equality says they are equal; reference equality says they are not. Kotlin uses `==` for the structural form because that is what you almost always want.

### Step 3: Use Entries with Collections

Data classes are designed to work cleanly with collections, especially sets and maps where structural equality matters:

```kotlin
data class Entry(
    val id: Int,
    val description: String,
    val priority: String = "Medium",
    val status: String = "Pending",
    val createdAt: String = "2026-04-26"
)

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent"),
        Entry(2, "Finish Kotlin course", priority = "High"),
        Entry(3, "Call dentist"),
        Entry(2, "Finish Kotlin course", priority = "High")  // duplicate
    )
    
    println("All entries (with duplicate):")
    for (e in entries) {
        println("  $e")
    }
    
    val unique = entries.toSet()
    println("\nUnique entries:")
    for (e in unique) {
        println("  $e")
    }
    
    val byId = entries.associateBy { it.id }
    println("\nBy ID:")
    for ((id, entry) in byId) {
        println("  $id -> $entry")
    }
}
```

Save and run. Output:

```text
All entries (with duplicate):
  Entry(id=1, description=Pay rent, priority=Medium, status=Pending, createdAt=2026-04-26)
  Entry(id=2, description=Finish Kotlin course, priority=High, status=Pending, createdAt=2026-04-26)
  Entry(id=3, description=Call dentist, priority=Medium, status=Pending, createdAt=2026-04-26)
  Entry(id=2, description=Finish Kotlin course, priority=High, status=Pending, createdAt=2026-04-26)

Unique entries:
  Entry(id=1, description=Pay rent, priority=Medium, status=Pending, createdAt=2026-04-26)
  Entry(id=2, description=Finish Kotlin course, priority=High, status=Pending, createdAt=2026-04-26)
  Entry(id=3, description=Call dentist, priority=Medium, status=Pending, createdAt=2026-04-26)

By ID:
  1 -> Entry(id=1, description=Pay rent, priority=Medium, status=Pending, createdAt=2026-04-26)
  2 -> Entry(id=2, description=Finish Kotlin course, priority=High, status=Pending, createdAt=2026-04-26)
  3 -> Entry(id=3, description=Call dentist, priority=Medium, status=Pending, createdAt=2026-04-26)
```

The list of four entries (with one duplicate) becomes a set of three when we call `.toSet()`. The set deduplicates based on structural equality, which works because the data class has a generated `equals` and `hashCode`. The `associateBy { it.id }` builds a map from id to entry; if two entries had the same id, the later one would win.

This kind of seamless collection integration is why data classes are so pleasant. Without `equals` and `hashCode`, sets and maps would not work correctly with your custom types; you would have to write the methods yourself to get the same behavior. Data classes give you correct collection behavior for free.

---

## 4. The copy Method in Detail

The `copy` method is one of the most-used data class features. Let us explore what it can and cannot do.

### Step 1: Copy with No Changes

`copy()` with no arguments produces an exact copy:

```kotlin
data class Entry(val id: Int, val description: String, val priority: String = "Medium")

fun main() {
    val original = Entry(1, "Pay rent")
    val twin = original.copy()
    
    println("original: $original")
    println("twin: $twin")
    println("original == twin? ${original == twin}")
    println("original === twin? ${original === twin}")
}
```

Save and run. Output:

```text
original: Entry(id=1, description=Pay rent, priority=Medium)
twin: Entry(id=1, description=Pay rent, priority=Medium)
original == twin? true
original === twin? false
```

`copy()` produces a new instance with the same field values. Structurally equal but a different object in memory. This is useful when you want a defensive copy (a separate instance you can pass around without exposing the original), though the immutable nature of `val` properties makes this less commonly needed than in mutable Java code.

### Step 2: Copy with Changes

`copy(field = newValue)` produces a new instance with one or more fields changed:

```kotlin
data class Entry(val id: Int, val description: String, val priority: String = "Medium", val status: String = "Pending")

fun main() {
    val original = Entry(1, "Pay rent")
    val markedDone = original.copy(status = "Done")
    val higherPriority = original.copy(priority = "High")
    val both = original.copy(status = "Done", priority = "High")
    
    println("original: $original")
    println("markedDone: $markedDone")
    println("higherPriority: $higherPriority")
    println("both: $both")
}
```

Save and run. Output:

```text
original: Entry(id=1, description=Pay rent, priority=Medium, status=Pending)
markedDone: Entry(id=1, description=Pay rent, priority=Medium, status=Done)
higherPriority: Entry(id=1, description=Pay rent, priority=High, status=Pending)
both: Entry(id=1, description=Pay rent, priority=High, status=Done)
```

Each `copy` call produces a new instance with the specified fields changed and all other fields copied. The original is never modified. This is the "immutable update" pattern: instead of mutating an existing object, you produce a new object that represents the post-update state.

For Catatku, this means that when the user marks a task done, we do not modify the existing `Entry`; we create a new `Entry` with `status = "Done"`. The `EntryList` then replaces the old entry with the new one. This pattern makes the code more thread-safe (immutable values are safe to share) and easier to reason about (no spooky mutations), and it costs nothing meaningful in performance for typical application code.

### Step 3: Chain Copy Calls

You can chain `copy` calls to produce a series of derived states:

```kotlin
data class Entry(val id: Int, val description: String, val priority: String = "Medium", val status: String = "Pending")

fun main() {
    val starting = Entry(1, "Read book")
    
    val updated = starting
        .copy(priority = "High")
        .copy(status = "Done")
        .copy(description = "Read book (completed)")
    
    println("starting: $starting")
    println("updated: $updated")
}
```

Save and run. Output:

```text
starting: Entry(id=1, description=Read book, priority=Medium, status=Pending)
updated: Entry(id=1, description=Read book (completed), priority=High, status=Done)
```

Each `copy` call returns a new instance, and the chain applies them in sequence. The starting instance is unchanged; the updated instance has all three modifications. This is a clean way to express a sequence of changes when each step is small.

In practice you often combine `copy` with other operations. For example, `entries.map { it.copy(priority = "High") }` produces a new list where every entry has high priority. The original list and original entries are unchanged; the result is a fresh list of fresh entries. This kind of transformation pipeline is one of the cleanest patterns in idiomatic Kotlin.

---

## 5. Destructuring in More Detail

Destructuring lets you unpack a data class into individual variables in one syntax. We saw this briefly in Section 2; here we look at it more carefully.

### Step 1: Destructure in a for Loop

A common use is iterating over a collection of data classes and immediately unpacking each one:

```kotlin
data class Entry(val id: Int, val description: String, val priority: String)

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", "High"),
        Entry(2, "Buy groceries", "Medium"),
        Entry(3, "Read", "Low")
    )
    
    for ((id, description, priority) in entries) {
        println("Task #$id ($priority): $description")
    }
}
```

Save and run. Output:

```text
Task #1 (High): Pay rent
Task #2 (Medium): Buy groceries
Task #3 (Low): Read
```

The destructuring `(id, description, priority)` in the loop header unpacks each `Entry` into three named variables for the duration of that iteration. This is much more readable than `for (entry in entries) { println("Task #${entry.id} (${entry.priority}): ${entry.description}") }`, especially when you have several fields to use.

### Step 2: Skip Fields with Underscore

If you do not need all the fields, use `_` to skip:

```kotlin
data class Entry(val id: Int, val description: String, val priority: String)

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", "High"),
        Entry(2, "Buy groceries", "Medium")
    )
    
    for ((_, description, _) in entries) {
        println(description)
    }
}
```

Save and run. Output:

```text
Pay rent
Buy groceries
```

The underscore says "I do not need this field; do not bind it to a variable". This is useful when you only need a subset of the fields, and using underscore makes that subset explicit. It is more readable than naming variables you do not use, and the compiler does not warn about unused names.

### Limits on Destructuring

Destructuring is positional: it uses the field declaration order, not the field names. If you reorder the fields in the data class definition, every destructuring across the codebase changes meaning. This is a real risk if you add a new field at the start of the class or rearrange the fields.

For this reason, destructuring is most useful for data classes with two or three fields where the order is intuitive (`(x, y)` for a point, `(name, value)` for a key-value pair, `(id, description, priority)` for an entry). For data classes with many fields, accessing them by name (`entry.id`, `entry.description`) is usually clearer.

Kotlin does not support named destructuring (where you would say `val { id, description } = entry` to unpack just the named fields). If you want to extract specific fields by name, you assign them to local variables: `val id = entry.id; val description = entry.description`. This is more verbose but unambiguous about which fields you are using.

---

## 6. Requirements and Limitations of Data Classes

Data classes have a few specific requirements and constraints worth knowing.

### Data Class Requirements

A data class must have at least one parameter in the primary constructor, and every primary-constructor parameter must be `val` or `var`. You cannot have a data class with no fields, and you cannot have a data class where some constructor parameters are not properties. Both of these rules exist because the auto-generated methods (especially `equals` and `toString`) operate on the properties, so the fields must be visible to them.

```kotlin
// This compiles:
data class Entry(val id: Int, val description: String)

// This does NOT compile (no parameters):
// data class Empty()

// This does NOT compile (parameter is not a property):
// data class Bad(val id: Int, raw: String)
```

If you remove the `//` from the `Empty` line, the compiler reports `Data class must have at least one primary constructor parameter.` If you remove it from the `Bad` line instead, it reports `Primary constructor of data class must only have property ('val' / 'var') parameters.`

The "must have at least one parameter" rule is rarely a problem because empty data classes do not make sense. The "all parameters must be properties" rule is occasionally inconvenient, but the workaround is to either make the parameter a property or to use a regular class.

### Step 1: Add Body Properties and Methods

Data classes can have all the same things regular classes have: secondary constructors, init blocks, properties declared in the body, methods, and companion objects. The auto-generated `equals`, `hashCode`, and `toString` are based only on the primary-constructor properties, not on properties declared in the body.

```kotlin
data class Entry(val id: Int, val description: String) {
    var note: String = ""  // body property, not in equals/hashCode/toString
    
    fun summary(): String = "$id. $description"
}

fun main() {
    val a = Entry(1, "Pay rent").apply { note = "this month" }
    val b = Entry(1, "Pay rent").apply { note = "next month" }
    
    println("a: $a")
    println("b: $b")
    println("a == b? ${a == b}")
    println("summary: ${a.summary()}")
}
```

Save and run. Output:

```text
a: Entry(id=1, description=Pay rent)
b: Entry(id=1, description=Pay rent)
a == b? true
summary: 1. Pay rent
```

Notice that `note` does not appear in `toString`, and `a == b` is true even though their notes differ. This is because only primary-constructor properties participate in the auto-generated methods. The `note` is just a regular `var` property that happens to be declared in the body.

This behavior is occasionally what you want (auxiliary state that is not part of the identity) but is more often a sign that you should refactor: either move `note` into the primary constructor (so it participates in equality) or use a regular class. As a habit, keep data classes purely as data carriers, with all relevant fields in the primary constructor.

The `apply` we used above is a scope function (Lesson 15) that runs a block on the receiver and returns the receiver. We use it here to set the body property at construction; we will see scope functions in detail later.

### Data Classes with Custom Methods

A data class can have custom methods like `summary()` above, just like a regular class. The methods are not auto-generated; you write them as you would in a regular class. Data classes are typically used as immutable value records, but adding small helper methods (like `summary()` for formatted display) is fine and common.

For Catatku, the `Entry` data class will eventually have a few methods, but most of the operations (adding, removing, finding) live on `EntryList` rather than on `Entry`. The `Entry` itself is mostly a data carrier with simple computed properties and maybe one or two helpers.

---

## 7. Run and Test

Build a comprehensive example using Entry as Catatku will use it.

### Step 1: A Real-World Catatku Snippet

Replace `Main.kt` with this:

```kotlin
data class Entry(
    val id: Int,
    val description: String,
    val priority: String = "Medium",
    val status: String = "Pending",
    val createdAt: String = "2026-04-26"
)

fun statusMarker(status: String): String = when (status) {
    "Pending" -> "[ ]"
    "InProgress" -> "[~]"
    "Done" -> "[x]"
    "Cancelled" -> "[!]"
    else -> "[?]"
}

fun priorityShortLabel(priority: String): String = when (priority) {
    "High" -> "H"
    "Medium" -> "M"
    "Low" -> "L"
    else -> "?"
}

fun formatEntry(e: Entry): String {
    val marker = statusMarker(e.status)
    val priority = priorityShortLabel(e.priority)
    return "$marker ($priority) ${e.id}. ${e.description}"
}

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", priority = "High"),
        Entry(2, "Finish Kotlin course"),
        Entry(3, "Call dentist", priority = "Low", status = "Done"),
        Entry(4, "Walk the dog")
    )
    
    println("Initial state:")
    for (e in entries) {
        println("  ${formatEntry(e)}")
    }
    
    // Mark entry 2 as done by producing a new list
    val updated = entries.map { e ->
        if (e.id == 2) e.copy(status = "Done") else e
    }
    
    println("\nAfter marking #2 done:")
    for (e in updated) {
        println("  ${formatEntry(e)}")
    }
    
    // Filter to just pending entries
    val pending = updated.filter { it.status == "Pending" }
    println("\nStill pending:")
    for (e in pending) {
        println("  ${formatEntry(e)}")
    }
}
```

Save and run.

### Step 2: Read the Output

The output is:

```text
Initial state:
  [ ] (H) 1. Pay rent
  [ ] (M) 2. Finish Kotlin course
  [x] (L) 3. Call dentist
  [ ] (M) 4. Walk the dog

After marking #2 done:
  [ ] (H) 1. Pay rent
  [x] (M) 2. Finish Kotlin course
  [x] (L) 3. Call dentist
  [ ] (M) 4. Walk the dog

Still pending:
  [ ] (H) 1. Pay rent
  [ ] (M) 4. Walk the dog
```

Walk through what each piece contributed. The data class definition is a single line for the constructor and properties. The `formatEntry` function takes an `Entry` and uses its fields to build a display string. The `entries.map { ... }` operation produces a new list where one entry has its status changed via `copy`. The original `entries` list is unchanged; the change exists in `updated`. The `filter` produces another new list containing only pending entries.

Every operation is functional and immutable. No entry was mutated; we produced new entries and new lists at each step. This is the style that data classes encourage and that Catatku's main code will use throughout.

### Compare to a Mutable Approach

For contrast, consider how this would look with a mutable class. We would have to mutate the entry directly (`entry.status = "Done"`), and any code holding a reference to that entry would see the change. With multiple references, this can cause subtle bugs where one piece of code does not expect the entry to change but it does because another piece changed it.

The immutable approach with `copy` avoids this entirely. Each `copy` produces a fresh entry; the original is preserved. Code holding the original keeps seeing the original; code holding the copy sees the modified version. The two are independent. This makes reasoning about the code dramatically simpler, especially as the program grows.

---

## 8. Fix the Errors in Your Code

Three data-class mistakes are common.

**Error 1: Forgetting val on primary constructor parameters**

```kotlin
// Wrong
data class Entry(id: Int, description: String)

// Correct
data class Entry(val id: Int, val description: String)
```

The wrong version stops with `Primary constructor of data class must only have property ('val' / 'var') parameters.`, once for each parameter. Without `val` or `var`, a parameter is a plain parameter and would not be accessible after construction, which would defeat the purpose of a data class. The fix is to add `val` (almost always the right choice) before each parameter name. As a habit, when writing a data class, treat every parameter as a property.

**Error 2: Reassigning a val property instead of copying**

```kotlin
// Wrong
data class Entry(val id: Int, val description: String)

fun main() {
    val e = Entry(1, "Pay rent")
    e.description = "Pay rent now"
}

// Correct
data class Entry(val id: Int, val description: String)

fun main() {
    val e = Entry(1, "Pay rent")
    val updated = e.copy(description = "Pay rent now")
    println(e)
    println(updated)
}
```

The wrong version stops with `'val' cannot be reassigned.` Properties declared with `val` cannot be reassigned after construction. This is by design: data classes work best as immutable value records, and `copy` is the way to "modify" them by producing new instances. The correct version prints `Entry(id=1, description=Pay rent)` and then `Entry(id=1, description=Pay rent now)`, showing that the original is untouched. If you really need mutable fields (which is rare for data classes), use `var` instead of `val`, but the immutable approach is almost always better. As a habit, use `val` on every data class property and use `copy` for derived states.

**Error 3: Storing a derived value in the primary constructor**

```kotlin
// Wrong
data class Entry(val id: Int, val description: String, val cachedDisplay: String)

fun main() {
    val e = Entry(1, "Pay rent", "[ ] 1. Pay rent")
    val e2 = e.copy(description = "Updated")
    println(e2.cachedDisplay)
}

// Correct
data class Entry(val id: Int, val description: String) {
    val display: String
        get() = "[ ] $id. $description"
}

fun main() {
    val e = Entry(1, "Pay rent")
    val e2 = e.copy(description = "Updated")
    println(e2.display)
}
```

The wrong version compiles but prints the stale text `[ ] 1. Pay rent`, because `copy` just clones the cached value and never recomputes it. The correct version prints `[ ] 1. Updated`, because the display text is a computed property that is rebuilt from the current fields every time you read it. As a habit, only put genuinely independent fields in the primary constructor; computed values go in the body with a `get()` clause.

---

## 9. Exercises

These exercises practice data classes.

**Exercise 1:** Define a data class `Book` with `title: String`, `author: String`, `pages: Int`, and `isRead: Boolean = false`. Create three book instances using named arguments, print each one, and check whether two instances with the same fields are equal.

**Exercise 2:** Using the `Book` data class from Exercise 1, write a function `markAsRead(book: Book): Book` that returns a copy of the book with `isRead = true`. Test it with a book where `isRead` is initially false, and verify that the original is unchanged after the function call.

**Exercise 3:** Create a `data class Score(val player: String, val value: Int)`. Use destructuring to iterate over a list of scores and print each player's name and score. Also use the data class with `toSet()` to deduplicate a list of scores and verify duplicates were removed.

---

## 10. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

This exercise practices declaring a data class, named arguments, and structural equality.

```kotlin
data class Book(val title: String, val author: String, val pages: Int, val isRead: Boolean = false)

fun main() {
    val first = Book(title = "Kotlin in Action", author = "Dmitry Jemerov", pages = 360)
    val second = Book(title = "Atomic Kotlin", author = "Bruce Eckel", pages = 640, isRead = true)
    val third = Book(title = "Kotlin in Action", author = "Dmitry Jemerov", pages = 360)

    println(first)
    println(second)
    println(third)

    println("first == third? ${first == third}")
    println("first == second? ${first == second}")
}
```

Save and run. Output:

```text
Book(title=Kotlin in Action, author=Dmitry Jemerov, pages=360, isRead=false)
Book(title=Atomic Kotlin, author=Bruce Eckel, pages=640, isRead=true)
Book(title=Kotlin in Action, author=Dmitry Jemerov, pages=360, isRead=false)
first == third? true
first == second? false
```

The `isRead` parameter has a default of `false`, so `first` and `third` can leave it out while `second` sets it explicitly. Named arguments make each call easy to read even with four fields. The generated `toString` prints every field, and the generated `equals` makes `first == third` true because all four fields match, even though they are two separate objects.

**Solution for Exercise 2:**

This exercise practices the `copy` method and the immutable update pattern.

```kotlin
data class Book(val title: String, val author: String, val pages: Int, val isRead: Boolean = false)

fun markAsRead(book: Book): Book = book.copy(isRead = true)

fun main() {
    val original = Book(title = "Kotlin in Action", author = "Dmitry Jemerov", pages = 360)
    println("Before: $original")
    
    val read = markAsRead(original)
    println("After:  $read")
    
    println("\nOriginal unchanged?")
    println("  original.isRead = ${original.isRead}")
    println("  read.isRead = ${read.isRead}")
    
    println("\nAre they equal? ${original == read}")
}
```

Save and run. Output:

```text
Before: Book(title=Kotlin in Action, author=Dmitry Jemerov, pages=360, isRead=false)
After:  Book(title=Kotlin in Action, author=Dmitry Jemerov, pages=360, isRead=true)

Original unchanged?
  original.isRead = false
  read.isRead = true

Are they equal? false
```

The `markAsRead` function is a single-expression function that calls `copy(isRead = true)` on its argument. The result is a new `Book` with `isRead` set to true; all other fields are copied from the original.

The function returns the new instance and the original is unchanged. This is the heart of the immutable update pattern: never mutate, always derive. The advantage is that any code holding a reference to the original keeps seeing the original. If we had mutated `original.isRead = true` directly (which we cannot, because it is a `val`), all references to `original` would see the change, which can be a source of confusion in larger programs.

The two `Book` instances are not equal because their `isRead` fields differ. The data class's `equals` checks every primary-constructor field, so a difference in any field makes the instances unequal. This is structural equality at work: the instances represent different states of the conceptually same book.

A more idiomatic version using an extension function (Lesson 14) would let you write `original.markAsRead()` instead of `markAsRead(original)`. Extension functions add methods to types you do not own, and a `markAsRead` operation feels naturally like a method on `Book`. We will see this style in Lesson 14 and use it in Catatku for operations like `entry.markDone()`.

**Solution for Exercise 3:**

This exercise combines destructuring in a `for` loop with deduplication through `toSet()`.

```kotlin
data class Score(val player: String, val value: Int)

fun main() {
    val scores = listOf(
        Score("Ani", 90),
        Score("Budi", 75),
        Score("Ani", 90),
        Score("Citra", 82)
    )

    println("All scores:")
    for ((player, value) in scores) {
        println("  $player: $value")
    }

    val unique = scores.toSet()
    println("\nUnique scores (${unique.size} of ${scores.size}):")
    for ((player, value) in unique) {
        println("  $player: $value")
    }
}
```

Save and run. Output:

```text
All scores:
  Ani: 90
  Budi: 75
  Ani: 90
  Citra: 82

Unique scores (3 of 4):
  Ani: 90
  Budi: 75
  Citra: 82
```

The loop header `(player, value)` destructures each `Score` through the generated `component1` and `component2` functions. The list contains `Score("Ani", 90)` twice, and `toSet()` keeps only one of them because the generated `equals` and `hashCode` treat the two instances as the same value. The set also keeps the original order of first appearance, which is why Budi still comes before Citra.

---

## 11. Understanding Why Data Classes Matter

Data classes are one of the small features that, taken together, make Kotlin feel dramatically more pleasant than Java. The savings come from removing boilerplate that does not contribute meaningfully to code clarity, while the conventions encode best practices that experienced programmers would follow anyway.

Consider how many lines of Java are required for an equivalent data class. The fields, the constructor, the getters, `equals`, `hashCode`, `toString`, and a copy-with-modification method together take about 50 to 80 lines for a class with five fields. None of these lines do anything you would not write the same way every time. The IDE can generate them, but they still bloat the source code: every time you open the class, you have to scroll past hundreds of lines of generated boilerplate to find the actual logic. Worse, when you add a new field, you have to update the constructor, the getter, `equals`, `hashCode`, and `toString`, and forgetting any one is a subtle bug.

Kotlin's `data class` keyword replaces all this with a single line. The compiler generates the same methods you would have written by hand, but they are invisible at the source level. When you add a new field, all the methods automatically include it. This is one of the clearest cases where Kotlin's design philosophy (let the compiler generate boilerplate, free the source for actual logic) pays off concretely. The savings might seem small for a single class, but a real codebase has dozens or hundreds of these classes, and the lines saved compound into thousands or tens of thousands.

Beyond the boilerplate savings, data classes encode the convention of immutability. Most data class properties are `val`, and the `copy` method is the canonical way to derive new instances rather than mutating existing ones. This convention is genuinely good practice in any language, but Kotlin makes it the path of least resistance. Programmers writing idiomatic Kotlin write more immutable code than they would in Java, not because they explicitly chose to but because the language nudges them in that direction.

The combination of structural equality and immutability is also what makes data classes work cleanly with collections. Sets and maps require working `equals` and `hashCode`; data classes provide them automatically. Immutable data classes can be safely used as keys in maps without worrying about hash codes changing if the object is mutated. This is a quiet correctness benefit that you do not notice until you accidentally use a mutable object as a map key in another language and watch your code break in mysterious ways.

A subtler point is that data classes encourage you to design your data carefully. When the type system enforces that every field of an `Entry` is part of `equals`, `hashCode`, and `toString`, you start thinking about which fields are essential to the entry's identity. If two entries with the same id and description should be considered equal regardless of priority and status, then `Entry` should not include priority and status in equality, which means they probably should not be properties of `Entry` either. They might belong on a separate `EntryStatus` type. This kind of design thinking is what produces clean domain models, and Kotlin's data classes nudge you toward it because the implications of each field decision become visible.

The cost of all this is a small one: data classes are not appropriate for every situation. Classes with mutable state, classes with custom equality logic that is not just "equal fields means equal instances", and classes designed for inheritance hierarchies are all better as regular classes. For pure data records (which is what most domain types are), data classes are essentially always the right choice. Recognizing the distinction between "data carrier" and "behavioral object" is part of becoming fluent in Kotlin.

---

## Next Up - Lesson 11

Data classes are Kotlin's mechanism for value-like records: classes whose primary purpose is to hold data. The `data class` keyword auto-generates `equals`, `hashCode`, `toString`, `copy`, and `componentN` functions, eliminating the boilerplate that would otherwise fill these classes in Java. The `copy(field = value)` method enables the immutable update pattern, where you produce new instances rather than mutating existing ones. Destructuring declarations let you unpack a data class into named variables in one syntax. Data classes work cleanly with collections, especially sets and maps that depend on structural equality. We defined the `Entry` data class that Catatku will use, with id, description, priority, status, and createdAt fields, and saw how immutable updates feel natural with `copy`. The `Entry` will be refined with proper enum (Lesson 12) and sealed class (Lesson 11) types for priority and status, but the data class skeleton stays the same.

In Lesson 11 you will learn sealed classes, which let you define closed type hierarchies where a value is exactly one of a fixed set of variants. Sealed classes are how Catatku's `Status` will be properly modeled, with variants for pending, in-progress, done, and cancelled (carrying a reason).
