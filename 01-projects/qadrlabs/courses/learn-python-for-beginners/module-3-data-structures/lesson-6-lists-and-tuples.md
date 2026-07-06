Storing a single value in a variable is useful. Storing a collection of related values is where Python's real power starts to emerge. Lists let you group multiple items under one name, iterate over them, sort them, filter them, and transform them. They are the most versatile data structure in Python and the one you will use most frequently in data work.

## 1. Before You Begin

In Lesson 5, you learned how to repeat actions with `for` and `while` loops. You iterated over lists like `["apple", "banana", "cherry"]` and dictionaries inside lists. Now it is time to understand lists as a data structure in their own right, not just something you loop over.

Lists are the building block of almost every data operation in this course. When you read a CSV file in Lesson 11, each row becomes a list. When you calculate totals in the mini project, you will be adding up numbers stored in a list. Understanding how to create, modify, slice, and transform lists is a prerequisite for all of that work. Tuples, the immutable counterpart to lists, appear whenever data must not be changed after it is created.

### What You'll Build

You will write a script called `lists.py` that stores a collection of product prices, filters out items below a threshold, applies a tax multiplier to the remaining prices using a list comprehension, and prints a formatted summary. You will also work with tuples to store fixed coordinate data and practice unpacking.

### What You'll Learn

- ✅ How to create, index, and slice lists
- ✅ How to use common list methods: `append()`, `insert()`, `remove()`, `pop()`, `sort()`
- ✅ How to write list comprehensions for concise data transformation
- ✅ What tuples are and when to use them instead of lists
- ✅ How to unpack tuples and lists into individual variables

### What You'll Need

- Completion of Lesson 5 (loops)
- The `python-basics` folder open in VS Code

## 2. List Basics

A list is an ordered, mutable collection of items enclosed in square brackets. Ordered means the items have a defined sequence and each item has a position. Mutable means you can add, remove, or change items after the list is created.

### Step 1: Create a List and Access Items

Create a new file called `lists.py` and add the following:

```python
products = ["Laptop", "Mouse", "Keyboard", "Monitor"]

print(products[0])
print(products[-1])
print(products[1:3])
print(len(products))
```

Output:

```
Laptop
Monitor
['Mouse', 'Keyboard']
4
```

Lists use zero-based indexing, meaning the first item is at position 0 and the last item is at position `len(list) - 1`. `products[0]` returns `"Laptop"`, the first item. Negative indexes count backward from the end: `products[-1]` returns `"Monitor"`, the last item, without needing to know the list's length.

The slice `products[1:3]` returns a new list containing items from index 1 up to but not including index 3. Only the items at positions 1 and 2 are included, so the result is `['Mouse', 'Keyboard']`. Slicing never modifies the original list; it always produces a new one.

`len(products)` returns the number of items in the list, which is `4`. This is a built-in function, not a method, so it is called with the list as an argument rather than using dot notation.

### Step 2: Modify List Items

```python
products[2] = "Mechanical Keyboard"
print(products)
```

Output:

```
['Laptop', 'Mouse', 'Mechanical Keyboard', 'Monitor']
```

You can overwrite any item in a list by assigning a new value to its index position. This works because lists are mutable. `products[2] = "Mechanical Keyboard"` replaces `"Keyboard"` at position 2 with the new string. The rest of the list is unchanged.

## 3. List Methods

Python provides a set of built-in methods on list objects for adding, removing, searching, and reordering items. These methods modify the list in place, meaning they change the original list rather than returning a new one.

### Step 1: Add and Remove Items

```python
products = ["Laptop", "Mouse"]

products.append("Keyboard")
print(products)

products.insert(1, "USB Hub")
print(products)

products.remove("Mouse")
print(products)

removed = products.pop()
print(removed)
print(products)
```

Output:

```
['Laptop', 'Mouse', 'Keyboard']
['Laptop', 'USB Hub', 'Mouse', 'Keyboard']
['Laptop', 'USB Hub', 'Keyboard']
Keyboard
['Laptop', 'USB Hub']
```

`.append(item)` adds an item to the end of the list. It is the most common way to build up a list gradually inside a loop. `.insert(index, item)` inserts an item at a specific position, shifting everything at that position and after it one step to the right. `.remove(value)` searches for the first occurrence of the given value and removes it. If the value does not exist in the list, it raises a `ValueError`. `.pop()` removes and returns the last item. You can also pass an index to `.pop(index)` to remove and return a specific item.

### Step 2: Sort, Search, and Count

```python
numbers = [3, 1, 4, 1, 5, 9, 2, 6]
numbers.sort()
print(numbers)

numbers.reverse()
print(numbers)

print("Laptop" in products)
print(products.count("Laptop"))
print(products.index("USB Hub"))
```

Output:

```
[1, 1, 2, 3, 4, 5, 6, 9]
[9, 6, 5, 4, 3, 2, 1, 1]
True
1
1
```

`.sort()` rearranges the list in ascending order in place. It modifies the original list and returns `None`, so do not write `sorted_list = numbers.sort()` expecting the result. If you need a sorted copy without modifying the original, use the built-in `sorted(numbers)` function instead, which returns a new list.

`.reverse()` reverses the order of the list in place. The `in` operator is a membership test that returns `True` if the value exists in the list and `False` otherwise. `.count(value)` counts how many times the value appears. `.index(value)` returns the index of the first occurrence of the value.

## 4. List Comprehensions

A list comprehension is a concise way to create a new list by applying an expression to each item in an existing sequence, optionally filtering items based on a condition. They replace three to five lines of loop code with a single readable line.

### Step 1: Transform a List

```python
prices = [85000, 150000, 750000, 2800000]

with_tax = []
for p in prices:
    with_tax.append(p * 1.11)
print(with_tax)

with_tax = [p * 1.11 for p in prices]
print(with_tax)
```

Both approaches produce the same result: a new list where every price has been multiplied by `1.11` to add 11% tax. The first approach uses a regular `for` loop with `.append()`. The second uses a list comprehension, which expresses the same operation in one line. The syntax is `[expression for variable in iterable]`.

The list comprehension reads almost like a plain English sentence: "make a list of `p * 1.11` for each `p` in `prices`." The result is a new list; the original `prices` list is not changed.

### Step 2: Filter and Transform Together

```python
prices = [85000, 150000, 750000, 2800000]

expensive = [p for p in prices if p > 500000]
print(expensive)

labels = [f"Rp {p:,.0f}" for p in prices if p > 100000]
print(labels)
```

Output:

```
[750000, 2800000]
['Rp 150,000', 'Rp 750,000', 'Rp 2,800,000']
```

Adding `if condition` at the end of a list comprehension filters the items: only items for which the condition is true are included in the result. `[p for p in prices if p > 500000]` produces a new list containing only the prices above 500000. The expression and the filter can be combined freely: `[f"Rp {p:,.0f}" for p in prices if p > 100000]` both filters the prices and formats each remaining price as a currency string.

## 5. Tuples

A tuple is an immutable sequence. It looks like a list but uses parentheses instead of square brackets, and once created, its contents cannot be changed. You cannot append to it, remove items from it, or modify any of its elements.

### Step 1: Create and Access a Tuple

```python
coordinates = (3.14, 2.71)
print(coordinates[0])
print(coordinates[1])
print(type(coordinates))
```

Output:

```
3.14
2.71
<class 'tuple'>
```

Tuple indexing works the same way as list indexing. However, if you try to assign a new value to any position, Python raises a `TypeError`. Tuples are used for data that must not be changed: geographic coordinates, RGB color values, database row results returned by a query, and function return values that pack multiple outputs together.

### Step 2: Tuple Unpacking

```python
name, age, city = ("Budi", 25, "Jakarta")
print(f"{name} is {age}, lives in {city}")

a, b = 10, 20
a, b = b, a
print(f"a={a}, b={b}")
```

Output:

```
Budi is 25, lives in Jakarta
a=20, b=10
```

Unpacking assigns each element of a tuple (or list) to a separate variable in a single statement. The number of variables on the left must match the number of elements in the tuple on the right, otherwise Python raises a `ValueError`.

The variable swap `a, b = b, a` is a Python idiom that works because Python evaluates the right side completely before performing any assignments. The values `b` and `a` are read first, then assigned to `a` and `b` respectively. No temporary variable is needed.

## 6. Fix the Errors in Your Code

This section covers the two most common mistakes beginners make when working with lists and tuples.

**Error 1: Treating `.sort()` as a function that returns a sorted list.**

`.sort()` modifies the list in place and returns `None`. Assigning its return value to a variable produces `None`, not a sorted list.

```python
# Wrong: sort() returns None, not the sorted list
numbers = [3, 1, 4, 1, 5]
sorted_numbers = numbers.sort()
print(sorted_numbers)

# Correct: use sorted() to get a new sorted list, or just sort() in place
numbers = [3, 1, 4, 1, 5]
sorted_numbers = sorted(numbers)
print(sorted_numbers)

numbers.sort()
print(numbers)
```

`sorted(numbers)` is a built-in function that returns a new sorted list without changing the original. `numbers.sort()` sorts the original list in place. Use `sorted()` when you need to keep the original order, and `.sort()` when you only need the sorted version.

**Error 2: Trying to modify a tuple.**

Tuples are immutable. Any attempt to change, add, or remove an element raises a `TypeError`.

```python
# Wrong: tuples cannot be modified after creation
point = (10, 20)
point[0] = 15

# Correct: convert to a list first if you need to modify it
point = list((10, 20))
point[0] = 15
point = tuple(point)
print(point)
```

If you find yourself needing to modify a tuple, that is a signal you should be using a list instead. The conversion pattern above works: `list()` converts a tuple to a mutable list, you make your changes, then `tuple()` converts it back to an immutable tuple if needed.

## 7. Exercises

**Exercise 1:** Create a list of five city names. Sort the list alphabetically, print each city with a number using `enumerate()`, then reverse the list and print it again.

**Exercise 2:** You have a list of raw prices: `[85000, 0, 150000, -500, 750000, 2800000, 0]`. Use a list comprehension to create a new list that contains only positive prices, then calculate and print the total.

**Exercise 3:** Write a script that stores a tuple containing three values: a product name, a price, and a stock count. Unpack the tuple into three variables and print a formatted summary: `"Product: Laptop | Price: Rp 8,500,000 | Stock: 42 units"`.

## 8. Solutions

**Solution for Exercise 1:**

```python
cities = ["Surabaya", "Jakarta", "Bandung", "Medan", "Bali"]

cities.sort()
print("Alphabetical order:")
for i, city in enumerate(cities, start=1):
    print(f"  {i}. {city}")

cities.reverse()
print("\nReversed order:")
for i, city in enumerate(cities, start=1):
    print(f"  {i}. {city}")
```

`.sort()` modifies `cities` in place, so subsequent operations on `cities` work with the sorted version. `.reverse()` then reverses the sorted list in place, producing reverse alphabetical order. `enumerate(cities, start=1)` provides a 1-based counter for each city without a separate counter variable.

**Solution for Exercise 2:**

```python
raw_prices = [85000, 0, 150000, -500, 750000, 2800000, 0]

valid_prices = [p for p in raw_prices if p > 0]
print(valid_prices)

total = sum(valid_prices)
print(f"Total: Rp {total:,}")
```

The list comprehension `[p for p in raw_prices if p > 0]` filters out any price that is zero or negative, keeping only meaningful values. `sum()` is a built-in Python function that adds all elements of a list and returns the total. The result is `Rp 3,785,000`.

**Solution for Exercise 3:**

```python
product_info = ("Laptop", 8500000, 42)

name, price, stock = product_info
print(f"Product: {name} | Price: Rp {price:,} | Stock: {stock} units")
```

Unpacking `product_info` into three variables happens in one line. Python assigns `"Laptop"` to `name`, `8500000` to `price`, and `42` to `stock` based on order. The f-string then formats all three values into a readable summary line with proper currency formatting.

## Next Up - Lesson 7

Lists are Python's workhorse data structure: ordered, mutable, and full of useful methods. You can now create and modify lists, access items by index and slice, add and remove items with `append()`, `insert()`, `remove()`, and `pop()`, sort and search lists, and write concise list comprehensions to transform and filter data. Tuples give you an immutable counterpart for data that should not change, and unpacking lets you assign multiple values at once.

In Lesson 7, you will learn about dictionaries, which map keys to values and allow you to look up data by name instead of by position. You will also learn about sets, which store unique collections and support mathematical operations like union and intersection.