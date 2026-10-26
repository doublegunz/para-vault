## 1. Before You Begin

You have reached the final project. Over twenty lessons you learned every building block this course set out to teach: sequence, selection, and repetition; procedures, functions, and recursion; arrays, strings, and records; searching and sorting. Now you will combine them into one complete application: a console **Student Grades** app that a teacher could actually use to record scores, calculate grades, find a student, rank the class, and see class statistics.

A program of this size should never be started by typing code. This lesson is about the stage that comes first: **design**. You will analyze the requirements, plan test data with expected results, design the data with records and arrays, break the work into subprograms, and write the complete algorithm in notation. You will also build a small Java prototype of the grading rules to check the design before building on it. In Lesson 22 you will turn this design into the finished Java program.

### What You'll Build

A complete design document for the Student Grades app, written as notation: the requirements, a test plan, the `Student` record type, the main menu algorithm, and every subprogram. You will also build and run `GradeRules.java`, a prototype that tests the grading rules against the test plan.

### What You'll Learn

- ✅ How to turn a problem description into clear requirements and rules
- ✅ How to plan test data and expected results before writing code
- ✅ How to design data with a record type and a partially filled array
- ✅ How to break an application into procedures and functions with clear contracts
- ✅ How to write a complete multi-subprogram algorithm in notation
- ✅ How to check a design with a small prototype and a desk check
- ✅ Common design mistakes and how to avoid them

### What You'll Need

- Lessons 1 to 20 completed, especially Lessons 13 (functions), 18 (records), 19 (searching), and 20 (sorting)
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-21
cd ~/java-basics/lesson-21
```

---

## 2. Analyze the Requirements

Every software project starts with a question: what exactly should the program do? Writing the answer down in precise terms is called **requirements analysis**. Vague requirements produce vague programs; precise requirements make the design almost write itself.

### Step 1: Write the Problem Statement and Features

Here is the problem in plain words, as a teacher might describe it:

> I teach a class of up to 50 students. For each student I record three scores: an assignment, a midterm exam, and a final exam. I want a program where I can add students, see everyone's final score and letter grade in a table, look up one student by name, rank the class from best to worst, and see a summary of how the class did.

From this, list the features the program must offer. Each one becomes an option in a menu:

| Option | Feature | Description |
| --- | --- | --- |
| 1 | Add a student | Read a name and three scores, and store the student |
| 2 | Show all students | Display a table with every student's scores, final score, and grade |
| 3 | Search for a student | Read a name and display that student's details, or say they were not found |
| 4 | Sort by final score | Rank the students from the highest final score to the lowest, then show the table |
| 5 | Class statistics | Show the class average, best and lowest student, how many passed, and how many got each grade |
| 6 | Exit | End the program |

The menu repeats until the user chooses Exit, which is the `repeat ... until` menu pattern from Lesson 10.

### Step 2: Define the Rules

Requirements also include the **rules** the program must follow. Each rule here must be exact enough to calculate by hand:

| Rule | Definition |
| --- | --- |
| Class size | At most 50 students |
| Score range | Each score is a whole number from 0 to 100; invalid input is asked again |
| Final score | 30% assignment + 30% midterm + 40% final exam |
| Letter grade | A: 85 and above, B: 70 to below 85, C: 55 to below 70, D: 40 to below 55, E: below 40 |
| Passing | A final score of 55 or more (grade C or better) |
| Name search | Not case sensitive: "citra dewi" finds "Citra Dewi" |
| Ranking ties | Students with the same final score keep the order in which they were added |
| Empty class | Options 2 to 5 display "No students yet." when there are no students |

Notice how much the rules decide in advance. The grade boundaries say whether 85 is an A or a B. The tie rule says the sort must be stable, which points to insertion sort from Lesson 20. The empty class rule warns you about a possible division by zero in the statistics.

### Step 3: Plan the Test Data

Before writing any algorithm, choose sample data and calculate the expected results by hand. These expected results become the answer key for testing in this lesson and the next.

| Name | Assignment | Midterm | Final exam | Final score (by hand) | Grade |
| --- | --- | --- | --- | --- | --- |
| Ani Lestari | 85 | 90 | 88 | 25.5 + 27.0 + 35.2 = 87.70 | A |
| Budi Santoso | 70 | 65 | 60 | 21.0 + 19.5 + 24.0 = 64.50 | C |
| Citra Dewi | 95 | 92 | 98 | 28.5 + 27.6 + 39.2 = 95.30 | A |
| Dodi Pratama | 40 | 55 | 35 | 12.0 + 16.5 + 14.0 = 42.50 | D |

From these four students, the expected statistics are:

| Statistic | Expected value |
| --- | --- |
| Class average | (87.70 + 64.50 + 95.30 + 42.50) / 4 = 72.50 |
| Best student | Citra Dewi (95.30) |
| Lowest student | Dodi Pratama (42.50) |
| Passed | 3 of 4 (everyone except Dodi) |
| Grade counts | A = 2, B = 0, C = 1, D = 1, E = 0 |
| Ranking | Citra, Ani, Budi, Dodi |

Two more test cases check the grade boundaries, where bugs like to hide (Lesson 7): a student with 55, 55, 55 should get exactly 55.00, a C; and a student with 15, 97, 16 should get exactly 40.00, a D (4.5 + 29.1 + 6.4 = 40.0). You will see in Section 6 why that second case is important.

---

## 3. Design the Data

With the requirements clear, decide how the program will store its data.

### Step 1: Define the Student Record

Each student has a name and three scores that always belong together, which is exactly what a record is for (Lesson 18):

```text
type Student : < name       : string,
                 assignment : integer,
                 midterm    : integer,
                 finalExam  : integer >
```

Notice what is *not* stored: the final score and the letter grade. Both can be calculated from the three scores at any time, so storing them would only create a risk of the stored value disagreeing with the scores. Calculating derived values with functions keeps the data consistent.

### Step 2: Store the Class in a Partially Filled Array

The class can have up to 50 students, but it starts empty and grows one student at a time. An array's length is fixed when it is created, so the design uses an array of the maximum size together with a counter:

```text
Dictionary
    constant MAX_STUDENTS : integer = 50
    students : array [0..MAX_STUDENTS-1] of Student
    count : integer          { how many elements of students are in use }
```

This is called a **partially filled array**. Only `students[0]` to `students[count - 1]` hold real students; the rest of the array is unused. The design follows three rules about `count`:

- It starts at 0.
- Adding a student stores the record at `students[count]`, then increases `count` by 1, and is only allowed while `count < MAX_STUDENTS`.
- Every loop over the class runs from 0 to `count - 1`, *never* to the end of the array.

Section 6 shows what happens when these rules are broken.

### Step 3: Prototype the Grading Rules

The final score and the letter grade are the heart of the app, and every feature depends on them. It is worth testing them on their own before building anything else. A small program that tests one piece of a design is called a **prototype**.

```text
Program GradeRules
{ Prototype of the Student record and the grading rules, tested with the planned test data }

Dictionary
    type Student : < name : string, assignment : integer, midterm : integer, finalExam : integer >
    testData : array [0..5] of Student = { < "Ani Lestari", 85, 90, 88 >,
                                           < "Budi Santoso", 70, 65, 60 >,
                                           < "Citra Dewi", 95, 92, 98 >,
                                           < "Dodi Pratama", 40, 55, 35 >,
                                           < "Boundary C", 55, 55, 55 >,
                                           < "Boundary D", 15, 97, 16 > }
    i : integer
    score : real
    function FinalScore(s : Student) -> real
    function LetterGrade(score : real) -> character

Algorithm
    for i <- 0 to 5 do
        score <- FinalScore(testData[i])
        output(testData[i].name, " ", score, "  ", LetterGrade(score))
    endfor

function FinalScore(s : Student) -> real
{ Returns the weighted final score: 30% assignment, 30% midterm, 40% final exam }
Algorithm
    -> (3 * s.assignment + 3 * s.midterm + 4 * s.finalExam) / 10

function LetterGrade(score : real) -> character
{ Returns the letter grade for a final score from 0 to 100 }
Algorithm
    if score >= 85 then
        -> 'A'
    else if score >= 70 then
        -> 'B'
    else if score >= 55 then
        -> 'C'
    else if score >= 40 then
        -> 'D'
    else
        -> 'E'
    endif
```

`FinalScore` multiplies by 3, 3, and 4 and then divides by 10, which is the same as multiplying by 0.3, 0.3, and 0.4. Writing it with whole numbers first is a deliberate choice, explained in Section 6. `LetterGrade` is the else-if chain from Lesson 8.

Create `GradeRules.java`:

```java
// Program GradeRules
// Prototype of the Student record and the grading rules, tested with the planned test data.
public class GradeRules {
    // Type Student
    record Student(String name, int assignment, int midterm, int finalExam) {}

    public static void main(String[] args) {
        // Dictionary
        Student[] testData = {
            new Student("Ani Lestari", 85, 90, 88),
            new Student("Budi Santoso", 70, 65, 60),
            new Student("Citra Dewi", 95, 92, 98),
            new Student("Dodi Pratama", 40, 55, 35),
            new Student("Boundary C", 55, 55, 55),
            new Student("Boundary D", 15, 97, 16)
        };
        double score;

        // Algorithm
        for (int i = 0; i < testData.length; i++) {
            score = finalScore(testData[i]);
            System.out.printf("%-14s %6.2f  %c%n", testData[i].name(), score, letterGrade(score));
        }
    }

    // Function FinalScore
    // Returns the weighted final score: 30% assignment, 30% midterm, 40% final exam
    static double finalScore(Student s) {
        return (3 * s.assignment() + 3 * s.midterm() + 4 * s.finalExam()) / 10.0;
    }

    // Function LetterGrade
    // Returns the letter grade for a final score from 0 to 100
    static char letterGrade(double score) {
        if (score >= 85) {
            return 'A';
        } else if (score >= 70) {
            return 'B';
        } else if (score >= 55) {
            return 'C';
        } else if (score >= 40) {
            return 'D';
        } else {
            return 'E';
        }
    }
}
```

In Java, `3 * s.assignment() + 3 * s.midterm() + 4 * s.finalExam()` is calculated with integers, and dividing by `10.0` (not `10`) makes the division real, so the decimal part is kept (Lesson 5). `%c` in `printf` displays a `char`.

```bash
javac GradeRules.java
java GradeRules
```

Output:

```text
Ani Lestari     87.70  A
Budi Santoso    64.50  C
Citra Dewi      95.30  A
Dodi Pratama    42.50  D
Boundary C      55.00  C
Boundary D      40.00  D
```

Every line matches the test plan from Section 2, including both boundary cases. The core rules are confirmed, and the rest of the design can safely build on them.

---

## 4. Design the Algorithm

Now break the application into subprograms. A good rule of thumb is one subprogram per job: each menu option becomes one subprogram, and any job used in several places (reading a valid number, calculating a final score) becomes its own function.

### Step 1: List the Subprograms and Their Contracts

| Subprogram | Kind | Contract |
| --- | --- | --- |
| `PrintMenu` | procedure | F.S.: the main menu is displayed |
| `ReadInRange(prompt, low, high) -> integer` | function | Asks until the user types a whole number from `low` to `high`, then returns it |
| `ReadStudent -> Student` | function | Reads a name and three valid scores, and returns them as a record |
| `FinalScore(s) -> real` | function | Returns the weighted final score of student `s` |
| `LetterGrade(score) -> character` | function | Returns the letter grade for a final score |
| `PrintTable(list, count)` | procedure | F.S.: the students are displayed as a table, or "No students yet." |
| `FindByName(list, count, name) -> integer` | function | Returns the index of the student with that name (ignoring case), or -1 |
| `SearchStudent(list, count)` | procedure | F.S.: a name is read and that student's details, or a message, are displayed |
| `SortByFinalScore(list, count)` | procedure | F.S.: the students are sorted from the highest final score to the lowest, ties kept in order |
| `PrintStatistics(list, count)` | procedure | F.S.: the class statistics, or "No students yet.", are displayed |

Every subprogram that works with the class receives both `list` and `count`, so it knows exactly which elements are in use. Many of these come straight from earlier lessons: `ReadInRange` from Lesson 13, `FindByName` from Lesson 19, and the stable insertion sort from Lesson 20.

### Step 2: Write the Main Algorithm

With the subprograms named, the main algorithm reads like a summary of the requirements:

```text
Program StudentGrades
{ A console app that stores students and their scores, calculates final scores and
  letter grades, and offers searching, sorting, and class statistics }

Dictionary
    type Student : < name : string, assignment : integer, midterm : integer, finalExam : integer >
    constant MAX_STUDENTS  : integer = 50
    constant PASSING_SCORE : real = 55.0
    students : array [0..MAX_STUDENTS-1] of Student
    count, choice : integer
    { subprograms: see the list in Step 1 }

Algorithm
    count <- 0
    repeat
        PrintMenu
        choice <- ReadInRange("Choice: ", 1, 6)
        depend on (choice)
            1 : if count = MAX_STUDENTS then
                    output("The class is full.")
                else
                    students[count] <- ReadStudent
                    count <- count + 1
                    output("Student added.")
                endif
            2 : PrintTable(students, count)
            3 : SearchStudent(students, count)
            4 : SortByFinalScore(students, count)
                output("Sorted from the highest final score to the lowest.")
                PrintTable(students, count)
            5 : PrintStatistics(students, count)
            6 : output("Goodbye!")
        enddepend
    until choice = 6
```

There is no `otherwise` case, because `ReadInRange` guarantees that `choice` is between 1 and 6. Option 1 follows the partially filled array rules exactly: check that there is room, store at `students[count]`, then increase `count`.

### Step 3: Write the Subprograms

Here is the notation for every subprogram. Read each one against its contract from Step 1.

```text
procedure PrintMenu
{ I.S.: - }
{ F.S.: the main menu is displayed }
Algorithm
    output("===== STUDENT GRADES =====")
    output("1. Add a student")
    output("2. Show all students")
    output("3. Search for a student")
    output("4. Sort by final score")
    output("5. Class statistics")
    output("6. Exit")

function ReadInRange(prompt : string, low : integer, high : integer) -> integer
{ Asks with prompt until the user types an integer from low to high, then returns it }
Dictionary
    value : integer
Algorithm
    repeat
        output(prompt)
        input(value)
        if value < low or value > high then
            output("Please enter a number from ", low, " to ", high, ".")
        endif
    until value >= low and value <= high
    -> value

function ReadStudent -> Student
{ Reads a student's name and three scores (0-100) and returns them as a record }
Dictionary
    name : string
    assignment, midterm, finalExam : integer
Algorithm
    output("Name            : ")
    input(name)
    assignment <- ReadInRange("Assignment score: ", 0, 100)
    midterm <- ReadInRange("Midterm score   : ", 0, 100)
    finalExam <- ReadInRange("Final exam score: ", 0, 100)
    -> < name, assignment, midterm, finalExam >

procedure PrintTable(input list : array of Student, input count : integer)
{ I.S.: list[0..count-1] holds the students }
{ F.S.: the students are displayed as a table with their final scores and grades }
Dictionary
    i : integer
    score : real
Algorithm
    if count = 0 then
        output("No students yet.")
    else
        output("No  Name  Asg  Mid  Fin  Score  Grade")
        for i <- 0 to count - 1 do
            score <- FinalScore(list[i])
            output(i + 1, list[i].name, list[i].assignment, list[i].midterm,
                   list[i].finalExam, score, LetterGrade(score))
        endfor
    endif

function FindByName(list : array of Student, count : integer, name : string) -> integer
{ Returns the index of the student named name in list[0..count-1] (ignoring case), or -1 }
Dictionary
    i : integer
Algorithm
    for i <- 0 to count - 1 do
        if lower(list[i].name) = lower(name) then
            -> i
        endif
    endfor
    -> -1

procedure SearchStudent(input list : array of Student, input count : integer)
{ I.S.: list[0..count-1] holds the students }
{ F.S.: a name is read and the matching student's details, or a message, are displayed }
Dictionary
    name : string
    position : integer
    score : real
Algorithm
    output("Name to search: ")
    input(name)
    position <- FindByName(list, count, name)
    if position = -1 then
        output("No student named ", name, ".")
    else
        score <- FinalScore(list[position])
        output("Name       : ", list[position].name)
        output("Assignment : ", list[position].assignment)
        output("Midterm    : ", list[position].midterm)
        output("Final exam : ", list[position].finalExam)
        output("Final score: ", score, " (grade ", LetterGrade(score), ")")
    endif

procedure SortByFinalScore(input/output list : array of Student, input count : integer)
{ I.S.: list[0..count-1] holds the students }
{ F.S.: list[0..count-1] is sorted from the highest final score to the lowest
        (insertion sort, so students with equal scores keep their order) }
Dictionary
    i, j : integer
    key : Student
Algorithm
    for i <- 1 to count - 1 do
        key <- list[i]
        j <- i - 1
        while j >= 0 and FinalScore(list[j]) < FinalScore(key) do
            list[j + 1] <- list[j]
            j <- j - 1
        endwhile
        list[j + 1] <- key
    endfor

procedure PrintStatistics(input list : array of Student, input count : integer)
{ I.S.: list[0..count-1] holds the students }
{ F.S.: the class average, best and lowest student, grade counts, and pass count are displayed }
Dictionary
    i, g, best, lowest, passed : integer
    total, score : real
    gradeCount : array [0..4] of integer = {0, 0, 0, 0, 0}     { A, B, C, D, E }
Algorithm
    if count = 0 then
        output("No students yet.")
    else
        total <- 0
        best <- 0
        lowest <- 0
        passed <- 0
        for i <- 0 to count - 1 do
            score <- FinalScore(list[i])
            total <- total + score
            if score > FinalScore(list[best]) then
                best <- i
            endif
            if score < FinalScore(list[lowest]) then
                lowest <- i
            endif
            if score >= PASSING_SCORE then
                passed <- passed + 1
            endif
            gradeCount[ord(LetterGrade(score)) - ord('A')] <- gradeCount[ord(LetterGrade(score)) - ord('A')] + 1
        endfor
        output("Students      : ", count)
        output("Class average : ", total / count)
        output("Best student  : ", list[best].name, " (", FinalScore(list[best]), ")")
        output("Lowest student: ", list[lowest].name, " (", FinalScore(list[lowest]), ")")
        output("Passed        : ", passed, " of ", count)
        output("Grades        :")
        for g <- 0 to 4 do
            output(" ", chr(ord('A') + g), "=", gradeCount[g])
        endfor
    endif
```

`PrintStatistics` combines four loop patterns from Lesson 11 in one pass: an accumulator (`total`), two extreme values (`best`, `lowest`), and a counter (`passed`). The grade counts use the counting array idea from the dice exercise in Lesson 15: the letter's distance from `'A'` (0 for A, 4 for E) is the index of its counter. The check `count = 0` at the start protects the average from a division by zero, as the "empty class" rule requires.

---

## 5. Run and Test

Before writing the full program in Lesson 22, check the design by **desk checking**: tracing the parts that are hardest to get right with the test data, the same way you traced loops by hand in Lesson 9.

The trickiest part is `SortByFinalScore`. The students are added in this order, with these final scores (already confirmed by the prototype):

| Index | Name | Final score |
| --- | --- | --- |
| 0 | Ani Lestari | 87.70 |
| 1 | Budi Santoso | 64.50 |
| 2 | Citra Dewi | 95.30 |
| 3 | Dodi Pratama | 42.50 |

Trace the insertion sort, writing the order of the array after each pass:

| Pass (i) | Key | What happens | Array after the pass |
| --- | --- | --- | --- |
| 1 | Budi (64.50) | Ani (87.70) is not lower than 64.50, so Budi stays | Ani, Budi, Citra, Dodi |
| 2 | Citra (95.30) | Budi and Ani are both lower, so both shift right; Citra goes to index 0 | Citra, Ani, Budi, Dodi |
| 3 | Dodi (42.50) | Budi (64.50) is not lower, so Dodi stays | Citra, Ani, Budi, Dodi |

The result, Citra, Ani, Budi, Dodi, matches the expected ranking in the test plan. Next, trace `PrintStatistics` on the same four students:

| i | Name | score | total | best | lowest | passed | Grade counted |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | Ani | 87.70 | 87.70 | 0 | 0 | 1 | A |
| 1 | Budi | 64.50 | 152.20 | 0 | 1 | 2 | C |
| 2 | Citra | 95.30 | 247.50 | 2 | 1 | 3 | A |
| 3 | Dodi | 42.50 | 290.00 | 2 | 3 | 3 | D |

After the loop, the average is 290.00 / 4 = 72.50, the best student is index 2 (Citra), the lowest is index 3 (Dodi), 3 students passed, and the grade counts are A = 2, C = 1, D = 1. Every value matches the test plan. The design is ready to be built.

Desk checking takes a few minutes and catches design mistakes while they are still cheap to fix: changing a line of notation is much easier than debugging a 200-line program.

---

## 6. Fix the Errors in Your Code

These mistakes are design decisions that look reasonable but cause bugs later. Each one is shown with a small Java program, so you can see the real effect.

**Error 1: Calculating the final score with decimal weights.**

The most natural way to write the formula is `0.3 * assignment + 0.3 * midterm + 0.4 * finalExam`. Try it in the prototype:

```java
// Wrong
static double finalScore(Student s) {
    return 0.3 * s.assignment() + 0.3 * s.midterm() + 0.4 * s.finalExam();
}

// Correct
static double finalScore(Student s) {
    return (3 * s.assignment() + 3 * s.midterm() + 4 * s.finalExam()) / 10.0;
}
```

With the wrong version, `GradeRules` displays:

```text
Ani Lestari     87.70  A
Budi Santoso    64.50  C
Citra Dewi      95.30  A
Dodi Pratama    42.50  D
Boundary C      55.00  C
Boundary D      40.00  E
```

The last line says the score is 40.00 but the grade is E, which contradicts the rules. As you saw in Lesson 5, values like 0.3 cannot be stored exactly in binary, so the calculation produces 39.99999999999999 instead of 40. `printf` rounds it to `40.00` for display, but the comparison `score >= 40` sees the real value and fails. A test of every possible combination of three scores from 0 to 100 shows this happens for 214 different combinations, all near a grade boundary. Multiplying by whole numbers first keeps the sum exact, and a single division by 10.0 gives a result that lands exactly on 40.0, 55.0, 70.0, or 85.0 when it should. This is why the test plan includes boundary cases: without "Boundary D," the bug would have gone unnoticed.

**Error 2: Looping to the end of the array instead of to `count`.**

```java
// Wrong
public class LengthNotCount {
    record Student(String name, int assignment, int midterm, int finalExam) {}

    public static void main(String[] args) {
        Student[] students = new Student[5];
        int count = 0;
        students[count] = new Student("Ani Lestari", 85, 90, 88);
        count = count + 1;
        students[count] = new Student("Budi Santoso", 70, 65, 60);
        count = count + 1;
        for (int i = 0; i < students.length; i++) {
            System.out.println(students[i].name());
        }
    }
}

// Correct
public class LengthNotCount {
    record Student(String name, int assignment, int midterm, int finalExam) {}

    public static void main(String[] args) {
        Student[] students = new Student[5];
        int count = 0;
        students[count] = new Student("Ani Lestari", 85, 90, 88);
        count = count + 1;
        students[count] = new Student("Budi Santoso", 70, 65, 60);
        count = count + 1;
        for (int i = 0; i < count; i++) {
            System.out.println(students[i].name());
        }
    }
}
```

The wrong version displays two names and then crashes:

```text
Ani Lestari
Budi Santoso
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "LengthNotCount$Student.name()" because "<local1>[<local3>]" is null
	at LengthNotCount.main(LengthNotCount.java:12)
```

In a partially filled array, the elements after `count - 1` are empty (`null`, as in Lesson 18). `students.length` is the *capacity* of the array, not the number of students. Every loop over the class must use `count`, which is why every subprogram in the design receives it as a parameter.

**Error 3: Adding a student without checking whether the class is full.**

```java
// Wrong
public class ClassFull {
    record Student(String name, int assignment, int midterm, int finalExam) {}

    public static void main(String[] args) {
        final int MAX_STUDENTS = 2;
        Student[] students = new Student[MAX_STUDENTS];
        int count = 0;
        String[] names = {"Ani", "Budi", "Citra"};
        for (int i = 0; i < names.length; i++) {
            students[count] = new Student(names[i], 80, 80, 80);
            count = count + 1;
            System.out.println("Added " + names[i]);
        }
    }
}

// Correct
public class ClassFull {
    record Student(String name, int assignment, int midterm, int finalExam) {}

    public static void main(String[] args) {
        final int MAX_STUDENTS = 2;
        Student[] students = new Student[MAX_STUDENTS];
        int count = 0;
        String[] names = {"Ani", "Budi", "Citra"};
        for (int i = 0; i < names.length; i++) {
            if (count == MAX_STUDENTS) {
                System.out.println("The class is full.");
            } else {
                students[count] = new Student(names[i], 80, 80, 80);
                count = count + 1;
                System.out.println("Added " + names[i]);
            }
        }
    }
}
```

With a capacity of 2 to make the problem easy to see, the wrong version crashes on the third student:

```text
Added Ani
Added Budi
Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index 2 out of bounds for length 2
	at ClassFull.main(ClassFull.java:10)
```

When `count` equals the capacity, `students[count]` is one position past the end. The design's option 1 checks `count = MAX_STUDENTS` first and refuses politely instead of crashing. A requirement such as "at most 50 students" always implies a check like this somewhere in the algorithm.

---

## 7. Exercises

These exercises extend the design. For each one, write the notation, then check your design with a small Java prototype, as `GradeRules` did.

**Exercise 1:** Design a function `DeleteAt(list : array of Student, count : integer, index : integer) -> integer` that removes the student at `index` from the partially filled array by shifting every following student one place to the left, and returns the new count. Prototype it by deleting a student from the middle and then the last student.

**Exercise 2:** Design a procedure `EditScores(input/output list : array of Student, input index : integer, input assignment : integer, input midterm : integer, input finalExam : integer)` that replaces the scores of the student at `index`, keeping the same name. Remember that Java records cannot be changed (Lesson 18).

**Exercise 3:** Design a procedure `PrintFailed(input list : array of Student, input count : integer)` that lists the name and final score of every student below the passing score, or displays "None. Everyone passed!" if there are none.

---

## 8. Solutions

**Solution for Exercise 1:**

```text
function DeleteAt(list : array of Student, count : integer, index : integer) -> integer
{ Removes list[index] by shifting the following students one place left; returns the new count }
Dictionary
    i : integer
Algorithm
    for i <- index to count - 2 do
        list[i] <- list[i + 1]
    endfor
    list[count - 1] <- empty
    -> count - 1
```

```java
// Program DeleteDemo
// Prototype of deleting a student from a partially filled array by shifting the rest left.
public class DeleteDemo {
    // Type Student
    record Student(String name, int assignment, int midterm, int finalExam) {}

    public static void main(String[] args) {
        // Dictionary
        Student[] students = new Student[5];
        int count;

        // Algorithm
        students[0] = new Student("Ani Lestari", 85, 90, 88);
        students[1] = new Student("Budi Santoso", 70, 65, 60);
        students[2] = new Student("Citra Dewi", 95, 92, 98);
        students[3] = new Student("Dodi Pratama", 40, 55, 35);
        count = 4;
        printNames(students, count);
        count = deleteAt(students, count, 1);
        printNames(students, count);
        count = deleteAt(students, count, count - 1);
        printNames(students, count);
    }

    // Function DeleteAt
    // Removes list[index] by shifting the following students one place left; returns the new count
    static int deleteAt(Student[] list, int count, int index) {
        for (int i = index; i < count - 1; i++) {
            list[i] = list[i + 1];
        }
        list[count - 1] = null;
        return count - 1;
    }

    // Procedure PrintNames
    // I.S.: list[0..count-1] holds the students
    // F.S.: the count and the names are displayed on one line
    static void printNames(Student[] list, int count) {
        System.out.print(count + " students:");
        for (int i = 0; i < count; i++) {
            System.out.print(" [" + list[i].name() + "]");
        }
        System.out.println();
    }
}
```

Deleting from the middle leaves a gap, and the loop closes it by copying each later student one place to the left, keeping the order. The last used slot is cleared with `null` (`empty` in notation). Why a function and not a procedure? The array's elements can be changed inside a subprogram (Lesson 15), but `count` is a simple `int`, passed by value (Lesson 12), so the subprogram cannot change the caller's `count`. Returning the new count and assigning it, `count = deleteAt(...)`, solves this.

```bash
javac DeleteDemo.java
java DeleteDemo
```

Output:

```text
4 students: [Ani Lestari] [Budi Santoso] [Citra Dewi] [Dodi Pratama]
3 students: [Ani Lestari] [Citra Dewi] [Dodi Pratama]
2 students: [Ani Lestari] [Citra Dewi]
```

Deleting the last student is an edge case: the loop runs zero times and only the count changes.

**Solution for Exercise 2:**

```text
procedure EditScores(input/output list : array of Student, input index : integer,
                     input assignment : integer, input midterm : integer, input finalExam : integer)
{ I.S.: list[index] holds a student }
{ F.S.: list[index] holds the same name with the new scores }
Algorithm
    list[index] <- < list[index].name, assignment, midterm, finalExam >
```

```java
// Program EditDemo
// Prototype of changing a student's scores by replacing the record in the array.
public class EditDemo {
    // Type Student
    record Student(String name, int assignment, int midterm, int finalExam) {}

    public static void main(String[] args) {
        // Dictionary
        Student[] students = new Student[5];
        int count;

        // Algorithm
        students[0] = new Student("Ani Lestari", 85, 90, 88);
        students[1] = new Student("Budi Santoso", 70, 65, 60);
        count = 2;
        System.out.println("Before: " + students[1]);
        editScores(students, 1, 75, 80, 72);
        System.out.println("After : " + students[1]);
        System.out.println("Count : " + count);
    }

    // Procedure EditScores
    // I.S.: list[index] holds a student
    // F.S.: list[index] holds the same name with the new scores
    static void editScores(Student[] list, int index, int assignment, int midterm, int finalExam) {
        list[index] = new Student(list[index].name(), assignment, midterm, finalExam);
    }
}
```

A record cannot be modified, but the *array element* can be replaced with a new record. The new record copies the old name and takes the new scores, the same "update by replacing" technique as `WithDiscount` in Lesson 18. Because only an array element changes, a procedure is enough, and the count stays the same.

```bash
javac EditDemo.java
java EditDemo
```

Output:

```text
Before: Student[name=Budi Santoso, assignment=70, midterm=65, finalExam=60]
After : Student[name=Budi Santoso, assignment=75, midterm=80, finalExam=72]
Count : 2
```

**Solution for Exercise 3:**

```text
procedure PrintFailed(input list : array of Student, input count : integer)
{ I.S.: list[0..count-1] holds the students }
{ F.S.: the students below the passing score are displayed, or a message if there are none }
Dictionary
    i, failed : integer
Algorithm
    failed <- 0
    output("Students below ", PASSING_SCORE, ":")
    for i <- 0 to count - 1 do
        if FinalScore(list[i]) < PASSING_SCORE then
            output("  ", list[i].name, " ", FinalScore(list[i]))
            failed <- failed + 1
        endif
    endfor
    if failed = 0 then
        output("  None. Everyone passed!")
    endif
```

```java
// Program FailedDemo
// Prototype of listing the students whose final score is below the passing score.
public class FailedDemo {
    // Type Student
    record Student(String name, int assignment, int midterm, int finalExam) {}

    static final double PASSING_SCORE = 55.0;

    public static void main(String[] args) {
        // Dictionary
        Student[] students = new Student[5];
        int count;

        // Algorithm
        students[0] = new Student("Ani Lestari", 85, 90, 88);
        students[1] = new Student("Budi Santoso", 70, 65, 60);
        students[2] = new Student("Citra Dewi", 95, 92, 98);
        students[3] = new Student("Dodi Pratama", 40, 55, 35);
        students[4] = new Student("Eka Putri", 50, 52, 49);
        count = 5;
        printFailed(students, count);
    }

    // Function FinalScore
    // Returns the weighted final score: 30% assignment, 30% midterm, 40% final exam
    static double finalScore(Student s) {
        return (3 * s.assignment() + 3 * s.midterm() + 4 * s.finalExam()) / 10.0;
    }

    // Procedure PrintFailed
    // I.S.: list[0..count-1] holds the students
    // F.S.: the students below the passing score are displayed, or a message if there are none
    static void printFailed(Student[] list, int count) {
        int failed = 0;
        System.out.println("Students below " + PASSING_SCORE + ":");
        for (int i = 0; i < count; i++) {
            if (finalScore(list[i]) < PASSING_SCORE) {
                System.out.printf("  %-15s %6.2f%n", list[i].name(), finalScore(list[i]));
                failed = failed + 1;
            }
        }
        if (failed == 0) {
            System.out.println("  None. Everyone passed!");
        }
    }
}
```

This is a filter (Lesson 11) with a counter that is only used to decide whether to show the "None" message. `PASSING_SCORE` is declared with `static final` at the class level, outside `main`, so every method can use it. This is how Java shares a constant across the whole program, the same idea as the shared variable in the Fibonacci program of Lesson 14, but safe, because a constant can never be changed. The test data adds a fifth student, Eka, so that two students fail.

```bash
javac FailedDemo.java
java FailedDemo
```

Output:

```text
Students below 55.0:
  Dodi Pratama     42.50
  Eka Putri        50.20
```

---

## Next Up - Lesson 22

In this lesson you designed a complete application before writing it. You turned a teacher's description into numbered features and exact rules, planned test data with hand-calculated answers, designed the data as a `Student` record in a partially filled array with a `count`, divided the work into subprograms with clear contracts, and wrote the whole algorithm in notation. A prototype confirmed the grading rules, a desk check confirmed the sort and the statistics, and the boundary test exposed a floating-point bug before it could reach the real program.

In Lesson 22 you will build the Student Grades app in Java. Because the design is finished, the implementation is mostly translation: each notation subprogram becomes a Java method. You will build it in two stages, test it against the test plan from this lesson, and then extend it with new features.
