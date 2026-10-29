## 1. Before You Begin

The tab-separated text format from Lesson 19 works, but it has costs that show up as soon as the data shape gets even slightly more complex. We had to invent encodings for things JSON handles naturally: the `cancelled:reason` syntax for the sealed status variant, the tab-stripping when descriptions might contain tabs, and the manual line-by-line parser that has to know about every field's order. Each of these is a hand-rolled solution to a problem that data interchange formats already solved decades ago. JSON in particular has become the default for application data because it handles nested structures, escapes special characters automatically, supports null and arrays naturally, and is universally readable across languages. This lesson swaps Catatku's persistence layer to use JSON via the `kotlinx.serialization` library, which is the official Kotlin solution for converting data classes to and from JSON.

The transformation is surprisingly small. The data classes barely change; we just add a few annotations to opt them into serialization. The parser and serializer become a single `Json.encodeToString(...)` and `Json.decodeFromString<...>(...)` call each. The format becomes structurally precise (arrays of objects with named fields, polymorphic encoding for the sealed status), human-readable when pretty-printed, and machine-readable for any other tool that wants to consume it. By the end of this lesson, Catatku reads and writes a real JSON file, and you have learned the patterns that apply to almost any Kotlin application that needs persistence.

### What You'll Build

The same Catatku as Lesson 19 but with JSON persistence instead of tab-separated text. The `entries.txt` file becomes `entries.json`, the entries are stored as a JSON array of objects, and the sealed `Status` class is encoded with a discriminator field. The application's behavior is unchanged from the user's perspective; only the storage format is upgraded.

### What You'll Learn

- ✅ How to add `kotlinx.serialization` as a Gradle dependency
- ✅ How to mark types as `@Serializable` for the library to handle
- ✅ How polymorphic serialization handles sealed classes with type discriminators
- ✅ How to control field names with `@SerialName`
- ✅ How to configure a `Json` instance with options like pretty-printing and `encodeDefaults`
- ✅ How to encode and decode using `Json.encodeToString` and `Json.decodeFromString`

### What You'll Need

- The Catatku project from Lesson 19 with the multi-file structure and tab-separated persistence
- Internet access for Gradle to download the new dependency (a few megabytes)
- About forty-five minutes
- Comfort with editing `build.gradle.kts` to add dependencies and plugins

---

## 2. Adding kotlinx.serialization to the Project

The library is not part of the standard library; it is a separate library published on Maven Central. We need to add it as a dependency and enable the serialization compiler plugin, then confirm both work with a tiny test.

### Step 1: Update build.gradle.kts

Open `build.gradle.kts` at the project root. Since Lesson 17 it looks like this:

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

We need two additions: the serialization plugin in the `plugins` block, and the JSON library in the `dependencies` block. Update the file to look like this:

```kotlin
plugins {
    kotlin("jvm") version "2.0.0"
    kotlin("plugin.serialization") version "2.0.0"
    application
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")
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

The two changes are the new `kotlin("plugin.serialization") version "2.0.0"` line in `plugins` and the new `implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")` line in `dependencies`. The plugin is a compiler plugin: it generates the code that converts your classes to and from JSON. The library provides the `Json` class that runs that code. The plugin version must match your Kotlin version (the `kotlin("jvm")` version above it). Version `1.7.1` of the library is the one this course was tested with on Kotlin 2.0.0; if your project uses a newer Kotlin version, pick the library version that the kotlinx.serialization release notes list for it.

Save the file. IntelliJ shows a small "Load Gradle Changes" button (an elephant icon) in the editor; click it, or use the refresh icon in the Gradle tool window. Gradle downloads the new dependencies the next time it builds (this takes a few seconds the first time).

If you get errors about the version, check the `kotlin("jvm")` line; whatever version it specifies should match the serialization plugin version exactly. Mismatched versions are the most common source of build problems with this plugin.

### Step 2: Verify the Plugin Works

Confirm the setup with a tiny program. Replace `Main.kt` temporarily with:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Serializable
data class Hello(val message: String)

fun main() {
    val h = Hello("world")
    val json = Json.encodeToString(h)
    println(json)
}
```

The `@Serializable` annotation marks `Hello` as eligible for serialization; the compiler plugin sees it and generates a serializer for the class. `Json.encodeToString(h)` uses that serializer to produce a JSON string. The `encodeToString` import is needed because it is an extension function in the `kotlinx.serialization` package. Run it:

```bash
./gradlew run -q
```

Output:

```text
{"message":"world"}
```

The `Hello` data class was serialized to a JSON object with one field. If you see an error like `Serializer for class 'Hello' is not found.` instead, the plugin is not active; double-check the plugin line in `build.gradle.kts` (Section 8 shows this mistake in detail).

---

## 3. Annotating the Domain Types

Each type that participates in serialization needs the `@Serializable` annotation. For our types, this includes `Entry` and the `Status` sealed class with each of its variants. `Priority` is an enum, and enums are handled automatically by the library without an annotation.

### Step 1: Annotate Entry and Status

Replace `Entry.kt` with this version. The new parts are the import and the `@Serializable` annotations; the extensions at the bottom are unchanged from Lesson 17:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.Serializable

enum class Priority(val displayName: String) {
    HIGH("High"), MEDIUM("Medium"), LOW("Low");

    fun shortLabel(): String = displayName.first().toString()
}

@Serializable
sealed class Status {
    @Serializable
    object Pending : Status() { override fun toString() = "Pending" }

    @Serializable
    object InProgress : Status() { override fun toString() = "InProgress" }

    @Serializable
    object Done : Status() { override fun toString() = "Done" }

    @Serializable
    data class Cancelled(val reason: String) : Status()
}

@Serializable
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

Save. The `@Serializable` annotation appears on `Status` (the sealed class itself), on each of its variants (`Pending`, `InProgress`, `Done`, `Cancelled`), and on `Entry`. The key insight is that sealed classes need `@Serializable` on both the parent and each variant. The library uses these annotations to set up polymorphic serialization, which encodes the variant type as part of the JSON output so that decoding can pick the right variant.

### Step 2: Test Encoding an Entry

Replace `Main.kt` temporarily with an encoding test:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

fun main() {
    val pending = Entry(1, "Pay rent", Priority.HIGH)
    val cancelled = Entry(2, "Read book", Priority.LOW, Status.Cancelled("rescheduled"))

    println(Json.encodeToString(pending))
    println(Json.encodeToString(cancelled))
}
```

The first entry uses the default status and date; the second gets an explicit cancelled status. Run it with `./gradlew run -q`. Output:

```text
{"id":1,"description":"Pay rent","priority":"HIGH"}
{"id":2,"description":"Read book","priority":"LOW","status":{"type":"com.qadrlabs.catatku.Status.Cancelled","reason":"rescheduled"}}
```

Two things stand out. First, the default `Json` leaves out every property whose value equals its default: the pending entry has no `status` and no `createdAt` at all, because `Status.Pending` and `"2026-04-26"` are the defaults in the `Entry` constructor. That keeps the output small, but for a data file we would rather see every field; Section 4 changes this. Second, the cancelled `status` is encoded as a nested JSON object with a `type` discriminator, and the library uses the fully qualified class name as the type by default, which is verbose. Section 4 improves that too.

### Step 3: Test Decoding

Now the reverse direction. Replace `Main.kt` temporarily with:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.json.Json

fun main() {
    val pendingJson = """{"id":1,"description":"Pay rent","priority":"HIGH"}"""
    val cancelledJson = """{"id":2,"description":"Read book","priority":"LOW","status":{"type":"com.qadrlabs.catatku.Status.Cancelled","reason":"rescheduled"}}"""

    val pending: Entry = Json.decodeFromString(pendingJson)
    val cancelled: Entry = Json.decodeFromString(cancelledJson)

    println(pending)
    println(cancelled)
}
```

The two JSON strings are exactly the output from Step 2, written as raw strings (`"""..."""`) so the quotes inside need no escaping. The type annotation `: Entry` tells `decodeFromString` which class to build. Run it with `./gradlew run -q`. Output:

```text
Entry(id=1, description=Pay rent, priority=HIGH, status=Pending, createdAt=2026-04-26)
Entry(id=2, description=Read book, priority=LOW, status=Cancelled(reason=rescheduled), createdAt=2026-04-26)
```

The JSON strings parse back into `Entry` objects with the correct status variants. Missing properties got their default values, and the polymorphic deserialization figured out which variant of `Status` to use from the `type` field in the nested object. This is the round-trip we need: encode an entry to JSON, save it, load it later, decode it back.

---

## 4. Configuring the Json Instance

The default `Json` configuration produces minimal one-line JSON and skips default values, which is hard to read in a file. We can configure it to pretty-print, to write every field, and to be lenient about extra fields, and we can give the status variants shorter type names.

### Step 1: Use @SerialName for Cleaner Discriminators

The default discriminator value is the fully qualified class name (`com.qadrlabs.catatku.Status.Cancelled`). We can override this with `@SerialName`. Replace `Entry.kt` with:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

enum class Priority(val displayName: String) {
    HIGH("High"), MEDIUM("Medium"), LOW("Low");

    fun shortLabel(): String = displayName.first().toString()
}

@Serializable
sealed class Status {
    @Serializable
    @SerialName("pending")
    object Pending : Status() { override fun toString() = "Pending" }

    @Serializable
    @SerialName("inprogress")
    object InProgress : Status() { override fun toString() = "InProgress" }

    @Serializable
    @SerialName("done")
    object Done : Status() { override fun toString() = "Done" }

    @Serializable
    @SerialName("cancelled")
    data class Cancelled(val reason: String) : Status()
}

@Serializable
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

Save. The new import is `kotlinx.serialization.SerialName`, and each variant now carries a `@SerialName(...)` annotation. `@SerialName("pending")` overrides the discriminator value for that variant, so instead of `"type": "com.qadrlabs.catatku.Status.Pending"`, the JSON will say `"type": "pending"`. The shorter form is much cleaner and more typical of JSON APIs, and it also means you could later move or rename the Kotlin classes without breaking existing files.

### Step 2: A Configured Json Instance

`Json { ... }` creates a `Json` instance with custom settings. Replace `Main.kt` temporarily with:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

fun main() {
    val json = Json {
        prettyPrint = true
        encodeDefaults = true
        ignoreUnknownKeys = true
    }

    val entry = Entry(1, "Pay rent", Priority.HIGH, Status.Cancelled("rescheduled"))
    println(json.encodeToString(entry))
}
```

Inside the block, we set three options. `prettyPrint = true` makes the output use indentation and newlines for readability. `encodeDefaults = true` writes every property, including the ones that still have their default value, so the file always shows the complete data. `ignoreUnknownKeys = true` makes the parser tolerate fields in the JSON that are not in our data class, which is useful for forward compatibility when reading files written by a newer version of the program. Note that we call `encodeToString` on our own `json` value now, not on the default `Json`.

Run it with `./gradlew run -q`. Output:

```text
{
    "id": 1,
    "description": "Pay rent",
    "priority": "HIGH",
    "status": {
        "type": "cancelled",
        "reason": "rescheduled"
    },
    "createdAt": "2026-04-26"
}
```

The pretty-printing produces multi-line output with indentation, the type discriminator is `"cancelled"` instead of the fully qualified name, and `createdAt` appears even though it has its default value. This is what we want for the on-disk format.

---

## 5. Replacing the Tab-Separated Storage

Now we replace the tab-separated logic from Lesson 19 with JSON serialization. The functions get much shorter.

### Step 1: Rewrite Storage.kt

Replace the entire contents of `Storage.kt`:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.SerializationException
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption

private val json = Json {
    prettyPrint = true
    encodeDefaults = true
    ignoreUnknownKeys = true
}

fun loadEntries(file: File): CatatkuResult<List<Entry>> {
    if (!file.exists()) {
        return CatatkuResult.Ok(emptyList())  // first run
    }

    val content = try {
        file.readText()
    } catch (e: Exception) {
        return CatatkuResult.Err(CatatkuError.IoError("failed to read ${file.path}: ${e.message}"))
    }

    if (content.isBlank()) {
        return CatatkuResult.Ok(emptyList())
    }

    return try {
        val entries: List<Entry> = json.decodeFromString(content)
        CatatkuResult.Ok(entries)
    } catch (e: SerializationException) {
        CatatkuResult.Err(CatatkuError.ParseError("invalid JSON in ${file.name}: ${e.message}"))
    } catch (e: IllegalArgumentException) {
        CatatkuResult.Err(CatatkuError.ParseError("unexpected data in ${file.name}: ${e.message}"))
    }
}

fun saveEntries(file: File, entries: List<Entry>): CatatkuResult<Unit> {
    val content = json.encodeToString(entries)

    return try {
        // Atomic write: write to a temporary file, then move it over the real file
        val tempFile = File(file.parentFile ?: File("."), "${file.name}.tmp")
        tempFile.writeText(content)
        Files.move(
            tempFile.toPath(),
            file.toPath(),
            StandardCopyOption.REPLACE_EXISTING,
            StandardCopyOption.ATOMIC_MOVE
        )
        CatatkuResult.Ok(Unit)
    } catch (e: Exception) {
        CatatkuResult.Err(CatatkuError.IoError("failed to write ${file.path}: ${e.message}"))
    }
}
```

Save. The file is dramatically shorter than the Lesson 19 version. The custom serializer (`entryToLine`, `serializeEntries`) and parser (`lineToEntry`, `parseStatus`, `parseEntries`) are gone. They are replaced by `json.encodeToString(entries)` for serialization and `json.decodeFromString(content)` for parsing, using the configured `private val json` from Section 4. The library handles all the field-by-field encoding, escaping, polymorphism, and parsing. Because `entries` is a `List<Entry>`, the file holds a JSON array of entry objects.

The error handling stays the same: `CatatkuError.IoError` for file-system problems, `CatatkuError.ParseError` for bad content. The new piece is catching `SerializationException`, which is what the library throws for malformed JSON or values that do not fit the data class. The `IllegalArgumentException` catch covers the rarer case of data that decodes but fails a check while building the objects. A blank file is treated like a missing one. The atomic-write pattern is unchanged from Lesson 19.

### Step 2: Update the File Path

The file now contains JSON, so give it a `.json` extension. Restore the Lesson 19 version of `Main.kt` (the one with `entriesFile()` and the load/save logic) and replace its `entriesFile` function with:

```kotlin
private fun entriesFile(): File {
    val home = System.getProperty("user.home")
    val dir = File(home, ".catatku")
    if (!dir.exists()) {
        dir.mkdirs()
    }
    return File(dir, "entries.json")
}
```

Save. The only change is the file name at the end: the path is now `~/.catatku/entries.json`. If you have an existing tab-separated `entries.txt` from Lesson 19, you can either delete it (Catatku will start fresh) or keep it as a record; the new code never reads it. We will not write a migration script because the data format change is a one-time event.

### Step 3: Run the Application

Delete any old entries file so you start fresh (`rm ~/.catatku/entries.txt` on macOS or Linux, if it is still there), rebuild the launcher, and add an entry:

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku add "Pay rent"
```

Output:

```text
Added entry 1: Pay rent
```

Inspect the file:

```bash
cat ~/.catatku/entries.json
```

Output:

```text
[
    {
        "id": 1,
        "description": "Pay rent",
        "priority": "MEDIUM",
        "status": {
            "type": "pending"
        },
        "createdAt": "2026-04-26"
    }
]
```

The file is JSON, pretty-printed, with the entry encoded as an object inside an array. The `status` is a nested object with the `type` discriminator. Now mark it done:

```bash
build/install/catatku/bin/catatku done 1
```

Output:

```text
Marked entry 1 as done.
```

`cat ~/.catatku/entries.json` now shows the new status:

```text
[
    {
        "id": 1,
        "description": "Pay rent",
        "priority": "MEDIUM",
        "status": {
            "type": "done"
        },
        "createdAt": "2026-04-26"
    }
]
```

Finally, cancel it with a reason:

```bash
build/install/catatku/bin/catatku cancel 1 "test"
```

Output:

```text
Cancelled entry 1: test
```

And the file:

```text
[
    {
        "id": 1,
        "description": "Pay rent",
        "priority": "MEDIUM",
        "status": {
            "type": "cancelled",
            "reason": "test"
        },
        "createdAt": "2026-04-26"
    }
]
```

The cancellation reason is encoded as an additional field in the status object, which is the natural shape for sealed-class variants with data. Compared to our hand-rolled `cancelled:reason` format from Lesson 19, this is much cleaner: the structure is explicit, and the parser does not have to know any special syntax.

---

## 6. Run and Test

The full Catatku with JSON persistence is the same application from the user's perspective; only the format on disk has changed. Test it thoroughly to verify the round-trip works.

### Step 1: A Realistic Test Sequence

Delete the entries file to start fresh (`rm ~/.catatku/entries.json`), then run a sequence of commands:

```bash
build/install/catatku/bin/catatku add "Pay rent"
build/install/catatku/bin/catatku add "Buy groceries"
build/install/catatku/bin/catatku done 1
build/install/catatku/bin/catatku cancel 2 "rescheduled"
build/install/catatku/bin/catatku list
```

Output:

```text
Added entry 1: Pay rent
Added entry 2: Buy groceries
Marked entry 1 as done.
Cancelled entry 2: rescheduled
[x] (M) 1. Pay rent
[!] (M) 2. Buy groceries

0 active out of 2 total
```

Each command is a separate run, so the final `list` proves the data persisted. Examine the file with `cat ~/.catatku/entries.json`:

```text
[
    {
        "id": 1,
        "description": "Pay rent",
        "priority": "MEDIUM",
        "status": {
            "type": "done"
        },
        "createdAt": "2026-04-26"
    },
    {
        "id": 2,
        "description": "Buy groceries",
        "priority": "MEDIUM",
        "status": {
            "type": "cancelled",
            "reason": "rescheduled"
        },
        "createdAt": "2026-04-26"
    }
]
```

The content is a JSON array of two objects, with entry 1 marked `"done"` and entry 2 marked `"cancelled"` with `"reason": "rescheduled"`.

### Step 2: Special Characters

The tab-separated format had to replace tabs with spaces. JSON escapes special characters instead. Add an entry whose description contains double quotes, wrapping the argument in single quotes so the shell keeps the inner double quotes:

```bash
build/install/catatku/bin/catatku add 'Read "Kotlin in Action"'
build/install/catatku/bin/catatku list
```

Output:

```text
Added entry 3: Read "Kotlin in Action"
[x] (M) 1. Pay rent
[!] (M) 2. Buy groceries
[ ] (M) 3. Read "Kotlin in Action"

1 active out of 3 total
```

In the file, the description is stored as `"description": "Read \"Kotlin in Action\""`. The `\"` is JSON's escape for a literal double quote inside a string. The library encodes it on write and decodes it on read, so the round-trip preserves the original characters exactly.

### Step 3: Hand-Edit the JSON File

Open `~/.catatku/entries.json` in a text editor, change the description `"Buy groceries"` to `"Buy groceries and fruit"`, save, and list again:

```bash
build/install/catatku/bin/catatku list
```

Output:

```text
[x] (M) 1. Pay rent
[!] (M) 2. Buy groceries and fruit
[ ] (M) 3. Read "Kotlin in Action"

1 active out of 3 total
```

The file is genuinely human-editable; you can fix bad data manually if you ever need to. Now introduce a syntax error: delete the final `]` at the end of the file, save, and run `list` again. Output:

```text
Error loading entries: Parse error: invalid JSON in entries.json: Expected end of the array ']', but had 'EOF' instead at path: $
JSON input: [
    {
        "id": 1,
   .....
```

The application exits with code 1, and the message comes from the serialization library: it says what it expected (`]`), what it found (the end of the file), and shows the start of the input. Put the `]` back. Then try a value error instead: change the first `"priority": "MEDIUM"` to `"priority": "URGENT"` and run `list`:

```text
Error loading entries: Parse error: invalid JSON in entries.json: com.qadrlabs.catatku.Priority does not contain element with name 'URGENT' at path $[0].priority
```

The path `$[0].priority` points straight at the `priority` field of the first array element. Change it back to `"MEDIUM"`. This kind of specific, actionable error is a real benefit of using a proper serialization library instead of a hand-written parser.

---

## 7. The Benefits of JSON Over a Hand-Rolled Format

The format change might seem cosmetic, but it solves several problems that the tab-separated format had. This section summarizes them.

### Special Characters Are Handled Automatically

JSON automatically escapes special characters in string values. A description containing a tab, a quote, a newline, or any other tricky character is encoded with escape sequences such as `\t`, `\"`, or `\n`, and decoded back exactly. We do not need our `replace("\t", " ")` workaround anymore; the library handles all of it, as the quote test in Section 6 showed.

### Structure Is Explicit

The status field is now a nested object, not a tagged string. Adding a new field to a status variant is a one-line change to the data class: for example, giving `Cancelled` a second property `val date: String` makes the JSON gain a `"date"` field next to `"reason"`, with no parser code to update. Compare that to the tab-separated format, where `cancelled:reason` would need to become `cancelled:reason:date` or some other ad-hoc encoding that you would have to teach the parser.

### Forward Compatibility

The `ignoreUnknownKeys = true` option lets the parser tolerate fields it does not recognize. This means old versions of Catatku can read files written by newer versions, ignoring fields they do not understand. This is forward compatibility, and it is much harder to achieve with hand-rolled formats.

Suppose a later version of Catatku adds a `tags: List<String>` field to `Entry`. With the hand-rolled format, an older version would reject every line because it would have six fields instead of five. With JSON and `ignoreUnknownKeys`, the older parser silently ignores the unknown field and reads everything else correctly. Exercise 1 explores the opposite direction: a newer version reading older files.

### Tooling Compatibility

JSON is universally supported. Other tools can read your entries file: a script written in Python, a web dashboard written in JavaScript, a command-line tool like `jq`. For Catatku this matters because someone might want to write integrations or migrate data; JSON is the format every tool understands.

For comparison, a hand-rolled tab-separated format with custom encoding for sealed classes would be readable only by code that knows our specific conventions. By using JSON, we tap into a vast ecosystem of tools and libraries.

---

## 8. Fix the Errors in Your Code

Three serialization-related mistakes are common. Each one compiles without complaint and fails only when the program runs.

**Error 1: Forgetting @Serializable on a class**

```kotlin
// Wrong
data class Note(val text: String)

// Correct
@Serializable
data class Note(val text: String)
```

Calling `Json.encodeToString(Note("hello"))` on the wrong version crashes with `kotlinx.serialization.SerializationException: Serializer for class 'Note' is not found.` and a hint to mark the class as `@Serializable`. Every class involved in serialization must have the annotation; without it, the compiler plugin does not generate the serializer code. As a habit, when you add a new data class that will be saved or loaded, immediately mark it `@Serializable`.

**Error 2: Missing @Serializable on a sealed class variant**

```kotlin
// Wrong
@Serializable
sealed class Event {
    object Created : Event()

    @Serializable
    data class Updated(val newValue: String) : Event()
}

// Correct
@Serializable
sealed class Event {
    @Serializable
    object Created : Event()

    @Serializable
    data class Updated(val newValue: String) : Event()
}
```

Encoding a `List<Event>` that contains `Event.Created` with the wrong version fails with `Serializer for subclass 'Created' is not found in the polymorphic scope of 'Event'.` The error even explains that the class has to be `@Serializable` and the base class has to be sealed and `@Serializable`. Each variant needs its own annotation, in addition to the parent class. As a habit, when defining a sealed class for serialization, treat the parent and each variant as separate annotation targets.

**Error 3: Adding the library but not the plugin**

```kotlin
// Wrong (build.gradle.kts)
plugins {
    kotlin("jvm") version "2.0.0"
    application
}

// Correct
plugins {
    kotlin("jvm") version "2.0.0"
    kotlin("plugin.serialization") version "2.0.0"
    application
}
```

With only the library in `dependencies`, the `@Serializable` annotation is available, so the code compiles, but nothing generates the serializers. The `Hello` test from Section 2 then fails with `Serializer for class 'Hello' is not found.`, the same message as Error 1 even though the class is annotated. The fix is to add the plugin line and reload Gradle. As a habit, when you add the serialization library, make sure you also add the plugin; both are required.

---

## 9. Exercises

These exercises practice serialization.

**Exercise 1:** Add a new field to `Entry`: `val tags: List<String> = emptyList()`. Verify the field roundtrips correctly through JSON encoding and decoding. Notice that older entries without the field still load correctly because the default value handles missing fields.

**Exercise 2:** Define a `data class AppMetadata(val version: String, val createdAt: String)` annotated with `@Serializable`. Write a function `saveAppMetadata(file: File, metadata: AppMetadata)` and a matching `loadAppMetadata`. Use this to store a simple application metadata file.

**Exercise 3:** Create a JSON file by hand that contains a list of three entries you make up. Put it at `~/.catatku/entries.json`, run Catatku, and verify it reads them correctly. This tests that hand-written JSON also works, not just JSON produced by Kotlin's encoder.

---

## 10. Solutions

Try the exercises yourself first, then check the solutions below. When you are done, return `Entry.kt` and `Main.kt` to the versions from Sections 4 and 5, because Lesson 21 starts from them.

**Solution for Exercise 1:**

In `Entry.kt`, add the new property at the end of the `Entry` constructor:

```kotlin
@Serializable
data class Entry(
    val id: Int,
    val description: String,
    val priority: Priority = Priority.MEDIUM,
    val status: Status = Status.Pending,
    val createdAt: String = "2026-04-26",
    val tags: List<String> = emptyList()
)
```

The new `tags` field has a default of `emptyList()`. This is important: when loading a JSON file written before this change, the field is missing from every object, and the default fills it in, so old files load correctly. Rebuild and run any state-modifying command:

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku add "Renew passport"
```

Output:

```text
Added entry 4: Renew passport
```

Look at the file with `cat ~/.catatku/entries.json`. The old entries were loaded without `tags` and saved again, so now every object, old and new, ends with `"tags": []`. To check both directions of the round-trip in isolation, replace `Main.kt` temporarily with:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.json.Json

fun main() {
    val oldJson = """{"id":1,"description":"Pay rent","priority":"HIGH","status":{"type":"pending"},"createdAt":"2026-04-26"}"""
    val newJson = """{"id":2,"description":"Pay bills","priority":"HIGH","status":{"type":"pending"},"createdAt":"2026-04-26","tags":["bills","monthly"]}"""

    val old: Entry = Json.decodeFromString(oldJson)
    val new: Entry = Json.decodeFromString(newJson)

    println("${old.description}: ${old.tags}")
    println("${new.description}: ${new.tags}")
}
```

The first string is an entry in the old format with no `tags` field; the second includes tags. Run it with `./gradlew run -q`. Output:

```text
Pay rent: []
Pay bills: [bills, monthly]
```

The old entry decoded with the default empty list, and the new one kept its tags. Small format changes are non-breaking when defaults are provided.

**Solution for Exercise 2:**

Create `src/main/kotlin/com/qadrlabs/catatku/Metadata.kt`:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

@Serializable
data class AppMetadata(val version: String, val createdAt: String)

private val metadataJson = Json { prettyPrint = true }

fun saveAppMetadata(file: File, metadata: AppMetadata): CatatkuResult<Unit> {
    return try {
        file.writeText(metadataJson.encodeToString(metadata))
        CatatkuResult.Ok(Unit)
    } catch (e: Exception) {
        CatatkuResult.Err(CatatkuError.IoError("failed to write ${file.name}: ${e.message}"))
    }
}

fun loadAppMetadata(file: File): CatatkuResult<AppMetadata?> {
    if (!file.exists()) {
        return CatatkuResult.Ok(null)
    }
    return try {
        CatatkuResult.Ok(metadataJson.decodeFromString<AppMetadata>(file.readText()))
    } catch (e: SerializationException) {
        CatatkuResult.Err(CatatkuError.ParseError("invalid JSON in ${file.name}: ${e.message}"))
    }
}
```

`AppMetadata` is a plain `@Serializable` data class. `saveAppMetadata` writes it as pretty-printed JSON and converts any I/O exception into an `IoError`. `loadAppMetadata` returns `Ok(null)` when the file does not exist yet, decodes it otherwise, and turns a `SerializationException` into a `ParseError`. The explicit type argument in `decodeFromString<AppMetadata>(...)` tells the library which class to build, because there is no variable type annotation to infer it from. Test it with a temporary `Main.kt`:

```kotlin
package com.qadrlabs.catatku

import java.io.File

fun main() {
    val file = File("metadata.json")

    when (val saved = saveAppMetadata(file, AppMetadata("0.1.0", "2026-04-26"))) {
        is CatatkuResult.Ok -> println("Saved ${file.name}")
        is CatatkuResult.Err -> println("Error: ${saved.error.describe()}")
    }

    when (val loaded = loadAppMetadata(file)) {
        is CatatkuResult.Ok -> println("Loaded: ${loaded.value}")
        is CatatkuResult.Err -> println("Error: ${loaded.error.describe()}")
    }
}
```

Run it with `./gradlew run -q`. Output:

```text
Saved metadata.json
Loaded: AppMetadata(version=0.1.0, createdAt=2026-04-26)
```

The file `metadata.json` in the project folder contains the two fields as a small JSON object. Delete it, and delete `Metadata.kt` too unless you want to keep the feature.

**Solution for Exercise 3:**

Write this file by hand and save it as `~/.catatku/entries.json` (back up your real entries first if you want to keep them):

```json
[
    {
        "id": 1,
        "description": "Book dentist appointment",
        "priority": "HIGH",
        "status": { "type": "pending" },
        "createdAt": "2026-05-01"
    },
    {
        "id": 2,
        "description": "Return library books",
        "priority": "LOW",
        "status": { "type": "done" },
        "createdAt": "2026-05-02"
    },
    {
        "id": 3,
        "description": "Plan weekend trip",
        "status": { "type": "cancelled", "reason": "too busy" },
        "createdAt": "2026-05-03"
    }
]
```

The third entry leaves out `priority` on purpose: the default `MEDIUM` fills it in, just like a missing `tags` field in Exercise 1. The `status` objects are written on one line each; JSON does not care about whitespace. Now list the entries and add one more:

```bash
build/install/catatku/bin/catatku list
build/install/catatku/bin/catatku add "Buy sunscreen"
```

Output:

```text
[ ] (H) 1. Book dentist appointment
[x] (L) 2. Return library books
[!] (M) 3. Plan weekend trip

1 active out of 3 total
Added entry 4: Buy sunscreen
```

Catatku read all three hand-written entries, including the cancelled one with its reason, and the next id continued at 4. After the `add`, the file is rewritten in Catatku's own pretty-printed style, with the missing `priority` now written out explicitly.

---

## 11. Understanding Why kotlinx.serialization Matters

The library does an enormous amount of work for you, and understanding what it provides helps you appreciate why this kind of tool is essential for real applications.

The first thing the library provides is correctness. Hand-written serializers are notorious for bugs: forgetting to escape quotes, getting the order of fields wrong, mishandling nested structures, breaking when fields are missing. The library handles all of these consistently because it is generated from the data class declaration; the compiler ensures the serializer matches the structure.

The second thing is performance. The library generates compact, efficient serializer code at compile time. Hand-written serialization either uses reflection (slow) or is verbose and error-prone (fast but ugly). The library gives you both: declarative syntax through annotations, with generated code that is as fast as hand-written.

The third thing is feature richness. The library supports many JSON features beyond what we covered: custom serializers for unusual types, conditional serialization based on predicates, alternative encoding formats (`Cbor`, `Protobuf`, etc.), schema generation, and more. We use only the most common features, but the rest are there when needed.

The fourth thing is type safety. The library uses Kotlin's type system at every step. The compiler knows the types being encoded and decoded, the type-check-then-cast pattern works, and there is no need for unchecked casts or manual `Any` handling. This is in contrast to many older serialization libraries that use reflection or type-erased structures.

The fifth thing is integration with Kotlin features. Sealed classes, data classes, default values, nullable types, generic types, all work with `kotlinx.serialization` directly. You do not have to twist your data classes into a different shape to make them serializable; you annotate them and they work.

The cost of using the library is the additional dependency and a small amount of compile-time overhead. Both costs are negligible for most projects. The benefit is that you stop hand-rolling serializers and parsers, which removes a whole class of bugs and saves significant development time.

For Catatku, the savings are visible in the line count: Lesson 19's hand-rolled `Storage.kt` was about 115 lines, while Lesson 20's library-based version is under 60, and most of what remains is error handling and the atomic write. The functionality is the same, the format is more robust, and the code is dramatically easier to maintain.

A more philosophical takeaway is that good libraries change what kinds of code you write. Without `kotlinx.serialization`, you would put off writing persistence until late in development, because the cost of correctness was high. With the library, persistence is one of the easiest parts of building an application; you add `@Serializable` and the rest is automatic. This shifts the development experience: features that depend on persistence become easier to add, and the application benefits from data preservation from day one.

---

## Next Up - Lesson 21

Catatku now uses JSON for persistence via the `kotlinx.serialization` library. The build configuration was updated to include the serialization plugin and the JSON library dependency. The data classes (`Entry`, the sealed `Status` and its variants) gained `@Serializable` annotations, with `@SerialName` providing clean discriminator values. The `Storage.kt` file is much shorter than its Lesson 19 counterpart because `Json.encodeToString` and `Json.decodeFromString` replace the hand-rolled serializer and parser. The on-disk format is a JSON array of entry objects, with the sealed status encoded as a nested object with a `type` discriminator. Pretty-printing makes the file human-readable, `encodeDefaults` writes every field, and `ignoreUnknownKeys` provides forward compatibility for new fields. The application's external behavior is unchanged from the user's perspective; only the format on disk is different.

In Lesson 21 you will add tests using `kotlin.test`. Tests are written as functions annotated with `@Test`, organized into test classes mirroring the production code, and run with `./gradlew test`. We will write tests for the domain types, the `EntryList` operations, the JSON round-trip, and a few of the parsing helpers. By the end Catatku has a small but useful test suite that catches regressions before they reach the user.
