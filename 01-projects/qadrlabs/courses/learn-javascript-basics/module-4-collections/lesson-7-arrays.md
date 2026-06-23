## 1. Before You Begin

Most real programs work with collections of data, not just single values. A shopping cart holds multiple items. A gradebook holds multiple scores. A to-do list holds multiple tasks. Arrays are the primary data structure for ordered collections in JavaScript. They grow and shrink dynamically, can hold any type of value, and come with powerful built-in methods that allow you to transform, search, filter, and summarize data with minimal code.

In Lesson 6, you learned how to use loops to repeat operations. In this lesson, you will see how array methods like `map`, `filter`, and `reduce` handle many of the same tasks as loops but in a more declarative and readable style.

### What You'll Build

You will create a `script.js` file that processes a list of products using array creation methods, mutation methods, and higher-order array methods to filter by stock, extract prices, sort by value, and calculate inventory totals.

### What You'll Learn

- ✅ Creating arrays and accessing elements
- ✅ Adding and removing: `push`, `pop`, `shift`, `unshift`, `splice`
- ✅ Searching: `indexOf`, `includes`, `find`, `findIndex`
- ✅ Transforming: `map`, `filter`, `reduce`, `sort`
- ✅ Iterating: `forEach`, `for...of`
- ✅ Spread operator `...` and array destructuring

### What You'll Need

- Lesson 6 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-07`. Inside it, create `index.html` and `script.js` using the same minimal HTML structure from previous lessons.

---

## 3. Array Basics

An array is created with square brackets `[]`. Elements are separated by commas. Each element has a numeric index starting at `0`. The first element is at index `0`, the second at index `1`, and so on.

Add the following to `script.js`:

```javascript
const fruits = ["Apple", "Banana", "Cherry"];
console.log(fruits[0]);
console.log(fruits.length);

fruits.push("Durian");
fruits.unshift("Avocado");
console.log(fruits);

fruits.pop();
fruits.shift();
console.log(fruits);

fruits.splice(1, 1);
console.log(fruits);

fruits.splice(1, 0, "Blueberry");
console.log(fruits);
```

`fruits[0]` accesses the element at index `0`, which is `"Apple"`. `fruits.length` returns the number of elements in the array, which is `3`. Indexes always start at `0`, so the last valid index is always `length - 1`.

`push` adds one or more elements to the end of the array and returns the new length. `unshift` adds elements to the beginning and shifts all existing elements one position to the right. Both methods modify the original array.

`pop` removes and returns the last element. `shift` removes and returns the first element, shifting all remaining elements one position to the left. After `push("Durian")` and `unshift("Avocado")`, the array has five elements. After `pop()` and `shift()`, it returns to its original three elements.

`splice` is the most flexible mutation method. `fruits.splice(1, 1)` starts at index `1` and removes `1` element. `fruits.splice(1, 0, "Blueberry")` starts at index `1`, removes `0` elements, and inserts `"Blueberry"` at that position. The second argument controls how many existing elements to remove, and any additional arguments are inserted in their place.

---

## 4. Array Methods: map, filter, find, and reduce

The most powerful feature of JavaScript arrays is their collection of higher-order methods. Each method accepts a callback function and applies it to the array in a specific way. Understanding what each method returns is essential to using them correctly.

Add the following to `script.js`:

```javascript
const products = [
    { name: "Laptop", price: 8500000, stock: 10 },
    { name: "Mouse", price: 150000, stock: 50 },
    { name: "Keyboard", price: 750000, stock: 30 },
    { name: "Monitor", price: 3500000, stock: 8 },
    { name: "Webcam", price: 500000, stock: 0 },
];

const names = products.map(p => p.name);
console.log("Names:", names);

const withTax = products.map(p => ({
    ...p,
    priceWithTax: p.price * 1.11
}));
console.log("With tax:", withTax);

const inStock = products.filter(p => p.stock > 0);
console.log("In stock:", inStock.length);

const expensive = products.filter(p => p.price > 1000000);
console.log("Expensive:", expensive.map(p => p.name));

const laptop = products.find(p => p.name === "Laptop");
console.log("Found:", laptop);

const totalValue = products.reduce((sum, p) => sum + p.price * p.stock, 0);
console.log("Total inventory value:", totalValue.toLocaleString());

const sorted = [...products].sort((a, b) => a.price - b.price);
console.log("Cheapest first:", sorted.map(p => `${p.name}: ${p.price}`));

products.forEach((p, i) => {
    console.log(`${i + 1}. ${p.name} - Rp ${p.price.toLocaleString()}`);
});
```

`map` creates a new array by calling the callback on every element and collecting each return value. `products.map(p => p.name)` returns a new array of just the name strings: `["Laptop", "Mouse", "Keyboard", "Monitor", "Webcam"]`. The original `products` array is unchanged. The second `map` uses the spread operator `...p` to copy all existing properties of each product into a new object and then adds a `priceWithTax` property alongside them.

`filter` creates a new array containing only the elements for which the callback returns `true`. `products.filter(p => p.stock > 0)` returns a new array with every product that has at least one unit in stock, excluding the Webcam because its `stock` is `0`.

`find` returns the first element for which the callback returns `true`, or `undefined` if no element passes the test. Unlike `filter`, it returns a single element, not a new array. `products.find(p => p.name === "Laptop")` returns the entire laptop object.

`reduce` processes the array down to a single accumulated value. It takes a callback with two arguments: the accumulator (`sum`) and the current element (`p`). The second argument to `reduce` (the `0` after the callback) is the initial value of the accumulator. Each call to the callback must return the new value of the accumulator for the next iteration.

`sort` sorts the array in place, modifying the original. To avoid mutating `products`, `[...products]` creates a shallow copy first. Without a compare function, `sort` converts elements to strings and sorts alphabetically - `10` would sort before `2` because `"1"` comes before `"2"` in ASCII. Passing `(a, b) => a.price - b.price` produces a numeric sort: when the result is negative, `a` comes first; when positive, `b` comes first; when zero, their order stays the same.

`forEach` calls the callback for each element but does not return anything. Its return value is always `undefined`. Use it for side effects (like logging) rather than for producing new values. The second parameter of the callback receives the current index.

---

## 5. Spread Operator and Destructuring

The spread operator and array destructuring are two modern JavaScript features that make working with arrays more concise and expressive.

Add the following to `script.js`:

```javascript
const arr1 = [1, 2, 3];
const arr2 = [4, 5, 6];
const merged = [...arr1, ...arr2];
console.log("Merged:", merged);

const copy = [...arr1];
console.log("Copy:", copy);

const [first, second, ...rest] = [10, 20, 30, 40, 50];
console.log(first, second, rest);

console.log([1, 2, 3].includes(2));
console.log([1, 2, 3].includes(5));
```

`[...arr1, ...arr2]` uses the spread operator to expand both arrays into a new one. The result is `[1, 2, 3, 4, 5, 6]`. You can spread multiple arrays and insert individual values anywhere in the new array: `[0, ...arr1, 3.5, ...arr2, 7]` is valid.

`[...arr1]` creates a shallow copy of the array. The new array contains the same values but is a completely separate object in memory. Modifying `copy` does not affect `arr1`. This is the standard way to clone an array in modern JavaScript.

Array destructuring extracts elements by position into named variables. `const [first, second, ...rest]` assigns the first element to `first`, the second to `second`, and all remaining elements to `rest` as a new array. The `...rest` syntax in a destructuring pattern is called a rest element and collects everything that was not explicitly named.

`includes` checks whether a value is present anywhere in the array and returns `true` or `false`. It uses strict equality internally, so `[1, 2, 3].includes("1")` would return `false`.

---

## 6. Fix the Errors in Your Code

Three of the most common array mistakes involve sorting, copying, and choosing the wrong iteration method. Each one produces incorrect results without throwing an error, which makes them harder to debug.

**Error 1: Calling `sort()` on a number array without a compare function.**

`sort()` without arguments converts elements to strings before comparing them. In string comparison, `"10"` comes before `"2"` because `"1"` has a smaller character code than `"2"`. This produces an order that is wrong for numbers.

```javascript
// Wrong: sorts as strings, result is [10, 2, 30, 4]
const nums = [10, 2, 30, 4];
nums.sort();
console.log(nums);

// Correct: compare function produces numeric sort [2, 4, 10, 30]
nums.sort((a, b) => a - b);
console.log(nums);
```

The compare function `(a, b) => a - b` tells `sort` how to order two elements: a negative result means `a` comes first, a positive result means `b` comes first, and zero means their order is unchanged. For descending order, reverse the subtraction: `(a, b) => b - a`.

**Error 2: Using `=` to copy an array.**

When you assign an array variable to another variable with `=`, you copy the reference, not the data. Both variables then point to the same underlying array in memory. Modifying one modifies both.

```javascript
// Wrong: copy and original point to the same array
const original = [1, 2, 3];
const copy = original;
copy.push(4);
console.log(original);

// Correct: spread creates a new independent array
const original = [1, 2, 3];
const copy = [...original];
copy.push(4);
console.log(original);
```

In the wrong version, `console.log(original)` prints `[1, 2, 3, 4]` because `push` modified the shared array. In the correct version, `original` still prints `[1, 2, 3]` because `copy` is a separate array created by the spread.

**Error 3: Using `forEach` when `map` is needed.**

`forEach` always returns `undefined`. If you call it expecting to get a transformed array back, you will receive `undefined` instead - and no error will be thrown.

```javascript
// Wrong: forEach returns undefined, doubled is undefined
const doubled = [1, 2, 3].forEach(n => n * 2);
console.log(doubled);

// Correct: map returns a new array with the transformed values
const doubled = [1, 2, 3].map(n => n * 2);
console.log(doubled);
```

Use `forEach` when you want to perform a side effect for each element (printing, updating a DOM element) and do not need a return value. Use `map` when you want to produce a new array where each element is a transformed version of the original.

---

## 7. Exercises

**Exercise 1:** Declare `const scores = [85, 72, 90, 65, 78, 92, 55]`. Using array methods, compute the average score, find all scores above 75, find the highest score using `Math.max()`, and count how many scores are 70 or above. Display all four results using `console.log`.

**Exercise 2:** Declare `const words = ["banana", "apple", "cherry", "avocado"]`. Create three separate result arrays: one sorted alphabetically using `sort()`, one containing only words longer than 5 characters using `filter()`, and one with all words converted to uppercase using `map()`. Log each result.

**Exercise 3:** Using the `products` array from Section 4, use `reduce` to find the product with the highest price. The callback should compare each product's price to a running maximum and return whichever is greater. Display the most expensive product's name and price.

---

## 8. Solutions

**Solution for Exercise 1:**

Create a file `scores.js` and write the following:

```javascript
const scores = [85, 72, 90, 65, 78, 92, 55];

const avg = scores.reduce((sum, val) => sum + val, 0) / scores.length;
const above75 = scores.filter(s => s > 75);
const highest = Math.max(...scores);
const passingCount = scores.filter(s => s >= 70).length;

console.log(`Average: ${avg.toFixed(1)}`);
console.log(`Above 75: ${above75}`);
console.log(`Highest: ${highest}`);
console.log(`Passing: ${passingCount}`);
```

`reduce` sums all values starting from `0`, then dividing by `scores.length` gives the average. `filter(s => s > 75)` returns a new array with only the qualifying scores. `Math.max(...scores)` uses the spread operator to pass each score as a separate argument to `Math.max`, which returns the largest value. `.filter(s => s >= 70).length` chains two operations: `filter` produces a new array of passing scores, and `.length` retrieves its count.

**Solution for Exercise 2:**

Create a file `words.js` and write the following:

```javascript
const words = ["banana", "apple", "cherry", "avocado"];

const sorted = [...words].sort();
const long = words.filter(w => w.length > 5);
const upper = words.map(w => w.toUpperCase());

console.log("Sorted:", sorted);
console.log("Long words:", long);
console.log("Uppercase:", upper);
```

`[...words].sort()` creates a copy before sorting to avoid modifying the original `words` array. String `sort()` without a compare function sorts alphabetically by default, which is correct for strings. `filter(w => w.length > 5)` keeps only words where the character count exceeds 5. `map(w => w.toUpperCase())` returns a new array where every string has been converted to uppercase using the built-in string method.

**Solution for Exercise 3:**

Create a file `expensive.js` and write the following:

```javascript
const products = [
    { name: "Laptop", price: 8500000, stock: 10 },
    { name: "Mouse", price: 150000, stock: 50 },
    { name: "Keyboard", price: 750000, stock: 30 },
    { name: "Monitor", price: 3500000, stock: 8 },
    { name: "Webcam", price: 500000, stock: 0 },
];

const mostExpensive = products.reduce((max, p) =>
    p.price > max.price ? p : max
);

console.log(`Most expensive: ${mostExpensive.name} - Rp ${mostExpensive.price.toLocaleString()}`);
```

When `reduce` is called without a second argument, the first element of the array serves as the initial accumulator value. In this case, the accumulator `max` starts as the Laptop object. For each subsequent product `p`, the callback compares `p.price` to `max.price`. If `p.price` is greater, `p` becomes the new `max`. Otherwise, `max` stays unchanged. After processing all products, `max` holds the object with the highest price.

---

## Next Up - Lesson 8

Arrays store ordered collections using numeric indexes starting at `0`. `push` and `pop` add and remove from the end. `shift` and `unshift` work at the beginning. `splice` inserts or removes at any position. `map` creates a new array of transformed values. `filter` creates a new array of elements that pass a test. `find` returns the first matching element. `reduce` accumulates an array into a single value. `sort` requires a compare function for correct numeric ordering. The spread operator `[...arr]` creates a shallow copy of an array. `forEach` returns `undefined` and is for side effects only.

In Lesson 8, you will learn about objects: how to structure related data with named properties using key-value pairs, and how to use object methods, destructuring, and the spread operator with objects.