## 1. Before You Begin

Welcome to the Learn Symfony course. If you are reading this, chances are you have heard about Symfony before, maybe tried a few tutorials, and now you want to build something real. Not just follow along with pre-made examples, but truly understand how a web application is built from scratch. This lesson is your orientation before any code is written.

Before diving into installation or code, it is worth taking a moment to understand what this course is about and what you will walk away with. Many Symfony tutorials jump straight into commands and configuration, leaving you with a working project but no real sense of *why* it works. This course is different. Every concept is introduced when it is needed and applied immediately in a real application called **Catatku**.

This lesson has no code. Its purpose is to give you the complete picture: what the application looks like when finished, what the 12-lesson journey covers, and what prior knowledge you need to bring.

### What You'll Build

Throughout this course, you will build **Catatku** (which means "My Notes" in Indonesian), a personal journal application. You will start from an empty Symfony 8 project and finish with a fully working application that includes a database, user authentication, form validation, and complete CRUD operations.

### What You'll Learn

- ✅ What the Catatku application looks like when complete
- ✅ Why a personal journal app is an ideal vehicle for learning Symfony
- ✅ What the MVC pattern, Doctrine ORM, Twig, and Symfony Security are
- ✅ What prior knowledge you need before starting
- ✅ How the 12 lessons are structured and what each one covers

### What You'll Need

- Basic knowledge of PHP: variables, functions, arrays, and conditionals
- Familiarity with HTML and how web pages work
- A computer running Windows (the installation guide is in Lesson 2)
- About 30 minutes per lesson

---

## 2. About Catatku

Catatku is the application you will build throughout this entire course. The name comes from the Indonesian word "catat" (to note, to record), combined with the possessive suffix "-ku" (my). It is a personal journal application where each user can write, read, update, and delete their own entries.

The application has two simple fields (title and body), but behind those fields live routing, MVC architecture, Doctrine ORM, Twig templates, form validation, the Symfony Security component, and CSRF protection. These are exactly the core concepts you need for virtually every real Symfony project.

### Why a Journal App?

A personal journal app has real pedagogical advantages over more generic examples like a to-do list or a blog.

**Authorization feels natural.** You obviously should not be able to read or edit someone else's journal. This concept makes complete sense without lengthy explanations, so we can focus on the implementation rather than the business logic motivation.

**Privacy as a core feature** introduces a query pattern that is extremely common in real-world applications: fetching data scoped to the currently authenticated user. Every serious application needs this pattern, and learning it early builds a lasting habit.

**Two simple fields** allow us to learn realistic form handling and validation without being weighed down by unnecessary complexity. The form is simple; the Symfony concepts behind it are not.

---

## 3. What You Will Have When You Finish

By the end of this course, you will have a working Catatku application with the following features.

**Full authentication.** Users can register a new account, log in with an email and password, and log out. Every journal entry is private. No other user can access your entries.

**Entry listing.** A main page showing all entries belonging to the logged-in user, sorted from newest to oldest, with the title and a snippet of the body visible on each card.

**Create new entries.** A form with validation for writing new journal entries. If any input is invalid, the user gets clear field-level error messages and does not lose what they already typed.

**Read entries.** A detail page for reading a single entry in full, showing the title, date written, and the full body text.

**Edit and delete entries.** Users can modify existing entries or remove them entirely, with ownership checks ensuring only the entry author can perform these operations.

---

## 4. Prerequisites

This course is designed for developers who already understand basic PHP. You know what variables, functions, arrays, and conditionals are. You do not need any experience with Symfony or any other framework.

It helps to have built a simple web page before and to understand how HTML works, including the concept of a form submitting data to a server. If you are completely new to PHP, it is worth learning the fundamentals of PHP first, because this course will not pause to explain basic PHP syntax.

---

## 5. The 12-Lesson Roadmap

The course is structured in six modules. Each module builds directly on the previous one.

**Lessons 1 and 2: Getting to Know Catatku.** Orientation and setup. Before writing a single line of code, you understand the full destination and have a working development environment.

**Lessons 3 and 4: Symfony Foundations.** You create your first routes using `#[Route]` PHP attributes, build Twig templates, and understand the MVC pattern that governs everything in Symfony.

**Lessons 5 and 6: Database and Entity.** You connect Symfony to MySQL using Doctrine ORM, define entities with attribute mapping, generate migrations, and learn the Repository pattern for querying data.

**Lessons 7, 8, and 9: Core Features of Catatku.** This is the heart of the course. You build a shared Twig layout, the entries listing and detail page, the create form with validation, and the edit and delete operations. The full CRUD cycle is complete by the end of Lesson 9.

**Lessons 10 and 11: User Authentication.** You build the login and logout system with the `form_login` authenticator, then add user registration with password hashing and automatic login, all using Symfony's Security component.

**Lesson 12: What's Next.** A reflection on everything built, a roadmap for continuing your Symfony journey, and feature ideas for extending Catatku on your own.

---

## 6. Fix the Errors in Your Code

This lesson contains no code, so there are no runtime errors to fix. However, there are two common misunderstandings beginners bring to Symfony that lead to frustration later. Recognizing them now will save you time.

**Error 1: Assuming Symfony is like WordPress or CodeIgniter.**

Symfony is a professional-grade framework built around dependency injection, a service container, and a structured request lifecycle. Patterns that work in simpler systems (such as using global functions or manually creating object instances) do not belong in Symfony code. When you see something like `$this->render(...)` or a method parameter that is auto-injected, that is Symfony working as intended. Trust the pattern.

**Error 2: Skipping Lesson 2 because you think your environment is already ready.**

Symfony 8 requires PHP 8.4 or higher. Many machines have an older version installed by default. Running Symfony on PHP 8.1 or 8.2 will cause surprising errors that have nothing to do with your code. Lesson 2 covers exactly what to install and how to verify it.

---

## 7. Exercises

These exercises are designed to help you think clearly about what you are about to build before writing a single line of code. There is nothing to install or run. Read the questions carefully and write your answers in your own words.

**Exercise 1:** In your own words, what does "MVC" stand for, and what does each part do? You do not need to give a perfect technical definition. Try to explain it as if you were describing it to a friend who has never programmed before.

**Exercise 2:** Look at the feature list in section 3 of this lesson (authentication, listing, create, read, edit, delete). Which of these features do you think will require database interaction? Write down your prediction before seeing how Lessons 5 and 6 approach it.

**Exercise 3:** A personal journal app enforces a rule: user A cannot see user B's entries. At what layer of the application do you think this rule should be enforced (in the database query, in the controller, in the template, or in all three)? Write your reasoning.

---

## 8. Solutions

**Solution for Exercise 1:**

MVC stands for Model, View, and Controller. The Model is responsible for data: it represents what the application knows, typically stored in a database. The View is responsible for presentation: it takes data and displays it as HTML for the user. The Controller is the coordinator: it receives an incoming request, asks the Model for the data it needs, and hands it to the View to produce the response.

In Symfony specifically: Doctrine entities are the Model, Twig templates are the View, and PHP classes in `src/Controller/` are the Controllers.

**Solution for Exercise 2:**

Every one of these features involves the database in some way. Authentication requires a `user` table to look up accounts and verify passwords. The listing, read, and edit features all query the `entry` table. The create feature inserts a new row. The delete feature removes a row. The database is at the center of every meaningful user action in Catatku.

**Solution for Exercise 3:**

The ownership rule should be enforced at the database query layer and at the controller layer. Enforcing it only in the template (by simply not displaying other users' entries) is not safe, because a user could still construct a direct URL to another user's entry and read it. The controller must check ownership before returning any data. The database query should also be scoped to the current user, so only their data is ever loaded into memory. Defense at multiple layers is the correct approach.

---

## Next Up - Lesson 2

In this lesson, you mapped out the full Catatku application: five features, two entities, and a 12-lesson path from empty project to working application. You also clarified the prior knowledge required and understood why a personal journal app is a particularly good vehicle for learning Symfony's core concepts.

In Lesson 2, you will install Visual Studio Code, Laragon, and PHP 8.4, then create a fresh Symfony 8 project and run it in the browser for the first time.