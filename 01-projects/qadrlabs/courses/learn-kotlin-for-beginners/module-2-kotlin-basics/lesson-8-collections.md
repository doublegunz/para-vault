## 1. Before You Begin

Almost every interesting program manipulates collections of values. A task manager has a collection of tasks. A search engine has a collection of documents. A game has a collection of entities. The data structures that hold these collections (lists, maps, sets) are some of the most important tools in any programmer's toolkit, and Kotlin's standard library provides a particularly clean API for working with them. This lesson covers the three main collection types you will use constantly (`List`, `Map`, `Set`), the mutable variants of each, the factory functions for creating them, the basic operations, and a preview of the rich set of standard-library functions that we will explore in detail in Lesson 13.

Kotlin makes one design choice about collections that is worth understanding upfront. The standard interfaces (`List`, `Map`, `Set`) are read-only: you can read from them but cannot modify them. The mutable variants (`MutableList`, `MutableMap`, `MutableSet`) extend the read-only interfaces and add modification methods. This split lets you express two different kinds of guarantees in your code: "I will not modify this" (use the read-only interface) and "I will modify this" (use the mutable interface). Combined with `val` and `var`, you get four levels of mutability for variables holding collections, and learning to pick the right combination for each situation is part of writing fluent Kotlin.

### What You'll Build

A series of small experiments inside `Main.kt` that exercise each collection type. You will create lists of task descriptions, a map from priority codes to labels, and a set of unique categories. You will iterate over them, look up specific elements, add and remove elements (where mutable), and use a few of the most useful standard-library functions. By the end of the lesson you will be comfortable choosing between collection types based on what you need to store and how you need to access it.

### What You'll Learn

- ✅ How to create lists, maps, and sets with factory functions
- ✅ The difference between read-only and mutable collection types
- ✅ How to iterate, index, look up, and check membership
- ✅ How to add, remove, and modify elements in mutable collections
- ✅ A preview of standard-library functions like `filter`, `map`, `count`, `joinToString`

### What You'll Need

- The `catatku` Gradle project from previous lessons
- A solid understanding of types and null safety from Lessons 4 and 7
- About forty minutes
- A willingness to type and modify each example to build muscle memory

---

## 2. Lists

A list is an ordered collection of elements that can be accessed by index. Kotlin has two list types: `List<T>` is the read-only interface, and `MutableList<T>` is the version that supports modifications. You almost always start with one or the other and rarely convert between them.

### Step 1: Create a Read-Only List

Open `Main.kt` and replace its contents with this experiment:

```kotlin
fun main() {
    val tasks: List<String> = listOf("Pay rent", "Buy groceries", "Call dentist")
    
    println("Total tasks: ${tasks.size}")
    println("First task: ${tasks[0]}")
    println("Last task: ${tasks[tasks.size - 1]}")
    println("Or: ${tasks.last()}")
    
    println("All tasks:")
    for (task in tasks) {
        println("  - $task")
    }
}
```

Save and run. Output:

```text
Total tasks: 3
First task: Pay rent
Last task: Call dentist
Or: Call dentist
All tasks:
  - Pay rent
  - Buy groceries
  - Call dentist
```

The factory function `listOf("Pay rent", "Buy groceries", "Call dentist")` creates a read-only `List<String>` containing those three elements. The type annotation `: List<String>` on the variable is optional because Kotlin can infer the type, but writing it makes the code more self-documenting. The `<String>` part is the element type; `List<Int>` would be a list of integers, `List<Boolean>` a list of booleans, and so on.

You access elements by index using square brackets, with indices starting at 0. The `tasks.size` property gives the number of elements, and `tasks.last()` is a convenience method for the last element. Iterating with `for (task in tasks)` walks through each element in order, exactly as you saw in Lesson 5.

The list is read-only, which means you cannot add, remove, or replace elements. Try uncommenting these lines:

```kotlin
// tasks.add("New task")        // error: unresolved reference
// tasks[0] = "Modified"        // error: no setter
```

Both fail to compile because `List<String>` does not have those methods. The read-only interface ensures that callers cannot accidentally modify your list. If you really do need to modify, you reach for `MutableList`.

### Step 2: Create a Mutable List

```kotlin
fun main() {
    val tasks: MutableList<String> = mutableListOf("Pay rent", "Buy groceries")
    
    println("Initial: $tasks")
    
    tasks.add("Call dentist")
    println("After add: $tasks")
    
    tasks.add(0, "Wake up")  // insert at index 0
    println("After insert: $tasks")
    
    tasks.remove("Buy groceries")
    println("After remove by value: $tasks")
    
    tasks.removeAt(0)  // remove by index
    println("After remove by index: $tasks")
    
    tasks[0] = "URGENT: Pay rent"
    println("After modification: $tasks")
}
```

Save and run. Output:

```text
Initial: [Pay rent, Buy groceries]
After add: [Pay rent, Buy groceries, Call dentist]
After insert: [Wake up, Pay rent, Buy groceries, Call dentist]
After remove by value: [Wake up, Pay rent, Call dentist]
After remove by index: [Pay rent, Call dentist]
After modification: [URGENT: Pay rent, Call dentist]
```

A `MutableList` adds methods like `add`, `remove`, `removeAt`, and indexed assignment (the `tasks[0] = ...` syntax). The `add(element)` method appends to the end. The `add(index, element)` overload inserts at the given index, shifting later elements right. The `remove(element)` method removes the first occurrence of the value. The `removeAt(index)` method removes by index and returns the removed element. Indexed assignment replaces the element at the given index.

Notice that we used `val` for the variable. The variable cannot be reassigned (you cannot do `tasks = mutableListOf(...)` later), but the list it points to can be modified. This is the distinction between binding immutability (controlled by `val` vs `var`) and content immutability (controlled by the type, `List` vs `MutableList`). They are independent, so you can have any combination:

- `val tasks: List<String>`: cannot change variable, cannot modify list. The most immutable form.
- `val tasks: MutableList<String>`: cannot change variable, can modify list. The most common form for collections you build up.
- `var tasks: List<String>`: can change variable to point at a different list, cannot modify the list itself. Useful when you replace the whole list at once.
- `var tasks: MutableList<String>`: can change either. The most permissive form, used when you really need both.

For Catatku, we will use `val tasks: MutableList<Task>` for the list of tasks: a fixed reference to a list whose contents we modify over time. This is the most common shape for application data.

### Step 3: Useful List Operations

Beyond basic indexing and modification, lists have many useful methods:

```kotlin
fun main() {
    val numbers = listOf(3, 1, 4, 1, 5, 9, 2, 6)
    
    println("Size: ${numbers.size}")
    println("Is empty: ${numbers.isEmpty()}")
    println("Contains 5: ${numbers.contains(5)}")
    println("Contains 100: ${numbers.contains(100)}")
    println("Index of 9: ${numbers.indexOf(9)}")
    println("Index of 99: ${numbers.indexOf(99)}")
    
    println("First: ${numbers.first()}")
    println("First or null: ${numbers.firstOrNull()}")
    
    val empty: List<Int> = emptyList()
    println("Empty first or null: ${empty.firstOrNull()}")
    // println(empty.first())  // throws NoSuchElementException
}
```

Save and run. Output:

```text
Size: 8
Is empty: false
Contains 5: true
Contains 100: false
Index of 9: 5
Index of 99: -1
First: 3
First or null: 3
Empty first or null: null
```

Notice the `OrNull` variants. Many list methods come in two flavors: a strict version that throws an exception when there is no result (`first()`, `last()`, `single()`) and an `OrNull` version that returns `null` instead (`firstOrNull()`, `lastOrNull()`, `singleOrNull()`). The `OrNull` versions integrate with the null safety patterns from Lesson 7: you can chain them with `?:`, `?.`, and `let`. As a habit, prefer the `OrNull` variants whenever the list might be empty, because the resulting null is easier to handle than catching an exception.

The `indexOf` method returns the index of the first matching element or `-1` if not found. This is consistent with Java's `indexOf` but is less Kotlin-idiomatic than the alternatives like `find`, which we will see in Lesson 13. For now, just be aware that `-1` is the convention for "not found" with `indexOf`.

---

## 3. Maps

A map (also called a dictionary or associative array) stores key-value pairs. You look up values by their keys rather than by index. Kotlin's `Map<K, V>` is read-only, and `MutableMap<K, V>` supports modifications.

### Step 1: Create a Map

Replace the body of `main` with this:

```kotlin
fun main() {
    val priorities = mapOf(
        "H" to "High",
        "M" to "Medium",
        "L" to "Low"
    )
    
    println("Priorities map: $priorities")
    println("'H' means: ${priorities["H"]}")
    println("'M' means: ${priorities["M"]}")
    println("'X' means: ${priorities["X"]}")
    
    println("Size: ${priorities.size}")
    println("Contains 'H': ${priorities.containsKey("H")}")
    println("Contains 'High': ${priorities.containsValue("High")}")
}
```

Save and run. Output:

```text
Priorities map: {H=High, M=Medium, L=Low}
'H' means: High
'M' means: Medium
'X' means: null
Size: 3
Contains 'H': true
Contains 'High': true
```

The factory function `mapOf` takes a series of pairs created with the `to` infix function. The expression `"H" to "High"` creates a `Pair<String, String>`, which `mapOf` collects into a map. The result has type `Map<String, String>` because all keys and values are strings; for mixed types you would write the type explicitly.

The `priorities["H"]` syntax looks up the value for key `"H"`. The result type is `String?` (nullable) because the key might not be in the map; for missing keys the lookup returns null. This is one of the places where Kotlin's null safety naturally fits: maps return null for missing keys, which is then handled the same way as any other nullable value.

For the missing case, you can chain with `?:` to provide a default:

```kotlin
fun main() {
    val priorities = mapOf("H" to "High", "M" to "Medium", "L" to "Low")
    
    val label = priorities["X"] ?: "Unknown"
    println("'X' means: $label")
    
    // Or use getOrDefault
    val label2 = priorities.getOrDefault("Y", "Unknown")
    println("'Y' means: $label2")
}
```

Save and run. Output:

```text
'X' means: Unknown
'Y' means: Unknown
```

Both styles work. The `?:` form is more concise; the `getOrDefault` form is sometimes clearer when the default is the main thing you want to communicate.

### Step 2: Iterate Over a Map

Iterating over a map walks through all key-value pairs:

```kotlin
fun main() {
    val priorities = mapOf("H" to "High", "M" to "Medium", "L" to "Low")
    
    for ((key, value) in priorities) {
        println("$key -> $value")
    }
    
    println("\nJust the keys:")
    for (key in priorities.keys) {
        println("  $key")
    }
    
    println("\nJust the values:")
    for (value in priorities.values) {
        println("  $value")
    }
}
```

Save and run. Output:

```text
H -> High
M -> Medium
L -> Low

Just the keys:
  H
  M
  L

Just the values:
  High
  Medium
  Low
```

The destructuring `(key, value)` in the loop unpacks each `Map.Entry` into two named variables. This is the same destructuring syntax we saw briefly in Lesson 5 with `withIndex`, and it is one of the small ergonomic touches that makes Kotlin pleasant to use.

The `keys` and `values` properties give you views of just the keys or just the values, which you can iterate over separately. These are read-only and reflect the current state of the map.

The order of iteration depends on the underlying map type. The default `mapOf` in Kotlin returns a `LinkedHashMap`, which preserves insertion order. If you used `hashMapOf` instead, the order would not be guaranteed. For most application code, insertion order is what you want, and `mapOf` is the right factory function.

### Step 3: Mutable Maps

The mutable variant supports adding, removing, and modifying entries:

```kotlin
fun main() {
    val taskPriorities: MutableMap<Int, String> = mutableMapOf()
    
    taskPriorities[1] = "High"
    taskPriorities[2] = "Medium"
    taskPriorities[3] = "Low"
    println("After adds: $taskPriorities")
    
    taskPriorities[1] = "Critical"  // overwrite existing
    println("After overwrite: $taskPriorities")
    
    taskPriorities.remove(3)
    println("After remove: $taskPriorities")
    
    taskPriorities.putIfAbsent(2, "Trying to overwrite")  // no-op because 2 exists
    taskPriorities.putIfAbsent(4, "New entry")            // adds because 4 is new
    println("After putIfAbsent: $taskPriorities")
}
```

Save and run. Output:

```text
After adds: {1=High, 2=Medium, 3=Low}
After overwrite: {1=Critical, 2=Medium, 3=Low}
After remove: {1=Critical, 2=Medium}
After putIfAbsent: {1=Critical, 2=Medium, 4=New entry}
```

The indexed assignment syntax (`taskPriorities[1] = "High"`) adds or replaces an entry. The `remove(key)` method removes the entry with the given key. The `putIfAbsent` method only adds if the key is missing; if the key already exists, it does nothing. There are also methods like `putAll` for merging two maps and `clear` for emptying the map.

For Catatku we will not use a `Map` directly, but the patterns transfer to many other applications: caches, configuration values, lookup tables, indices. Whenever you have key-value data, a `Map` is usually the right structure.

---

## 4. Sets

A set stores unique elements. Adding an element that is already present has no effect; the set keeps each element exactly once. Kotlin has `Set<T>` for read-only and `MutableSet<T>` for mutable sets.

### Step 1: Create a Set

Replace the body of `main` with this:

```kotlin
fun main() {
    val categories = setOf("urgent", "personal", "work", "personal")
    
    println("Categories: $categories")
    println("Size: ${categories.size}")
    println("Contains 'work': ${categories.contains("work")}")
    println("Contains 'home': ${categories.contains("home")}")
}
```

Save and run. Output:

```text
Categories: [urgent, personal, work]
Size: 3
Contains 'work': true
Contains 'home': false
```

Notice that "personal" appeared twice in the input but only once in the resulting set. Sets automatically deduplicate. The factory function `setOf` returns a `Set<String>`, and the size is 3 because duplicates were collapsed.

The `contains` method tells you whether an element is in the set. For sets backed by a hash table (the default implementation), `contains` is O(1) on average, which makes sets the right choice when you frequently need to check membership in a collection. Lists, by comparison, have O(n) `contains` because they have to walk the elements one by one.

### Step 2: Mutable Sets

```kotlin
fun main() {
    val seen: MutableSet<String> = mutableSetOf()
    
    val items = listOf("apple", "banana", "apple", "cherry", "banana", "apple")
    
    for (item in items) {
        if (seen.add(item)) {
            println("First time seeing: $item")
        } else {
            println("Duplicate: $item")
        }
    }
    
    println("\nFinal set: $seen")
}
```

Save and run. Output:

```text
First time seeing: apple
First time seeing: banana
Duplicate: apple
First time seeing: cherry
Duplicate: banana
Duplicate: apple

Final set: [apple, banana, cherry]
```

The `add` method on `MutableSet` returns a `Boolean`: true if the element was new (and was added), false if it was already present (and was not changed). This makes sets useful for "have I seen this before?" patterns: you walk through some inputs, calling `add` on each, and the return value tells you whether each input is new.

Other set methods include `remove(element)` for removing, `clear` for emptying, and `addAll(otherCollection)` for adding many elements at once. There are also operations like `intersect`, `union`, and `minus` for combining sets in mathematical ways.

### Choosing Between Set, List, and Map

Each collection type has a sweet spot:

A `List` is right when order matters and duplicates are allowed. Lists are the most common collection because most data has a natural order (creation order, sort order, or user-defined order). Catatku's tasks live in a `MutableList` because each task has a specific position in the user's list.

A `Set` is right when you need to track membership without duplicates and order does not matter. Sets are useful for things like "which tags has this task been given" (each tag should appear at most once) or "which user IDs have logged in today" (each ID should be counted once).

A `Map` is right when you have key-value associations: looking up values by some identifier. Maps are useful for things like "what is the priority label for this priority code", "what is the user's name given their ID", or "what is the count for each category". Whenever you have data of the form "given X, what is Y", a map is usually right.

These are guidelines, not rules. Sometimes you can use any of the three and the choice is style or performance preference. As a habit, start with `List` and switch to `Set` or `Map` only when one of their specific advantages (deduplication, fast lookup) is clearly needed.

---

## 5. Standard-Library Functions: A Preview

The Kotlin standard library has dozens of useful functions for working with collections. Lesson 13 covers them in depth as part of higher-order functions; for now, here is a preview of the most useful ones.

### Step 1: filter, map, and joinToString

These three are probably the most commonly used collection functions:

```kotlin
fun main() {
    val tasks = listOf("Pay rent", "Buy groceries", "Call dentist", "Walk the dog")
    
    val longTasks = tasks.filter { it.length > 10 }
    println("Long tasks: $longTasks")
    
    val upperTasks = tasks.map { it.uppercase() }
    println("Uppercase: $upperTasks")
    
    val joined = tasks.joinToString(", ")
    println("Joined: $joined")
    
    val numbered = tasks.mapIndexed { i, task -> "${i + 1}. $task" }
    println("Numbered:")
    for (line in numbered) {
        println("  $line")
    }
}
```

Save and run. Output:

```text
Long tasks: [Buy groceries, Call dentist, Walk the dog]
Uppercase: [PAY RENT, BUY GROCERIES, CALL DENTIST, WALK THE DOG]
Joined: Pay rent, Buy groceries, Call dentist, Walk the dog
Numbered:
  1. Pay rent
  2. Buy groceries
  3. Call dentist
  4. Walk the dog
```

Each function takes a lambda and produces a new collection (or string). `filter { ... }` keeps elements where the lambda returns true. `map { ... }` transforms each element using the lambda. `joinToString(separator)` builds a single string by separator-joining the elements. `mapIndexed { i, item -> ... }` is like `map` but the lambda also receives the index.

The lambda syntax with the `it` parameter is what we will cover in Lesson 13. For now, read the examples by analogy: `filter { it.length > 10 }` keeps elements whose length is greater than 10, where `it` is the placeholder for "each element".

### Step 2: count, any, all, none

These functions answer common boolean questions about collections:

```kotlin
fun main() {
    val numbers = listOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    
    println("Total count: ${numbers.size}")
    println("Even count: ${numbers.count { it % 2 == 0 }}")
    println("Any > 7: ${numbers.any { it > 7 }}")
    println("All > 0: ${numbers.all { it > 0 }}")
    println("None > 100: ${numbers.none { it > 100 }}")
}
```

Save and run. Output:

```text
Total count: 10
Even count: 5
Any > 7: true
All > 0: true
None > 100: true
```

Each function asks a specific question: how many match the predicate (`count`), is at least one a match (`any`), are all matches (`all`), are none matches (`none`). These are short and readable replacements for hand-written loops with counters and flags.

### Step 3: sum, sumOf, average, max, min

For numeric collections, several aggregating functions are built in:

```kotlin
fun main() {
    val scores = listOf(78, 92, 64, 85, 71)
    
    println("Sum: ${scores.sum()}")
    println("Average: ${scores.average()}")
    println("Max: ${scores.max()}")
    println("Min: ${scores.min()}")
    
    // sumOf is for transforming then summing
    val taskLengths = listOf("Pay rent", "Buy groceries", "Call dentist")
    val totalChars = taskLengths.sumOf { it.length }
    println("Total characters: $totalChars")
}
```

Save and run. Output:

```text
Sum: 390
Average: 78.0
Max: 92
Min: 64
Total characters: 33
```

Each function does what its name suggests. `sum()` works on lists of numbers. `average()` returns a `Double`. `max()` and `min()` return the largest and smallest elements (and throw if the list is empty; use `maxOrNull` and `minOrNull` for the safer variants). `sumOf { ... }` applies a transformation and sums the results, which is a tidy combination of `map` and `sum` in one call.

These are just a sampling of the standard-library collection functions. The full list is in the official Kotlin documentation, and you will absorb more of them as the course progresses. For now, the takeaway is that Kotlin has a rich vocabulary for collection operations, and writing collection code idiomatically often means picking the right function rather than writing a loop.

---

## 6. Run and Test

Combine everything into one program that uses each collection type and a few of the standard-library functions.

### Step 1: Build the Combined Example

Replace `Main.kt` with this comprehensive example:

```kotlin
fun main() {
    // A list of task descriptions
    val tasks = mutableListOf(
        "Pay rent",
        "Finish Kotlin course",
        "Call dentist",
        "Buy groceries",
        "Read for fun"
    )
    
    // A map from priority codes to labels
    val priorityLabels = mapOf(
        "H" to "High",
        "M" to "Medium",
        "L" to "Low"
    )
    
    // A set of categories
    val categories = setOf("personal", "work", "health", "personal")  // duplicate intentional
    
    // Standard-library operations
    val longTasks = tasks.filter { it.length > 10 }
    val joined = tasks.joinToString(", ")
    val totalChars = tasks.sumOf { it.length }
    val averageLength = tasks.map { it.length }.average()
    
    // Iteration with index
    println("Catatku tasks (${tasks.size} total):")
    for ((index, task) in tasks.withIndex()) {
        println("  ${index + 1}. $task")
    }
    
    println("\nLong tasks (>10 chars): $longTasks")
    println("All tasks one line: $joined")
    println("Total chars: $totalChars")
    println("Average task length: ${"%.1f".format(averageLength)}")
    
    println("\nPriority labels:")
    for ((code, label) in priorityLabels) {
        println("  $code -> $label")
    }
    
    println("\nCategories (deduplicated): $categories")
    println("Has 'personal': ${categories.contains("personal")}")
    
    // Modify the mutable list
    tasks.add("Take a break")
    tasks.removeAt(0)
    println("\nAfter modifications:")
    for (task in tasks) {
        println("  - $task")
    }
}
```

Save and run.

### Step 2: Read the Output

The output is:

```text
Catatku tasks (5 total):
  1. Pay rent
  2. Finish Kotlin course
  3. Call dentist
  4. Buy groceries
  5. Read for fun

Long tasks (>10 chars): [Finish Kotlin course, Call dentist, Buy groceries, Read for fun]
All tasks one line: Pay rent, Finish Kotlin course, Call dentist, Buy groceries, Read for fun
Total chars: 65
Average task length: 13.0

Priority labels:
  H -> High
  M -> Medium
  L -> Low

Categories (deduplicated): [personal, work, health]
Has 'personal': true

After modifications:
  - Finish Kotlin course
  - Call dentist
  - Buy groceries
  - Read for fun
  - Take a break
```

Walk through what each piece contributed. The `mutableListOf` creates a list we can add to and remove from. The `mapOf` with `"H" to "High"` syntax creates a key-value mapping. The `setOf` automatically deduplicates the input. The standard-library functions (`filter`, `joinToString`, `sumOf`, `map(...).average()`) produce derived values without modifying the originals. Iteration with destructuring (`(index, task)`) and (`(code, label)`) walks through indexed and key-value sequences. Finally the mutations (`add`, `removeAt`) demonstrate that the mutable list responds to changes.

This single program touches every collection concept from the lesson. If you can read it fluently and predict what each line will do, you have absorbed the material. If parts are confusing, identify those parts and reread the relevant section before moving on.

### Step 3: Try a Few Modifications

Change the input data and rerun. Add more tasks, change the priority codes, add or remove categories. Each change should produce predictable output. If something surprises you, that is a sign of an interaction you have not fully internalized yet, which is useful information.

A more substantive modification: try replacing the parallel list pattern (where we have separate variables for tasks, priorities, and categories) with a single list of "task records" where each record is a `Map<String, Any>` containing all the fields. This is closer to how Catatku will eventually work, but uses `Map` rather than the dedicated `Task` class we will introduce in Lesson 10. The exercise lets you see the intermediate step between "scattered data" and "real types".

---

## 7. Fix the Errors in Your Code

Three collection mistakes are common in early Kotlin code.

**Error 1: Modifying a read-only list**

```kotlin
// Wrong
fun main() {
    val tasks = listOf("a", "b", "c")
    tasks.add("d")
    println(tasks)
}

// Correct
fun main() {
    val tasks = mutableListOf("a", "b", "c")
    tasks.add("d")
    println(tasks)
}
```

`listOf` returns a read-only `List<T>`, which does not have `add`, `remove`, or other mutation methods. The compiler reports `Unresolved reference 'add'.`, which literally means the method does not exist on that type. The fix depends on whether you really need to modify: if yes, change to `mutableListOf`, as the correct version does, and the program prints `[a, b, c, d]`; if no, compute a new list with `tasks + "d"`, which leaves the original untouched. As a habit, default to `listOf` and switch to `mutableListOf` only when you need to.

**Error 2: Indexing past the end of a list**

```kotlin
// Wrong
fun main() {
    val tasks = listOf("a", "b", "c")
    val fifth = tasks[5]
    println(fifth)
}

// Correct
fun main() {
    val tasks = listOf("a", "b", "c")
    val fifth = tasks.getOrNull(5) ?: "(no such task)"
    println(fifth)
}
```

Indexing past the end of a list fails at runtime, not at compile time. The wrong version compiles and then stops with `Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index 5 out of bounds for length 3` (a more specific kind of `IndexOutOfBoundsException`). The fix is to either check the index against `tasks.size` first or use `getOrNull(i)`, which returns null instead of throwing. The latter integrates with null safety: the correct version chains `?:` to supply a fallback and prints `(no such task)`. As a habit, prefer `getOrNull` when the index might be out of range, and reserve direct indexing for cases where you are certain the index is valid.

**Error 3: Treating a map lookup as non-null**

```kotlin
// Wrong
fun main() {
    val priorities = mapOf("H" to "High")
    val length: Int = priorities["X"].length
    println(length)
}

// Correct
fun main() {
    val priorities = mapOf("H" to "High")
    val length: Int = priorities["X"]?.length ?: 0
    println(length)
}
```

Map lookup with `[]` returns `V?` (a nullable value type) because the key might not be in the map. The compiler rejects the wrong version with `Only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'kotlin.String?'.` The fix is to handle the null case with `?.length` and `?:` for a fallback, as the correct version does (it prints `0` because `"X"` is not a key), or with a smart cast in an `if` block. Alternatively, use `getValue(key)`, which throws `NoSuchElementException` for missing keys but returns a non-null type. Most code uses the safe `[]` form because handling null is usually preferable to handling exceptions.

---

## 8. Exercises

These exercises practice collection operations.

**Exercise 1:** Create a `MutableList<Int>` of test scores (pick five numbers between 0 and 100). Print the list, then add a sixth score, remove the lowest score, and print the modified list. Use `min()` and `remove()` methods.

**Exercise 2:** Create a `Map<String, Int>` of word counts (pick a few words and their imagined frequencies). Iterate over the map and print each word with its count. Then use `filter` to find only the words with count greater than 5 and print them.

**Exercise 3:** Given a list of task descriptions, write code that produces a summary: total count, average description length (rounded to one decimal), longest description, and shortest description. Use `size`, `map`, `average`, `maxByOrNull` (or `maxBy` if your Kotlin version supports it), and `minByOrNull`.

---

## 9. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

The scores change during the program, so they live in a `MutableList<Int>`.

```kotlin
fun main() {
    val scores = mutableListOf(78, 92, 64, 85, 71)
    println("Scores: $scores")
    
    scores.add(88)
    println("After add: $scores")
    
    val lowest = scores.min()
    scores.remove(lowest)
    println("After removing lowest ($lowest): $scores")
}
```

Save and run. Output:

```text
Scores: [78, 92, 64, 85, 71]
After add: [78, 92, 64, 85, 71, 88]
After removing lowest (64): [78, 92, 85, 71, 88]
```

`add(88)` appends the new score at the end. `min()` returns the smallest value without changing the list, and we keep it in `lowest` so the last line can report which score was dropped. `remove(lowest)` removes the first element equal to that value. Be careful with `remove` on a list of `Int`: `remove(64)` removes the value 64, while `removeAt(2)` removes whatever sits at index 2.

**Solution for Exercise 2:**

A map holds each word with its count, a `for` loop with destructuring prints the pairs, and `filter` keeps only the frequent words.

```kotlin
fun main() {
    val wordCounts = mapOf("kotlin" to 12, "null" to 3, "list" to 8, "class" to 5)
    
    for ((word, count) in wordCounts) {
        println("$word: $count")
    }
    
    val frequent = wordCounts.filter { (_, count) -> count > 5 }
    println("Count greater than 5: $frequent")
}
```

Save and run. Output:

```text
kotlin: 12
null: 3
list: 8
class: 5
Count greater than 5: {kotlin=12, list=8}
```

The loop `for ((word, count) in wordCounts)` unpacks each map entry into its key and value, in insertion order. `filter` on a map receives each entry and returns a new map with only the entries whose condition is true. Inside the lambda, `(_, count)` destructures the entry and ignores the key with `_`, because only the count matters for the test. The word `class` has a count of exactly 5, so `count > 5` leaves it out.

**Solution for Exercise 3:**

This exercise practices using several standard-library functions together to compute a summary.

```kotlin
fun main() {
    val tasks = listOf(
        "Pay rent",
        "Finish Kotlin course",
        "Call dentist",
        "Buy groceries",
        "Read"
    )
    
    val count = tasks.size
    val averageLength = tasks.map { it.length }.average()
    val longest = tasks.maxByOrNull { it.length } ?: "(none)"
    val shortest = tasks.minByOrNull { it.length } ?: "(none)"
    
    println("Total tasks: $count")
    println("Average length: ${"%.1f".format(averageLength)}")
    println("Longest: '$longest' (${longest.length} chars)")
    println("Shortest: '$shortest' (${shortest.length} chars)")
}
```

Save and run. Output:

```text
Total tasks: 5
Average length: 11.4
Longest: 'Finish Kotlin course' (20 chars)
Shortest: 'Read' (4 chars)
```

The function uses several standard-library operations together. `tasks.size` is the count. `tasks.map { it.length }.average()` first transforms each task to its length (giving a list of integers), then computes the average. `maxByOrNull { it.length }` finds the element whose length is largest, returning `String?` because the list might be empty. The `?: "(none)"` provides a fallback for the empty case. `minByOrNull` works the same way for the smallest. The `"%.1f".format(...)` formats a number to one decimal place.

This kind of summary code is the basic shape of data-processing logic. Each piece is a small named operation that produces a value, and the operations chain together to compute the final result. The Kotlin standard library is rich enough that most summary computations can be expressed as a chain of these functions rather than as a hand-written loop with mutable accumulators. The chained style is shorter, easier to read once you know the vocabulary, and less error-prone because there is no mutable state to get wrong.

A small note about `maxByOrNull` versus `maxBy`: in Kotlin 2.x, `maxBy` returns a non-null value and throws `NoSuchElementException` when the list is empty, while `maxByOrNull` returns null for an empty list. Very old codebases (before Kotlin 1.4) used `maxBy` with the nullable meaning, so read it carefully there. In new code, pick `maxByOrNull` when the list might be empty and `maxBy` when you are certain it is not.

---

## 10. Understanding the Read-Only vs Mutable Split

Kotlin's choice to have separate `List` and `MutableList` interfaces (and similarly for maps and sets) is unusual. Java has a single `List` interface that supports modifications, with optional read-only views via `Collections.unmodifiableList`. Most other languages either have only mutable collections or only immutable ones. Kotlin's split is deliberate, and understanding why illuminates a lot about how the language wants you to write code.

The first reason is intent communication. When a function takes a `List<T>` parameter, callers know the function will not modify the list. When the parameter is `MutableList<T>`, callers know modification is on the table. This visible contract makes APIs clearer: a function's signature tells you what the function might do to its input without you having to read the body. In Java, the only way to indicate "this function does not modify the list" is documentation, which is inconsistently followed and not enforced by the compiler.

The second reason is defensive coding. When you receive a collection from outside your code (an API call, a function parameter, a configuration), you often want to be sure it will not be modified by the code you pass it to. With `List<T>`, the type system enforces this: even if the underlying object is mutable, the read-only interface does not expose mutation methods. Code working through a `List<T>` reference cannot modify the collection, which means you can pass the same collection to many places without worrying about one of them changing it. This is a kind of immutability-by-discipline that the type system enforces.

The third reason is concurrency. Read-only collections are safer to share across threads because (assuming the underlying data is also immutable) they cannot be modified by any thread, which eliminates a class of race conditions. We are not covering concurrency in this course, but the patterns you build with `val` and `List` here will transfer naturally to multi-threaded code later, where the discipline pays off.

The cost of the split is a small mental overhead at the start: you have to decide between `List` and `MutableList` for each variable, parameter, and return type, where some other languages would just have one option. With practice this becomes second nature: `List` for "I just want to read" and `MutableList` for "I will modify". The Kotlin standard library follows this convention rigorously, and following it in your own code makes the code blend in with the ecosystem.

A subtle but important point: `List<T>` is read-only, not immutable. The underlying object might still be a `MutableList<T>` viewed through the `List<T>` interface, and code that holds the `MutableList<T>` reference can still modify it. So the read-only-ness is about what you can do through that particular reference, not about what the collection itself can do. For genuinely immutable collections (where nothing can modify them), you would use libraries like `kotlinx.collections.immutable`. For most application code, the read-only views are sufficient because you control who has the mutable reference.

A common pattern in Kotlin code is to expose a `List<T>` as the public API while holding a `MutableList<T>` internally. This way, the class can modify the internal list as needed, but external code only sees the read-only view and cannot accidentally corrupt the state. We will use exactly this pattern in Lesson 17 when we define `EntryList` for Catatku: the `entries` field is a private `MutableList<Entry>`, and the public `all()` method returns a read-only `List<Entry>` snapshot for external readers.

---

## Next Up - Lesson 9

Kotlin's collection types come in three primary forms (List, Map, Set), each with a read-only interface and a mutable variant. Lists store ordered elements accessed by index. Maps store key-value pairs. Sets store unique elements. The factory functions (`listOf`, `mapOf`, `setOf` and their `mutable` variants) create instances tersely. The choice between read-only and mutable encodes intent: read-only signals "I will not modify" while mutable signals "I may modify". The standard library has a rich set of extension functions (`filter`, `map`, `joinToString`, `count`, `any`, `all`, `none`, `sum`, `sumOf`, `average`, `maxByOrNull`, and many more) that turn collections into pipelines of named operations. We will use these extensively in Lesson 13 when we cover lambdas and higher-order functions in depth.

In Lesson 9 you will start building real types: classes with primary constructors, properties, methods, and visibility modifiers. Classes are how you bundle related data and behavior together, and they are the foundation for the data classes (Lesson 10) and sealed classes (Lesson 11) that Catatku's `Entry` and `Status` types will use.
