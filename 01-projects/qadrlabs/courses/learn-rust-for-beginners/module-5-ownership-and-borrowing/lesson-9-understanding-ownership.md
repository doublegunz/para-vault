## 1. Before You Begin

Modules 2 to 4 covered ideas that exist in almost every programming language: variables, types, decisions, loops, functions, and input. This module covers the idea that makes Rust different from nearly all of them: ownership. It is the reason Rust can be fast and memory safe at the same time, and it is the reason the compiler sometimes rejects code that looks perfectly reasonable.

You have already brushed against ownership. In Lesson 8, `read_line` returned `input.trim().to_string()` instead of simply `input.trim()`, and you had to write `&mut input` when calling `read_line`. This lesson explains the rules behind those details. You will learn where values live in memory, when Rust cleans them up, why assigning a `String` to another variable "moves" it, and how ownership travels into and out of functions. Lesson 10 then shows how to use values without taking ownership.

### What You'll Build

An `ownership` program that experiments with scopes, growing strings, copying numbers, moving and cloning strings, and passing strings into and out of functions. Along the way you will deliberately trigger the most famous Rust error, `borrow of moved value`, and learn to read it.

### What You'll Learn

- ✅ The difference between the stack and the heap, at a beginner level
- ✅ How scope determines when a value is dropped (cleaned up)
- ✅ How `String` differs from string literals (`&str`)
- ✅ The three ownership rules
- ✅ What a move is and why Rust invalidates the old variable
- ✅ How `clone` makes a deep copy and when `Copy` types are copied automatically
- ✅ How ownership moves into a function and back out through return values

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with functions, parameters, and return values (Lesson 7)
- Familiarity with `String::new()` and `&str` from Lesson 8

---

## 2. Why Memory Management Matters

Every value your program uses is stored somewhere in the computer's memory. When the value is no longer needed, that memory must be given back so it can be reused. If a program never gives memory back, it slowly consumes more and more until the computer runs out. If it gives memory back too early and then keeps using it, it reads garbage or crashes. Both mistakes are among the most common and dangerous bugs in software.

Programming languages handle this in one of three ways. In languages like C, the programmer allocates and frees memory manually, which is fast but error prone. In languages like Python, Java, and JavaScript, a garbage collector runs in the background, finds memory that nothing uses anymore, and frees it; this is safe but costs extra work while the program runs. Rust takes a third path: a set of ownership rules that the compiler checks at compile time. Memory is freed automatically at exactly the right moment, and no garbage collector is needed.

### The Stack and the Heap

To understand ownership, it helps to know two regions of memory, described here in simplified form.

The stack stores values whose size is known when the program is compiled, such as an `i32` (always 4 bytes), a `bool`, a `char`, or an array like `[i32; 5]`. Pushing a value onto the stack and removing it again is extremely fast, like stacking and unstacking plates.

The heap stores data whose size can change or is only known while the program runs, such as text typed by the user. When a program needs heap memory, it asks for a block of the right size and receives a pointer: an address saying where the block is. The pointer itself has a fixed size, so it can live on the stack, while the data it points to lives on the heap.

A `String` is the perfect example. A `String` variable is a small fixed size record on the stack containing three numbers: a pointer to the text on the heap, the length of the text, and the capacity of the heap block. The characters themselves are on the heap, so the text can grow. Ownership exists mainly to manage heap data like this safely.

---

## 3. Scope and the String Type

Ownership is easiest to see with `String`, because a `String` owns heap memory that must eventually be freed. In this section you will see when that happens and how a `String` differs from a text literal.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new ownership
cd ownership
```

These commands create the `ownership` project. You will build `src/main.rs` in parts, adding helper functions below `main` at the end.

### Step 2: Watch a Value Go Out of Scope

Replace the contents of `src/main.rs` with:

```rust
fn main() {
    // Scope: a variable lives until the end of its block.
    {
        let greeting = String::from("Hello");
        println!("Inside the block: {greeting}");
    } // greeting is dropped here
    println!("The block has ended.");
```

`String::from("Hello")` creates a `String` from a text literal: it requests heap memory and copies the characters into it. You can put a block in curly braces anywhere inside a function, and it creates a new scope. A scope is the region of code where a variable is valid. `greeting` is valid from the line where it is declared until the closing brace of its block.

When a variable that owns heap memory goes out of scope, Rust automatically calls a special function named `drop`, which frees the memory. This happens at the closing brace, exactly where the comment says. You never write `drop` yourself and you can never forget it. If you tried to use `greeting` after the block, the compiler would reject it, because the variable no longer exists (you will see this error in Section 7).

### Step 3: Grow a String

Add these lines:

```rust
    // A String can grow at runtime.
    let mut message = String::from("Learning");
    message.push_str(" Rust");
    message.push('!');
    println!("{message} ({} bytes)", message.len());
```

Because the text of a `String` lives on the heap, it can change size. `push_str` appends a piece of text, and `push` appends a single `char`. Both change the string, so `message` must be `mut`. `len()` returns the length in bytes: "Learning Rust!" is 14 bytes.

A text literal like `"Learning"` cannot do this. Its characters are stored directly inside the compiled program, they never change, and its type is `&str`: a reference to text stored somewhere else. You will learn what references are in Lesson 10. For now, the rule of thumb is: use `&str` for fixed text you write in your code, and `String` for text that is built, changed, or read at runtime, such as user input.

---

## 4. The Ownership Rules and Moves

The Rust Book summarizes ownership in three rules:

1. Each value in Rust has an owner, which is a variable.
2. There can only be one owner at a time.
3. When the owner goes out of scope, the value is dropped.

You have already seen rule 3 in action. Rule 2 has a surprising consequence that you will discover now: what happens when you assign one variable to another.

### Step 1: Copy a Number

Add these lines:

```rust
    // Copy types: simple values are copied.
    let a = 10;
    let b = a;
    println!("a = {a}, b = {b}");
```

`let b = a;` copies the value 10 into `b`. Both variables are usable afterward, and each has its own 10. This works because an `i32` lives entirely on the stack and copying four bytes is trivial. Types that are copied like this have a property called `Copy`. All integer and float types, `bool`, `char`, and tuples or arrays made only of `Copy` types are `Copy`.

### Step 2: Move a String

Now do the same with a `String`:

```rust
    // Move: ownership of a String moves to the new variable.
    let original = String::from("notebook");
    let moved = original;
    println!("moved = {moved}");
```

You might expect `let moved = original;` to copy the text, but it does not. Copying the heap data could be expensive for long strings, so Rust copies only the small stack record (pointer, length, capacity). Now two variables would point to the same heap memory. If both were still valid, both would try to free that memory when they went out of scope, a bug called a double free.

Rust prevents this by applying rule 2: there can only be one owner. After `let moved = original;`, ownership has moved to `moved`, and `original` is no longer valid. This is called a move. Using `moved` is fine. Try adding `println!("original = {original}");` after the move and run `cargo run`:

```text
error[E0382]: borrow of moved value: `original`
```

The full message labels three places: where `original` was declared (with the explanation that its type `String` does not implement the `Copy` trait), the line where the ``value moved here``, and the line where the ``value borrowed here after move``. "Borrowed" refers to `println!` reading the value. Remove that line before continuing.

### Step 3: Clone When You Need a Real Copy

If you really want two independent strings, ask for a deep copy explicitly:

```rust
    // Clone: make a real copy of the heap data.
    let first = String::from("pencil");
    let second = first.clone();
    println!("first = {first}, second = {second}");
```

`first.clone()` allocates new heap memory and copies all the characters into it. `first` and `second` now own separate heap data, so both are valid and each is dropped independently. Cloning has a cost proportional to the size of the data, which is why Rust never does it silently. When you see `.clone()` in code, you know a copy is being made on purpose.

---

## 5. Ownership and Functions

Passing a value to a function works exactly like assigning it to a variable: `Copy` types are copied, and other types are moved into the function's parameter. Returning a value moves ownership out of the function to the caller.

### Step 1: Move a Value into a Function

Add these lines to `main`:

```rust
    // Ownership and functions.
    let item = String::from("eraser");
    take_ownership(item);

    let count = 3;
    make_copy(count);
    println!("count is still usable: {count}");
```

Then add the two functions below `main` (after its closing brace, which you will add in Step 2):

```rust
fn take_ownership(text: String) {
    println!("take_ownership got: {text}");
} // text is dropped here

fn make_copy(number: i32) {
    println!("make_copy got: {number}");
}
```

When `main` calls `take_ownership(item)`, ownership of the `String` moves into the parameter `text`. Inside the function, `text` is the owner. When the function ends, `text` goes out of scope and the string is dropped. Back in `main`, `item` is no longer valid, so using it after the call would cause the same `borrow of moved value` error as before.

`make_copy(count)` behaves differently because `i32` is a `Copy` type. The function receives a copy of 3, and `count` in `main` stays valid, which is why the `println!` after the call works.

### Step 2: Get Ownership Back from a Function

Add these lines to the end of `main`, and close `main` with its brace:

```rust
    let created = give_ownership();
    println!("Received: {created}");

    let label = String::from("ruler");
    let label = add_price_tag(label);
    println!("After the function: {label}");
}
```

Add the two new functions below the others:

```rust
fn give_ownership() -> String {
    String::from("stapler")
}

fn add_price_tag(mut text: String) -> String {
    text.push_str(" (Rp5000)");
    text
}
```

`give_ownership` creates a `String` and returns it. The return value moves out of the function into `created` in `main`, so the string is not dropped when the function ends; it now belongs to `main`.

`add_price_tag` takes ownership of a string, changes it, and returns it. The parameter is declared `mut text: String` because the function modifies it; `mut` on a parameter works just like `mut` on a `let`. In `main`, `let label = add_price_tag(label);` moves the string in and receives it back, using shadowing to reuse the name `label`. This "take it and give it back" pattern works, but it gets tedious, especially when a function needs to return another value too. Lesson 10 introduces borrowing, which lets functions use a value without taking it at all.

---

## 6. Run and Test

Your complete `src/main.rs` should look like this:

```rust
fn main() {
    // Scope: a variable lives until the end of its block.
    {
        let greeting = String::from("Hello");
        println!("Inside the block: {greeting}");
    } // greeting is dropped here
    println!("The block has ended.");

    // A String can grow at runtime.
    let mut message = String::from("Learning");
    message.push_str(" Rust");
    message.push('!');
    println!("{message} ({} bytes)", message.len());

    // Copy types: simple values are copied.
    let a = 10;
    let b = a;
    println!("a = {a}, b = {b}");

    // Move: ownership of a String moves to the new variable.
    let original = String::from("notebook");
    let moved = original;
    println!("moved = {moved}");

    // Clone: make a real copy of the heap data.
    let first = String::from("pencil");
    let second = first.clone();
    println!("first = {first}, second = {second}");

    // Ownership and functions.
    let item = String::from("eraser");
    take_ownership(item);

    let count = 3;
    make_copy(count);
    println!("count is still usable: {count}");

    let created = give_ownership();
    println!("Received: {created}");

    let label = String::from("ruler");
    let label = add_price_tag(label);
    println!("After the function: {label}");
}

fn take_ownership(text: String) {
    println!("take_ownership got: {text}");
} // text is dropped here

fn make_copy(number: i32) {
    println!("make_copy got: {number}");
}

fn give_ownership() -> String {
    String::from("stapler")
}

fn add_price_tag(mut text: String) -> String {
    text.push_str(" (Rp5000)");
    text
}
```

Run it:

```bash
cargo run -q
```

```text
Inside the block: Hello
The block has ended.
Learning Rust! (14 bytes)
a = 10, b = 10
moved = notebook
first = pencil, second = pencil
take_ownership got: eraser
make_copy got: 3
count is still usable: 3
Received: stapler
After the function: ruler (Rp5000)
```

The output looks unremarkable, and that is the point: ownership is checked entirely at compile time and adds no visible work at runtime. The interesting part is what the compiler *refused* to compile. Try each of these experiments, read the error, and then undo the change:

- Add `println!("{item}");` right after `take_ownership(item);`.
- Change `let second = first.clone();` to `let second = first;` while keeping the `println!` that prints both.
- Change `let a = 10;` to `let a = String::from("10");` and see which line fails.

Each experiment produces `error[E0382]: borrow of moved value`, pointing at the exact move. Learning to see moves in your head is the core skill of this module.

---

## 7. Fix the Errors in Your Code

Ownership errors are the ones Rust beginners meet most. The good news is that the compiler explains them precisely and usually suggests a fix.

**Error 1: Using a value after it was moved to another variable.**

```rust
// Wrong
fn main() {
    let original = String::from("notebook");
    let moved = original;
    println!("original = {original}");
    println!("moved = {moved}");
}

// Correct
fn main() {
    let original = String::from("notebook");
    let moved = original.clone();
    println!("original = {original}");
    println!("moved = {moved}");
}
```

The wrong version produces ``error[E0382]: borrow of moved value: `original` ``. The compiler's `help` section suggests ``consider cloning the value if the performance cost is acceptable``. Cloning is the right fix when you genuinely need two independent copies. Often, though, the better fix is to not move at all: use `original` directly and drop the second variable, or borrow it as you will learn in Lesson 10.

**Error 2: Using a value after moving it into a function.**

```rust
// Wrong
fn main() {
    let item = String::from("eraser");
    take_ownership(item);
    println!("Still have: {item}");
}

// Correct
fn main() {
    let item = String::from("eraser");
    take_ownership(item.clone());
    println!("Still have: {item}");
}
```

The wrong version produces the same ``error[E0382]: borrow of moved value: `item` ``, but with an extra note: ``consider changing this parameter type in function `take_ownership` to borrow instead if owning the value isn't necessary``. That note is a preview of Lesson 10. Cloning works, but if the function only needs to read the text, changing its parameter to a reference is the better design.

**Error 3: Using a variable outside its scope.**

```rust
// Wrong
fn main() {
    {
        let greeting = String::from("Hello");
        println!("{greeting}");
    }
    println!("{greeting}");
}

// Correct
fn main() {
    let greeting = String::from("Hello");
    {
        println!("{greeting}");
    }
    println!("{greeting}");
}
```

The wrong version produces ``error[E0425]: cannot find value `greeting` in this scope``, and the `help` says the binding ``is available in a different scope in the same function``. The value was dropped at the end of the inner block. Declare the variable in the outer scope if it is needed there; inner blocks can still use variables from outer blocks.

**Error 4: Trying to modify a text literal.**

```rust
// Wrong
fn main() {
    let mut message = "Learning";
    message.push_str(" Rust");
    println!("{message}");
}

// Correct
fn main() {
    let mut message = String::from("Learning");
    message.push_str(" Rust");
    println!("{message}");
}
```

The wrong version produces ``error[E0599]: no method named `push_str` found for reference `&str` in the current scope``. A literal is a `&str`, fixed text that cannot grow, even when the variable is `mut`. (`mut` would only let you point the variable at a *different* literal.) Create a `String` with `String::from` when you need text that changes.

---

## 8. Exercises

**Exercise 1:** Create a project called `copy_or_move`. The following program does not compile. Predict which line fails and why, then fix it so all three lines print both values.

```rust
fn main() {
    let score = 90;
    let backup_score = score;
    println!("{score} {backup_score}");

    let city = String::from("Bandung");
    let backup_city = city;
    println!("{city} {backup_city}");

    let passed = true;
    let copy_of_passed = passed;
    println!("{passed} {copy_of_passed}");
}
```

**Exercise 2:** Create a project called `shout`. Write a function `shout(text: String) -> String` that returns the text in uppercase with an exclamation mark at the end. (`to_uppercase()` returns an uppercase copy of a string.) Call it from `main` with `"hello"` and print the result.

**Exercise 3:** Create a project called `sentence`. Starting from an empty `String`, use a `for` loop over the array `["Rust", "is", "fun"]` to build the sentence `Rust is fun`, with a single space between words. Then write a function `measure(text: String) -> (String, usize)` that returns the string together with its length, so that `main` can still print the sentence after calling it.

---

## 9. Solutions

**Solution for Exercise 1:**

The second `println!` fails. `score` and `passed` are `Copy` types (`i32` and `bool`), so assigning them copies the value and both variables stay valid. `city` is a `String`, so `let backup_city = city;` moves it, and `city` cannot be used afterward. The fix is to clone:

```rust
fn main() {
    let score = 90;
    let backup_score = score;
    println!("{score} {backup_score}");

    let city = String::from("Bandung");
    let backup_city = city.clone();
    println!("{city} {backup_city}");

    let passed = true;
    let copy_of_passed = passed;
    println!("{passed} {copy_of_passed}");
}
```

`city.clone()` creates a second `String` with its own heap memory, so both variables own valid data. The program prints:

```text
90 90
Bandung Bandung
true true
```

**Solution for Exercise 2:**

```rust
fn main() {
    let word = String::from("hello");
    let loud = shout(word);
    println!("{loud}");
}

fn shout(text: String) -> String {
    let mut result = text.to_uppercase();
    result.push('!');
    result
}
```

`shout` takes ownership of `word`. `text.to_uppercase()` creates a new `String` with the uppercase text, which is stored in a mutable variable so that `push('!')` can add the exclamation mark. The function returns `result`, moving it to `loud` in `main`. The original `text` is dropped when the function ends, and `word` cannot be used in `main` after the call. The program prints:

```text
HELLO!
```

**Solution for Exercise 3:**

```rust
fn main() {
    let words = ["Rust", "is", "fun"];
    let mut sentence = String::new();
    for word in words {
        if !sentence.is_empty() {
            sentence.push(' ');
        }
        sentence.push_str(word);
    }

    let (sentence, length) = measure(sentence);
    println!("'{sentence}' has {length} bytes.");
}

fn measure(text: String) -> (String, usize) {
    let length = text.len();
    (text, length)
}
```

The array holds `&str` literals, which `push_str` accepts. `sentence.is_empty()` is true only before the first word, so the `if` adds a space before every word except the first. `measure` takes ownership of the string, calculates its length, and returns both in a tuple, giving ownership back. `main` destructures the tuple and shadows `sentence` with the returned string. The program prints:

```text
'Rust is fun' has 11 bytes.
```

Returning the string just so the caller can keep using it is awkward. That awkwardness is exactly the problem borrowing solves in the next lesson.

---

## Next Up - Lesson 10

In this lesson you learned how Rust manages memory without a garbage collector. Values live on the stack or the heap, every value has exactly one owner, and the value is dropped when its owner goes out of scope. Assigning or passing a `String` moves it, `clone` makes an explicit deep copy, `Copy` types such as integers are copied automatically, and return values move ownership back to the caller.

In Lesson 10, you will learn references and borrowing: how to let a function read or change a value without taking ownership, the rules that keep borrowing safe, and slices, which let you refer to part of a string or array. That will finally explain the `&` in `&str` and the `&mut` in `read_line(&mut input)`.
