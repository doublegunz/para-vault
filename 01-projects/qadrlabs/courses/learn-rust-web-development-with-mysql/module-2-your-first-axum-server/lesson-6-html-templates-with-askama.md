## 1. Before You Begin

In Lesson 5, your handlers read paths, query strings, and forms, but they still built their HTML with `format!` and raw strings. That works for one line of markup. It does not work for real pages: every page needs the same `<head>` and navigation, HTML mixed into Rust strings is hard to read, and it is easy to forget a closing tag or a quote. There is also a security problem. If a user types `<script>` into the search box and your code pastes it into the page unchanged, the browser runs it.

Askama solves all of this. You write each page as an HTML file with placeholders, loops, and conditions, and you connect it to a Rust struct that holds the data. At compile time, Askama turns the template into Rust code, so a typo in a variable name is a compiler error, not a broken page in production. Every value is HTML-escaped automatically. Templates can also inherit from a base layout, so the shared parts of every page are written once.

### What You'll Build

Todo Web with real HTML pages: a base layout with a navigation bar, a home page that counts unfinished tasks, a task list with a search form, a detail page for each task, a "new task" page, and a templated 404 page. The tasks become a `Task` struct with an ID, a title, and a done flag, which is the shape they will have in MySQL.

### What You'll Learn

- ✅ How to add Askama and where template files live
- ✅ How to connect a template to a struct with `#[derive(Template)]`
- ✅ How to print values with `{{ }}` and use `{% if %}` and `{% for %}` in templates
- ✅ How to share a layout with `{% extends %}` and `{% block %}`
- ✅ How to render a template in an Axum handler and handle render errors
- ✅ Why automatic HTML escaping matters

### What You'll Need

- The `todo-web` project from Lesson 5
- Basic HTML: headings, links, lists, and forms

---

## 2. Add Askama and Create the Base Layout

Askama looks for templates in a folder named `templates` next to `Cargo.toml`. Every page will extend one base template, so that is the first file to write.

### Step 1: Add the Crate and the Folders

In the `todo-web` folder, run:

```bash
cargo add askama
mkdir -p templates/tasks
```

The `templates/tasks` subfolder keeps the task pages together. Your project now looks like this:

```text
todo-web/
├── Cargo.toml
├── src/
│   └── main.rs
└── templates/
    └── tasks/
```

### Step 2: Write the Base Template

Create `templates/base.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{% block title %}Todo Web{% endblock %}</title>
</head>
<body>
  <nav>
    <a href="/">Home</a> |
    <a href="/tasks">Tasks</a> |
    <a href="/tasks/new">New task</a>
  </nav>
  <main>
    {% block content %}{% endblock %}
  </main>
</body>
</html>
```

This is ordinary HTML with two blocks. `{% block title %}Todo Web{% endblock %}` defines a block named `title` with default content: pages that do not override it get the title "Todo Web." `{% block content %}{% endblock %}` is an empty block that every page fills with its own content. Tags written as `{% ... %}` are template instructions; they never appear in the output.

---

## 3. Write the Page Templates

Each page template starts with `{% extends "base.html" %}` and then fills the blocks it needs. Everything outside a block in a child template is ignored, so the whole page lives inside blocks.

### Step 1: The Home Page

Create `templates/home.html`:

```html
{% extends "base.html" %}

{% block content %}
<h1>Todo Web</h1>
<p>Your tasks, now in the browser. You have {{ pending }} unfinished tasks.</p>
{% endblock %}
```

`{{ pending }}` prints the value of a field named `pending` from the Rust struct you will connect to this template. Double braces are for output; `{% %}` is for logic.

### Step 2: The Task List

Create `templates/tasks/list.html`:

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
      </li>
    {% endfor %}
  </ul>
{% endif %}
{% endblock %}
```

Here is what each part does:

- `{% block title %}` overrides the default title, so the browser tab shows "Tasks - Todo Web."
- The search form uses `method="get"`, so submitting it simply loads `/tasks?search=...`, which your `Query` extractor from Lesson 5 already understands. `value="{{ search }}"` puts the current search term back into the box, so the user can see what they searched for.
- `{% if tasks.is_empty() %}` calls a real Rust method on the `tasks` field. Askama templates can call methods and access fields, because they are compiled into Rust code.
- `{% for task in tasks %} ... {% endfor %}` repeats its content once for each task, just like a Rust `for` loop.
- `{% if task.done %}[x]{% else %}[ ]{% endif %}` shows a checkbox-like marker, the same style as the command-line to-do list.
- `{{ task.id }}` builds a link to the detail page, such as `/tasks/2`.

### Step 3: The Detail, New Task, and Not Found Pages

Create `templates/tasks/show.html`:

```html
{% extends "base.html" %}

{% block title %}{{ task.title }} - Todo Web{% endblock %}

{% block content %}
<h1>{{ task.title }}</h1>
<p>Status: {% if task.done %}done{% else %}not done{% endif %}</p>
<p><a href="/tasks">Back to all tasks</a></p>
{% endblock %}
```

The title block uses a value too, so each task page has its own browser tab title. Create `templates/tasks/new.html`:

```html
{% extends "base.html" %}

{% block title %}New Task - Todo Web{% endblock %}

{% block content %}
<h1>New Task</h1>
<form method="post" action="/tasks">
  <input name="title" placeholder="What needs to be done?">
  <button type="submit">Add</button>
</form>
{% endblock %}
```

This is the form from Lesson 5, moved into a template. Finally, create `templates/not_found.html`:

```html
{% extends "base.html" %}

{% block title %}Not Found - Todo Web{% endblock %}

{% block content %}
<h1>404</h1>
<p>{{ message }}</p>
{% endblock %}
```

The message is a variable, so the same template can say "That task does not exist" or "The page you are looking for does not exist."

---

## 4. Connect the Templates to Rust

A template on its own does nothing. Each one is connected to a struct whose fields provide the template's variables, and the `Template` derive generates a `render()` method that produces the final HTML.

### Step 1: Define the Task Struct and Sample Data

Replace `src/main.rs` piece by piece, starting with the imports, the `Task` struct, and some sample data. The `use` block now includes `askama::Template`:

```rust
use askama::Template;
use axum::{
    Form, Router,
    extract::{Path, Query},
    http::StatusCode,
    response::{Html, IntoResponse, Redirect, Response},
    routing::get,
};
use serde::Deserialize;

struct Task {
    id: u64,
    title: String,
    done: bool,
}

fn sample_tasks() -> Vec<Task> {
    vec![
        Task { id: 1, title: String::from("Learn Rust"), done: true },
        Task { id: 2, title: String::from("Build a web app"), done: false },
        Task { id: 3, title: String::from("Connect to MySQL"), done: false },
    ]
}
```

The `TASKS` constant from Lesson 5 is gone. Tasks now have an `id`, a `title`, and a `done` flag, which is exactly the shape of the `tasks` table you will create in Lesson 8. `sample_tasks()` returns a fresh vector every time it is called, standing in for a database query until Lesson 10. The `id` is a `u64` because MySQL IDs will be unsigned 64-bit numbers.

### Step 2: Define One Struct per Template

Add the template structs below `sample_tasks`, followed by the two extractor structs from Lesson 5:

```rust
#[derive(Template)]
#[template(path = "home.html")]
struct HomeTemplate {
    pending: usize,
}

#[derive(Template)]
#[template(path = "tasks/list.html")]
struct TaskListTemplate {
    tasks: Vec<Task>,
    search: String,
}

#[derive(Template)]
#[template(path = "tasks/show.html")]
struct TaskShowTemplate {
    task: Task,
}

#[derive(Template)]
#[template(path = "tasks/new.html")]
struct NewTaskTemplate;

#[derive(Template)]
#[template(path = "not_found.html")]
struct NotFoundTemplate {
    message: String,
}

#[derive(Deserialize)]
struct TaskFilter {
    search: Option<String>,
}

#[derive(Deserialize)]
struct NewTask {
    title: String,
}
```

Each template struct follows the same pattern:

- `#[derive(Template)]` asks Askama to generate rendering code for this struct.
- `#[template(path = "...")]` names the template file, relative to the `templates` folder.
- The fields are the variables the template can use. `HomeTemplate` has `pending`, so `home.html` can print `{{ pending }}`. `TaskListTemplate` has `tasks` and `search`, which `list.html` uses.
- `NewTaskTemplate` is a unit struct with no fields, because the form page needs no data.

Askama reads the template files while compiling. If a template uses a variable the struct does not have, compilation fails, as you will see in Section 7.

### Step 3: Add Render Helpers

Add two helper functions below the structs:

```rust
fn render<T: Template>(template: T) -> Response {
    match template.render() {
        Ok(html) => Html(html).into_response(),
        Err(err) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("template error: {err}"),
        )
            .into_response(),
    }
}

fn not_found_page(message: &str) -> Response {
    let page = NotFoundTemplate { message: message.to_string() };
    (StatusCode::NOT_FOUND, render(page)).into_response()
}
```

Line by line:

- `fn render<T: Template>(template: T) -> Response` is a generic function from the first course: it accepts any type that implements the `Template` trait.
- `template.render()` produces the HTML as a `Result<String, askama::Error>`. Rendering can fail at runtime in rare cases, for example when a custom filter returns an error, so the result must be handled.
- On success, the HTML is wrapped in `Html` so the browser receives `text/html`. On failure, the user gets a `500 Internal Server Error` with a short message. In Lesson 14, you will replace this with a proper error type.
- `not_found_page` renders the 404 template and combines it with `StatusCode::NOT_FOUND`. A tuple of a status code and a `Response` is itself a valid response, so the status overrides the `200` that `render` would normally use.

### Step 4: Rewrite the Handlers

Replace all the handlers and `main` with these versions:

```rust
async fn home() -> Response {
    let pending = sample_tasks().iter().filter(|task| !task.done).count();
    render(HomeTemplate { pending })
}

async fn health() -> (StatusCode, &'static str) {
    (StatusCode::OK, "ok")
}

async fn list_tasks(Query(filter): Query<TaskFilter>) -> Response {
    let search = filter.search.unwrap_or_default();
    let needle = search.to_lowercase();
    let tasks = sample_tasks()
        .into_iter()
        .filter(|task| task.title.to_lowercase().contains(&needle))
        .collect();
    render(TaskListTemplate { tasks, search })
}

async fn show_task(Path(id): Path<u64>) -> Response {
    match sample_tasks().into_iter().find(|task| task.id == id) {
        Some(task) => render(TaskShowTemplate { task }),
        None => not_found_page("That task does not exist."),
    }
}

async fn new_task_form() -> Response {
    render(NewTaskTemplate)
}

async fn create_task(Form(form): Form<NewTask>) -> Redirect {
    println!("new task received: {}", form.title);
    Redirect::to("/tasks")
}

async fn not_found() -> Response {
    not_found_page("The page you are looking for does not exist.")
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(home))
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

Here is what changed:

- Every page handler now returns `Response` and builds a template struct. The HTML lives in the template files; the handlers only prepare data.
- `home` counts the unfinished tasks with `filter` and `count`.
- `list_tasks` keeps the original `search` text for the template (so the box shows exactly what the user typed) and uses a lowercase copy, `needle`, for matching. `into_iter()` takes ownership of the sample tasks, so the filtered `Task` values can be moved into the template without cloning. `collect()` knows to build a `Vec<Task>` because that is the type of the `tasks` field.
- `show_task` now takes `Path<u64>` and uses `find` to search by ID instead of by position.
- The `/about` route is gone for now; you will bring it back as a templated page in Exercise 3.
- `main` is unchanged apart from the routes.

---

## 5. Run and Test

Start the server:

```bash
cargo run
```

Output:

```text
Todo Web running on http://127.0.0.1:3000
```

### Step 1: Check the Home Page

In a second terminal, request the home page:

```bash
curl http://127.0.0.1:3000/
```

Output:

```text
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Todo Web</title>
</head>
<body>
  <nav>
    <a href="/">Home</a> |
    <a href="/tasks">Tasks</a> |
    <a href="/tasks/new">New task</a>
  </nav>
  <main>
    
<h1>Todo Web</h1>
<p>Your tasks, now in the browser. You have 2 unfinished tasks.</p>

  </main>
</body>
</html>
```

The base layout and the home page were merged: the navigation comes from `base.html`, the content from `home.html`, and the title kept its default because `home.html` does not override it. The empty lines come from the template tags; browsers ignore this whitespace.

### Step 2: Check the Task List and Search

```bash
curl http://127.0.0.1:3000/tasks
```

Output:

```text
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Tasks - Todo Web</title>
</head>
<body>
  <nav>
    <a href="/">Home</a> |
    <a href="/tasks">Tasks</a> |
    <a href="/tasks/new">New task</a>
  </nav>
  <main>
    
<h1>Tasks</h1>

<form method="get" action="/tasks">
  <input name="search" value="" placeholder="Search tasks">
  <button type="submit">Search</button>
</form>


  <ul>
    
      <li>
        [x]
        <a href="/tasks/1">Learn Rust</a>
      </li>
    
      <li>
        [ ]
        <a href="/tasks/2">Build a web app</a>
      </li>
    
      <li>
        [ ]
        <a href="/tasks/3">Connect to MySQL</a>
      </li>
    
  </ul>


  </main>
</body>
</html>
```

The `for` loop produced one `<li>` per task, and the `if` inside it printed `[x]` only for the finished task.

### Step 3: See Automatic Escaping

Now search for something that contains HTML tags. In a URL, `<` is written as `%3C` and `>` as `%3E`, so this request searches for the text `<b>zzz</b>`:

```bash
curl "http://127.0.0.1:3000/tasks?search=%3Cb%3Ezzz%3C/b%3E"
```

Output:

```text
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Tasks - Todo Web</title>
</head>
<body>
  <nav>
    <a href="/">Home</a> |
    <a href="/tasks">Tasks</a> |
    <a href="/tasks/new">New task</a>
  </nav>
  <main>
    
<h1>Tasks</h1>

<form method="get" action="/tasks">
  <input name="search" value="&#60;b&#62;zzz&#60;/b&#62;" placeholder="Search tasks">
  <button type="submit">Search</button>
</form>


  <p>No tasks found.</p>


  </main>
</body>
</html>
```

Two things happened. No task matched, so the `{% if tasks.is_empty() %}` branch showed "No tasks found." More importantly, look at the `value` attribute: `<` became `&#60;` and `>` became `&#62;`. These are HTML entities, which the browser displays as the characters `<` and `>` but never treats as tags. Askama escaped the user's input automatically. If it had not, a user could put a `<script>` tag into a link and send it to someone else, and that script would run in the victim's browser. This attack is called cross-site scripting (XSS), and with Askama you are protected by default.

### Step 4: Check the Detail and 404 Pages

```bash
curl -i http://127.0.0.1:3000/tasks/1
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 360
date: Sun, 01 Nov 2026 16:50:44 GMT

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Learn Rust - Todo Web</title>
</head>
<body>
  <nav>
    <a href="/">Home</a> |
    <a href="/tasks">Tasks</a> |
    <a href="/tasks/new">New task</a>
  </nav>
  <main>
    
<h1>Learn Rust</h1>
<p>Status: done</p>
<p><a href="/tasks">Back to all tasks</a></p>

  </main>
</body>
</html>
```

```bash
curl -i http://127.0.0.1:3000/tasks/7
```

Output:

```text
HTTP/1.1 404 Not Found
content-type: text/html; charset=utf-8
content-length: 319
date: Sun, 01 Nov 2026 16:50:44 GMT

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Not Found - Todo Web</title>
</head>
<body>
  <nav>
    <a href="/">Home</a> |
    <a href="/tasks">Tasks</a> |
    <a href="/tasks/new">New task</a>
  </nav>
  <main>
    
<h1>404</h1>
<p>That task does not exist.</p>

  </main>
</body>
</html>
```

The status is `404`, and the body is a full page with the navigation, so the user can find their way back.

### Step 5: Click Through in the Browser

Open `http://127.0.0.1:3000` and use the navigation links. Search for `rust` on the task list page: the result appears, and the search box keeps your text. Click a task to open its detail page, and watch the browser tab title change. The "New task" page still submits to `POST /tasks` and redirects back, as in Lesson 5. Stop the server with `Ctrl+C`.

---

## 6. Template Syntax Reference

Here are the template features you used, plus a few you will need later in the course:

| Syntax | Meaning |
| --- | --- |
| `{{ value }}` | Print a value, HTML-escaped |
| `{{ task.title }}` | Print a field |
| `{{ tasks.len() }}` | Call a method and print the result |
| `{% if cond %} ... {% else %} ... {% endif %}` | Conditional content |
| `{% for item in items %} ... {% endfor %}` | Repeat content for each item |
| `{{ loop.index }}` | The current loop iteration, starting at 1 (inside `for`) |
| `{% extends "base.html" %}` | Inherit from a base template |
| `{% block name %} ... {% endblock %}` | Define or override a block |
| `{% if let Some(x) = value %}` | Match an `Option`, just like Rust |
| `{{ value\|safe }}` | Print without escaping; only for HTML you produced yourself |

A few important properties of Askama:

- **Templates are compiled into your binary.** The `templates` folder is read when you build, not when the server runs. After changing a template, run `cargo run` again to see the change. The release binary in Lesson 19 does not need the `templates` folder at all.
- **Templates are type-checked.** A misspelled variable, a missing field, or a method that does not exist is a compiler error.
- **Escaping is on by default for `.html` files.** Use the `safe` filter only for content you generated and trust, never for user input.

---

## 7. Fix the Errors in Your Code

**Error 1: A misspelled variable in a template**

```html
<!-- Wrong: templates/tasks/show.html -->
<h1>{{ task.titel }}</h1>
```

```html
<!-- Correct -->
<h1>{{ task.title }}</h1>
```

Because Askama compiles templates into Rust, this typo is caught by the compiler:

```text
error[E0609]: no field `titel` on type `Task`
  --> src/main.rs:38:10
   |
38 | #[derive(Template)]
   |          ^^^^^^^^ unknown field
   |
   = note: this error originates in the derive macro `Template` (in Nightly builds, run with -Z macro-backtrace for more info)
```

The error points at the `#[derive(Template)]` line in Rust, not at the template file, because that is where the generated code lives. Look at the struct below the highlighted line to find the template (`tasks/show.html`), then search it for the name in the message (`titel`).

**Error 2: A wrong template path**

```rust
// Wrong
#[template(path = "task/show.html")]
```

```rust
// Correct
#[template(path = "tasks/show.html")]
```

If the file does not exist, the build fails with `error: template "task/show.html" not found in directories`, followed by the full path of your `templates` folder, and the wrong path in the attribute is underlined. Paths are relative to the `templates` folder, so do not start them with `templates/`. Also check that the folder sits next to `Cargo.toml`, not inside `src/`.

**Error 3: Forgetting to import the Template trait**

```rust
// Wrong: the use line is missing
#[derive(Template)]
#[template(path = "home.html")]
struct HomeTemplate {
    pending: usize,
}
```

```rust
// Correct
use askama::Template;

#[derive(Template)]
#[template(path = "home.html")]
struct HomeTemplate {
    pending: usize,
}
```

Without the import, Rust does not know what `Template` means:

```text
error: cannot find derive macro `Template` in this scope
  --> src/main.rs:25:10
   |
25 | #[derive(Template)]
   |          ^^^^^^^^

error: cannot find attribute `template` in this scope
  --> src/main.rs:26:3
   |
26 | #[template(path = "home.html")]
   |   ^^^^^^^^
```

The same pair of errors repeats for every template struct. `use askama::Template;` brings in both the derive macro and the trait that provides `render()`.

---

## 8. Exercises

**Exercise 1:** On the task list page, show a line such as `3 tasks found.` above the list. Use the `len()` method of the `tasks` vector inside the template, and do not add a new struct field.

**Exercise 2:** Number the tasks in the list (`1.`, `2.`, `3.`) using `loop.index` inside the `for` loop. Search for `build` and check that the single result is numbered `1.`, not `2.`.

**Exercise 3:** Bring back the about page as a template. Create `templates/about.html` that extends the base layout, sets the title to `About - Todo Web`, and shows a short description plus the version from `Cargo.toml`. Add an `AboutTemplate` struct with a `version: &'static str` field, an `about` handler, the `/about` route, and an "About" link in the navigation of `base.html`.

---

## 9. Solutions

**Solution for Exercise 1 and Exercise 2:**

Both changes are inside the `{% else %}` branch of `templates/tasks/list.html`:

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
  <p>{{ tasks.len() }} tasks found.</p>
  <ul>
    {% for task in tasks %}
      <li>
        {{ loop.index }}.
        {% if task.done %}[x]{% else %}[ ]{% endif %}
        <a href="/tasks/{{ task.id }}">{{ task.title }}</a>
      </li>
    {% endfor %}
  </ul>
{% endif %}
{% endblock %}
```

`{{ tasks.len() }}` calls `Vec::len` on the template's field, so no extra field is needed. `loop.index` counts the iterations of the current loop starting at 1 (use `loop.index0` to start at 0). It counts positions in the list being rendered, not task IDs, so a search result always starts at `1.`. Rebuild and run, then search:

```bash
curl "http://127.0.0.1:3000/tasks?search=build"
```

The part of the output inside `<main>`:

```text
  <p>1 tasks found.</p>
  <ul>
    
      <li>
        1.
        [ ]
        <a href="/tasks/2">Build a web app</a>
      </li>
    
  </ul>
```

The task with ID 2 is shown as number `1.`. You may want to write "1 task" instead of "1 tasks"; you could do that with an `{% if tasks.len() == 1 %}` condition.

**Solution for Exercise 3:**

Create `templates/about.html`:

```html
{% extends "base.html" %}

{% block title %}About - Todo Web{% endblock %}

{% block content %}
<h1>About Todo Web</h1>
<p>Todo Web is the web version of the command-line to-do list.</p>
<p>Version {{ version }}</p>
{% endblock %}
```

Add the struct and the handler to `src/main.rs`:

```rust
#[derive(Template)]
#[template(path = "about.html")]
struct AboutTemplate {
    version: &'static str,
}
```

```rust
async fn about() -> Response {
    render(AboutTemplate { version: env!("CARGO_PKG_VERSION") })
}
```

Register the route in `main`:

```rust
.route("/about", get(about))
```

Finally, add the link to the navigation in `templates/base.html`:

```html
  <nav>
    <a href="/">Home</a> |
    <a href="/tasks">Tasks</a> |
    <a href="/tasks/new">New task</a> |
    <a href="/about">About</a>
  </nav>
```

Template fields can be any type that can be displayed, including `&'static str`. Because the navigation lives in the base template, the new link appears on every page at once, which is the main benefit of template inheritance.

```bash
curl http://127.0.0.1:3000/about
```

Output:

```text
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>About - Todo Web</title>
</head>
<body>
  <nav>
    <a href="/">Home</a> |
    <a href="/tasks">Tasks</a> |
    <a href="/tasks/new">New task</a> |
    <a href="/about">About</a>
  </nav>
  <main>
    
<h1>About Todo Web</h1>
<p>Todo Web is the web version of the command-line to-do list.</p>
<p>Version 0.1.0</p>

  </main>
</body>
</html>
```

---

## Next Up - Lesson 7

In this lesson, you moved every page of Todo Web into Askama templates. You built a base layout with blocks, printed values with `{{ }}`, used `if` and `for` in templates, connected each template to a struct, and saw automatic escaping protect the search box from injected HTML. You also introduced the `Task` struct that the database will soon fill.

The sample tasks are still hard-coded in `sample_tasks()`. Module 3 connects Todo Web to MySQL. In Lesson 7, you will store the database URL in a `.env` file, load it with dotenvy, create a SQLx connection pool, and share that pool with every handler through Axum state, then prove the connection works by showing the MySQL version on a page.
