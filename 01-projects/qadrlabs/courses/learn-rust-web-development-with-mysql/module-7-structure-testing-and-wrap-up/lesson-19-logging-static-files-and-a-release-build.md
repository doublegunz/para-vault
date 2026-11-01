## 1. Before You Begin

Todo Web is feature complete. It stores tasks and categories in MySQL, validates every form, shows proper error pages, filters and paginates the task list, and has sixteen tests. A few things still separate it from an application you would happily run for real. The server prints a handful of `println!` lines at startup and nothing at all while it works, so you cannot see which requests arrive, how long they take, or which ones fail. Every page is unstyled HTML. And so far, you have only ever run the slow, unoptimized debug build.

This final lesson fixes all three. You will set up `tracing`, Rust's standard library for structured logging, and add `tower-http`'s trace layer so every request is logged with its method, path, status, and duration. You will serve a CSS file from a `static` folder, build an optimized release binary, and run it. The lesson ends with a review of everything you built in this course and ideas for where to go next.

### What You'll Build

Todo Web with structured log output (startup messages, one line per request, and error details), a stylesheet served at `/static/style.css` and linked from the base layout, and an optimized release binary under `target/release/`.

### What You'll Learn

- ✅ How to set up `tracing` and `tracing-subscriber` with log levels and the `RUST_LOG` variable
- ✅ How to log every request with `tower-http`'s `TraceLayer`
- ✅ How to write structured log messages with fields
- ✅ How to serve static files with `ServeDir` and `nest_service`
- ✅ How to build and run an optimized release binary
- ✅ What a release binary needs at runtime, and what it carries inside

### What You'll Need

- The `todo-web` project from Lesson 18, with all tests passing
- About a minute of patience for the first release build

---

## 2. Add Structured Logging

`println!` and `eprintln!` write plain text with no timestamp, no severity, and no way to turn messages on or off. The `tracing` crate replaces them with log events that have a level (such as `INFO` or `ERROR`), a source (the module that logged them), optional named fields, and a timestamp. A subscriber, provided by `tracing-subscriber`, decides which events to show and how to format them.

### Step 1: Add the Crates

```bash
cargo add tracing
cargo add tracing-subscriber --features env-filter
cargo add tower-http --features trace,fs
```

`tracing` provides the logging macros. `tracing-subscriber` prints the events; its `env-filter` feature lets the `RUST_LOG` environment variable choose what is shown. `tower-http` is a collection of ready-made layers for Axum and other Tower services: the `trace` feature contains the request logger, and the `fs` feature contains the static file server used in Section 3. The `[dependencies]` section of `Cargo.toml` now reads:

```toml
[dependencies]
askama = "0.16.1"
axum = "0.8.9"
chrono = "0.4.45"
dotenvy = "0.15.7"
serde = { version = "1.0.229", features = ["derive"] }
sqlx = { version = "0.9.0", features = ["runtime-tokio", "mysql", "chrono"] }
tokio = { version = "1.54.1", features = ["full"] }
tower-http = { version = "0.7.1", features = ["trace", "fs"] }
tracing = "0.1.44"
tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }
```

### Step 2: Initialize the Subscriber in main

Replace `src/main.rs` with:

```rust
mod db;
mod error;
mod handlers;
mod models;
mod routes;
mod state;
mod templates;

use sqlx::mysql::MySqlPoolOptions;
use tracing_subscriber::EnvFilter;

use crate::state::AppState;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("todo_web=info,tower_http=info")),
        )
        .init();

    dotenvy::dotenv().ok();
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set in .env");

    let pool = MySqlPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("should connect to MySQL");
    tracing::info!("connected to MySQL");

    sqlx::migrate!()
        .run(&pool)
        .await
        .expect("migrations should run");
    tracing::info!("migrations are up to date");

    let app = routes::app(AppState { pool });

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    tracing::info!("Todo Web running on http://127.0.0.1:3000");

    axum::serve(listener, app).await.expect("server should run");
}
```

Here is what changed:

- `tracing_subscriber::fmt()` creates a subscriber that prints readable lines to the terminal. It must be set up first in `main`; events logged before `.init()` are lost.
- `.with_env_filter(...)` decides which events are printed. `EnvFilter::try_from_default_env()` reads the `RUST_LOG` environment variable. If it is not set, the fallback `"todo_web=info,tower_http=info"` shows events of level `INFO` and above from your own crate (`todo_web`, the crate name with an underscore) and from `tower-http`. Everything else, such as the internal `DEBUG` events of SQLx, stays hidden.
- `tracing::info!(...)` replaces `println!`. It works like `println!`, but produces an `INFO` event with a timestamp and the module name.

### Step 3: Log Errors with Fields

In `src/error.rs`, replace the two `eprintln!` lines in `into_response` with `tracing::error!` calls:

```rust
            AppError::Database(err) => {
                tracing::error!(error = %err, "database error");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Server Error",
                    "Something went wrong on our side. Please try again later.",
                )
            }
            AppError::Template(err) => {
                tracing::error!(error = %err, "template error");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Server Error",
                    "Something went wrong on our side. Please try again later.",
                )
            }
```

`error = %err` adds a named field to the event. The `%` means "record this value using its `Display` implementation." The message, `database error`, stays short and constant, and the details go into the field. Log tools can then search for every `database error` event and read the `error` field separately, which is the "structured" part of structured logging.

### Step 4: Log Every Request

Replace `src/routes.rs` (keeping the `tests` module from Lesson 18 at the bottom unchanged) so the router gets a trace layer and a static file service:

```rust
use axum::{
    Router,
    routing::{get, post},
};
use tower_http::services::ServeDir;
use tower_http::trace::{DefaultMakeSpan, DefaultOnResponse, TraceLayer};
use tracing::Level;

use crate::handlers;
use crate::state::AppState;

pub fn app(state: AppState) -> Router {
    Router::new()
        .route("/", get(handlers::home))
        .route("/health", get(handlers::health))
        .route("/tasks", get(handlers::list_tasks).post(handlers::create_task))
        .route("/tasks/new", get(handlers::new_task_form))
        .route("/tasks/{id}", get(handlers::show_task))
        .route("/tasks/{id}/edit", get(handlers::edit_task_form).post(handlers::save_task))
        .route("/tasks/{id}/toggle", post(handlers::toggle_done))
        .route("/tasks/{id}/delete", post(handlers::remove_task))
        .route("/categories", get(handlers::list_categories).post(handlers::create_category))
        .route("/categories/{id}/delete", post(handlers::remove_category))
        .nest_service("/static", ServeDir::new("static"))
        .fallback(handlers::not_found)
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(DefaultMakeSpan::new().level(Level::INFO))
                .on_response(DefaultOnResponse::new().level(Level::INFO)),
        )
        .with_state(state)
}
```

The new pieces:

- `.layer(...)` wraps the whole router in a middleware layer. A layer sees every request on its way in and every response on its way out, which makes it the right place for cross-cutting concerns like logging.
- `TraceLayer::new_for_http()` creates a layer that opens a span for each request and logs when the response is sent. A span is a context that is attached to every event logged while it is active, so even the `database error` event from a handler shows which request caused it.
- By default, `TraceLayer` logs at the `DEBUG` level, which the filter hides. `.make_span_with(DefaultMakeSpan::new().level(Level::INFO))` and `.on_response(DefaultOnResponse::new().level(Level::INFO))` raise the request span and the response event to `INFO`, so they appear with the default filter.
- `.nest_service("/static", ServeDir::new("static"))` is explained in Section 3.

Layers added with `.layer` apply to everything registered before them, including the fallback. Put `.layer` after the routes and the fallback, and before `.with_state(state)`.

---

## 3. Serve a Stylesheet

Static files are files sent to the browser exactly as they are: stylesheets, images, scripts, fonts. `ServeDir` from `tower-http` serves a whole folder, with the right `content-type` for each file and support for browser caching.

### Step 1: Create the Stylesheet

Create a folder named `static` next to `Cargo.toml`, and in it `style.css`:

```css
body {
  font-family: system-ui, sans-serif;
  max-width: 48rem;
  margin: 2rem auto;
  padding: 0 1rem;
  color: #1f2933;
  background: #f8fafc;
}

nav {
  padding-bottom: 0.75rem;
  margin-bottom: 1.5rem;
  border-bottom: 1px solid #d9e2ec;
}

a {
  color: #2563eb;
}

ul {
  padding-left: 1.25rem;
}

li {
  margin: 0.4rem 0;
}

input,
select,
button {
  font: inherit;
  padding: 0.3rem 0.5rem;
}

form {
  margin: 0.5rem 0;
}

strong {
  color: #b91c1c;
}
```

The rules give the pages a readable width, a system font, some spacing, and red error messages (the forms use `<strong>` for errors). Feel free to adjust them; this is the only CSS in the course.

### Step 2: Link It from the Base Layout

In `templates/base.html`, add a `<link>` element below the `<title>`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{% block title %}Todo Web{% endblock %}</title>
  <link rel="stylesheet" href="/static/style.css">
</head>
```

Every page extends the base layout, so every page now loads the stylesheet. In `routes.rs`, `nest_service("/static", ServeDir::new("static"))` connects the two: a request for `/static/style.css` is answered with the file `static/style.css`. `ServeDir` is a Tower service, not an Axum handler, which is why it is attached with `nest_service` instead of `route`. Its path `static` is relative to the folder where the program runs, a detail that matters in Section 7.

---

## 4. Run and Test

Build, run the tests, and start the server:

```bash
cargo test
cargo run
```

The tests still pass. The startup output has changed:

```text
2026-11-01T17:34:23.454449Z  INFO todo_web: connected to MySQL
2026-11-01T17:34:23.455813Z  INFO todo_web: migrations are up to date
2026-11-01T17:34:23.456091Z  INFO todo_web: Todo Web running on http://127.0.0.1:3000
```

Each line has a UTC timestamp, a level, the module that logged it (`todo_web`), and the message. In your terminal, the levels and names are shown in color.

### Step 1: Watch Requests in the Log

In a second terminal, send a few requests: a page, the stylesheet, a missing file, and an invalid form:

```bash
curl -s -o /dev/null http://127.0.0.1:3000/tasks
curl -s -i http://127.0.0.1:3000/static/style.css | head -5
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000/static/missing.css
curl -s -o /dev/null -d "title=&due_date=" http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/css
accept-ranges: bytes
last-modified: Sun, 01 Nov 2026 17:34:02 GMT
etag: "6ae7780a.3329916b-1cd"
404
```

The stylesheet is served with `content-type: text/css`, plus `last-modified` and `etag` headers that let the browser cache it. A missing static file gets a plain `404` from `ServeDir`. The server terminal shows one line per request:

```text
2026-11-01T17:34:24.958906Z  INFO request{method=GET uri=/tasks version=HTTP/1.1}: tower_http::trace::on_response: finished processing request latency=2 ms status=200
2026-11-01T17:34:24.965129Z  INFO request{method=GET uri=/static/style.css version=HTTP/1.1}: tower_http::trace::on_response: finished processing request latency=0 ms status=200
2026-11-01T17:34:24.971231Z  INFO request{method=GET uri=/static/missing.css version=HTTP/1.1}: tower_http::trace::on_response: finished processing request latency=0 ms status=404
2026-11-01T17:34:24.977477Z  INFO request{method=POST uri=/tasks version=HTTP/1.1}: tower_http::trace::on_response: finished processing request latency=0 ms status=422
```

Each line carries the request's method, path, and HTTP version (from the span), the latency, and the status code. You can see at a glance that the form submission returned `422`.

### Step 2: See an Error in Context

Break the database for a moment, as in Lesson 14, and request the home page:

```bash
mysql -u todo_user -p db_rust_todo -e "RENAME TABLE tasks TO tasks_backup;"
curl -s -o /dev/null http://127.0.0.1:3000/
mysql -u todo_user -p db_rust_todo -e "RENAME TABLE tasks_backup TO tasks;"
```

The log shows three events for that one request:

```text
2026-11-01T17:34:25.014060Z ERROR request{method=GET uri=/ version=HTTP/1.1}: todo_web::error: database error error=error returned from database: 1146 (42S02): Table 'db_rust_todo.tasks' doesn't exist
2026-11-01T17:34:25.014119Z  INFO request{method=GET uri=/ version=HTTP/1.1}: tower_http::trace::on_response: finished processing request latency=0 ms status=500
2026-11-01T17:34:25.014141Z ERROR request{method=GET uri=/ version=HTTP/1.1}: tower_http::trace::on_failure: response failed classification=Status code: 500 Internal Server Error latency=0 ms
```

The first is your `tracing::error!` from `AppError`, with the `error` field. Because it happened inside the request's span, it is prefixed with `request{method=GET uri=/ ...}`, so you know exactly which request failed. The second is the normal response line with status `500`, and the third is an extra `ERROR` event that `TraceLayer` adds for every server error. Stop the server with `Ctrl+C`.

### Step 3: Look at the Pages

Start the server again and open `http://127.0.0.1:3000` in the browser. Every page now uses the stylesheet: the content is centered, the fonts are cleaner, and validation errors on the forms appear in red.

---

## 5. Build the Release Binary

Everything so far ran as a debug build: compiled quickly, with extra checks and debugging information, but not optimized. For real use, Cargo can build an optimized release binary.

### Step 1: Build in Release Mode

```bash
cargo build --release
```

The first release build compiles every dependency again with optimizations, so it takes noticeably longer than a debug build. On the machine used for this course, it ended with:

```text
    Finished `release` profile [optimized] target(s) in 47.06s
```

The binary is in `target/release/` instead of `target/debug/`. Compare the two:

```bash
ls -lh target/debug/todo-web target/release/todo-web | awk '{print $5, $9}'
```

Output:

```text
76M target/debug/todo-web
5.9M target/release/todo-web
```

The `awk` command prints only the size and the name from each line of `ls`. The release binary is a fraction of the size of the debug binary, mostly because it carries no debugging information, and its code is optimized, so it runs considerably faster.

### Step 2: Run the Release Binary

Run it from the project folder, so it finds `.env` and the `static` folder:

```bash
./target/release/todo-web
```

Output, after one request to `/tasks` from another terminal:

```text
2026-11-01T17:35:27.801116Z  INFO todo_web: connected to MySQL
2026-11-01T17:35:27.802180Z  INFO todo_web: migrations are up to date
2026-11-01T17:35:27.802264Z  INFO todo_web: Todo Web running on http://127.0.0.1:3000
2026-11-01T17:35:28.805961Z  INFO request{method=GET uri=/tasks version=HTTP/1.1}: tower_http::trace::on_response: finished processing request latency=1 ms status=200
```

The same application, now optimized. Commit the final lesson:

```bash
git add -A
git commit -m "lesson 19: logging, static files, release build"
```

---

## 6. What the Binary Needs at Runtime

Deploying Todo Web to a server means copying the release binary and everything it needs but does not contain. Some things are compiled into the binary; others must sit next to it:

| Part | Where it lives at runtime |
| --- | --- |
| Rust code, handlers, queries | Inside the binary |
| Askama templates | Inside the binary (compiled in Lesson 6) |
| Migrations | Inside the binary (embedded by `sqlx::migrate!()` in Lesson 8) |
| `static/` files | A folder next to where the program runs |
| `DATABASE_URL` | An environment variable or a `.env` file |
| MySQL | A running server the program can reach |

A typical deployment therefore copies `todo-web` and the `static` folder to the server, sets `DATABASE_URL` as an environment variable (production servers usually do not use `.env` files), and starts the program with a process manager such as systemd, which restarts it if it stops. The migrations run automatically on startup, so a new version brings its own schema changes with it. In production, you would also put a reverse proxy such as Nginx in front of the application to handle HTTPS, and bind Todo Web to an address chosen through configuration rather than the hard-coded `127.0.0.1:3000`.

Logging levels are worth knowing for that environment:

| Level | Use it for |
| --- | --- |
| `ERROR` | Something failed and needs attention |
| `WARN` | Something unusual happened, but the request still worked |
| `INFO` | Important normal events: startup, requests, a task created |
| `DEBUG` | Details for developers, such as every SQL statement |
| `TRACE` | Extremely detailed internals |

`RUST_LOG` changes the levels without recompiling, for example `RUST_LOG=todo_web=debug,tower_http=info` while investigating a problem.

---

## 7. Fix the Errors in Your Code

**Error 1: Forgetting to initialize the subscriber**

```rust
// Wrong: no subscriber is set up
#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();
```

```rust
// Correct
#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("todo_web=info,tower_http=info")),
        )
        .init();

    dotenvy::dotenv().ok();
```

This compiles and runs without any complaint, and pages load normally, but the server prints nothing at all: not the startup lines, not the requests, not even database errors. `tracing` macros only create events; without a subscriber, nobody prints them. If your logs are suddenly empty, check that `.init()` runs at the start of `main`.

**Error 2: Running the binary from another folder**

The release binary reads `.env` and serves `static/` relative to the current folder. Started from another folder, with `DATABASE_URL` set by hand:

```bash
cd /tmp
DATABASE_URL=mysql://todo_user:todo_password@localhost:3306/db_rust_todo ~/todo-web/target/release/todo-web
```

(Adjust the path to where your project lives.) The application starts and the pages work, but the stylesheet request fails:

```text
2026-11-01T17:36:06.111866Z  INFO todo_web: connected to MySQL
2026-11-01T17:36:06.112714Z  INFO todo_web: migrations are up to date
2026-11-01T17:36:06.112804Z  INFO todo_web: Todo Web running on http://127.0.0.1:3000
2026-11-01T17:36:07.114607Z  INFO request{method=GET uri=/static/style.css version=HTTP/1.1}: tower_http::trace::on_response: finished processing request latency=0 ms status=404
```

`ServeDir::new("static")` looked for `/tmp/static/style.css`. Without `DATABASE_URL` set by hand, the program would not even start, because there is no `.env` in `/tmp`: it stops with `DATABASE_URL must be set in .env: NotPresent`, the error from Lesson 7. Always start the program from the folder that contains `static/` (and `.env`, if you use one). Process managers such as systemd have a "working directory" setting for exactly this purpose.

**Error 3: TraceLayer without INFO levels**

```rust
// Wrong: the default TraceLayer logs at DEBUG level
        .layer(TraceLayer::new_for_http())
```

```rust
// Correct
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(DefaultMakeSpan::new().level(Level::INFO))
                .on_response(DefaultOnResponse::new().level(Level::INFO)),
        )
```

With the plain `TraceLayer`, requests are handled normally, but the log shows only the startup lines, even after several requests:

```text
2026-11-01T17:36:01.820813Z  INFO todo_web: connected to MySQL
2026-11-01T17:36:01.822146Z  INFO todo_web: migrations are up to date
2026-11-01T17:36:01.822418Z  INFO todo_web: Todo Web running on http://127.0.0.1:3000
```

The request events exist, but at `DEBUG` level, which the filter `tower_http=info` hides. Either raise the layer's levels, as in the correct version, or run with `RUST_LOG=todo_web=info,tower_http=debug` to see them.

---

## 8. Exercises

**Exercise 1:** Log an `INFO` event whenever a task is created, with the new task's ID and title as fields, for example `task created task_id=25 title=Deploy Todo Web`.

**Exercise 2:** Run the server with `RUST_LOG=todo_web=info,sqlx=debug` and open a task's detail page. Find the event that shows the SQL statement of `find_task`. What does it tell you, and why is this level not the default?

**Exercise 3:** When you press `Ctrl+C`, the server stops immediately, even in the middle of a request. Make it shut down gracefully: stop accepting new connections, let open requests finish, and log `shutdown signal received, finishing open requests` and `server stopped`. Use `with_graceful_shutdown` on `axum::serve` and `tokio::signal::ctrl_c()`.

---

## 9. Solutions

**Solution for Exercise 1:**

In `src/handlers.rs`, add one line to `create_task`, right after the insert:

```rust
    let id = db::insert_task(&state.pool, &task).await?;
    tracing::info!(task_id = id, title = %task.title, "task created");
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
```

`task_id = id` records a number field directly; `title = %task.title` records the title with `Display`, which prints it without quotes. Creating a task now logs:

```text
2026-11-01T17:36:22.686302Z  INFO request{method=POST uri=/tasks version=HTTP/1.1}: todo_web::handlers: task created task_id=25 title=Deploy Todo Web
2026-11-01T17:36:22.686359Z  INFO request{method=POST uri=/tasks version=HTTP/1.1}: tower_http::trace::on_response: finished processing request latency=6 ms status=303
```

The event comes from `todo_web::handlers` and sits inside the request span, followed by the usual response line with status `303`.

**Solution for Exercise 2:**

```bash
RUST_LOG=todo_web=info,sqlx=debug cargo run
```

Opening `/tasks/2` logs, among other lines:

```text
2026-11-01T17:36:25.701003Z DEBUG sqlx::query: summary="SELECT id, title, done, …" db.statement="\n\nSELECT id, title, done, due_date, created_at, category_id FROM tasks WHERE id = ?\n" rows_affected=0 rows_returned=1 elapsed=370.076µs elapsed_secs=0.000370076
```

SQLx logs every statement at `DEBUG` level: a shortened `summary`, the full `db.statement`, how many rows it returned, and how long it took. This is invaluable when a page is slow or returns the wrong data, because you see the exact SQL that ran. It is not the default because it is very noisy: every page produces several such lines, and SQLx also logs its own housekeeping queries. At startup, you will also see the statement SQLx runs on every new connection, which includes `time_zone='+00:00'`; that is the reason the creation times stored by the application are in UTC, as noted in Lesson 10.

**Solution for Exercise 3:**

In `src/main.rs`, replace the last line of `main` and add a new function below it:

```rust
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .expect("server should run");
    tracing::info!("server stopped");
}

async fn shutdown_signal() {
    tokio::signal::ctrl_c()
        .await
        .expect("should listen for Ctrl+C");
    tracing::info!("shutdown signal received, finishing open requests");
}
```

`with_graceful_shutdown` takes a future. The server runs normally until that future completes; then it stops accepting new connections, waits for the requests in progress to finish, and returns. `tokio::signal::ctrl_c()` is a future that completes when the process receives `Ctrl+C`, using the async ideas from Lesson 2. After creating a task and pressing `Ctrl+C`, the log ends with:

```text
2026-11-01T17:36:21.175930Z  INFO todo_web: connected to MySQL
2026-11-01T17:36:21.177493Z  INFO todo_web: migrations are up to date
2026-11-01T17:36:21.177831Z  INFO todo_web: Todo Web running on http://127.0.0.1:3000
2026-11-01T17:36:22.686302Z  INFO request{method=POST uri=/tasks version=HTTP/1.1}: todo_web::handlers: task created task_id=25 title=Deploy Todo Web
2026-11-01T17:36:22.686359Z  INFO request{method=POST uri=/tasks version=HTTP/1.1}: tower_http::trace::on_response: finished processing request latency=6 ms status=303
2026-11-01T17:36:23.189886Z  INFO todo_web: shutdown signal received, finishing open requests
2026-11-01T17:36:23.190067Z  INFO todo_web: server stopped
```

Process managers send a similar signal when they restart a service, so graceful shutdown means that deploying a new version never cuts off a user in the middle of saving a task.

---

## 10. Course Wrap-Up and Next Steps

Congratulations! You started this course with a command-line to-do list that kept its tasks in a text file, and you finish it with a tested, organized, database-backed web application. Look back at what you built, module by module:

- **Module 1** laid the foundations. You wrote an HTTP server with only the standard library to see what a request and a response really are, learned async Rust with Tokio (`async`, `.await`, `join!`, and `spawn`), and prepared MySQL with a dedicated database and user.
- **Module 2** started Todo Web with Axum: routes and handlers, the `Path`, `Query`, and `Form` extractors, redirects after `POST`, and server-rendered pages with Askama templates, layouts, and automatic escaping.
- **Module 3** connected the application to MySQL with SQLx: configuration in `.env`, a connection pool shared through state, migrations with sqlx-cli and `sqlx::migrate!()`, and queries with bound parameters, `query_as`, and `FromRow`.
- **Module 4** delivered complete CRUD for tasks: listing, detail pages, creating, editing, toggling, and deleting, with `rows_affected()` turning missing rows into 404 pages.
- **Module 5** made the application safe and friendly: server-side validation with typed results and tests, error messages next to fields, and an `AppError` type that turns every failure into a proper error page through `From` and `IntoResponse`.
- **Module 6** added relationships and real querying: a `categories` table with a foreign key and `ON DELETE SET NULL`, `LEFT JOIN`, dynamic filters with `QueryBuilder`, escaped `LIKE` searches, and pagination.
- **Module 7** prepared Todo Web for the long run: modules and `AppState`, database and handler tests with `#[sqlx::test]` and `oneshot`, structured logging, static files, and a release build.

Along the way, the Rust you learned in the first course did the heavy lifting: ownership decided where values could go, `Result` and `?` carried errors, enums modeled failures and filters, traits connected your types to Axum and SQLx, and the compiler caught mistakes in templates, handlers, and queries long before a user could.

Here are some directions for what to learn next:

- **Add user accounts.** Registration and login, with passwords hashed using the `argon2` crate and sessions stored with `tower-sessions`, then a `user_id` foreign key so each person sees only their own tasks. It reuses almost every technique from this course.
- **Deploy Todo Web.** Rent a small Linux server, install MySQL, copy the release binary and the `static` folder, run it with systemd, and put Nginx with a free HTTPS certificate in front of it.
- **Build a JSON API.** Add routes under `/api` that return tasks as JSON with Axum's `Json` extractor and response type, so a mobile app or a JavaScript front end could use the same data.
- **Try compile-time checked queries.** SQLx's `query!` and `query_as!` macros verify your SQL against the database schema during compilation. Now that you know the runtime functions well, the macros are a natural next step.
- **Keep improving the app.** Due date reminders, task priorities, drag-and-drop ordering, a dark theme in the stylesheet, or a "completed this week" statistic on the home page. Each one is a chance to practice migrations, queries, templates, and tests.

Thank you for following the course to the end. Keep building!
