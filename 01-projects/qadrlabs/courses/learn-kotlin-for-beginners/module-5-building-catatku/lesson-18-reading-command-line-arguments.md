## 1. Before You Begin

Catatku is meant to be used from the terminal. The user types something like `catatku add "Pay rent"` or `catatku done 5`, and the program responds. Up to this point, our `main` function has just run a hardcoded sequence of operations and printed the result; nothing read input from the user. This lesson connects Catatku to the command line by reading the `args: Array<String>` parameter, parsing the command name and its arguments, dispatching to the appropriate `EntryList` method, and reporting the outcome with friendly messages.

Command-line argument parsing is one of those tasks that looks trivial until you do it carefully. The user can type the wrong number of arguments, an invalid id, an empty description, or a command name that does not exist. Each case needs to be handled gracefully: a clear error message, an appropriate exit code, no crash. By the end of this lesson, Catatku has a command processor that handles every reasonable input plus the malformed ones, with the structured error type from Lesson 16 carrying domain-specific failure information through the layers. The command-handling logic goes into a new file, `Cli.kt`, so that `Main.kt` stays focused on dispatch.

### What You'll Build

A complete command-line interface for Catatku supporting `add`, `list`, `done`, `cancel`, `remove`, and `help` commands. The program will read its commands from `args`, dispatch via a clean `when` expression, validate inputs, and produce friendly output for both successes and failures. By the end of the lesson, you can run Catatku from the terminal as a real CLI tool.

### What You'll Learn

- ✅ How `main` reads command-line arguments via the `args: Array<String>` parameter
- ✅ How to dispatch commands with `when` over the first argument
- ✅ How to parse numeric arguments safely using `toIntOrNull`
- ✅ How to join trailing arguments to form a description or reason
- ✅ How to use `exitProcess` for appropriate exit codes
- ✅ How to write to stderr via `System.err.println` for error messages
- ✅ How to build a `catatku` launcher script with Gradle's `installDist` task

### What You'll Need

- The multi-file Catatku project from Lesson 17, with `Entry.kt`, `EntryList.kt`, `Errors.kt`, `Stats.kt`, and `Main.kt` all in `com.qadrlabs.catatku`, and `mainClass` set to `com.qadrlabs.catatku.MainKt`
- A terminal where you can run the program with arguments
- About forty-five minutes
- Comfort with the `EntryList` class and its `CatatkuResult` return values

---

## 2. Reading Arguments in main

The `main` function can declare a parameter `args: Array<String>` to receive the command-line arguments. Each element of the array is one argument as the user typed it. In this section you will print the arguments to see what the program receives, then dispatch on the first one.

### Step 1: A Minimal Argument-Reading main

Update `Main.kt` to look like this:

```kotlin
package com.qadrlabs.catatku

fun main(args: Array<String>) {
    println("Number of arguments: ${args.size}")
    for ((i, arg) in args.withIndex()) {
        println("  [$i] = '$arg'")
    }
}
```

The new parameter `args: Array<String>` holds every argument passed to the program. `args.size` tells you how many there are, and `withIndex()` pairs each argument with its position so the loop can print both. Wrapping each argument in single quotes in the output makes it easy to see where one argument ends and the next begins.

To pass arguments from the terminal, use Gradle's `--args` option. Run the program with `add` and a quoted description:

```bash
./gradlew run -q --args="add 'Pay rent'"
```

Output:

```text
Number of arguments: 2
  [0] = 'add'
  [1] = 'Pay rent'
```

The whole `--args` value is in double quotes so your shell passes it to Gradle as one piece, and Gradle then splits it on whitespace, keeping the single-quoted `'Pay rent'` together as one argument. Without the inner quotes, the description becomes two separate arguments:

```bash
./gradlew run -q --args="add Pay rent"
```

Output:

```text
Number of arguments: 3
  [0] = 'add'
  [1] = 'Pay'
  [2] = 'rent'
```

The program just receives whatever was parsed before it started. If you prefer the IDE, click the Run configuration dropdown, choose "Edit Configurations", and type the arguments (for example `add "Pay rent"`) into the "Program arguments" field.

### Step 2: Dispatch on the First Argument

The first argument is conventionally the command name. We dispatch on it using `when`. Replace `Main.kt` with:

```kotlin
package com.qadrlabs.catatku

fun main(args: Array<String>) {
    if (args.isEmpty()) {
        printUsage()
        return
    }

    val command = args[0]
    val rest = args.drop(1)  // List<String> of the remaining args

    when (command) {
        "add" -> println("Will add: $rest")
        "list" -> println("Will list")
        "done" -> println("Will mark done: $rest")
        "cancel" -> println("Will cancel: $rest")
        "remove" -> println("Will remove: $rest")
        "help" -> printUsage()
        else -> {
            println("Unknown command: $command")
            printUsage()
        }
    }
}

fun printUsage() {
    println("""
        |Catatku - personal entry tracker
        |
        |Usage:
        |  catatku add <description>     Add a new entry
        |  catatku list                  List all entries
        |  catatku done <id>             Mark an entry as done
        |  catatku cancel <id> <reason>  Cancel an entry with a reason
        |  catatku remove <id>           Remove an entry
        |  catatku help                  Show this message
    """.trimMargin())
}
```

The `args.drop(1)` returns a `List<String>` of all arguments after the command name. We use this list (which we named `rest`) to look at the remaining arguments. If the user typed `add "Pay rent"`, then `args` is `["add", "Pay rent"]`, and `rest` is `["Pay rent"]`. The `if (args.isEmpty())` check at the top runs first, so `args[0]` is only read when at least one argument exists.

The `printUsage` function uses a multi-line raw string with `trimMargin()`. The `|` characters mark the left margin; everything before them on each line gets stripped, which lets us indent the source nicely while producing flush-left output.

Run it with `add`:

```bash
./gradlew run -q --args="add 'Pay rent'"
```

Output:

```text
Will add: [Pay rent]
```

Run it with `list`:

```bash
./gradlew run -q --args="list"
```

Output:

```text
Will list
```

And with a command that does not exist:

```bash
./gradlew run -q --args="xyz"
```

Output:

```text
Unknown command: xyz
Catatku - personal entry tracker

Usage:
  catatku add <description>     Add a new entry
  catatku list                  List all entries
  catatku done <id>             Mark an entry as done
  catatku cancel <id> <reason>  Cancel an entry with a reason
  catatku remove <id>           Remove an entry
  catatku help                  Show this message
```

The skeleton recognizes every command. Next we replace the `println` placeholders with real work.

---

## 3. Implementing the Command Handlers

Each handler function takes the `EntryList` and the remaining arguments, performs the appropriate operation, and returns a `CatatkuResult<String>`. Most are short. We will put them all in a new file called `Cli.kt` to keep `Main.kt` focused on dispatch.

### Step 1: Create Cli.kt

Create `src/main/kotlin/com/qadrlabs/catatku/Cli.kt`:

```kotlin
package com.qadrlabs.catatku

fun handleAdd(list: EntryList, args: List<String>): CatatkuResult<String> {
    if (args.isEmpty()) {
        return CatatkuResult.Err(CatatkuError.EmptyDescription)
    }
    val description = args.joinToString(" ")
    return when (val r = list.add(description)) {
        is CatatkuResult.Ok -> {
            println("Added entry ${r.value.id}: ${r.value.description}")
            CatatkuResult.Ok("added")
        }
        is CatatkuResult.Err -> r
    }
}

fun handleList(list: EntryList): CatatkuResult<String> {
    val entries = list.all()
    if (entries.isEmpty()) {
        println("(no entries yet)")
    } else {
        for (entry in entries) {
            println(entry.summary)
        }
    }
    return CatatkuResult.Ok("listed")
}

fun handleDone(list: EntryList, args: List<String>): CatatkuResult<String> {
    val idText = args.firstOrNull()
        ?: return CatatkuResult.Err(CatatkuError.ParseError("done command requires an id"))
    val id = idText.toIntOrNull()
        ?: return CatatkuResult.Err(CatatkuError.InvalidId(idText))

    return when (val r = list.markDone(id)) {
        is CatatkuResult.Ok -> {
            println("Marked entry $id as done.")
            CatatkuResult.Ok("done")
        }
        is CatatkuResult.Err -> r
    }
}

fun handleCancel(list: EntryList, args: List<String>): CatatkuResult<String> {
    val idText = args.firstOrNull()
        ?: return CatatkuResult.Err(CatatkuError.ParseError("cancel command requires an id and reason"))
    val id = idText.toIntOrNull()
        ?: return CatatkuResult.Err(CatatkuError.InvalidId(idText))

    val reason = args.drop(1).joinToString(" ")
    if (reason.isBlank()) {
        return CatatkuResult.Err(CatatkuError.ParseError("cancel command requires a reason"))
    }

    return when (val r = list.cancel(id, reason)) {
        is CatatkuResult.Ok -> {
            println("Cancelled entry $id: $reason")
            CatatkuResult.Ok("cancelled")
        }
        is CatatkuResult.Err -> r
    }
}

fun handleRemove(list: EntryList, args: List<String>): CatatkuResult<String> {
    val idText = args.firstOrNull()
        ?: return CatatkuResult.Err(CatatkuError.ParseError("remove command requires an id"))
    val id = idText.toIntOrNull()
        ?: return CatatkuResult.Err(CatatkuError.InvalidId(idText))

    return when (val r = list.remove(id)) {
        is CatatkuResult.Ok -> {
            println("Removed entry $id: ${r.value.description}")
            CatatkuResult.Ok("removed")
        }
        is CatatkuResult.Err -> r
    }
}

fun printUsage() {
    println("""
        |Catatku - personal entry tracker
        |
        |Usage:
        |  catatku add <description>     Add a new entry
        |  catatku list                  List all entries
        |  catatku done <id>             Mark an entry as done
        |  catatku cancel <id> <reason>  Cancel an entry with a reason
        |  catatku remove <id>           Remove an entry
        |  catatku help                  Show this message
    """.trimMargin())
}
```

Save. The file declares six functions: five command handlers plus `printUsage`, which now lives here instead of in `Main.kt`. Each handler validates its arguments, calls the appropriate `EntryList` method, and reports the result. The structure is repetitive (each handler does roughly the same thing) but the repetition makes each handler self-contained and easy to read.

Walk through `handleDone` as a representative example. The function takes the `EntryList` and the remaining args. It pulls the first argument as `idText` with `firstOrNull()`, returning `Err(ParseError(...))` if there are no arguments. It tries to parse `idText` as an integer with `toIntOrNull`, returning `Err(InvalidId(...))` if parsing fails. It calls `list.markDone(id)` to do the actual work. Finally, it pattern-matches on the result: on success, it prints a friendly message and returns `Ok`; on failure, it propagates the error directly.

`handleAdd` and `handleCancel` use `joinToString(" ")` to glue the remaining arguments back together, so a description typed without quotes still becomes one string. Each handler has the same shape: validate args, parse what is needed, call the appropriate `EntryList` method, report the result. The `CatatkuResult` flow makes errors explicit at every step; a missing argument, a bad id, or a missing entry each produce an `Err` with the right variant.

### Step 2: Replace Main.kt with the Dispatcher

Now wire the dispatch to the handlers. Replace the whole `Main.kt` with this version. It no longer contains `printUsage`, because that function moved to `Cli.kt`; keeping both would declare the same function twice in one package, which the compiler rejects.

```kotlin
package com.qadrlabs.catatku

import kotlin.system.exitProcess

fun main(args: Array<String>) {
    val list = EntryList()

    // For now, the entry list is empty each run. Lesson 19 will add persistence.

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

    when (result) {
        is CatatkuResult.Ok -> { /* the handler already printed the success */ }
        is CatatkuResult.Err -> {
            System.err.println("Error: ${result.error.describe()}")
            exitProcess(1)
        }
    }
}
```

The `when (command)` expression now produces a value: each branch returns a `CatatkuResult<String>`, either from a handler or directly (for `help` and unknown commands). The second `when` inspects that result. On success the handler has already printed its message, so there is nothing left to do. On failure, `main` prints the error and stops with exit code 1. For now the entry list is empty on every run; Lesson 19 adds persistence.

The `import kotlin.system.exitProcess` brings in the function for terminating with a specific exit code. Code 0 is the convention for "success", and any non-zero code is "failure". Shell scripts and CI tools rely on this convention to know whether a command succeeded.

The `System.err.println` writes to standard error rather than standard output. This matters because shell pipelines combine stdout from one program into stdin of the next; if errors went to stdout, they would corrupt the pipeline. By writing errors to stderr, we keep the data path clean and let users redirect just the data with `> file.txt` while still seeing errors in the terminal.

### Step 3: Build a catatku Launcher

`./gradlew run` is handy, but when a program exits with code 1, Gradle reports the run task itself as failed and prints a long "BUILD FAILED" block after your error message. A real CLI tool should print only its own message. Gradle's `application` plugin can build a small launcher script for you:

```bash
./gradlew installDist -q
```

This compiles the project and creates `build/install/catatku/`, with the launcher scripts in its `bin` folder: `catatku` for macOS and Linux, and `catatku.bat` for Windows. The command prints nothing when it succeeds. Now run a command through the launcher:

```bash
build/install/catatku/bin/catatku add "Pay rent"
```

Output:

```text
Added entry 1: Pay rent
```

On Windows, use `build\install\catatku\bin\catatku.bat add "Pay rent"`. From here on, whenever you change the code, run `./gradlew installDist -q` again before trying the launcher, because the launcher runs the last compiled version.

Try a few more commands:

```bash
build/install/catatku/bin/catatku list
```

Output:

```text
(no entries yet)
```

The list is empty because each run starts with a fresh `EntryList`: the entry added by the previous command disappeared when that program exited. Now try marking an entry that does not exist:

```bash
build/install/catatku/bin/catatku done 5
```

Output:

```text
Error: Entry with id 5 not found
```

This message is written to stderr, and the program exits with code 1. An id that is not a number takes a different path:

```bash
build/install/catatku/bin/catatku done abc
```

Output:

```text
Error: Invalid id: 'abc' is not a valid integer
```

And an unknown command:

```bash
build/install/catatku/bin/catatku xyz
```

Output:

```text
Error: Parse error: Unknown command: xyz
```

Each input is handled appropriately, and the error messages tell the user what went wrong.

### Step 4: Pre-Populate Entries for Testing

Because we do not have persistence yet, each `main` invocation starts with an empty `EntryList`. So commands like `done 1` cannot succeed across runs. To test the full flow, we add a hardcoded sequence at the top of `main` (just for testing) and remove it once Lesson 19 adds file persistence. Replace `Main.kt` with:

```kotlin
package com.qadrlabs.catatku

import kotlin.system.exitProcess

fun main(args: Array<String>) {
    val list = EntryList()

    // Pre-populate for testing (will be replaced by file persistence in Lesson 19)
    list.add("Pay rent", Priority.HIGH)
    list.add("Buy groceries")
    list.add("Read for fun", Priority.LOW)

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

    when (result) {
        is CatatkuResult.Ok -> { /* handler already printed */ }
        is CatatkuResult.Err -> {
            System.err.println("Error: ${result.error.describe()}")
            exitProcess(1)
        }
    }
}
```

The only change is the three `list.add(...)` calls right after creating the list. They give every run the same three starting entries. Rebuild the launcher, then list the entries:

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku list
```

Output:

```text
[ ] (H) 1. Pay rent
[ ] (M) 2. Buy groceries
[ ] (L) 3. Read for fun
```

Mark the first one done:

```bash
build/install/catatku/bin/catatku done 1
```

Output:

```text
Marked entry 1 as done.
```

Cancel the third one with a reason:

```bash
build/install/catatku/bin/catatku cancel 3 "not interested"
```

Output:

```text
Cancelled entry 3: not interested
```

Each command works correctly against the pre-populated state. After Lesson 19 adds file persistence, the pre-population block will be replaced by reading from disk, and changes will persist across runs.

---

## 4. Handling Edge Cases

A real CLI tool needs to handle inputs the user might actually type, not just the happy path. This section covers a few cases that are easy to miss. All of them already work with the code you have; each step shows you how to confirm it.

### Step 1: Empty Description

The user might type `add` with no following words. We already handle this in `handleAdd` by returning `Err(EmptyDescription)`:

```bash
build/install/catatku/bin/catatku add
```

Output:

```text
Error: Description cannot be empty
```

Good. The error is clear and the program exits with code 1.

### Step 2: Multi-Word Descriptions

The user might type the description without quotes. The shell splits it into separate arguments: `["add", "Pay", "the", "rent", "immediately"]`. Our handler joins everything after the command with `args.joinToString(" ")`:

```bash
build/install/catatku/bin/catatku add Pay the rent immediately
```

Output:

```text
Added entry 4: Pay the rent immediately
```

The new entry gets id 4 because the three pre-populated entries already use ids 1 to 3. The behavior is what the user probably wanted. With quotes, the shell keeps the words together as one argument, and `joinToString(" ")` of a single-element list is just that element. Either input produces the same result.

### Step 3: Leading or Trailing Whitespace

The user might accidentally include trailing whitespace in a description:

```bash
build/install/catatku/bin/catatku add "Pay rent  "
```

Output:

```text
Added entry 4: Pay rent
```

The `EntryList.add` method already calls `description.trim()`, so the entry is stored without the trailing spaces. We could be more aggressive and strip extra internal whitespace too, but trim is usually enough for reasonable inputs.

### Step 4: Negative or Zero IDs

The user might type a negative id or zero. The parsing succeeds (both are valid integers), but no entry has that id (we start at 1), so `EntryList.markDone` returns `Err(EntryNotFound)`:

```bash
build/install/catatku/bin/catatku done -5
```

Output:

```text
Error: Entry with id -5 not found
```

This is the right behavior. The error message tells the user what went wrong, and the application exits cleanly. We do not need a separate validation for "id must be positive"; the `EntryNotFound` error is sufficient.

### Step 5: Very Large Numbers

The user might type a number larger than `Int.MAX_VALUE`. `toIntOrNull` returns `null` for it, and we report `InvalidId`:

```bash
build/install/catatku/bin/catatku done 99999999999999999999999
```

Output:

```text
Error: Invalid id: '99999999999999999999999' is not a valid integer
```

This is the right behavior. If we used `toLongOrNull` instead, we could handle larger numbers, but `Int` is fine for a personal entry tracker.

---

## 5. Improving the User Experience

A few small touches make the CLI nicer to use. We will add them now, both in `Cli.kt`.

### Step 1: Better Help Output

In `Cli.kt`, replace the whole `printUsage` function with this more detailed version:

```kotlin
fun printUsage() {
    println("""
        |Catatku 0.1.0 - personal entry tracker
        |
        |Usage:
        |  catatku <command> [arguments]
        |
        |Commands:
        |  add <description>             Add a new pending entry
        |  list                          List all entries
        |  done <id>                     Mark an entry as done
        |  cancel <id> <reason>          Cancel an entry with a reason
        |  remove <id>                   Remove an entry permanently
        |  help                          Show this message
        |
        |Examples:
        |  catatku add "Pay rent"
        |  catatku list
        |  catatku done 5
        |  catatku cancel 3 "rescheduled"
        |  catatku remove 7
    """.trimMargin())
}
```

The structure is the same raw string with `trimMargin()`; only the text changed. It now shows the version, a general usage line, a command list, and examples. Examples are particularly useful because they show the expected syntax in concrete form.

### Step 2: Show Entry Count on List

When listing, it can be nice to see how many entries there are. Replace `handleList` in `Cli.kt` with:

```kotlin
fun handleList(list: EntryList): CatatkuResult<String> {
    val entries = list.all()
    if (entries.isEmpty()) {
        println("(no entries yet)")
    } else {
        for (entry in entries) {
            println(entry.summary)
        }
        val active = entries.count { it.isActive }
        println()
        println("$active active out of ${entries.size} total")
    }
    return CatatkuResult.Ok("listed")
}
```

After printing the entries, the function counts the active ones with `count { it.isActive }`, prints an empty line, and prints the summary. This kind of small affordance (telling the user the counts at a glance) makes the tool feel polished. You will see both changes in action in the next section.

---

## 6. Run and Test

The full Catatku CLI is now wired up. Rebuild the launcher once, then test every command to verify everything works. Remember that each run starts from the same three pre-populated entries.

### Step 1: Run a Sequence of Commands

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku
```

With no arguments, the program prints the usage and exits cleanly. Output:

```text
Catatku 0.1.0 - personal entry tracker

Usage:
  catatku <command> [arguments]

Commands:
  add <description>             Add a new pending entry
  list                          List all entries
  done <id>                     Mark an entry as done
  cancel <id> <reason>          Cancel an entry with a reason
  remove <id>                   Remove an entry permanently
  help                          Show this message

Examples:
  catatku add "Pay rent"
  catatku list
  catatku done 5
  catatku cancel 3 "rescheduled"
  catatku remove 7
```

Now list the entries:

```bash
build/install/catatku/bin/catatku list
```

Output:

```text
[ ] (H) 1. Pay rent
[ ] (M) 2. Buy groceries
[ ] (L) 3. Read for fun

3 active out of 3 total
```

Then try each remaining command in turn:

```bash
build/install/catatku/bin/catatku add "Test entry"
build/install/catatku/bin/catatku done 1
build/install/catatku/bin/catatku cancel 2 "not needed"
build/install/catatku/bin/catatku remove 3
build/install/catatku/bin/catatku done 99
build/install/catatku/bin/catatku xyz foo
```

Output:

```text
Added entry 4: Test entry
Marked entry 1 as done.
Cancelled entry 2: not needed
Removed entry 3: Read for fun
Error: Entry with id 99 not found
Error: Parse error: Unknown command: xyz
```

Each command exercises a different code path, and each one produces a sensible message. If anything looks wrong, trace through the code to find the bug.

### Step 2: Verify Exit Codes

After running a command from the terminal, check the exit code with `echo $?` (on macOS or Linux) or `echo %errorlevel%` (in the Windows Command Prompt):

```bash
build/install/catatku/bin/catatku done 99
echo $?
```

Output:

```text
Error: Entry with id 99 not found
1
```

A successful command such as `build/install/catatku/bin/catatku list` followed by `echo $?` prints `0` on the last line instead. This matters because shell scripts use exit codes to chain commands or detect failures:

```bash
build/install/catatku/bin/catatku add "foo" && build/install/catatku/bin/catatku list
```

Output:

```text
Added entry 4: foo
[ ] (H) 1. Pay rent
[ ] (M) 2. Buy groceries
[ ] (L) 3. Read for fun

3 active out of 3 total
```

The `&&` runs the second command only because the first succeeded (exit code 0). The list does not contain "foo" because the two commands are separate runs; persistence arrives in Lesson 19.

### Step 3: Verify stdout vs stderr Separation

Try redirecting stdout and stderr into separate files for a failing command, then print both files:

```bash
build/install/catatku/bin/catatku done 99 > out.txt 2> err.txt
cat out.txt
cat err.txt
```

Output:

```text
Error: Entry with id 99 not found
```

`out.txt` is empty and the error message landed in `err.txt`. For a successful command such as `add "foo"`, it is the other way around: the confirmation lands in `out.txt` and `err.txt` stays empty. This separation lets users redirect the data path while still seeing errors, which is the standard convention for Unix-style tools. Delete `out.txt` and `err.txt` when you are done.

---

## 7. Fix the Errors in Your Code

Three CLI-related mistakes are common.

**Error 1: Indexing the arguments without checking the size**

```kotlin
// Wrong
val idText = args[0]

// Correct
val idText = args.firstOrNull()
    ?: return CatatkuResult.Err(CatatkuError.ParseError("done command requires an id"))
```

Inside `handleDone`, `args` is the list of arguments after the command name. If the user types just `done`, the list is empty and `args[0]` crashes the program with `java.lang.IndexOutOfBoundsException: Empty list doesn't contain element at index 0.` followed by a stack trace. The fix is to use `args.firstOrNull()` (which returns null instead) and handle the null case with `?:`. As a habit, never index a list directly without first checking the size or using a safe accessor.

**Error 2: Parsing with toInt instead of toIntOrNull**

```kotlin
// Wrong
val id = idText.toInt()

// Correct
val id = idText.toIntOrNull()
    ?: return CatatkuResult.Err(CatatkuError.InvalidId(idText))
```

`String.toInt()` throws on bad input: `done abc` crashes with `java.lang.NumberFormatException: For input string: "abc"`. The fix is to use `toIntOrNull()`, which returns `null` instead. The null integrates naturally with `?:` and the rest of the null-safety patterns. As a habit, prefer the `OrNull` variants for any parsing where invalid input is possible (which is essentially always when the input comes from outside).

**Error 3: Writing errors to stdout instead of stderr**

```kotlin
// Wrong
is CatatkuResult.Err -> println("Error: ${result.error.describe()}")

// Correct
is CatatkuResult.Err -> {
    System.err.println("Error: ${result.error.describe()}")
    exitProcess(1)
}
```

With `println`, the program still shows the message, so nothing looks broken until someone pipes or redirects the output: the error text then ends up mixed into the data, and the exit code stays 0, so `&&` chains continue as if everything succeeded. The fix is to use `System.err.println` for error messages and exit with a non-zero code. As a habit, when you write an error message that should be visible to the user but not part of the data flow, use stderr.

---

## 8. Exercises

These exercises practice CLI handling.

**Exercise 1:** Add a new command `count` that prints just the total number of entries (for example, "3 entries"). Wire it into the dispatch in `main` and add a handler in `Cli.kt`.

**Exercise 2:** Add a new command `pending` that lists only the entries with `Status.Pending`. Re-use the existing `entry.summary` extension and the `EntryList.all()` method to filter.

**Exercise 3:** Modify `handleAdd` to accept an optional `--priority H|M|L` flag at the end of the arguments. If present, set the priority accordingly; if absent, default to medium. Hint: scan the args for "--priority" and check the next argument.

---

## 9. Solutions

Try the exercises yourself first, then check the solutions below. Exercises 1 and 2 share the same updated `Main.kt`, shown once after both handlers.

**Solution for Exercise 1:**

Add this handler to `Cli.kt`:

```kotlin
fun handleCount(list: EntryList): CatatkuResult<String> {
    println("${list.size} entries")
    return CatatkuResult.Ok("counted")
}
```

`EntryList` already exposes a `size` property (Lesson 17), so the handler just prints it and returns `Ok`. It takes no arguments beyond the list, like `handleList`.

**Solution for Exercise 2:**

Add this handler to `Cli.kt`:

```kotlin
fun handlePending(list: EntryList): CatatkuResult<String> {
    val pending = list.all().filter { it.status is Status.Pending }
    if (pending.isEmpty()) {
        println("(no pending entries)")
    } else {
        for (entry in pending) {
            println(entry.summary)
        }
        println()
        println("${pending.size} pending entries")
    }
    return CatatkuResult.Ok("pending listed")
}
```

The handler filters the snapshot from `all()` down to entries whose status is `Status.Pending`, prints them with the existing `summary` extension, and adds a count at the bottom.

Now add both commands to the dispatch. Replace `Main.kt` with:

```kotlin
package com.qadrlabs.catatku

import kotlin.system.exitProcess

fun main(args: Array<String>) {
    val list = EntryList()

    // Pre-populate for testing (will be replaced by file persistence in Lesson 19)
    list.add("Pay rent", Priority.HIGH)
    list.add("Buy groceries")
    list.add("Read for fun", Priority.LOW)

    if (args.isEmpty()) {
        printUsage()
        exitProcess(0)
    }

    val command = args[0]
    val rest = args.drop(1)

    val result: CatatkuResult<String> = when (command) {
        "add" -> handleAdd(list, rest)
        "list" -> handleList(list)
        "count" -> handleCount(list)
        "pending" -> handlePending(list)
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

    when (result) {
        is CatatkuResult.Ok -> { /* handler already printed */ }
        is CatatkuResult.Err -> {
            System.err.println("Error: ${result.error.describe()}")
            exitProcess(1)
        }
    }
}
```

The only changes are the two new branches, `"count" -> handleCount(list)` and `"pending" -> handlePending(list)`. You can also add matching lines such as `|  count                         Show the number of entries` to `printUsage`. Rebuild and try both commands:

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku count
build/install/catatku/bin/catatku pending
```

Output:

```text
3 entries
[ ] (H) 1. Pay rent
[ ] (M) 2. Buy groceries
[ ] (L) 3. Read for fun

3 pending entries
```

All three pre-populated entries are pending at the start of every run, so `pending` shows them all. The implementation reuses everything we have: the `EntryList.all()` method, the `Status.Pending` sealed class variant, the `entry.summary` extension property. Adding a new command takes a few lines and follows the same pattern as the existing handlers.

A subtle detail is the `is Status.Pending` check. Because `Status.Pending` is an object (not a class), we could also have written `it.status == Status.Pending` and gotten the same result, since there is only one `Pending` instance. Both styles work. The `is` form is consistent with the other status checks in the codebase, which is a small reason to prefer it.

For a more sophisticated implementation, you could parameterize the filter: `fun handleByStatus(list: EntryList, statusFilter: (Status) -> Boolean): CatatkuResult<String>`. Then `pending` would call `handleByStatus(list) { it is Status.Pending }`, and you could add similar commands with different lambdas. This is the higher-order function pattern from Lesson 13 applied to CLI handlers.

**Solution for Exercise 3:**

Replace `handleAdd` in `Cli.kt` with:

```kotlin
fun handleAdd(list: EntryList, args: List<String>): CatatkuResult<String> {
    val flagIndex = args.indexOf("--priority")
    val words = if (flagIndex >= 0) args.take(flagIndex) else args
    val priority = if (flagIndex >= 0) {
        when (args.getOrNull(flagIndex + 1)?.uppercase()) {
            "H" -> Priority.HIGH
            "M" -> Priority.MEDIUM
            "L" -> Priority.LOW
            else -> return CatatkuResult.Err(
                CatatkuError.ParseError("--priority must be followed by H, M, or L")
            )
        }
    } else {
        Priority.MEDIUM
    }

    if (words.isEmpty()) {
        return CatatkuResult.Err(CatatkuError.EmptyDescription)
    }
    val description = words.joinToString(" ")
    return when (val r = list.add(description, priority)) {
        is CatatkuResult.Ok -> {
            println("Added entry ${r.value.id}: ${r.value.description} (${r.value.priority.displayName})")
            CatatkuResult.Ok("added")
        }
        is CatatkuResult.Err -> r
    }
}
```

`indexOf("--priority")` returns the flag's position, or `-1` if the user did not type it. The description is every word before the flag (`take(flagIndex)`), or all the words when there is no flag. `getOrNull(flagIndex + 1)` safely reads the value after the flag, and `uppercase()` accepts `h` as well as `H`. Any other value, including a missing one, returns a `ParseError` straight out of the function. The confirmation message now also shows the priority's `displayName`, so you can see that the flag worked. Rebuild and try it:

```bash
./gradlew installDist -q
build/install/catatku/bin/catatku add "Call dentist" --priority H
build/install/catatku/bin/catatku add Water the plants
build/install/catatku/bin/catatku add "Fix bike" --priority X
```

Output:

```text
Added entry 4: Call dentist (High)
Added entry 4: Water the plants (Medium)
Error: Parse error: --priority must be followed by H, M, or L
```

The first command sets the priority from the flag, the second falls back to medium, and the third reports the invalid flag value on stderr with exit code 1. When you are done with the exercises, you can keep them or return `Cli.kt` and `Main.kt` to the versions from Sections 5 and 3; the next lessons start from the main lesson code.

---

## 10. Understanding CLI Design

CLI tools have decades of conventions that make them feel familiar to users. Following these conventions, even informally, makes your tool feel polished.

The first convention is "command-and-arguments" structure. The first argument is usually the command name, and subsequent arguments are the command's parameters. This is Catatku's structure: `catatku add <description>`, `catatku done <id>`, and so on. Tools like git, docker, and npm follow the same pattern. Users who know one CLI tool can usually figure out another quickly because the command structure is consistent.

The second convention is exit codes. Code 0 means success; non-zero means failure. Many shells use this for chaining: `cmd1 && cmd2` runs `cmd2` only if `cmd1` succeeded. CI systems use exit codes to determine whether a build step passed. Without proper exit codes, your tool cannot participate in these scripted workflows, which limits its usefulness.

The third convention is stdout/stderr separation. Successful data goes to stdout; errors and diagnostics go to stderr. This lets users pipe data without seeing errors mixed in: `cat file.txt | catatku list | grep urgent` would only see entries from `list`, not error messages. Tools that violate this (writing errors to stdout) corrupt pipelines and feel broken.

The fourth convention is help. Running with no arguments or with a `help` subcommand should produce a usage message. Users use this to discover what the tool can do and remind themselves of the syntax. A good help message lists the commands, briefly describes each one, and shows examples. Catatku's help message follows this pattern.

The fifth convention is being terse on success and chatty on failure. Successful operations should produce a short confirmation ("Added entry 4: Pay rent") rather than a verbose log. Failures should explain what went wrong, ideally with a hint for fixing it. This matches users' mental models: "if it works, just confirm; if it does not work, tell me why".

For Catatku, we follow these conventions reasonably well: command-and-arguments structure, exit codes 0 and 1, stdout for data and stderr for errors, a help message, and concise success messages with detailed error messages. This is enough to make the tool feel like a "real" CLI rather than a homework exercise.

A more sophisticated CLI might add features like:

Flags and options like `--verbose` or `-v` to enable extra output, `--quiet` or `-q` to suppress confirmation, `--output json` to produce machine-readable output. Each flag is parsed alongside the positional arguments.

Subcommands with their own help, like `catatku add help` to show just the add command's syntax. Tools like git use this heavily.

Configuration files in the user's home directory or current directory, letting users set defaults that apply across runs.

Pipes and redirections, where the tool reads stdin or writes stdout in machine-readable format for use in scripts.

We are not doing any of this for Catatku because the basics are enough. But knowing the patterns exist gives you a vocabulary to recognize good CLI design when you see it and to apply it to your own tools when the situation calls for more sophistication.

---

## Next Up - Lesson 19

Reading command-line arguments through the `args: Array<String>` parameter is straightforward, but writing a polished CLI requires care. Catatku now has a complete command processor: the `main` function dispatches on the first argument using `when`, with branches for each command (`add`, `list`, `done`, `cancel`, `remove`, `help`). Each command has a handler function in `Cli.kt` that validates its arguments, parses numeric inputs with `toIntOrNull`, joins trailing arguments for descriptions and reasons, calls the appropriate `EntryList` method, and reports the result. Errors flow through `CatatkuResult` and are reported to stderr with exit code 1; success cases produce friendly messages on stdout with exit code 0. The structure follows CLI conventions: command-and-arguments syntax, proper exit codes, stdout for data and stderr for errors, and a clear help message. The code is divided across six files in the `com.qadrlabs.catatku` package (`Entry.kt`, `EntryList.kt`, `Errors.kt`, `Stats.kt`, `Cli.kt`, and `Main.kt`), each focused on a specific concern, and `./gradlew installDist` turns it into a `catatku` launcher you can run like any other command.

In Lesson 19 you will add file persistence, replacing the pre-populated warm-up block with code that reads entries from a file at startup and writes them back at shutdown. The format will be a simple tab-separated text format for now, which Lesson 20 will replace with proper JSON serialization.
