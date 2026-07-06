Programs make assumptions: the file exists, the user enters a valid number, the network responds. When those assumptions are wrong, Python raises an exception and the program crashes. Error handling is the skill of anticipating those failures and writing code that responds gracefully rather than stopping entirely.

## 1. Before You Begin

In Lesson 11, you read CSV files and processed their contents. The scripts you wrote assumed the file always exists and every field always contains a valid number. In real data work, those assumptions regularly fail. A CSV file might be missing. A cell might contain an empty string or a non-numeric value. A user might type letters where a number was expected.

Without error handling, every one of those situations crashes your script and produces a full Python traceback, which is confusing for users and unhelpful for debugging. With error handling, you can detect the problem, respond to it appropriately, and continue running or exit cleanly.

This lesson also covers the robust `read_sales_data()` function that you will use directly in the mini project in Lesson 13. That function uses nested `try`/`except` blocks to skip bad rows while continuing to process valid ones.

### What You'll Build

You will write a robust data-loading function called `read_sales_data()` that handles missing files, skips malformed rows with a warning message, and returns clean data for processing. You will also write a simple input validation loop that reprompts the user until they enter valid data.

### What You'll Learn

- ✅ How `try`/`except` catches exceptions and prevents crashes
- ✅ How to catch specific exception types by name
- ✅ How `else` and `finally` extend the `try` structure
- ✅ How to raise your own exceptions with `raise`
- ✅ How to handle errors row by row in CSV processing without stopping the whole script

### What You'll Need

- Completion of Lesson 11 (file handling and CSV)
- The `data/sales.csv` file created in Lesson 11

## 2. The try / except Structure

When Python encounters an operation that fails, it raises an exception. An exception is an object that carries information about what went wrong. Without `try`/`except`, the exception propagates up through the call stack and eventually terminates the program. With `try`/`except`, you intercept the exception and run your own response code instead.

### Step 1: Catch a ValueError

Create a new file called `errors_demo.py`:

```python
try:
    number = int(input("Enter a number: "))
    print(f"Double: {number * 2}")
except ValueError:
    print("That is not a valid number. Please enter digits only.")

print("Script continues after the try/except block.")
```

If the user types `"hello"`, `int("hello")` raises a `ValueError`. Without the `try`/`except`, the script would crash there. With it, Python jumps to the `except ValueError:` block, prints the message, and then continues to the next line after the entire `try`/`except` structure. The script does not crash.

`ValueError` is one of Python's built-in exception types. It is raised when a function receives an argument of the correct type but an inappropriate value, such as `int()` receiving a string that cannot be interpreted as an integer.

### Step 2: Catch a FileNotFoundError

```python
try:
    with open("data/missing_file.csv", "r") as f:
        content = f.read()
    print(f"Read {len(content)} characters.")
except FileNotFoundError:
    print("Error: the file does not exist.")
    content = None
```

`FileNotFoundError` is raised when `open()` cannot find the file at the specified path. By catching it, the script can print a clear error message and assign a fallback value to `content` rather than crashing. The variable `content` is available after the `try`/`except` block because `content = None` is executed in the `except` block when the file is not found.

## 3. Catching Multiple Exception Types

A single `try` block can have multiple `except` clauses, each catching a different exception type. Python checks them in order and executes the first one that matches the raised exception.

### Step 1: Handle Different Failures Separately

```python
import csv
import json

data_file = "data/sales.csv"

try:
    with open(data_file, "r") as f:
        content = f.read()
    parsed = json.loads(content)
    value = parsed["total"]
except FileNotFoundError:
    print(f"Error: '{data_file}' was not found.")
except json.JSONDecodeError:
    print("Error: the file content is not valid JSON.")
except KeyError as e:
    print(f"Error: missing expected key {e}.")
```

Each `except` clause catches a specific type of exception. `FileNotFoundError` catches a missing file. `json.JSONDecodeError` catches invalid JSON content. `KeyError` catches a missing dictionary key after parsing. The `as e` syntax captures the exception object in the variable `e`, which you can print to include the specific detail in the error message, such as which key was missing.

Avoid using a bare `except:` with no exception type specified. A bare `except` catches everything, including system signals like `KeyboardInterrupt` (when the user presses `Ctrl + C`) and `SystemExit`. Catching those by accident prevents the user from stopping a misbehaving script and can hide unexpected errors that you should know about.

## 4. else and finally

`try`/`except` can be extended with two additional clauses: `else` and `finally`. They handle two different scenarios: code that should run only on success, and code that should always run regardless of outcome.

### Step 1: Use else for Success Code

```python
try:
    with open("data/sales.csv", "r") as f:
        content = f.read()
except FileNotFoundError:
    print("File not found.")
    content = None
else:
    print(f"File read successfully: {len(content)} characters.")
    print(f"First 50 characters: {content[:50]}")
```

The `else` block executes only when the `try` block completes without raising any exception. Placing success-path code in `else` rather than at the bottom of the `try` block makes the intent clearer: the code in `else` only belongs there if no error occurred. If the file is not found, the `else` block is skipped entirely.

### Step 2: Use finally for Cleanup

```python
connection = None
try:
    connection = open("data/sales.csv", "r")
    data = connection.read()
    print("Data loaded.")
except FileNotFoundError:
    print("File not found.")
finally:
    if connection:
        connection.close()
    print("Cleanup complete. Connection closed.")
```

The `finally` block always executes, whether an exception was raised or not, and whether it was caught or not. It is the right place for cleanup code that must run no matter what: closing a database connection, releasing a lock, or logging that an operation ended. In practice, the `with` statement handles file closing automatically, so `finally` is more commonly used for database connections, network sockets, and other resources that do not have a built-in context manager.

## 5. Raising Your Own Exceptions

Sometimes you want to detect an invalid situation in your own code and signal it to the caller. The `raise` statement lets you throw any exception with a custom message.

### Step 1: Validate Input and Raise

```python
def set_discount_rate(rate):
    """
    Set a discount rate between 0 and 1 (exclusive).
    Raises ValueError if the rate is out of range.
    """
    if not isinstance(rate, (int, float)):
        raise TypeError(f"rate must be a number, got {type(rate).__name__}")
    if rate < 0 or rate >= 1:
        raise ValueError(f"rate must be between 0 and 1, got {rate}")
    return rate

try:
    r = set_discount_rate(1.5)
except ValueError as e:
    print(f"Invalid rate: {e}")
except TypeError as e:
    print(f"Wrong type: {e}")
```

`raise ValueError("message")` creates a `ValueError` exception with the given message and stops execution of the current function. The exception travels up the call stack until it is caught by a `try`/`except` block or reaches the top level and crashes the program.

Raising exceptions in validation functions is better than returning `None` or `False` for invalid input, because the caller is forced to handle the failure explicitly. Returning a sentinel value like `None` is easy to ignore accidentally.

## 6. Practical Error Handling for Data

In data processing scripts, you often cannot stop the entire process when one row has bad data. If a CSV file has 10000 rows and row 47 has an empty price field, you want to skip that row with a warning and continue processing the remaining 9999 rows.

### Step 1: Robust CSV Loading Function

Create a new file called `data_loader.py`:

```python
import csv

def read_sales_data(filepath):
    """
    Read a sales CSV file and return a list of cleaned row dictionaries.

    Skips any row that has missing or invalid quantity or unit_price fields
    and prints a warning for each skipped row. Returns an empty list if
    the file cannot be found.
    """
    try:
        with open(filepath, "r") as f:
            reader = csv.DictReader(f)
            rows = []
            for i, row in enumerate(reader, start=2):
                try:
                    rows.append({
                        "date": row["date"],
                        "product": row["product"],
                        "category": row["category"],
                        "quantity": int(row["quantity"]),
                        "unit_price": int(row["unit_price"]),
                    })
                except (ValueError, KeyError) as e:
                    print(f"Warning: skipping row {i} — {e}")
            return rows
    except FileNotFoundError:
        print(f"Error: file '{filepath}' not found.")
        return []

sales = read_sales_data("data/sales.csv")
print(f"Loaded {len(sales)} valid rows.")
```

The outer `try`/`except FileNotFoundError` handles the case where the file does not exist at all. If the file is missing, the function returns an empty list and the caller can decide what to do next. The inner `try`/`except (ValueError, KeyError)` handles individual row problems: a `ValueError` if a field cannot be converted to `int()`, or a `KeyError` if an expected column name is missing from the row.

`enumerate(reader, start=2)` starts the counter at 2 because row 1 is the header, so the first data row is physically row 2 in the file. This makes the warning messages point to the correct line number when the user opens the file to investigate.

## 7. Fix the Errors in Your Code

This section covers the two most common mistakes beginners make with error handling.

**Error 1: Using a bare `except:` that catches everything.**

A bare `except:` with no exception type catches all exceptions, including ones you did not anticipate and ones the system needs to handle itself.

```python
# Wrong: catches everything including KeyboardInterrupt and SystemExit
try:
    data = int(input("Enter a number: "))
except:
    print("Something went wrong.")

# Correct: catch only the specific exception you expect
try:
    data = int(input("Enter a number: "))
except ValueError:
    print("Please enter a valid integer.")
```

Catching `ValueError` specifically means only the expected failure (non-numeric input) is handled silently. Any other unexpected exception still propagates and shows you a traceback, which is what you want during development. A bare `except` hides bugs by swallowing every error.

**Error 2: Catching an exception but doing nothing with it.**

Catching an exception and silently ignoring it is one of the most dangerous patterns in programming. It hides failures and makes debugging extremely difficult.

```python
# Wrong: exception is caught but completely ignored
try:
    price = int(row["unit_price"])
except ValueError:
    pass

# Correct: at minimum, log the issue or set a meaningful fallback
try:
    price = int(row["unit_price"])
except ValueError:
    print(f"Warning: invalid price value '{row['unit_price']}', using 0.")
    price = 0
```

`pass` in an `except` block swallows the error completely. If `row["unit_price"]` contains `"N/A"` and `int("N/A")` fails, `price` will not be assigned at all, and the next line that uses `price` will raise a `NameError`. At a minimum, log the problem or set a fallback value. Better yet, skip the row entirely as shown in the `read_sales_data()` function in Section 6.

## 8. Exercises

**Exercise 1:** Write a function called `safe_divide(a, b)` that returns `a / b`. If `b` is zero, catch the `ZeroDivisionError` and return `None`. Test it with `safe_divide(10, 2)`, `safe_divide(10, 0)`, and `safe_divide(7, 3)`.

**Exercise 2:** Write a loop that keeps asking the user to enter a positive integer using `input()`. Use `try`/`except ValueError` to catch invalid input and display an error message. Use `try`/`except` with a custom check to reject non-positive numbers. The loop should exit only when a valid positive integer is entered.

**Exercise 3:** Copy the `read_sales_data()` function from Section 6 into a script. Manually edit `data/sales.csv` to add one row with a missing `unit_price` field (leave the field empty). Run the script and confirm that the warning is printed for the bad row but all other rows are loaded successfully.

## 9. Solutions

**Solution for Exercise 1:**

```python
def safe_divide(a, b):
    """
    Divide a by b and return the result.
    Returns None if b is zero.
    """
    try:
        return a / b
    except ZeroDivisionError:
        return None

print(safe_divide(10, 2))
print(safe_divide(10, 0))
print(safe_divide(7, 3))
```

Output:

```
5.0
None
2.3333333333333335
```

`ZeroDivisionError` is raised when any number is divided by zero. Returning `None` signals to the caller that the operation could not be completed, without crashing. The caller can then check `if result is None:` before using the value.

**Solution for Exercise 2:**

```python
while True:
    raw = input("Enter a positive integer: ")
    try:
        value = int(raw)
    except ValueError:
        print(f"'{raw}' is not a valid integer. Try again.")
        continue
    if value <= 0:
        print(f"{value} is not positive. Try again.")
        continue
    print(f"Valid input received: {value}")
    break
```

The `try`/`except ValueError` block catches non-numeric input. The explicit `if value <= 0` check catches negative numbers and zero after a successful conversion. Both failures use `continue` to restart the loop without breaking out. The loop exits only when both conditions are satisfied: the input is a valid integer and it is greater than zero.

**Solution for Exercise 3:**

Add a row like `2025-06-01,Broken Row,Electronics,2,` to `data/sales.csv` (note the empty last field). The expected output when running the `read_sales_data()` function is:

```
Warning: skipping row 12 — invalid literal for int() with base 10: ''
Loaded 10 valid rows.
```

`int("")` raises a `ValueError` because an empty string cannot be converted to an integer. The inner `except (ValueError, KeyError)` block catches this, prints the warning with the row number, and continues to the next row. The outer function returns only the 10 valid rows.

## Next Up - Lesson 13

Robust code anticipates failure. You now know how to catch specific exceptions with `try`/`except`, handle different failure types with multiple `except` clauses, run success-only code in `else`, guarantee cleanup code in `finally`, raise your own exceptions when input is invalid, and write data processing functions that skip bad rows rather than crashing. These skills make the difference between a fragile script and a reliable one.

In Lesson 13, you will assemble everything from this course into the mini project: a complete data analysis script that reads `sales.csv`, calculates summaries, and produces a chart using Matplotlib. You will see how every concept from Lessons 1 through 12 contributes to a real, working data analysis program.