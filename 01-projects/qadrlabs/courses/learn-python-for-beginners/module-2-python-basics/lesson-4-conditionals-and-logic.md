Programs that only store data are not very useful on their own. Real programs make decisions: apply a discount if the cart total exceeds a threshold, show an error if a form field is empty, or classify a value differently depending on its range. Python's conditional statements give your code the ability to branch, executing one path or another based on whether a condition is true or false.

## 1. Before You Begin

In Lesson 3, you learned how to store data in variables and distinguish between types: strings, integers, floats, booleans, and None. You also saw that Python evaluates any value as either truthy or falsy. This lesson builds directly on that concept.

Conditional logic is the mechanism that connects stored data to action. Without it, a script can only run the same steps in the same order every time. With it, a script can respond to different inputs, validate data before processing it, and handle edge cases gracefully. In the mini project at the end of this course, you will use conditionals to flag unusual sales values and handle missing data. Everything you learn in this lesson feeds directly into that.

### What You'll Build

You will write a script called `conditionals.py` that takes a sales quantity and unit price as input, applies a discount tier based on the quantity, calculates the final total, and prints a formatted summary. The script uses `if`/`elif`/`else` to select the correct discount and conditional checks to validate the input values.

### What You'll Learn

- ✅ How to write `if`, `elif`, and `else` blocks in Python
- ✅ How comparison operators work: `==`, `!=`, `<`, `>`, `<=`, `>=`
- ✅ How to combine conditions with `and`, `or`, and `not`
- ✅ How Python evaluates truthiness in conditional checks
- ✅ How to write a one-line conditional expression (the ternary form)

### What You'll Need

- Completion of Lesson 3 (variables and data types)
- The `python-basics` folder open in VS Code

## 2. The if / elif / else Structure

A conditional statement lets Python evaluate a condition and execute a block of code only when that condition is true. Python's conditional structure uses three keywords: `if` for the first condition, `elif` for each additional condition to check, and `else` for the fallback when no condition matches.

### Step 1: Write a Basic Grading Check

Create a new file called `conditionals.py` and add the following:

```python
score = 85

if score >= 90:
    grade = "A"
elif score >= 80:
    grade = "B"
elif score >= 70:
    grade = "C"
else:
    grade = "F"

print(f"Score: {score}, Grade: {grade}")
```

Output:

```
Score: 85, Grade: B
```

Python reads the conditions from top to bottom and executes the first block whose condition evaluates to `True`. Because `score` is `85`, the first condition `score >= 90` is `False` and Python skips that block. The second condition `score >= 80` is `True`, so Python executes `grade = "B"` and then skips all remaining `elif` and `else` blocks. Once one condition matches, the rest are ignored.

The colon `:` at the end of each condition line is required. It signals to Python that a block is about to begin. The block itself is defined by indentation: every line indented four spaces beneath the condition belongs to that condition's block. When the indentation returns to the previous level, the block ends.

### Step 2: The else Block

The `else` block runs when none of the `if` or `elif` conditions above it were true. It has no condition of its own. In the grading example, any score below 70 falls through to `else` and receives a grade of `"F"`. An `else` block is optional. If you leave it out and no condition matches, Python simply executes nothing and moves on.

## 3. Comparison and Logical Operators

Conditions are built from expressions that evaluate to `True` or `False`. Python provides two sets of operators for this: comparison operators that compare two values, and logical operators that combine multiple conditions.

### Step 1: Comparison Operators

Add the following to `conditionals.py`:

```python
age = 25
salary = 8000000

print(age == 25)
print(age != 30)
print(salary > 5000000)
print(salary <= 10000000)
```

Output:

```
True
True
True
True
```

`==` checks whether two values are equal. `!=` checks whether they are not equal. `<` and `>` check for less than and greater than. `<=` and `>=` check for less than or equal and greater than or equal. Each of these expressions produces a boolean: either `True` or `False`. That boolean is what the `if` statement evaluates.

One important note for PHP developers: Python only has `==` for equality. There is no `===` (strict equality) because Python's type system handles type differences differently from PHP.

### Step 2: Logical Operators

```python
age = 25
has_id = True
is_member = False

if age >= 18 and has_id:
    print("Access granted")

if age < 18 or not has_id:
    print("Access denied")

if not is_member:
    print("Please register as a member")
```

Output:

```
Access granted
Please register as a member
```

Python uses the English words `and`, `or`, and `not` instead of symbols like `&&`, `||`, and `!`. `and` requires both sides to be truthy for the result to be `True`. `or` requires at least one side to be truthy. `not` inverts the boolean: `not True` becomes `False` and `not False` becomes `True`.

`age >= 18 and has_id` evaluates to `True` only when both `age >= 18` is true and `has_id` is truthy. Since `age` is `25` and `has_id` is `True`, both conditions pass and the block executes.

## 4. Truthiness in Conditions

Python evaluates any value as truthy or falsy when it appears in a conditional context. You do not always need to compare a variable to another value explicitly. You can use the variable itself as the condition.

### Step 1: Checking for Empty Values

```python
name = ""
items = [1, 2, 3]
error_message = None

if name:
    print(f"Hello, {name}")
else:
    print("Name is empty")

if items:
    print(f"Found {len(items)} items")

if not error_message:
    print("No errors")
```

Output:

```
Name is empty
Found 3 items
No errors
```

An empty string `""` is falsy, so `if name` evaluates to `False` and the `else` block runs. A list with items is truthy, so `if items` evaluates to `True`. None is falsy, so `not error_message` evaluates to `True`.

This pattern appears constantly in Python code. Instead of writing `if name != ""` or `if items != []`, you simply write `if name` or `if items`. Python's truthiness rules make these checks concise and readable.

The falsy values in Python are: `False`, `0`, `0.0`, `""`, `[]`, `{}`, and `None`. Every other value is truthy.

## 5. The Conditional Expression

Python also supports a compact, one-line form of the `if`/`else` structure called a conditional expression. It is sometimes called a ternary expression because it involves three parts: a value if true, a condition, and a value if false.

### Step 1: Write a Conditional Expression

```python
age = 20
status = "adult" if age >= 18 else "minor"
print(status)

stock = 0
availability = "In stock" if stock > 0 else "Out of stock"
print(availability)
```

Output:

```
adult
Out of stock
```

The syntax is: `value_if_true if condition else value_if_false`. Python evaluates the condition first. If it is true, the expression returns the value on the left. If it is false, it returns the value on the right. The result is assigned to the variable on the left side of `=`.

Use conditional expressions for simple, single-value assignments. For anything more complex, such as multi-line blocks or nested conditions, use a regular `if`/`else` structure instead. Overusing conditional expressions in complex situations makes code harder to read.

## 6. Practical Example: Discount Tiers

This example brings together everything from this lesson into a realistic scenario. It calculates a final price after applying a discount that depends on quantity, which is a common pattern in sales and e-commerce applications.

### Step 1: Write the Discount Calculator

```python
quantity = int(input("Enter quantity: "))
unit_price = float(input("Enter unit price (Rp): "))

if quantity <= 0:
    print("Error: quantity must be greater than zero.")
elif unit_price <= 0:
    print("Error: unit price must be greater than zero.")
else:
    if quantity >= 100:
        discount_rate = 0.20
        tier = "Gold (20%)"
    elif quantity >= 50:
        discount_rate = 0.10
        tier = "Silver (10%)"
    elif quantity >= 10:
        discount_rate = 0.05
        tier = "Bronze (5%)"
    else:
        discount_rate = 0.0
        tier = "None"

    subtotal = quantity * unit_price
    discount_amount = subtotal * discount_rate
    total = subtotal - discount_amount

    print(f"\nDiscount tier:  {tier}")
    print(f"Subtotal:       Rp {subtotal:,.0f}")
    print(f"Discount:       Rp {discount_amount:,.0f}")
    print(f"Total:          Rp {total:,.0f}")
```

The outer `if`/`elif`/`else` block validates the inputs before doing any calculation. If either `quantity` or `unit_price` is zero or negative, the script prints an error and stops. If both values are valid, the inner `if`/`elif`/`else` block selects the correct discount tier based on the quantity. This pattern of validating inputs before processing them is a good habit that prevents incorrect results and confusing errors.

The `\n` at the start of the first print statement adds a blank line before the output section, making the terminal output easier to read.

## 7. Fix the Errors in Your Code

This section covers the two most common mistakes beginners make when writing conditionals in Python.

**Error 1: Using `=` instead of `==` in a condition.**

A single `=` is assignment. A double `==` is comparison. Using `=` inside an `if` condition is a syntax error in Python.

```python
# Wrong: single = is assignment, not comparison
score = 85
if score = 90:
    print("Perfect score")

# Correct: use == to compare two values
if score == 90:
    print("Perfect score")
```

This is one of the most frequent typos for beginners coming from any background. Python raises a `SyntaxError` immediately when it encounters `=` inside a condition, so you will see the error right away rather than getting a silent wrong result.

**Error 2: Forgetting the colon at the end of the condition line.**

The colon is required after every `if`, `elif`, and `else` line. Leaving it out causes a `SyntaxError`.

```python
# Wrong: missing colon after the condition
if score >= 90
    grade = "A"

# Correct: colon required at the end of every condition line
if score >= 90:
    grade = "A"
```

Python uses the colon to know that a block is beginning. Without it, Python cannot parse the statement and raises a `SyntaxError` pointing to that line. VS Code will underline the error before you even run the script if the Python extension is installed.

## 8. Exercises

**Exercise 1:** Write a script that asks the user to enter a temperature in Celsius. Print `"Freezing"` if it is below 0, `"Cold"` if it is between 0 and 15, `"Comfortable"` if it is between 16 and 25, and `"Hot"` if it is above 25.

**Exercise 2:** Write a script that asks the user for a username and a password. If the username is `"admin"` and the password is `"python123"`, print `"Login successful"`. If the username is correct but the password is wrong, print `"Wrong password"`. If the username is wrong, print `"User not found"`.

**Exercise 3:** Write a script that stores a list of three integers: `[150, 30, 75]`. Loop through the list (you can use `for item in numbers:` which you will learn formally in Lesson 5) and use a conditional expression to print `"High"` if the value is greater than 100 and `"Normal"` otherwise.

## 9. Solutions

**Solution for Exercise 1:**

```python
temperature = float(input("Enter temperature in Celsius: "))

if temperature < 0:
    label = "Freezing"
elif temperature <= 15:
    label = "Cold"
elif temperature <= 25:
    label = "Comfortable"
else:
    label = "Hot"

print(f"{temperature}°C is {label}")
```

The conditions are ordered from lowest to highest so each `elif` only needs to check the upper bound. When the code reaches `elif temperature <= 15`, it already knows the temperature is not below 0 (because that condition was checked first and did not match). Ordering conditions correctly prevents overlapping ranges from causing wrong results.

**Solution for Exercise 2:**

```python
username = input("Enter username: ")
password = input("Enter password: ")

if username != "admin":
    print("User not found")
elif password != "python123":
    print("Wrong password")
else:
    print("Login successful")
```

Checking the username first with `!=` allows the script to give a specific error message for each case. If the username is wrong, there is no point checking the password, so Python skips the remaining conditions. The `else` block only runs when both the username and password are correct.

**Solution for Exercise 3:**

```python
numbers = [150, 30, 75]

for item in numbers:
    label = "High" if item > 100 else "Normal"
    print(f"{item}: {label}")
```

Output:

```
150: High
30: Normal
75: Normal
```

The `for` loop iterates through each item in the list, assigning it to `item` on each pass. The conditional expression on the next line evaluates `item > 100`: if true, it assigns `"High"` to `label`; if false, it assigns `"Normal"`. The f-string then prints both values on one line.

## Next Up - Lesson 5

Conditionals give your code the ability to make decisions based on the value of variables. You can now write `if`/`elif`/`else` blocks, combine multiple conditions with `and`, `or`, and `not`, use Python's truthiness rules to write concise checks, and apply conditional expressions for simple one-line decisions.

In Lesson 5, you will learn how to repeat actions with loops: using `for` to iterate over sequences, `while` to repeat until a condition changes, and `range()`, `enumerate()`, `break`, and `continue` to control exactly how iteration works.