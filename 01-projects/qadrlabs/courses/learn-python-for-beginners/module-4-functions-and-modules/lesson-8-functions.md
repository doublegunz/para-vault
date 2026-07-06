As code grows, repetition becomes a problem. You write the same calculation in three different places, and when the formula needs to change, you have to find and update it in three places. Bugs follow. Functions solve this by letting you write a piece of logic once, give it a name, and call it from anywhere in your program. The logic lives in one place, and every caller benefits from any improvement you make.

## 1. Before You Begin

In Lessons 3 through 7, you worked with Python's core data types and structures: variables, lists, dictionaries, conditionals, and loops. Every script you wrote ran from top to bottom in a single flow. Functions introduce a new organizational layer: named, reusable blocks of code that can be called multiple times, in any order, from anywhere in the program.

In the mini project at Lesson 13, your script will have several distinct responsibilities: reading a CSV file, cleaning raw values, calculating summaries, and printing a formatted report. Without functions, all of that logic would be mixed together in one long sequence of code that is hard to read and impossible to reuse. Functions let you break the project into named, focused pieces. This lesson teaches you everything you need to write those pieces.

### What You'll Build

You will write a script called `functions.py` that defines several utility functions for processing product data: one that validates an entry, one that calculates a discounted price with a default discount rate, one that analyzes a list of prices and returns summary statistics, and one that formats a currency value. Together these functions simulate the kind of helper library you will build in the mini project.

### What You'll Learn

- ✅ How to define functions with `def` and return values with `return`
- ✅ How to define required parameters and optional parameters with default values
- ✅ How to call functions with positional and named (keyword) arguments
- ✅ How functions can return multiple values as a tuple
- ✅ How to write one-line anonymous functions with `lambda`
- ✅ How to document functions with docstrings

### What You'll Need

- Completion of Lesson 7 (dictionaries and sets)
- The `python-basics` folder open in VS Code

## 2. Defining and Calling Functions

A function is defined with the `def` keyword, followed by the function name, a set of parentheses containing any parameters, and a colon. The function body is indented beneath the `def` line. When Python reaches a `return` statement, it sends the specified value back to the caller and exits the function immediately.

### Step 1: Write Your First Function

Create a new file called `functions.py` and add the following:

```python
def greet(name):
    return f"Hello, {name}!"

print(greet("Budi"))
print(greet("Siti"))
print(greet("Andi"))
```

Output:

```
Hello, Budi!
Hello, Siti!
Hello, Andi!
```

`def greet(name):` declares a function named `greet` that accepts one parameter called `name`. Each time you call `greet("Budi")`, Python executes the function body with `name` set to `"Budi"` and returns the formatted string. The original string `f"Hello, {name}!"` is constructed fresh on each call using whatever value was passed for `name`.

If a function reaches the end of its body without hitting a `return` statement, Python automatically returns `None`. This is fine for functions whose purpose is to produce a side effect (like printing), but any function that is supposed to produce a value for the caller to use must have an explicit `return`.

### Step 2: Write a Function Without Parameters

```python
def print_separator():
    print("-" * 40)

print_separator()
print("Product Report")
print_separator()
```

Output:

```
----------------------------------------
Product Report
----------------------------------------
```

Not all functions need parameters. `print_separator()` takes no input and returns nothing. Its entire purpose is the side effect of printing a divider line. Calling it multiple times prints the same line each time, which is more readable than repeating `print("-" * 40)` throughout the code.

## 3. Parameters and Default Values

Functions become more flexible when parameters have default values. A parameter with a default value is optional: callers can omit it, in which case the default is used, or they can pass a custom value to override the default.

### Step 1: Define Default Parameter Values

```python
def get_excerpt(text, length=100):
    if len(text) <= length:
        return text
    return text[:length] + "..."

print(get_excerpt("Short text"))
print(get_excerpt("A very long description that goes on and on.", 20))
```

Output:

```
Short text
A very long description...
```

`length=100` makes `length` optional. When you call `get_excerpt("Short text")`, Python uses `100` as the default. When you call `get_excerpt("A very long description...", 20)`, the value `20` overrides the default. Parameters with default values must always come after parameters without defaults in the function signature.

### Step 2: Use Named (Keyword) Arguments

```python
def create_product(name, price, category, in_stock=True):
    return {
        "name": name,
        "price": price,
        "category": category,
        "in_stock": in_stock,
    }

product_a = create_product("Laptop", 8500000, "Electronics")
product_b = create_product(name="Mouse", price=150000, category="Accessories", in_stock=False)

print(product_a)
print(product_b)
```

Output:

```
{'name': 'Laptop', 'price': 8500000, 'category': 'Electronics', 'in_stock': True}
{'name': 'Mouse', 'price': 150000, 'category': 'Accessories', 'in_stock': False}
```

When calling a function, you can pass arguments by position (like `product_a`) or by name (like `product_b`). Named arguments, also called keyword arguments, let you pass values in any order and make the call self-documenting: `in_stock=False` is immediately clear at the call site without needing to count parameter positions.

## 4. Returning Multiple Values

Python functions can return more than one value in a single `return` statement. The values are packed into a tuple automatically, and you can unpack them on the receiving end.

### Step 1: Return More Than One Value

```python
def analyze_prices(prices):
    lowest = min(prices)
    highest = max(prices)
    average = sum(prices) / len(prices)
    return lowest, highest, average

prices = [85000, 150000, 750000, 2800000]
lowest, highest, average = analyze_prices(prices)

print(f"Lowest:  Rp {lowest:,}")
print(f"Highest: Rp {highest:,}")
print(f"Average: Rp {average:,.0f}")
```

Output:

```
Lowest:  Rp 85,000
Highest: Rp 2,800,000
Average: Rp 953,750
```

`return lowest, highest, average` is equivalent to `return (lowest, highest, average)`. Python packs the three values into a tuple. On the receiving side, `lowest, highest, average = analyze_prices(prices)` unpacks the tuple into three separate variables. This is the idiomatic way to get multiple outputs from a single function call without needing wrapper objects.

`min()`, `max()`, and `sum()` are Python built-in functions that operate on any iterable and return the minimum value, maximum value, and sum of all values respectively.

## 5. Lambda Functions

A lambda is a short, anonymous function written in a single expression. It is defined with the `lambda` keyword rather than `def` and does not have a name unless you assign it to a variable. Lambdas are most useful as short callbacks passed to other functions like `sort()`, `filter()`, and `map()`.

### Step 1: Create a Lambda

```python
def double(x):
    return x * 2

double_lambda = lambda x: x * 2

print(double(5))
print(double_lambda(5))
```

Both produce `10`. The `lambda x: x * 2` syntax defines a function that takes one argument `x` and returns `x * 2`. It is equivalent to the `def` version but written in one line.

### Step 2: Use Lambda as a Sort Key

```python
products = [
    {"name": "Laptop", "price": 8500000},
    {"name": "Mouse", "price": 150000},
    {"name": "Monitor", "price": 2800000},
]

products.sort(key=lambda p: p["price"])

for product in products:
    print(f"{product['name']}: Rp {product['price']:,}")
```

Output:

```
Mouse: Rp 150,000
Monitor: Rp 2,800,000
Laptop: Rp 8,500,000
```

`products.sort(key=lambda p: p["price"])` sorts the list of dictionaries by the `"price"` field. The `key` argument accepts a function that takes one element and returns the value to sort by. A lambda is perfect here because the function is short and used only in this one place. Writing a full `def` for a single-use sort key would add unnecessary lines and visual noise.

For anything more complex than a simple expression, use a regular `def` function and pass its name as the `key` argument instead.

## 6. Docstrings

A docstring is a string literal placed immediately after a function definition, before the function body. It documents what the function does, what parameters it expects, and what it returns. Python stores docstrings as part of the function object and exposes them through the `help()` built-in.

### Step 1: Write a Documented Function

```python
def validate_entry(title, content):
    """
    Validate the title and content fields of a journal entry.

    Returns a list of error messages. An empty list means all fields are valid.
    """
    errors = []

    if not title or not title.strip():
        errors.append("Title is required.")
    elif len(title) > 255:
        errors.append("Title must be 255 characters or less.")

    if not content or not content.strip():
        errors.append("Content is required.")

    return errors

result = validate_entry("", "Some content here")
print(result)

help(validate_entry)
```

Output:

```
['Title is required.']
```

The triple-quoted string `"""..."""` immediately after `def validate_entry(...)` is the docstring. Calling `help(validate_entry)` in the terminal prints the docstring along with the function signature.

`not title or not title.strip()` checks two things: whether `title` is falsy (an empty string or `None`), or whether stripping whitespace leaves an empty string. A title of `"   "` (only spaces) passes the first check but fails the `.strip()` check, so it is correctly rejected.

Write docstrings for any function that is longer than a few lines or that will be called from multiple places. It takes seconds to write and saves minutes of confusion later.

## 7. Fix the Errors in Your Code

This section covers the two most common mistakes beginners make when writing functions.

**Error 1: Using a variable before it is assigned inside the function.**

Variables defined inside a function are local to that function. If you reference a name that was not assigned and is not a parameter, Python raises a `NameError`.

```python
# Wrong: tax_rate is not defined inside the function
def calculate_total(price, quantity):
    return price * quantity * (1 + tax_rate)

# Correct: pass it as a parameter
def calculate_total(price, quantity, tax_rate=0.11):
    return price * quantity * (1 + tax_rate)

print(calculate_total(85000, 3))
```

The corrected version makes `tax_rate` a parameter with a default value of `0.11`. This makes the function self-contained: it does not depend on any variable from the outer scope, and callers can override the default if needed.

**Error 2: Forgetting that `return` exits the function immediately.**

Every line after a `return` statement is unreachable. If you have logic that should run before the function exits, it must come before the `return`.

```python
# Wrong: the second return never executes
def check_stock(quantity):
    return "In stock"
    if quantity == 0:
        return "Out of stock"

# Correct: condition check comes before the return
def check_stock(quantity):
    if quantity == 0:
        return "Out of stock"
    return "In stock"

print(check_stock(0))
print(check_stock(10))
```

In the wrong version, `return "In stock"` executes unconditionally on the first line, so the `if` block is never reached. Python does not raise an error for unreachable code; it simply ignores it. The fix is to check the condition first and only fall through to the final `return` if none of the earlier conditions matched.

## 8. Exercises

**Exercise 1:** Write a function called `format_currency(amount, currency="Rp")` that accepts a number and an optional currency prefix, and returns a formatted string like `"Rp 8,500,000"`. Test it with both the default prefix and a custom one like `"USD"`.

**Exercise 2:** Write a function called `summarize(data)` that accepts a list of numbers and returns a dictionary with four keys: `"count"`, `"total"`, `"min"`, and `"max"`. Call the function with `[85000, 150000, 750000, 2800000, 320000]` and print each value in the returned dictionary.

**Exercise 3:** You have a list of products as dictionaries with `"name"` and `"price"` keys. Write a lambda expression used as the `key` argument to `sorted()` to return a new list sorted by product name alphabetically. Print the sorted list.

## 9. Solutions

**Solution for Exercise 1:**

```python
def format_currency(amount, currency="Rp"):
    return f"{currency} {amount:,.0f}"

print(format_currency(8500000))
print(format_currency(150000, "USD"))
```

Output:

```
Rp 8,500,000
USD 150,000
```

`currency="Rp"` makes the prefix optional. When called with only `amount`, the default `"Rp"` is used. The format specifier `,.0f` formats the number with comma separators and no decimal places. This function is a practical utility you could put in a `helpers.py` module and import into any script that needs currency output.

**Solution for Exercise 2:**

```python
def summarize(data):
    return {
        "count": len(data),
        "total": sum(data),
        "min": min(data),
        "max": max(data),
    }

result = summarize([85000, 150000, 750000, 2800000, 320000])

for key, value in result.items():
    print(f"{key}: {value:,}")
```

Output:

```
count: 5
total: 4,105,000
min: 85,000
max: 2,800,000
```

The function returns a dictionary rather than a tuple because a dictionary makes each value's meaning explicit through its key name. Iterating with `.items()` lets you print each key-value pair in a readable format.

**Solution for Exercise 3:**

```python
products = [
    {"name": "Monitor", "price": 2800000},
    {"name": "Laptop", "price": 8500000},
    {"name": "Mouse", "price": 150000},
]

sorted_products = sorted(products, key=lambda p: p["name"])

for product in sorted_products:
    print(f"{product['name']}: Rp {product['price']:,}")
```

Output:

```
Laptop: Rp 8,500,000
Monitor: Rp 2,800,000
Mouse: Rp 150,000
```

`sorted()` returns a new list without modifying the original. The `key=lambda p: p["name"]` argument tells Python to sort by extracting the `"name"` field from each dictionary and comparing those strings alphabetically.

## Next Up - Lesson 9

Functions let you write logic once, give it a meaningful name, and reuse it from anywhere in your program. You now know how to define functions with `def`, accept required and optional parameters, return single or multiple values, write concise one-line lambdas for callbacks, and document functions with docstrings.

In Lesson 9, you will learn how to organize functions across multiple files using modules and how to leverage Python's built-in standard library for common tasks like working with dates, file paths, JSON data, and random values.