## 1. Before You Begin

In Lesson 9 you learned the `while` loop, which can express any kind of repetition. But two situations come up so often that algorithms give them their own forms. Sometimes a group of steps must run **at least once** before you can decide whether to repeat it: you cannot check whether the user typed a valid number before they have typed anything. Other times you know **exactly how many rounds** you need, such as "display the numbers 1 to 10," and managing the counter by hand is extra work and a source of off-by-one errors.

This lesson covers both. You will write `repeat ... until` in notation and implement it with Java's `do-while`, and you will write counted loops with `for ... to ... do` and implement them with Java's `for` statement. You will also put one loop inside another to draw patterns, and learn how to choose the right loop for a problem.

### What You'll Build

An input validator, a menu-driven counter program, a squares table, a factorial calculator, a star triangle drawn with nested loops, and a number guessing game.

### What You'll Learn

- ✅ How to write a loop that runs at least once with `repeat ... until`
- ✅ How to implement it with Java's `do-while`, and why the condition is reversed
- ✅ How to write a counted loop with `for i <- 1 to n do ... endfor`
- ✅ How to count down with `downto` and count in steps with `step`
- ✅ How to implement counted loops with Java's `for` statement
- ✅ How to nest one loop inside another
- ✅ How to choose between `while`, `repeat-until`, and `for`

### What You'll Need

- Lesson 9 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-10
cd ~/java-basics/lesson-10
```

---

## 2. Repeat-Until Loops

A `repeat ... until` loop runs its body first and checks the condition *afterward*. If the condition is false, it repeats. When the condition becomes true, it stops.

```text
repeat
    steps to repeat
until condition
```

Compare it with `while`:

| | `while ... do` | `repeat ... until` |
| --- | --- | --- |
| Condition checked | Before each round | After each round |
| Minimum rounds | 0 | 1 |
| Loop continues while the condition is | true | false |
| Loop stops when the condition is | false | true |

The last two rows are the important ones. A `while` condition says when to *keep going*; an `until` condition says when to *stop*.

Java does not have `repeat ... until`. It has **`do-while`**, which also checks after each round, but its condition says when to *keep going*, like `while`:

```java
do {
    // statements to repeat
} while (condition);
```

So when you translate `repeat ... until condition`, you write the **opposite** condition in the `do-while`. "Repeat until the number is positive" becomes "do ... while the number is not positive." Note the semicolon after the closing parenthesis; `do-while` is the only loop that needs one.

### Step 1: Validate Input

**Problem:** Ask the user for a positive number, and keep asking until they enter one.

```text
Program PositiveInput
{ Keeps asking until the user enters a positive number }

Dictionary
    number : integer

Algorithm
    repeat
        output("Enter a positive number: ")
        input(number)
    until number > 0
    output("Thank you, you entered ", number)
```

The prompt and the input must happen at least once, which makes `repeat ... until` a perfect fit. Unlike the sentinel loop in Lesson 9, there is no need for a separate read before the loop.

To translate the condition, reverse it: the opposite of `number > 0` is `number <= 0`. Create `PositiveInput.java`:

```java
import java.util.Scanner;

// Program PositiveInput
// Keeps asking until the user enters a positive number.
public class PositiveInput {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int number;

        // Algorithm
        do {
            System.out.print("Enter a positive number: ");
            number = input.nextInt();
        } while (number <= 0);
        System.out.println("Thank you, you entered " + number);
    }
}
```

The body runs once, then `number <= 0` is checked. If the number is zero or negative, the loop goes around again. As soon as a positive number is entered, the condition is false and the loop ends.

```bash
javac PositiveInput.java
java PositiveInput
```

Output:

```text
Enter a positive number: -5
Enter a positive number: 0
Enter a positive number: 12
Thank you, you entered 12
```

| Opposite of | Is |
| --- | --- |
| `x > 0` | `x <= 0` |
| `x = 4` | `x <> 4` (Java `x != 4`) |
| `a and b` | `not a or not b` |
| `a or b` | `not a and not b` |

The last two rows are useful when the condition has several parts. You can also simply wrap the whole `until` condition in `not ( )`, written `!( )` in Java.

### Step 2: Repeat a Menu

Menus are the classic use of `repeat ... until`: show the options, perform the chosen action, and repeat until the user chooses to exit.

```text
Program CounterMenu
{ Shows a menu repeatedly until the user chooses to exit }

Dictionary
    counter, choice : integer

Algorithm
    counter <- 0
    repeat
        output("--- Counter: ", counter, " ---")
        output("1. Add 1")
        output("2. Subtract 1")
        output("3. Reset")
        output("4. Exit")
        output("Choice: ")
        input(choice)
        depend on (choice)
            1 : counter <- counter + 1
            2 : counter <- counter - 1
            3 : counter <- 0
            4 : output("Goodbye!")
            otherwise : output("Invalid choice.")
        enddepend
    until choice = 4
```

The menu must appear at least once, and the loop stops when the choice is 4. The `depend on` inside the loop is the decision structure from Lesson 8.

Create `CounterMenu.java`:

```java
import java.util.Scanner;

// Program CounterMenu
// Shows a menu repeatedly until the user chooses to exit.
public class CounterMenu {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int counter;
        int choice;

        // Algorithm
        counter = 0;
        do {
            System.out.println("--- Counter: " + counter + " ---");
            System.out.println("1. Add 1");
            System.out.println("2. Subtract 1");
            System.out.println("3. Reset");
            System.out.println("4. Exit");
            System.out.print("Choice: ");
            choice = input.nextInt();
            switch (choice) {
                case 1 -> counter = counter + 1;
                case 2 -> counter = counter - 1;
                case 3 -> counter = 0;
                case 4 -> System.out.println("Goodbye!");
                default -> System.out.println("Invalid choice.");
            }
        } while (choice != 4);
    }
}
```

`until choice = 4` becomes `while (choice != 4)`. A `switch` sits inside the `do-while` body, and each case is a single statement.

```bash
javac CounterMenu.java
java CounterMenu
```

Choose 1 twice, then an invalid option, then 4.

Output:

```text
--- Counter: 0 ---
1. Add 1
2. Subtract 1
3. Reset
4. Exit
Choice: 1
--- Counter: 1 ---
1. Add 1
2. Subtract 1
3. Reset
4. Exit
Choice: 1
--- Counter: 2 ---
1. Add 1
2. Subtract 1
3. Reset
4. Exit
Choice: 5
Invalid choice.
--- Counter: 2 ---
1. Add 1
2. Subtract 1
3. Reset
4. Exit
Choice: 4
Goodbye!
```

You will use this exact menu pattern for the Student Grades app in the final project.

---

## 3. For Loops

When the number of rounds is known before the loop starts, a **counted loop** is the clearest choice. The notation puts the initialization, the limit, and the update into one line:

```text
for i <- 1 to n do
    steps to repeat
endfor
```

This means: "set `i` to 1, run the body, add 1 to `i`, and keep going until the round where `i` is `n` has run." The loop variable changes automatically; you must not change it inside the body.

Java's `for` statement packs the three parts of a loop into its header, separated by semicolons:

```java
for (initialization; condition; update) {
    // statements to repeat
}
```

| Notation | Java |
| --- | --- |
| `for i <- 1 to n do` | `for (i = 1; i <= n; i++) {` |
| `for i <- n downto 1 do` | `for (i = n; i >= 1; i--) {` |
| `for i <- 0 to 50 step 5 do` | `for (i = 0; i <= 50; i += 5) {` |
| `endfor` | `}` |

Java runs the initialization once, then checks the condition before each round, runs the body, and runs the update after each round. In other words, a `for` loop is a `while` loop with its three parts gathered in one place, which makes it much harder to forget the update.

### Step 1: Display a Table of Squares

```text
Program SquaresTable
{ Displays the numbers 1 to 5 with their squares using a for loop }

Dictionary
    i : integer

Algorithm
    for i <- 1 to 5 do
        output(i, " squared is ", i * i)
    endfor
```

Create `SquaresTable.java`:

```java
// Program SquaresTable
// Displays the numbers 1 to 5 with their squares using a for loop.
public class SquaresTable {
    public static void main(String[] args) {
        // Dictionary
        int i;

        // Algorithm
        for (i = 1; i <= 5; i++) {
            System.out.println(i + " squared is " + (i * i));
        }
    }
}
```

`i = 1` runs once at the start. `i <= 5` is checked before each round. `i++` (the shorthand from Lesson 5) runs after each round. Compare it with `CountToFive` from Lesson 9: the same three parts, but all visible in the first line of the loop.

```bash
javac SquaresTable.java
java SquaresTable
```

Output:

```text
1 squared is 1
2 squared is 4
3 squared is 9
4 squared is 16
5 squared is 25
```

### Step 2: Count Down and Count in Steps

```text
Program CountingPatterns
{ Shows for loops that count down and count in steps }

Dictionary
    i : integer

Algorithm
    output("Down from 10: ")
    for i <- 10 downto 1 do
        output(i, " ")
    endfor
    output("Steps of 5  : ")
    for i <- 0 to 50 step 5 do
        output(i, " ")
    endfor
```

`downto` counts backward by 1. `step 5` adds 5 each round instead of 1.

In Java, it is common to declare the loop variable right inside the `for` header. Create `CountingPatterns.java`:

```java
// Program CountingPatterns
// Shows for loops that count down and count in steps.
public class CountingPatterns {
    public static void main(String[] args) {
        // Algorithm
        System.out.print("Down from 10: ");
        for (int i = 10; i >= 1; i--) {
            System.out.print(i + " ");
        }
        System.out.println();

        System.out.print("Steps of 5  : ");
        for (int i = 0; i <= 50; i += 5) {
            System.out.print(i + " ");
        }
        System.out.println();
    }
}
```

`for (int i = 10; ...)` declares `i` as part of the loop. A variable declared this way exists only inside that loop, which is why the second loop can declare its own `i` without a conflict. The first loop counts down with `i--` and a `>=` condition; the second counts up by 5 with `i += 5`.

```bash
javac CountingPatterns.java
java CountingPatterns
```

Output:

```text
Down from 10: 10 9 8 7 6 5 4 3 2 1 
Steps of 5  : 0 5 10 15 20 25 30 35 40 45 50 
```

### Step 3: Calculate a Factorial

The **factorial** of n, written n!, is the product 1 x 2 x 3 x ... x n. For example, 5! = 120. By definition, 0! = 1.

```text
Program Factorial
{ Calculates n! = 1 x 2 x ... x n with a for loop }

Dictionary
    n, i : integer
    factorial : integer

Algorithm
    output("n: ")
    input(n)
    factorial <- 1
    for i <- 1 to n do
        factorial <- factorial * i
    endfor
    output(n, "! = ", factorial)
```

This is the accumulator idea from Lesson 9, but for multiplication. A sum starts at 0 because adding 0 changes nothing; a product starts at 1 because multiplying by 1 changes nothing.

Create `Factorial.java`:

```java
import java.util.Scanner;

// Program Factorial
// Calculates n! = 1 x 2 x ... x n with a for loop.
public class Factorial {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        long factorial;

        // Algorithm
        System.out.print("n: ");
        n = input.nextInt();
        factorial = 1;
        for (int i = 1; i <= n; i++) {
            factorial = factorial * i;
        }
        System.out.println(n + "! = " + factorial);
    }
}
```

Factorials grow very quickly: 13! is already larger than the largest `int`. Declaring `factorial` as `long` (from Lesson 4) lets the program handle values up to 20!.

```bash
javac Factorial.java
java Factorial
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

Output:

```text
n: 20
20! = 2432902008176640000
```

For 0, the condition `1 <= 0` is false right away, the body never runs, and `factorial` keeps its starting value of 1, which is exactly the definition of 0!.

### Step 4: Nest One Loop Inside Another

A loop body can contain another loop. For every round of the **outer loop**, the **inner loop** runs completely. **Problem:** Read a number of rows and draw a right triangle of stars, where row 1 has one star, row 2 has two, and so on.

```text
Program StarTriangle
{ Draws a right triangle of stars with nested for loops }

Dictionary
    rows, row, col : integer

Algorithm
    output("Number of rows: ")
    input(rows)
    for row <- 1 to rows do
        for col <- 1 to row do
            output("*")
        endfor
        output(new line)
    endfor
```

The outer loop picks a row. The inner loop draws that row's stars, and its limit is `row`, the outer loop's variable, so each row has one more star than the last. `output(new line)` moves to the next line after each row.

Create `StarTriangle.java`:

```java
import java.util.Scanner;

// Program StarTriangle
// Draws a right triangle of stars with nested for loops.
public class StarTriangle {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int rows;

        // Algorithm
        System.out.print("Number of rows: ");
        rows = input.nextInt();
        for (int row = 1; row <= rows; row++) {
            for (int col = 1; col <= row; col++) {
                System.out.print("*");
            }
            System.out.println();
        }
    }
}
```

`print("*")` keeps the stars on the same line. The `println()` after the inner loop, but still inside the outer loop, ends each row.

```bash
javac StarTriangle.java
java StarTriangle
```

Output:

```text
Number of rows: 5
*
**
***
****
*****
```

---

## 4. Run and Test

A guessing game combines `repeat ... until` with an else-if chain. **Problem:** The program has a secret number from 1 to 100. The user keeps guessing; after each wrong guess the program says "Too low." or "Too high." When the guess is right, it displays how many attempts it took.

```text
Program GuessNumber
{ The user guesses a secret number from 1 to 100, with hints after each guess }

Dictionary
    constant SECRET : integer = 37
    guess, attempts : integer

Algorithm
    attempts <- 0
    repeat
        output("Your guess (1-100): ")
        input(guess)
        attempts <- attempts + 1
        if guess < SECRET then
            output("Too low.")
        else if guess > SECRET then
            output("Too high.")
        endif
    until guess = SECRET
    output("Correct! You found it in ", attempts, " attempts.")
```

The chain has no `else`: when the guess is correct, neither hint is displayed, and the `until` condition ends the loop. The secret is a constant so the game behaves the same every time you test it.

Create `GuessNumber.java`:

```java
import java.util.Scanner;

// Program GuessNumber
// The user guesses a secret number from 1 to 100, with hints after each guess.
public class GuessNumber {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int SECRET = 37;
        int guess;
        int attempts;

        // Algorithm
        attempts = 0;
        do {
            System.out.print("Your guess (1-100): ");
            guess = input.nextInt();
            attempts = attempts + 1;
            if (guess < SECRET) {
                System.out.println("Too low.");
            } else if (guess > SECRET) {
                System.out.println("Too high.");
            }
        } while (guess != SECRET);
        System.out.println("Correct! You found it in " + attempts + " attempts.");
    }
}
```

```bash
javac GuessNumber.java
java GuessNumber
```

Play using a smart strategy: always guess the middle of the range that is still possible.

Output:

```text
Your guess (1-100): 50
Too high.
Your guess (1-100): 25
Too low.
Your guess (1-100): 40
Too high.
Your guess (1-100): 37
Correct! You found it in 4 attempts.
```

Each hint cuts the possible range roughly in half: 1 to 100, then 1 to 49, then 26 to 49, then 26 to 39. This "halve the range each time" strategy is the idea behind **binary search**, one of the most important algorithms you will implement in Lesson 19.

---

## 5. Choosing the Right Loop

All three loops can solve any repetition problem, but choosing the one that matches the problem makes the algorithm clearer and avoids bugs. Ask these questions in order:

| Question | If yes, use | Typical examples |
| --- | --- | --- |
| Do you know the number of rounds before the loop starts? | `for` | Display 1 to n, process every item in a list, draw n rows |
| Must the body run at least once before you can decide? | `repeat ... until` (`do-while`) | Input validation, menus, games |
| Otherwise (the loop may need zero rounds, and the count is unknown) | `while` | Sentinel input, digit counting, waiting for a target |

"Known number of rounds" does not mean the number is written in the code; `for i <- 1 to n` is still a counted loop even though `n` comes from the user, because `n` is known before the loop starts.

---

## 6. Fix the Errors in Your Code

**Error 1: Copying the `until` condition into `do-while` without reversing it.**

```java
// Wrong
import java.util.Scanner;

public class UntilWrong {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        int number;
        do {
            System.out.print("Enter a positive number: ");
            number = input.nextInt();
        } while (number > 0);
        System.out.println("Thank you, you entered " + number);
    }
}

// Correct
import java.util.Scanner;

public class UntilWrong {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        int number;
        do {
            System.out.print("Enter a positive number: ");
            number = input.nextInt();
        } while (number <= 0);
        System.out.println("Thank you, you entered " + number);
    }
}
```

The wrong version compiles but does the exact opposite of what was intended. A valid number makes it ask again:

```text
Enter a positive number: 12
Enter a positive number: 
```

And an invalid number is accepted:

```text
Enter a positive number: -5
Thank you, you entered -5
```

The notation said `until number > 0`, which means "stop when positive." Java's `do-while` needs "continue while not positive," which is `number <= 0`. Every time you translate `repeat ... until`, reverse the condition.

**Error 2: A missing semicolon after `do-while`.**

```java
// Wrong
public class NoSemi {
    public static void main(String[] args) {
        int i = 1;
        do {
            System.out.println(i);
            i++;
        } while (i <= 3)
    }
}

// Correct
public class NoSemi {
    public static void main(String[] args) {
        int i = 1;
        do {
            System.out.println(i);
            i++;
        } while (i <= 3);
    }
}
```

The wrong version produces:

```text
NoSemi.java:7: error: ';' expected
        } while (i <= 3)
                        ^
1 error
```

`while` and `for` loops must *not* have a semicolon after their condition (you saw the bug that causes in Lesson 9), but `do-while` *must* have one, because the condition comes at the end of the statement.

**Error 3: Using a `for` loop variable after the loop.**

```java
// Wrong
public class Scope {
    public static void main(String[] args) {
        int sum = 0;
        for (int i = 1; i <= 5; i++) {
            sum = sum + i;
        }
        System.out.println("Last i: " + i + ", sum: " + sum);
    }
}

// Correct
public class Scope {
    public static void main(String[] args) {
        int sum = 0;
        int i;
        for (i = 1; i <= 5; i++) {
            sum = sum + i;
        }
        System.out.println("Last i: " + i + ", sum: " + sum);
    }
}
```

The wrong version produces:

```text
Scope.java:7: error: cannot find symbol
        System.out.println("Last i: " + i + ", sum: " + sum);
                                        ^
  symbol:   variable i
  location: class Scope
1 error
```

A variable declared inside the `for` header exists only inside that loop. The part of a program where a variable exists is called its **scope**. If you need the loop variable after the loop, declare it before the loop, as in the Dictionary. (The correct version displays `Last i: 6, sum: 15`, since `i` stops at the first value that fails the condition.)

---

## 7. Exercises

**Exercise 1:** Write the notation and the Java program `SumToN` that reads `n` and adds the numbers from 1 to `n` with a `for` loop. Then check your answer with the formula n x (n + 1) / 2 and display both results.

**Exercise 2:** Write the notation and the Java program `StarPyramid` that reads a number of rows and draws a centered pyramid. Row `r` of a pyramid with `rows` rows has `rows - r` spaces followed by `2r - 1` stars. For 4 rows:

```text
   *
  ***
 *****
*******
```

**Exercise 3:** Write the notation and the Java program `ValidScore` that reads a score and keeps asking until it is between 0 and 100. After each invalid entry, display "Invalid, please try again."

---

## 8. Solutions

**Solution for Exercise 1:**

```text
Program SumToN
{ Adds the numbers from 1 to n with a for loop and checks the result with a formula }

Dictionary
    n, i, sum : integer

Algorithm
    output("n: ")
    input(n)
    sum <- 0
    for i <- 1 to n do
        sum <- sum + i
    endfor
    output("Sum with a loop   : ", sum)
    output("Sum with a formula: ", n * (n + 1) div 2)
```

```java
import java.util.Scanner;

// Program SumToN
// Adds the numbers from 1 to n with a for loop and checks the result with a formula.
public class SumToN {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        int sum;

        // Algorithm
        System.out.print("n: ");
        n = input.nextInt();
        sum = 0;
        for (int i = 1; i <= n; i++) {
            sum = sum + i;
        }
        System.out.println("Sum with a loop   : " + sum);
        System.out.println("Sum with a formula: " + (n * (n + 1) / 2));
    }
}
```

The loop runs exactly `n` rounds, so `for` is the natural choice. The formula gives the same answer without a loop. It is a reminder that a better algorithm can sometimes replace many steps with one, an idea you will meet again when comparing search and sort algorithms.

```bash
javac SumToN.java
java SumToN
```

Output:

```text
n: 100
Sum with a loop   : 5050
Sum with a formula: 5050
```

**Solution for Exercise 2:**

```text
Program StarPyramid
{ Draws a centered pyramid of stars }

Dictionary
    rows, row, s, star : integer

Algorithm
    output("Number of rows: ")
    input(rows)
    for row <- 1 to rows do
        for s <- 1 to rows - row do
            output(" ")
        endfor
        for star <- 1 to 2 * row - 1 do
            output("*")
        endfor
        output(new line)
    endfor
```

```java
import java.util.Scanner;

// Program StarPyramid
// Draws a centered pyramid of stars.
public class StarPyramid {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int rows;

        // Algorithm
        System.out.print("Number of rows: ");
        rows = input.nextInt();
        for (int row = 1; row <= rows; row++) {
            for (int s = 1; s <= rows - row; s++) {
                System.out.print(" ");
            }
            for (int star = 1; star <= 2 * row - 1; star++) {
                System.out.print("*");
            }
            System.out.println();
        }
    }
}
```

The outer loop has two inner loops, one after the other: the first prints the leading spaces and the second prints the stars. As `row` grows, the number of spaces shrinks and the number of stars grows by two, which centers each row under the one above it.

```bash
javac StarPyramid.java
java StarPyramid
```

Output:

```text
Number of rows: 4
   *
  ***
 *****
*******
```

**Solution for Exercise 3:**

```text
Program ValidScore
{ Reads a score, asking again until it is between 0 and 100 }

Dictionary
    score : integer

Algorithm
    repeat
        output("Score (0-100): ")
        input(score)
        if score < 0 or score > 100 then
            output("Invalid, please try again.")
        endif
    until score >= 0 and score <= 100
    output("Score saved: ", score)
```

```java
import java.util.Scanner;

// Program ValidScore
// Reads a score, asking again until it is between 0 and 100.
public class ValidScore {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int score;

        // Algorithm
        do {
            System.out.print("Score (0-100): ");
            score = input.nextInt();
            if (score < 0 || score > 100) {
                System.out.println("Invalid, please try again.");
            }
        } while (score < 0 || score > 100);
        System.out.println("Score saved: " + score);
    }
}
```

The `until` condition is "the score is in range": `score >= 0 and score <= 100`. Its opposite, using the table from Section 2, is `score < 0 or score > 100`, which becomes the `do-while` condition. The same expression is used inside the `if` to decide when to show the error message.

```bash
javac ValidScore.java
java ValidScore
```

Output:

```text
Score (0-100): 120
Invalid, please try again.
Score (0-100): -3
Invalid, please try again.
Score (0-100): 88
Score saved: 88
```

---

## Next Up - Lesson 11

In this lesson you completed your set of loops. `repeat ... until` runs its body at least once and stops when its condition becomes true; in Java it becomes `do-while` with the condition reversed. The counted `for` loop gathers initialization, condition, and update into one line, can count up, down, or in steps, and can be nested to process rows and columns. You also learned how to choose the right loop for a problem.

Knowing how to write loops is one thing; knowing *what to do* inside them is another. In Lesson 11 you will learn the classic loop patterns that appear in almost every program: counting items that match a condition, summing and averaging values, finding the minimum and maximum, and validating input, each designed in notation and implemented in Java.
