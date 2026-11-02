---
title: "Learn Symfony for Beginners"
slug: "learn-symfony-for-beginners"
status: "draft"
---

# Learn Symfony for Beginners

## Deskripsi
```
Learn Symfony 8 by building Catatku, a personal journal app with full CRUD, login, registration, and private entries. Go from an empty project to a working application, one concept at a time.
```


## Konten

```
Most Symfony tutorials teach concepts in isolation. You learn routing in one lesson, Doctrine in another, and security somewhere else, but you never see how they all connect inside a real application. This course takes a different approach.

You will build **Catatku**, a personal journal application, from an empty project to a fully working app across 12 structured lessons. Every concept is introduced at the moment you need it, applied immediately, and built upon in the next lesson. By the end, you will not just know Symfony syntax. You will understand why the code is organized the way it is.

The course follows Symfony 8 with PHP 8.4 and covers modern conventions, including PHP attribute-based routing with `#[Route]`, Doctrine ORM entities with attribute mapping, and the Symfony Security component. No starter kits or scaffolding for the application code. You write every controller and template yourself, so nothing feels like magic.

This course is for you if you understand basic PHP but have never used a framework, if you have tried Symfony before but got confused about how all the pieces fit together, or if you want a portfolio-ready project instead of a collection of disconnected exercises.

**Prerequisites:**
- Basic PHP: variables, functions, arrays, and conditionals
- Basic HTML, including how a form submits data to a server
- A computer running Windows (Lesson 2 walks you through installing VS Code, Laragon, PHP 8.4, and Composer)
- No prior Symfony or framework experience required

**By the end, you will have:**
- A working Symfony 8 application you can demo, deploy, or extend on your own
- A solid mental model of how Symfony processes a request from URL to database and back
- Hands-on experience with routing, Twig layouts, Doctrine entities, migrations, repositories, and fixtures
- Create, edit, and delete forms with CSRF protection and field-level validation
- Login, logout, and registration with hashed passwords and private, per-user entries
- The confidence to read the official Symfony documentation and understand it
```

## Daftar Modul

### 1. `Module 1 - Getting to Know Catatku`

```
Get the full picture of the Catatku journal app you will build, then set up VS Code, Laragon, PHP 8.4, and a fresh Symfony 8 project on Windows.
```


- Lesson 1 - What We Will Build
    lesson short description
    ```
    Meet Catatku, the personal journal app you will build in this course, and see the features, prerequisites, and 12-lesson roadmap before writing any code.
    
    ```
- Lesson 2 - Setting Up Your Symfony Project
    lesson short description
    ```
    Install VS Code, Laragon, and PHP 8.4, create a Symfony 8 project with Composer and the webapp package, explore its folders, and run it in the browser.
    
    ```

### 2. `Module 2 - Symfony Foundations`

```
Build your first pages with #[Route] attributes and Twig templates, and learn how the MVC pattern organizes every Symfony application.
```


- Lesson 3 - Your First Route and View
    lesson short description
    ```
    Create your first controllers with #[Route] attributes, pass data from a controller to Twig templates, and check your routes with debug:router.
    
    ```
- Lesson 4 - What is MVC?
    lesson short description
    ```
    Understand the Model, View, and Controller pattern, see where each part lives in a Symfony project, and trace a full request from URL to HTML.
    
    ```

### 3. `Module 3 - Database and Entity`

```
Connect Symfony to MySQL with Doctrine ORM, create the User and Entry entities, run migrations, and load seed data with fixtures.
```


- Lesson 5 - Working with the Database
    lesson short description
    ```
    Connect Symfony to MySQL, create the User and Entry entities with make:user and make:entity, and build the tables with Doctrine migrations.
    
    ```
- Lesson 6 - Your First Entity
    lesson short description
    ```
    Query entries through the Repository pattern, show real database data in Twig, and seed the database with Doctrine Fixtures.
    
    ```

### 4. `Module 4 - Core Features of Catatku`

```
Build the heart of Catatku: a shared Twig layout, the entry list and detail pages, and forms to create, edit, and delete entries with validation and CSRF protection.
```


- Lesson 7 - Displaying Entries List and Detail
    lesson short description
    ```
    Build a reusable base layout with Twig template inheritance and add an entry detail page using route parameters and the entity value resolver.
    
    ```
- Lesson 8 - Writing and Saving Entries
    lesson short description
    ```
    Protect routes with access_control, log in through a temporary dev route, and build a create form with CSRF protection, validation, and flash messages.
    
    ```
- Lesson 9 - Edit and Delete Entries
    lesson short description
    ```
    Complete the CRUD cycle with an edit form, Doctrine change tracking, and POST-only delete actions guarded by ownership checks and per-entry CSRF tokens.
    
    ```

### 5. `Module 5 - User Authentication`

```
Replace the temporary login shortcut with real authentication: log in and out with form_login, then let new users register and get logged in automatically.
```


- Lesson 10 - Basic Authentication: Login and Logout
    lesson short description
    ```
    Configure the form_login authenticator, build the login page and logout, remove the dev login route, and show each user only their own entries.
    
    ```
- Lesson 11 - Basic Authentication: Registration
    lesson short description
    ```
    Build a registration form with validation, hash passwords, block duplicate emails, and log new users in automatically with the Security helper.
    
    ```

### 6. `Module 6 - What's Next?`

```
Review everything you built in Catatku and plan your next steps with feature ideas, a learning roadmap, and recommended resources.
```


- Lesson 12 - What's Next
    lesson short description
    ```
    Look back at the Symfony concepts you mastered, learn which topics come next, and pick feature ideas to keep extending Catatku on your own.
    
    ```
