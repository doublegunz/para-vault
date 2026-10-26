## 1. Before You Begin

In Lesson 15 you stored lists of values in one-dimensional arrays: a row of scores, a week of temperatures. But a lot of data is naturally shaped like a **table**, with rows *and* columns. A teacher's grade book has a row for each student and a column for each subject. A cinema has rows of seats. A spreadsheet, a calendar, a chess board, and the pixels of an image are all tables.

A **two-dimensional array** stores exactly this kind of data. Each element is identified by two indexes: its row and its column. In this lesson you will declare two-dimensional arrays in notation and Java, traverse them with nested loops (the technique you practiced drawing star patterns in Lesson 10), calculate row and column totals, write functions that return new tables, and build a small cinema seat booking program.

### What You'll Build

A program that displays a grid of numbers, a grade book that calculates each student's average and each subject's average, matrix addition and transpose functions, and an interactive cinema seat map.

### What You'll Learn

- ✅ What a two-dimensional array is: rows, columns, and two indexes
- ✅ How to declare two-dimensional arrays in notation and Java
- ✅ How to find the number of rows and columns in Java
- ✅ How to traverse a table row by row with nested loops
- ✅ How to calculate totals for each row and for each column
- ✅ How to write functions that receive and return two-dimensional arrays
- ✅ How to avoid mixing up row and column indexes

### What You'll Need

- Lesson 15 completed
- Comfort with nested loops from Lesson 10
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-16
cd ~/java-basics/lesson-16
```

---

## 2. Declaring and Traversing a Table

A two-dimensional array with 3 rows and 4 columns looks like this. Both indexes start at 0:

```text
            col 0  col 1  col 2  col 3
          +------+------+------+------+
  row 0   |   4  |   7  |   1  |   9  |
          +------+------+------+------+
  row 1   |   3  |   8  |   6  |   2  |
          +------+------+------+------+
  row 2   |   5  |   0  |   7  |   4  |
          +------+------+------+------+
```

The element in row 1, column 2 is 6. By convention, the **row index always comes first**.

| | Notation | Java |
| --- | --- | --- |
| Declare a 3 x 4 table | `grid : array [0..2, 0..3] of integer` | `int[][] grid = new int[3][4];` |
| Element at row `r`, column `c` | `grid[r, c]` | `grid[r][c]` |
| Number of rows | `rows(grid)` | `grid.length` |
| Number of columns | `cols(grid)` | `grid[0].length` |

In Java, a two-dimensional array is really an *array of arrays*: `grid` is an array of rows, and each row is an ordinary one-dimensional array. That explains the two Java expressions for size: `grid.length` counts the rows, and `grid[0].length` is the length of the first row, which is the number of columns.

### Step 1: Display a Grid

```text
Program GridBasics
{ Stores a table of numbers in a two-dimensional array and displays it }

Dictionary
    grid : array [0..2, 0..3] of integer = {{4, 7, 1, 9},
                                            {3, 8, 6, 2},
                                            {5, 0, 7, 4}}
    row, col : integer

Algorithm
    output("Rows    : ", rows(grid))
    output("Columns : ", cols(grid))
    output("grid[1][2] = ", grid[1, 2])
    grid[2, 1] <- 10
    for row <- 0 to rows(grid) - 1 do
        for col <- 0 to cols(grid) - 1 do
            output(grid[row, col])
        endfor
        output(new line)
    endfor
```

The nested loops are the key pattern. The outer loop picks a row; for each row, the inner loop visits every column in that row. After a row is finished, `output(new line)` starts the next line, so the output has the same shape as the table. Before displaying, the algorithm changes one element (row 2, column 1) to show that elements can be assigned just like in a one-dimensional array.

Create `GridBasics.java`:

```java
// Program GridBasics
// Stores a table of numbers in a two-dimensional array and displays it.
public class GridBasics {
    public static void main(String[] args) {
        // Dictionary
        int[][] grid = {
            {4, 7, 1, 9},
            {3, 8, 6, 2},
            {5, 0, 7, 4}
        };

        // Algorithm
        System.out.println("Rows    : " + grid.length);
        System.out.println("Columns : " + grid[0].length);
        System.out.println("grid[1][2] = " + grid[1][2]);
        grid[2][1] = 10;
        for (int row = 0; row < grid.length; row++) {
            for (int col = 0; col < grid[row].length; col++) {
                System.out.printf("%4d", grid[row][col]);
            }
            System.out.println();
        }
    }
}
```

`int[][]` means "array of arrays of `int`." The initializer lists each row in its own pair of braces, so the code itself looks like the table. In the inner loop, `grid[row].length` is the length of the current row; for a rectangular table this is the same as `grid[0].length`. `printf("%4d", ...)` gives every number the same width so the columns line up.

```bash
javac GridBasics.java
java GridBasics
```

Output:

```text
Rows    : 3
Columns : 4
grid[1][2] = 6
   4   7   1   9
   3   8   6   2
   5  10   7   4
```

The 0 in row 2, column 1 was replaced by 10.

---

## 3. Working with Rows and Columns

Most table algorithms process either each **row** or each **column**. The difference is simply which loop is on the outside.

| To process | Outer loop | Inner loop |
| --- | --- | --- |
| Each row (for example, a student's total) | rows | columns |
| Each column (for example, a subject's total) | columns | rows |

### Step 1: Totals for Rows and for Columns

**Problem:** A grade book stores the scores of 3 students in 4 subjects. Display the table with each student's average at the end of their row, and each subject's average at the bottom of its column.

```text
Program ScoreTable
{ Calculates each student's average (rows) and each subject's average (columns) }

Dictionary
    students : array [0..2] of string = {"Ani", "Budi", "Citra"}
    subjects : array [0..3] of string = {"Math", "Sci", "Eng", "Art"}
    scores : array [0..2, 0..3] of integer = {{80, 75, 90, 85},
                                              {65, 70, 60, 95},
                                              {92, 88, 79, 81}}
    row, col, total : integer

Algorithm
    { header row }
    for col <- 0 to 3 do
        output(subjects[col])
    endfor
    output("Average")
    { one line per student: scores and the row average }
    for row <- 0 to 2 do
        output(students[row])
        total <- 0
        for col <- 0 to 3 do
            output(scores[row, col])
            total <- total + scores[row, col]
        endfor
        output(total / 4)
    endfor
    { last line: the average of each column }
    output("Average")
    for col <- 0 to 3 do
        total <- 0
        for row <- 0 to 2 do
            total <- total + scores[row, col]
        endfor
        output(total / 3)
    endfor
```

For row averages, `total` is reset to 0 at the start of each row, then the inner loop adds that row's columns. For column averages, the loops are swapped: the outer loop picks a column and the inner loop adds that column's rows. The `students` and `subjects` arrays are parallel arrays (Lesson 15) that give names to the row and column indexes.

Create `ScoreTable.java`:

```java
// Program ScoreTable
// Calculates each student's average (rows) and each subject's average (columns).
public class ScoreTable {
    public static void main(String[] args) {
        // Dictionary
        String[] students = {"Ani", "Budi", "Citra"};
        String[] subjects = {"Math", "Sci", "Eng", "Art"};
        int[][] scores = {
            {80, 75, 90, 85},
            {65, 70, 60, 95},
            {92, 88, 79, 81}
        };
        int total;

        // Algorithm
        System.out.printf("%-8s", "");
        for (int col = 0; col < subjects.length; col++) {
            System.out.printf("%6s", subjects[col]);
        }
        System.out.printf("%8s%n", "Average");
        for (int row = 0; row < students.length; row++) {
            System.out.printf("%-8s", students[row]);
            total = 0;
            for (int col = 0; col < subjects.length; col++) {
                System.out.printf("%6d", scores[row][col]);
                total = total + scores[row][col];
            }
            System.out.printf("%8.2f%n", (double) total / subjects.length);
        }
        System.out.printf("%-8s", "Average");
        for (int col = 0; col < subjects.length; col++) {
            total = 0;
            for (int row = 0; row < students.length; row++) {
                total = total + scores[row][col];
            }
            System.out.printf("%6.1f", (double) total / students.length);
        }
        System.out.println();
    }
}
```

The lengths of `students` and `subjects` are used as the loop limits, so they always match the table's size. `%-8s` reserves 8 characters, left aligned, for the name column. The row average is displayed with `%8.2f` at the end of each row, and the column averages use `%6.1f` so they fit under the subject columns.

```bash
javac ScoreTable.java
java ScoreTable
```

Output:

```text
          Math   Sci   Eng   Art Average
Ani         80    75    90    85   82.50
Budi        65    70    60    95   72.50
Citra       92    88    79    81   85.00
Average   79.0  77.7  76.3  87.0
```

Read the table both ways: Citra has the highest student average, and Art has the highest subject average. One table, two different summaries, depending on the direction of traversal.

### Step 2: Functions That Return a New Table

A function can also *return* a two-dimensional array. **Problem:** Add two matrices of the same size, element by element, and **transpose** a matrix, which means turning its rows into columns.

```text
Program MatrixOperations
{ Adds two matrices and transposes a matrix using functions that return new arrays }

Dictionary
    a : array [0..1, 0..2] of integer = {{1, 2, 3}, {4, 5, 6}}
    b : array [0..1, 0..2] of integer = {{10, 20, 30}, {40, 50, 60}}
    function Add(a : 2D array of integer, b : 2D array of integer) -> 2D array of integer
    function Transpose(m : 2D array of integer) -> 2D array of integer
    procedure PrintMatrix(input m : 2D array of integer)

Algorithm
    output("A + B:")
    PrintMatrix(Add(a, b))
    output("Transpose of A:")
    PrintMatrix(Transpose(a))

function Add(a : 2D array of integer, b : 2D array of integer) -> 2D array of integer
{ Returns a new matrix where each element is a[r, c] + b[r, c]; a and b have the same size }
Dictionary
    result : array [0..rows(a)-1, 0..cols(a)-1] of integer
    r, c : integer
Algorithm
    for r <- 0 to rows(a) - 1 do
        for c <- 0 to cols(a) - 1 do
            result[r, c] <- a[r, c] + b[r, c]
        endfor
    endfor
    -> result

function Transpose(m : 2D array of integer) -> 2D array of integer
{ Returns a new matrix whose rows are the columns of m }
Dictionary
    result : array [0..cols(m)-1, 0..rows(m)-1] of integer
    r, c : integer
Algorithm
    for r <- 0 to rows(m) - 1 do
        for c <- 0 to cols(m) - 1 do
            result[c, r] <- m[r, c]
        endfor
    endfor
    -> result
```

The transposed matrix has its dimensions swapped: a 2 x 3 matrix becomes 3 x 2. The single line `result[c, r] <- m[r, c]` does all the work by swapping the two indexes. The result of each function is passed straight to `PrintMatrix`.

Create `MatrixOperations.java`:

```java
// Program MatrixOperations
// Adds two matrices and transposes a matrix using functions that return new arrays.
public class MatrixOperations {
    public static void main(String[] args) {
        // Dictionary
        int[][] a = {{1, 2, 3}, {4, 5, 6}};
        int[][] b = {{10, 20, 30}, {40, 50, 60}};

        // Algorithm
        System.out.println("A + B:");
        printMatrix(add(a, b));
        System.out.println("Transpose of A:");
        printMatrix(transpose(a));
    }

    // Function Add
    // Returns a new matrix where each element is a[r][c] + b[r][c]; a and b have the same size
    static int[][] add(int[][] a, int[][] b) {
        int[][] result = new int[a.length][a[0].length];
        for (int r = 0; r < a.length; r++) {
            for (int c = 0; c < a[0].length; c++) {
                result[r][c] = a[r][c] + b[r][c];
            }
        }
        return result;
    }

    // Function Transpose
    // Returns a new matrix whose rows are the columns of m
    static int[][] transpose(int[][] m) {
        int[][] result = new int[m[0].length][m.length];
        for (int r = 0; r < m.length; r++) {
            for (int c = 0; c < m[0].length; c++) {
                result[c][r] = m[r][c];
            }
        }
        return result;
    }

    // Procedure PrintMatrix
    // I.S.: m is defined
    // F.S.: m is displayed as a table
    static void printMatrix(int[][] m) {
        for (int r = 0; r < m.length; r++) {
            for (int c = 0; c < m[r].length; c++) {
                System.out.printf("%4d", m[r][c]);
            }
            System.out.println();
        }
    }
}
```

The return type `int[][]` says the function returns a two-dimensional array. Each function creates its result with `new int[rows][columns]`; `transpose` swaps the sizes with `new int[m[0].length][m.length]`.

```bash
javac MatrixOperations.java
java MatrixOperations
```

Output:

```text
A + B:
  11  22  33
  44  55  66
Transpose of A:
   1   4
   2   5
   3   6
```

---

## 4. Run and Test

Two-dimensional arrays are perfect for anything laid out in a grid. **Problem:** A small cinema has 4 rows of 6 seats. Show the seat map, then let the user book seats by row and seat number until they enter row 0. Reject seats that do not exist or are already booked. At the end, show the updated map and how many seats were booked.

A `boolean` table fits naturally: `true` means booked, `false` means free.

```text
Program CinemaSeats
{ Books cinema seats on a grid until the user enters row 0 }

Dictionary
    constant ROWS : integer = 4
    constant COLS : integer = 6
    booked : array [0..ROWS-1, 0..COLS-1] of boolean     { all false at the start }
    row, col, count : integer
    procedure PrintSeats(input booked : 2D array of boolean)

Algorithm
    count <- 0
    PrintSeats(booked)
    output("Row (1-", ROWS, ", 0 to finish): ")
    input(row)
    while row <> 0 do
        output("Seat (1-", COLS, "): ")
        input(col)
        if row < 1 or row > ROWS or col < 1 or col > COLS then
            output("That seat does not exist.")
        else if booked[row - 1, col - 1] then
            output("Sorry, that seat is already booked.")
        else
            booked[row - 1, col - 1] <- true
            count <- count + 1
            output("Booked row ", row, ", seat ", col, ".")
        endif
        output("Row (1-", ROWS, ", 0 to finish): ")
        input(row)
    endwhile
    PrintSeats(booked)
    output(count, " seats booked, ", ROWS * COLS - count, " still free.")

procedure PrintSeats(input booked : 2D array of boolean)
{ I.S.: booked is defined }
{ F.S.: the seat map is displayed, X for booked and . for free }
Dictionary
    r, c : integer
Algorithm
    for c <- 0 to cols(booked) - 1 do
        output(c + 1)
    endfor
    output(new line)
    for r <- 0 to rows(booked) - 1 do
        output("R", r + 1)
        for c <- 0 to cols(booked) - 1 do
            if booked[r, c] then
                output("X")
            else
                output(".")
            endif
        endfor
        output(new line)
    endfor
```

The user thinks in seat numbers starting at 1, while the array starts at 0, so the algorithm subtracts 1 from both numbers when it uses them as indexes. The validity check comes first in the chain, so an invalid seat is never used as an index. This is the sentinel loop from Lesson 9 and the else-if chain from Lesson 8 working together on a table.

Create `CinemaSeats.java`:

```java
import java.util.Scanner;

// Program CinemaSeats
// Books cinema seats on a grid until the user enters row 0.
public class CinemaSeats {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int ROWS = 4;
        final int COLS = 6;
        boolean[][] booked = new boolean[ROWS][COLS];
        int row;
        int col;
        int count;

        // Algorithm
        count = 0;
        printSeats(booked);
        System.out.print("Row (1-" + ROWS + ", 0 to finish): ");
        row = input.nextInt();
        while (row != 0) {
            System.out.print("Seat (1-" + COLS + "): ");
            col = input.nextInt();
            if (row < 1 || row > ROWS || col < 1 || col > COLS) {
                System.out.println("That seat does not exist.");
            } else if (booked[row - 1][col - 1]) {
                System.out.println("Sorry, that seat is already booked.");
            } else {
                booked[row - 1][col - 1] = true;
                count = count + 1;
                System.out.println("Booked row " + row + ", seat " + col + ".");
            }
            System.out.print("Row (1-" + ROWS + ", 0 to finish): ");
            row = input.nextInt();
        }
        printSeats(booked);
        System.out.println(count + " seats booked, " + (ROWS * COLS - count) + " still free.");
    }

    // Procedure PrintSeats
    // I.S.: booked is defined
    // F.S.: the seat map is displayed, X for booked and . for free
    static void printSeats(boolean[][] booked) {
        System.out.print("   ");
        for (int c = 0; c < booked[0].length; c++) {
            System.out.print(" " + (c + 1));
        }
        System.out.println();
        for (int r = 0; r < booked.length; r++) {
            System.out.print("R" + (r + 1) + " ");
            for (int c = 0; c < booked[r].length; c++) {
                if (booked[r][c]) {
                    System.out.print(" X");
                } else {
                    System.out.print(" .");
                }
            }
            System.out.println();
        }
    }
}
```

`new boolean[ROWS][COLS]` creates the table with every element set to `false`, so every seat starts free. `booked[row - 1][col - 1]` is used directly as a condition, because it is already a boolean.

```bash
javac CinemaSeats.java
java CinemaSeats
```

Test a normal booking, a second booking next to it, an attempt to book the same seat again, a seat that does not exist, and one more valid booking:

Output:

```text
    1 2 3 4 5 6
R1  . . . . . .
R2  . . . . . .
R3  . . . . . .
R4  . . . . . .
Row (1-4, 0 to finish): 2
Seat (1-6): 3
Booked row 2, seat 3.
Row (1-4, 0 to finish): 2
Seat (1-6): 4
Booked row 2, seat 4.
Row (1-4, 0 to finish): 2
Seat (1-6): 3
Sorry, that seat is already booked.
Row (1-4, 0 to finish): 5
Seat (1-6): 1
That seat does not exist.
Row (1-4, 0 to finish): 1
Seat (1-6): 6
Booked row 1, seat 6.
Row (1-4, 0 to finish): 0
    1 2 3 4 5 6
R1  . . . . . X
R2  . . X X . .
R3  . . . . . .
R4  . . . . . .
3 seats booked, 21 still free.
```

Every branch of the decision ran at least once, and the final map shows exactly the three seats that were booked.

---

## 5. Fix the Errors in Your Code

**Error 1: Swapping the row and column indexes.**

```java
// Wrong
public class SwappedIndex {
    public static void main(String[] args) {
        int[][] grid = {{4, 7, 1, 9}, {3, 8, 6, 2}, {5, 0, 7, 4}};
        for (int row = 0; row < grid.length; row++) {
            for (int col = 0; col < grid[row].length; col++) {
                System.out.printf("%4d", grid[col][row]);
            }
            System.out.println();
        }
    }
}

// Correct
public class SwappedIndex {
    public static void main(String[] args) {
        int[][] grid = {{4, 7, 1, 9}, {3, 8, 6, 2}, {5, 0, 7, 4}};
        for (int row = 0; row < grid.length; row++) {
            for (int col = 0; col < grid[row].length; col++) {
                System.out.printf("%4d", grid[row][col]);
            }
            System.out.println();
        }
    }
}
```

The wrong version prints three numbers and then crashes:

```text
   4   3   5Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index 3 out of bounds for length 3
	at SwappedIndex.main(SwappedIndex.java:6)
```

`grid[col][row]` uses the column number as a row index. The grid has only 3 rows, so when `col` reaches 3, there is no row 3. With a square table, this mistake does not crash; it silently displays the table transposed, which is even harder to notice. Always write the row first: `grid[row][col]`.

**Error 2: Using the number of rows as the number of columns.**

```java
// Wrong
public class WrongLength {
    public static void main(String[] args) {
        int[][] grid = {{4, 7, 1, 9}, {3, 8, 6, 2}, {5, 0, 7, 4}};
        int total = 0;
        for (int row = 0; row < grid.length; row++) {
            for (int col = 0; col < grid.length; col++) {
                total = total + grid[row][col];
            }
        }
        System.out.println("Total: " + total);
    }
}

// Correct
public class WrongLength {
    public static void main(String[] args) {
        int[][] grid = {{4, 7, 1, 9}, {3, 8, 6, 2}, {5, 0, 7, 4}};
        int total = 0;
        for (int row = 0; row < grid.length; row++) {
            for (int col = 0; col < grid[row].length; col++) {
                total = total + grid[row][col];
            }
        }
        System.out.println("Total: " + total);
    }
}
```

The wrong version displays:

```text
Total: 41
```

The correct total of all twelve numbers is 56. `grid.length` is 3, the number of rows, so the inner loop only visited columns 0 to 2 and skipped the last column (9 + 2 + 4 = 15). The inner loop's limit must be the number of columns, `grid[row].length`.

**Error 3: Using `println` inside the inner loop.**

```java
// Wrong
public class Println {
    public static void main(String[] args) {
        int[][] grid = {{4, 7, 1}, {3, 8, 6}};
        for (int row = 0; row < grid.length; row++) {
            for (int col = 0; col < grid[row].length; col++) {
                System.out.println(grid[row][col] + " ");
            }
        }
    }
}

// Correct
public class Println {
    public static void main(String[] args) {
        int[][] grid = {{4, 7, 1}, {3, 8, 6}};
        for (int row = 0; row < grid.length; row++) {
            for (int col = 0; col < grid[row].length; col++) {
                System.out.print(grid[row][col] + " ");
            }
            System.out.println();
        }
    }
}
```

The wrong version displays every number on its own line, losing the table shape:

```text
4 
7 
1 
3 
8 
6 
```

Inside the inner loop, use `print` so the numbers of one row stay together. Put the `println()` *after* the inner loop, inside the outer loop, so a new line starts once per row.

---

## 6. Exercises

**Exercise 1:** Write the notation and the Java program `TimesTable` that fills a 5 x 5 array so that the element at row `r`, column `c` holds (r + 1) x (c + 1), then displays the table. Use one pair of nested loops to fill the array and another to display it.

**Exercise 2:** A square matrix has two diagonals: the main diagonal from top left to bottom right (where the row and column indexes are equal), and the other diagonal from top right to bottom left. Write the notation and the Java program `DiagonalSum` with two functions that return the sum of each diagonal, and test them on the matrix `{{2, 9, 4}, {7, 5, 3}, {6, 1, 8}}`.

**Exercise 3:** Write the notation and the Java program `MaxInMatrix` that finds the largest value in a table of rainfall readings `{{12, 30, 8, 0}, {45, 22, 51, 17}, {9, 38, 26, 40}}` and displays the value along with its row and column (counting from 1).

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program TimesTable
{ Fills a 5 x 5 array with a multiplication table and displays it }

Dictionary
    constant SIZE : integer = 5
    table : array [0..SIZE-1, 0..SIZE-1] of integer
    r, c : integer

Algorithm
    for r <- 0 to SIZE - 1 do
        for c <- 0 to SIZE - 1 do
            table[r, c] <- (r + 1) * (c + 1)
        endfor
    endfor
    for r <- 0 to SIZE - 1 do
        for c <- 0 to SIZE - 1 do
            output(table[r, c])
        endfor
        output(new line)
    endfor
```

```java
// Program TimesTable
// Fills a 5 x 5 array with a multiplication table and displays it.
public class TimesTable {
    public static void main(String[] args) {
        // Dictionary
        final int SIZE = 5;
        int[][] table = new int[SIZE][SIZE];

        // Algorithm
        for (int r = 0; r < SIZE; r++) {
            for (int c = 0; c < SIZE; c++) {
                table[r][c] = (r + 1) * (c + 1);
            }
        }
        for (int r = 0; r < SIZE; r++) {
            for (int c = 0; c < SIZE; c++) {
                System.out.printf("%4d", table[r][c]);
            }
            System.out.println();
        }
    }
}
```

Each element's value is calculated from its own position. Adding 1 to each index turns the 0-based positions into the numbers 1 to 5 that a multiplication table uses. Filling and displaying are kept as two separate passes, which makes each one simple.

```bash
javac TimesTable.java
java TimesTable
```

Output:

```text
   1   2   3   4   5
   2   4   6   8  10
   3   6   9  12  15
   4   8  12  16  20
   5  10  15  20  25
```

**Solution for Exercise 2:**

```text
Program DiagonalSum
{ Adds the elements on both diagonals of a square matrix }

Dictionary
    m : array [0..2, 0..2] of integer = {{2, 9, 4}, {7, 5, 3}, {6, 1, 8}}
    function MainDiagonal(m : 2D array of integer) -> integer
    function OtherDiagonal(m : 2D array of integer) -> integer

Algorithm
    output("Main diagonal : ", MainDiagonal(m))
    output("Other diagonal: ", OtherDiagonal(m))

function MainDiagonal(m : 2D array of integer) -> integer
{ Returns the sum of m[i, i] for a square matrix m }
Dictionary
    i, sum : integer
Algorithm
    sum <- 0
    for i <- 0 to rows(m) - 1 do
        sum <- sum + m[i, i]
    endfor
    -> sum

function OtherDiagonal(m : 2D array of integer) -> integer
{ Returns the sum of the diagonal from top right to bottom left of a square matrix m }
Dictionary
    i, n, sum : integer
Algorithm
    n <- rows(m)
    sum <- 0
    for i <- 0 to n - 1 do
        sum <- sum + m[i, n - 1 - i]
    endfor
    -> sum
```

```java
// Program DiagonalSum
// Adds the elements on both diagonals of a square matrix.
public class DiagonalSum {
    public static void main(String[] args) {
        // Dictionary
        int[][] m = {
            {2, 9, 4},
            {7, 5, 3},
            {6, 1, 8}
        };

        // Algorithm
        System.out.println("Main diagonal : " + mainDiagonal(m));
        System.out.println("Other diagonal: " + otherDiagonal(m));
    }

    // Function MainDiagonal
    // Returns the sum of m[i][i] for a square matrix m
    static int mainDiagonal(int[][] m) {
        int sum = 0;
        for (int i = 0; i < m.length; i++) {
            sum = sum + m[i][i];
        }
        return sum;
    }

    // Function OtherDiagonal
    // Returns the sum of the diagonal from top right to bottom left of a square matrix m
    static int otherDiagonal(int[][] m) {
        int n = m.length;
        int sum = 0;
        for (int i = 0; i < n; i++) {
            sum = sum + m[i][n - 1 - i];
        }
        return sum;
    }
}
```

A diagonal needs only *one* loop, not two, because there is exactly one diagonal element per row. On the main diagonal, the column equals the row. On the other diagonal, the column goes down as the row goes up: in row `i`, the column is `n - 1 - i`. The test matrix is a "magic square," where every row, column, and diagonal adds up to 15.

```bash
javac DiagonalSum.java
java DiagonalSum
```

Output:

```text
Main diagonal : 15
Other diagonal: 15
```

**Solution for Exercise 3:**

```text
Program MaxInMatrix
{ Finds the largest value in a matrix and its row and column }

Dictionary
    rainfall : array [0..2, 0..3] of integer = {{12, 30, 8, 0},
                                                {45, 22, 51, 17},
                                                {9, 38, 26, 40}}
    r, c, maxRow, maxCol : integer

Algorithm
    maxRow <- 0
    maxCol <- 0
    for r <- 0 to 2 do
        for c <- 0 to 3 do
            if rainfall[r, c] > rainfall[maxRow, maxCol] then
                maxRow <- r
                maxCol <- c
            endif
        endfor
    endfor
    output("Highest rainfall: ", rainfall[maxRow, maxCol])
    output("At row ", maxRow + 1, ", column ", maxCol + 1)
```

```java
// Program MaxInMatrix
// Finds the largest value in a matrix and its row and column.
public class MaxInMatrix {
    public static void main(String[] args) {
        // Dictionary
        int[][] rainfall = {
            {12, 30, 8, 0},
            {45, 22, 51, 17},
            {9, 38, 26, 40}
        };
        int maxRow;
        int maxCol;

        // Algorithm
        maxRow = 0;
        maxCol = 0;
        for (int r = 0; r < rainfall.length; r++) {
            for (int c = 0; c < rainfall[r].length; c++) {
                if (rainfall[r][c] > rainfall[maxRow][maxCol]) {
                    maxRow = r;
                    maxCol = c;
                }
            }
        }
        System.out.println("Highest rainfall: " + rainfall[maxRow][maxCol]);
        System.out.println("At row " + (maxRow + 1) + ", column " + (maxCol + 1));
    }
}
```

This is `IndexOfMax` from Lesson 15 extended to two dimensions: instead of one index, the record is a pair of indexes, both updated together. The first element, at row 0 and column 0, is the starting record.

```bash
javac MaxInMatrix.java
java MaxInMatrix
```

Output:

```text
Highest rainfall: 51
At row 2, column 3
```

---

## Next Up - Lesson 17

In this lesson you learned to store tables in two-dimensional arrays, with the row index first and the column index second. You traversed tables with nested loops, swapped the loops to switch between row totals and column totals, wrote functions that return new tables, and built a seat booking program on a grid of booleans.

There is one kind of data you have been using since Lesson 2 without looking inside it: text. A `String` is really a sequence of characters, a lot like an array. In Lesson 17 you will treat text as a sequence of characters, design algorithms to count, reverse, and compare strings, and implement them with Java's `String` methods such as `length`, `charAt`, `equals`, and `substring`.
