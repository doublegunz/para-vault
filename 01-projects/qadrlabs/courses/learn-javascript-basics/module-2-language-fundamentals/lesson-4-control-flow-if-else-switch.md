## 1. Before You Begin

Programs need to make decisions. Every interactive application is built on conditional logic: if the user is logged in, show the dashboard; if the score is above 90, assign a grade of A; if the day is Saturday or Sunday, display "Weekend." Without control flow, a program follows the same path every single time it runs, regardless of the data it receives.

In Lesson 3, you learned how to store values in variables and compare them using operators. In this lesson, you will use those comparisons inside control flow statements to make your programs respond differently to different conditions.

### What You'll Build

You will create a `script.js` file that implements a grade classifier, an access control check, a ticket pricing system, and a day-of-week program using `if/else`, `switch`, and the ternary operator.

### What You'll Learn

- ✅ `if`, `else if`, `else` for conditional execution
- ✅ `switch` for multiple exact-value checks
- ✅ Ternary operator `condition ? a : b`
- ✅ Truthy and falsy values
- ✅ Logical operators in conditions: `&&`, `||`, `!`

### What You'll Need

- Lesson 3 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-04`. Inside it, create `index.html` and `script.js` using the same structure from Lesson 3: an HTML page that links to the script file at the bottom of `<body>` and instructs the reader to open the browser console for output.

---

## 3. if, else if, else

The `if` statement is the most fundamental building block of conditional logic. It evaluates a condition and executes a block of code only when that condition is `true`. Chaining `else if` and `else` provides additional paths for every other possibility.

Add the following to `script.js`:

```javascript
const score = 78;

if (score >= 90) {
    console.log("Grade: A");
} else if (score >= 80) {
    console.log("Grade: B");
} else if (score >= 70) {
    console.log("Grade: C");
} else if (score >= 60) {
    console.log("Grade: D");
} else {
    console.log("Grade: F");
}

const age = 22;
const hasId = true;

if (age >= 17 && hasId) {
    console.log("Access granted.");
} else if (age >= 17 && !hasId) {
    console.log("Please bring your ID.");
} else {
    console.log("You must be at least 17.");
}
```

JavaScript evaluates each condition from top to bottom and executes only the first block whose condition is `true`. When `score` is `78`, the first condition `score >= 90` is `false`, the second `score >= 80` is `false`, and the third `score >= 70` is `true`. The third block runs and prints `"Grade: C"`. None of the remaining conditions are checked because a match was already found.

The `else` block at the end is a catch-all. It runs only when none of the preceding `if` or `else if` conditions were `true`. It is optional, but including it ensures your code handles unexpected input rather than silently doing nothing.

In the access check example, `age >= 17 && hasId` uses the `&&` operator to require both conditions to be true simultaneously. `!hasId` inverts the boolean value of `hasId`. When `hasId` is `true`, `!hasId` is `false`. This allows the second branch to represent the specific case where the person is old enough but forgot their ID.

---

## 4. Truthy and Falsy

JavaScript does not require a strict boolean in an `if` condition. Any value can be used, and JavaScript automatically classifies it as either truthy or falsy. This is one of JavaScript's most practical features and also one of its most common sources of confusion.

Add the following to `script.js`:

```javascript
const userName = "";
if (userName) {
    console.log("Name:", userName);
} else {
    console.log("Name is empty.");
}

const items = [];
if (items.length) {
    console.log("Has items");
} else {
    console.log("No items");
}
```

The falsy values in JavaScript are exactly seven: `false`, `0`, `-0`, `""` (empty string), `null`, `undefined`, and `NaN`. Every other value is truthy, including `"0"` (a non-empty string), `[]` (an empty array), and `{}` (an empty object).

In the first example, `userName` holds an empty string `""`. An empty string is falsy, so the `if` block is skipped and the `else` block runs, printing `"Name is empty."`. This pattern is the standard way to check whether a string has content without explicitly writing `userName !== ""`.

In the second example, `items` is an empty array. The array itself is truthy (all objects are truthy), but `items.length` is `0` because there are no elements. `0` is falsy, so the `else` block runs. This is the standard way to check whether an array contains any items.

---

## 5. switch

`switch` is designed for situations where you need to compare a single value against many specific options. It is often cleaner than a long chain of `else if` statements when all the conditions test the same variable for exact equality.

Add the following to `script.js`:

```javascript
const day = new Date().getDay();

switch (day) {
    case 0:
        console.log("Sunday");
        break;
    case 1:
        console.log("Monday");
        break;
    case 2:
        console.log("Tuesday");
        break;
    case 3:
        console.log("Wednesday");
        break;
    case 4:
        console.log("Thursday");
        break;
    case 5:
        console.log("Friday");
        break;
    case 6:
        console.log("Saturday");
        break;
    default:
        console.log("Invalid day");
}

switch (day) {
    case 0:
    case 6:
        console.log("Weekend");
        break;
    default:
        console.log("Weekday");
}
```

`new Date().getDay()` returns a number from `0` to `6` representing the current day of the week, where `0` is Sunday and `6` is Saturday. The `switch` statement compares this number against each `case` using strict equality (`===`).

`break` is required at the end of each case. Without it, JavaScript continues executing the code in the next case regardless of whether it matched. This behavior is called fall-through, and it is almost always a bug rather than an intentional choice. Always include `break` unless you are deliberately grouping cases.

In the second `switch`, `case 0:` and `case 6:` share a single code block. When neither case has a `break`, execution falls through from one to the next. Here this is intentional: both Saturday and Sunday should print `"Weekend"`. Grouping cases this way is a common and accepted pattern.

The `default` case runs when no `case` matches the value being switched on. It serves the same purpose as the final `else` in an `if/else` chain.

---

## 6. Ternary Operator

The ternary operator is a compact way to write a simple `if/else` that produces one of two values. It is not a replacement for full `if/else` blocks but is useful when a condition determines a single value assignment or a short message.

Add the following to `script.js`:

```javascript
const voterAge = 20;
const canVote = voterAge >= 17 ? "Yes" : "No";
console.log("Can vote:", canVote);

const examScore = 75;
const result = examScore >= 70 ? "Pass" : "Fail";
console.log("Result:", result);
```

The syntax is `condition ? valueIfTrue : valueIfFalse`. JavaScript evaluates the condition first. If it is truthy, the expression returns `valueIfTrue`. If it is falsy, it returns `valueIfFalse`. The result is then assigned to the variable on the left of `=`.

`voterAge >= 17 ? "Yes" : "No"` evaluates the condition `20 >= 17`, which is `true`, so `canVote` is assigned `"Yes"`. For `examScore >= 70`, `75 >= 70` is `true`, so `result` is assigned `"Pass"`.

Use the ternary operator only when both branches are short values or simple expressions. When either branch requires multiple statements, use a full `if/else` block for readability.

---

## 7. Fix the Errors in Your Code

Three control flow mistakes appear with high frequency and are particularly dangerous because they either fail silently or produce incorrect results without throwing an error.

**Error 1: Using `=` (assignment) instead of `===` (comparison) in an `if` condition.**

A single `=` in a condition assigns a value rather than testing one. The condition then evaluates the assigned value as truthy or falsy, which almost always evaluates to `true` and causes the `if` block to run unconditionally.

```javascript
// Wrong: assigns 100 to score, condition is always true
if (score = 100) {
    console.log("Perfect score!");
}

// Correct: compares score to 100
if (score === 100) {
    console.log("Perfect score!");
}
```

This mistake is easy to make because `=` and `===` look similar. Some developers write the constant on the left side of the comparison, like `100 === score`, which causes a syntax error instead of a silent bug if a single `=` is used accidentally. Most modern code editors and linters flag this pattern automatically.

**Error 2: Missing `break` in a `switch` case.**

Without `break`, execution continues into the next case even if that case's value does not match. This is called fall-through and produces output from multiple cases when only one was expected.

```javascript
// Wrong: case 1 falls through into case 2
switch (day) {
    case 1:
        console.log("Monday");
    case 2:
        console.log("Tuesday");
}

// Correct: each case ends with break
switch (day) {
    case 1:
        console.log("Monday");
        break;
    case 2:
        console.log("Tuesday");
        break;
}
```

When `day` is `1`, the wrong version prints both `"Monday"` and `"Tuesday"`. The correct version prints only `"Monday"` because `break` exits the `switch` block immediately. The only time fall-through is intentional is when multiple `case` labels share a single code block with no statements between them, as shown in the weekend example in Section 5.

**Error 3: Using `==` instead of `===` in conditions involving falsy values.**

Loose equality `==` applies type coercion before comparing, which causes values that look different to be considered equal. This produces conditions that pass when they should not.

```javascript
// Wrong: true due to coercion, both 0 and "" are falsy
if (0 == "") {
    console.log("Equal!");
}

// Correct: false because types differ
if (0 === "") {
    console.log("Equal!");
}
```

`0 == ""` is `true` in JavaScript because both values coerce to the same falsy form before comparison. `0 === ""` is `false` because one is a number and the other is a string. Using `===` everywhere prevents this class of bugs entirely.

---

## 8. Exercises

**Exercise 1:** Create a file `ticket.js` and declare `const age = 22`. Write an `if/else if/else` chain that assigns a price to a `let price` variable based on age: under 5 is free (0), 5 through 12 is 25, 13 through 17 is 50, 18 through 59 is 100, and 60 and above is 25. Display the age and price using a template literal.

**Exercise 2:** Create a file `season.js` and declare `const month = 4`. Write a `switch` statement that assigns a season name to a `let season` variable: months 12, 1, and 2 are Winter; 3, 4, and 5 are Spring; 6, 7, and 8 are Summer; 9, 10, and 11 are Autumn. Use grouped cases. Display the month and season using `console.log`.

**Exercise 3:** Create a file `login.js`. Declare `const username = "admin"` and `const password = "1234"`. Write an `if/else` that logs `"Login successful."` when both values match exactly, and `"Invalid credentials."` otherwise. Use strict equality and the `&&` operator.

---

## 9. Solutions

**Solution for Exercise 1:**

Create `ticket.js` and write the following:

```javascript
const age = 22;
let price;

if (age < 5) {
    price = 0;
} else if (age <= 12) {
    price = 25;
} else if (age <= 17) {
    price = 50;
} else if (age <= 59) {
    price = 100;
} else {
    price = 25;
}

console.log(`Age: ${age}, Price: $${price}`);
```

`price` is declared with `let` rather than `const` because its value is assigned inside one of the branches, not at the point of declaration. If `const` were used, the initial declaration would have no value, and `const` requires a value at declaration time. The conditions use `<` and `<=` rather than `>= x && <= y` because the `else if` chain already filters out ages covered by earlier conditions. By the time the condition `age <= 12` is checked, ages below 5 were already caught by the first branch.

**Solution for Exercise 2:**

Create `season.js` and write the following:

```javascript
const month = 4;
let season;

switch (month) {
    case 12:
    case 1:
    case 2:
        season = "Winter";
        break;
    case 3:
    case 4:
    case 5:
        season = "Spring";
        break;
    case 6:
    case 7:
    case 8:
        season = "Summer";
        break;
    case 9:
    case 10:
    case 11:
        season = "Autumn";
        break;
    default:
        season = "Invalid month";
}

console.log(`Month ${month}: ${season}`);
```

Grouping three `case` labels before a single code block is the clean way to handle multiple values that produce the same result. When `month` is `4`, JavaScript matches `case 4:`, finds no code between `case 4:` and `case 5:`, falls through to the line `season = "Spring"`, assigns it, then hits `break` and exits.

**Solution for Exercise 3:**

Create `login.js` and write the following:

```javascript
const username = "admin";
const password = "1234";

if (username === "admin" && password === "1234") {
    console.log("Login successful.");
} else {
    console.log("Invalid credentials.");
}
```

`&&` requires both conditions to be `true` for the entire expression to be `true`. If `username` is correct but `password` is wrong, the overall condition is `false` and the `else` branch runs. Using `===` ensures no type coercion occurs: the string `"1234"` is compared strictly against the string value of `password`, so a numeric `1234` without quotes would not be accepted.

---

## Next Up - Lesson 5

`if/else if/else` evaluates conditions in order and executes the first matching branch. `switch` compares a single value against multiple exact cases and requires `break` at the end of each case to prevent fall-through. The ternary operator `condition ? a : b` is a concise way to assign one of two values based on a condition. Falsy values are `false`, `0`, `""`, `null`, `undefined`, and `NaN`; everything else is truthy. Always use `===` for comparison - `==` can produce unexpected results through type coercion.

In Lesson 5, you will learn about functions: how to group code into reusable, named blocks that accept input and return output.