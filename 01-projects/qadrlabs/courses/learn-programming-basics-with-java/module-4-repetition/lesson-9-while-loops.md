## 1. Before You Begin

You now have two of the three building blocks of every algorithm: sequence and selection. The third is **repetition**. Imagine displaying the numbers 1 to 100, adding up a list of prices whose length you do not know in advance, or giving a user three chances to type the right PIN. Writing the same steps over and over is tedious, and for an unknown number of repetitions it is impossible. A **loop** solves this by running a group of steps again and again while a condition stays true.

This lesson introduces the most fundamental loop: `while ... do ... endwhile` in notation and the `while` statement in Java. You will learn the three parts every loop needs, how to stop a loop with a special input value, and how to trace a loop round by round. You will also learn to recognize and fix the infinite loop, the bug every programmer meets sooner or later.

### What You'll Build

A counter, a countdown, a program that adds numbers until the user types 0, a digit counter, a PIN checker with three attempts, and a savings calculator that finds how many years it takes to reach a target.

### What You'll Learn

- ✅ How to write a loop with `while ... do ... endwhile` in notation
- ✅ How to implement it with Java's `while` statement
- ✅ The three parts of a loop: initialization, condition, and update
- ✅ How to trace a loop with a table, one row per round
- ✅ How to stop a loop with a sentinel value such as 0
- ✅ How to combine a loop condition with a boolean flag
- ✅ How to recognize and fix infinite loops and off-by-one errors

### What You'll Need

- Lessons 7 and 8 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-09
cd ~/java-basics/lesson-09
```

---

## 2. The While Loop

A `while` loop checks a condition *before* each round. If the condition is true, it runs the steps in its body, then goes back and checks the condition again. As soon as the condition is false, the loop ends and the algorithm continues with the step after `endwhile`.

```text
while condition do
    steps to repeat
endwhile
```

In Java:

```java
while (condition) {
    // statements to repeat
}
```

The structure looks like an `if` statement, and the condition works the same way. The difference is what happens after the body runs: an `if` moves on, while a `while` jumps back up and asks the question again. Each run through the body is called an **iteration** or a **round**.

### Step 1: Count from 1 to 5

You traced this algorithm in plain English in Lesson 1. Here it is in notation:

```text
Program CountToFive
{ Displays the numbers 1 to 5 using a while loop }

Dictionary
    counter : integer

Algorithm
    counter <- 1
    while counter <= 5 do
        output(counter)
        counter <- counter + 1
    endwhile
    output("Done")
```

Every well-formed loop has three parts, and you can see all of them here:

| Part | In this algorithm | Purpose |
| --- | --- | --- |
| Initialization | `counter <- 1` | Give the loop variable a starting value before the loop |
| Condition | `counter <= 5` | Decide whether to run another round |
| Update | `counter <- counter + 1` | Move the loop variable toward making the condition false |

If any of the three is missing or wrong, the loop either runs the wrong number of times or never stops.

Create `CountToFive.java`:

```java
// Program CountToFive
// Displays the numbers 1 to 5 using a while loop.
public class CountToFive {
    public static void main(String[] args) {
        // Dictionary
        int counter;

        // Algorithm
        counter = 1;
        while (counter <= 5) {
            System.out.println(counter);
            counter = counter + 1;
        }
        System.out.println("Done");
    }
}
```

The initialization sits before the loop, the condition is in the parentheses after `while`, and the update is the last statement in the body. The closing brace plays the role of `endwhile`. `System.out.println("Done")` is after the loop, so it runs once, when the loop has finished.

```bash
javac CountToFive.java
java CountToFive
```

Output:

```text
1
2
3
4
5
Done
```

The tracing table from Lesson 1 predicted exactly this: five rounds where the condition is true, then a sixth check where `counter` is 6, the condition is false, and the loop ends.

### Step 2: Count Down from Any Number

Loops can count in any direction. **Problem:** Read a starting number and count down to 1, then display "Lift off!".

```text
Program Countdown
{ Counts down from a starting number to 1, then displays "Lift off!" }

Dictionary
    n : integer

Algorithm
    output("Start from: ")
    input(n)
    while n >= 1 do
        output(n, " ")
        n <- n - 1
    endwhile
    output("Lift off!")
```

Here the input itself is the loop variable. The initialization is `input(n)`, the condition is `n >= 1`, and the update subtracts 1 each round.

Create `Countdown.java`:

```java
import java.util.Scanner;

// Program Countdown
// Counts down from a starting number to 1, then displays "Lift off!".
public class Countdown {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;

        // Algorithm
        System.out.print("Start from: ");
        n = input.nextInt();
        while (n >= 1) {
            System.out.print(n + " ");
            n = n - 1;
        }
        System.out.println();
        System.out.println("Lift off!");
    }
}
```

`print` keeps all the numbers on one line, each followed by a space. After the loop, an empty `println()` ends that line before the final message.

```bash
javac Countdown.java
java Countdown
```

Output:

```text
Start from: 10
10 9 8 7 6 5 4 3 2 1 
Lift off!
```

Now run it with 0:

Output:

```text
Start from: 0

Lift off!
```

With 0, the condition `n >= 1` is false the very first time it is checked, so the body never runs and the line of numbers is empty. This is an important property of `while`: **the body can run zero times**, because the condition is checked before the first round.

---

## 3. Loops Controlled by Data

A counter loop knows in advance how many rounds it will run. Many problems do not. A cashier does not know how many items a customer will buy; a program reading scores does not know how many students there are. In these cases the loop is controlled by the data itself.

### Step 1: Stop with a Sentinel Value

A **sentinel** is a special value that means "stop." It must be a value that can never be real data. **Problem:** Read numbers one at a time until the user types 0, then display how many numbers were entered and their sum.

```text
Program SumUntilZero
{ Reads numbers until the user enters 0, then displays their sum and count }

Dictionary
    number, sum, count : integer

Algorithm
    sum <- 0
    count <- 0
    output("Enter a number (0 to stop): ")
    input(number)
    while number <> 0 do
        sum <- sum + number
        count <- count + 1
        output("Enter a number (0 to stop): ")
        input(number)
    endwhile
    output("You entered ", count, " numbers.")
    output("Sum: ", sum)
```

Look carefully at where `input(number)` appears: once *before* the loop, and again at the *end* of the body. This pattern is called a **priming read**. The first read gives the condition something to check. Inside the loop, the program processes the current number first and then reads the next one, so the condition always checks the newest value. When the user types 0, the loop ends *before* 0 is added or counted.

`sum` and `count` both start at 0. A variable that collects a running total like this is called an **accumulator**, and you will study it in depth in Lesson 11.

Create `SumUntilZero.java`:

```java
import java.util.Scanner;

// Program SumUntilZero
// Reads numbers until the user enters 0, then displays their sum and count.
public class SumUntilZero {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int number;
        int sum;
        int count;

        // Algorithm
        sum = 0;
        count = 0;
        System.out.print("Enter a number (0 to stop): ");
        number = input.nextInt();
        while (number != 0) {
            sum = sum + number;
            count = count + 1;
            System.out.print("Enter a number (0 to stop): ");
            number = input.nextInt();
        }
        System.out.println("You entered " + count + " numbers.");
        System.out.println("Sum: " + sum);
    }
}
```

The notation's `<>` becomes `!=`. Everything else follows the notation line by line.

```bash
javac SumUntilZero.java
java SumUntilZero
```

Output:

```text
Enter a number (0 to stop): 15
Enter a number (0 to stop): 8
Enter a number (0 to stop): 22
Enter a number (0 to stop): 5
Enter a number (0 to stop): 0
You entered 4 numbers.
Sum: 50
```

Run it again and type 0 immediately:

Output:

```text
Enter a number (0 to stop): 0
You entered 0 numbers.
Sum: 0
```

Because the accumulators start at 0 and the loop body never runs, the empty case is handled correctly without any extra code.

### Step 2: Repeat Until a Value Runs Out

**Problem:** Count how many digits a positive integer has. For example, 2026 has 4 digits.

Dividing an integer by 10 with integer division removes its last digit: 2026 becomes 202, then 20, then 2, then 0. Counting how many divisions it takes to reach 0 gives the number of digits:

```text
Program DigitCount
{ Counts the digits of a positive integer by repeatedly dividing by 10 }

Dictionary
    number, digits : integer

Algorithm
    output("Positive integer: ")
    input(number)
    digits <- 0
    while number > 0 do
        number <- number div 10
        digits <- digits + 1
    endwhile
    output("Number of digits: ", digits)
```

| Round | number before | Condition number > 0 | number after | digits |
| --- | --- | --- | --- | --- |
| 1 | 2026 | true | 202 | 1 |
| 2 | 202 | true | 20 | 2 |
| 3 | 20 | true | 2 | 3 |
| 4 | 2 | true | 0 | 4 |
| 5 | 0 | false | | 4 |

Here the update is `number <- number div 10`. It is not a counter, but it still moves the loop toward its end, because the number gets smaller every round and must eventually reach 0.

Create `DigitCount.java`:

```java
import java.util.Scanner;

// Program DigitCount
// Counts the digits of a positive integer by repeatedly dividing by 10.
public class DigitCount {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int number;
        int digits;

        // Algorithm
        System.out.print("Positive integer: ");
        number = input.nextInt();
        digits = 0;
        while (number > 0) {
            number = number / 10;
            digits = digits + 1;
        }
        System.out.println("Number of digits: " + digits);
    }
}
```

`div` becomes `/`, which is integer division because `number` is an `int`.

```bash
javac DigitCount.java
java DigitCount
```

Output:

```text
Positive integer: 2026
Number of digits: 4
```

Output:

```text
Positive integer: 7
Number of digits: 1
```

### Step 3: Combine a Counter and a Flag

A loop condition can use logical operators, just like an `if`. **Problem:** An ATM gives the user up to three attempts to enter the correct PIN. Stop as soon as the PIN is correct, or after three wrong attempts.

```text
Program PinCheck
{ Gives the user up to three attempts to enter the correct PIN }

Dictionary
    constant CORRECT_PIN  : integer = 4821
    constant MAX_ATTEMPTS : integer = 3
    pin, attempts : integer
    isCorrect     : boolean

Algorithm
    attempts <- 0
    isCorrect <- false
    while attempts < MAX_ATTEMPTS and not isCorrect do
        output("Enter PIN: ")
        input(pin)
        attempts <- attempts + 1
        if pin = CORRECT_PIN then
            isCorrect <- true
        else
            output("Wrong PIN. Attempts left: ", MAX_ATTEMPTS - attempts)
        endif
    endwhile
    if isCorrect then
        output("Access granted.")
    else
        output("Card blocked.")
    endif
```

`isCorrect` is a **flag**: a boolean that records whether something has happened. The loop continues only while *both* parts are true: there are attempts left *and* the PIN has not been entered correctly. Either event ends the loop. After the loop, the flag tells the algorithm *why* the loop ended.

Create `PinCheck.java`:

```java
import java.util.Scanner;

// Program PinCheck
// Gives the user up to three attempts to enter the correct PIN.
public class PinCheck {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int CORRECT_PIN = 4821;
        final int MAX_ATTEMPTS = 3;
        int pin;
        int attempts;
        boolean isCorrect;

        // Algorithm
        attempts = 0;
        isCorrect = false;
        while (attempts < MAX_ATTEMPTS && !isCorrect) {
            System.out.print("Enter PIN: ");
            pin = input.nextInt();
            attempts = attempts + 1;
            if (pin == CORRECT_PIN) {
                isCorrect = true;
            } else {
                System.out.println("Wrong PIN. Attempts left: " + (MAX_ATTEMPTS - attempts));
            }
        }
        if (isCorrect) {
            System.out.println("Access granted.");
        } else {
            System.out.println("Card blocked.");
        }
    }
}
```

`and not isCorrect` becomes `&& !isCorrect`. The `if-else` inside the loop body shows that loops and decisions combine freely: any steps, including decisions, can go inside a loop.

```bash
javac PinCheck.java
java PinCheck
```

Output:

```text
Enter PIN: 1234
Wrong PIN. Attempts left: 2
Enter PIN: 4821
Access granted.
```

Run it again and type three wrong PINs:

Output:

```text
Enter PIN: 1111
Wrong PIN. Attempts left: 2
Enter PIN: 2222
Wrong PIN. Attempts left: 1
Enter PIN: 3333
Wrong PIN. Attempts left: 0
Card blocked.
```

---

## 4. Run and Test

Here is a loop where you cannot easily guess the number of rounds in your head, which makes it a good candidate for tracing. **Problem:** A savings account earns 10% interest per year. Given a starting balance and a target, calculate how many years it takes for the balance to reach the target, showing the balance after each year.

```text
Program SavingsGoal
{ Calculates how many years it takes for savings to reach a target with yearly interest }

Dictionary
    constant INTEREST_RATE : real = 0.10
    balance, target : real
    years : integer

Algorithm
    output("Starting balance: ")
    input(balance)
    output("Target          : ")
    input(target)
    years <- 0
    while balance < target do
        balance <- balance + balance * INTEREST_RATE
        years <- years + 1
        output("Year ", years, ": ", balance)
    endwhile
    output("Target reached after ", years, " years.")
```

Before writing any Java, trace it with a starting balance of 1000000 and a target of 1500000:

| Round | balance before | balance < target | balance after | years |
| --- | --- | --- | --- | --- |
| 1 | 1000000 | true | 1100000 | 1 |
| 2 | 1100000 | true | 1210000 | 2 |
| 3 | 1210000 | true | 1331000 | 3 |
| 4 | 1331000 | true | 1464100 | 4 |
| 5 | 1464100 | true | 1610510 | 5 |
| 6 | 1610510 | false | | 5 |

The trace predicts 5 years. Now create `SavingsGoal.java`:

```java
import java.util.Scanner;

// Program SavingsGoal
// Calculates how many years it takes for savings to reach a target with yearly interest.
public class SavingsGoal {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final double INTEREST_RATE = 0.10;
        double balance;
        double target;
        int years;

        // Algorithm
        System.out.print("Starting balance: ");
        balance = input.nextDouble();
        System.out.print("Target          : ");
        target = input.nextDouble();
        years = 0;
        while (balance < target) {
            balance = balance + balance * INTEREST_RATE;
            years = years + 1;
            System.out.printf("Year %d: %.2f%n", years, balance);
        }
        System.out.println("Target reached after " + years + " years.");
    }
}
```

```bash
javac SavingsGoal.java
java SavingsGoal
```

Output:

```text
Starting balance: 1000000
Target          : 1500000
Year 1: 1100000.00
Year 2: 1210000.00
Year 3: 1331000.00
Year 4: 1464100.00
Year 5: 1610510.00
Target reached after 5 years.
```

Every line matches a row of the trace. Now test the edge case where the starting balance already meets the target:

Output:

```text
Starting balance: 2000000
Target          : 1500000
Target reached after 0 years.
```

The condition is false at the first check, the loop body never runs, and the answer is 0 years, which is correct.

---

## 5. Fix the Errors in Your Code

Loop bugs are rarely caught by the compiler. The program compiles fine and then runs too many times, too few times, or forever. Tracing is the best tool for finding them.

**Error 1: Forgetting the update (an infinite loop).**

```java
// Wrong
public class Forever {
    public static void main(String[] args) {
        int counter = 1;
        while (counter <= 5) {
            System.out.println(counter);
        }
        System.out.println("Done");
    }
}

// Correct
public class Forever {
    public static void main(String[] args) {
        int counter = 1;
        while (counter <= 5) {
            System.out.println(counter);
            counter = counter + 1;
        }
        System.out.println("Done");
    }
}
```

The wrong version compiles, then prints `1` over and over, endlessly. These are the first lines it displays:

```text
1
1
1
1
1
```

Nothing in the body changes `counter`, so `counter <= 5` stays true forever and "Done" is never reached. This is an **infinite loop**. To stop a program stuck in one, press `Ctrl` + `C` in the terminal. Then check that your loop body contains an update that moves the condition toward false.

**Error 2: An off-by-one condition.**

```java
// Wrong
public class OffByOne {
    public static void main(String[] args) {
        int counter = 1;
        while (counter < 5) {
            System.out.println(counter);
            counter = counter + 1;
        }
    }
}

// Correct
public class OffByOne {
    public static void main(String[] args) {
        int counter = 1;
        while (counter <= 5) {
            System.out.println(counter);
            counter = counter + 1;
        }
    }
}
```

The wrong version displays only four numbers:

```text
1
2
3
4
```

When `counter` reaches 5, `counter < 5` is false, so 5 is never displayed. Running one round too many or too few is called an **off-by-one error**, and it is one of the most common bugs in programming. Check the last round of your trace: what is the loop variable's value, and should that round run?

**Error 3: A semicolon after the condition.**

```java
// Wrong
public class SemiWhile {
    public static void main(String[] args) {
        int counter = 1;
        while (counter <= 5); {
            System.out.println(counter);
            counter = counter + 1;
        }
        System.out.println("Done");
    }
}

// Correct
public class SemiWhile {
    public static void main(String[] args) {
        int counter = 1;
        while (counter <= 5) {
            System.out.println(counter);
            counter = counter + 1;
        }
        System.out.println("Done");
    }
}
```

The wrong version compiles, displays nothing at all, and never ends. You have to stop it with `Ctrl` + `C`. As with `if` in Lesson 7, the semicolon gives the `while` an empty body. The loop repeats that empty body forever, because the block below it, which contains the update, is no longer part of the loop and is never reached. A program that hangs silently right where a loop starts is a strong hint of this mistake.

---

## 6. Exercises

**Exercise 1:** Write the notation and the Java program `MultiplicationTable` that reads a number `n` and displays its multiplication table from 1 to 10 using a `while` loop, in the format `7 x  3 =  21`.

**Exercise 2:** Write the notation and the Java program `ReverseDigits` that reads a positive integer and displays its digits in reverse order. For example, 12345 becomes 54321. Hint: `number mod 10` gives the last digit, and `number div 10` removes it.

**Exercise 3:** Write the notation and the Java program `SumOfEvens` that reads `n` and displays the sum of all even numbers from 1 to `n`. Try to make the loop visit only even numbers. Test it with 10 and with an odd number such as 7.

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program MultiplicationTable
{ Displays the multiplication table of a number from 1 to 10 }

Dictionary
    n, i : integer

Algorithm
    output("Table of: ")
    input(n)
    i <- 1
    while i <= 10 do
        output(n, " x ", i, " = ", n * i)
        i <- i + 1
    endwhile
```

```java
import java.util.Scanner;

// Program MultiplicationTable
// Displays the multiplication table of a number from 1 to 10.
public class MultiplicationTable {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        int i;

        // Algorithm
        System.out.print("Table of: ");
        n = input.nextInt();
        i = 1;
        while (i <= 10) {
            System.out.printf("%d x %2d = %3d%n", n, i, n * i);
            i = i + 1;
        }
    }
}
```

`i` is the counter, running from 1 to 10. Each round multiplies `n` by the current `i`. The widths in `%2d` and `%3d` keep the columns aligned when the numbers grow to two or three digits.

```bash
javac MultiplicationTable.java
java MultiplicationTable
```

Output:

```text
Table of: 7
7 x  1 =   7
7 x  2 =  14
7 x  3 =  21
7 x  4 =  28
7 x  5 =  35
7 x  6 =  42
7 x  7 =  49
7 x  8 =  56
7 x  9 =  63
7 x 10 =  70
```

**Solution for Exercise 2:**

```text
Program ReverseDigits
{ Reverses the digits of a positive integer }

Dictionary
    number, reversed, lastDigit : integer

Algorithm
    output("Positive integer: ")
    input(number)
    reversed <- 0
    while number > 0 do
        lastDigit <- number mod 10
        reversed <- reversed * 10 + lastDigit
        number <- number div 10
    endwhile
    output("Reversed: ", reversed)
```

```java
import java.util.Scanner;

// Program ReverseDigits
// Reverses the digits of a positive integer.
public class ReverseDigits {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int number;
        int reversed;
        int lastDigit;

        // Algorithm
        System.out.print("Positive integer: ");
        number = input.nextInt();
        reversed = 0;
        while (number > 0) {
            lastDigit = number % 10;
            reversed = reversed * 10 + lastDigit;
            number = number / 10;
        }
        System.out.println("Reversed: " + reversed);
    }
}
```

Each round takes the last digit off `number` and attaches it to the end of `reversed`. Multiplying `reversed` by 10 shifts its digits one place to the left, making room for the new digit. For 12345, `reversed` grows as 5, 54, 543, 5432, 54321, while `number` shrinks to 0.

```bash
javac ReverseDigits.java
java ReverseDigits
```

Output:

```text
Positive integer: 12345
Reversed: 54321
```

**Solution for Exercise 3:**

```text
Program SumOfEvens
{ Adds up all even numbers from 1 to n }

Dictionary
    n, i, sum : integer

Algorithm
    output("n: ")
    input(n)
    sum <- 0
    i <- 2
    while i <= n do
        sum <- sum + i
        i <- i + 2
    endwhile
    output("Sum of even numbers from 1 to ", n, ": ", sum)
```

```java
import java.util.Scanner;

// Program SumOfEvens
// Adds up all even numbers from 1 to n.
public class SumOfEvens {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        int i;
        int sum;

        // Algorithm
        System.out.print("n: ");
        n = input.nextInt();
        sum = 0;
        i = 2;
        while (i <= n) {
            sum = sum + i;
            i = i + 2;
        }
        System.out.println("Sum of even numbers from 1 to " + n + ": " + sum);
    }
}
```

Starting `i` at 2 and adding 2 each round visits only even numbers, so no `if` is needed to check each one. This is half as many rounds as checking every number from 1 to `n`. For 10, the sum is 2 + 4 + 6 + 8 + 10 = 30. For 7, the loop stops after 6, giving 2 + 4 + 6 = 12.

```bash
javac SumOfEvens.java
java SumOfEvens
```

Output:

```text
n: 10
Sum of even numbers from 1 to 10: 30
```

Output:

```text
n: 7
Sum of even numbers from 1 to 7: 12
```

---

## Next Up - Lesson 10

In this lesson you added repetition with `while ... do ... endwhile` and Java's `while` statement. You learned that every loop needs an initialization, a condition, and an update; that a `while` body can run zero times because the condition is checked first; and how to stop loops with a counter, a sentinel value, a shrinking number, or a boolean flag. You also practiced tracing loops round by round to catch infinite loops and off-by-one errors.

`while` can express any loop, but two other forms make common cases clearer. In Lesson 10 you will learn `repeat ... until` for steps that must run at least once, such as showing a menu, and the counted `for` loop for when the number of rounds is known in advance, implementing them in Java with `do-while` and `for`.
