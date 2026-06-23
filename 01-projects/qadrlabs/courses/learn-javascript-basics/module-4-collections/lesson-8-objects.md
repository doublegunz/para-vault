## 1. Before You Begin

Arrays are excellent for ordered collections where position matters. But many real-world data structures are better described by named properties than by numeric indexes. A user account has a name, an email, and a role. A product has a title, a price, and a stock count. Objects let you group related data under named keys, making the code that uses that data more readable and intentional.

In Lesson 7, you learned to process collections with array methods. In this lesson, you will learn how objects organize structured data, how to work with their properties, and how arrays of objects are the backbone of almost every data-driven JavaScript application.

### What You'll Build

You will create objects for students and products, add methods to objects, use `Object.keys()`, `Object.values()`, and `Object.entries()` to iterate over properties, convert objects to JSON and back, and process an array of student objects with array methods.

### What You'll Learn

- ✅ Creating objects with `{}` (object literals)
- ✅ Accessing properties: dot notation and bracket notation
- ✅ Adding, modifying, and deleting properties
- ✅ Object destructuring
- ✅ Object methods (functions inside objects)
- ✅ `Object.keys()`, `Object.values()`, `Object.entries()`
- ✅ JSON: `JSON.stringify()` and `JSON.parse()`

### What You'll Need

- Lesson 7 completed
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-08`. Inside it, create `index.html` and `script.js` using the same minimal HTML structure from previous lessons.

---

## 3. Object Basics

An object is created with curly braces `{}`. Inside, each entry is a key-value pair where the key is a property name and the value can be any data type. Properties are separated by commas.

Add the following to `script.js`:

```javascript
const student = {
    name: "Budi Santoso",
    age: 25,
    major: "Informatics",
    gpa: 3.87,
    isActive: true,
};

console.log(student.name);
console.log(student["major"]);

student.age = 26;
student.email = "budi@example.com";
delete student.isActive;

console.log(student);

const { name, age, gpa } = student;
console.log(`${name}, age ${age}, GPA ${gpa}`);

const updated = { ...student, gpa: 3.90, semester: 7 };
console.log(updated);
```

Dot notation (`student.name`) is the standard way to read a property when you know its name at the time you write the code. Bracket notation (`student["major"]`) is used when the property name is stored in a variable or contains characters that are not valid in dot notation.

You can add a new property to an existing `const` object by simply assigning to a key that does not exist yet. `student.email = "budi@example.com"` creates the `email` property on the spot. `delete student.isActive` removes the property entirely. Note that `const` prevents you from reassigning the variable to a different object, but it does not prevent you from modifying the object's contents.

Object destructuring `const { name, age, gpa } = student` extracts the named properties into individual variables in a single statement. It is equivalent to writing three separate `const name = student.name`, `const age = student.age`, and `const gpa = student.gpa` declarations but more concise.

The spread operator `{ ...student, gpa: 3.90, semester: 7 }` creates a new object that contains copies of all properties from `student`, then overrides `gpa` with the new value and adds a new `semester` property. Properties listed after the spread override any matching ones from the spread source.

---

## 4. Object Methods and Iteration

Objects can contain functions as property values. When a function is stored as an object property, it is called a method. Methods use `this` to refer to the object they belong to.

Add the following to `script.js`:

```javascript
const product = {
    name: "Laptop",
    price: 8500000,
    stock: 10,
    getTotal() {
        return this.price * this.stock;
    },
    display() {
        console.log(`${this.name}: Rp ${this.price.toLocaleString()} (${this.stock} units)`);
    },
};

product.display();
console.log("Total:", product.getTotal().toLocaleString());

console.log("Keys:", Object.keys(product));
console.log("Values:", Object.values(product));

Object.entries(product).forEach(([key, value]) => {
    if (typeof value !== "function") {
        console.log(`  ${key}: ${value}`);
    }
});
```

`getTotal()` and `display()` use the shorthand method syntax, which is equivalent to writing `getTotal: function() { ... }` but shorter. Inside both methods, `this` refers to the object the method is called on. When you call `product.getTotal()`, JavaScript sets `this` to `product`, so `this.price` equals `product.price` and `this.stock` equals `product.stock`.

`Object.keys(product)` returns an array of all the object's property names as strings, including method names. `Object.values(product)` returns an array of all the values. `Object.entries(product)` returns an array of `[key, value]` pairs, which the `forEach` then destructures directly in the callback parameter using `([key, value])`. The `typeof value !== "function"` check filters out the methods so only data properties are logged.

---

## 5. JSON

JSON (JavaScript Object Notation) is a text format for representing objects and arrays. It is used to send data between a server and a browser, to store data in `localStorage`, and to save configuration. JavaScript provides two built-in functions for converting between objects and JSON strings.

Add the following to `script.js`:

```javascript
const data = { name: "Budi", scores: [85, 90, 78] };
const jsonString = JSON.stringify(data);
console.log("JSON:", jsonString);
console.log("Pretty:", JSON.stringify(data, null, 2));

const parsed = JSON.parse(jsonString);
console.log("Parsed:", parsed.name, parsed.scores);
```

`JSON.stringify(data)` converts the object into a JSON string: `{"name":"Budi","scores":[85,90,78]}`. The result is a plain string that can be stored or transmitted. `JSON.stringify(data, null, 2)` adds indentation of 2 spaces per level, producing a human-readable multiline format useful for logging.

`JSON.parse(jsonString)` does the reverse: it reads a JSON string and produces a JavaScript object. The returned value is a real object you can access with dot notation. After parsing, `parsed.name` is `"Budi"` and `parsed.scores` is the array `[85, 90, 78]`.

A common use of `JSON.stringify` and `JSON.parse` is storing and retrieving structured data in `localStorage`, the browser's built-in key-value storage. `localStorage` can only hold strings, so objects must be stringified before saving and parsed after retrieving.

---

## 6. Arrays of Objects

The most common data structure in JavaScript applications is an array of objects. Each object represents a single record, and the array represents a collection. All the array methods from Lesson 7 (`map`, `filter`, `reduce`, `sort`) work seamlessly with arrays of objects.

Add the following to `script.js`:

```javascript
const students = [
    { name: "Andi", gpa: 3.5 },
    { name: "Budi", gpa: 3.87 },
    { name: "Citra", gpa: 3.2 },
    { name: "Dewi", gpa: 3.95 },
];

const top = students.reduce((best, s) => s.gpa > best.gpa ? s : best);
console.log("Top:", top.name, top.gpa);

const ranked = [...students].sort((a, b) => b.gpa - a.gpa);
ranked.forEach((s, i) => console.log(`${i + 1}. ${s.name} (${s.gpa})`));

const avgGpa = students.reduce((sum, s) => sum + s.gpa, 0) / students.length;
console.log("Average GPA:", avgGpa.toFixed(2));
```

`reduce` without a second argument uses the first element as the initial accumulator. Here, `best` starts as the first student object. The callback compares the current student's GPA to the best seen so far and returns whichever is higher. After processing all students, the result is the object with the highest GPA.

`[...students].sort((a, b) => b.gpa - a.gpa)` creates a copy before sorting to avoid mutating the original array. Subtracting `a.gpa` from `b.gpa` (rather than `a` from `b`) sorts in descending order, placing the highest GPA first.

---

## 7. Fix the Errors in Your Code

Three object-related mistakes appear consistently and each one either produces `undefined` silently or corrupts data in a way that is not immediately obvious.

**Error 1: Using dot notation when the property name is in a variable.**

Dot notation treats whatever follows the dot as a literal property name. It does not look up a variable by that name. To use a variable as the key, bracket notation is required.

```javascript
// Wrong: looks for a property literally named "key", returns undefined
const key = "name";
console.log(student.key);

// Correct: reads the value of the variable key ("name"), then looks up that property
console.log(student[key]);
```

This distinction matters whenever property names are computed dynamically, such as when iterating over keys or building a generic utility function that works with any object property.

**Error 2: Using an arrow function as an object method that needs `this`.**

Arrow functions do not have their own `this`. They inherit `this` from the scope where they are defined, which is typically the global scope or the enclosing function - not the object. As a result, `this.value` inside an arrow method returns `undefined`.

```javascript
// Wrong: arrow function inherits this from outer scope, not the object
const obj = {
    value: 42,
    getValue: () => this.value,
};
console.log(obj.getValue());

// Correct: regular method syntax binds this to the calling object
const obj = {
    value: 42,
    getValue() {
        return this.value;
    },
};
console.log(obj.getValue());
```

Always use the regular method shorthand (`methodName() { ... }`) when an object method needs to reference its own properties through `this`. Reserve arrow functions for callbacks inside those methods.

**Error 3: Assuming spread creates a deep copy.**

The spread operator performs a shallow copy. For top-level primitive values, this is a true copy. For nested objects or arrays, only the reference is copied. Modifying a nested property in the copy also modifies the original.

```javascript
// Wrong: nested object b is still shared between original and copy
const original = { a: 1, b: { c: 2 } };
const copy = { ...original };
copy.b.c = 99;
console.log(original.b.c);

// Correct: JSON round-trip creates a fully independent deep copy
const copy = JSON.parse(JSON.stringify(original));
copy.b.c = 99;
console.log(original.b.c);
```

`JSON.parse(JSON.stringify(original))` creates a deep copy by converting the object to a string (which breaks all references) and then parsing it back into a new object. This approach does not work for objects containing functions, `undefined`, or special types like `Date`, but it is sufficient for plain data objects.

---

## 8. Exercises

**Exercise 1:** Create a `book` object with `title`, `author`, `price`, and `pages` properties. Add a `summary()` method that returns a formatted description string. Create an array of three book objects and log each one's summary.

**Exercise 2:** Create a `contacts` array containing at least three objects with `name`, `phone`, and `city` properties. Write three functions: `findByName(name)` using `find`, `addContact(contact)` using `push`, and `removeByName(name)` using `filter`. Test all three operations and log the updated contacts array.

**Exercise 3:** Create an `orders` array where each object has `product`, `quantity`, and `unitPrice` properties. Use `map` to add a `total` property to each order, `reduce` to compute the grand total of all orders, and `filter` to find orders where the total exceeds Rp 500,000.

---

## 9. Solutions

**Solution for Exercise 1:**

Create `books.js` and write the following:

```javascript
const books = [
    {
        title: "Clean Code",
        author: "Robert Martin",
        price: 45,
        pages: 431,
        summary() {
            return `${this.title} by ${this.author} (${this.pages} pages, $${this.price})`;
        }
    },
    {
        title: "Refactoring",
        author: "Martin Fowler",
        price: 55,
        pages: 448,
        summary() {
            return `${this.title} by ${this.author} (${this.pages} pages, $${this.price})`;
        }
    },
    {
        title: "Design Patterns",
        author: "GoF",
        price: 60,
        pages: 395,
        summary() {
            return `${this.title} by ${this.author} (${this.pages} pages, $${this.price})`;
        }
    },
];

books.forEach(b => console.log(b.summary()));
```

Each method uses `this` to reference the properties of the object it belongs to. When `books[0].summary()` is called, `this` is bound to that specific book object, so `this.title` gives `"Clean Code"` and `this.price` gives `45`. `forEach` calls `summary()` on each book and passes the returned string to `console.log`.

**Solution for Exercise 2:**

Create `contacts.js` and write the following:

```javascript
let contacts = [
    { name: "Andi", phone: "081234", city: "Jakarta" },
    { name: "Budi", phone: "089876", city: "Bandung" },
    { name: "Citra", phone: "087654", city: "Surabaya" },
];

const findByName = name =>
    contacts.find(c => c.name.toLowerCase() === name.toLowerCase());

const addContact = contact => contacts.push(contact);

const removeByName = name => {
    contacts = contacts.filter(c => c.name !== name);
};

addContact({ name: "Dewi", phone: "085432", city: "Medan" });
console.log(findByName("Budi"));
removeByName("Andi");
console.log(contacts);
```

`contacts` is declared with `let` rather than `const` because `removeByName` replaces the entire array reference using `filter`. `findByName` uses `.toLowerCase()` on both sides of the comparison to make the search case-insensitive. `addContact` mutates the existing array with `push`, while `removeByName` creates a new filtered array and reassigns the variable.

**Solution for Exercise 3:**

Create `orders.js` and write the following:

```javascript
const orders = [
    { product: "Laptop", quantity: 1, unitPrice: 8500000 },
    { product: "Mouse", quantity: 5, unitPrice: 150000 },
    { product: "Monitor", quantity: 2, unitPrice: 3500000 },
];

const withTotal = orders.map(o => ({ ...o, total: o.quantity * o.unitPrice }));
const grandTotal = withTotal.reduce((sum, o) => sum + o.total, 0);
const bigOrders = withTotal.filter(o => o.total > 500000);

console.log(withTotal);
console.log("Grand total: Rp", grandTotal.toLocaleString());
console.log("Big orders:", bigOrders.map(o => o.product));
```

`map` creates a new array of order objects, each augmented with a `total` property computed from `quantity * unitPrice`. The spread `...o` copies all existing properties so nothing is lost. `reduce` starts from `0` and accumulates the total price of every order. `filter` then selects only orders where that computed total exceeds Rp 500,000.

---

## Next Up - Lesson 9

Objects store data as key-value pairs accessed with dot notation or bracket notation. Properties can be added, changed, or deleted at any time on `const` objects. Object destructuring extracts named properties into variables. Methods are functions inside objects and must use regular syntax (not arrow functions) when they need `this`. `Object.keys`, `Object.values`, and `Object.entries` provide array-based iteration over an object's contents. `JSON.stringify` converts an object to a string and `JSON.parse` converts it back. Spread performs a shallow copy only - use `JSON.parse(JSON.stringify())` for deeply nested data.

In Lesson 9, you will learn about the DOM: the browser's representation of the HTML page as a tree of objects that JavaScript can read and modify to make pages interactive.