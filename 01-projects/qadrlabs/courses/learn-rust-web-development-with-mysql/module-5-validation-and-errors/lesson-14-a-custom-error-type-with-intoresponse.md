## 1. Before You Begin

Since Lesson 10, every handler that talks to MySQL has followed the same routine: call a query, add `.map_err(internal_error)`, add `?`, and return `Result<Response, (StatusCode, String)>`. Missing tasks are handled separately with `not_found_page`, and template errors are handled inside `render` in yet another way. It works, but the error handling is spread across the file, the `500` response is plain text without the site layout, and every new handler repeats the same boilerplate.

In this lesson, you will collect every kind of failure into one type, `AppError`. Two standard Rust traits do the heavy lifting. `From` teaches the `?` operator how to convert a `sqlx::Error` or an `askama::Error` into an `AppError` automatically, so the `.map_err(...)` calls disappear. Axum's `IntoResponse` teaches the framework how to turn an `AppError` into an HTTP response, so every failure, from a missing task to a broken database connection, produces a proper error page with the right status code.

### What You'll Build

An `AppError` enum with three variants (`NotFound`, `Database`, and `Template`), `From` implementations for SQLx and Askama errors, an `IntoResponse` implementation that renders a new `error.html` template, and simplified handlers that return `Result<Response, AppError>` and use `?` everywhere.

### What You'll Learn

- ✅ How to model the failures of an application as an enum
- ✅ How implementing `From` makes the `?` operator convert errors automatically
- ✅ How to implement Axum's `IntoResponse` trait for your own type
- ✅ How to turn `Option` into an error with `ok_or` and `?`
- ✅ How to log internal details while showing users a safe message
- ✅ How to test error pages by temporarily breaking the database

### What You'll Need

- The `todo-web` project from Lesson 13
- Error handling with `Result`, `?`, and `match` from the first course

---

## 2. Define the Error Type

An enum is the natural way to describe "one of several kinds of failure." Each variant is one kind, and variants can carry the original error so nothing is lost.

### Step 1: Create the AppError Enum

Add this enum to `src/main.rs`, right above the `render` function:

```rust
enum AppError {
    NotFound,
    Database(sqlx::Error),
    Template(askama::Error),
}
```

The three variants cover every failure Todo Web has today:

- `NotFound` means a task or page does not exist. It carries no data, because there is nothing more to say.
- `Database(sqlx::Error)` wraps any SQLx failure: a lost connection, a broken query, a missing table.
- `Template(askama::Error)` wraps a failure while rendering a template.

### Step 2: Implement From for SQLx and Askama Errors

Add these two implementations below the enum:

```rust
impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        AppError::Database(err)
    }
}

impl From<askama::Error> for AppError {
    fn from(err: askama::Error) -> Self {
        AppError::Template(err)
    }
}
```

`From<T>` is the standard trait for converting a value of type `T` into another type. Each implementation simply wraps the error in the matching variant. The important part is what this enables: when you write `?` on a `Result<_, sqlx::Error>` inside a function that returns `Result<_, AppError>`, the `?` operator calls `AppError::from(err)` for you. That is exactly the conversion you have been doing by hand with `map_err`.

---

## 3. Turn Errors into Responses

Axum only accepts a handler whose error type implements `IntoResponse`. Implementing it for `AppError` decides, in one place, what the user sees for each kind of failure.

### Step 1: Create the Error Template

The old `templates/not_found.html` only handled 404s. Delete it, and create `templates/error.html`, which handles every error:

```html
{% extends "base.html" %}

{% block title %}{{ title }} - Todo Web{% endblock %}

{% block content %}
<h1>{{ status }} {{ title }}</h1>
<p>{{ message }}</p>
<p><a href="/tasks">Back to your tasks</a></p>
{% endblock %}
```

In `src/main.rs`, replace `NotFoundTemplate` with the struct for the new template:

```rust
#[derive(Template)]
#[template(path = "error.html")]
struct ErrorTemplate {
    status: u16,
    title: &'static str,
    message: &'static str,
}
```

`status` is the numeric code, such as `404`. The title and message are `&'static str`, because every error page uses fixed text written in the code, never text from the user or the database.

### Step 2: Implement IntoResponse

Add this implementation below the two `From` implementations:

```rust
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, title, message) = match self {
            AppError::NotFound => (
                StatusCode::NOT_FOUND,
                "Not Found",
                "The page or task you are looking for does not exist.",
            ),
            AppError::Database(err) => {
                eprintln!("database error: {err}");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Server Error",
                    "Something went wrong on our side. Please try again later.",
                )
            }
            AppError::Template(err) => {
                eprintln!("template error: {err}");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Server Error",
                    "Something went wrong on our side. Please try again later.",
                )
            }
        };

        let page = ErrorTemplate { status: status.as_u16(), title, message };
        match page.render() {
            Ok(html) => (status, Html(html)).into_response(),
            Err(_) => (status, message).into_response(),
        }
    }
}
```

Here is what happens inside:

- `IntoResponse` has one method, `into_response`, which takes the error by value and returns a `Response`.
- The `match` picks a status code, a title, and a message for each variant. `NotFound` becomes `404`. Database and template errors become `500`.
- For the two internal errors, the real error is printed with `eprintln!`, exactly like `internal_error` did. The user only sees a generic message. This is the same "log details, show summaries" rule from Lesson 10, now enforced in one place for the whole application.
- `status.as_u16()` turns `StatusCode::NOT_FOUND` into the number `404` for the template.
- Rendering the error page could itself fail. If it does, the fallback is a plain text response with the same status, so an error never causes a second, unhandled error.

### Step 3: Simplify render

Replace the `render` function with:

```rust
fn render<T: Template>(template: T) -> Result<Response, AppError> {
    let html = template.render()?;
    Ok(Html(html).into_response())
}
```

`render` now returns a `Result`. `template.render()` returns `Result<String, askama::Error>`, and the `?` converts an `askama::Error` into an `AppError::Template` using the `From` implementation. Delete `not_found_page` and `internal_error`; `AppError` replaces both.

---

## 4. Simplify the Handlers

With `From` and `IntoResponse` in place, the handlers can return `Result<Response, AppError>` and use `?` on every query and every render.

### Step 1: Rewrite the Reading Handlers

Replace `home`, `list_tasks`, `show_task`, `new_task_form`, and `edit_task_form` with:

```rust
async fn home(State(pool): State<MySqlPool>) -> Result<Response, AppError> {
    let (total, pending) = count_tasks(&pool).await?;
    render(HomeTemplate { pending, total })
}

async fn list_tasks(
    State(pool): State<MySqlPool>,
    Query(filter): Query<TaskFilter>,
) -> Result<Response, AppError> {
    let search = filter.search.unwrap_or_default();
    let tasks = search_tasks(&pool, &search).await?;
    render(TaskListTemplate { tasks, search })
}

async fn show_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, AppError> {
    let task = find_task(&pool, id).await?.ok_or(AppError::NotFound)?;
    render(TaskShowTemplate { task })
}

async fn new_task_form() -> Result<Response, AppError> {
    render(NewTaskTemplate { form: TaskForm::default(), errors: FormErrors::default() })
}

async fn edit_task_form(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, AppError> {
    let task = find_task(&pool, id).await?.ok_or(AppError::NotFound)?;
    let form = TaskForm {
        title: task.title,
        due_date: task.due_date.map(|date| date.to_string()).unwrap_or_default(),
    };
    render(EditTaskTemplate { id, form, errors: FormErrors::default() })
}
```

Compare `show_task` with the Lesson 10 version: the `match` on `Option` is gone. `find_task(&pool, id).await?` returns an `Option<Task>` (the `?` handled any database error), and `.ok_or(AppError::NotFound)` turns that `Option` into a `Result`: `Some(task)` becomes `Ok(task)`, and `None` becomes `Err(AppError::NotFound)`. The second `?` returns the error early. Because `render` now returns a `Result`, the handlers can return its value directly, without `Ok(...)`.

### Step 2: Rewrite the Writing Handlers

Replace `create_task`, `save_task`, `toggle_done`, `remove_task`, and `not_found` with:

```rust
async fn create_task(
    State(pool): State<MySqlPool>,
    Form(form): Form<TaskForm>,
) -> Result<Response, AppError> {
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => {
            let page = render(NewTaskTemplate { form, errors })?;
            return Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response());
        }
    };

    let id = insert_task(&pool, &task.title, task.due_date).await?;
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
}

async fn save_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
    Form(form): Form<TaskForm>,
) -> Result<Response, AppError> {
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => {
            let page = render(EditTaskTemplate { id, form, errors })?;
            return Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response());
        }
    };

    if !update_task(&pool, id, &task.title, task.due_date).await? {
        return Err(AppError::NotFound);
    }
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
}

async fn toggle_done(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Redirect, AppError> {
    if !toggle_task(&pool, id).await? {
        return Err(AppError::NotFound);
    }
    Ok(Redirect::to("/tasks"))
}

async fn remove_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Redirect, AppError> {
    if !delete_task(&pool, id).await? {
        return Err(AppError::NotFound);
    }
    Ok(Redirect::to("/tasks"))
}

async fn not_found() -> AppError {
    AppError::NotFound
}
```

Some details worth noticing:

- Validation errors are not `AppError`s. A form with mistakes is a normal situation with its own page and status (`422`), so the handlers still handle it themselves. Only the `render(...)?` inside that branch can produce an `AppError`.
- `if !update_task(...).await?` reads naturally: run the update, and if it did not touch a row, return `NotFound`.
- `toggle_done` and `remove_task` always redirect on success, so their success type can be `Redirect` instead of `Response`. A handler's `Ok` and `Err` types only both need to implement `IntoResponse`.
- The fallback handler simply returns `AppError::NotFound`. Because `AppError` implements `IntoResponse`, a handler can return it directly, without a `Result`.
- The `health` handler stays as it is. It deliberately returns `503 Service Unavailable` with the error text for monitoring tools, which is a different job from the user-facing pages.

Run the tests to make sure the validation code still compiles and passes:

```bash
cargo test
```

The five tests from Lesson 13 pass as before.

---

## 5. Run and Test

Start the server with `cargo run`.

### Step 1: Check the 404 Pages

```bash
curl -s -i http://127.0.0.1:3000/tasks/999 | head -1
```

Output:

```text
HTTP/1.1 404 Not Found
```

```bash
curl -s http://127.0.0.1:3000/tasks/999 | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>404 Not Found</h1>
<p>The page or task you are looking for does not exist.</p>
<p><a href="/tasks">Back to your tasks</a></p>

  </main>
```

Unknown pages and actions on missing tasks give the same status:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000/nope
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://127.0.0.1:3000/tasks/999/delete
```

Output:

```text
404
404
```

### Step 2: Break the Database on Purpose

To see the `500` page, the database has to fail. A safe way to cause that is to rename the `tasks` table for a moment, so every query that uses it fails:

```bash
mysql -u todo_user -p db_rust_todo -e "RENAME TABLE tasks TO tasks_backup;"
```

Now load the task list:

```bash
curl -s -i http://127.0.0.1:3000/tasks | head -1
```

Output:

```text
HTTP/1.1 500 Internal Server Error
```

```bash
curl -s http://127.0.0.1:3000/tasks | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>500 Server Error</h1>
<p>Something went wrong on our side. Please try again later.</p>
<p><a href="/tasks">Back to your tasks</a></p>

  </main>
```

The user gets a calm error page inside the normal layout. The server terminal shows what really happened, once per failed request:

```text
database error: error returned from database: 1146 (42S02): Table 'db_rust_todo.tasks' doesn't exist
database error: error returned from database: 1146 (42S02): Table 'db_rust_todo.tasks' doesn't exist
```

Put the table back right away:

```bash
mysql -u todo_user -p db_rust_todo -e "RENAME TABLE tasks_backup TO tasks;"
```

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000/tasks
```

Output:

```text
200
```

The application recovers by itself as soon as the database works again. No restart is needed, because each request runs its queries fresh.

### Step 3: Check That Validation Still Works

```bash
curl -s -o /dev/null -w "%{http_code}\n" -d "title=&due_date=" http://127.0.0.1:3000/tasks
```

Output:

```text
422
```

Invalid forms still get their own page with field errors, not the generic error page. Stop the server with `Ctrl+C` and commit:

```bash
git add -A
git commit -m "lesson 14: custom error type"
```

---

## 6. How ? and IntoResponse Work Together

The whole error flow of Todo Web now fits in one picture:

```text
find_task(...).await          -> Result<Option<Task>, sqlx::Error>
   ? (From<sqlx::Error>)      -> on Err: return Err(AppError::Database(err))
.ok_or(AppError::NotFound)?   -> on None: return Err(AppError::NotFound)
render(...)                   -> Result<Response, AppError>  (askama errors via From)
   |
handler returns Result<Response, AppError>
   |
Axum: Ok(response) -> send it
      Err(app_error) -> app_error.into_response() -> error page with 404 or 500
```

Some takeaways:

- **`?` is not magic, it is `From`.** Every time `?` meets an error, it calls `From::from` to convert it into the function's error type. Implementing `From` once removes `map_err` from every call site.
- **One place decides what users see.** Status codes, messages, and logging for every failure live in a single `match`. Changing the wording or adding logging later means editing one function.
- **The enum documents the failures.** Reading `AppError` tells a new developer every way a request can fail. Adding a new kind of failure means adding a variant, and the compiler then points at every `match` that must handle it.
- **Not everything is an error.** Validation problems, like a blank title, are expected outcomes with their own pages. `AppError` is for situations where the request cannot be completed at all.

Larger projects often use the `thiserror` crate to generate the `From` and `Display` implementations with attributes, but writing them by hand, as you did here, shows exactly what such crates do.

---

## 7. Fix the Errors in Your Code

**Error 1: Missing From implementation**

```rust
// Wrong: the From<sqlx::Error> implementation was removed or never written
enum AppError {
    NotFound,
    Database(sqlx::Error),
    Template(askama::Error),
}
```

```rust
// Correct
impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        AppError::Database(err)
    }
}
```

Without it, every `?` on a query fails to compile. The error appears once per call site, eight times in Todo Web; the first one reads:

```text
error[E0277]: `?` couldn't convert the error to `AppError`
   --> src/main.rs:243:52
    |
243 |     let (total, pending) = count_tasks(&pool).await?;
    |                            ------------------------^ the trait `From<sqlx::Error>` is not implemented for `AppError`
    |                            |
    |                            this can't be annotated with `?` because it has type `Result<_, sqlx::Error>`
    |
note: `AppError` needs to implement `From<sqlx::Error>`
   --> src/main.rs:190:1
    |
190 | enum AppError {
    | ^^^^^^^^^^^^^
    = note: the question mark operation (`?`) implicitly performs a conversion on the error value using the `From` trait
```

The compiler states the solution itself: `AppError needs to implement From<sqlx::Error>`. A long list of identical errors after a refactoring usually has one cause, so fix the first one and build again.

**Error 2: Missing IntoResponse implementation**

```rust
// Wrong: AppError has no IntoResponse implementation
async fn home(State(pool): State<MySqlPool>) -> Result<Response, AppError> {
```

```rust
// Correct: keep the handler, and add an implementation (the smallest possible one is shown)
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        (StatusCode::INTERNAL_SERVER_ERROR, "Something went wrong").into_response()
    }
}
```

The handlers compile on their own, but Axum cannot use them:

```text
error[E0277]: the trait bound `fn(State<Pool<MySql>>) -> _ {home}: Handler<_, _>` is not satisfied
   --> src/main.rs:336:25
    |
336 |         .route("/", get(home))
    |                     --- ^^^^ unsatisfied trait bound
    |                     |
    |                     required by a bound introduced by this call
    |
    = help: the trait `Handler<_, _>` is not implemented for fn item `fn(State<Pool<MySql>>) -> impl Future<Output = Result<Response<Body>, AppError>> {home}`
```

The help line shows the handler's full return type, `Result<Response<Body>, AppError>`. A `Result` is only a valid response if both its `Ok` and `Err` types implement `IntoResponse`, and `AppError` does not. Use the complete implementation from Section 3.

**Error 3: Using ? on an Option**

```rust
// Wrong
    let task = find_task(&pool, id).await??;
```

```rust
// Correct
    let task = find_task(&pool, id).await?.ok_or(AppError::NotFound)?;
```

The first `?` handles the `Result`, but what remains is an `Option<Task>`, and `?` on an `Option` only works in functions that return an `Option`:

```text
error[E0277]: the `?` operator can only be used on `Result`s, not `Option`s, in an async function that returns `Result`
   --> src/main.rs:272:43
    |
271 |   ) -> Result<Response, AppError> {
    |  _________________________________-
272 | |     let task = find_task(&pool, id).await??;
    | |                                           ^ use `.ok_or(...)?` to provide an error compatible with `Result<Response<Body>, AppError>`
```

The compiler suggests exactly the right fix: `.ok_or(...)?`. `ok_or` says which error `None` should become.

---

## 8. Exercises

**Exercise 1:** Implement `std::fmt::Display` for `AppError`, so each variant prints a short description (`not found`, `database error: ...`, `template error: ...`). Then simplify `into_response` so the two internal variants share one `match` arm that logs with `eprintln!("{self}")`.

**Exercise 2:** Add a `BadRequest(&'static str)` variant that produces a `400 Bad Request` page with the given message. Use it in `show_task` to reject task number `0` with the message `Task numbers start at 1.`

**Exercise 3:** A URL such as `/tasks/abc` still produces Axum's plain text `400` response from Lesson 5, without your layout. Make it show your 404 page instead. Hint: an extractor can be wrapped in a `Result`, such as `Result<Path<u64>, PathRejection>`, to receive the rejection instead of letting Axum answer; `PathRejection` lives in `axum::extract::rejection`.

---

## 9. Solutions

**Solution for Exercise 1 and Exercise 2:**

Both changes touch the enum and `into_response`. Replace the enum and add a `Display` implementation:

```rust
enum AppError {
    NotFound,
    BadRequest(&'static str),
    Database(sqlx::Error),
    Template(askama::Error),
}

impl std::fmt::Display for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AppError::NotFound => write!(f, "not found"),
            AppError::BadRequest(message) => write!(f, "bad request: {message}"),
            AppError::Database(err) => write!(f, "database error: {err}"),
            AppError::Template(err) => write!(f, "template error: {err}"),
        }
    }
}
```

Then replace the `match` at the start of `into_response`:

```rust
        let (status, title, message) = match &self {
            AppError::NotFound => (
                StatusCode::NOT_FOUND,
                "Not Found",
                "The page or task you are looking for does not exist.",
            ),
            AppError::BadRequest(message) => (StatusCode::BAD_REQUEST, "Bad Request", *message),
            AppError::Database(_) | AppError::Template(_) => {
                eprintln!("{self}");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Server Error",
                    "Something went wrong on our side. Please try again later.",
                )
            }
        };
```

And add the check at the start of `show_task`, after the extractors:

```rust
    if id == 0 {
        return Err(AppError::BadRequest("Task numbers start at 1."));
    }
```

`Display` is the trait behind `{}` in `format!` and `println!`, as in the first course. With it, `eprintln!("{self}")` prints the right description for any variant. The `match` now borrows `self` (`match &self`), because `self` is still needed afterwards for printing. Matching on a reference gives references to the fields, so `message` is a `&&'static str`, and `*message` removes one layer to get the `&'static str` the tuple needs; without the `*`, the compiler reports `expected (StatusCode, &str, &str), found (StatusCode, &str, &&str)`. The pattern `AppError::Database(_) | AppError::Template(_)` matches either variant in one arm.

```bash
curl -s -i http://127.0.0.1:3000/tasks/0 | grep -E "HTTP|<h1>|<p>Task"
```

Output:

```text
HTTP/1.1 400 Bad Request
<h1>400 Bad Request</h1>
<p>Task numbers start at 1.</p>
```

With the table renamed as in Section 5, the log line now comes from the `Display` implementation:

```text
database error: error returned from database: 1146 (42S02): Table 'db_rust_todo.tasks' doesn't exist
```

**Solution for Exercise 3:**

Import the rejection type:

```rust
    extract::{Path, Query, State, rejection::PathRejection},
```

And change the start of `show_task`:

```rust
async fn show_task(
    State(pool): State<MySqlPool>,
    path: Result<Path<u64>, PathRejection>,
) -> Result<Response, AppError> {
    let Path(id) = path.map_err(|_| AppError::NotFound)?;
    if id == 0 {
        return Err(AppError::BadRequest("Task numbers start at 1."));
    }
    let task = find_task(&pool, id).await?.ok_or(AppError::NotFound)?;
    render(TaskShowTemplate { task })
}
```

When an extractor is wrapped in `Result<Extractor, Rejection>`, Axum always calls the handler and passes either the extracted value or the reason extraction failed. `map_err(|_| AppError::NotFound)?` turns a failed parse into your 404 page. `let Path(id) = ...` destructures the successful value, just like the pattern in the parameter list did before. A path such as `/tasks/abc` cannot point to a task, so `404` is a sensible answer.

```bash
curl -s -i http://127.0.0.1:3000/tasks/abc | grep -E "HTTP|<h1>|<p>The"
```

Output:

```text
HTTP/1.1 404 Not Found
<h1>404 Not Found</h1>
<p>The page or task you are looking for does not exist.</p>
```

---

## Next Up - Lesson 15

In this lesson, you replaced scattered error handling with one `AppError` enum. `From` implementations let `?` convert SQLx and Askama errors automatically, `ok_or` turns missing tasks into `AppError::NotFound`, and the `IntoResponse` implementation renders a proper error page with the right status while logging internal details. You also tested the `500` page by temporarily renaming the table.

Module 6 makes the data richer. In Lesson 15, you will add a second table, `categories`, with a new migration, link each task to a category through a foreign key, build pages to manage categories, and add a category drop-down to the task forms.
