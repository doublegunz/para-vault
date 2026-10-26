## 1. Before You Begin

In Lesson 4 you learned to store data in variables of the right type. Storing data is only half the job; programs also need to *work* with it. They add prices, split minutes into hours, compare a score with a passing grade, and check whether several conditions are true at the same time. All of this is done with **operators**, and a combination of values, variables, and operators is called an **expression**.

This lesson covers the three families of operators you will use in almost every algorithm: arithmetic operators that calculate, relational operators that compare, and logical operators that combine true and false values. You will also learn the precedence rules that decide which part of an expression is calculated first, and how to convert between `int` and `double` without losing data by accident.

### What You'll Build

A set of small programs in a `lesson-05` folder that demonstrate every operator, plus a leap year checker that combines arithmetic, relational, and logical operators into one expression.

### What You'll Learn

- ✅ The arithmetic operators in notation and Java, including `div` and `mod`
- ✅ Why `17 / 5` is `3` in Java, and how to get `3.4` instead
- ✅ Shorthand assignment operators such as `+=` and `++`
- ✅ The relational operators and how notation's `=` and `<>` map to Java's `==` and `!=`
- ✅ The logical operators `and`, `or`, and `not`, written `&&`, `||`, and `!` in Java
- ✅ Operator precedence and how parentheses change the order of evaluation
- ✅ Widening and casting between `int` and `double`

### What You'll Need

- Lesson 4 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-05
cd ~/java-basics/lesson-05
```

---

## 2. Arithmetic Operators

Arithmetic operators calculate new values from numbers. Most of them behave exactly as in school mathematics. Two of them, integer division and remainder, need extra attention because they are used constantly in algorithms and often surprise beginners.

| Notation | Java | Meaning | Example (a = 17, b = 5) |
| --- | --- | --- | --- |
| `+` | `+` | Addition | `22` |
| `-` | `-` | Subtraction | `12` |
| `*` | `*` | Multiplication | `85` |
| `div` | `/` with two integers | Integer division, whole part only | `3` |
| `mod` | `%` | Remainder of integer division | `2` |
| `/` | `/` with at least one real | Real division | `3.4` |

### Step 1: Try Every Arithmetic Operator

The notation keeps integer division (`div`) and real division (`/`) separate, so the intent is always clear:

```text
Program ArithmeticOperators
{ Shows the result of each arithmetic operator on two integers }

Dictionary
    a : integer = 17
    b : integer = 5

Algorithm
    output("a + b   = ", a + b)
    output("a - b   = ", a - b)
    output("a * b   = ", a * b)
    output("a div b = ", a div b)
    output("a mod b = ", a mod b)
    output("a / b   = ", a / b)
```

Java uses the same `/` symbol for both kinds of division. Which kind you get depends on the types involved: if both sides are integers, the result is an integer. Create `ArithmeticOperators.java`:

```java
// Program ArithmeticOperators
// Shows the result of each arithmetic operator on two integers.
public class ArithmeticOperators {
    public static void main(String[] args) {
        // Dictionary
        int a = 17;
        int b = 5;

        // Algorithm
        System.out.println("a + b   = " + (a + b));
        System.out.println("a - b   = " + (a - b));
        System.out.println("a * b   = " + (a * b));
        System.out.println("a div b = " + (a / b));
        System.out.println("a mod b = " + (a % b));
        System.out.println("a / b   = " + ((double) a / b));
    }
}
```

Each calculation is wrapped in parentheses, such as `(a + b)`. This is important: without them, Java would join `"a + b   = "` with `a` first, producing the text `a + b   = 17`, and then join `5` to that text, giving `175` instead of `22`. Parentheses make the calculation happen before the joining.

`a / b` divides two integers, so Java performs integer division and keeps only the whole part. `a % b` gives the remainder. In the last line, `(double) a` converts `a` to a `double` before dividing, so Java performs real division. You will learn more about this conversion, called a **cast**, in Section 6.

```bash
javac ArithmeticOperators.java
java ArithmeticOperators
```

Output:

```text
a + b   = 22
a - b   = 12
a * b   = 85
a div b = 3
a mod b = 2
a / b   = 3.4
```

17 divided by 5 is 3 with 2 left over: `div` gives the 3 and `mod` gives the 2. Real division gives the exact answer, 3.4.

### Step 2: Use div and mod Together

`div` and `mod` are a natural pair for splitting a quantity into larger and smaller units. You saw this algorithm as an exercise in Lesson 2:

```text
Program MinutesToHours
{ Converts a number of minutes into hours and remaining minutes }

Dictionary
    totalMinutes : integer = 135
    hours, minutes : integer

Algorithm
    hours <- totalMinutes div 60
    minutes <- totalMinutes mod 60
    output(totalMinutes, " minutes = ", hours, " hours ", minutes, " minutes")
```

Create `MinutesToHours.java`:

```java
// Program MinutesToHours
// Converts a number of minutes into hours and remaining minutes.
public class MinutesToHours {
    public static void main(String[] args) {
        // Dictionary
        int totalMinutes = 135;
        int hours;
        int minutes;

        // Algorithm
        hours = totalMinutes / 60;
        minutes = totalMinutes % 60;
        System.out.println(totalMinutes + " minutes = " + hours + " hours " + minutes + " minutes");
    }
}
```

`div` becomes `/` (safe here because both values are `int`) and `mod` becomes `%`. The same pattern converts seconds into minutes and seconds, grams into kilograms and grams, or days into weeks and days.

```bash
javac MinutesToHours.java
java MinutesToHours
```

Output:

```text
135 minutes = 2 hours 15 minutes
```

### Step 3: Use Shorthand Assignment Operators

Updating a variable based on its own value, such as `balance <- balance + 25000`, is so common that Java has shorthand forms for it:

| Long form | Shorthand | Meaning |
| --- | --- | --- |
| `x = x + 5;` | `x += 5;` | Add 5 to `x` |
| `x = x - 5;` | `x -= 5;` | Subtract 5 from `x` |
| `x = x * 5;` | `x *= 5;` | Multiply `x` by 5 |
| `x = x / 5;` | `x /= 5;` | Divide `x` by 5 |
| `x = x + 1;` | `x++;` | Increase `x` by 1 (increment) |
| `x = x - 1;` | `x--;` | Decrease `x` by 1 (decrement) |

Notation keeps the long form (`x <- x + 1`) because it is clearer, but you will see the shorthand in almost all Java code, especially `++` in loops. Create `CompoundAssignment.java`:

```java
// Program CompoundAssignment
// Shows the shorthand forms of updating a variable.
public class CompoundAssignment {
    public static void main(String[] args) {
        // Dictionary
        int balance = 100000;
        int count = 0;

        // Algorithm
        balance += 25000;
        System.out.println("After deposit : " + balance);
        balance -= 40000;
        System.out.println("After withdraw: " + balance);
        balance *= 2;
        System.out.println("After doubling: " + balance);
        count++;
        count++;
        System.out.println("Count         : " + count);
        count--;
        System.out.println("Count         : " + count);
    }
}
```

Each shorthand line reads the current value, updates it, and stores the result back in the same variable. `count++` twice moves the count from 0 to 2, and `count--` brings it back to 1.

```bash
javac CompoundAssignment.java
java CompoundAssignment
```

Output:

```text
After deposit : 125000
After withdraw: 85000
After doubling: 170000
Count         : 2
Count         : 1
```

---

## 3. Relational Operators

A **relational operator** compares two values and produces a `boolean`: `true` or `false`. Comparisons are the heart of decisions and loops, which you will build in Modules 3 and 4.

| Notation | Java | Meaning |
| --- | --- | --- |
| `=` | `==` | Equal to |
| `<>` | `!=` | Not equal to |
| `>` | `>` | Greater than |
| `<` | `<` | Less than |
| `>=` | `>=` | Greater than or equal to |
| `<=` | `<=` | Less than or equal to |

Pay close attention to the first row. In notation, assignment is `<-`, so `=` is free to mean "is equal to." In Java, `=` is already taken by assignment, so equality is written with *two* equal signs, `==`. Mixing them up is one of the most common beginner mistakes in Java.

### Step 1: Compare Two Values

```text
Program CompareValues
{ Compares two scores with every relational operator }

Dictionary
    myScore      : integer = 80
    passingScore : integer = 75

Algorithm
    output("myScore =  passingScore : ", myScore = passingScore)
    output("myScore <> passingScore : ", myScore <> passingScore)
    output("myScore >  passingScore : ", myScore > passingScore)
    output("myScore <  passingScore : ", myScore < passingScore)
    output("myScore >= passingScore : ", myScore >= passingScore)
    output("myScore <= passingScore : ", myScore <= passingScore)
```

Create `CompareValues.java`:

```java
// Program CompareValues
// Compares two scores with every relational operator.
public class CompareValues {
    public static void main(String[] args) {
        // Dictionary
        int myScore = 80;
        int passingScore = 75;

        // Algorithm
        System.out.println("myScore =  passingScore : " + (myScore == passingScore));
        System.out.println("myScore <> passingScore : " + (myScore != passingScore));
        System.out.println("myScore >  passingScore : " + (myScore > passingScore));
        System.out.println("myScore <  passingScore : " + (myScore < passingScore));
        System.out.println("myScore >= passingScore : " + (myScore >= passingScore));
        System.out.println("myScore <= passingScore : " + (myScore <= passingScore));
    }
}
```

The labels keep the notation symbols so you can compare the two side by side, while the code uses Java's operators. Every comparison is wrapped in parentheses so that it is evaluated before being joined to the label. Each one produces a `boolean`, which `println` displays as `true` or `false`.

```bash
javac CompareValues.java
java CompareValues
```

Output:

```text
myScore =  passingScore : false
myScore <> passingScore : true
myScore >  passingScore : true
myScore <  passingScore : false
myScore >= passingScore : true
myScore <= passingScore : false
```

80 is not equal to 75, it is greater than 75, and therefore it is also "greater than or equal to" 75. Each result is a value you could store in a `boolean` variable.

---

## 4. Logical Operators

Real conditions often have several parts. "You can apply for a driving license if you are at least 17 *and* you have an ID card." **Logical operators** combine boolean values into a single result.

| Notation | Java | Result is true when |
| --- | --- | --- |
| `and` | `&&` | Both sides are true |
| `or` | `\|\|` | At least one side is true |
| `not` | `!` | The value is false (it flips true and false) |

The full behavior of each operator fits in a small table called a **truth table**:

| p | q | p and q | p or q | not p |
| --- | --- | --- | --- | --- |
| true | true | true | true | false |
| true | false | false | true | false |
| false | true | false | true | true |
| false | false | false | false | true |

### Step 1: Combine Conditions

**Problem:** A person can apply for a driving license if they are at least 17 and have an ID card. They get the license if they can apply and they passed the test. If they can apply but did not pass, they must retake the test.

```text
Program LogicalOperators
{ Decides whether a person can get a driving license using logical operators }

Dictionary
    age        : integer = 18
    hasIdCard  : boolean = true
    passedTest : boolean = false
    canApply, canGetLicense, mustRetake : boolean

Algorithm
    canApply <- age >= 17 and hasIdCard
    canGetLicense <- canApply and passedTest
    mustRetake <- canApply and not passedTest
    output("Can apply       : ", canApply)
    output("Can get license : ", canGetLicense)
    output("Must retake test: ", mustRetake)
    output("Is a teenager   : ", age >= 13 and age <= 19)
    output("Gets a discount : ", age < 12 or age >= 60)
```

Create `LogicalOperators.java`:

```java
// Program LogicalOperators
// Decides whether a person can get a driving license using logical operators.
public class LogicalOperators {
    public static void main(String[] args) {
        // Dictionary
        int age = 18;
        boolean hasIdCard = true;
        boolean passedTest = false;
        boolean canApply;
        boolean canGetLicense;
        boolean mustRetake;

        // Algorithm
        canApply = age >= 17 && hasIdCard;
        canGetLicense = canApply && passedTest;
        mustRetake = canApply && !passedTest;
        System.out.println("Can apply       : " + canApply);
        System.out.println("Can get license : " + canGetLicense);
        System.out.println("Must retake test: " + mustRetake);
        System.out.println("Is a teenager   : " + (age >= 13 && age <= 19));
        System.out.println("Gets a discount : " + (age < 12 || age >= 60));
    }
}
```

`age >= 17 && hasIdCard` is true only when both parts are true; here, 18 is at least 17 and the person has an ID card, so `canApply` is `true`. `canApply && passedTest` is `false` because the test was not passed. `!passedTest` flips `false` to `true`, so `mustRetake` is `true`. The teenager check shows how to test whether a number is inside a range: it must be at least the lower limit *and* at most the upper limit. The discount check uses `||` because either condition alone is enough.

```bash
javac LogicalOperators.java
java LogicalOperators
```

Output:

```text
Can apply       : true
Can get license : false
Must retake test: true
Is a teenager   : true
Gets a discount : false
```

Trace each line against the truth table to confirm the results. Change `passedTest` to `true`, compile, and run again: `canGetLicense` becomes `true` and `mustRetake` becomes `false`.

---

## 5. Precedence and Type Conversion

When an expression contains several operators, Java needs rules to decide which one goes first. When it contains different types, Java needs rules to decide the type of the result. Both sets of rules can produce surprising results if you do not know them.

### Step 1: Control the Order with Parentheses

**Operator precedence** is the order in which operators are applied. It follows school mathematics, extended with the new operators:

| Priority | Operators |
| --- | --- |
| 1 (first) | Parentheses `( )` |
| 2 | `!` (not), casts such as `(double)` |
| 3 | `*`, `/`, `%` |
| 4 | `+`, `-` |
| 5 | `<`, `<=`, `>`, `>=` |
| 6 | `==`, `!=` |
| 7 | `&&` |
| 8 (last) | `\|\|` |

Operators with the same priority are applied from left to right. Create `Precedence.java` to see the rules in action:

```java
// Program Precedence
// Shows how operator precedence and parentheses change a result.
public class Precedence {
    public static void main(String[] args) {
        // Dictionary
        double score1 = 80.0;
        double score2 = 90.0;
        double score3 = 70.0;

        // Algorithm
        System.out.println("2 + 3 * 4   = " + (2 + 3 * 4));
        System.out.println("(2 + 3) * 4 = " + ((2 + 3) * 4));
        System.out.println("10 - 4 - 3  = " + (10 - 4 - 3));
        System.out.println("Wrong average: " + (score1 + score2 + score3 / 3));
        System.out.println("Right average: " + ((score1 + score2 + score3) / 3));
    }
}
```

`2 + 3 * 4` multiplies first because `*` has higher priority, giving 2 + 12. Parentheses force the addition first in `(2 + 3) * 4`. `10 - 4 - 3` is evaluated left to right as (10 - 4) - 3. The two average lines show why this matters in a real algorithm: without parentheses, only `score3` is divided by 3.

```bash
javac Precedence.java
java Precedence
```

Output:

```text
2 + 3 * 4   = 14
(2 + 3) * 4 = 20
10 - 4 - 3  = 3
Wrong average: 193.33333333333334
Right average: 80.0
```

An average of 193 for scores of 80, 90, and 70 is obviously wrong, which is a good reminder to always check whether a result makes sense. When in doubt, add parentheses: they never hurt, and they make your intent clear to anyone reading the code.

### Step 2: Convert Between int and double

Java converts types automatically when no data can be lost. Storing an `int` in a `double` is safe, so Java does it silently; this is called **widening**. Going the other way, from `double` to `int`, would lose the decimal part, so Java requires you to ask for it explicitly with a **cast**: the target type in parentheses before the value, such as `(int) price`.

Create `TypeConversion.java`:

```java
// Program TypeConversion
// Shows automatic widening and explicit casting between int and double.
public class TypeConversion {
    public static void main(String[] args) {
        // Dictionary
        int totalScore = 255;
        int studentCount = 3;
        int wholeNumber = 7;
        double price = 9.99;
        double widened;
        int truncated;

        // Algorithm
        widened = wholeNumber;
        truncated = (int) price;
        System.out.println("int 7 stored in a double : " + widened);
        System.out.println("(int) 9.99               : " + truncated);
        System.out.println("255 / 3 with ints        : " + (totalScore / studentCount));
        System.out.println("255 / 4 with ints        : " + (totalScore / 4));
        System.out.println("(double) 255 / 4         : " + ((double) totalScore / 4));
    }
}
```

`widened = wholeNumber;` copies 7 into a `double`, which then holds `7.0`. `(int) price` cuts off the decimal part of 9.99. Note that it does not round: it simply drops everything after the decimal point, which is called **truncation**. The last three lines show integer division again: 255 divided by 4 is 63.75, but with two `int` values Java keeps only 63. Casting one of the values to `double` before dividing gives the exact result.

```bash
javac TypeConversion.java
java TypeConversion
```

Output:

```text
int 7 stored in a double : 7.0
(int) 9.99               : 9
255 / 3 with ints        : 85
255 / 4 with ints        : 63
(double) 255 / 4         : 63.75
```

The rule to remember: **if you want a real division result, make sure at least one side of `/` is a `double`.**

---

## 6. Run and Test

Now combine everything into one expression. The rule for leap years is:

- A year divisible by 4 is a leap year,
- except a year divisible by 100, which is not,
- except a year divisible by 400, which is.

Written as a single boolean expression in notation:

```text
Program LeapYear
{ Checks several years with the leap year rule }

Dictionary
    year1 : integer = 2024
    year2 : integer = 2023
    year3 : integer = 1900
    year4 : integer = 2000

Algorithm
    output(year1, " is a leap year: ", (year1 mod 4 = 0 and year1 mod 100 <> 0) or year1 mod 400 = 0)
    output(year2, " is a leap year: ", (year2 mod 4 = 0 and year2 mod 100 <> 0) or year2 mod 400 = 0)
    output(year3, " is a leap year: ", (year3 mod 4 = 0 and year3 mod 100 <> 0) or year3 mod 400 = 0)
    output(year4, " is a leap year: ", (year4 mod 4 = 0 and year4 mod 100 <> 0) or year4 mod 400 = 0)
```

"Divisible by 4" means the remainder after dividing by 4 is 0, so it is written `year mod 4 = 0`. The four test years were chosen on purpose: one of each kind in the rule. Before running anything, predict the results: 2024 is a leap year, 2023 is not, 1900 is not (divisible by 100 but not 400), and 2000 is (divisible by 400).

Create `LeapYear.java`:

```java
// Program LeapYear
// Checks several years with the leap year rule.
public class LeapYear {
    public static void main(String[] args) {
        // Dictionary
        int year1 = 2024;
        int year2 = 2023;
        int year3 = 1900;
        int year4 = 2000;

        // Algorithm
        System.out.println(year1 + " is a leap year: " + ((year1 % 4 == 0 && year1 % 100 != 0) || year1 % 400 == 0));
        System.out.println(year2 + " is a leap year: " + ((year2 % 4 == 0 && year2 % 100 != 0) || year2 % 400 == 0));
        System.out.println(year3 + " is a leap year: " + ((year3 % 4 == 0 && year3 % 100 != 0) || year3 % 400 == 0));
        System.out.println(year4 + " is a leap year: " + ((year4 % 4 == 0 && year4 % 100 != 0) || year4 % 400 == 0));
    }
}
```

The inner parentheses group the "divisible by 4 but not by 100" part. The outer parentheses make the whole expression evaluate before it is joined to the label. Repeating the expression four times is clumsy; in Lesson 13 you will write it once as a function and call it for each year.

```bash
javac LeapYear.java
java LeapYear
```

Output:

```text
2024 is a leap year: true
2023 is a leap year: false
1900 is a leap year: false
2000 is a leap year: true
```

All four results match the predictions. Testing one example of every case in a rule, especially the exceptions, is how you gain confidence that an expression is correct.

---

## 7. Fix the Errors in Your Code

Some operator mistakes are caught by the compiler. Others compile perfectly and quietly produce the wrong answer, which makes them more dangerous.

**Error 1: Integer division in an average.**

```java
// Wrong
public class Average {
    public static void main(String[] args) {
        int total = 250;
        int count = 3;
        double average = total / count;
        System.out.println("Average: " + average);
    }
}

// Correct
public class Average {
    public static void main(String[] args) {
        int total = 250;
        int count = 3;
        double average = (double) total / count;
        System.out.println("Average: " + average);
    }
}
```

The wrong version compiles and runs, but displays:

```text
Average: 83.0
```

The correct version displays:

```text
Average: 83.33333333333333
```

Storing the result in a `double` is not enough, because the division `total / count` happens *first*, with two `int` values, and the decimal part is already gone before the result is stored. Cast one side to `double` before dividing.

**Error 2: Using `=` instead of `==`.**

```java
// Wrong
public class IsPassing {
    public static void main(String[] args) {
        int score = 75;
        boolean isPerfect = score = 100;
        System.out.println(isPerfect);
    }
}

// Correct
public class IsPassing {
    public static void main(String[] args) {
        int score = 75;
        boolean isPerfect = score == 100;
        System.out.println(isPerfect);
    }
}
```

The wrong version produces:

```text
IsPassing.java:4: error: incompatible types: int cannot be converted to boolean
        boolean isPerfect = score = 100;
                                  ^
1 error
```

`score = 100` is an assignment, and its result is the number 100, which cannot be stored in a `boolean`. Use `==` to compare. When translating notation, remember: notation `<-` becomes Java `=`, and notation `=` becomes Java `==`.

**Error 3: Writing a range like in mathematics.**

```java
// Wrong
public class Range {
    public static void main(String[] args) {
        int age = 15;
        boolean isTeenager = 13 <= age <= 19;
        System.out.println(isTeenager);
    }
}

// Correct
public class Range {
    public static void main(String[] args) {
        int age = 15;
        boolean isTeenager = age >= 13 && age <= 19;
        System.out.println(isTeenager);
    }
}
```

The wrong version produces:

```text
Range.java:4: error: bad operand types for binary operator '<='
        boolean isTeenager = 13 <= age <= 19;
                                       ^
  first type:  boolean
  second type: int
1 error
```

Java evaluates `13 <= age` first, which gives a `boolean`, and then tries to compare that boolean with 19, which makes no sense. A range check is always two comparisons joined with `&&`.

---

## 8. Exercises

**Exercise 1:** Write the notation and the Java program `MoneyBreakdown` that breaks an amount of 185000 into the smallest number of 50000, 20000, 10000, and 5000 notes, using `div` and `mod`. Display how many of each note are needed and how much is left over.

**Exercise 2:** Write the notation and the Java program `TemperatureConverter` that converts a body temperature of 36.6 degrees Celsius into Fahrenheit (C x 9 / 5 + 32) and Kelvin (C + 273.15).

**Exercise 3:** A number is valid for a game if it is between 1 and 100 (inclusive) and is a multiple of 5. Write the notation and the Java program `ValidNumber` that displays whether 45, 47, and 105 are valid.

---

## 9. Solutions

**Solution for Exercise 1:**

```text
Program MoneyBreakdown
{ Breaks an amount of money into 50000, 20000, 10000, and 5000 notes }

Dictionary
    amount : integer = 185000
    remaining, notes50k, notes20k, notes10k, notes5k : integer

Algorithm
    notes50k <- amount div 50000
    remaining <- amount mod 50000
    notes20k <- remaining div 20000
    remaining <- remaining mod 20000
    notes10k <- remaining div 10000
    remaining <- remaining mod 10000
    notes5k <- remaining div 5000
    remaining <- remaining mod 5000
    output("Amount  : ", amount)
    output("50000 x ", notes50k)
    output("20000 x ", notes20k)
    output("10000 x ", notes10k)
    output(" 5000 x ", notes5k)
    output("Left    : ", remaining)
```

```java
// Program MoneyBreakdown
// Breaks an amount of money into 50000, 20000, 10000, and 5000 notes.
public class MoneyBreakdown {
    public static void main(String[] args) {
        // Dictionary
        int amount = 185000;
        int remaining;
        int notes50k;
        int notes20k;
        int notes10k;
        int notes5k;

        // Algorithm
        notes50k = amount / 50000;
        remaining = amount % 50000;
        notes20k = remaining / 20000;
        remaining = remaining % 20000;
        notes10k = remaining / 10000;
        remaining = remaining % 10000;
        notes5k = remaining / 5000;
        remaining = remaining % 5000;
        System.out.println("Amount  : " + amount);
        System.out.println("50000 x " + notes50k);
        System.out.println("20000 x " + notes20k);
        System.out.println("10000 x " + notes10k);
        System.out.println(" 5000 x " + notes5k);
        System.out.println("Left    : " + remaining);
    }
}
```

The algorithm works from the largest note down. For each note, `div` counts how many fit and `mod` keeps what is left for the next, smaller note. The variable `remaining` is reused at every step, so each line builds on the result of the line before.

```bash
javac MoneyBreakdown.java
java MoneyBreakdown
```

Output:

```text
Amount  : 185000
50000 x 3
20000 x 1
10000 x 1
 5000 x 1
Left    : 0
```

**Solution for Exercise 2:**

```text
Program TemperatureConverter
{ Converts a Celsius temperature to Fahrenheit and Kelvin }

Dictionary
    celsius : real = 36.6
    fahrenheit, kelvin : real

Algorithm
    fahrenheit <- celsius * 9 / 5 + 32
    kelvin <- celsius + 273.15
    output("Celsius   : ", celsius)
    output("Fahrenheit: ", fahrenheit)
    output("Kelvin    : ", kelvin)
```

```java
// Program TemperatureConverter
// Converts a Celsius temperature to Fahrenheit and Kelvin.
public class TemperatureConverter {
    public static void main(String[] args) {
        // Dictionary
        double celsius = 36.6;
        double fahrenheit;
        double kelvin;

        // Algorithm
        fahrenheit = celsius * 9 / 5 + 32;
        kelvin = celsius + 273.15;
        System.out.println("Celsius   : " + celsius);
        System.out.println("Fahrenheit: " + fahrenheit);
        System.out.println("Kelvin    : " + kelvin);
    }
}
```

Because `celsius` is a `double`, `celsius * 9` is a `double`, and the division by 5 is real division, so no cast is needed. Multiplication and division happen before the addition of 32, which matches the formula.

```bash
javac TemperatureConverter.java
java TemperatureConverter
```

Output:

```text
Celsius   : 36.6
Fahrenheit: 97.88000000000001
Kelvin    : 309.75
```

The exact answer is 97.88, but Java shows `97.88000000000001`. Computers store decimal numbers in binary, and some decimals, like 36.6, cannot be stored exactly, so tiny rounding differences appear. The value is correct for all practical purposes. In Lesson 6 you will learn to display it neatly with a fixed number of decimal places.

**Solution for Exercise 3:**

```text
Program ValidNumber
{ Checks whether numbers are between 1 and 100 and multiples of 5 }

Dictionary
    n1 : integer = 45
    n2 : integer = 47
    n3 : integer = 105

Algorithm
    output(n1, " is valid: ", n1 >= 1 and n1 <= 100 and n1 mod 5 = 0)
    output(n2, " is valid: ", n2 >= 1 and n2 <= 100 and n2 mod 5 = 0)
    output(n3, " is valid: ", n3 >= 1 and n3 <= 100 and n3 mod 5 = 0)
```

```java
// Program ValidNumber
// Checks whether numbers are between 1 and 100 and multiples of 5.
public class ValidNumber {
    public static void main(String[] args) {
        // Dictionary
        int n1 = 45;
        int n2 = 47;
        int n3 = 105;

        // Algorithm
        System.out.println(n1 + " is valid: " + (n1 >= 1 && n1 <= 100 && n1 % 5 == 0));
        System.out.println(n2 + " is valid: " + (n2 >= 1 && n2 <= 100 && n2 % 5 == 0));
        System.out.println(n3 + " is valid: " + (n3 >= 1 && n3 <= 100 && n3 % 5 == 0));
    }
}
```

Three conditions must all be true, so they are joined with `&&`. The first two form the range check, and `% 5 == 0` checks for a multiple of 5. The test values cover each case: 45 passes everything, 47 fails the multiple check, and 105 is a multiple of 5 but outside the range.

```bash
javac ValidNumber.java
java ValidNumber
```

Output:

```text
45 is valid: true
47 is valid: false
105 is valid: false
```

---

## Next Up - Lesson 6

In this lesson you worked with all three families of operators. Arithmetic operators calculate, and you learned that `div` and `mod` map to `/` and `%` in Java, with integer division as a trap to watch for. Relational operators compare values and produce booleans, with notation's `=` and `<>` becoming `==` and `!=`. Logical operators combine conditions with `&&`, `||`, and `!`. You also used precedence, parentheses, and casts to make expressions calculate exactly what you intend.

Every program so far has used fixed values written into the code. In Lesson 6 you will finally translate `input()` into Java: you will read numbers and text from the keyboard with `Scanner`, display results neatly with formatted output, and build programs that work with any data the user types.
