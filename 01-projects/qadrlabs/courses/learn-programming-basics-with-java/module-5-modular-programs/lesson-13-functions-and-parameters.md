## 1. Before You Begin

In Lesson 12 you learned to package steps into procedures. A procedure *does* something: it displays a header, draws a line, or prints a receipt row. But many subprograms need to *calculate* something and hand the answer back: the area of a circle, the larger of two numbers, whether a year is a leap year. You saw in Lesson 12 that a procedure cannot send a value back through its parameters in Java. The tool for that job is a **function**.

A function receives values through its parameters, computes a result, and **returns** it to the caller. The caller can then store the result in a variable, display it, or use it inside a larger expression, exactly like a value. In this lesson you will define functions in notation, implement them in Java as methods with a return type, and use them to make your programs shorter and clearer. You will also implement two famous algorithms as functions: checking whether a number is prime, and Euclid's algorithm for the greatest common divisor.

### What You'll Build

A square function, area functions for circles and rectangles, a leap year function that powers a year-range report, a reusable `max` function, an input function that validates values, and a prime number lister.

### What You'll Learn

- ✅ The difference between a procedure and a function
- ✅ How to define a function in notation and return a value with `->`
- ✅ How to implement functions in Java with a return type and `return`
- ✅ How to use a function call inside expressions, conditions, and other calls
- ✅ How to write functions that return `double`, `boolean`, and `char`
- ✅ How to write a function that reads and validates input
- ✅ How to implement prime checking and Euclid's GCD algorithm

### What You'll Need

- Lesson 12 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-13
cd ~/java-basics/lesson-13
```

---

## 2. Your First Function

A function definition in notation looks like a procedure's, with two differences: the header says what type of value it returns, and the algorithm ends by returning a value.

```text
function Square(x : integer) -> integer
{ Returns x * x }

Dictionary
    { no local variables }

Algorithm
    -> x * x
```

The `-> integer` at the end of the header says that this function returns an integer. Inside the Algorithm section, `-> x * x` means "calculate `x * x` and return it to the caller." Function parameters are always input parameters, so the keyword `input` is left out. Instead of I.S. and F.S., a function's comment says what it returns.

| | Procedure | Function |
| --- | --- | --- |
| Purpose | Performs an action | Calculates and returns a value |
| Header in notation | `procedure Name(input x : type)` | `function Name(x : type) -> type` |
| Ends with | Its last step | `-> value` |
| Called as | A step on its own: `PrintLine(10, '=')` | Part of an expression: `y <- Square(5)` |
| Java return type | `void` | `int`, `double`, `boolean`, `char`, `String`, ... |

### Step 1: Define and Use a Function

A function call *is* a value, so it can go anywhere a value can go:

```text
Program SquareFunction
{ Uses a function that returns the square of a number }

Dictionary
    result : integer
    function Square(x : integer) -> integer

Algorithm
    result <- Square(5)
    output("square(5) = ", result)
    output("square(12) = ", Square(12))
    output("square(3) + square(4) = ", Square(3) + Square(4))
    output("square(square(2)) = ", Square(Square(2)))

function Square(x : integer) -> integer
{ Returns x * x }
Algorithm
    -> x * x
```

The first call stores the result in a variable. The second displays it directly. The third uses two calls in an addition. The fourth passes the result of one call as the argument of another: `Square(2)` is 4, and `Square(4)` is 16.

In Java, a function is a method whose return type is the type of value it gives back, and `return` plays the role of `->`. Create `SquareFunction.java`:

```java
// Program SquareFunction
// Uses a function that returns the square of a number.
public class SquareFunction {
    public static void main(String[] args) {
        // Dictionary
        int result;

        // Algorithm
        result = square(5);
        System.out.println("square(5) = " + result);
        System.out.println("square(12) = " + square(12));
        System.out.println("square(3) + square(4) = " + (square(3) + square(4)));
        System.out.println("square(square(2)) = " + square(square(2)));
    }

    // Function Square
    // Returns x * x
    static int square(int x) {
        return x * x;
    }
}
```

`static int square(int x)` declares a method named `square` that takes one `int` and returns an `int`. The word before the name, which was `void` for procedures, is now the **return type**. `return x * x;` calculates the value, ends the method immediately, and sends the value back to the place where the method was called. That call is then replaced by the returned value, so `result = square(5);` becomes `result = 25;`.

```bash
javac SquareFunction.java
java SquareFunction
```

Output:

```text
square(5) = 25
square(12) = 144
square(3) + square(4) = 25
square(square(2)) = 16
```

### Step 2: Return Real Values

Functions can return any type. **Problem:** Read the radius of a circle and the sides of a rectangle, then display each area and their total.

```text
Program Geometry
{ Calculates areas with functions that return real values }

Dictionary
    radius, length, width : real
    function CircleArea(r : real) -> real
    function RectangleArea(length : real, width : real) -> real

Algorithm
    output("Circle radius    : ")
    input(radius)
    output("Rectangle length : ")
    input(length)
    output("Rectangle width  : ")
    input(width)
    output("Circle area      : ", CircleArea(radius))
    output("Rectangle area   : ", RectangleArea(length, width))
    output("Total area       : ", CircleArea(radius) + RectangleArea(length, width))

function CircleArea(r : real) -> real
{ Returns the area of a circle with radius r }
Dictionary
    constant PI : real = 3.14159
Algorithm
    -> PI * r * r

function RectangleArea(length : real, width : real) -> real
{ Returns the area of a rectangle with sides length and width }
Algorithm
    -> length * width
```

The constant `PI` is declared inside `CircleArea`, because only that function needs it. Keeping data close to where it is used is a good habit.

Create `Geometry.java`:

```java
import java.util.Scanner;

// Program Geometry
// Calculates areas with functions that return real values.
public class Geometry {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        double radius;
        double length;
        double width;

        // Algorithm
        System.out.print("Circle radius    : ");
        radius = input.nextDouble();
        System.out.print("Rectangle length : ");
        length = input.nextDouble();
        System.out.print("Rectangle width  : ");
        width = input.nextDouble();
        System.out.printf("Circle area      : %.2f%n", circleArea(radius));
        System.out.printf("Rectangle area   : %.2f%n", rectangleArea(length, width));
        System.out.printf("Total area       : %.2f%n", circleArea(radius) + rectangleArea(length, width));
    }

    // Function CircleArea
    // Returns the area of a circle with radius r
    static double circleArea(double r) {
        final double PI = 3.14159;
        return PI * r * r;
    }

    // Function RectangleArea
    // Returns the area of a rectangle with sides length and width
    static double rectangleArea(double length, double width) {
        return length * width;
    }
}
```

Both functions return `double`. Their results are passed straight to `printf`. Notice that `main` never mentions pi or multiplication: it only says *what* is being calculated, and each function knows *how*.

```bash
javac Geometry.java
java Geometry
```

Output:

```text
Circle radius    : 7
Rectangle length : 8
Rectangle width  : 5
Circle area      : 153.94
Rectangle area   : 40.00
Total area       : 193.94
```

---

## 3. Functions as Building Blocks

Functions become truly powerful when you combine them: a boolean function becomes a condition, a small function becomes part of a bigger one, and a function can even handle input for you.

### Step 1: Write a Boolean Function

In Lesson 5 you wrote the leap year expression four times. A function lets you write it once and give it a name. **Problem:** Read a range of years and list the leap years in it.

```text
Program LeapYears
{ Lists the leap years in a range using a boolean function }

Dictionary
    start, end, year, count : integer
    function IsLeapYear(year : integer) -> boolean

Algorithm
    output("From year: ")
    input(start)
    output("To year  : ")
    input(end)
    count <- 0
    for year <- start to end do
        if IsLeapYear(year) then
            output(year, " ")
            count <- count + 1
        endif
    endfor
    output(count, " leap years found.")

function IsLeapYear(year : integer) -> boolean
{ Returns true if year is a leap year }
Algorithm
    -> (year mod 4 = 0 and year mod 100 <> 0) or year mod 400 = 0
```

A function that returns a `boolean` can be used directly as a condition. `if IsLeapYear(year) then` reads almost like English. Names that start with `Is` or `Has` make boolean functions easy to recognize.

Create `LeapYears.java`:

```java
import java.util.Scanner;

// Program LeapYears
// Lists the leap years in a range using a boolean function.
public class LeapYears {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int start;
        int end;
        int count;

        // Algorithm
        System.out.print("From year: ");
        start = input.nextInt();
        System.out.print("To year  : ");
        end = input.nextInt();
        count = 0;
        for (int year = start; year <= end; year++) {
            if (isLeapYear(year)) {
                System.out.print(year + " ");
                count = count + 1;
            }
        }
        System.out.println();
        System.out.println(count + " leap years found.");
    }

    // Function IsLeapYear
    // Returns true if year is a leap year
    static boolean isLeapYear(int year) {
        return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    }
}
```

The function returns the value of the boolean expression directly. There is no need for `if (...) return true; else return false;`; the expression already *is* true or false.

```bash
javac LeapYears.java
java LeapYears
```

Output:

```text
From year: 1896
To year  : 1912
1896 1904 1908 1912 
4 leap years found.
```

The range includes 1900, which is divisible by 4 but not a leap year, and the function correctly skips it.

### Step 2: Combine Functions

**Problem:** Find the largest of three numbers. In Lesson 8 you solved this with nested `if` statements. With a function that finds the larger of *two* numbers, the three-number version becomes a single line.

```text
Program MaxFunctions
{ Finds the largest of three numbers by reusing a two-number max function }

Dictionary
    a, b, c : integer
    function Max(x : integer, y : integer) -> integer

Algorithm
    output("Enter three integers: ")
    input(a, b, c)
    output("Largest of the first two: ", Max(a, b))
    output("Largest of all three    : ", Max(Max(a, b), c))

function Max(x : integer, y : integer) -> integer
{ Returns the larger of x and y }
Algorithm
    if x > y then
        -> x
    else
        -> y
    endif
```

`Max(Max(a, b), c)` first finds the larger of `a` and `b`, then compares that winner with `c`. The function itself has two `->` steps, one in each branch. Only one of them runs, and the function ends as soon as it returns.

Create `MaxFunctions.java`:

```java
import java.util.Scanner;

// Program MaxFunctions
// Finds the largest of three numbers by reusing a two-number max function.
public class MaxFunctions {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int a;
        int b;
        int c;

        // Algorithm
        System.out.print("Enter three integers: ");
        a = input.nextInt();
        b = input.nextInt();
        c = input.nextInt();
        System.out.println("Largest of the first two: " + max(a, b));
        System.out.println("Largest of all three    : " + max(max(a, b), c));
    }

    // Function Max
    // Returns the larger of x and y
    static int max(int x, int y) {
        if (x > y) {
            return x;
        } else {
            return y;
        }
    }
}
```

```bash
javac MaxFunctions.java
java MaxFunctions
```

Output:

```text
Enter three integers: 4 9 2
Largest of the first two: 9
Largest of all three    : 9
```

Building bigger solutions from small, tested functions is one of the most important skills in programming. Once `max` is known to be correct, any program built from it starts on solid ground.

### Step 3: Read and Validate Input with a Function

In Lesson 11 you wrote the same validation loop several times. A function can hold it once and return the valid value. **Problem:** Read the number of students (1 to 50) and a score for each (0 to 100), then display each student's letter grade.

```text
Program GradeFunctions
{ Reads valid scores with a function and converts them to grades with another function }

Dictionary
    n, i, score : integer
    function ReadInRange(prompt : string, low : integer, high : integer) -> integer
    function LetterGrade(score : integer) -> character

Algorithm
    n <- ReadInRange("How many students? ", 1, 50)
    for i <- 1 to n do
        score <- ReadInRange("Score of student " + i + ": ", 0, 100)
        output("  Grade: ", LetterGrade(score))
    endfor

function ReadInRange(prompt : string, low : integer, high : integer) -> integer
{ Asks with prompt until the user types an integer from low to high, then returns it }
Dictionary
    value : integer
Algorithm
    repeat
        output(prompt)
        input(value)
        if value < low or value > high then
            output("  Please enter a number from ", low, " to ", high, ".")
        endif
    until value >= low and value <= high
    -> value

function LetterGrade(score : integer) -> character
{ Returns the letter grade for a score from 0 to 100 }
Algorithm
    if score >= 85 then
        -> 'A'
    else if score >= 70 then
        -> 'B'
    else if score >= 55 then
        -> 'C'
    else if score >= 40 then
        -> 'D'
    else
        -> 'E'
    endif
```

`ReadInRange` is called twice with different prompts and limits, which shows how parameters make one function serve many purposes. The `+` in the prompt argument joins text and the number `i` into one string.

Create `GradeFunctions.java`:

```java
import java.util.Scanner;

// Program GradeFunctions
// Reads valid scores with a function and converts them to grades with another function.
public class GradeFunctions {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        int score;

        // Algorithm
        n = readInRange(input, "How many students? ", 1, 50);
        for (int i = 1; i <= n; i++) {
            score = readInRange(input, "Score of student " + i + ": ", 0, 100);
            System.out.println("  Grade: " + letterGrade(score));
        }
    }

    // Function ReadInRange
    // Asks with prompt until the user types an integer from low to high, then returns it
    static int readInRange(Scanner input, String prompt, int low, int high) {
        int value;
        do {
            System.out.print(prompt);
            value = input.nextInt();
            if (value < low || value > high) {
                System.out.println("  Please enter a number from " + low + " to " + high + ".");
            }
        } while (value < low || value > high);
        return value;
    }

    // Function LetterGrade
    // Returns the letter grade for a score from 0 to 100
    static char letterGrade(int score) {
        if (score >= 85) {
            return 'A';
        } else if (score >= 70) {
            return 'B';
        } else if (score >= 55) {
            return 'C';
        } else if (score >= 40) {
            return 'D';
        } else {
            return 'E';
        }
    }
}
```

There is one Java detail that the notation does not show. The `Scanner` named `input` is a local variable of `main`, so other methods cannot see it. The simplest solution is to pass it to `readInRange` as an extra parameter of type `Scanner`. Every call then shares the same `Scanner`, which is important because a program should only create one `Scanner` for the keyboard.

`letterGrade` returns a `char`, and its else-if chain has a `return` in every branch.

```bash
javac GradeFunctions.java
java GradeFunctions
```

Output:

```text
How many students? 0
  Please enter a number from 1 to 50.
How many students? 2
Score of student 1: 88
  Grade: A
Score of student 2: 120
  Please enter a number from 0 to 100.
Score of student 2: 64
  Grade: C
```

The same function rejected 0 students and a score of 120, each with the right limits in its message.

---

## 4. Run and Test

A **prime number** is a whole number greater than 1 whose only divisors are 1 and itself: 2, 3, 5, 7, 11, and so on. **Problem:** Read a limit, list all primes up to it, and count them.

To decide whether `n` is prime, try dividing it by 2, 3, 4, and so on. If any of them divides `n` evenly, `n` is not prime. You do not need to try every number up to `n`: if `n` has a divisor larger than its square root, it must also have one smaller than its square root, so it is enough to try divisors while `divisor * divisor <= n`.

```text
Program PrimeNumbers
{ Lists and counts the prime numbers up to a limit }

Dictionary
    limit, n, count : integer
    function IsPrime(n : integer) -> boolean

Algorithm
    output("Show primes up to: ")
    input(limit)
    count <- 0
    for n <- 2 to limit do
        if IsPrime(n) then
            output(n, " ")
            count <- count + 1
        endif
    endfor
    output("There are ", count, " primes up to ", limit, ".")

function IsPrime(n : integer) -> boolean
{ Returns true if n has no divisors other than 1 and itself }
Dictionary
    divisor : integer
Algorithm
    if n < 2 then
        -> false
    endif
    divisor <- 2
    while divisor * divisor <= n do
        if n mod divisor = 0 then
            -> false
        endif
        divisor <- divisor + 1
    endwhile
    -> true
```

The function returns `false` as soon as it finds a divisor, even in the middle of the loop. Returning ends the function immediately, so there is no need for a flag. If the loop finishes without finding a divisor, the last line returns `true`.

Create `PrimeNumbers.java`:

```java
import java.util.Scanner;

// Program PrimeNumbers
// Lists and counts the prime numbers up to a limit.
public class PrimeNumbers {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int limit;
        int count;

        // Algorithm
        System.out.print("Show primes up to: ");
        limit = input.nextInt();
        count = 0;
        for (int n = 2; n <= limit; n++) {
            if (isPrime(n)) {
                System.out.print(n + " ");
                count = count + 1;
            }
        }
        System.out.println();
        System.out.println("There are " + count + " primes up to " + limit + ".");
    }

    // Function IsPrime
    // Returns true if n has no divisors other than 1 and itself
    static boolean isPrime(int n) {
        if (n < 2) {
            return false;
        }
        int divisor = 2;
        while (divisor * divisor <= n) {
            if (n % divisor == 0) {
                return false;
            }
            divisor = divisor + 1;
        }
        return true;
    }
}
```

The main loop and the function's loop are completely separate: the main loop does not need to know how primality is checked, only that `isPrime` answers the question.

```bash
javac PrimeNumbers.java
java PrimeNumbers
```

Output:

```text
Show primes up to: 50
2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 
There are 15 primes up to 50.
```

Test the edge case where no primes exist:

Output:

```text
Show primes up to: 1

There are 0 primes up to 1.
```

The list matches the known primes below 50. To gain more confidence, you could test `isPrime` directly with values that are easy to get wrong: 1 (not prime), 2 (the only even prime), 9 and 25 (squares of primes, which test the `<=` in the loop condition).

---

## 5. Fix the Errors in Your Code

**Error 1: A path through the function that does not return.**

```java
// Wrong
public class MissingReturn {
    public static void main(String[] args) {
        System.out.println(max(3, 7));
    }

    static int max(int x, int y) {
        if (x > y) {
            return x;
        }
    }
}

// Correct
public class MissingReturn {
    public static void main(String[] args) {
        System.out.println(max(3, 7));
    }

    static int max(int x, int y) {
        if (x > y) {
            return x;
        }
        return y;
    }
}
```

The wrong version produces:

```text
MissingReturn.java:10: error: missing return statement
    }
    ^
1 error
```

When `x > y` is false, the function reaches its end without returning anything, but it promised to return an `int`. Every possible path through a function must end with a `return`. Check each branch, including the "otherwise" case.

**Error 2: Calling a function and ignoring its result.**

```java
// Wrong
public class IgnoredResult {
    public static void main(String[] args) {
        int side = 6;
        square(side);
        System.out.println("The square of " + side + " is calculated.");
    }

    static int square(int x) {
        return x * x;
    }
}

// Correct
public class IgnoredResult {
    public static void main(String[] args) {
        int side = 6;
        int area = square(side);
        System.out.println("The square of " + side + " is " + area + ".");
    }

    static int square(int x) {
        return x * x;
    }
}
```

The wrong version compiles and runs, but displays:

```text
The square of 6 is calculated.
```

The function calculated 36 and returned it, but nobody caught the value, so it was thrown away. A function call on a line by itself is almost always a mistake. Store the result in a variable, display it, or use it in an expression.

**Error 3: Returning a value of the wrong type.**

```java
// Wrong
public class WrongType {
    public static void main(String[] args) {
        System.out.println(average(7, 8));
    }

    static int average(int a, int b) {
        return (a + b) / 2.0;
    }
}

// Correct
public class WrongType {
    public static void main(String[] args) {
        System.out.println(average(7, 8));
    }

    static double average(int a, int b) {
        return (a + b) / 2.0;
    }
}
```

The wrong version produces:

```text
WrongType.java:7: error: incompatible types: possible lossy conversion from double to int
        return (a + b) / 2.0;
                       ^
1 error
```

The expression produces a `double` (7.5), but the function's header promises an `int`. The return type in the header and the type of the returned value must match. Decide what type the result really is, and declare it in the header. In notation, the same decision is made in the `-> type` part of the function header.

---

## 6. Exercises

**Exercise 1:** Write the notation and the Java program `PowerFunction` with a function `Power(base : integer, exponent : integer) -> integer` that calculates base to the power of exponent with a loop (exponent is 0 or more). Display 2^10, 3^4, and 5^0. Use `long` as the Java return type.

**Exercise 2:** Write the notation and the Java program `DigitSum` with a function `DigitSum(n : integer) -> integer` that returns the sum of the digits of `n`. The main algorithm reads a number, displays its digit sum, and uses the function again to say whether the number is divisible by 9 (a number is divisible by 9 exactly when its digit sum is).

**Exercise 3:** The greatest common divisor (GCD) of two positive integers is the largest number that divides both. **Euclid's algorithm** finds it like this: while `b` is not 0, replace `a` with `b` and `b` with the remainder of `a` divided by `b`; when `b` becomes 0, `a` is the GCD. Write the notation and the Java program `GreatestCommonDivisor` with a function `Gcd(a : integer, b : integer) -> integer`, and use it to simplify a fraction such as 48/180.

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program PowerFunction
{ Calculates base to the power of exponent with a loop inside a function }

Dictionary
    function Power(base : integer, exponent : integer) -> integer

Algorithm
    output("2^10 = ", Power(2, 10))
    output("3^4  = ", Power(3, 4))
    output("5^0  = ", Power(5, 0))

function Power(base : integer, exponent : integer) -> integer
{ Returns base raised to exponent, exponent >= 0 }
Dictionary
    i, result : integer
Algorithm
    result <- 1
    for i <- 1 to exponent do
        result <- result * base
    endfor
    -> result
```

```java
// Program PowerFunction
// Calculates base to the power of exponent with a loop inside a function.
public class PowerFunction {
    public static void main(String[] args) {
        // Algorithm
        System.out.println("2^10 = " + power(2, 10));
        System.out.println("3^4  = " + power(3, 4));
        System.out.println("5^0  = " + power(5, 0));
    }

    // Function Power
    // Returns base raised to exponent, exponent >= 0
    static long power(int base, int exponent) {
        long result = 1;
        for (int i = 1; i <= exponent; i++) {
            result = result * base;
        }
        return result;
    }
}
```

The product accumulator starts at 1, the same idea as the factorial in Lesson 10. With an exponent of 0 the loop never runs and the function returns 1, which is the correct value of any number to the power of 0.

```bash
javac PowerFunction.java
java PowerFunction
```

Output:

```text
2^10 = 1024
3^4  = 81
5^0  = 1
```

**Solution for Exercise 2:**

```text
Program DigitSum
{ Adds up the digits of a number using a function }

Dictionary
    number : integer
    function DigitSum(n : integer) -> integer

Algorithm
    output("Positive integer: ")
    input(number)
    output("Sum of digits: ", DigitSum(number))
    if DigitSum(number) mod 9 = 0 then
        output(number, " is divisible by 9.")
    else
        output(number, " is not divisible by 9.")
    endif

function DigitSum(n : integer) -> integer
{ Returns the sum of the digits of n, n >= 0 }
Dictionary
    sum : integer
Algorithm
    sum <- 0
    while n > 0 do
        sum <- sum + n mod 10
        n <- n div 10
    endwhile
    -> sum
```

```java
import java.util.Scanner;

// Program DigitSum
// Adds up the digits of a number using a function.
public class DigitSum {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int number;

        // Algorithm
        System.out.print("Positive integer: ");
        number = input.nextInt();
        System.out.println("Sum of digits: " + digitSum(number));
        if (digitSum(number) % 9 == 0) {
            System.out.println(number + " is divisible by 9.");
        } else {
            System.out.println(number + " is not divisible by 9.");
        }
    }

    // Function DigitSum
    // Returns the sum of the digits of n, n >= 0
    static int digitSum(int n) {
        int sum = 0;
        while (n > 0) {
            sum = sum + n % 10;
            n = n / 10;
        }
        return sum;
    }
}
```

The function changes its parameter `n` while it works, but because Java passes a copy, `number` in `main` keeps its original value. That is why the second call, inside the `if`, still works with the full number. This is the pass by value behavior from Lesson 12, and here it is helpful.

```bash
javac DigitSum.java
java DigitSum
```

Output:

```text
Positive integer: 4518
Sum of digits: 18
4518 is divisible by 9.
```

Output:

```text
Positive integer: 2026
Sum of digits: 10
2026 is not divisible by 9.
```

**Solution for Exercise 3:**

```text
Program GreatestCommonDivisor
{ Finds the GCD of two numbers with Euclid's algorithm and uses it to simplify a fraction }

Dictionary
    numerator, denominator, divisor : integer
    function Gcd(a : integer, b : integer) -> integer

Algorithm
    output("Numerator  : ")
    input(numerator)
    output("Denominator: ")
    input(denominator)
    divisor <- Gcd(numerator, denominator)
    output("GCD: ", divisor)
    output(numerator, "/", denominator, " = ", numerator div divisor, "/", denominator div divisor)

function Gcd(a : integer, b : integer) -> integer
{ Returns the greatest common divisor of a and b (a, b > 0) using Euclid's algorithm }
Dictionary
    remainder : integer
Algorithm
    while b <> 0 do
        remainder <- a mod b
        a <- b
        b <- remainder
    endwhile
    -> a
```

```java
import java.util.Scanner;

// Program GreatestCommonDivisor
// Finds the GCD of two numbers with Euclid's algorithm and uses it to simplify a fraction.
public class GreatestCommonDivisor {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int numerator;
        int denominator;
        int divisor;

        // Algorithm
        System.out.print("Numerator  : ");
        numerator = input.nextInt();
        System.out.print("Denominator: ");
        denominator = input.nextInt();
        divisor = gcd(numerator, denominator);
        System.out.println("GCD: " + divisor);
        System.out.println(numerator + "/" + denominator + " = " + (numerator / divisor) + "/" + (denominator / divisor));
    }

    // Function Gcd
    // Returns the greatest common divisor of a and b (a, b > 0) using Euclid's algorithm
    static int gcd(int a, int b) {
        int remainder;
        while (b != 0) {
            remainder = a % b;
            a = b;
            b = remainder;
        }
        return a;
    }
}
```

Trace it with 48 and 180: (48, 180) becomes (180, 48), then (48, 36), then (36, 12), then (12, 0), and the GCD is 12. Euclid's algorithm is more than 2000 years old and is still used today, because it finds the answer in very few steps even for huge numbers. Dividing both parts of the fraction by the GCD gives its simplest form.

```bash
javac GreatestCommonDivisor.java
java GreatestCommonDivisor
```

Output:

```text
Numerator  : 48
Denominator: 180
GCD: 12
48/180 = 4/15
```

---

## Next Up - Lesson 14

In this lesson you learned to write functions: subprograms that receive parameters, calculate a result, and return it with `->` in notation and `return` in Java. You used function calls as values inside expressions, conditions, and other calls; wrote functions returning `int`, `double`, `boolean`, and `char`; moved input validation into a reusable function; and implemented prime checking and Euclid's GCD algorithm.

So far, functions have called *other* functions. In Lesson 14 you will see something that surprises most beginners: a function that calls *itself*. This technique is called **recursion**. You will learn to identify the base case and the recursive case in notation, and implement classic recursive algorithms such as factorial and power in Java.
