## 1. Before You Begin

Welcome to the Learn PHP for Beginners course. Before you write a single line of code, this lesson gives you a map of where you are headed and explains the fundamentals of how PHP works on the server. Understanding the big picture first means every lesson you follow will feel purposeful rather than abstract.

### Introduction

PHP powers over 75% of all websites that use a server-side language, from small blogs to large platforms like WordPress and Wikipedia. These sites all started from the same building blocks you will learn here: variables, loops, forms, and database interaction. This course starts at absolute zero and builds toward something real: a working, database-driven journal page called Catatku that you build piece by piece over the 14 lessons.

### What You'll Learn

- ✅ How PHP works on the server and why it is different from HTML and JavaScript
- ✅ The difference between static HTML and dynamic PHP pages
- ✅ What you will build throughout this course
- ✅ The full course roadmap from setup to authentication

### What You'll Need

- A computer running Windows (for Laragon), or macOS/Linux if using alternatives
- Basic knowledge of HTML — you know what `<p>`, `<h1>`, `<form>`, and `<input>` tags are
- No prior programming experience is required

---

## 2. What You Will Build

Throughout this course, you will build toward a **journal page** called Catatku where you can create, read, update, and delete entries. It will not be a full application with polished design yet. Instead, it will be a functional set of PHP pages that talk to a MySQL database and include a simple login system. Think of it as the engine before the car body.

Every concept in this course exists to serve that project. You learn variables to hold entry data, arrays to manage lists of entries, functions to organize your code, forms to accept user input, and PDO to save everything in a database. By the end of Lesson 13, you will be able to open a browser, log in, write a journal entry, edit it, and delete it — all powered by code you wrote yourself.

---

## 3. How PHP Works

When you open a webpage, your browser sends a request to a server. If the page is a plain `.html` file, the server sends it back exactly as written. But if the page is a `.php` file, something different happens: the server runs the PHP code first, generates HTML from it, and then sends the resulting HTML to the browser.

```
Browser requests page
        |
        v
Server receives request
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

This is why PHP is called a **server-side** language. The code runs on the server, not in the browser. JavaScript runs in the browser (client-side). PHP runs before the page ever reaches the browser. The browser only receives the finished HTML that PHP produces.

This architecture has an important security consequence: users can never see your PHP code. Database passwords, business logic, and user data processing all happen on the server, invisible to anyone inspecting "View Source" in the browser.

---

## 4. Static HTML vs Dynamic PHP

This comparison is fundamental to understanding why PHP exists.

**HTML** is static. If you write `<h1>Hello</h1>`, it always says "Hello." It cannot change based on who is viewing the page, what time it is, or what is stored in a database. Every visitor gets the exact same file.

**PHP** is dynamic. You can write logic that says "If the user is logged in, show their name. Otherwise, show a login link." PHP makes decisions, processes data, and generates different HTML for different situations. This is why every login page, shopping cart, search result, and personalized feed on the internet is backed by a server-side language like PHP.

In this course, you will write PHP that generates HTML. The browser still displays HTML, but the HTML is created fresh on every request because PHP builds it on the fly based on the current situation.

---

## 5. Course Roadmap

This course consists of 14 lessons arranged in a progressive sequence where each lesson builds on what came before.

**Lessons 1 and 2** cover orientation and setup. Before writing a single line of code, you understand the destination and get your development environment ready. You should resist the urge to skip Lesson 2 even if you think setup is obvious, because understanding how Laragon works will help you debug problems later.

**Lessons 3 and 4** introduce the fundamentals: variables for storing data, operators for performing calculations, and control structures for making decisions. These are the building blocks every program is made from.

**Lessons 5 and 6** add power and efficiency. Loops repeat actions automatically, and arrays organize entire collections of data into a single variable.

**Lessons 7 and 8** level up your code. Functions bundle reusable logic into named blocks, and forms connect your PHP code to the user through HTML so your program becomes interactive.

**Lesson 9** teaches you how to organize code across multiple files using includes — a crucial skill before projects grow large enough to become unmanageable.

**Lessons 10, 11, and 12** bring in the database. You will connect to MySQL using PDO, read data into listings and detail pages, and complete the full CRUD cycle by adding, editing, and deleting entries through forms.

**Lessons 13 and 14** complete the application. Authentication adds a login system so only registered users can access their private entries, and the final lesson consolidates everything you have learned and maps the path forward.

---

## 6. Understanding PHP's Role

A helpful way to think about where PHP fits is to imagine a restaurant. The HTML page is like the menu customers see — it is what is presented to them. PHP is like the kitchen that prepares each dish fresh based on each order. The database is the pantry where ingredients are stored. The customer (browser) never enters the kitchen; they only receive the finished dish (the HTML). PHP orchestrates all the kitchen work behind the scenes.

This mental model also explains why changing a menu item (updating database content) affects every customer immediately — the kitchen creates each dish from the database on demand rather than serving pre-made food.

---

## 7. Conclusion

Here is what to carry forward as you begin. PHP runs on the server and generates HTML that is sent to the browser. The browser never sees your PHP code. This course starts from zero programming experience, requiring only basic HTML knowledge. Every concept is introduced through practical examples that build toward a journal page connected to a MySQL database. By the end, you will have the foundation to learn PHP OOP and then a framework like Laravel.

**In Lesson 2**, you will set up your development environment, installing VS Code and Laragon, and writing your very first PHP file.