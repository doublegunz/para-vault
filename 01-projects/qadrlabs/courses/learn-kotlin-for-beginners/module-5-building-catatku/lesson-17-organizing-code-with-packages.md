## 1. Before You Begin

Up to this point, every Kotlin example we have written has lived in a single file (`Main.kt`) in the default package. That works for small examples, but Catatku is starting to outgrow it. We have data classes, sealed classes, enum classes, extension functions, and error types, all crowding into one file. Real applications spread their code across many files, with each file focused on a single concern, and use packages to organize related code together. Lesson 17 marks the transition from "Catatku as a single-file demo" to "Catatku as a real multi-file application", which means we need to learn how Kotlin handles file organization.

A package in Kotlin is a namespace: a logical grouping of related types and functions. Packages give names to your code that are unique across the whole codebase, so that two different files can declare the same class name without conflict, as long as they are in different packages. Packages also act as a coarse-grained access control unit: the `internal` visibility modifier (Lesson 9) limits visibility to the same module, but you can also use file-level `private` to limit visibility within a single file. By the end of this lesson, Catatku's code will be split across several files (`Entry.kt`, `EntryList.kt`, `Errors.kt`, and `Main.kt`), all sharing a `com.qadrlabs.catatku` package, and each file's responsibilities will be clearly separated.

This lesson also marks the start of Module 5, "Building Catatku". The previous modules taught you the language; from here on, every lesson adds a real piece of the application. Lesson 17 organizes the code. Lesson 18 adds the command-line interface. Lesson 19 adds file I/O. Lesson 20 swaps in JSON serialization. By the end of Module 5, Catatku is a complete, working CLI application built in idiomatic Kotlin, and Module 6 then adds tests (Lesson 21) and wraps up the course (Lesson 22).

### What You'll Build

The skeleton of the multi-file Catatku project. You will create the directory structure under `src/main/kotlin/com/qadrlabs/catatku/`, move the existing types into appropriate files, add `package` declarations and `import` statements, and verify that everything still compiles and runs. The functionality is the same as Lesson 16's setup; we are just organizing the code into a structure that can grow.

### What You'll Learn

- ✅ How `package` declarations at the top of a file determine the file's namespace
- ✅ How directory structure must match package structure
- ✅ How `import` brings types and functions from other packages into scope
- ✅ When to use `internal` visibility for module-private code
- ✅ How file-level `private` hides helpers that should not be exported

### What You'll Need

- The `catatku` Gradle project from previous lessons
- Familiarity with the Catatku domain types (`Entry`, `Status`, `Priority`, `CatatkuError`)
- About thirty-five minutes
- Willingness to make small structural changes that may feel slow at first
- A terminal open in the project root, so you can run `./gradlew run -q` (the `-q` flag hides Gradle's own progress lines and shows only your program's output)

---

## 2. Package Declarations

Every Kotlin file can begin with a `package` declaration that names its namespace. Files without a `package` declaration are in the "default package", which is what we have been using. In this section you will move `Main.kt` into a package, tell Gradle where the new entry point lives, and run the program again to prove nothing broke.

### Step 1: Move the File to Match the Package

The package we will use is `com.qadrlabs.catatku`. By convention, a file in that package lives in a directory that matches the package name. Currently `Main.kt` is in `src/main/kotlin/`. The package `com.qadrlabs.catatku` requires it to be in `src/main/kotlin/com/qadrlabs/catatku/`. Use IntelliJ's project tree or your terminal to create the directory structure and move the file:

```text
src/main/kotlin/
└── com/
    └── qadrlabs/
        └── catatku/
            └── Main.kt
```

The directory structure now matches the package name segment by segment: `com` directory, `qadrlabs` directory inside it, `catatku` directory inside that, and finally `Main.kt`. This convention is important because IntelliJ uses it for navigation and refactoring, and every Kotlin developer who opens your project expects it.

A subtle note: Kotlin technically allows the directory structure to differ from the package, but doing so is non-idiomatic and confuses tooling. As a habit, always match the directory structure to the package name. IntelliJ's refactoring tools (like "Move..." on a class) automatically maintain this correspondence when you move things around.

### Step 2: Add a Package Declaration

Open the moved `Main.kt` and replace its contents with this small program. The first line is the new part:

```kotlin
package com.qadrlabs.catatku

fun main() {
    println("Catatku now lives in package com.qadrlabs.catatku")
}
```

The `package com.qadrlabs.catatku` declaration says that everything in this file belongs to the package `com.qadrlabs.catatku`. It must be the first line of the file, before any imports or other code. The package name is a series of identifiers separated by dots, by convention starting with a reverse domain name to avoid conflicts with other libraries.

The convention `com.qadrlabs.catatku` is used because the qadrlabs.com website's domain reversed is `com.qadrlabs`, and `catatku` is the application name. Real-world projects follow this convention to avoid name clashes when their code is published or used alongside other libraries. For internal company code, `com.companyname.projectname.module` is typical.

### Step 3: Point Gradle at the New Main Class

Moving `main` into a package changes the name of the class Kotlin generates for it. In Lesson 2 you saw that the top-level functions in `Main.kt` compile into a class called `MainKt`. Now that the file declares a package, the class is called `com.qadrlabs.catatku.MainKt`, and the `application` block in `build.gradle.kts` must use that full name. Open `build.gradle.kts` and update it so the whole file looks like this:

```kotlin
plugins {
    kotlin("jvm") version "2.0.0"
    application
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(kotlin("test"))
}

application {
    mainClass.set("com.qadrlabs.catatku.MainKt")
}

tasks.test {
    useJUnitPlatform()
}

kotlin {
    jvmToolchain(17)
}
```

The only line that changed is `mainClass.set("com.qadrlabs.catatku.MainKt")`. It is the package name, a dot, and the generated class name. The green run icon next to `fun main()` in IntelliJ works either way, because the IDE finds the function directly, but `./gradlew run` relies on this setting. Run the project from the terminal:

```bash
./gradlew run -q
```

Output:

```text
Catatku now lives in package com.qadrlabs.catatku
```

The program runs exactly as before, now from inside a package.

### How Imports Relate to Packages

Now that `Main.kt` is in package `com.qadrlabs.catatku`, anything declared in this file is in that package. Files in other packages would need to import the types to use them. Within the same package, no imports are needed; you can use types declared in any file of the same package directly.

We have not yet split into multiple files, so we cannot demonstrate imports yet. Section 3 will create additional files in the same package and Section 4 will show how imports work when crossing packages.

---

## 3. Splitting Into Multiple Files

Now let us split the single-file Catatku into multiple focused files. The split will follow concerns: domain types in one file, collection wrapper in another, error types in another, and the entry point in the last.

### Step 1: Create Entry.kt for Domain Types

Create a new file `src/main/kotlin/com/qadrlabs/catatku/Entry.kt` with the domain type declarations:

```kotlin
package com.qadrlabs.catatku

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

// === Extensions ===

val Status.marker: String
    get() = when (this) {
        is Status.Pending -> "[ ]"
        is Status.InProgress -> "[~]"
        is Status.Done -> "[x]"
        is Status.Cancelled -> "[!]"
    }

val Status.isTerminal: Boolean
    get() = this is Status.Done || this is Status.Cancelled

val Entry.summary: String
    get() = "${this.status.marker} (${this.priority.shortLabel()}) ${this.id}. ${this.description}"

val Entry.isActive: Boolean
    get() = !this.status.isTerminal

fun Entry.markDone(): Entry = this.copy(status = Status.Done)
fun Entry.markInProgress(): Entry = this.copy(status = Status.InProgress)
fun Entry.cancel(reason: String): Entry = this.copy(status = Status.Cancelled(reason))
fun Entry.withPriority(p: Priority): Entry = this.copy(priority = p)
```

Save the file. The first line `package com.qadrlabs.catatku` puts everything in this file in the same package as `Main.kt`. All the types and extensions from earlier lessons live here together, organized by concern (the data types, then the extensions on those types).

### Step 2: Create Errors.kt for Error Types

Create `src/main/kotlin/com/qadrlabs/catatku/Errors.kt`:

```kotlin
package com.qadrlabs.catatku

sealed class CatatkuError {
    data class EntryNotFound(val id: Int) : CatatkuError()
    data class InvalidId(val text: String) : CatatkuError()
    object EmptyDescription : CatatkuError()
    data class IoError(val message: String) : CatatkuError()
    data class ParseError(val message: String) : CatatkuError()

    fun describe(): String = when (this) {
        is EntryNotFound -> "Entry with id $id not found"
        is InvalidId -> "Invalid id: '$text' is not a valid integer"
        is EmptyDescription -> "Description cannot be empty"
        is IoError -> "I/O error: $message"
        is ParseError -> "Parse error: $message"
    }
}

sealed class CatatkuResult<out T> {
    data class Ok<T>(val value: T) : CatatkuResult<T>()
    data class Err(val error: CatatkuError) : CatatkuResult<Nothing>()
}
```

Save. The file declares `CatatkuError` and `CatatkuResult` in the same package `com.qadrlabs.catatku`. Because both files are in the same package, code in either file can refer to types in the other without imports.

### Step 3: Create EntryList.kt for the Collection Wrapper

Create `src/main/kotlin/com/qadrlabs/catatku/EntryList.kt`:

```kotlin
package com.qadrlabs.catatku

class EntryList {
    private val entries: MutableList<Entry> = mutableListOf()
    private var nextId: Int = 1

    val size: Int
        get() = entries.size

    val isEmpty: Boolean
        get() = entries.isEmpty()

    fun all(): List<Entry> = entries.toList()

    fun add(description: String, priority: Priority = Priority.MEDIUM): CatatkuResult<Entry> {
        if (description.isBlank()) {
            return CatatkuResult.Err(CatatkuError.EmptyDescription)
        }
        val newEntry = Entry(
            id = nextId,
            description = description.trim(),
            priority = priority
        )
        entries.add(newEntry)
        nextId += 1
        return CatatkuResult.Ok(newEntry)
    }

    fun findById(id: Int): CatatkuResult<Entry> {
        val found = entries.firstOrNull { it.id == id }
            ?: return CatatkuResult.Err(CatatkuError.EntryNotFound(id))
        return CatatkuResult.Ok(found)
    }

    fun markDone(id: Int): CatatkuResult<Entry> {
        val index = entries.indexOfFirst { it.id == id }
        if (index < 0) {
            return CatatkuResult.Err(CatatkuError.EntryNotFound(id))
        }
        val updated = entries[index].markDone()
        entries[index] = updated
        return CatatkuResult.Ok(updated)
    }

    fun cancel(id: Int, reason: String): CatatkuResult<Entry> {
        val index = entries.indexOfFirst { it.id == id }
        if (index < 0) {
            return CatatkuResult.Err(CatatkuError.EntryNotFound(id))
        }
        val updated = entries[index].cancel(reason)
        entries[index] = updated
        return CatatkuResult.Ok(updated)
    }

    fun remove(id: Int): CatatkuResult<Entry> {
        val index = entries.indexOfFirst { it.id == id }
        if (index < 0) {
            return CatatkuResult.Err(CatatkuError.EntryNotFound(id))
        }
        val removed = entries.removeAt(index)
        return CatatkuResult.Ok(removed)
    }

    fun activeOnly(): List<Entry> = entries.filter { it.isActive }

    fun byPriority(p: Priority): List<Entry> = entries.filter { it.priority == p }
}
```

Save. The `EntryList` class wraps a `MutableList<Entry>` (private, encapsulated) and exposes operations to add, find, mark done, cancel, and remove entries. Each operation returns a `CatatkuResult<Entry>`, so callers handle errors uniformly via `when`.

The `private val entries` and `private var nextId` are private to the class. Outside callers cannot read or modify them directly; they go through the public methods. The public `all()` method returns `entries.toList()`, which produces an immutable copy that callers cannot use to mutate the original.

This is the encapsulation pattern from Lesson 9 applied to a real domain object. The mutable state is hidden, the public API is methods that maintain invariants (auto-incrementing the id, validating description, finding by id), and external code cannot bypass these invariants because the field is not accessible.

### Step 4: Update Main.kt to Use the Other Files

Replace the contents of `Main.kt` (now at `src/main/kotlin/com/qadrlabs/catatku/Main.kt`) with:

```kotlin
package com.qadrlabs.catatku

fun main() {
    val list = EntryList()

    list.add("Pay rent", Priority.HIGH)
    list.add("Finish Kotlin course", Priority.HIGH)
    list.add("Read for fun", Priority.LOW)
    list.add("Call dentist")
    list.add("Walk the dog")

    println("=== All entries ===")
    for (entry in list.all()) {
        println(entry.summary)
    }

    println("\n=== Marking entry 2 done ===")
    when (val result = list.markDone(2)) {
        is CatatkuResult.Ok -> println("Done: ${result.value.summary}")
        is CatatkuResult.Err -> println("Error: ${result.error.describe()}")
    }

    println("\n=== Cancelling entry 4 ===")
    when (val result = list.cancel(4, "rescheduled")) {
        is CatatkuResult.Ok -> println("Cancelled: ${result.value.summary}")
        is CatatkuResult.Err -> println("Error: ${result.error.describe()}")
    }

    println("\n=== Trying to mark entry 99 done (does not exist) ===")
    when (val result = list.markDone(99)) {
        is CatatkuResult.Ok -> println("Done: ${result.value.summary}")
        is CatatkuResult.Err -> println("Error: ${result.error.describe()}")
    }

    println("\n=== Final state ===")
    for (entry in list.all()) {
        println(entry.summary)
    }

    println("\n=== Active only ===")
    for (entry in list.activeOnly()) {
        println(entry.summary)
    }

    println("\n=== High priority ===")
    for (entry in list.byPriority(Priority.HIGH)) {
        println(entry.summary)
    }
}
```

Save and run. Output:

```text
=== All entries ===
[ ] (H) 1. Pay rent
[ ] (H) 2. Finish Kotlin course
[ ] (L) 3. Read for fun
[ ] (M) 4. Call dentist
[ ] (M) 5. Walk the dog

=== Marking entry 2 done ===
Done: [x] (H) 2. Finish Kotlin course

=== Cancelling entry 4 ===
Cancelled: [!] (M) 4. Call dentist

=== Trying to mark entry 99 done (does not exist) ===
Error: Entry with id 99 not found

=== Final state ===
[ ] (H) 1. Pay rent
[x] (H) 2. Finish Kotlin course
[ ] (L) 3. Read for fun
[!] (M) 4. Call dentist
[ ] (M) 5. Walk the dog

=== Active only ===
[ ] (H) 1. Pay rent
[ ] (L) 3. Read for fun
[ ] (M) 5. Walk the dog

=== High priority ===
[ ] (H) 1. Pay rent
[x] (H) 2. Finish Kotlin course
```

The output is what we expect: the entries are added, two are modified (one done, one cancelled), one operation fails gracefully, and the final state reflects the changes. Notice that `Main.kt` does not need any `import` statements because every type it uses (`EntryList`, `Priority`, `CatatkuResult`, etc.) is in the same package.

The directory structure is now:

```text
src/main/kotlin/
└── com/
    └── qadrlabs/
        └── catatku/
            ├── Entry.kt        (domain types)
            ├── EntryList.kt    (collection wrapper)
            ├── Errors.kt       (error types)
            └── Main.kt         (entry point)
```

This is a small but real multi-file Kotlin project. Each file has a clear concern, and the package gathers them together. As Catatku grows in subsequent lessons, we will add files for command-line parsing, file I/O, and JSON serialization, each in the same package.

---

## 4. Imports for Cross-Package Use

When code in one package wants to use a type from a different package, it needs an `import` statement. We have not needed imports yet because all our code is in one package. But Catatku will soon use an external type from the Java standard library: `java.io.File` (for the file I/O coming in Lesson 19). Let us look at how imports work using a few small examples. Each one temporarily replaces the contents of `Main.kt`; the other files stay untouched.

### Step 1: A Simple Import

Replace `Main.kt` temporarily with this small example:

```kotlin
package com.qadrlabs.catatku

import java.io.File

fun main() {
    val tempFile = File("/tmp/catatku-test.txt")
    println("File path: ${tempFile.absolutePath}")
    println("Exists: ${tempFile.exists()}")
}
```

Save and run. The output depends on your operating system and on whether the file exists. On Linux, with no such file, it looks like this:

```text
File path: /tmp/catatku-test.txt
Exists: false
```

The line `import java.io.File` brings the `File` class from the `java.io` package into scope. Now the rest of the file can refer to it by its short name `File` instead of the fully qualified `java.io.File`. Without the import, we would have to write `val tempFile = java.io.File("/tmp/catatku-test.txt")`, which is more verbose. The program only creates a `File` object that describes a path; it does not create the file on disk, which is why `exists()` returns `false`.

Imports go at the top of the file, after the package declaration but before any other code. By convention, imports are grouped (standard library imports first, then third-party, then project imports), but Kotlin does not enforce this. IntelliJ's "Optimize Imports" command keeps them tidy automatically.

### Step 2: Importing Multiple Things

You can import several types from the same package with one `import` line each. This example imports both `File` and the exception it throws when a file is missing:

```kotlin
package com.qadrlabs.catatku

import java.io.File
import java.io.FileNotFoundException

fun main() {
    try {
        val text = File("missing.txt").readText()
        println(text)
    } catch (e: FileNotFoundException) {
        println("Caught: ${e.message}")
    }
}
```

Save and run. On Linux the output is:

```text
Caught: missing.txt (No such file or directory)
```

The two `import` lines bring in `File` and `FileNotFoundException`. `readText()` tries to read `missing.txt` from the project folder, the file does not exist, and the `catch` block (from Lesson 16) receives the `FileNotFoundException`. The exact message text comes from the operating system, so it reads slightly differently on Windows.

You could replace both lines with a wildcard, `import java.io.*`, which imports everything in `java.io`. Most codebases prefer the explicit form because it makes the dependencies visible. Wildcards are convenient but obscure which specific types are used. As a habit, use explicit imports unless you really do use many things from the same package.

### Step 3: Importing Functions and Properties

Imports work for functions and properties too, not just classes. For example, the `println` function we have been using is in `kotlin.io`, but it is automatically imported (the standard library has a small set of "implicit imports" that always work). For functions in other packages, you need an explicit import:

```kotlin
package com.qadrlabs.catatku

import kotlin.math.PI
import kotlin.math.sqrt

fun main() {
    println(PI)
    println(sqrt(16.0))
}
```

Save and run. Output:

```text
3.141592653589793
4.0
```

The constant `PI` and the function `sqrt` come from `kotlin.math`, which is not implicitly imported, so we add explicit imports. After the imports, we use the names directly.

For Catatku, we will need a few imports as we add functionality: `java.io.File` for file I/O in Lesson 19, and `kotlinx.serialization.json.Json` and related types for JSON in Lesson 20. The pattern is the same: add the import at the top, use the short name throughout the file.

### Step 4: Restore Main.kt

Restore the multi-file Catatku version of `Main.kt` from Section 3, Step 4, and run it once more to confirm you see the same output as before. We will not need the `File` import yet; that will come in Lesson 19.

---

## 5. Run and Test

The split-file Catatku from Section 3 is the comprehensive example for this lesson. You have already run it; the output verifies that everything compiles and works correctly. Now confirm the layout and practice adding one more file to the package.

### Step 1: Verify the File Structure

Confirm your project structure looks like:

```text
src/main/kotlin/
└── com/
    └── qadrlabs/
        └── catatku/
            ├── Entry.kt
            ├── EntryList.kt
            ├── Errors.kt
            └── Main.kt
```

Each file has the `package com.qadrlabs.catatku` declaration as its first line. None of the files needs `import` statements for the others, because they share a package.

### Step 2: Add a New File

To practice, create a fifth file `src/main/kotlin/com/qadrlabs/catatku/Stats.kt` that provides a summary function:

```kotlin
package com.qadrlabs.catatku

fun statistics(list: EntryList): String {
    val all = list.all()
    val total = all.size
    val active = all.count { it.isActive }
    val done = all.count { it.status is Status.Done }
    val cancelled = all.count { it.status is Status.Cancelled }

    return """
        |Total: $total
        |Active: $active
        |Done: $done
        |Cancelled: $cancelled
    """.trimMargin()
}
```

The function takes an `EntryList`, reads a snapshot of its entries with `all()`, and counts them with `count { ... }` (Lesson 13): every entry for the total, active entries using the `isActive` extension from `Entry.kt`, and done or cancelled entries by checking the status type with `is`. The triple-quoted string with `|` markers and `trimMargin()` builds a multi-line report without leading indentation.

### Step 3: Call It from Main.kt

Now give `Main.kt` a shorter `main` that sets up a few entries and prints the statistics:

```kotlin
package com.qadrlabs.catatku

fun main() {
    val list = EntryList()

    list.add("Pay rent", Priority.HIGH)
    list.add("Finish Kotlin course", Priority.HIGH)
    list.add("Read for fun", Priority.LOW)
    list.add("Call dentist")
    list.add("Walk the dog")

    list.markDone(2)
    list.cancel(4, "rescheduled")

    println("=== Statistics ===")
    println(statistics(list))
}
```

Save and run. Output:

```text
=== Statistics ===
Total: 5
Active: 3
Done: 1
Cancelled: 1
```

The new file declares a function in the same package as the rest. `Main.kt` calls it without any import because they are in the same package. This is how Catatku grows: add a new file for each new concern, keep them in the same package, and the compiler handles the connections. Keep `Stats.kt` in the project, and put the full `Main.kt` from Section 3 back afterward; Lesson 18 replaces `main` entirely anyway.

### Subpackages for Larger Projects

For a larger project you might split into subpackages. For example, you could put domain types in `com.qadrlabs.catatku.domain`, error types in `com.qadrlabs.catatku.error`, and the entry point in `com.qadrlabs.catatku`. Each subpackage would be its own directory.

Doing this for Catatku is overkill (we only have a handful of files), but the pattern is good to know. The directory structure would mirror the package structure exactly, and cross-subpackage uses would require imports. Exercise 3 lets you try it once.

---

## 6. Visibility Across Packages

Visibility modifiers (Lesson 9) interact with packages in interesting ways. The default `public` visibility is everywhere; `private` at the file level is file-only; `internal` is module-wide. This section is a reference for those rules rather than a set of build steps.

### File-Level private

A function or class declared `private` at the top level (not inside a class) is visible only within the same file. This is useful for utility helpers that are implementation details of a single file.

```kotlin
package com.qadrlabs.catatku

private fun internalHelper(): Int = 42

class PublicClass {
    fun useHelper(): Int = internalHelper()  // ok, same file
}
```

Imagine this is the whole content of a file called `Helpers.kt`. Anywhere outside `Helpers.kt`, the function `internalHelper` is invisible. Even other files in the same package cannot use it; Exercise 2 shows the exact compiler message you get if you try. This is more restrictive than Java's "package-private" (which has no direct Kotlin equivalent).

For Catatku, file-level `private` is the right tool for things like small parsing helpers that should not be part of the application's public API.

### internal for Module-Wide

The `internal` modifier limits visibility to the same module. A "module" in Kotlin is roughly one Gradle project or one Gradle subproject. For Catatku, the entire application is one module, so `internal` is essentially "everywhere in the project but invisible to external libraries that depend on us".

```kotlin
package com.qadrlabs.catatku

internal class InternalHelper {
    fun doWork(): String = "internal work"
}
```

For an application like Catatku, the difference between `public` and `internal` does not matter much because nothing outside Catatku uses Catatku's types. The distinction becomes important when you write a library that other projects depend on: `public` means "part of the published API", while `internal` means "implementation detail, not for external use".

### No Package-Private Visibility

Kotlin does not have a "package-private" visibility like Java. Code in one package cannot say "I am visible to other code in the same package but not elsewhere". The closest analog is `internal` (visible to the same module) or file-level `private` (visible to one file).

In practice, the main Kotlin visibility tool for organizing access is class-level `private` (members of a class only visible inside the class). For utilities that should be hidden, file-level `private` works for single files; for module-wide code that should be hidden from external dependents, `internal` works.

For Catatku's small package, we will use `public` (default) for the API of `Entry`, `Status`, `Priority`, `CatatkuError`, and `EntryList`, and `private` for helper functions inside specific files.

---

## 7. The IntelliJ Refactoring Workflow

Real Kotlin development uses IntelliJ for moves, renames, and other structural changes. The IDE handles updates to imports and references automatically, which makes refactoring cheap. You do not need to perform these now; they are worth knowing as the project grows.

### Move a Class to a New File

Suppose we decide to move `Status` out of `Entry.kt` into its own `Status.kt`. In IntelliJ, right-click on the `Status` declaration and choose Refactor > Move. The IDE moves the class declaration to the file you choose and updates any imports automatically.

For Catatku, we will not split this finely, but the workflow is good to know. As a project grows, you will want to move things around, and the IDE makes it painless.

### Rename a Class

If we wanted to rename `Entry` to `Task`, IntelliJ's refactor tool would update every reference across the codebase: in `Entry.kt`, in `EntryList.kt`, in `Main.kt`, in any tests, everywhere. The workflow is right-click > Refactor > Rename, type the new name, hit Enter. The IDE does the work.

This is the practical advantage of static typing and good tooling: changes that would be risky in dynamic languages (rename a class and hope for the best) are mechanical operations in Kotlin. The compiler knows every reference, and the IDE uses that knowledge to update them all.

### Find Usages

Right-click on a class or function and choose Find Usages to see every place it is used in the codebase. This is invaluable when reasoning about whether a change is safe: "if I change this method, what will be affected?" The list of usages tells you. For Catatku's small project, the usages are obvious; for large projects, this tool is essential.

---

## 8. Fix the Errors in Your Code

Three package-related mistakes are common when you first split a project into packages.

**Error 1: Forgetting to update mainClass**

```kotlin
// Wrong (build.gradle.kts, after Main.kt moved into com.qadrlabs.catatku)
application {
    mainClass.set("MainKt")
}

// Correct
application {
    mainClass.set("com.qadrlabs.catatku.MainKt")
}
```

With the wrong setting, the code compiles but `./gradlew run` fails with `Error: Could not find or load main class MainKt`, followed by `Caused by: java.lang.ClassNotFoundException: MainKt`. The class Kotlin generated is now `com.qadrlabs.catatku.MainKt`, and the JVM needs the full name to find it. The fix is to use the package name plus `MainKt` in `mainClass`. The IntelliJ run icon keeps working even with the wrong setting, which is why this mistake often shows up only when you first run from the terminal.

**Error 2: Using a class from another package without importing it**

```kotlin
// Wrong
package com.qadrlabs.catatku

fun main() {
    val tempFile = File("/tmp/catatku-test.txt")
    println("Exists: ${tempFile.exists()}")
}

// Correct
package com.qadrlabs.catatku

import java.io.File

fun main() {
    val tempFile = File("/tmp/catatku-test.txt")
    println("Exists: ${tempFile.exists()}")
}
```

Types from outside the current package need imports. Without the import, the compiler reports `Unresolved reference 'File'.` The fix is to add the import at the top of the file. IntelliJ usually suggests the import automatically when you type a type name; pressing Alt+Enter (Option+Enter on macOS) on the unresolved name accepts the suggestion.

**Error 3: A package declaration that does not match the other files**

```kotlin
// Wrong (first line of EntryList.kt)
package com.qadrlabs.catatku.model

// Correct (first line of EntryList.kt)
package com.qadrlabs.catatku
```

A typo or a copy-pasted header puts `EntryList.kt` in a different package from `Entry.kt` and `Errors.kt`. The file then cannot see the types it uses without imports, and the compiler reports errors such as `Unresolved reference 'Entry'.` inside `EntryList.kt`. The fix is to make the package declaration match the directory and the rest of the files. As a habit, when creating a new file in IntelliJ, let the IDE generate the package declaration based on the directory; this avoids the mistake.

---

## 9. Exercises

These exercises practice package organization.

**Exercise 1:** Add a new file `Display.kt` to the `com.qadrlabs.catatku` package containing a function `printAll(list: EntryList)` that prints every entry's summary. Modify `Main.kt` to use this function in place of a manual loop.

**Exercise 2:** Add a new file `Util.kt` containing a `private` top-level function `internalCount(items: List<Any>): Int = items.size`. From `Main.kt`, try to call `internalCount(list.all())` and observe the compile error. Then change the function to `internal` (or remove the `private`) and confirm it works.

**Exercise 3:** Suppose Catatku grows into multiple subpackages. Create a subpackage `com.qadrlabs.catatku.display` containing a new `Formatter.kt` file with a function `formatPriorityHeader(p: Priority): String`. Use it from `Main.kt` and observe what import is needed.

---

## 10. Solutions

Try the exercises yourself first, then check the solutions below. Each solution replaces `Main.kt` temporarily; restore the Section 3 version when you are done, and delete the exercise files if you do not want to keep them.

**Solution for Exercise 1:**

Create `src/main/kotlin/com/qadrlabs/catatku/Display.kt`:

```kotlin
package com.qadrlabs.catatku

fun printAll(list: EntryList) {
    for (entry in list.all()) {
        println(entry.summary)
    }
}
```

The function lives in the same package as everything else, so it can use `EntryList` and the `summary` extension property without imports. Now use it from `Main.kt`:

```kotlin
package com.qadrlabs.catatku

fun main() {
    val list = EntryList()

    list.add("Pay rent", Priority.HIGH)
    list.add("Finish Kotlin course", Priority.HIGH)
    list.add("Read for fun", Priority.LOW)

    list.markDone(2)

    println("=== All entries ===")
    printAll(list)
}
```

Save and run. Output:

```text
=== All entries ===
[ ] (H) 1. Pay rent
[x] (H) 2. Finish Kotlin course
[ ] (L) 3. Read for fun
```

`main` no longer contains the loop; it calls `printAll(list)` and the new file does the printing. Moving small, repeated pieces of code into named functions in their own files is how `Main.kt` stays short as the application grows.

**Solution for Exercise 2:**

Create `src/main/kotlin/com/qadrlabs/catatku/Util.kt`:

```kotlin
package com.qadrlabs.catatku

private fun internalCount(items: List<Any>): Int = items.size
```

Then call it from `Main.kt`:

```kotlin
package com.qadrlabs.catatku

fun main() {
    val list = EntryList()
    list.add("Pay rent", Priority.HIGH)
    list.add("Read for fun", Priority.LOW)

    println("Entries: ${internalCount(list.all())}")
}
```

The build fails with `Cannot access 'fun internalCount(items: List<Any>): Int': it is private in file.` Even though `Main.kt` and `Util.kt` share a package, a top-level `private` function belongs to its file only. Now change `private` to `internal` in `Util.kt`:

```kotlin
package com.qadrlabs.catatku

internal fun internalCount(items: List<Any>): Int = items.size
```

Save and run again. Output:

```text
Entries: 2
```

With `internal`, the function is visible anywhere in the module, so `Main.kt` can call it. Removing the modifier entirely (making it `public`) would also work; `internal` simply keeps it out of any public API.

**Solution for Exercise 3:**

This exercise practices subpackages and imports. Create the directory `src/main/kotlin/com/qadrlabs/catatku/display/` and add a file `Formatter.kt` inside:

```kotlin
package com.qadrlabs.catatku.display

import com.qadrlabs.catatku.Priority

fun formatPriorityHeader(p: Priority): String {
    val line = "=".repeat(20)
    return "$line\n  ${p.displayName} Priority\n$line"
}
```

Notice two things. First, the package declaration is `com.qadrlabs.catatku.display`, matching the directory. Second, since this file uses `Priority` (which is in `com.qadrlabs.catatku`), it needs an explicit import. Subpackages do not implicitly include their parent's contents.

Now in `Main.kt` (which is in `com.qadrlabs.catatku`), import the new function and use it:

```kotlin
package com.qadrlabs.catatku

import com.qadrlabs.catatku.display.formatPriorityHeader

fun main() {
    val list = EntryList()

    list.add("Pay rent", Priority.HIGH)
    list.add("Finish Kotlin course", Priority.HIGH)
    list.add("Read for fun", Priority.LOW)

    println(formatPriorityHeader(Priority.HIGH))
    for (entry in list.byPriority(Priority.HIGH)) {
        println(entry.summary)
    }
}
```

Save and run. Output:

```text
====================
  High Priority
====================
[ ] (H) 1. Pay rent
[ ] (H) 2. Finish Kotlin course
```

The `import com.qadrlabs.catatku.display.formatPriorityHeader` brings the function into scope; without the import, the compiler reports `Unresolved reference 'formatPriorityHeader'.` The parent package does not see its subpackage's contents automatically, just as the subpackage does not see the parent's.

This pattern (parent package and child subpackages) is common in real-world Kotlin projects. Each subpackage is an organizational unit that groups related code. For example, a typical project might have `domain` (data types), `service` (business logic), `infrastructure` (database, network), and `presentation` (UI or CLI) subpackages. Each one focuses on a specific concern, with imports making the dependencies between them explicit.

A subtle point about visibility: the `internal` modifier applies to the whole module, not to a subpackage. If you have a class marked `internal` in `com.qadrlabs.catatku.domain`, it is visible everywhere in the module, including in `com.qadrlabs.catatku.presentation`. To restrict visibility further, you would need to split into separate modules (separate Gradle subprojects), which is overkill for a small application like Catatku.

---

## 11. Understanding Why Packages Matter

The package system might seem like just bureaucracy at first, but it earns its keep as projects grow. Understanding why packages matter helps you organize your own code thoughtfully.

The first benefit is namespacing. As your project grows or you add libraries, name collisions become inevitable. Two libraries might both define a `Logger` class. Two parts of your application might both want a `Validator` class for different purposes. Packages give each declaration a unique fully-qualified name, so collisions are resolved automatically. The compiler does not have to choose between the two `Logger` classes; they are different classes in different packages. From the calling code, you choose which one you want via your import statements.

The second benefit is organization. A flat list of fifty class declarations is hard to navigate. The same fifty classes split across five packages with ten classes each is much easier to think about. Each package is a unit of meaning: "the domain types are here", "the parsing code is here", "the persistence code is here". When you open a project, the package structure tells you the high-level architecture before you read any code.

The third benefit is encapsulation. The `internal` and `private` modifiers, in conjunction with packages, let you control which parts of your code are exposed to external users. A library can have a public API in one package and implementation details in others. The implementation can change freely without breaking client code, because the client only sees the public API. This is the same kind of encapsulation that classes provide, but at a higher level of abstraction.

The fourth benefit is dependency management. When you write `import com.othercompany.theirlib.SomeClass`, you are explicitly declaring that your code depends on `theirlib`. This makes dependencies visible at the file level. Tools like Gradle use this information to figure out what to compile, what to bundle, and what to fetch from the network. Without packages, all dependencies would be implicit, which is much harder to reason about.

A subtle but important benefit is mental modeling. When you think about a problem in terms of named groups (domain, validation, persistence, presentation), your design becomes clearer. The decision to put a new class in this package versus that one is itself an architectural decision: "is this a domain concept or a UI concern?" Forcing yourself to answer such questions tends to produce better code than just dumping everything into one big bag.

The cost of packages is a small amount of typing (the `package` declaration at the top of each file, the `import` statements to bring things in) and the discipline of maintaining the directory structure. With IntelliJ's tooling, both costs are trivial; the IDE handles imports automatically and warns if the directory does not match the package. Without good tooling, the cost would be higher; one of the reasons IntelliJ is the recommended IDE for Kotlin is that it makes package management painless.

A final benefit worth mentioning is testability. When you have well-organized packages, writing tests is easier. Tests typically live in a parallel structure under `src/test/kotlin/`, with the same package names as the production code they test. This way, test code can access internal members of the production code (via `internal` visibility, which extends to test code in the same module) without making everything public. Lesson 21 will use this pattern when we add tests for Catatku.

---

## Next Up - Lesson 18

Packages organize Kotlin code into named groups. Every file should start with a `package` declaration that matches its directory location. Code in the same package can refer to each other directly; code in different packages needs `import` statements. Visibility modifiers (`public`, `internal`, `private`) interact with packages: `public` is everywhere, `internal` is module-wide, and `private` at the file level restricts to a single file. Catatku is now organized into five files (`Entry.kt`, `EntryList.kt`, `Errors.kt`, `Stats.kt`, `Main.kt`) all sharing the package `com.qadrlabs.catatku`, and `build.gradle.kts` points at `com.qadrlabs.catatku.MainKt`. The `EntryList` class encapsulates the mutable list of entries and exposes a clean public API of operations (add, find, mark done, cancel, remove) that return `CatatkuResult<Entry>` values. Each file has a single concern, the directory structure mirrors the package structure, and the codebase is ready to grow with more files for command-line parsing, file I/O, and JSON serialization in the next lessons.

In Lesson 18 you will add the command-line interface to Catatku: parsing `args: Array<String>` to recognize commands like `add`, `list`, `done`, `remove`, and `cancel`, dispatching to the appropriate `EntryList` methods, and reporting results or errors to the terminal.
