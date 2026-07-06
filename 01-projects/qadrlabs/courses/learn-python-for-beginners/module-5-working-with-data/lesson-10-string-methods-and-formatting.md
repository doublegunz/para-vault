In data work, strings are everywhere. Product names, city fields, email addresses, dates stored as text, currency values with inconsistent formatting. Raw data is almost never clean. Before you can calculate anything useful, you have to extract, normalize, and reshape the text your data contains. Python's string methods make this kind of data cleaning concise and readable.

## 1. Before You Begin

In Lesson 9, you learned how to organize code with modules and how to use Python's standard library. You also installed Pandas and Matplotlib in preparation for the mini project. This lesson focuses specifically on strings, the data type you will manipulate most frequently when processing real-world data.

When you read a CSV file in Lesson 11, every cell value arrives as a raw string. A price might be stored as `"Rp 8.500.000"` instead of the integer `8500000`. A name might have extra spaces: `"  budi santoso "`. A date might be `"30-04-2026"` instead of a `date` object. Before any of that data is useful, it needs to be cleaned. The string methods and formatting techniques in this lesson are the tools you will use for that cleaning step in the mini project.

### What You'll Build

You will write a script called `strings.py` that takes a list of raw, messy sales records stored as strings, applies a chain of string methods to clean each record, extracts fields by splitting on delimiters, and prints a formatted report with aligned columns.

### What You'll Learn

- ✅ How to use the most important string methods: `strip()`, `lower()`, `upper()`, `title()`, `replace()`, `split()`, `join()`
- ✅ How to search strings with `startswith()`, `endswith()`, `find()`, and the `in` operator
- ✅ How to use f-string format specifiers for alignment, decimal precision, and percentages
- ✅ How to chain string methods for multi-step data cleaning in one expression

### What You'll Need

- Completion of Lesson 9 (modules and imports)
- The `python-basics` folder open in VS Code

## 2. Core String Methods

String methods are functions attached to a string value using dot notation. They return new strings with the transformation applied. Strings in Python are immutable, so no method modifies the original string. Each call returns a fresh string object, and the original remains unchanged.

### Step 1: Whitespace and Case Methods

Create a new file called `strings.py` and add the following:

```python
raw = "  Hello, World!  "

print(raw.strip())
print(raw.lstrip())
print(raw.rstrip())
print(raw.lower())
print(raw.upper())

name = "budi santoso"
print(name.title())
print(name.capitalize())
```

Output:

```
Hello, World!
Hello, World!  
  Hello, World!
  hello, world!  
  HELLO, WORLD!  
Budi Santoso
Budi santoso
```

`.strip()` removes leading and trailing whitespace from both ends of the string. `.lstrip()` removes whitespace from the left side only and `.rstrip()` from the right side only. These methods are essential for cleaning data read from CSV files, where cells often have invisible trailing spaces.

`.lower()` converts all characters to lowercase. `.upper()` converts all to uppercase. `.title()` capitalizes the first letter of every word, which is useful for normalizing name fields. `.capitalize()` capitalizes only the first letter of the entire string, leaving all others lowercase.

### Step 2: replace() and Chaining Methods

```python
raw_price = "Rp 8.500.000"
cleaned = raw_price.replace("Rp ", "").replace(".", "")
price = int(cleaned)
print(price)

messy = "  BUDI SANTOSO  "
normalized = messy.strip().lower().title()
print(normalized)
```

Output:

```
8500000
Budi Santoso
```

`.replace(old, new)` returns a new string with every occurrence of `old` replaced by `new`. `raw_price.replace("Rp ", "")` removes the `"Rp "` prefix, producing `"8.500.000"`. Chaining `.replace(".", "")` on the result removes all the dots, producing `"8500000"`. Wrapping the result with `int()` converts the cleaned string to an integer.

Method chaining, calling multiple methods one after the other on a single line, works because each method returns a new string. `messy.strip()` returns a stripped string, then `.lower()` is called on that result, then `.title()` on the result of that. The final value assigned to `normalized` is the output of the last method in the chain.

## 3. Splitting and Joining

Two of the most important string methods for structured data are `split()` and `join()`. They are inverses of each other: `split()` breaks a string into a list of parts, and `join()` combines a list of strings into a single string.

### Step 1: split() to Parse Structured Text

```python
csv_line = "Budi,Jakarta,25,active"
parts = csv_line.split(",")
print(parts)
print(parts[0])
print(parts[2])

path = "/home/user/documents/report.csv"
segments = path.split("/")
print(segments)
print(segments[-1])
```

Output:

```
['Budi', 'Jakarta', '25', 'active']
Budi
25
[' ', 'home', 'user', 'documents', 'report.csv']
report.csv
```

`.split(delimiter)` splits the string at every occurrence of the delimiter and returns a list of the resulting parts. The delimiter itself is not included in any of the parts. `csv_line.split(",")` produces a list of four strings. `parts[0]` is `"Budi"` and `parts[2]` is `"25"`. Splitting a file path on `"/"` lets you extract the filename with `segments[-1]`, the last element.

Calling `.split()` without an argument splits on any whitespace (spaces, tabs, newlines) and discards empty strings, which is useful for tokenizing sentences or command-line input.

### Step 2: join() to Reassemble Parts

```python
parts = ["Budi", "Jakarta", "25", "active"]
csv_line = ",".join(parts)
print(csv_line)

words = ["Python", "is", "great"]
sentence = " ".join(words)
print(sentence)

filename_parts = ["2026", "04", "30", "report"]
filename = "_".join(filename_parts) + ".csv"
print(filename)
```

Output:

```
Budi,Jakarta,25,active
Python is great
2026_04_30_report.csv
```

`",".join(parts)` joins every string in the `parts` list, placing `","` between each adjacent pair. The string you call `.join()` on is the separator, not one of the items. Joining with `" "` produces a space-separated sentence. Joining with `"_"` and appending `".csv"` builds a filename from date and label parts. Every element in the list passed to `.join()` must be a string; passing a list that contains integers raises a `TypeError`.

## 4. Searching Strings

Python provides several ways to check whether a string contains a substring, where a substring appears, or how a string begins and ends.

### Step 1: Membership and Position Checks

```python
email = "budi@example.com"

print("@" in email)
print("@" not in email)
print(email.startswith("budi"))
print(email.endswith(".com"))
print(email.find("@"))
print(email.find("xyz"))
```

Output:

```
True
False
True
True
4
-1
```

The `in` operator checks whether a substring exists anywhere in the string and returns `True` or `False`. `"@" in email` is the idiomatic way to test membership. `.startswith(prefix)` returns `True` if the string begins with the given prefix. `.endswith(suffix)` returns `True` if it ends with the given suffix. These are commonly used to filter filenames by extension or classify URLs by protocol.

`.find(substring)` returns the index of the first occurrence of the substring. If the substring is not found, it returns `-1` rather than raising an error. `email.find("@")` returns `4` because the `@` character is at position 4 (counting from 0). This return value of `-1` for not found is important: always check for `-1` before using the result as an index.

## 5. F-string Format Specifiers

F-strings support a rich set of format specifiers that control how values are displayed: width, alignment, decimal precision, number separators, and percentages. These specifiers go inside the `{}` after a colon.

### Step 1: Alignment and Width

```python
products = [
    ("Laptop", 8500000),
    ("Mouse", 150000),
    ("Mechanical Keyboard", 750000),
]

print(f"{'Product':<25} {'Price':>15}")
print("-" * 40)
for name, price in products:
    print(f"{name:<25} {price:>15,.0f}")
```

Output:

```
Product                            Price
----------------------------------------
Laptop                         8,500,000
Mouse                            150,000
Mechanical Keyboard              750,000
```

`:<25` left-aligns the value in a field 25 characters wide, padding with spaces on the right. `:>15` right-aligns the value in a field 15 characters wide, padding with spaces on the left. `,.0f` adds comma separators and formats the number with zero decimal places. Combining alignment and numeric formatting in one specifier produces clean, tabular output without manual string padding.

### Step 2: Decimal Precision and Percentages

```python
rate = 0.1156
pi = 3.141592653589793
score = 0.875

print(f"Rate: {rate:.2%}")
print(f"Rate: {rate:.4f}")
print(f"Pi:   {pi:.3f}")
print(f"Score: {score:.1%}")
```

Output:

```
Rate: 11.56%
Rate: 0.1156
Pi:   3.142
Score: 87.5%
```

`:.2%` multiplies the value by 100 and formats it as a percentage with two decimal places. `:.4f` formats as a fixed-point float with four decimal places. `:.3f` rounds to three decimal places. Python applies standard rounding rules automatically. The `%` format specifier is the cleanest way to display ratios and rates without manually multiplying by 100.

### Step 3: Center Alignment and Fill Characters

```python
title = "Sales Report"
print(f"{title:=^40}")
print(f"{'':=^40}")
print(f"{'Total':>40}")
```

Output:

```
==============Sales Report==============
========================================
                                   Total
```

`:=^40` centers the string in a 40-character field and fills the empty space with `=` characters. The `=` is the fill character, `^` is the alignment direction (center), and `40` is the total width. Changing `^` to `<` left-aligns and `>` right-aligns. Any single character can serve as the fill character. This technique is useful for generating formatted text reports and section headers.

## 6. Practical Data Cleaning

The real value of string methods appears when you combine them to clean messy, real-world data. This section puts all of the methods from this lesson together in a realistic scenario: cleaning raw sales records before processing them.

### Step 1: Clean a List of Raw Records

```python
raw_records = [
    "  Laptop | Rp 8.500.000 | jakarta  ",
    " MOUSE | Rp 150.000 | BANDUNG ",
    "Keyboard  | Rp 750.000  | surabaya",
]

cleaned = []
for record in raw_records:
    parts = record.strip().split("|")
    product = parts[0].strip().title()
    price_str = parts[1].strip().replace("Rp ", "").replace(".", "")
    price = int(price_str)
    city = parts[2].strip().title()
    cleaned.append({"product": product, "price": price, "city": city})

for item in cleaned:
    print(f"{item['product']:<25} Rp {item['price']:>12,}  {item['city']}")
```

Output:

```
Laptop                    Rp    8,500,000  Jakarta
Mouse                     Rp      150,000  Bandung
Keyboard                  Rp      750,000  Surabaya
```

Each raw record is a single string with fields separated by `|`. `.strip()` removes leading and trailing whitespace from the whole record before splitting. `.split("|")` breaks it into three parts. Each part is then `.strip()`-ped individually to remove internal whitespace. The price string is cleaned with two `.replace()` calls before conversion to `int`. `.title()` normalizes the product name and city to proper title case. The final `print` uses alignment specifiers to produce a neatly formatted table.

## 7. Fix the Errors in Your Code

This section covers the two most common string mistakes in data cleaning work.

**Error 1: Splitting without stripping first.**

If a string has leading or trailing whitespace, splitting it before stripping produces parts with embedded spaces that are difficult to work with.

```python
# Wrong: splitting before stripping
line = "  Budi , Jakarta , 25  "
parts = line.split(",")
print(parts)
print(repr(parts[0]))

# Correct: strip the whole string first, then strip each part
parts = [p.strip() for p in line.strip().split(",")]
print(parts)
print(repr(parts[0]))
```

Output:

```
['  Budi ', ' Jakarta ', ' 25  ']
'  Budi '
['Budi', 'Jakarta', '25']
'Budi'
```

Splitting without stripping leaves each part with surrounding whitespace. The correct pattern is to strip the whole line first with `.strip()`, then split it, then strip each resulting part with a list comprehension. `repr()` shows the exact string including whitespace, which makes the difference visible.

**Error 2: Using `.find()` result without checking for -1.**

`.find()` returns `-1` when the substring is not present. Using `-1` as an index returns the last character of the string, which is almost certainly not what you intended.

```python
# Wrong: using find() result as an index without checking -1
text = "hello world"
at_sign_pos = text.find("@")
domain = text[at_sign_pos + 1:]
print(domain)

# Correct: check for -1 before using the result
at_sign_pos = text.find("@")
if at_sign_pos != -1:
    domain = text[at_sign_pos + 1:]
    print(domain)
else:
    print("No @ symbol found in string")
```

When `find("@")` returns `-1`, `text[-1 + 1:]` is `text[0:]`, which returns the entire string. This is a silent bug: no error is raised, but the output is wrong. Checking `!= -1` before using the result prevents this class of mistake.

## 8. Exercises

**Exercise 1:** You have this list of raw names: `["  budi santoso ", "SITI RAHAYU", "andi pratama  ", " DEwI suSAnTI"]`. Write a list comprehension that strips whitespace and converts each name to title case. Print the cleaned list.

**Exercise 2:** You have this string: `"product=Laptop;price=8500000;category=Electronics;in_stock=True"`. Split it on `";"` to get each field, then split each field on `"="` to get the key and value. Build a dictionary from the result and print it.

**Exercise 3:** Write a script that prints a formatted table of this data using f-string alignment specifiers:

```python
data = [
    ("Laptop", 8500000, 0.85),
    ("Mouse", 150000, 0.12),
    ("Monitor", 3200000, 0.56),
]
```

Print a header row and a separator line, then each row with the product name left-aligned in 20 characters, the price right-aligned with comma separator, and the rating formatted as a percentage with one decimal place.

## 9. Solutions

**Solution for Exercise 1:**

```python
raw_names = ["  budi santoso ", "SITI RAHAYU", "andi pratama  ", " DEwI suSAnTI"]
cleaned = [name.strip().title() for name in raw_names]
print(cleaned)
```

Output:

```
['Budi Santoso', 'Siti Rahayu', 'Andi Pratama', 'Dewi Susanti']
```

The list comprehension applies `.strip()` first to remove whitespace, then `.title()` to normalize the casing. Because string methods are chained, Python evaluates left to right: `name.strip()` returns a stripped string, then `.title()` is called on that result. The original `raw_names` list is not modified.

**Solution for Exercise 2:**

```python
raw = "product=Laptop;price=8500000;category=Electronics;in_stock=True"

fields = raw.split(";")
data = {}
for field in fields:
    key, value = field.split("=")
    data[key] = value

print(data)
```

Output:

```
{'product': 'Laptop', 'price': '8500000', 'category': 'Electronics', 'in_stock': 'True'}
```

`raw.split(";")` produces a list of four strings, each containing a key-value pair. `field.split("=")` splits each pair on `"="` and unpacking assigns the two parts to `key` and `value`. All values in the resulting dictionary are strings because they came from splitting a string. To use `price` in calculations, you would need to call `int(data["price"])`.

**Solution for Exercise 3:**

```python
data = [
    ("Laptop", 8500000, 0.85),
    ("Mouse", 150000, 0.12),
    ("Monitor", 3200000, 0.56),
]

print(f"{'Product':<20} {'Price':>15} {'Rating':>10}")
print("-" * 47)

for name, price, rating in data:
    print(f"{name:<20} {price:>15,.0f} {rating:>9.1%}")
```

Output:

```
Product                         Price     Rating
-----------------------------------------------
Laptop                      8,500,000     85.0%
Mouse                         150,000     12.0%
Monitor                     3,200,000     56.0%
```

The header row uses the same alignment widths as the data rows so the columns line up correctly. `:.0f` formats prices with no decimal places. `:.1%` multiplies the float by 100 and formats it as a percentage with one decimal place.

## Next Up - Lesson 11

String methods are the foundation of data cleaning in Python. You can now strip whitespace, normalize case, replace substrings, split on delimiters, join lists back into strings, search for substrings, and format output with precisely controlled alignment, decimal precision, and percentage display. Chaining these methods in list comprehensions gives you concise one-line data transformations.

In Lesson 11, you will apply these string skills to real files: reading text files and CSV files from disk, processing their contents row by row, writing results back to new files, and using context managers to ensure files are opened and closed safely.