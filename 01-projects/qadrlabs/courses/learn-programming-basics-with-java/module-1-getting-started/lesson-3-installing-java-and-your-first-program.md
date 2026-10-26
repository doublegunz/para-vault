## 1. Before You Begin

In Lessons 1 and 2 you designed algorithms on paper and tested them by tracing. Now it is time to hand an algorithm to a real computer. To do that, you need a programming language and the tools that turn your code into something the computer can run. This course uses **Java**.

In this lesson you will install the Java Development Kit (JDK) 21, write the classic Hello World program, and compile and run it from the terminal. Then you will take a notation algorithm and translate it into a complete Java program, part by part, so you can see that every section of the notation has a matching section in Java.

By the end of this lesson you will have a `java-basics` folder in your home directory. Every later lesson adds a new subfolder inside it, so all your course work stays in one place.

### What You'll Build

Two Java programs. The first, `HelloWorld.java`, displays a greeting. The second, `TotalPrice.java`, is a direct translation of the `TotalPrice` algorithm from Lesson 2: it stores a price and a quantity, calculates the total, and displays the result.

### What You'll Learn

- ✅ What the JDK is, and what `javac` and `java` each do
- ✅ How to install JDK 21 on Ubuntu, Windows, or macOS and verify the installation
- ✅ How to write, compile, and run a Java program from the terminal
- ✅ What a `.class` file is and why compiling is a separate step
- ✅ The difference between `System.out.println` and `System.out.print`
- ✅ How the Program header, Dictionary, and Algorithm sections map to a Java program

### What You'll Need

- Lessons 1 and 2 completed
- A computer running Linux, Windows, or macOS with terminal access
- An internet connection to download JDK 21 (around 200 megabytes)
- A text editor such as Visual Studio Code

---

## 2. Install JDK 21

Java programs go through two stages. First, a tool called the **compiler** reads your source code and checks that it follows Java's rules. If it does, the compiler translates it into **bytecode**, a compact format stored in a `.class` file. Second, the **Java Virtual Machine (JVM)** reads the bytecode and runs it on your computer. The same `.class` file runs on Linux, Windows, and macOS, which is one of the reasons Java is so widely used.

The **Java Development Kit (JDK)** contains both tools:

| Tool | Responsibility |
| --- | --- |
| `javac` | The Java compiler; turns `.java` source files into `.class` bytecode files |
| `java` | The launcher; starts the JVM and runs a compiled program |

This course uses **JDK 21**, a long-term support (LTS) release, which means it receives updates for many years. Any newer JDK version also works for everything in this course.

### Step 1: Install the JDK

Choose the instructions for your operating system.

**Ubuntu or Debian based Linux.** Open a terminal (press `Ctrl` + `Alt` + `T` on Ubuntu) and run:

```bash
sudo apt update
sudo apt install openjdk-21-jdk
```

`sudo` runs a command with administrator rights, so Ubuntu asks for your password. `apt update` refreshes the list of available packages, and `apt install openjdk-21-jdk` installs OpenJDK 21, a free and open source build of the JDK, including both `javac` and `java`.

**Windows or macOS.** Open [adoptium.net](https://adoptium.net/), choose **Temurin 21 (LTS)**, and download the installer for your system (`.msi` for Windows, `.pkg` for macOS). Run the installer and keep the default options. On Windows, make sure the option that adds Java to the `PATH` is enabled, so the terminal can find `javac` and `java`. Eclipse Temurin is a free, widely used build of OpenJDK.

### Step 2: Verify the Installation

Open a new terminal (on Windows, open **Command Prompt** or **PowerShell**) and check both tools:

```bash
java -version
javac -version
```

Output:

```text
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-26.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-26.04.4-Ubuntu, mixed mode, sharing)
javac 21.0.12.1
```

The first three lines come from `java -version` and the last line from `javac -version`. Your exact numbers and build names will differ depending on your system and when you install, but both commands should report version 21 or newer. If the terminal says `command not found` (Linux and macOS) or `is not recognized as an internal or external command` (Windows), close the terminal and open a new one; if the problem remains, the JDK is either not installed or not on your `PATH`, so run the installer again.

---

## 3. Write and Run Your First Program

Before translating algorithms, it helps to see the compile and run workflow with the smallest possible program.

### Step 1: Create a Course Folder

Create a folder for all your course work and a subfolder for this lesson:

```bash
mkdir -p ~/java-basics/lesson-03
cd ~/java-basics/lesson-03
```

`mkdir -p` creates a directory, including any missing parent directories (here, `java-basics` and then `lesson-03` inside it). The `~` is a shortcut for your home directory. `cd` moves the terminal into the new folder, so the next commands run there. On Windows Command Prompt, use `mkdir %USERPROFILE%\java-basics\lesson-03` followed by `cd %USERPROFILE%\java-basics\lesson-03` instead.

If Visual Studio Code is installed, open the current folder in it:

```bash
code .
```

The `.` means "the current directory." Any other text editor works too, as long as it saves plain text files.

### Step 2: Write the Source File

Create a new file named `HelloWorld.java` in the `lesson-03` folder and type the following code:

```java
public class HelloWorld {
    public static void main(String[] args) {
        // Display a greeting on the screen.
        System.out.println("Hello, world!");
    }
}
```

There is more ceremony here than in a notation algorithm, so let us go through it line by line:

- `public class HelloWorld {` starts a **class** named `HelloWorld`. Every Java program lives inside a class. For now, think of the class as the container for your program, the same role the `Program` header plays in notation. The class name must match the file name exactly: `HelloWorld` goes in `HelloWorld.java`.
- `public static void main(String[] args) {` declares the **main method**, the place where the program starts running. Java looks for a method with exactly this line when you run a program. You will learn what `public`, `static`, `void`, and `String[] args` mean in later lessons; for now, type it exactly as shown.
- `// Display a greeting on the screen.` is a **comment**. Everything after `//` on a line is ignored by the compiler, just like text in `{ }` in notation.
- `System.out.println("Hello, world!");` displays the text inside the quotes and then moves to a new line. It is Java's version of `output("Hello, world!")`. The semicolon `;` marks the end of the statement. Every statement in Java ends with a semicolon.
- The two closing braces `}` end the `main` method and then the class. Every `{` must have a matching `}`.

Java is **case sensitive**: `System` and `system` are different words, and only `System` is correct. Pay attention to capital letters as you type.

### Step 3: Compile the Program

Save the file, go back to the terminal, and compile it:

```bash
javac HelloWorld.java
```

If the code is correct, `javac` prints nothing at all. For command-line tools, silence usually means success. List the folder's contents to see what the compiler produced:

```bash
ls
```

Output:

```text
HelloWorld.class
HelloWorld.java
```

(On Windows Command Prompt, use `dir` instead of `ls`.) There are now two files. `HelloWorld.java` is your source code, which humans read and edit. `HelloWorld.class` is the bytecode the compiler created, which the JVM runs.

### Step 4: Run the Program

Run the compiled program with `java` followed by the class name:

```bash
java HelloWorld
```

Output:

```text
Hello, world!
```

Notice that you type `java HelloWorld`, not `java HelloWorld.class` and not `java HelloWorld.java`. The `java` command takes the *name of the class* to run, and it finds the matching `.class` file by itself.

### Step 5: See That Compiling Is a Separate Step

Change the greeting in `HelloWorld.java` to `"Hello, Java!"` and save the file. Now run `java HelloWorld` again *without* compiling. It still prints `Hello, world!`, because the `.class` file was built from the old source and does not know the source changed. Run `javac HelloWorld.java` and then `java HelloWorld`, and the new greeting appears.

This is the most important habit from this lesson: **after every change to a `.java` file, compile again before running.** The workflow is always edit, compile, run.

### Step 6: Compare print and println

Java has two common ways to display text. Create `PrintVsPrintln.java`:

```java
public class PrintVsPrintln {
    public static void main(String[] args) {
        System.out.print("One ");
        System.out.print("line, ");
        System.out.println("then a new line.");
        System.out.println("Second line.");
        System.out.println();
        System.out.println("After an empty line.");
    }
}
```

`System.out.print` displays text and stays on the same line, so the next output continues right after it. `System.out.println` displays text and then moves to the next line (the `ln` stands for "line"). `System.out.println()` with nothing inside the parentheses just moves to a new line, which produces an empty line in the output.

Compile and run it:

```bash
javac PrintVsPrintln.java
java PrintVsPrintln
```

Output:

```text
One line, then a new line.
Second line.

After an empty line.
```

The first three statements together produce one line of output, because only the third one ends the line. You will use `print` most often for prompts, so the user types their answer on the same line as the question.

---

## 4. Translate an Algorithm into Java

Now for the main goal of this lesson: turning a notation algorithm into a Java program. Here is a version of the `TotalPrice` algorithm from Lesson 2. Since reading keyboard input in Java is covered in Lesson 6, this version assigns fixed values instead of using `input()`:

```text
Program TotalPrice
{ Calculates the total price of a purchase from the price and quantity }

Dictionary
    price    : integer
    quantity : integer
    total    : integer

Algorithm
    price <- 5000
    quantity <- 3
    total <- price * quantity
    output("Price: ", price)
    output("Quantity: ", quantity)
    output("Total: ", total)
```

### Step 1: Map Each Part of the Notation

Every part of the notation has a home in a Java program:

| Notation | Java |
| --- | --- |
| `Program TotalPrice` | `public class TotalPrice { ... }` in a file named `TotalPrice.java` |
| `{ comment }` | `// comment` |
| `Dictionary` | Variable declarations at the start of `main` |
| `price : integer` | `int price;` |
| `Algorithm` | The statements inside `main` |
| `price <- 5000` | `price = 5000;` |
| `output("Total: ", total)` | `System.out.println("Total: " + total);` |

Two differences deserve attention. First, the integer type is called `int` in Java. Second, Java writes assignment with a single `=` instead of `<-`. It still means "store the value on the right in the variable on the left," not "is equal to." In `output`, notation separates items with commas; in Java, you join text and values with `+`, which glues them together into one piece of text.

### Step 2: Write the Java Program

Create `TotalPrice.java` in the `lesson-03` folder:

```java
// Program TotalPrice
// Calculates the total price of a purchase from the price and quantity.
public class TotalPrice {
    public static void main(String[] args) {
        // Dictionary
        int price;
        int quantity;
        int total;

        // Algorithm
        price = 5000;
        quantity = 3;
        total = price * quantity;
        System.out.println("Price: " + price);
        System.out.println("Quantity: " + quantity);
        System.out.println("Total: " + total);
    }
}
```

Compare it with the notation line by line:

- The first two comment lines carry the program name and description from the notation header. The class name `TotalPrice` matches both the `Program` name and the file name.
- The `// Dictionary` block declares three variables. `int price;` tells Java: "reserve a storage place named `price` that holds a whole number." This is exactly what `price : integer` says in notation.
- The `// Algorithm` block contains the steps in the same order as the notation. `price = 5000;` and `quantity = 3;` store values. `total = price * quantity;` calculates the product and stores it in `total`.
- Each `System.out.println` displays a label followed by a value. In `"Price: " + price`, Java takes the text `"Price: "`, converts the number in `price` to text, and joins them, producing `Price: 5000`.

The `// Dictionary` and `// Algorithm` comments are not required by Java, but this course uses them in early lessons so you can see the notation's structure inside the code.

### Step 3: Compile and Run

```bash
javac TotalPrice.java
java TotalPrice
```

Output:

```text
Price: 5000
Quantity: 3
Total: 15000
```

The computer produced exactly the result you would get by tracing the algorithm by hand: 5000 times 3 is 15000. That match between your trace and the program's output is the whole point of designing algorithms first. When they disagree, either the algorithm or the translation has a mistake, and you know where to look.

---

## 5. Run and Test

Test that you are comfortable with the edit, compile, run workflow by changing the program's data.

1. In `TotalPrice.java`, change `price = 5000;` to `price = 7500;` and `quantity = 3;` to `quantity = 4;`.
2. Before running anything, trace the algorithm in your head: 7500 times 4 is 30000.
3. Save, compile, and run:

```bash
javac TotalPrice.java
java TotalPrice
```

Output:

```text
Price: 7500
Quantity: 4
Total: 30000
```

The output matches the expected value. If you see the old values instead, you forgot to compile after saving. If `javac` prints an error, read it carefully and check the next section; compiler messages always include the file name and the line number where the problem was found.

When you are done, put the original values (5000 and 3) back so the file matches the lesson.

---

## 6. Fix the Errors in Your Code

Compiler errors are a normal part of programming, not a sign that you are doing badly. The Java compiler checks every line before the program runs and tells you exactly where it got confused. Here are the errors beginners see first.

**Error 1: A missing semicolon.**

```java
// Wrong
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, world!")
    }
}

// Correct
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, world!");
    }
}
```

The wrong version produces this message:

```text
HelloWorld.java:3: error: ';' expected
        System.out.println("Hello, world!")
                                           ^
1 error
```

`HelloWorld.java:3` means "file `HelloWorld.java`, line 3." The caret `^` points to the spot where Java expected a semicolon. Every statement must end with `;`.

**Error 2: A class name that does not match the file name.**

```java
// Wrong (saved in a file named Hello.java)
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, world!");
    }
}

// Correct (saved in a file named HelloWorld.java)
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, world!");
    }
}
```

Compiling the wrong version with `javac Hello.java` produces:

```text
Hello.java:1: error: class HelloWorld is public, should be declared in a file named HelloWorld.java
public class HelloWorld {
       ^
1 error
```

A public class must be saved in a file with exactly the same name, including capital letters, plus `.java`. Either rename the file or rename the class so they match.

**Error 3: Wrong capitalization.**

```java
// Wrong
public class HelloWorld {
    public static void main(String[] args) {
        system.out.println("Hello, world!");
    }
}

// Correct
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, world!");
    }
}
```

The wrong version produces:

```text
HelloWorld.java:3: error: package system does not exist
        system.out.println("Hello, world!");
              ^
1 error
```

The message looks confusing because Java tried to understand `system` as something else entirely. The real cause is simple: Java is case sensitive, and the correct name is `System` with a capital S.

A related mistake happens when running. Typing `java HelloWorld.class` instead of `java HelloWorld` produces:

```text
Error: Could not find or load main class HelloWorld.class
Caused by: java.lang.ClassNotFoundException: HelloWorld.class
```

The `java` command expects the class name only, without any file extension.

---

## 7. Exercises

**Exercise 1:** Write a program named `WelcomeBox` that displays a welcome message inside a box drawn with `+`, `-`, and `|` characters, using several `System.out.println` statements.

**Exercise 2:** Translate the `RectangleArea` algorithm below into a Java program, then compile and run it.

```text
Program RectangleArea
{ Calculates the area and perimeter of a rectangle with a fixed size }

Dictionary
    length, width, area, perimeter : integer

Algorithm
    length <- 8
    width <- 5
    area <- length * width
    perimeter <- 2 * (length + width)
    output("Length: ", length)
    output("Width: ", width)
    output("Area: ", area)
    output("Perimeter: ", perimeter)
```

**Exercise 3:** Write the notation for a program named `DailySavings` that calculates how much money someone saves if they put aside 2000 every day for 30 days. Then translate it into Java. Display the result on one line using `System.out.print` followed by `System.out.println`.

---

## 8. Solutions

**Solution for Exercise 1:**

```java
public class WelcomeBox {
    public static void main(String[] args) {
        System.out.println("+----------------------------+");
        System.out.println("|  Welcome to Programming!   |");
        System.out.println("|  Algorithm first, code     |");
        System.out.println("|  second.                   |");
        System.out.println("+----------------------------+");
    }
}
```

Each `println` displays one line of the box. Inside double quotes, characters like `+`, `-`, and `|` are just text, so Java displays them exactly as written. The spaces inside the quotes are also part of the text, which is how the right edge of the box lines up.

```bash
javac WelcomeBox.java
java WelcomeBox
```

Output:

```text
+----------------------------+
|  Welcome to Programming!   |
|  Algorithm first, code     |
|  second.                   |
+----------------------------+
```

**Solution for Exercise 2:**

```java
// Program RectangleArea
// Calculates the area and perimeter of a rectangle with a fixed size.
public class RectangleArea {
    public static void main(String[] args) {
        // Dictionary
        int length;
        int width;
        int area;
        int perimeter;

        // Algorithm
        length = 8;
        width = 5;
        area = length * width;
        perimeter = 2 * (length + width);
        System.out.println("Length: " + length);
        System.out.println("Width: " + width);
        System.out.println("Area: " + area);
        System.out.println("Perimeter: " + perimeter);
    }
}
```

The Dictionary line `length, width, area, perimeter : integer` becomes four `int` declarations. Each assignment arrow becomes `=` with a semicolon at the end, and each `output` becomes a `println` that joins a label and a value with `+`. The parentheses in the perimeter formula work exactly as in mathematics.

```bash
javac RectangleArea.java
java RectangleArea
```

Output:

```text
Length: 8
Width: 5
Area: 40
Perimeter: 26
```

**Solution for Exercise 3:**

```text
Program DailySavings
{ Calculates how much money is saved after a number of days }

Dictionary
    savingPerDay, days, totalSaving : integer

Algorithm
    savingPerDay <- 2000
    days <- 30
    totalSaving <- savingPerDay * days
    output("Saving ", savingPerDay, " per day for ", days, " days gives ", totalSaving, ".")
```

```java
// Program DailySavings
// Calculates how much money is saved after a number of days.
public class DailySavings {
    public static void main(String[] args) {
        // Dictionary
        int savingPerDay;
        int days;
        int totalSaving;

        // Algorithm
        savingPerDay = 2000;
        days = 30;
        totalSaving = savingPerDay * days;
        System.out.print("Saving " + savingPerDay + " per day for " + days + " days");
        System.out.println(" gives " + totalSaving + ".");
    }
}
```

The single `output` in the notation is split into a `print` and a `println` in Java, but the result is still one line, because `print` does not move to a new line. Joining several pieces with `+` works the same way as in earlier examples: each number is converted to text and glued between the labels.

```bash
javac DailySavings.java
java DailySavings
```

Output:

```text
Saving 2000 per day for 30 days gives 60000.
```

---

## Next Up - Lesson 4

In this lesson you installed JDK 21, learned that `javac` compiles `.java` source files into `.class` bytecode and `java` runs that bytecode on the JVM, and practiced the edit, compile, run workflow. Most importantly, you translated a notation algorithm into a Java program and saw that the Program header becomes a class, the Dictionary becomes variable declarations, and the Algorithm section becomes the statements inside `main`.

So far every variable has been an `integer`. In Lesson 4 you will look closely at variables, constants, and data types: how to choose between `integer`, `real`, `character`, `boolean`, and `string` in notation, and how each one maps to a Java type such as `int`, `double`, `char`, `boolean`, and `String`.
