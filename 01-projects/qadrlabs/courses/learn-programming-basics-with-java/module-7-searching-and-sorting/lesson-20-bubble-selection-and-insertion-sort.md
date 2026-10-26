## 1. Before You Begin

In Lesson 19 you saw how much faster binary search is than sequential search, but only on sorted data. Sorted data is useful far beyond searching: a ranked leaderboard, a class list in alphabetical order, the cheapest products first, the median of a set of scores. Putting data in order is so common that **sorting** is one of the most studied problems in computer science.

This lesson covers three classic sorting algorithms. Each one sorts an array in place by comparing elements and moving them around, and each one has a different strategy:

- **Bubble sort** repeatedly swaps neighbors that are in the wrong order, so large values "bubble" to the end.
- **Selection sort** repeatedly selects the smallest remaining value and puts it in its final position.
- **Insertion sort** takes each value in turn and inserts it into its correct place among the values before it, like sorting playing cards in your hand.

You will design each algorithm in notation, watch it work pass by pass, implement it in Java, and count how much work each one does. These algorithms rely on two techniques you already know: the swap with a temporary variable from Lesson 4, and procedures that change an array's elements from Lesson 15.

### What You'll Build

Three sorting programs that display the array after every pass, a program that compares the three algorithms on 1000 elements, and a leaderboard that ranks players by score.

### What You'll Learn

- ✅ What it means to sort an array in place
- ✅ How bubble sort works, and how to stop early when the array is already sorted
- ✅ How selection sort works
- ✅ How insertion sort works
- ✅ How to trace a sorting algorithm pass by pass
- ✅ How to compare sorting algorithms by counting comparisons
- ✅ How to sort records by a field and strings alphabetically

### What You'll Need

- Lessons 15, 18, and 19 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-20
cd ~/java-basics/lesson-20
```

---

## 2. Bubble Sort

Bubble sort walks through the array comparing each pair of neighbors: elements 0 and 1, then 1 and 2, then 2 and 3, and so on. Whenever a pair is in the wrong order, it swaps them. One complete walk is called a **pass**. After the first pass, the largest value has been carried all the way to the last position, like a bubble rising to the surface. After the second pass, the second largest value is in the second to last position, and so on.

Each pass therefore fixes one more element at the end, so the next pass can stop one position earlier. And if a whole pass makes no swaps, every neighbor is already in order and the array is sorted, so the algorithm can stop early.

### Step 1: Sort and Watch Each Pass

```text
Program BubbleSort
{ Sorts an array with bubble sort, displaying the array after each pass }

Dictionary
    numbers : array [0..4] of integer = {29, 10, 14, 37, 13}
    procedure BubbleSort(input/output a : array of integer)
    procedure PrintArray(input a : array of integer)

Algorithm
    output("Start : ")
    PrintArray(numbers)
    BubbleSort(numbers)
    output("Sorted: ")
    PrintArray(numbers)

procedure BubbleSort(input/output a : array of integer)
{ I.S.: a is defined }
{ F.S.: a is sorted in ascending order; the array is displayed after each pass }
Dictionary
    n, pass, j, temp : integer
    swapped : boolean
Algorithm
    n <- length(a)
    for pass <- 1 to n - 1 do
        swapped <- false
        for j <- 0 to n - pass - 1 do
            if a[j] > a[j + 1] then
                temp <- a[j]
                a[j] <- a[j + 1]
                a[j + 1] <- temp
                swapped <- true
            endif
        endfor
        output("Pass ", pass, ": ")
        PrintArray(a)
        if not swapped then
            -> { stop: the array is sorted }
        endif
    endfor
```

The outer loop counts passes. The inner loop compares neighbors `a[j]` and `a[j + 1]`; it stops at `n - pass - 1` because the last `pass` elements are already in their final places, and because `j + 1` must stay inside the array. The `swapped` flag (the flag pattern from Lesson 11) records whether the pass changed anything. In a procedure, `->` with no value simply ends the procedure early.

Create `BubbleSort.java`:

```java
// Program BubbleSort
// Sorts an array with bubble sort, displaying the array after each pass.
public class BubbleSort {
    public static void main(String[] args) {
        // Dictionary
        int[] numbers = {29, 10, 14, 37, 13};

        // Algorithm
        System.out.print("Start : ");
        printArray(numbers);
        bubbleSort(numbers);
        System.out.print("Sorted: ");
        printArray(numbers);
    }

    // Procedure BubbleSort
    // I.S.: a is defined
    // F.S.: a is sorted in ascending order; the array is displayed after each pass
    static void bubbleSort(int[] a) {
        int n = a.length;
        int temp;
        boolean swapped;
        for (int pass = 1; pass <= n - 1; pass++) {
            swapped = false;
            for (int j = 0; j < n - pass; j++) {
                if (a[j] > a[j + 1]) {
                    temp = a[j];
                    a[j] = a[j + 1];
                    a[j + 1] = temp;
                    swapped = true;
                }
            }
            System.out.print("Pass " + pass + ": ");
            printArray(a);
            if (!swapped) {
                return;
            }
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

`j < n - pass` is the Java version of `j <- 0 to n - pass - 1`. In a `void` method, `return;` without a value ends the method immediately. Because the array is passed by reference (Lesson 15), the sorted order is visible in `main` after the call.

```bash
javac BubbleSort.java
java BubbleSort
```

Output:

```text
Start : 29 10 14 37 13 
Pass 1: 10 14 29 13 37 
Pass 2: 10 14 13 29 37 
Pass 3: 10 13 14 29 37 
Pass 4: 10 13 14 29 37 
Sorted: 10 13 14 29 37 
```

Follow pass 1 closely. 29 and 10 are swapped, then 29 and 14, then 29 and 37 are already in order, then 37 and 13 are swapped. The largest value, 37, ended up at the end. Pass 2 carries 29 to its place, and pass 3 fixes 13 and 14. Pass 4 makes no swaps, so the algorithm confirms the array is sorted and stops.

---

## 3. Selection Sort and Insertion Sort

Bubble sort does a lot of swapping: a value that needs to travel far moves one position per swap. The next two algorithms move values more directly.

### Step 1: Selection Sort

Selection sort divides the array into a sorted part on the left (initially empty) and an unsorted part on the right. In each pass, it scans the unsorted part, **selects** the smallest value, and swaps it into the first unsorted position. After pass 1 the smallest value is at index 0, after pass 2 the second smallest is at index 1, and so on.

```text
Program SelectionSort
{ Sorts an array with selection sort, displaying the array after each pass }

Dictionary
    numbers : array [0..4] of integer = {29, 10, 14, 37, 13}
    procedure SelectionSort(input/output a : array of integer)
    procedure PrintArray(input a : array of integer)

Algorithm
    output("Start : ")
    PrintArray(numbers)
    SelectionSort(numbers)
    output("Sorted: ")
    PrintArray(numbers)

procedure SelectionSort(input/output a : array of integer)
{ I.S.: a is defined }
{ F.S.: a is sorted in ascending order; the array is displayed after each pass }
Dictionary
    n, i, j, minIndex, temp : integer
Algorithm
    n <- length(a)
    for i <- 0 to n - 2 do
        minIndex <- i
        for j <- i + 1 to n - 1 do
            if a[j] < a[minIndex] then
                minIndex <- j
            endif
        endfor
        temp <- a[i]
        a[i] <- a[minIndex]
        a[minIndex] <- temp
        output("Pass ", i + 1, ": ")
        PrintArray(a)
    endfor
```

The inner loop is exactly the `IndexOfMax` pattern from Lesson 15, turned around to find the minimum, and limited to the unsorted part starting at `i`. There is only **one swap per pass**, after the minimum has been found. The outer loop stops at `n - 2`, because once all other elements are in place, the last one must be too.

Create `SelectionSort.java`:

```java
// Program SelectionSort
// Sorts an array with selection sort, displaying the array after each pass.
public class SelectionSort {
    public static void main(String[] args) {
        // Dictionary
        int[] numbers = {29, 10, 14, 37, 13};

        // Algorithm
        System.out.print("Start : ");
        printArray(numbers);
        selectionSort(numbers);
        System.out.print("Sorted: ");
        printArray(numbers);
    }

    // Procedure SelectionSort
    // I.S.: a is defined
    // F.S.: a is sorted in ascending order; the array is displayed after each pass
    static void selectionSort(int[] a) {
        int n = a.length;
        int minIndex;
        int temp;
        for (int i = 0; i < n - 1; i++) {
            minIndex = i;
            for (int j = i + 1; j < n; j++) {
                if (a[j] < a[minIndex]) {
                    minIndex = j;
                }
            }
            temp = a[i];
            a[i] = a[minIndex];
            a[minIndex] = temp;
            System.out.print("Pass " + (i + 1) + ": ");
            printArray(a);
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

```bash
javac SelectionSort.java
java SelectionSort
```

Output:

```text
Start : 29 10 14 37 13 
Pass 1: 10 29 14 37 13 
Pass 2: 10 13 14 37 29 
Pass 3: 10 13 14 37 29 
Pass 4: 10 13 14 29 37 
Sorted: 10 13 14 29 37 
```

In pass 1, the smallest value, 10, is swapped with 29 at index 0. In pass 2, the smallest of the rest, 13, is swapped into index 1. In pass 3, 14 is already the smallest remaining value at index 2, so it is "swapped" with itself and nothing changes. Pass 4 puts 29 and 37 in order. The sorted part on the left grows by exactly one element per pass.

### Step 2: Insertion Sort

Insertion sort also keeps a sorted part on the left, but it grows that part differently. It takes the next unsorted value, called the **key**, and slides it left past every larger value until it reaches its correct place. This is how most people sort a hand of playing cards: pick up the next card and insert it where it belongs among the cards already in order.

```text
Program InsertionSort
{ Sorts an array with insertion sort, displaying the array after each pass }

Dictionary
    numbers : array [0..4] of integer = {29, 10, 14, 37, 13}
    procedure InsertionSort(input/output a : array of integer)
    procedure PrintArray(input a : array of integer)

Algorithm
    output("Start : ")
    PrintArray(numbers)
    InsertionSort(numbers)
    output("Sorted: ")
    PrintArray(numbers)

procedure InsertionSort(input/output a : array of integer)
{ I.S.: a is defined }
{ F.S.: a is sorted in ascending order; the array is displayed after each pass }
Dictionary
    i, j, key : integer
Algorithm
    for i <- 1 to length(a) - 1 do
        key <- a[i]
        j <- i - 1
        while j >= 0 and a[j] > key do
            a[j + 1] <- a[j]           { shift the larger value one place right }
            j <- j - 1
        endwhile
        a[j + 1] <- key                { drop the key into the gap }
        output("Pass ", i, ": ")
        PrintArray(a)
    endfor
```

The key is saved in a variable first, because its position will be overwritten as larger values shift right. The `while` loop moves left through the sorted part, shifting each larger value one position to the right to open a gap. When it finds a value that is not larger than the key (or reaches the start of the array), it stops, and the key is placed in the gap at `j + 1`. Instead of swapping repeatedly, insertion sort shifts values and writes the key once.

Create `InsertionSort.java`:

```java
// Program InsertionSort
// Sorts an array with insertion sort, displaying the array after each pass.
public class InsertionSort {
    public static void main(String[] args) {
        // Dictionary
        int[] numbers = {29, 10, 14, 37, 13};

        // Algorithm
        System.out.print("Start : ");
        printArray(numbers);
        insertionSort(numbers);
        System.out.print("Sorted: ");
        printArray(numbers);
    }

    // Procedure InsertionSort
    // I.S.: a is defined
    // F.S.: a is sorted in ascending order; the array is displayed after each pass
    static void insertionSort(int[] a) {
        int key;
        int j;
        for (int i = 1; i < a.length; i++) {
            key = a[i];
            j = i - 1;
            while (j >= 0 && a[j] > key) {
                a[j + 1] = a[j];
                j = j - 1;
            }
            a[j + 1] = key;
            System.out.print("Pass " + i + ": ");
            printArray(a);
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

The order of the two conditions in `j >= 0 && a[j] > key` matters, for the same reason as in sequential search: when `j` becomes -1, the short-circuit `&&` stops before reading `a[-1]` (see Error 3 in Section 6).

```bash
javac InsertionSort.java
java InsertionSort
```

Output:

```text
Start : 29 10 14 37 13 
Pass 1: 10 29 14 37 13 
Pass 2: 10 14 29 37 13 
Pass 3: 10 14 29 37 13 
Pass 4: 10 13 14 29 37 
Sorted: 10 13 14 29 37 
```

In pass 1, the key 10 slides left past 29. In pass 2, the key 14 slides past 29 and stops after 10. In pass 3, the key 37 is already larger than everything before it, so it stays put. In pass 4, the key 13 slides past 37, 29, and 14, and lands right after 10. Notice that the left part is always sorted, but unlike selection sort, its values are not necessarily in their *final* positions yet.

### Step 3: Compare the Three Algorithms

All three algorithms produce the same sorted array, so which one is best? A fair way to compare them is to count how many comparisons each one makes on the same data. **Problem:** Count the comparisons of each algorithm on 1000 elements in three situations: mixed order, already sorted, and in reverse order.

```text
Program CompareSorts
{ Counts the comparisons each sorting algorithm makes on mixed, sorted, and reversed data }

Dictionary
    constant N : integer = 1000
    mixed, sorted, reversed : array [0..N-1] of integer
    i : integer
    procedure PrintRow(input label : string, input data : array of integer)

Algorithm
    for i <- 0 to N - 1 do
        mixed[i] <- (i * 7919) mod N
        sorted[i] <- i
        reversed[i] <- N - 1 - i
    endfor
    output("Data  Bubble  Selection  Insertion")
    PrintRow("mixed", mixed)
    PrintRow("sorted", sorted)
    PrintRow("reversed", reversed)
```

`PrintRow` sorts a fresh copy of the data with each algorithm and displays the three counts. Each counting function is one of the sorting procedures with a counter that goes up every time two elements are compared. The formula `(i * 7919) mod N` mixes the numbers 0 to 999 into a scrambled order that is the same every time you run the program.

Create `CompareSorts.java`:

```java
// Program CompareSorts
// Counts the comparisons each sorting algorithm makes on mixed, sorted, and reversed data.
public class CompareSorts {
    public static void main(String[] args) {
        // Dictionary
        final int N = 1000;
        int[] mixed = new int[N];
        int[] sorted = new int[N];
        int[] reversed = new int[N];

        // Algorithm
        for (int i = 0; i < N; i++) {
            mixed[i] = (i * 7919) % N;
            sorted[i] = i;
            reversed[i] = N - 1 - i;
        }
        System.out.printf("%-10s %10s %10s %10s%n", "Data", "Bubble", "Selection", "Insertion");
        printRow("mixed", mixed);
        printRow("sorted", sorted);
        printRow("reversed", reversed);
    }

    // Procedure PrintRow
    // I.S.: label and data are defined
    // F.S.: the comparison counts of the three sorts on copies of data are displayed
    static void printRow(String label, int[] data) {
        System.out.printf("%-10s %10d %10d %10d%n", label,
                bubbleComparisons(copyOf(data)),
                selectionComparisons(copyOf(data)),
                insertionComparisons(copyOf(data)));
    }

    // Function CopyOf
    // Returns a new array with the same elements as a
    static int[] copyOf(int[] a) {
        int[] copy = new int[a.length];
        for (int i = 0; i < a.length; i++) {
            copy[i] = a[i];
        }
        return copy;
    }

    // Function BubbleComparisons
    // Sorts a with bubble sort (with early exit) and returns the number of comparisons
    static long bubbleComparisons(int[] a) {
        long count = 0;
        int temp;
        boolean swapped;
        for (int pass = 1; pass <= a.length - 1; pass++) {
            swapped = false;
            for (int j = 0; j < a.length - pass; j++) {
                count = count + 1;
                if (a[j] > a[j + 1]) {
                    temp = a[j];
                    a[j] = a[j + 1];
                    a[j + 1] = temp;
                    swapped = true;
                }
            }
            if (!swapped) {
                return count;
            }
        }
        return count;
    }

    // Function SelectionComparisons
    // Sorts a with selection sort and returns the number of comparisons
    static long selectionComparisons(int[] a) {
        long count = 0;
        int minIndex;
        int temp;
        for (int i = 0; i < a.length - 1; i++) {
            minIndex = i;
            for (int j = i + 1; j < a.length; j++) {
                count = count + 1;
                if (a[j] < a[minIndex]) {
                    minIndex = j;
                }
            }
            temp = a[i];
            a[i] = a[minIndex];
            a[minIndex] = temp;
        }
        return count;
    }

    // Function InsertionComparisons
    // Sorts a with insertion sort and returns the number of comparisons
    static long insertionComparisons(int[] a) {
        long count = 0;
        int key;
        int j;
        boolean placed;
        for (int i = 1; i < a.length; i++) {
            key = a[i];
            j = i - 1;
            placed = false;
            while (j >= 0 && !placed) {
                count = count + 1;
                if (a[j] > key) {
                    a[j + 1] = a[j];
                    j = j - 1;
                } else {
                    placed = true;
                }
            }
            a[j + 1] = key;
        }
        return count;
    }
}
```

Each algorithm gets its own copy of the data, made by `copyOf`, because sorting changes the array, and the second algorithm must not receive data that the first one already sorted. The insertion sort counter uses a `placed` flag so that each comparison of `a[j]` with the key can be counted inside the loop.

```bash
javac CompareSorts.java
java CompareSorts
```

Output:

```text
Data           Bubble  Selection  Insertion
mixed          498324     499500     251100
sorted            999     499500        999
reversed       499500     499500     499500
```

What the numbers show:

- **Selection sort** always makes 499500 comparisons, whatever the input. It scans the whole unsorted part every pass, even when the data is already sorted.
- **Bubble sort** with the early exit needs only 999 comparisons on sorted data (one pass with no swaps), but almost the maximum on mixed data.
- **Insertion sort** also needs only 999 comparisons on sorted data, and about half as many as the others on mixed data, because each key usually stops partway through the sorted part.
- On reversed data, the worst case, all three make 499500 comparisons.

499500 is 1000 x 999 / 2. All three algorithms make roughly n x n / 2 comparisons in the worst case, so doubling the size of the data makes them about four times slower. For the arrays in this course, that is perfectly fine. For millions of elements, programmers use faster algorithms such as merge sort and quicksort, which are natural next steps after this course. Among the three you learned, insertion sort is usually the best choice, especially when the data is already nearly sorted.

---

## 4. Run and Test

Sorting records works exactly like sorting numbers, except that the comparison looks at one field and the whole record moves. **Problem:** Read the names and scores of several players, then display a leaderboard ranked from the highest score to the lowest. Players with equal scores should stay in the order they were entered.

Use insertion sort with the comparison reversed (`<` instead of `>`) to sort in descending order. Insertion sort has a helpful property here: it never moves a record past another record with an *equal* score, so ties keep their original order. A sorting algorithm with this property is called **stable**.

```text
Program Leaderboard
{ Reads players and scores, then ranks them from the highest score to the lowest }

Dictionary
    type Player : < name : string, score : integer >
    players : array [0..n-1] of Player
    n, i, score : integer
    name : string
    procedure SortByScoreDescending(input/output list : array of Player)

Algorithm
    output("Number of players: ")
    input(n)
    for i <- 0 to n - 1 do
        output("Name : ")
        input(name)
        output("Score: ")
        input(score)
        players[i] <- < name, score >
    endfor
    SortByScoreDescending(players)
    output("Rank  Name        Score")
    for i <- 0 to n - 1 do
        output(i + 1, "  ", players[i].name, "  ", players[i].score)
    endfor

procedure SortByScoreDescending(input/output list : array of Player)
{ I.S.: list is defined }
{ F.S.: list is sorted from the highest score to the lowest (insertion sort);
        players with equal scores keep their original order }
Dictionary
    i, j : integer
    key : Player
Algorithm
    for i <- 1 to length(list) - 1 do
        key <- list[i]
        j <- i - 1
        while j >= 0 and list[j].score < key.score do
            list[j + 1] <- list[j]
            j <- j - 1
        endwhile
        list[j + 1] <- key
    endfor
```

The key is now a whole `Player` record, and the comparison uses its `score` field. Because the comparison is a strict `<`, a player with the same score as the key does not get shifted, which is what keeps the sort stable.

Create `Leaderboard.java`:

```java
import java.util.Scanner;

// Program Leaderboard
// Reads players and scores, then ranks them from the highest score to the lowest.
public class Leaderboard {
    // Type Player
    record Player(String name, int score) {}

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        Player[] players;
        int n;
        String name;
        int score;

        // Algorithm
        System.out.print("Number of players: ");
        n = input.nextInt();
        input.nextLine();
        players = new Player[n];
        for (int i = 0; i < n; i++) {
            System.out.print("Name : ");
            name = input.nextLine();
            System.out.print("Score: ");
            score = input.nextInt();
            input.nextLine();
            players[i] = new Player(name, score);
        }
        sortByScoreDescending(players);
        System.out.println();
        System.out.println("Rank  Name        Score");
        for (int i = 0; i < n; i++) {
            System.out.printf("%4d  %-10s %6d%n", i + 1, players[i].name(), players[i].score());
        }
    }

    // Procedure SortByScoreDescending
    // I.S.: list is defined
    // F.S.: list is sorted from the highest score to the lowest (insertion sort);
    //       players with equal scores keep their original order
    static void sortByScoreDescending(Player[] list) {
        Player key;
        int j;
        for (int i = 1; i < list.length; i++) {
            key = list[i];
            j = i - 1;
            while (j >= 0 && list[j].score() < key.score()) {
                list[j + 1] = list[j];
                j = j - 1;
            }
            list[j + 1] = key;
        }
    }
}
```

The array holds records, so `key` is a `Player` and each shift moves an entire record. The name and score always travel together, which is the problem with parallel arrays that records solved in Lesson 18.

```bash
javac Leaderboard.java
java Leaderboard
```

Output:

```text
Number of players: 5
Name : Rina
Score: 780
Name : Dodi
Score: 920
Name : Sari
Score: 650
Name : Tono
Score: 920
Name : Wulan
Score: 810

Rank  Name        Score
   1  Dodi          920
   2  Tono          920
   3  Wulan         810
   4  Rina          780
   5  Sari          650
```

The players are ranked from 920 down to 650. Dodi and Tono both scored 920, and Dodi stays first because Dodi was entered first, which confirms the sort is stable.

---

## 5. Fix the Errors in Your Code

**Error 1: The inner loop of bubble sort goes one step too far.**

```java
// Wrong
public class InnerBound {
    public static void main(String[] args) {
        int[] a = {29, 10, 14, 37, 13};
        int temp;
        for (int pass = 1; pass <= a.length - 1; pass++) {
            for (int j = 0; j < a.length; j++) {
                if (a[j] > a[j + 1]) {
                    temp = a[j];
                    a[j] = a[j + 1];
                    a[j + 1] = temp;
                }
            }
        }
        System.out.println(a[0]);
    }
}

// Correct
public class InnerBound {
    public static void main(String[] args) {
        int[] a = {29, 10, 14, 37, 13};
        int temp;
        for (int pass = 1; pass <= a.length - 1; pass++) {
            for (int j = 0; j < a.length - pass; j++) {
                if (a[j] > a[j + 1]) {
                    temp = a[j];
                    a[j] = a[j + 1];
                    a[j + 1] = temp;
                }
            }
        }
        System.out.println(a[0]);
    }
}
```

The wrong version crashes:

```text
Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index 5 out of bounds for length 5
	at InnerBound.main(InnerBound.java:7)
```

When `j` is 4, the last valid index, the comparison reads `a[j + 1]`, which is `a[5]`. Whenever a loop reads a neighbor such as `a[j + 1]`, it must stop one position earlier. The limit `a.length - pass` both avoids the crash and skips the elements already in place.

**Error 2: Swapping without a temporary variable.**

```java
// Wrong
public class SwapNoTemp {
    public static void main(String[] args) {
        int[] a = {29, 10, 14, 37, 13};
        for (int pass = 1; pass <= a.length - 1; pass++) {
            for (int j = 0; j < a.length - pass; j++) {
                if (a[j] > a[j + 1]) {
                    a[j] = a[j + 1];
                    a[j + 1] = a[j];
                }
            }
        }
        for (int i = 0; i < a.length; i++) {
            System.out.print(a[i] + " ");
        }
        System.out.println();
    }
}

// Correct
public class SwapNoTemp {
    public static void main(String[] args) {
        int[] a = {29, 10, 14, 37, 13};
        int temp;
        for (int pass = 1; pass <= a.length - 1; pass++) {
            for (int j = 0; j < a.length - pass; j++) {
                if (a[j] > a[j + 1]) {
                    temp = a[j];
                    a[j] = a[j + 1];
                    a[j + 1] = temp;
                }
            }
        }
        for (int i = 0; i < a.length; i++) {
            System.out.print(a[i] + " ");
        }
        System.out.println();
    }
}
```

The wrong version compiles and displays:

```text
10 10 13 13 13 
```

The values 29, 14, and 37 have disappeared, and others are duplicated. This is the broken swap you traced in Lesson 4: `a[j] = a[j + 1]` overwrites `a[j]` before its value is saved, so the second line copies the same value back. A swap always needs three steps and a temporary variable.

**Error 3: The insertion sort conditions in the wrong order.**

```java
// Wrong
public class InsertOrder {
    public static void main(String[] args) {
        int[] a = {29, 10, 14, 37, 13};
        int key;
        int j;
        for (int i = 1; i < a.length; i++) {
            key = a[i];
            j = i - 1;
            while (a[j] > key && j >= 0) {
                a[j + 1] = a[j];
                j = j - 1;
            }
            a[j + 1] = key;
        }
        System.out.println(a[0]);
    }
}

// Correct
public class InsertOrder {
    public static void main(String[] args) {
        int[] a = {29, 10, 14, 37, 13};
        int key;
        int j;
        for (int i = 1; i < a.length; i++) {
            key = a[i];
            j = i - 1;
            while (j >= 0 && a[j] > key) {
                a[j + 1] = a[j];
                j = j - 1;
            }
            a[j + 1] = key;
        }
        System.out.println(a[0]);
    }
}
```

The wrong version crashes:

```text
Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index -1 out of bounds for length 5
	at InsertOrder.main(InsertOrder.java:9)
```

When the key is smaller than every value before it (10 in the first pass), `j` goes down to -1. The wrong condition reads `a[-1]` *before* checking `j >= 0`. With `j >= 0` first, the short-circuit `&&` stops as soon as `j` is negative and never reads the invalid index. When one condition protects another, the protecting condition must come first.

---

## 6. Exercises

**Exercise 1:** Write the notation and the Java program `SortDescending` that sorts the scores `{72, 95, 61, 88, 79, 95, 54}` from largest to smallest with bubble sort, including the early exit.

**Exercise 2:** Write the notation and the Java program `SortNames` that sorts the names `{"Rudi", "Agus", "Gita", "Dina", "Bayu", "Hana", "Fajar"}` alphabetically with selection sort. Use `compareTo` to compare strings.

**Exercise 3:** The **median** of a list is the middle value after sorting; if the list has an even number of values, it is the average of the two middle values. Write the notation and the Java program `ScoreStatistics` that reads `n` scores, sorts them with insertion sort, and displays the sorted scores, the lowest, the highest, and the median. Test it with an odd and an even number of scores.

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program SortDescending
{ Sorts an array from largest to smallest with bubble sort }

Dictionary
    scores : array [0..6] of integer = {72, 95, 61, 88, 79, 95, 54}
    i : integer
    procedure BubbleSortDescending(input/output a : array of integer)

Algorithm
    BubbleSortDescending(scores)
    for i <- 0 to 6 do
        output(scores[i], " ")
    endfor

procedure BubbleSortDescending(input/output a : array of integer)
{ I.S.: a is defined }
{ F.S.: a is sorted from the largest to the smallest value }
Dictionary
    pass, j, temp : integer
    swapped : boolean
Algorithm
    for pass <- 1 to length(a) - 1 do
        swapped <- false
        for j <- 0 to length(a) - pass - 1 do
            if a[j] < a[j + 1] then
                temp <- a[j]
                a[j] <- a[j + 1]
                a[j + 1] <- temp
                swapped <- true
            endif
        endfor
        if not swapped then
            ->
        endif
    endfor
```

```java
// Program SortDescending
// Sorts an array from largest to smallest with bubble sort.
public class SortDescending {
    public static void main(String[] args) {
        // Dictionary
        int[] scores = {72, 95, 61, 88, 79, 95, 54};

        // Algorithm
        bubbleSortDescending(scores);
        for (int i = 0; i < scores.length; i++) {
            System.out.print(scores[i] + " ");
        }
        System.out.println();
    }

    // Procedure BubbleSortDescending
    // I.S.: a is defined
    // F.S.: a is sorted from the largest to the smallest value
    static void bubbleSortDescending(int[] a) {
        int temp;
        boolean swapped;
        for (int pass = 1; pass <= a.length - 1; pass++) {
            swapped = false;
            for (int j = 0; j < a.length - pass; j++) {
                if (a[j] < a[j + 1]) {
                    temp = a[j];
                    a[j] = a[j + 1];
                    a[j + 1] = temp;
                    swapped = true;
                }
            }
            if (!swapped) {
                return;
            }
        }
    }
}
```

The only change from ascending order is the comparison: `a[j] < a[j + 1]` swaps a pair when the left value is *smaller*, so small values sink to the end and large values rise to the front. Changing one comparison is all it takes to reverse the order of any of the three algorithms.

```bash
javac SortDescending.java
java SortDescending
```

Output:

```text
95 95 88 79 72 61 54 
```

**Solution for Exercise 2:**

```text
Program SortNames
{ Sorts an array of names alphabetically with selection sort }

Dictionary
    names : array [0..6] of string = {"Rudi", "Agus", "Gita", "Dina", "Bayu", "Hana", "Fajar"}
    i : integer
    procedure SelectionSort(input/output a : array of string)

Algorithm
    SelectionSort(names)
    for i <- 0 to 6 do
        output(names[i], " ")
    endfor

procedure SelectionSort(input/output a : array of string)
{ I.S.: a is defined }
{ F.S.: a is sorted in alphabetical order }
Dictionary
    i, j, minIndex : integer
    temp : string
Algorithm
    for i <- 0 to length(a) - 2 do
        minIndex <- i
        for j <- i + 1 to length(a) - 1 do
            if a[j] < a[minIndex] then
                minIndex <- j
            endif
        endfor
        temp <- a[i]
        a[i] <- a[minIndex]
        a[minIndex] <- temp
    endfor
```

```java
// Program SortNames
// Sorts an array of names alphabetically with selection sort.
public class SortNames {
    public static void main(String[] args) {
        // Dictionary
        String[] names = {"Rudi", "Agus", "Gita", "Dina", "Bayu", "Hana", "Fajar"};

        // Algorithm
        selectionSort(names);
        for (int i = 0; i < names.length; i++) {
            System.out.print(names[i] + " ");
        }
        System.out.println();
    }

    // Procedure SelectionSort
    // I.S.: a is defined
    // F.S.: a is sorted in alphabetical order
    static void selectionSort(String[] a) {
        int minIndex;
        String temp;
        for (int i = 0; i < a.length - 1; i++) {
            minIndex = i;
            for (int j = i + 1; j < a.length; j++) {
                if (a[j].compareTo(a[minIndex]) < 0) {
                    minIndex = j;
                }
            }
            temp = a[i];
            a[i] = a[minIndex];
            a[minIndex] = temp;
        }
    }
}
```

The algorithm is unchanged; only the types and the comparison differ. `a[j] < a[minIndex]` in notation becomes `a[j].compareTo(a[minIndex]) < 0` in Java, and the temporary variable is a `String`. The sorted result is the same order as the phone book from Lesson 19, which needed sorted names for binary search.

```bash
javac SortNames.java
java SortNames
```

Output:

```text
Agus Bayu Dina Fajar Gita Hana Rudi 
```

**Solution for Exercise 3:**

```text
Program ScoreStatistics
{ Reads scores, sorts them, and displays the lowest, highest, and median score }

Dictionary
    n, i : integer
    scores : array [0..n-1] of integer
    median : real
    procedure InsertionSort(input/output a : array of integer)

Algorithm
    output("How many scores? ")
    input(n)
    output("Scores: ")
    for i <- 0 to n - 1 do
        input(scores[i])
    endfor
    InsertionSort(scores)
    if n mod 2 = 1 then
        median <- scores[n div 2]
    else
        median <- (scores[n div 2 - 1] + scores[n div 2]) / 2
    endif
    output("Sorted : ")
    for i <- 0 to n - 1 do
        output(scores[i], " ")
    endfor
    output("Lowest : ", scores[0])
    output("Highest: ", scores[n - 1])
    output("Median : ", median)

procedure InsertionSort(input/output a : array of integer)
{ I.S.: a is defined }
{ F.S.: a is sorted in ascending order }
Dictionary
    i, j, key : integer
Algorithm
    for i <- 1 to length(a) - 1 do
        key <- a[i]
        j <- i - 1
        while j >= 0 and a[j] > key do
            a[j + 1] <- a[j]
            j <- j - 1
        endwhile
        a[j + 1] <- key
    endfor
```

```java
import java.util.Scanner;

// Program ScoreStatistics
// Reads scores, sorts them, and displays the lowest, highest, and median score.
public class ScoreStatistics {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int n;
        int[] scores;
        double median;

        // Algorithm
        System.out.print("How many scores? ");
        n = input.nextInt();
        scores = new int[n];
        System.out.print("Scores: ");
        for (int i = 0; i < n; i++) {
            scores[i] = input.nextInt();
        }
        insertionSort(scores);
        if (n % 2 == 1) {
            median = scores[n / 2];
        } else {
            median = (scores[n / 2 - 1] + scores[n / 2]) / 2.0;
        }
        System.out.print("Sorted : ");
        for (int i = 0; i < n; i++) {
            System.out.print(scores[i] + " ");
        }
        System.out.println();
        System.out.println("Lowest : " + scores[0]);
        System.out.println("Highest: " + scores[n - 1]);
        System.out.println("Median : " + median);
    }

    // Procedure InsertionSort
    // I.S.: a is defined
    // F.S.: a is sorted in ascending order
    static void insertionSort(int[] a) {
        int key;
        int j;
        for (int i = 1; i < a.length; i++) {
            key = a[i];
            j = i - 1;
            while (j >= 0 && a[j] > key) {
                a[j + 1] = a[j];
                j = j - 1;
            }
            a[j + 1] = key;
        }
    }
}
```

Once the array is sorted, several statistics become trivial: the lowest value is the first element, the highest is the last, and the median is in the middle. For 7 scores, the middle index is `7 div 2` = 3. For 6 scores, the two middle indexes are 2 and 3, and their average is calculated with `/ 2.0` to keep the decimal part. Sorting first is often the simplest way to solve a problem that sounds complicated.

```bash
javac ScoreStatistics.java
java ScoreStatistics
```

Output:

```text
How many scores? 7
Scores: 72 95 61 88 79 90 54
Sorted : 54 61 72 79 88 90 95 
Lowest : 54
Highest: 95
Median : 79.0
```

Output:

```text
How many scores? 6
Scores: 72 95 61 88 79 90
Sorted : 61 72 79 88 90 95 
Lowest : 61
Highest: 95
Median : 83.5
```

---

## Next Up - Lesson 21

In this lesson you implemented three classic sorting algorithms. Bubble sort swaps neighbors and can stop early when a pass makes no swaps. Selection sort selects the smallest remaining value and makes one swap per pass. Insertion sort shifts larger values to insert each key into place, and it is stable and fast on nearly sorted data. You traced every pass, counted comparisons to see how the algorithms differ, and sorted records and strings. Module 7 is complete.

You now have every building block this course set out to teach: sequence, selection, repetition, subprograms, arrays, strings, records, searching, and sorting. In Lesson 21 you will start the final project. Before writing any code, you will analyze the requirements of a **Student Grades app**, design its data with records and arrays, and write the complete algorithm and its subprograms in notation, just as a professional would plan a program before building it.
