## 1. Before You Begin

In Lesson 1 you learned what machine learning is and the workflow every project follows. Now it is time to set up the place where you will do all your work for the rest of this course: Google Colab. Colab is a free tool that lets you write and run Python in your browser, with every machine learning library already installed. There is nothing to download and nothing to configure on your computer.

By the end of this lesson you will have created your first notebook, run Python code in it, confirmed that the machine learning libraries are ready, loaded a real dataset, and saved your work to Google Drive. This is the foundation for every lesson that follows.

### What You'll Build

A working Colab notebook named `ml-setup` that prints your Python and library versions, imports the core machine learning libraries (NumPy, pandas, matplotlib, seaborn, and scikit-learn), and loads a built-in dataset to prove everything works. You will save this notebook to your Google Drive.

### What You'll Learn

- ✅ What Google Colab is and why it is ideal for learning machine learning
- ✅ How to create, name, and organize a Colab notebook
- ✅ How to write and run code in cells, and why execution order matters
- ✅ How to check your Python and library versions
- ✅ How to import the libraries you will use all course long
- ✅ How to load a built-in dataset and save your notebook to Google Drive

### What You'll Need

- A Google account (the same one you use for Gmail or Drive)
- A web browser, Chrome recommended
- The mental model of machine learning from Lesson 1

---

## 2. What Is Google Colab?

Google Colaboratory, or Colab for short, is a free service that runs Python notebooks in the cloud. A notebook is a document that mixes runnable code, its output, and formatted text in one place. Instead of installing Python and dozens of libraries on your own machine, you open a browser tab and Google gives you a ready-made environment on its servers.

This matters for beginners for a few concrete reasons:

- **No installation headaches.** NumPy, pandas, scikit-learn, matplotlib, and seaborn are already installed. Setup problems are the number one reason beginners quit, and Colab removes them entirely.
- **It runs anywhere.** Your code executes on Google's computers, so even a modest laptop or a Chromebook works fine.
- **Free access to more power.** Colab can give you a GPU for heavier work later, though you will not need one in this course.
- **Everything saves to Drive.** Your notebooks live in your Google Drive, so you never lose your work and can open it from any device.

A notebook is made of cells. A **code cell** holds Python you can run, and its output appears right below it. A **text cell** (also called a markdown cell) holds formatted notes. This combination of live code and explanation is exactly why notebooks are the standard tool for learning and doing machine learning.

---

## 3. Create Your First Notebook

Let us get you into Colab and create the notebook you will use for the rest of this lesson. The steps are quick, and you only need your Google account.

### Step 1: Open Colab

In your browser, go to [https://colab.research.google.com](https://colab.research.google.com). If you are not already signed in, sign in with your Google account. You will land on a welcome screen with a dialog listing recent notebooks.

Colab is a Google product, so your account is all you need. There is no separate sign-up.

### Step 2: Create a new notebook

In the dialog, click **New notebook** in the bottom right. If the dialog is closed, use the menu **File > New notebook**. A fresh notebook opens with a single empty code cell, ready for you to type Python.

This new notebook is automatically saved to a folder called "Colab Notebooks" in your Google Drive.

### Step 3: Rename the notebook

At the top left, the notebook is named something like `Untitled0.ipynb`. Click that name and change it to `ml-setup`. Naming your notebooks clearly is a small habit that saves you a lot of confusion once you have many of them.

You now have an empty, named notebook. Time to run some code.

---

## 4. Run Code in Cells

The heart of working in Colab is writing code in a cell and running it. Let us practice the basic mechanics before we touch any machine learning, because getting comfortable here makes everything later feel easy.

### Step 1: Write and run your first line

Click inside the empty code cell and type:

```python
print("Hello, machine learning!")
```

To run the cell, click the round play button on its left, or press **Shift + Enter**. The output appears directly below the cell:

```
Hello, machine learning!
```

`print()` is the built-in Python function that displays text. `Shift + Enter` runs the current cell and moves focus to the next one, which is the shortcut you will use constantly.

### Step 2: Add another cell

After running a cell with `Shift + Enter`, Colab moves to the next cell, creating one if needed. You can also hover near the bottom of a cell and click **+ Code** to add a code cell, or **+ Text** to add a text cell for notes. Add a new code cell and type:

```python
a = 10
b = 5
print(a + b)
```

Run it and you will see:

```
15
```

Here you store two numbers in the variables `a` and `b`, then print their sum. This is plain Python, exactly what you already know, just running in the cloud.

### Step 3: Understand execution order

This is the one Colab concept that trips up beginners, so read it carefully. Cells do not run on their own. They run only when you run them, and they share the same memory in the order you run them, not the order they appear on the page.

For example, if you define a variable in one cell, run it, then use that variable in another cell, it works. But if you skip running the cell that defines the variable, the later cell fails with a `NameError`. The fix is almost always to run the earlier cell first. When in doubt, use the menu **Runtime > Run all** to run every cell from top to bottom in order.

Keeping your cells runnable from top to bottom is a good habit. It means anyone (including future you) can reopen the notebook and reproduce your results by running all cells.

---

## 5. Check Your Setup

Before you rely on the machine learning libraries, it is worth confirming they are present and seeing their versions. This is also a natural test that your environment is working.

### Step 1: Print your Python and library versions

In a new cell, type the following and run it:

```python
import sys
import numpy as np
import pandas as pd
import sklearn

print("Python version:", sys.version.split()[0])
print("NumPy:", np.__version__)
print("pandas:", pd.__version__)
print("scikit-learn:", sklearn.__version__)
```

Line by line: `import sys` gives access to information about the Python interpreter. The next three lines import the core libraries, giving NumPy the short alias `np` and pandas the short alias `pd`, which are universal conventions you will see everywhere. The `print()` lines then display each version. `sys.version.split()[0]` takes just the version number from the longer Python version string.

The output looks something like this, though your exact version numbers will differ because Colab updates over time:

```
Python version: 3.12.0
NumPy: 2.1.0
pandas: 2.2.0
scikit-learn: 1.5.0
```

If this runs without errors, your environment is ready. The specific numbers do not matter for this course.

### Step 2: Import the rest of the toolkit

Add a new cell with the standard imports you will use throughout the course, and run it:

```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
```

This cell produces no visible output, and that is expected. A successful import is silent. `matplotlib.pyplot` is the plotting module, given the alias `plt`, and `seaborn` is a higher-level plotting library, given the alias `sns`. You will use these two for the visualizations in Module 2.

### Step 3: Load a built-in dataset

Now prove the whole stack works together by loading a real dataset. In a new cell, type:

```python
from sklearn.datasets import load_iris

iris = load_iris(as_frame=True)
df = iris.frame

print(df.shape)
print(df.head())
```

`from sklearn.datasets import load_iris` imports a helper that loads the classic Iris flower dataset, which ships with scikit-learn so there is nothing to download. `load_iris(as_frame=True)` returns the data in a form that includes a pandas DataFrame, and `iris.frame` is that DataFrame, which we store in `df`. `df.shape` reports the number of rows and columns, and `df.head()` shows the first five rows.

Running it gives:

```
(150, 5)
   sepal length (cm)  sepal width (cm)  petal length (cm)  petal width (cm)  target
0                5.1               3.5                1.4               0.2       0
1                4.9               3.0                1.4               0.2       0
2                4.7               3.2                1.4               0.2       0
3                4.6               3.1                1.5               0.2       0
4                5.0               3.6                1.4               0.2       0
```

The `(150, 5)` tells you there are 150 flowers and 5 columns: four measurement features and one `target` column with the species encoded as a number. Seeing this table means NumPy, pandas, and scikit-learn are all working together. You are fully set up.

---

## 6. Save and Manage Your Work

Colab autosaves to Google Drive every few minutes, but it is good to know how saving works so you never lose progress and can find your notebooks later.

### Step 1: Save manually

Press **Ctrl + S** (or **Cmd + S** on a Mac), or use **File > Save**. Your notebook is stored in your Google Drive under a folder named "Colab Notebooks". You can reopen it any time from [drive.google.com](https://drive.google.com) or from the Colab home screen under **File > Open notebook**.

### Step 2: Download a copy (optional)

If you want a local copy of your work, use **File > Download > Download .ipynb** to save the notebook file to your computer, or **File > Download > Download .py** to export just the Python code. You do not need to do this for the course, but it is handy for backups or sharing.

### Step 3: Mount Google Drive for data files (optional, for later)

Later in the course you will sometimes want to read your own data files from Drive. You connect Drive to a notebook with this code:

```python
from google.colab import drive
drive.mount('/content/drive')
```

`from google.colab import drive` imports a helper that only exists inside Colab, and `drive.mount('/content/drive')` connects your Google Drive so its files appear under the `/content/drive` folder. The first time you run it, Colab asks for permission and you click through an authorization prompt. You will not need this until later lessons, so just file it away for now.

---

## 7. Fix the Errors in Your Code

A few mistakes catch almost everyone in their first week with Colab. Here is how to recognize and fix them.

**Mistake 1: Using a variable before running the cell that defines it.**

```python
# Wrong: this cell is run before the cell that defines df, so df does not exist yet
print(df.shape)
# NameError: name 'df' is not defined
```

```python
# Correct: run the cell that defines df first, then run this one
# (or use Runtime > Run all to run every cell top to bottom)
print(df.shape)
```

The error is not in the line itself. It means an earlier cell that creates `df` has not been run in this session. Run the earlier cell, or use **Runtime > Run all**.

**Mistake 2: Forgetting the alias after importing.**

```python
# Wrong: imported pandas as pd, but then call it by its full name
import pandas as pd
data = pandas.DataFrame({"x": [1, 2, 3]})
# NameError: name 'pandas' is not defined
```

```python
# Correct: use the alias you assigned in the import
import pandas as pd
data = pd.DataFrame({"x": [1, 2, 3]})
```

When you write `import pandas as pd`, you must refer to it as `pd` from then on. Pick one style and stay consistent.

**Mistake 3: Expecting output without printing or returning a value.**

```python
# Wrong: assigning to a variable shows nothing
result = 2 + 2
```

```python
# Correct: print it, or put the bare expression on the last line of the cell
result = 2 + 2
print(result)
```

Assigning a value to a variable produces no output. Either call `print()`, or let the last line of the cell be the value itself, which Colab displays automatically.

---

## 8. Exercises

**Exercise 1:** In your `ml-setup` notebook, add a text (markdown) cell at the very top with a heading like `# ML Setup` and a sentence describing what the notebook does. Then run it to see it render as formatted text.

**Exercise 2:** In a new code cell, create a small pandas DataFrame of your own with two columns, `name` and `score`, holding three rows of data. Print it.

**Exercise 3:** Load a different built-in dataset, the California housing dataset, with `from sklearn.datasets import fetch_california_housing`, turn it into a DataFrame, and print its shape and the first five rows.

---

## 9. Solutions

**Solution for Exercise 1:**

Add a text cell (use **+ Text**) and type:

```markdown
# ML Setup

This notebook checks my Python and library versions, imports the core machine learning libraries, and loads a sample dataset to confirm everything works.
```

Text cells use Markdown, where `#` creates a heading. When you run the cell, Colab renders it as formatted text instead of code. This is how you document your notebooks as they grow.

**Solution for Exercise 2:**

```python
import pandas as pd

data = {"name": ["Ana", "Budi", "Cici"], "score": [90, 85, 95]}
df = pd.DataFrame(data)
print(df)
```

Output:

```
   name  score
0   Ana     90
1  Budi     85
2  Cici     95
```

You build a dictionary where each key is a column name and each value is a list of that column's data, then pass it to `pd.DataFrame()`. The leftmost column of numbers is the index, which pandas adds automatically.

**Solution for Exercise 3:**

```python
from sklearn.datasets import fetch_california_housing

housing = fetch_california_housing(as_frame=True)
df = housing.frame

print(df.shape)
print(df.head())
```

`fetch_california_housing(as_frame=True)` loads the dataset and `housing.frame` gives you the DataFrame. This is the dataset you will use to build your first regression model in Module 3, so it is good to meet it early. The shape shows around 20,640 rows and 9 columns. The exact preview values are not important here; what matters is that it loads without error.

---

## Next Up - Lesson 3

You now have a working Colab notebook, you know how to run code in cells and why execution order matters, you have confirmed your libraries are installed, and you have loaded real datasets and saved your work to Drive. Every tool you need for this course is ready in your browser.

In Lesson 3, you will dig into the two libraries at the center of all data work in Python: NumPy for fast numerical arrays and pandas for working with tables of data. These are the tools you will use to load, inspect, and shape every dataset for the rest of the course.
