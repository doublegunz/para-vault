## 1. Before You Begin

### Introduction

Welcome to the PHP OOP course. You have completed the PHP Fundamental course and can write procedural PHP that connects to a database, handles form submissions, and manages sessions. That is a solid foundation. Now it is time to organize that knowledge into something that scales.

Object-Oriented Programming (OOP) is not a replacement for what you already know. It is a way to **reorganize** the same concepts (variables, functions, arrays, database queries) into a structure that is easier to maintain, extend, and understand as projects grow larger.

In this first lesson, there is no code to write. The focus is on understanding what you will build, why OOP matters before frameworks, and what the course roadmap looks like.

### What You'll Learn

- ✅ Why OOP is a required step before learning frameworks like Laravel
- ✅ How each concept from procedural PHP maps to an OOP equivalent (see the comparison table in section 3)
- ✅ What Catatku looks like and which features you will build
- ✅ The full 14-lesson roadmap: what each lesson covers and why it is in that order

### What You'll Need

- The PHP Fundamental course completed (variables, arrays, functions, forms, PDO, sessions)
- Laragon installed with PHP 8.3 and Composer
- VS Code installed

---

## 2. Why OOP Before Frameworks? {#why-oop-before-frameworks}

Every major PHP framework (Laravel, Symfony, CodeIgniter) is built entirely with OOP. When you open a Laravel project and see code like `$request->validate([...])` or `Entry::where('user_id', $userId)->get()`, you are looking at objects, methods, classes, and inheritance.

If you jump straight from procedural PHP to Laravel without understanding OOP, two things happen. First, you learn to use the framework by memorizing patterns without understanding them. Second, the moment something breaks or you need to customize behavior, you are stuck because you cannot read the framework's source code.

This course bridges that gap. You will build the same kind of application you built in the PHP Fundamental course (a journal app called Catatku), but this time using OOP patterns. By the end, when you open a framework project, you will recognize the patterns because you have already built them yourself.

---

## 3. What You Will Build {#what-you-will-build}

You will build **Catatku** again, but with a completely different architecture:

| PHP Fundamental (Procedural) | PHP OOP (This Course) |
|---|---|
| One PHP file per page | Front controller: every request goes through `public/index.php` |
| `$pdo` variable passed around | `Database` class manages the connection |
| `$entry` associative array | `Entry` class with typed properties and methods |
| SQL queries scattered in pages | `EntryRepository` class dedicated to database operations |
| `require 'header.php'` | `View` class that renders templates with a shared layout |
| `if/elseif` for URL routing | `Router` class that maps URLs to controller methods |
| `session_start()` and manual checks | `AuthController` with proper middleware-style protection |

The application will have the same features: user registration, login, CRUD for journal entries, and page protection. But the code will be organized into classes with clear responsibilities.

---

## 4. Course Roadmap {#course-roadmap}

This course is split into six modules. Each module builds directly on the one before it — you cannot skip ahead because every lesson depends on concepts from the previous one.

| Module | Lesson | Title | What You Will Do |
|--------|--------|-------|------------------|
| 1 — Getting Started | 1 | What We Will Build | Understand the application, the roadmap, and why OOP comes before frameworks |
| | 2 | Setting Up Your PHP Project | Install Composer, create the folder structure, and configure PSR-4 autoloading |
| 2 — OOP Fundamentals | 3 | Classes and Objects | Write your first class, create objects, and model a journal entry in OOP |
| | 4 | Constructors and Encapsulation | Learn `__construct()`, visibility modifiers, and how to protect your data |
| | 5 | Namespaces and Autoloading | Organize code with namespaces and eliminate every `require` statement |
| 3 — Database Layer | 6 | Connecting to MySQL with PDO | Build a `Database` class and replace scattered `$pdo` variables with an object |
| | 7 | The Repository Pattern | Create `EntryRepository` to keep all SQL in one dedicated class |
| 4 — Application Architecture | 8 | The Front Controller and Routing | Build a single entry point and a `Router` class that maps URLs to controllers |
| | 9 | Views and Templating | Build a `View` class and a shared layout so HTML is never mixed with logic |
| 5 — Building Catatku | 10 | Displaying and Creating Entries | Build the entry list and create form with validation and flash messages |
| | 11 | Edit and Delete Entries | Complete the CRUD cycle and add ownership checks |
| | 12 | User Authentication | Build registration, login, logout, and middleware-style route protection |
| 6 — Advanced OOP | 13 | Inheritance, Interfaces, and Abstraction | Refactor Catatku with abstract classes and interfaces |
| | 14 | What's Next | Map everything you built to its Laravel/Symfony equivalent and plan your next step |

> **Note:** If you are wondering why the database layer comes before routing and views, it is intentional. You need to know how to fetch data before you build the pages that display it.

---

## 5. Conclusion {#conclusion}

OOP is not about making simple things complicated. It is about making complex things manageable. The journal app is simple enough to learn the patterns without drowning in complexity, but realistic enough that you will see exactly how each pattern solves a real problem.

Every concept you learned in the PHP Fundamental course still applies. Variables become properties. Functions become methods. Arrays of data become objects. `require` becomes autoloading. The tools are the same. The organization is different.

---

## Next Up — Lesson 2: Setting Up Your PHP Project

In the next lesson you will:

1. Create the Catatku project folder and install Composer
2. Configure PSR-4 autoloading so PHP can find your classes automatically
3. Start PHP's built-in development server and verify everything works

No concepts from this lesson need to be memorized before you continue. Everything becomes clearer once you see it in code.