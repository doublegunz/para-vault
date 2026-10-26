## 1. Before You Begin

In Lesson 3 you translated your first algorithm into Java. Every variable in that program was an `integer`, which in Java is `int`. Real programs deal with many kinds of data: names, prices with decimals, single letters, and yes or no answers. Choosing the right kind of storage for each piece of data is one of the first decisions you make when designing an algorithm.

This lesson takes a closer look at the Dictionary section of your algorithms. You will learn what a variable really is, how to choose a data type, how to declare constants for values that never change, and how each notation type maps to a Java type. You will also meet your first classic algorithm: swapping the values of two variables.

### What You'll Build

Several small Java programs in a `lesson-04` folder: a student profile that uses five different data types, a program that shows a variable changing over time, a swap algorithm, and a circle calculator that uses a constant.

### What You'll Learn

- ✅ What a variable is: a name, a type, and a value
- ✅ How to choose between `integer`, `real`, `character`, `boolean`, and `string`
- ✅ How notation types map to Java's `int`, `double`, `char`, `boolean`, and `String`
- ✅ How to declare a variable and give it a first value on the same line
- ✅ How to declare constants with `constant` in notation and `final` in Java
- ✅ The rules and conventions for naming variables
- ✅ How to swap two values using a temporary variable
- ✅ When to use `long` instead of `int`

### What You'll Need

- Lesson 3 completed, with JDK 21 installed and working
- The `~/java-basics` folder from Lesson 3
- A text editor

Create the folder for this lesson before you begin:

```bash
mkdir -p ~/java-basics/lesson-04
cd ~/java-basics/lesson-04
```

---

## 2. Variables and Data Types

A **variable** is a named storage place in the computer's memory. You can picture it as a labeled box: the label is the variable's **name**, the shape of the box is its **type**, and whatever is inside the box is its **value**. A box shaped for whole numbers cannot hold text, just as a box shaped for text cannot hold a true or false answer.

Every variable has these three parts:

| Part | Meaning | Example |
| --- | --- | --- |
| Name | How the algorithm refers to the variable | `age` |
| Type | What kind of value it can hold | `integer` |
| Value | What it currently holds | `19` |

The name and the type are fixed when you declare the variable. The value can change while the program runs, which is why it is called a *variable*.

### Step 1: Map the Notation Types to Java

Lesson 2 introduced five basic types for notation. Each one has a direct match in Java:

| Notation | Java | Holds | Java example |
| --- | --- | --- | --- |
| `integer` | `int` | Whole numbers | `int age = 19;` |
| `real` | `double` | Numbers with a decimal part | `double height = 170.5;` |
| `character` | `char` | One character, in single quotes | `char bloodType = 'O';` |
| `boolean` | `boolean` | `true` or `false` | `boolean isActive = true;` |
| `string` | `String` | Text, in double quotes | `String name = "Budi";` |

Notice that `String` starts with a capital letter while the others are lowercase. This is not a typo. The first four are Java's **primitive types**, simple values built into the language. `String` is a **class**, a more complex type provided by Java's standard library. You will learn more about strings in Lesson 17; for now, just remember the capital S.

### Step 2: Write an Algorithm That Uses Every Type

**Problem:** Store a student's name, age, height, blood type, and whether they are an active student, then display all of it.

Start with the notation. Choosing each type is a small design decision:

```text
Program StudentProfile
{ Stores and displays a student's profile using different data types }

Dictionary
    name      : string
    age       : integer
    height    : real
    bloodType : character
    isActive  : boolean

Algorithm
    name <- "Budi Santoso"
    age <- 19
    height <- 170.5
    bloodType <- 'O'
    isActive <- true
    output("Name       : ", name)
    output("Age        : ", age)
    output("Height (cm): ", height)
    output("Blood type : ", bloodType)
    output("Active     : ", isActive)
```

A name is text, so it is a `string`. Age is counted in whole years, so it is an `integer`. Height can have a decimal part, so it is `real`. A blood type such as O, A, or B is a single letter, so it is a `character`. "Is this student active?" is a yes or no question, so it is a `boolean`. The extra spaces inside the labels line up the colons so the output is easy to read.

### Step 3: Translate It into Java

Create `StudentProfile.java`:

```java
// Program StudentProfile
// Stores and displays a student's profile using different data types.
public class StudentProfile {
    public static void main(String[] args) {
        // Dictionary
        String name;
        int age;
        double height;
        char bloodType;
        boolean isActive;

        // Algorithm
        name = "Budi Santoso";
        age = 19;
        height = 170.5;
        bloodType = 'O';
        isActive = true;
        System.out.println("Name       : " + name);
        System.out.println("Age        : " + age);
        System.out.println("Height (cm): " + height);
        System.out.println("Blood type : " + bloodType);
        System.out.println("Active     : " + isActive);
    }
}
```

The Dictionary block declares five variables, each with the Java type from the table in Step 1. In Java, the type comes *first* and the name second (`int age;`), while notation writes the name first (`age : integer`). The Algorithm block assigns a value to each variable, using double quotes for the `String`, single quotes for the `char`, and no quotes for the numbers and the boolean. Each `println` joins a label with a value using `+`; Java automatically converts numbers, characters, and booleans to text when you join them with a string.

Compile and run it:

```bash
javac StudentProfile.java
java StudentProfile
```

Output:

```text
Name       : Budi Santoso
Age        : 19
Height (cm): 170.5
Blood type : O
Active     : true
```

Every value is displayed in a form that matches its type: the text as text, the decimal number with its decimal point, and the boolean as the word `true`.

---

## 3. Declaring, Initializing, and Changing Values

So far you have declared variables first and assigned values later. Java also lets you do both in one line, and you will usually see code written that way.

### Step 1: Declare and Initialize in One Line

Giving a variable its first value is called **initializing** it. In notation, you can show a starting value in the Dictionary with `=`; in Java, you write the value right after the declaration:

```text
Dictionary
    score : integer = 70
```

```java
int score = 70;
```

Both mean: "create a variable named `score` of type integer, and start it with the value 70." This is shorter and also safer, because a variable that always starts with a known value cannot accidentally be used while empty.

### Step 2: Change a Variable's Value

A variable can receive new values as many times as needed. Each new assignment replaces the old value completely.

```text
Program ChangingValues
{ Shows that a variable can hold different values over time }

Dictionary
    score : integer = 70

Algorithm
    output("Starting score: ", score)
    score <- 85
    output("After the retake: ", score)
    score <- score + 5
    output("After the bonus: ", score)
```

Create `ChangingValues.java`:

```java
// Program ChangingValues
// Shows that a variable can hold different values over time.
public class ChangingValues {
    public static void main(String[] args) {
        // Dictionary
        int score = 70;

        // Algorithm
        System.out.println("Starting score: " + score);
        score = 85;
        System.out.println("After the retake: " + score);
        score = score + 5;
        System.out.println("After the bonus: " + score);
    }
}
```

The variable starts at 70. `score = 85;` replaces 70 with 85; the old value is gone. `score = score + 5;` is the interesting line: Java first calculates the right side using the *current* value (85 + 5 = 90) and then stores the result back in `score`. This is the `x <- x + 1` idea from Lesson 2, and it is how programs count, add up totals, and keep track of changing data.

```bash
javac ChangingValues.java
java ChangingValues
```

Output:

```text
Starting score: 70
After the retake: 85
After the bonus: 90
```

### Step 3: Swap Two Values

Here is your first classic algorithm. **Problem:** two variables, `a` and `b`, hold 10 and 25. Exchange their values so that `a` holds 25 and `b` holds 10.

A tempting first attempt is:

```text
a <- b
b <- a
```

Trace it: after `a <- b`, both `a` and `b` hold 25, and the original 10 has been overwritten and lost. The second line then copies 25 back into `b`. Both variables end up as 25. The fix is to save one value in a **temporary variable** before overwriting it, the same way you would need an empty third glass to swap the drinks in two full glasses:

```text
Program SwapValues
{ Swaps the values of two variables using a temporary variable }

Dictionary
    a    : integer = 10
    b    : integer = 25
    temp : integer

Algorithm
    output("Before: a = ", a, ", b = ", b)
    temp <- a
    a <- b
    b <- temp
    output("After : a = ", a, ", b = ", b)
```

| Step | a | b | temp |
| --- | --- | --- | --- |
| Start | 10 | 25 | |
| `temp <- a` | 10 | 25 | 10 |
| `a <- b` | 25 | 25 | 10 |
| `b <- temp` | 25 | 10 | 10 |

The trace shows that the original value of `a` survives in `temp` while `a` is overwritten. Now create `SwapValues.java`:

```java
// Program SwapValues
// Swaps the values of two variables using a temporary variable.
public class SwapValues {
    public static void main(String[] args) {
        // Dictionary
        int a = 10;
        int b = 25;
        int temp;

        // Algorithm
        System.out.println("Before: a = " + a + ", b = " + b);
        temp = a;
        a = b;
        b = temp;
        System.out.println("After : a = " + a + ", b = " + b);
    }
}
```

The three assignment lines are exactly the three middle lines of the notation. `temp` is declared without a starting value because the algorithm always assigns it before using it.

```bash
javac SwapValues.java
java SwapValues
```

Output:

```text
Before: a = 10, b = 25
After : a = 25, b = 10
```

The output matches the last row of the tracing table. You will use this swap again in Lesson 20, where sorting algorithms swap values thousands of times to put a list in order.

---

## 4. Constants

Some values should never change while a program runs: the value of pi, the number of minutes in an hour, a fixed tax rate. Declaring them as **constants** protects them from being changed by mistake and gives them meaningful names.

### Step 1: Declare a Constant

In notation, a constant uses the `constant` keyword. In Java, it uses the `final` keyword, which means "this value is final and cannot be reassigned":

```text
Dictionary
    constant PI : real = 3.14159
```

```java
final double PI = 3.14159;
```

By convention, both notation and Java write constant names in capital letters, with underscores between words, such as `TAX_RATE` or `MAX_STUDENTS`. This makes constants easy to spot in a long program.

### Step 2: Use a Constant in a Calculation

**Problem:** Calculate the area and circumference of a circle with a radius of 7.

```text
Program CircleArea
{ Calculates the area and circumference of a circle with a fixed radius }

Dictionary
    constant PI : real = 3.14159
    radius : real = 7.0
    area, circumference : real

Algorithm
    area <- PI * radius * radius
    circumference <- 2 * PI * radius
    output("Radius       : ", radius)
    output("Area         : ", area)
    output("Circumference: ", circumference)
```

Create `CircleArea.java`:

```java
// Program CircleArea
// Calculates the area and circumference of a circle with a fixed radius.
public class CircleArea {
    public static void main(String[] args) {
        // Dictionary
        final double PI = 3.14159;
        double radius = 7.0;
        double area;
        double circumference;

        // Algorithm
        area = PI * radius * radius;
        circumference = 2 * PI * radius;
        System.out.println("Radius       : " + radius);
        System.out.println("Area         : " + area);
        System.out.println("Circumference: " + circumference);
    }
}
```

`PI` is declared with `final`, so any later attempt to assign it a new value is rejected by the compiler. The radius is written as `7.0` to make it clear that it is a `double`; Java would also accept `7` and convert it, but writing the decimal point shows your intent. Both formulas read just like the notation.

```bash
javac CircleArea.java
java CircleArea
```

Output:

```text
Radius       : 7.0
Area         : 153.93791
Circumference: 43.98226
```

Java displays a `double` with at least one digit after the decimal point, which is why the radius appears as `7.0`. In Lesson 6 you will learn to control how many decimal places are displayed.

---

## 5. Run and Test

Two more ideas complete your picture of variables: naming rules and number sizes. Test both with the checks below.

### Naming Variables

Java has a few strict rules for names, and a few conventions that every Java programmer follows:

| Rule or convention | Good | Not allowed or not recommended |
| --- | --- | --- |
| Start with a letter | `total`, `score2` | `2score` (starts with a digit) |
| No spaces or symbols except `_` and `$` | `totalPrice` | `total price`, `total-price` |
| Not a Java keyword | `classCount` | `class`, `int`, `public` |
| Variables use camelCase | `bloodType`, `isActive` | `BloodType`, `bloodtype` |
| Constants use UPPER_CASE | `TAX_RATE` | `taxRate` (for a constant) |
| Names describe the value | `price`, `quantity` | `x`, `data1` |

**camelCase** means writing the first word in lowercase and starting each following word with a capital letter, like the humps of a camel: `totalPrice`, `numberOfStudents`. Booleans often start with `is` or `has`, like `isActive` or `hasPaid`, so they read like a yes or no question.

To test the rules, try changing `int age;` in `StudentProfile.java` to `int 2age;` and compile. The compiler rejects it. Change it back before moving on.

### Number Sizes: int and long

An `int` cannot hold every whole number. Its largest value is 2,147,483,647, a little over two billion. For bigger whole numbers, such as the world's population, Java has `long`. Create `BigNumbers.java`:

```java
// Program BigNumbers
// Compares the limits of int and long.
public class BigNumbers {
    public static void main(String[] args) {
        // Dictionary
        int largestInt = 2147483647;
        long worldPopulation = 8100000000L;

        // Algorithm
        System.out.println("Largest int     : " + largestInt);
        System.out.println("World population: " + worldPopulation);
    }
}
```

The `L` at the end of `8100000000L` tells Java that this number is a `long`. Without it, Java treats the number as an `int` and reports that it is too large.

```bash
javac BigNumbers.java
java BigNumbers
```

Output:

```text
Largest int     : 2147483647
World population: 8100000000
```

Java has a few other number types (`byte`, `short`, and `float`), but `int` for whole numbers, `long` for very large whole numbers, and `double` for decimals cover everything in this course.

---

## 6. Fix the Errors in Your Code

Type mistakes are caught by the compiler before the program runs. That is one of Java's strengths: many bugs never reach the user.

**Error 1: Storing a decimal in an `int`.**

```java
// Wrong
public class Quantity {
    public static void main(String[] args) {
        int quantity = 2.5;
        System.out.println(quantity);
    }
}

// Correct
public class Quantity {
    public static void main(String[] args) {
        double quantity = 2.5;
        System.out.println(quantity);
    }
}
```

The wrong version produces:

```text
Quantity.java:3: error: incompatible types: possible lossy conversion from double to int
        int quantity = 2.5;
                       ^
1 error
```

An `int` has no room for the `.5`, and Java refuses to throw part of your data away silently ("lossy conversion"). If the value can have decimals, declare it as `double`. If it really should be a whole number, fix the value instead.

**Error 2: Using a variable before giving it a value.**

```java
// Wrong
public class Total {
    public static void main(String[] args) {
        int total;
        System.out.println("Total: " + total);
    }
}

// Correct
public class Total {
    public static void main(String[] args) {
        int total = 0;
        System.out.println("Total: " + total);
    }
}
```

The wrong version produces:

```text
Total.java:4: error: variable total might not have been initialized
        System.out.println("Total: " + total);
                                       ^
1 error
```

Declaring a variable creates the box but puts nothing in it. Java will not let you read an empty box. Initialize the variable when you declare it, or assign it before the line that uses it.

**Error 3: Changing a constant.**

```java
// Wrong
public class Tax {
    public static void main(String[] args) {
        final double TAX_RATE = 0.11;
        TAX_RATE = 0.12;
        System.out.println(TAX_RATE);
    }
}

// Correct
public class Tax {
    public static void main(String[] args) {
        final double TAX_RATE = 0.12;
        System.out.println(TAX_RATE);
    }
}
```

The wrong version produces:

```text
Tax.java:4: error: cannot assign a value to final variable TAX_RATE
        TAX_RATE = 0.12;
        ^
1 error
```

This error is the constant doing its job. If the value truly needs to change while the program runs, it should be a normal variable, not a constant. If the rate changed for good, update the value where the constant is declared.

---

## 7. Exercises

**Exercise 1:** Write the notation and the Java program `BookInfo` that stores a book's title, author, number of pages, price, and whether it is available, then displays them. Choose a suitable type for each value.

**Exercise 2:** Three variables hold `a = 1`, `b = 2`, and `c = 3`. Write the notation and the Java program `RotateValues` that rotates them so that `a` gets the value of `b`, `b` gets the value of `c`, and `c` gets the original value of `a`. Trace your algorithm with a table first.

**Exercise 3:** Write the notation and the Java program `SecondsInWeek` that calculates the number of seconds in one week. Use a constant for each fixed value: seconds per minute, minutes per hour, hours per day, and days per week.

---

## 8. Solutions

**Solution for Exercise 1:**

```text
Program BookInfo
{ Stores and displays information about a book }

Dictionary
    title       : string = "Learning Algorithms"
    author      : string = "Siti Rahma"
    pages       : integer = 320
    price       : real = 89500.0
    isAvailable : boolean = false

Algorithm
    output("Title    : ", title)
    output("Author   : ", author)
    output("Pages    : ", pages)
    output("Price    : ", price)
    output("Available: ", isAvailable)
```

```java
// Program BookInfo
// Stores and displays information about a book.
public class BookInfo {
    public static void main(String[] args) {
        // Dictionary
        String title = "Learning Algorithms";
        String author = "Siti Rahma";
        int pages = 320;
        double price = 89500.0;
        boolean isAvailable = false;

        // Algorithm
        System.out.println("Title    : " + title);
        System.out.println("Author   : " + author);
        System.out.println("Pages    : " + pages);
        System.out.println("Price    : " + price);
        System.out.println("Available: " + isAvailable);
    }
}
```

The title and author are text (`String`), pages are counted in whole numbers (`int`), a price can include decimals (`double`), and availability is a yes or no answer (`boolean`). Every variable is initialized in its declaration, so the Algorithm section only has to display them.

```bash
javac BookInfo.java
java BookInfo
```

Output:

```text
Title    : Learning Algorithms
Author   : Siti Rahma
Pages    : 320
Price    : 89500.0
Available: false
```

**Solution for Exercise 2:**

```text
Program RotateValues
{ Rotates three values: a takes b, b takes c, and c takes the old a }

Dictionary
    a    : integer = 1
    b    : integer = 2
    c    : integer = 3
    temp : integer

Algorithm
    output("Before: a = ", a, ", b = ", b, ", c = ", c)
    temp <- a
    a <- b
    b <- c
    c <- temp
    output("After : a = ", a, ", b = ", b, ", c = ", c)
```

| Step | a | b | c | temp |
| --- | --- | --- | --- | --- |
| Start | 1 | 2 | 3 | |
| `temp <- a` | 1 | 2 | 3 | 1 |
| `a <- b` | 2 | 2 | 3 | 1 |
| `b <- c` | 2 | 3 | 3 | 1 |
| `c <- temp` | 2 | 3 | 1 | 1 |

```java
// Program RotateValues
// Rotates three values: a takes b, b takes c, and c takes the old a.
public class RotateValues {
    public static void main(String[] args) {
        // Dictionary
        int a = 1;
        int b = 2;
        int c = 3;
        int temp;

        // Algorithm
        System.out.println("Before: a = " + a + ", b = " + b + ", c = " + c);
        temp = a;
        a = b;
        b = c;
        c = temp;
        System.out.println("After : a = " + a + ", b = " + b + ", c = " + c);
    }
}
```

This is the swap algorithm extended to three variables. Only one value is at risk of being lost (the original `a`, which is overwritten first), so one temporary variable is enough. After that, each variable copies from the next one, and `c` finally takes the saved value.

```bash
javac RotateValues.java
java RotateValues
```

Output:

```text
Before: a = 1, b = 2, c = 3
After : a = 2, b = 3, c = 1
```

**Solution for Exercise 3:**

```text
Program SecondsInWeek
{ Calculates the number of seconds in one week using constants }

Dictionary
    constant SECONDS_PER_MINUTE : integer = 60
    constant MINUTES_PER_HOUR   : integer = 60
    constant HOURS_PER_DAY      : integer = 24
    constant DAYS_PER_WEEK      : integer = 7
    secondsPerWeek : integer

Algorithm
    secondsPerWeek <- SECONDS_PER_MINUTE * MINUTES_PER_HOUR * HOURS_PER_DAY * DAYS_PER_WEEK
    output("Seconds in one week: ", secondsPerWeek)
```

```java
// Program SecondsInWeek
// Calculates the number of seconds in one week using constants.
public class SecondsInWeek {
    public static void main(String[] args) {
        // Dictionary
        final int SECONDS_PER_MINUTE = 60;
        final int MINUTES_PER_HOUR = 60;
        final int HOURS_PER_DAY = 24;
        final int DAYS_PER_WEEK = 7;
        int secondsPerWeek;

        // Algorithm
        secondsPerWeek = SECONDS_PER_MINUTE * MINUTES_PER_HOUR * HOURS_PER_DAY * DAYS_PER_WEEK;
        System.out.println("Seconds in one week: " + secondsPerWeek);
    }
}
```

Compare the calculation with `60 * 60 * 24 * 7`. Both give the same result, but the version with named constants explains itself: anyone reading it can see what each number means without guessing.

```bash
javac SecondsInWeek.java
java SecondsInWeek
```

Output:

```text
Seconds in one week: 604800
```

---

## Next Up - Lesson 5

In this lesson you learned that a variable has a name, a type, and a value, and you mapped the five notation types to Java's `int`, `double`, `char`, `boolean`, and `String`. You declared and initialized variables, changed their values over time, protected fixed values with constants, and wrote your first classic algorithm, the swap with a temporary variable.

Your programs already do some arithmetic, but there is much more to expressions than `+` and `*`. In Lesson 5 you will work with all the arithmetic operators, including the tricky integer division and remainder, compare values with relational operators, combine conditions with logical operators, and learn the precedence rules that decide which part of an expression is calculated first.
