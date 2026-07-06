Real data lives in files. When a company exports sales records from its database, it usually produces a CSV file. When a system generates a log, it writes to a text file. When an API returns data, it often serializes it to JSON. Learning to read and write files is therefore not an optional skill for data work; it is the gateway to working with any real dataset.

## 1. Before You Begin

In Lesson 10, you mastered string manipulation: stripping whitespace, splitting on delimiters, replacing substrings, and formatting output. Those skills are directly applied in this lesson every time you process a cell read from a CSV file. In Lesson 9, you also briefly encountered the `with open(...)` pattern when working with `json.dump()`. This lesson explains that pattern in full detail.

By the end of this lesson, you will be able to read any CSV file, convert its fields to the correct types, aggregate values across rows, and write a processed summary to a new CSV file. This is the exact workflow used in the mini project in Lesson 13, where you will read `sales.csv`, calculate revenue summaries, and export the results.

### What You'll Build

You will create the core data pipeline of the mini project: a CSV file called `data/sales.csv` with ten rows of sales records, a Python script that reads it row by row, calculates total revenue and per-category revenue, and writes a summary CSV file called `data/summary.csv`.

### What You'll Learn

- ✅ How to read and write text files using `open()` and the `with` statement
- ✅ What a context manager is and why it matters for file safety
- ✅ How `csv.DictReader` reads each row as a named dictionary
- ✅ How `csv.DictWriter` writes dictionaries as rows to a CSV file
- ✅ How to load all CSV rows into memory for multi-pass processing

### What You'll Need

- Completion of Lesson 10 (string methods and formatting)
- The `python-basics` folder open in VS Code

## 2. Reading and Writing Text Files

Before working with structured formats like CSV, it is important to understand how Python handles any file. Every file operation in Python uses `open()`, which returns a file object that you read from or write to. The `with` statement manages the file's lifecycle automatically.

### Step 1: Write a Text File

Create a new folder called `data` inside your `python-basics` folder. Then create a new file called `files_demo.py` and add the following:

```python
with open("data/notes.txt", "w") as f:
    f.write("First line\n")
    f.write("Second line\n")
    f.write("Third line\n")

print("File written successfully.")
```

`open("data/notes.txt", "w")` opens the file at the given path in write mode. The `"w"` argument is the mode flag. If the file does not exist, Python creates it. If it already exists, `"w"` overwrites it entirely. The `as f` part assigns the file object to the variable `f`, which you use to write data. `f.write(text)` writes the string to the file. The `\n` at the end of each string is the newline character, which moves to the next line in the file.

The `with` block is a context manager. When Python exits the `with` block, whether normally or because of an error, it automatically calls `f.close()`. This ensures the file is not left open and that all buffered data is actually written to disk. Always use `with` for file operations, never call `open()` without it.

### Step 2: Read a Text File

```python
with open("data/notes.txt", "r") as f:
    content = f.read()
    print(content)

with open("data/notes.txt", "r") as f:
    for line in f:
        print(line.strip())
```

Output:

```
First line
Second line
Third line

First line
Second line
Third line
```

`open(..., "r")` opens the file in read mode. `f.read()` reads the entire file as one long string, including all newline characters. The blank line in the first output block appears because the string already contains `\n` at the end of each line and `print()` adds another.

The second pattern, `for line in f`, reads the file one line at a time without loading the entire file into memory. This is more efficient for large files. `.strip()` removes the `\n` at the end of each line and any surrounding whitespace, which is why the output looks clean.

The three most common file modes are `"r"` for reading, `"w"` for writing (overwriting any existing content), and `"a"` for appending (adding to the end of an existing file without erasing it).

## 3. Reading CSV Files with csv.DictReader

CSV (Comma-Separated Values) is the most widespread format for tabular data. Python's built-in `csv` module handles all the edge cases of the CSV format: quoted fields that contain commas, fields with embedded newlines, and different delimiters.

### Step 1: Create the Sales CSV File

Create `data/sales.csv` with the following content. You can create this file directly in VS Code:

```
date,product,category,quantity,unit_price
2025-01-10,Laptop ProBook 14,Electronics,2,8500000
2025-01-15,Wireless Mouse,Electronics,5,150000
2025-02-05,Novel Bumi Manusia,Books,3,85000
2025-02-14,Kopi Arabika Toraja,Food,10,95000
2025-03-10,Mechanical Keyboard,Electronics,1,750000
2025-03-18,Tas Ransel Urban,Fashion,2,280000
2025-04-02,Monitor 24 inch,Electronics,1,2800000
2025-04-15,Kemeja Batik,Fashion,4,195000
2025-05-01,Teh Hijau Premium,Food,8,45000
2025-05-10,USB-C Hub,Electronics,3,350000
```

The first row is the header row containing the column names. Every subsequent row is one sales transaction. Each field is separated by a comma, and there are no spaces around commas.

### Step 2: Read the CSV with DictReader

Create a new file called `read_csv.py` and add the following:

```python
import csv

with open("data/sales.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(f"{row['date']} | {row['product']} | Qty: {row['quantity']}")
```

Output:

```
2025-01-10 | Laptop ProBook 14 | Qty: 2
2025-01-15 | Wireless Mouse | Qty: 5
2025-02-05 | Novel Bumi Manusia | Qty: 3
...
```

`csv.DictReader(f)` wraps the file object and reads the first row as the header. For every subsequent row, it returns an ordered dictionary where the keys are the column names from the header and the values are the fields from that row. This is much more readable than using `csv.reader`, which returns plain lists and forces you to access fields by index number.

Every value read by `DictReader` is a string, even numeric columns like `quantity` and `unit_price`. You must convert them with `int()` or `float()` before doing arithmetic.

## 4. Processing CSV Data

Reading individual rows is only the beginning. Most data analysis requires loading all rows, then performing calculations across the entire dataset.

### Step 1: Load All Rows and Calculate Revenue

```python
import csv
from collections import defaultdict

with open("data/sales.csv", "r") as f:
    reader = csv.DictReader(f)
    rows = list(reader)

total_revenue = sum(int(r["quantity"]) * int(r["unit_price"]) for r in rows)
print(f"Total Revenue: Rp {total_revenue:,.0f}")
print(f"Total Transactions: {len(rows)}")
```

Output:

```
Total Revenue: Rp 25,255,000
Total Transactions: 10
```

`list(reader)` converts the iterator into a list of dictionaries and loads all rows into memory at once. After the `with` block closes the file, `rows` still holds all the data in memory. This allows you to run multiple calculations over the same data.

`sum(int(r["quantity"]) * int(r["unit_price"]) for r in rows)` is a generator expression that computes the revenue for each row and passes each result to `sum()`. `int(r["quantity"])` converts the string `"2"` to the integer `2` before multiplying.

### Step 2: Revenue Grouped by Category

```python
category_revenue = defaultdict(int)

for row in rows:
    revenue = int(row["quantity"]) * int(row["unit_price"])
    category_revenue[row["category"]] += revenue

for category, revenue in sorted(category_revenue.items(), key=lambda x: -x[1]):
    print(f"  {category:<15} Rp {revenue:>12,.0f}")
```

Output:

```
  Electronics     Rp   22,350,000
  Fashion         Rp    1,340,000
  Food            Rp    1,310,000
  Books           Rp      255,000
```

`defaultdict(int)` is a special dictionary from the `collections` module that automatically creates a default value for any key that does not yet exist. The default for `defaultdict(int)` is `0`. This means `category_revenue["Electronics"] += revenue` works even the first time `"Electronics"` is seen, without needing to check whether the key exists first.

`sorted(category_revenue.items(), key=lambda x: -x[1])` sorts the categories by revenue in descending order. `key=lambda x: -x[1]` extracts the revenue (index 1 of each tuple) and negates it, so that `sorted()` which normally sorts ascending produces descending order instead.

## 5. Writing CSV Files with csv.DictWriter

After processing data, you often need to save the results to a new file for reporting or for use in another tool. `csv.DictWriter` writes a list of dictionaries as CSV rows.

### Step 1: Write a Summary CSV

```python
import csv

summary = [
    {"category": "Electronics", "revenue": 22350000, "units_sold": 12},
    {"category": "Fashion", "revenue": 1340000, "units_sold": 6},
    {"category": "Food", "revenue": 1310000, "units_sold": 18},
    {"category": "Books", "revenue": 255000, "units_sold": 3},
]

with open("data/summary.csv", "w", newline="") as f:
    fieldnames = ["category", "revenue", "units_sold"]
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(summary)

print("Summary written to data/summary.csv")
```

`csv.DictWriter(f, fieldnames=fieldnames)` creates a writer that knows the column names and their order. `fieldnames` must be a list of strings matching the keys in your dictionaries. `writer.writeheader()` writes the header row (the column names) as the first line of the file. `writer.writerows(summary)` writes all dictionaries in the list as consecutive rows.

The `newline=""` argument in `open(..., "w", newline="")` is important on Windows. Without it, the `csv` module's internal newline handling and Python's text-mode file handling interact to produce blank lines between rows. Passing `newline=""` disables Python's automatic newline translation and lets the `csv` module handle line endings correctly on all platforms.

## 6. Fix the Errors in Your Code

This section covers the two most common file handling mistakes beginners make.

**Error 1: Opening a file without the `with` statement.**

Opening a file with a plain `f = open(...)` call and forgetting to call `f.close()` leaves the file handle open. On some systems this prevents other programs from accessing the file, and any data written to the buffer may not be saved to disk.

```python
# Wrong: file is never closed if an error occurs
f = open("data/notes.txt", "w")
f.write("Some data\n")
f.close()

# Correct: with statement closes the file automatically
with open("data/notes.txt", "w") as f:
    f.write("Some data\n")
```

The `with` statement calls `f.close()` when the block exits, even if an exception is raised inside the block. This guarantee of cleanup is the primary reason to always use `with` for file operations.

**Error 2: Forgetting that all CSV values are strings.**

`csv.DictReader` returns every field as a string. If you try to multiply two string values, Python raises a `TypeError` rather than performing arithmetic.

```python
# Wrong: quantity and unit_price are strings from DictReader
for row in rows:
    revenue = row["quantity"] * row["unit_price"]
    print(revenue)

# Correct: convert to int before multiplying
for row in rows:
    revenue = int(row["quantity"]) * int(row["unit_price"])
    print(f"Rp {revenue:,}")
```

`"2" * "8500000"` raises a `TypeError: can't multiply sequence by non-int of type 'str'` because Python interprets `*` on strings as repetition, not multiplication, and even that requires one side to be an integer. Always convert numeric fields from CSV rows with `int()` or `float()` before using them in calculations.

## 7. Exercises

**Exercise 1:** Create a text file called `data/products.txt` with five product names, one per line. Then write a script that reads the file line by line and prints each product with a 1-based number: `1. Laptop`, `2. Mouse`, etc.

**Exercise 2:** Using `data/sales.csv`, write a script that reads all rows and prints only the rows in the `"Electronics"` category, along with the calculated revenue for each row (`quantity × unit_price`).

**Exercise 3:** Write a script that reads `data/sales.csv`, finds the product with the highest total revenue across all its rows, and prints the product name and its total revenue.

## 8. Solutions

**Solution for Exercise 1:**

```python
with open("data/products.txt", "w") as f:
    f.write("Laptop\n")
    f.write("Mouse\n")
    f.write("Keyboard\n")
    f.write("Monitor\n")
    f.write("USB Hub\n")

with open("data/products.txt", "r") as f:
    for i, line in enumerate(f, start=1):
        print(f"{i}. {line.strip()}")
```

`enumerate(f, start=1)` works directly on the file object because files are iterable. Each iteration yields one line. `.strip()` removes the trailing newline character from each line before printing.

**Solution for Exercise 2:**

```python
import csv

with open("data/sales.csv", "r") as f:
    reader = csv.DictReader(f)
    rows = list(reader)

electronics = [r for r in rows if r["category"] == "Electronics"]

print("Electronics sales:")
for row in electronics:
    revenue = int(row["quantity"]) * int(row["unit_price"])
    print(f"  {row['product']:<25} Rp {revenue:>12,.0f}")
```

The list comprehension filters `rows` to keep only dictionaries where the `"category"` field equals `"Electronics"`. The revenue is calculated inside the loop for each filtered row by converting both fields to integers before multiplying.

**Solution for Exercise 3:**

```python
import csv
from collections import defaultdict

with open("data/sales.csv", "r") as f:
    rows = list(csv.DictReader(f))

product_revenue = defaultdict(int)
for row in rows:
    revenue = int(row["quantity"]) * int(row["unit_price"])
    product_revenue[row["product"]] += revenue

top_product, top_revenue = max(product_revenue.items(), key=lambda x: x[1])
print(f"Top product: {top_product}")
print(f"Total revenue: Rp {top_revenue:,}")
```

`defaultdict(int)` accumulates revenue per product across all rows. `max(product_revenue.items(), key=lambda x: x[1])` finds the tuple with the highest value (index 1 of each tuple is the revenue). The result is unpacked into `top_product` and `top_revenue`.

## Next Up - Lesson 12

File handling is the bridge between Python and real-world data. You can now read text files line by line, load CSV files into memory as lists of dictionaries using `csv.DictReader`, aggregate values across rows, group data by category using `defaultdict`, and write processed results to a new CSV file using `csv.DictWriter`.

In Lesson 12, you will learn how to make your file reading and data processing code robust against errors: handling missing files, skipping malformed rows, and using `try`/`except`/`finally` to write scripts that fail gracefully rather than crashing.
