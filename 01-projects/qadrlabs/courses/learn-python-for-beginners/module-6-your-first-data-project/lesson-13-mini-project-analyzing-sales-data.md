This is the lesson where everything comes together. Every concept you have learned across the previous 12 lessons has been building toward this moment. Variables store the data, loops process every row, functions organize the logic, the `csv` module reads the file, error handling makes the script robust, and string formatting produces a clean output report. Now you will see all of those pieces in one working program.

## 1. Before You Begin

In Lesson 12, you wrote the `read_sales_data()` function: a robust CSV loader that skips bad rows with a warning instead of crashing. In Lesson 11, you created `data/sales.csv` with 10 rows of product sales. In Lessons 6 and 7, you learned the list and dictionary patterns used to group and aggregate data. In Lesson 8, you learned to organize reusable code into named functions.

This lesson assembles all of that into a complete mini data analysis project. You will write two versions: one using pure Python to show exactly what is happening at each step, and one using Pandas and Matplotlib to show how the same result is achieved in far fewer lines. The Pandas version is your first real taste of the libraries that power professional data science work.

### What You'll Build

You will build a complete script called `analyze.py` that reads `data/sales.csv`, calculates total revenue and transactions, identifies the top-earning product, displays per-category revenue with a text-based bar chart, and saves the results. You will then write `analyze_pandas.py` that performs the same analysis using Pandas, and produces a real bar chart image saved as `data/revenue_chart.png`.

### What You'll Learn

- ✅ How to structure a complete data analysis script into load, process, and output functions
- ✅ How to use `defaultdict` for multi-category aggregation
- ✅ How to sort and display results in descending order
- ✅ How `pd.read_csv()` loads a CSV into a Pandas DataFrame in one line
- ✅ How `groupby().sum()` replicates SQL-style GROUP BY in Pandas
- ✅ How to create and save a bar chart with Matplotlib

### What You'll Need

- Completion of Lesson 12 (error handling)
- `data/sales.csv` created in Lesson 11
- Pandas and Matplotlib installed: run `pip install pandas matplotlib` if not already done

## 2. Version 1: Analysis with Pure Python

In this version, you will implement every step manually using the Python tools you have already learned. This version is longer than the Pandas version, but it shows clearly what each calculation is doing and reinforces all the concepts from earlier lessons.

### Step 1: Set Up the Project Structure

Create a new file called `analyze.py` at the root of your `python-basics` folder. The script will import from the standard library only, with no third-party dependencies.

### Step 2: Write the Data Loading Function

Add the following to `analyze.py`:

```python
import csv
from collections import defaultdict

def load_data(filepath):
    """
    Load sales CSV and return a list of row dictionaries with typed fields.
    Skips malformed rows and prints a warning for each one.
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
        print(f"Error: '{filepath}' not found.")
        return []
```

`load_data()` wraps the CSV-reading logic from Lesson 11 and the error handling from Lesson 12 into a single reusable function. The outer `try`/`except FileNotFoundError` handles a missing file. The inner `try`/`except (ValueError, KeyError)` handles individual rows with missing or non-numeric fields. The function always returns a list, either with data or empty, so the rest of the script never has to check for `None`.

### Step 3: Write the Analysis Function

```python
def analyze(rows):
    """
    Compute summary statistics from a list of sales row dictionaries.
    Returns a results dictionary with totals, category breakdown, and top product.
    """
    total_revenue = 0
    category_revenue = defaultdict(int)
    product_revenue = defaultdict(int)

    for row in rows:
        revenue = row["quantity"] * row["unit_price"]
        total_revenue += revenue
        category_revenue[row["category"]] += revenue
        product_revenue[row["product"]] += revenue

    top_product_name, top_product_revenue = max(
        product_revenue.items(), key=lambda x: x[1]
    )

    return {
        "total_revenue": total_revenue,
        "total_transactions": len(rows),
        "category_revenue": dict(category_revenue),
        "top_product": top_product_name,
        "top_product_revenue": top_product_revenue,
    }
```

The `analyze()` function iterates over `rows` once and accumulates three counters simultaneously: `total_revenue` for the grand total, `category_revenue` for per-category totals, and `product_revenue` for per-product totals. Using `defaultdict(int)` means there is no need to check whether a key exists before adding to it; any unseen key automatically starts at `0`.

`max(product_revenue.items(), key=lambda x: x[1])` finds the key-value tuple with the highest value. The `key=lambda x: x[1]` argument tells `max()` to compare tuples by their second element (the revenue amount), not by their first element (the product name). The result is unpacked into two variables in one line.

### Step 4: Write the Report Display Function

```python
def display_report(results):
    """Print a formatted sales analysis report to the terminal."""
    width = 52
    print("=" * width)
    print(f"{'SALES ANALYSIS REPORT':^{width}}")
    print("=" * width)

    print(f"\nTotal Revenue:       Rp {results['total_revenue']:>12,.0f}")
    print(f"Total Transactions:  {results['total_transactions']:>15}")
    print(f"\nTop Product:         {results['top_product']}")
    print(f"Top Product Revenue: Rp {results['top_product_revenue']:>12,.0f}")

    print(f"\n{'Revenue by Category':}")
    print("-" * width)
    for category, revenue in sorted(
        results["category_revenue"].items(), key=lambda x: -x[1]
    ):
        pct = revenue / results["total_revenue"] * 100
        bar = "█" * int(pct / 2)
        print(f"  {category:<15} Rp {revenue:>10,.0f}  ({pct:4.1f}%) {bar}")
```

`f"{'SALES ANALYSIS REPORT':^{width}}"` centers the title within a field of `width` characters. `sorted(..., key=lambda x: -x[1])` sorts categories by revenue descending. `pct / 2` scales the percentage to a bar length, so 50% produces 25 block characters. `"█" * int(pct / 2)` creates the visual bar by repeating the block character. This approach produces a readable text-based chart that works in any terminal without requiring external libraries.

### Step 5: Connect the Functions and Run

```python
if __name__ == "__main__":
    rows = load_data("data/sales.csv")

    if not rows:
        print("No data loaded. Exiting.")
    else:
        results = analyze(rows)
        display_report(results)
```

`if __name__ == "__main__":` is an important Python convention. When Python runs a file directly (as in `python analyze.py`), the special variable `__name__` is set to `"__main__"`. When the same file is imported as a module by another script, `__name__` is set to the filename. Placing the main execution code inside this block ensures that it only runs when you explicitly execute the file, not when it is imported.

Run the script from the terminal:

```bash
python analyze.py
```

You should see a formatted report with total revenue, top product, and a bar chart by category printed in the terminal.

## 3. Version 2: The Same Analysis with Pandas

Pandas is a third-party library built on top of NumPy that provides a data structure called a DataFrame: a two-dimensional table with labeled columns, similar to a spreadsheet or a SQL query result. A task that takes 40 lines in pure Python typically takes 5 to 10 lines with Pandas.

### Step 1: Create analyze_pandas.py

Create a new file called `analyze_pandas.py` and add the following:

```python
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("data/sales.csv")

df["revenue"] = df["quantity"] * df["unit_price"]
```

`pd.read_csv("data/sales.csv")` reads the entire CSV file and returns a DataFrame in a single line. The DataFrame has one column for each header in the CSV file. Unlike `csv.DictReader`, Pandas automatically infers the data type of each column: `quantity` and `unit_price` are loaded as integers, so you do not need to convert them manually.

`df["revenue"] = df["quantity"] * df["unit_price"]` adds a new column called `"revenue"` to the DataFrame. The multiplication operates on entire columns at once, which is called vectorized operation. Pandas multiplies every `quantity` value by its corresponding `unit_price` value across all 10 rows simultaneously, without any loop.

### Step 2: Print Summary Statistics

```python
print(f"Total Revenue:      Rp {df['revenue'].sum():,.0f}")
print(f"Total Transactions: {len(df)}")
print(f"Average Revenue:    Rp {df['revenue'].mean():,.0f}")
print(f"\nTop Product:")
top_row = df.loc[df['revenue'].idxmax()]
print(f"  {top_row['product']} — Rp {top_row['revenue']:,.0f}")
```

`df["revenue"].sum()` adds all values in the `revenue` column. `df["revenue"].mean()` calculates the average. `df["revenue"].idxmax()` returns the index (row number) of the row with the highest revenue. `df.loc[...]` retrieves that row as a Series, which you then access by column name.

### Step 3: Group by Category and Print

```python
cat_revenue = df.groupby("category")["revenue"].sum().sort_values(ascending=False)

print("\nRevenue by Category:")
for category, revenue in cat_revenue.items():
    print(f"  {category:<15} Rp {revenue:>12,.0f}")
```

`df.groupby("category")["revenue"].sum()` groups the DataFrame by the `"category"` column, selects the `"revenue"` column from each group, and sums the values within each group. The result is a Series where the index is the category name and the value is the total revenue. `.sort_values(ascending=False)` sorts the Series from highest to lowest revenue. This single chained expression replaces the entire `defaultdict` aggregation and sorting logic from the pure Python version.

### Step 4: Create and Save a Bar Chart

```python
fig, ax = plt.subplots(figsize=(8, 5))
cat_revenue.plot(kind="bar", ax=ax, color="steelblue", edgecolor="white")

ax.set_title("Revenue by Category", fontsize=14, fontweight="bold")
ax.set_ylabel("Revenue (Rp)")
ax.set_xlabel("Category")
ax.tick_params(axis="x", rotation=45)

for bar in ax.patches:
    ax.text(
        bar.get_x() + bar.get_width() / 2,
        bar.get_height() + 50000,
        f"Rp {bar.get_height():,.0f}",
        ha="center", va="bottom", fontsize=8,
    )

plt.tight_layout()
plt.savefig("data/revenue_chart.png", dpi=150)
plt.show()
print("Chart saved to data/revenue_chart.png")
```

`plt.subplots(figsize=(8, 5))` creates a figure and an axes object. `cat_revenue.plot(kind="bar", ax=ax)` draws the bar chart using the grouped revenue Series. Each category becomes one bar with its total revenue as the height.

`ax.set_title()`, `ax.set_ylabel()`, and `ax.set_xlabel()` add labels. `ax.tick_params(axis="x", rotation=45)` rotates the x-axis labels 45 degrees so they do not overlap. The `for bar in ax.patches:` loop iterates over every bar in the chart and adds a text label above each one showing the exact revenue value. `plt.tight_layout()` adjusts the spacing so the rotated labels are not cut off. `plt.savefig()` saves the chart as a PNG file and `plt.show()` opens it in a window.

## 4. Comparing the Two Approaches

Having both scripts side by side reveals why Pandas exists and what it does for you.

Looking at the two scripts together makes the tradeoff clear. The pure Python version is longer, but every step is visible and transparent. You can see exactly how each value is calculated. The Pandas version achieves the same result in a fraction of the code because Pandas handles the column type inference, vectorized arithmetic, grouping, and sorting internally.

| Task | Pure Python | Pandas |
|---|---|---|
| Read CSV | `csv.DictReader` + type conversion | `pd.read_csv()` |
| Calculate revenue per row | `int(row["quantity"]) * int(row["unit_price"])` | `df["quantity"] * df["unit_price"]` |
| Group by category | `defaultdict(int)` + loop | `df.groupby("category")["revenue"].sum()` |
| Sort results | `sorted(..., key=lambda x: -x[1])` | `.sort_values(ascending=False)` |
| Create chart | Not available in standard library | `cat_revenue.plot(kind="bar")` |

For a 10-row file, the difference in speed and convenience is not dramatic. For a 100000-row file, Pandas is dramatically faster because its operations run in compiled C code rather than Python loops.

## 5. Fix the Errors in Your Code

This section covers the two most common mistakes when writing data analysis scripts.

**Error 1: Calling analysis functions before checking whether data was loaded.**

If `load_data()` returns an empty list because the file was not found, passing an empty list to `analyze()` causes a `ValueError` inside `max()` because you cannot find the maximum of an empty sequence.

```python
# Wrong: no guard against empty data
rows = load_data("data/sales.csv")
results = analyze(rows)
display_report(results)

# Correct: check whether data was loaded before proceeding
rows = load_data("data/sales.csv")
if not rows:
    print("No data to analyze. Exiting.")
else:
    results = analyze(rows)
    display_report(results)
```

`if not rows:` is True when `rows` is an empty list. The `else` block only runs when at least one row was successfully loaded. This prevents a cascade of confusing errors from an empty dataset.

**Error 2: Forgetting that Pandas columns still need type checking.**

Pandas infers column types when reading CSV, but if a CSV has non-numeric values in a numeric column, Pandas reads the column as strings (object type) and arithmetic on it raises a `TypeError`.

```python
# Wrong: assumes revenue column is already numeric
df["revenue"] = df["quantity"] * df["unit_price"]

# Correct: explicitly convert if needed, using errors='coerce' to handle bad values
df["quantity"] = pd.to_numeric(df["quantity"], errors="coerce").fillna(0).astype(int)
df["unit_price"] = pd.to_numeric(df["unit_price"], errors="coerce").fillna(0).astype(int)
df["revenue"] = df["quantity"] * df["unit_price"]
```

`pd.to_numeric(column, errors="coerce")` converts values to numbers and replaces any invalid values with `NaN` (Not a Number). `.fillna(0)` replaces those `NaN` values with `0`. `.astype(int)` converts the column to integer type. This pattern is the Pandas equivalent of the `try`/`except ValueError` approach used in the pure Python version.

## 6. Exercises

**Exercise 1:** Modify `display_report()` to also print the month with the highest total revenue. The `"date"` field is in `YYYY-MM-DD` format. Extract the `YYYY-MM` prefix from each row's date using string slicing, then aggregate revenue by month.

**Exercise 2:** Add a function called `export_summary(results, filepath)` to `analyze.py` that writes the category revenue data to a CSV file at the given path using `csv.DictWriter`. Each row should have three fields: `category`, `revenue`, and `percentage`.

**Exercise 3:** In `analyze_pandas.py`, add a second chart: a pie chart showing the percentage of total revenue contributed by each category. Save it as `data/revenue_pie.png`.

## 7. Solutions

**Solution for Exercise 1:**

Add to `analyze()`:

```python
month_revenue = defaultdict(int)
for row in rows:
    month = row["date"][:7]
    revenue = row["quantity"] * row["unit_price"]
    month_revenue[month] += revenue

top_month, top_month_revenue = max(month_revenue.items(), key=lambda x: x[1])
```

Then add to `display_report()`:

```python
print(f"\nTop Month:           {results['top_month']}")
print(f"Top Month Revenue:   Rp {results['top_month_revenue']:>10,.0f}")
```

`row["date"][:7]` extracts the first seven characters of the date string, which is the `YYYY-MM` part. For `"2025-01-10"`, this produces `"2025-01"`. The rest of the aggregation follows the same `defaultdict` pattern used for categories.

**Solution for Exercise 2:**

```python
import csv

def export_summary(results, filepath):
    """Write category revenue summary to a CSV file."""
    total = results["total_revenue"]
    rows = []
    for category, revenue in results["category_revenue"].items():
        rows.append({
            "category": category,
            "revenue": revenue,
            "percentage": round(revenue / total * 100, 2),
        })

    with open(filepath, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["category", "revenue", "percentage"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"Summary exported to {filepath}")
```

`round(revenue / total * 100, 2)` computes the percentage and rounds it to two decimal places. `csv.DictWriter` writes each dictionary in `rows` as a CSV row. `newline=""` prevents blank lines between rows on Windows.

**Solution for Exercise 3:**

```python
fig, ax = plt.subplots(figsize=(7, 7))
cat_revenue.plot(kind="pie", ax=ax, autopct="%1.1f%%", startangle=90)
ax.set_title("Revenue Share by Category", fontsize=14, fontweight="bold")
ax.set_ylabel("")
plt.tight_layout()
plt.savefig("data/revenue_pie.png", dpi=150)
plt.show()
print("Pie chart saved to data/revenue_pie.png")
```

`kind="pie"` switches Matplotlib to a pie chart. `autopct="%1.1f%%"` adds percentage labels to each slice formatted to one decimal place. `startangle=90` rotates the chart so the first slice starts at the top. `ax.set_ylabel("")` removes the default y-axis label that Matplotlib adds to pie charts.

## Next Up - Lesson 14

You have built a complete data analysis project from scratch. The pure Python version demonstrated that every concept from the first 12 lessons contributes to a real program. The Pandas version showed that once you understand the foundations, professional data tools collapse dozens of lines into a few expressive operations.

In Lesson 14, you will take stock of everything you have built across the course, see exactly how Python connects to the broader data science ecosystem, and map out the learning path from here into Pandas, NumPy, statistics, and machine learning.