## 1. Before You Begin

Every interesting program eventually has to make decisions and repeat operations. Should we mark a task as done or as cancelled? Should we keep prompting the user for input until they enter something valid? Should we print all the high-priority tasks first, or all of them in id order? Control flow is the part of a language that handles these decisions and repetitions, and Kotlin's approach builds on the same constructs you would expect from any modern language while adding two important twists. The first twist is that `if` and `when` are expressions rather than statements, meaning they return values you can capture in variables. The second twist is `when` itself, which is a vastly more powerful version of the `switch` statement from C-family languages and one of the features that immediately marks code as Kotlin rather than Java.

This lesson covers `if` and its expression form, `when` with all its capabilities (matching values, ranges, types, predicates), the three loop constructs (`for`, `while`, `do-while`), and the keywords for jumping around inside loops (`break`, `continue`, and labels). The examples are still small (we are not yet building real Catatku features), but every pattern you practice here will reappear in later lessons. By the end you will know which control-flow construct to reach for in each situation, and you will be writing in the expression-oriented style that distinguishes idiomatic Kotlin from a transliteration of Java.

### What You'll Build

A series of small experiments inside `Main.kt` that demonstrate each control-flow construct. You will write a numeric grade classifier using `if` as an expression, a status-marker selector using `when`, a loop that counts through a range and another that walks through a list, a small input-validation pattern using `while`, and a final example that combines `for` with `when` to print a Catatku-style task list. By the end, the basic vocabulary of control flow in Kotlin is in your hands.

### What You'll Learn

- ✅ How `if`/`else` works as both a statement and an expression
- ✅ How `when` matches values, ranges, types, and arbitrary predicates
- ✅ How `for` iterates over ranges, collections, and string characters
- ✅ When to use `while` versus `do-while` versus `for`
- ✅ How `break` and `continue` work, including with labeled loops

### What You'll Need

- The `catatku` Gradle project from the previous lessons, with IntelliJ IDEA open
- A working understanding of `val` and `var` from Lesson 4
- About thirty-five minutes
- Willingness to type each example and run it before reading the next one

---

## 2. The if Expression

Most languages treat `if` as a statement that runs different blocks of code depending on a condition, but does not produce a value. Kotlin treats `if` as an expression that returns a value, the same way that addition or function calls return values. This is the same idea as the ternary operator (`condition ? a : b`) in C and Java, but generalized to all `if` chains and using normal `if`/`else` syntax. Once you internalize this, a lot of common code patterns become noticeably shorter.

### Step 1: Write a Standard if as a Statement

Open `Main.kt` and replace its body with a familiar-looking grade classifier:

```kotlin
fun main() {
    val score = 78
    
    if (score >= 90) {
        println("Grade: A")
    } else if (score >= 80) {
        println("Grade: B")
    } else if (score >= 70) {
        println("Grade: C")
    } else if (score >= 60) {
        println("Grade: D")
    } else {
        println("Grade: F")
    }
}
```

Save and run. Output:

```text
Grade: C
```

The program prints "Grade: C" because 78 falls into the 70 to 79 range. This usage looks like `if` in Java or C: parentheses around the condition, curly braces around each block, and `else if` to chain alternatives. The braces are optional when the body is a single statement (you could write `if (score >= 90) println("Grade: A")` without braces), but most code uses them for consistency and to avoid bugs when the body grows.

The condition is a `Boolean` expression. Kotlin is strict here: you cannot use a non-boolean as a condition the way C and JavaScript let you write `if (count)` to mean "if count is non-zero". You have to write `if (count != 0)` or `if (count > 0)` explicitly. This strictness eliminates a class of bugs and makes the meaning of every condition clear.

### Step 2: Capture the if as an Expression

Now the same logic written as an expression. The whole `if`/`else if`/`else` chain produces a value, which we capture in a variable.

```kotlin
fun main() {
    val score = 78
    
    val grade = if (score >= 90) {
        "A"
    } else if (score >= 80) {
        "B"
    } else if (score >= 70) {
        "C"
    } else if (score >= 60) {
        "D"
    } else {
        "F"
    }
    
    println("Grade: $grade")
}
```

Save and run. Output:

```text
Grade: C
```

The output is the same, but the structure is different. The `if` chain is now on the right side of `val grade = ...`, and the entire chain evaluates to a single string ("A", "B", "C", "D", or "F") that gets bound to `grade`. Each branch is a block that ends with a string literal, which becomes the value of that branch.

Two rules govern this expression form. First, every branch must produce the same type, or at least types that have a common supertype. If one branch returned `"A"` (a `String`) and another returned `5` (an `Int`), the compiler would refuse because the variable on the left cannot be both. Try changing one branch to return an integer and watch the error message; the error tells you exactly what went wrong.

Second, when an `if` is used as an expression, the `else` branch is required. The compiler needs to know what value the expression takes when the condition is false; without an `else`, that case is undefined. As a statement (where the result is not captured), `else` is optional, but as an expression it is mandatory.

### Step 3: Use the Single-Line if Expression

For simple two-branch cases, you can write the `if` expression on a single line, similar to a ternary operator:

```kotlin
fun main() {
    val score = 78
    val passing = if (score >= 60) "yes" else "no"
    val marker = if (score >= 90) "★" else " "
    
    println("Score: $score")
    println("Passing: $passing")
    println("Marker: '$marker'")
}
```

Save and run. Output:

```text
Score: 78
Passing: yes
Marker: ' '
```

The single-line form is cleaner than wrapping each branch in curly braces when the branches are simple values. Catatku will use this pattern in Lesson 17 to compute a status marker (`[ ]` or `[x]`) based on whether a task is done.

Notice that even on a single line, both `if` and `else` are required when used as an expression. There is no Kotlin equivalent of writing just `if (condition) value` and having the type system fall back to null or empty; the language insists you cover both cases explicitly. This is consistent with Kotlin's general philosophy of making important decisions visible in the source.

---

## 3. The when Expression

The `when` construct is Kotlin's most distinctive control-flow feature. It serves the same purpose as `switch` in Java, but it is much more capable. A `when` can match against literal values, ranges, types, and arbitrary boolean predicates, and like `if` it works as both a statement and an expression. Once you start using `when`, you rarely write a chained `if`/`else if`/`else` again.

### Step 1: Match Against Literal Values

The simplest use of `when` is matching against literal values, similar to a switch:

```kotlin
fun main() {
    val priority = 'H'
    
    val description = when (priority) {
        'H' -> "High"
        'M' -> "Medium"
        'L' -> "Low"
        else -> "Unknown"
    }
    
    println("Priority $priority means: $description")
}
```

Save and run. Output:

```text
Priority H means: High
```

The `when (priority)` line says "look at the value of `priority` and check it against each branch below". Each branch has the form `pattern -> expression`. The `else` branch catches anything that did not match. The whole `when` is an expression that produces the value of whichever branch matched, which we capture in `description`.

Notice how much cleaner this is than the equivalent `if`/`else if`/`else` chain. There is one mention of `priority` at the top, the patterns are aligned for easy reading, and each result is right next to its pattern. For more than two branches, `when` is almost always the right choice over chained `if`.

### Step 2: Match Multiple Values

A single branch can match multiple values by listing them, separated by commas:

```kotlin
fun main() {
    val day = "Saturday"
    
    val type = when (day) {
        "Saturday", "Sunday" -> "weekend"
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday" -> "weekday"
        else -> "unknown"
    }
    
    println("$day is a $type")
}
```

Save and run. Output:

```text
Saturday is a weekend
```

The branch `"Saturday", "Sunday" -> "weekend"` matches if `day` equals either string. This is much more concise than writing two separate branches that produce the same result, or a long `if` chain with `||` operators.

### Step 3: Match Against Ranges and Predicates

`when` can match against ranges (using the `in` operator) and against any boolean expression (by omitting the value at the top of the `when`). This is where it gets significantly more powerful than `switch`.

```kotlin
fun main() {
    val score = 78
    
    val gradeFromRange = when (score) {
        in 90..100 -> "A"
        in 80..89 -> "B"
        in 70..79 -> "C"
        in 60..69 -> "D"
        in 0..59 -> "F"
        else -> "Invalid"
    }
    
    val description = when {
        score >= 90 -> "Excellent"
        score >= 75 -> "Good"
        score >= 60 -> "Pass"
        else -> "Fail"
    }
    
    println("Score $score: grade $gradeFromRange ($description)")
}
```

Save and run. Output:

```text
Score 78: grade C (Good)
```

Two new patterns appear. The first `when` uses range patterns like `in 90..100`, where `90..100` is a `Range` (we will see ranges more in Section 4) and `in` checks if `score` falls within. This is much clearer than `if (score >= 90 && score <= 100)` style conditions.

The second `when` has no value at the top, just `when {`. This is the "predicate" form: each branch is a boolean expression, and the branch whose expression is true gets selected. This form is essentially a chained `if`/`else if` written more cleanly. It is the right choice when your conditions are not simple value comparisons.

The combination of these features makes `when` extraordinarily flexible. You can match types (using `is`), match collection contents, match captured values from sealed classes (we will see this in Lesson 11), and combine these with predicates and ranges. For now, just notice that `when` can replace almost any complex conditional you might write.

### Step 4: Use when as a Statement

Like `if`, `when` can be used as a statement (without capturing the result) when you just want to dispatch on the value:

```kotlin
fun main() {
    val command = "add"
    
    when (command) {
        "add" -> println("Will add a task")
        "list" -> println("Will list tasks")
        "done" -> println("Will mark a task done")
        "remove" -> println("Will remove a task")
        else -> println("Unknown command: $command")
    }
}
```

Save and run. Output:

```text
Will add a task
```

This is the structure that Catatku's command dispatcher will use in Lesson 18. Each branch handles one command name; the `else` catches anything else. The whole construct is much cleaner than a chained `if`/`else if` would be, and adding a new command later is just adding one more branch.

When `when` is used as a statement, the `else` branch is optional. When used as an expression (capturing the result), it is required unless the compiler can prove that the branches cover every possible value, which we will see in Lesson 11 with sealed classes.

---

## 4. The Loop Constructs

Kotlin has three loop constructs: `for`, `while`, and `do-while`. They overlap somewhat but each has a sweet spot, and knowing which to reach for in each situation is part of writing fluent Kotlin.

### Step 1: The for Loop

Kotlin's `for` is closer to Python's `for` than to C's. It iterates over a sequence (a range, a collection, a string's characters, or anything else iterable), binding each element to the loop variable for one iteration:

```kotlin
fun main() {
    println("Counting up:")
    for (i in 1..5) {
        println("  i = $i")
    }
    
    println("\nLetters in 'hello':")
    for (letter in "hello") {
        println("  $letter")
    }
    
    println("\nElements in a list:")
    val tasks = listOf("Task A", "Task B", "Task C")
    for (task in tasks) {
        println("  $task")
    }
}
```

Save and run. Output:

```text
Counting up:
  i = 1
  i = 2
  i = 3
  i = 4
  i = 5

Letters in 'hello':
  h
  e
  l
  l
  o

Elements in a list:
  Task A
  Task B
  Task C
```

Three iteration patterns are at work. The first, `1..5`, is a range that produces the integers 1 through 5 inclusive. The two-dot operator `..` creates an inclusive range; `1..5` includes both 1 and 5. There is also `until` for an exclusive end (`1 until 5` is 1, 2, 3, 4) and `downTo` for descending (`5 downTo 1` is 5, 4, 3, 2, 1). Kotlin's range syntax is one of the small features that makes loop code more readable than the C-style `for (int i = 1; i <= 5; i++)`.

The second, iterating over a `String`, walks through each character in order. The loop variable `letter` is a `Char`. This works because `String` is iterable in Kotlin's standard library; many built-in types support iteration.

The third, iterating over a `listOf(...)`, walks through each element in order. The loop variable `task` is a `String` (inferred from the list's element type). We will cover lists in detail in Lesson 8; for now, just notice that `for` works on collections naturally.

You can also iterate with both the index and the element using `withIndex`:

```kotlin
fun main() {
    val tasks = listOf("Task A", "Task B", "Task C")
    for ((index, task) in tasks.withIndex()) {
        println("${index + 1}. $task")
    }
}
```

Save and run. Output:

```text
1. Task A
2. Task B
3. Task C
```

The destructuring `(index, task)` unpacks the `IndexedValue` returned by `withIndex` into two variables. We will see destructuring more in Lesson 10 with data classes. For now, just notice that this is a clean way to iterate when you need both the position and the value.

### Step 2: The while Loop

A `while` loop runs as long as a condition stays true. It is the cleanest choice when you have a condition you can express directly and the number of iterations is not known in advance:

```kotlin
fun main() {
    var remaining = 10
    var step = 1
    
    while (remaining > 0) {
        println("Step $step: $remaining items remaining")
        remaining -= step
        step += 1
    }
    
    println("Done.")
}
```

Save and run. Output:

```text
Step 1: 10 items remaining
Step 2: 9 items remaining
Step 3: 7 items remaining
Step 4: 4 items remaining
Done.
```

The loop checks `remaining > 0` before each iteration and runs the body if the condition is true. Inside the body, both `remaining` and `step` change, and the loop terminates when `remaining` drops to or below 0. This is the natural pattern when the exit condition depends on the work done inside the loop.

`while` is interchangeable with `for ... in` plus an `if`/`break`, but it is often clearer when the iteration count is unknown or when the exit condition is not a simple counter. For Catatku we will use `while` rarely, because most iteration is over collections (which `for` handles cleanly) or over a fixed number of items.

### Step 3: The do-while Loop

The `do-while` loop is a variation of `while` that checks the condition after running the body, so the body always runs at least once:

```kotlin
fun main() {
    var attempt = 0
    val maxAttempts = 3
    var success = false
    
    do {
        attempt += 1
        println("Attempt $attempt")
        // Simulate something that succeeds on the second attempt
        if (attempt == 2) {
            success = true
        }
    } while (!success && attempt < maxAttempts)
    
    println("Final attempt count: $attempt, success: $success")
}
```

Save and run. Output:

```text
Attempt 1
Attempt 2
Final attempt count: 2, success: true
```

The body runs unconditionally the first time, and then the condition is checked. If the condition is true, the body runs again. This is the right shape when the work has to happen at least once before you can check whether to repeat it. A typical use case is reading input from the user: you have to prompt at least once before you can know whether the input was valid.

In practice, `do-while` is the least common of the three loop constructs because most iteration patterns can be expressed with `for` or `while`. We will not use it in Catatku.

### Step 4: break and continue

Two keywords let you alter the normal flow of a loop. `break` exits the loop entirely. `continue` skips the rest of the current iteration and starts the next one.

```kotlin
fun main() {
    println("Find first even number above 5:")
    for (i in 1..20) {
        if (i <= 5) {
            continue  // skip values <= 5
        }
        if (i % 2 != 0) {
            continue  // skip odd values
        }
        println("Found: $i")
        break  // stop after finding one
    }
    
    println("Done.")
}
```

Save and run. Output:

```text
Find first even number above 5:
Found: 6
Done.
```

The two `continue` statements skip iterations that we are not interested in (values 1 through 5 and odd values). The `break` after finding 6 exits the loop. Without the `break`, the loop would continue checking 7, 8, 9, and so on, finding more even numbers but printing them all before reaching the natural end at 20.

For nested loops, `break` and `continue` only affect the innermost enclosing loop. To control an outer loop from inside a nested one, you can use labeled loops:

```kotlin
fun main() {
    outer@ for (i in 1..5) {
        for (j in 1..5) {
            if (i * j > 10) {
                println("Stopping at i=$i, j=$j")
                break@outer
            }
        }
    }
}
```

Save and run. Output:

```text
Stopping at i=3, j=4
```

The label `outer@` (any name followed by `@`) attaches to the outer `for` loop. Inside the inner loop, `break@outer` exits the labeled loop directly, rather than just the inner one. The `@` syntax for labels is unusual but distinctive and easy to recognize in code. Labels are an advanced feature you will rarely need; they exist for the cases when you do need them, like search loops over a 2D structure.

---

## 5. Putting It All Together with a Catatku Preview

Combine `for` and `when` in a small example that previews the structure Catatku's `list` command will eventually use.

### Step 1: Iterate and Format

Replace the body of `main` with this combined example:

```kotlin
fun main() {
    val descriptions = listOf("Pay rent", "Finish Kotlin course", "Call dentist", "Walk the dog")
    val statuses = listOf("done", "pending", "cancelled", "pending")
    val priorities = listOf("H", "M", "L", "M")
    
    println("Catatku task list:")
    
    for (i in descriptions.indices) {
        val description = descriptions[i]
        val status = statuses[i]
        val priority = priorities[i]
        
        val marker = when (status) {
            "pending" -> "[ ]"
            "done" -> "[x]"
            "cancelled" -> "[!]"
            else -> "[?]"
        }
        
        val priorityLabel = when (priority) {
            "H" -> "High"
            "M" -> "Medium"
            "L" -> "Low"
            else -> "?"
        }
        
        println("$marker (${priorityLabel}) ${i + 1}. $description")
    }
}
```

Save and run. Output:

```text
Catatku task list:
[x] (High) 1. Pay rent
[ ] (Medium) 2. Finish Kotlin course
[!] (Low) 3. Call dentist
[ ] (Medium) 4. Walk the dog
```

Walk through what each piece contributes. We have three parallel lists (descriptions, statuses, priorities) representing four tasks. The `for (i in descriptions.indices)` loop walks through the indices 0, 1, 2, 3 (the `.indices` property on a list gives you the valid indices as a range).

Inside the loop, we extract the three fields for the current task. Then two `when` expressions map the raw status and priority strings to display markers and labels. Finally, `println` formats the line using string templates. Each `when` is an expression whose result is captured in a variable, which is then used in the output.

This is what idiomatic Kotlin looks like: small, composable expressions that combine into clear code. The same logic in Java would be considerably more verbose because Java's `switch` is less flexible and `if`/`else if` chains require more boilerplate. The Kotlin version reads almost like a description of what we want.

### Notice the Parallel-List Smell

Even though this example works, having three parallel lists is a code smell. It is easy to imagine a bug where one of the lists has a different length than the others, or where adding a new task means remembering to update all three. The right fix is to bundle the three fields into a single type, which is what classes are for. We will introduce data classes in Lesson 10 and refactor exactly this pattern into something cleaner.

For now, the parallel-list approach lets us focus on control flow without introducing the class machinery. Recognizing that this is a temporary scaffold (rather than a good final design) is itself a useful programming insight: not every working code is good code, and seeing the difference is the start of learning to refactor.

---

## 6. Run and Test

You have already run examples throughout the lesson. For this final exercise, build a single program that uses every control-flow construct from the lesson together.

### Step 1: Combine Everything

Replace `Main.kt` with this final example:

```kotlin
fun main() {
    val taskCount = 5
    val descriptions = listOf("Plan day", "Write code", "Test code", "Take break", "Review work")
    val priorityLevels = listOf(2, 3, 3, 1, 2)  // 1=Low, 2=Medium, 3=High
    
    println("=== Catatku Task Overview ===")
    
    var highPriorityCount = 0
    var totalChars = 0
    
    for (i in 0 until taskCount) {
        val priority = priorityLevels[i]
        
        // Skip low-priority tasks for brevity in this overview
        if (priority == 1) {
            continue
        }
        
        val priorityLabel = when (priority) {
            3 -> "HIGH"
            2 -> "MED"
            1 -> "LOW"
            else -> "???"
        }
        
        val description = descriptions[i]
        totalChars += description.length
        
        if (priority == 3) {
            highPriorityCount += 1
        }
        
        println("[$priorityLabel] ${i + 1}. $description")
    }
    
    println("=== Summary ===")
    println("Showed ${taskCount - priorityLevels.count { it == 1 }} non-low-priority tasks")
    println("High-priority count: $highPriorityCount")
    println("Total characters in shown descriptions: $totalChars")
    
    val verdict = if (highPriorityCount >= 2) "busy day ahead" else "manageable"
    println("Verdict: $verdict")
}
```

Save and run. Output:

```text
=== Catatku Task Overview ===
[MED] 1. Plan day
[HIGH] 2. Write code
[HIGH] 3. Test code
[MED] 5. Review work
=== Summary ===
Showed 4 non-low-priority tasks
High-priority count: 2
Total characters in shown descriptions: 38
Verdict: busy day ahead
```

Trace through what each construct contributed. The `for (i in 0 until taskCount)` is a counted loop using exclusive range. The `if (priority == 1) continue` skips low-priority tasks. The `when` block maps numeric priorities to text labels. The accumulator variables `highPriorityCount` and `totalChars` are mutated inside the loop, which is one of the legitimate uses of `var`. The final `if` expression decides on a verdict based on the count.

The line `priorityLevels.count { it == 1 }` is a preview of Lesson 13: `count` is a higher-order function that takes a lambda (the `{ it == 1 }`) and counts how many elements match. We use it here to compute "how many low-priority tasks were skipped" for the summary message. This is a one-liner replacement for what would otherwise be another `for` loop with a counter, and it is the kind of expression-oriented code that Kotlin makes easy.

### Step 2: Modify and Re-Run

Try a few variations. Change the priority levels to make all tasks high-priority and observe how the verdict changes. Change `0 until taskCount` to `0 until 3` to limit the iteration. Add a fourth case to the `when` expression. Each variation tests your understanding of one piece of the program.

The point of these small experiments is to build the kind of intuition where you can predict what a piece of code will do before running it. With enough small experiments, prediction becomes reliable, and reliable prediction is the foundation of programming productively rather than guessing.

---

## 7. Fix the Errors in Your Code

Three control-flow mistakes are common in early Kotlin code.

**Error 1: Forgetting the else branch in an if expression**

```kotlin
// Wrong
fun main() {
    val score = 78
    val grade = if (score >= 90) "A" else if (score >= 80) "B"
    println(grade)
}

// Correct
fun main() {
    val score = 78
    val grade = if (score >= 90) "A" else if (score >= 80) "B" else "Other"
    println(grade)
}
```

When `if` is used as an expression, every possible value of the condition must lead to a result. The compiler refuses the wrong version with the message `'if' must have both main and 'else' branches when used as an expression.`, because there would be a case where the expression had no value. The fix is to add an `else` branch, as the correct version does; with a score of 78 it prints `Other`. As a habit, when you write `val x = if (...)`, immediately think about what the `else` should be. As a statement (where the result is not captured), `else` is optional.

**Error 2: Writing == in front of a when value pattern**

```kotlin
// Wrong
fun main() {
    val priority = 'H'
    val label = when (priority) {
        == 'H' -> "High"
        else -> "Other"
    }
    println(label)
}

// Correct
fun main() {
    val priority = 'H'
    val label = when (priority) {
        'H' -> "High"
        else -> "Other"
    }
    println(label)
}
```

In a `when` block matching against a value, each branch's pattern is just the value to match, not an `==` expression. The wrong version does not even parse: the compiler reports `Syntax error: Expecting an expression.` on the `==` line. The `==` would be needed only if you used the predicate form `when {`, where each branch is a boolean: `when { priority == 'H' -> "High" ... }`. Mixing up the two forms is a common early mistake, and the fix is to remember that the value form (`when (x)`) takes patterns directly, while the predicate form (`when`) takes booleans.

**Error 3: Breaking out of an outer loop without a label**

```kotlin
// Wrong
fun main() {
    for (i in 1..3) {
        for (j in 1..3) {
            if (i * j > 4) {
                println("Stopping at i=$i, j=$j")
                break
            }
        }
    }
}

// Correct
fun main() {
    outer@ for (i in 1..3) {
        for (j in 1..3) {
            if (i * j > 4) {
                println("Stopping at i=$i, j=$j")
                break@outer
            }
        }
    }
}
```

This mistake compiles, which makes it sneakier. The wrong version prints two lines, `Stopping at i=2, j=3` and then `Stopping at i=3, j=2`, because a plain `break` only leaves the inner loop and the outer loop keeps going. To break out of an outer loop from inside a nested one, you label the outer loop and use `break@label`. The correct version stops after the first line, `Stopping at i=2, j=3`. As a habit, write nested loops without labels until you actually need them; many cases that look like they need labels can be refactored into a function call that uses `return` instead, which is often clearer.

---

## 8. Exercises

These exercises practice the control-flow constructs.

**Exercise 1:** Use a `for` loop and `if` to print all numbers from 1 to 50 that are divisible by both 3 and 7. Use `%` (modulo) for the divisibility check.

**Exercise 2:** Write a function that takes a `Char` parameter representing a Catatku priority code (`'H'`, `'M'`, `'L'`) and returns a `String` description ("High Priority", "Medium Priority", "Low Priority", or "Unknown"). Use `when` as an expression. Test the function with a few different priority codes.

**Exercise 3:** Use a `while` loop to find the smallest power of 2 that is greater than 1000. Print each power as you compute it (1, 2, 4, 8, 16, ...) and the final answer when found.

---

## 9. Solutions

Try the exercises yourself first, then check the solutions below.

**Solution for Exercise 1:**

A number is divisible by both 3 and 7 when the remainder of dividing by each is zero, so the condition combines two `%` checks with `&&`.

```kotlin
fun main() {
    for (n in 1..50) {
        if (n % 3 == 0 && n % 7 == 0) {
            println(n)
        }
    }
}
```

Save and run. Output:

```text
21
42
```

The `for (n in 1..50)` loop walks through every number from 1 to 50 inclusive. The expression `n % 3` is the remainder after dividing `n` by 3, so `n % 3 == 0` is true exactly when `n` is a multiple of 3. The `&&` operator requires both checks to be true, which means the number is a multiple of 21. Only 21 and 42 fall inside the range.

**Solution for Exercise 2:**

This exercise practices using `when` as an expression in a function context. We have not yet covered functions in detail (that comes in Lesson 6), but the basic syntax we used in Lesson 3's exercises is enough.

```kotlin
fun describePriority(code: Char): String {
    return when (code) {
        'H' -> "High Priority"
        'M' -> "Medium Priority"
        'L' -> "Low Priority"
        else -> "Unknown"
    }
}

fun main() {
    println(describePriority('H'))
    println(describePriority('M'))
    println(describePriority('L'))
    println(describePriority('X'))
}
```

Save and run. Output:

```text
High Priority
Medium Priority
Low Priority
Unknown
```

The function declaration `fun describePriority(code: Char): String` says the function takes a `Char` named `code` and returns a `String`. Inside, the `return when (code) { ... }` returns the value produced by the `when` expression. Each branch matches one possible priority code and produces the corresponding description; the `else` catches anything that does not match.

A more idiomatic Kotlin version would use a single-expression function, which we will see in Lesson 6:

```kotlin
fun describePriority(code: Char): String = when (code) {
    'H' -> "High Priority"
    'M' -> "Medium Priority"
    'L' -> "Low Priority"
    else -> "Unknown"
}
```

The `=` after the parameter list and return type, followed by the expression body, replaces the curly-brace block with a `return`. For functions that consist of a single expression, this form is shorter and reads more like a definition (`describePriority of code is the when of code`). Both forms produce identical bytecode; the choice is purely stylistic, and idiomatic Kotlin usually prefers the single-expression form when the body fits on one expression.

This exercise demonstrates a pattern you will use constantly in Catatku and beyond: a small function that maps an input value to a corresponding output value using `when`. The combination of `when` as an expression and single-expression functions makes this kind of mapping code remarkably terse.

**Solution for Exercise 3:**

The number of doublings is not known in advance, so this is a natural fit for `while`: keep doubling as long as the value has not passed 1000.

```kotlin
fun main() {
    var power = 1
    while (power <= 1000) {
        println(power)
        power *= 2
    }
    println("Smallest power of 2 greater than 1000: $power")
}
```

Save and run. Output:

```text
1
2
4
8
16
32
64
128
256
512
Smallest power of 2 greater than 1000: 1024
```

The variable `power` starts at 1 (which is 2 to the power of 0) and must be a `var` because the loop changes it. The condition `power <= 1000` is checked before every iteration; while it holds, the loop prints the current value and doubles it with `power *= 2`. When `power` becomes 1024, the condition is false, the loop ends, and the final `println` reports the answer.

---

## 10. Understanding Why if Is an Expression

Kotlin's choice to make `if` (and `when`, and `try`, and most other control-flow constructs) an expression rather than a statement is one of those small design decisions that has surprisingly large effects on code style. The roots are in functional programming languages like ML, Haskell, and Scala, where almost everything is an expression. Kotlin adopted this approach because it leads to code that is more concise, more declarative, and easier to refactor.

In a statement-based language, you typically write code in two stages: declare a variable with some default or uninitialized value, then conditionally reassign it based on some logic. The Java equivalent of our grade classifier looks like this:

```java
String grade;
if (score >= 90) {
    grade = "A";
} else if (score >= 80) {
    grade = "B";
} else if (score >= 70) {
    grade = "C";
} else {
    grade = "F";
}
```

This works, but notice that `grade` is declared without an initial value, then assigned in each branch. To trace what `grade` ends up as, you mentally simulate every branch and remember which one matched. In Kotlin's expression form, the assignment happens once and the value is the result of the whole `if`:

```kotlin
val grade = if (score >= 90) "A"
            else if (score >= 80) "B"
            else if (score >= 70) "C"
            else "F"
```

This reads more like math: `grade` is defined to be one specific thing, and that thing is determined by `score`. The `val` binding happens once; mutation is not involved. For a simple case the savings are small, but for chained or nested conditionals the difference compounds. And critically, the expression form lets you use `val` instead of `var`, which carries all the immutability benefits we discussed in Lesson 4.

The same expression-orientation extends to `when`, to `try`/`catch` (Lesson 16), and to block expressions (a `{ ... }` block whose value is the value of its last expression). Once you internalize the pattern, you start writing in a style where computations flow into values that get bound once, rather than into variables that get mutated repeatedly. This is the heart of the functional style of programming, and it produces code that is easier to reason about because each name in scope has a fixed meaning.

A subtler benefit is that expression-form control flow plays well with type inference. When you write `val grade = if (...) "A" else "B"`, the compiler can infer that `grade` is `String` from the branch results. With the statement form, you would have to declare `grade` separately with an explicit type annotation, because there is no value at the declaration point for inference to work from. So the expression form is shorter at every level: less typing, less variable declaration ceremony, less mental tracking of mutation.

The cost of all this is that you have to learn to think in expressions, which feels slightly unnatural if your background is C, C++, or Java. The first few days of writing Kotlin you will instinctively reach for the statement form, then realize you wanted the expression form, then rewrite. Over time the expression form becomes the default reach, and writing the statement form starts to feel verbose. This shift in style is one of the markers of moving from "writing Java with Kotlin syntax" to "writing actual Kotlin", and it pays back the investment in clarity for the rest of your career.

---

## Next Up - Lesson 6

Kotlin's control flow is built from a small set of constructs that are deliberately more flexible than their counterparts in older languages. The `if` and `when` constructs work as both statements and expressions, with the expression form letting you assign to `val` variables in one go rather than mutating a `var` across branches. The `for` loop iterates over ranges and collections in a Python-like style rather than the C-style counting loop. The `while` and `do-while` loops handle the cases where the iteration count is unknown. The `break` and `continue` keywords (with optional labels for nested loops) handle the few cases where you need to step outside the normal loop flow. Combining `for` with `when` produces clean dispatch logic for things like printing a Catatku-style task list, which is the same pattern Lesson 18 will use for command dispatch.

In Lesson 6 you will learn about functions properly: parameters, return types, default and named arguments, single-expression functions, and how to organize code into reusable named pieces.
