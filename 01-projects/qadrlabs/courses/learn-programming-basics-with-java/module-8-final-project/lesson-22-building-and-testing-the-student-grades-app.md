## 1. Before You Begin

In Lesson 21 you designed the Student Grades app from top to bottom: the requirements and rules, a test plan with hand-calculated answers, the `Student` record and the partially filled array, the main menu algorithm, and every subprogram in notation. You also proved the grading rules with a prototype and desk checked the sort and the statistics.

Now you will build it. Because the design is finished, this lesson is mostly *translation*: each notation subprogram becomes a Java method, using exactly the mappings you have practiced since Lesson 3. You will build the app in two stages. First, a working skeleton with the menu, adding students, and the table. Then the complete app with searching, sorting, and statistics. After that, you will test it against the test plan, fix the integration bugs that commonly appear when pieces are joined together, and extend the app with new features.

### What You'll Build

`StudentGrades.java`, a complete console application with a menu to add students with validated scores, display a table of final scores and letter grades, search for a student by name, rank the class by final score, and show class statistics. In the exercises, you will add deleting a student, sorting by name, and protection against duplicate names.

### What You'll Learn

- ✅ How to turn a notation design into a complete Java program
- ✅ How to build a larger program in stages, testing each stage
- ✅ How to share constants across methods with `static final`
- ✅ How to keep `Scanner` input reliable when mixing numbers and text
- ✅ How to test a whole application against a test plan
- ✅ How to find and fix integration bugs
- ✅ How to extend a working program with new features safely

### What You'll Need

- Lesson 21 completed, with its design notation at hand
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-22
cd ~/java-basics/lesson-22
```

---

## 2. Build the Skeleton

A large program should never be typed in one go and compiled for the first time at the end. If it fails, the error could be anywhere. Instead, build a small part that runs, test it, and grow it. The first stage contains everything needed to add students and see them in a table: the record, the menu loop, `ReadInRange`, `ReadStudent`, `FinalScore`, `LetterGrade`, and `PrintTable`. Options 3, 4, and 5 simply say "Not available yet."

Here is how the notation maps to Java in this program:

| Notation (Lesson 21) | Java |
| --- | --- |
| `type Student : < name : string, ... >` | `record Student(String name, ...) {}` inside the class |
| `constant MAX_STUDENTS : integer = 50` used by several subprograms | `static final int MAX_STUDENTS = 50;` at the class level |
| `repeat ... until choice = 6` | `do { ... } while (choice != 6);` |
| `depend on (choice)` | `switch (choice)` with arrow cases |
| `procedure Name(...)` | `static void name(...)` |
| `function Name(...) -> type` | `static type name(...)` |

### Step 1: Write the Skeleton

Create `StudentGrades.java`:

```java
import java.util.Scanner;

// Program StudentGrades
// A console app that stores students and their scores, calculates final scores and
// letter grades, and offers searching, sorting, and class statistics.
public class StudentGrades {
    // Type Student
    record Student(String name, int assignment, int midterm, int finalExam) {}

    // Constants shared by the whole program
    static final int MAX_STUDENTS = 50;

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        Student[] students = new Student[MAX_STUDENTS];
        int count = 0;
        int choice;

        // Algorithm
        do {
            printMenu();
            choice = readInRange(input, "Choice: ", 1, 6);
            switch (choice) {
                case 1 -> {
                    if (count == MAX_STUDENTS) {
                        System.out.println("The class is full.");
                    } else {
                        students[count] = readStudent(input);
                        count = count + 1;
                        System.out.println("Student added.");
                    }
                }
                case 2 -> printTable(students, count);
                case 3, 4, 5 -> System.out.println("Not available yet.");
                case 6 -> System.out.println("Goodbye!");
            }
        } while (choice != 6);
    }

    // Procedure PrintMenu
    // I.S.: -
    // F.S.: the main menu is displayed
    static void printMenu() {
        System.out.println();
        System.out.println("===== STUDENT GRADES =====");
        System.out.println("1. Add a student");
        System.out.println("2. Show all students");
        System.out.println("3. Search for a student");
        System.out.println("4. Sort by final score");
        System.out.println("5. Class statistics");
        System.out.println("6. Exit");
    }

    // Function ReadInRange
    // Asks with prompt until the user types an integer from low to high, then returns it
    static int readInRange(Scanner input, String prompt, int low, int high) {
        int value;
        do {
            System.out.print(prompt);
            value = input.nextInt();
            input.nextLine();
            if (value < low || value > high) {
                System.out.println("Please enter a number from " + low + " to " + high + ".");
            }
        } while (value < low || value > high);
        return value;
    }

    // Function ReadStudent
    // Reads a student's name and three scores (0-100) and returns them as a record
    static Student readStudent(Scanner input) {
        String name;
        int assignment;
        int midterm;
        int finalExam;
        System.out.print("Name            : ");
        name = input.nextLine();
        assignment = readInRange(input, "Assignment score: ", 0, 100);
        midterm = readInRange(input, "Midterm score   : ", 0, 100);
        finalExam = readInRange(input, "Final exam score: ", 0, 100);
        return new Student(name, assignment, midterm, finalExam);
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

    // Procedure PrintTable
    // I.S.: list[0..count-1] holds the students
    // F.S.: the students are displayed as a table with their final scores and grades
    static void printTable(Student[] list, int count) {
        double score;
        if (count == 0) {
            System.out.println("No students yet.");
        } else {
            System.out.printf("%-3s %-15s %5s %5s %5s %7s %6s%n",
                    "No", "Name", "Asg", "Mid", "Fin", "Score", "Grade");
            for (int i = 0; i < count; i++) {
                score = finalScore(list[i]);
                System.out.printf("%-3d %-15s %5d %5d %5d %7.2f %6c%n", i + 1, list[i].name(),
                        list[i].assignment(), list[i].midterm(), list[i].finalExam(),
                        score, letterGrade(score));
            }
        }
    }
}
```

Most of this is a direct copy of the design, but a few Java details deserve attention:

- **`static final int MAX_STUDENTS = 50;`** is declared at the class level, outside `main`, so that every method can use it. `static` makes it belong to the program as a whole (like the methods), and `final` makes it a constant. You used the same idea for `PASSING_SCORE` in the last exercise of Lesson 21.
- **`case 3, 4, 5 -> ...`** handles three menu options with one case (Lesson 8). They will get real code in the next stage.
- **`input.nextLine()` right after `input.nextInt()` in `readInRange`** is the most important line for reliable input. Every number in this program is read through `readInRange`, and this extra call throws away the end of line that `nextInt` leaves behind (Lesson 6). Because of it, the `nextLine` that reads a student's name always waits for the user, even right after the menu choice. Section 5 shows what happens without it.
- **`printf` with `%6c`** displays the `char` grade right aligned in a 6 character column, so it sits under the "Grade" heading.

### Step 2: Compile and Test the Skeleton

```bash
javac StudentGrades.java
java StudentGrades
```

Add two students, typing an invalid midterm score for the second one, then show the table, try an unfinished option, and exit.

Output:

```text

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 1
Name            : Ani Lestari
Assignment score: 85
Midterm score   : 90
Final exam score: 88
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 1
Name            : Budi Santoso
Assignment score: 70
Midterm score   : 105
Please enter a number from 0 to 100.
Midterm score   : 65
Final exam score: 60
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 2
No  Name              Asg   Mid   Fin   Score  Grade
1   Ani Lestari        85    90    88   87.70      A
2   Budi Santoso       70    65    60   64.50      C

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 4
Not available yet.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 6
Goodbye!
```

The skeleton already works end to end: the menu repeats, names with spaces are read correctly, the invalid score of 105 was rejected and asked again, and both final scores match the test plan (87.70 and 64.50). With this solid base, the remaining features can be added with confidence.

---

## 3. Complete the App

The second stage adds the four remaining subprograms from the design: `FindByName`, `SearchStudent`, `SortByFinalScore`, and `PrintStatistics`, plus the `PASSING_SCORE` constant that the statistics need. The `main` method changes only in its `switch`: cases 3, 4, and 5 now call the new subprograms.

### Step 1: Write the Complete Program

Replace the contents of `StudentGrades.java` with the complete version:

```java
import java.util.Scanner;

// Program StudentGrades
// A console app that stores students and their scores, calculates final scores and
// letter grades, and offers searching, sorting, and class statistics.
public class StudentGrades {
    // Type Student
    record Student(String name, int assignment, int midterm, int finalExam) {}

    // Constants shared by the whole program
    static final int MAX_STUDENTS = 50;
    static final double PASSING_SCORE = 55.0;

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        Student[] students = new Student[MAX_STUDENTS];
        int count = 0;
        int choice;

        // Algorithm
        do {
            printMenu();
            choice = readInRange(input, "Choice: ", 1, 6);
            switch (choice) {
                case 1 -> {
                    if (count == MAX_STUDENTS) {
                        System.out.println("The class is full.");
                    } else {
                        students[count] = readStudent(input);
                        count = count + 1;
                        System.out.println("Student added.");
                    }
                }
                case 2 -> printTable(students, count);
                case 3 -> searchStudent(input, students, count);
                case 4 -> {
                    sortByFinalScore(students, count);
                    System.out.println("Sorted from the highest final score to the lowest.");
                    printTable(students, count);
                }
                case 5 -> printStatistics(students, count);
                case 6 -> System.out.println("Goodbye!");
            }
        } while (choice != 6);
    }

    // Procedure PrintMenu
    // I.S.: -
    // F.S.: the main menu is displayed
    static void printMenu() {
        System.out.println();
        System.out.println("===== STUDENT GRADES =====");
        System.out.println("1. Add a student");
        System.out.println("2. Show all students");
        System.out.println("3. Search for a student");
        System.out.println("4. Sort by final score");
        System.out.println("5. Class statistics");
        System.out.println("6. Exit");
    }

    // Function ReadInRange
    // Asks with prompt until the user types an integer from low to high, then returns it
    static int readInRange(Scanner input, String prompt, int low, int high) {
        int value;
        do {
            System.out.print(prompt);
            value = input.nextInt();
            input.nextLine();
            if (value < low || value > high) {
                System.out.println("Please enter a number from " + low + " to " + high + ".");
            }
        } while (value < low || value > high);
        return value;
    }

    // Function ReadStudent
    // Reads a student's name and three scores (0-100) and returns them as a record
    static Student readStudent(Scanner input) {
        String name;
        int assignment;
        int midterm;
        int finalExam;
        System.out.print("Name            : ");
        name = input.nextLine();
        assignment = readInRange(input, "Assignment score: ", 0, 100);
        midterm = readInRange(input, "Midterm score   : ", 0, 100);
        finalExam = readInRange(input, "Final exam score: ", 0, 100);
        return new Student(name, assignment, midterm, finalExam);
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

    // Procedure PrintTable
    // I.S.: list[0..count-1] holds the students
    // F.S.: the students are displayed as a table with their final scores and grades
    static void printTable(Student[] list, int count) {
        double score;
        if (count == 0) {
            System.out.println("No students yet.");
        } else {
            System.out.printf("%-3s %-15s %5s %5s %5s %7s %6s%n",
                    "No", "Name", "Asg", "Mid", "Fin", "Score", "Grade");
            for (int i = 0; i < count; i++) {
                score = finalScore(list[i]);
                System.out.printf("%-3d %-15s %5d %5d %5d %7.2f %6c%n", i + 1, list[i].name(),
                        list[i].assignment(), list[i].midterm(), list[i].finalExam(),
                        score, letterGrade(score));
            }
        }
    }

    // Function FindByName
    // Returns the index of the student named name in list[0..count-1] (ignoring case), or -1
    static int findByName(Student[] list, int count, String name) {
        for (int i = 0; i < count; i++) {
            if (list[i].name().equalsIgnoreCase(name)) {
                return i;
            }
        }
        return -1;
    }

    // Procedure SearchStudent
    // I.S.: list[0..count-1] holds the students
    // F.S.: a name is read and the matching student's details, or a message, are displayed
    static void searchStudent(Scanner input, Student[] list, int count) {
        String name;
        int position;
        double score;
        System.out.print("Name to search: ");
        name = input.nextLine();
        position = findByName(list, count, name);
        if (position == -1) {
            System.out.println("No student named " + name + ".");
        } else {
            score = finalScore(list[position]);
            System.out.println("Name       : " + list[position].name());
            System.out.println("Assignment : " + list[position].assignment());
            System.out.println("Midterm    : " + list[position].midterm());
            System.out.println("Final exam : " + list[position].finalExam());
            System.out.printf("Final score: %.2f (grade %c)%n", score, letterGrade(score));
        }
    }

    // Procedure SortByFinalScore
    // I.S.: list[0..count-1] holds the students
    // F.S.: list[0..count-1] is sorted from the highest final score to the lowest
    //       (insertion sort, so students with equal scores keep their order)
    static void sortByFinalScore(Student[] list, int count) {
        Student key;
        int j;
        for (int i = 1; i < count; i++) {
            key = list[i];
            j = i - 1;
            while (j >= 0 && finalScore(list[j]) < finalScore(key)) {
                list[j + 1] = list[j];
                j = j - 1;
            }
            list[j + 1] = key;
        }
    }

    // Procedure PrintStatistics
    // I.S.: list[0..count-1] holds the students
    // F.S.: the class average, best and lowest student, grade counts, and pass count are displayed
    static void printStatistics(Student[] list, int count) {
        double total;
        double score;
        int best;
        int lowest;
        int passed;
        int[] gradeCount = new int[5];
        if (count == 0) {
            System.out.println("No students yet.");
        } else {
            total = 0;
            best = 0;
            lowest = 0;
            passed = 0;
            for (int i = 0; i < count; i++) {
                score = finalScore(list[i]);
                total = total + score;
                if (score > finalScore(list[best])) {
                    best = i;
                }
                if (score < finalScore(list[lowest])) {
                    lowest = i;
                }
                if (score >= PASSING_SCORE) {
                    passed = passed + 1;
                }
                gradeCount[letterGrade(score) - 'A'] = gradeCount[letterGrade(score) - 'A'] + 1;
            }
            System.out.println("Students      : " + count);
            System.out.printf("Class average : %.2f%n", total / count);
            System.out.printf("Best student  : %s (%.2f)%n", list[best].name(), finalScore(list[best]));
            System.out.printf("Lowest student: %s (%.2f)%n", list[lowest].name(), finalScore(list[lowest]));
            System.out.println("Passed        : " + passed + " of " + count);
            System.out.print("Grades        :");
            for (int g = 0; g < 5; g++) {
                System.out.print(" " + (char) ('A' + g) + "=" + gradeCount[g]);
            }
            System.out.println();
        }
    }
}
```

Each new method is a line-by-line translation of its notation in Lesson 21. The points worth noticing:

- **`findByName`** is the sequential search from Lesson 19 with `equalsIgnoreCase`, so "citra dewi" finds "Citra Dewi." Binary search is not an option here, because the students are not kept in name order.
- **`searchStudent`** receives the `Scanner` as a parameter, like `readInRange`, because it reads a name from the keyboard. It stores the index from `findByName` and uses it to read every field of the record.
- **`sortByFinalScore`** is the stable insertion sort from the leaderboard in Lesson 20. Because `list` is an array, the sorted order is visible in `main` after the call (Lesson 15). Its loop runs to `count`, not `list.length`.
- **`printStatistics`** combines four loop patterns in one pass, as designed. The line `gradeCount[letterGrade(score) - 'A']` uses character arithmetic from Lesson 17: `'A' - 'A'` is 0, `'C' - 'A'` is 2, and `'E' - 'A'` is 4. At the end, `(char) ('A' + g)` turns the index back into a letter for display.

Compile it:

```bash
javac StudentGrades.java
```

---

## 4. Run and Test

Now test the complete app against the test plan from Lesson 21. Follow this script, which covers every menu option and the important edge cases:

1. Show the table and the statistics while the class is empty.
2. Add the four students from the test plan.
3. Show the table.
4. Search for "citra dewi" (lowercase), then for a missing name, "Eko."
5. Sort by final score.
6. Show the statistics.
7. Type an invalid menu choice (7), then exit.

```bash
java StudentGrades
```

Output:

```text

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 2
No students yet.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 5
No students yet.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 1
Name            : Ani Lestari
Assignment score: 85
Midterm score   : 90
Final exam score: 88
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 1
Name            : Budi Santoso
Assignment score: 70
Midterm score   : 65
Final exam score: 60
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 1
Name            : Citra Dewi
Assignment score: 95
Midterm score   : 92
Final exam score: 98
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 1
Name            : Dodi Pratama
Assignment score: 40
Midterm score   : 55
Final exam score: 35
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 2
No  Name              Asg   Mid   Fin   Score  Grade
1   Ani Lestari        85    90    88   87.70      A
2   Budi Santoso       70    65    60   64.50      C
3   Citra Dewi         95    92    98   95.30      A
4   Dodi Pratama       40    55    35   42.50      D

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 3
Name to search: citra dewi
Name       : Citra Dewi
Assignment : 95
Midterm    : 92
Final exam : 98
Final score: 95.30 (grade A)

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 3
Name to search: Eko
No student named Eko.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 4
Sorted from the highest final score to the lowest.
No  Name              Asg   Mid   Fin   Score  Grade
1   Citra Dewi         95    92    98   95.30      A
2   Ani Lestari        85    90    88   87.70      A
3   Budi Santoso       70    65    60   64.50      C
4   Dodi Pratama       40    55    35   42.50      D

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 5
Students      : 4
Class average : 72.50
Best student  : Citra Dewi (95.30)
Lowest student: Dodi Pratama (42.50)
Passed        : 3 of 4
Grades        : A=2 B=0 C=1 D=1 E=0

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 7
Please enter a number from 1 to 6.
Choice: 6
Goodbye!
```

Now compare the results with the test plan, item by item:

| Check | Expected (Lesson 21) | Actual | Result |
| --- | --- | --- | --- |
| Empty class, options 2 and 5 | "No students yet." | "No students yet." | Pass |
| Final scores and grades | 87.70 A, 64.50 C, 95.30 A, 42.50 D | Same | Pass |
| Search ignoring case | Finds Citra Dewi | Found, 95.30 (grade A) | Pass |
| Search for a missing name | Not found message | "No student named Eko." | Pass |
| Ranking | Citra, Ani, Budi, Dodi | Same | Pass |
| Class average | 72.50 | 72.50 | Pass |
| Best and lowest | Citra (95.30), Dodi (42.50) | Same | Pass |
| Passed | 3 of 4 | 3 of 4 | Pass |
| Grade counts | A=2 B=0 C=1 D=1 E=0 | Same | Pass |
| Invalid menu choice | Asked again | "Please enter a number from 1 to 6." | Pass |

Every check passes. Because the expected values were calculated *before* the code existed, this comparison is meaningful: the program is not just producing output, it is producing the *right* output.

---

## 5. Fix the Errors in Your Code

When separately correct pieces are joined into one program, new bugs can appear at the joints. These are called **integration bugs**. Here are three that are easy to introduce in this app.

**Error 1: Reading a number without clearing the rest of the line.**

```java
// Wrong
static int readInRange(Scanner input, String prompt, int low, int high) {
    int value;
    do {
        System.out.print(prompt);
        value = input.nextInt();
        if (value < low || value > high) {
            System.out.println("Please enter a number from " + low + " to " + high + ".");
        }
    } while (value < low || value > high);
    return value;
}

// Correct
static int readInRange(Scanner input, String prompt, int low, int high) {
    int value;
    do {
        System.out.print(prompt);
        value = input.nextInt();
        input.nextLine();
        if (value < low || value > high) {
            System.out.println("Please enter a number from " + low + " to " + high + ".");
        }
    } while (value < low || value > high);
    return value;
}
```

With the wrong version, choosing option 1 skips the name and crashes:

```text
Choice: 1
Name            : Assignment score: Ani Lestari
Exception in thread "main" java.util.InputMismatchException
	at java.base/java.util.Scanner.throwFor(Scanner.java:947)
	at java.base/java.util.Scanner.next(Scanner.java:1602)
	at java.base/java.util.Scanner.nextInt(Scanner.java:2267)
	at java.base/java.util.Scanner.nextInt(Scanner.java:2221)
	at StudentGrades.readInRange(StudentGrades.java:62)
	at StudentGrades.readStudent(StudentGrades.java:79)
	at StudentGrades.main(StudentGrades.java:30)
```

The menu choice `1` was read by `nextInt`, which left the end of line behind. `readStudent` then called `nextLine` for the name, which immediately returned the empty leftover, so the name prompt and the assignment prompt appeared on the same line. The name the user typed then went to `nextInt`, which cannot read "Ani Lestari" as a number. Each method worked fine on its own; the bug only appears when they are combined. The trace at the bottom is helpful here: it shows the chain of calls, from `main` to `readStudent` to `readInRange`, that led to the crash.

**Error 2: Sorting the whole array instead of the used part.**

```java
// Wrong
static void sortByFinalScore(Student[] list, int count) {
    Student key;
    int j;
    for (int i = 1; i < list.length; i++) {
        key = list[i];
        j = i - 1;
        while (j >= 0 && finalScore(list[j]) < finalScore(key)) {
            list[j + 1] = list[j];
            j = j - 1;
        }
        list[j + 1] = key;
    }
}

// Correct
static void sortByFinalScore(Student[] list, int count) {
    Student key;
    int j;
    for (int i = 1; i < count; i++) {
        key = list[i];
        j = i - 1;
        while (j >= 0 && finalScore(list[j]) < finalScore(key)) {
            list[j + 1] = list[j];
            j = j - 1;
        }
        list[j + 1] = key;
    }
}
```

With two students added, choosing option 4 in the wrong version crashes:

```text
Choice: 4
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "StudentGrades$Student.assignment()" because "<parameter1>" is null
	at StudentGrades.finalScore(StudentGrades.java:96)
	at StudentGrades.sortByFinalScore(StudentGrades.java:177)
	at StudentGrades.main(StudentGrades.java:39)
```

The sort was copied from the leaderboard in Lesson 20, where the array was always full, so `list.length` was correct there. In this app, the array has 50 slots but only `count` students, and the third slot is `null`. `finalScore` then tries to read a field of a record that does not exist. This is the design mistake from Lesson 21 sneaking back in through reused code: when you reuse a subprogram, check that its assumptions still hold.

**Error 3: Forgetting to increase `count`.**

```java
// Wrong
case 1 -> {
    if (count == MAX_STUDENTS) {
        System.out.println("The class is full.");
    } else {
        students[count] = readStudent(input);
        System.out.println("Student added.");
    }
}

// Correct
case 1 -> {
    if (count == MAX_STUDENTS) {
        System.out.println("The class is full.");
    } else {
        students[count] = readStudent(input);
        count = count + 1;
        System.out.println("Student added.");
    }
}
```

The wrong version does not crash, which makes it confusing. The program says the student was added, but the table disagrees:

```text
Final exam score: 88
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Exit
Choice: 2
No students yet.
```

The record *was* stored in `students[0]`, but `count` is still 0, so every other subprogram believes the class is empty. Worse, the next student would overwrite slot 0. In a partially filled array, storing an element and increasing the count always go together; forgetting either one breaks the whole program.

---

## 6. Exercises

Each exercise extends the app with a feature, using designs from Lesson 21 and techniques from earlier lessons. Add the features one at a time, compiling and testing after each, as in Sections 2 and 3.

**Exercise 1:** Add a menu option **6. Delete a student** that reads a name, finds the student with `findByName`, and removes them with the `DeleteAt` function you designed in Lesson 21. Display a message if the name is not found. Move Exit to the last option.

**Exercise 2:** Add a menu option **7. Sort by name** that sorts the students alphabetically, ignoring upper and lower case, and then shows the table. Use insertion sort with `compareToIgnoreCase`.

**Exercise 3:** Prevent duplicate names. When adding a student, read the name first, and if a student with that name already exists (ignoring case), display a message and return to the menu without asking for the scores.

---

## 7. Solutions

The three solutions change different parts of the program. Each one is explained below with the notation and the Java code that changes, and the complete program with all three features follows at the end.

**Solution for Exercise 1:**

In the main algorithm, add a new case to `depend on`, using the design of `DeleteAt` from Lesson 21:

```text
6 : output("Name to delete: ")
    input(name)
    position <- FindByName(students, count, name)
    if position = -1 then
        output("No student named ", name, ".")
    else
        output(students[position].name, " deleted.")
        count <- DeleteAt(students, count, position)
    endif
```

In Java, this becomes a new `case 6` in the `switch`, and `deleteAt` is added as a new method, exactly as in `DeleteDemo`:

```java
case 6 -> {
    System.out.print("Name to delete: ");
    name = input.nextLine();
    position = findByName(students, count, name);
    if (position == -1) {
        System.out.println("No student named " + name + ".");
    } else {
        System.out.println(students[position].name() + " deleted.");
        count = deleteAt(students, count, position);
    }
}
```

The message uses the stored name, `students[position].name()`, so it shows the name with its proper capitalization even if the user typed it in lowercase. It is displayed *before* deleting, because after `deleteAt` runs, `students[position]` holds a different student. `count = deleteAt(...)` stores the new count, as designed. `main` needs two new variables, `position` and `name`, the menu gains a line, and Exit moves to option 8, so `readInRange(input, "Choice: ", 1, 8)` and `while (choice != 8)` change too.

**Solution for Exercise 2:**

```text
procedure SortByName(input/output list : array of Student, input count : integer)
{ I.S.: list[0..count-1] holds the students }
{ F.S.: list[0..count-1] is sorted alphabetically by name, ignoring upper and lower case }
Dictionary
    i, j : integer
    key : Student
Algorithm
    for i <- 1 to count - 1 do
        key <- list[i]
        j <- i - 1
        while j >= 0 and lower(list[j].name) > lower(key.name) do
            list[j + 1] <- list[j]
            j <- j - 1
        endwhile
        list[j + 1] <- key
    endfor
```

```java
// Procedure SortByName
// I.S.: list[0..count-1] holds the students
// F.S.: list[0..count-1] is sorted alphabetically by name, ignoring upper and lower case
static void sortByName(Student[] list, int count) {
    Student key;
    int j;
    for (int i = 1; i < count; i++) {
        key = list[i];
        j = i - 1;
        while (j >= 0 && list[j].name().compareToIgnoreCase(key.name()) > 0) {
            list[j + 1] = list[j];
            j = j - 1;
        }
        list[j + 1] = key;
    }
}
```

This is `sortByFinalScore` with a different comparison: a student is shifted right while their name comes *after* the key's name. `compareToIgnoreCase` (Lesson 17) ignores capitalization, so "ani lestari" sorts before "Budi Santoso." With plain `compareTo`, all names starting with a capital letter would come before all lowercase names. The menu gets a `case 7` that calls `sortByName` and then `printTable`.

**Solution for Exercise 3:**

The name must be checked *before* the scores are read, so the main algorithm now reads the name itself and passes it to `ReadStudent`, which only reads the scores:

```text
1 : if count = MAX_STUDENTS then
        output("The class is full.")
    else
        output("Name            : ")
        input(name)
        if FindByName(students, count, name) <> -1 then
            output("A student named ", name, " already exists.")
        else
            students[count] <- ReadStudent(name)
            count <- count + 1
            output("Student added.")
        endif
    endif

function ReadStudent(name : string) -> Student
{ Reads three scores (0-100) for the student called name and returns them as a record }
Dictionary
    assignment, midterm, finalExam : integer
Algorithm
    assignment <- ReadInRange("Assignment score: ", 0, 100)
    midterm <- ReadInRange("Midterm score   : ", 0, 100)
    finalExam <- ReadInRange("Final exam score: ", 0, 100)
    -> < name, assignment, midterm, finalExam >
```

```java
// Function ReadStudent
// Reads three scores (0-100) for the student called name and returns them as a record
static Student readStudent(Scanner input, String name) {
    int assignment;
    int midterm;
    int finalExam;
    assignment = readInRange(input, "Assignment score: ", 0, 100);
    midterm = readInRange(input, "Midterm score   : ", 0, 100);
    finalExam = readInRange(input, "Final exam score: ", 0, 100);
    return new Student(name, assignment, midterm, finalExam);
}
```

`findByName` from the search feature is reused for a completely different purpose: instead of displaying a student, it checks whether one exists. Changing `readStudent` to receive the name is a small change to its contract, so every place that calls it must be updated; in this program there is only one call. Checking first means the user is not asked for three scores that would be thrown away.

**The complete program with all three features:**

```java
import java.util.Scanner;

// Program StudentGrades
// A console app that stores students and their scores, calculates final scores and
// letter grades, and offers searching, sorting, and class statistics.
public class StudentGrades {
    // Type Student
    record Student(String name, int assignment, int midterm, int finalExam) {}

    // Constants shared by the whole program
    static final int MAX_STUDENTS = 50;
    static final double PASSING_SCORE = 55.0;

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        Student[] students = new Student[MAX_STUDENTS];
        int count = 0;
        int choice;
        int position;
        String name;

        // Algorithm
        do {
            printMenu();
            choice = readInRange(input, "Choice: ", 1, 8);
            switch (choice) {
                case 1 -> {
                    if (count == MAX_STUDENTS) {
                        System.out.println("The class is full.");
                    } else {
                        System.out.print("Name            : ");
                        name = input.nextLine();
                        if (findByName(students, count, name) != -1) {
                            System.out.println("A student named " + name + " already exists.");
                        } else {
                            students[count] = readStudent(input, name);
                            count = count + 1;
                            System.out.println("Student added.");
                        }
                    }
                }
                case 2 -> printTable(students, count);
                case 3 -> searchStudent(input, students, count);
                case 4 -> {
                    sortByFinalScore(students, count);
                    System.out.println("Sorted from the highest final score to the lowest.");
                    printTable(students, count);
                }
                case 5 -> printStatistics(students, count);
                case 6 -> {
                    System.out.print("Name to delete: ");
                    name = input.nextLine();
                    position = findByName(students, count, name);
                    if (position == -1) {
                        System.out.println("No student named " + name + ".");
                    } else {
                        System.out.println(students[position].name() + " deleted.");
                        count = deleteAt(students, count, position);
                    }
                }
                case 7 -> {
                    sortByName(students, count);
                    System.out.println("Sorted by name.");
                    printTable(students, count);
                }
                case 8 -> System.out.println("Goodbye!");
            }
        } while (choice != 8);
    }

    // Procedure PrintMenu
    // I.S.: -
    // F.S.: the main menu is displayed
    static void printMenu() {
        System.out.println();
        System.out.println("===== STUDENT GRADES =====");
        System.out.println("1. Add a student");
        System.out.println("2. Show all students");
        System.out.println("3. Search for a student");
        System.out.println("4. Sort by final score");
        System.out.println("5. Class statistics");
        System.out.println("6. Delete a student");
        System.out.println("7. Sort by name");
        System.out.println("8. Exit");
    }

    // Function ReadInRange
    // Asks with prompt until the user types an integer from low to high, then returns it
    static int readInRange(Scanner input, String prompt, int low, int high) {
        int value;
        do {
            System.out.print(prompt);
            value = input.nextInt();
            input.nextLine();
            if (value < low || value > high) {
                System.out.println("Please enter a number from " + low + " to " + high + ".");
            }
        } while (value < low || value > high);
        return value;
    }

    // Function ReadStudent
    // Reads three scores (0-100) for the student called name and returns them as a record
    static Student readStudent(Scanner input, String name) {
        int assignment;
        int midterm;
        int finalExam;
        assignment = readInRange(input, "Assignment score: ", 0, 100);
        midterm = readInRange(input, "Midterm score   : ", 0, 100);
        finalExam = readInRange(input, "Final exam score: ", 0, 100);
        return new Student(name, assignment, midterm, finalExam);
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

    // Procedure PrintTable
    // I.S.: list[0..count-1] holds the students
    // F.S.: the students are displayed as a table with their final scores and grades
    static void printTable(Student[] list, int count) {
        double score;
        if (count == 0) {
            System.out.println("No students yet.");
        } else {
            System.out.printf("%-3s %-15s %5s %5s %5s %7s %6s%n",
                    "No", "Name", "Asg", "Mid", "Fin", "Score", "Grade");
            for (int i = 0; i < count; i++) {
                score = finalScore(list[i]);
                System.out.printf("%-3d %-15s %5d %5d %5d %7.2f %6c%n", i + 1, list[i].name(),
                        list[i].assignment(), list[i].midterm(), list[i].finalExam(),
                        score, letterGrade(score));
            }
        }
    }

    // Function FindByName
    // Returns the index of the student named name in list[0..count-1] (ignoring case), or -1
    static int findByName(Student[] list, int count, String name) {
        for (int i = 0; i < count; i++) {
            if (list[i].name().equalsIgnoreCase(name)) {
                return i;
            }
        }
        return -1;
    }

    // Procedure SearchStudent
    // I.S.: list[0..count-1] holds the students
    // F.S.: a name is read and the matching student's details, or a message, are displayed
    static void searchStudent(Scanner input, Student[] list, int count) {
        String name;
        int position;
        double score;
        System.out.print("Name to search: ");
        name = input.nextLine();
        position = findByName(list, count, name);
        if (position == -1) {
            System.out.println("No student named " + name + ".");
        } else {
            score = finalScore(list[position]);
            System.out.println("Name       : " + list[position].name());
            System.out.println("Assignment : " + list[position].assignment());
            System.out.println("Midterm    : " + list[position].midterm());
            System.out.println("Final exam : " + list[position].finalExam());
            System.out.printf("Final score: %.2f (grade %c)%n", score, letterGrade(score));
        }
    }

    // Procedure SortByFinalScore
    // I.S.: list[0..count-1] holds the students
    // F.S.: list[0..count-1] is sorted from the highest final score to the lowest
    //       (insertion sort, so students with equal scores keep their order)
    static void sortByFinalScore(Student[] list, int count) {
        Student key;
        int j;
        for (int i = 1; i < count; i++) {
            key = list[i];
            j = i - 1;
            while (j >= 0 && finalScore(list[j]) < finalScore(key)) {
                list[j + 1] = list[j];
                j = j - 1;
            }
            list[j + 1] = key;
        }
    }

    // Procedure PrintStatistics
    // I.S.: list[0..count-1] holds the students
    // F.S.: the class average, best and lowest student, grade counts, and pass count are displayed
    static void printStatistics(Student[] list, int count) {
        double total;
        double score;
        int best;
        int lowest;
        int passed;
        int[] gradeCount = new int[5];
        if (count == 0) {
            System.out.println("No students yet.");
        } else {
            total = 0;
            best = 0;
            lowest = 0;
            passed = 0;
            for (int i = 0; i < count; i++) {
                score = finalScore(list[i]);
                total = total + score;
                if (score > finalScore(list[best])) {
                    best = i;
                }
                if (score < finalScore(list[lowest])) {
                    lowest = i;
                }
                if (score >= PASSING_SCORE) {
                    passed = passed + 1;
                }
                gradeCount[letterGrade(score) - 'A'] = gradeCount[letterGrade(score) - 'A'] + 1;
            }
            System.out.println("Students      : " + count);
            System.out.printf("Class average : %.2f%n", total / count);
            System.out.printf("Best student  : %s (%.2f)%n", list[best].name(), finalScore(list[best]));
            System.out.printf("Lowest student: %s (%.2f)%n", list[lowest].name(), finalScore(list[lowest]));
            System.out.println("Passed        : " + passed + " of " + count);
            System.out.print("Grades        :");
            for (int g = 0; g < 5; g++) {
                System.out.print(" " + (char) ('A' + g) + "=" + gradeCount[g]);
            }
            System.out.println();
        }
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

    // Procedure SortByName
    // I.S.: list[0..count-1] holds the students
    // F.S.: list[0..count-1] is sorted alphabetically by name, ignoring upper and lower case
    static void sortByName(Student[] list, int count) {
        Student key;
        int j;
        for (int i = 1; i < count; i++) {
            key = list[i];
            j = i - 1;
            while (j >= 0 && list[j].name().compareToIgnoreCase(key.name()) > 0) {
                list[j + 1] = list[j];
                j = j - 1;
            }
            list[j + 1] = key;
        }
    }
}
```

```bash
javac StudentGrades.java
java StudentGrades
```

Test the new features: add three students (one name typed in lowercase), try to add a duplicate, sort by name, delete a student by typing the name in lowercase, try to delete a missing name, show the table, and exit.

Output:

```text

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Delete a student
7. Sort by name
8. Exit
Choice: 1
Name            : Citra Dewi
Assignment score: 95
Midterm score   : 92
Final exam score: 98
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Delete a student
7. Sort by name
8. Exit
Choice: 1
Name            : ani lestari
Assignment score: 85
Midterm score   : 90
Final exam score: 88
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Delete a student
7. Sort by name
8. Exit
Choice: 1
Name            : Budi Santoso
Assignment score: 70
Midterm score   : 65
Final exam score: 60
Student added.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Delete a student
7. Sort by name
8. Exit
Choice: 1
Name            : Citra Dewi
A student named Citra Dewi already exists.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Delete a student
7. Sort by name
8. Exit
Choice: 7
Sorted by name.
No  Name              Asg   Mid   Fin   Score  Grade
1   ani lestari        85    90    88   87.70      A
2   Budi Santoso       70    65    60   64.50      C
3   Citra Dewi         95    92    98   95.30      A

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Delete a student
7. Sort by name
8. Exit
Choice: 6
Name to delete: budi santoso
Budi Santoso deleted.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Delete a student
7. Sort by name
8. Exit
Choice: 6
Name to delete: Eko
No student named Eko.

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Delete a student
7. Sort by name
8. Exit
Choice: 2
No  Name              Asg   Mid   Fin   Score  Grade
1   ani lestari        85    90    88   87.70      A
2   Citra Dewi         95    92    98   95.30      A

===== STUDENT GRADES =====
1. Add a student
2. Show all students
3. Search for a student
4. Sort by final score
5. Class statistics
6. Delete a student
7. Sort by name
8. Exit
Choice: 8
Goodbye!
```

The duplicate "Citra Dewi" was refused before any scores were asked, "ani lestari" sorted correctly between the capitalized names, the deletion found "Budi Santoso" from a lowercase name and closed the gap in the table, and the missing name was reported politely.

---

## 8. Course Wrap-Up and Next Steps

Congratulations: you have finished the course. You started in Lesson 1 with a cup of tea written as numbered steps, and you have just designed, built, tested, and extended a complete application. Take a moment to look back at the path:

- **Module 1** introduced programs, algorithms, and algorithmic notation, then set up JDK 21 and the edit, compile, run workflow.
- **Module 2** covered data: variables, constants, types, operators, expressions, input, and formatted output.
- **Modules 3 and 4** added the two remaining building blocks of every algorithm, selection and repetition, along with the loop patterns that appear in almost every program.
- **Module 5** organized programs into procedures and functions, and showed how recursion solves a problem with a smaller copy of itself.
- **Module 6** gave you structured data: arrays, two-dimensional arrays, strings, and records.
- **Module 7** implemented the classic searching and sorting algorithms and compared them by counting their steps.
- **Module 8** brought everything together in a project designed in notation first and then built in Java.

The most important thing you learned is not a Java keyword. It is a way of working: understand the problem, design the algorithm, trace it by hand, then implement it and test it against answers you worked out in advance. That process works in every programming language, and it is what will make every language you learn next much easier.

Here are some good directions for what to learn next:

- **Keep improving the Student Grades app.** Add an option to edit a student's scores using the `EditScores` design from Lesson 21, list the students who failed with `PrintFailed`, or let the teacher choose the weights of the three scores.
- **Save data to a file.** Right now, everything is lost when the program ends. Learning to read and write text files in Java (with classes such as `java.nio.file.Files`) would let the app remember the class between runs.
- **Learn object-oriented programming.** Java is an object-oriented language, and you have already used objects such as `Scanner` and `String`. The next step is writing your own classes with fields and methods, which builds directly on the records and subprograms from this course.
- **Explore Java's collections.** Instead of a fixed-size array with a `count`, `ArrayList` grows automatically, and Java provides ready-made sorting and searching methods. Now that you know how these algorithms work inside, you can use the library versions with understanding.
- **Study more algorithms.** Faster sorting algorithms such as merge sort and quicksort, data structures such as stacks, queues, and linked lists, and the analysis of how algorithms scale are the natural continuation of Module 7.
- **Practice regularly.** Solve small problems on a practice site, or write tiny programs for things you need, like a budget tracker or a quiz. Design each one in notation first; the habit will pay off for the rest of your programming life.

Thank you for learning programming with qadrlabs. Keep thinking in algorithms, keep testing your assumptions, and keep building.
