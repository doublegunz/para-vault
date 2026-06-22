## 1. Before You Begin

You are about to write your first line of PHP. But before that, you need a place to write it and a way to run it. Unlike HTML, which you can open directly in a browser by double-clicking a file, PHP requires a web server to execute it. This lesson walks you through installing everything you need and ends with your first working PHP page running in the browser.

### Introduction

This lesson is the only setup lesson in the course, and it is worth taking your time with. A correctly configured development environment prevents a whole category of frustrating problems later. You will install Visual Studio Code as your code editor, install Laragon as your local server environment, create your project folder structure, and write your first PHP program.

### What You'll Build

You will install your development tools, create a project folder inside Laragon's web root, and write three PHP files: a simple Hello World, a demonstration of echo variations and comments, and a page that mixes PHP with HTML to display dynamic content.

### What You'll Learn

- ✅ How to install Visual Studio Code as your code editor
- ✅ How to install Laragon as your local server environment
- ✅ How to create and save a PHP file
- ✅ How to run a PHP file in the browser through a local server
- ✅ How to embed PHP inside HTML using opening and closing tags

### What You'll Need

- A computer running Windows
- An internet connection for downloading software

---

## 2. Install Your Tools

Before writing a single line of code, you need two pieces of software. Visual Studio Code is the editor where you write your PHP files, and Laragon bundles everything a PHP developer needs on Windows into one installer.

### Step 1: Install Visual Studio Code {#step-1-install-visual-studio-code}

#### Download Visual Studio Code {#download-visual-studio-code}

Visual Studio Code (VS Code) is a free, lightweight code editor built by Microsoft. It has become the go-to editor for web developers thanks to its excellent extension ecosystem, built-in terminal, and first-class support for PHP and JavaScript.

Go to the [official Visual Studio Code website](https://code.visualstudio.com/) and click the **Download** button for Windows.

![download visual studio code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/01-download.png)

Wait for the download to complete before moving on.

#### Installation Process {#installation-process}

Once the installer file `VSCodeUserSetup-x64-1.82.2` has been downloaded, double-click it to begin the installation.

1. On the first page, you will be asked to accept the **License Agreement**. Select **I accept the agreement** and click **Next**.

    ![start install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/03-%20setup.png)

2. Choose the directory where you want to install VS Code. The default location is `C:\Program Files\Microsoft VS Code`. You can keep the default or customize it to your preference. Click **Next**.

    ![setup directory vscode](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/04-setup%20direktori.png)

3. On the **Select Additional Tasks** page, check the **Create a desktop icon** option if you want a shortcut on your desktop. Then click **Next**.

    ![select additional task](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/06%20-%20select%20additional%20task.png)

4. On the **Ready to Install** page, click **Install** and wait for the process to finish.

    ![ready to install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/07%20-%20ready%20to%20install.png)

Once the installation is complete, click **Finish** to close the installer.

![finish install visual studio code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/09%20-%20finish.png)

#### Running Visual Studio Code {#running-visual-studio-code}

After installation, you can open VS Code from the desktop icon or through the Windows Start menu. Take a moment to familiarize yourself with the interface. We will be spending a lot of time here throughout this course.



### Step 2: Install Laragon {#step-2-install-laragon}

#### Download Laragon {#download-laragon}

Laragon is an all-in-one local development environment for Windows. It bundles Apache/Nginx, MySQL, PHP, Node.js, and Composer into a single, lightweight package. Unlike heavier alternatives like XAMPP or WAMP, Laragon is fast to start, easy to configure, and designed with modern PHP development in mind.

You can download Laragon from the [official Laragon website](https://laragon.org/index.html). Click the **Download** menu and select the **Laragon - Full** version.

![download laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/01-download.png)

**Important Note:**
- Since Laragon version 7 was released, the download page now serves Laragon version 7. Based on a [discussion in the Laragon repository](https://github.com/leokhoa/laragon/discussions/960), Laragon version 7 **is no longer free** and uses a **Paid Licensing model**.
- If you want to use the **free version of Laragon**, you can download it directly from GitHub: [https://github.com/leokhoa/laragon/releases/download/6.0.0/laragon-wamp.exe](https://github.com/leokhoa/laragon/releases/download/6.0.0/laragon-wamp.exe)

#### Laragon Installation Process {#laragon-installation-process}

Once the `laragon-wamp.exe` file has been downloaded, double-click it to start the installation. Follow these steps:

1. Select the installation language (for example, **English**), then click **Next**.

    ![select language](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/02-pilih-bahasa.png)

2. Choose the installation directory for Laragon. The default is `C:\Laragon`. Click **Next** to continue.

    ![select install location](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/03-pilih-lokasi-install.png)

3. You will see configuration options such as autostart when Windows starts and adding Notepad++ and terminal to Laragon. Choose the options that suit your preference, then click **Next**.

    ![configure laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/04-atur-konfigurasi-laragon.png)

4. On the **Ready to Install** page, click **Install** to begin the Laragon installation process.

    ![ready install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/05-ready-install.png)

5. Wait for the installation to complete. After that, click **Finish** to close the installer and open Laragon.

    ![finish install laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/07-selesai-install.png)

#### Running Laragon {#running-laragon}

After Laragon opens, you will see its intuitive and user-friendly interface.

![laragon main screen](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/08-tampilan-laragon.png)

To start services like Apache and MySQL, simply click **Start All**. Laragon will launch all the services needed for web application development, including Apache, MySQL, and PHP.

### Step 3: Create the Project Folder

Laragon serves files from a specific folder on your hard drive. In Laragon, click the **Root** button — this opens File Explorer at the web root directory, typically `C:\laragon\www\`. Inside this folder, create a new folder called `learn-php`. Inside `learn-php`, create a subfolder called `lesson-02`.

Your folder structure should look like this:

```
C:\laragon\www\
└── learn-php\
    └── lesson-02\
```

Everything you build in this course will live inside `learn-php`, organized by lesson.

### Step 4: Open the Folder in VS Code

Open Visual Studio Code. In the menu bar, go to **File** then **Open Folder**, navigate to `C:\laragon\www\learn-php`, and click **Select Folder**. You will now see the `lesson-02` folder in the Explorer panel on the left side. This is your working environment for the rest of the course.

---

## 3. Your First PHP File

Now that the tools are ready, it is time to write your first PHP program. The classic starting point is a program that simply displays text in the browser.

### Step 1: Create a New File

In the VS Code Explorer panel, right-click on the `lesson-02` folder, select **New File**, type `hello.php`, and press Enter. A blank editor tab opens ready for code.

### Step 2: Write the Code

Open `hello.php` and type the following code:

```php
<?php
echo "Hello, World!";
?>
```

### Step 3: Save the File

Press **Ctrl+S** to save. You will notice the dot on the tab disappears, confirming the file is saved.

### Step 4: Run in the Browser

Open a browser and type the following address, then press Enter:

```
http://localhost/learn-php/lesson-02/hello.php
```

You should see the text `Hello, World!` appear on a blank white page.

Congratulations — you just ran your first PHP program. Notice that you typed the URL starting with `http://localhost/...` rather than opening the file directly from File Explorer. This is because Laragon's Apache server must process the PHP before sending it to the browser. If you double-clicked the file instead, the browser would display the raw PHP code as text.

Now let us understand what each part of the code does. The `<?php` tag is the PHP opening tag. It tells Apache: "Starting here, treat this as PHP code and execute it." Everything after this tag is PHP until the program ends or a closing tag appears. The `echo "Hello, World!";` statement outputs the text between the quotation marks to the browser. The word `echo` is PHP's instruction to send text as output. The semicolon at the end is mandatory — in PHP, every statement must end with a semicolon, just as every English sentence ends with a period. The `?>` is the PHP closing tag, signalling that the PHP block ends here. In files that contain only PHP code, this closing tag is optional, but in files that mix PHP with HTML you will see it frequently.

---

## 4. Echo Variations and Comments

PHP's `echo` can output more than just simple text. It can output numbers, HTML tags, and even dynamic content. This section also introduces comments, which are notes in your code that PHP ignores but that help you and other people understand what the code does.

### Step 1: Create a New File

In the `lesson-02` folder, create a new file called `echo-variations.php`.

### Step 2: Write the Code

Open `echo-variations.php` and type the following code:

```php
<?php
// This is a comment — PHP ignores it completely
// Comments are used to write notes or explanations in the code

echo "Welcome to PHP!";
echo "<br>";

echo 'Single quotes also work for text!';
echo "<br>";

echo 2025;
echo "<br>";

// You can include HTML tags inside echo
echo "<h1>This Is a Big Heading</h1>";
echo "<p>This is a regular paragraph.</p>";

/*
   This is a multi-line comment.
   Use it when your explanation needs more space.
*/
echo "<strong>Bold text</strong>";
?>
```

### Step 3: Save the File

Press **Ctrl+S**.

### Step 4: Run in the Browser

```
http://localhost/learn-php/lesson-02/echo-variations.php
```

The page renders the heading, paragraph, and bold text because the browser receives them as HTML. This is because `echo` sends whatever you put between the quotes directly into the HTML stream. When PHP outputs `<h1>This Is a Big Heading</h1>`, the browser reads it as an HTML heading tag, not as the literal text of those characters.

Looking at each section: the two comment styles, `//` for single-line and `/* */` for multi-line, let you write notes that PHP skips entirely. Comments are invisible to anyone viewing the page in a browser. Both single and double quotes create string values in PHP; the difference between them becomes important in the next lesson when variables are introduced. Outputting a bare number like `2025` works without any quotes because PHP recognizes it as a numeric value.

---

## 5. Mixing PHP with HTML

One of PHP's most important features is that you can drop in and out of PHP mode anywhere inside an HTML document. This lets you write a proper HTML page structure and insert PHP-generated content precisely where you need it.

### Step 1: Create a New File

Create a new file called `php-and-html.php` in the `lesson-02` folder.

### Step 2: Write the Code

Open `php-and-html.php` and type the following code:

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>PHP and HTML</title>
</head>
<body>

    <h1>My First PHP Page</h1>

    <p>This line is plain HTML — always the same.</p>

    <?php
        echo "<p>This paragraph is generated by PHP!</p>";
        echo "<p>Today is " . date("l, F j, Y") . "</p>";
        echo "<p>The server time is " . date("H:i:s") . "</p>";
    ?>

    <p>This is HTML again after the PHP block.</p>

    <p>Shorthand: Today is <?= date("l, F j, Y") ?></p>

</body>
</html>
```

### Step 3: Save the File

Press **Ctrl+S**.

### Step 4: Run in the Browser

```
http://localhost/learn-php/lesson-02/php-and-html.php
```

You will see a complete HTML page where some content is static (the `<h1>` heading and the plain paragraph) and some is dynamic (the date and time lines). If you refresh the page, the time changes each time, but the static HTML remains the same. This is the essence of dynamic web pages.

Let us look at what each part does. Outside `<?php ... ?>` tags, everything is treated as plain HTML and passed to the browser unchanged. Inside the tags, PHP executes. The `date("l, F j, Y")` call invokes a built-in PHP function that returns the current date formatted according to the pattern you provide: `l` gives the full day name (Monday), `F` gives the full month name, `j` gives the day number without leading zeros, and `Y` gives the four-digit year. The dot (`.`) between strings joins them together — this is PHP's concatenation operator. On the last line, `<?= ... ?>` is a shorthand that means the same as `<?php echo ... ?>`. It is a convenient shortcut that you will see frequently and can use anywhere you need to output a single value.

---

## 6. Run and Test

Take a moment to verify your understanding of what you have built before moving forward. Open all three files in the browser and confirm you can see their output. Then try one additional experiment that will cement the most important concept from this lesson.

Using File Explorer, navigate to `C:\laragon\www\learn-php\lesson-02\` and double-click `hello.php`. Notice that the browser either shows an error, displays the raw PHP code as text, or prompts you to download the file — but it definitely does not run the PHP and show "Hello, World!" This happens because double-clicking opens the file directly without going through Laragon's Apache server, so nothing executes the PHP. When you access the same file through `http://localhost/learn-php/lesson-02/hello.php`, Apache receives the request, PHP processes the file, and only the output reaches the browser.

This single experiment demonstrates why the correct URL matters: **always access PHP files through the `http://localhost/...` address, never by opening them directly from File Explorer.**

---

## 7. Fix the Errors in Your Code

Look at the following code before running it and identify the mistakes:

```php
<?php
echo "This line is correct";
echo "This line forgot something"
echo "This line will cause an error too";
?>
```

This code has one error that prevents everything from working. The second `echo` statement is missing a semicolon at the end. When PHP encounters the third `echo` without a semicolon terminating the second statement, it cannot parse the code and throws a syntax error. The error message typically says something like "syntax error, unexpected token `echo`" and points to the third line, which is slightly confusing since the actual problem is on the second line. This is because PHP did not know the second statement ended until it ran into the unexpected next statement.

The corrected code:

```php
<?php
echo "This line is correct";
echo "This line now has a semicolon";
echo "Now all three lines execute properly";
?>
```

---

## 8. Exercises

**Exercise 1:** In the `lesson-02` folder, create a file called `exercise-1.php` that displays your full name, your city, and your favorite hobby, with each piece of information on its own line using the `<br>` tag.

**Exercise 2:** In the `lesson-02` folder, create a file called `exercise-2.php` with a complete HTML page structure including `<!DOCTYPE html>`, `<html>`, `<head>`, and `<body>` tags. Inside the body, use PHP to output an `<h1>` heading and three `<p>` paragraphs.

**Exercise 3:** In the `lesson-02` folder, create a file called `exercise-3.php` that displays the current date and time using `date()`. Show the date in the format "Day, Month Date, Year" and the time in "HH:MM:SS" format. Add at least one comment to explain what the file does.

---

## 9. Solutions

**Solution for Exercise 1:**

```php
<?php
// Display personal information, each on its own line
echo "Name: Budi Santoso";
echo "<br>";
echo "City: Bandung";
echo "<br>";
echo "Hobby: Reading";
?>
```

Run at: `http://localhost/learn-php/lesson-02/exercise-1.php`

**Solution for Exercise 2:**

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>About Me</title>
</head>
<body>
    <?php
        echo "<h1>About Me</h1>";
        echo "<p>Hello! My name is Budi Santoso.</p>";
        echo "<p>I am from Bandung, West Java.</p>";
        echo "<p>I am currently learning PHP programming.</p>";
    ?>
</body>
</html>
```

Run at: `http://localhost/learn-php/lesson-02/exercise-2.php`

**Solution for Exercise 3:**

```php
<?php
// Display the current date in a readable format
echo "Today is: " . date("l, F j, Y");
echo "<br>";

// Display the current time in 24-hour format
echo "Current time: " . date("H:i:s");
echo "<br>";

// Display both together as a full timestamp
echo "Full timestamp: " . date("Y-m-d H:i:s");
?>
```

Run at: `http://localhost/learn-php/lesson-02/exercise-3.php`

---

## 10. Understanding Your Development Environment

Before moving forward, it is worth understanding why each piece of your setup exists and what it contributes. Laragon gives you Apache, which is the web server that listens for incoming HTTP requests and hands PHP files to the PHP interpreter. The PHP interpreter executes your code and hands the output back to Apache, which then sends it to your browser. MySQL is the database engine that stores data permanently, which you will connect to starting in Lesson 10. Visual Studio Code is simply your editing tool — it does not run anything, it just provides a comfortable environment for writing and organizing files. The combination of these three components (web server, language interpreter, database) running on your local machine mirrors almost exactly what a real production web hosting environment looks like.

---

## 11. Conclusion

You now have a working development environment and have successfully run PHP code in the browser. PHP files use the `.php` extension and must always be accessed through `http://localhost/...` because they need Apache to execute them. The `echo` statement outputs text, every PHP statement ends with a semicolon, and `<?php ... ?>` marks PHP code blocks inside HTML. Comments (`//` and `/* */`) are invisible to the browser but invaluable for explaining your code to yourself and others.

**In Lesson 3**, you will learn how to store data in variables and work with PHP's four fundamental data types: integers, floats, strings, and booleans.