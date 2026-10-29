## 1. Before You Begin

Catatku is now a working CLI application with a real domain model, command processing, and JSON persistence. Everything appears to function correctly when we test it manually by running commands and inspecting output. But manual testing has limits. Every change risks breaking something we have not thought to verify. As Catatku grows over time, the time required to manually re-test every feature grows linearly, and our patience does not. The solution is automated tests: small programs that exercise specific behaviors of the application and report whether each one still works as expected. Adding tests is one of the highest-value investments you can make in a codebase, because each test you write is a guard that catches regressions for as long as the codebase exists.

Kotlin's testing story is built on `kotlin.test`, a small library that provides annotations for marking test functions and assertion functions for checking expected outcomes. It runs on top of JUnit 5 (the standard JVM test framework), which integrates with IntelliJ and Gradle so that running tests is a single click or command. By the end of this lesson, Catatku has a small but useful test suite covering the domain types, the `EntryList` operations, the JSON round-trip, and the parsing logic. Future lessons (and any maintenance you do on Catatku afterward) will be safer because the tests will catch regressions before they reach users.

### What You'll Build

Two test files: `EntryListTest.kt` for testing the collection operations and `StorageTest.kt` for testing the JSON serialization round-trip. Each file contains several `@Test` functions that exercise specific behaviors. By the end you can run `./gradlew test` and see a green report showing every test passing.

### What You'll Learn

- ✅ How to organize tests in `src/test/kotlin/` mirroring the production code
- ✅ How to write a test function with `@Test` annotation
- ✅ How to check results with the assertion functions `assertEquals` and `assertTrue`
- ✅ How to organize tests by class and by behavior
- ✅ How to run tests via Gradle and IntelliJ, and how to read a failing test

### What You'll Need

- The complete Catatku project from Lesson 20 with JSON persistence
- About forty-five minutes
- Comfort with the existing `EntryList` and `Storage` modules
- An understanding that tests are small programs that exercise specific behaviors

---

## 2. The Test Directory Structure

Tests live in a parallel directory tree under `src/test/kotlin/` rather than `src/main/kotlin/`. The structure mirrors the production code: tests for code in `com.qadrlabs.catatku` go in `src/test/kotlin/com/qadrlabs/catatku/`. This convention is universal across JVM projects, and Gradle automatically compiles and runs everything in `src/test/kotlin/` when you invoke the test task.

### Step 1: Create the Test Directory

If your project does not already have it, create the directory structure:

```text
src/test/kotlin/
└── com/
    └── qadrlabs/
        └── catatku/
```

You can do this in IntelliJ (right-click on `src/test/kotlin`, choose New > Package and type `com.qadrlabs.catatku`) or from a terminal (`mkdir -p src/test/kotlin/com/qadrlabs/catatku` on macOS or Linux). Either way, the result is the same.

### Step 2: Configure the Test Task

The Catatku project from Lesson 2 onwards includes `testImplementation(kotlin("test"))` in `build.gradle.kts`. This pulls in `kotlin.test` for use in test code (but not in production code, which is what `testImplementation` means as opposed to `implementation`). The `kotlin("test")` is shorthand for "the kotlin-test library matching this project's Kotlin version". It includes the assertion functions and integrates with JUnit 5 for the test runner.

The block `tasks.test { useJUnitPlatform() }` configures Gradle's test task to use JUnit 5's Platform runner; without it, Gradle would not find the tests. By default, Gradle prints only "BUILD SUCCESSFUL" when tests pass, without naming them. To see each test in the terminal, add a `testLogging` block. Update `build.gradle.kts` so the whole file looks like this:

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
    testLogging {
        events("passed", "skipped", "failed")
    }
}

kotlin {
    jvmToolchain(17)
}
```

The only change is the `testLogging` block inside `tasks.test`. `events("passed", "skipped", "failed")` tells Gradle to print one line for each test that passes, is skipped, or fails.

### Step 3: Verify with a Trivial Test

Create a file `src/test/kotlin/com/qadrlabs/catatku/SmokeTest.kt`:

```kotlin
package com.qadrlabs.catatku

import kotlin.test.Test
import kotlin.test.assertEquals

class SmokeTest {
    @Test
    fun `addition works`() {
        assertEquals(4, 2 + 2)
    }
}
```

Save. Now run the tests from the terminal:

```bash
./gradlew test
```

Gradle first prints its usual task lines; the part that matters is at the end. Output:

```text
> Task :test

SmokeTest > addition works() PASSED

BUILD SUCCESSFUL in 1s
3 actionable tasks: 1 executed, 2 up-to-date
```

The time and the task counts vary from run to run. From IntelliJ, you can instead click the small green triangle next to the test class or function name.

The test passed, which confirms the test infrastructure works. The test function is annotated with `@Test`, takes no parameters, and returns nothing useful (`Unit`). Inside, we call `assertEquals(expected, actual)`. If the values match, the test passes silently; if they do not, the test fails with a descriptive message.

The function name is `` `addition works` `` (in backticks). Kotlin allows arbitrary names for functions, including names with spaces, when wrapped in backticks. This is conventional for test names because test names should read like documentation: "addition works", "empty list returns null", "marking done changes status". Backtick names are usually used only for test names, never for production code. The report adds `()` after each name because, underneath, every test is a function.

Once you have seen it pass, delete `SmokeTest.kt`; the real tests replace it.

Gradle only reruns tests when something changed. If you run `./gradlew test` twice in a row without editing anything, the second run says `> Task :test UP-TO-DATE` and prints no test lines. Add `--rerun` (`./gradlew test --rerun`) to force the tests to run again.

---

## 3. Testing EntryList

The `EntryList` class is the central piece of Catatku's logic. Its operations (add, find, mark done, cancel, remove) need to be tested. We will build one test class step by step: Step 1 creates the file, and each later step adds more `@Test` functions inside the same class, just before its closing brace.

### Step 1: Test that add Increments Ids

Create `src/test/kotlin/com/qadrlabs/catatku/EntryListTest.kt`:

```kotlin
package com.qadrlabs.catatku

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class EntryListTest {
    @Test
    fun `add assigns increasing ids`() {
        val list = EntryList()

        val first = list.add("First task")
        val second = list.add("Second task")
        val third = list.add("Third task")

        assertTrue(first is CatatkuResult.Ok)
        assertTrue(second is CatatkuResult.Ok)
        assertTrue(third is CatatkuResult.Ok)

        assertEquals(1, (first as CatatkuResult.Ok).value.id)
        assertEquals(2, (second as CatatkuResult.Ok).value.id)
        assertEquals(3, (third as CatatkuResult.Ok).value.id)
    }
}
```

Walk through what is happening. We create a fresh `EntryList`, call `add` three times, and check that the returned entries have ids 1, 2, and 3. Every test creates its own `EntryList`, so tests never share state and can run in any order.

The `assertTrue(first is CatatkuResult.Ok)` line confirms that the result is an `Ok` variant, not an `Err`. If it is not, the test stops right there with a clear failure. The `(first as CatatkuResult.Ok).value.id` then accesses the entry's id from inside the `Ok` variant. The explicit cast is needed because `assertTrue` does not tell the compiler anything about the type; it is safe because the line above just verified it.

Run `./gradlew test`. The report shows `EntryListTest > add assigns increasing ids() PASSED`.

### Step 2: Test the Empty Description Error

Add two more test functions inside the `EntryListTest` class:

```kotlin
@Test
fun `add rejects empty description`() {
    val list = EntryList()

    val result = list.add("")

    assertTrue(result is CatatkuResult.Err)
    assertEquals(CatatkuError.EmptyDescription, (result as CatatkuResult.Err).error)
}

@Test
fun `add rejects blank description`() {
    val list = EntryList()

    val result = list.add("   ")

    assertTrue(result is CatatkuResult.Err)
    assertEquals(CatatkuError.EmptyDescription, (result as CatatkuResult.Err).error)
}
```

These tests verify that empty and whitespace-only descriptions produce the expected error. We pass the bad input, capture the result, and assert that it is an `Err` with the right variant. Comparing with `assertEquals(CatatkuError.EmptyDescription, ...)` works because `EmptyDescription` is an `object`, so there is exactly one instance. Each test exercises one specific behavior, which makes failures easy to localize: if the "rejects empty" test fails but "rejects blank" passes, you know the empty-string check is broken but the blank check works.

### Step 3: Test markDone

Add two tests for the `markDone` operation inside the class:

```kotlin
@Test
fun `markDone updates status`() {
    val list = EntryList()
    list.add("Pay rent")

    val result = list.markDone(1)

    assertTrue(result is CatatkuResult.Ok)
    val updated = (result as CatatkuResult.Ok).value
    assertTrue(updated.status is Status.Done)
    assertEquals(1, updated.id)
}

@Test
fun `markDone returns EntryNotFound for unknown id`() {
    val list = EntryList()
    list.add("Pay rent")

    val result = list.markDone(99)

    assertTrue(result is CatatkuResult.Err)
    val error = (result as CatatkuResult.Err).error
    assertTrue(error is CatatkuError.EntryNotFound)
    assertEquals(99, (error as CatatkuError.EntryNotFound).id)
}
```

The first test adds an entry, marks it done, and verifies that the status changed to `Status.Done`. The second test attempts to mark a non-existent entry done and verifies the error is `EntryNotFound` with the right id. The pattern of "set up, perform action, assert outcome" is called Arrange-Act-Assert and is the foundation of unit testing; the blank lines inside each test separate those three parts.

### Step 4: Test cancel and remove

Add three tests for `cancel` and `remove` inside the class:

```kotlin
@Test
fun `cancel sets the reason`() {
    val list = EntryList()
    list.add("Pay rent")

    val result = list.cancel(1, "rescheduled")

    assertTrue(result is CatatkuResult.Ok)
    val updated = (result as CatatkuResult.Ok).value
    assertTrue(updated.status is Status.Cancelled)
    assertEquals("rescheduled", (updated.status as Status.Cancelled).reason)
}

@Test
fun `remove deletes the entry`() {
    val list = EntryList()
    list.add("Pay rent")
    list.add("Buy groceries")

    val result = list.remove(1)

    assertTrue(result is CatatkuResult.Ok)
    assertEquals(1, list.size)
    assertEquals("Buy groceries", list.all().first().description)
}

@Test
fun `remove returns EntryNotFound for unknown id`() {
    val list = EntryList()
    list.add("Pay rent")

    val result = list.remove(99)

    assertTrue(result is CatatkuResult.Err)
    assertEquals(1, list.size)
}
```

The `cancel sets the reason` test verifies that the status becomes `Cancelled` with the right reason. The `remove deletes the entry` test verifies both the result and the side effect on the list (the size decreases, the remaining entry is the right one). The `remove returns EntryNotFound for unknown id` test verifies that nothing is removed when the id is not found.

### Step 5: Test findById

Add the last two `EntryList` tests inside the class:

```kotlin
@Test
fun `findById returns the matching entry`() {
    val list = EntryList()
    list.add("First")
    list.add("Second")
    list.add("Third")

    val result = list.findById(2)

    assertTrue(result is CatatkuResult.Ok)
    assertEquals("Second", (result as CatatkuResult.Ok).value.description)
}

@Test
fun `findById returns error when not found`() {
    val list = EntryList()
    list.add("First")

    val result = list.findById(99)

    assertTrue(result is CatatkuResult.Err)
    assertEquals(CatatkuError.EntryNotFound(99), (result as CatatkuResult.Err).error)
}
```

The second test compares the whole error with `assertEquals(CatatkuError.EntryNotFound(99), ...)`. That works because `EntryNotFound` is a data class, so two instances with the same id are equal. These complete the basic `EntryList` coverage: ten tests that exercise the main operations and their error cases. Run `./gradlew test` and check that all ten pass.

---

## 4. Testing the JSON Round-Trip

The JSON serialization layer should be tested too. The most important property is that encoding and then decoding produces the same value, the round-trip property.

### Step 1: Set Up the Storage Test

Create `src/test/kotlin/com/qadrlabs/catatku/StorageTest.kt`:

```kotlin
package com.qadrlabs.catatku

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class StorageTest {
    private val json = Json {
        prettyPrint = true
        encodeDefaults = true
        ignoreUnknownKeys = true
    }
}
```

The test class has the same `Json` configuration as the production code. The production `json` in `Storage.kt` is `private`, so the test keeps its own copy; the same settings on encode and decode ensure the round-trip behaves like the real application. The `File` import is for the file tests in Section 5. As in Section 3, the following steps add test functions inside this class.

### Step 2: Test the Pending Status Round-Trip

Add a test function inside `StorageTest`:

```kotlin
@Test
fun `Entry with pending status round-trips through JSON`() {
    val original = Entry(
        id = 1,
        description = "Pay rent",
        priority = Priority.HIGH,
        status = Status.Pending
    )

    val encoded = json.encodeToString(original)
    val decoded: Entry = json.decodeFromString(encoded)

    assertEquals(original, decoded)
}
```

The entry encodes to JSON, decodes back, and the structural equality check confirms that the result is the same as the original. This works because data classes have generated `equals` based on all primary-constructor fields, and `Status.Pending` is a single object instance.

### Step 3: Test All Status Variants

Add tests for the other statuses inside the class:

```kotlin
@Test
fun `Entry with done status round-trips through JSON`() {
    val original = Entry(2, "Buy groceries", Priority.MEDIUM, Status.Done)
    val encoded = json.encodeToString(original)
    val decoded: Entry = json.decodeFromString(encoded)
    assertEquals(original, decoded)
}

@Test
fun `Entry with in-progress status round-trips through JSON`() {
    val original = Entry(3, "Read book", Priority.LOW, Status.InProgress)
    val encoded = json.encodeToString(original)
    val decoded: Entry = json.decodeFromString(encoded)
    assertEquals(original, decoded)
}

@Test
fun `Entry with cancelled status round-trips through JSON including reason`() {
    val original = Entry(4, "Walk dog", Priority.MEDIUM, Status.Cancelled("rainy day"))
    val encoded = json.encodeToString(original)
    val decoded: Entry = json.decodeFromString(encoded)

    assertEquals(original, decoded)
    assertTrue(decoded.status is Status.Cancelled)
    assertEquals("rainy day", (decoded.status as Status.Cancelled).reason)
}
```

Each test verifies that one specific variant of `Status` survives the round-trip. The cancelled-status test additionally checks that the reason field is preserved. If one of them failed (perhaps because a variant lost its `@Serializable`), the failure would point at exactly which variant is broken.

### Step 4: Test a List Round-Trip

The application stores a list of entries, not a single entry. Add a test for the list round-trip inside the class:

```kotlin
@Test
fun `List of entries round-trips through JSON`() {
    val original = listOf(
        Entry(1, "First", Priority.HIGH, Status.Pending),
        Entry(2, "Second", Priority.MEDIUM, Status.Done),
        Entry(3, "Third", Priority.LOW, Status.Cancelled("test"))
    )

    val encoded = json.encodeToString(original)
    val decoded: List<Entry> = json.decodeFromString(encoded)

    assertEquals(original, decoded)
    assertEquals(3, decoded.size)
}
```

This is the test most directly relevant to Catatku's storage layer because the production code encodes and decodes `List<Entry>`. Comparing two lists with `assertEquals` checks size, order, and every element, so the round-trip must preserve all three.

### Step 5: Test Edge Cases

Add a test for an empty list inside the class:

```kotlin
@Test
fun `Empty list round-trips through JSON`() {
    val original: List<Entry> = emptyList()
    val encoded = json.encodeToString(original)
    val decoded: List<Entry> = json.decodeFromString(encoded)

    assertEquals(original, decoded)
    assertTrue(decoded.isEmpty())
}
```

Empty lists are a common edge case in serialization: a freshly emptied Catatku saves an empty array. This test confirms the empty case encodes and decodes cleanly.

---

## 5. Testing Integration: loadEntries and saveEntries

The `loadEntries` and `saveEntries` functions handle the file I/O. Testing them requires writing to and reading from actual files, so the tests use temporary files that never touch your real `~/.catatku/entries.json`.

### Step 1: Use a Temporary File

Add an integration test inside `StorageTest`:

```kotlin
@Test
fun `saveEntries and loadEntries round-trip through a real file`() {
    val tempFile = File.createTempFile("catatku-test", ".json")
    tempFile.deleteOnExit()  // clean up when JVM exits

    try {
        val original = listOf(
            Entry(1, "First", Priority.HIGH, Status.Pending),
            Entry(2, "Second", Priority.MEDIUM, Status.Done)
        )

        // Save
        val saveResult = saveEntries(tempFile, original)
        assertTrue(saveResult is CatatkuResult.Ok)

        // Load
        val loadResult = loadEntries(tempFile)
        assertTrue(loadResult is CatatkuResult.Ok)

        val loaded = (loadResult as CatatkuResult.Ok).value
        assertEquals(original, loaded)
    } finally {
        tempFile.delete()
    }
}
```

The test uses `File.createTempFile`, which creates a new, uniquely named empty file in the system's temp directory on every operating system. We call `deleteOnExit()` and also delete the file in the `finally` block to ensure cleanup even if an assertion fails. The actual test logic is: save the entries to the temp file, load them back, and verify that the round-trip produces the same list.

This is an integration test because it exercises multiple components together (the encoder, the file I/O, the atomic move, the decoder), as opposed to the unit tests that exercised one component in isolation.

### Step 2: Test Loading a Non-Existent File

Loading from a file that does not exist should return an empty list (the "first run" case). Add inside the class:

```kotlin
@Test
fun `loadEntries returns empty list when file does not exist`() {
    val nonExistent = File.createTempFile("catatku-missing", ".json")
    nonExistent.delete()

    val result = loadEntries(nonExistent)

    assertTrue(result is CatatkuResult.Ok)
    assertTrue((result as CatatkuResult.Ok).value.isEmpty())
}
```

Creating a temp file and deleting it immediately is a simple way to get a unique path that is guaranteed not to exist, in a folder that exists on every operating system. The test verifies that the load returns `Ok(emptyList())` rather than an error.

### Step 3: Test Loading Invalid JSON

The error path is also worth testing. Add a test that writes malformed JSON to a temp file and verifies that loading produces a parse error:

```kotlin
@Test
fun `loadEntries returns parse error for malformed JSON`() {
    val tempFile = File.createTempFile("catatku-bad", ".json")
    tempFile.deleteOnExit()

    try {
        tempFile.writeText("this is not valid json {")

        val result = loadEntries(tempFile)

        assertTrue(result is CatatkuResult.Err)
        assertTrue((result as CatatkuResult.Err).error is CatatkuError.ParseError)
    } finally {
        tempFile.delete()
    }
}
```

The test writes a clearly invalid JSON string to the file, attempts to load it, and verifies that the result is an `Err` with a `ParseError`. The exact error message could change between library versions, so the test checks only the variant type, which is what the rest of Catatku relies on. We have now covered the success path, the empty path, and the failure path of `loadEntries`.

---

## 6. Running and Organizing Tests

With 19 tests in two classes, the test suite is small but useful. Let us look at how it integrates with the build.

### Step 1: Run All Tests

From a terminal:

```bash
./gradlew test
```

Output (the part after Gradle's task lines):

```text
> Task :test

EntryListTest > findById returns error when not found() PASSED

EntryListTest > cancel sets the reason() PASSED

EntryListTest > add rejects blank description() PASSED

EntryListTest > remove returns EntryNotFound for unknown id() PASSED

EntryListTest > markDone returns EntryNotFound for unknown id() PASSED

EntryListTest > markDone updates status() PASSED

EntryListTest > add rejects empty description() PASSED

EntryListTest > findById returns the matching entry() PASSED

EntryListTest > remove deletes the entry() PASSED

EntryListTest > add assigns increasing ids() PASSED

StorageTest > Entry with in-progress status round-trips through JSON() PASSED

StorageTest > loadEntries returns parse error for malformed JSON() PASSED

StorageTest > List of entries round-trips through JSON() PASSED

StorageTest > Entry with cancelled status round-trips through JSON including reason() PASSED

StorageTest > Entry with done status round-trips through JSON() PASSED

StorageTest > Entry with pending status round-trips through JSON() PASSED

StorageTest > Empty list round-trips through JSON() PASSED

StorageTest > saveEntries and loadEntries round-trip through a real file() PASSED

StorageTest > loadEntries returns empty list when file does not exist() PASSED

BUILD SUCCESSFUL in 1s
3 actionable tasks: 2 executed, 1 up-to-date
```

Every test passes. The output lists each test by its class and human-readable name, which is exactly the kind of summary that makes test runs useful: at a glance you can see what was tested and what passed. Notice that the order is not the order in the source file. JUnit does not promise any particular order, which is one more reason each test sets up its own data.

### Step 2: View the HTML Report

After running tests, Gradle generates an HTML report at `build/reports/tests/test/index.html`. Open it in a browser to see a structured view of the test results, including any failures with their full messages and stack traces. For passing builds the report is mostly informational, but for failing builds it is enormously useful for diagnosing what went wrong.

### Step 3: Run Tests in IntelliJ

In IntelliJ, you can run individual tests, all tests in a class, or all tests in the project from the IDE. Click the green triangle icon next to a test function to run just that test; click the icon next to a test class to run all tests in that class. The results appear in the Run tool window as a tree of passed and failed tests, and you can click on a failing assertion to jump to its location in the source.

For day-to-day development, running a single test class in IntelliJ is faster than running the whole suite. As a habit, run tests frequently while working on the code: every time you finish a logical unit of change, run the relevant tests to make sure nothing is broken.

---

## 7. Run and Test

The tests we have written form a small but representative suite. Let us verify everything works end to end, including what a failure looks like.

### Step 1: Verify All Tests Pass

Run `./gradlew test` and confirm that all 19 tests pass, as in Section 6. If any test fails, the failure line tells you which test and where. Read the message carefully and fix the issue.

### Step 2: Add a Failing Test to See What That Looks Like

To experience the test failure flow, deliberately add a wrong test inside `EntryListTest`:

```kotlin
@Test
fun `intentionally failing test`() {
    assertEquals(5, 2 + 2)
}
```

Run `./gradlew test`. Among the other results, the output now includes:

```text
> Task :test FAILED

EntryListTest > intentionally failing test() FAILED
    org.opentest4j.AssertionFailedError at EntryListTest.kt:134
```

The build ends with `BUILD FAILED`. The terminal tells you which test failed, the kind of failure, and the file and line number of the assertion (the line number depends on where you placed the test). Open the HTML report from Section 6 to read the full message: `expected: <5> but was: <4>`. This is what working with tests looks like: when something is wrong, the failing test gives you a precise diagnosis rather than a vague crash.

Remove the failing test before continuing.

### Step 3: Run the Tests After Making a Change

To see the safety net in action, deliberately break something in the production code. Open `EntryList.kt` and change the id counter to start at 0 instead of 1:

```kotlin
private var nextId: Int = 0  // was 1
```

Run `./gradlew test`. This time five tests fail: `add assigns increasing ids`, `markDone updates status`, `cancel sets the reason`, `remove deletes the entry`, and `findById returns the matching entry`. The summary line says `19 tests completed, 5 failed`. In the HTML report, `add assigns increasing ids` shows exactly what changed:

```text
org.opentest4j.AssertionFailedError: expected: <1> but was: <0>
```

The other failures are consequences of the same change: `findById returns the matching entry` reports `expected: <Second> but was: <Third>`, because id 2 now belongs to the third entry. This is the regression-prevention purpose of tests: one small mistake in the production code lights up every behavior it affects. Without the tests, you might not notice that the id sequence shifted; with them, the failure is immediate and the cause is obvious.

Restore the original `nextId: Int = 1` and confirm the tests pass again.

---

## 8. Fix the Errors in Your Code

Three test-related mistakes are common.

**Error 1: Putting tests in the main source folder**

```kotlin
// Wrong: src/main/kotlin/com/qadrlabs/catatku/EntryListTest.kt
package com.qadrlabs.catatku

import kotlin.test.Test

// Correct: src/test/kotlin/com/qadrlabs/catatku/EntryListTest.kt
package com.qadrlabs.catatku

import kotlin.test.Test
```

The two files can be identical; only the folder differs. In `src/main/kotlin`, the file is part of the production source set, which only has access to `implementation` dependencies. `kotlin-test` is a `testImplementation` dependency, so the production build cannot see it, and the build fails with `Unresolved reference 'test'.` on the import line. Even if it compiled, the tests would ship inside your application. The fix is to move test files to `src/test/kotlin/`, mirroring the production package.

**Error 2: Forgetting the @Test annotation**

```kotlin
// Wrong
fun `add rejects empty description`() {
    val result = EntryList().add("")
    assertTrue(result is CatatkuResult.Err)
}

// Correct
@Test
fun `add rejects empty description`() {
    val result = EntryList().add("")
    assertTrue(result is CatatkuResult.Err)
}
```

The function looks like a test and has assertions, but without `@Test` the runner never calls it. Nothing fails; the test just silently disappears from the report, so the behavior it was supposed to protect is unprotected. The fix is to add `@Test` (imported from `kotlin.test`). As a habit, check that the number of tests in the report grows when you add a test.

**Error 3: Testing implementation details instead of behavior**

```kotlin
// Wrong: depends on the exact JSON text
assertEquals("""{"id":1,"description":"Pay rent"}""", json.encodeToString(original))

// Correct: depends only on the round-trip behavior
val decoded: Entry = json.decodeFromString(json.encodeToString(original))
assertEquals(original, decoded)
```

The wrong version breaks as soon as anything about the formatting changes: pretty-printing, field order, or `encodeDefaults`. With the `Json` settings from this lesson it already fails, because the real output is indented and contains every field. None of those changes are bugs. The correct version tests what callers actually rely on: whatever is saved can be loaded back unchanged. As a habit, ask "what would a user of this code see as broken?" The answers to that question are the behaviors worth testing.

---

## 9. Exercises

These exercises practice writing tests.

**Exercise 1:** Write a test class `EntryFormattingTest.kt` that tests the `Entry.summary` extension property. Test that the summary for a pending entry has `[ ]`, for a done entry has `[x]`, for an in-progress entry has `[~]`, and for a cancelled entry has `[!]`. Use `assertEquals` to check the expected output strings.

**Exercise 2:** Write a test that verifies the `EntryList.activeOnly()` filter returns only entries whose status is `Pending` or `InProgress`. Add several entries with different statuses, call `activeOnly()`, and assert on the resulting list size and contents.

**Exercise 3:** Write a test that verifies adding an entry then loading from disk preserves the data correctly. The test should: create a temp file, set up an `EntryList`, add an entry, save with `saveEntries`, load with `loadEntries`, and assert that the loaded list contains the same entry.

---

## 10. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

Create `src/test/kotlin/com/qadrlabs/catatku/EntryFormattingTest.kt`:

```kotlin
package com.qadrlabs.catatku

import kotlin.test.Test
import kotlin.test.assertEquals

class EntryFormattingTest {
    @Test
    fun `summary uses correct marker for pending`() {
        val entry = Entry(1, "Pay rent", Priority.HIGH, Status.Pending)
        assertEquals("[ ] (H) 1. Pay rent", entry.summary)
    }

    @Test
    fun `summary uses correct marker for done`() {
        val entry = Entry(2, "Buy groceries", Priority.MEDIUM, Status.Done)
        assertEquals("[x] (M) 2. Buy groceries", entry.summary)
    }

    @Test
    fun `summary uses correct marker for in progress`() {
        val entry = Entry(3, "Read book", Priority.LOW, Status.InProgress)
        assertEquals("[~] (L) 3. Read book", entry.summary)
    }

    @Test
    fun `summary uses correct marker for cancelled`() {
        val entry = Entry(4, "Walk dog", Priority.MEDIUM, Status.Cancelled("rainy"))
        assertEquals("[!] (M) 4. Walk dog", entry.summary)
    }
}
```

Each test constructs an entry with a specific status and asserts that `entry.summary` produces the expected string. The expected strings follow the `summary` logic in `Entry.kt`: the status marker, the first letter of the priority in parentheses, the id, and the description. Run `./gradlew test`. The new lines in the report are:

```text
EntryFormattingTest > summary uses correct marker for cancelled() PASSED
EntryFormattingTest > summary uses correct marker for done() PASSED
EntryFormattingTest > summary uses correct marker for in progress() PASSED
EntryFormattingTest > summary uses correct marker for pending() PASSED
```

(Gradle prints an empty line between test lines; they are left out here.) This kind of test is useful because the summary is user-visible output: if the format ever changes accidentally, these tests catch it immediately.

**Solution for Exercise 2:**

Add this test inside `EntryListTest`:

```kotlin
@Test
fun `activeOnly returns pending and in-progress entries`() {
    val list = EntryList()
    list.add("Pay rent")
    list.add("Buy groceries")
    list.add("Read book")
    list.add("Walk dog")
    list.markDone(2)
    list.cancel(3, "no time")
    list.addPreserveId(Entry(5, "Write report", status = Status.InProgress))

    val active = list.activeOnly()

    assertEquals(3, active.size)
    assertEquals(listOf(1, 4, 5), active.map { it.id })
    assertTrue(active.all { it.status is Status.Pending || it.status is Status.InProgress })
}
```

The list ends up with every kind of status: entries 1 and 4 are pending, 2 is done, 3 is cancelled, and 5 is in progress. `EntryList` has no method for "in progress", so the test inserts entry 5 directly with `addPreserveId`. That function is `internal`, and test code in the same Gradle module can call `internal` functions, which is exactly the visibility rule from Lesson 17. The assertions check the count, the exact ids in order, and, with `all { ... }`, that every returned entry really is pending or in progress. Run `./gradlew test`. The new line in the report is:

```text
EntryListTest > activeOnly returns pending and in-progress entries() PASSED
```

**Solution for Exercise 3:**

Add this test inside `StorageTest`:

```kotlin
@Test
fun `entries added to an EntryList survive save and load`() {
    val tempFile = File.createTempFile("catatku-list", ".json")
    tempFile.deleteOnExit()

    try {
        val list = EntryList()
        list.add("Pay rent", Priority.HIGH)
        list.cancel(1, "paid early")

        val saveResult = saveEntries(tempFile, list.all())
        assertTrue(saveResult is CatatkuResult.Ok)

        val loadResult = loadEntries(tempFile)
        assertTrue(loadResult is CatatkuResult.Ok)

        val loaded = (loadResult as CatatkuResult.Ok).value
        assertEquals(list.all(), loaded)
        assertEquals(Status.Cancelled("paid early"), loaded.first().status)
    } finally {
        tempFile.delete()
    }
}
```

This test connects the two halves of the application: entries are created through `EntryList`, the way the CLI creates them, and then go through the real save and load functions. Comparing `list.all()` with the loaded list checks every field, and the last assertion checks the cancelled status, including its reason, explicitly. Run `./gradlew test`. The new line in the report is:

```text
StorageTest > entries added to an EntryList survive save and load() PASSED
```

With all three exercises, the suite grows from 19 to 25 tests.

---

## 11. Understanding the Value of Tests

Adding tests is one of the most controversial topics in software development. Some teams have extensive test suites with thousands of tests; others have almost none. Both approaches have proponents, but for almost all projects, having some tests is dramatically better than having none. Understanding why helps you decide what to test and how much.

The most concrete benefit of tests is regression prevention. A test you wrote a year ago is still running on every build, checking that the behavior you cared about then still works today. As your codebase grows, the surface area of "things that could be broken by a change" grows too, and tests are the only practical way to keep that surface manageable. Without tests, every change risks breaking something nobody thinks to verify; with tests, the failures are immediate and localized to the broken behavior.

The second benefit is documentation. A test names a behavior and demonstrates it with code. Reading tests is a fast way to understand what a system does without reading the implementation. When tests have descriptive names like "add rejects empty description" or "remove deletes the entry", they tell you both what the code is supposed to do and how to call it. New team members can read the tests to learn the codebase, and future you can read them to remember how something worked.

The third benefit is design feedback. Code that is hard to test is usually code that is hard to use. If you find that writing a test for a function requires extensive setup, the function probably has too many dependencies or too many responsibilities. Tests force you to confront this and refactor toward simpler, more focused code. This effect is most visible in unit tests, which exercise small components in isolation; integration tests are less prescriptive about design.

The fourth benefit is confidence. Knowing that the test suite passes gives you confidence to refactor, to ship a release, or to make a risky change. Without tests, every change feels like a gamble: maybe it works, maybe it breaks something. With tests, you can change the code aggressively, rerun the tests, and trust that anything that was working before is still working.

The cost of tests is that they take time to write and maintain. Tests are code, and code is liability: it can have bugs, it has to be updated when the production code changes, it adds to the codebase's overall size. If you write tests that are flaky (sometimes pass, sometimes fail), or that test the wrong things, or that are too tightly coupled to implementation details, you make the project harder to maintain rather than easier. The skill of writing good tests, ones that catch real bugs without being a maintenance burden, takes years to develop, and even experienced programmers disagree about specific cases.

For Catatku and most application code, the right balance is to have tests for the most important behaviors, focusing on the public interfaces and observable outcomes. We tested `EntryList`'s public methods, the JSON round-trip, and the file I/O integration. We did not test private helpers or internal data structures, because those would require knowledge of the implementation and would couple the tests to specific design choices. If the implementation changes (perhaps we switch from a list to a map for fast lookup), the tests should still pass without modification because they only depend on the public interface.

A useful rule of thumb is "test the API, not the implementation". The API is what callers depend on; if the API behavior is correct, the implementation can be anything. The implementation is what you might change to optimize or refactor; if you test it, your tests become brittle and discourage improvement. By testing only the API, you get the regression-catching benefit without the maintenance burden.

The deeper lesson is that tests are a tool, and like all tools they have a sweet spot. Too few tests and you have no safety net; too many tests, especially poorly chosen ones, and the maintenance cost overwhelms the benefit. The right amount depends on the project's stability requirements, the team's familiarity with the codebase, and the cost of failures in production. Over time, you develop a sense of what to test, what to skip, and what to refactor when tests are hard to write. The investment is worth it because high-quality test suites are one of the things that distinguish maintainable codebases from fragile ones.

---

## Next Up - Lesson 22

Catatku now has a test suite that exercises its main behaviors automatically. The test files live under `src/test/kotlin/` mirroring the production packages, with `EntryListTest.kt` covering the collection operations and `StorageTest.kt` covering the JSON round-trip and file I/O. Each test is a small function annotated with `@Test`, using assertion functions like `assertEquals` and `assertTrue` to check expected outcomes. Tests run via `./gradlew test` from the terminal or via the green triangle icons in IntelliJ. The suite catches regressions automatically: any change that breaks an existing behavior produces a clear failure message pointing at the broken case. The investment of writing 19 tests pays back continuously as the codebase evolves, and the tests serve as documentation for what the application is supposed to do.

In Lesson 22, the final lesson, we will wrap up Catatku and the course. We will recap what was built, look at the final file structure, discuss what the course did not cover (coroutines, Android, web frameworks, multiplatform), and recommend next steps for continuing your Kotlin journey. The code is complete; what remains is reflection on the journey and direction for the future.
