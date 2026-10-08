## 1. Before You Begin

Lesson 9 ended with an awkward pattern. To let a function read a `String` and still use it afterward, you had to move the string into the function and return it again, sometimes bundled in a tuple with the real result. Imagine doing that for every function that only needs to *look* at a value. There has to be a better way, and there is: references.

A reference lets you use a value without owning it. Lending a book to a friend is a good comparison: your friend can read it, but it is still yours, and they must give it back. In Rust, creating a reference is called borrowing. In this lesson you will borrow values for reading and for changing, learn the two rules that keep borrowing safe, and use slices to borrow just part of a string or an array. By the end, the `&` in `&str` and the `&mut` in `read_line(&mut input)` will make complete sense.

### What You'll Build

A `borrowing` program that measures a book title without taking ownership of it, edits a note through a mutable reference, cuts words out of a sentence with string slices, finds the first word of any text, and sums all or part of an array with a single function that works for arrays of any length.

### What You'll Learn

- ✅ How to create a reference with `&` and pass it to a function
- ✅ How to change a borrowed value through a mutable reference, `&mut`
- ✅ The two borrowing rules and why they prevent bugs
- ✅ Why Rust never allows a reference to a value that no longer exists
- ✅ How to borrow part of a string with a string slice (`&str`)
- ✅ Why `&str` is a better parameter type than `&String`
- ✅ How to borrow part of an array with an array slice (`&[i32]`)

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- A solid understanding of ownership, moves, and `String` (Lesson 9)

---

## 2. Borrow a Value with a Reference

A reference is written with an ampersand: `&value`. It points to a value owned by someone else. The owner keeps ownership, so the value is not moved and is not dropped when the reference goes away.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new borrowing
cd borrowing
```

These commands create the `borrowing` project. As before, you will add code to `main` section by section and put helper functions below it.

### Step 2: Pass a Reference to a Function

Replace the contents of `src/main.rs` with:

```rust
fn main() {
    // Immutable references: read without taking ownership.
    let title = String::from("The Rust Programming Language");
    let length = count_bytes(&title);
    println!("'{title}' has {length} bytes.");
```

Add this function below `main` (you will add `main`'s closing brace later in the lesson):

```rust
fn count_bytes(text: &String) -> usize {
    text.len()
}
```

The parameter type `&String` means "a reference to a `String`." When `main` calls `count_bytes(&title)`, the `&title` creates a reference to `title` and passes it in. Ownership stays with `title` in `main`. Inside the function, `text.len()` works on the reference just as it would on the `String` itself; Rust follows the reference automatically when you call a method.

When `count_bytes` ends, `text` goes out of scope, but because it is only a reference, nothing is dropped. That is why `main` can still print `title` on the next line. Compare this with `measure` from Lesson 9's exercise, which had to return the string in a tuple. Borrowing makes that unnecessary.

### Step 3: Have Several Readers at Once

Add these lines to `main`:

```rust
    let r1 = &title;
    let r2 = &title;
    println!("Two readers: {r1} / {r2}");
```

References can also be stored in variables. `r1` and `r2` are two references to the same `String`. Having many immutable references at the same time is always allowed, because none of them can change the value; any number of people can safely read the same book at the same time. `println!` follows each reference and prints the text it points to.

---

## 3. Change a Borrowed Value with &mut

A plain reference only allows reading. To let a function change a value it does not own, you pass a mutable reference, written `&mut`. You have done this since Lesson 8: `read_line(&mut input)` borrows your `String` mutably so it can append the text the user typed.

### Step 1: Write a Function That Modifies Its Argument

Add these lines to `main`:

```rust
    // Mutable references: change without taking ownership.
    let mut note = String::from("Buy milk");
    add_suffix(&mut note);
    add_suffix(&mut note);
    println!("Note: {note}");
```

And add the function below the others:

```rust
fn add_suffix(text: &mut String) {
    text.push_str(" (urgent)");
}
```

Three things must line up for mutable borrowing. The variable must be declared `mut`, because its value will change. The call must write `&mut note` to create a mutable reference. And the parameter type must be `&mut String`. Inside the function, `text.push_str(...)` changes the `String` that `note` owns. When the function returns, the borrow ends, and `main` can borrow it again for the second call. After two calls, the note has two suffixes.

### Step 2: Understand the Borrowing Rules

Rust enforces two rules for references, checked at compile time by a part of the compiler called the borrow checker:

1. At any given time, you can have **either** one mutable reference **or** any number of immutable references to a value, but not both.
2. References must always be valid: a reference can never outlive the value it points to.

Rule 1 is like a document that many people can read at once, but which only one person can edit, and only when nobody is reading it. Without this rule, one part of a program could change data while another part is in the middle of reading it, a bug known as a data race. Rust makes this impossible.

A borrow lasts from where the reference is created to the last place it is used, not necessarily to the end of the block. In Step 1, each `&mut note` borrow ends as soon as `add_suffix` returns, so the next borrow is allowed. Section 7 shows what the compiler says when the rule is broken.

Rule 2 prevents dangling references: references that point to memory that has already been freed. For example, a function cannot create a `String` and return a reference to it, because the `String` is dropped when the function ends and the reference would point to nothing. The compiler rejects such code, and the fix is to return the owned `String` itself. This is exactly why the `read_line` helper in Lesson 8 returned `input.trim().to_string()`: `trim()` returns a reference into `input`, and `input` is dropped at the end of the function.

---

## 4. Borrow Part of a String with Slices

Often you need only part of a value: the first word of a sentence, the file name at the end of a path, the first three scores of a list. A slice is a reference to a contiguous part of a string or array. It borrows that part without copying it.

### Step 1: Take String Slices

Add these lines to `main`:

```rust
    // String slices: borrow part of a string.
    let sentence = String::from("hello wonderful world");
    let hello = &sentence[0..5];
    let world = &sentence[16..];
    println!("Slices: [{hello}] [{world}]");
```

`&sentence[0..5]` is a string slice that refers to the bytes from position 0 up to, but not including, position 5: the text `hello`. The range syntax is the same as in `for` loops from Lesson 6. You can leave out either end: `[16..]` means from position 16 to the end, which is `world`, and `[..5]` would mean from the start up to position 5.

The type of a string slice is `&str`. Now you know what that type has meant all along: a reference to some text stored elsewhere. A text literal such as `"hello"` is also a `&str`; it is a slice pointing to text stored inside the compiled program. That is why literals cannot be modified.

The positions are byte positions. For plain English letters each character is one byte, so counting characters works. Characters outside the basic Latin alphabet, such as `é` or emoji, use more than one byte, and slicing in the middle of one makes the program panic. In this course, you will find slice positions by searching the text, as in the next step, rather than by counting by hand.

### Step 2: Write a Function That Returns a Slice

Add these lines to `main`:

```rust
    println!("First word: {}", first_word(&sentence));
    println!("First word of a literal: {}", first_word("borrow checker"));
```

And add the function:

```rust
fn first_word(text: &str) -> &str {
    for (index, character) in text.char_indices() {
        if character == ' ' {
            return &text[..index];
        }
    }
    text
}
```

`text.char_indices()` goes through the text one character at a time and gives you each character together with its byte position, as a tuple. The `for` loop destructures each tuple into `index` and `character`. When it finds a space, it returns the slice from the start up to that position, which is the first word. If the loop finishes without finding a space, the whole text is one word, so the function returns `text` itself.

The return type `&str` is a slice of the input, so it borrows from the same value as the parameter. The compiler connects the two automatically: the returned slice is valid as long as the text passed in is valid. If `main` tried to clear `sentence` while still holding the first word, the borrow checker would stop it (see Section 7).

### Step 3: Prefer &str for Text Parameters

Notice that `first_word` takes `&str`, not `&String`, and the second call passes a literal. A function that takes `&str` accepts both: a literal is already a `&str`, and `&sentence` (a `&String`) is converted to a `&str` automatically. A function that takes `&String` would accept only the second.

So for parameters that only read text, `&str` is the better, more flexible choice. You could change `count_bytes` from Section 2 to take `&str` without changing anything else in the program. You will use `&str` parameters for the rest of the course.

---

## 5. Borrow Part of an Array

Slices work for arrays too. This solves a limitation from Lesson 7, where `average` and `min_max` could only accept an array of exactly five elements because the parameter type was `[i32; 5]`.

### Step 1: Write a Function That Takes Any Number of Elements

Add the last lines to `main` and close it:

```rust
    // Array slices: borrow part of an array.
    let scores = [80, 92, 67, 75, 88, 95];
    println!("Sum of all: {}", sum(&scores));
    println!("Sum of first three: {}", sum(&scores[..3]));
    println!("Sum of last two: {}", sum(&scores[4..]));
}
```

Add the function:

```rust
fn sum(numbers: &[i32]) -> i32 {
    let mut total = 0;
    for number in numbers {
        total += *number;
    }
    total
}
```

The parameter type `&[i32]` is an array slice: a reference to a sequence of `i32` values of any length. `&scores` borrows the whole array, `&scores[..3]` borrows the first three elements, and `&scores[4..]` borrows everything from index 4 to the end. The same function handles all three, because a slice knows its own length.

Looping over a slice gives you references to its elements, so `number` has the type `&i32`. The `*` in `*number` is the dereference operator: it follows the reference to the value it points to, giving a plain `i32` that can be added to `total`. You will see `*` whenever you need the value behind a reference. For method calls and printing, Rust dereferences automatically, which is why `text.len()` worked without it.

---

## 6. Run and Test

Your complete `src/main.rs` should look like this:

```rust
fn main() {
    // Immutable references: read without taking ownership.
    let title = String::from("The Rust Programming Language");
    let length = count_bytes(&title);
    println!("'{title}' has {length} bytes.");

    let r1 = &title;
    let r2 = &title;
    println!("Two readers: {r1} / {r2}");

    // Mutable references: change without taking ownership.
    let mut note = String::from("Buy milk");
    add_suffix(&mut note);
    add_suffix(&mut note);
    println!("Note: {note}");

    // String slices: borrow part of a string.
    let sentence = String::from("hello wonderful world");
    let hello = &sentence[0..5];
    let world = &sentence[16..];
    println!("Slices: [{hello}] [{world}]");
    println!("First word: {}", first_word(&sentence));
    println!("First word of a literal: {}", first_word("borrow checker"));

    // Array slices: borrow part of an array.
    let scores = [80, 92, 67, 75, 88, 95];
    println!("Sum of all: {}", sum(&scores));
    println!("Sum of first three: {}", sum(&scores[..3]));
    println!("Sum of last two: {}", sum(&scores[4..]));
}

fn count_bytes(text: &String) -> usize {
    text.len()
}

fn add_suffix(text: &mut String) {
    text.push_str(" (urgent)");
}

fn first_word(text: &str) -> &str {
    for (index, character) in text.char_indices() {
        if character == ' ' {
            return &text[..index];
        }
    }
    text
}

fn sum(numbers: &[i32]) -> i32 {
    let mut total = 0;
    for number in numbers {
        total += *number;
    }
    total
}
```

Run it:

```bash
cargo run -q
```

```text
'The Rust Programming Language' has 29 bytes.
Two readers: The Rust Programming Language / The Rust Programming Language
Note: Buy milk (urgent) (urgent)
Slices: [hello] [world]
First word: hello
First word of a literal: borrow
Sum of all: 497
Sum of first three: 239
Sum of last two: 183
```

Every value was used after being borrowed: `title` was printed after `count_bytes`, `note` after two mutable borrows, and `sentence` and `scores` after several slices. No `clone` and no "give it back" tuples were needed. The sums confirm the slices: 80 + 92 + 67 is 239, and 88 + 95 is 183.

As an experiment, change `count_bytes` to take `text: &str` and run again. The output is identical, which shows that `&String` arguments convert to `&str` automatically.

---

## 7. Fix the Errors in Your Code

Borrowing errors are where the borrow checker earns its reputation. Each message names the borrows involved and shows where they start and where they are used.

**Error 1: Changing a value through an immutable reference.**

```rust
// Wrong
fn main() {
    let mut note = String::from("Buy milk");
    add_suffix(&note);
    println!("{note}");
}

fn add_suffix(text: &String) {
    text.push_str(" (urgent)");
}

// Correct
fn main() {
    let mut note = String::from("Buy milk");
    add_suffix(&mut note);
    println!("{note}");
}

fn add_suffix(text: &mut String) {
    text.push_str(" (urgent)");
}
```

The wrong version produces ``error[E0596]: cannot borrow `*text` as mutable, as it is behind a `&` reference``, and the `help` suggests changing the parameter to `&mut String`. Remember that all three places must agree: `let mut`, `&mut` at the call, and `&mut` in the parameter type. The compiler also warns that `note` does not need to be mutable, a hint that nothing in `main` actually changes it.

**Error 2: Two mutable references at the same time.**

```rust
// Wrong
fn main() {
    let mut note = String::from("Buy milk");
    let first = &mut note;
    let second = &mut note;
    first.push_str("!");
    second.push_str("?");
    println!("{note}");
}

// Correct
fn main() {
    let mut note = String::from("Buy milk");
    let first = &mut note;
    first.push_str("!");
    let second = &mut note;
    second.push_str("?");
    println!("{note}");
}
```

The wrong version produces ``error[E0499]: cannot borrow `note` as mutable more than once at a time``. The compiler marks the ``first mutable borrow occurs here``, the ``second mutable borrow occurs here``, and the line where the ``first borrow later used here``. In the correct version, `first` is no longer used when `second` is created, so the two borrows do not overlap.

**Error 3: Changing a value while it is borrowed for reading.**

```rust
// Wrong
fn main() {
    let mut sentence = String::from("hello world");
    let word = first_word(&sentence);
    sentence.clear();
    println!("First word: {word}");
}

// Correct
fn main() {
    let mut sentence = String::from("hello world");
    let word = first_word(&sentence);
    println!("First word: {word}");
    sentence.clear();
}
```

(Both versions use the `first_word` function from Section 4.) The wrong version produces ``error[E0502]: cannot borrow `sentence` as mutable because it is also borrowed as immutable``. `word` is a slice of `sentence`, and `clear()` would empty the string while `word` still points into it. In many languages this compiles and prints garbage or crashes. Rust refuses. Finish using the slice before changing the original.

**Error 4: Returning a reference to a value created inside the function.**

```rust
// Wrong
fn make_text() -> &String {
    let text = String::from("temporary");
    &text
}

// Correct
fn make_text() -> String {
    String::from("temporary")
}
```

The wrong version produces `error[E0106]: missing lifetime specifier`, with the explanation that ``this function's return type contains a borrowed value, but there is no value for it to be borrowed from``. `text` is dropped when the function ends, so a reference to it would dangle. Ignore the first suggestion about `'static` (an advanced topic) and follow the second: ``instead, you are more likely to want to return an owned value``. Return the `String` itself, moving ownership to the caller.

---

## 8. Exercises

**Exercise 1:** Create a project called `measure`. Rewrite the `measure` function from Lesson 9's Exercise 3 so it borrows the text instead of taking ownership. It should take a `&str` and return only the length (`usize`). Use it on `"Rust is fun"` and print the sentence and its length afterward.

**Exercise 2:** Create a project called `letter`. Write a function `sign(letter: &mut String, name: &str)` that appends a new line, `Regards,`, another new line, and the name to the end of a letter. In `main`, create a letter with two lines of text, sign it with your name, and print it. (`"\n"` inside a string is a newline character.)

**Exercise 3:** Create a project called `slices`. Write `largest(numbers: &[i32]) -> i32`, which returns the largest number in a slice, and `last_part(text: &str) -> &str`, which returns everything after the last `/` in a path (or the whole text if there is no `/`). Test `largest` on a week of temperatures and on only the first two days, and test `last_part` on `"home/dina/notes/rust.txt"` and `"photo.png"`.

---

## 9. Solutions

**Solution for Exercise 1:**

```rust
fn main() {
    let sentence = String::from("Rust is fun");
    let length = measure(&sentence);
    println!("'{sentence}' has {length} bytes.");
}

fn measure(text: &str) -> usize {
    text.len()
}
```

The function borrows the text, so it no longer needs to return it. `main` keeps ownership of `sentence` and can print it after the call. The function is shorter, the call is simpler, and nothing is moved or cloned. The program prints:

```text
'Rust is fun' has 11 bytes.
```

**Solution for Exercise 2:**

```rust
fn main() {
    let mut letter = String::from("Dear team,\nThe meeting moves to Friday.");
    sign(&mut letter, "Dina");
    println!("{letter}");
}

fn sign(letter: &mut String, name: &str) {
    letter.push_str("\nRegards,\n");
    letter.push_str(name);
}
```

`sign` takes two different kinds of reference: a mutable reference to the letter, because it changes it, and an immutable `&str` for the name, because it only reads it. The `\n` sequences become line breaks when printed. The program prints:

```text
Dear team,
The meeting moves to Friday.
Regards,
Dina
```

**Solution for Exercise 3:**

```rust
fn main() {
    let temperatures = [31, 29, 34, 30, 28, 33, 32];
    println!("Hottest day of the week: {}", largest(&temperatures));
    println!("Hottest of the first two days: {}", largest(&temperatures[..2]));

    let path = String::from("home/dina/notes/rust.txt");
    println!("Last part: {}", last_part(&path));
    println!("Last part of a literal: {}", last_part("photo.png"));
}

fn largest(numbers: &[i32]) -> i32 {
    let mut result = numbers[0];
    for number in numbers {
        if *number > result {
            result = *number;
        }
    }
    result
}

fn last_part(text: &str) -> &str {
    let mut start = 0;
    for (index, character) in text.char_indices() {
        if character == '/' {
            start = index + 1;
        }
    }
    &text[start..]
}
```

`largest` starts with the first element and replaces it whenever it finds a bigger one, dereferencing each `&i32` with `*`. (It assumes the slice is not empty; `numbers[0]` would panic on an empty slice. Lesson 12 shows how to handle "no value" properly.) `last_part` remembers the position just after the most recent `/`. If there is no slash, `start` stays 0 and the whole text is returned. The program prints:

```text
Hottest day of the week: 34
Hottest of the first two days: 31
Last part: rust.txt
Last part of a literal: photo.png
```

---

## Next Up - Lesson 11

In this lesson you learned to use values without owning them. You passed immutable references with `&`, changed values through mutable references with `&mut`, learned the two borrowing rules that prevent data races and dangling references, and borrowed parts of strings and arrays with slices. You also learned why `&str` is the best type for text parameters and how `*` dereferences a reference.

With ownership and borrowing in place, you are ready to model real data. In Lesson 11, you will start Module 6 by creating your own types with structs, grouping related values such as a book's title, author, and page count into one named type, and adding methods that work on them.
