## 1. Before You Begin

In Lesson 7 you wrote decisions with one or two outcomes. Many real problems have more. A number can be positive, negative, or zero. A score can earn an A, B, C, D, or E. A calculator has to handle four different operators. You could try to squeeze these into a single `if-else`, but you would quickly run out of branches.

This lesson shows three ways to handle many outcomes. **Nested conditions** put one decision inside another. **Else-if chains** test conditions one after another until one is true. The **`depend on`** notation picks a branch based on the value of a single variable, and in Java it becomes the `switch` statement. Knowing which tool fits which problem is a big part of writing clear algorithms.

### What You'll Build

A number sign checker, a letter grade converter, a program that finds the largest of three numbers, a day name lookup, a days-in-month table, and a four-operation calculator that refuses to divide by zero.

### What You'll Learn

- ✅ How to place a decision inside another decision (nesting)
- ✅ How to write an else-if chain in notation and Java
- ✅ Why the order of conditions in an else-if chain matters
- ✅ How to write multiple cases with `depend on ... enddepend`
- ✅ How to implement `depend on` with Java's `switch` and arrow cases (`->`)
- ✅ How to use a `switch` expression to choose a value
- ✅ How to read several values typed on one line, and a single character

### What You'll Need

- Lesson 7 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-08
cd ~/java-basics/lesson-08
```

---

## 2. Nested Conditions

A **nested condition** is a decision placed inside a branch of another decision. The inner decision only runs when the outer branch that contains it runs. Nesting is the natural tool when one question only makes sense after another has been answered.

### Step 1: Positive, Negative, or Zero

**Problem:** Read an integer and display whether it is positive, negative, or zero.

There are three outcomes, but each `if-else` only has two. The solution is to answer one question at a time. First ask "is it greater than zero?" If not, the number is either negative or zero, so ask a second question inside the `else` branch:

```text
Program NumberSign
{ Displays whether a number is positive, negative, or zero using a nested if }

Dictionary
    number : integer

Algorithm
    output("Enter an integer: ")
    input(number)
    if number > 0 then
        output("POSITIVE")
    else
        if number < 0 then
            output("NEGATIVE")
        else
            output("ZERO")
        endif
    endif
```

Each `if` has its own `endif`, and the inner decision is indented one more level, so you can see exactly which `else` belongs to which `if`.

Create `NumberSign.java`:

```java
import java.util.Scanner;

// Program NumberSign
// Displays whether a number is positive, negative, or zero using a nested if.
public class NumberSign {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int number;

        // Algorithm
        System.out.print("Enter an integer: ");
        number = input.nextInt();
        if (number > 0) {
            System.out.println("POSITIVE");
        } else {
            if (number < 0) {
                System.out.println("NEGATIVE");
            } else {
                System.out.println("ZERO");
            }
        }
    }
}
```

The inner `if-else` sits entirely inside the outer `else` block. Matching braces play the role of the two `endif` keywords. When `number` is 5, the outer condition is true and the inner decision never runs.

```bash
javac NumberSign.java
java NumberSign
```

Run it three times, once for each outcome.

Output:

```text
Enter an integer: 5
POSITIVE
```

Output:

```text
Enter an integer: -3
NEGATIVE
```

Output:

```text
Enter an integer: 0
ZERO
```

### Step 2: The Largest of Three Numbers

Nesting can also happen in *both* branches. **Problem:** Read three integers and display the largest.

Compare `a` with `b` first. If `a` is at least as big as `b`, then the answer is either `a` or `c`, so compare those two. Otherwise, the answer is either `b` or `c`:

```text
Program LargestOfThree
{ Reads three integers and displays the largest one }

Dictionary
    a, b, c, largest : integer

Algorithm
    output("Enter three integers: ")
    input(a, b, c)
    if a >= b then
        if a >= c then
            largest <- a
        else
            largest <- c
        endif
    else
        if b >= c then
            largest <- b
        else
            largest <- c
        endif
    endif
    output("Largest: ", largest)
```

`input(a, b, c)` reads three values in one step. Using `>=` instead of `>` makes the algorithm handle equal values correctly.

Create `LargestOfThree.java`:

```java
import java.util.Scanner;

// Program LargestOfThree
// Reads three integers and displays the largest one.
public class LargestOfThree {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int a;
        int b;
        int c;
        int largest;

        // Algorithm
        System.out.print("Enter three integers: ");
        a = input.nextInt();
        b = input.nextInt();
        c = input.nextInt();
        if (a >= b) {
            if (a >= c) {
                largest = a;
            } else {
                largest = c;
            }
        } else {
            if (b >= c) {
                largest = b;
            } else {
                largest = c;
            }
        }
        System.out.println("Largest: " + largest);
    }
}
```

`input(a, b, c)` becomes three `nextInt` calls. `Scanner` splits the input at spaces, so the user can type all three numbers on one line separated by spaces, or on three separate lines; both work. Every path through the nested decisions assigns `largest`, so the compiler is satisfied that it has a value at the end.

```bash
javac LargestOfThree.java
java LargestOfThree
```

Output:

```text
Enter three integers: 4 9 2
Largest: 9
```

Output:

```text
Enter three integers: 3 3 1
Largest: 3
```

Output:

```text
Enter three integers: 1 5 8
Largest: 8
```

The three tests put the largest value in each of the three positions, plus a tie, so every path through the decisions is exercised.

---

## 3. Else-If Chains

Nesting works, but with five or six outcomes the indentation grows deeper and deeper. When each outcome is decided by testing conditions *in order*, an **else-if chain** is much easier to read. The algorithm tests the first condition; if it is false, it tests the second; and so on. The first true condition wins, and its branch runs. If none is true, the final `else` runs.

```text
if condition1 then
    steps 1
else if condition2 then
    steps 2
else if condition3 then
    steps 3
else
    steps when no condition is true
endif
```

An else-if chain is really a nested condition written in a flatter style: each `else if` is an `if` placed inside the previous `else`. Only one `endif` is needed at the end.

### Step 1: Convert a Score into a Letter Grade

**Problem:** Convert a score from 0 to 100 into a letter grade: A for 85 and above, B for 70 to 84, C for 55 to 69, D for 40 to 54, and E below 40. Scores outside 0 to 100 are invalid.

```text
Program LetterGrade
{ Converts a score from 0 to 100 into a letter grade }

Dictionary
    score : integer
    grade : character

Algorithm
    output("Score (0-100): ")
    input(score)
    if score < 0 or score > 100 then
        output("Invalid score.")
    else
        if score >= 85 then
            grade <- 'A'
        else if score >= 70 then
            grade <- 'B'
        else if score >= 55 then
            grade <- 'C'
        else if score >= 40 then
            grade <- 'D'
        else
            grade <- 'E'
        endif
        output("Grade: ", grade)
    endif
```

Look at the second condition: it is just `score >= 70`, not `score >= 70 and score < 85`. The upper limit is not needed, because the chain only reaches `score >= 70` when `score >= 85` was already false. Each condition can rely on the fact that all the conditions above it failed. The whole chain is nested inside a validation check, so invalid scores never get a grade.

Create `LetterGrade.java`:

```java
import java.util.Scanner;

// Program LetterGrade
// Converts a score from 0 to 100 into a letter grade.
public class LetterGrade {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int score;
        char grade;

        // Algorithm
        System.out.print("Score (0-100): ");
        score = input.nextInt();
        if (score < 0 || score > 100) {
            System.out.println("Invalid score.");
        } else {
            if (score >= 85) {
                grade = 'A';
            } else if (score >= 70) {
                grade = 'B';
            } else if (score >= 55) {
                grade = 'C';
            } else if (score >= 40) {
                grade = 'D';
            } else {
                grade = 'E';
            }
            System.out.println("Grade: " + grade);
        }
    }
}
```

In Java, each `else if` is written `} else if (condition) {`. The structure is a direct copy of the notation. The grade is a `char`, so each letter is written in single quotes.

```bash
javac LetterGrade.java
```

Good test values for a chain include one value inside each range, plus both sides of at least one boundary. Run `java LetterGrade` with 92, 85, 84, 70, 60, 45, 20, and 105:

Output:

```text
Score (0-100): 92
Grade: A
Score (0-100): 85
Grade: A
Score (0-100): 84
Grade: B
Score (0-100): 70
Grade: B
Score (0-100): 60
Grade: C
Score (0-100): 45
Grade: D
Score (0-100): 20
Grade: E
Score (0-100): 105
Invalid score.
```

Every grade appears, the boundaries 85 and 84 land on different sides, and the out-of-range value is rejected.

---

## 4. Multiple Cases with Depend On and Switch

Sometimes the decision is not about ranges but about exact values of a single variable: day 1 is Monday, day 2 is Tuesday, and so on. You could write this as an else-if chain with `day = 1`, `day = 2`, and so on, but notation has a clearer structure for it, **`depend on`**:

```text
depend on (variable)
    value1 : steps for value1
    value2 : steps for value2
    value3, value4 : steps for either value
    otherwise : steps when no value matches
enddepend
```

The algorithm looks at the variable once and jumps to the case that matches its value. Several values can share one case, separated by commas. `otherwise` handles every value that is not listed.

Java's version is the **`switch`** statement. Since Java 14, `switch` supports a clean arrow form that matches `depend on` almost exactly:

```java
switch (variable) {
    case value1 -> statement;
    case value2 -> statement;
    case value3, value4 -> statement;
    default -> statement;
}
```

`default` is Java's `otherwise`. If a case needs more than one statement, put them in braces after the arrow.

### Step 1: Look Up a Day Name

```text
Program DayName
{ Reads a day number from 1 to 7 and displays the day's name }

Dictionary
    day : integer

Algorithm
    output("Day number (1-7): ")
    input(day)
    depend on (day)
        1 : output("Monday")
        2 : output("Tuesday")
        3 : output("Wednesday")
        4 : output("Thursday")
        5 : output("Friday")
        6 : output("Saturday")
        7 : output("Sunday")
        otherwise : output("Invalid day number.")
    enddepend
```

Create `DayName.java`:

```java
import java.util.Scanner;

// Program DayName
// Reads a day number from 1 to 7 and displays the day's name.
public class DayName {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int day;

        // Algorithm
        System.out.print("Day number (1-7): ");
        day = input.nextInt();
        switch (day) {
            case 1 -> System.out.println("Monday");
            case 2 -> System.out.println("Tuesday");
            case 3 -> System.out.println("Wednesday");
            case 4 -> System.out.println("Thursday");
            case 5 -> System.out.println("Friday");
            case 6 -> System.out.println("Saturday");
            case 7 -> System.out.println("Sunday");
            default -> System.out.println("Invalid day number.");
        }
    }
}
```

`switch (day)` evaluates `day` once. Java then runs only the statement after the matching `case`, and `default` catches anything else. Compared with seven `else if` lines, this is easier to read and makes it obvious that every branch is about the same variable.

```bash
javac DayName.java
java DayName
```

Output:

```text
Day number (1-7): 3
Wednesday
```

Output:

```text
Day number (1-7): 7
Sunday
```

Output:

```text
Day number (1-7): 9
Invalid day number.
```

### Step 2: Choose a Value with a Switch Expression

Often each case simply produces a value. **Problem:** Read a month number and display how many days it has in a non-leap year.

```text
Program DaysInMonth
{ Reads a month number and displays how many days it has in a non-leap year }

Dictionary
    month, days : integer

Algorithm
    output("Month (1-12): ")
    input(month)
    depend on (month)
        1, 3, 5, 7, 8, 10, 12 : days <- 31
        4, 6, 9, 11 : days <- 30
        2 : days <- 28
        otherwise : days <- 0
    enddepend
    if days = 0 then
        output("Invalid month.")
    else
        output("Month ", month, " has ", days, " days.")
    endif
```

Several months share each case, which keeps the algorithm short. The value 0 marks an invalid month, and the decision afterward checks for it.

In Java, when every case assigns the same variable, you can write the `switch` as an **expression** that produces a value directly. Create `DaysInMonth.java`:

```java
import java.util.Scanner;

// Program DaysInMonth
// Reads a month number and displays how many days it has in a non-leap year.
public class DaysInMonth {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int month;
        int days;

        // Algorithm
        System.out.print("Month (1-12): ");
        month = input.nextInt();
        days = switch (month) {
            case 1, 3, 5, 7, 8, 10, 12 -> 31;
            case 4, 6, 9, 11 -> 30;
            case 2 -> 28;
            default -> 0;
        };
        if (days == 0) {
            System.out.println("Invalid month.");
        } else {
            System.out.println("Month " + month + " has " + days + " days.");
        }
    }
}
```

`days = switch (month) { ... };` means "set `days` to whatever value the matching case produces." Each case gives a value after its arrow instead of a statement. Because it is an expression assigned to a variable, the whole `switch` ends with a semicolon after the closing brace. Java requires a switch expression to produce a value for *every* possible input, so `default` is mandatory here.

```bash
javac DaysInMonth.java
java DaysInMonth
```

Output:

```text
Month (1-12): 2
Month 2 has 28 days.
```

Output:

```text
Month (1-12): 4
Month 4 has 30 days.
```

Output:

```text
Month (1-12): 12
Month 12 has 31 days.
```

Output:

```text
Month (1-12): 13
Invalid month.
```

---

## 5. Run and Test

A calculator combines `depend on` with a nested decision. **Problem:** Read two numbers and an operator (`+`, `-`, `*`, or `/`), then display the result. Division by zero must be refused, and an unknown operator must be reported.

```text
Program SimpleCalculator
{ Reads two numbers and an operator, then displays the result }

Dictionary
    a, b     : real
    operator : character

Algorithm
    output("First number : ")
    input(a)
    output("Operator (+ - * /): ")
    input(operator)
    output("Second number: ")
    input(b)
    depend on (operator)
        '+' : output("Result: ", a + b)
        '-' : output("Result: ", a - b)
        '*' : output("Result: ", a * b)
        '/' : if b = 0 then
                  output("Error: division by zero.")
              else
                  output("Result: ", a / b)
              endif
        otherwise : output("Unknown operator: ", operator)
    enddepend
```

The `'/'` case contains a whole `if-else`. Any steps can go inside a case, including another decision.

Create `SimpleCalculator.java`:

```java
import java.util.Scanner;

// Program SimpleCalculator
// Reads two numbers and an operator, then displays the result.
public class SimpleCalculator {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        double a;
        double b;
        char operator;

        // Algorithm
        System.out.print("First number : ");
        a = input.nextDouble();
        System.out.print("Operator (+ - * /): ");
        operator = input.next().charAt(0);
        System.out.print("Second number: ");
        b = input.nextDouble();
        switch (operator) {
            case '+' -> System.out.println("Result: " + (a + b));
            case '-' -> System.out.println("Result: " + (a - b));
            case '*' -> System.out.println("Result: " + (a * b));
            case '/' -> {
                if (b == 0) {
                    System.out.println("Error: division by zero.");
                } else {
                    System.out.println("Result: " + (a / b));
                }
            }
            default -> System.out.println("Unknown operator: " + operator);
        }
    }
}
```

`Scanner` has no method to read a single character, so `input.next().charAt(0)` reads the next word the user types and takes its first character. (You will learn more about `charAt` in Lesson 17.) `switch` works with `char` values, and each case label is a character in single quotes. The `'/'` case has more than one line, so its statements are wrapped in braces.

```bash
javac SimpleCalculator.java
```

Test every operator, division by zero, and an unknown operator. Run `java SimpleCalculator` once for each test:

Output:

```text
First number : 12
Operator (+ - * /): +
Second number: 30
Result: 42.0
```

Output:

```text
First number : 12
Operator (+ - * /): -
Second number: 30
Result: -18.0
```

Output:

```text
First number : 6
Operator (+ - * /): *
Second number: 7
Result: 42.0
```

Output:

```text
First number : 10
Operator (+ - * /): /
Second number: 4
Result: 2.5
```

Output:

```text
First number : 10
Operator (+ - * /): /
Second number: 0
Error: division by zero.
```

Output:

```text
First number : 5
Operator (+ - * /): %
Second number: 2
Unknown operator: %
```

Every branch of the algorithm has been run at least once. That is the goal of testing a program with many cases: make sure no branch is left untested.

---

## 6. Fix the Errors in Your Code

**Error 1: Conditions in the wrong order in an else-if chain.**

```java
// Wrong
public class GradeOrder {
    public static void main(String[] args) {
        int score = 92;
        char grade;
        if (score >= 55) {
            grade = 'C';
        } else if (score >= 70) {
            grade = 'B';
        } else if (score >= 85) {
            grade = 'A';
        } else {
            grade = 'D';
        }
        System.out.println("Grade: " + grade);
    }
}

// Correct
public class GradeOrder {
    public static void main(String[] args) {
        int score = 92;
        char grade;
        if (score >= 85) {
            grade = 'A';
        } else if (score >= 70) {
            grade = 'B';
        } else if (score >= 55) {
            grade = 'C';
        } else {
            grade = 'D';
        }
        System.out.println("Grade: " + grade);
    }
}
```

The wrong version compiles and displays:

```text
Grade: C
```

A score of 92 is greater than or equal to 55, so the very first condition is true and the chain stops there. The B and A branches can never run. When conditions overlap, put the most restrictive one first: for "at least" conditions, start with the highest limit.

**Error 2: A switch expression without `default`.**

```java
// Wrong
public class MonthDays {
    public static void main(String[] args) {
        int month = 4;
        int days = switch (month) {
            case 1, 3, 5, 7, 8, 10, 12 -> 31;
            case 4, 6, 9, 11 -> 30;
            case 2 -> 28;
        };
        System.out.println(days);
    }
}

// Correct
public class MonthDays {
    public static void main(String[] args) {
        int month = 4;
        int days = switch (month) {
            case 1, 3, 5, 7, 8, 10, 12 -> 31;
            case 4, 6, 9, 11 -> 30;
            case 2 -> 28;
            default -> 0;
        };
        System.out.println(days);
    }
}
```

The wrong version produces:

```text
MonthDays.java:4: error: the switch expression does not cover all possible input values
        int days = switch (month) {
                   ^
1 error
```

An `int` can hold far more values than 1 to 12. If `month` were 13, the switch expression would have no value to give `days`, so Java refuses to compile it. Add a `default` case, just as a good `depend on` has an `otherwise`.

**Error 3: The old switch style without `break`.**

You will see an older form of `switch` in many books and websites. It uses a colon after each case instead of an arrow. In that form, Java keeps running into the next case unless you stop it with `break`.

```java
// Wrong
public class OldSwitch {
    public static void main(String[] args) {
        int day = 6;
        switch (day) {
            case 6:
                System.out.println("Saturday");
            case 7:
                System.out.println("Sunday");
            default:
                System.out.println("Weekday");
        }
    }
}

// Correct
public class OldSwitch {
    public static void main(String[] args) {
        int day = 6;
        switch (day) {
            case 6:
                System.out.println("Saturday");
                break;
            case 7:
                System.out.println("Sunday");
                break;
            default:
                System.out.println("Weekday");
        }
    }
}
```

The wrong version compiles, but for day 6 it displays all three lines:

```text
Saturday
Sunday
Weekday
```

With `break` added, it displays only:

```text
Saturday
```

This behavior is called **fall-through**, and forgetting `break` is a classic bug. The arrow form (`case 6 ->`) used in this course never falls through, which is why it is the better choice for new code.

---

## 7. Exercises

**Exercise 1:** Write the notation and the Java program `BmiCategory` that reads a BMI value and displays its category: Underweight below 18.5, Normal from 18.5 up to but not including 25, Overweight from 25 up to but not including 30, and Obese from 30 upward. Use an else-if chain.

**Exercise 2:** Write the notation and the Java program `TriangleType` that reads three side lengths and displays whether the triangle is equilateral (all sides equal), isosceles (exactly two sides equal), or scalene (no sides equal). First check that the sides can form a triangle: the sum of any two sides must be greater than the third side.

**Exercise 3:** Write the notation and the Java program `DrinkMenu` that displays a menu (1. Coffee 15000, 2. Tea 10000, 3. Juice 18000), reads the customer's choice, and uses `depend on` / `switch` to set the drink name and price. If the choice is valid, read the quantity and display the total; otherwise display "Invalid choice."

---

## 8. Solutions

**Solution for Exercise 1:**

```text
Program BmiCategory
{ Reads a BMI value and displays its category }

Dictionary
    bmi      : real
    category : string

Algorithm
    output("BMI: ")
    input(bmi)
    if bmi < 18.5 then
        category <- "Underweight"
    else if bmi < 25.0 then
        category <- "Normal"
    else if bmi < 30.0 then
        category <- "Overweight"
    else
        category <- "Obese"
    endif
    output("Category: ", category)
```

```java
import java.util.Scanner;

// Program BmiCategory
// Reads a BMI value and displays its category.
public class BmiCategory {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        double bmi;
        String category;

        // Algorithm
        System.out.print("BMI: ");
        bmi = input.nextDouble();
        if (bmi < 18.5) {
            category = "Underweight";
        } else if (bmi < 25.0) {
            category = "Normal";
        } else if (bmi < 30.0) {
            category = "Overweight";
        } else {
            category = "Obese";
        }
        System.out.println("Category: " + category);
    }
}
```

This chain uses "less than" conditions, so it starts from the *lowest* limit, the mirror image of the grade chain. Each later condition can skip the lower limit because the earlier ones already failed. The test value 25 checks the boundary between Normal and Overweight.

```bash
javac BmiCategory.java
java BmiCategory
```

Output:

```text
BMI: 17.2
Category: Underweight
```

Output:

```text
BMI: 22.5
Category: Normal
```

Output:

```text
BMI: 25
Category: Overweight
```

Output:

```text
BMI: 31.8
Category: Obese
```

**Solution for Exercise 2:**

```text
Program TriangleType
{ Reads three side lengths and displays the type of triangle }

Dictionary
    a, b, c : integer

Algorithm
    output("Three side lengths: ")
    input(a, b, c)
    if a + b <= c or a + c <= b or b + c <= a then
        output("Not a valid triangle.")
    else
        if a = b and b = c then
            output("Equilateral triangle")
        else if a = b or b = c or a = c then
            output("Isosceles triangle")
        else
            output("Scalene triangle")
        endif
    endif
```

```java
import java.util.Scanner;

// Program TriangleType
// Reads three side lengths and displays the type of triangle.
public class TriangleType {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int a;
        int b;
        int c;

        // Algorithm
        System.out.print("Three side lengths: ");
        a = input.nextInt();
        b = input.nextInt();
        c = input.nextInt();
        if (a + b <= c || a + c <= b || b + c <= a) {
            System.out.println("Not a valid triangle.");
        } else {
            if (a == b && b == c) {
                System.out.println("Equilateral triangle");
            } else if (a == b || b == c || a == c) {
                System.out.println("Isosceles triangle");
            } else {
                System.out.println("Scalene triangle");
            }
        }
    }
}
```

The validity check runs first, and the classification is nested inside its `else`, so invalid sides are never classified. Inside, the equilateral test must come before the isosceles test: three equal sides also satisfy "two sides are equal," so the order of the chain decides which answer wins.

```bash
javac TriangleType.java
java TriangleType
```

Output:

```text
Three side lengths: 5 5 5
Equilateral triangle
```

Output:

```text
Three side lengths: 5 5 8
Isosceles triangle
```

Output:

```text
Three side lengths: 3 4 5
Scalene triangle
```

Output:

```text
Three side lengths: 1 2 8
Not a valid triangle.
```

**Solution for Exercise 3:**

```text
Program DrinkMenu
{ Displays a drink menu, reads a choice and quantity, then displays the price }

Dictionary
    choice, quantity, price : integer
    drink : string

Algorithm
    output("1. Coffee  15000")
    output("2. Tea     10000")
    output("3. Juice   18000")
    output("Your choice: ")
    input(choice)
    depend on (choice)
        1 : drink <- "Coffee"
            price <- 15000
        2 : drink <- "Tea"
            price <- 10000
        3 : drink <- "Juice"
            price <- 18000
        otherwise : drink <- ""
                    price <- 0
    enddepend
    if price = 0 then
        output("Invalid choice.")
    else
        output("Quantity: ")
        input(quantity)
        output(quantity, " x ", drink, " = ", quantity * price)
    endif
```

```java
import java.util.Scanner;

// Program DrinkMenu
// Displays a drink menu, reads a choice and quantity, then displays the price.
public class DrinkMenu {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        int choice;
        int quantity;
        String drink;
        int price;

        // Algorithm
        System.out.println("1. Coffee  15000");
        System.out.println("2. Tea     10000");
        System.out.println("3. Juice   18000");
        System.out.print("Your choice: ");
        choice = input.nextInt();
        switch (choice) {
            case 1 -> {
                drink = "Coffee";
                price = 15000;
            }
            case 2 -> {
                drink = "Tea";
                price = 10000;
            }
            case 3 -> {
                drink = "Juice";
                price = 18000;
            }
            default -> {
                drink = "";
                price = 0;
            }
        }
        if (price == 0) {
            System.out.println("Invalid choice.");
        } else {
            System.out.print("Quantity: ");
            quantity = input.nextInt();
            System.out.println(quantity + " x " + drink + " = " + (quantity * price));
        }
    }
}
```

Each case sets two variables, so each needs braces. The `default` case also assigns both variables, which guarantees they have values after the `switch`. A price of 0 marks an invalid choice, and the program only asks for a quantity when the choice is valid.

```bash
javac DrinkMenu.java
java DrinkMenu
```

Output:

```text
1. Coffee  15000
2. Tea     10000
3. Juice   18000
Your choice: 2
Quantity: 3
3 x Tea = 30000
```

Output:

```text
1. Coffee  15000
2. Tea     10000
3. Juice   18000
Your choice: 5
Invalid choice.
```

---

## Next Up - Lesson 9

In this lesson you learned three ways to handle more than two outcomes. Nested conditions answer one question at a time, else-if chains test ordered conditions until one is true, and `depend on` chooses a branch from the exact value of one variable, implemented in Java with `switch` and its arrow cases. You also saw how the order of conditions decides the result, and why every case structure needs an `otherwise` or `default`. Module 3 is complete.

Your programs can now make decisions, but each one still runs just once. In Lesson 9 you will begin Module 4 and add the third building block, repetition. You will design `while ... do` loops in notation, choose loop conditions that eventually become false, and implement them in Java with the `while` statement.
