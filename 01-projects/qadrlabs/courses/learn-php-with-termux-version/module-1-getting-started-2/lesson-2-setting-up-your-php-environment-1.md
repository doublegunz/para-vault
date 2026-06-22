## 1. Before You Begin

Unlike a laptop where you install software by clicking buttons, setting up a development environment on Android requires a few terminal commands. But do not worry. This lesson walks you through every step, from installing Termux to running your first PHP file in the browser. Every command is shown exactly as you need to type it.

By the end of this lesson, you will have Apache (web server), PHP (programming language), MariaDB (database), and micro (code editor) all running on your phone, ready to use for the rest of the course.

### What You'll Build

You will install all four development tools, create a project folder in the web server's document root, and write your first PHP file that displays text in the browser.

### What You'll Learn

- ✅ How to install Termux on Android
- ✅ How to install Apache, PHP, MariaDB, and the micro editor
- ✅ How to create and edit PHP files using micro
- ✅ How to start the web server and view PHP pages in the browser
- ✅ How to embed PHP inside HTML

### What You'll Need

- An Android phone
- A stable internet connection (approximately 170MB for downloads)
- About 30 minutes for the full setup

---

## 2. Install Termux

Termux is the foundation of your entire development environment. Everything else runs inside it. Follow the steps below to get it installed correctly.

### Step 1: Download Termux

Open your phone's browser and go to [f-droid.org/en/packages/com.termux/](https://f-droid.org/en/packages/com.termux/). Tap the **Download APK** link to download the latest version.

> **Important:** Do not install Termux from the Google Play Store. The Play Store version is deprecated and no longer updated. Always download from F-Droid.

### Step 2: Install the APK

Open the downloaded APK file. If your phone shows a warning about installing from unknown sources, tap **Settings** and enable "Allow from this source." Then tap **Install** and wait for the installation to finish.

### Step 3: Open Termux

Open the Termux app. You will see a terminal screen with a blinking cursor. This is where you will type all your commands for the rest of the course.

---

## 3. Install PHP and Apache

Apache is the web server that will process your PHP files, and PHP is the language engine that runs your code. A setup script handles everything automatically so you do not have to configure each piece manually.

### Step 1: Run the Setup Script

Type the following command in Termux and press Enter:

```bash
pkg install git -y && cd ~/ && git clone https://github.com/gungunpriatna/termux-php-apache2-setup.git && cd ~/termux-php-apache2-setup && bash setup && cd ~/ && rm -rf termux-php-apache2-setup
```

This command does five things in sequence: it installs `git`, downloads the setup script from GitHub, runs the script to install PHP and Apache, configures Apache to process PHP files, and then removes the setup folder since it is no longer needed.

### Step 2: Wait for Installation

If you see the question `Do you want to continue? [Y/n]`, type `Y` and press Enter. The installation downloads approximately 162MB. Wait until you see this output:

```
PHP and Apache2 Installed Sucessfully...
/sdcard/htdocs - is your document directory..
Place your files in /sdcard/htdocs
Run apachectl
```

This message confirms both PHP and Apache are installed. The `htdocs` folder mentioned here is your web server's document root - any PHP file you place inside it becomes accessible through the browser.

### Step 3: Verify PHP

After the installation finishes, confirm that PHP is available by running:

```bash
php -v
```

You should see output similar to `PHP 8.x.x (cli)`. The version number tells you which PHP release was installed. If this command returns an error, the setup script did not complete successfully - try running it again.

---

## 4. Install MariaDB (MySQL)

MariaDB is the database that will store your journal entries. It is fully compatible with MySQL, which means every MySQL command you will learn in this course works identically with MariaDB. Follow these steps to install and secure it.

### Step 1: Update Packages

Before installing MariaDB, update Termux's package list to make sure you are getting the latest version. Run the following two commands one at a time:

```bash
apt update
```

```bash
apt upgrade
```

If either command asks `Do you want to continue? [Y/n]`, type `Y` and press Enter. The upgrade process ensures your existing packages are up to date and avoids conflicts during installation.

### Step 2: Install MariaDB

Now install MariaDB with the following command:

```bash
pkg install mariadb
```

If asked to continue, type `Y` and press Enter. The installation will take a minute or two. Wait until the terminal returns to the normal prompt before moving on.

### Step 3: Start MariaDB

Before you can interact with the database, you need to start the MariaDB server process. Run:

```bash
mariadbd-safe -u root &
```

The `&` at the end runs MariaDB in the background so it keeps running while you continue working in the terminal. Press Enter if the terminal prompt does not return immediately.

### Step 4: Set the Root Password

By default, MariaDB has no password. You need to set one before the course project connects to it. Log in first:

```bash
mysql -u root
```

You should see the MariaDB prompt: `MariaDB [(none)]>`. Type the following commands one by one and press Enter after each:

```sql
USE mysql;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('1234');
FLUSH PRIVILEGES;
QUIT;
```

`USE mysql` switches to the internal system database where user credentials are stored. `SET PASSWORD` updates the root user's password to `1234`. `FLUSH PRIVILEGES` tells MariaDB to reload the permission tables so the change takes effect immediately. `QUIT` exits the MariaDB shell.

Now test that the new password works:

```bash
mysql -u root -p
```

Type `1234` when prompted for the password. If you see the MariaDB prompt again, the setup is complete. Type `QUIT;` to exit.

---

## 5. Install the micro Editor

micro is the text editor you will use to write every PHP file in this course. It runs inside the terminal, which means you never have to leave Termux to write and save code.

### Step 1: Install micro

Run the following command to install micro through Termux's package manager:

```bash
pkg install micro
```

Wait for the installation to finish. Once it completes, the `micro` command becomes available in your terminal.

### Step 2: Understand micro Basics

micro uses keyboard shortcuts that will feel familiar if you have used any desktop text editor. Here are the ones you will use most often:

| Shortcut | Action |
|----------|--------|
| Ctrl+S | Save the file |
| Ctrl+Q | Quit micro |
| Ctrl+C | Copy selected text |
| Ctrl+V | Paste |
| Ctrl+Z | Undo |
| Ctrl+F | Find text |

To open or create a file, type `micro filename.php` and press Enter. The file opens immediately in the editor. Type your code, press Ctrl+S to save, and Ctrl+Q to quit.

> **Tip on Ctrl key in Termux:** On the Termux keyboard, you can press the Volume Down button together with a letter key to simulate Ctrl. For example, Volume Down + S is the same as Ctrl+S (save).

---

## 6. Create the Project Folder

Your web server's document root is `/sdcard/htdocs`. Any file you place inside this folder (or a subfolder inside it) becomes accessible through the browser. You will create a dedicated folder for this course so all lesson files stay organized.

### Step 1: Create the Folder

Run the following command to create the course folder and the subfolder for this lesson:

```bash
mkdir -p ~/storage/shared/htdocs/learn-php/lesson-02
```

The `-p` flag tells `mkdir` to create all the intermediate directories in one step. This means `learn-php` and `lesson-02` are both created even though neither existed before. You will create a new `lesson-0X` subfolder at the start of each lesson.

### Step 2: Navigate to the Folder

Move into the lesson folder so that any file you create appears in the right location:

```bash
cd ~/storage/shared/htdocs/learn-php/lesson-02
```

You are now inside the folder that your web server serves. Any `.php` file you create here will be reachable in the browser at `http://localhost:8080/learn-php/lesson-02/`.

---

## 7. Your First PHP File: Hello World

Everything is now in place. Let's write an actual PHP file and see it run in the browser. This is the moment the environment stops being abstract and starts being real.

### Step 1: Create the File

Open the micro editor and create a new file called `hello.php`:

```bash
micro hello.php
```

The editor opens immediately. The file does not exist yet on disk - it will be created when you save.

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
echo "Hello, World!";
?>
```

Press **Ctrl+S** (or Volume Down + S) to save, then **Ctrl+Q** (or Volume Down + Q) to quit and return to the terminal.

`<?php` is the PHP opening tag. It tells Apache and the PHP engine that everything following is PHP code to execute. `echo "Hello, World!";` is a PHP statement that outputs the text between the quotes. The semicolon at the end is mandatory - PHP uses it to know where one statement ends and the next begins. `?>` is the closing PHP tag. It is optional when a file contains only PHP code, but including it here makes the structure clear for a first example.

> **Important:** Always access PHP files through `http://localhost:8080/...` in the browser. Opening the file directly from a file manager will show the raw PHP source code, not the result, because only Apache can run PHP.

### Step 3: Start Apache

If Apache is not already running, start it with:

```bash
apachectl
```

Apache will keep running in the background. You only need to start it once per Termux session.

### Step 4: View in the Browser

Open Chrome or any browser on your phone and type this address:

```
http://localhost:8080/learn-php/lesson-02/hello.php
```

You should see the words `Hello, World!` on a plain white page. Congratulations - you just ran your first PHP program on your Android phone.

---

## 8. Echo Variations and Comments

Now that you have confirmed PHP works, it is time to explore what `echo` can produce. PHP's `echo` is not limited to plain text - it can output numbers, HTML tags, and any combination of both.

### Step 1: Create the File

Open a new file called `echo-variations.php`:

```bash
micro echo-variations.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
// This is a single-line comment, ignored by PHP
echo "Welcome to PHP!";
echo "<br>";
echo 'Single quotes also work!';
echo "<br>";
echo 2025;
echo "<br>";

// HTML tags inside echo
echo "<h1>This Is a Big Heading</h1>";
echo "<p>This is a regular paragraph.</p>";

/* This is a multi-line comment.
   PHP ignores everything inside. */
echo "<strong>Bold text</strong>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

Single-line comments start with `//` and tell PHP to ignore everything after them on that line. Multi-line comments are wrapped in `/* ... */` and can span as many lines as needed. Comments are useful for leaving notes in your code without affecting what the browser sees. Notice that `echo` works with both double quotes and single quotes - both produce output, though double quotes allow certain special characters that single quotes do not (you will see this in Lesson 3 with variables).

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-02/echo-variations.php
```

The page renders the HTML tags so you see a large heading and formatted paragraphs, not the raw tag characters. This is PHP generating HTML that the browser then interprets normally.

---

## 9. Mixing PHP with HTML

In real PHP applications, PHP code sits inside an HTML document rather than replacing it entirely. You open and close PHP tags wherever you need dynamic content, and the rest of the file stays as plain HTML.

### Step 1: Create the File

Open a new file:

```bash
micro php-and-html.php
```

### Step 2: Write the Code

Type the following into the editor:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>PHP and HTML</title>
</head>
<body>
    <h1>My First PHP Page</h1>
    <p>This line is plain HTML.</p>

    <?php
        echo "<p>This line is generated by PHP!</p>";
        echo "<p>Today is " . date("l, F j, Y") . "</p>";
        echo "<p>The server time is " . date("H:i:s") . "</p>";
    ?>

    <p>Shorthand: Today is <?= date("l, F j, Y") ?></p>
</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

The `.` operator joins two strings together - this is called concatenation. `date("l, F j, Y")` is a PHP built-in function that returns the current date formatted according to the pattern you pass. `"l"` gives the full weekday name, `"F"` the full month name, `"j"` the day number, and `"Y"` the four-digit year. The `<?= ... ?>` shorthand is equivalent to `<?php echo ... ?>` and is useful for outputting a single value inline inside HTML.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-02/php-and-html.php
```

Refresh the page a few times. The date and time update on every refresh, because PHP generates the output fresh on each request. That is the core behavior that makes PHP dynamic.

---

## 10. Quick Reference: Common Termux Commands

Throughout this course, you will use a small set of terminal commands over and over. The table below collects them in one place for reference.

| Command | What It Does |
|---------|-------------|
| `cd ~/storage/shared/htdocs/learn-php` | Navigate to the project folder |
| `mkdir lesson-03` | Create a new lesson folder |
| `cd lesson-03` | Enter a folder |
| `cd ..` | Go up one folder |
| `ls` | List files in the current folder |
| `micro filename.php` | Open or create a file in the editor |
| `cat filename.php` | View file contents without editing |
| `apachectl` | Start the Apache web server |
| `apachectl stop` | Stop the Apache web server |
| `mysql -u root -p` | Log in to MariaDB |
| `mariadbd-safe -u root &` | Start the MariaDB server |
| `pwd` | Show the current directory path |

---

## 11. Fix the Errors in Your Code

Working PHP code has a strict set of rules. Breaking any one of them causes the page to either show an error message or go completely blank. This section covers the most common mistake beginners make in their first PHP files.

**Error 1: Missing semicolon at the end of a statement.**

PHP uses the semicolon to know where one statement ends and the next begins. Without it, PHP cannot parse your code correctly and throws a parse error - usually pointing to the line *after* the one that is actually missing the semicolon.

```php
// Wrong
echo "This line is correct";
echo "This line forgot something"
echo "This line will cause an error too";

// Correct
echo "This line is correct";
echo "This line now has a semicolon";
echo "Now all three lines execute properly";
```

In the wrong version, the second `echo` has no semicolon. PHP tries to continue reading that statement onto the next line, which causes a parse error on line 3 - even though the actual mistake is on line 2. This off-by-one behavior is why beginners often look at the wrong line when debugging. The fix is simple: every PHP statement must end with `;`, without exception.

---

## 12. Exercises

The exercises below ask you to practice everything you learned in this lesson. Use `micro` to create each file, and view the results in your browser through `http://localhost:8080/learn-php/lesson-02/`.

**Exercise 1:** Navigate to the `lesson-02` folder and create a file called `exercise-1.php`. Display your full name, your city, and your favorite hobby, each on a different line using the `<br>` tag.

**Exercise 2:** Create `exercise-2.php` with a complete HTML page structure (including `<!DOCTYPE html>`, `<html>`, `<head>`, and `<body>` tags). Inside the body, use PHP to output an `<h1>` heading and three `<p>` paragraphs.

**Exercise 3:** Create `exercise-3.php` that uses PHP's `date()` function to display the current date in "Day, Month Date, Year" format and the current time in "HH:MM:SS" format. Add at least one comment in your code.

---

## 13. Solutions

**Solution for Exercise 1:**

Navigate to the lesson folder and open the file in micro:

```bash
micro exercise-1.php
```

Type the following code:

```php
<?php
echo "Name: Budi Santoso";
echo "<br>";
echo "City: Bandung";
echo "<br>";
echo "Hobby: Reading";
?>
```

Press Ctrl+S to save and Ctrl+Q to quit. Open `http://localhost:8080/learn-php/lesson-02/exercise-1.php` in the browser. Each `echo` statement outputs a string, and each `echo "<br>"` inserts an HTML line break between the items. The browser interprets the `<br>` tags and renders each piece of information on its own line.

---

**Solution for Exercise 2:**

```bash
micro exercise-2.php
```

Type the following code:

```php
<!DOCTYPE html>
<html lang="en">
<head><title>About Me</title></head>
<body>
    <?php
        echo "<h1>About Me</h1>";
        echo "<p>Hello! My name is Budi Santoso.</p>";
        echo "<p>I am from Bandung, West Java.</p>";
        echo "<p>I am currently learning PHP on my phone!</p>";
    ?>
</body>
</html>
```

Press Ctrl+S to save and Ctrl+Q to quit. Open `http://localhost:8080/learn-php/lesson-02/exercise-2.php`. The outer HTML structure is static and sent to the browser as-is. The PHP block inside `<body>` runs first and generates four additional HTML elements. The browser receives a complete HTML document and renders it as a formatted page with a heading and three paragraphs.

---

**Solution for Exercise 3:**

```bash
micro exercise-3.php
```

Type the following code:

```php
<?php
// Display the current date
echo "Today is: " . date("l, F j, Y");
echo "<br>";

// Display the current time
echo "Current time: " . date("H:i:s");
echo "<br>";

// Full timestamp
echo "Full timestamp: " . date("Y-m-d H:i:s");
?>
```

Press Ctrl+S to save and Ctrl+Q to quit. Open `http://localhost:8080/learn-php/lesson-02/exercise-3.php`. The `date()` function accepts a format string where each letter is a placeholder: `"l"` is the full weekday name, `"F j, Y"` is the month, day, and year, and `"H:i:s"` is the time in 24-hour format with hours, minutes, and seconds. Every time you refresh the page, `date()` runs again and returns the current server time, so the output changes in real time.

---

## Next Up - Lesson 3

You now have a complete development environment running on your Android phone. PHP files use the `.php` extension and must be processed by Apache before the browser sees any output. The `echo` statement outputs text and HTML tags, every statement ends with a semicolon, and `<?php ... ?>` marks the boundaries of PHP code. The `date()` function demonstrates that PHP generates output dynamically on each request, unlike static HTML.

In Lesson 3, you will learn how to store data in variables, work with different data types (strings, integers, floats, and booleans), and display dynamic content inside HTML pages.