## 1. Before You Begin

In Lesson 3 you stored values in variables and saw the compiler reject `level = "two"` with a `mismatched types` error. That error exists because every value in Rust has a type, and the compiler checks types before the program runs. The type tells Rust what kind of data a value is, how much memory it needs, and which operations make sense for it. Adding two numbers makes sense; adding a number to a piece of text does not.

This lesson tours Rust's basic types. You will work with whole numbers and decimal numbers, true and false values, single characters, and two ways of grouping values: tuples and arrays. Along the way, you will use operators to calculate, compare, and combine values, and learn how to convert one numeric type into another.

### What You'll Build

A single program, `data_types`, that demonstrates each type with realistic values: a class size, a temperature, a discounted price, a pass or fail check, a product record, and a list of test scores with their average. The final output is a 26 line report that you will check line by line.

### What You'll Learn

- ✅ Integer types such as `i32`, `u8`, and `u64`, and their ranges
- ✅ Floating point types (`f64`) for decimal numbers
- ✅ Arithmetic operators, including integer division and the remainder operator `%`
- ✅ Booleans, comparison operators, and logical operators (`&&`, `||`, `!`)
- ✅ The `char` type for single characters
- ✅ Tuples for grouping values of different types, and destructuring
- ✅ Arrays for fixed lists of values of the same type
- ✅ Type annotations, type inference, and conversion with `as`

### What You'll Need

- The `~/rust-basics` folder and a working Rust installation (Lesson 2)
- Familiarity with `let`, `mut`, and `println!` placeholders (Lesson 3)

---

## 2. Whole Numbers and Decimal Numbers

Numbers are the most common data in programs, and Rust divides them into two families. Integers are whole numbers without a fractional part, such as `27`, `-3`, or `8100000000`. Floating point numbers (floats, for short) have a fractional part, such as `12.5` or `0.1`. The two families are stored differently in memory and Rust never mixes them silently.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new data_types
cd data_types
```

These commands create a new Cargo project called `data_types` and move into it. You will write the whole program in `src/main.rs`, adding one block at a time.

### Step 2: Integer Types

Replace the contents of `src/main.rs` with:

```rust
fn main() {
    // Integers: whole numbers.
    let students: i32 = 27;
    let temperature: i32 = -3;
    let age: u8 = 19;
    let population: u64 = 8_100_000_000;
    println!("Students: {students}, temperature: {temperature}, age: {age}");
    println!("World population: {population}");
    println!("u8 range: {} to {}", u8::MIN, u8::MAX);
    println!("i32 range: {} to {}", i32::MIN, i32::MAX);
```

Do not add the closing brace of `main` yet; you will keep adding lines and close the function at the end of the lesson.

The part after the variable name, such as `: i32`, is a type annotation. It tells the compiler exactly which type to use. Integer type names follow a simple pattern: `i` means signed (can be negative), `u` means unsigned (zero or positive only), and the number is how many bits of memory the value uses. More bits means a larger range.

| Type | Range | Typical use |
| --- | --- | --- |
| `u8` | 0 to 255 | Ages, small counts, bytes |
| `i32` | about -2.1 billion to 2.1 billion | The default for whole numbers |
| `u32` | 0 to about 4.2 billion | Counts that are never negative |
| `i64` / `u64` | very large ranges | Big totals, populations, timestamps |
| `usize` | depends on the computer (64 bit on most PCs) | Positions and lengths of lists |

`students` and `temperature` use `i32`, which is Rust's default integer type. The temperature is negative, so it needs a signed type. `age` uses `u8` because an age is never negative and never above 255. `population` needs `u64` because eight billion does not fit in an `i32`. The underscores in `8_100_000_000` are visual separators, like thousands separators on paper; the compiler ignores them.

`u8::MIN` and `u8::MAX` are constants built into Rust that hold the smallest and largest value of a type. Printing them makes the ranges in the table concrete.

### Step 3: Floating Point Numbers and Type Inference

Add these lines below the previous ones:

```rust
    // Floating point numbers: numbers with a fractional part.
    let price: f64 = 12.5;
    let discount = 0.1;
    println!("Price: {price}, discount: {discount}");
```

`f64` is a 64 bit floating point number and the default choice for decimals in Rust. (There is also `f32`, which uses less memory but is less precise.) `price` has an explicit annotation. `discount` does not, and that is fine: when you leave out the type, Rust infers it from the value. A literal with a decimal point, such as `0.1`, becomes an `f64`; a literal without one, such as `27`, becomes an `i32`. You only need annotations when you want a type other than the default, as with `u8` and `u64` above, or when the compiler cannot work it out.

### Step 4: Arithmetic

Add the arithmetic examples:

```rust
    // Arithmetic.
    let a = 17;
    let b = 5;
    println!("{a} + {b} = {}", a + b);
    println!("{a} - {b} = {}", a - b);
    println!("{a} * {b} = {}", a * b);
    println!("{a} / {b} = {}", a / b);
    println!("{a} % {b} = {}", a % b);
    println!("17.0 / 5.0 = {}", 17.0 / 5.0);
    let final_price = price - price * discount;
    println!("Final price: {final_price:.2}");
```

Rust uses `+` for addition, `-` for subtraction, `*` for multiplication, and `/` for division. Each `println!` here mixes an inline placeholder (`{a}`) with a positional one (`{}`), whose value is the calculation listed after the string.

Two lines deserve attention. When both values are integers, `/` performs integer division: `17 / 5` gives `3` and throws away the fractional part. The `%` operator, called remainder or modulo, gives what is left over: 17 divided by 5 is 3 with 2 left over, so `17 % 5` is `2`. Remainders are surprisingly useful; for example, `n % 2` is 0 for even numbers and 1 for odd ones. When the values are floats, as in `17.0 / 5.0`, division keeps the fraction and gives `3.4`.

`final_price` applies a 10 percent discount. Multiplication happens before subtraction, just as in school math, so Rust first calculates `price * discount` (1.25) and then subtracts it from `price`. Use parentheses whenever you want a different order or simply want to make the order obvious.

---

## 3. True, False, and Characters

Not all data is numeric. Programs constantly ask yes or no questions ("did the student pass?", "is the user logged in?"), and they work with individual letters and symbols. Rust has a dedicated type for each.

### Step 1: Booleans and Comparisons

Add these lines:

```rust
    // Booleans and comparisons.
    let is_raining = false;
    let has_umbrella = true;
    let score = 78;
    let passed = score >= 75;
    println!("Passed: {passed}");
    println!("score == 100: {}", score == 100);
    println!("score != 100: {}", score != 100);
    println!("Stay dry: {}", !is_raining || has_umbrella);
    println!("Perfect and passed: {}", score == 100 && passed);
```

A boolean (type `bool`) has exactly two possible values: `true` and `false`. You can write them directly, as with `is_raining` and `has_umbrella`, but booleans usually come from comparisons. `score >= 75` asks "is score greater than or equal to 75?" and produces `true` or `false`, which is stored in `passed`.

Rust has six comparison operators: `==` (equal), `!=` (not equal), `<` (less than), `>` (greater than), `<=` (less than or equal), and `>=` (greater than or equal). Note that equality is tested with two equals signs; a single `=` means assignment.

Booleans can be combined with logical operators. `&&` (and) is `true` only when both sides are true. `||` (or) is `true` when at least one side is true. `!` (not) flips a boolean. `!is_raining || has_umbrella` reads as "it is not raining, or I have an umbrella," which is true here. `score == 100 && passed` is false because the score is not 100, even though `passed` is true. In Lesson 5, you will use booleans like these to make decisions with `if`.

### Step 2: Characters

Add the character example:

```rust
    // Characters.
    let grade = 'B';
    let heart = '❤';
    println!("Grade: {grade}, symbol: {heart}");
```

The `char` type holds a single character and is written with single quotes. This is an important difference: `'B'` is a `char`, while `"B"` is a string (text that could be any length). A Rust `char` is a Unicode character, so it can hold letters from any alphabet, digits, symbols, and even emoji such as `'❤'`, not only English letters.

---

## 4. Group Values with Tuples and Arrays

Often several values belong together: a product has a name, quantity, and price; a class has a list of test scores. Rust has two simple compound types for grouping values. Both have a fixed size that cannot grow or shrink. (In Lesson 13 you will meet vectors, which can grow.)

### Step 1: Tuples

Add the tuple example:

```rust
    // Tuples: a fixed group of values with different types.
    let product = ("Notebook", 3, 12.75);
    println!("Product: {}, qty: {}, price: {}", product.0, product.1, product.2);
    let (name, qty, unit_price) = product;
    println!("Total for {name}: {:.2}", qty as f64 * unit_price);
```

A tuple is written as values separated by commas inside parentheses. The values can have different types: here a string, an integer, and a float. You access each element with a dot followed by its position, counting from zero: `product.0` is `"Notebook"`, `product.1` is `3`, and `product.2` is `12.75`.

`let (name, qty, unit_price) = product;` is called destructuring. It unpacks the tuple into three separate variables in one line, matching names to positions. This is usually more readable than `product.0` and `product.1`.

The last line multiplies quantity by unit price. `qty` is an integer and `unit_price` is a float, and Rust will not multiply them directly (you will see the error in Section 7). `qty as f64` converts the integer into a float first. The `as` keyword is covered in Section 5.

### Step 2: Arrays

Add the array example:

```rust
    // Arrays: a fixed number of values of the same type.
    let scores = [80, 92, 67, 75, 88];
    println!("First score: {}, last score: {}", scores[0], scores[4]);
    println!("Number of scores: {}", scores.len());
    println!("All scores: {:?}", scores);
    let total = scores[0] + scores[1] + scores[2] + scores[3] + scores[4];
    let average = total as f64 / scores.len() as f64;
    println!("Average: {average:.1}");
```

An array is written with square brackets, and all of its elements must have the same type. Elements are accessed by index in square brackets, again starting at zero: `scores[0]` is the first element and `scores[4]` is the fifth and last. The index of the last element is always the length minus one. `scores.len()` returns the number of elements, which is 5.

`{:?}` is a different kind of placeholder. Plain `{}` is for output meant for end users, and arrays do not support it. `{:?}` uses debug formatting, which is meant for programmers and prints the array with its brackets and commas. You will use `{:?}` often to inspect values while learning.

The average is the total divided by the number of scores. Both `total` and `scores.len()` are integers, and integer division would cut off the decimals, so both are converted with `as f64` before dividing. The array type, if you want to write it out, is `[i32; 5]`: the element type, a semicolon, and the length. Adding up five elements by hand is tedious; in Lesson 6 you will use a loop instead.

---

## 5. Convert Between Number Types

Rust never converts between numeric types automatically, even when the conversion looks harmless. This prevents a whole category of bugs where precision is lost without anyone noticing. When you do want a conversion, you ask for it explicitly with `as`.

### Step 1: Use as and Close the Program

Add the last block and close `main` with its brace:

```rust
    // Type conversion with as.
    let whole = 9.99_f64 as i32;
    let big: i32 = 300;
    let small = big as u8;
    println!("9.99 as i32 = {whole}");
    println!("300 as u8 = {small}");
}
```

`9.99_f64` is a float literal with a type suffix, which is another way to state a type. Converting it with `as i32` does not round; it simply drops the fraction, giving `9`. `big as u8` is more surprising: 300 does not fit in a `u8`, whose maximum is 255, so `as` wraps the value around (300 minus 256 is 44). `as` always succeeds, even when the result is wrong for your purpose, so use it only when you are sure the value fits, such as converting an integer count to `f64` for division. Lesson 15 shows safer conversions that report failures.

---

## 6. Run and Test

Run the complete program:

```bash
cargo run -q
```

```text
Students: 27, temperature: -3, age: 19
World population: 8100000000
u8 range: 0 to 255
i32 range: -2147483648 to 2147483647
Price: 12.5, discount: 0.1
17 + 5 = 22
17 - 5 = 12
17 * 5 = 85
17 / 5 = 3
17 % 5 = 2
17.0 / 5.0 = 3.4
Final price: 11.25
Passed: true
score == 100: false
score != 100: true
Stay dry: true
Perfect and passed: false
Grade: B, symbol: ❤
Product: Notebook, qty: 3, price: 12.75
Total for Notebook: 38.25
First score: 80, last score: 88
Number of scores: 5
All scores: [80, 92, 67, 75, 88]
Average: 80.4
9.99 as i32 = 9
300 as u8 = 44
```

Walk through the output and match each line to the code. The ranges show why `u8` cannot hold 300 and why `i32` cannot hold a world population. Integer division gives `3`, float division gives `3.4`. The comparisons print `true` or `false`. `{:?}` printed the whole array. The average of 80, 92, 67, 75, and 88 is 402 divided by 5, which is 80.4. The last two lines show that `as` truncates floats and wraps integers that do not fit.

If your output differs, compare your code with each step. A missing `as f64`, for example, would cause a compile error rather than different output, which brings us to the next section.

---

## 7. Fix the Errors in Your Code

Type errors are the most common compiler errors in Rust. Each of these comes from a real misunderstanding about types, and the compiler message points straight at it.

**Error 1: Mixing integers and floats in arithmetic.**

Rust does not convert an integer to a float automatically, even in a simple multiplication.

```rust
// Wrong
fn main() {
    let quantity = 3;
    let price = 12.5;
    let total = quantity * price;
    println!("Total: {total}");
}

// Correct
fn main() {
    let quantity = 3;
    let price = 12.5;
    let total = quantity as f64 * price;
    println!("Total: {total}");
}
```

The wrong version produces ``error[E0277]: cannot multiply `{integer}` by `{float}` ``. `{integer}` and `{float}` are the compiler's way of saying "some integer type" and "some float type" before it has picked an exact one. The message continues with a long list of types that *can* be multiplied, which you can skip. The fix is to convert one side with `as` so both sides are floats. Alternatively, write the quantity as `3.0` if it is never used as an integer.

**Error 2: Storing a value that does not fit in the type.**

Every integer type has a range. A literal outside that range is rejected at compile time.

```rust
// Wrong
fn main() {
    let age: u8 = 300;
    println!("Age: {age}");
}

// Correct
fn main() {
    let age: u16 = 300;
    println!("Age: {age}");
}
```

The wrong version produces ``error: literal out of range for `u8` ``, and the note explains that `300` does not fit into a type whose range is `0..=255`. Choose a type with a larger range, such as `u16` (0 to 65,535) or the default `i32`.

When the overflow happens while the program is running instead of in a literal, Rust stops the program in debug builds. For example, a `u8` holding 250 that is increased by 10 makes `cargo run` stop with a message containing `attempt to add with overflow`. Stopping the program on an error like this is called a panic, and you will learn more about it in Lesson 15.

**Error 3: Using an index that is out of bounds.**

An array of length 5 has indexes 0 to 4. Index 5 does not exist.

```rust
// Wrong
fn main() {
    let scores = [80, 92, 67, 75, 88];
    println!("Score: {}", scores[5]);
}

// Correct
fn main() {
    let scores = [80, 92, 67, 75, 88];
    println!("Score: {}", scores[4]);
}
```

The wrong version produces `error: this operation will panic at runtime`, with the explanation `index out of bounds: the length is 5 but the index is 5`. Here the compiler can see the problem because the index is a fixed number. When the index comes from a calculation, the compiler cannot know it in advance, and the program panics at runtime instead. Either way, Rust never reads memory outside the array, which is one of the safety guarantees mentioned in Lesson 1.

**Error 4: Using double quotes for a `char`.**

Single quotes make a `char`; double quotes make a string. They are different types.

```rust
// Wrong
fn main() {
    let initial: char = "D";
    println!("{initial}");
}

// Correct
fn main() {
    let initial: char = 'D';
    println!("{initial}");
}
```

The wrong version produces `error[E0308]: mismatched types` with ``expected `char`, found `&str` ``. The `help` section even shows the fix: ``if you meant to write a `char` literal, use single quotes``.

---

## 8. Exercises

**Exercise 1:** Create a project called `bmi`. Store a weight of `68.0` kilograms and a height of `1.72` meters as `f64` values. Calculate the body mass index (weight divided by height squared), print it with one decimal place, and print whether it is in the healthy range of 18.5 to 24.9 as a boolean.

**Exercise 2:** Create a project called `duration`. Store `7384` seconds in a variable and use integer division and `%` to print it as hours, minutes, and seconds in the form `7384 seconds = 2h 3m 4s`.

**Exercise 3:** Create a project called `weather`. Store seven daily temperatures in an array of `f64` (`31.5, 32.0, 29.8, 30.4, 33.1, 28.9, 30.0`). Print the whole array with `{:?}`, print the average with two decimal places, and print a boolean that answers "was the last day warmer than the first day?". Use tuple destructuring to get the first and last temperatures in one `let`.

---

## 9. Solutions

**Solution for Exercise 1:**

```rust
fn main() {
    let weight_kg: f64 = 68.0;
    let height_m: f64 = 1.72;
    let bmi = weight_kg / (height_m * height_m);
    println!("Weight: {weight_kg} kg, height: {height_m} m");
    println!("BMI: {bmi:.1}");
    println!("Healthy range (18.5 to 24.9): {}", bmi >= 18.5 && bmi <= 24.9);
}
```

The parentheses make sure the height is squared before dividing. Without them, Rust would divide by the height and then multiply by the height again, which gives the original weight. The healthy range check combines two comparisons with `&&`, so it is true only when the BMI is at least 18.5 *and* at most 24.9. The program prints:

```text
Weight: 68 kg, height: 1.72 m
BMI: 23.0
Healthy range (18.5 to 24.9): true
```

Notice that `68.0` prints as `68`: when a float has no fractional part, `{}` leaves out the `.0`. Use a precision option such as `{weight_kg:.1}` if you always want a decimal shown.

**Solution for Exercise 2:**

```rust
fn main() {
    let total_seconds = 7384;
    let hours = total_seconds / 3600;
    let minutes = total_seconds % 3600 / 60;
    let seconds = total_seconds % 60;
    println!("{total_seconds} seconds = {hours}h {minutes}m {seconds}s");
}
```

An hour has 3600 seconds, so integer division by 3600 gives the whole hours (2). `total_seconds % 3600` gives the seconds left after removing whole hours (184), and dividing that by 60 gives the whole minutes (3). `% 60` gives the seconds left after removing whole minutes (4). `%` and `/` have the same priority and are evaluated left to right, so `total_seconds % 3600 / 60` works without parentheses. The program prints:

```text
7384 seconds = 2h 3m 4s
```

**Solution for Exercise 3:**

```rust
fn main() {
    let temperatures: [f64; 7] = [31.5, 32.0, 29.8, 30.4, 33.1, 28.9, 30.0];
    let total = temperatures[0] + temperatures[1] + temperatures[2] + temperatures[3]
        + temperatures[4] + temperatures[5] + temperatures[6];
    let average = total / temperatures.len() as f64;
    let (first, last) = (temperatures[0], temperatures[6]);
    println!("Temperatures: {:?}", temperatures);
    println!("Average: {average:.2}");
    println!("Warmer at the end of the week: {}", last > first);
}
```

The annotation `[f64; 7]` says "an array of seven `f64` values." The total is long enough to split over two lines; Rust does not care about line breaks inside an expression, only about the semicolon at the end. The elements are already floats, so only `len()`, which returns a `usize`, needs `as f64`. `let (first, last) = (temperatures[0], temperatures[6]);` builds a tuple on the right and destructures it on the left in one step. The program prints:

```text
Temperatures: [31.5, 32.0, 29.8, 30.4, 33.1, 28.9, 30.0]
Average: 30.81
Warmer at the end of the week: false
```

The last day (30.0) was cooler than the first (31.5), so the comparison is `false`.

---

## Next Up - Lesson 5

In this lesson you learned Rust's basic types: integers with different sizes and signs, `f64` floats, booleans, and characters. You calculated with arithmetic operators, compared values with comparison operators, combined booleans with `&&`, `||`, and `!`, grouped values in tuples and arrays, and converted numbers with `as`. You also saw how the compiler catches type mismatches, out of range literals, and out of bounds indexes before the program runs.

So far, every program runs every line from top to bottom. In Lesson 5, you will make programs choose between different paths with `if`, `else if`, `else`, and Rust's powerful `match` expression, using the comparisons and booleans you just learned.
