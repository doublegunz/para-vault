## 1. Before You Begin

Every program, regardless of language, does three fundamental things: it stores data, it categorizes what kind of data it has, and it performs operations on that data. In JavaScript, these three concerns map directly to variables, data types, and operators. Until you understand how JavaScript handles each of these, reading or writing even a short program will feel unpredictable.

JavaScript has a few behaviors that are unusual compared to other languages. It is dynamically typed, which means a variable can hold any kind of data and does not need to be declared with a type. It also performs something called type coercion, where it automatically converts values from one type to another in certain situations. Both features are important to understand before they surprise you in your own code.

### What You'll Build

You will create a `script.js` file that stores personal and product data in typed variables, performs calculations using arithmetic and comparison operators, and demonstrates JavaScript's type system and coercion behavior through `console.log()` output.

### What You'll Learn

- ✅ Declaring variables with `let`, `const`, and `var`
- ✅ Data types: string, number, boolean, null, undefined, symbol, bigint
- ✅ Type checking with `typeof`
- ✅ Arithmetic operators: `+`, `-`, `*`, `/`, `%`, `**`
- ✅ Comparison operators: `==`, `===`, `!=`, `!==`
- ✅ Logical operators: `&&`, `||`, `!`
- ✅ Template literals (backtick strings)
- ✅ Type coercion and why `===` is preferred

### What You'll Need

- Lesson 2 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-03`. Then right-click on `lesson-03`, select **New File**, type `index.html`, and press Enter. Right-click again, select **New File**, and type `script.js`.

Add the following to `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lesson 3</title>
</head>
<body>
    <h1>Variables, Data Types, and Operators</h1>
    <p>Open the browser console (F12) to see output.</p>
    <script src="script.js"></script>
</body>
</html>
```

The HTML is minimal here because all output for this lesson goes to the browser console rather than the page itself. The page exists only to load and run `script.js`. Open this file with Live Server to see the console output as you complete each step.

---

## 3. Variables: let, const, and var

Variables are named containers that hold values. JavaScript gives you three keywords for declaring them: `let`, `const`, and `var`. They differ in how they behave when you try to reassign them and in which parts of the code they are accessible. Understanding when to use each one is the first decision you make every time you write JavaScript.

Add the following to `script.js`:

```javascript
let age = 25;
console.log("Age:", age);
age = 26;
console.log("Age after birthday:", age);

const name = "Budi Santoso";
console.log("Name:", name);

const TAX_RATE = 0.11;
console.log("Tax rate:", TAX_RATE);

var city = "Bandung";
console.log("City:", city);
```

`let` declares a variable that can be reassigned. On the first line, `age` is set to `25`. Two lines later, it is reassigned to `26` without any error. Use `let` for values that are expected to change during the program.

`const` declares a variable that cannot be reassigned after its initial value is set. Attempting to write `name = "Citra"` after the `const` declaration would throw a `TypeError` at runtime. Use `const` by default for everything. Switch to `let` only when you know the value needs to change. This rule keeps your code predictable: if you see `const`, you know the variable's reference never changes.

`TAX_RATE` uses an all-uppercase naming convention. This is not enforced by JavaScript but is a widely followed signal to other developers that this value is an application-level constant that should never change.

`var` is the original variable declaration keyword from JavaScript's early days. It behaves differently from `let` and `const` in ways that create subtle bugs, particularly around variable hoisting and scope. In all new code, `var` should not be used. It appears here only so you can recognize it when reading older code.

---

## 4. Data Types

JavaScript has seven primitive data types. Every value in your program belongs to one of them. Understanding what category a value belongs to determines what operations are valid on it and what JavaScript will do when you mix types unexpectedly.

Add the following to `script.js`:

```javascript
const greeting = "Hello, World!";
const singleQuote = 'Also a string';
const templateLiteral = `Name: ${name}, Age: ${age}`;
console.log(templateLiteral);

const integer = 42;
const decimal = 3.14;
console.log(typeof integer, typeof decimal);

const isStudent = true;
const isAdmin = false;
console.log("Student:", isStudent, typeof isStudent);

const data = null;
console.log("Data:", data, typeof data);

let score;
console.log("Score:", score, typeof score);

console.log(typeof "hello");
console.log(typeof 42);
console.log(typeof true);
console.log(typeof undefined);
console.log(typeof null);
console.log(typeof [1, 2, 3]);
```

Strings can be written with double quotes, single quotes, or backticks. The backtick version is called a template literal, and it is the most powerful of the three because it supports string interpolation: any expression placed inside `${}` is evaluated and its result is embedded directly in the string. `${name}` is replaced with the value of the `name` variable, and `${age}` with the value of `age`.

JavaScript has only one type for all numbers: `number`. There is no distinction between integers and decimals. `42` and `3.14` both have `typeof` equal to `"number"`. JavaScript uses 64-bit floating-point representation for all numeric values.

Boolean values are either `true` or `false`. They are used in conditions and comparisons throughout every program.

`null` is a value you assign deliberately to indicate that a variable intentionally has no value. `typeof null` returns `"object"`, which is a well-known quirk of JavaScript that has been present since 1995. It cannot be fixed without breaking existing code, so it persists as a known inconsistency. `null` is not an object; `typeof` simply returns the wrong string for it.

`undefined` appears when a variable has been declared but has not yet been assigned a value. Declaring `let score` without assigning anything leaves it as `undefined`. You can check for `undefined` with `typeof`, which returns `"undefined"`.

`typeof [1, 2, 3]` returns `"object"` because arrays are objects in JavaScript. To check whether a value is an array specifically, you use `Array.isArray()`, which you will learn about in the arrays lesson.

---

## 5. Operators

Operators transform and compare values. JavaScript provides three main categories you will use constantly: arithmetic operators for mathematical calculations, comparison operators for evaluating relationships between values, and logical operators for combining boolean conditions.

Add the following to `script.js`:

```javascript
console.log("10 + 3 =", 10 + 3);
console.log("10 - 3 =", 10 - 3);
console.log("10 * 3 =", 10 * 3);
console.log("10 / 3 =", 10 / 3);
console.log("10 % 3 =", 10 % 3);
console.log("2 ** 10 =", 2 ** 10);

console.log("Hello" + " " + "World");

const price = 85000;
const qty = 3;
console.log(`Total: ${price * qty}`);

console.log(5 == "5");
console.log(5 === "5");
console.log(5 === 5);

console.log(true && false);
console.log(true || false);
console.log(!true);
```

`/` always returns a decimal result in JavaScript. `10 / 3` produces `3.3333...`, not `3`. There is no integer division operator. If you need a whole number result, use `Math.floor()` or `Math.trunc()`.

`%` is the modulo operator. It returns the remainder after dividing the left value by the right. `10 % 3` equals `1` because 3 fits into 10 three times, leaving 1 left over. Modulo is commonly used to determine whether a number is even or odd: any number where `n % 2 === 0` is even.

`**` is the exponentiation operator. `2 ** 10` means 2 raised to the power of 10, which equals 1024.

`+` has dual behavior. When both operands are numbers, it adds them. When either operand is a string, it concatenates. `"Hello" + " " + "World"` produces the string `"Hello World"`. This dual behavior is why type coercion can cause unexpected results, covered in the next section.

`==` performs loose equality comparison. Before comparing, it converts both values to the same type if they differ. `5 == "5"` evaluates to `true` because JavaScript converts the string `"5"` to the number `5` before comparing. `===` performs strict equality comparison. It compares both value and type without any conversion. `5 === "5"` evaluates to `false` because one is a number and the other is a string. Always use `===` and `!==` in your code. Loose equality (`==`) produces results that can be difficult to predict and is a common source of bugs.

`&&` is the logical AND operator. It returns `true` only when both sides are `true`. `||` is the logical OR operator. It returns `true` when at least one side is `true`. `!` is the logical NOT operator. It inverts the boolean value: `!true` is `false`, and `!false` is `true`.

---

## 6. Type Coercion

Type coercion is JavaScript's automatic conversion of values from one type to another when an operation requires it. Some coercions are intuitive and helpful. Others are surprising and can introduce bugs that are difficult to track down without knowing the rules.

Add the following to `script.js`:

```javascript
console.log("5" + 3);
console.log("5" - 3);
console.log("5" * 2);
console.log(true + 1);
console.log(false + 1);
console.log("" == false);

console.log(Number("42"));
console.log(String(42));
console.log(Boolean(0));
console.log(Boolean("hello"));
console.log(parseInt("42px"));
console.log(parseFloat("3.14"));
```

`"5" + 3` produces the string `"53"`, not the number `8`. When the `+` operator sees a string on either side, it treats the entire operation as string concatenation and converts the other value to a string first. This is why mixing string input from a form field with arithmetic using `+` produces unexpected results.

`"5" - 3` produces the number `2`. The `-` operator has no string meaning, so JavaScript converts `"5"` to the number `5` and performs subtraction. The same applies to `*`, `/`, and `%`. Only `+` triggers string concatenation.

`true + 1` produces `2` because `true` coerces to the number `1`. `false + 1` produces `1` because `false` coerces to `0`. These boolean-to-number conversions happen silently whenever a boolean appears in an arithmetic context.

`"" == false` returns `true` because both an empty string and `false` are considered "falsy" values, and `==` coerces them to a common type before comparing. This is one of the most cited reasons to always use `===` instead.

`Number("42")`, `String(42)`, and `Boolean(0)` are explicit conversions you control. When you need to convert between types, explicit conversion is always safer than relying on coercion. `parseInt("42px")` reads the integer portion of a string and stops at the first non-numeric character, returning `42`. `parseFloat("3.14")` does the same for decimal numbers.

---

## 7. Fix the Errors in Your Code

Three variable and type mistakes appear so commonly that they deserve specific attention. Each one produces an error or a wrong result that is invisible until you run the code.

**Error 1: Reassigning a `const` variable.**

`const` prevents any reassignment after the variable is declared. Attempting to assign a new value to a `const` throws a `TypeError` at runtime and stops the script entirely.

```javascript
// Wrong: cannot reassign a const
const total = 100;
total = 200;

// Correct: use let when the value needs to change
let total = 100;
total = 200;
```

The fix is straightforward: if a variable's value needs to change at any point during the program, declare it with `let` from the start. Reserve `const` for values that are fixed for the entire lifetime of the variable.

**Error 2: Using `==` instead of `===` for comparison.**

`==` compares values after converting them to the same type. This produces results that do not match what the code appears to say, which makes bugs harder to reason about.

```javascript
// Wrong: true even though the types are different
if (age == "25") { }

// Correct: false when types differ, which is the intended behavior
if (age === 25) { }
```

When `age` holds the number `25`, the condition `age == "25"` evaluates to `true` because `==` converts the string to a number before comparing. This might seem harmless, but it means code that should only accept the number `25` will accidentally accept the string `"25"` as well. Using `===` prevents this by requiring both value and type to match.

**Error 3: String concatenation when arithmetic is intended.**

When `+` appears in an expression that mixes strings and numbers, JavaScript applies concatenation from left to right as soon as it encounters a string operand.

```javascript
// Wrong: produces "Price: 10050" instead of "Price: 150"
let result = "Price: " + 100 + 50;

// Correct: parentheses force addition before concatenation
let result = "Price: " + (100 + 50);
```

`"Price: " + 100` runs first and produces the string `"Price: 100"`. Then `"Price: 100" + 50` concatenates again, producing `"Price: 10050"`. Wrapping the arithmetic in parentheses evaluates `100 + 50` as a number first, producing `150`, and then concatenates it with `"Price: "` to give the intended `"Price: 150"`.

---

## 8. Exercises

**Exercise 1:** Create a file `product.js` and declare four variables: `name` with `const` for a product name string, `price` with `const` for a numeric price, `quantity` with `let` for a number, and `inStock` with `let` for a boolean. Calculate a `total` equal to `price * quantity`. Display all five values using template literals in `console.log()`.

**Exercise 2:** Create a file `temperature.js`. Declare `const celsius = 37`. Calculate `fahrenheit` using the formula `celsius * 9 / 5 + 32`. Display both values in a single template literal. Use `.toFixed(1)` on each variable to limit the output to one decimal place.

**Exercise 3:** Create a file `coercion.js`. Write six `console.log()` statements, one each for: `"10" + 5`, `"10" - 5`, `"10" * 2`, `"10" / 2`, `"hello" * 2`, and `true + true`. Predict each result before running the file, then compare your predictions with the actual output.

---

## 9. Solutions

**Solution for Exercise 1:**

Create `product.js` and write the following:

```javascript
const name = "Laptop";
const price = 8500000;
let quantity = 3;
let inStock = true;
const total = price * quantity;

console.log(`Product: ${name}`);
console.log(`Price: Rp ${price.toLocaleString()}`);
console.log(`Quantity: ${quantity}`);
console.log(`Total: Rp ${total.toLocaleString()}`);
console.log(`In Stock: ${inStock}`);
```

`name` and `price` use `const` because a product's name and unit price do not change during a single calculation. `quantity` and `inStock` use `let` because these are values that might be updated later as inventory changes. `.toLocaleString()` formats the number with comma separators appropriate for the current locale, turning `8500000` into `"8,500,000"` in an English locale. Template literals make the output readable without manual string concatenation.

**Solution for Exercise 2:**

Create `temperature.js` and write the following:

```javascript
const celsius = 37;
const fahrenheit = celsius * 9 / 5 + 32;
console.log(`${celsius.toFixed(1)}°C = ${fahrenheit.toFixed(1)}°F`);
```

The formula `celsius * 9 / 5 + 32` follows the standard Celsius-to-Fahrenheit conversion. Because all operands are numbers, JavaScript performs arithmetic multiplication and division without any coercion issues. `.toFixed(1)` returns a string version of the number rounded to one decimal place. For `37`, this produces `"37.0"`. For `98.6`, it produces `"98.6"`. The result is always a string, but inside a template literal that does not cause any problem.

**Solution for Exercise 3:**

Create `coercion.js` and write the following:

```javascript
console.log("10" + 5);
console.log("10" - 5);
console.log("10" * 2);
console.log("10" / 2);
console.log("hello" * 2);
console.log(true + true);
```

`"10" + 5` produces `"105"` because `+` triggers string concatenation when a string is present. `"10" - 5` produces `5` because `-` has no string meaning and converts `"10"` to a number. `"10" * 2` and `"10" / 2` produce `20` and `5` respectively for the same reason. `"hello" * 2` produces `NaN` (Not a Number) because `"hello"` cannot be converted to a valid number, and any arithmetic on `NaN` remains `NaN`. `true + true` produces `2` because `true` coerces to `1` in a numeric context.

---

## Next Up - Lesson 4

Use `const` by default and switch to `let` only when the value must change. Never use `var` in new code. JavaScript has seven primitive types: string, number, boolean, null, undefined, symbol, and bigint. Template literals use backticks and support `${}` interpolation for embedding expressions directly in strings. Always use `===` for comparison - it checks both value and type without coercion. The `+` operator concatenates when a string is involved; all other arithmetic operators convert strings to numbers first.

In Lesson 4, you will learn control flow: making decisions with `if`, `else if`, `else`, and `switch` to write code that reacts differently to different conditions.