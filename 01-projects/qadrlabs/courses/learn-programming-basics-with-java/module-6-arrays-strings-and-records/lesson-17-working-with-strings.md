## 1. Before You Begin

You have used strings since Lesson 2: names, prompts, messages, menu labels. So far, every string has been treated as one solid piece of text that you store and display. But a string is really a **sequence of characters**, much like the arrays from Lesson 15. "Algorithm" is the character `A`, followed by `l`, then `g`, and so on, each one at its own position.

Once you see a string this way, a whole family of problems opens up: counting the vowels in a sentence, reversing a word, checking whether a word is a palindrome, validating a password, or encrypting a secret message. Each of these is an algorithm that walks through the characters one by one, using the same loop patterns you already know. In this lesson you will design these algorithms in notation and implement them with Java's `String` methods.

### What You'll Build

A program that explores a word character by character, a vowel and consonant counter, a text reverser, a word comparer, a password strength checker, and a palindrome tester.

### What You'll Learn

- ✅ How a string is a sequence of characters with indexes starting at 0
- ✅ How to get a string's length and a character at a position
- ✅ How to traverse a string with a loop
- ✅ How to build a new string piece by piece
- ✅ How to compare strings correctly with `equals` and `compareTo`
- ✅ Useful `String` and `Character` methods such as `substring`, `indexOf`, `toUpperCase`, and `isDigit`
- ✅ Why strings cannot be changed, and what that means for your code

### What You'll Need

- Lessons 15 and 16 completed
- JDK 21 and your `~/java-basics` folder

```bash
mkdir -p ~/java-basics/lesson-17
cd ~/java-basics/lesson-17
```

---

## 2. A String Is a Sequence of Characters

Like an array, each character in a string has an index, starting at 0:

```text
index:   0   1   2   3   4   5   6   7   8
       +---+---+---+---+---+---+---+---+---+
       | A | l | g | o | r | i | t | h | m |
       +---+---+---+---+---+---+---+---+---+
```

The length of "Algorithm" is 9, so the last index is 8. Notation treats a string like an array of characters. In Java, a `String` is an object, and you use its **methods** (called with a dot, like `word.length()`) to look inside it:

| Operation | Notation | Java |
| --- | --- | --- |
| Length | `length(s)` | `s.length()` |
| Character at index `i` | `s[i]` | `s.charAt(i)` |
| Join two strings | `s + t` | `s + t` |
| Part from index `a` up to (not including) `b` | `substring(s, a, b)` | `s.substring(a, b)` |
| Uppercase or lowercase copy | `upper(s)`, `lower(s)` | `s.toUpperCase()`, `s.toLowerCase()` |
| First position of a character (-1 if absent) | `position(ch, s)` | `s.indexOf(ch)` |
| Equal? | `s = t` | `s.equals(t)` |

Note that for arrays, length is `a.length` with no parentheses, while for strings it is `s.length()` with parentheses, because for strings it is a method.

### Step 1: Explore a Word

```text
Program StringBasics
{ Explores a string as a sequence of characters }

Dictionary
    word : string = "Algorithm"
    i : integer

Algorithm
    output("Word          : ", word)
    output("Length        : ", length(word))
    output("First char    : ", word[0])
    output("Last char     : ", word[length(word) - 1])
    output("Chars 0 to 3  : ", substring(word, 0, 4))
    output("Upper case    : ", upper(word))
    output("Position of r : ", position('r', word))
    output("Position of z : ", position('z', word))
    output("Spaced out    : ")
    for i <- 0 to length(word) - 1 do
        output(word[i], " ")
    endfor
```

The last character is at `length(word) - 1`, exactly as with arrays. The `for` loop traverses the string, visiting each character in order; it is the string version of the array traversal from Lesson 15.

Create `StringBasics.java`:

```java
// Program StringBasics
// Explores a string as a sequence of characters.
public class StringBasics {
    public static void main(String[] args) {
        // Dictionary
        String word = "Algorithm";

        // Algorithm
        System.out.println("Word          : " + word);
        System.out.println("Length        : " + word.length());
        System.out.println("First char    : " + word.charAt(0));
        System.out.println("Last char     : " + word.charAt(word.length() - 1));
        System.out.println("Chars 0 to 3  : " + word.substring(0, 4));
        System.out.println("Upper case    : " + word.toUpperCase());
        System.out.println("Position of r : " + word.indexOf('r'));
        System.out.println("Position of z : " + word.indexOf('z'));
        System.out.print("Spaced out    : ");
        for (int i = 0; i < word.length(); i++) {
            System.out.print(word.charAt(i) + " ");
        }
        System.out.println();
    }
}
```

`charAt(i)` returns a `char`, the single character at index `i`. `substring(0, 4)` returns the characters from index 0 up to *but not including* index 4, so you get 4 characters. `indexOf('r')` searches the string and returns the position of the first `r`, or -1 when the character is not there. The loop header `for (int i = 0; i < word.length(); i++)` is the standard string traversal.

```bash
javac StringBasics.java
java StringBasics
```

Output:

```text
Word          : Algorithm
Length        : 9
First char    : A
Last char     : m
Chars 0 to 3  : Algo
Upper case    : ALGORITHM
Position of r : 4
Position of z : -1
Spaced out    : A l g o r i t h m 
```

---

## 3. Algorithms on Characters

Now apply the loop patterns from Lesson 11 to the characters of a string.

### Step 1: Count Characters by Category

**Problem:** Read a sentence and count its vowels, consonants, and spaces.

Each character is checked once, and one of three counters goes up. To avoid checking both `'A'` and `'a'`, convert each character to lowercase first.

```text
Program CountVowels
{ Counts the vowels, consonants, and spaces in a sentence }

Dictionary
    sentence : string
    ch : character
    i, vowels, consonants, spaces : integer

Algorithm
    output("Sentence: ")
    input(sentence)
    vowels <- 0
    consonants <- 0
    spaces <- 0
    for i <- 0 to length(sentence) - 1 do
        ch <- lower(sentence[i])
        if ch = 'a' or ch = 'e' or ch = 'i' or ch = 'o' or ch = 'u' then
            vowels <- vowels + 1
        else if ch >= 'a' and ch <= 'z' then
            consonants <- consonants + 1
        else if ch = ' ' then
            spaces <- spaces + 1
        endif
    endfor
    output("Vowels    : ", vowels)
    output("Consonants: ", consonants)
    output("Spaces    : ", spaces)
```

`ch >= 'a' and ch <= 'z'` checks whether a character is a lowercase letter. Characters can be compared like numbers, because each character is stored as a number (its **character code**), and the codes for `a` to `z` are in alphabetical order. Since vowels were checked first, any letter that reaches the second condition is a consonant. Characters that are neither letters nor spaces, such as punctuation, are not counted.

Create `CountVowels.java`:

```java
import java.util.Scanner;

// Program CountVowels
// Counts the vowels, consonants, and spaces in a sentence.
public class CountVowels {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String sentence;
        char ch;
        int vowels;
        int consonants;
        int spaces;

        // Algorithm
        System.out.print("Sentence: ");
        sentence = input.nextLine();
        vowels = 0;
        consonants = 0;
        spaces = 0;
        for (int i = 0; i < sentence.length(); i++) {
            ch = Character.toLowerCase(sentence.charAt(i));
            if (ch == 'a' || ch == 'e' || ch == 'i' || ch == 'o' || ch == 'u') {
                vowels = vowels + 1;
            } else if (ch >= 'a' && ch <= 'z') {
                consonants = consonants + 1;
            } else if (ch == ' ') {
                spaces = spaces + 1;
            }
        }
        System.out.println("Vowels    : " + vowels);
        System.out.println("Consonants: " + consonants);
        System.out.println("Spaces    : " + spaces);
    }
}
```

The sentence is read with `nextLine` so it can contain spaces. `Character.toLowerCase(ch)` comes from Java's `Character` class, which provides helpful methods for single characters. Characters are compared with `==`, which is correct for `char` values (but not for strings, as you will see shortly).

```bash
javac CountVowels.java
java CountVowels
```

Output:

```text
Sentence: Learning to code is fun
Vowels    : 8
Consonants: 11
Spaces    : 4
```

### Step 2: Build a New String

**Problem:** Read a line of text and display it reversed.

A new string can be built one character at a time, starting from the empty string `""` and joining characters to it, just like an accumulator starts at 0 and adds numbers. To reverse, traverse the original string from the *last* index down to 0:

```text
Program ReverseText
{ Reverses a line of text by building a new string from the last character to the first }

Dictionary
    text : string
    function Reverse(s : string) -> string

Algorithm
    output("Text: ")
    input(text)
    output("Reversed: ", Reverse(text))

function Reverse(s : string) -> string
{ Returns s with its characters in reverse order }
Dictionary
    result : string
    i : integer
Algorithm
    result <- ""
    for i <- length(s) - 1 downto 0 do
        result <- result + s[i]
    endfor
    -> result
```

Create `ReverseText.java`:

```java
import java.util.Scanner;

// Program ReverseText
// Reverses a line of text by building a new string from the last character to the first.
public class ReverseText {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String text;

        // Algorithm
        System.out.print("Text: ");
        text = input.nextLine();
        System.out.println("Reversed: " + reverse(text));
    }

    // Function Reverse
    // Returns s with its characters in reverse order
    static String reverse(String s) {
        String result = "";
        for (int i = s.length() - 1; i >= 0; i--) {
            result = result + s.charAt(i);
        }
        return result;
    }
}
```

`result + s.charAt(i)` joins a character to the end of the string so far. The function's return type is `String`, so it can be used anywhere a string is needed.

```bash
javac ReverseText.java
java ReverseText
```

Output:

```text
Text: Hello, Java
Reversed: avaJ ,olleH
```

Every character is reversed, including the comma and the space.

### Step 3: Compare Strings

Comparing strings is different from comparing numbers or characters. **Problem:** Read two words and display whether they are equal (exactly, and ignoring case), and which comes first alphabetically.

```text
Program CompareText
{ Compares two words for equality and alphabetical order }

Dictionary
    first, second : string

Algorithm
    output("First word : ")
    input(first)
    output("Second word: ")
    input(second)
    output("Exactly equal        : ", first = second)
    output("Equal ignoring case  : ", lower(first) = lower(second))
    if first < second then
        output(first, " comes before ", second)
    else if first > second then
        output(first, " comes after ", second)
    else
        output("Both words are the same")
    endif
```

In notation, strings can be compared with `=`, `<`, and `>`, where "less than" means "comes earlier in alphabetical order."

Java does *not* allow `<` and `>` on strings, and `==` does not compare their contents (see Error 1 in Section 5). Instead, use these methods:

| Notation | Java | Result |
| --- | --- | --- |
| `s = t` | `s.equals(t)` | `true` if the characters are identical |
| `lower(s) = lower(t)` | `s.equalsIgnoreCase(t)` | `true` if identical apart from upper and lower case |
| `s < t`, `s > t` | `s.compareTo(t)` | A negative number if `s` comes first, positive if `s` comes after, 0 if equal |

Create `CompareText.java`:

```java
import java.util.Scanner;

// Program CompareText
// Compares two words for equality and alphabetical order.
public class CompareText {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String first;
        String second;

        // Algorithm
        System.out.print("First word : ");
        first = input.nextLine();
        System.out.print("Second word: ");
        second = input.nextLine();
        System.out.println("Exactly equal        : " + first.equals(second));
        System.out.println("Equal ignoring case  : " + first.equalsIgnoreCase(second));
        if (first.compareTo(second) < 0) {
            System.out.println(first + " comes before " + second);
        } else if (first.compareTo(second) > 0) {
            System.out.println(first + " comes after " + second);
        } else {
            System.out.println("Both words are the same");
        }
    }
}
```

`compareTo` returns a number, not a boolean, so it is compared with 0. Sorting names alphabetically, which you will do in Lesson 20, relies on exactly this method.

```bash
javac CompareText.java
java CompareText
```

Output:

```text
First word : apple
Second word: banana
Exactly equal        : false
Equal ignoring case  : false
apple comes before banana
```

Run it again with words that differ only in case:

Output:

```text
First word : Java
Second word: java
Exactly equal        : false
Equal ignoring case  : true
Java comes before java
```

`compareTo` compares character codes, and in those codes *all* uppercase letters come before *all* lowercase letters. That is why "Java" comes before "java." If you want a pure alphabetical comparison, convert both strings to the same case first, or use `compareToIgnoreCase`.

### Step 4: Check Several Properties with Flags

**Problem:** A password is accepted if it has at least 8 characters, at least one uppercase letter, and at least one digit. Read a password and say what is missing, or accept it.

This is the "any" flag pattern from Lesson 11: start each flag as false, and set it to true as soon as a matching character is found.

```text
Program PasswordCheck
{ Checks that a password is long enough and has an uppercase letter and a digit }

Dictionary
    password : string
    hasUpper, hasDigit : boolean
    ch : character
    i : integer

Algorithm
    output("New password: ")
    input(password)
    hasUpper <- false
    hasDigit <- false
    for i <- 0 to length(password) - 1 do
        ch <- password[i]
        if ch >= 'A' and ch <= 'Z' then
            hasUpper <- true
        endif
        if ch >= '0' and ch <= '9' then
            hasDigit <- true
        endif
    endfor
    if length(password) < 8 then
        output("Too short: use at least 8 characters.")
    else if not hasUpper then
        output("Add at least one uppercase letter.")
    else if not hasDigit then
        output("Add at least one digit.")
    else
        output("Strong enough. Password saved.")
    endif
```

Create `PasswordCheck.java`:

```java
import java.util.Scanner;

// Program PasswordCheck
// Checks that a password is long enough and has an uppercase letter and a digit.
public class PasswordCheck {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String password;
        boolean hasUpper;
        boolean hasDigit;
        char ch;

        // Algorithm
        System.out.print("New password: ");
        password = input.nextLine();
        hasUpper = false;
        hasDigit = false;
        for (int i = 0; i < password.length(); i++) {
            ch = password.charAt(i);
            if (Character.isUpperCase(ch)) {
                hasUpper = true;
            }
            if (Character.isDigit(ch)) {
                hasDigit = true;
            }
        }
        if (password.length() < 8) {
            System.out.println("Too short: use at least 8 characters.");
        } else if (!hasUpper) {
            System.out.println("Add at least one uppercase letter.");
        } else if (!hasDigit) {
            System.out.println("Add at least one digit.");
        } else {
            System.out.println("Strong enough. Password saved.");
        }
    }
}
```

`Character.isUpperCase(ch)` and `Character.isDigit(ch)` do the same job as the range checks in the notation, and they also understand letters and digits from other alphabets. The `Character` class has several similar methods, such as `isLetter` and `isLowerCase`.

```bash
javac PasswordCheck.java
java PasswordCheck
```

Test one password for each rule, plus one that passes:

Output:

```text
New password: abc12
Too short: use at least 8 characters.
```

Output:

```text
New password: password123
Add at least one uppercase letter.
```

Output:

```text
New password: Password
Add at least one digit.
```

Output:

```text
New password: Password123
Strong enough. Password saved.
```

---

## 4. Run and Test

A **palindrome** reads the same forward and backward, like "level" or "Kodok." **Problem:** Read words until the user types "stop" and say whether each one is a palindrome, ignoring upper and lower case.

You could reverse the word and compare it with the original, but there is a more efficient method that does not build a new string: compare the first and last characters, then the second and second to last, moving two positions toward the middle. This is the two-marker technique from the array reversal in Lesson 15. As soon as one pair differs, the answer is no.

```text
Program Palindrome
{ Checks whether words read the same forward and backward, until the user types "stop" }

Dictionary
    word : string
    function IsPalindrome(s : string) -> boolean

Algorithm
    output("Word (stop to quit): ")
    input(word)
    while word <> "stop" do
        if IsPalindrome(word) then
            output("  ", word, " is a palindrome")
        else
            output("  ", word, " is not a palindrome")
        endif
        output("Word (stop to quit): ")
        input(word)
    endwhile

function IsPalindrome(s : string) -> boolean
{ Returns true if s reads the same forward and backward, ignoring upper and lower case }
Dictionary
    lowerS : string
    left, right : integer
Algorithm
    lowerS <- lower(s)
    left <- 0
    right <- length(lowerS) - 1
    while left < right do
        if lowerS[left] <> lowerS[right] then
            -> false
        endif
        left <- left + 1
        right <- right - 1
    endwhile
    -> true
```

The main algorithm is a sentinel loop where the sentinel is a word instead of a number.

Create `Palindrome.java`:

```java
import java.util.Scanner;

// Program Palindrome
// Checks whether words read the same forward and backward, until the user types "stop".
public class Palindrome {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String word;

        // Algorithm
        System.out.print("Word (stop to quit): ");
        word = input.nextLine();
        while (!word.equals("stop")) {
            if (isPalindrome(word)) {
                System.out.println("  \"" + word + "\" is a palindrome");
            } else {
                System.out.println("  \"" + word + "\" is not a palindrome");
            }
            System.out.print("Word (stop to quit): ");
            word = input.nextLine();
        }
    }

    // Function IsPalindrome
    // Returns true if s reads the same forward and backward, ignoring upper and lower case
    static boolean isPalindrome(String s) {
        String lower = s.toLowerCase();
        int left = 0;
        int right = lower.length() - 1;
        while (left < right) {
            if (lower.charAt(left) != lower.charAt(right)) {
                return false;
            }
            left = left + 1;
            right = right - 1;
        }
        return true;
    }
}
```

The loop condition `!word.equals("stop")` is the Java version of `word <> "stop"`. Inside a string, `\"` displays a double quote character; the backslash tells Java that this quote is part of the text, not the end of the string.

```bash
javac Palindrome.java
java Palindrome
```

Output:

```text
Word (stop to quit): level
  "level" is a palindrome
Word (stop to quit): Kodok
  "Kodok" is a palindrome
Word (stop to quit): java
  "java" is not a palindrome
Word (stop to quit): Racecar
  "Racecar" is a palindrome
Word (stop to quit): a
  "a" is a palindrome
Word (stop to quit): stop
```

"Kodok" and "Racecar" pass because the comparison ignores case. The one-letter word "a" is a palindrome because the loop never runs (`left` is not less than `right`), and the function returns `true`.

---

## 5. Fix the Errors in Your Code

**Error 1: Comparing strings with `==`.**

```java
// Wrong
import java.util.Scanner;

public class CompareWrong {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        System.out.print("Type yes to continue: ");
        String answer = input.nextLine();
        if (answer == "yes") {
            System.out.println("Continuing...");
        } else {
            System.out.println("Stopped.");
        }
    }
}

// Correct
import java.util.Scanner;

public class CompareWrong {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        System.out.print("Type yes to continue: ");
        String answer = input.nextLine();
        if (answer.equals("yes")) {
            System.out.println("Continuing...");
        } else {
            System.out.println("Stopped.");
        }
    }
}
```

The wrong version compiles, but even when the user types exactly `yes`, it displays:

```text
Type yes to continue: yes
Stopped.
```

For strings, `==` checks whether two variables refer to the *same object in memory*, not whether they contain the same characters. The text typed by the user is a different object from the `"yes"` written in the code, so `==` is false. This is one of the most famous Java bugs. Always compare strings with `equals` (or `equalsIgnoreCase`). `==` is still correct for `char`, `int`, and other simple types.

**Error 2: An index past the end of the string.**

```java
// Wrong
public class CharBounds {
    public static void main(String[] args) {
        String word = "Java";
        System.out.println("Last char: " + word.charAt(word.length()));
    }
}

// Correct
public class CharBounds {
    public static void main(String[] args) {
        String word = "Java";
        System.out.println("Last char: " + word.charAt(word.length() - 1));
    }
}
```

The wrong version crashes with a long message:

```text
Exception in thread "main" java.lang.StringIndexOutOfBoundsException: Index 4 out of bounds for length 4
	at java.base/jdk.internal.util.Preconditions$1.apply(Preconditions.java:55)
	at java.base/jdk.internal.util.Preconditions$1.apply(Preconditions.java:52)
	at java.base/jdk.internal.util.Preconditions$4.apply(Preconditions.java:213)
	at java.base/jdk.internal.util.Preconditions$4.apply(Preconditions.java:210)
	at java.base/jdk.internal.util.Preconditions.outOfBounds(Preconditions.java:98)
	at java.base/jdk.internal.util.Preconditions.outOfBoundsCheckIndex(Preconditions.java:106)
	at java.base/jdk.internal.util.Preconditions.checkIndex(Preconditions.java:302)
	at java.base/java.lang.String.checkIndex(String.java:4822)
	at java.base/java.lang.StringLatin1.charAt(StringLatin1.java:46)
	at java.base/java.lang.String.charAt(String.java:1544)
	at CharBounds.main(CharBounds.java:4)
```

Most of these lines are inside Java's own library. The useful parts are the first line, which says index 4 is out of bounds for a string of length 4, and the *last* line, which points to your code: `CharBounds.java:4`. As with arrays, the last valid index is `length() - 1`.

**Error 3: Expecting a string method to change the string.**

```java
// Wrong
public class Immutable {
    public static void main(String[] args) {
        String city = "bandung";
        city.toUpperCase();
        System.out.println(city);
    }
}

// Correct
public class Immutable {
    public static void main(String[] args) {
        String city = "bandung";
        city = city.toUpperCase();
        System.out.println(city);
    }
}
```

The wrong version displays:

```text
bandung
```

Java strings are **immutable**: once created, their characters can never change. `toUpperCase()` does not modify `city`; it creates and returns a *new* string. If the result is not stored, it is thrown away, just like the ignored function result in Lesson 13. To keep the change, assign the result back: `city = city.toUpperCase();`. The same rule applies to every string method, such as `toLowerCase`, `substring`, and `replace`.

---

## 6. Exercises

**Exercise 1:** Write the notation and the Java program `WordCount` with a function `CountWords(s : string) -> integer` that counts the words in a sentence. Words may be separated by more than one space, and the sentence may start or end with spaces. Hint: a word starts at a character that is not a space and is either the first character or follows a space.

**Exercise 2:** The **Caesar cipher** encrypts a message by shifting every letter a fixed number of places along the alphabet, wrapping around from `z` to `a`. With a shift of 3, `a` becomes `d` and `x` becomes `a`. Write the notation and the Java program `CaesarCipher` with a function `Encrypt(s : string, shift : integer) -> string` for lowercase messages (other characters stay unchanged). Show that encrypting with a shift of `26 - shift` decrypts the message.

**Exercise 3:** Write the notation and the Java program `Initials` with a function that returns the uppercase initials of a full name. For example, "budi santoso wijaya" becomes "BSW."

---

## 7. Solutions

**Solution for Exercise 1:**

```text
Program WordCount
{ Counts the words in a sentence, where words are separated by one or more spaces }

Dictionary
    sentence : string
    function CountWords(s : string) -> integer

Algorithm
    output("Sentence: ")
    input(sentence)
    output("Words: ", CountWords(sentence))

function CountWords(s : string) -> integer
{ Returns the number of words in s; a word starts at a non-space character
  that is either the first character or follows a space }
Dictionary
    i, count : integer
Algorithm
    count <- 0
    for i <- 0 to length(s) - 1 do
        if s[i] <> ' ' and (i = 0 or s[i - 1] = ' ') then
            count <- count + 1
        endif
    endfor
    -> count
```

```java
import java.util.Scanner;

// Program WordCount
// Counts the words in a sentence, where words are separated by one or more spaces.
public class WordCount {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String sentence;

        // Algorithm
        System.out.print("Sentence: ");
        sentence = input.nextLine();
        System.out.println("Words: " + countWords(sentence));
    }

    // Function CountWords
    // Returns the number of words in s; a word starts at a non-space character
    // that is either the first character or follows a space
    static int countWords(String s) {
        int count = 0;
        for (int i = 0; i < s.length(); i++) {
            if (s.charAt(i) != ' ' && (i == 0 || s.charAt(i - 1) == ' ')) {
                count = count + 1;
            }
        }
        return count;
    }
}
```

Counting spaces would give the wrong answer when there are extra spaces, so the function counts the *start* of each word instead. The condition `i == 0 || s.charAt(i - 1) == ' '` is safe even at index 0: when `i` is 0, the left side is true, so Java never evaluates `s.charAt(-1)`. Java stops evaluating `||` as soon as the answer is known, which is called **short-circuit evaluation**.

```bash
javac WordCount.java
java WordCount
```

Output:

```text
Sentence:   Programming   is about   thinking 
Words: 4
```

**Solution for Exercise 2:**

To shift a letter, convert it to its position in the alphabet (0 for `a`, 25 for `z`), add the shift, wrap with `mod 26`, and convert back. In notation, `ord(ch)` gives a character's code and `chr(code)` gives the character for a code.

```text
Program CaesarCipher
{ Encrypts and decrypts lowercase text by shifting each letter }

Dictionary
    message, secret : string
    shift : integer
    function Encrypt(s : string, shift : integer) -> string

Algorithm
    output("Message (lowercase): ")
    input(message)
    output("Shift (1-25)       : ")
    input(shift)
    secret <- Encrypt(message, shift)
    output("Encrypted: ", secret)
    output("Decrypted: ", Encrypt(secret, 26 - shift))

function Encrypt(s : string, shift : integer) -> string
{ Returns s with each lowercase letter shifted forward by shift places, wrapping from z to a;
  other characters are unchanged }
Dictionary
    result : string
    ch : character
    i : integer
Algorithm
    result <- ""
    for i <- 0 to length(s) - 1 do
        ch <- s[i]
        if ch >= 'a' and ch <= 'z' then
            ch <- chr(ord('a') + (ord(ch) - ord('a') + shift) mod 26)
        endif
        result <- result + ch
    endfor
    -> result
```

```java
import java.util.Scanner;

// Program CaesarCipher
// Encrypts and decrypts lowercase text by shifting each letter.
public class CaesarCipher {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String message;
        String secret;
        int shift;

        // Algorithm
        System.out.print("Message (lowercase): ");
        message = input.nextLine();
        System.out.print("Shift (1-25)       : ");
        shift = input.nextInt();
        secret = encrypt(message, shift);
        System.out.println("Encrypted: " + secret);
        System.out.println("Decrypted: " + encrypt(secret, 26 - shift));
    }

    // Function Encrypt
    // Returns s with each lowercase letter shifted forward by shift places, wrapping from z to a;
    // other characters are unchanged
    static String encrypt(String s, int shift) {
        String result = "";
        char ch;
        for (int i = 0; i < s.length(); i++) {
            ch = s.charAt(i);
            if (ch >= 'a' && ch <= 'z') {
                ch = (char) ('a' + (ch - 'a' + shift) % 26);
            }
            result = result + ch;
        }
        return result;
    }
}
```

In Java, arithmetic on characters works directly with their codes: `ch - 'a'` is the letter's position, from 0 to 25. After adding the shift and wrapping with `% 26`, adding `'a'` gives a code again, and the cast `(char)` turns that number back into a character. The message is read with `nextLine` before the shift is read with `nextInt`, which avoids the leftover end of line problem from Lesson 6. Shifting by 3 and then by 23 adds up to 26, a full trip around the alphabet, which restores the original message.

```bash
javac CaesarCipher.java
java CaesarCipher
```

Output:

```text
Message (lowercase): attack at dawn
Shift (1-25)       : 3
Encrypted: dwwdfn dw gdzq
Decrypted: attack at dawn
```

**Solution for Exercise 3:**

```text
Program Initials
{ Builds the uppercase initials of a full name }

Dictionary
    name : string
    function Initials(s : string) -> string

Algorithm
    output("Full name: ")
    input(name)
    output("Initials : ", Initials(name))

function Initials(s : string) -> string
{ Returns the first letter of every word in s, in uppercase }
Dictionary
    result : string
    i : integer
Algorithm
    result <- ""
    for i <- 0 to length(s) - 1 do
        if s[i] <> ' ' and (i = 0 or s[i - 1] = ' ') then
            result <- result + upper(s[i])
        endif
    endfor
    -> result
```

```java
import java.util.Scanner;

// Program Initials
// Builds the uppercase initials of a full name.
public class Initials {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // Dictionary
        String name;

        // Algorithm
        System.out.print("Full name: ");
        name = input.nextLine();
        System.out.println("Initials : " + initials(name));
    }

    // Function Initials
    // Returns the first letter of every word in s, in uppercase
    static String initials(String s) {
        String result = "";
        for (int i = 0; i < s.length(); i++) {
            if (s.charAt(i) != ' ' && (i == 0 || s.charAt(i - 1) == ' ')) {
                result = result + Character.toUpperCase(s.charAt(i));
            }
        }
        return result;
    }
}
```

This reuses the "start of a word" condition from Exercise 1. Instead of counting each word start, it collects the character there, converted to uppercase. Recognizing that two problems share the same core idea is how experienced programmers solve new problems quickly.

```bash
javac Initials.java
java Initials
```

Output:

```text
Full name: budi santoso wijaya
Initials : BSW
```

---

## Next Up - Lesson 18

In this lesson you learned to treat a string as a sequence of characters. You traversed strings with `length()` and `charAt()`, counted characters by category, built new strings piece by piece, compared strings correctly with `equals` and `compareTo`, checked passwords with flags, and tested palindromes with two markers. You also learned that strings are immutable and must never be compared with `==`.

So far, related data has been kept in separate variables or parallel arrays: a student's name in one array, their score in another. In Lesson 18 you will group related values into a single **record** type in notation, implement it in Java with the `record` keyword, and combine records with arrays to store lists of structured data, the last building block you need before the searching, sorting, and final project lessons.
