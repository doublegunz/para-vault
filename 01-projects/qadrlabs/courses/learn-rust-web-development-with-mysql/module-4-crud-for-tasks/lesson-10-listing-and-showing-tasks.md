## 1. Before You Begin

Module 3 prepared everything the database side needs: a connection pool shared through Axum state (Lesson 7), a `tasks` table created by a migration (Lesson 8), and a set of tested SQLx queries in a playground (Lesson 9). The web pages, however, still read from `sample_tasks()`, a hard-coded vector. Module 4 replaces that fake data with MySQL, one feature at a time, until Todo Web can create, read, update, and delete tasks.

This lesson covers the "read" part. You will move the queries from the playground into the application, make the home page count tasks from the database, list and search the real tasks, and give every task a detail page. Database errors also need a plan now: a query can fail at any time, and the user should see a friendly message instead of a crashed request.

### What You'll Build

Todo Web reading from MySQL: the home page shows how many tasks are unfinished, `/tasks` lists every task from the `tasks` table (unfinished first) with its due date and a working search, `/tasks/{id}` shows a task's status, due date, and creation time, and a task ID that does not exist returns the templated 404 page.

### What You'll Learn

- ✅ How to replace sample data with SQLx queries inside Axum handlers
- ✅ How to combine `State`, `Path`, and `Query` extractors in one handler
- ✅ How to return `Result` from a handler and turn database errors into a `500` response with `map_err`
- ✅ How to search with `LIKE` while still using bound parameters
- ✅ How to display `Option` values and format dates in Askama templates
- ✅ How to turn `fetch_optional`'s `None` into a 404 page

### What You'll Need

- The `todo-web` project from Lesson 9
- A few rows in the `tasks` table; the playground from Lesson 9 left two (`Learn Rust` and `Build a web app`)

---

## 2. Move the Task Model and Queries into the App

The playground proved that the queries work. Now they move into `src/main.rs`, next to the handlers that will use them. For now, everything stays in one file; Lesson 17 splits it into modules.

### Step 1: Update the Imports and the Task Struct

Replace the top of `src/main.rs`, from the `use` lines down to and including `sample_tasks()`, with:

```rust
use askama::Template;
use axum::{
    Form, Router,
    extract::{Path, Query, State},
    http::StatusCode,
    response::{Html, IntoResponse, Redirect, Response},
    routing::get,
};
use chrono::{NaiveDate, NaiveDateTime};
use serde::Deserialize;
use sqlx::MySqlPool;
use sqlx::mysql::MySqlPoolOptions;

#[derive(sqlx::FromRow)]
struct Task {
    id: u64,
    title: String,
    done: bool,
    due_date: Option<NaiveDate>,
    created_at: NaiveDateTime,
}
```

`sample_tasks()` is gone. The `Task` struct now derives `sqlx::FromRow`, like the playground version, and has two new fields: the optional `due_date` and `created_at`, a `NaiveDateTime` (a date with a time) that matches the `DATETIME` column. The `chrono` import provides both types.

### Step 2: Update the Home Template Struct

The home page will show two counts from the database. Replace `HomeTemplate` with:

```rust
#[derive(Template)]
#[template(path = "home.html")]
struct HomeTemplate {
    pending: i64,
    total: i64,
}
```

The fields are `i64` because MySQL's `COUNT(*)` returns a `BIGINT`, as you saw in Lesson 9. The `db_version` field from Lesson 7 is no longer needed; `/health` still checks the database. The other template structs (`TaskListTemplate`, `TaskShowTemplate`, `NewTaskTemplate`, and `NotFoundTemplate`) and the `TaskFilter` and `NewTask` structs stay as they are.

### Step 3: Add the Query Functions

Add these three functions below the `NewTask` struct:

```rust
async fn search_tasks(pool: &MySqlPool, search: &str) -> Result<Vec<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>(
        "SELECT id, title, done, due_date, created_at FROM tasks
         WHERE title LIKE CONCAT('%', ?, '%')
         ORDER BY done, id",
    )
    .bind(search)
    .fetch_all(pool)
    .await
}

async fn find_task(pool: &MySqlPool, id: u64) -> Result<Option<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>(
        "SELECT id, title, done, due_date, created_at FROM tasks WHERE id = ?",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
}

async fn count_tasks(pool: &MySqlPool) -> Result<(i64, i64), sqlx::Error> {
    let total = sqlx::query_scalar("SELECT COUNT(*) FROM tasks")
        .fetch_one(pool)
        .await?;
    let pending = sqlx::query_scalar("SELECT COUNT(*) FROM tasks WHERE done = FALSE")
        .fetch_one(pool)
        .await?;
    Ok((total, pending))
}
```

Here is what each one does:

- `search_tasks` moves the search from Rust into SQL. `LIKE` compares text with a pattern in which `%` means "any characters," so `%rust%` matches every title containing `rust`. The pattern is built inside MySQL with `CONCAT('%', ?, '%')`, so the user's text is still sent through a placeholder and can never become part of the SQL. An empty search becomes `%%`, which matches every title, so the same query serves both the full list and search results. The `utf8mb4_unicode_ci` collation from Lesson 3 makes the comparison case-insensitive. `ORDER BY done, id` sorts by `done` first (`0` before `1`), so unfinished tasks come first, each group in creation order.
- `find_task` is the playground function with the new column. A string literal can span several lines, and MySQL does not mind the line breaks and spaces.
- `count_tasks` runs two `COUNT(*)` queries and returns both numbers as a tuple. The types of `total` and `pending` are inferred from the return type, `(i64, i64)`.

---

## 3. Handle Database Errors in Handlers

Every query returns a `Result`. A handler cannot just `.expect()` it: a panic would abort the request, and the user would get an empty error. The handler should return a proper `500 Internal Server Error` page instead, and the details should go to the server log, not to the user.

### Step 1: Add the internal_error Helper

Add this function below `not_found_page`:

```rust
fn internal_error(err: sqlx::Error) -> (StatusCode, String) {
    eprintln!("database error: {err}");
    (
        StatusCode::INTERNAL_SERVER_ERROR,
        String::from("Something went wrong. Please try again later."),
    )
}
```

The function takes a `sqlx::Error` and turns it into a response value: a status code and a message. It prints the real error to standard error with `eprintln!`, which shows up in the terminal where the server runs. The user only sees a generic message, because error details such as table names or SQL fragments can help an attacker and do not help the user. In Lesson 14, this helper grows into a proper error type.

### Step 2: Rewrite the Reading Handlers

Replace the `home`, `list_tasks`, and `show_task` handlers with:

```rust
async fn home(State(pool): State<MySqlPool>) -> Result<Response, (StatusCode, String)> {
    let (total, pending) = count_tasks(&pool).await.map_err(internal_error)?;
    Ok(render(HomeTemplate { pending, total }))
}

async fn list_tasks(
    State(pool): State<MySqlPool>,
    Query(filter): Query<TaskFilter>,
) -> Result<Response, (StatusCode, String)> {
    let search = filter.search.unwrap_or_default();
    let tasks = search_tasks(&pool, &search).await.map_err(internal_error)?;
    Ok(render(TaskListTemplate { tasks, search }))
}

async fn show_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, (StatusCode, String)> {
    let task = find_task(&pool, id).await.map_err(internal_error)?;
    match task {
        Some(task) => Ok(render(TaskShowTemplate { task })),
        None => Ok(not_found_page("That task does not exist.")),
    }
}
```

The pattern is the same in all three:

- The return type is `Result<Response, (StatusCode, String)>`. Axum accepts it because both sides implement `IntoResponse`: `Ok` becomes the page, `Err` becomes the error response.
- `.map_err(internal_error)` converts a `sqlx::Error` into the handler's error type, and `?` returns early if the query failed. You passed a function name to `map_err`, which works just like a closure that calls it.
- `list_tasks` and `show_task` use two extractors each. `State` comes first; `Query` and `Path` do not consume the body, so their order does not matter, but keeping state first is a common convention.
- In `show_task`, a missing task is `Ok(None)`, not an error, so it becomes the 404 page from Lesson 6, wrapped in `Ok`.

The other handlers (`health`, `new_task_form`, `create_task`, and `not_found`) and `main` do not change.

---

## 4. Show the Real Data in Templates

The templates still expect the old fields. The list and detail pages should show due dates, and the detail page should also show when a task was created.

### Step 1: Update the Home Page

Replace `templates/home.html` with:

```html
{% extends "base.html" %}

{% block content %}
<h1>Todo Web</h1>
<p>You have {{ pending }} unfinished tasks out of {{ total }}.</p>
<p><a href="/tasks">See all tasks</a> or <a href="/tasks/new">add a new one</a>.</p>
{% endblock %}
```

### Step 2: Show Due Dates in the List

Replace `templates/tasks/list.html` with:

```html
{% extends "base.html" %}

{% block title %}Tasks - Todo Web{% endblock %}

{% block content %}
<h1>Tasks</h1>

<form method="get" action="/tasks">
  <input name="search" value="{{ search }}" placeholder="Search tasks">
  <button type="submit">Search</button>
</form>

{% if tasks.is_empty() %}
  <p>No tasks found.</p>
{% else %}
  <ul>
    {% for task in tasks %}
      <li>
        {% if task.done %}[x]{% else %}[ ]{% endif %}
        <a href="/tasks/{{ task.id }}">{{ task.title }}</a>
        {% if let Some(date) = task.due_date %}(due {{ date }}){% endif %}
      </li>
    {% endfor %}
  </ul>
{% endif %}
{% endblock %}
```

The only new line is `{% if let Some(date) = task.due_date %}`. It works exactly like `if let` in Rust: when the task has a due date, `date` holds it and the text is printed; when the field is `None`, nothing is printed. A `NaiveDate` displays as `2026-11-30`.

### Step 3: Show the Details

Replace `templates/tasks/show.html` with:

```html
{% extends "base.html" %}

{% block title %}{{ task.title }} - Todo Web{% endblock %}

{% block content %}
<h1>{{ task.title }}</h1>
<p>Status: {% if task.done %}done{% else %}not done{% endif %}</p>
<p>Due date: {% if let Some(date) = task.due_date %}{{ date.format("%d %B %Y") }}{% else %}none{% endif %}</p>
<p>Created: {{ task.created_at.format("%Y-%m-%d %H:%M") }}</p>
<p><a href="/tasks">Back to all tasks</a></p>
{% endblock %}
```

Templates can call methods, so dates can be formatted right where they are shown. chrono's `format` takes a pattern: `%d` is the day, `%B` the full month name, `%Y` the four-digit year, and `%H:%M` the hours and minutes. The detail page shows `30 November 2026`, a friendlier format than the list.

---

## 5. Run and Test

Start the server:

```bash
cargo run
```

Output:

```text
Connected to MySQL
Migrations are up to date
Todo Web running on http://127.0.0.1:3000
```

### Step 1: Check the Home Page

As in Lesson 7, the `sed` command keeps only the `<main>` part of the page:

```bash
curl -s http://127.0.0.1:3000/ | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Todo Web</h1>
<p>You have 1 unfinished tasks out of 2.</p>
<p><a href="/tasks">See all tasks</a> or <a href="/tasks/new">add a new one</a>.</p>

  </main>
```

These numbers come from the two rows the playground left behind: `Learn Rust` (done) and `Build a web app` (not done). If you ran the Lesson 9 exercises, your numbers will be different.

### Step 2: Check the Task List

```bash
curl -s http://127.0.0.1:3000/tasks | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Tasks</h1>

<form method="get" action="/tasks">
  <input name="search" value="" placeholder="Search tasks">
  <button type="submit">Search</button>
</form>


  <ul>
    
      <li>
        [ ]
        <a href="/tasks/2">Build a web app</a>
        (due 2026-11-30)
      </li>
    
      <li>
        [x]
        <a href="/tasks/1">Learn Rust</a>
        
      </li>
    
  </ul>


  </main>
```

The unfinished task comes first because of `ORDER BY done, id`, and only it has a due date.

### Step 3: Change the Database, Reload the Page

The page now reflects whatever is in the table. Add a task directly in MySQL:

```bash
mysql -u todo_user -p db_rust_todo -e "INSERT INTO tasks (title) VALUES ('Write the first handler test');"
```

Request the list again, without restarting the server:

```bash
curl -s http://127.0.0.1:3000/tasks | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Tasks</h1>

<form method="get" action="/tasks">
  <input name="search" value="" placeholder="Search tasks">
  <button type="submit">Search</button>
</form>


  <ul>
    
      <li>
        [ ]
        <a href="/tasks/2">Build a web app</a>
        (due 2026-11-30)
      </li>
    
      <li>
        [ ]
        <a href="/tasks/4">Write the first handler test</a>
        
      </li>
    
      <li>
        [x]
        <a href="/tasks/1">Learn Rust</a>
        
      </li>
    
  </ul>


  </main>
```

The new task appears immediately. Its ID is 4, not 3: the playground deleted task 3 in Lesson 9, and MySQL never reuses `AUTO_INCREMENT` values.

### Step 4: Search

```bash
curl -s "http://127.0.0.1:3000/tasks?search=test" | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Tasks</h1>

<form method="get" action="/tasks">
  <input name="search" value="test" placeholder="Search tasks">
  <button type="submit">Search</button>
</form>


  <ul>
    
      <li>
        [ ]
        <a href="/tasks/4">Write the first handler test</a>
        
      </li>
    
  </ul>


  </main>
```

The filtering now happens in MySQL with `LIKE`.

### Step 5: Check the Detail and 404 Pages

```bash
curl -s http://127.0.0.1:3000/tasks/2 | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Build a web app</h1>
<p>Status: not done</p>
<p>Due date: 30 November 2026</p>
<p>Created: 2026-11-01 16:59</p>
<p><a href="/tasks">Back to all tasks</a></p>

  </main>
```

Your creation time will match the moment you ran the playground. SQLx sets every connection's time zone to UTC, so times stored by the application are in UTC. A task added with the `mysql` client, like task 4, uses the server's local time zone instead, so its time may look shifted by a few hours.

A task that does not exist:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000/tasks/42
```

Output:

```text
404
```

`-o /dev/null` discards the body and `-w "%{http_code}\n"` prints only the status code. Open the pages in the browser as well; the task list links to each detail page. Stop the server with `Ctrl+C` and commit:

```bash
git add -A
git commit -m "lesson 10: list and show tasks from mysql"
```

---

## 6. Where the Work Happens

With real data, it is worth being clear about which part of the system does which job. Each request now travels through three layers:

```text
GET /tasks?search=test
   |
   v
Axum: route + extractors        -> State(pool), Query(TaskFilter { search: Some("test") })
   |
   v
list_tasks (handler)            -> calls search_tasks(&pool, "test")
   |
   v
MySQL: SELECT ... WHERE title LIKE CONCAT('%', 'test', '%') ORDER BY done, id
   |
   v
FromRow -> Vec<Task> -> TaskListTemplate -> Askama -> HTML
```

Some guidelines that follow from this picture:

- **Let the database filter and sort.** MySQL is built for searching and ordering rows, and only the rows you need travel over the connection. Filtering in Rust after `fetch_all` would load the whole table on every request.
- **Keep SQL in small functions.** Handlers call `search_tasks` or `find_task`; they do not contain SQL themselves. This keeps handlers short and makes the queries easy to test, which you will do in Lesson 18.
- **"Not found" is not an error.** `fetch_optional` returns `Ok(None)` for a missing task, and the handler turns it into a `404`. Only real failures, such as a lost connection or a broken query, become `500`.
- **Log details, show summaries.** The terminal gets the full error; the browser gets a short, safe message.

---

## 7. Fix the Errors in Your Code

**Error 1: A column missing from the SELECT**

```rust
// Wrong: created_at is not selected, but Task has a created_at field
        "SELECT id, title, done, due_date FROM tasks
         WHERE title LIKE CONCAT('%', ?, '%')
         ORDER BY done, id",
```

```rust
// Correct
        "SELECT id, title, done, due_date, created_at FROM tasks
         WHERE title LIKE CONCAT('%', ?, '%')
         ORDER BY done, id",
```

After adding a field to `Task`, every query that reads tasks must select the new column. This compiles, but the task list now fails with a `500`:

```text
HTTP/1.1 500 Internal Server Error
content-type: text/plain; charset=utf-8
content-length: 45
date: Sun, 01 Nov 2026 17:02:24 GMT

Something went wrong. Please try again later.
```

The browser only gets the friendly message. The real reason is in the server terminal, printed by `internal_error`:

```text
database error: no column found for name: created_at
```

This is why logging the error matters: without that line, a `500` would be a mystery. Search the code for every `query_as::<_, Task>` whenever the struct changes.

**Error 2: Returning sqlx::Error directly from a handler**

```rust
// Wrong
async fn show_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, sqlx::Error> {
    let task = find_task(&pool, id).await?;
```

```rust
// Correct
async fn show_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, (StatusCode, String)> {
    let task = find_task(&pool, id).await.map_err(internal_error)?;
```

Axum does not know how to turn a `sqlx::Error` into an HTTP response, because `sqlx::Error` does not implement `IntoResponse`. So the function is not a valid handler:

```text
error[E0277]: the trait bound `fn(State<Pool<MySql>>, Path<u64>) -> _ {show_task}: Handler<_, _>` is not satisfied
   --> src/main.rs:185:35
    |
185 |         .route("/tasks/{id}", get(show_task))
    |                               --- ^^^^^^^^^ the trait `Handler<_, _>` is not implemented for fn item `fn(State<Pool<MySql>>, Path<u64>) -> _ {show_task}`
```

You have seen this message several times now; this time the return type is the cause. Convert the error with `map_err` into something that implements `IntoResponse`. In Lesson 14, you will make your own error type implement `IntoResponse`, so `?` works without `map_err`.

**Error 3: Printing an Option directly in a template**

```html
<!-- Wrong -->
<p>Due date: {{ task.due_date }}</p>
```

```html
<!-- Correct -->
<p>Due date: {% if let Some(date) = task.due_date %}{{ date }}{% else %}none{% endif %}</p>
```

`{{ }}` needs a value that implements `Display`, and `Option<NaiveDate>` does not: Rust cannot know what you want to show for `None`. Askama reports it at compile time, with a long message:

```text
error[E0599]: the method `askama_auto_escape` exists for reference `&&AutoEscaper<'_, std::option::Option<NaiveDate>, _::askama::filters::Html>`, but its trait bounds were not satisfied
  --> src/main.rs:37:10
   |
37 | #[derive(Template)]
   |          ^^^^^^^^ method cannot be called due to unsatisfied trait bounds
   |
   = note: the following trait bounds were not satisfied:
           `std::option::Option<NaiveDate>: HtmlSafe`
           which is required by `&AutoEscaper<'_, std::option::Option<NaiveDate>, _::askama::filters::Html>: AutoEscape`
           `std::option::Option<NaiveDate>: std::fmt::Display`
           which is required by `&&AutoEscaper<'_, std::option::Option<NaiveDate>, _::askama::filters::Html>: AutoEscape`
```

Look for the line ending in `std::fmt::Display`: it names the type that cannot be printed. Unwrap the `Option` with `{% if let %}` and decide what to show when it is `None`.

---

## 8. Exercises

**Exercise 1:** On the detail page, show the warning `This task is overdue!` when a task is not done and its due date is before today. Compute an `overdue: bool` in `show_task` and add it to `TaskShowTemplate`. Hint: `chrono::Local::now().date_naive()` returns today's date, and `Option::is_some_and` checks the value inside an `Option`.

**Exercise 2:** Add a "Coming up" section to the home page that lists up to three unfinished tasks with a due date, nearest first. Write an `upcoming_tasks` query function with `LIMIT 3`, and hide the section when there are no such tasks.

**Exercise 3:** On the task list, distinguish two empty states: with no search, show `No tasks yet.` and a link to the new task form; with a search, show `No tasks match "<search>".` Do it only in the template.

---

## 9. Solutions

**Solution for Exercise 1:**

Add the field to the template struct:

```rust
#[derive(Template)]
#[template(path = "tasks/show.html")]
struct TaskShowTemplate {
    task: Task,
    overdue: bool,
}
```

Compute it in `show_task`:

```rust
async fn show_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, (StatusCode, String)> {
    let task = find_task(&pool, id).await.map_err(internal_error)?;
    match task {
        Some(task) => {
            let today = chrono::Local::now().date_naive();
            let overdue = !task.done && task.due_date.is_some_and(|date| date < today);
            Ok(render(TaskShowTemplate { task, overdue }))
        }
        None => Ok(not_found_page("That task does not exist.")),
    }
}
```

And show it in `templates/tasks/show.html`, below the status line:

```html
{% if overdue %}<p><strong>This task is overdue!</strong></p>{% endif %}
```

`Local::now()` is the current date and time in the computer's time zone, and `date_naive()` keeps only the date. `is_some_and` returns `true` only when the `Option` holds a value and the closure returns `true`, so tasks without a due date are never overdue. Keeping the calculation in Rust keeps the template simple. To test it, add a task with a past due date, for example `INSERT INTO tasks (title, due_date) VALUES ('Renew the domain', '2026-10-15');`, and open its page:

```text
  <main>
    
<h1>Renew the domain</h1>
<p>Status: not done</p>
<p><strong>This task is overdue!</strong></p>
<p>Due date: 15 October 2026</p>
<p>Created: 2026-11-02 00:02</p>
<p><a href="/tasks">Back to all tasks</a></p>

  </main>
```

The creation time is in the server's local time here, because the row was added with the `mysql` client.

**Solution for Exercise 2:**

Add the query below `count_tasks`:

```rust
async fn upcoming_tasks(pool: &MySqlPool) -> Result<Vec<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>(
        "SELECT id, title, done, due_date, created_at FROM tasks
         WHERE done = FALSE AND due_date IS NOT NULL
         ORDER BY due_date
         LIMIT 3",
    )
    .fetch_all(pool)
    .await
}
```

Add a field to `HomeTemplate` and fill it in `home`:

```rust
#[derive(Template)]
#[template(path = "home.html")]
struct HomeTemplate {
    pending: i64,
    total: i64,
    upcoming: Vec<Task>,
}
```

```rust
async fn home(State(pool): State<MySqlPool>) -> Result<Response, (StatusCode, String)> {
    let (total, pending) = count_tasks(&pool).await.map_err(internal_error)?;
    let upcoming = upcoming_tasks(&pool).await.map_err(internal_error)?;
    Ok(render(HomeTemplate { pending, total, upcoming }))
}
```

Then update `templates/home.html`:

```html
{% extends "base.html" %}

{% block content %}
<h1>Todo Web</h1>
<p>You have {{ pending }} unfinished tasks out of {{ total }}.</p>

{% if !upcoming.is_empty() %}
  <h2>Coming up</h2>
  <ul>
    {% for task in upcoming %}
      {% if let Some(date) = task.due_date %}
        <li><a href="/tasks/{{ task.id }}">{{ task.title }}</a> (due {{ date }})</li>
      {% endif %}
    {% endfor %}
  </ul>
{% endif %}

<p><a href="/tasks">See all tasks</a> or <a href="/tasks/new">add a new one</a>.</p>
{% endblock %}
```

`due_date IS NOT NULL` excludes tasks without a date (in SQL, `= NULL` never matches, so `IS` is required), `ORDER BY due_date` puts the nearest first, and `LIMIT 3` returns at most three rows. In the template, `!upcoming.is_empty()` hides the whole section when the list is empty. The query guarantees a due date, but the field is still an `Option`, so the template unwraps it with `if let`. With two extra tasks due on 2026-10-15 and 2026-11-12, the section shows:

```text
  <h2>Coming up</h2>
  <ul>
    
      
        <li><a href="/tasks/5">Renew the domain</a> (due 2026-10-15)</li>
      
    
      
        <li><a href="/tasks/6">Plan the demo</a> (due 2026-11-12)</li>
      
    
      
        <li><a href="/tasks/2">Build a web app</a> (due 2026-11-30)</li>
      
    
  </ul>
```

**Solution for Exercise 3:**

In `templates/tasks/list.html`, replace the `{% if tasks.is_empty() %}` line and the "No tasks found" paragraph with:

```html
{% if tasks.is_empty() && search.is_empty() %}
  <p>No tasks yet. <a href="/tasks/new">Add your first task</a>.</p>
{% else if tasks.is_empty() %}
  <p>No tasks match "{{ search }}".</p>
{% else %}
```

The rest of the template, from `<ul>` to `{% endif %}`, stays the same. Askama supports `&&` and `else if` just like Rust. The search text is escaped automatically, so it is safe to show it back to the user. A search for `zzz` now shows:

```text
  <p>No tasks match "zzz".</p>
```

---

## Next Up - Lesson 11

In this lesson, you replaced the sample data with MySQL. The home page counts tasks, the list shows and searches real rows with `LIKE` and a bound parameter, the detail page formats dates and shows a 404 for missing tasks, and database errors become a logged `500` response through `map_err` and an `internal_error` helper.

The "New task" form still only prints the title in the terminal. In Lesson 11, you will make it save tasks: add an optional due date to the form, parse it into a `NaiveDate`, insert the task with a parameterized query, and redirect to the new task's page with the Post/Redirect/Get pattern.
