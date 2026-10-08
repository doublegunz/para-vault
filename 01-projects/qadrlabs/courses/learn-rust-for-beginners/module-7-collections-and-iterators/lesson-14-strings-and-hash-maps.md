## 1. Before You Begin

Text is everywhere in real programs: names, messages, file contents, user input, lines of a CSV export. You have been using `String` and `&str` since Lesson 8 and learned how they relate to ownership in Module 5, but only a handful of their methods. This lesson fills in the toolbox: building text, searching it, changing it, splitting it into pieces, and understanding why Rust is careful about characters that take more than one byte.

The second half of the lesson introduces the hash map, a collection that stores values under keys. A vector answers "what is at position 3?", while a hash map answers "what is the price of `tea`?" or "how many times does the word `the` appear?". Hash maps and strings go together naturally, and by the end of the lesson you will use both to count the words in a sentence.

### What You'll Build

A `text_and_maps` program that builds and cleans up text, compares the byte length and character count of a word with an accented letter, splits a comma separated line into fields, manages a menu of prices in a hash map (adding, looking up, updating, and removing items), and counts how often each word appears in a sentence.

### What You'll Learn

- ✅ How to build strings with `format!`, `push_str`, and `+`
- ✅ Common text methods: `trim`, `to_lowercase`, `contains`, `starts_with`, and `replace`
- ✅ Why `len()` counts bytes, how `chars()` counts characters, and why strings cannot be indexed
- ✅ How to split text with `split` and `split_whitespace`
- ✅ How to create a `HashMap` and use `insert`, `get`, `contains_key`, `get_mut`, and `remove`
- ✅ How to loop over a hash map in a predictable order
- ✅ How to count things with the `entry` API

### What You'll Need

- A working Rust installation and the `~/rust-basics` folder
- Comfort with `String`, `&str`, and borrowing (Lessons 9 and 10)
- Comfort with vectors, iterators, closures, and `Option` (Lessons 12 and 13)

---

## 2. Build and Transform Text

Rust's two text types split the work between them. `String` owns its text and can change it. `&str` is a borrowed view of text owned elsewhere, such as a literal or part of a `String`. Most methods that only read text are available on both, because a `String` automatically provides all the `&str` methods.

### Step 1: Create the Project

```bash
cd ~/rust-basics
cargo new text_and_maps
cd text_and_maps
```

These commands create the `text_and_maps` project. The hash map type you will use later needs a `use` statement at the top of the file, which you will add in Section 4.

### Step 2: Combine Pieces of Text

Replace the contents of `src/main.rs` with:

```rust
fn main() {
    // Building strings.
    let first = String::from("Rust");
    let second = "is fun";
    let joined = format!("{first} {second}!");
    let mut built = String::new();
    built.push_str(&first);
    built.push_str(" & friends");
    println!("{joined} / {built}");
```

There are several ways to combine text, and `format!` is usually the clearest. It works like `println!`, but returns the result as a new `String` instead of printing it, and it accepts any mix of `String` and `&str` values. It only borrows its inputs, so `first` is still usable afterward.

`push_str` appends text to an existing `String`, which must be mutable. It takes a `&str`, so passing a `String` requires a reference: `&first`. Rust converts the `&String` to `&str` automatically, as you saw in Lesson 10.

Rust also supports `+` for joining text, as in `first + " is fun"`, but it has a twist: the left side must be an owned `String`, and it is moved into the result. That makes `+` awkward for beginners, so this course prefers `format!`. Section 6 shows the error you get when both sides are `&str`.

### Step 3: Inspect and Transform Text

Add these lines:

```rust
    // Inspecting and transforming text.
    let title = "  Learning Rust, One Lesson at a Time  ";
    let clean = title.trim();
    println!("Trimmed: [{clean}]");
    println!("Lowercase: {}", clean.to_lowercase());
    println!("Contains 'Rust'? {}", clean.contains("Rust"));
    println!("Starts with 'Learn'? {}", clean.starts_with("Learn"));
    println!("Replaced: {}", clean.replace("Rust", "Programming"));
```

`trim` removes whitespace from both ends and returns a `&str` slice of the original text, without copying anything. `to_lowercase` (and its partner `to_uppercase`) creates a new `String`, because changing letters produces different text. `contains` and `starts_with` answer yes or no questions and return a `bool`; `ends_with` also exists. `replace` returns a new `String` in which every occurrence of the first argument is replaced by the second.

None of these methods change `title` or `clean`. Methods that produce modified text return a new `String`, and methods that answer questions return a `bool` or a number. This makes text methods easy to chain and safe to call on borrowed text.

### Step 4: Bytes Versus Characters

Add these lines:

```rust
    // Bytes versus characters.
    let city = "Café Bogor";
    println!("'{city}' has {} bytes and {} characters", city.len(), city.chars().count());
    let initials: String = city.split_whitespace().map(|w| w.chars().next().unwrap()).collect();
    println!("Initials: {initials}");
```

Rust stores text as UTF-8, an encoding in which basic English letters take one byte, but accented letters like `é` take two bytes, and many other characters take three or four. `len()` returns the number of bytes, which is 11 here, while `chars()` produces an iterator over the actual characters, and `count()` counts them: 10. When you need "how many letters does this have," use `chars().count()`.

This is also why Rust does not let you write `city[0]` to get the first character: a byte position does not always line up with a character. To work with characters, use `chars()`. The second line splits the city name into words with `split_whitespace` (Step 5 explains splitting), takes the first character of each word with `chars().next()`, and collects them into a new `String`. `next()` returns an `Option<char>`, because a word could be empty; `split_whitespace` never produces empty words, so `unwrap()` is safe here.

### Step 5: Split Text into Parts

Add these lines:

```rust
    // Splitting text.
    let csv_line = "Dina,19,Bandung";
    let parts: Vec<&str> = csv_line.split(',').collect();
    println!("Name: {}, age: {}, city: {}", parts[0], parts[1], parts[2]);
```

`split(',')` produces an iterator over the pieces of text between commas, and `collect` gathers them into a `Vec<&str>`. Each piece is a slice of the original line, so no text is copied. CSV (comma separated values) files store data exactly like this, one record per line. `split_whitespace`, used in the previous step, splits on any run of spaces, tabs, or newlines, which is what you usually want for words. There is also `lines()`, which splits text into lines; you will use it in Lesson 17 when reading files.

---

## 3. Store Values by Key with HashMap

A hash map, `HashMap<K, V>`, stores pairs of a key of type `K` and a value of type `V`. Each key appears at most once, and looking up a value by its key is fast no matter how many entries there are. Think of a dictionary (word to definition), a phone book (name to number), or a menu (item to price).

### Step 1: Import HashMap and Create a Map

Add this line at the very top of `src/main.rs`, above `fn main()`:

```rust
use std::collections::HashMap;
```

Unlike `Vec` and `String`, `HashMap` is not available automatically. It lives in the `std::collections` module of the standard library, so you bring it into scope with `use`, as you did with `std::io` in Lesson 8.

Now add these lines at the end of `main`:

```rust
    // A hash map of prices.
    let mut prices: HashMap<String, u32> = HashMap::new();
    prices.insert(String::from("coffee"), 18_000);
    prices.insert(String::from("tea"), 12_000);
    prices.insert(String::from("cake"), 25_000);
```

`HashMap::new()` creates an empty map, and the annotation `HashMap<String, u32>` says keys are `String`s and values are `u32`s. `insert` adds a key and value pair. The map takes ownership of both, just as a vector takes ownership of what you push into it. The map must be `mut` because inserting changes it.

### Step 2: Look Up and Check Keys

Add these lines:

```rust
    match prices.get("tea") {
        Some(price) => println!("Tea: Rp{price}"),
        None => println!("Tea is not on the menu"),
    }
    println!("Has pizza? {}", prices.contains_key("pizza"));
```

`get` looks up a key and returns an `Option<&V>`: `Some` with a reference to the value if the key exists, or `None` if it does not. This is the same pattern as `Vec::get` from Lesson 13, and you handle it with `match` or `if let`. Even though the keys are `String`s, you can look them up with a `&str` like `"tea"`; the map compares the text, not the type.

`contains_key` returns a `bool` when you only need to know whether a key exists.

### Step 3: Update and Remove Entries

Add these lines:

```rust
    prices.insert(String::from("tea"), 13_000);
    if let Some(price) = prices.get_mut("coffee") {
        *price += 2_000;
    }
    prices.remove("cake");
```

Calling `insert` with a key that already exists replaces the old value: tea now costs 13,000. `get_mut` returns an `Option<&mut V>`, a mutable reference to the value, so you can change it in place. As with mutable references in vectors, you dereference it with `*` to modify it: coffee goes up by 2,000. `remove` deletes a key and its value from the map.

### Step 4: Loop over the Map in Order

Add these lines:

```rust
    let mut menu: Vec<(&String, &u32)> = prices.iter().collect();
    menu.sort();
    for (item, price) in menu {
        println!("{item:<8} Rp{price}");
    }
```

`prices.iter()` produces every key and value pair as a tuple of references. There is one important detail: a hash map does not keep its entries in any particular order, and the order can even change between runs of the same program. If you need a predictable order, collect the pairs into a vector and sort it. Tuples sort by their first element, so `menu.sort()` arranges the items alphabetically. Then the loop destructures each tuple into `item` and `price`.

---

## 4. Count Words with the entry API

Counting is one of the most common uses of a hash map: how many times does each word appear, how many orders did each customer place, how many students got each grade. The pattern is always the same: if the key is new, start at zero; then add one. The `entry` API expresses that in a single line.

### Step 1: Count Each Word

Add the final lines and close `main`:

```rust
    // Counting words with the entry API.
    let text = "the cat sat on the mat and the dog sat too";
    let mut counts: HashMap<&str, u32> = HashMap::new();
    for word in text.split_whitespace() {
        let count = counts.entry(word).or_insert(0);
        *count += 1;
    }
    let mut sorted: Vec<(&&str, &u32)> = counts.iter().collect();
    sorted.sort();
    for (word, count) in sorted {
        println!("{word}: {count}");
    }
    println!("Distinct words: {}", counts.len());
}
```

This map uses `&str` keys: each word is a slice of `text`, so no text is copied. `counts.entry(word)` looks up the key and returns an entry, a handle for that spot in the map whether or not the key exists yet. `.or_insert(0)` inserts 0 if the key is new, and in either case returns a mutable reference to the value. `*count += 1` then increases it. The first time `"the"` appears, it is inserted with 0 and increased to 1; the next times, the existing count is increased.

Sorting works as in Section 3. The tuple contains references to the keys, and since the keys are already `&str`, the key references are `&&str`; printing follows all the references automatically. `counts.len()` returns the number of entries, which is the number of distinct words.

---

## 5. Run and Test

Your complete `src/main.rs` should look like this:

```rust
use std::collections::HashMap;

fn main() {
    // Building strings.
    let first = String::from("Rust");
    let second = "is fun";
    let joined = format!("{first} {second}!");
    let mut built = String::new();
    built.push_str(&first);
    built.push_str(" & friends");
    println!("{joined} / {built}");

    // Inspecting and transforming text.
    let title = "  Learning Rust, One Lesson at a Time  ";
    let clean = title.trim();
    println!("Trimmed: [{clean}]");
    println!("Lowercase: {}", clean.to_lowercase());
    println!("Contains 'Rust'? {}", clean.contains("Rust"));
    println!("Starts with 'Learn'? {}", clean.starts_with("Learn"));
    println!("Replaced: {}", clean.replace("Rust", "Programming"));

    // Bytes versus characters.
    let city = "Café Bogor";
    println!("'{city}' has {} bytes and {} characters", city.len(), city.chars().count());
    let initials: String = city.split_whitespace().map(|w| w.chars().next().unwrap()).collect();
    println!("Initials: {initials}");

    // Splitting text.
    let csv_line = "Dina,19,Bandung";
    let parts: Vec<&str> = csv_line.split(',').collect();
    println!("Name: {}, age: {}, city: {}", parts[0], parts[1], parts[2]);

    // A hash map of prices.
    let mut prices: HashMap<String, u32> = HashMap::new();
    prices.insert(String::from("coffee"), 18_000);
    prices.insert(String::from("tea"), 12_000);
    prices.insert(String::from("cake"), 25_000);

    match prices.get("tea") {
        Some(price) => println!("Tea: Rp{price}"),
        None => println!("Tea is not on the menu"),
    }
    println!("Has pizza? {}", prices.contains_key("pizza"));

    prices.insert(String::from("tea"), 13_000);
    if let Some(price) = prices.get_mut("coffee") {
        *price += 2_000;
    }
    prices.remove("cake");

    let mut menu: Vec<(&String, &u32)> = prices.iter().collect();
    menu.sort();
    for (item, price) in menu {
        println!("{item:<8} Rp{price}");
    }

    // Counting words with the entry API.
    let text = "the cat sat on the mat and the dog sat too";
    let mut counts: HashMap<&str, u32> = HashMap::new();
    for word in text.split_whitespace() {
        let count = counts.entry(word).or_insert(0);
        *count += 1;
    }
    let mut sorted: Vec<(&&str, &u32)> = counts.iter().collect();
    sorted.sort();
    for (word, count) in sorted {
        println!("{word}: {count}");
    }
    println!("Distinct words: {}", counts.len());
}
```

Run it:

```bash
cargo run -q
```

```text
Rust is fun! / Rust & friends
Trimmed: [Learning Rust, One Lesson at a Time]
Lowercase: learning rust, one lesson at a time
Contains 'Rust'? true
Starts with 'Learn'? true
Replaced: Learning Programming, One Lesson at a Time
'Café Bogor' has 11 bytes and 10 characters
Initials: CB
Name: Dina, age: 19, city: Bandung
Tea: Rp12000
Has pizza? false
coffee   Rp20000
tea      Rp13000
and: 1
cat: 1
dog: 1
mat: 1
on: 1
sat: 2
the: 3
too: 1
Distinct words: 8
```

The text section shows that `trim`, `to_lowercase`, and `replace` produced new values while leaving the original untouched. `Café Bogor` really does have one more byte than characters, because of the `é`. The menu reflects every change: tea was updated to 13,000, coffee increased to 20,000, and cake was removed. The word counts are in alphabetical order thanks to sorting; remove the `sorted.sort();` line and run the program a few times to see that the order of a hash map is not fixed.

---

## 6. Fix the Errors in Your Code

String errors are mostly about the difference between bytes and characters and between `String` and `&str`. Hash map errors are mostly about the `Option` returned by `get`.

**Error 1: Indexing a string by position.**

```rust
// Wrong
let word = String::from("hello");
let first = word[0];

// Correct
let word = String::from("hello");
let first = word.chars().next();
```

The wrong version produces ``error[E0277]: the type `str` cannot be indexed by `{integer}` ``, with the note ``string indices are ranges of `usize` `` and the suggestion ``you can use `.chars().nth()` or `.bytes().nth()` ``. Since characters can span several bytes, a single position is ambiguous. `chars().next()` returns the first character as an `Option<char>` (it is `None` for an empty string), and `chars().nth(2)` returns the third.

**Error 2: Joining two `&str` values with `+`.**

```rust
// Wrong
let first = "Rust";
let second = " is fun";
let joined = first + second;

// Correct
let first = "Rust";
let second = " is fun";
let joined = format!("{first}{second}");
```

The wrong version produces ``error[E0369]: cannot add `&str` to `&str` ``, with the note ``string concatenation requires an owned `String` on the left``. The compiler suggests `first.to_owned() + second`, which works, but `format!` is clearer and works with any combination of text types.

**Error 3: Slicing in the middle of a multi byte character.**

```rust
// Wrong
let city = "Café Bogor";
println!("{}", &city[0..4]);

// Correct
let city = "Café Bogor";
let first_four: String = city.chars().take(4).collect();
println!("{first_four}");
```

The wrong version compiles but panics at runtime with ``end byte index 4 is not a char boundary; it is inside 'é' (bytes 3..5 of string)``. The `é` occupies bytes 3 and 4, so cutting at byte 4 would split it in half. The correct version works with characters: `take(4)` keeps the first four characters, and `collect` builds a `String` from them.

**Error 4: Using the result of `get` directly.**

```rust
// Wrong
let total = prices.get("tea") * 2;

// Correct
let total = prices.get("tea").unwrap_or(&0) * 2;
```

The wrong version produces ``error[E0369]: cannot multiply `Option<&{integer}>` by `{integer}` ``. `get` returns an `Option` containing a *reference*, because the key might be missing and because the map still owns the value. `unwrap_or(&0)` supplies a reference to 0 as the default, matching the `&` type. In a real program, `match` or `if let` lets you handle the missing case explicitly. If you forget the `use std::collections::HashMap;` line instead, the compiler reports ``error[E0433]: cannot find type `HashMap` in this scope`` and suggests the import.

---

## 7. Exercises

**Exercise 1:** Create a project called `palindrome`. Write `is_palindrome(text: &str) -> bool`, which ignores case, spaces, and punctuation: convert to lowercase, keep only letters and digits with `filter(|c| c.is_alphanumeric())`, collect into a `String`, and compare it with the same characters reversed (`chars().rev()` iterates backward). Test it on `"Kasur ini rusak"`, `"Rust is fun"`, and `"Never odd or even"`.

**Exercise 2:** Create a project called `vowel_counter`. Count how many times each vowel appears in the sentence `"Programming in Rust is a rewarding adventure"`, ignoring case, using a `HashMap<char, u32>` and the `entry` API. Print the counts in alphabetical order and the total number of vowels.

**Exercise 3:** Create a project called `contacts`. Store three names and phone numbers in a `HashMap<String, String>`. Look up one name that exists and one that does not, using `match`. Then update one person's number with `insert` and print all contacts sorted by name, together with the number of contacts.

---

## 8. Solutions

**Solution for Exercise 1:**

```rust
fn is_palindrome(text: &str) -> bool {
    let letters: String = text
        .to_lowercase()
        .chars()
        .filter(|c| c.is_alphanumeric())
        .collect();
    let reversed: String = letters.chars().rev().collect();
    letters == reversed
}

fn main() {
    for text in ["Kasur ini rusak", "Rust is fun", "Never odd or even"] {
        println!("{text:<20} palindrome: {}", is_palindrome(text));
    }
}
```

The first chain normalizes the text: lowercase everything, then keep only alphanumeric characters, which removes spaces and punctuation. `rev()` reverses an iterator, so collecting `letters.chars().rev()` builds the text backward. Two `String`s can be compared with `==`, which compares their content. The program prints:

```text
Kasur ini rusak      palindrome: true
Rust is fun          palindrome: false
Never odd or even    palindrome: true
```

**Solution for Exercise 2:**

```rust
use std::collections::HashMap;

fn main() {
    let sentence = "Programming in Rust is a rewarding adventure";
    let mut counts: HashMap<char, u32> = HashMap::new();
    for c in sentence.to_lowercase().chars() {
        if "aeiou".contains(c) {
            *counts.entry(c).or_insert(0) += 1;
        }
    }

    let mut sorted: Vec<(&char, &u32)> = counts.iter().collect();
    sorted.sort();
    for (vowel, count) in sorted {
        println!("{vowel}: {count}");
    }
    let total: u32 = counts.values().sum();
    println!("Total vowels: {total}");
}
```

`"aeiou".contains(c)` checks whether the character is one of the vowels; `contains` accepts a `char` as well as a `&str`. The counting line combines the two lines from the lesson into one: `*counts.entry(c).or_insert(0) += 1` gets the mutable reference and increases it in one statement. `counts.values()` iterates over just the values, which `sum` adds up. The program prints:

```text
a: 4
e: 3
i: 4
o: 1
u: 2
Total vowels: 14
```

**Solution for Exercise 3:**

```rust
use std::collections::HashMap;

fn main() {
    let mut contacts: HashMap<String, String> = HashMap::new();
    contacts.insert(String::from("Dina"), String::from("0812-1111-2222"));
    contacts.insert(String::from("Raka"), String::from("0813-3333-4444"));
    contacts.insert(String::from("Sari"), String::from("0857-5555-6666"));

    for name in ["Raka", "Budi"] {
        match contacts.get(name) {
            Some(phone) => println!("{name}: {phone}"),
            None => println!("{name}: no contact saved"),
        }
    }

    contacts.insert(String::from("Dina"), String::from("0819-7777-8888"));

    let mut names: Vec<&String> = contacts.keys().collect();
    names.sort();
    println!("Contacts ({}):", contacts.len());
    for name in names {
        println!("  {name:<5} {}", contacts[name]);
    }
}
```

Inserting `"Dina"` a second time replaces her old number, so the map still has three entries. This solution sorts only the keys with `keys()`, then reads each number with `contacts[name]`. Indexing a hash map with `[]` returns the value directly, but panics if the key is missing; here it is safe, because every name came from the map itself. The program prints:

```text
Raka: 0813-3333-4444
Budi: no contact saved
Contacts (3):
  Dina  0819-7777-8888
  Raka  0813-3333-4444
  Sari  0857-5555-6666
```

---

## Next Up - Lesson 15

In this lesson you learned to build text with `format!` and `push_str`, transform it with `trim`, `to_lowercase`, and `replace`, split it into parts, and respect the difference between bytes and characters. You also stored values by key in a `HashMap`, looked them up safely with `get`, updated and removed entries, sorted them for predictable output, and counted words with the `entry` API.

Several of the operations you have used can fail: parsing a number, reading a line, looking up a key. So far you have handled failures with `match`, `unwrap_or`, or `expect`. In Lesson 15, you will start Module 8 by learning Rust's full approach to error handling: when to panic, how to return a `Result` from your own functions, and how the `?` operator passes errors up to the caller in a single character.
