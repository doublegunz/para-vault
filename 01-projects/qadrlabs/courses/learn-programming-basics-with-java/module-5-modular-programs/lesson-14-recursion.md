## 1. Before You Begin

In Lessons 12 and 13, procedures and functions called other subprograms: `PrintHeader` called `PrintLine`, and `Max(Max(a, b), c)` called `Max` twice. There is nothing stopping a subprogram from calling *itself*. This technique is called **recursion**, and it is one of the most elegant ideas in programming.

Recursion solves a problem by reducing it to a *smaller version of the same problem*. To calculate 5!, you can calculate 4! and multiply by 5. To calculate 4!, calculate 3! and multiply by 4. Eventually the problem becomes so small that the answer is obvious (0! is 1), and the chain of answers unwinds back to the original question. In this lesson you will learn how to design recursive algorithms safely, how to trace them, and when a loop is the better choice.

### What You'll Build

A recursive countdown, a recursive factorial with a trace that shows every call and return, recursive power and digit sum functions, and a Fibonacci program that compares a recursive solution with a loop.

### What You'll Learn

- ✅ What recursion is and how a subprogram can call itself
- ✅ The two parts of every recursive algorithm: the base case and the recursive case
- ✅ How to write recursive procedures and functions in notation and Java
- ✅ How to trace recursive calls and returns
- ✅ How the call stack works, and what a `StackOverflowError` means
- ✅ Why some recursive algorithms are very slow, and how a loop can fix it
- ✅ How to choose between recursion and a loop

### What You'll Need

- Lessons 12 and 13 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-14
cd ~/java-basics/lesson-14
```

---

## 2. Base Case and Recursive Case

Every correct recursive algorithm has two parts:

| Part | Meaning | Factorial example |
| --- | --- | --- |
| Base case | The smallest version of the problem, solved directly without recursion | 0! = 1 |
| Recursive case | Solves the problem using a smaller version of itself | n! = n x (n - 1)! |

The recursive case must always move closer to the base case. If it does, the chain of calls is guaranteed to reach the base case and stop. If it does not, the calls go on forever (until the program crashes, as you will see in Section 6).

### Step 1: A Recursive Procedure

Start with something you already know: a countdown. Instead of a loop, think of it recursively. Counting down from 5 means "display 5, then count down from 4." Counting down from 0 means "display Go!" and stop.

```text
Program RecursiveCountdown
{ Counts down with a procedure that calls itself }

Dictionary
    procedure Countdown(input n : integer)

Algorithm
    Countdown(5)

procedure Countdown(input n : integer)
{ I.S.: n >= 0 }
{ F.S.: the numbers n down to 1 and then "Go!" are displayed }
Algorithm
    if n = 0 then
        output("Go!")              { base case }
    else
        output(n)
        Countdown(n - 1)           { recursive case }
    endif
```

`Countdown(n - 1)` is the recursive call. Each call has a smaller `n`, so eventually `n` reaches 0, the base case runs, and nothing more is called.

Create `RecursiveCountdown.java`:

```java
// Program RecursiveCountdown
// Counts down with a procedure that calls itself.
public class RecursiveCountdown {
    public static void main(String[] args) {
        // Algorithm
        countdown(5);
    }

    // Procedure Countdown
    // I.S.: n >= 0
    // F.S.: the numbers n down to 1 and then "Go!" are displayed
    static void countdown(int n) {
        if (n == 0) {
            System.out.println("Go!");
        } else {
            System.out.println(n);
            countdown(n - 1);
        }
    }
}
```

The method `countdown` calls `countdown` inside its own body. Java treats this like any other method call: each call gets its own fresh copy of the parameter `n`, so the `n` in `countdown(5)` and the `n` in `countdown(4)` are separate variables.

```bash
javac RecursiveCountdown.java
java RecursiveCountdown
```

Output:

```text
5
4
3
2
1
Go!
```

There is no loop anywhere in this program, yet the steps repeat. Each recursive call does the work of one round.

### Step 2: A Recursive Function

Factorial is the classic recursive function, because its mathematical definition is already recursive:

```text
0! = 1
n! = n x (n - 1)!     for n > 0
```

The notation follows the definition almost word for word:

```text
Program RecursiveFactorial
{ Calculates n! with a recursive function }

Dictionary
    n : integer
    function Factorial(n : integer) -> integer

Algorithm
    output("n: ")
    input(n)
    output(n, "! = ", Factorial(n))

function Factorial(n : integer) -> integer
{ Returns n! for n >= 0 }
Algorithm
    if n = 0 then
        -> 1                          { base case }
    else
        -> n * Factorial(n - 1)       { recursive case }
    endif
```

Compare this with the loop version in Lesson 10. There is no accumulator and no loop variable. The function trusts that `Factorial(n - 1)` returns the right answer for the smaller problem, and only adds the last step: multiply by `n`.

Create `RecursiveFactorial.java`:

```java
import java.util.Scanner;

// Program RecursiveFactorial
// Calculates n! with a recursive function.
public class RecursiveFactorial {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;

        // Algorithm
        System.out.print("n: ");
        n = input.nextInt();
        System.out.println(n + "! = " + factorial(n));
    }

    // Function Factorial
    // Returns n! for n >= 0
    static long factorial(int n) {
        if (n == 0) {
            return 1;
        } else {
            return n * factorial(n - 1);
        }
    }
}
```

The return type is `long` because factorials grow quickly, just as in Lesson 10.

```bash
javac RecursiveFactorial.java
java RecursiveFactorial
```

Output:

```text
n: 5
5! = 120
```

Output:

```text
n: 0
0! = 1
```

---

## 3. Trace Recursive Calls

How does `factorial(4)` actually produce 24? Every time a function is called, the computer pauses the caller, remembers where it was, and starts the new call. These paused calls are stored in a structure called the **call stack**, like a stack of plates: each new call is placed on top, and when a call returns, it is removed from the top and the call below it continues.

For `factorial(4)`, the calls pile up until the base case is reached, then the returns unwind in reverse order:

```text
factorial(4) = 4 * factorial(3)
                   factorial(3) = 3 * factorial(2)
                                      factorial(2) = 2 * factorial(1)
                                                         factorial(1) = 1 * factorial(0)
                                                                            factorial(0) = 1
                                                         factorial(1) = 1 * 1 = 1
                                      factorial(2) = 2 * 1 = 2
                   factorial(3) = 3 * 2 = 6
factorial(4) = 4 * 6 = 24
```

### Step 1: Make the Program Show Its Own Trace

You can make a recursive function display its calls and returns. The version below takes an extra parameter, `indent`, which grows by two spaces with each level of recursion, so deeper calls are printed further to the right.

```text
Program TracedFactorial
{ Shows every call and return of a recursive factorial }

Dictionary
    function Factorial(n : integer, indent : string) -> integer

Algorithm
    output("Result: ", Factorial(4, ""))

function Factorial(n : integer, indent : string) -> integer
{ Returns n! for n >= 0 and displays each call and return, indented by depth }
Dictionary
    result : integer
Algorithm
    output(indent, "factorial(", n, ") called")
    if n = 0 then
        result <- 1
    else
        result <- n * Factorial(n - 1, indent + "  ")
    endif
    output(indent, "factorial(", n, ") returns ", result)
    -> result
```

Create `TracedFactorial.java`:

```java
// Program TracedFactorial
// Shows every call and return of a recursive factorial.
public class TracedFactorial {
    public static void main(String[] args) {
        // Algorithm
        System.out.println("Result: " + factorial(4, ""));
    }

    // Function Factorial
    // Returns n! for n >= 0 and displays each call and return, indented by depth
    static long factorial(int n, String indent) {
        long result;
        System.out.println(indent + "factorial(" + n + ") called");
        if (n == 0) {
            result = 1;
        } else {
            result = n * factorial(n - 1, indent + "  ");
        }
        System.out.println(indent + "factorial(" + n + ") returns " + result);
        return result;
    }
}
```

The result is stored in a local variable before returning, so the function can display it first. Each call has its own `n`, `indent`, and `result`.

```bash
javac TracedFactorial.java
java TracedFactorial
```

Output:

```text
factorial(4) called
  factorial(3) called
    factorial(2) called
      factorial(1) called
        factorial(0) called
        factorial(0) returns 1
      factorial(1) returns 1
    factorial(2) returns 2
  factorial(3) returns 6
factorial(4) returns 24
Result: 24
```

The top half shows the calls going *down* to the base case; none of them can finish yet, because each is waiting for the answer from the call below. The bottom half shows the returns coming back *up*, each one using the answer it was waiting for. Tracing like this is the best way to understand, and debug, any recursive algorithm.

### Step 2: More Recursive Functions

Many problems have a natural recursive shape once you find the smaller version inside them:

- **Power:** b^0 = 1, and b^e = b x b^(e - 1).
- **Digit sum:** a single digit is its own sum; otherwise, the sum is the last digit plus the digit sum of the remaining digits.

```text
Program RecursivePower
{ Calculates powers and digit sums with recursive functions }

Dictionary
    function Power(base : integer, exponent : integer) -> integer
    function DigitSum(n : integer) -> integer

Algorithm
    output("power(2, 10) = ", Power(2, 10))
    output("power(7, 3)  = ", Power(7, 3))
    output("digitSum(4518) = ", DigitSum(4518))

function Power(base : integer, exponent : integer) -> integer
{ Returns base raised to exponent, exponent >= 0 }
Algorithm
    if exponent = 0 then
        -> 1
    else
        -> base * Power(base, exponent - 1)
    endif

function DigitSum(n : integer) -> integer
{ Returns the sum of the digits of n, n >= 0 }
Algorithm
    if n < 10 then
        -> n
    else
        -> n mod 10 + DigitSum(n div 10)
    endif
```

In `Power`, the exponent shrinks by 1 each call. In `DigitSum`, `n div 10` removes one digit each call. Both move steadily toward their base case.

Create `RecursivePower.java`:

```java
// Program RecursivePower
// Calculates powers and digit sums with recursive functions.
public class RecursivePower {
    public static void main(String[] args) {
        // Algorithm
        System.out.println("power(2, 10) = " + power(2, 10));
        System.out.println("power(7, 3)  = " + power(7, 3));
        System.out.println("digitSum(4518) = " + digitSum(4518));
    }

    // Function Power
    // Returns base raised to exponent, exponent >= 0
    static long power(int base, int exponent) {
        if (exponent == 0) {
            return 1;
        } else {
            return base * power(base, exponent - 1);
        }
    }

    // Function DigitSum
    // Returns the sum of the digits of n, n >= 0
    static int digitSum(int n) {
        if (n < 10) {
            return n;
        } else {
            return n % 10 + digitSum(n / 10);
        }
    }
}
```

```bash
javac RecursivePower.java
java RecursivePower
```

Output:

```text
power(2, 10) = 1024
power(7, 3)  = 343
digitSum(4518) = 18
```

These match the loop versions from Lesson 13. Any loop can be rewritten as recursion and vice versa; the question is which one expresses the idea more clearly.

---

## 4. Run and Test

The **Fibonacci sequence** starts with 1, 1, and each following number is the sum of the two before it: 1, 1, 2, 3, 5, 8, 13, ... Its definition is recursive:

```text
fib(1) = 1
fib(2) = 1
fib(n) = fib(n - 1) + fib(n - 2)     for n > 2
```

This time the recursive case calls the function *twice*. **Problem:** Display the first 10 Fibonacci numbers, then compute `fib(n)` for a chosen `n` both recursively and with a loop, counting how many recursive calls were made.

```text
Program Fibonacci
{ Compares a recursive and a loop-based Fibonacci function, counting the recursive calls }

Dictionary
    calls : integer            { shared by the whole program }
    n, i, recursiveResult : integer
    function Fib(n : integer) -> integer
    function FibLoop(n : integer) -> integer

Algorithm
    output("First 10 Fibonacci numbers: ")
    for i <- 1 to 10 do
        output(Fib(i), " ")
    endfor
    output("n: ")
    input(n)
    calls <- 0
    recursiveResult <- Fib(n)
    output("Recursive : fib(", n, ") = ", recursiveResult, " after ", calls, " calls")
    output("With loop : fib(", n, ") = ", FibLoop(n))

function Fib(n : integer) -> integer
{ Returns the n-th Fibonacci number, n >= 1 (recursive version) }
Algorithm
    calls <- calls + 1
    if n <= 2 then
        -> 1
    else
        -> Fib(n - 1) + Fib(n - 2)
    endif

function FibLoop(n : integer) -> integer
{ Returns the n-th Fibonacci number, n >= 1 (loop version) }
Dictionary
    previous, current, next, i : integer
Algorithm
    previous <- 1
    current <- 1
    for i <- 3 to n do
        next <- previous + current
        previous <- current
        current <- next
    endfor
    -> current
```

`calls` must be visible to both `main` and `Fib`, so it is declared at the program level instead of inside one subprogram. A variable like this is called a **global variable**. Global variables are convenient for measurements like this one, but in general it is better to pass data through parameters, because a variable that any subprogram can change is harder to reason about.

Create `Fibonacci.java`:

```java
import java.util.Scanner;

// Program Fibonacci
// Compares a recursive and a loop-based Fibonacci function, counting the recursive calls.
public class Fibonacci {
    // Dictionary (shared by the whole program)
    static long calls;

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        long recursiveResult;

        // Algorithm
        System.out.print("First 10 Fibonacci numbers: ");
        for (int i = 1; i <= 10; i++) {
            System.out.print(fib(i) + " ");
        }
        System.out.println();
        System.out.print("n: ");
        n = input.nextInt();
        calls = 0;
        recursiveResult = fib(n);
        System.out.println("Recursive : fib(" + n + ") = " + recursiveResult + " after " + calls + " calls");
        System.out.println("With loop : fib(" + n + ") = " + fibLoop(n));
    }

    // Function Fib
    // Returns the n-th Fibonacci number, n >= 1 (recursive version)
    static long fib(int n) {
        calls = calls + 1;
        if (n <= 2) {
            return 1;
        } else {
            return fib(n - 1) + fib(n - 2);
        }
    }

    // Function FibLoop
    // Returns the n-th Fibonacci number, n >= 1 (loop version)
    static long fibLoop(int n) {
        long previous = 1;
        long current = 1;
        long next;
        for (int i = 3; i <= n; i++) {
            next = previous + current;
            previous = current;
            current = next;
        }
        return current;
    }
}
```

`static long calls;` is declared inside the class but outside every method, which makes it a variable shared by all the methods of the class, Java's version of a global variable. The recursive result is stored in `recursiveResult` before displaying `calls`, so the count is complete when it is printed.

```bash
javac Fibonacci.java
java Fibonacci
```

Output:

```text
First 10 Fibonacci numbers: 1 1 2 3 5 8 13 21 34 55 
n: 20
Recursive : fib(20) = 6765 after 13529 calls
With loop : fib(20) = 6765
```

Both versions agree. Now try a larger number:

Output:

```text
First 10 Fibonacci numbers: 1 1 2 3 5 8 13 21 34 55 
n: 35
Recursive : fib(35) = 9227465 after 18454929 calls
With loop : fib(35) = 9227465
```

Over 18 million calls to compute one number, and you probably noticed a delay before the answer appeared. The loop version needs only 33 rounds. The reason is that the recursive version solves the same small problems again and again: `fib(35)` calls `fib(34)` and `fib(33)`, but `fib(34)` *also* calls `fib(33)`, and so on all the way down. Finally, test the smallest input:

Output:

```text
First 10 Fibonacci numbers: 1 1 2 3 5 8 13 21 34 55 
n: 1
Recursive : fib(1) = 1 after 1 calls
With loop : fib(1) = 1
```

---

## 5. Recursion or Loop?

Every recursive algorithm can be written with a loop, and every loop can be written recursively. Neither is always better. Use these guidelines:

| Prefer recursion when | Prefer a loop when |
| --- | --- |
| The problem is defined in terms of smaller versions of itself (factorial, GCD, power) | The task is simply "repeat these steps n times" or "until a condition" |
| The data has a nested, branching shape (folders inside folders, family trees) | The recursive version would repeat work, like Fibonacci |
| The recursive version is much shorter and clearer | The input can be very large (deep recursion uses a lot of stack memory) |

For most problems in this course, loops are the practical choice. But recursion is a way of *thinking*: breaking a problem into a smaller copy of itself is a powerful design skill, and some advanced algorithms, such as the fast sorting methods you may study after this course, are naturally recursive.

---

## 6. Fix the Errors in Your Code

Recursion bugs usually make the chain of calls go on forever. Java does not let that happen silently: the call stack has a limited size, and when it fills up, the program stops with a `StackOverflowError`.

**Error 1: No base case.**

```java
// Wrong
public class NoBase {
    public static void main(String[] args) {
        System.out.println(factorial(5));
    }

    static long factorial(int n) {
        return n * factorial(n - 1);
    }
}

// Correct
public class NoBase {
    public static void main(String[] args) {
        System.out.println(factorial(5));
    }

    static long factorial(int n) {
        if (n == 0) {
            return 1;
        }
        return n * factorial(n - 1);
    }
}
```

The wrong version compiles, then crashes. These are the first lines of the error:

```text
Exception in thread "main" java.lang.StackOverflowError
	at NoBase.factorial(NoBase.java:7)
	at NoBase.factorial(NoBase.java:7)
	at NoBase.factorial(NoBase.java:7)
	at NoBase.factorial(NoBase.java:7)
	at NoBase.factorial(NoBase.java:7)
```

The real message continues with hundreds more identical lines, one for each call waiting on the stack. Without a base case, `factorial` keeps calling itself with 4, 3, 2, 1, 0, -1, -2, and so on, until the stack runs out of space. Every recursive subprogram needs a base case that stops the recursion.

**Error 2: A recursive call that does not get smaller.**

```java
// Wrong
public class NoProgress {
    public static void main(String[] args) {
        countdown(3);
    }

    static void countdown(int n) {
        if (n == 0) {
            System.out.println("Go!");
        } else {
            System.out.println(n);
            countdown(n);
        }
    }
}

// Correct
public class NoProgress {
    public static void main(String[] args) {
        countdown(3);
    }

    static void countdown(int n) {
        if (n == 0) {
            System.out.println("Go!");
        } else {
            System.out.println(n);
            countdown(n - 1);
        }
    }
}
```

The wrong version displays `3` thousands of times:

```text
3
3
3
3
```

and finally ends with `Exception in thread "main" java.lang.StackOverflowError`. There *is* a base case, but the recursive call passes `n` unchanged, so the base case is never reached. Always check that the argument of the recursive call moves toward the base case.

**Error 3: An input that skips past the base case.**

```java
// Wrong
public class Negative {
    public static void main(String[] args) {
        System.out.println(factorial(-3));
    }

    static long factorial(int n) {
        if (n == 0) {
            return 1;
        } else {
            return n * factorial(n - 1);
        }
    }
}
```

This function is correct for every `n >= 0`, but with -3 it crashes:

```text
Exception in thread "main" java.lang.StackOverflowError
	at Negative.factorial(Negative.java:10)
	at Negative.factorial(Negative.java:10)
```

Starting from -3, subtracting 1 moves *away* from 0, so the base case `n == 0` is never hit. The function's comment says it requires `n >= 0`, the same role as I.S. in a procedure. Respect that requirement by validating input before calling, for example with `readInRange` from Lesson 13, or make the base case cover the invalid values with `if (n <= 0)`.

---

## 7. Exercises

**Exercise 1:** Write the notation and the Java program `RecursiveSum` with a recursive function `SumTo(n : integer) -> integer` that returns 1 + 2 + ... + n. Test it with 5, 100, and 0.

**Exercise 2:** Write the notation and the Java program `DigitsBothWays` with two recursive procedures: `PrintBackward(input n : integer)` displays the digits of `n` from last to first, and `PrintForward(input n : integer)` displays them from first to last. Test both with 2026. Hint: the two procedures differ only in whether the digit is displayed before or after the recursive call.

**Exercise 3:** Euclid's algorithm from Lesson 13 has a natural recursive form: gcd(a, 0) = a, and gcd(a, b) = gcd(b, a mod b). Write the notation and the Java program `RecursiveGcd` with a recursive function `Gcd(a : integer, b : integer) -> integer`.

---

## 8. Solutions

**Solution for Exercise 1:**

```text
Program RecursiveSum
{ Adds the numbers from 1 to n with a recursive function }

Dictionary
    function SumTo(n : integer) -> integer

Algorithm
    output("sumTo(5)   = ", SumTo(5))
    output("sumTo(100) = ", SumTo(100))
    output("sumTo(0)   = ", SumTo(0))

function SumTo(n : integer) -> integer
{ Returns 1 + 2 + ... + n, n >= 0 }
Algorithm
    if n = 0 then
        -> 0
    else
        -> n + SumTo(n - 1)
    endif
```

```java
// Program RecursiveSum
// Adds the numbers from 1 to n with a recursive function.
public class RecursiveSum {
    public static void main(String[] args) {
        // Algorithm
        System.out.println("sumTo(5)   = " + sumTo(5));
        System.out.println("sumTo(100) = " + sumTo(100));
        System.out.println("sumTo(0)   = " + sumTo(0));
    }

    // Function SumTo
    // Returns 1 + 2 + ... + n, n >= 0
    static int sumTo(int n) {
        if (n == 0) {
            return 0;
        } else {
            return n + sumTo(n - 1);
        }
    }
}
```

The sum of nothing is 0, which is the base case. Otherwise, the sum up to `n` is `n` plus the sum up to `n - 1`. The structure is identical to factorial, with addition instead of multiplication and 0 instead of 1.

```bash
javac RecursiveSum.java
java RecursiveSum
```

Output:

```text
sumTo(5)   = 15
sumTo(100) = 5050
sumTo(0)   = 0
```

**Solution for Exercise 2:**

```text
Program DigitsBothWays
{ Displays the digits of a number forward and backward with recursive procedures }

Dictionary
    procedure PrintBackward(input n : integer)
    procedure PrintForward(input n : integer)

Algorithm
    output("Backward: ")
    PrintBackward(2026)
    output(new line)
    output("Forward : ")
    PrintForward(2026)
    output(new line)

procedure PrintBackward(input n : integer)
{ I.S.: n >= 0 }
{ F.S.: the digits of n are displayed from last to first, separated by spaces }
Algorithm
    output(n mod 10, " ")
    if n >= 10 then
        PrintBackward(n div 10)
    endif

procedure PrintForward(input n : integer)
{ I.S.: n >= 0 }
{ F.S.: the digits of n are displayed from first to last, separated by spaces }
Algorithm
    if n >= 10 then
        PrintForward(n div 10)
    endif
    output(n mod 10, " ")
```

```java
// Program DigitsBothWays
// Displays the digits of a number forward and backward with recursive procedures.
public class DigitsBothWays {
    public static void main(String[] args) {
        // Algorithm
        System.out.print("Backward: ");
        printBackward(2026);
        System.out.println();
        System.out.print("Forward : ");
        printForward(2026);
        System.out.println();
    }

    // Procedure PrintBackward
    // I.S.: n >= 0
    // F.S.: the digits of n are displayed from last to first, separated by spaces
    static void printBackward(int n) {
        System.out.print(n % 10 + " ");
        if (n >= 10) {
            printBackward(n / 10);
        }
    }

    // Procedure PrintForward
    // I.S.: n >= 0
    // F.S.: the digits of n are displayed from first to last, separated by spaces
    static void printForward(int n) {
        if (n >= 10) {
            printForward(n / 10);
        }
        System.out.print(n % 10 + " ");
    }
}
```

Here the base case is implicit: when `n` has a single digit, the `if` is false and no recursive call is made. `PrintBackward` displays the last digit *before* recursing, so the last digit comes first. `PrintForward` recurses *first*, so all the earlier digits are displayed (on the way back up the call stack) before its own last digit. Moving one line changes the whole order, which is a striking demonstration of how the call stack unwinds.

```bash
javac DigitsBothWays.java
java DigitsBothWays
```

Output:

```text
Backward: 6 2 0 2 
Forward : 2 0 2 6 
```

**Solution for Exercise 3:**

```text
Program RecursiveGcd
{ Finds the GCD of two numbers with a recursive version of Euclid's algorithm }

Dictionary
    a, b : integer
    function Gcd(a : integer, b : integer) -> integer

Algorithm
    output("Two positive integers: ")
    input(a, b)
    output("GCD(", a, ", ", b, ") = ", Gcd(a, b))

function Gcd(a : integer, b : integer) -> integer
{ Returns the greatest common divisor of a and b, a > 0 and b >= 0 }
Algorithm
    if b = 0 then
        -> a
    else
        -> Gcd(b, a mod b)
    endif
```

```java
import java.util.Scanner;

// Program RecursiveGcd
// Finds the GCD of two numbers with a recursive version of Euclid's algorithm.
public class RecursiveGcd {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int a;
        int b;

        // Algorithm
        System.out.print("Two positive integers: ");
        a = input.nextInt();
        b = input.nextInt();
        System.out.println("GCD(" + a + ", " + b + ") = " + gcd(a, b));
    }

    // Function Gcd
    // Returns the greatest common divisor of a and b, a > 0 and b >= 0
    static int gcd(int a, int b) {
        if (b == 0) {
            return a;
        } else {
            return gcd(b, a % b);
        }
    }
}
```

The recursive version is a direct copy of the mathematical definition, and it is shorter than the loop in Lesson 13. Each call makes `b` smaller (the remainder `a mod b` is always less than `b`), so the base case `b = 0` is always reached. Two numbers with no common divisor except 1, like 17 and 5, have a GCD of 1.

```bash
javac RecursiveGcd.java
java RecursiveGcd
```

Output:

```text
Two positive integers: 48 180
GCD(48, 180) = 12
```

Output:

```text
Two positive integers: 17 5
GCD(17, 5) = 1
```

---

## Next Up - Lesson 15

In this lesson you learned recursion: a subprogram that calls itself with a smaller version of the problem. Every recursive algorithm needs a base case that stops the chain and a recursive case that moves toward it. You traced calls and returns on the call stack, saw what a `StackOverflowError` means, and discovered that some recursive solutions, like Fibonacci, repeat so much work that a loop is far better. Module 5 is complete: you can now organize programs into procedures, functions, and recursive subprograms.

Until now, every variable has held a single value. To process a class of 30 students, you would need 30 separate variables, which is impractical. In Lesson 15 you will start Module 6 with **arrays**: one variable that holds a whole list of values. You will declare arrays in the Dictionary, fill and traverse them with loops, and implement array algorithms such as totals and averages in Java.
