## 1. Before You Begin

Searching is one of the most common tasks a computer performs. Every time you look up a contact on your phone, find a product in an online shop, or check whether a username is already taken, a program is searching through a collection of data. With arrays (Lesson 15) and records (Lesson 18), you now have collections worth searching.

This lesson covers the two classic searching algorithms. **Sequential search** checks the elements one by one from the start; it is simple and works on any array. **Binary search** works only on *sorted* arrays, but it is dramatically faster: it can find a value among a million elements in about twenty steps. You will design both in notation, trace them step by step, implement them in Java, and measure the difference. You already met the idea behind binary search in the guessing game of Lesson 10.

### What You'll Build

A sequential search function, a student lookup by name, a binary search that prints each step, a program that counts the comparisons each algorithm needs on a million numbers, and a phone book that finds contacts with binary search.

### What You'll Learn

- ✅ How sequential search works and how to return "not found"
- ✅ How to search an array of records by one of its fields
- ✅ How binary search halves the search range at every step
- ✅ Why binary search requires a sorted array
- ✅ How to trace binary search with `low`, `high`, and `mid`
- ✅ How to compare algorithms by counting their steps
- ✅ How to binary search strings with `compareTo`

### What You'll Need

- Lessons 15, 17, and 18 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-19
cd ~/java-basics/lesson-19
```

---

## 2. Sequential Search

**Sequential search** (also called linear search) is what you would do with a pile of unsorted papers: look at the first one, then the next, and so on, until you either find what you want or run out of papers. It makes no assumptions about the order of the data.

A search function needs a way to say "not found." Because valid indexes are 0 or greater, the convention is to return **-1** when the target is not in the array.

### Step 1: Search an Array of Numbers

```text
Program SequentialSearch
{ Searches an array from the first element to the last }

Dictionary
    numbers : array [0..7] of integer = {42, 17, 8, 93, 25, 61, 8, 74}
    target, position : integer
    function SequentialSearch(a : array of integer, target : integer) -> integer

Algorithm
    output("Number to find: ")
    input(target)
    position <- SequentialSearch(numbers, target)
    if position = -1 then
        output(target, " is not in the array.")
    else
        output(target, " found at index ", position, ".")
    endif

function SequentialSearch(a : array of integer, target : integer) -> integer
{ Returns the index of the first element of a equal to target, or -1 if there is none }
Dictionary
    i : integer
Algorithm
    i <- 0
    while i < length(a) and a[i] <> target do
        i <- i + 1
    endwhile
    if i < length(a) then
        -> i
    else
        -> -1
    endif
```

The loop moves `i` forward while two things are true: there are elements left, *and* the current element is not the target. It stops for one of two reasons. If it found the target, `i` is that element's index. If it ran past the end, `i` equals the length, which means "not found."

The order of the two conditions matters. When `i` reaches the length, `a[i]` does not exist. Because `and` is evaluated from left to right and stops as soon as the first part is false (the short-circuit evaluation from Lesson 17), `a[i]` is never checked once `i` is out of range.

Create `SequentialSearch.java`:

```java
import java.util.Scanner;

// Program SequentialSearch
// Searches an array from the first element to the last.
public class SequentialSearch {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int[] numbers = {42, 17, 8, 93, 25, 61, 8, 74};
        int target;
        int position;

        // Algorithm
        System.out.print("Number to find: ");
        target = input.nextInt();
        position = sequentialSearch(numbers, target);
        if (position == -1) {
            System.out.println(target + " is not in the array.");
        } else {
            System.out.println(target + " found at index " + position + ".");
        }
    }

    // Function SequentialSearch
    // Returns the index of the first element of a equal to target, or -1 if there is none
    static int sequentialSearch(int[] a, int target) {
        int i = 0;
        while (i < a.length && a[i] != target) {
            i = i + 1;
        }
        if (i < a.length) {
            return i;
        } else {
            return -1;
        }
    }
}
```

```bash
javac SequentialSearch.java
java SequentialSearch
```

Test a value in the middle, a value that appears twice, and a value that is missing:

Output:

```text
Number to find: 93
93 found at index 3.
```

Output:

```text
Number to find: 8
8 found at index 2.
```

Output:

```text
Number to find: 50
50 is not in the array.
```

The value 8 appears at indexes 2 and 6, and the search returns the *first* one, because it stops as soon as it finds a match. Finding 50 required checking all 8 elements.

### Step 2: Search Records by a Field

The same algorithm works on an array of records. You compare one field of each record with the target. **Problem:** Find a student by name (ignoring upper and lower case) and display their score.

```text
Program FindStudent
{ Searches an array of student records by name }

Dictionary
    type Student : < name : string, score : integer >
    students : array [0..3] of Student = { < "Ani", 88 >, < "Budi", 74 >,
                                           < "Citra", 91 >, < "Dewi", 67 > }
    name : string
    position : integer
    function FindByName(list : array of Student, name : string) -> integer

Algorithm
    output("Student name: ")
    input(name)
    position <- FindByName(students, name)
    if position = -1 then
        output("No student named ", name, ".")
    else
        output(students[position].name, " scored ", students[position].score, ".")
    endif

function FindByName(list : array of Student, name : string) -> integer
{ Returns the index of the student whose name equals name (ignoring case), or -1 }
Dictionary
    i : integer
Algorithm
    for i <- 0 to length(list) - 1 do
        if lower(list[i].name) = lower(name) then
            -> i
        endif
    endfor
    -> -1
```

This version uses a `for` loop with an early return, the style from `IsPrime` in Lesson 13. If the loop finishes without returning, the name was not found. Both styles are correct; the `while` version is the traditional one in notation, and the `for` version is often shorter in Java.

Create `FindStudent.java`:

```java
import java.util.Scanner;

// Program FindStudent
// Searches an array of student records by name.
public class FindStudent {
    // Type Student
    record Student(String name, int score) {}

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        Student[] students = {
            new Student("Ani", 88),
            new Student("Budi", 74),
            new Student("Citra", 91),
            new Student("Dewi", 67)
        };
        String name;
        int position;

        // Algorithm
        System.out.print("Student name: ");
        name = input.nextLine();
        position = findByName(students, name);
        if (position == -1) {
            System.out.println("No student named " + name + ".");
        } else {
            System.out.println(students[position].name() + " scored " + students[position].score() + ".");
        }
    }

    // Function FindByName
    // Returns the index of the student whose name equals name (ignoring case), or -1
    static int findByName(Student[] list, String name) {
        for (int i = 0; i < list.length; i++) {
            if (list[i].name().equalsIgnoreCase(name)) {
                return i;
            }
        }
        return -1;
    }
}
```

Strings are compared with `equalsIgnoreCase`, never `==` (Lesson 17). Returning the index rather than the record lets the caller use any field of the record that was found.

```bash
javac FindStudent.java
java FindStudent
```

Output:

```text
Student name: citra
Citra scored 91.
```

Output:

```text
Student name: Eko
No student named Eko.
```

---

## 3. Binary Search

Sequential search is fine for small arrays, but it has to look at every element in the worst case. If the array is **sorted**, you can do much better. Think of looking up a word in a printed dictionary: you open it near the middle, see whether your word comes before or after that page, and throw away the half that cannot contain it. A few repetitions get you to the right page.

**Binary search** does exactly this. It keeps track of the part of the array that could still contain the target, from index `low` to index `high`:

1. Look at the middle element, at index `mid = (low + high) div 2`.
2. If it equals the target, you are done.
3. If it is smaller than the target, the target can only be in the right half, so move `low` to `mid + 1`.
4. If it is larger, the target can only be in the left half, so move `high` to `mid - 1`.
5. Repeat while `low <= high`. If the range becomes empty, the target is not there.

### Step 1: Trace Binary Search

```text
Program BinarySearchTrace
{ Searches a sorted array by repeatedly halving the search range, showing each step }

Dictionary
    sorted : array [0..11] of integer = {3, 8, 12, 17, 25, 31, 42, 56, 61, 74, 88, 93}
    target, position : integer
    function BinarySearch(a : array of integer, target : integer) -> integer

Algorithm
    output("Number to find: ")
    input(target)
    position <- BinarySearch(sorted, target)
    if position = -1 then
        output(target, " is not in the array.")
    else
        output(target, " found at index ", position, ".")
    endif

function BinarySearch(a : array of integer, target : integer) -> integer
{ Returns the index of target in the sorted array a, or -1; displays each step }
Dictionary
    low, high, mid : integer
Algorithm
    low <- 0
    high <- length(a) - 1
    while low <= high do
        mid <- (low + high) div 2
        output("  low=", low, " high=", high, " mid=", mid, " a[mid]=", a[mid])
        if a[mid] = target then
            -> mid
        else if a[mid] < target then
            low <- mid + 1
        else
            high <- mid - 1
        endif
    endwhile
    -> -1
```

The `output` inside the loop is only there for learning: it shows how the range shrinks. A normal binary search does not display anything.

Create `BinarySearchTrace.java`:

```java
import java.util.Scanner;

// Program BinarySearchTrace
// Searches a sorted array by repeatedly halving the search range, showing each step.
public class BinarySearchTrace {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int[] sorted = {3, 8, 12, 17, 25, 31, 42, 56, 61, 74, 88, 93};
        int target;
        int position;

        // Algorithm
        System.out.print("Number to find: ");
        target = input.nextInt();
        position = binarySearch(sorted, target);
        if (position == -1) {
            System.out.println(target + " is not in the array.");
        } else {
            System.out.println(target + " found at index " + position + ".");
        }
    }

    // Function BinarySearch
    // Returns the index of target in the sorted array a, or -1; displays each step
    static int binarySearch(int[] a, int target) {
        int low = 0;
        int high = a.length - 1;
        int mid;
        while (low <= high) {
            mid = (low + high) / 2;
            System.out.println("  low=" + low + " high=" + high + " mid=" + mid + " a[mid]=" + a[mid]);
            if (a[mid] == target) {
                return mid;
            } else if (a[mid] < target) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return -1;
    }
}
```

`(low + high) / 2` is integer division, so `mid` is always a whole index, rounded down when the range has an even number of elements.

```bash
javac BinarySearchTrace.java
java BinarySearchTrace
```

Output:

```text
Number to find: 61
  low=0 high=11 mid=5 a[mid]=31
  low=6 high=11 mid=8 a[mid]=61
61 found at index 8.
```

In the first step, the middle element is 31. Since 31 is less than 61, the whole left half (indexes 0 to 5) is discarded. The second step lands right on 61. Now search for the first element:

Output:

```text
Number to find: 3
  low=0 high=11 mid=5 a[mid]=31
  low=0 high=4 mid=2 a[mid]=12
  low=0 high=1 mid=0 a[mid]=3
3 found at index 0.
```

And for a value that is missing:

Output:

```text
Number to find: 50
  low=0 high=11 mid=5 a[mid]=31
  low=6 high=11 mid=8 a[mid]=61
  low=6 high=7 mid=6 a[mid]=42
  low=7 high=7 mid=7 a[mid]=56
50 is not in the array.
```

After the last step, 56 is greater than 50, so `high` becomes 6. Now `low` (7) is greater than `high` (6), the range is empty, and the loop ends. Even to prove that 50 is missing, binary search needed only 4 steps instead of 12.

### Step 2: Count the Steps

How big is the difference on a large array? **Problem:** Fill an array with one million sorted numbers (0, 3, 6, 9, ...) and count how many elements each algorithm compares before it finds, or gives up on, several targets.

```text
Program CompareSearches
{ Counts how many comparisons sequential and binary search need on a large sorted array }

Dictionary
    constant SIZE : integer = 1000000
    data : array [0..SIZE-1] of integer
    targets : array [0..3] of integer = {3, 1500000, 2999997, 7}
    i, t : integer
    function SequentialSteps(a : array of integer, target : integer) -> integer
    function BinarySteps(a : array of integer, target : integer) -> integer

Algorithm
    for i <- 0 to SIZE - 1 do
        data[i] <- i * 3
    endfor
    output("Target  Sequential  Binary")
    for t <- 0 to 3 do
        output(targets[t], SequentialSteps(data, targets[t]), BinarySteps(data, targets[t]))
    endfor
```

`SequentialSteps` and `BinarySteps` are the two search algorithms with a counter added: each time an element is compared with the target, the counter goes up by one, and the function returns the counter instead of the index. The targets are chosen to cover different cases: near the start (3), in the middle (1500000), the very last element (2999997), and a value that is not a multiple of 3 and therefore missing (7).

Create `CompareSearches.java`:

```java
// Program CompareSearches
// Counts how many comparisons sequential and binary search need on a large sorted array.
public class CompareSearches {
    public static void main(String[] args) {
        // Dictionary
        final int SIZE = 1000000;
        int[] data = new int[SIZE];
        int[] targets = {3, 1500000, 2999997, 7};

        // Algorithm
        for (int i = 0; i < SIZE; i++) {
            data[i] = i * 3;
        }
        System.out.printf("%-10s %12s %12s%n", "Target", "Sequential", "Binary");
        for (int t = 0; t < targets.length; t++) {
            System.out.printf("%-10d %12d %12d%n", targets[t],
                    sequentialSteps(data, targets[t]), binarySteps(data, targets[t]));
        }
    }

    // Function SequentialSteps
    // Returns how many elements sequential search compares before it stops
    static int sequentialSteps(int[] a, int target) {
        int steps = 0;
        for (int i = 0; i < a.length; i++) {
            steps = steps + 1;
            if (a[i] == target) {
                return steps;
            }
        }
        return steps;
    }

    // Function BinarySteps
    // Returns how many elements binary search compares before it stops
    static int binarySteps(int[] a, int target) {
        int low = 0;
        int high = a.length - 1;
        int mid;
        int steps = 0;
        while (low <= high) {
            mid = (low + high) / 2;
            steps = steps + 1;
            if (a[mid] == target) {
                return steps;
            } else if (a[mid] < target) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return steps;
    }
}
```

The `printf` call is split over two lines because it is long; Java allows a statement to continue on the next line until the semicolon.

```bash
javac CompareSearches.java
java CompareSearches
```

Output:

```text
Target       Sequential       Binary
3                     2           20
1500000          500001           19
2999997         1000000           20
7               1000000           20
```

The results tell an important story:

- For a target near the start (3), sequential search wins easily: 2 steps against 20. Binary search always starts in the middle.
- For a target in the middle or at the end, sequential search needs half a million or a million steps, while binary search needs about 20.
- For a missing value, sequential search must check all one million elements to be sure. Binary search needs only 20.

Each step of binary search halves the range, and you can only halve one million about 20 times before reaching one element (2^20 is about one million). If the array grew to one *billion* elements, sequential search would need up to a billion steps, and binary search only about 30. This way of comparing algorithms by how their number of steps grows with the size of the data is the starting point of a field called **algorithm analysis**.

---

## 4. Run and Test

Binary search works on any data that can be put in order, including strings. **Problem:** A phone book stores contacts as records, sorted alphabetically by name. Look up names until the user types "stop."

To compare strings, use `compareTo` from Lesson 17: it returns 0 if the strings are equal, a negative number if the first comes earlier in the order, and a positive number if it comes later.

```text
Program PhoneBook
{ Looks up phone numbers in a contact list sorted by name, using binary search }

Dictionary
    type Contact : < name : string, phone : string >
    contacts : array [0..6] of Contact = { < "Agus", "0812-1111-2222" >,
                                           < "Bayu", "0813-3333-4444" >,
                                           < "Dina", "0815-5555-6666" >,
                                           < "Fajar", "0817-7777-8888" >,
                                           < "Gita", "0819-9999-0000" >,
                                           < "Hana", "0821-1234-5678" >,
                                           < "Rudi", "0822-8765-4321" > }
    name : string
    position : integer
    function FindContact(list : array of Contact, name : string) -> integer

Algorithm
    output("Name (stop to quit): ")
    input(name)
    while name <> "stop" do
        position <- FindContact(contacts, name)
        if position = -1 then
            output("  ", name, " is not in the phone book.")
        else
            output("  ", contacts[position].name, ": ", contacts[position].phone)
        endif
        output("Name (stop to quit): ")
        input(name)
    endwhile

function FindContact(list : array of Contact, name : string) -> integer
{ Returns the index of the contact named name in list (sorted by name), or -1 }
Dictionary
    low, high, mid : integer
Algorithm
    low <- 0
    high <- length(list) - 1
    while low <= high do
        mid <- (low + high) div 2
        if list[mid].name = name then
            -> mid
        else if list[mid].name < name then
            low <- mid + 1
        else
            high <- mid - 1
        endif
    endwhile
    -> -1
```

The structure is identical to the number version; only the comparisons work on the `name` field.

Create `PhoneBook.java`:

```java
import java.util.Scanner;

// Program PhoneBook
// Looks up phone numbers in a contact list sorted by name, using binary search.
public class PhoneBook {
    // Type Contact
    record Contact(String name, String phone) {}

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        Contact[] contacts = {
            new Contact("Agus", "0812-1111-2222"),
            new Contact("Bayu", "0813-3333-4444"),
            new Contact("Dina", "0815-5555-6666"),
            new Contact("Fajar", "0817-7777-8888"),
            new Contact("Gita", "0819-9999-0000"),
            new Contact("Hana", "0821-1234-5678"),
            new Contact("Rudi", "0822-8765-4321")
        };
        String name;
        int position;

        // Algorithm
        System.out.print("Name (stop to quit): ");
        name = input.nextLine();
        while (!name.equals("stop")) {
            position = findContact(contacts, name);
            if (position == -1) {
                System.out.println("  " + name + " is not in the phone book.");
            } else {
                System.out.println("  " + contacts[position].name() + ": " + contacts[position].phone());
            }
            System.out.print("Name (stop to quit): ");
            name = input.nextLine();
        }
    }

    // Function FindContact
    // Returns the index of the contact named name in list (sorted by name), or -1
    static int findContact(Contact[] list, String name) {
        int low = 0;
        int high = list.length - 1;
        int mid;
        int comparison;
        while (low <= high) {
            mid = (low + high) / 2;
            comparison = list[mid].name().compareTo(name);
            if (comparison == 0) {
                return mid;
            } else if (comparison < 0) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return -1;
    }
}
```

The result of `compareTo` is stored in `comparison` so the comparison is done only once per step. A negative value means the middle name comes before the target, so the search continues in the right half.

```bash
javac PhoneBook.java
java PhoneBook
```

Test a name from the middle, the first name, the last name, and a missing name:

Output:

```text
Name (stop to quit): Fajar
  Fajar: 0817-7777-8888
Name (stop to quit): Agus
  Agus: 0812-1111-2222
Name (stop to quit): Rudi
  Rudi: 0822-8765-4321
Name (stop to quit): Citra
  Citra is not in the phone book.
Name (stop to quit): stop
```

The first and last elements are the classic edge cases for binary search, because they are found only when the range shrinks all the way to one end.

---

## 5. Fix the Errors in Your Code

Binary search is famous for being easy to describe and surprisingly easy to get wrong. All three of these bugs compile without any error.

**Error 1: Using binary search on an unsorted array.**

```java
// Wrong
public class Unsorted {
    public static void main(String[] args) {
        int[] numbers = {42, 17, 8, 93, 25, 61, 74};
        System.out.println("Index of 17: " + binarySearch(numbers, 17));
        System.out.println("Index of 42: " + binarySearch(numbers, 42));
    }

    static int binarySearch(int[] a, int target) {
        int low = 0;
        int high = a.length - 1;
        while (low <= high) {
            int mid = (low + high) / 2;
            if (a[mid] == target) {
                return mid;
            } else if (a[mid] < target) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return -1;
    }
}
```

The output is:

```text
Index of 17: 1
Index of 42: -1
```

42 is at index 0, but the search says it is not there. The first middle element is 93, which is larger than 42, so the search throws away the right half; then it finds 17 and 8, both smaller than 42, and moves right until the range is empty. Binary search assumes the array is sorted, and when that assumption is false, the results are unreliable: sometimes right (17), sometimes wrong (42). The fix is to sort the array first (the topic of Lesson 20), or to use sequential search, which works on any order.

**Error 2: Using `<` instead of `<=` in the loop condition.**

```java
// Wrong
public class LessThan {
    public static void main(String[] args) {
        int[] sorted = {3, 8, 12, 17, 25};
        System.out.println("Index of 25: " + binarySearch(sorted, 25));
        System.out.println("Index of 12: " + binarySearch(sorted, 12));
    }

    static int binarySearch(int[] a, int target) {
        int low = 0;
        int high = a.length - 1;
        while (low < high) {
            int mid = (low + high) / 2;
            if (a[mid] == target) {
                return mid;
            } else if (a[mid] < target) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return -1;
    }
}
```

The output is:

```text
Index of 25: -1
Index of 12: 2
```

12 is found because it happens to be the first middle element, but 25 is reported as missing. When the range shrinks to a single element, `low` equals `high`, and the condition `low < high` stops the loop *before* that last element is checked. A range with one element is still a valid range, so the condition must be `low <= high`.

**Error 3: Not moving past the middle element.**

```java
// Wrong
public class MidStuck {
    public static void main(String[] args) {
        int[] sorted = {3, 8, 12, 17, 25};
        System.out.println("Index of 25: " + binarySearch(sorted, 25));
    }

    static int binarySearch(int[] a, int target) {
        int low = 0;
        int high = a.length - 1;
        while (low <= high) {
            int mid = (low + high) / 2;
            System.out.println("low=" + low + " high=" + high + " mid=" + mid);
            if (a[mid] == target) {
                return mid;
            } else if (a[mid] < target) {
                low = mid;
            } else {
                high = mid;
            }
        }
        return -1;
    }
}
```

With a trace line added, the first lines of output show the problem:

```text
low=0 high=4 mid=2
low=2 high=4 mid=3
low=3 high=4 mid=3
low=3 high=4 mid=3
low=3 high=4 mid=3
low=3 high=4 mid=3
```

The program never ends; you must stop it with `Ctrl` + `C`. When `low` is 3 and `high` is 4, `mid` is 3, and `low = mid` sets `low` to 3 again. Nothing changes, so the loop repeats forever. The middle element has already been checked, so the new range must exclude it: `low = mid + 1` and `high = mid - 1`. This guarantees that the range shrinks by at least one element every step, the same "move toward the end" rule every loop needs (Lesson 9).

---

## 6. Exercises

**Exercise 1:** Sequential search stops at the first match, but sometimes you need *every* match. Write the notation and the Java program `CountOccurrences` with a function `CountOf(a : array of integer, target : integer) -> integer` that counts how many times `target` appears, and a procedure `PrintPositions` that displays every index where it appears. Use the dice rolls `{3, 6, 1, 3, 5, 3, 6, 2}`.

**Exercise 2:** Write the notation and the Java program `LastOccurrence` with a function `LastIndexOf(a : array of integer, target : integer) -> integer` that returns the index of the *last* element equal to `target`, or -1. Make it efficient: it should stop as soon as it finds the answer.

**Exercise 3:** Binary search has a natural recursive form (Lesson 14): search the range `low..high`; if it is empty, return -1; otherwise compare the middle element and search the left or right half recursively. Write the notation and the Java program `RecursiveBinarySearch` with a function `Search(a, target, low, high) -> integer`.

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program CountOccurrences
{ Counts how many times a value appears in an array and lists its positions }

Dictionary
    rolls : array [0..7] of integer = {3, 6, 1, 3, 5, 3, 6, 2}
    function CountOf(a : array of integer, target : integer) -> integer
    procedure PrintPositions(input a : array of integer, input target : integer)

Algorithm
    output("Positions of 3: ")
    PrintPositions(rolls, 3)
    output("3 appears ", CountOf(rolls, 3), " times")
    output("4 appears ", CountOf(rolls, 4), " times")

function CountOf(a : array of integer, target : integer) -> integer
{ Returns how many elements of a are equal to target }
Dictionary
    i, count : integer
Algorithm
    count <- 0
    for i <- 0 to length(a) - 1 do
        if a[i] = target then
            count <- count + 1
        endif
    endfor
    -> count

procedure PrintPositions(input a : array of integer, input target : integer)
{ I.S.: a and target are defined }
{ F.S.: every index where a[i] = target is displayed on one line }
Dictionary
    i : integer
Algorithm
    for i <- 0 to length(a) - 1 do
        if a[i] = target then
            output(i, " ")
        endif
    endfor
    output(new line)
```

```java
// Program CountOccurrences
// Counts how many times a value appears in an array and lists its positions.
public class CountOccurrences {
    public static void main(String[] args) {
        // Dictionary
        int[] rolls = {3, 6, 1, 3, 5, 3, 6, 2};

        // Algorithm
        System.out.print("Positions of 3: ");
        printPositions(rolls, 3);
        System.out.println("3 appears " + countOf(rolls, 3) + " times");
        System.out.println("4 appears " + countOf(rolls, 4) + " times");
    }

    // Function CountOf
    // Returns how many elements of a are equal to target
    static int countOf(int[] a, int target) {
        int count = 0;
        for (int i = 0; i < a.length; i++) {
            if (a[i] == target) {
                count = count + 1;
            }
        }
        return count;
    }

    // Procedure PrintPositions
    // I.S.: a and target are defined
    // F.S.: every index where a[i] = target is displayed on one line
    static void printPositions(int[] a, int target) {
        for (int i = 0; i < a.length; i++) {
            if (a[i] == target) {
                System.out.print(i + " ");
            }
        }
        System.out.println();
    }
}
```

To find every match, the search must not stop early, so both subprograms always traverse the whole array. This is the counter pattern from Lesson 11, applied as a search.

```bash
javac CountOccurrences.java
java CountOccurrences
```

Output:

```text
Positions of 3: 0 3 5 
3 appears 3 times
4 appears 0 times
```

**Solution for Exercise 2:**

```text
Program LastOccurrence
{ Finds the last position of a value by searching from the end of the array }

Dictionary
    numbers : array [0..7] of integer = {42, 17, 8, 93, 25, 61, 8, 74}
    function LastIndexOf(a : array of integer, target : integer) -> integer

Algorithm
    output("Last index of 8 : ", LastIndexOf(numbers, 8))
    output("Last index of 42: ", LastIndexOf(numbers, 42))
    output("Last index of 50: ", LastIndexOf(numbers, 50))

function LastIndexOf(a : array of integer, target : integer) -> integer
{ Returns the index of the last element of a equal to target, or -1 if there is none }
Dictionary
    i : integer
Algorithm
    i <- length(a) - 1
    while i >= 0 and a[i] <> target do
        i <- i - 1
    endwhile
    -> i
```

```java
// Program LastOccurrence
// Finds the last position of a value by searching from the end of the array.
public class LastOccurrence {
    public static void main(String[] args) {
        // Dictionary
        int[] numbers = {42, 17, 8, 93, 25, 61, 8, 74};

        // Algorithm
        System.out.println("Last index of 8 : " + lastIndexOf(numbers, 8));
        System.out.println("Last index of 42: " + lastIndexOf(numbers, 42));
        System.out.println("Last index of 50: " + lastIndexOf(numbers, 50));
    }

    // Function LastIndexOf
    // Returns the index of the last element of a equal to target, or -1 if there is none
    static int lastIndexOf(int[] a, int target) {
        int i = a.length - 1;
        while (i >= 0 && a[i] != target) {
            i = i - 1;
        }
        return i;
    }
}
```

Searching backward means the first match found is the last one in the array, so the function can stop immediately. There is a neat bonus: if the target is missing, the loop ends with `i` equal to -1, which is exactly the "not found" value, so no extra `if` is needed.

```bash
javac LastOccurrence.java
java LastOccurrence
```

Output:

```text
Last index of 8 : 6
Last index of 42: 0
Last index of 50: -1
```

**Solution for Exercise 3:**

```text
Program RecursiveBinarySearch
{ Implements binary search as a recursive function }

Dictionary
    sorted : array [0..11] of integer = {3, 8, 12, 17, 25, 31, 42, 56, 61, 74, 88, 93}
    function Search(a : array of integer, target : integer, low : integer, high : integer) -> integer

Algorithm
    output("Index of 74: ", Search(sorted, 74, 0, 11))
    output("Index of 3 : ", Search(sorted, 3, 0, 11))
    output("Index of 50: ", Search(sorted, 50, 0, 11))

function Search(a : array of integer, target : integer, low : integer, high : integer) -> integer
{ Returns the index of target in the sorted part a[low..high], or -1 }
Dictionary
    mid : integer
Algorithm
    if low > high then
        -> -1                                    { base case: empty range }
    endif
    mid <- (low + high) div 2
    if a[mid] = target then
        -> mid                                   { base case: found }
    else if a[mid] < target then
        -> Search(a, target, mid + 1, high)      { search the right half }
    else
        -> Search(a, target, low, mid - 1)       { search the left half }
    endif
```

```java
// Program RecursiveBinarySearch
// Implements binary search as a recursive function.
public class RecursiveBinarySearch {
    public static void main(String[] args) {
        // Dictionary
        int[] sorted = {3, 8, 12, 17, 25, 31, 42, 56, 61, 74, 88, 93};

        // Algorithm
        System.out.println("Index of 74: " + search(sorted, 74, 0, sorted.length - 1));
        System.out.println("Index of 3 : " + search(sorted, 3, 0, sorted.length - 1));
        System.out.println("Index of 50: " + search(sorted, 50, 0, sorted.length - 1));
    }

    // Function Search
    // Returns the index of target in the sorted part a[low..high], or -1
    static int search(int[] a, int target, int low, int high) {
        if (low > high) {
            return -1;
        }
        int mid = (low + high) / 2;
        if (a[mid] == target) {
            return mid;
        } else if (a[mid] < target) {
            return search(a, target, mid + 1, high);
        } else {
            return search(a, target, low, mid - 1);
        }
    }
}
```

This version has two base cases (an empty range, or the target found at `mid`) and a recursive case that searches a range about half the size. The `low` and `high` variables of the loop version have become parameters, so each recursive call describes its own part of the array. The first call covers the whole array, from 0 to `sorted.length - 1`.

```bash
javac RecursiveBinarySearch.java
java RecursiveBinarySearch
```

Output:

```text
Index of 74: 9
Index of 3 : 0
Index of 50: -1
```

---

## Next Up - Lesson 20

In this lesson you implemented the two classic searching algorithms. Sequential search checks elements one by one, works on any array, and returns -1 when the target is missing. Binary search halves the range at every step and needs only about 20 comparisons for a million elements, but it only works on sorted data. You traced both, measured the difference, searched records by a field, and binary searched strings with `compareTo`.

Binary search showed how valuable sorted data is, which raises the obvious question: how do you sort an array in the first place? In Lesson 20 you will implement three classic sorting algorithms, **bubble sort**, **selection sort**, and **insertion sort**, trace each pass in notation, and implement them in Java using the swap technique you learned back in Lesson 4.
