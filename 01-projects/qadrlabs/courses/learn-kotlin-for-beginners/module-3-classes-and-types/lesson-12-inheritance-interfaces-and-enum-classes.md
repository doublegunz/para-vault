## 1. Before You Begin

Lesson 11 introduced sealed classes for modeling closed type hierarchies, where every value is exactly one of a fixed set of variants. Sealed classes are a specialization of a more general feature: inheritance. In Kotlin, classes can extend other classes, picking up their fields and methods, and they can implement interfaces, which are contracts that define what a class must provide. Together, inheritance and interfaces let you model a wider range of relationships between types: "every Cat is an Animal", "every Catatku entry can be displayed as a string", "every payable item has a price". Where sealed classes describe "this type is one of these specific shapes", regular inheritance describes "this type is a kind of that other type, with possibly its own additions".

Kotlin makes one significant change from Java's inheritance model: classes are final by default. You cannot extend a Kotlin class unless you mark it with the `open` keyword. This is a deliberate design choice that nudges you toward composition over inheritance: instead of building deep class hierarchies, you build small focused classes that work together via interfaces. The same nudge applies to methods (final by default unless marked `open`) and to method overriding (must use `override`, never silently override). Combined with `data class` (Lesson 10), `sealed class` (Lesson 11), and the topics of this lesson, Kotlin gives you a rich vocabulary for type design while encouraging you toward the simpler shapes that are easier to reason about.

This lesson covers `open` and `final` (which mark whether classes and methods can be extended), `override` (which marks intentional method overrides), `abstract class` (for partial implementations), `interface` (for contracts), and `enum class` (for the closed-set-without-variant-data case). By the end you will have written the `Priority` enum that Catatku will use, plus a small interface example that previews how interfaces compose with the rest of Kotlin. Along the way you will see interfaces with default method implementations, a class implementing several interfaces at once, and how to decide between an enum class and a sealed class.

### What You'll Build

A `Priority` enum class with three values (`HIGH`, `MEDIUM`, `LOW`), a small custom property and method on each value to demonstrate enum-with-behavior, an `Animal` open class with two subclasses (`Dog` and `Cat`) to demonstrate inheritance, and a `Greetable` interface implemented by multiple types. By the end the type system pieces are in place for the rest of Catatku to use: the data class for the entry shape, the sealed class for the status, and the enum class for the priority.

### What You'll Learn

- ✅ How `open`, `final`, `abstract`, and `override` control inheritance
- ✅ How to declare interfaces with required and default methods
- ✅ How a class implements one or more interfaces
- ✅ How `enum class` defines a closed set of named constants
- ✅ When to use enum versus sealed class versus interface

### What You'll Need

- The `catatku` Gradle project from previous lessons
- A solid understanding of classes, data classes, and sealed classes from Lessons 9, 10, and 11
- About forty minutes
- Patience for the more abstract type system topics

---

## 2. Inheritance with open and override

In Java, classes are open to extension by default; you write `final` to prevent subclassing. In Kotlin the default is reversed: classes are `final` (cannot be extended) unless you mark them `open`. This change pushes you toward composition (using objects together) instead of inheritance (extending other classes), which generally produces cleaner code.

### Step 1: Try to Extend a Closed Class

Open `Main.kt` and replace its contents with:

```kotlin
class Animal(val name: String) {
    fun describe(): String = "Animal named $name"
}

// The next line is a compile error:
// class Dog(name: String) : Animal(name)

fun main() {
    val a = Animal("Generic")
    println(a.describe())
}
```

Save and run. Output:

```text
Animal named Generic
```

If you uncomment the `Dog` declaration, the compiler complains:

```text
This type is final, so it cannot be extended.
```

The `Animal` class cannot be extended because it is final by default. To allow extension, we add the `open` keyword to the class declaration.

### Step 2: Open the Class for Extension

```kotlin
open class Animal(val name: String) {
    fun describe(): String = "Animal named $name"
}

class Dog(name: String) : Animal(name) {
    fun bark() = println("$name says: Woof!")
}

fun main() {
    val rex = Dog("Rex")
    println(rex.describe())  // inherited from Animal
    rex.bark()                // defined in Dog
}
```

Save and run. Output:

```text
Animal named Rex
Rex says: Woof!
```

The `open class Animal(val name: String)` declaration says "this class can be extended". The subclass declaration `class Dog(name: String) : Animal(name)` reads "Dog extends Animal, passing the constructor parameter `name` to Animal's constructor". The `: Animal(name)` part is both the inheritance declaration and the call to the parent constructor.

Notice that `name` in `Dog`'s constructor is just a plain parameter (no `val`). It does not need to be a property because `Animal` already declares `val name`, and `Dog` inherits that property. If you wrote `val name` on `Dog`'s parameter, the compiler would complain because the same property would be declared twice.

The `Dog` class inherits the `describe()` method from `Animal` and adds its own `bark()` method. From outside, you can call both methods on a `Dog` instance because a `Dog` is also an `Animal` (every `Dog` instance is-a Animal).

### Step 3: Override a Method

Methods are also final by default. To allow a subclass to override a method, mark it `open`. To override, the subclass uses the `override` keyword:

```kotlin
open class Animal(val name: String) {
    open fun describe(): String = "Animal named $name"
    open fun sound(): String = "(generic animal sound)"
}

class Dog(name: String) : Animal(name) {
    override fun describe(): String = "Dog named $name"
    override fun sound(): String = "Woof!"
}

class Cat(name: String) : Animal(name) {
    override fun sound(): String = "Meow!"
}

fun main() {
    val animals: List<Animal> = listOf(Dog("Rex"), Cat("Whiskers"), Animal("Generic"))
    
    for (a in animals) {
        println("${a.describe()} says ${a.sound()}")
    }
}
```

Save and run. Output:

```text
Dog named Rex says Woof!
Animal named Whiskers says Meow!
Animal named Generic says (generic animal sound)
```

Both methods are marked `open` in `Animal`. `Dog` overrides both `describe` and `sound`. `Cat` only overrides `sound`, so it inherits the default `describe` from `Animal` (which prints "Animal named ..."). The `override` keyword is mandatory; without it, the compiler complains. Forgetting `override` is a common bug source in Java where adding a method to a parent class can silently shadow an unrelated method in a subclass; Kotlin's `override` requirement prevents this entirely.

The line `val animals: List<Animal> = listOf(Dog("Rex"), Cat("Whiskers"), Animal("Generic"))` shows polymorphism in action. The list type is `List<Animal>`, but it holds instances of subtypes. When we call `a.describe()` and `a.sound()` in the loop, the runtime picks the actual class's implementation. Each instance produces output appropriate to its actual type.

### Why open Is Off by Default

The default `final` choice is one of Kotlin's small but meaningful differences from Java. The reasoning is "Effective Java Item 19": most classes are not designed for inheritance, and allowing arbitrary extension can break the class's invariants. By making classes final by default, Kotlin forces you to think about whether a class should be extendable, and to mark it `open` deliberately when it should.

In practice, most application code has very few `open` classes. Data classes and sealed class hierarchies handle the cases where you want shared structure without arbitrary extension. Regular classes are almost always final. `open` shows up mostly in libraries that expose extension points, in framework integration code, and in mocking-friendly code for tests (some testing libraries need to subclass, which requires `open`).

For Catatku, we will not use `open` classes at all. Every Catatku class is final, with `data class` and `sealed class` providing the structure where it is needed. This is typical of clean modern Kotlin code and is a good default to follow in your own projects.

---

## 3. Abstract Classes

An abstract class is one that has some methods or properties without implementations, leaving them for subclasses to fill in. You declare it with `abstract class`, and the unimplemented members are marked `abstract`. An abstract class cannot be instantiated directly; you can only create instances of concrete subclasses.

### Step 1: A Simple Abstract Class

```kotlin
abstract class Shape(val name: String) {
    abstract fun area(): Double
    
    fun describe(): String = "Shape '$name' with area ${"%.2f".format(area())}"
}

class Circle(radius: Double) : Shape("Circle") {
    private val r = radius
    override fun area(): Double = Math.PI * r * r
}

class Square(side: Double) : Shape("Square") {
    private val s = side
    override fun area(): Double = s * s
}

fun main() {
    val shapes: List<Shape> = listOf(Circle(5.0), Square(4.0))
    for (s in shapes) {
        println(s.describe())
    }
    
    // The next line is a compile error:
    // val abstract = Shape("Generic")  // cannot instantiate abstract class
}
```

Save and run. Output:

```text
Shape 'Circle' with area 78.54
Shape 'Square' with area 16.00
```

The `abstract class Shape` declaration introduces an abstract class. The `abstract fun area(): Double` declares a method without an implementation; subclasses must provide one. The non-abstract method `describe()` provides shared behavior that uses `area()` polymorphically: `describe` calls `area`, and the runtime picks the right implementation based on the actual class.

The `Circle` and `Square` classes are concrete: they provide implementations for all abstract members. They can be instantiated. The abstract `Shape` cannot be instantiated, so `Shape("Generic")` is a compile error: if you uncomment that line, the compiler reports `Cannot create an instance of an abstract class.` This makes sense; an abstract class is a partial implementation that does not know how to compute its own `area`, so it cannot be a complete object.

Abstract classes are useful when you have shared behavior across a set of related types and want to enforce that subclasses implement specific operations. The shared behavior lives in the abstract class; the variant-specific behavior lives in the concrete subclasses. This is the same pattern as sealed classes (Lesson 11), but more open: you do not have to enumerate the subclasses upfront, and any code can extend the abstract class.

### Abstract vs Sealed Class

Both abstract classes and sealed classes have abstract methods. The difference is that a sealed class restricts who can extend it (only subclasses in the same package and module, which in this course always means the same file), while an abstract class lets anyone extend it. Sealed classes get exhaustive `when` checking; abstract classes do not.

The choice depends on your intent. Use sealed when you want to enumerate every possible variant at design time and have the compiler enforce exhaustive matching. Use abstract when you want to allow open-ended extension, perhaps because the variants will grow over time or because external code should be able to add its own.

For Catatku's domain types, sealed is almost always the right choice. The `Status` is a closed set of states (pending, in progress, done, cancelled) that the application defines; outside code should not invent new statuses. An abstract class would be the wrong choice because it would invite subclassing that breaks our exhaustive `when` blocks.

### Step 2: Abstract Properties

Properties can also be abstract:

```kotlin
abstract class Vehicle {
    abstract val wheels: Int
    
    fun describe(): String = "A $wheels-wheeled vehicle"
}

class Car : Vehicle() {
    override val wheels: Int = 4
}

class Motorcycle : Vehicle() {
    override val wheels: Int = 2
}

fun main() {
    println(Car().describe())
    println(Motorcycle().describe())
}
```

Save and run. Output:

```text
A 4-wheeled vehicle
A 2-wheeled vehicle
```

The `abstract val wheels: Int` declares a property that subclasses must provide. Each concrete class supplies a value. The `describe` method uses the abstract property the same way it would use a regular property; polymorphism handles the dispatch at runtime.

Abstract properties are useful when you want subclasses to determine specific values while sharing the structure and behavior defined in the parent class. This is rarer in modern Kotlin (you would more often use a regular property in the constructor) but is a tool in the toolbox when needed.

---

## 4. Interfaces

An interface is a contract: a list of methods (and properties) that any class implementing the interface must provide. Interfaces are similar to abstract classes but with two key differences. First, a class can implement multiple interfaces (whereas it can only extend one class). Second, interfaces cannot have constructors or backing fields for properties.

### Step 1: Define and Implement an Interface

Replace the body of the file with:

```kotlin
interface Greetable {
    fun greet(): String
}

class Robot(val id: Int) : Greetable {
    override fun greet(): String = "BEEP BOOP UNIT $id"
}

class Cat(val name: String) : Greetable {
    override fun greet(): String = "$name says: meow"
}

fun main() {
    val greeters: List<Greetable> = listOf(Robot(7), Cat("Whiskers"))
    for (g in greeters) {
        println(g.greet())
    }
}
```

Save and run. Output:

```text
BEEP BOOP UNIT 7
Whiskers says: meow
```

The `interface Greetable { fun greet(): String }` declaration creates an interface with one required method. The `class Robot : Greetable` declaration says "Robot implements Greetable". The `class Cat : Greetable` does the same. Both classes provide an `override fun greet()` method that satisfies the contract.

The list type `List<Greetable>` shows polymorphism through interfaces: any type implementing `Greetable` can go in the list, and any code working through the interface can call `greet()` without knowing the actual class. This is the same idea as a Java interface, with the same uses (defining contracts, enabling polymorphism, allowing testability through mock implementations).

Notice that the `: Greetable` syntax for implementing an interface looks the same as the `: Animal` syntax for extending a class, and Kotlin disambiguates by which kind the right-hand side is. There are also no parentheses after `Greetable` because interfaces have no constructors to invoke.

### Step 2: Default Method Implementations

Unlike Java's traditional interfaces, Kotlin interfaces can provide default implementations for methods. This is similar to Java 8+ default methods.

```kotlin
interface Describable {
    fun name(): String
    
    // Default implementation: subclasses inherit this unless they override
    fun describe(): String = "Item named '${name()}'"
}

class Book(private val title: String) : Describable {
    override fun name(): String = title
}

class Special(private val customName: String) : Describable {
    override fun name(): String = customName
    override fun describe(): String = "*** Special item: ${customName.uppercase()} ***"
}

fun main() {
    val items = listOf(Book("Kotlin in Action"), Special("Limited Edition"))
    for (item in items) {
        println(item.describe())
    }
}
```

Save and run. Output:

```text
Item named 'Kotlin in Action'
*** Special item: LIMITED EDITION ***
```

The `Describable` interface has two methods: `name()` is required (no default), and `describe()` has a default implementation. `Book` provides only `name`; the default `describe` is used. `Special` overrides both, providing a custom `describe` that produces a different format.

Default implementations are useful when most implementers would write the same code, but a few want to customize. They reduce boilerplate and let interfaces evolve over time (you can add a new method with a default implementation without breaking existing implementers).

### Step 3: Multiple Interface Implementation

A class can implement multiple interfaces, which is one of the main reasons interfaces exist:

```kotlin
interface Greetable {
    fun greet(): String
}

interface Describable {
    fun describe(): String
}

class Person(val name: String, val age: Int) : Greetable, Describable {
    override fun greet(): String = "Hello, I am $name"
    override fun describe(): String = "Person named $name, $age years old"
}

fun main() {
    val p = Person("Reader", 25)
    println(p.greet())
    println(p.describe())
    
    val asGreetable: Greetable = p
    val asDescribable: Describable = p
    println("(via Greetable) ${asGreetable.greet()}")
    println("(via Describable) ${asDescribable.describe()}")
}
```

Save and run. Output:

```text
Hello, I am Reader
Person named Reader, 25 years old
(via Greetable) Hello, I am Reader
(via Describable) Person named Reader, 25 years old
```

The class `Person : Greetable, Describable` implements two interfaces, separated by commas. It must provide implementations for the methods of both. The same instance can be viewed through either interface, depending on what kind of access the calling code wants. Polymorphism works through both interfaces independently.

This is a major reason interfaces are useful and why you cannot do the same thing with class inheritance alone (Kotlin classes inherit from at most one parent class, like Java but unlike C++). When a class genuinely fits multiple roles (Greetable, Describable, Comparable, Iterable), interfaces let you express that without forcing a complex inheritance hierarchy.

---

## 5. Enum Classes

An enum class is a fixed set of named constants. We saw the basic form briefly in Lesson 11 when comparing to sealed classes; here we cover enum classes properly. Enums are simpler than sealed classes when every variant has the same shape, and they get the same exhaustive-`when` benefits.

### Step 1: A Basic Enum

```kotlin
enum class Priority {
    HIGH, MEDIUM, LOW
}

fun main() {
    val p = Priority.HIGH
    println(p)
    
    println("All priorities:")
    for (priority in Priority.values()) {
        println("  $priority")
    }
}
```

Save and run. Output:

```text
HIGH
All priorities:
  HIGH
  MEDIUM
  LOW
```

The `enum class Priority { HIGH, MEDIUM, LOW }` declaration creates an enum with three values. Each value is accessible via the type name: `Priority.HIGH`, `Priority.MEDIUM`, `Priority.LOW`. The `Priority.values()` function returns all values as an array, in declaration order. Since Kotlin 1.9 you can also write `Priority.entries`, which returns the same values as a read-only list; both work, and you will see `values()` throughout this course because it is still very common in existing code.

The default `toString` for enums is the constant name, which is much friendlier than the `Class@hash` default for objects. This is one of the small ergonomic wins of using enums.

### Step 2: Enums with Constructor Parameters

Enum values can carry shared data via the enum's constructor:

```kotlin
enum class Priority(val displayName: String, val sortOrder: Int) {
    HIGH("High", 0),
    MEDIUM("Medium", 1),
    LOW("Low", 2);
    
    fun shortLabel(): String = displayName.first().uppercase()
}

fun main() {
    for (p in Priority.values()) {
        println("$p (${p.displayName}, ${p.shortLabel()}, sort order ${p.sortOrder})")
    }
    
    val sorted = Priority.values().sortedBy { it.sortOrder }
    println("\nSorted: ${sorted.toList()}")
}
```

Save and run. Output:

```text
HIGH (High, H, sort order 0)
MEDIUM (Medium, M, sort order 1)
LOW (Low, L, sort order 2)

Sorted: [HIGH, MEDIUM, LOW]
```

The enum's primary constructor takes two parameters: `displayName` and `sortOrder`. Each value provides arguments at declaration: `HIGH("High", 0)`. The fields are `val` properties accessible on each value: `Priority.HIGH.displayName` is "High". Methods like `shortLabel()` are members of the enum class and apply to every value.

Notice the semicolon after the value list (`LOW("Low", 2);`). It is required when the enum has any members beyond the values themselves; without it, the compiler does not know where the value list ends and the member declarations begin.

This enum-with-data pattern is useful when each variant has the same shape but different specific values. For Catatku, the priority needs a display name and a sort order, both of which differ per variant but follow the same structure. An enum is the right choice over a sealed class because there is no variant-specific shape; only specific values.

### Step 3: Use Enums in when

Enums get the same exhaustive-`when` benefit as sealed classes:

```kotlin
enum class Priority {
    HIGH, MEDIUM, LOW
}

fun urgencyHours(p: Priority): Int = when (p) {
    Priority.HIGH -> 1
    Priority.MEDIUM -> 24
    Priority.LOW -> 168
}

fun main() {
    for (p in Priority.values()) {
        println("$p: should be done within ${urgencyHours(p)} hours")
    }
}
```

Save and run. Output:

```text
HIGH: should be done within 1 hours
MEDIUM: should be done within 24 hours
LOW: should be done within 168 hours
```

The `when` over an enum requires every value to be matched (or an `else` branch). Adding a new enum value would force every `when` over the type to be updated, exactly like with sealed classes. The branches use the value name directly (`Priority.HIGH -> ...`) without the `is` keyword, because enum values are values, not types.

Enums and sealed classes are both useful, with overlapping use cases. The choice is mostly mechanical:

If every variant has the same shape (no variant-specific fields), use an enum. The syntax is shorter, and `values()` and `valueOf()` give you useful operations for free.

If variants need different shapes (some carry data, some do not, or different variants carry different data), use a sealed class. Enums cannot represent this cleanly.

For Catatku, `Priority` is an enum (three named values, no variant-specific data) and `Status` is a sealed class (four variants, one of which carries a reason). The split is exactly right for the domain.

---

## 6. The Final Catatku Type Layout

Now we have all three type-modeling tools (data class, sealed class, enum class), let us put them together for Catatku.

### Step 1: All Three Types in One File

Replace `Main.kt` with this:

```kotlin
enum class Priority(val displayName: String) {
    HIGH("High"),
    MEDIUM("Medium"),
    LOW("Low");
    
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

fun marker(status: Status): String = when (status) {
    is Status.Pending -> "[ ]"
    is Status.InProgress -> "[~]"
    is Status.Done -> "[x]"
    is Status.Cancelled -> "[!]"
}

fun formatEntry(e: Entry): String =
    "${marker(e.status)} (${e.priority.shortLabel()}) ${e.id}. ${e.description}"

fun main() {
    val entries = listOf(
        Entry(1, "Pay rent", priority = Priority.HIGH),
        Entry(2, "Finish Kotlin course", priority = Priority.MEDIUM, status = Status.InProgress),
        Entry(3, "Read for fun", priority = Priority.LOW),
        Entry(4, "Call dentist", priority = Priority.MEDIUM, status = Status.Cancelled("rescheduled")),
        Entry(5, "Walk the dog")
    )
    
    println("Catatku entries:")
    for (e in entries) {
        println("  ${formatEntry(e)}")
    }
    
    val highPriority = entries.filter { it.priority == Priority.HIGH }
    println("\nHigh-priority entries:")
    for (e in highPriority) {
        println("  ${formatEntry(e)}")
    }
}
```

Save and run. Output:

```text
Catatku entries:
  [ ] (H) 1. Pay rent
  [~] (M) 2. Finish Kotlin course
  [ ] (L) 3. Read for fun
  [!] (M) 4. Call dentist
  [ ] (M) 5. Walk the dog

High-priority entries:
  [ ] (H) 1. Pay rent
```

This is the complete domain model for Catatku. Each type uses the right tool for its shape: enum for priority (closed set, all variants equivalent), sealed class for status (closed set with one variant carrying data), data class for entry (record of fields, immutable, compares structurally). The display logic uses both kinds of pattern matching: `when` on the sealed class via `is`, and direct comparison on the enum via `==`.

### Why This Combination Works

Each tool earns its place. Without enums, priorities would be a sealed class with three trivial object variants, which is more boilerplate than the situation deserves. Without sealed classes, statuses would be an enum, but then `Cancelled` could not carry its reason (or would have to carry it via an awkward optional field shared by all values). Without data classes, every entry would need 100 lines of boilerplate for `equals`, `hashCode`, `toString`, and copy methods. The combination produces the cleanest possible model.

This is the typical shape of well-designed Kotlin code: a small number of types, each using the right kind of declaration, working together. Once the types are in place, the rest of the application is just functions that operate on these types, with the compiler checking that every operation is valid.

---

## 7. Run and Test

Build a final example that exercises every concept from this lesson.

### Step 1: A Mixed-Concepts Example

Replace `Main.kt` with:

```kotlin
interface Describable {
    fun describe(): String
}

abstract class Shape(val name: String) : Describable {
    abstract fun area(): Double
    
    override fun describe(): String = "$name with area ${"%.2f".format(area())}"
}

class Circle(private val radius: Double) : Shape("Circle") {
    override fun area(): Double = Math.PI * radius * radius
}

class Square(private val side: Double) : Shape("Square") {
    override fun area(): Double = side * side
}

enum class Priority(val displayName: String) {
    HIGH("High"), MEDIUM("Medium"), LOW("Low");
    
    fun shortLabel(): String = displayName.first().toString()
}

interface Sortable {
    fun sortKey(): Int
}

class PriorityWrapper(val priority: Priority) : Describable, Sortable {
    override fun describe(): String = "Priority: ${priority.displayName}"
    override fun sortKey(): Int = when (priority) {
        Priority.HIGH -> 0
        Priority.MEDIUM -> 1
        Priority.LOW -> 2
    }
}

fun main() {
    println("=== Inheritance and Abstract ===")
    val shapes: List<Shape> = listOf(Circle(5.0), Square(4.0))
    for (s in shapes) {
        println(s.describe())
    }
    
    println("\n=== Enums ===")
    for (p in Priority.values()) {
        println("$p (${p.shortLabel()}): ${p.displayName}")
    }
    
    println("\n=== Multiple Interface Implementation ===")
    val wrappers = listOf(
        PriorityWrapper(Priority.LOW),
        PriorityWrapper(Priority.HIGH),
        PriorityWrapper(Priority.MEDIUM)
    )
    val sorted = wrappers.sortedBy { it.sortKey() }
    for (w in sorted) {
        println(w.describe())
    }
}
```

Save and run.

### Step 2: Read the Output

The output is:

```text
=== Inheritance and Abstract ===
Circle with area 78.54
Square with area 16.00

=== Enums ===
HIGH (H): High
MEDIUM (M): Medium
LOW (L): Low

=== Multiple Interface Implementation ===
Priority: High
Priority: Medium
Priority: Low
```

Walk through what each piece contributed. The `Describable` interface defines a single method. The abstract `Shape` class implements `Describable` (so subclasses get it for free) and adds an abstract `area()` method that subclasses must define. `Circle` and `Square` are concrete subclasses with their own `area` formulas. Polymorphism through the abstract class lets us iterate a `List<Shape>` and call `describe()` (which calls `area()` polymorphically through the override).

The `Priority` enum has three values, each carrying a display name. The `shortLabel` member uses the `displayName` to produce a one-character abbreviation. Iterating with `Priority.values()` walks through every constant in declaration order.

The `PriorityWrapper` class implements two interfaces (`Describable` and `Sortable`). The `sortKey` method uses an exhaustive `when` over the enum to map each priority to an integer, which `sortedBy` then uses to order the list. The result is the wrappers sorted by priority (HIGH first, then MEDIUM, then LOW).

### The Type Vocabulary

This one example uses every type-design tool we have covered: interfaces (`Describable`, `Sortable`), an abstract class (`Shape`), concrete classes inheriting from the abstract one (`Circle`, `Square`), an enum class (`Priority`), and a class implementing multiple interfaces (`PriorityWrapper`). Plus from earlier lessons, sealed classes (`Status` from Lesson 11) and data classes (`Entry` from Lesson 10).

The vocabulary is rich, but each tool has a clear sweet spot. With practice you will reach for the right one without thinking: data class for value records, sealed class for closed type hierarchies with variant-specific data, enum for closed sets without variant-specific data, abstract class for partial implementations with shared behavior, interface for contracts. Most application code uses data classes and sealed classes heavily; enums occasionally; abstract classes and complex interface hierarchies rarely.

---

## 8. Fix the Errors in Your Code

Three inheritance and interface mistakes are common.

**Error 1: Forgetting open on a class you want to extend**

```kotlin
// Wrong
class Animal(val name: String)
class Dog(name: String) : Animal(name)

// Correct
open class Animal(val name: String)
class Dog(name: String) : Animal(name)
```

The wrong version stops with `This type is final, so it cannot be extended.` Kotlin classes are final by default, so extending one without permission is a compile error. The fix is to add `open` to the parent class declaration if you really want to allow extension. As a habit, default to final classes and only mark `open` when you have a specific reason. Most domain types are final; `open` is more common in framework code or in libraries that expose extension points.

**Error 2: Forgetting override on a method that overrides a parent's**

```kotlin
// Wrong
open class Animal {
    open fun sound(): String = "generic"
}

class Dog : Animal() {
    fun sound(): String = "Woof"
}

// Correct
open class Animal {
    open fun sound(): String = "generic"
}

class Dog : Animal() {
    override fun sound(): String = "Woof"
}
```

The wrong version stops with `'sound' hides member of supertype 'Animal' and needs an 'override' modifier.` To override a method, the parent's method must be `open`, and the subclass's method must say `override`. Without `override`, Kotlin refuses to guess whether you meant to replace the parent's method or accidentally reused its name. The fix is to add `override` to the subclass method. As a habit, when a subclass method shares a name with a parent method, always write `override`.

**Error 3: Trying to instantiate an interface directly**

```kotlin
// Wrong
interface Greetable {
    fun greet(): String
}

fun main() {
    val g = Greetable()
    println(g.greet())
}

// Correct
interface Greetable {
    fun greet(): String
}

class Robot(val id: Int) : Greetable {
    override fun greet(): String = "BEEP BOOP UNIT $id"
}

fun main() {
    val g: Greetable = Robot(7)
    println(g.greet())
}
```

The wrong version stops with `Interface 'interface Greetable : Any' does not have constructors.` (plus follow-up errors on the next line, because the compiler no longer knows what `g` is). Interfaces and abstract classes cannot be instantiated directly because they have unimplemented members; the same mistake on an abstract class gives `Cannot create an instance of an abstract class.` The fix is to create an instance of a concrete class that implements the interface, such as `Robot`, and store it in a variable of the interface type if you like. As a habit, design interfaces and abstract classes to be implemented by named classes, and create objects from those classes.

---

## 9. Exercises

These exercises practice the type-modeling tools.

**Exercise 1:** Define an interface `Discountable` with a method `discountedPrice(percent: Double): Double`. Create two classes (`Book` and `Coffee`), each with a `price` property, that implement `Discountable`. Test by printing the discounted price for each at 20%.

**Exercise 2:** Define an enum `DayOfWeek` with all seven days. Add a property `isWeekend: Boolean` that is true for Saturday and Sunday and false for the rest. Use a primary constructor to set the property at declaration time, then iterate over all days and print which ones are weekend days.

**Exercise 3:** Define an abstract class `Notification` with an abstract method `format(): String`. Create concrete subclasses `EmailNotification(val subject: String)`, `SmsNotification(val number: String)`, and `PushNotification(val deviceId: String)`, each implementing `format()` differently. Test by creating one of each and printing their formatted forms.

---

## 10. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

This exercise practices declaring an interface and implementing it in two unrelated classes.

```kotlin
interface Discountable {
    fun discountedPrice(percent: Double): Double
}

class Book(val title: String, val price: Double) : Discountable {
    override fun discountedPrice(percent: Double): Double = price * (100 - percent) / 100
}

class Coffee(val size: String, val price: Double) : Discountable {
    override fun discountedPrice(percent: Double): Double = price * (100 - percent) / 100
}

fun main() {
    val book = Book("Kotlin in Action", 50.0)
    val coffee = Coffee("Large", 4.5)

    println("Book '${book.title}': ${book.price} -> ${book.discountedPrice(20.0)}")
    println("Coffee (${coffee.size}): ${coffee.price} -> ${coffee.discountedPrice(20.0)}")

    val items: List<Discountable> = listOf(book, coffee)
    val total = items.sumOf { it.discountedPrice(20.0) }
    println("Total after 20% off: $total")
}
```

Save and run. Output:

```text
Book 'Kotlin in Action': 50.0 -> 40.0
Coffee (Large): 4.5 -> 3.6
Total after 20% off: 43.6
```

`Discountable` declares one required method, and both `Book` and `Coffee` provide it with `override`. The two classes have nothing else in common (one has a title, the other a size), yet both can sit in a `List<Discountable>`, and `sumOf` can call `discountedPrice` on each without knowing which class it is. The formula `price * (100 - percent) / 100` keeps the arithmetic simple: 20 percent off 50.0 is 40.0. The two implementations happen to be identical here; if that bothers you, the interface could provide `discountedPrice` as a default method that reads an abstract `price` property, which is a nice follow-up experiment.

**Solution for Exercise 2:**

This exercise practices enums with constructor parameters.

```kotlin
enum class DayOfWeek(val isWeekend: Boolean) {
    MONDAY(false),
    TUESDAY(false),
    WEDNESDAY(false),
    THURSDAY(false),
    FRIDAY(false),
    SATURDAY(true),
    SUNDAY(true)
}

fun main() {
    for (d in DayOfWeek.values()) {
        val label = if (d.isWeekend) "weekend" else "weekday"
        println("$d: $label")
    }
}
```

Save and run. Output:

```text
MONDAY: weekday
TUESDAY: weekday
WEDNESDAY: weekday
THURSDAY: weekday
FRIDAY: weekday
SATURDAY: weekend
SUNDAY: weekend
```

The enum has a primary constructor that takes one parameter, `isWeekend: Boolean`, marked as `val` so it becomes a property. Each value provides its argument at declaration: `MONDAY(false)`, `SATURDAY(true)`, and so on. Inside `main`, we iterate over `DayOfWeek.values()` and read each value's `isWeekend` property.

This pattern is one of the cleanest ways to associate static metadata with each variant of an enum. The data is part of the enum value itself, not in a separate table or function. New developers can read the enum and understand the structure at a glance; if they add a new day, the constructor reminds them to specify the weekend flag.

A more elaborate version might add multiple parameters: `MONDAY("Mon", false, 1)` with a short name, a weekend flag, and a sort order. Each piece of related metadata becomes a constructor parameter and a property. Enums with rich metadata like this are common in real Kotlin code, especially for things like HTTP status codes (with name, numeric value, and category) or country codes (with name, ISO code, and currency).

**Solution for Exercise 3:**

This exercise practices an abstract class with one abstract method and three concrete subclasses.

```kotlin
abstract class Notification {
    abstract fun format(): String
}

class EmailNotification(val subject: String) : Notification() {
    override fun format(): String = "[Email] Subject: $subject"
}

class SmsNotification(val number: String) : Notification() {
    override fun format(): String = "[SMS] To: $number"
}

class PushNotification(val deviceId: String) : Notification() {
    override fun format(): String = "[Push] Device: $deviceId"
}

fun main() {
    val notifications: List<Notification> = listOf(
        EmailNotification("Your entry is due today"),
        SmsNotification("+62 812 0000 0000"),
        PushNotification("pixel-7a")
    )

    for (n in notifications) {
        println(n.format())
    }
}
```

Save and run. Output:

```text
[Email] Subject: Your entry is due today
[SMS] To: +62 812 0000 0000
[Push] Device: pixel-7a
```

`Notification` cannot be created on its own, because it does not know how to format itself. Each subclass passes no arguments to `Notification()` (the parent has no constructor parameters) and provides its own `format()`. The loop works through the `List<Notification>` type and calls `format()` on each item; the runtime picks the right implementation for each subclass, which is polymorphism at work.

---

## 11. Understanding Why Final Is the Default

Kotlin's choice to make classes and methods final by default (the opposite of Java) is one of the small but consequential design decisions that shape how Kotlin code is written. Understanding why it matters helps you design types deliberately rather than by accident.

The argument for final-by-default comes from the experience of designing large class hierarchies in Java. Inheritance is a powerful tool, but it is also fragile. A subclass that extends a class is tightly coupled to the parent's implementation, including private behaviors that the parent might rely on internally. If the parent changes, the subclass can break in subtle ways. Joshua Bloch's "Effective Java" devotes an entire item to this issue: "Design and document for inheritance or else prohibit it." The book's advice is that classes should either be explicitly designed for extension (with documented hooks, careful invariants, and stable APIs) or should be marked `final` to prevent extension entirely. The middle ground, where classes are accidentally extendable, leads to bugs.

Java's default is "anyone can extend anything", which is the wrong default given the advice above. Most classes are not designed for extension and should be `final`, but Java requires you to remember to mark them. People forget. Kotlin reverses the default: classes are final unless you mark them `open`. This way, classes are extendable only when you have made a deliberate decision to design for it. The result is fewer accidental extension points and fewer bugs from subclasses depending on parent internals.

The same reasoning applies to methods. A method is part of a class's public API, and overriding it can change behavior in ways that the class's other methods do not expect. Marking methods as `open` is a deliberate signal that "this method is designed to be overridden, and the class is structured to handle subclass-provided implementations." Final methods (the default) give the class implementor control over behavior; if you want callers to be able to customize, you mark the method `open`.

The cost of this approach is that you have to mark `open` more often than you would expect coming from Java. For application code, this is rarely a burden because most application classes are leaf classes that should be final. For library code, you have to think carefully about which classes and methods are part of your public extension contract, which is good design discipline. The Kotlin standard library and most published Kotlin libraries follow the final-by-default approach, with `open` reserved for genuine extension points.

A subtler benefit is that final methods are easier to optimize. The compiler and runtime can sometimes inline a final method call directly, eliminating the dispatch overhead. With `open` methods, the compiler has to assume any subclass might override and use virtual dispatch, which is slower. For most code the difference is negligible, but in hot loops it can matter, and final-by-default gives the optimizer more opportunities.

The deeper cultural lesson is that Kotlin nudges you toward composition over inheritance. When extending a class is more deliberate (requiring `open`), you naturally reach for it less often and look for alternatives. The alternatives are usually composition (one class contains another) or interfaces (one class implements multiple contracts), both of which produce more flexible and maintainable designs than inheritance hierarchies. This is the same advice you would find in any modern OOP book: prefer composition over inheritance. Kotlin's defaults make the advice easier to follow.

---

## Next Up - Lesson 13

Kotlin's type system is built from a small set of orthogonal tools. Classes are final by default; mark them `open` to allow extension. Methods are final by default; mark them `open` to allow overriding, and use `override` in the subclass to make the override explicit. Abstract classes (`abstract class`) provide partial implementations with `abstract` members that subclasses must complete. Interfaces (`interface`) declare contracts that classes implement; classes can implement multiple interfaces, which is one of the main reasons interfaces exist. Enum classes (`enum class`) define closed sets of named constants, optionally with shared metadata via constructor parameters. Combined with data classes (Lesson 10) and sealed classes (Lesson 11), this gives you the full type-design vocabulary of Kotlin. For Catatku, we use data classes for entries (value records), sealed classes for status (closed hierarchies with variant-specific data), and enum classes for priority (closed sets of named constants). The combination produces a type model that catches mistakes at compile time and reads cleanly at runtime.

In Lesson 13 you will learn higher-order functions and lambdas, which take the function-first style from Lesson 6 and let you pass functions as values, returning rich data-processing patterns. The standard library's collection functions (`filter`, `map`, `fold`) all work this way, and they will become your everyday tools.
