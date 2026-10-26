## 1. Before You Begin

With sequence, selection, and repetition, you can already solve any problem a computer can solve. But as problems grow, so do algorithms, and a single long list of steps becomes hard to read, hard to test, and full of repeated code. Look back at Lesson 11: several programs repeated the same validation loop, and a receipt program would print the same separator line many times.

The solution is to break a big algorithm into smaller, named pieces called **subprograms**. Each subprogram does one job, has a clear name, and can be used as many times as needed. This lesson introduces the first kind of subprogram, the **procedure**: a named group of steps that *does* something, such as displaying a header or drawing a line. In Java, a procedure becomes a `void` method.

### What You'll Build

A welcome screen that reuses a header procedure, a flexible line-drawing procedure, a shop receipt built from three procedures, and a program that prints several multiplication tables by calling one procedure in a loop.

### What You'll Learn

- ✅ What a procedure is and why breaking algorithms into pieces helps
- ✅ How to define a procedure in notation, with initial and final states
- ✅ How to call a procedure from the main algorithm
- ✅ How to pass data to a procedure through input parameters
- ✅ How to implement procedures in Java as `static void` methods
- ✅ What local variables are and where they exist
- ✅ Why changing a parameter inside a procedure does not change the caller's variable

### What You'll Need

- Lessons 7 to 11 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-12
cd ~/java-basics/lesson-12
```

---

## 2. Your First Procedure

A **procedure** is a named group of steps. You define it once, and then **call** it by name whenever you need those steps to run. When a procedure is called, the algorithm jumps into it, runs its steps, and then comes back to continue right after the call.

In notation, a procedure is defined with its own header, comments describing what it does, its own Dictionary, and its own Algorithm section:

```text
procedure PrintHeader
{ I.S.: - }
{ F.S.: the shop's header is displayed }

Dictionary
    { no local variables }

Algorithm
    output("=========================")
    output("     WARUNG QADR CAFE    ")
    output("=========================")
```

The two comments are a contract that describes the procedure from the outside:

- **I.S.** (Initial State) says what must be true *before* the procedure runs. A dash means nothing is required.
- **F.S.** (Final State) says what will be true *after* it runs.

Anyone who wants to use the procedure only needs to read its name, I.S., and F.S. They do not have to read the steps inside. This idea of using something without knowing how it works inside is called **abstraction**, and it is what makes large programs manageable.

### Step 1: Define and Call a Procedure

In a complete algorithm, the procedure is declared in the main program's Dictionary, called from the main Algorithm, and its full definition is written after the main program:

```text
Program WelcomeScreen
{ Displays a welcome screen using a procedure without parameters }

Dictionary
    procedure PrintHeader
    { displays the shop's header }

Algorithm
    PrintHeader
    output("Today's special: Fried Rice")
    PrintHeader

procedure PrintHeader
{ I.S.: - }
{ F.S.: the shop's header is displayed }

Dictionary
    { no local variables }

Algorithm
    output("=========================")
    output("     WARUNG QADR CAFE    ")
    output("=========================")
```

Calling the procedure is just writing its name. The main algorithm is now three lines long, and it reads like a description of what happens rather than how.

In Java, a procedure is a **method** whose return type is `void`, meaning it does not give back a value. Create `WelcomeScreen.java`:

```java
// Program WelcomeScreen
// Displays a welcome screen using a procedure without parameters.
public class WelcomeScreen {
    public static void main(String[] args) {
        // Algorithm
        printHeader();
        System.out.println("Today's special: Fried Rice");
        printHeader();
    }

    // Procedure PrintHeader
    // I.S.: -
    // F.S.: the shop's header is displayed
    static void printHeader() {
        System.out.println("=========================");
        System.out.println("     WARUNG QADR CAFE    ");
        System.out.println("=========================");
    }
}
```

Here is what is new:

- `static void printHeader() { ... }` defines the method. It sits inside the class but *outside* `main`, after `main`'s closing brace. `void` means it returns nothing; the empty parentheses mean it takes no data. For now, always write `static` before your methods; you will see what happens without it in Section 5.
- Java method names follow camelCase starting with a lowercase letter, so the notation's `PrintHeader` becomes `printHeader` in Java.
- `printHeader();` calls the method. The parentheses are required in Java, even when empty, and the call ends with a semicolon like any other statement.
- The I.S. and F.S. comments are copied above the method, so the contract stays with the code.

You have actually been writing a method since Lesson 3: `main` is a method too, the one Java calls automatically when the program starts.

```bash
javac WelcomeScreen.java
java WelcomeScreen
```

Output:

```text
=========================
     WARUNG QADR CAFE    
=========================
Today's special: Fried Rice
=========================
     WARUNG QADR CAFE    
=========================
```

The header appears twice, but its steps are written only once. If the shop changes its name, you update one place.

---

## 3. Procedures with Parameters

A procedure that always does exactly the same thing is useful, but limited. **Parameters** let the caller send data into a procedure, so the same steps can work with different values each time.

```text
procedure PrintLine(input length : integer, input symbol : character)
```

Each parameter has a name and a type, just like a variable in a Dictionary. The keyword `input` says the data flows *into* the procedure: the procedure reads the value but does not send anything back through it. Notation also has `output` and `input/output` parameters for sending values back, but Java does not support them for simple types, so this course returns values with **functions** instead, in Lesson 13.

When you call the procedure, you provide one value for each parameter, in the same order:

```text
PrintLine(10, '=')
```

The values in the call (`10` and `'='`) are called **arguments**. When the procedure starts, each parameter receives the matching argument: `length` gets 10 and `symbol` gets `'='`.

### Step 1: Draw Lines of Any Length

```text
Program LineDemo
{ Draws lines of different lengths and symbols with one procedure }

Dictionary
    procedure PrintLine(input length : integer, input symbol : character)
    { displays a line of length symbols }

Algorithm
    PrintLine(10, '=')
    PrintLine(20, '-')
    PrintLine(5, '*')

procedure PrintLine(input length : integer, input symbol : character)
{ I.S.: length >= 0 and symbol are defined }
{ F.S.: a line of length symbols is displayed }

Dictionary
    i : integer

Algorithm
    for i <- 1 to length do
        output(symbol)
    endfor
    output(new line)
```

The procedure has its own Dictionary with a variable `i`. Variables declared inside a procedure are **local variables**: they exist only while the procedure runs, and the main algorithm cannot see them. Parameters are local too.

Create `LineDemo.java`:

```java
// Program LineDemo
// Draws lines of different lengths and symbols with one procedure.
public class LineDemo {
    public static void main(String[] args) {
        // Algorithm
        printLine(10, '=');
        printLine(20, '-');
        printLine(5, '*');
    }

    // Procedure PrintLine
    // I.S.: length >= 0 and symbol are defined
    // F.S.: a line of length symbols is displayed
    static void printLine(int length, char symbol) {
        // Dictionary (local)
        int i;

        // Algorithm
        for (i = 1; i <= length; i++) {
            System.out.print(symbol);
        }
        System.out.println();
    }
}
```

In Java, each parameter is written as `type name`, separated by commas: `(int length, char symbol)`. There is no `input` keyword; every simple parameter in Java is an input parameter. The local variable `i` is declared at the start of the method body, which plays the role of the procedure's Dictionary.

```bash
javac LineDemo.java
java LineDemo
```

Output:

```text
==========
--------------------
*****
```

One procedure, three different lines. The procedure does not care where its values come from; they can be numbers written in the call, variables, or even expressions such as `printLine(n * 2, '#')`.

### Step 2: Build a Program from Several Procedures

**Problem:** Print a shop receipt. The user enters items until they type a quantity of 0. For each item, read the name and price, and print a row with the subtotal. At the end, print the total between separator lines.

Splitting the work into procedures makes the main algorithm short and readable:

```text
Program ShopReceipt
{ Reads items until the quantity is 0 and prints a receipt using procedures }

Dictionary
    name : string
    quantity, price, total : integer
    procedure PrintHeader(input title : string)
    procedure PrintItem(input name : string, input quantity : integer, input price : integer)
    procedure PrintLine(input length : integer, input symbol : character)

Algorithm
    total <- 0
    PrintHeader("WARUNG QADR CAFE")
    output("Quantity (0 to finish): ")
    input(quantity)
    while quantity <> 0 do
        output("Item name: ")
        input(name)
        output("Price    : ")
        input(price)
        PrintItem(name, quantity, price)
        total <- total + quantity * price
        output("Quantity (0 to finish): ")
        input(quantity)
    endwhile
    PrintLine(32, '-')
    output("TOTAL", total)
    PrintLine(32, '=')

procedure PrintHeader(input title : string)
{ I.S.: title is defined }
{ F.S.: title is displayed between two lines }
Algorithm
    PrintLine(32, '=')
    output(title)
    PrintLine(32, '=')

procedure PrintItem(input name : string, input quantity : integer, input price : integer)
{ I.S.: name, quantity, and price are defined }
{ F.S.: one receipt row with the subtotal is displayed }
Algorithm
    output(quantity, " x ", name, "  ", quantity * price)

procedure PrintLine(input length : integer, input symbol : character)
{ I.S.: length >= 0 and symbol are defined }
{ F.S.: a line of length symbols is displayed }
Dictionary
    i : integer
Algorithm
    for i <- 1 to length do
        output(symbol)
    endfor
    output(new line)
```

Notice that `PrintHeader` calls `PrintLine`. Procedures can call other procedures, so small, reliable pieces combine into bigger ones. Also notice that `PrintItem` has a parameter called `name`, and the main program has a variable called `name`. These are two different variables that happen to share a name; the parameter is local to the procedure.

Create `ShopReceipt.java`:

```java
import java.util.Scanner;

// Program ShopReceipt
// Reads items until the quantity is 0 and prints a receipt using procedures.
public class ShopReceipt {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String name;
        int quantity;
        int price;
        int total;

        // Algorithm
        total = 0;
        printHeader("WARUNG QADR CAFE");
        System.out.print("Quantity (0 to finish): ");
        quantity = input.nextInt();
        while (quantity != 0) {
            System.out.print("Item name: ");
            name = input.next();
            System.out.print("Price    : ");
            price = input.nextInt();
            printItem(name, quantity, price);
            total = total + quantity * price;
            System.out.print("Quantity (0 to finish): ");
            quantity = input.nextInt();
        }
        printLine(32, '-');
        System.out.printf("%-20s %11d%n", "TOTAL", total);
        printLine(32, '=');
    }

    // Procedure PrintHeader
    // I.S.: title is defined
    // F.S.: title is displayed between two lines
    static void printHeader(String title) {
        printLine(32, '=');
        System.out.println(title);
        printLine(32, '=');
    }

    // Procedure PrintItem
    // I.S.: name, quantity, and price are defined
    // F.S.: one receipt row with the subtotal is displayed
    static void printItem(String name, int quantity, int price) {
        System.out.printf("%2d x %-15s %11d%n", quantity, name, quantity * price);
    }

    // Procedure PrintLine
    // I.S.: length >= 0 and symbol are defined
    // F.S.: a line of length symbols is displayed
    static void printLine(int length, char symbol) {
        for (int i = 1; i <= length; i++) {
            System.out.print(symbol);
        }
        System.out.println();
    }
}
```

Each procedure is a separate `static void` method in the class, and the order of the methods does not matter to Java. The item name is read with `input.next()`, which reads a single word, because the quantity was read with `nextInt` just before it (remember the leftover end of line from Lesson 6). This means item names must be one word, such as `Coffee`. `printItem` uses `printf` widths so every row lines up.

```bash
javac ShopReceipt.java
java ShopReceipt
```

Output:

```text
================================
WARUNG QADR CAFE
================================
Quantity (0 to finish): 3
Item name: Coffee
Price    : 15000
 3 x Coffee                45000
Quantity (0 to finish): 2
Item name: Croissant
Price    : 18000
 2 x Croissant             36000
Quantity (0 to finish): 0
--------------------------------
TOTAL                      81000
================================
```

Read the `main` method again: it describes *what* the receipt does, step by step, while the details of formatting are hidden inside the procedures. That is the main benefit of procedures: each piece can be understood, tested, and changed on its own.

---

## 4. Run and Test

Procedures shine when they are called repeatedly with different arguments, for example from inside a loop. **Problem:** Read a number `last` and print the first five multiples of every number from 1 to `last`, one table per line.

```text
Program TablePrinter
{ Prints the multiplication tables from 1 up to a chosen number }

Dictionary
    last, n : integer
    procedure PrintTable(input n : integer, input count : integer)

Algorithm
    output("Print tables up to: ")
    input(last)
    for n <- 1 to last do
        PrintTable(n, 5)
    endfor

procedure PrintTable(input n : integer, input count : integer)
{ I.S.: n and count are defined, count >= 1 }
{ F.S.: the first count multiples of n are displayed on one line }
Dictionary
    i : integer
Algorithm
    output("Table of ", n, ":")
    for i <- 1 to count do
        output(n * i)
    endfor
    output(new line)
```

The main loop calls `PrintTable` once per round, with a different `n` each time. The procedure has its own loop inside. Without the procedure, this would be a nested loop; with it, each loop lives in its own clearly named place.

Create `TablePrinter.java`:

```java
import java.util.Scanner;

// Program TablePrinter
// Prints the multiplication tables from 1 up to a chosen number.
public class TablePrinter {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int last;

        // Algorithm
        System.out.print("Print tables up to: ");
        last = input.nextInt();
        for (int n = 1; n <= last; n++) {
            printTable(n, 5);
        }
    }

    // Procedure PrintTable
    // I.S.: n and count are defined, count >= 1
    // F.S.: the first count multiples of n are displayed on one line
    static void printTable(int n, int count) {
        System.out.print("Table of " + n + ":");
        for (int i = 1; i <= count; i++) {
            System.out.printf("%4d", n * i);
        }
        System.out.println();
    }
}
```

`%4d` gives each multiple four characters of space, so the columns line up.

```bash
javac TablePrinter.java
java TablePrinter
```

Output:

```text
Print tables up to: 4
Table of 1:   1   2   3   4   5
Table of 2:   2   4   6   8  10
Table of 3:   3   6   9  12  15
Table of 4:   4   8  12  16  20
```

Each line is one call to `printTable`. To test the procedure on its own, you could also call it directly from `main` with values like `printTable(7, 10)` and check that it prints the first ten multiples of 7. Testing small pieces separately is much easier than testing a whole program at once.

---

## 5. Fix the Errors in Your Code

**Error 1: Arguments that do not match the parameters.**

The arguments must match the parameters in number, order, and type.

```java
// Wrong
public class WrongArgs {
    public static void main(String[] args) {
        printLine(10);
    }

    static void printLine(int length, char symbol) {
        for (int i = 1; i <= length; i++) {
            System.out.print(symbol);
        }
        System.out.println();
    }
}

// Correct
public class WrongArgs {
    public static void main(String[] args) {
        printLine(10, '=');
    }

    static void printLine(int length, char symbol) {
        for (int i = 1; i <= length; i++) {
            System.out.print(symbol);
        }
        System.out.println();
    }
}
```

The wrong version produces:

```text
WrongArgs.java:3: error: method printLine in class WrongArgs cannot be applied to given types;
        printLine(10);
        ^
  required: int,char
  found:    int
  reason: actual and formal argument lists differ in length
1 error
```

The message lists what the method requires (`int,char`) and what the call provided (`int`). Swapping the order, as in `printLine('=', 10)`, also fails, with a different message:

```text
WrongArgs.java:3: error: incompatible types: possible lossy conversion from int to char
        printLine('=', 10);
                       ^
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
1 error
```

Java matches arguments to parameters by position, not by name. The second argument, `10`, is being given to the `char` parameter. Check the procedure's header and pass the values in the same order.

**Error 2: Forgetting `static`.**

```java
// Wrong
public class NoStatic {
    public static void main(String[] args) {
        printHello();
    }

    void printHello() {
        System.out.println("Hello!");
    }
}

// Correct
public class NoStatic {
    public static void main(String[] args) {
        printHello();
    }

    static void printHello() {
        System.out.println("Hello!");
    }
}
```

The wrong version produces:

```text
NoStatic.java:3: error: non-static method printHello() cannot be referenced from a static context
        printHello();
        ^
1 error
```

`main` is `static`, and a static method can only call other static methods directly. Methods without `static` belong to objects, a topic of object-oriented programming that is beyond this course. For now, mark every method you write with `static`.

**Error 3: Expecting a procedure to change the caller's variables.**

```java
// Wrong
public class SwapProcedure {
    public static void main(String[] args) {
        int a = 10;
        int b = 25;
        swap(a, b);
        System.out.println("After swap: a = " + a + ", b = " + b);
    }

    static void swap(int x, int y) {
        int temp = x;
        x = y;
        y = temp;
        System.out.println("Inside swap: x = " + x + ", y = " + y);
    }
}
```

This compiles and runs, but displays:

```text
Inside swap: x = 25, y = 10
After swap: a = 10, b = 25
```

The swap worked *inside* the procedure, but `a` and `b` in `main` did not change. When Java calls a method, each parameter receives a **copy** of the argument's value. This is called **pass by value**. Changing `x` changes the copy, not `a`. In notation terms, every Java parameter of a simple type is an `input` parameter.

The fix depends on what you need. If a subprogram should produce a result, make it a **function** that returns the value, which is the topic of Lesson 13. For a swap like this one, keep the three swap steps directly in the code that owns the variables, as you did in Lesson 4. (In Lesson 15 you will see that arrays behave differently, and a procedure *can* swap two elements of an array.)

---

## 6. Exercises

**Exercise 1:** Write the notation and the Java program `StarBox` with a procedure `PrintBox(input width : integer, input height : integer)` that draws a hollow rectangle of stars: stars on the border, spaces inside. Call it to draw a 6 by 4 box and a 3 by 3 box.

**Exercise 2:** Write the notation and the Java program `GradeCards` with a procedure `PrintGradeCard(input number : integer, input score : integer)` that displays a student's number, score, and letter grade (A: 85+, B: 70+, C: 55+, D: 40+, E: below 40). The main algorithm reads `n` and then reads a score for each student, calling the procedure after each one.

**Exercise 3:** Write the notation and the Java program `CountdownProcedure` with a procedure `Countdown(input start : integer)` that displays the numbers from `start` down to 1 on one line, followed by "Go!". Call it with 5, 3, and 0.

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program StarBox
{ Draws hollow boxes of different sizes with a procedure }

Dictionary
    procedure PrintBox(input width : integer, input height : integer)

Algorithm
    PrintBox(6, 4)
    output(new line)
    PrintBox(3, 3)

procedure PrintBox(input width : integer, input height : integer)
{ I.S.: width >= 2 and height >= 2 }
{ F.S.: a hollow box of stars is displayed }
Dictionary
    row, col : integer
Algorithm
    for row <- 1 to height do
        for col <- 1 to width do
            if row = 1 or row = height or col = 1 or col = width then
                output("*")
            else
                output(" ")
            endif
        endfor
        output(new line)
    endfor
```

```java
// Program StarBox
// Draws hollow boxes of different sizes with a procedure.
public class StarBox {
    public static void main(String[] args) {
        // Algorithm
        printBox(6, 4);
        System.out.println();
        printBox(3, 3);
    }

    // Procedure PrintBox
    // I.S.: width >= 2 and height >= 2
    // F.S.: a hollow box of stars is displayed
    static void printBox(int width, int height) {
        for (int row = 1; row <= height; row++) {
            for (int col = 1; col <= width; col++) {
                if (row == 1 || row == height || col == 1 || col == width) {
                    System.out.print("*");
                } else {
                    System.out.print(" ");
                }
            }
            System.out.println();
        }
    }
}
```

The nested loops visit every position in the rectangle. A position is on the border if it is in the first or last row, or the first or last column, and only those positions get a star. All the drawing logic lives in the procedure, so `main` only decides which boxes to draw.

```bash
javac StarBox.java
java StarBox
```

Output:

```text
******
*    *
*    *
******

***
* *
***
```

**Solution for Exercise 2:**

```text
Program GradeCards
{ Reads scores for n students and prints a grade card for each one }

Dictionary
    n, i, score : integer
    procedure PrintGradeCard(input number : integer, input score : integer)

Algorithm
    output("How many students? ")
    input(n)
    for i <- 1 to n do
        output("Score of student ", i, ": ")
        input(score)
        PrintGradeCard(i, score)
    endfor

procedure PrintGradeCard(input number : integer, input score : integer)
{ I.S.: number and score (0-100) are defined }
{ F.S.: the student's score and letter grade are displayed }
Dictionary
    grade : character
Algorithm
    if score >= 85 then
        grade <- 'A'
    else if score >= 70 then
        grade <- 'B'
    else if score >= 55 then
        grade <- 'C'
    else if score >= 40 then
        grade <- 'D'
    else
        grade <- 'E'
    endif
    output("  Student ", number, " | score ", score, " | grade ", grade)
```

```java
import java.util.Scanner;

// Program GradeCards
// Reads scores for n students and prints a grade card for each one.
public class GradeCards {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        int score;

        // Algorithm
        System.out.print("How many students? ");
        n = input.nextInt();
        for (int i = 1; i <= n; i++) {
            System.out.print("Score of student " + i + ": ");
            score = input.nextInt();
            printGradeCard(i, score);
        }
    }

    // Procedure PrintGradeCard
    // I.S.: number and score (0-100) are defined
    // F.S.: the student's score and letter grade are displayed
    static void printGradeCard(int number, int score) {
        char grade;
        if (score >= 85) {
            grade = 'A';
        } else if (score >= 70) {
            grade = 'B';
        } else if (score >= 55) {
            grade = 'C';
        } else if (score >= 40) {
            grade = 'D';
        } else {
            grade = 'E';
        }
        System.out.println("  Student " + number + " | score " + score + " | grade " + grade);
    }
}
```

The else-if chain from Lesson 8 moved into a procedure, so the main loop stays simple. The loop variable `i` is passed as the `number` argument, and the procedure's local `grade` exists only during each call.

```bash
javac GradeCards.java
java GradeCards
```

Output:

```text
How many students? 3
Score of student 1: 92
  Student 1 | score 92 | grade A
Score of student 2: 67
  Student 2 | score 67 | grade C
Score of student 3: 38
  Student 3 | score 38 | grade E
```

**Solution for Exercise 3:**

```text
Program CountdownProcedure
{ Calls a countdown procedure with different starting values }

Dictionary
    procedure Countdown(input start : integer)

Algorithm
    Countdown(5)
    Countdown(3)
    Countdown(0)

procedure Countdown(input start : integer)
{ I.S.: start is defined }
{ F.S.: the numbers from start down to 1 and "Go!" are displayed on one line }
Dictionary
    i : integer
Algorithm
    for i <- start downto 1 do
        output(i, " ")
    endfor
    output("Go!")
```

```java
// Program CountdownProcedure
// Calls a countdown procedure with different starting values.
public class CountdownProcedure {
    public static void main(String[] args) {
        // Algorithm
        countdown(5);
        countdown(3);
        countdown(0);
    }

    // Procedure Countdown
    // I.S.: start is defined
    // F.S.: the numbers from start down to 1 and "Go!" are displayed on one line
    static void countdown(int start) {
        for (int i = start; i >= 1; i--) {
            System.out.print(i + " ");
        }
        System.out.println("Go!");
    }
}
```

The `downto` loop becomes a `for` loop with `i--`. Calling it with 0 tests the edge case: the loop runs zero times, and only "Go!" is displayed.

```bash
javac CountdownProcedure.java
java CountdownProcedure
```

Output:

```text
5 4 3 2 1 Go!
3 2 1 Go!
Go!
```

---

## Next Up - Lesson 13

In this lesson you learned to break an algorithm into procedures: named groups of steps with an I.S. and F.S. contract, their own local variables, and input parameters that let the same steps work with different data. You implemented them in Java as `static void` methods, called them from `main` and from each other, and saw that Java passes simple values by copy, so a procedure cannot change the caller's variables.

Procedures *do* things, but many subprograms need to *calculate* something and give the answer back, like the area of a circle or whether a year is a leap year. In Lesson 13 you will write **functions** that receive parameters and return a value, and implement them in Java as methods with a return type such as `int`, `double`, or `boolean`.
