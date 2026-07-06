Before you can write Python, you need two things in place: Python itself installed on your machine, and an editor that helps you write and run `.py` files. This lesson walks through both, then puts them to work by running your first real Python script.

## 1. Before You Begin

In Lesson 1, you learned why Python dominates data science: its readable syntax, its massive library ecosystem, and its role in the data pipeline after SQL. Now it is time to move from theory to practice.

This lesson is entirely about environment setup and getting your first script running. No data structures, no functions, no complex logic yet. The goal is simple: by the end of this lesson, you should be able to open a terminal, type a command, and see Python execute a file you wrote. That moment, running your own code successfully for the first time, is the foundation every subsequent lesson builds on.

### What You'll Build

You will write a short Python script called `hello.py` that prints a greeting, stores a name in a variable, and calculates a total price. You will run it from the terminal and see the output printed line by line.

### What You'll Learn

- ✅ How to install Python 3.12 on your machine and verify the installation
- ✅ How to install VS Code and the Python extension
- ✅ The difference between the interactive interpreter and script files
- ✅ How to run a `.py` file from the terminal
- ✅ How Python's syntax differs from PHP if you are coming from a PHP background

### What You'll Need

- A computer running Windows, macOS, or Linux
- Basic terminal skills: opening a terminal, navigating to a folder
- No prior Python experience

## 2. Install Python

Python does not come pre-installed on Windows, so the first step is downloading and installing it from the official website. On macOS and most Linux distributions, Python 3 may already be available, but it is still worth installing the latest stable version to ensure compatibility with everything taught in this course.

### Step 1: Download the Installer

Go to [python.org/downloads](https://python.org/downloads) in your browser. The website automatically detects your operating system and offers you the latest stable release. At the time of writing, that is Python 3.12. Click the download button to get the installer.

### Step 2: Run the Installer

Open the downloaded installer file and follow the prompts. Before clicking Install, look for a checkbox labeled **"Add Python to PATH"** and make sure it is checked.

This checkbox is critical. Adding Python to PATH means your operating system knows where to find the `python` command when you type it in any terminal window. Without this, you would have to specify the full file path to Python every time you run it, which is cumbersome and error-prone.

### Step 3: Verify the Installation

Open a new terminal window and run the following command:

```bash
python --version
```

This command asks Python to report its version number. If the installation succeeded, you will see output similar to this:

```
Python 3.12.3
```

The exact patch number after `3.12` does not matter. What matters is that the command runs without an error. If you see an error like `command not found`, it means Python was not added to PATH. In that case, re-run the installer and ensure the checkbox is checked before proceeding.

## 3. Install VS Code and the Python Extension

VS Code is a free, lightweight code editor made by Microsoft. It has strong Python support through an official extension that adds syntax highlighting, code completion, error detection, and an integrated terminal. You do not have to use VS Code, but it is the editor assumed throughout this course.

### Step 1: Download and Install VS Code

Go to [code.visualstudio.com](https://code.visualstudio.com/) and download the installer for your operating system. Run it and follow the default installation steps. No special configuration is needed during installation.

### Step 2: Install the Python Extension

Once VS Code is open, click the **Extensions** icon in the left sidebar (it looks like four small squares). In the search bar, type `Python` and find the extension published by **Microsoft**. Click Install.

This extension connects VS Code to the Python interpreter you just installed. It enables features like running the current file with a single button click and underlining syntax errors before you even run the code.

## 4. The Python Interpreter

Python gives you two ways to run code: the interactive interpreter and script files. Understanding the difference will save you confusion as the course progresses.

### Step 1: Open the Interpreter

Open a terminal and type `python`, then press Enter. You will see a prompt that looks like this:

```
Python 3.12.3 (...)
>>>
```

The `>>>` prompt means Python is waiting for your input. This is the interactive interpreter. You can type any Python expression and Python will evaluate it immediately.

### Step 2: Try Some Expressions

Type the following lines one at a time, pressing Enter after each one:

```python
>>> 2 + 3
5
>>> "Hello" + " " + "Python"
'Hello Python'
>>> len("Python")
6
>>> exit()
```

Each line is evaluated and the result is printed right below it. `2 + 3` produces `5`. Joining two strings with `+` produces a combined string. `len("Python")` counts the characters in the word and returns `6`. Calling `exit()` closes the interpreter and returns you to the normal terminal prompt.

The interpreter is excellent for quick experiments and testing small ideas. However, anything you write in the interpreter disappears when you close it. For real, reusable programs, you write scripts.

## 5. Your First Script

A script is a plain text file ending in `.py`. Python reads the file from top to bottom and executes each line in order. Scripts are saved, sharable, and repeatable, which is why all real Python work happens in script files rather than the interpreter.

### Step 1: Create a Project Folder

Create a new folder on your computer called `python-basics`. Open VS Code, go to **File > Open Folder**, and select that folder. This keeps all your course files organized in one place.

### Step 2: Create hello.py

Inside VS Code, create a new file and name it `hello.py`. Type the following code exactly as shown:

```python
print("Hello, Python!")

name = "Budi"
print(f"Welcome, {name}!")

price = 85000
quantity = 3
total = price * quantity
print(f"Total: Rp {total:,}")
```

`print()` is a built-in Python function that outputs text to the terminal. You pass it a value inside the parentheses and it displays that value. The `f` in front of the opening quote marks this as an f-string, which is Python's modern way of embedding variables inside text: anything inside `{}` is evaluated as Python code and its result is inserted into the string. The `:,` inside `{total:,}` is a formatting instruction that tells Python to display the number with comma separators, so `255000` becomes `255,000`.

Unlike PHP, Python variables do not need a `$` prefix. Unlike JavaScript, Python does not require `var`, `let`, or `const`. You simply write the variable name, an equals sign, and the value.

### Step 3: Run the Script

Open the integrated terminal in VS Code (go to **Terminal > New Terminal**). Make sure you are inside the `python-basics` folder, then run:

```bash
python hello.py
```

This tells the `python` program to read and execute `hello.py`. You should see the following output:

```
Hello, Python!
Welcome, Budi!
Total: Rp 255,000
```

If the output matches, your environment is working correctly. Every lesson from here on follows this same pattern: write code in a `.py` file, run it from the terminal, and observe the output.

## 6. Python vs PHP: A Quick Comparison

If you are coming from a PHP background, some of Python's syntax will feel unfamiliar at first. The table below maps the most common patterns so you can orient yourself quickly.

This section is for readers who already know PHP. If PHP is not part of your background, you can skip this section entirely without missing anything important.

| PHP | Python |
|-----|--------|
| `$name = "Budi";` | `name = "Budi"` |
| `echo $name;` | `print(name)` |
| `if ($x > 0) { ... }` | `if x > 0:` followed by indented block |
| `foreach ($items as $item)` | `for item in items:` |
| `function greet($name) { }` | `def greet(name):` |
| Semicolons required | No semicolons |
| Curly braces define blocks | Indentation defines blocks |

The most important difference is indentation. In PHP, you use curly braces `{}` to define where a block of code begins and ends. In Python, you use indentation: four spaces at the start of a line tell Python that line belongs to the block above it. This is not optional formatting. Python enforces it as part of the syntax. A missing or inconsistent indent is a syntax error.

## 7. Fix the Errors in Your Code

This section covers the two most common mistakes beginners make when setting up their environment for the first time.

**Error 1: `python` is not recognized as a command.**

This error appears in the terminal when Python was installed but not added to the system PATH. It means the operating system does not know where to find the `python` program.

```
# Wrong: running python before it is on PATH
python hello.py
# 'python' is not recognized as an internal or external command

# Correct: reinstall Python with "Add to PATH" checked
python hello.py
Hello, Python!
```

The fix is to uninstall Python, re-run the installer, and this time check the box labeled "Add Python to PATH" before clicking Install. After reinstalling, open a new terminal window (the old one will not pick up the change) and try the command again.

**Error 2: IndentationError when writing code.**

Python is strict about indentation. Mixing spaces and tabs, or using inconsistent amounts of spaces, causes an `IndentationError` and the script will not run.

```python
# Wrong: inconsistent indentation
if True:
print("hello")

# Correct: four spaces of indentation inside every block
if True:
    print("hello")
```

The line `print("hello")` belongs to the `if` block, so it must be indented. Python expects exactly four spaces for each level of nesting. VS Code automatically inserts four spaces when you press the Tab key inside a Python file, which makes this easier to get right.

## 8. Exercises

These exercises reinforce the setup steps and give you practice writing and running small scripts.

**Exercise 1:** Open a terminal and start the Python interpreter. Calculate `7 * 8`, then calculate `100 / 3`. Note the difference in the results and exit the interpreter.

**Exercise 2:** Create a new file called `profile.py` in your `python-basics` folder. Store your name, your age, and your city in three separate variables. Use f-strings to print a sentence like: `My name is Budi. I am 25 years old. I live in Jakarta.`

**Exercise 3:** Add four lines to `profile.py`. Store a product price in a variable, store a discount rate as a float (for example, `0.10` for 10%), calculate the discounted price, and print it with comma separators using the `:,` format specifier.

## 9. Solutions

**Solution for Exercise 1:**

Start the interpreter by typing `python` in the terminal, then try both calculations:

```python
>>> 7 * 8
56
>>> 100 / 3
33.333333333333336
>>> exit()
```

`7 * 8` returns `56`, a whole number. `100 / 3` returns `33.333...`, a float, because Python's `/` operator always performs true division and returns a decimal result. This is different from PHP where dividing two integers may return an integer. If you want integer division in Python, you use `//` instead.

**Solution for Exercise 2:**

```python
name = "Budi"
age = 25
city = "Jakarta"

print(f"My name is {name}. I am {age} years old. I live in {city}.")
```

Each variable is assigned on its own line without a type keyword and without a `$` prefix. The f-string embeds all three variables into a single sentence. Python evaluates each `{}` expression at runtime and replaces it with the variable's value.

**Solution for Exercise 3:**

```python
name = "Budi"
age = 25
city = "Jakarta"

print(f"My name is {name}. I am {age} years old. I live in {city}.")

price = 500000
discount_rate = 0.10
discounted_price = price - (price * discount_rate)
print(f"Discounted price: Rp {discounted_price:,.0f}")
```

`price * discount_rate` calculates 10% of the price. Subtracting it from `price` gives the final discounted amount. The format specifier `:.0f` tells Python to display the float with zero decimal places, and `,` adds the comma separator. The output will be `Discounted price: Rp 450,000`.

## Next Up - Lesson 3

You now have a working Python environment: Python 3.12 is installed, VS Code is configured, and you have successfully written and executed your first script. You understand the difference between the interactive interpreter for quick experiments and script files for real programs. You also know that Python uses indentation to define code blocks, not curly braces.

In Lesson 3, you will go deeper into how Python stores data: variables, data types, strings, numbers, booleans, type conversion, and f-strings for formatted output.