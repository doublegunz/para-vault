## 1. Before You Begin

In Lesson 1 you wrote algorithms as numbered steps in plain English. That worked, but you may have noticed a problem: plain English is flexible. One person writes "read the price," another writes "ask the user for the price," and a third writes "get price." All three mean the same thing, yet they look different, and some sentences can be read in more than one way.

**Algorithmic notation** solves this. It is a structured way of writing algorithms with a small set of fixed keywords and a fixed layout. It is not a programming language, so no computer runs it and you do not have to worry about semicolons or brackets. But it is precise enough that you can translate it into Java almost line by line, which is exactly what you will do starting in Lesson 3.

This lesson introduces the layout of a notation algorithm and the first few keywords: declaring data, assigning values, reading input, and displaying output. You will use this notation in every remaining lesson of the course.

### What You'll Build

Three complete algorithms written in algorithmic notation: a greeting program, a total price calculator, and a temperature converter. You will also trace a notation algorithm with a table to confirm it produces the right result.

### What You'll Learn

- ✅ The three parts of a notation algorithm: the Program header, the Dictionary, and the Algorithm
- ✅ How to write comments with curly braces
- ✅ The five basic data types: integer, real, character, boolean, and string
- ✅ How to declare variables and constants in the Dictionary
- ✅ How to assign a value with the `<-` arrow
- ✅ How to read data with `input()` and display results with `output()`
- ✅ A preview of the notation for decisions, loops, and subprograms

### What You'll Need

- Lesson 1 completed, so you are comfortable with sequence, selection, repetition, and tracing
- A pen and paper, or a plain text editor

---

## 2. The Layout of a Notation Algorithm

Every algorithm in this course is written with the same three-part layout. Here is the total price algorithm from Lesson 1, rewritten in notation:

```text
Program TotalPrice
{ Reads the price of one item and the quantity bought, then displays the total price }

Dictionary
    price    : integer
    quantity : integer
    total    : integer

Algorithm
    input(price)
    input(quantity)
    total <- price * quantity
    output("Total: ", total)
```

Before looking at each part in detail, compare it with the plain English version. The steps are the same, but the notation version is shorter, every action uses a fixed keyword, and all the data the algorithm needs is listed up front.

### Step 1: Write the Program Header

The first part is the **header**. It gives the algorithm a name and a short description:

```text
Program TotalPrice
{ Reads the price of one item and the quantity bought, then displays the total price }
```

`Program` is a keyword, followed by a name. Names in notation are written without spaces; this course joins words with capital letters, like `TotalPrice`, because Java uses the same style for program names. The line in curly braces `{ }` is a **comment**. Comments are notes for human readers; they are not steps of the algorithm. A good header comment says what the algorithm does in one sentence.

You can write comments anywhere in an algorithm, always inside `{ }`, to explain a step that may not be obvious.

### Step 2: Declare the Data in the Dictionary

The second part is the **Dictionary**. It lists every piece of data the algorithm uses, each with a name and a type:

```text
Dictionary
    price    : integer
    quantity : integer
    total    : integer
```

Each line reads as "name is of type." `price : integer` means "`price` is a named storage place that holds a whole number." These named storage places are called **variables**, because the value stored in them can change while the algorithm runs. Listing variables before using them is called **declaring** them.

Why declare data first? Because it forces you to think about what information the algorithm needs before writing any step. It also catches mistakes early: if a step uses a name that is not in the Dictionary, something is wrong. Java works the same way, as you will see in Lesson 4, so this habit transfers directly.

If several variables share a type, you can declare them on one line, separated by commas:

```text
Dictionary
    price, quantity, total : integer
```

### Step 3: Write the Steps in the Algorithm Section

The third part is the **Algorithm** section. It contains the actual steps, one per line, executed from top to bottom:

```text
Algorithm
    input(price)
    input(quantity)
    total <- price * quantity
    output("Total: ", total)
```

Each line uses one of the basic actions you will learn in the next section: reading input, assigning a value, or displaying output. Steps are indented under the `Algorithm` keyword so it is clear where the section begins.

---

## 3. The Basic Building Blocks

Now let us look at the pieces you can use inside the Dictionary and the Algorithm section.

### Step 1: Choose a Data Type

A **data type** says what kind of value a variable can hold. Notation uses five basic types:

| Type | Holds | Examples |
| --- | --- | --- |
| `integer` | Whole numbers, positive or negative | `0`, `42`, `-7`, `15000` |
| `real` | Numbers with a decimal part | `3.14`, `-0.5`, `98.6` |
| `character` | A single letter, digit, or symbol | `'A'`, `'z'`, `'7'`, `'?'` |
| `boolean` | One of two values: true or false | `true`, `false` |
| `string` | A sequence of characters, that is, text | `"Hello"`, `"Budi Santoso"` |

Notice the quotes: a single character goes in single quotes `'A'`, while text goes in double quotes `"Hello"`. Numbers and booleans have no quotes at all.

Choosing the right type matters. A quantity of notebooks should be an `integer`, because nobody buys 2.5 notebooks. A temperature should be a `real`, because 36.6 degrees is a normal value. A student's name is a `string`. A value that answers a yes or no question, such as "has the student paid?", is a `boolean`.

### Step 2: Declare a Constant

Some values never change while the algorithm runs, such as the number of days in a week or a fixed tax rate. These are declared as **constants**:

```text
Dictionary
    constant DAYS_IN_WEEK : integer = 7
    constant TAX_RATE     : real    = 0.11
```

A constant declaration starts with the keyword `constant`, then the name, the type, and its value after `=`. This course writes constant names in capital letters with underscores, so you can tell at a glance that they are fixed. Using a named constant instead of typing `0.11` everywhere makes an algorithm easier to read, and if the tax rate ever changes, you only update one line.

### Step 3: Assign a Value with the Arrow

**Assignment** stores a value in a variable. In notation it is written with a left arrow `<-`:

```text
total <- price * quantity
```

Read it as "total gets price times quantity." The right side is calculated first, and the result is then stored in the variable on the left. Whatever value `total` held before is replaced.

The arrow is used on purpose instead of `=`. In mathematics, `x = x + 1` is impossible, but in an algorithm, `x <- x + 1` makes perfect sense: take the current value of `x`, add 1, and store the result back in `x`. The arrow shows the direction the data moves. (Java writes assignment with `=`, which is a common source of confusion; you will deal with that in Lesson 7.)

The arithmetic operators in notation are:

| Operator | Meaning | Example | Result |
| --- | --- | --- | --- |
| `+` | Addition | `7 + 2` | `9` |
| `-` | Subtraction | `7 - 2` | `5` |
| `*` | Multiplication | `7 * 2` | `14` |
| `/` | Real division | `7 / 2` | `3.5` |
| `div` | Integer division (whole part only) | `7 div 2` | `3` |
| `mod` | Remainder of integer division | `7 mod 2` | `1` |

You will practice all of these in Lesson 5.

### Step 4: Read Input and Display Output

`input()` reads a value, usually typed by the user on the keyboard, and stores it in the variable named inside the parentheses:

```text
input(price)
```

`output()` displays values on the screen. It can display text, variables, or both, separated by commas:

```text
output("Hello!")
output(total)
output("Total: ", total)
```

The first line displays the text `Hello!`. The second displays the value stored in `total`, for example `15000`. The third displays the text `Total: ` followed by the value of `total`, for example `Total: 15000`. Text inside double quotes is displayed exactly as written; a name without quotes is replaced by the value it holds.

---

## 4. Write Complete Algorithms

Now put the pieces together. Each algorithm below is complete: it has a header, a Dictionary, and an Algorithm section.

### Step 1: A Greeting Algorithm

**Problem:** Ask for the user's name, then greet them by name.

```text
Program Greeting
{ Reads the user's name and displays a personal greeting }

Dictionary
    name : string

Algorithm
    output("What is your name?")
    input(name)
    output("Hello, ", name, "! Welcome to programming.")
```

The algorithm needs only one piece of data, the name, so the Dictionary has one variable of type `string`. The first `output` displays a question so the user knows what to type; this is called a **prompt**. `input(name)` stores whatever the user types in `name`. The last line combines three things into one line of output: some text, the value of `name`, and more text. If the user types `Budi`, the result is `Hello, Budi! Welcome to programming.`

### Step 2: An Algorithm with a Constant

**Problem:** A shop charges 11% tax on every purchase. Given the price of one item and the quantity, display the subtotal, the tax, and the total to pay.

```text
Program PurchaseWithTax
{ Calculates the subtotal, tax, and total payment for a purchase }

Dictionary
    constant TAX_RATE : real = 0.11
    price, quantity    : integer
    subtotal, tax, total : real

Algorithm
    input(price)
    input(quantity)
    subtotal <- price * quantity
    tax <- subtotal * TAX_RATE
    total <- subtotal + tax
    output("Subtotal: ", subtotal)
    output("Tax: ", tax)
    output("Total: ", total)
```

The tax rate never changes, so it is a constant. `price` and `quantity` are whole numbers, but the tax can have a decimal part (11% of 15000 is 1650, but 11% of 1250 is 137.5), so `subtotal`, `tax`, and `total` are `real`. Each assignment uses values that were calculated on earlier lines, which is why the order of the steps matters: `tax` needs `subtotal`, and `total` needs both.

### Step 3: A Conversion Algorithm

**Problem:** Convert a temperature from degrees Celsius to degrees Fahrenheit, using the formula F = C x 9 / 5 + 32.

```text
Program CelsiusToFahrenheit
{ Converts a temperature from Celsius to Fahrenheit }

Dictionary
    celsius, fahrenheit : real

Algorithm
    output("Temperature in Celsius: ")
    input(celsius)
    fahrenheit <- celsius * 9 / 5 + 32
    output(celsius, " C = ", fahrenheit, " F")
```

Temperatures can have decimals, so both variables are `real`. The formula is written almost exactly as it appears in a science book; the only change is that multiplication uses `*`. The final `output` mixes values and text to produce a readable line such as `30 C = 86 F`.

---

## 5. A Preview of the Rest of the Notation

The algorithms in this lesson are pure sequences. In later lessons you will add selection, repetition, and subprograms. You do not need to memorize these yet, but it helps to see where the course is going. Each row below is covered in the lesson listed.

| Structure | Notation | Lesson |
| --- | --- | --- |
| Selection | `if condition then ... else ... endif` | 7 |
| Multiple cases | `depend on (variable) ... enddepend` | 8 |
| Repetition with a condition | `while condition do ... endwhile` | 9 |
| Repetition at least once | `repeat ... until condition` | 10 |
| Counted repetition | `for i <- 1 to n do ... endfor` | 10 |
| Procedure | `procedure Name(input x : integer)` | 12 |
| Function | `function Name(x : integer) -> integer` | 13 |
| Array | `scores : array [0..4] of integer` | 15 |
| Record | `type Student : < name : string, score : integer >` | 18 |

For example, the pass or fail algorithm from Lesson 1 looks like this in notation:

```text
Program PassOrFail
{ Displays PASS if the score is at least 75, otherwise FAIL }

Dictionary
    score : integer

Algorithm
    input(score)
    if score >= 75 then
        output("PASS")
    else
        output("FAIL")
    endif
```

Even without studying `if` yet, you can probably read this. That is the goal of notation: it should be clear to anyone who reads it, including you, a week later.

---

## 6. Run and Test

Notation algorithms do not run on a computer, so you test them by tracing, just as in Lesson 1. The difference is that the Dictionary already tells you which columns your tracing table needs: one column per variable.

Trace `PurchaseWithTax` with a price of 12500 and a quantity of 4. The values are expected to be: subtotal 50000, tax 5500, and total 55500.

| Step | price | quantity | subtotal | tax | total | Output |
| --- | --- | --- | --- | --- | --- | --- |
| `input(price)` | 12500 | | | | | |
| `input(quantity)` | 12500 | 4 | | | | |
| `subtotal <- price * quantity` | 12500 | 4 | 50000 | | | |
| `tax <- subtotal * TAX_RATE` | 12500 | 4 | 50000 | 5500 | | |
| `total <- subtotal + tax` | 12500 | 4 | 50000 | 5500 | 55500 | |
| `output("Subtotal: ", subtotal)` | | | | | | Subtotal: 50000 |
| `output("Tax: ", tax)` | | | | | | Tax: 5500 |
| `output("Total: ", total)` | | | | | | Total: 55500 |

Each row is one line of the Algorithm section, and each cell shows the variable's value *after* that line runs. The final outputs match the expected values, so the algorithm is correct for this input. In Lesson 3 you will write a Java version of an algorithm like this and see a real computer produce the same output.

---

## 7. Fix the Errors in Your Code

These are the mistakes beginners most often make when writing notation for the first time.

**Error 1: Using a variable that is not in the Dictionary.**

```text
// Wrong
Program RectangleArea
Dictionary
    length, width : integer
Algorithm
    input(length)
    input(width)
    area <- length * width
    output(area)

// Correct
Program RectangleArea
Dictionary
    length, width, area : integer
Algorithm
    input(length)
    input(width)
    area <- length * width
    output(area)
```

The wrong version stores a result in `area`, but `area` was never declared. Every variable used in the Algorithm section must appear in the Dictionary with a type. Java enforces the same rule and refuses to compile a program that uses an undeclared variable.

**Error 2: Writing the assignment in the wrong direction.**

```text
// Wrong
price * quantity <- total

// Correct
total <- price * quantity
```

The arrow always points *into* the variable that receives the value. The left side must be a single variable name, and the right side is the value or calculation. `price * quantity` is not a storage place, so nothing can be stored in it.

**Error 3: Forgetting the quotes around text.**

```text
// Wrong
output(Total: , total)

// Correct
output("Total: ", total)
```

Without quotes, `Total:` looks like a variable name, and there is no variable called `Total:`. Text that should be displayed exactly as written always goes inside double quotes. Names without quotes are replaced by the values they hold.

---

## 8. Exercises

Write each algorithm in full notation, with a header, a Dictionary, and an Algorithm section.

**Exercise 1:** Write an algorithm that reads the length and width of a rectangle (whole numbers) and displays its area and perimeter. The perimeter is 2 x (length + width).

**Exercise 2:** Write an algorithm that reads a number of minutes (a whole number) and displays it as hours and minutes. For example, 135 minutes is 2 hours and 15 minutes. Use `div` and `mod`.

**Exercise 3:** Write an algorithm that reads the radius of a circle and displays its area, using a constant `PI` with the value 3.14159. Then trace it with a radius of 10.

---

## 9. Solutions

**Solution for Exercise 1:**

```text
Program RectangleAreaPerimeter
{ Reads the length and width of a rectangle and displays its area and perimeter }

Dictionary
    length, width, area, perimeter : integer

Algorithm
    input(length)
    input(width)
    area <- length * width
    perimeter <- 2 * (length + width)
    output("Area: ", area)
    output("Perimeter: ", perimeter)
```

All four values are whole numbers, so they share the `integer` type on one line. The parentheses in the perimeter formula make sure the length and width are added before multiplying by 2.

**Solution for Exercise 2:**

```text
Program MinutesToHours
{ Converts a number of minutes into hours and remaining minutes }

Dictionary
    totalMinutes, hours, minutes : integer

Algorithm
    input(totalMinutes)
    hours <- totalMinutes div 60
    minutes <- totalMinutes mod 60
    output(totalMinutes, " minutes = ", hours, " hours ", minutes, " minutes")
```

`div` keeps only the whole part of the division, so `135 div 60` is 2. `mod` gives what is left over, so `135 mod 60` is 15. The output displays `135 minutes = 2 hours 15 minutes`. This pair of operators is the standard way to split a quantity into larger and smaller units.

**Solution for Exercise 3:**

```text
Program CircleArea
{ Reads the radius of a circle and displays its area }

Dictionary
    constant PI : real = 3.14159
    radius, area : real

Algorithm
    input(radius)
    area <- PI * radius * radius
    output("Area: ", area)
```

| Step | radius | area | Output |
| --- | --- | --- | --- |
| `input(radius)` | 10 | | |
| `area <- PI * radius * radius` | 10 | 314.159 | |
| `output("Area: ", area)` | 10 | 314.159 | Area: 314.159 |

`PI` never changes, so it is a constant. The radius and the area can both have decimals, so they are `real`. The trace confirms that a circle with radius 10 has an area of 314.159.

---

## Next Up - Lesson 3

In this lesson you learned the three-part layout of algorithmic notation: the Program header that names the algorithm, the Dictionary that declares every variable and constant with its type, and the Algorithm section that lists the steps. You used `<-` to assign values, `input()` to read data, and `output()` to display results, and you traced a notation algorithm with a table built from its Dictionary.

Your algorithms are ready; now it is time to make a computer run them. In Lesson 3 you will install JDK 21, write and run your first Java program from the terminal, and translate a notation algorithm into a complete Java program, seeing how each part of the notation has a matching part in Java.
