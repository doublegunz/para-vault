As programs grow, putting all of your code in one file becomes unmanageable. A three-hundred-line script mixing data loading, validation, calculation, and reporting is hard to read, hard to test, and hard to maintain. Modules solve this by letting you split code across separate files and use each file as a named unit. Beyond your own code, Python ships with a standard library of ready-made modules covering everything from file system access to date manipulation to JSON parsing.

## 1. Before You Begin

In Lesson 8, you learned how to define reusable functions. You wrote `greet()`, `validate_entry()`, `analyze_prices()`, and others. Right now, all of those functions live in the same file as the code that calls them. That works for small scripts, but as your project grows, you will want to separate utility functions into their own files so they can be shared across multiple scripts.

This lesson teaches you two skills that work together: how to import code from Python's built-in standard library, and how to create your own modules by splitting functions into separate files. Both skills are used directly in the mini project: the mini project imports `csv` to read data files, `os` to check file paths, and a custom `helpers.py` module for formatting and calculation utilities.

### What You'll Build

You will create a reusable module called `helpers.py` containing several utility functions from Lesson 8. You will then write a main script called `main.py` that imports from `helpers.py`, uses `datetime` to timestamp the report, uses `os` to verify a file path, and uses `json` to save results to a JSON file.

### What You'll Learn

- ✅ How to import a module with `import` and use it with dot notation
- ✅ How to import specific items with `from module import name`
- ✅ How to rename an import with `as` for shorter aliases
- ✅ How to use key standard library modules: `math`, `datetime`, `os`, `json`, `random`
- ✅ How to create your own module and import from it
- ✅ How to install third-party packages with `pip`

### What You'll Need

- Completion of Lesson 8 (functions)
- The `python-basics` folder open in VS Code

## 2. Importing Modules

Python provides three ways to import code from a module. Each has a different tradeoff between explicitness and brevity.

### Step 1: Import an Entire Module

Open a new file called `imports_demo.py` and add the following:

```python
import math

print(math.sqrt(144))
print(math.pi)
print(math.floor(3.9))
print(math.ceil(3.1))
```

Output:

```
12.0
3.141592653589793
3
4
```

`import math` makes the entire `math` module available under the name `math`. You access anything inside it using dot notation: `math.sqrt()`, `math.pi`, `math.floor()`. This approach is explicit: when you see `math.sqrt(144)` later in the code, you know immediately which module it came from.

`math.sqrt(144)` computes the square root and returns a float, so the result is `12.0` rather than `12`. `math.floor()` rounds a float down to the nearest integer and `math.ceil()` rounds it up.

### Step 2: Import Specific Items

```python
from math import sqrt, pi, floor

print(sqrt(144))
print(pi)
print(floor(3.9))
```

`from math import sqrt, pi, floor` imports only the named items from the module and makes them available directly without the `math.` prefix. This is useful when you use a function frequently and do not want to type the module name every time. However, if two modules export a function with the same name, this style can cause a naming conflict where one import silently overwrites the other.

### Step 3: Import with an Alias

```python
import datetime as dt
import math as m

today = dt.date.today()
print(today)
print(m.pi)
```

`import datetime as dt` makes the module available under the alias `dt` instead of `datetime`. This is common for modules with long names. Later in the course, you will see `import pandas as pd` and `import matplotlib.pyplot as plt`, which are the standard aliases used by the data science community. Using the same aliases as the community makes your code immediately recognizable to other Python data practitioners.

## 3. Key Standard Library Modules

Python's standard library is a collection of modules that come bundled with every Python installation. You do not need to install them. They cover common programming tasks so you do not have to write that functionality from scratch.

### Step 1: datetime for Dates and Times

```python
from datetime import datetime, timedelta, date

now = datetime.now()
print(now)
print(now.strftime("%d %B %Y"))
print(now.strftime("%Y-%m-%d %H:%M"))

yesterday = now - timedelta(days=1)
next_week = now + timedelta(weeks=1)
print(yesterday.strftime("%d %B %Y"))
print(next_week.strftime("%d %B %Y"))

birthday = date(1999, 8, 17)
today = date.today()
age_days = (today - birthday).days
print(f"Days since birthday: {age_days:,}")
```

`datetime.now()` returns the current date and time as a `datetime` object. `.strftime()` formats it as a string using format codes: `%d` is the day as a zero-padded two-digit number, `%B` is the full month name, `%Y` is the four-digit year, and `%H:%M` is hours and minutes. `timedelta` represents a duration and can be added to or subtracted from a `datetime` object to calculate past or future dates. Subtracting two `date` objects produces a `timedelta` whose `.days` attribute gives the difference in days.

### Step 2: os for File System Operations

```python
import os

print(os.getcwd())
print(os.listdir("."))

file_path = "data.csv"
if os.path.exists(file_path):
    print(f"File found: {file_path}")
else:
    print(f"File not found: {file_path}")

print(os.path.join("data", "sales", "2026.csv"))
```

`os.getcwd()` returns a string containing the current working directory, which is the folder your script is running from. `os.listdir(".")` returns a list of all files and folders in the current directory. `os.path.exists(path)` checks whether a file or folder exists at the given path and returns `True` or `False`. `os.path.join()` assembles a file path correctly for the current operating system, using backslashes on Windows and forward slashes on macOS and Linux. Using `os.path.join()` instead of string concatenation ensures your paths work correctly on any platform.

### Step 3: json for Reading and Writing JSON

```python
import json

data = {
    "product": "Laptop",
    "price": 8500000,
    "tags": ["electronics", "portable"],
}

json_string = json.dumps(data, indent=2)
print(json_string)

parsed = json.loads(json_string)
print(parsed["product"])

with open("product.json", "w") as f:
    json.dump(data, f, indent=2)

with open("product.json", "r") as f:
    loaded = json.load(f)
    print(loaded)
```

`json.dumps(data, indent=2)` converts a Python dictionary to a JSON-formatted string. The `indent=2` argument adds readable indentation. `json.loads(json_string)` parses a JSON string back into a Python dictionary. `json.dump(data, f)` writes JSON directly to a file object (note the single argument version, without the `s`). `json.load(f)` reads JSON from a file object back into Python. The `with open(...) as f:` pattern is covered in detail in Lesson 11, but for now understand that it opens the file, assigns it to `f`, and closes it automatically when the block ends.

### Step 4: random for Random Values

```python
import random

print(random.randint(1, 100))
print(random.uniform(0.0, 1.0))

items = ["Laptop", "Mouse", "Keyboard", "Monitor"]
print(random.choice(items))

sample = random.sample(items, 2)
print(sample)

random.shuffle(items)
print(items)
```

`random.randint(1, 100)` returns a random integer between 1 and 100 inclusive. `random.uniform(0.0, 1.0)` returns a random float between 0.0 and 1.0. `random.choice(items)` picks one random item from a list. `random.sample(items, 2)` picks 2 unique items without replacement. `random.shuffle(items)` randomizes the order of the list in place. These functions are useful for generating test data and for statistical sampling.

## 4. Creating Your Own Module

Any `.py` file can be used as a module. Python's import system finds files by looking in the same directory as the script that is importing them, so you simply create a file in the same folder and import from it by filename.

### Step 1: Create helpers.py

Create a new file in your `python-basics` folder called `helpers.py` and add the following functions:

```python
def format_currency(amount, currency="Rp"):
    return f"{currency} {amount:,.0f}"

def get_excerpt(text, length=100):
    if len(text) <= length:
        return text
    return text[:length] + "..."

def summarize(data):
    if not data:
        return None
    return {
        "count": len(data),
        "total": sum(data),
        "min": min(data),
        "max": max(data),
        "average": sum(data) / len(data),
    }

def validate_entry(title, content):
    """
    Validate title and content fields.
    Returns a list of error messages. Empty list means valid.
    """
    errors = []
    if not title or not title.strip():
        errors.append("Title is required.")
    elif len(title) > 255:
        errors.append("Title must be 255 characters or less.")
    if not content or not content.strip():
        errors.append("Content is required.")
    return errors
```

This file defines four reusable utility functions. Notice that `helpers.py` contains no code that runs on import, only `def` statements. This is the correct way to write a module: it defines capabilities, and the calling script decides when and how to use them.

### Step 2: Import from helpers.py

Create a new file called `main.py` in the same folder and add the following:

```python
from helpers import format_currency, summarize, validate_entry
from datetime import datetime

prices = [85000, 150000, 750000, 2800000, 320000]
stats = summarize(prices)

print(f"Report generated: {datetime.now().strftime('%d %B %Y %H:%M')}")
print(f"Count:   {stats['count']}")
print(f"Total:   {format_currency(stats['total'])}")
print(f"Average: {format_currency(stats['average'])}")
print(f"Min:     {format_currency(stats['min'])}")
print(f"Max:     {format_currency(stats['max'])}")

errors = validate_entry("", "Some content")
print(f"\nValidation errors: {errors}")
```

`from helpers import format_currency, summarize, validate_entry` makes those three functions available in `main.py` exactly as if they had been defined there. Python looks for `helpers.py` in the same directory as `main.py` and loads it. Any changes you make to `helpers.py` are automatically reflected the next time `main.py` is run.

## 5. Installing Third-Party Packages with pip

Python's standard library covers many common tasks, but the real power of the Python ecosystem comes from the thousands of third-party packages maintained by the community. `pip` is Python's package manager. It downloads packages from the Python Package Index (PyPI) and installs them so they can be imported in any script.

### Step 1: Install a Package

Open your terminal and run the following command:

```bash
pip install pandas matplotlib
```

This command downloads and installs two libraries: Pandas for tabular data analysis and Matplotlib for creating charts. These are the two libraries you will use in Lesson 13 for the mini project.

After installation, you can import them in any script with `import pandas as pd` and `import matplotlib.pyplot as plt`. The `as pd` and `as plt` aliases are conventions used throughout the data science community. You will see these exact lines in virtually every Python data analysis script you encounter.

To see a list of all packages currently installed in your Python environment, run `pip list`. To check the version of a specific package, run `pip show pandas`.

## 6. Fix the Errors in Your Code

This section covers the two most common mistakes beginners make when working with modules and imports.

**Error 1: Importing a module that is not installed.**

Trying to import a third-party package that has not been installed with `pip` raises a `ModuleNotFoundError`.

```python
# Wrong: pandas is not installed yet
import pandas as pd
df = pd.read_csv("data.csv")

# Correct: install the package first, then import
# Run in terminal: pip install pandas
import pandas as pd
df = pd.read_csv("data.csv")
```

The fix is to install the package before importing it. `ModuleNotFoundError: No module named 'pandas'` means exactly what it says: Python cannot find the module because it has not been installed. Run `pip install pandas` in your terminal, then run the script again.

**Error 2: Naming your own file the same as a standard library module.**

If you create a file named `math.py` or `random.py` in your project folder, Python will import your file instead of the standard library module when you write `import math`. This silently breaks any standard library functions you try to use.

```python
# Wrong: you have a file called json.py in your project folder
# This imports YOUR file, not the standard library
import json
json.dumps({"key": "value"})  # AttributeError: module 'json' has no attribute 'dumps'

# Correct: rename your file to something that does not conflict
# Rename json.py to data_utils.py or similar
import json
json.dumps({"key": "value"})  # Works correctly
```

Python's module resolution always checks the current directory before the standard library. Avoid naming your files `os.py`, `math.py`, `random.py`, `csv.py`, `json.py`, or any other name that matches a standard library module. Use descriptive names like `helpers.py`, `data_utils.py`, or `report_tools.py` instead.

## 7. Exercises

**Exercise 1:** Write a script that uses `datetime` to print today's date in the format `"Today is Saturday, 19 April 2026"`. Then calculate and print the number of days until 1 January 2027.

**Exercise 2:** Write a script that uses `os` to list all `.py` files in your `python-basics` folder. Filter the `os.listdir()` result using a list comprehension that keeps only filenames ending in `.py`.

**Exercise 3:** Add a new function to `helpers.py` called `apply_discount(price, rate=0.10)` that returns the discounted price. Then import and use it in `main.py` to apply a 15% discount to the price `8500000` and print the result using `format_currency()`.

## 8. Solutions

**Solution for Exercise 1:**

```python
from datetime import date

today = date.today()
print(f"Today is {today.strftime('%A, %d %B %Y')}")

target = date(2027, 1, 1)
days_remaining = (target - today).days
print(f"Days until 1 January 2027: {days_remaining:,}")
```

`%A` is the full weekday name (Monday, Tuesday, etc.). `%d` is the zero-padded day number. `%B` is the full month name. `%Y` is the four-digit year. Subtracting two `date` objects produces a `timedelta`, and `.days` gives the number of days as an integer.

**Solution for Exercise 2:**

```python
import os

all_files = os.listdir(".")
python_files = [f for f in all_files if f.endswith(".py")]

print("Python files in this folder:")
for i, filename in enumerate(python_files, start=1):
    print(f"  {i}. {filename}")
```

`os.listdir(".")` returns all files and folders in the current directory. The list comprehension filters the results by calling `.endswith(".py")` on each name. `.endswith()` is a string method that returns `True` if the string ends with the specified suffix.

**Solution for Exercise 3:**

Add to `helpers.py`:

```python
def apply_discount(price, rate=0.10):
    """
    Apply a discount to a price and return the discounted amount.
    rate is a decimal (0.10 = 10%). Defaults to 10%.
    """
    discount_amount = price * rate
    return price - discount_amount
```

Then in `main.py`:

```python
from helpers import format_currency, apply_discount

original_price = 8500000
discounted = apply_discount(original_price, rate=0.15)

print(f"Original:   {format_currency(original_price)}")
print(f"Discounted: {format_currency(discounted)}")
```

Output:

```
Original:   Rp 8,500,000
Discounted: Rp 7,225,000
```

`apply_discount(original_price, rate=0.15)` overrides the default 10% rate with 15%. `price * rate` calculates the discount amount and `price - discount_amount` gives the final price. Composing `format_currency(apply_discount(...))` chains the two helper functions together to produce formatted output in one readable line.

## Next Up - Lesson 10

Modules are the organizational layer that makes Python projects scale beyond a single file. You know how to import from the standard library using all three import styles, how to create your own module and import from it, and how to install third-party packages with `pip`. The standard library modules `datetime`, `os`, `json`, and `random` each solve a category of real-world programming tasks you will encounter regularly.

In Lesson 10, you will go deep on string manipulation: the methods for cleaning, splitting, searching, and formatting text that appear constantly in data work. You will also learn the full range of f-string format specifiers for producing polished, aligned output.