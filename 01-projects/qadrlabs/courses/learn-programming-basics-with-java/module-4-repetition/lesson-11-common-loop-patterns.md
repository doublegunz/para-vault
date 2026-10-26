## 1. Before You Begin

In Lessons 9 and 10 you learned *how* to write loops: `while`, `repeat ... until`, and `for`. Now comes a more interesting question: *what* do you put inside them? It turns out that a small number of patterns appear again and again. Counting how many scores pass, adding up a list of prices, finding the highest temperature of the week, checking whether every student passed: each of these is a classic **loop pattern** with a well-known shape.

Experienced programmers do not invent these from scratch every time. They recognize the pattern a problem needs and apply it. In this lesson you will learn the most important patterns, design each one in notation, implement it in Java, and then combine several of them in one program. You will use these patterns in nearly every remaining lesson, especially when you start working with arrays in Module 6.

### What You'll Build

A pass counter, a price total and average calculator, a minimum and maximum finder, an "all passed / any perfect" checker, and a daily sales summary that combines every pattern in one loop.

### What You'll Learn

- ✅ The counter pattern: count items that match a condition
- ✅ The accumulator pattern: sum values and calculate an average
- ✅ The extreme value pattern: find the minimum and maximum
- ✅ The flag pattern: check whether all items, or any item, match a condition
- ✅ The validation pattern: repeat input until it is valid
- ✅ How to combine several patterns in a single loop
- ✅ How to handle the "no data" case safely

### What You'll Need

- Lessons 9 and 10 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-11
cd ~/java-basics/lesson-11
```

---

## 2. Counting and Summing

The first two patterns both use a variable that starts at a fixed value *before* the loop and is updated *inside* the loop. The only difference is what gets added each round.

| Pattern | Before the loop | Inside the loop | After the loop |
| --- | --- | --- | --- |
| Counter | `count <- 0` | `if condition then count <- count + 1` | `count` is the number of matches |
| Accumulator (sum) | `total <- 0` | `total <- total + value` | `total` is the sum; `total / n` is the average |

### Step 1: Count Items That Match a Condition

**Problem:** Read `n` scores and count how many of them pass (75 or higher).

```text
Program CountPassing
{ Reads n scores and counts how many of them pass }

Dictionary
    constant PASSING_SCORE : integer = 75
    n, i, score, passCount : integer

Algorithm
    output("How many scores? ")
    input(n)
    passCount <- 0
    for i <- 1 to n do
        output("Score ", i, ": ")
        input(score)
        if score >= PASSING_SCORE then
            passCount <- passCount + 1
        endif
    endfor
    output(passCount, " of ", n, " students passed.")
```

The number of scores is known before the loop, so it is a `for` loop. The counter starts at 0 and grows by 1 only when the condition is true. Each score is read, used, and then replaced by the next one; the algorithm never needs to remember old scores, only the count.

Create `CountPassing.java`:

```java
import java.util.Scanner;

// Program CountPassing
// Reads n scores and counts how many of them pass.
public class CountPassing {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int PASSING_SCORE = 75;
        int n;
        int score;
        int passCount;

        // Algorithm
        System.out.print("How many scores? ");
        n = input.nextInt();
        passCount = 0;
        for (int i = 1; i <= n; i++) {
            System.out.print("Score " + i + ": ");
            score = input.nextInt();
            if (score >= PASSING_SCORE) {
                passCount = passCount + 1;
            }
        }
        System.out.println(passCount + " of " + n + " students passed.");
    }
}
```

The prompt includes the loop variable `i`, so the user always knows which score they are typing. The `if` inside the loop is the counter's condition.

```bash
javac CountPassing.java
java CountPassing
```

Output:

```text
How many scores? 5
Score 1: 80
Score 2: 62
Score 3: 75
Score 4: 91
Score 5: 70
3 of 5 students passed.
```

80, 75, and 91 pass, so the count is 3. The score of exactly 75 is counted, which confirms that the condition uses `>=`.

### Step 2: Sum Values and Calculate an Average

**Problem:** Read the number of items in a shopping basket and the price of each item, then display the total and the average price. The number of items must be positive.

```text
Program SumAndAverage
{ Reads n prices, then displays their total and average }

Dictionary
    n, i : integer
    price, total, average : real

Algorithm
    repeat
        output("How many items? ")
        input(n)
    until n > 0
    total <- 0
    for i <- 1 to n do
        output("Price of item ", i, ": ")
        input(price)
        total <- total + price
    endfor
    average <- total / n
    output("Total  : ", total)
    output("Average: ", average)
```

The accumulator `total` starts at 0, and each price is added to it. The average is calculated *after* the loop, once all the prices are known. The `repeat ... until` at the start is the **validation pattern** from Lesson 10: it guarantees that `n` is positive, which also protects the division `total / n` from dividing by zero.

Create `SumAndAverage.java`:

```java
import java.util.Scanner;

// Program SumAndAverage
// Reads n prices, then displays their total and average.
public class SumAndAverage {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        double price;
        double total;
        double average;

        // Algorithm
        do {
            System.out.print("How many items? ");
            n = input.nextInt();
        } while (n <= 0);
        total = 0;
        for (int i = 1; i <= n; i++) {
            System.out.print("Price of item " + i + ": ");
            price = input.nextDouble();
            total = total + price;
        }
        average = total / n;
        System.out.printf("Total  : %.2f%n", total);
        System.out.printf("Average: %.2f%n", average);
    }
}
```

`total` is a `double`, so `total / n` is real division, and the average keeps its decimal part.

```bash
javac SumAndAverage.java
java SumAndAverage
```

Output:

```text
How many items? 0
How many items? 3
Price of item 1: 12500
Price of item 2: 8000
Price of item 3: 23750
Total  : 44250.00
Average: 14750.00
```

The validation loop rejected 0 and asked again. 12500 + 8000 + 23750 is 44250, and divided by 3 that is 14750.

---

## 3. Finding the Minimum and Maximum

The **extreme value pattern** keeps track of the smallest or largest value seen so far. Each new value is compared with the current record, and if it beats the record, it becomes the new record.

The tricky part is the starting value. What should `max` be before any number has been read? The safest answer is: **the first value itself.** Read the first value before the loop, use it to initialize both `min` and `max`, and let the loop handle the remaining values.

### Step 1: Track the Smallest and Largest

**Problem:** Read `n` integers (which may be negative) and display the smallest and the largest.

```text
Program MinMax
{ Reads n numbers and displays the smallest and the largest }

Dictionary
    n, i, number, min, max : integer

Algorithm
    repeat
        output("How many numbers? ")
        input(n)
    until n > 0
    output("Number 1: ")
    input(number)
    min <- number
    max <- number
    for i <- 2 to n do
        output("Number ", i, ": ")
        input(number)
        if number < min then
            min <- number
        endif
        if number > max then
            max <- number
        endif
    endfor
    output("Smallest: ", min)
    output("Largest : ", max)
```

The first number is read outside the loop, so the loop starts at 2. The two `if` statements are separate, not an `if-else`, because a single number could in principle update one record or the other, and checking both is simple and always correct.

Create `MinMax.java`:

```java
import java.util.Scanner;

// Program MinMax
// Reads n numbers and displays the smallest and the largest.
public class MinMax {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        int number;
        int min;
        int max;

        // Algorithm
        do {
            System.out.print("How many numbers? ");
            n = input.nextInt();
        } while (n <= 0);
        System.out.print("Number 1: ");
        number = input.nextInt();
        min = number;
        max = number;
        for (int i = 2; i <= n; i++) {
            System.out.print("Number " + i + ": ");
            number = input.nextInt();
            if (number < min) {
                min = number;
            }
            if (number > max) {
                max = number;
            }
        }
        System.out.println("Smallest: " + min);
        System.out.println("Largest : " + max);
    }
}
```

```bash
javac MinMax.java
java MinMax
```

Output:

```text
How many numbers? 5
Number 1: -4
Number 2: 17
Number 3: -9
Number 4: 3
Number 5: 8
Smallest: -9
Largest : 17
```

Trace how the records change: after -4, both are -4; 17 becomes the new max; -9 becomes the new min; 3 and 8 change nothing. Now test the smallest possible input, a single number:

Output:

```text
How many numbers? 1
Number 1: 42
Smallest: 42
Largest : 42
```

With `n` equal to 1, the loop from 2 to 1 runs zero times, and the first number is correctly both the smallest and the largest.

---

## 4. Checking All or Any with a Flag

Sometimes you do not need a number at all, only a yes or no answer about the whole list. "Did *every* student pass?" "Is there *any* perfect score?" The **flag pattern** answers these with a `boolean` variable.

| Question | Start the flag at | Change it when | Reason |
| --- | --- | --- | --- |
| Do **all** items match? | `true` | an item does **not** match | One failure is enough to make "all" false |
| Does **any** item match? | `false` | an item **does** match | One success is enough to make "any" true |

### Step 1: Check All and Any in One Loop

**Problem:** Read `n` scores, then report whether everyone passed and whether anyone got a perfect score of 100.

```text
Program AllPassed
{ Checks whether every score passes and whether any score is perfect }

Dictionary
    constant PASSING_SCORE : integer = 75
    n, i, score : integer
    allPassed, anyPerfect : boolean

Algorithm
    output("How many scores? ")
    input(n)
    allPassed <- true
    anyPerfect <- false
    for i <- 1 to n do
        output("Score ", i, ": ")
        input(score)
        if score < PASSING_SCORE then
            allPassed <- false
        endif
        if score = 100 then
            anyPerfect <- true
        endif
    endfor
    output("Everyone passed : ", allPassed)
    output("A perfect score : ", anyPerfect)
```

Notice that neither flag is ever set back. Once `allPassed` becomes false, no later passing score can make it true again, and that is exactly right: one failure is enough.

Create `AllPassed.java`:

```java
import java.util.Scanner;

// Program AllPassed
// Checks whether every score passes and whether any score is perfect.
public class AllPassed {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int PASSING_SCORE = 75;
        int n;
        int score;
        boolean allPassed;
        boolean anyPerfect;

        // Algorithm
        System.out.print("How many scores? ");
        n = input.nextInt();
        allPassed = true;
        anyPerfect = false;
        for (int i = 1; i <= n; i++) {
            System.out.print("Score " + i + ": ");
            score = input.nextInt();
            if (score < PASSING_SCORE) {
                allPassed = false;
            }
            if (score == 100) {
                anyPerfect = true;
            }
        }
        System.out.println("Everyone passed : " + allPassed);
        System.out.println("A perfect score : " + anyPerfect);
    }
}
```

```bash
javac AllPassed.java
java AllPassed
```

Output:

```text
How many scores? 4
Score 1: 80
Score 2: 100
Score 3: 90
Score 4: 77
Everyone passed : true
A perfect score : true
```

Output:

```text
How many scores? 3
Score 1: 80
Score 2: 60
Score 3: 90
Everyone passed : false
A perfect score : false
```

In the second run, the 60 turns `allPassed` to false, and the 90 that follows does not change it back.

---

## 5. Run and Test

Real programs often combine several patterns in a single loop. **Problem:** A shop owner types in the sales for each day, ending with -1. Display the number of days recorded, the total sales, the average per day, the best day, and how many days reached the target of 500000. If no days are entered, say so.

This problem uses five patterns at once: a sentinel loop (Lesson 9), a counter for the days, an accumulator for the total, an extreme value for the best day, and a conditional counter for the days on target.

```text
Program DailySales
{ Reads daily sales until -1, then displays a summary }

Dictionary
    constant SENTINEL : integer = -1
    constant TARGET   : integer = 500000
    sales, days, total, best, daysOnTarget : integer

Algorithm
    days <- 0
    total <- 0
    best <- 0
    daysOnTarget <- 0
    output("Sales for day 1 (-1 to finish): ")
    input(sales)
    while sales <> SENTINEL do
        days <- days + 1
        total <- total + sales
        if days = 1 or sales > best then
            best <- sales
        endif
        if sales >= TARGET then
            daysOnTarget <- daysOnTarget + 1
        endif
        output("Sales for day ", days + 1, " (-1 to finish): ")
        input(sales)
    endwhile
    if days = 0 then
        output("No sales data entered.")
    else
        output("Days recorded  : ", days)
        output("Total sales    : ", total)
        output("Average per day: ", total / days)
        output("Best day       : ", best)
        output("Days on target : ", daysOnTarget)
    endif
```

With a sentinel loop you cannot read the first value separately to initialize `best`, so the condition `days = 1 or sales > best` does the same job: on the first day, the first sale always becomes the record. The final `if` handles the "no data" case, so the average is only calculated when `days` is greater than 0.

Create `DailySales.java`:

```java
import java.util.Scanner;

// Program DailySales
// Reads daily sales until -1, then displays a summary.
public class DailySales {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int SENTINEL = -1;
        final int TARGET = 500000;
        int sales;
        int days;
        int total;
        int best;
        int daysOnTarget;

        // Algorithm
        days = 0;
        total = 0;
        best = 0;
        daysOnTarget = 0;
        System.out.print("Sales for day 1 (-1 to finish): ");
        sales = input.nextInt();
        while (sales != SENTINEL) {
            days = days + 1;
            total = total + sales;
            if (days == 1 || sales > best) {
                best = sales;
            }
            if (sales >= TARGET) {
                daysOnTarget = daysOnTarget + 1;
            }
            System.out.print("Sales for day " + (days + 1) + " (-1 to finish): ");
            sales = input.nextInt();
        }
        if (days == 0) {
            System.out.println("No sales data entered.");
        } else {
            System.out.println("Days recorded  : " + days);
            System.out.println("Total sales    : " + total);
            System.out.printf("Average per day: %.2f%n", (double) total / days);
            System.out.println("Best day       : " + best);
            System.out.println("Days on target : " + daysOnTarget);
        }
    }
}
```

The average uses a cast to `double`, because `total` and `days` are both integers.

```bash
javac DailySales.java
java DailySales
```

Before running, predict the results for sales of 450000, 620000, 380000, and 510000: 4 days, a total of 1960000, an average of 490000, a best day of 620000, and 2 days on target.

Output:

```text
Sales for day 1 (-1 to finish): 450000
Sales for day 2 (-1 to finish): 620000
Sales for day 3 (-1 to finish): 380000
Sales for day 4 (-1 to finish): 510000
Sales for day 5 (-1 to finish): -1
Days recorded  : 4
Total sales    : 1960000
Average per day: 490000.00
Best day       : 620000
Days on target : 2
```

Then test the empty case:

Output:

```text
Sales for day 1 (-1 to finish): -1
No sales data entered.
```

Both results match the predictions, and the empty case does not crash.

---

## 6. Fix the Errors in Your Code

Pattern bugs usually come from a wrong starting value or an update in the wrong place. The program compiles and runs, but the answer is quietly wrong.

**Error 1: Starting the maximum at 0.**

```java
// Wrong
import java.util.Scanner;

public class Warmest {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        int temperature;
        int max = 0;
        for (int i = 1; i <= 3; i++) {
            System.out.print("Temperature " + i + ": ");
            temperature = input.nextInt();
            if (temperature > max) {
                max = temperature;
            }
        }
        System.out.println("Warmest: " + max);
    }
}

// Correct
import java.util.Scanner;

public class Warmest {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        int temperature;
        int max;
        System.out.print("Temperature 1: ");
        temperature = input.nextInt();
        max = temperature;
        for (int i = 2; i <= 3; i++) {
            System.out.print("Temperature " + i + ": ");
            temperature = input.nextInt();
            if (temperature > max) {
                max = temperature;
            }
        }
        System.out.println("Warmest: " + max);
    }
}
```

With winter temperatures of -8, -3, and -12, the wrong version displays:

```text
Temperature 1: -8
Temperature 2: -3
Temperature 3: -12
Warmest: 0
```

The correct version displays:

```text
Temperature 1: -8
Temperature 2: -3
Temperature 3: -12
Warmest: -3
```

No temperature was 0, but 0 is larger than every negative value, so it was never replaced. Starting `max` at 0 only works when all values are positive. Initialize it with the first real value instead.

**Error 2: Resetting the accumulator inside the loop.**

```java
// Wrong
public class ResetInside {
    public static void main(String[] args) {
        int sum;
        for (int i = 1; i <= 5; i++) {
            sum = 0;
            sum = sum + i;
            System.out.println("After adding " + i + ": " + sum);
        }
    }
}

// Correct
public class ResetInside {
    public static void main(String[] args) {
        int sum = 0;
        for (int i = 1; i <= 5; i++) {
            sum = sum + i;
            System.out.println("After adding " + i + ": " + sum);
        }
    }
}
```

The wrong version displays:

```text
After adding 1: 1
After adding 2: 2
After adding 3: 3
After adding 4: 4
After adding 5: 5
```

Each round throws away the total so far and starts again from 0, so `sum` only ever holds the current `i`. The initialization of an accumulator, counter, or flag belongs *before* the loop, so it happens once. With the fix, the last line would show 15.

**Error 3: Calculating an average when there is no data.**

```java
// Wrong
public class AvgZero {
    public static void main(String[] args) {
        int total = 0;
        int count = 0;
        System.out.println("Average: " + (total / count));
    }
}

// Correct
public class AvgZero {
    public static void main(String[] args) {
        int total = 0;
        int count = 0;
        if (count == 0) {
            System.out.println("No data entered.");
        } else {
            System.out.println("Average: " + ((double) total / count));
        }
    }
}
```

The wrong version crashes:

```text
Exception in thread "main" java.lang.ArithmeticException: / by zero
	at AvgZero.main(AvgZero.java:5)
```

Integer division by zero is impossible, so Java stops the program with an exception. Casting to `double` does not really fix it either: with real division, Java displays `Average: NaN` ("not a number") instead of crashing, which is still meaningless to a user. Whenever a loop may run zero times, check the count before dividing, as `DailySales` does.

---

## 7. Exercises

**Exercise 1:** Write the notation and the Java program `EvenOddCount` that reads `n` integers and counts how many are even and how many are odd.

**Exercise 2:** Write the notation and the Java program `AgeRange` that reads ages until the user types 0, then displays the youngest age, the oldest age, and the average age with one decimal place. If no ages are entered, display "No ages entered."

**Exercise 3:** Write the notation and the Java program `ScoreReport` that reads the number of students (positive) and a score for each student. Each score must be validated to be between 0 and 100. Display the average score, the number of A grades (85 or higher), and whether all students passed (75 or higher).

---

## 8. Solutions

**Solution for Exercise 1:**

```text
Program EvenOddCount
{ Reads n integers and counts how many are even and how many are odd }

Dictionary
    n, i, number, evenCount, oddCount : integer

Algorithm
    output("How many numbers? ")
    input(n)
    evenCount <- 0
    oddCount <- 0
    for i <- 1 to n do
        output("Number ", i, ": ")
        input(number)
        if number mod 2 = 0 then
            evenCount <- evenCount + 1
        else
            oddCount <- oddCount + 1
        endif
    endfor
    output("Even: ", evenCount)
    output("Odd : ", oddCount)
```

```java
import java.util.Scanner;

// Program EvenOddCount
// Reads n integers and counts how many are even and how many are odd.
public class EvenOddCount {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        int number;
        int evenCount;
        int oddCount;

        // Algorithm
        System.out.print("How many numbers? ");
        n = input.nextInt();
        evenCount = 0;
        oddCount = 0;
        for (int i = 1; i <= n; i++) {
            System.out.print("Number " + i + ": ");
            number = input.nextInt();
            if (number % 2 == 0) {
                evenCount = evenCount + 1;
            } else {
                oddCount = oddCount + 1;
            }
        }
        System.out.println("Even: " + evenCount);
        System.out.println("Odd : " + oddCount);
    }
}
```

Two counters share one loop. Because every number is either even or odd, an `if-else` updates exactly one counter per round, and the two counts always add up to `n`.

```bash
javac EvenOddCount.java
java EvenOddCount
```

Output:

```text
How many numbers? 6
Number 1: 4
Number 2: 7
Number 3: 10
Number 4: 15
Number 5: 22
Number 6: 9
Even: 3
Odd : 3
```

**Solution for Exercise 2:**

```text
Program AgeRange
{ Reads ages until 0, then displays the youngest, the oldest, and the average age }

Dictionary
    age, count, total, youngest, oldest : integer

Algorithm
    count <- 0
    total <- 0
    youngest <- 0
    oldest <- 0
    output("Age (0 to stop): ")
    input(age)
    while age <> 0 do
        count <- count + 1
        total <- total + age
        if count = 1 then
            youngest <- age
            oldest <- age
        else
            if age < youngest then
                youngest <- age
            endif
            if age > oldest then
                oldest <- age
            endif
        endif
        output("Age (0 to stop): ")
        input(age)
    endwhile
    if count = 0 then
        output("No ages entered.")
    else
        output("Youngest: ", youngest)
        output("Oldest  : ", oldest)
        output("Average : ", total / count)
    endif
```

```java
import java.util.Scanner;

// Program AgeRange
// Reads ages until 0, then displays the youngest, the oldest, and the average age.
public class AgeRange {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int age;
        int count;
        int total;
        int youngest;
        int oldest;

        // Algorithm
        count = 0;
        total = 0;
        youngest = 0;
        oldest = 0;
        System.out.print("Age (0 to stop): ");
        age = input.nextInt();
        while (age != 0) {
            count = count + 1;
            total = total + age;
            if (count == 1) {
                youngest = age;
                oldest = age;
            } else {
                if (age < youngest) {
                    youngest = age;
                }
                if (age > oldest) {
                    oldest = age;
                }
            }
            System.out.print("Age (0 to stop): ");
            age = input.nextInt();
        }
        if (count == 0) {
            System.out.println("No ages entered.");
        } else {
            System.out.println("Youngest: " + youngest);
            System.out.println("Oldest  : " + oldest);
            System.out.printf("Average : %.1f%n", (double) total / count);
        }
    }
}
```

This combines a sentinel loop with a counter, an accumulator, and two extreme values. The first age initializes both records (when `count` is 1), and later ages update them. `youngest` and `oldest` are also set to 0 before the loop only so Java knows they always have a value; those zeros are never displayed, because the "no data" check comes first.

```bash
javac AgeRange.java
java AgeRange
```

Output:

```text
Age (0 to stop): 34
Age (0 to stop): 8
Age (0 to stop): 61
Age (0 to stop): 25
Age (0 to stop): 0
Youngest: 8
Oldest  : 61
Average : 32.0
```

Output:

```text
Age (0 to stop): 0
No ages entered.
```

**Solution for Exercise 3:**

```text
Program ScoreReport
{ Reads valid scores, then reports the average, the number of A grades, and whether all passed }

Dictionary
    constant PASSING_SCORE : integer = 75
    constant A_SCORE       : integer = 85
    n, i, score, total, aCount : integer
    allPassed : boolean

Algorithm
    repeat
        output("How many students? ")
        input(n)
    until n > 0
    total <- 0
    aCount <- 0
    allPassed <- true
    for i <- 1 to n do
        repeat
            output("Score of student ", i, ": ")
            input(score)
        until score >= 0 and score <= 100
        total <- total + score
        if score >= A_SCORE then
            aCount <- aCount + 1
        endif
        if score < PASSING_SCORE then
            allPassed <- false
        endif
    endfor
    output("Average   : ", total / n)
    output("A grades  : ", aCount)
    output("All passed: ", allPassed)
```

```java
import java.util.Scanner;

// Program ScoreReport
// Reads valid scores, then reports the average, the number of A grades, and whether all passed.
public class ScoreReport {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int PASSING_SCORE = 75;
        final int A_SCORE = 85;
        int n;
        int score;
        int total;
        int aCount;
        boolean allPassed;

        // Algorithm
        do {
            System.out.print("How many students? ");
            n = input.nextInt();
        } while (n <= 0);
        total = 0;
        aCount = 0;
        allPassed = true;
        for (int i = 1; i <= n; i++) {
            do {
                System.out.print("Score of student " + i + ": ");
                score = input.nextInt();
            } while (score < 0 || score > 100);
            total = total + score;
            if (score >= A_SCORE) {
                aCount = aCount + 1;
            }
            if (score < PASSING_SCORE) {
                allPassed = false;
            }
        }
        System.out.printf("Average   : %.2f%n", (double) total / n);
        System.out.println("A grades  : " + aCount);
        System.out.println("All passed: " + allPassed);
    }
}
```

A validation loop is nested inside the `for` loop, so each score is checked before it is used. The `for` loop's counter `i` does not change while the inner loop repeats, which is why the prompt asks for "student 2" again after an invalid entry. An accumulator, a counter, and a flag all share the same loop.

```bash
javac ScoreReport.java
java ScoreReport
```

Output:

```text
How many students? 4
Score of student 1: 88
Score of student 2: 105
Score of student 2: 92
Score of student 3: 70
Score of student 4: 85
Average   : 83.75
A grades  : 3
All passed: false
```

The invalid 105 was rejected, and student 2 was asked again. The scores 88, 92, 70, and 85 average 83.75, three of them are A grades, and the 70 means not everyone passed.

---

## Next Up - Lesson 12

In this lesson you learned the loop patterns that appear in almost every program: counters for matching items, accumulators for sums and averages, extreme values for minimums and maximums, flags for "all" and "any" questions, and validation loops for safe input. You also combined several patterns in one loop and protected your averages against the "no data" case. Module 4 is complete, and you now have all three building blocks: sequence, selection, and repetition.

Your programs are getting longer, and some steps, like printing a separator line or validating a score, appear in several places. In Lesson 12 you will start Module 5 and learn to break an algorithm into named **procedures**, call them from the main algorithm, and implement them in Java as `void` methods, keeping your programs short, organized, and easy to read.
