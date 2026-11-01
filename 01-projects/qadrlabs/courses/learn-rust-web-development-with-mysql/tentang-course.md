---
title: "Learn Rust Web Development with MySQL: Build a To-Do Web App"
slug: "learn-rust-web-development-with-mysql"
status: "draft"
---

# Learn Rust Web Development with MySQL: Build a To-Do Web App

## Deskripsi
```
Turn your Rust skills into a real web app. Build a MySQL-backed to-do application with Axum, SQLx, and Askama, covering async basics, routing, templates, CRUD, forms, validation, categories, error handling, and tests.
```


## Konten

```
The first Rust course ended with a command-line to-do list that saved its tasks to a text file. It worked, but only for one person, in one terminal, with one file. Real applications usually live on the web and keep their data in a database, so many people can use them from a browser while the data stays safe, structured, and easy to query. This course takes that next step: you will rebuild the to-do list as a web application backed by MySQL.

You will use a small, popular stack that fits Rust well. Tokio runs asynchronous code, Axum handles routing and requests, SQLx talks to MySQL, and Askama renders HTML pages from templates that the compiler checks for you. There is no JavaScript framework involved; pages are rendered on the server and forms are submitted the classic way, which keeps the focus on Rust and the database. Async Rust is introduced from the ground up, because the first course did not cover it.

The course follows one project from start to finish. Each lesson adds one feature to the same application: first a plain web server, then templates, then a database connection and migrations, then full create, read, update, and delete for tasks. After that, you add form validation, a custom error type, categories linked with foreign keys, and filtering, search, and pagination. The final lessons organize the code into modules, test handlers and queries against a real test database, and prepare a release build. Every step is small, runs on its own, and is followed by fixes for common mistakes and exercises.

**Prerequisites:**
- Completion of "Learn Rust for Beginners" or equivalent knowledge: structs, enums, Option and Result, the ? operator, traits, modules, and cargo test
- A computer running Ubuntu (or another Linux distribution) with the Rust toolchain installed
- MySQL or MariaDB installed locally, with permission to create a database and a user
- Basic HTML and SQL (SELECT, INSERT, UPDATE, DELETE); the qadrlabs HTML and SQL courses cover what you need
- An internet connection to download crates with Cargo

**By the end, you will have:**
- A clear picture of how a browser, a web server, and a database work together
- A working understanding of async Rust with async functions, .await, and the Tokio runtime
- An Axum application with routes, handlers, extractors, and shared state
- Server-rendered HTML pages built with Askama templates and layouts
- A MySQL database managed with SQLx connection pools and sqlx-cli migrations
- Full CRUD for tasks with HTML forms, redirects, and input validation
- A custom error type that turns failures into proper HTTP responses
- Categories linked with foreign keys, plus joins, filtering, search, and pagination
- Tests for handlers and queries that run against a real test database
- A complete to-do web application that grows directly out of the first course's command-line project
```

## Daftar Modul

### 1. `Module 1 - Foundations`

```
See how a browser, a web server, and a database work together, learn async Rust with Tokio, and prepare the MySQL database the to-do app will use.
```


- Lesson 1 - From the Command Line to the Web
    lesson short description
    ```
    Compare the command-line to-do list with a web version, follow an HTTP request from the browser to the server and the database, and meet the crates used in this course.
    
    ```
- Lesson 2 - Async Rust with Tokio
    lesson short description
    ```
    Write async functions, wait for them with .await, run them on the Tokio runtime, and use tokio::spawn and tokio::join to see why web servers handle many requests at once.
    
    ```
- Lesson 3 - Preparing MySQL for the Project
    lesson short description
    ```
    Create the project database and a dedicated MySQL user, grant the right privileges, and test the connection and a few queries from the mysql client.
    
    ```

### 2. `Module 2 - Your First Axum Server`

```
Start the to-do web app with Axum: define routes and handlers, read data from paths, query strings, and forms, and render HTML pages with Askama templates.
```


- Lesson 4 - Routes and Handlers
    lesson short description
    ```
    Create the Cargo project, add Axum and Tokio, start a server, and map URLs to async handler functions that return text, HTML, and status codes.
    
    ```
- Lesson 5 - Extractors: Path, Query, and Forms
    lesson short description
    ```
    Read values from the URL path, the query string, and submitted HTML forms with Axum extractors and serde, and redirect the browser after a POST request.
    
    ```
- Lesson 6 - HTML Templates with Askama
    lesson short description
    ```
    Render pages with Askama templates checked at compile time, share a base layout through template inheritance, and use loops and conditions inside templates.
    
    ```

### 3. `Module 3 - Connecting to MySQL with SQLx`

```
Connect the app to MySQL with SQLx: load configuration from a .env file, share a connection pool, manage the schema with migrations, and map rows to Rust structs.
```


- Lesson 7 - Configuration and Connection Pools
    lesson short description
    ```
    Store the database URL in a .env file, load it with dotenvy, create a MySQL connection pool with SQLx, and share it with every handler through Axum state.
    
    ```
- Lesson 8 - Migrations with sqlx-cli
    lesson short description
    ```
    Install sqlx-cli, create and run migrations for the tasks table, revert them when needed, and run pending migrations automatically when the app starts.
    
    ```
- Lesson 9 - Querying Data with query_as and FromRow
    lesson short description
    ```
    Run SELECT and INSERT statements with SQLx, bind parameters safely, map rows to a Task struct with FromRow, and choose between fetch_all, fetch_one, and fetch_optional.
    
    ```

### 4. `Module 4 - CRUD for Tasks`

```
Build full create, read, update, and delete features for tasks, connecting HTML pages and forms to MySQL queries.
```


- Lesson 10 - Listing and Showing Tasks
    lesson short description
    ```
    Show every task from MySQL on the home page, add a detail page for a single task, and return a 404 page when a task does not exist.
    
    ```
- Lesson 11 - Creating Tasks with Forms
    lesson short description
    ```
    Add a form for new tasks, insert them into MySQL with a parameterized query, and redirect back to the list with the Post/Redirect/Get pattern.
    
    ```
- Lesson 12 - Editing, Completing, and Deleting Tasks
    lesson short description
    ```
    Edit a task's title and due date, mark tasks as done or not done, and delete tasks with POST forms, checking how many rows each query affected.
    
    ```

### 5. `Module 5 - Validation and Errors`

```
Make the app safe and friendly: validate form input, show errors next to the fields, and turn database and other failures into proper HTTP responses.
```


- Lesson 13 - Validating Form Input
    lesson short description
    ```
    Validate titles and dates on the server, show error messages next to the form fields, and keep what the user typed when a form is submitted with mistakes.
    
    ```
- Lesson 14 - A Custom Error Type with IntoResponse
    lesson short description
    ```
    Create an AppError enum, convert SQLx errors into it with From and the ? operator, and implement IntoResponse so failures become friendly error pages.
    
    ```

### 6. `Module 6 - Categories and Queries`

```
Organize tasks into categories with a second table and a foreign key, then use joins, filters, search, and pagination to find tasks quickly.
```


- Lesson 15 - Categories and Foreign Keys
    lesson short description
    ```
    Add a categories table with a migration, link tasks to categories with a foreign key, manage categories with CRUD pages, and choose a category in the task form.
    
    ```
- Lesson 16 - Joins, Filtering, Search, and Pagination
    lesson short description
    ```
    Show category names with a JOIN, filter tasks by status and category, search titles with LIKE, and split long lists into pages with LIMIT and OFFSET.
    
    ```

### 7. `Module 7 - Structure, Testing, and Wrap-Up`

```
Organize the code into modules, test handlers and queries against a real test database, and prepare the finished app for a release build.
```


- Lesson 17 - Organizing the Project with AppState and Modules
    lesson short description
    ```
    Split the growing main.rs into modules for routes, handlers, models, and errors, group shared resources in an AppState struct, and build the router in one place.
    
    ```
- Lesson 18 - Testing Handlers and Queries with sqlx::test
    lesson short description
    ```
    Test database queries with #[sqlx::test] and a fresh test database, and test full HTTP requests to handlers with tower's oneshot without starting a server.
    
    ```
- Lesson 19 - Logging, Static Files, and a Release Build
    lesson short description
    ```
    Log requests with tracing and tower-http, serve a CSS file as a static asset, build an optimized release binary, and review the finished to-do web app.
    
    ```
