## 1. Before You Begin

Welcome to the course. Before you install anything or type any code, this lesson answers two questions every beginner should be able to answer: what is a program, and what is an algorithm? Many people think programming means memorizing the commands of a language. In practice, the hard part of programming is deciding *what steps* solve a problem. Typing those steps in a language like Java comes afterward and is much easier once the steps are clear.

This lesson uses everyday examples and plain English only. There is no software to install yet. You will need a pen and paper (or a text file), because the best way to learn this lesson is to write the algorithms yourself.

### What You'll Build

A handful of algorithms written as numbered steps in plain English: making a cup of tea, finding the larger of two numbers, calculating the total price of a purchase, and checking whether a student passed. You will also "run" each algorithm by hand to test that it gives the correct answer.

### What You'll Learn

- ✅ What a program is and what a computer actually does when it runs one
- ✅ What an algorithm is and the five properties a good algorithm has
- ✅ The relationship between a problem, an algorithm, and a program
- ✅ How every algorithm can be built from three basic structures: sequence, selection, and repetition
- ✅ How to describe a solution as clear, ordered steps
- ✅ How to test an algorithm by tracing it by hand
- ✅ Why this course writes algorithms first and Java code second

### What You'll Need

- No previous programming experience
- A pen and paper, or any plain text editor
- About 45 minutes of focused time

---

## 2. What Is a Program?

A computer is very fast and very obedient, but it is not smart. It cannot guess what you mean. It only follows instructions, one at a time, exactly as they are written. A **program** is a set of instructions written for a computer, in a language the computer (or a tool on the computer) can understand.

Think about the apps you use every day. A calculator app takes the numbers you type, performs an operation, and shows a result. A music player reads a list of songs and plays them one after another. A game checks which button you pressed and moves a character. Each of these is a program, and each one follows the same overall shape:

| Part | What happens | Calculator example |
| --- | --- | --- |
| Input | The program receives data | You type `12`, `+`, and `30` |
| Process | The program works with the data | It adds 12 and 30 |
| Output | The program shows or saves a result | It displays `42` |

You will see this input, process, output pattern in almost every program in this course. When you are not sure how to start solving a problem, asking "What is the input? What should the output be? What process turns one into the other?" is a reliable first step.

### Programming Languages

Computers internally work with numbers and very simple operations. Writing instructions at that level would be slow and painful, so people invented **programming languages**: languages with a strict, small vocabulary that humans can read and that tools can translate into something the computer runs. Java, Python, C, JavaScript, PHP, and Rust are all programming languages.

Every language has its own **syntax**, the exact rules for how instructions must be written: which words are allowed, where the punctuation goes, and so on. Syntax is important, because the computer rejects anything that breaks the rules. But syntax is the *last* step. Before you can write instructions in any language, you need to know which instructions to write. That is where algorithms come in.

---

## 3. What Is an Algorithm?

An **algorithm** is a finite sequence of clear steps that solves a problem. The word comes from the name of the ninth century Persian mathematician Muhammad ibn Musa al-Khwarizmi, whose books described step-by-step methods for doing arithmetic.

You already follow algorithms every day without calling them that. A recipe is an algorithm for cooking a dish. The instructions for assembling a piece of furniture are an algorithm. Directions to a friend's house are an algorithm. In each case, someone has broken a task into steps that anyone can follow in order to reach the same result.

### Step 1: Write an Everyday Algorithm

Here is an algorithm for making a cup of tea, written as numbered steps:

```text
Algorithm: Make a cup of tea

1. Fill the kettle with water.
2. Boil the water.
3. Put a tea bag into a cup.
4. Pour the hot water into the cup.
5. Wait 3 minutes.
6. Remove the tea bag.
7. Serve the tea.
```

Read it slowly and notice a few things. Each line does exactly one action. The steps are in an order that matters: pouring the water (step 4) before boiling it (step 2) would give you a cold, sad drink. The algorithm has a clear start and a clear end. And every step is concrete: "wait 3 minutes" is better than "wait a while," because anyone who follows it gets the same result.

### Step 2: Check the Five Properties of a Good Algorithm

Computer scientists usually describe a good algorithm with five properties. The tea algorithm above has all of them.

| Property | Meaning | In the tea algorithm |
| --- | --- | --- |
| Input | It works with zero or more pieces of data given at the start | Water, a tea bag, a cup |
| Output | It produces at least one result | A cup of tea |
| Definiteness | Every step is clear and has only one meaning | "Wait 3 minutes", not "wait a bit" |
| Finiteness | It always stops after a limited number of steps | It ends at step 7 |
| Effectiveness | Every step is simple enough to actually be done | Each step is a basic action |

When you write an algorithm for a computer, **definiteness** matters even more than in daily life. A person can guess what "add some sugar" means. A computer cannot. Every step you give a computer must have exactly one meaning.

---

## 4. From Problem to Algorithm to Program

Programming is the process of going from a problem to a working program. In this course you will always walk through the same three stages:

```text
Problem  ------>  Algorithm  ------>  Program
(what)            (how, in steps)      (how, in a language)
```

1. **Understand the problem.** What is the input? What output is expected? Are there special cases?
2. **Design the algorithm.** Write the steps that turn the input into the output, without worrying about any language.
3. **Implement the program.** Translate the algorithm into a programming language, then run and test it.

Most beginner mistakes come from skipping stage 2 and going straight to typing code. When the steps are not clear in your head, the code will not be clear either. Designing the algorithm first lets you focus on *logic*. Implementing it afterward lets you focus on *syntax*. Doing both at the same time is much harder than doing them one after the other.

### Step 1: Understand a Small Problem

Let us apply the three stages to a computing problem.

**Problem:** A shop sells notebooks. Given the price of one notebook and the number of notebooks a customer buys, calculate the total price.

Start by naming the input, the output, and the process:

| Part | Description |
| --- | --- |
| Input | The price of one notebook, and the quantity bought |
| Output | The total price |
| Process | Multiply the price by the quantity |

### Step 2: Design the Algorithm

Now write the steps in plain English:

```text
Algorithm: Calculate total price

1. Read the price of one notebook.
2. Read the quantity bought.
3. Calculate total = price x quantity.
4. Display the total.
```

Notice the word "read." In computing, reading a value means receiving it as input, for example from the keyboard. "Display" means showing a value as output, for example on the screen. These two words appear in nearly every algorithm you will write.

Notice also that step 3 gives the result a **name**: `total`. Giving names to values is how algorithms remember data from one step to the next. In Lesson 4 you will learn that these named storage places are called **variables**.

### Step 3: Test the Algorithm by Hand

An algorithm is a plan, and you can test a plan before writing any code. Pick some sample input and follow the steps yourself, writing down what happens. This is called **tracing** the algorithm.

Suppose the price is 5000 and the quantity is 3:

| Step | Action | price | quantity | total | Displayed |
| --- | --- | --- | --- | --- | --- |
| 1 | Read the price | 5000 | | | |
| 2 | Read the quantity | 5000 | 3 | | |
| 3 | total = price x quantity | 5000 | 3 | 15000 | |
| 4 | Display the total | 5000 | 3 | 15000 | 15000 |

The algorithm displays 15000, which is correct: three notebooks at 5000 each cost 15000. A tracing table like this one is one of the most useful tools in programming. When a program behaves strangely later, tracing it step by step is usually how you find out why.

---

## 5. The Three Building Blocks of Every Algorithm

The total price algorithm runs its steps straight from top to bottom. Real problems often need more than that. Fortunately, it has been proven that every algorithm, no matter how complicated, can be built from just three basic structures.

### Step 1: Sequence

A **sequence** is a list of steps executed one after another, in order. The tea algorithm and the total price algorithm are pure sequences. Each step runs exactly once.

```text
1. Do the first thing.
2. Do the second thing.
3. Do the third thing.
```

### Step 2: Selection

**Selection** (also called a decision or a condition) lets an algorithm choose between different steps depending on whether something is true. Here is an algorithm that finds the larger of two numbers:

```text
Algorithm: Find the larger of two numbers

1. Read number A.
2. Read number B.
3. If A is greater than B, then
       display A.
   Otherwise,
       display B.
```

Step 3 checks a **condition**, "A is greater than B." The condition is either true or false. If it is true, the algorithm displays A. If it is false, it displays B. Only one of the two branches runs. Trace it with A = 8 and B = 12: the condition "8 is greater than 12" is false, so the algorithm displays 12, the larger number.

### Step 3: Repetition

**Repetition** (also called a loop) repeats some steps several times. Here is an algorithm that displays the numbers 1 to 5:

```text
Algorithm: Count from 1 to 5

1. Set counter to 1.
2. While counter is less than or equal to 5, repeat:
       a. Display counter.
       b. Add 1 to counter.
3. Display "Done".
```

Steps 2a and 2b run again and again while the condition "counter is less than or equal to 5" is true. Each time through, the counter grows by one, so eventually the condition becomes false and the loop stops. That is what makes the algorithm **finite**. If you forgot step 2b, the counter would stay at 1 forever and the algorithm would never end, which breaks the finiteness property.

| Round | counter before | Condition counter <= 5 | Displayed | counter after |
| --- | --- | --- | --- | --- |
| 1 | 1 | true | 1 | 2 |
| 2 | 2 | true | 2 | 3 |
| 3 | 3 | true | 3 | 4 |
| 4 | 4 | true | 4 | 5 |
| 5 | 5 | true | 5 | 6 |
| 6 | 6 | false | Done | |

Sequence, selection, and repetition are the whole toolbox. Modules 2, 3, and 4 of this course teach each of them in depth, first in algorithmic notation and then in Java.

---

## 6. Run and Test

You do not have a computer program to run yet, but you can still run your algorithms: on paper. Use the problem below to practice the full process from Section 4.

**Problem:** A student passes a course if their final score is 75 or higher. Given a score, display "PASS" or "FAIL".

First, name the parts:

| Part | Description |
| --- | --- |
| Input | The final score |
| Output | The text "PASS" or "FAIL" |
| Process | Compare the score with 75 |

Then write the algorithm:

```text
Algorithm: Check pass or fail

1. Read the score.
2. If the score is greater than or equal to 75, then
       display "PASS".
   Otherwise,
       display "FAIL".
```

Now trace it with three test values. Choose one value clearly above the limit, one clearly below, and one exactly on the limit, because the boundary is where mistakes usually hide:

| Test | score | Condition score >= 75 | Displayed | Expected | Correct? |
| --- | --- | --- | --- | --- | --- |
| 1 | 90 | true | PASS | PASS | Yes |
| 2 | 60 | false | FAIL | FAIL | Yes |
| 3 | 75 | true | PASS | PASS | Yes |

All three tests give the expected result, so the algorithm is ready to be turned into a program. Testing values on and around a boundary is a habit worth building now. You will use the same idea to test real Java programs later in the course.

---

## 7. Fix the Errors in Your Code

There is no code yet, but algorithms can have bugs too, and the bugs are exactly the same kinds you will meet in programs later. Here are the three most common ones.

**Error 1: Steps in the wrong order.**

```text
// Wrong
1. Calculate total = price x quantity.
2. Read the price.
3. Read the quantity.
4. Display the total.

// Correct
1. Read the price.
2. Read the quantity.
3. Calculate total = price x quantity.
4. Display the total.
```

In the wrong version, step 1 tries to multiply two values that have not been read yet. A computer runs steps strictly from top to bottom, so every value must be known *before* the step that uses it. When tracing, an empty cell in the table at the moment you need a value is a sign of this bug.

**Error 2: An unclear step.**

```text
// Wrong
1. Read the score.
2. If the score is good, display "PASS".

// Correct
1. Read the score.
2. If the score is greater than or equal to 75, then
       display "PASS".
   Otherwise,
       display "FAIL".
```

"Good" means different things to different people, so the wrong version breaks the definiteness property. It also forgets to say what happens when the score is not good. The correct version uses an exact comparison and handles both cases.

**Error 3: A loop that never ends.**

```text
// Wrong
1. Set counter to 1.
2. While counter is less than or equal to 5, repeat:
       a. Display counter.
3. Display "Done".

// Correct
1. Set counter to 1.
2. While counter is less than or equal to 5, repeat:
       a. Display counter.
       b. Add 1 to counter.
3. Display "Done".
```

In the wrong version, nothing inside the loop changes the counter, so the condition is true forever and step 3 is never reached. Every loop needs a step that moves it closer to stopping. In Java, this mistake produces a program that keeps running until you stop it by hand.

---

## 8. Exercises

Write each algorithm as numbered steps in plain English, then trace it with the test values given.

**Exercise 1:** Write an algorithm that reads the length and width of a rectangle and displays its area. Trace it with length 8 and width 5.

**Exercise 2:** Write an algorithm that reads a whole number and displays "EVEN" if it is even or "ODD" if it is odd. (Hint: a number is even when the remainder of dividing it by 2 is 0.) Trace it with 14 and 7.

**Exercise 3:** Write an algorithm that reads five numbers, one at a time, and displays their total. Use repetition instead of writing "read a number" five times. Trace it with the numbers 4, 10, 6, 2, and 8.

---

## 9. Solutions

**Solution for Exercise 1:**

```text
Algorithm: Rectangle area

1. Read the length.
2. Read the width.
3. Calculate area = length x width.
4. Display the area.
```

| Step | length | width | area | Displayed |
| --- | --- | --- | --- | --- |
| 1 | 8 | | | |
| 2 | 8 | 5 | | |
| 3 | 8 | 5 | 40 | |
| 4 | 8 | 5 | 40 | 40 |

This is a pure sequence: two inputs, one calculation, one output. The order matters because the area can only be calculated after both measurements are known.

**Solution for Exercise 2:**

```text
Algorithm: Even or odd

1. Read the number.
2. If the remainder of number divided by 2 equals 0, then
       display "EVEN".
   Otherwise,
       display "ODD".
```

| Test | number | Remainder of number / 2 | Condition remainder = 0 | Displayed |
| --- | --- | --- | --- | --- |
| 1 | 14 | 0 | true | EVEN |
| 2 | 7 | 1 | false | ODD |

The algorithm uses selection. The remainder after dividing by 2 is always either 0 or 1, so the two branches cover every whole number. In Java you will calculate this remainder with the `%` operator in Lesson 5.

**Solution for Exercise 3:**

```text
Algorithm: Total of five numbers

1. Set total to 0.
2. Set counter to 1.
3. While counter is less than or equal to 5, repeat:
       a. Read a number.
       b. Add the number to total.
       c. Add 1 to counter.
4. Display the total.
```

| Round | counter | Number read | total after |
| --- | --- | --- | --- |
| 1 | 1 | 4 | 4 |
| 2 | 2 | 10 | 14 |
| 3 | 3 | 6 | 20 |
| 4 | 4 | 2 | 22 |
| 5 | 5 | 8 | 30 |

After round 5 the counter becomes 6, the condition is false, and step 4 displays 30. Starting `total` at 0 is important: it gives the loop a known starting value to add to. This "start at zero, then add inside a loop" idea is called an accumulator, and you will use it many times in Lesson 11.

---

## Next Up - Lesson 2

In this lesson you learned that a program is a set of instructions for a computer, that an algorithm is the clear, finite list of steps behind it, and that every algorithm is built from sequence, selection, and repetition. You also practiced the most underrated skill in programming: tracing an algorithm by hand to test it before any code exists.

Plain English is a good start, but it can still be vague, and it looks different every time someone writes it. In Lesson 2 you will learn **algorithmic notation**, a structured way of writing algorithms with a Program section, a Dictionary section, and an Algorithm section. It is precise enough to translate almost line by line into Java, yet free of any language's syntax rules, and you will use it in every lesson from now on.
