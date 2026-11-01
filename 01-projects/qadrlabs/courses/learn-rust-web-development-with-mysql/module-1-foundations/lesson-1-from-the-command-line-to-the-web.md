## 1. Before You Begin

At the end of "Learn Rust for Beginners," you built a command-line to-do list. It parsed commands into an enum, kept tasks in a `TodoList` struct, saved them to a text file, and had unit tests guarding the logic. That is a real program, but it has clear limits: only one person can use it, only from the terminal where it runs, and all the data lives in one plain text file that is easy to break and hard to search.

This course removes those limits. Over nineteen lessons, you will rebuild the to-do list as a web application: people open it in a browser, the server is written in Rust, and the tasks are stored in a MySQL database. Before you install any crates, this lesson builds the mental model that every later lesson relies on. You will write a tiny web server using only the Rust standard library, look at the raw text a browser sends and the raw text a server answers with, and then map out the tools and the application you will build in the rest of the course.

### What You'll Build

A minimal HTTP server, written with `std::net` and no external crates, that listens on port 3000, prints every incoming request to the terminal, and answers with a small HTML page listing two tasks. You will test it with `curl` and with your browser.

### What You'll Learn

- ✅ How a web application differs from a command-line application
- ✅ What an HTTP request and an HTTP response look like as plain text
- ✅ How a server listens on a port and handles connections with `TcpListener`
- ✅ Why web applications store data in a database instead of a text file
- ✅ The role of each crate in this course: Tokio, Axum, SQLx, Askama, and serde
- ✅ The features of the to-do web app you will build, lesson by lesson

### What You'll Need

- Everything from "Learn Rust for Beginners," especially structs, `Result`, iterators, and closures
- Ubuntu (or another Linux distribution) with Rust and Cargo installed
- `curl`, which is installed on most Linux systems (`sudo apt install curl` if it is missing)
- A web browser

---

## 2. Build a Tiny Web Server with the Standard Library

Frameworks such as Axum hide a lot of detail, which is exactly what you want when building a real application. The danger is that the detail becomes magic. Writing a very small server by hand first, with nothing but the standard library, shows you what every framework is doing underneath: accept a connection, read text, write text back.

### Step 1: Create the Project

Create a new Cargo project for this lesson's experiment. It is a throwaway project; the real application starts in Lesson 4.

```bash
cargo new raw-http
cd raw-http
```

Cargo creates a `raw-http` folder with a `Cargo.toml` file and a `src/main.rs` file containing Hello World, the same layout you used throughout the first course. No dependencies are needed, so `Cargo.toml` stays as it is.

### Step 2: Write the Server

Replace the contents of `src/main.rs` with the following program:

```rust
use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;

fn main() {
    let listener = TcpListener::bind("127.0.0.1:3000").expect("port 3000 should be free");
    println!("Listening on http://127.0.0.1:3000");

    for stream in listener.incoming() {
        let mut stream = stream.expect("connection should succeed");

        let reader = BufReader::new(&stream);
        let request: Vec<String> = reader
            .lines()
            .map(|line| line.expect("line should be valid text"))
            .take_while(|line| !line.is_empty())
            .collect();

        println!("--- request ---");
        for line in &request {
            println!("{line}");
        }

        let body = "<h1>My Tasks</h1><ul><li>Learn Rust</li><li>Build a web app</li></ul>";
        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\n\r\n{}",
            body.len(),
            body
        );
        stream
            .write_all(response.as_bytes())
            .expect("response should be sent");
    }
}
```

Here is what each part does:

- `use std::io::{BufRead, BufReader, Write};` brings in the reading and writing tools. `BufReader` wraps a connection so it can be read line by line, `BufRead` is the trait that provides the `lines()` method, and `Write` is the trait that provides `write_all`.
- `use std::net::TcpListener;` imports the type that waits for network connections. TCP is the protocol that carries HTTP traffic between a browser and a server.
- `TcpListener::bind("127.0.0.1:3000")` asks the operating system for port 3000 on `127.0.0.1`, the address that always means "this computer." `bind` returns a `Result` because the port might already be in use, so `.expect(...)` stops the program with a clear message if it fails, exactly like the file operations in the first course.
- `for stream in listener.incoming()` is a loop that never ends on its own. Each time a client connects, `incoming()` produces a new item: a `Result` holding a `TcpStream`, which is the two-way connection to that client.
- `let mut stream = ...` unwraps the connection. It must be `mut` because writing to a stream changes it.
- `BufReader::new(&stream)` borrows the stream for reading. Then an iterator chain from Lesson 13 of the first course does the work: `lines()` yields each line of the request, `map` unwraps each one, `take_while` stops at the first empty line (in HTTP, an empty line marks the end of the request headers), and `collect` gathers the lines into a `Vec<String>`.
- The `for` loop prints every line of the request so you can see what the client sent.
- `body` is the HTML the browser will display. It is a plain string slice for now.
- `format!` builds the full HTTP response as text: a status line (`HTTP/1.1 200 OK`), two headers, an empty line, and the body. HTTP requires `\r\n` (carriage return plus newline) at the end of every line, and `\r\n\r\n` marks the end of the headers. `Content-Length` tells the client how many bytes of body to expect, which is why it is filled with `body.len()`.
- `stream.write_all(response.as_bytes())` sends the response back over the connection. When `stream` goes out of scope at the end of the loop body, Rust drops it and the connection closes.

Run the server:

```bash
cargo run
```

Output:

```text
Listening on http://127.0.0.1:3000
```

Cargo first prints its usual `Compiling` and `Finished` lines, then the program prints the message above and waits. It looks frozen, but it is working: the `for` loop is waiting for the first connection. Leave this terminal open.

---

## 3. Run and Test

A server is only half of a web application; the other half is a client. You will use two clients: `curl`, which shows the raw response, and a browser, which renders it.

### Step 1: Send a Request with curl

Open a second terminal and request the `/tasks` path. The `-i` flag tells `curl` to include the status line and headers in its output, not only the body.

```bash
curl -i http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 69

<h1>My Tasks</h1><ul><li>Learn Rust</li><li>Build a web app</li></ul>
```

This is exactly the text your `format!` call built. The first line is the status, the next two lines are headers, then comes the empty line and the 69 bytes of HTML.

### Step 2: Read the Request in the Server Terminal

Switch back to the first terminal. The server printed the request it received:

```text
Listening on http://127.0.0.1:3000
--- request ---
GET /tasks HTTP/1.1
Host: 127.0.0.1:3000
User-Agent: curl/8.21.0
Accept: */*
```

The first line is the request line, and it carries the most important information: the method (`GET`), the path (`/tasks`), and the protocol version. The lines after it are headers. `Host` names the server, `User-Agent` names the client (your `curl` version number may differ), and `Accept` says which kinds of content the client can handle.

Notice that your server ignored the path completely. It answers `/tasks`, `/`, and `/anything-else` with the same page. Choosing a different response for each path is called routing, and doing it well by hand is tedious. Axum does it for you from Lesson 4.

### Step 3: Open the Page in a Browser

Visit `http://127.0.0.1:3000` in your browser. You see a heading, "My Tasks," and a bulleted list with two items. The server terminal prints a new request block, and it is longer than the one from `curl`: browsers send many more headers, such as `Accept-Language` and `Accept-Encoding`. Depending on the browser, you may also see a second request for `/favicon.ico`, the small icon shown in the browser tab. Your server answers that request with the same HTML page, because it has no routing.

Stop the server with `Ctrl+C` when you are done.

---

## 4. From One Terminal to Many Browsers

You have now seen the whole idea of the web in about thirty lines: a server waits on a port, a client sends a text request, and the server writes a text response. Everything else in web development builds on this loop. It is worth comparing it with the command-line to-do list you already know.

| | Command-line to-do list | To-do web app |
| --- | --- | --- |
| Who uses it | One person at the terminal where it runs | Anyone who can reach the server with a browser |
| Input | Commands typed into `stdin` | HTTP requests: a method, a path, and form data |
| Output | Text printed with `println!` | HTTP responses containing HTML pages |
| Program lifetime | Starts, handles commands, exits | Runs continuously, handling request after request |
| Storage | One text file read and written as a whole | A MySQL database queried row by row |

The middle rows map surprisingly well. The `Command` enum in the first course turned text like `add Buy milk` into a checked value. A web framework does the same for requests: it turns `POST /tasks` with a form body into a call to the right function with typed arguments. Printing a task list becomes rendering an HTML page. The ideas you practiced, parsing input into types and keeping logic in clear functions, carry over directly.

---

## 5. Why a Database?

The text file worked for one person, but a web application changes the situation. Many requests can arrive at the same moment; two people might add a task at the same time, and rewriting one shared file from two places at once can lose data. The application also needs to answer questions such as "show only unfinished tasks in the Work category, ten per page," and reading a whole file and filtering it in Rust every time does not scale.

A database server such as MySQL solves these problems:

- **Structure.** Data lives in tables with typed columns. A `tasks` table has an `id`, a `title`, a `done` flag, and a due date, and MySQL rejects rows that do not fit.
- **Safe concurrent access.** Many connections can read and write at the same time, and MySQL keeps the data consistent.
- **Queries.** SQL lets you ask precise questions (`SELECT ... WHERE done = FALSE ORDER BY due_date LIMIT 10`) and the database answers them efficiently.
- **Relationships.** Tables can reference each other. In Module 6, each task will belong to a category through a foreign key.

Your Rust program becomes a translator between two worlds: it receives HTTP requests from browsers, turns them into SQL queries for MySQL, and turns the results back into HTML.

```text
browser  --HTTP request-->  Rust server (Axum)  --SQL query-->  MySQL
browser  <--HTML page-----  Rust server (Axum)  <--rows--------  MySQL
```

---

## 6. The Tools in This Course

Your hand-written server has real problems. It handles only one connection at a time, so a slow client blocks everyone else. It has no routing, no way to read form data, and no protection against malformed requests. Fixing all of that by hand would take the entire course. Instead, you will use a small set of well-known crates, each with one clear job:

| Crate | Job | First used |
| --- | --- | --- |
| Tokio | An async runtime that lets one program handle thousands of connections at once | Lesson 2 |
| Axum | A web framework: routing, request extractors, responses | Lesson 4 |
| serde | Converting form data and query strings into Rust structs | Lesson 5 |
| Askama | HTML templates that the compiler checks, like `format!` for whole pages | Lesson 6 |
| SQLx | Talking to MySQL: connection pools, queries, migrations | Lessons 7 to 9 |
| dotenvy | Loading settings such as the database URL from a `.env` file | Lesson 7 |
| tracing | Structured logging for requests and errors | Lesson 19 |

You will add each crate with `cargo add` in the lesson that first needs it, so `Cargo.toml` grows together with your understanding. All of these crates are written in Rust and checked by the same compiler you learned to trust in the first course; a mistake in a template or a handler signature is usually caught before the program runs.

---

## 7. The App You Will Build

The project for the whole course is **Todo Web**, the web version of your command-line to-do list. It grows one feature per lesson:

- **Module 1** prepares the foundations: async Rust in Lesson 2 and the MySQL database and user in Lesson 3.
- **Module 2** starts the Axum server, reads data from URLs and forms, and renders pages with Askama templates.
- **Module 3** connects to MySQL with a connection pool, creates the `tasks` table with migrations, and maps rows to a `Task` struct.
- **Module 4** builds the core features: list tasks, show one task, create, edit, mark as done, and delete.
- **Module 5** validates form input and introduces a custom error type that turns failures into proper error pages.
- **Module 6** adds categories with a second table and a foreign key, then filtering, search, and pagination.
- **Module 7** organizes the code into modules, adds tests that run against a real test database, and prepares a release build.

Every lesson ends with a working application you can run and click through. When something breaks, the "Fix the Errors" section shows the most common mistakes for that lesson and how to recognize them from the compiler or the browser.

---

## 8. Fix the Errors in Your Code

**Error 1: Calling `incoming` on a `Result`**

```rust
// Wrong
let listener = TcpListener::bind("127.0.0.1:3000");
println!("Listening on http://127.0.0.1:3000");

for stream in listener.incoming() {
```

```rust
// Correct
let listener = TcpListener::bind("127.0.0.1:3000").expect("port 3000 should be free");
println!("Listening on http://127.0.0.1:3000");

for stream in listener.incoming() {
```

`bind` can fail, so it returns `Result<TcpListener, std::io::Error>`, not a `TcpListener`. The compiler explains this precisely:

```text
error[E0599]: no method named `incoming` found for enum `Result<T, E>` in the current scope
 --> src/main.rs:8:28
  |
8 |     for stream in listener.incoming() {
  |                            ^^^^^^^^ method not found in `Result<TcpListener, std::io::Error>`
  |
note: the method `incoming` exists on the type `TcpListener`
```

Unwrap the `Result` with `.expect(...)` (or handle it with `match`) before using the listener.

**Error 2: Forgetting `mut` on the stream**

```rust
// Wrong
let stream = stream.expect("connection should succeed");
```

```rust
// Correct
let mut stream = stream.expect("connection should succeed");
```

Writing to a `TcpStream` requires a mutable reference, so `write_all` cannot be called on an immutable binding. The compiler reports:

```text
error[E0596]: cannot borrow `stream` as mutable, as it is not declared as mutable
  --> src/main.rs:29:9
   |
29 |         stream
   |         ^^^^^^ cannot borrow as mutable
```

The help message below the error even suggests the fix: add `mut` to the `let`.

**Error 3: Starting the server twice**

If you run `cargo run` while another copy of the server is still running in a different terminal, the second copy cannot get the port:

```text
thread 'main' (22540) panicked at src/main.rs:5:56:
port 3000 should be free: Os { code: 98, kind: AddrInUse, message: "Address already in use" }
```

This is not a bug in your code; only one program can listen on a port at a time. Stop the first server with `Ctrl+C`, then run the program again. The message after `port 3000 should be free:` comes from the operating system, and `AddrInUse` is the clue to look for. (The thread number in your panic message will be different.)

---

## 9. Exercises

**Exercise 1:** Instead of a hard-coded HTML string, keep the tasks in a vector (`vec!["Learn Rust", "Build a web app", "Connect to MySQL"]`) and write a function `tasks_page(tasks: &[&str]) -> String` that builds the page. It should show a heading, a line with the number of tasks (for example `3 tasks`), and one `<li>` per task.

**Exercise 2:** Add simple routing. Read only the first line of the request (the request line). If it is exactly `GET / HTTP/1.1`, answer with `200 OK` and the task list; for anything else, answer with `404 Not Found` and the body `<h1>Page not found</h1>`. Print one line per request in the form `GET /about HTTP/1.1 -> 404 Not Found`.

**Exercise 3:** Instead of printing the whole request, split the request line into its method and path with `split_whitespace` and print `method: GET, path: /`. Test it with `curl -X POST http://127.0.0.1:3000/tasks` to see a different method.

---

## 10. Solutions

**Solution for Exercise 1:**

```rust
use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;

fn tasks_page(tasks: &[&str]) -> String {
    let items: String = tasks
        .iter()
        .map(|task| format!("<li>{task}</li>"))
        .collect();
    format!("<h1>My Tasks</h1><p>{} tasks</p><ul>{items}</ul>", tasks.len())
}

fn main() {
    let tasks = vec!["Learn Rust", "Build a web app", "Connect to MySQL"];

    let listener = TcpListener::bind("127.0.0.1:3000").expect("port 3000 should be free");
    println!("Listening on http://127.0.0.1:3000");

    for stream in listener.incoming() {
        let mut stream = stream.expect("connection should succeed");

        let reader = BufReader::new(&stream);
        let request_line = reader
            .lines()
            .next()
            .expect("request should have a first line")
            .expect("line should be valid text");

        let mut parts = request_line.split_whitespace();
        let method = parts.next().unwrap_or("");
        let path = parts.next().unwrap_or("");
        println!("method: {method}, path: {path}");

        let body = tasks_page(&tasks);
        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\n\r\n{body}",
            body.len()
        );
        stream
            .write_all(response.as_bytes())
            .expect("response should be sent");
    }
}
```

`tasks_page` takes a slice so it works with a vector, an array, or any part of either. `map` turns each task into an `<li>` element, and `collect` into a `String` joins them all together, because `String` can be collected from an iterator of `String`s. The final `format!` adds the heading and the count from `tasks.len()`. In `main`, `body` is now an owned `String` built for every request; `body.len()` still gives the byte length for `Content-Length`. This program also contains the solution for Exercise 3 (the request line handling), so you can test both at once.

```bash
curl http://127.0.0.1:3000/
```

Output:

```text
<h1>My Tasks</h1><p>3 tasks</p><ul><li>Learn Rust</li><li>Build a web app</li><li>Connect to MySQL</li></ul>
```

**Solution for Exercise 2:**

```rust
use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;

fn main() {
    let listener = TcpListener::bind("127.0.0.1:3000").expect("port 3000 should be free");
    println!("Listening on http://127.0.0.1:3000");

    for stream in listener.incoming() {
        let mut stream = stream.expect("connection should succeed");

        let reader = BufReader::new(&stream);
        let request_line = reader
            .lines()
            .next()
            .expect("request should have a first line")
            .expect("line should be valid text");

        let (status, body) = if request_line == "GET / HTTP/1.1" {
            ("200 OK", "<h1>My Tasks</h1><ul><li>Learn Rust</li><li>Build a web app</li></ul>")
        } else {
            ("404 Not Found", "<h1>Page not found</h1>")
        };

        println!("{request_line} -> {status}");

        let response = format!(
            "HTTP/1.1 {status}\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\n\r\n{body}",
            body.len()
        );
        stream
            .write_all(response.as_bytes())
            .expect("response should be sent");
    }
}
```

`lines().next()` reads only the first line instead of collecting all of them. It returns `Option<Result<String, _>>`: `None` if the client sent nothing, and an error if the line is not valid text, which is why there are two `expect` calls. An `if` expression returns a tuple of the status and the body, and the destructuring `let (status, body)` from the first course unpacks it. Both branches return string slices, so the types match. The status is inserted into the status line of the response.

```bash
curl -i http://127.0.0.1:3000/
```

Output:

```text
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 69

<h1>My Tasks</h1><ul><li>Learn Rust</li><li>Build a web app</li></ul>
```

```bash
curl -i http://127.0.0.1:3000/about
```

Output:

```text
HTTP/1.1 404 Not Found
Content-Type: text/html; charset=utf-8
Content-Length: 23

<h1>Page not found</h1>
```

Output in the server terminal:

```text
Listening on http://127.0.0.1:3000
GET / HTTP/1.1 -> 200 OK
GET /about HTTP/1.1 -> 404 Not Found
```

**Solution for Exercise 3:**

The request line handling is already part of the Solution for Exercise 1:

```rust
let mut parts = request_line.split_whitespace();
let method = parts.next().unwrap_or("");
let path = parts.next().unwrap_or("");
println!("method: {method}, path: {path}");
```

`split_whitespace` returns an iterator over the words of the line. The first `next()` gives the method and the second gives the path. `unwrap_or("")` uses an empty string if a part is missing, so a malformed request line does not crash the server. Run the Exercise 1 program, then send one `GET` and one `POST` request:

```bash
curl http://127.0.0.1:3000/
curl -X POST http://127.0.0.1:3000/tasks
```

Output in the server terminal:

```text
Listening on http://127.0.0.1:3000
method: GET, path: /
method: POST, path: /tasks
```

The method tells the server what the client wants to do. `GET` asks for a page, and `POST` sends data, such as a new task from a form. Axum will let you attach a different function to each method and path combination.

---

## Next Up - Lesson 2

In this lesson, you wrote a web server with nothing but the standard library, read real HTTP requests and responses as plain text, and saw why a web version of the to-do list needs a database. You also met the crates that will do the heavy lifting for the rest of the course.

Your server had one serious weakness: it handled connections one at a time, so a single slow client would make everyone else wait. In Lesson 2, you will learn async Rust with Tokio, the foundation Axum is built on. You will write `async` functions, wait for them with `.await`, and see how one program can make progress on many tasks at once.
