# How to Install Anaconda Navigator and Run Your First Python Program in Jupyter Notebook on Windows

Setting up Python for the first time on Windows can feel surprisingly hostile. You search for a guide, install Python from one site, then read that you also need pip, then a virtual environment, then an editor, and somewhere along the way your terminal says `'python' is not recognized as an internal or external command`. For a beginner who just wants to write a few lines of code, that wall of conflicting instructions is enough to quit before writing a single `print()` statement. Anaconda Navigator removes that friction. It bundles Python, the Conda package manager, hundreds of preinstalled libraries, and a graphical launcher into a single installer, so you can go from a fresh Windows machine to running Python in Jupyter Notebook without ever touching the command line. In this guide you will install Anaconda on Windows, launch Jupyter Notebook from Navigator, and write a small Python program that you can run and verify cell by cell.

## Overview {#overview}

This tutorial is written for absolute beginners, so it assumes no prior Python experience and no existing tools on your machine. You will start by downloading the Anaconda Distribution, install it through the graphical wizard, open Anaconda Navigator, and then use it to launch Jupyter Notebook. Once the notebook is open, you will write four small programs that build on each other, from a simple greeting to a working calculator function. By the end you will understand not just how to run code, but how Jupyter actually executes it behind the scenes.

### What You'll Build

- A working Anaconda installation on Windows, including Python, Conda, and Jupyter Notebook
- A single Jupyter Notebook file (`.ipynb`) containing four runnable Python programs
- A mini calculator function that takes two numbers and an operator and returns a result

### What You'll Learn

- How to download and install Anaconda Distribution on Windows the recommended way
- How to open Anaconda Navigator and launch Jupyter Notebook without using the command line
- How to create, rename, and run cells in a Jupyter Notebook
- How to write basic Python: variables, arithmetic, lists, and functions
- How the Jupyter kernel executes cells and keeps your variables in memory

### What You'll Need

- A computer running Windows 10 or Windows 11 (64-bit)
- About 5 GB of free disk space (3 GB for Anaconda plus room for packages and files)
- A stable internet connection to download the installer
- A screen resolution of at least 1366 x 768
- No prior Python or programming experience required

## Step 1: Download the Anaconda Distribution {#step-1-download-the-anaconda-distribution}

Before installing anything, it helps to know what you are actually downloading. Anaconda Distribution is not just Python; it is a full data science platform that ships Python itself, the Conda package and environment manager, Anaconda Navigator (the graphical launcher you will use), and more than 250 preinstalled packages such as NumPy, pandas, and Matplotlib. Jupyter Notebook and JupyterLab come included as well. This is why beginners are pointed to Anaconda so often: one download gives you everything, with nothing left to wire together by hand.

Open your browser and go to the official download page at [https://www.anaconda.com/download](https://www.anaconda.com/download). The site detects your operating system automatically and offers the Windows installer. Choose the 64-bit Graphical Installer for Windows, which is the right option for virtually every modern PC. The file is a standard `.exe` of roughly 900 MB, so give it a moment to finish downloading.

If the page asks for an email address before downloading, look for the option to skip registration and proceed directly to the download. You do not need an account to install or use Anaconda for personal learning.

## Step 2: Install Anaconda on Windows {#step-2-install-anaconda-on-windows}

With the installer downloaded, the rest is a guided wizard. The defaults are sensible, and there is only one screen where you should pay close attention, which we will flag clearly when we reach it.

Locate the downloaded file, usually named something like `Anaconda3-2025.12-Windows-x86_64.exe`, in your Downloads folder and double-click it to start the installer. When the Welcome screen appears, click **Next**, then click **I Agree** on the License Agreement to continue.

On the "Select Installation Type" screen you will see two options, **Just Me** and **All Users**. Choose **Just Me (recommended)**. This installs Anaconda into your own user folder and does not require administrator privileges, which avoids a whole class of permission errors that beginners commonly hit when they pick All Users. Click **Next**.

The next screen lets you choose the install location. The default path inside your user directory is fine, so unless you have a specific reason to change it, leave it as is and click **Next**.

Now you reach the one screen that matters most, the "Advanced Installation Options". You will see a checkbox labeled **Add Anaconda3 to my PATH environment variable**, and it is unchecked by default. Leave it unchecked. Anaconda's own documentation recommends this, because adding Anaconda to PATH can interfere with other software that expects a different Python. Since you will launch everything through Anaconda Navigator and the Anaconda Prompt, you do not need it on the system PATH. Leave the second checkbox, **Register Anaconda3 as my default Python**, checked as it is. Then click **Install**.

The installation copies thousands of files and typically takes five to ten minutes depending on your disk speed. When the progress bar completes, click **Next**, and on the final screens you can uncheck the boxes offering to open tutorials or sign up, then click **Finish**.

## Step 3: Open Anaconda Navigator {#step-3-open-anaconda-navigator}

Installation done, it is time to meet the tool you will live in as a beginner. Anaconda Navigator is a desktop application that lets you launch data science tools and manage packages and environments through buttons and menus instead of typed commands.

Click the Windows **Start** menu and begin typing `Anaconda Navigator`. When it appears in the results, click it to open. The first launch can take fifteen to thirty seconds because Navigator is initializing, so be patient if the window does not appear instantly.

Once it opens, you land on the **Home** tab. Here you see a grid of tiles, each representing an application you can install or launch, including JupyterLab, Jupyter Notebook, Spyder, and others. Some tiles show a **Launch** button, meaning the app is already installed, while others show an **Install** button. Because Anaconda Distribution ships Jupyter Notebook by default, its tile should already display **Launch**.

You may notice two similar tiles, Jupyter Notebook and JupyterLab. Both let you write and run Python in your browser, and both use the same notebook files. JupyterLab is the newer, more feature-rich interface with a file browser, tabs, and panels arranged like a full IDE. Jupyter Notebook is the classic, simpler single-document view. For your very first program, the classic Jupyter Notebook keeps the screen uncluttered, so that is what we will use here. Everything you learn applies equally to JupyterLab later.

## Step 4: Launch Jupyter Notebook {#step-4-launch-jupyter-notebook}

This is the moment Python comes alive in your browser. Launching from Navigator starts a small local server on your machine and opens its interface in a browser tab.

On the Navigator Home tab, find the **Jupyter Notebook** tile and click its **Launch** button. Two things happen. First, a small black terminal window may appear and stay open in the background; this is the Jupyter server, and you must leave it running while you work. Second, your default web browser opens a new tab showing the Jupyter file browser.

It is worth clearing up a common point of confusion right away. Even though Jupyter runs inside your browser and the address bar shows something like `http://localhost:8888`, nothing is happening on the internet or in the cloud. The word `localhost` means your own computer. Jupyter simply uses the browser as its display surface, while all your code runs locally on your machine.

The file browser shows the contents of your user home folder by default. You can click into any folder here to choose where your new notebook will be saved. For this tutorial you can stay in the home folder or click into your `Documents` folder to keep things tidy.

## Step 5: Create a New Notebook {#step-5-create-a-new-notebook}

With the file browser open, you will now create the actual notebook document where your code lives. A notebook is a single file with an `.ipynb` extension that stores your code, its output, and any notes together.

In the top-right corner of the Jupyter file browser, click the **New** button to open a dropdown menu, then select **Python 3 (ipykernel)**. A new browser tab opens with an empty notebook, and you will see a single empty box called a **cell** with `In [ ]:` to its left.

By default the notebook is named "Untitled", which is easy to lose track of. Click the word **Untitled** at the top of the page, next to the Jupyter logo. A dialog appears asking for a new name. Type `my-first-notebook` and click **Rename**. Your notebook now has a meaningful name and is saved as `my-first-notebook.ipynb`.

Before writing code, it helps to know that cells come in two main types. A **Code cell** holds Python that Jupyter will execute, and this is the default type. A **Markdown cell** holds formatted text, headings, and notes, which is useful for documenting what your code does. You can switch a cell's type using the dropdown in the toolbar, which usually reads "Code". For now, leave your cells as Code cells.

## Step 6: Write Your First Python Program {#step-6-write-your-first-python-program}

Now for the part you came for. You will write four small programs, each in its own cell, running them one at a time so you can see exactly what each produces. To run any cell, click inside it and press **Shift + Enter**, which executes the cell and moves focus to the next one.

Click inside the first empty cell and type the following:

```python
# The print() function displays whatever you put inside it
print("Hello, World!")
```

The `#` at the start of the first line marks a comment, which Python ignores; comments exist to explain code to humans. The `print()` function takes the text inside the quotes and displays it as output. Press **Shift + Enter** to run the cell, and you will see the result appear directly beneath it:

```
Hello, World!
```

A new empty cell appears below. In this second cell, you will work with variables and arithmetic. A variable is a named container that stores a value so you can reuse it later. Type the following:

```python
# Store values in variables, then do math with them
price = 50000
quantity = 3
total = price * quantity

# Display the result, joining text and a number with a comma
print("Total price:", total)

# Python also supports other operators
print("Addition:", 10 + 5)
print("Subtraction:", 10 - 5)
print("Division:", 10 / 5)
print("Power (10 squared):", 10 ** 2)
```

Here `price`, `quantity`, and `total` are variables. The `*` operator multiplies, and the result is stored in `total`. Notice the last line uses `**`, which is Python's exponent operator, so `10 ** 2` means ten raised to the power of two. Run the cell with **Shift + Enter** to see the output:

```
Total price: 150000
Addition: 15
Subtraction: 5
Division: 2.0
Power (10 squared): 100
```

Notice that division with `/` produces `2.0` rather than `2`. Python treats division as a decimal operation by default, which is why the result includes a decimal point.

In the third cell, you will work with a list. A list is an ordered collection that can hold many values in a single variable. Type the following:

```python
# A list holds multiple values in order, inside square brackets
fruits = ["apple", "banana", "cherry"]

# Access items by their position; counting starts at 0, not 1
print("First fruit:", fruits[0])
print("Second fruit:", fruits[1])

# Add a new item to the end of the list
fruits.append("orange")
print("Updated list:", fruits)

# len() returns how many items the list contains
print("Number of fruits:", len(fruits))
```

The square brackets `[]` create the list, and each item is separated by a comma. To read an item you use its index inside brackets, as in `fruits[0]`. This is the part beginners trip over most: Python counts positions starting from `0`, so the first item is at index `0` and the second at index `1`. The `append()` method adds an item to the end of the list, and `len()` tells you how many items the list now holds. Run the cell to confirm:

```
First fruit: apple
Second fruit: banana
Updated list: ['apple', 'banana', 'cherry', 'orange']
Number of fruits: 4
```

For the final cell, you will combine everything into a small calculator function. A function is a reusable block of code that takes inputs, does something with them, and returns a result. Type the following:

```python
# Define a function named calculate with three inputs
def calculate(a, b, operator):
    if operator == "+":
        return a + b
    elif operator == "-":
        return a - b
    elif operator == "*":
        return a * b
    elif operator == "/":
        return a / b
    else:
        return "Unknown operator"

# Call the function with different inputs and print each result
print("8 + 4 =", calculate(8, 4, "+"))
print("8 - 4 =", calculate(8, 4, "-"))
print("8 * 4 =", calculate(8, 4, "*"))
print("8 / 4 =", calculate(8, 4, "/"))
print("8 ? 4 =", calculate(8, 4, "?"))
```

The `def` keyword defines a function, here named `calculate`, which accepts three inputs called `a`, `b`, and `operator`. Inside, the `if` and `elif` (short for "else if") checks compare the `operator` against each symbol and `return` the matching calculation. The final `else` catches anything that does not match, so passing an unknown symbol returns a friendly message instead of crashing. Note that the body of the function is indented; in Python, indentation is not decoration, it is how the language knows which lines belong inside the function. Run the cell to see all five calls evaluated:

```
8 + 4 = 12
8 - 4 = 4
8 * 4 = 32
8 / 4 = 2.0
8 ? 4 = Unknown operator
```

You have now written and run a complete, if small, Python program across four cells, ending with a working function that makes decisions based on its input.

## Step 7: Save and Export Your Notebook {#step-7-save-and-export-your-notebook}

Your work so far lives in the browser, so the last practical step is making sure it is safely on disk and knowing how to share it. Jupyter does autosave periodically, but you should not rely on that alone.

To save manually at any time, press **Ctrl + S**, or click the floppy-disk icon in the toolbar. This writes your notebook, including all code and the output beneath each cell, to the `my-first-notebook.ipynb` file in whatever folder you created it.

When you want to hand your work to someone else or keep a copy in another format, use the menu at the top. Click **File**, then **Download as**, and you will see several options. Choosing **Notebook (.ipynb)** gives you the native format that anyone with Jupyter can open and run. Choosing **Python (.py)** strips out the notebook structure and saves just the raw code as a plain script you can run from a terminal. Some installations also offer PDF or HTML export for sharing a read-only copy with people who do not use Jupyter.

The downloaded file lands in your browser's usual download location, while the live `.ipynb` you have been editing stays in the folder you chose back in Step 4. Knowing the difference between the working file and an exported copy saves a lot of "where did my notebook go" confusion later.

## How Jupyter Notebook Works Under the Hood {#how-jupyter-notebook-works-under-the-hood}

Running cells feels almost magical at first, but understanding the mechanism underneath will save you from some genuinely baffling moments. The behavior here is the single most common source of beginner confusion in Jupyter, so it is worth a few minutes.

Behind every notebook runs a **kernel**, which is the actual Python process that executes your code. When you opened the notebook with "Python 3 (ipykernel)", you started a kernel. Each time you run a cell, the code is sent to that kernel, executed, and the output is sent back to your browser. The kernel keeps running in the background between cells, which is what makes the next two points possible.

Because one long-lived kernel runs everything, your variables persist across cells. When you set `total = 150000` in one cell, that value stays in the kernel's memory and is available in every cell you run afterward, even cells above it on the page. The notebook is not a single top-to-bottom script; it is a live session, and each cell adds to or changes the state the kernel is holding.

This leads to the part that trips people up: cells run in the order you execute them, not the order they appear on the page. The number in the brackets, such as `In [3]:`, tells you the order in which cells actually ran. If you run a lower cell, then scroll up and run an earlier one, the earlier one runs *later* and may see variables that did not exist when you first wrote it. When results stop making sense, the cure is to click the **Kernel** menu and choose **Restart & Run All**, which wipes the kernel's memory and runs every cell fresh from top to bottom. If you ever see a cell stuck with `In [*]:`, that asterisk means the kernel is still busy running it.

## Conclusion {#conclusion}

You started with a blank Windows machine and finished with a working Python environment and a notebook full of code you wrote and ran yourself. More importantly, you now understand the tools well enough to keep going on your own. Here are the key takeaways to carry forward:

- **Anaconda is the beginner-friendly bundle.** A single installer gives you Python, the Conda package manager, Anaconda Navigator, and Jupyter, so there is nothing to wire together by hand.
- **Choose "Just Me" and skip adding to PATH.** These two installer choices avoid the permission errors and Python conflicts that derail most first-time setups on Windows.
- **Navigator launches everything without the command line.** You open Jupyter Notebook with a single Launch button, and the same approach works for JupyterLab, Spyder, and other tools later.
- **Cells run in execution order, not page order.** The number in `In [n]:` reflects when a cell actually ran, and when state gets confusing, Restart & Run All gives you a clean slate.
- **The kernel holds your state.** Variables persist across cells because one Python process runs the whole notebook as a live session, which is what makes interactive coding so fast to experiment with.

With this foundation in place, you are ready to install extra libraries through Navigator, explore data with pandas, or move up to JupyterLab whenever you want a more powerful workspace.
