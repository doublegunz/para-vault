# Computational Thinking Still Matters When AI Writes the Code

A beginner types one sentence into an AI assistant, gets back thirty lines of Python, runs it, and sees a clean result on the first try. The feature ships. A week later the report shows an employee who was "minus 1,280 minutes late", and nobody on the team can say whether the bug lives in the prompt, the logic, or the data, because the problem was never broken down in the first place. The code was generated, but the thinking that should have shaped it never happened. That missing piece has a name, computational thinking, and it turns out to be the skill that sits both before and after the prompt. This article looks at what computational thinking is, why AI coding tools make it more important rather than obsolete, and how to practice it with a small, runnable Python program.

## Overview {#overview}

Most discussions about AI and programming focus on what the tools can generate. This article focuses on the other half of the loop: describing a problem precisely enough that the generated code is correct, and checking the result well enough to know when it is not. Instead of staying abstract, you will watch the same small problem get solved twice, once from a vague prompt and once from a prompt shaped by computational thinking.

### What You'll Build

- A small Python script that reads a week of attendance records from a CSV file and reports how many minutes each employee was late.
- A first draft that mirrors what a vague prompt typically produces, including the bugs it hides.
- An improved version built from a decomposed, rule-based specification.
- A `unittest` suite that acts as a contract for any version of the code, whether you or an AI wrote it.

### What You'll Learn

- The four pillars of computational thinking: decomposition, pattern recognition, abstraction, and algorithm design.
- How AI assistants change the developer's role from code writer to problem specifier and reviewer.
- How to turn a vague request into a spec-style prompt with explicit rules and edge cases.
- How to verify AI output with small, focused tests instead of trusting a single happy-path run.
- Why computational thinking is still worth learning for beginners who start with AI from day one.

### What You'll Need

- Python 3.9 or newer (the examples use only the standard library).
- A terminal and a text editor.
- Any AI coding assistant, optional, if you want to try the prompts yourself.
- Basic ability to read Python functions, `if` statements, and dictionaries.

## What Computational Thinking Actually Is {#what-computational-thinking-is}

The term was popularized by Jeannette Wing in a 2006 essay that argued computational thinking is a fundamental skill for everyone, not only for computer scientists. The common misreading is that it means "thinking like a computer". It actually means formulating a problem and its solution in a form that an information processor can carry out. In 2006 that processor was a machine running code a human wrote. In 2026 it is often a model that writes the code for us, but the requirement is the same: somebody has to state the problem clearly.

Computational thinking is usually described through four pillars. They are not steps you perform in strict order; they are lenses you switch between while working on a problem.

### Decomposition

Decomposition means breaking a large, fuzzy problem into smaller parts that can each be solved and checked on their own. "Plan a trip" becomes book transport, book lodging, plan daily activities, and set a budget. In code, decomposition usually shows up as small functions with one job each.

### Pattern Recognition

Pattern recognition means noticing that several parts of a problem share the same shape. If every day of the trip needs "find a place to eat near the activity", you solve it once and reuse the approach. In code, patterns turn into loops, reusable functions, and shared data structures.

### Abstraction

Abstraction means deciding what to ignore. A subway map ignores real distances and street names because the rider only needs stations and connections. In code, abstraction is choosing the data shape and the rules that matter, and leaving out details that do not affect the result.

### Algorithm Design

Algorithm design means writing the exact sequence of steps that solves the problem, including what happens when the input is unusual. A recipe that says "bake until done" is not an algorithm; "bake at 180°C for 25 minutes, then check that a skewer comes out clean" is. Edge cases live here, and this is the pillar AI assistants most often fill in by guessing.

## How AI Changed the Way Code Gets Written {#how-ai-changed-coding}

For decades, learning to program started with a blank editor. Beginners spent their first months fighting syntax, and computational thinking was learned almost by accident, because there was no way to get working code without first breaking the problem down in your head.

AI assistants removed the blank page. A beginner today can describe a feature in plain language and receive runnable code in seconds. That is a real productivity gain, and there is no reason to pretend otherwise. What changed is where the difficulty sits. Generating code became cheap; judging code did not.

When the prompt is vague, the model still has to make decisions about everything the prompt left out. It picks a data format, decides what "late" means, and chooses what to do with missing values. Those choices are often reasonable defaults, but they are guesses about your domain, and they are invisible unless you know to look for them. The developer's job shifts from typing every line to two activities that are pure computational thinking:

- **Specifying**: describing the problem with enough structure, rules, and edge cases that the generated code has fewer gaps to guess about.
- **Reviewing**: reading and testing the output to confirm it matches the rules, instead of trusting that it "looks right".

The next section shows what happens when both of those are skipped.

## A Vague Prompt and the Code It Produces {#vague-prompt-example}

Imagine a small company that tracks attendance in a spreadsheet exported as CSV. Someone asks an AI assistant a single sentence:

```text
Write a Python script that reads attendance.csv and calculates how many minutes each employee was late this week.
```

Create a working folder for the examples and move into it.

```bash
mkdir computational-thinking
cd computational-thinking
```

The commands create an empty folder for every file in this article and make it the current directory, so the scripts can find the CSV files by name.

Now create a file named `attendance_sample.csv` with a few records. Each row holds the employee name, the date, the scheduled shift start, and the actual check-in time.

```
employee,date,shift_start,check_in
Rina,2026-10-12,09:00,09:12
Rina,2026-10-13,09:00,09:20
Budi,2026-10-12,09:00,09:30
Budi,2026-10-13,09:00,09:08
```

This is the kind of data people usually have in mind when they write the prompt: everyone has a check-in time and everyone is a little late.

Next, create `report_v1.py`. The code below is a typical answer to the vague prompt. It is short, readable, and it runs.

```python
import csv
import sys
from datetime import datetime


def minutes_late(shift_start, check_in):
    fmt = "%H:%M"
    start = datetime.strptime(shift_start, fmt)
    actual = datetime.strptime(check_in, fmt)
    diff = actual - start
    return int(diff.total_seconds() // 60)


def summarize(rows):
    totals = {}
    for row in rows:
        late = minutes_late(row["shift_start"], row["check_in"])
        totals[row["employee"]] = totals.get(row["employee"], 0) + late
    return totals


if __name__ == "__main__":
    with open(sys.argv[1], newline="") as f:
        rows = list(csv.DictReader(f))

    for name, total in summarize(rows).items():
        print(f"{name}: {total} minutes late")
```

The `minutes_late()` function parses both times with the `HH:MM` format and returns the difference in whole minutes. The `summarize()` function loops over every row and adds each difference to a running total per employee. The bottom block reads the CSV file passed on the command line with `csv.DictReader`, which turns each row into a dictionary keyed by the header names, and prints one line per employee.

Save the file and run it against the sample data.

```bash
python3 report_v1.py attendance_sample.csv
```

```
Rina: 32 minutes late
Budi: 38 minutes late
```

Rina was 12 and 20 minutes late, which adds up to 32. Budi was 30 and 8 minutes late, which adds up to 38. The output is correct, and this is exactly the moment when many people stop checking.

### Running It on a Real Week

Real attendance data is messier. Create `attendance_week.csv` with records that a real company would actually have: an early arrival, a small delay of a few minutes, a night shift that starts at 22:00, and someone who arrived exactly on time.

```
employee,date,shift_start,check_in
Rina,2026-10-12,09:00,09:12
Rina,2026-10-13,09:00,08:45
Rina,2026-10-14,09:00,09:03
Budi,2026-10-12,09:00,09:30
Budi,2026-10-13,22:00,00:15
Budi,2026-10-14,22:00,21:55
Sari,2026-10-12,09:00,09:00
Sari,2026-10-13,09:00,09:40
```

Run the same script against this file.

```bash
python3 report_v1.py attendance_week.csv
```

```
Rina: 0 minutes late
Budi: -1280 minutes late
Sari: 40 minutes late
```

Two of the three lines are wrong, and only one of them looks wrong. Rina's 15-minute early arrival on Tuesday was subtracted from her 12 minutes of lateness on Monday, so the report claims she was never late. Budi's night shift started at 22:00 and he checked in at 00:15 after midnight, which the script reads as more than 21 hours *early*. The negative number is obvious; Rina's zero is the dangerous one, because it looks perfectly plausible.

### Running It With a Missing Check-In

Finally, create `attendance_missing.csv`. It has the same rows as the previous file plus one more line where Sari never checked in on Wednesday, so the `check_in` cell is empty.

```
employee,date,shift_start,check_in
Rina,2026-10-12,09:00,09:12
Rina,2026-10-13,09:00,08:45
Rina,2026-10-14,09:00,09:03
Budi,2026-10-12,09:00,09:30
Budi,2026-10-13,22:00,00:15
Budi,2026-10-14,22:00,21:55
Sari,2026-10-12,09:00,09:00
Sari,2026-10-13,09:00,09:40
Sari,2026-10-14,09:00,
```

Run the script once more.

```bash
python3 report_v1.py attendance_missing.csv
```

```
Traceback (most recent call last):
  File "/Users/username/sandbox/computational-thinking/report_v1.py", line 26, in <module>
    for name, total in summarize(rows).items():
  File "/Users/username/sandbox/computational-thinking/report_v1.py", line 17, in summarize
    late = minutes_late(row["shift_start"], row["check_in"])
  File "/Users/username/sandbox/computational-thinking/report_v1.py", line 9, in minutes_late
    actual = datetime.strptime(check_in, fmt)
  File "/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/_strptime.py", line 568, in _strptime_datetime
    tt, fraction, gmtoff_fraction = _strptime(data_string, format)
  File "/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/_strptime.py", line 349, in _strptime
    raise ValueError("time data %r does not match format %r" %
ValueError: time data '' does not match format '%H:%M'
```

The script crashes because `datetime.strptime()` cannot parse an empty string. The paths in your traceback will differ, but the final `ValueError` line is the same.

None of these problems are the AI being "bad at Python". The code does exactly what the prompt asked. The prompt simply never said what "late" means when someone is early, what a grace period is, how night shifts work, or what an empty cell represents. The model filled those gaps with the simplest assumption: subtract two times.

## Applying Computational Thinking to the Same Problem {#applying-computational-thinking}

Before writing any new code or a new prompt, it helps to spend a few minutes thinking through the problem with the four pillars. None of this requires a computer; a notebook or a comment block is enough. The goal is to make every decision explicit so neither you nor the AI has to guess.

### Decomposition: Split the Report Into Parts

"Calculate lateness for the week" breaks down into smaller questions that can each be answered and tested on their own:

1. Read the rows from the CSV file.
2. Parse a time value, and decide what an empty value means.
3. Compute the lateness for **one** record.
4. Combine many records into a summary per employee.
5. Format the summary for display.

Step 3 is where every bug from the previous section lived. Decomposition makes that obvious, because it can now be discussed separately from file reading and printing.

### Pattern Recognition: Every Row Is the Same Comparison

Every row, whether it is a morning shift, a night shift, or a missing check-in, is the same pattern: an expected time compared with an actual time. That means one function can handle every case, and the summary step is just a loop that applies the same rule to each row. It also tells us where to put tests: if the single-record function is right, the loop is very likely right too.

### Abstraction: Decide What Matters

The date column, the employee's department, and the spreadsheet layout do not affect lateness. What matters is the shift start, the check-in time, and a small set of business rules. The output also needs more than a single number. A manager reading the report wants to know total late minutes, how many days someone was late, and how many days they were absent, because "40 minutes late" means something different spread over one day than over eight.

### Algorithm Design: Write the Rules Down

This is the pillar the vague prompt skipped entirely. Written out in plain language, the rules for one record become:

1. If the check-in is empty, the employee was **absent**. Absence is not "zero minutes late"; it is counted separately.
2. Subtract the shift start from the check-in.
3. If the result is more than 12 hours negative, the check-in happened after midnight, so add one day. (22:00 to 00:15 is 135 minutes late, not 21 hours early.)
4. If the result is 5 minutes or less, including any early arrival, the employee is **on time** and the lateness is 0.
5. Otherwise, the lateness is the full number of minutes after the shift start.

Each rule is a decision that a human with domain knowledge has to make. A different company might use a 10-minute grace period, or count only the minutes beyond the grace period. The point is not that these are the correct rules; the point is that they are now **written down**.

### Turning the Rules Into a Prompt

With the problem decomposed and the rules explicit, the prompt changes from one sentence into a specification:

```text
Write a Python 3.9 script (standard library only) that reads an attendance CSV
with the columns: employee, date, shift_start, check_in. Times use HH:MM.

Split the code into these functions:
- parse_time(value): returns None for an empty value, otherwise a datetime.
- minutes_late(shift_start, check_in, grace=5): returns minutes late for one record.
- summarize(rows): returns {employee: {late_minutes, late_days, absences}}.
- format_report(summary): returns an aligned text table sorted by name.

Rules for minutes_late:
1. Empty check_in means absent: return None.
2. If check_in minus shift_start is less than -12 hours, add 1 day (overnight shift).
3. A result of `grace` minutes or less, including negative results, returns 0.
4. Otherwise return the full number of minutes late.

The script takes the CSV path as its first command-line argument.
```

Notice that every line of this prompt comes from one of the pillars. The function list is decomposition. The single `minutes_late` rule set reflects pattern recognition. The chosen columns and summary fields are abstraction. The numbered rules are the algorithm. The AI still writes the code, but it no longer has to invent the requirements.

## Building the Improved Version {#building-improved-version}

The specification above is precise enough that the resulting code is predictable. Whether an AI generates it or you type it yourself, it should look very close to the version below. Create `report_v2.py`:

```python
import csv
import sys
from datetime import datetime, timedelta
from typing import Optional

GRACE_MINUTES = 5
TIME_FORMAT = "%H:%M"


def parse_time(value: str) -> Optional[datetime]:
    # An empty cell means the employee never checked in.
    value = value.strip()
    if not value:
        return None
    return datetime.strptime(value, TIME_FORMAT)


def minutes_late(shift_start: str, check_in: str, grace: int = GRACE_MINUTES) -> Optional[int]:
    start = parse_time(shift_start)
    actual = parse_time(check_in)

    # Rule 1: no check-in is an absence, not "zero minutes late".
    if actual is None:
        return None

    diff = actual - start

    # Rule 2: a check-in more than 12 hours "before" the shift
    # actually happened after midnight, on the next day.
    if diff < timedelta(hours=-12):
        diff += timedelta(days=1)

    minutes = int(diff.total_seconds() // 60)

    # Rule 3: arriving early or within the grace period counts as on time.
    if minutes <= grace:
        return 0
    return minutes


def summarize(rows):
    summary = {}
    for row in rows:
        stats = summary.setdefault(
            row["employee"], {"late_minutes": 0, "late_days": 0, "absences": 0}
        )
        late = minutes_late(row["shift_start"], row["check_in"])

        if late is None:
            stats["absences"] += 1
        elif late > 0:
            stats["late_minutes"] += late
            stats["late_days"] += 1
    return summary


def format_report(summary) -> str:
    lines = [f"{'Employee':<10}{'Late (min)':>12}{'Late days':>11}{'Absent':>8}"]
    for name in sorted(summary):
        s = summary[name]
        lines.append(
            f"{name:<10}{s['late_minutes']:>12}{s['late_days']:>11}{s['absences']:>8}"
        )
    return "\n".join(lines)


if __name__ == "__main__":
    with open(sys.argv[1], newline="") as f:
        rows = list(csv.DictReader(f))

    print(format_report(summarize(rows)))
```

The structure follows the decomposition one to one. `parse_time()` handles the "what does an empty cell mean" question in a single place and returns `None` for it, so no other function has to worry about blank strings. `minutes_late()` implements the numbered rules in order, and each rule has a comment that matches the specification, which makes reviewing the code against the rules easy. `timedelta(hours=-12)` is the overnight threshold, and adding `timedelta(days=1)` moves an after-midnight check-in to the next day.

`summarize()` uses `setdefault()` to create an empty stats dictionary the first time an employee appears, then sorts each record into one of three buckets: absent, late, or on time. On-time records add nothing, which is why early arrivals can no longer cancel out late days. `format_report()` is kept separate so the calculation can be tested without parsing printed text; it pads each column with format specifiers such as `:<10` (left-aligned, 10 characters) and `:>12` (right-aligned, 12 characters).

Save the file and run it against the messiest data set, the one that crashed the first draft.

```bash
python3 report_v2.py attendance_missing.csv
```

```
Employee    Late (min)  Late days  Absent
Budi               165          2       0
Rina                12          1       0
Sari                40          1       1
```

Each line can now be checked by hand against the rules. Budi was 30 minutes late on Monday and 135 minutes late on his Tuesday night shift, which totals 165 over 2 days; his 21:55 check-in on Wednesday was early, so it counts as on time. Rina was 12 minutes late on Monday; her early Tuesday arrival and her 3-minute Wednesday delay are both inside the rules for "on time". Sari was 40 minutes late once and absent once. Nothing crashed, and nothing negative appears.

## Verifying AI Output with Tests {#verifying-ai-output}

Running the script once and eyeballing the output is how the first draft slipped through. A better habit is to turn the written rules into tests. Tests are the most direct form of computational thinking in code: each one is a tiny, concrete example of one rule. They also work as a contract with the AI, because any future version of the code, generated or handwritten, must pass them.

Create `test_report.py`:

```python
import importlib
import os
import unittest

# Run against report_v2 by default; set REPORT_MODULE=report_v1 to test the first draft.
report = importlib.import_module(os.environ.get("REPORT_MODULE", "report_v2"))


class MinutesLateTests(unittest.TestCase):
    def test_on_time_is_zero(self):
        self.assertEqual(report.minutes_late("09:00", "09:00"), 0)

    def test_early_arrival_is_zero_not_negative(self):
        self.assertEqual(report.minutes_late("09:00", "08:45"), 0)

    def test_within_grace_period_is_zero(self):
        self.assertEqual(report.minutes_late("09:00", "09:03"), 0)

    def test_beyond_grace_period_counts_full_minutes(self):
        self.assertEqual(report.minutes_late("09:00", "09:12"), 12)

    def test_overnight_shift_crosses_midnight(self):
        self.assertEqual(report.minutes_late("22:00", "00:15"), 135)

    def test_missing_check_in_is_absence(self):
        self.assertIsNone(report.minutes_late("09:00", ""))


class SummarizeTests(unittest.TestCase):
    def test_summary_counts_minutes_days_and_absences(self):
        rows = [
            {"employee": "Sari", "shift_start": "09:00", "check_in": "09:40"},
            {"employee": "Sari", "shift_start": "09:00", "check_in": "09:02"},
            {"employee": "Sari", "shift_start": "09:00", "check_in": ""},
        ]
        self.assertEqual(
            report.summarize(rows)["Sari"],
            {"late_minutes": 40, "late_days": 1, "absences": 1},
        )


if __name__ == "__main__":
    unittest.main()
```

The test file uses only the built-in `unittest` module, so there is nothing to install. `importlib.import_module()` loads the module named in the `REPORT_MODULE` environment variable and falls back to `report_v2`, which lets the same tests run against either version. Each test in `MinutesLateTests` maps directly to one rule from the algorithm section: on time, early, inside the grace period, outside it, overnight, and missing. `SummarizeTests` checks that the three buckets are counted correctly when records are combined.

Save the file and run the tests against the improved version.

```bash
python3 -m unittest -v test_report
```

```
test_beyond_grace_period_counts_full_minutes (test_report.MinutesLateTests) ... ok
test_early_arrival_is_zero_not_negative (test_report.MinutesLateTests) ... ok
test_missing_check_in_is_absence (test_report.MinutesLateTests) ... ok
test_on_time_is_zero (test_report.MinutesLateTests) ... ok
test_overnight_shift_crosses_midnight (test_report.MinutesLateTests) ... ok
test_within_grace_period_is_zero (test_report.MinutesLateTests) ... ok
test_summary_counts_minutes_days_and_absences (test_report.SummarizeTests) ... ok

----------------------------------------------------------------------
Ran 7 tests in 0.001s

OK
```

All seven tests pass. The `-v` flag prints each test name, and because the names describe the rules, the output also reads like a checklist of the specification.

### Running the Same Tests Against the First Draft

Now point the per-record tests at `report_v1.py`. Only the `MinutesLateTests` class is selected, because the first draft's `summarize()` returns a different shape and was never designed to report absences.

```bash
REPORT_MODULE=report_v1 python3 -m unittest test_report.MinutesLateTests
```

```
.FE.FF
======================================================================
ERROR: test_missing_check_in_is_absence (test_report.MinutesLateTests)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/Users/username/sandbox/computational-thinking/test_report.py", line 26, in test_missing_check_in_is_absence
    self.assertIsNone(report.minutes_late("09:00", ""))
  File "/Users/username/sandbox/computational-thinking/report_v1.py", line 9, in minutes_late
    actual = datetime.strptime(check_in, fmt)
  File "/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/_strptime.py", line 568, in _strptime_datetime
    tt, fraction, gmtoff_fraction = _strptime(data_string, format)
  File "/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/_strptime.py", line 349, in _strptime
    raise ValueError("time data %r does not match format %r" %
ValueError: time data '' does not match format '%H:%M'

======================================================================
FAIL: test_early_arrival_is_zero_not_negative (test_report.MinutesLateTests)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/Users/username/sandbox/computational-thinking/test_report.py", line 14, in test_early_arrival_is_zero_not_negative
    self.assertEqual(report.minutes_late("09:00", "08:45"), 0)
AssertionError: -15 != 0

======================================================================
FAIL: test_overnight_shift_crosses_midnight (test_report.MinutesLateTests)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/Users/username/sandbox/computational-thinking/test_report.py", line 23, in test_overnight_shift_crosses_midnight
    self.assertEqual(report.minutes_late("22:00", "00:15"), 135)
AssertionError: -1305 != 135

======================================================================
FAIL: test_within_grace_period_is_zero (test_report.MinutesLateTests)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/Users/username/sandbox/computational-thinking/test_report.py", line 17, in test_within_grace_period_is_zero
    self.assertEqual(report.minutes_late("09:00", "09:03"), 0)
AssertionError: 3 != 0

----------------------------------------------------------------------
Ran 6 tests in 0.002s

FAILED (failures=3, errors=1)
```

The first line, `.FE.FF`, is a compact summary where `.` means pass, `F` means a failed assertion, and `E` means an unexpected error. Four of the six rules are broken, and each failure message points to the exact rule and the exact wrong value: `-15 != 0` for early arrival, `-1305 != 135` for the night shift, `3 != 0` for the grace period, and a `ValueError` for the missing check-in. These are the same bugs found manually in the previous section, but now they are found in milliseconds and will be caught automatically if they ever come back.

This is the practical payoff. When an AI suggests a refactor next month, there is no need to reread every line with suspicion. Run the tests; if they pass, the rules still hold.

## Is Computational Thinking Still Relevant? {#is-it-still-relevant}

The short answer is yes, but the reason has changed. A decade ago, computational thinking mattered because you could not write a working program without it. Today it matters because you cannot tell whether a working program is **correct** without it.

Some parts of learning to program have honestly become less important. Memorizing the exact signature of `strptime()` or the order of arguments to a library function is no longer a good use of a beginner's time; the assistant knows those details better than most people do. What AI cannot know is the domain: that this company has a 5-minute grace period, that night shifts exist, that an empty cell means absence. That knowledge has to come from a person, and computational thinking is the discipline of turning it into something precise enough to act on.

Look back at the example. The first draft failed not because of syntax but because of four missing decisions. Every one of those decisions was recovered through decomposition, abstraction, and algorithm design, and every one was then locked in by a test. The AI was useful at both ends; it just could not supply the middle.

### What This Means for Beginners

Starting with AI is not the problem. Skipping the thinking is. A few habits let beginners use AI from day one while still building computational thinking:

- **Break the problem down before prompting.** Write the list of parts in plain language first, then ask for one part at a time.
- **Write the rules and edge cases yourself.** Ask "what happens if the input is empty, negative, huge, or crosses midnight?" before the model answers it for you.
- **Predict the output before running code.** Read the generated function, guess what it will return for a tricky input, then run it. Every wrong guess is a lesson.
- **Ask the AI to explain, not just to write.** Requests like "walk me through this function line by line" or "what assumptions does this code make?" expose the hidden decisions.
- **Turn rules into tests early.** A test you wrote is a rule you understand. A test the AI wrote is still worth reading, because it shows what the model assumed.
- **Still learn the fundamentals.** Variables, conditions, loops, functions, and data structures are the vocabulary of computational thinking. You do not need to memorize every API, but you need enough fluency to read code and notice when it is wrong.

## Conclusion {#conclusion}

AI assistants made writing code dramatically faster, but they did not remove the need to understand the problem the code is supposed to solve. The attendance report showed how a correct-looking script can hide four broken rules, and how the four pillars of computational thinking recover those rules and turn them into a precise prompt, clean code, and a test suite that keeps the result honest.

- **Computational thinking is problem formulation.** It is about stating a problem so that a processor, whether a computer or an AI model, can solve it correctly, not about thinking like a machine.
- **Vague prompts produce guessed requirements.** When a prompt leaves out the rules, the model fills the gaps with the simplest assumption, and those assumptions are easy to miss on happy-path data.
- **Decomposition makes prompts precise.** Splitting the work into small functions shows exactly where the risky logic lives and lets you ask for, review, and test one piece at a time.
- **Abstraction decides the data shape.** Choosing which inputs matter and what the output should contain prevents misleading results such as early arrivals cancelling out late days.
- **Algorithm design is where edge cases live.** Writing the rules as numbered steps forces decisions about empty values, overnight shifts, and grace periods before any code is generated.
- **Tests are the contract with AI.** Turning each rule into a test catches wrong output in milliseconds and protects the behavior through future AI-assisted refactors.
- **Fundamentals still pay off.** Beginners can start with AI, but knowing variables, conditions, loops, and functions is what makes it possible to read generated code and spot when it is wrong.
