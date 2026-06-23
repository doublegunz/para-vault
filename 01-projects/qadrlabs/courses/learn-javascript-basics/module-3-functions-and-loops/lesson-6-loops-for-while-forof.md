## 1. Before You Begin

Most useful programs do not just run through a fixed set of steps once. They repeat operations: for every item in a list, process it; while a condition has not been met, keep trying; for each character in a string, examine it. Without loops, you would have to write the same code manually for each repetition - which is both impractical and fragile.

In Lesson 5, you learned to package logic into reusable functions. In this lesson, you will use loops to run that logic across entire collections of data and repeat operations until a condition changes.

### What You'll Build

You will create a `script.js` file that generates a multiplication table, computes the sum of a range of numbers, processes arrays and object keys, and uses `break` and `continue` to control iteration precisely.

### What You'll Learn

- ✅ `for` loop (counter-controlled)
- ✅ `while` and `do...while` loops
- ✅ `for...of` for iterating arrays and strings
- ✅ `for...in` for iterating object keys
- ✅ `break` and `continue`
- ✅ Nested loops

### What You'll Need

- Lesson 5 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-06`. Inside it, create `index.html` and `script.js`. Use the same minimal HTML structure from previous lessons: a page that links to `script.js` at the bottom of `<body>` with a note to open the browser console for output.

---

## 3. The for Loop

The `for` loop is the most common loop in JavaScript. It is ideal when you know in advance how many times the loop should run, or when you need a counter variable to use inside the loop body.

Add the following to `script.js`:

```javascript
for (let i = 1; i <= 5; i++) {
    console.log("Count:", i);
}

let sum = 0;
for (let i = 1; i <= 100; i++) {
    sum += i;
}
console.log("Sum 1-100:", sum);

for (let i = 10; i >= 1; i--) {
    console.log(i);
}
console.log("Liftoff!");

const num = 7;
for (let i = 1; i <= 10; i++) {
    console.log(`${num} x ${i} = ${num * i}`);
}
```

A `for` loop has three parts inside the parentheses, separated by semicolons. The first part is the initializer: `let i = 1` creates a counter variable and sets its starting value. The second part is the condition: `i <= 5` is checked before each iteration, and the loop stops as soon as it is `false`. The third part is the update: `i++` increments the counter after each iteration. All three parts work together to advance the loop toward its exit condition.

`sum += i` is shorthand for `sum = sum + i`. Each iteration adds the current value of `i` to the running total. After 100 iterations, `sum` holds the result of adding every integer from 1 to 100, which is `5050`.

Counting down works by starting from a high value and using `i--` to decrement until the condition `i >= 1` becomes `false`. This is identical to counting up but in the opposite direction.

The multiplication table example combines the loop counter `i` with a fixed value `num` inside a template literal. Each iteration produces one row of the table by computing `num * i`.

---

## 4. while and do...while

The `while` loop is appropriate when you do not know in advance how many iterations are needed - only the condition that should stop the loop. The `do...while` loop is a variant that guarantees the body runs at least once before the condition is checked.

Add the following to `script.js`:

```javascript
let count = 0;
while (count < 5) {
    console.log("While:", count);
    count++;
}

let input;
do {
    input = Math.floor(Math.random() * 10);
    console.log("Got:", input);
} while (input !== 7);
console.log("Found 7!");
```

In the `while` example, `count` starts at `0` and the condition `count < 5` is checked before each iteration. The body runs and `count++` increments the counter. When `count` reaches `5`, the condition becomes `false` and the loop stops. The most common mistake with `while` loops is forgetting to update the variable that the condition depends on, which results in an infinite loop.

`do...while` executes the body first, then checks the condition. In this example, a random number from 0 to 9 is generated using `Math.floor(Math.random() * 10)`. `Math.random()` returns a decimal between 0 (inclusive) and 1 (exclusive). Multiplying by 10 scales it to the range 0 to just under 10. `Math.floor()` rounds down to the nearest integer, giving a whole number from 0 to 9. The loop continues as long as the generated number is not 7. Because the body always runs at least once, the first number is always generated and checked.

---

## 5. for...of and for...in

JavaScript provides two specialized loop forms for working with collections. `for...of` iterates over the values in an array or string. `for...in` iterates over the keys of an object. Using the wrong one for the wrong data structure is a common source of confusion.

Add the following to `script.js`:

```javascript
const fruits = ["Apple", "Banana", "Cherry"];
for (const fruit of fruits) {
    console.log("Fruit:", fruit);
}

for (const char of "Hello") {
    console.log("Char:", char);
}

const person = { name: "Budi", age: 25, city: "Bandung" };
for (const key in person) {
    console.log(`${key}: ${person[key]}`);
}
```

`for...of` produces each value from the iterable in order. For the `fruits` array, it produces `"Apple"`, then `"Banana"`, then `"Cherry"`. For the string `"Hello"`, it produces each character individually: `"H"`, `"e"`, `"l"`, `"l"`, `"o"`. The loop variable (`fruit`, `char`) is declared with `const` because its value does not change within a single iteration - it is reassigned fresh on each iteration.

`for...in` produces each key from the object in order of insertion. For `person`, it produces the strings `"name"`, `"age"`, and `"city"`. Using `person[key]` retrieves the value associated with that key. The bracket notation `object[variable]` is used here instead of dot notation `object.key` because the key is stored in a variable, not written as a literal property name.

---

## 6. break and continue

`break` and `continue` give you fine-grained control over loop execution. `break` exits the loop entirely. `continue` skips the rest of the current iteration and moves immediately to the next one.

Add the following to `script.js`:

```javascript
for (let i = 1; i <= 20; i++) {
    if (i === 7) {
        console.log("Found 7! Stopping.");
        break;
    }
    console.log(i);
}

for (let i = 1; i <= 10; i++) {
    if (i % 2 !== 0) continue;
    console.log("Even:", i);
}
```

In the first loop, the numbers 1 through 20 would normally all be printed. When `i` reaches 7, the `if` condition is true and `break` runs. The loop terminates immediately - none of the remaining numbers are printed. `break` is useful when you are searching for something and want to stop as soon as you find it.

In the second loop, `continue` is used to skip all odd numbers. When `i % 2 !== 0` is `true`, meaning `i` is odd, the rest of the loop body is skipped and the loop advances to the next iteration. Only even numbers, where `i % 2 === 0`, reach the `console.log("Even:", i)` line. The output is `2`, `4`, `6`, `8`, `10`.

---

## 7. Fix the Errors in Your Code

Three loop-related mistakes are responsible for a disproportionate number of bugs in JavaScript programs. Each one is easy to make and sometimes difficult to diagnose.

**Error 1: Creating an infinite loop by forgetting to update the loop variable.**

A `while` loop's condition must eventually become `false`, or the loop never stops. Forgetting the line that changes the variable the condition depends on freezes the browser tab.

```javascript
// Wrong: i never changes, loop runs forever
let i = 0;
while (i < 5) {
    console.log(i);
}

// Correct: i increments each iteration, loop exits when i reaches 5
let i = 0;
while (i < 5) {
    console.log(i);
    i++;
}
```

If you accidentally create an infinite loop, close the browser tab immediately. In Chrome, you can also open Task Manager (Shift+Esc) and end the unresponsive tab process. Always confirm that your loop has a statement that advances toward the exit condition.

**Error 2: Misunderstanding `<` vs `<=` (off-by-one error).**

Off-by-one errors occur when a loop runs one iteration too many or too few. The choice between `<` and `<=` controls whether the boundary value is included or excluded.

```javascript
// Runs 5 times: i = 0, 1, 2, 3, 4 (stops before 5)
for (let i = 0; i < 5; i++) {
    console.log(i);
}

// Runs 5 times: i = 1, 2, 3, 4, 5 (includes 5)
for (let i = 1; i <= 5; i++) {
    console.log(i);
}
```

Both versions run exactly 5 times but produce different values. Use `< length` when working with zero-indexed arrays (since the last valid index is `length - 1`). Use `<= n` when you want to include `n` itself in the range, such as counting from 1 to 10.

**Error 3: Using `for...in` to iterate over an array.**

`for...in` iterates over an object's enumerable property keys. When applied to an array, it produces the indexes as strings (`"0"`, `"1"`, `"2"`) rather than the values. This is rarely what you want, and the string type of the keys can cause unexpected behavior in code that expects numbers.

```javascript
// Wrong: produces string indexes "0", "1", "2" - not the values
const arr = ["a", "b", "c"];
for (const i in arr) {
    console.log(i);
}

// Correct: use for...of to get values directly
for (const value of arr) {
    console.log(value);
}
```

Use `for...of` when you want the values in an array or string. Use `for...in` only when you want the property keys of a plain object.

---

## 8. Exercises

**Exercise 1:** Create a file `divisible.js`. Use a `for` loop to find all numbers between 1 and 100 that are divisible by both 3 and 5. Use `continue` to skip numbers that do not meet the condition and `console.log` each qualifying number.

**Exercise 2:** Create a file `fizzbuzz.js`. Use a `for` loop to iterate numbers 1 through 30. For each number: print `"FizzBuzz"` if divisible by both 3 and 5, `"Fizz"` if divisible only by 3, `"Buzz"` if divisible only by 5, or the number itself otherwise.

**Exercise 3:** Create a file `table.js`. Use two nested `for` loops to generate a 5x5 multiplication table. Each row should show the products of one row of the table (1 through 5 multiplied by the column number). Display each row as a single formatted string using `console.log`.

---

## 9. Solutions

**Solution for Exercise 1:**

Create `divisible.js` and write the following:

```javascript
for (let i = 1; i <= 100; i++) {
    if (i % 3 !== 0 || i % 5 !== 0) continue;
    console.log(i);
}
```

The condition `i % 3 !== 0 || i % 5 !== 0` is true whenever `i` is not divisible by 3 or not divisible by 5. In either of those cases, `continue` skips to the next iteration. Only when both `i % 3 === 0` and `i % 5 === 0` are true does execution reach `console.log(i)`. The qualifying numbers are 15, 30, 45, 60, 75, and 90 - every multiple of 15 in the range.

**Solution for Exercise 2:**

Create `fizzbuzz.js` and write the following:

```javascript
for (let i = 1; i <= 30; i++) {
    if (i % 15 === 0) {
        console.log("FizzBuzz");
    } else if (i % 3 === 0) {
        console.log("Fizz");
    } else if (i % 5 === 0) {
        console.log("Buzz");
    } else {
        console.log(i);
    }
}
```

The FizzBuzz check must come first. If the divisibility by 3 check came first, numbers like 15 would print `"Fizz"` instead of `"FizzBuzz"` because the first matching condition would win. Checking `i % 15 === 0` first ensures that multiples of both 3 and 5 are caught before either individual check runs.

**Solution for Exercise 3:**

Create `table.js` and write the following:

```javascript
for (let i = 1; i <= 5; i++) {
    let row = "";
    for (let j = 1; j <= 5; j++) {
        row += String(i * j).padStart(4);
    }
    console.log(row);
}
```

The outer loop controls the row number `i`. The inner loop controls the column number `j`. For each combination of `i` and `j`, the product `i * j` is computed. `String(i * j).padStart(4)` converts the number to a string and pads it with spaces on the left until it is at least 4 characters wide. This alignment ensures that single-digit and double-digit products line up into neat columns. Each iteration of the inner loop appends one product to the `row` string. When the inner loop finishes, the complete row is logged, and the outer loop moves to the next row.

---

## Next Up - Lesson 7

The `for` loop is best for counter-controlled repetition where the number of iterations is known. The `while` loop runs as long as a condition is true and is best when the iteration count is unknown. The `do...while` loop guarantees at least one execution before checking the condition. `for...of` iterates over array and string values. `for...in` iterates over object property keys and should not be used on arrays. `break` exits the loop immediately. `continue` skips the rest of the current iteration and advances to the next. Always ensure loops have an update step that moves toward the exit condition.

In Lesson 7, you will learn about arrays: how to store ordered collections of data and process them with powerful built-in methods like `map`, `filter`, and `reduce`.