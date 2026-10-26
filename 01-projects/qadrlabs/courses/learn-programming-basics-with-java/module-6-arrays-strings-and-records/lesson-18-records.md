## 1. Before You Begin

Think about how you stored student data in Lesson 15: names in one array, scores in another, connected only by sharing the same index. These **parallel arrays** work, but they are fragile. If you sort the scores, you must remember to move the names in exactly the same way, or every name ends up next to the wrong score. And a function that needs "a student" has to receive two separate values and trust that they belong together.

A **record** solves this by grouping related values into a single unit. A student record holds a name *and* a score; a book record holds a title, an author, a page count, and a price. The record is one value that can be stored in a variable, passed to a function, returned from a function, and placed in an array. In this lesson you will define record types in notation and implement them with Java's `record` keyword. Records are the last building block you need before the searching and sorting lessons and the final project.

### What You'll Build

A book record, a point record used with functions for the midpoint and distance, a product record whose price is updated, and a class list that stores students in an array of records and reports the average and the top student.

### What You'll Learn

- ✅ What a record is and why it is better than parallel arrays
- ✅ How to define a record type in notation with `type Name : < ... >`
- ✅ How to define a record in Java with `record`
- ✅ How to create a record and read its fields
- ✅ How to pass records to functions and return them
- ✅ Why Java records cannot be changed, and how to "update" one
- ✅ How to store many records in an array

### What You'll Need

- Lessons 13 and 15 completed
- JDK 21 and your `~/java-basics` folder (the `record` keyword needs Java 16 or newer)

```bash
mkdir -p ~/java-basics/lesson-18
cd ~/java-basics/lesson-18
```

---

## 2. Defining and Using a Record

A record type describes the **fields** that every value of that type contains. Each field has a name and a type, just like a variable. In notation, a new type is declared in the Dictionary with the `type` keyword, and its fields are listed between angle brackets:

```text
type Book : < title  : string,
              author : string,
              pages  : integer,
              price  : real >
```

Once the type exists, you can declare variables of that type and reach each field with a dot:

| Operation | Notation | Java |
| --- | --- | --- |
| Define the type | `type Book : < title : string, pages : integer >` | `record Book(String title, int pages) {}` |
| Declare a variable | `book1 : Book` | `Book book1;` |
| Create a value | `book1 <- < "Algorithms", 320 >` | `book1 = new Book("Algorithms", 320);` |
| Read a field | `book1.title` | `book1.title()` |

In Java, a **record** declares a new type in one line: the name, followed by its fields in parentheses. Java automatically creates a way to build the record (`new Book(...)`) and a method to read each field, named after the field (`title()`, `pages()`). Notice the parentheses when reading a field: in Java, a record's field is read by calling a method.

### Step 1: Group the Data of a Book

```text
Program BookRecord
{ Groups the data of a book into one record }

Dictionary
    type Book : < title : string, author : string, pages : integer, price : real >
    book1, book2 : Book

Algorithm
    book1 <- < "Learning Algorithms", "Siti Rahma", 320, 89500.0 >
    book2 <- < "Java for Beginners", "Andi Saputra", 250, 75000.0 >
    output("Title : ", book1.title)
    output("Author: ", book1.author)
    output("Pages : ", book1.pages)
    output("Total pages of both books: ", book1.pages + book2.pages)
    output(book2)
```

Each book is now *one* variable. When the record is created, the values are given in the same order as the fields in the type definition: title, author, pages, price. A field such as `book1.pages` can be used in any expression, just like a normal integer.

Create `BookRecord.java`:

```java
// Program BookRecord
// Groups the data of a book into one record.
public class BookRecord {
    // Type Book
    record Book(String title, String author, int pages, double price) {}

    public static void main(String[] args) {
        // Dictionary
        Book book1;
        Book book2;

        // Algorithm
        book1 = new Book("Learning Algorithms", "Siti Rahma", 320, 89500.0);
        book2 = new Book("Java for Beginners", "Andi Saputra", 250, 75000.0);
        System.out.println("Title : " + book1.title());
        System.out.println("Author: " + book1.author());
        System.out.println("Pages : " + book1.pages());
        System.out.println("Total pages of both books: " + (book1.pages() + book2.pages()));
        System.out.println(book2);
    }
}
```

Line by line:

- `record Book(String title, String author, int pages, double price) {}` defines the type. It is placed inside the program's class, before `main`, which plays the role of the type declaration at the top of the notation's Dictionary. The empty braces `{}` at the end are required.
- `Book book1;` declares a variable whose type is `Book`, exactly like `int` or `String`.
- `new Book("Learning Algorithms", "Siti Rahma", 320, 89500.0)` creates a new record. The values must be given in the order of the fields.
- `book1.title()` reads the `title` field.
- `System.out.println(book2)` displays the whole record. Unlike arrays, records know how to display themselves, showing every field by name.

```bash
javac BookRecord.java
java BookRecord
```

Output:

```text
Title : Learning Algorithms
Author: Siti Rahma
Pages : 320
Total pages of both books: 570
Book[title=Java for Beginners, author=Andi Saputra, pages=250, price=75000.0]
```

When you compile, you may notice an extra file named `BookRecord$Book.class` in the folder. Java compiles the record into its own class file; you do not need to do anything with it.

---

## 3. Records and Subprograms

Records really pay off when you pass them to functions and procedures. Instead of sending several separate values that "belong together," you send one value that *is* together.

### Step 1: Pass and Return Records

**Problem:** Represent points on a plane as records with `x` and `y` coordinates. Write functions that return the midpoint between two points (a new point) and the distance between them (a number).

The distance between two points comes from the Pythagorean theorem: the square root of (dx x dx + dy x dy), where dx and dy are the differences in the coordinates. In notation, `sqrt(x)` is the square root; in Java, it is `Math.sqrt(x)`.

```text
Program PointFunctions
{ Uses records as function parameters and return values }

Dictionary
    type Point : < x : real, y : real >
    a, b, middle : Point
    function Midpoint(p : Point, q : Point) -> Point
    function Distance(p : Point, q : Point) -> real
    function Format(p : Point) -> string

Algorithm
    a <- < 1.0, 2.0 >
    b <- < 7.0, 10.0 >
    middle <- Midpoint(a, b)
    output("A        : ", Format(a))
    output("B        : ", Format(b))
    output("Midpoint : ", Format(middle))
    output("Distance : ", Distance(a, b))

function Midpoint(p : Point, q : Point) -> Point
{ Returns the point halfway between p and q }
Algorithm
    -> < (p.x + q.x) / 2, (p.y + q.y) / 2 >

function Distance(p : Point, q : Point) -> real
{ Returns the straight-line distance between p and q }
Dictionary
    dx, dy : real
Algorithm
    dx <- q.x - p.x
    dy <- q.y - p.y
    -> sqrt(dx * dx + dy * dy)

function Format(p : Point) -> string
{ Returns p as text in the form (x, y) }
Algorithm
    -> "(" + p.x + ", " + p.y + ")"
```

`Midpoint` returns a *whole point*, which would be impossible with a function that returns a single number. Each function's header clearly says it works with points, which makes the code easier to read than passing four separate coordinates.

Create `PointFunctions.java`:

```java
// Program PointFunctions
// Uses records as function parameters and return values.
public class PointFunctions {
    // Type Point
    record Point(double x, double y) {}

    public static void main(String[] args) {
        // Dictionary
        Point a = new Point(1.0, 2.0);
        Point b = new Point(7.0, 10.0);
        Point middle;

        // Algorithm
        middle = midpoint(a, b);
        System.out.println("A        : " + format(a));
        System.out.println("B        : " + format(b));
        System.out.println("Midpoint : " + format(middle));
        System.out.println("Distance : " + distance(a, b));
    }

    // Function Midpoint
    // Returns the point halfway between p and q
    static Point midpoint(Point p, Point q) {
        return new Point((p.x() + q.x()) / 2, (p.y() + q.y()) / 2);
    }

    // Function Distance
    // Returns the straight-line distance between p and q
    static double distance(Point p, Point q) {
        double dx = q.x() - p.x();
        double dy = q.y() - p.y();
        return Math.sqrt(dx * dx + dy * dy);
    }

    // Function Format
    // Returns p as text in the form (x, y)
    static String format(Point p) {
        return "(" + p.x() + ", " + p.y() + ")";
    }
}
```

The return type of `midpoint` is `Point`, and it returns a brand new record built with `new Point(...)`. `Math.sqrt` comes from Java's `Math` class, which also offers `Math.abs`, `Math.max`, `Math.pow`, and other common functions.

```bash
javac PointFunctions.java
java PointFunctions
```

Output:

```text
A        : (1.0, 2.0)
B        : (7.0, 10.0)
Midpoint : (4.0, 6.0)
Distance : 10.0
```

The two points are 6 apart horizontally and 8 apart vertically, and the square root of 36 + 64 is 10.

### Step 2: Update a Record

In notation, you can change a single field of a record with an assignment such as `item.price <- 4000`. Java records work differently: they are **immutable**, like strings in Lesson 17. Once a record is created, its fields can never change. To "update" a record, you create a *new* record with the new value and the old values of the other fields, then store it in the variable.

**Problem:** A product's price is reduced by a percentage. Write a function that returns the discounted product.

```text
Program PriceUpdate
{ "Changes" a field of a record by creating a new record with the new value }

Dictionary
    type Product : < name : string, price : integer, stock : integer >
    item : Product
    function WithDiscount(p : Product, percent : integer) -> Product

Algorithm
    item <- < "Notebook", 5000, 40 >
    output("Before: ", item)
    item <- WithDiscount(item, 20)
    output("After : ", item)

function WithDiscount(p : Product, percent : integer) -> Product
{ Returns a copy of p whose price is reduced by percent }
Dictionary
    newPrice : integer
Algorithm
    newPrice <- p.price - p.price * percent div 100
    -> < p.name, newPrice, p.stock >
```

The function builds a new product from the old name, the new price, and the old stock. The main algorithm replaces `item` with the result. Writing the update as a function in notation keeps the design identical to the Java version.

Create `PriceUpdate.java`:

```java
// Program PriceUpdate
// "Changes" a field of a record by creating a new record with the new value.
public class PriceUpdate {
    // Type Product
    record Product(String name, int price, int stock) {}

    public static void main(String[] args) {
        // Dictionary
        Product item = new Product("Notebook", 5000, 40);

        // Algorithm
        System.out.println("Before: " + item);
        item = withDiscount(item, 20);
        System.out.println("After : " + item);
    }

    // Function WithDiscount
    // Returns a copy of p whose price is reduced by percent
    static Product withDiscount(Product p, int percent) {
        int newPrice = p.price() - p.price() * percent / 100;
        return new Product(p.name(), newPrice, p.stock());
    }
}
```

`item = withDiscount(item, 20);` follows the same pattern as `city = city.toUpperCase();` in Lesson 17: call something that returns a new value, then store it back.

```bash
javac PriceUpdate.java
java PriceUpdate
```

Output:

```text
Before: Product[name=Notebook, price=5000, stock=40]
After : Product[name=Notebook, price=4000, stock=40]
```

Immutability may feel restrictive at first, but it prevents a whole class of bugs: no part of a program can accidentally change a record that another part is still using.

---

## 4. Run and Test

The most common use of records is an **array of records**: a list where each element is a complete record. This replaces parallel arrays with a single array. **Problem:** Read the number of students, then each student's full name and score. Display a numbered table, the average score, and the name of the top student.

```text
Program ClassList
{ Reads a list of students into an array of records, then displays a report }

Dictionary
    type Student : < name : string, score : integer >
    students : array [0..n-1] of Student
    n, i, score, best, total : integer
    name : string
    procedure PrintRow(input number : integer, input s : Student)

Algorithm
    output("Number of students: ")
    input(n)
    for i <- 0 to n - 1 do
        output("Name of student ", i + 1, " : ")
        input(name)
        output("Score of student ", i + 1, ": ")
        input(score)
        students[i] <- < name, score >
    endfor
    output("No  Name            Score")
    total <- 0
    best <- 0
    for i <- 0 to n - 1 do
        PrintRow(i + 1, students[i])
        total <- total + students[i].score
        if students[i].score > students[best].score then
            best <- i
        endif
    endfor
    output("Average score: ", total / n)
    output("Top student  : ", students[best].name)

procedure PrintRow(input number : integer, input s : Student)
{ I.S.: number and s are defined }
{ F.S.: one table row with the student's number, name, and score is displayed }
Algorithm
    output(number, "  ", s.name, "  ", s.score)
```

`students[i]` is a whole record, and `students[i].score` is one field of that record: first choose the element with the index, then the field with the dot. `best` stores the index of the top student, so both the name and the score stay together automatically. There is no risk of mixing up names and scores, because they live in the same record.

Create `ClassList.java`:

```java
import java.util.Scanner;

// Program ClassList
// Reads a list of students into an array of records, then displays a report.
public class ClassList {
    // Type Student
    record Student(String name, int score) {}

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        Student[] students;
        int n;
        String name;
        int score;
        int best;
        int total;

        // Algorithm
        System.out.print("Number of students: ");
        n = input.nextInt();
        input.nextLine();
        students = new Student[n];
        for (int i = 0; i < n; i++) {
            System.out.print("Name of student " + (i + 1) + " : ");
            name = input.nextLine();
            System.out.print("Score of student " + (i + 1) + ": ");
            score = input.nextInt();
            input.nextLine();
            students[i] = new Student(name, score);
        }
        System.out.println();
        System.out.printf("%-3s %-15s %5s%n", "No", "Name", "Score");
        total = 0;
        best = 0;
        for (int i = 0; i < n; i++) {
            printRow(i + 1, students[i]);
            total = total + students[i].score();
            if (students[i].score() > students[best].score()) {
                best = i;
            }
        }
        System.out.printf("Average score: %.2f%n", (double) total / n);
        System.out.println("Top student  : " + students[best].name());
    }

    // Procedure PrintRow
    // I.S.: number and s are defined
    // F.S.: one table row with the student's number, name, and score is displayed
    static void printRow(int number, Student s) {
        System.out.printf("%-3d %-15s %5d%n", number, s.name(), s.score());
    }
}
```

`Student[]` is an array of `Student` records, created with `new Student[n]` once the size is known. The names are read with `nextLine` so they can contain spaces, which means each `nextInt` is followed by an extra `input.nextLine()` to throw away the leftover end of line (the fix from Lesson 6). Each record is created from the two values just read and stored in the array.

```bash
javac ClassList.java
java ClassList
```

Output:

```text
Number of students: 3
Name of student 1 : Ani Lestari
Score of student 1: 88
Name of student 2 : Budi Santoso
Score of student 2: 74
Name of student 3 : Citra Dewi
Score of student 3: 91

No  Name            Score
1   Ani Lestari        88
2   Budi Santoso       74
3   Citra Dewi         91
Average score: 84.33
Top student  : Citra Dewi
```

The names with spaces were read correctly, and the top student's name came from the same record as the highest score. This program is a small preview of the Student Grades app you will build in the final project.

---

## 5. Fix the Errors in Your Code

**Error 1: Trying to assign to a record's field.**

```java
// Wrong
public class AssignField {
    record Student(String name, int score) {}

    public static void main(String[] args) {
        Student s = new Student("Ani", 88);
        s.score = 95;
        System.out.println(s);
    }
}

// Correct
public class AssignField {
    record Student(String name, int score) {}

    public static void main(String[] args) {
        Student s = new Student("Ani", 88);
        s = new Student(s.name(), 95);
        System.out.println(s);
    }
}
```

The wrong version produces:

```text
AssignField.java:6: error: cannot assign a value to final variable score
        s.score = 95;
         ^
1 error
```

Every field of a Java record is `final`, the same keyword you used for constants in Lesson 4. To change a value, create a new record with the updated field and assign it to the variable, as `withDiscount` does.

**Error 2: Giving the values in the wrong order.**

```java
// Wrong
public class WrongOrder {
    record Student(String name, int score) {}

    public static void main(String[] args) {
        Student s = new Student(88, "Ani");
        System.out.println(s);
    }
}

// Correct
public class WrongOrder {
    record Student(String name, int score) {}

    public static void main(String[] args) {
        Student s = new Student("Ani", 88);
        System.out.println(s);
    }
}
```

The wrong version produces:

```text
WrongOrder.java:5: error: incompatible types: int cannot be converted to String
        Student s = new Student(88, "Ani");
                                ^
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
1 error
```

The values are matched to the fields by position, just like arguments to a function in Lesson 12. Here the types happen to be different, so the compiler catches the mistake. If two fields had the same type, such as a `price` and a `stock` that are both `int`, swapping them would compile without complaint and silently store wrong data, so always check the order against the record definition.

**Error 3: Using an empty slot of an array of records.**

```java
// Wrong
public class EmptySlot {
    record Student(String name, int score) {}

    public static void main(String[] args) {
        Student[] students = new Student[3];
        students[0] = new Student("Ani", 88);
        students[1] = new Student("Budi", 74);
        for (int i = 0; i < students.length; i++) {
            System.out.println(students[i].name());
        }
    }
}

// Correct
public class EmptySlot {
    record Student(String name, int score) {}

    public static void main(String[] args) {
        Student[] students = new Student[3];
        students[0] = new Student("Ani", 88);
        students[1] = new Student("Budi", 74);
        students[2] = new Student("Citra", 91);
        for (int i = 0; i < students.length; i++) {
            System.out.println(students[i].name());
        }
    }
}
```

The wrong version displays two names and then crashes:

```text
Ani
Budi
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "EmptySlot$Student.name()" because "<local1>[<local2>]" is null
	at EmptySlot.main(EmptySlot.java:9)
```

`new Student[3]` creates an array with room for three records, but it does not create any records. Each empty slot holds the special value `null`, meaning "no record here." Calling `name()` on `null` causes a `NullPointerException`. Make sure every element you read has been filled, or keep a separate count of how many elements are actually used, which is exactly what you will do in the final project.

---

## 6. Exercises

**Exercise 1:** Write the notation and the Java program `RectangleRecord` with a record type `Rectangle` (length and width as real numbers) and two functions, `Area(r : Rectangle) -> real` and `Perimeter(r : Rectangle) -> real`. Create a garden of 12 by 8.5 and a room of 4 by 3, display their area and perimeter, and say which one is larger.

**Exercise 2:** Write the notation and the Java program `StockReport` with a record type `Product` (name, price, stock) and an array of four products: Notebook (5000, 40), Pen (2500, 8), Eraser (1500, 25), and Ruler (4000, 5). Display the total value of all stock (price x stock, added up) and list the products with fewer than 10 items left.

**Exercise 3:** Write the notation and the Java program `TimeRecord` with a record type `Time` (hour and minute) and a function `AddMinutes(t : Time, minutes : integer) -> Time` that returns the time `minutes` later on a 24-hour clock. Starting from 09:45, display the times after 30, 150, and 900 minutes.

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program RectangleRecord
{ Stores rectangles as records and calculates their area and perimeter with functions }

Dictionary
    type Rectangle : < length : real, width : real >
    garden, room : Rectangle
    function Area(r : Rectangle) -> real
    function Perimeter(r : Rectangle) -> real

Algorithm
    garden <- < 12.0, 8.5 >
    room <- < 4.0, 3.0 >
    output("Garden: area ", Area(garden), ", perimeter ", Perimeter(garden))
    output("Room  : area ", Area(room), ", perimeter ", Perimeter(room))
    if Area(garden) > Area(room) then
        output("The garden is larger.")
    else
        output("The room is larger.")
    endif

function Area(r : Rectangle) -> real
{ Returns the area of rectangle r }
Algorithm
    -> r.length * r.width

function Perimeter(r : Rectangle) -> real
{ Returns the perimeter of rectangle r }
Algorithm
    -> 2 * (r.length + r.width)
```

```java
// Program RectangleRecord
// Stores rectangles as records and calculates their area and perimeter with functions.
public class RectangleRecord {
    // Type Rectangle
    record Rectangle(double length, double width) {}

    public static void main(String[] args) {
        // Dictionary
        Rectangle garden = new Rectangle(12.0, 8.5);
        Rectangle room = new Rectangle(4.0, 3.0);

        // Algorithm
        System.out.printf("Garden: area %.2f, perimeter %.2f%n", area(garden), perimeter(garden));
        System.out.printf("Room  : area %.2f, perimeter %.2f%n", area(room), perimeter(room));
        if (area(garden) > area(room)) {
            System.out.println("The garden is larger.");
        } else {
            System.out.println("The room is larger.");
        }
    }

    // Function Area
    // Returns the area of rectangle r
    static double area(Rectangle r) {
        return r.length() * r.width();
    }

    // Function Perimeter
    // Returns the perimeter of rectangle r
    static double perimeter(Rectangle r) {
        return 2 * (r.length() + r.width());
    }
}
```

Compare these functions with `rectangleArea(length, width)` from Lesson 13: each now takes one `Rectangle` instead of two separate numbers, so it is impossible to accidentally pass the length of one rectangle with the width of another.

```bash
javac RectangleRecord.java
java RectangleRecord
```

Output:

```text
Garden: area 102.00, perimeter 41.00
Room  : area 12.00, perimeter 14.00
The garden is larger.
```

**Solution for Exercise 2:**

```text
Program StockReport
{ Reports the total stock value and the products that need restocking }

Dictionary
    type Product : < name : string, price : integer, stock : integer >
    constant MIN_STOCK : integer = 10
    products : array [0..3] of Product = { < "Notebook", 5000, 40 >,
                                           < "Pen", 2500, 8 >,
                                           < "Eraser", 1500, 25 >,
                                           < "Ruler", 4000, 5 > }
    i, totalValue : integer

Algorithm
    totalValue <- 0
    for i <- 0 to 3 do
        totalValue <- totalValue + products[i].price * products[i].stock
    endfor
    output("Total stock value: ", totalValue)
    output("Restock needed:")
    for i <- 0 to 3 do
        if products[i].stock < MIN_STOCK then
            output("  ", products[i].name, " (only ", products[i].stock, " left)")
        endif
    endfor
```

```java
// Program StockReport
// Reports the total stock value and the products that need restocking.
public class StockReport {
    // Type Product
    record Product(String name, int price, int stock) {}

    public static void main(String[] args) {
        // Dictionary
        final int MIN_STOCK = 10;
        Product[] products = {
            new Product("Notebook", 5000, 40),
            new Product("Pen", 2500, 8),
            new Product("Eraser", 1500, 25),
            new Product("Ruler", 4000, 5)
        };
        long totalValue;

        // Algorithm
        totalValue = 0;
        for (int i = 0; i < products.length; i++) {
            totalValue = totalValue + (long) products[i].price() * products[i].stock();
        }
        System.out.println("Total stock value: " + totalValue);
        System.out.println("Restock needed:");
        for (int i = 0; i < products.length; i++) {
            if (products[i].stock() < MIN_STOCK) {
                System.out.println("  " + products[i].name() + " (only " + products[i].stock() + " left)");
            }
        }
    }
}
```

An array of records can be filled directly with an initializer, one `new Product(...)` per element. The first loop is an accumulator, the second a filter. `totalValue` is a `long` and the multiplication is cast to `long`, a good habit when money values might grow large.

```bash
javac StockReport.java
java StockReport
```

Output:

```text
Total stock value: 277500
Restock needed:
  Pen (only 8 left)
  Ruler (only 5 left)
```

**Solution for Exercise 3:**

```text
Program TimeRecord
{ Adds minutes to a clock time stored as a record }

Dictionary
    type Time : < hour : integer, minute : integer >
    start : Time
    function AddMinutes(t : Time, minutes : integer) -> Time
    function Format(t : Time) -> string

Algorithm
    start <- < 9, 45 >
    output("Start             : ", Format(start))
    output("After 30 minutes  : ", Format(AddMinutes(start, 30)))
    output("After 150 minutes : ", Format(AddMinutes(start, 150)))
    output("After 900 minutes : ", Format(AddMinutes(start, 900)))

function AddMinutes(t : Time, minutes : integer) -> Time
{ Returns the time that is minutes after t, on a 24-hour clock }
Dictionary
    total : integer
Algorithm
    total <- t.hour * 60 + t.minute + minutes
    -> < (total div 60) mod 24, total mod 60 >

function Format(t : Time) -> string
{ Returns t as text in the form hh:mm }
Algorithm
    -> two-digit(t.hour) + ":" + two-digit(t.minute)
```

```java
// Program TimeRecord
// Adds minutes to a clock time stored as a record.
public class TimeRecord {
    // Type Time
    record Time(int hour, int minute) {}

    public static void main(String[] args) {
        // Dictionary
        Time start = new Time(9, 45);

        // Algorithm
        System.out.println("Start             : " + format(start));
        System.out.println("After 30 minutes  : " + format(addMinutes(start, 30)));
        System.out.println("After 150 minutes : " + format(addMinutes(start, 150)));
        System.out.println("After 900 minutes : " + format(addMinutes(start, 900)));
    }

    // Function AddMinutes
    // Returns the time that is minutes after t, on a 24-hour clock
    static Time addMinutes(Time t, int minutes) {
        int total = t.hour() * 60 + t.minute() + minutes;
        return new Time((total / 60) % 24, total % 60);
    }

    // Function Format
    // Returns t as text in the form hh:mm
    static String format(Time t) {
        return String.format("%02d:%02d", t.hour(), t.minute());
    }
}
```

The trick is to convert the time to a single number of minutes since midnight, add the extra minutes, and convert back with `div` and `mod`, the same pattern as `MinutesToHours` in Lesson 5. `mod 24` wraps the hour past midnight, so 900 minutes after 09:45 is 00:45 the next day. `String.format` works like `printf`, but instead of printing, it returns the formatted text as a string.

```bash
javac TimeRecord.java
java TimeRecord
```

Output:

```text
Start             : 09:45
After 30 minutes  : 10:15
After 150 minutes : 12:15
After 900 minutes : 00:45
```

---

## Next Up - Lesson 19

In this lesson you learned to group related data into records. You defined record types in notation with `type Name : < ... >` and in Java with `record`, created records and read their fields, passed records to functions and returned new ones, "updated" immutable records by creating new ones, and stored many records in an array. Module 6 is complete: you can now organize data as single values, lists, tables, text, and records.

With data stored in arrays, two questions come up constantly: "Is this value in the list, and where?" and "How do I put this list in order?" In Lesson 19 you will start Module 7 with **searching**. You will implement sequential search and binary search, trace both step by step in notation, and compare how many steps each one needs to find a value.
