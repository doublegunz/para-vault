## 1. Before You Begin

Your Colab notebook is ready and your libraries are confirmed. Before you can train any model, you need to be comfortable handling data, because machine learning is mostly data work. In practice you will spend far more time loading, inspecting, and shaping data than you will spend training models. The two tools for that job in Python are NumPy and pandas.

This lesson teaches you just enough NumPy and pandas to be productive for the rest of the course. You will create arrays and DataFrames, select and filter data, add new columns, and load data from a CSV file. These are the exact operations you will repeat in every later lesson.

### What You'll Build

A notebook that creates NumPy arrays and a pandas DataFrame of students, then selects columns, filters rows by condition, adds a computed column, summarizes the data, and finally loads a dataset from a CSV file. By the end you will be able to move data around with confidence.

### What You'll Learn

- ✅ What NumPy arrays are and why they are fast
- ✅ How to do vectorized math and aggregations on arrays
- ✅ How to create pandas Series and DataFrames
- ✅ How to select columns and rows with `[]`, `loc`, and `iloc`
- ✅ How to filter rows with conditions and add new columns
- ✅ How to summarize data with `describe()` and load a CSV file

### What You'll Need

- The Colab setup from Lesson 2
- Basic Python: variables, lists, and dictionaries
- A new Colab notebook (name it `numpy-pandas` if you like)

---

## 2. Why NumPy and pandas?

Plain Python lists can hold data, but they are slow for math and awkward for tables. NumPy and pandas exist to fix both problems, and nearly every machine learning library, including scikit-learn, is built on top of them.

- **NumPy** gives you the `ndarray`, a fast array of numbers. Operations apply to the whole array at once, which is both shorter to write and far faster than looping. This is called vectorization.
- **pandas** gives you the `DataFrame`, a table with labeled rows and columns, like a spreadsheet you control with code. It is the standard way to load, clean, and explore datasets.

You will use pandas for almost everything in this course, and NumPy underneath it for numerical work. Understanding both makes the rest of the course much smoother. Start each notebook by importing them with their conventional aliases:

```python
import numpy as np
import pandas as pd
```

`np` and `pd` are universal shortcuts. Everyone uses them, so your code will look familiar to any Python data person.

---

## 3. NumPy Arrays

A NumPy array holds a sequence of values, usually numbers, and lets you compute on all of them at once. Let us create one and see what makes it special.

### Step 1: Create an array

In a new cell, type:

```python
import numpy as np

a = np.array([1, 2, 3, 4, 5])
print(a)
print(type(a))
```

`np.array([...])` turns a Python list into a NumPy array. `print(a)` shows its contents and `type(a)` confirms its type. The output is:

```
[1 2 3 4 5]
<class 'numpy.ndarray'>
```

Notice the array prints without commas, which is how you can tell a NumPy array apart from a regular list at a glance.

### Step 2: Do vectorized math

This is where arrays shine. You can apply math to the entire array in one expression, with no loop:

```python
print(a * 2)
print(a + 10)
```

Output:

```
[ 2  4  6  8 10]
[11 12 13 14 15]
```

`a * 2` multiplies every element by 2, and `a + 10` adds 10 to every element. With a plain Python list, `[1, 2, 3] * 2` would repeat the list instead, so this element-wise behavior is a key reason we use NumPy.

### Step 3: Compute aggregations

Arrays come with fast built-in summaries:

```python
print("mean:", a.mean(), "sum:", a.sum(), "max:", a.max())
```

Output:

```
mean: 3.0 sum: 15 max: 5
```

`a.mean()` returns the average, `a.sum()` the total, and `a.max()` the largest value. These methods are the building blocks of the statistics you will compute on datasets later.

### Step 4: Work in two dimensions

Real datasets are tables, which are two dimensional. A 2D array is an array of rows:

```python
m = np.array([[1, 2, 3], [4, 5, 6]])
print(m)
print("shape:", m.shape)
```

Output:

```
[[1 2 3]
 [4 5 6]]
shape: (2, 3)
```

Each inner list is a row, so this array has 2 rows and 3 columns. `m.shape` reports that as `(2, 3)`. You will see `shape` constantly, because knowing the number of rows and columns is the first thing you check about any dataset.

---

## 4. From Arrays to pandas DataFrames

NumPy arrays are great for pure numbers, but real datasets mix numbers with text and need column names. That is what pandas adds. A pandas DataFrame is a table with labeled columns and an index for the rows.

### Step 1: Create a Series

A Series is a single labeled column. It is the building block of a DataFrame:

```python
import pandas as pd

s = pd.Series([90, 85, 95], index=["Ana", "Budi", "Cici"])
print(s)
```

Output:

```
Ana     90
Budi    85
Cici    95
dtype: int64
```

`pd.Series([...])` makes a one-column structure, and the `index` gives each value a label. `dtype: int64` tells you the values are 64-bit integers. A Series is essentially one column of a table.

### Step 2: Create a DataFrame

A DataFrame is a full table. The most common way to build one is from a dictionary, where each key is a column name and each value is the list of that column's data:

```python
data = {
    "name": ["Ana", "Budi", "Cici", "Dedi"],
    "age": [23, 35, 29, 42],
    "city": ["Bandung", "Jakarta", "Bandung", "Surabaya"],
    "score": [90, 85, 95, 70],
}
df = pd.DataFrame(data)
print(df)
```

Output:

```
   name  age      city  score
0   Ana   23   Bandung     90
1  Budi   35   Jakarta     85
2  Cici   29   Bandung     95
3  Dedi   42  Surabaya     70
```

`pd.DataFrame(data)` builds the table. The leftmost column of numbers, 0 to 3, is the index that pandas adds automatically to label each row. In a Colab notebook, `df` on its own line renders as a nicely formatted table, but `print(df)` works everywhere.

### Step 3: Inspect the DataFrame

Before working with any table, you check its size and columns:

```python
print(df.shape)
print(df.columns.tolist())
```

Output:

```
(4, 4)
['name', 'age', 'city', 'score']
```

`df.shape` reports 4 rows and 4 columns. `df.columns.tolist()` lists the column names. On a real dataset you would also call `df.head()` to peek at the first five rows and `df.info()` to see column types and missing values, which you will use heavily in the next lesson.

---

## 5. Selecting Columns and Rows

Once you have a DataFrame, you constantly need to pull out specific columns or rows. pandas gives you a few clear tools for this.

### Step 1: Select columns

Use square brackets with a column name to get one column as a Series, or a list of names to get several columns as a smaller DataFrame:

```python
print(df["name"])
print(df[["name", "score"]])
```

The first prints one column:

```
0     Ana
1    Budi
2    Cici
3    Dedi
Name: name, dtype: str
```

The second prints two columns:

```
   name  score
0   Ana     90
1  Budi     85
2  Cici     95
3  Dedi     70
```

`df["name"]` returns a single column (a Series). `df[["name", "score"]]` uses a list inside the brackets and returns a DataFrame with just those columns. A small note on the `dtype: str` line: pandas 3.0 labels text columns `str`, while older versions you might see in Colab label them `object`. They mean the same thing.

### Step 2: Select rows with loc and iloc

To select rows, pandas gives you two tools. `loc` selects by label and `iloc` selects by integer position:

```python
print(df.loc[0])
print(df.iloc[0:2])
```

`df.loc[0]` returns the row with index label 0, shown as a vertical Series:

```
name         Ana
age           23
city     Bandung
score         90
Name: 0, dtype: object
```

`df.iloc[0:2]` returns the first two rows by position:

```
   name  age     city  score
0   Ana   23  Bandung     90
1  Budi   35  Jakarta     85
```

The difference matters: `loc` works with the labels in the index, while `iloc` works with positions counting from 0. Here they happen to look similar because the index is just 0, 1, 2, 3, but on real data the index can be dates or IDs, and the distinction becomes important.

---

## 6. Filtering Rows with Conditions

The most common data task is keeping only the rows that meet some condition, like all students who scored 90 or higher. pandas does this with boolean filtering.

### Step 1: Filter by a single condition

Put a condition inside the brackets, and pandas keeps only the rows where it is true:

```python
print(df[df["score"] >= 90])
```

Output:

```
   name  age     city  score
0   Ana   23  Bandung     90
2  Cici   29  Bandung     95
```

`df["score"] >= 90` produces a column of True/False values, one per row. Wrapping it in `df[...]` keeps only the rows where the value is True. Notice the index keeps the original labels 0 and 2, so you can tell which original rows survived.

### Step 2: Combine conditions

You can combine conditions with `&` for "and" and `|` for "or". Each condition must be wrapped in parentheses:

```python
print(df[(df["score"] >= 80) & (df["city"] == "Bandung")])
```

Output:

```
   name  age     city  score
0   Ana   23  Bandung     90
2  Cici   29  Bandung     95
```

This keeps rows where the score is at least 80 and the city is Bandung. The parentheses around each condition are required; without them, Python's operator precedence produces an error. This filtering pattern is something you will use in almost every data lesson.

---

## 7. Adding Columns and Summarizing Data

Beyond selecting and filtering, you will often create new columns from existing ones and ask pandas for quick statistics.

### Step 1: Add a computed column

Assigning to a new column name creates it:

```python
df["passed"] = df["score"] >= 80
print(df)
```

Output:

```
   name  age      city  score  passed
0   Ana   23   Bandung     90    True
1  Budi   35   Jakarta     85    True
2  Cici   29   Bandung     95    True
3  Dedi   42  Surabaya     70   False
```

`df["score"] >= 80` computes a True/False value for every row, and assigning it to `df["passed"]` adds that as a new column. Creating features from existing columns like this is the heart of feature engineering, which you will explore in the next course.

### Step 2: Summarize with describe

`describe()` gives you a fast statistical summary of every numeric column:

```python
print(df.describe())
```

Output:

```
            age      score
count   4.00000   4.000000
mean   32.25000  85.000000
std     8.13941  10.801234
min    23.00000  70.000000
25%    27.50000  81.250000
50%    32.00000  87.500000
75%    36.75000  91.250000
max    42.00000  95.000000
```

Each row of this summary is a statistic: `count` is how many values there are, `mean` is the average, `std` is the standard deviation (how spread out the values are), and `min`, `25%`, `50%`, `75%`, `max` describe the distribution. pandas summarizes only the numeric columns and skips text columns like `name` and `city`. This one method gives you an instant feel for any dataset.

---

## 8. Loading Data from a CSV File

So far you typed data by hand, but real datasets come from files, most often CSV files. In Colab you usually upload a file or read one, then load it with `pd.read_csv()`.

### Step 1: Get a CSV into Colab

You have two common options. To upload a file from your computer, run this in a cell and pick the file when prompted:

```python
from google.colab import files
uploaded = files.upload()
```

`files.upload()` is a Colab helper that opens a file picker and stores the chosen file in your notebook's temporary storage. The other option, which needs no upload, is to read a CSV directly from a public web address by passing the URL straight to `pd.read_csv()`.

### Step 2: Read the CSV into a DataFrame

Once the file is available (say it is named `students.csv`), load it:

```python
df = pd.read_csv("students.csv")
print(df)
```

Output:

```
   name  age      city  score
0   Ana   23   Bandung     90
1  Budi   35   Jakarta     85
2  Cici   29   Bandung     95
3  Dedi   42  Surabaya     70
```

`pd.read_csv("students.csv")` reads the file and returns a DataFrame, automatically using the first line as column names. From here, everything you learned in this lesson applies: select, filter, add columns, and summarize. Loading data this way is step one of every real machine learning project.

---

## 9. Fix the Errors in Your Code

These three mistakes are the most common when starting with pandas. Learn to recognize them and they will stop slowing you down.

**Mistake 1: Forgetting parentheses around combined conditions.**

```python
# Wrong: without parentheses, this raises an error
df[df["score"] >= 80 & df["city"] == "Bandung"]
```

```python
# Correct: wrap each condition in parentheses
df[(df["score"] >= 80) & (df["city"] == "Bandung")]
```

The `&` operator binds more tightly than the comparisons, so Python tries to evaluate `80 & df["city"]` first and fails. Parentheses force the comparisons to happen first.

**Mistake 2: Confusing single brackets with double brackets.**

```python
# Wrong: this looks up a column literally named "name, score" and fails
df["name", "score"]
```

```python
# Correct: pass a list of column names with double brackets
df[["name", "score"]]
```

To select multiple columns you pass a list, so you need an inner pair of brackets that builds that list.

**Mistake 3: Mixing up loc and iloc.**

```python
# Wrong: iloc does not accept label-based slicing the way you might expect
df.iloc["Ana"]
```

```python
# Correct: use loc for labels, iloc for integer positions
df.iloc[0]      # first row by position
df.loc[0]       # row with index label 0
```

Remember: `iloc` is for integer positions, `loc` is for labels. Passing a label to `iloc` raises an error.

---

## 10. Exercises

**Exercise 1:** Create a NumPy array of the numbers 10, 20, 30, 40, 50. Print the array multiplied by 3, and print its mean.

**Exercise 2:** Build a DataFrame of three products with columns `product`, `price`, and `stock`. Print the rows where `price` is greater than 100.

**Exercise 3:** Using the same products DataFrame, add a new column `value` equal to `price` times `stock`, then print the full table and its `describe()` summary.

---

## 11. Solutions

**Solution for Exercise 1:**

```python
import numpy as np

nums = np.array([10, 20, 30, 40, 50])
print(nums * 3)
print(nums.mean())
```

Output:

```
[ 30  60  90 120 150]
30.0
```

`nums * 3` multiplies every element by 3 in one vectorized operation, and `nums.mean()` computes the average of all five numbers.

**Solution for Exercise 2:**

```python
import pandas as pd

products = pd.DataFrame({
    "product": ["Pen", "Notebook", "Backpack"],
    "price": [5, 25, 150],
    "stock": [200, 80, 15],
})
print(products[products["price"] > 100])
```

Output:

```
    product  price  stock
2  Backpack    150     15
```

The condition `products["price"] > 100` is True only for the backpack, so the filter keeps just that row, and it keeps its original index label of 2.

**Solution for Exercise 3:**

```python
products["value"] = products["price"] * products["stock"]
print(products)
print(products.describe())
```

Output:

```
    product  price  stock  value
0       Pen      5    200   1000
1  Notebook     25     80   2000
2  Backpack    150     15   2250
            price       stock        value
count    3.000000    3.000000     3.000000
mean    60.000000   98.333333  1750.000000
std     78.581168   93.852722   661.437828
min      5.000000   15.000000  1000.000000
25%     15.000000   47.500000  1500.000000
50%     25.000000   80.000000  2000.000000
75%     87.500000  140.000000  2125.000000
max    150.000000  200.000000  2250.000000
```

Multiplying two columns element by element creates the `value` column. `describe()` then summarizes all three numeric columns, skipping the text `product` column.

---

## Next Up - Lesson 4

You can now create arrays and DataFrames, select and filter data, add columns, summarize tables, and load CSV files. These are the everyday tools of data work, and you will use them in every remaining lesson of this course.

In Lesson 4, you will go from manipulating data to understanding it. You will use pandas together with matplotlib and seaborn to explore a dataset visually: spotting distributions, relationships, and patterns through plots. Exploring data well is what separates people who guess from people who know their data before they model it.
