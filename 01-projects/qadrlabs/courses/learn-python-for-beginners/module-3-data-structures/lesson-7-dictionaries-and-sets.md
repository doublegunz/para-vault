Lists are great for ordered collections where position matters. But when you need to look up a value by a meaningful name rather than a numeric index, dictionaries are the right tool. A dictionary maps keys to values, the same way a real dictionary maps words to definitions. Instead of `product[0]` to get a product's name, you write `product["name"]`. The code becomes self-documenting.

## 1. Before You Begin

In Lesson 6, you worked with lists and tuples: ordered sequences of items accessed by index position. This lesson introduces the two remaining core data structures: dictionaries and sets.

Dictionaries are arguably the most important data structure in Python for data work. When you read rows from a CSV file using the `csv` module in Lesson 11, each row is returned as a dictionary where the column names are the keys. When you work with JSON data from an API, the entire response is a nested dictionary. When Pandas loads a DataFrame, it stores each column as a named series, which is dictionary-like. Learning dictionaries now prepares you for all of that. Sets are more specialized, but they solve a specific problem - removing duplicates from a collection - with a single elegant operation.

### What You'll Build

You will write a script called `dictionaries.py` that stores sales order data as a list of dictionaries, calculates the total revenue from delivered orders only, groups orders by status, and prints a formatted summary. You will also use a set to deduplicate a list of city names.

### What You'll Learn

- ✅ How to create, access, and modify dictionaries
- ✅ How to safely access keys with `.get()` and a default value
- ✅ How to iterate over a dictionary's keys, values, and key-value pairs
- ✅ How to work with lists of dictionaries as tabular data
- ✅ How to write dictionary comprehensions for in-place transformation
- ✅ How sets store unique values and support set operations

### What You'll Need

- Completion of Lesson 6 (lists and tuples)
- The `python-basics` folder open in VS Code

## 2. Dictionary Basics

A dictionary is an unordered collection of key-value pairs enclosed in curly braces. Each key maps to a value, and keys must be unique within a dictionary. Keys are typically strings, though integers and tuples can also serve as keys. Values can be any Python object: strings, numbers, booleans, lists, or even other dictionaries.

### Step 1: Create a Dictionary and Access Values

Create a new file called `dictionaries.py` and add the following:

```python
product = {
    "name": "Laptop ProBook 14",
    "category": "Electronics",
    "price": 8500000,
    "in_stock": True,
}

print(product["name"])
print(product["price"])
print(product.get("color"))
print(product.get("color", "Black"))
```

Output:

```
Laptop ProBook 14
8500000
None
Black
```

`product["name"]` accesses the value stored under the key `"name"`. This is the direct access method and it raises a `KeyError` if the key does not exist in the dictionary, which causes your script to crash.

`product.get("color")` is the safe access method. If `"color"` does not exist in the dictionary, `.get()` returns `None` instead of raising an error. You can also provide a default value as the second argument: `product.get("color", "Black")` returns `"Black"` if the key is missing. Always use `.get()` when you are not certain whether a key exists, especially when working with data from external sources like user input or CSV files.

### Step 2: Modify a Dictionary

```python
product["price"] = 7999000
product["brand"] = "ProTech"
del product["in_stock"]

print(product)
```

Output:

```
{'name': 'Laptop ProBook 14', 'category': 'Electronics', 'price': 7999000, 'brand': 'ProTech'}
```

Assigning to an existing key updates its value: `product["price"] = 7999000` replaces the original price. Assigning to a key that does not yet exist adds a new key-value pair to the dictionary. `del product["in_stock"]` removes a key and its value entirely. If the key does not exist, `del` raises a `KeyError`, so only use it when you are certain the key is present.

## 3. Iterating Over Dictionaries

Dictionaries are iterable, but what you get when you loop over them depends on which method you call. You can iterate over just the keys, just the values, or both at once.

### Step 1: Loop Over Keys, Values, and Pairs

```python
product = {"name": "Laptop", "price": 8500000, "category": "Electronics"}

for key in product:
    print(key)

for value in product.values():
    print(value)

for key, value in product.items():
    print(f"{key}: {value}")
```

Output:

```
name
price
category
8500000
8500000
Electronics
name: Laptop
price: 8500000
category: Electronics
```

When you loop `for key in product`, Python iterates over the dictionary's keys by default. `.values()` returns a view of all values. `.items()` returns a view of key-value pairs as tuples, which you can unpack into two variables using `for key, value in product.items()`. The `.items()` form is the most commonly used because it gives you access to both the key and value in every iteration.

## 4. Lists of Dictionaries

The most important pattern you will encounter in Python data work is a list of dictionaries. Each dictionary represents one row of data and each key represents a field or column name. This is the structure you get when reading CSV files, querying a database, or receiving JSON from an API.

### Step 1: Process Tabular Data

```python
orders = [
    {"id": 1, "product": "Laptop", "amount": 8500000, "status": "delivered"},
    {"id": 2, "product": "Mouse", "amount": 150000, "status": "delivered"},
    {"id": 3, "product": "Keyboard", "amount": 750000, "status": "cancelled"},
    {"id": 4, "product": "Monitor", "amount": 3200000, "status": "delivered"},
]

total_delivered = sum(o["amount"] for o in orders if o["status"] == "delivered")
print(f"Total delivered: Rp {total_delivered:,}")

cancelled = [o["product"] for o in orders if o["status"] == "cancelled"]
print(f"Cancelled orders: {cancelled}")
```

Output:

```
Total delivered: Rp 11,850,000
Cancelled orders: ['Keyboard']
```

`sum(o["amount"] for o in orders if o["status"] == "delivered")` is a generator expression: it behaves like a list comprehension but produces values one at a time rather than building a full list in memory. The `sum()` function consumes those values and adds them together. This pattern is efficient for aggregation and you will see it frequently in data scripts.

The list comprehension `[o["product"] for o in orders if o["status"] == "cancelled"]` collects the product names of cancelled orders into a new list. Both patterns use the same dictionary access syntax: `o["amount"]` and `o["status"]` access the respective fields of each order dictionary.

### Step 2: Group Orders by Status

```python
status_groups = {}

for order in orders:
    status = order["status"]
    if status not in status_groups:
        status_groups[status] = []
    status_groups[status].append(order["product"])

for status, products in status_groups.items():
    print(f"{status}: {products}")
```

Output:

```
delivered: ['Laptop', 'Mouse', 'Monitor']
cancelled: ['Keyboard']
```

This pattern builds a dictionary whose keys are status values and whose values are lists of product names. `if status not in status_groups` checks whether the key already exists using the `in` operator with a dictionary. If it does not, a new empty list is created for that key. `.append(order["product"])` then adds the product to the appropriate group. This grouping pattern appears frequently in data analysis when you need to aggregate values by category.

## 5. Dictionary Comprehensions

Just as list comprehensions create new lists in one line, dictionary comprehensions create new dictionaries in one line. They are useful for transforming or filtering an existing dictionary without writing a full loop.

### Step 1: Transform and Filter a Dictionary

```python
prices = {"Laptop": 8500000, "Mouse": 150000, "Keyboard": 750000}

with_tax = {name: price * 1.11 for name, price in prices.items()}
print(with_tax)

expensive = {k: v for k, v in prices.items() if v > 500000}
print(expensive)
```

Output:

```
{'Laptop': 9435000.0, 'Mouse': 166500.0, 'Keyboard': 832500.0}
{'Laptop': 8500000, 'Keyboard': 750000}
```

The dictionary comprehension syntax is `{key_expression: value_expression for key, value in dict.items()}`. `{name: price * 1.11 for name, price in prices.items()}` creates a new dictionary where every price has been multiplied by 1.11 to add tax. Adding `if v > 500000` filters the dictionary to include only products whose price exceeds 500000. Like list comprehensions, dictionary comprehensions always produce a new dictionary and leave the original unchanged.

## 6. Sets

A set is an unordered collection of unique values. Duplicate values are not allowed: if you try to add a value that already exists in a set, nothing happens. Sets are defined using curly braces, just like dictionaries, but they contain values rather than key-value pairs.

### Step 1: Create a Set and Remove Duplicates

```python
cities_with_duplicates = ["Jakarta", "Bandung", "Jakarta", "Surabaya", "Bandung", "Bali"]
unique_cities = set(cities_with_duplicates)

print(unique_cities)
print(len(unique_cities))
```

Output:

```
{'Jakarta', 'Bandung', 'Surabaya', 'Bali'}
4
```

`set(cities_with_duplicates)` converts the list to a set, automatically discarding the duplicate values `"Jakarta"` and `"Bandung"`. The order of items in the output is not guaranteed because sets are unordered. If you need the deduplicated items in a sorted list, you can chain the operations: `sorted(set(cities_with_duplicates))`.

This deduplication pattern is very common in data cleaning. When processing real-world data, you frequently encounter repeated values that need to be counted only once.

### Step 2: Set Operations

```python
python_skills = {"variables", "loops", "functions", "classes"}
data_skills = {"functions", "pandas", "numpy", "classes"}

print(python_skills & data_skills)
print(python_skills | data_skills)
print(python_skills - data_skills)
print(python_skills ^ data_skills)
```

Output:

```
{'functions', 'classes'}
{'variables', 'loops', 'functions', 'classes', 'pandas', 'numpy'}
{'variables', 'loops'}
{'variables', 'loops', 'pandas', 'numpy'}
```

`&` is the intersection operator: it returns only the items that appear in both sets. `|` is the union operator: it returns all items from both sets with no duplicates. `-` is the difference operator: it returns items that are in the left set but not in the right set. `^` is the symmetric difference operator: it returns items that appear in one set but not both. These operations are the same as mathematical set theory and are useful for comparing lists of records, tags, or categories.

## 7. Fix the Errors in Your Code

This section covers the two most common mistakes beginners make when working with dictionaries and sets.

**Error 1: Using square bracket access on a key that might not exist.**

Direct key access with `dict["key"]` raises a `KeyError` and crashes the script if the key is not in the dictionary. This is particularly dangerous when working with data from external sources.

```python
# Wrong: raises KeyError if "color" is not in the dictionary
product = {"name": "Laptop", "price": 8500000}
print(product["color"])

# Correct: use .get() with an optional default value
print(product.get("color"))
print(product.get("color", "Not specified"))
```

`.get()` is the safe alternative. When the key does not exist, it returns `None` by default or the fallback value you provide. Using `.get()` with a default is especially important when processing rows from a CSV file or JSON response where not every row is guaranteed to have every field.

**Error 2: Confusing an empty set with an empty dictionary.**

An empty dictionary is written `{}`. An empty set cannot be written as `{}` because Python interprets that as an empty dictionary. You must use `set()` to create an empty set.

```python
# Wrong: {} creates an empty dictionary, not an empty set
empty_set = {}
print(type(empty_set))

# Correct: use set() to create an empty set
empty_set = set()
print(type(empty_set))

# Adding items to a set
empty_set.add("Jakarta")
empty_set.add("Bandung")
print(empty_set)
```

`type({})` returns `<class 'dict'>`, not `<class 'set'>`. If you try to call `.add()` on what you think is a set but is actually a dictionary, Python raises an `AttributeError`. Always use `set()` to create an empty set.

## 8. Exercises

**Exercise 1:** Create a dictionary representing a student: name, age, city, and GPA. Print each key-value pair using `.items()`. Then update the GPA to a new value and add a new key `"is_graduated"` set to `False`.

**Exercise 2:** You have this list of orders:

```python
orders = [
    {"product": "Laptop", "amount": 8500000, "region": "Jakarta"},
    {"product": "Mouse", "amount": 150000, "region": "Bandung"},
    {"product": "Monitor", "amount": 3200000, "region": "Jakarta"},
    {"product": "Keyboard", "amount": 750000, "region": "Surabaya"},
]
```

Use a generator expression with `sum()` to calculate the total amount for orders from `"Jakarta"` only. Then use a dictionary comprehension to create a new dictionary mapping each product name to its amount.

**Exercise 3:** You have two lists: `["Python", "SQL", "Excel", "Power BI"]` and `["Python", "R", "SQL", "Tableau"]`. Convert both to sets and find: the skills that appear in both lists, all unique skills combined, and skills that are in the first list but not the second.

## 9. Solutions

**Solution for Exercise 1:**

```python
student = {
    "name": "Budi",
    "age": 22,
    "city": "Jakarta",
    "gpa": 3.45,
}

for key, value in student.items():
    print(f"{key}: {value}")

student["gpa"] = 3.72
student["is_graduated"] = False

print("\nUpdated student:")
print(student)
```

`.items()` returns key-value pairs, which are unpacked into `key` and `value` on each iteration. Assigning to `student["gpa"]` updates the existing key. Assigning to `student["is_graduated"]` creates a new key because it does not yet exist in the dictionary.

**Solution for Exercise 2:**

```python
orders = [
    {"product": "Laptop", "amount": 8500000, "region": "Jakarta"},
    {"product": "Mouse", "amount": 150000, "region": "Bandung"},
    {"product": "Monitor", "amount": 3200000, "region": "Jakarta"},
    {"product": "Keyboard", "amount": 750000, "region": "Surabaya"},
]

jakarta_total = sum(o["amount"] for o in orders if o["region"] == "Jakarta")
print(f"Jakarta total: Rp {jakarta_total:,}")

product_amounts = {o["product"]: o["amount"] for o in orders}
print(product_amounts)
```

The generator expression filters orders where `region` is `"Jakarta"` and sums only their `amount` values. The Jakarta total is `Rp 11,700,000`. The dictionary comprehension uses `o["product"]` as the key and `o["amount"]` as the value, building a new dictionary that maps each product name to its price in one line.

**Solution for Exercise 3:**

```python
list_a = ["Python", "SQL", "Excel", "Power BI"]
list_b = ["Python", "R", "SQL", "Tableau"]

set_a = set(list_a)
set_b = set(list_b)

print("In both:", set_a & set_b)
print("All unique:", set_a | set_b)
print("In A but not B:", set_a - set_b)
```

Output:

```
In both: {'Python', 'SQL'}
All unique: {'Python', 'SQL', 'Excel', 'Power BI', 'R', 'Tableau'}
In A but not B: {'Excel', 'Power BI'}
```

`&` finds the intersection: skills that appear in both sets. `|` finds the union: all unique skills across both sets. `-` finds the difference: skills in `set_a` that do not appear in `set_b`.

## Next Up - Lesson 8

Dictionaries are Python's most powerful built-in data structure for named data access. You can now create and modify dictionaries, safely read keys with `.get()`, iterate over keys, values, and key-value pairs, process lists of dictionaries as tabular data, and transform dictionaries with comprehensions. Sets handle the specialized case of unique collections and set operations.

In Lesson 8, you will learn how to bundle reusable logic into functions using `def`, pass data in with parameters, return results, set default argument values, and handle variable numbers of arguments with `*args` and `**kwargs`.