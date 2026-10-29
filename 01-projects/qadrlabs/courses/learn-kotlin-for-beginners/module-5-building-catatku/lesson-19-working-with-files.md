## 1. Before You Begin

Catatku works as a CLI tool now, but each run starts from scratch. The user adds entries, marks them done, lists them, and as soon as the program exits, everything is gone. The next run begins with an empty list again, which is not what anyone wants from an entry tracker. Persistence is the missing piece, and this lesson adds it. We will use Kotlin's standard library wrappers around `java.io.File` to read and write text files, picking a simple tab-separated format for now. Lesson 20 will replace this format with JSON, but the file I/O patterns from this lesson stay the same: open, read or write, handle errors, save atomically when possible.

This lesson focuses on three concerns that come up whenever you persist data. The first is finding the right place to put the file: a fixed path, a path in the user's home directory, or a path the user specified. The second is reading data when the program starts, including the case where the file does not yet exist (first run or fresh machine). The third is writing data when the program changes state, ideally in a way that does not lose the existing data if something goes wrong mid-write. Together these patterns give Catatku reliable persistence. All file errors flow through `CatatkuError.IoError` and `CatatkuError.ParseError` into the existing `CatatkuResult` machinery from Lesson 16. By the end of this lesson, your entries from one run will still be there next time.

### What You'll Build

A new file `Storage.kt` in the `com.qadrlabs.catatku` package containing functions to load entries from a file and save entries to a file. The `Main.kt` will be updated to load entries at startup, run the requested command, and save entries when the command modified state. The pre-populated test data from Lesson 18 will be removed because real persistence replaces it. By the end the application persists its state across runs, and the file format is one we can swap out for JSON in the next lesson.

### What You'll Learn

- ✅ How to read and write text files via `java.io.File` and Kotlin extensions
- ✅ How to design a simple line-based serialization format
- ✅ How to handle "file does not exist" as a normal case via `File.exists()`
- ✅ How to perform atomic writes using a temporary file plus an atomic move
- ✅ How file errors flow through `CatatkuError` for consistent handling

### What You'll Need

- The Catatku project from Lesson 18 with the multi-file structure
- About forty-five minutes
- Familiarity with `CatatkuResult` and the existing handlers from Lesson 18
- Understanding that this lesson's tab-separated format is a stepping stone toward JSON in Lesson 20

---

## 2. Reading and Writing Files

The `java.io.File` class is the workhorse of file I/O on the JVM. Kotlin adds extension functions like `readText` and `writeText` that make common operations one-liners. Before building the real persistence, try them in a few small experiments. Each experiment temporarily replaces the contents of `Main.kt`; the other files stay untouched, and you will restore the Lesson 18 `Main.kt` at the end of this section. Run the experiments with `./gradlew run -q`, which runs the program from the project folder, so the demo file is created there.

### Step 1: Read a File

Replace `Main.kt` with this small experiment:

```kotlin
package com.qadrlabs.catatku

import java.io.File

fun main() {
    val file = File("catatku-demo.txt")
    if (file.exists()) {
        val content = file.readText()
        println("File content:")
        println(content)
    } else {
        println("File does not exist: ${file.name}")
    }
}
```

The expression `File("catatku-demo.txt")` creates a `File` object representing a path. The path is relative, so it points into the folder the program runs from. The path does not have to exist yet; the object is just a handle. The `exists()` method checks whether the path corresponds to a real file on disk. The `readText()` extension reads the entire file content into a `String` (using the default UTF-8 encoding).

Run it:

```bash
./gradlew run -q
```

The first time, the file does not exist. Output:

```text
File does not exist: catatku-demo.txt
```

### Step 2: Write a File

Now replace `Main.kt` with a program that writes something to the file:

```kotlin
package com.qadrlabs.catatku

import java.io.File

fun main() {
    val file = File("catatku-demo.txt")
    val content = "Hello from Catatku!\nThis is the second line."
    file.writeText(content)
    println("Wrote ${content.length} characters to ${file.name}")
}
```

The `writeText(content)` extension writes the string to the file, creating the file if it does not exist or overwriting it if it does. The default encoding is UTF-8. Run it with `./gradlew run -q`. Output:

```text
Wrote 44 characters to catatku-demo.txt
```

The 44 characters include the `\n` between the two lines, which counts as one character. Now put the Step 1 program back into `Main.kt` and run it again. The file exists this time, so the output shows the content we wrote:

```text
File content:
Hello from Catatku!
This is the second line.
```

The two extensions, `readText` and `writeText`, handle the most common cases of file I/O in one line each. They are part of `kotlin.io`, and they work for any text file that fits comfortably in memory. For very large files you would use streaming approaches, but for Catatku's modest entry list, full-file read and write are fine.

### Step 3: A Few More File Operations

Other useful members of `File` describe the file without reading it. Replace `Main.kt` with:

```kotlin
package com.qadrlabs.catatku

import java.io.File

fun main() {
    val file = File("catatku-demo.txt")
    println("Name: ${file.name}")
    println("Exists: ${file.exists()}")
    if (file.exists()) {
        println("Size: ${file.length()} bytes")
        println("Is file: ${file.isFile}")
        println("Is directory: ${file.isDirectory}")
    }
}
```

Run it with `./gradlew run -q`. Output:

```text
Name: catatku-demo.txt
Exists: true
Size: 44 bytes
Is file: true
Is directory: false
```

Each member does what its name suggests. `name` is the file name without directory. `length()` returns the size in bytes; it matches the character count here because every character in the text is plain ASCII, which UTF-8 stores in one byte. `isFile` and `isDirectory` distinguish between regular files and directories. Two more you will meet often are `absolutePath`, the full path on your machine, and `lastModified()`, a timestamp in milliseconds.

Catatku just reads the entire file at startup and writes the entire file when it changes. Delete `catatku-demo.txt` from the project folder and restore the Lesson 18 version of `Main.kt` (the one with the pre-populated entries); the rest of this lesson builds the real persistence.

---

## 3. Designing the File Format

For Lesson 19, we will use a simple tab-separated text format. Each line represents one entry. Fields are separated by tabs (the `\t` character). The fields are: id, description, priority, status, createdAt. Sealed-class statuses with data (like `Cancelled`) need a sub-format to encode the reason; we use `cancelled:reason here` as the status value.

This format is a stopgap. Lesson 20 will replace it with JSON, which handles structure naturally without our hand-rolled encoding. But seeing how to design a custom format teaches you how serialization works at a low level, which is useful even when you switch to a structured format like JSON.

### Step 1: Define the Format Rules

The file format rules are:

- One entry per line, fields separated by tab characters.
- Fields in order: id, description, priority, status, createdAt.
- Empty lines and lines starting with `#` are comments and ignored.
- The status field is one of: `pending`, `inprogress`, `done`, `cancelled:<reason>`.
- The priority field is one of: `HIGH`, `MEDIUM`, `LOW`.
- The description and cancellation reason cannot contain tabs (we replace tabs with spaces when writing).

A sample file might look like this (the gaps between fields are single tab characters):

```text
# Catatku entries (tab-separated)
1	Pay rent	HIGH	pending	2026-04-26
2	Read for fun	LOW	done	2026-04-26
3	Call dentist	MEDIUM	cancelled:rescheduled	2026-04-26
```

This is human-readable, simple to parse, and good enough for now.

### Step 2: Write the Serializer

Create `src/main/kotlin/com/qadrlabs/catatku/Storage.kt` with the serialization functions:

```kotlin
package com.qadrlabs.catatku

import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption

private const val FILE_HEADER = "# Catatku entries (tab-separated)"

fun entryToLine(entry: Entry): String {
    val statusField = when (val s = entry.status) {
        is Status.Pending -> "pending"
        is Status.InProgress -> "inprogress"
        is Status.Done -> "done"
        is Status.Cancelled -> "cancelled:${s.reason.replace("\t", " ")}"
    }
    val priorityField = entry.priority.name  // HIGH, MEDIUM, LOW
    val safeDescription = entry.description.replace("\t", " ")
    return "${entry.id}\t$safeDescription\t$priorityField\t$statusField\t${entry.createdAt}"
}

fun serializeEntries(entries: List<Entry>): String {
    val lines = listOf(FILE_HEADER) + entries.map { entryToLine(it) }
    return lines.joinToString("\n")
}
```

Save. The imports at the top cover everything `Storage.kt` will need by the end of this lesson: `File` for paths, and `Files` plus `StandardCopyOption` from the newer `java.nio.file` API for the safe save in Section 4.

The function `entryToLine(entry)` produces one tab-separated line for an entry. The status field uses a `when` over the sealed `Status` class to convert each variant to its string form. The `Status.Cancelled` case includes the reason; we replace any tabs in the reason with spaces to keep the format intact. The same protective replacement is applied to the description. `entry.priority.name` gives the enum constant's name exactly as declared (`HIGH`, `MEDIUM`, or `LOW`).

The function `serializeEntries(entries)` builds the full file content: a header line followed by one line per entry, joined with newlines. The header is a comment line (`# ...`) that the parser will skip; it is just for human readers who open the file. `FILE_HEADER` is a `private const val`, so it is a compile-time constant visible only inside `Storage.kt`.

### Step 3: Write the Parser

Now add the matching parser functions to `Storage.kt`, below `serializeEntries`:

```kotlin
fun lineToEntry(line: String): CatatkuResult<Entry> {
    val parts = line.split("\t")
    if (parts.size != 5) {
        return CatatkuResult.Err(CatatkuError.ParseError(
            "expected 5 fields separated by tabs, got ${parts.size}: '$line'"
        ))
    }

    val id = parts[0].toIntOrNull()
        ?: return CatatkuResult.Err(CatatkuError.ParseError("invalid id: '${parts[0]}'"))

    val description = parts[1]

    val priority = try {
        Priority.valueOf(parts[2])
    } catch (e: IllegalArgumentException) {
        return CatatkuResult.Err(CatatkuError.ParseError("unknown priority: '${parts[2]}'"))
    }

    val status = parseStatus(parts[3])
        ?: return CatatkuResult.Err(CatatkuError.ParseError("unknown status: '${parts[3]}'"))

    val createdAt = parts[4]

    return CatatkuResult.Ok(Entry(id, description, priority, status, createdAt))
}

private fun parseStatus(s: String): Status? = when {
    s == "pending" -> Status.Pending
    s == "inprogress" -> Status.InProgress
    s == "done" -> Status.Done
    s.startsWith("cancelled:") -> Status.Cancelled(s.removePrefix("cancelled:"))
    else -> null
}

fun parseEntries(content: String): CatatkuResult<List<Entry>> {
    val entries = mutableListOf<Entry>()

    for ((lineNumber, line) in content.lines().withIndex()) {
        val trimmed = line.trim()
        if (trimmed.isEmpty() || trimmed.startsWith("#")) {
            continue  // skip blank lines and comments
        }

        when (val result = lineToEntry(trimmed)) {
            is CatatkuResult.Ok -> entries.add(result.value)
            is CatatkuResult.Err -> {
                val detail = when (val e = result.error) {
                    is CatatkuError.ParseError -> e.message
                    else -> e.describe()
                }
                return CatatkuResult.Err(CatatkuError.ParseError("line ${lineNumber + 1}: $detail"))
            }
        }
    }

    return CatatkuResult.Ok(entries)
}
```

Save. The functions form a small parser:

`lineToEntry(line)` parses a single line into an `Entry`. It splits on tabs, checks the field count, parses the id with `toIntOrNull`, looks up the priority enum with `valueOf`, parses the status with the helper `parseStatus`, and assembles the entry. Any failure produces a `CatatkuResult.Err` with a descriptive `ParseError`.

`parseStatus(s)` returns the matching `Status` variant or null if the string is unrecognized. The cancellation case uses `startsWith("cancelled:")` and strips the prefix to get the reason. It is `private` because nothing outside this file needs it.

`parseEntries(content)` is the top-level parser for the whole file. It iterates over lines, skipping blanks and comments, and parses each remaining line. If any line fails to parse, the function returns an `Err` whose message starts with the line number, which makes a damaged file easy to diagnose.

The `Priority.valueOf` call uses the auto-generated `valueOf` function on enums, which converts a string to the corresponding constant or throws `IllegalArgumentException` if no match. We wrap it in a `try`/`catch` to convert the exception into a `ParseError`. This is the bridge between Java's exception-based API and our `CatatkuResult`-based error handling.

---

## 4. Loading and Saving from Disk

With the serializer and parser in place, we can read and write files in terms of `Entry` lists. Two more functions wrap the file I/O, `EntryList` needs one small addition, and then `Main.kt` ties it together.

### Step 1: Add loadEntries and saveEntries

Add these functions to the end of `Storage.kt`:

```kotlin
fun loadEntries(file: File): CatatkuResult<List<Entry>> {
    if (!file.exists()) {
        return CatatkuResult.Ok(emptyList())  // first run
    }

    val content = try {
        file.readText()
    } catch (e: Exception) {
        return CatatkuResult.Err(CatatkuError.IoError("failed to read ${file.path}: ${e.message}"))
    }

    return parseEntries(content)
}

fun saveEntries(file: File, entries: List<Entry>): CatatkuResult<Unit> {
    val content = serializeEntries(entries)

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

Save. The `loadEntries(file)` function returns a `CatatkuResult<List<Entry>>`. If the file does not exist, this is the first run and we return an empty list. Otherwise, we read the file (catching any I/O exception and converting it to `IoError`) and parse the content.

The `saveEntries(file, entries)` function writes the entries to the file using the temporary-file pattern. We write the serialized content to a temporary file with a `.tmp` extension next to the real one, then `Files.move` moves it over the real file. `REPLACE_EXISTING` allows the move to overwrite an existing `entries.txt`, and `ATOMIC_MOVE` asks the operating system to do the switch as one indivisible step. If the program is interrupted while writing the temporary file, the original file is untouched; once the move happens, the new content fully replaces the old. At no point does a half-written `entries.txt` exist.

The `Unit` type as the `Ok` value's payload signals "the operation succeeded but produces no useful value". This is the closest equivalent to "void" in C-style languages.

### Step 2: Add addPreserveId to EntryList

When entries are loaded from the file, they already have ids. The existing `add` method always generates a new id and increments the counter, so we need a second way to insert an entry that keeps its id. Add this method inside the `EntryList` class in `EntryList.kt`, right after the existing `add` method:

```kotlin
    internal fun addPreserveId(entry: Entry) {
        entries.add(entry)
        if (entry.id >= nextId) {
            nextId = entry.id + 1
        }
    }
```

The `internal` modifier makes the method visible within the module but not as part of any external API; this matches its purpose as a loading helper. The method appends the entry without validation (we trust loaded data was already valid) and bumps `nextId` so that future `add` calls do not collide with existing ids. After loading entries `[1, 2, 5]`, `nextId` is `6`, so the next added entry gets id `6`.

### Step 3: Load and Save in Main.kt

Now decide where the entries file lives. A reasonable default is `~/.catatku/entries.txt`, where `~` is the user's home directory. Replace `Main.kt` with:

```kotlin
package com.qadrlabs.catatku

import java.io.File
import kotlin.system.exitProcess

private fun entriesFile(): File {
    val home = System.getProperty("user.home")
    val dir = File(home, ".catatku")
    if (!dir.exists()) {
        dir.mkdirs()
    }
    return File(dir, "entries.txt")
}

fun main(args: Array<String>) {
    val file = entriesFile()
    val list = EntryList()

    // Load existing entries
    when (val loadResult = loadEntries(file)) {
        is CatatkuResult.Ok -> {
            // Restore the entries into the list, preserving ids
            for (entry in loadResult.value) {
                list.addPreserveId(entry)
            }
        }
        is CatatkuResult.Err -> {
            System.err.println("Error loading entries: ${loadResult.error.describe()}")
            exitProcess(1)
        }
    }

    if (args.isEmpty()) {
        printUsage()
        exitProcess(0)
    }

    val command = args[0]
    val rest = args.drop(1)

    val result: CatatkuResult<String> = when (command) {
        "add" -> handleAdd(list, rest)
        "list" -> handleList(list)
        "done" -> handleDone(list, rest)
        "cancel" -> handleCancel(list, rest)
        "remove" -> handleRemove(list, rest)
        "help" -> {
            printUsage()
            CatatkuResult.Ok("(help displayed)")
        }
        else -> {
            CatatkuResult.Err(CatatkuError.ParseError("Unknown command: $command"))
        }
    }

    // Save if the command modified state
    if (command in setOf("add", "done", "cancel", "remove") && result is CatatkuResult.Ok) {
        when (val saveResult = saveEntries(file, list.all())) {
            is CatatkuResult.Ok -> { /* fine */ }
            is CatatkuResult.Err -> {
                System.err.println("Warning: failed to save: ${saveResult.error.describe()}")
            }
        }
    }

    when (result) {
        is CatatkuResult.Ok -> { /* handler already printed */ }
        is CatatkuResult.Err -> {
            System.err.println("Error: ${result.error.describe()}")
            exitProcess(1)
        }
    }
}
```

The `entriesFile()` function builds the path `<user.home>/.catatku/entries.txt`, creating the directory if it does not exist. `System.getProperty("user.home")` returns the user's home directory across platforms. The function is `private` because only `Main.kt` needs it.

The main function now loads the existing entries before dispatching, and saves them after the command if the command was a state-modifying one (add, done, cancel, remove) and succeeded. The check uses `command in setOf(...)` for a clean membership test. The pre-populated entries from Lesson 18 are gone: the file is now the source of truth. If loading fails (for example, because the file is damaged), the program reports the problem and exits with code 1 instead of overwriting the file.

---

## 5. Testing the Persistence

Run a sequence of commands through the launcher and verify the data persists across invocations. Rebuild first, and look at the file between commands to see exactly what Catatku writes. On Windows, use `type %USERPROFILE%\.catatku\entries.txt` instead of `cat ~/.catatku/entries.txt`.

### Step 1: First Run, Add an Entry

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku add "Pay rent"
```

Output:

```text
Added entry 1: Pay rent
```

Now look at the file:

```bash
cat ~/.catatku/entries.txt
```

Output:

```text
# Catatku entries (tab-separated)
1	Pay rent	MEDIUM	pending	2026-04-26
```

The entry was saved in the format we designed. The date is the default `createdAt` value from the `Entry` data class, so every entry shows the same date for now.

### Step 2: Second Run, Add More

```bash
build/install/catatku/bin/catatku add "Buy groceries"
```

Output:

```text
Added entry 2: Buy groceries
```

Check the file again with `cat ~/.catatku/entries.txt`. Output:

```text
# Catatku entries (tab-separated)
1	Pay rent	MEDIUM	pending	2026-04-26
2	Buy groceries	MEDIUM	pending	2026-04-26
```

The original entry is still there, and the new one was added with id 2 (the next available). The id counter was rebuilt correctly from the file by `addPreserveId`.

### Step 3: Verify list and Modifications

```bash
build/install/catatku/bin/catatku list
```

Output:

```text
[ ] (M) 1. Pay rent
[ ] (M) 2. Buy groceries

2 active out of 2 total
```

Mark the first entry done:

```bash
build/install/catatku/bin/catatku done 1
```

Output:

```text
Marked entry 1 as done.
```

Running `cat ~/.catatku/entries.txt` now shows:

```text
# Catatku entries (tab-separated)
1	Pay rent	MEDIUM	done	2026-04-26
2	Buy groceries	MEDIUM	pending	2026-04-26
```

The status of entry 1 changed from `pending` to `done`, and the change persisted. Now cancel the second entry:

```bash
build/install/catatku/bin/catatku cancel 2 "rescheduled"
```

Output:

```text
Cancelled entry 2: rescheduled
```

And the file:

```text
# Catatku entries (tab-separated)
1	Pay rent	MEDIUM	done	2026-04-26
2	Buy groceries	MEDIUM	cancelled:rescheduled	2026-04-26
```

The cancellation reason is encoded as `cancelled:rescheduled`. Everything roundtrips: we can write entries to the file, read them back, modify them, and write them again with the changes preserved.

---

## 6. Run and Test

The full Catatku with persistence is a real, usable application now. Here is a complete test sequence from a clean start, including the error cases.

### Step 1: Clean Up and Start Fresh

Delete the entries file so Catatku behaves as on a first run:

```bash
rm ~/.catatku/entries.txt
```

On Windows, delete `%USERPROFILE%\.catatku\entries.txt` with File Explorer or `del`. Now list the entries:

```bash
build/install/catatku/bin/catatku list
```

Output:

```text
(no entries yet)
```

No file is created by this command: `loadEntries` returned an empty list, and `list` does not modify state, so nothing is saved.

### Step 2: A Realistic Session

Add three entries, finish one, cancel one, and look at the result:

```bash
build/install/catatku/bin/catatku add "Pay rent"
build/install/catatku/bin/catatku add "Finish Kotlin course"
build/install/catatku/bin/catatku add "Read for fun"
build/install/catatku/bin/catatku done 2
build/install/catatku/bin/catatku cancel 3 "lost interest"
build/install/catatku/bin/catatku list
```

Output:

```text
Added entry 1: Pay rent
Added entry 2: Finish Kotlin course
Added entry 3: Read for fun
Marked entry 2 as done.
Cancelled entry 3: lost interest
[ ] (M) 1. Pay rent
[x] (M) 2. Finish Kotlin course
[!] (M) 3. Read for fun

1 active out of 3 total
```

Every command ran as a separate program, yet each one saw the changes made by the previous one. Now remove the cancelled entry and list again:

```bash
build/install/catatku/bin/catatku remove 3
build/install/catatku/bin/catatku list
```

Output:

```text
Removed entry 3: Read for fun
[ ] (M) 1. Pay rent
[x] (M) 2. Finish Kotlin course

1 active out of 2 total
```

Finally, `cat ~/.catatku/entries.txt` shows the header line and the two remaining entries:

```text
# Catatku entries (tab-separated)
1	Pay rent	MEDIUM	pending	2026-04-26
2	Finish Kotlin course	MEDIUM	done	2026-04-26
```

### Step 3: Test Error Cases

Invalid input still produces the same errors as in Lesson 18, and because saving happens only after a successful command, the file stays unchanged:

```bash
build/install/catatku/bin/catatku done abc
build/install/catatku/bin/catatku done 99
```

Output:

```text
Error: Invalid id: 'abc' is not a valid integer
Error: Entry with id 99 not found
```

Now simulate a damaged file. Open `~/.catatku/entries.txt` in a text editor, change the priority of entry 2 from `MEDIUM` to `URGENT`, save, and list again:

```bash
build/install/catatku/bin/catatku list
```

Output:

```text
Error loading entries: Parse error: line 3: unknown priority: 'URGENT'
```

The message names the line (the header is line 1) and the bad value, and the program exits with code 1 without touching the file. Change `URGENT` back to `MEDIUM` and `list` works again.

---

## 7. Handling Edge Cases

A few corner cases are worth thinking about even for a simple file format. This section explains how the code you wrote handles each one.

### Tabs in Descriptions

The format uses tabs as separators, so a description containing a tab would break parsing. We replace tabs with spaces in `entryToLine`. This is a lossy transformation (tabs become spaces), but it preserves the format integrity. For Catatku's use case (short text descriptions), this is fine. A more sophisticated format (like JSON in Lesson 20) handles this correctly without lossy transformations.

### File Not Existing on First Run

We handle this by returning `Ok(emptyList())` from `loadEntries` when `file.exists()` is false. This is the "first run" behavior: no errors, no warnings, just start with no entries. The first save creates the file.

### Corrupted File

If the user (or another program) damages the file, parsing fails, and we report a `ParseError` with the line number, as you saw in the Run and Test section. The user can either fix the file manually or delete it to start fresh. We do not auto-recover from corruption because that would risk silently losing data.

### Concurrent Writes

If two instances of Catatku ran at the same time, they could overwrite each other's changes. This is not handled in our implementation; we assume a single user running one instance at a time. For a multi-user application, you would use file locking or a database, but for a personal CLI tool, the simple assumption is fine.

### Permission Errors

If the user does not have permission to read or write the file, the I/O exception is caught and reported as `IoError`. The user sees a clear error message and can fix the permissions or change the file location.

---

## 8. Fix the Errors in Your Code

Three file-handling mistakes are common.

**Error 1: Reading a file that might not exist**

```kotlin
// Wrong
fun loadEntries(file: File): CatatkuResult<List<Entry>> {
    val content = file.readText()
    return parseEntries(content)
}

// Correct
fun loadEntries(file: File): CatatkuResult<List<Entry>> {
    if (!file.exists()) {
        return CatatkuResult.Ok(emptyList())  // first run
    }
    val content = try {
        file.readText()
    } catch (e: Exception) {
        return CatatkuResult.Err(CatatkuError.IoError("failed to read ${file.path}: ${e.message}"))
    }
    return parseEntries(content)
}
```

On the very first run there is no `entries.txt`, so the wrong version crashes with `java.io.FileNotFoundException`, followed by the full path and `(No such file or directory)`. The fix is to check `file.exists()` first and return an empty result for "first run". As a habit, when reading a data file that might not exist on first launch, treat the missing case as a normal initial state rather than as an error.

**Error 2: Writing directly to the target file**

```kotlin
// Wrong
fun saveEntries(file: File, entries: List<Entry>): CatatkuResult<Unit> {
    file.writeText(serializeEntries(entries))
    return CatatkuResult.Ok(Unit)
}

// Correct
fun saveEntries(file: File, entries: List<Entry>): CatatkuResult<Unit> {
    return try {
        val tempFile = File(file.parentFile ?: File("."), "${file.name}.tmp")
        tempFile.writeText(serializeEntries(entries))
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

The wrong version works in every normal run, which is what makes it dangerous. `writeText` first empties the target file and then writes the new content, so if the program is interrupted in between (a crash, a full disk, a power cut), the file is left empty or half-written and the old data is gone. It also lets any I/O exception escape instead of returning an `IoError`. The fix is to write to a temporary file and move it into place atomically. As a habit, use this pattern for any file you care about; the cost is one extra file operation and the benefit is no corruption from interrupted writes.

**Error 3: Printing diagnostics to stdout**

```kotlin
// Wrong
if (!file.exists()) {
    println("Warning: file does not exist, starting fresh")
    return CatatkuResult.Ok(emptyList())
}

// Correct
if (!file.exists()) {
    return CatatkuResult.Ok(emptyList())  // first run is normal, nothing to report
}
```

Information about file operations does not belong on stdout. The user might be redirecting the output of `list` to a file or piping it to another program, and the warning would end up mixed into that data. Here the first run is a normal situation, so the right fix is to print nothing at all; when a message really is needed, use `System.err.println`. As a habit, anything that is "diagnostic" (warnings, info, errors) goes to stderr; only the actual data the user asked for goes to stdout.

---

## 9. Exercises

These exercises practice file I/O.

**Exercise 1:** Add a `--file <path>` flag to Catatku that overrides the default file location. Parse it from the args before dispatching, falling back to `entriesFile()` when the flag is absent. Hint: scan args for "--file" and use the next argument as the path.

**Exercise 2:** Add a backup feature: before each save, copy the current file (if it exists) to `<file>.bak`. This way the user can recover from a bad save by restoring the backup. Use `file.copyTo(...)` for the copy.

**Exercise 3:** Modify `parseEntries` to ignore unparseable lines instead of returning an error, but report the count of skipped lines in a stderr warning. This is more forgiving for partially corrupt files.

---

## 10. Solutions

Try the exercises yourself first, then check the solutions below. When you are done, return the files to the versions from Section 4, because Lesson 20 starts from them.

**Solution for Exercise 1:**

The flag has to be removed from the arguments before the command dispatch sees them, otherwise `--file` would be treated as part of a description. Replace `Main.kt` with:

```kotlin
package com.qadrlabs.catatku

import java.io.File
import kotlin.system.exitProcess

private fun entriesFile(): File {
    val home = System.getProperty("user.home")
    val dir = File(home, ".catatku")
    if (!dir.exists()) {
        dir.mkdirs()
    }
    return File(dir, "entries.txt")
}

fun main(rawArgs: Array<String>) {
    val fileFlag = rawArgs.indexOf("--file")
    val customPath = if (fileFlag >= 0) rawArgs.getOrNull(fileFlag + 1) else null
    if (fileFlag >= 0 && customPath == null) {
        System.err.println("Error: --file requires a path")
        exitProcess(1)
    }
    val args = if (fileFlag >= 0) {
        rawArgs.filterIndexed { i, _ -> i != fileFlag && i != fileFlag + 1 }
    } else {
        rawArgs.toList()
    }
    val file = if (customPath != null) File(customPath) else entriesFile()
    val list = EntryList()

    // Load existing entries
    when (val loadResult = loadEntries(file)) {
        is CatatkuResult.Ok -> {
            // Restore the entries into the list, preserving ids
            for (entry in loadResult.value) {
                list.addPreserveId(entry)
            }
        }
        is CatatkuResult.Err -> {
            System.err.println("Error loading entries: ${loadResult.error.describe()}")
            exitProcess(1)
        }
    }

    if (args.isEmpty()) {
        printUsage()
        exitProcess(0)
    }

    val command = args[0]
    val rest = args.drop(1)

    val result: CatatkuResult<String> = when (command) {
        "add" -> handleAdd(list, rest)
        "list" -> handleList(list)
        "done" -> handleDone(list, rest)
        "cancel" -> handleCancel(list, rest)
        "remove" -> handleRemove(list, rest)
        "help" -> {
            printUsage()
            CatatkuResult.Ok("(help displayed)")
        }
        else -> {
            CatatkuResult.Err(CatatkuError.ParseError("Unknown command: $command"))
        }
    }

    // Save if the command modified state
    if (command in setOf("add", "done", "cancel", "remove") && result is CatatkuResult.Ok) {
        when (val saveResult = saveEntries(file, list.all())) {
            is CatatkuResult.Ok -> { /* fine */ }
            is CatatkuResult.Err -> {
                System.err.println("Warning: failed to save: ${saveResult.error.describe()}")
            }
        }
    }

    when (result) {
        is CatatkuResult.Ok -> { /* handler already printed */ }
        is CatatkuResult.Err -> {
            System.err.println("Error: ${result.error.describe()}")
            exitProcess(1)
        }
    }
}
```

`main` now receives the raw arguments as `rawArgs`. `indexOf("--file")` finds the flag (or returns `-1`), and `getOrNull(fileFlag + 1)` reads the path after it without risking an out-of-bounds crash. A flag without a path is reported as an error. `filterIndexed` builds the cleaned-up `args` list by dropping the flag and its value, so the rest of `main` works exactly as before; `args` is now a `List<String>` instead of an array, which is fine because the code only uses `isEmpty()`, indexing, and `drop`. Rebuild and try it:

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku --file work.txt add "Prepare slides"
build/install/catatku/bin/catatku list --file work.txt
build/install/catatku/bin/catatku list --file
```

Output:

```text
Added entry 1: Prepare slides
[ ] (M) 1. Prepare slides

1 active out of 1 total
Error: --file requires a path
```

The entry went into `work.txt` in the folder you ran the command from (the project folder here), not into `~/.catatku/entries.txt`; a plain `list` still shows your normal entries. The flag works in any position because it is removed before dispatch.

**Solution for Exercise 2:**

In `Storage.kt`, replace `saveEntries` with a version that backs up first:

```kotlin
fun saveEntries(file: File, entries: List<Entry>): CatatkuResult<Unit> {
    val content = serializeEntries(entries)

    return try {
        // Back up the current file if it exists
        if (file.exists()) {
            val backup = File(file.parentFile ?: File("."), "${file.name}.bak")
            file.copyTo(backup, overwrite = true)
        }

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

The `file.copyTo(backup, overwrite = true)` extension copies the current file to `entries.txt.bak` before the new content is written. The `overwrite = true` argument is required because, after the first save, the backup already exists; without it, `copyTo` throws a `FileAlreadyExistsException`. Rebuild, run a state-modifying command, and list the folder:

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku add "Water the plants"
ls ~/.catatku/
```

Output:

```text
Added entry 3: Water the plants
entries.txt
entries.txt.bak
```

The backup holds the state from just before the last save. If a save ever goes wrong, the user can copy `entries.txt.bak` back over `entries.txt` to recover. A more sophisticated version might include a timestamp in the backup name and keep a few previous versions, which is the start of a "save history" feature. For a personal CLI tool, a single rolling backup is usually enough.

**Solution for Exercise 3:**

In `Storage.kt`, replace `parseEntries` with:

```kotlin
fun parseEntries(content: String): CatatkuResult<List<Entry>> {
    val entries = mutableListOf<Entry>()
    var skipped = 0

    for (line in content.lines()) {
        val trimmed = line.trim()
        if (trimmed.isEmpty() || trimmed.startsWith("#")) {
            continue  // skip blank lines and comments
        }

        when (val result = lineToEntry(trimmed)) {
            is CatatkuResult.Ok -> entries.add(result.value)
            is CatatkuResult.Err -> skipped += 1
        }
    }

    if (skipped > 0) {
        System.err.println("Warning: skipped $skipped unreadable line(s)")
    }
    return CatatkuResult.Ok(entries)
}
```

Instead of returning at the first bad line, the loop counts failures in `skipped` and keeps going. After the loop, a non-zero count produces one warning on stderr, and the function always returns `Ok` with the entries it could read. To test it, add a line such as `this line is broken` to the end of `~/.catatku/entries.txt` with a text editor, rebuild, and list:

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku list
```

Output:

```text
Warning: skipped 1 unreadable line(s)
[ ] (M) 1. Pay rent
[x] (M) 2. Finish Kotlin course
[ ] (M) 3. Water the plants

2 active out of 3 total
```

The tradeoff is real: the next save writes only the readable entries, so the broken line disappears from the file for good. That is acceptable for a forgiving tool, but it is exactly the "silently losing data" risk that made the main lesson stop with an error instead.

---

## 11. Understanding Persistence Choices

When designing a file format for an application's data, you face a series of choices that have long-term consequences. Understanding the tradeoffs helps you pick wisely.

The first choice is the format itself: line-based text, structured text (JSON, YAML, TOML), binary, or a database. Each has tradeoffs. Line-based text is simple and human-editable but does not handle complex structure well; you have to invent ad-hoc encodings for things like nested data or special characters. Structured text formats handle structure naturally but are slightly more verbose and less human-skimmable. Binary formats are most compact and fastest to parse but require tools to inspect. Databases are most powerful but add a dependency and complexity.

For Catatku, the entry data is shallow (no nesting), the volume is small (dozens or hundreds of entries), and the user might want to inspect or edit the file. This suggests text-based formats. We started with line-based tab-separated for educational reasons; Lesson 20 will switch to JSON, which handles structure more cleanly.

The second choice is how to handle changes over time. Your data format will need to evolve as the application grows. New fields get added, existing fields might change types, old fields might be removed. The file format needs to allow these changes without breaking existing data. Strategies include:

Versioning: include a version number in the file, and have the parser handle multiple versions. This is robust but requires writing migration code as new versions are introduced.

Forward-compatible parsing: design the format so that new fields are optional and missing fields use defaults. This works well for additive changes but not for breaking changes.

Migration: when an old format is detected, read it, convert it to the new format, and write it back. This handles structural changes but requires keeping all the old reader code around.

For Catatku, our format does not include a version number yet. We will introduce one when we switch to JSON in Lesson 20, where it becomes a standard JSON field.

The third choice is atomicity and durability. We use the temporary-file-then-atomic-move pattern for atomicity. For durability (the data survives a sudden power loss), some applications additionally call `fsync` or its equivalent to flush kernel buffers to disk. The Java standard library has `RandomAccessFile.getFD().sync()` for this, but it is rarely needed for personal applications. For Catatku, the atomic move is enough.

The fourth choice is location. Application data goes in different places depending on the operating system and user expectations. The XDG Base Directory specification (used on most Linux systems) suggests `~/.local/share/<appname>/` for data. macOS suggests `~/Library/Application Support/<appname>/`. Windows uses `%APPDATA%\<appname>\`. For cross-platform tools, libraries like `appdirs` handle these conventions, but we use `~/.catatku/` for simplicity, which is fine on macOS and Linux but slightly off-convention on Windows.

The fifth choice is concurrency. If multiple instances of the application can run at once, you need to coordinate writes. Options include file locking (use `FileLock` to claim exclusive access), append-only logs (each instance appends to a log, and reads merge them), or a single coordinator process. For a personal CLI tool used by one user at a time, none of this is needed. For a multi-user system, the choice depends on the use case.

For Catatku, we have made simple choices throughout: text format, no versioning yet, atomic writes, simple location, single-user assumption. These work well for the application's scope. As needs grow, you would revisit each choice; for now, simplicity is the right tradeoff.

The deeper lesson is that persistence is more than just "write the data to disk". Each layer (format, evolution, atomicity, location, concurrency) deserves thought, and getting them right means the application works reliably even in unexpected situations. A poorly-designed format causes pain forever; a well-designed format gives you flexibility for years. The few hours spent thinking through the choices upfront save many hours of headaches later.

---

## Next Up - Lesson 20

Catatku now persists its state across runs using a simple tab-separated text format stored at `~/.catatku/entries.txt`. The new file `Storage.kt` contains the serialization functions (`entryToLine`, `serializeEntries`), the parser (`lineToEntry`, `parseStatus`, `parseEntries`), and the file I/O (`loadEntries`, `saveEntries`). The save writes a temporary file and moves it into place atomically. The `EntryList` class gained an `addPreserveId` method for restoring entries with their original ids during loading. The `Main.kt` now loads entries at startup, runs the requested command, and saves entries when state changes, with errors flowing through the existing `CatatkuResult` machinery. The file does not exist on first run (which we treat as "no entries yet"), and the application exits cleanly without crashing for any error case we have considered.

In Lesson 20 you will replace the tab-separated format with JSON, using the `kotlinx.serialization` library. This involves adding a dependency in `build.gradle.kts`, annotating the data classes with `@Serializable`, configuring polymorphic serialization for the sealed `Status` class, and using `Json.encodeToString` and `Json.decodeFromString` for the actual conversion. The end result is a more robust file format that handles structure naturally and is the standard choice for application data interchange.
