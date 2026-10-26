## 1. Before You Begin

Every program you have written so far is a pure **sequence**: it runs the same steps, in the same order, no matter what the user types. But think about the problems from Lesson 1. "Display PASS or FAIL" needs the program to choose. "Give a discount if the total is large enough" needs the program to sometimes do something and sometimes not. This is **selection**, the second of the three building blocks of every algorithm.

In this lesson you will write decisions in algorithmic notation with `if ... then ... endif` and `if ... then ... else ... endif`, and translate them into Java's `if` and `if-else` statements. You will reuse the relational and logical operators from Lesson 5 as conditions, and you will learn how to test a decision properly by checking values on both sides of a boundary.

### What You'll Build

A collection of interactive programs that make decisions: an absolute value calculator, a shopping discount checker, an even or odd checker, a program that finds the larger of two numbers, a pass or fail grader, and a museum ticket pricer.

### What You'll Learn

- ✅ How to write a one-way decision with `if ... then ... endif`
- ✅ How to write a two-way decision with `if ... then ... else ... endif`
- ✅ How these map to Java's `if` and `if-else` statements
- ✅ How blocks of code are grouped with curly braces
- ✅ How to use a `boolean` variable and logical operators as conditions
- ✅ How to choose test values around a boundary
- ✅ The most common `if` mistakes and how to avoid them

### What You'll Need

- Lessons 5 and 6 completed, so you can write conditions and read input
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-07
cd ~/java-basics/lesson-07
```

---

## 2. One-Way Decisions with If-Then

The simplest decision is "if something is true, do these steps; otherwise, skip them." In notation, it looks like this:

```text
if condition then
    steps to run when the condition is true
endif
```

The **condition** is any expression that produces a `boolean`, such as `number < 0` or `total >= 100000`. The steps between `then` and `endif` are indented to show that they belong to the decision. After `endif`, the algorithm continues with the next step, whether the condition was true or not.

In Java, the same structure is written as:

```java
if (condition) {
    // statements to run when the condition is true
}
```

The condition must be inside parentheses, and the statements that belong to the decision are grouped in curly braces `{ }`. A group of statements in braces is called a **block**. The closing brace plays the role of `endif`.

### Step 1: Calculate an Absolute Value

**Problem:** Read an integer and display its absolute value, the number without its minus sign. For example, the absolute value of -42 is 42, and the absolute value of 17 is 17.

The algorithm only needs to act when the number is negative:

```text
Program AbsoluteValue
{ Reads an integer and displays its absolute value }

Dictionary
    number : integer

Algorithm
    output("Enter an integer: ")
    input(number)
    if number < 0 then
        number <- -number
    endif
    output("Absolute value: ", number)
```

If the number is negative, `number <- -number` flips its sign, turning -42 into 42. If it is zero or positive, the assignment is skipped, and the number is already its own absolute value. Either way, the last `output` runs.

Create `AbsoluteValue.java`:

```java
import java.util.Scanner;

// Program AbsoluteValue
// Reads an integer and displays its absolute value.
public class AbsoluteValue {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int number;

        // Algorithm
        System.out.print("Enter an integer: ");
        number = input.nextInt();
        if (number < 0) {
            number = -number;
        }
        System.out.println("Absolute value: " + number);
    }
}
```

The `if` line holds the condition `number < 0` in parentheses. The block in braces contains the one statement that runs only for negative numbers. The `println` after the closing brace is outside the block, so it always runs. Indenting the block by four spaces is not required by Java, but it makes the structure visible, just as in notation.

```bash
javac AbsoluteValue.java
java AbsoluteValue
```

Run it twice, first with a negative number and then with a positive one.

Output:

```text
Enter an integer: -42
Absolute value: 42
```

Output:

```text
Enter an integer: 17
Absolute value: 17
```

For -42 the condition is true, so the sign is flipped. For 17 the condition is false, so the block is skipped.

### Step 2: Run Several Steps Under One Condition

A block can contain as many steps as you need. **Problem:** A shop gives a 10% discount when the shopping total is at least 100000. Display a message when the discount applies, then display the discount and the amount to pay.

```text
Program MemberDiscount
{ Gives a 10% discount when the shopping total is at least 100000 }

Dictionary
    constant DISCOUNT_RATE : real = 0.10
    total, discount : real

Algorithm
    output("Shopping total: ")
    input(total)
    discount <- 0
    if total >= 100000 then
        discount <- total * DISCOUNT_RATE
        output("You get a 10% discount!")
    endif
    output("Discount: ", discount)
    output("To pay  : ", total - discount)
```

Notice that `discount` is set to 0 *before* the decision. This gives it a correct value for customers who do not qualify. Without it, `discount` would have no value when the condition is false, and the last two outputs would have nothing to display.

Create `MemberDiscount.java`:

```java
import java.util.Scanner;

// Program MemberDiscount
// Gives a 10% discount when the shopping total is at least 100000.
public class MemberDiscount {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final double DISCOUNT_RATE = 0.10;
        double total;
        double discount;

        // Algorithm
        System.out.print("Shopping total: ");
        total = input.nextDouble();
        discount = 0;
        if (total >= 100000) {
            discount = total * DISCOUNT_RATE;
            System.out.println("You get a 10% discount!");
        }
        System.out.printf("Discount: %.2f%n", discount);
        System.out.printf("To pay  : %.2f%n", total - discount);
    }
}
```

Both statements inside the braces run together when the condition is true, and both are skipped when it is false. The `printf` lines after the block always run. Note that the `println` inside the block uses `10%` directly: only `printf` treats `%` as special.

```bash
javac MemberDiscount.java
java MemberDiscount
```

Output:

```text
Shopping total: 150000
You get a 10% discount!
Discount: 15000.00
To pay  : 135000.00
```

Run it again with a smaller total:

Output:

```text
Shopping total: 80000
Discount: 0.00
To pay  : 80000.00
```

---

## 3. Two-Way Decisions with If-Then-Else

Many decisions have two outcomes: one set of steps when the condition is true, and a *different* set when it is false. In notation:

```text
if condition then
    steps when the condition is true
else
    steps when the condition is false
endif
```

Exactly one of the two branches runs, never both and never neither. In Java:

```java
if (condition) {
    // statements when the condition is true
} else {
    // statements when the condition is false
}
```

### Step 1: Check Even or Odd

You designed this algorithm in Lesson 1 using plain English. Here it is in notation:

```text
Program EvenOrOdd
{ Reads an integer and displays whether it is even or odd }

Dictionary
    number : integer

Algorithm
    output("Enter an integer: ")
    input(number)
    if number mod 2 = 0 then
        output(number, " is EVEN")
    else
        output(number, " is ODD")
    endif
```

Create `EvenOrOdd.java`:

```java
import java.util.Scanner;

// Program EvenOrOdd
// Reads an integer and displays whether it is even or odd.
public class EvenOrOdd {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int number;

        // Algorithm
        System.out.print("Enter an integer: ");
        number = input.nextInt();
        if (number % 2 == 0) {
            System.out.println(number + " is EVEN");
        } else {
            System.out.println(number + " is ODD");
        }
    }
}
```

The translation follows the patterns from Lesson 5: `mod` becomes `%`, and the notation's equality `=` becomes `==`. The `else` keyword sits between the two blocks: `} else {`.

```bash
javac EvenOrOdd.java
java EvenOrOdd
```

Output:

```text
Enter an integer: 14
14 is EVEN
```

Output:

```text
Enter an integer: 7
7 is ODD
```

### Step 2: Choose a Value in Each Branch

A decision does not have to display anything directly. Often each branch assigns a value to a variable, and the program uses that variable afterward. **Problem:** Read two integers and display the larger one.

```text
Program LargerOfTwo
{ Reads two integers and displays the larger one }

Dictionary
    a, b, larger : integer

Algorithm
    output("First number : ")
    input(a)
    output("Second number: ")
    input(b)
    if a > b then
        larger <- a
    else
        larger <- b
    endif
    output("The larger number is ", larger)
```

Create `LargerOfTwo.java`:

```java
import java.util.Scanner;

// Program LargerOfTwo
// Reads two integers and displays the larger one.
public class LargerOfTwo {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int a;
        int b;
        int larger;

        // Algorithm
        System.out.print("First number : ");
        a = input.nextInt();
        System.out.print("Second number: ");
        b = input.nextInt();
        if (a > b) {
            larger = a;
        } else {
            larger = b;
        }
        System.out.println("The larger number is " + larger);
    }
}
```

Both branches give `larger` a value, so after the decision `larger` is guaranteed to hold something. Java checks this: if one branch forgot to assign `larger`, the compiler would report "variable larger might not have been initialized," just like in Lesson 4. Separating the decision from the output keeps the program tidy, because the output line is written only once.

```bash
javac LargerOfTwo.java
java LargerOfTwo
```

Output:

```text
First number : 8
Second number: 12
The larger number is 12
```

What happens when both numbers are equal? `a > b` is false, so `larger` gets `b`, which has the same value. The answer is still correct.

### Step 3: Use a Boolean Variable and Logical Operators

A condition can be any boolean expression, including a `boolean` variable or a combination built with `and`, `or`, and `not`. **Problem:** A museum charges 15000 for children under 12 and seniors aged 60 or older, and 30000 for everyone else.

```text
Program MuseumTicket
{ Decides the ticket price: children and seniors pay less }

Dictionary
    age, price : integer

Algorithm
    output("Visitor age: ")
    input(age)
    if age < 12 or age >= 60 then
        price <- 15000
    else
        price <- 30000
    endif
    output("Ticket price: ", price)
```

Create `MuseumTicket.java`:

```java
import java.util.Scanner;

// Program MuseumTicket
// Decides the ticket price: children and seniors pay less.
public class MuseumTicket {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int age;
        int price;

        // Algorithm
        System.out.print("Visitor age: ");
        age = input.nextInt();
        if (age < 12 || age >= 60) {
            price = 15000;
        } else {
            price = 30000;
        }
        System.out.println("Ticket price: " + price);
    }
}
```

`or` becomes `||`. The discounted price applies if *either* condition is true. Everyone else falls into the `else` branch.

```bash
javac MuseumTicket.java
java MuseumTicket
```

Run it three times with a child, an adult, and a senior.

Output:

```text
Visitor age: 8
Ticket price: 15000
```

Output:

```text
Visitor age: 35
Ticket price: 30000
```

Output:

```text
Visitor age: 65
Ticket price: 15000
```

---

## 4. Run and Test

The pass or fail problem from Lesson 1 brings everything together: a constant, a boolean variable used as a condition, and several steps in each branch.

```text
Program PassOrFail
{ Displays PASS if the score is at least 75, otherwise FAIL }

Dictionary
    constant PASSING_SCORE : integer = 75
    score    : integer
    isPassed : boolean

Algorithm
    output("Score: ")
    input(score)
    isPassed <- score >= PASSING_SCORE
    if isPassed then
        output("PASS")
        output("Congratulations!")
    else
        output("FAIL")
        output("Points needed to pass: ", PASSING_SCORE - score)
    endif
```

Storing the comparison in `isPassed` first makes the `if` line read like plain English: "if is passed then." Since `isPassed` is already a boolean, there is no need to write `isPassed = true`.

Create `PassOrFail.java`:

```java
import java.util.Scanner;

// Program PassOrFail
// Displays PASS if the score is at least 75, otherwise FAIL.
public class PassOrFail {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int PASSING_SCORE = 75;
        int score;
        boolean isPassed;

        // Algorithm
        System.out.print("Score: ");
        score = input.nextInt();
        isPassed = score >= PASSING_SCORE;
        if (isPassed) {
            System.out.println("PASS");
            System.out.println("Congratulations!");
        } else {
            System.out.println("FAIL");
            System.out.println("Points needed to pass: " + (PASSING_SCORE - score));
        }
    }
}
```

```bash
javac PassOrFail.java
```

Now test it properly. In Lesson 1 you learned that the boundary is where mistakes hide, so choose values on both sides of 75 as well as values clearly inside each range:

| Test | score | Expected |
| --- | --- | --- |
| 1 | 90 | PASS |
| 2 | 60 | FAIL, 15 points needed |
| 3 | 75 | PASS (exactly on the boundary) |
| 4 | 74 | FAIL, 1 point needed (just below the boundary) |

Run `java PassOrFail` four times, once for each test value.

Output:

```text
Score: 90
PASS
Congratulations!
```

Output:

```text
Score: 60
FAIL
Points needed to pass: 15
```

Output:

```text
Score: 75
PASS
Congratulations!
```

Output:

```text
Score: 74
FAIL
Points needed to pass: 1
```

All four results match the table. Tests 3 and 4 are the important ones: if you had accidentally written `score > PASSING_SCORE` instead of `>=`, tests 1 and 2 would still pass, but a score of exactly 75 would fail. Only a boundary test catches that bug.

---

## 5. Fix the Errors in Your Code

Some `if` mistakes stop the compiler, but the most dangerous ones compile without complaint and silently run the wrong steps.

**Error 1: A semicolon after the condition.**

```java
// Wrong
import java.util.Scanner;

public class Warning {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        System.out.print("Score: ");
        int score = input.nextInt();
        if (score < 75); {
            System.out.println("Warning: score below passing grade.");
        }
        System.out.println("Score recorded: " + score);
    }
}

// Correct
import java.util.Scanner;

public class Warning {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        System.out.print("Score: ");
        int score = input.nextInt();
        if (score < 75) {
            System.out.println("Warning: score below passing grade.");
        }
        System.out.println("Score recorded: " + score);
    }
}
```

The wrong version compiles, but even a score of 90 triggers the warning:

```text
Score: 90
Warning: score below passing grade.
Score recorded: 90
```

The semicolon right after `if (score < 75)` ends the `if` statement with an empty step. The block in braces is no longer connected to the `if`, so it always runs. Never put a semicolon between the condition and the opening brace.

**Error 2: Missing braces around several statements.**

```java
// Wrong
import java.util.Scanner;

public class Braces {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        System.out.print("Items in stock: ");
        int stock = input.nextInt();
        if (stock == 0)
            System.out.println("Out of stock.");
            System.out.println("Please order more.");
        System.out.println("Stock: " + stock);
    }
}

// Correct
import java.util.Scanner;

public class Braces {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        System.out.print("Items in stock: ");
        int stock = input.nextInt();
        if (stock == 0) {
            System.out.println("Out of stock.");
            System.out.println("Please order more.");
        }
        System.out.println("Stock: " + stock);
    }
}
```

The wrong version compiles. With 25 items in stock, it still says to order more:

```text
Items in stock: 25
Please order more.
Stock: 25
```

Without braces, an `if` controls only the *one* statement right after it. The indentation suggests that both messages belong to the `if`, but Java ignores indentation. Always use braces, even when a block has only one statement; it prevents this bug when you add a second line later.

**Error 3: Forgetting the parentheses around the condition, or misplacing `else`.**

```java
// Wrong
public class NoParens {
    public static void main(String[] args) {
        int number = 7;
        if number > 0 {
            System.out.println("Positive");
        }
    }
}

// Correct
public class NoParens {
    public static void main(String[] args) {
        int number = 7;
        if (number > 0) {
            System.out.println("Positive");
        }
    }
}
```

The wrong version produces:

```text
NoParens.java:4: error: '(' expected
        if number > 0 {
          ^
NoParens.java:4: error: ')' expected
        if number > 0 {
                     ^
2 errors
```

Notation does not use parentheses around conditions, but Java requires them. A related error appears when another statement sits between the `if` block and the `else`:

```java
// Wrong
public class ElseSemi {
    public static void main(String[] args) {
        int number = 7;
        if (number % 2 == 0) {
            System.out.println("EVEN");
        }
        System.out.println("checked");
        else {
            System.out.println("ODD");
        }
    }
}
```

Compiling it produces:

```text
ElseSemi.java:8: error: 'else' without 'if'
        else {
        ^
1 error
```

`else` must come immediately after the closing brace of the `if` block. Move the extra statement before the `if` or after the whole `if-else`.

---

## 6. Exercises

**Exercise 1:** A theme park charges 25000 for children under 12 and 50000 for everyone else. Write the notation and the Java program `TicketPrice` that reads an age and displays the ticket price. Test it with 9 and with the boundary value 12.

**Exercise 2:** Write the notation and the Java program `DivisibleByThree` that reads an integer and displays whether it is divisible by 3. If it is not, also display the remainder.

**Exercise 3:** An online shop charges a shipping fee of 15000, but shipping is free for orders of at least 200000. Write the notation and the Java program `ShippingCost` that reads the order total and displays the shipping cost and the grand total. If shipping is not free, also tell the customer how much more they need to spend to get free shipping.

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program TicketPrice
{ Children under 12 pay 25000; everyone else pays 50000 }

Dictionary
    age, price : integer

Algorithm
    output("Age: ")
    input(age)
    if age < 12 then
        price <- 25000
    else
        price <- 50000
    endif
    output("Ticket price: ", price)
```

```java
import java.util.Scanner;

// Program TicketPrice
// Children under 12 pay 25000; everyone else pays 50000.
public class TicketPrice {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int age;
        int price;

        // Algorithm
        System.out.print("Age: ");
        age = input.nextInt();
        if (age < 12) {
            price = 25000;
        } else {
            price = 50000;
        }
        System.out.println("Ticket price: " + price);
    }
}
```

"Under 12" means 11 or younger, so the condition is `age < 12`. A 12 year old pays the full price, which the boundary test confirms.

```bash
javac TicketPrice.java
java TicketPrice
```

Output:

```text
Age: 9
Ticket price: 25000
```

Output:

```text
Age: 12
Ticket price: 50000
```

**Solution for Exercise 2:**

```text
Program DivisibleByThree
{ Displays whether an integer is divisible by 3 }

Dictionary
    number : integer

Algorithm
    output("Enter an integer: ")
    input(number)
    if number mod 3 = 0 then
        output(number, " is divisible by 3")
    else
        output(number, " is not divisible by 3, remainder ", number mod 3)
    endif
```

```java
import java.util.Scanner;

// Program DivisibleByThree
// Displays whether an integer is divisible by 3.
public class DivisibleByThree {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int number;

        // Algorithm
        System.out.print("Enter an integer: ");
        number = input.nextInt();
        if (number % 3 == 0) {
            System.out.println(number + " is divisible by 3");
        } else {
            System.out.println(number + " is not divisible by 3, remainder " + (number % 3));
        }
    }
}
```

This is the even or odd pattern with 3 instead of 2. The remainder is calculated again inside the `else` branch, wrapped in parentheses so it is calculated before being joined to the text.

```bash
javac DivisibleByThree.java
java DivisibleByThree
```

Output:

```text
Enter an integer: 27
27 is divisible by 3
```

Output:

```text
Enter an integer: 20
20 is not divisible by 3, remainder 2
```

**Solution for Exercise 3:**

```text
Program ShippingCost
{ Adds a shipping cost of 15000 unless the order is at least 200000 }

Dictionary
    constant FREE_SHIPPING_MINIMUM : integer = 200000
    constant SHIPPING_FEE          : integer = 15000
    orderTotal, shipping : integer

Algorithm
    output("Order total: ")
    input(orderTotal)
    if orderTotal >= FREE_SHIPPING_MINIMUM then
        shipping <- 0
        output("Free shipping!")
    else
        shipping <- SHIPPING_FEE
        output("Spend ", FREE_SHIPPING_MINIMUM - orderTotal, " more for free shipping.")
    endif
    output("Shipping   : ", shipping)
    output("Grand total: ", orderTotal + shipping)
```

```java
import java.util.Scanner;

// Program ShippingCost
// Adds a shipping cost of 15000 unless the order is at least 200000.
public class ShippingCost {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        final int FREE_SHIPPING_MINIMUM = 200000;
        final int SHIPPING_FEE = 15000;
        int orderTotal;
        int shipping;

        // Algorithm
        System.out.print("Order total: ");
        orderTotal = input.nextInt();
        if (orderTotal >= FREE_SHIPPING_MINIMUM) {
            shipping = 0;
            System.out.println("Free shipping!");
        } else {
            shipping = SHIPPING_FEE;
            System.out.println("Spend " + (FREE_SHIPPING_MINIMUM - orderTotal) + " more for free shipping.");
        }
        System.out.println("Shipping   : " + shipping);
        System.out.println("Grand total: " + (orderTotal + shipping));
    }
}
```

Each branch does two things: it sets `shipping` and displays a message. The grand total is calculated once, after the decision, using whichever shipping value was chosen. Constants keep the rule easy to change if the shop updates its policy.

```bash
javac ShippingCost.java
java ShippingCost
```

Output:

```text
Order total: 250000
Free shipping!
Shipping   : 0
Grand total: 250000
```

Output:

```text
Order total: 185000
Spend 15000 more for free shipping.
Shipping   : 15000
Grand total: 200000
```

---

## Next Up - Lesson 8

In this lesson you added selection to your toolbox. You wrote one-way decisions with `if ... then ... endif` and two-way decisions with `if ... then ... else ... endif`, translated them into Java's `if` and `if-else` with conditions in parentheses and blocks in braces, and used boolean variables and logical operators as conditions. You also learned to test decisions with values on both sides of a boundary.

Two branches are not always enough. A grading system has five letter grades, and a menu might have four options. In Lesson 8 you will handle more than two outcomes with nested conditions, chains of `else if`, and the `depend on` notation, then implement them in Java with `if-else` chains and the `switch` statement.
