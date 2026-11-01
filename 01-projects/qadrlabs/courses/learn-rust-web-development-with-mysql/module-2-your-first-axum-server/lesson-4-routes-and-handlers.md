## 1. Before You Begin

Module 1 gave you the three foundations of this course: how HTTP requests and responses work (Lesson 1), how async Rust and Tokio let one program serve many clients (Lesson 2), and a MySQL database ready for your data (Lesson 3). Now the real application begins.

In this lesson, you create the `todo-web` project that you will grow until the end of the course, and you start it with Axum. Axum is a web framework built on Tokio. It accepts connections, parses HTTP for you, and calls your async functions, called handlers, based on the method and path of each request. Your job shrinks to two things: write handlers that return responses, and tell the router which handler belongs to which URL.

### What You'll Build

The first version of Todo Web: an Axum server on port 3000 with a home page, an about page, a health check, a `/tasks` route that answers `GET` and `POST` differently, and a custom 404 page for every unknown URL.

### What You'll Learn

- ✅ How to create the project and add Axum and Tokio with `cargo add`
- ✅ How to start a server with `Router`, `TcpListener`, and `axum::serve`
- ✅ What a handler is and which return types Axum turns into responses
- ✅ How to return plain text, HTML with `Html`, and custom status codes with `StatusCode`
- ✅ How to route different HTTP methods on the same path
- ✅ How to add a fallback handler for unknown URLs

### What You'll Need

- Lessons 1 to 3 completed
- Rust and Cargo installed, plus an internet connection for downloading crates
- `curl` and a web browser

---

## 2. Create the Project and Start a Server

Every Axum application has the same skeleton: build a `Router`, bind a TCP listener, and hand both to `axum::serve`. You will write that skeleton with a single route first, and grow it in the next section.

### Step 1: Create the Project and Add the Dependencies

Create the project in the folder where you keep your Rust code:

```bash
cargo new todo-web
cd todo-web
cargo add axum
cargo add tokio --features full
```

The first `cargo add` adds Axum, and the second adds Tokio with all features, as in Lesson 2. Axum needs Tokio as its runtime. Your `Cargo.toml` now contains:

```toml
[package]
name = "todo-web"
version = "0.1.0"
edition = "2024"

[dependencies]
axum = "0.8.9"
tokio = { version = "1.54.1", features = ["full"] }
```

Your version numbers may be newer. This course uses Axum 0.8; any `0.8.x` version works. Axum 0.7 and older have small but important differences, especially in route paths, which Section 7 shows.

### Step 2: Write the Smallest Axum Application

Replace the contents of `src/main.rs` with:

```rust
use axum::{Router, routing::get};

async fn home() -> &'static str {
    "Hello from Todo Web!"
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(home));

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    println!("Todo Web running on http://127.0.0.1:3000");

    axum::serve(listener, app).await.expect("server should run");
}
```

Here is what each part does:

- `use axum::{Router, routing::get};` imports the router type and the `get` function, which attaches a handler to the `GET` method.
- `async fn home() -> &'static str` is a handler: an async function whose return value Axum can turn into an HTTP response. A string slice becomes a `200 OK` response with a plain text body. `&'static str` means a string that lives for the whole program, such as a string literal.
- `Router::new().route("/", get(home))` creates a router and registers one route: `GET` requests for the path `/` are handled by `home`. Notice that you pass the function itself, `home`, not a call `home()`. Axum calls it for every matching request.
- `tokio::net::TcpListener::bind(...)` opens port 3000, exactly like the async server in Lesson 2.
- `axum::serve(listener, app).await` starts the server. Inside, it runs the accept loop you wrote by hand in Lesson 2: accept a connection, spawn a task, parse the request, find the route, call the handler, and write the response. It runs until the program is stopped, so the `.expect(...)` only matters if the server fails.

Run the server:

```bash
cargo run
```

The first build downloads and compiles Axum and its dependencies, which takes a while. Then you see:

```text
Todo Web running on http://127.0.0.1:3000
```

### Step 3: Send the First Requests

In a second terminal, request the home page:

```bash
curl -i http://127.0.0.1:3000/
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/plain; charset=utf-8
content-length: 20
date: Sun, 01 Nov 2026 16:45:31 GMT

Hello from Todo Web!
```

Compare this with the response you built with `format!` in Lesson 1. Axum filled in the status line, the `content-type` header (it knows a string slice is plain text), the `content-length`, and a `date` header. Your date will of course be different. Header names are written in lowercase; HTTP header names are case-insensitive, so `content-type` and `Content-Type` mean the same thing.

Now request a path that has no route:

```bash
curl -i http://127.0.0.1:3000/missing
```

Output:

```text
HTTP/1.1 404 Not Found
content-length: 0
date: Sun, 01 Nov 2026 16:45:31 GMT
```

The router already answers unknown paths with `404 Not Found`, but with an empty body. In a browser, that shows a blank page. You will replace it with a friendlier page in the next section. Stop the server with `Ctrl+C`.

---

## 3. Return Different Kinds of Responses

A handler can return many types, as long as Axum knows how to turn them into a response. Formally, the return type must implement Axum's `IntoResponse` trait. Strings, `Html`, status codes, and tuples combining them all do. In this section, you use the most common ones and add a route that behaves differently depending on the HTTP method.

### Step 1: Add More Routes and Response Types

Replace `src/main.rs` with this version:

```rust
use axum::{
    Router,
    http::StatusCode,
    response::Html,
    routing::get,
};

async fn home() -> Html<&'static str> {
    Html("<h1>Todo Web</h1><p>Your tasks, now in the browser.</p>")
}

async fn about() -> &'static str {
    "Todo Web is the web version of the command-line to-do list."
}

async fn health() -> (StatusCode, &'static str) {
    (StatusCode::OK, "ok")
}

async fn list_tasks() -> Html<String> {
    let tasks = ["Learn Rust", "Build a web app", "Connect to MySQL"];
    let items: String = tasks
        .iter()
        .map(|task| format!("<li>{task}</li>"))
        .collect();
    Html(format!("<h1>Tasks</h1><ul>{items}</ul>"))
}

async fn create_task() -> (StatusCode, &'static str) {
    (StatusCode::CREATED, "task created (not saved yet)")
}

async fn not_found() -> (StatusCode, Html<&'static str>) {
    (StatusCode::NOT_FOUND, Html("<h1>404</h1><p>Page not found.</p>"))
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(home))
        .route("/about", get(about))
        .route("/health", get(health))
        .route("/tasks", get(list_tasks).post(create_task))
        .fallback(not_found);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    println!("Todo Web running on http://127.0.0.1:3000");

    axum::serve(listener, app).await.expect("server should run");
}
```

There is a lot of new code, but each handler is small. Here is what each piece does:

- The `use` block now also imports `StatusCode`, an enum of all HTTP status codes, and `Html`, a wrapper type.
- `home` returns `Html<&'static str>`. Wrapping a string in `Html(...)` does not change the text; it only tells Axum to send the header `content-type: text/html` so the browser renders it as a web page instead of showing the tags as text.
- `about` returns a plain string slice, which becomes a `text/plain` response, as in Section 2.
- `health` returns a tuple `(StatusCode, &'static str)`. When a handler returns a tuple, Axum uses the status code from the first element and the body from the second. `StatusCode::OK` is `200`. Health check routes like this are used by monitoring tools to ask "is the server alive?"
- `list_tasks` returns `Html<String>`, because the HTML is built at runtime. It uses the same `iter`, `map`, and `collect` chain as the exercises in Lesson 1. The tasks are still hard-coded; they move into templates in Lesson 6 and into MySQL in Lesson 10.
- `create_task` returns `StatusCode::CREATED` (`201`), the status that means "a new resource was created." It does not save anything yet; reading form data is the topic of Lesson 5.
- `not_found` returns a tuple of `StatusCode::NOT_FOUND` (`404`) and an HTML page.
- In `main`, the router now has four routes. `get(list_tasks).post(create_task)` attaches two handlers to the same path: `GET /tasks` calls `list_tasks`, and `POST /tasks` calls `create_task`. This is called method routing.
- `.fallback(not_found)` sets the handler that runs when no route matches the path.

Run the server again:

```bash
cargo run
```

Output:

```text
Todo Web running on http://127.0.0.1:3000
```

---

## 4. Run and Test

Test every route with `curl -i` so you can see the status codes and headers, then look at the pages in the browser.

### Step 1: Test the GET Routes

In the second terminal:

```bash
curl -i http://127.0.0.1:3000/
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 55
date: Sun, 01 Nov 2026 16:45:45 GMT

<h1>Todo Web</h1><p>Your tasks, now in the browser.</p>
```

The `content-type` is now `text/html`, thanks to the `Html` wrapper.

```bash
curl -i http://127.0.0.1:3000/about
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/plain; charset=utf-8
content-length: 59
date: Sun, 01 Nov 2026 16:45:45 GMT

Todo Web is the web version of the command-line to-do list.
```

```bash
curl -i http://127.0.0.1:3000/health
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/plain; charset=utf-8
content-length: 2
date: Sun, 01 Nov 2026 16:45:45 GMT

ok
```

```bash
curl -i http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 91
date: Sun, 01 Nov 2026 16:45:45 GMT

<h1>Tasks</h1><ul><li>Learn Rust</li><li>Build a web app</li><li>Connect to MySQL</li></ul>
```

### Step 2: Test Method Routing

`curl -X` sets the HTTP method. Send a `POST` to `/tasks`:

```bash
curl -i -X POST http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 201 Created
content-type: text/plain; charset=utf-8
content-length: 28
date: Sun, 01 Nov 2026 16:45:45 GMT

task created (not saved yet)
```

The same path answered differently because the method changed. Now try a method that has no handler:

```bash
curl -i -X DELETE http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 405 Method Not Allowed
allow: GET,HEAD,POST
content-length: 0
date: Sun, 01 Nov 2026 16:45:45 GMT
```

Axum knows the path exists but has no `DELETE` handler for it, so it answers `405 Method Not Allowed` and lists the allowed methods in the `allow` header. `HEAD` appears automatically because Axum answers `HEAD` requests with the headers of the `GET` handler. Notice that this is not a `404`: the fallback only runs when the path itself is unknown.

### Step 3: Test the Fallback

```bash
curl -i http://127.0.0.1:3000/missing
```

Output:

```text
HTTP/1.1 404 Not Found
content-type: text/html; charset=utf-8
content-length: 34
date: Sun, 01 Nov 2026 16:45:45 GMT

<h1>404</h1><p>Page not found.</p>
```

The status is still `404`, but now with an HTML body.

### Step 4: Check in the Browser

Open `http://127.0.0.1:3000`, `http://127.0.0.1:3000/tasks`, and `http://127.0.0.1:3000/anything` in your browser. The home page and the 404 page are rendered as HTML with headings, the task list shows three bullet points, and `/about` shows plain text. Browsers always send `GET` requests when you type a URL, so you cannot test the `POST` route from the address bar; in Lesson 5, an HTML form will send it. Stop the server with `Ctrl+C` when you are done.

---

## 5. How Axum Routes a Request

You have now used every piece of an Axum application. Here is how they fit together when a request arrives:

```text
request: POST /tasks
   |
   v
Router: find the route for the path "/tasks"
   |       not found -> fallback handler (404 page)
   v
MethodRouter: find the handler for POST
   |       not found -> 405 Method Not Allowed
   v
create_task().await  ->  (StatusCode::CREATED, "...")
   |
   v
IntoResponse: status line, headers, body  ->  sent to the client
```

A few rules are worth remembering:

- **Routes match the whole path.** `/tasks` does not match `/tasks/1` or `/tasks/`. Each path needs its own route; Lesson 5 shows how to capture parts of a path, such as an ID.
- **Handlers are async functions.** Their arguments (none so far) and their return type decide how Axum calls them. In Lesson 5, arguments called extractors will receive data from the request.
- **The return type decides the response.** These are the types you used and what Axum does with them:

| Return type | Status | `content-type` |
| --- | --- | --- |
| `&'static str` or `String` | `200 OK` | `text/plain; charset=utf-8` |
| `Html<T>` | `200 OK` | `text/html; charset=utf-8` |
| `StatusCode` | the given status | no body |
| `(StatusCode, T)` | the given status | from `T` |

- **Order of `.route` calls does not matter**, but registering the same method and path twice is a mistake that Axum reports when the server starts.

---

## 6. Fix the Errors in Your Code

**Error 1: A handler that is not async**

```rust
// Wrong
fn about() -> &'static str {
    "Todo Web is the web version of the command-line to-do list."
}
```

```rust
// Correct
async fn about() -> &'static str {
    "Todo Web is the web version of the command-line to-do list."
}
```

Axum only accepts async functions as handlers. Without `async`, the program does not compile, and the error is long because it comes from inside Axum's generic code:

```text
error[E0277]: the trait bound `fn() -> &'static str {about}: Handler<_, _>` is not satisfied
   --> src/main.rs:41:30
    |
 41 |         .route("/about", get(about))
    |                          --- ^^^^^ the trait `Handler<_, _>` is not implemented for fn item `fn() -> &'static str {about}`
    |                          |
    |                          required by a bound introduced by this call
    |
    = note: Consider using `#[axum::debug_handler]` to improve the error message
```

The key phrase is "`Handler<_, _>` is not implemented." Whenever you see it, check the handler: is it `async`, does it return a type that implements `IntoResponse`, and are its arguments valid extractors? The note mentions `#[axum::debug_handler]`, an attribute that produces clearer messages; it requires enabling Axum's `macros` feature.

**Error 2: Using the old `:id` path syntax**

```rust
// Wrong: Axum 0.7 syntax
.route("/tasks/:id", get(show_task))
```

```rust
// Correct: Axum 0.8 syntax
.route("/tasks/{id}", get(show_task))
```

Many tutorials online were written for Axum 0.7, which wrote path parameters as `:id`. Axum 0.8 uses `{id}`. The old syntax compiles, but the server stops as soon as it starts:

```text
thread 'main' (29665) panicked at src/main.rs:42:10:
Path segments must not start with `:`. For capture groups, use `{capture}`. If you meant to literally match a segment starting with a colon, call `without_v07_checks` on the router.
```

The message tells you exactly what to change. You will use `{id}` paths in Lesson 5.

**Error 3: Registering the same route twice**

```rust
// Wrong
.route("/about", get(about))
.route("/about", get(home))
```

```rust
// Correct
.route("/about", get(about))
.route("/", get(home))
```

Two handlers for the same method and path would be ambiguous, so Axum refuses to start:

```text
thread 'main' (29936) panicked at src/main.rs:42:10:
Overlapping method route. Handler for `GET /about` already exists
```

This usually happens after copying a `.route` line and forgetting to change the path. The line number in the panic message points to the duplicated route. (The thread number differs on every run.)

---

## 7. Exercises

**Exercise 1:** Add a `GET /version` route that returns the version number from `Cargo.toml` as plain text. Hint: the macro `env!("CARGO_PKG_VERSION")` gives you that value at compile time as a `&'static str`.

**Exercise 2:** Add a `GET /teapot` route that responds with the status `418 I'm a teapot` and the body `I am a teapot, not a to-do list.` Find the right constant in `StatusCode`.

**Exercise 3:** Move the three task titles into a constant `TASKS` at the top of the file, use it in `list_tasks`, and add a `GET /tasks/count` route that returns the text `3 tasks`, computed from the length of `TASKS`.

---

## 8. Solutions

All three solutions fit in one updated `src/main.rs`:

```rust
use axum::{
    Router,
    http::StatusCode,
    response::Html,
    routing::get,
};

const TASKS: [&str; 3] = ["Learn Rust", "Build a web app", "Connect to MySQL"];

async fn home() -> Html<&'static str> {
    Html("<h1>Todo Web</h1><p>Your tasks, now in the browser.</p>")
}

async fn about() -> &'static str {
    "Todo Web is the web version of the command-line to-do list."
}

async fn health() -> (StatusCode, &'static str) {
    (StatusCode::OK, "ok")
}

async fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

async fn teapot() -> (StatusCode, &'static str) {
    (StatusCode::IM_A_TEAPOT, "I am a teapot, not a to-do list.")
}

async fn list_tasks() -> Html<String> {
    let items: String = TASKS
        .iter()
        .map(|task| format!("<li>{task}</li>"))
        .collect();
    Html(format!("<h1>Tasks</h1><ul>{items}</ul>"))
}

async fn count_tasks() -> String {
    format!("{} tasks", TASKS.len())
}

async fn create_task() -> (StatusCode, &'static str) {
    (StatusCode::CREATED, "task created (not saved yet)")
}

async fn not_found() -> (StatusCode, Html<&'static str>) {
    (StatusCode::NOT_FOUND, Html("<h1>404</h1><p>Page not found.</p>"))
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(home))
        .route("/about", get(about))
        .route("/health", get(health))
        .route("/version", get(version))
        .route("/teapot", get(teapot))
        .route("/tasks", get(list_tasks).post(create_task))
        .route("/tasks/count", get(count_tasks))
        .fallback(not_found);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    println!("Todo Web running on http://127.0.0.1:3000");

    axum::serve(listener, app).await.expect("server should run");
}
```

**Solution for Exercise 1:**

`env!("CARGO_PKG_VERSION")` is replaced by the compiler with the `version` value from `Cargo.toml`. Because it is a string literal baked into the program, its type is `&'static str`, which is exactly what the handler returns.

```bash
curl http://127.0.0.1:3000/version
```

Output:

```text
0.1.0
```

**Solution for Exercise 2:**

`StatusCode::IM_A_TEAPOT` is status `418`, originally an April Fools' joke in an internet standard, and still part of the HTTP status registry. The tuple return type works the same way as in `create_task`.

```bash
curl -i http://127.0.0.1:3000/teapot
```

Output:

```text
HTTP/1.1 418 I'm a teapot
content-type: text/plain; charset=utf-8
content-length: 32
date: Sun, 01 Nov 2026 16:46:12 GMT

I am a teapot, not a to-do list.
```

**Solution for Exercise 3:**

`const TASKS: [&str; 3]` is an array constant, available to every function in the file. `list_tasks` iterates over it directly, and `count_tasks` uses `TASKS.len()`. `count_tasks` returns an owned `String` because the text is built with `format!`; Axum treats `String` exactly like `&str`. The route `/tasks/count` is separate from `/tasks`, because routes match whole paths.

```bash
curl http://127.0.0.1:3000/tasks/count
```

Output:

```text
3 tasks
```

---

## Next Up - Lesson 5

In this lesson, you created the `todo-web` project, started an Axum server, and wrote handlers that return plain text, HTML, and custom status codes. You routed different HTTP methods on the same path and replaced the empty 404 response with a fallback page.

So far, your handlers ignore the request completely: they always return the same thing. In Lesson 5, you will read data from requests with Axum extractors. You will capture a task ID from paths such as `/tasks/2`, read search options from query strings such as `?search=rust`, receive submitted HTML forms with serde, and redirect the browser after a `POST` request.
