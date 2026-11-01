## 1. Before You Begin

Module 2 gave Todo Web its shape: routes, extractors, and Askama pages. The tasks themselves are still fake, returned by `sample_tasks()`. Module 3 connects the application to the `db_rust_todo` database you created in Lesson 3, and this lesson builds the connection itself.

Three problems need solving. First, the application needs the database address, user, and password, but those must not be written into the source code, where they would end up in Git. Second, opening a MySQL connection is slow, so the application should not log in again for every request. Third, every handler that talks to the database needs access to the connections. You will solve them with a `.env` file read by the dotenvy crate, a SQLx connection pool, and Axum's shared state. At the end, the home page will show the version of the MySQL server it is talking to.

### What You'll Build

Todo Web connected to MySQL: the database URL lives in a `.env` file that Git ignores, `main` creates a pool of up to five connections at startup, and the home page and the `/health` route use the pool through Axum state to run real SQL queries.

### What You'll Learn

- ✅ How a MySQL connection URL is structured
- ✅ How to keep secrets out of source code with a `.env` file and dotenvy
- ✅ What a connection pool is and how to create one with `MySqlPoolOptions`
- ✅ How to share the pool with handlers using `with_state` and the `State` extractor
- ✅ How to run a first query with `sqlx::query_scalar`
- ✅ How to read connection errors and fix the most common ones

### What You'll Need

- The `todo-web` project from Lesson 6
- The `db_rust_todo` database and the `todo_user` account from Lesson 3
- MySQL or MariaDB running

---

## 2. Store the Database URL in a .env File

Database clients usually take their settings as one connection URL. It packs everything needed to connect into a single string, which is easy to store in one setting.

### Step 1: Write the Connection URL

The URL for Todo Web looks like this:

```text
mysql://todo_user:todo_password@localhost:3306/db_rust_todo
```

Read it from left to right:

| Part | Meaning |
| --- | --- |
| `mysql://` | The protocol: talk to a MySQL-compatible server |
| `todo_user:todo_password` | The user name and password, separated by a colon |
| `@localhost` | The host where the server runs |
| `:3306` | The port; 3306 is the MySQL default |
| `/db_rust_todo` | The database to use after logging in |

These are exactly the values from Lesson 3. If your password contains special characters such as `@`, `:`, or `/`, they must be percent-encoded in the URL (for example `@` becomes `%40`); the simplest fix is to choose a password made of letters and numbers for local development.

### Step 2: Create .env and Keep It Out of Git

Create a file named `.env` in the project folder, next to `Cargo.toml`:

```bash
DATABASE_URL=mysql://todo_user:todo_password@localhost:3306/db_rust_todo
```

A `.env` file holds `NAME=value` lines, one setting per line. `DATABASE_URL` is the conventional name, and sqlx-cli in Lesson 8 reads the same variable.

This file contains a password, so it must never be committed. Create a `.gitignore` file in the project folder (or add to the existing one) so Git ignores it, together with the build output:

```text
target/
.env
```

If the project is not a Git repository yet, run `git init` now. From here on, you can commit your work at the end of every lesson. To tell other developers which settings the project needs, teams often commit a `.env.example` file with the same names and placeholder values, which each person copies to `.env` and fills in.

### Step 3: Add dotenvy and SQLx

Add the two crates:

```bash
cargo add dotenvy
cargo add sqlx --features runtime-tokio,mysql
```

dotenvy reads `.env` and puts its lines into the program's environment variables. SQLx is the database library. Like Tokio, it is split into features: `runtime-tokio` tells SQLx to run on Tokio (it supports other runtimes too), and `mysql` enables the MySQL driver. SQLx also has default features that you will use later, such as migrations in Lesson 8 and the `FromRow` derive in Lesson 9. The new lines in `Cargo.toml` are:

```toml
dotenvy = "0.15.7"
sqlx = { version = "0.9.0", features = ["runtime-tokio", "mysql"] }
```

The first build after this takes a while, because SQLx has many dependencies.

---

## 3. Create a Connection Pool

Opening a connection means a network round trip, a login, and some setup on the server. Doing that for every request would make each page slower and put extra load on MySQL. A connection pool opens connections once and keeps them. When a handler needs the database, it borrows a connection from the pool and gives it back as soon as its query is done, so a few connections can serve many requests.

### Step 1: Load the Settings and Connect in main

Add these imports to the `use` section at the top of `src/main.rs`, below `use serde::Deserialize;`:

```rust
use sqlx::MySqlPool;
use sqlx::mysql::MySqlPoolOptions;
```

Then replace `main` with this version:

```rust
#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set in .env");

    let pool = MySqlPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("should connect to MySQL");
    println!("Connected to MySQL");

    let app = Router::new()
        .route("/", get(home))
        .route("/health", get(health))
        .route("/tasks", get(list_tasks).post(create_task))
        .route("/tasks/new", get(new_task_form))
        .route("/tasks/{id}", get(show_task))
        .fallback(not_found)
        .with_state(pool);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    println!("Todo Web running on http://127.0.0.1:3000");

    axum::serve(listener, app).await.expect("server should run");
}
```

Line by line:

- `dotenvy::dotenv()` looks for a `.env` file in the current folder (and its parents) and loads its variables. It returns a `Result`, because the file might not exist. `.ok()` deliberately ignores that error: on a production server, the variables are often set by the system instead of a file, and the program should still work.
- `std::env::var("DATABASE_URL")` reads the variable from the environment. If it is missing, `.expect(...)` stops the program at startup with a clear message. Failing early is good: a server without a database cannot do anything useful, and it is better to find out immediately than on the first request.
- `MySqlPoolOptions::new()` starts configuring a pool. `.max_connections(5)` limits it to five open connections, which is plenty for local development. Each connection uses memory on the MySQL server, so the limit protects the database from being flooded.
- `.connect(&database_url).await` creates the pool and opens a first connection to check that the URL works. It is async because it talks over the network. If the server is down or the password is wrong, `.expect(...)` stops the program with the database's error message.
- `.with_state(pool)` at the end of the router stores the pool as shared state. Every handler can now ask for it.

### Step 2: Use the Pool in Handlers

Add `State` to the `extract` import:

```rust
    extract::{Path, Query, State},
```

Then replace the `home` and `health` handlers with these versions:

```rust
async fn home(State(pool): State<MySqlPool>) -> Response {
    let pending = sample_tasks().iter().filter(|task| !task.done).count();
    let db_version = match sqlx::query_scalar("SELECT VERSION()").fetch_one(&pool).await {
        Ok(version) => version,
        Err(err) => format!("unavailable ({err})"),
    };
    render(HomeTemplate { pending, db_version })
}

async fn health(State(pool): State<MySqlPool>) -> (StatusCode, String) {
    match sqlx::query_scalar::<_, i32>("SELECT 1").fetch_one(&pool).await {
        Ok(_) => (StatusCode::OK, String::from("ok: database reachable")),
        Err(err) => (StatusCode::SERVICE_UNAVAILABLE, format!("database error: {err}")),
    }
}
```

Here is what is new:

- `State(pool): State<MySqlPool>` is another extractor. Instead of reading from the request, it gives the handler a copy of the state you passed to `with_state`. `MySqlPool` is cheap to copy: it is a handle pointing to the same shared pool, so every handler uses the same connections.
- `sqlx::query_scalar("SELECT VERSION()")` prepares a query that returns a single value, a scalar. `VERSION()` is a MySQL function that returns the server version as text.
- `.fetch_one(&pool).await` borrows a connection from the pool, runs the query, expects exactly one row, and returns the connection to the pool. It returns a `Result`, because the database can fail.
- In `home`, the type of `version` is inferred from the `db_version` field of the template, which is a `String`. If the query fails, the page still renders and shows the error instead of the version.
- In `health`, `query_scalar::<_, i32>` states the result type explicitly with turbofish syntax, because the value is ignored (`Ok(_)`) and Rust could not infer it otherwise. The `_` is the database type, which SQLx infers from the pool. `SELECT 1` is the classic cheap query for checking that a database answers. If it fails, the handler returns `503 Service Unavailable`, which tells monitoring tools that the application is up but cannot do its job.

### Step 3: Show the Version on the Home Page

Add the new field to `HomeTemplate`:

```rust
#[derive(Template)]
#[template(path = "home.html")]
struct HomeTemplate {
    pending: usize,
    db_version: String,
}
```

And print it in `templates/home.html`:

```html
{% extends "base.html" %}

{% block content %}
<h1>Todo Web</h1>
<p>Your tasks, now in the browser. You have {{ pending }} unfinished tasks.</p>
<p>Database: {{ db_version }}</p>
{% endblock %}
```

The other handlers do not use the pool yet, and that is fine: a handler only receives the state if it asks for it with a `State` extractor.

---

## 4. Run and Test

Start the server:

```bash
cargo run
```

Output:

```text
Connected to MySQL
Todo Web running on http://127.0.0.1:3000
```

`Connected to MySQL` proves that the URL from `.env` was loaded and the login succeeded, before the server even started listening.

### Step 1: Check the Home Page

In a second terminal, fetch the home page. The `sed` command prints only the lines between `<main>` and `</main>`, so you do not have to scroll through the whole layout:

```bash
curl -s http://127.0.0.1:3000/ | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Todo Web</h1>
<p>Your tasks, now in the browser. You have 2 unfinished tasks.</p>
<p>Database: 11.8.6-MariaDB-5ubuntu0.1 from Ubuntu</p>

  </main>
```

The version string came from the MySQL server through the pool. Yours depends on what you installed; MySQL 8 shows something like `8.0.x` instead.

### Step 2: Check the Health Route

```bash
curl -i http://127.0.0.1:3000/health
```

Output:

```text
HTTP/1.1 200 OK
content-type: text/plain; charset=utf-8
content-length: 22
date: Sun, 01 Nov 2026 16:53:52 GMT

ok: database reachable
```

Open `http://127.0.0.1:3000` in the browser as well; the database version appears below the task count. Stop the server with `Ctrl+C`.

### Step 3: Commit Your Work

Check that `.env` is really ignored before you commit:

```bash
git status --short
```

The list should include `.gitignore`, `Cargo.toml`, `Cargo.lock`, `src/main.rs`, and `templates/home.html`, but not `.env`. Then commit:

```bash
git add -A
git commit -m "lesson 7: config and connection pool"
```

---

## 5. How the Pool and State Work Together

You have now seen every piece of a database-backed Axum application. Here is what happens during one request to the home page:

```text
startup:   .env --dotenvy--> DATABASE_URL --> MySqlPool (up to 5 connections) --> with_state
request:   GET /  -->  home(State(pool))
                         |
                         +-- pool: borrow an idle connection (or open a new one, up to 5)
                         +-- send "SELECT VERSION()" and wait for the row (.await)
                         +-- return the connection to the pool
                         |
                         v
                       render(HomeTemplate { ... })  -->  HTML response
```

Some details that matter as the application grows:

- **The pool grows on demand.** At startup, it opens one connection to test the URL. When several requests need the database at the same moment, it opens more, up to `max_connections`.
- **Waiting is async.** If all five connections are busy, the next query waits for one to be returned. Because the wait is an `.await`, the server keeps serving other requests in the meantime, exactly as you saw with `tokio::time::sleep` in Lesson 2.
- **Clones share the same pool.** Axum clones the state for every request. Cloning a `MySqlPool` only copies a handle, never the connections themselves.
- **Connections close when unused.** By default, SQLx closes connections that sit idle for a long time and replaces connections that become too old, so a server that runs for weeks stays healthy.
- **State is typed.** The router's state type is `MySqlPool`, so `State<MySqlPool>` is the only state extractor that compiles. In Lesson 17, you will replace it with an `AppState` struct that can hold more shared resources.

---

## 6. Fix the Errors in Your Code

**Error 1: The .env file is missing or in the wrong folder**

```text
# Wrong: .env saved inside src/ or with a different name such as env.txt
todo-web/src/.env
```

```text
# Correct: .env next to Cargo.toml
todo-web/.env
```

If dotenvy cannot find the file, `DATABASE_URL` is not set, and the program stops at startup:

```text
thread 'main' (34395) panicked at src/main.rs:132:54:
DATABASE_URL must be set in .env: NotPresent
```

`NotPresent` means the variable does not exist in the environment. Check that the file is named exactly `.env`, that it sits in the folder where you run `cargo run`, and that the line starts with `DATABASE_URL=` without spaces around the `=`.

**Error 2: Wrong credentials in the URL**

```bash
# Wrong
DATABASE_URL=mysql://todo_user:wrong@localhost:3306/db_rust_todo
```

```bash
# Correct
DATABASE_URL=mysql://todo_user:todo_password@localhost:3306/db_rust_todo
```

The pool cannot log in, so `connect` fails and the program stops:

```text
thread 'main' (34406) panicked at src/main.rs:138:10:
should connect to MySQL: Database(MySqlDatabaseError { code: Some("28000"), number: 1045, message: "Access denied for user 'todo_user'@'localhost' (using password: YES)" })
```

Inside the debug output, you can recognize error 1045 from Lesson 3. SQLx passes MySQL's own error number and message through, so everything you learned about MySQL errors in the `mysql` client applies here. A test that rules out Rust completely: log in with `mysql -u todo_user -p` using the same values. If that fails too, the problem is the account or the password, not your code. If the error mentions `Connection refused` instead, the database server is not running.

**Error 3: Forgetting `with_state`**

```rust
// Wrong
        .fallback(not_found);
```

```rust
// Correct
        .fallback(not_found)
        .with_state(pool);
```

When handlers use `State<MySqlPool>`, the router knows it needs a `MySqlPool`, and it is not complete until one is provided. Without `with_state`, `axum::serve` refuses it:

```text
error[E0277]: the trait bound `Router<Pool<MySql>>: Service<IncomingStream<'a, TcpListener>>` is not satisfied
   --> src/main.rs:154:27
    |
154 |     axum::serve(listener, app).await.expect("server should run");
    |     -----------           ^^^ the trait `for<'a> tower_service::Service<IncomingStream<'a, tokio::net::TcpListener>>` is not implemented for `Router<Pool<MySql>>`
```

The important part is the type `Router<Pool<MySql>>`: a router that still waits for a `Pool<MySql>` (the full name of `MySqlPool`). Only a `Router<()>`, a router with nothing missing, can be served. Adding `.with_state(pool)` turns one into the other.

---

## 7. Exercises

**Exercise 1:** Extend `/health` so the success message also reports how many connections the pool has open and how many are idle, for example `ok: database reachable, 1 connections open, 0 idle`. Look for the methods `size()` and `num_idle()` on the pool.

**Exercise 2:** Make the listening address configurable. Read an optional `APP_ADDR` variable and fall back to `127.0.0.1:3000` when it is not set. Test it by adding `APP_ADDR=127.0.0.1:8080` to `.env`, then remove the line again.

**Exercise 3:** Add a `GET /whoami` route that runs `SELECT DATABASE(), CURRENT_USER()` and returns `database: <name>, user: <user>`. A query that returns two columns does not fit `query_scalar`; use `sqlx::query_as` and read the row into a tuple `(String, String)`. Return `Result<String, (StatusCode, String)>` from the handler and use `map_err` with `?` to turn a database error into a `500` response.

---

## 8. Solutions

**Solution for Exercise 1:**

```rust
async fn health(State(pool): State<MySqlPool>) -> (StatusCode, String) {
    match sqlx::query_scalar::<_, i32>("SELECT 1").fetch_one(&pool).await {
        Ok(_) => (
            StatusCode::OK,
            format!(
                "ok: database reachable, {} connections open, {} idle",
                pool.size(),
                pool.num_idle()
            ),
        ),
        Err(err) => (StatusCode::SERVICE_UNAVAILABLE, format!("database error: {err}")),
    }
}
```

`size()` counts every open connection, busy or idle, and `num_idle()` counts the ones waiting in the pool.

```bash
curl -w "\n" http://127.0.0.1:3000/health
```

Output:

```text
ok: database reachable, 1 connections open, 0 idle
```

There is one open connection, the one created at startup. It shows as not idle because the numbers are read right after the `SELECT 1` query, before SQLx has finished returning that connection to the pool in the background. A single connection is enough because the requests arrive one at a time; the pool only opens more when queries overlap.

**Solution for Exercise 2:**

In `main`, replace the listener lines with:

```rust
    let address = std::env::var("APP_ADDR").unwrap_or_else(|_| String::from("127.0.0.1:3000"));
    let listener = tokio::net::TcpListener::bind(&address)
        .await
        .expect("address should be free");
    println!("Todo Web running on http://{address}");
```

`std::env::var` returns a `Result`, and `unwrap_or_else` supplies a default when the variable is missing. The closure only runs in that case, so the default `String` is only created when needed. Because dotenvy has already loaded `.env`, `APP_ADDR` from the file is visible here too. With `APP_ADDR=127.0.0.1:8080` in `.env`, `cargo run` prints:

```text
Connected to MySQL
Todo Web running on http://127.0.0.1:8080
```

Remove the line from `.env` afterwards so the rest of the course can keep using port 3000.

**Solution for Exercise 3:**

```rust
async fn whoami(State(pool): State<MySqlPool>) -> Result<String, (StatusCode, String)> {
    let (database, user): (String, String) =
        sqlx::query_as("SELECT DATABASE(), CURRENT_USER()")
            .fetch_one(&pool)
            .await
            .map_err(|err| (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()))?;
    Ok(format!("database: {database}, user: {user}"))
}
```

Register the route in `main`:

```rust
.route("/whoami", get(whoami))
```

`query_as` maps each row into a type; a tuple works out of the box, with one element per column in order. The type annotation `(String, String)` tells SQLx what to decode. `map_err` converts the `sqlx::Error` into the handler's error type, a tuple of a status code and a message, and `?` returns it early if the query fails. Axum accepts `Result<T, E>` as a handler return type whenever both `T` and `E` implement `IntoResponse`, which is the pattern you will build on in Lesson 14.

```bash
curl -w "\n" http://127.0.0.1:3000/whoami
```

Output:

```text
database: db_rust_todo, user: todo_user@localhost
```

---

## Next Up - Lesson 8

In this lesson, you moved the database URL into a `.env` file that Git ignores, loaded it with dotenvy, created a SQLx connection pool in `main`, and shared it with handlers through `with_state` and the `State` extractor. The home page and `/health` now run real queries against MySQL.

The database is still empty, though. In Lesson 8, you will install sqlx-cli and use migrations to create the `tasks` table: versioned SQL files that build the schema step by step, can be undone, and run automatically when Todo Web starts, so every copy of the application always has the tables it expects.
