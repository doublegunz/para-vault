If you are reading this, chances are you have heard about Laravel before, maybe tried a few tutorials, and now you want to build something real. Not just follow along with pre-made examples, but truly understand how a web application comes together from scratch. This course is designed for exactly that.

## What You Will Build {#what-you-will-build}

Throughout this course, you will build **Catatku**, a personal journal application. The name means "My Notes" in Indonesian, and the concept is deliberately simple: users can write, read, edit, and delete their own private journal entries. No one else can see them.

From the outside, Catatku looks modest. But underneath it, you will implement everything that makes a real web application work:

- **Routing** - how Laravel maps a URL to the right code
- **MVC pattern** - how controllers, views, and models divide responsibilities
- **Database migrations** - defining table structures using PHP instead of raw SQL
- **Eloquent ORM** - reading and writing to the database with clean, expressive syntax
- **Full CRUD** - creating, reading, updating, and deleting journal entries with proper validation
- **Authentication** - registration, login, and logout, built from scratch
- **Ownership-based authorization** - ensuring users can only access their own data

By the end, you will have a fully working application and a clear mental model of how each piece connects to the others.

### Why a Journal App?

A personal journal is an ideal teaching project for two reasons that go beyond its simplicity.

First, **authorization feels intuitive**. Of course you should not be able to read someone else's journal. The rule makes immediate sense without needing a lengthy explanation, which means we can focus on *how* to enforce it rather than *why* it matters.

Second, **the data scope pattern is universal**. Fetching entries that belong only to the logged-in user, rather than all entries in the database, is one of the most common patterns in real-world applications. Learning it here, in a context that makes sense, means you will recognize it instantly when you encounter it again in your own projects.

## Who This Course Is For {#who-this-course-is-for}

This course is for developers who already have a basic working knowledge of PHP. You should be comfortable with variables, functions, arrays, and conditionals. You do not need any prior experience with Laravel or any other framework.

It will also help if you have built a simple web page before and have a basic understanding of how HTML works. This course will not spend time explaining fundamental PHP syntax, because the focus is entirely on Laravel and the reasoning behind how it works.

If you are completely new to PHP, it is worth learning the basics there first before continuing here.

## What You Will Need {#what-you-will-need}

Before we start building, make sure you have the following tools available:

**PHP 8.3 or higher.** Laravel 13 requires at least PHP 8.3.

**Composer.** The package manager for PHP. Laravel and all of its dependencies are installed through Composer.

**MySQL.** The database we will use to store user accounts and journal entries.

**A code editor.** VS Code is the most popular choice and has excellent extensions for PHP and Laravel development.

There are several ways to get PHP, Composer, and MySQL set up on your machine. You can install each one separately, or use a package that bundles them together. Some popular options include [Laravel Herd](https://herd.laravel.com), [XAMPP](https://www.apachefriends.org), and [Laragon](https://laragon.org). Some of these have paid tiers or paid versions, so it is worth checking before you download.

In this course, we will use **Laragon version 6**, which is completely free and does not require purchasing a license. It bundles PHP, MySQL, and a local server in a single installer, making it the most straightforward option for getting started on Windows.

Do not worry if you do not have any of this set up yet. Lesson 2 covers the full installation process step by step.

## Course Roadmap {#course-roadmap}

This course is structured as 12 progressive lessons. Each group builds directly on what came before.

**Lessons 1-2: Orientation and Setup.**
Before writing a single line of code, you will know where this journey is heading and have a working development environment. By the end of Lesson 2, a fresh Laravel project will be running in your browser.

**Lessons 3-4: Routing and MVC.**
You will learn how Laravel processes a request from the moment a URL is entered to the moment a response is sent back. Understanding this flow early makes everything else click, because you will know *why* code is organized the way it is, not just *what* to type.

**Lessons 5-6: Database and Eloquent.**
You will learn migrations, which define table structures using PHP code, and Eloquent ORM, which lets you interact with the database without writing raw SQL. Instead of `SELECT * FROM entries WHERE user_id = 1`, you simply write `auth()->user()->entries()`.

**Lessons 7-9: Full CRUD.**
This is where Catatku truly comes to life. You will build the complete set of operations: listing entries, reading details, creating new ones with form validation, editing existing ones, and deleting with proper confirmation. After these three lessons, you will have a solid intuition for how data flows from a browser form all the way to the database and back.

**Lessons 10-11: Authentication and Authorization.**
You will add user registration, login, and logout. You will also lock down every entry so that only its owner can read, edit, or delete it. This ownership pattern is something you will encounter in nearly every real-world application you build.

**Lesson 12: Reflection and Next Steps.**
The final lesson is not about writing new code. It is a chance to look back at everything you have built, explore features you could add to Catatku on your own, and map out which advanced Laravel topics are worth exploring next.

## Before You Continue

Every concept in this course is introduced at the moment it is needed, not as abstract theory disconnected from context. You will always understand the *why* behind the code before you write it.

Take your time. One lesson fully understood is worth more than three lessons rushed through.

Head over to **Lesson 2** to set up your development environment and get your first Laravel project running.