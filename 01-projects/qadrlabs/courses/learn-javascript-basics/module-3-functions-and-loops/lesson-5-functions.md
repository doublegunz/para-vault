## 1. Before You Begin

As programs grow, the same logic tends to appear in multiple places. Without a way to group and reuse code, you end up copying the same lines repeatedly - and when something needs to change, you have to find and update every copy. Functions solve this problem by letting you define logic once, give it a name, and call it wherever it is needed.

In Lesson 4, you learned how to write conditional logic that makes decisions based on values. In this lesson, you will wrap that logic and other code into functions so it can be reused, tested, and maintained more easily.

### What You'll Build

You will create a `script.js` file containing utility functions for calculations, string formatting, and data processing. You will also explore how arrow functions simplify short function expressions and how callback functions let you pass behavior as an argument.

### What You'll Learn

- ✅ Function declarations and expressions
- ✅ Parameters, default parameters, and return values
- ✅ Arrow functions (`=>`)
- ✅ Scope: global, function, block
- ✅ Callback functions (functions as arguments)

### What You'll Need

- Lesson 4 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-05`. Inside it, create `index.html` and `script.js`. Use the same HTML structure from previous lessons: a minimal page that links to `script.js` at the bottom of `<body>` and tells the reader to open the console for output.

---

## 3. Function Declarations

A function declaration defines a named function and makes it available throughout the current scope. It is the most explicit and readable way to define a function, and it has one important property called hoisting: the function is available even before the line where it is defined in the file.

Add the following to `script.js`:

```javascript
function greet(name) {
    return `Hello, ${name}!`;
}

console.log(greet("Budi"));
console.log(greet("Citra"));

function add(a, b) {
    return a + b;
}
console.log("Sum:", add(10, 5));

function calculateTax(price, rate = 0.11) {
    return price * rate;
}
console.log("Tax:", calculateTax(100000));
console.log("Tax:", calculateTax(100000, 0.05));

function logMessage(msg) {
    console.log("[LOG]", msg);
}
const result = logMessage("test");
console.log(result);
```

`function greet(name)` defines a function named `greet` that accepts one parameter called `name`. Inside the curly braces is the function body - the code that runs every time the function is called. `return` sends a value back to the caller. When you write `console.log(greet("Budi"))`, JavaScript calls `greet` with the argument `"Budi"`, the function runs, returns the string `"Hello, Budi!"`, and `console.log` prints it.

Parameters are the named placeholders in the function definition. Arguments are the actual values passed when calling the function. `greet` has one parameter (`name`). When called as `greet("Budi")`, the argument `"Budi"` is assigned to `name` for the duration of that call.

`calculateTax(price, rate = 0.11)` demonstrates a default parameter. When `rate` is not provided by the caller, JavaScript uses `0.11` automatically. When called as `calculateTax(100000, 0.05)`, the provided value `0.05` overrides the default.

`logMessage` has no `return` statement. Functions without a `return` statement always return `undefined`. Assigning the result of calling `logMessage` to `result` and then logging `result` confirms this: the console shows `undefined`. This is expected behavior, not an error. Functions that perform a side effect (like printing) rather than computing a value typically have no return statement.

---

## 4. Arrow Functions

Arrow functions are a more concise syntax for writing functions. They are especially useful for short, single-expression functions and are now the preferred style in modern JavaScript for most cases outside of class methods.

Add the following to `script.js`:

```javascript
const multiply = (a, b) => a * b;
console.log("Multiply:", multiply(4, 5));

const calculateTotal = (price, qty) => {
    const subtotal = price * qty;
    const tax = subtotal * 0.11;
    return subtotal + tax;
};
console.log("Total:", calculateTotal(50000, 3));

const double = n => n * 2;
console.log("Double:", double(7));

const getTimestamp = () => new Date().toLocaleString();
console.log("Now:", getTimestamp());
```

`const multiply = (a, b) => a * b` is an implicit return arrow function. When the function body is a single expression with no curly braces, JavaScript automatically returns the result of that expression. This is equivalent to writing `function multiply(a, b) { return a * b; }` but in a single line.

`calculateTotal` uses curly braces because its body has multiple statements. When curly braces are used, the implicit return is disabled and you must write `return` explicitly. Forgetting `return` in a multi-line arrow function is a very common mistake, covered in the Fix the Errors section.

`const double = n => n * 2` shows that when an arrow function has exactly one parameter, the parentheses around the parameter list are optional. With two or more parameters, or with zero parameters, the parentheses are required.

`const getTimestamp = () => new Date().toLocaleString()` shows an arrow function with no parameters. The empty parentheses `()` are required in this case. Every time `getTimestamp()` is called, it creates a new `Date` object and returns the current date and time formatted as a string.

---

## 5. Scope

Scope determines which parts of your code can access which variables. JavaScript has three levels of scope: global, function, and block. Understanding scope prevents bugs where a variable is undefined in one place but not another.

Add the following to `script.js`:

```javascript
const globalVar = "I am global";

function testScope() {
    const localVar = "I am local";
    console.log(globalVar);
    console.log(localVar);

    if (true) {
        const blockVar = "I am block-scoped";
        let alsoBlock = "Me too";
        console.log(blockVar);
        console.log(alsoBlock);
    }
}

testScope();
```

`globalVar` is declared outside any function, at the top level of the file. It is accessible everywhere in the script, including inside `testScope()`. This is global scope.

`localVar` is declared inside `testScope()`. It is accessible anywhere within the function body, but not outside it. Trying to access `localVar` after `testScope()` returns would throw a `ReferenceError: localVar is not defined`. This is function scope.

`blockVar` and `alsoBlock` are declared inside the `if` block. Variables declared with `const` or `let` exist only within the pair of curly braces where they are defined. This is block scope. Once execution moves past the closing `}` of the `if` block, those variables no longer exist. This is one of the key reasons `var` is avoided in modern code: `var` is function-scoped, not block-scoped, which means a `var` declared inside an `if` block leaks out and is accessible for the rest of the function.

---

## 6. Callback Functions

A callback is a function passed as an argument to another function. The receiving function calls it at some point during its own execution. Callbacks allow you to write flexible, reusable functions that can perform different operations depending on what behavior is passed in.

Add the following to `script.js`:

```javascript
function processArray(arr, callback) {
    const results = [];
    for (const item of arr) {
        results.push(callback(item));
    }
    return results;
}

const numbers = [1, 2, 3, 4, 5];

const doubled = processArray(numbers, n => n * 2);
console.log("Doubled:", doubled);

const squared = processArray(numbers, n => n * n);
console.log("Squared:", squared);

setTimeout(() => {
    console.log("This runs after 2 seconds");
}, 2000);
```

`processArray` accepts any array and any function as its second argument. Inside, it loops through the array, calls `callback(item)` for each element, and collects the results into a new array. The function does not know or care what `callback` does, which is what makes it reusable.

When `processArray(numbers, n => n * 2)` is called, the arrow function `n => n * 2` is passed as the callback. `processArray` calls it with each number in the array, and the results are `[2, 4, 6, 8, 10]`. When called with `n => n * n`, the same function produces `[1, 4, 9, 16, 25]`.

`setTimeout` is a built-in JavaScript function that accepts a callback and a delay in milliseconds. It waits for the specified delay, then calls the callback. `setTimeout(() => { console.log(...) }, 2000)` delays the log by two seconds. This is one of the most common uses of callbacks in real JavaScript code.

---

## 7. Fix the Errors in Your Code

Three function-related mistakes appear frequently and each one has a behavior that feels counterintuitive the first time you encounter it.

**Error 1: Calling an arrow function before it is declared.**

Function declarations are hoisted, meaning the JavaScript engine processes them before executing any code in the file. Arrow functions assigned to `const` or `let` are not. Calling them before the line where they are defined throws a `ReferenceError`.

```javascript
// Wrong: square is not yet defined at this point
console.log(square(5));
const square = n => n * n;

// Correct: call after the declaration
const square = n => n * n;
console.log(square(5));
```

If you need to call a function before it is written in the file, use a function declaration (`function square(n) { ... }`) instead of an arrow function assigned to `const`. Function declarations can be called from anywhere in the file because they are hoisted to the top before execution begins.

**Error 2: Missing `return` in a multi-line arrow function.**

Arrow functions without curly braces have an implicit return. Arrow functions with curly braces require an explicit `return` statement. Forgetting it means the function computes a value but silently discards it, returning `undefined` instead.

```javascript
// Wrong: result is calculated but never returned
const getTotal = (price, qty) => {
    price * qty;
};
console.log(getTotal(100, 3));

// Correct: return sends the value back to the caller
const getTotal = (price, qty) => {
    return price * qty;
};
console.log(getTotal(100, 3));
```

The wrong version logs `undefined` because the expression `price * qty` is evaluated but its result is immediately discarded. Adding `return` before the expression sends the computed value back to whoever called `getTotal`.

**Error 3: Returning an object literal from a single-line arrow function.**

When an arrow function body starts with `{`, JavaScript treats it as the opening of a code block, not an object literal. The object's properties are parsed as labeled statements, and the function returns `undefined`.

```javascript
// Wrong: {} is read as a code block, name: name is a label
const makePerson = name => { name: name };
console.log(makePerson("Budi"));

// Correct: wrap the object in parentheses to clarify intent
const makePerson = name => ({ name: name });
console.log(makePerson("Budi"));
```

Wrapping the object in parentheses tells JavaScript that the `{` starts an expression, not a block. The function then correctly returns an object with a `name` property.

---

## 8. Exercises

**Exercise 1:** Create a file `temperature.js`. Write two arrow functions: `celsiusToFahrenheit(c)` and `fahrenheitToCelsius(f)` using the correct formulas. Then display a conversion table for the Celsius values `0`, `20`, `37`, and `100` using `console.log` and template literals. Format each number to one decimal place with `.toFixed(1)`.

**Exercise 2:** Create a file `currency.js`. Write a function `formatCurrency(amount)` that returns a formatted string like `"Rp 8,500,000"`. Use `amount.toLocaleString("id-ID")` to handle the comma separators. Test it with at least three different amounts using `console.log`.

**Exercise 3:** Create a file `primes.js`. Write a function `isPrime(n)` that returns `true` if `n` is a prime number and `false` otherwise. A prime number is only divisible by 1 and itself. Use it to collect and log all prime numbers between 1 and 50.

---

## 9. Solutions

**Solution for Exercise 1:**

Create `temperature.js` and write the following:

```javascript
const celsiusToFahrenheit = c => c * 9 / 5 + 32;
const fahrenheitToCelsius = f => (f - 32) * 5 / 9;

[0, 20, 37, 100].forEach(c => {
    const f = celsiusToFahrenheit(c);
    console.log(`${c.toFixed(1)}°C = ${f.toFixed(1)}°F`);
});
```

Both functions use single-expression arrow syntax with implicit return. `celsiusToFahrenheit` multiplies by `9/5` and adds 32. `fahrenheitToCelsius` subtracts 32 and multiplies by `5/9`. The parentheses around `(f - 32)` ensure subtraction happens before multiplication. `.forEach` is an array method that calls the provided callback once for each element - here it runs the conversion and log for each Celsius value in the array.

**Solution for Exercise 2:**

Create `currency.js` and write the following:

```javascript
const formatCurrency = amount => `Rp ${amount.toLocaleString("id-ID")}`;

console.log(formatCurrency(8500000));
console.log(formatCurrency(150000));
console.log(formatCurrency(75500));
```

`toLocaleString("id-ID")` formats the number according to Indonesian locale conventions, inserting a period as the thousands separator: `8500000` becomes `"8.500.000"`. The function concatenates `"Rp "` to the front using a template literal. Because the function body is a single expression, no `return` keyword or curly braces are needed.

**Solution for Exercise 3:**

Create `primes.js` and write the following:

```javascript
const isPrime = n => {
    if (n < 2) return false;
    for (let i = 2; i <= Math.sqrt(n); i++) {
        if (n % i === 0) return false;
    }
    return true;
};

const primes = [];
for (let i = 1; i <= 50; i++) {
    if (isPrime(i)) primes.push(i);
}
console.log("Primes:", primes);
```

`isPrime` first rejects any number below 2, since prime numbers are defined as greater than 1. The loop then checks every integer from 2 up to the square root of `n`. If any number divides `n` evenly (remainder is 0), `n` is not prime and the function returns `false` immediately. If the loop finishes without finding a divisor, the function returns `true`. Using `Math.sqrt(n)` as the loop limit is an optimization: if `n` has no divisors up to its square root, it has no divisors at all. The outer loop collects all primes from 1 to 50 into the `primes` array using `push`, then logs the complete array.

---

## Next Up - Lesson 6

Functions are defined with `function` declarations or arrow function expressions (`=>`). Parameters accept input and `return` sends output back to the caller. Default parameters provide fallback values when an argument is omitted. Arrow functions without curly braces return the result of a single expression implicitly. Arrow functions with curly braces require an explicit `return`. `const` and `let` are block-scoped: they exist only within the `{}` where they are declared. Callbacks are functions passed as arguments, allowing behavior to be injected into reusable functions.

In Lesson 6, you will learn about loops: repeating actions with `for`, `while`, and `for...of` to process sequences of data without writing repetitive code.