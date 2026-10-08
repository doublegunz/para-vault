## 1. Before You Begin

In Lesson 5 you taught programs to choose between paths with `if` and `match`. The other half of control flow is repetition. Computers are extremely good at doing the same thing many times without getting bored or making mistakes, and loops are how you ask them to. In Lesson 4 you added up five test scores by writing `scores[0] + scores[1] + ...` by hand. With a loop, the same code works for five scores or five thousand.

Rust has three kinds of loops, and each fits a different situation. `loop` repeats forever until you explicitly stop it. `while` repeats as long as a condition stays true. `for` repeats once for each item in a range or collection. In this lesson you will use all three, control them with `break` and `continue`, and nest one loop inside another.

### What You'll Build

A `loops` program that simulates connection attempts, calculates how many weeks of saving reach a goal, counts down to a rocket launch, prints a multiplication table, sums an array of scores with a running total, filters odd numbers, and prints a small grid with nested loops.

### What You'll Learn

- ✅ How to repeat code with `loop` and stop it with `break`
- ✅ How to return a value from a `loop` with `break value`
- ✅ How to repeat while a condition is true with `while`
- ✅ How to iterate over ranges (`1..=5`) and arrays with `for`
- ✅ The difference between exclusive (`1..5`) and inclusive (`1..=5`) ranges
- ✅ How to skip an iteration with `continue` and exit early with `break`
- ✅ How to keep a running total and nest loops

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with `mut` variables, arrays, comparison operators, and `if` (Lessons 3 to 5)

---

## 2. Repeat Until You Stop with loop

The simplest loop in Rust is `loop`. It runs its block again and again with no built-in end. That sounds dangerous, and it would be without a way out: `break` immediately exits the loop. `loop` is a good fit when you do not know in advance how many repetitions you need, only the condition for stopping.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new loops
cd loops
```

These commands create the `loops` project and move into it. You will build up `src/main.rs` block by block and close `main` at the end.

### Step 2: Loop Until a Condition Is Met

Replace the contents of `src/main.rs` with:

```rust
fn main() {
    // loop: repeat until break
    let mut attempts = 0;
    loop {
        attempts += 1;
        println!("Connecting... attempt {attempts}");
        if attempts == 3 {
            println!("Connected!");
            break;
        }
    }
```

This simulates a program that keeps trying to connect to a server. `attempts` starts at 0 and must be mutable because the loop changes it. Each pass through the block is called an iteration. In every iteration, `attempts += 1` increases the counter, the `println!` reports the attempt, and the `if` checks whether this is the third attempt. On the third iteration the condition is true, so the program prints `Connected!` and `break` exits the loop. The program then continues with whatever comes after the loop's closing brace.

If you forgot the `break`, or wrote a condition that never becomes true, the loop would run forever. If that ever happens while you are experimenting, press `Ctrl` + `C` in the terminal to stop the program.

### Step 3: Return a Value from a Loop

`loop` is an expression, just like `if` and `match`, so it can produce a value. You give the value to `break`. Add this block:

```rust
    // loop that returns a value with break
    let mut savings = 0;
    let mut weeks = 0;
    let weeks_needed = loop {
        savings += 75_000;
        weeks += 1;
        if savings >= 300_000 {
            break weeks;
        }
    };
    println!("Weeks needed to save Rp300000: {weeks_needed}");
```

Someone saves Rp75,000 every week and wants to know how long it takes to reach Rp300,000. Each iteration adds one week of savings and counts the week. When the savings reach the goal, `break weeks;` exits the loop *and* hands back the value of `weeks`. That value becomes the value of the whole `loop` expression and is stored in `weeks_needed`. The semicolon after the loop's closing brace ends the `let` statement. After four weeks the savings are exactly Rp300,000, so `weeks_needed` is 4.

---

## 3. Repeat While a Condition Is True with while

Many loops have the form "check a condition; if it is true, run the block; repeat." You could write that with `loop`, `if`, and `break`, but `while` expresses it directly and is easier to read.

### Step 1: Count Down

Add the countdown:

```rust
    // while: repeat while a condition is true
    let mut countdown = 5;
    while countdown > 0 {
        print!("{countdown}... ");
        countdown -= 1;
    }
    println!("Liftoff!");
```

`while countdown > 0` checks the condition *before* each iteration. While it is true, Rust runs the block: it prints the current number without a newline (using `print!` from Lesson 3) and then decreases `countdown` by 1. When `countdown` reaches 0, the condition becomes false, the loop ends, and `println!("Liftoff!")` finishes the line.

The `countdown -= 1;` line is what eventually makes the condition false. Every `while` loop needs something inside it that moves toward the end; without it, the condition stays true forever. Also notice that if `countdown` started at 0, the condition would be false immediately and the block would never run at all. A `while` loop can run zero times; a `loop` always runs at least once.

---

## 4. Iterate over Ranges and Arrays with for

The `for` loop is the one you will use most. It runs its block once for each item in a sequence, such as a range of numbers or the elements of an array, and it handles the counting for you. There is no counter to forget to increase and no index that can go out of bounds.

### Step 1: Loop over a Range

Add a multiplication table:

```rust
    // for with a range
    for number in 1..=5 {
        println!("{number} x 3 = {}", number * 3);
    }
```

`1..=5` is an inclusive range: the numbers 1, 2, 3, 4, and 5. (You used the same syntax as a pattern in `match` in Lesson 5.) `for number in 1..=5` runs the block five times, and on each iteration the variable `number` holds the next value from the range. `number` exists only inside the loop's block; it is created fresh on each iteration and does not need `mut`.

Rust also has an exclusive range, written `1..5`, which stops *before* the last number and produces 1, 2, 3, and 4. Exclusive ranges are handy for positions, because `0..5` gives exactly the five valid indexes of a five element array. When you want to include the end, use `..=`.

### Step 2: Loop over an Array with a Running Total

Now replace the hand written sum from Lesson 4 with a loop:

```rust
    // for over an array, with a running total
    let scores = [80, 92, 67, 75, 88];
    let mut total = 0;
    for score in scores {
        total += score;
    }
    println!("Total: {total}, average: {:.1}", total as f64 / scores.len() as f64);
```

`for score in scores` goes through the array's elements in order, and on each iteration `score` holds one of them: first 80, then 92, and so on. This is the running total pattern: a mutable variable starts at zero before the loop, and each iteration adds the current element to it. When the loop ends, `total` holds the sum of all elements. The `println!` then divides by the length, converting both to `f64` as in Lesson 4, to get the average.

The great advantage over `scores[0] + scores[1] + ...` is that this loop does not care how many elements the array has. Add or remove scores, and the code still works without changes.

### Step 3: Skip with continue and Exit with break

`continue` and `break` work in every kind of loop. Add this block:

```rust
    // continue and break inside for
    for number in 1..=10 {
        if number % 2 == 0 {
            continue;
        }
        if number > 7 {
            break;
        }
        print!("{number} ");
    }
    println!();
```

`continue` skips the rest of the current iteration and jumps straight to the next one. Here it skips even numbers, so the `print!` line only runs for odd numbers. `break` ends the loop entirely: once an odd number above 7 appears (that is, 9), the loop stops, even though the range goes up to 10. The result is the odd numbers 1, 3, 5, and 7. The empty `println!()` after the loop prints just a newline, finishing the line that `print!` started.

### Step 4: Nest Loops

A loop can contain another loop. Add a small multiplication grid and close `main`:

```rust
    // nested loops
    for row in 1..=3 {
        for col in 1..=4 {
            print!("{:>4}", row * col);
        }
        println!();
    }
}
```

The outer loop runs three times, once per row. For *each* of those iterations, the inner loop runs four times, once per column, so the `print!` line runs 3 times 4, or 12 times in total. `{:>4}` right aligns each product in a space four characters wide (Lesson 3), which keeps the columns tidy. After the inner loop finishes a row, `println!()` moves to the next line. Nested loops are the natural way to work with anything that has rows and columns, such as tables, grids, and game boards.

---

## 5. Run and Test

Run the complete program:

```bash
cargo run -q
```

```text
Connecting... attempt 1
Connecting... attempt 2
Connecting... attempt 3
Connected!
Weeks needed to save Rp300000: 4
5... 4... 3... 2... 1... Liftoff!
1 x 3 = 3
2 x 3 = 6
3 x 3 = 9
4 x 3 = 12
5 x 3 = 15
Total: 402, average: 80.4
1 3 5 7 
   1   2   3   4
   2   4   6   8
   3   6   9  12
```

Trace each block. The `loop` ran three times and stopped with `break`. The savings loop returned 4 through `break weeks`. The `while` loop printed five numbers on one line before `Liftoff!`. The range loop printed five lines. The array loop produced the same total and average as the manual calculation in Lesson 4. `continue` removed the even numbers and `break` stopped at 9. The nested loops produced a three by four grid.

Experiment to build intuition. Change the savings per week to `60_000` and predict the new number of weeks. Change the range in the multiplication table to `1..5` and notice which line disappears. Add a sixth score to the array and confirm the average updates without any other change.

---

## 6. Fix the Errors in Your Code

Loops introduce two kinds of mistakes: ones the compiler catches, and ones that compile but do the wrong thing. Both are worth recognizing.

**Error 1: Off by one when looping over indexes.**

When you loop over positions instead of elements, it is easy to go one step too far. An array of length 5 has indexes 0 to 4.

```rust
// Wrong
fn main() {
    let scores = [80, 92, 67, 75, 88];
    for i in 0..=scores.len() {
        println!("Score {i}: {}", scores[i]);
    }
}

// Correct
fn main() {
    let scores = [80, 92, 67, 75, 88];
    for i in 0..scores.len() {
        println!("Score {i}: {}", scores[i]);
    }
}
```

The wrong version compiles, prints the five scores, and then crashes on the sixth iteration with a panic: `index out of bounds: the len is 5 but the index is 5`. `0..=scores.len()` includes 5, which is not a valid index. The exclusive range `0..scores.len()` stops at 4. Even better, when you do not need the index, loop over the elements directly with `for score in scores`, which cannot go out of bounds at all.

**Error 2: Using an exclusive range when you meant to include the end.**

This mistake does not produce any error message, which makes it sneaky.

```rust
// Wrong: prints 1 2 3 4
for number in 1..5 {
    print!("{number} ");
}

// Correct: prints 1 2 3 4 5
for number in 1..=5 {
    print!("{number} ");
}
```

The wrong version prints `1 2 3 4 ` because `1..5` excludes 5. If your output is missing its last item, check the range first. Use `..=` when the end value should be included.

**Error 3: Trying to return a value from a `while` loop.**

Only `loop` can produce a value with `break`. A `while` loop might end because its condition became false, in which case no `break` value would exist.

```rust
// Wrong
fn main() {
    let mut n = 0;
    let result = while n < 10 {
        n += 1;
        if n == 5 {
            break n;
        }
    };
    println!("{result:?}");
}

// Correct
fn main() {
    let mut n = 0;
    let result = loop {
        n += 1;
        if n == 5 {
            break n;
        }
    };
    println!("{result:?}");
}
```

The wrong version produces ``error[E0571]: `break` with value from a `while` loop``, with the note ``can only break with a value inside `loop` or breakable block``. Switch to `loop` when you need a value out of the loop, and make sure every path eventually reaches `break`.

**Error 4: Forgetting to update the loop variable.**

A `while` loop whose condition never changes runs forever.

```rust
// Wrong: countdown never changes, so the loop never ends
let mut countdown = 5;
while countdown > 0 {
    print!("{countdown}... ");
}

// Correct
let mut countdown = 5;
while countdown > 0 {
    print!("{countdown}... ");
    countdown -= 1;
}
```

The wrong version compiles (with a warning that `countdown` does not need to be mutable, which is a useful hint) and then never stops. Press `Ctrl` + `C` to end it. Always check that something inside a `while` loop moves the condition toward false.

---

## 7. Exercises

**Exercise 1:** Create a project called `sums`. Use a `for` loop to calculate the sum of all numbers from 1 to 100. Then calculate the sum of only the even numbers from 1 to 100, using `continue` to skip the odd ones. Print both results.

**Exercise 2:** Create a project called `price_stats`. Store five prices in an array: `45_000`, `120_000`, `18_500`, `250_000`, `76_000`. Using a single `for` loop, find the highest price, the lowest price, and the number of prices at Rp100,000 or more. Print the array and the three results.

**Exercise 3:** Create a project called `patterns`. First, use a `while` loop to solve this puzzle: start with 27; if the number is even, halve it; if it is odd, multiply it by 3 and add 1; repeat until the number is 1, and count the steps. Then use nested `for` loops to print a triangle of stars with four rows (one star in the first row, four in the last).

---

## 8. Solutions

**Solution for Exercise 1:**

```rust
fn main() {
    let mut sum = 0;
    for number in 1..=100 {
        sum += number;
    }
    println!("Sum of 1 to 100: {sum}");

    let mut even_sum = 0;
    for number in 1..=100 {
        if number % 2 != 0 {
            continue;
        }
        even_sum += number;
    }
    println!("Sum of even numbers from 1 to 100: {even_sum}");
}
```

Both parts use the running total pattern with an inclusive range so that 100 is included. In the second loop, `number % 2 != 0` is true for odd numbers, and `continue` skips them before they reach the addition. The program prints:

```text
Sum of 1 to 100: 5050
Sum of even numbers from 1 to 100: 2550
```

**Solution for Exercise 2:**

```rust
fn main() {
    let prices = [45_000, 120_000, 18_500, 250_000, 76_000];
    let mut highest = prices[0];
    let mut lowest = prices[0];
    let mut expensive_items = 0;

    for price in prices {
        if price > highest {
            highest = price;
        }
        if price < lowest {
            lowest = price;
        }
        if price >= 100_000 {
            expensive_items += 1;
        }
    }

    println!("Prices: {:?}", prices);
    println!("Highest: Rp{highest}");
    println!("Lowest: Rp{lowest}");
    println!("Items at Rp100000 or more: {expensive_items}");
}
```

`highest` and `lowest` both start with the first price, which is a safe starting point because it is a real value from the array. (Starting `lowest` at 0 would be a bug: no price is below 0, so it would never change.) Each iteration compares the current price against the best values seen so far and replaces them when needed. The third `if` is a counter: it adds 1 whenever the condition is true. The three `if` statements are independent, so a single price can update more than one result. The program prints:

```text
Prices: [45000, 120000, 18500, 250000, 76000]
Highest: Rp250000
Lowest: Rp18500
Items at Rp100000 or more: 2
```

**Solution for Exercise 3:**

```rust
fn main() {
    let mut number = 27;
    let mut steps = 0;

    while number != 1 {
        if number % 2 == 0 {
            number /= 2;
        } else {
            number = number * 3 + 1;
        }
        steps += 1;
    }
    println!("27 reaches 1 after {steps} steps.");

    for row in 1..=4 {
        for _ in 0..row {
            print!("*");
        }
        println!();
    }
}
```

`while` is the right loop for the puzzle because the number of steps is not known in advance; the loop runs until `number` equals 1. The `if` inside picks the rule for even or odd numbers, and `number /= 2` is the shorthand for `number = number / 2`. For the triangle, the inner loop's range depends on the outer loop's variable: `0..row` runs once in the first row, twice in the second, and so on. The inner loop does not use its variable, so it is named `_`, which tells Rust (and readers) that the value is intentionally ignored. The program prints:

```text
27 reaches 1 after 111 steps.
*
**
***
****
```

---

## Next Up - Lesson 7

In this lesson you repeated work with Rust's three loops. You used `loop` with `break` and returned a value from it, used `while` for condition based repetition, and used `for` to walk through ranges and arrays. You controlled loops with `continue` and `break`, kept running totals, nested loops to build a grid, and learned to spot off by one errors and infinite loops.

Your `main` functions are getting long. In Lesson 7, you will learn to split programs into smaller, named functions with parameters and return values, so each piece of logic is written once and reused wherever you need it.
