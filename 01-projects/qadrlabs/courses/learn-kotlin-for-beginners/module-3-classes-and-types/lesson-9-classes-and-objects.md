## 1. Before You Begin

Up to this point Catatku's data has been scattered across loose variables and parallel lists: one list of descriptions, one list of priorities, one list of statuses. That worked for demonstrating control flow and functions, but it does not scale. Real programs have data with structure, where a "task" is not just a description but a description plus a priority plus a status plus a created-at timestamp, all bundled together as one logical unit. Classes are how Kotlin (and most other modern languages) lets you define such bundles, giving them a name and behavior of their own. Once you have an `Entry` class, code that works with entries can pass around single `Entry` values rather than juggling three or four parallel arrays.

Kotlin's class syntax is more concise than Java's, mostly because of two features that you will use in nearly every class you write: primary constructors that declare the parameters and properties on the same line as the class name, and properties that combine field and getter/setter into a single declaration. This lesson also covers secondary constructors, the `init` block, the `this` keyword, the visibility modifiers (`public`, `private`, `internal`, `protected`), and the `companion object` for static-like members. The result is that a class with three fields and a constructor takes about three lines of Kotlin instead of fifteen lines of Java. This concision adds up across a real codebase, but the bigger benefit is that the structure of the class is visible at a glance: when you read the class header, you immediately see what data the class holds.

### What You'll Build

A `Counter` class inside `Main.kt` that holds a count, exposes operations to increment and reset it, and tracks how many times it has been incremented across all instances using a `companion object`. You will also see a small preview of how the `Entry` class will look in Lesson 10 when we introduce data classes; for now, the `Counter` is enough to make every concept concrete.

### What You'll Learn

- ✅ How to declare a class with `class` and a primary constructor
- ✅ How `val` and `var` in the constructor header create properties
- ✅ How to write member functions and use `this`
- ✅ How visibility modifiers control access
- ✅ How `companion object` provides static-like behavior

### What You'll Need

- The `catatku` Gradle project from previous lessons
- A solid understanding of functions from Lesson 6 and null safety from Lesson 7
- About forty minutes
- Curiosity about how Kotlin's classes differ from Java's, if you have a Java background

---

## 2. Declaring a Class

A class in Kotlin is declared with the `class` keyword, optionally followed by a primary constructor in parentheses, and a body in curly braces.

### Step 1: Write the Smallest Possible Class

Open `Main.kt` and replace its contents with this minimal example:

```kotlin
class Counter

fun main() {
    val c = Counter()
    println("Created a counter: $c")
}
```

Save and run. Output:

```text
Created a counter: Counter@8bcc55f
```

The class declaration `class Counter` introduces a new type named `Counter`. The class has no body, no constructor parameters, no methods, no properties; it is the minimum that compiles. Even so, you can create instances with `Counter()`, the same way you call a function. The default constructor takes no arguments and produces an instance with no state.

When you print a class instance with default behavior, Kotlin shows the class name plus a hash code (the `@8bcc55f` part). The hash code is different on every run and on every machine, so do not worry if yours does not match. This is not very useful; we will see in Lesson 10 how data classes give you a cleaner default representation. For regular classes you can override the `toString` method to control the output.

### Step 2: Add a Primary Constructor

The primary constructor goes in parentheses after the class name. Each parameter has a name and a type, just like function parameters.

```kotlin
class Counter(initialValue: Int)

fun main() {
    val c = Counter(0)
    println("Created a counter starting at... well, we cannot read it yet")
}
```

Save and run. Output:

```text
Created a counter starting at... well, we cannot read it yet
```

The primary constructor declares one parameter `initialValue` of type `Int`. To create an instance, we now have to pass an argument: `Counter(0)`. The parameter is just a parameter at this point; it is not stored anywhere accessible from outside the class. To make it accessible, we mark it with `val` or `var`, which turns it into a property.

### Step 3: Convert Constructor Parameters to Properties

```kotlin
class Counter(val initialValue: Int)

fun main() {
    val c = Counter(10)
    println("Initial value: ${c.initialValue}")
}
```

Save and run. Output:

```text
Initial value: 10
```

Adding `val` (or `var`) before the parameter name turns it into a property. Now the value is accessible from outside the class via the `.initialValue` syntax. Properties created this way are also stored as fields inside the instance, so each `Counter` you create has its own `initialValue`.

The choice between `val` and `var` for a property is the same as for a regular variable: `val` means read-only after construction, `var` means mutable. For values that should not change after the object is built, use `val`. For values that change over time, use `var`. The convention for most data classes (Lesson 10) is to use `val` everywhere, because immutability is generally preferred.

This combined declaration (constructor parameter + property) is one of Kotlin's most common shortcuts. The Java equivalent would be:

```java
public class Counter {
    private final int initialValue;
    public Counter(int initialValue) {
        this.initialValue = initialValue;
    }
    public int getInitialValue() {
        return initialValue;
    }
}
```

About 9 lines for what Kotlin does in 1 line. Multiply this savings across every class in a real project and you start to feel why Kotlin code feels lighter than Java code.

---

## 3. Properties and State

Properties are how a class stores its state. We saw that constructor parameters with `val` or `var` become properties, but you can also declare properties inside the class body for state that is not initialized from the constructor.

### Step 1: Add a Mutable Property

Replace the body of the file with:

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
}

fun main() {
    val c = Counter(10)
    println("Initial: ${c.initialValue}")
    println("Count: ${c.count}")
    
    c.count = 20
    println("After change: ${c.count}")
}
```

Save and run. Output:

```text
Initial: 10
Count: 10
After change: 20
```

The line `var count: Int = initialValue` declares a mutable property named `count` initialized from the constructor parameter `initialValue`. Inside the class body, we can refer to the constructor parameter directly because it is in scope during property initialization. After construction, the parameter `initialValue` is no longer accessible (it is just a parameter, not a property, unless we marked it with `val` or `var`). However, in this example we did mark it with `val`, so it is also a property and remains accessible.

The `count` property starts at `initialValue` and can be reassigned. From outside the class, you read and write properties with the dot syntax: `c.count` reads, `c.count = 20` writes. This is the same syntax as accessing fields in Java, but Kotlin compiles it to getter and setter calls under the hood, which lets the class control the access if it wants to.

### Step 2: Add Computed Properties

Properties can also have custom getters that compute their value rather than reading a stored field. This is useful for derived state:

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
    
    val isPositive: Boolean
        get() = count > 0
    
    val description: String
        get() = "Counter at $count (started at $initialValue)"
}

fun main() {
    val c = Counter(5)
    println(c.description)
    println("Is positive? ${c.isPositive}")
    
    c.count = -3
    println(c.description)
    println("Is positive? ${c.isPositive}")
}
```

Save and run. Output:

```text
Counter at 5 (started at 5)
Is positive? true
Counter at -3 (started at 5)
Is positive? false
```

The `val isPositive: Boolean` declaration with `get() = count > 0` says "this property has type `Boolean`, and its value is computed by the expression `count > 0`". Each time you read `c.isPositive`, the getter runs and produces the current value. There is no stored field; the value is derived on demand.

The same pattern works for `description`: each read of `c.description` constructs the string fresh from the current `count` and the immutable `initialValue`. Computed properties are great for things like "is this counter positive", "what is the percentage progress", or "what is the formatted display name", where the value is a function of other state and you want to compute it lazily.

### When to Use Properties vs Methods

Sometimes you can express the same idea as either a property or a method. For example, instead of `val isPositive: Boolean get() = count > 0`, you could write `fun isPositive(): Boolean = count > 0`. Both work. Which to choose?

The convention is: use a property when the value is conceptually a state of the object (the object "has" a name, "is" positive, "has" a count) and the computation is cheap. Use a method when the operation does work, has side effects, or takes parameters. So `c.isPositive` is a property because being positive is a state, and computing it is just one comparison. But `c.increment()` is a method because incrementing does work and changes state.

When in doubt, lean toward properties for read-only attributes and methods for actions. The Kotlin standard library follows this convention rigorously: `list.size` is a property, `list.add(x)` is a method, `string.length` is a property, `string.uppercase()` is a method.

---

## 4. Member Functions

Member functions (methods) are functions defined inside a class that operate on instances of the class. They are declared the same way as top-level functions but live inside the class body.

### Step 1: Add a Method

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
    
    fun increment() {
        count = count + 1
    }
    
    fun reset() {
        count = initialValue
    }
}

fun main() {
    val c = Counter(0)
    println("Start: ${c.count}")
    
    c.increment()
    c.increment()
    c.increment()
    println("After three increments: ${c.count}")
    
    c.reset()
    println("After reset: ${c.count}")
}
```

Save and run. Output:

```text
Start: 0
After three increments: 3
After reset: 0
```

The methods `increment` and `reset` are defined inside the class body. Both modify `count` (and `reset` reads `initialValue`). Inside a method, you can refer to other properties and methods of the same class directly, without any prefix. The implicit "current instance" is what `this` refers to, but you usually do not need to write `this` because the resolution is automatic.

Methods are called from outside the class using the dot syntax: `c.increment()`. Each call operates on the specific instance: calling `c.increment()` increments `c`'s count, but a different counter instance would have its own count.

### Step 2: Add a Method That Returns a Value

Methods can return values just like top-level functions:

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
    
    fun increment() {
        count = count + 1
    }
    
    fun reset() {
        count = initialValue
    }
    
    fun stepsTaken(): Int = count - initialValue
}

fun main() {
    val c = Counter(10)
    c.increment()
    c.increment()
    c.increment()
    
    println("Count: ${c.count}, steps taken: ${c.stepsTaken()}")
}
```

Save and run. Output:

```text
Count: 13, steps taken: 3
```

The method `stepsTaken()` returns an `Int` computed from `count` and `initialValue`. As a single-expression function (Lesson 6), the return type can be inferred but is shown explicitly here for clarity. The method does not modify any state; it just reads the current values and returns a derived result.

Notice that `stepsTaken()` is a method (called with parentheses) rather than a computed property. The choice was style: it does involve subtraction, which is "doing work", and the name reads like an action. Either form would work, and you could refactor to a property by writing `val stepsTaken: Int get() = count - initialValue`. Pick whichever feels right for the situation.

### Step 3: Use this Explicitly

Inside a method, `this` refers to the current instance. You usually do not need to write it because property and method resolution is automatic, but `this` is required when a parameter or local variable shadows a property of the same name:

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
    
    fun setTo(count: Int) {
        // The parameter 'count' shadows the property 'count'.
        this.count = count
    }
}

fun main() {
    val c = Counter(0)
    c.setTo(42)
    println(c.count)
}
```

Save and run. Output:

```text
42
```

Inside `setTo`, `count` refers to the parameter (the local variable), so `this.count` is needed to refer to the property. Without `this`, the line `count = count` would try to assign to the parameter, and function parameters in Kotlin are read-only, so the compiler stops with `'val' cannot be reassigned.`

This kind of shadowing is common in setter methods and constructors, where the parameter name often matches the property name for clarity. Using `this` to disambiguate is standard practice. As a matter of style, some programmers always write `this.property` when assigning, even when there is no shadow, because it makes the assignment self-documenting; others only use `this` when needed. Either is fine.

---

## 5. The init Block

When a constructor needs to do work beyond just assigning parameters to properties, you put that work in an `init` block. The block runs once during construction, in the order it appears in the class body.

### Step 1: Add Validation

A common use of `init` is validating constructor arguments:

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
    
    init {
        require(initialValue >= 0) { "Counter cannot start negative, got $initialValue" }
        println("Counter created with initial value $initialValue")
    }
    
    fun increment() {
        count += 1
    }
}

fun main() {
    val c = Counter(5)
    c.increment()
    println("Final: ${c.count}")
    
    // The next line would throw IllegalArgumentException:
    // val bad = Counter(-1)
}
```

Save and run. Output:

```text
Counter created with initial value 5
Final: 6
```

The `init` block runs during construction, after the property declarations are initialized but before the instance is fully created. The `require` function is a standard-library helper that throws `IllegalArgumentException` if its condition is false, with the message provided by the lambda. This is a clean way to validate inputs at construction time.

If you uncomment the `Counter(-1)` line, the program crashes during that line's execution. The first line of the error is:

```text
Exception in thread "main" java.lang.IllegalArgumentException: Counter cannot start negative, got -1
```

Validation in the constructor is one of the ways classes encode invariants. By running this check at construction, we guarantee that no `Counter` instance can ever exist with a negative `initialValue`. Code that uses a `Counter` does not have to defensively check that `initialValue` is positive; the type system has already proven it.

### Step 2: Multiple init Blocks

You can have multiple `init` blocks. They run in the order they appear in the class body:

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
    
    init {
        println("First init: count = $count")
    }
    
    val description: String = "Counter starting at $initialValue"
    
    init {
        println("Second init: description = $description")
    }
}

fun main() {
    Counter(5)
}
```

Save and run. Output:

```text
First init: count = 5
Second init: description = Counter starting at 5
```

The two init blocks run in order, interleaved with the property initializations. Properties declared above an init block are initialized before that block; properties declared below are initialized after. This ordering matters when properties depend on each other, but for most classes a single init block at the end of the property declarations is enough.

In practice, most classes do not need an init block at all because the property initializers in the constructor parameters and body are sufficient. Reach for `init` when you need validation, logging during construction, or computation that does not fit neatly into a property initializer.

### Step 3: When to Use a Secondary Constructor

Most classes have a single way to construct them, declared in the primary constructor. But sometimes you want alternate construction paths, like "construct from a JSON string" or "construct from a different combination of inputs". For these, Kotlin supports secondary constructors declared with `constructor` inside the class body:

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
    
    constructor(): this(0)
    
    fun increment() { count += 1 }
}

fun main() {
    val c1 = Counter(10)
    val c2 = Counter()  // uses the secondary constructor
    
    println("c1: ${c1.count}")
    println("c2: ${c2.count}")
}
```

Save and run. Output:

```text
c1: 10
c2: 0
```

The secondary constructor `constructor(): this(0)` takes no parameters and delegates to the primary constructor with `this(0)`. So `Counter()` is equivalent to `Counter(0)`. This is occasionally useful when you want a no-argument constructor to coexist with the parameterized one.

In practice, default arguments often replace secondary constructors. Instead of writing a secondary constructor, you can give the primary constructor's parameter a default: `class Counter(val initialValue: Int = 0)`. Now `Counter()` works without the extra constructor. We will see this pattern with default arguments throughout the course; secondary constructors are useful but not commonly needed in idiomatic Kotlin.

---

## 6. Visibility Modifiers

By default, classes and their members are `public`, meaning visible from anywhere. Kotlin has four visibility levels: `public`, `internal`, `protected`, and `private`. The most useful ones for everyday code are `public` and `private`.

### Step 1: Use private to Hide Internals

Replace the body of `main` and the class with this:

```kotlin
class Counter(initialValue: Int) {
    private var count: Int = initialValue
    private val maxValue: Int = 100
    
    fun increment() {
        if (count < maxValue) {
            count += 1
        }
    }
    
    fun current(): Int = count
}

fun main() {
    val c = Counter(0)
    c.increment()
    c.increment()
    c.increment()
    
    println("Current value: ${c.current()}")
    
    // The next lines would not compile:
    // println(c.count)        // count is private
    // println(c.maxValue)     // maxValue is private
}
```

Save and run. Output:

```text
Current value: 3
```

Both `count` and `maxValue` are marked `private`, which means they are accessible only inside the class itself. From outside (like inside `main`), trying to access `c.count` is a compile error: `Cannot access 'var count: Int': it is private in '/Counter'.` To read the count, the class exposes a `current()` method, which is public by default.

This pattern is encapsulation: hide implementation details, expose only the methods you want callers to use. The benefit is that you can change how `count` is stored or computed later (perhaps store it as two separate fields, or compute it from a different source) without breaking any caller's code, because no caller has access to the field directly. They go through the `current()` method, which can be reimplemented to provide the same value from a new internal representation.

For Catatku's `EntryList` class in Lesson 17, we will use exactly this pattern: the underlying `MutableList<Entry>` will be private, and the public API will be methods like `add`, `remove`, and `find`. This way, we can later change the internal storage (perhaps to a `Map` keyed by id for faster lookups) without breaking any code that uses `EntryList`.

### The Other Visibility Modifiers

The four visibility levels are:

`public` (the default): visible everywhere. Most things you write are public.

`private`: visible only inside the same class (or, for top-level declarations, inside the same file). Use for implementation details that should not be exposed.

`internal`: visible within the same module. A "module" is roughly a project or a Gradle subproject. Use for things you want to expose to your own code but hide from libraries that use yours.

`protected`: visible inside the class and its subclasses. Use rarely; most classes do not have subclasses, and `private` plus `internal` cover most needs.

For Catatku and most application code, you will use `public` (default) and `private` almost exclusively. `internal` becomes relevant in larger projects with multiple modules. `protected` is mostly for library design where you want to provide hooks for subclasses to customize.

### A Note on File-Level Privacy

For top-level functions and classes, `private` means "private to the file". This is more restrictive than Java's package-private (which would be `internal` for "module-private" in Kotlin). It means a private top-level function in `Helpers.kt` cannot be called from `Main.kt`, even if both files are in the same package.

This file-level privacy is useful for utility functions that are only meaningful within one file. Top-level helper functions that you do not want to expose to other files can be marked `private`, keeping the public API of the file (and the package) clean.

---

## 7. companion object for Static-Like Members

Kotlin does not have static members the way Java does. Instead, you declare members inside a `companion object` block, which is a singleton object associated with the class. Members of the companion object are accessible from outside as `ClassName.member`, similar to how you access `String.format` in Java.

### Step 1: Track the Number of Instances

A common use is tracking how many instances have been created across the whole program:

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
    
    init {
        instanceCount += 1
    }
    
    fun increment() { count += 1 }
    
    companion object {
        private var instanceCount: Int = 0
        
        fun totalCreated(): Int = instanceCount
    }
}

fun main() {
    val c1 = Counter(0)
    val c2 = Counter(10)
    val c3 = Counter(100)
    
    println("Total counters created: ${Counter.totalCreated()}")
}
```

Save and run. Output:

```text
Total counters created: 3
```

The `companion object { ... }` block contains members that are shared across all instances of the class. The `instanceCount` variable lives in the companion object, so there is one of it across the whole program (not one per instance). Each time the `Counter` constructor runs, the `init` block increments the companion's `instanceCount`. The function `totalCreated()` returns the current value.

From outside, we access companion-object members with the class name: `Counter.totalCreated()`. The companion object is implicitly named (you can give it a name if you want), and members of it become "static-like" in their access pattern.

A subtle point: even though `instanceCount` is `private` to the companion object, the class's own `init` block can read and modify it because the companion object is part of the class. The visibility scoping treats the class and its companion object as one unit for access purposes.

### Step 2: Companion Object for Factory Methods

Another common use of companion objects is providing alternate construction methods (factory methods):

```kotlin
class Counter(val initialValue: Int) {
    var count: Int = initialValue
    
    fun increment() { count += 1 }
    
    companion object {
        fun zero(): Counter = Counter(0)
        fun startingAt(value: Int): Counter = Counter(value)
    }
}

fun main() {
    val c1 = Counter.zero()
    val c2 = Counter.startingAt(50)
    
    c1.increment()
    c2.increment()
    c2.increment()
    
    println("c1.count: ${c1.count}")
    println("c2.count: ${c2.count}")
}
```

Save and run. Output:

```text
c1.count: 1
c2.count: 52
```

The factory methods `zero()` and `startingAt(value)` are static-like alternatives to the primary constructor. They give callers convenience names for common construction patterns. This is similar to Java's static factory methods (like `List.of(...)` or `Optional.empty()`), and the syntax is essentially the same.

For Catatku we will not use companion objects heavily, but they are good to know about because they appear constantly in standard library and third-party APIs. The Kotlin standard library uses companion objects extensively for things like `Int.MAX_VALUE`, `String.format`, and many factory methods.

### When Not to Use companion object

Static-like members exist for a reason, but they can also be overused. As a habit, prefer top-level functions over companion-object methods for utility functions that do not need access to private class members. Top-level functions are simpler to declare, simpler to test, and discoverable by their name without knowing the class.

Reserve `companion object` for things genuinely associated with the class: constants that belong to the class, factory methods, instance counters, or other state that scopes to the class as a whole. For everything else, top-level functions are cleaner.

---

## 8. Run and Test

Combine everything from this lesson into one program that uses every feature.

### Step 1: Build the Combined Example

Replace `Main.kt` with this:

```kotlin
class Counter(initialValue: Int = 0) {
    private var count: Int = initialValue
    private val origin: Int = initialValue
    
    val current: Int
        get() = count
    
    val stepsTaken: Int
        get() = count - origin
    
    init {
        require(initialValue >= 0) { "initialValue must be non-negative, got $initialValue" }
        instanceCount += 1
    }
    
    fun increment(): Int {
        count += 1
        return count
    }
    
    fun reset() {
        count = origin
    }
    
    fun describe(): String = "Counter at $count (origin $origin, $stepsTaken steps taken)"
    
    companion object {
        private var instanceCount: Int = 0
        
        fun totalCreated(): Int = instanceCount
        
        fun zero(): Counter = Counter(0)
    }
}

fun main() {
    val a = Counter(5)
    val b = Counter()
    val c = Counter.zero()
    
    a.increment()
    a.increment()
    
    b.increment()
    b.increment()
    b.increment()
    
    c.increment()
    
    println(a.describe())
    println(b.describe())
    println(c.describe())
    
    println("\nTotal instances created: ${Counter.totalCreated()}")
    
    a.reset()
    println("After reset, a: ${a.describe()}")
    
    println("\nDirect property reads:")
    println("a.current: ${a.current}")
    println("b.current: ${b.current}")
    println("c.stepsTaken: ${c.stepsTaken}")
}
```

Save and run.

### Step 2: Read the Output

The output is:

```text
Counter at 7 (origin 5, 2 steps taken)
Counter at 3 (origin 0, 3 steps taken)
Counter at 1 (origin 0, 1 steps taken)

Total instances created: 3
After reset, a: Counter at 5 (origin 5, 0 steps taken)

Direct property reads:
a.current: 5
b.current: 3
c.stepsTaken: 1
```

Walk through what each piece contributed. The class has a primary constructor with a default argument (`initialValue: Int = 0`), allowing both `Counter(5)` and `Counter()`. The `init` block validates that the value is non-negative and increments the companion's instance count. The `count` and `origin` are private properties; `count` is mutable, `origin` is read-only after construction. The computed properties `current` and `stepsTaken` give read-only views derived from the state.

The methods `increment`, `reset`, and `describe` are public. `increment` returns the new count for convenience (you could call `c.increment()` and use the return value directly without a separate read). The companion object has its own private `instanceCount` and exposes `totalCreated()` as a class-level function plus `zero()` as a factory.

Each instance has its own `count` and `origin`. Modifying one instance does not affect others (the `instanceCount` in the companion is shared, but per-instance state is private to each).

### Step 3: Modify and Re-Run

Try a few experiments. Add a fourth counter and observe `Counter.totalCreated()`. Change the default argument from 0 to 10 and watch `Counter()` start at 10. Add a `companion object` method `withDescription(name: String): Counter` that takes a description and returns a new counter, illustrating how factory methods can do more than just delegate to the primary constructor.

The point of these variations is to feel comfortable with the class machinery. Each piece (constructor, init, properties, methods, companion) is a tool you reach for when the situation calls for it, and reaching for the right tool becomes natural with practice.

---

## 9. Fix the Errors in Your Code

Three class-related mistakes are common.

**Error 1: Forgetting to mark the constructor parameter as a property**

```kotlin
// Wrong
class Counter(initialValue: Int)

fun main() {
    val c = Counter(10)
    println(c.initialValue)
}

// Correct
class Counter(val initialValue: Int)

fun main() {
    val c = Counter(10)
    println(c.initialValue)
}
```

The wrong version stops with `Unresolved reference 'initialValue'.` A constructor parameter without `val` or `var` is just a parameter, not a property. It is in scope during property initializers and `init` blocks but is not stored on the instance and is not accessible from outside. The fix is to add `val` (or `var`) before the parameter name to turn it into a property. As a habit, when you write a primary constructor, decide for each parameter whether it should also be a property. If callers need to read the value later, it should be a property; if it is just for construction-time use, leave it as a plain parameter.

**Error 2: Accessing a private member from outside the class**

```kotlin
// Wrong
class Counter(val value: Int) {
    private var count: Int = value
    fun increment() { count += 1 }
}

fun main() {
    val c = Counter(0)
    c.count += 1
}

// Correct
class Counter(val value: Int) {
    private var count: Int = value
    val current: Int
        get() = count
    fun increment() { count += 1 }
}

fun main() {
    val c = Counter(0)
    c.increment()
    println(c.current)
}
```

The wrong version stops with `Cannot access 'var count: Int': it is private in '/Counter'.` Private members are not accessible from outside the class, and the compiler refuses any external attempt to read or write them. The fix is to use the public API the class already offers (here, `c.increment()`) and, when callers need to read the state, to expose it through a read-only property such as `current`. As a habit, design the public API of a class deliberately: think about what callers should be able to do, not what they should be able to access.

**Error 3: Putting per-instance state in the companion object**

```kotlin
// Wrong
class Logger {
    companion object {
        var lastMessage: String = ""
    }

    fun log(msg: String) {
        lastMessage = msg
    }
}

fun main() {
    val l1 = Logger()
    val l2 = Logger()
    l1.log("from l1")
    l2.log("from l2")
    println(Logger.lastMessage)
}

// Correct
class Logger {
    var lastMessage: String = ""

    fun log(msg: String) {
        lastMessage = msg
    }
}

fun main() {
    val l1 = Logger()
    val l2 = Logger()
    l1.log("from l1")
    l2.log("from l2")
    println(l1.lastMessage)
    println(l2.lastMessage)
}
```

This one compiles, which makes it sneaky. The wrong version prints only `from l2`, because there is a single `lastMessage` shared by every `Logger`, and the second call overwrote the first. The correct version prints `from l1` and then `from l2`, because each logger now keeps its own message. Members of a `companion object` are shared across all instances of the class, not stored per instance. As a habit, ask yourself "is this state shared across all instances or specific to each one?" Per-instance state goes in the class body; shared state goes in the companion object. Most state is per-instance.

---

## 10. Exercises

These exercises practice declaring and using classes.

**Exercise 1:** Write a class `BankAccount` with a constructor that takes an `initialBalance: Double` and stores it as a private property. Add methods `deposit(amount: Double)` and `withdraw(amount: Double)` that modify the balance. Add a computed property `balance: Double` that exposes the current balance read-only. Test the class from `main` by depositing and withdrawing, then printing the balance.

**Exercise 2:** Add a `companion object` to `BankAccount` that tracks the total number of accounts created. Expose the count via a `totalAccounts()` function on the companion. Test by creating several accounts and printing the total.

**Exercise 3:** Add input validation: `withdraw` should throw `IllegalArgumentException` if the amount is negative or greater than the balance. The constructor should throw if `initialBalance` is negative. Use the `require` function for both checks.

---

## 11. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

The first version of `BankAccount` only needs a private balance, two methods that change it, and a read-only property that exposes it.

```kotlin
class BankAccount(initialBalance: Double) {
    private var _balance: Double = initialBalance

    val balance: Double
        get() = _balance

    fun deposit(amount: Double) {
        _balance += amount
    }

    fun withdraw(amount: Double) {
        _balance -= amount
    }
}

fun main() {
    val account = BankAccount(100.0)
    account.deposit(50.0)
    account.withdraw(30.0)
    println("Balance: ${account.balance}")
}
```

Save and run. Output:

```text
Balance: 120.0
```

The constructor parameter `initialBalance` is a plain parameter (no `val`), used only to initialize the private property `_balance`. The methods `deposit` and `withdraw` change `_balance` from inside the class, and the computed property `balance` lets callers read the value without being able to assign to it. Writing `account.balance = 1000.0` in `main` would not compile, because `balance` is a `val` with only a getter.

**Solution for Exercise 2:**

The account counter belongs to the class as a whole, so it goes in a `companion object`, and the `init` block bumps it every time an account is created.

```kotlin
class BankAccount(initialBalance: Double) {
    private var _balance: Double = initialBalance

    val balance: Double
        get() = _balance

    init {
        accountCount += 1
    }

    fun deposit(amount: Double) {
        _balance += amount
    }

    fun withdraw(amount: Double) {
        _balance -= amount
    }

    companion object {
        private var accountCount: Int = 0
        fun totalAccounts(): Int = accountCount
    }
}

fun main() {
    val savings = BankAccount(500.0)
    val checking = BankAccount(80.0)
    val holiday = BankAccount(0.0)

    savings.deposit(100.0)
    checking.withdraw(30.0)

    println("Savings: ${savings.balance}")
    println("Checking: ${checking.balance}")
    println("Holiday: ${holiday.balance}")
    println("Total accounts: ${BankAccount.totalAccounts()}")
}
```

Save and run. Output:

```text
Savings: 600.0
Checking: 50.0
Holiday: 0.0
Total accounts: 3
```

Each account keeps its own `_balance`, so depositing into `savings` does not touch `checking`. The `accountCount` variable, in contrast, exists only once because it lives in the companion object. It is `private`, so code outside the class cannot change it by accident; callers read it through `BankAccount.totalAccounts()`.

**Solution for Exercise 3:**

This exercise practices using `require` for validation, both in the constructor and in methods.

```kotlin
class BankAccount(initialBalance: Double) {
    private var _balance: Double = initialBalance
    
    val balance: Double
        get() = _balance
    
    init {
        require(initialBalance >= 0.0) { "initialBalance cannot be negative, got $initialBalance" }
        accountCount += 1
    }
    
    fun deposit(amount: Double) {
        require(amount > 0.0) { "deposit amount must be positive, got $amount" }
        _balance += amount
    }
    
    fun withdraw(amount: Double) {
        require(amount > 0.0) { "withdraw amount must be positive, got $amount" }
        require(amount <= _balance) { "insufficient funds: tried to withdraw $amount, balance is $_balance" }
        _balance -= amount
    }
    
    companion object {
        private var accountCount: Int = 0
        fun totalAccounts(): Int = accountCount
    }
}

fun main() {
    val a = BankAccount(100.0)
    a.deposit(50.0)
    a.withdraw(30.0)
    println("Balance: ${a.balance}")
    
    println("Total accounts: ${BankAccount.totalAccounts()}")
    
    // The next line would throw:
    // a.withdraw(1000.0)
}
```

Save and run. Output:

```text
Balance: 120.0
Total accounts: 1
```

The class uses an underscore-prefixed private property (`_balance`) and a public computed property (`balance`) for the same conceptual state. This is a common idiom: when you want to expose a property as read-only externally but mutate it internally, you have two names. The underscore prefix is a Kotlin convention for the private backing field. Inside the class, all writes go through `_balance`; outside, all reads go through `balance`.

The `require` calls throw `IllegalArgumentException` if their conditions are false, which is the right exception type for "the caller passed bad input". For internal invariants violated by the class itself (rather than by the caller), `check` is the corresponding helper that throws `IllegalStateException`. We use `require` here because all three validations are about external inputs.

If you uncomment the `a.withdraw(1000.0)` line, the program crashes with the message "insufficient funds: tried to withdraw 1000.0, balance is 120.0". The error is precise and actionable, which is much better than letting the withdraw silently produce a negative balance or letting the program continue in a broken state.

This validation pattern is one of the simplest forms of "design by contract" programming: each method declares preconditions, the runtime checks them, and the rest of the method can assume they hold. As code grows, this discipline pays off because each method's body becomes simpler when it does not have to handle invalid inputs gracefully.

---

## 12. Understanding Why Properties Replace Getters

Kotlin's choice to make properties first-class language constructs (rather than just fields with associated getter and setter methods like Java) is one of the small ergonomic wins that adds up across a real codebase. Understanding why it matters helps you appreciate the difference.

In Java, a field is private by convention, and code accesses it through a getter and (optionally) a setter. The pattern is so common that IDEs auto-generate the methods, but they still bloat the source code: every property takes 5 to 10 lines of boilerplate (the field, the getter, the setter, plus the documentation). Java tooling has long since accepted this as a fact of life, but it is genuinely a design wart: 90% of accessors are simple read-and-return-the-field operations that contribute nothing except syntactic ceremony.

Kotlin's properties unify the field and the accessors into one concept. When you write `val name: String`, you are declaring a property that is conceptually a read-only attribute of the object. The compiler generates a private field and a public getter under the hood (matching Java's pattern at the bytecode level), but at the source level you just have one declaration. If you need the getter to do something more interesting than "return the field", you can write a custom `get()` block, but you do not have to.

The same applies to mutable properties with `var`. The default behavior is field plus getter plus setter, all generated automatically. If you need custom behavior in the setter (logging, validation, change notifications), you can write a custom `set()` block. Most of the time you do not, and the property is just the equivalent of a field with a getter and a setter, written in one line.

The benefit at the source level is significant. A class with five mutable fields takes about 75 lines in Java (counting the fields and their accessors) but maybe 6 lines in Kotlin. Multiplied across a real codebase, that is thousands of lines of boilerplate that you no longer have to write, read, or maintain. The class's structure becomes visible at a glance: when you read the class header, you see exactly what data the class holds, without scrolling past method bodies that do nothing interesting.

A subtler benefit is that properties play well with the rest of the language. You can use them in expressions naturally (`person.name`), assign to them when they are mutable (`person.age = 30`), and reference them where a function would otherwise be needed. Computed properties (`get() = ...`) let you treat derived values as if they were fields, which is often more natural than method calls for things that are conceptually attributes. The result is code where the boundary between data and computation is fluid: you can refactor a stored property into a computed one (or vice versa) without changing any caller's code, because the access syntax is the same either way.

The cost is a small mental adjustment for programmers coming from Java. The same code looks different on the page: `String name` and `public String getName()` versus `val name: String`. The Kotlin form is shorter but takes a moment to recognize the first time. After a few days of writing Kotlin classes you stop noticing the difference, and the conciseness becomes the new normal.

A common worry is interop: how does Kotlin's property model interact with Java code that expects getters and setters? The answer is that the compiler generates exactly the getter and setter Java would expect. A Kotlin `val name: String` produces a `getName()` method visible from Java, and a `var age: Int` produces both `getAge()` and `setAge(int)`. Java code calling Kotlin sees the familiar getter-setter pattern; Kotlin code calling Java can also use property syntax for Java getters, with the compiler doing the mapping. The interop is effectively transparent in both directions.

---

## Next Up - Lesson 10

Kotlin classes bundle data and behavior into named types. The primary constructor declares parameters in the class header, and parameters marked with `val` or `var` become properties of the class. Properties combine field, getter, and (optionally) setter into a single declaration. Member functions are declared inside the class body and operate on instances. Visibility modifiers control access, with `public` (the default) and `private` covering most needs. The `init` block runs during construction for setup that does not fit into property initializers, and `require`/`check` are the standard helpers for validation. The `companion object` provides static-like members associated with the class as a whole, useful for instance counters, factory methods, and class-level constants. Together these features let you define rich types with much less code than the equivalent Java would take, while keeping the same level of static safety.

In Lesson 10 you will meet data classes, which take Kotlin's class syntax and add automatic generation of `equals`, `hashCode`, `toString`, `copy`, and destructuring. Data classes are how Catatku will represent each entry, and they are one of Kotlin's most beloved features.
