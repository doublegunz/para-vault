Loops are what make programs scale. Without them, processing a list of 1000 sales transactions would require writing 1000 individual lines of code. With a loop, you write the logic once and Python repeats it for every item automatically. In data work, loops are everywhere: iterating over rows in a CSV file, processing each item in a product list, or accumulating totals across a collection.

## 1. Before You Begin

In Lesson 4, you learned how to make decisions with `if`, `elif`, and `else`. Conditionals control which path your code takes. Loops control how many times your code runs a path. Together, these two tools form the backbone of almost every Python script you will write.

This lesson introduces Python's two loop types and the tools that make them more powerful. By the end, you will be able to loop over any collection of data, track position with `enumerate()`, generate numeric sequences with `range()`, and stop or skip iterations when needed with `break` and `continue`. These skills appear directly in the mini project, where you will loop over rows of sales data to calculate totals.

### What You'll Build

You will write a script called `loops.py` that processes a list of sales orders: printing each order with a numbered label, summing the totals of delivered orders, and skipping cancelled ones. The script uses `for` loops, `enumerate()`, `range()`, and `continue`.

### What You'll Learn

- ✅ How to use `for` loops to iterate over any sequence
- ✅ How `range()` generates numeric sequences for counted loops
- ✅ How `enumerate()` gives you the index and value simultaneously
- ✅ How `while` loops repeat until a condition becomes false
- ✅ How `break` exits a loop and `continue` skips an iteration

### What You'll Need

- Completion of Lesson 4 (conditionals and logic)
- The `python-basics` folder open in VS Code

## 2. The for Loop

The `for` loop is Python's primary tool for iterating over a collection. It cycles through every item in a sequence, one at a time, and executes the indented block for each one. The sequence can be a list, a string, a range of numbers, or any other iterable object.

### Step 1: Iterate Over a List

Create a new file called `loops.py` and add the following:

```python
fruits = ["apple", "banana", "cherry"]

for fruit in fruits:
    print(fruit)
```

Output:

```
apple
banana
cherry
```

The syntax is `for variable_name in collection:`. On each iteration, Python assigns the current item to `variable_name` and executes the indented block. After the block runs, Python moves to the next item. When the collection is exhausted, the loop ends and execution continues with the code after the loop.

The variable name `fruit` is chosen to match the items in the list. You can use any name, but choosing a meaningful name makes the code easier to read.

### Step 2: Iterate Over a String

```python
word = "Python"

for character in word:
    print(character)
```

Output:

```
P
y
t
h
o
n
```

A string is a sequence of characters, so a `for` loop iterates over each character individually. This same mental model applies to all iterables in Python: the loop simply moves through each element of the sequence in order.

## 3. range() for Numeric Loops

When you need to loop a specific number of times, or work with a sequence of numbers rather than a collection of objects, you use `range()`. It generates a sequence of integers without storing them all in memory at once.

### Step 1: Basic range() Usage

```python
for i in range(5):
    print(i)
```

Output:

```
0
1
2
3
4
```

`range(5)` generates the integers 0, 1, 2, 3, 4. It starts at 0 by default and stops before the number you provide. The stop value is always exclusive, meaning `range(5)` produces five numbers but does not include 5 itself.

### Step 2: range() with Start, Stop, and Step

```python
for i in range(1, 11):
    print(i)

for i in range(0, 20, 5):
    print(i)
```

Output:

```
1
2
3
...
10
0
5
10
15
```

`range(start, stop)` begins at `start` and ends before `stop`. `range(1, 11)` produces numbers 1 through 10. Adding a third argument, `range(start, stop, step)`, controls the increment between each number. `range(0, 20, 5)` produces 0, 5, 10, 15 because it increments by 5 each time and stops before reaching 20.

## 4. enumerate() for Index and Value

A common situation in loops is needing both the index (the position of the item) and the item itself. You could use `range(len(collection))` and index manually, but `enumerate()` is cleaner and more readable.

### Step 1: Use enumerate()

```python
fruits = ["apple", "banana", "cherry"]

for i, fruit in enumerate(fruits):
    print(f"{i + 1}. {fruit}")
```

Output:

```
1. apple
2. banana
3. cherry
```

`enumerate(fruits)` wraps the list and returns pairs of `(index, item)` on each iteration. By writing `for i, fruit in enumerate(fruits):`, Python unpacks each pair into two variables: `i` receives the index and `fruit` receives the item. The index starts at 0 by default, so `i + 1` produces a 1-based counter for display purposes.

If you prefer the counter to start at 1 directly, you can pass a second argument: `enumerate(fruits, start=1)`.

## 5. The while Loop

The `while` loop repeats a block of code as long as a condition remains true. Unlike a `for` loop, which knows how many items it will iterate over, a `while` loop continues indefinitely until something changes the condition to false.

### Step 1: Write a while Loop

```python
count = 0

while count < 5:
    print(f"Count: {count}")
    count += 1

print("Done")
```

Output:

```
Count: 0
Count: 1
Count: 2
Count: 3
Count: 4
Done
```

`count += 1` is shorthand for `count = count + 1`. It increments `count` by 1 on each iteration. The loop condition `count < 5` is checked at the top of every iteration. When `count` reaches 5, the condition becomes false, the loop exits, and `"Done"` is printed.

`while` loops are best when you do not know in advance how many iterations you need: waiting for valid user input, reading data until a sentinel value appears, or retrying an operation until it succeeds.

### Step 2: Infinite Loop and Exit with Input

```python
while True:
    answer = input("Type 'quit' to exit: ")
    if answer == "quit":
        print("Goodbye!")
        break
```

`while True` creates a loop that never stops on its own because `True` is always truthy. The `break` statement inside the loop is the only exit point. This pattern is common for interactive programs that keep running until the user explicitly chooses to stop.

## 6. break and continue

Two keywords give you fine-grained control over loop execution: `break` terminates the loop immediately, and `continue` skips the rest of the current iteration and moves to the next one.

### Step 1: break to Exit Early

```python
for num in range(1, 100):
    if num > 5:
        break
    print(num)
```

Output:

```
1
2
3
4
5
```

When `num` reaches 6, the condition `num > 5` becomes true, `break` executes, and the loop ends immediately. The remaining 94 iterations never run. `break` is useful when you are searching for a specific item and want to stop as soon as you find it.

### Step 2: continue to Skip an Iteration

```python
for num in range(1, 11):
    if num % 2 == 0:
        continue
    print(num)
```

Output:

```
1
3
5
7
9
```

When `num % 2 == 0` is true (meaning the number is even), `continue` skips the `print(num)` line and jumps directly to the next iteration. The loop does not exit; it simply moves on. Only odd numbers reach the `print` statement.

## 7. Practical Example: Processing Sales Orders

This example combines `for`, `enumerate()`, and `continue` to process a realistic list of orders, the same structure you will work with in the mini project.

### Step 1: Loop Over a List of Dictionaries

```python
orders = [
    {"id": 1, "product": "Laptop", "amount": 8500000, "status": "delivered"},
    {"id": 2, "product": "Mouse", "amount": 150000, "status": "delivered"},
    {"id": 3, "product": "Keyboard", "amount": 750000, "status": "cancelled"},
    {"id": 4, "product": "Monitor", "amount": 3200000, "status": "delivered"},
]

total = 0

for i, order in enumerate(orders, start=1):
    if order["status"] == "cancelled":
        print(f"{i}. [SKIPPED] {order['product']}")
        continue
    total += order["amount"]
    print(f"{i}. {order['product']} - Rp {order['amount']:,}")

print(f"\nTotal (delivered): Rp {total:,}")
```

Output:

```
1. Laptop - Rp 8,500,000
2. Mouse - Rp 150,000
3. [SKIPPED] Keyboard
4. Monitor - Rp 3,200,000

Total (delivered): Rp 11,850,000
```

Each `order` is a dictionary with four keys. `order["status"]` accesses the status field, and `order["amount"]` accesses the amount. When the status is `"cancelled"`, `continue` skips the `total +=` line so cancelled orders never contribute to the sum. `enumerate(orders, start=1)` numbers the rows from 1 instead of 0, which reads more naturally in output.

## 8. Fix the Errors in Your Code

This section covers the two most common mistakes beginners make when writing loops.

**Error 1: Forgetting to update the loop variable in a while loop.**

If the condition of a `while` loop never becomes false, the loop runs forever. This is called an infinite loop and it usually freezes the terminal. The most common cause is forgetting to update the variable the condition depends on.

```python
# Wrong: count never changes, loop runs forever
count = 0
while count < 5:
    print(count)

# Correct: increment count on every iteration
count = 0
while count < 5:
    print(count)
    count += 1
```

The `while` loop checks `count < 5` on every iteration. If `count` stays at 0 forever because it is never incremented, the condition is always true and the loop never stops. Adding `count += 1` inside the loop ensures the value eventually reaches 5 and the loop ends. If you accidentally create an infinite loop in the terminal, press `Ctrl + C` to interrupt it.

**Error 2: Modifying a list while iterating over it.**

Removing items from a list inside a `for` loop that is iterating over that same list causes items to be skipped or produces unexpected results.

```python
# Wrong: removing items while iterating causes skipped elements
numbers = [1, 2, 3, 4, 5]
for n in numbers:
    if n % 2 == 0:
        numbers.remove(n)

# Correct: iterate over a copy, or build a new list
numbers = [1, 2, 3, 4, 5]
odd_numbers = [n for n in numbers if n % 2 != 0]
```

When you remove an item from a list during iteration, the list shrinks and Python's internal counter points to a different position than expected. Some items get skipped silently. The safe approach is to use a list comprehension or build a new list outside the loop instead of mutating the list you are looping over.

## 9. Exercises

**Exercise 1:** Write a script that uses `range()` to print the multiplication table for 7: `7 x 1 = 7`, `7 x 2 = 14`, and so on up to `7 x 10 = 70`.

**Exercise 2:** Write a script that stores a list of five prices. Use a `for` loop with `enumerate()` to print each price with a 1-based number, then calculate and print the total and average.

**Exercise 3:** Write a `while` loop that keeps asking the user to enter a positive number. If the user enters a negative number or zero, print an error and ask again. When the user types `0` exactly, exit the loop and print the sum of all valid numbers entered.

## 10. Solutions

**Solution for Exercise 1:**

```python
for i in range(1, 11):
    result = 7 * i
    print(f"7 x {i} = {result}")
```

`range(1, 11)` generates integers 1 through 10 inclusive. On each iteration, `i` holds the current multiplier. `7 * i` calculates the product and the f-string formats the output as a readable multiplication table line.

**Solution for Exercise 2:**

```python
prices = [85000, 150000, 750000, 2800000, 320000]
total = 0

for i, price in enumerate(prices, start=1):
    print(f"{i}. Rp {price:,}")
    total += price

average = total / len(prices)
print(f"\nTotal:   Rp {total:,}")
print(f"Average: Rp {average:,.0f}")
```

`enumerate(prices, start=1)` gives both the 1-based index and the price on each iteration. `total += price` accumulates the running sum. After the loop, `total / len(prices)` computes the average by dividing the sum by the number of items in the list. `len(prices)` returns the count of items without requiring a separate counter variable.

**Solution for Exercise 3:**

```python
total = 0

while True:
    value = float(input("Enter a positive number (0 to quit): "))
    if value < 0:
        print("Error: please enter a positive number.")
        continue
    if value == 0:
        break
    total += value

print(f"Sum of entered numbers: {total:,.2f}")
```

`while True` keeps the loop running until an explicit `break`. If the user enters a negative number, `continue` skips the `total +=` line and loops back without adding anything to the sum. If the user enters `0`, `break` exits the loop entirely. Any positive number reaches `total += value` and is added to the running sum.

## Next Up - Lesson 6

Loops are the mechanism that makes Python practical for real data work. You can now iterate over any sequence with `for`, generate numeric ranges with `range()`, track position with `enumerate()`, repeat conditionally with `while`, and control flow inside loops with `break` and `continue`. These tools will appear in every lesson from here forward.

In Lesson 6, you will learn about Python's most important data structure: the list. You will go beyond simple iteration and explore indexing, slicing, list methods, list comprehensions, and immutable tuples.