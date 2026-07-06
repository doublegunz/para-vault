Every program needs to store data. A calculator needs to remember the numbers you entered. A sales script needs to remember product names, prices, and quantities. In Python, you store data in variables, and the language automatically determines what type of data you are storing based on the value you assign.

## 1. Before You Begin

In Lesson 2, you installed Python and ran your first script. You already used a variable without much explanation: `name = "Budi"` and `price = 85000`. This lesson goes deeper into exactly what is happening when you write those lines.

Understanding variables and data types is not optional groundwork. Every single thing you do in Python, from reading a CSV file in Lesson 11 to calculating sales totals in the mini project, relies on storing values in variables and knowing what type those values are. A variable holding the string `"85000"` and a variable holding the integer `85000` look similar but behave completely differently when you try to do math with them. This lesson teaches you how to tell the difference and how to convert between types when you need to.

### What You'll Build

You will write a script called `variables.py` that stores a product's name, price, tax rate, and quantity in variables, performs a price calculation, and prints a formatted invoice summary to the terminal.

### What You'll Learn

- ✅ How to declare variables without type keywords
- ✅ The four basic Python data types: strings, integers, floats, and booleans
- ✅ How to use f-strings for formatted output
- ✅ How to convert between types with `int()`, `float()`, and `str()`
- ✅ How to get user input with `input()`
- ✅ How `None` works as Python's null value

### What You'll Need

- Python 3.12 installed and working (covered in Lesson 2)
- VS Code open with the `python-basics` folder
- Completion of Lesson 2

## 2. Variables

In Python, you create a variable by writing its name, an equals sign, and the value you want to store. There are no type keywords like `int` or `string`, and no `$` prefix like in PHP. Python reads the value on the right side and automatically determines the type.

### Step 1: Declare Variables

Create a new file called `variables.py` and add the following:

```python
name = "Budi"
age = 25
height = 1.75
is_student = True

print(name, age, height, is_student)
print(type(name))
print(type(age))
print(type(height))
print(type(is_student))
```

Running this script produces:

```
Budi 25 1.75 True
<class 'str'>
<class 'int'>
<class 'float'>
<class 'bool'>
```

`type()` is a built-in Python function that returns the data type of any value. When you pass a variable to it, Python tells you which class that variable belongs to. `str` means string (text), `int` means integer (whole number), `float` means decimal number, and `bool` means boolean (True or False). These are the four basic types you will use in almost every script you write.

Notice that `print(name, age, height, is_student)` prints all four variables on a single line, separated by spaces. When you pass multiple values to `print()` separated by commas, Python automatically inserts a space between each one.

## 3. Strings

A string is any sequence of characters enclosed in single quotes or double quotes. Python treats both the same way. Strings are used to represent text: names, messages, labels, file paths, and anything else that is not a number.

### Step 1: Concatenation and F-strings

Add the following to `variables.py`:

```python
greeting = "Hello"
name = "Budi"

full = greeting + ", " + name + "!"
print(full)

print(f"{greeting}, {name}!")
```

Both `print` statements produce the same output: `Hello, Budi!`. The first approach uses concatenation, joining strings together with the `+` operator. The second approach uses an f-string, which is the modern and recommended way to embed variables inside text. The `f` prefix before the opening quote tells Python this is an f-string. Any expression inside `{}` is evaluated at runtime and its result is inserted into the string at that position.

F-strings are preferred over concatenation because they are easier to read and less error-prone. You do not have to remember to convert numbers to strings before inserting them, which is a common mistake with concatenation.

### Step 2: Multi-line Strings and String Methods

```python
bio = """This is a
multi-line string
in Python."""

print(bio)
print(name.upper())
print(name.lower())
print(len(name))
print("  hello  ".strip())
```

Triple quotes `"""` allow a string to span multiple lines without any special characters. This is useful for storing longer blocks of text.

String methods are functions attached to a string value using dot notation. `.upper()` returns a version of the string with all letters capitalized. `.lower()` returns all lowercase. `len()` is a built-in function (not a method) that returns the number of characters in the string. `.strip()` removes any leading and trailing whitespace from a string, which is particularly useful when cleaning up data read from files or user input.

## 4. Numbers and Math

Python has two numeric types: `int` for whole numbers and `float` for decimal numbers. Python automatically chooses the right type based on the value you assign.

### Step 1: Arithmetic Operators

Add the following to `variables.py`:

```python
price = 85000
tax_rate = 0.11
quantity = 3

subtotal = price * quantity
tax = subtotal * tax_rate
total = subtotal + tax

print(f"Subtotal: Rp {subtotal:,.0f}")
print(f"Tax:      Rp {tax:,.0f}")
print(f"Total:    Rp {total:,.0f}")

print(10 / 3)
print(10 // 3)
print(10 % 3)
print(2 ** 10)
```

Output:

```
Subtotal: Rp 255,000
Tax:      Rp 28,050
Total:    Rp 283,050
3.3333333333333335
3
1
1024
```

The format specifier `,.0f` inside the f-string does two things: the `,` inserts comma separators for thousands (so `255000` becomes `255,000`), and `.0f` rounds the float to zero decimal places. This is the same formatting you will use in the mini project when displaying currency amounts.

The division operators deserve attention. `/` performs true division and always returns a float, even if both numbers divide evenly. `//` is integer division: it divides and discards the decimal part, returning a whole number. `%` is the modulo operator: it returns the remainder after division. `**` is the exponentiation operator: `2 ** 10` means 2 raised to the power of 10, which equals 1024.

## 5. Type Conversion

Because Python determines types automatically, you sometimes end up with a type you did not expect. The most common situation is user input: `input()` always returns a string, even if the user types a number. If you try to do math with that string, Python raises a `TypeError`. Type conversion functions let you change a value from one type to another.

### Step 1: Converting Between Types

```python
age_str = "25"
age = int(age_str)
price = float("85000.50")

count = 42
message = "There are " + str(count) + " items."
print(message)

name = input("What is your name? ")
age = int(input("How old are you? "))
print(f"Hello {name}, you are {age} years old.")
```

`int()` converts a value to an integer. `float()` converts to a decimal number. `str()` converts to a string.

When you call `int("25")`, Python reads the string `"25"` and produces the integer `25`. This only works if the string contains a valid number. If you call `int("hello")`, Python raises a `ValueError` because `"hello"` cannot be interpreted as a number. You will learn how to handle that kind of error safely in Lesson 12.

The `input()` function pauses the script and waits for the user to type something and press Enter. Whatever the user types is returned as a string. Wrapping it with `int()` immediately converts it: `int(input("How old are you? "))` reads the input string and converts it to an integer in one step.

## 6. Booleans and None

Booleans represent truth values. Python has exactly two boolean values: `True` and `False`. They appear throughout Python code, especially in conditions and comparisons.

### Step 1: Booleans

```python
is_active = True
is_deleted = False

print(type(is_active))
print(is_active)
print(not is_active)
```

Output:

```
<class 'bool'>
True
False
```

`not` is the logical negation operator. `not True` produces `False`, and `not False` produces `True`. You will see this used frequently in Lesson 4 when writing conditional checks.

### Step 2: None

```python
result = None
print(result is None)
print(result == None)
```

`None` is Python's way of representing the absence of a value. It is equivalent to `null` in PHP or SQL. Use `is None` to check whether a variable is `None`, not `== None`. The `is` operator checks object identity (whether two names refer to the exact same object in memory), which is the correct and reliable way to test for `None`. You will encounter `None` frequently when working with functions that do not explicitly return a value.

### Step 3: Falsy Values

Python evaluates any value as either truthy or falsy when it appears in a conditional check. Knowing which values are falsy saves you from writing unnecessary comparisons.

The following values are all falsy in Python: `False`, `0`, `0.0`, `""` (empty string), `[]` (empty list), `{}` (empty dictionary), and `None`. Every other value is truthy.

```python
name = ""
if name:
    print(f"Hello, {name}")
else:
    print("Name is empty")
```

Output: `Name is empty`

Because `name` is an empty string, which is falsy, the `if` block is skipped and the `else` block runs. This pattern, checking a variable directly in an `if` statement without an explicit comparison, is idiomatic Python. It works because Python automatically evaluates the truthiness of the value.

## 7. Fix the Errors in Your Code

This section covers the two most common mistakes beginners make when working with variables and types.

**Error 1: Using `+` to join a string and a number.**

When you try to concatenate a string and a number with `+`, Python raises a `TypeError` because it cannot add two incompatible types together.

```python
# Wrong: cannot concatenate string and integer
count = 5
print("There are " + count + " items.")

# Correct: convert the number to a string first
print("There are " + str(count) + " items.")

# Better: use an f-string instead
print(f"There are {count} items.")
```

Python's `+` operator means two different things depending on the types involved: it adds numbers and it concatenates strings. When one side is a string and the other is a number, Python does not know which operation you intend, so it raises a `TypeError`. Converting `count` to a string with `str()` resolves the ambiguity. Using an f-string is even cleaner because Python handles the conversion automatically inside `{}`.

**Error 2: Forgetting that `input()` returns a string.**

This mistake causes a `TypeError` when you try to do math with the result of `input()`.

```python
# Wrong: input() returns a string, not a number
quantity = input("Enter quantity: ")
total = 85000 * quantity

# Correct: wrap input() with int() to convert immediately
quantity = int(input("Enter quantity: "))
total = 85000 * quantity
```

Even if the user types `3`, `input()` returns the string `"3"`, not the integer `3`. Multiplying `85000 * "3"` does not give you `255000`. Python has no way to decide whether you meant arithmetic or string repetition, so it raises a `TypeError`. Wrapping `input()` with `int()` converts the string to a number right away before it is assigned to `quantity`.

## 8. Exercises

**Exercise 1:** Declare five variables: a product name (string), a price (float), a quantity (integer), whether the product is in stock (boolean), and a description set to `None`. Print each variable and its type using `type()`.

**Exercise 2:** Write a script that asks the user for two numbers using `input()`, converts them to floats, adds them together, and prints the result formatted to two decimal places.

**Exercise 3:** Create a variable `username` and set it to an empty string. Write an `if` statement that checks whether `username` is truthy and prints `"Welcome back!"` if it is, or `"Please log in."` if it is not. Then change `username` to `"Budi"` and run the script again to see the difference.

## 9. Solutions

**Solution for Exercise 1:**

```python
product_name = "Laptop"
price = 12500000.00
quantity = 3
in_stock = True
description = None

print(product_name, type(product_name))
print(price, type(price))
print(quantity, type(quantity))
print(in_stock, type(in_stock))
print(description, type(description))
```

Each variable holds a value of a different type. `type()` returns the class of the value, not the name of the variable. Notice that `type(None)` returns `<class 'NoneType'>`, which is the special type Python uses to represent the absence of a value.

**Solution for Exercise 2:**

```python
first = float(input("Enter the first number: "))
second = float(input("Enter the second number: "))
result = first + second
print(f"Result: {result:.2f}")
```

Wrapping each `input()` call with `float()` converts the user's text input into a decimal number immediately. The format specifier `:.2f` inside the f-string formats the result to exactly two decimal places. If the user types `3.5` and `1.25`, the output will be `Result: 4.75`.

**Solution for Exercise 3:**

```python
username = ""

if username:
    print("Welcome back!")
else:
    print("Please log in.")
```

With `username = ""`, the output is `Please log in.` because an empty string is falsy. Changing `username = "Budi"` gives output `Welcome back!` because a non-empty string is truthy. This pattern of checking a variable directly in an `if` statement is idiomatic Python and appears frequently in real-world code.

## Next Up - Lesson 4

Variables are the foundation of every Python program. You now know how to store text with strings, whole numbers with integers, decimal values with floats, truth values with booleans, and the absence of a value with None. You can format output cleanly with f-strings, convert between types with `int()`, `float()`, and `str()`, and collect user input with `input()`.

In Lesson 4, you will use these variables to make decisions: writing `if`, `elif`, and `else` blocks that execute different code depending on conditions, and combining conditions with `and`, `or`, and `not`.