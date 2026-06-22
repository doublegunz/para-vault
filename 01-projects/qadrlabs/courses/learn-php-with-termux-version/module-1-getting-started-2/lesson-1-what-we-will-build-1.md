## 1. Before You Begin

Welcome to the Learn PHP course, Termux edition. PHP powers over 75% of all websites that use a server-side language, from small blogs to platforms like WordPress, Facebook (in its early years), and Wikipedia. And it all starts with the basics you will learn in this course.

The unique thing about this course is that you will learn PHP using only your **Android phone** and the **Termux** application. You do not need a laptop or computer. Everything from writing code to running a web server to managing a database will happen on your phone.

In this first lesson, there is no code to write. The focus is on understanding what you will build, how PHP works on the server, and what the course roadmap looks like.

### What You'll Build

Throughout this course, you will build a journal page called Catatku where you can create, read, update, and delete entries. It will not be a full application with a polished design. Instead, it will be a set of functional pages that talk to a MariaDB database (MySQL-compatible) and include a simple login system.

### What You'll Learn

- ✅ How PHP works on the server and why it is different from HTML and JavaScript
- ✅ The difference between static HTML and dynamic PHP pages
- ✅ What you will build throughout this course
- ✅ The full course roadmap from setup to authentication

### What You'll Need

- An Android phone
- A stable internet connection (approximately 170MB for initial setup)
- No prior programming experience is required
- Basic knowledge of HTML is helpful but not mandatory

---

## 2. How PHP Works {#how-php-works}

Before writing a single line of code, it helps to understand what PHP actually does when someone visits a page. Most beginners assume the browser runs PHP, just like it runs JavaScript. It does not. PHP runs on the server, and the browser only ever receives the HTML that PHP produces.

Here is what happens when you visit a PHP page:

```
Browser requests page
        |
        v
Server receives request (Apache on your phone)
        |
        v
PHP code runs on the server
(reads database, processes data, makes decisions)
        |
        v
PHP generates HTML
        |
        v
HTML sent to browser
(the browser never sees the PHP code)
```

This is why PHP is called a **server-side** language. In this course, the "server" is Apache running on your phone through Termux, and the "browser" is Chrome or any browser on the same phone. The browser only sees the finished HTML that PHP generates. Your PHP source code is never exposed.

---

## 3. What Is the Difference Between PHP and HTML? {#php-vs-html}

Understanding the boundary between PHP and HTML is one of the most important foundations you will build in this course. They look similar on the surface because PHP files contain both, but they serve completely different purposes.

**HTML** is static. If you write `<h1>Hello</h1>`, it always says "Hello." It cannot change based on who is viewing the page, what time it is, or what data is stored in the database.

**PHP** is dynamic. You can write code that says "If the user is logged in, show their name. Otherwise, show a login link." PHP makes decisions, processes data from a database, and generates different HTML depending on the situation. That is the power this course will give you.

---

## 4. Your Tools {#your-tools}

This course uses four tools, all running on your Android phone inside Termux. You will install each of them in Lesson 2. For now, here is what each one does and why you need it.

**Termux** is a terminal emulator for Android. It gives you a Linux-like command line on your phone where you can install and run software that normally requires a computer.

**Apache** is the web server. When you visit a URL in your browser, Apache is the program that receives the request, passes the PHP file to the PHP engine, and sends the resulting HTML back to your browser.

**MariaDB** is a MySQL-compatible database. It stores your journal entries permanently so that data survives after the browser tab is closed. MariaDB also runs inside Termux.

**micro** is a terminal-based text editor. It is small, fast, and beginner-friendly: you type your code, press Ctrl+S to save, and Ctrl+Q to quit. You will use it to write every PHP file in this course.

---

## 5. Course Roadmap {#course-roadmap}

This section gives you a bird's-eye view of everything in the course so you know where you are at any point and where you are headed.

**Lessons 1 and 2** cover orientation and setup. You will install all the tools and write your first PHP file.

**Lessons 3 and 4** introduce the basics: variables for storing data, operators for performing calculations, and control structures for making decisions with if/else and switch.

**Lessons 5 and 6** make your code smart and efficient. Loops let you repeat actions, and arrays let you store and manage lists of data.

**Lessons 7 and 8** level up your code organization. Functions bundle logic into reusable pieces, and forms let users submit data to your PHP pages.

**Lesson 9** teaches you how to split your code across multiple files using includes, keeping HTML templates separate from PHP logic.

**Lessons 10, 11, and 12** bring in the database. You will connect to MariaDB using PDO, read data from tables, and build a complete CRUD page for your journal.

**Lessons 13 and 14** add the authentication layer with sessions and a simple login system, then close the course with a summary and your recommended next learning path.

---

## Next Up - Lesson 2

PHP is a server-side language: the browser sends a request, the server runs your PHP code, and only the resulting HTML travels back to the browser. Your source code stays on the server and is never exposed. The course project is Catatku, a journal page powered by MariaDB, and every concept you will learn has a direct role in making that project work.

In Lesson 2, you will set up your entire development environment, installing Termux, Apache, PHP, MariaDB, and the micro editor on your Android phone, then writing and running your very first PHP file.