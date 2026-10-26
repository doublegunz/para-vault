## 1. Before You Begin

Every variable you have used so far holds exactly one value. That works for a single price or a single score, but real data usually comes in lists: the scores of a whole class, the temperatures of a week, the sales of a month. In Lesson 11 you calculated averages without storing the individual values, which worked because each value was used once and thrown away. But try this problem: "read five scores, then list the ones above the average." The average is only known after the *last* score is read, and by then the earlier scores are gone.

An **array** solves this. It is a single variable that holds a whole list of values of the same type, each one identified by its position. In this lesson you will declare arrays in notation and Java, fill them with input, traverse them with loops, and write procedures and functions that work on whole arrays. Arrays are the foundation of Module 6 and of the searching and sorting algorithms in Module 7.

### What You'll Build

A program that stores and displays scores, a program that lists scores above the average, functions that sum an array and find the position of its largest element, a procedure that reverses an array in place, and a weekly temperature report.

### What You'll Learn

- ✅ What an array is: elements, indexes, and length
- ✅ How to declare arrays in notation (`array [0..4] of integer`) and Java (`int[]`)
- ✅ How to read and write elements with `a[i]`
- ✅ How to traverse an array with a loop
- ✅ How to pass arrays to procedures and functions
- ✅ Why a procedure *can* change the elements of an array it receives
- ✅ How to avoid the most common array error: an index out of bounds

### What You'll Need

- Lessons 11 to 13 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-15
cd ~/java-basics/lesson-15
```

---

## 2. Declaring and Using Arrays

Picture an array as a row of numbered boxes, all of the same type. Each box is an **element**, and its number is its **index**. In Java, and in this course's notation, indexes start at **0**, so an array of 5 elements has indexes 0, 1, 2, 3, and 4.

```text
index:     0    1    2    3    4
         +----+----+----+----+----+
scores:  | 80 | 65 | 92 | 74 | 88 |
         +----+----+----+----+----+
```

The number of elements is the array's **length**. The last index is always length minus 1.

| | Notation | Java |
| --- | --- | --- |
| Declare an array of 5 integers | `scores : array [0..4] of integer` | `int[] scores = new int[5];` |
| Declare with values | `scores : array [0..4] of integer = {80, 65, 92, 74, 88}` | `int[] scores = {80, 65, 92, 74, 88};` |
| Element at index `i` | `scores[i]` | `scores[i]` |
| Store a value | `scores[2] <- 92` | `scores[2] = 92;` |
| Length | `length(scores)` | `scores.length` |

In Java, `int[]` means "array of `int`." `new int[5]` creates the array with room for 5 elements, all starting at 0. Once created, an array's length cannot change.

### Step 1: Store and Display Values

```text
Program ArrayBasics
{ Stores five scores in an array and displays them }

Dictionary
    scores : array [0..4] of integer
    i : integer

Algorithm
    scores[0] <- 80
    scores[1] <- 65
    scores[2] <- 92
    scores[3] <- 74
    scores[4] <- 88
    output("First score : ", scores[0])
    output("Third score : ", scores[2])
    output("Array length: ", length(scores))
    for i <- 0 to length(scores) - 1 do
        output("scores[", i, "] = ", scores[i])
    endfor
```

Each element behaves like an ordinary variable: you can assign to it, read it, and use it in expressions. The real power appears in the `for` loop: by using the loop variable `i` as the index, one line of code processes every element. Visiting every element of an array in order is called **traversing** the array. Note that the third score is at index 2, because counting starts at 0.

Create `ArrayBasics.java`:

```java
// Program ArrayBasics
// Stores five scores in an array and displays them.
public class ArrayBasics {
    public static void main(String[] args) {
        // Dictionary
        int[] scores = new int[5];

        // Algorithm
        scores[0] = 80;
        scores[1] = 65;
        scores[2] = 92;
        scores[3] = 74;
        scores[4] = 88;
        System.out.println("First score : " + scores[0]);
        System.out.println("Third score : " + scores[2]);
        System.out.println("Array length: " + scores.length);
        for (int i = 0; i < scores.length; i++) {
            System.out.println("scores[" + i + "] = " + scores[i]);
        }
    }
}
```

The loop condition is `i < scores.length`, which is the Java way of writing `i <= length(scores) - 1`. Using `scores.length` instead of the number 5 means the loop still works if the array size changes later. This loop header, `for (int i = 0; i < a.length; i++)`, is the standard way to traverse an array in Java, and you will write it many times.

```bash
javac ArrayBasics.java
java ArrayBasics
```

Output:

```text
First score : 80
Third score : 92
Array length: 5
scores[0] = 80
scores[1] = 65
scores[2] = 92
scores[3] = 74
scores[4] = 88
```

### Step 2: Solve a Problem That Needs an Array

Now the problem from the introduction. **Problem:** Read 5 scores, display their average, then list every score above the average.

```text
Program AboveAverage
{ Reads n scores into an array, then lists the scores above the average }

Dictionary
    constant N : integer = 5
    scores : array [0..N-1] of integer
    i, total : integer
    average : real

Algorithm
    total <- 0
    for i <- 0 to N - 1 do
        output("Score ", i + 1, ": ")
        input(scores[i])
        total <- total + scores[i]
    endfor
    average <- total / N
    output("Average: ", average)
    output("Above average:")
    for i <- 0 to N - 1 do
        if scores[i] > average then
            output(" ", scores[i])
        endif
    endfor
```

The algorithm makes **two passes** over the data. The first pass reads the scores into the array and adds them up. The second pass goes over the stored scores again and compares each one with the average. Without the array, the second pass would be impossible. The prompt shows `i + 1` so the user sees "Score 1" to "Score 5" even though the indexes are 0 to 4. Using a constant `N` for the size keeps the declaration and both loops consistent.

Create `AboveAverage.java`:

```java
import java.util.Scanner;

// Program AboveAverage
// Reads n scores into an array, then lists the scores above the average.
public class AboveAverage {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int N = 5;
        int[] scores = new int[N];
        int total;
        double average;

        // Algorithm
        total = 0;
        for (int i = 0; i < N; i++) {
            System.out.print("Score " + (i + 1) + ": ");
            scores[i] = input.nextInt();
            total = total + scores[i];
        }
        average = (double) total / N;
        System.out.printf("Average: %.2f%n", average);
        System.out.print("Above average:");
        for (int i = 0; i < N; i++) {
            if (scores[i] > average) {
                System.out.print(" " + scores[i]);
            }
        }
        System.out.println();
    }
}
```

`input(scores[i])` becomes `scores[i] = input.nextInt();`: the value read from the keyboard is stored directly in element `i`.

```bash
javac AboveAverage.java
java AboveAverage
```

Output:

```text
Score 1: 80
Score 2: 65
Score 3: 92
Score 4: 74
Score 5: 88
Average: 79.80
Above average: 80 92 88
```

---

## 3. Arrays and Subprograms

Arrays become even more useful when combined with the procedures and functions from Module 5. A subprogram that receives an array can work with every element, and it does not need to know the array's size in advance, because it can ask for the length.

### Step 1: Pass an Array to a Function

**Problem:** Given the sales of a week, display the total, the highest sales, and the day it happened. Write a function for the total and another that returns the *position* of the largest element.

Returning the index instead of the value is more useful: with the index you can get the value (`sales[best]`) *and* know which day it was.

```text
Program ArrayFunctions
{ Uses functions that receive an array: sum, maximum, and the position of the maximum }

Dictionary
    sales : array [0..6] of integer = {120, 340, 95, 410, 260, 410, 180}
    best : integer
    function Sum(a : array of integer) -> integer
    function IndexOfMax(a : array of integer) -> integer

Algorithm
    best <- IndexOfMax(sales)
    output("Days recorded : ", length(sales))
    output("Total sales   : ", Sum(sales))
    output("Highest sales : ", sales[best])
    output("On day number : ", best + 1)

function Sum(a : array of integer) -> integer
{ Returns the sum of all elements of a }
Dictionary
    i, total : integer
Algorithm
    total <- 0
    for i <- 0 to length(a) - 1 do
        total <- total + a[i]
    endfor
    -> total

function IndexOfMax(a : array of integer) -> integer
{ Returns the index of the first largest element of a, a has at least one element }
Dictionary
    i, maxIndex : integer
Algorithm
    maxIndex <- 0
    for i <- 1 to length(a) - 1 do
        if a[i] > a[maxIndex] then
            maxIndex <- i
        endif
    endfor
    -> maxIndex
```

The parameter type `array of integer` has no size, so the function works with arrays of any length. `IndexOfMax` uses the extreme value pattern from Lesson 11, with the first element as the starting record. Because it uses `>` and not `>=`, ties keep the *first* largest element: the value 410 appears twice, and the function returns the earlier one.

Create `ArrayFunctions.java`:

```java
// Program ArrayFunctions
// Uses functions that receive an array: sum, maximum, and the position of the maximum.
public class ArrayFunctions {
    public static void main(String[] args) {
        // Dictionary
        int[] sales = {120, 340, 95, 410, 260, 410, 180};
        int best;

        // Algorithm
        best = indexOfMax(sales);
        System.out.println("Days recorded : " + sales.length);
        System.out.println("Total sales   : " + sum(sales));
        System.out.println("Highest sales : " + sales[best]);
        System.out.println("On day number : " + (best + 1));
    }

    // Function Sum
    // Returns the sum of all elements of a
    static int sum(int[] a) {
        int total = 0;
        for (int i = 0; i < a.length; i++) {
            total = total + a[i];
        }
        return total;
    }

    // Function IndexOfMax
    // Returns the index of the first largest element of a, a has at least one element
    static int indexOfMax(int[] a) {
        int maxIndex = 0;
        for (int i = 1; i < a.length; i++) {
            if (a[i] > a[maxIndex]) {
                maxIndex = i;
            }
        }
        return maxIndex;
    }
}
```

`int[] sales = {120, 340, ...};` creates an array and fills it in one step; Java counts the values to set the length. A parameter declared as `int[] a` accepts any `int` array, and `a.length` tells the function how many elements it received.

```bash
javac ArrayFunctions.java
java ArrayFunctions
```

Output:

```text
Days recorded : 7
Total sales   : 1815
Highest sales : 410
On day number : 4
```

Index 3 holds the first 410, which is day 4 for a human reader.

### Step 2: Change an Array Inside a Procedure

In Lesson 12, a `swap` procedure could not change the caller's variables, because Java passes a copy of each simple value. Arrays are different. When you pass an array, Java passes a **reference** to it, which works like the address of the array in memory. The procedure's parameter and the caller's variable then refer to the *same* array, so changes made to the elements inside the procedure are visible to the caller. In notation terms, an array parameter in Java behaves like an `input/output` parameter.

**Problem:** Reverse the elements of an array in place, without creating a new array.

The idea is to swap the first and last elements, then the second and second to last, and so on, moving two markers toward the middle until they meet:

```text
Program ReverseArray
{ Reverses an array in place with a procedure }

Dictionary
    numbers : array [0..5] of integer = {1, 2, 3, 4, 5, 6}
    procedure Reverse(input/output a : array of integer)
    procedure PrintArray(input a : array of integer)

Algorithm
    output("Before: ")
    PrintArray(numbers)
    Reverse(numbers)
    output("After : ")
    PrintArray(numbers)

procedure Reverse(input/output a : array of integer)
{ I.S.: a is defined }
{ F.S.: the elements of a are in reverse order }
Dictionary
    left, right, temp : integer
Algorithm
    left <- 0
    right <- length(a) - 1
    while left < right do
        temp <- a[left]
        a[left] <- a[right]
        a[right] <- temp
        left <- left + 1
        right <- right - 1
    endwhile

procedure PrintArray(input a : array of integer)
{ I.S.: a is defined }
{ F.S.: the elements of a are displayed on one line }
Dictionary
    i : integer
Algorithm
    for i <- 0 to length(a) - 1 do
        output(a[i], " ")
    endfor
    output(new line)
```

The three swap lines are the algorithm from Lesson 4, applied to two array elements. The loop stops when `left` and `right` meet or cross, so each pair is swapped exactly once.

Create `ReverseArray.java`:

```java
// Program ReverseArray
// Reverses an array in place with a procedure.
public class ReverseArray {
    public static void main(String[] args) {
        // Dictionary
        int[] numbers = {1, 2, 3, 4, 5, 6};

        // Algorithm
        System.out.print("Before: ");
        printArray(numbers);
        reverse(numbers);
        System.out.print("After : ");
        printArray(numbers);
    }

    // Procedure Reverse
    // I.S.: a is defined
    // F.S.: the elements of a are in reverse order
    static void reverse(int[] a) {
        int left = 0;
        int right = a.length - 1;
        int temp;
        while (left < right) {
            temp = a[left];
            a[left] = a[right];
            a[right] = temp;
            left = left + 1;
            right = right - 1;
        }
    }

    // Procedure PrintArray
    // I.S.: a is defined
    // F.S.: the elements of a are displayed on one line
    static void printArray(int[] a) {
        for (int i = 0; i < a.length; i++) {
            System.out.print(a[i] + " ");
        }
        System.out.println();
    }
}
```

`reverse` is a `void` method that changes `a[left]` and `a[right]`. Because `a` refers to the same array as `numbers` in `main`, the second `printArray` call shows the reversed order.

```bash
javac ReverseArray.java
java ReverseArray
```

Output:

```text
Before: 1 2 3 4 5 6 
After : 6 5 4 3 2 1 
```

This is the swap that failed in Lesson 12, now working, because array elements are shared between the caller and the procedure. The sorting algorithms in Lesson 20 rely on exactly this behavior.

---

## 4. Run and Test

Arrays of different types can work together when they share the same indexes. **Problem:** Read the temperature for each day of a week, then display the average, the hottest day by name, and the names of the days above the average.

Use two **parallel arrays**: `days` holds the names and `temps` holds the temperatures. Element `i` of one array belongs with element `i` of the other.

```text
Program WeeklyTemperature
{ Reads a temperature for each day of the week and reports the average, the hottest day,
  and the days above average }

Dictionary
    days  : array [0..6] of string = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"}
    temps : array [0..6] of real
    i, hottest : integer
    total, average : real

Algorithm
    total <- 0
    for i <- 0 to 6 do
        output(days[i], ": ")
        input(temps[i])
        total <- total + temps[i]
    endfor
    average <- total / 7
    hottest <- 0
    for i <- 1 to 6 do
        if temps[i] > temps[hottest] then
            hottest <- i
        endif
    endfor
    output("Average temperature: ", average)
    output("Hottest day        : ", days[hottest], " (", temps[hottest], ")")
    output("Above average      :")
    for i <- 0 to 6 do
        if temps[i] > average then
            output(" ", days[i])
        endif
    endfor
```

`hottest` stores an index, so it can be used in both arrays: `temps[hottest]` is the temperature and `days[hottest]` is the name of that day.

Create `WeeklyTemperature.java`:

```java
import java.util.Scanner;

// Program WeeklyTemperature
// Reads a temperature for each day of the week and reports the average, the hottest day,
// and the days above average.
public class WeeklyTemperature {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String[] days = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
        double[] temps = new double[days.length];
        double total;
        double average;
        int hottest;

        // Algorithm
        total = 0;
        for (int i = 0; i < days.length; i++) {
            System.out.print(days[i] + ": ");
            temps[i] = input.nextDouble();
            total = total + temps[i];
        }
        average = total / days.length;
        hottest = 0;
        for (int i = 1; i < days.length; i++) {
            if (temps[i] > temps[hottest]) {
                hottest = i;
            }
        }
        System.out.printf("Average temperature: %.1f%n", average);
        System.out.println("Hottest day        : " + days[hottest] + " (" + temps[hottest] + ")");
        System.out.print("Above average      :");
        for (int i = 0; i < days.length; i++) {
            if (temps[i] > average) {
                System.out.print(" " + days[i]);
            }
        }
        System.out.println();
    }
}
```

`String[]` is an array of strings and `double[]` an array of real numbers. `new double[days.length]` makes `temps` exactly as long as `days`, so the two arrays always match.

```bash
javac WeeklyTemperature.java
java WeeklyTemperature
```

Output:

```text
Mon: 31.5
Tue: 33.0
Wed: 29.8
Thu: 34.2
Fri: 32.1
Sat: 30.4
Sun: 28.9
Average temperature: 31.4
Hottest day        : Thu (34.2)
Above average      : Mon Tue Thu Fri
```

Check the result by hand: the seven temperatures add up to 219.9, and 219.9 / 7 is about 31.41. Thursday's 34.2 is the highest, and Monday, Tuesday, Thursday, and Friday are the only days above 31.41.

---

## 5. Fix the Errors in Your Code

**Error 1: An index out of bounds.**

```java
// Wrong
public class OutOfBounds {
    public static void main(String[] args) {
        int[] scores = {80, 65, 92, 74, 88};
        for (int i = 0; i <= scores.length; i++) {
            System.out.println(scores[i]);
        }
    }
}

// Correct
public class OutOfBounds {
    public static void main(String[] args) {
        int[] scores = {80, 65, 92, 74, 88};
        for (int i = 0; i < scores.length; i++) {
            System.out.println(scores[i]);
        }
    }
}
```

The wrong version prints all five scores, then crashes:

```text
80
65
92
74
88
Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index 5 out of bounds for length 5
	at OutOfBounds.main(OutOfBounds.java:5)
```

An array of length 5 has indexes 0 to 4. With `<=`, the loop also tries index 5, which does not exist. This is the off-by-one error from Lesson 9 in its most common form. The message tells you the bad index and the array's length. When traversing with indexes starting at 0, always use `i < a.length`.

**Error 2: Printing an array directly.**

```java
// Wrong
public class PrintDirect {
    public static void main(String[] args) {
        int[] scores = {80, 65, 92};
        System.out.println(scores);
    }
}

// Correct
import java.util.Arrays;

public class PrintDirect {
    public static void main(String[] args) {
        int[] scores = {80, 65, 92};
        System.out.println(Arrays.toString(scores));
    }
}
```

The wrong version compiles and runs, but displays something like:

```text
[I@2a139a55
```

The exact characters after `@` differ on each computer and each run. `println` does not know how to display the contents of an array, so it shows a code that identifies the array object (`[I` means "array of int"). To display the elements, traverse the array with a loop, as `printArray` does, or use `Arrays.toString` from the `java.util.Arrays` class, which produces:

```text
[80, 65, 92]
```

**Error 3: Starting the loop at 1 and skipping the first element.**

```java
// Wrong
public class SkipFirst {
    public static void main(String[] args) {
        int[] prices = {15000, 8000, 23000};
        int total = 0;
        for (int i = 1; i < prices.length; i++) {
            total = total + prices[i];
        }
        System.out.println("Total: " + total);
    }
}

// Correct
public class SkipFirst {
    public static void main(String[] args) {
        int[] prices = {15000, 8000, 23000};
        int total = 0;
        for (int i = 0; i < prices.length; i++) {
            total = total + prices[i];
        }
        System.out.println("Total: " + total);
    }
}
```

The wrong version displays:

```text
Total: 31000
```

The correct total is 46000. Starting at 1 is a habit from counting things in daily life, but array indexes start at 0, so the first price was never added. There is no error message, which makes this bug easy to miss. Starting at 1 is only correct when index 0 was already handled before the loop, as in `IndexOfMax`.

---

## 6. Exercises

**Exercise 1:** Write the notation and the Java program `CountAbove` with a function `CountGreater(a : array of integer, limit : integer) -> integer` that returns how many elements of `a` are greater than `limit`. Use it on an array of heights `{152, 167, 171, 158, 180, 165, 175}` with limits 160, 170, and 190.

**Exercise 2:** Write the notation and the Java program `RunningTotal` that takes an array of weekly deposits `{50000, 20000, 75000, 10000, 45000}` and builds a second array `balance` where each element is the total of all deposits up to and including that week. Display both arrays as a table.

**Exercise 3:** Write the notation and the Java program `DiceFrequency` that reads dice rolls (1 to 6) until the user types 0, then displays how many times each face appeared, followed by a bar of stars. Use an array of counters indexed by the face value.

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program CountAbove
{ Counts how many elements of an array are greater than a limit, using a function }

Dictionary
    heights : array [0..6] of integer = {152, 167, 171, 158, 180, 165, 175}
    function CountGreater(a : array of integer, limit : integer) -> integer

Algorithm
    output("Taller than 160 cm: ", CountGreater(heights, 160))
    output("Taller than 170 cm: ", CountGreater(heights, 170))
    output("Taller than 190 cm: ", CountGreater(heights, 190))

function CountGreater(a : array of integer, limit : integer) -> integer
{ Returns how many elements of a are greater than limit }
Dictionary
    i, count : integer
Algorithm
    count <- 0
    for i <- 0 to length(a) - 1 do
        if a[i] > limit then
            count <- count + 1
        endif
    endfor
    -> count
```

```java
// Program CountAbove
// Counts how many elements of an array are greater than a limit, using a function.
public class CountAbove {
    public static void main(String[] args) {
        // Dictionary
        int[] heights = {152, 167, 171, 158, 180, 165, 175};

        // Algorithm
        System.out.println("Taller than 160 cm: " + countGreater(heights, 160));
        System.out.println("Taller than 170 cm: " + countGreater(heights, 170));
        System.out.println("Taller than 190 cm: " + countGreater(heights, 190));
    }

    // Function CountGreater
    // Returns how many elements of a are greater than limit
    static int countGreater(int[] a, int limit) {
        int count = 0;
        for (int i = 0; i < a.length; i++) {
            if (a[i] > limit) {
                count = count + 1;
            }
        }
        return count;
    }
}
```

This is the counter pattern from Lesson 11 applied to an array. Because the data is stored, the same function can be called three times with different limits without reading anything again.

```bash
javac CountAbove.java
java CountAbove
```

Output:

```text
Taller than 160 cm: 5
Taller than 170 cm: 3
Taller than 190 cm: 0
```

**Solution for Exercise 2:**

```text
Program RunningTotal
{ Builds a new array where each element is the total of all elements up to that position }

Dictionary
    deposits : array [0..4] of integer = {50000, 20000, 75000, 10000, 45000}
    balance  : array [0..4] of integer
    i : integer

Algorithm
    balance[0] <- deposits[0]
    for i <- 1 to 4 do
        balance[i] <- balance[i - 1] + deposits[i]
    endfor
    output("Week  Deposit  Balance")
    for i <- 0 to 4 do
        output(i + 1, " ", deposits[i], " ", balance[i])
    endfor
```

```java
// Program RunningTotal
// Builds a new array where each element is the total of all elements up to that position.
public class RunningTotal {
    public static void main(String[] args) {
        // Dictionary
        int[] deposits = {50000, 20000, 75000, 10000, 45000};
        int[] balance = new int[deposits.length];

        // Algorithm
        balance[0] = deposits[0];
        for (int i = 1; i < deposits.length; i++) {
            balance[i] = balance[i - 1] + deposits[i];
        }
        System.out.println("Week  Deposit  Balance");
        for (int i = 0; i < deposits.length; i++) {
            System.out.printf("%4d %8d %8d%n", i + 1, deposits[i], balance[i]);
        }
    }
}
```

Each balance is the *previous* balance plus this week's deposit. `balance[i - 1]` reads the element just before the current one, which is why the first element is set before the loop and the loop starts at 1. Using a neighboring element like this is a common array technique.

```bash
javac RunningTotal.java
java RunningTotal
```

Output:

```text
Week  Deposit  Balance
   1    50000    50000
   2    20000    70000
   3    75000   145000
   4    10000   155000
   5    45000   200000
```

**Solution for Exercise 3:**

```text
Program DiceFrequency
{ Reads dice rolls until 0 and counts how often each face appears }

Dictionary
    count : array [0..6] of integer = {0, 0, 0, 0, 0, 0, 0}
    roll, face, k : integer

Algorithm
    output("Rolls (1-6, 0 to stop): ")
    input(roll)
    while roll <> 0 do
        if roll >= 1 and roll <= 6 then
            count[roll] <- count[roll] + 1
        endif
        input(roll)
    endwhile
    for face <- 1 to 6 do
        output("Face ", face, ": ", count[face], " ")
        for k <- 1 to count[face] do
            output("*")
        endfor
        output(new line)
    endfor
```

```java
import java.util.Scanner;

// Program DiceFrequency
// Reads dice rolls until 0 and counts how often each face appears.
public class DiceFrequency {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int[] count = new int[7];
        int roll;

        // Algorithm
        System.out.print("Rolls (1-6, 0 to stop): ");
        roll = input.nextInt();
        while (roll != 0) {
            if (roll >= 1 && roll <= 6) {
                count[roll] = count[roll] + 1;
            }
            roll = input.nextInt();
        }
        for (int face = 1; face <= 6; face++) {
            System.out.print("Face " + face + ": " + count[face] + " ");
            for (int k = 1; k <= count[face]; k++) {
                System.out.print("*");
            }
            System.out.println();
        }
    }
}
```

The trick is to use the roll itself as the index: a roll of 3 adds 1 to `count[3]`. Instead of six separate counters and a six-way decision, one line handles every face. The array has 7 elements so that indexes 1 to 6 match the faces directly; index 0 is simply not used. `new int[7]` starts every counter at 0. The rolls can be typed on one line, because `Scanner` reads them one at a time.

```bash
javac DiceFrequency.java
java DiceFrequency
```

Output:

```text
Rolls (1-6, 0 to stop): 3 6 1 3 5 3 6 2 3 6 4 0
Face 1: 1 *
Face 2: 1 *
Face 3: 4 ****
Face 4: 1 *
Face 5: 1 *
Face 6: 3 ***
```

---

## Next Up - Lesson 16

In this lesson you learned to store lists of values in arrays. You declared arrays in notation and Java, accessed elements by index starting at 0, traversed arrays with loops, and used them to solve problems that need the data more than once. You also passed arrays to functions and procedures, and saw that, unlike simple values, array elements changed inside a procedure stay changed for the caller.

A one-dimensional array is a single row of values. Many kinds of data are better shown as a table: the scores of several students in several subjects, the seats in a cinema, or a game board. In Lesson 16 you will work with **two-dimensional arrays**, traverse them row by row and column by column with nested loops, and implement table and matrix algorithms in Java.
