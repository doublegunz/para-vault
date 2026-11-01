## 1. Before You Begin

In Lesson 1, your hand-written server handled one connection at a time. While it was busy writing a response to one client, every other client had to wait. A real web server cannot work like that: while one request is waiting for MySQL to answer, the server should already be working on the next request.

Rust solves this with async programming. An async function can pause while it waits for something slow, such as a timer, a network connection, or a database query, and let other work run in the meantime. Rust itself only provides the `async` and `.await` syntax; a separate library called a runtime actually schedules and runs the async code. The runtime used by Axum and SQLx is Tokio, so this lesson teaches async Rust through Tokio. Every handler you write from Lesson 4 onward is an async function, so the ideas here are the foundation for the rest of the course.

### What You'll Build

A small Cargo project, `async-basics`, in which you will write several short programs: an async function awaited from `main`, two slow operations run one after another and then at the same time, a batch of spawned background tasks, and finally an async version of the Lesson 1 server that serves several clients at once.

### What You'll Learn

- ✅ What `async fn` and `.await` mean, and why futures do nothing until awaited
- ✅ How the `#[tokio::main]` attribute starts the Tokio runtime
- ✅ How to wait without blocking using `tokio::time::sleep`
- ✅ The difference between running futures one after another and concurrently with `tokio::join!`
- ✅ How to run independent tasks with `tokio::spawn` and collect their results
- ✅ How an async server handles many connections at the same time

### What You'll Need

- Lesson 1 completed, so the request and response cycle is familiar
- Closures, `Vec`, and `Result` from the first course
- An internet connection, because Cargo downloads the Tokio crate the first time you build

---

## 2. Your First Async Function

Async code looks almost like normal code. The differences are the `async` keyword in front of a function and `.await` after a call. To run async code at all, the program needs a runtime, so the first step is adding Tokio.

### Step 1: Create the Project and Add Tokio

Create a new project and add Tokio as a dependency:

```bash
cargo new async-basics
cd async-basics
cargo add tokio --features full
```

`cargo add` edits `Cargo.toml` for you. Tokio is split into optional features so small programs do not compile code they never use; `full` turns all of them on, which is the simplest choice while learning. Open `Cargo.toml` and you will see the new dependency:

```toml
[dependencies]
tokio = { version = "1.54.1", features = ["full"] }
```

Your version number may be newer. Any `1.x` version works with this course.

### Step 2: Write and Await an Async Function

Replace the contents of `src/main.rs` with this program:

```rust
async fn load_tasks() -> Vec<String> {
    vec![String::from("Learn Rust"), String::from("Build a web app")]
}

#[tokio::main]
async fn main() {
    println!("Loading tasks...");
    let tasks = load_tasks().await;
    for task in &tasks {
        println!("- {task}");
    }
    println!("{} tasks loaded", tasks.len());
}
```

Here is what is new:

- `async fn load_tasks() -> Vec<String>` declares an async function. Calling it does not run the body right away. Instead, it returns a future: a value that represents work which will produce a `Vec<String>` when it is driven to completion.
- `load_tasks().await` drives that future to completion and gives you its result. `.await` can only be used inside another async function or async block, which is why `main` is also `async`.
- `#[tokio::main]` is an attribute macro. Rust does not allow `main` to be async on its own, so this attribute rewrites your `main` into a normal function that starts the Tokio runtime and runs your async body on it.
- The rest is ordinary Rust from the first course: a `for` loop over a borrowed vector and `len()`.

This function has nothing slow inside it yet, so being async does not change its behavior. Later, `load_tasks` will become a real database query that has to wait for MySQL, and the shape of the code will stay exactly the same.

Run the program:

```bash
cargo run
```

The first build downloads and compiles Tokio and a few related crates, so it takes a little longer than usual. Then the program prints:

```text
Loading tasks...
- Learn Rust
- Build a web app
2 tasks loaded
```

---

## 3. Waiting Without Blocking

Async code becomes interesting when there is something to wait for. A web server waits for clients, and a database client waits for query results. To experiment safely, you will simulate slow work with a timer.

### Step 1: Run Two Slow Operations One After Another

Replace `src/main.rs` with this program:

```rust
use std::time::{Duration, Instant};
use tokio::time::sleep;

async fn fetch(name: &str, seconds: u64) -> String {
    println!("start {name}");
    sleep(Duration::from_secs(seconds)).await;
    println!("done  {name}");
    format!("{name} finished after {seconds}s")
}

#[tokio::main]
async fn main() {
    let started = Instant::now();

    let a = fetch("tasks", 1).await;
    let b = fetch("categories", 2).await;

    println!("{a}");
    println!("{b}");
    println!("total: {:.1}s", started.elapsed().as_secs_f64());
}
```

Line by line:

- `Duration` represents a length of time and `Instant` a moment in time. Both come from the standard library.
- `tokio::time::sleep` is Tokio's async timer. `sleep(Duration::from_secs(seconds)).await` pauses this function for the given number of seconds, but it does not stop the whole thread. While it waits, the runtime is free to run other futures.
- `fetch` pretends to be a slow lookup, such as loading tasks from a database. It prints when it starts and finishes so you can see the order of events, then returns a `String`.
- `Instant::now()` records the start time, and `started.elapsed()` measures how long everything took. `as_secs_f64()` converts the duration to seconds as a floating point number, and `{:.1}` rounds it to one decimal place.
- `fetch("tasks", 1).await` runs the first fetch to completion before the next line starts. Only then does `fetch("categories", 2).await` begin.

Run it:

```bash
cargo run
```

Output:

```text
start tasks
done  tasks
start categories
done  categories
tasks finished after 1s
categories finished after 2s
total: 3.0s
```

The total is the sum of both waits: one second plus two seconds. Each `.await` in sequence waits for the previous one, exactly like normal code.

### Step 2: Run Them Concurrently with join!

The two fetches do not depend on each other, so there is no reason to wait for the first before starting the second. `tokio::join!` runs several futures at the same time and waits until all of them are finished. Replace `src/main.rs` with:

```rust
use std::time::{Duration, Instant};
use tokio::time::sleep;

async fn fetch(name: &str, seconds: u64) -> String {
    println!("start {name}");
    sleep(Duration::from_secs(seconds)).await;
    println!("done  {name}");
    format!("{name} finished after {seconds}s")
}

#[tokio::main]
async fn main() {
    let started = Instant::now();

    let (a, b) = tokio::join!(fetch("tasks", 1), fetch("categories", 2));

    println!("{a}");
    println!("{b}");
    println!("total: {:.1}s", started.elapsed().as_secs_f64());
}
```

Only one line in `main` changed. `tokio::join!(fetch("tasks", 1), fetch("categories", 2))` takes both futures, polls them together, and returns a tuple of their results in the same order you listed them. You destructure that tuple with `let (a, b)`, a pattern from the first course. Notice that there is no `.await` after each call inside `join!`; the macro awaits all of them for you.

Run it:

```bash
cargo run
```

Output:

```text
start tasks
start categories
done  tasks
done  categories
tasks finished after 1s
categories finished after 2s
total: 2.0s
```

Both fetches start immediately. While `tasks` sleeps, `categories` is already sleeping too, so the total is the length of the longest wait, two seconds, not the sum. This is concurrency: making progress on several things during the same period of time. Nothing here needed extra threads; a single thread can switch between futures every time one of them is waiting.

---

## 4. Spawning Tasks

`join!` is perfect when you know in advance exactly which futures to run. A web server does not: it cannot know how many requests will arrive. For that, Tokio lets you spawn tasks. A task is a future handed to the runtime to run in the background, independently of the code that spawned it.

### Step 1: Spawn Several Tasks and Collect Their Results

Replace `src/main.rs` with:

```rust
use std::time::{Duration, Instant};
use tokio::time::sleep;

#[tokio::main]
async fn main() {
    let started = Instant::now();
    let mut handles = Vec::new();

    for id in 1..=5 {
        let handle = tokio::spawn(async move {
            sleep(Duration::from_secs(1)).await;
            println!("request {id} handled");
            id * 10
        });
        handles.push(handle);
    }

    let mut total = 0;
    for handle in handles {
        total += handle.await.expect("task should not panic");
    }

    println!("sum of results: {total}");
    println!("total: {:.1}s", started.elapsed().as_secs_f64());
}
```

Here is how it works:

- `async move { ... }` is an async block: an anonymous piece of async code, similar to a closure. `move` makes the block take ownership of the variables it uses, here `id`. This matters because a spawned task can keep running after the code that created it moves on, so it must not borrow local variables.
- `tokio::spawn(...)` hands the async block to the runtime, which starts running it right away. `spawn` returns a `JoinHandle`, which you can use later to wait for the task and get its result.
- The loop spawns five tasks, each pretending to handle a request that takes one second, and stores every handle in a vector.
- The last expression in the block, `id * 10`, is the task's result.
- `handle.await` waits for one task to finish. It returns a `Result`, because a task can fail if it panics; `.expect(...)` unwraps the value. Adding the results gives `10 + 20 + 30 + 40 + 50`.

Run it:

```bash
cargo run
```

Output:

```text
request 4 handled
request 1 handled
request 2 handled
request 3 handled
request 5 handled
sum of results: 150
total: 1.0s
```

Five one-second jobs finished in one second, because all five were waiting at the same time. Notice the order of the `handled` lines: the tasks run independently, so they finish in whatever order the runtime happens to complete them. Your order will probably be different from this one, and it may change every time you run the program. The sum is always 150, because the results are collected from the handles in a fixed order.

---

## 5. An Async Server That Serves Everyone

Now you can fix the weakness from Lesson 1. Tokio provides async versions of the networking types, and spawning one task per connection lets the server keep accepting new clients while earlier ones are still being served.

### Step 1: Write the Async Server

Replace `src/main.rs` with this program:

```rust
use std::time::Duration;
use tokio::io::AsyncWriteExt;
use tokio::net::TcpListener;
use tokio::time::sleep;

#[tokio::main]
async fn main() {
    let listener = TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    println!("Listening on http://127.0.0.1:3000");

    loop {
        let (mut stream, address) = listener.accept().await.expect("connection should succeed");
        println!("connection from {address}");

        tokio::spawn(async move {
            sleep(Duration::from_secs(2)).await;

            let body = "<h1>My Tasks</h1>";
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\n\r\n{body}",
                body.len()
            );
            stream
                .write_all(response.as_bytes())
                .await
                .expect("response should be sent");
        });
    }
}
```

Compare it with the Lesson 1 server:

- `tokio::net::TcpListener` is the async counterpart of `std::net::TcpListener`. Binding is async too, so it needs `.await` before `.expect(...)`.
- `loop { ... }` replaces the `for` loop. `listener.accept().await` waits for the next client and returns a tuple: the connection (`stream`) and the client's address. The address is printed so you can see each connection arrive.
- `tokio::spawn(async move { ... })` moves the connection into a new task. The loop immediately goes back to `accept()`, ready for the next client, while the task serves this one.
- Inside the task, `sleep(Duration::from_secs(2)).await` simulates a slow database query. This is where a real handler would wait for MySQL.
- `tokio::io::AsyncWriteExt` is the trait that provides the async `write_all` method, the counterpart of `std::io::Write`. Writing to the network can wait, so `write_all` also needs `.await`.
- To keep the example short, this server does not read the request. It simply answers every connection with the same page.

Start the server:

```bash
cargo run
```

Output:

```text
Listening on http://127.0.0.1:3000
```

---

## 6. Run and Test

A single request will not show the difference; you need several clients at the same time. `xargs -P` can start several `curl` processes in parallel.

### Step 1: Send Three Requests at Once

In a second terminal, run:

```bash
seq 3 | xargs -P 3 -I{} curl -s -o /dev/null -w "request {}: %{http_code} in %{time_total}s\n" http://127.0.0.1:3000/
```

This command looks dense, so here are its parts. `seq 3` prints the numbers 1, 2, and 3. `xargs -P 3` runs up to three commands in parallel, replacing `{}` with each number. For each one, `curl -s -o /dev/null` sends a request quietly and throws the body away, and `-w` prints a custom line with the HTTP status code and the total time.

Output:

```text
request 3: 200 in 2.001882s
request 2: 200 in 2.002258s
request 1: 200 in 2.002279s
```

All three requests finished in about two seconds, even though each one waits two seconds on the server. The server terminal shows the three connections arriving immediately, one after another:

```text
Listening on http://127.0.0.1:3000
connection from 127.0.0.1:42452
connection from 127.0.0.1:42458
connection from 127.0.0.1:42466
```

The port numbers after `127.0.0.1:` are chosen by the operating system for each client, so yours will differ.

### Step 2: Compare with a Server That Does Not Spawn

To see what `tokio::spawn` is buying you, stop the server with `Ctrl+C` and temporarily replace the `tokio::spawn(async move {` line with a plain `{`, and the matching `});` with `}`. The connection is now served directly inside the loop. Run the server again, then repeat the `xargs` command from Step 1.

Output:

```text
request 1: 200 in 2.002032s
request 2: 200 in 4.002184s
request 3: 200 in 6.002392s
```

Without spawning, the loop cannot accept the second client until the first response is finished, so the requests queue up: two, four, and six seconds. This is the same behavior as the Lesson 1 server. Undo the change so the server spawns a task again, and stop it with `Ctrl+C`.

Axum does all of this for you: it accepts connections, spawns tasks, and calls your async handler functions. You will never write the accept loop yourself again, but now you know what is happening underneath.

---

## 7. How Async Works Under the Hood

You have used async Rust successfully, so it is a good moment to name the ideas behind it. You do not need to memorize these details to build the to-do app, but they explain the behavior you saw.

- **A future is lazy.** Calling an async function only creates a future, a value describing the work. Nothing happens until something polls it. `.await`, `join!`, and `spawn` are the three ways you have seen to get a future polled.
- **The runtime is a scheduler.** Tokio keeps a list of tasks. It polls a task until that task reaches an `.await` that cannot finish yet, such as a timer or a network read, then switches to another task that is ready. When the timer fires or data arrives, the waiting task is marked ready and polled again.
- **`.await` is a pause point, not a block.** At every `.await`, a task may give the thread back to the runtime. This is why one thread can serve thousands of connections, as long as each task spends most of its time waiting.
- **Blocking code breaks the model.** Functions such as `std::thread::sleep` or a slow loop of heavy calculations do not reach an `.await`, so the task never gives the thread back. Other tasks on that thread stop moving. Section 8 shows this mistake.
- **Concurrency is not the same as parallelism.** Concurrency means making progress on several tasks during the same period, by switching between them. Parallelism means running at the exact same instant on several CPU cores. With the `full` feature set, Tokio uses a thread pool, so spawned tasks may also run in parallel, but the speedups in this lesson came from concurrency: the tasks were simply waiting at the same time.

| Tool | Use it when |
| --- | --- |
| `.await` | You need the result before the next line can run |
| `tokio::join!` | You have a fixed set of independent futures and want all results |
| `tokio::spawn` | The number of jobs is not known in advance, or a job should run in the background |

---

## 8. Fix the Errors in Your Code

**Error 1: Forgetting `.await`**

```rust
// Wrong
async fn save_task(title: &str) {
    println!("saved: {title}");
}

#[tokio::main]
async fn main() {
    save_task("Learn Rust");
    println!("done");
}
```

```rust
// Correct
async fn save_task(title: &str) {
    println!("saved: {title}");
}

#[tokio::main]
async fn main() {
    save_task("Learn Rust").await;
    println!("done");
}
```

This mistake compiles, which makes it sneaky. Calling `save_task` only creates a future, and the future is thrown away without being polled, so the body never runs. The compiler warns you, and the program prints only `done`:

```text
warning: unused implementer of `Future` that must be used
 --> src/main.rs:7:5
  |
7 |     save_task("Learn Rust");
  |     ^^^^^^^^^^^^^^^^^^^^^^^
  |
  = note: futures do nothing unless you `.await` or poll them
  = note: `#[warn(unused_must_use)]` (part of `#[warn(unused)]`) on by default

done
```

Treat this warning as an error. The note says it plainly: futures do nothing unless you `.await` them. With `.await` added, the program prints `saved: Learn Rust` before `done`.

**Error 2: Making `main` async without `#[tokio::main]`**

```rust
// Wrong
async fn main() {
    let tasks = load_tasks().await;
    println!("{} tasks loaded", tasks.len());
}
```

```rust
// Correct
#[tokio::main]
async fn main() {
    let tasks = load_tasks().await;
    println!("{} tasks loaded", tasks.len());
}
```

Rust has no built-in runtime, so it does not know how to run an async `main`:

```text
error[E0752]: `main` function is not allowed to be `async`
 --> src/main.rs:5:1
  |
5 | async fn main() {
  | ^^^^^^^^^^^^^^^ `main` function is not allowed to be `async`
```

The `#[tokio::main]` attribute turns `main` back into a normal function that starts Tokio and runs your async code on it.

**Error 3: Blocking inside async code**

```rust
// Wrong
async fn fetch(name: &str, seconds: u64) -> String {
    println!("start {name}");
    std::thread::sleep(Duration::from_secs(seconds));
    println!("done  {name}");
    format!("{name} finished after {seconds}s")
}
```

```rust
// Correct
async fn fetch(name: &str, seconds: u64) -> String {
    println!("start {name}");
    tokio::time::sleep(Duration::from_secs(seconds)).await;
    println!("done  {name}");
    format!("{name} finished after {seconds}s")
}
```

`std::thread::sleep` stops the whole thread instead of pausing just this future, so the runtime cannot switch to other work. With the wrong version, the `tokio::join!` program from Section 3 compiles without any warning but loses all of its concurrency:

```text
start tasks
done  tasks
start categories
done  categories
tasks finished after 1s
categories finished after 2s
total: 3.0s
```

The output looks exactly like the sequential version: three seconds instead of two. Inside async code, always use the async version of anything that waits: `tokio::time::sleep`, Tokio's networking types, and SQLx's async queries.

**Error 4: Spawning a task without `move`**

```rust
// Wrong
let title = String::from("Learn Rust");

let handle = tokio::spawn(async {
    println!("saving {title}");
});
```

```rust
// Correct
let title = String::from("Learn Rust");

let handle = tokio::spawn(async move {
    println!("saving {title}");
});
```

A spawned task might outlive the function that created it, so it is not allowed to borrow that function's local variables:

```text
error[E0373]: async block may outlive the current function, but it borrows `title`, which is owned by the current function
 --> src/main.rs:5:31
  |
5 |     let handle = tokio::spawn(async {
  |                               ^^^^^ may outlive borrowed value `title`
6 |         println!("saving {title}");
  |                           ----- `title` is borrowed here
```

The help line in the full message suggests adding `move`, which transfers ownership of `title` into the task. This is the same ownership rule you learned in the first course, applied to async blocks.

---

## 9. Exercises

**Exercise 1:** Extend the `tokio::join!` program from Section 3 with a third fetch, `fetch("users", 3)`. Before running it, predict the total time. Then run it and print all three results.

**Exercise 2:** Spawn three tasks from a vector of `(title, seconds)` pairs: `("Learn Rust", 3)`, `("Build a web app", 1)`, and `("Connect to MySQL", 2)`. Each task sleeps for its number of seconds, prints `finished: <title>`, and returns the title in uppercase. Collect the results from the handles and print each one as `result: <TITLE>`. Look closely at the order of the two kinds of lines.

**Exercise 3:** A web server should not wait forever for a slow operation. Use `tokio::time::timeout` to give each fetch at most 1.5 seconds. Call `fetch("tasks", 1)` and `fetch("categories", 2)` one after another, printing `ok: <result>` when a fetch finishes in time and `<name> took too long` when it does not.

---

## 10. Solutions

**Solution for Exercise 1:**

```rust
use std::time::{Duration, Instant};
use tokio::time::sleep;

async fn fetch(name: &str, seconds: u64) -> String {
    println!("start {name}");
    sleep(Duration::from_secs(seconds)).await;
    println!("done  {name}");
    format!("{name} finished after {seconds}s")
}

#[tokio::main]
async fn main() {
    let started = Instant::now();

    let (a, b, c) = tokio::join!(
        fetch("tasks", 1),
        fetch("categories", 2),
        fetch("users", 3)
    );

    println!("{a}");
    println!("{b}");
    println!("{c}");
    println!("total: {:.1}s", started.elapsed().as_secs_f64());
}
```

`tokio::join!` accepts any number of futures and returns a tuple with one result per future, so the pattern grows to `(a, b, c)`. The right prediction is three seconds: the fetches wait at the same time, so the total is the longest wait, not the sum of one, two, and three.

```bash
cargo run
```

Output:

```text
start tasks
start categories
start users
done  tasks
done  categories
done  users
tasks finished after 1s
categories finished after 2s
users finished after 3s
total: 3.0s
```

**Solution for Exercise 2:**

```rust
use std::time::Duration;
use tokio::time::sleep;

#[tokio::main]
async fn main() {
    let titles = vec![("Learn Rust", 3), ("Build a web app", 1), ("Connect to MySQL", 2)];
    let mut handles = Vec::new();

    for (title, seconds) in titles {
        let handle = tokio::spawn(async move {
            sleep(Duration::from_secs(seconds)).await;
            println!("finished: {title}");
            title.to_uppercase()
        });
        handles.push(handle);
    }

    for handle in handles {
        let result = handle.await.expect("task should not panic");
        println!("result: {result}");
    }
}
```

The `for` loop destructures each tuple into `title` and `seconds`, and `async move` moves both into the task. `title` is a `&'static str` (a string literal), so the task can own it without problems. `to_uppercase` returns a new `String`, which becomes the task's result.

```bash
cargo run
```

Output:

```text
finished: Build a web app
finished: Connect to MySQL
finished: Learn Rust
result: LEARN RUST
result: BUILD A WEB APP
result: CONNECT TO MYSQL
```

The `finished` lines appear in the order the tasks complete: shortest sleep first. The `result` lines follow the order of the handles in the vector, because the second loop awaits the first handle (the three-second task) before it looks at the others. By then, the other two tasks are already done, so their results come out immediately.

**Solution for Exercise 3:**

```rust
use std::time::Duration;
use tokio::time::{sleep, timeout};

async fn fetch(name: &str, seconds: u64) -> String {
    sleep(Duration::from_secs(seconds)).await;
    format!("{name} finished after {seconds}s")
}

#[tokio::main]
async fn main() {
    let limit = Duration::from_millis(1500);

    match timeout(limit, fetch("tasks", 1)).await {
        Ok(result) => println!("ok: {result}"),
        Err(_) => println!("tasks took too long"),
    }

    match timeout(limit, fetch("categories", 2)).await {
        Ok(result) => println!("ok: {result}"),
        Err(_) => println!("categories took too long"),
    }
}
```

`timeout(limit, future)` wraps a future in a new future with a deadline. When awaited, it returns `Ok(value)` if the inner future finishes in time and `Err(...)` if the deadline passes first; in that case, the inner future is dropped and never finishes. `match` handles both cases, just like any other `Result`. `Duration::from_millis(1500)` expresses one and a half seconds.

```bash
cargo run
```

Output:

```text
ok: tasks finished after 1s
categories took too long
```

---

## Next Up - Lesson 3

In this lesson, you learned that async functions return lazy futures, that `#[tokio::main]` starts the runtime, and that `.await`, `tokio::join!`, and `tokio::spawn` each drive futures in their own way. You also rebuilt the Lesson 1 server so it serves many clients at once, which is exactly what Axum will do for you.

Before writing the real application, it needs somewhere to keep its data. In Lesson 3, you will prepare MySQL for the project: create the `db_rust_todo` database and a dedicated user with the right privileges, connect with the `mysql` client, and run a few SQL queries by hand so you know exactly what your Rust code will be asking the database to do.
