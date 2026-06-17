Welcome to the Learn CodeIgniter 4 course. If you are reading this, chances are you have heard about CodeIgniter before, maybe tried a few tutorials, and now you want to build something real. Not just follow along with pre-made examples, but truly understand how a web application is built from scratch. This course is designed for exactly that.

## Overview {#overview}

### What You'll Build

Throughout this course, you will build **Catatku** ("My Notes" in Indonesian), a personal journal application. You will start from an empty project and end with a fully functional app complete with a database, form validation, and a full authentication system.

### What You'll Learn

- How CodeIgniter processes a web request from URL to response
- The MVC (Model-View-Controller) pattern and why CodeIgniter is built around it
- Database migrations and the Query Builder
- Full CRUD operations (Create, Read, Update, Delete)
- Form validation with user-friendly error messages
- User authentication: registration, login, and logout
- Ownership-based authorization to protect private data
- Filters for route protection (CodeIgniter's equivalent of middleware)

### What You'll Need

- Basic knowledge of PHP (variables, functions, arrays, conditionals)
- Familiarity with HTML and how web pages work
- A computer running Windows (installation guide is covered in Lesson 2)
- About 30 minutes per lesson

---

## About This Course {#about-this-course}

CodeIgniter is a PHP framework known for being lightweight, fast, and easy to learn. Unlike heavier frameworks that impose a steep learning curve, CodeIgniter gives you a solid MVC structure without overwhelming you with abstractions. It has clear documentation, a small footprint, and just enough convention to keep your code organized while still feeling close to native PHP.

This course teaches CodeIgniter 4 through a single, complete project: **Catatku**, a personal journal application. We will build it together from an empty project to a fully working application, complete with a database, validation, and an authentication system. Every concept is introduced when it is needed, not as abstract theory disconnected from context.

### Why a Journal App? {#why-a-journal-app}

Compared to public-facing applications like a Twitter clone, a personal journal app has real pedagogical advantages.

**Authorization feels natural.** Of course you should not be able to read or edit someone else's journal entries. The concept makes immediate sense without lengthy explanations.

**Privacy as a core feature** introduces a query pattern that is extremely common in real-world applications: fetching data scoped to the currently authenticated user.

**Two simple fields (title and body)** allow us to learn realistic form handling and validation without being weighed down by unnecessary complexity. The app is simple on the surface, but underneath it covers routing, MVC, database migrations, the Query Builder, form validation, session-based authentication, and security protections. These are the core concepts you will need in virtually every real CodeIgniter project.

---

## Prerequisites {#prerequisites}

This course is designed for developers who already have a basic understanding of PHP. You know what variables, functions, arrays, and conditionals are. You do not need any prior experience with CodeIgniter, but it will help if you have built a simple web page before and understand how HTML works.

If you are completely new to PHP, it is a good idea to learn the basics of PHP first before continuing. This course will not spend much time explaining fundamental PHP syntax because the focus is on CodeIgniter and the thinking behind it.

---

## What You'll Need to Install {#what-youll-need-to-install}

Before we start building, make sure you have the following tools ready:

**PHP 8.3 or higher.** CodeIgniter 4 requires at least PHP 8.1, but we will use 8.3 for the latest features and best compatibility.

**Composer.** The package manager for PHP. CodeIgniter 4 and all of its dependencies are installed through Composer.

**MySQL.** The database we will use to store user accounts and journal entries. It is usually included in installation packages like Laragon or XAMPP.

**A code editor.** VS Code is the most popular choice and has excellent extensions for PHP development.

Do not worry if you do not have these installed yet. Lesson 2 provides a complete, step-by-step installation guide.

---

## What We Will Build {#what-we-will-build}

By the end of this course, you will have a fully working **Catatku** application with the following features:

**Full authentication.** Users can register a new account, log in, and log out. All journal entries are private. No other user can access your entries.

**Entry listing.** A main page displaying all entries belonging to the logged-in user, sorted from newest to oldest, showing the title and a snippet of the body.

**Create new entries.** A form with validation for writing new journal entries. If any input is invalid, the user gets clear error messages and does not have to start over from scratch.

**Read entries.** A detail page for reading a single entry in full, with information about when it was written and last updated.

**Edit and delete entries.** Users can modify existing entries or delete them, with protections ensuring only the entry owner can perform these operations.

From the outside, Catatku might look simple. But behind it are routing, the MVC pattern, database migrations, the Query Builder, form validation, session-based authentication, Filters, and security protections. These are the core concepts you will need in almost every real CodeIgniter project.

---

## Course Roadmap {#course-roadmap}

This course consists of 12 lessons arranged in a progressive sequence, where each group of lessons builds the foundation for the next.

**Lessons 1 and 2** start with orientation and setup. Before writing a single line of code, we make sure you know where this journey is heading and that your development environment is ready. PHP, Composer, CodeIgniter, and MySQL will be installed, and a fresh project will be running in your browser.

**Lessons 3 and 4** introduce the CodeIgniter way of thinking through routing and the MVC pattern. You will understand how CodeIgniter processes a request: from the incoming URL, to the controller that runs the logic, to the view that generates the output. Understanding this pattern early will make everything else click in later lessons, because you will know *why* code is organized a certain way instead of just following instructions.

**Lessons 5 and 6** dive into the database and models. You will learn migrations, which let you define table structures using PHP code instead of raw SQL, and CodeIgniter's Model class with the Query Builder, which lets you interact with the database using clean, readable methods instead of writing SQL strings.

**Lessons 7, 8, and 9** are the heart of the course. This is where Catatku truly comes to life. We will build the full CRUD operations one by one: listing entries, reading details, creating new entries with form validation, editing existing ones, and deleting with confirmation. After these three lessons, you will have a strong intuition for how data flows from a form in the browser to the database and back to the screen.

**Lessons 10 and 11** add the authentication layer: registration, login, and logout. They also ensure that every entry can only be accessed by its owner. The ownership-based authorization pattern you learn here is something you will encounter repeatedly in almost every real-world application.

**Lesson 12** is not about writing new code. It is a chance to step back, look at everything you have built, and plan your next steps: what features you could add to Catatku on your own, and which advanced CodeIgniter topics are worth exploring next.

---

## Conclusion {#conclusion}

Here is what to keep in mind as you begin this course:

- **Catatku** is a personal journal application that covers all the core CodeIgniter concepts: routing, MVC, migrations, models, CRUD, validation, and authentication.
- The course is structured in **12 progressive lessons**, each building on the previous one.
- You need **basic PHP knowledge** (variables, functions, arrays, conditionals) to follow along. No prior CodeIgniter experience is required.
- **CodeIgniter 4 with PHP 8.3** is the version we will use. Lesson 2 covers the full installation process.
- Every concept is introduced **when it is needed**, not as isolated theory. You will always understand the "why" behind the code.
- Take your time. One lesson fully understood is better than three lessons rushed through.

Let's start building. Head over to **Lesson 2** to set up your development environment.