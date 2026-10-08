## 1. Before You Begin

Every program you have written so far runs each line exactly once, from top to bottom. That is fine for printing a report, but most useful programs need to react to their data: show a different message when a student fails, charge a different price for children, or refuse to continue when something is missing. Choosing between different paths based on a condition is called control flow, and it is one of the core ingredients of programming listed in Lesson 1.

In Lesson 4 you learned to produce `true` and `false` values with comparisons such as `score >= 75` and to combine them with `&&`, `||`, and `!`. In this lesson you will put those booleans to work. You will write `if`, `else if`, and `else` branches, use `if` to produce a value, and then learn `match`, Rust's tool for comparing one value against many possible patterns.

### What You'll Build

A `decisions` program that evaluates a test score (pass or fail, an encouraging message, and a letter grade), checks whether a student may join a school trip, turns a day number into a day name, and calculates a ticket price based on age.

### What You'll Learn

- ✅ How to run code conditionally with `if` and `else`
- ✅ How to chain several conditions with `else if`
- ✅ How to combine conditions with `&&` and `||`
- ✅ How to use `if` as an expression that produces a value
- ✅ How to compare a value against patterns with `match`
- ✅ How to match ranges (`90..=100`), several values (`6 | 7`), and everything else (`_`)
- ✅ Why `match` must be exhaustive, and how the compiler enforces it

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with variables, integers, booleans, and comparison operators (Lessons 3 and 4)

---

## 2. Branch with if and else

An `if` statement runs a block of code only when a condition is true. The condition is any expression that produces a `bool`. You can add an `else` block that runs when the condition is false, so exactly one of the two blocks runs.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new decisions
cd decisions
```

These commands create the `decisions` project and move into its folder. As in Lesson 4, you will build `src/main.rs` gradually and close `main` at the end.

### Step 2: Write a Simple if and else

Replace the contents of `src/main.rs` with:

```rust
fn main() {
    // if, else if, else
    let score = 83;

    if score >= 75 {
        println!("Score {score}: passed.");
    } else {
        println!("Score {score}: not passed yet.");
    }
```

The keyword `if` is followed by a condition, `score >= 75`, and then a block in curly braces. If the condition is `true`, Rust runs that block. If it is `false`, Rust runs the block after `else`. Exactly one of the two `println!` calls runs, never both and never neither.

Unlike some other languages, Rust does not need parentheses around the condition; writing `if (score >= 75)` works but the compiler warns that the parentheses are unnecessary. The curly braces, on the other hand, are always required, even when the block contains a single line. The code inside each block is indented by four spaces to make the structure easy to see.

### Step 3: Chain Conditions with else if

A pass or fail answer is not always enough. Add a message that depends on how high the score is:

```rust
    if score >= 90 {
        println!("Excellent work!");
    } else if score >= 80 {
        println!("Great job!");
    } else if score >= 75 {
        println!("Good, you passed.");
    } else {
        println!("Keep practicing.");
    }
```

`else if` adds another condition to check when the previous one was false. Rust checks the conditions from top to bottom and runs the first block whose condition is true, then skips the rest of the chain. With a score of 83, the first condition (`83 >= 90`) is false, the second (`83 >= 80`) is true, so Rust prints `Great job!` and ignores the remaining branches, even though `83 >= 75` is also true.

That is why the order matters. If you checked `score >= 75` first, every score from 75 upward would get the same message, and the `>= 90` branch would never run. When conditions overlap, put the most specific one first. The final `else` catches every score that matched none of the conditions.

### Step 4: Combine Conditions

Conditions can be built from several comparisons joined with logical operators. Add this block:

```rust
    // Combining conditions
    let age = 16;
    let has_permission = true;
    if age >= 17 || has_permission {
        println!("Age {age}: you may join the trip.");
    }
```

A student may join the trip if they are at least 17 *or* they have permission from a parent. `age >= 17` is false, but `has_permission` is true, so the whole `||` expression is true and the message prints. This `if` has no `else`, which is perfectly valid: when the condition is false, the program simply skips the block and continues. Use `&&` when every part must be true, such as `age >= 17 && has_ticket`.

---

## 3. Use if as an Expression

In Rust, `if` is not only a statement that runs code; it is also an expression, which means it can produce a value. This lets you choose a value with `if` and store it directly in a variable, instead of declaring a variable first and assigning to it in each branch.

### Step 1: Choose a Value with if

Add the following lines:

```rust
    // if as an expression
    let status = if score >= 75 { "PASS" } else { "FAIL" };
    println!("Status: {status}");
```

The right side of `let status =` is an entire `if` expression. When the condition is true, the expression's value is the value of the first block, `"PASS"`; otherwise it is `"FAIL"`. That value is stored in `status`. Notice there is no semicolon after `"PASS"` or `"FAIL"` inside the blocks. In Rust, the last expression in a block without a semicolon becomes the block's value. You will see this rule again with `match` below and with functions in Lesson 7.

Because the result goes into a single variable, both branches must produce the same type. Here both are text. If one branch produced text and the other a number, Rust would not know what type `status` has, and the compiler rejects it (you will see this error in Section 6). An `if` used as an expression also needs an `else`, because the variable must get a value in every case.

---

## 4. Match Values Against Patterns

A long chain of `else if` comparisons against the same variable works, but it gets noisy. Rust's `match` expression is built for exactly this situation: it compares one value against a list of patterns and runs the code for the first pattern that fits. Like `if`, `match` is an expression, so it can produce a value.

### Step 1: Match Ranges to Compute a Letter Grade

Add the letter grade calculation:

```rust
    // match with ranges
    let letter = match score {
        90..=100 => 'A',
        80..=89 => 'B',
        70..=79 => 'C',
        60..=69 => 'D',
        _ => 'E',
    };
    println!("Letter grade: {letter}");
```

`match score { ... }` takes the value of `score` and compares it with each arm inside the braces. An arm has a pattern on the left, a fat arrow `=>`, and the value or code to run on the right. Arms are separated by commas.

`90..=100` is an inclusive range pattern: it matches any number from 90 to 100, including both ends. Rust checks the arms from top to bottom, so 83 skips the first arm and matches `80..=89`, and the whole `match` produces `'B'`. The letters are `char` values in single quotes, as you learned in Lesson 4.

The last arm, `_`, is a wildcard. It matches anything, so it acts like `else`: every score not covered by the earlier arms (below 60, or above 100) gets `'E'`. The semicolon after the closing brace ends the `let` statement.

### Step 2: Match Exact Values and Several Values

Add the day name example:

```rust
    // match with exact values and multiple patterns
    let day = 6;
    let day_name = match day {
        1 => "Monday",
        2 => "Tuesday",
        3 => "Wednesday",
        4 => "Thursday",
        5 => "Friday",
        6 | 7 => "Weekend",
        _ => "Unknown day",
    };
    println!("Day {day}: {day_name}");
```

A pattern can be a single exact value such as `1`. The `|` symbol, read as "or," joins several patterns into one arm: `6 | 7` matches either 6 or 7. With `day` set to 6, the `match` produces `"Weekend"`. The wildcard arm handles numbers that are not valid days, such as 0 or 12, so the program never ends up without a value.

### Step 3: Run Several Lines in a Match Arm

Sometimes an arm needs to do more than produce a value. Add the ticket price calculation, then close `main`:

```rust
    // match arms with blocks
    let ticket_age = 67;
    let price = match ticket_age {
        0..=4 => 0,
        5..=17 => {
            println!("Child ticket applied.");
            15_000
        }
        65.. => {
            println!("Senior discount applied.");
            20_000
        }
        _ => 35_000,
    };
    println!("Ticket price for age {ticket_age}: Rp{price}");
}
```

An arm's right side can be a block in curly braces containing several lines. The block runs its statements in order, and its last expression, written without a semicolon, becomes the arm's value. For a 67 year old visitor, the `65..` arm matches, prints a message, and produces `20_000` as the price.

`65..` is a range with no upper end: it matches 65 and every number above it. Children under 5 enter free, children from 5 to 17 pay 15,000, seniors pay 20,000, and the `_` arm covers everyone else (ages 18 to 64) with the full price. Arms written as blocks do not need a comma after the closing brace, though adding one is allowed. The final brace closes `main`.

---

## 5. Run and Test

Your complete program reads from top to bottom like a series of decisions. Run it:

```bash
cargo run -q
```

```text
Score 83: passed.
Great job!
Age 16: you may join the trip.
Status: PASS
Letter grade: B
Day 6: Weekend
Senior discount applied.
Ticket price for age 67: Rp20000
```

Each line comes from a different decision. The score of 83 passed, matched the `>= 80` branch, produced `PASS`, and fell into the `80..=89` range for a `B`. The trip check passed because of the permission. Day 6 is part of the weekend. The ticket arm for seniors printed its message before the final price line, because the `match` runs before the `println!` that uses `price`.

Now test the other branches. Change `score` to `95`, then `76`, then `42`, and run the program after each change. Then change `ticket_age` to `3`, `10`, and `30`. Predict the output before running each time; checking your prediction against the real output is one of the best ways to understand control flow.

---

## 6. Fix the Errors in Your Code

Conditions and branches produce some of Rust's most helpful error messages. Here are the ones beginners meet first.

**Error 1: Using a number as a condition.**

Some languages treat any non-zero number as true. Rust does not: an `if` condition must be a `bool`.

```rust
// Wrong
fn main() {
    let items_in_cart = 3;
    if items_in_cart {
        println!("Ready to check out.");
    }
}

// Correct
fn main() {
    let items_in_cart = 3;
    if items_in_cart > 0 {
        println!("Ready to check out.");
    }
}
```

The wrong version produces `error[E0308]: mismatched types` with ``expected `bool`, found integer``. The fix is to write the comparison you actually mean. `items_in_cart > 0` makes the intent explicit, which is exactly why Rust requires it.

**Error 2: Using `=` instead of `==` in a condition.**

A single `=` assigns a value; `==` compares two values. Mixing them up is a classic mistake in every language.

```rust
// Wrong
fn main() {
    let score = 100;
    if score = 100 {
        println!("Perfect!");
    }
}

// Correct
fn main() {
    let score = 100;
    if score == 100 {
        println!("Perfect!");
    }
}
```

The wrong version produces `error[E0308]: mismatched types` with ``expected `bool`, found `()` ``. An assignment produces `()`, Rust's "empty" value, not a boolean. The `help` section says ``you might have meant to compare for equality`` and shows where to add the second `=`.

**Error 3: Branches that produce different types.**

When `if` is used as an expression, every branch must produce a value of the same type.

```rust
// Wrong
fn main() {
    let score = 83;
    let status = if score >= 75 { "PASS" } else { 0 };
    println!("{status}");
}

// Correct
fn main() {
    let score = 83;
    let status = if score >= 75 { "PASS" } else { "FAIL" };
    println!("{status}");
}
```

The wrong version produces ``error[E0308]: `if` and `else` have incompatible types``. The compiler points at `"PASS"` as the reason it expected `&str` (text) and at `0` as the integer it found instead. Make both branches produce the same kind of value.

**Error 4: A `match` that does not cover every possible value.**

`match` must be exhaustive: every possible value of the matched type must be handled by some arm. This rule prevents the program from ever reaching a `match` with no answer.

```rust
// Wrong
fn main() {
    let score = 83;
    let letter = match score {
        90..=100 => 'A',
        80..=89 => 'B',
        70..=79 => 'C',
    };
    println!("{letter}");
}

// Correct
fn main() {
    let score = 83;
    let letter = match score {
        90..=100 => 'A',
        80..=89 => 'B',
        70..=79 => 'C',
        _ => 'D',
    };
    println!("{letter}");
}
```

The wrong version produces ``error[E0004]: non-exhaustive patterns: `i32::MIN..=69_i32` and `101_i32..=i32::MAX` not covered``. `score` is an `i32`, which can hold any value from about minus two billion to plus two billion, and the compiler lists exactly which ranges no arm handles. Even though you "know" a score is between 0 and 100, the type does not. A wildcard arm `_` is the usual fix.

---

## 7. Exercises

**Exercise 1:** Create a project called `even_odd`. Store a number in a variable. Use `if` and `else` with the `%` operator to print whether it is even or odd. Then use `if` as an expression with `else if` to store `"positive"`, `"negative"`, or `"zero"` in a variable and print it.

**Exercise 2:** Create a project called `discount`. A shop gives a 20 percent discount on purchases of Rp500,000 or more, and a 10 percent discount on purchases of Rp200,000 or more *or* for members. Everyone else gets no discount. Store the total (`275_000`) and a membership flag (`true`), calculate the discount percentage with an `if` expression, and print the total, the discount, and the amount to pay.

**Exercise 3:** Create a project called `calendar`. Use `match` with `|` patterns to store the number of days in a given month (use 28 for February). Print `Month 2 has 28 days.` for a valid month and a different message for an invalid month. Then use `match` with ranges to turn an hour from 0 to 23 into a greeting: morning (0 to 10), afternoon (11 to 14), evening (15 to 18), or night (19 to 23).

---

## 8. Solutions

**Solution for Exercise 1:**

```rust
fn main() {
    let number = 17;
    if number % 2 == 0 {
        println!("{number} is even.");
    } else {
        println!("{number} is odd.");
    }

    let kind = if number > 0 {
        "positive"
    } else if number < 0 {
        "negative"
    } else {
        "zero"
    };
    println!("{number} is {kind}.");
}
```

`number % 2` is the remainder after dividing by 2, which is 0 for even numbers, so `number % 2 == 0` is a boolean that is true exactly when the number is even. The second part shows that an `if` expression can have `else if` branches too; each branch's block produces a text value, and the chosen one is stored in `kind`. Writing each branch on its own lines makes a longer `if` expression easier to read. The program prints:

```text
17 is odd.
17 is positive.
```

**Solution for Exercise 2:**

```rust
fn main() {
    let total = 275_000;
    let is_member = true;

    let discount_percent = if total >= 500_000 {
        20
    } else if total >= 200_000 || is_member {
        10
    } else {
        0
    };

    let discount = total * discount_percent / 100;
    let to_pay = total - discount;
    println!("Total: Rp{total}");
    println!("Discount: {discount_percent}% (Rp{discount})");
    println!("To pay: Rp{to_pay}");
}
```

The biggest discount is checked first so that a Rp600,000 purchase gets 20 percent instead of stopping at the 10 percent branch. The middle branch combines two conditions with `||`, matching the rule "Rp200,000 or more *or* a member." The discount amount is calculated with integers: multiplying before dividing (`total * discount_percent / 100`) keeps the result exact, while dividing first (`discount_percent / 100`) would give 0 because of integer division. The program prints:

```text
Total: Rp275000
Discount: 10% (Rp27500)
To pay: Rp247500
```

**Solution for Exercise 3:**

```rust
fn main() {
    let month = 2;
    let days = match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 => 28,
        _ => 0,
    };

    if days == 0 {
        println!("Month {month} does not exist.");
    } else {
        println!("Month {month} has {days} days.");
    }

    let hour = 14;
    let greeting = match hour {
        0..=10 => "Good morning",
        11..=14 => "Good afternoon",
        15..=18 => "Good evening",
        19..=23 => "Good night",
        _ => "Invalid hour",
    };
    println!("{hour}:00 -> {greeting}");
}
```

The first `match` groups months by their number of days with `|`, so only three arms cover all twelve months. The wildcard arm returns `0` as a signal for "invalid month," and the `if` that follows checks for that signal. (In Lesson 12 you will learn `Option`, a cleaner way to represent "no value.") The second `match` uses inclusive ranges, and the wildcard catches numbers outside 0 to 23. The program prints:

```text
Month 2 has 28 days.
14:00 -> Good afternoon
```

---

## Next Up - Lesson 6

In this lesson you made programs choose between paths. You used `if`, `else if`, and `else`, combined conditions with `&&` and `||`, used `if` as an expression to pick a value, and compared values against ranges, exact values, and wildcards with `match`. You also saw that Rust requires `bool` conditions, matching branch types, and exhaustive `match` expressions.

Choosing is one half of control flow; repeating is the other. In Lesson 6, you will learn Rust's three loops, `loop`, `while`, and `for`, and use them to count, sum the elements of an array without writing each index by hand, and stop early with `break` and `continue`.
