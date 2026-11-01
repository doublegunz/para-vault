## 1. Before You Begin

In Lesson 4, you built the first version of Todo Web with Axum. Every handler returned a response, but none of them looked at the request: `/tasks` always showed the same three tasks, and `POST /tasks` always answered the same text. A real to-do app needs data from the user. It must know which task to show, what to search for, and what title a new task should have.

Axum delivers request data to handlers through extractors. An extractor is a type you put in a handler's parameter list; before calling the handler, Axum pulls the matching data out of the request, converts it to that type, and passes it in. If the conversion fails, Axum answers with an error status and never calls your handler. In this lesson, you will use the three extractors the to-do app needs most: `Path` for parts of the URL, `Query` for query strings, and `Form` for submitted HTML forms. You will also send the browser to another page with a redirect.

### What You'll Build

An updated Todo Web with a detail page for each task (`/tasks/2`), a search filter on the task list (`/tasks?search=rust`), a "new task" form at `/tasks/new`, and a `POST /tasks` handler that reads the submitted title and redirects back to the list.

### What You'll Learn

- ✅ What an extractor is and how Axum uses handler parameters
- ✅ How to capture URL segments with `Path` and the `{id}` route syntax
- ✅ How to read optional query string values with `Query` and a serde struct
- ✅ How to receive HTML form data with `Form`
- ✅ How to redirect after a `POST` request with `Redirect`
- ✅ How to return different response types from one handler with `Response` and `into_response`

### What You'll Need

- The `todo-web` project from Lesson 4
- The `TASKS` constant from Lesson 4's Exercise 3 (it is repeated below, so you can add it now if you skipped the exercise)
- `curl` and a web browser

---

## 2. Read Values from the URL Path

Most web applications put identifiers in the path: `/tasks/2` means "task number 2." Axum lets you mark a segment of the route as a capture with curly braces, and the `Path` extractor gives you its value already converted to the type you ask for.

### Step 1: Add the Task List Constant

Make sure `src/main.rs` has this constant below the `use` block. If you solved Exercise 3 in Lesson 4, it is already there:

```rust
const TASKS: [&str; 3] = ["Learn Rust", "Build a web app", "Connect to MySQL"];
```

This array stands in for the database until Lesson 10. Task number 1 is at index 0, task number 2 at index 1, and so on.

### Step 2: Write the show_task Handler

Change the `use` block at the top of `src/main.rs` so it imports everything this lesson needs:

```rust
use axum::{
    Form, Router,
    extract::{Path, Query},
    http::StatusCode,
    response::{Html, IntoResponse, Redirect, Response},
    routing::get,
};
use serde::Deserialize;
```

`serde` is not installed yet, so the project will not compile until you add it in Section 3. If you want to build after every step, add it now with `cargo add serde --features derive`. Then add this handler below `list_tasks`:

```rust
async fn show_task(Path(id): Path<usize>) -> Response {
    match id.checked_sub(1).and_then(|index| TASKS.get(index)) {
        Some(title) => Html(format!("<h1>Task {id}</h1><p>{title}</p>")).into_response(),
        None => (StatusCode::NOT_FOUND, Html("<h1>Task not found</h1>")).into_response(),
    }
}
```

Here is what is happening:

- `Path(id): Path<usize>` is the extractor. `Path<usize>` tells Axum to take the captured path segment and parse it as a `usize`. The left side, `Path(id)`, is a pattern that unwraps the `Path` wrapper right in the parameter list, so inside the function `id` is a plain `usize`. This is the same destructuring you used with tuple structs in the first course.
- `id.checked_sub(1)` converts the task number to an index. It returns `None` instead of panicking when `id` is 0, because 0 minus 1 does not fit in an unsigned number.
- `.and_then(|index| TASKS.get(index))` looks up the index. `get` returns `None` for an index that is out of range, so both "0" and "99" end up as `None`.
- The two `match` arms return different types: one an `Html<String>`, the other a tuple with a status code. A function can only have one return type, so both are converted with `.into_response()` into Axum's general `Response` type. `IntoResponse` is the trait that provides this method, which is why it is imported.

### Step 3: Register the Route

Add the route to the router in `main`. The full `main` function now looks like this (the `/tasks/new` route is used in Section 4; its handler comes later, so leave that line out until then if you are building as you go):

```rust
#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(home))
        .route("/about", get(about))
        .route("/health", get(health))
        .route("/tasks", get(list_tasks).post(create_task))
        .route("/tasks/new", get(new_task_form))
        .route("/tasks/{id}", get(show_task))
        .fallback(not_found);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    println!("Todo Web running on http://127.0.0.1:3000");

    axum::serve(listener, app).await.expect("server should run");
}
```

`/tasks/{id}` matches `/tasks/` followed by exactly one segment, and the name inside the braces is the capture. Notice that `/tasks/new` also looks like `/tasks/` plus one segment. Axum always prefers a fixed path over a capture, so `/tasks/new` goes to `new_task_form` and every other single segment goes to `show_task`, no matter in which order the routes are registered.

---

## 3. Read Options from the Query String

The part of a URL after `?` is the query string: `/tasks?search=rust&page=2`. It holds optional settings for a page, such as a search term, a filter, or a page number. The `Query` extractor parses it into a struct, using serde to match names to fields.

### Step 1: Add serde

serde is the standard Rust library for converting data between formats. Axum uses it to turn query strings and form bodies into your structs. Add it with the `derive` feature, which provides the `#[derive(Deserialize)]` attribute:

```bash
cargo add serde --features derive
```

### Step 2: Describe the Query String with a Struct

Add this struct below the `TASKS` constant:

```rust
#[derive(Deserialize)]
struct TaskFilter {
    search: Option<String>,
}
```

`#[derive(Deserialize)]` generates the code that fills a `TaskFilter` from incoming data. The field name `search` must match the name in the query string. The field is an `Option<String>` because the user may not send it at all: `/tasks` should still work and show every task. If you used a plain `String`, a request without `?search=...` would be rejected.

### Step 3: Filter the List

Replace the `list_tasks` handler with this version:

```rust
async fn list_tasks(Query(filter): Query<TaskFilter>) -> Html<String> {
    let search = filter.search.unwrap_or_default().to_lowercase();
    let items: String = TASKS
        .iter()
        .filter(|task| task.to_lowercase().contains(&search))
        .map(|task| format!("<li>{task}</li>"))
        .collect();
    Html(format!("<h1>Tasks</h1><ul>{items}</ul>"))
}
```

Line by line:

- `Query(filter): Query<TaskFilter>` extracts the query string into a `TaskFilter`, destructured just like `Path`.
- `filter.search.unwrap_or_default()` turns `None` into an empty string. `.to_lowercase()` makes the search case-insensitive.
- The new `.filter(...)` step keeps only tasks whose lowercase title contains the search text. Every string contains the empty string, so with no search term, all tasks pass. This is the same pattern as the `find` command in the first course's final project.

---

## 4. Receive Form Data and Redirect

HTML forms are how users send data in a server-rendered app. When a form with `method="post"` is submitted, the browser sends a `POST` request whose body contains the fields encoded as `title=Write+tests`. The `Form` extractor decodes that body into a struct.

### Step 1: Add the Form Struct and the Form Page

Add this struct below `TaskFilter`:

```rust
#[derive(Deserialize)]
struct NewTask {
    title: String,
}
```

This time the field is a plain `String`, because a new task must have a title. Then add a handler that shows the form, below `show_task`:

```rust
async fn new_task_form() -> Html<&'static str> {
    Html(
        r#"<h1>New Task</h1>
<form method="post" action="/tasks">
  <input name="title" placeholder="What needs to be done?">
  <button type="submit">Add</button>
</form>"#,
    )
}
```

`r#"..."#` is a raw string literal: it can span several lines and contain double quotes without escaping them, which is convenient for HTML. The form sends a `POST` request to `/tasks`, and the input's `name="title"` is what connects it to the `title` field of `NewTask`.

### Step 2: Read the Form and Redirect

Replace the `create_task` handler with:

```rust
async fn create_task(Form(form): Form<NewTask>) -> Redirect {
    println!("new task received: {}", form.title);
    Redirect::to("/tasks")
}
```

Here is what it does:

- `Form(form): Form<NewTask>` reads the request body and decodes it into a `NewTask`. If the `title` field is missing, Axum rejects the request before your code runs.
- `println!` prints the title in the server terminal. There is nowhere to save it yet; MySQL takes over this job in Lesson 11.
- `Redirect::to("/tasks")` answers with status `303 See Other` and a `location` header. The browser then loads `/tasks` with a normal `GET` request.

Redirecting after a successful `POST` is a pattern called Post/Redirect/Get. Without it, the browser would stay on the result of the `POST`, and pressing the refresh button would submit the form again, creating a duplicate task. After a redirect, refresh simply reloads the list.

---

## 5. Run and Test

Before testing, compare your file with the complete version. If anything does not compile, this is the reference.

### Step 1: Check the Complete File

`src/main.rs` should now contain:

```rust
use axum::{
    Form, Router,
    extract::{Path, Query},
    http::StatusCode,
    response::{Html, IntoResponse, Redirect, Response},
    routing::get,
};
use serde::Deserialize;

const TASKS: [&str; 3] = ["Learn Rust", "Build a web app", "Connect to MySQL"];

#[derive(Deserialize)]
struct TaskFilter {
    search: Option<String>,
}

#[derive(Deserialize)]
struct NewTask {
    title: String,
}

async fn home() -> Html<&'static str> {
    Html("<h1>Todo Web</h1><p>Your tasks, now in the browser.</p>")
}

async fn about() -> &'static str {
    "Todo Web is the web version of the command-line to-do list."
}

async fn health() -> (StatusCode, &'static str) {
    (StatusCode::OK, "ok")
}

async fn list_tasks(Query(filter): Query<TaskFilter>) -> Html<String> {
    let search = filter.search.unwrap_or_default().to_lowercase();
    let items: String = TASKS
        .iter()
        .filter(|task| task.to_lowercase().contains(&search))
        .map(|task| format!("<li>{task}</li>"))
        .collect();
    Html(format!("<h1>Tasks</h1><ul>{items}</ul>"))
}

async fn show_task(Path(id): Path<usize>) -> Response {
    match id.checked_sub(1).and_then(|index| TASKS.get(index)) {
        Some(title) => Html(format!("<h1>Task {id}</h1><p>{title}</p>")).into_response(),
        None => (StatusCode::NOT_FOUND, Html("<h1>Task not found</h1>")).into_response(),
    }
}

async fn new_task_form() -> Html<&'static str> {
    Html(
        r#"<h1>New Task</h1>
<form method="post" action="/tasks">
  <input name="title" placeholder="What needs to be done?">
  <button type="submit">Add</button>
</form>"#,
    )
}

async fn create_task(Form(form): Form<NewTask>) -> Redirect {
    println!("new task received: {}", form.title);
    Redirect::to("/tasks")
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
        .route("/tasks/new", get(new_task_form))
        .route("/tasks/{id}", get(show_task))
        .fallback(not_found);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    println!("Todo Web running on http://127.0.0.1:3000");

    axum::serve(listener, app).await.expect("server should run");
}
```

Start the server:

```bash
cargo run
```

Output:

```text
Todo Web running on http://127.0.0.1:3000
```

### Step 2: Test the Path Extractor

In a second terminal:

```bash
curl -i http://127.0.0.1:3000/tasks/2
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 37
date: Sun, 01 Nov 2026 16:47:50 GMT

<h1>Task 2</h1><p>Build a web app</p>
```

A number that does not match a task gets your own 404 page:

```bash
curl -i http://127.0.0.1:3000/tasks/9
```

Output:

```text
HTTP/1.1 404 Not Found
content-type: text/html; charset=utf-8
content-length: 23
date: Sun, 01 Nov 2026 16:47:50 GMT

<h1>Task not found</h1>
```

`/tasks/0` gives the same result, thanks to `checked_sub`. Now send something that is not a number at all:

```bash
curl -i http://127.0.0.1:3000/tasks/abc
```

Output:

```text
HTTP/1.1 400 Bad Request
content-type: text/plain; charset=utf-8
content-length: 42
date: Sun, 01 Nov 2026 16:47:50 GMT

Invalid URL: Cannot parse `abc` to a `u64`
```

Your handler never ran. The `Path` extractor failed to parse `abc` and Axum answered `400 Bad Request` on its own. The message says `u64` because `usize` is a 64-bit number on a 64-bit system. This is the type system protecting your handler: inside `show_task`, `id` is always a valid number.

### Step 3: Test the Query Extractor

```bash
curl -i "http://127.0.0.1:3000/tasks?search=RUST"
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 42
date: Sun, 01 Nov 2026 16:47:50 GMT

<h1>Tasks</h1><ul><li>Learn Rust</li></ul>
```

The search found `Learn Rust` even though the query was uppercase. Put the URL in double quotes in the shell, because `?` and `&` have special meanings there. Without a query string, or with an empty one such as `/tasks?search=`, all three tasks are listed:

```bash
curl -i http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 91
date: Sun, 01 Nov 2026 16:47:50 GMT

<h1>Tasks</h1><ul><li>Learn Rust</li><li>Build a web app</li><li>Connect to MySQL</li></ul>
```

### Step 4: Test the Form and the Redirect

`curl -d` sends a `POST` request with a form-encoded body, exactly like a browser submitting a form:

```bash
curl -i -d "title=Write tests" http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 303 See Other
location: /tasks
content-length: 0
date: Sun, 01 Nov 2026 16:47:50 GMT
```

The server terminal shows the title it received:

```text
new task received: Write tests
```

Add `-L` to make `curl` follow the redirect like a browser would:

```bash
curl -i -L -d "title=Write tests" http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 303 See Other
location: /tasks
content-length: 0
date: Sun, 01 Nov 2026 16:48:32 GMT

HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 91
date: Sun, 01 Nov 2026 16:48:32 GMT

<h1>Tasks</h1><ul><li>Learn Rust</li><li>Build a web app</li><li>Connect to MySQL</li></ul>
```

Two responses: the `303` from `create_task`, then the task list from a new `GET /tasks` request. The new task is not in the list yet, because nothing stores it.

### Step 5: Try It in the Browser

Open `http://127.0.0.1:3000/tasks/new`, type a title, and press **Add**. The browser lands on `/tasks`, and the server terminal prints the title. Press the browser's refresh button: the list simply reloads, and no new line appears in the terminal, which shows that Post/Redirect/Get works. Also try `http://127.0.0.1:3000/tasks?search=web` and `http://127.0.0.1:3000/tasks/3`. Stop the server with `Ctrl+C` when you are done.

---

## 6. How Extractors Work

You have used three extractors. They all follow the same rules, and knowing the rules makes Axum's errors much easier to understand.

| Extractor | Reads from | Example request | Failure status |
| --- | --- | --- | --- |
| `Path<T>` | Captured route segments | `/tasks/2` | `400 Bad Request` |
| `Query<T>` | The query string after `?` | `/tasks?search=rust` | `400 Bad Request` |
| `Form<T>` | A form-encoded request body | `title=Write+tests` | `415` or `422` |

- **Extraction happens before your handler runs.** If any extractor fails, Axum sends its rejection response and your handler is never called. This keeps validation of the request's shape out of your code.
- **`T` decides what is accepted.** `Path<usize>` accepts only numbers. A `String` field in a form is required; an `Option<String>` field is optional. serde matches names in the request to struct field names.
- **A handler can have several extractors.** For example, `async fn update(Path(id): Path<u64>, Form(form): Form<EditTask>)` reads both the ID and the form. You will write exactly that in Lesson 12.
- **The body can only be read once.** Extractors that consume the request body, such as `Form`, must be the last parameter. Path, query, and (from Lesson 7) state extractors come first.
- **Values arrive decoded.** Browsers encode special characters in URLs and form bodies, for example a space as `+` or `%20` and `&` as `%26`. By the time `form.title` reaches your handler, it is the plain text the user typed.

---

## 7. Fix the Errors in Your Code

**Error 1: Forgetting `#[derive(Deserialize)]`**

```rust
// Wrong
struct NewTask {
    title: String,
}
```

```rust
// Correct
#[derive(Deserialize)]
struct NewTask {
    title: String,
}
```

`Form<NewTask>` can only be an extractor if serde knows how to build a `NewTask`. Without the derive, the handler no longer qualifies as a handler, and you get the same kind of message you saw in Lesson 4:

```text
error[E0277]: the trait bound `fn(Form<NewTask>) -> impl Future<Output = Redirect> {create_task}: Handler<_, _>` is not satisfied
   --> src/main.rs:75:47
    |
 75 |         .route("/tasks", get(list_tasks).post(create_task))
    |                                          ---- ^^^^^^^^^^^ the trait `Handler<_, _>` is not implemented for fn item `fn(Form<NewTask>) -> impl Future<Output = Redirect> {create_task}`
```

The error points at the route, not at the struct. When a handler that used to work suddenly stops being a `Handler`, check the types used in its extractors first.

**Error 2: Putting the body extractor before other extractors**

```rust
// Wrong
async fn create_task(Form(form): Form<NewTask>, Query(filter): Query<TaskFilter>) -> Redirect {
```

```rust
// Correct
async fn create_task(Query(filter): Query<TaskFilter>, Form(form): Form<NewTask>) -> Redirect {
```

`Form` consumes the request body, so it must be the last parameter. The wrong order produces the same "`Handler<_, _>` is not implemented" error:

```text
error[E0277]: the trait bound `fn(Form<NewTask>, Query<TaskFilter>) -> _ {create_task}: Handler<_, _>` is not satisfied
   --> src/main.rs:77:47
    |
 77 |         .route("/tasks", get(list_tasks).post(create_task))
    |                                          ---- ^^^^^^^^^^^ unsatisfied trait bound
```

Swap the parameters so the body extractor comes last, and the error disappears.

**Error 3: An input name that does not match the struct field**

```html
<!-- Wrong: the struct field is called title -->
<input name="name" placeholder="What needs to be done?">
```

```html
<!-- Correct -->
<input name="title" placeholder="What needs to be done?">
```

This mistake compiles, because the HTML is just a string to Rust. It fails at runtime when the form is submitted. You can reproduce what the browser sends with `curl`:

```bash
curl -i -d "name=x" http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 422 Unprocessable Entity
content-type: text/plain; charset=utf-8
content-length: 54
date: Sun, 01 Nov 2026 16:47:50 GMT

Failed to deserialize form body: missing field `title`
```

The body tells you which field serde expected. Make the `name` attribute of every input match a field of the form struct. A related status, `415 Unsupported Media Type`, means the request was not form-encoded at all, for example when a client sends JSON to a `Form` handler.

---

## 8. Exercises

**Exercise 1:** Add an optional `limit` field of type `Option<usize>` to `TaskFilter`. When it is present, `list_tasks` shows at most that many tasks; when it is missing, it shows all of them. Test `/tasks?limit=2`, `/tasks?search=a&limit=1`, and `/tasks?limit=two`.

**Exercise 2:** Add a route `GET /hello/{name}` that captures the name as a `String` and returns `Hello, <name>! You have 3 tasks.` as plain text. Test it with a name that contains a space, written as `%20` in the URL.

**Exercise 3:** Add a second field to the form: `<input name="due_date" type="date">`. Add `due_date: String` to `NewTask`, and print `new task received: <title> (due <date>)` when a date was entered, or `new task received: <title> (no due date)` when the field was left empty.

---

## 9. Solutions

**Solution for Exercise 1:**

```rust
#[derive(Deserialize)]
struct TaskFilter {
    search: Option<String>,
    limit: Option<usize>,
}
```

```rust
async fn list_tasks(Query(filter): Query<TaskFilter>) -> Html<String> {
    let search = filter.search.unwrap_or_default().to_lowercase();
    let items: String = TASKS
        .iter()
        .filter(|task| task.to_lowercase().contains(&search))
        .take(filter.limit.unwrap_or(TASKS.len()))
        .map(|task| format!("<li>{task}</li>"))
        .collect();
    Html(format!("<h1>Tasks</h1><ul>{items}</ul>"))
}
```

`take(n)` stops the iterator after `n` items. When `limit` is missing, `unwrap_or(TASKS.len())` uses the total number of tasks, so nothing is cut off. Because `take` comes after `filter`, the limit applies to the search results.

```bash
curl -w "\n" "http://127.0.0.1:3000/tasks?limit=2"
curl -w "\n" "http://127.0.0.1:3000/tasks?search=a&limit=1"
curl -w "\n" "http://127.0.0.1:3000/tasks?limit=two"
```

The `-w "\n"` option prints a newline after each response body, so the three results do not run together on one line.

Output:

```text
<h1>Tasks</h1><ul><li>Learn Rust</li><li>Build a web app</li></ul>
<h1>Tasks</h1><ul><li>Learn Rust</li></ul>
Failed to deserialize query string: limit: invalid digit found in string
```

The third request was rejected with `400 Bad Request` because `two` cannot be parsed as a `usize`. The message names the field that failed.

**Solution for Exercise 2:**

```rust
async fn hello(Path(name): Path<String>) -> String {
    format!("Hello, {name}! You have {} tasks.", TASKS.len())
}
```

Register it in `main`:

```rust
.route("/hello/{name}", get(hello))
```

`Path<String>` accepts any segment as text. Axum decodes the URL encoding, so `%20` arrives as a real space.

```bash
curl "http://127.0.0.1:3000/hello/Ada%20Lovelace"
```

Output:

```text
Hello, Ada Lovelace! You have 3 tasks.
```

**Solution for Exercise 3:**

```rust
#[derive(Deserialize)]
struct NewTask {
    title: String,
    due_date: String,
}
```

```rust
async fn new_task_form() -> Html<&'static str> {
    Html(
        r#"<h1>New Task</h1>
<form method="post" action="/tasks">
  <input name="title" placeholder="What needs to be done?">
  <input name="due_date" type="date">
  <button type="submit">Add</button>
</form>"#,
    )
}
```

```rust
async fn create_task(Form(form): Form<NewTask>) -> Redirect {
    if form.due_date.is_empty() {
        println!("new task received: {} (no due date)", form.title);
    } else {
        println!("new task received: {} (due {})", form.title, form.due_date);
    }
    Redirect::to("/tasks")
}
```

A browser always sends every input of a form, even empty ones, so an empty date input arrives as `due_date=` and becomes an empty `String`. Checking `is_empty()` tells the two cases apart. The browser's date picker sends dates as `YYYY-MM-DD`; in Lesson 11, you will parse that text into a real date type before saving it to MySQL. Test both cases with `curl`, as a browser would send them:

```bash
curl -s -o /dev/null -d "title=Write tests&due_date=2026-11-30" http://127.0.0.1:3000/tasks
curl -s -o /dev/null -d "title=Read docs&due_date=" http://127.0.0.1:3000/tasks
```

Output in the server terminal:

```text
new task received: Write tests (due 2026-11-30)
new task received: Read docs (no due date)
```

---

## Next Up - Lesson 6

In this lesson, you used Axum extractors to read data from requests: `Path` for task IDs, `Query` with an `Option` field for the search filter, and `Form` for submitted titles. You also returned different response types from one handler with `into_response`, and redirected after a `POST` with the Post/Redirect/Get pattern.

Building HTML with `format!` and raw strings is already getting awkward, and it would be easy to forget a closing tag. In Lesson 6, you will move every page into Askama templates: real HTML files with placeholders, loops, and conditions, checked by the compiler, and sharing one base layout so every page of Todo Web has the same look.
