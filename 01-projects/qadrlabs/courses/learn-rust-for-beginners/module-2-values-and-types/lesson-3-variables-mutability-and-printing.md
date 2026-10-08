## 1. Before You Begin

In Lesson 2 you installed Rust and ran Hello World as a Cargo project. That program printed fixed text, which is a good start but not very useful. Real programs work with data that comes from somewhere, gets stored, changes over time, and is shown to the user in a readable form. The tool for storing data is the variable.

This lesson introduces variables in Rust. You will learn how to create them with `let`, why Rust variables cannot change unless you explicitly allow it, how constants differ from variables, and a Rust feature called shadowing. You will also learn the formatting options of `println!` so your output looks exactly the way you want.

### What You'll Build

A small "character sheet" program for a game hero. It stores the hero's name, class, level, and gold, updates some of those values as the hero completes quests, and prints a formatted summary that includes an aligned table and a rounded decimal number.

### What You'll Learn

- ✅ How to create variables with `let`
- ✅ Why variables are immutable by default and how `mut` changes that
- ✅ Shorthand operators such as `+=` and `-=`
- ✅ How constants are declared with `const` and when to use them
- ✅ What shadowing is and how it differs from `mut`
- ✅ How to print values with `{}`, named placeholders, and positional arguments
- ✅ How to align text, set widths, and round decimals in output
- ✅ The difference between `print!` and `println!`

### What You'll Need

- Rust installed and working (Lesson 2)
- The `~/rust-basics` folder from Lesson 2
- A terminal and a text editor

---

## 2. Store Values with let

A variable is a name attached to a value. Think of it as a labeled box: the label is the variable name, and the content is the value. Once a value has a name, you can use the name anywhere you need that value instead of repeating the value itself.

### Step 1: Create the Project

Open a terminal and create a new Cargo project for this lesson:

```bash
cd ~/rust-basics
cargo new variables
cd variables
```

`cargo new variables` creates a project folder named `variables` with a `Cargo.toml` file and a `src/main.rs` file, exactly like `hello_cargo` in Lesson 2. The `cd` command moves into the project so the Cargo commands you run next apply to it. Open the folder in your editor.

### Step 2: Create Your First Variables

Replace everything in `src/main.rs` with the following code:

```rust
fn main() {
    // Immutable variables: set once, never changed.
    let player = "Dina";
    let class = "Mage";
    let level = 1;

    println!("{player} the {class} starts at level {level}.");
}
```

`let` is the keyword that creates a variable. In `let player = "Dina";`, the word `player` is the variable's name, the `=` sign means "store the value on the right in the name on the left," and `"Dina"` is the value, a piece of text called a string. The semicolon ends the statement. The next two lines work the same way: `class` holds the text `"Mage"`, and `level` holds the whole number `1`. Notice that numbers are written without quotes; `1` is a number, while `"1"` would be text.

Rust variable names use `snake_case`: lowercase words joined by underscores, such as `player_name` or `max_health`. The compiler warns you if you use another style, so it is good to adopt the convention from the start.

The `println!` line prints a sentence that includes all three values. Each `{name}` inside the string is a placeholder that Rust replaces with the value of the variable with that name. This is called inline formatting, and it is the easiest way to mix text and values.

### Step 3: Run the Program

Run the project:

```bash
cargo run
```

After Cargo's `Compiling`, `Finished`, and `Running` messages, the program prints:

```text
Dina the Mage starts at level 1.
```

Every placeholder was replaced with the stored value. If you change `"Dina"` to another name and run again, the sentence changes everywhere that name is used, without touching the `println!` line. That is the main benefit of variables: data is stored once and reused by name.

---

## 3. Change Values with mut

In most programs, some data changes over time: a score goes up, a balance goes down, a counter increases. In Rust, variables are immutable by default, which means once a value is stored, it cannot be replaced. This sounds restrictive, but it is a deliberate safety feature. When you read code and see a plain `let`, you know that value will never change, which makes the code easier to reason about. When a value *does* need to change, you mark it with `mut` (short for mutable) so readers can see that clearly.

### Step 1: Try to Change an Immutable Variable

Before fixing anything, it helps to see what Rust does when you break the rule. Temporarily add this line at the end of `main`, just before the closing brace:

```rust
    level = 2;
```

This line tries to assign a new value to `level`. Run `cargo run`, and the compiler refuses:

```text
error[E0384]: cannot assign twice to immutable variable `level`
```

The full message points to the line where `level` was first assigned and the line where you tried to change it, and its `help` section suggests the fix: ``consider making this binding mutable``, with `let mut level = 1;`. Remove the line you just added before continuing.

### Step 2: Make the Level Mutable

Replace `src/main.rs` with this version:

```rust
fn main() {
    // Immutable variables: set once, never changed.
    let player = "Dina";
    let class = "Mage";

    // A mutable variable: its value can change later.
    let mut level = 1;
    println!("{player} the {class} starts at level {level}.");

    level = level + 1;
    println!("After the first quest, {player} reaches level {level}.");

    level += 3;
    println!("After three more quests, {player} is level {level}.");
}
```

`let mut level = 1;` creates a mutable variable. The keyword `mut` goes between `let` and the name, and it is the only difference from an ordinary `let`. `player` and `class` stay immutable because a hero's name and class do not change in this program.

`level = level + 1;` reassigns the variable. Notice there is no `let` this time; `let` creates a new variable, while a plain `name = value` changes an existing one. Rust evaluates the right side first: it reads the current value of `level` (1), adds 1, and stores the result (2) back into `level`.

`level += 3;` is a shorthand for `level = level + 3;`. Rust has the same shorthand for other operations: `-=` subtracts, `*=` multiplies, and `/=` divides. The shorthand only works on mutable variables, because it changes the value in place.

The `println!` calls between the assignments show the value at each point. Statements run from top to bottom, so each `println!` sees whatever `level` holds at that moment.

### Step 3: Run the Program

Run `cargo run` again. The program prints:

```text
Dina the Mage starts at level 1.
After the first quest, Dina reaches level 2.
After three more quests, Dina is level 5.
```

The same variable shows three different values because it was printed three times, each after a different change. Being able to change a value step by step is what makes counters, totals, and game states possible.

---

## 4. Constants and Shadowing

Rust has two more ways to work with named values: constants, for values that are fixed for the whole program, and shadowing, for reusing a name with a new value. They look similar to variables but solve different problems.

### Step 1: Add a Constant

Constants are values that never change and are known before the program runs, such as the maximum level in a game, the number of seconds in a minute, or a tax rate. Add the following line at the very top of `src/main.rs`, above `fn main()`:

```rust
const MAX_LEVEL: u32 = 50;
```

`const` declares a constant. Three rules make constants different from `let` variables. First, the name is written in `SCREAMING_SNAKE_CASE`: all uppercase with underscores. Second, the type must always be written out; here `: u32` says the constant is an unsigned 32 bit integer, a whole number that cannot be negative. (You will learn about types in detail in Lesson 4.) Third, constants can be declared outside any function, so every function in the file can use them, and they can never be made mutable.

Now change the last `println!` in `main` so it also shows the maximum level:

```rust
    println!("After three more quests: level {level} of {MAX_LEVEL}.");
```

Constants are used in placeholders exactly like variables. Giving a fixed number a name such as `MAX_LEVEL` also makes the code self explanatory: `50` alone says nothing, while `MAX_LEVEL` says what the number means.

### Step 2: Shadow a Variable

Shadowing means declaring a new variable with the same name as an existing one, using `let` again. The new variable "shadows" the old one: from that point on, the name refers to the new value. Add these lines inside `main`, after the last `println!`:

```rust
    // Shadowing: a new variable that reuses an existing name.
    let gold = 120;
    let gold = gold + 30;
    println!("Gold after selling an item: {gold}");

    let title = "   Archmage   ";
    let title = title.trim();
    println!("Title: [{title}]");
```

The first `let gold = 120;` creates an immutable variable. The second `let gold = gold + 30;` creates a *brand new* variable, also named `gold`, whose value is calculated from the old one: 120 plus 30 equals 150. After this line, `gold` refers to 150. Neither variable is mutable; the second simply replaces the first name.

The `title` example shows why shadowing is useful. The first `title` is text with extra spaces around it. `title.trim()` produces the same text without the leading and trailing spaces. Shadowing lets you keep the meaningful name `title` for the cleaned value instead of inventing names such as `title_trimmed`. The square brackets in the `println!` make the absence of spaces visible in the output.

Shadowing and `mut` are not the same. With `mut`, there is one variable whose value changes, and the new value must have the same type as the old one. With shadowing, there are two separate variables, and the new one can even have a different type. You will see that difference again in Lesson 8, when you turn text typed by the user into a number.

---

## 5. Format Your Output

So far you have used inline placeholders like `{player}`. `println!` supports several other ways to insert values, plus options that control alignment, width, and decimal places. These are worth learning early because every program you write prints something.

### Step 1: Positional and Numbered Placeholders

Add these lines at the end of `main`:

```rust
    // Formatting options.
    println!("{} has {} gold and is level {}.", player, gold, level);
    println!("{0} says: {1}! {1}!", player, "Ready");
```

In the first line, each empty `{}` is filled by the values listed after the string, in order: the first `{}` gets `player`, the second gets `gold`, and the third gets `level`. This style is useful when the value is not a simple variable name, such as the result of a calculation.

In the second line, the numbers inside the braces refer to positions in the list of values, counting from zero: `{0}` is `player` and `{1}` is the text `"Ready"`. Numbered placeholders let you use the same value more than once without listing it twice.

### Step 2: Align Text in Columns

Add a small table:

```rust
    println!("|{:<10}|{:>6}|", "Name", "Level");
    println!("|{:<10}|{:>6}|", player, level);
```

Options go after a colon inside the braces. `{:<10}` means "left align (`<`) the value in a space 10 characters wide." `{:>6}` means "right align (`>`) in a space 6 characters wide." Shorter values are padded with spaces, so every row lines up. The `|` characters are plain text that makes the column edges visible. Use `^` instead of `<` or `>` to center a value.

### Step 3: Round Decimal Numbers

Add these lines:

```rust
    let health = 87.456;
    println!("Health: {health:.1}%");
```

`87.456` is a decimal number (Rust calls it a floating point number; more on that in Lesson 4). The option `:.1` inside `{health:.1}` rounds the value to one digit after the decimal point when printing. The stored value is not changed; only its printed form is. The `%` after the closing brace is ordinary text.

### Step 4: print! and Escaped Braces

Finish `main` with these lines:

```rust
    print!("Saving");
    print!("...");
    println!(" done.");

    println!("Use {{ and }} to print braces.");
}
```

`print!` works like `println!` but does not add a new line at the end, so the next output continues on the same line. The three calls above produce a single line of text. `println!` at the end finishes the line.

Because `{` and `}` have special meaning inside `println!`, you write them twice, `{{` and `}}`, when you want an actual brace in the output. The closing `}` on the last line ends the `main` function.

---

## 6. Run and Test

Your complete `src/main.rs` should now look like this:

```rust
const MAX_LEVEL: u32 = 50;

fn main() {
    // Immutable variables: set once, never changed.
    let player = "Dina";
    let class = "Mage";

    // A mutable variable: its value can change later.
    let mut level = 1;
    println!("{player} the {class} starts at level {level}.");

    level = level + 1;
    println!("After the first quest, {player} reaches level {level}.");

    level += 3;
    println!("After three more quests: level {level} of {MAX_LEVEL}.");

    // Shadowing: a new variable that reuses an existing name.
    let gold = 120;
    let gold = gold + 30;
    println!("Gold after selling an item: {gold}");

    let title = "   Archmage   ";
    let title = title.trim();
    println!("Title: [{title}]");

    // Formatting options.
    println!("{} has {} gold and is level {}.", player, gold, level);
    println!("{0} says: {1}! {1}!", player, "Ready");

    println!("|{:<10}|{:>6}|", "Name", "Level");
    println!("|{:<10}|{:>6}|", player, level);

    let health = 87.456;
    println!("Health: {health:.1}%");

    print!("Saving");
    print!("...");
    println!(" done.");

    println!("Use {{ and }} to print braces.");
}
```

The constant sits above `main`, and the body runs top to bottom through the four topics of this lesson: immutable variables, a mutable variable, shadowing, and formatting. Run it, this time with `-q` to hide Cargo's messages:

```bash
cargo run -q
```

```text
Dina the Mage starts at level 1.
After the first quest, Dina reaches level 2.
After three more quests: level 5 of 50.
Gold after selling an item: 150
Title: [Archmage]
Dina has 150 gold and is level 5.
Dina says: Ready! Ready!
|Name      | Level|
|Dina      |     5|
Health: 87.5%
Saving... done.
Use { and } to print braces.
```

Check each line against the code. `level` shows 1, 2, and then 5. `gold` shows 150 because of shadowing. The title has no extra spaces. The table columns line up because both rows use the same widths. `87.456` printed as `87.5` because of rounding to one decimal place. The three `print!`/`println!` calls produced one line, and the doubled braces printed as single ones.

---

## 7. Fix the Errors in Your Code

These are the mistakes beginners make most often with variables and printing.

**Error 1: Changing a variable that is not mutable.**

Plain `let` variables cannot be reassigned. Forgetting `mut` is the most common error for people learning Rust.

```rust
// Wrong
fn main() {
    let level = 1;
    println!("Level: {level}");
    level = 2;
    println!("Level: {level}");
}

// Correct
fn main() {
    let mut level = 1;
    println!("Level: {level}");
    level = 2;
    println!("Level: {level}");
}
```

The wrong version produces ``error[E0384]: cannot assign twice to immutable variable `level` ``, and the compiler's `help` section shows exactly where to add `mut`. Only add `mut` when a value really needs to change; if it does not, leave it immutable.

**Error 2: Giving a mutable variable a value of a different type.**

`mut` allows the *value* to change, but not its type. A variable that started as a number must stay a number.

```rust
// Wrong
fn main() {
    let mut level = 1;
    level = "two";
    println!("Level: {level}");
}

// Correct
fn main() {
    let mut level = 1;
    level = 2;
    println!("Level: {level}");
}
```

The wrong version produces `error[E0308]: mismatched types`, with the note ``expected integer, found `&str` ``. `&str` is Rust's name for a piece of text like `"two"`. Rust decided that `level` holds integers when you wrote `let mut level = 1;`, and that decision is fixed. If you really need a different type under the same name, use shadowing with a new `let` instead.

**Error 3: Declaring a constant without a type.**

Unlike `let`, `const` always requires a type annotation.

```rust
// Wrong
const MAX_LEVEL = 50;

// Correct
const MAX_LEVEL: u32 = 50;
```

The wrong version produces ``error: missing type for `const` item`` and suggests a type. Add a colon and the type after the name. For counts and levels that are never negative, `u32` is a good choice.

**Error 4: Misspelling a variable name in a placeholder.**

Inline placeholders must match a variable name exactly.

```rust
// Wrong
fn main() {
    let player = "Dina";
    println!("Hello, {playr}!");
}

// Correct
fn main() {
    let player = "Dina";
    println!("Hello, {player}!");
}
```

The wrong version produces ``error[E0425]: cannot find value `playr` in this scope``, and the `help` section notes that a local variable with a similar name exists. The compiler catches typos in placeholders at compile time, so a misspelled name can never print garbage at runtime.

---

## 8. Exercises

**Exercise 1:** Create a project called `time_converter`. Declare a constant `SECONDS_PER_MINUTE` with the value 60. Store a number of minutes in a variable, calculate the number of seconds, and print a line in the form `15 minutes = 900 seconds`.

**Exercise 2:** Create a project called `wallet`. Store a starting balance of 100 in a mutable variable and print it. Subtract 35 (a book purchase) and print the new balance, then add 50 (pocket money) and print it again. Use `-=` and `+=`.

**Exercise 3:** Create a project called `receipt`. Store a product name, a price of `18.5`, and a quantity of `3` in variables. Print a two row table with the headers `Product`, `Price`, and `Qty`, where the product column is 12 characters wide and left aligned, the price column is 8 wide, right aligned, and shows two decimal places, and the quantity column is 5 wide and right aligned.

---

## 9. Solutions

**Solution for Exercise 1:**

```rust
const SECONDS_PER_MINUTE: u32 = 60;

fn main() {
    let minutes = 15;
    let seconds = minutes * SECONDS_PER_MINUTE;
    println!("{minutes} minutes = {seconds} seconds");
}
```

The constant is declared above `main` with its type, `u32`. `let minutes = 15;` stores the input value. `minutes * SECONDS_PER_MINUTE` multiplies the two (`*` is the multiplication operator) and the result is stored in `seconds`. Neither variable changes after it is created, so neither needs `mut`. The program prints:

```text
15 minutes = 900 seconds
```

**Solution for Exercise 2:**

```rust
fn main() {
    let mut balance = 100;
    println!("Starting balance: {balance}");
    balance -= 35;
    println!("After buying a book: {balance}");
    balance += 50;
    println!("After receiving pocket money: {balance}");
}
```

`balance` must be mutable because it changes twice. `balance -= 35;` is shorthand for `balance = balance - 35;`, and `balance += 50;` is shorthand for `balance = balance + 50;`. Each `println!` shows the value at that moment. The program prints:

```text
Starting balance: 100
After buying a book: 65
After receiving pocket money: 115
```

**Solution for Exercise 3:**

```rust
fn main() {
    let product = "Coffee";
    let price = 18.5;
    let quantity = 3;
    println!("|{:<12}|{:>8}|{:>5}|", "Product", "Price", "Qty");
    println!("|{:<12}|{:>8.2}|{:>5}|", product, price, quantity);
}
```

Both rows use the same widths so the columns line up. In the header row, the price column uses `{:>8}` because the header is text. In the data row, `{:>8.2}` combines two options: right align in 8 characters, and show exactly two decimal places. That is why `18.5` prints as `18.50`. The program prints:

```text
|Product     |   Price|  Qty|
|Coffee      |   18.50|    3|
```

---

## Next Up - Lesson 4

In this lesson you created variables with `let`, made them changeable with `mut`, declared constants with `const`, reused names with shadowing, and controlled your output with placeholders, alignment, widths, and decimal rounding. You also met two important compiler errors: assigning to an immutable variable and mismatched types.

That second error hinted at something bigger: every value in Rust has a type. In Lesson 4, you will learn Rust's basic data types (integers, floating point numbers, booleans, and characters), group values with tuples and arrays, and use arithmetic, comparison, and logical operators to compute new values.
