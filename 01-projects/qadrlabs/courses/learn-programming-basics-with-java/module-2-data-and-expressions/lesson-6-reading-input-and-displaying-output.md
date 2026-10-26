## 1. Before You Begin

Since Lesson 2, almost every algorithm you designed started with `input()`. Yet every Java program so far has used fixed values written directly into the code, so the only way to try new data was to edit the file and compile again. A program that always calculates the total for 3 notebooks at 5000 each is not very useful.

In this lesson you will finally translate `input()` into Java. You will use the `Scanner` class to read text, whole numbers, and decimal numbers from the keyboard. You will also improve the other side of the input, process, output pattern: instead of letting Java print numbers however it likes, you will use `printf` to control decimal places, widths, and alignment. By the end, your programs will work with any data the user types.

### What You'll Build

Interactive versions of algorithms from earlier lessons: a greeting that asks for your name, a total price calculator, a circle calculator, and a purchase program that reads an item name, price, and quantity, then prints a neatly formatted bill with tax.

### What You'll Learn

- ✅ How to create a `Scanner` that reads from the keyboard
- ✅ How to read a line of text, an integer, and a decimal with `nextLine`, `nextInt`, and `nextDouble`
- ✅ How to write a clear prompt with `System.out.print`
- ✅ How to format numbers with `printf` and format specifiers such as `%d`, `%s`, and `%.2f`
- ✅ How to set column widths and align text in output
- ✅ Why `nextLine` after `nextInt` skips input, and how to fix it
- ✅ What happens when the user types the wrong kind of data

### What You'll Need

- Lessons 4 and 5 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-06
cd ~/java-basics/lesson-06
```

---

## 2. Read Input with Scanner

Java's standard library has a class named `Scanner` that reads input piece by piece. To use it, you import it at the top of the file and create one `Scanner` object connected to the keyboard. After that, each `input(x)` in your notation becomes a single line of Java.

| Notation | Java | Reads |
| --- | --- | --- |
| `input(name)` where `name : string` | `name = input.nextLine();` | A whole line of text |
| `input(age)` where `age : integer` | `age = input.nextInt();` | A whole number |
| `input(height)` where `height : real` | `height = input.nextDouble();` | A decimal number |

The method you call depends on the variable's type in the Dictionary. This is another reason to declare types carefully: the type tells you exactly which `Scanner` method to use.

### Step 1: Read a Line of Text

Here is the greeting algorithm from Lesson 2:

```text
Program Greeting
{ Reads the user's name and displays a personal greeting }

Dictionary
    name : string

Algorithm
    output("What is your name? ")
    input(name)
    output("Hello, ", name, "! Welcome to programming.")
```

Create `Greeting.java`:

```java
import java.util.Scanner;

// Program Greeting
// Reads the user's name and displays a personal greeting.
public class Greeting {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String name;

        // Algorithm
        System.out.print("What is your name? ");
        name = input.nextLine();
        System.out.println("Hello, " + name + "! Welcome to programming.");
    }
}
```

There are three new lines compared with earlier programs:

- `import java.util.Scanner;` goes at the very top, before the class. Java's library is organized into **packages**, and `Scanner` lives in the package `java.util`. The `import` line tells the compiler where to find it.
- `Scanner input = new Scanner(System.in);` creates a `Scanner` object and stores it in a variable named `input`. `System.in` is the keyboard, the standard input, just as `System.out` is the screen. You create the `Scanner` once at the start of `main` and reuse it for every input. Naming it `input` makes the Java code read like the notation.
- `name = input.nextLine();` waits for the user to type something and press Enter, then stores the whole line, spaces included, in `name`.

The prompt uses `print` instead of `println`, so the cursor waits on the same line as the question.

```bash
javac Greeting.java
java Greeting
```

The program stops and waits after the prompt. Type `Budi Santoso` and press Enter.

Output:

```text
What is your name? Budi Santoso
Hello, Budi Santoso! Welcome to programming.
```

In this output and the ones that follow, the text after each prompt is what the user typed. Because `nextLine` reads the whole line, the space between the first and last name is kept.

### Step 2: Read Whole Numbers

Now the total price algorithm can finally read its data:

```text
Program TotalPrice
{ Reads the price of one item and the quantity bought, then displays the total price }

Dictionary
    price, quantity, total : integer

Algorithm
    output("Price of one item: ")
    input(price)
    output("Quantity: ")
    input(quantity)
    total <- price * quantity
    output("Total: ", total)
```

Create `TotalPrice.java`:

```java
import java.util.Scanner;

// Program TotalPrice
// Reads the price of one item and the quantity bought, then displays the total price.
public class TotalPrice {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int price;
        int quantity;
        int total;

        // Algorithm
        System.out.print("Price of one item: ");
        price = input.nextInt();
        System.out.print("Quantity: ");
        quantity = input.nextInt();
        total = price * quantity;
        System.out.println("Total: " + total);
    }
}
```

Each `input()` becomes a prompt with `print` followed by `input.nextInt()`, because `price` and `quantity` are integers. `nextInt` reads the characters the user typed and converts them into an `int` value.

```bash
javac TotalPrice.java
java TotalPrice
```

Type `5000`, press Enter, then type `3` and press Enter.

Output:

```text
Price of one item: 5000
Quantity: 3
Total: 15000
```

Run it again with different numbers. You no longer need to edit and recompile the program to test new data, which is exactly what makes input so powerful.

### Step 3: Read Decimal Numbers

For `real` variables, use `nextDouble`:

```text
Program CircleCalculator
{ Reads the radius of a circle and displays its area and circumference }

Dictionary
    constant PI : real = 3.14159
    radius, area, circumference : real

Algorithm
    output("Radius: ")
    input(radius)
    area <- PI * radius * radius
    circumference <- 2 * PI * radius
    output("Area         : ", area)
    output("Circumference: ", circumference)
```

Create `CircleCalculator.java`. This version prints each result twice, once with `println` and once with `printf`, so you can compare them:

```java
import java.util.Scanner;

// Program CircleCalculator
// Reads the radius of a circle and displays its area and circumference.
public class CircleCalculator {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final double PI = 3.14159;
        double radius;
        double area;
        double circumference;

        // Algorithm
        System.out.print("Radius: ");
        radius = input.nextDouble();
        area = PI * radius * radius;
        circumference = 2 * PI * radius;
        System.out.println("Area         : " + area);
        System.out.println("Circumference: " + circumference);
        System.out.printf("Area         : %.2f%n", area);
        System.out.printf("Circumference: %.2f%n", circumference);
    }
}
```

`input.nextDouble()` reads a number that may include a decimal point, such as `7` or `7.5`. The two `printf` lines are new; they are explained in the next section.

```bash
javac CircleCalculator.java
java CircleCalculator
```

Type `7` and press Enter.

Output:

```text
Radius: 7
Area         : 153.93791
Circumference: 43.98226
Area         : 153.94
Circumference: 43.98
```

The `println` lines show every digit Java has. The `printf` lines show exactly two decimal places, rounded, which is usually what a person wants to see.

---

## 3. Format Output with printf

`System.out.printf` ("print formatted") displays text built from a **format string** and a list of values. Inside the format string, each **format specifier**, which starts with `%`, marks a place where a value is inserted and says how to display it.

| Specifier | Displays | Example | Result |
| --- | --- | --- | --- |
| `%d` | An integer | `printf("%d", 42)` | `42` |
| `%f` | A decimal number (6 decimal places) | `printf("%f", 3.14159)` | `3.141590` |
| `%.2f` | A decimal number with 2 decimal places | `printf("%.2f", 3.14159)` | `3.14` |
| `%s` | A string (or any value as text) | `printf("%s", "Budi")` | `Budi` |
| `%c` | A single character | `printf("%c", 'A')` | `A` |
| `%n` | A new line | | |
| `%%` | A literal percent sign | `printf("11%%")` | `11%` |

Unlike `println`, `printf` does not move to a new line by itself, so most format strings end with `%n`.

### Step 1: Control Width and Alignment

A number between `%` and the letter sets a minimum **width**: the value is padded with spaces to fill that many characters. A minus sign aligns the value to the left instead of the right. This is how you build tables with straight columns.

| Specifier | Meaning | Example value | Result |
| --- | --- | --- | --- |
| `%8d` | Integer, at least 8 wide, right aligned | `450` | `     450` |
| `%-10s` | String, at least 10 wide, left aligned | `"Pen"` | `Pen       ` |
| `%10.2f` | Decimal, 10 wide, 2 decimal places | `412.5` | `    412.50` |
| `%02d` | Integer, 2 wide, padded with zeros | `5` | `05` |

Create `FormattedReceipt.java`:

```java
// Program FormattedReceipt
// Displays a small receipt with aligned columns using printf.
public class FormattedReceipt {
    public static void main(String[] args) {
        // Dictionary
        String item1 = "Notebook";
        int qty1 = 3;
        int price1 = 5000;
        String item2 = "Pen";
        int qty2 = 12;
        int price2 = 2500;
        int total;

        // Algorithm
        total = qty1 * price1 + qty2 * price2;
        System.out.printf("%-10s %5s %10s%n", "Item", "Qty", "Subtotal");
        System.out.printf("%-10s %5d %10d%n", item1, qty1, qty1 * price1);
        System.out.printf("%-10s %5d %10d%n", item2, qty2, qty2 * price2);
        System.out.printf("%-10s %5s %10d%n", "TOTAL", "", total);
    }
}
```

Every line uses the same widths: 10 characters, left aligned, for the item name; 5 characters for the quantity; and 10 characters for the subtotal. Because the widths match, the columns line up regardless of how long each value is. The values after the format string are inserted in order: the first value goes into the first specifier, the second into the second, and so on. In the last line, an empty string `""` fills the quantity column with spaces.

```bash
javac FormattedReceipt.java
java FormattedReceipt
```

Output:

```text
Item         Qty   Subtotal
Notebook       3      15000
Pen           12      30000
TOTAL                 45000
```

In notation, you do not need to write format specifiers. `output("Total: ", total)` describes *what* to display; choosing the exact layout is a detail of the Java implementation.

A note for readers whose computers use a language setting such as Indonesian: `printf` follows the system's number format, so it may display `153,94` with a comma instead of `153.94`. Both are correct; the program simply follows your system's settings.

---

## 4. Run and Test

Now put input and formatted output together in the purchase algorithm from Lesson 2, extended with an item name:

```text
Program PurchaseWithTax
{ Calculates the subtotal, tax, and total payment for a purchase }

Dictionary
    constant TAX_RATE : real = 0.11
    itemName : string
    price, quantity : integer
    subtotal, tax, total : real

Algorithm
    output("Item name : ")
    input(itemName)
    output("Price     : ")
    input(price)
    output("Quantity  : ")
    input(quantity)
    subtotal <- price * quantity
    tax <- subtotal * TAX_RATE
    total <- subtotal + tax
    output(quantity, " x ", itemName)
    output("Subtotal  : ", subtotal)
    output("Tax (11%) : ", tax)
    output("Total     : ", total)
```

Create `PurchaseWithTax.java`:

```java
import java.util.Scanner;

// Program PurchaseWithTax
// Calculates the subtotal, tax, and total payment for a purchase.
public class PurchaseWithTax {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final double TAX_RATE = 0.11;
        String itemName;
        int price;
        int quantity;
        double subtotal;
        double tax;
        double total;

        // Algorithm
        System.out.print("Item name : ");
        itemName = input.nextLine();
        System.out.print("Price     : ");
        price = input.nextInt();
        System.out.print("Quantity  : ");
        quantity = input.nextInt();
        subtotal = price * quantity;
        tax = subtotal * TAX_RATE;
        total = subtotal + tax;
        System.out.println();
        System.out.printf("%d x %s%n", quantity, itemName);
        System.out.printf("Subtotal  : %12.2f%n", subtotal);
        System.out.printf("Tax (11%%) : %12.2f%n", tax);
        System.out.printf("Total     : %12.2f%n", total);
    }
}
```

The item name is read first with `nextLine`, so it can contain spaces. The two numbers are read with `nextInt`. `System.out.println()` prints an empty line to separate the input from the bill. Each amount uses `%12.2f`, so all three numbers are right aligned in a 12 character column with exactly two decimal places. The `%%` in the tax label displays a single `%` sign.

Compile it and test it with the values you traced in Lesson 2 (price 12500, quantity 4), where you expected a subtotal of 50000, tax of 5500, and total of 55500:

```bash
javac PurchaseWithTax.java
java PurchaseWithTax
```

Output:

```text
Item name : Drawing Book
Price     : 12500
Quantity  : 4

4 x Drawing Book
Subtotal  :     50000.00
Tax (11%) :      5500.00
Total     :     55500.00
```

The program agrees with your hand trace. Now run it again with a price that produces a tax with a decimal part, such as 1250 and a quantity of 3:

```bash
java PurchaseWithTax
```

Output:

```text
Item name : Pencil
Price     : 1250
Quantity  : 3

3 x Pencil
Subtotal  :      3750.00
Tax (11%) :       412.50
Total     :      4162.50
```

11% of 3750 is 412.5, and `%.2f` displays it as `412.50`. The amounts stay aligned even though they have different numbers of digits.

---

## 5. Fix the Errors in Your Code

Input brings a new kind of problem: the program depends on what a human types, and humans do unexpected things. Here are the mistakes you are most likely to meet.

**Error 1: Forgetting the import.**

```java
// Wrong
public class NoImport {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        int number = input.nextInt();
        System.out.println(number);
    }
}

// Correct
import java.util.Scanner;

public class NoImport {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        int number = input.nextInt();
        System.out.println(number);
    }
}
```

The wrong version produces:

```text
NoImport.java:3: error: cannot find symbol
        Scanner input = new Scanner(System.in);
        ^
  symbol:   class Scanner
  location: class NoImport
NoImport.java:3: error: cannot find symbol
        Scanner input = new Scanner(System.in);
                            ^
  symbol:   class Scanner
  location: class NoImport
2 errors
```

"Cannot find symbol" means the compiler does not know the name `Scanner`. Add `import java.util.Scanner;` as the first line of the file.

**Error 2: `nextLine` after `nextInt` skips the input.**

```java
// Wrong
import java.util.Scanner;

public class StudentCard {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        int age;
        String name;

        System.out.print("Age : ");
        age = input.nextInt();
        System.out.print("Name: ");
        name = input.nextLine();
        System.out.println(name + " is " + age + " years old.");
    }
}

// Correct
import java.util.Scanner;

public class StudentCard {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        int age;
        String name;

        System.out.print("Age : ");
        age = input.nextInt();
        input.nextLine();
        System.out.print("Name: ");
        name = input.nextLine();
        System.out.println(name + " is " + age + " years old.");
    }
}
```

The wrong version compiles, but when you type `19` and press Enter, it does not wait for the name at all:

```text
Age : 19
Name:  is 19 years old.
```

The correct version waits for the name as expected:

```text
Age : 19
Name: Budi Santoso
Budi Santoso is 19 years old.
```

When you type `19` and press Enter, the keyboard sends the characters `19` followed by an invisible "end of line" character. `nextInt` reads the `19` but leaves the end of line waiting. The following `nextLine` reads everything up to the next end of line, finds it immediately, and returns an empty string. The fix is an extra `input.nextLine();` right after `nextInt` to throw away the leftover end of line. Another simple fix is to read all text values *before* any numbers, as `PurchaseWithTax` does.

**Error 3: The user types the wrong kind of data.**

Run `TotalPrice` and type the word `five` instead of a number:

```bash
java TotalPrice
```

Output:

```text
Price of one item: five
Exception in thread "main" java.util.InputMismatchException
	at java.base/java.util.Scanner.throwFor(Scanner.java:947)
	at java.base/java.util.Scanner.next(Scanner.java:1602)
	at java.base/java.util.Scanner.nextInt(Scanner.java:2267)
	at java.base/java.util.Scanner.nextInt(Scanner.java:2221)
	at TotalPrice.main(TotalPrice.java:16)
```

This is not a compiler error; the program compiled fine. It is a **runtime error**, called an **exception** in Java, that happens while the program runs. `InputMismatchException` means `nextInt` received text it could not turn into an integer, so the program stopped. The last line, `TotalPrice.java:16`, points to the line that was running. The fix for now is simply to type the kind of value the prompt asks for. In Lesson 11 you will learn a loop pattern that checks input and asks again when it is not valid.

---

## 6. Exercises

**Exercise 1:** Write the notation and the Java program `BmiCalculator` that reads a person's weight in kilograms and height in centimeters, then displays their body mass index (BMI) with one decimal place. BMI is weight divided by height in meters squared.

**Exercise 2:** Write the notation and the Java program `SecondsToClock` that reads a number of seconds and displays it in the format `hh:mm:ss`, with each part shown as two digits. For example, 3725 seconds is `01:02:05`.

**Exercise 3:** Write the notation and the Java program `AverageOfThree` that reads a student's name and three integer scores, then displays a sentence such as `Siti Rahma's average is 84.33`, with two decimal places. Make sure the average is not affected by integer division.

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program BmiCalculator
{ Reads weight and height, then displays the body mass index }

Dictionary
    weight, heightCm, heightM, bmi : real

Algorithm
    output("Weight (kg): ")
    input(weight)
    output("Height (cm): ")
    input(heightCm)
    heightM <- heightCm / 100
    bmi <- weight / (heightM * heightM)
    output("Your BMI is ", bmi)
```

```java
import java.util.Scanner;

// Program BmiCalculator
// Reads weight and height, then displays the body mass index.
public class BmiCalculator {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        double weight;
        double heightCm;
        double heightM;
        double bmi;

        // Algorithm
        System.out.print("Weight (kg): ");
        weight = input.nextDouble();
        System.out.print("Height (cm): ");
        heightCm = input.nextDouble();
        heightM = heightCm / 100;
        bmi = weight / (heightM * heightM);
        System.out.printf("Your BMI is %.1f%n", bmi);
    }
}
```

Height is read in centimeters, which is what most people know, and converted to meters before the calculation. The parentheses around `heightM * heightM` make sure the height is squared before dividing. `%.1f` displays one decimal place.

```bash
javac BmiCalculator.java
java BmiCalculator
```

Output:

```text
Weight (kg): 65
Height (cm): 170
Your BMI is 22.5
```

**Solution for Exercise 2:**

```text
Program SecondsToClock
{ Converts a number of seconds into the hh:mm:ss format }

Dictionary
    totalSeconds, hours, minutes, seconds : integer

Algorithm
    output("Total seconds: ")
    input(totalSeconds)
    hours <- totalSeconds div 3600
    minutes <- (totalSeconds mod 3600) div 60
    seconds <- totalSeconds mod 60
    output("Time: ", hours, ":", minutes, ":", seconds)
```

```java
import java.util.Scanner;

// Program SecondsToClock
// Converts a number of seconds into the hh:mm:ss format.
public class SecondsToClock {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int totalSeconds;
        int hours;
        int minutes;
        int seconds;

        // Algorithm
        System.out.print("Total seconds: ");
        totalSeconds = input.nextInt();
        hours = totalSeconds / 3600;
        minutes = (totalSeconds % 3600) / 60;
        seconds = totalSeconds % 60;
        System.out.printf("Time: %02d:%02d:%02d%n", hours, minutes, seconds);
    }
}
```

An hour has 3600 seconds, so `div 3600` gives the hours. `mod 3600` keeps the seconds that do not make a full hour, and `div 60` turns them into minutes. `mod 60` gives the remaining seconds. The specifier `%02d` pads each number with a leading zero to two digits, which is the standard clock format. The notation leaves out this formatting detail.

```bash
javac SecondsToClock.java
java SecondsToClock
```

Output:

```text
Total seconds: 3725
Time: 01:02:05
```

**Solution for Exercise 3:**

```text
Program AverageOfThree
{ Reads a student's name and three scores, then displays the average }

Dictionary
    name : string
    score1, score2, score3 : integer
    average : real

Algorithm
    output("Student name: ")
    input(name)
    output("Score 1: ")
    input(score1)
    output("Score 2: ")
    input(score2)
    output("Score 3: ")
    input(score3)
    average <- (score1 + score2 + score3) / 3
    output(name, "'s average is ", average)
```

```java
import java.util.Scanner;

// Program AverageOfThree
// Reads a student's name and three scores, then displays the average.
public class AverageOfThree {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String name;
        int score1;
        int score2;
        int score3;
        double average;

        // Algorithm
        System.out.print("Student name: ");
        name = input.nextLine();
        System.out.print("Score 1: ");
        score1 = input.nextInt();
        System.out.print("Score 2: ");
        score2 = input.nextInt();
        System.out.print("Score 3: ");
        score3 = input.nextInt();
        average = (score1 + score2 + score3) / 3.0;
        System.out.printf("%s's average is %.2f%n", name, average);
    }
}
```

The name is read first with `nextLine`, which avoids the skipped input problem from Error 2. Dividing by `3.0` instead of `3` makes the division real, because one side is now a `double`; this is a common alternative to a cast. In notation, `/` already means real division, so no special treatment is needed there.

```bash
javac AverageOfThree.java
java AverageOfThree
```

Output:

```text
Student name: Siti Rahma
Score 1: 85
Score 2: 90
Score 3: 78
Siti Rahma's average is 84.33
```

---

## Next Up - Lesson 7

In this lesson you translated `input()` into Java with `Scanner`, choosing `nextLine`, `nextInt`, or `nextDouble` based on the variable's type in the Dictionary. You wrote clear prompts, formatted output with `printf` specifiers for decimals, widths, and alignment, and learned to handle the leftover end of line after `nextInt`. Module 2 is complete: your programs can now store data, calculate with it, and talk to the user.

So far every program runs the same steps for every input. In Lesson 7 you will start Module 3 and teach your programs to make decisions. You will write `if ... then` and `if ... then ... else` in notation, implement them in Java, and solve problems such as checking whether a number is even or whether a student has passed.
