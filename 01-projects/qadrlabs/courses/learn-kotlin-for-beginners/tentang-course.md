---
title: "Learn Kotlin for Beginners: Build a Command-Line Task Tracker"
slug: "learn-kotlin-for-beginners"
status: "draft"
---

# Learn Kotlin for Beginners: Build a Command-Line Task Tracker

## Deskripsi
```
Learn Kotlin from zero by building Catatku, a command-line task tracker. Master null safety, collections, data and sealed classes, lambdas, error handling, JSON files, and tests.
```


## Konten

```
Kotlin is a modern, statically typed programming language created by JetBrains. It runs on the JVM, powers Android apps, and is used for server-side and multiplatform code. Its defining features include null safety built into the type system, data classes that remove boilerplate, extension functions, scope functions, sealed classes, and expressive `when` expressions.

This course teaches Kotlin from the ground up by building one real application from start to finish: Catatku, a command-line task tracker. You will add entries, list them with priorities and statuses, mark them done, cancel them with a reason, remove them, and save everything to a JSON file between runs. The first four modules teach the language with small, runnable examples, and each Kotlin idiom is introduced when Catatku's design calls for it. The last two modules turn those pieces into a multi-file application with a command-line interface, file storage, JSON serialization, and a test suite.

Every lesson follows the same rhythm: build something step by step, run it and check the output, fix common mistakes, and practice with three exercises that come with full solutions.

**Prerequisites:**
- No previous Kotlin experience required; basic computer skills and comfort with typing commands in a terminal
- A computer running Windows, macOS, or Linux with at least 4 GB of RAM
- JDK 17 or newer and IntelliJ IDEA (installation is covered in Lesson 2)
- An internet connection to download the JDK, the IDE, and Gradle dependencies

**By the end, you will have:**
- A working Kotlin development environment with IntelliJ IDEA and Gradle (Kotlin DSL)
- A solid grasp of variables, types, control flow, functions, and collections
- A clear understanding of null safety with `?.`, `?:`, smart casts, and `let`
- Experience modeling data with classes, data classes, sealed classes, enum classes, and interfaces
- Practice with lambdas, higher-order functions, extension functions, and scope functions
- Error handling with exceptions, `runCatching`, and sealed result types
- Code organized into packages, a command-line interface, and file storage with kotlinx.serialization
- A Catatku task tracker with a passing test suite written with `kotlin.test`
```

## Daftar Modul

### 1. `Module 1 - Getting Started`

```
Meet Kotlin and the Catatku project, set up the JDK, IntelliJ IDEA, and Gradle, then write your first programs with variables and data types.
```


- Lesson 1 - What We Will Build
    lesson short description
    ```
    Tour the Catatku task tracker you will build, learn why Kotlin is worth learning, and see how the six modules of the course fit together.
    
    ```
- Lesson 2 - Setting Up Your Kotlin Environment
    lesson short description
    ```
    Install a JDK and IntelliJ IDEA, create a Kotlin Gradle project, run it from the IDE and the terminal, and learn what each project file does.
    
    ```
- Lesson 3 - Your First Kotlin Program
    lesson short description
    ```
    Understand fun main, print text with println and print, build strings with templates, and document your code with comments.
    
    ```
- Lesson 4 - Variables and Data Types
    lesson short description
    ```
    Declare values with val and var, rely on type inference, use numeric, boolean, character, and string types, and convert between them explicitly.
    
    ```

### 2. `Module 2 - Kotlin Basics`

```
Control the flow of your programs, write reusable functions, handle missing values safely, and store data in lists, maps, and sets.
```


- Lesson 5 - Control Flow
    lesson short description
    ```
    Use if and when as expressions, loop over ranges and collections with for, repeat work with while, and control loops with break and continue.
    
    ```
- Lesson 6 - Functions
    lesson short description
    ```
    Declare functions with parameters and return types, use default and named arguments, write single-expression functions, and meet the Unit type.
    
    ```
- Lesson 7 - Null Safety
    lesson short description
    ```
    Work with nullable types using safe calls, the Elvis operator, smart casts, and let, and learn why the not-null assertion is a last resort.
    
    ```
- Lesson 8 - Collections
    lesson short description
    ```
    Store data in lists, maps, and sets, choose between read-only and mutable collections, and get a first look at filter and map.
    
    ```

### 3. `Module 3 - Classes and Types`

```
Model Catatku's data with classes, data classes, sealed classes, enum classes, and interfaces so the compiler catches mistakes for you.
```


- Lesson 9 - Classes and Objects
    lesson short description
    ```
    Declare classes with primary constructors and properties, add member functions and init blocks, control visibility, and use companion objects.
    
    ```
- Lesson 10 - Data Classes
    lesson short description
    ```
    Define the Entry data class for Catatku and use the equals, toString, copy, and destructuring support that data classes generate for you.
    
    ```
- Lesson 11 - Sealed Classes and Pattern Matching
    lesson short description
    ```
    Model entry statuses with a sealed class, carry data in variants, and let exhaustive when expressions catch missing cases at compile time.
    
    ```
- Lesson 12 - Inheritance, Interfaces, and Enum Classes
    lesson short description
    ```
    Extend open and abstract classes, implement interfaces, define the Priority enum class, and decide when to use an enum or a sealed class.
    
    ```

### 4. `Module 4 - Functional Kotlin`

```
Write concise, idiomatic Kotlin with lambdas, higher-order functions, extension functions, scope functions, and clear error handling.
```


- Lesson 13 - Higher-Order Functions and Lambdas
    lesson short description
    ```
    Write lambdas, store functions in variables, and process collections with filter, map, fold, and friends, chaining them into clear pipelines.
    
    ```
- Lesson 14 - Extension Functions and Properties
    lesson short description
    ```
    Add functions and properties to existing types without changing them, write extensions for Catatku types, and learn how extensions are resolved.
    
    ```
- Lesson 15 - Scope Functions
    lesson short description
    ```
    Use let, apply, also, run, and with for null handling, object configuration, and side effects, and pick the right one with a simple decision tree.
    
    ```
- Lesson 16 - Error Handling
    lesson short description
    ```
    Handle failures with try and catch, use try as an expression, turn exceptions into Result with runCatching, and model expected errors with a sealed class.
    
    ```

### 5. `Module 5 - Building Catatku`

```
Turn the language examples into a real multi-file command-line application that reads commands and saves entries to a JSON file.
```


- Lesson 17 - Organizing Code with Packages
    lesson short description
    ```
    Split Catatku into several files under one package, use imports and visibility modifiers, and keep each file focused on a single concern.
    
    ```
- Lesson 18 - Reading Command Line Arguments
    lesson short description
    ```
    Read command-line arguments in main, dispatch commands with when, parse ids safely with toIntOrNull, and print helpful usage and error messages.
    
    ```
- Lesson 19 - Working with Files
    lesson short description
    ```
    Save and load Catatku entries with Kotlin's file helpers, treat a missing file as an empty list, and handle file errors gracefully.
    
    ```
- Lesson 20 - JSON with kotlinx.serialization
    lesson short description
    ```
    Add kotlinx.serialization to the build, annotate the domain types, and replace the hand-written file format with pretty-printed JSON.
    
    ```

### 6. `Module 6 - Real-World Kotlin`

```
Protect Catatku with automated tests, then review what you have learned and plan your next steps with Kotlin.
```


- Lesson 21 - Writing Tests
    lesson short description
    ```
    Write unit tests with kotlin.test for the entry list, the JSON round-trip, and file storage, and run them with Gradle and IntelliJ IDEA.
    
    ```
- Lesson 22 - What's Next
    lesson short description
    ```
    Look back at the finished Catatku, review what the course did not cover, and choose your next steps with coroutines, Android, Ktor, or Multiplatform.
    
    ```
